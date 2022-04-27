local BaseWindow = import(".BaseWindow")
local ActivityRechargeLotteryBoxDetailWindow = class("ActivityRechargeLotteryBoxDetailWindow", BaseWindow)

function ActivityRechargeLotteryBoxDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.type = params.type
	self.boxID = params.boxID

	if self.type == 1 then
		self.boxName = "dcmb"
	else
		self.boxName = "csmb"
	end
end

function ActivityRechargeLotteryBoxDetailWindow:initWindow()
	self:getUIComponent()
	ActivityRechargeLotteryBoxDetailWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityRechargeLotteryBoxDetailWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.imgBox = groupAction:ComponentByName("imgBox", typeof(UISprite))
	self.imgText = groupAction:ComponentByName("imgText", typeof(UISprite))
	self.labelDesc = groupAction:ComponentByName("labelDesc", typeof(UILabel))
	local groupAward = groupAction:NodeByName("groupAward").gameObject
	self.layout = groupAward:ComponentByName("layout", typeof(UILayout))
end

function ActivityRechargeLotteryBoxDetailWindow:initUIComponent()
	xyd.setUISpriteAsync(self.imgBox, nil, "activity_recharge_lottery_" .. self.boxName, nil, , true)
	xyd.setUISpriteAsync(self.imgText, nil, "activity_recharge_lottery_" .. self.boxName .. "_" .. xyd.Global.lang, nil, , true)

	self.labelDesc.text = __("ACTIVITY_LOTTERY_TEXT02")
	local awards = xyd.tables.activityLotteryTable:getAwards(self.boxID)

	for i = 1, #awards do
		local award = awards[i]

		xyd.getItemIcon({
			show_has_num = true,
			showGetWays = false,
			scale = 0.6574074074074074,
			notShowGetWayBtn = true,
			itemID = award[1],
			num = award[2],
			uiRoot = self.layout.gameObject,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self.layout:Reposition()
end

return ActivityRechargeLotteryBoxDetailWindow
