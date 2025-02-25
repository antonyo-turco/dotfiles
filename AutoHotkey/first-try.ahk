#Requires AutoHotkey v2.0

^Enter:: { ; Control + Enter
    MsgBox "The active window's class is " WinGetClass("A")
} 
