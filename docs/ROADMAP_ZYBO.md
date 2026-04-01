# Roadmap for Zybo Z7-10 Project

## Milestone 0 - Scaffold

- tach repo moi khoi Basys 3
- doi target sang `Zybo Z7-10`
- tao shell top moi
- tao script Vivado moi

## Milestone 1 - PS/PL bring-up

- tao block design Zynq PS
- FCLK sang PL
- reset chain on dinh
- UART Linux len console
- LED debug / register bridge
- AXI-Lite bridge den `accel_mmio_regs`

## Milestone 2 - Linux boot

- FSBL / U-Boot / kernel / devicetree
- rootfs nho tren SD
- userspace test MMIO

## Milestone 3 - NPU v2

- register map moi
- tensor scratchpad
- MAC array tile nho
- GEMV/GEMM int8
- demo model nho that

Trang thai chen giua milestone 2-3:

- da co unified-memory command queue ABI
- da co host-side producer library cho queue
- da co RTL command-queue frontend stub
- da co AXI read-fetch stub cho descriptor `32-byte`
- da co descriptor decode stub sau fetch stage
- da co dispatch stub va GPU command mux dau tien
- da co NPU payload-fetch stub de doi `input/weight/output offsets` thanh launch payload
- da co NPU command-exec stub sau dispatch de latch offsets va phat `start/model/seq`
- da co block-design scaffold `M_AXI_UMEM -> S_AXI_HP0`
- chua co command processor / DMA day du de doc-va-thuc-thi descriptor that tu DDR

## Milestone 4 - GPU 3D lite

- command FIFO
- triangle setup
- rasterizer
- framebuffer writeback
- demo quay tam giac / mesh don gian

Trang thai hien tai:

- da co built-in linear model va runtime linear model nap qua MMIO
- da co runtime `MLP-lite` mode `0x81` voi `hidden0/hidden1` writeback trong output payload
- da co triangle setup + bounding-box raster `32x32` 1bpp
- da co MMIO row readback va userspace ASCII dump
- da co queue submit flow `GPU_CLEAR -> GPU_DRAW_TRI -> NPU_INFER` trong shared memory
- da co NPU queue payload fetch scaffold doc tu unified memory qua AXI read path
- da co NPU queue writeback scaffold de commit output payload `status/logit/class/hidden` ve unified memory
- chua co z-buffer, transform 3D, hay framebuffer mau day du

## Milestone 5 - Integrated demo

- Linux app load model
- Linux app gui command render
- NPU va GPU chay song song trong PL
- board demo tren Zybo Z7-10
