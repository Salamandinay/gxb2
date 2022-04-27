local ActivityContent = import(".ActivityContent")
local ActivityBaoxiang = class("ActivityBaoxiang", ActivityContent)

function ActivityBaoxiang:ctor(parentGO, params, parent)
	ActivityBaoxiang.super.ctor(self, parentGO, params, parent)
end

function ActivityBaoxiang:getPrefabPath()
	return "Prefabs/Windows/activity/activity_baoxiang"
end

function ActivityBaoxiang:resizeToParent()
	ActivityBaoxiang.super.resizeToParent(self)

	local h = self.go:GetComponent(typeof(UIWidget)).height

	if h > 900 then
		self.redBox_:Y(-589)
		self.yellowBox_:Y(-845)
	end
end

function ActivityBaoxiang:initUI()
	self:getUIComponent()
	ActivityBaoxiang.super.initUI(self)

	self.labelDes.text = __("ACTIVTIY_NEWYEAR_BOX_TEXT")
	self.awardBtnLabel.text = __("ACTIVTIY_NEWYEAR_COST")

	if xyd.Global.lang == "ja_jp" then
		self.awardBtnLabel.width = 90
	end

	xyd.setUITextureByNameAsync(self.imgText, "newyear_baoxiang_text_" .. xyd.Global.lang)

	self.previewBtn1_label.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.NEWYEAR_WELFARE_GIFTBAG2022)
	self.previewBtn2_label.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.NEWYEAR_SUPER_GIFTBAG2022)
	local effect = xyd.Spine.new(self.awardBtn_effect)

	effect:setInfo("fx_ui_txsaoguang", function ()
		effect:SetLocalScale(0.5, 0.5, 0.5)
		effect:SetLocalPosition(0, -10, 0)
		effect:play("texiao01", 0, 1)
	end)

	local effect1 = xyd.Spine.new(self.redBox_effect)

	effect1:setInfo("newyear_box_1", function ()
		effect1:SetLocalScale(1.05, 1.1, 1)
		effect1:play("animation", 0, 1)
	end)

	local effect2 = xyd.Spine.new(self.yellowBox_effect)

	effect2:setInfo("newyear_box_2", function ()
		effect2:SetLocalScale(1.05, 1.1, 1)
		effect2:play("animation", 0, 1)
	end)

	self.effect1 = effect1
	self.effect2 = effect2

	self:registerEvent(xyd.event.USE_ITEM, handler(self, self.useGiftBag))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:setRedPoint()
end

function ActivityBaoxiang:getUIComponent()
	local go = self.go
	self.imgText = go:ComponentByName("imgText", typeof(UITexture))
	self.labelDes = go:ComponentByName("labelDesc", typeof(UILabel))
	self.yellowBox_ = go:NodeByName("yellowBox_").gameObject
	self.yellowBox_effect = go:NodeByName("yellowBox_/effect").gameObject
	self.previewBtn1 = self.yellowBox_:NodeByName("previewBtn1/btn").gameObject
	self.previewBtn1_label = self.yellowBox_:ComponentByName("previewBtn1/button_label", typeof(UILabel))
	self.redBox_ = go:NodeByName("redBox_").gameObject
	self.redBox_effect = go:NodeByName("redBox_/effect").gameObject
	self.previewBtn2 = self.redBox_:NodeByName("previewBtn2/btn").gameObject
	self.previewBtn2_label = self.redBox_:ComponentByName("previewBtn2/button_label", typeof(UILabel))
	self.awardBtn = go:NodeByName("awardBtn").gameObject
	self.awardBtnLabel = self.awardBtn:ComponentByName("label", typeof(UILabel))
	self.redPoint = self.awardBtn:NodeByName("redPoint").gameObject
	self.awardBtn_effect = self.awardBtn:NodeByName("effectGroup").gameObject
end

function ActivityBaoxiang:onRegister()
	UIEventListener.Get(self.yellowBox_).onClick = function ()
		self:palyAnimation(2)

		local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.NEWYEAR_WELFARE_GIFTBAG2022)

		xyd.WindowManager.get():openWindow("item_use_window", {
			showGetWay = true,
			itemID = xyd.ItemID.NEWYEAR_WELFARE_GIFTBAG2022,
			itemNum = num
		})
	end

	UIEventListener.Get(self.redBox_).onClick = function ()
		self:palyAnimation(1)

		local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.NEWYEAR_SUPER_GIFTBAG2022)

		xyd.WindowManager.get():openWindow("item_use_window", {
			showGetWay = true,
			itemID = xyd.ItemID.NEWYEAR_SUPER_GIFTBAG2022,
			itemNum = num
		})
	end

	UIEventListener.Get(self.previewBtn1).onClick = function ()
		local giftId = xyd.tables.itemTable:getGiftID(xyd.ItemID.NEWYEAR_WELFARE_GIFTBAG2022)
		local box_id = xyd.tables.giftTable:getDropboxId(giftId)

		xyd.WindowManager.get():openWindow("drop_probability_window", {
			isShowProbalitity = true,
			box_id = box_id,
			activityID = xyd.ActivityID.NEWYEAR_BAOXIANG
		})
	end

	UIEventListener.Get(self.previewBtn2).onClick = function ()
		local giftId = xyd.tables.itemTable:getGiftID(xyd.ItemID.NEWYEAR_SUPER_GIFTBAG2022)
		local box_id = xyd.tables.giftTable:getDropboxId(giftId)

		xyd.WindowManager.get():openWindow("drop_probability_window", {
			isShowProbalitity = true,
			box_id = box_id,
			activityID = xyd.ActivityID.NEWYEAR_BAOXIANG
		})
	end

	UIEventListener.Get(self.awardBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_baoxiang_award_window", {})
	end
end

function ActivityBaoxiang:useGiftBag(event)
	local id_ = tonumber(event.data.used_item_id)

	if id_ == xyd.ItemID.NEWYEAR_SUPER_GIFTBAG2022 or id_ == xyd.ItemID.NEWYEAR_WELFARE_GIFTBAG2022 then
		self:setRedPoint()
	end
end

function ActivityBaoxiang:onItemChange(event)
	local items = event.data.items

	for _, item in ipairs(items) do
		if item.item_id == xyd.ItemID.NEWYEAR_WELFARE_GIFTBAG2022 then
			self.previewBtn1_label.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.NEWYEAR_WELFARE_GIFTBAG2022)
		end

		if item.item_id == xyd.ItemID.NEWYEAR_SUPER_GIFTBAG2022 then
			self.previewBtn2_label.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.NEWYEAR_SUPER_GIFTBAG2022)
		end

		self:setRedPoint()
	end
end

function ActivityBaoxiang:palyAnimation(index)
	local sequence = self:getSequence()
	local effect = self["effect" .. index]

	local function resGroupSetter(value)
		effect:SetLocalScale(value, value, value)
	end

	sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(resGroupSetter), 1, 0.85, 0.1):SetEase(DG.Tweening.Ease.Linear))
	sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(resGroupSetter), 0.85, 1.06, 0.03):SetEase(DG.Tweening.Ease.Linear))
	sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(resGroupSetter), 1.06, 1, 0.07):SetEase(DG.Tweening.Ease.Linear))
end

function ActivityBaoxiang:onAward(event)
	if event.data.activity_id == xyd.ActivityID.NEWYEAR_BAOXIANG then
		self:setRedPoint()
	end
end

function ActivityBaoxiang:setRedPoint()
	self.redPoint:SetActive(self.activityData:getRedMarkState())
end

return ActivityBaoxiang
