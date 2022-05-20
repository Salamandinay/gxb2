local ExploreAdventureWindow = class("ExploreAdventureWindow", import(".BaseWindow"))
local BoxFormationItem = class("BoxFormationItem")
local exploreModel = xyd.models.exploreModel
local adventureTable = xyd.tables.exploreAdventureTable
local adventureEventTable = xyd.tables.adventureEventTable
local cjson = require("cjson")
local EventType = {
	COST_AWARD = 3,
	MYSTERY_SHOP = 4,
	BATTLE = 1
}
local secneCaseImg = {
	"adven_case_1",
	"adven_case_2",
	"adven_case_2",
	"adven_case_3",
	"adven_case_4",
	"adven_case_4"
}
local adventureMaxLevel = 10

function ExploreAdventureWindow:ctor(name, params)
	ExploreAdventureWindow.super.ctor(self, name, params)
end

function ExploreAdventureWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ExploreAdventureWindow:getUIComponent()
	self.resGroup = self.window_:NodeByName("resGroup").gameObject
	local groupMain = self.window_:NodeByName("groupAction").gameObject
	local groupTop = groupMain:NodeByName("groupTop").gameObject
	self.closeBtn = groupTop:NodeByName("closeBtn").gameObject
	self.tipsBtn = groupTop:NodeByName("tipsBtn").gameObject
	self.helpBtn = groupTop:NodeByName("helpBtn").gameObject
	self.labelTitle = groupTop:ComponentByName("labelTitle", typeof(UILabel))
	local groupMiddle = groupMain:NodeByName("groupMiddle").gameObject
	self.btnLevelUp = groupMiddle:NodeByName("btnLevelUp").gameObject
	self.lvMaxImg = groupMiddle:NodeByName("lvMaxImg").gameObject
	self.redPoint = groupMiddle:NodeByName("redPoint").gameObject
	self.labelItemList = {}

	for i = 1, 3 do
		local labelItem = groupMiddle:NodeByName("labelItem" .. i).gameObject
		self.labelItemList[i] = {
			labelName = labelItem:ComponentByName("labelName", typeof(UILabel)),
			labelNum = labelItem:ComponentByName("labelNum", typeof(UILabel))
		}
	end

	local groupBottom = groupMain:NodeByName("groupBottom").gameObject
	self.btnLeft = groupBottom:NodeByName("btnLeft").gameObject
	self.btnLeftLabel = self.btnLeft:ComponentByName("labelLeft", typeof(UILabel))
	self.btnGO = groupBottom:NodeByName("btnGO").gameObject
	self.btnGOLabel = self.btnGO:ComponentByName("labelGO", typeof(UILabel))
	self.btnAdven = groupBottom:NodeByName("btnAdven").gameObject
	self.btnAdvenLabel = self.btnAdven:ComponentByName("labelAdven", typeof(UILabel))
	self.giftBoxItem = groupBottom:NodeByName("giftBoxItem").gameObject

	self.giftBoxItem:SetActive(false)

	self.boxScroller = groupBottom:ComponentByName("boxScroller", typeof(UIScrollView))
	self.groupGiftBox = self.boxScroller:NodeByName("groupGiftBox").gameObject
	self.groupCost_ = groupBottom:NodeByName("groupCost_").gameObject
	self.imgCost = self.groupCost_:ComponentByName("imgCost", typeof(UISprite))
	self.labelCost = self.groupCost_:ComponentByName("labelCost", typeof(UILabel))
	self.btnGroup = groupBottom:NodeByName("btnGroup").gameObject
	self.btnChange = self.btnGroup:NodeByName("btnChange").gameObject
	self.btnOpenBox = self.btnGroup:NodeByName("btnOpenBox").gameObject
	self.imgOpenBoxBtn = self.btnGroup:ComponentByName("btnOpenBox", typeof(UISprite))
	self.btnSetup = self.btnGroup:NodeByName("btnSetup").gameObject
	self.btnFormation = self.btnGroup:NodeByName("btnFormation").gameObject
	self.autoAdven = groupBottom:NodeByName("autoAdven").gameObject
	self.iconON = self.autoAdven:NodeByName("iconON").gameObject
	self.iconOFF = self.autoAdven:NodeByName("iconOFF").gameObject
	self.labelAutoAdven = self.autoAdven:ComponentByName("labelAutoAdven", typeof(UILabel))
	self.btnStopAutoAdven = groupBottom:NodeByName("btnStopAutoAdven").gameObject
	self.labelStopAutoAdven = self.btnStopAutoAdven:ComponentByName("labelStopAutoAdven", typeof(UILabel))
	self.labelAutoAdvening = groupBottom:ComponentByName("labelAutoAdvening", typeof(UILabel))
	local groupScene = groupMain:NodeByName("groupScene").gameObject
	self.sceneBg = groupScene:ComponentByName("sceneBg", typeof(UITexture))
	self.sceneBg1 = groupScene:ComponentByName("sceneBg1", typeof(UITexture))
	self.modelNode1 = groupScene:NodeByName("modelNode1").gameObject
	self.modelNode2 = groupScene:NodeByName("modelNode2").gameObject
	self.sceneImg1 = self.sceneBg:ComponentByName("sceneImg1", typeof(UISprite))
	self.bubble = self.sceneBg:NodeByName("bubble").gameObject
	self.sceneImg2 = self.bubble:ComponentByName("sceneImg2", typeof(UISprite))
	self.eventTitleLabel = groupScene:ComponentByName("eventTitleLabel", typeof(UILabel))
end

function ExploreAdventureWindow:initTop()
	self.resCrystal = require("app.components.ResItem").new(self.resGroup)
	self.resBread_ = require("app.components.ResItem").new(self.resGroup)

	self.resGroup:GetComponent(typeof(UILayout)):Reposition()
	self.resCrystal:setInfo({
		tableId = xyd.ItemID.CRYSTAL
	})
	self.resBread_:setInfo({
		tableId = xyd.ItemID.DELICIOUS_BREAD,
		callback = function ()
			xyd.WindowManager.get():openWindow("explore_source_buy_window")
		end
	})
