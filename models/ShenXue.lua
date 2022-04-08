local BaseModel = import(".BaseModel")
local ShenXueModel = class("ShenXueModel", BaseModel)

function ShenXueModel:ctor(...)
	self.forgeStatus = {}
	self.SlotModel = xyd.models.slot

	BaseModel.ctor(self)
end

function ShenXueModel:get()
	if ShenXueModel.INSTANCE == nil then
		ShenXueModel.INSTANCE = ShenXueModel.new()

		ShenXueModel.INSTANCE:onRegister()
	end

	return ShenXueModel.INSTANCE
end

function ShenXueModel:reset()
	if ShenXueModel.INSTANCE then
		ShenXueModel.INSTANCE:removeEvents()
	end

	ShenXueModel.INSTANCE = nil
end

function ShenXueModel:onRegister()
	BaseModel.onRegister(self)
	self:refreshForgeStatus()
	self:registerEvent(xyd.event.COMPOSE_PARTNER, handler(self, self.onComposePartner))
	self:registerEvent(xyd.event.PARTNER_ADD, handler(self, self.onSlotChange))
	self:registerEvent(xyd.event.PARTNER_DEL, handler(self, self.onSlotChange))
end

function ShenXueModel:onSlotChange(event)
	local params = event.data
	local partnerID = params.partnerID
	local tableID = params.tableID
	local groupId = xyd.tables.partnerTable:getGroup(tableID)

	self:refreshGroup(groupId)
end

function ShenXueModel:onComposePartner(event)
	local params = event.data
	local pInfo = params.partner_info
	local tableID = pInfo.table_id
	local groupId = xyd.tables.partnerTable:getGroup(tableID)

	self:refreshGroup(groupId)
end

function ShenXueModel:getStatusByTableID(tableID)
	local group = xyd.tables.partnerTable:getGroup(tableID)
	local status = self.forgeStatus[tostring(group)][tostring(tableID)]

	return status
end

function ShenXueModel:getForgeList()
	return self.forgeList
end

function ShenXueModel:refreshForgeStatus()
	self.SlotModel:refreshShenxueForgeStatus()

	self.forgeList = self.SlotModel.forgeList
	self.forgeStatus = self.SlotModel.forgeStatus
end

function ShenXueModel:refreshGroup(groupId)
	self.SlotModel:refreshShenxueGroup(groupId)
end

ShenXueModel.INSTANCE = nil

return ShenXueModel
