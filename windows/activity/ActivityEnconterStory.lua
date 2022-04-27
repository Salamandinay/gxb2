local ActivityEnconterStory = class("ActivityEnconterStory", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")

function ActivityEnconterStory:ctor(parentGO, params, parent)
	ActivityEnconterStory.super.ctor(self, parentGO, params, parent)
	dump(self.activityData.detail)
end

function ActivityEnconterStory:getPrefabPath()
	return "Prefabs/Windows/activity/activity_enconter_story"
end

function ActivityEnconterStory:initUI()
	ActivityEnconterStory.super.initUI(self)
	self:getUIComponent()
	self:updatePos()
	self:layout()
	self:updateItemNum()
	self:register()
end

function ActivityEnconterStory:updatePos()
	local realHeight = xyd.Global.getRealHeight()

	self.missionGroup:Y(-108 - 0.3089887640449438 * (realHeight - 1280))
	self.fightBtn.transform:Y(-771 - 0.898876404494382 * (realHeight - 1280))
	self.bgImg_:Y(84 - 0.47191011235955055 * (realHeight - 1280))

	for i = 1, 5 do
		self["missionItem" .. i].transform:Y(self["missionItem" .. i].transform.localPosition.y - (i - 1) * 14 / 178 * (realHeight - 1280))
	end
end

function ActivityEnconterStory:getUIComponent()
	local goTrans = self.go.transform
	self.bgImg_ = goTrans:NodeByName("bgImg")
	self.helpBtn = goTrans:NodeByName("topGroup/helpBtn").gameObject
	self.costLabel = goTrans:ComponentByName("topGroup/iconGroup/labelNum", typeof(UILabel))
	self.plusBtn = goTrans:NodeByName("topGroup/iconGroup/plusBtn").gameObject
	self.missionGroup = goTrans:NodeByName("missionGroup")

	for i = 1, 5 do
		self["missionItem" .. i] = self.missionGroup:NodeByName("missionItem" .. i).gameObject
		self["missionLabel" .. i] = self.missionGroup:ComponentByName("missionItem" .. i .. "/labelDesc", typeof(UILabel))
		self["missionRed" .. i] = self.missionGroup:NodeByName("missionItem" .. i .. "/redPoint").gameObject
		self["missionMask" .. i] = self.missionGroup:NodeByName("missionItem" .. i .. "/lockImg").gameObject
		self["missionType" .. i] = self.missionGroup:ComponentByName("missionItem" .. i .. "/iconType", typeof(UISprite))

		UIEventListener.Get(self["missionItem" .. i]).onClick = function ()
			self:onClickMission(i)
		end
	end

	self.fightBtn = goTrans:NodeByName("fightBtn").gameObject
	self.fightBtnLabel = goTrans:ComponentByName("fightBtn/label", typeof(UILabel))
	self.fightBtnRed = goTrans:NodeByName("fightBtn/redPoint").gameObject
end

function ActivityEnconterStory:updateItemNum()
	self.costLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ENCONTER_STORY)
end

function ActivityEnconterStory:layout()
	self.fightBtnLabel.text = __("ACTIVITY_ENCOUNTER_STORY_TEXT05")

	self:updateMissionState()
	self:updateFightRed()
end

function ActivityEnconterStory:updateFightRed()
	self.fightBtnRed:SetActive(self.activityData:getFightRed() or self.activityData:getRedPointStar())
end

function ActivityEnconterStory:updateMissionState(id)
	local startNum = 1
	local endNum = 5

	if id then
		startNum = id
		endNum = id
	end

	for i = startNum, endNum do
		local type_ = xyd.tables.activityEnconterStoryTable:getType(i)
		local cost = xyd.tables.activityEnconterStoryTable:getCost(i)

		if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) and self.activityData.detail.plots[i] == 0 then
			self["missionRed" .. i]:SetActive(true)
		else
			self["missionRed" .. i]:SetActive(false)
		end

		local text_id = xyd.tables.activityEnconterStoryTable:getTextID(i)

		if type_ == 1 then
			self["missionLabel" .. i].text = xyd.tables.activityEncounterStoryTextTable:getTitle(text_id)
		else
			self["missionLabel" .. i].text = xyd.tables.storyTextTable:getTitle(text_id)
		end

		xyd.setUISpriteAsync(self["missionType" .. i], nil, "activity_enconter_story_icon" .. type_, nil, , true)

		local is_unLock = self.activityData.detail.plots[i]

		if not is_unLock or is_unLock == 0 then
			self["missionMask" .. i]:SetActive(true)
		else
			self["missionMask" .. i]:SetActive(false)
		end
	end
end

function ActivityEnconterStory:register()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_ENCOUNTER_STORY_HELP"
		})
	end

	UIEventListener.Get(self.fightBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_enconter_story_fight_window", {})
	end

	UIEventListener.Get(self.plusBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_enconter_story_fight_window", {})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onUpdateActivityInfo))
	self:registerEvent(xyd.event.ENCOUNTER_UNLOCK_PLOT, handler(self, self.unLockPlotBack))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateFightRed))
end

function ActivityEnconterStory:onUpdateActivityInfo(event)
	if event.data.activity_id == xyd.ActivityID.ENCONTER_STORY then
		self:updateFightRed()
		self:fightBack()
	end
end

function ActivityEnconterStory:onClickMission(index)
	print("測試點擊了", index)

	local type = xyd.tables.activityEnconterStoryTable:getType(index)
	local text_id = xyd.tables.activityEnconterStoryTable:getTextID(index)
	local is_unLock = self.activityData.detail.plots[index]

	if not is_unLock or is_unLock == 0 then
		local cost = xyd.tables.activityEnconterStoryTable:getCost(index)
		local num = cost[2]
		local name = xyd.tables.itemTable:getName(cost[1])

		xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_ENCOUNTER_STORY_TEXT01", num, name), function (yes_no)
			if yes_no then
				local hasNum = xyd.models.backpack:getItemNumByID(cost[1])

				if hasNum < num then
					xyd.alertTips(__("NOT_ENOUGH", name))
				else
					local msg = messages_pb:encounter_unlock_plot_req()
					msg.activity_id = self.id
					msg.table_id = index

					xyd.Backend.get():request(xyd.mid.ENCOUNTER_UNLOCK_PLOT, msg)
				end
			end
		end)

		return
	end

	self:showPlot(text_id, type)
end

function ActivityEnconterStory:showPlot(text_id, type)
	if type == 1 then
		xyd.WindowManager.get():openWindow("activity_enconter_story_explain_window", {
			text_id = text_id
		})
	elseif type == 2 then
		local storyId = text_id

		xyd.WindowManager.get():openWindow("story_window", {
			is_back = true,
			story_type = xyd.StoryType.ACTIVITY,
			story_id = storyId
		})
	end
end

function ActivityEnconterStory:unLockPlotBack(event)
	local data = xyd.decodeProtoBuf(event.data)
	local type = xyd.tables.activityEnconterStoryTable:getType(data.table_id)
	local text_id = xyd.tables.activityEnconterStoryTable:getTextID(data.table_id)

	self:showPlot(text_id, type)
	self:updateItemNum()
	self:updateMissionState()
end

function ActivityEnconterStory:fightBack()
	self:updateItemNum()
	self:updateMissionState()
end

return ActivityEnconterStory
