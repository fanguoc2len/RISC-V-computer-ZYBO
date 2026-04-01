# RISC-V Computer on Zybo Z7-10

Project nay la mot he moi, tach rieng khoi repo Basys 3 cu. Huong di moi:

- `Zynq PS` chay `Linux`
- `PL` chua accelerator fabric
- tai su dung cac khoi RTL huu ich tu repo cu de bring-up nhanh

Repo nay khong con dong vai tro "mini PC text mode tren Basys 3" nua. Muc tieu cua no la mot platform `heterogeneous` tren `Zybo Z7-10` de chay:

1. `Linux` tren `PS`
2. `NPU v2` trong `PL`
3. `GPU 3D lite` trong `PL`
4. userspace Linux dieu khien accelerator qua `MMIO/DMA`

## Kien truc tong quan

- Board target: `Zybo Z7-10`
- SoC host: `Zynq-7000 PS`
- Legacy RTL duoc giu lai trong giai doan dau:
  - `riscv_pc_soc.v`
  - boot ROM / SRAM / UART / SPI / PS2
- Accelerator huong moi:
  - `rtl/accel/npu_v2_stub.v`
  - `rtl/accel/gpu3d_lite_stub.v`
- Shell top moi:
  - `rtl/top/zybo_z7_10_accel_shell.v`

Lua chon kien truc quan trong: `Linux` se chay tren `PS`, khong chay tren `PicoRV32`. `PicoRV32` duoc giu lai nhu mot khoi tham chieu va control island trong giai doan migration.

## Trang thai hien tai

Moc hien tai la `foundation scaffold` cho project Zybo:

- da tach thanh repo moi
- da doi README va docs sang huong `Zybo Z7-10`
- da co shell top moi cho `PL-first bring-up`
- da co script Vivado moi cho part `xc7z010clg400-1`
- da co skeleton cho `NPU v2`, `GPU 3D lite`, va Linux plan
- da co script tao `Zynq PS -> AXI-Lite -> PL` block design
- da co MMIO regression bench cho bridge `PS <-> accelerator`
- da co Linux UIO demo + software reference cho tiny-model NPU
- da co runtime-programmable linear model 2 lop cho NPU qua MMIO
- da co GPU triangle raster path `32x32` 1bpp voi row readback qua MMIO
- da co host-side emulation path cho `accel_mmio_demo` de test stack khong can board
- da co unified-memory ABI dau tien giua NPU/GPU tren host emulation + MMIO bridge
- da co unified command queue trong shared memory voi `HEAD/TAIL/DOORBELL` va descriptor flow `GPU_CLEAR -> GPU_DRAW_TRI -> NPU_INFER`
- da co hardware scaffold `command queue frontend -> AXI read fetch stub` cho unified-memory path trong PL
- da co `dispatch stub` sau decode, nhanh GPU da duoc mux vao `gpu3d_lite_stub`, va nhanh NPU da di them 1 buoc qua `accel_npu_cmd_exec_stub`

Nhung thu chua xong trong moc nay:

- block design da co script tao, nhung chua duoc dong goi thanh handoff `XSA` da xac minh
- chua boot `Linux` that tren board
- chua co `AXI DMA` va kernel driver rieng
- chua co pipeline GPU 3D day du
- chua co model AI end-to-end chay tren NPU moi

## Cau truc repo

