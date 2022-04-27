local ActivityContent = import(".ActivityContent")
local ActivityHalloweenPumpkinField = class("ActivityHalloweenPumpkinField", ActivityContent)
local AnniversaryCakeEndAwardItem = class("AnniversaryCakeEndAwardItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local pumpkinType = {
	CUT = 2,
	COMMON = 1
}

function ActivityHalloweenPumpkinField:ctor(parentGO, params, parent)
	ActivityHalloweenPumpkinField.super.ctor(self, parentGO, params, parent)

	self.currentRound = self.activityData.detail.times + 1

	if self.currentRound > #xyd.tables.activityHalloweenAwardTable:finalAwardIds() then
		self.currentRound = #xyd.tables.activityHalloweenAwardTable:finalAwardIds()
	end
end

function ActivityHalloweenPumpkinField:getPrefabPath()
	return "Prefabs/Windows/activity/halloween_pumpkin_field"
end

function ActivityHalloweenPumpkinField:initUI()
	ActivityHalloweenPumpkinField.super.initUI(self)

	self.currentRound = self.activityData.detail.times + 1

	if self.currentRound > #xyd.tables.activityHalloweenAwardTable:finalAwardIds() then
		self.currentRound = #xyd.tables.activityHalloweenAwardTable:finalAwardIds()
	end

	self.tenItemIDs = {}

	self:getUIComponent()
	self:initUIComponent()
	self:initDownGroup()
	self:updateDDL1()
end

