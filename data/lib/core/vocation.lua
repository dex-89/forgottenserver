function Vocation:getBase()
	local base = self
	while base:getDemotion() do
		base = base:getDemotion()
	end
	return base
end
