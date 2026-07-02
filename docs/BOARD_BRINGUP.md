# Board Bring-up

Tai lieu nay da duoc doi huong cho repo `Zybo Z7-10`.

Repo nay khong con la du an "mini PC tren Basys 3" nua. Muc tieu board bring-up hien tai la:

1. build duoc shell `PL-first`
2. co the nap shell bitstream len board de test cac cong co ban
3. export duoc `XSA` cho huong `PS + PL + Linux`

## 1. Build shell bitstream

Mo Windows `CMD` tai thu muc repo va chay:

```bat
scripts\run_vivado_build.bat
```

Neu dang mo Vivado GUI va muon giu cua so mo de xem report sau khi build:

```tcl
cd <duong-dan-repo>
source scripts/run_vivado_build_gui.tcl
```

Build nay tao project Zybo theo `scripts/create_vivado_zybo_project.tcl`, set top synthesis la
`zybo_z7_10_accel_shell`, va ky vong bitstream o:

```text
build\vivado_zybo\riscv_computer_zybo_z7_10.runs\impl_1\zybo_z7_10_accel_shell.bit
```

File can kiem tra sau khi build:

- `build\vivado_build.log`
- `build\build_status.txt`
- `build\timing_summary_post_route.rpt`
- `build\utilization_post_route.rpt`

## 2. Nap shell len board

Neu muon nap shell `PL-first` qua JTAG, dung:

```bat
scripts\program_zybo_accel_shell.bat
```

Script cu `program_basys3.bat` van duoc giu lai nhu alias tuong thich nguoc, nhung ten dung
de dung cho repo nay la `program_zybo_accel_shell.bat`.

## 3. Dau hieu dung mong doi

Vi day la moc scaffold cho Zybo, dau hieu "dung" hien tai can thuc te va khiem ton:

- bitstream shell duoc tao ra
- JTAG program khong bao loi
- cac cong shell co mat trong top: `uart_rx`, `uart_tx`, `ps2_*`, `spi_*`, `led`
- MMIO/queue/NPU/GPU regression host-side van pass

Khong nen coi repo nay da hoan tat bring-up Linux chi vi build shell pass.

## 4. Handoff sang huong PS + PL

Neu muon di tiep theo duong dung cho Zybo, uu tien export `XSA`:

```tcl
source scripts/export_zybo_ps_xsa.tcl
```

File handoff du kien:

```text
build/hw/zybo_z7_10_ps_pl.xsa
```

Summary du kien:

```text
build/zybo_ps_xsa_status.txt
```

Sau moc nay moi hop ly de tiep tuc `PetaLinux`, `UIO`, hoac driver/kernel flow.

## 5. Neu muon xem lai nguon goc Basys 3

Nhung thanh phan legacy nhu `top_basys3.v`, `constraints/basys3_top.xdc`, `monitor_shell_tb`, va
monitor/boot ROM regression van duoc giu lai trong repo nay nhu nguon tham chieu migration.

Phan giai thich ro hon nam o:

- `docs/MIGRATION_FROM_BASYS3.md`
- `docs/ARCHITECTURE_ZYBO.md`
