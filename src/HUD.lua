local HUD = Class:extend()

function HUD:new(playState)
    self.playState = playState
    
    -- Images & Assets
    self.heartsImage = love.graphics.newImage('imgs/hearts.png')
    self.manaBarImage = love.graphics.newImage('imgs/mana-bar.png')
    self.bookImage = love.graphics.newImage('imgs/book.png')
    self.upgradeIcon = love.graphics.newImage('imgs/pentagram-upgrade.png')
    
    -- Quads
    local hw = self.heartsImage:getWidth()
    local hh = self.heartsImage:getHeight()
    self.heartFullQuad = love.graphics.newQuad(0, 0, hw/2, hh, hw, hh)
    self.heartEmptyQuad = love.graphics.newQuad(hw/2, 0, hw/2, hh, hw, hh)
    
    -- Grimoire State
    self.showGrimoire = false
    self.grimoireY = love.graphics.getHeight()
    self.grimoireTargetY = love.graphics.getHeight()
    self.grimoirePage = 1
    self.grimoireSpells = {'IMP', 'VOIDWALKER', 'SUCCUBUS', 'MEDITATE', 'MANA', 'REGEN', 'HEAL', 'UPGRADES_LOG'}
    self.grimoireAnimTimer = 0
    self.grimoireFloatTimer = 0
    self.grimoireAnimFrame = 1
    self.boonScrollOffset = 0
    
    -- Animation State
    self.manaAnimIntensity = 0
    
    -- Tutorial State
    -- self.playState.tutorialSeen/showTutorial handles the logic, we handle display state if needed?
    -- Actually tutorial logic blocks input, so it's deeply tied to PlayState update loop.
    -- But rendering is here.
    
    -- Particles (Visuals only)
    self.meditateParticles = {}
    self.manaAbsorptionParticles = {}
    
    -- Shader
    self.vignetteShader = love.graphics.newShader[[
        extern vec2 screenDims;
        extern float time;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 uv = screen_coords / screenDims;
            vec2 center = vec2(0.5, 0.5);
            float d = distance(uv, center);
            
            float edge = 0.3 + (sin(time * 2.0) * 0.05);
            float vignette = smoothstep(edge, 1.2, d); 
            
            float alpha = 0.3 + (sin(time * 3.0) * 0.1);
            
            return vec4(0.4, 0.8, 1.0, vignette * alpha);
        }
    ]]
end

function HUD:update(dt)
    -- Update Grimoire Animation (Slide)
    local winH = love.graphics.getHeight()
    local bookScale = 1.1 
    local bookH = winH * bookScale
    
    if self.showGrimoire then
        self.grimoireTargetY = (winH - bookH) / 2
    else
        self.grimoireTargetY = winH + 10
    end
    
    self.grimoireY = self.grimoireY + (self.grimoireTargetY - self.grimoireY) * 10 * dt
    
    if self.showGrimoire and math.abs(self.grimoireY - self.grimoireTargetY) < 1 then
        self.grimoireAnimTimer = self.grimoireAnimTimer + dt
        self.grimoireFloatTimer = self.grimoireFloatTimer + dt
        if self.grimoireAnimTimer >= 0.15 then
            self.grimoireAnimTimer = 0
            self.grimoireAnimFrame = (self.grimoireAnimFrame % 4) + 1
        end
    end
    
    -- Update Mana Animation Intensity
    local targetIntensity = self.playState.isChanneling and 1 or 0
    self.manaAnimIntensity = self.manaAnimIntensity + (targetIntensity - self.manaAnimIntensity) * dt * 10
    
    -- Update Particles
    self:updateParticles(dt)
end

