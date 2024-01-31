local ext = require("ext")

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function tableLen(t)
    if not t then return 0 end
    local count = 0
    for _, _ in pairs(t) do count = count + 1 end
    return count
end

local function underscore2Dash(s)
    local result = string.gsub(s, "_", "-")
    return result
end

local function attrEscape(attr)
    attr = attr:gsub("\"", "&quot;")
    attr = attr:gsub("'", "&#39;")
    return attr
end

local function htmlEscape(html)
    html = html:gsub("&", "&amp;")
    html = html:gsub(">", "&gt;")
    html = html:gsub("<", "&lt;")
    return html
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
    if tableLen(attrs) == 0 then return "" end
    local entries = {}
    for k, v in pairs(attrs) do
        if type(k) == "string" then
            k = attrEscape(underscore2Dash(k))
            if k == "style" and type(v) == "table" then
                table.insert(entries, underscore2Dash(k) .. "=" .. '"' .. attrEscape(styleToString(v)) .. '"')
            elseif type(v) == "boolean" then
                table.insert(entries, underscore2Dash(k))
            else
                table.insert(entries, underscore2Dash(k) .. "=" .. '"' .. attrEscape(tostring(v)) .. '"')
            end
        end
    end
    return " " .. table.concat(entries, " ")
end

local function nodeToString(node, level)
    local prefix = node.options.prefix or ""
    local suffix = node.options.suffix or ""

    if node.options.selfClosing then
        if not node.children or #node.children == 0 and node.tag ~= "script" then
            local tag = node.tag or ""
            return prefix .. "<" .. tag .. attrsToString(node.attrs) .. "/>" .. suffix
        end
    end

    if not level then level = 1 end

    local body = table.concat(
        ext.map(node.children, function(sub)
            if type(sub) == "string" then
                return htmlEscape(sub)
            end
            return nodeToString(sub, level)
        end), ""
    )

    if node.tag == "" then
        return body
    end

    return prefix .. "<" .. node.tag .. attrsToString(node.attrs) .. ">" ..
        body .. "</" .. node.tag .. ">" .. suffix
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

local ctorMeta
local nodeMeta = {
    __tostring = nodeToString,
    __div = appendChild,
    __pow = appendChild,
}

local function _node(tagName, args, options)
    if type(args) == "string" then
        local result = { tag = tagName, attrs = {}, children = { args }, options = options or {} }
        setmetatable(result, nodeMeta)
        return result
    end

    local attrs    = {}
    local children = {}

    if getmetatable(args) ~= nil then
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
                elseif mt and mt == ctorMeta then
                    table.insert(children, v())
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
                table.insert(children, "x" .. tostring(v()))
            elseif v then
                table.insert(children, "y" .. tostring(v))
                --error("invalid child node: " .. type(v))
            end
        end
    end

    local result = { tag = tagName, attrs = attrs, children = children, options = options or {} }
    setmetatable(result, nodeMeta)

    return result
end

ctorMeta = {
    __call = function(self, args) return self.ctor(args) end,
    __pow = function(self, args) return self.ctor(args) end,
    __div = function(self, args) return self.ctor(args) end,
    __idiv = function(self, args) return self.ctor(args) end,
}

function Node(tagName, options)
    local ctor = function(args)
        args = args or {}
        if getmetatable(args) == ctorMeta then
            args = args {}
        end
        local result = _node(tagName, args, options)
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

HTML = Node("html", { prefix = "<!DOCTYPE html>" })

HEAD = Node "head"
TITLE = Node "title"
BODY = Node "body"
SCRIPT = Node "script"
LINK = Node("link", { selfClosing = true })
STYLE = Node "style"
META = Node("meta", { selfClosing = true })

A = Node "a"
BASE = Node("base", { selfClosing = true })

P = Node "p"
DIV = Node "div"
SPAN = Node "span"

B = Node "b"
I = Node "i"
EM = Node "em"
STRONG = Node "strong"
SMALL = Node "small"
S = Node "s"
PRE = Node "pre"
CODE = Node "code"

OL = Node "ol"
UL = Node "ul"
LI = Node "li"

FORM = Node "form"
INPUT = Node("input", { selfClosing = true })
TEXTAREA = Node "textarea"
BUTTON = Node "button"
LABEL = Node "label"
SELECT = Node "select"
OPTION = Node "option"

TABLE = Node "table"
THEAD = Node "thead"
TBODY = Node "tbody"
COL = Node("col", { selfClosing = true })
TR = Node "tr"
TD = Node "td"

SVG = Node "svg"

BR = Node("br", { selfClosing = true })
HR = Node("hr", { selfClosing = true })

H1 = Node "h1"
H2 = Node "h2"
H3 = Node "h3"
H4 = Node "h4"
H5 = Node "h5"
H6 = Node "h6"

IMG = Node("img", { selfClosing = true })
AREA = Node("area", { selfClosing = true })

VIDEO = Node "video"
IFRAME = Node "iframe"
EMBED = Node("embed", { selfClosing = true })
TRACK = Node("track", { selfClosing = true })
SOURCE = Node("source", { selfClosing = true })

FRAGMENT = Node ""

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
            if block == "" or not block then
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

                if block == "" or not block then
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
