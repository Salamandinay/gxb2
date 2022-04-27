local MapWindow = class("MapWindow", import(".BaseWindow"))
local BuildingTable = xyd.tables.building
local BuildingGroupTable = xyd.tables.buildingGroup
local StoryConstants = xyd.StoryConstants
local QuestConversationComponent = import("app.components.QuestConversationComponent")
local ConversationComponent = import("app.components.ConversationComponent")
local NewQuestComponent = import("app.components.NewQuestComponent")
local RandomActionController = import("app.controllers.RandomActionController")
local QuestChangeBuildingComponent = import("app.components.QuestChangeBuildingComponent")
local BuildingsChangeDressComponent = import("app.components.BuildingsChangeDressComponent")
local RandomActionController = import("app.controllers.RandomActionController")
local MapDebugComponent = import("app.windows.MapDebugComponent")
local EditPetComponent = import("app.components.EditPetComponent")
local EditNameComponent = import("app.components.EditNameComponent")
local ShowLetterComponent = import("app.components.ShowLetterComponent")
local DBResManager = xyd.DBResManager
local CityMap = xyd.CityMap
local QuestController = xyd.QuestController
local SelfInfo = xyd.SelfInfo
local Destroy = UnityEngine.Object.Destroy
local QuestTable = xyd.tables.quest
local Screen = UnityEngine.Screen
local ActivityConstants = xyd.ActivityConstants
local HEAD_WIDTH = 14.6

function MapWindow:ctor(name, params)
	MapWindow.super.ctor(self, name, params)

	if params ~= nil then
		self.mapType = params.mapType
		self._nickName = params.nickName
		self._avatar = params.avatar
		self._uin = params.uin
		self._backFromFriendHome = params.backFromFriendHome
		self._conversationScale = xyd.BUBBLE_CONVERSATION_SCALE
	end

	self.playerInfoModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYER_INFO)
end

function MapWindow:initWindow()
	MapWindow.super.initWindow(self)
	self:initMembers()
	self:getUIComponent()
	self:initUIComponent()
end

function MapWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_task_core = winTrans:NodeByName("e:Skin/icon_group/group_task/group_task_core").gameObject
	self.snow_man = winTrans:ComponentByName("e:Skin/icon_group/group_task/group_task_core/snow_man", typeof(UISprite))
	self.setting_btn = winTrans:NodeByName("e:Skin/icon_group/setting_btn_group/setting_btn").gameObject
	self.group_sound_bg = winTrans:NodeByName("e:Skin/icon_group/setting_btn_group/group_sound_bg").gameObject
	self.group_sound_effect = winTrans:NodeByName("e:Skin/icon_group/setting_btn_group/group_sound_effect").gameObject
	self.group_question = winTrans:NodeByName("e:Skin/icon_group/setting_btn_group/group_question").gameObject
	self.group_exit = winTrans:NodeByName("e:Skin/icon_group/setting_btn_group/group_exit").gameObject
	self.bg_shezhi = winTrans:NodeByName("e:Skin/icon_group/setting_btn_group/bg_shezhi").gameObject
	self._currentLevelNumPic = winTrans:ComponentByName("e:Skin/icon_group/group_start/_currentLevelNumPic", typeof(UILabel))
	self._starNumPic = winTrans:ComponentByName("e:Skin/icon_group/group_task/group_star/_starNumPic", typeof(UILabel))
	self._settingBgGroup = winTrans:NodeByName("e:Skin/_settingBgGroup").gameObject
	self.icon_group = winTrans:NodeByName("e:Skin/icon_group").gameObject
	self._touchMask = winTrans:NodeByName("e:Skin/_touchMask").gameObject
	self.conversation_group = winTrans:NodeByName("e:Skin/conversation_group").gameObject
	self.newtask_group = winTrans:NodeByName("e:Skin/newtask_group").gameObject
	self.other_player_home_group = winTrans:NodeByName("e:Skin/other_player_home_group").gameObject
	self.debug_text = winTrans:NodeByName("e:Skin/debug_text").gameObject
	self.bubble_conversation_group = winTrans:NodeByName("e:Skin/bubble_conversation_group").gameObject
	self.group_task = winTrans:NodeByName("e:Skin/icon_group/group_task").gameObject
	self.setting_btn_group = winTrans:NodeByName("e:Skin/icon_group/setting_btn_group").gameObject
	self.stage_group = winTrans:NodeByName("e:Skin/icon_group/stage_group").gameObject
	self.group_start = winTrans:NodeByName("e:Skin/icon_group/group_start").gameObject
	self.group_start_bg = winTrans:ComponentByName("e:Skin/icon_group/group_start/group_start_bg", typeof(UISprite))
	self.sound_bg_disable = self.group_sound_bg:NodeByName("sound_bg_disable").gameObject
	self.sound_eff_disable = self.group_sound_effect:NodeByName("sound_eff_disable").gameObject
	self.friend_info_group = winTrans:NodeByName("e:Skin/other_player_home_group/friend_info_group").gameObject
	self.btn_add = winTrans:NodeByName("e:Skin/other_player_home_group/btn_add").gameObject
	self.btn_back = winTrans:NodeByName("e:Skin/other_player_home_group/btn_back").gameObject
	self.quest_tip_ = winTrans:ComponentByName("e:Skin/icon_group/group_task/group_task_core/quest_tip_", typeof(UISprite))
	self.guide_area = winTrans:NodeByName("guide_area").gameObject
	self.longpress_guide_target = winTrans:NodeByName("longpress_guide_target").gameObject
	self.stamina_group = winTrans:NodeByName("e:Skin/icon_group/stamina_group").gameObject
	self.stamina_num = self.stamina_group.transform:ComponentByName("stamina_num", typeof(UILabel))
	self.stamina_time = self.stamina_group.transform:ComponentByName("stamina_time", typeof(UILabel))
	self.stamina_full = self.stamina_group.transform:ComponentByName("stamina_full", typeof(UILabel))
	self.stamina_icon = self.stamina_group.transform:ComponentByName("stamina_icon", typeof(UISprite))
	self.stamina_add = self.stamina_group.transform:NodeByName("stamina_add").gameObject
	self.stamina_inf = self.stamina_group.transform:NodeByName("stamina_inf").gameObject
	self.dark_mask = winTrans:ComponentByName("e:Skin/dark_mask", typeof(UITexture))
	self.gem_group = winTrans:NodeByName("e:Skin/icon_group/gem_group").gameObject
	self.gem_num = self.gem_group.transform:ComponentByName("gem_num", typeof(UILabel))
	self.gem_icon = self.gem_group.transform:ComponentByName("gem_icon", typeof(UISprite))
	self.gem_add = self.gem_group.transform:NodeByName("gem_add").gameObject
	self.activity_group = winTrans:NodeByName("e:Skin/icon_group/activity_group").gameObject
	self.black_mask_widget = winTrans:ComponentByName("e:Skin/icon_group/black_mask", typeof(UIWidget))
	local baseBitmap = winTrans:NodeByName("basebitmap").gameObject
	local baseGroup = winTrans:NodeByName("basegroup").gameObject

	xyd.ViewResManager.get():initTemplate({
		compSprite = baseBitmap,
		compWidget = baseGroup
	})
