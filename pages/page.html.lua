PAGE_TITLE = "test title"
PAGE_DESC = "test desc"

return LAYOUT {
    DIV {
        id = "test-id",
        class = "test-class",
        DIV "this is a div",
        HR,
        SPAN "span elem",
        P {
            class = "ab cd efg",
            "this is a text",
            BR,
            "this is another text",
            BR,
            A { href = "index.html", "This is a link to the other page" }
        },
        STYLE {
            CSS "#test-id" {
                margin = "5px",
                border = "2px solid blue",
                color = "red",
                background_color = "#003",

                a = { color = "white", },
                ["a:visited"] = { color = "gray", },

                span = {
                    color = "yellow"
                },
                [".ab"] = {
                    color = "green"
                }

            }
        },
    },

}
