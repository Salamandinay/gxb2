local BaseWindow = import(".BaseWindow")
local DatesStoryWindow = class("DatesStoryWindow", BaseWindow)
local DatesStoryItem = class("DatesStoryItem", import("app.common.ui.FixedMultiWrapContentItem"))
local PartnerAchievementTable = xyd.tables.partnerAchievementTable

function DatesStoryWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.tableID = params.tableID
end

function DatesStoryWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function DatesStoryWindow:getUIComponent()
	local winTran = self.window_.transform
	local groupAction = winTran:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	local scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("itemList", typeof(MultiRowWrapContent))
	local item = groupAction:NodeByName("item").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent, item, DatesStoryItem, self)
end

function DatesStoryWindow:registerEvent()
	self:register()
	self.eventProxy_:addEventListener(xyd.event.COMPLETE_PARTNER_ACHIEVEMENT, handler(self, self.onComplete))
end

function DatesStoryWindow:layout()
	self:initData()
end

function DatesStoryWindow:initData(isUpdate)
	local achievements = xyd.tables.partnerTable:getAchievementIDs(self.tableID)
	local data = {}
	local achievementData = xyd.models.achievement:getPartnerAchievement(self.tableID)
	local index = xyd.arrayIndexOf(achievements, achievementData.table_id)

	for i = 1, #achievements do
		local id = achievements[i]
		local plot_id = PartnerAchievementTable:getPlotID(id)
		local state = "complete"

		if index < i then
			state = "lock"
		elseif i == index and achievementData.is_complete == 0 then
			state = "unlock"
		end

		local params = {
			plot_id = plot_id,
			achievement_id = id,
			state = state,
			achievement = achievementData
		}

		table.insert(data, params)
	end

	self.collection = data
	local params = {}

	if isUpdate then
		params.keepPosition = true
	end

	dump(data)
	self.multiWrap_:setInfos(data, params)
end

function DatesStoryWindow:onComplete()
	self:initData(true)
end

function DatesStoryItem:ctor(go, parent)
	DatesStoryItem.super.ctor(self, go, parent)
end

function DatesStoryItem:initUI()
	DatesStoryItem.super.initUI(self)
	self:getUIComponent()
	self:layout()
end

function DatesStoryItem:getUIComponent()
	self.lock = self.go:NodeByName("lock").gameObject
	self.labelText01 = self.lock:ComponentByName("labelText01", typeof(UILabel))
	self.labelLock = self.lock:ComponentByName("labelLock", typeof(UILabel))
	self.labelTitle = self.go:ComponentByName("labelTitle", typeof(UILabel))
	self.imgRedMark = self.go:NodeByName("imgRedMark").gameObject
	self.progress = self.go:ComponentByName("progress", typeof(UISlider))
	self.progressLabel = self.progress:ComponentByName("labelDisplay", typeof(UILabel))
	self.imgPlay = self.go:NodeByName("imgPlay").gameObject

	for i = 1, 3 do
		self["bg" .. i] = self.go:ComponentByName("bg" .. i, typeof(UISprite))
	end

	self.stateObj = {
		self.lock,
		self.progress,
		self.labelTitle,
		self.imgPlay
	}
end

function DatesStoryItem:registerEvent()
	UIEventListener.Get(self.go).onClick = function ()
		if self.data.state == "lock" then
			return
		end

		if self.data.state == "unlock" and self.data.is_complete == 0 then
			xyd.showToast(__("DATES_TEXT20"))

			return
		end

		if self.data.achievement_id == self.data.achievement.table_id and self.data.achievement.is_complete == 1 and self.data.achievement.is_reward == 0 then
			xyd.models.achievement:completePartnerAchievement(self.data.achievement_id)
		end

		if self.data.state == "complete" then
			xyd.WindowManager:get():openWindow("story_window", {
				story_id = self.data.plot_id,
				achievement_id = self.data.achievement_id,
				story_type = xyd.StoryType.PARTNER
			})
		end
	end
end

function DatesStoryItem:layout()
	self.labelText01.text = __("DATES_TEXT14")
	self.labelLock.text = __("DATES_TEXT15")
end

function DatesStoryItem:updateInfo()
	self:updateState()

	local prefix = nil

	if self.data.state == "complete" then
		prefix = PartnerAchievementTable:getIcon(self.data.achievement_id)
		self.labelTitle.text = xyd.tables.partnerPlotTextTable:getTitle(self.data.plot_id)
	elseif self.data.state == "lock" then
		prefix = "dates_icon37_"
	elseif self.data.state == "unlock" then
		prefix = "dates_icon36_"
		self.labelTitle.text = xyd.tables.partnerAchievementTextTable:getDesc(self.data.achievement_id)
		local missionType = PartnerAchievementTable:getType(self.data.achievement_id)
		local maximum, curVal = nil

		if missionType == xyd.PartnerAchievementType.LovePoint then
			maximum = PartnerAchievementTable:getCompleteValue(self.data.achievement_id) / 100
			curVal = self.data.achievement.count / 100
		else
			maximum = PartnerAchievementTable:getCompleteValue(self.data.achievement_id)
			curVal = self.data.achievement.count
		end

		self.progress.value = curVal / maximum
		self.progressLabel.text = curVal .. "/" .. maximum
	end

	for i = 1, 3 do
		local bg = self["bg" .. tostring(i)]
		local str = prefix .. i

		xyd.setUISpriteAsync(bg, nil, str, function ()
			if not tolua.isnull(bg) then
				bg:MakePixelPerfect()
			end
		end)
	end

	local redMark = self.data.achievement_id == self.data.achievement.table_id and self.data.achievement.is_complete == 1 and self.data.achievement.is_reward == 0

	self.imgRedMark:SetActive(redMark)
end

function DatesStoryItem:updateState()
	self.currentState = self.data.state
	local arry = {
		1,
		1,
		1,
		1
	}

	if self.currentState == "complete" then
		arry = {
			0,
			0,
			1,
			1
		}
	elseif self.currentState == "lock" then
		arry = {
			1,
			0,
			0,
			0
		}
	elseif self.currentState == "unlock" then
		arry = {
			0,
			1,
			1,
			0
		}
	end

	for i = 1, #self.stateObj do
		self.stateObj[i]:SetActive(arry[i] == 1)
	end
end

return DatesStoryWindow