end

function MapWindow:initMembers()
	self._settingCanTouch = true
	self._settingState = 0
	self._currentLevel = 0
	self._starNum = 0
	self._changeDressComponent = nil
	self._selfBuildingGroupModel = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_BUILDING_GROUP)
	self._isMoving = false
	self._isPlayingStory = false
	self._gotFirstStoryFinishedEvent = false
	self.lastX = 0
	self.lastY = 0
	self._talkingCharId = 0
	self.cannotChangeUIState = false
	self.cameraManager = xyd.CameraManager.get()
	self._currentLevel = xyd.SelfInfo.get():getCurrentLevel()
	self.mapWindowIconAnimator = import("app.components.MapWindowIconAnimator").new(self)
	self._showingStory = false
	self._showingNewQuest = false
	self._showingCharBubble = false
	self._showingAction = false
	self._newQuestComponents = {}
	self._questConversationComponent = nil
	self._conversationComponent = nil
	self._changeBuildingCompoent = nil
	self._closeConversationComponentTimer = nil
end

function MapWindow:initUIComponent()
	self.dark_mask:SetActive(false)
	self:_initCurrentLevel()
	xyd.setDarkenBtnBehavior(self.group_task_core, self, self._onTask)
	xyd.setDarkenBtnBehavior(self.group_start, self, self._onBtnStart)
	xyd.setDarkenBtnBehavior(self.setting_btn, self, self._onSetting)
	xyd.setDarkenBtnBehavior(self._settingBgGroup, self, self._onSetting)
	xyd.setDarkenBtnBehavior(self.group_sound_bg, self, self.onSoundBg)
	xyd.setDarkenBtnBehavior(self.group_sound_effect, self, self.onSoundEffect)
	xyd.setDarkenBtnBehavior(self.group_question, self, self.onBtnQuestion)
	xyd.setDarkenBtnBehavior(self.group_exit, self, self.onBtnExit)

	if xyd.SHOP_ON then
		xyd.setDarkenBtnBehavior(self.gem_group, self, self.onGemAddClick)
		self.gem_add:SetActive(true)
	end

	xyd.setDarkenBtnBehavior(self.stamina_group, self, self.onStaminaAddClick)
	self:updateStaminaNum()
	self:updateGemNum()
	self:initStaminaTime()
	self:registerEvents()
	self:updateStarNum()
	self:initSetting()
	self:initDebugComponent()
	self:initActivities()
	self.mapWindowIconAnimator:init()
end

function MapWindow:registerEvents()
	self.eventProxy_:addEventListener(xyd.event.MAP_WINDOW_PLAY_STORY_FINISHED, handler(self, self._storyFinished))
	self.eventProxy_:addEventListener(xyd.event.SHOW_STORY, handler(self, self._showStory))
	self.eventProxy_:addEventListener(xyd.event.HIDE_STORY, handler(self, self._hideStory))
	self.eventProxy_:addEventListener(xyd.event.HIDE_AND_REMOVE_TOUCH, handler(self, self._hideAndCanNotTouch))
	self.eventProxy_:addEventListener(xyd.event.SHOW_AND_ENABLE_TOUCH, handler(self, self._showAndCanTouch))
	self.eventProxy_:addEventListener(xyd.event.UPDATE_CHANGE_DRESS_UI, handler(self, self._updateChangeDressUI))
	self.eventProxy_:addEventListener(xyd.event.BUILDING_CHANGE_DRESS_VIEW, handler(self, self._buildingChangeDress))
	self.eventProxy_:addEventListener(xyd.event.POPUP_CHAGNE_BUILDING_COMPONENT, handler(self, self._popupChangeBuildingComponent))
	self.eventProxy_:addEventListener(xyd.event.SHOW_QUEST_ICON, handler(self, self._showQuestIcon))
	self.eventProxy_:addEventListener(xyd.event.CLOSE_NEW_QUEST, handler(self, self._closeNewQuestUI))
	self.eventProxy_:addEventListener(xyd.event.CHECK_UI_DISPLAY, handler(self, self.checkUIDisplay))
	self.eventProxy_:addEventListener(xyd.event.CHECK_SHOW_QUEST_TIP, handler(self, self._checkShowQuestTip))
	self.eventProxy_:addEventListener(xyd.event.SET_MOVE_ACTION, handler(self, self._setMoveAction))
	self.eventProxy_:addEventListener(xyd.event.QUEST_STORY_SKIP, handler(self, self._onSkipStory))
	self.eventProxy_:addEventListener(xyd.event.UPDATE_TEXT_POS, handler(self, self._updateTextPos))
	self.eventProxy_:addEventListener(xyd.event.QUEST_DIALOG, handler(self, self._showConversationComponent))
	self.eventProxy_:addEventListener(xyd.event.UPDATE_GEM_NUM, handler(self, self.updateGemNum))
	self.eventProxy_:addEventListener(xyd.event.UPDATE_STAR_NUM, handler(self, self.updateStarNum))
	self.eventProxy_:addEventListener(xyd.event.UPDATE_STAMINA_NUM, handler(self, self.updateStaminaNum))
	self.eventProxy_:addEventListener(xyd.event.UPDATE_STAMINA_TIME, handler(self, self.updateStaminaTime))
	self.eventProxy_:addEventListener(xyd.event.HIDE_ICON, handler(self, self._hideIcon))
