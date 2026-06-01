; Press End to black out the screen using a fullscreen black GUI.
; Press End again to restore everything.
; Does NOT lock the PC — just hides windows and shows a black overlay.

$End:: {
    static blackScreenActive := false
    static guiHwnd := 0

    if (!blackScreenActive) {
        ; Get the virtual screen dimensions
        virtualX := SysGet(76)
        virtualY := SysGet(77)
        virtualW := SysGet(78)
        virtualH := SysGet(79)

        ; Create a fullscreen black GUI
        blackGui := Gui("-Caption +AlwaysOnTop +ToolWindow")
        blackGui.BackColor := "Black"
        blackGui.Show("x" virtualX " y" virtualY " w" virtualW " h" virtualH)
        guiHwnd := blackGui.Hwnd

        ; Hide taskbars
        WinHide("ahk_class Shell_TrayWnd")
        WinHide("ahk_class Shell_SecondaryTrayWnd")

        ; Hide the cursor (call repeatedly to overcome the reference counter)
        loop 10 {
            DllCall("user32\ShowCursor", "int", 0)
        }

        ; Block user input
        BlockInput("On")

        blackScreenActive := true
    } else {
        ; Restore everything
        BlockInput("Off")

        ; Show the cursor (call repeatedly to restore the reference counter)
        loop 10 {
            DllCall("user32\ShowCursor", "int", 1)
        }

        ; Show taskbars
        try WinShow("ahk_class Shell_TrayWnd")
        try WinShow("ahk_class Shell_SecondaryTrayWnd")

        ; Destroy the black GUI
        if (guiHwnd) {
            try GuiFromHwnd(guiHwnd).Destroy()
        }
        guiHwnd := 0

        blackScreenActive := false
    }
}
