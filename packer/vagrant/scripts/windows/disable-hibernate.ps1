Start-Process "powercfg" "/hibernate off" -Wait
Start-Process "powercfg" "-change -standby-timeout-ac 0" -Wait