end

function MapWindow:_onBtnStart()
	xyd.dispatchEventByFrontEnd(xyd.event.HANDLE_LONG_PRESS_END)
	xyd.dispatchEventByFrontEnd(xyd.event.UPDATE_TEXT_POS)
	xyd.SoundManager.get():playEffect("Common/se_button")

	local playerInfoModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYER_INFO)

	if playerInfoModel:hasStamina() then
		xyd.WindowManager.get():openWindow("pre_game_window", {
			totalLevel = self._currentLevel
		})
	else
		xyd.WindowManager.get():openWindow("stamina_window")
	end
end

function MapWindow:_onTask()
	if not self:checkCanTouch() then
		return
	end

	xyd.dispatchEventByFrontEnd(xyd.event.HANDLE_LONG_PRESS_END)
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.CLOSE_HOME_GUIDE
	})
	xyd.WindowManager:get():openWindow("quest_window")
end

function MapWindow:_onSetting()
	xyd.SoundManager.get():playEffect("Common/se_button")
	xyd.dispatchEventByFrontEnd(xyd.event.HANDLE_LONG_PRESS_END)
	xyd.WindowManager.get():openWindow("setting_window")
end

function MapWindow:onSoundEffect()
	local soundMgr = xyd.SoundManager.get()
	local bg = soundMgr:getIsSoundOn()

	if bg then
		soundMgr:setIsSoundOn(false)
		self.sound_eff_disable:SetActive(false)
	else
		soundMgr:setIsSoundOn(true)
		self.sound_eff_disable:SetActive(true)
	end
end

function MapWindow:onSoundBg()
	local soundMgr = xyd.SoundManager.get()
	local bg = soundMgr:getIsMusicOn()

	if bg then
		soundMgr:setIsMusicOn(false)
		self.sound_bg_disable:SetActive(false)
	else
		soundMgr:setIsMusicOn(true)
		self.sound_bg_disable:SetActive(true)
	end
end

function MapWindow:onBtnQuestion()
end

function MapWindow:onBtnExit()
	xyd.SoundManager.get():playEffect("Common/se_button")

	if UNITY_EDITOR or UNITY_STANDALONE then
		local function callback()
			xyd.WindowManager.get():openWindow("stage_window")
		end

		xyd.MapController.get():closeMap(callback)
	end
end

function MapWindow:_initCurrentLevel()
	self._currentLevelNumPic.text = self._currentLevel
end

function MapWindow:initSetting()
end

function MapWindow:updateStarNum()
	self._starNum = xyd.SelfInfo.get():get_star()
	self._starNumPic.text = self._starNum

	self:_checkShowQuestTip()
end

function MapWindow:checkCanTouch()
	if self._isPlayingStory or xyd.QuestController.get().isRequesting then
		return false
	end

	return true
end

function MapWindow:_storyFinished(event)
	self:setCanTouchMap(true)
	self:_setIconGroupVisible(true)

	if xyd.WindowManager.get():getWindow("quest_share_window") or self._changeDressComponent and self._changeDressComponent._isDuringChanging or self._changeBuildingCompoent and self._changeBuildingCompoent._isDuringChanging then
		self:_setIconGroupVisible(false)
	end

	self:closeQuestConversationUI()

	if not self._gotFirstStoryFinishedEvent then
		self._gotFirstStoryFinishedEvent = true
	elseif event.params and event.params.story then
		local questID = event.params.story.questID

		self:_checkActionOfQuest(questID)
	end

	if event.params.story then
		self:checkBuildingGuide(event.params.story.questID)
	end

	if event.params and event.params.story and event.params.story.storyId == StoryConstants.FIRST_QUEST_STORY_ID then
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.CHECK_HOME_GUIDE,
			params = {
				target_name = "group_task_core",
				container_name = "map_window",
				quest_id = tonumber(event.params.story.mission[1]),
				target = self.group_task_core,
				container = self.guide_area
			}
		})
	end
end

function MapWindow:setCanTouchMap(val)
	self.cameraManager:setEnabled(val)
end

function MapWindow:_showStory(event)
	self.storyQuestData = event.params

	self:showQuestConversationUI()
end

