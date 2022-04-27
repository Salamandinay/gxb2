local ActivityContent = import(".ActivityContent")
local ActivityFanPai = class("ActivityFanPai", ActivityContent)
local ActivityFanPaiShowItem = class("ActivityFanPaiItem", import("app.components.BaseComponent"))
local ActivityFanPaiCardItem = class("ActivityFanPaiCardItem", import("app.components.BaseComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local json = require("cjson")
local ActivityFanPaiTable = xyd.tables.activityFanPaiTable
local ShowAwardIndex = {
	1,
	10
}
local ShowItemPositions = {
	{
		pos = Vector3(-265, -42, 0),
		angle = Vector3(0, 0, -4)
	},
	{
		pos = Vector3(-133, -53, 0),
		angle = Vector3(0, 0, 4)
	},
	{
		pos = Vector3(-2, -55, 0),
		angle = Vector3(0, 0, -4)
	},
	{
		pos = Vector3(130, -50, 0),
		angle = Vector3(0, 0, -3)
	},
	{
		pos = Vector3(260, -40, 0),
		angle = Vector3(0, 0, 6)
	},
	{
		pos = Vector3(-265, -42, 0),
		angle = Vector3(0, 0, -4)
	},
	{
		pos = Vector3(-130, -50, 0),
		angle = Vector3(0, 0, 3)
	},
	{
		pos = Vector3(-2, -52, 0),
		angle = Vector3(0, 0, -4)
	},
	{
		pos = Vector3(130, -50, 0),
		angle = Vector3(0, 0, 5)
	},
	{
		pos = Vector3(258, -45, 0),
		angle = Vector3(0, 0, 3)
	}
}

function ActivityFanPai:ctor(parentGO, params, parent)
	ActivityFanPai.super.ctor(self, parentGO, params, parent)
end

function ActivityFanPai:getPrefabPath()
	return "Prefabs/Windows/activity/activity_fanpai"
end

function ActivityFanPai:initUI()
	self:getUIComponent()
	ActivityFanPai.super.initUI(self)
	self:initUIComponent()
	self:initContentGroup()
	self:initBottomNormalGroup()
	self:setContentState(0)
end

function ActivityFanPai:getUIComponent()
	local go = self.go
	self.Bg_ = go:ComponentByName("Bg_", typeof(UITexture))
	self.imgText = go:ComponentByName("imgText", typeof(UITexture))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.backBtn = go:NodeByName("backBtn").gameObject
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.leftTime = go:ComponentByName("timeGroup/leftTime", typeof(UILabel))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.group_1 = self.contentGroup:NodeByName("group_1").gameObject
	self.group_2 = self.contentGroup:NodeByName("group_2").gameObject
	self.bottomGroup = go:NodeByName("bottomGroup").gameObject
	self.labelText1 = self.bottomGroup:ComponentByName("labelText1", typeof(UILabel))
	self.resNode = self.bottomGroup:NodeByName("resNode").gameObject
	self.resIcon = self.resNode:ComponentByName("resIcon", typeof(UISprite))
	self.resNumLabel = self.resNode:ComponentByName("resNumLabel", typeof(UILabel))
	self.resAddBtn_ = self.resNode:NodeByName("resAddBtn_").gameObject
	self.normalGroup = self.bottomGroup:NodeByName("normalGroup").gameObject
	self.labelText2 = self.normalGroup:ComponentByName("labelText2", typeof(UILabel))
	self.cardShowGroup = self.normalGroup:NodeByName("cardShowGroup").gameObject
	self.BigItemNode_ = self.normalGroup:NodeByName("BigItemNode_").gameObject
	self.goBtn_ = self.normalGroup:NodeByName("goBtn_").gameObject
	self.effectNode1_ = self.normalGroup:NodeByName("effectNode1_").gameObject
	self.effectNode2_ = self.normalGroup:NodeByName("effectNode2_").gameObject
	self.gameGroup = self.bottomGroup:NodeByName("gameGroup").gameObject
	self.Bg3_ = self.gameGroup:ComponentByName("Bg3_", typeof(UISprite))
	self.scrollView = self.gameGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.cardPlayGroup = self.gameGroup:NodeByName("scroller/cardPlayGroup").gameObject
	self.cardItem = self.gameGroup:NodeByName("scroller/activity_fanpai_card_item").gameObject
end

function ActivityFanPai:initUIComponent()
	self.ticketID = xyd.tables.miscTable:split2num("activity_fanpai_card_cost", "value", "#")[1]

	xyd.setUITextureByNameAsync(self.imgText, "activity_fanpai_logo_" .. xyd.Global.lang, true)
	xyd.setUISpriteAsync(self.resIcon, nil, xyd.tables.itemTable:getIcon(self.ticketID) .. "_small")
	import("app.components.CountDown").new(self.leftTime, {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	})

	self.labelText1.text = __("ACTIVITY_FANPAI_DESC")
	self.labelText2.text = __("ACTIVITY_FANPAI_DESC_1")
	self.resNumLabel.text = xyd.models.backpack:getItemNumByID(self.ticketID)
	self.goBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("ACTIVITY_FANPAI_GOTO")
end

function ActivityFanPai:initContentGroup()
	local ids = ActivityFanPaiTable:getIds()
	local counts = self.activityData.detail.counts

	for i = 1, #ids / 2 do
		self["showItem_" .. i] = ActivityFanPaiShowItem.new(self.group_1, i, counts[i])
	end

	for i = #ids / 2 + 1, #ids do
		self["showItem_" .. i] = ActivityFanPaiShowItem.new(self.group_2, i, counts[i])
	end

	self:updateShowItems()
end

function ActivityFanPai:initBottomNormalGroup()
	local ids = ActivityFanPaiTable:getIds()

	for i = 1, #ids do
		self["cardItem_" .. i] = ActivityFanPaiCardItem.new(self.cardShowGroup, nil, {
			is_show = true,
			id = i
		})
	end

	self.cardShowGroup:GetComponent(typeof(UILayout)):Reposition()

	local BigAwardID = ActivityFanPaiTable:getBigAwardID()
	local BigAwardData = ActivityFanPaiTable:getAward(BigAwardID)

	xyd.getItemIcon({
		noClick = true,
		scale = 1.1,
		noFrame = true,
		uiRoot = self.BigItemNode_,
		itemID = BigAwardData[1],
		num = BigAwardData[2] * 2
	})

	self.effect_1 = xyd.Spine.new(self.effectNode1_)
	self.effect_2 = xyd.Spine.new(self.effectNode2_)

	self.effect_1:setInfo("activity_fanpai", function ()
		self.effect_1:play("texiao01", 0)
	end)
	self.effect_2:setInfo("activity_fanpai", function ()
		self.effect_2:play("texiao02", 0)
	end)
end

function ActivityFanPai:onRegister()
	ActivityFanPai.super.onRegister(self)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onFanPai))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateResNum))
	self:registerEvent(xyd.event.BOSS_BUY, handler(self, self.onBuyTicket))

	UIEventListener.Get(self.goBtn_).onClick = handler(self, self.initPlayContent)
	UIEventListener.Get(self.resAddBtn_).onClick = handler(self, self.addBtnFunc)

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_FANPAI_HELP"
		})
	end

	UIEventListener.Get(self.backBtn).onClick = function ()
		if self.canFanPai then
			self:setContentState(0)
		end
	end
