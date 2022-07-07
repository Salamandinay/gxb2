local Activity4AnniversarySign = class("Activity4AnniversarySign", import(".ActivityContent"))
local Activity4AnniversarySignItem = class("Activity4AnniversarySignItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function Activity4AnniversarySign:ctor(parentGO, params)
	Activity4AnniversarySign.super.ctor(self, parentGO, params)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT_GIFTBAG, function ()
		xyd.db.misc:setValue({
			key = "activity_4anniversary_sign_viewtime",
			value = xyd.getServerTime()
		})
	end)
end

function Activity4AnniversarySign:getPrefabPath()
	return "Prefabs/Windows/activity/activity_4anniversary_sign"
end

function Activity4AnniversarySign:resizeToParent()
	Activity4AnniversarySign.super.resizeToParent(self)
	self:resizePosY(self.groupGiftbag, -172, -235)
	self:resizePosY(self.logo, 189, 208)
	self:resizePosY(self.groupSign, -657, -734)
	self:resizePosY(self.imgBanner, 263, 250)
	self:resizePosY(self.labelTip1, 263, 250)
	self:resizePosY(self.groupItems, 163, 124)

	self.groupItemsGrid.cellHeight = 152 + 5 * self.scale_num_contrary
end

function Activity4AnniversarySign:initUI()
	self:getUIComponent()
	Activity4AnniversarySign.super.initUI(self)
	self:initData()
	self:initUIComponent()
	self:register()
end

function Activity4AnniversarySign:getUIComponent()
	self.groupGiftbag = self.go:NodeByName("groupGiftbag").gameObject
	self.logo = self.groupGiftbag:ComponentByName("logo", typeof(UISprite))
	self.tabs = self.groupGiftbag:NodeByName("tabs").gameObject

	for i = 1, 4 do
		self["tab" .. i] = self.tabs:NodeByName("tab" .. i).gameObject
		self["tabBg" .. i] = self["tab" .. i]:ComponentByName("bg", typeof(UISprite))
		self["tabLabel" .. i] = self["tab" .. i]:ComponentByName("label", typeof(UILabel))
	end

	self.giftbag = self.groupGiftbag:NodeByName("giftbag").gameObject
	self.labelDesc = self.giftbag:ComponentByName("labelDesc", typeof(UILabel))
	self.labelLimit = self.giftbag:ComponentByName("labelLimit", typeof(UILabel))
	self.labelVipexp = self.giftbag:ComponentByName("labelVipexp", typeof(UILabel))
	self.groupAward = self.giftbag:NodeByName("groupAward").gameObject
	self.btnBuy = self.giftbag:NodeByName("btnBuy").gameObject
	self.originPrice = self.btnBuy:ComponentByName("originPrice", typeof(UILabel))
	self.curPrice = self.btnBuy:ComponentByName("curPrice", typeof(UILabel))
	self.line = self.btnBuy:ComponentByName("line", typeof(UISprite))
	self.groupDiscount = self.giftbag:NodeByName("groupDiscount").gameObject
	self.labelDiscount = self.groupDiscount:ComponentByName("label", typeof(UILabel))
	self.groupSign = self.go:NodeByName("groupSign").gameObject
	self.imgBanner = self.groupSign:NodeByName("imgBanner").gameObject
	self.labelTip1 = self.groupSign:ComponentByName("labelTip1", typeof(UILabel))
	self.labelTip2 = self.groupSign:ComponentByName("labelTip2", typeof(UILabel))
	self.groupItems = self.groupSign:NodeByName("groupItems").gameObject
	self.groupItemsGrid = self.groupSign:ComponentByName("groupItems", typeof(UIGrid))
	self.sign_item = self.groupSign:NodeByName("sign_item").gameObject
end

function Activity4AnniversarySign:initData()
	self.day = self.activityData:getDay()
	self.signTimes = self.activityData:getSignTimes()
	self.giftbagOpenLimit = {}
	local giftbagOpenLimit = xyd.tables.miscTable:split2Cost("activity_4anniversary_sign_giftbag_limit", "value", "|#")

	for u, v in ipairs(giftbagOpenLimit) do
		self.giftbagOpenLimit[v[1]] = v[2]
	end

	self.giftbagIDs = xyd.tables.activityTable:getGiftBag(self.activityData.activity_id)
	self.originPriceText = {}
	self.curTab = 1

	for i, giftbagID in ipairs(self.giftbagIDs) do
		local textIndex = tostring(i + 7)

		if i + 7 < 10 then
			textIndex = "0" .. textIndex
		end

		self.originPriceText[giftbagID] = __("ACTIVITY_4ANIVERSARY_SIGN_TEXT" .. textIndex)

		if self.giftbagOpenLimit[giftbagID] <= self.signTimes then
			self.curTab = i
		end
	end