function MapWindow:showQuestConversationUI()
	if not xyd.QuestController:get().isPlayingClickAction and not RandomActionController.get().isPlayingRandomAction then
		self:_setIconGroupVisible(false)
	end

	local missions = {}

	if type(self.storyQuestData.story.mission) == "number" then
		missions = {
			self.storyQuestData.story.mission
		}
	else
		missions = self.storyQuestData.story.mission
	end

	if self.storyQuestData.story.guess_story and #self.storyQuestData.story.guess_story > 1 then
		self:closeQuestConversationUI(function ()
			local GuessStoryComponent = import("app.components.GuessStoryComponent")

			GuessStoryComponent.new(self.conversation_group, self.storyQuestData.story)
		end)
	elseif self.storyQuestData.story.position == StoryConstants.CONVERSATION_POSITION_BUBBLE or self.storyQuestData.story.position == StoryConstants.CONVERSATION_POSITION_BUBBLE_OPPOSITE then
		self:closeQuestConversationUI()

		self._showingCharBubble = true
		local bubbleHandler = xyd.QuestBubbleHandler.get()
		local timerRingHandler = xyd.TimerRingHandler.get()

		if (not self.storyQuestData.isRandom or not bubbleHandler or not bubbleHandler.bubbleOnChar) and (not self.storyQuestData.isRandom or not timerRingHandler or not timerRingHandler.timerOnChar) then
			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.QUEST_DIALOG,
				params = {
					data = self.storyQuestData,
					isRandom = self.storyQuestData.isRandom
				}
			})
		end
	elseif self.storyQuestData.story.position == StoryConstants.CONVERSATION_POSITION_EDIT_NAME then
		self:closeQuestConversationUI(function ()
			EditNameComponent.new(self.conversation_group)
		end)
	elseif self.storyQuestData.story.position == StoryConstants.CONVERSATION_POSITION_EDIT_PET then
		self:closeQuestConversationUI(function ()
			EditPetComponent.new(self.conversation_group)
		end)
	elseif self.storyQuestData.story.position == StoryConstants.CONVERSATION_POSITION_LETTER then
		self:closeQuestConversationUI(function ()
			ShowLetterComponent.new(self.conversation_group, self.storyQuestData.story)
		end)
	else
		if self._questConversationComponent == nil then
			self._questConversationComponent = QuestConversationComponent.new(self.conversation_group, self.storyQuestData.story)
		elseif self._questConversationComponent.isClosingAnimation then
			if not tolua.isnull(self._questConversationComponent.conversation.transform.parent) then
				self._questConversationComponent:dispose()

				self._questConversationComponent = nil
				self._questConversationComponent = QuestConversationComponent.new(self.conversation_group, self.storyQuestData.story)
			end
		elseif self._questConversationComponent.isClosingEffect and not tolua.isnull(self._questConversationComponent.conversation.transform.parent) then
			self._questConversationComponent:dispose()

			self._questConversationComponent = nil
			self._questConversationComponent = QuestConversationComponent.new(self.conversation_group, self.storyQuestData.story)
		end

		self._questConversationComponent:playStory(self.storyQuestData)
	end

	self:_showNewQuestUI(missions)
end

function MapWindow:closeQuestConversationUI(callback)
	if self._questConversationComponent then
		self._questConversationComponent:clearUIEventListener()

		local function callback()
			if not tolua.isnull(self._questConversationComponent.conversation.transform.parent) then
				self._questConversationComponent:dispose()

				self._questConversationComponent = nil
			end
		end

		self._questConversationComponent:UICloseAnimation(callback)
		self:_closeNewQuestUI()
	end

	if callback then
		callback()
	end
end

function MapWindow:_showNewQuestUI(questIds)
	for i = 1, #questIds do
		local questId = tonumber(questIds[i])

		if questId ~= nil and questId > 0 and questId ~= xyd.FINAL_QUEST then
			if self._newQuestComponents[i] == nil then
				self._newQuestComponents[i] = NewQuestComponent.new(self.newtask_group.gameObject, questId, i - 1)
			end

			self._showingNewQuest = true
		end
	end
end

function MapWindow:showNewDayAnimation(callback)
	DBResManager.get():newEffect(self.window_, "text_new_day", function (success, eff)
		if success then
			if self._isDisposed then
				DBResManager.get():pushEffect(eff)

				return
			end

			if self._newDayEffect then
				DBResManager.get():pushEffect(eff)

				self._newDayEffect = nil
			end

			eff.transform.localPosition = Vector3(0, 200, 0)
			eff.transform.localScale = Vector3(100, 100, 100)
			local animComponent = eff:GetComponent(typeof(DragonBones.UnityArmatureComponent))
			local effAnimation = animComponent.animation

			effAnimation:Play("texiao01", 1)

			local onComplete = nil

			local function remove()
				animComponent:RemoveDBEventListener("complete", onComplete)
			end

			function onComplete()
				remove()
				DBResManager.get():pushEffect(eff)

				self._newDayEffect = nil

				callback()
			end

			self._newDayEffect = eff

			animComponent:AddDBEventListener("complete", onComplete)

			return
		end

		if callback then
			callback()
		end
	end)
end

function MapWindow:_hideStory()
	self:closeQuestConversationUI()
end

function MapWindow:_hideAndCanNotTouch()
	self:setCanTouchMap(false)
	self:_setIconGroupVisible(false)
end

function MapWindow:_showAndCanTouch()
	self:setCanTouchMap(true)
	self:_setIconGroupVisible(true)
end

