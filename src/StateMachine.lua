local StateMachine = Class:extend()

function StateMachine:new(states)
	self.empty = {
		render = function() end,
		renderUI = function() end,
		update = function() end,
		enter = function() end,
		exit = function() end,
		textinput = function() end,
		keypressed = function() end
	}
	self.states = states or {} -- [name] -> [function that returns states]
	self.stack = { self.empty }
end

function StateMachine:change(stateName, enterParams)
	assert(self.states[stateName]) -- state must exist!
	self.stack[#self.stack]:exit()
	self.stack = { self.states[stateName]() }
	self.stack[#self.stack]:enter(enterParams)
end

function StateMachine:push(stateName, enterParams)
	assert(self.states[stateName])
	local state = self.states[stateName]()
	table.insert(self.stack, state)
	state:enter(enterParams)
end

function StateMachine:pop()
	if #self.stack > 1 then
		self.stack[#self.stack]:exit()
		table.remove(self.stack)
	end
end

function StateMachine:getCurrent()
	return self.stack[#self.stack]
end

function StateMachine:update(dt)
	self:getCurrent():update(dt)
end

function StateMachine:textinput(t)
    self:getCurrent():textinput(t)
end

function StateMachine:keypressed(key)
    self:getCurrent():keypressed(key)
end

function StateMachine:render()
	-- Render all states in the stack (bottom to top)
	-- This allows background states to stay visible (e.g. game visible while paused)
	for i = 1, #self.stack do
		self.stack[i]:render()
	end
end

function StateMachine:renderUI()
	local current = self:getCurrent()
	if current.renderUI then
		current:renderUI()
	end
end

return StateMachine
