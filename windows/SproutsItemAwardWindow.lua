local BaseWindow = import(".BaseWindow")
local SproutsItemAwardWindow = class("SproutsItemAwardWindow", BaseWindow)
local ProbabilityRender = class("ProbabilityRender", import("app.components.CopyComponent"))
local ActivitySproutsCostAwardTable = xyd.tables.activitySproutsCostAwardTable

function SproutsItemAwardWindow:ctor(name, params)
	SproutsItemAwardWindow.super.ctor(self, name, params)
end

function SproutsItemAwardWindow:initWindow()
	SproutsItemAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function SproutsItemAwardWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.labelTitle = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.label1 = winTrans:ComponentByName("label1", typeof(UILabel))
	self.label2 = winTrans:ComponentByName("label2", typeof(UILabel))
	self.awardIcon = winTrans:NodeByName("awardIcon").gameObject
	self.scroller = winTrans:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = winTrans:NodeByName("scroller/itemGroup").gameObject
	self.dropItem = winTrans:NodeByName("scroller/dropItem").gameObject
end

function SproutsItemAwardWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.label1.text = __("ACTIVITY_SPROUTS_NEW_TEXT02")
	self.label2.text = __("ACTIVITY_SPROUTTS_TEXT")
	local awardInfo = xyd.tables.miscTable:split2Cost("activity_sprouts_10_award", "value", "|#")

	xyd.getItemIcon({
		show_has_num = false,
		uiRoot = self.awardIcon,
		itemID = tonumber(awardInfo[2][1]),
		num = tonumber(awardInfo[2][2])
	})

	local ids = ActivitySproutsCostAwardTable:getIDs()

	for id in pairs(ids) do
		local weight = ActivitySproutsCostAwardTable:getWeight(id)

		if weight and ActivitySproutsCostAwardTable:isHeight(id) ~= 1 then
			local tmp = NGUITools.AddChild(self.itemGroup, self.dropItem)
			local item = ProbabilityRender.new(tmp)

			item:setInfo(id)
			xyd.setDragScrollView(item.go, self.scroller)
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ProbabilityRender:ctor(go)
	ProbabilityRender.super.ctor(self, go)
end

function ProbabilityRender:initUI()
	local go = self.go
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.label = go:ComponentByName("label", typeof(UILabel))
end

function ProbabilityRender:setInfo(id)
	self.table_id = id
	local data = ActivitySproutsCostAwardTable:getAward(self.table_id)
	local proba = ActivitySproutsCostAwardTable:getProbability(self.table_id) * 100
	self.label.text = tostring(proba) .. "%"
	self.icon_ = xyd.getItemIcon({
		show_has_num = false,
		noClickSelected = true,
		uiRoot = self.groupIcon,
		itemID = data[1],
		num = data[2]
	})
end

return SproutsItemAwardWindow
