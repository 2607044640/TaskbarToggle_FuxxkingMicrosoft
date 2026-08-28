#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; 管理员权限
; ============================================================
if not A_IsAdmin {
    Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

; ============================================================
; 状态变量：-1=未初始化, 0=应隐藏, 1=应显示
; ============================================================
global g_State := -1

; ============================================================
; 退出时恢复任务栏
; ============================================================
OnExit((*) => DoShow())

; ============================================================
; 启动后 600ms 隐藏（等 Explorer 完全加载）
; ============================================================
SetTimer(() => DoHide(), -600)

; ============================================================
; 【核心修复】Inspector：每 800ms 巡查一次
;
; Bug 根因：微信/QQ 等 app 通过 Shell 通知机制（NIM_MODIFY）
; 绕过脚本，直接让 Windows 强制 ShowWindow(Shell_TrayWnd)，
; 导致任务栏弹出但 g_State 仍为 0（状态失同步）。
; 用两次 Win 键才能藏回去，是因为第一次 DoHide() 刚藏完，
; 通知还在 pending，Windows 立刻又弹出来；
; 第二次按时通知刚好超时，hide 才生效。
;
; Inspector不依赖 Win 键，每 800ms 自动检查并强制修复，
; 任务栏最多弹出不到 1 秒就会被压回去。
; ============================================================
SetTimer(Inspector, 800)

Inspector() {
    global g_State
    if g_State != 0          ; 只在"应该隐藏"状态下工作
        return
    prev := DetectHiddenWindows(true)
    hwndMain := WinExist("ahk_class Shell_TrayWnd")
    DetectHiddenWindows(prev)
    ; 如果任务栏此刻是可见的，说明被系统偷偷弹出来了，立刻压回去
    if hwndMain && DllCall("User32\IsWindowVisible", "Ptr", hwndMain)
        ForceHide()
}

; ============================================================
; 强制隐藏（不检查 g_State，专供看门狗调用）
; g_State 已经是 0，不需要修改
; ============================================================
ForceHide() {
    prev := DetectHiddenWindows(true)
    hwndMain := WinExist("ahk_class Shell_TrayWnd")
    hwndSec  := WinExist("ahk_class Shell_SecondaryTrayWnd")
    DetectHiddenWindows(prev)
    if hwndMain
        DllCall("User32\ShowWindow", "Ptr", hwndMain, "Int", 0)   ; SW_HIDE
    if hwndSec
        DllCall("User32\ShowWindow", "Ptr", hwndSec,  "Int", 0)
}

; ============================================================
; Win 键按下：立刻显示任务栏（开始菜单/Win 快捷键正常用）
; ============================================================
~LWin::
~RWin:: {
    Send "{Blind}{vkE8}"
    DoShow()
}

; ============================================================
; Win 键抬起：150ms 后判断是否收回任务栏
; ============================================================
~LWin Up::
~RWin Up:: {
    SetTimer DeferHide, -150
}

; ============================================================
; 延迟隐藏：等开始菜单彻底关闭后再藏
; ============================================================
DeferHide() {
    if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
        return
    if IsMenuOpen() {
        SetTimer DeferHide, -200
        return
    }
    DoHide()
}

; ============================================================
; 检测开始菜单/搜索是否仍可见（Win10/11 均兼容）
; ============================================================
IsMenuOpen() {
    prev := DetectHiddenWindows(false)
    r := WinExist("ahk_exe StartMenuExperienceHost.exe")
      || WinExist("ahk_exe SearchHost.exe")
      || WinExist("ahk_exe SearchApp.exe")
      || WinExist("ahk_exe SearchUI.exe")
    DetectHiddenWindows(prev)
    return r
}

; ============================================================
; 显示任务栏
; SW_SHOWNA (8)：显示但不抢焦点
; ============================================================
DoShow() {
    global g_State
    if g_State = 1
        return
    g_State := 1
    prev := DetectHiddenWindows(true)
    hwndMain := WinExist("ahk_class Shell_TrayWnd")
    hwndSec  := WinExist("ahk_class Shell_SecondaryTrayWnd")
    DetectHiddenWindows(prev)
    if hwndMain
        DllCall("User32\ShowWindow", "Ptr", hwndMain, "Int", 8)   ; SW_SHOWNA
    if hwndSec
        DllCall("User32\ShowWindow", "Ptr", hwndSec,  "Int", 8)
}

; ============================================================
; 隐藏任务栏
; SW_HIDE (0)：直接隐藏
; ============================================================
DoHide() {
    global g_State
    if g_State = 0
        return
    g_State := 0
    prev := DetectHiddenWindows(true)
    hwndMain := WinExist("ahk_class Shell_TrayWnd")
    hwndSec  := WinExist("ahk_class Shell_SecondaryTrayWnd")
    DetectHiddenWindows(prev)
    if hwndMain
        DllCall("User32\ShowWindow", "Ptr", hwndMain, "Int", 0)   ; SW_HIDE
    if hwndSec
        DllCall("User32\ShowWindow", "Ptr", hwndSec,  "Int", 0)
}