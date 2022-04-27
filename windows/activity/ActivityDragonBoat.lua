local ActivityDragonBoat = class("ActivityDragonBoat", import(".ActivityContent"))
local ActivityDragonBoatItem = class("ActivityDragonBoatItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local ReplaceIcon = import("app.components.ReplaceIcon")
local ActivityDragonBoatTable = xyd.tables.activityDragonBoatTable
local GiftBagTextTable = xyd.tables.giftBagTextTable

function ActivityDragonBoat:ctor(parent, params)
	ActivityDragonBoat.super.ctor(self, parent, params)
end

function ActivityDragonBoat:getPrefabPath()
	return "Prefabs/Windows/activity/activity_dragon_boat"
end

function ActivityDragonBoat:initUI()
	ActivityDragonBoat.super.initUI(self)
	self:getUIComponent()
	self:setText()

	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.labelEnd:SetActive(false)
		self.labelTime:SetActive(false)
	else
		local timeCount = CountDown.new(self.labelTime)

		timeCount:setInfo({
			duration = duration
		})
	end

	self:updateContent()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.DAILY_GIFTBAG_FREE, handler(self, self.onFree))

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_DRAGON_BOAT_HELP"
		})
	end
end

function ActivityDragonBoat:getUIComponent()
	local go = self.go
	self.imgText = go:ComponentByName("imgText", typeof(UISprite))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.labelTime = go:ComponentByName("timeGroup/labelTime", typeof(UILabel))
	self.labelEnd = go:ComponentByName("timeGroup/labelEnd", typeof(UILabel))
	self.labelDesc = go:ComponentByName("labelDesc", typeof(UILabel))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.scrollView = go:ComponentByName("scroller", typeof(UIScrollView))
	self.item = go:NodeByName("item").gameObject
	self.groupContent = go:ComponentByName("scroller/groupContent", typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, self.groupContent, self.item, ActivityDragonBoatItem, self)
end

function ActivityDragonBoat:setText()
	self.labelDesc.text = __("ACTIVITY_DRAGON_BOAT_DESC")
	self.labelEnd.text = __("END")

	xyd.setUISpriteAsync(self.imgText, nil, "activity_dragon_boat_logo_" .. xyd.Global.lang)

	if xyd.Global.lang == "en_en" then
		self.labelDesc.width = 300
		self.labelDesc.spacingY = 3

		self.labelDesc:X(200)
		self.labelDesc:Y(-201)
	elseif xyd.Global.lang == "fr_fr" then
		self.labelDesc:X(210)
		self.labelDesc:Y(-220)
	elseif xyd.Global.lang == "ja_jp" then
		self.labelDesc.spacingY = 3

		self.labelDesc:X(200)
		self.labelDesc:Y(-210)
	elseif xyd.Global.lang == "de_de" then
		self.labelDesc.fontSize = 20
		self.labelDesc.width = 350
		self.labelDesc.spacingY = 5

		self.labelDesc:X(175)
		self.labelDesc:Y(-208)
		self.timeGroup:X(175)
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelEnd.transform:SetSiblingIndex(0)
		self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
	end
end

function ActivityDragonBoat:updateContent()
	local free = self.activityData.detail.free_charge
	local freeId = xyd.tables.miscTable:split2num("activity_chose_gift_free", "value", "|")[1]
	self.sortedDatas = {
		{
			id = freeId,
			times = free.awarded,
			leftTimes = 1 - free.awarded
		}
	}
	local charges = self.activityData.detail.charges

	for i = 1, #charges do
		local data = charges[i]

		table.insert(self.sortedDatas, {
			id = data.table_id,
			times = data.buy_times,
			leftTimes = data.limit_times - data.buy_times
		})
	end

	table.sort(self.sortedDatas, function (a, b)
		if a.leftTimes == 0 and b.leftTimes ~= 0 then
			return false
		elseif a.leftTimes ~= 0 and b.leftTimes == 0 then
			return true
		else
			return a.id < b.id
		end
	end)
	self.wrapContent:setInfos(self.sortedDatas, {})

	self.itemList = self.wrapContent:getItems()
end

function ActivityDragonBoat:updateItems()
	local sortedDatas = self.sortedDatas

	for i = 1, #sortedDatas do
		local item = self.itemList["-" .. tostring(i)]
		local buyTimes = sortedDatas[i].times

		item:updateBuyTimes(buyTimes)
	end
end

function ActivityDragonBoat:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	for i = 1, #self.sortedDatas do
		local id = self.sortedDatas[i].id

		if giftBagID == id then
			self.sortedDatas[i].times = self.sortedDatas[i].times + 1

			break
		end
	end

	self:updateItems()
end

