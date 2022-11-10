local ActivityDailyRecharge = class("ActivityDailyRecharge", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local activityID = xyd.ActivityID.ACTIVITY_DAILY_RECHARGE
local cellCenter = {
	{
		x = 0,
		y = 247
	},
	{
		x = -73,
		y = 120
	},
	{
		x = 73,
		y = 120
	},
	{
		x = -141,
		y = -5
	},
	{
		x = 0,
		y = -5
	},
	{
		x = 141,
		y = -5
	},
	{
		x = -202,
		y = -127
	},
	{
		x = -68,
		y = -127
	},
	{
		x = 68,
		y = -127
	},
	{
		x = 202,
		y = -127
	},
	{
		x = -266,
		y = -240
	},
	{
		x = -132,
		y = -240
	},
	{
		x = 0,
		y = -240
	},
	{
		x = 132,
		y = -240
	},
	{
		x = 266,
		y = -240
	}
}
local spriteSize = {
	{
		x = 138,
		y = 138
	},
	{
		x = 148,
		y = 148
	},
	{
		x = 158,
		y = 158
	},
	{
		x = 168,
		y = 168
	},
	{
		x = 255,
		y = 222
	}
}

function ActivityDailyRecharge:ctor(parentGO, params)
	ActivityDailyRecharge.super.ctor(self, parentGO, params)
end

function ActivityDailyRecharge:getPrefabPath()
	return "Prefabs/Windows/activity/activity_daily_recharge"
end

function ActivityDailyRecharge:resizeToParent()
	ActivityDailyRecharge.super.resizeToParent(self)
	self:resizePosY(self.buyBtn, -837, -977)
	self:resizePosY(self.buyTipLabel, -783, -915)
	self:resizePosY(self.itemGroup, -460, -564)
	self:resizePosY(self.timeGroup, -133, -220)
	self:resizePosY(self.imgLogo, -20, -105)
end

function ActivityDailyRecharge:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_DAILY_RECHARGE)

	dump(self.activityData)

	self.id = xyd.ActivityID.ACTIVITY_DAILY_RECHARGE

	self:getUIComponent()
	ActivityDailyRecharge.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityDailyRecharge:getUIComponent()
	self.trans = self.go
	self.bg = self.trans:ComponentByName("bg", typeof(UISprite))
	self.imgLogo = self.trans:ComponentByName("imgLogo", typeof(UISprite))
	self.timeGroup = self.trans:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLayout = self.trans:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = self.trans:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.endLabel_ = self.trans:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
	self.btnHelp = self.trans:NodeByName("btnHelp").gameObject
	self.buyBtn = self.trans:NodeByName("buyBtn").gameObject
	self.buyBtnSprite = self.trans:ComponentByName("buyBtn", typeof(UISprite))
	self.buyBtnLabel = self.trans:ComponentByName("buyBtn/buttonLabel", typeof(UILabel))
	self.buyBtnRed = self.trans:NodeByName("buyBtn/redPoint").gameObject
	self.giftBtn = self.trans:NodeByName("giftBtn").gameObject
	self.giftBtnLabel = self.trans:ComponentByName("giftBtn/buttonLabel", typeof(UILabel))
	self.giftBtnRed = self.trans:NodeByName("giftBtn/redPoint").gameObject
	self.buyTipLabel = self.trans:ComponentByName("buyTipLabel", typeof(UILabel))
	self.itemGroup = self.trans:NodeByName("itemGroup").gameObject
	self.awardItem = self.trans:NodeByName("awardItem").gameObject
end

function ActivityDailyRecharge:register()
	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_PAY_DAY_HELP"
		})
	end

	UIEventListener.Get(self.buyBtn).onClick = function ()
		if self.activityData.detail.award_times > 0 then
			local data = require("cjson").encode({
				type = 1
			})
			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = activityID
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		elseif #self.activityData.detail.award_ids >= 15 then
			return
		else
			xyd.alertTips(__("ACTIVITY_PAY_DAY_TEXT05"))
		end
	end

	UIEventListener.Get(self.giftBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_daily_recharge_giftbag_window")
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = json.decode(data.detail)

		if data.activity_id ~= xyd.ActivityID.ACTIVITY_DAILY_RECHARGE then
			return
		end

		self:initData()
	end)
	self:registerEvent(xyd.event.RECHARGE, function (event)
		self:initData()
	end)
