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
    
    -- Start the downloader thread
    self.thread = love.thread.newThread("src/downloader_thread.lua")
    self.thread:start()
    
    -- Communication Channels
    self.commandChannel = love.thread.getChannel('update_commands')
    self.statusChannel = love.thread.getChannel('update_status')
end

function UpdateState:enter()
    self.statusText = "Checking for updates..."
    self.commandChannel:push({
        command = 'check_update',
        url = UPDATE_URL,
        currentVersion = GAME_VERSION
    })
end

function UpdateState:update(dt)
    -- Check for messages from the thread
    local msg = self.statusChannel:pop()
    
    if msg then
        if msg.type == 'progress' then
            self.statusText = msg.data.phase
            if msg.data.file then
                self.currentFile = msg.data.file
            end
            self.progress = msg.data.percent
            
        elseif msg.type == 'update_available' then
            self.statusText = "Update Found: " .. msg.data.version
            -- Automatically start download (or prompt user if desired)
            self.commandChannel:push({
                command = 'download_update',
                files = msg.data.files
            })
            
        elseif msg.type == 'no_update' then
            self.statusText = "Game is up to date!"
            -- Transition to Menu after a brief delay
            self.transitioning = true
            self.transitionTimer = 1
            self.nextState = 'menu'
            
        elseif msg.type == 'error' then
            self.error = msg.data
            self.statusText = "Error: " .. tostring(msg.data)
            
            -- Retry or Continue to Menu? Let's verify files anyway
            self.transitioning = true
            self.transitionTimer = 3
            self.nextState = 'menu'
            
        elseif msg.type == 'complete' then
            self.statusText = "Update Complete! Restarting..."
            self.complete = true
            
            self.transitioning = true
            self.transitionTimer = 2
            self.restart = true
        end
    end
    
    -- Thread error handling
    local err = self.thread:getError()
    if err then
        self.error = err
    end
    
    -- Handle Transitions
    if self.transitioning then
        self.transitionTimer = self.transitionTimer - dt
        if self.transitionTimer <= 0 then
            if self.restart then
                love.event.quit("restart")
            elseif self.nextState then
                gStateMachine:change(self.nextState)
            end
        end
    end
end

function UpdateState:render()
    -- Draw Background (reuse menu background if available, or just black)
    love.graphics.clear(0.1, 0.1, 0.1, 1)
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(1, 1, 1, 1)
    
    if self.error then
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.printf("Update Failed", 0, height/2 - 60, width, 'center')
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(self.error, 0, height/2 - 20, width, 'center')
        love.graphics.printf("Continuing to game...", 0, height/2 + 20, width, 'center')
    else
        love.graphics.printf(self.statusText, 0, height/2 - 40, width, 'center')
        
        -- Progress Bar
        if self.progress > 0 then
            local barW = 400
            local barH = 20
            local barX = (width - barW) / 2
            local barY = height/2 + 20
            
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle('fill', barX, barY, barW, barH)
            
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
            love.graphics.rectangle('fill', barX, barY, barW * self.progress, barH)
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle('line', barX, barY, barW, barH)
            
            if self.currentFile ~= "" then
                love.graphics.setFont(gFonts['small'])
                love.graphics.printf("Downloading: " .. self.currentFile, 0, barY + 30, width, 'center')
            end
        end
    end
    
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.printf("v" .. GAME_VERSION, 10, height - 20, width, 'left')
end

return UpdateState
