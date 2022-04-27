local BaseWindow = import(".BaseWindow")
local ActivityPromotionLadderDetailWindow = class("ActivityPromotionLadderDetailWindow", BaseWindow)
local HeroIcon = import("app.components.HeroIcon")
local activityID = xyd.ActivityID.ACTIVITY_PROMOTION_LADDER
local costBase = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_basenum", "value", "#")
local costIncreaseInterval = xyd.tables.miscTable:getNumber("activity_promotion_ladder_interval", "value")
local costIncrease = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_increasenum", "value", "#")
local materialPartnerTableID = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_material", "value", "|")

function ActivityPromotionLadderDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(activityID)
end

function ActivityPromotionLadderDetailWindow:initWindow()
	self:getUIComponent()
	ActivityPromotionLadderDetailWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityPromotionLadderDetailWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local groupMain = groupAction:NodeByName("groupMain").gameObject
	local groupMaterial = groupMain:NodeByName("groupMaterial").gameObject
	self.labelDesc = groupMaterial:ComponentByName("labelDesc", typeof(UILabel))
	self.groupIcon = groupMaterial:NodeByName("groupIcon").gameObject
	local groupProgress = groupMain:NodeByName("groupProgress").gameObject
	self.labelProgress = groupProgress:ComponentByName("labelProgress", typeof(UILabel))
	self.progressBar = groupProgress:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressNum = self.progressBar:ComponentByName("progressNum", typeof(UILabel))
	self.labelTip = groupProgress:ComponentByName("labelTip", typeof(UILabel))
	self.costNow = groupProgress:ComponentByName("costNow", typeof(UISprite))
	self.costNowNum = self.costNow:ComponentByName("num", typeof(UILabel))
	self.costAfter = groupProgress:ComponentByName("costAfter", typeof(UISprite))
	self.costAfterNum = self.costAfter:ComponentByName("num", typeof(UILabel))
end

function ActivityPromotionLadderDetailWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_PROMOTION_LADDER_TEXT02")
	self.labelDesc.text = __("ACTIVITY_PROMOTION_LADDER_TEXT03")
	self.labelProgress.text = __("ACTIVITY_PROMOTION_LADDER_TEXT04")
	self.progressBar.value = self.activityData.detail.times % costIncreaseInterval / costIncreaseInterval
	self.progressNum.text = self.activityData.detail.times % costIncreaseInterval .. "/" .. costIncreaseInterval
	self.costNowNum.text = costBase[2] + math.floor(self.activityData.detail.times / costIncreaseInterval) * costIncrease[2]
	self.costAfterNum.text = costBase[2] + (math.floor(self.activityData.detail.times / costIncreaseInterval) + 1) * costIncrease[2]
	self.labelTip.text = __("ACTIVITY_PROMOTION_LADDER_TEXT05", costIncreaseInterval - self.activityData.detail.times % costIncreaseInterval, costBase[2] + (math.floor(self.activityData.detail.times / costIncreaseInterval) + 1) * costIncrease[2])

	if xyd.Global.lang == "ko_kr" then
		self.labelTip.fontSize = 20
	end

	for _, tableID in ipairs(materialPartnerTableID) do
		local params = {
			noClickSelected = true,
			star = 5,
			tableID = tableID,
			group = xyd.tables.partnerTable:getGroup(tableID),
			callback = function ()
				local collection = {
					{
						table_id = tableID
					}
				}
				local params = {
					partners = collection,
					table_id = tableID
				}

				xyd.WindowManager.get():openWindow("guide_detail_window", params, function ()
					xyd.WindowManager.get():closeWindowsOnLayer(6)
				end)
			end
		}
		local icon = HeroIcon.new(self.groupIcon.gameObject)

		icon:setInfo(params)
	end

	self.groupIcon:GetComponent(typeof(UIGrid)):Reposition()
end

return ActivityPromotionLadderDetailWindow
