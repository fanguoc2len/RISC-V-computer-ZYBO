@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "REPO_DIR=%SCRIPT_DIR%.."
set "BITFILE=%REPO_DIR%\build\vivado_zybo\riscv_computer_zybo_z7_10.runs\impl_1\zybo_z7_10_accel_shell.bit"

call "%SCRIPT_DIR%resolve_vivado_bin.bat" || exit /b 1

if not exist "%BITFILE%" (
  echo ERROR: Chua co bitstream Zybo shell. Hay chay scripts\run_vivado_build.bat truoc.
  echo Duong dan du kien:
  echo   "%BITFILE%"
  exit /b 1
)

call "%VIVADO_BIN%\vivado.bat" -mode batch -notrace ^
  -source "%SCRIPT_DIR%program_zybo_accel_shell.tcl" ^
  -log "%REPO_DIR%\build\program_zybo_accel_shell.log" ^
  -journal "%REPO_DIR%\build\program_zybo_accel_shell.jou"

if errorlevel 1 (
  echo Program Zybo shell FAILED.
  echo Xem log: "%REPO_DIR%\build\program_zybo_accel_shell.log"
  exit /b %errorlevel%
)

echo Program Zybo shell FINISHED.
echo Log: "%REPO_DIR%\build\program_zybo_accel_shell.log"
