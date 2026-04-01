#include <errno.h>
#include <stdbool.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "../include/accel_mmio.h"
#include "../include/accel_unified_mem.h"
#include "../include/accel_unified_queue.h"

#define EMU_FETCH_STATUS_BUSY  0x00000001u
#define EMU_FETCH_STATUS_ERROR 0x00000002u
#define EMU_FETCH_STATUS_IDLE  0x00000004u
#define EMU_DISPATCH_STATUS_BUSY  0x00000001u
#define EMU_DISPATCH_STATUS_ERROR 0x00000002u
#define EMU_DISPATCH_STATUS_IDLE  0x00000004u

typedef struct {
    uint32_t control_shadow;
    uint8_t npu_model_id;
    uint16_t npu_seq_length;
    uint32_t npu_input0;
    uint32_t npu_input1;
    uint32_t npu_weight0_a;
    uint32_t npu_weight0_b;
    uint32_t npu_weight1_a;
    uint32_t npu_weight1_b;
    uint32_t npu_bias0;
    uint32_t npu_bias1;
    uint32_t umem_ctrl;
    uint32_t umem_base_addr;
    uint32_t umem_size_bytes;
    uint32_t umem_npu_input_offset;
    uint32_t umem_npu_weight_offset;
    uint32_t umem_npu_output_offset;
    uint32_t umem_gpu_fb_offset;
    uint32_t umem_gpu_fb_pitch;
    uint32_t umem_cmdq_base_offset;
    uint32_t umem_cmdq_size_bytes;
    uint32_t umem_cmdq_head;
    uint32_t umem_cmdq_tail;
    uint32_t umem_cmdq_doorbell;
    uint32_t umem_cmdq_status;
    uint32_t umem_cmdq_processed;
    uint32_t umem_cmdq_last_offset;
    uint32_t umem_cmdq_last_sequence;
    uint16_t umem_cmdq_last_slot;
    uint32_t umem_cmdq_fetch_status;
    uint32_t umem_cmdq_last_araddr;
    uint32_t umem_cmdq_last_beat_count;
    uint32_t umem_cmdq_last_desc_word0;
    uint32_t umem_cmdq_dispatch_status;
    uint32_t umem_cmdq_dispatch_opcode;
    uint32_t umem_cmdq_dispatch_npu_count;
    uint32_t umem_cmdq_dispatch_gpu_count;
    uint32_t umem_cmdq_dispatch_error_count;
    uint16_t umem_cmdq_npu_exec_count;
    uint8_t umem_cmdq_npu_exec_last_model_id;
    bool umem_cmdq_npu_exec_error;
    uint32_t umem_cmdq_npu_exec_status;
    uint32_t umem_cmdq_npu_exec_input_offset;
    uint32_t umem_cmdq_npu_exec_output_offset;
    bool npu_busy;
    bool npu_done_sticky;
    uint32_t npu_status_word;
    int32_t npu_logit0;
    int32_t npu_logit1;
    uint8_t npu_class_id;
    uint8_t gpu_cmd_opcode;
    uint16_t gpu_vertex0;
    uint16_t gpu_vertex1;
    uint16_t gpu_vertex2;
    uint8_t gpu_clear_value;
    uint8_t gpu_fb_row_select;
    bool gpu_busy;
    bool gpu_done_sticky;
    uint32_t gpu_triangles;
    uint32_t gpu_frame_count;
    uint32_t gpu_raster_pixels;
    int32_t gpu_last_area2;
    uint32_t gpu_last_bbox;
    uint32_t irq_enable;
    uint32_t framebuffer[GPU_FB_ROWS];
    uint8_t unified_mem[ACCEL_UMEM_BYTES];
} accel_emulator_t;

typedef struct {
    bool emulate;
    volatile uint8_t *mmio;
    accel_emulator_t emu;
} accel_backend_t;

static int32_t unpack_i8(uint32_t word, unsigned shift) {
    uint32_t value = (word >> shift) & 0xFFu;
    if ((value & 0x80u) != 0u) {
        value -= 0x100u;
    }
    return (int32_t)value;
}

static int32_t dot4_i8(uint32_t lhs, uint32_t rhs) {
    int32_t sum = 0;
    for (unsigned shift = 0; shift <= 24; shift += 8) {
        sum += unpack_i8(lhs, shift) * unpack_i8(rhs, shift);
    }
    return sum;
}

static int32_t edge_fn(int ax, int ay, int bx, int by, int px, int py) {
    return (bx - ax) * (py - ay) - (by - ay) * (px - ax);
}

static uint32_t pack_xy(uint8_t x, uint8_t y) {
    return ((uint32_t)y << 8) | (uint32_t)x;
}

static uint32_t emu_umem_limit_bytes(const accel_emulator_t *emu) {
    return (emu->umem_size_bytes < ACCEL_UMEM_BYTES) ? emu->umem_size_bytes : ACCEL_UMEM_BYTES;
}

static uint32_t *emu_umem_word_ptr(accel_emulator_t *emu, uint32_t offset) {
    if ((offset + sizeof(uint32_t)) > emu_umem_limit_bytes(emu)) {
        fprintf(stderr, "emulator unified-memory access out of range: offset=0x%08x size=0x%08x\n",
                offset, emu->umem_size_bytes);
        exit(1);
    }
    return (uint32_t *)(void *)(emu->unified_mem + offset);
}

static uint32_t emu_umem_read32(accel_emulator_t *emu, uint32_t offset) {
    return *emu_umem_word_ptr(emu, offset);
}

static void emu_umem_write32(accel_emulator_t *emu, uint32_t offset, uint32_t value) {
    *emu_umem_word_ptr(emu, offset) = value;
}

static uint32_t emu_cmdq_entry_count(const accel_emulator_t *emu) {
    uint32_t bytes = emu->umem_cmdq_size_bytes;
    if (bytes < ACCEL_UMEM_CMDQ_DESC_BYTES) {
        bytes = ACCEL_UMEM_CMDQ_DESC_BYTES;
    }
    bytes -= bytes % ACCEL_UMEM_CMDQ_DESC_BYTES;
    if (bytes == 0u) {
        bytes = ACCEL_UMEM_CMDQ_DESC_BYTES;
    }
    return bytes / ACCEL_UMEM_CMDQ_DESC_BYTES;
}

static accel_umem_cmd_desc_t *emu_cmdq_desc_ptr(accel_emulator_t *emu, uint32_t slot) {
    uint32_t entry_count = emu_cmdq_entry_count(emu);
    uint32_t offset = emu->umem_cmdq_base_offset + (slot % entry_count) * ACCEL_UMEM_CMDQ_DESC_BYTES;

    if ((offset + ACCEL_UMEM_CMDQ_DESC_BYTES) > emu_umem_limit_bytes(emu)) {
        fprintf(stderr, "emulator unified command-queue access out of range: slot=%u offset=0x%08x limit=0x%08x\n",
                slot, offset, emu_umem_limit_bytes(emu));
        exit(1);
    }

    return (accel_umem_cmd_desc_t *)(void *)(emu->unified_mem + offset);
}

static void emu_cmdq_refresh_status(accel_emulator_t *emu, bool error_seen) {
    uint32_t status = 0u;

    if (error_seen) {
        status |= CMDQ_STATUS_ERROR;
    }
    if (emu->umem_cmdq_head == emu->umem_cmdq_tail) {
        status |= CMDQ_STATUS_EMPTY;
    }
    status |= (emu->umem_cmdq_processed & 0xFFFFu) << 16;
    emu->umem_cmdq_status = status;
}

static void emu_sync_gpu_framebuffer_to_umem(accel_emulator_t *emu) {
    if ((emu->umem_ctrl & (ACCEL_UMEM_CTRL_ENABLE | ACCEL_UMEM_CTRL_GPU_USE_BUF)) !=
        (ACCEL_UMEM_CTRL_ENABLE | ACCEL_UMEM_CTRL_GPU_USE_BUF)) {
        return;
    }

    for (uint32_t row = 0; row < GPU_FB_ROWS; ++row) {
        emu_umem_write32(emu, emu->umem_gpu_fb_offset + row * emu->umem_gpu_fb_pitch, emu->framebuffer[row]);
    }
}

