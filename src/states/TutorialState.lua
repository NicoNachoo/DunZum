
local TutorialState = PlayState:extend()

local function drawModal(text, y, width, height)
    local padding = 10
    local font = love.graphics.getFont()
    local textWidth = width - padding * 2
    local _, wrappedLines = font:getWrap(text, textWidth)
    local textHeight = #wrappedLines * font:getHeight()
    
    -- Auto-adjust height if not provided or too small
    height = height or (textHeight + padding * 2)
    height = math.max(height, textHeight + padding * 2)
    
    local x = (VIRTUAL_WIDTH - width) / 2
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle('fill', x, y, width, height, 5)
    
    -- Border
    love.graphics.setColor(1, 0.8, 0, 1) -- Gold
    love.graphics.setLineWidth(2)
    love.graphics.rectangle('line', x, y, width, height, 5)
    love.graphics.setLineWidth(1)
    
    -- Text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(text, x + padding, y + (height - textHeight) / 2, textWidth, 'center')
end

function TutorialState:enter(params)
    -- Call PlayState enter to setup basic game state (mana, castle, etc.)
    PlayState.enter(self, params)
    
    -- Override default game values for tutorial
    self.waveState = 'TUTORIAL' -- Disable wave logic
    self.mana = 20
    self.maxMana = 100
    self.manaRegen = 0 -- Disable natural regen initially? Or keep it low.
    self.castleHealth = 3
    
    -- Tutorial Flow State
    self.step = 1
    -- Steps:
    -- 1: Movement (W/S)
    -- 2: Typing (Meditate)
    -- 3: Mana Explanation
    -- 4: Enemy/Damage Explanation
    -- 5: Finish
    
    self.movementProgress = {w = false, s = false}
    
    self.messages = {
        [2] = "Type 'MEDITATE' to channel mana.",
        [3] = "Mana regenerates quickly while channeling.",
        [4] = "Enemies will try to reach your castle.",
        [5] = "Good luck, Dark Lord."
    }
    
    -- Custom tutorial flags
    self.enemySpawned = false
    self.highlightMana = false
    self.blockInput = false
    
    self.arrowY = 0
    
    self.disableInput = true 
end

