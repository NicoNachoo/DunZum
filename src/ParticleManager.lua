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

function ParticleManager:spawnHealEffect(x, y)
    local ps = love.graphics.newParticleSystem(self.texture, 16)
    ps:setParticleLifetime(0.5, 1.0)
    ps:setLinearAcceleration(-10, -30, 10, -10) -- Float up gently
    ps:setColors(0, 1, 0.2, 1, 0, 1, 0.2, 0) -- Green fade
    
    ps:emit(8)
    
    table.insert(self.systems, { ps = ps, x = x, y = y })
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

function ParticleManager:update(dt)
    for i = #self.systems, 1, -1 do
        local system = self.systems[i]
        system.ps:update(dt)
        if system.ps:getCount() == 0 then
            table.remove(self.systems, i)
        end
    end
end

function ParticleManager:render()
    for _, system in ipairs(self.systems) do
        love.graphics.draw(system.ps, system.x, system.y)
    end
end

return ParticleManager