end

function ActivityFanPai:initPlayContent()
	self:setContentState(1)

	if self.not_first then
		self.wrapContent:resetScrollView()

		return
	else
		self:waitForFrame(1, function ()
			self.cardInfos = {}
			local wrapContent = self.cardPlayGroup:GetComponent(typeof(MultiRowWrapContent))
			self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.cardItem, ActivityFanPaiCardItem, self)
			local ids = ActivityFanPaiTable:getIds()
			local sum = 0

			for i = 1, #ids do
				sum = sum + ActivityFanPaiTable:getLimit(ids[i])
			end

			for i = 1, sum do
				self.cardInfos[i] = {
					id = i
				}
			end

			self:updateCards()

			self.not_first = true
			self.canFanPai = true
		end)
	end
end

function ActivityFanPai:updateCards()
	local posIDs = self.activityData.detail.pos_ids
	local awardIDs = self.activityData.detail.awards
	local cardPairs = {}
	local lastItemIDs = {}

	for i = 1, #posIDs do
		local pos = posIDs[i]
		local awardID = awardIDs[i]

		if cardPairs[awardID] then
			cardPairs[awardID] = cardPairs[awardID] + 1
		else
			cardPairs[awardID] = 1
		end

		if cardPairs[awardID] ~= 0 and cardPairs[awardID] % 2 == 0 then
			self.cardInfos[pos].hasGotten = true
			self.cardInfos[lastItemIDs[awardID]].hasGotten = true
		else
			lastItemIDs[awardID] = pos
		end

		self.cardInfos[pos].awardID = awardID
	end

	self.wrapContent:setInfos(self.cardInfos, {
		keepPosition = true
	})
