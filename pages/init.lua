PAGE_TITLE = ""
PAGE_DESC  = ""
PAGE_BODY  = ""


LAYOUT = function(body)
    return HTML {
        HEAD {
            TITLE(PAGE_TITLE or "test"),
            LINK { rel = "stylesheet", href = "style.css" },
            STYLE {
                CSS "body" {
                }
            },
            SCRIPT {

            }
        },
        BODY {
            H1 { PAGE_TITLE },
            HR,
            HR,
            BR,
            DIV {
                data_x = true,
                data_y = "asdf",
                style = {
                    background_color = "blue"
                }
            },
            body,
        }
    }
end
