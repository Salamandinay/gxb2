local ActivityContent = import(".ActivityContent")
local Activity3BirthdayVipWindow = class("Activity3BirthdayVipWindow", ActivityContent)
local Activity3BirthdayVipItem = class("Activity3BirthdayVipItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")
local Activity3BirthdayVipAwardTable = xyd.tables.activity3BirthdayVipAwardTable

function Activity3BirthdayVipWindow:ctor(parentGO, params)
	self.curVipLev = xyd.models.backpack:getVipLev()
	self.collection = {}

	Activity3BirthdayVipWindow.super.ctor(self, parentGO, params)
end

function Activity3BirthdayVipWindow:getPrefabPath()
	return "Prefabs/Windows/activity/activity_3birthday_vip_window"
end

function Activity3BirthdayVipWindow:initUI()
	Activity3BirthdayVipWindow.super.initUI(self)
	self:getUIComponent()
	self:initUIComponent()
	self:onRegister()
	self:updateDailyAward()
	self:updateContent()
end

function Activity3BirthdayVipWindow:getUIComponent()
	local go = self.go
	self.textImg_ = go:ComponentByName("textImg_", typeof(UISprite))
	local timeGroup = go:NodeByName("countdownGroup/timeGroup").gameObject
	self.timeLabel_ = timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.titleLabel_ = go:ComponentByName("dailyGroup/titleLabel_", typeof(UILabel))
	self.awardGroup = go:NodeByName("dailyGroup/awardGroup").gameObject
	self.dailyAwardlayout_ = self.awardGroup:GetComponent(typeof(UILayout))
	local tipsGroup = go:NodeByName("dailyGroup/tipsGroup").gameObject
	self.awardTimeLabel_ = tipsGroup:ComponentByName("awardTimeLabel_", typeof(UILabel))
	self.tipsLabel_ = tipsGroup:ComponentByName("tipsLabel_", typeof(UILabel))
	self.previewBtn_ = go:NodeByName("dailyGroup/previewBtn_").gameObject
	self.helpBtn_ = go:NodeByName("helpBtn_").gameObject
	self.scrollView = go:ComponentByName("contentGroup/scrollerGroup/itemScroller", typeof(UIScrollView))
	self.itemGroup = go:NodeByName("contentGroup/scrollerGroup/itemScroller/itemGroup").gameObject
	self.scrollerItem = go:NodeByName("activity_3birthday_vip_item").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.scrollerItem, Activity3BirthdayVipItem, self)
end

function Activity3BirthdayVipWindow:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "activity_3birthday_vip_text_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel_.text = __("END")

	CountDown.new(self.awardTimeLabel_, {
		duration = xyd.getTomorrowTime() - xyd.getServerTime()
	})

	self.tipsLabel_.text = __("ACTIVITY_3BIRTHDAY_VIP_TEXT02")
	self.titleLabel_.text = __("ACTIVITY_3BIRTHDAY_VIP_TEXT01")
end

function Activity3BirthdayVipWindow:updateDailyAward()
	local ids = Activity3BirthdayVipAwardTable:getIds()
	local curId = 1

	for i, id in ipairs(ids) do
		local vipLev = Activity3BirthdayVipAwardTable:getVipLevel(id)

		if vipLev == self.curVipLev then
			curId = id

			break
		end
	end

	local dailyAwards = Activity3BirthdayVipAwardTable:getdailyAwards(curId)

	NGUITools.DestroyChildren(self.awardGroup.transform)

	for i = 1, #dailyAwards do
		local award = dailyAwards[i]

		xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7037037037037037,
			uiRoot = self.awardGroup,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self.dailyAwardlayout_:Reposition()
end

