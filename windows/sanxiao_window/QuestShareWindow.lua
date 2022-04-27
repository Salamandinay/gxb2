local QuestShareWindow = class("QuestShareWindow", import(".BaseWindow"))
local QuestTable = xyd.tables.quest
local MappingData = xyd.MappingData

function QuestShareWindow:ctor(name, params)
	QuestShareWindow.super.ctor(self, name, params)

	self._usingTimelines = {}
	self._needShowTimer = false
	self._status = -1
	self.AVATAR_WIDTH = 154
	self._isRequesting = false
	self._questModel = xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST)
	self.questId = params.questId

	if params.needShowTimer == true then
		self._needShowTimer = params.needShowTimer
	end

	xyd.EventDispatcher.outer():addEventListener("QUEST_SPEED_UP", handler(self, self.onQuestSpeedUp))
end

function QuestShareWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_all = winTrans:NodeByName("e:Skin/group_all").gameObject
	self.guide_area = winTrans:NodeByName("guide_area").gameObject
	self.group_close = winTrans:ComponentByName("e:Skin/group_all/group_close", typeof(UISprite))
	self.group_share = winTrans:NodeByName("e:Skin/group_all/group_share").gameObject
	self.diamond_num_ = winTrans:ComponentByName("e:Skin/group_all/group_share/diamond_num_", typeof(UILabel))
	self._name_ = winTrans:ComponentByName("e:Skin/group_all/name_", typeof(UILabel))
	self.desc_ = winTrans:ComponentByName("e:Skin/group_all/desc_", typeof(UILabel))
	self.time_ = winTrans:ComponentByName("e:Skin/group_all/group_time/time_", typeof(UILabel))
	self.accelerate_ = winTrans:ComponentByName("e:Skin/group_all/group_share/accelerate_", typeof(UILabel))
	self.clock_icon = winTrans:ComponentByName("e:Skin/group_all/group_time/clock_icon", typeof(UISprite))
end

function QuestShareWindow:initWindow()
	QuestShareWindow.super.initWindow(self)
	self:getUIComponent()

	local questModel = xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST)
	local quest = questModel:getQuestByID(self.questId)

	self:setDisplay(quest)
	self:initUIComponent()
	self:checkGuide()
end

function QuestShareWindow:checkGuide()
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.CHECK_HOME_GUIDE,
		params = {
			target_name = "group_share",
			container_name = "quest_share_window",
			quest_id = tonumber(self.questId),
			target = self.group_share,
			container = self.guide_area
		}
	})
end

function QuestShareWindow:setDisplay(data)
	xyd.setUISpriteAsync(self.clock_icon, MappingData.icon_shizhong, "icon_shizhong")

	local questInfo = QuestTable:getTableDataByQuestID(self.questId)
	local nameTransInfo = __(questInfo.name)
	local descTransInfo = __(questInfo.desc)
	self.accelerate_.text = __("ACCELERATE")
	self._name_.text = nameTransInfo
	self.desc_.text = descTransInfo
	self.endTime = data.endTime

	self:_timerCallback()
	self:_initTimer()
end

function QuestShareWindow:updateQuest(data)
	local quest = self._questModel:getQuestByID(self.questId)

	if quest ~= nil then
		quest.state = data.state
		quest.endTime = data.end_time
	end

	xyd.EventDispatcher:inner():dispatchEventWith(xyd.event.REPAIR_CHANGE_TIME, false, {
		questID = self.questId
	})
end

function QuestShareWindow:_initTimer()
	if not self._timer then
		self._timer = Timer.New(handler(self, self._timerCallback), 1, -1)
	end

	self._timer:Start()
end

function QuestShareWindow:_timerCallback()
	local cd = self.endTime - xyd.SelfInfo.get():getTime()

	if cd > 0 then
		local price = xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST).diamondPrice

		self:setTime(cd)

		self.diamond_num_.text = tostring(math.ceil(cd / 60) * price)
	else
		if self._timer then
			self._timer:Stop()

			self._timer = nil
		end

		xyd.WindowManager.get():closeWindow("quest_share_window")
	end
end

function QuestShareWindow:setTime(time)
	local timestr = xyd.secondsNoHourToTimeString(time)
	self.time_.text = timestr
end

function QuestShareWindow:_onTapBtnClose()
	if self._isRequesting then
		return
	end

	self:close()
end

function QuestShareWindow:_onTapBtnShare()
	if self._isRequesting then
		return
	end

	self._isRequesting = true

	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.CLOSE_HOME_GUIDE
	})
	xyd.DataPlatform.get():request("QUEST_SPEED_UP", {
		quest_id = self.questId
	})
end

function QuestShareWindow:onQuestSpeedUp(event)
	local data = event.data

	if data.status and data.status == 0 then
		local questModel = xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST)
		local quest = questModel:getQuestByID(self.questId)
		quest.endTime = data.server_time

		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.REPAIR_CHANGE_TIME,
			params = {
				questID = self.questId
			}
		})

		self._isRequesting = false

		self:_onTapBtnClose()
	elseif data.status and data.status == 1 then
		self._isRequesting = false
	else
		self:showFailedTips(data.status)
	end
end

function QuestShareWindow:showFailedTips(status)
end

function QuestShareWindow:initUIComponent()
	self:setDefaultBgClick(function ()
		self:_onTapBtnClose()
	end)
	xyd.setNormalBtnBehavior(self.group_close.gameObject, self, self._onTapBtnClose)
	xyd.setNormalBtnBehavior(self.group_share.gameObject, self, self._onTapBtnShare)
	xyd.SoundManager.get():playEffect("room_web1/se_room_countdown")
end

function QuestShareWindow:didClose(params)
	if self._needShowTimer then
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.SET_TIMER_RING_VISIBLE,
			params = {
				isPlayingClickAction = false,
				visible = true
			}
		})
	end

	QuestShareWindow.super.didClose(self, params)
end

function QuestShareWindow:dispose()
	xyd.EventDispatcher.outer():removeEventListenersByEvent("QUEST_SPEED_UP")

	if self._timer then
		self._timer:Stop()

		self._timer = nil
	end

	XYDCo.WaitForTime(5 * xyd.TweenDeltaTime, function ()
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.CHECK_UI_DISPLAY
		})
	end, "")
	QuestShareWindow.super.dispose(self)
end

function QuestShareWindow:close()
	if xyd.MapController.get().isInHomeGuide and tonumber(self.questId) == xyd.QuestConstants.FIRST_NEED_TIME_QUEST then
		return
	end

	QuestShareWindow.super.close(self)
end

return QuestShareWindow
