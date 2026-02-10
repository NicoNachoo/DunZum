local Demon = Entity:extend()
Demon.sheets = {}
Demon.quads = {}

if DEMON_ANIMATIONS then
    for type, anims in pairs(DEMON_ANIMATIONS) do
        Demon.sheets[type] = {}
        Demon.quads[type] = {}
        
        for state, config in pairs(anims) do
            if config.frames then
                 -- Setup generic loading
                 local imgPath = config.texture
                 if love.filesystem.getInfo(imgPath) then
                     local img = love.graphics.newImage(imgPath)
                     Demon.sheets[type][state] = img
                     
                     Demon.quads[type][state] = {}
                     local fw = img:getWidth() / config.frames
                     local fh = img:getHeight()
                     for i = 0, config.frames - 1 do
                         table.insert(Demon.quads[type][state], love.graphics.newQuad(i * fw, 0, fw, fh, img:getDimensions())) 
                     end
                 else
                     print("Demon: Could not find texture at " .. imgPath)
                 end
            elseif state == 'PROJECTILE' then
                -- Load projectile texture just in case we need it cached, though Projectile class might handle it
            end
        end
    end
end

function Demon:new(x, y, width, height, color, speed, attackRange, originalCost, playState, demonType)
    Demon.super.new(self, x, y, width, height, color)
    self.originalCost = originalCost or 0
    self.speed = speed or 20
    self.type = 'demon'
    self.demonType = demonType -- Set early
    
    local hpBase = 50
    if demonType == 'IMP' then
        hpBase = 30 -- Reduced HP for Imp
    end
    
    local damageBase = 15
    
    if playState then
        self.hp = hpBase * playState.demonHpMult
        self.damage = damageBase * playState.demonDamageMult
    else
        self.hp = hpBase
        self.damage = damageBase
    end
    
    self.maxHp = self.hp
    self.attackRange = attackRange or 10 -- Dynamic range
    self.attackRate = 1.0
    
    self.chargeTimer = 0
    self.chargeDuration = 1.2 -- Increased charge time for Imp
    self.particleTimer = 0
    self.attackCooldownTimer = 0
    
    self.animTimer = 0
    self.animState = 'IDLE' -- Default state
    
    -- Voidwalker Shield State
    -- Use MANA as SHIELD
    self.maxMana = 50 
    self.mana = self.maxMana
    self.isEnraged = false
end

function Demon:update(dt, playState)
    Demon.super.update(self, dt)
    

    
    if self.state == 'WALK' then
        self.x = self.x + self.speed * dt
        
        -- Generic Animation Update
        self.animState = 'WALK'
        self.animTimer = self.animTimer + dt
    elseif self.state == 'ATTACK' then
        if self.attackCooldownTimer > 0 then
            self.attackCooldownTimer = self.attackCooldownTimer - dt
            -- Fall through to animation update
        else
            if self.target and not self.target.dead then
                if self.demonType == 'IMP' then
                    -- Imp Charge Logic
                    self.chargeTimer = self.chargeTimer + dt
                    
                    -- Calculate duration based on animation frames
                    local animConfig = DEMON_ANIMATIONS['IMP']['ATTACK']
                    local animDuration = animConfig.frames * animConfig.duration
                    
                    -- Spawn charge particles (Throttled)
                    self.particleTimer = self.particleTimer + dt
                    if self.particleTimer >= 0.15 then -- Spawn every 0.15s
                        self.particleTimer = 0
                        if gParticleManager then
                            gParticleManager:spawnChargeEffect(self.x + self.width/2, self.y + self.height/2, self.color)
                        end
                    end

                    if self.chargeTimer >= animDuration then
                        self.chargeTimer = 0
                        self:fireProjectile(playState)
                        self.attackCooldownTimer = 2.0 -- 2 second cooldown
                    end
                else
                    -- Normal Attack logic
                    if self.attackTimer >= self.attackRate then
                        self.attackTimer = 0
                        if self.attackRange > 20 then
                            self:fireProjectile(playState)
                        else
                        self.target:takeDamage(self.damage, playState, self)
                        end
                    end
                end
            else
                -- Target dead or gone, resume walking
                self.state = 'WALK'
                self.target = nil
                self.chargeTimer = 0
                -- Don't reset cooldown here, it persists
            end
        end
    end
    
    -- Update State Logic
    if self.state == 'ATTACK' then
         if self.demonType == 'IMP' and self.attackCooldownTimer > 0 then
             self.animState = 'IDLE'
         else
             self.animState = 'ATTACK'
         end
         self.animTimer = self.animTimer + dt
    elseif self.state == 'IDLE' then -- If there was an IDLE state in update logic
         self.animState = 'IDLE'
         self.animTimer = self.animTimer + dt
    end
    
    -- Rage Particles
    if self.demonType == 'VOIDWALKER' and self.isEnraged then
        if gParticleManager then
            if math.random() < (60 * dt) then -- Increased spawn rate for dense effect
                 local rx = self.x + math.random(0, self.width)
                 local ry = self.y + math.random(0, self.height)
                 gParticleManager:spawnRageParticles(rx, ry)
            end
        end
    end
