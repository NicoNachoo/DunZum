local BaseState = Class:extend()

function BaseState:new() end
function BaseState:enter() end
function BaseState:exit() end
function BaseState:update(dt) end
function BaseState:textinput(t) end
function BaseState:keypressed(key) end
function BaseState:render() end
function BaseState:renderUI() end

function BaseState:drawPentagram(x, y, radius, rotation)
    local points = {}
    local starOrder = {1, 3, 5, 2, 4}
    
    for i = 1, 5 do
        local angle = (i - 1) * (2 * math.pi / 5) + rotation
        table.insert(points, x + math.cos(angle) * radius)
        table.insert(points, y + math.sin(angle) * radius)
    end
    
    love.graphics.setLineWidth(2)
    for i = 1, #starOrder do
        local p1Idx = starOrder[i]
        local p2Idx = starOrder[i % 5 + 1]
        love.graphics.line(
            points[(p1Idx-1)*2 + 1], points[(p1Idx-1)*2 + 2],
            points[(p2Idx-1)*2 + 1], points[(p2Idx-1)*2 + 2]
        )
    end
    
    love.graphics.circle('line', x, y, radius + 2)
    love.graphics.setLineWidth(1)
end

return BaseState
