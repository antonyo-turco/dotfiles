#Requires AutoHotkey >=2.0- <2.1
#SingleInstance Force

; Pressing Control + Enter opens terminal
^Enter:: { 
    ; Check if a terminal session is open and in focus
    activeWindowClass := WinGetClass("A")
    if (activeWindowClass = "CASCADIA_HOSTING_WINDOW_CLASS") {
        WinMinimize("A")
        return
    }

    ; Check if a terminal session exists and is hidden
    if (WinExist("ahk_class CASCADIA_HOSTING_WINDOW_CLASS")) {
        WinActivate
        WinMaximize
        ; Screen:	1913, 9
        ; Window:	1924, 20
        ; Color:	C42B1C (Red=C4 Green=2B Blue=1C)
        color := PixelGetColor(1913, 9)  ; get the color of this area
        ; the x should not be grey in full screen
        ; if (color=="0x2E2E2E") {   ; if it's grey (= fullscreen is OFF)
        ;     send "{f11}" ; then press f11 to activate fullscreen
        ; }
        return
    } 
    ;If a terminal was not opened, open a new one and set it in fullscreen
    Run("wt.exe")
    ;sleep(2000)
    ;Send "{f11}"  
    return    
}

; Pressing Windows+Shift+D opens file explorer in Downloads
#+d:: {
  Run "explorer.exe C:\Users\anton\Downloads"
}

; Pressing Caps Lock pauses media playback
CapsLock:: {
    Send("{Media_Play_Pause}")
}

RShift:: {
    Send("{Media_Play_Pause}")
}