function MapWindow:_updateChangeDressUI(event)
	if event.params.needCloseUI then
		if self._changeDressComponent then
			self._changeDressComponent:onCancelByClickOnMap()
		end

		return
	end

	self:_setIconGroupVisible(false)

	local buildingGroupID = event.params.buildingGroupID
	local buildingGroupTblInfos = BuildingGroupTable:getAllBuildingGroups()
	local buildingGroupTblInfo = buildingGroupTblInfos[buildingGroupID]
	local buildingGroupInfo = self._selfBuildingGroupModel:getBuildingGroupInfoByID(buildingGroupID)
	local currentID = buildingGroupInfo:getDressID()
	local sorceIcons = buildingGroupTblInfo.dress_icon
	local sorceNames = buildingGroupTblInfo.dress_name

	if self._changeDressComponent then
		self._changeDressComponent.changeDressComponent:SetActive(true)
		self._changeDressComponent:init()
	else
		local dressAndBuildingComponent = self.window_.transform:NodeByName("building_change_dress")

		if dressAndBuildingComponent then
			self._changeDressComponent = BuildingsChangeDressComponent.new(self.window_, dressAndBuildingComponent)

			self._changeDressComponent.changeDressComponent:SetActive(true)
		else
			self._changeDressComponent = BuildingsChangeDressComponent.new(self.window_, dressAndBuildingComponent)
			local panel = self._changeDressComponent.changeDressComponent:GetComponent(typeof(UIRect))

			panel:SetAnchor(self.window_)
			panel:SetTopAnchor(self.window_, 0, 500)
		end
	end

	self._changeDressComponent:setDisplay(buildingGroupID, sorceIcons, sorceNames, currentID, xyd.BUILDING_ANIMATION_TYPE_NORMAL)
end

function MapWindow:_closeChangeDressUI()
	if self._changeDressComponent then
		self._changeDressComponent:destroyIcons()
		self._changeDressComponent.changeDressComponent:SetActive(false)
	end

	self:_setIconGroupVisible(true)
end

function MapWindow:_buildingChangeDress(event)
	local needCloseChangeDressUI = event.params.needChangeMapState

	if needCloseChangeDressUI then
		self:_closeChangeDressUI()
	end
end

function MapWindow:_popupChangeBuildingComponent(event)
	self:_removeChangeBuildingComponent()
	self:_setIconGroupVisible(false)

	local oldGroupID = event.params.oldGroupID
	local newGroupID = event.params.newGroupID
	local questID = event.params.questID
	local animationType = event.params.animationType
	local cancelCallback = event.params.cancelCallback
	local confirmCallback = event.params.confirmCallback

	local function removeSelfCallback()
		self:_removeChangeBuildingComponent()
	end

	local buildingGroupTblInfos = BuildingGroupTable:getAllBuildingGroups()
	local buildingGroupTblInfo = buildingGroupTblInfos[newGroupID]
	local buildingGroupInfo = self._selfBuildingGroupModel:getBuildingGroupInfoByID(newGroupID)
	local currentID = buildingGroupInfo:getDressID()
	local dressIcons = buildingGroupTblInfo.dress_icon
	local dressNames = buildingGroupTblInfo.dress_name

	if self._changeBuildingCompoent then
		self._changeBuildingCompoent.changeDressComponent:SetActive(true)
		self._changeBuildingCompoent:init()
		self._changeBuildingCompoent:updateData(cancelCallback, confirmCallback, removeSelfCallback, questID)
	else
		local dressAndBuildingComponent = self.window_.transform:NodeByName("building_change_dress")

		if dressAndBuildingComponent then
			self._changeBuildingCompoent = QuestChangeBuildingComponent.new(self.window_, cancelCallback, confirmCallback, removeSelfCallback, questID, dressAndBuildingComponent)

			self._changeBuildingCompoent.changeDressComponent:SetActive(true)
		else
			self._changeBuildingCompoent = QuestChangeBuildingComponent.new(self.window_, cancelCallback, confirmCallback, removeSelfCallback, questID, dressAndBuildingComponent)
			local panel = self._changeBuildingCompoent.changeDressComponent:GetComponent(typeof(UIRect))

			panel:SetAnchor(self.window_)
			panel:SetTopAnchor(self.window_, 0, 500)
		end
	end

	self._changeBuildingCompoent:setOldBuildingID(oldGroupID)
	self._changeBuildingCompoent:setDisplay(newGroupID, dressIcons, dressNames, currentID, animationType, oldGroupID)
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.CHECK_HOME_GUIDE,
		params = {
			target_name = "_changeBuildingCompoent",
			container_name = "map_window",
			quest_id = questID,
			target = self._changeBuildingCompoent.group_all,
			container = self.guide_area
		}
	})
end

function MapWindow:_removeChangeBuildingComponent()
	if self._changeBuildingCompoent then
		self._changeBuildingCompoent:destroyIcons()
		self._changeBuildingCompoent.changeDressComponent:SetActive(false)
	end
end

function MapWindow:_showQuestIcon()
	if self.cannotChangeUIState then
		return
	end

	self.icon_group:SetActive(false)
	self:_checkShowQuestTip()
end

function MapWindow:_setIconGroupVisible(isVisible)
	if self.cannotChangeUIState then
		return
	end

	if xyd.WindowManager.get():getWindow("quest_window") then
		isVisible = false
	end

	self:_checkShowQuestTip()
	self.icon_group:SetActive(isVisible)
end

function MapWindow:_closeNewQuestUI()
	self._showingCharBubble = false

	for i = 1, #self._newQuestComponents do
		if self._newQuestComponents[i] and not self._newQuestComponents[i].isClosingAnimation then
			local function callback()
				if self._newQuestComponents[i] == nil then
					return
				end

				if not tolua.isnull(self._newQuestComponents[i].gameObjectNode.transform.parent) then
					Destroy(self._newQuestComponents[i].gameObjectNode)
				end

				self._newQuestComponents[i]:dispose()

				self._newQuestComponents[i] = nil
				local hasNonCompleteNewQuestComp = false

				for i = 1, #self._newQuestComponents do
					if self._newQuestComponents[i] then
						hasNonCompleteNewQuestComp = true

						break
					end
				end

				if hasNonCompleteNewQuestComp == false then
					self._showingNewQuest = false
				end
			end

			self._newQuestComponents[i]:UICloseAnimation(callback)
		end
	end