end

function ActivityDailyRecharge:initUIComponent()
	xyd.setUISpriteAsync(self.imgLogo, nil, "daily_recharge_logo_" .. xyd.Global.lang)
	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel_.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	self.timeLayout:Reposition()

	self.buyBtnLabel.text = __("ACTIVITY_PAY_DAY_TEXT02")
	self.buyTipLabel.text = __("ACTIVITY_PAY_DAY_TEXT03")
	self.giftBtnLabel.text = __("ACTIVITY_PAY_DAY_TEXT01")
	self.awardItems_ = {}
	local awardIds = {}

	dump(self.activityData.detail.start_time)
	dump(xyd.tables.miscTable:getNumber("acticity_pay_day_awards_chang_time", "value"))

	if self.activityData.detail.start_time < xyd.tables.miscTable:getNumber("acticity_pay_day_awards_chang_time", "value") then
		awardIds = xyd.tables.activityDailyRechargeTable:getIDs()
	else
		awardIds = xyd.tables.activityDailyRechargeGiftTable:getIDs()
	end

	for i = 1, #awardIds do
		local award = {}

		if self.activityData.detail.start_time < xyd.tables.miscTable:getNumber("acticity_pay_day_awards_chang_time", "value") then
			award = xyd.tables.activityDailyRechargeTable:getAwards(i)
		else
			award = xyd.tables.activityDailyRechargeGiftTable:getAwards(i)
		end

		local newRoot = NGUITools.AddChild(self.itemGroup.gameObject, self.awardItem)

		newRoot:SetActive(true)
		newRoot:X(cellCenter[i].x)
		newRoot:Y(cellCenter[i].y)

		local floorFlag = 0

		if i <= 1 then
			floorFlag = 5
		elseif i <= 3 then
			floorFlag = 4
		elseif i <= 6 then
			floorFlag = 3
		elseif i <= 10 then
			floorFlag = 2
		else
			floorFlag = 1
		end

		local newRootSprite = newRoot:ComponentByName("bg", typeof(UISprite))
		newRootSprite.width = spriteSize[floorFlag].x
		newRootSprite.height = spriteSize[floorFlag].y

		xyd.setUISpriteAsync(newRootSprite, nil, "daily_recharge_icon_pp_" .. floorFlag)

		if i == 1 then
			local iconBg = newRoot:NodeByName("bg").gameObject

			iconBg:X(-40)
			iconBg:Y(21)
		end

		self.awardItems_[i] = xyd.getItemIcon({
			showGetWays = false,
			notShowGetWayBtn = true,
			show_has_num = true,
			scale = 0.7777777777777778,
			isShowSelected = false,
			uiRoot = newRoot,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		self.awardItems_[i]:setDepth(20)
	end

	self:initData()
end

function ActivityDailyRecharge:initData()
	if self.activityData.detail.award_times > 0 and #self.activityData.detail.award_ids < 15 then
		xyd.setUISpriteAsync(self.buyBtnSprite, nil, "daily_recharge_btn_l")
		self.buyBtnRed:SetActive(true)

		local awardedTimes = math.min(self.activityData.detail.award_times, 15 - #self.activityData.detail.award_ids)
		self.buyBtnLabel.text = "(" .. awardedTimes .. "/1)" .. __("ACTIVITY_PAY_DAY_TEXT02")
	else
		xyd.setUISpriteAsync(self.buyBtnSprite, nil, "daily_recharge_btn_h")
		self.buyBtnRed:SetActive(false)

		self.buyBtnLabel.text = __("ACTIVITY_PAY_DAY_TEXT02")
	end

	for i = 1, #self.activityData.detail.award_ids do
		self.awardItems_[self.activityData.detail.award_ids[i]]:setChoose(true)
	end

	if self.activityData.detail.free_times == 0 then
		self.giftBtnRed:SetActive(true)
	else
		self.giftBtnRed:SetActive(false)
	end
end

return ActivityDailyRecharge
