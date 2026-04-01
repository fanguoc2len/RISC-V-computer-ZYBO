#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "../include/accel_cmdq_host.h"
#include "../include/accel_unified_mem.h"

typedef struct {
    uint32_t regs[ACCEL_MAP_BYTES / 4];
    uint8_t umem[ACCEL_UMEM_BYTES];
} fake_platform_t;

static uint32_t fake_reg_read(void *ctx, uint32_t offset) {
    fake_platform_t *plat = (fake_platform_t *)ctx;
    return plat->regs[offset >> 2];
}

static void fake_reg_write(void *ctx, uint32_t offset, uint32_t value) {
    fake_platform_t *plat = (fake_platform_t *)ctx;
    plat->regs[offset >> 2] = value;
}

int main(void) {
    fake_platform_t plat;
    accel_cmdq_host_t host;
    const accel_umem_cmd_desc_t *desc0;
    const accel_umem_cmd_desc_t *desc1;
    const accel_umem_cmd_desc_t *desc2;

    memset(&plat, 0, sizeof(plat));
    plat.regs[REG_UMEM_CMDQ_BASE >> 2] = ACCEL_UMEM_CMDQ_OFFSET;
    plat.regs[REG_UMEM_CMDQ_SIZE >> 2] = ACCEL_UMEM_CMDQ_BYTES;
    plat.regs[REG_UMEM_CMDQ_HEAD >> 2] = 0u;
    plat.regs[REG_UMEM_CMDQ_TAIL >> 2] = 0u;

    if (accel_cmdq_host_init(&host, fake_reg_read, fake_reg_write, &plat, plat.umem, sizeof(plat.umem)) != 0) {
        fprintf(stderr, "init failed\n");
        return 1;
    }

    if (accel_cmdq_host_reset(&host) != 0) {
        fprintf(stderr, "reset failed\n");
        return 1;
    }

    if (accel_cmdq_host_push_gpu_clear(&host, 0x00001200u, 0u) != 0) {
        fprintf(stderr, "push clear failed\n");
        return 1;
    }
    if (accel_cmdq_host_push_gpu_draw_tri(&host, 0x00000202u, 0x0000020Au, 0x00000A02u, 0x00001200u) != 0) {
        fprintf(stderr, "push draw failed\n");
        return 1;
    }
    if (accel_cmdq_host_push_npu_infer(&host, 0x80u, 8u, 0x00000400u, 0x00000420u, 0x00000480u) != 0) {
        fprintf(stderr, "push npu failed\n");
        return 1;
    }
    if (accel_cmdq_host_submit(&host, 3u) != 0) {
        fprintf(stderr, "submit failed\n");
        return 1;
    }

    desc0 = accel_cmdq_host_desc(&host, 0u);
    desc1 = accel_cmdq_host_desc(&host, 1u);
    desc2 = accel_cmdq_host_desc(&host, 2u);
    if (desc0 == NULL || desc1 == NULL || desc2 == NULL) {
        fprintf(stderr, "descriptor lookup failed\n");
        return 1;
    }

    if (plat.regs[REG_UMEM_CMDQ_HEAD >> 2] != 3u || plat.regs[REG_UMEM_CMDQ_DOORBELL >> 2] != 3u) {
        fprintf(stderr, "head/doorbell mismatch: head=%u doorbell=%u\n",
                plat.regs[REG_UMEM_CMDQ_HEAD >> 2], plat.regs[REG_UMEM_CMDQ_DOORBELL >> 2]);
        return 1;
    }

    if (desc0->opcode != ACCEL_UMEM_CMD_GPU_CLEAR || desc0->dst0 != 0x00001200u) {
        fprintf(stderr, "descriptor0 mismatch\n");
        return 1;
    }
    if (desc1->opcode != ACCEL_UMEM_CMD_GPU_DRAW_TRI || desc1->src1 != 0x0000020Au) {
        fprintf(stderr, "descriptor1 mismatch\n");
        return 1;
    }
    if (desc2->opcode != ACCEL_UMEM_CMD_NPU_INFER || desc2->flags != 0x80u ||
        desc2->src0 != 0x00000400u || desc2->src1 != 0x00000420u || desc2->dst0 != 0x00000480u) {
        fprintf(stderr, "descriptor2 mismatch\n");
        return 1;
    }

    printf("PASS: command-queue host producer regression completed.\n");
    return 0;
}
