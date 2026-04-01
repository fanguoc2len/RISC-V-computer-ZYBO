# Linux Plan

Linux trong project nay se chay tren `Zynq PS`, khong chay tren `PicoRV32`.

## Muc tieu software

- boot tu SD card
- co serial console
- co device tree cho PL accelerators
- userspace app dieu khien `NPU v2` va `GPU 3D lite`

## Huong trien khai

1. tao block design Zynq PS trong Vivado
2. export hardware (`XSA`)
3. build FSBL / U-Boot / kernel / devicetree
4. boot toi shell
5. map accelerator thanh `uio` truoc

Repo da co script cho buoc 1-2:

- `scripts/create_vivado_zybo_ps_project.tcl`
- `scripts/export_zybo_ps_xsa.tcl`

## Driver strategy

Ban dau uu tien:

- AXI-Lite control registers
- `uio_pdrv_genirq` hoac `/dev/mem` cho bring-up nhanh

Ve sau moi nang len:

- kernel driver rieng
- DMA coherent buffers
- interrupts / fences cho GPU va NPU

## Files da co san

- `linux/include/accel_mmio.h`: header cho register map hien tai
- `linux/include/accel_unified_mem.h`: layout ABI cho unified memory giua NPU/GPU
- `linux/include/accel_unified_queue.h`: descriptor ABI cho unified command queue trong shared memory
- `linux/include/accel_cmdq_host.h`: producer API cho userspace Linux day descriptor vao queue
- `rtl/accel/accel_umem_axi_fetch_stub.v`: scaffold cho AXI read fetch descriptor tu `PS DDR`
- `rtl/accel/accel_cmdq_desc_decode_stub.v`: scaffold cho descriptor decode sau fetch stage
- `rtl/accel/accel_cmdq_dispatch_stub.v`: scaffold cho dispatch stage sau decode
- `linux/uio/accel_mmio_demo.c`: userspace demo cho MMIO path hien tai
- `linux/uio/accel_cmdq_host.c`: implementation cho host-side command queue producer
- `linux/uio/Makefile`: build nhanh host-side cho demo `uio`
- `linux/devicetree/zybo_accel_uio.dtsi`: snippet device-tree de expose accelerator qua `generic-uio`
- `linux/devicetree/system-user-accel-uio.dtsi`: template de merge vao `system-user.dtsi` cua PetaLinux
- `linux/petalinux/kernel_uio.cfg`: config fragment bat `UIO`
- `linux/petalinux/README.md`: note handoff `XSA -> PetaLinux -> UIO demo`
- `scripts/gpu3d_lite_reference.py`: software reference cho triangle raster path
- `scripts/npu_v2_reference.py`: software reference cho tiny model cua `NPU v2`
- `scripts/npu_v2_pack_model.py`: pack runtime weights/bias thanh MMIO words

## Register map hien tai