end

function ExploreAdventureWindow:layout()
	self:initTop()

	self.adventureCost = xyd.split(xyd.tables.miscTable:getVal("travel_event_consume"), "#", true)
	self.labelTitle.text = __("TRAVEL_BUILDING_NAME5")
	self.btnLeftLabel.text = "[u]" .. __("TRAVEL_MAIN_TEXT29") .. "[/u]"
	self.btnGOLabel.text = __("TRAVEL_MAIN_TEXT28")

	if xyd.Global.lang == "fr_fr" then
		self.btnLeftLabel.fontSize = 24

		self.btnLeftLabel:X(15)

		self.btnGOLabel.fontSize = 24
	end

	self.btnAdvenLabel.text = __("TRAVEL_MAIN_TEXT27")
	self.data = exploreModel:getExploreInfo()

	if self.data.lv == adventureMaxLevel then
		self.lvMaxImg:SetActive(true)
	else
		self.lvMaxImg:SetActive(false)
	end

	self.labelAutoAdven.text = __("TRAVEL_NEW_TEXT01")
	local value = xyd.db.misc:getValue("auto_adventure_is_open")

	if value and tonumber(value) == 1 then
		self.autoAdvenIsOpen = true
	else
		self.autoAdvenIsOpen = false
	end

	self.iconOFF:SetActive(not self.autoAdvenIsOpen)
	self.iconON:SetActive(self.autoAdvenIsOpen)

	self.onAutoAdven = false
	self.labelStopAutoAdven.text = __("TRAVEL_NEW_TEXT11")
	self.labelAutoAdvening.text = __("TRAVEL_NEW_TEXT10")
	self.travelQuickLimit = xyd.tables.miscTable:getNumber("travel_quick_limit", "value")
	self.eventModelList = xyd.split(xyd.tables.miscTable:getVal("travel_event_model_u3"), "|")
	self.lastBoxNum = 0

	for i in ipairs(self.data.chests) do
		if self.data.chests[i] ~= 0 then
			self.lastBoxNum = self.lastBoxNum + 1
		end
	end

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.EXPLORE_ADVENTURE_LV_UP, self.redPoint)

	self.sceneImg1OriginY = self.sceneImg1.transform.localPosition.y

	self:setAdventureData()
	self:setBtn()
	self:initScene()
end

function ExploreAdventureWindow:setAdventureData()
	local lv = self.data.lv
	self.slotNum = adventureTable:getSlotNum(lv)
	local maxNum = adventureTable:getSlotNum(adventureMaxLevel)
	self.labelItemList[1].labelName.text = __("TRAVEL_MAIN_TEXT21")
	self.labelItemList[1].labelNum.text = lv
	self.labelItemList[2].labelName.text = __("TRAVEL_MAIN_TEXT22")
	self.labelItemList[2].labelNum.text = self.slotNum
	self.labelItemList[3].labelName.text = __("TRAVEL_MAIN_TEXT23")
	self.labelItemList[3].labelNum.text = adventureTable:getEnemyLv(lv)
	self.giftBoxItemList = {}

	NGUITools.DestroyChildren(self.groupGiftBox.transform)

	for i = 1, maxNum do
		local temp = NGUITools.AddChild(self.groupGiftBox, self.giftBoxItem)
		local item = BoxFormationItem.new(temp, self)

		item:initBox(self.slotNum < i)
		table.insert(self.giftBoxItemList, item)
	end

	self.groupGiftBox:GetComponent(typeof(UIGrid)):Reposition()
	self:setGiftBoxContent()
end

function ExploreAdventureWindow:setBtn()
	if self.onAutoAdven then
		self.btnStopAutoAdven:SetActive(true)
		self.labelAutoAdvening:SetActive(true)
		self.autoAdven:SetActive(false)
		self.btnAdven:SetActive(false)
		self.btnGO:SetActive(false)
		self.groupCost_:SetActive(false)
		self.btnLeft:SetActive(false)
	elseif self.data.event_id == 0 then
		self.btnStopAutoAdven:SetActive(false)
		self.labelAutoAdvening:SetActive(false)
		self.btnAdven:SetActive(true)
		self.groupCost_:SetActive(true)
		xyd.setUISpriteAsync(self.imgCost, nil, "icon_" .. self.adventureCost[1])

		self.labelCost.text = self.adventureCost[2]

		if xyd.models.backpack:getItemNumByID(self.adventureCost[1]) < self.adventureCost[2] then
			self.labelCost.color = Color.New2(3981269247.0)
		else
			self.labelCost.color = Color.New2(1363960063)
		end

		self.btnGO:SetActive(false)
		self.btnLeft:SetActive(false)

		if self.travelQuickLimit <= self.data.lv and not self.onAutoAdven then
			self.autoAdven:SetActive(true)
			self.btnSetup:SetActive(true)
			self.btnFormation:SetActive(true)
			self.btnOpenBox:SetActive(true)
		else
			self.autoAdven:SetActive(false)
			self.btnSetup:SetActive(false)
			self.btnFormation:SetActive(false)
			self.btnOpenBox:SetActive(false)
		end
	else
		self.btnStopAutoAdven:SetActive(false)
		self.labelAutoAdvening:SetActive(false)
		self.autoAdven:SetActive(false)
		self.btnAdven:SetActive(false)
		self.btnGO:SetActive(true)
		self.btnLeft:SetActive(true)

		local cost = adventureEventTable:getCost(self.data.event_id)

		if next(cost) ~= nil then
			self.groupCost_:SetActive(true)
			xyd.setUISpriteAsync(self.imgCost, nil, "icon_" .. cost[1])

			self.labelCost.text = xyd.getRoughDisplayNumber(tonumber(cost[2]))

			if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
				self.labelCost.color = Color.New2(3981269247.0)
			end
		else
			self.groupCost_:SetActive(false)
		end
	end