function HUD:updateParticles(dt)
    -- Meditate Particles logic
    if self.playState.isChanneling then
        local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
        if math.random() < (10 * dt) then 
            table.insert(self.meditateParticles, {
                x = math.random(0, winW),
                y = winH + 10,
                vx = (math.random() - 0.5) * 50,
                vy = -math.random(50, 150),
                life = math.random(1, 3),
                maxLife = 3,
                size = math.random(2, 5)
            })
        end
    end
    
    for i = #self.meditateParticles, 1, -1 do
        local p = self.meditateParticles[i]
        p.life = p.life - dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        if p.life <= 0 or p.y < -10 then table.remove(self.meditateParticles, i) end
    end
    
    -- Mana Absorption Particles logic
    local winW = love.graphics.getWidth()
    local time = love.timer.getTime()
    local resolutionScale = winW / 1280
    
    -- Re-calculate target (Mana Bar center)
    local baseImgX, baseImgY = 20, 20
    local rawFloat = math.sin(time * 1.5) * 5 
    local rawSway = (love.math.noise(time * 0.5) - 0.5) * 20
    local floatOffset = rawFloat * self.manaAnimIntensity
    local swayOffset = rawSway * self.manaAnimIntensity
    
    local imgX = math.floor(baseImgX + swayOffset)
    local imgY = math.floor(baseImgY + floatOffset)
    local barW = math.floor(math.max(1, 190 * resolutionScale))
    local barH = math.floor(math.max(1, 20 * resolutionScale))
    local barX = math.floor(imgX + (60 * resolutionScale)) -- Approx
    local barY = math.floor(imgY + (65 * resolutionScale))
    
    local targetX = barX + barW / 2
    local targetY = barY + barH / 2
    
    for i = #self.manaAbsorptionParticles, 1, -1 do
        local p = self.manaAbsorptionParticles[i]
        p.timer = p.timer + dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        
        if p.state == 'explode' then
             p.vx = p.vx * 0.9
             p.vy = p.vy * 0.9
             if p.timer > 0.15 then p.state = 'seek' end
        elseif p.state == 'seek' then
             local dx = targetX - p.x
             local dy = targetY - p.y
             local dist = math.sqrt(dx*dx + dy*dy)
             if dist < 20 then
                 self.playState.mana = math.min(self.playState.mana + (p.value or 0), self.playState.maxMana)
                 table.remove(self.manaAbsorptionParticles, i)
             else
                 local nx, ny = dx/dist, dy/dist
                 local seekSpeed = 7000 + (p.timer * 10000)
                 if dist < 100 then seekSpeed = seekSpeed + 5000 end
                 p.vx = p.vx + (nx * seekSpeed) * dt
                 p.vy = p.vy + (ny * seekSpeed) * dt -- Simplified steering for brevity
                 p.vx = p.vx * 0.92
                 p.vy = p.vy * 0.92
             end
        end
        if p.timer > 8.0 then table.remove(self.manaAbsorptionParticles, i) end
    end
end

