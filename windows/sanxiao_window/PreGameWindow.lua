local GameModeConstants = xyd.GameModeConstants
local CellConstants = xyd.CellConstants
local MainController = xyd.MainController
local DisplayConstants = xyd.DisplayConstants
local ItemConstants = xyd.ItemConstants
local LevelTable = xyd.tables.level
local GameConf = import("app.common.confs.GameConf")
local GameTargetView = import("app.components.GameTargetView")
local GameAssetsPreloader = xyd.GameAssetsPreloader
local PreGameWindow = class("PreGameWindow", import(".BaseWindow"))

function PreGameWindow:ctor(name, params)
	PreGameWindow.super.ctor(self, name, params)

	self.time_limited_img = {}
	self.expired_time_cache = {}
	self.timer_group = {}
	self.timer_label = {}
	self.img_add = {}
	self.item_image = {}
	self.cur_item_click_index = 0
	self._itemSelect1 = false
	self._itemSelect2 = false
	self._itemSelect3 = false
	self._itemSelect4 = false
	self._itemSelect = {}
	self._itemIDs = {}
	self._retry = false
	self._diff = 0
	self._useItems = {}
	self._notUse = false
	self.labelItemNum = {}
	self.labeTarget = {}
	self._usingTimelines = {}
	self._callingMethods = {}
	self.selfInfo_ = xyd.SelfInfo.get()
	self.params_ = params
	self._sceneID = params.scene_id
	local totalLevel = params.totalLevel or params.total_level
	self._totalLevel = totalLevel

	if params.retry then
		self._retry = params.retry
	end

	if params.items then
		self._useItems = params.items
	end

	if params.notUse then
		self._notUse = params.notUse
	end

	local chapter = -1
	local level = -1

	if totalLevel <= 10 then
		chapter = 1
		level = totalLevel
	elseif totalLevel <= 20 then
		chapter = 2
		level = totalLevel - 10
	else
		local tmp = totalLevel - 5
		chapter = math.floor(tmp / 15) + 2
		tmp = tmp % 15

		if tmp == 0 then
			chapter = chapter - 1
			level = 15
		else
			level = tmp
		end
	end

	self._chapter = chapter
	self._level = level
	local levelData = LevelTable:getTableData(self._totalLevel)

	if levelData then
		self._diff = levelData.difficulty
	end

	self._gameConf = GameConf.new()

	self._gameConf:init(totalLevel)
end

function PreGameWindow:initWindow()
	PreGameWindow.super.initWindow(self)
	self:getUIComponents()
	self:registerEvents()
	self:initDiff()
	self:initUIComponent()
	self:timerCallback()
	self:UIAnimation()
	self:initScroller()
	self:initTimer()

	local activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITY)

	if activityModel:isOpen(xyd.ActivityConstants.CLEAR_STREAK_REWARD) then
		self:initStreak()
	end
end

function PreGameWindow:registerEvents()
	xyd.EventDispatcher.outer():addEventListener("GAME_PRE_BEGIN", handler(self, self._onGamePreBegin))
	self.eventProxy_:addEventListener(xyd.event.BUY_ITEM_BY_ID, handler(self, self.onBuyItemByID))
end

function PreGameWindow:removeEventListeners()
	xyd.EventDispatcher.outer():removeEventListenersByEvent("GAME_PRE_BEGIN")
end

