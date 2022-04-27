local ActivityContent = import(".ActivityContent")
local NewFiveStarGiftBag = class("NewFiveStarGiftBag", ActivityContent)
local CountDown = import("app.components.CountDown")
local GiftBagTable = xyd.tables.giftBagTable
local GiftTable = xyd.tables.giftTable
local GiftBagTextTable = xyd.tables.giftBagTextTable

function NewFiveStarGiftBag:ctor(parentGO, params, parent)
	ActivityContent.ctor(self, parentGO, params, parent)
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function NewFiveStarGiftBag:getPrefabPath()
	return "Prefabs/Components/new_five_star_gift"
end

function NewFiveStarGiftBag:initData()
	if self.activityData.detail[self.type] then
		self.table_id = self.activityData.detail[self.type].charge.table_id
		self.data = self.activityData.detail[self.type].charge
	else
		self.table_id = self.activityData.detail.table_id
		self.data = self.activityData.detail
	end

	self.price = GiftBagTable:getPrice(self.table_id)
	self.vip_exp = GiftBagTable:getVipExp(self.table_id)
	self.limit_times = GiftBagTable:getBuyLimit(self.table_id)
end

function NewFiveStarGiftBag:getUIComponent()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UITexture))
	self.mainGroup = go:NodeByName("e:Group/mainGroup")
	self.timeLabel = go:ComponentByName("e:Group/mainGroup/timeLabel", typeof(UILabel))
	self.addExpLabel = go:ComponentByName("e:Group/mainGroup/addExpLabel", typeof(UILabel))
	self.limitLabel = go:ComponentByName("e:Group/mainGroup/limitLabel", typeof(UILabel))
	self.buyBtn = go:NodeByName("e:Group/mainGroup/buyBtn").gameObject
	self.button_label = go:ComponentByName("e:Group/mainGroup/buyBtn/button_label", typeof(UILabel))
	self.itemGroup = go:ComponentByName("e:Group/mainGroup/itemGroup", typeof(UILayout))
	self.imgText01 = go:ComponentByName("e:Group/mainGroup/imgText01", typeof(UISprite))
	self.imgText02 = go:ComponentByName("e:Group/mainGroup/imgText02", typeof(UISprite))
end

function NewFiveStarGiftBag:initUIComponent()
	local ret_time = self:retTime()

	xyd.setUITextureAsync(self.imgBg, "Textures/scenes_web/five_star_gift_bg01")
	xyd.setUISpriteAsync(self.imgText01, nil, "five_star_gift_text01_" .. tostring(xyd.Global.lang), nil, , true)

	if xyd.Global.lang == "ja_jp" then
		self.imgText01.width = 344
		self.imgText01.height = 97

		self.imgText01:Y(94)
		self.addExpLabel:Y(163)
	end

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		self.imgText01.width = 381
		self.imgText01.height = 118
	end

	if xyd.Global.lang == "en_en" then
		self.imgText01.width = 324
		self.imgText01.height = 57

		self.imgText01:Y(154)
		xyd.setUISpriteAsync(self.imgText02, nil, "five_star_gift_text02_" .. tostring(xyd.Global.lang), nil, , true)
	end

	self.button_label.text = tostring(GiftBagTextTable:getCurrency(self.table_id)) .. " " .. tostring(GiftBagTextTable:getCharge(self.table_id))
	self.addExpLabel.text = "+ " .. tostring(self.vip_exp) .. " VIP EXP"
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.limit_times - self.data.buy_times)

	if ret_time > 0 and self.data.buy_times < self.limit_times then
		UIEventListener.Get(self.buyBtn).onClick = function ()
			xyd.SdkManager.get():showPayment(self.table_id)
		end
	else
		self:setBtnState(false)
	end

	if ret_time > 0 then
		local countdown = CountDown.new(self.timeLabel, {
			duration = ret_time
		})
	else
		self.timeLabel:SetActive(false)
	end
end

function NewFiveStarGiftBag:setIcon()
	local giftID = GiftBagTable:getGiftID(self.table_id)
	local awards = GiftTable:getAwards(giftID)

	for i = 1, #awards do
		local cur_data = awards[i]

		if cur_data[1] ~= xyd.ItemID.VIP_EXP then
			local icon = xyd.getItemIcon({
				show_has_num = true,
				itemID = cur_data[1],
				num = cur_data[2],
				uiRoot = self.itemGroup.gameObject,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
			local icon_widget = icon:getGameObject():GetComponent(typeof(UIWidget))

			if #awards == 5 then
				icon:SetLocalScale(83.129 / icon_widget.width, 83.129 / icon_widget.height, 0)

				self.itemGroup.gap = Vector2(17.2, 0)

				self.itemGroup:X(145)
			else
				icon:SetLocalScale(97 / icon_widget.width, 97 / icon_widget.height, 0)
			end
		end
	end
end

function NewFiveStarGiftBag:initUI()
	ActivityContent.initUI(self)
	self:initData()
	self:getUIComponent()
	self:initUIComponent()
	self:setIcon()
end

function NewFiveStarGiftBag:setBtnState(can)
	if not can then
		xyd.setEnabled(self.buyBtn, false)
		self.limitLabel:SetActive(false)
	end
end

function NewFiveStarGiftBag:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if GiftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	if self.limit_times <= self.data.buy_times then
		self:setBtnState(false)
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.limit_times - self.data.buy_times)
end

function NewFiveStarGiftBag:retTime()
	local cur_time = xyd.getServerTime()

	return self:getUpdateTime() - cur_time
end

function NewFiveStarGiftBag:getUpdateTime()
	local updateTime = nil

	if self.data.update_time then
		updateTime = self.data.update_time
	else
		updateTime = 0
	end

	if updateTime == 0 then
		return self.data.end_time
	end

	return updateTime + GiftBagTable:getLastTime(self.table_id)
end

function NewFiveStarGiftBag:returnCommonScreen()
	self.mainGroup:Y(-50)
end

return NewFiveStarGiftBag
