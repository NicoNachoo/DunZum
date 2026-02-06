local InputManager = {}

function InputManager:wasPressed(action)
    if action == 'up' then
        return love.keyboard.wasPressed('w') or love.keyboard.wasPressed('up')
    elseif action == 'down' then
        return love.keyboard.wasPressed('s') or love.keyboard.wasPressed('down')
    elseif action == 'left' then
        return love.keyboard.wasPressed('a') or love.keyboard.wasPressed('left')
    elseif action == 'right' then
        return love.keyboard.wasPressed('d') or love.keyboard.wasPressed('right')
    elseif action == 'confirm' then
        return love.keyboard.wasPressed('return') or love.keyboard.wasPressed('kpenter') or love.keyboard.wasPressed('space')
    elseif action == 'back' then
        return love.keyboard.wasPressed('escape')
    end
    return false
end

return InputManager
