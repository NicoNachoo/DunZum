local PlayState = BaseState:extend()

function PlayState:enter(params)
    self.inputBuffer = ""
    
    self.background = love.graphics.newImage('imgs/background.png')
    
    -- Play Main Theme
    MusicManager:play('main_theme')
    
    local data = params and params.saveData
    
    self.mana = data and data.mana or 20
    self.maxMana = data and data.maxMana or 100
    self.manaRegen = data and data.manaRegen or 5
    
    self.activeUnits = {}
    if data and data.units then
        for _, uData in ipairs(data.units) do
            local unit
            if uData.isHero then
                unit = Hero(uData.x, uData.y, uData.width, uData.height, uData.classType, uData.level)
                unit.enchanted = uData.enchanted
                if unit.enchanted then 
                    unit:enchant() 
                end
            elseif uData.type == 'demon' then
                unit = Demon(uData.x, uData.y, uData.width, uData.height, uData.color, uData.speed, uData.attackRange, uData.originalCost)
                unit.demonType = uData.demonType
                unit.currentShield = uData.currentShield
                unit.isEnraged = uData.isEnraged
                
                if unit.isEnraged then
                    unit.damage = unit.damage * 1.5
                    unit.attackRate = unit.attackRate * 0.5
                end
            else
                unit = Hero(uData.x, uData.y, uData.width, uData.height, uData.classType, uData.level)
            end
            unit.hp = uData.hp
            unit.lane = uData.lane
            unit.state = uData.state
            table.insert(self.activeUnits, unit)
        end
    end

    self.projectiles = {}
    
    -- Lane Logic
    self.highlightedLane = 3 
    
    -- Input Mode
    self.isTyping = false
    
    -- Enemy Spawning / Wave System
    self.wave = data and data.wave or 1
    self.enemiesSpawned = data and data.enemiesSpawned or 0
    self.enemiesToSpawn = data and data.enemiesToSpawn or 10
    self.spawnRate = data and data.spawnRate or 4
    self.spawnTimer = data and data.spawnTimer or 0
    self.waveState = data and data.waveState or 'SPAWNING'
    
    -- Castle Stats
    self.castleHealth = data and data.castleHealth or 3
    self.castleSignal = false 
    self.castleSignalTimer = 0
    
    self.highlightedLane = 1
    self.floatingNumbers = {}
    
    -- Currency
    self.souls = data and data.souls or 0
    
    -- Particles
    gParticleManager = ParticleManager()
    
    -- Screen Shake
    self.shakeDuration = 0
    self.shakeMagnitude = 0
    
    -- UI State
    self.showGrimoire = false
    self.grimoireY = love.graphics.getHeight()
    self.bookImage = love.graphics.newImage('imgs/book.png')
    self.upgradeIcon = love.graphics.newImage('imgs/pentagram-upgrade.png')
    self.grimoireTargetY = love.graphics.getHeight()
    
    self.manaAnimIntensity = 0 -- For smooth animation ease-out
    
    self.grimoirePage = 1
    self.grimoireSpells = {'IMP', 'VOIDWALKER', 'SUCCUBUS', 'MEDITATE', 'MANA', 'REGEN', 'HEAL', 'UPGRADES_LOG'}
    self.grimoireAnimTimer = 0
    self.grimoireFloatTimer = 0
    self.grimoireAnimFrame = 1
    self.boonScrollOffset = 0 -- Scroll position for boons page
    
    -- Selected Upgrades Tracking
    self.selectedUpgrades = data and data.selectedUpgrades or {}
    
    -- Channeling State
    self.isChanneling = false
    
    -- Upgradeable Stats (Roguelike Progression)
    self.demonHpMult = data and data.demonHpMult or 1.0
    self.demonDamageMult = data and data.demonDamageMult or 1.0
    self.manaRefundRate = data and data.manaRefundRate or 0.5
    self.manaCostReduction = data and data.manaCostReduction or 0
    self.impRangeBonus = data and data.impRangeBonus or 0
    self.voidwalkerArmor = data and data.voidwalkerArmor or 0.5 -- Damage taken multiplier
    
    -- Purchase Tracking for Progressive Costs
    self.upgradeCounts = data and data.upgradeCounts or {}
    
    -- Mouse tracking for selection conflict fix
    self.lastMouseX = 0
    self.lastMouseY = 0
    
    -- Vignette Shader for Meditation
    self.vignetteShader = love.graphics.newShader[[
        extern vec2 screenDims;
        extern float time;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 uv = screen_coords / screenDims;
            vec2 center = vec2(0.5, 0.5);
            float d = distance(uv, center);
            
            // Fluctuate the edge slightly based on time
            float edge = 0.3 + (sin(time * 2.0) * 0.05);
            float vignette = smoothstep(edge, 1.2, d); 
            
            // Fluctuate alpha (intensity) - less aggressive (max 0.4)
            float alpha = 0.3 + (sin(time * 3.0) * 0.1);
            
            return vec4(0.4, 0.8, 1.0, vignette * alpha);
        }
    ]]
    
    self.meditateParticles = {} -- Particles for meditation effect
    self.manaAbsorptionParticles = {} -- Particles for mana absorption effect
    
    self.manaBarImage = love.graphics.newImage('imgs/mana-bar.png')
    
    -- Tutorial State
    self.tutorialSeen = data and data.tutorialSeen or false
    self.showTutorial = not self.tutorialSeen
    self.tutorialStep = 1
    self.tutorialSteps = {
        {
            title = "Welcome, Dark Lord",
            text = "The 'Heroes' are invading your realm. Defend the castle at the left cost at all costs! Use your mana to summon demons and cast spells."
        },
        {
            title = "Summoning Minions",
            text = "Select a lane using W/S or Mouse. Press ENTER and type a name like 'IMP' or 'VOIDWALKER' to spawn them. They will walk and attack automatically."
        },
        {
            title = "Mana & Meditation",
            text = "Your mana is limited. Reach out to the void by typing 'MEDITATE'. You will channel mana much faster, but you cannot summon while doing so."
        },
        {
            title = "The Grimoire",
            text = "Press TAB to open your Grimoire. Here you can see unit stats and purchase permanent Boons (Upgrades) using the Souls of fallen heroes."
        },
        {
            title = "Victory Awaits",
            text = "Survive the waves of heroes. As they grow stronger, so must you. Good luck!"
        }
    }
end

