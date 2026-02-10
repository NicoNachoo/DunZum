require 'src/Dependencies'

function love.load()
    -- Initialize virtual resolution
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- love.math.random is automatically seeded by LÖVE on startup

    -- Load Music
    MusicManager:addTrack('main_theme', 'music/Breakout_01.mp3')
    MusicManager:addTrack('menu_theme', 'music/Title_Screen_v0.mp3')
    
    
    -- Initialize Fonts
    local fontName = 'fonts/PressStart2P-Regular.ttf'

    local function loadFont(path, size)
        local rasterizer = love.font.newRasterizer(path, size, 'normal')
        local font = love.graphics.newFont(rasterizer)
        font:setFilter('nearest', 'nearest')
        return font
    end

    local tinyFont = loadFont(fontName, 6)
    local smallFont = loadFont(fontName, 8)
    local mediumSmallFont = loadFont(fontName, 12)
    local mediumFont = loadFont(fontName, 16)
    local xlargeFont = loadFont(fontName, 24)
    local largeFont = loadFont(fontName, 32)
    local hugeFont = loadFont(fontName, 48)
    
    gFonts = {
        ['tiny'] = tinyFont,
        ['small'] = smallFont,
        ['medium_small'] = mediumSmallFont,
        ['medium'] = mediumFont,
        ['xlarge'] = xlargeFont, -- 24px
        ['large'] = largeFont,   -- 32px
        ['huge'] = hugeFont      -- 48px
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
        ['gameover'] = function() return GameOverState() end,
        ['tutorial'] = function() return TutorialState() end
    }
    gStateMachine:change('menu')

    -- Initialize input table
    love.keyboard.keysPressed = {}
    love.mouse.keysPressed = {}

    -- Global Update System
    gUpdateAvailable = false
    gUpdateFiles = nil
    gUpdateThread = love.thread.newThread("src/downloader_thread.lua")
    gUpdateThread:start()
    
    -- Load Hero Sprites
    gHeroSpriteManager:load()
    
    -- Start background check
    local commandChannel = love.thread.getChannel('update_commands')
    commandChannel:push({
        command = 'check_update',
        url = UPDATE_URL,
        currentVersion = GAME_VERSION
    })
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
    
    -- Poll Update Thread (Background Check)
    local statusChannel = love.thread.getChannel('update_status')
    local msg = statusChannel:pop()
    if msg then
        if msg.type == 'update_available' then
            gUpdateAvailable = true
            gUpdateFiles = msg.data.files
            print("Update Available: " .. msg.data.version)
        end
    end
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
    love.graphics.printOutline('FPS: ' .. tostring(love.timer.getFPS()), 4, 4)
    love.graphics.setColor(1, 1, 1, 1)
end