- `0x00`: ID/version
- `0x04`: control, bit0 start NPU, bit1 start GPU
- `0x08`: status, bit0 NPU busy, bit1 NPU done sticky, bit2 GPU busy, bit3 GPU done sticky
- `0x0C`: NPU config (`seq_length[31:16]`, `model_id[7:0]`)
- `0x10`: NPU status word
- `0x14`: NPU input vector dau
- `0x18`: NPU input vector sau
- `0x1C`: NPU logit class0
- `0x20`: NPU logit class1
- `0x24`: NPU class argmax
- `0x28`: GPU command opcode
- `0x2C`: GPU triangles drawn
- `0x30`: legacy boot status
- `0x34`: legacy GPIO snapshot
- `0x38`: IRQ enable, bit0 NPU done, bit1 GPU done
- `0x3C`: IRQ status, bit0 NPU pending, bit1 GPU pending, bit2 IRQ line level
- `0x40`: GPU vertex0, packed `xy = {y[7:0], x[7:0]}`
- `0x44`: GPU vertex1
- `0x48`: GPU vertex2
- `0x4C`: GPU clear value, bit0 fill color
- `0x50`: GPU frame counter
- `0x54`: GPU raster pixel count
- `0x58`: GPU last signed area2
- `0x5C`: GPU last bbox, packed `{max_y,max_x,min_y,min_x}`
- `0x60`: GPU framebuffer row select
- `0x64`: GPU framebuffer row data, 32 pixels per row
- `0x68`: NPU runtime class0 weights cho input0
- `0x6C`: NPU runtime class0 weights cho input1
- `0x70`: NPU runtime class1 weights cho input0
- `0x74`: NPU runtime class1 weights cho input1
- `0x78`: NPU runtime bias0
- `0x7C`: NPU runtime bias1
- `0x80`: unified-memory control
- `0x84`: unified-memory base
- `0x88`: unified-memory size
- `0x8C`: unified-memory NPU input offset
- `0x90`: unified-memory NPU runtime-weight offset
- `0x94`: unified-memory NPU output offset
- `0x98`: unified-memory GPU framebuffer offset
- `0x9C`: unified-memory GPU framebuffer pitch
- `0xA0`: unified-memory command queue base
- `0xA4`: unified-memory command queue size
- `0xA8`: unified-memory command queue head
- `0xAC`: unified-memory command queue tail
- `0xB0`: unified-memory command queue doorbell
- `0xB4`: unified-memory command queue status
- `0xB8`: command queue tail shadow
- `0xBC`: command queue status shadow
- `0xC0`: command queue fetch offset shadow
- `0xC4`: command queue fetch sequence shadow
- `0xC8`: command queue fetch slot shadow
- `0xCC`: unified-memory AXI fetch status
- `0xD0`: unified-memory AXI fetch last ARADDR
- `0xD4`: unified-memory AXI fetch last sequence
- `0xD8`: unified-memory AXI fetch beat count
- `0xDC`: unified-memory AXI fetch descriptor word0
- `0xE0`: command queue dispatch status
- `0xE4`: command queue dispatch opcode
- `0xE8`: command queue dispatch NPU count
- `0xEC`: command queue dispatch GPU count
- `0xF0`: command queue dispatch error count
- `0xF4`: NPU command-exec status
- `0xF8`: NPU command-exec input offset
- `0xFC`: NPU command-exec output offset

## Tiny model hien tai

`NPU v2` dang co mot tiny model 2 lop tren 8 input signed int8:

- `class0 ~= sum(first4) - sum(last4)`
- `class1 ~= -sum(first4) + sum(last4)`

Golden vectors de bring-up nhanh:

- `input0 = 0x04030201`, `input1 = 0x00000000` => `class = 0`, logits `(+10, -10)`
- `input0 = 0x00000000`, `input1 = 0x04030201` => `class = 1`, logits `(-10, +10)`

Ngoai built-in model, `model_id = 0x80` mo runtime linear model duoc nap qua MMIO. Demo runtime hien tai dung:

- `W0A/W0B = [2,0,2,0]`
- `W1A/W1B = [0,2,0,2]`
- `bias0 = bias1 = 0`

Khi do:

- `input0 = 0x00020001`, `input1 = 0x00040003` => `class = 0`, logits `(+20, 0)`
- `input0 = 0x02000100`, `input1 = 0x04000300` => `class = 1`, logits `(0, +20)`

Them nua, `model_id = 0x81` mo runtime MLP nho:

- `hidden0 = ReLU(dot(class0_weights, input) + bias0)`
- `hidden1 = ReLU(dot(class1_weights, input) + bias1)`
- `logit0 = hidden0 - hidden1`
- `logit1 = hidden1 - hidden0`

Demo MLP hien tai dung:

- `W0A/W0B = [2,0,2,0]`
- `W1A/W1B = [0,2,0,2]`
- `bias0 = bias1 = -8`
- `input0 = 0x00020001`, `input1 = 0x00040003` => `hidden = (12, 0)`, logits `(+12, -12)`, `status = 0x4E008108`

Co the doi chieu nhanh bang:

```sh
python3 scripts/npu_v2_reference.py --input0 0x04030201 --input1 0x00000000
python3 scripts/npu_v2_reference.py --input0 0x00000000 --input1 0x04030201
python3 scripts/npu_v2_reference.py --runtime-demo --input0 0x00020001 --input1 0x00040003 --emit-mmio
python3 scripts/npu_v2_reference.py --runtime-mlp-demo --input0 0x00020001 --input1 0x00040003
python3 scripts/npu_v2_pack_model.py --model linear --class0 2,0,2,0,2,0,2,0 --class1 0,2,0,2,0,2,0,2
python3 scripts/npu_v2_pack_model.py --model mlp --class0 2,0,2,0,2,0,2,0 --class1 0,2,0,2,0,2,0,2 --bias0 -8 --bias1 -8
```

## Build userspace demo

Tren host Linux, build nhanh binary demo:

```sh
make -C linux/uio
make -C linux/uio check-emulate
```

Binary tao ra:

- `linux/uio/accel_mmio_demo`

Makefile trong thu muc nay con co:

- `make -C linux/uio emulate` de chay full demo o che do `--emulate`
- `make -C linux/uio emulate-irq` de chay emulation voi IRQ path
- `make -C linux/uio check-emulate` de verify cac golden outputs va PBM header
- `make -C linux/uio check-emulate-irq` de verify golden outputs cho duong IRQ
- `make -C linux/uio check-cmdq-host` de verify rieng host-side command queue producer

Demo app ho tro 2 che do:

- polling mac dinh: `./accel_mmio_demo`
- interrupt qua UIO: `./accel_mmio_demo --irq`
- emulation host-side khong can board: `./accel_mmio_demo --emulate`
- xuat framebuffer thanh anh PBM: `./accel_mmio_demo --pbm gpu_triangle.pbm`

Ngoai demo chinh, repo da co producer API rieng cho command queue:

- `accel_cmdq_host_init`
- `accel_cmdq_host_reset`
- `accel_cmdq_host_push_gpu_clear`
- `accel_cmdq_host_push_gpu_draw_tri`
- `accel_cmdq_host_push_npu_infer`
- `accel_cmdq_host_submit`

NPU demo trong app se:

- chay 2 vector built-in model smoke test
- nap runtime weights vao `0x68..0x7C`
- chay them 2 vector cho runtime model `model_id = 0x80`
- chay them 1 vector cho runtime MLP `model_id = 0x81`
- chay them unified-memory NPU path voi input/weight/output nam trong cung mot buffer
- chay them unified command queue demo voi `GPU_CLEAR`, `GPU_DRAW_TRI`, `NPU_INFER` chung mot ring buffer
- in them command-queue `dispatch` va `NPU execute` debug regs (`0xE0..0xFC`) trong che do emulation

Che do `--emulate` dung backend MMIO noi bo trong process, nen co the verify ngay tren host:

- register map `PS <-> PL`
- built-in NPU model
- runtime NPU model
- runtime NPU MLP model
- unified memory ABI giua NPU/GPU
- unified command queue trong shared memory
- GPU triangle raster + PBM export

GPU demo hien tai se:

- clear framebuffer `32x32` 1bpp
- nap triangle `(2,2) -> (10,2) -> (2,10)`
- draw triangle qua MMIO
- doc `frame_count`, `pixel_count`, `area2`, `bbox`
- dump framebuffer ra ASCII
- tuy chon ghi framebuffer ra file `PBM` de xem/doi sang PNG sau
- mirror framebuffer vao unified memory khi bat `UMEM_CTRL`

## IRQ bring-up note

RTL va block design da co duong:

- `accel_mmio_regs.irq`
- `zybo_z7_10_ps_pl_top.irq_f2p`
- `xlconcat_irq_f2p_0`
- `processing_system7_0/IRQ_F2P`

Unified-memory hardware scaffold hien tai da them:

- `zybo_z7_10_ps_pl_top.M_AXI_UMEM`
- `smartconnect_umem_0`
- `processing_system7_0/S_AXI_HP0`

Nhung so `GIC SPI` cu the cho `IRQ_F2P[0]` can duoc xac minh sau khi import `XSA` vao flow Linux. Vi the `zybo_accel_uio.dtsi` hien de o dang template co ghi chu thay vi hardcode mot gia tri co the sai.
