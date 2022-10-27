local ActivityRelayGiftNew = class("ActivityRelayGiftNew", import(".ActivityContent"))
local ActivityRelayGiftItem = class("ActivityRelayGiftItem", import("app.components.CopyComponent"))
local AdvanceIcon = import("app.components.AdvanceIcon")
local CountDown = import("app.components.CountDown")
local json = require("cjson")

function ActivityRelayGiftNew:ctor(parentGO, params)
	ActivityRelayGiftNew.super.ctor(self, parentGO, params)
end

function ActivityRelayGiftNew:getPrefabPath()
	return "Prefabs/Windows/activity/activity_relay_gift_new"
end

function ActivityRelayGiftNew:resizeToParent()
	ActivityRelayGiftNew.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874
end

function ActivityRelayGiftNew:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RELAY_GIFT_NEW)

	dump(self.activityData)

	self.id = xyd.ActivityID.ACTIVITY_RELAY_GIFT_NEW
	self.tempGiftImgIndex = 1

	self:getUIComponent()
	ActivityRelayGiftNew.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityRelayGiftNew:getUIComponent()
	self.trans = self.go
	self.item = self.trans:NodeByName("common_item").gameObject
	self.bg = self.trans:ComponentByName("bg", typeof(UITexture))
	self.imgLogo = self.trans:ComponentByName("imgLogo", typeof(UISprite))
	self.scroller = self.trans:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.drag = self.trans:NodeByName("drag").gameObject
	self.labelTitle = self.trans:ComponentByName("labelTitle", typeof(UILabel))
	self.timeLayout = self.trans:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = self.trans:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.endLabel_ = self.trans:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
end

function ActivityRelayGiftNew:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = json.decode(data.detail)

		if data.activity_id == xyd.ActivityID.ACTIVITY_RELAY_GIFT_NEW then
			local awards = xyd.tables.activityRelayGiftNewTable:getAwards(detail.awarded_id)
			local items = {}

			for _, info in ipairs(awards) do
				local item = {
					item_id = info[1],
					item_num = info[2]
				}

				table.insert(items, item)
			end

			xyd.models.itemFloatModel:pushNewItems(items)
			self:initData()
		end
	end)
	self:registerEvent(xyd.event.RECHARGE, function (event)
		self:initData()
	end)
end

function ActivityRelayGiftNew:initUIComponent()
	CountDown.new(self.timeLabel_, {
		duration = self.activityData.detail.start_time + 604800 - xyd.getServerTime()
	})
	xyd.setUISpriteAsync(self.imgLogo, nil, "logo_lb_" .. xyd.Global.lang)

	self.labelTitle.text = __("ACTIVITY_RELAY_GIFT_TEXT02")
	self.endLabel_.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	self.timeLayout:Reposition()
	self:initData()
end

function ActivityRelayGiftNew:initData()
	self.data = self.activityData:getGiftIDs()

	dump(self.data)

	if not self.items then
		self.items = {}
	end

	self.curIndex = self.activityData:getCurIndex()

	for i = 1, #self.data do
		if not self.items[i] then
			local obj = NGUITools.AddChild(self.itemGroup.gameObject, self.item)

			if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
				local labelGameobjedt = obj:NodeByName("mainGroup/labelTitle").gameObject

				labelGameobjedt:X(-260)

				local awardUILabel = obj:ComponentByName("mainGroup/labelTitle", typeof(UILabel))
				awardUILabel.width = 230
				awardUILabel.height = 24
			end

			self.items[i] = ActivityRelayGiftItem.new(obj, self)
		end

		self.items[i]:setInfo({
			tableID = self.data[i],
			index = i
		})
	end

	self:waitForFrame(3, function ()
		local sp = self.scroller.gameObject:GetComponent(typeof(SpringPanel))
		local initPos = -681
		local panelHeight = self.scroller.gameObject:GetComponent(typeof(UIPanel)).height
		local maxDis = 253 - (panelHeight - 454)
		local maxCanSee = math.floor(panelHeight / 153)
		local dis = initPos + math.min(self.curIndex - 1, 9 - maxCanSee) * 153
		dis = math.min(dis, maxDis)

		sp.Begin(sp.gameObject, Vector3(0, dis, 0), 8)
	end)