end

function Demon:fireProjectile(playState)
    if playState and self.target then
        local direction = 1
        if self.target.x < self.x then
            direction = -1
        end
        
        local projectileConfig = nil
        if DEMON_ANIMATIONS[self.demonType] and DEMON_ANIMATIONS[self.demonType]['PROJECTILE'] then
            projectileConfig = DEMON_ANIMATIONS[self.demonType]['PROJECTILE']
        end
        
        local spawnY = self.y + self.height/2
        if self.demonType == 'IMP' then
            spawnY = spawnY - 5 -- Adjust up to center
        end

        local p = Projectile(
            self.x + self.width/2, 
            spawnY, 
            self.target, 
            self.damage, 
            150 * direction, -- speed
            'demon',
            nil,
            self,
            projectileConfig
        )
        table.insert(playState.projectiles, p)
    end
end

function Demon:takeDamage(amount, playState, attacker)
    if self.demonType == 'VOIDWALKER' then
        if self.mana > 0 then
            -- Shield takes damage
            self.mana = self.mana - amount
            
            -- Check for Rage Trigger
            if self.mana <= 0 then
                self.mana = 0
                self.isEnraged = true
                self.damage = self.damage * 1.5 -- Rage Damage Buff
                self.attackRate = self.attackRate * 0.5 -- Rage Attack Speed Buff (Lower is faster)
                
                if gParticleManager then
                    gParticleManager:spawnPoof(self.x + self.width/2, self.y + self.height/2) -- Rage explosion?
                end
            end
            
            -- Floating Text for Shield Damage (Blue)
             table.insert(playState.floatingNumbers, FloatingNumber(self.x, self.y, "-" .. math.ceil(amount), {0.2, 0.5, 1, 1}))
        else
            -- No shield, take health damage
            Demon.super.takeDamage(self, amount, playState, attacker)
        end
    elseif self.demonType == 'SUCCUBUS' then
        -- Succubus disappearance and enchantment logic
        if attacker and attacker.type == 'hero' and attacker.enchant then
            attacker:enchant()
        end
        -- Disappear
        self.hp = 0
        self.dead = true
        if gParticleManager then
            gParticleManager:spawnPortalEffect(self.x + self.width/2, self.y + self.height/2)
        end
    else
        Demon.super.takeDamage(self, amount, playState, attacker)
    end