static uint32_t emu_pack_npu_exec_status(const accel_emulator_t *emu, bool busy) {
    uint32_t flags = 0u;

    if (busy) {
        flags |= NPU_CMD_EXEC_BUSY;
    }
    if (emu->umem_cmdq_npu_exec_error) {
        flags |= NPU_CMD_EXEC_ERROR;
    }
    if (!busy) {
        flags |= NPU_CMD_EXEC_IDLE;
    }

    return ((uint32_t)emu->umem_cmdq_npu_exec_count << 16) |
           ((uint32_t)emu->umem_cmdq_npu_exec_last_model_id << 8) |
           flags;
}

static void emu_init(accel_emulator_t *emu) {
    memset(emu, 0, sizeof(*emu));
    emu->npu_model_id = NPU_MODEL_BUILTIN_1;
    emu->npu_seq_length = 8u;
    emu->npu_input0 = 0x04030201u;
    emu->npu_input1 = 0x00000000u;
    emu->npu_weight0_a = 0x01010101u;
    emu->npu_weight0_b = 0xFFFFFFFFu;
    emu->npu_weight1_a = 0xFFFFFFFFu;
    emu->npu_weight1_b = 0x01010101u;
    emu->umem_ctrl = 0u;
    emu->umem_base_addr = ACCEL_UMEM_DEFAULT_BASE;
    emu->umem_size_bytes = ACCEL_UMEM_BYTES;
    emu->umem_npu_input_offset = ACCEL_UMEM_NPU_INPUT_OFFSET;
    emu->umem_npu_weight_offset = ACCEL_UMEM_NPU_WEIGHT_OFFSET;
    emu->umem_npu_output_offset = ACCEL_UMEM_NPU_OUTPUT_OFFSET;
    emu->umem_gpu_fb_offset = ACCEL_UMEM_GPU_FB_OFFSET;
    emu->umem_gpu_fb_pitch = ACCEL_UMEM_GPU_FB_PITCH;
    emu->umem_cmdq_base_offset = ACCEL_UMEM_CMDQ_OFFSET;
    emu->umem_cmdq_size_bytes = ACCEL_UMEM_CMDQ_BYTES;
    emu->umem_cmdq_head = 0u;
    emu->umem_cmdq_tail = 0u;
    emu->umem_cmdq_doorbell = 0u;
    emu->umem_cmdq_status = CMDQ_STATUS_EMPTY;
    emu->umem_cmdq_processed = 0u;
    emu->umem_cmdq_last_offset = 0u;
    emu->umem_cmdq_last_sequence = 0u;
    emu->umem_cmdq_last_slot = 0u;
    emu->umem_cmdq_fetch_status = EMU_FETCH_STATUS_IDLE;
    emu->umem_cmdq_last_araddr = 0u;
    emu->umem_cmdq_last_beat_count = 0u;
    emu->umem_cmdq_last_desc_word0 = 0u;
    emu->umem_cmdq_dispatch_status = EMU_DISPATCH_STATUS_IDLE;
    emu->umem_cmdq_dispatch_opcode = 0u;
    emu->umem_cmdq_dispatch_npu_count = 0u;
    emu->umem_cmdq_dispatch_gpu_count = 0u;
    emu->umem_cmdq_dispatch_error_count = 0u;
    emu->umem_cmdq_npu_exec_count = 0u;
    emu->umem_cmdq_npu_exec_last_model_id = 0u;
    emu->umem_cmdq_npu_exec_error = false;
    emu->umem_cmdq_npu_exec_status = NPU_CMD_EXEC_IDLE;
    emu->umem_cmdq_npu_exec_input_offset = 0u;
    emu->umem_cmdq_npu_exec_output_offset = 0u;
    emu->gpu_cmd_opcode = GPU_CMD_DRAW_TRI;
    emu->gpu_vertex0 = 0x0202u;
    emu->gpu_vertex1 = 0x020Au;
    emu->gpu_vertex2 = 0x0A02u;
}

static void emu_select_npu_weights(const accel_emulator_t *emu, uint8_t model_id,
                                   uint32_t *weight0_a, uint32_t *weight0_b,
                                   uint32_t *weight1_a, uint32_t *weight1_b,
                                   int32_t *bias0, int32_t *bias1) {
    switch (model_id) {
        case NPU_MODEL_BUILTIN_2:
            *weight0_a = 0xFFFFFFFFu;
            *weight0_b = 0x01010101u;
            *weight1_a = 0x01010101u;
            *weight1_b = 0xFFFFFFFFu;
            *bias0 = 2;
            *bias1 = -2;
            break;
        case NPU_MODEL_RUNTIME:
            *weight0_a = emu->npu_weight0_a;
            *weight0_b = emu->npu_weight0_b;
            *weight1_a = emu->npu_weight1_a;
            *weight1_b = emu->npu_weight1_b;
            *bias0 = (int32_t)emu->npu_bias0;
            *bias1 = (int32_t)emu->npu_bias1;
            break;
        case NPU_MODEL_BUILTIN_1:
        default:
            *weight0_a = 0x01010101u;
            *weight0_b = 0xFFFFFFFFu;
            *weight1_a = 0xFFFFFFFFu;
            *weight1_b = 0x01010101u;
            *bias0 = 0;
            *bias1 = 0;
            break;
    }
}

static void emu_run_npu(accel_emulator_t *emu) {
    uint32_t weight0_a = 0;
    uint32_t weight0_b = 0;
    uint32_t weight1_a = 0;
    uint32_t weight1_b = 0;
    int32_t bias0 = 0;
    int32_t bias1 = 0;

    emu->npu_busy = true;
    if ((emu->umem_ctrl & (ACCEL_UMEM_CTRL_ENABLE | ACCEL_UMEM_CTRL_NPU_USE_BUF)) ==
        (ACCEL_UMEM_CTRL_ENABLE | ACCEL_UMEM_CTRL_NPU_USE_BUF)) {
        emu->npu_input0 = emu_umem_read32(emu, emu->umem_npu_input_offset + 0u);
        emu->npu_input1 = emu_umem_read32(emu, emu->umem_npu_input_offset + 4u);
        if (emu->npu_model_id == NPU_MODEL_RUNTIME) {
            emu->npu_weight0_a = emu_umem_read32(emu, emu->umem_npu_weight_offset + 0u);
            emu->npu_weight0_b = emu_umem_read32(emu, emu->umem_npu_weight_offset + 4u);
            emu->npu_weight1_a = emu_umem_read32(emu, emu->umem_npu_weight_offset + 8u);
            emu->npu_weight1_b = emu_umem_read32(emu, emu->umem_npu_weight_offset + 12u);
            emu->npu_bias0 = emu_umem_read32(emu, emu->umem_npu_weight_offset + 16u);
            emu->npu_bias1 = emu_umem_read32(emu, emu->umem_npu_weight_offset + 20u);
        }
    }
    emu_select_npu_weights(emu, emu->npu_model_id, &weight0_a, &weight0_b, &weight1_a, &weight1_b, &bias0, &bias1);
    emu->npu_logit0 = dot4_i8(emu->npu_input0, weight0_a) + dot4_i8(emu->npu_input1, weight0_b) + bias0;
    emu->npu_logit1 = dot4_i8(emu->npu_input0, weight1_a) + dot4_i8(emu->npu_input1, weight1_b) + bias1;
    emu->npu_class_id = (emu->npu_logit1 > emu->npu_logit0) ? 1u : 0u;
    emu->npu_status_word =
        (0x4Eu << 24) |
        ((uint32_t)emu->npu_class_id << 16) |
        ((uint32_t)emu->npu_model_id << 8) |
        (emu->npu_seq_length & 0xFFu);
    if ((emu->umem_ctrl & (ACCEL_UMEM_CTRL_ENABLE | ACCEL_UMEM_CTRL_NPU_USE_BUF)) ==
        (ACCEL_UMEM_CTRL_ENABLE | ACCEL_UMEM_CTRL_NPU_USE_BUF)) {
        emu_umem_write32(emu, emu->umem_npu_output_offset + 0u, emu->npu_status_word);
        emu_umem_write32(emu, emu->umem_npu_output_offset + 4u, (uint32_t)emu->npu_logit0);
        emu_umem_write32(emu, emu->umem_npu_output_offset + 8u, (uint32_t)emu->npu_logit1);
        emu_umem_write32(emu, emu->umem_npu_output_offset + 12u, emu->npu_class_id);
    }
    emu->npu_busy = false;
    emu->npu_done_sticky = true;
}

