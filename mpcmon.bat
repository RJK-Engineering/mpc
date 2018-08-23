@cd\
@perl C:\scripts\mpc\mpcmon.pl ^
--run ^
--port 13578 ^
--window-title "%~n0" ^
--snapshot-dir "c:\data\mpc\snapshots" ^
--status-file "c:\data\mpc\.mpcmon\status.json" ^
--lock-file "c:\data\mpc\.mpcmon\lock" ^
--log-file "c:\data\mpc\.mpcmon\log" %*
rem --after-move "dlc"
rem --after-delete "..."

@if %errorlevel% gtr 0 pause