end

function ActivityFanPai:onFanPai(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.FAN_PAI then
		return
	end

	local detail = json.decode(data.detail)
	local info = detail.info
	local cardItems = self.wrapContent:getItems()
	local len = #info.pos_ids
	local pos_id = info.pos_ids[len]
	local cardItem = cardItems[pos_id % #cardItems] or cardItems[#cardItems]
	local awardIndex = info.awards[len]
	local awardItem = ActivityFanPaiTable:getAward(awardIndex)
	local bigAwardItem = detail.items

	local function callback()
		if bigAwardItem and next(bigAwardItem) then
			xyd.itemFloat(bigAwardItem, nil, , 6000)
			self:updateShowItems()
		end

		self:updateCards()
		self:updateResNum()

		self.canFanPai = true
	end

	cardItem:setAwardItem(awardItem[1], awardItem[2])
	cardItem:playOpenAnimation(callback)
end

function ActivityFanPai:setContentState(value)
	if value == 1 then
		self.gameGroup:SetActive(true)
		self.backBtn:SetActive(true)
		self.contentGroup:SetActive(false)
		self.normalGroup:SetActive(false)
		self.labelText1:Y(self.resNode_y)
		self.resNode:Y(self.resNode_y)
	else
		self.contentGroup:SetActive(true)
		self.normalGroup:SetActive(true)
		self.gameGroup:SetActive(false)
		self.backBtn:SetActive(false)
		self.labelText1:Y(140)
		self.resNode:Y(140)
	end
end

function ActivityFanPai:addBtnFunc()
	if self.activityData:getEndTime() <= xyd.getServerTime() then
		xyd.showToast(__("ACTIVITY_END_YET"))

		return
	end

	local maxNumBeen = self.activityData.detail.buy_times or 0
	local maxNumCanBuy = xyd.tables.miscTable:getNumber("activity_fanpai_buy_limit", "value") - maxNumBeen

	if maxNumCanBuy <= 0 then
		xyd.showToast(__("FULL_BUY_SLOT_TIME"))

		return
	end

	xyd.WindowManager.get():openWindow("item_buy_window", {
		hide_min_max = false,
		item_no_click = false,
		cost = xyd.tables.miscTable:split2num("activity_fanpai_buy_cost", "value", "#"),
		max_num = xyd.checkCondition(maxNumCanBuy == 0, 1, maxNumCanBuy),
		itemParams = {
			num = 1,
			itemID = self.ticketID
		},
		buyCallback = function (num)
			if maxNumCanBuy <= 0 then
				xyd.showToast(__("FULL_BUY_SLOT_TIME"))

				return
			end

			local msg = messages_pb.boss_buy_req()
			msg.activity_id = xyd.ActivityID.FAN_PAI
			msg.num = num

			xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
		end,
		maxCallback = function ()
			xyd.showToast(__("FULL_BUY_SLOT_TIME"))
		end,
		limitText = __("BUY_GIFTBAG_LIMIT", self.activityData.detail.buy_times .. "/" .. xyd.tables.miscTable:getNumber("activity_fanpai_buy_limit", "value"))
	})
end

function ActivityFanPai:onBuyTicket(event)
	local data = event.data
	local num = data.buy_times - self.activityData.detail.buy_times

	xyd.alertItems({
		{
			item_id = self.ticketID,
			item_num = num
		}
	})

	self.activityData.redMark = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.FAN_PAI, function ()
		self.activityData.detail.buy_times = data.buy_times
		self.activityData.redMark = nil
	end)
end

function ActivityFanPai:updateShowItems()
	local ids = ActivityFanPaiTable:getIds()
	local counts = self.activityData.detail.counts

	for i = 1, #ids do
		self["showItem_" .. i]:updateLabel(counts[i])
	end
end

function ActivityFanPai:updateResNum()
	self.resNumLabel.text = xyd.models.backpack:getItemNumByID(self.ticketID)
end

function ActivityFanPai:resizeToParent()
	ActivityFanPai.super.resizeToParent(self)
	self.go:Y(-530)

	if xyd.Global.lang == "zh_tw" then
		self.labelText1.spacingX = 2
		self.labelText2.spacingX = 2
	end

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.Bg_:Y(45 - (p_height - 873) * 0.258)
	self.group_1:Y(325 - (p_height - 873) * 0.315)
	self.group_2:Y(155 - (p_height - 873) * 0.632)
	self.bottomGroup:Y(-158 - (p_height - 873))
	self.gameGroup:Y(165 + (p_height - 873) * 0.4)

	self.Bg3_.height = 700 + (p_height - 873) * 0.685
	self.resNode_y = 470 + (p_height - 873) * 0.75

	self.imgText:Y(436 - (p_height - 873) * 0.1)
	self.timeGroup:Y(366 - (p_height - 873) * 0.1)
end

function ActivityFanPaiCardItem:ctor(parentGO, parent, params)
	self.params = params or {}
	self.parent = parent

	ActivityFanPaiCardItem.super.ctor(self, parentGO)
end

function ActivityFanPaiCardItem:getPrefabPath()
	return "Prefabs/Windows/activity/activity_fanpai_card_item"
end

function ActivityFanPaiCardItem:initGO()
	if self.params.is_show then
		self.go = ResCache.AddGameObject(self.parentGo, self:getPrefabPath())
	else
		self.go = self.parentGo
	end

	local widget = self.go:GetComponent(typeof(UIWidget))

	if widget then
		widget.onDispose = handler(self, self.dispose)
	end
end

function ActivityFanPaiCardItem:initUI()
	ActivityFanPaiCardItem.super.initUI(self)
	self:getUIComponent()
	self:initUIComponent()
end

function ActivityFanPaiCardItem:getUIComponent()
	local go = self.go
	self.bg_ = go:NodeByName("bg_").gameObject
	self.fg_ = go:NodeByName("fg_").gameObject
	self.itemNode_ = go:NodeByName("itemNode_").gameObject
	self.selectGroup = go:NodeByName("selectGroup").gameObject
	self.mask_ = self.selectGroup:NodeByName("mask_").gameObject
end

function ActivityFanPaiCardItem:initUIComponent()
	if self.params.is_show then
		self:initShow()
	else
		self:initNormal()
	end

	self.go:SetLocalScale(0.86, 0.86, 0.86)
end

function ActivityFanPaiCardItem:initShow()
	xyd.setTouchEnable(self.bg_, false)

	local id = self.params.id

	if id == ShowAwardIndex[1] or id == ShowAwardIndex[2] then
		local BigAwardID = ActivityFanPaiTable:getBigAwardID()
		local BigAwardData = ActivityFanPaiTable:getAward(BigAwardID)

		xyd.getItemIcon({
			noClick = true,
			noFrame = true,
			uiRoot = self.itemNode_,
			itemID = BigAwardData[1],
			num = BigAwardData[2]
		})
	end
end

function ActivityFanPaiCardItem:initNormal()
	xyd.setDragScrollView(self.go, self.parent.scrollView)
	xyd.setDragScrollView(self.mask_, self.parent.scrollView)

	UIEventListener.Get(self.go).onClick = function ()
		if not self.parent.canFanPai or self.awardID then
			return
		end

		local cost = xyd.tables.miscTable:split2num("activity_fanpai_card_cost", "value", "#")

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alert(xyd.AlertType.TIPS, __("FANPAI_TICKETS_NOT_ENOUGH"))

			return
		end

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.FAN_PAI, json.encode({
			pos_id = self.id
		}))

		self.parent.canFanPai = false
	end

	self.hasGotten = false
