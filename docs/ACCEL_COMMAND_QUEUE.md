# Unified Command Queue

Tai lieu nay chot `submission ABI` cho accelerator platform Zybo moi.

## Muc tieu

Thay vi software go tung thanh ghi `NPU/GPU`, `PS Linux` se day job vao mot queue trong `unified memory`:

- `GPU_CLEAR`
- `GPU_DRAW_TRI`
- `NPU_INFER`

Huong nay giu cho giao dien software khong bi khoa cung vao MMIO polling, dong thoi mo duong cho `AXI master/DMA` ve sau.

## Register hook

MMIO bridge hien tai expose cac thanh ghi queue:

- `0xA0` `UMEM_CMDQ_BASE`
- `0xA4` `UMEM_CMDQ_SIZE`
- `0xA8` `UMEM_CMDQ_HEAD`
- `0xAC` `UMEM_CMDQ_TAIL`
- `0xB0` `UMEM_CMDQ_DOORBELL`
- `0xB4` `UMEM_CMDQ_STATUS`
- `0xE0` `CMDQ_DISPATCH_STATUS`
- `0xE4` `CMDQ_DISPATCH_OPCODE`
- `0xE8` `CMDQ_DISPATCH_NPU_COUNT`
- `0xEC` `CMDQ_DISPATCH_GPU_COUNT`
- `0xF0` `CMDQ_DISPATCH_ERROR_COUNT`
- `0xF4` `NPU_CMD_EXEC_STATUS`
- `0xF8` `NPU_CMD_EXEC_INPUT_OFFSET`
- `0xFC` `NPU_CMD_EXEC_OUTPUT_OFFSET`

Y nghia:

- `HEAD`: producer index do software cap nhat
- `TAIL`: consumer index do command processor cap nhat
- `DOORBELL`: software thong bao co job moi
- `STATUS`: bit0 busy, bit1 error, bit2 empty, upper `16 bit` la so descriptor da xu ly trong host emulation

## Descriptor ABI

Descriptor duoc chot trong [accel_unified_queue.h](/tmp/RISC-V-computer-zybo-z710/linux/include/accel_unified_queue.h):

```c
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
```

Kich thuoc:

- `32 bytes / descriptor`
- default ring = `0x100 bytes`
- default `8 descriptors`

Opcode hien tai:

- `0x00` `NOP`
- `0x01` `NPU_INFER`
- `0x02` `GPU_CLEAR`
- `0x03` `GPU_DRAW_TRI`

Flag bit:

- `bit31` `DONE`
- `bit30` `ERROR`
- `bit[7:0]` mang `model_id` cho `NPU_INFER`

## Giai nghia tung lenh

### NPU_INFER

- `src0`: offset toi `accel_umem_npu_input_t`
- `src1`: offset toi `accel_umem_npu_runtime_model_t`
- `dst0`: offset toi `accel_umem_npu_output_t`
- `arg0`: `seq_length`
- `flags[7:0]`: `model_id` (`0x80` linear runtime, `0x81` runtime MLP)

### GPU_CLEAR

- `dst0`: offset framebuffer dich trong unified memory
- `arg0[7:0]`: clear value

### GPU_DRAW_TRI

- `src0`: packed `vertex0`
- `src1`: packed `vertex1`
- `src2`: packed `vertex2`
- `dst0`: offset framebuffer dich trong unified memory

## Trang thai hien tai

Queue nay da duoc verify trong `host emulation`:

- `GPU_CLEAR -> GPU_DRAW_TRI -> NPU_INFER`
- `TAIL` di tu `0` len `3`
- `STATUS = 0x00030004`
- descriptor cuoi co `DONE` + `model_id runtime`

Golden log hien tai:

- `cmdq_status = 0x00030004`
- `cmdq_desc2 = 0x80000080`
- `cmdq_npu_exec_status = 0x00018004`
- `cmdq_npu_exec_in = 0x00000400`
- `cmdq_npu_exec_out = 0x00000480`
- `cmdq_status_word = 0x4E008008`
- `cmdq_hidden0 = 20`
- `cmdq_hidden1 = 0`
- `cmdq_gpu_row02 = 0x000007FC`

Repo hien tai da tach thanh 2 lop ro rang:

- producer software: [accel_cmdq_host.c](/tmp/RISC-V-computer-zybo-z710/linux/uio/accel_cmdq_host.c)
- consumer/frontend RTL: [accel_cmdq_frontend_stub.v](/tmp/RISC-V-computer-zybo-z710/rtl/accel/accel_cmdq_frontend_stub.v)
- AXI read-fetch scaffold: [accel_umem_axi_fetch_stub.v](/tmp/RISC-V-computer-zybo-z710/rtl/accel/accel_umem_axi_fetch_stub.v)
- descriptor decode scaffold: [accel_cmdq_desc_decode_stub.v](/tmp/RISC-V-computer-zybo-z710/rtl/accel/accel_cmdq_desc_decode_stub.v)
- dispatch scaffold: [accel_cmdq_dispatch_stub.v](/tmp/RISC-V-computer-zybo-z710/rtl/accel/accel_cmdq_dispatch_stub.v)
- NPU payload-fetch scaffold: [accel_npu_payload_fetch_stub.v](/tmp/RISC-V-computer-zybo-z710/rtl/accel/accel_npu_payload_fetch_stub.v)
- NPU execute scaffold: [accel_npu_cmd_exec_stub.v](/tmp/RISC-V-computer-zybo-z710/rtl/accel/accel_npu_cmd_exec_stub.v)
- NPU result-store scaffold: [accel_npu_result_store_stub.v](/tmp/RISC-V-computer-zybo-z710/rtl/accel/accel_npu_result_store_stub.v)

Frontend stub chua fetch DDR that, nhung da chot state machine:

- nhan `HEAD/TAIL/DOORBELL`
- phat `fetch_valid/slot/offset`
- retire descriptor va cap nhat processed-count shadow

Fetch stub moi them da scaffold:

- `ARADDR = UMEM_BASE + fetch_offset`
- `ARLEN = 7`, `ARSIZE = 2` de doc `8 beat x 32-bit`
- pack thanh `desc_data_flat[255:0]`
- tra ve `fetch_ready`, `desc_done`, `desc_error`

Decode stub moi them da scaffold:

- latched `opcode/flags/src0/src1/src2/dst0/arg0/arg1`
- tach san `model_id`, `seq_length`, `vertex0/1/2`, `clear_value`
- dem descriptor hop le va descriptor loi de sau nay noi vao command dispatcher

Dispatch stub moi them da scaffold:

- phan loai `NPU_INFER`, `GPU_CLEAR`, `GPU_DRAW_TRI`
- dem so lenh `NPU/GPU/error`
- latch `last_opcode`
- nhanh `GPU` da duoc mux vao `gpu3d_lite_stub` o top-level

NPU execute stub moi them da scaffold:

- nhan `NPU_INFER` da qua dispatch
- latch `model_id`, `seq_length`, `input/weight/output offset`
- phat `npu_start_pulse` vao `npu_v2_stub`
- expose `exec_count/last_model_id/flags` qua `NPU_CMD_EXEC_STATUS`

NPU payload-fetch stub moi them da scaffold:

- nam giua `dispatch` va `exec`
- doi `input/weight/output offsets` thanh bo payload launch cho `npu_v2_stub`
- phat `2 burst AXI read` de lay `input` roi `weights/bias` tu unified memory

Read arbiter moi them da scaffold:

- chia se `M_AXI_UMEM` giua `descriptor fetch` va `NPU payload fetch`
- uu tien descriptor fetch neu 2 nhanh cung xin read channel
- giu cho ABI queue phia software khong phai doi

NPU result-store stub moi them da scaffold:

- nam sau `npu_v2_stub`
- nhan `store_request_pulse` tu execute stub khi queue-driven infer ket thuc
- dong goi `status/logit0/logit1/class/hidden0/hidden1` thanh `6 beat x 32-bit`
- phat `AW/W/B` transaction tren AXI write channel ve `UMEM_BASE + output_offset`

## Chua xong

De bien no thanh hardware that trong PL, can them:

- command fetch unit doc descriptor tu DDR
- `TAIL/STATUS` do hardware cap nhat that
- cache/coherency strategy voi Linux
- neu can, descriptor `fence/event/timestamp`

Nhung ngay bay gio ABI software da du on dinh de tiep tuc phat trien theo huong nay.