static void emu_run_gpu_clear(accel_emulator_t *emu) {
    uint32_t fill = (emu->gpu_clear_value & 1u) ? 0xFFFFFFFFu : 0x00000000u;
    emu->gpu_busy = true;
    for (uint32_t row = 0; row < GPU_FB_ROWS; ++row) {
        emu->framebuffer[row] = fill;
    }
    emu->gpu_raster_pixels = 0u;
    emu->gpu_last_area2 = 0;
    emu->gpu_last_bbox = 0u;
    emu->gpu_frame_count += 1u;
    emu_sync_gpu_framebuffer_to_umem(emu);
    emu->gpu_busy = false;
    emu->gpu_done_sticky = true;
}

static void emu_run_gpu_draw(accel_emulator_t *emu) {
    int x0 = emu->gpu_vertex0 & 0xFFu;
    int y0 = (emu->gpu_vertex0 >> 8) & 0xFFu;
    int x1 = emu->gpu_vertex1 & 0xFFu;
    int y1 = (emu->gpu_vertex1 >> 8) & 0xFFu;
    int x2 = emu->gpu_vertex2 & 0xFFu;
    int y2 = (emu->gpu_vertex2 >> 8) & 0xFFu;

    int min_x = x0;
    int max_x = x0;
    int min_y = y0;
    int max_y = y0;
    if (x1 < min_x) min_x = x1;
    if (x2 < min_x) min_x = x2;
    if (x1 > max_x) max_x = x1;
    if (x2 > max_x) max_x = x2;
    if (y1 < min_y) min_y = y1;
    if (y2 < min_y) min_y = y2;
    if (y1 > max_y) max_y = y1;
    if (y2 > max_y) max_y = y2;
    if (min_x < 0) min_x = 0;
    if (min_y < 0) min_y = 0;
    if (max_x >= (int)GPU_FB_COLS) max_x = (int)GPU_FB_COLS - 1;
    if (max_y >= (int)GPU_FB_ROWS) max_y = (int)GPU_FB_ROWS - 1;

    emu->gpu_busy = true;
    emu->gpu_last_area2 = edge_fn(x0, y0, x1, y1, x2, y2);
    emu->gpu_last_bbox =
        ((uint32_t)max_y << 24) |
        ((uint32_t)max_x << 16) |
        ((uint32_t)min_y << 8) |
        (uint32_t)min_x;
    emu->gpu_raster_pixels = 0u;

    for (int y = min_y; y <= max_y; ++y) {
        for (int x = min_x; x <= max_x; ++x) {
            int32_t e0 = edge_fn(x0, y0, x1, y1, x, y);
            int32_t e1 = edge_fn(x1, y1, x2, y2, x, y);
            int32_t e2 = edge_fn(x2, y2, x0, y0, x, y);
            bool inside = false;

            if (emu->gpu_last_area2 > 0) {
                inside = (e0 >= 0) && (e1 >= 0) && (e2 >= 0);
            } else if (emu->gpu_last_area2 < 0) {
                inside = (e0 <= 0) && (e1 <= 0) && (e2 <= 0);
            }

            if (inside) {
                emu->framebuffer[y] |= 1u << x;
                emu->gpu_raster_pixels += 1u;
            }
        }
    }

    emu->gpu_triangles += 1u;
    emu->gpu_frame_count += 1u;
    emu_sync_gpu_framebuffer_to_umem(emu);
    emu->gpu_busy = false;
    emu->gpu_done_sticky = true;
}

static bool emu_cmdq_execute_desc(accel_emulator_t *emu, accel_umem_cmd_desc_t *desc) {
    uint32_t old_umem_ctrl = emu->umem_ctrl;
    uint32_t old_npu_input = emu->umem_npu_input_offset;
    uint32_t old_npu_weight = emu->umem_npu_weight_offset;
    uint32_t old_npu_output = emu->umem_npu_output_offset;
    uint32_t old_gpu_fb = emu->umem_gpu_fb_offset;
    uint8_t old_model_id = emu->npu_model_id;
    uint16_t old_seq_length = emu->npu_seq_length;
    uint8_t old_gpu_cmd = emu->gpu_cmd_opcode;
    uint16_t old_v0 = emu->gpu_vertex0;
    uint16_t old_v1 = emu->gpu_vertex1;
    uint16_t old_v2 = emu->gpu_vertex2;
    uint8_t old_clear = emu->gpu_clear_value;
    uint32_t base_flags = desc->flags & ACCEL_UMEM_CMD_FLAG_MODEL_MASK;
    bool ok = true;

    emu->umem_cmdq_dispatch_status = EMU_DISPATCH_STATUS_BUSY;
    emu->umem_cmdq_dispatch_opcode = desc->opcode;

    switch (desc->opcode) {
        case ACCEL_UMEM_CMD_NOP:
            emu->umem_cmdq_dispatch_status = EMU_DISPATCH_STATUS_IDLE;
            break;
        case ACCEL_UMEM_CMD_NPU_INFER:
            emu->umem_ctrl |= ACCEL_UMEM_CTRL_ENABLE | ACCEL_UMEM_CTRL_NPU_USE_BUF;
            emu->umem_npu_input_offset = desc->src0;
            emu->umem_npu_weight_offset = desc->src1;
            emu->umem_npu_output_offset = desc->dst0;
            emu->umem_cmdq_npu_exec_input_offset = desc->src0;
            emu->umem_cmdq_npu_exec_output_offset = desc->dst0;
            if ((desc->flags & ACCEL_UMEM_CMD_FLAG_MODEL_MASK) != 0u) {
                emu->npu_model_id = desc->flags & ACCEL_UMEM_CMD_FLAG_MODEL_MASK;
            }
            emu->npu_seq_length = (desc->arg0 != 0u) ? (uint16_t)(desc->arg0 & 0xFFFFu) : 8u;
            emu->umem_cmdq_npu_exec_last_model_id = emu->npu_model_id;
            emu->umem_cmdq_npu_exec_status = emu_pack_npu_exec_status(emu, true);
            emu->umem_cmdq_npu_exec_count += 1u;
            emu_run_npu(emu);
            emu->umem_cmdq_npu_exec_status = emu_pack_npu_exec_status(emu, false);
            emu->umem_cmdq_dispatch_npu_count += 1u;
            emu->umem_cmdq_dispatch_status = EMU_DISPATCH_STATUS_IDLE;
            break;
        case ACCEL_UMEM_CMD_GPU_CLEAR:
            emu->umem_ctrl |= ACCEL_UMEM_CTRL_ENABLE | ACCEL_UMEM_CTRL_GPU_USE_BUF;
            if (desc->dst0 != 0u) {
                emu->umem_gpu_fb_offset = desc->dst0;
            }
            emu->gpu_cmd_opcode = GPU_CMD_CLEAR;
            emu->gpu_clear_value = (uint8_t)(desc->arg0 & 0xFFu);
            emu_run_gpu_clear(emu);
            emu->umem_cmdq_dispatch_gpu_count += 1u;
            emu->umem_cmdq_dispatch_status = EMU_DISPATCH_STATUS_IDLE;
            break;
        case ACCEL_UMEM_CMD_GPU_DRAW_TRI:
            emu->umem_ctrl |= ACCEL_UMEM_CTRL_ENABLE | ACCEL_UMEM_CTRL_GPU_USE_BUF;
            if (desc->dst0 != 0u) {
                emu->umem_gpu_fb_offset = desc->dst0;
            }
            emu->gpu_cmd_opcode = GPU_CMD_DRAW_TRI;
            emu->gpu_vertex0 = (uint16_t)(desc->src0 & 0xFFFFu);
            emu->gpu_vertex1 = (uint16_t)(desc->src1 & 0xFFFFu);
            emu->gpu_vertex2 = (uint16_t)(desc->src2 & 0xFFFFu);
            emu_run_gpu_draw(emu);
            emu->umem_cmdq_dispatch_gpu_count += 1u;
            emu->umem_cmdq_dispatch_status = EMU_DISPATCH_STATUS_IDLE;
            break;
        default:
            ok = false;
            emu->umem_cmdq_dispatch_error_count += 1u;
            emu->umem_cmdq_dispatch_status = EMU_DISPATCH_STATUS_ERROR;
            break;
    }

    desc->flags = base_flags | ACCEL_UMEM_CMD_FLAG_DONE | (ok ? 0u : ACCEL_UMEM_CMD_FLAG_ERROR);

    emu->umem_ctrl = old_umem_ctrl;
    emu->umem_npu_input_offset = old_npu_input;
    emu->umem_npu_weight_offset = old_npu_weight;
    emu->umem_npu_output_offset = old_npu_output;
    emu->umem_gpu_fb_offset = old_gpu_fb;
    emu->npu_model_id = old_model_id;
    emu->npu_seq_length = old_seq_length;
    emu->gpu_cmd_opcode = old_gpu_cmd;
    emu->gpu_vertex0 = old_v0;
    emu->gpu_vertex1 = old_v1;
    emu->gpu_vertex2 = old_v2;
    emu->gpu_clear_value = old_clear;
    return ok;
}

