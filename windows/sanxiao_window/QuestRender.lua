local QuestComponent = class("QuestComponent")
local QuestTable = xyd.tables.quest
local QuestConstants = xyd.QuestConstants
local Destroy = UnityEngine.Object.Destroy
local MappingData = xyd.MappingData
local Point = import("app.common.Point")
local RandomActionController = import("app.controllers.RandomActionController")
local EffectConstants = xyd.EffectConstants
local DBResManager = xyd.DBResManager

function QuestComponent:ctor(id, parent, count)
	local quest_render = ResCache.AddGameObject(parent, "Prefabs/Components/quest_render")
	quest_render.transform.localPosition = Vector3(0, 415 - count * 200, 0)
	self.window = quest_render
	self.gou = {}
	self._actionTimeline = {}
	self.ICON_WIDTH = 104
	self._count = 3
	self.COUNT_LIMIT = 5
	self._questID = id

	self:initWindow()
end

function QuestComponent:initWindow()
	self:getUIComponent()
	xyd.setUISpriteAsync(self.gou1, MappingData.icon_gou, "icon_gou")
	xyd.setUISpriteAsync(self.gou2, MappingData.icon_gou, "icon_gou")
	xyd.setUISpriteAsync(self.gou3, MappingData.icon_gou, "icon_gou")
	__TS__ArrayPush(self.gou, self.gou1)
	__TS__ArrayPush(self.gou, self.gou2)
	__TS__ArrayPush(self.gou, self.gou3)
	self:setView(self._questID)
	xyd.setNormalBtnBehavior(self.btn_start_, self, self._onTapBtnStart)
	xyd.setNormalBtnBehavior(self.btn_accelerate_bg.gameObject, self, self._onTapBtnAccelerate)
	xyd.setNormalBtnBehavior(self.btn_complete_, self, self._onTapBtnComplete)
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.CHECK_HOME_GUIDE,
		params = {
			target_name = "btn_start_",
			container_name = "quest_window",
			quest_id = self._questID,
			target = self.btn_start_,
			container = xyd.WindowManager.get():getWindow("quest_window").guide_area
		}
	})
end

