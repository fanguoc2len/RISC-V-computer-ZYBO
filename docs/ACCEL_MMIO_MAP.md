# Accelerator MMIO Map

Tai lieu nay mo ta register map hien tai cua `accel_mmio_regs.v`.

## Base address

Trong phase dau, base address du kien tu PS la:

- `0x43C0_0000`

Gia tri nay khop voi snippet trong `linux/devicetree/zybo_accel_uio.dtsi`.

## Registers

| Offset | Ten | Mo ta |
| --- | --- | --- |
| `0x00` | `ID_VERSION` | magic/version cua accelerator bridge |
| `0x04` | `CONTROL` | bit0 pulse start NPU, bit1 pulse start GPU |
| `0x08` | `STATUS` | bit0 NPU busy, bit1 NPU done sticky, bit2 GPU busy, bit3 GPU done sticky |
| `0x0C` | `NPU_CFG0` | `seq_length[31:16]`, `model_id[7:0]` |
| `0x10` | `NPU_STATUS_WORD` | status/model/class tu `npu_v2_stub` |
| `0x14` | `NPU_INPUT0` | 4 phan tu int8 dau tien |
| `0x18` | `NPU_INPUT1` | 4 phan tu int8 cuoi |
| `0x1C` | `NPU_LOGIT0` | logit class 0 |
| `0x20` | `NPU_LOGIT1` | logit class 1 |
| `0x24` | `NPU_CLASS` | class argmax |
| `0x28` | `GPU_CMD` | opcode command cho `gpu3d_lite_stub` |
| `0x2C` | `GPU_TRIANGLES` | so triangle da xu ly |
| `0x30` | `LEGACY_BOOT_STATUS` | snapshot tu legacy PicoRV32 subsystem |
| `0x34` | `LEGACY_GPIO_OUT` | snapshot GPIO tu legacy PicoRV32 subsystem |
| `0x38` | `IRQ_ENABLE` | bit0 enable IRQ NPU done, bit1 enable IRQ GPU done |
| `0x3C` | `IRQ_STATUS` | bit0 NPU pending, bit1 GPU pending, bit2 line IRQ tong hop |
| `0x40` | `GPU_VERTEX0` | packed `xy = {y[7:0], x[7:0]}` |
| `0x44` | `GPU_VERTEX1` | packed `xy = {y[7:0], x[7:0]}` |
| `0x48` | `GPU_VERTEX2` | packed `xy = {y[7:0], x[7:0]}` |
| `0x4C` | `GPU_CLEAR_VALUE` | bit0 la mau fill cho clear |
| `0x50` | `GPU_FRAME_COUNT` | so command GPU da hoan tat |
| `0x54` | `GPU_RASTER_PIXELS` | so pixel duoc to o lan draw cuoi |
| `0x58` | `GPU_LAST_AREA2` | signed area x2 cua triangle cuoi |
| `0x5C` | `GPU_LAST_BBOX` | packed `{max_y,max_x,min_y,min_x}` |
| `0x60` | `GPU_FB_ROWSEL` | chon hang framebuffer de doc |
| `0x64` | `GPU_FB_ROWDATA` | 32 bit, moi bit la 1 pixel |
| `0x68` | `NPU_WEIGHT0_A` | 4 trong so int8 dau cua class0 runtime |
| `0x6C` | `NPU_WEIGHT0_B` | 4 trong so int8 cuoi cua class0 runtime |
| `0x70` | `NPU_WEIGHT1_A` | 4 trong so int8 dau cua class1 runtime |
| `0x74` | `NPU_WEIGHT1_B` | 4 trong so int8 cuoi cua class1 runtime |
| `0x78` | `NPU_BIAS0` | bias signed 32-bit cua class0 runtime |
| `0x7C` | `NPU_BIAS1` | bias signed 32-bit cua class1 runtime |
| `0x80` | `UMEM_CTRL` | bit0 enable, bit1 NPU dung unified memory, bit2 GPU mirror framebuffer, bit3 enable command queue |
| `0x84` | `UMEM_BASE` | base address cua vung unified memory |
| `0x88` | `UMEM_SIZE` | kich thuoc vung unified memory |
| `0x8C` | `UMEM_NPU_INPUT` | offset input NPU trong unified memory |
| `0x90` | `UMEM_NPU_WEIGHT` | offset runtime-weight NPU trong unified memory |
| `0x94` | `UMEM_NPU_OUTPUT` | offset output NPU trong unified memory |
| `0x98` | `UMEM_GPU_FB` | offset framebuffer GPU trong unified memory |
| `0x9C` | `UMEM_GPU_FB_PITCH` | pitch theo byte cho moi row framebuffer |
| `0xA0` | `UMEM_CMDQ_BASE` | offset base cua command queue trong unified memory |
| `0xA4` | `UMEM_CMDQ_SIZE` | kich thuoc ring buffer command queue theo byte |
| `0xA8` | `UMEM_CMDQ_HEAD` | producer index do software cap nhat |
| `0xAC` | `UMEM_CMDQ_TAIL` | consumer index do command processor cap nhat |
| `0xB0` | `UMEM_CMDQ_DOORBELL` | software thong bao co them descriptor moi |
| `0xB4` | `UMEM_CMDQ_STATUS` | bit0 busy, bit1 error, bit2 empty, upper 16 bit la processed count trong emulation |
| `0xB8` | `CMDQ_TAIL_SHADOW` | consumer shadow do frontend stub cap nhat |
| `0xBC` | `CMDQ_STATUS_SHADOW` | processed-count/error/empty shadow cua frontend stub |
| `0xC0` | `CMDQ_FETCH_OFFSET` | offset descriptor cuoi cung duoc frontend yeu cau fetch |
| `0xC4` | `CMDQ_FETCH_SEQUENCE` | sequence counter cuoi cung cua frontend |
| `0xC8` | `CMDQ_FETCH_SLOT` | slot cuoi cung duoc frontend chon |
| `0xCC` | `UMEM_FETCH_STATUS` | `busy/error/idle` cua AXI fetch stub |
| `0xD0` | `UMEM_FETCH_LAST_ARADDR` | dia chi `ARADDR` cuoi cung = `UMEM_BASE + fetch_offset` |
| `0xD4` | `UMEM_FETCH_LAST_SEQUENCE` | sequence counter cuoi cung do fetch stub giu |
| `0xD8` | `UMEM_FETCH_BEAT_COUNT` | so beat da nhan o burst descriptor cuoi cung |
| `0xDC` | `UMEM_FETCH_DESC_WORD0` | word0 cua descriptor cuoi cung sau khi pack |
| `0xE0` | `CMDQ_DISPATCH_STATUS` | `busy/error/idle` cua dispatch stub |
| `0xE4` | `CMDQ_DISPATCH_OPCODE` | opcode cuoi cung da duoc dispatch |
| `0xE8` | `CMDQ_DISPATCH_NPU_COUNT` | so lenh `NPU_INFER` da di qua dispatcher |
| `0xEC` | `CMDQ_DISPATCH_GPU_COUNT` | so lenh `GPU_*` da di qua dispatcher |
| `0xF0` | `CMDQ_DISPATCH_ERROR_COUNT` | so descriptor invalid-opcode |
| `0xF4` | `NPU_CMD_EXEC_STATUS` | `{exec_count,last_model_id,flags}` tu NPU execute stub |
| `0xF8` | `NPU_CMD_EXEC_INPUT_OFFSET` | offset input buffer cuoi cung ma NPU execute stub da latch |
| `0xFC` | `NPU_CMD_EXEC_OUTPUT_OFFSET` | offset output buffer cuoi cung ma NPU execute stub da latch |

