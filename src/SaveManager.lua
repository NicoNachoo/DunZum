local SaveManager = {}

SaveManager.fileName = "save.lua"

-- Simple recursive table serialization to Loua code
function SaveManager.serialize(t, indent)
    indent = indent or ""
    local nextIndent = indent .. "  "
    local s = "{\n"
    
    for k, v in pairs(t) do
        s = s .. nextIndent
        
        -- Serialize Key
        if type(k) == "string" then
            s = s .. "['" .. k .. "'] = "
        elseif type(k) == "number" then
            s = s .. "[" .. k .. "] = "
        end
        
        -- Serialize Value
        if type(v) == "table" then
            s = s .. SaveManager.serialize(v, nextIndent) .. ",\n"
        elseif type(v) == "string" then
            s = s .. "'" .. v .. "',\n"
        elseif type(v) == "number" or type(v) == "boolean" then
            s = s .. tostring(v) .. ",\n"
        else
            s = s .. "nil,\n" -- Skip functions/userdata
        end
    end
    
    s = s .. indent .. "}"
    return s
end

function SaveManager.save(data)
    local content = "return " .. SaveManager.serialize(data)
    local success, message = love.filesystem.write(SaveManager.fileName, content)
    if not success then
        print("Save failed: " .. tostring(message))
    end
    return success
end

function SaveManager.load()
    if not love.filesystem.getInfo(SaveManager.fileName) then
        return nil
    end
    
    local chunk = love.filesystem.load(SaveManager.fileName)
    if chunk then
        return chunk()
    end
    return nil
end

function SaveManager.exists()
    return love.filesystem.getInfo(SaveManager.fileName) ~= nil
end

function SaveManager.delete()
    love.filesystem.remove(SaveManager.fileName)
end

return SaveManager
