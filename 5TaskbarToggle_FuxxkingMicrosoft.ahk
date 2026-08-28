#Requires AutoHotkey v2.0

; ==========================================
; 【新增】：自动获取管理员权限，无视任何高权限游戏/软件的屏蔽
if not A_IsAdmin {
    Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}
; ==========================================

DetectHiddenWindows True
CoordMode "Mouse", "Screen" 

; 初始化一个全局变量，用来记录任务栏的当前状态 (-1代表初始未知状态)
global CurrentTaskbarState := -1 

SetTimer EnforceTaskbarState, 200

~LWin::
~RWin:: {
    Send "{Blind}{vkE8}"
    EnforceTaskbarState()
}

~LWin Up::
~RWin Up:: {
    EnforceTaskbarState()
}

EnforceTaskbarState() {
    global CurrentTaskbarState
    
    isWinDown := GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
    
    ; 5 为显示，0 为隐藏
    targetState := isWinDown ? 5 : 0
    
    ; 【修复核心】：如果当前状态已经和目标状态一致，直接 return 阻断执行。
    ; 这样就避免了一直按住 Win 键，或者平时松开时，每秒 5 次疯狂 DLLCall 导致 explorer.exe 图标渲染崩溃。
    if (CurrentTaskbarState == targetState)
        return
        
    ; 更新状态记录
    CurrentTaskbarState := targetState

    hwndMain := WinExist("ahk_class Shell_TrayWnd")
    hwndSec := WinExist("ahk_class Shell_SecondaryTrayWnd")
    hwndStart := WinExist("ahk_class Button")

    if (hwndMain)
        DllCall("User32.dll\ShowWindow", "Ptr", hwndMain, "Int", targetState)
    if (hwndSec)
        DllCall("User32.dll\ShowWindow", "Ptr", hwndSec, "Int", targetState)
    if (hwndStart)
        DllCall("User32.dll\ShowWindow", "Ptr", hwndStart, "Int", targetState)
}