static void emu_cmdq_process(accel_emulator_t *emu) {
    uint32_t entry_count = emu_cmdq_entry_count(emu);
    uint32_t safety = entry_count;
    bool error_seen = false;

    emu->umem_cmdq_status = (emu->umem_cmdq_processed & 0xFFFFu) << 16;
    emu->umem_cmdq_status |= CMDQ_STATUS_BUSY;
    emu->umem_cmdq_fetch_status = (emu->umem_cmdq_head == emu->umem_cmdq_tail)
        ? EMU_FETCH_STATUS_IDLE : EMU_FETCH_STATUS_BUSY;
    emu->umem_cmdq_last_beat_count = 0u;

    while ((emu->umem_cmdq_tail != emu->umem_cmdq_head) && (safety != 0u)) {
        accel_umem_cmd_desc_t *desc = emu_cmdq_desc_ptr(emu, emu->umem_cmdq_tail);
        emu->umem_cmdq_last_slot = (uint16_t)(emu->umem_cmdq_tail % entry_count);
        emu->umem_cmdq_last_offset = emu->umem_cmdq_base_offset + (emu->umem_cmdq_last_slot * ACCEL_UMEM_CMDQ_DESC_BYTES);
        emu->umem_cmdq_last_sequence = emu->umem_cmdq_processed;
        emu->umem_cmdq_last_araddr = emu->umem_base_addr + emu->umem_cmdq_last_offset;
        emu->umem_cmdq_last_desc_word0 = desc->opcode;
        emu->umem_cmdq_last_beat_count = 8u;
        bool ok = emu_cmdq_execute_desc(emu, desc);
        if (!ok) {
            error_seen = true;
        }
        emu->umem_cmdq_fetch_status = ok ? EMU_FETCH_STATUS_IDLE : EMU_FETCH_STATUS_ERROR;
        emu->umem_cmdq_tail = (emu->umem_cmdq_tail + 1u) % entry_count;
        emu->umem_cmdq_processed += 1u;
        safety -= 1u;
    }

    if (emu->umem_cmdq_tail != emu->umem_cmdq_head) {
        error_seen = true;
        emu->umem_cmdq_fetch_status = EMU_FETCH_STATUS_ERROR;
    }

    emu_cmdq_refresh_status(emu, error_seen);
}

static uint32_t emu_reg_read(const accel_emulator_t *emu, off_t offset) {
    switch (offset) {
        case REG_ID_VERSION: return 0x5A37100Au;
        case REG_CONTROL: return emu->control_shadow;
        case REG_STATUS:
            return (emu->npu_busy ? STATUS_NPU_BUSY : 0u) |
                   (emu->npu_done_sticky ? STATUS_NPU_DONE : 0u) |
                   (emu->gpu_busy ? STATUS_GPU_BUSY : 0u) |
                   (emu->gpu_done_sticky ? STATUS_GPU_DONE : 0u);
        case REG_NPU_CFG0: return ((uint32_t)emu->npu_seq_length << 16) | emu->npu_model_id;
        case REG_NPU_STATUS_WORD: return emu->npu_status_word;
        case REG_NPU_INPUT0: return emu->npu_input0;
        case REG_NPU_INPUT1: return emu->npu_input1;
        case REG_NPU_LOGIT0: return (uint32_t)emu->npu_logit0;
        case REG_NPU_LOGIT1: return (uint32_t)emu->npu_logit1;
        case REG_NPU_CLASS: return emu->npu_class_id;
        case REG_GPU_CMD: return emu->gpu_cmd_opcode;
        case REG_GPU_TRIANGLES: return emu->gpu_triangles;
        case REG_LEGACY_BOOT: return 0x00000001u;
        case REG_LEGACY_GPIO: return 0xA5A50001u;
        case REG_IRQ_ENABLE: return emu->irq_enable & (IRQ_EN_NPU_DONE | IRQ_EN_GPU_DONE);
        case REG_IRQ_STATUS: {
            uint32_t pending = 0u;
            if (emu->npu_done_sticky) {
                pending |= IRQ_STATUS_NPU_PENDING;
            }
            if (emu->gpu_done_sticky) {
                pending |= IRQ_STATUS_GPU_PENDING;
            }
            if ((emu->npu_done_sticky && (emu->irq_enable & IRQ_EN_NPU_DONE) != 0u) ||
                (emu->gpu_done_sticky && (emu->irq_enable & IRQ_EN_GPU_DONE) != 0u)) {
                pending |= IRQ_STATUS_LINE;
            }
            return pending;
        }
        case REG_GPU_VERTEX0: return emu->gpu_vertex0;
        case REG_GPU_VERTEX1: return emu->gpu_vertex1;
        case REG_GPU_VERTEX2: return emu->gpu_vertex2;
        case REG_GPU_CLEAR_VALUE: return emu->gpu_clear_value;
        case REG_GPU_FRAME_COUNT: return emu->gpu_frame_count;
        case REG_GPU_RASTER_PIXELS: return emu->gpu_raster_pixels;
        case REG_GPU_LAST_AREA2: return (uint32_t)emu->gpu_last_area2;
        case REG_GPU_LAST_BBOX: return emu->gpu_last_bbox;
        case REG_GPU_FB_ROWSEL: return emu->gpu_fb_row_select;
        case REG_GPU_FB_ROWDATA: return emu->framebuffer[emu->gpu_fb_row_select];
        case REG_NPU_WEIGHT0_A: return emu->npu_weight0_a;
        case REG_NPU_WEIGHT0_B: return emu->npu_weight0_b;
        case REG_NPU_WEIGHT1_A: return emu->npu_weight1_a;
        case REG_NPU_WEIGHT1_B: return emu->npu_weight1_b;
        case REG_NPU_BIAS0: return emu->npu_bias0;
        case REG_NPU_BIAS1: return emu->npu_bias1;
        case REG_UMEM_CTRL: return emu->umem_ctrl;
        case REG_UMEM_BASE: return emu->umem_base_addr;
        case REG_UMEM_SIZE: return emu->umem_size_bytes;
        case REG_UMEM_NPU_INPUT: return emu->umem_npu_input_offset;
        case REG_UMEM_NPU_WEIGHT: return emu->umem_npu_weight_offset;
        case REG_UMEM_NPU_OUTPUT: return emu->umem_npu_output_offset;
        case REG_UMEM_GPU_FB: return emu->umem_gpu_fb_offset;
        case REG_UMEM_GPU_FB_PITCH: return emu->umem_gpu_fb_pitch;
        case REG_UMEM_CMDQ_BASE: return emu->umem_cmdq_base_offset;
        case REG_UMEM_CMDQ_SIZE: return emu->umem_cmdq_size_bytes;
        case REG_UMEM_CMDQ_HEAD: return emu->umem_cmdq_head;
        case REG_UMEM_CMDQ_TAIL: return emu->umem_cmdq_tail;
        case REG_UMEM_CMDQ_DOORBELL: return emu->umem_cmdq_doorbell;
        case REG_UMEM_CMDQ_STATUS: return emu->umem_cmdq_status;
        case REG_CMDQ_TAIL_SHADOW: return emu->umem_cmdq_tail;
        case REG_CMDQ_STATUS_SHADOW: return emu->umem_cmdq_status;
        case REG_CMDQ_FETCH_OFFSET: return emu->umem_cmdq_last_offset;
        case REG_CMDQ_FETCH_SEQUENCE: return emu->umem_cmdq_last_sequence;
        case REG_CMDQ_FETCH_SLOT: return emu->umem_cmdq_last_slot;
        case REG_UMEM_FETCH_STATUS: return emu->umem_cmdq_fetch_status;
        case REG_UMEM_FETCH_LAST_ARADDR: return emu->umem_cmdq_last_araddr;
        case REG_UMEM_FETCH_LAST_SEQUENCE: return emu->umem_cmdq_last_sequence;
        case REG_UMEM_FETCH_BEAT_COUNT: return emu->umem_cmdq_last_beat_count;
        case REG_UMEM_FETCH_DESC_WORD0: return emu->umem_cmdq_last_desc_word0;
        case REG_CMDQ_DISPATCH_STATUS: return emu->umem_cmdq_dispatch_status;
        case REG_CMDQ_DISPATCH_OPCODE: return emu->umem_cmdq_dispatch_opcode;
        case REG_CMDQ_DISPATCH_NPU_COUNT: return emu->umem_cmdq_dispatch_npu_count;
        case REG_CMDQ_DISPATCH_GPU_COUNT: return emu->umem_cmdq_dispatch_gpu_count;
        case REG_CMDQ_DISPATCH_ERROR_COUNT: return emu->umem_cmdq_dispatch_error_count;
        case REG_NPU_CMD_EXEC_STATUS: return emu->umem_cmdq_npu_exec_status;
        case REG_NPU_CMD_EXEC_INPUT_OFFSET: return emu->umem_cmdq_npu_exec_input_offset;
        case REG_NPU_CMD_EXEC_OUTPUT_OFFSET: return emu->umem_cmdq_npu_exec_output_offset;
        default: return 0u;
    }
}

