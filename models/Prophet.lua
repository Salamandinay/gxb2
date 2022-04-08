local BaseModel = import(".BaseModel")
local Prophet = class("Prophet", BaseModel, true)

function Prophet:ctor()
	BaseModel.ctor(self)

	self.currentGroup_ = 1
	self.is10Times_ = false
end

function Prophet.____getters:is10Times()
	return self.is10Times_
end

function Prophet.____getters:currentGroup()
	return self.currentGroup_
end

function Prophet.____setters:is10Times(bool)
	self.is10Times_ = bool
end

function Prophet.____setters:currentGroup(val)
	self.currentGroup_ = val
end

function Prophet:get()
	if Prophet.INSTANCE == nil then
		Prophet.INSTANCE = Prophet.new()

		Prophet.INSTANCE:onRegister()
	end

	return Prophet.INSTANCE
end

function Prophet:reset()
	if Prophet.INSTANCE then
		Prophet.INSTANCE:removeEvents()
	end

	Prophet.INSTANCE = nil
end

function Prophet:onRegister()
	BaseModel.onRegister(self)
end

function Prophet:reqProphetSummon()
	local index = self.currentGroup_ + (self.is10Times_ and 5 or 0)
	local id = Prophet.SUMMONMID[index + 1]
	local msg = messages_pb:summon_req()
	msg.summon_id = id
	msg.times = 1

	xyd.Backend:get():request(xyd.mid.SUMMON, msg)
end

Prophet.SUMMONMID = {
	0,
	10,
	11,
	12,
	13,
	14,
	17,
	18,
	19,
	20,
	21
}

return Prophet
