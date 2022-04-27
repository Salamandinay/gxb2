local ActivityContent = import(".ActivityContent")
local DoubleRingGiftbag = class("DoubleRingGiftbag", ActivityContent)
local CountDown = import("app.components.CountDown")

function DoubleRingGiftbag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function DoubleRingGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/double_ring_giftbag"
end

function DoubleRingGiftbag:initUI()
	self:getUIComponent()

	self.curId = 1
	self.noClick = true
	self.allIds = xyd.tables.activityRingGiftbagTable:getIds()
	local gift_bag_id = tonumber(xyd.tables.activityTable:getGiftBag(self.id)[1])
	self.gift_id = xyd.tables.giftBagTable:getGiftID(gift_bag_id)
	self.rewards = xyd.tables.giftTable:getAwards(self.gift_id)
	self.buy_limit_count_ = xyd.tables.giftBagTable:getBuyLimit(gift_bag_id)
	self.vip_ = xyd.tables.giftBagTable:getVipExp(gift_bag_id)
	self.price_ = tostring(xyd.tables.giftBagTextTable:getCurrency(gift_bag_id)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(gift_bag_id))
	self.currentState = xyd.Global.lang

	DoubleRingGiftbag.super.initUI(self)
	self:initUIComponent()
	self:euiComplete()
	self:loadRes()
end

function DoubleRingGiftbag:loadRes()
	local effectArr = {}

	for i, id in pairs(self.allIds) do
		local itemId = xyd.tables.activityRingGiftbagTable:getItemId(id)
		local modelID = xyd.tables.equipTable:getSkinModel(itemId)
		local littleName = xyd.tables.modelTable:getModelName(modelID)

		table.insert(effectArr, littleName)

		local bigName = xyd.tables.activityRingGiftbagTable:getModel(id)

		table.insert(effectArr, bigName)
	end

	local res = xyd.getEffectFilesByNames(effectArr)
	local allHasRes = xyd.isAllPathLoad(res)

	if allHasRes then
		self:showPage()

		return
	else
		ResCache.DownloadAssets("double_ring_gift_bag", res, function (success)
			if tolua.isnull(self.go) then
				return
			end

			self:showPage()
		end, nil)
	end
end

function DoubleRingGiftbag:showPage()
	if #self.allIds == 1 then
		return
	end

	self.arrGroup.gameObject:SetActive(true)
	self:actArrowMove()
	self:checkFirstMove()
end

function DoubleRingGiftbag:checkFirstMove()
	self:waitForTime(5, function ()
		if self.noClick then
			self:onClickArrow(1)
			self:checkFirstMove()
		end
	end)
end

function DoubleRingGiftbag:onClickArrow(num)
	self["littleModel" .. self.curId]:SetActive(false)
	self["bigModel" .. self.curId]:SetActive(false)

	if num == 1 then
		self.curId = self.curId + 1

		if self.curId > #self.allIds then
			self.curId = 1
		end
	elseif num == -1 then
		self.curId = self.curId - 1

		if self.curId < 1 then
			self.curId = #self.allIds
		end
	end

	local tableId = self.curId

	if not self["bigModel" .. self.curId] then
		local ringTable = xyd.tables.activityRingGiftbagTable
		self["bigModel" .. self.curId] = xyd.Spine.new(self.groupModel)

		self["bigModel" .. self.curId]:setInfo(ringTable:getModel(tableId), function ()
			self["bigModel" .. self.curId]:SetLocalScale(ringTable:getModelScale(tableId), ringTable:getModelScale(tableId), 1)
			self["bigModel" .. self.curId]:play("animation", -1, 1)
			self["bigModel" .. self.curId]:SetLocalPosition(ringTable:getModelXY(tableId)[1], ringTable:getModelXY(tableId)[2], 0)
		end)
	else
		self["bigModel" .. self.curId]:SetActive(true)
	end

	local itemId = xyd.tables.activityRingGiftbagTable:getItemId(tableId)
	self.labelSkinDesc.text = xyd.tables.equipTextTable:getSkinDesc(itemId)

	if not self["littleModel" .. self.curId] then
		self["littleModel" .. self.curId] = xyd.Spine.new(self.groupModel2)
		local modelID = xyd.tables.equipTable:getSkinModel(itemId)
		local name = xyd.tables.modelTable:getModelName(modelID)
		local scale = xyd.tables.modelTable:getScale(modelID)

		self["littleModel" .. self.curId]:setInfo(name, function ()
			self["littleModel" .. self.curId]:SetLocalPosition(0, 0, 0)
			self["littleModel" .. self.curId]:SetLocalScale(scale, scale, 1)
			self["littleModel" .. self.curId]:play("idle", 0)
		end)

		return
	end

	self["littleModel" .. self.curId]:SetActive(true)
