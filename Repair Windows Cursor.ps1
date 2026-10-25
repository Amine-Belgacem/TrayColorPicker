Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class CursorRepair {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
}
"@
[CursorRepair]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0) | Out-Null