static void emu_reg_write(accel_emulator_t *emu, off_t offset, uint32_t value) {
    switch (offset) {
        case REG_CONTROL:
            emu->control_shadow = value;
            if ((value & CTRL_NPU_START) != 0u) {
                emu_run_npu(emu);
            }
            if ((value & CTRL_GPU_START) != 0u) {
                if (emu->gpu_cmd_opcode == GPU_CMD_CLEAR) {
                    emu_run_gpu_clear(emu);
                } else {
                    emu_run_gpu_draw(emu);
                }
            }
            break;
        case REG_STATUS:
            if ((value & STATUS_CLR_NPU_DONE) != 0u) {
                emu->npu_done_sticky = false;
            }
            if ((value & STATUS_CLR_GPU_DONE) != 0u) {
                emu->gpu_done_sticky = false;
            }
            break;
        case REG_NPU_CFG0:
            emu->npu_model_id = value & 0xFFu;
            emu->npu_seq_length = (value >> 16) & 0xFFFFu;
            break;
        case REG_NPU_INPUT0:
            emu->npu_input0 = value;
            break;
        case REG_NPU_INPUT1:
            emu->npu_input1 = value;
            break;
        case REG_GPU_CMD:
            emu->gpu_cmd_opcode = value & 0xFFu;
            break;
        case REG_IRQ_ENABLE:
            emu->irq_enable = value & (IRQ_EN_NPU_DONE | IRQ_EN_GPU_DONE);
            break;
        case REG_GPU_VERTEX0:
            emu->gpu_vertex0 = value & 0xFFFFu;
            break;
        case REG_GPU_VERTEX1:
            emu->gpu_vertex1 = value & 0xFFFFu;
            break;
        case REG_GPU_VERTEX2:
            emu->gpu_vertex2 = value & 0xFFFFu;
            break;
        case REG_GPU_CLEAR_VALUE:
            emu->gpu_clear_value = value & 0xFFu;
            break;
        case REG_GPU_FB_ROWSEL:
            emu->gpu_fb_row_select = value & 0x1Fu;
            break;
        case REG_NPU_WEIGHT0_A:
            emu->npu_weight0_a = value;
            break;
        case REG_NPU_WEIGHT0_B:
            emu->npu_weight0_b = value;
            break;
        case REG_NPU_WEIGHT1_A:
            emu->npu_weight1_a = value;
            break;
        case REG_NPU_WEIGHT1_B:
            emu->npu_weight1_b = value;
            break;
        case REG_NPU_BIAS0:
            emu->npu_bias0 = value;
            break;
        case REG_NPU_BIAS1:
            emu->npu_bias1 = value;
            break;
        case REG_UMEM_CTRL:
            emu->umem_ctrl = value;
            break;
        case REG_UMEM_BASE:
            emu->umem_base_addr = value;
            break;
        case REG_UMEM_SIZE:
            emu->umem_size_bytes = value;
            break;
        case REG_UMEM_NPU_INPUT:
            emu->umem_npu_input_offset = value;
            break;
        case REG_UMEM_NPU_WEIGHT:
            emu->umem_npu_weight_offset = value;
            break;
        case REG_UMEM_NPU_OUTPUT:
            emu->umem_npu_output_offset = value;
            break;
        case REG_UMEM_GPU_FB:
            emu->umem_gpu_fb_offset = value;
            break;
        case REG_UMEM_GPU_FB_PITCH:
            emu->umem_gpu_fb_pitch = value;
            break;
        case REG_UMEM_CMDQ_BASE:
            emu->umem_cmdq_base_offset = value;
            emu_cmdq_refresh_status(emu, false);
            break;
        case REG_UMEM_CMDQ_SIZE:
            emu->umem_cmdq_size_bytes = value;
            emu_cmdq_refresh_status(emu, false);
            break;
        case REG_UMEM_CMDQ_HEAD:
            emu->umem_cmdq_head = value;
            emu_cmdq_refresh_status(emu, false);
            break;
        case REG_UMEM_CMDQ_TAIL:
            emu->umem_cmdq_tail = value;
            emu_cmdq_refresh_status(emu, false);
            break;
        case REG_UMEM_CMDQ_DOORBELL:
            emu->umem_cmdq_doorbell = value;
            if (((emu->umem_ctrl & ACCEL_UMEM_CTRL_CMDQ_ENABLE) != 0u) && (value != 0u)) {
                emu_cmdq_process(emu);
            } else {
                emu_cmdq_refresh_status(emu, false);
            }
            break;
        default:
            break;
    }
}

static uint32_t reg_read(accel_backend_t *backend, off_t offset) {
    if (backend->emulate) {
        return emu_reg_read(&backend->emu, offset);
    }
    return *(volatile uint32_t *)(backend->mmio + offset);
}

static void reg_write(accel_backend_t *backend, off_t offset, uint32_t value) {
    if (backend->emulate) {
        emu_reg_write(&backend->emu, offset, value);
        return;
    }
    *(volatile uint32_t *)(backend->mmio + offset) = value;
}

static void read_framebuffer_rows(accel_backend_t *backend, uint32_t rows[GPU_FB_ROWS]) {
    for (uint32_t row = 0; row < GPU_FB_ROWS; ++row) {
        reg_write(backend, REG_GPU_FB_ROWSEL, row);
        rows[row] = reg_read(backend, REG_GPU_FB_ROWDATA);
    }
}

static void write_framebuffer_pbm(const char *path, const uint32_t rows[GPU_FB_ROWS]) {
    FILE *fp = fopen(path, "w");
    if (fp == NULL) {
        fprintf(stderr, "open %s failed: %s\n", path, strerror(errno));
        exit(1);
    }

    fprintf(fp, "P1\n%u %u\n", GPU_FB_COLS, GPU_FB_ROWS);
    for (uint32_t y = 0; y < GPU_FB_ROWS; ++y) {
        for (uint32_t x = 0; x < GPU_FB_COLS; ++x) {
            fputc((rows[y] & (1u << x)) ? '1' : '0', fp);
            if (x + 1 != GPU_FB_COLS) {
                fputc(' ', fp);
            }
        }
        fputc('\n', fp);
    }

    fclose(fp);
}

static void wait_until_done_poll(accel_backend_t *backend, uint32_t busy_mask, uint32_t done_mask) {
    for (int i = 0; i < 1000000; ++i) {
        uint32_t status = reg_read(backend, REG_STATUS);
        if ((status & busy_mask) == 0u && (status & done_mask) != 0u) {
            return;
        }
        usleep(100);
    }

    fprintf(stderr, "timeout waiting for accelerator completion\n");
    exit(1);
}

static void uio_enable_irq(int fd) {
    uint32_t enable = 1;
    ssize_t written = write(fd, &enable, sizeof(enable));
    if (written != (ssize_t)sizeof(enable)) {
        fprintf(stderr, "uio irq enable failed: %s\n", strerror(errno));
        exit(1);
    }
}

static void wait_until_done(accel_backend_t *backend, int uio_fd, bool use_irq,
                            uint32_t busy_mask, uint32_t done_mask, const char *label) {
    if (!use_irq) {
        wait_until_done_poll(backend, busy_mask, done_mask);
        return;
    }

    if (backend->emulate) {
        printf("%s irq_count    = 1\n", label);
        wait_until_done_poll(backend, busy_mask, done_mask);
        return;
    }

    uint32_t irq_count = 0;
    ssize_t received = read(uio_fd, &irq_count, sizeof(irq_count));
    if (received != (ssize_t)sizeof(irq_count)) {
        fprintf(stderr, "uio irq wait failed for %s: %s\n", label, strerror(errno));
        exit(1);
    }

    printf("%s irq_count    = %u\n", label, irq_count);
    wait_until_done_poll(backend, busy_mask, done_mask);
}