end

function ActivityRelayGiftItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	ActivityRelayGiftItem.super.ctor(self, go)
	self:initUI()
end

function ActivityRelayGiftItem:initUI()
	self:getUIComponent()
end

function ActivityRelayGiftItem:getUIComponent()
	self.mainGroup = self.go:NodeByName("mainGroup").gameObject
	self.itemBg = self.mainGroup:ComponentByName("itemBg", typeof(UISprite))
	self.itemGroup = self.mainGroup:NodeByName("itemGroup").gameObject
	self.itemGroupLayout = self.mainGroup:ComponentByName("itemGroup", typeof(UILayout))
	self.labelItemText01 = self.mainGroup:ComponentByName("labelItemText01", typeof(UILabel))
	self.labelItemText02 = self.mainGroup:ComponentByName("labelItemText02", typeof(UILabel))
	self.labelItemLimit = self.mainGroup:ComponentByName("labelItemLimit", typeof(UILabel))
	self.labelTitle = self.mainGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.btnPurchase = self.mainGroup:NodeByName("btnPurchase").gameObject
	self.label = self.btnPurchase:ComponentByName("label", typeof(UILabel))
	self.imgGift = self.go:ComponentByName("imgGift", typeof(UISprite))
	self.imgGun = self.go:ComponentByName("imgGun", typeof(UISprite))
	self.img = self.go:ComponentByName("img", typeof(UISprite))
	self.mask = self.mainGroup:ComponentByName("mask", typeof(UISprite))
	UIEventListener.Get(self.btnPurchase).onClick = handler(self, function ()
		if self.state == 3 then
			xyd.alertTips(__("ACTIVITY_RELAY_GIFT_TEXT01"))

			return
		end

		if self.isFree == true then
			self:buyFreeGiftbag()
		else
			xyd.SdkManager.get():showPayment(self.tableID)
		end
	end)
end

