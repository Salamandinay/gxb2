local ActivityOptionalSupply = class("ActivityOptionalSupply", import(".ActivityContent"))
local ReplaceIcon = import("app.components.ReplaceIcon")
local cjson = require("cjson")

function ActivityOptionalSupply:ctor(parentGo, params, parent)
	ActivityOptionalSupply.super.ctor(self, parentGo, params, parent)
end

function ActivityOptionalSupply:getPrefabPath()
	return "Prefabs/Windows/activity/activity_optional_supply"
end

function ActivityOptionalSupply:resizeToParent()
	ActivityOptionalSupply.super.resizeToParent(self)
	self.textLogo:Y(-193 + self.scale_num_ * 41)
	self.groupContent:Y(-683 + self.scale_num_ * 84)
end

function ActivityOptionalSupply:initUI()
	self:getUIComponent()
	ActivityOptionalSupply.super.initUI(self)
	self:layout()
	self:register()
end

function ActivityOptionalSupply:getUIComponent()
	local go = self.go
	self.textLogo = go:ComponentByName("textLogo", typeof(UISprite))
	self.labelTime = self.textLogo:ComponentByName("timeGroup/labelTime", typeof(UILabel))
	self.labelEnd = self.textLogo:ComponentByName("timeGroup/labelEnd", typeof(UILabel))
	self.groupContent = go:NodeByName("groupContent").gameObject

	for i = 1, 4 do
		self["optional_item_" .. i] = self.groupContent:NodeByName("optional_item_" .. i).gameObject
	end

	self.labelLimit = self.groupContent:ComponentByName("labelLimit", typeof(UILabel))
	self.labelVIP = self.groupContent:ComponentByName("labelVIP", typeof(UILabel))
	self.btnBuy = self.groupContent:NodeByName("btnBuy").gameObject
	self.labelPrice = self.btnBuy:ComponentByName("labelPrice", typeof(UILabel))
end

function ActivityOptionalSupply:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "activity_optional_supply_" .. xyd.Global.lang)

	self.labelEnd.text = __("END")
	local lastTime = xyd.tables.giftBagTable:getLastTime(self.activityData.detail_[self.type].charge.table_id)
	local duration = lastTime + self.activityData.detail_[self.type].update_time - xyd.getServerTime()

	if duration < 0 then
		self.labelTime:SetActive(false)
		self.labelEnd:SetActive(false)
	elseif xyd.Global.lang == "fr_fr" then
		self.labelTime.color = Color.New2(4294967295.0)
		self.labelEnd.color = Color.New2(2667547647.0)
		self.labelTime.text = __("END")
		local timeCount = import("app.components.CountDown").new(self.labelEnd)

		timeCount:setInfo({
			function ()
				xyd.WindowManager.get():closeWindow("activity_window")
			end,
			duration = duration
		})
	else
		local timeCount = import("app.components.CountDown").new(self.labelTime)

		timeCount:setInfo({
			function ()
				xyd.WindowManager.get():closeWindow("activity_window")
			end,
			duration = duration
		})
	end

	self.giftBagID = self.activityData.detail_[self.type].charge.table_id
	self.labelVIP.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagID) .. "VIP EXP"
	self.labelPrice.text = xyd.tables.giftBagTextTable:getCurrency(self.giftBagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftBagID)

	self:setBuyLimitInfo()
	self:setItemList()
end

function ActivityOptionalSupply:setBuyLimitInfo()
	local limit = xyd.tables.giftBagTable:getBuyLimit(self.giftBagID) - self.activityData.detail_[self.type].charge.buy_times

	if limit <= 0 then
		xyd.applyChildrenGrey(self.btnBuy)
		xyd.setTouchEnable(self.btnBuy, false)
		self.labelLimit:SetActive(false)
	else
		self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", limit)
	end
end

