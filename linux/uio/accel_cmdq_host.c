#include <errno.h>
#include <stddef.h>
#include <string.h>

#include "../include/accel_cmdq_host.h"

static uint32_t host_limit_bytes(const accel_cmdq_host_t *host) {
    return (host->umem_bytes < host->cmdq_base_offset + host->cmdq_size_bytes)
               ? host->umem_bytes
               : (host->cmdq_base_offset + host->cmdq_size_bytes);
}

uint32_t accel_cmdq_host_entry_count(const accel_cmdq_host_t *host) {
    uint32_t bytes = host->cmdq_size_bytes;
    if (bytes < ACCEL_UMEM_CMDQ_DESC_BYTES) {
        bytes = ACCEL_UMEM_CMDQ_DESC_BYTES;
    }
    bytes -= bytes % ACCEL_UMEM_CMDQ_DESC_BYTES;
    if (bytes == 0u) {
        bytes = ACCEL_UMEM_CMDQ_DESC_BYTES;
    }
    return bytes / ACCEL_UMEM_CMDQ_DESC_BYTES;
}

static accel_umem_cmd_desc_t *host_desc_mut(accel_cmdq_host_t *host, uint32_t slot) {
    uint32_t entry_count = accel_cmdq_host_entry_count(host);
    uint32_t offset = host->cmdq_base_offset + (slot % entry_count) * ACCEL_UMEM_CMDQ_DESC_BYTES;

    if (offset + ACCEL_UMEM_CMDQ_DESC_BYTES > host_limit_bytes(host)) {
        return NULL;
    }

    return (accel_umem_cmd_desc_t *)(void *)(host->umem + offset);
}

const accel_umem_cmd_desc_t *accel_cmdq_host_desc(const accel_cmdq_host_t *host, uint32_t slot) {
    return (const accel_umem_cmd_desc_t *)host_desc_mut((accel_cmdq_host_t *)host, slot);
}

int accel_cmdq_host_sync(accel_cmdq_host_t *host) {
    if (host == NULL || host->reg_read == NULL || host->reg_write == NULL || host->umem == NULL) {
        return -EINVAL;
    }

    host->cmdq_base_offset = host->reg_read(host->reg_ctx, REG_UMEM_CMDQ_BASE);
    host->cmdq_size_bytes = host->reg_read(host->reg_ctx, REG_UMEM_CMDQ_SIZE);
    host->cached_head = host->reg_read(host->reg_ctx, REG_UMEM_CMDQ_HEAD);
    host->cached_tail = host->reg_read(host->reg_ctx, REG_UMEM_CMDQ_TAIL);
    return 0;
}

int accel_cmdq_host_init(accel_cmdq_host_t *host,
                         accel_cmdq_reg_read_fn reg_read,
                         accel_cmdq_reg_write_fn reg_write,
                         void *reg_ctx,
                         uint8_t *umem,
                         uint32_t umem_bytes) {
    if (host == NULL || reg_read == NULL || reg_write == NULL || umem == NULL) {
        return -EINVAL;
    }

    memset(host, 0, sizeof(*host));
    host->reg_read = reg_read;
    host->reg_write = reg_write;
    host->reg_ctx = reg_ctx;
    host->umem = umem;
    host->umem_bytes = umem_bytes;
    return accel_cmdq_host_sync(host);
}

int accel_cmdq_host_reset(accel_cmdq_host_t *host) {
    if (host == NULL) {
        return -EINVAL;
    }
    if (accel_cmdq_host_sync(host) != 0) {
        return -EINVAL;
    }
    if (host->cmdq_base_offset + host->cmdq_size_bytes > host->umem_bytes) {
        return -ERANGE;
    }

    memset(host->umem + host->cmdq_base_offset, 0, host->cmdq_size_bytes);
    host->cached_head = 0u;
    host->cached_tail = 0u;
    host->reg_write(host->reg_ctx, REG_UMEM_CMDQ_HEAD, 0u);
    host->reg_write(host->reg_ctx, REG_UMEM_CMDQ_TAIL, 0u);
    host->reg_write(host->reg_ctx, REG_UMEM_CMDQ_DOORBELL, 0u);
    return 0;
}

int accel_cmdq_host_push(accel_cmdq_host_t *host, const accel_umem_cmd_desc_t *desc) {
    accel_umem_cmd_desc_t *slot = NULL;
    uint32_t entry_count = 0;
    uint32_t next_head = 0;

    if (host == NULL || desc == NULL) {
        return -EINVAL;
    }
    if (host->reg_read == NULL || host->reg_write == NULL || host->umem == NULL) {
        return -EINVAL;
    }

    entry_count = accel_cmdq_host_entry_count(host);
    next_head = (host->cached_head + 1u) % entry_count;
    if (next_head == host->cached_tail) {
        return -ENOSPC;
    }

    slot = host_desc_mut(host, host->cached_head);
    if (slot == NULL) {
        return -ERANGE;
    }

    *slot = *desc;
    host->cached_head = next_head;
    return 0;
}

int accel_cmdq_host_push_gpu_clear(accel_cmdq_host_t *host, uint32_t fb_offset, uint32_t clear_value) {
    accel_umem_cmd_desc_t desc;

    memset(&desc, 0, sizeof(desc));
    desc.opcode = ACCEL_UMEM_CMD_GPU_CLEAR;
    desc.dst0 = fb_offset;
    desc.arg0 = clear_value;
    return accel_cmdq_host_push(host, &desc);
}

int accel_cmdq_host_push_gpu_draw_tri(accel_cmdq_host_t *host,
                                      uint32_t vertex0_xy,
                                      uint32_t vertex1_xy,
                                      uint32_t vertex2_xy,
                                      uint32_t fb_offset) {
    accel_umem_cmd_desc_t desc;

    memset(&desc, 0, sizeof(desc));
    desc.opcode = ACCEL_UMEM_CMD_GPU_DRAW_TRI;
    desc.src0 = vertex0_xy;
    desc.src1 = vertex1_xy;
    desc.src2 = vertex2_xy;
    desc.dst0 = fb_offset;
    return accel_cmdq_host_push(host, &desc);
}

int accel_cmdq_host_push_npu_infer(accel_cmdq_host_t *host,
                                   uint8_t model_id,
                                   uint32_t seq_length,
                                   uint32_t input_offset,
                                   uint32_t weight_offset,
                                   uint32_t output_offset) {
    accel_umem_cmd_desc_t desc;

    memset(&desc, 0, sizeof(desc));
    desc.opcode = ACCEL_UMEM_CMD_NPU_INFER;
    desc.flags = model_id;
    desc.src0 = input_offset;
    desc.src1 = weight_offset;
    desc.dst0 = output_offset;
    desc.arg0 = seq_length;
    return accel_cmdq_host_push(host, &desc);
}

int accel_cmdq_host_submit(accel_cmdq_host_t *host, uint32_t doorbell_value) {
    if (host == NULL || host->reg_write == NULL) {
        return -EINVAL;
    }

    host->reg_write(host->reg_ctx, REG_UMEM_CMDQ_HEAD, host->cached_head);
    host->reg_write(host->reg_ctx, REG_UMEM_CMDQ_DOORBELL, doorbell_value);
    return 0;
}
