local HeroSpriteManager = {}

HeroSpriteManager.sheets = {}
HeroSpriteManager.quads = {}

function HeroSpriteManager:load()
    if not HERO_ANIMATIONS then return end

    for class, anims in pairs(HERO_ANIMATIONS) do
        self.sheets[class] = {}
        self.quads[class] = {}
        
        for state, config in pairs(anims) do
            -- Load Texture
            if love.filesystem.getInfo(config.texture) then
                local img = love.graphics.newImage(config.texture)
                self.sheets[class][state] = img
                
                -- Generate Quads
                local frameWidth = img:getWidth() / config.frames
                local frameHeight = img:getHeight()
                self.quads[class][state] = {}
                
                for i = 0, config.frames - 1 do
                    table.insert(self.quads[class][state], love.graphics.newQuad(
                        i * frameWidth, 0, frameWidth, frameHeight, img:getDimensions()
                    ))
                end
            else
                print("HeroSpriteManager: Could not find texture at " .. config.texture)
            end
        end
    end
end

function HeroSpriteManager:draw(hero)
    local class = hero.classType
    -- Use animState (granular) if available, fallback to state (logic)
    local state = hero.animState or hero.state 
    
    -- Fallback for missing animations
    if not self.sheets[class] or not self.sheets[class][state] then
        -- Render fallback rectangle
        love.graphics.setColor(hero.color)
        love.graphics.rectangle('fill', hero.x, hero.y, hero.width, hero.height)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle('line', hero.x, hero.y, hero.width, hero.height)
        return
    end

    local img = self.sheets[class][state]
    local quads = self.quads[class][state]
    local config = HERO_ANIMATIONS[class][state]
    
    -- Calculate Frame
    -- We use hero.animTimer which should be accumulated in Hero:update
    local totalDuration = config.duration * config.frames
    local currentTime = hero.animTimer % totalDuration
    local frameIndex = math.floor(currentTime / config.duration) + 1
    
    local quad = quads[frameIndex]
    
    -- Positioning
    -- Sprites might be larger than hitboxes. We center them at the bottom-center of the hitbox usually.
    -- Or just center-center?
    -- Let's assume the sprite acts as the visual representation of the hitbox.
    
    
    local _, _, w, h = quad:getViewport()
    
    -- Default scale is 1 if not specified
    local baseScale = config.scale or 1

    local scaleX = baseScale
    local scaleY = baseScale

    if hero.enchanted then
        -- Moving Right
        -- If sprite faces Right, scaleX is positive
        scaleX = baseScale
    else
        -- Moving Left
        -- If sprite faces Right, flip X
        scaleX = -baseScale
    end
    
    local drawX = hero.x + hero.width / 2
    
    -- Center vertically: Hitbox Center + Half Sprite Height 
    -- (Since Origin is Bottom-Center, DrawY is the visual bottom)
    -- Visual Bottom = Hitbox CenterY + (VisualHeight / 2)
    local drawY = (hero.y + hero.height / 2) + (h * scaleY / 2)
    
    -- HOWEVER, User said "sprite ... is facing the other direction".
    -- Let's assume standard behavior: Sprite faces Right.
    -- Code:
    -- x, y, r, sx, sy, ox, oy
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
    love.graphics.draw(img, quad, drawX, drawY, 0, scaleX, scaleY, w/2, h) 
    -- Origin w/2, h puts the anchor at Bottom-Center of the sprite.
    -- Drawing at drawX (Hitbox Center X), drawY (Hitbox Bottom Y).
end

return HeroSpriteManager
