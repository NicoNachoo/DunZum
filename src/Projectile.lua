local Projectile = Class:extend()
Projectile.textureCache = {}

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
    
    -- Animation State
    self.state = 'TRAVEL' -- 'TRAVEL', 'EXPLODE'
    self.timer = 0
    self.currentFrame = 1
    
    -- If config has TRAVEL/EXPLODE structure, use it. Otherwise fallback (legacy support or other units)
    if self.projectileConfig and self.projectileConfig['TRAVEL'] then
        self.animConfig = self.projectileConfig['TRAVEL']
        self.isAnimated = true
    else
        self.animConfig = self.projectileConfig
        self.isAnimated = false
    end

    self.dead = false
    self.remove = false -- separate dead (logic) from remove (cleanup) for explosion delay
end

function Projectile:update(dt)
    if self.remove then return end
    
    if self.state == 'TRAVEL' then
        self.x = self.x + self.speed * dt
        
        -- Check if out of bounds
        if self.x > VIRTUAL_WIDTH + 50 or self.x < -50 then
            self.remove = true
            self.dead = true
        end
    elseif self.state == 'EXPLODE' then
        -- Stay in place, just animate
        if self.currentFrame == self.animConfig.frames then
            -- Check if animation finished (this is a simplified check, 
            -- ideally check timer > duration of last frame)
             if self.timer > self.animConfig.duration then
                 self.remove = true
             end
        end
    end
    
    -- Animation Logic
    if self.isAnimated and self.animConfig then
        self.timer = self.timer + dt
        if self.timer > self.animConfig.duration then
            self.timer = self.timer - self.animConfig.duration
            self.currentFrame = self.currentFrame + 1
            
            if self.currentFrame > self.animConfig.frames then
                if self.state == 'EXPLODE' then
                    self.remove = true
                    self.currentFrame = self.animConfig.frames -- Hold last frame just in case
                else
                    self.currentFrame = 1 -- Loop travel animation
                end
            end
        end
    end
end

function Projectile:explode()
    if self.state == 'EXPLODE' then return end
    
    if self.projectileConfig and self.projectileConfig['EXPLODE'] then
        self.state = 'EXPLODE'
        self.animConfig = self.projectileConfig['EXPLODE']
        self.currentFrame = 1
        self.timer = 0
        self.dead = true -- Stop logic collisions
        -- Centering the explosion might be needed if sizes differ significantly, 
        -- but keeping top-left same is usually safer for visual continuity unless offsets are provided.
    else
        self.dead = true
        self.remove = true
    end
end

function Projectile:render()
    if self.remove then return end

    if self.animConfig and self.animConfig.texture then
        local path = self.animConfig.texture
        
        -- Cache texture
        if not Projectile.textureCache[path] then
             if love.filesystem.getInfo(path) then
                 Projectile.textureCache[path] = love.graphics.newImage(path)
             else
                 print("Projectile: Could not find texture at " .. path)
                 return
             end
        end
        
        local texture = Projectile.textureCache[path]
        
        if texture then
            local baseScale = self.animConfig.scale or 1
            local scaleX = self.speed < 0 and -baseScale or baseScale
            local scaleY = baseScale
            
            -- Assume horizontal strip for animation
            local frameWidth = texture:getWidth() / (self.animConfig.frames or 1)
            local frameHeight = texture:getHeight()
            
            -- Create Quad if strict optimization needed, but dynamic calc is okay for low count
            local quad = love.graphics.newQuad(
                (self.currentFrame - 1) * frameWidth, 0,
                frameWidth, frameHeight,
                texture:getDimensions()
            )
            
            -- Center origin (approximate based on frame size)
            local ox = frameWidth / 2
            local oy = frameHeight / 2

            love.graphics.setColor(1, 1, 1, 1) 
            love.graphics.draw(texture, quad, self.x + self.width/2, self.y + self.height/2, 0, scaleX, scaleY, ox, oy)
            return
        end
    end

    -- Fallback rectangle
    love.graphics.setColor(unpack(self.color))
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
    
    -- Border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
    
    love.graphics.setColor(1, 1, 1, 1)
end

return Projectile