function QuestComponent:getUIComponent()
	local winTrans = self.window.transform
	self.bg = winTrans:ComponentByName("e:Skin/group_quest_/bg", typeof(UISprite))
	self.group_quest_ = winTrans:NodeByName("e:Skin/group_quest_").gameObject
	self.group_quest_widget = winTrans:ComponentByName("e:Skin/group_quest_", typeof(UIWidget))
	self.effectTarget = winTrans:ComponentByName("e:Skin/group_quest_/effectLayerTarget", typeof(UITexture))
	self.icon_quest_ = winTrans:ComponentByName("e:Skin/group_quest_/group_icon/icon_quest_", typeof(UISprite))
	self.desc_ = winTrans:ComponentByName("e:Skin/group_quest_/desc_", typeof(UILabel))
	self.bg_gou1 = winTrans:ComponentByName("e:Skin/group_quest_/chain_/bg_gou1", typeof(UISprite))
	self.gou1 = winTrans:ComponentByName("e:Skin/group_quest_/chain_/gou1", typeof(UISprite))
	self.bg_gou2 = winTrans:ComponentByName("e:Skin/group_quest_/chain_/bg_gou2", typeof(UISprite))
	self.gou2 = winTrans:ComponentByName("e:Skin/group_quest_/chain_/gou2", typeof(UISprite))
	self.bg_gou3 = winTrans:ComponentByName("e:Skin/group_quest_/chain_/bg_gou3", typeof(UISprite))
	self.gou3 = winTrans:ComponentByName("e:Skin/group_quest_/chain_/gou3", typeof(UISprite))
	self.chain_ = winTrans:NodeByName("e:Skin/group_quest_/chain_").gameObject
	self.quest_chain_ = winTrans:ComponentByName("e:Skin/group_quest_/chain_/quest_chain_", typeof(UILabel))
	self.btn_start_ = winTrans:NodeByName("e:Skin/group_quest_/btn_start_").gameObject
	self.bg_start = winTrans:ComponentByName("e:Skin/group_quest_/btn_start_/bg_start", typeof(UISprite))
	self.txt_start_ = winTrans:ComponentByName("e:Skin/group_quest_/btn_start_/txt_start_", typeof(UILabel))
	self.txt_complete_ = winTrans:ComponentByName("e:Skin/group_quest_/btn_complete_/txt_complete_", typeof(UILabel))
	self.btn_complete_ = winTrans:NodeByName("e:Skin/group_quest_/btn_complete_").gameObject
	self.btn_accelerate_ = winTrans:NodeByName("e:Skin/group_quest_/btn_accelerate_").gameObject
	self.acc_active = winTrans:NodeByName("e:Skin/group_quest_/btn_accelerate_/acc_active").gameObject
	self.btn_accelerate_bg = winTrans:ComponentByName("e:Skin/group_quest_/btn_accelerate_/btn_accelerate_bg_", typeof(UISprite))
	self.complete_ = winTrans:ComponentByName("e:Skin/group_quest_/btn_accelerate_/complete_", typeof(UILabel))
	self.diamond_icon_ = winTrans:ComponentByName("e:Skin/group_quest_/btn_accelerate_/diamond_icon_", typeof(UISprite))
	self.diamond_num_ = winTrans:ComponentByName("e:Skin/group_quest_/btn_accelerate_/diamond_num_", typeof(UILabel))
	self.star_ = winTrans:ComponentByName("e:Skin/group_quest_/btn_start_/star_", typeof(UILabel))
	self.num_ = winTrans:ComponentByName("e:Skin/group_quest_/btn_start_/num_", typeof(UILabel))
	self.num_acc = winTrans:ComponentByName("e:Skin/group_quest_/btn_accelerate_/acc_active/num_acc", typeof(UILabel))
	self.time_ = winTrans:ComponentByName("e:Skin/group_quest_/btn_accelerate_/time_", typeof(UILabel))
	self.clock = winTrans:ComponentByName("e:Skin/group_quest_/btn_accelerate_/clock", typeof(UISprite))
	self.star_ = winTrans:ComponentByName("e:Skin/group_quest_/btn_start_/star_", typeof(UISprite))
	self.star_acc = winTrans:ComponentByName("e:Skin/group_quest_/btn_accelerate_/acc_active/star_acc", typeof(UISprite))
	self.start_acc = winTrans:ComponentByName("e:Skin/group_quest_/btn_accelerate_/acc_active/start_acc", typeof(UILabel))

	xyd.setUISpriteAsync(self.clock, MappingData.icon_daojishi_quest, "icon_daojishi_quest")

	self.txt_start_.text = __("START")
	self.start_acc.text = __("START")
	self.txt_complete_.text = __("COMPLETE")
	self.complete_.text = __("COMPLETE")
end

function QuestComponent:_initTimer()
	if not self._timer then
		self._timer = Timer.New(handler(self, self._timerCallback), 1, -1)

		self._timer:Start()
	end
end

function QuestComponent:_timerCallback()
	self._count = self._count + 1
	local quest = xyd.ModelManager:get():loadModel(xyd.ModelType.QUEST):getQuestViewByID(self._questID)

	if not quest then
		return
	end

	if quest.state == QuestConstants.ACTIVE then
		if self.COUNT_LIMIT <= self._count then
			self._count = 0
		end
	elseif quest.state == QuestConstants.COMPLETE then
		if self._lastState ~= QuestConstants.COMPLETE then
			self._lastState = QuestConstants.COMPLETE

			xyd.QuestController.get():updateQuest(quest, QuestConstants.COMPLETE)
			self:setView(self._questID)
		end

		if self.COUNT_LIMIT <= self._count then
			self._count = 0
		end
	elseif quest.state == QuestConstants.STARTED then
		local cd = quest.endTime - xyd.SelfInfo.get():getTime()

		if cd > 0 then
			local price = xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST).diamondPrice
			self.diamond_num_.text = tostring(math.ceil(cd / 60) * price)

			self:setTime(cd)
		else
			xyd.QuestController.get():updateQuest(quest, QuestConstants.COMPLETE)
			self:setView(self._questID)
		end
	end
end

function QuestComponent:_onTapBtnStart()
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.CLOSE_HOME_GUIDE
	})
	xyd.QuestController.get():onSkipStory(false)
	RandomActionController.get():onSkipStory()

	local starpos = Point.new(self.group_quest_.transform.localPosition.x + self.btn_start_.transform.localPosition.x + self.star_.transform.localPosition.x, self.group_quest_.transform.localPosition.y + self.btn_start_.transform.localPosition.y + self.star_.transform.localPosition.y)

	xyd.QuestController.get():onStartQuest(self._questID, self._starCost, starpos, self.star_.transform.localScale.x, self.star_.transform.localScale.y, self.btn_start_, self)
