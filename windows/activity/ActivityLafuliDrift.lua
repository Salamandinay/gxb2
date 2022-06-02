local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ActivityLafuliDrift = class("ActivityLafuliDrift", ActivityContent)
local cjson = require("cjson")
local cellCenter = {
	{
		x = -275,
		y = 275
	},
	{
		x = -165,
		y = 275
	},
	{
		x = -55,
		y = 275
	},
	{
		x = 55,
		y = 275
	},
	{
		x = 165,
		y = 275
	},
	{
		x = 275,
		y = 275
	},
	{
		x = 275,
		y = 165
	},
	{
		x = 275,
		y = 55
	},
	{
		x = 275,
		y = -55
	},
	{
		x = 275,
		y = -165
	},
	{
		x = 275,
		y = -275
	},
	{
		x = 165,
		y = -275
	},
	{
		x = 55,
		y = -275
	},
	{
		x = -55,
		y = -275
	},
	{
		x = -165,
		y = -275
	},
	{
		x = -275,
		y = -275
	},
	{
		x = -275,
		y = -165
	},
	{
		x = -275,
		y = -55
	},
	{
		x = -275,
		y = 55
	},
	{
		x = -275,
		y = 165
	},
	{
		x = -275,
		y = 385
	}
}
local BUFFS_TYPE = {
	DOWN_BLOCK = 6,
	DOUBLE_MOVE = 2,
	GET_ITEM = 1,
	HALF_MOVE = 10,
	BACK = 7,
	DOUBLE_DICE = 3,
	DOUBLE_SCORE = 4,
	NO_ITEM = 8,
	UP_BLOCK = 5,
	TRANSFORM = 9
}

function ActivityLafuliDrift:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function ActivityLafuliDrift:getPrefabPath()
	return "Prefabs/Windows/activity/activity_lafuli_drift"
end

function ActivityLafuliDrift:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)

	self.modelPos = self.activityData.detail.pos
	self.lvs = self.activityData.detail.slot_lvs
	self.leadedDice = nil
	self.select = 0
	self.select1 = 0
	self.select2 = 0
	self.onGoing = false
	self.isDouble = false
	self.rudderDouble = false
	self.isCry = false
	self.isStar = false
	self.isRevert = false
	self.autoPlayTimes = 0
	self.skipAni = xyd.db.misc:getValue("lafuli_drift_skipani")
	self.skipAni = self.skipAni ~= nil and tonumber(self.skipAni) == 1 or false

	self:layout()
	self:refresh()
	self:registEvent()
	dump(self.activityData.detail.shop_times)
	self:autoPlay()
end

function ActivityLafuliDrift:getUIComponent()
	local go = self.go
	self.mainGroup = go:NodeByName("main").gameObject
	self.helpBtn = self.mainGroup:NodeByName("btnGroup/helpBtn").gameObject
	self.chestBtn = self.mainGroup:NodeByName("btnGroup/chestBtn").gameObject
	self.shopBtn = self.mainGroup:NodeByName("btnGroup/shopBtn").gameObject
	self.shopNum = self.shopBtn:ComponentByName("num", typeof(UILabel))
	self.textImg = self.mainGroup:ComponentByName("textImg", typeof(UITexture))
	self.timerGroup = self.mainGroup:NodeByName("textImg/timerGroup").gameObject
	self.timeLabel = self.mainGroup:ComponentByName("textImg/timerGroup/timeLabel", typeof(UILabel))
	self.endLabel = self.mainGroup:ComponentByName("textImg/timerGroup/endLabel", typeof(UILabel))
	self.touchField = self.mainGroup:NodeByName("touchField").gameObject

	self.touchField:SetActive(false)

	self.buttomGroup = self.mainGroup:NodeByName("buttomGroup").gameObject
	self.skipBtn = self.buttomGroup:NodeByName("skipBtn").gameObject
	self.skipCheck = self.skipBtn:ComponentByName("check", typeof(UISprite))
	self.autoBtn = self.buttomGroup:NodeByName("autoBtn").gameObject
	self.autoLabel = self.autoBtn:ComponentByName("label", typeof(UILabel))
	self.autoBg = self.autoBtn:ComponentByName("bg", typeof(UISprite))
	self.itemGroup = self.buttomGroup:NodeByName("itemGroup").gameObject
	self.itemGroupBg = self.itemGroup:ComponentByName("bg", typeof(UISprite))
	self.itemProgress = self.itemGroup:ComponentByName("progressBar", typeof(UIProgressBar))
	self.itemProgressLabel = self.itemProgress:ComponentByName("progressLabel", typeof(UILabel))
	self.itemGroupItemIcon = self.itemGroup:NodeByName("itemGroup").gameObject
	self.rudderGroup = self.buttomGroup:NodeByName("rudderGroup").gameObject
	self.rudderBtn1 = self.rudderGroup:NodeByName("rudderBtn1").gameObject
	self.rudderBtn2 = self.rudderGroup:NodeByName("rudderBtn2").gameObject
	self.pointer = self.rudderGroup:NodeByName("pointer").gameObject
	self.itemGroup1 = self.rudderGroup:NodeByName("itemGroup1").gameObject
	self.itemGroupLabel1 = self.itemGroup1:ComponentByName("label", typeof(UILabel))
	self.itemGroup2 = self.rudderGroup:NodeByName("itemGroup2").gameObject
	self.itemGroupLabel2 = self.itemGroup2:ComponentByName("label", typeof(UILabel))
	self.plusBtn = self.itemGroup2:NodeByName("btn").gameObject
	self.cellGroup = self.buttomGroup:NodeByName("cellGroup").gameObject

	for i = 1, 5 do
		self["cell" .. i] = self.cellGroup:NodeByName("cell" .. i).gameObject
	end

	self.model = self.cellGroup:NodeByName("model")
	self.numGroup = self.model:NodeByName("numGroup")
	self.numLabel = self.numGroup:ComponentByName("label", typeof(UILabel))
	self.cellModel = self.cellGroup:NodeByName("cellModel")
	self.selectWnd = go:NodeByName("activity_drift_select_window").gameObject
	local groupMain = self.selectWnd:NodeByName("groupMain").gameObject
	self.selectBg = self.selectWnd:NodeByName("bg").gameObject
	self.rudder = groupMain:NodeByName("rudder").gameObject
	self.rudder1 = groupMain:NodeByName("rudder1").gameObject
	self.rudder2 = groupMain:NodeByName("rudder2").gameObject
	self.selectBtn = groupMain:NodeByName("btn").gameObject
	self.selectBtnLabel = self.selectBtn:ComponentByName("label", typeof(UILabel))
	self.selectLabel = groupMain:ComponentByName("label", typeof(UILabel))
	self.rudderMask = self.rudder:NodeByName("mask").gameObject

	for i = 1, 6 do
		self["select_" .. i] = self.rudder:NodeByName("select" .. i).gameObject
		self["selected_" .. i] = self["select_" .. i]:NodeByName("selected").gameObject
	end

	self.rudderMask1 = self.rudder1:NodeByName("mask").gameObject

	for i = 1, 6 do
		self["select1_" .. i] = self.rudder1:NodeByName("select" .. i).gameObject
		self["selected1_" .. i] = self["select1_" .. i]:NodeByName("selected").gameObject
	end

	self.rudderMask2 = self.rudder2:NodeByName("mask").gameObject

	for i = 1, 6 do
		self["select2_" .. i] = self.rudder2:NodeByName("select" .. i).gameObject
		self["selected2_" .. i] = self["select2_" .. i]:NodeByName("selected").gameObject
	end

	self.selectWnd:SetActive(false)

	self.tipsWnd = self.cellGroup:NodeByName("activity_drift_tips_window").gameObject
	self.tipsMain = self.tipsWnd:NodeByName("groupMain").gameObject
	self.tipsBg = self.tipsMain:ComponentByName("bg", typeof(UISprite))
	self.tipsName = self.tipsMain:ComponentByName("name", typeof(UILabel))
	self.tipsLabel = self.tipsMain:ComponentByName("label", typeof(UILabel))
	self.tipsIcon = self.tipsMain:ComponentByName("icon", typeof(UISprite))

	self.tipsWnd:SetActive(false)

	self.guide = go:NodeByName("guide_window").gameObject
	self.guideModel = self.guide:NodeByName("fingerModel").gameObject

	self.guide:SetActive(false)
