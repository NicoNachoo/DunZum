local UpgradeState = BaseState:extend()

-- Load scroll image for card backgrounds
local scrollImage = love.graphics.newImage('imgs/scroll-upgrade.png')

local ALL_UPGRADES = {
    { id = 'DEMON_HP', name = "Iron Spirits", desc = "Demons gain +30% Max HP.", effect = function(p) p.demonHpMult = p.demonHpMult + 0.3 end },
    { id = 'DEMON_DMG', name = "Vicious Intent", desc = "Demons deal +25% Damage.", effect = function(p) p.demonDamageMult = p.demonDamageMult + 0.25 end },
    { id = 'MANA_REGEN', name = "Essence Flow", desc = "Meditate Mana Regen +2/sec.", effect = function(p) p.manaRegen = p.manaRegen + 2 end },
    { id = 'MAX_MANA', name = "Mana Surge", desc = "+50 Max Mana.", effect = function(p) p.maxMana = p.maxMana + 50 end },
    { id = 'MANA_REFUND', name = "Efficient Exit", desc = "Mana refund increased by 20%.", effect = function(p) p.manaRefundRate = math.min(1.0, p.manaRefundRate + 0.2) end },
    { id = 'REDUCE_COST', name = "Swift Summoning", desc = "All summons cost -4 mana.", effect = function(p) p.manaCostReduction = p.manaCostReduction + 4 end },
    { id = 'IMP_RANGE', name = "Greater Reach", desc = "Imp attack range +60.", effect = function(p) p.impRangeBonus = p.impRangeBonus + 60 end },
    { id = 'VOIDWALKER_ARMOR', name = "Dense Ether", desc = "Voidwalker takes -15% damage.", effect = function(p) p.voidwalkerArmor = math.max(0.1, p.voidwalkerArmor - 0.15) end },
}