end

function QuestComponent:_onTapBtnAccelerate()
	local quest = xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST):getQuestViewByID(self._questID)

	if quest.state == QuestConstants.STARTED then
		xyd.WindowManager.get():openWindow("quest_share_window", {
			questId = self._questID
		})
	elseif quest.state == QuestConstants.ACTIVE then
		xyd.QuestController.get():onSkipStory()
		RandomActionController.get():onSkipStory()

		local starpos = Point.new(self.group_quest_.transform.localPosition.x + self.btn_accelerate_.transform.localPosition.x + self.acc_active.transform.localPosition.x + self.star_acc.transform.localPosition.x, self.group_quest_.transform.localPosition.y + self.btn_accelerate_.transform.localPosition.y + self.acc_active.transform.localPosition.y + self.star_acc.transform.localPosition.y)

		xyd.QuestController.get():onStartQuest(self._questID, self._starCost, starpos, self.star_acc.transform.localScale.x, self.star_acc.transform.localScale.y, self.btn_accelerate_bg.gameObject, self)
	end
end

function QuestComponent:_onTapBtnComplete()
	xyd.QuestController.get():onSkipStory(false)
	RandomActionController.get():onSkipStory()
	xyd.QuestController.get():onCompleteQuest(self._questID)
end

function QuestComponent:setView(id)
	local quest = xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST):getQuestViewByID(id)

	if quest then
		self:_createQuest(quest)
	end
end

function QuestComponent:_createQuest(quest)
	self:_setQuestView()

	if quest.state ~= QuestConstants.FINISHED then
		self:_initTimer()
	end

	self._lastState = quest.state

	if quest.state == QuestConstants.ACTIVE then
		self:_getActiveQuest(quest.state)
	elseif quest.state == QuestConstants.STARTED then
		self:_getStartedQuest(quest.state)
	elseif quest.state == QuestConstants.COMPLETE then
		self:_getCompleteQuest(quest.state)
	elseif quest.state == QuestConstants.FINISHED then
		self:_getFinishedQuest()
	end
end

function QuestComponent:_initEffect(isAccelerate)
end

function QuestComponent:_getActiveQuest()
	local questInfo = QuestTable:getTableDataByQuestID(tonumber(self._questID))

	if questInfo.last_time == 0 then
		self.btn_start_:SetActive(true)
		self.btn_accelerate_:SetActive(false)
		self.btn_complete_:SetActive(false)
		self:_initEffect(false)
	else
		xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST):getAccelerateInfo(self._questID)
		self.btn_start_:SetActive(false)
		self.btn_accelerate_:SetActive(true)
		self.btn_complete_:SetActive(false)
		self.complete_:SetActive(false)
		self.acc_active:SetActive(true)
		self.diamond_icon_:SetActive(false)
		self.diamond_num_:SetActive(false)
		self:_initEffect(true)
	end
end

function QuestComponent:_getStartedQuest()
	self.btn_start_:SetActive(false)
	self.btn_accelerate_:SetActive(true)
	self.btn_complete_:SetActive(false)
	self:_timerCallback()
	self:_initEffect(true)
end

function QuestComponent:_getCompleteQuest()
	self.btn_start_:SetActive(false)
	self.btn_accelerate_:SetActive(false)
	self.btn_complete_:SetActive(true)
	self:_initEffect(false)
end

function QuestComponent:_getFinishedQuest()
	self.btn_start_:SetActive(false)
	self.btn_accelerate_:SetActive(false)
	self.btn_complete_:SetActive(false)
end

function QuestComponent:_setQuestView()
	local questInfo = QuestTable:getTableDataByQuestID(tonumber(self._questID))

	self:setDesc(__(questInfo.name))
	self:setIcon(questInfo.icon)
	self:setStar(questInfo.star)
	self:setChain(questInfo.quest_chain_len, questInfo.quest_chain_index)
	self:setTime(bit.bor(questInfo.last_time, 0))
end

