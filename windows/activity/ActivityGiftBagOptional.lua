local ActivityContent = import(".ActivityContent")
local ActivityGiftBagOptional = class("ActivityGiftBagOptional", ActivityContent)
local OptionalItem = class("OptionalItem", import("app.components.CopyComponent"))
local SelectItem = class("SelectItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local HeroIcon = import("app.components.HeroIcon")
local ItemIcon = import("app.components.ItemIcon")
local OptionalTable = xyd.tables.activityGiftbagOptionalTable
local GiftBagTextTable = xyd.tables.giftBagTextTable

function ActivityGiftBagOptional:ctor(parentGO, params, parent)
	ActivityGiftBagOptional.super.ctor(self, parentGO, params, parent)
end

function ActivityGiftBagOptional:getPrefabPath()
	return "Prefabs/Windows/activity/activity_giftbag_optional"
end

function ActivityGiftBagOptional:initUI()
	self:getUIComponent()
	ActivityGiftBagOptional.super.initUI(self)
	self:initData()
	self:initUIComponent()
	self:updateContent(1)
end

function ActivityGiftBagOptional:getUIComponent()
	local go = self.go
	self.imgText_ = go:ComponentByName("imgText_", typeof(UISprite))
	self.timeLabel_ = go:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.endLabel_ = go:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
	self.mainGroup = go:NodeByName("mainGroup")
	self.nav = self.mainGroup:NodeByName("nav").gameObject

	for i = 1, 3 do
		self["tab_" .. i] = self.nav:NodeByName("tab_" .. i).gameObject
		self["tabSprite" .. i] = self["tab_" .. i]:GetComponent(typeof(UISprite))
	end

	self.tipsLabel_ = self.mainGroup:ComponentByName("tipsLabel_", typeof(UILabel))
	self.itemGroup = self.mainGroup:NodeByName("itemGroup").gameObject
	self.selectGroup = self.mainGroup:NodeByName("selectGroup").gameObject

	for i = 1, 4 do
		self["selectNode" .. i] = self.selectGroup:NodeByName("item" .. i).gameObject
	end

	local bottomGroup = self.mainGroup:NodeByName("bottomGroup")
	self.vipLabel_ = bottomGroup:ComponentByName("vipLabel_", typeof(UILabel))
	self.buyBtn_ = bottomGroup:NodeByName("buyBtn_").gameObject
	self.buyBtnLabel_ = self.buyBtn_:ComponentByName("button_label", typeof(UILabel))
	self.limitLabel_ = bottomGroup:ComponentByName("limitLabel_", typeof(UILabel))
	self.optionalItem = self.mainGroup:NodeByName("optionalItem").gameObject
	self.selectItem = self.mainGroup:NodeByName("selectItem").gameObject
	self.mask_ = go:NodeByName("mask_").gameObject
end

function ActivityGiftBagOptional:initData()
	self.items = {}
	self.selectIds = {}
	self.giftBagIDs = OptionalTable:getGiftBagIDs()
	self.awards = {}

	for i = 1, #self.giftBagIDs do
		local giftBagID = self.giftBagIDs[i]
		local awards = OptionalTable:getAwards(giftBagID)
		self.selectIds[i] = {}
		self.awards[i] = {}

		for j = 1, #awards do
			local award = awards[j]

			table.insert(self.awards[i], {
				isSelected = false,
				id = j,
				itemID = award[1],
				num = award[2],
				type = xyd.getItemIconType(award[1])
			})
		end
	end

	self.selectItems = {}

	for i = 1, 4 do
		local tmpItem = NGUITools.AddChild(self["selectNode" .. i], self.selectItem)
		self.selectItems[i] = SelectItem.new(tmpItem, self)
	end
end

function ActivityGiftBagOptional:initUIComponent()
	xyd.setUISpriteAsync(self.imgText_, nil, "activity_giftbag_optional_text_" .. xyd.Global.lang, nil, , true)

	self.tipsLabel_.text = __("ACTIVITY_GIFTBAG_OPTIONAL_TEXT01")

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		if xyd.Global.lang == "fr_fr" then
			self.timeLabel_.color = Color.New2(4294901503.0)
			self.endLabel_.color = Color.New2(2667547647.0)
			self.timeLabel_.text = __("END")

			CountDown.new(self.endLabel_, {
				duration = self.activityData:getUpdateTime() - xyd.getServerTime()
			})
		else
			self.endLabel_.text = __("END")

			CountDown.new(self.timeLabel_, {
				duration = self.activityData:getEndTime() - xyd.getServerTime()
			})
		end
	else
		self.timeLabel_:SetActive(false)
		self.endLabel_:SetActive(false)
	end

	for i = 1, 3 do
		local label = self["tab_" .. i]:ComponentByName("label", typeof(UILabel))
		local giftBagID = self.giftBagIDs[i]
		label.text = GiftBagTextTable:getCurrency(giftBagID) .. " " .. GiftBagTextTable:getCharge(giftBagID)
	end
end

function ActivityGiftBagOptional:updateContent(index)
	self:updateState(index)

	local awards = self.awards[index]

	for i = 1, #awards do
		local award = awards[i]

		if not self.items[i] then
			local tmpItem = NGUITools.AddChild(self.itemGroup, self.optionalItem)
			self.items[i] = OptionalItem.new(tmpItem, self)
		end

		self.items[i]:setInfos(award)
	end

	for i = #awards + 1, #self.items do
		self.items[i]:SetActive(false)
	end

	for i = 1, 4 do
		local id = self.selectIds[self.curIndex][i]

		if id and id > 0 then
			self.items[id]:setChoose(true)
			self.selectItems[i]:setInfos(self.awards[self.curIndex][id])
			xyd.setTouchEnable(self["selectNode" .. i], false)
		else
			self.selectItems[i]:SetActive(false)

			self.selectItems[i].state = true

			xyd.setTouchEnable(self["selectNode" .. i], true)
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityGiftBagOptional:updateState(index)
	self.curIndex = index

	for i = 1, 3 do
		if i == index then
			xyd.setUISpriteAsync(self["tabSprite" .. i], nil, "activity_giftbag_optional_tab1")
		else
			xyd.setUISpriteAsync(self["tabSprite" .. i], nil, "activity_giftbag_optional_tab2")
		end
	end

	local giftBagID = self.giftBagIDs[index]
	self.vipLabel_.text = "+" .. xyd.tables.giftBagTable:getVipExp(giftBagID) .. " VIP EXP"
	local charges = self.activityData.detail.charges[index]
	local limit = charges.limit_times - charges.buy_times
	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", limit)

	if limit > 0 then
		xyd.setEnabled(self.buyBtn_, true)
	else
		xyd.setEnabled(self.buyBtn_, false)
	end

	self.buyBtnLabel_.text = GiftBagTextTable:getCurrency(giftBagID) .. " " .. GiftBagTextTable:getCharge(giftBagID)
end

function ActivityGiftBagOptional:onRegister()
	ActivityGiftBagOptional.super.onRegister(self)
	self:registerEvent(xyd.event.GIFTBAG_SET_ATTACH_INDEX, handler(self, self.onPay))
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))

	UIEventListener.Get(self.buyBtn_).onClick = handler(self, self.onBuy)

	for i = 1, 3 do
		UIEventListener.Get(self["tab_" .. i]).onClick = handler(self, function ()
			self:updateContent(i)
		end)
	end

	for i = 1, 4 do
		UIEventListener.Get(self["selectNode" .. i]).onClick = handler(self, function ()
			xyd.alertTips(__("ACTIVITY_GIFTBAG_OPTIONAL_TEXT03"))
		end)
	end
