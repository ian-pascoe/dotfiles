#Requires AutoHotkey v2.0

; Flow Launcher on Win+Space
; - Pressing the Windows key alone still opens the Start Menu
; - Win+Space will launch (if not running) or toggle Flow Launcher (by sending its default Alt+Space hotkey)
; - If you changed Flow Launcher's own hotkey, modify the Send() line accordingly
;
; Note: Win+Space is normally used by Windows for input language switching. This script overrides that combo.

flowLauncherPaths := [
  "C:\APPS\scoop\apps\flow-launcher\current\Flow.Launcher.exe"
]

getFlowLauncherPath() {
    global flowLauncherPaths
    for p in flowLauncherPaths {
        if FileExist(p)
            return p
    }
    return ""
}

launchOrToggleFlow() {
    exeName := "Flow.Launcher.exe"
    if !ProcessExist(exeName) {
        path := getFlowLauncherPath()
        if (path != "") {
            Run(path)
            ; Wait briefly for the process/window (non-fatal if it times out)
            WinWait("ahk_exe " exeName, , 2000)
        } else {
            ; Could not locate executable—fallback: try sending its default hotkey
            Send("!{Space}")
            return
        }
    } else {
        ; Already running: send (default) toggle hotkey Alt+Space
        Send("!{Space}")
    }
}

#Space::
{
    launchOrToggleFlow()
}

Return
