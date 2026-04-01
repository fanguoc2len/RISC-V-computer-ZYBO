#ifndef ACCEL_UNIFIED_MEM_H
#define ACCEL_UNIFIED_MEM_H

#include <stdint.h>

#define ACCEL_UMEM_BYTES              0x00010000u
#define ACCEL_UMEM_DEFAULT_BASE       0x10000000u

#define ACCEL_UMEM_CTRL_ENABLE        0x00000001u
#define ACCEL_UMEM_CTRL_NPU_USE_BUF   0x00000002u
#define ACCEL_UMEM_CTRL_GPU_USE_BUF   0x00000004u
#define ACCEL_UMEM_CTRL_CMDQ_ENABLE   0x00000008u

#define ACCEL_UMEM_NPU_INPUT_OFFSET   0x00000000u
#define ACCEL_UMEM_NPU_WEIGHT_OFFSET  0x00000100u
#define ACCEL_UMEM_NPU_OUTPUT_OFFSET  0x00000200u
#define ACCEL_UMEM_GPU_FB_OFFSET      0x00001000u
#define ACCEL_UMEM_GPU_FB_PITCH       0x00000004u
#define ACCEL_UMEM_CMDQ_OFFSET        0x00002000u
#define ACCEL_UMEM_CMDQ_BYTES         0x00000100u

typedef struct {
    uint32_t input0;
    uint32_t input1;
} accel_umem_npu_input_t;

typedef struct {
    uint32_t weight0_a;
    uint32_t weight0_b;
    uint32_t weight1_a;
    uint32_t weight1_b;
    uint32_t bias0;
    uint32_t bias1;
} accel_umem_npu_runtime_model_t;

typedef struct {
    uint32_t status_word;
    uint32_t logit0;
    uint32_t logit1;
    uint32_t class_id;
    uint32_t hidden0;
    uint32_t hidden1;
} accel_umem_npu_output_t;

#endif
