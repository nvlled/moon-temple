---@meta

-- This file contains type annotations for the lua language server:
-- https://github.com/luals/lua-language-server
--
-- Usage: place this file on your project root.

---@type (fun(selector: string): fun(args: table): table) | fun(args: table): table
function CSS() end

---@type fun(types: string): fun(args: table): table
function CSS_MEDIA() end

---@type fun(tag: string, options?:table): fun(args: table): table
function Node() end

---@alias Tag fun(args: table|string): table

---@type Tag
function HEAD() end

---@type Tag
function TITLE() end

---@type Tag
function BODY() end

---@type Tag
function SCRIPT() end

---@type Tag
function LINK() end

---@type Tag
function STYLE() end

---@type Tag
function META() end

---@type Tag
function A() end

---@type Tag
function BASE() end

---@type Tag
function P() end

---@type Tag
function DIV() end

---@type Tag
function SPAN() end

---@type Tag
function B() end

---@type Tag
function I() end

---@type Tag
function EM() end

---@type Tag
function STRONG() end

---@type Tag
function SMALL() end

---@type Tag
function S() end

---@type Tag
function PRE() end

---@type Tag
function CODE() end

---@type Tag
function OL() end

---@type Tag
function UL() end

---@type Tag
function LI() end

---@type Tag
function FORM() end

---@type Tag
function INPUT() end

---@type Tag
function TEXTAREA() end

---@type Tag
function BUTTON() end

---@type Tag
function LABEL() end

---@type Tag
function SELECT() end

---@type Tag
function OPTION() end

---@type Tag
function TABLE() end

---@type Tag
function THEAD() end

---@type Tag
function TBODY() end

---@type Tag
function COL() end

---@type Tag
function TR() end

---@type Tag
function TD() end

---@type Tag
function SVG() end

---@type Tag
function BR() end

---@type Tag
function HR() end

---@type Tag
function H1() end

---@type Tag
function H2() end

---@type Tag
function H3() end

---@type Tag
function H4() end

---@type Tag
function H5() end

---@type Tag
function H6() end

---@type Tag
function IMG() end

---@type Tag
function AREA() end

---@type Tag
function VIDEO() end

---@type Tag
function IFRAME() end

---@type Tag
function EMBED() end

---@type Tag
function TRACK() end

---@type Tag
function SOURCE() end

---@type Tag
function FRAGMENT() end

---@type fun(args: string): table) | fun(args: table): table
function PP() end

-- type annotations for redbean: https://redbean.dev
---@type fun(): string
function GetPath() end

---@type fun(string): string
function Write() end

---@type fun(): string
function GetMethod() end

-----------------------------------------------------------------

---@type string
COMMAND_ARG = ""

---@type string
AUTORELOAD_SCRIPT = ""

---@type fun(filename: string): table
function GetPageData() end

---@type fun(): table
function GetPageList() end

---@type fun(fn: fun(): table)
function OnPostRender() end

---@type fun(filenames: string[]): table
function QueueBuildFiles() end

-----------------------------------------------------------------

---@type fun(host: string, path: string): string
function Route() end

---@type fun(): string
function GetHost() end

---@type fun()
function Route() end

---@type fun(seconds: integer)
function Sleep() end

---@type fun(key: string, value: string)
function SetHeader() end

---@type fun(filename: string)
function Slurp() end

---@type fun(filename: string, data: string)
function Barf() end

---@type fun(path: string)
function ProgramDirectory() end

path = {}

---@type fun(s: string): boolean
function path.isdir() end

---@type fun(s: string): boolean
function path.exists() end

unix = {}

---@type fun(code?: number): boolean
function unix.exit() end
