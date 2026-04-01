#ifndef ACCEL_UNIFIED_QUEUE_H
#define ACCEL_UNIFIED_QUEUE_H

#include <stdint.h>

#define ACCEL_UMEM_CMDQ_DESC_BYTES    0x00000020u
#define ACCEL_UMEM_CMDQ_ENTRIES       (ACCEL_UMEM_CMDQ_BYTES / ACCEL_UMEM_CMDQ_DESC_BYTES)

#define ACCEL_UMEM_CMD_NOP            0x00000000u
#define ACCEL_UMEM_CMD_NPU_INFER      0x00000001u
#define ACCEL_UMEM_CMD_GPU_CLEAR      0x00000002u
#define ACCEL_UMEM_CMD_GPU_DRAW_TRI   0x00000003u

#define ACCEL_UMEM_CMD_FLAG_MODEL_MASK 0x000000FFu
#define ACCEL_UMEM_CMD_FLAG_DONE       0x80000000u
#define ACCEL_UMEM_CMD_FLAG_ERROR      0x40000000u

typedef struct {
    uint32_t opcode;
    uint32_t flags;
    uint32_t src0;
    uint32_t src1;
    uint32_t src2;
    uint32_t dst0;
    uint32_t arg0;
    uint32_t arg1;
} accel_umem_cmd_desc_t;

#endif
