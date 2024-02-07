PAGE_TITLE = "home page"

return LAYOUT {
    DIV {
        H1 "testing",
        HR,
        H2 "testing 2",
    },
    IMG { src = "yomama.png", style = "max-width: 300px" },
    COMMAND_ARG == "serve" and SCRIPT (AUTORELOAD_SCRIPT),
}
