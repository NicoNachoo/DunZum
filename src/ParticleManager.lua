local ParticleManager = Class:extend()

function ParticleManager:new()
    self.systems = {}
    
    -- Create a simple 2x2 white pixel texture for particles
    local canvas = love.graphics.newCanvas(2, 2)
    love.graphics.setCanvas(canvas)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('fill', 0, 0, 2, 2)
    love.graphics.setCanvas()
    self.texture = canvas
    
    self.spriteEffects = {}
    
    -- Load Heal Effect
    local healDef = HERO_ANIMATIONS['PRIEST']['HEAL_EFFECT']
    if healDef and love.filesystem.getInfo(healDef.texture) then
        self.healEffectImg = love.graphics.newImage(healDef.texture)
        self.healEffectQuads = {}
        local fw = self.healEffectImg:getWidth() / healDef.frames
        local fh = self.healEffectImg:getHeight()
        for i = 0, healDef.frames - 1 do
            table.insert(self.healEffectQuads, love.graphics.newQuad(i * fw, 0, fw, fh, self.healEffectImg:getDimensions()))
        end
    end
    
    -- Load Priest Attack Effect
    local attackDef = HERO_ANIMATIONS['PRIEST']['ATTACK_EFFECT']
    if attackDef and love.filesystem.getInfo(attackDef.texture) then
        self.priestAttackEffectSprite = love.graphics.newImage(attackDef.texture)
        self.priestAttackEffectQuads = {}
        local fw = self.priestAttackEffectSprite:getWidth() / attackDef.frames
        local fh = self.priestAttackEffectSprite:getHeight()
        for i = 0, attackDef.frames - 1 do
            table.insert(self.priestAttackEffectQuads, love.graphics.newQuad(i * fw, 0, fw, fh, self.priestAttackEffectSprite:getDimensions()))
        end
    end
end

function ParticleManager:spawnChargeEffect(x, y, color)
    local ps = love.graphics.newParticleSystem(self.texture, 32)
    ps:setParticleLifetime(0.6, 1.2)
    -- Vertical motion: Up
    ps:setLinearAcceleration(-10, -80, 10, -40) 
    ps:setSpeed(5, 15)
    ps:setSpread(math.pi / 2)
    -- Use a bright orange/yellow for charging
    ps:setColors(1, 0.9, 0.3, 1, 1, 0.4, 0, 0)
    ps:setSizeVariation(1)
    
    ps:emit(1)
    
    table.insert(self.systems, { ps = ps, x = x, y = y })
end

function ParticleManager:spawnExplosion(x, y, color)
    local ps = love.graphics.newParticleSystem(self.texture, 32)
    ps:setParticleLifetime(0.5, 1.0)
    ps:setLinearAcceleration(-50, -50, 50, 50)
    ps:setSpeed(20, 50)
    ps:setSpread(math.pi * 2)
    ps:setColors(color[1], color[2], color[3], 1, color[1], color[2], color[3], 0)
    ps:setSizeVariation(1)
    
    ps:emit(16)
    -- Don't setPosition, just draw at location
    
    table.insert(self.systems, { ps = ps, x = x, y = y })
end

function ParticleManager:spawnPoof(x, y)
    local ps = love.graphics.newParticleSystem(self.texture, 16)
    ps:setParticleLifetime(0.3, 0.6)
    ps:setLinearAcceleration(-10, -50, 10, -20) -- float up
    ps:setColors(1, 1, 1, 0.8, 1, 1, 1, 0)
    
    ps:emit(8)
    
    table.insert(self.systems, { ps = ps, x = x, y = y })
end

function ParticleManager:spawnFireExplosion(x, y)
    local ps = love.graphics.newParticleSystem(self.texture, 32)
    ps:setParticleLifetime(0.2, 0.5)
    ps:setLinearAcceleration(-50, -50, 50, 50)
    ps:setSpeed(30, 80)
    ps:setSpread(math.pi * 2)
    ps:setColors(1, 0.5, 0, 1, 1, 1, 0, 0) -- Orange -> Yellow -> Transparent
    ps:setSizeVariation(1)
    
    ps:emit(12)
    
    table.insert(self.systems, { ps = ps, x = x, y = y })
end