end

function MapWindow:checkUIDisplay()
	if self.mapType == xyd.MapType.FriendHomeMap then
		self:_setIconGroupVisible(false)

		return
	end

	local startLayerType = 3
	local numSubWindow = 0

	for layerType = startLayerType, 4 do
		local layer = xyd.WindowManager:get():getUILayer(layerType)

		if not tolua.isnull(layer) then
			numSubWindow = numSubWindow + layer.transform.childCount

			if layerType == 4 and xyd.WindowManager.get():isOpen("loading_component") then
				numSubWindow = numSubWindow - 1
			end
		end
	end

	if numSubWindow > 0 or self._questConversationComponent and self._questConversationComponent.transform and self._questConversationComponent.transform.parent then
		self:_setIconGroupVisible(false)

		return
	end

	self:_setIconGroupVisible(true)
end

function MapWindow:_checkShowQuestTip()
	local curQuestsView = xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST):getCurQuestsView()

	self.quest_tip_:SetActive(false)

	for idStr, _ in pairs(curQuestsView) do
		local quest = curQuestsView[idStr]
		local questInfo = QuestTable:getTableDataByQuestID(quest.id)

		if quest.state == xyd.QuestConstants.ACTIVE and questInfo.star <= SelfInfo.get():get_star() and quest.id ~= xyd.FINAL_QUEST or quest.state == xyd.QuestConstants.STARTED and quest.endTime <= SelfInfo.get():getTime() or xyd.QuestConstants.COMPLETE <= quest.state then
			self.quest_tip_:SetActive(true)

			break
		end
	end
end

function MapWindow:_setMoveAction(event)
	self._isMoving = event.params.moving
end

function MapWindow:getMoveAction()
	return self._isMoving
end

function MapWindow:_onSkipStory(event)
	self._questActionState = StoryConstants.ACTION_NONE

	if event.params and event.params.story then
		local questID = event.params.story.questID

		self:_checkActionOfQuest(questID)
	end
end

function MapWindow:_checkActionOfQuest(questID)
	local questModel = xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST)
	local quest = questModel:getQuestByID(questID)

	if not quest then
		print("tolua.isnull(quest)")

		return
	end

	local buildingGroupID = QuestTable:getNewBuildingIDByQuestID(questID)

	if quest ~= nil and quest.state == 1 then
		xyd.WindowManager.get():openWindow("quest_share_window", {
			needShowTimer = true,
			questId = quest.id
		})
	end
end

function MapWindow:_updateTextPos()
	print(self.name_ .. "ppp")
end

function MapWindow:hideSetting()
	self._settingBgGroup:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Insert(0, self.group_sound_bg.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y, 10 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, self.group_sound_effect.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y, 10 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, self.group_question.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y, 10 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, self.group_exit.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y, 10 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, self.bg_shezhi.transform:DOScaleY(0, 10 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear):OnComplete(function ()
		self.bg_shezhi:SetActive(false)
	end))

	local function getter()
		return self.bg_shezhi:GetComponent(typeof(UISprite)).color
	end

	local function setter(value)
		self.bg_shezhi:GetComponent(typeof(UISprite)).color = value
	end

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 10 * xyd.TweenDeltaTime))
	sequence:AppendCallback(function ()
		self.group_sound_bg:SetActive(false)
		self.group_sound_effect:SetActive(false)
		self.group_question:SetActive(false)
		self.group_exit:SetActive(false)

		self._settingCanTouch = true
	end)
end

