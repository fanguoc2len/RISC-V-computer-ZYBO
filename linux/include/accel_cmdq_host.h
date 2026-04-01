#ifndef ACCEL_CMDQ_HOST_H
#define ACCEL_CMDQ_HOST_H

#include <stddef.h>
#include <stdint.h>

#include "accel_mmio.h"
#include "accel_unified_queue.h"

typedef uint32_t (*accel_cmdq_reg_read_fn)(void *ctx, uint32_t offset);
typedef void (*accel_cmdq_reg_write_fn)(void *ctx, uint32_t offset, uint32_t value);

typedef struct {
    accel_cmdq_reg_read_fn reg_read;
    accel_cmdq_reg_write_fn reg_write;
    void *reg_ctx;
    uint8_t *umem;
    uint32_t umem_bytes;
    uint32_t cmdq_base_offset;
    uint32_t cmdq_size_bytes;
    uint32_t cached_head;
    uint32_t cached_tail;
} accel_cmdq_host_t;

int accel_cmdq_host_init(accel_cmdq_host_t *host,
                         accel_cmdq_reg_read_fn reg_read,
                         accel_cmdq_reg_write_fn reg_write,
                         void *reg_ctx,
                         uint8_t *umem,
                         uint32_t umem_bytes);
int accel_cmdq_host_sync(accel_cmdq_host_t *host);
int accel_cmdq_host_reset(accel_cmdq_host_t *host);
int accel_cmdq_host_push(accel_cmdq_host_t *host, const accel_umem_cmd_desc_t *desc);
int accel_cmdq_host_push_gpu_clear(accel_cmdq_host_t *host, uint32_t fb_offset, uint32_t clear_value);
int accel_cmdq_host_push_gpu_draw_tri(accel_cmdq_host_t *host,
                                      uint32_t vertex0_xy,
                                      uint32_t vertex1_xy,
                                      uint32_t vertex2_xy,
                                      uint32_t fb_offset);
int accel_cmdq_host_push_npu_infer(accel_cmdq_host_t *host,
                                   uint8_t model_id,
                                   uint32_t seq_length,
                                   uint32_t input_offset,
                                   uint32_t weight_offset,
                                   uint32_t output_offset);
int accel_cmdq_host_submit(accel_cmdq_host_t *host, uint32_t doorbell_value);
const accel_umem_cmd_desc_t *accel_cmdq_host_desc(const accel_cmdq_host_t *host, uint32_t slot);
uint32_t accel_cmdq_host_entry_count(const accel_cmdq_host_t *host);

#endif
