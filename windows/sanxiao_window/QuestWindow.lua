local QuestWindow = class("QuestWindow", import(".BaseWindow"))
local QuestComponent = import("app.windows.QuestRender")
local Point = import("app.common.Point")
local MappingData = xyd.MappingData
local QuestTable = xyd.tables.quest

function QuestWindow:ctor(name, params)
	QuestWindow.super.ctor(self, name, params)

	self._animationCenterX = xyd.getWidth() / 2
	self._animationCenterY = xyd.getHeight() / 2
	self._usingTimelines = {}
	self._questComponents = {}
	self._giftGroups = {}
	self._isClosed = false
	self._tapcount = 0
	self._isFirst = true
	self._uin = ""
	self._backFromFriendHome = false
	self._isTopicImageAnimation = false
	self._questModel = xyd.ModelManager:get():loadModel(xyd.ModelType.QUEST)

	if params then
		self._uin = params.uin
		self._backFromFriendHome = params.backFromFriendHome
	end

	xyd.EventDispatcher.outer():addEventListener("GET_QUEST_INFO", handler(self, self.onGetQuestInfo))
	xyd.DataPlatform.get():request("GET_QUEST_INFO", {})
end

function QuestWindow:initWindow()
	xyd.SoundManager.get():playEffect("room_web1/se_room_quest_window")
	QuestWindow.super.initWindow(self)
	self:getUIComponent()
	self:_initEvents()
	self:_onBtnQuest()
	self:initGift()
	self:initUIComponent()
end

function QuestWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_close = winTrans:ComponentByName("e:Skin/group_all/group_close", typeof(UISprite))
	self.group_quest = winTrans:NodeByName("e:Skin/group_all/quest/group_quest").gameObject
	self.quest_container = winTrans:NodeByName("e:Skin/group_all/quest/group_quest/container").gameObject
	self.group_all = winTrans:NodeByName("e:Skin/group_all").gameObject
	self.star_container = winTrans:NodeByName("e:Skin/group_all/star_container").gameObject
	self.bottom_quest = winTrans:NodeByName("e:Skin/group_all/bottom_btn/bottom_quest").gameObject
	self.bottom_visit = winTrans:NodeByName("e:Skin/group_all/bottom_btn/bottom_visit").gameObject
	self.bottom_zone = winTrans:NodeByName("e:Skin/group_all/bottom_btn/bottom_zone").gameObject
	self.quest_parent = winTrans:NodeByName("e:Skin/group_all/quest").gameObject
	self.group_visit = winTrans:NodeByName("e:Skin/group_all/group_visit").gameObject
	self.group_zone = winTrans:NodeByName("e:Skin/group_all/group_zone").gameObject
	self.group_noquest = winTrans:NodeByName("e:Skin/group_all/quest/group_noquest").gameObject
	self.no_quest_bg = winTrans:ComponentByName("e:Skin/group_all/quest/group_noquest/no_quest_bg", typeof(UISprite))
	self.no_quest_img = winTrans:ComponentByName("e:Skin/group_all/quest/group_noquest/no_quest_img", typeof(UISprite))
	self.date = winTrans:ComponentByName("e:Skin/group_all/quest/group_questinfo/date", typeof(UILabel))
	self.date_ = winTrans:ComponentByName("e:Skin/group_all/quest/group_questinfo/date_", typeof(UILabel))
	self.progress_percent_ = winTrans:ComponentByName("e:Skin/group_all/quest/group_questinfo/progress_percent_", typeof(UILabel))
	self.group_star = winTrans:NodeByName("e:Skin/group_all/group_star").gameObject
	self.group_gift = winTrans:NodeByName("e:Skin/group_all/quest/group_questinfo/group_gift").gameObject
	self.quest = winTrans:ComponentByName("e:Skin/group_all/bottom_btn/bottom_quest/quest", typeof(UISprite))
	self.quest_light = winTrans:ComponentByName("e:Skin/group_all/bottom_btn/bottom_quest/btn_quest/quest_light", typeof(UISprite))
	self.visit = winTrans:ComponentByName("e:Skin/group_all/bottom_btn/bottom_visit/visit", typeof(UISprite))
	self.visit_light = winTrans:ComponentByName("e:Skin/group_all/bottom_btn/bottom_visit/btn_visit/visit_light", typeof(UISprite))
	self.zone = winTrans:ComponentByName("e:Skin/group_all/bottom_btn/bottom_zone/zone", typeof(UISprite))
	self.zone_light = winTrans:ComponentByName("e:Skin/group_all/bottom_btn/bottom_zone/btn_zone/zone_light", typeof(UISprite))
	self.txt_quest = winTrans:ComponentByName("e:Skin/group_all/bottom_btn/bottom_quest/btn_quest/txt_quest", typeof(UILabel))
	self.txt_visit = winTrans:ComponentByName("e:Skin/group_all/bottom_btn/bottom_visit/btn_visit/txt_visit", typeof(UILabel))
	self.txt_zone = winTrans:ComponentByName("e:Skin/group_all/bottom_btn/bottom_zone/btn_zone/txt_zone", typeof(UILabel))
	self.image_banzi = winTrans:ComponentByName("e:Skin/group_all/image_banzi", typeof(UISprite))
	self.star_num_group = winTrans:ComponentByName("e:Skin/group_all/group_star/star_num_group", typeof(UILabel))
	self.star_ = winTrans:ComponentByName("e:Skin/group_all/group_star/star_", typeof(UISprite))
	self.gift_slider = winTrans:ComponentByName("e:Skin/group_all/quest/group_questinfo/progress_bar", typeof(UISlider))
	self.progress_bar = winTrans:ComponentByName("e:Skin/group_all/quest/group_questinfo/progress_bar", typeof(UISprite))
	self.image_gift = winTrans:ComponentByName("e:Skin/group_all/quest/group_questinfo/group_gift/image_gift", typeof(UISprite))
	self.guide_area = winTrans:NodeByName("guide_area").gameObject
	self.txt_quest.text = __("PLAN")
	self.txt_visit.text = __("VISIT")
	self.txt_zone.text = __("ZONE")
	self.group_star.transform.localPosition = Vector3(self.group_star.transform.localPosition.x, (xyd.getFixedHeight() - 1920) / 2.4 + 890, 0)
	self.group_close.transform.localPosition = Vector3(self.group_close.transform.localPosition.x, (xyd.getFixedHeight() - 1920) / 2.4 + 890, 0)

	xyd.setUISpriteAsync(self.quest, MappingData.icon_jihua1, "icon_jihua1")
	xyd.setUISpriteAsync(self.quest_light, MappingData.icon_jihua2, "icon_jihua2")

	local pos = self.group_quest.transform.localPosition
	self.saved_scroll_pos = Vector3(pos.x, pos.y, pos.z)
end

function QuestWindow:initGift()
	local rewards = xyd.tables.questReward:getTableDataByDay(self._questModel:getCurDay())

	for key in pairs(rewards) do
		local numKey = key

		if self._questModel.progress < numKey then
			if numKey ~= 100 then
				local new_gift = NGUITools.AddChild(self.group_gift, self.image_gift.gameObject)
				new_gift.transform.localPosition = Vector3(self.image_gift.transform.localPosition.x - 5 * (100 - numKey), new_gift.transform.localPosition.y, new_gift.transform.localPosition.z)
				new_gift.transform.localScale = Vector3(0.62, 0.62, 1)

				xyd.setUISpriteAsync(new_gift:GetComponent(typeof(UISprite)), MappingData.icon_quest_gift2, "icon_quest_gift2")

				self._giftGroups[numKey] = new_gift
			else
				xyd.setUISpriteAsync(self.image_gift, MappingData.icon_quest_gift, "icon_quest_gift")

				self._giftGroups[numKey] = self.image_gift
			end
		end
	end
end

