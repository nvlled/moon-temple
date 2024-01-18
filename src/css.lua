local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function map(t, fn)
    local result = {}
    for i, v in pairs(t) do
        table.insert(result, fn(v, i))
    end
    return result
end

local function underscore2Dash(s)
    return string.gsub(s, "_", "-")
end

local function cssToString(ruleset)
    local result = ""
    for _, rule in ipairs(ruleset) do
        if not rule or rule.selector == "" then
            goto continue
        end
        result = result .. trim(rule.selector) .. " {\n"
        for k, v in pairs(rule.declarations) do
            local decl = "  " .. k .. ": " .. v .. ";\n"
            result = result .. decl
        end
        result = result .. "}\n"

        ::continue::
    end
    return result
end

local cssMeta = {
    __tostring = cssToString
}

local function strsplit(inputstr, sep)
    local i = 1
    return function()
        local a, b = inputstr:find(sep, i)
        if i then
            if not a then
                local s = inputstr:sub(i, -1)
                i = nil
                return s
            else
                local s = inputstr:sub(i, a - 1)
                i = b + 1
                return s
            end
        end
    end
end

local function appendSelector(parent, child, nospace)
    local sep = nospace and '' or ' '
    if not child:find(',') then
        return parent .. sep .. child
    end

    local xs = {}
    for k in strsplit(child, ",") do
        k = k:match("^%s*(.-)%s*$")
        table.insert(xs, parent .. sep .. k)
    end

    return table.concat(xs, ", ")
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
    local subRules = {}

    for key, value in pairs(args) do
        if type(key) == "string" then
            if type(value) == "table" then
                local subRules = _CSS(value, appendSelector(selector, key, true))
                for _, s in ipairs(subRules) do
                    table.insert(result, s)
                end
            elseif type(value) == "number" then
                rule.declarations[underscore2Dash(key)] = tostring(value) .. "px"
            else
                rule.declarations[underscore2Dash(key)] = tostring(value)
            end
        elseif type(key) == "number" and type(value) == "table" then
            table.insert(subRules, value)
        else
            error("invalid declaration")
        end
    end

    for _, value in ipairs(subRules) do
        if getmetatable(value) == cssMeta then
            for _, rule in ipairs(value) do
                rule.selector = appendSelector(selector, rule.selector)
                table.insert(result, rule)
            end
        else
            for k, v in pairs(value) do
                if type(v) == "number" then
                    rule.declarations[underscore2Dash(k)] = tostring(v) .. "px"
                else
                    rule.declarations[underscore2Dash(k)] = v
                end
            end
        end
    end

    return result
end

function CSS(selector)
    if type(selector) == "table" then
        local css = _CSS(selector, '')
        setmetatable(css, cssMeta)
        return css
    end

    return function(args)
        local css = _CSS(args, selector)
        setmetatable(css, cssMeta)

        return css
    end
end

return CSS
