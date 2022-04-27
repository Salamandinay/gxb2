local ActivityTimeLimitCallAwardWindow = class("ActivityTimeLimitCallAwardWindow", import(".BaseWindow"))
local CommonTabBar = import("app.common.ui.CommonTabBar")
local LimitAwardItem = class("LimitAwardItem", import("app.components.CopyComponent"))
local cjson = require("cjson")

function ActivityTimeLimitCallAwardWindow:ctor(name, params)
	ActivityTimeLimitCallAwardWindow.super.ctor(self, name, params)

	self.cur_select_ = 1
	self.itemPointList_ = {}
	self.itemPartnerList_ = {}
	self.activityDetail = xyd.models.activity:getActivity(xyd.ActivityID.TIME_LIMIT_CALL).detail
end

function ActivityTimeLimitCallAwardWindow:initWindow()
	ActivityTimeLimitCallAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:register()
	self:checkOpenIndex()
	self:initNav()
end

function ActivityTimeLimitCallAwardWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.winTitle_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.navGroup_ = winTrans:NodeByName("navGroup").gameObject
	self.scrollView1 = winTrans:ComponentByName("scrollView1", typeof(UIScrollView))
	self.grid1 = winTrans:ComponentByName("scrollView1/grid", typeof(UIGrid))
	self.scrollView2 = winTrans:ComponentByName("scrollView2", typeof(UIScrollView))
	self.grid2 = winTrans:ComponentByName("scrollView2/grid", typeof(UIGrid))
	self.itemRoot_ = winTrans:NodeByName("itemRoot").gameObject
	self.winTitle_.text = __(self.name_)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow("activity_time_limit_call_award_window")
	end

	self.winTitle_.text = __("ACTIVITY_LIMIT_GACHA_TEXT02")
end

function ActivityTimeLimitCallAwardWindow:register()
	ActivityTimeLimitCallAwardWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function ActivityTimeLimitCallAwardWindow:initNav()
	local chosen = {
		color = Color.New2(4294967295.0),
		effectColor = Color.New2(1012112383)
	}
	local unchosen = {
		color = Color.New2(960513791),
		effectColor = Color.New2(4294967295.0)
	}
	local colorParams = {
		chosen = chosen,
		unchosen = unchosen
	}
	self.tab_ = CommonTabBar.new(self.navGroup_, 2, function (index)
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		self.cur_select_ = index

		self:updateLayout()
	end, nil, colorParams)
	local tableLabels = {
		__("LIMIT_TIME_CALL_AWARD"),
		__("LIMIT_TIME_CALL_PARTNER")
	}

	self.tab_:setTexts(tableLabels)
	self.tab_:setTabActive(1, true)
	self:updateNavRed()
end

function ActivityTimeLimitCallAwardWindow:updateNavRed()
	self.tab_:getRedMark(2):SetActive(self.needRed2)
	self.tab_:getRedMark(1):SetActive(self.needRed1)
end

function ActivityTimeLimitCallAwardWindow:updateLayout()
	self.scrollView1.gameObject:SetActive(self.cur_select_ == 1)
	self.scrollView2.gameObject:SetActive(self.cur_select_ == 2)
	self:updateMissionGroup(true)
end

function ActivityTimeLimitCallAwardWindow:checkOpenIndex()
	local pointIds = xyd.tables.activityLimitPointAwards:getIds()
	self.sortPointIds = {}
	self.needRed1 = false

	for idx, id in ipairs(pointIds) do
		local point = xyd.tables.activityLimitPointAwards:getPoint(id)
		local hasComp = false
		local hasRewarded = false

		if point < self.activityDetail.times then
			hasComp = true
		end

		if self.activityDetail.awards[idx] and self.activityDetail.awards[idx] == 1 then
			hasRewarded = true
		end

		if hasComp and not hasRewarded then
			self.needRed1 = true
		end

		table.insert(self.sortPointIds, {
			id = id,
			idx = idx,
			hasComp = hasComp,
			hasRewarded = hasRewarded
		})
	end

	table.sort(self.sortPointIds, function (a, b)
		local pointA = a.id
		local pointB = b.id

		if a.hasRewarded then
			pointA = pointA + 10000
		end

		if b.hasRewarded then
			pointB = pointB + 10000
		end

		return pointA < pointB
	end)

	self.sortPrIds = {}
	local partnerIdList = xyd.tables.activityLimitPartnerAwards:getIds()
	self.needRed2 = false

	for idx, id in ipairs(partnerIdList) do
		local point = xyd.tables.activityLimitPartnerAwards:getPoint(id)
		local hasComp = false
		local hasRewarded = false

		if point <= self.activityDetail.times_pr then
			hasComp = true
		end

		if self.activityDetail.awards_pr[idx] and self.activityDetail.awards_pr[idx] == 1 then
			hasRewarded = true
		end

		if hasComp and not hasRewarded then
			self.needRed2 = true
		end

		table.insert(self.sortPrIds, {
			id = id,
			idx = idx,
			hasComp = hasComp,
			hasRewarded = hasRewarded
		})
	end

	table.sort(self.sortPrIds, function (a, b)
		local pointA = a.id
		local pointB = b.id

		if a.hasRewarded then
			pointA = pointA + 10000
		end

		if b.hasRewarded then
			pointB = pointB + 10000
		end

		return pointA < pointB
	end)
end