function ActivityHalloweenPumpkinField:getUIComponent()
	self.groupOne = self.go:NodeByName("groupOne").gameObject
	self.contentGroup = self.groupOne:NodeByName("contentGroup").gameObject
	self.resGroup = self.contentGroup:NodeByName("resGroup").gameObject
	self.bg_ = self.resGroup:ComponentByName("bg_", typeof(UITexture))
	self.icon = self.resGroup:ComponentByName("icon", typeof(UITexture))
	self.countLabel = self.resGroup:ComponentByName("countLabel", typeof(UILabel))
	self.addBtn = self.resGroup:NodeByName("addBtn").gameObject
	self.textImg = self.groupOne:ComponentByName("textImg", typeof(UISprite))
	self.awardScroller = self.contentGroup:ComponentByName("awardScroller", typeof(UIScrollView))
	self.awardScroller_uipanel = self.contentGroup:ComponentByName("awardScroller", typeof(UIPanel))
	self.itemGroupAll = self.awardScroller:NodeByName("itemGroupAll").gameObject
	local wrapContent = self.awardScroller:ComponentByName("itemGroupAll", typeof(MultiRowWrapContent))
	self.anniversary_cake_end_award_item = self.groupOne:NodeByName("anniversary_cake_end_award_item").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.awardScroller, wrapContent, self.anniversary_cake_end_award_item, AnniversaryCakeEndAwardItem, self)
	self.helpBtn = self.go:NodeByName("helpBtn").gameObject
	self.helpBtn_box = self.helpBtn:GetComponent(typeof(UnityEngine.BoxCollider))
	self.explainLabel = self.groupOne:ComponentByName("explainLabel", typeof(UILabel))
	self.timeGroup = self.groupOne:NodeByName("timeGroup").gameObject
	self.timeGroup_uilayout = self.groupOne:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.goMarkGroup = self.contentGroup:NodeByName("goMarkGroup").gameObject
	self.goImg = self.goMarkGroup:ComponentByName("goImg", typeof(UISprite))
	self.goLabel = self.goMarkGroup:ComponentByName("goLabel", typeof(UILabel))
	self.fireEffectCon1 = self.goMarkGroup:ComponentByName("fireEffectCon1", typeof(UITexture))
	self.fireEffectCon2 = self.goMarkGroup:ComponentByName("fireEffectCon2", typeof(UITexture))
	self.showLabel = self.contentGroup:ComponentByName("showLabel", typeof(UILabel))
	self.personEffectCon = self.groupOne:ComponentByName("personEffectCon", typeof(UITexture))
	self.explainLabel.text = __("ACTIVITY_HALLOWEEN_TEXT1")
	self.endLabel.text = __("END")
	self.goLabel.text = __("ACTIVITY_HALLOWEEN_GO")
	self.showLabel.text = __("ACTIVITY_HALLOWEEN_TEXT2")

	xyd.setUISpriteAsync(self.textImg, nil, "halloween_name_" .. tostring(xyd.Global.lang), nil, , true)

	self.groupTwo = self.go:NodeByName("groupTwo").gameObject
	self.cutBtn = self.groupTwo:NodeByName("cutBtn").gameObject
	self.cutBtn_box = self.cutBtn:GetComponent(typeof(UnityEngine.BoxCollider))
	self.cutBtnCon = self.cutBtn:NodeByName("cutBtnCon").gameObject
	self.cutBtnIcon = self.cutBtnCon:ComponentByName("cutBtnIcon", typeof(UISprite))
	self.cutBtnIconLabel = self.cutBtnIcon:ComponentByName("cutBtnIconLabel", typeof(UILabel))
	self.cutBtnLabel = self.cutBtnCon:ComponentByName("cutBtnLabel", typeof(UILabel))
	self.backBtn = self.groupTwo:NodeByName("backBtn").gameObject
	self.backBtn_box = self.backBtn:GetComponent(typeof(UnityEngine.BoxCollider))
	self.textImg2 = self.groupTwo:ComponentByName("textImg2", typeof(UISprite))
	self.bgImg2 = self.groupTwo:ComponentByName("bgImg2", typeof(UITexture))
	self.receiveBtnCon = self.cutBtn:NodeByName("receiveBtnCon").gameObject
	self.receiveBtnLabel = self.receiveBtnCon:ComponentByName("receiveBtnLabel", typeof(UILabel))
	self.redPoint = self.receiveBtnCon:ComponentByName("redPoint", typeof(UISprite))
	self.resGroup2 = self.groupTwo:NodeByName("resGroup2").gameObject
	self.bg2_ = self.resGroup2:ComponentByName("bg2_", typeof(UISprite))
	self.icon2 = self.resGroup2:ComponentByName("icon2", typeof(UISprite))
	self.countLabel2 = self.resGroup2:ComponentByName("countLabel2", typeof(UILabel))
	self.addBtn2 = self.resGroup2:NodeByName("addBtn2").gameObject
	self.addBtn2_box = self.addBtn2:GetComponent(typeof(UnityEngine.BoxCollider))
	self.finalCon = self.groupTwo:NodeByName("finalCon").gameObject
	self.finalConBg = self.finalCon:ComponentByName("finalConBg", typeof(UISprite))
	self.finalConCheckBtn = self.finalCon:NodeByName("finalConCheckBtn").gameObject
	self.finalItemCon = self.finalCon:NodeByName("finalItemCon").gameObject
	self.pumpkinCon = self.groupTwo:NodeByName("pumpkinCon").gameObject

	for i = 1, 10 do
		self["pumpkinBtn" .. i] = self.pumpkinCon:ComponentByName("pumpkinBtn" .. i, typeof(UISprite))
		self["pumpkinWidget" .. i] = self.pumpkinCon:ComponentByName("pumpkinBtn" .. i, typeof(UIWidget))
		self["itemicon" .. i] = self["pumpkinBtn" .. i]:NodeByName("itemicon" .. i).gameObject
	end

	self.effectCon = self.pumpkinCon:ComponentByName("effectCon", typeof(UITexture))
	self.finalItemLabel = self.finalCon:ComponentByName("finalItemLabel", typeof(UILabel))

	xyd.setUISpriteAsync(self.textImg2, nil, "halloween_name_" .. tostring(xyd.Global.lang), nil, , true)

	self.cutBtnLabel.text = __("ACTIVITY_HALLOWEEN_USE")
	self.receiveBtnLabel.text = __("ACTIVITY_HALLOWEEN_GET")
	self.finalItemLabel.text = __("ACTIVITY_HALLOWEEN_AWARD")

	if xyd.Global.lang == "ja_jp" then
		self.finalItemLabel.width = 100
	elseif xyd.Global.lang == "fr_fr" then
		self.cutBtnLabel.fontSize = 28
	end

	self.groupOne:SetActive(true)
	self.groupTwo:SetActive(false)

	self.personEffect_ = xyd.Spine.new(self.personEffectCon.gameObject)

	self.personEffect_:setInfo("zhitianxinchang_pifu03_lihui01", function ()
		self.personEffect_:setRenderTarget(self.personEffectCon, 1)
		self.personEffect_:SetLocalScale(0.75, 0.75, 1)
		self.personEffect_:SetLocalPosition(56, -877 + -18 * self.scale_num_contrary, 0)
		self.personEffect_:play("animation", 0)
	end)

	self.fireEffect1_ = xyd.Spine.new(self.fireEffectCon1.gameObject)

	self.fireEffect1_:setInfo("fx_halloween_fire", function ()
		self.fireEffect1_:setRenderTarget(self.fireEffectCon1, 1)
		self.fireEffect1_:SetLocalScale(0.55, 0.55, 1)
		self.fireEffect1_:SetLocalPosition(46, -2.6, 0)

		self.fireEffect1_:getGameObject().transform.localEulerAngles = Vector3(0, 0, -102)

		self.fireEffect1_:setAlpha(0.7)
		self.fireEffect1_:play("texiao01", 0)
	end)

	self.fireEffect2_ = xyd.Spine.new(self.fireEffectCon2.gameObject)

	self.fireEffect2_:setInfo("fx_halloween_fire", function ()
		self.fireEffect2_:setRenderTarget(self.fireEffectCon2, 1)
		self.fireEffect2_:SetLocalScale(0.65, 0.65, 1)
		self.fireEffect2_:SetLocalPosition(-78, 98, 0)

		self.fireEffect2_:getGameObject().transform.localEulerAngles = Vector3(0, 0, -89)

		self.fireEffect2_:setAlpha(0.7)
		self.fireEffect2_:play("texiao01", 0)
	end)
	self.textImg:Y(333 + -35 * self.scale_num_contrary)
	self.contentGroup:Y(-227 + -142 * self.scale_num_contrary)
	self.explainLabel:Y(184 + -130 * self.scale_num_contrary)
	self.timeGroup:Y(215 + -110 * self.scale_num_contrary)
	self.bgImg2:Y(-485 + -124 * self.scale_num_contrary)
	self.finalCon:Y(-343 + -168 * self.scale_num_contrary)
	self.cutBtn:Y(-368 + -152 * self.scale_num_contrary)
	self.resGroup2:Y(-408 + -156 * self.scale_num_contrary)
	self.textImg2:Y(366 + -46 * self.scale_num_contrary)
	self.backBtn:Y(385 + -134 * self.scale_num_contrary)
	self.pumpkinCon:Y(0 + -121 * self.scale_num_contrary)
