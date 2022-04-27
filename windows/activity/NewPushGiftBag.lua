local ActivityContent = import(".ActivityContent")
local NewPushGiftBag = class("NewPushGiftBag", ActivityContent)
local GiftTable = xyd.tables.giftTable
local GiftBagTable = xyd.tables.giftBagTable
local GiftBagTextTable = xyd.tables.giftBagTextTable
local partnerModelID = {
	"school_practise_degula",
	"school_practise_caocao",
	"school_practise_zhitian",
	"school_practise_zhugeliang",
	"school_practise_luxifa",
	"school_practise_mijiale"
}

function NewPushGiftBag:ctor(parentGO, params, parent)
	NewPushGiftBag.super.ctor(self, parentGO, params, parent)
end

function NewPushGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/new_push_giftbag"
end

function NewPushGiftBag:initUI()
	self:getUIComponent()
	NewPushGiftBag.super.initUI(self)
	self:initData()
	self:initUIComponent()
	self:inititems()
	self:initContent()
	self:updateContent()

	UIEventListener.Get(self.buyButton).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function NewPushGiftBag:initData()
	if self.id == xyd.ActivityID.MAGIC_DUST_PUSH_GIFTBGA then
		self.type_ = 1
	elseif self.id == xyd.ActivityID.GRADE_STONE_PUSH_GIFTBAG then
		self.type_ = 2
	elseif self.id == xyd.ActivityID.PET_STONE_PUSH_GIFTBAG then
		self.type_ = 3
	elseif self.id == xyd.ActivityID.ACADEMY_ASSESSMENT_PUSH_GIFTBAG then
		self.type_ = 4
	end

	self.giftBagID = self.activityData.detail.table_id or self.activityData.detail[self.type].charge.table_id
end