function QuestComponent:setIcon(val)
	xyd.setUISpriteAsync(self.icon_quest_, MappingData[val], val, function ()
		self.icon_quest_:MakePixelPerfect()

		local originWidth = self.icon_quest_.width
		local originHeight = self.icon_quest_.height
		local limitEdgeLength = self.ICON_WIDTH
		local newWidth, newHeight = nil

		if originHeight < originWidth then
			newWidth = limitEdgeLength
			newHeight = limitEdgeLength * originHeight / originWidth
		else
			newHeight = limitEdgeLength
			newWidth = limitEdgeLength * originWidth / originHeight
		end

		self.icon_quest_.height = newHeight
		self.icon_quest_.width = newWidth
	end)
end

function QuestComponent:setDesc(val)
	self.desc_.text = val
end

function QuestComponent:setChain(length, index)
	if length > 1 then
		self.chain_:SetActive(true)

		self.quest_chain_.text = "(" .. tostring(index - 1) .. "/" .. tostring(length) .. ")"

		self.quest_chain_:SetActive(true)

		if length == 2 then
			self.bg_gou3:SetActive(false)
			self.gou3:SetActive(false)

			self.quest_chain_.transform.localPosition.x = self.bg_gou3.transform.localPosition.x
		end

		local i = 1

		while length >= i do
			if i < index then
				self.gou[i - 1 + 1]:SetActive(true)
			else
				self.gou[i - 1 + 1]:SetActive(false)
			end

			i = i + 1
		end
	else
		self.chain_:SetActive(false)
		self.quest_chain_:SetActive(false)
	end
end

function QuestComponent:setStar(val)
	self._starCost = val
	self.num_.text = tostring(val)
	self.num_acc.text = tostring(val)
end

function QuestComponent:setTime(val)
	if val <= 0 then
		self.time_:SetActive(false)

		return
	else
		self.time_:SetActive(true)

		self.time_.text = xyd.secondsNoHourToTimeString(val)
	end
end

function QuestComponent:dispose()
	if self._timer then
		self._timer:Stop()
	end
end

function QuestComponent:playDagouEffect(finishedID, nextQuestIDs)
	xyd.QuestController.get():increaseActionCount()
	XYDCo.WaitForTime(40 * xyd.TweenDeltaTime, function ()
		xyd.QuestController.get():decreaseActionCount()
	end, nil)
	DBResManager.get():newEffect(self.group_quest_, EffectConstants.QUEST_COMPLETE_CHECK, function (success, eff)
		if success then
			local start = self.btn_start_.transform.localPosition
			local scale = self.bg_start.transform.localScale.x
			eff.transform.localPosition = Vector3(start.x + self.bg_start.width / 2 * scale, start.y - self.bg_start.height / 2 * scale, 0)
			eff.transform.localScale = Vector3(100, 100, 100)
			local animComponent = eff:GetComponent(typeof(DragonBones.UnityArmatureComponent))
			animComponent.renderTarget = self.effectTarget
			animComponent.sortingOrder = 1
			local effAnimation = animComponent.animation

			effAnimation:Play("texiao01", 1)

			local onComplete = nil

			local function remove()
				animComponent:RemoveDBEventListener("complete", onComplete)
			end

			function onComplete()
				remove()
				effAnimation:Stop()
				Destroy(eff)
				xyd.EventDispatcher:inner():dispatchEvent({
					name = xyd.event.REMOVE_QUEST_VIEW,
					params = {
						finishedID = finishedID,
						nextQuestIDs = nextQuestIDs
					}
				})
			end

			animComponent:AddDBEventListener("complete", onComplete)

			return
		end

		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.REMOVE_QUEST_VIEW,
			params = {
				finishedID = finishedID,
				nextQuestIDs = nextQuestIDs
			}
		})
	end)
end