function QuestWindow:initUIComponent()
	self.group_quest:GetComponent(typeof(UIScrollView)).onMomentumMove = handler(self, self.onMomentumMove)

	self:setDefaultBgClick(function ()
		self:_onBtnExit()
	end)
	xyd.setNormalBtnBehavior(self.group_close.gameObject, self, self._onBtnExit)
	xyd.setNormalBtnBehavior(self.bottom_quest.gameObject, self, self._onBtnQuest)
	self:setStarNum(xyd.SelfInfo.get():get_star())
	self:_initQuests()
	self:_setProgress()
	self:_checkFinishedQuests()
end

function QuestWindow:onMomentumMove()
	if self.group_quest == nil or tolua.isnull(self.group_quest) then
		return
	end

	self.group_quest:GetComponent(typeof(SpringPanel)).target = self.saved_scroll_pos
end

function QuestWindow:setStarNum(val)
	self.star_num_group.text = tostring(val)
end

function QuestWindow:_setProgress()
	if self._percentTimeline then
		self._percentTimeline:stop()
		self._percentTimeline:kill()
	end

	local progress = self._questModel.progress
	local progressView = self._questModel.progressView
	local delta = progressView - progress

	if progressView < progress then
		self.gift_slider.value = progressView / 100
		self.progress_percent_.text = tostring(progressView) .. "%"

		return
	end

	self.gift_slider.value = progress / 100
	self.progress_percent_.text = tostring(progress) .. "%"

	if delta == 0 then
		return
	end

	local now = progress
	local moveTime = math.max(delta * xyd.TweenDeltaTime, 30 * xyd.TweenDeltaTime)

	local function numGetter()
		return self.gift_slider.value
	end

	local function numSetter(value)
		self.gift_slider.value = value
	end

	local function intGetter()
		return now
	end

	local function intSetter(value)
		now = value
		self.progress_percent_.text = tostring(now) .. "%"
	end

	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOGetter_float(numGetter), DG.Tweening.Core.DOSetter_float(numSetter), progressView / 100, moveTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOGetter_int(intGetter), DG.Tweening.Core.DOSetter_int(intSetter), progressView, moveTime):SetEase(DG.Tweening.Ease.Linear))

	self._questModel.progress = progressView
end

function QuestWindow:_checkQuestReward()
	local flag = false
	local rewards = xyd.tables.questReward:getTableDataByDay(self._questModel:getCurDay())
	local progress = self._questModel.progress

	for key in pairs(rewards) do
		local numKey = key

		if numKey <= progress and self._giftGroups[numKey] then
			xyd.QuestController.get():increaseActionCount()

			flag = true

			self:_loadQuestRewards(self._questModel:getCurDay(), numKey)

			break
		end
	end

	return flag
end

function QuestWindow:_loadQuestRewards(day, percent)
	local function callback(response, success)
		local data = response.payload
		local backpackModel = xyd.ModelManager.get():loadModel(xyd.ModelType.BACKPACK)

		if success then
			if data.rewards ~= nil and data.success then
				for _, reward in pairs(data.rewards) do
					if reward.item_id == xyd.ItemConstants.GEM then
						xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYER_INFO):addGem(reward.item_num)
					else
						backpackModel:addItemByID(reward.item_id, reward.item_num)
					end
				end

				xyd.SelfInfo.get():syncItem(backpackModel.items)
				self:_giftAnimation(data.rewards, percent)
			end

			xyd.QuestController.get():decreaseActionCount()
		else
			xyd.QuestController.get():decreaseActionCount()
		end
	end

	xyd.DataPlatform.get():loadQuestRewards(day, percent, callback)
end

function QuestWindow:_initEvents()
	xyd.EventDispatcher:inner():addEventListener(xyd.event.REMOVE_QUEST_VIEW, self._removeQuestView, self)
	xyd.EventDispatcher:inner():addEventListener(xyd.event.ACTIVE_QUEST_VIEW, self._activeQuestView, self)
	xyd.EventDispatcher:inner():addEventListener(xyd.event.CHECK_QUEST_REWARD, self._checkQuestReward, self)
end

function QuestWindow:_removeEvents()
	xyd.EventDispatcher:inner():removeEventListenersByEvent(xyd.event.REMOVE_QUEST_VIEW)
	xyd.EventDispatcher:inner():removeEventListenersByEvent(xyd.event.ACTIVE_QUEST_VIEW)
	xyd.EventDispatcher:inner():removeEventListenersByEvent(xyd.event.CHECK_QUEST_REWARD)
