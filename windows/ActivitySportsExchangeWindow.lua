local ActivitySportsExchangeWindow = class("ActivitySportsExchangeWindow", import(".BaseWindow"))
local ActivitySportsAchieveItem = class("ActivitySportsAchieveItem", import("app.components.CopyComponent"))
local ActivitySportsMissionItem = class("ActivitySportsMissionItem", import("app.components.CopyComponent"))
local CommonTabBar = import("app.common.ui.CommonTabBar")

function ActivitySportsExchangeWindow:ctor(name, params)
	ActivitySportsExchangeWindow.super.ctor(self, name, params)
end

function ActivitySportsExchangeWindow:initWindow()
	ActivitySportsExchangeWindow.super.initWindow(self)
	self:getComponent()
	self:initNav()
	self:registerEvent()

	self.winTitle_.text = __("ACTIVITY_SPORTS_EXCHANGE_WINDOW")
	self.noneLabel_.text = __("ACTIVITY_SPORTS_TEXT03")

	xyd.models.activity:reqActivityByID(xyd.ActivityID.SPORTS)
end

function ActivitySportsExchangeWindow:getComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.topBgImg_ = self.groupAction:ComponentByName("topBgImg", typeof(UISprite))
	self.winTitle_ = self.groupAction:ComponentByName("winTitle", typeof(UILabel))
	self.closeBtn_ = self.groupAction:NodeByName("closeBtn").gameObject
	self.navGroup = self.groupAction:NodeByName("navGroup").gameObject
	self.groupNone_ = self.groupAction:NodeByName("groupNone").gameObject
	self.noneLabel_ = self.groupAction:ComponentByName("groupNone/noneLabel", typeof(UILabel))
	self.itemRoot_ = self.groupAction:NodeByName("itemRoot").gameObject
	self.tastScrollView_ = self.groupAction:ComponentByName("tastScrollView", typeof(UIScrollView))
	self.contentTast_ = self.groupAction:ComponentByName("tastScrollView/content", typeof(MultiRowWrapContent))
	self.achievementScroll_ = self.groupAction:ComponentByName("achievementScroll", typeof(UIScrollView))
	self.contentAchieve_ = self.groupAction:ComponentByName("achievementScroll/content", typeof(MultiRowWrapContent))
	self.tastWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.tastScrollView_, self.contentTast_, self.itemRoot_, ActivitySportsMissionItem, self)
end