end

function ExploreAdventureWindow:setGiftBoxContent()
	local curBoxNum = 0

	for i = 1, self.slotNum do
		local boxID = self.data.chests[i] or 0

		if boxID ~= 0 then
			curBoxNum = curBoxNum + 1
		end

		self.giftBoxItemList[i]:setInfo({
			boxID = boxID,
			updateTime = self.data.update_times[i],
			boxIndex = i,
			isNew = self.lastBoxNum < i and boxID ~= 0
		})
	end

	self.lastBoxNum = curBoxNum

	self:setOpenBoxBtn()
end

function ExploreAdventureWindow:setOpenBoxBtn()
	for i = 1, self.slotNum do
		if self.giftBoxItemList[i].id > 0 and self.giftBoxItemList[i].isFree then
			xyd.setUISpriteAsync(self.imgOpenBoxBtn, nil, "btn_open_box_free", nil, , true)

			return
		end
	end

	xyd.setUISpriteAsync(self.imgOpenBoxBtn, nil, "btn_open_box", nil, , true)
end

function ExploreAdventureWindow:getMainModelID()
	local modelID, itemID = nil
	local value = xyd.db.misc:getValue("xwtx_chosen_models")

	if value then
		local modelList = cjson.decode(value)
		local modelIndex = 1

		if tonumber(xyd.db.misc:getValue("xwtx_show_random")) == 1 then
			modelIndex = math.random(1, #modelList)
		end

		itemID = modelList[modelIndex]
	else
		itemID = self.eventModelList[1]
	end

	local type = xyd.tables.itemTable:getType(itemID)

	if type == xyd.ItemType.SKIN or type == xyd.ItemType.FAKE_PARTNER_SKIN then
		modelID = xyd.tables.equipTable:getSkinModel(itemID)
	else
		modelID = xyd.tables.partnerTable:getModelID(itemID)
	end

	return modelID
end

function ExploreAdventureWindow:initScene()
	local modelID = self:getMainModelID()
	self.mainModelID = modelID
	local name1 = xyd.tables.modelTable:getModelName(modelID)
	local scale1 = xyd.tables.modelTable:getScale(modelID)
	self.modelEffect1 = xyd.Spine.new(self.modelNode1)

	if self.data.event_id == 0 then
		local tm = os.date("*t")

		if tm.hour >= 6 and tm.hour <= 18 then
			xyd.setUITextureByNameAsync(self.sceneBg, "explore_scene_day")
		else
			xyd.setUITextureByNameAsync(self.sceneBg, "explore_scene_night")
		end

		self.modelEffect1:setInfo(name1, function ()
			self.modelEffect1:setToSetupPose()
			self.modelEffect1:SetLocalScale(scale1, scale1, scale1)
			self.modelEffect1:play("idle", 0, 1)
			self.modelEffect1:SetLocalPosition(0, -112, 0)
		end)
		self.sceneImg1:SetActive(false)
		self.bubble:SetActive(false)
		self.eventTitleLabel:SetActive(false)
		self.btnGroup:SetActive(true)
	else
		self.btnGroup:SetActive(false)

		local mapId = adventureEventTable:getMap(self.data.event_id)

		xyd.setUITextureByNameAsync(self.sceneBg, "explore_scene_" .. mapId)
		self.sceneImg1:SetActive(true)
		xyd.setUISpriteAsync(self.sceneImg1, nil, secneCaseImg[mapId])
		self:setEmojiSequence1()
		self.modelEffect1:setInfo(name1, function ()
			self.modelEffect1:SetLocalScale(scale1, scale1, scale1)
			self.modelEffect1:play("idle", 0, 1)
			self.modelEffect1:SetLocalPosition(-180, -112, 0)
		end)
		self.eventTitleLabel:SetActive(true)

		local dialogText = adventureEventTable:getDialogText(self.data.event_id)
		self.eventTitleLabel.text = __(dialogText)
		local modelIndex = adventureEventTable:getModelIndex(self.data.event_id)

		if modelIndex > 0 then
			local name2 = xyd.tables.modelTable:getModelName(self.eventModelList[modelIndex + 1])
			local scale2 = xyd.tables.modelTable:getScale(self.eventModelList[modelIndex + 1])
			self.modelEffect2 = xyd.Spine.new(self.modelNode2)

			self.modelEffect2:setInfo(name2, function ()
				self.modelEffect2:SetLocalScale(-scale2, scale2, scale2)
				self.modelEffect2:play("idle", 0, 1)
				self.modelEffect2:SetLocalPosition(180, -112, 0)
			end)
			self.bubble:SetActive(true)

			local cost = adventureEventTable:getCost(self.data.event_id)

			if adventureEventTable:getType(self.data.event_id) == EventType.COST_AWARD then
				xyd.setUISpriteAsync(self.sceneImg2, nil, "icon_" .. cost[1])
			else
				xyd.setUISpriteAsync(self.sceneImg2, nil, "adven_case_battle")
			end

			self:setEmojiSequence2()

			return
		end

		self.bubble:SetActive(false)
	end
end

function ExploreAdventureWindow:goToAdventureScene(callback)
	self.btnGroup:SetActive(false)
	self.eventTitleLabel:SetActive(true)

	local dialogText = adventureEventTable:getDialogText(self.data.event_id)
	self.eventTitleLabel.text = __(dialogText)
	local modelIndex = adventureEventTable:getModelIndex(self.data.event_id)
	local mapId = adventureEventTable:getMap(self.data.event_id)

	xyd.setUITextureByNameAsync(self.sceneBg1, "explore_scene_" .. mapId)

	local w = self.sceneBg:GetComponent(typeof(UIWidget))
	local getter, setter = xyd.getTweenAlphaGeterSeter(w)
	local sequence = self:getSequence()
	self.isplayAnimation = true

	local function effectAlphaSetter(value)
		self.modelEffect1:setAlpha(value)
	end

	local function effectPosSetter1(x)
		self.modelEffect1:SetLocalPosition(x, -112, 0)
	end

	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0.4):SetEase(DG.Tweening.Ease.Linear))
	sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(effectAlphaSetter), 1, 0.01, 0.2):SetEase(DG.Tweening.Ease.Linear))

	if modelIndex > 0 then
		local name2 = xyd.tables.modelTable:getModelName(self.eventModelList[modelIndex + 1])
		local scale2 = xyd.tables.modelTable:getScale(self.eventModelList[modelIndex + 1])
		self.modelEffect2 = xyd.Spine.new(self.modelNode2)

		self.modelEffect2:setInfo(name2, function ()
			self.modelEffect2:SetLocalScale(-scale2, scale2, scale2)
			self.modelEffect2:play("idle", 0, 1)
			self.modelEffect2:SetLocalPosition(500, -112, 0)
		end)

		local function effectPosSetter2(x)
			self.modelEffect2:SetLocalPosition(x, -112, 0)
		end

		sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(effectPosSetter2), 500, 180, 0.4):SetEase(DG.Tweening.Ease.Linear))
	end

	sequence:AppendCallback(function ()
		xyd.setUITextureByNameAsync(self.sceneBg, "explore_scene_" .. mapId)

		w.alpha = 1

		self.modelEffect1:SetLocalPosition(-500, -112, 0)
		self.modelEffect1:setAlpha(1)
	end)
	sequence:Insert(0.2, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(effectPosSetter1), -500, -180, 0.4):SetEase(DG.Tweening.Ease.Linear))
	sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(function (vlaue)
	end), 0, 0, 0.2))
	sequence:AppendCallback(function ()
		self.sceneImg1:SetActive(true)
		xyd.setUISpriteAsync(self.sceneImg1, nil, secneCaseImg[mapId])

		self.sceneImg1.alpha = 0.01
	end)

	local getter1, setter1 = xyd.getTweenAlphaGeterSeter(self.sceneImg1:GetComponent(typeof(UIWidget)))

	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter1, setter1, 1, 0.2):SetEase(DG.Tweening.Ease.Linear))
	sequence:AppendCallback(function ()
		self.isplayAnimation = false

		if modelIndex > 0 then
			self.bubble:SetActive(true)

			local cost = adventureEventTable:getCost(self.data.event_id)

			if adventureEventTable:getType(self.data.event_id) == EventType.COST_AWARD then
				xyd.setUISpriteAsync(self.sceneImg2, nil, "icon_" .. cost[1])
			else
				xyd.setUISpriteAsync(self.sceneImg2, nil, "adven_case_battle")
			end

			self.sceneImg2:SetLocalScale(1, 1, 1)
			self:setEmojiSequence2()
		end

		if callback then
			callback()
		end

		sequence:Kill(false)

		sequence = nil
	end)
	self:setEmojiSequence1()