function ActivityOptionalSupply:setItemList()
	local fixAward = xyd.tables.giftTable:getAwards(self.giftBagID)[2]
	self.fixItem = xyd.getItemIcon({
		show_has_num = true,
		scale = 0.9074074074074074,
		uiRoot = self.optional_item_1:NodeByName("item_root").gameObject,
		itemID = fixAward[1],
		num = fixAward[2]
	})
	self.optionalNum = xyd.tables.activityLevelPushOptionalTable:getNum(self.giftBagID)

	if self.optionalNum == 2 then
		self.optional_item_4:SetActive(false)
		self.optional_item_1:X(-1.5)
		self.optional_item_2:X(-70)
		self.optional_item_2:Y(-1)
		self.optional_item_3:X(67)
		self.optional_item_3:Y(-1)
	end

	self.selectAwards = self.activityData:getSelectAwards(self.giftBagID)
	self.selectAwardIndexs = {}
	self.selectIcons = {}

	if next(self.selectAwards) then
		for i = 1, self.optionalNum do
			self.selectIcons[i] = ReplaceIcon.new(self["optional_item_" .. i + 1], {})

			self.selectIcons[i]:SetLocalScale(0.9074074074074074, 0.9074074074074074, 0.9074074074074074)
			self.selectIcons[i]:setReplaceBtn(false)
			self.selectIcons[i]:setIcon(self.selectAwards[i][1], self.selectAwards[i][2], false, true)
		end
	end

	self.optionalList = {}

	for i = 1, self.optionalNum do
		table.insert(self.optionalList, xyd.tables.activityLevelPushOptionalTable:getAwards(self.giftBagID, i))
	end
end

function ActivityOptionalSupply:register()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))

	UIEventListener.Get(self.btnBuy).onClick = function ()
		self:onBuy()
	end

	for i = 2, 4 do
		UIEventListener.Get(self["optional_item_" .. i]).onClick = function ()
			self:openSelectWindow(i - 1)
		end
	end
end

function ActivityOptionalSupply:openSelectWindow(selectIndex)
	local exAwards = {}

	if next(self.selectAwards) then
		for i = 1, self.optionalNum do
			table.insert(exAwards, self.selectAwards[i])
		end
	end

	xyd.WindowManager.get():openWindow("activity_optional_award_window", {
		optionalList = self.optionalList,
		opNum = self.optionalNum,
		curIndex = selectIndex,
		exAwards = exAwards,
		titleText = __("ACTIVITY_DRAGON_BOAT_AWARD_SELECT_WINDOW_SECOND_TITLE"),
		callback = function (exAwards, exAwardIndexs)
			for i = 1, self.optionalNum do
				self.selectAwards[i] = exAwards[i]
				self.selectAwardIndexs[i] = exAwardIndexs[i]

				self:setOptionalIcon(i)
			end
		end
	})
end

function ActivityOptionalSupply:setOptionalIcon(selectIndex)
	if not self.selectIcons[selectIndex] then
		self.selectIcons[selectIndex] = ReplaceIcon.new(self["optional_item_" .. selectIndex + 1], {
			callback = function ()
				self:openSelectWindow(selectIndex)
			end
		})

		self.selectIcons[selectIndex]:SetLocalScale(0.9074074074074074, 0.9074074074074074, 0.9074074074074074)
	end

	self.selectIcons[selectIndex]:setIcon(self.selectAwards[selectIndex][1], self.selectAwards[selectIndex][2], false, true)
end

function ActivityOptionalSupply:onBuy()
	local selectNum = 0

	for i = 1, self.optionalNum do
		if self.selectAwardIndexs[i] then
			selectNum = selectNum + 1
		end
	end

	if selectNum < self.optionalNum then
		xyd.showToast(__("ACTIVITY_DRAGON_BOAT_AWARD_SELECT_WINDOW_SECOND_TITLE"))

		return
	end

	local msg = messages_pb.set_attach_index_req()
	msg.activity_id = self.id

	for i = 1, self.optionalNum do
		table.insert(msg.indexs, self.selectAwardIndexs[i])
	end

	msg.giftbag_id = self.giftBagID

	xyd.Backend.get():request(xyd.mid.SET_ATTACH_INDEX, msg)
	xyd.SdkManager.get():showPayment(self.giftBagID)
end

function ActivityOptionalSupply:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	self.activityData:setSelectAwards(self.giftBagID, self.selectAwards)
	self:setBuyLimitInfo()

	for i = 1, self.optionalNum do
		self.selectIcons[i]:setReplaceBtn(false)
	end
end

return ActivityOptionalSupply
