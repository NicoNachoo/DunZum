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
    
    for i, item in ipairs(self.menuItems) do
        local textW = font:getWidth(item.text)
        local textH = font:getHeight()
        local x = (winW - textW) / 2
        local y = 100 + (i-1) * 60
        
        if mouseX >= x - 20 and mouseX <= x + textW + 20 and
           mouseY >= y - 10 and mouseY <= y + textH + 10 then
            if self.highlightedIndex ~= i then
                self.highlightedIndex = i
            end
            if love.mouse.wasPressed(1) then
                item.action()
            end
        end
    end
    
    self.timer = self.timer + dt
end

function OptionsState:keypressed(key)
    if key == 'up' or key == 'w' then
        self.highlightedIndex = self.highlightedIndex - 1
        if self.highlightedIndex < 1 then self.highlightedIndex = #self.menuItems end
    elseif key == 'down' or key == 's' then
        self.highlightedIndex = self.highlightedIndex + 1
        if self.highlightedIndex > #self.menuItems then self.highlightedIndex = 1 end
    elseif key == 'return' or key == 'kpenter' or key == 'space' then
        self.menuItems[self.highlightedIndex].action()
    elseif key == 'escape' then
        gStateMachine:pop()
    end
end

function OptionsState:renderUI()
    local winW = love.graphics.getWidth()
    
    love.graphics.setFont(gFonts['large'])
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("OPTIONS", 0, 40, winW, 'center')
    
    love.graphics.setFont(gFonts['medium'])
    for i, item in ipairs(self.menuItems) do
        local textW = gFonts['medium']:getWidth(item.text)
        local textH = gFonts['medium']:getHeight()
        
        local x = (winW - textW) / 2
        local y = 100 + (i-1) * 60
        
        if i == self.highlightedIndex then
            love.graphics.setColor(1, 1, 0, 1)
            -- Pentagram Cursor on the right
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

return OptionsState
