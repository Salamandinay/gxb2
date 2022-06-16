local RedRidingHood = class("OnlineAward", import(".ActivityContent"))
local RedRidingHoodItem = class("RedRidingHoodItem")
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local GiftBagTable = xyd.tables.giftBagTable
local GiftBagTextTable = xyd.tables.giftBagTextTable
local ActivityTable = xyd.tables.activityRedRidingHoodTable
local GiftTable = xyd.tables.giftTable
local GIFTBAG_TYPE = {
	RECHARGE = 1,
	AWARD = 2
}
local OPENDAYS = 7

function RedRidingHood:ctor(parentGO, params, parent)
	RedRidingHood.super.ctor(self, parentGO, params, parent)
end

function RedRidingHood:getPrefabPath()
	return "Prefabs/Windows/activity/red_riding_hood"
end

function RedRidingHood:initUI()
	self:getUIComponent()
	RedRidingHood.super.initUI(self)
	self:initUIComponent()
	self:register()
	self:updateRedMark()
end

function RedRidingHood:getUIComponent()
	self.imgText_ = self.go:ComponentByName("imgText_", typeof(UISprite))
	self.timeGroup = self.go:NodeByName("timeGroup").gameObject
	self.timeLabel_ = self.go:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.endLabel_ = self.go:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
	self.helpBtn = self.go:NodeByName("helpBtn").gameObject
	self.contentGroup = self.go:NodeByName("contentGroup").gameObject
	self.scroll_ = self.contentGroup:ComponentByName("scroll_", typeof(UIScrollView))
	self.groupItem = self.scroll_:ComponentByName("groupItem", typeof(UIGrid))
	self.cardItem_ = self.go:NodeByName("cardItem_").gameObject
	self.arrow_ = self.contentGroup:NodeByName("arrow_").gameObject
end

function RedRidingHood:initUIComponent()
	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
		self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
	end

	xyd.setUISpriteAsync(self.imgText_, nil, "red_riding_hood_text_" .. xyd.Global.lang, function ()
		self.imgText_:MakePixelPerfect()
	end)
	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel_.text = __("END")
	self.items = {}
	local awards = self.activityData.detail_.item_buys

	for i = 1, #awards do
		local data = {
			table_id = awards[i].table_id,
			buy_times = awards[i].buy_times,
			giftbag_type = GIFTBAG_TYPE.AWARD
		}
		local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.cardItem_.gameObject)
		local item = RedRidingHoodItem.new(tmp, self)

		item:setInfo(data)
		table.insert(self.items, item)
	end

	local chargeDatas = {}
	local charges = self.activityData.detail_.charges

	for i = 1, #charges do
		local data = {
			table_id = charges[i].table_id,
			buy_times = charges[i].buy_times,
			giftbag_type = GIFTBAG_TYPE.RECHARGE
		}

		table.insert(chargeDatas, data)
	end

	table.sort(chargeDatas, function (a, b)
		return GiftBagTable:getVipExp(a.table_id) < GiftBagTable:getVipExp(b.table_id)
	end)

	for i = 1, #chargeDatas do
		local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.cardItem_.gameObject)
		local item = RedRidingHoodItem.new(tmp, self)

		item:setInfo(chargeDatas[i])
		table.insert(self.items, item)
	end

	self.groupItem:Reposition()
	self.scroll_:ResetPosition()

	local timeStamp = xyd.db.misc:getValue("red_riding_hood_arrow" .. xyd.Global.playerID)

	if not timeStamp then
		self.arrow_:SetActive(true)
	else
		self.arrow_:SetActive(false)
	end
end