end

function ActivityGiftBagOptional:onBuy()
	for i = 1, 4 do
		if not self.selectIds[self.curIndex][i] or self.selectIds[self.curIndex][i] == 0 then
			xyd.alertTips(__("ACTIVITY_GIFTBAG_OPTIONAL_TEXT03"))

			return
		end
	end

	local msg = messages_pb.giftbag_set_attach_index_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_GIFTBAG_OPTIONAL

	for i = 1, #self.selectIds[self.curIndex] do
		table.insert(msg.indexs, self.selectIds[self.curIndex][i])
	end

	msg.giftbag_id = self.giftBagIDs[self.curIndex]

	xyd.Backend.get():request(xyd.mid.GIFTBAG_SET_ATTACH_INDEX, msg)
end

function ActivityGiftBagOptional:onPay()
	xyd.SdkManager.get():showPayment(self.giftBagIDs[self.curIndex])
end

function ActivityGiftBagOptional:onRecharge()
	for i = 1, 4 do
		self.selectIds[self.curIndex] = {}

		self.selectItems[i]:SetActive(false)

		self.selectItems[i].state = true

		xyd.setTouchEnable(self["selectNode" .. i], true)
	end

	self:updateContent(self.curIndex)
end

function ActivityGiftBagOptional:onClickSelect(id)
	local index = xyd.arrayIndexOf(self.selectIds[self.curIndex], id)

	if index > 0 then
		self.selectItems[index]:SetActive(false)

		self.selectItems[index].state = true
		self.selectIds[self.curIndex][index] = 0

		self.items[id]:setChoose(false)
	else
		local flag = true

		for i = 1, #self.selectItems do
			if self.selectItems[i].state then
				self.mask_:SetActive(true)

				local pos = self:getDesPos(id, i)

				self.selectItems[i]:SetLocalPosition(pos[1], pos[2], 0)

				local award = self.awards[self.curIndex][id]

				self.selectItems[i]:setInfos(award)

				self.selectIds[self.curIndex][i] = id

				self.items[id]:setChoose(true)
				xyd.setTouchEnable(self["selectNode" .. i], false)

				local seq = self:getSequence()

				seq:Append(self.selectItems[i].go.transform:DOLocalMove(Vector3(0, 0, 0), 0.2)):AppendCallback(function ()
					self.mask_:SetActive(false)
				end)

				flag = false

				break
			end
		end

		if flag then
			xyd.alertTips(__("ACTIVITY_GIFTBAG_OPTIONAL_TEXT02"))
		end
	end
