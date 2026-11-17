# Takes a screenshot of the game without showing a window or stealing focus.
#
# The game is started on a separate, invisible Windows desktop, so its window never
# appears on the user's desktop and can never become the foreground window.
# (Start flags such as "no activate" or an off-screen position do not help: Godot asks
# for the foreground itself right after start.)
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\screenshot.ps1 -Out C:\path\shot.png
#       [-Scene res://scenes/battle/battle_scene.tscn] [-Setup res://path/to/setup.gd] [-Wait 0.5]
#
# -Setup: a GDScript with `static func setup(scene: Node) -> void`, called after the scene
#         is added, to bring the game into the state to capture. See tools/screenshot.gd.
#
# NOTE: keep this file ASCII only. Windows PowerShell 5.1 misreads UTF-8 without BOM.
param(
    [Parameter(Mandatory = $true)][string]$Out,
    [string]$Scene = "",
    [string]$Setup = "",
    [double]$Wait = 0.5,
    [int]$TimeoutSeconds = 60
)

$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class HiddenDesktopRunner {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct STARTUPINFO {
        public int cb; public string lpReserved; public string lpDesktop; public string lpTitle;
        public int dwX; public int dwY; public int dwXSize; public int dwYSize;
        public int dwXCountChars; public int dwYCountChars; public int dwFillAttribute;
        public int dwFlags; public short wShowWindow; public short cbReserved2;
        public IntPtr lpReserved2; public IntPtr hStdInput; public IntPtr hStdOutput; public IntPtr hStdError;
    }
    [StructLayout(LayoutKind.Sequential)]
    struct PROCESS_INFORMATION { public IntPtr hProcess; public IntPtr hThread; public int dwProcessId; public int dwThreadId; }

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern bool CreateProcess(string app, StringBuilder cmd, IntPtr pa, IntPtr ta, bool inherit,
        int flags, IntPtr env, string cwd, ref STARTUPINFO si, out PROCESS_INFORMATION pi);
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern IntPtr CreateDesktop(string name, IntPtr device, IntPtr devmode, int flags, uint access, IntPtr sa);
    [DllImport("user32.dll")] static extern bool CloseDesktop(IntPtr h);
    [DllImport("kernel32.dll")] static extern bool TerminateProcess(IntPtr h, int code);
    [DllImport("kernel32.dll")] static extern int WaitForSingleObject(IntPtr h, int ms);
    [DllImport("kernel32.dll")] static extern bool GetExitCodeProcess(IntPtr h, out int code);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);

    const uint GENERIC_ALL = 0x10000000;
    const int WAIT_OBJECT_0 = 0;

    // Runs cmdline on a new desktop and waits. Returns the exit code, or -2 on timeout (process is killed).
    public static int Run(string cmdline, string cwd, string desktopName, int timeoutMs) {
        IntPtr desktop = CreateDesktop(desktopName, IntPtr.Zero, IntPtr.Zero, 0, GENERIC_ALL, IntPtr.Zero);
        if (desktop == IntPtr.Zero)
            throw new Exception("CreateDesktop failed: " + Marshal.GetLastWin32Error());
        try {
            var si = new STARTUPINFO();
            si.cb = Marshal.SizeOf(typeof(STARTUPINFO));
            si.lpDesktop = "WinSta0\\" + desktopName;
            PROCESS_INFORMATION pi;
            if (!CreateProcess(null, new StringBuilder(cmdline), IntPtr.Zero, IntPtr.Zero, false, 0,
                    IntPtr.Zero, cwd, ref si, out pi))
                throw new Exception("CreateProcess failed: " + Marshal.GetLastWin32Error());
            try {
                if (WaitForSingleObject(pi.hProcess, timeoutMs) != WAIT_OBJECT_0) {
                    TerminateProcess(pi.hProcess, 1);
                    WaitForSingleObject(pi.hProcess, 5000);
                    return -2;
                }
                int code;
                GetExitCodeProcess(pi.hProcess, out code);
                return code;
            } finally {
                CloseHandle(pi.hThread);
                CloseHandle(pi.hProcess);
            }
        } finally {
            CloseDesktop(desktop);
        }
    }
}
'@

$project = Split-Path -Parent $PSScriptRoot
$godot = $env:GODOT_GUI
if (-not $godot) { $godot = "C:\Tools\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" }
if (-not (Test-Path $godot)) { throw "Godot not found: $godot (set GODOT_GUI)" }

$outPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Get-Location).Path, $Out))
$outDir = Split-Path -Parent $outPath
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force $outDir | Out-Null }
if (Test-Path $outPath) { Remove-Item $outPath -Confirm:$false }
$logPath = Join-Path ([System.IO.Path]::GetTempPath()) "hex-rogue-screenshot-$PID.log"

$cmd = "`"$godot`" --path `"$project`" --log-file `"$logPath`" -s res://tools/screenshot.gd --"
$cmd += " `"--out=$outPath`" --wait=$($Wait.ToString([System.Globalization.CultureInfo]::InvariantCulture))"
if ($Scene) { $cmd += " `"--scene=$Scene`"" }
if ($Setup) { $cmd += " `"--setup=$Setup`"" }

$code = [HiddenDesktopRunner]::Run($cmd, $project, "hex-rogue-screenshot-$PID", $TimeoutSeconds * 1000)

$ok = ($code -eq 0) -and (Test-Path $outPath)
if (-not $ok) {
    if ($code -eq -2) { Write-Output "FAILED: timed out after $TimeoutSeconds s (process killed)" }
    else { Write-Output "FAILED: exit code $code" }
    if (Test-Path $logPath) { Get-Content $logPath -Encoding UTF8 }
}
if (Test-Path $logPath) { Remove-Item $logPath -Confirm:$false }
if (-not $ok) { exit 1 }
Write-Output "saved: $outPath"