- `rtl/top/zybo_z7_10_accel_shell.v`: shell top moi
- `rtl/accel/`: skeleton accelerator moi
- `rtl/accel/accel_mmio_regs.v`: AXI-Lite bridge tu PS sang accelerator regs
- `rtl/accel/accel_cmdq_frontend_stub.v`: command-queue frontend scaffold cho PL
- `rtl/accel/accel_umem_axi_fetch_stub.v`: AXI read-fetch scaffold cho descriptor trong unified memory
- `rtl/accel/accel_cmdq_desc_decode_stub.v`: descriptor decode scaffold sau fetch stage
- `rtl/accel/accel_cmdq_dispatch_stub.v`: command dispatcher scaffold tu decode sang NPU/GPU
- `rtl/accel/accel_npu_cmd_exec_stub.v`: NPU execute stub sau dispatcher de phat `start/model/seq` va debug offsets
- `rtl/soc/`: legacy PicoRV32 subsystem de tai su dung
- `linux/README.md`: ke hoach boot Linux tren PS
- `docs/ARCHITECTURE_ZYBO.md`: kien truc muc tieu
- `docs/ACCEL_MMIO_MAP.md`: register map dau tien cho `PS -> PL`
- `docs/ACCEL_COMMAND_QUEUE.md`: descriptor ABI va submission flow cho unified command queue
- `docs/ROADMAP_ZYBO.md`: roadmap Linux / NPU / GPU
- `docs/MIGRATION_FROM_BASYS3.md`: nhung gi se giu, bo, va lam lai
- `scripts/create_vivado_zybo_project.tcl`: entrypoint tao project Vivado moi
- `scripts/create_vivado_zybo_ps_project.tcl`: tao them block design `PS -> PL`
- `scripts/run_vivado_zybo_umem_axi_fetch_sim.tcl`: test rieng AXI fetch stub
- `scripts/run_vivado_zybo_cmdq_decode_sim.tcl`: test rieng descriptor decode stub
- `scripts/run_vivado_zybo_cmdq_dispatch_sim.tcl`: test rieng dispatch stub
- `scripts/run_vivado_zybo_npu_exec_sim.tcl`: test rieng NPU execute stub
- `scripts/run_vivado_zybo_npu_queue_path_sim.tcl`: test rieng chuoi `dispatch -> exec -> npu_v2`
- `scripts/export_zybo_ps_xsa.tcl`: build PS/PL platform va export `XSA` cho Linux flow
- `linux/petalinux/README.md`: cac manh ghep handoff tu `XSA` sang `PetaLinux`
- `linux/uio/accel_cmdq_host.c`: host-side producer library cho unified command queue

## Cach dung nhanh

Mo Vivado Tcl console, roi chay:

```tcl
cd <duong-dan-repo>
source scripts/create_vivado_zybo_project.tcl
```

Script nay se:

- tao project moi voi part `xc7z010clg400-1`
- add cac nguon `rtl/`, `third_party/picorv32/`, va memory images
- set top synthesis sang `zybo_z7_10_accel_shell`
- set sim top sang `monitor_shell_tb` de giu mot regression nhanh cho legacy subsystem

Luu y: day la `PL-first skeleton` cho project moi. No chua phai ban Linux/Zynq hoan chinh, nhung da la mot diem bat dau dung huong.

Neu muon tao them block design `PS -> AXI-Lite -> accelerator bridge`, dung:

```tcl
source scripts/create_vivado_zybo_ps_project.tcl
```

Script nay tao `processing_system7_0`, noi `M_AXI_GP0` vao module ref `zybo_z7_10_ps_pl_top`, externalize cac cong debug co ban, va scaffold them duong `M_AXI_UMEM -> smartconnect -> S_AXI_HP0` de PL co the fetch descriptor tu `PS DDR`.

Neu muon build PS/PL platform va export handoff `XSA`, dung:

```tcl
source scripts/export_zybo_ps_xsa.tcl
```

Script nay se:

- tao lai project `PS -> PL`
- build `synth_1` va `impl_1`
- co gang export `build/hw/zybo_z7_10_ps_pl.xsa`
- ghi summary vao `build/zybo_ps_xsa_status.txt`

Neu muon test rieng register bridge cua accelerator trong Vivado simulation, dung:

```tcl
source scripts/run_vivado_zybo_accel_mmio_sim.tcl
```

Bench `accel_mmio_regs_tb` se tu check:

- AXI-Lite read/write co ban
- default register map sau reset
- tiny-model `NPU v2` voi 2 vector mau va logits/class golden
- IRQ enable/status va line interrupt tong hop
- clear + draw triangle cho `GPU 3D lite`
- `pixel_count`, `area2`, `bbox`, va framebuffer rows mau
- runtime-model NPU voi weights/bias duoc nap tu software
- snapshot register map dau tien giua `PS` va `PL`

Neu muon test rieng command-queue frontend stub trong Vivado simulation, dung:

```tcl
source scripts/run_vivado_zybo_cmdq_frontend_sim.tcl
```

Bench nay kiem tra:

- `HEAD/TAIL/DOORBELL`
- slot/offset fetch dau tien va thu hai
- retire 2 descriptor va processed-count shadow

Neu muon test rieng AXI read-fetch stub cua unified-memory path trong Vivado simulation, dung:

```tcl
source scripts/run_vivado_zybo_umem_axi_fetch_sim.tcl
```

Bench nay kiem tra:

- `ARADDR = UMEM_BASE + fetch_offset`
- burst `8 beat x 32-bit` cho 1 descriptor `32-byte`
- pack du lieu descriptor vao `desc_data_flat`
- `fetch_ready`, `desc_done`, `desc_error`, va status cua fetch engine

Neu muon test rieng descriptor decode stub trong Vivado simulation, dung:

```tcl
source scripts/run_vivado_zybo_cmdq_decode_sim.tcl
```

Bench nay kiem tra:

- decode `GPU_DRAW_TRI`
- decode `NPU_INFER`
- count descriptor hop le va descriptor loi

Neu muon test rieng dispatch stub trong Vivado simulation, dung:

```tcl
source scripts/run_vivado_zybo_cmdq_dispatch_sim.tcl
```

Bench nay kiem tra:

- dispatch `GPU_CLEAR`
- dispatch `GPU_DRAW_TRI`
- dispatch `NPU_INFER`
- latch invalid-opcode error va dispatch counters

Neu muon test rieng NPU execute stub trong Vivado simulation, dung:

```tcl
source scripts/run_vivado_zybo_npu_exec_sim.tcl
```

Bench nay kiem tra:

- `NPU_INFER` sau dispatch phat `start pulse`
- latch `model_id`, `seq_length`, `input/output offset`
- `exec_status = 0x00018004` sau lan runtime-model dau tien
- sticky error khi co dispatch moi trong luc NPU dang ban

Neu muon test rieng NPU queue path trong Vivado simulation, dung:

```tcl
source scripts/run_vivado_zybo_npu_queue_path_sim.tcl
```

Bench nay kiem tra:

- `NPU_INFER` di qua `dispatch -> exec -> npu_v2`
- offset `input/weight/output` duoc latch dung
- runtime model `0x80` cho ra `STATUS=0x4E008008`, `LOGIT0=20`, `LOGIT1=0`
- `exec_status = 0x00018004` sau queue-driven launch dau tien

Neu can mot duong regression hoan toan tren host, khong can board hay UIO node, co the dung:

```sh
make -C linux/uio check-emulate
make -C linux/uio check-emulate-irq
make -C linux/uio check-cmdq-host
```

Che do nay chay `accel_mmio_demo --emulate`, verify built-in NPU, runtime NPU, GPU triangle raster, PBM export, va co ca duong IRQ emulation rieng.

## File quan trong cho giai doan tiep theo

- `scripts/create_vivado_zybo_project.tcl`
- `rtl/top/zybo_z7_10_accel_shell.v`
- `rtl/top/zybo_z7_10_ps_pl_top.v`
- `rtl/accel/npu_v2_stub.v`
- `rtl/accel/gpu3d_lite_stub.v`
- `rtl/accel/accel_mmio_regs.v`
- `rtl/accel/accel_cmdq_frontend_stub.v`
- `rtl/accel/accel_umem_axi_fetch_stub.v`
- `rtl/accel/accel_cmdq_desc_decode_stub.v`
- `rtl/accel/accel_cmdq_dispatch_stub.v`
- `rtl/accel/accel_npu_cmd_exec_stub.v`
- `tb/accel_mmio_regs_tb.v`
- `tb/accel_cmdq_frontend_stub_tb.v`
- `tb/accel_umem_axi_fetch_stub_tb.v`
- `tb/accel_cmdq_desc_decode_stub_tb.v`
- `tb/accel_cmdq_dispatch_stub_tb.v`
- `tb/accel_npu_cmd_exec_stub_tb.v`
- `tb/accel_npu_queue_path_tb.v`
- `scripts/npu_v2_reference.py`
- `scripts/npu_v2_pack_model.py`
- `linux/uio/accel_cmdq_host.c`
- `linux/include/accel_cmdq_host.h`
- `docs/ARCHITECTURE_ZYBO.md`
- `docs/ACCEL_MMIO_MAP.md`
- `docs/ACCEL_COMMAND_QUEUE.md`
- `docs/ROADMAP_ZYBO.md`
- `docs/UNIFIED_MEMORY.md`
- `linux/README.md`

## Migration notes

Repo Basys 3 cu van la nguon tham chieu cho:

- boot ROM generator
- monitor shell
- SPI / PS2 / UART bring-up
- regression `monitor_shell_tb`

Nhung trong repo moi nay:

- target board da doi sang `Zybo Z7-10`
- `Linux` chay tren `PS`
- `NPU-lite` cu chi con la tham chieu
- `VGA text console` cu khong duoc coi la GPU nua
- `GPU 3D lite` se la khoi render rieng