end

function Activity4AnniversarySign:updateData()
	self.signTimes = self.activityData:getSignTimes()
end

function Activity4AnniversarySign:initUIComponent()
	xyd.setUISpriteAsync(self.logo, nil, "activity_4anniversary_sign_text_" .. xyd.Global.lang, nil, , true)

	self.labelDiscount.text = __("ACTIVITY_4ANIVERSARY_SIGN_TEXT07")
	self.labelTip1.text = __("ACTIVITY_4ANIVERSARY_SIGN_TEXT01")

	self:updateGiftbag()

	self.info = {}
	local signIds = xyd.tables.activity4AnniversarySignTable:getIDs()

	for _, id in ipairs(signIds) do
		table.insert(self.info, id)
	end

	self.items = {}

	for i, id in ipairs(self.info) do
		local tmp = NGUITools.AddChild(self.groupItems, self.sign_item)
		self.items[i] = Activity4AnniversarySignItem.new(tmp, self, id)
	end

	self.groupItemsGrid:Reposition()
	self:updateSign()
end

function Activity4AnniversarySign:updateGiftbag()
	for i = 1, 4 do
		if self.giftbagOpenLimit[self.giftbagIDs[i]] <= self.signTimes then
			self["tabLabel" .. i].text = __("ACTIVITY_4ANIVERSARY_SIGN_TEXT05", self.giftbagOpenLimit[self.giftbagIDs[i]])
		else
			self["tabLabel" .. i].text = __("ACTIVITY_4ANIVERSARY_SIGN_TEXT06", self.signTimes, self.giftbagOpenLimit[self.giftbagIDs[i]])
		end

		if i == self.curTab then
			xyd.setUISpriteAsync(self["tabBg" .. i], nil, "activity_4anniversary_sign_tab_chosen", nil, , true)

			self["tabLabel" .. i].color = Color.New2(2642897407.0)
		else
			xyd.setUISpriteAsync(self["tabBg" .. i], nil, "activity_4anniversary_sign_tab_unchosen", nil, , true)

			self["tabLabel" .. i].color = Color.New2(4126272511.0)
		end
	end

	local giftbagID = self.giftbagIDs[self.curTab]
	local giftID = xyd.tables.giftBagTable:getGiftID(giftbagID) or 0
	self.labelDesc.text = xyd.tables.giftBagTextTable:getName(giftbagID)
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", tostring(self.activityData.detail.charges[self.curTab].limit_times - self.activityData.detail.charges[self.curTab].buy_times))
	self.labelVipexp.text = "+" .. (xyd.tables.giftBagTable:getVipExp(giftbagID) or 0) .. " VIP EXP"
	self.curPrice.text = (xyd.tables.giftBagTextTable:getCurrency(giftbagID) or 0) .. " " .. (xyd.tables.giftBagTextTable:getCharge(giftbagID) or 0)
	self.originPrice.text = self.originPriceText[giftbagID]

	NGUITools.DestroyChildren(self.groupAward.transform)

	local awards = xyd.tables.giftTable:getAwards(giftID) or {}

	for i, award in ipairs(awards) do
		if award[1] ~= xyd.ItemID.VIP_EXP then
			xyd.getItemIcon({
				show_has_num = true,
				notShowGetWayBtn = true,
				scale = 0.7407407407407407,
				uiRoot = self.groupAward.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}, xyd.ItemIconType.ADVANCE_ICON)
		end
	end

	self.groupAward:GetComponent(typeof(UIGrid)):Reposition()

	if self.activityData.detail.charges[self.curTab].limit_times <= self.activityData.detail.charges[self.curTab].buy_times then
		xyd.setEnabled(self.btnBuy.gameObject, false)
	else
		xyd.setEnabled(self.btnBuy.gameObject, true)

		self.line.color = Color.New2(1549556991)
	end
end

function Activity4AnniversarySign:updateSign()
	for i, item in ipairs(self.items) do
		item:update(self.activityData.detail.awarded[item.id])
	end
end