end
function Demon:render()
    -- Draw Shield for Voidwalker
    if self.demonType == 'VOIDWALKER' and not self.dead then
        if self.mana > 0 then
            love.graphics.setColor(0.2, 0.2, 1, 0.3 + (self.mana/self.maxMana) * 0.3)
            love.graphics.circle('fill', self.x + self.width/2, self.y + self.height/2, self.width/2 + 6)
            love.graphics.setColor(0.4, 0.4, 1, 0.8)
            love.graphics.setLineWidth(2)
            love.graphics.circle('line', self.x + self.width/2, self.y + self.height/2, self.width/2 + 6)
            love.graphics.setLineWidth(1)
        end
    end

    if DEMON_ANIMATIONS[self.demonType] and not self.dead then
         love.graphics.setColor(1, 1, 1, 1)
         
         local animState = self.animState
         -- Check if animation exists, fallback to IDLE or WALK if ATTACK missing
         if not Demon.sheets[self.demonType][animState] then
             animState = 'IDLE'
         end
         
         if Demon.sheets[self.demonType][animState] then
             local img = Demon.sheets[self.demonType][animState]
             local quads = Demon.quads[self.demonType][animState]
             local config = DEMON_ANIMATIONS[self.demonType][animState]
             
             local totalDuration = config.duration * config.frames
             local currentTime = self.animTimer % totalDuration
             local frameIndex = math.floor(currentTime / config.duration) + 1
             
             local quad = quads[frameIndex]
             if not quad then quad = quads[1] end
             
             local _, _, w, h = quad:getViewport()
             
             -- Scale and Direction
             local scale = config.scale or 1
             local scaleX = scale
             if self.demonType == 'IMP' then -- Assume Imp sprites face Right
                 -- If moving Left (standard for demons), flip?
                 -- Demons move Left (positiveSpeed moves x + speed * dt... wait)
                 -- Demon:update: self.x = self.x + self.speed * dt
                 -- Wait, demons move RIGHT towards Castle? Or LEFT?
                 -- Constants: HERO_SPAWN_RATE...
                 -- Let's check Demon.lua walk logic: self.x = self.x + self.speed * dt.
                 -- If speed is positive, they move RIGHT.
                 -- Where is the castle?
                 -- TutorialState usually implies Left -> Right or Right -> Left.
                 -- Constants: WINDOW_WIDTH = 1280.
                 -- Grimoire assumes you are the Demon Lord?
                 -- "Restore one heart to your CASTLE".
                 -- Usually Enemies spawn right and move left.
                 -- Demon.lua: self.x = self.x + self.speed * dt. 
                 -- If speed is positive, they move Right.
                 -- Let's check Hero.lua: self.x = self.x - self.speed * dt (if not enchanted).
                 -- So Heroes move LEFT.
                 -- Demons move RIGHT.
                 -- So if Imp sprites face Right (Run, Idle), then ScaleX should be positive.
             end
             
             local drawX = self.x + self.width/2
             local yOffset = 0
             if self.demonType == 'IMP' then
                 yOffset = 10 -- Small offset to align feet with shadow/lane
             end
             
             local drawY = (self.y + self.height) + yOffset
             
             -- Center sprite horizontally on hitbox
             -- Anchor point: Bottom Center of sprite (w/2, h)
             
                         -- Outline
             love.graphics.setShader(Shaders.SolidColor)
             Shaders.SolidColor:send('color', {0.2, 0.2, 0.2, 1}) -- Black outline
             
             local offsets = {
                 {x = -0.3, y = 0}, {x = 0.3, y = 0},
                 {x = 0, y = -0.3}, {x = 0, y = 0.3}
             }
             
             for _, off in ipairs(offsets) do
                 love.graphics.draw(img, quad, drawX + off.x, drawY + off.y, 0, scaleX, scale, w/2, h)
             end
             
             love.graphics.setShader()

             love.graphics.draw(img, quad, drawX, drawY, 0, scaleX, scale, w/2, h)
             
             -- Floating UI
             self:renderHealthBar(self.width, 0)
             if self.maxMana > 0 then
                self:renderManaBar(self.width, 0, 4) -- Offset Y by 4 to be below HP bar
             end
         else
             -- Fallback if animation missing
             Demon.super.render(self)
         end
    else
        Demon.super.render(self)
    end
end

return Demon