function PlayState:serializeState()
    local units = {}
    for _, u in ipairs(self.activeUnits) do
        local uData = {
            type = u.type,
            x = u.x, y = u.y,
            width = u.width, height = u.height,
            hp = u.hp, maxHp = u.maxHp,
            lane = u.lane,
            state = u.state,
            color = u.color
        }
        uData.isHero = u.isHero
        uData.enchanted = u.enchanted
        uData.originalCost = u.originalCost
        
        if u.isHero then
            uData.classType = u.classType
            uData.level = u.level
        elseif u.type == 'demon' then
            uData.speed = u.speed
            uData.attackRange = u.attackRange
            uData.demonType = u.demonType
            uData.currentShield = u.currentShield
            uData.isEnraged = u.isEnraged
        end
        table.insert(units, uData)
    end

    return {
        mana = self.mana,
        maxMana = self.maxMana,
        manaRegen = self.manaRegen,
        wave = self.wave,
        enemiesSpawned = self.enemiesSpawned,
        enemiesToSpawn = self.enemiesToSpawn,
        spawnRate = self.spawnRate,
        spawnTimer = self.spawnTimer,
        waveState = self.waveState,
        castleHealth = self.castleHealth,
        souls = self.souls,
        units = units,
        
        -- Upgrades (Roguelike Progression)
        demonHpMult = self.demonHpMult,
        demonDamageMult = self.demonDamageMult,
        manaRefundRate = self.manaRefundRate,
        manaCostReduction = self.manaCostReduction,
        impRangeBonus = self.impRangeBonus,
        voidwalkerArmor = self.voidwalkerArmor,
        selectedUpgrades = self.selectedUpgrades,
        upgradeCounts = self.upgradeCounts,
        tutorialSeen = self.tutorialSeen
    }
end

function PlayState:save()
    SaveManager.save(self:serializeState())
end

