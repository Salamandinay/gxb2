local ActivityExploreOldCampusWayBuyWindow = class("ActivityExploreOldCampusWayBuyWindow", import(".BaseWindow"))
local skillDetail = import("app.components.ActivityExploreOldCampusWayAlert")

function ActivityExploreOldCampusWayBuyWindow:ctor(name, params)
	ActivityExploreOldCampusWayBuyWindow.super.ctor(self, name, params)

	self.buffId_ = params.id
	self.areaId_ = params.area_id
end

function ActivityExploreOldCampusWayBuyWindow:initWindow()
	ActivityExploreOldCampusWayBuyWindow.super.initWindow(self)
	self:getUIComponent()
	self:register()
	self:updateSkillInfo()
end

function ActivityExploreOldCampusWayBuyWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.winTitle_ = goTrans:ComponentByName("winTitle", typeof(UILabel))
	self.closeBtn_ = goTrans:NodeByName("closeBtn").gameObject
	self.detailRoot_ = goTrans:NodeByName("detailRoot").gameObject
	self.labelTips_ = goTrans:ComponentByName("labelTips", typeof(UILabel))
	self.costImg_ = goTrans:ComponentByName("costGroup/costImg", typeof(UISprite))
	self.costClickBg_ = goTrans:NodeByName("costGroup/bg").gameObject
	self.costLabel_ = goTrans:ComponentByName("costGroup/label", typeof(UILabel))
	self.buyBtn_ = goTrans:NodeByName("buyBtn").gameObject
	self.buyBtnLabel = goTrans:ComponentByName("buyBtn/label", typeof(UILabel))
end

function ActivityExploreOldCampusWayBuyWindow:register()
	ActivityExploreOldCampusWayBuyWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.buyBtn_).onClick = handler(self, self.onClickBuy)

	UIEventListener.Get(self.costClickBg_).onClick = function ()
		local cost = xyd.tables.activityOldBuildingBuffTable:getUnlockCost(self.buffId_)
		local params = {
			showGetWays = true,
			show_has_num = true,
			itemID = cost[1],
			itemNum = xyd.models.backpack:getItemNumByID(cost[1]),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function ActivityExploreOldCampusWayBuyWindow:onClickBuy()
	local cost = xyd.tables.activityOldBuildingBuffTable:getUnlockCost(self.buffId_)
	local costNum = cost[2]

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.OLD_BUILDING_CARD) < costNum then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
	else
		xyd.models.activity:getActivity(xyd.ActivityID.EXPLORE_OLD_CAMPUS_PVE):reqBuyBuff(self.buffId_, self.areaId_)
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityExploreOldCampusWayBuyWindow:updateSkillInfo()
	local cost = xyd.tables.activityOldBuildingBuffTable:getUnlockCost(self.buffId_)
	local itemName = xyd.tables.itemTextTable:getName(cost[1])
	self.winTitle_.text = __("ACTIVITY_EXPLORE_CAMPUS_4")
	self.labelTips_.text = __("ACTIVITY_EXPLORE_CAMPUS_5", cost[2], itemName)
	self.costLabel_.text = xyd.models.backpack:getItemNumByID(cost[1]) .. "/" .. cost[2]

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.OLD_BUILDING_CARD) < cost[2] then
		self.costLabel_.color = Color.New2(4278190335.0)
	else
		self.costLabel_.color = Color.New2(960513791)
	end

	self.buyBtnLabel.text = __("SURE")

	self:initDetailGroup()
end

function ActivityExploreOldCampusWayBuyWindow:initDetailGroup()
	local goTrans = self.detailRoot_:NodeByName("groupAction")
	self.skillImg_ = goTrans:ComponentByName("skillImg", typeof(UISprite))
	self.skillName_ = goTrans:ComponentByName("skillName", typeof(UILabel))
	self.skillDesc_ = goTrans:ComponentByName("scrollView/skillDesc", typeof(UILabel))
	self.scoreLabel_ = goTrans:ComponentByName("scoreCon/scoreLabel", typeof(UILabel))
	local skillIconName = xyd.tables.activityOldBuildingBuffTable:getIconName(self.buffId_)
	local point = xyd.tables.activityOldBuildingBuffTable:getPoint(self.buffId_)

	xyd.setUISpriteAsync(self.skillImg_, nil, skillIconName)

	local skillName = xyd.tables.activityOldBuildingBuffTextTable:getBuffName(self.buffId_)
	local skillDesc = xyd.tables.activityOldBuildingBuffTextTable:getBuffDesc(self.buffId_)
	self.skillName_.text = skillName
	self.skillDesc_.text = skillDesc
	self.scoreLabel_.text = point
end

return ActivityExploreOldCampusWayBuyWindow