function UpgradeState:enter(params)
    self.playState = params.playState
    self.choices = {}
    
    -- Pick 3 random unique upgrades
    local pool = {}
    for i, u in ipairs(ALL_UPGRADES) do table.insert(pool, u) end
    
    for i = 1, 3 do
        if #pool == 0 then break end
        local idx = love.math.random(#pool)
        table.insert(self.choices, pool[idx])
        table.remove(pool, idx)
    end
    
    self.highlighted = 1
    self.timer = 0
    
    -- Animation state
    self.animationTimer = 0
    self.animationPhase = 'sliding' -- 'sliding' -> 'done'
    
    -- Per-card animation state
    self.cardAnims = {}
    for i = 1, #self.choices do
        self.cardAnims[i] = {
            xOffset = -1000 - (i * 100),  -- Start off-screen to the left
            scale = 1,
            floatIntensity = 0,
            wobbleOffset = math.random() * math.pi * 2 -- Random start phase for rotation
        }
    end
    
    -- Particles for cursor
    self.cursorParticles = {}
end

function UpgradeState:update(dt)
    -- Only allow input after animation is done
    if self.animationPhase == 'done' then
        if love.keyboard.wasPressed('1') then self:select(1)
        elseif love.keyboard.wasPressed('2') then self:select(2)
        elseif love.keyboard.wasPressed('3') then self:select(3)
        end
        
        if love.keyboard.wasPressed('left') or love.keyboard.wasPressed('a') then
            self.highlighted = math.max(1, self.highlighted - 1)
        elseif love.keyboard.wasPressed('right') or love.keyboard.wasPressed('d') then
            self.highlighted = math.min(#self.choices, self.highlighted + 1)
        elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('space') then
            self:select(self.highlighted)
        end
    end
    
    self.timer = self.timer + dt
    
    -- Update float intensity for each card (smooth transition)
    if self.animationPhase == 'done' then
        for i = 1, #self.choices do
            local anim = self.cardAnims[i]
            local targetIntensity = (i == self.highlighted) and 1 or 0
            local speed = 3  -- Transition speed
            if anim.floatIntensity < targetIntensity then
                anim.floatIntensity = math.min(targetIntensity, anim.floatIntensity + dt * speed)
            else
                anim.floatIntensity = math.max(targetIntensity, anim.floatIntensity - dt * speed)
            end
        end
    end
    
    -- Update cursor particles
    if self.animationPhase == 'done' then
        -- Spawn new particles
        if math.random() < 0.3 then -- 30% chance per frame
            table.insert(self.cursorParticles, {
                x = (math.random() - 0.5) * 40, -- Relative to cursor X
                y = (math.random() - 0.5) * 40, -- Relative to cursor Y
                speedY = -math.random(10, 30),  -- Float up
                life = 1.0, 
                maxLife = 1.0,
                size = math.random(2, 4)
            })
        end
        
        -- Update existing particles
        for i = #self.cursorParticles, 1, -1 do
            local p = self.cursorParticles[i]
            p.life = p.life - dt
            p.y = p.y + p.speedY * dt
            
            if p.life <= 0 then
                table.remove(self.cursorParticles, i)
            end
        end
    end
    
    -- Animation update
    if self.animationPhase == 'sliding' then
        self.animationTimer = self.animationTimer + dt
        
        local cardSlideDuration = 0.5 -- Duration for each card to slide
        local staggerDelay = 0.15     -- Delay between each card starting
        
        local allDone = true
        for i = 1, #self.choices do
            local anim = self.cardAnims[i]
            
            -- Each card starts after a staggered delay
            local cardStartTime = (i - 1) * staggerDelay
            local cardProgress = math.max(0, math.min(1, (self.animationTimer - cardStartTime) / cardSlideDuration))
            
            -- Easing function (ease out cubic)
            local cardEased = 1 - math.pow(1 - cardProgress, 3)
            
            -- Slide from off-screen left to final position (xOffset 0)
            local startOffset = -1000 - (i * 100)
            anim.xOffset = startOffset * (1 - cardEased)
            
            if cardProgress < 1 then
                allDone = false
            end
        end
        
        if allDone then
            self.animationPhase = 'done'
            for i = 1, #self.choices do
                self.cardAnims[i].xOffset = 0
            end
        end
    end
end

function UpgradeState:select(index)
    if self.choices[index] then
        local choice = self.choices[index]
        choice.effect(self.playState)
        
        -- Store the upgrade for the Grimoire log (with stacking)
        local found = false
        for i, upgrade in ipairs(self.playState.selectedUpgrades) do
            if upgrade.id == choice.id then
                -- Increment count for duplicate upgrades
                upgrade.count = upgrade.count + 1
                found = true
                break
            end
        end
        
        if not found then
            -- Add new upgrade with count = 1
            table.insert(self.playState.selectedUpgrades, {
                id = choice.id,
                name = choice.name,
                desc = choice.desc,
                count = 1
            })
        end
        
        gStateMachine:pop() -- Go back to PlayState
        -- PlayState will continue to next wave logic
        self.playState:nextWave()
    end
end

function UpgradeState:render()
    -- Darkened overlay (Virtual resolution space)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
end

function UpgradeState:renderUI()
    -- Draw PlayState UI in background
    self.playState:renderUI()
    
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    
    -- Resolution Scale (Base 1280x720)
    local resolutionScale = winW / 1280
    
    -- Only show title after animation starts
    if self.animationPhase ~= 'stacked' then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("CHOOSE AN UPGRADE", 0, 60 * resolutionScale, winW / resolutionScale, 'center', 0, resolutionScale, resolutionScale)
    end
    
    -- Get scroll image dimensions and set card size to match
    local imgW = scrollImage:getWidth()
    local imgH = scrollImage:getHeight()
    local scrollScale = 0.40 * resolutionScale -- Scale factor for the scroll image
    local cardW = imgW * scrollScale
    local cardH = imgH * scrollScale
    local scaledW = cardW
    local scaledH = cardH
    local scrollOffsetX = 0
    local scrollOffsetY = 0
    local spacing = 30 * resolutionScale
    
    local startX = (winW - (cardW * 3 + spacing * 2)) / 2
    local y = winH / 2 - cardH / 2
    
    for i, upgrade in ipairs(self.choices) do
        local anim = self.cardAnims[i]
        local baseX = startX + (i-1) * (cardW + spacing)
        local x = baseX + (anim and anim.xOffset or 0)
        
        -- Get animation values
        local scale = anim and anim.scale or 1
        
        -- Push transform
        love.graphics.push()
        love.graphics.translate(x + cardW/2, y + cardH/2)
        
        -- Apply random rotation (wobble)
        local wobble = anim and anim.wobbleOffset or 0
        local rotation = math.sin(self.timer * 2 + wobble) * 0.03
        love.graphics.rotate(rotation)
        
        love.graphics.scale(scale, scale)
        love.graphics.translate(-cardW/2, -cardH/2)
        
        -- Floating animation with smooth transition (AGGRRESSIVE)
        local floatIntensity = anim and anim.floatIntensity or 0
        -- Increased frequency (3->5) and amplitude (6->10)
        local floatOffsetY = math.sin(self.timer * 5) * 10 * floatIntensity * resolutionScale
        
        -- Draw dark magical cursor above selected card
        if floatIntensity > 0.1 then
            love.graphics.push()
            -- Position above the card, moving with it
            local cursorX = scrollOffsetX + scaledW / 2
            local cursorY = scrollOffsetY + floatOffsetY - (30 * resolutionScale)
            
            -- Alpha based on selection intensity
            local alpha = floatIntensity
            
            -- Draw particles
            for _, p in ipairs(self.cursorParticles) do
                local pAlpha = (p.life / p.maxLife) * alpha
                love.graphics.setColor(0.4, 0, 0.6, pAlpha)
                love.graphics.circle('fill', cursorX + (p.x * resolutionScale), cursorY + (p.y * resolutionScale), p.size * resolutionScale)
            end
            
            -- Draw glow
            love.graphics.setColor(0.5, 0, 0.5, 0.4 * alpha)
            love.graphics.circle('fill', cursorX, cursorY, (25 + math.sin(self.timer * 10) * 5) * resolutionScale)
            
            -- Draw inverted cross cursor
            love.graphics.setColor(0.2, 0, 0.3, alpha) -- Dark purple
            
            -- Vertical bar (pointing down, so top is thinner/shorter?) - standard cross shape 
            local barW = 8 * resolutionScale
            local barH = 35 * resolutionScale
            love.graphics.rectangle('fill', cursorX - barW/2, cursorY - barH/2, barW, barH)
            
            -- Horizontal bar (lower down for inverted cross)
            local hBarW = 25 * resolutionScale
            local hBarH = 8 * resolutionScale
            love.graphics.rectangle('fill', cursorX - hBarW/2, cursorY + (5 * resolutionScale), hBarW, hBarH)
            
            -- Inner detail (brighter purple)
            love.graphics.setColor(0.6, 0.2, 0.8, alpha)
            love.graphics.rectangle('fill', cursorX - barW/4, cursorY - barH/2 + (2 * resolutionScale), barW/2, barH - (4 * resolutionScale))
            love.graphics.rectangle('fill', cursorX - hBarW/4 + (2 * resolutionScale), cursorY + (7 * resolutionScale), hBarW/2 - (4 * resolutionScale), hBarH/2)
            
            love.graphics.pop()
        end
        
        -- Draw scroll image with floating effect
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(scrollImage, scrollOffsetX, scrollOffsetY + floatOffsetY, 0, scrollScale, scrollScale)
            
        -- Text positioned inside the scroll's paper area
        -- The red X symbol is at about 15% from left, 18% from top
        -- Position text to the right of it and centered in the paper area
        local textStartX = scrollOffsetX + scaledW * 0.40   -- Start after the red X
        local textAreaTop = scrollOffsetY + floatOffsetY + scaledH * 0.32  -- Below top roll
        local textWidth = scaledW * 0.30                    -- Width for text
        local textAreaBottom = scrollOffsetY + floatOffsetY + scaledH * 0.70  -- Above bottom roll
        
        -- Upgrade name (to the right of the red X)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['medium_small'])
        love.graphics.printf(upgrade.name, textStartX, textAreaTop, textWidth / resolutionScale, 'left', 0, resolutionScale, resolutionScale)
        
        -- Description (below the name, centered)
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        love.graphics.setFont(gFonts['small'])
        local descY = textAreaTop + (50 * resolutionScale)
        love.graphics.printf(upgrade.desc, scrollOffsetX + scaledW * 0.30, descY, (scaledW * 0.40) / resolutionScale, 'left', 0, resolutionScale, resolutionScale)
        
        -- Press number instruction
        if i == self.highlighted and self.animationPhase == 'done' then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 0.7)
        end
        love.graphics.printf("Press " .. i, scrollOffsetX, textAreaBottom, scaledW / resolutionScale, 'center', 0, resolutionScale, resolutionScale)
        
        love.graphics.pop()
    end
end

return UpgradeState