function QuestComponent:playChainDagouEffect(isLast)
	local questInfo = QuestTable:getTableDataByQuestID(self._questID)

	if questInfo.quest_chain_len <= 1 then
		return
	end

	local index = 1

	if isLast then
		index = 2
	else
		self.quest_chain_.text = "(" .. tostring(questInfo.quest_chain_index) .. "/" .. tostring(questInfo.quest_chain_len) .. ")"
	end

	local imgGou = self.gou[questInfo.quest_chain_index - index + 1]

	imgGou:SetActive(false)
	xyd.QuestController.get():increaseActionCount()
	XYDCo.WaitForTime(40 * xyd.TweenDeltaTime, function ()
		xyd.QuestController.get():decreaseActionCount()
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.CHECK_QUEST_REWARD
		})
	end, "")
	DBResManager.get():newEffect(self.chain_, EffectConstants.QUEST_COMPLETE_CHECK, function (success, eff)
		if success then
			local start = self.btn_start_.transform.localPosition
			local scale = self.bg_start.transform.localScale.x
			eff.transform.localPosition = Vector3(imgGou.transform.localPosition.x + 23, imgGou.transform.localPosition.y - 21, 0)
			eff.transform.localScale = Vector3(70, 70, 70)
			local animComponent = eff:GetComponent(typeof(DragonBones.UnityArmatureComponent))
			animComponent.renderTarget = self.effectTarget
			local effAnimation = animComponent.animation

			effAnimation:Play("texiao01", 1)

			local onComplete = nil

			local function remove()
				animComponent:RemoveDBEventListener("complete", onComplete)
			end

			function onComplete()
				remove()
				effAnimation:Stop()
				Destroy(eff)
				imgGou:SetActive(true)
			end

			animComponent:AddDBEventListener("complete", onComplete)

			return
		end

		imgGou:SetActive(true)
	end)
end

function QuestComponent:playRemoveEffect(finishedID, nextQuestIDs)
	xyd.QuestController.get():increaseActionCount()
	XYDCo.WaitForTime(15 * xyd.TweenDeltaTime, function ()
		xyd.QuestController.get():decreaseActionCount()
	end, "")

	local tw = DG.Tweening.DOTween.Sequence()

	local function setter(value)
		self.group_quest_widget.color = value
	end

	local function getter()
		return self.group_quest_widget.color
	end

	local tw = DG.Tweening.DOTween.Sequence()

	tw:Append(self.group_quest_.transform:DOLocalMoveX(self.group_quest_.transform.localPosition.x + 45, 0.1))
	tw:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.6, 0.1))
	tw:Append(self.group_quest_.transform:DOLocalMoveX(self.group_quest_.transform.localPosition.x - 405, 0.2))
	tw:Insert(0.1, DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0.2))
	tw:AppendCallback(function ()
		self.window:SetActive(false)
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.ACTIVE_QUEST_VIEW,
			params = {
				finishedID = finishedID,
				nextQuestIDs = nextQuestIDs
			}
		})
	end)
end

function QuestComponent:playUpEffect(id, nextQuestIDs)
	local count = 1

	for ____TS_index = 1, #nextQuestIDs do
		local nextQuestID = nextQuestIDs[____TS_index]

		if tonumber(nextQuestID) < id then
			count = count - 1
		end
	end

	if count <= 0 then
		return
	end

	xyd.QuestController.get():decreaseActionCount()
	XYDCo.WaitForTime(15 * xyd.TweenDeltaTime, function ()
		xyd.QuestController.get():decreaseActionCount()
	end, "")

	local sequence = DG.Tweening.DOTween.Sequence()
	local y = self.window.transform.localPosition.y

	sequence:Append(self.window.transform:DOLocalMoveY(y - 20, 0.1))
	sequence:Append(self.window.transform:DOLocalMoveY(y + 200, 0.1))
end

function QuestComponent:playActiveEffect()
	local tw = DG.Tweening.DOTween.Sequence()

	local function setter(value)
		self.group_quest_widget.color = value
	end

	local function getter()
		return self.group_quest_widget.color
	end

	local tw = DG.Tweening.DOTween.Sequence()
	self.group_quest_.transform.localScale = Vector3(0.5, 0.5, 1)
	self.group_quest_widget.alpha = 0

	tw:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.2))
	tw:Insert(0, self.group_quest_.transform:DOScale(Vector3(1, 1, 1), 0.2))
	tw:AppendCallback(function ()
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.CHECK_QUEST_REWARD
		})
	end)
end

function QuestComponent:onTapQuestBubble()
	local quest = xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST):getQuestViewByID(self._questID)

	if not quest then
		return
	end

	if quest.state == QuestConstants.ACTIVE then
		local last_time = QuestTable:getLastTimeByQuestID(self._questID)

		if last_time > 0 then
			self:_onTapBtnAccelerate()
		else
			self:_onTapBtnStart()
		end
	elseif quest.state == QuestConstants.COMPLETE then
		self:_onTapBtnComplete()
	end
end

function QuestComponent:onTapTimeRing()
	local quest = xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST):getQuestViewByID(self._questID)

	if not quest then
		return
	end

	if quest.state == QuestConstants.COMPLETE then
		self:_onTapBtnComplete()
	end
end

return QuestComponent
