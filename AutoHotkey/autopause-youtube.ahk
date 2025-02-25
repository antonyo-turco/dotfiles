#SingleInstance force
#SingleInstance force

SetTitleMatchMode, 2
#IfWinNotActive, Firefox
^k::ControlSend, , ^!p, Firefox
#IfWinNotActive