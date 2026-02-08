local Hero = Entity:extend()

function Hero:new(x, y, width, height, classType, level)
    -- Load base stats from class
    local classDef = HeroClasses[classType] or HeroClasses['KNIGHT']
    
    Hero.super.new(self, x, y, width, height, classDef.color)
    
    self.type = 'hero'
    self.classType = classType
    self.level = level or 1
    
    -- Scale stats
    self.hp = 100 * classDef.hpMult + (self.level - 1) * 20
    self.maxHp = self.hp
    self.damage = classDef.damage + (self.level - 1) * 2 -- Projectiles will use this damage
    self.speed = classDef.speed
    self.attackRange = classDef.range
    self.attackRate = classDef.attackRate
    self.behavior = classDef.behavior
    self.healAmount = classDef.healAmount or 10
    
    self.projectileSpeed = classDef.projectileSpeed
    self.projectileType = classDef.projectileType
    
    self.enchanted = false
    self.isHero = true
    
    -- Animation state
    self.animTimer = 0
    self.animState = 'WALK'
    self.attackAnimTimer = 0
    self.attackAnimTimer = 0
    self.hasDealtDamage = false
    
    self.attackVariant = 1
    self.lockedAnimTimer = 0
    self.lockedAnim = nil
end

function Hero:takeDamage(amount, playState, attacker, color)
    Hero.super.takeDamage(self, amount, playState, attacker, color)
    
    -- Only guard if not already in a locked animation (like attacking)
    if self.lockedAnimTimer <= 0 then
        self.lockedAnim = 'GUARD'
        self.lockedAnimTimer = 0.6 -- Guard duration
        self.animTimer = 0 -- Reset animation frame
    end
end

function Hero:update(dt, playState)
    Hero.super.update(self, dt)
    self.animTimer = self.animTimer + dt
    
    -- Update Timers
    if self.attackAnimTimer > 0 then self.attackAnimTimer = self.attackAnimTimer - dt end
    if self.lockedAnimTimer > 0 then self.lockedAnimTimer = self.lockedAnimTimer - dt end
    
    -- Determine Animation State
    if self.lockedAnimTimer > 0 then
        self.animState = self.lockedAnim
    elseif self.state == 'ATTACK' then
        self.animState = 'IDLE'
    else
        self.animState = 'WALK'
    end

    if self.state == 'WALK' then
        -- Stop moving if guarding/hurt
        if self.enchanted then
            self.x = self.x + self.speed * dt
        else
            self.x = self.x - self.speed * dt
        end
    elseif self.state == 'ATTACK' then
        -- Stop attacking cooldown if guarding/hurt
        self.attackTimer = self.attackTimer + dt
            
            -- Handle Mid-Animation Damage
            if self.attackAnimTimer > 0 and not self.hasDealtDamage then
                -- Trigger damage at ~50% of animation (animation is 0.4s, so at 0.2s left)
                if self.attackAnimTimer <= 0.2 then
                    self.hasDealtDamage = true
                    if self.target and not self.target.dead then
                        if self.behavior == 'SUPPORT' and self.target.type == self.type then
                             -- Heal Logic
                             self.target.hp = math.min(self.target.maxHp, self.target.hp + self.healAmount)
                             gParticleManager:spawnHealEffect(self.target.x + self.target.width/2, self.target.y + self.target.height/2)
                             
                        elseif self.behavior == 'RANGED' then
                             -- Shoot Projectile
                             if playState then
                                 local spawnOffset = self.enchanted and self.width + 6 or -6
                                 local speed = self.enchanted and math.abs(self.projectileSpeed) or -math.abs(self.projectileSpeed)
                                 
                                 local p = Projectile(
                                     self.x + spawnOffset,
                                     self.y + self.height/2 - 3,
                                     nil, -- No specific target for linear
                                     self.damage,
                                     speed,
                                     self.type, -- Team (can be 'hero' or 'demon')
                                     self.color, -- Projectile color matches hero
                                     self
                                 )
                                 table.insert(playState.projectiles, p)
                             end
                             
                        else -- MELEE / SUPPORT Attack
                            self.target:takeDamage(self.damage, playState, self)
                        end
                    end
                end
            end
            
            -- Start New Attack Logic
            if self.attackAnimTimer <= 0 then -- Only start new attack if previous anim done
                if self.attackTimer >= self.attackRate then
                    -- Check Target Validity
                    if self.target and not self.target.dead then
                        -- Check Range for Ranged units? (Handled in PlayState for state switching, but good to double check)
                         if self.lockedAnimTimer <= 0 then -- Only attack if not locked (e.g. recovering from hit or prev attack)
                             self.attackTimer = 0
                             self.attackAnimTimer = 0.4 -- Used for logic/timing events
                             
                             -- Lock Animation
                             self.lockedAnim = 'ATTACK' .. self.attackVariant
                             self.lockedAnimTimer = 0.4 
                             self.animTimer = 0 -- Reset animation frame 
                             
                             self.hasDealtDamage = false -- Reset damage flag
                             -- Toggle Variant
                             self.attackVariant = self.attackVariant == 1 and 2 or 1
                         end
                    else
                         -- Target dead/gone
                         self.state = 'WALK'
                         self.target = nil
                    end
                end
            end
    end
end

function Hero:render()
    gHeroSpriteManager:draw(self)
    self:renderHealthBar()
end

function Hero:enchant()
    if self.enchanted then return end
    self.enchanted = true
    self.type = 'demon' -- Switch team
    self.state = 'WALK' -- Reset state
    self.target = nil -- Clear old targets
    self.originalCost = 0 -- Enchanted heroes have no refund cost
    self.color = {0.7, 0.3, 0.9, 1} -- Violet/Purple tint
    
    -- Spawn some particles
    if gParticleManager then
        gParticleManager:spawnPortalEffect(self.x + self.width/2, self.y + self.height/2)
    end
end



return Hero