function PreGameWindow:getUIComponents()
	local winTrans = self.window_.transform
	self.start_btn = winTrans:NodeByName("e:Skin/group_bg/btn_group/start_btn").gameObject
	self.share_btn = winTrans:NodeByName("e:Skin/group_bg/btn_group/share_btn").gameObject
	self.close_btn = winTrans:NodeByName("e:Skin/group_bg/close_btn").gameObject
	self.group_item1 = winTrans:NodeByName("e:Skin/group_bg/group_item1").gameObject
	self.group_item2 = winTrans:NodeByName("e:Skin/group_bg/group_item2").gameObject
	self.group_item3 = winTrans:NodeByName("e:Skin/group_bg/group_item3").gameObject
	self.group_item4 = winTrans:NodeByName("e:Skin/group_bg/group_item4").gameObject
	self.item_img_1 = winTrans:ComponentByName("e:Skin/group_bg/group_item1/item_img_1", typeof(UISprite))
	self.item_img_2 = winTrans:ComponentByName("e:Skin/group_bg/group_item2/item_img_2", typeof(UISprite))
	self.item_img_3 = winTrans:ComponentByName("e:Skin/group_bg/group_item3/item_img_3", typeof(UISprite))
	self.item_img_4 = winTrans:ComponentByName("e:Skin/group_bg/group_item4/item_img_4", typeof(UISprite))
	self.num_label_1 = winTrans:ComponentByName("e:Skin/group_bg/group_item1/num_group_1/num_label_1", typeof(UILabel))
	self.num_label_2 = winTrans:ComponentByName("e:Skin/group_bg/group_item2/num_group_2/num_label_2", typeof(UILabel))
	self.num_label_3 = winTrans:ComponentByName("e:Skin/group_bg/group_item3/num_group_3/num_label_3", typeof(UILabel))
	self.num_label_4 = winTrans:ComponentByName("e:Skin/group_bg/group_item4/num_group_4/num_label_4", typeof(UILabel))
	self.num_label_timer_1 = winTrans:ComponentByName("e:Skin/group_bg/group_item1/num_group_1/num_label_timer_1", typeof(UILabel))
	self.num_label_timer_2 = winTrans:ComponentByName("e:Skin/group_bg/group_item2/num_group_2/num_label_timer_2", typeof(UILabel))
	self.num_label_timer_3 = winTrans:ComponentByName("e:Skin/group_bg/group_item3/num_group_3/num_label_timer_3", typeof(UILabel))
	self.num_label_timer_4 = winTrans:ComponentByName("e:Skin/group_bg/group_item4/num_group_4/num_label_timer_4", typeof(UILabel))
	self.img_add_1 = winTrans:ComponentByName("e:Skin/group_bg/group_item1/num_group_1/img_add_1", typeof(UISprite))
	self.img_add_2 = winTrans:ComponentByName("e:Skin/group_bg/group_item2/num_group_2/img_add_2", typeof(UISprite))
	self.img_add_3 = winTrans:ComponentByName("e:Skin/group_bg/group_item3/num_group_3/img_add_3", typeof(UISprite))
	self.img_add_4 = winTrans:ComponentByName("e:Skin/group_bg/group_item4/num_group_4/img_add_4", typeof(UISprite))
	self.select_1 = winTrans:NodeByName("e:Skin/group_bg/group_item1/select_1").gameObject
	self.select_2 = winTrans:NodeByName("e:Skin/group_bg/group_item2/select_2").gameObject
	self.select_3 = winTrans:NodeByName("e:Skin/group_bg/group_item3/select_3").gameObject
	self.select_4 = winTrans:NodeByName("e:Skin/group_bg/group_item4/select_4").gameObject
	self.taget_ = winTrans:ComponentByName("e:Skin/group_bg/group_score/taget_", typeof(UILabel))
	self.score_ = winTrans:ComponentByName("e:Skin/group_bg/group_score/score_", typeof(UILabel))
	self.timer1_group = winTrans:NodeByName("e:Skin/group_bg/group_item1/timer1_group").gameObject
	self.timer2_group = winTrans:NodeByName("e:Skin/group_bg/group_item2/timer2_group").gameObject
	self.timer3_group = winTrans:NodeByName("e:Skin/group_bg/group_item3/timer3_group").gameObject
	self.timer4_group = winTrans:NodeByName("e:Skin/group_bg/group_item4/timer4_group").gameObject
	self.timer1_label = winTrans:ComponentByName("e:Skin/group_bg/group_item1/timer1_group/timer1_label", typeof(UILabel))
	self.timer2_label = winTrans:ComponentByName("e:Skin/group_bg/group_item2/timer2_group/timer2_label", typeof(UILabel))
	self.timer3_label = winTrans:ComponentByName("e:Skin/group_bg/group_item3/timer3_group/timer3_label", typeof(UILabel))
	self.timer4_label = winTrans:ComponentByName("e:Skin/group_bg/group_item4/timer4_group/timer4_label", typeof(UILabel))
	self.time_limited_img1 = winTrans:ComponentByName("e:Skin/group_bg/group_item1/num_group_1/time_limited_img1", typeof(UISprite))
	self.time_limited_img2 = winTrans:ComponentByName("e:Skin/group_bg/group_item2/num_group_2/time_limited_img2", typeof(UISprite))
	self.time_limited_img3 = winTrans:ComponentByName("e:Skin/group_bg/group_item3/num_group_3/time_limited_img3", typeof(UISprite))
	self.time_limited_img4 = winTrans:ComponentByName("e:Skin/group_bg/group_item4/num_group_4/time_limited_img4", typeof(UISprite))
	self.group_bg = winTrans:NodeByName("e:Skin/group_bg").gameObject
	self._rankPanel = winTrans:NodeByName("e:Skin/group_bg/_rankPanel").gameObject
	self.group_target = winTrans:NodeByName("e:Skin/group_bg/group_target").gameObject
	self.stage_label_ = winTrans:NodeByName("e:Skin/group_bg/stage_group/stage_label_").gameObject
	self.icon_diff = winTrans:ComponentByName("e:Skin/group_bg/icon_diff", typeof(UISprite))
	self.bg_kuang = winTrans:ComponentByName("e:Skin/group_bg/bg_kuang", typeof(UISprite))
	self.bg_title = winTrans:ComponentByName("e:Skin/group_bg/stage_group/bg_title", typeof(UISprite))
	self.btn_bg_ = winTrans:ComponentByName("e:Skin/group_bg/btn_group/start_btn/btn_bg_", typeof(UISprite))
	self.share_btn_bg_ = winTrans:ComponentByName("e:Skin/group_bg/btn_group/share_btn/share_btn_bg_", typeof(UISprite))
	self.share_btn_text = winTrans:ComponentByName("e:Skin/group_bg/btn_group/share_btn/share_btn_text", typeof(UILabel))
	self.bg_rank = winTrans:ComponentByName("e:Skin/group_bg/_rankPanel/bg_rank", typeof(UISprite))
	self.rank_img = winTrans:ComponentByName("e:Skin/group_bg/_rankPanel/rank_img", typeof(UISprite))
	self.selectItemText_ = winTrans:ComponentByName("e:Skin/group_bg/selectItemText_", typeof(UILabel))
	self.stage_txt1_ = winTrans:ComponentByName("e:Skin/group_bg/stage_group/stage_txt1_", typeof(UILabel))
	self.stage_txt2_ = winTrans:ComponentByName("e:Skin/group_bg/stage_group/stage_txt2_", typeof(UILabel))
	self.start_btn_text = winTrans:ComponentByName("e:Skin/group_bg/btn_group/start_btn/start_btn_text", typeof(UILabel))
	self.streak_group = winTrans:NodeByName("e:Skin/group_bg/streak_group").gameObject
	self.icon_streak = self.streak_group.transform:ComponentByName("icon_streak", typeof(UISprite))
	self.num_streak = self.streak_group.transform:ComponentByName("num_streak", typeof(UILabel))
	self.text_streak = self.streak_group.transform:ComponentByName("text_streak", typeof(UILabel))
	self.hasTimerOnItem_1 = false
	self.hasTimerOnItem_2 = false
	self.hasTimerOnItem_3 = false
	self.hasTimerOnItem_4 = false
	self.timer_group = {
		self.timer1_group,
		self.timer2_group,
		self.timer3_group,
		self.timer4_group
	}
	self.timer_label = {
		self.timer1_label,
		self.timer2_label,
		self.timer3_label,
		self.timer4_label
	}
	self.time_limited_img = {
		self.time_limited_img1,
		self.time_limited_img2,
		self.time_limited_img3,
		self.time_limited_img4
	}
	self._itemSelect = {
		self._itemSelect1,
		self._itemSelect2,
		self._itemSelect3,
		self._itemSelect4
	}
	self.img_add = {
		self.img_add_1,
		self.img_add_2,
		self.img_add_3,
		self.img_add_4
	}
	self.item_image = {
		self.item_img_1,
		self.item_img_2,
		self.item_img_3,
		self.item_img_4
	}
	self.labelItemNum = {
		self.num_label_1,
		self.num_label_2,
		self.num_label_3,
		self.num_label_4
	}
	self.labelItemNumTimer = {
		self.num_label_timer_1,
		self.num_label_timer_2,
		self.num_label_timer_3,
		self.num_label_timer_4
	}
	self.hasTimerOnItem = {
		self.hasTimerOnItem_1,
		self.hasTimerOnItem_2,
		self.hasTimerOnItem_3,
		self.hasTimerOnItem_4
	}