end

function DoubleRingGiftbag:actArrowMove()
	self.leftArr.gameObject:X(-310)

	function self.playAni1_()
		if not self.sequence1_ then
			self.sequence1_ = self:getSequence()

			self.sequence1_:Append(self.leftArr.gameObject.transform:DOLocalMoveX(-315, 0.5):SetEase(DG.Tweening.Ease.Linear))
			self.sequence1_:Append(self.leftArr.gameObject.transform:DOLocalMoveX(-305, 1):SetEase(DG.Tweening.Ease.Linear))
			self.sequence1_:Append(self.leftArr.gameObject.transform:DOLocalMoveX(-310, 0.5):SetEase(DG.Tweening.Ease.Linear))
			self.sequence1_:AppendCallback(function ()
				self.playAni1_()
			end)
			self.sequence1_:SetAutoKill(false)
		else
			self.sequence1_:Restart()
		end
	end

	self.rightArr.gameObject:X(310)

	function self.playAni2_()
		if not self.sequence2_ then
			self.sequence2_ = self:getSequence()

			self.sequence2_:Append(self.rightArr.gameObject.transform:DOLocalMoveX(315, 0.5):SetEase(DG.Tweening.Ease.Linear))
			self.sequence2_:Append(self.rightArr.gameObject.transform:DOLocalMoveX(305, 1):SetEase(DG.Tweening.Ease.Linear))
			self.sequence2_:Append(self.rightArr.gameObject.transform:DOLocalMoveX(310, 0.5):SetEase(DG.Tweening.Ease.Linear))
			self.sequence2_:AppendCallback(function ()
				self.playAni2_()
			end)
			self.sequence2_:SetAutoKill(false)
		else
			self.sequence2_:Restart()
		end
	end

	self.playAni1_()
	self.playAni2_()
end

function DoubleRingGiftbag:resizeToParent()
	DoubleRingGiftbag.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.contentGroup:Y(-533 - (p_height - 874) * 109 / 178)
	self.groupModel:Y(-420 - (p_height - 874) * 2 / 178)
	self.groupModel:X(86 - (p_height - 874) * 4 / 178)
	self.imgBg0:Y(-6)
	self.imgBg:Y(-6)
	self.skinEffectGroup:Y(-365 - (p_height - 874) * 105 / 178)
end

function DoubleRingGiftbag:getUIComponent()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UITexture))
	self.imgBg0 = go:ComponentByName("imgBg0", typeof(UITexture))
	self.groupModel = go:NodeByName("groupModel").gameObject
	self.showSkinBtn = go:NodeByName("showSkinBtn").gameObject
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.textImg = self.timeGroup:ComponentByName("textImg", typeof(UITexture))
	self.timeLabelGroup_layout = self.timeGroup:ComponentByName("timeLabelGroup", typeof(UILayout))
	self.endLabel = self.timeGroup:ComponentByName("timeLabelGroup/endLabel", typeof(UILabel))
	self.timeLabel = self.timeGroup:ComponentByName("timeLabelGroup/timeLabel", typeof(UILabel))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.contentBg = self.contentGroup:ComponentByName("contentBg", typeof(UITexture))
	self.vipLabel = self.contentGroup:ComponentByName("vipLabel", typeof(UILabel))
	self.limitLabel = self.contentGroup:ComponentByName("limitLabel", typeof(UILabel))
	self.discountIcon = self.contentGroup:ComponentByName("discountIcon", typeof(UITexture))
	self.purchaseBtn = self.contentGroup:ComponentByName("purchaseBtn", typeof(UISprite))
	self.purchaseBtn_boxCollider = self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider))
	self.purchaseBtn_button_label = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.itemGroup = self.contentGroup:NodeByName("itemGroup").gameObject
	self.priceImg = self.contentGroup:ComponentByName("priceImg", typeof(UITexture))
	self.itemImg1 = self.contentGroup:ComponentByName("itemImg1", typeof(UITexture))
	self.limitLabel0 = self.contentGroup:ComponentByName("limitLabel0", typeof(UILabel))
	self.itemImg2 = self.contentGroup:ComponentByName("itemImg2", typeof(UISprite))
	self.limitLabel1 = self.contentGroup:ComponentByName("limitLabel1", typeof(UILabel))
	self.skinEffectGroup = go:NodeByName("skinEffectGroup").gameObject
	self.cancelEffectGroup = self.skinEffectGroup:NodeByName("cancelEffectGroup").gameObject
	self.labelSkinDesc = self.skinEffectGroup:ComponentByName("labelSkinDesc", typeof(UILabel))
	self.groupEffect1 = self.skinEffectGroup:NodeByName("groupEffect1").gameObject
	self.groupEffect2 = self.skinEffectGroup:NodeByName("groupEffect2").gameObject
	self.groupTouch = self.skinEffectGroup:NodeByName("groupTouch").gameObject
	self.groupModel2 = self.skinEffectGroup:NodeByName("groupModel2").gameObject
	self.arrGroup = self.go:NodeByName("arrGroup").gameObject
	self.leftArr = self.arrGroup:ComponentByName("leftArr", typeof(UISprite))
	self.rightArr = self.arrGroup:ComponentByName("rightArr", typeof(UISprite))
