--
-- UpdateState.lua
--
-- Manages the auto-update process via a background thread.
--
-- SERVER SETUP INSTRUCTIONS:
-- 1. Host a 'version.json' file at the URL specified in Constants.lua (UPDATE_URL).
-- 2. Structure of 'version.json':
--    {
--      "version": "1.0.1",
--      "files": [
--        { "path": "main.lua", "url": "http://yourserver.com/patch/1.0.1/main.lua" },
--        { "path": "src/states/PlayState.lua", "url": "http://yourserver.com/patch/1.0.1/src/states/PlayState.lua" }
--      ]
--    }
-- 3. Ensure the 'version' field is semantically higher than GAME_VERSION in Constants.lua to trigger an update.
--

local UpdateState = BaseState:extend()

function UpdateState:new()
    self.statusText = "Initializing Update System..."
    self.progress = 0
    self.currentFile = ""
    self.error = nil
    self.complete = false
    
    -- Transition logic
    self.transitioning = false
    self.transitionTimer = 0
    self.nextState = nil
    self.restart = false
    
    -- Use global thread/channels
    self.commandChannel = love.thread.getChannel('update_commands')
    self.statusChannel = love.thread.getChannel('update_status')
    
    -- Load same background as menu
    if love.filesystem.getInfo('imgs/menu.png') then
        self.background = love.graphics.newImage('imgs/menu.png')
    end
end

function UpdateState:enter()
    if gUpdateAvailable and gUpdateFiles then
        self.statusText = "Update Available! Starting Download..."
        self.commandChannel:push({
            command = 'download_update',
            files = gUpdateFiles
        })
    else
        self.statusText = "Checking for updates..."
        self.commandChannel:push({
            command = 'check_update',
            url = UPDATE_URL,
            currentVersion = GAME_VERSION
        })
    end
end

function UpdateState:update(dt)
    -- Consume ALL messages to prevent main.lua from grabbing them
    while true do
        local msg = self.statusChannel:pop()
        if not msg then break end
        
        if msg.type == 'progress' then
            self.statusText = msg.data.phase
            if msg.data.file then
                self.currentFile = msg.data.file
            end
            self.progress = msg.data.percent
            
        elseif msg.type == 'update_available' then
            self.statusText = "Update Found: " .. msg.data.version
            -- Update global state just in case
            gUpdateAvailable = true
            gUpdateFiles = msg.data.files
            
            -- Automatically start download
            self.commandChannel:push({
                command = 'download_update',
                files = msg.data.files
            })
            
        elseif msg.type == 'no_update' then
            self.statusText = "Game is up to date!"
            -- Transition to Menu after a brief delay
            self.transitioning = true
            self.transitionTimer = 2
            self.nextState = 'menu'
            
        elseif msg.type == 'error' then
            self.error = msg.data
            self.statusText = "Error: " .. tostring(msg.data)
            
            self.transitioning = true
            self.transitionTimer = 3
            self.nextState = 'menu'
            
        elseif msg.type == 'complete' then
            self.statusText = "Update Complete! Press 'R' to Restart."
            self.complete = true
            -- Disable auto-restart to debug crash
            -- self.restart = true
        end
    end
    
    -- Thread error handling
    local err = gUpdateThread:getError()
    if err then
        self.error = err
    end
    
    -- Handle Transitions
    if self.transitioning then
        self.transitionTimer = self.transitionTimer - dt
        if self.transitionTimer <= 0 then
            if self.nextState then
                gStateMachine:change(self.nextState)
            end
        end
    end
    
    -- Manual Restart
    if self.complete and love.keyboard.isDown('r') and not self.restarting then
         self.restarting = true
         self.statusText = "Restarting..."
         
         -- Gracefully stop thread
         self.commandChannel:push({command='quit'})
         gUpdateThread:wait()
         
         love.event.quit("restart")
    end
end

function UpdateState:renderUI()
    -- Draw Background
    if self.background then
        local winW = love.graphics.getWidth()
        local winH = love.graphics.getHeight()
        local scale = math.max(winW / self.background:getWidth(), winH / self.background:getHeight())
        love.graphics.setColor(0.5, 0.5, 0.5, 1) -- Dimmed
        love.graphics.draw(self.background, 0, 0, 0, scale, scale)
    else
        love.graphics.clear(0.1, 0.1, 0.1, 1)
    end
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- Semi-transparent Overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, width, height)
    
    -- Modal Box
    local boxW, boxH = 500, 200
    local boxX = (width - boxW) / 2
    local boxY = (height - boxH) / 2
    
    -- Box Background
    love.graphics.setColor(0.15, 0.15, 0.2, 1)
    love.graphics.rectangle('fill', boxX, boxY, boxW, boxH, 10, 10)
    
    -- Box Border
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle('line', boxX, boxY, boxW, boxH, 10, 10)
    
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(1, 1, 1, 1)
    
    if self.error then
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.printf("Update Failed", boxX, boxY + 40, boxW, 'center')
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(self.error, boxX + 20, boxY + 80, boxW - 40, 'center')
        love.graphics.printf("Continuing to game...", boxX, boxY + 140, boxW, 'center')
    else
        love.graphics.printf("SYSTEM UPDATE", boxX, boxY + 30, boxW, 'center')
        
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(self.statusText, boxX, boxY + 70, boxW, 'center')
        
        -- Progress Bar
        local barW = 400
        local barH = 20
        local barX = (width - barW) / 2
        local barY = boxY + 110
        
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.rectangle('fill', barX, barY, barW, barH)
        
        if self.progress > 0 then
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
            love.graphics.rectangle('fill', barX, barY, barW * self.progress, barH)
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('line', barX, barY, barW, barH)
        
        if self.currentFile ~= "" then
            love.graphics.setFont(gFonts['tiny'])
            love.graphics.printf("Processing: " .. self.currentFile, boxX, barY + 30, boxW, 'center')
        end
    end
    
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.printf("v" .. GAME_VERSION, 0, height - 20, width - 10, 'right')
end

return UpdateState
