local BaseWindow = import(".BaseWindow")
local ActivityRechargeLotteryMissionWindow = class("ActivityRechargeLotteryMissionWindow", BaseWindow)
local ActivityRechargeLotteryMissionWindowItem = class("ActivityRechargeLotteryMissionWindowItem", import("app.components.CopyComponent"))
local awardItemID = xyd.ItemID.RECHARGE_LOTTERY_TICKET

function ActivityRechargeLotteryMissionWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.vipExp = params.vipExp or 0
end

function ActivityRechargeLotteryMissionWindow:initWindow()
	self:getUIComponent()
	ActivityRechargeLotteryMissionWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityRechargeLotteryMissionWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.imgText = groupAction:ComponentByName("imgText", typeof(UISprite))
	self.scroller = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.itemCell = winTrans:NodeByName("itemCell").gameObject
end

function ActivityRechargeLotteryMissionWindow:initUIComponent()
	xyd.setUISpriteAsync(self.imgText, nil, "activity_recharge_lottery_ljjl_" .. xyd.Global.lang, nil, , true)

	local vipExpNeed = xyd.tables.miscTable:split2Cost("activity_lottery_vip_exp", "value", "|")

	table.sort(vipExpNeed)

	local data = {}

	for i = 1, #vipExpNeed do
		if #data == 0 or data[#data].vipExpNeed ~= vipExpNeed[i] then
			table.insert(data, {
				awardNum = 1,
				vipExp = self.vipExp,
				vipExpNeed = vipExpNeed[i],
				sortIndex = #data + 1
			})
		else
			data[#data].awardNum = data[#data].awardNum + 1
		end
	end

	table.sort(data, function (a, b)
		local isCompleteA = a.vipExpNeed <= a.vipExp and 1 or 0
		local isCompleteB = b.vipExpNeed <= b.vipExp and 1 or 0

		if isCompleteA == isCompleteB then
			return a.sortIndex < b.sortIndex
		else
			return isCompleteA < isCompleteB
		end
	end)

	for i = 1, #data do
		local go = NGUITools.AddChild(self.groupItem, self.itemCell)
		local item = ActivityRechargeLotteryMissionWindowItem.new(go, self)

		item:setInfo(data[i])
	end

	self.groupItem:GetComponent(typeof(UILayout)):Reposition()
	self.scroller:ResetPosition()
end

function ActivityRechargeLotteryMissionWindowItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.labelTip = self.go:ComponentByName("labelTip", typeof(UILabel))
	self.progressBar = self.go:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.groupIcon = self.go:NodeByName("groupIcon").gameObject

	UIEventListener.Get(self.go).onClick = function ()
		xyd.goToActivityWindowAgain({
			activity_type = 1
		})
		xyd.WindowManager.get():closeWindow("activity_recharge_lottery_mission_window")
		xyd.WindowManager.get():closeWindow("activity_recharge_lottery_window")
	end
end

function ActivityRechargeLotteryMissionWindowItem:setInfo(params)
	self.labelTip.text = __("ACTIVITY_LOTTERY_TEXT05", params.vipExpNeed)
	self.progressBar.value = math.min(params.vipExp, params.vipExpNeed) / params.vipExpNeed
	self.progressLabel.text = math.min(params.vipExp, params.vipExpNeed) .. "/" .. params.vipExpNeed
	local icon = xyd.getItemIcon({
		showGetWays = false,
		notShowGetWayBtn = true,
		show_has_num = true,
		scale = 0.6018518518518519,
		itemID = awardItemID,
		num = params.awardNum,
		uiRoot = self.groupIcon,
		dragScrollView = self.parent.scroller,
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})

	if params.vipExpNeed <= params.vipExp then
		icon:setChoose(true)
	end
end

return ActivityRechargeLotteryMissionWindow
