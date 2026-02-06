local OptionsState = BaseState:extend()

function OptionsState:new()
    self.menuItems = {
        { text = "FULLSCREEN: OFF", action = function() 
            local _, _, flags = love.window.getMode()
            love.window.setFullscreen(not flags.fullscreen)
            self:refreshStrings()
        end },
        { text = "RESOLUTION: 1280x720", action = function()
            local _, _, flags = love.window.getMode()
            if flags.fullscreen then return end -- Block in fullscreen

            local configs = {{w=1280, h=720}, {w=1600, h=900}, {w=1920, h=1080}}
            self.resIndex = (self.resIndex or 1) % #configs + 1
            local conf = configs[self.resIndex]
            love.window.setMode(conf.w, conf.h, {fullscreen = flags.fullscreen, resizable = true})
            self:refreshStrings()
        end },
        { text = "MUSIC VOLUME: 100%", action = function()
            local vol = MusicManager:getVolume()
            vol = vol + 0.25
            if vol > 1.0 then vol = 0 end
            MusicManager:setVolume(vol)
            self:refreshStrings()
        end },
        { text = "BACK", action = function() gStateMachine:pop() end }
    }
    
    self.highlightedIndex = 1
    self.timer = 0
    self:refreshStrings()
end

function OptionsState:refreshStrings()
    local w, h, flags = love.window.getMode()
    self.menuItems[1].text = "FULLSCREEN: " .. (flags.fullscreen and "ON" or "OFF")
    self.menuItems[2].text = "RESOLUTION: " .. w .. "x" .. h
    
    local vol = math.floor(MusicManager:getVolume() * 100 + 0.5)
    self.menuItems[3].text = "MUSIC VOLUME: " .. vol .. "%"
    
    local configs = {{w=1280, h=720}, {w=1600, h=900}, {w=1920, h=1080}}
    for i, conf in ipairs(configs) do
        if conf.w == w and conf.h == h then
            self.resIndex = i
            break
        end
    end
end

function OptionsState:update(dt)
    local mouseX, mouseY = love.mouse.getPosition()
    local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
    local font = gFonts['medium']
    
    -- Mouse Selection
    for i, item in ipairs(self.menuItems) do
        local textW = font:getWidth(item.text)
        local textH = font:getHeight()
        
        -- Special case for slider (Item 3)?
        -- Just use standard detection for now, maybe wider for slider
        
        local x = (winW - textW) / 2
        local y = 100 + (i-1) * 60
        
        if mouseX >= x - 40 and mouseX <= x + textW + 40 and
           mouseY >= y - 10 and mouseY <= y + textH + 10 then
            if self.highlightedIndex ~= i then
                self.highlightedIndex = i
            end
            if love.mouse.wasPressed(1) then
                if i == 3 then
                    -- Click on slider?
                    -- Simplified: Toggle if clicked, or just rely on arrows
                    -- Let's stick to arrows/keys for precise control
                else
                    item.action()
                end
            end
        end
    end
    
    -- Keyboard Input
    if InputManager:wasPressed('up') then
        self.highlightedIndex = self.highlightedIndex - 1
        if self.highlightedIndex < 1 then self.highlightedIndex = #self.menuItems end
    elseif InputManager:wasPressed('down') then
        self.highlightedIndex = self.highlightedIndex + 1
        if self.highlightedIndex > #self.menuItems then self.highlightedIndex = 1 end
    elseif InputManager:wasPressed('confirm') then
        if self.highlightedIndex ~= 3 then -- Volume is handled by arrows
            self.menuItems[self.highlightedIndex].action()
        end
    elseif InputManager:wasPressed('back') then
        gStateMachine:pop()
    end
    
    -- Volume Control
    if self.highlightedIndex == 3 then
        if InputManager:wasPressed('left') then
             local vol = MusicManager:getVolume()
             vol = math.max(0, vol - 0.1)
             MusicManager:setVolume(vol)
             self:refreshStrings()
        elseif InputManager:wasPressed('right') then
             local vol = MusicManager:getVolume()
             vol = math.min(1.0, vol + 0.1)
             MusicManager:setVolume(vol)
             self:refreshStrings()
        end
    end
    
    self.timer = self.timer + dt
end

-- Removed keypressed, using InputManager in update instead

function OptionsState:renderUI()
    local winW = love.graphics.getWidth()
    
    love.graphics.setFont(gFonts['large'])
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("OPTIONS", 0, 40, winW, 'center')
    
    love.graphics.setFont(gFonts['medium'])
    for i, item in ipairs(self.menuItems) do
        local y = 100 + (i-1) * 60
        
        -- Special Draw for Volume Slider (Item 3)
        if i == 3 then
            love.graphics.setColor(1, 1, 1, 1)
            local label = "MUSIC VOLUME"
            local labelW = gFonts['medium']:getWidth(label)
            local x = (winW - labelW) / 2
            
            -- Highlight Logic
            if i == self.highlightedIndex then
                love.graphics.setColor(1, 1, 0, 1)
                
                -- Pentagram Logic
                local cursorX = x + labelW + 35
                local cursorY = y + 10
                local radius = 10 + math.sin(self.timer * 5) * 2
                love.graphics.setColor(1, 0, 0, 1)
                self:drawPentagram(cursorX, cursorY, radius, self.timer * 2)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            
            -- Draw Label
            love.graphics.print(label, x, y)
            
            -- Draw Slider
            local sliderW = 200
            local sliderH = 10
            local sliderX = (winW - sliderW) / 2
            local sliderY = y + 30
            
            -- Background
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle('fill', sliderX, sliderY, sliderW, sliderH)
            
            -- Fill
            local vol = MusicManager:getVolume()
            local fillW = vol * sliderW
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.rectangle('fill', sliderX, sliderY, fillW, sliderH)
            
            -- Border
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle('line', sliderX, sliderY, sliderW, sliderH)
            
            -- Percentage Text
            love.graphics.setFont(gFonts['small'])
            love.graphics.printf(math.floor(vol * 100) .. "%", 0, sliderY + 15, winW, 'center')
            love.graphics.setFont(gFonts['medium'])
            
        else
            -- Standard Text Item
            local textW = gFonts['medium']:getWidth(item.text)
            local x = (winW - textW) / 2
            
            if i == self.highlightedIndex then
                love.graphics.setColor(1, 1, 0, 1)
                local cursorX = x + textW + 35
                local cursorY = y + 10
                local radius = 10 + math.sin(self.timer * 5) * 2
                love.graphics.setColor(1, 0, 0, 1)
                self:drawPentagram(cursorX, cursorY, radius, self.timer * 2)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            
             -- Grey out Resolution if in fullscreen
            if i == 2 then
                local _, _, flags = love.window.getMode()
                if flags.fullscreen then
                    love.graphics.setColor(0.5, 0.5, 0.5, 1)
                end
            end
            
            love.graphics.print(item.text, x, y)
        end
    end
end

return OptionsState
