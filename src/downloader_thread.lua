--
-- downloader_thread.lua
--
-- Running in a separate thread.
-- Communicates with Main Thread via Channels.
--

require 'love.filesystem'
require 'love.timer'
require 'love.data' -- Needed for hashing
local json = require 'lib/json'
local http = require 'socket.http'
local ltn12 = require 'ltn12'

-- Try to load HTTPS support
local https_available, https = pcall(require, 'ssl.https')

-- Helper: Universal Request function
local function request(url, sink)
    if url:sub(1, 5) == "https" then
        if https_available then
            return https.request{ url = url, sink = sink }
        else
            return nil, "HTTPS not supported (missing LuaSec)"
        end
    else
        return http.request{ url = url, sink = sink }
    end
end

-- Channels
local commandChannel = love.thread.getChannel('update_commands')
local statusChannel = love.thread.getChannel('update_status')

-- Helper: Send Status
local function sendStatus(type, data)
    statusChannel:push({type = type, data = data})
end

-- Helper: Check Version (Semantic Versioning)
local function isNewer(current, remote)
    local c_major, c_minor, c_patch = current:match("(%d+)%.(%d+)%.(%d+)")
    local r_major, r_minor, r_patch = remote:match("(%d+)%.(%d+)%.(%d+)")
    
    if not c_major or not r_major then return false end -- format header error
    
    if tonumber(r_major) > tonumber(c_major) then return true end
    if tonumber(r_major) < tonumber(c_major) then return false end
    
    if tonumber(r_minor) > tonumber(c_minor) then return true end
    if tonumber(r_minor) < tonumber(c_minor) then return false end
    
    if tonumber(r_patch) > tonumber(c_patch) then return true end
    
    return false
end

-- Helper: Verify File Hash
local function verifyHash(path, expectedHash)
    if not expectedHash then return false end -- Force download if no hash provided
    
    local info = love.filesystem.getInfo(path)
    if not info then return false end
    
    local content = love.filesystem.read(path)
    if not content then return false end
    
    local hash = love.data.hash('md5', content)
    local hexHash = love.data.encode('string', 'hex', hash)
    
    return hexHash == expectedHash
end

-- Command Loop
while true do
    -- Blocking pop (wait for command)
    local msg = commandChannel:pop()
    
    if msg then
        if msg.command == 'check_update' then
            -- 1. Fetch Version Manifest
            sendStatus('progress', {phase = 'Checking', percent = 0})
            
            local url = msg.url
            local currentVersion = msg.currentVersion
            
            local response_body = {}
            local res, code, response_headers = request(url, ltn12.sink.table(response_body))
            
            if code == 200 then
                local jsonStr = table.concat(response_body)
                local status, remoteManifest = pcall(json.decode, jsonStr)
                
                if status and remoteManifest and remoteManifest.version then
                    if isNewer(currentVersion, remoteManifest.version) then
                        sendStatus('update_available', remoteManifest)
                    else
                        sendStatus('no_update', {})
                    end
                else
                    sendStatus('error', "Invalid manifest format")
                end
            elseif not res then
                 sendStatus('error', code) -- code is error message here
            else
                sendStatus('error', "Failed to connect: " .. tostring(code))
            end
            
        elseif msg.command == 'download_update' then
            -- 2. Download Files
            local files = msg.files -- list of {path="src/main.lua", url="http...", md5="..."}
            local total = #files
            local success = true
            
            for i, file in ipairs(files) do
                sendStatus('progress', {
                    phase = 'Verifying ' .. file.path, 
                    file = file.path, 
                    percent = (i-1) / total
                })
                
                -- Check MD5 to see if we can skip
                if verifyHash(file.path, file.md5) then
                    -- Skip download
                    love.timer.sleep(0.01) -- Brief yield
                else
                    -- Download needed
                    sendStatus('progress', {
                        phase = 'Downloading ' .. file.path, 
                        file = file.path, 
                        percent = (i-1) / total
                    })
                    
                    -- Create directory if needed
                    local dir = file.path:match("(.+)/")
                    if dir then
                        love.filesystem.createDirectory(dir)
                    end
                    
                    -- Download
                    local file_content = {}
                    local res, code = request(file.url, ltn12.sink.table(file_content))
                    
                    if code == 200 then
                        local data = table.concat(file_content)
                        if not love.filesystem.write(file.path, data) then
                            sendStatus('error', "Failed to write " .. file.path)
                            success = false
                            break
                        end
                    elseif not res then
                        sendStatus('error', "Download Error: " .. tostring(code))
                        success = false
                        break
                    else
                        sendStatus('error', "Failed to download " .. file.path .. " (" .. tostring(code) .. ")")
                        success = false
                        break
                    end
                end
            end
            
            if success then
                sendStatus('complete', {})
            end
        end
    end
    
    love.timer.sleep(0.1)
end