end

function DoubleRingGiftbag:initUIComponent()
	local ringTable = xyd.tables.activityRingGiftbagTable
	local tableId = 1

	if ringTable:getLogoSide(tableId) == 1 then
		self.timeGroup:X(-207)
	elseif ringTable:getLogoSide(tableId) == 2 then
		self.timeGroup:X(207)
	end

	if ringTable:getModelSide(tableId) == 1 then
		self.showSkinBtn:X(-307)
	elseif ringTable:getModelSide(tableId) == 2 then
		self.showSkinBtn:X(307)
	end

	if ringTable:getBuySide(tableId) == 1 then
		self.contentGroup:X(-186)
	elseif ringTable:getBuySide(tableId) == 2 then
		self.contentGroup:X(175)
	end

	self.textImg:SetLocalScale(ringTable:getLogoScale(tableId), ringTable:getLogoScale(tableId), 1)
	self.timeLabelGroup_layout:Y(ringTable:getTimeY(tableId))

	if xyd.Global.lang == "ko_kr" then
		self.timeLabelGroup_layout:Y(ringTable:getTimeY(tableId) - 7)
	end

	local imgpath = "Textures/activity_web/double_ring_giftbag/"

	xyd.setUITextureAsync(self.imgBg, imgpath .. ringTable:getImgBg(tableId))
	xyd.setUITextureAsync(self.imgBg0, imgpath .. ringTable:getImgFront(tableId))
	xyd.setUITextureAsync(self.contentBg, imgpath .. "double_ring_giftbag_bg02")
	xyd.setUITextureAsync(self.discountIcon, imgpath .. "double_ring_giftbag_icon02")
	xyd.setUITextureByNameAsync(self.priceImg, "double_ring_giftbag_price_" .. xyd.Global.lang, true, function ()
		if xyd.Global.lang == "ko_kr" then
			self.priceImg.width = 254
			self.priceImg.height = 38
		elseif xyd.Global.lang == "de_de" then
			self.priceImg.width = 310
			self.priceImg.height = 28
		elseif xyd.Global.lang == "ja_jp" then
			self.priceImg:SetActive(false)
		end
	end)
	xyd.setUITextureAsync(self.itemImg1, imgpath .. "double_ring_giftbag_icon01")

	local textImgPath = "Textures/activity_text_web/"

	xyd.setUITextureAsync(self.textImg, textImgPath .. "double_ring_giftbag_text01_" .. xyd.Global.lang)
	xyd.setUISpriteAsync(self.itemImg2, nil, "icon_" .. self.rewards[3][1])

	self["bigModel" .. self.curId] = xyd.Spine.new(self.groupModel)

	self["bigModel" .. self.curId]:setInfo(ringTable:getModel(tableId), function ()
		self["bigModel" .. self.curId]:SetLocalScale(ringTable:getModelScale(tableId), ringTable:getModelScale(tableId), 1)
		self["bigModel" .. self.curId]:play("animation", -1, 1)
		self["bigModel" .. self.curId]:SetLocalPosition(ringTable:getModelXY(tableId)[1], ringTable:getModelXY(tableId)[2], 0)
	end)
end