end

function ExploreAdventureWindow:setEmojiSequence1()
	self.emojiSequence1 = self:getSequence()

	self.sceneImg1:Y(self.sceneImg1OriginY)
	self.emojiSequence1:Append(self.sceneImg1.transform:DOLocalMoveY(self.sceneImg1OriginY + 5, 0.8))
	self.emojiSequence1:SetLoops(-1, DG.Tweening.LoopType.Yoyo)
end

function ExploreAdventureWindow:setEmojiSequence2()
	self.emojiSequence2 = self:getSequence()

	self.emojiSequence2:Append(self.sceneImg2.transform:DOScale(0.85, 0.9))
	self.emojiSequence2:Append(self.sceneImg2.transform:DOScale(1, 0.9))
	self.emojiSequence2:SetLoops(-1)
end

function ExploreAdventureWindow:backToBaseScene(callback)
	if self.onAutoAdven then
		self.btnGroup:SetActive(false)
	else
		self.btnGroup:SetActive(true)
	end

	self.eventTitleLabel.text = ""

	self.eventTitleLabel:SetActive(false)

	local tm = os.date("*t")

	if tm.hour >= 6 and tm.hour <= 18 then
		xyd.setUITextureByNameAsync(self.sceneBg1, "explore_scene_day")
	else
		xyd.setUITextureByNameAsync(self.sceneBg1, "explore_scene_night")
	end

	local w = self.sceneBg:GetComponent(typeof(UIWidget))
	local getter, setter = xyd.getTweenAlphaGeterSeter(w)
	local sequence = self:getSequence()
	self.isplayAnimation = true

	local function effectAlphaSetter1(value)
		self.modelEffect1:setAlpha(value)
	end

	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0.4):SetEase(DG.Tweening.Ease.Linear))
	sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(effectAlphaSetter1), 1, 0.01, 0.4):SetEase(DG.Tweening.Ease.Linear))

	if self.modelEffect2 then
		local function effectAlphaSetter2(value)
			self.modelEffect2:setAlpha(value)
		end

		sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(effectAlphaSetter2), 1, 0.01, 0.4):SetEase(DG.Tweening.Ease.Linear))
	end

	sequence:AppendCallback(function ()
		if tm.hour >= 6 and tm.hour <= 18 then
			xyd.setUITextureByNameAsync(self.sceneBg, "explore_scene_day")
		else
			xyd.setUITextureByNameAsync(self.sceneBg, "explore_scene_night")
		end

		w.alpha = 1

		self.modelEffect1:SetLocalPosition(0, -112, 0)

		if self.modelEffect2 then
			self.modelEffect2:destroy()
		end

		self.sceneImg1:SetActive(false)

		if self.emojiSequence1 then
			self.emojiSequence1:Kill(false)

			self.emojiSequence1 = nil
		end

		self.bubble:SetActive(false)

		if self.emojiSequence2 then
			self.emojiSequence2:Kill(false)

			self.emojiSequence2 = nil
		end
	end)
	sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(effectAlphaSetter1), 0.01, 1, 0.4):SetEase(DG.Tweening.Ease.Linear))
	sequence:AppendCallback(function ()
		self.isplayAnimation = false

		if callback then
			callback()
		end

		sequence:Kill(false)

		sequence = nil
	end)