function RedRidingHood:register()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_RED_RIDING_HOOD_HELP"
		})
	end

	UIEventListener.Get(self.arrow_).onClick = function ()
		self.arrow_:SetActive(false)

		local sequence = DG.Tweening.DOTween.Sequence():OnComplete(function ()
		end)

		sequence:Append(self.groupItem.transform:DOLocalMoveX(-536, 0.4))
		sequence:AppendCallback(function ()
			sequence:Kill(false)

			sequence = nil
		end)
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_RED_RIDING_HOOD_TIP"))

		if event.data.activity_id == xyd.ActivityID.RED_RIDING_HOOD then
			for i = 1, #self.items do
				local item = self.items[i]

				if item.giftbag_type == GIFTBAG_TYPE.AWARD and item.table_id == self.buyIndex then
					item:updateInfo()

					break
				end
			end

			local awards = self.activityData.detail_.item_buys

			for i = 1, #awards do
				if awards[i].table_id == self.buyIndex then
					self.activityData.detail_.item_buys[i].buy_times = self.activityData.detail_.item_buys[i].buy_times + 1

					break
				end
			end
		end
	end)
	self:registerEvent(xyd.event.RECHARGE, function (event)
		xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_RED_RIDING_HOOD_TIP"))

		for i = 1, #self.items do
			local item = self.items[i]

			if item.giftbag_type == GIFTBAG_TYPE.RECHARGE and item.table_id == event.data.giftbag_id then
				item:updateInfo()

				break
			end
		end

		local charges = self.activityData.detail_.charges

		for i = 1, #charges do
			if charges[i].table_id == event.data.giftbag_id then
				self.activityData.detail_.charges[i].buy_times = self.activityData.detail_.charges[i].buy_times + 1
				self.activityData.detail_.charges[i].left_days = 6

				break
			end
		end
	end)

	function self.scroll_.onDragMoving()
		self.arrow_:SetActive(false)
		xyd.db.misc:setValue({
			key = "red_riding_hood_arrow" .. xyd.Global.playerID,
			value = xyd.getServerTime()
		})
	end
end

function RedRidingHood:resizeToParent()
	RedRidingHood.super.resizeToParent(self)
	self.go:Y(-435)

	local height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	if height > 1045 then
		height = 1045
	end

	self.contentGroup:Y(854 - height - 160)
	self.imgText_:Y(270 + (867 - height) * 0.3)
	self.go:ComponentByName("Bg_", typeof(UISprite)):Y(60 + (867 - height) * 0.3)

	if xyd.Global.lang == "de_de" then
		self.timeGroup:X(135)
	end
end

function RedRidingHood:updateRedMark()
	self:waitForTime(0.5, function ()
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.RED_RIDING_HOOD, function ()
			xyd.db.misc:setValue({
				key = "red_riding_hood",
				value = xyd.getServerTime()
			})
		end)
	end)
end

function RedRidingHoodItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function RedRidingHoodItem:getUIComponent()
	self.desLabel_ = self.go:ComponentByName("desLabel_", typeof(UILabel))
	self.limitLabel_ = self.go:ComponentByName("limitLabel_", typeof(UILabel))
	self.expLabel_ = self.go:ComponentByName("expLabel_", typeof(UILabel))
	self.rechargeBtn_ = self.go:NodeByName("rechargeButton").gameObject
	self.rechargeBtnLabel_ = self.rechargeBtn_:ComponentByName("button_label", typeof(UILabel))
	self.buyBtn_ = self.go:NodeByName("buyButton").gameObject
	self.buyBtnLabel_ = self.buyBtn_:ComponentByName("button_label", typeof(UILabel))
	self.buyBtnIcon_ = self.buyBtn_:ComponentByName("icon_", typeof(UISprite))
	self.dailyGroup = self.go:NodeByName("dailyGroup").gameObject
	self.totalLabel_ = self.go:ComponentByName("totalLabel_", typeof(UILabel))
	self.totalGroup = self.go:NodeByName("totalGroup").gameObject
	self.dailyItem_ = self.go:NodeByName("dailyItem_").gameObject
end

function RedRidingHoodItem:initUIComponent()
	self.desLabel_.text = __("ACTIVITY_RED_RIDING_HOOD_TEXT_2")
	self.totalLabel_.text = __("BLACK_CARD_TEXT03")

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
		self.desLabel_.fontSize = 18
		self.desLabel_.spacingY = 1
	end

	if xyd.Global.lang == "ko_kr" then
		self.desLabel_:Y(205)
	end
end

