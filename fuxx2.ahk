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
; 全局配置与状态（fuxx2：极简双条件悬停保活 + 纯净 Win+1/2/3 路由）
; 核心交互：
; 1. 唤醒：按住 Win 键 + 鼠标放到底部 -> 任务栏持续展开显示（此时松开 Win 键也不会缩回）
; 2. 交互：只要鼠标在任务栏/托盘/右键菜单内，持续保持显示，从容点击或拖拽重排 Pin 图标
; 3. 收起：鼠标一旦移出任务栏范围 -> 自动平滑隐藏
; 4. 防误触：鼠标单独划到底部坚决不弹！
; 5. 快捷键：Win+1/2/3/4... 瞬发切换应用，150ms 自然收起，零焦点干扰
; 6. 纯净精简：彻底剔除三击 Win 检测与全局鼠标按键 Hook，极低系统开销
; 7. 稳定性：彻底修复 fuxx9 原始看门狗状态死锁，无需按 Win+1 碰巧解锁
; ============================================================
global g_State := -1             ; 任务栏逻辑状态：-1=未知, 0=隐藏, 1=显示
global g_HoverActive := false    ; 是否已通过 Win+触底 激活了任务栏鼠标悬停交互会话
global g_LeaveGraceTick := 0     ; 鼠标刚移开任务栏时的微缓冲（250ms 防手抖闪烁）

; 退出脚本时恢复任务栏显示，避免残留隐藏
OnExit((*) => DoShow())

; 启动后 600ms 初次收起（等待 Explorer 桌面环境完全加载就绪）
SetTimer(() => DoHide(), -600)

; ============================================================
; 【看门狗】Inspector：每 800ms 巡查一次
; 彻底修复原版 ForceHide 未同步 g_State 的致命 Bug！
; 仅在完全没有保活需求时，压制第三方应用偷弹的任务栏
; ============================================================
SetTimer(Inspector, 800)

Inspector() {
    global g_State
    if ShouldKeepAlive()
        return
        
    prev := DetectHiddenWindows(true)
    hwndMain := WinExist("ahk_class Shell_TrayWnd")
    DetectHiddenWindows(prev)
    if hwndMain && DllCall("User32\IsWindowVisible", "Ptr", hwndMain) {
        ForceHide()
    } else {
        g_State := 0
    }
}

