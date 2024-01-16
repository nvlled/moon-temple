local function underscore2Dash(s)
    return string.gsub(s, "_", "-")
end

local function cssToString(ruleset)
    local result = ""
    for _, rule in ipairs(ruleset) do
        result = result .. rule.selector .. " {\n"
        for k, v in pairs(rule.declarations) do
            local decl = "  " .. k .. ": " .. v .. ";\n"
            result = result .. decl
        end
        result = result .. "}\n"
    end
    return result
end

local function _CSS(args, selector)
    if not selector then
        selector = ''
    end

    local rule = {
        selector = selector,
        declarations = {},
    }
    local result = {
        type = "css",
        rule,
    }

    for key, value in pairs(args) do
        if type(key) == "string" then
            if type(value) == "table" then
                local subRules = _CSS(value, selector .. " " .. key)
                for _, s in ipairs(subRules) do
                    table.insert(result, s)
                end
            elseif type(value) == "number" then
                rule.declarations[underscore2Dash(key)] = tostring(value) .. "px"
            else
                rule.declarations[underscore2Dash(key)] = tostring(value)
            end
        elseif type(key) == "number" and type(value) == "table" then
            for k, v in pairs(value) do
                if type(v) == "number" then
                    rule.declarations[underscore2Dash(k)] = tostring(v) .. "px"
                else
                    rule.declarations[underscore2Dash(k)] = v
                end
            end
        else
            error("invalid declaration")
        end
    end

    return result
end

function CSS(selector)
    return function(args)
        local css = _CSS(args, selector)
        setmetatable(css, {
            __tostring = cssToString
        })

        return css
    end
end

return CSS
