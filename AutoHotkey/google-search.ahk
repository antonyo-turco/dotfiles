google(service := 1)
{
    static urls := { 0: ""
        , 1 : "https://www.google.com/search?hl=en&q="
        , 2 : "https://images.google.com/"
        , 3 : "https://www.google.com/maps/search/"
        , 4 : "https://translate.google.com/?sl=auto&tl=en&text=" }
    backup := ClipboardAll
    Clipboard := ""
    Send ^c
    ClipWait 0
    if ErrorLevel
        InputBox query, Google Search,,, 200, 100
    else query := Clipboard
    Run % urls[service] query
    Clipboard := backup
}

F1::google(1) ; Regular search