ForceHide() {
    global g_State
    g_State := 0  ; ★★★ 强制同步状态，彻底消灭状态机死锁！
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
; 使用 SW_SHOWNA (8)：纯显示，绝不抢焦点，绝不改变 Z 序，绝不干扰 Win+1/2/3！
; ============================================================
DoShow() {
    global g_State
    prev := DetectHiddenWindows(true)
    hwndMain := WinExist("ahk_class Shell_TrayWnd")
    hwndSec  := WinExist("ahk_class Shell_SecondaryTrayWnd")
    DetectHiddenWindows(prev)
    
    isVis := hwndMain ? DllCall("User32\IsWindowVisible", "Ptr", hwndMain) : false
    if (g_State == 1 && isVis)
        return
        
    g_State := 1
    if hwndMain
        DllCall("User32\ShowWindow", "Ptr", hwndMain, "Int", 8)   ; SW_SHOWNA
    if hwndSec
        DllCall("User32\ShowWindow", "Ptr", hwndSec,  "Int", 8)
}

; ============================================================
; 隐藏任务栏
; ============================================================
DoHide() {
    global g_State
    prev := DetectHiddenWindows(true)
    hwndMain := WinExist("ahk_class Shell_TrayWnd")
    hwndSec  := WinExist("ahk_class Shell_SecondaryTrayWnd")
    DetectHiddenWindows(prev)
    
    isVis := hwndMain ? DllCall("User32\IsWindowVisible", "Ptr", hwndMain) : false
    if (g_State == 0 && !isVis)
        return
        
    g_State := 0
    if hwndMain
        DllCall("User32\ShowWindow", "Ptr", hwndMain, "Int", 0)   ; SW_HIDE
    if hwndSec
        DllCall("User32\ShowWindow", "Ptr", hwndSec,  "Int", 0)
}

; ============================================================
; 【核心引擎】保活仲裁主循环：每 50ms 评估一次全局保活状态
; ============================================================
SetTimer(KeepAliveArbiter, 50)

KeepAliveArbiter() {
    global g_State
    if ShouldKeepAlive() {
        DoShow()
    } else {
        if g_State != 0
            DoHide()
    }
}

; ============================================================
; 保活判定逻辑（真·极简状态流）
; ============================================================
ShouldKeepAlive() {
    global g_HoverActive, g_LeaveGraceTick
    
    ; 1. 系统开始菜单、搜索UI、托盘右键菜单处于打开状态 -> 保持显示
    if IsMenuOrSearchOpen()
        return true

    isWinHeld := GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
    inTaskbar := IsMouseInTaskbarArea()
    atBottom  := IsMouseAtBottomEdge()
    now       := A_TickCount

    ; 2. 【核心唤醒触发点】
    ; 只要同时满足【按住 Win 键】并且【鼠标放到底部/任务栏】，立刻激活悬停交互会话！
    if (isWinHeld && (atBottom || inTaskbar)) {
        g_HoverActive := true
        g_LeaveGraceTick := 0
        return true
    }

    ; 3. 【悬停会话中】：松开 Win 键后依然可以从容操作
    if g_HoverActive {
        if inTaskbar {
            ; 只要鼠标一直在任务栏区域内（点击、拖拽图标、看托盘等），无限保活！
            g_LeaveGraceTick := 0
            return true
        } else {
            ; 鼠标离开任务栏，给 250ms 防手抖缓冲期；超过缓冲期则结束悬停会话并收起
            if (g_LeaveGraceTick == 0) {
                g_LeaveGraceTick := now + 250
                return true
            } else if (now < g_LeaveGraceTick) {
                return true
            } else {
                g_HoverActive := false
                g_LeaveGraceTick := 0
                return false
            }
        }
    }

    ; 4. 【Win 组合键切换期】：按住 Win 键（但未去底栏）
    ; 任务栏保持显示，供系统识别 Win+1/2/3/4... Pin 切换
    if isWinHeld
        return true

    ; 5. 既没按 Win，又不在悬停会话中：鼠标单独放到底部坚决不弹，保持隐藏！
    return false
}

; ============================================================
; 获取鼠标所在显示器的物理工作区底边（支持多显示器与不同DPI缩放）
; ============================================================
GetMouseMonitorBottom() {
    CoordMode "Mouse", "Screen"
    MouseGetPos(&mX, &mY)
    monCount := MonitorGetCount()
    loop monCount {
        MonitorGet(A_Index, &mL, &mT, &mR, &mB)
        if (mX >= mL && mX < mR && mY >= mT && mY < mB)
            return mB
    }
    return A_ScreenHeight
}

; ============================================================
; 检测光标是否处于屏幕最底边（触底判定：距离底边 <= 5 像素）
; ============================================================
IsMouseAtBottomEdge() {
    CoordMode "Mouse", "Screen"
    MouseGetPos(&mX, &mY)
    monB := GetMouseMonitorBottom()
    return (mY >= monB - 5)
}

; ============================================================
; 检测光标是否在任务栏、托盘或其上下文浮层内
; 支持：任务栏背景、Pin 图标子控件、系统托盘区、溢出浮窗、右键菜单等
; ============================================================
IsMouseInTaskbarArea() {
    CoordMode "Mouse", "Screen"
    MouseGetPos(&mX, &mY, &mHwnd)
    if !mHwnd
        return false
        
    prev := DetectHiddenWindows(true)
    hwndMain := WinExist("ahk_class Shell_TrayWnd")
    hwndSec  := WinExist("ahk_class Shell_SecondaryTrayWnd")
    DetectHiddenWindows(prev)
    
    ; 1. 祖先窗口判定（子控件溯源，Pin 图标点击/拖拽支持）
    rootHwnd := DllCall("User32\GetAncestor", "Ptr", mHwnd, "UInt", 2, "Ptr") ; GA_ROOT = 2
    if (mHwnd == hwndMain || mHwnd == hwndSec || rootHwnd == hwndMain || rootHwnd == hwndSec)
        return true
        
    ; 2. 物理几何坐标碰撞判定
    if hwndMain {
        rc := Buffer(16, 0)
        if DllCall("User32\GetWindowRect", "Ptr", hwndMain, "Ptr", rc) {
            tL := NumGet(rc, 0, "Int"), tT := NumGet(rc, 4, "Int")
            tR := NumGet(rc, 8, "Int"), tB := NumGet(rc, 12, "Int")
            if (mX >= tL && mX <= tR && mY >= tT && mY <= tB)
                return true
        }
    }
    if hwndSec {
        rc := Buffer(16, 0)
        if DllCall("User32\GetWindowRect", "Ptr", hwndSec, "Ptr", rc) {
            tL := NumGet(rc, 0, "Int"), tT := NumGet(rc, 4, "Int")
            tR := NumGet(rc, 8, "Int"), tB := NumGet(rc, 12, "Int")
            if (mX >= tL && mX <= tR && mY >= tT && mY <= tB)
                return true
        }
    }
    
    ; 3. 白名单类名与进程判定（系统托盘溢出单、右键上下文菜单、开始菜单等）
    try {
        cClass := WinGetClass(mHwnd)
        rClass := rootHwnd ? WinGetClass(rootHwnd) : ""
        cExe   := WinGetProcessName(mHwnd)
        if (cClass = "Shell_TrayWnd" || rClass = "Shell_TrayWnd"
         || cClass = "Shell_SecondaryTrayWnd" || rClass = "Shell_SecondaryTrayWnd"
         || cClass = "NotifyIconOverflowWindow" || rClass = "NotifyIconOverflowWindow"
         || cClass = "#32768"
         || cClass = "Windows.UI.Core.CoreWindow"
         || cClass = "MSTaskListWClass"
         || cClass = "TrayNotifyWnd"
         || cClass = "ToolbarWindow32"
         || cClass = "DirectUIHWND"
         || cExe = "StartMenuExperienceHost.exe"
         || cExe = "SearchHost.exe"
         || cExe = "SearchApp.exe"
         || cExe = "SearchUI.exe"
         || cExe = "ShellExperienceHost.exe") {
            return true
        }
    }
    
    return false
}

; ============================================================
; 检测开始菜单/Windows 搜索是否仍打开
; ============================================================
IsMenuOrSearchOpen() {
    prev := DetectHiddenWindows(false)
    r := WinExist("ahk_exe StartMenuExperienceHost.exe")
      || WinExist("ahk_exe SearchHost.exe")
      || WinExist("ahk_exe SearchApp.exe")
      || WinExist("ahk_exe SearchUI.exe")
      || WinExist("ahk_class #32768")
    DetectHiddenWindows(prev)
    return r
}

; ============================================================
; Win 键按下：
; 1. 瞬发展现任务栏（SW_SHOWNA），确保原生 Win+1/2/3 完美切换
; 2. 发送 vkE8 屏蔽系统开始菜单误闪烁
; ============================================================
~LWin::
~RWin:: {
    Send "{Blind}{vkE8}"
    DoShow()
}

; ============================================================
; Win 键抬起：
; 1. 组合键（Win+1/2/3, Win+E, Win+R 等）：抬起后 150ms 自动收回任务栏
; 2. 单按松开：
;    - 若已激活底部悬停会话（Win+放到底部），继续保持悬停，绝不收起！
;    - 若没有触发底部悬停会话，松开后立即平滑收起！
; ============================================================
~LWin Up::
~RWin Up:: {
    global g_HoverActive
    
    ; 场景 1：组合键（用户按了 Win+1/2/3/E/R 等）
    if (A_PriorKey != "LWin" && A_PriorKey != "RWin") {
        if !g_HoverActive
            SetTimer(() => (!g_HoverActive && DoHide()), -150)
        return
    }
    
    ; 场景 2：单按 Win 松开
    ; 若当前鼠标未在任务栏激活悬停会话，松开 Win 键立即收回
    if !g_HoverActive {
        DoHide()
    }
}
