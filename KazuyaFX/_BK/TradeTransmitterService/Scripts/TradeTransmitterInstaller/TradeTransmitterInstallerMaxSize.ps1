Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Window {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr GetForegroundWindow();
}
"@

# 3 = SW_MAXIMIZE
$SW_MAXIMIZE = 3

# 現在アクティブなウィンドウを取得して最大化
$hwnd = [Window]::GetForegroundWindow()
[Window]::ShowWindow($hwnd, $SW_MAXIMIZE) | Out-Null