static void write_runtime_model(accel_backend_t *backend) {
    reg_write(backend, REG_NPU_WEIGHT0_A, 0x00020002u);
    reg_write(backend, REG_NPU_WEIGHT0_B, 0x00020002u);
    reg_write(backend, REG_NPU_WEIGHT1_A, 0x02000200u);
    reg_write(backend, REG_NPU_WEIGHT1_B, 0x02000200u);
    reg_write(backend, REG_NPU_BIAS0, 0u);
    reg_write(backend, REG_NPU_BIAS1, 0u);
}

static void run_npu_sample(accel_backend_t *backend, int uio_fd, bool use_irq,
                           const char *label, uint8_t model_id, uint32_t input0, uint32_t input1) {
    if (use_irq && !backend->emulate) {
        uio_enable_irq(uio_fd);
    }

    reg_write(backend, REG_NPU_CFG0, (8u << 16) | model_id);
    reg_write(backend, REG_NPU_INPUT0, input0);
    reg_write(backend, REG_NPU_INPUT1, input1);
    reg_write(backend, REG_CONTROL, CTRL_NPU_START);
    wait_until_done(backend, uio_fd, use_irq, STATUS_NPU_BUSY, STATUS_NPU_DONE, label);

    printf("npu_model_id    = 0x%02x\n", model_id);
    printf("npu_status_word = 0x%08x\n", reg_read(backend, REG_NPU_STATUS_WORD));
    printf("npu_logit0      = %d\n", (int32_t)reg_read(backend, REG_NPU_LOGIT0));
    printf("npu_logit1      = %d\n", (int32_t)reg_read(backend, REG_NPU_LOGIT1));
    printf("npu_class       = %u\n", reg_read(backend, REG_NPU_CLASS) & 0xffu);
    printf("irq_status      = 0x%08x\n", reg_read(backend, REG_IRQ_STATUS));
    reg_write(backend, REG_STATUS, STATUS_CLR_NPU_DONE);
}

static void run_runtime_npu_demo(accel_backend_t *backend, int uio_fd, bool use_irq) {
    write_runtime_model(backend);
    printf("runtime_w0_a    = 0x%08x\n", reg_read(backend, REG_NPU_WEIGHT0_A));
    printf("runtime_w0_b    = 0x%08x\n", reg_read(backend, REG_NPU_WEIGHT0_B));
    printf("runtime_w1_a    = 0x%08x\n", reg_read(backend, REG_NPU_WEIGHT1_A));
    printf("runtime_w1_b    = 0x%08x\n", reg_read(backend, REG_NPU_WEIGHT1_B));

    printf("\n-- runtime sample even-lanes --\n");
    run_npu_sample(backend, uio_fd, use_irq, "npu_runtime_even", NPU_MODEL_RUNTIME, 0x00020001u, 0x00040003u);

    printf("\n-- runtime sample odd-lanes --\n");
    run_npu_sample(backend, uio_fd, use_irq, "npu_runtime_odd", NPU_MODEL_RUNTIME, 0x02000100u, 0x04000300u);
}

static void configure_unified_memory(accel_backend_t *backend) {
    reg_write(backend, REG_UMEM_BASE, ACCEL_UMEM_DEFAULT_BASE);
    reg_write(backend, REG_UMEM_SIZE, ACCEL_UMEM_BYTES);
    reg_write(backend, REG_UMEM_NPU_INPUT, ACCEL_UMEM_NPU_INPUT_OFFSET);
    reg_write(backend, REG_UMEM_NPU_WEIGHT, ACCEL_UMEM_NPU_WEIGHT_OFFSET);
    reg_write(backend, REG_UMEM_NPU_OUTPUT, ACCEL_UMEM_NPU_OUTPUT_OFFSET);
    reg_write(backend, REG_UMEM_GPU_FB, ACCEL_UMEM_GPU_FB_OFFSET);
    reg_write(backend, REG_UMEM_GPU_FB_PITCH, ACCEL_UMEM_GPU_FB_PITCH);
    reg_write(backend, REG_UMEM_CMDQ_BASE, ACCEL_UMEM_CMDQ_OFFSET);
    reg_write(backend, REG_UMEM_CMDQ_SIZE, ACCEL_UMEM_CMDQ_BYTES);
    reg_write(backend, REG_UMEM_CMDQ_HEAD, 0u);
    reg_write(backend, REG_UMEM_CMDQ_TAIL, 0u);
    reg_write(backend, REG_UMEM_CMDQ_DOORBELL, 0u);
    reg_write(backend, REG_UMEM_CTRL,
              ACCEL_UMEM_CTRL_ENABLE | ACCEL_UMEM_CTRL_NPU_USE_BUF | ACCEL_UMEM_CTRL_GPU_USE_BUF);
}

static void write_umem_runtime_model(accel_emulator_t *emu, uint32_t weight_offset) {
    emu_umem_write32(emu, weight_offset + 0u, 0x00020002u);
    emu_umem_write32(emu, weight_offset + 4u, 0x00020002u);
    emu_umem_write32(emu, weight_offset + 8u, 0x02000200u);
    emu_umem_write32(emu, weight_offset + 12u, 0x02000200u);
    emu_umem_write32(emu, weight_offset + 16u, 0u);
    emu_umem_write32(emu, weight_offset + 20u, 0u);
}

static void write_umem_npu_input(accel_emulator_t *emu, uint32_t input_offset, uint32_t input0, uint32_t input1) {
    emu_umem_write32(emu, input_offset + 0u, input0);
    emu_umem_write32(emu, input_offset + 4u, input1);
}

static void read_umem_framebuffer_rows_at(accel_backend_t *backend, uint32_t fb_offset,
                                          uint32_t pitch_bytes, uint32_t rows[GPU_FB_ROWS]) {
    if (!backend->emulate) {
        memset(rows, 0, GPU_FB_ROWS * sizeof(rows[0]));
        return;
    }

    for (uint32_t row = 0; row < GPU_FB_ROWS; ++row) {
        rows[row] = emu_umem_read32(&backend->emu, fb_offset + row * pitch_bytes);
    }
}

static void read_umem_framebuffer_rows(accel_backend_t *backend, uint32_t rows[GPU_FB_ROWS]) {
    read_umem_framebuffer_rows_at(backend, backend->emu.umem_gpu_fb_offset, backend->emu.umem_gpu_fb_pitch, rows);
}

