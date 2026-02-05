local Demon = Entity:extend()
Demon.impSprite = love.graphics.newImage('imgs/imp.png')
Demon.impQuads = {}
local frameSize = 64
for i = 0, 3 do
    -- Row 3 (y=128) is walking right
    table.insert(Demon.impQuads, love.graphics.newQuad(i * frameSize, 128, frameSize, frameSize, Demon.impSprite:getDimensions()))
end

function Demon:new(x, y, width, height, color, speed, attackRange, originalCost, playState)
    Demon.super.new(self, x, y, width, height, color)
    self.originalCost = originalCost or 0
    self.speed = speed or 20
    self.type = 'demon'
    
    local hpBase = 50
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
    
    -- Animation state for Imp
    self.animationTimer = 0
    self.animationFrame = 1
    self.animationSpeed = 0.15
end

function Demon:update(dt, playState)
    Demon.super.update(self, dt)
    
    if self.state == 'WALK' then
        self.x = self.x + self.speed * dt
        
        -- Animation for Imp
        if self.demonType == 'IMP' then
            self.animationTimer = self.animationTimer + dt
            if self.animationTimer >= self.animationSpeed then
                self.animationTimer = 0
                self.animationFrame = (self.animationFrame % #Demon.impQuads) + 1
            end
        end
    elseif self.state == 'ATTACK' then
        if self.attackCooldownTimer > 0 then
            self.attackCooldownTimer = self.attackCooldownTimer - dt
            return
        end

        if self.target and not self.target.dead then
            if self.demonType == 'IMP' then
                -- Imp Charge Logic
                self.chargeTimer = self.chargeTimer + dt
                
                -- Spawn charge particles (Throttled)
                self.particleTimer = self.particleTimer + dt
                if self.particleTimer >= 0.15 then -- Spawn every 0.15s
                    self.particleTimer = 0
                    if gParticleManager then
                        gParticleManager:spawnChargeEffect(self.x + self.width/2, self.y + self.height/2, self.color)
                    end
                end

                if self.chargeTimer >= self.chargeDuration then
                    self.chargeTimer = 0
                    self:fireProjectile(playState)
                    self.attackCooldownTimer = 2.0 -- 2 second cooldown
                end
            else
                -- Normal Attack logic
                self.attackTimer = self.attackTimer + dt
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
            self.attackTimer = 0
            -- Don't reset cooldown here, it persists
        end
    end
end

function Demon:fireProjectile(playState)
    if playState and self.target then
        local direction = 1
        if self.target.x < self.x then
            direction = -1
        end
        
        local p = Projectile(
            self.x + self.width/2, 
            self.y + self.height/2 - 3, 
            self.target, 
            self.damage, 
            150 * direction, -- speed
            'demon',
            nil,
            self
        )
        table.insert(playState.projectiles, p)
    end
end

function Demon:takeDamage(amount, playState, attacker)
    if self.demonType == 'VOIDWALKER' then
        local reduction = playState and playState.voidwalkerArmor or 0.5
        local finalDamage = amount * reduction
        -- Voidwalker takes reduced damage
        Demon.super.takeDamage(self, finalDamage, playState, attacker, {0.5, 0.5, 1, 1}) -- Blueish numbers for reduction
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
        love.graphics.setColor(0.2, 0.2, 1, 0.3)
        love.graphics.circle('fill', self.x + self.width/2, self.y + self.height/2, self.width/2 + 4)
        love.graphics.setColor(0.4, 0.4, 1, 0.6)
        love.graphics.setLineWidth(2)
        love.graphics.circle('line', self.x + self.width/2, self.y + self.height/2, self.width/2 + 4)
        love.graphics.setLineWidth(1)
    end

    if self.demonType == 'IMP' and not self.dead then
        love.graphics.setColor(1, 1, 1, 1)
        -- Draw the imp sprite. It's 64x64, we need to scale it to fit width/height
        local scale = self.width / 64
        love.graphics.draw(Demon.impSprite, Demon.impQuads[self.animationFrame], self.x, self.y, 0, scale, scale)
        
        -- Draw HP Bar for Imp (Smaller and centered: 16px wide, 4px offset)
        self:renderHealthBar(16, 4)
    else
        Demon.super.render(self)
    end
end

return Demon