end

function ActivityHalloweenPumpkinField:updateDDL1()
	local durationTime = self.activityData:getEndTime() - xyd.getServerTime()

	if durationTime > 0 then
		self.setCountDownTime = CountDown.new(self.timeLabel, {
			duration = durationTime,
			callback = handler(self, self.timeOver)
		})
	else
		self.timeLabel.text = "00:00"
	end

	self.timeGroup_uilayout:Reposition()
end

function ActivityHalloweenPumpkinField:timeOver()
	self.timeLabel.text = "00:00"

	self.timeGroup_uilayout:Reposition()
end

function ActivityHalloweenPumpkinField:initUIComponent()
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, self.onAward, self)

	self.countLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.PUMPKIN_KNIFE)
	self.countLabel2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.PUMPKIN_KNIFE)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_HALLOWEEN_HELP"
		})
	end)
	UIEventListener.Get(self.goImg.gameObject).onClick = handler(self, function ()
		self.groupOne:SetActive(false)
		self.groupTwo:SetActive(true)
	end)
	UIEventListener.Get(self.addBtn.gameObject).onClick = handler(self, self.addBtnFun)
	UIEventListener.Get(self.addBtn2.gameObject).onClick = handler(self, self.addBtnFun)

	self.eventProxyInner_:addEventListener(xyd.event.BOSS_BUY, function (e)
		local data = e.data
		local a = xyd.decodeProtoBuf(e.data)
		self.countLabel.text = data.energy
		self.countLabel2.text = data.energy

		self.activityData:setBuyTimes(data.buy_times)
		xyd.showToast(__("PURCHASE_SUCCESS"))
	end)

	UIEventListener.Get(self.cutBtn.gameObject).onClick = handler(self, function ()
		if self.activityData:getEndTime() <= xyd.getServerTime() then
			xyd.showToast(__("ACTIVITY_END_YET"))

			return
		end

		if xyd.models.backpack:getItemNumByID(xyd.ItemID.PUMPKIN_KNIFE) > 0 or self.activityData.detail.left and tonumber(self.activityData.detail.left) == 0 then
			local msg = messages_pb:get_activity_award_req()
			msg.activity_id = self.id

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.PUMPKIN_KNIFE)))
		end
	end)
	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, function ()
		self.groupOne:SetActive(true)
		self.groupTwo:SetActive(false)
	end)
	UIEventListener.Get(self.finalConCheckBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("anniversary_cake_award_window", {
			currentRound = self.currentRound
		})
	end)

	for i = 1, 10 do
		UIEventListener.Get(self["pumpkinBtn" .. i].gameObject).onClick = handler(self, function ()
			xyd.WindowManager.get():openWindow("halloween_show_award_window", {
				currentRound = i
			})
		end)
	end

	self:changeGetBtnState()
	self:initFinalCon()
	self:updateTenItem()