function ActivityDragonBoat:onFree(event)
	local data = event.data
	local items = data.items

	self:itemFloat(items)
	self.activityData:updateInfo({
		awarded = 1
	})

	self.sortedDatas[1].times = self.sortedDatas[1].times + 1

	self:updateItems()
end

function ActivityDragonBoatItem:ctor(go, parent)
	self.isFirstInit = true

	ActivityDragonBoatItem.super.ctor(self, go, parent)
end

function ActivityDragonBoatItem:initUI()
	local group1 = self.go:NodeByName("group1").gameObject
	self.showLayout = group1:ComponentByName("e:Group", typeof(UILayout))
	self.groupAward = group1:NodeByName("e:Group/groupAward").gameObject
	self.groupExAward = group1:NodeByName("e:Group/groupExAward").gameObject
	self.add = group1:NodeByName("e:Group/add").gameObject
	self.labelText01 = group1:ComponentByName("labelText01", typeof(UILabel))
	self.labelText02 = group1:ComponentByName("labelText02", typeof(UILabel))
	self.purchaseBtn = group1:NodeByName("purchaseBtn").gameObject
	self.button_label = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.redMark = self.purchaseBtn:NodeByName("redMark").gameObject

	self.redMark:SetActive(false)

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
		self.button_label.fontSize = 21
	end

	if xyd.Global.lang == "ja_jp" then
		self.button_label.fontSize = 20
	end

	local group2 = self.go:NodeByName("group2").gameObject
	self.labelLimit = group2:ComponentByName("labelLimit", typeof(UILabel))
	self.labelPrice = group2:ComponentByName("labelPrice", typeof(UILabel))
end

function ActivityDragonBoatItem:registerEvent()
	UIEventListener.Get(self.purchaseBtn).onClick = handler(self, self.onExchange)

	xyd.setDragScrollView(self.purchaseBtn, self.parent.scrollView)
end

function ActivityDragonBoatItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info
	self.id = self.data.id
	self.buyTimes = self.data.times
	self.isFree = not GiftBagTextTable:getCurrency(self.id)

	self:setText()

	if self.isFirstInit then
		self:initIcon()
		self:setIcon()

		self.isFirstInit = false
	end

	self:setBtn()
end

function ActivityDragonBoatItem:updateBuyTimes(times)
	if self.buyTimes == times then
		return
	end

	self.buyTimes = times

	if not self.isFree and self.buyTimes < ActivityDragonBoatTable:getLimit(self.id) then
		for i = 1, #self.exAward do
			local item = self.exAwardIcons[i]

			item:setIcon(nil)
		end

		self.exAward = nil
	end

	self:setBtn()
	self:setText()
end

function ActivityDragonBoatItem:setText()
	self.labelText01.text = __("VIP EXP")
	self.labelText02.text = "+" .. __(xyd.tables.giftBagTable:getVipExp(self.id) or 0)

	if not self.isFree then
		self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", ActivityDragonBoatTable:getLimit(self.id) - self.buyTimes)
		self.labelPrice.text = __("ACTIVITY_DRAGON_BOAT_PRICE_2", GiftBagTextTable:getCurrency(self.id) .. " " .. GiftBagTextTable:getCharge(self.id))
	else
		self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", 1 - self.buyTimes)
		self.labelPrice.text = __("ACTIVITY_DRAGON_BOAT_PRICE")
	end
end

