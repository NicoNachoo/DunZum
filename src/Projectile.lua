local Projectile = Class:extend()

function Projectile:new(x, y, target, damage, speed, team, color, source, projectileConfig)
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
    self.projectileConfig = projectileConfig
    
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

    if self.projectileConfig and self.projectileConfig.texture then
        -- Lazy load image if not already loaded (or assume it's a path string)
        -- To avoid loading every frame, we should ideally cache it or load it in :new or use a resource manager.
        -- For now, let's use a cached image if possible, or just love.graphics.newImage (bad for performance but simple).
        -- BETTER: Check if it's already an Image object, if not load it and store it back? 
        -- Or rely on a global cache. Constants has 'imgs/...".
        -- Let's implement a simple static cache here or use the path.
        -- Actually, ParticleManager loads images. We could use a similar approach or just load once.
        -- Let's try to just use love.graphics.newImage but CACHED in a local table.
        
        if not self.image then
            self.image = love.graphics.newImage(self.projectileConfig.texture)
        end
        
        local texture = self.image
        
        -- Determine direction
        local baseScale = self.projectileConfig.scale or 1
        local scaleX = self.speed < 0 and -baseScale or baseScale
        local scaleY = baseScale
        
        -- Center the origin
        local ox = texture:getWidth() / 2
        local oy = texture:getHeight() / 2

        love.graphics.setColor(1, 1, 1, 1) 
        love.graphics.draw(texture, self.x + self.width/2, self.y + self.height/2, 0, scaleX, scaleY, ox, oy)
    else
        love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
        
        -- Border
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

return Projectile