function NewPushGiftBag:getUIComponent()
	local go = self.go
	self.Bg_ = go:ComponentByName("Bg_", typeof(UITexture))
	self.textBg_ = go:ComponentByName("textBg_", typeof(UITexture))
	self.bottomBg_ = go:ComponentByName("bottomBg_", typeof(UITexture))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.partnerNode = go:NodeByName("partnerNode").gameObject
	self.timeBg_ = self.timeGroup:ComponentByName("timeBg_", typeof(UITexture))
	self.textLayout = self.timeGroup:ComponentByName("textLayout", typeof(UILayout))
	self.timeLabel_ = self.timeGroup:ComponentByName("textLayout/timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("textLayout/endLabel_", typeof(UILabel))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.contentBg_ = self.contentGroup:ComponentByName("contentBg_", typeof(UITexture))
	self.itemGroup = self.contentGroup:NodeByName("itemGroup").gameObject
	self.itemLayout = self.itemGroup:GetComponent(typeof(UILayout))
	self.expLabel_ = self.contentGroup:ComponentByName("expLabel_", typeof(UILabel))
	self.limitLabel_ = self.contentGroup:ComponentByName("limitLabel_", typeof(UILabel))
	self.buyButton = self.contentGroup:NodeByName("buyButton").gameObject
	self.buyButton_sprite = self.buyButton:GetComponent(typeof(UISprite))
	self.button_label = self.buyButton:ComponentByName("button_label", typeof(UILabel))
end

function NewPushGiftBag:initUIComponent()
	local type_ = self.type_

	xyd.setUITextureByNameAsync(self.timeBg_, "new_push_giftbag_timeBg0" .. type_, false)

	if self.id == xyd.ActivityID.ACADEMY_ASSESSMENT_PUSH_GIFTBAG then
		self.assessment_type = GiftBagTable:getGiftType(self.giftBagID) - 63
		type_ = self.type_ .. "_" .. self.assessment_type
		self.partnerModel = xyd.Spine.new(self.partnerNode)

		self.partnerModel:setInfo(partnerModelID[self.assessment_type], function ()
			self.partnerModel:play("texiao01", 0)
		end)
	else
		xyd.setUITextureByNameAsync(self.bottomBg_, "new_push_giftbag_bottom0" .. type_, true)
	end

	xyd.setUITextureByNameAsync(self.Bg_, "new_push_giftbag_bg0" .. type_, false)
	xyd.setUITextureByNameAsync(self.textBg_, "new_push_giftbag_text0" .. type_ .. "_" .. xyd.Global.lang, true)
	xyd.setUITextureByNameAsync(self.contentBg_, "new_push_giftbag_frame0" .. type_, false)

	self.endLabel_.text = __("END")
	self.expLabel_.text = "+" .. GiftBagTable:getVipExp(self.giftBagID) .. " VIP EXP"
	self.button_label.text = GiftBagTextTable:getCurrency(self.giftBagID) .. " " .. GiftBagTextTable:getCharge(self.giftBagID)

	import("app.components.CountDown").new(self.timeLabel_, {
		duration = self:getUpdateTime()
	})
	self.textLayout:Reposition()
end

function NewPushGiftBag:inititems()
	self.items = {}
	local awards = GiftTable:getAwards(self.giftBagID)

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local params = {
				show_has_num = true,
				uiRoot = self.itemGroup,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}
			local item = xyd.getItemIcon(params)

			table.insert(self.items, item)
		end
	end
end

function NewPushGiftBag:initContent()
	local activityID = self.id
	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	if activityID == xyd.ActivityID.MAGIC_DUST_PUSH_GIFTBGA then
		self.textBg_:SetLocalPosition(120, 378, 0)
		self.timeGroup:SetLocalPosition(135, 235, 0)
		self.contentGroup:SetLocalPosition(140, -38, 0)
		self.itemGroup:SetLocalPosition(-5, 50, 0)
		self.expLabel_:SetLocalPosition(-5, 135, 0)
		self.limitLabel_:SetLocalPosition(-5, -40, 0)
		self.buyButton:SetLocalPosition(-3, -105, 0)

		self.contentBg_.width = 370
		self.contentBg_.height = 454

		if xyd.Global.lang == "de_de" then
			self.timeBg_.width = 340

			self.textLayout:X(-25)
		else
			self.timeBg_.width = 264
		end

		self.buyButton_sprite.width = 208
		self.buyButton_sprite.height = 70
		self.timeLabel_.fontSize = 24
		self.endLabel_.fontSize = 24
		self.expLabel_.fontSize = 22
		self.limitLabel_.fontSize = 20
		self.timeLabel_.color = Color.New2(2986279167.0)
		self.timeLabel_.effectStyle = UILabel.Effect.Outline8
		self.timeLabel_.effectColor = Color.New2(959734783)
		self.endLabel_.color = Color.New2(4294967295.0)
		self.endLabel_.effectStyle = UILabel.Effect.Outline8
		self.endLabel_.effectColor = Color.New2(959734783)
		self.expLabel_.color = Color.New2(3006283519.0)
		self.limitLabel_.color = Color.New2(2404924927.0)

		self.textBg_:Y(378 - (p_height - 867) / 2)
		self.bottomBg_:Y(-345 + 867 - p_height)
		self.timeGroup:Y(235 - (p_height - 867) / 2)
		self.contentGroup:Y(-45 - (p_height - 867) / 2)
		self.Bg_:Y((1045 - p_height) / 2)

		self.itemLayout.gap = Vector2(28, 0)

		self.itemLayout:Reposition()
	elseif activityID == xyd.ActivityID.GRADE_STONE_PUSH_GIFTBAG then
		self.textBg_:SetLocalPosition(152, 408, 0)
		self.timeGroup:SetLocalPosition(157, 300, 0)
		self.contentGroup:SetLocalPosition(145, -10, 0)
		self.itemGroup:SetLocalPosition(15, 120, 0)
		self.expLabel_:SetLocalPosition(15, -35, 0)
		self.limitLabel_:SetLocalPosition(15, 0, 0)
		self.buyButton:SetLocalPosition(15, -120, 0)

		self.contentBg_.width = 361
		self.contentBg_.height = 565

		if xyd.Global.lang == "de_de" then
			self.timeBg_.width = 298

			self.textLayout:X(-25)
		else
			self.timeBg_.width = 248
		end

		self.buyButton_sprite.width = 197
		self.buyButton_sprite.height = 64
		self.timeLabel_.fontSize = 20
		self.endLabel_.fontSize = 20
		self.expLabel_.fontSize = 20
		self.limitLabel_.fontSize = 20
		self.timeLabel_.color = Color.New2(2134198783)
		self.endLabel_.color = Color.New2(2134198783)
		self.expLabel_.color = Color.New2(964090879)
		self.expLabel_.effectStyle = UILabel.Effect.Outline8
		self.expLabel_.effectColor = Color.New2(4294967295.0)
		self.limitLabel_.color = Color.New2(3762979583.0)
		self.limitLabel_.effectStyle = UILabel.Effect.Outline8
		self.limitLabel_.effectColor = Color.New2(4294967295.0)

		self.textBg_:Y(410 - (p_height - 867) / 6)
		self.bottomBg_:Y(-345 + 867 - p_height)
		self.timeGroup:Y(300 - (p_height - 867) / 4)
		self.contentGroup:Y(-20 - (p_height - 867) / 3)

		for i = 1, #self.items do
			self.items[i]:setScale(0.9074074074074074)
		end

		self.itemLayout.gap = Vector2(38, 0)

		self.itemLayout:Reposition()
	elseif activityID == xyd.ActivityID.PET_STONE_PUSH_GIFTBAG then
		local offset = 0

		if xyd.Global.lang == "ja_jp" then
			offset = -20
		end

		self.textBg_:SetLocalPosition(152, 410, 0)
		self.timeGroup:SetLocalPosition(154, 310 + offset, 0)
		self.contentGroup:SetLocalPosition(135, 10, 0)
		self.expLabel_:SetLocalPosition(15, -100, 0)
		self.limitLabel_:SetLocalPosition(15, -60, 0)
		self.buyButton:SetLocalPosition(15, -170, 0)

		self.contentBg_.width = 404
		self.contentBg_.height = 535

		if xyd.Global.lang == "de_de" then
			self.timeBg_.width = 298

			self.textLayout:X(-25)
		else
			self.timeBg_.width = 248
		end

		self.buyButton_sprite.width = 197
		self.buyButton_sprite.height = 64
		self.timeLabel_.fontSize = 20
		self.endLabel_.fontSize = 20
		self.expLabel_.fontSize = 20
		self.limitLabel_.fontSize = 20
		self.timeLabel_.color = Color.New2(2134198783)
		self.endLabel_.color = Color.New2(2134198783)
		self.expLabel_.color = Color.New2(964090879)
		self.expLabel_.effectStyle = UILabel.Effect.Outline8
		self.expLabel_.effectColor = Color.New2(4294967295.0)
		self.limitLabel_.color = Color.New2(3762979583.0)
		self.limitLabel_.effectStyle = UILabel.Effect.Outline8
		self.limitLabel_.effectColor = Color.New2(4294967295.0)

		self.textBg_:Y(410 - (p_height - 867) / 6)
		self.bottomBg_:Y(-405 + 867 - p_height)
		self.timeGroup:Y(310 + offset - (p_height - 867) / 3)
		self.contentGroup:Y(10 - (p_height - 867) / 3)

		for i = 1, #self.items do
			self.items[i]:setScale(0.9074074074074074)
		end

		if #self.items == 3 then
			self.itemLayout.enabled = false

			self.items[1]:SetLocalPosition(0, 115, 0)
			self.items[2]:SetLocalPosition(63, 0, 0)
			self.items[3]:SetLocalPosition(-63, 0, 0)
			self.itemGroup:SetLocalPosition(15, 35, 0)
		elseif #self.items == 4 then
			self.itemLayout.enabled = false

			self.items[1]:SetLocalPosition(-63, 115, 0)
			self.items[2]:SetLocalPosition(63, 115, 0)
			self.items[3]:SetLocalPosition(63, 0, 0)
			self.items[4]:SetLocalPosition(-63, 0, 0)
			self.itemGroup:SetLocalPosition(15, 35, 0)
		else
			self.itemLayout.gap = Vector2(28, 0)

			self.itemLayout:Reposition()
			self.itemGroup:SetLocalPosition(15, 85, 0)
		end
	elseif activityID == xyd.ActivityID.ACADEMY_ASSESSMENT_PUSH_GIFTBAG then
		self.bottomBg_:SetActive(false)
		self.textBg_:SetLocalPosition(150, 380, 0)
		self.timeGroup:SetLocalPosition(155, 260, 0)
		self.contentGroup:SetLocalPosition(155, -40, 0)
		self.expLabel_:SetLocalPosition(0, -120, 0)
		self.limitLabel_:SetLocalPosition(0, -80, 0)
		self.buyButton:SetLocalPosition(0, -180, 0)

		self.contentBg_.width = 322
		self.contentBg_.height = 531

		if xyd.Global.lang == "de_de" then
			self.timeBg_.width = 340

			self.textLayout:X(-20)
		else
			self.timeBg_.width = 326
		end

		self.timeBg_.height = 32
		self.buyButton_sprite.width = 208
		self.buyButton_sprite.height = 70
		self.timeLabel_.fontSize = 22
		self.endLabel_.fontSize = 22
		self.expLabel_.fontSize = 24
		self.limitLabel_.fontSize = 24
		self.timeLabel_.color = Color.New2(4294967295.0)
		self.timeLabel_.effectStyle = UILabel.Effect.Outline8
		self.endLabel_.color = Color.New2(4294967295.0)
		self.endLabel_.effectStyle = UILabel.Effect.Outline8
		self.expLabel_.color = Color.New2(964090879)
		self.expLabel_.effectStyle = UILabel.Effect.Outline8
		self.expLabel_.effectColor = Color.New2(4294967295.0)
		self.limitLabel_.color = Color.New2(3762979583.0)
		self.limitLabel_.effectStyle = UILabel.Effect.Outline8
		self.limitLabel_.effectColor = Color.New2(4294967295.0)

		if self.assessment_type == 1 then
			self.partnerModel:SetLocalPosition(-40, -620, 0)
			self.partnerModel:SetLocalScale(0.95, 0.95, 0.95)

			self.timeLabel_.effectColor = Color.New2(3545533183.0)
			self.endLabel_.effectColor = Color.New2(3545533183.0)
		elseif self.assessment_type == 2 then
			self.partnerModel:SetLocalPosition(-220, -1060, 0)
			self.partnerModel:SetLocalScale(0.95, 0.95, 0.95)

			self.timeLabel_.effectColor = Color.New2(1248637951)
			self.endLabel_.effectColor = Color.New2(1248637951)
		elseif self.assessment_type == 3 then
			self.partnerModel:SetLocalPosition(-150, -940, 0)
			self.partnerModel:SetLocalScale(0.95, 0.95, 0.95)

			self.timeLabel_.effectColor = Color.New2(3107468799.0)
			self.endLabel_.effectColor = Color.New2(3107468799.0)
		elseif self.assessment_type == 4 then
			self.partnerModel:SetLocalPosition(-145, -760, 0)
			self.partnerModel:SetLocalScale(0.95, 0.95, 0.95)

			self.timeLabel_.effectColor = Color.New2(511975167)
			self.endLabel_.effectColor = Color.New2(511975167)
		elseif self.assessment_type == 5 then
			self.partnerModel:SetLocalPosition(-185, -1030, 0)
			self.partnerModel:SetLocalScale(-0.95, 0.95, 0.95)

			self.timeLabel_.effectColor = Color.New2(2083895807)
			self.endLabel_.effectColor = Color.New2(2083895807)
		elseif self.assessment_type == 6 then
			self.partnerModel:SetLocalPosition(-155, -800, 0)
			self.partnerModel:SetLocalScale(-0.95, 0.95, 0.95)

			self.timeLabel_.effectColor = Color.New2(3479188735.0)
			self.endLabel_.effectColor = Color.New2(3479188735.0)
		end

		self.textBg_:Y(380 - (p_height - 867) / 9)
		self.timeGroup:Y(260 - (p_height - 867) / 8)
		self.contentGroup:Y(-40 - (p_height - 867) / 3)

		if #self.items == 3 then
			self.itemLayout.enabled = false

			self.items[1]:SetLocalPosition(0, 130, 0)
			self.items[2]:SetLocalPosition(65, 0, 0)
			self.items[3]:SetLocalPosition(-65, 0, 0)
			self.itemGroup:SetLocalPosition(0, 20, 0)
		elseif #self.items == 4 then
			self.itemLayout.enabled = false

			self.items[1]:SetLocalPosition(65, 130, 0)
			self.items[2]:SetLocalPosition(-65, 130, 0)
			self.items[3]:SetLocalPosition(65, 0, 0)
			self.items[4]:SetLocalPosition(-65, 0, 0)
			self.itemGroup:SetLocalPosition(0, 20, 0)
		else
			self.itemLayout.gap = Vector2(32, 0)

			self.itemLayout:Reposition()
			self.itemGroup:SetLocalPosition(0, 65, 0)
		end
	end
end

function NewPushGiftBag:resizeToParent()
	NewPushGiftBag.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.go:Y(-520)
end

function NewPushGiftBag:getUpdateTime()
	local update_time = self.activityData.detail.update_time or self.activityData.detail[self.type].update_time or 0

	return update_time + GiftBagTable:getLastTime(self.giftBagID) - xyd.getServerTime()
end

function NewPushGiftBag:updateContent()
	local buy_times = self.activityData.detail.buy_times or self.activityData.detail[self.type].charge.buy_times or 0
	local limit = GiftBagTable:getBuyLimit(self.giftBagID) - buy_times
	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", limit)

	if limit > 0 then
		xyd.setEnabled(self.buyButton, true)
	else
		xyd.setEnabled(self.buyButton, false)
	end
end

function NewPushGiftBag:onRecharge(event)
	if self.giftBagID ~= event.data.giftbag_id then
		return
	end

	self:updateContent()
end

return NewPushGiftBag
