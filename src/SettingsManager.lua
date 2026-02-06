local SettingsManager = {}

SettingsManager.fileName = "settings.lua"

-- Simple table serialization (Reuse logic or keep simple)
function SettingsManager.serialize(t)
    local s = "{\n"
    for k, v in pairs(t) do
        if type(k) == "string" then
            s = s .. "['" .. k .. "'] = "
        end
        
        if type(v) == "number" or type(v) == "boolean" then
            s = s .. tostring(v) .. ",\n"
        elseif type(v) == "string" then
            s = s .. "'" .. v .. "',\n"
        end
    end
    s = s .. "}"
    return s
end

function SettingsManager.save(data)
    local content = "return " .. SettingsManager.serialize(data)
    love.filesystem.write(SettingsManager.fileName, content)
end

function SettingsManager.load()
    if not love.filesystem.getInfo(SettingsManager.fileName) then
        return nil
    end
    
    local chunk = love.filesystem.load(SettingsManager.fileName)
    if chunk then
        return chunk()
    end
    return nil
end

return SettingsManager