function ParticleManager:spawnHealEffectSprite(x, y)
    if not self.healEffectImg then return end
    local def = HERO_ANIMATIONS['PRIEST']['HEAL_EFFECT']
    table.insert(self.spriteEffects, {
        type = 'HEAL',
        x = x,
        y = y,
        timer = 0,
        duration = def.duration * def.frames,
        frameDuration = def.duration
    })
end

function ParticleManager:spawnPriestAttackEffect(x, y)
    if not self.priestAttackEffectSprite then return end
    local def = HERO_ANIMATIONS['PRIEST']['ATTACK_EFFECT']
    table.insert(self.spriteEffects, {
        type = 'PRIEST_ATTACK',
        x = x,
        y = y,
        timer = 0,
        duration = def.duration * def.frames,
        frameDuration = def.duration
    })
end

function ParticleManager:spawnPortalEffect(x, y)
    local ps = love.graphics.newParticleSystem(self.texture, 32)
    ps:setParticleLifetime(0.5, 0.8)
    -- Swirling motion
    ps:setLinearAcceleration(-20, -20, 20, 20)
    ps:setSpeed(10, 30)
    ps:setSpin(math.pi * -2, math.pi * 2)
    -- Dark purple/void colors
    ps:setColors(0.4, 0, 0.8, 0.5, 0.1, 0, 0.2, 0)
    ps:setSizeVariation(1)
    
    ps:emit(4)
    
    table.insert(self.systems, { ps = ps, x = x, y = y })
end

function ParticleManager:spawnCancelEffect(x, y)
    local ps = love.graphics.newParticleSystem(self.texture, 32)
    ps:setParticleLifetime(0.4, 0.7)
    ps:setLinearAcceleration(-30, -60, 30, -20) -- burst up
    -- Bright cyan/mana colors
    ps:setColors(0, 0.8, 1, 1, 0, 0.3, 0.5, 0)
    ps:setSizeVariation(1)
    
    ps:emit(12)
    
    table.insert(self.systems, { ps = ps, x = x, y = y })
end

function ParticleManager:spawnRageParticles(x, y)
    local ps = love.graphics.newParticleSystem(self.texture, 8)
    ps:setParticleLifetime(0.5, 1.2)
    -- Float upwards
    ps:setLinearAcceleration(-5, -50, 5, -100)
    ps:setSpeed(10, 20)
    ps:setDirection(-math.pi / 2) -- Up
    ps:setSpread(0.5)
    -- Red squares fading out
    ps:setColors(1, 0, 0, 0.8, 0.5, 0, 0, 0)
    ps:setSizeVariation(0.5)
    ps:setSizes(2, 1) -- Start larger, shrink
    
    ps:emit(1) 
    
    table.insert(self.systems, { ps = ps, x = x, y = y })
end



function ParticleManager:update(dt)
    for i = #self.systems, 1, -1 do
        local system = self.systems[i]
        system.ps:update(dt)
        if system.ps:getCount() == 0 then
            table.remove(self.systems, i)
        end
    end
    
    for i = #self.spriteEffects, 1, -1 do
        local effect = self.spriteEffects[i]
        effect.timer = effect.timer + dt
        if effect.timer >= effect.duration then
            table.remove(self.spriteEffects, i)
        end
    end
end

function ParticleManager:render()
    for _, system in ipairs(self.systems) do
        love.graphics.draw(system.ps, system.x, system.y)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    for _, effect in ipairs(self.spriteEffects) do
        local img, quads, scale
        if effect.type == 'HEAL' then
             img = self.healEffectImg
             quads = self.healEffectQuads
             scale = HERO_ANIMATIONS['PRIEST']['HEAL_EFFECT'].scale
        elseif effect.type == 'PRIEST_ATTACK' then
             img = self.priestAttackEffectSprite
             quads = self.priestAttackEffectQuads
             scale = HERO_ANIMATIONS['PRIEST']['ATTACK_EFFECT'].scale
        end
        
        if img and quads then
            local frame = math.floor(effect.timer / effect.frameDuration) + 1
            if frame <= #quads then
                 local quad = quads[frame]
                 local _, _, w, h = quad:getViewport()
                 love.graphics.draw(img, quad, effect.x, effect.y, 0, scale, scale, w/2, h/2)
            end
        end
    end
end

return ParticleManager
