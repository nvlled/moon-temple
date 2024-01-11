local inspect = require("inspect")

function CSS(arg, root)
    if type(arg[1]) ~= "string" then
        error("must provide selector to css")
    end
    local selector = arg[1]
    table.remove(arg, 1)

    if root then
        selector = root .. " " .. selector
    end

    local rule = {
        selector = selector,
        declarations = {},
    }
    local result = {
        type = "css",
        rule,
    }

    for key, value in pairs(arg) do
        if type(key) == "string" then
            if type(value) == "number" then
                rule.declarations[key] = tostring(value) .. "px"
            else
                rule.declarations[key] = value
            end
        elseif type(key) == "number" then
            if type(value) ~= "table" then
                error("sub-declarations must be a table")
            end
            local subRules = CSS(value, selector)
            for _, s in ipairs(subRules) do
                table.insert(result, s)
            end
        else
            error("invalid declaration")
        end
    end

    return result
end

function RenderCSS(ruleset)
    local result = ""
    for _, rule in ipairs(ruleset) do
        result = result .. rule.selector .. " {\n"
        for k, v in pairs(rule.declarations) do
            -- TODO: handle style
            local decl = "  " .. k .. ": " .. v .. ";\n"
            result = result .. decl
        end
        result = result .. "}\n"
    end
    return result
end

function renderStyle() end

--[[
css = CSS{...}
print(renderCSS(css)) == '.x { color: "red"; }'


local css = (CSS "div.root#blah") {
    background = "red",
    color = "white",
    CSS(".x") {
        background = "blue",
        color = "green",
        CSS(".Z") {
            border = 5,
        }
    }
}

]]

local css = CSS { "div.root",
    background = "red",
    color = "white",
    { ".x",
        background = "blue",
        color = "green",
        { ".z",
            border = 5,
        }
    }
}

print(inspect(css))
print("---------")
print(RenderCSS(css))

--[[
div.root {
    background: "red";
    color: "white";
}

div.root .x {
    background: "red";
    color: "white";
}

div.root .x .z {
    background: "red";
    color: "white";
}

]]

return CSS