function RedRidingHoodItem:setInfo(data)
	self.table_id = data.table_id
	self.buy_times = data.buy_times
	self.giftbag_type = data.giftbag_type

	if self.giftbag_type == GIFTBAG_TYPE.RECHARGE then
		self.rechargeBtn_:SetActive(true)
		self.buyBtn_:SetActive(false)

		self.buy_limit = GiftBagTable:getBuyLimit(self.table_id)
		self.expLabel_.text = "+ " .. GiftBagTable:getVipExp(self.table_id) .. " VIP EXP"
		self.rechargeBtnLabel_.text = tostring(GiftBagTextTable:getCurrency(self.table_id)) .. " " .. tostring(GiftBagTextTable:getCharge(self.table_id))
		local awards = nil

		if self.table_id == 138 then
			awards = xyd.tables.miscTable:split2Cost("activity_red_riding_hood_awards_1", "value", "|#")
		elseif self.table_id == 317 then
			awards = xyd.tables.miscTable:split2Cost("activity_red_riding_hood_awards_2", "value", "|#")
		elseif self.table_id == 318 then
			awards = xyd.tables.miscTable:split2Cost("activity_red_riding_hood_awards_3", "value", "|#")
		elseif self.table_id == 443 then
			awards = xyd.tables.miscTable:split2Cost("activity_red_riding_hood_awards_4", "value", "|#")
		end

		for i = 1, #awards do
			if awards[i][1] ~= xyd.ItemID.VIP_EXP then
				xyd.getItemIcon({
					show_has_num = true,
					notShowGetWayBtn = true,
					scale = 0.7222222222222222,
					uiRoot = self.totalGroup,
					itemID = awards[i][1],
					num = awards[i][2] * OPENDAYS,
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					dragScrollView = self.parent.scroll_
				})

				local tmp = NGUITools.AddChild(self.dailyGroup.gameObject, self.dailyItem_.gameObject)
				local icon = tmp:ComponentByName("icon_", typeof(UISprite))
				local numLabel = tmp:ComponentByName("numLabel_", typeof(UILabel))
				numLabel.text = "X" .. awards[i][2]

				if awards[i][1] == 940002 then
					xyd.getItemIcon({
						noClick = true,
						scale = 0.4166666666666667,
						uiRoot = icon.gameObject,
						itemID = awards[i][1],
						dragScrollView = self.parent.scroll_
					})
				else
					xyd.setUISpriteAsync(icon, nil, xyd.tables.itemTable:getIcon(awards[i][1]))
				end
			end
		end

		self.totalGroup:GetComponent(typeof(UILayout)):Reposition()
		self.dailyGroup:GetComponent(typeof(UILayout)):Reposition()
	else
		self.rechargeBtn_:SetActive(false)
		self.buyBtn_:SetActive(true)

		self.buy_limit = ActivityTable:getBuyLimit(self.table_id)

		self.expLabel_:SetActive(false)

		local cost = ActivityTable:getCost(self.table_id)
		self.buyBtnLabel_.text = xyd.getRoughDisplayNumber(cost[2])

		xyd.setUISpriteAsync(self.buyBtnIcon_, nil, "icon_" .. cost[1])

		local awards = ActivityTable:getAwards(self.table_id)

		for i = 1, #awards do
			xyd.getItemIcon({
				show_has_num = true,
				notShowGetWayBtn = true,
				scale = 0.7222222222222222,
				uiRoot = self.totalGroup,
				itemID = awards[i][1],
				num = awards[i][2] * OPENDAYS,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scroll_
			})

			local tmp = NGUITools.AddChild(self.dailyGroup.gameObject, self.dailyItem_.gameObject)
			local icon = tmp:ComponentByName("icon_", typeof(UISprite))
			local numLabel = tmp:ComponentByName("numLabel_", typeof(UILabel))
			numLabel.text = "X" .. awards[i][2]

			xyd.setUISpriteAsync(icon, nil, "icon_" .. awards[i][1])
		end

		self.totalGroup:GetComponent(typeof(UILayout)):Reposition()
		self.dailyGroup:GetComponent(typeof(UILayout)):Reposition()
	end

	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", self.buy_limit - self.buy_times)

	if self.buy_limit <= self.buy_times then
		if self.giftbag_type == GIFTBAG_TYPE.RECHARGE then
			xyd.setTouchEnable(self.rechargeBtn_, false)
			xyd.applyChildrenGrey(self.rechargeBtn_)
		else
			xyd.setTouchEnable(self.buyBtn_, false)
			xyd.applyChildrenGrey(self.buyBtn_)
		end
	end
end

function RedRidingHoodItem:updateInfo()
	self.buy_times = self.buy_times + 1
	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", self.buy_limit - self.buy_times)

	if self.buy_limit <= self.buy_times then
		if self.giftbag_type == GIFTBAG_TYPE.RECHARGE then
			xyd.setTouchEnable(self.rechargeBtn_, false)
			xyd.applyChildrenGrey(self.rechargeBtn_)
		else
			xyd.setTouchEnable(self.buyBtn_, false)
			xyd.applyChildrenGrey(self.buyBtn_)
		end
	end
end

function RedRidingHoodItem:registerEvent()
	UIEventListener.Get(self.buyBtn_).onClick = function ()
		local data = {
			id = self.table_id
		}
		local cost = ActivityTable:getCost(self.table_id)

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
			if yes then
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.RED_RIDING_HOOD
				msg.params = json.encode(data)

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

				self.parent.buyIndex = self.table_id
			end
		end)
	end

	UIEventListener.Get(self.rechargeBtn_).onClick = function ()
		xyd.SdkManager.get():showPayment(self.table_id)
	end
end

return RedRidingHood
