local BaseWindow = import(".BaseWindow")
local ActivityFishingResultWindow = class("ActivityFishingResultWindow", BaseWindow)

function ActivityFishingResultWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.id = params.id
	self.len = params.len
end

function ActivityFishingResultWindow:initWindow()
	self:getUIComponent()
	ActivityFishingResultWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityFishingResultWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.imgFish = self.groupAction:ComponentByName("imgFish", typeof(UISprite))
	self.labelName = self.groupAction:ComponentByName("labelName", typeof(UILabel))
	self.imgCrown = self.groupAction:ComponentByName("imgCrown", typeof(UISprite))
	self.labelLen = self.groupAction:ComponentByName("labelLen", typeof(UILabel))
end

function ActivityFishingResultWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_FISH_GET_TITLE")

	xyd.setUISpriteAsync(self.imgFish, nil, xyd.tables.activityFishingMainTable:getPic(self.id), nil, , true)

	local goldLenRange = xyd.tables.activityFishingMainTable:getRange1(self.id)
	local silverLenRange = xyd.tables.activityFishingMainTable:getRange2(self.id)

	if goldLenRange[2][1] <= self.len then
		xyd.setUISpriteAsync(self.imgCrown, nil, "activity_fishing_icon_gold")
	elseif silverLenRange[2][1] <= self.len then
		xyd.setUISpriteAsync(self.imgCrown, nil, "activity_fishing_icon_silver")
	elseif self.len <= goldLenRange[1][2] then
		xyd.setUISpriteAsync(self.imgCrown, nil, "activity_fishing_icon_gold")
	elseif self.len <= silverLenRange[1][2] then
		xyd.setUISpriteAsync(self.imgCrown, nil, "activity_fishing_icon_silver")
	end

	self.labelName.text = xyd.tables.activityFishingTextTable:getName(self.id)
	self.labelLen.text = __("ACTIVITY_FISH_GET_LENGTH", string.format("%.2f", self.len))
end

function ActivityFishingResultWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

return ActivityFishingResultWindow
