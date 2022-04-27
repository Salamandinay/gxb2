local ActivityReturnGiftOptionalWindow = class("ActivityReturnGiftOptionalWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local ReplaceIcon = import("app.components.ReplaceIcon")
local myTable = xyd.tables.activityReturnGiftOptionalTable

function ActivityReturnGiftOptionalWindow:ctor(name, params)
	ActivityReturnGiftOptionalWindow.super.ctor(self, name, params)
end

function ActivityReturnGiftOptionalWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	xyd.db.misc:setValue({
		key = "activity_return_gift_optional_red_time",
		value = xyd.getServerTime()
	})

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN)

	if activityData then
		activityData:setRedMarkState(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_4)
	end
end

function ActivityReturnGiftOptionalWindow:getUIComponent()
	self.group1 = self.window_:NodeByName("group1").gameObject
	self.textLogo = self.group1:ComponentByName("textLogo", typeof(UISprite))
	self.group2 = self.window_:NodeByName("group2").gameObject

	for i = 1, 2 do
		for j = 1, 4 do
			self["optional_item_" .. j .. "_" .. i] = self["group" .. i]:NodeByName("optional_item_" .. j).gameObject
		end

		self["labelVIP_" .. i] = self["group" .. i]:ComponentByName("labelVIP", typeof(UILabel))
		self["labelLimit_" .. i] = self["group" .. i]:ComponentByName("labelLimit", typeof(UILabel))
		self["btnBuy_" .. i] = self["group" .. i]:NodeByName("btnBuy").gameObject
		self["labelPrice_" .. i] = self["btnBuy_" .. i]:ComponentByName("labelPrice", typeof(UILabel))
	end
end

function ActivityReturnGiftOptionalWindow:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "activity_return_gift_optional_" .. xyd.Global.lang)
	self:initTopGroup()

	self.giftBagID_2 = 300
	self.giftBagID_1 = 299

	for i = 1, 2 do
		local giftBagID = self["giftBagID_" .. i]
		self["optionalNum_" .. i] = myTable:getNum(giftBagID)
		self["optionalList_" .. i] = self:getOptionalAwardsList(giftBagID)
		self["selectAwards_" .. i] = {}
		self["selectAwardIndexs_" .. i] = {}
		self["selectIcons_" .. i] = {}
		self["labelVIP_" .. i].text = "+" .. xyd.tables.giftBagTable:getVipExp(giftBagID) .. "VIP EXP"
		self["labelPrice_" .. i].text = xyd.tables.giftBagTextTable:getCurrency(giftBagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(giftBagID)

		self:setBuyLimitInfo(i)
	end
end

function ActivityReturnGiftOptionalWindow:setBuyLimitInfo(group)
	local giftBagID = self["giftBagID_" .. group]
	local charges = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RETURN_GIFT_OPTIONAL).detail_.charges
	local limit = 0

	for _, chargeInfo in pairs(charges) do
		if chargeInfo.table_id == giftBagID then
			limit = chargeInfo.limit_times - chargeInfo.buy_times
		end
	end

	if limit <= 0 then
		xyd.applyChildrenGrey(self["btnBuy_" .. group])
		xyd.setTouchEnable(self["btnBuy_" .. group], false)
		self["labelLimit_" .. group]:SetActive(false)

		self["canSelect_" .. group] = false
	else
		self["labelLimit_" .. group].text = __("BUY_GIFTBAG_LIMIT", limit)
		self["canSelect_" .. group] = true
	end
end

function ActivityReturnGiftOptionalWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, nil, , function ()
		xyd.WindowManager.get():openWindow("activity_resident_return_main_window")
		self:close()
	end)
	local items = {
		{
			show_tips = true,
			hidePlus = false,
			id = xyd.ItemID.MANA
		},
		{
			show_tips = true,
			hidePlus = false,
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)
end

function ActivityReturnGiftOptionalWindow:getOptionalAwardsList(group)
	local list = {}

	for i = 1, 4 do
		local awards = myTable:getAwards(group, i)

		table.insert(list, awards)
	end

	return list
end

function ActivityReturnGiftOptionalWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))

	for i = 1, 2 do
		UIEventListener.Get(self["btnBuy_" .. i]).onClick = function ()
			self:onBuy(i)
		end

		for j = 1, 4 do
			UIEventListener.Get(self["optional_item_" .. j .. "_" .. i]).onClick = function ()
				if self["canSelect_" .. i] then
					self:openSelectWindow(i, j)
				end
			end
		end
	end
end

function ActivityReturnGiftOptionalWindow:openSelectWindow(group, selectIndex)
	local exAwards = {}

	if next(self["selectAwards_" .. group]) then
		for i = 1, self["optionalNum_" .. group] do
			table.insert(exAwards, self["selectAwards_" .. group][i])
		end
	end

	xyd.WindowManager.get():openWindow("activity_optional_award_window", {
		optionalList = self["optionalList_" .. group],
		opNum = self["optionalNum_" .. group],
		curIndex = selectIndex,
		exAwards = exAwards,
		titleText = __("ACTIVITY_RETURN_GIFT_TEXT"),
		callback = function (exAwards, exAwardIndexs)
			for i = 1, self["optionalNum_" .. group] do
				self["selectAwards_" .. group][i] = exAwards[i]
				self["selectAwardIndexs_" .. group][i] = exAwardIndexs[i]

				self:setOptionalIcon(group, i)
			end
		end
	})
end

function ActivityReturnGiftOptionalWindow:setOptionalIcon(group, selectIndex)
	if not self["selectIcons_" .. group][selectIndex] then
		self["selectIcons_" .. group][selectIndex] = ReplaceIcon.new(self["optional_item_" .. selectIndex .. "_" .. group], {
			callback = function ()
				self:openSelectWindow(group, selectIndex)
			end
		})
		local scale = (selectIndex == 1 and 88 or 78) / 108

		self["selectIcons_" .. group][selectIndex]:SetLocalScale(scale, scale, scale)
	end

	self["selectIcons_" .. group][selectIndex]:setIcon(self["selectAwards_" .. group][selectIndex][1], self["selectAwards_" .. group][selectIndex][2], false, true)
end

function ActivityReturnGiftOptionalWindow:onBuy(group)
	local selectNum = 0

	for i = 1, self["optionalNum_" .. group] do
		if self["selectAwardIndexs_" .. group][i] then
			selectNum = selectNum + 1
		end
	end

	if selectNum < self["optionalNum_" .. group] then
		xyd.showToast(__("ACTIVITY_DRAGON_BOAT_AWARD_SELECT_WINDOW_SECOND_TITLE"))

		return
	end

	local msg = messages_pb.activity_return_set_attach_index_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_RETURN_GIFT_OPTIONAL

	for i = 1, self["optionalNum_" .. group] do
		table.insert(msg.indexs, self["selectAwardIndexs_" .. group][i])
	end

	msg.giftbag_id = self["giftBagID_" .. group]

	xyd.Backend.get():request(xyd.mid.ACTIVITY_RETURN_SET_ATTACH_INDEX, msg)
	xyd.SdkManager.get():showPayment(self["giftBagID_" .. group])
end

function ActivityReturnGiftOptionalWindow:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= xyd.ActivityID.ACTIVITY_RETURN_GIFT_OPTIONAL then
		return
	end

	local group = giftBagID == 299 and 1 or 2

	self:setBuyLimitInfo(group)

	for i = 1, self["optionalNum_" .. group] do
		if self["selectIcons_" .. group][i] then
			NGUITools.Destroy(self["selectIcons_" .. group][i].go)
		end
	end

	self["selectAwards_" .. group] = {}
	self["selectAwardIndexs_" .. group] = {}
	self["selectIcons_" .. group] = {}
end

return ActivityReturnGiftOptionalWindow