end

function ExploreAdventureWindow:goToAdventure()
	if not self.isplayAnimation then
		if xyd.models.backpack:getItemNumByID(self.adventureCost[1]) < self.adventureCost[2] then
			if self.onAutoAdven then
				self:stopAutoAdventure()
			end

			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(self.adventureCost[1]))))
			self:openBreadBuyWindow()
		elseif self.lastBoxNum == self.slotNum then
			xyd.WindowManager.get():openWindow("explore_buy_tips_window", {
				noTodayTips = true,
				text = __("TRAVEL_MAIN_TEXT30"),
				yesCallBack = function ()
					exploreModel:reqAdventureInfo()
				end
			})
		else
			exploreModel:reqAdventureInfo()
		end
	end
end

function ExploreAdventureWindow:dealAdventureEvent()
	if not self.isplayAnimation then
		local evtType = adventureEventTable:getType(self.data.event_id)

		if evtType == EventType.BATTLE then
			local cost = adventureEventTable:getCost(self.data.event_id)

			if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(cost[1]))))
				self:openBreadBuyWindow()
			else
				xyd.WindowManager.get():openWindow("explore_adventure_prepare_window", {
					eventID = self.data.event_id,
					battleID = self.data.battle_id,
					lv = self.data.lv
				})
			end
		else
			local cost = adventureEventTable:getCost(self.data.event_id)

			if next(cost) ~= nil and xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(cost[1]))))

				if tonumber(cost[1]) == xyd.ItemID.DELICIOUS_BREAD then
					self:openBreadBuyWindow()
				end
			else
				exploreModel:reqAdventureCost({})
			end
		end
	end
end

function ExploreAdventureWindow:openBreadBuyWindow()
	if not self.openBreadBuyWindowing then
		self.openBreadBuyWindowing = true

		self:waitForTime(0.5, function ()
			xyd.WindowManager.get():openWindow("explore_source_buy_window", nil, function ()
				self.openBreadBuyWindowing = false
			end)
		end)
	end
end

function ExploreAdventureWindow:onBuyBread(event)
	if self.data.event_id == 0 then
		if xyd.models.backpack:getItemNumByID(self.adventureCost[1]) < self.adventureCost[2] then
			self.labelCost.color = Color.New2(3981269247.0)
		else
			self.labelCost.color = Color.New2(1363960063)
		end
	else
		local cost = adventureEventTable:getCost(self.data.event_id)

		if next(cost) ~= nil and tonumber(cost[1]) == xyd.ItemID.DELICIOUS_BREAD then
			if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
				self.labelCost.color = Color.New2(3981269247.0)
			else
				self.labelCost.color = Color.New2(1363960063)
			end
		end
	end
end

function ExploreAdventureWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_ADVENTURE_EVENT, handler(self, self.onGetAdventureInfo))
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_ADVENTURE_COST, handler(self, self.onGetAdvenEventResult))
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_ADVENTURE_OPEN_CHEST, handler(self, self.onOpenAdventureChest))
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_ADVENTURE_UPGRADE, handler(self, self.onLevelUp))
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_BUY_BREAD, handler(self, self.onBuyBread))
	self.eventProxy_:addEventListener(xyd.event.BATCH_CHEST_OPEN, handler(self, self.onOpenBoxAll))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.tipsBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("explore_box_detail_window")
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("explore_help_window", {
			key = "TRAVEL_EXPLORE_HELP_U3"
		})
	end

	UIEventListener.Get(self.btnLevelUp).onClick = function ()
		xyd.WindowManager.get():openWindow("adventure_level_up_window")
	end

	UIEventListener.Get(self.btnLeftLabel.gameObject).onClick = function ()
		if not self.isplayAnimation then
			local timeStamp = xyd.db.misc:getValue("adventure_left_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				xyd.WindowManager.get():openWindow("explore_buy_tips_window", {
					timeStampKey = "adventure_left_stamp",
					text = __("TRAVEL_MAIN_TEXT59"),
					yesCallBack = function ()
						exploreModel:reqAdventureCost({
							is_cancel = 1
						})
					end
				})
			else
				exploreModel:reqAdventureCost({
					is_cancel = 1
				})
			end
		end
	end

	UIEventListener.Get(self.btnGO).onClick = handler(self, self.dealAdventureEvent)

	UIEventListener.Get(self.btnAdven).onClick = function ()
		if self.autoAdvenIsOpen then
			if not xyd.db.formation:getValue(xyd.BattleType.EXPLORE_ADVENTURE) then
				xyd.WindowManager.get():openWindow("adventure_battle_formation_window", {
					isSetting = true,
					battleType = xyd.BattleType.EXPLORE_ADVENTURE,
					showSkip = self.travelQuickLimit <= self.data.lv,
					skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("explore_adventure_skip_report")) == 1, true, false),
					btnSkipCallback = function (flag)
						local valuedata = xyd.checkCondition(flag, 1, 0)

						xyd.db.misc:setValue({
							key = "explore_adventure_skip_report",
							value = valuedata
						})
					end
				})
			else
				self:startAutoAdventure()
			end
		else
			self:goToAdventure()
		end
	end

	UIEventListener.Get(self.btnChange).onClick = function ()
		xyd.WindowManager.get():openWindow("explore_change_model_window", {
			confirmCallback = function (itemID)
				local modelID = nil
				local type = xyd.tables.itemTable:getType(itemID)

				if type == xyd.ItemType.SKIN or type == xyd.ItemType.FAKE_PARTNER_SKIN then
					modelID = xyd.tables.equipTable:getSkinModel(itemID)
				else
					modelID = xyd.tables.partnerTable:getModelID(itemID)
				end

				if modelID ~= self.mainModelID then
					self.mainModelID = modelID
					local pos = self.modelEffect1.go.transform.localPosition
					local name1 = xyd.tables.modelTable:getModelName(modelID)
					local scale1 = xyd.tables.modelTable:getScale(modelID)

					NGUITools.DestroyChildren(self.modelNode1.transform)

					self.modelEffect1 = xyd.Spine.new(self.modelNode1)

					self.modelEffect1:setInfo(name1, function ()
						self.modelEffect1:setToSetupPose()
						self.modelEffect1:SetLocalScale(scale1, scale1, scale1)
						self.modelEffect1:play("idle", 0, 1)
						self.modelEffect1:SetLocalPosition(pos.x, pos.y, pos.z)
					end)
				end
			end
		})
	end

	UIEventListener.Get(self.btnOpenBox).onClick = handler(self, self.openBoxAll)

	UIEventListener.Get(self.autoAdven).onClick = function ()
		self.autoAdvenIsOpen = not self.autoAdvenIsOpen

		self.iconON:SetActive(self.autoAdvenIsOpen)
		self.iconOFF:SetActive(not self.autoAdvenIsOpen)
		xyd.db.misc:setValue({
			key = "auto_adventure_is_open",
			value = self.autoAdvenIsOpen and 1 or 0
		})

		local value = xyd.db.misc:getValue("auto_adventure_setup")

		if not value then
			xyd.WindowManager.get():openWindow("auto_adventure_setup_window")
		end
	end

	UIEventListener.Get(self.btnSetup).onClick = function ()
		xyd.WindowManager.get():openWindow("auto_adventure_setup_window")
	end

	UIEventListener.Get(self.btnFormation).onClick = function ()
		xyd.WindowManager.get():openWindow("adventure_battle_formation_window", {
			isSetting = true,
			battleType = xyd.BattleType.EXPLORE_ADVENTURE,
			showSkip = self.travelQuickLimit <= self.data.lv,
			skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("explore_adventure_skip_report")) == 1, true, false),
			btnSkipCallback = function (flag)
				local valuedata = xyd.checkCondition(flag, 1, 0)

				xyd.db.misc:setValue({
					key = "explore_adventure_skip_report",
					value = valuedata
				})
			end
		})
	end

	UIEventListener.Get(self.btnStopAutoAdven).onClick = function ()
		self:stopAutoAdventure()
	end
