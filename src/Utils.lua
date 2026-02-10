-- Utility functions

function DrawPentagram(x, y, radius, rotation)
    local vertices = {}
    for i = 0, 4 do
        -- Outer points (tips of the star)
        local angle = rotation + (i * math.pi * 2 / 5) - (math.pi / 2)
        table.insert(vertices, x + math.cos(angle) * radius)
        table.insert(vertices, y + math.sin(angle) * radius)
        
        -- Inner points (indentations) -> optimized for pentagram shape
        local innerAngle = angle + (math.pi / 5)
        local innerRadius = radius * 0.4 -- Standard pentagram ratio
        table.insert(vertices, x + math.cos(innerAngle) * innerRadius)
        table.insert(vertices, y + math.sin(innerAngle) * innerRadius)
    end
    
    -- Draw the polygon filled
    love.graphics.polygon('fill', vertices)
    
    -- Optional: Draw outline for better visibility
    love.graphics.setLineWidth(2)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(r*1.2, g*1.2, b*1.2, a) -- Lighter outline
    love.graphics.polygon('line', vertices)
    love.graphics.setColor(r, g, b, a) -- Reset color
    love.graphics.setLineWidth(1)
end

function DrawPentagramLine(x, y, radius, rotation)
    -- Draws the classic 5-pointed star lines (interconnected)
    local points = {}
    for i = 0, 4 do
        local angle = rotation + (i * math.pi * 2 / 5) - (math.pi / 2)
        table.insert(points, {x = x + math.cos(angle) * radius, y = y + math.sin(angle) * radius})
    end
    
    -- Connect every second point: 1-3-5-2-4-1
    local connectionOrder = {1, 3, 5, 2, 4, 1}
    for i = 1, 5 do
        local p1 = points[connectionOrder[i]]
        local p2 = points[connectionOrder[i+1]]
        love.graphics.line(p1.x, p1.y, p2.x, p2.y)
    end
    
    -- Circle
    love.graphics.circle('line', x, y, radius)
end

function love.graphics.printfOutline(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
    local originalColor = {love.graphics.getColor()}
    local steps = 2
    local alpha = originalColor[4]
    
    love.graphics.setColor(0, 0, 0, alpha)
    for dx = -steps, steps, steps do
        for dy = -steps, steps, steps do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.printf(text, x + dx, y + dy, limit, align, r, sx, sy, ox, oy, kx, ky)
            end
        end
    end
    
    love.graphics.setColor(unpack(originalColor))
    love.graphics.printf(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
end

function love.graphics.printOutline(text, x, y, r, sx, sy, ox, oy, kx, ky)
    local originalColor = {love.graphics.getColor()}
    local steps = 2
    local alpha = originalColor[4]
    
    love.graphics.setColor(0, 0, 0, alpha)
    for dx = -steps, steps, steps do
        for dy = -steps, steps, steps do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.print(text, x + dx, y + dy, r, sx, sy, ox, oy, kx, ky)
            end
        end
    end
    
    love.graphics.setColor(unpack(originalColor))
    love.graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
end