end

function QuestWindow:_initQuests()
	local curQuestsView = self._questModel:getCurQuestsView()
	local day = self._questModel:getCurDay()
	local count = 0

	for idStr in pairs(curQuestsView) do
		local id = __TS__Number(idStr)
		local questComponent = QuestComponent.new(id, self.quest_container, count)
		self._questComponents[id] = questComponent
		count = count + 1
	end

	if count == 0 then
		self.group_noquest.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.no_quest_img, MappingData.icon_zanwurenwu, "icon_zanwurenwu")
	else
		self.group_noquest.gameObject:SetActive(false)
	end

	local datetext = __("DAY_TIP")
	self.date.text = string.gsub(datetext, "%%d", "    ")
	self.date_.text = tostring(day)
end

function QuestWindow:_checkFinishedQuests()
	local finishedQuestInfo = self._questModel:getFinishedQuestInfo()

	if #finishedQuestInfo == 0 then
		return
	end

	local finishedID = finishedQuestInfo[1]
	local nextQuestIDs = finishedQuestInfo[2]
	local isInQuestChain = finishedQuestInfo[3]

	if isInQuestChain then
		self._questModel:clearFinishedQuestInfo()

		for idStr in pairs(self._questComponents) do
			local id = __TS__Number(idStr)
			local questComponent = self._questComponents[id]

			if id == nextQuestIDs[1] then
				questComponent:playChainDagouEffect(true)

				break
			end
		end
	else
		for idStr in pairs(self._questComponents) do
			local id = __TS__Number(idStr)
			local questComponent = self._questComponents[id]

			if id == finishedID then
				questComponent:playDagouEffect(finishedID, nextQuestIDs)
				questComponent:playChainDagouEffect(false)

				break
			end
		end
	end
end

function QuestWindow:onGetQuestInfo(event)
	xyd.EventDispatcher.outer():removeEventListenersByEvent("GET_QUEST_INFO")

	local questData = event.data.quest

	for questInfo in __TS__Iterator(questData) do
		if QuestTable:hasQuest(questInfo.id) then
			local quest = self._questModel:getQuestByID(questInfo.id)

			if quest then
				quest.state = questInfo.state
				quest.endTime = questInfo.end_time

				xyd.EventDispatcher:inner():dispatchEvent({
					name = xyd.event.REPAIR_CHANGE_TIME,
					params = {
						questID = quest.id
					}
				})
			end
		end
	end
end

function QuestWindow:_removeQuestView(event)
	local finishedID = event.params.finishedID
	local nextQuestIDs = event.params.nextQuestIDs

	for idStr in pairs(self._questComponents) do
		local id = __TS__Number(idStr)
		local questComponent = self._questComponents[tonumber(id)]

		if id == finishedID then
			questComponent:playRemoveEffect(finishedID, nextQuestIDs)
		elseif finishedID < id then
			questComponent:playUpEffect(id, nextQuestIDs)
		end
	end
end

function QuestWindow:_activeQuestView(event)
	local finishedID = event.params.finishedID
	local nextQuestIDs = event.params.nextQuestIDs
	self._questComponents[finishedID] = nil

	for nextQuestID in __TS__Iterator(nextQuestIDs) do
		if self._questModel.isFinal then
			break
		end

		self._questModel:addQuestView(nextQuestID)

		local index = self:_getQuestPos(nextQuestID)
		local questComponent = QuestComponent.new(nextQuestID, self.quest_container, index)
		self._questComponents[tonumber(nextQuestID)] = questComponent

		questComponent:playActiveEffect()
	end

	if self._questModel.isFinal then
		self.group_noquest:SetActive(true)
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.CHECK_QUEST_REWARD
		})
	else
		self.group_noquest:SetActive(false)
	end

	self._questModel:removeQuestView(finishedID)
	self._questModel:clearFinishedQuestInfo()
end

