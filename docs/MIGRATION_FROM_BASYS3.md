# Migration Notes from Basys 3 Repo

## Giu lai

- `third_party/picorv32/picorv32.v`
- boot ROM generator va firmware flow
- cac peripheral nho nhu UART / timer / SPI / PS2
- bai test `monitor_shell_tb` de giu mot regression nhanh

## Bo vai tro trung tam

- `top_basys3.v`
- `constraints/basys3_top.xdc`
- quan diem "PicoRV32 la CPU chinh cua ca he thong"
- `NPU-lite` cu nhu diem dung cuoi

## Lam lai theo board moi

- top-level cho `Zybo Z7-10`
- project creation script
- pin planning / board constraints
- Linux boot flow
- memory architecture dua vao DDR cua Zynq
- accelerator interface AXI / DMA

## Dinh huong moi

Repo cu = tham chieu RTL va regression.

Repo moi = he thong moi, board moi, software stack moi, accelerator moi.