static void run_unified_memory_demo(accel_backend_t *backend, int uio_fd, bool use_irq, const char *pbm_path) {
    uint32_t umem_rows[GPU_FB_ROWS];

    printf("umem_base       = 0x%08x\n", reg_read(backend, REG_UMEM_BASE));
    printf("umem_size       = 0x%08x\n", reg_read(backend, REG_UMEM_SIZE));
    printf("umem_npu_in     = 0x%08x\n", reg_read(backend, REG_UMEM_NPU_INPUT));
    printf("umem_npu_weight = 0x%08x\n", reg_read(backend, REG_UMEM_NPU_WEIGHT));
    printf("umem_npu_out    = 0x%08x\n", reg_read(backend, REG_UMEM_NPU_OUTPUT));
    printf("umem_gpu_fb     = 0x%08x\n", reg_read(backend, REG_UMEM_GPU_FB));
    printf("umem_gpu_pitch  = 0x%08x\n", reg_read(backend, REG_UMEM_GPU_FB_PITCH));
    printf("umem_ctrl       = 0x%08x\n", reg_read(backend, REG_UMEM_CTRL));

    if (!backend->emulate) {
        printf("umem_note       = functional unified-memory path is emulation-backed until AXI master/DMA lands\n");
        return;
    }

    emu_umem_write32(&backend->emu, backend->emu.umem_npu_input_offset + 0u, 0x00020001u);
    emu_umem_write32(&backend->emu, backend->emu.umem_npu_input_offset + 4u, 0x00040003u);
    emu_umem_write32(&backend->emu, backend->emu.umem_npu_weight_offset + 0u, 0x00020002u);
    emu_umem_write32(&backend->emu, backend->emu.umem_npu_weight_offset + 4u, 0x00020002u);
    emu_umem_write32(&backend->emu, backend->emu.umem_npu_weight_offset + 8u, 0x02000200u);
    emu_umem_write32(&backend->emu, backend->emu.umem_npu_weight_offset + 12u, 0x02000200u);
    emu_umem_write32(&backend->emu, backend->emu.umem_npu_weight_offset + 16u, 0u);
    emu_umem_write32(&backend->emu, backend->emu.umem_npu_weight_offset + 20u, 0u);

    if (use_irq) {
        printf("umem_npu irq_count    = 1\n");
    }
    reg_write(backend, REG_NPU_CFG0, (8u << 16) | NPU_MODEL_RUNTIME);
    reg_write(backend, REG_CONTROL, CTRL_NPU_START);
    wait_until_done(backend, uio_fd, false, STATUS_NPU_BUSY, STATUS_NPU_DONE, "umem_npu");
    printf("umem_status_word = 0x%08x\n", emu_umem_read32(&backend->emu, backend->emu.umem_npu_output_offset + 0u));
    printf("umem_logit0      = %d\n", (int32_t)emu_umem_read32(&backend->emu, backend->emu.umem_npu_output_offset + 4u));
    printf("umem_logit1      = %d\n", (int32_t)emu_umem_read32(&backend->emu, backend->emu.umem_npu_output_offset + 8u));
    printf("umem_class       = %u\n", emu_umem_read32(&backend->emu, backend->emu.umem_npu_output_offset + 12u));
    reg_write(backend, REG_STATUS, STATUS_CLR_NPU_DONE);

    reg_write(backend, REG_GPU_CLEAR_VALUE, 0u);
    reg_write(backend, REG_GPU_CMD, GPU_CMD_CLEAR);
    if (use_irq) {
        printf("umem_gpu_clear irq_count = 1\n");
    }
    reg_write(backend, REG_CONTROL, CTRL_GPU_START);
    wait_until_done(backend, uio_fd, false, STATUS_GPU_BUSY, STATUS_GPU_DONE, "umem_gpu_clear");
    reg_write(backend, REG_STATUS, STATUS_CLR_GPU_DONE);

    reg_write(backend, REG_GPU_VERTEX0, pack_xy(2u, 2u));
    reg_write(backend, REG_GPU_VERTEX1, pack_xy(10u, 2u));
    reg_write(backend, REG_GPU_VERTEX2, pack_xy(2u, 10u));
    reg_write(backend, REG_GPU_CMD, GPU_CMD_DRAW_TRI);
    if (use_irq) {
        printf("umem_gpu_draw irq_count  = 1\n");
    }
    reg_write(backend, REG_CONTROL, CTRL_GPU_START);
    wait_until_done(backend, uio_fd, false, STATUS_GPU_BUSY, STATUS_GPU_DONE, "umem_gpu_draw");
    read_umem_framebuffer_rows(backend, umem_rows);
    printf("umem_gpu_row02  = 0x%08x\n", umem_rows[2]);
    printf("umem_gpu_row03  = 0x%08x\n", umem_rows[3]);
    printf("umem_gpu_row10  = 0x%08x\n", umem_rows[10]);
    if (pbm_path != NULL) {
        char umem_pbm_path[1024];
        snprintf(umem_pbm_path, sizeof(umem_pbm_path), "%s.umem.pbm", pbm_path);
        write_framebuffer_pbm(umem_pbm_path, umem_rows);
        printf("umem_gpu_pbm    = %s\n", umem_pbm_path);
    }
    reg_write(backend, REG_STATUS, STATUS_CLR_GPU_DONE);
}

static void run_unified_command_queue_demo(accel_backend_t *backend, const char *pbm_path) {
    const uint32_t q_input_offset = 0x00000400u;
    const uint32_t q_weight_offset = 0x00000420u;
    const uint32_t q_output_offset = 0x00000480u;
    const uint32_t q_fb_offset = 0x00001200u;
    const uint32_t q_pitch = ACCEL_UMEM_GPU_FB_PITCH;
    accel_umem_cmd_desc_t *queue = NULL;
    uint32_t q_rows[GPU_FB_ROWS];

    printf("cmdq_base       = 0x%08x\n", reg_read(backend, REG_UMEM_CMDQ_BASE));
    printf("cmdq_size       = 0x%08x\n", reg_read(backend, REG_UMEM_CMDQ_SIZE));
    printf("cmdq_status     = 0x%08x\n", reg_read(backend, REG_UMEM_CMDQ_STATUS));

    if (!backend->emulate) {
        printf("cmdq_note       = unified command queue executes in emulation until AXI master/DMA is wired\n");
        return;
    }

    reg_write(backend, REG_UMEM_CTRL,
              ACCEL_UMEM_CTRL_ENABLE |
              ACCEL_UMEM_CTRL_NPU_USE_BUF |
              ACCEL_UMEM_CTRL_GPU_USE_BUF |
              ACCEL_UMEM_CTRL_CMDQ_ENABLE);
    reg_write(backend, REG_UMEM_CMDQ_HEAD, 0u);
    reg_write(backend, REG_UMEM_CMDQ_TAIL, 0u);
    reg_write(backend, REG_UMEM_CMDQ_DOORBELL, 0u);

    write_umem_npu_input(&backend->emu, q_input_offset, 0x00020001u, 0x00040003u);
    write_umem_runtime_model(&backend->emu, q_weight_offset);

    queue = (accel_umem_cmd_desc_t *)(void *)(backend->emu.unified_mem + backend->emu.umem_cmdq_base_offset);
    memset(queue, 0, backend->emu.umem_cmdq_size_bytes);

    queue[0].opcode = ACCEL_UMEM_CMD_GPU_CLEAR;
    queue[0].dst0 = q_fb_offset;
    queue[0].arg0 = 0u;

    queue[1].opcode = ACCEL_UMEM_CMD_GPU_DRAW_TRI;
    queue[1].src0 = pack_xy(2u, 2u);
    queue[1].src1 = pack_xy(10u, 2u);
    queue[1].src2 = pack_xy(2u, 10u);
    queue[1].dst0 = q_fb_offset;

    queue[2].opcode = ACCEL_UMEM_CMD_NPU_INFER;
    queue[2].flags = NPU_MODEL_RUNTIME;
    queue[2].src0 = q_input_offset;
    queue[2].src1 = q_weight_offset;
    queue[2].dst0 = q_output_offset;
    queue[2].arg0 = 8u;

    reg_write(backend, REG_UMEM_CMDQ_HEAD, 3u);
    reg_write(backend, REG_UMEM_CMDQ_DOORBELL, 3u);

    printf("cmdq_head       = 0x%08x\n", reg_read(backend, REG_UMEM_CMDQ_HEAD));
    printf("cmdq_tail       = 0x%08x\n", reg_read(backend, REG_UMEM_CMDQ_TAIL));
    printf("cmdq_status     = 0x%08x\n", reg_read(backend, REG_UMEM_CMDQ_STATUS));
    printf("cmdq_tail_dbg   = 0x%08x\n", reg_read(backend, REG_CMDQ_TAIL_SHADOW));
    printf("cmdq_status_dbg = 0x%08x\n", reg_read(backend, REG_CMDQ_STATUS_SHADOW));
    printf("cmdq_fetch_off  = 0x%08x\n", reg_read(backend, REG_CMDQ_FETCH_OFFSET));
    printf("cmdq_fetch_seq  = 0x%08x\n", reg_read(backend, REG_CMDQ_FETCH_SEQUENCE));
    printf("cmdq_fetch_slot = 0x%08x\n", reg_read(backend, REG_CMDQ_FETCH_SLOT));
    printf("cmdq_axi_status = 0x%08x\n", reg_read(backend, REG_UMEM_FETCH_STATUS));
    printf("cmdq_axi_araddr = 0x%08x\n", reg_read(backend, REG_UMEM_FETCH_LAST_ARADDR));
    printf("cmdq_axi_seq    = 0x%08x\n", reg_read(backend, REG_UMEM_FETCH_LAST_SEQUENCE));
    printf("cmdq_axi_beats  = %u\n", reg_read(backend, REG_UMEM_FETCH_BEAT_COUNT));
    printf("cmdq_axi_desc0  = 0x%08x\n", reg_read(backend, REG_UMEM_FETCH_DESC_WORD0));
    printf("cmdq_dispatch_status = 0x%08x\n", reg_read(backend, REG_CMDQ_DISPATCH_STATUS));
    printf("cmdq_dispatch_opcode = 0x%08x\n", reg_read(backend, REG_CMDQ_DISPATCH_OPCODE));
    printf("cmdq_dispatch_npu    = %u\n", reg_read(backend, REG_CMDQ_DISPATCH_NPU_COUNT));
    printf("cmdq_dispatch_gpu    = %u\n", reg_read(backend, REG_CMDQ_DISPATCH_GPU_COUNT));
    printf("cmdq_dispatch_err    = %u\n", reg_read(backend, REG_CMDQ_DISPATCH_ERROR_COUNT));
    printf("cmdq_npu_exec_status = 0x%08x\n", reg_read(backend, REG_NPU_CMD_EXEC_STATUS));
    printf("cmdq_npu_exec_in     = 0x%08x\n", reg_read(backend, REG_NPU_CMD_EXEC_INPUT_OFFSET));
    printf("cmdq_npu_exec_out    = 0x%08x\n", reg_read(backend, REG_NPU_CMD_EXEC_OUTPUT_OFFSET));
    printf("cmdq_desc0      = 0x%08x\n", queue[0].flags);
    printf("cmdq_desc1      = 0x%08x\n", queue[1].flags);
    printf("cmdq_desc2      = 0x%08x\n", queue[2].flags);
    printf("cmdq_status_word = 0x%08x\n", emu_umem_read32(&backend->emu, q_output_offset + 0u));
    printf("cmdq_logit0      = %d\n", (int32_t)emu_umem_read32(&backend->emu, q_output_offset + 4u));
    printf("cmdq_logit1      = %d\n", (int32_t)emu_umem_read32(&backend->emu, q_output_offset + 8u));
    printf("cmdq_class       = %u\n", emu_umem_read32(&backend->emu, q_output_offset + 12u));

    read_umem_framebuffer_rows_at(backend, q_fb_offset, q_pitch, q_rows);
    printf("cmdq_gpu_row02  = 0x%08x\n", q_rows[2]);
    printf("cmdq_gpu_row03  = 0x%08x\n", q_rows[3]);
    printf("cmdq_gpu_row10  = 0x%08x\n", q_rows[10]);
    if (pbm_path != NULL) {
        char cmdq_pbm_path[1024];
        snprintf(cmdq_pbm_path, sizeof(cmdq_pbm_path), "%s.cmdq.pbm", pbm_path);
        write_framebuffer_pbm(cmdq_pbm_path, q_rows);
        printf("cmdq_gpu_pbm    = %s\n", cmdq_pbm_path);
    }
}

