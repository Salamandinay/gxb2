local ArcticExpeditionTimeWindow = class("ArcticExpeditionTimeWindow", import(".BaseWindow"))
local ArcTicMissionItem = class("ArcTicMissionItem", import("app.components.CopyComponent"))
local navStatus = {
	choose = {
		labelColor = Color.New2(4294967295.0),
		labelEffectColor = Color.New2(1012112383)
	},
	unchoose = {
		labelColor = Color.New2(960513791),
		labelEffectColor = Color.New2(4294967295.0)
	}
}

function ArcTicMissionItem:ctor(goItem, parent)
	self.parent_ = parent

	ArcTicMissionItem.super.ctor(self, goItem)
end

function ArcTicMissionItem:initUI()
	ArcTicMissionItem.super.initUI(self)
	self:getUIComponent()
end

function ArcTicMissionItem:getUIComponent()
	local goTrans = self.go.transform
	self.nameLabel_ = goTrans:ComponentByName("nameLabel", typeof(UILabel))
	self.progressBar_ = goTrans:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel_ = goTrans:ComponentByName("progressBar/label", typeof(UILabel))
	self.scoreLabel_ = goTrans:ComponentByName("scoreLabel", typeof(UILabel))
	self.completeText_ = goTrans:ComponentByName("completeText", typeof(UILabel))
	self.completeNum_ = goTrans:ComponentByName("completeNum", typeof(UILabel))
	self.completeImg_ = goTrans:ComponentByName("completeImg", typeof(UISprite))
end

function ArcTicMissionItem:setInfo(id, data)
	self.timeMissionID_ = id
	self.nameLabel_.text = xyd.tables.arcticExpeditionEraTaskTable:getDesc(id)
	local completeValue = xyd.tables.arcticExpeditionEraTaskTable:getCompleteValue(id)
	self.scoreLabel_.text = xyd.tables.arcticExpeditionEraTaskTable:getScore(id)
	local value = data.value or 0
	local is_completed = data.is_completed or 0
	local limitTime = xyd.tables.arcticExpeditionEraTaskTable:getLimitTime(id)

	if is_completed and is_completed >= 1 and limitTime <= 1 then
		self.completeImg_.gameObject:SetActive(true)
		self.completeNum_.gameObject:SetActive(false)
		self.completeText_.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.completeImg_, nil, "mission_awarded_" .. xyd.Global.lang, nil, , true)

		self.progressBar_.value = 1
		self.progressLabel_.text = value .. "/" .. completeValue
	else
		self.completeImg_.gameObject:SetActive(false)
		self.completeNum_.gameObject:SetActive(true)
		self.completeText_.gameObject:SetActive(true)

		self.completeNum_.text = is_completed .. "/" .. limitTime
		self.completeText_.text = __("ACTIVITY_PRAY_COMPLETE")

		if limitTime <= is_completed then
			self.progressBar_.value = 1
			self.progressLabel_.text = completeValue .. "/" .. completeValue
		else
			self.progressBar_.value = math.fmod(value, completeValue) / completeValue
			self.progressLabel_.text = math.fmod(value, completeValue) .. "/" .. completeValue
		end
	end
end

function ArcticExpeditionTimeWindow:ctor(name, params)
	ArcticExpeditionTimeWindow.super.ctor(self, name, params)

	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)
	self.eraID_ = self.activityData_:getEra()
	self.chooseNav_ = self.eraID_
	self.missionItemList_ = {}
end

function ArcticExpeditionTimeWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:regisetr()
end

function ArcticExpeditionTimeWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.navGroup_ = winTrans:ComponentByName("navGroup", typeof(UILayout))

	for i = 1, 3 do
		self["nav" .. i] = self.navGroup_:ComponentByName("nav" .. i, typeof(UISprite))
		self["navNum" .. i] = self["nav" .. i].transform:ComponentByName("labelTime", typeof(UILabel))
		self["unchooseImg" .. i] = self["nav" .. i].transform:NodeByName("unchoose").gameObject
		self["lockImg" .. i] = self["nav" .. i].transform:NodeByName("lockImg").gameObject
		self["lockBg" .. i] = self["nav" .. i].transform:NodeByName("lockBg").gameObject
		self["labelText" .. i] = winTrans:ComponentByName("missionInfo/labelText" .. i, typeof(UILabel))
	end

	self.labelTips_ = winTrans:ComponentByName("timeInfo/labelTips", typeof(UILabel))
	self.progressBar_ = winTrans:ComponentByName("timeInfo/progressBar", typeof(UIProgressBar))
	self.progressBarLabel_ = winTrans:ComponentByName("timeInfo/progressBar/label", typeof(UILabel))
	self.labelTime_ = winTrans:ComponentByName("timeInfo/labelTime", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("missionInfo/scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("missionInfo/scrollView/grid", typeof(UILayout))
	self.missionItem_ = winTrans:NodeByName("missionInfo/missionItem").gameObject
	self.timeTexture_ = winTrans:ComponentByName("timeTexture", typeof(UITexture))
end

function ArcticExpeditionTimeWindow:regisetr()
	ArcticExpeditionTimeWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ARCTIC_EXPEDITION_HELP_ERA"
		})
	end

	for i = 1, 3 do
		UIEventListener.Get(self["nav" .. i].gameObject).onClick = function ()
			if self.chooseNav_ ~= i then
				if self.eraID_ < i then
					xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_21"))
				else
					self.chooseNav_ = i

					self:layout()
				end
			end
		end
	end
