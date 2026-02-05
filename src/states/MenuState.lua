local MenuState = BaseState:extend()

function MenuState:new()
    self.menuItems = {}
    
    if SaveManager.exists() then
        table.insert(self.menuItems, { 
            text = "CONTINUE GAME", 
            action = function() 
                local data = SaveManager.load()
                gStateMachine:change('play', { saveData = data })
            end 
        })
    end

    table.insert(self.menuItems, { text = "START GAME", action = function() 
        SaveManager.delete() -- Start fresh
        gStateMachine:change('play') 
    end })
    
    -- Update Client Option
    local updateText = "UPDATE CLIENT"
    if gUpdateAvailable then
        updateText = "UPDATE CLIENT (+)"
    end
    
    table.insert(self.menuItems, { text = updateText, action = function() gStateMachine:change('update') end })
    
    table.insert(self.menuItems, { text = "OPTIONS", action = function() gStateMachine:push('options') end })
    table.insert(self.menuItems, { text = "EXIT", action = function() love.event.quit() end })
    
    self.highlightedIndex = 1
    self.timer = 0
    
    self.background = love.graphics.newImage('imgs/menu.png')
end

function MenuState:update(dt)
    local mouseX, mouseY = love.mouse.getPosition()
    local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
    local font = gFonts['medium']
    
    -- Mouse Selection
    for i, item in ipairs(self.menuItems) do
        local x = 60 -- Left padding
        local y = winH - 180 + (i-1) * 40 -- Bottom-ish
        local textW = font:getWidth(item.text)
        local textH = font:getHeight()
        
        if mouseX >= x and mouseX <= x + textW + 40 and
           mouseY >= y and mouseY <= y + textH then
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

function MenuState:keypressed(key)
    if key == 'up' or key == 'w' then
        self.highlightedIndex = self.highlightedIndex - 1
        if self.highlightedIndex < 1 then self.highlightedIndex = #self.menuItems end
    elseif key == 'down' or key == 's' then
        self.highlightedIndex = self.highlightedIndex + 1
        if self.highlightedIndex > #self.menuItems then self.highlightedIndex = 1 end
    elseif key == 'return' or key == 'kpenter' or key == 'space' then
        self.menuItems[self.highlightedIndex].action()
    end
end

function MenuState:renderUI()
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    
    local winH = love.graphics.getHeight()
    
    -- Background
    local startX = 0
    local startY = 0
    local bgW = self.background:getWidth()
    local bgH = self.background:getHeight()
    
    -- Scale to fit
    local scaleX = winW / bgW
    local scaleY = winH / bgH
    local scale = math.max(scaleX, scaleY) -- Cover mode
    
    -- Center crop if needed
    local finalW = bgW * scale
    local finalH = bgH * scale
    local offX = (winW - finalW) / 2
    local offY = (winH - finalH) / 2
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.background, offX, 0, 0, scale, scale)
    
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Menu Items (Bottom Left)
    love.graphics.setFont(gFonts['medium'])
    for i, item in ipairs(self.menuItems) do
        local x = 60
        local y = winH - 200 + (i-1) * 40
        
        if i == self.highlightedIndex then
            love.graphics.setColor(1, 1, 0, 1) -- Highlight
            -- Pentagram Cursor on the RIGHT
            local textW = gFonts['medium']:getWidth(item.text)
            local cursorX = x + textW + 35
            local cursorY = y + 10
            local radius = 10 + math.sin(self.timer * 5) * 2 -- Pulsating size
            love.graphics.setColor(1, 0, 0, 1) -- Red for the pentagram
            self:drawPentagram(cursorX, cursorY, radius, self.timer * 2)
        else
            love.graphics.setColor(1, 1, 1, 0.8)
        end
        
        love.graphics.print(item.text, x, y)
    end
    

    
    love.graphics.setColor(1, 1, 1, 1)
end

return MenuState