## Handshake software

### Chay NPU

1. ghi `NPU_CFG0`
2. ghi `NPU_INPUT0` va `NPU_INPUT1`
3. tuy chon ghi `IRQ_ENABLE.bit0 = 1`
4. ghi `CONTROL.bit0 = 1`
5. poll `STATUS` cho toi khi `busy = 0` va `done sticky = 1`, hoac doi `UIO interrupt`
6. doc `NPU_STATUS_WORD`, `NPU_LOGIT0`, `NPU_LOGIT1`, `NPU_CLASS`
7. ghi `STATUS.bit0 = 1` de clear `NPU done sticky`

### Tiny model hien tai

Model dau tien la classifier 2 lop tren 8 input int8:

- `class0 ~= sum(first4) - sum(last4)`
- `class1 ~= -sum(first4) + sum(last4)`

Vi du:

- `INPUT0 = 0x04030201`, `INPUT1 = 0x00000000` se nghieng ve `class0`
- `INPUT0 = 0x00000000`, `INPUT1 = 0x04030201` se nghieng ve `class1`

Golden outputs cho regression hien tai:

| Input0 | Input1 | Status word | Logit0 | Logit1 | Class |
| --- | --- | --- | --- | --- | --- |
| `0x04030201` | `0x00000000` | `0x4E000108` | `+10` | `-10` | `0` |
| `0x00000000` | `0x04030201` | `0x4E010108` | `-10` | `+10` | `1` |

