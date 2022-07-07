local ActivityContent = import(".ActivityContent")
local AnniversaryGiftbag3 = class("AnniversaryGiftbag3", ActivityContent)
local CountDown = import("app.components.CountDown")

function AnniversaryGiftbag3:ctor(parentGO, params, parent)
	AnniversaryGiftbag3.super.ctor(self, parentGO, params, parent)
	xyd.models.activity:updateRedMarkCount(self.id, function ()
		xyd.db.misc:setValue({
			key = "anniversary_giftbag_last_time_" .. tostring(self.id),
			value = xyd.getServerTime()
		})
	end)
end

function AnniversaryGiftbag3:getPrefabPath()
	return "Prefabs/Windows/activity/anniversary_giftbag3"
end

function AnniversaryGiftbag3:initUI()
	self:getUIComponent()
	AnniversaryGiftbag3.super.initUI(self)
	self:initUIComponent()
end

function AnniversaryGiftbag3:getUIComponent()
	local go = self.go
	self.all_go = self.go:NodeByName("allCon").gameObject
	self.buyNode = self.all_go:NodeByName("buyNode").gameObject
	self.buyBtn = self.all_go:NodeByName("buyNode/btnPurchase").gameObject
	self.curPrice = self.buyBtn:ComponentByName("curPrice", typeof(UILabel))
	self.labelVipExp = self.all_go:ComponentByName("buyNode/labelVipExp", typeof(UILabel))
	self.limitBuyText = self.all_go:ComponentByName("buyNode/limitBuyText", typeof(UILabel))
	self.showNode = self.all_go:NodeByName("showNode").gameObject
	self.modelNode = self.all_go:ComponentByName("modelNode", typeof(UITexture))
	self.modelImg = self.all_go:NodeByName("modelImg")
	self.titleImg = self.all_go:ComponentByName("titleImg", typeof(UISprite))
	self.MAX_ITEM_NUM = 6
	self.giftId = xyd.tables.activityTable:getGiftBag(self.id)[1]
	self.actNode = self.showNode:NodeByName("actNode").gameObject
	self.timerGroup = self.all_go:NodeByName("timerGroup").gameObject
	self.timeLabel = self.all_go:ComponentByName("timerGroup/timeLabel", typeof(UILabel))
	self.endLabel = self.all_go:ComponentByName("timerGroup/endLabel", typeof(UILabel))
end

function AnniversaryGiftbag3:initUIComponent()
	self:setText()
	self:setBtnState()
	self:waitForFrame(1, function ()
		local personEffect_ = xyd.Spine.new(self.modelNode.gameObject)

		personEffect_:setInfo("xunyu_pifu03_lihui01", function ()
			personEffect_:SetLocalScale(0.84, 0.84, 1)
			personEffect_:SetLocalPosition(56, -877 + -18 * self.scale_num_contrary, 0)
			personEffect_:play("animation", 0)
		end)
	end)

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end
end

function AnniversaryGiftbag3:setText()
	self.endLabel.text = __("TEXT_END")
	self.curPrice.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftId)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftId))
	self.labelVipExp.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(self.giftId)) .. " VIP EXP"

	xyd.setUISpriteAsync(self.titleImg, nil, "activity_anniversary_giftbag3_title_" .. xyd.Global.lang, nil, , true)

	self.limitBuyText.text = __("BUY_GIFTBAG_LIMIT", xyd.tables.giftBagTable:getBuyLimit(self.giftId) - self.activityData.detail.charges[1].buy_times)
end

function AnniversaryGiftbag3:resizeToParent()
	AnniversaryGiftbag3.super.resizeToParent(self)
	self:resizePosY(self.showNode, -960, -1055)
	self:resizePosY(self.titleImg, -69, -89)
	self:resizePosY(self.timerGroup, -134, -154)
	self:resizePosY(self.buyNode, -800, -925)
	self:resizePosY(self.modelImg, -590, -628)
end

function AnniversaryGiftbag3:setBtnState()
	local data = self.activityData.detail.charges[1]

	if data.buy_times < data.limit_times then
		xyd.setEnabled(self.buyBtn, true)
	else
		xyd.setEnabled(self.buyBtn, false)
	end
end

function AnniversaryGiftbag3:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	self.activityData:updateInfo()
	xyd.models.activity:updateRedMarkCount(self.id, function ()
		self.activityData.detail.charges[1].buy_times = self.activityData.detail.charges[1].buy_times + 1
	end)
	self:setBtnState()
	self:setText()
end

function AnniversaryGiftbag3:onRegister()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))

	local realGifts = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.giftId))
	local gifts = {}

	for k, v in ipairs(realGifts) do
		if v[1] ~= xyd.ItemID.VIP_EXP then
			table.insert(gifts, v)
		end
	end

	for i = 1, self.MAX_ITEM_NUM do
		local itemNode = self.actNode:NodeByName("item" .. i).gameObject

		if i == 2 and self.id == xyd.ActivityID.ANNIVERSARY_GIFTBAG3_2 then
			itemNode = self.actNode:NodeByName("item2_2").gameObject

			self.actNode:NodeByName("item2"):SetActive(false)
			itemNode:SetActive(true)
		end

		local itemText = itemNode:ComponentByName("text", typeof(UILabel))
		itemText.text = "x" .. gifts[i][2]

		UIEventListener.Get(itemNode).onClick = function ()
			local params = {
				notShowGetWayBtn = true,
				show_has_num = true,
				itemID = gifts[i][1],
				itemNum = gifts[i][2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			xyd.WindowManager.get():openWindow("item_tips_window", params)
		end
	end

	UIEventListener.Get(self.buyBtn).onClick = function ()
		xyd.SdkManager.get():showPayment(self.activityData.detail_.charges[1].table_id)
	end
end

return AnniversaryGiftbag3