function MapWindow:showSetting()
	self._settingBgGroup:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

	self.group_sound_bg:SetActive(true)
	self.group_sound_effect:SetActive(true)
	self.group_question:SetActive(true)
	self.group_exit:SetActive(true)

	self.bg_shezhi:GetComponent(typeof(UIWidget)).alpha = 0.33
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Insert(0, self.group_sound_bg.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 160, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(0, self.group_sound_effect.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 320, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(0, self.group_question.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 480, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(0, self.group_exit.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 640, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(6 * xyd.TweenDeltaTime, self.group_sound_bg.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 150, 9 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(6 * xyd.TweenDeltaTime, self.group_sound_effect.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 300, 9 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(6 * xyd.TweenDeltaTime, self.group_question.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 450, 9 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(6 * xyd.TweenDeltaTime, self.group_exit.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 600, 9 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(0, self.bg_shezhi.transform:DOScaleY(1.07, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad):OnComplete(function ()
		self.bg_shezhi:SetActive(true)
	end))
	sequence:Insert(6 * xyd.TweenDeltaTime, self.bg_shezhi.transform:DOScaleY(1, 9 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))

	local function getter()
		return self.bg_shezhi:GetComponent(typeof(UISprite)).color
	end

	local function setter(value)
		self.bg_shezhi:GetComponent(typeof(UISprite)).color = value
	end

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 2 * xyd.TweenDeltaTime))
	sequence:AppendCallback(function ()
		self._settingCanTouch = true
	end)
end

function MapWindow:updateBubbleConversation(pos, isUpdateArrow)
	local orthographicSize = self.cameraManager:getOrthographicSize()
	local rate = self.cameraManager:getCameraRate()
	local cameraScale = orthographicSize / rate
	local offsetX = HEAD_WIDTH / cameraScale
	local offsetY = CityMap.get():getCharDefaultHeight() / cameraScale
	local rateX = Screen.width / xyd.STANDARD_WIDTH
	local rateY = xyd.STANDARD_HEIGHT / Screen.height
	local rate = rateX * rateY
	local changingHeight = xyd.STANDARD_HEIGHT / rate
	local screenPos = self.cameraManager:worldToScreenPoint(pos)
	local bubbleWidth, bubbleHeight, arrowHeight = self._conversationComponent:getWidthAndHeight()
	local adjustArrowHeight = arrowHeight - 10
	local x = (screenPos.x - Screen.width / 2) * xyd.STANDARD_WIDTH / Screen.width + offsetX + bubbleWidth / 2 - 25
	local y = (screenPos.y - Screen.height / 2) * changingHeight / Screen.height + offsetY + bubbleHeight / 2
	local arrowOffsetX = 0
	local isTop = false
	local leftBorderX = bubbleWidth / 2 - xyd.STANDARD_WIDTH / 2
	local rightBorderX = xyd.STANDARD_WIDTH / 2 - bubbleWidth / 2
	local downBorderY = bubbleHeight / 2 + adjustArrowHeight - changingHeight / 2
	local upBorderY = changingHeight / 2 - bubbleHeight / 2

	if rightBorderX < x then
		arrowOffsetX = x - rightBorderX
	end

	if y > upBorderY + offsetY / 2 then
		isTop = true
		upBorderY = upBorderY - adjustArrowHeight
	end

	local finalX = Mathf.Clamp(x, leftBorderX, rightBorderX)
	local finalY = Mathf.Clamp(y, downBorderY, upBorderY)

	self._conversationComponent:updatePos(finalX, finalY)

	if isUpdateArrow then
		self._conversationComponent:setArrowPos(isTop, arrowOffsetX)
	end
end

function MapWindow:_showConversationComponent(event)
	local storyQuestData = event.params.data
	local isRandom = event.params.isRandom or false

	if self._conversationComponent then
		if QuestController.get().isPlayingClickAction and self._conversationComponent.conversation then
			return
		end

		self._conversationComponent:dispose()

		self._conversationComponent = nil
	end

	if self._closeConversationComponentTimer then
		XYDCo.StopWait(self._closeConversationComponentTimer)

		self._closeConversationComponentTimer = nil
	end

	self._conversationComponent = ConversationComponent.new(self.bubble_conversation_group.gameObject, storyQuestData.story.position)

	self._conversationComponent:playStory(storyQuestData)

	if storyQuestData.story.char_id ~= nil and storyQuestData.story.char_id > 0 then
		self._talkingCharId = storyQuestData.story.char_id
	else
		self._talkingCharId = CityMap.get().MyCharID
	end

	local char = CityMap.get()._allChars[self._talkingCharId]
	local pos = nil

	if char then
		pos = char:getPos3D()
	else
		local temp = self.cameraManager:gridToWorldPoint(Vector2(CityMap.get():getMyCharX(), CityMap.get().getMyCharY()))
		pos = Vector3(temp.x, temp.y, CityMap.get().getMyCharZ())
	end

	if pos == nil then
		self:closeConversationComponent(false)
	end

	self:updateBubbleConversation(pos, false)
	UpdateBeat:Add(self._followConversationComponent, self)
	XYDCo.WaitForTime(3, function ()
		self._closeConversationComponentTimer = "closeConversationComponentTimer"

		self:closeConversationComponent(not isRandom)
	end, "closeConversationComponentTimer")
end

function MapWindow:_followConversationComponent()
	if self._conversationComponent then
		local char = CityMap.get()._allChars[self._talkingCharId]
		local pos = nil

		if char then
			pos = char:getPos3D()
		else
			local temp = self.cameraManager:gridToWorldPoint(Vector2(CityMap.get():getMyCharX(), CityMap.get().getMyCharY()))
			pos = Vector3(temp.x, temp.y, CityMap.get().getMyCharZ())
		end

		if pos == nil then
			UpdateBeat:Remove(self._followConversationComponent, self)

			return
		end

		self:updateBubbleConversation(pos, true)
	end
end

function MapWindow:closeConversationComponent(needPlayNext)
	if self._conversationComponent then
		local function callback()
			UpdateBeat:Remove(self._followConversationComponent, self)

			if self._conversationComponent == nil then
				return
			end

			if not tolua.isnull(self._conversationComponent.conversation) then
				Destroy(self._conversationComponent.conversation)

				self._conversationComponent.conversation = nil
			end

			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.CLOSE_NEW_QUEST,
				params = {}
			})

			if needPlayNext then
				self._conversationComponent:playNextStory()
			end
		end

		self._conversationComponent:UICloseAnimation(callback)
	end
end

function MapWindow:dispose()
	UpdateBeat:Remove(self._followConversationComponent, self)

	if self._changeDressComponent then
		self._changeDressComponent:dispose()

		self._changeDressComponent = nil
	end

	if self._closeConversationComponentTimer then
		XYDCo.StopWait(self._closeConversationComponentTimer)

		self._closeConversationComponentTimer = nil
	end

	if self._conversationComponent then
		self._conversationComponent:dispose()

		self._conversationComponent = nil
	end

	if self._changeBuildingCompoent then
		self._changeBuildingCompoent:dispose()

		self._changeBuildingCompoent = nil
	end

	if self._mapDebugComponent then
		self._mapDebugComponent:dispose()

		self._mapDebugComponent = nil
	end

	if self.mapWindowIconAnimator then
		self.mapWindowIconAnimator:dispose()

		self.mapWindowIconAnimator = nil
	end

	for k, v in pairs(self.activity_component) do
		v:dispose()
	end

	self.activity_component = {}

	MapWindow.super.dispose(self)
end

function MapWindow:checkBuildingGuide(questID)
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.CHECK_HOME_GUIDE,
		params = {
			target_name = "building_sprite",
			container_name = "map_window",
			quest_id = questID,
			target = self.longpress_guide_target,
			container = self.guide_area
		}
	})
end

function MapWindow:isChangeBuilding()
	local res = false

	if self._changeDressComponent and self._changeDressComponent._isDuringChanging then
		res = true
	end

	if self._changeBuildingCompoent and self._changeBuildingCompoent._isDuringChanging then
		res = true
	end

	return res
end

function MapWindow:initDebugComponent()
	if UNITY_EDITOR or UNITY_STANDALONE or XYD_TEST or XYDUtils.IsTest() then
		if not self._mapDebugComponent then
			self._mapDebugComponent = MapDebugComponent.new(self.icon_group)
		end
	else
		self._mapDebugComponent = nil
	end
end

function MapWindow:checkValidChar()
	local char = CityMap.get()._allChars[self._talkingCharId]

	if char == nil or char.charSprite_ == nil or tolua.isnull(char.Sprite_._model3D) then
		UpdateBeat:Remove(self._followConversationComponent, self)

		return false
	end

	return true
end

function MapWindow:onGemAddClick()
	if xyd.WindowManager.get():getWindow("shop_window") then
		return
	end

	xyd.WindowManager.get():openWindow("shop_window")
end

function MapWindow:onStaminaAddClick()
	if xyd.WindowManager.get():getWindow("stamina_window") then
		return
	end

	xyd.WindowManager.get():openWindow("stamina_window")
end

function MapWindow:updateStaminaTime(event)
	if self.isDisposed_ then
		return
	end

	local stamina_num = xyd.SelfInfo.get():getStamina()

	if event.data.is_inf_stamina then
		self.stamina_time:SetActive(true)
		self.stamina_inf:SetActive(true)
		self.stamina_full:SetActive(false)
		self.stamina_num:SetActive(false)

		self.stamina_time.text = xyd.secondsToString(event.data.inf_time)
	else
		self.stamina_num:SetActive(true)
		self.stamina_inf:SetActive(false)

		if stamina_num < 5 then
			self.stamina_time.text = xyd.secondsToString(event.data.normal_time)

			self.stamina_time:SetActive(true)
			self.stamina_full:SetActive(false)
		else
			self.stamina_time:SetActive(false)
			self.stamina_full:SetActive(true)
		end
	end
end

function MapWindow:updateStaminaNum()
	if self.isDisposed_ then
		return
	end

	local stamina_num = xyd.SelfInfo.get():getStamina()
	self.stamina_num.text = tostring(stamina_num)
end

function MapWindow:updateGemNum()
	if self.isDisposed_ then
		return
	end

	local gem_num = xyd.SelfInfo.get():getGems()
	self.gem_num.text = tostring(gem_num)
end

function MapWindow:initStaminaTime()
	local stamina_time = self.playerInfoModel:getStaminaTime()
	local stamina_num = xyd.SelfInfo.get():getStamina()

	if stamina_num < 5 then
		self.stamina_time.text = xyd.secondsToString(stamina_time)

		self.stamina_time:SetActive(true)
		self.stamina_full:SetActive(false)
	else
		self.stamina_time:SetActive(false)
		self.stamina_full:SetActive(true)
	end
end

function MapWindow:addAvatar()
end

function MapWindow:_hideIcon()
	self:_setIconGroupVisible(false)
end

function MapWindow:darkMaskShow(callback)
	self.dark_mask:SetActive(true)

	self.dark_mask.alpha = 0

	local function setter(value)
		self.dark_mask.color = value
	end

	local function getter()
		return self.dark_mask.color
	end

	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.3))
	sequence:AppendCallback(function ()
		if callback then
			callback()
		end
	end)
	self:setGreyEffect(true)