function QuestWindow:_getQuestPos(nextQuestID)
	local pos = 0

	for idStr in pairs(self._questComponents) do
		local id = __TS__Number(idStr)
		pos = pos + 1
	end

	return pos
end

function QuestWindow:updateQuestView(id)
	self._questComponents[id]:setView(id)
end

function QuestWindow:useStar(starCost, starAnimationPos, starScaleX, starScaleY, callback, questComponent)
	if starCost == 0 then
		callback(nil)

		return
	end

	local deltaTime = 0.2

	xyd.QuestController.get():increaseActionCount()
	XYDCo.WaitForTime((starCost - 1) * deltaTime + 60 * xyd.TweenDeltaTime, function ()
		xyd.QuestController.get():decreaseActionCount()
	end, nil)

	local fromPos = Point.new(self.star_.transform.localPosition.x + self.group_star.transform.localPosition.x, self.star_.transform.localPosition.y + self.group_star.transform.localPosition.y)
	local toPos = Point.new(starAnimationPos.x + questComponent.window.transform.localPosition.x, starAnimationPos.y + questComponent.window.transform.localPosition.y)
	local sequence = DG.Tweening.DOTween.Sequence()

	table.insert(self._usingTimelines, sequence)

	local i = 1

	while starCost >= i do
		local star = NGUITools.AddChild(self.star_container.gameObject, "fakestar")
		local starmap = star:AddComponent(typeof(UISprite))
		starmap.pivot = UIWidget.Pivot.TopLeft
		starmap.depth = 100

		xyd.setUISpriteAsync(starmap, MappingData.icon_xingxing, "icon_xingxing")
		starmap:MakePixelPerfect()

		star.transform.localPosition = Vector3(fromPos.x, fromPos.y, 0)
		star.transform.localScale = Vector3(self.star_.transform.localScale.x, self.star_.transform.localScale.y, 1)

		star:SetActive(false)

		local temp = i

		sequence:InsertCallback((i - 1) * deltaTime, function ()
			star:SetActive(true)
			xyd.SoundManager.get():playEffect("room_web1/se_room_star1")
			self:setStarNum(xyd.SelfInfo.get():get_star() - temp)
		end)
		sequence:Insert((i - 1) * deltaTime, star.transform:DOScale(Vector3(1.1, 1.1, 1), 10 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
		sequence:Insert((i - 1) * deltaTime, star.transform:DOLocalMoveY(toPos.y, 30 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
		sequence:Insert((i - 1) * deltaTime, star.transform:DOLocalMoveX(toPos.x, 30 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.InBack, 0.5, 0))
		sequence:Insert((i - 1) * deltaTime + 10 * xyd.TweenDeltaTime, star.transform:DOScale(Vector3(starScaleX, starScaleY, 1), 23 * xyd.TweenDeltaTime))
		sequence:AppendCallback(function ()
			star:SetActive(false)
		end)

		i = i + 1
	end

	sequence:AppendCallback(function ()
		callback(nil)
	end)
end

function QuestWindow:_giftAnimation(reward, progress)
	xyd.QuestController.get():increaseActionCount()
	XYDCo.WaitForTime(54 * xyd.TweenDeltaTime, function ()
		xyd.QuestController.get():decreaseActionCount()
	end, nil)

	local gift = self._giftGroups[progress]
	gift.transform.parent = self.star_container.transform
	local groupGift = NGUITools.AddChild(self.star_container.gameObject, self._giftGroups[progress].gameObject):GetComponent(typeof(UISprite))
	groupGift.pivot = UIWidget.Pivot.Bottom
	groupGift.transform.localPosition = gift.transform.localPosition
	groupGift.transform.localScale = gift.transform.localScale

	gift.gameObject:SetActive(false)

	local x = groupGift.transform.localPosition.x
	local y = groupGift.transform.localPosition.y
	local scale = 0.62

	if progress == 100 then
		scale = 0.68
	end

	local sequence = DG.Tweening.DOTween.Sequence()
	local transform = groupGift.transform

	sequence:Insert(0, transform:DOLocalMoveY(y - 6, 2 * xyd.TweenDeltaTime))
	sequence:Insert(0, transform:DOScale(Vector3(scale, scale * 0.3, 1), 2 * xyd.TweenDeltaTime))
	sequence:Insert(12 * xyd.TweenDeltaTime, transform:DOLocalMoveY(y + 12, 6 * xyd.TweenDeltaTime))
	sequence:Insert(2 * xyd.TweenDeltaTime, transform:DOScale(Vector3(scale, scale, 1), 15 * xyd.TweenDeltaTime))
	sequence:Insert(4 * xyd.TweenDeltaTime, transform:DORotate(Vector3(0, 0, -7), 1 * xyd.TweenDeltaTime, DG.Tweening.RotateMode.Fast))
	sequence:Insert(5 * xyd.TweenDeltaTime, transform:DORotate(Vector3(0, 0, 7), 2 * xyd.TweenDeltaTime, DG.Tweening.RotateMode.Fast))
	sequence:Insert(7 * xyd.TweenDeltaTime, transform:DORotate(Vector3(0, 0, -9), 2 * xyd.TweenDeltaTime, DG.Tweening.RotateMode.Fast))
	sequence:Insert(9 * xyd.TweenDeltaTime, transform:DORotate(Vector3(0, 0, 4), 3 * xyd.TweenDeltaTime, DG.Tweening.RotateMode.Fast))
	sequence:Insert(12 * xyd.TweenDeltaTime, transform:DORotate(Vector3(0, 0, -6), 3 * xyd.TweenDeltaTime, DG.Tweening.RotateMode.Fast))
	sequence:Insert(15 * xyd.TweenDeltaTime, transform:DORotate(Vector3(0, 0, 2), 3 * xyd.TweenDeltaTime, DG.Tweening.RotateMode.Fast))
	sequence:Insert(18 * xyd.TweenDeltaTime, transform:DORotate(Vector3(0, 0, -2), 3 * xyd.TweenDeltaTime, DG.Tweening.RotateMode.Fast))
	sequence:Insert(21 * xyd.TweenDeltaTime, transform:DORotate(Vector3(0, 0, 0), 3 * xyd.TweenDeltaTime, DG.Tweening.RotateMode.Fast))

	local toPos = {
		x = 0,
		y = 200
	}

	XYDCo.WaitForTime(24 * xyd.TweenDeltaTime, function ()
		groupGift.pivot = UIWidget.Pivot.Center
	end, nil)
	sequence:Insert(24 * xyd.TweenDeltaTime, transform:DOLocalMoveY(toPos.y, 30 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(24 * xyd.TweenDeltaTime, transform:DOLocalMoveX(toPos.x, 30 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.InBack))
	sequence:Insert(24 * xyd.TweenDeltaTime, transform:DOScale(Vector3(scale * 3.5, scale * 3.5, 1), 30 * xyd.TweenDeltaTime))

	xyd.QuestController.get().isRequesting = true

	XYDCo.WaitForTime(54 * xyd.TweenDeltaTime, function ()
		self:_closeWindow()

		local reward_standard = {}

		for key in pairs(reward) do
			reward_standard[reward[key].item_id] = reward[key].item_num
		end

		xyd.WindowManager.get():openWindow("item_reward_window", {
			from = "quest",
			items = reward_standard,
			progress = progress,
			onComplete = function ()
				xyd.QuestController.get().isRequesting = false

				xyd.EventDispatcher.inner():dispatchEvent({
					name = xyd.event.CHECK_UI_DISPLAY
				})
				xyd.WindowManager.get():openWindow("quest_window")
			end
		})
	end, nil)
end

function QuestWindow:_onBtnExit()
	if xyd.QuestController.get().isRequesting then
		return
	end

	xyd.SoundManager.get():playEffect("Common/se_button")
	self:_closeWindow()
end

function QuestWindow:_closeWindow()
	if self._isClosed then
		return
	end

	self._isClosed = true

	self:close(function ()
		XYDCo.WaitForTime(5 * xyd.TweenDeltaTime, function ()
			xyd.EventDispatcher:inner():dispatchEvent({
				name = xyd.event.CHECK_UI_DISPLAY
			})
		end, nil)
	end, false)
end

function QuestWindow:resetBtnState()
	self.quest.gameObject:SetActive(true)
	self.quest_light.gameObject:SetActive(false)
	self.visit.gameObject:SetActive(true)
	self.visit_light.gameObject:SetActive(false)
	self.zone.gameObject:SetActive(true)
	self.zone_light.gameObject:SetActive(false)
	self.quest_parent.gameObject:SetActive(false)
	self.group_visit.gameObject:SetActive(false)
	self.group_zone.gameObject:SetActive(false)

	self.txt_quest.color = Color.New2(1010980351)
	self.txt_visit.color = Color.New2(1010980351)
	self.txt_zone.color = Color.New2(1010980351)
end

function QuestWindow:_onBtnQuest()
	if xyd.QuestController.get().isRequesting or self.isDisposed_ then
		return
	end

	if self.selectedIndex == 0 and not self._isFirst then
		return
	end

	self._isFirst = false

	self:resetBtnState()

	self.selectedIndex = 0

	self.quest_parent.gameObject:SetActive(true)
	self.quest_light.gameObject:SetActive(true)
	self.quest.gameObject:SetActive(false)
	self.image_banzi.gameObject:SetActive(true)

	self.txt_quest.color = Color.New2(4294307839.0)

	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.OPERATE_HOME_GUIDE,
		params = {
			container_name = "quest_window",
			related_target_name = "btn_quest"
		}
	})
end

function QuestWindow:_onBtnZone()
	if xyd.QuestController.get().isRequesting or self.isDisposed_ then
		return
	end

	if self.selectedIndex == 2 then
		return
	end

	self:resetBtnState()
	self.group_zone.gameObject:SetActive(true)
	self.zone_light.gameObject:SetActive(true)
	self.zone.gameObject:SetActive(false)

	self.selectedIndex = 2

	self.image_banzi.gameObject:SetActive(false)

	self.txt_zone.color = Color.New2(4294307839.0)

	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.OPERATE_HOME_GUIDE,
		params = {
			container_name = "quest_window",
			related_target_name = "btn_zone"
		}
	})
end

function QuestWindow:_onBtnVisit()
	if xyd.QuestController.get().isRequesting or self.isDisposed_ then
		return
	end

	if self.selectedIndex == 1 then
		return
	end

	self:resetBtnState()
	self.group_visit.gameObject:SetActive(true)
	self.visit_light.gameObject:SetActive(true)
	self.visit.gameObject:SetActive(false)

	self.selectedIndex = 1
	self.txt_visit.color = Color.New2(4294307839.0)

	self.image_banzi.gameObject:SetActive(true)
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.OPERATE_HOME_GUIDE,
		params = {
			container_name = "quest_window",
			related_target_name = "btn_visit"
		}
	})
end

function QuestWindow:disableUIListener()
	self.group_quest:GetComponent(typeof(UIScrollView)).onMomentumMove = nil

	self:setDefaultBgClick(nil)

	UIEventListener.Get(self.group_close.gameObject).onPress = nil
	UIEventListener.Get(self.bottom_quest.gameObject).onPress = nil
end

function QuestWindow:dispose()
	self:disableUIListener()
	self:_removeEvents()

	for _, sq in ipairs(self._usingTimelines) do
		if sq then
			sq:Kill()
		end
	end

	self._usingTimelines = {}

	for idStr in pairs(self._questComponents) do
		local id = __TS__Number(idStr)
		local questComponent = self._questComponents[id]

		questComponent:dispose()
	end

	QuestWindow.super.dispose(self)
end

function QuestWindow:onTapQuestBubble(id)
	if self._tapcount > 0 then
		return
	end

	self._tapcount = self._tapcount + 1

	if not self:_checkQuestReward() and self._questComponents and self._questComponents[id] then
		self._questComponents[id]:onTapQuestBubble()
	end
end

function QuestWindow:onTapTimeRing(id)
	if self._questComponents and self._questComponents[id] then
		self._questComponents[id]:onTapTimeRing()
	end
end

return QuestWindow