function PlayState:update(dt)
    -- Tutorial Input Blocking
    if self.showTutorial then
        -- Next Step (Right, Confirm, Click)
        if InputManager:wasPressed('right') or InputManager:wasPressed('confirm') or love.mouse.wasPressed(1) then
            self.tutorialStep = self.tutorialStep + 1
            if self.tutorialStep > #self.tutorialSteps then
                self.showTutorial = false
                self.tutorialSeen = true
                -- Optionally save here or rely on next save
            end
        -- Previous Step (Left)
        elseif InputManager:wasPressed('left') then
            self.tutorialStep = math.max(1, self.tutorialStep - 1)
        end
        
        return -- Block all other updates
    end

    -- Update Mana Animation Intensity
    local targetIntensity = self.isChanneling and 1 or 0
    -- Lerp towards target (Speed 10 = faster stop)
    self.manaAnimIntensity = self.manaAnimIntensity + (targetIntensity - self.manaAnimIntensity) * dt * 10
    
    -- Global Input (Pause)
    if InputManager:wasPressed('back') then
        if self.showGrimoire then
            self.showGrimoire = false
        elseif self.isTyping then
            self.isTyping = false
            self.inputBuffer = ""
        else
            gStateMachine:push('pause')
        end
    end
    
    -- Grimoire Toggle (Tab)
    if love.keyboard.wasPressed('tab') then
        self.showGrimoire = not self.showGrimoire
        if self.showGrimoire then
            self.grimoirePage = 1 -- Reset to first page
        end
        self:breakChanneling()
    end

    -- Grimoire Navigation
    if self.showGrimoire then
        if InputManager:wasPressed('left') then
            self.grimoirePage = math.max(1, self.grimoirePage - 1)
            self.boonScrollOffset = 0
        elseif InputManager:wasPressed('right') then
            self.grimoirePage = math.min(#self.grimoireSpells, self.grimoirePage + 1)
            self.boonScrollOffset = 0
        end
        
        -- Scroll on boons page
        local spellKey = self.grimoireSpells[self.grimoirePage]
        if spellKey == 'UPGRADES_LOG' then
            local numBoons = #self.selectedUpgrades
            local maxVisibleBoons = 5
            local maxScroll = math.max(0, numBoons - maxVisibleBoons)
            
            if InputManager:wasPressed('up') then
                self.boonScrollOffset = math.max(0, self.boonScrollOffset - 1)
            elseif InputManager:wasPressed('down') then
                self.boonScrollOffset = math.min(maxScroll, self.boonScrollOffset + 1)
            end
        end
        
        -- While Grimoire is open, block other updates? 
        -- Original code returned here if showGrimoire was true inside update...
        -- Wait, update() handles animations even when grimoire is opening. 
        -- But logic paused.
    end
    
    -- Toggle Grimoire handled in keypressed
    
    -- Update Grimoire Animation
    local winH = love.graphics.getHeight()
    local bookScale = 1.1 -- Must match renderUI
    local bookH = winH * bookScale
    
    if self.showGrimoire then
        self.grimoireTargetY = (winH - bookH) / 2 -- Centered vertically
    else
        self.grimoireTargetY = winH + 10 -- Off-screen
    end
    
    -- Smooth slide (Lerp-like)
    self.grimoireY = self.grimoireY + (self.grimoireTargetY - self.grimoireY) * 10 * dt

    if self.showGrimoire and math.abs(self.grimoireY - self.grimoireTargetY) < 1 then
        -- Update Grimoire Animation
        self.grimoireAnimTimer = self.grimoireAnimTimer + dt
        self.grimoireFloatTimer = self.grimoireFloatTimer + dt
        if self.grimoireAnimTimer >= 0.15 then
            self.grimoireAnimTimer = 0
            self.grimoireAnimFrame = (self.grimoireAnimFrame % 4) + 1
        end
        return -- Pause game logic while open
    end
    
    -- Tutorial Logic
    if self.showTutorial then
        if love.keyboard.wasPressed('space') or love.keyboard.wasPressed('return') or love.mouse.wasPressed(1) then
            self.tutorialStep = self.tutorialStep + 1
            if self.tutorialStep > #self.tutorialSteps then
                self.showTutorial = false
                self.tutorialSeen = true
                self:save() -- Persist that they've seen it
            end
        end
        return -- Pause game logic during tutorial
    end
    
    -- Update Particles
    gParticleManager:update(dt)
    
    -- Meditation Particles
    if self.isChanneling then
        -- Spawn random particles
        local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
        if math.random() < (10 * dt) then -- density
            table.insert(self.meditateParticles, {
                x = math.random(0, winW),
                y = winH + 10,
                vx = (math.random() - 0.5) * 50, -- slight drift
                vy = -math.random(50, 150), -- rising
                life = math.random(1, 3),
                maxLife = 3,
                size = math.random(2, 5)
            })
        end
    end
    
    -- Update Meditation Particles
    for i = #self.meditateParticles, 1, -1 do
        local p = self.meditateParticles[i]
        p.life = p.life - dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        
        if p.life <= 0 or p.y < -10 then
            table.remove(self.meditateParticles, i)
        end
    end
    
    -- Update Mana Absorption Particles
    -- Calculate dynamic target position (same logic as renderUI)
    local winW = love.graphics.getWidth()
    local time = love.timer.getTime()
    local resolutionScale = winW / 1280
    
    local baseImgX, baseImgY = 20, 20
    local floatOffset = math.sin(time * 1.5) * 5
    local swayOffset = (love.math.noise(time * 0.5) - 0.5) * 20
    
    local imgX = math.floor(baseImgX + swayOffset)
    local imgY = math.floor(baseImgY + floatOffset)
    
    -- Target center of the bar
    local barX = math.floor(imgX + (200 * resolutionScale))
    local barY = math.floor(imgY + (65 * resolutionScale))
    local barW = math.floor(math.max(1, 190 * resolutionScale))
    local barH = math.floor(math.max(1, 20 * resolutionScale))
    
    local targetX = barX + barW / 2
    local targetY = barY + barH / 2 
    for i = #self.manaAbsorptionParticles, 1, -1 do
        local p = self.manaAbsorptionParticles[i]
        p.timer = p.timer + dt
        
        -- Physics
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        
        if p.state == 'explode' then
             -- Initial burst phase
             p.vx = p.vx * 0.9 -- Slow down
             p.vy = p.vy * 0.9
             
             if p.timer > 0.15 then
                 p.state = 'seek'
             end
        elseif p.state == 'seek' then
             -- Seek logic
             local dx = targetX - p.x
             local dy = targetY - p.y
             local dist = math.sqrt(dx*dx + dy*dy)
            
             if dist < 20 then
                 -- Reached target!
                 self.mana = math.min(self.mana + (p.value or 0), self.maxMana) -- Delayed refund
                 table.remove(self.manaAbsorptionParticles, i)
             else
                 local nx, ny = dx/dist, dy/dist
                 
                 -- Nonlinear steering
                 local wander = 500
                 local noiseTime = love.timer.getTime() + p.noiseOffset
                 local wx = math.sin(noiseTime * 5) * wander
                 local wy = math.cos(noiseTime * 3) * wander
                 
                 local seekSpeed = 7000 + (p.timer * 10000) -- Accelerate over time
                 if dist < 100 then seekSpeed = seekSpeed + 5000 end -- Hard pull when close
                 
                 p.vx = p.vx + (nx * seekSpeed + wx) * dt
                 p.vy = p.vy + (ny * seekSpeed + wy) * dt
                 
                 -- Heavy damping to prevent orbiting, but less aggressive than before
                 p.vx = p.vx * 0.92
                 p.vy = p.vy * 0.92
             end
        end
        
        if p.timer > 8.0 then -- Long failsafe removal
            table.remove(self.manaAbsorptionParticles, i)
        end
    end
    
    -- Update Shake
    if self.shakeDuration > 0 then
        self.shakeDuration = self.shakeDuration - dt
        if self.shakeDuration <= 0 then
            self.shakeDuration = 0
            self.shakeMagnitude = 0
        end
    end

    -- Mouse Selection Logic
    if not self.showGrimoire and not self.isTyping then
        local mouseX, mouseY = love.mouse.getPosition()
        local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
        
        -- Only update selection if mouse moved
        local mouseMoved = (mouseX ~= self.lastMouseX or mouseY ~= self.lastMouseY)
        
        if mouseMoved then
            -- Map to virtual coordinates
            local virtualX = mouseX / (winW / VIRTUAL_WIDTH)
            local virtualY = mouseY / (winH / VIRTUAL_HEIGHT)
            
            -- Determine Lane
            if virtualY >= LANE_OFFSET and virtualY < LANE_OFFSET + NUM_LANES * LANE_HEIGHT then
                local lane = math.floor((virtualY - LANE_OFFSET) / LANE_HEIGHT) + 1
                if lane >= 1 and lane <= NUM_LANES then
                    self.highlightedLane = lane
                end
            end
        end

        -- Click to Type
        if love.mouse.wasPressed(1) then
            self.isTyping = true
            self.inputBuffer = ""
            self:breakChanneling()
        end

        self.lastMouseX = mouseX
        self.lastMouseY = mouseY
    end
    
    -- Mana Regen (Only while channeling)
    if self.isChanneling then
        self.mana = math.min(self.mana + self.manaRegen * dt, self.maxMana)
    end
    
    -- Castle Signal Decay
    if self.castleSignal then
        self.castleSignalTimer = self.castleSignalTimer + dt
        if self.castleSignalTimer > 0.1 then
            self.castleSignal = false
            self.castleSignalTimer = 0
        end
    end
    
    -- Update Float numbers
    for i = #self.floatingNumbers, 1, -1 do
        local fn = self.floatingNumbers[i]
        fn:update(dt)
        if fn.dead then
            table.remove(self.floatingNumbers, i)
        end
    end

    -- Update Units
    for k, unit in pairs(self.activeUnits) do
        -- Pass self (PlayState) to unit update so they can spawn projectiles
        unit:update(dt, self)
    end
    
    -- Selection / Typing Logic (Only if not in Grimoire)
    if not self.showGrimoire then
        if self.isTyping then
            if love.keyboard.wasPressed('backspace') then
                self.inputBuffer = string.sub(self.inputBuffer, 1, -2)
            elseif InputManager:wasPressed('confirm') then
                self:trySummon()
            end
        else
            -- Selection Mode
            if InputManager:wasPressed('up') then
                self.highlightedLane = math.max(1, self.highlightedLane - 1)
                self:breakChanneling()
            elseif InputManager:wasPressed('down') then
                self.highlightedLane = math.min(NUM_LANES, self.highlightedLane + 1)
                self:breakChanneling()
            elseif InputManager:wasPressed('confirm') then
                self.isTyping = true
                self.inputBuffer = ""
                self:breakChanneling()
            end
        end
    end

    -- Update Projectiles
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]
        p:update(dt)
        
        if p.dead then
            table.remove(self.projectiles, i)
        else
            -- Check collision
            local hit = false
            for _, unit in pairs(self.activeUnits) do
                -- Check against opposite team
                if p.team == 'demon' and unit.type == 'hero' then
                     -- Collision Check (AABB or Center distance)
                     if unit.x < p.x + p.width and unit.x + unit.width > p.x and
                        unit.y < p.y + p.height and unit.y + unit.height > p.y then
                        
                        unit:takeDamage(p.damage, self, p.source)
                        gParticleManager:spawnFireExplosion(p.x + p.width/2, p.y + p.height/2)
                        hit = true
                        break
                     end
                elseif p.team == 'hero' and unit.type == 'demon' then
                     if unit.x < p.x + p.width and unit.x + unit.width > p.x and
                        unit.y < p.y + p.height and unit.y + unit.height > p.y then
                        
                        unit:takeDamage(p.damage, self, p.source)
                        -- Maybe standard hit effect?
                        gParticleManager:spawnPoof(p.x + p.width/2, p.y + p.height/2) 
                        hit = true
                        break
                     end
                end
            end
            
            if hit then
                p.dead = true
                table.remove(self.projectiles, i)
            elseif p.target and p.target.dead then
                 -- If homing target died, keep flying (linear)
            end
        end
    end
    
    -- Combat Logic
    -- Check for collisions/range between opposing units
    -- This is O(N^2) but N is small (num units)
    for i, unitA in ipairs(self.activeUnits) do
        if unitA.type == 'demon' then
            if unitA.behavior == 'SUPPORT' then
                -- Scans for INJURED ALLIES (Demons/Charmed)
                local bestTarget = nil
                local minHpRatio = 1.0
                
                for j, unitB in ipairs(self.activeUnits) do
                    if unitB.type == 'demon' and unitA.lane == unitB.lane and not unitB.dead and unitB ~= unitA then
                        local dist = math.abs(unitA.x - unitB.x)
                        if dist <= unitA.attackRange then
                            local ratio = unitB.hp / unitB.maxHp
                            if ratio < 1.0 and ratio < minHpRatio then
                                minHpRatio = ratio
                                bestTarget = unitB
                            end
                        end
                    end
                end
                
                -- If no ally to heal, check for Enemies to attack (heroes)
                if not bestTarget then
                    local minDist = 10000
                    for j, unitB in ipairs(self.activeUnits) do
                        if unitB.type == 'hero' and unitA.lane == unitB.lane and not unitB.dead then
                            local dist = unitB.x - (unitA.x + unitA.width)
                            local range = unitA.attackRange
                            if dist <= range and dist >= -10 then
                                local absDist = math.abs(dist)
                                if absDist < minDist then
                                    minDist = absDist
                                    bestTarget = unitB
                                end
                            end
                        end
                    end
                end
                
                if bestTarget then
                    unitA.state = 'ATTACK'
                    unitA.target = bestTarget
                elseif unitA.state == 'ATTACK' and (not unitA.target or unitA.target.dead or unitA.target.type == unitA.type) then
                    unitA.state = 'WALK'
                    unitA.target = nil
                end
            else
                -- Traditional Attacker logic
                local bestTarget = nil
                local minDist = 10000
                
                for j, unitB in ipairs(self.activeUnits) do
                    if unitB.type == 'hero' and unitA.lane == unitB.lane and not unitB.dead then
                        -- Calculate distance (Herox - Demonx)
                        local dist = unitB.x - (unitA.x + unitA.width)
                        
                        -- Check if in range
                        local range = unitA.attackRange
                        if unitA.demonType == 'IMP' then
                            range = range + self.impRangeBonus
                        end
                        local inRange = (dist <= range and dist >= -10)
                        
                        if inRange then
                            local absDist = math.abs(dist)
                            if absDist < minDist then
                                minDist = absDist
                                bestTarget = unitB
                            end
                        end
                    end
                end
                
                if bestTarget then
                    unitA.state = 'ATTACK'
                    unitA.target = bestTarget
                elseif unitA.state == 'ATTACK' and (not unitA.target or unitA.target.dead or unitA.target.type == unitA.type) then
                     -- If we were attacking but target is gone/dead/friendly, resume walking
                     unitA.state = 'WALK'
                     unitA.target = nil
                end
            end
        elseif unitA.type == 'hero' then
             -- Logic depends on behavior
             if unitA.behavior == 'SUPPORT' then
                 -- Scans for INJURED ALLIES (Heroes)
                 local bestTarget = nil
                 local minHpRatio = 1.0
                 
                 for j, unitB in ipairs(self.activeUnits) do
                     if unitB.type == 'hero' and unitA.lane == unitB.lane and not unitB.dead and unitB ~= unitA then
                         local dist = math.abs(unitA.x - unitB.x)
                         if dist <= unitA.attackRange then
                             local ratio = unitB.hp / unitB.maxHp
                             if ratio < 1.0 and ratio < minHpRatio then
                                 minHpRatio = ratio
                                 bestTarget = unitB
                             end
                         end
                     end
                 end
                 
                 -- If no ally to heal, check for Enemies to block/attack
                 if not bestTarget then
                     local minDist = 10000
                     for j, unitB in ipairs(self.activeUnits) do
                        if unitB.type == 'demon' and unitA.lane == unitB.lane and not unitB.dead then
                            local dist = unitA.x - (unitB.x + unitB.width)
                            -- Use smaller range for self-defense if desired, or standard range
                            if dist <= unitA.attackRange and dist >= -10 then
                                if dist < minDist then
                                    minDist = dist
                                    bestTarget = unitB
                                end
                            end
                        end
                     end
                 end
                 
                 if bestTarget then
                     unitA.state = 'ATTACK'
                     unitA.target = bestTarget
                 else
                     unitA.state = 'WALK'
                     unitA.target = nil
                 end
                 
             else
                 -- Normal Combat (Against DEMONS)
                 local bestTarget = nil
                 local minDist = 10000
                
                 for j, unitB in ipairs(self.activeUnits) do
                    if unitB.type == 'demon' and unitA.lane == unitB.lane and not unitB.dead then
                        -- Calculate distance (Herox - Demonx)
                        -- Hero is on right, Demon on left.
                        local dist = unitA.x - (unitB.x + unitB.width)
                        
                        if dist <= unitA.attackRange and dist >= -10 then
                            if dist < minDist then
                                minDist = dist
                                bestTarget = unitB
                            end
                        end
                    end
                 end
                 
                 if bestTarget then
                    unitA.state = 'ATTACK'
                    unitA.target = bestTarget
                 elseif unitA.state == 'ATTACK' and (not unitA.target or unitA.target.dead or unitA.target.type == unitA.type) then
                     unitA.state = 'WALK'
                     unitA.target = nil
                 end
             end
        end
    end
    
    -- Clean up dead units and check for Castle Damage / Summon Cancellation
    for i = #self.activeUnits, 1, -1 do
        local unit = self.activeUnits[i]
        
        -- Portal Effect for Summons near the end
        if unit.type == 'demon' and not unit.dead then
            local approachThreshold = VIRTUAL_WIDTH - 70 -- Shifted 30px left (was 40)
            if unit.x > approachThreshold then
                -- Spawn portal particles
                gParticleManager:spawnPortalEffect(VIRTUAL_WIDTH - 40, unit.y + unit.height/2) -- Shifted 30px left (was 10)
            end
        end

        -- Check if Hero reached left side
        if unit.type == 'hero' and unit.x < -unit.width then
            self.castleHealth = self.castleHealth - 1
            self.castleSignal = true
            
            -- Trigger Shake
            self.shakeDuration = 0.3
            self.shakeMagnitude = 5
            
            if self.castleHealth <= 0 then
                SaveManager.delete()
                gStateMachine:change('gameover')
            end
            
            table.remove(self.activeUnits, i)
        elseif unit.dead then
            -- Reward for killing Hero
            if unit.type == 'hero' then
                self.souls = self.souls + 10
            end
            table.remove(self.activeUnits, i)
        elseif unit.type == 'demon' and unit.x > VIRTUAL_WIDTH - 30 then -- Shifted 30px left
            -- Mana Refund Logic (Delayed via particles)
            local totalRefund = math.floor((unit.originalCost or 0) * self.manaRefundRate)
            -- self.mana updated by particles now
            
            -- Visual Feedback
            gParticleManager:spawnCancelEffect(unit.x, unit.y + unit.height/2)
            
            -- Spawn Mana Absorption Particles (World space -> Screen space simulation)
            local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
            local startX = (unit.x / VIRTUAL_WIDTH) * winW
            local startY = (unit.y / VIRTUAL_HEIGHT) * winH
            
            local numParticles = 15
            local refundPerParticle = totalRefund / numParticles
            
            for k = 1, numParticles do
                table.insert(self.manaAbsorptionParticles, {
                    x = startX,
                    y = startY,
                    vx = (math.random() - 0.5) * 1500, -- Much wider explosion
                    vy = (math.random() - 0.5) * 1500,
                    timer = 0,
                    state = 'explode',
                    noiseOffset = math.random() * 10,
                    value = refundPerParticle -- Carry value
                })
            end
            
            -- Floating number for refund
            table.insert(self.floatingNumbers, FloatingNumber(unit.x - 20, unit.y, "+" .. totalRefund .. " Mana", {0.2, 0.8, 1, 1}))
            
            table.remove(self.activeUnits, i)
        elseif unit.x > VIRTUAL_WIDTH + 50 or unit.x < -50 then
            table.remove(self.activeUnits, i)
        end
    end
    
    -- Wave Logic
    if self.waveState == 'SPAWNING' then
        self.spawnTimer = self.spawnTimer + dt
        if self.spawnTimer > self.spawnRate then
            self.spawnTimer = 0
            self:spawnHero()
            self.enemiesSpawned = self.enemiesSpawned + 1
            
            if self.enemiesSpawned >= self.enemiesToSpawn then
                self.waveState = 'WAITING'
            end
        end
    elseif self.waveState == 'WAITING' then
        -- Check if all heroes are dead
        local heroCount = 0
        for k, unit in pairs(self.activeUnits) do
            if unit.type == 'hero' then
                heroCount = heroCount + 1
            end
        end
        
        if heroCount == 0 then
            -- Wave Clear! 
            gStateMachine:push('upgrade', { playState = self })
        end
    end
