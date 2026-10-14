-- Pure elapsed-time ledger. Settle the previous rate BEFORE changing it.
local Income = {}
Income.__index = Income

function Income.new(now)
	return setmetatable({Pending = 0, Rate = 0, LastTime = now}, Income)
end

function Income:accrue(now)
	self.Pending += math.max(0, now - self.LastTime) * self.Rate
	self.LastTime = math.max(self.LastTime, now)
	return math.floor(self.Pending)
end

function Income:setRate(rate, now)
	self:accrue(now)
	self.Rate = rate
end

function Income:collect(now)
	local amount = self:accrue(now)
	self.Pending -= amount -- retain fractions rather than losing income on spam
	return amount
end

return Income