function ActivityRelayGiftItem:setInfo(params)
	if not params then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.tableID = params.tableID
	local freeGiftIDs = self.parent.activityData:getFreeGiftIDs()
	local paidGiftIDs = self.parent.activityData:getPaidGiftIDs()
	local giftIDs = self.parent.activityData:getGiftIDs()
	self.labelTitle.text = __("ACTIVITY_5WEEK_TEXT05", params.index)

	if self.tableID <= #freeGiftIDs then
		self.isFree = true
		self.awards = xyd.tables.activityRelayGiftNewTable:getAwards(self.tableID)

		if self.parent.activityData.detail.awarded_id > 0 and self.tableID <= self.parent.activityData.detail.awarded_id then
			self.state = 1
		elseif giftIDs[self.parent.curIndex] ~= self.tableID then
			self.state = 3
		else
			self.state = 2
		end
	else
		self.isFree = false
		self.giftID = xyd.tables.giftBagTable:getGiftID(self.tableID)
		local awards = xyd.tables.giftTable:getAwards(self.giftID)
		self.awards = {}

		for i = 1, #awards do
			if awards[i][1] ~= 8 and xyd.tables.itemTable:getType(awards[i][1]) ~= 12 then
				table.insert(self.awards, awards[i])
			end
		end

		local charge = self.parent.activityData:getCharge(self.tableID)

		if charge.limit_times <= charge.buy_times then
			self.state = 1
		elseif giftIDs[self.parent.curIndex] ~= self.tableID then
			self.state = 3
		else
			self.state = 2
		end
	end

	if not self.icons then
		self.icons = {}
	end

	local scale = 1
	scale = #self.awards > 4 and 0.49074074074074076 or 0.6203703703703703

	for i = 1, #self.awards do
		local params2 = {
			show_has_num = false,
			notShowGetWayBtn = true,
			uiRoot = self.itemGroup,
			itemID = self.awards[i][1],
			num = self.awards[i][2],
			scale = scale,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent.scroller
		}

		if not self.icons[i] then
			self.icons[i] = xyd.getItemIcon(params2, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.icons[i]:setInfo(params2)
		end

		self.icons[i]:setChoose(self.state <= 0)
	end

	self.itemGroupLayout:Reposition()

	if not self.isFree then
		local charge = self.parent.activityData:getCharge(self.tableID)
		self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", charge.limit_times - charge.buy_times)
		self.labelItemText01.text = __("VIP EXP")
		self.labelItemText02.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.tableID)
		self.label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.tableID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.tableID))

		for i = 1, #paidGiftIDs do
			if paidGiftIDs[i] == self.tableID then
				self.parent.tempGiftImgIndex = i
			end
		end

		dump(paidGiftIDs)
		dump(self.tableID)
		dump(self.parent.tempGiftImgIndex)
	else
		local leftTime = 1

		if self.state == 1 then
			leftTime = 0
		end

		self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", leftTime)
		self.label.text = __("FREE2")
	end

	if self.state == 1 then
		if self.parent.sequence1_ then
			self.parent.sequence1_:Kill(false)

			self.parent.sequence1_ = nil
		end

		if self.parent.sequence2_ then
			self.parent.sequence2_:Kill(false)

			self.parent.sequence2_ = nil
		end

		self.imgGun:SetActive(true)
		xyd.setUISpriteAsync(self.imgGun, nil, "activity_relay_gift_icon_q_1", nil, , true)
		xyd.setUISpriteAsync(self.imgGift, nil, "activity_relay_gift_icon_lb_" .. self.parent.tempGiftImgIndex .. "_a", nil, , true)
		xyd.applyGrey(self.btnPurchase:GetComponent(typeof(UISprite)))
		self.label:ApplyGrey()
		xyd.setTouchEnable(self.btnPurchase, false)
		self.mask:SetActive(false)
	elseif self.state == 2 then
		function self.parent.playAni2_()
			if self.parent.sequence2_ then
				self.parent.sequence2_:Kill(false)

				self.parent.sequence2_ = nil
			end

			self.parent.sequence2_ = self.parent:getSequence()

			self.parent.sequence2_:AppendInterval(1)
			self.parent.sequence2_:AppendCallback(function ()
				xyd.setUISpriteAsync(self.imgGun, nil, "activity_relay_gift_icon_q_2", nil, , true)
				self.parent.playAni1_()
			end)
		end

		function self.parent.playAni1_()
			if self.parent.sequence1_ then
				self.parent.sequence1_:Kill(false)

				self.parent.sequence1_ = nil
			end

			self.parent.sequence1_ = self.parent:getSequence()

			self.parent.sequence1_:AppendInterval(1)
			self.parent.sequence1_:AppendCallback(function ()
				xyd.setUISpriteAsync(self.imgGun, nil, "activity_relay_gift_icon_q_1", nil, , true)
				self.parent.playAni2_()
			end)
		end

		self.imgGun:SetActive(true)
		self.parent.playAni1_()
		xyd.setUISpriteAsync(self.imgGift, nil, "activity_relay_gift_icon_lb_" .. self.parent.tempGiftImgIndex .. "_a", nil, , true)
		xyd.applyOrigin(self.btnPurchase:GetComponent(typeof(UISprite)))
		self.label:ApplyOrigin()
		xyd.setTouchEnable(self.btnPurchase, true)
		self.mask:SetActive(false)
	else
		self.imgGun:SetActive(false)
		xyd.setUISpriteAsync(self.imgGun, nil, "activity_relay_gift_icon_q_1", nil, , true)
		xyd.setUISpriteAsync(self.imgGift, nil, "activity_relay_gift_icon_lb_" .. self.parent.tempGiftImgIndex .. "_b", nil, , true)
		xyd.applyOrigin(self.btnPurchase:GetComponent(typeof(UISprite)))
		self.label:ApplyOrigin()
		xyd.setTouchEnable(self.btnPurchase, true)
		self.mask:SetActive(true)
	end

	if self.tableID == giftIDs[#giftIDs] then
		self.imgGun:SetActive(false)
		self.img:SetActive(false)
	end
end

function ActivityRelayGiftItem:buyFreeGiftbag()
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_RELAY_GIFT_NEW, json.encode({}))
end

return ActivityRelayGiftNew
