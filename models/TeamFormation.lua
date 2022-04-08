local TeamFormation = class("TeamFormation")

function TeamFormation:ctor(info)
	self.partner_id = info.partner_id
	self.pos = info.pos
end

return TeamFormation
