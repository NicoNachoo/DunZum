local GameOverState = BaseState:extend()

function GameOverState:enter()
    -- We could pass score/reason here
end

function GameOverState:update(dt)
    if love.keyboard.wasPressed('return') then
        gStateMachine:change('play')
    elseif love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function GameOverState:render()
    love.graphics.clear(0, 0, 0, 1) -- Black background
end

function GameOverState:renderUI()
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    
    love.graphics.setFont(gFonts['large'])
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.printfOutline(
        'GAME OVER', 
        0, 
        winH / 2 - 60, 
        winW, 
        'center'
    )
    
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printfOutline(
        'Press Enter to Restart', 
        0, 
        winH / 2 + 20, 
        winW, 
        'center'
    )
end

return GameOverState
