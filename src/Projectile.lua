local Projectile = Class:extend()

function Projectile:new(x, y, target, damage, speed, team, color, source)
    self.x = x
    self.y = y
    self.width = 6
    self.height = 6
    
    self.target = target -- Optional specific target
    self.damage = damage
    self.speed = speed or 100 -- Positive = Right, Negative = Left
    self.team = team or 'demon' -- 'demon' or 'hero'
    self.color = color or {1, 0.5, 0, 1}
    self.source = source
    
    self.dead = false
end

function Projectile:update(dt)
    if self.dead then return end
    
    self.x = self.x + self.speed * dt
    
    -- Check if out of bounds
    if self.x > VIRTUAL_WIDTH + 50 or self.x < -50 then
        self.dead = true
    end
end

function Projectile:render()
    love.graphics.setColor(unpack(self.color))
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
    
    -- Border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
    
    love.graphics.setColor(1, 1, 1, 1)
end

return Projectile