function ActivityTimeLimitCallAwardWindow:updateMissionGroup(init)
	local tableUse, itemList, awardsdata, tipsText, point, ids = nil

	if self.cur_select_ == 1 then
		tableUse = xyd.tables.activityLimitPointAwards
		itemList = self.itemPointList_
		awardsdata = self.activityDetail.awards or {}
		point = self.activityDetail.times
		tipsText = "LIMIT_TIME_CALL_TEXT"
		ids = self.sortPointIds
	else
		tableUse = xyd.tables.activityLimitPartnerAwards
		itemList = self.itemPartnerList_
		awardsdata = self.activityDetail.awards_pr or {}
		point = self.activityDetail.times_pr
		tipsText = "LIMIT_TIME_CALL_PARTNER_TEXT"
		ids = self.sortPrIds
	end

	for idx, info in ipairs(ids) do
		local params = {
			type_ = self.cur_select_,
			id = info.id,
			awards = tableUse:getAward(info.id),
			is_rewarded = awardsdata[info.idx],
			value = point,
			point = tableUse:getPoint(info.id),
			tipText = tipsText,
			idx = info.idx
		}

		if not itemList[idx] then
			local goRoot = NGUITools.AddChild(self["grid" .. self.cur_select_].gameObject, self.itemRoot_)
			itemList[idx] = LimitAwardItem.new(goRoot, self)
		end

		itemList[idx]:setInfo(params)
	end

	self["grid" .. self.cur_select_]:Reposition()

	if init then
		self["scrollView" .. self.cur_select_]:ResetPosition()
	end
end

function ActivityTimeLimitCallAwardWindow:onClickAward(itemType, itemId)
	local params = {
		table_id = itemId,
		type = itemType
	}
	params = cjson.encode(params)

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.TIME_LIMIT_CALL, params)
end

function ActivityTimeLimitCallAwardWindow:onGetAward(event)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.TIME_LIMIT_CALL)
	self.activityDetail = activityData.detail
	self.needRed2 = activityData:getRedMarkPartner()
	self.needRed1 = activityData:getRedMarkPoint()

	self:updateNavRed()
	self:updateMissionGroup()

	local awardItems = activityData:getAwardItems()

	xyd.itemFloat(awardItems, nil, , 7000)
end

function LimitAwardItem:ctor(parentGo, parent)
	self.parent_ = parent

	LimitAwardItem.super.ctor(self, parentGo)
end

function LimitAwardItem:getItemId()
	if not self.info_ then
		return 0
	end

	return self.info_.id
end

function LimitAwardItem:initUI()
	LimitAwardItem.super.initUI(self)

	local goTrans = self.go.transform
	self.dragBg_ = goTrans:ComponentByName("e:image", typeof(UIDragScrollView))
	self.awardGroup_ = goTrans:ComponentByName("awardGroup", typeof(UIGrid))
	self.tipsLabel_ = goTrans:ComponentByName("tipsLabel", typeof(UILabel))
	self.awardBtn_ = goTrans:ComponentByName("awardBtn", typeof(UISprite))
	self.awardBtnGrey_ = goTrans:NodeByName("awardBtnGrey").gameObject
	self.awardBtnGreyLabel_ = goTrans:ComponentByName("awardBtnGrey/label", typeof(UILabel))
	self.awardBtnLabel_ = goTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.awardImg_ = goTrans:ComponentByName("awardImg", typeof(UISprite))
	self.valueLabel_ = goTrans:ComponentByName("valueLabel", typeof(UILabel))
	UIEventListener.Get(self.awardBtn_.gameObject).onClick = handler(self, self.onClickAward)
end

function LimitAwardItem:getIndex()
	return self.info_.idx
end

function LimitAwardItem:setInfo(info)
	self.info_ = info
	self.tipsLabel_.text = __(info.tipText, info.point)

	if info.point < info.value then
		info.value = info.point
	end

	self.valueLabel_.text = "(" .. info.value .. "/" .. info.point .. ")"

	xyd.setUISpriteAsync(self.awardImg_, nil, "mission_awarded_" .. xyd.Global.lang)

	self.awardBtnLabel_.text = __("MIDAS_TEXT04")
	self.awardBtnGreyLabel_.text = __("MIDAS_TEXT04")

	if info.value < info.point then
		self.awardBtn_.gameObject:SetActive(false)
		self.awardBtnGrey_:SetActive(true)
	else
		self.awardBtnGrey_:SetActive(false)
		self.awardBtn_.gameObject:SetActive(true)
	end

	if info.is_rewarded and info.is_rewarded == 1 then
		self.awardBtn_.gameObject:SetActive(false)
		self.awardImg_:SetActive(true)
	end

	self.dragBg_.scrollView = self.parent_["scrollView" .. self.info_.type_]

	self:initAwardGroup()
end

function LimitAwardItem:initAwardGroup()
	if not self.hasInitAward_ then
		self.hasInitAward_ = true

		for _, item in ipairs(self.info_.awards) do
			local params = {
				show_has_num = true,
				scale = 0.7962962962962963,
				itemID = item[1],
				num = item[2],
				uiRoot = self.awardGroup_.gameObject,
				dragScrollView = self.parent_["scrollView" .. self.info_.type_]
			}

			xyd.getItemIcon(params)
		end

		self.awardGroup_:Reposition()
	end
end

function LimitAwardItem:onClickAward()
	self.parent_:onClickAward(self.info_.type_, self.info_.id)
end

return ActivityTimeLimitCallAwardWindow
