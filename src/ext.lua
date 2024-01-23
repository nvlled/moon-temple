local P = {}
function P.relativePath(srcPath, targetPath, srcPath)
    if targetPath:sub(1, 1) ~= "/" or not srcPath or srcPath == '' then
        return targetPath
    end

    local slashCount = 0
    local i = 1
    while true do
        local j = srcPath:find("/", i)
        if not j then
            break
        end
        slashCount = slashCount + 1
        i = j + 1
    end

    return string.rep("../", slashCount - 1) .. targetPath:sub(2)
end

function P.map(t, fn)
    local result = {}
    for i, v in pairs(t) do
        table.insert(result, fn(v, i))
    end
    return result
end

function P.split(inputstr, sep)
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

function P.endsWith(s, suffix)
    return s:sub(- #suffix) == suffix
end

function P.getFileExt(s)
    local lastDotIndex = -1
    local i = #s
    while i > 1 do
        if s:sub(i, i) == "." then
            lastDotIndex = i
        end
        i = i - 1
    end
    if lastDotIndex > 0 then
        return s:sub(lastDotIndex, -1)
    end

    return ""
end

function P.alt(x, y)
    if not x or x == '' then
        return y
    end
    return x
end

return P