function Activity3BirthdayVipWindow:onRegister()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_3BIRTHDAY_VIP_HELP"
		})
	end

	UIEventListener.Get(self.previewBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_3birthday_vip_award_window")
	end

	self.eventProxyInner_:addEventListener(xyd.event.VIP_CHANGE, handler(self, self.onVipChange))
end

function Activity3BirthdayVipWindow:updateContent()
	local ids = Activity3BirthdayVipAwardTable:getIds()
	self.collection = {}

	for i, id in ipairs(ids) do
		table.insert(self.collection, {
			id = id,
			curVipLev = self.curVipLev,
			isAwarded = self.activityData.detail.awards[id]
		})
	end

	table.sort(self.collection, function (a, b)
		if a.isAwarded ~= b.isAwarded then
			return a.isAwarded < b.isAwarded
		else
			return a.id < b.id
		end
	end)
	self.wrapContent:setInfos(self.collection, {})
	self.scrollView:ResetPosition()
end

function Activity3BirthdayVipWindow:onVipChange(event)
	self.curVipLev = xyd.models.backpack:getVipLev()

	self:updateDailyAward()
	self:updateContent()
end

function Activity3BirthdayVipItem:ctor(go, parent)
	Activity3BirthdayVipItem.super.ctor(self, go, parent)

	self.items = {}
end

function Activity3BirthdayVipItem:initUI()
	local go = self.go
	self.desLabel_ = go:ComponentByName("desLabel_", typeof(UILabel))
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.layout_ = self.awardGroup:GetComponent(typeof(UILayout))
	self.awardBtn_ = go:NodeByName("awardBtn_").gameObject
	self.awardBtnLabel_ = self.awardBtn_:ComponentByName("button_label", typeof(UILabel))
	self.awardBtnGrey_ = go:NodeByName("awardBtnGrey_").gameObject
	self.awardBtnGreyLabel_ = self.awardBtnGrey_:ComponentByName("button_label", typeof(UILabel))
	self.awardImg_ = self.go:ComponentByName("awardImg_", typeof(UISprite))

	xyd.setUISpriteAsync(self.awardImg_, nil, "mission_awarded_" .. xyd.Global.lang, nil, , true)

	self.awardBtnLabel_.text = __("GET2")
	self.awardBtnGreyLabel_.text = __("GET2")

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		local data = cjson.encode({
			table_id = self.id
		})
		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_3BIRTHDAY_VIP
		msg.params = data

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

		self.data.isAwarded = 1

		self:updateInfo()
	end
end

function Activity3BirthdayVipItem:updateInfo()
	self.id = self.data.id
	self.isAwarded = self.data.isAwarded
	self.curVipLev = self.data.curVipLev
	self.targetVipLev = Activity3BirthdayVipAwardTable:getVipLevel(self.id)
	self.desLabel_.text = __("ACTIVITY_3BIRTHDAY_VIP_TEXT03", self.targetVipLev, self.curVipLev, self.targetVipLev)
	local awards = Activity3BirthdayVipAwardTable:getOnceAwards(self.id)

	NGUITools.DestroyChildren(self.awardGroup.transform)

	for i = 1, #awards do
		local award = awards[i]
		self.items[i] = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7962962962962963,
			uiRoot = self.awardGroup,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent.scrollView
		})

		if self.isAwarded == 1 then
			self.items[i]:setChoose(true)

			if xyd.tables.itemTable:getType(award[1]) == xyd.ItemType.AVATAR_FRAME then
				self.items[i].imgMask_:SetLocalScale(1.15, 1.15, 1.15)
			end
		else
			self.items[i]:setChoose(false)
		end
	end

	self.layout_:Reposition()

	if self.isAwarded == 1 then
		self.awardBtn_:SetActive(false)
		self.awardImg_:SetActive(true)
		self.awardBtnGrey_:SetActive(false)
	elseif self.targetVipLev <= self.curVipLev then
		self.awardBtn_:SetActive(true)
		self.awardImg_:SetActive(false)
		self.awardBtnGrey_:SetActive(false)
	else
		self.awardBtn_:SetActive(false)
		self.awardImg_:SetActive(false)
		self.awardBtnGrey_:SetActive(true)
	end
end

return Activity3BirthdayVipWindow