function ActivityDragonBoatItem:initIcon()
	self.awardIcon = {}
	local awards = ActivityDragonBoatTable:getAward(self.id)

	if self.isFree then
		awards = self:getFreeFixAward()
	end

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local icon = ReplaceIcon.new(self.groupAward, {
				scrollView = self.parent.scrollView
			})

			icon:SetLocalScale(0.7037037037037037, 0.7037037037037037, 0.7037037037037037)
			icon:setDragScrollView(self.parent.scrollView)
			table.insert(self.awardIcon, icon)
		end
	end

	self.add:X(self.add.transform.localPosition.x + 87 * (#self.awardIcon - 1))
	self.groupExAward:X(self.groupExAward.transform.localPosition.x + 87 * (#self.awardIcon - 1))

	self.exAwardIcons = {}
	local num = ActivityDragonBoatTable:getExAwardNum(self.id)

	if self.isFree then
		num = 1
	end

	for i = 1, num do
		local icon = ReplaceIcon.new(self.groupExAward, {
			scrollView = self.parent.scrollView,
			callback = function ()
				self:openSelectWindow(i)
			end
		})

		icon:SetLocalScale(0.7037037037037037, 0.7037037037037037, 0.7037037037037037)
		icon:setDragScrollView(self.parent.scrollView)
		table.insert(self.exAwardIcons, icon)

		local index = i

		UIEventListener.Get(icon:getGameObject()).onClick = function ()
			if icon.itemID then
				return
			end

			self:openSelectWindow(index)
		end
	end

	if num == 0 then
		self.add:SetActive(false)
	end
end

function ActivityDragonBoatItem:setExAward(exAward)
	self.exAward = exAward
	local msg = messages_pb:get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ENERGY_SUMMON

	xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)

	for i = 1, #exAward do
		local msg1 = messages_pb.get_activity_award_req()
		msg1.activity_id = tonumber(exAward[i][1])
	end
end

function ActivityDragonBoatItem:getFreeFixAward()
	local giftIds = xyd.tables.miscTable:split2num("activity_chose_gift_free", "value", "|")
	local awards = xyd.tables.giftTable:getAwards(giftIds[1])

	table.remove(awards)

	return awards
end

function ActivityDragonBoatItem:setIcon()
	local awards = ActivityDragonBoatTable:getAward(self.id)

	if self.isFree then
		awards = self:getFreeFixAward()
	end

	local count = 1

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = self.awardIcon[count]

			item:setIcon(data[1], data[2])

			count = count + 1
		end
	end

	local limitTimes = ActivityDragonBoatTable:getLimit(self.id)

	if self.isFree then
		limitTimes = 1
	end

	if self.data.leftTimes == 0 then
		self.exAward = self:getAwarded()
	end

	if self.exAward then
		for i = 1, #self.exAward do
			local data = self.exAward[i]
			local item = self.exAwardIcons[i]

			item:setIcon(data[1], data[2])
			item:setReplaceBtn(self.buyTimes < limitTimes)
		end
	end

	self:setBtn()
end

function ActivityDragonBoatItem:getAwarded()
	local data = xyd.models.activity:getActivity(xyd.ActivityID.DRAGON_BOAT)

	if self.isFree then
		local giftId = data.detail.free_charge.gift_id
		local exAwards = xyd.tables.giftTable:getAwards(giftId)
		local exAward = {}

		table.insert(exAward, table.remove(exAwards))

		return exAward
	end

	local indexs = xyd.split(data.detail.self_chosen[tostring(self.id)], "|", true)
	local awards = {}
	local num = ActivityDragonBoatTable:getExAwardNum(self.id)

	for i = 1, num do
		local arr = ActivityDragonBoatTable:getExAward(self.id, i)

		table.insert(awards, arr)
	end

	local exAward = {}

	for i = 1, #indexs do
		table.insert(exAward, awards[i][tonumber(indexs[i])])
	end

	return exAward
end

function ActivityDragonBoatItem:setBtn()
	self.redMark:SetActive(self.isFree and self.buyTimes == 0)

	if not self.isFree and ActivityDragonBoatTable:getLimit(self.id) - self.buyTimes == 0 then
		xyd.applyGrey(self.purchaseBtn:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.purchaseBtn, false)
		self.button_label:ApplyGrey()

		for i = 1, #self.exAwardIcons do
			self.exAwardIcons[i]:setReplaceBtn(false)
		end
	end

	if self.isFree and self.buyTimes == 1 then
		xyd.applyGrey(self.purchaseBtn:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.purchaseBtn, false)
		self.button_label:ApplyGrey()

		for i = 1, #self.exAwardIcons do
			self.exAwardIcons[i]:setReplaceBtn(false)
		end
	end

	local num = ActivityDragonBoatTable:getExAwardNum(self.id)

	if self.isFree then
		num = 1
	end

	if not self.exAward or #self.exAward ~= num then
		self.button_label.text = __("DRAGON_BOAT_SELECT")

		return
	end

	if self.isFree then
		self.button_label.text = __("FREE4")
	else
		self.button_label.text = GiftBagTextTable:getCurrency(self.id) .. " " .. GiftBagTextTable:getCharge(self.id)
	end
end

function ActivityDragonBoatItem:onExchange()
	local num = ActivityDragonBoatTable:getExAwardNum(self.id)

	if self.isFree and self.exAward and #self.exAward == 1 then
		local msg = messages_pb:daily_giftbag_free_req()
		msg.activity_id = xyd.ActivityID.DRAGON_BOAT

		xyd.Backend.get():request(xyd.mid.DAILY_GIFTBAG_FREE, msg)

		return
	end

	if self.exAward and #self.exAward == num then
		xyd.SdkManager.get():showPayment(self.id)
	else
		self:openSelectWindow()
	end
end

function ActivityDragonBoatItem:openSelectWindow(index)
	local arr = {}

	if self.exAward then
		for i = 1, #self.exAward do
			arr[i] = self.exAward[i]
		end
	end

	xyd.WindowManager.get():openWindow("activity_dragon_boat_award_select_window", {
		item = self,
		index = index,
		exAwards = arr,
		isFree = self.isFree
	})
end

return ActivityDragonBoat