static void dump_framebuffer_rows(const uint32_t rows[GPU_FB_ROWS]) {
    printf("\nframebuffer 32x32 ('.' empty, '#' filled)\n");
    for (uint32_t row = 0; row < GPU_FB_ROWS; ++row) {
        printf("%02u ", row);
        for (uint32_t x = 0; x < GPU_FB_COLS; ++x) {
            putchar((rows[row] & (1u << x)) ? '#' : '.');
        }
        putchar('\n');
    }
}

static void run_gpu_demo(accel_backend_t *backend, int uio_fd, bool use_irq, const char *pbm_path) {
    uint32_t fb_rows[GPU_FB_ROWS];

    reg_write(backend, REG_GPU_CLEAR_VALUE, 0u);
    reg_write(backend, REG_GPU_CMD, GPU_CMD_CLEAR);
    if (use_irq && !backend->emulate) {
        uio_enable_irq(uio_fd);
    }
    reg_write(backend, REG_CONTROL, CTRL_GPU_START);
    wait_until_done(backend, uio_fd, use_irq, STATUS_GPU_BUSY, STATUS_GPU_DONE, "gpu_clear");
    printf("gpu_frame_count = %u\n", reg_read(backend, REG_GPU_FRAME_COUNT));
    printf("irq_status      = 0x%08x\n", reg_read(backend, REG_IRQ_STATUS));
    reg_write(backend, REG_STATUS, STATUS_CLR_GPU_DONE);

    reg_write(backend, REG_GPU_VERTEX0, pack_xy(2u, 2u));
    reg_write(backend, REG_GPU_VERTEX1, pack_xy(10u, 2u));
    reg_write(backend, REG_GPU_VERTEX2, pack_xy(2u, 10u));
    reg_write(backend, REG_GPU_CMD, GPU_CMD_DRAW_TRI);
    if (use_irq && !backend->emulate) {
        uio_enable_irq(uio_fd);
    }
    reg_write(backend, REG_CONTROL, CTRL_GPU_START);
    wait_until_done(backend, uio_fd, use_irq, STATUS_GPU_BUSY, STATUS_GPU_DONE, "gpu_draw");

    printf("gpu_triangles   = %u\n", reg_read(backend, REG_GPU_TRIANGLES));
    printf("gpu_frame_count = %u\n", reg_read(backend, REG_GPU_FRAME_COUNT));
    printf("gpu_pixels      = %u\n", reg_read(backend, REG_GPU_RASTER_PIXELS));
    printf("gpu_area2       = %d\n", (int32_t)reg_read(backend, REG_GPU_LAST_AREA2));
    printf("gpu_bbox        = 0x%08x\n", reg_read(backend, REG_GPU_LAST_BBOX));
    printf("irq_status      = 0x%08x\n", reg_read(backend, REG_IRQ_STATUS));

    read_framebuffer_rows(backend, fb_rows);
    dump_framebuffer_rows(fb_rows);
    if (pbm_path != NULL) {
        write_framebuffer_pbm(pbm_path, fb_rows);
        printf("gpu_pbm         = %s\n", pbm_path);
    }
    reg_write(backend, REG_STATUS, STATUS_CLR_GPU_DONE);
}

int main(int argc, char **argv) {
    const char *uio_path = "/dev/uio0";
    const char *pbm_path = NULL;
    bool use_irq = false;
    bool emulate = false;
    accel_backend_t backend;
    int fd = -1;

    memset(&backend, 0, sizeof(backend));

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--irq") == 0) {
            use_irq = true;
        } else if (strcmp(argv[i], "--pbm") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "--pbm needs an output path\n");
                return 1;
            }
            pbm_path = argv[++i];
        } else if (strcmp(argv[i], "--emulate") == 0) {
            emulate = true;
        } else {
            uio_path = argv[i];
        }
    }

    backend.emulate = emulate;
    if (backend.emulate) {
        emu_init(&backend.emu);
    } else {
        fd = open(uio_path, O_RDWR | O_SYNC);
        if (fd < 0) {
            fprintf(stderr, "open %s failed: %s\n", uio_path, strerror(errno));
            return 1;
        }

        backend.mmio = mmap(NULL, ACCEL_MAP_BYTES, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (backend.mmio == MAP_FAILED) {
            fprintf(stderr, "mmap failed: %s\n", strerror(errno));
            close(fd);
            return 1;
        }
    }

    printf("backend         = %s\n", backend.emulate ? "emulated-mmio" : "uio-mmio");
    printf("id_version      = 0x%08x\n", reg_read(&backend, REG_ID_VERSION));
    printf("legacy_boot     = 0x%08x\n", reg_read(&backend, REG_LEGACY_BOOT));
    printf("legacy_gpio     = 0x%08x\n", reg_read(&backend, REG_LEGACY_GPIO));
    printf("irq_mode        = %s\n", use_irq ? "uio-interrupt" : "polling");

    reg_write(&backend, REG_IRQ_ENABLE, use_irq ? (IRQ_EN_NPU_DONE | IRQ_EN_GPU_DONE) : 0u);
    printf("irq_enable      = 0x%08x\n", reg_read(&backend, REG_IRQ_ENABLE));

    printf("\n== NPU sample A ==\n");
    run_npu_sample(&backend, fd, use_irq, "npu_sample_a", NPU_MODEL_BUILTIN_1, 0x04030201u, 0x00000000u);

    printf("\n== NPU sample B ==\n");
    run_npu_sample(&backend, fd, use_irq, "npu_sample_b", NPU_MODEL_BUILTIN_1, 0x00000000u, 0x04030201u);

    printf("\n== NPU runtime model demo ==\n");
    run_runtime_npu_demo(&backend, fd, use_irq);

    printf("\n== Unified memory demo ==\n");
    configure_unified_memory(&backend);
    run_unified_memory_demo(&backend, fd, use_irq, pbm_path);

    printf("\n== Unified command queue demo ==\n");
    run_unified_command_queue_demo(&backend, pbm_path);

    printf("\n== GPU triangle demo ==\n");
    run_gpu_demo(&backend, fd, use_irq, pbm_path);

    if (!backend.emulate) {
        munmap((void *)backend.mmio, ACCEL_MAP_BYTES);
        close(fd);
    }
    return 0;
}
