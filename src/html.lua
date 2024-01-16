local function tableLen(t)
    local count = 0
    for _, _ in pairs(t) do count = count + 1 end
    return count
end

local function map(t, fn)
    local result = {}
    for i, v in pairs(t) do
        table.insert(result, fn(v, i))
    end
    return result
end

local function indent(s, n)
    -- source: https://stackoverflow.com/a/7615129
    local function strsplit(inputstr, sep)
        if sep == nil then
            sep = "%s"
        end
        local t = {}
        for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
            table.insert(t, str)
        end
        return t
    end

    local result = {}
    for _, line in ipairs(strsplit(s, "\n")) do
        local spaces = ''
        for _ = 1, n do
            spaces = spaces .. '  '
        end
        table.insert(result, spaces .. line)
    end

    return table.concat(result, "\n")
end

local function underscore2Dash(s)
    local result = string.gsub(s, "_", "-")
    return result
end

local function styleToString(t)
    local declarations = {}
    for key, value in pairs(t) do
        if type(key) == "string" then
            if type(value) == "number" then
                table.insert(declarations, underscore2Dash(key) .. ": " .. tostring(value) .. "px")
            else
                table.insert(declarations, underscore2Dash(key) .. ": " .. value)
            end
        else
            error("invalid declaration: " .. tostring(key))
        end
    end

    return table.concat(declarations, "; ")
end

local function attrsToString(attrs)
    if tableLen(attrs) == 0 then return '' end
    local entries = {}
    for k, v in pairs(attrs) do
        if type(k) == "string" then
            if k == "style" and type(v) == "table" then
                table.insert(entries, underscore2Dash(k) .. "=" .. '"' .. styleToString(v) .. '"')
            elseif type(v) == "boolean" then
                table.insert(entries, underscore2Dash(k))
            else
                table.insert(entries, underscore2Dash(k) .. "=" .. '"' .. tostring(v) .. '"')
            end
        end
    end
    return " " .. table.concat(entries, " ")
end

local function nodeToString(node, level)
    if not node.children or #node.children == 0 and node.tag ~= "script" then
        return "<" .. node.tag .. attrsToString(node.attrs) .. "/>"
    end

    if not level then level = 1 end
    local body = table.concat(
        map(node.children, function(sub)
            if type(sub) == "string" then
                return indent(sub, level)
            end
            return indent(nodeToString(sub, level + 1), level)
        end), "\n"
    )
    return "<" .. node.tag .. attrsToString(node.attrs) .. ">\n" ..
        body .. (#body and '\n' or '') .. "</" .. node.tag .. ">"
end

local nodeMeta = {
    __tostring = nodeToString
}

local function _node(tagName, args)
    if type(args) == "string" then
        local result = { tag = tagName, attrs = {}, children = { args } }
        setmetatable(result, nodeMeta)
        return result
    end

    local attrs    = {}
    local children = {}

    for k, v in pairs(args) do
        if type(k) == "string" then
            attrs[k] = v
        elseif type(k) == "number" then
            if type(v) == "string" then
                table.insert(children, v)
            elseif type(v) == "table" then
                local mt = getmetatable(v)
                if mt == nodeMeta then
                    table.insert(children, v)
                elseif mt and mt.__tostring then
                    table.insert(children, tostring(v))
                else
                    local elems = {}
                    for _, elem in ipairs(v) do
                        table.insert(elems, tostring(elem))
                    end
                    table.insert(children, table.concat(elems, " "))
                end
            elseif type(v) == "function" then
                table.insert(children, tostring(v()))
            elseif v then
                table.insert(children, tostring(v))
                --error("invalid child node: " .. type(v))
            end
        end
    end

    local result = { tag = tagName, attrs = attrs, children = children }
    setmetatable(result, nodeMeta)

    return result
end


local function Node(tagName)
    return function(args)
        args = args or {}
        local result = _node(tagName, args)
        return result
    end
end

HTML = Node 'html'
HEAD = Node 'head'
TITLE = Node 'title'
BODY = Node 'body'
SCRIPT = Node 'script'
LINK = Node 'link'
STYLE = Node 'style'
META = Node 'meta'

P = Node 'p'
A = Node 'a'
DIV = Node 'div'
SPAN = Node 'span'

B = Node 'b'
I = Node 'i'
EM = Node 'em'
STRONG = Node 'strong'
SMALL = Node 'small'
S = Node 's'
PRE = Node 'pre'
CODE = Node 'code'

OL = Node 'ol'
UL = Node 'ul'
LI = Node 'li'

FORM = Node 'form'
INPUT = Node 'input'
TEXTAREA = Node 'textarea'
BUTTON = Node 'button'
LABEL = Node 'label'
SELECT = Node 'select'
OPTION = Node 'option'

TABLE = Node 'table'
THEAD = Node 'thead'
TBODY = Node 'tbody'
TR = Node 'tr'
TD = Node 'td'

SVG = Node 'svg'

BR = Node 'br'
HR = Node 'hr'

H1 = Node 'h1'
H2 = Node 'h2'
H3 = Node 'h3'
H4 = Node 'h4'
H5 = Node 'h5'
H6 = Node 'h6'

IMG = Node 'img'
VIDEO = Node 'video'
IFRAME = Node 'iframe'

return {
    Node,
}