function HUD:render()
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local layoutScale = math.max(1, winH / 720)
    local resolutionScale = winW / 1280
    
    local ps = self.playState
    
    -- Helper
    local function getNativeFont(baseSize)
        local target = baseSize * layoutScale
        if target <= 7 then return gFonts['tiny']
        elseif target <= 10 then return gFonts['small']
        elseif target <= 14 then return gFonts['medium_small']
        elseif target <= 20 then return gFonts['medium']
        elseif target <= 28 then return gFonts['xlarge']
        elseif target <= 40 then return gFonts['large']
        else return gFonts['huge'] end
    end
    
    -- Expose to methods
    self.getNativeFont = getNativeFont

    -- 1. Mana Bar Rendering
    local baseImgX, baseImgY = 20, 20
    local time = love.timer.getTime()
    local rawFloat = math.sin(time * 1.5) * 5
    local rawSway = (love.math.noise(time * 0.5) - 0.5) * 20
    local floatOffset = rawFloat * self.manaAnimIntensity
    local swayOffset = rawSway * self.manaAnimIntensity
    
    local imgX = math.floor(baseImgX + swayOffset)
    local imgY = math.floor(baseImgY + floatOffset)
    local imgW = self.manaBarImage:getWidth()
    local imgH = self.manaBarImage:getHeight()
    local targetWidth = winW * 0.25
    local scale = targetWidth / imgW
    
    local barMaxWidth = math.floor(math.max(1, 190 * resolutionScale))
    local barHeight = math.floor(math.max(1, 20 * resolutionScale))
    local barX = math.floor(imgX + (60 * resolutionScale))
    local barY = math.floor(imgY + (65 * resolutionScale))
    
    -- Fill
    local fillWidth = (ps.mana / ps.maxMana) * barMaxWidth
    local pixelSize = math.max(1, 4 * scale)
    
    love.graphics.setScissor(barX, barY, fillWidth, barHeight)
    for y = 0, barHeight, pixelSize do
        for x = 0, barMaxWidth, pixelSize do
            if x < fillWidth then
                local wave = math.sin(time * 2.0 + x * 0.1)
                local noise = love.math.noise(x * 0.05, y * 0.05, time * 0.5)
                local combined = (wave * 0.7) + (noise * 0.3)
                love.graphics.setColor(0.1, 0.2 + (combined + 1) * 0.1, 0.7 + (combined + 1) * 0.15, 0.8 + noise * 0.2)
                love.graphics.rectangle('fill', barX + x, barY + y, pixelSize, pixelSize)
            end
        end
    end
    love.graphics.setScissor()
    
    -- Markers
    love.graphics.setColor(0, 0, 0, 0.5)
    for i = 100, ps.maxMana - 1, 100 do
        local markerRatio = i / ps.maxMana
        local markerX = barX + markerRatio * barMaxWidth
        if markerX < barX + barMaxWidth then
            love.graphics.line(markerX, barY, markerX, barY + barHeight)
        end
    end
    
    -- Frame
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.manaBarImage, imgX, imgY, 0, scale, scale)
    
    -- Text
    love.graphics.setFont(gFonts['medium_small'])
    local manaText = math.floor(ps.mana) .. '/' .. math.floor(ps.maxMana)
    local textY = barY + (4 * resolutionScale)
    love.graphics.printf(manaText, barX, textY, 190, 'center', 0, resolutionScale, resolutionScale)
    
    -- Absorption Particles
    love.graphics.setBlendMode('add')
    for _, p in ipairs(self.manaAbsorptionParticles) do
        love.graphics.setColor(0.2, 0.6, 1, 1.0)
        love.graphics.rectangle('fill', p.x - 3, p.y - 3, 6, 6)
    end
    love.graphics.setBlendMode('alpha')
    love.graphics.setColor(1, 1, 1, 1)

    -- 2. Hearts (Centered on Screen, Aligned Y with Bar)
    local heartSize = 64 * resolutionScale 
    local heartSpacing = 5 * resolutionScale
    local hScale = heartSize / (self.heartsImage:getHeight())
    
    local totalHeartW = (ps.maxCastleHealth * heartSize) + ((ps.maxCastleHealth - 1) * heartSpacing)
    local heartsStartX = (winW / 2) - (totalHeartW / 2)
    local heartsY = imgY + (imgH * scale) / 2 - (heartSize / 2)
    
    local curHeartX = heartsStartX
    for i = 1, ps.maxCastleHealth do
        local quad = self.heartEmptyQuad
        if i <= ps.castleHealth then quad = self.heartFullQuad end
        love.graphics.draw(self.heartsImage, quad, curHeartX, heartsY, 0, hScale, hScale)
        curHeartX = curHeartX + heartSize + heartSpacing
    end
    
    -- 3. Souls & Wave (Simple Text)
    love.graphics.setFont(getNativeFont(16))
    love.graphics.setColor(0.8, 0.4, 1, 1) 
    love.graphics.printf(ps.souls .. " Souls", winW - (220 * layoutScale), 50 * layoutScale, 200 * layoutScale, 'right', 0, 1, 1)
    
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print('Wave: ' .. ps.wave, winW / 2 - (50 * layoutScale), 20 * layoutScale, 0, 1, 1)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- 4. Typing Buffer
    if ps.isTyping then
        love.graphics.setFont(getNativeFont(16))
        local bufferW, bufferH = 400 * layoutScale, 60 * layoutScale
        local bufferX, bufferY = (winW - bufferW) / 2, winH - (100 * layoutScale)
        
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle('fill', bufferX, bufferY, bufferW, bufferH, 10 * layoutScale)
        love.graphics.setColor(1, 0.8, 0, 1) 
        love.graphics.setLineWidth(2 * layoutScale)
        love.graphics.rectangle('line', bufferX, bufferY, bufferW, bufferH, 10 * layoutScale)
        love.graphics.setLineWidth(1)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(ps.inputBuffer, bufferX, bufferY + (15 * layoutScale), bufferW, 'center')
        
        love.graphics.setFont(getNativeFont(10))
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.printf("TYPE UNIT NAME AND ENTER", bufferX, bufferY + bufferH + (5 * layoutScale), bufferW, 'center')
    else
        love.graphics.setFont(getNativeFont(10))
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.printf("W/S: Select Lane | ENTER: Summon | TAB: Grimoire", 0, winH - (30 * layoutScale), winW, 'center')
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- 5. Grimoire
    if self.grimoireY < winH then
        self:renderGrimoire(winW, winH, layoutScale)
    end
    
    -- 6. Channeling Vignette
    if ps.isChanneling then
        self.vignetteShader:send("screenDims", {winW, winH})
        self.vignetteShader:send("time", love.timer.getTime())
        love.graphics.setShader(self.vignetteShader)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('fill', 0, 0, winW, winH)
        love.graphics.setShader()
        
        love.graphics.setBlendMode('add')
        for _, p in ipairs(self.meditateParticles) do
            love.graphics.setColor(0.4, 0.8, 1, p.life / p.maxLife)
            love.graphics.rectangle('fill', p.x, p.y, p.size, p.size)
        end
        love.graphics.setBlendMode('alpha')
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- 7. Tutorial
    if ps.showTutorial then
        self:renderTutorial(winW, winH, layoutScale, getNativeFont)
    end
