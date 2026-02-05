require 'src/Dependencies'

function love.load()
    -- Initialize virtual resolution
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- love.math.random is automatically seeded by LÖVE on startup
    
    -- Initialize Fonts
    local smallFont = love.graphics.newFont('fonts/pixel.ttf', 8)
    smallFont:setFilter('nearest', 'nearest')
    
    local tinyFont = love.graphics.newFont('fonts/pixel.ttf', 6)
    tinyFont:setFilter('nearest', 'nearest')
    
    local mediumFont = love.graphics.newFont('fonts/pixel.ttf', 16)
    mediumFont:setFilter('nearest', 'nearest')
    
    local mediumSmallFont = love.graphics.newFont('fonts/pixel.ttf', 12)
    mediumSmallFont:setFilter('nearest', 'nearest')
    
    local largeFont = love.graphics.newFont('fonts/pixel.ttf', 32)
    largeFont:setFilter('nearest', 'nearest')
    
    gFonts = {
        ['tiny'] = tinyFont,
        ['small'] = smallFont,
        ['medium_small'] = mediumSmallFont,
        ['medium'] = mediumFont,
        ['large'] = largeFont
    }
    love.graphics.setFont(gFonts['small'])
    
    -- Initialize state machine
    gStateMachine = StateMachine {
        ['update'] = function() return UpdateState() end,
        ['menu'] = function() return MenuState() end,
        ['play'] = function() return PlayState() end,
        ['upgrade'] = function() return UpgradeState() end,
        ['options'] = function() return OptionsState() end,
        ['pause'] = function() return PauseState() end,
        ['gameover'] = function() return GameOverState() end
    }
    gStateMachine:change('update')

    -- Initialize input table
    love.keyboard.keysPressed = {}
    love.mouse.keysPressed = {}
end

function love.resize(w, h)
end

function love.textinput(t)
    gStateMachine:textinput(t)
end

function love.keypressed(key)
    love.keyboard.keysPressed[key] = true
    gStateMachine:keypressed(key)
end

function love.mousepressed(x, y, button)
    love.mouse.keysPressed[button] = true
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

function love.mouse.wasPressed(button)
    return love.mouse.keysPressed[button]
end

function love.update(dt)
    gStateMachine:update(dt)
    
    love.keyboard.keysPressed = {}
    love.mouse.keysPressed = {}
end

function love.draw()
    -- Begin virtual resolution
    love.graphics.push()
    
    -- Scale specifically for simple pixel art look if desired, or just fit window
    local scaleX = love.graphics.getWidth() / VIRTUAL_WIDTH
    local scaleY = love.graphics.getHeight() / VIRTUAL_HEIGHT
    
    -- Simple aspect ratio maintenance could suffice, but for now just stretch to fill window as basic scaffold
    love.graphics.scale(scaleX, scaleY)
    
    -- Clear background
    love.graphics.clear(40/255, 45/255, 52/255, 1)
    
    gStateMachine:render()
    
    love.graphics.pop()
    
    gStateMachine:renderUI()
    
    -- Draw FPS
    displayFPS()
end

function displayFPS()
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setFont(love.graphics.newFont(8))
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 4, 4)
    love.graphics.setColor(1, 1, 1, 1)
end