end

function ArcticExpeditionTimeWindow:updateNav()
	for i = 1, 3 do
		if i ~= self.chooseNav_ then
			self["unchooseImg" .. i]:SetActive(true)

			self["navNum" .. i].color = navStatus.unchoose.labelColor
			self["navNum" .. i].effectColor = navStatus.unchoose.labelEffectColor
		else
			self["unchooseImg" .. i]:SetActive(false)

			self["navNum" .. i].color = navStatus.choose.labelColor
			self["navNum" .. i].effectColor = navStatus.choose.labelEffectColor
		end

		if self.eraID_ < i then
			self["lockImg" .. i]:SetActive(true)
			self["lockBg" .. i]:SetActive(true)
			self["navNum" .. i].transform:X(20)

			self["navNum" .. i].width = 180
		else
			self["lockImg" .. i]:SetActive(false)
			self["lockBg" .. i]:SetActive(false)
			self["navNum" .. i].transform:X(0)

			self["navNum" .. i].width = 216
		end
	end
end

function ArcticExpeditionTimeWindow:layout()
	for i = 1, 3 do
		self["labelText" .. i].text = __("ARCTIC_EXPEDITION_TIME_MISSION_TEXT_" .. i)
		self["navNum" .. i].text = xyd.tables.arcticExpeditionEraTextTable:getName(i)
	end

	self.titleLabel_.text = __("ARCTIC_EXPEDITION_TIME_MISSION_TEXT_4")
	self.labelTips_.text = xyd.tables.arcticExpeditionEraTextTable:getDesc(self.chooseNav_)

	xyd.setUITextureByNameAsync(self.timeTexture_, "arctic_expedition_time_boss_bg" .. self.chooseNav_)

	if self.chooseNav_ < self.eraID_ then
		self.labelTime_.gameObject:SetActive(false)
		self.progressBar_.gameObject:SetActive(false)
	elseif self.activityData_:checkWillOpenNextStage() then
		self.labelTime_.gameObject:SetActive(true)
		self.progressBar_.gameObject:SetActive(false)

		local tomorrowTime = xyd.getTomorrowTime()
		local duration = tomorrowTime - xyd:getServerTime()
		local timeCount = import("app.components.CountDown").new(self.labelTime_)

		timeCount:setInfo({
			key = "ARCTIC_EXPEDITION_TIME_MISSION_TEXT_5",
			duration = duration,
			callback = function ()
				xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_19"))
			end
		})
	else
		self.labelTime_.gameObject:SetActive(false)
		self.progressBar_.gameObject:SetActive(true)

		local totalScore = 0
		local finishValue = 0
		local missionIds = xyd.tables.arcticExpeditionEraTaskTable:getIDsByEraID(self.eraID_)

		for index, id in ipairs(missionIds) do
			local missionData = self.activityData_:getTimeMissionInfo(id)
			local value = xyd.tables.arcticExpeditionEraTaskTable:getScore(id)
			local is_completed = missionData.is_completed
			totalScore = totalScore + value

			if is_completed and is_completed == 1 then
				finishValue = finishValue + value
			end

			self.progressBar_.value = finishValue / totalScore
			self.progressBarLabel_.text = finishValue .. "/" .. totalScore
		end
	end

	if self.eraID_ >= 3 then
		self.progressBar_.gameObject:SetActive(false)
	end

	local totalScoreNeed = xyd.tables.arcticExpeditionEraTaskTable:getTotalComVal(self.chooseNav_)
	local scoreNow = nil

	self:updateNav()
	self:refreshMissionList()
end

function ArcticExpeditionTimeWindow:refreshMissionList()
	local missionIds = xyd.tables.arcticExpeditionEraTaskTable:getIDsByEraID(self.chooseNav_)

	for index, id in ipairs(missionIds) do
		if not self.missionItemList_[id] then
			local newItem = NGUITools.AddChild(self.grid_.gameObject, self.missionItem_)
			self.missionItemList_[id] = ArcTicMissionItem.new(newItem)
		end

		self.missionItemList_[id]:SetActive(true)
		self.missionItemList_[id]:setInfo(id, self.activityData_:getTimeMissionInfo(id))
	end

	for id, item in pairs(self.missionItemList_) do
		if xyd.arrayIndexOf(missionIds, tonumber(id)) < 0 then
			item:SetActive(false)
		end
	end

	self.grid_:Reposition()
	self.scrollView_:ResetPosition()
end

return ArcticExpeditionTimeWindow