function ActivitySportsExchangeWindow:initNav()
	local colorParams = {
		chosen = {
			color = Color.New2(4294967295.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	}
	self.tab = CommonTabBar.new(self.navGroup, 2, function (index)
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:onTouch(index)
	end, nil, colorParams)
	local tableLabels = xyd.split(__("ACTIVITY_SPORTS_EXCHANGE_LABELS"), "|")

	self.tab:setTexts(tableLabels)
	self.tab:setTabActive(1, true)
end

function ActivitySportsExchangeWindow:registerEvent()
	ActivitySportsExchangeWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self.eventProxy_:addEventListener(xyd.event.ACTIVITY_INFO_BY_ID, handler(self, self.onGetInfo))

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivitySportsExchangeWindow:onGetInfo(event)
	local data = event.data

	if data.activity_id == xyd.ActivityID.SPORTS then
		self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPORTS)

		self.tab:getRedMark(1):SetActive(self.activityData:getMissionRed())
		self.tab:getRedMark(2):SetActive(self.activityData:getAchieveRed())
		self:initTask()
	end
end

function ActivitySportsExchangeWindow:onGetAward(event)
	local detail = require("cjson").decode(event.data.detail)
	local items = detail.items

	xyd.itemFloat(items, nil, , 6000)

	if detail.mission_id then
		self:initTask()
	else
		self:initAchieve(true)
	end
end

function ActivitySportsExchangeWindow:onTouch(index)
	self.tastScrollView_.gameObject:SetActive(index == 1)
	self.achievementScroll_.gameObject:SetActive(index == 2)

	local flag = false

	if index == 1 and self.activityData and self.activityData:isFinalDay() then
		flag = true
	end

	if index == 2 and not self.achieveWrap_ then
		self:initAchieve()
	end

	self.groupNone_:SetActive(flag)
end

function ActivitySportsExchangeWindow:initTask()
	if self.activityData:isFinalDay() then
		self.groupNone_:SetActive(true)

		return
	end

	local missionsList = {}
	local missions = xyd.tables.activitySportsMissionTable:getIds()
	local missionAward = self.activityData.detail.mission_awarded or {}
	local missionCount = self.activityData.detail.mission_count or {}
	local state = self.activityData:getNowState()

	for i = 1, #missions do
		local id = missions[i]

		if state == 2 or not xyd.tables.activitySportsMissionTable:isLimit(id) then
			local mission = {
				extra = 0,
				is_completed = 0,
				mission_id = id,
				is_awarded = missionAward[i],
				value = missionCount[i]
			}

			table.insert(missionsList, mission)
		end
	end

	self.tastWrap_:setInfos(missionsList, {})

	local state = self.activityData:getMissionRed()

	self.tab:getRedMark(1):SetActive(state)
end

function ActivitySportsExchangeWindow:getAchieveIDs()
	local achievements = xyd.tables.activitySportsAchievementTable:getIDs()
	local ids = {}
	local list = self.activityData.detail.achievement_list.achievements or {}
	local a_t = xyd.tables.activitySportsAchievementTable

	for _, item in ipairs(list) do
		local complete = a_t:getCompleteValue(item.achieve_id)

		if complete and item.achieve_id > 0 and complete <= item.value then
			table.insert(ids, item.achieve_id)
		end
	end

	self.tab:getRedMark(2):SetActive(#ids > 0)

	for i = 1, #achievements do
		local id = tonumber(achievements[i])

		if xyd.arrayIndexOf(ids, id) < 0 then
			table.insert(ids, id)
		end
	end

	return ids
end

function ActivitySportsExchangeWindow:initAchieve(keepPosition)
	if not self.achieveWrap_ then
		self.achieveWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.achievementScroll_, self.contentAchieve_, self.itemRoot_, ActivitySportsAchieveItem, self)
	end

	local achievements = self:getAchieveIDs()
	local achievementData = {}
	local a_t = xyd.tables.activitySportsAchievementTable

	for _, id in ipairs(achievements) do
		local type_ = a_t:getType(id)
		local achievement_info = self:getAchieveDataByType(type_)
		local complete_value = a_t:getCompleteValue(id)
		local desc = a_t:getDesc(type_, complete_value)
		local awards = a_t:getAward(id)

		table.insert(achievementData, {
			id = id,
			type_ = type_,
			achievement_info = achievement_info,
			complete_value = complete_value,
			desc = desc,
			awards = awards
		})
	end

	self.achieveWrap_:setInfos(achievementData, {
		keepPosition = keepPosition
	})

	local state = self.activityData:getAchieveRed()

	self.tab:getRedMark(2):SetActive(state)
end

function ActivitySportsExchangeWindow:getAchieveDataByType(type_)
	local list = self.activityData.detail.achievement_list.achievements
	local data = nil

	for i = 1, #list do
		if list[i].achieve_type == type_ then
			data = list[i]

			break
		end
	end

	return data
end

function ActivitySportsAchieveItem:ctor(parentGo, parent)
	self.parent_ = parent
	self.itemList_ = {}

	ActivitySportsAchieveItem.super.ctor(self, parentGo)
end

function ActivitySportsAchieveItem:initUI()
	ActivitySportsAchieveItem.super.initUI(self)
	self:getComponent()
	self:layout()
end

function ActivitySportsAchieveItem:getComponent()
	local goTrans = self.go.transform
	self.bgImg = goTrans:ComponentByName("bgImg", typeof(UIDragScrollView))
	self.missionDesc_ = goTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.itemGroup_ = goTrans:ComponentByName("itemGroup", typeof(UIGrid))
	self.btnAward_ = goTrans:NodeByName("btnAward").gameObject
	self.btnAwardMask_ = goTrans:NodeByName("btnAward/btnMask").gameObject
	self.btnAwardLabel_ = goTrans:ComponentByName("btnAward/label", typeof(UILabel))
	self.btnGo_ = goTrans:NodeByName("btnGo").gameObject
	self.btnGoMask_ = goTrans:NodeByName("btnGo/btnMask").gameObject
	self.btnGoLabel_ = goTrans:ComponentByName("btnGo/label", typeof(UILabel))
	self.imgAwarded_ = goTrans:ComponentByName("imgAwarded", typeof(UISprite))
	self.progressBar_ = goTrans:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel_ = goTrans:ComponentByName("progressBar/label", typeof(UILabel))
end

function ActivitySportsAchieveItem:layout()
	self.btnGo_:SetActive(false)

	self.btnAwardLabel_.text = __("GET2")

	xyd.setUISpriteAsync(self.imgAwarded_, nil, "mission_awarded_" .. xyd.Global.lang)

	self.bgImg.scrollView = self.parent_.achievementScroll_
	UIEventListener.Get(self.btnAward_).onClick = handler(self, self.onClickAward)
end

function ActivitySportsAchieveItem:onClickAward()
	if not self.achievement_info then
		return
	end

	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.SPORTS
	msg.params = require("cjson").encode({
		type = 1,
		achievement_type = self.achievement_info.achieve_type
	})

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivitySportsAchieveItem:getAchievementInfo()
	return self.achievement_info
end

function ActivitySportsAchieveItem:update(__, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.achieveID_ = tonumber(info.id)
	self.achievement_info = info.achievement_info
	self.info_ = info
	self.missionDesc_.text = info.desc
	self.progressBar_.value = info.achievement_info.value / info.complete_value
	self.progressLabel_.text = info.achievement_info.value .. "/" .. info.complete_value
	self.items_info = info.awards

	self:updateItems()
	self:updateAchieve()
end

function ActivitySportsAchieveItem:updateItems()
	for i = 1, #self.items_info do
		local labelNumScale = 1.6
		local itemType_ = xyd.tables.itemTable:getType(self.items_info[i][1])
		local params = {
			scale = 0.55,
			uiRoot = self.itemGroup_.gameObject,
			itemID = self.items_info[i][1],
			num = self.items_info[i][2],
			labelNumScale = labelNumScale,
			dragScrollView = self.parent_.achievementScroll_
		}

		if not self.itemList_[i] then
			if itemType_ == xyd.ItemType.HERO_DEBRIS or itemType_ == xyd.ItemType.HERO or itemType_ == xyd.ItemType.HERO_RANDOM_DEBRIS or itemType_ == xyd.ItemType.SKIN then
				params.labelNumScale = 1.3
			end

			self.itemList_[i] = xyd.getItemIcon(params)
		elseif self.itemList_[i].getItemID then
			if itemType_ == xyd.ItemType.HERO_DEBRIS or itemType_ == xyd.ItemType.HERO or itemType_ == xyd.ItemType.HERO_RANDOM_DEBRIS or itemType_ == xyd.ItemType.SKIN then
				params.labelNumScale = 1.3

				NGUITools.Destroy(self.itemList_[i]:getGameObject())

				self.itemList_[i] = xyd.getItemIcon(params)
			else
				self.itemList_[i]:setInfo(params)
			end
		elseif itemType_ == xyd.ItemType.HERO_DEBRIS or itemType_ == xyd.ItemType.HERO or itemType_ == xyd.ItemType.HERO_RANDOM_DEBRIS or itemType_ == xyd.ItemType.SKIN then
			params.labelNumScale = 1.3

			self.itemList_[i]:setInfo(params)
		else
			NGUITools.Destroy(self.itemList_[i]:getGameObject())

			self.itemList_[i] = xyd.getItemIcon(params)
		end
	end

	for idx, item in ipairs(self.itemList_) do
		if not self.items_info[idx] then
			item:SetActive(false)
		else
			item:SetActive(true)
			item:getGameObject().transform:SetSiblingIndex(idx)
		end
	end

	self.itemGroup_:Reposition()
end

function ActivitySportsAchieveItem:updateAchieve()
	if self.achievement_info.achieve_id == 0 or self.achieveID_ < self.achievement_info.achieve_id then
		self.btnAward_:SetActive(false)
		self.imgAwarded_.gameObject:SetActive(true)
	elseif self.info_.complete_value <= self.achievement_info.value and self.achievement_info.achieve_id == self.achieveID_ then
		self.btnAward_:SetActive(true)
		self.imgAwarded_.gameObject:SetActive(false)

		self.btnAward_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

		self.btnAwardMask_:SetActive(false)
	else
		self.btnAward_:SetActive(true)
		self.imgAwarded_.gameObject:SetActive(false)

		self.btnAward_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		self.btnAwardMask_:SetActive(true)
	end
end

function ActivitySportsMissionItem:ctor(parentGo, parent)
	self.parent_ = parent
	self.itemList_ = {}

	ActivitySportsMissionItem.super.ctor(self, parentGo)
end

function ActivitySportsMissionItem:initUI()
	self:getComponent()
	ActivitySportsMissionItem.super.initUI(self)

	UIEventListener.Get(self.btnAward_).onClick = handler(self, self.onClickAward)
	UIEventListener.Get(self.btnGo_).onClick = handler(self, self.onClickGo)
end

function ActivitySportsMissionItem:getComponent()
	local goTrans = self.go.transform
	self.bgImg = goTrans:ComponentByName("bgImg", typeof(UIDragScrollView))
	self.missionDesc_ = goTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.itemGroup_ = goTrans:ComponentByName("itemGroup", typeof(UIGrid))
	self.btnAward_ = goTrans:NodeByName("btnAward").gameObject
	self.btnAwardMask_ = goTrans:NodeByName("btnAward/btnMask").gameObject
	self.btnAwardLabel_ = goTrans:ComponentByName("btnAward/label", typeof(UILabel))
	self.btnGo_ = goTrans:NodeByName("btnGo").gameObject
	self.btnGoMask_ = goTrans:NodeByName("btnGo/btnMask").gameObject
	self.btnGoLabel_ = goTrans:ComponentByName("btnGo/label", typeof(UILabel))
	self.imgAwarded_ = goTrans:ComponentByName("imgAwarded", typeof(UISprite))
	self.progressBar_ = goTrans:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel_ = goTrans:ComponentByName("progressBar/label", typeof(UILabel))
	self.btnGoLabel_.text = __("GO")
	self.btnAwardLabel_.text = __("GET2")
end

function ActivitySportsMissionItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.info_ = info
	local mt = xyd.tables.activitySportsMissionTable
	self.missionDesc_.text = mt:getDesc(info.mission_id)
	self.completeNum = mt:getCompleteValue(info.mission_id)
	local value = info.value or 0
	self.progressBar_.value = value / self.completeNum
	self.progressLabel_.text = value .. "/" .. self.completeNum
	self.items_info = mt:getAward(info.mission_id)

	self:updateItems()
	self:updateMission()
end

function ActivitySportsMissionItem:updateItems()
	for i = 1, #self.items_info do
		local labelNumScale = 1.6
		local itemType_ = xyd.tables.itemTable:getType(self.items_info[i][1])
		local params = {
			scale = 0.55,
			uiRoot = self.itemGroup_.gameObject,
			itemID = self.items_info[i][1],
			num = self.items_info[i][2],
			labelNumScale = labelNumScale
		}

		if not self.itemList_[i] then
			if itemType_ == xyd.ItemType.HERO_DEBRIS or itemType_ == xyd.ItemType.HERO or itemType_ == xyd.ItemType.HERO_RANDOM_DEBRIS or itemType_ == xyd.ItemType.SKIN then
				params.labelNumScale = 1.3
			end

			self.itemList_[i] = xyd.getItemIcon(params)
		elseif self.itemList_[i].getItemID then
			if itemType_ == xyd.ItemType.HERO_DEBRIS or itemType_ == xyd.ItemType.HERO or itemType_ == xyd.ItemType.HERO_RANDOM_DEBRIS or itemType_ == xyd.ItemType.SKIN then
				params.labelNumScale = 1.3

				NGUITools.Destroy(self.itemList_[i]:getGameObject())

				self.itemList_[i] = xyd.getItemIcon(params)
			else
				self.itemList_[i]:setInfo(params)
			end
		elseif itemType_ == xyd.ItemType.HERO_DEBRIS or itemType_ == xyd.ItemType.HERO or itemType_ == xyd.ItemType.HERO_RANDOM_DEBRIS or itemType_ == xyd.ItemType.SKIN then
			params.labelNumScale = 1.3

			self.itemList_[i]:setInfo(params)
		else
			NGUITools.Destroy(self.itemList_[i]:getGameObject())

			self.itemList_[i] = xyd.getItemIcon(params)
		end
	end

	for idx, item in pairs(self.itemList_) do
		if not self.items_info[idx] then
			item:SetActive(false)
		else
			item:SetActive(true)
			item:getGameObject().transform:SetSiblingIndex(idx)
		end
	end

	self.itemGroup_:Reposition()
end

function ActivitySportsMissionItem:updateMission()
	local showBtnGo = false
	showBtnGo = (self.completeNum > self.info_.value or false) and true

	if self.info_.is_awarded == 1 then
		showBtnGo = true

		self.btnGoMask_:SetActive(true)

		self.btnGo_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.btnGoLabel_.text = __("ALREADY_GET_PRIZE")
		self.btnGoLabel_.color = Color.New2(960513791)
		self.btnGoLabel_.effectColor = Color.New2(4294967295.0)
	end

	self.btnGo_:SetActive(showBtnGo)
	self.btnAward_:SetActive(not showBtnGo)
end

function ActivitySportsMissionItem:onClickAward()
	if not self.info_ then
		return
	end

	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.SPORTS
	msg.params = require("cjson").encode({
		type = 2,
		mission_id = self.info_.mission_id
	})

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivitySportsMissionItem:onClickGo()
	local goWin = xyd.tables.activitySportsMissionTable:getGoWindow(self.info_.mission_id)
	local params = xyd.tables.activitySportsMissionTable:getGoParams(self.info_.mission_id)

	function params.closeCallBack()
		xyd.WindowManager.get():openWindow("activity_sports_exchange_window")
	end

	xyd.WindowManager.get():openWindow(goWin, params)
	xyd.WindowManager.get():closeWindow("activity_sports_exchange_window")
end

return ActivitySportsExchangeWindow
