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
    self.maxCastleHealth = 3
    self.castleSignal = false 
    self.castleSignalTimer = 0
    
    -- Currency
    self.souls = data and data.souls or 0

    -- Particles
    gParticleManager = ParticleManager()

    self.floatingNumbers = {}

    -- Screen Shake
    self.shakeDuration = 0
    self.shakeMagnitude = 0
    
    -- HUD
    self.hud = HUD(self)

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
    self.voidwalkerArmor = data and data.voidwalkerArmor or 0.5 
    
    -- Purchase Tracking
    self.upgradeCounts = data and data.upgradeCounts or {}
    
    -- Mouse tracking
    self.lastMouseX = 0
    self.lastMouseY = 0
    
    -- Particles (still needed if logic references them? or move references to HUD?)
    -- Logic in update() references self.meditateParticles. 
    -- We will move that logic to HUD, but for now let's not crash if we haven't deleted the update logic yet.
    -- Actually, we plan to delete the update logic next. 
    -- But PlayState still adds to them? 
    -- e.g. self.meditateParticles is added to when channeling.
    -- We should change PlayState to add to self.hud.meditateParticles?
    -- Yes. So we don't need self.meditateParticles here if we fix the references.
    
    -- Tutorial State (Logic only)
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

    -- Update HUD
    self.hud:update(dt)

    -- Global Input (Pause)
    if InputManager:wasPressed('back') then
        if self.hud.showGrimoire then
            self.hud.showGrimoire = false
        elseif self.isTyping then
            self.isTyping = false
            self.inputBuffer = ""
        else
            gStateMachine:push('pause')
        end
    end
    
    -- Grimoire Toggle (Tab)
    if love.keyboard.wasPressed('tab') then
        self.hud.showGrimoire = not self.hud.showGrimoire
        if self.hud.showGrimoire then
            self.hud.grimoirePage = 1 -- Reset to first page
        end
        self:breakChanneling()
    end

    -- Grimoire Navigation
    if self.hud.showGrimoire then
        if InputManager:wasPressed('left') then
            self.hud.grimoirePage = math.max(1, self.hud.grimoirePage - 1)
            self.hud.boonScrollOffset = 0
        elseif InputManager:wasPressed('right') then
            self.hud.grimoirePage = math.min(#self.hud.grimoireSpells, self.hud.grimoirePage + 1)
            self.hud.boonScrollOffset = 0
        end
        
        -- Scroll on boons page
        local spellKey = self.hud.grimoireSpells[self.hud.grimoirePage]
        if spellKey == 'UPGRADES_LOG' then
            local numBoons = #self.selectedUpgrades
            local maxScroll = math.max(0, numBoons - 5)
            
            if InputManager:wasPressed('up') then
                self.hud.boonScrollOffset = math.max(0, self.hud.boonScrollOffset - 1)
            elseif InputManager:wasPressed('down') then
                self.hud.boonScrollOffset = math.min(maxScroll, self.hud.boonScrollOffset + 1)
            end
        end
    end
    
    -- Check if Grimoire is fully open (Animation handled in HUD)
    -- Logic: If Grimoire is opening/open, we might want to pause game logic?
    -- Original code paused if animation was running or open.
    -- We can check self.hud.showGrimoire.
    -- But we want the slide to finish?
    -- HUD handles the slide.
    -- Let's just return if showGrimoire is strictly true for now, 
    -- as precise animation timing check is complex across classes without a getter.
    if self.hud.showGrimoire then
        return
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
    
    -- Meditation Particles (Moved to HUD)
    
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
                table.insert(self.hud.manaAbsorptionParticles, {
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
    self.hud:render()
end


return PlayState
