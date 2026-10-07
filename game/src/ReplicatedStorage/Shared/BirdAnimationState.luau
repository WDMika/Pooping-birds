-- Presentation only: movement, damage, rewards and action acceptance remain authoritative elsewhere.
local State = {}
State.__index = State
function State.new()
	return setmetatable({State = nil, Age = 0, Grounded = nil, GroundAge = 0, Action = nil, ActionRemaining = 0}, State)
end
function State:Signal(name, duration)
	self.Action = name; self.ActionRemaining = duration
end
function State:Update(dt, input)
	dt = math.clamp(dt, 0, 0.1)
	self.Age += dt
	self.ActionRemaining = math.max(0, self.ActionRemaining - dt)
	if self.ActionRemaining == 0 then self.Action = nil end
	local grounded = input.Grounded == true
	if self.Grounded == nil then self.Grounded = grounded end
	if grounded ~= self.Grounded then self.GroundAge += dt else self.GroundAge = 0 end
	local edge
	if self.GroundAge >= 0.1 then self.Grounded = grounded; self.GroundAge = 0; edge = grounded and "Land" or "TakeOff" end
	local nextState
	if input.Dead then nextState = "Death"
	elseif input.Stunned then nextState = "Stunned"
	elseif self.Action then nextState = self.Action
	elseif edge then nextState = edge
	elseif self.State == "TakeOff" and self.Age < 0.8 and not self.Grounded then nextState = "TakeOff"
	elseif self.State == "Land" and self.Age < 0.7 and self.Grounded then nextState = "Land"
	elseif self.Grounded then nextState = (input.Speed or 0) > 2 and "Walk" or "Idle"
	elseif (input.VerticalSpeed or 0) < -22 then nextState = "Dive"
	elseif input.Boost then nextState = "FastFly"
	elseif input.Flapping == false then nextState = "Glide"
	else nextState = "Fly" end
	if nextState ~= self.State then self.State = nextState; self.Age = 0 end
	return self.State, self.Age
end
return State
