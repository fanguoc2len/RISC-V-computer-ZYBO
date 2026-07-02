@echo off
setlocal

echo INFO: program_basys3_click.bat trong repo Zybo chi con la alias tuong thich nguoc.
call "%~dp0program_zybo_accel_shell_click.bat"
exit /b %errorlevel%