end

function PreGameWindow:initStreak()
	local streakNum = xyd.SelfInfo.get():getClearStreak()

	if streakNum == 0 then
		return
	end

	local picName = "icon_liansheng"

	xyd.setUISpriteAsync(self.icon_streak, xyd.MappingData[picName], picName, function ()
		self.num_streak.text = tostring(streakNum)

		self.streak_group:SetActive(true)
		xyd.setNormalBtnBehavior(self.streak_group, self, function ()
			xyd.WindowManager.get():openWindow("clear_streak_window")
		end)
	end)
end

function PreGameWindow:initTimer()
	self.timer = Timer.New(handler(self, self.timerCallback), 1, -1, false)

	self.timer:Start()
end

function PreGameWindow:initScroller()
	self._rankPanel:SetActive(false)

	if self.params_.lottery_text then
		self._retainPanel:SetActive(true)

		return
	end
end

function PreGameWindow:initDiff()
	if self._diff == 0 then
		self.icon_diff:SetActive(false)
	elseif self._diff == 1 then
		xyd.setUISprite(self.icon_diff, xyd.MappingData.icon_difficulty_1, "icon_difficulty_1")
		xyd.setUISprite(self.bg_kuang, xyd.MappingData.bg_kaishi2, "bg_kaishi2")
		xyd.setUISprite(self.bg_title, xyd.MappingData.bg_titledi2, "bg_titledi2")
		xyd.setUISprite(self.close_btn:GetComponent(typeof(UISprite)), xyd.MappingData.icon_guanbi_2, "icon_guanbi_2")
		xyd.setUISprite(self.btn_bg_, xyd.MappingData.bg_anniudi2, "bg_anniudi2")
		xyd.setUISprite(self.share_btn_bg_, xyd.MappingData.bg_anniudi2, "bg_anniudi2")

		self.selectItemText_.effectColor = Color.New2(3123123967.0)
		self.stage_txt1_.effectColor = Color.New2(3123123967.0)
		self.stage_txt2_.effectColor = Color.New2(3123123967.0)
	elseif self._diff == 2 then
		xyd.setUISprite(self.icon_diff, xyd.MappingData.icon_difficulty_2, "icon_difficulty_2")
		xyd.setUISprite(self.bg_kuang, xyd.MappingData.bg_kaishi2, "bg_kaishi2")
		xyd.setUISprite(self.bg_title, xyd.MappingData.bg_titledi2, "bg_titledi2")
		xyd.setUISprite(self.close_btn:GetComponent(typeof(UISprite)), xyd.MappingData.icon_guanbi_2, "icon_guanbi_2")
		xyd.setUISprite(self.btn_bg_, xyd.MappingData.bg_anniudi2, "bg_anniudi2")
		xyd.setUISprite(self.share_btn_bg_, xyd.MappingData.bg_anniudi2, "bg_anniudi2")

		self.selectItemText_.effectColor = Color.New2(3123123967.0)
		self.stage_txt1_.effectColor = Color.New2(3123123967.0)
		self.stage_txt2_.effectColor = Color.New2(3123123967.0)
	elseif self._diff == 3 then
		xyd.setUISprite(self.icon_diff, xyd.MappingData.icon_difficulty_3, "icon_difficulty_3")
		xyd.setUISprite(self.bg_kuang, xyd.MappingData.bg_kaishi3, "bg_kaishi3")
		xyd.setUISprite(self.bg_title, xyd.MappingData.bg_titledi3, "bg_titledi3")
		xyd.setUISprite(self.close_btn:GetComponent(typeof(UISprite)), xyd.MappingData.icon_guanbi_3, "icon_guanbi_3")
		xyd.setUISprite(self.btn_bg_, xyd.MappingData.bg_anniudi3, "bg_anniudi3")
		xyd.setUISprite(self.share_btn_bg_, xyd.MappingData.bg_anniudi3, "bg_anniudi3")

		self.selectItemText_.effectColor = Color.New2(2553208063.0)
		self.stage_txt1_.effectColor = Color.New2(2553208063.0)
		self.stage_txt2_.effectColor = Color.New2(2553208063.0)
	end
end

