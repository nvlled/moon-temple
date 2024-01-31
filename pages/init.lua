-- init.lua will automatically be ran (dofile'd) before rendering each lua file

-- Default values, these can be overriden by each page
PAGE_TITLE = ""
PAGE_DESC  = ""
PAGE_BODY  = ""

LAYOUT     = function(body)
    return HTML {
        HEAD {
            META { charset = "utf-8" },
            TITLE(PAGE_TITLE or "test"),
            LINK { rel = "stylesheet", href = "/style.css" },
        },
        BODY {
            H1 { PAGE_TITLE },
            H2 / A { href = "#link", "some heading with link" },
            H3 "heading 3",
            DIV {
                data_x = true,
                data_y = "asdf",
                style = {
                    background_color = "blue"
                },
                EM "div contents 1",
                BR,
                S "div contents 2",
            },
            body,
        }
    }
end
