@echo off

perl mpcmon.pl ^
--run ^
--port 13578 ^
--window-title "%~n0" ^
--snapshot-dir "p:\temp\mpc\snapshots" ^
--status-file "p:\temp\mpc\.mpcmon\status.json" ^
--lock-file "p:\temp\mpc\.mpcmon\lock" ^
--log-file "p:\temp\mpc\.mpcmon\log" %*
rem --after-move "dlc"
rem --after-delete "..."

if %errorlevel% gtr 0 pause