end

function ExploreAdventureWindow:openBoxAll()
	local freeList = {}
	local costList = {}

	for i = 1, self.slotNum do
		if self.giftBoxItemList[i].id > 0 then
			if self.giftBoxItemList[i].isFree then
				table.insert(freeList, i)
			else
				table.insert(costList, {
					boxID = self.giftBoxItemList[i].id,
					boxIndex = self.giftBoxItemList[i].boxIndex
				})
			end
		end
	end

	if next(freeList) then
		exploreModel:bacthChestOpen(freeList)
	elseif next(costList) then
		xyd.WindowManager.get():openWindow("adventure_box_preview_window", {
			boxList = costList
		})
	else
		xyd.showToast(__("TRAVEL_NEW_TEXT15"))
	end
end

function ExploreAdventureWindow:startAutoAdventure()
	self.onAutoAdven = true

	self:setBtn()
	self:autoGoToAdventure()
end

function ExploreAdventureWindow:stopAutoAdventure()
	self.onAutoAdven = false

	if self.data.event_id == 0 then
		self.btnGroup:SetActive(true)
	end

	self:setBtn()
end

function ExploreAdventureWindow:autoGoToAdventure()
	if not self.onAutoAdven then
		self:stopAutoAdventure()

		return
	end

	if xyd.models.backpack:getItemNumByID(self.adventureCost[1]) < self.adventureCost[2] then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(self.adventureCost[1]))))
		self:openBreadBuyWindow()
		self:stopAutoAdventure()

		return
	end

	local spSetUpList = exploreModel:getSpSetUpList()

	if self.lastBoxNum == self.slotNum then
		local hasFree = false

		for i = 1, self.slotNum do
			if self.giftBoxItemList[i].id > 0 and self.giftBoxItemList[i].isFree then
				hasFree = true

				break
			end
		end

		if hasFree then
			self:openBoxAll()
		elseif tonumber(spSetUpList[1]) == 1 then
			local cheapestIndex = 1
			local cost = xyd.tables.adventureBoxTable:getCost(self.giftBoxItemList[1].id)

			for i = 1, self.slotNum do
				if self.giftBoxItemList[i].id > 0 then
					local tempCost = xyd.tables.adventureBoxTable:getCost(self.giftBoxItemList[i].id)

					if tempCost[2] < cost[2] then
						cheapestIndex = i
						cost = tempCost
					end
				end
			end

			if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(cost[1]))))
				self:stopAutoAdventure()
			else
				exploreModel:reqOpenAdventureChest(cheapestIndex, 1)
			end
		else
			xyd.showToast(__("TRAVEL_NEW_TEXT13"))
			self:stopAutoAdventure()
		end
	else
		self:goToAdventure()
	end
end

