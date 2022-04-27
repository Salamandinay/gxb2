local BaseWindow = import(".BaseWindow")
local ActivityNewbeeFundAwardWindow = class("ActivityNewbeeFundAwardWindow", BaseWindow)
local ActivityNewbeeFundAwardItem = class("ActivityNewbeeFundAwardItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ActivityNewbeeFundTable = xyd.tables.activityNewbeeFundTable
local json = require("cjson")

function ActivityNewbeeFundAwardWindow:ctor(name, params)
	ActivityNewbeeFundAwardWindow.super.ctor(self, name, params)

	self.isNew_ = params.isNew

	if self.isNew_ then
		ActivityNewbeeFundTable = xyd.tables.activityNewbeeFundTable2
	end
end

function ActivityNewbeeFundAwardWindow:initWindow()
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function ActivityNewbeeFundAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelDes_ = groupAction:ComponentByName("labelDes_", typeof(UILabel))
	local mainGroup = groupAction:NodeByName("mainGroup").gameObject
	self.scrollView = mainGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = mainGroup:NodeByName("scroller/itemGroup").gameObject
	self.awardItem = mainGroup:NodeByName("scroller/activity_year_fund_award_item").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.awardItem, ActivityNewbeeFundAwardItem, self)
end

function ActivityNewbeeFundAwardWindow:initUIComponent(flag)
	self.labelTitle_.text = __("ACTIVITY_YEAR_FUND_AWARD_WINDOW")
	self.labelDes_.text = __("ACTIVITY_YEAR_FUND_AWARD_TIPS")
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_NEWBEE_FUND)
	self.days = self.activityData:getDays()
	self.awards = self.activityData.detail.info.awards or {}

	if not self.activityData then
		return
	end

	local ids = ActivityNewbeeFundTable:getIds()
	local collection = {}

	for i = 1, #ids do
		local id = ids[i]
		local state = 0

		if id <= self.days then
			if self.awards[id] == 1 then
				state = 1
			elseif self.awards[id] == 0 and id < self.days then
				state = 2
			end
		end

		table.insert(collection, {
			id = id,
			state = state
		})
	end

	local pos = 180
	local startTime = self.activityData.detail.info.start_time
	local newTime = xyd.tables.miscTable:getNumber("activity_newbee_fund2_start_time", "value")

	if tonumber(newTime) <= tonumber(startTime) then
		-- Nothing
	elseif self.days <= 15 and self.days > 0 then
		pos = 180 + 140 * math.floor((self.days - 1) / 5) + 4 * (math.floor((self.days - 1) / 5) > 0 and 1 or 0)
	elseif self.days == 0 then
		pos = 180
	else
		pos = 532
	end

	self.wrapContent:setInfos(collection, {
		scrollPos = Vector3(0, pos, 0)
	})
end

function ActivityNewbeeFundAwardWindow:register()
	ActivityNewbeeFundAwardWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_NEWBEE_FUND)

	if activityData then
		-- Nothing
	end
end

function ActivityNewbeeFundAwardWindow:onAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_NEWBEE_FUND then
		return
	end

	self:initUIComponent(true)
end

function ActivityNewbeeFundAwardItem:ctor(go, parent)
	ActivityNewbeeFundAwardItem.super.ctor(self, go, parent)
end

function ActivityNewbeeFundAwardItem:initUI()
	local go = self.go
	self.itemNode = go:NodeByName("itemNode").gameObject
	self.reqBtn = go:ComponentByName("reqBtn", typeof(UITexture))
	self.label_ = go:ComponentByName("label_", typeof(UILabel))

	xyd.setUITextureByNameAsync(self.reqBtn, "activity_year_fund_icon_" .. xyd.Global.lang, true)
	self.reqBtn:AddComponent(typeof(UIDragScrollView))

	UIEventListener.Get(self.reqBtn.gameObject).onClick = function ()
		local cost = ActivityNewbeeFundTable:getCost(self.id)[2]
		local timeStamp = xyd.db.misc:getValue("activity_year_fund_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "activity_year_fund",
				wndType = self.curWindowType_,
				callback = function ()
					local crystal = xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)

					if cost <= crystal then
						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_NEWBEE_FUND, json.encode({
							table_id = self.id
						}))
					else
						xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_CRYSTAL"))
					end
				end,
				text = __("ACTIVITY_YEAR_FUND_LATE_AWARD_TIP", cost)
			})
		else
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_NEWBEE_FUND, json.encode({
				table_id = self.id
			}))
		end
	end
end

function ActivityNewbeeFundAwardItem:updateInfo()
	self.id = self.data.id
	self.state = self.data.state
	local isNew = ActivityNewbeeFundTable:isNew(self.id)

	if self.state == 1 then
		isNew = false
	end

	local awards = ActivityNewbeeFundTable:getAwards(self.id)

	NGUITools.DestroyChildren(self.itemNode.transform)

	local item = xyd.getItemIcon({
		show_has_num = true,
		scale = 0.9537037037037037,
		isShowSelected = false,
		uiRoot = self.itemNode,
		itemID = awards[1],
		num = awards[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		dragScrollView = self.parent.scrollView,
		isNew = isNew
	})

	if ActivityNewbeeFundTable:hasEffect(self.id) then
		item:setEffect(true, "fx_ui_bp_available", {
			effectPos = Vector3(0, 5, 0)
		})
	end

	self.reqBtn:SetActive(false)

	if self.state == 1 then
		item:setChoose(true)
	elseif self.state == 2 then
		self.reqBtn:SetActive(true)

		local flag = xyd.db.misc:getValue("activity_newbee_fund_red_mark_2") or 0

		if tonumber(flag) < self.id then
			xyd.db.misc:setValue({
				key = "activity_newbee_fund_red_mark_2",
				value = self.id
			})
		end
	end

	self.label_.text = __("ACTIVITY_WEEK_DATE", self.id)
end

return ActivityNewbeeFundAwardWindow
