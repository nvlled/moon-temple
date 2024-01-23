local ext = require("ext")

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function tableLen(t)
    local count = 0
    for _, _ in pairs(t) do count = count + 1 end
    return count
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
        ext.map(node.children, function(sub)
            if type(sub) == "string" then
                return sub
            end
            return nodeToString(sub, level)
        end), ""
    )

    if node.tag == '' then
        return body
    end

    return "<" .. node.tag .. attrsToString(node.attrs) .. ">" ..
        body .. "</" .. node.tag .. ">"
end

local appendChild = function(a, b)
    if type(a) == "function" then
        a = a()
    end
    table.insert(
        a.children, type(b) == "function" and b() or b
    )
    return a
end

local nodeMeta = {
    __tostring = nodeToString,
    __div = appendChild,
    __pow = appendChild,
}

local function _node(tagName, args)
    if type(args) == "string" then
        local result = { tag = tagName, attrs = {}, children = { args } }
        setmetatable(result, nodeMeta)
        return result
    end

    local attrs    = {}
    local children = {}

    if getmetatable(args) == nodeMeta then
        args = { args }
    end

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
                    for _, elem in ipairs(v) do
                        if getmetatable(elem) == nodeMeta then
                            table.insert(children, elem)
                        elseif type(elem) == "function" or getmetatable(elem).__call then
                            table.insert(children, elem())
                        else
                            table.insert(children, elem)
                        end
                    end
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

local ctorMeta = {
    __call = function(self, args) return self.ctor(args) end,
    __pow = function(self, args) return self.ctor(args) end,
    __div = function(self, args) return self.ctor(args) end,
    __idiv = function(self, args) return self.ctor(args) end,
}

function Node(tagName)
    local ctor = function(args)
        args = args or {}
        if getmetatable(args) == ctorMeta then
            args = args {}
        end
        local result = _node(tagName, args)
        return result
    end
    return setmetatable({ ctor = ctor }, ctorMeta)
end

function GetComponentArgs(args)
    local props = {}
    local children = {}
    for k, v in pairs(args) do
        if type(k) == "string" then
            props[k] = v
        else
            table.insert(children, v)
        end
    end

    return props, children
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

FRAGMENT = Node ''

local ppMeta = {
    __div = function(a, b)
        if type(a) == "function" then
            a = a()
        end

        local function f(x)
            if #a.children == 0 then
                table.insert(a.children, x)
            else
                table.insert(
                    a.children[#a.children].children, x
                )
            end
        end

        b = type(b) == "function" and b() or b
        if type(b) == "string" then
            local c = PP(b)

            for _, z in ipairs(c.children[1].children) do
                f(z)
            end

            for i = 2, #c.children do
                appendChild(a, c.children[i])
            end

            return a
        end

        f(b)


        return a
    end,
    __pow = function(a, b) return nodeMeta.__pow(a, b) end,
    __tostring = function(x) return nodeMeta.__tostring(x) end,
}

function PP(args)
    if type(args) == "string" then
        local result = {}
        for block in ext.split(args, "\n\n") do
            if block == '' or not block then
                table.insert(result, BR {})
            else
                table.insert(result, P(block))
            end
        end
        local frag = FRAGMENT(result)

        return setmetatable(frag, ppMeta)
    end

    local p = P {}
    local result = { p }
    for _, arg in ipairs(args) do
        if type(arg) ~= "string" then
            table.insert(p.children, arg)
        else
            local i = 1
            for block in ext.split(arg, "\n\n") do
                if i == 1 then
                    table.insert(p.children, block)
                    goto continue
                end

                if block == '' or not block then
                    table.insert(p.children, BR {})
                else
                    p = P {}
                    table.insert(result, p)
                    table.insert(p.children, block)
                end

                ::continue::
                i = i + 1
            end
        end
    end

    local frag = FRAGMENT(result)

    return setmetatable(frag, ppMeta)
end

return {
    Node,
}
