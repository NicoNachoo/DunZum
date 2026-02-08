local Entity = Class:extend()

function Entity:new(x, y, width, height, color)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.color = color or {1, 1, 1, 1}
    self.dead = false
    
    -- Combat Stats
    self.hp = 100
    self.maxHp = 100
    self.damage = 10
    self.attackRange = 5
    self.attackRate = 1.0 -- seconds between attacks
    self.attackTimer = 100 -- Start ready to attack!
    
    self.state = 'WALK' -- 'WALK', 'ATTACK'
    self.target = nil
    
    self.flashTimer = 0
    self.floatingNumbers = {}
    
    -- Mana Stats (Generic)
    self.mana = 0
    self.maxMana = 0
    
    self.lockedAnimTimer = 0 -- Animation lock timer
end

function Entity:update(dt)
    self.attackTimer = self.attackTimer + dt
    
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - dt
    end
end

function Entity:takeDamage(amount, playState, attacker, color)
    self.hp = self.hp - amount
    self.flashTimer = 0.1
    
    if playState then
        local numColor = color or {1, 0, 0, 1} -- Default red
        local fn = FloatingNumber(self.x + self.width/2, self.y, tostring(math.floor(amount)), numColor)
        table.insert(playState.floatingNumbers, fn)
    end

    if self.hp <= 0 then
        self.hp = 0
        self.dead = true
        -- Spawn explosion
        if gParticleManager then
            gParticleManager:spawnExplosion(self.x + self.width/2, self.y + self.height/2, self.color)
        end
    end
end

function Entity:render()
    if self.flashTimer > 0 then
        love.graphics.setColor(1, 1, 1, 1) -- Flash white
        love.graphics.setShader(gWhiteShader) -- We might need a shader for true white flash, but color works okay for now
    else
        love.graphics.setColor(unpack(self.color))
    end
    
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
    love.graphics.setShader() -- Reset shader
    
    -- Draw Black Border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
    
    -- Draw HP Bar
    self:renderHealthBar()
    
    -- Draw Mana Bar (if applicable)
    if self.maxMana > 0 then
        self:renderManaBar()
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Entity:renderHealthBar(customWidth, offsetX)
    if not self.dead then
        local w = customWidth or self.width
        local ox = offsetX or 0
        local hpPercent = math.max(0, self.hp / self.maxHp)
        
        love.graphics.setColor(0, 0, 0, 1) -- HP Bar Border
        love.graphics.rectangle('fill', self.x + ox - 1, self.y - 5, w + 2, 4)
        
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle('fill', self.x + ox, self.y - 4, w, 2)
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.rectangle('fill', self.x + ox, self.y - 4, w * hpPercent, 2)
    end
end

function Entity:renderManaBar(customWidth, offsetX, offsetY)
    if not self.dead and self.maxMana > 0 then
        local w = customWidth or self.width
        local ox = offsetX or 0
        local oy = offsetY or 0
        local manaPercent = math.max(0, self.mana / self.maxMana)
        
        -- Draw below HP bar (HP is at y-5, height 4. Mana at y-1?)
        -- HP Bar is at self.y - 5 (border) -> self.y - 1 (bottom)
        -- Let's put Mana Bar right below it? Or maybe above?
        -- Standard: HP, then Mana below?
        -- If HP is at y-5, let's put mana at y-1 or slightly lower?
        -- Actually, HP bar is taking y-5 to y-1. 
        -- Entity starts at y.
        -- Let's put mana bar directly under HP bar, at y-1?
        
        love.graphics.setColor(0, 0, 0, 1) -- Mana Bar Border
        love.graphics.rectangle('fill', self.x + ox - 1, self.y - 1, w + 2, 3) 
        
        love.graphics.setColor(0.2, 0.4, 1, 1) -- Mana Blue Background
        love.graphics.rectangle('fill', self.x + ox, self.y, w, 1)
        
        love.graphics.setColor(0.4, 0.8, 1, 1) -- Mana Blue Foreground
        love.graphics.rectangle('fill', self.x + ox, self.y, w * manaPercent, 1)
    end
end

return Entity
