---@meta
--
-- This file contains type annotations for the lua LSP
-- https://luals.github.io/wiki/annotations
-- This file doesn't need to be imported.


-- type annotations for redbean: https://redbean.dev
---@type fun(): string
function GetPath() end

---@type fun(string): string
function Write() end

---@type fun(): string
function GetMtehod() end

GetMethod = GetMethod

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

path = {}

---@type fun(s: string): boolean
function path.isdir() end

---@type fun(s: string): boolean
function path.exists() end

unix = {}

---@type fun(code?: number): boolean
function unix.exit() end