### Runtime-model qua MMIO

`model_id = 0x80` duoc dung cho linear model nap tu software. Runtime model hien tai trong regression/userspace demo:

- `W0A = 0x00020002` => `[2,0,2,0]`
- `W0B = 0x00020002` => `[2,0,2,0]`
- `W1A = 0x02000200` => `[0,2,0,2]`
- `W1B = 0x02000200` => `[0,2,0,2]`
- `BIAS0 = 0`
- `BIAS1 = 0`

Golden outputs:

| Input0 | Input1 | Status word | Logit0 | Logit1 | Class |
| --- | --- | --- | --- | --- | --- |
| `0x00020001` | `0x00040003` | `0x4E008008` | `+20` | `0` | `0` |
| `0x02000100` | `0x04000300` | `0x4E018008` | `0` | `+20` | `1` |

### Unified memory

Layout mac dinh hien tai:

- `UMEM_BASE = 0x10000000`
- `UMEM_SIZE = 0x00010000`
- `UMEM_NPU_INPUT = 0x00000000`
- `UMEM_NPU_WEIGHT = 0x00000100`
- `UMEM_NPU_OUTPUT = 0x00000200`
- `UMEM_GPU_FB = 0x00001000`
- `UMEM_GPU_FB_PITCH = 0x00000004`
- `UMEM_CMDQ_BASE = 0x00002000`
- `UMEM_CMDQ_SIZE = 0x00000100`

Khi `UMEM_CTRL = 0x00000007` trong emulation:

- NPU runtime model doc `input0/input1` va weights tu unified memory
- output `status/logit0/logit1/class` duoc ghi tro lai unified memory
- GPU se mirror framebuffer row-words vao unified memory

Golden outputs cho unified-memory demo hien tai:

- `UMEM NPU STATUS = 0x4E008008`
- `UMEM NPU LOGIT0 = 20`
- `UMEM NPU LOGIT1 = 0`
- `UMEM GPU ROW[02] = 0x000007FC`
- `UMEM GPU ROW[03] = 0x000003FC`
- `UMEM GPU ROW[10] = 0x00000004`

### Unified command queue

Queue descriptor ABI nam trong [accel_unified_queue.h](/tmp/RISC-V-computer-zybo-z710/linux/include/accel_unified_queue.h).

Flow demo hien tai:

1. software ghi `UMEM_CMDQ_BASE/SIZE`
2. software dat descriptor `GPU_CLEAR`, `GPU_DRAW_TRI`, `NPU_INFER` vao ring
3. software cap nhat `UMEM_CMDQ_HEAD = 3`
4. software ring `UMEM_CMDQ_DOORBELL = 3`
5. command processor emulation day `TAIL` den `3` va set flag `DONE`