end

function HUD:renderGrimoire(winW, winH, layoutScale)
    -- Helper for Font Scaling
    local function getNativeFont(baseSize)
        local target = baseSize * layoutScale
        if target <= 7 then return gFonts['tiny']
        elseif target <= 10 then return gFonts['small']
        elseif target <= 14 then return gFonts['medium_small']
        elseif target <= 20 then return gFonts['medium']
        elseif target <= 28 then return gFonts['xlarge']
        elseif target <= 40 then return gFonts['large']
        else return gFonts['huge'] end
    end

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
        
        if #self.playState.selectedUpgrades == 0 then
            love.graphics.setFont(getNativeFont(10))
            love.graphics.printf("No boons yet claimed...", rightPageX, contentY, rightPageW, 'center')
        else
            local maxVisibleBoons = 4 
            local numBoons = #self.playState.selectedUpgrades
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
                local upgrade = self.playState.selectedUpgrades[i]
                
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
            -- Accessing Demon static assets (Ensure Demon is loaded)
            if Demon and Demon.impSprite then
                love.graphics.draw(Demon.impSprite, Demon.impQuads[self.grimoireAnimFrame], iconX, iconY, 0, s, s)
            else
               -- Fallback
               love.graphics.rectangle('line', iconX, iconY, iconSize, iconSize)
            end
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
            displayCost = self.playState:getUpgradeCost(spellKey)
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

function HUD:renderTutorial(winW, winH, layoutScale, fontFunc)
    local step = self.playState.tutorialSteps[self.playState.tutorialStep]
    local overlayW = 500 * layoutScale
    local overlayH = 250 * layoutScale
    local overlayX = (winW - overlayW) / 2
    local overlayY = (winH - overlayH) / 2
    
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle('fill', overlayX, overlayY, overlayW, overlayH, 15)
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle('line', overlayX, overlayY, overlayW, overlayH, 15)
    love.graphics.setLineWidth(1)
    
    love.graphics.setFont(fontFunc(20))
    love.graphics.printf(step.title, overlayX, overlayY + 30, overlayW, 'center')
    love.graphics.setFont(fontFunc(14))
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.printf(step.text, overlayX + 40, overlayY + 80, overlayW - 80, 'center')
    
    love.graphics.setFont(fontFunc(10))
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.printf("Press SPACE/ENTER/CLICK to continue", overlayX, overlayY + overlayH - 30, overlayW, 'center')
end

return HUD
