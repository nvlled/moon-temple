require "html"
require "css"
local ext = require "ext"

local systemPackages = {}
for k, v in pairs(package.loaded) do
    systemPackages[k] = v
end

local args
local options
local serveDir = "pages"

local Stub
Stub = {
    __call = function(self) return {} end,
    __concat = function(self) return {} end,
    __div = function(self) return {} end,
    __pow = function(self) return {} end,
    __idiv = function(self) return {} end,
}
function StubFunction()
    return {}
end

function GetPageData(filename)
    local env = {}
    for k, v in pairs(_ENV) do
        if type(v) == "function" then
            env[k] = StubFunction
        else
            env[k] = v
        end
    end

    local f = loadfile(filename, "t", env)
    if f then
        pcall(f)
    end

    return env
end

function GetBasePath(path)
    local i = string.find(path, "/")
    local j = string.find(path, "/", i + 1)
    if not j then
        return ""
    end
    return path:sub(2, j - 1)
end

function GetPageList()
    local result = {}

    WalkDir(".", function(filename)
        local fileExt = ext.getFileExt(filename)
        local link = "/" .. filename
        if fileExt == ".html.lua" then
            link = "/" .. filename:sub(1, #filename - 4)
        elseif fileExt ~= ".html" then
            return
        end

        local dir, base = ext.dirPath(link)

        local data = GetPageData(filename)

        table.insert(result, {
            filename = filename,
            link = link,
            path = { dir = dir, base = base },
            title = data.PAGE_TITLE,
            desc = data.PAGE_DESC,
            datetimeStr = data.PAGE_DATE,
            datetime = ext.parseDateTime(data.PAGE_DATE),
        })
    end)

    table.sort(result, function(x, y)
        if x.datetime and y.datetime then return x.datetime > y.datetime end
        if x.datetime and not y.datetime then return true end
        if not x.datetime and y.datetime then return false end

        return false
    end)

    return result
end

function WalkDir(root, fn)
    local function loop(dir)
        for name, kind, ino, off in assert(unix.opendir(path.join(root, dir))) do
            if name == "." or name == ".." then
                goto continue
            end

            local filename = path.join(dir, name)
            if kind == unix.DT_DIR then
                loop(filename)
            else
                fn(filename, kind)
            end

            ::continue::
        end
    end

    loop("")
end

local function endsWith(s, suffix)
    return s:sub(- #suffix) == suffix
end

---@type fun(dir: string, type: "init")
local function runHook(dir, type)
    local hookFile = path.join(dir, type .. ".lua")

    if options[type] then
        dofile(options[type])
    elseif path.exists(hookFile) then
        dofile(hookFile)
    end
end

local function parseOptions()
    local args = {}
    local options = {}

    local skipNext = false
    for i, x in ipairs(arg) do
        if skipNext then
            skipNext = false
            goto continue
        end

        if x:sub(1, 1) ~= "-" then
            table.insert(args, x)
        else
            local j = 1
            while x:sub(j, j) == "-" do j = j + 1 end
            x = string.sub(x, j)
            local eqIndex = string.find(x, "=")
            if eqIndex then
                local val = string.sub(x, eqIndex + 1, -1)
                x = string.sub(x, 1, eqIndex - 1)
                options[x] = val
            else
                skipNext = true
                options[x] = arg[i + 1]
            end

            if options[x] == "0" or options[x] == "false" or options[x] == "" then
                options[x] = false
            end
        end

        ::continue::
    end

    return args, options
end


function OnHttpRequest()
    for k in pairs(package.loaded) do
        if not systemPackages[k] then
            package.loaded[k] = nil
        end
    end

    local function isDir(file)
        local st = unix.stat(file)
        if not st then return false end
        return unix.S_ISDIR(st:mode())
    end


    PAGE_PATH = GetPath()
    local pagePath = "." .. PAGE_PATH

    if isDir(pagePath) then
        pagePath = pagePath .. "index.html"
    end

    if not endsWith(pagePath, ".lua") then
        pagePath = pagePath .. ".lua"
    end

    if path.exists(pagePath) then
        runHook(".", "init")
        local filename = pagePath
        local contents = dofile(filename)

        if not contents then
            contents = PAGE_BODY
        end


        local actualFilename = filename:sub(1, #filename - 4)
        local contentType = ProgramContentType(actualFilename)
        if contentType then
            SetHeader("Content-Type", contentType)
        end

        Write(tostring(contents))
    else
        Route()
    end
end

args, options = parseOptions()
local command = args[1]

if command == "build" then
    local function deferClose(fd)
        local file = { fd = fd }
        setmetatable(file, { __close = function() unix.close(fd) end })
        return file
    end

    local function copyFile(src, dest)
        local srcFile  = assert(unix.open(src, unix.O_RDONLY))
        local destFile = assert(unix.open(dest, unix.O_WRONLY|unix.O_CREAT|unix.O_TRUNC, 0644))

        while true do
            local data = unix.read(srcFile)
            if data == "" then break end
            unix.write(destFile, data)
        end

        unix.close(srcFile)
        unix.close(destFile)
    end

    local function isSubDir(base, dir)
        if base:sub(-1, -1) ~= "/" then base = base .. "/" end
        return dir:sub(1, #base) == base
    end

    local function checkDestDir(srcDir, destDir)
        if not unix.stat(srcDir) then
            error("source directory does not exist")
        end

        unix.makedirs(destDir)
        srcDir = unix.realpath(srcDir)
        destDir = unix.realpath(destDir)

        if srcDir == destDir and not options.inplace then
            error("source and destination directories cannot be the same, unless set --inplace")
        elseif isSubDir(destDir, srcDir) then
            error("destination cannot be inside source")
        elseif isSubDir(srcDir, destDir) then
            error("source cannot be inside destination")
        end
    end

    local srcDir = args[2]
    local destDir = args[3] or "output"

    if not srcDir then
        print("source directory is required")
        unix.exit(1)
    end

    checkDestDir(srcDir, destDir)

    if Slurp(path.join(destDir, ".site-generator")) == "moon-temple" then
        print("cleaning " .. destDir)
        unix.rmrf(destDir)
        unix.makedirs(destDir)
    end

    srcDir = unix.realpath(srcDir)
    destDir = unix.realpath(destDir)
    package.path = package.path .. ";" .. path.join(unix.realpath(srcDir), "?.lua")

    unix.chdir(srcDir)

    if srcDir == destDir or options.inplace then
        WalkDir(srcDir, function(filename, kind)
            local src = path.join(srcDir, filename)
            local dest = path.join(destDir, filename)
            unix.makedirs(path.dirname(path.dirname(dest)))

            if not endsWith(dest, ".lua") then
                return
            end

            dest = string.sub(dest, 1, #dest - 4) -- remove .lua from filename

            PAGE_PATH = "/" .. string.sub(filename, 1, #filename - 4)

            runHook(".", "init")

            local contents = dofile(src)

            if not contents then
                contents = PAGE_BODY
            end

            local str = tostring(contents)
            if str and str ~= "" then
                print("render " .. src .. " -> " .. dest)
                Barf(dest, str, 0644)
            end
        end)
    else
        WalkDir(srcDir, function(filename, kind)
            local src = path.join(srcDir, filename)
            local dest = path.join(destDir, filename)
            unix.makedirs(path.dirname(dest))

            if endsWith(dest, ".lua") then
                PAGE_PATH = "/" .. string.sub(filename, 1, #filename - 4)

                runHook(".", "init")

                local contents = dofile(src)

                if not contents then
                    contents = PAGE_BODY
                end

                local str = tostring(contents)
                if str and str ~= "" then
                    local dest2 = string.sub(dest, 1, #dest - 4) -- remove .lua from filename
                    print("render " .. src .. " -> " .. dest2)
                    Barf(dest2, str, 0644)
                end
            else
                print("copy " .. unix.realpath(ext.relativePath(src)) .. " -> " .. dest)
                copyFile(src, dest)
            end
        end)

        Barf(path.join(destDir, ".site-generator"), "moon-temple")
    end
elseif command == "run" then
    local filename = args[2]
    if not filename then
        print("filename is required")
        unix.exit(1)
    end

    dofile(filename)
elseif command == "render" then
    local projectDir = args[2]
    local filename = args[3]

    if not projectDir or not filename then
        print("usage: " .. arg[-1] .. " render <project_dir> [page-filename.html.lua]")
        unix.exit(1)
    end

    package.path = package.path .. ";" .. path.join(unix.realpath(projectDir), "?.lua")
    unix.chdir(projectDir)

    runHook(".", "init")

    if not unix.stat(filename) then
        print("file not found: \"" .. filename .. "\" in \"" .. projectDir .. "\"")
        unix.exit(1)
    end

    local contents = dofile(filename)

    if not contents then
        contents = PAGE_BODY
    end

    print(contents)
elseif command == "serve" then
    serveDir = args[2]

    if not serveDir then
        print("serveDir required")
        unix.exit()
    end

    package.path = package.path .. ";" .. unix.realpath(serveDir) .. "/?.lua"

    ProgramDirectory(unix.realpath(serveDir))

    unix.chdir(serveDir)
else
    print("usage: " .. arg[-1] .. " <serve | render | build> <filename | dir>")
    print("-h to see help documentation")
end

if command ~= "serve" then
    unix.exit(0)
end