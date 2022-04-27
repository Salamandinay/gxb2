local NewbeeGachaPoolAwardWindow = class("ActivityTimeLimitCallAwardWindow", import(".BaseWindow"))
local GachaAwardItem = class("GachaAwardItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local json = require("cjson")
local NewbeeGachaTable = xyd.tables.activityNewbeeGachaTable

function NewbeeGachaPoolAwardWindow:ctor(name, params)
	NewbeeGachaPoolAwardWindow.super.ctor(self, name, params)

	self.isNewVersion = params.isNewVersion
end

function NewbeeGachaPoolAwardWindow:initWindow()
	NewbeeGachaPoolAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function NewbeeGachaPoolAwardWindow:getUIComponent()
	local timeStamp = xyd.tables.miscTable:getNumber("activity_newbee_gacha_dropbox_new_time", "value")

	if timeStamp < xyd.getServerTime() then
		self.isNewVersion = true
		NewbeeGachaTable = xyd.tables.activityNewbeeGachaNewTable
	end

	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.scrollView = winTrans:ComponentByName("scroller", typeof(UIScrollView))
	self.awardItem_ = winTrans:NodeByName("scroller/awardItem_").gameObject
	self.itemGroup = winTrans:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.awardItem_, GachaAwardItem, self)
end

function NewbeeGachaPoolAwardWindow:initUIComponent()
	self.titleLabel.text = __("ACTIVITY_NEWBEE_GACHA_TEXT02")
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.NEWBEE_GACHA_POOL)
	local ids = NewbeeGachaTable:getIds()
	local collection = {}

	for i = 1, #ids do
		table.insert(collection, {
			id = ids[i],
			point = activityData.detail.draw_times,
			isCompleted = activityData.detail.awards[i] == 1
		})
	end

	table.sort(collection, function (a, b)
		if a.isCompleted ~= b.isCompleted then
			return xyd.bool2Num(a.isCompleted) < xyd.bool2Num(b.isCompleted)
		else
			return a.id < b.id
		end
	end)
	self.wrapContent:setInfos(collection, {})
end

function NewbeeGachaPoolAwardWindow:register()
	NewbeeGachaPoolAwardWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function NewbeeGachaPoolAwardWindow:onAward(event)
	xyd.models.itemFloatModel:pushNewItems(json.decode(event.data.detail).items)

	local items = self.wrapContent:getItems()

	if self.awardItem then
		self.awardItem:update(nil, {
			isCompleted = 1,
			id = self.awardID,
			point = NewbeeGachaTable:getLimit(self.awardID)
		})
	end
end

function GachaAwardItem:ctor(go, parent)
	GachaAwardItem.super.ctor(self, go, parent)
end

function GachaAwardItem:initUI()
	local goTrans = self.go.transform
	self.itemGroup = goTrans:NodeByName("itemGroup").gameObject
	self.tipsLabel_ = goTrans:ComponentByName("tipsLabel", typeof(UILabel))
	self.awardBtn_ = goTrans:NodeByName("awardBtn").gameObject
	self.awardBtnLabel_ = goTrans:ComponentByName("awardBtn/button_label", typeof(UILabel))
	self.awardImg_ = goTrans:ComponentByName("awardImg", typeof(UISprite))
	self.valueLabel_ = goTrans:ComponentByName("valueLabel", typeof(UILabel))
	self.awardBtnLabel_.text = __("MIDAS_TEXT04")

	xyd.setUISpriteAsync(self.awardImg_, nil, "mission_awarded_" .. xyd.Global.lang)

	UIEventListener.Get(self.awardBtn_).onClick = handler(self, self.reqAward)
end

function GachaAwardItem:updateInfo()
	self.id = self.data.id
	self.point = self.data.point
	self.isCompleted = self.data.isCompleted
	self.limit = NewbeeGachaTable:getLimit(self.id)
	self.valueLabel_.text = "(" .. math.min(self.limit, self.point) .. "/" .. self.limit .. ")"
	self.tipsLabel_.text = __("ACTIVITY_NEWBEE_GACHA_TEXT04", self.limit)

	NGUITools.DestroyChildren(self.itemGroup.transform)

	local awards = NewbeeGachaTable:getAwards(self.id)

	for i = 1, #awards do
		local award = awards[i]
		local item = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7962962962962963,
			uiRoot = self.itemGroup,
			itemID = award[1],
			num = award[2],
			dragScrollView = self.parent.scrollView,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		if self.isCompleted then
			item:setChoose(true)
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

	if self.point < self.limit then
		self.awardBtn_:SetActive(true)
		xyd.setEnabled(self.awardBtn_, false)
	elseif self.isCompleted then
		self.awardBtn_:SetActive(false)
		self.awardImg_:SetActive(true)
	else
		self.awardBtn_:SetActive(true)
		self.awardImg_:SetActive(false)
		xyd.setEnabled(self.awardBtn_, true)
	end
end

function GachaAwardItem:reqAward()
	if self.limit <= self.point and not self.isCompleted then
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.NEWBEE_GACHA_POOL, json.encode({
			table_id = self.id
		}))

		self.parent.awardItem = self
		self.parent.awardID = self.id
	end
end

return NewbeeGachaPoolAwardWindow
