local BaseWindow = import(".BaseWindow")
local ArtifactShopWarmUpAwardWindow = class("ArtifactShopWarmUpAwardWindow", BaseWindow)
local ActivityMissionPointTable = xyd.tables.activityMissionPointTable

function ArtifactShopWarmUpAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ArtifactShopWarmUpAwardWindow:initWindow()
	ArtifactShopWarmUpAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function ArtifactShopWarmUpAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local mainGroup = groupAction:NodeByName("mainGroup").gameObject
	self.scrollView = mainGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.mainLayout = mainGroup:ComponentByName("scroller/layout", typeof(UILayout))
	self.titleLabel1 = mainGroup:ComponentByName("scroller/layout/awardGroup1/label1", typeof(UILabel))
	self.itemGroup1 = mainGroup:NodeByName("scroller/layout/awardGroup1/itemGroup1").gameObject
	self.titleLabel2 = mainGroup:ComponentByName("scroller/layout/awardGroup2/label2", typeof(UILabel))
	self.itemGroup2 = mainGroup:NodeByName("scroller/layout/awardGroup2/itemGroup2").gameObject
end

function ArtifactShopWarmUpAwardWindow:initUIComponent()
	self.labelTitle_.text = __("ACTIVITY_MISSION_POINT_TEXT09")
	self.titleLabel1.text = __("ACTIVITY_MISSION_POINT_TEXT08")
	self.titleLabel2.text = __("ACTIVITY_MISSION_POINT_TEXT07")
	local ids = ActivityMissionPointTable:getIds()
	local awards1 = {}
	local awards2 = {}

	for i = 1, #ids do
		local extraAwards = ActivityMissionPointTable:getExtraAwards(i)

		for j = 1, #extraAwards do
			local itemID = extraAwards[j][1]
			local num = extraAwards[j][2]

			if not awards1[itemID] then
				awards1[itemID] = 0
			end

			awards1[itemID] = awards1[itemID] + num
		end

		local baseAwards = ActivityMissionPointTable:getBaseAwards(i)

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
				show_has_num = true,
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
				show_has_num = true,
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
end

function ArtifactShopWarmUpAwardWindow:register()
	ArtifactShopWarmUpAwardWindow.super.register(self)
end

return ArtifactShopWarmUpAwardWindow
