local BaseWindow = import(".BaseWindow")
local ActivityHalloweenTrickPreviewWindow = class("ActivityHalloweenTrickPreviewWindow", BaseWindow)
local ActivityHalloweenTrickPreviewWindowItem = class("ActivityHalloweenTrickPreviewWindowItem")

function ActivityHalloweenTrickPreviewWindow:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.boxID = params.boxID
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
	self.groupCommonAward = self.groupAction:NodeByName("groupCommonAward").gameObject
	self.bgCommonAward = self.groupAction:NodeByName("bgCommonAward").gameObject
	self.itemCell = winTrans:NodeByName("awardItem").gameObject
end

function ActivityHalloweenTrickPreviewWindow:layout()
	self.labelTitle.text = __("ACTIVITY_TRICKORTREAT_TEXT03")
	self.labelSuperAward.text = __("ACTIVITY_TRICKORTREAT_TEXT04")
	self.labelCommonAward.text = __("ACTIVITY_TRICKORTREAT_TEXT05")
	local totalWeight = 0
	local awards = xyd.tables.activityTrickortreatTable:getAwards(self.boxID)
	local weights = xyd.tables.activityTrickortreatTable:getWeights(self.boxID)

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

	self.groupCommonAward:GetComponent(typeof(UILayout)):Reposition()

	if self.boxID == 6 then
		self.labelCommonAward:SetActive(false)
		self.groupCommonAward:SetActive(false)
		self.bgCommonAward:SetActive(false)

		self.groupAction.height = 277
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
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})

	self.labelProbablility.text = params.probablility
end

return ActivityHalloweenTrickPreviewWindow