end

function ActivityHalloweenPumpkinField:addBtnFun()
	if self.activityData:getEndTime() <= xyd.getServerTime() then
		xyd.showToast(__("ACTIVITY_END_YET"))

		return
	end

	local maxNumBeen = self.activityData.detail.buy_times
	maxNumBeen = maxNumBeen or 0
	local maxNumCanBuy = xyd.tables.miscTable:getNumber("halloween_limit", "value") - self.activityData.detail.buy_times

	if maxNumCanBuy <= 0 then
		maxNumCanBuy = 0
	end

	xyd.WindowManager.get():openWindow("item_buy_window", {
		hide_min_max = false,
		item_no_click = false,
		cost = xyd.tables.miscTable:split2Cost("halloween_buy", "value", "|#")[1],
		max_num = xyd.checkCondition(maxNumCanBuy == 0, 1, maxNumCanBuy),
		itemParams = {
			num = 1,
			itemID = xyd.ItemID.PUMPKIN_KNIFE
		},
		buyCallback = function (num)
			if maxNumCanBuy <= 0 then
				xyd.showToast(__("FULL_BUY_SLOT_TIME"))

				return
			end

			local msg = messages_pb:boss_buy_req()
			msg.activity_id = xyd.ActivityID.HALLOWEEN_PUMPKIN_FIELD
			msg.num = num

			xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
		end,
		maxCallback = function ()
			xyd.showToast(__("FULL_BUY_SLOT_TIME"))
		end,
		limitText = __("BUY_GIFTBAG_LIMIT", tostring(self.activityData.detail.buy_times) .. "/" .. tostring(xyd.tables.miscTable:getNumber("halloween_limit", "value")))
	})
end

function ActivityHalloweenPumpkinField:initDownGroup()
	local awardsList = self:getAwardList()

	self.wrapContent:setInfos(awardsList, {})
	self.awardScroller:ResetPosition()
end

function ActivityHalloweenPumpkinField:onAward(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.activity_id ~= self.id then
		return
	end

	local dataValue = json.decode(data.detail)
	self.countLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.PUMPKIN_KNIFE)
	self.countLabel2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.PUMPKIN_KNIFE)
	local isPlay = true

	if self.currentRound ~= dataValue.info.times + 1 then
		self.currentRound = dataValue.info.times + 1

		if self.currentRound > #xyd.tables.activityHalloweenAwardTable:finalAwardIds() then
			self.currentRound = #xyd.tables.activityHalloweenAwardTable:finalAwardIds()
		end

		local infoItems = self.wrapContent:getItems()

		for i in pairs(infoItems) do
			if self.currentRound < i then
				break
			end

			infoItems[i]:updateState()
		end

		self.tenItemIDs = {}

		self:initFinalCon()
		xyd.openWindow("gamble_rewards_window", {
			wnd_type = 2,
			data = dataValue.items
		})

		isPlay = false
	end

	self:changeGetBtnState()
	self:updateTenItem(isPlay, dataValue)
