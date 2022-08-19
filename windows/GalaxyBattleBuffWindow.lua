local BaseWindow = import(".BaseWindow")
local GalaxyBattleBuffWindow = class("GalaxyBattleBuffWindow", BaseWindow)
local GalaxyBattleBuffWindowItem = class("GalaxyBattleBuffWindowItem", import("app.components.CopyComponent"))

function GalaxyBattleBuffWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.skillIDs = params.skillIDs
	self.mapID = params.mapID
	self.items = {}
end

function GalaxyBattleBuffWindow:initWindow()
	self:getUIComponent()
	GalaxyBattleBuffWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function GalaxyBattleBuffWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupAction = groupAction
	self.labelTitle_ = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.labelLimit = self.groupAction:ComponentByName("labelLimit", typeof(UILabel))
	self.item = self.groupAction:NodeByName("item").gameObject
	self.itemGroup = self.groupAction:NodeByName("itemGroup").gameObject
	self.itemGroupLayout = self.groupAction:ComponentByName("itemGroup", typeof(UILayout))
end

function GalaxyBattleBuffWindow:initUIComponent()
	self.labelTitle_.text = __("GALAXY_TRIP_TEXT31")
	self.labelTitle.text = __("GALAXY_TRIP_TEXT40")
	local eventIDs = xyd.tables.galaxyTripEventTable:getIDsByMap(self.mapID)
	local limit = 0
	local helpArr = {}

	for i = 1, #eventIDs do
		local eventType = xyd.tables.galaxyTripEventTable:getType(eventIDs[i])

		if xyd.models.galaxyTrip:getIsBuff(eventType) then
			limit = limit + xyd.tables.galaxyTripEventTable:getAmount(eventIDs[i])
			local skillID = xyd.tables.galaxyTripEventTable:getSkillId(eventIDs[i])

			if skillID and not helpArr[skillID] then
				helpArr[skillID] = 1
			end
		end
	end

	local activeNum = 0
	local activeArr = {}

	for i = 1, #self.skillIDs do
		local skillID = self.skillIDs[i]

		if skillID and skillID > 0 and helpArr[skillID] then
			activeNum = activeNum + 1
			local effectID = xyd.tables.skillTable:getEffects(skillID)[1][1]
			local buff = xyd.tables.effectTable:getType(effectID)
			local buffValue = xyd.tables.effectTable:getNum(effectID)

			if not activeArr[buff] then
				activeArr[buff] = 0
			end

			activeArr[buff] = activeArr[buff] + buffValue
		end
	end

	self.labelLimit.text = "(" .. activeNum .. "/" .. limit .. ")"
	self.activeArr = {}

	for key, value in pairs(activeArr) do
		table.insert(self.activeArr, {
			key,
			value
		})
	end

	self:updateContent()
end

function GalaxyBattleBuffWindow:updateContent()
	for i = 1, #self.activeArr do
		local data = self.activeArr[i]

		if not self.items[i] then
			local itemObj = NGUITools.AddChild(self.itemGroup, self.item)
			local item = GalaxyBattleBuffWindowItem.new(itemObj)
			self.items[i] = item
		end

		self.items[i]:setInfo(data)
	end

	if #self.activeArr > 3 then
		self.bg.height = 320 + (#self.activeArr - 3) * 52
	end

	self.itemGroupLayout:Reposition()
end

function GalaxyBattleBuffWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.closeWindow(self.name_)
	end
end

function GalaxyBattleBuffWindow:willClose()
	BaseWindow.willClose(self)
end

function GalaxyBattleBuffWindowItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function GalaxyBattleBuffWindowItem:getUIComponent()
	self.img = self.go:ComponentByName("img", typeof(UISprite))
	self.labelBuff = self.go:ComponentByName("labelBuff", typeof(UILabel))
	self.labelValue = self.go:ComponentByName("labelValue", typeof(UILabel))
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
end

function GalaxyBattleBuffWindowItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	self.buff = params[1]
	self.buffValue = params[2]
	self.labelBuff.text = xyd.tables.dBuffTable:getDesc(self.buff)
	self.labelValue.text = xyd.tables.dBuffTable:getDesc(self.buff)
	local factor = xyd.tables.dBuffTable:getFactor(self.buff)

	if xyd.tables.dBuffTable:isPercent(self.buff) then
		self.labelValue.text = "+" .. string.format("%.1f", self.buffValue * 100) .. "%"
	elseif factor and factor > 0 then
		self.labelValue.text = "+" .. string.format("%.1f", self.buffValue * 100 / factor) .. "%"
	else
		self.labelValue.text = "+" .. self.buffValue
	end

	xyd.setUISpriteAsync(self.img, nil, xyd.tables.dBuffTable:getIcon1(self.buff))
end

return GalaxyBattleBuffWindow