end

function ActivityGiftBagOptional:getDesPos(index1, index2)
	local x = -self["selectNode" .. index2].transform.localPosition.x
	local y = -self["selectNode" .. index2].transform.localPosition.y
	x = x - self.selectGroup.transform.localPosition.x + self.itemGroup.transform.localPosition.x
	y = y - self.selectGroup.transform.localPosition.y + self.itemGroup.transform.localPosition.y
	x = x + self.items[index1].go.transform.localPosition.x
	y = y + self.items[index1].go.transform.localPosition.y

	return {
		x,
		y,
		0
	}
end

function ActivityGiftBagOptional:resizeToParent()
	ActivityGiftBagOptional.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.mainGroup:Y(-613 - (p_height - 874))
end

function OptionalItem:ctor(go, parent)
	OptionalItem.super.ctor(self, go)

	self.parent_ = parent
end

function OptionalItem:initUI()
	self.heroIcon = HeroIcon.new(self.go)
	self.itemIcon = ItemIcon.new(self.go)

	UIEventListener.Get(self.go).onLongPress = function (go)
		local params = {
			show_has_num = true,
			itemID = self.itemID,
			itemNum = self.num,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.go).onClick = function (go)
		self.parent_:onClickSelect(self.id)
	end
end

function OptionalItem:setInfos(params)
	self.go:SetActive(true)

	self.id = params.id
	self.itemID = params.itemID
	self.num = params.num
	self.type = params.type
	self.isSelected = params.isSelected

	if self.type == 2 then
		self.heroIcon:SetActive(false)
		self.itemIcon:SetActive(true)

		self.icon = self.itemIcon
	else
		self.heroIcon:SetActive(true)
		self.itemIcon:SetActive(false)

		self.icon = self.heroIcon
	end

	self.icon:setInfo({
		scale = 0.7962962962962963,
		notShowGetWayBtn = true,
		noClick = true,
		itemID = self.itemID,
		num = self.num
	})
	self.icon:setChoose(self.isSelected)
end

function OptionalItem:setChoose(flag)
	self.icon:setChoose(flag)

	self.isSelected = flag
end

function SelectItem:ctor(go, parent)
	SelectItem.super.ctor(self, go)

	self.parent_ = parent
end

function SelectItem:initUI()
	self.deleteBtn_ = self.go:NodeByName("deleteBtn_").gameObject
	self.heroIcon = HeroIcon.new(self.go)
	self.itemIcon = ItemIcon.new(self.go)

	UIEventListener.Get(self.deleteBtn_).onClick = function (go)
		self.parent_:onClickSelect(self.id)
	end

	self.go:SetActive(false)

	self.state = true
end

function SelectItem:setInfos(params)
	self.state = false

	self.go:SetActive(true)

	self.id = params.id
	self.itemID = params.itemID
	self.num = params.num
	self.type = params.type
	self.isSelected = params.isSelected

	if self.type == 2 then
		self.heroIcon:SetActive(false)
		self.itemIcon:SetActive(true)

		self.icon = self.itemIcon
	else
		self.heroIcon:SetActive(true)
		self.itemIcon:SetActive(false)

		self.icon = self.heroIcon
	end

	self.icon:setInfo({
		show_has_num = true,
		notShowGetWayBtn = true,
		scale = 0.7962962962962963,
		itemID = self.itemID,
		num = self.num,
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})
end

function SelectItem:setChoose(flag)
	self.icon:setChoose(flag)

	self.isSelected = flag
end

return ActivityGiftBagOptional