end

function ActivityHalloweenPumpkinField:changeGetBtnState()
	if self.activityData.detail.left and tonumber(self.activityData.detail.left) == 0 then
		self.cutBtnCon:SetActive(false)
		self.receiveBtnCon:SetActive(true)
	else
		self.cutBtnCon:SetActive(true)
		self.receiveBtnCon:SetActive(false)
	end
end

function ActivityHalloweenPumpkinField:getAwardList()
	local awardList = {}
	local ids = xyd.tables.activityHalloweenAwardTable:finalAwardIds()
	self.maxRound = #ids

	for turnId in pairs(ids) do
		local item = xyd.tables.activityHalloweenAwardTable:getAwards(ids[turnId])
		local params = {
			itemId = item[1][1],
			itemNum = item[1][2],
			turn = turnId
		}

		table.insert(awardList, params)
	end

	return awardList
end

function ActivityHalloweenPumpkinField:initFinalCon()
	NGUITools.DestroyChildren(self.finalItemCon.transform)

	local ids = xyd.tables.activityHalloweenAwardTable:finalAwardIds()
	local itemData = xyd.tables.activityHalloweenAwardTable:getAwards(tonumber(ids[self.currentRound]))
	local itemIcon = xyd.getItemIcon({
		show_has_num = true,
		noClickSelected = true,
		showLightEffect = true,
		uiRoot = self.finalItemCon.gameObject,
		itemID = itemData[1][1],
		num = itemData[1][2],
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})
end