function DoubleRingGiftbag:euiComplete()
	self.purchaseBtn_button_label.text = self.price_
	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.activityData.detail.charges[1].table_id)
	end)

	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, function (_, evt)
		local gift_bag_id = evt.data.giftbag_id

		if xyd.tables.giftBagTable:getActivityID(gift_bag_id) ~= self.id then
			return
		end

		self:updateStatus()
	end, self)

	if xyd:getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
		self.endLabel.text = __("END_TEXT")

		self.timeLabelGroup_layout:Reposition()
	else
		self.endLabel:SetActive(false)
		self.timeLabel:SetActive(false)
	end

	UIEventListener.Get(self.itemImg1.gameObject).onClick = handler(self, function ()
		local params = {
			smallTips = "",
			hideText = false,
			itemID = self.rewards[2][1],
			itemNum = self.rewards[2][2],
			wndType = xyd.ItemTipsWndType.NORMAL
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)
	UIEventListener.Get(self.itemImg2.gameObject).onClick = handler(self, function ()
		local params = {
			smallTips = "",
			hideText = false,
			itemID = self.rewards[3][1],
			itemNum = self.rewards[3][2],
			wndType = xyd.ItemTipsWndType.NORMAL
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)

	UIEventListener.Get(self.showSkinBtn).onClick = function ()
		self.noClick = false

		self.skinEffectGroup:SetActive(not self.skinEffectGroup.activeSelf)
		self:playSkinEffect()
	end

	UIEventListener.Get(self.cancelEffectGroup).onClick = function ()
		self.skinEffectGroup:SetActive(false)
		self:stopSkinEffect()
	end

	UIEventListener.Get(self.groupTouch).onClick = handler(self, self.onModelTouch)

	UIEventListener.Get(self.leftArr.gameObject).onClick = function ()
		self.noClick = false

		self:onClickArrow(-1)
	end

	UIEventListener.Get(self.rightArr.gameObject).onClick = function ()
		self.noClick = false

		self:onClickArrow(1)
	end

	for i in ipairs(self.rewards) do
		if tonumber(self.rewards[i][1]) == 45 then
			self.limitLabel0.text = "x" .. tostring(self.rewards[i][2])

			break
		end
	end

	self.limitLabel1.text = "x" .. self.rewards[3][2]
	self.vipLabel.text = "+" .. tostring(self.vip_) .. " VIP EXP"
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(self.buy_limit_count_ - self.activityData.detail.charges[1].buy_times))

	self:updateStatus()
	self:loadSkinModel()
	self:initSkinEffect()
end

function DoubleRingGiftbag:onModelTouch()
	if not self["littleModel" .. self.curId] then
		return
	end

	self["littleModel" .. self.curId]:play("attack", 1, 1, function ()
		self["littleModel" .. self.curId]:play("idle", 0)
	end)
end

function DoubleRingGiftbag:initSkinEffect()
	if self.skinEffect1 then
		return
	end

	self.skinEffect1 = xyd.Spine.new(self.groupEffect1)
	self.skinEffect2 = xyd.Spine.new(self.groupEffect2)

	self.skinEffect1:setInfo("fx_ui_fazhen", function ()
		self.skinEffect1:SetLocalPosition(0, 0, -10)
		self.skinEffect1:SetLocalScale(1, 1, 1)
	end)
	self.skinEffect2:setInfo("fx_ui_fazhen", function ()
		self.skinEffect2:SetLocalPosition(0, 0, 0)
		self.skinEffect2:SetLocalScale(1, 1, 1)
	end)
	self.groupEffect1:SetActive(false)
	self.groupEffect2:SetActive(false)
end

function DoubleRingGiftbag:loadSkinModel()
	local itemId = xyd.tables.activityRingGiftbagTable:getItemId(1)
	local modelID = xyd.tables.equipTable:getSkinModel(itemId)
	self.labelSkinDesc.text = xyd.tables.equipTextTable:getSkinDesc(itemId)
	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)

	if self["littleModel" .. self.curId] and self["littleModel" .. self.curId]:getName() == name then
		return
	end

	if self["littleModel" .. self.curId] then
		self["littleModel" .. self.curId]:destroy()
	end

	local model = xyd.Spine.new(self.groupModel2)

	model:setInfo(name, function ()
		model:SetLocalPosition(0, 0, 0)
		model:SetLocalScale(scale, scale, 1)
		model:play("idle", 0)
	end)

	self["littleModel" .. self.curId] = model
end

function DoubleRingGiftbag:playSkinEffect()
	if self["littleModel" .. self.curId] then
		self["littleModel" .. self.curId]:play("idle", 0, 1, nil, true)
	end

	if not self.skinEffect1 then
		return
	end

	if not self.skinEffect2 then
		return
	end

	self.skinEffect1:play("texiao01", 0, 1, nil, true)
	self.skinEffect2:play("texiao02", 0, 1, nil, true)
	self.groupEffect1:SetActive(true)
	self.groupEffect2:SetActive(true)
end

function DoubleRingGiftbag:stopSkinEffect()
	if self["littleModel" .. self.curId] then
		self["littleModel" .. self.curId]:stop()
	end

	if self.skinEffect1 then
		self.skinEffect1:stop()
	end

	if self.skinEffect1 then
		self.skinEffect2:stop()
	end

	self.groupEffect1:SetActive(false)
	self.groupEffect2:SetActive(false)
end

function DoubleRingGiftbag:updateStatus()
	if self.buy_limit_count_ <= self.activityData.detail.charges[1].buy_times then
		xyd.applyChildrenGrey(self.purchaseBtn.gameObject)

		self.purchaseBtn_boxCollider.enabled = false
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(self.buy_limit_count_ - self.activityData.detail.charges[1].buy_times))
end

return DoubleRingGiftbag