end

function ActivityFanPaiCardItem:update(wrapIndex, index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info

	self:updateInfo()
end

function ActivityFanPaiCardItem:updateInfo()
	self.id = self.data.id
	self.awardID = self.data.awardID
	self.hasGotten = self.data.hasGotten or false

	self.bg_:SetActive(true)
	self.fg_:SetActive(false)

	self.bg_.transform.localScale = Vector3(1, 1, 0)

	NGUITools.DestroyChildren(self.itemNode_.transform)

	if self.awardID then
		local award = ActivityFanPaiTable:getAward(self.awardID)

		self:setAwardItem(award[1], award[2])
		self.fg_:SetActive(true)
		self.bg_:SetActive(false)
	end

	self:SetSelected(self.hasGotten)
end

function ActivityFanPaiCardItem:setAwardItem(itemID, num)
	local scale = 0.9

	if xyd.tables.itemTable:getType(itemID) == xyd.ItemType.HERO_DEBRIS then
		scale = 1
	end

	xyd.getItemIcon({
		noFrame = true,
		uiRoot = self.itemNode_,
		itemID = itemID,
		num = num,
		scale = scale,
		dragScrollView = self.parent.scrollView
	})
end

function ActivityFanPaiCardItem:playOpenAnimation(callback)
	self.fg_:SetActive(true)

	local sequence = self:getSequence(callback)
	local time = 0.3

	self.bg_:SetLocalScale(1, 1, 0)
	self.fg_:SetLocalScale(0, 1, 0)
	self.itemNode_:SetLocalScale(0, 1, 0)
	sequence:Append(self.bg_.transform:DOScaleX(0, time)):Insert(time, self.fg_.transform:DOScaleX(1, time)):Insert(time, self.itemNode_.transform:DOScaleX(1, time))
end

function ActivityFanPaiCardItem:SetSelected(value)
	self.selectGroup:SetActive(value)
end

function ActivityFanPaiShowItem:ctor(parentGO, id)
	self.id = id

	ActivityFanPaiShowItem.super.ctor(self, parentGO)
end

function ActivityFanPaiShowItem:getPrefabPath()
	return "Prefabs/Windows/activity/activity_fanpai_show_item"
end

function ActivityFanPaiShowItem:initUI()
	ActivityFanPaiShowItem.super.initUI(self)
	self:getUIComponent()
	self:initUIComponent()
end

function ActivityFanPaiShowItem:getUIComponent()
	local go = self.go
	self.Bg1_ = self.go:ComponentByName("Bg1_", typeof(UISprite))
	self.itemNode_ = go:NodeByName("itemNode_").gameObject
	self.labelLimit = go:ComponentByName("labelLimit", typeof(UILabel))
end

function ActivityFanPaiShowItem:initUIComponent()
	self.limit = ActivityFanPaiTable:getLimit(self.id)
	local award = ActivityFanPaiTable:getAward(self.id)
	local item = xyd.getItemIcon({
		noClickSelected = true,
		scale = 0.7,
		noFrame = true,
		uiRoot = self.itemNode_,
		itemID = award[1],
		num = award[2]
	})
	self.go.transform.localPosition = ShowItemPositions[self.id].pos
	self.go.transform.localEulerAngles = ShowItemPositions[self.id].angle
end

function ActivityFanPaiShowItem:updateLabel(count)
	self.labelLimit.text = count .. "/" .. self.limit
end

return ActivityFanPai