function TutorialState:update(dt)
    -- Base PlayState update (particles, units, etc.)
    -- We need to check if we should call super update or custom.
    -- PlayState:update handles input for lane selection, which we want.
    
    -- Specific Step Logic
    if self.step == 1 then
        -- Movement
        if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
            self.movementProgress.w = true
        end
        if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
            self.movementProgress.s = true
        end
        
        -- Flash/Highlight W/S logic handled in render
        if self.movementProgress.w and self.movementProgress.s then
             -- Delay slightly before next step?
            self.step = 2
            self.isTyping = true -- Force typing mode
            self.inputBuffer = ""
        else
             -- Allow lane movement (Manual since disableInput is true)
            if InputManager:wasPressed('up') then
                self.highlightedLane = math.max(1, self.highlightedLane - 1)
            elseif InputManager:wasPressed('down') then
                self.highlightedLane = math.min(NUM_LANES, self.highlightedLane + 1)
            end
             
             -- Update simulation
             PlayState.update(self, dt)
        end
        
    elseif self.step == 2 then
        -- Typing "MEDITATE"
        -- PlayState update handles text input if self.isTyping is true
        -- But we need to intercept confirmation
        
        -- We manually handle input buffer in textinput, checking here
        -- If they press enter, we validate
        
        -- Block normal PlayState update to prevent spawning/other inputs
        -- But we need particle updates
        self.hud:update(dt)
        gParticleManager:update(dt)
        
        -- Custom Input Handling for this step
        if InputManager:wasPressed('confirm') then
            if self.inputBuffer == 'MEDITATE' then
                self:breakChanneling() -- Start mechanic? No, summon triggers channeling.
                -- Actually MEDITATE spell triggers channeling.
                -- We want them to successfully cast it.
                
                -- Simulate casting Meditate
                self.isChanneling = true
                self.isTyping = false
                self.inputBuffer = ""
                self.step = 3
                self.highlightMana = true
                self.timer = 0
            else
                -- Feedback: Only MEDITATE
                -- Maybe shake effect on text?
                self.wrongInputTimer = 0.5
            end
        end
        
        if InputManager:wasPressed('backspace') then
             self.inputBuffer = string.sub(self.inputBuffer, 1, -2)
        end
        
        -- Prevent leaving typing mode
        if not self.isTyping then self.isTyping = true end

    elseif self.step == 3 then
        -- Mana Explanation
        -- Auto-regenerate mana visually?
        PlayState.update(self, dt) -- Allow channeling logic (mana regen)
        
        -- Wait for user to read/mana to fill?
        -- Or just wait for a key press to continue?
        if InputManager:wasPressed('confirm') or love.keyboard.wasPressed('space') or love.mouse.wasPressed(1) then
            self.step = 4
            self.highlightMana = false
            self.isChanneling = false -- Stop channeling
            
             -- Spawn simplified enemy
            self:spawnTutorialEnemy()
        end
        
    elseif self.step == 4 then
        -- Enemy Logic
        -- We want the enemy to move towards castle
        -- We want to pause/slow down when it gets close?
        -- Or just let it hit?
        -- "then move it to almost the left side so you can explain that when the Heroes reach the end your castle take 1 heart of damage"
        
        -- Let's run full update so unit moves
        PlayState.update(self, dt)
        
        local enemy = self.activeUnits[1]
        if enemy then
            -- If enemy is close to castle (left side)
            if enemy.x < 100 and not self.frozenEnemy then
                -- Freeze everything to explain damage
                self.frozenEnemy = true
            end
            
            if self.frozenEnemy then
                 -- Wait for input to finish tutorial
                 if InputManager:wasPressed('confirm') or love.keyboard.wasPressed('space') or love.mouse.wasPressed(1) then
                    self.step = 5
                    enemy.dead = true -- Kill demo unit
                    table.remove(self.activeUnits, 1)
                 end
            end
        else
            -- If enemy died somehow (shouldn't happen), respawn or move on
            if self.frozenEnemy then 
                 self.step = 5
            else
                 self:spawnTutorialEnemy() -- Respawn if they killed it?
            end
        end

    elseif self.step == 5 then
        -- Final Message
        if InputManager:wasPressed('confirm') or love.keyboard.wasPressed('space') or love.mouse.wasPressed(1) then
            -- Tutorial Complete: Start the real game
            -- We should probably save that they saw the tutorial so next time they can skip?
            -- For now, just change to PlayState with fresh data.
            gStateMachine:change('play', { saveData = { tutorialSeen = true } })
        end
        
        -- Particles only
        gParticleManager:update(dt) 
    end
end

function TutorialState:spawnTutorialEnemy()
    -- Spawn a weak Hero at the right side of currently highlighted lane (or middle)
    local lane = self.highlightedLane
    local width, height = 16, 16 
    local y = LANE_OFFSET + (lane - 1) * LANE_HEIGHT + (LANE_HEIGHT - height) / 2
    local x = VIRTUAL_WIDTH - 20
    
    local hero = Hero(x, y, width, height, 'KNIGHT', 1)
    hero.lane = lane
    
    table.insert(self.activeUnits, hero)
end

function TutorialState:textinput(t)
    if self.step == 2 then
        -- Only accept letters
        if t:match("%a") and #self.inputBuffer < 10 then
            self.inputBuffer = self.inputBuffer .. string.upper(t)
        end
    end
end

function TutorialState:render()
    PlayState.render(self)
    
    -- Tutorial Overlays
    local font = gFonts['small']
    love.graphics.setFont(font)
    
    if self.step == 1 then
        -- Render W/S hints next to lanes
        -- Left of lanes? Lanes start at x=0? 
        -- Lanes go from 0 to Width. 
        -- We can draw ON the lanes on the left side.
        
        local laneY = LANE_OFFSET + (self.highlightedLane - 1) * LANE_HEIGHT
        
        -- W (Up)
        if self.highlightedLane > 1 then
             local wColor = self.movementProgress.w and {0.5, 0.5, 0.5, 1} or {1, 1, 0, 1} -- Dim if pressed
             love.graphics.setColor(unpack(wColor))
             love.graphics.print("W", 10, laneY - LANE_HEIGHT + 15)
        end
        
        -- S (Down)
        if self.highlightedLane < NUM_LANES then
             local sColor = self.movementProgress.s and {0.5, 0.5, 0.5, 1} or {1, 1, 0, 1}
             love.graphics.setColor(unpack(sColor))
             love.graphics.print("S", 10, laneY + LANE_HEIGHT + 15)
        end
        
        
        drawModal("Move Up and Down to select a lane", VIRTUAL_HEIGHT / 4, 300)
        
    elseif self.step == 2 then
        -- Render Input Box (handled by PlayState:renderUI -> HUD usually, but logic is in HUD:render)
        -- PlayState:render calls HUD:render. 
        -- HUD renders input buffer if isTyping is true.
        
        drawModal("Type 'MEDITATE' to channel mana", VIRTUAL_HEIGHT / 3, 300)
        
        if self.wrongInputTimer and self.wrongInputTimer > 0 then
             love.graphics.setColor(1, 0, 0, 1)
             love.graphics.printf("Only input 'MEDITATE'!", 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        end
        
    elseif self.step == 3 then
        -- Highlight Mana Bar
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.circle('line', 40, 40, 40) -- Rough location of mana bar
        love.graphics.print("->", 80, 40)
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.circle('line', 40, 40, 40) -- Rough location of mana bar
        love.graphics.print("->", 80, 40)
        
        drawModal("This is your Mana. It regenerates over time.", 80, 300)
        drawModal("Press ENTER to continue", VIRTUAL_HEIGHT - 60, 300, 40)
        
    elseif self.step == 4 then
        -- Point to Enemy
        local enemy = self.activeUnits[1]
        
        -- Always show warning in Step 4
        drawModal("Enemies will attack your castle! Don't let them reach the left side.", 40, 400)
        
        if enemy then
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.line(enemy.x, enemy.y - 10, enemy.x + 10, enemy.y - 20)
            love.graphics.print("Enemy", enemy.x, enemy.y - 30)
            
            if self.frozenEnemy then
                 drawModal("If they reach the left side...\nYour Castle takes damage!", VIRTUAL_HEIGHT/2 - 20, 350)
                 drawModal("Press ENTER to finish", VIRTUAL_HEIGHT - 60, 300, 40)
            end
        end
        
    elseif self.step == 5 then
         drawModal("Be Careful!", VIRTUAL_HEIGHT/2 - 20, 200)
         drawModal("Press ENTER to return to menu", VIRTUAL_HEIGHT - 60, 300, 40)
    end
end

function TutorialState:renderUI()
    -- Call base HUD render
    PlayState.renderUI(self)
end

return TutorialState