end

function MapWindow:darkMaskHide(callback)
	self.dark_mask:SetActive(true)

	self.dark_mask.alpha = 1

	local function setter(value)
		self.dark_mask.color = value
	end

	local function getter()
		return self.dark_mask.color
	end

	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0.3))
	sequence:AppendCallback(function ()
		self.dark_mask:SetActive(false)

		if callback then
			callback()
		end
	end)
	self:setGreyEffect(false)
end

function MapWindow:setGreyEffect(onoff)
	local ngui = UnityEngine.GameObject.FindWithTag("Ngui")
	local uiCamera = ngui:ComponentByName("UICamera", typeof(UnityEngine.Camera))
	local greyEffect = uiCamera:GetComponent(typeof(GreyEffect))
	greyEffect.enabled = onoff
end

function MapWindow:initActivities()
	self.activity_component = {}
	local model = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITY)
	local ActivityTable = xyd.tables.activity

	for name, id in pairs(ActivityConstants) do
		if type(id) == "number" and model:isOpen(id) and ActivityConstants.Entry[id] then
			self.activity_component[id] = import(ActivityConstants.Entry[id]).new(self.activity_group, id)
		end
	end

	self:syncActivityPosition()
end

function MapWindow:syncActivityPosition()
	local group = self.activity_group:GetComponent(typeof(UIWidget))
	local y = -group.height / 2

	for id, component in pairs(self.activity_component) do
		y = y + 15 + component.height / 2
		component._gameObject.transform.localPosition = Vector3(0, y, 0)
		y = y + component.height / 2 + 5
	end
end

return MapWindow