end

function PlayState:nextWave()
    self.wave = self.wave + 1
    self.enemiesSpawned = 0
    self.enemiesToSpawn = self.enemiesToSpawn + 2
    self.spawnRate = math.max(0.5, self.spawnRate * 0.9) -- Faster spawns
    self.waveState = 'SPAWNING'
end

function PlayState:spawnHero()
    local lane = love.math.random(1, NUM_LANES)
    local width, height = 16, 16 
    
    local y = LANE_OFFSET + (lane - 1) * LANE_HEIGHT + (LANE_HEIGHT - height) / 2
    local x = VIRTUAL_WIDTH + 10 -- Right side spawn
    
    -- Pick Random Class
    local classes = {'KNIGHT', 'PRIEST', 'ARCHER', 'ASSASSIN', 'MAGE'}
    local classType = classes[love.math.random(#classes)]
    
    local hero = Hero(x, y, width, height, classType, self.wave)
    hero.lane = lane
    
    gParticleManager:spawnPoof(x + width/2, y + height/2) -- Spawn effect
    table.insert(self.activeUnits, hero)
end

function PlayState:textinput(t)
    if self.showGrimoire then return end
    if self.isTyping then
        -- Only accept single-byte (ASCII) characters to prevent UTF-8 mangling
        if #t == 1 then
            self.inputBuffer = self.inputBuffer .. string.upper(t)
        end
    end
end

-- Removed keypressed, using InputManager in update instead

function PlayState:trySummon()
    local spell = Grimoire[self.inputBuffer]
    
    if spell then
        if spell.type == 'summon' then
            local adjustedCost = math.max(0, spell.cost - self.manaCostReduction)
            if self.mana >= adjustedCost then
                self:summon(spell)
                self.mana = self.mana - adjustedCost
                self.inputBuffer = "" 
                self.isTyping = false 
            else
                print("Not enough mana!") 
                self.isTyping = false 
            end
        elseif spell.type == 'upgrade' then
            local currentCost = self:getUpgradeCost(self.inputBuffer)
            
            if self.souls >= currentCost then
                self.souls = self.souls - currentCost
                
                -- Apply Effect
                if spell.effect == 'max_mana' then
                    self.maxMana = self.maxMana + spell.amount
                elseif spell.effect == 'regen' then
                    self.manaRegen = self.manaRegen + spell.amount
                elseif spell.effect == 'heal' then
                    self.castleHealth = math.min(3, self.castleHealth + spell.amount)
                end
                
                -- Increment count for progressive cost
                self.upgradeCounts[self.inputBuffer] = (self.upgradeCounts[self.inputBuffer] or 0) + 1
                
                self.inputBuffer = ""
                self.isTyping = false
            else
                print("Not enough souls! Cost: " .. currentCost)
                self.isTyping = false
            end
        elseif spell.type == 'channel' then
            self.isChanneling = true
            self.inputBuffer = ""
            self.isTyping = false
        end
    else
        print("Unknown spell: " .. self.inputBuffer)
        self.inputBuffer = "" 
        self.isTyping = false 
    end
end

function PlayState:summon(spell)
    -- Calculate X (fixed starting position for demons)
    local x = 20
    -- Calculate Y based on lane center
    local y = LANE_OFFSET + (self.highlightedLane - 1) * LANE_HEIGHT + (LANE_HEIGHT - spell.height) / 2
    
    local demon = Demon(x, y, spell.width, spell.height, spell.color, spell.speed, spell.attackRange, spell.cost, self, self.inputBuffer)
    demon.lane = self.highlightedLane
    -- demon.demonType already set in new()
    
    gParticleManager:spawnPoof(x + spell.width/2, y + spell.height/2)
    table.insert(self.activeUnits, demon)
end

function PlayState:breakChanneling()
    self.isChanneling = false
end

function PlayState:getUpgradeCost(spellName)
    local spell = Grimoire[spellName]
    if not spell or spell.type ~= 'upgrade' then return 0 end
    
    local count = self.upgradeCounts[spellName] or 0
    -- Exponential scaling: base * 1.5 ^ count
    return math.floor(spell.cost * math.pow(1.5, count))
end

function PlayState:render()
    -- Apply Shake
    if self.shakeMagnitude > 0 then
        local dx = love.math.random(-self.shakeMagnitude, self.shakeMagnitude)
        local dy = love.math.random(-self.shakeMagnitude, self.shakeMagnitude)
        love.graphics.translate(dx, dy)
    end

    -- Draw Background
    love.graphics.setColor(1, 1, 1, 1)
    if self.background then
        local bgW = self.background:getWidth()
        local bgH = self.background:getHeight()
        -- Scale to fit virtual screen
        love.graphics.draw(self.background, 0, 0, 0, VIRTUAL_WIDTH / bgW, VIRTUAL_HEIGHT / bgH)
    end

    -- Render Lanes
    for i = 1, NUM_LANES do
        local y = LANE_OFFSET + (i - 1) * LANE_HEIGHT
        
        -- Draw lane divider
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.line(0, y, VIRTUAL_WIDTH, y)
        
        -- Highlight current lane
        if i == self.highlightedLane then
            if self.isTyping then
                love.graphics.setColor(1, 0, 0, 0.2) -- Red highlight when typing
                love.graphics.rectangle('fill', 0, y, VIRTUAL_WIDTH, LANE_HEIGHT)
                love.graphics.setColor(1, 0, 0, 0.5)
                love.graphics.rectangle('line', 0, y, VIRTUAL_WIDTH, LANE_HEIGHT)
            else
                love.graphics.setColor(1, 1, 1, 0.1) -- White highlight when selecting
                love.graphics.rectangle('fill', 0, y, VIRTUAL_WIDTH, LANE_HEIGHT)
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.rectangle('line', 0, y, VIRTUAL_WIDTH, LANE_HEIGHT)
            end
        end
    end
    
    -- Bottom-most divider
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.line(0, LANE_OFFSET + NUM_LANES * LANE_HEIGHT, VIRTUAL_WIDTH, LANE_OFFSET + NUM_LANES * LANE_HEIGHT)
    love.graphics.setColor(1, 1, 1, 1)

    -- Render Units
    for k, unit in pairs(self.activeUnits) do
        unit:render()
    end
    
    -- Render Projectiles
    for k, p in pairs(self.projectiles) do
        p:render()
    end
    
    -- Render Particles
    gParticleManager:render()

    -- Render Floating Numbers
    for _, fn in ipairs(self.floatingNumbers) do
        fn:render()
    end
end

function PlayState:renderUI()
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()



    -- UI: Mana Bar (Centered inside mana-bar.png)
    local baseImgX, baseImgY = 20, 20
    
    -- Animation: Floating (Sine) + Random Sway (Noise)
    -- Animation: Floating (Sine) + Random Sway (Noise)
    local time = love.timer.getTime()
    
    -- Calculate raw offsets
    local rawFloat = math.sin(time * 1.5) * 5 -- Vertical floating
    local rawSway = (love.math.noise(time * 0.5) - 0.5) * 20 -- Slow random horizontal sway
    
    -- Apply smoothed intensity
    local floatOffset = rawFloat * self.manaAnimIntensity
    local swayOffset = rawSway * self.manaAnimIntensity
    
    local imgX = math.floor(baseImgX + swayOffset)
    local imgY = math.floor(baseImgY + floatOffset)

    local imgW = self.manaBarImage:getWidth()
    local imgH = self.manaBarImage:getHeight()
    
    -- Calculate Scale to be 20% of screen width (User change)
    local targetWidth = winW * 0.25
    local scale = targetWidth / imgW
    
    -- Resolution Scale for manual offsets (Base: 1280x720)
    local resolutionScale = winW / 1280

    -- 2. Calculate Bar Dimensions (Centered within the image)
    -- Scaling hardcoded values: 
    -- 190 -> 190 * resolutionScale
    -- 20 -> 20 * resolutionScale
    -- Offset X: 60 (80-20) -> 60 * resolutionScale
    -- Offset Y: 65 (85-20) -> 65 * resolutionScale
    
    local barMaxWidth = math.floor(math.max(1, 190 * resolutionScale))
    local barHeight = math.floor(math.max(1, 20 * resolutionScale))
    
    local barX = math.floor(imgX + (60 * resolutionScale))
    local barY = math.floor(imgY + (65 * resolutionScale))

    -- 3. Draw Filled Portion (Pixel Art Particles)
    local fillWidth = (self.mana / self.maxMana) * barMaxWidth
    local pixelSize = math.max(1, 4 * scale)

    local time = love.timer.getTime()
    
    -- Scissor to ensure we don't draw outside the bar area (optional but safe)
    love.graphics.setScissor(barX, barY, fillWidth, barHeight)
    
    -- Iterate through the bar area in grid steps
    for y = 0, barHeight, pixelSize do
        for x = 0, barMaxWidth, pixelSize do
             -- Only draw if within fillWidth
            if x < fillWidth then
                -- Generate a pseudo-random pulsating shade of blue
                local flowSpeed = 2.0
                local wave = math.sin(time * flowSpeed + x * 0.1) 
                local noise = love.math.noise(x * 0.05, y * 0.05, time * 0.5)
                
                -- Blend: 70% wave, 30% noise
                local combined = (wave * 0.7) + (noise * 0.3)
                
                -- Blue colors
                local r = 0.1
                local g = 0.2 + (combined + 1) * 0.1
                local b = 0.7 + (combined + 1) * 0.15
                local a = 0.8 + noise * 0.2
                
                love.graphics.setColor(r, g, b, a)
                love.graphics.rectangle('fill', barX + x, barY + y, pixelSize, pixelSize)
            end
        end
    end
    love.graphics.setScissor() -- Reset scissor

    -- 4. Draw markers every 100 mana
    love.graphics.setColor(0, 0, 0, 0.5)
    for i = 100, self.maxMana - 1, 100 do
        local markerRatio = i / self.maxMana
        local markerX = barX + markerRatio * barMaxWidth
        if markerX < barX + barMaxWidth then
            love.graphics.line(markerX, barY, markerX, barY + barHeight)
        end
    end
    
    -- 1. Draw the Container/Frame Image first
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.manaBarImage, imgX, imgY, 0, scale, scale)
    
    -- 5. Mana Text (Centered on bar)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(gFonts['medium_small'])
    
    local manaText = math.floor(self.mana) .. '/' .. math.floor(self.maxMana)
    
    -- Center vertically in the bar (Height 20 unscaled, Font 12 unscaled -> 4 offset)
    local textY = barY + (4 * resolutionScale)
    
    -- Limit is 190 (unscaled bar width), centered
    love.graphics.printf(manaText, barX, textY, 190, 'center', 0, resolutionScale, resolutionScale)

    -- Draw Mana Absorption Particles (On Top of HUD)
    love.graphics.setBlendMode('add')
    for _, p in ipairs(self.manaAbsorptionParticles) do
        -- Light Blue Glow
        love.graphics.setColor(0.2, 0.6, 1, 1.0) 
        local size = 6 -- Squared size
        love.graphics.rectangle('fill', p.x - size/2, p.y - size/2, size, size) 
    end
    love.graphics.setBlendMode('alpha')
    love.graphics.setColor(1, 1, 1, 1)
    
    -- UI: Castle Health
    if self.castleSignal then
        love.graphics.setColor(1, 0, 0, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    -- Resolution Scale for manual offsets (Base: 1280x720)
    local resolutionScale = winW / 1280
    local layoutScale = math.max(1, winH / 720)

    -- Helper to pick native font size
    local function getNativeFont(baseSize)
        local target = baseSize * layoutScale
        if target <= 7 then return gFonts['tiny']
        elseif target <= 10 then return gFonts['small']
        elseif target <= 14 then return gFonts['medium_small'] -- 12px base (at 720p)
        elseif target <= 20 then return gFonts['medium']       -- 16px base (at 720p)
        elseif target <= 28 then return gFonts['xlarge']       -- 24px
        elseif target <= 40 then return gFonts['large']        -- 32px
        else return gFonts['huge'] end                         -- 48px
    end
    
    -- UI: Castle Health
    love.graphics.setFont(getNativeFont(16))
    love.graphics.printf(self.castleHealth .. " Hearts", winW - (220 * layoutScale), 20 * layoutScale, 200 * layoutScale, 'right', 0, 1, 1)
    
    -- UI: Souls
    love.graphics.setColor(0.8, 0.4, 1, 1) -- Purple
    love.graphics.printf(self.souls .. " Souls", winW - (220 * layoutScale), 50 * layoutScale, 200 * layoutScale, 'right', 0, 1, 1)
    
    -- UI: Wave
    love.graphics.setColor(1, 1, 0, 1) -- Yellow
    love.graphics.print('Wave: ' .. self.wave, winW / 2 - (50 * layoutScale), 20 * layoutScale, 0, 1, 1)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- UI: Typing Buffer
    if self.isTyping then
        love.graphics.setFont(getNativeFont(16))
        
        local bufferW = 400 * layoutScale
        local bufferH = 60 * layoutScale
        local bufferX = (winW - bufferW) / 2
        local bufferY = winH - (100 * layoutScale)
        
        -- Draw background for text buffer (Chunky pixel look)
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle('fill', bufferX, bufferY, bufferW, bufferH, 10 * layoutScale)
        
        love.graphics.setColor(1, 0.8, 0, 1) -- Gold border
        love.graphics.setLineWidth(2 * layoutScale)
        love.graphics.rectangle('line', bufferX, bufferY, bufferW, bufferH, 10 * layoutScale)
        love.graphics.setLineWidth(1)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(
            self.inputBuffer, 
            bufferX, 
            bufferY + (15 * layoutScale), 
            bufferW, 
            'center'
        )
        
        -- Helper line when typing
        love.graphics.setFont(getNativeFont(10))
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.printf("TYPE UNIT NAME AND ENTER", bufferX, bufferY + bufferH + (5 * layoutScale), bufferW, 'center')
    else
        love.graphics.setFont(getNativeFont(10))
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.printf(
            "W/S: Select Lane | ENTER: Summon | TAB: Grimoire", 
            0, 
            winH - (30 * layoutScale), 
            winW, 
            'center'
        )
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- UI: Grimoire Overlay (Animated Book)

    if self.grimoireY < winH then
        local imgW = self.bookImage:getWidth()
        local imgH = self.bookImage:getHeight()
        
        -- Target size based on Screen Height (110% of screen - Massive close-up)
        local targetH = winH * 1.1
        local scale = targetH / imgH
        
        local bookH = targetH
        local bookW = imgW * scale
        
        local bookX = math.floor((winW - bookW) / 2)
        -- Add floating animation (Sine wave: Speed 2, Amplitude 10)
        local floatOffset = math.sin(self.grimoireFloatTimer * 2) * (10 * layoutScale)
        local bookY = math.floor(self.grimoireY + floatOffset)
        
        -- Draw Book Image
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.bookImage, bookX, bookY, 0, scale, scale)
        
        -- Page Layout Calculations (Relative to book size on screen)
        local marginX = bookW * 0.22 
        local marginY = bookH * 0.30 
        local gutter = bookW * 0.12  
            
        local contentX = math.floor(bookX + marginX)
        local contentY = math.floor(bookY + marginY)
        
        -- Dimensions of a single page print area
        local pageWidth = math.floor((bookW / 2) - marginX - (gutter / 2))
        
        -- Right Page Start X
        local rightPageX = math.floor(bookX + (bookW / 2) + (gutter / 2))
        
        -- Page Content
        local spellKey = self.grimoireSpells[self.grimoirePage]
        local spell = Grimoire[spellKey]
        
        if spellKey == 'UPGRADES_LOG' then
            -- Left Page Title
            love.graphics.setColor(0.2, 0.1, 0, 1) 
            love.graphics.setFont(getNativeFont(16)) -- Base 16px
            love.graphics.printf("Grimoire\nof Boons", contentX, contentY, pageWidth, 'center')
            
            -- Central Illustration (Pentagram Image)
            local centerX = contentX + pageWidth / 2
            local centerY = contentY + (160 * layoutScale) 
            
            love.graphics.setColor(1, 1, 1, 1)
            local targetSize = 150 * layoutScale
            local uScale = targetSize / self.upgradeIcon:getWidth()
            love.graphics.draw(self.upgradeIcon, centerX, centerY, 0, uScale, uScale, self.upgradeIcon:getWidth()/2, self.upgradeIcon:getHeight()/2)
            
            -- Right Page: The List
            local rightPageW = pageWidth
            
            love.graphics.setColor(0.2, 0.1, 0, 1)
            
            if #self.selectedUpgrades == 0 then
                love.graphics.setFont(getNativeFont(10))
                love.graphics.printf("No boons yet claimed...", rightPageX, contentY, rightPageW, 'center')
            else
                local maxVisibleBoons = 4 
                local numBoons = #self.selectedUpgrades
                local maxScroll = math.max(0, numBoons - maxVisibleBoons)
                
                self.boonScrollOffset = math.max(0, math.min(maxScroll, self.boonScrollOffset))
                
                -- Scroll Indicator Top
                if self.boonScrollOffset > 0 then
                    love.graphics.setColor(0.5, 0.3, 0.1, 1)
                    love.graphics.setFont(getNativeFont(10))
                    love.graphics.printf("▲ More above (W to scroll up)", rightPageX, contentY - (20 * layoutScale), rightPageW, 'center')
                end
                
                local yOffset = contentY
                local startIndex = self.boonScrollOffset + 1
                local endIndex = math.min(numBoons, startIndex + maxVisibleBoons - 1)
                
                for i = startIndex, endIndex do
                    local upgrade = self.selectedUpgrades[i]
                    
                    love.graphics.setFont(getNativeFont(10)) -- Base 12px
                    love.graphics.setColor(0.3, 0.1, 0.05, 1)
                    
                    local displayName = upgrade.name
                    if upgrade.count and upgrade.count > 1 then
                        displayName = displayName .. " x" .. upgrade.count
                    end
                    
                    love.graphics.print("- " .. displayName, rightPageX, yOffset + (10 * layoutScale))
                    yOffset = yOffset + (25 * layoutScale) 
                    
                    love.graphics.setFont(getNativeFont(10)) 
                    love.graphics.setColor(0.4, 0.3, 0.2, 1)
                    love.graphics.printf(upgrade.desc, rightPageX + (10 * layoutScale), yOffset + (5 * layoutScale), rightPageW - (10 * layoutScale), 'left')
                    yOffset = yOffset + (55 * layoutScale) 
                end
                
                -- Scroll Indicator Bottom
                if self.boonScrollOffset < maxScroll then
                    love.graphics.setColor(0.5, 0.3, 0.1, 1)
                    love.graphics.setFont(getNativeFont(10))
                    love.graphics.printf("▼ More below (S to scroll down)", rightPageX, yOffset + (10 * layoutScale), rightPageW, 'center')
                end
            end
            
            -- Footer
            love.graphics.setFont(getNativeFont(10))
            love.graphics.setColor(0.4, 0.3, 0.2, 1)
            love.graphics.printf("A/D to flip pages", bookX + marginX, bookY + bookH - marginY - (35 * layoutScale), pageWidth, 'center')
            
        elseif spell then
            -- Left Page: Illustration & Name
            love.graphics.setColor(0.2, 0.1, 0, 1) 
            love.graphics.setFont(getNativeFont(16)) -- Base 16px
            love.graphics.printf(spellKey, contentX, contentY, pageWidth, 'center')
            
            -- Icon
            local iconSize = 80 * scale 
            local iconX = math.floor(contentX + (pageWidth / 2) - (iconSize/2))
            local iconY = math.floor(contentY + (40 * layoutScale))
            
            if spellKey == 'IMP' then
                love.graphics.setColor(1, 1, 1, 1)
                local s = iconSize / 64
                love.graphics.draw(Demon.impSprite, Demon.impQuads[self.grimoireAnimFrame], iconX, iconY, 0, s, s)
            else
                if spell.color then
                    love.graphics.setColor(unpack(spell.color))
                else
                    love.graphics.setColor(1, 1, 1, 1)
                end
                love.graphics.rectangle('fill', iconX, iconY, iconSize, iconSize)
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.rectangle('line', iconX, iconY, iconSize, iconSize)
            end
            
            -- Right Page: Details
            local rightPageW = pageWidth
            
            love.graphics.setColor(0.2, 0.1, 0, 1)
            love.graphics.setFont(getNativeFont(16)) -- Base 16px for Title
            
            local nameText = spell.name
            if spell.type == 'summon' then
                nameText = "Summon " .. nameText
            elseif spell.type == 'upgrade' then
                nameText = "Upgrade " .. nameText
            end
            
            love.graphics.printf(nameText, rightPageX, contentY, rightPageW, 'left')
            
            love.graphics.setFont(getNativeFont(10)) -- Base 12px for Body
            local yOffset = contentY + (60 * layoutScale)
            
            local displayCost = spell.cost
            if spell.type == 'upgrade' then
                displayCost = self:getUpgradeCost(spellKey)
            end

            local costText = "Cost: " .. displayCost
            if spell.type == 'upgrade' then 
                costText = costText .. " Souls" 
            else 
                costText = costText .. " Mana" 
            end
            love.graphics.print(costText, rightPageX, yOffset)
            
            if spell.attackRange then
                love.graphics.print("Range: " .. spell.attackRange, rightPageX, yOffset + (20 * layoutScale))
            end
            
            if spell.speed then
                love.graphics.print("Speed: " .. spell.speed, rightPageX, yOffset + (40 * layoutScale))
            end
            
            -- Description
            if spell.description then
                love.graphics.setColor(0.3, 0.2, 0.1, 1) 
                love.graphics.setFont(getNativeFont(10))
                local descYOffset = yOffset + (70 * layoutScale)
                love.graphics.printf(spell.description, rightPageX, descYOffset, rightPageW, 'left')
            end
            
            -- Footer
            love.graphics.setFont(getNativeFont(10))
            love.graphics.setColor(0.4, 0.3, 0.2, 1)
            love.graphics.printf("A/D to flip pages", bookX + marginX, bookY + bookH - marginY - (35 * layoutScale), pageWidth, 'center')
        end
    end

    -- Channeling Indicator
    if self.isChanneling then
        -- Draw Vignette
        self.vignetteShader:send("screenDims", {winW, winH})
        self.vignetteShader:send("time", love.timer.getTime())
        love.graphics.setShader(self.vignetteShader)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('fill', 0, 0, winW, winH)
        love.graphics.setShader()
        
        -- Draw Particles
        love.graphics.setBlendMode('add')
        for _, p in ipairs(self.meditateParticles) do
            love.graphics.setColor(0.4, 0.8, 1, p.life / p.maxLife)
            love.graphics.rectangle('fill', p.x, p.y, p.size, p.size)
        end
        love.graphics.setBlendMode('alpha')
        
        love.graphics.setColor(1, 1, 1, 1)
        
        -- Removed MEDITATING text per request
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Tutorial Overlay
    if self.showTutorial then
        local step = self.tutorialSteps[self.tutorialStep]
        local overlayW = 500 * layoutScale
        local overlayH = 250 * layoutScale
        local overlayX = (winW - overlayW) / 2
        local overlayY = (winH - overlayH) / 2
        
        -- Dark Background
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle('fill', overlayX, overlayY, overlayW, overlayH, 15)
        
        -- Gold Border
        love.graphics.setColor(1, 0.8, 0, 1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle('line', overlayX, overlayY, overlayW, overlayH, 15)
        love.graphics.setLineWidth(1)
        
        -- Title
        love.graphics.setFont(getNativeFont(20))
        love.graphics.printf(step.title, overlayX, overlayY + 30, overlayW, 'center')
        
        -- Text
        love.graphics.setFont(getNativeFont(14))
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.printf(step.text, overlayX + 40, overlayY + 80, overlayW - 80, 'center')
        
        -- Click to continue
        love.graphics.setFont(getNativeFont(10))
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.printf("Click or Press SPACE to continue (" .. self.tutorialStep .. "/" .. #self.tutorialSteps .. ")", 
            overlayX, overlayY + overlayH - 30, overlayW, 'center')
    end
end

return PlayState