Golden outputs:

- `CMDQ STATUS = 0x00030004`
- `CMDQ TAIL SHADOW = 0x00000003`
- `CMDQ FETCH OFFSET = 0x00002040`
- `CMDQ FETCH SEQUENCE = 0x00000002`
- `CMDQ AXI STATUS = 0x00000004`
- `CMDQ AXI ARADDR = 0x10002040`
- `CMDQ AXI DESC WORD0 = 0x00000001`
- `CMDQ DISPATCH STATUS = 0x00000004`
- `CMDQ DISPATCH OPCODE = 0x00000001`
- `CMDQ DISPATCH NPU COUNT = 1`
- `CMDQ DISPATCH GPU COUNT = 2`
- `CMDQ DISPATCH ERROR COUNT = 0`
- `CMDQ NPU EXEC STATUS = 0x00018004`
- `CMDQ NPU EXEC INPUT OFFSET = 0x00000400`
- `CMDQ NPU EXEC OUTPUT OFFSET = 0x00000480`
- `CMDQ DESC2 = 0x80000080`
- `CMDQ NPU STATUS = 0x4E008008`
- `CMDQ GPU ROW[02] = 0x000007FC`

### Chay GPU

1. tuy chon ghi `IRQ_ENABLE.bit1 = 1`
2. neu clear frame: ghi `GPU_CLEAR_VALUE`, roi `GPU_CMD = 1`
3. neu draw triangle: ghi `GPU_VERTEX0/1/2`, roi `GPU_CMD = 2`
4. ghi `CONTROL.bit1 = 1`
5. poll `STATUS` cho toi khi `busy = 0` va `done sticky = 1`, hoac doi `UIO interrupt`
6. doc `GPU_TRIANGLES`, `GPU_FRAME_COUNT`, `GPU_RASTER_PIXELS`, `GPU_LAST_AREA2`, `GPU_LAST_BBOX`
7. de doc framebuffer, ghi `GPU_FB_ROWSEL` roi doc `GPU_FB_ROWDATA`
8. ghi `STATUS.bit1 = 1` de clear `GPU done sticky`

## IRQ path hien tai

Duong tong hop interrupt dau tien cua platform moi:

- `accel_mmio_regs.irq`
- `zybo_z7_10_ps_pl_top.irq_f2p`
- `xlconcat_irq_f2p_0`
- `processing_system7_0/IRQ_F2P`

Unified-memory hardware path scaffold moi:

- `zybo_z7_10_ps_pl_top.M_AXI_UMEM`
- `smartconnect_umem_0`
- `processing_system7_0/S_AXI_HP0`

Device-tree binding cu the cho `IRQ_F2P[0]` se duoc chot sau khi import `XSA` vao flow Linux.

## Triangle demo hien tai

Triangle mau trong regression va userspace demo:

- `V0 = (2,2)`
- `V1 = (10,2)`
- `V2 = (2,10)`

Golden outputs:

- `AREA2 = 64`
- `BBOX = 0x0A0A0202`
- `PIXELS = 45`
- `ROW[02] = 0x000007FC`
- `ROW[03] = 0x000003FC`
- `ROW[10] = 0x00000004`

## Files lien quan

- `rtl/accel/accel_mmio_regs.v`
- `rtl/accel/npu_v2_stub.v`
- `rtl/top/zybo_z7_10_ps_pl_top.v`
- `tb/accel_mmio_regs_tb.v`
- `linux/include/accel_mmio.h`
- `linux/include/accel_unified_mem.h`
- `linux/include/accel_unified_queue.h`
- `linux/uio/accel_mmio_demo.c`
- `scripts/gpu3d_lite_reference.py`
- `scripts/npu_v2_reference.py`
- `scripts/npu_v2_pack_model.py`
- `docs/UNIFIED_MEMORY.md`
- `docs/ACCEL_COMMAND_QUEUE.md`