function Activity4AnniversarySign:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		self:updateData()
		self:updateSign()
		self:updateGiftbag()
	end)
	self:registerEvent(xyd.event.RECHARGE, function (event)
		self:updateData()
		self:updateSign()
		self:updateGiftbag()
	end)

	for i = 1, 4 do
		UIEventListener.Get(self["tab" .. i].gameObject).onClick = function ()
			self.curTab = i

			self:updateGiftbag()
		end
	end

	UIEventListener.Get(self.btnBuy).onClick = function ()
		if self.signTimes < self.giftbagOpenLimit[self.giftbagIDs[self.curTab]] then
			xyd.alertTips(__("ACTIVITY_4ANIVERSARY_SIGN_TEXT12", xyd.tables.giftBagTextTable:getName(self.giftbagIDs[self.curTab])))

			return
		end

		xyd.SdkManager.get():showPayment(self.giftbagIDs[self.curTab])
	end
end

function Activity4AnniversarySign:reqSign(id)
	self.curSign = id
	self.activityData.curSign = id

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_4ANNIVERSARY_SIGN, cjson.encode({
		id = id
	}))
end

function Activity4AnniversarySignItem:ctor(go, parent, id)
	self.go = go
	self.parent = parent
	self.id = id
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.labelDay = self.go:ComponentByName("labelDay", typeof(UILabel))
	self.labelSign = self.go:ComponentByName("labelSign", typeof(UILabel))
	self.groupAward = self.go:NodeByName("groupAward").gameObject
	self.mask = self.go:ComponentByName("mask", typeof(UISprite))
	self.frame = self.go:ComponentByName("frame", typeof(UISprite))
	self.redMark = self.go:NodeByName("redMark").gameObject
	self.labelDay.text = __("ACTIVITY_4ANIVERSARY_SIGN_TEXT02", self.id)
	local isShow = xyd.tables.activity4AnniversarySignTable:getIsShow(self.id)

	if isShow == 1 then
		xyd.setUISpriteAsync(self.bg, nil, "activity_4anniversary_sign_item1")
	else
		xyd.setUISpriteAsync(self.bg, nil, "activity_4anniversary_sign_item2")
	end

	self.icons = {}
	local awards = xyd.tables.activity4AnniversarySignTable:getAwards(self.id)

	for i, award in ipairs(awards) do
		self.icons[i] = xyd.getItemIcon({
			show_has_num = true,
			notShowGetWayBtn = true,
			scale = 0.6018518518518519,
			uiRoot = self.groupAward,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self.mask:SetActive(false)

	if self.parent.day < self.id then
		self.labelSign:SetActive(false)
		self.frame:SetActive(false)
		self.redMark:SetActive(false)
	elseif self.id == self.parent.day then
		self.labelSign:SetActive(true)

		self.labelSign.text = __("ACTIVITY_4ANIVERSARY_SIGN_TEXT04")
		self.labelSign.color = Color.New2(796976127)

		xyd.setUISpriteAsync(self.frame, nil, "activity_4anniversary_sign_selected_mark")
		self.redMark:SetActive(true)
	else
		self.labelSign:SetActive(true)

		self.labelSign.text = __("ACTIVITY_4ANIVERSARY_SIGN_TEXT03")
		self.labelSign.color = Color.New2(3947917311.0)

		xyd.setUISpriteAsync(self.frame, nil, "activity_4anniversary_sign_selectable_mark")
		self.redMark:SetActive(false)
	end

	UIEventListener.Get(self.go).onClick = function ()
		if self.awarded == 1 or self.parent.day < self.id then
			return
		end

		if self.id == self.parent.day then
			self.parent:reqSign(self.id)
		else
			local cost = xyd.tables.miscTable:split2Cost("activity_4anniversary_sign_cost", "value", "#")

			xyd.alertYesNo(__("RE_CHECKIN_TIPS", cost[2]), function (yes)
				if yes then
					if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
						xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

						return
					end

					self.parent:reqSign(self.id)
				end
			end)
		end
	end
end

function Activity4AnniversarySignItem:update(awarded)
	self.awarded = awarded

	if self.awarded == 1 then
		self.mask:SetActive(true)

		self.labelSign.text = __("ALREADY_GET_PRIZE")
		self.labelSign.color = Color.New2(796976127)

		self.frame:SetActive(false)
		self.redMark:SetActive(false)

		for _, icon in pairs(self.icons) do
			icon:setChoose(true)
		end
	end
end

return Activity4AnniversarySign
