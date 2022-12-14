local BaseWindow = import(".BaseWindow")
local ActivityGrowthPlanAwardWindow = class("ActivityGrowthPlanAwardWindow", BaseWindow)
local activityGrowthPlanTable = nil

function ActivityGrowthPlanAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	if params and params.ActivityID and params.ActivityID == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
		activityGrowthPlanTable = xyd.tables.activityNewGrowthAwardTable
		self.id = xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN
	else
		activityGrowthPlanTable = xyd.tables.activityGrowthPlanTable
		self.id = xyd.ActivityID.ACTIVITY_GROWTH_PLAN
	end

	if self.id == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
		self.preText = "ACTIVITY_NEW_GROWTH_PLAN_TEXT"
	else
		self.preText = "ACTIVITY_GROWTH_PLAN_TEXT"
	end
end

function ActivityGrowthPlanAwardWindow:initWindow()
	ActivityGrowthPlanAwardWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(self.id)

	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function ActivityGrowthPlanAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.bg_ = groupAction:ComponentByName("bg_", typeof(UISprite))
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local mainGroup = groupAction:NodeByName("mainGroup").gameObject
	self.bg2_ = mainGroup:ComponentByName("bg2_", typeof(UISprite))
	self.scrollView = mainGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.mainLayout = mainGroup:ComponentByName("scroller/layout", typeof(UILayout))
	self.titleLabel1 = mainGroup:ComponentByName("scroller/layout/awardGroup1/label1", typeof(UILabel))
	self.itemGroup1 = mainGroup:NodeByName("scroller/layout/awardGroup1/itemGroup1").gameObject
	self.titleLabel2 = mainGroup:ComponentByName("scroller/layout/awardGroup2/label2", typeof(UILabel))
	self.itemGroup2 = mainGroup:NodeByName("scroller/layout/awardGroup2/itemGroup2").gameObject
end

function ActivityGrowthPlanAwardWindow:initUIComponent()
	self.labelTitle_.text = __("ACTIVITY_MISSION_POINT_TEXT09")
	self.titleLabel1.text = __(self.preText .. "10")
	self.titleLabel2.text = __(self.preText .. "09")
	self.bg_.height = 502

	self.bg_:Y(-47)

	self.bg2_.height = 426

	self.bg2_:Y(-46)

	local ids = activityGrowthPlanTable:getIDs()
	local awards1 = {}
	local awards2 = {}

	for i = 1, #ids do
		local extraAwards = activityGrowthPlanTable:getPaidAward(i, self.activityData:getCurPartnerIndex())

		for j = 1, #extraAwards do
			local itemID = extraAwards[j][1]
			local num = extraAwards[j][2]

			if not awards1[itemID] then
				awards1[itemID] = 0
			end

			awards1[itemID] = awards1[itemID] + num
		end

		local baseAwards = activityGrowthPlanTable:getFreeAward(i, self.activityData:getCurPartnerIndex())

		for j = 1, #baseAwards do
			local itemID = baseAwards[j][1]
			local num = baseAwards[j][2]

			if not awards2[itemID] then
				awards2[itemID] = 0
			end

			awards2[itemID] = awards2[itemID] + num
		end
	end

	local index = 1
	local awards_1 = {}

	for id, num in pairs(awards1) do
		awards_1[index] = {
			itemID = id,
			num = num
		}
		index = index + 1
	end

	local index = 1
	local awards_2 = {}

	for id, num in pairs(awards2) do
		awards_2[index] = {
			itemID = id,
			num = num
		}
		index = index + 1
	end

	table.sort(awards_1, function (a, b)
		return a.itemID < b.itemID
	end)
	table.sort(awards_2, function (a, b)
		return a.itemID < b.itemID
	end)

	for i = 1, #awards_1 do
		local award = awards_1[i]

		if award.itemID ~= xyd.ItemID.VIP_EXP then
			local item = xyd.getItemIcon({
				scale = 0.7962962962962963,
				uiRoot = self.itemGroup1,
				itemID = award.itemID,
				num = award.num,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.scrollView
			})
		end
	end

	for i = 1, #awards_2 do
		local award = awards_2[i]

		if award[1] ~= xyd.ItemID.VIP_EXP then
			local item = xyd.getItemIcon({
				scale = 0.7962962962962963,
				uiRoot = self.itemGroup2,
				itemID = award.itemID,
				num = award.num,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.scrollView
			})
		end
	end

	self.itemGroup1:GetComponent(typeof(UILayout)):Reposition()
	self.itemGroup2:GetComponent(typeof(UILayout)):Reposition()
	self.mainLayout:Reposition()
	self:waitForTime(0.02, function ()
		self.itemGroup2:GetComponent(typeof(UIGrid)):Reposition()

		self.itemGroup2.transform.localPosition = Vector3(0, -75, 0)
	end)
end

function ActivityGrowthPlanAwardWindow:register()
	ActivityGrowthPlanAwardWindow.super.register(self)
end

return ActivityGrowthPlanAwardWindow