function ExploreAdventureWindow:autoDealAdventureEvent()
	if not self.onAutoAdven then
		self:stopAutoAdventure()

		return
	end

	local setUpList = exploreModel:getSetUpList()
	local eventType = adventureEventTable:getType(self.data.event_id)

	local function checkCost(cost)
		if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
			self:stopAutoAdventure()
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(cost[1]))))
		else
			exploreModel:reqAdventureCost({})
		end
	end

	if eventType == EventType.BATTLE then
		if tonumber(setUpList[3]) == 1 then
			local cost = adventureEventTable:getCost(self.data.event_id)

			if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
				self:stopAutoAdventure()
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(cost[1]))))
				self:openBreadBuyWindow()
			else
				local data = cjson.decode(xyd.db.formation:getValue(xyd.BattleType.EXPLORE_ADVENTURE))
				local partners = {}

				for i = 1, #data.partners do
					if tonumber(data.partners[i]) and data.partners[i] > 0 then
						table.insert(partners, {
							pos = i,
							partner_id = data.partners[i]
						})
					end
				end

				xyd.models.exploreModel:reqAdventureCost({
					pet_id = data.pet_id,
					partners = partners
				})
			end
		else
			exploreModel:reqAdventureCost({
				is_cancel = 1
			})
		end
	elseif self.data.event_id == 6 then
		if tonumber(setUpList[1]) == 1 then
			local cost = adventureEventTable:getCost(self.data.event_id)

			checkCost(cost)
		else
			exploreModel:reqAdventureCost({
				is_cancel = 1
			})
		end
	elseif self.data.event_id == 8 then
		if tonumber(setUpList[2]) == 1 then
			local cost = adventureEventTable:getCost(self.data.event_id)

			checkCost(cost)
		else
			exploreModel:reqAdventureCost({
				is_cancel = 1
			})
		end
	else
		local cost = adventureEventTable:getCost(self.data.event_id)

		if next(cost) then
			checkCost(cost)
		else
			exploreModel:reqAdventureCost({})
		end
	end
end

function ExploreAdventureWindow:onGetAdventureInfo(event)
	self.data = exploreModel:getExploreInfo()

	self.btnAdven:SetActive(false)
	self.groupCost_:SetActive(false)
	self.autoAdven:SetActive(false)
	self:goToAdventureScene(function ()
		if self.onAutoAdven then
			self:autoDealAdventureEvent()
		else
			self:setBtn()
		end
	end)
end

function ExploreAdventureWindow:onGetAdvenEventResult(event)
	self.data = exploreModel:getExploreInfo()
	local lastEventID = exploreModel:getLastAdventureEventID()

	if (adventureEventTable:getType(lastEventID) ~= EventType.BATTLE or self.onAutoAdven) and event.data.items then
		xyd.models.itemFloatModel:pushNewItems(event.data.items)
	end

	if event.data.battle_result and event.data.battle_result.battle_report.isWin == 0 and tonumber(exploreModel:getSpSetUpList()[2]) == 1 and self.onAutoAdven then
		xyd.showToast(__("TRAVEL_NEW_TEXT12"))

		self.onAutoAdven = false

		self.btnStopAutoAdven:SetActive(false)
		self.labelAutoAdvening:SetActive(false)
	end

	self:setGiftBoxContent()
	self.btnGO:SetActive(false)
	self.btnLeft:SetActive(false)
	self.groupCost_:SetActive(false)
	self:backToBaseScene(function ()
		if self.onAutoAdven then
			self:autoGoToAdventure()
		else
			self:setBtn()
		end
	end)
end

function ExploreAdventureWindow:onOpenAdventureChest(event)
	self.data = exploreModel:getExploreInfo()

	xyd.models.itemFloatModel:pushNewItems(event.data.items)
	self:setGiftBoxContent()

	if self.onAutoAdven then
		self:autoGoToAdventure()
	end
end

function ExploreAdventureWindow:onOpenBoxAll(event)
	local chests = event.data.chests
	local tempList = {}

	for _, item in ipairs(chests) do
		for _, data in ipairs(item.items) do
			tempList[data.item_id] = (tempList[data.item_id] or 0) + data.item_num
		end
	end

	local res = {}

	for item_id, item_num in pairs(tempList) do
		table.insert(res, {
			item_id = item_id,
			item_num = item_num
		})
	end

	xyd.models.itemFloatModel:pushNewItems(res)

	self.data = exploreModel:getExploreInfo()

	self:setGiftBoxContent()

	if self.onAutoAdven then
		self:autoGoToAdventure()
	end
end

function ExploreAdventureWindow:onLevelUp(event)
	self.data = exploreModel:getExploreInfo()

	if self.travelQuickLimit <= self.data.lv and self.data.event_id == 0 then
		self.autoAdven:SetActive(true)
		self.btnSetup:SetActive(true)
		self.btnFormation:SetActive(true)
		self.btnOpenBox:SetActive(true)
	else
		self.autoAdven:SetActive(false)
		self.btnSetup:SetActive(false)
		self.btnFormation:SetActive(false)
		self.btnOpenBox:SetActive(false)
	end

	self:setAdventureData()
end

function ExploreAdventureWindow:onItemChange(event)
	local items = event.data.items

	for _, item in ipairs(items) do
		if item.item_id == xyd.ItemID.DELICIOUS_BREAD then
			self.resBread_:updateNum()
		elseif item.item_id == xyd.ItemID.CRYSTAL then
			self.resCrystal:updateNum()
		end
	end
end

function BoxFormationItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:getUIComponent()
	self:register()
end

function BoxFormationItem:getUIComponent()
	local go = self.go
	self.bg = go:NodeByName("bg").gameObject
	self.openBg = go:NodeByName("openBg").gameObject
	self.qltLabel = go:ComponentByName("qltLabel", typeof(UILabel))
	self.boxImg = go:ComponentByName("boxImg", typeof(UISprite))
	self.openLabel1 = go:ComponentByName("openLabel1", typeof(UILabel))
	self.openLabel2 = go:ComponentByName("openLabel2", typeof(UILabel))
	self.groupCost_ = go:NodeByName("groupCost_").gameObject
	self.labelCost = self.groupCost_:ComponentByName("labelCost", typeof(UILabel))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.effectNode = self.timeGroup:NodeByName("effectNode").gameObject
	self.clockEffect_ = xyd.Spine.new(self.effectNode)

	self.clockEffect_:setInfo("fx_ui_shizhong", function ()
		self.clockEffect_:play("texiao1", 0)
		self.clockEffect_:SetLocalScale(0.9, 0.9, 0.9)
	end)

	self.openLabel1.text = __("TRAVEL_MAIN_TEXT25")
	self.openLabel2.text = __("TRAVEL_MAIN_TEXT26")
	self.getEffectNode = go:NodeByName("effect").gameObject

	if xyd.Global.lang == "fr_fr" then
		self.qltLabel.fontSize = 16
	end
