require 'html'
require 'css'

local systemPackages = {}
for k, v in pairs(package.loaded) do
    systemPackages[k] = v
end

local args
local options
local serveDir = "pages"

local function endsWith(s, suffix)
    return s:sub(- #suffix) == suffix
end

---@type fun(dir: string, type: "init"|"pre"|"post")
local function runHook(dir, type)
    local hookFile = path.join(dir, "__" .. type .. "__.lua")

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
            local eqIndex = string.find(x, '=')
            if eqIndex then
                local val = string.sub(x, eqIndex + 1, -1)
                x = string.sub(x, 1, eqIndex - 1)
                options[x] = val
            else
                skipNext = true
                options[x] = arg[i + 1]
            end
        end

        ::continue::
    end

    return args, options
end

args, options = parseOptions()
if options["init"] then
    dofile(options["init"])
end

function OnHttpRequest()
    for k in pairs(package.loaded) do
        if not systemPackages[k] then
            package.loaded[k] = nil
            print("reloading", k)
        end
    end

    local function isDir(file)
        local st = unix.stat(file)
        if not st then return false end
        return unix.S_ISDIR(st:mode())
    end

    runHook(".", "pre")

    local pagePath = "." .. GetPath()
    PAGE_PATH = GetPath()

    if isDir(pagePath) then
        pagePath = pagePath .. "index.html"
    end

    if not endsWith(pagePath, ".lua") then
        pagePath = pagePath .. ".lua"
    end

    if path.exists(pagePath) then
        local filename = pagePath
        local contents = dofile(filename)

        runHook(".", "post")

        if not contents then
            contents = PAGE_BODY
        end

        Write(tostring(contents))
    else
        Route()
    end
end

local command = args[1]

if command == "build" then
    local function walkDir(root, fn, subDir)
        local function loop(dir)
            for name, kind, ino, off in assert(unix.opendir(path.join(root, dir))) do
                if name == '.' or name == '..' then
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
            if data == '' then break end
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

        if srcDir == destDir then
            error("source and destination directories cannot be the same")
        end

        if isSubDir(destDir, srcDir) then
            error("destination cannot be inside source")
        end
        if isSubDir(srcDir, destDir) then
            error("source cannot be inside destination")
        end
    end


    local srcDir = arg[2]
    local destDir = arg[3] or "output"

    if not srcDir then
        print("source directory is required")
        unix.exit(1)
    end

    checkDestDir(srcDir, destDir)

    if Slurp(path.join(destDir, ".site-generator")) == "moon-temple" then
        print("cleaning " .. destDir)
        unix.rmrf(destDir)
    end

    package.path = package.path .. ";" .. unix.realpath(srcDir) .. "/?.lua"

    runHook(srcDir, "init")

    walkDir(srcDir, function(filename, kind)
        local src = path.join(srcDir, filename)
        local dest = path.join(destDir, filename)
        unix.makedirs(path.dirname(dest))

        if endsWith(dest, ".lua") then
            PAGE_PATH = "/" .. string.sub(filename, 1, #filename - 4)

            runHook(srcDir, "init")
            runHook(srcDir, "pre")

            local contents = dofile(src)
            contents = runHook(srcDir, "post") or contents

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
            print("copy " .. src .. " -> " .. dest)
            copyFile(src, dest)
        end
    end)

    Barf(path.join(destDir, ".site-generator"), "moon-temple")
elseif command == "build" then
elseif command == "render" then
    local filename = args[2]
    if not filename then
        print("filename is required")
        unix.exit(1)
    end

    runHook(path.dirname(filename), "init")
    runHook(path.dirname(filename), "pre")

    local contents = dofile(filename)
    contents = runHook(path.dirname(filename), "post") or contents

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


    local function addRelPath(dir)
        local spath =
            debug.getinfo(1, 'S').source
            :sub(2)
            :gsub("^([^/])", "./%1")
            :gsub("[^/]*$", "")
        dir = dir and (dir .. "/") or ""
        spath = spath .. dir
        package.path = spath .. "?.lua;"
            .. spath .. "?/init.lua"
            .. package.path
    end

    package.path = package.path .. ";" .. unix.realpath(serveDir) .. "/?.lua"

    ProgramDirectory(unix.realpath(serveDir))

    runHook(serveDir, "init")
    unix.chdir(serveDir)
else
    print("usage: " .. arg[-1] .. " <serve | render | build> <filename | dir>")
    print("-h to see help documentation")
end

if command ~= "serve" then
    unix.exit(0)
end
