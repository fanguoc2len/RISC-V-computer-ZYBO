# Architecture for Zybo Z7-10

## 1. System split

Project moi duoc chia thanh 2 mien ro rang:

- `PS`: Zynq processing system, boot tu SD, chay U-Boot + Linux
- `PL`: custom logic, accelerator fabric, peripheral glue, debug datapaths

Huong nay giai quyet 2 van de cua repo cu:

- khong ep `PicoRV32` lam viec qua suc nhu chay Linux
- cho phep dung DDR va ecosystem Linux cua Zynq de feed model / framebuffer lon

## 2. PL blocks

### 2.1 Legacy RISC-V subsystem

`riscv_pc_soc.v` duoc giu lai trong giai doan dau de:

- tai su dung boot ROM, UART, SPI, PS2, timer, va cac bai test cu
- duy tri mot duong debug nhe trong simulation
- lam "control island" neu can mot firmware cuc nho trong PL

Ve sau, khoi nay co the:

- bi loai bo hoan toan
- hoac tro thanh microcontroller phu cho housekeeping / debug

### 2.2 NPU v2

Huong thiet ke:

- command queue tu PS
- tensor buffer trong BRAM/URAM
- INT8/INT16 MAC array
- DMA path tu DDR qua AXI
- op dau tien uu tien:
  - vector dot
  - GEMV
  - GEMM tile nho
  - activation / requant co ban

Muc tieu khong phai "AI marketing", ma la chay duoc mot model nho that, vi du:

- perceptron / MLP
- keyword spotting nho
- tiny CNN

Trong moc scaffold hien tai, NPU moi moi o dang:

- `npu_v2_stub.v`
- duoc expose qua `accel_mmio_regs.v`
- co 2 built-in linear model de smoke test nhanh
- co them runtime-programmable linear model nap qua MMIO
- co them `accel_npu_payload_fetch_stub.v` de doi `NPU_INFER` queue payload thanh launch payload cho datapath
- co them `accel_npu_cmd_exec_stub.v` de nhan `NPU_INFER` tu command queue va phat `start/model/seq`
- co them `accel_npu_result_store_stub.v` de commit `status/logit/class/hidden` thanh AXI write burst ve unified memory
- san sang de noi vao `PS M_AXI_GP0`

### 2.3 GPU 3D lite

Huong GPU cho do an nay la `fixed-function renderer`, khong phai shader GPU day du.

Pipeline muc tieu:

- command fetch
- vertex transform don gian
- triangle setup
- rasterizer
- depth/color write vao framebuffer

Ban dau du:

- triangle list
- flat color
- z-buffer co ban
- framebuffer RGB565 hoac XRGB8888

Trong moc scaffold hien tai, GPU moi moi o dang:

- `gpu3d_lite_stub.v`
- triangle setup + bounding-box raster tren framebuffer `32x32` 1bpp
- row readback qua `accel_mmio_regs.v`
- de Linux userspace co the goi den tu som va dump ket qua render

## 3. Linux software stack

Linux tren PS se phu trach:

- khoi dong he thong
- cap phat bo nho lon trong DDR
- nap command / tensor / vertex buffer cho PL
- doc ket qua tra ve
- demo app / benchmark

Software path de uu tien:

1. userspace MMIO qua `uio`
2. sau do moi can nhac driver kernel rieng

Unified memory huong toi:

- `PS DDR` la memory pool dung chung
- `PS` truyen cho accelerator `base + offsets`, khong copy tung block qua nhieu pool rieng
- NPU va GPU cung huong toi mot ABI memory chung truoc khi co DMA/AXI master that
- command queue frontend trong PL se dung `HEAD/TAIL/DOORBELL` de tach producer software khoi command fetch hardware
- command queue fetch engine se noi ra `M_AXI_UMEM` de doc descriptor tu `PS DDR` qua `S_AXI_HP0`

## 4. Bring-up strategy

1. Dung `zybo_z7_10_accel_shell` de giu path synth/sim don gian.
2. Tao block design Zynq PS, bat FCLK + AXI GP/HP.
3. Noi NPU/GPU vao AXI-Lite va AXI master/DMA.
4. Boot Linux toi shell.
5. Viet userspace test cho NPU/GPU.

## 5. Queue architecture

Sau moc command-queue dau tien, project da co 2 lop ro rang:

- `linux/uio/accel_cmdq_host.c`: producer library tao descriptor va ring doorbell
- `rtl/accel/accel_cmdq_frontend_stub.v`: consumer/frontend stub cho PL
- `rtl/accel/accel_umem_axi_fetch_stub.v`: AXI read master stub fetch 1 descriptor `32-byte`
- `rtl/accel/accel_cmdq_desc_decode_stub.v`: descriptor decode stage sau fetch
- `rtl/accel/accel_cmdq_dispatch_stub.v`: dispatch stage phan loai job sang NPU/GPU

Y nghia cua viec tach doi nay:

- software app giu mot ABI on dinh
- PL co the thay tu stub sang command fetch unit that ma khong doi giao dien Linux
- block design co the noi `M_AXI_UMEM -> smartconnect -> S_AXI_HP0` de PL fetch descriptor tu `PS DDR`
- fetch stage va decode stage da duoc tach rieng de ve sau chen command dispatcher / scheduler that
- GPU branch da co mux dau tien vao `gpu3d_lite_stub`, con NPU branch da di them 3 buoc qua `accel_npu_payload_fetch_stub`, `accel_npu_cmd_exec_stub`, va `accel_npu_result_store_stub`
- read channel da co `accel_umem_axi_read_arbiter_stub.v` de chia giua descriptor fetch va NPU payload fetch
- ve sau chi can thay fetch stub bang command processor / DMA that ma khong doi ABI software
