local FloatingNumber = Class:extend()

function FloatingNumber:new(x, y, text, color)
    self.x = x
    self.y = y
    self.text = text
    self.color = color or {1, 1, 1, 1}
    self.timer = 0
    self.duration = 1.0
    self.dead = false
    self.vx = love.math.random(-20, 20) -- Horizontal arc
    self.vy = -80 -- Initial jump up
    self.gravity = 150 -- Pull down
end

function FloatingNumber:update(dt)
    self.timer = self.timer + dt
    self.vy = self.vy + self.gravity * dt
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    if self.timer >= self.duration then
        self.dead = true
    end
end

function FloatingNumber:render()
    local alpha = 1 - (self.timer / self.duration)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.setFont(gFonts['tiny'])
    love.graphics.printOutline(self.text, self.x, self.y)
    love.graphics.setColor(1, 1, 1, 1)
end

return FloatingNumber