function ActivityHalloweenPumpkinField:updateTenItem(isPlayEffect, dataValue)
	for i = 1, 10 do
		local awardsId = self.activityData.detail.awards[i]

		if not self.tenItemIDs[i] or self.tenItemIDs[i] and self.tenItemIDs[i] ~= awardsId or awardsId == 0 then
			NGUITools.DestroyChildren(self["itemicon" .. i].transform)

			local imgName = "halloween_pumpkin_4"

			if i == 1 then
				imgName = "halloween_pumpkin_1"
			elseif i == 2 or i == 3 then
				imgName = "halloween_pumpkin_2"
			elseif i == 4 or i == 5 or i == 6 then
				imgName = "halloween_pumpkin_3"
			end

			xyd.setUISpriteAsync(self["pumpkinBtn" .. i], nil, imgName, nil, , true)
			self:updatePumpkinScale(i, pumpkinType.COMMON, self["pumpkinBtn" .. i])
		end

		if isPlayEffect and isPlayEffect == true then
			if not self.tenItemIDs[i] and awardsId ~= 0 or awardsId ~= 0 and self.tenItemIDs[i] and self.tenItemIDs[i] ~= awardsId then
				self.effectCon:SetLocalPosition(self["pumpkinBtn" .. i].transform.localPosition.x, self["pumpkinBtn" .. i].transform.localPosition.y + self["pumpkinWidget" .. i].height / 2, 0)
				self:setBtnEnabel(false)
				self:playEffect(function ()
					xyd.itemFloat(dataValue.items, nil, , 6500)

					self.tenItemIDs[i] = awardsId
					local itemDatas = xyd.tables.activityHalloweenAwardTable:getAwards(i)
					local itemIcon = xyd.getItemIcon({
						show_has_num = true,
						noClickSelected = true,
						uiRoot = self["itemicon" .. i].gameObject,
						itemID = itemDatas[awardsId][1],
						num = itemDatas[awardsId][2],
						wndType = xyd.ItemTipsWndType.ACTIVITY
					})

					self["itemicon" .. i]:Y(95)
					itemIcon:setChoose(true)
					xyd.setUISpriteAsync(self["pumpkinBtn" .. i], nil, "halloween_pumpkin_cut", nil, , true)
					self:updatePumpkinScale(i, pumpkinType.CUT, self["pumpkinBtn" .. i])
					self:setBtnEnabel(true)
				end)
			end
		elseif awardsId ~= 0 then
			self:setBtnEnabel(false)

			self.tenItemIDs[i] = awardsId
			local itemDatas = xyd.tables.activityHalloweenAwardTable:getAwards(i)
			local itemIcon = xyd.getItemIcon({
				show_has_num = true,
				noClickSelected = true,
				uiRoot = self["itemicon" .. i].gameObject,
				itemID = itemDatas[awardsId][1],
				num = itemDatas[awardsId][2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			self["itemicon" .. i]:Y(95)
			itemIcon:setChoose(true)
			xyd.setUISpriteAsync(self["pumpkinBtn" .. i], nil, "halloween_pumpkin_cut", nil, , true)
			self:updatePumpkinScale(i, pumpkinType.CUT, self["pumpkinBtn" .. i])
			self:setBtnEnabel(true)
		end
	end
end

function ActivityHalloweenPumpkinField:playEffect(func)
	if not self.Effect_ then
		self.Effect_ = xyd.Spine.new(self.effectCon.gameObject)

		self.Effect_:setInfo("fx_halloween_hit", function ()
			self.Effect_:setRenderTarget(self.effectCon, 1)
			self.Effect_:play("texiao01", 1, 1, function ()
				self.Effect_:SetActive(false)
				func()
			end)
		end)
	else
		self.Effect_:SetActive(true)
		self.Effect_:play("texiao01", 1, 1, function ()
			self.Effect_:SetActive(false)
			func()
		end)
	end
end

function ActivityHalloweenPumpkinField:setBtnEnabel(state)
	self.cutBtn_box.enabled = state
	self.helpBtn_box.enabled = state
	self.addBtn2_box.enabled = state
	self.backBtn_box.enabled = state
end

function ActivityHalloweenPumpkinField:updatePumpkinScale(i, state, objImg)
	if state == pumpkinType.COMMON then
		if i == 3 or i == 6 or i == 8 or i == 10 then
			objImg:SetLocalScale(-1, 1, 1)
		else
			objImg:SetLocalScale(1, 1, 1)
		end
	elseif state == pumpkinType.CUT then
		objImg:SetLocalScale(1, 1, 1)
	end
end

function AnniversaryCakeEndAwardItem:ctor(go, parent)
	AnniversaryCakeEndAwardItem.super.ctor(self, go, parent)
end

function AnniversaryCakeEndAwardItem:initUI()
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.selectedGrey = self.go:ComponentByName("selectedGrey", typeof(UISprite))
	self.selectedMark = self.go:ComponentByName("selectedMark", typeof(UISprite))
	self.currentMark = self.go:ComponentByName("currentMark", typeof(UISprite))
	self.turnsLabel = self.go:ComponentByName("turnsLabel", typeof(UILabel))
end

function AnniversaryCakeEndAwardItem:updateInfo()
	if not self.data.itemId then
		return
	end

	if self.itemIcon and self.turn and self.turn == self.data.turn then
		return
	end

	NGUITools.DestroyChildren(self.itemGroup.transform)

	self.turn = self.data.turn
	self.itemIcon = xyd.getItemIcon({
		show_has_num = true,
		noClickSelected = true,
		uiRoot = self.itemGroup.gameObject,
		itemID = self.data.itemId,
		num = self.data.itemNum,
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		panel = self.parent.awardScroller_uipanel
	})

	self.itemIcon:AddUIDragScrollView()
	self.itemIcon:setScale(0.9)

	if self.data.turn < self.parent.currentRound then
		self.selectedGrey:SetActive(true)
		self.selectedMark:SetActive(true)
	else
		self.selectedGrey:SetActive(false)
		self.selectedMark:SetActive(false)
	end

	if self.turn ~= self.parent.maxRound then
		self.turnsLabel.text = __("ROUNDS", self.data.turn)
	else
		self.turnsLabel.text = __("MAX_ROUNDS", self.data.turn)
	end
end

function AnniversaryCakeEndAwardItem:updateState()
	if self.data.turn < self.parent.currentRound then
		self.selectedGrey:SetActive(true)
		self.selectedMark:SetActive(true)
	else
		self.selectedGrey:SetActive(false)
		self.selectedMark:SetActive(false)
	end
end

return ActivityHalloweenPumpkinField