end

function ActivityLafuliDrift:resizeToParent()
	ActivityContent.resizeToParent(self)

	local height = self.parentWidget.height

	self.textImg:Y(-0.2135 * height + 100)
	self.buttomGroup:Y(-0.393 * height - 250)
	self.selectWnd:Y(-height + 548)
	self.guide:Y(-0.393 * height - 188 + 600)
end

function ActivityLafuliDrift:layout()
	xyd.setUITextureByNameAsync(self.textImg, "activity_lafuli_drift_title_" .. xyd.Global.lang, true)

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.endLabel.text = __("END")
	local nextID = xyd.tables.activityDriftAwardTable:getNextID(self.activityData.detail.point)
	local nextPoint = xyd.tables.activityDriftAwardTable:getPoint(nextID)
	local nextAwards = xyd.tables.activityDriftAwardTable:getAwards(nextID)
	local ids = xyd.tables.activityDriftAwardTable:getIDs()
	local number = math.floor(self.activityData.detail.point / 300) * 300
	self.itemProgress.value = self.activityData.detail.point % xyd.tables.activityDriftAwardTable:getPoint(ids[#ids]) / nextPoint
	self.itemProgressLabel.text = self.activityData.detail.point % xyd.tables.activityDriftAwardTable:getPoint(ids[#ids]) + number .. "/" .. nextPoint + number
	self.shopNum.text = "X" .. xyd.models.backpack:getItemNumByID(xyd.ItemID.DRIFT_SHOP_COIN)

	NGUITools.DestroyChildren(self.itemGroupItemIcon.transform)

	for i = 1, #nextAwards do
		local icon = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.6018518518518519,
			itemID = nextAwards[i][1],
			num = nextAwards[i][2],
			uiRoot = self.itemGroupItemIcon,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	if #nextAwards == 2 then
		self.itemGroupBg.width = 430

		self.itemProgress:X(-191)
	else
		self.itemGroupBg.width = 364

		self.itemProgress:X(-157)
	end

	self.itemGroupItemIcon:GetComponent(typeof(UILayout)):Reposition()

	self.selectLabel.text = __("ACTIVITY_LAFULI_DRIFT_GO")
	self.selectBtnLabel.text = __("FOR_SURE")

	self.skipCheck:SetActive(self.skipAni)

	if xyd.Global.lang == "de_de" then
		self.endLabel.fontSize = 14
	end

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
		self.timerGroup:GetComponent(typeof(UILayout)):Reposition()
	end

	self.autoLabel.text = __("ACTIVITY_LAFULI_DRIFT_AUTO_WINDOW")
	self.autoLabel.color = Color.New2(1012112383)
	self.autoLabel.effectColor = Color.New2(4294967295.0)

	self.model:SetLocalPosition(cellCenter[self.modelPos].x, cellCenter[self.modelPos].y - 13, 0)

	if self.modelPos == 21 then
		self.modelPos = 0
	end

	if self.modelPos >= 0 and self.modelPos <= 10 then
		self.model:SetLocalScale(-1, 1, 1)
		self.numGroup:SetLocalScale(-1, 1, 1)
	end

	if not self.modelEffect then
		self.modelEffect = xyd.Spine.new(self.model.gameObject)

		self.modelEffect:setInfo("lafuli_drift", function ()
			self.modelEffect:play("idle", 0, 1)
			self.modelEffect:SetLocalScale(1, 1, 1)
		end)
	else
		self.modelEffect:SetActive(true)
	end

	local buff = self.activityData.detail.buffs[1]
	self.buffs = self.activityData.detail.buffs

	self:waitForFrame(1, function ()
		if buff == BUFFS_TYPE.DOUBLE_MOVE then
			self.rudderDouble = true

			self:refreshx2()
		elseif buff == BUFFS_TYPE.DOUBLE_DICE then
			self.isDouble = true

			self:refreshx2()
		elseif buff == BUFFS_TYPE.DOUBLE_SCORE then
			self.isStar = true

			self.modelEffect:play("star", 0, 1)
			self:refreshCoralx2()
		elseif buff == BUFFS_TYPE.BACK then
			self.isCry = true

			self.modelEffect:play("cry", 0, 1)

			self.isRevert = true
		elseif buff == BUFFS_TYPE.NO_ITEM then
			self.isCry = true

			self.modelEffect:play("cry", 0, 1)
		elseif xyd.tables.activityLafuliDriftTable:getType(self.modelPos) == 5 then
			self.isCry = true

			self.modelEffect:play("cry", 0, 1)
		end
	end)

	local ids = xyd.tables.activityLafuliDriftTable:getIDs()
	self.items = {}

	for i = 1, #ids do
		local id = ids[i]
		local type = xyd.tables.activityLafuliDriftTable:getType(id)
		local go = NGUITools.AddChild(self.cellGroup, self["cell" .. type])

		go:SetLocalPosition(cellCenter[id].x, cellCenter[id].y, 0)
		table.insert(self.items, go)

		if type == 1 then
			local iconGroup = go:NodeByName("iconGroup").gameObject
			local iconName = xyd.tables.activityLafuliDriftTable:getIcon(ids[i])
			local icon = iconGroup:ComponentByName("icon", typeof(UISprite))
			local award = xyd.tables.activityLafuliDriftTable:getAward(ids[i], 1)
			local itemType = xyd.tables.itemTable:getType(award[1])

			if itemType == xyd.ItemType.HERO_DEBRIS or itemType == xyd.ItemType.HERO_RANDOM_DEBRIS then
				local heroIcon = xyd.getItemIcon({
					noClick = true,
					itemID = award[1],
					scale = Vector3(0.6, 0.6, 1),
					uiRoot = iconGroup
				})

				icon:SetActive(false)
			else
				xyd.setUISpriteAsync(icon, nil, iconName)
				icon:SetActive(true)
			end

			local bg = go:ComponentByName("bg", typeof(UISprite))

			if xyd.tables.activityLafuliDriftTable:getBgID(id) == 1 then
				xyd.setUISpriteAsync(bg, nil, "activity_lafuli_drift_bg_gz")
			elseif xyd.tables.activityLafuliDriftTable:getBgID(id) == 2 then
				xyd.setUISpriteAsync(bg, nil, "activity_lafuli_drift_bg_gz1")
			end
		elseif type == 2 then
			local iconGroup = go:ComponentByName("iconGroup", typeof(UISprite))

			xyd.setUISpriteAsync(iconGroup, nil, "activity_lafuli__sh" .. self.lvs[id])
		elseif type == 3 then
			local bg = go:ComponentByName("bg", typeof(UISprite))

			if xyd.tables.activityLafuliDriftTable:getBgID(id) and xyd.tables.activityLafuliDriftTable:getBgID(id) == 4 then
				local bg2 = go:ComponentByName("bg2", typeof(UISprite))

				xyd.setUISpriteAsync(bg2, nil, "lafuli_drift_bg" .. xyd.tables.activityLafuliDriftTable:getBgID(id), nil, , true)

				local label = go:ComponentByName("label2", typeof(UILabel))

				label:SetActive(true)

				label.text = xyd.tables.activityLafuliDriftTable:getFixedAward(id)[2]

				xyd.setUISpriteAsync(bg, nil, xyd.tables.activityLafuliDriftTable:getIcon(id), nil, , true)
				bg:Y(12)
			else
				xyd.setUISpriteAsync(bg, nil, xyd.tables.activityLafuliDriftTable:getIcon(id))
			end
		elseif type == 4 then
			local model = go:NodeByName("model").gameObject
			local levelUp = xyd.Spine.new(model)

			levelUp:setInfo("fx_drift_bubbles", function ()
				levelUp:play("texiao01", 0)
			end)
		elseif type == 5 then
			local model = go:NodeByName("model").gameObject
			local levelUp = xyd.Spine.new(model)

			levelUp:setInfo("fx_drift_whirlpool", function ()
				levelUp:play("texiao01", 0)
			end)
		end
	end

	for i = 1, #self.items do
		local label = self.items[i]:ComponentByName("lv", typeof(UILabel))

		if label then
			label.text = __("ACTIVITY_LAFULI_DRIFT_LV", self.lvs[ids[i]])
		end

		local label1 = self.items[i]:ComponentByName("label", typeof(UILabel))

		if label1 then
			label1.text = xyd.getRoughDisplayNumber2(xyd.tables.activityLafuliDriftTable:getAward(i, self.lvs[i])[2])
		end
	end

	for i = 1, 5 do
		self["cell" .. i]:SetActive(false)
	end

	if self.activityData.detail.select_buffs ~= nil and self.activityData.detail.select_buffs ~= 0 then
		xyd.WindowManager.get():openWindow("activity_drift_card_window", {
			parent = self
		})
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.LAFULI_DRIFT, function ()
		self.activityData.redMarkState = xyd.models.backpack:getItemNumByID(xyd.ItemID.LAFULI_SIMPLE_DICE) > 0
	end)

	if (self.modelPos == 0 or self.modelPos == 21) and xyd.models.backpack:getItemNumByID(xyd.ItemID.LAFULI_SIMPLE_DICE) > 0 and self.activityData.detail.point == 0 then
		self.guide:SetActive(true)

		if not self.guideEffect then
			self.guideEffect = xyd.Spine.new(self.guideModel)

			self.guideEffect:setInfo("fx_ui_dianji", function ()
				self.guideEffect:play("texiao01", 0)
			end)
		end

		self.isGuide = true
	end
end

function ActivityLafuliDrift:refresh()
	self.itemGroupLabel1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LAFULI_CONTROL_DICE)
	self.itemGroupLabel2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LAFULI_SIMPLE_DICE)

	if next(self.activityData.detail.items) then
		self.chestBtn:SetActive(true)
	else
		self.chestBtn:SetActive(false)
	end
end

function ActivityLafuliDrift:refreshx2()
	if self.isDouble or self.rudderDouble then
		self.rudderGroup:ComponentByName("rudderBtnLabel1", typeof(UILabel)):SetActive(true)
		self.rudderGroup:ComponentByName("rudderBtnLabel2", typeof(UILabel)):SetActive(true)
	else
		self.rudderGroup:ComponentByName("rudderBtnLabel1", typeof(UILabel)):SetActive(false)
		self.rudderGroup:ComponentByName("rudderBtnLabel2", typeof(UILabel)):SetActive(false)
	end
end

function ActivityLafuliDrift:refreshCoralx2()
	local ids = xyd.tables.activityLafuliDriftTable:getIDs()

	for i = 1, #self.items do
		local type = xyd.tables.activityLafuliDriftTable:getType(ids[i])

		if type == 2 then
			local label = self.items[i]:ComponentByName("label2", typeof(UILabel))

			if label then
				label:SetActive(self.isStar)
			end
		end
	end
end

function ActivityLafuliDrift:moveTo(index, sq, func, steps)
	self.touchField:SetActive(false)

	local sequence = nil

	if not sq then
		sequence = self:getSequence()
	else
		sequence = sq
	end

	sequence:AppendCallback(function ()
		self.numLabel.text = steps
	end)

	if self.modelPos == 20 then
		self.modelPos = 1

		sequence:AppendCallback(function ()
			self.model:SetLocalScale(-1, 1, 1)
			self.numGroup:SetLocalScale(-1, 1, 1)
		end)
		sequence:Append(self.model:DOLocalMove(Vector3(cellCenter[self.modelPos].x, cellCenter[self.modelPos].y - 13, 0), 0.33))
	else
		if self.modelPos == 1 then
			sequence:AppendCallback(function ()
				self.model:SetLocalScale(-1, 1, 1)
				self.numGroup:SetLocalScale(-1, 1, 1)
			end)
		elseif self.modelPos == 10 then
			sequence:AppendCallback(function ()
				self.model:SetLocalScale(1, 1, 1)
				self.numGroup:SetLocalScale(1, 1, 1)
			end)
		end

		self.modelPos = self.modelPos + 1

		sequence:Append(self.model:DOLocalMove(Vector3(cellCenter[self.modelPos].x, cellCenter[self.modelPos].y - 13, 0), 0.33))
	end

	if index == self.modelPos then
		sequence:AppendCallback(function ()
			if func then
				func()
			end

			self:moveResult()
		end)
	else
		self:moveTo(index, sequence, func, steps - 1)
	end
end

function ActivityLafuliDrift:moveRevert(index, sq, func, steps)
	self.touchField:SetActive(false)

	local sequence = nil

	if not sq then
		sequence = self:getSequence()
	else
		sequence = sq
	end

	sequence:AppendCallback(function ()
		self.numLabel.text = steps
	end)

	if self.modelPos == 1 then
		self.modelPos = 20

		sequence:Append(self.model:DOLocalMove(Vector3(cellCenter[self.modelPos].x, cellCenter[self.modelPos].y - 13, 0), 0.33))
	else
		self.modelPos = self.modelPos - 1

		sequence:Append(self.model:DOLocalMove(Vector3(cellCenter[self.modelPos].x, cellCenter[self.modelPos].y - 13, 0), 0.33))
	end

	if index == self.modelPos then
		sequence:AppendCallback(function ()
			if func then
				func()
			end

			self:moveResult()
		end)
	else
		self:moveRevert(index, sequence, func, steps - 1)
	end
end

function ActivityLafuliDrift:moveResult()
	local type = xyd.tables.activityLafuliDriftTable:getType(self.modelPos)

	if self.isCry then
		self.isCry = false

		self.modelEffect:play("idle", 0, 1)
	end

	if self.isRevert then
		self.isRevert = false
	elseif type == 1 or type == 2 then
		if self.lvs[self.modelPos] < 3 then
			local levelUp = xyd.Spine.new(self.model.gameObject)

			levelUp:setInfo("fx_drift_levelup", function ()
				levelUp:play("texiao01", 1, 1, function ()
					levelUp:destroy()
				end)
			end)
			xyd.SoundManager.get():playSound(xyd.SoundID.DRIFT_SMOKE)

			local label = self.items[self.modelPos]:ComponentByName("lv", typeof(UILabel))

			if label then
				label.text = __("ACTIVITY_LAFULI_DRIFT_LV", self.lvs[self.modelPos] + 1)
				self.lvs[self.modelPos] = self.lvs[self.modelPos] + 1
			end

			local award = xyd.tables.activityLafuliDriftTable:getAward(self.modelPos, self.lvs[self.modelPos])

			if award then
				local label1 = self.items[self.modelPos]:ComponentByName("label", typeof(UILabel))

				if label1 then
					label1.text = xyd.getRoughDisplayNumber2(award[2])
				end

				if award[1] == xyd.ItemID.CORAL_BRANCH then
					local iconGroup = self.items[self.modelPos]:ComponentByName("iconGroup", typeof(UISprite))

					xyd.setUISpriteAsync(iconGroup, nil, "activity_lafuli__sh" .. self.lvs[self.modelPos])
				end
			end
		end
	elseif type == 4 then
		if self.autoPlayTimes and self.autoPlayTimes > 0 then
			xyd.WindowManager.get():openWindow("activity_drift_card_window", {
				autoPlay = true,
				parent = self
			})
		else
			xyd.WindowManager.get():openWindow("activity_drift_card_window", {
				parent = self
			})
		end
	elseif type == 5 then
		self.isCry = true

		self.modelEffect:play("cry", 0, 1)
		xyd.alertTips(__("ACTIVITY_LAFULI_DRIFT_WATER"), nil, , , , , -10)
	end

	self:refreshx2()
	self:refresh()

	local nextID = xyd.tables.activityDriftAwardTable:getNextID(self.activityData.detail.point)
	local nextPoint = xyd.tables.activityDriftAwardTable:getPoint(nextID)
	local nextAwards = xyd.tables.activityDriftAwardTable:getAwards(nextID)
	local ids = xyd.tables.activityDriftAwardTable:getIDs()
	local number = math.floor(self.activityData.detail.point / 300) * 300
	self.itemProgress.value = self.activityData.detail.point % xyd.tables.activityDriftAwardTable:getPoint(ids[#ids]) / nextPoint
	self.itemProgressLabel.text = self.activityData.detail.point % xyd.tables.activityDriftAwardTable:getPoint(ids[#ids]) + number .. "/" .. nextPoint + number
	self.shopNum.text = "X" .. xyd.models.backpack:getItemNumByID(xyd.ItemID.DRIFT_SHOP_COIN)

	NGUITools.DestroyChildren(self.itemGroupItemIcon.transform)

	for i = 1, #nextAwards do
		local icon = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.6018518518518519,
			itemID = nextAwards[i][1],
			num = nextAwards[i][2],
			uiRoot = self.itemGroupItemIcon,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	if #nextAwards == 2 then
		self.itemGroupBg.width = 430

		self.itemProgress:X(-191)
	else
		self.itemGroupBg.width = 364

		self.itemProgress:X(-157)
	end

	self.itemGroupItemIcon:GetComponent(typeof(UILayout)):Reposition()

	self.onGoing = false

	self.touchField:SetActive(false)

	if self.autoPlayTimes and self.autoPlayTimes > 0 and type ~= 4 then
		self:autoPlay()
	elseif self.autoPlayTimes and self.autoPlayTimes == 0 then
		self.autoBg:SetActive(false)

		self.autoLabel.text = __("ACTIVITY_LAFULI_DRIFT_AUTO_WINDOW")
		self.autoLabel.color = Color.New2(1012112383)
		self.autoLabel.effectColor = Color.New2(4294967295.0)
	end
end

function ActivityLafuliDrift:registEvent()
	UIEventListener.Get(self.chestBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_drift_chest_window", {
			items = self.activityData.detail.items
		})
	end)
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_LAFULI_DRIFT_HELP"
		})
	end)
	UIEventListener.Get(self.shopBtn).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("activity_drift_shop_window")
	end)
	UIEventListener.Get(self.plusBtn).onClick = handler(self, function ()
		local maxNumBeen = self.activityData.detail.buy_times
		maxNumBeen = maxNumBeen or 0
		local maxNumCanBuy = xyd.tables.miscTable:getNumber("activity_lafuli_limit", "value") - maxNumBeen

		if maxNumCanBuy <= 0 then
			maxNumCanBuy = 0
		end

		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.LAFULI_SIMPLE_DICE,
			activityData = self.activityData,
			openItemBuyWnd = function ()
				xyd.WindowManager.get():openWindow("item_buy_window", {
					hide_min_max = false,
					item_no_click = false,
					cost = xyd.tables.miscTable:split2Cost("activity_lafuli_buy", "value", "|#")[1],
					max_num = xyd.checkCondition(maxNumCanBuy == 0, 1, maxNumCanBuy),
					itemParams = {
						num = 1,
						itemID = xyd.ItemID.LAFULI_SIMPLE_DICE
					},
					buyCallback = function (num)
						if maxNumCanBuy <= 0 then
							xyd.showToast(__("FULL_BUY_SLOT_TIME"))

							xyd.WindowManager.get():getWindow("item_buy_window").skipClose = true

							return
						end

						local msg = messages_pb:boss_buy_req()
						msg.activity_id = xyd.ActivityID.LAFULI_DRIFT
						msg.num = num

						xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
					end,
					limitText = __("BUY_GIFTBAG_LIMIT", tostring(self.activityData.detail.buy_times) .. "/" .. tostring(xyd.tables.miscTable:getNumber("activity_lafuli_limit", "value")))
				})
			end
		})
	end)
	UIEventListener.Get(self.skipBtn).onClick = handler(self, function ()
		self.skipAni = not self.skipAni

		self.skipCheck:SetActive(self.skipAni)
		xyd.db.misc:setValue({
			key = "lafuli_drift_skipani",
			value = self.skipAni and 1 or 0
		})
	end)
	UIEventListener.Get(self.touchField).onClick = handler(self, function ()
		self.touchField:SetActive(false)
		xyd.SoundManager.get():stopSound(xyd.SoundID.DRIFT_ROTATE)

		if next(self.sequences_) then
			for i = 1, #self.sequences_ do
				if not tolua.isnull(self.sequences_[i]) then
					self.sequences_[i]:Pause()
					self.sequences_[i]:Kill(false)
				end
			end

			self.sequences_ = {}
		end

		if not self.isDouble then
			local ishalf = (self.last_buffs and self.last_buffs[1] and self.last_buffs[1] == BUFFS_TYPE.HALF_MOVE or self.rudderDouble) and 2 or 1

			if self.last_buffs and self.last_buffs[1] and self.last_buffs[1] == BUFFS_TYPE.HALF_MOVE then
				ishalf = 2
			end

			if self.rudderDouble then
				ishalf = 0.5
			end

			self.rudderDouble = false
			self.rudderBtn2.transform.localEulerAngles = Vector3(0, 0, -780 + 60 * self.resSteps * ishalf)
		else
			self.isDouble = false

			math.randomseed(xyd.getServerTime())

			local steps1 = math.random(math.min(6, self.resSteps - 1))
			self.rudderBtn2.transform.localEulerAngles = Vector3(0, 0, -780 + 60 * steps1)
		end

		self:refreshx2()
		self:refresh()

		self.pointer.transform.localEulerAngles = Vector3(0, 0, 0)

		if self.skipAni then
			self.modelPos = self.resPos

			self.model:SetLocalPosition(cellCenter[self.resPos].x, cellCenter[self.resPos].y - 13, 0)

			if self.modelPos >= 0 and self.modelPos <= 10 then
				self.model:SetLocalScale(-1, 1, 1)
				self.numGroup:SetLocalScale(-1, 1, 1)
			else
				self.model:SetLocalScale(1, 1, 1)
				self.numGroup:SetLocalScale(1, 1, 1)
			end

			self:moveResult()
			xyd.models.itemFloatModel:pushNewItems(self.resAward)
		else
			self.numGroup:SetActive(true)

			if self.isRevert then
				self:moveRevert(self.resPos, nil, function ()
					self.numGroup:SetActive(false)
					xyd.models.itemFloatModel:pushNewItems(self.resAward)
				end, self.resSteps)
			else
				self:moveTo(self.resPos, nil, function ()
					self.numGroup:SetActive(false)
					xyd.models.itemFloatModel:pushNewItems(self.resAward)
				end, self.resSteps)
			end
		end
	end)
	UIEventListener.Get(self.rudderBtn2).onClick = handler(self, function ()
		if self.autoPlayTimes > 0 then
			xyd.showToast(__("ACTIVITY_LAFULI_DRIFT_AUTO_TIP2"))
		end

		if xyd.models.backpack:getItemNumByID(xyd.ItemID.LAFULI_SIMPLE_DICE) <= 0 then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.LAFULI_SIMPLE_DICE)))

			return
		end

		if self.isGuide then
			self.isGuide = nil

			self.guide:SetActive(false)
		end

		if not self.onGoing then
			self.onGoing = true
			local data = cjson.encode({
				type = 1
			})
			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.LAFULI_DRIFT
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		end
	end)
	UIEventListener.Get(self.rudderBtn1).onClick = handler(self, function ()
		if self.autoPlayTimes > 0 then
			xyd.showToast(__("ACTIVITY_LAFULI_DRIFT_AUTO_TIP2"))
		end

		if xyd.models.backpack:getItemNumByID(xyd.ItemID.LAFULI_CONTROL_DICE) <= 0 then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.LAFULI_CONTROL_DICE)))

			return
		end

		if not self.onGoing then
			self.leadedDice = true

			if self.isDouble then
				self.rudder:SetActive(false)
				self.rudder1:SetActive(true)
				self.rudder2:SetActive(true)
			else
				self.rudder:SetActive(true)
				self.rudder1:SetActive(false)
				self.rudder2:SetActive(false)
			end

			self.selectWnd:SetActive(true)
		end
	end)
	UIEventListener.Get(self.tipsWnd).onClick = handler(self, function ()
		self.tipsWnd:SetActive(false)
	end)

	for i = 1, #self.items do
		UIEventListener.Get(self.items[i]).onClick = handler(self, function ()
			local ids = xyd.tables.activityLafuliDriftTable:getIDs()
			local textID = xyd.tables.activityLafuliDriftTable:getTextID(ids[i])
			local type = xyd.tables.activityLafuliDriftTable:getType(ids[i])

			if type == 1 or type == 2 then
				self.tipsName.text = xyd.tables.activityLafuliDriftTextTable:getTitle(textID) .. " " .. __("ACTIVITY_LAFULI_DRIFT_LV", self.lvs[ids[i]])
			else
				self.tipsName.text = xyd.tables.activityLafuliDriftTextTable:getTitle(textID)
			end

			self.tipsLabel.text = xyd.tables.activityLafuliDriftTextTable:getDesc(textID)
			local iconName = xyd.tables.activityLafuliDriftTable:getIcon(ids[i])
			local award = xyd.tables.activityLafuliDriftTable:getAward(ids[i], 1)
			local itemType = xyd.tables.itemTable:getType(award[1])

			if itemType == xyd.ItemType.HERO_DEBRIS or itemType == xyd.ItemType.HERO_RANDOM_DEBRIS then
				NGUITools.DestroyChildren(self.tipsIcon.transform)

				local heroIcon = xyd.getItemIcon({
					noClick = true,
					itemID = award[1],
					scale = Vector3(1, 1, 1),
					uiRoot = self.tipsIcon.gameObject
				})
			elseif award[1] == xyd.ItemID.CORAL_BRANCH then
				NGUITools.DestroyChildren(self.tipsIcon.transform)
				xyd.setUISpriteAsync(self.tipsIcon, nil, "activity_lafuli__sh" .. self.lvs[ids[i]], nil, , true)
			else
				NGUITools.DestroyChildren(self.tipsIcon.transform)

				if iconName == "lafuli_drift_card" then
					xyd.setUISpriteAsync(self.tipsIcon, nil, iconName)

					self.tipsIcon.height = 100
					self.tipsIcon.width = 115
				elseif iconName == "lafuli_drift_slow" then
					xyd.setUISpriteAsync(self.tipsIcon, nil, iconName)

					self.tipsIcon.height = 110
					self.tipsIcon.width = 108
				else
					xyd.setUISpriteAsync(self.tipsIcon, nil, iconName, nil, , true)
				end
			end

			local height = math.max(196, self.tipsLabel.height + 84)
			self.tipsBg.height = height

			self.tipsWnd:SetActive(true)

			local dis = xyd.tables.activityLafuliDriftTable:getTipPos(ids[i])

			if dis[1] == 1 then
				self.tipsMain:Y(300 - (dis[2] + height / 2))
			else
				self.tipsMain:Y(300 - (dis[2] - height / 2))
			end
		end)
	end

	UIEventListener.Get(self.autoBtn).onClick = handler(self, function ()
		if self.autoPlayTimes and self.autoPlayTimes > 0 then
			self.autoPlayTimes = 0

			self.autoBg:SetActive(false)

			self.autoLabel.text = __("ACTIVITY_LAFULI_DRIFT_AUTO_WINDOW")
			self.autoLabel.color = Color.New2(1012112383)
			self.autoLabel.effectColor = Color.New2(4294967295.0)
		elseif xyd.models.backpack:getItemNumByID(xyd.ItemID.LAFULI_SIMPLE_DICE) > 0 then
			xyd.WindowManager.get():openWindow("activity_lafuli_drift_auto_window", {
				parent = self
			})
		else
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(xyd.ItemID.LAFULI_SIMPLE_DICE)))
		end
	end)

	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.LAFULI_DRIFT, function ()
			self.activityData.redMarkState = xyd.models.backpack:getItemNumByID(xyd.ItemID.LAFULI_SIMPLE_DICE) > 0
		end)
		self:refresh()

		self.shopNum.text = "X" .. xyd.models.backpack:getItemNumByID(xyd.ItemID.DRIFT_SHOP_COIN)
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		self.last_buffs = nil

		if self.buffs then
			self.last_buffs = {}

			for i in pairs(self.buffs) do
				table.insert(self.last_buffs, self.buffs[i])
			end
		end

		local detail = cjson.decode(event.data.detail)
		local pos = detail.info.pos
		self.buffs = detail.info.buffs
		local award = detail.items
		local steps = detail.steps
		self.resPos = pos
		self.resAward = award
		self.resSteps = steps
		self.activityData.detail.slot_lvs = detail.info.slot_lvs

		if next(award) ~= nil then
			for i = 1, #award do
				if award[i].item_id ~= xyd.ItemID.LAFULI_SIMPLE_DICE and award[i].item_id ~= xyd.ItemID.LAFULI_CONTROL_DICE then
					if self.activityData.detail.items[tostring(award[i].item_id)] ~= nil then
						self.activityData.detail.items[tostring(award[i].item_id)] = self.activityData.detail.items[tostring(award[i].item_id)] + award[i].item_num
					else
						self.activityData.detail.items[tostring(award[i].item_id)] = award[i].item_num
					end
				end
			end
		end

		if self.isStar and self.activityData.detail.point ~= detail.info.point then
			if self.leadedDice then
				self.modelEffect:play("idle", 0, 1)

				self.isStar = false

				self:refreshCoralx2()
			else
				self:waitForTime(0.33, function ()
					self.modelEffect:play("idle", 0, 1)

					self.isStar = false

					self:refreshCoralx2()
				end)
			end
		end

		local pointGot = detail.info.point - self.activityData.detail.point
		self.activityData.detail.point = detail.info.point

		if pointGot > 0 then
			table.insert(award, {
				item_id = xyd.ItemID.CORAL_BRANCH,
				item_num = pointGot
			})
		end

		if self.leadedDice then
			if self.skipAni then
				self.modelPos = pos

				self.model:SetLocalPosition(cellCenter[pos].x, cellCenter[pos].y - 13, 0)

				if self.modelPos >= 0 and self.modelPos <= 10 then
					self.model:SetLocalScale(-1, 1, 1)
					self.numGroup:SetLocalScale(-1, 1, 1)
				else
					self.model:SetLocalScale(1, 1, 1)
					self.numGroup:SetLocalScale(1, 1, 1)
				end

				self:moveResult()
				xyd.models.itemFloatModel:pushNewItems(award)
			else
				self.numGroup:SetActive(true)

				if self.isRevert then
					self:moveRevert(pos, nil, function ()
						self.numGroup:SetActive(false)
						xyd.models.itemFloatModel:pushNewItems(award)
					end, self.resSteps)
				else
					self:moveTo(pos, nil, function ()
						self.numGroup:SetActive(false)
						xyd.models.itemFloatModel:pushNewItems(award)
					end, self.resSteps)
				end
			end

			self.leadedDice = false
			self.isDouble = false
			self.rudderDouble = false

			self:refreshx2()
		else
			if self.autoPlayTimes and self.autoPlayTimes == 0 then
				self.touchField:SetActive(true)
			end

			if not self.isDouble then
				local ishalf = (self.last_buffs and self.last_buffs[1] and self.last_buffs[1] == BUFFS_TYPE.HALF_MOVE or self.rudderDouble) and 2 or 1

				if self.last_buffs and self.last_buffs[1] and self.last_buffs[1] == BUFFS_TYPE.HALF_MOVE then
					ishalf = 2
				end

				if self.rudderDouble then
					ishalf = 0.5
				end

				xyd.SoundManager.get():playSound(xyd.SoundID.DRIFT_ROTATE)

				local sequence = self:getSequence()

				sequence:Insert(0, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(0.1, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(0.2, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(0.3, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(0.4, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(0.5, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(0.6, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(0.7, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(0.8, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(0.9, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(1, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(1.1, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 0), 0.233))
				sequence:Insert(0, self.rudderBtn2.transform:DOLocalRotate(Vector3(0, 0, -780 + 60 * steps * ishalf), 1.333, DG.Tweening.RotateMode.FastBeyond360):SetEase(DG.Tweening.Ease.InOutSine))
				sequence:InsertCallback(1.333, function ()
					self.rudderDouble = false

					if self.skipAni then
						self.modelPos = pos

						self.model:SetLocalPosition(cellCenter[pos].x, cellCenter[pos].y - 13, 0)

						if self.modelPos >= 0 and self.modelPos <= 10 then
							self.model:SetLocalScale(-1, 1, 1)
							self.numGroup:SetLocalScale(-1, 1, 1)
						else
							self.model:SetLocalScale(1, 1, 1)
							self.numGroup:SetLocalScale(1, 1, 1)
						end

						self:moveResult()
						xyd.models.itemFloatModel:pushNewItems(award)
					else
						self.numGroup:SetActive(true)

						if self.isRevert then
							self:moveRevert(pos, nil, function ()
								self.numGroup:SetActive(false)
								xyd.models.itemFloatModel:pushNewItems(award)
							end, self.resSteps)
						else
							self:moveTo(pos, nil, function ()
								self.numGroup:SetActive(false)
								xyd.models.itemFloatModel:pushNewItems(award)
							end, self.resSteps)
						end
					end
				end)
			else
				self:refreshx2()

				local delay = 1.833

				math.randomseed(xyd.getServerTime())

				local steps1 = math.random(math.min(6, steps - 1))
				local steps2 = steps - steps1

				xyd.SoundManager.get():playSound(xyd.SoundID.DRIFT_ROTATE)

				local sequence = self:getSequence()

				sequence:Insert(0, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(0.1, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(0.2, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(0.3, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(0.4, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(0.5, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(0.6, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(0.7, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(0.8, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(0.9, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(1, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(1.1, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 0), 0.233))
				sequence:InsertCallback(delay, function ()
					xyd.SoundManager.get():playSound(xyd.SoundID.DRIFT_ROTATE)
				end)
				sequence:Insert(delay + 0, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(delay + 0.1, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(delay + 0.2, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(delay + 0.3, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(delay + 0.4, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(delay + 0.5, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(delay + 0.6, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(delay + 0.7, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(delay + 0.8, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(delay + 0.9, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 10), 0.1))
				sequence:Insert(delay + 1, self.pointer.transform:DOLocalRotate(Vector3(0, 0, -20), 0.1))
				sequence:Insert(delay + 1.1, self.pointer.transform:DOLocalRotate(Vector3(0, 0, 0), 0.233))
				sequence:Insert(0, self.rudderBtn2.transform:DOLocalRotate(Vector3(0, 0, -780 + 60 * steps1), 1.333, DG.Tweening.RotateMode.FastBeyond360):SetEase(DG.Tweening.Ease.InOutSine))
				sequence:Insert(delay, self.rudderBtn2.transform:DOLocalRotate(Vector3(0, 0, -780 + 60 * steps2), 1.333, DG.Tweening.RotateMode.FastBeyond360):SetEase(DG.Tweening.Ease.InOutSine))
				sequence:InsertCallback(2.966, function ()
					self.rudderDouble = false
					self.isDouble = false

					if self.skipAni then
						self.modelPos = pos

						self.model:SetLocalPosition(cellCenter[pos].x, cellCenter[pos].y - 13, 0)

						if self.modelPos >= 0 and self.modelPos <= 10 then
							self.model:SetLocalScale(-1, 1, 1)
							self.numGroup:SetLocalScale(-1, 1, 1)
						else
							self.model:SetLocalScale(1, 1, 1)
							self.numGroup:SetLocalScale(1, 1, 1)
						end

						self:moveResult()
						xyd.models.itemFloatModel:pushNewItems(award)
					else
						self.numGroup:SetActive(true)

						if self.isRevert then
							self:moveRevert(pos, nil, function ()
								self.numGroup:SetActive(false)
								xyd.models.itemFloatModel:pushNewItems(award)
							end, self.resSteps)
						else
							self:moveTo(pos, nil, function ()
								self.numGroup:SetActive(false)
								xyd.models.itemFloatModel:pushNewItems(award)
							end, self.resSteps)
						end
					end
				end)
			end
		end

		self:refreshx2()
		self:refresh()

		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FISHING)

		if activityData and xyd.getServerTime() < activityData:getEndTime() and activityData:isOpen() then
			local award = xyd.tables.miscTable:split2Cost("activity_lafuli_get", "value", "|#")[1]

			xyd.models.itemFloatModel:pushNewItems({
				{
					item_id = award[1],
					item_num = award[2]
				}
			})
		end

		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_DRAGONBOAT2022)

		if activityData and xyd.getServerTime() < activityData:getEndTime() and activityData:isOpen() then
			local award = xyd.tables.miscTable:split2Cost("activity_lafuli_get", "value", "|#")[1]

			xyd.models.itemFloatModel:pushNewItems({
				{
					item_id = award[1],
					item_num = award[2]
				}
			})
		end
	end)
	self:registerEvent(xyd.event.LAFULI_ACTIVITY_SELECT_BUFF, function (event)
		local detail = cjson.decode(event.data.detail)
		local buff = detail.buff_id

		table.insert(self.buffs, detail.buff_id)

		if buff == BUFFS_TYPE.DOUBLE_MOVE then
			self.rudderDouble = true

			self:refreshx2()
		elseif buff == BUFFS_TYPE.DOUBLE_DICE then
			self.isDouble = true

			self:refreshx2()
		elseif buff == BUFFS_TYPE.DOUBLE_SCORE then
			self.isStar = true

			self.modelEffect:play("star", 0, 1)
			self:refreshCoralx2()
		elseif buff == BUFFS_TYPE.BACK then
			self.isRevert = true
			self.isCry = true

			self.modelEffect:play("cry", 0, 1)
		elseif buff == BUFFS_TYPE.NO_ITEM then
			self.isCry = true

			self.modelEffect:play("cry", 0, 1)
		elseif buff == BUFFS_TYPE.TRANSFORM then
			self.modelPos = 0

			self.model:SetLocalPosition(cellCenter[21].x, cellCenter[21].y - 13, 0)
			self.model:SetLocalScale(-1, 1, 1)
			self.numGroup:SetLocalScale(1, 1, 1)
		end

		self.activityData.detail.select_buffs = nil
	end)
	self:registerEvent(xyd.event.BOSS_BUY, function (event)
		xyd.showToast(__("PURCHASE_SUCCESS"))

		self.activityData.detail.buy_times = event.data.buy_times

		if (self.modelPos == 0 or self.modelPos == 21) and xyd.models.backpack:getItemNumByID(xyd.ItemID.LAFULI_SIMPLE_DICE) > 0 and self.activityData.detail.point == 0 then
			self.guide:SetActive(true)

			if not self.guideEffect then
				self.guideEffect = xyd.Spine.new(self.guideModel)

				self.guideEffect:setInfo("fx_ui_dianji", function ()
					self.guideEffect:play("texiao01", 0)
				end)
			end

			self.isGuide = true
		end

		self:refresh()
	end)

	for i = 1, 6 do
		UIEventListener.Get(self["select_" .. i]).onClick = handler(self, function ()
			if self.select == 0 then
				self.select = i

				self["selected_" .. self.select]:SetActive(true)
				NGUITools.DestroyChildren(self["selected_" .. self.select].transform)

				local selecteffect = xyd.Spine.new(self["selected_" .. self.select].gameObject)

				selecteffect:setInfo("fx_drift_select", function ()
					selecteffect:play("animation", 0, 1)
				end)
				self.rudderMask:SetActive(true)

				self.rudderMask.transform.localEulerAngles = Vector3(0, 0, 60 - self.select * 60)

				return
			end

			if self.select == i then
				self["selected_" .. self.select]:SetActive(false)

				self.select = 0

				self.rudderMask:SetActive(false)
			else
				self["selected_" .. self.select]:SetActive(false)

				self.select = i

				self["selected_" .. self.select]:SetActive(true)
				NGUITools.DestroyChildren(self["selected_" .. self.select].transform)

				local selecteffect = xyd.Spine.new(self["selected_" .. self.select].gameObject)

				selecteffect:setInfo("fx_drift_select", function ()
					selecteffect:play("animation", 0, 1)
				end)

				self.rudderMask.transform.localEulerAngles = Vector3(0, 0, 60 - self.select * 60)
			end
		end)
		UIEventListener.Get(self["select1_" .. i]).onClick = handler(self, function ()
			if self.select1 == 0 then
				self.select1 = i

				self["selected1_" .. self.select1]:SetActive(true)
				NGUITools.DestroyChildren(self["selected1_" .. self.select1].transform)

				local selecteffect = xyd.Spine.new(self["selected1_" .. self.select1].gameObject)

				selecteffect:setInfo("fx_drift_select", function ()
					selecteffect:play("animation", 0, 1)
				end)
				self.rudderMask1:SetActive(true)

				self.rudderMask1.transform.localEulerAngles = Vector3(0, 0, 60 - self.select1 * 60)

				return
			end

			if self.select1 == i then
				self["selected1_" .. self.select1]:SetActive(false)

				self.select1 = 0

				self.rudderMask1:SetActive(false)
			else
				self["selected1_" .. self.select1]:SetActive(false)

				self.select1 = i

				self["selected1_" .. self.select1]:SetActive(true)
				NGUITools.DestroyChildren(self["selected1_" .. self.select1].transform)

				local selecteffect = xyd.Spine.new(self["selected1_" .. self.select1].gameObject)

				selecteffect:setInfo("fx_drift_select", function ()
					selecteffect:play("animation", 0, 1)
				end)

				self.rudderMask1.transform.localEulerAngles = Vector3(0, 0, 60 - self.select1 * 60)
			end
		end)
		UIEventListener.Get(self["select2_" .. i]).onClick = handler(self, function ()
			if self.select2 == 0 then
				self.select2 = i

				self["selected2_" .. self.select2]:SetActive(true)
				NGUITools.DestroyChildren(self["selected2_" .. self.select2].transform)

				local selecteffect = xyd.Spine.new(self["selected2_" .. self.select2].gameObject)

				selecteffect:setInfo("fx_drift_select", function ()
					selecteffect:play("animation", 0, 1)
				end)
				self.rudderMask2:SetActive(true)

				self.rudderMask2.transform.localEulerAngles = Vector3(0, 0, 60 - self.select2 * 60)

				return
			end

			if self.select2 == i then
				self["selected2_" .. self.select2]:SetActive(false)

				self.select2 = 0

				self.rudderMask2:SetActive(false)
			else
				self["selected2_" .. self.select2]:SetActive(false)

				self.select2 = i

				self["selected2_" .. self.select2]:SetActive(true)
				NGUITools.DestroyChildren(self["selected2_" .. self.select2].transform)

				local selecteffect = xyd.Spine.new(self["selected2_" .. self.select2].gameObject)

				selecteffect:setInfo("fx_drift_select", function ()
					selecteffect:play("animation", 0, 1)
				end)

				self.rudderMask2.transform.localEulerAngles = Vector3(0, 0, 60 - self.select2 * 60)
			end
		end)
	end

	UIEventListener.Get(self.selectBg).onClick = handler(self, function ()
		if self.select ~= 0 then
			self["selected_" .. self.select]:SetActive(false)

			self.select = 0

			self.rudderMask:SetActive(false)
		end

		if self.select1 ~= 0 then
			self["selected1_" .. self.select1]:SetActive(false)

			self.select1 = 0

			self.rudderMask1:SetActive(false)
		end

		if self.select2 ~= 0 then
			self["selected2_" .. self.select2]:SetActive(false)

			self.select2 = 0

			self.rudderMask2:SetActive(false)
		end

		self.leadedDice = false
		self.onGoing = false

		self.selectWnd:SetActive(false)
	end)
	UIEventListener.Get(self.selectBtn).onClick = handler(self, function ()
		local seletNum = self.isDouble and self.select1 + self.select2 or self.select

		if self.isDouble then
			if self.select1 > 0 then
				if self.select2 <= 0 then
					-- Nothing
				end
			end
		elseif self.isDouble or self.select > 0 then
			self.onGoing = true
			local data = cjson.encode({
				type = 2,
				steps = seletNum
			})
			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.LAFULI_DRIFT
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

			if self.select ~= 0 then
				self["selected_" .. self.select]:SetActive(false)

				self.select = 0

				self.rudderMask:SetActive(false)
			end

			if self.select1 ~= 0 then
				self["selected1_" .. self.select1]:SetActive(false)

				self.select1 = 0

				self.rudderMask1:SetActive(false)
			end

			if self.select2 ~= 0 then
				self["selected2_" .. self.select2]:SetActive(false)

				self.select2 = 0

				self.rudderMask2:SetActive(false)
			end

			self.selectWnd:SetActive(false)
		end
	end)
end

function ActivityLafuliDrift:levelUp(index)
	if not index or index == 0 then
		return
	end

	if self.lvs[index] >= 3 then
		return
	end

	self.cellModel:SetLocalPosition(cellCenter[index].x, cellCenter[index].y, 0)

	local levelUp = xyd.Spine.new(self.cellModel.gameObject)

	levelUp:setInfo("fx_drift_levelup", function ()
		levelUp:play("texiao01", 1, 1, function ()
			levelUp:destroy()
		end)
	end)
	xyd.SoundManager.get():playSound(xyd.SoundID.DRIFT_SMOKE)

	self.lvs[index] = self.lvs[index] + 1
	self.activityData.detail.slot_lvs[index] = self.activityData.detail.slot_lvs[index] + 1
	local award = xyd.tables.activityLafuliDriftTable:getAward(index, self.lvs[index])
	local label = self.items[index]:ComponentByName("lv", typeof(UILabel))

	if label then
		label.text = __("ACTIVITY_LAFULI_DRIFT_LV", self.lvs[index])
	end

	if award then
		local label1 = self.items[index]:ComponentByName("label", typeof(UILabel))

		if label1 then
			label1.text = xyd.getRoughDisplayNumber2(award[2])
		end

		if award[1] == xyd.ItemID.CORAL_BRANCH then
			local iconGroup = self.items[index]:ComponentByName("iconGroup", typeof(UISprite))

			xyd.setUISpriteAsync(iconGroup, nil, "activity_lafuli__sh" .. self.lvs[index])
		end
	end
end

function ActivityLafuliDrift:levelDown(index)
	if not index or index == 0 then
		return
	end

	if self.lvs[index] <= 1 then
		return
	end

	self.cellModel:SetLocalPosition(cellCenter[index].x, cellCenter[index].y, 0)

	local levelUp = xyd.Spine.new(self.cellModel.gameObject)

	levelUp:setInfo("fx_drift_leveldown", function ()
		levelUp:play("texiao01", 1, 1, function ()
			levelUp:destroy()
		end)
	end)
	xyd.SoundManager.get():playSound(xyd.SoundID.DRIFT_SMOKE)

	self.lvs[index] = self.lvs[index] - 1
	self.activityData.detail.slot_lvs[index] = self.activityData.detail.slot_lvs[index] - 1
	local award = xyd.tables.activityLafuliDriftTable:getAward(index, self.lvs[index])
	local label = self.items[index]:ComponentByName("lv", typeof(UILabel))

	if label then
		label.text = __("ACTIVITY_LAFULI_DRIFT_LV", self.lvs[index])
	end

	if award then
		local label1 = self.items[index]:ComponentByName("label", typeof(UILabel))

		if label1 then
			label1.text = xyd.getRoughDisplayNumber2(award[2])
		end

		if award[1] == xyd.ItemID.CORAL_BRANCH then
			local iconGroup = self.items[index]:ComponentByName("iconGroup", typeof(UISprite))

			xyd.setUISpriteAsync(iconGroup, nil, "activity_lafuli__sh" .. self.lvs[index])
		end
	end
end

function ActivityLafuliDrift:startAutoPlay(num)
	self.autoPlayTimes = num

	self.autoBg:SetActive(true)

	self.autoLabel.text = __("ACTIVITY_LAFULI_DRIFT_AUTO_END")
	self.autoLabel.color = Color.New2(4278124287.0)
	self.autoLabel.effectColor = Color.New2(2604482047.0)

	self:autoPlay()
end

function ActivityLafuliDrift:autoPlay()
	if not self.autoPlayTimes or self.autoPlayTimes <= 0 or self.onGoing then
		if self.autoPlayTimes <= 0 then
			self.autoBg:SetActive(false)

			self.autoLabel.text = __("ACTIVITY_LAFULI_DRIFT_AUTO_WINDOW")
			self.autoLabel.color = Color.New2(1012112383)
			self.autoLabel.effectColor = Color.New2(4294967295.0)
		end

		return
	end

	self.onGoing = true
	self.autoPlayTimes = self.autoPlayTimes - 1
	local data = cjson.encode({
		type = 1
	})
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.LAFULI_DRIFT
	msg.params = data

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityLafuliDrift:dispose()
	if self.modelPos == 0 then
		self.activityData.detail.pos = 21
	else
		self.activityData.detail.pos = self.modelPos
	end

	if self.buffs then
		self.activityData.detail.buffs = self.buffs
	end

	ActivityContent.super.dispose(self)
end

return ActivityLafuliDrift
