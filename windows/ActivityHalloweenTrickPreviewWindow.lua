local BaseWindow = import(".BaseWindow")
local ActivityHalloweenTrickPreviewWindow = class("ActivityHalloweenTrickPreviewWindow", BaseWindow)
local ActivityHalloweenTrickPreviewWindowItem = class("ActivityHalloweenTrickPreviewWindowItem")
local WINDOW_TYPE = {
	DRAGONBOAT2022 = 2,
	HALLOWEEN_TRICK = 1
}

function ActivityHalloweenTrickPreviewWindow:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.params = params
end

function ActivityHalloweenTrickPreviewWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityHalloweenTrickPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:ComponentByName("groupAction", typeof(UIWidget))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.labelSuperAward = self.groupAction:ComponentByName("labelSuperAward", typeof(UILabel))
	self.groupSuperAward = self.groupAction:NodeByName("groupSuperAward").gameObject
	self.labelCommonAward = self.groupAction:ComponentByName("labelCommonAward", typeof(UILabel))
	self.scroller = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.groupCommonAward = self.scroller:NodeByName("groupCommonAward").gameObject
	self.bgCommonAward = self.groupAction:ComponentByName("bgCommonAward", typeof(UISprite))
	self.itemCell = winTrans:NodeByName("awardItem").gameObject
end

function ActivityHalloweenTrickPreviewWindow:layout()
	if self.params.windowTpye == WINDOW_TYPE.HALLOWEEN_TRICK then
		self.labelTitle.text = __("ACTIVITY_TRICKORTREAT_TEXT03")
		self.labelSuperAward.text = __("ACTIVITY_TRICKORTREAT_TEXT04")
		self.labelCommonAward.text = __("ACTIVITY_TRICKORTREAT_TEXT05")
		local totalWeight = 0
		local awards = xyd.tables.activityTrickortreatTable:getAwards(self.params.boxID)
		local weights = xyd.tables.activityTrickortreatTable:getWeights(self.params.boxID)

		for i in ipairs(weights) do
			totalWeight = totalWeight + weights[i]
		end

		for i in ipairs(awards) do
			local groupObj = i == 1 and self.groupSuperAward.gameObject or self.groupCommonAward.gameObject
			local tmp = NGUITools.AddChild(groupObj, self.itemCell.gameObject)
			local item = ActivityHalloweenTrickPreviewWindowItem.new(tmp)

			item:setInfo({
				award = awards[i],
				probablility = tostring(weights[i] * 100 / totalWeight) .. "%"
			})
		end

		self.groupCommonAward:GetComponent(typeof(UIGrid)):Reposition()

		if self.params.boxID == 6 then
			self.labelCommonAward:SetActive(false)
			self.groupCommonAward:SetActive(false)
			self.bgCommonAward:SetActive(false)

			self.groupAction.height = 277
		end
	else
		self.labelTitle.text = __("ACTIVITY_TRICKORTREAT_TEXT03")
		self.labelSuperAward.text = self.params.superAwardText
		self.labelCommonAward.text = self.params.commonAwardText
		self.groupAction.height = 521
		self.bgCommonAward.height = 208

		self.labelCommonAward:Y(-16.5)

		for i in ipairs(self.params.superAwards) do
			local tmp = NGUITools.AddChild(self.groupSuperAward.gameObject, self.itemCell.gameObject)
			local item = ActivityHalloweenTrickPreviewWindowItem.new(tmp)

			item:setInfo({
				award = self.params.superAwards[i],
				probablility = self.params.superAwardProb[i] * 100 .. "%"
			})
		end

		local info = xyd.tables.dropboxShowTable:getIdsByBoxId(self.params.dropBox)
		local all_weight = info.all_weight
		local list = info.list

		for _, id in ipairs(list) do
			local weight = xyd.tables.dropboxShowTable:getWeight(id)
			local data = xyd.tables.dropboxShowTable:getItem(id)
			local tmp = NGUITools.AddChild(self.groupCommonAward.gameObject, self.itemCell.gameObject)
			local item = ActivityHalloweenTrickPreviewWindowItem.new(tmp)

			item:setInfo({
				award = data,
				probablility = math.ceil(weight * 1000000 / all_weight) / 10000 .. "%",
				scroller = self.scroller
			})
		end

		self.groupCommonAward:GetComponent(typeof(UIGrid)):Reposition()
		self.scroller:ResetPosition()
	end
end

function ActivityHalloweenTrickPreviewWindow:register()
	UIEventListener.Get(self.btnClose).onClick = function ()
		self:close()
	end
end

function ActivityHalloweenTrickPreviewWindowItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function ActivityHalloweenTrickPreviewWindowItem:getUIComponent()
	self.icon = self.go:NodeByName("icon").gameObject
	self.labelProbablility = self.go:ComponentByName("labelProbablility", typeof(UILabel))
end

function ActivityHalloweenTrickPreviewWindowItem:setInfo(params)
	xyd.getItemIcon({
		show_has_num = true,
		showGetWays = false,
		notShowGetWayBtn = true,
		itemID = params.award[1],
		num = params.award[2],
		uiRoot = self.icon.gameObject,
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		dragScrollView = params.scroller
	})

	self.labelProbablility.text = params.probablility
end

return ActivityHalloweenTrickPreviewWindow
