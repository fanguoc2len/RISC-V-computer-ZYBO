## Zybo Z7-10 template constraints
##
## Muc dich cua file nay la danh dau diem bat dau cho board moi.
## Khong co gang hardcode pin khi chua verify tu master XDC / board file.
##
## Viec can lam tiep theo:
## 1. nap Digilent Zybo Z7 board files vao Vivado
## 2. tao block design Zynq PS
## 3. map cac PL ports can thiet nhu LED / UART / PMOD / video
## 4. thay file template nay bang constraint da verify
##
## Goi y:
## - Neu dung Zynq PS UART, phan serial console Linux se di qua MIO.
## - Cac cong PL trong `zybo_z7_10_accel_shell.v` chi la shell cho giai doan dau.
