local BaseWindow = import(".BaseWindow")
local DressShowBuffsDetailWindow = class("DressShowBuffsDetailWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local BaseComponent = import("app.components.BaseComponent")
local DressShowBuffItem = class("DressShowBuffItem", import("app.components.CopyComponent"))
local AdvanceIcon = import("app.components.AdvanceIcon")

function DressShowBuffsDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.dressShow
	self.funID = params.function_id
	self.buffTableID = params.buffTableID
	self.data = {}
end

function DressShowBuffsDetailWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.buffsGroup = self.groupAction:NodeByName("buffsGroup").gameObject
	self.buffsGroup_layout = self.groupAction:ComponentByName("buffsGroup", typeof(UILayout))
	self.buffItem = self.groupAction:NodeByName("buffItem").gameObject
	self.labelTitle = self.buffItem:ComponentByName("labelTitle", typeof(UILabel))
	self.line = self.buffItem:ComponentByName("line", typeof(UISprite))
	self.bg = self.buffItem:ComponentByName("bg", typeof(UISprite))
	self.labelDesc = self.buffItem:ComponentByName("labelDesc", typeof(UILabel))
	self.labelAwakeTime = self.buffItem:ComponentByName("labelAwakeTime", typeof(UILabel))
	self.labelLeftTips = self.buffItem:ComponentByName("labelLeftTips", typeof(UILabel))
	self.icon = self.buffItem:ComponentByName("icon", typeof(UISprite))
	self.labelNoAwakeTime = self.buffItem:ComponentByName("labelNoAwakeTime", typeof(UILabel))
end

function DressShowBuffsDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	self.data = {}

	if self.buffTableID then
		local id = self.buffTableID
		local times = self.activityData:getBuffs()[id].times
		local awakeTime = 0
		local left = {}

		if times then
			awakeTime = #times
			local min = {
				1000,
				1000
			}

			for j = 1, #times do
				if times[j] < min[2] then
					min = {
						1,
						times[j]
					}
				elseif times[j] == min[2] then
					min[1] = min[1] + 1
				end
			end

			left = min
		end

		local data = {
			title = xyd.tables.dressShowWindowShop1TableText:getName(id),
			desc = xyd.tables.dressShowWindowShop1TableText:getDesc2(id),
			left = left,
			awakeTime = awakeTime,
			icon = xyd.tables.functionTable:getIcon(xyd.tables.dressShowWindowShop1Table:getFunctionID(id)[1])
		}
		local tran = NGUITools.AddChild(self.buffsGroup.gameObject, self.buffItem)
		local item = DressShowBuffItem.new(tran, self)

		item:setInfo(data)
	elseif self.funID then
		local ids = xyd.tables.dressShowWindowShop1Table:getIDsByFunction(self.funID)

		table.sort(ids)

		local buffs = self.activityData:getBuffs()

		for i = 1, #ids do
			local id = tonumber(ids[i])
			local times = {}

			if buffs and buffs[id] and buffs[id].times then
				times = buffs[id].times
			end

			local awakeTime = 0
			local left = {}

			if times then
				awakeTime = #times
				local min = {
					1000,
					1000
				}

				for j = 1, #times do
					if times[j] < min[2] then
						min = {
							1,
							times[j]
						}
					elseif times[j] == min[2] then
						min[1] = min[1] + 1
					end
				end

				left = min
			end

			local data = {
				title = xyd.tables.dressShowWindowShop1TableText:getName(id),
				desc = xyd.tables.dressShowWindowShop1TableText:getDesc2(id),
				left = left,
				awakeTime = awakeTime,
				icon = xyd.tables.functionTable:getIcon(xyd.tables.dressShowWindowShop1Table:getFunctionID(id)[1])
			}
			local tran = NGUITools.AddChild(self.buffsGroup.gameObject, self.buffItem)
			local item = DressShowBuffItem.new(tran, self)

			item:setInfo(data)
		end
	else
		return
	end

	self:waitForFrame(3, function ()
		self.buffsGroup_layout:Reposition()
	end)
end

function DressShowBuffsDetailWindow:register()
end

function DressShowBuffItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	DressShowBuffItem.super.ctor(self, go)
	self:initUI()
end

function DressShowBuffItem:initUI()
	self:getUIComponent()
	self:register()
end

function DressShowBuffItem:getUIComponent()
	self.labelTitle = self.go:ComponentByName("labelTitle", typeof(UILabel))
	self.labelDesc = self.go:ComponentByName("labelDesc", typeof(UILabel))
	self.labelAwakeTime = self.go:ComponentByName("labelAwakeTime", typeof(UILabel))
	self.labelLeftTips = self.go:ComponentByName("labelLeftTips", typeof(UILabel))
	self.icon = self.go:ComponentByName("icon", typeof(UISprite))
	self.labelNoAwakeTime = self.go:ComponentByName("labelNoAwakeTime", typeof(UILabel))
end

function DressShowBuffItem:register()
end

function DressShowBuffItem:setInfo(params)
	if not params then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.data = params

	if xyd.Global.lang == "fr_fr" then
		self.labelDesc.width = 275
	end

	self.labelTitle.text = self.data.title
	self.labelDesc.text = self.data.desc
	self.labelAwakeTime.height = 22

	if not self.data.awakeTime or self.data.awakeTime <= 0 then
		self.labelNoAwakeTime:SetActive(true)
		self.labelAwakeTime:SetActive(false)
		self.labelLeftTips:SetActive(false)

		self.labelNoAwakeTime.text = __("SHOW_WINDOW_TEXT35")
	else
		self.labelNoAwakeTime:SetActive(false)
		self.labelAwakeTime:SetActive(true)
		self.labelLeftTips:SetActive(true)

		self.labelAwakeTime.text = __("SHOW_WINDOW_TEXT36", self.data.awakeTime)

		if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "en_en" then
			self.labelAwakeTime.height = 44
		end

		self.labelLeftTips.text = __("SHOW_WINDOW_TEXT37", self.data.left[1], self.data.left[2])
	end

	xyd.setUISpriteAsync(self.icon, nil, self.data.icon)
end

return DressShowBuffsDetailWindow
