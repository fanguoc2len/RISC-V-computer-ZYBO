@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "REPO_DIR=%SCRIPT_DIR%.."
set "BITFILE=%REPO_DIR%\build\vivado_zybo\riscv_computer_zybo_z7_10.runs\impl_1\zybo_z7_10_accel_shell.bit"

call "%SCRIPT_DIR%resolve_vivado_bin.bat" || exit /b 1

if not exist "%REPO_DIR%\build" mkdir "%REPO_DIR%\build"

call "%VIVADO_BIN%\vivado.bat" -mode batch -notrace ^
  -source "%SCRIPT_DIR%run_vivado_build.tcl" ^
  -log "%REPO_DIR%\build\vivado_build.log" ^
  -journal "%REPO_DIR%\build\vivado_build.jou"

if errorlevel 1 (
  echo Vivado build FAILED.
  echo Xem log: "%REPO_DIR%\build\vivado_build.log"
  exit /b %errorlevel%
)

if not exist "%BITFILE%" (
  echo Vivado build FAILED.
  echo Khong tim thay bitstream sau khi Vivado ket thuc.
  echo Xem log: "%REPO_DIR%\build\vivado_build.log"
  exit /b 1
)

echo Vivado build FINISHED.
echo Bitstream du kien nam o:
echo   "%BITFILE%"
if exist "%REPO_DIR%\build\build_status.txt" (
  echo Build summary:
  type "%REPO_DIR%\build\build_status.txt"
)
echo Reports:
echo   "%REPO_DIR%\build\timing_summary_post_route.rpt"
echo   "%REPO_DIR%\build\utilization_post_route.rpt"
echo Log: "%REPO_DIR%\build\vivado_build.log"