end

function BoxFormationItem:register()
	UIEventListener.Get(self.openBg).onClick = function ()
		if self.parent.onAutoAdven then
			xyd.showToast(__("TRAVEL_NEW_TEXT16"))

			return
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		exploreModel:reqOpenAdventureChest(self.boxIndex, 0)
	end

	xyd.setDragScrollView(self.bg, self.parent.boxScroller)
	xyd.setDragScrollView(self.openBg, self.parent.boxScroller)
end

function BoxFormationItem:setInfo(info)
	self.id = info.boxID or 0
	self.updateTime = info.updateTime
	self.boxIndex = info.boxIndex
	self.isNew = info.isNew
	self.isFree = false
	local boxTable = xyd.tables.adventureBoxTable

	if self.id == 0 then
		NGUITools.DestroyChildren(self.getEffectNode.transform)
		self.boxImg:SetActive(true)
		xyd.setUISpriteAsync(self.boxImg, nil, "icon_bx_" .. self.id, nil, , true)
		self.openBg:SetActive(false)
		self.qltLabel:SetActive(false)
		self.openLabel1:SetActive(false)
		self.openLabel2:SetActive(false)
		self.groupCost_:SetActive(false)
		self.timeGroup:SetActive(false)
	else
		self.qltLabel:SetActive(true)

		self.qltLabel.text = __("TRAVEL_MAIN_TEXT24", self.id)
		local lastTime = boxTable:getTimeCost(self.id)
		local duration = self.updateTime + lastTime - xyd.getServerTime()

		if duration > 0 then
			xyd.setUISpriteAsync(self.boxImg, nil, "icon_bx_" .. self.id, nil, , true)
			self.boxImg:SetLocalScale(0.84, 0.84, 0.84)
			NGUITools.DestroyChildren(self.getEffectNode.transform)

			if self.isNew then
				self.boxImg:SetActive(false)

				local effect = xyd.Spine.new(self.getEffectNode)

				effect:setInfo("travel_box_all", function ()
					effect:SetLocalScale(0.84, 0.84, 0.84)
					effect:play("icon_bx_" .. self.id, 1, 1, function ()
						self.boxImg:SetActive(true)
						effect:destroy()

						effect = nil

						NGUITools.DestroyChildren(self.getEffectNode.transform)
					end)
					effect:startAtFrame(0)
				end, true)
			end

			self.openBg:SetActive(false)
			self.openLabel1:SetActive(true)
			self.openLabel2:SetActive(false)
			self.groupCost_:SetActive(true)
			self.timeGroup:SetActive(true)

			local cost = boxTable:getCost(self.id)
			self.labelCost.text = cost[2]

			if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
				self.labelCost.color = Color.New2(3981269247.0)
			end

			if not self.timeLabelCount_ then
				self.timeLabelCount_ = import("app.components.CountDown").new(self.timeLabel)
			end

			self.timeLabelCount_:setInfo({
				duration = duration,
				callback = function ()
					xyd.setUISpriteAsync(self.boxImg, nil, "icon_bx_" .. self.id .. "_2", nil, , true)

					local effect = xyd.Spine.new(self.getEffectNode)

					effect:setInfo("travel_other", function ()
						effect:play("travel_other_01", 0, 1)
					end)
					self.openBg:SetActive(true)
					self.openLabel1:SetActive(false)
					self.openLabel2:SetActive(true)
					self.groupCost_:SetActive(false)
					self.timeGroup:SetActive(false)

					self.isFree = true
				end
			})
		else
			self.isFree = true

			NGUITools.DestroyChildren(self.getEffectNode.transform)

			local effect = xyd.Spine.new(self.getEffectNode)

			effect:setInfo("travel_other", function ()
				effect:play("travel_other_01", 0, 1)
			end)
			xyd.setUISpriteAsync(self.boxImg, nil, "icon_bx_" .. self.id .. "_2", nil, , true)
			self.openBg:SetActive(true)
			self.openLabel1:SetActive(false)
			self.openLabel2:SetActive(true)
			self.groupCost_:SetActive(false)
			self.timeGroup:SetActive(false)
		end
	end
end

function BoxFormationItem:initBox(isLocked)
	if isLocked then
		xyd.setUISpriteAsync(self.bg:GetComponent(typeof(UISprite)), nil, "gift_bg_2")

		self.qltLabel.text = __("TRAVEL_MAIN_TEXT22")

		xyd.setUISpriteAsync(self.boxImg, nil, "btn_locked", function ()
			self.boxImg.gameObject:SetLocalScale(0.8, 0.8, 0.8)
		end, nil, true)

		UIEventListener.Get(self.bg).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
			xyd.showToast(__("TRAVEL_MAIN_TEXT52"))
		end

		self.openBg:SetActive(false)
		self.openLabel1:SetActive(false)
		self.openLabel2:SetActive(false)
		self.groupCost_:SetActive(false)
		self.timeGroup:SetActive(false)
	else
		xyd.setUISpriteAsync(self.bg:GetComponent(typeof(UISprite)), nil, "gift_bg_1")

		UIEventListener.Get(self.bg).onClick = function ()
			if self.parent.onAutoAdven then
				xyd.showToast(__("TRAVEL_NEW_TEXT16"))

				return
			end

			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

			if self.id and self.id ~= 0 then
				xyd.WindowManager.get():openWindow("adventure_box_preview_window", {
					boxIndex = self.boxIndex,
					boxID = self.id,
					updateTime = self.updateTime
				})
			end
		end
	end
end

return ExploreAdventureWindow
