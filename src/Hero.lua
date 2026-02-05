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
end

function Hero:update(dt, playState)
    Hero.super.update(self, dt)
    
    if self.state == 'WALK' then
        if self.enchanted then
            self.x = self.x + self.speed * dt
        else
            self.x = self.x - self.speed * dt
        end
    elseif self.state == 'ATTACK' then
        self.attackTimer = self.attackTimer + dt
        
        -- Behavior Logic
        if self.behavior == 'SUPPORT' then
             if self.attackTimer >= self.attackRate then
                 if self.target and not self.target.dead then
                    self.attackTimer = 0
                    
                    if self.target.type == self.type then
                         -- Heal Logic
                         self.target.hp = math.min(self.target.maxHp, self.target.hp + self.healAmount)
                         gParticleManager:spawnHealEffect(self.target.x + self.target.width/2, self.target.y + self.target.height/2)
                    else
                        -- Attack Logic (Self Defense)
                        self.target:takeDamage(self.damage, playState, self)
                    end
                 end
             end
             
             -- If target is full HP or dead, resume walking?
             if not self.target or self.target.dead or self.target.hp >= self.target.maxHp then
                 self.target = nil
                 self.state = 'WALK'
             end
             
        elseif self.behavior == 'RANGED' then
            if self.attackTimer >= self.attackRate then
                 self.attackTimer = 0
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
            end
            
             -- If no enemies in range (logic handled in PlayState), verify if we should still stop?
             -- PlayState sets state to ATTACK if enemy in range.
             -- If enemy dies, PlayState sets to WALK.
             
        else -- MELEE
             if self.target and not self.target.dead then
                if self.attackTimer >= self.attackRate then
                    self.attackTimer = 0
                    self.target:takeDamage(self.damage, playState, self)
                end
             else
                self.state = 'WALK'
                 self.target = nil
             end
        end
    end
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
