local PauseState = BaseState:extend()

function PauseState:new()
    self.menuItems = {
        { text = "RESUME", action = function() gStateMachine:pop() end },
        { text = "SAVE & QUIT", action = function() 
            -- Note: We need a reference to PlayState to save
            -- In our current stack machine, PlayState is stack[#stack-1]
            local playState = gStateMachine.stack[#gStateMachine.stack - 1]
            if playState and playState.save then
                if playState.castleHealth <= 0 then
                    SaveManager.delete() -- No continuing after death
                    gStateMachine:change('gameover')
                else
                    playState:save()
                    gStateMachine:change('menu') 
                end
            else
                gStateMachine:change('menu') -- If no playState or save function, just go to menu
            end
        end },
        { text = "OPTIONS", action = function() gStateMachine:push('options') end },
        { text = "EXIT", action = function() 
            local playState = gStateMachine.stack[#gStateMachine.stack - 1]
            if playState and playState.save then
                playState:save()
            end
            love.event.quit() 
        end }
    }
    
    self.highlightedIndex = 1
    self.timer = 0
end

function PauseState:update(dt)
    local mouseX, mouseY = love.mouse.getPosition()
    local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
    local font = gFonts['medium']
    
    -- Mouse Selection
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
    
    -- Keyboard Input (Unified)
    if InputManager:wasPressed('up') then
        self.highlightedIndex = self.highlightedIndex - 1
        if self.highlightedIndex < 1 then self.highlightedIndex = #self.menuItems end
    elseif InputManager:wasPressed('down') then
        self.highlightedIndex = self.highlightedIndex + 1
        if self.highlightedIndex > #self.menuItems then self.highlightedIndex = 1 end
    elseif InputManager:wasPressed('confirm') then
        self.menuItems[self.highlightedIndex].action()
    elseif InputManager:wasPressed('back') then
        gStateMachine:pop()
    end
    
    self.timer = self.timer + dt
end

-- Removed keypressed, using InputManager in update instead

function PauseState:render()
    -- Dim the background (game is still rendering underneath)
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)
end

function PauseState:renderUI()
    local winW = love.graphics.getWidth()
    
    love.graphics.setFont(gFonts['large'])
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("PAUSED", 0, 40, winW, 'center')
    
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
        
        love.graphics.print(item.text, x, y)
    end
end

return PauseState
