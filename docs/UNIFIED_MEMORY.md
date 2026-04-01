# Unified Memory Plan

Tai lieu nay chot huong `unified memory` cho platform Zybo moi.

## Muc tieu

`PS DDR` dong vai tro bo nho dung chung cho:

- input / weight / output cua `NPU v2`
- framebuffer / command payload cua `GPU 3D lite`
- command descriptor va scratch buffer ve sau

Y tuong trung tam la:

- `PS` cap phat mot vung DDR lien tuc
- `PL` chi nhin thay cac `offset` ben trong vung do
- software va accelerator dung chung mot memory map, khong copy qua lai giua nhieu pool nho

## Register map cho unified memory

Nhung thanh ghi dau tien trong `accel_mmio_regs.v`:

- `0x80` `UMEM_CTRL`
- `0x84` `UMEM_BASE`
- `0x88` `UMEM_SIZE`
- `0x8C` `UMEM_NPU_INPUT`
- `0x90` `UMEM_NPU_WEIGHT`
- `0x94` `UMEM_NPU_OUTPUT`
- `0x98` `UMEM_GPU_FB`
- `0x9C` `UMEM_GPU_FB_PITCH`
- `0xA0` `UMEM_CMDQ_BASE`
- `0xA4` `UMEM_CMDQ_SIZE`
- `0xA8` `UMEM_CMDQ_HEAD`
- `0xAC` `UMEM_CMDQ_TAIL`
- `0xB0` `UMEM_CMDQ_DOORBELL`
- `0xB4` `UMEM_CMDQ_STATUS`

Bit hien tai cua `UMEM_CTRL`:

- bit0: enable unified memory
- bit1: NPU lay input/weight/output tu unified memory
- bit2: GPU mirror framebuffer vao unified memory
- bit3: enable unified command queue

## Layout mac dinh hien tai

ABI software dau tien duoc chot trong [accel_unified_mem.h](/tmp/RISC-V-computer-zybo-z710/linux/include/accel_unified_mem.h):

- base = `0x1000_0000`
- size = `0x0001_0000`
- NPU input offset = `0x0000`
- NPU runtime-weight offset = `0x0100`
- NPU output offset = `0x0200`
- GPU framebuffer offset = `0x1000`
- GPU framebuffer pitch = `4` bytes / row
- command queue offset = `0x2000`
- command queue bytes = `0x0100`

## Trang thai hien tai

Unified memory da co o 2 tang:

1. `MMIO ABI`
   - register map da ton tai trong RTL bridge
   - testbench da verify duoc default values va kha nang reprogram

2. `host emulation`
   - `accel_mmio_demo --emulate` co mot unified buffer noi bo
   - NPU runtime model doc input/weight tu vung nho chung va ghi output tro lai
   - GPU raster mirror framebuffer row-words vao vung nho chung
   - PBM co the duoc xuat tu framebuffer do

3. `host-side command queue`
   - queue descriptor nam ngay trong unified memory
   - software day `GPU_CLEAR`, `GPU_DRAW_TRI`, `NPU_INFER` vao ring
   - emulator xu ly theo `HEAD/TAIL/DOORBELL`
   - ABI nay la buoc dem truoc khi thay bang command fetch unit that trong PL

4. `hardware fetch scaffold`
   - `accel_cmdq_frontend_stub.v` phat `fetch_valid/offset/sequence`
   - `accel_umem_axi_fetch_stub.v` doc 1 descriptor `32-byte` qua `M_AXI_UMEM`
   - `zybo_z7_10_ps_pl_top.v` da scaffold duong `frontend -> fetch -> M_AXI_UMEM`
   - block-design script da scaffold `M_AXI_UMEM -> smartconnect -> processing_system7_0/S_AXI_HP0`

5. `hardware dispatch scaffold`
   - `accel_cmdq_desc_decode_stub.v` boc tach `opcode/args`
   - `accel_cmdq_dispatch_stub.v` phan loai `GPU/NPU`
   - nhanh `GPU` da co mux dau tien vao `gpu3d_lite_stub`
   - nhanh `NPU` hien moi dung o muc dispatch debug cho den khi co payload fetch that

## Chua xong

Nhung phan con lai de unified memory thanh duong hardware that:

- `PL` can AXI master hoac `AXI DMA` de truy cap DDR that
- NPU/GPU can bo phan fetch/store thep offset thay vi chi la register-level stub
- can command processor trong PL doc descriptor tu queue va cap nhat `TAIL/STATUS`
- can cache / coherency strategy ro rang giua Linux va PL

## Ly do chon huong nay

Neu giu moi accelerator mot BRAM rieng va software copy thu cong, do an se nhanh bi vach tran:

- data move ro ri, kho scale
- kho demo Linux + accelerator song song
- kho mo rong len model hay framebuffer lon hon

Unified memory giup repo moi di dung huong cua mot accelerator platform that, du cho ngay hom nay no moi duoc verify day du trong host emulation.
