#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; 管理员权限自提
; ============================================================
if not A_IsAdmin {
    Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

; ============================================================
; 状态变量
; g_State: -1=未初始化, 0=应隐藏, 1=应显示
; g_Persistent: false=常态隐藏模式, true=任务栏暂时持久化模式
; g_WinTapCount: 记录快速按 Win 键的次数
; ============================================================
global g_State := -1
global g_Persistent := false
global g_WinTapCount := 0

; ============================================================
; 退出时恢复任务栏显示
; ============================================================
OnExit((*) => DoShow())

; ============================================================
; 启动后 600ms 隐藏（等 Explorer 完全加载）
; ============================================================
SetTimer(() => DoHide(), -600)

; ============================================================
; 【看门狗】Inspector：每 800ms 巡查一次
; 仅在常态隐藏状态下工作（!g_Persistent 且 g_State == 0）
; 防止微信/QQ等第三方应用通过通知偷偷弹起任务栏
; 在持久化模式下绝不压回
; ============================================================
SetTimer(Inspector, 800)

Inspector() {
    global g_State, g_Persistent
    if g_Persistent || g_State != 0
        return
    prev := DetectHiddenWindows(true)
    hwndMain := WinExist("ahk_class Shell_TrayWnd")
    DetectHiddenWindows(prev)
    if hwndMain && DllCall("User32\IsWindowVisible", "Ptr", hwndMain)
        ForceHide()
}

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

; ============================================================
; 进入 / 退出持久化模式
; ============================================================
EnterPersistentMode() {
    global g_Persistent, g_WinTapCount
    g_Persistent := true
    g_WinTapCount := 0
    DoShow()
}

ExitPersistentMode() {
    global g_Persistent, g_WinTapCount
    if !g_Persistent
        return
    g_Persistent := false
    g_WinTapCount := 0
    DoHide()
}

; ============================================================
; Win 键按下：
; 无论常态还是持久化，按下 Win 瞬间必须显示任务栏，
; 这样 Windows 原生 Win+1/2/3/4/5/6/7/8/9/0 切换 Pin 软件及其他 Win 组合键才能正常响应！
; ============================================================
~LWin::
~RWin:: {
    Send "{Blind}{vkE8}"
    DoShow()
}

; ============================================================
; Win 键抬起：
; 1. 组合键（Win+1/2/3, Win+E, Win+R等）：抬起后 150ms 自动收起任务栏
; 2. 持久化模式下单按 Win：立刻退出持久化并收起任务栏
; 3. 常态下单按 Win：计数 +1，若 450ms 内未达到 3 次则 450ms 后收起；若达到 3 次则进入持久化常驻
; ============================================================
~LWin Up::
~RWin Up:: {
    global g_Persistent, g_WinTapCount
    
    ; 检查是否为组合键（若刚按过 1/2/3/E/R 等其他键，A_PriorKey 不是 Win 键）
    if (A_PriorKey != "LWin" && A_PriorKey != "RWin") {
        g_WinTapCount := 0
        if !g_Persistent
            SetTimer(() => (!g_Persistent && DoHide()), -150)
        return
    }
    
    ; 场景 1：如果当前处于持久化模式，单按 1 下 Win 键即刻退出持久化
    if g_Persistent {
        ExitPersistentMode()
        return
    }
    
    ; 场景 2：常态模式下检测快速连按 3 次
    g_WinTapCount++
    if (g_WinTapCount = 1) {
        SetTimer(OnWinTapTimeout, -450)
    } else if (g_WinTapCount = 2) {
        SetTimer(OnWinTapTimeout, -450)
    } else if (g_WinTapCount >= 3) {
        SetTimer(OnWinTapTimeout, 0)
        EnterPersistentMode()
    }
}

OnWinTapTimeout() {
    global g_WinTapCount, g_Persistent
    g_WinTapCount := 0
    if !g_Persistent {
        DoHide()
    }
}

; ============================================================
; 鼠标点击监听：
; 在持久化模式下，点击任何任务栏 UI 之外的区域，立刻退出持久化
; ============================================================
~*LButton::
~*RButton::
~*MButton:: {
    global g_Persistent
    if !g_Persistent
        return
    
    ; 获取鼠标当前所在窗口句柄
    MouseGetPos ,, &clickedHwnd
    if !clickedHwnd
        return
    
    try {
        clickedClass := WinGetClass(clickedHwnd)
        clickedExe   := WinGetProcessName(clickedHwnd)
    } catch {
        return
    }
    
    ; 白名单放行：任务栏主窗口、副屏任务栏、托盘折叠菜单、上下文右键菜单、开始菜单、Windows搜索UI等
    if (clickedClass = "Shell_TrayWnd" 
     || clickedClass = "Shell_SecondaryTrayWnd"
     || clickedClass = "NotifyIconOverflowWindow"
     || clickedClass = "#32768"
     || clickedClass = "Windows.UI.Core.CoreWindow"
     || clickedExe = "StartMenuExperienceHost.exe"
     || clickedExe = "SearchHost.exe"
     || clickedExe = "SearchApp.exe"
     || clickedExe = "SearchUI.exe"
     || clickedExe = "ShellExperienceHost.exe") {
        return
    }
    
    ; 点击了任务栏 UI 外部区域，立刻退出持久化
    ExitPersistentMode()
}