function PreGameWindow:btnSingleAnimation(group, startFrame)
	local tw = DG.Tweening.DOTween.Sequence()
	group.transform.localScale = Vector3(0, 0)

	table.insert(self._usingTimelines, tw)
	tw:Insert(4 * xyd.TweenDeltaTime, group.transform:DOScale(Vector3(1.2, 1.2), 4 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	tw:Insert(8 * xyd.TweenDeltaTime, group.transform:DOScale(Vector3(0.9, 0.9), 5 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	tw:Insert(14 * xyd.TweenDeltaTime, group.transform:DOScale(Vector3(1, 1), 5 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
end

function PreGameWindow:UIAnimation()
	self:btnSingleAnimation(self.group_item1, 4)
	self:btnSingleAnimation(self.group_item2, 4)
	self:btnSingleAnimation(self.group_item3, 4)
	self:btnSingleAnimation(self.group_item4, 4)
end

function PreGameWindow:initUIComponent()
	if xyd.MapController.get().isInNewUserGuide then
		self.close_btn:SetActive(false)
	end

	xyd.setDarkenBtnBehavior(self.start_btn, self, self.startBtnClick)
	xyd.setDarkenBtnBehavior(self.share_btn, self, self.shareBtnClick)
	xyd.setDarkenBtnBehavior(self.close_btn, self, self.closeBtnClick)

	self.stage_label_:GetComponent(typeof(UILabel)).text = self._totalLevel

	if self._retry then
		self.start_btn_text.text = __("RESTART")
	else
		self.start_btn_text.text = __("START")
	end

	self.selectItemText_.text = __("PREGAME_SELECTITEM")
	self.taget_.text = __("TEXT_TARGET")
	self.text_streak.text = __("CLEAR_STREAK")
	self.stage_txt1_.text = __("DI")
	self.stage_txt2_.text = __("LEVEL")
	self.share_btn_text.text = __("PREGAME_REWARD")
	local selfInfo = xyd.SelfInfo.get()
	self.selfInfo_ = selfInfo
	self._itemIDs = self._gameConf.pregameItemList
	local zero_num = 4 - #self._itemIDs

	for index = 1, zero_num do
		table.insert(self._itemIDs, 0)
	end

	local itemID1 = tostring(self._itemIDs[1])
	local itemTimeID1 = tostring(self._itemIDs[1] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemID2 = tostring(self._itemIDs[2])
	local itemTimeID2 = tostring(self._itemIDs[2] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemID3 = tostring(self._itemIDs[3])
	local itemTimeID3 = self._itemIDs[3] + ItemConstants.LIMITED_TIME_OFFSET
	local itemID4 = tostring(self._itemIDs[4])
	local itemTimeID4 = tostring(self._itemIDs[4] + ItemConstants.LIMITED_TIME_OFFSET)
	local item1Count = selfInfo:getItemNumByID(itemID1)
	local itemTime1Count = selfInfo:getItemNumByID(itemTimeID1)
	local item2Count = selfInfo:getItemNumByID(itemID2)
	local itemTime2Count = selfInfo:getItemNumByID(itemTimeID2)
	local item3Count = selfInfo:getItemNumByID(itemID3)
	local itemTime3Count = selfInfo:getItemNumByID(itemTimeID3)
	local item4Count = selfInfo:getItemNumByID(itemID4)
	local itemTime4Count = selfInfo:getItemNumByID(itemTimeID4)
	local useItem1 = false
	local useItem2 = false
	local useItem3 = false
	local useItem4 = false

	if self._useItems and #self._useItems > 0 then
		local i = 1

		while i <= #self._useItems do
			if self._useItems[i - 1 + 1] == self._itemIDs[1] then
				useItem1 = true
			elseif self._useItems[i - 1 + 1] == self._itemIDs[2] then
				useItem2 = true
			elseif self._useItems[i - 1 + 1] == self._itemIDs[3] then
				useItem3 = true
			elseif self._useItems[i - 1 + 1] == self._itemIDs[4] then
				useItem4 = true
			end

			i = i + 1
		end
	end

	if itemTime1Count > 0 then
		self.timer1_group:SetActive(true)
		xyd.setUISprite(self.time_limited_img1, xyd.MappingData.icon_xianshi, "icon_xianshi")

		self.hasTimerOnItem[1] = true
	end

	if itemTime2Count > 0 then
		self.timer2_group:SetActive(true)
		xyd.setUISprite(self.time_limited_img2, xyd.MappingData.icon_xianshi, "icon_xianshi")

		self.hasTimerOnItem[2] = true
	end

	if itemTime3Count > 0 then
		self.timer3_group:SetActive(true)
		xyd.setUISprite(self.time_limited_img3, xyd.MappingData.icon_xianshi, "icon_xianshi")

		self.hasTimerOnItem[3] = true
	end

	if itemTime4Count > 0 then
		self.timer4_group:SetActive(true)
		xyd.setUISprite(self.time_limited_img4, xyd.MappingData.icon_xianshi, "icon_xianshi")

		self.hasTimerOnItem[4] = true
	end

	for i = 1, 4 do
		local picName = DisplayConstants.ItemSourceMap[self._itemIDs[i]]

		xyd.setUISprite(self.item_image[i], xyd.MappingData[picName], picName)
	end

	if item1Count + itemTime1Count >= 0 then
		local num = item1Count + itemTime1Count

		xyd.setDarkenBtnBehavior(self.group_item1, self, self.itemClick1)
		self:updateItemCountByIndex(1, num)
	end

	if itemTime1Count > 0 or useItem1 or item1Count > 0 and self.selfInfo_.lastGameChooseItems[1] and self.selfInfo_.lastGameLevel == self._totalLevel and not self._notUse then
		self:itemClick1()
	end

	if item2Count + itemTime2Count >= 0 then
		local num = item2Count + itemTime2Count

		xyd.setDarkenBtnBehavior(self.group_item2, self, self.itemClick2)
		self:updateItemCountByIndex(2, num)
	end

	if itemTime2Count > 0 or useItem2 or item2Count > 0 and self.selfInfo_.lastGameChooseItems[2] and self.selfInfo_.lastGameLevel == self._totalLevel and not self._notUse then
		self:itemClick2()
	end

	if item3Count + itemTime3Count >= 0 then
		self.group_item3:SetActive(true)

		local num = item3Count + itemTime3Count

		xyd.setDarkenBtnBehavior(self.group_item3, self, self.itemClick3)
		self:updateItemCountByIndex(3, num)
	end

	if itemTime3Count > 0 or useItem3 or item3Count > 0 and self.selfInfo_.lastGameChooseItems[3] and self.selfInfo_.lastGameLevel == self._totalLevel and not self._notUse then
		self:itemClick3()
	end

	if item4Count + itemTime4Count >= 0 then
		self.group_item4:SetActive(true)

		local num = item4Count + itemTime4Count

		xyd.setDarkenBtnBehavior(self.group_item4, self, self.itemClick4)
		self:updateItemCountByIndex(4, num)
	end

	if itemTime4Count > 0 or useItem4 or item4Count > 0 and self.selfInfo_.lastGameChooseItems[4] and self.selfInfo_.lastGameLevel == self._totalLevel and not self._notUse then
		self:itemClick4()
	end

	local stageInfo = selfInfo:getStageInfo(self._totalLevel)
	local star = 0
	local score = 0

	if stageInfo ~= nil then
		star = stageInfo.stars
		score = stageInfo.score
	end

	local scoreTargets = self._gameConf:getScoreTargets()

	if star == 0 then
		score = scoreTargets[1]
	elseif star == 1 then
		score = scoreTargets[2]
	elseif star == 2 then
		score = scoreTargets[3]
	elseif star == 3 then
		-- Nothing
	end

	self.taget_:SetActive(false)

	local gameType = self._gameConf.modeName

	if gameType == GameModeConstants.CLASSIC_MOVES then
		self.taget_:SetActive(true)

		self.score_.text = tostring(score)
	elseif gameType == GameModeConstants.OBJECTIVE then
		local obj = self._gameConf:getObjectives()
		local i = 0

		while i < #obj do
			self:_updateTarget(tostring(obj[i + 1].item), obj[i + 1].quantity)

			i = i + 1
		end
	elseif gameType == GameModeConstants.LEAF_OBJECTIVE then
		local leafNum = 0
		local cellMap = self._gameConf:getCellMap()

		for row = 1, 9 do
			for col = 1, 9 do
				local cell = cellMap[row][col]

				if cell:hasProperty(CellConstants.LEAF_1) then
					leafNum = leafNum + 1
				elseif cell:hasProperty(CellConstants.LEAF_2) then
					leafNum = leafNum + 1
				end
			end
		end

		self:_updateTarget("leaf", leafNum)

		local obj = self._gameConf:getObjectives()
		local i = 0

		while i < #obj do
			self:_updateTarget(tostring(obj[i + 1].item), obj[i + 1].quantity)

			i = i + 1
		end
	elseif gameType == GameModeConstants.LAMP then
		local lamps = self._gameConf:getLamps()
		local lamp1 = 0
		local lamp2 = 0

		if #lamps >= 1 then
			lamp1 = lamps[1]
		end

		if #lamps >= 2 then
			lamp2 = lamps[2]
		end

		self:_updateTarget("lamp1", lamp1)
		self:_updateTarget("lamp2", lamp2)
	elseif gameType == GameModeConstants.LEAF then
		local leafNum = 0
		local cellMap = self._gameConf:getCellMap()

		for row = 1, 9 do
			for col = 1, 9 do
				local cell = cellMap[row][col]

				if cell:hasProperty(CellConstants.LEAF_1) then
					leafNum = leafNum + 1
				elseif cell:hasProperty(CellConstants.LEAF_2) then
					leafNum = leafNum + 1
				end
			end
		end

		self:_updateTarget("leaf", leafNum)
	end

	if self.params_.bonus_items then
		for ID in __TS__Iterator(self.params_.bonus_items) do
			self:selectItem(ID)
		end
	end

	self._scoreTarget = score

	self.group_target:GetComponent(typeof(UIGrid)):Reposition()
end

function PreGameWindow:updateItemCountByIndex(index, count)
	local numLabel = self.labelItemNum[index]

	if numLabel == nil then
		return
	end

	if count <= 0 then
		self.img_add[index]:SetActive(true)

		if self.hasTimerOnItem[index] then
			xyd.setUISprite(self.time_limited_img[index], xyd.MappingData.icon_shuliang, "icon_shuliang")

			self.hasTimerOnItem[index] = false
		end

		self.labelItemNum[index]:SetActive(false)

		return
	end

	self.img_add[index]:SetActive(false)

	if self.hasTimerOnItem[index] then
		self.labelItemNumTimer[index]:SetActive(true)
		self.labelItemNum[index]:SetActive(false)

		self.labelItemNumTimer[index].text = tostring(count)
	else
		self.labelItemNumTimer[index]:SetActive(false)
		self.labelItemNum[index]:SetActive(true)

		self.labelItemNum[index].text = tostring(count)
	end
end

function PreGameWindow:_updateTarget(key, val)
	if val == -1 then
		return
	end

	GameTargetView.new(key, val, self.group_target)
end

function PreGameWindow:PreStartGame()
	xyd.SelfInfo.get().addMovesTime = 0

	if self._callingMethods.GAME_PRE_BEGIN then
		return
	end

	self._callingMethods.GAME_PRE_BEGIN = true
	local itemID1 = tostring(self._itemIDs[1])
	local itemTimeID1 = tostring(self._itemIDs[1] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemID2 = tostring(self._itemIDs[2])
	local itemTimeID2 = tostring(self._itemIDs[2] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemID3 = tostring(self._itemIDs[3])
	local itemTimeID3 = tostring(self._itemIDs[3] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemID4 = tostring(self._itemIDs[4])
	local itemTimeID4 = tostring(self._itemIDs[4] + ItemConstants.LIMITED_TIME_OFFSET)
	local selfInfo = xyd.SelfInfo:get()
	local itemTime1Count = selfInfo:getItemNumByID(itemTimeID1)
	local itemTime2Count = selfInfo:getItemNumByID(itemTimeID2)
	local itemTime3Count = selfInfo:getItemNumByID(itemTimeID3)
	local itemTime4Count = selfInfo:getItemNumByID(itemTimeID4)

	if self._itemSelect1 and itemTime1Count <= 0 then
		xyd.SelfInfo.get().lastGameLevel = self._totalLevel
		xyd.SelfInfo.get().lastGameChooseItems[1] = true
	else
		xyd.SelfInfo.get().lastGameChooseItems[1] = false
	end

	if self._itemSelect2 and itemTime2Count <= 0 then
		xyd.SelfInfo.get().lastGameLevel = self._totalLevel
		xyd.SelfInfo.get().lastGameChooseItems[2] = true
	else
		xyd.SelfInfo.get().lastGameChooseItems[2] = false
	end

	if self._itemSelect3 and itemTime3Count <= 0 then
		xyd.SelfInfo.get().lastGameLevel = self._totalLevel
		xyd.SelfInfo.get().lastGameChooseItems[3] = true
	else
		xyd.SelfInfo.get().lastGameChooseItems[3] = false
	end

	if self._itemSelect4 and itemTime4Count <= 0 then
		xyd.SelfInfo.get().lastGameLevel = self._totalLevel
		xyd.SelfInfo.get().lastGameChooseItems[4] = true
	else
		xyd.SelfInfo.get().lastGameChooseItems[4] = false
	end

	xyd.DataPlatform.get():request("GAME_PRE_BEGIN", {
		confirmed = true,
		show = false,
		chapter = self._chapter,
		level = self._level,
		total_level = self._totalLevel
	})
end

function PreGameWindow:_onGamePreBegin(event)
	local data = event.data

	if data.success then
		self:_disableBtns()

		local loadingWindow = nil

		if xyd.WindowManager.get():getWindow("loading_component") == nil then
			loadingWindow = xyd.WindowManager.get():openWindow("loading_component", data)
		else
			loadingWindow = xyd.WindowManager.get():getWindow("loading_component")
		end

		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.LOADING_DOWN_START,
			params = {
				onComplete = function ()
					if xyd.WindowManager.get():getWindow("map_window") ~= nil then
						xyd.SpineManager.get():cleanUp()
					end

					xyd.MapController.get():closeMap()

					local mapWin = xyd.WindowManager.get():getWindow("map_window")

					if mapWin then
						xyd.WindowManager.get():closeWindow("map_window")
					end

					xyd.MapController.get():closeMap(nil)

					local function callback()
						self:close()

						local game = MainController:get():initGameFromConf(self._gameConf)

						game:setScoreTarget(self._scoreTarget)

						local activeItemList = {}

						if self._itemSelect1 then
							table.insert(activeItemList, self._itemIDs[1])
						end

						if self._itemSelect2 then
							table.insert(activeItemList, self._itemIDs[2])
						end

						if self._itemSelect3 then
							table.insert(activeItemList, self._itemIDs[3])
						end

						if self._itemSelect4 then
							table.insert(activeItemList, self._itemIDs[4])
						end

						if #activeItemList > 0 then
							game:setActiveItemList(activeItemList)
						end

						xyd.EventDispatcher.inner():dispatchEvent({
							name = xyd.event.LOADING_UP_START
						})
						XYDCo.WaitForTime(0.5, function ()
							xyd.EventDispatcher.inner():dispatchEvent({
								name = xyd.event.GAME_START
							})
						end, "")
					end

					local GAPreloader = GameAssetsPreloader.get()

					GAPreloader:init()
					GAPreloader:run(self._gameConf, callback)
				end
			}
		})
	end

	self._callingMethods.GAME_PRE_BEGIN = false
end

function PreGameWindow:onBuyItemByID(event)
	local data = event.data

	if data.success and self.cur_item_click_index > 0 then
		local itemID = tostring(self._itemIDs[self.cur_item_click_index])
		local itemTimeID = tostring(self._itemIDs[self.cur_item_click_index] + ItemConstants.LIMITED_TIME_OFFSET)
		local itemCount = self.selfInfo_:getItemNumByID(itemID)
		local itemTimeCount = self.selfInfo_:getItemNumByID(itemTimeID)

		self:updateItemCountByIndex(self.cur_item_click_index, itemCount + itemTimeCount)

		self["_itemSelect" .. tostring(self.cur_item_click_index)] = true

		self["select_" .. tostring(self.cur_item_click_index)]:SetActive(true)
		self["timer" .. tostring(self.cur_item_click_index) .. "_group"]:SetActive(false)
	end
end

function PreGameWindow:startBtnClick()
	self:PreStartGame()
end

function PreGameWindow:shareBtnClick()
end

function PreGameWindow:updateItems()
	local selfInfo = xyd.SelfInfo:get()
	local itemID1 = tostring(self._itemIDs[1])
	local itemTimeID1 = tostring(self._itemIDs[1] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemID2 = tostring(self._itemIDs[2])
	local itemTimeID2 = tostring(self._itemIDs[2] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemID3 = tostring(self._itemIDs[3])
	local itemTimeID3 = tostring(self._itemIDs[3] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemID4 = tostring(self._itemIDs[4])
	local itemTimeID4 = tostring(self._itemIDs[4] + ItemConstants.LIMITED_TIME_OFFSET)
	local item1Count = selfInfo:getItemNumByID(itemID1)
	local itemTime1Count = selfInfo:getItemNumByID(itemTimeID1)
	local item2Count = selfInfo:getItemNumByID(itemID2)
	local itemTime2Count = selfInfo:getItemNumByID(itemTimeID2)
	local item3Count = selfInfo:getItemNumByID(itemID3)
	local itemTime3Count = selfInfo:getItemNumByID(itemTimeID3)
	local item4Count = selfInfo:getItemNumByID(itemID4)
	local itemTime4Count = selfInfo:getItemNumByID(itemTimeID4)

	self.timer1_group:SetActive(false)
	self.timer2_group:SetActive(false)
	self.timer3_group:SetActive(false)
	self.timer4_group:SetActive(false)

	if itemTime1Count > 0 and not self.hasTimerOnItem[1] then
		self.timer1_group:SetActive(true)
		xyd.setUISprite(self.time_limited_img1, xyd.MappingData.icon_xianshi, "icon_xianshi")

		self.hasTimerOnItem[1] = true
	end

	if itemTime2Count > 0 and not self.hasTimerOnItem[2] then
		self.timer2_group:SetActive(true)
		xyd.setUISprite(self.time_limited_img2, xyd.MappingData.icon_xianshi, "icon_xianshi")

		self.hasTimerOnItem[2] = true
	end

	if itemTime3Count > 0 and not self.hasTimerOnItem[3] then
		self.timer3_group:SetActive(true)
		xyd.setUISprite(self.time_limited_img3, xyd.MappingData.icon_xianshi, "icon_xianshi")

		self.hasTimerOnItem[3] = true
	end

	if itemTime4Count > 0 and not self.hasTimerOnItem[4] then
		self.timer4_group:SetActive(true)
		xyd.setUISprite(self.time_limited_img4, xyd.MappingData.icon_xianshi, "icon_xianshi")

		self.hasTimerOnItem[4] = true
	end

	if item1Count + itemTime1Count >= 0 then
		local num = item1Count + itemTime1Count

		if not self.labelItemNum1 then
			xyd.setDarkenBtnBehavior(self.group_item1, self, self.itemClick1)
			table.insert(self.labelItemNum, self.labelItemNum1)
		end

		self:updateItemCountByIndex(1, num)
	end

	if itemTime1Count > 0 then
		self._itemSelect1 = false

		self:itemClick1()
	end

	if item2Count + itemTime2Count >= 0 then
		local num = item2Count + itemTime2Count

		if not self.labelItemNum2 then
			xyd.setDarkenBtnBehavior(self.group_item2, self, self.itemClick2)
			table.insert(self.labelItemNum, self.labelItemNum2)
		end

		self:updateItemCountByIndex(2, num)
	end

	if itemTime2Count > 0 then
		self._itemSelect2 = false

		self:itemClick2()
	end

	if item3Count + itemTime3Count >= 0 then
		self.group_item3:SetActive(true)

		local num = item3Count + itemTime3Count

		if not self.labelItemNum3 then
			xyd.setDarkenBtnBehavior(self.group_item3, self, self.itemClick3)
			table.insert(self.labelItemNum, self.labelItemNum3)
		end

		self:updateItemCountByIndex(3, num)
	end

	if itemTime3Count > 0 then
		self._itemSelect3 = false

		self:itemClick3()
	end

	if item4Count + itemTime3Count >= 0 then
		self.group_item4:SetActive(true)

		local num = item4Count + itemTime4Count

		if not self.labelItemNum4 then
			xyd.setDarkenBtnBehavior(self.group_item4, self, self.itemClick4)
			table.insert(self.labelItemNum, self.labelItemNum4)
		end

		self:updateItemCountByIndex(4, num)
	end

	if itemTime4Count > 0 then
		self._itemSelect4 = false

		self:itemClick4()
	end
end

function PreGameWindow:closeBtnClick()
	self:_disableBtns()
	self:close()

	if not xyd.WindowManager.get():isOpen("map_window") then
		xyd.MainController.get():clearGame()
		xyd.MapController.get():openSelfMap(nil)
	end
end

function PreGameWindow:willClose()
	PreGameWindow.super.willClose(self)
	self:removeEventListeners()

	for i = 1, #self._usingTimelines do
		local sequence = self._usingTimelines[i]

		sequence:Kill(false)
	end

	self.timer:Stop()
end

function PreGameWindow:dispose()
	if self.params_.callBack then
		self.params_.callBack()
	end

	PreGameWindow.super.dispose(self)
end

function PreGameWindow:_disableBtns()
	self.start_btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.close_btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.defaultBg_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
end

function PreGameWindow:_enableBtns()
	self.start_btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	self.close_btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	self.defaultBg_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
end

function PreGameWindow:selectItem(itemId)
	local untimeItemID = itemId % 1000 + 1000

	if untimeItemID == self._itemIDs[1] then
		self._itemSelect1 = true

		self.select_1:SetActive(true)
		self.timer1_group:SetActive(false)
	elseif untimeItemID == self._itemIDs[2] then
		self._itemSelect2 = true

		self.select_2:SetActive(true)
		self.timer2_group:SetActive(false)
	elseif untimeItemID == self._itemIDs[3] then
		self._itemSelect3 = true

		self.select_3:SetActive(true)
		self.timer3_group:SetActive(false)
	elseif untimeItemID == self._itemIDs[4] then
		self._itemSelect4 = true

		self.select_4:SetActive(true)
		self.timer4_group:SetActive(false)
	end
end

function PreGameWindow:itemClick1()
	self.cur_item_click_index = 1
	local selfInfo = self.selfInfo_
	local itemID = tostring(self._itemIDs[1])
	local itemTimeID = tostring(self._itemIDs[1] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemCount = selfInfo:getItemNumByID(itemID)
	local itemTimeCount = selfInfo:getItemNumByID(itemTimeID)
	local count = itemCount + itemTimeCount

	if count <= 0 then
		if not xyd.MapController.get().isInNewUserGuide then
			xyd.WindowManager.get():openWindow("buy_item_window", {
				id = itemID
			})
		end

		return
	end

	if self._itemSelect1 then
		self._itemSelect1 = false

		self.select_1:SetActive(false)

		if self.expired_time_cache[1] then
			self.timer1_group:SetActive(true)
		end
	else
		self._itemSelect1 = true

		self.select_1:SetActive(true)
		self.timer1_group:SetActive(false)
	end
end

function PreGameWindow:itemClick2()
	self.cur_item_click_index = 2
	local selfInfo = self.selfInfo_
	local itemID = tostring(self._itemIDs[2])
	local itemTimeID = tostring(self._itemIDs[2] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemCount = selfInfo:getItemNumByID(itemID)
	local itemTimeCount = selfInfo:getItemNumByID(itemTimeID)
	local count = itemCount + itemTimeCount

	if count <= 0 then
		if not xyd.MapController.get().isInNewUserGuide then
			xyd.WindowManager.get():openWindow("buy_item_window", {
				id = itemID
			})
		end

		return
	end

	if self._itemSelect2 then
		self._itemSelect2 = false

		self.select_2:SetActive(false)

		if self.expired_time_cache[2] then
			self.timer2_group:SetActive(true)
		end
	else
		self._itemSelect2 = true

		self.select_2:SetActive(true)
		self.timer2_group:SetActive(false)
	end
end

function PreGameWindow:itemClick3()
	self.cur_item_click_index = 3
	local selfInfo = self.selfInfo_
	local itemID = tostring(self._itemIDs[3])
	local itemTimeID = tostring(self._itemIDs[3] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemCount = selfInfo:getItemNumByID(itemID)
	local itemTimeCount = selfInfo:getItemNumByID(itemTimeID)
	local count = itemCount + itemTimeCount

	if count <= 0 then
		if not xyd.MapController.get().isInNewUserGuide then
			xyd.WindowManager.get():openWindow("buy_item_window", {
				id = itemID
			})
		end

		return
	end

	if self._itemSelect3 then
		self._itemSelect3 = false

		self.select_3:SetActive(false)

		if self.expired_time_cache[3] then
			self.timer3_group:SetActive(true)
		end
	else
		self._itemSelect3 = true

		self.select_3:SetActive(true)
		self.timer3_group:SetActive(false)
	end
end

function PreGameWindow:itemClick4()
	self.cur_item_click_index = 4
	local selfInfo = self.selfInfo_
	local itemID = tostring(self._itemIDs[4])
	local itemTimeID = tostring(self._itemIDs[4] + ItemConstants.LIMITED_TIME_OFFSET)
	local itemCount = selfInfo:getItemNumByID(itemID)
	local itemTimeCount = selfInfo:getItemNumByID(itemTimeID)
	local count = itemCount + itemTimeCount

	if count <= 0 then
		if not xyd.MapController.get().isInNewUserGuide then
			xyd.WindowManager.get():openWindow("buy_item_window", {
				id = itemID
			})
		end

		return
	end

	if self._itemSelect4 then
		self._itemSelect4 = false

		self.select_4:SetActive(false)

		if self.expired_time_cache[4] then
			self.timer4_group:SetActive(true)
		end
	else
		self._itemSelect4 = true

		self.select_4:SetActive(true)
		self.timer4_group:SetActive(false)
	end
end

function PreGameWindow:timerCallback()
	local curTime = os.time()

	for i = 1, 4 do
		self:timerHelper(i, curTime)
	end
end

function PreGameWindow:timerHelper(index, curTime)
	local expireTime = self.expired_time_cache[index]

	if expireTime == nil or expireTime - curTime <= 0 then
		local selfInfo = self.selfInfo_
		local itemID = tostring(self._itemIDs[index])
		local itemTimeID = tostring(self._itemIDs[index] + ItemConstants.LIMITED_TIME_OFFSET)
		local itemCount = selfInfo:getItemNumByID(itemID)
		local itemTimeCount = selfInfo:getItemNumByID(itemTimeID)

		if not itemTimeCount or itemTimeCount <= 0 then
			if self.hasTimerOnItem[index] then
				self.timer_group[index]:SetActive(false)
				xyd.setUISprite(self.time_limited_img[index], xyd.MappingData.icon_shuliang, "icon_shuliang")

				self.hasTimerOnItem[index] = false
			end

			self:updateItemCountByIndex(index, itemCount)

			return
		end

		if not self.hasTimerOnItem[index] then
			xyd.setUISprite(self.time_limited_img[index], xyd.MappingData.icon_xianshi, "icon_xianshi")

			self.hasTimerOnItem[index] = true
		end

		expireTime = selfInfo:getItemExpireTimeByID(itemTimeID)
		self.expired_time_cache[index] = expireTime

		self:updateItemCountByIndex(index, itemCount + itemTimeCount)
	end

	local cd = expireTime - curTime

	if cd > 0 then
		self.timer_label[index].text = xyd.secondsToString(cd, xyd.SecondsStrType.WITH_HOUR)
	else
		self.timer_label[index].text = xyd.secondsToString(0, xyd.SecondsStrType.WITH_HOUR)
	end
end

function PreGameWindow:getTotalLevel()
	return self._totalLevel
end

function PreGameWindow:showShareBtn()
	self.share_btn_group:SetActive(true)
end

return PreGameWindow
