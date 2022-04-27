local ActivityContent = import(".ActivityContent")
local ActivityBeachSummer = class("ActivityBeachSummer", ActivityContent)
local ActivityBeachSummerMissionItem = class("ActivityBeachSummerMissionItem", import("app.components.CopyComponent"))
local ActivityBeachIslandItem = class("ActivityBeachIslandItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")

function ActivityBeachSummer:ctor(parentGO, params)
	self.missionItemList_ = {}
	self.landGroup_ = 1
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_BEACH_SUMMER)
	local stage = activityData.detail.stage
	local start_time = activityData:startTime()
	local openDay = xyd.tables.activityBeachIsland:getOpenDay(6)

	if xyd.getServerTime() - start_time >= 86400 * openDay and stage >= 6 then
		self.landGroup_ = 2
	end

	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_BEACH_SUMMER)
	ActivityBeachSummer.super.ctor(self, parentGO, params)
end

function ActivityBeachSummer:getPrefabPath()
	return "Prefabs/Windows/activity/activity_beach_island"
end

function ActivityBeachSummer:initUI()
	ActivityBeachSummer.super.initUI(self)
	self:getUIComponent()
	self:updatePos()
	self:layout()
end

function ActivityBeachSummer:updatePos()
	local realHeight = xyd.Global.getRealHeight()

	self.bgImg_.transform:Y(91 - 0.5112359550561798 * (realHeight - 1280))
	self.islandGroup_:Y(-0.4438202247191011 * (realHeight - 1280))
	self.missionGroup:Y(-176 - 0.5561797752808989 * (realHeight - 1280))
	self.logoImg_.transform:Y(-0.06179775280898876 * (realHeight - 1280))
end

function ActivityBeachSummer:getUIComponent()
	local goTrans = self.go.transform
	self.bgImg_ = goTrans:NodeByName("bgImg").gameObject
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.labelNum_ = goTrans:ComponentByName("itemGroup/labelNum", typeof(UILabel))
	self.btnGet_ = goTrans:NodeByName("itemGroup/btnGet").gameObject
	self.labelTime_ = goTrans:ComponentByName("timeGroup/labelTime", typeof(UILabel))
	self.labelEnd_ = goTrans:ComponentByName("timeGroup/labelEnd", typeof(UILabel))
	self.btnHelp_ = goTrans:NodeByName("btnHelp").gameObject
	self.btnAward_ = goTrans:NodeByName("btnAward").gameObject
	self.redPoint_ = goTrans:NodeByName("btnAward/redPoint").gameObject
	local missionGroup = goTrans:NodeByName("groupMission")
	self.missionGroup = missionGroup
	self.missionTime_ = missionGroup:ComponentByName("timeGroup/labelTime", typeof(UILabel))
	self.missionEnd_ = missionGroup:ComponentByName("timeGroup/labelEnd", typeof(UILabel))
	self.missionItemRoot_ = missionGroup:NodeByName("beach_mission_item").gameObject
	self.scrollView_ = missionGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.gridMission_ = missionGroup:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.labelMission_ = missionGroup:ComponentByName("labelTips", typeof(UILabel))

	for i = 1, 5 do
		self["islandRoot" .. i] = goTrans:NodeByName("islandGroup/landItem" .. i).gameObject
	end

	self.changeBtn_ = goTrans:ComponentByName("islandGroup/changeBtn", typeof(UISprite))
	self.changeBtnRed_ = goTrans:NodeByName("islandGroup/changeBtn/redPoint").gameObject
	self.islandGroup_ = goTrans:NodeByName("islandGroup")

	self.missionItemRoot_:SetActive(false)
end

function ActivityBeachSummer:onRegister()
	UIEventListener.Get(self.btnHelp_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_BEACH_ISLAND_HELP"
		})
	end

	UIEventListener.Get(self.btnAward_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_beach_island_award_window", {
			star = self.activityData.detail.star_num,
			awarded = self.activityData.detail.awarded
		})
	end

	UIEventListener.Get(self.changeBtn_.gameObject).onClick = handler(self, self.onClickChangeBtn)

	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onUpdateActivityInfo))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNum))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateRed))

	UIEventListener.Get(self.btnGet_).onClick = function ()
		local params = xyd.tables.activityTable:getWindowParams(xyd.ActivityID.ACTIVITY_BEACH_SUMMER)
		local testParams = nil

		if params ~= nil then
			testParams = params.activity_ids
		end

		xyd.WindowManager.get():closeWindow("activity_window", function ()
			xyd.openWindow("activity_window", {
				activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_BEACH_SUMMER),
				onlyShowList = testParams,
				select = xyd.ActivityID.ACTIVITY_BEACH_PUZZLE
			})
		end)
	end
end

function ActivityBeachSummer:updateRed()
	self.redPoint_:SetActive(self.activityData:getRedPointStar())

	local win = xyd.WindowManager.get():getWindow("activity_window")

	if win then
		win:updateTitleRedMark()
	end
end

function ActivityBeachSummer:layout()
	self:initIsland()
	self:initMission()
	self:updateItemNum()
	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_beach_island_logo_" .. xyd.Global.lang)

	self.labelMission_.text = __("ACTIVITY_BEACH_ISLAND_TEXT01")
	local activityStartTime = self.activityData:startTime()
	local openDay = xyd.tables.activityBeachIsland:getOpenDay(6)

	if xyd.getServerTime() - activityStartTime < 86400 * openDay then
		self.missionEnd_.text = __("ACTIVITY_ICE_SECRET_MISSION_CD")
		local countdown = CountDown.new(self.missionTime_, {
			duration = 86400 * openDay - (xyd.getServerTime() - activityStartTime)
		})
	else
		self.missionEnd_.text = __("ACTIVITY_ICE_SECRET_MISSION_TIP")
	end

	self:updateRed()
	self:updateNextRed()
	self:checkFinger()
end

function ActivityBeachSummer:checkFinger()
	local hasClick = xyd.db.misc:getValue("beach_island_click")

	if not hasClick or tonumber(hasClick) ~= 1 then
		self.fingerEffect_ = xyd.Spine.new(self.islandRoot1:NodeByName("effectRoot").gameObject)

		self.fingerEffect_:setInfo("fx_ui_dianji", function ()
			self.fingerEffect_:play("texiao01", 0)
		end)
	end
end

function ActivityBeachSummer:updateFinger()
	if self.fingerEffect_ then
		self.fingerEffect_:SetActive(false)
		xyd.db.misc:setValue({
			value = 1,
			key = "beach_island_click"
		})
	end
end

function ActivityBeachSummer:onUpdateActivityInfo()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_BEACH_SUMMER)

	self:updateMission()
	self:updateIsland()
	self:updateRed()
end

function ActivityBeachSummer:updateItemNum()
	self.labelNum_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.BEACH_ISLAND_ITEM)
end

function ActivityBeachSummer:initMission()
	local ids = xyd.tables.activityBeachIslandMission:getIDs()
	local infos = {}

	for index, id in ipairs(ids) do
		local params = {
			id = id,
			is_awarded = self.activityData.detail.mission_awarded[index],
			value = self.activityData.detail.mission_count[index],
			complete_value = xyd.tables.activityBeachIslandMission:getCompleteValue(id),
			desc = xyd.tables.activityBeachIslandMission:getDesc(id),
			award = xyd.tables.activityBeachIslandMission:getAward(id)
		}
		local linkActivity = xyd.tables.activityBeachIslandMission:getLinkActivity(id)
		local activityData = xyd.models.activity:getActivity(linkActivity)

		if activityData then
			table.insert(infos, params)
		end
	end

	table.sort(infos, function (a, b)
		local valueA = a.id + xyd.checkCondition(a.complete_value <= a.value, -100, 0)
		local valueB = b.id + xyd.checkCondition(b.complete_value <= b.value, -100, 0)

		return valueA > valueB
	end)

	for _, info in ipairs(infos) do
		local itemNew = NGUITools.AddChild(self.gridMission_.gameObject, self.missionItemRoot_)

		itemNew:SetActive(true)

		self.missionItemList_[info.id] = ActivityBeachSummerMissionItem.new(itemNew, info)
	end

	self.gridMission_:Reposition()
	self.scrollView_:ResetPosition()
end

function ActivityBeachSummer:updateMission()
	local ids = xyd.tables.activityBeachIslandMission:getIDs()
	local infos = {}

	for index, id in ipairs(ids) do
		local params = {
			id = id,
			is_awarded = self.activityData.detail.mission_awarded[index],
			value = self.activityData.detail.mission_count[index],
			complete_value = xyd.tables.activityBeachIslandMission:getCompleteValue(id),
			desc = xyd.tables.activityBeachIslandMission:getDesc(id),
			award = xyd.tables.activityBeachIslandMission:getAward(id)
		}

		table.insert(infos, params)
	end

	for _, info in ipairs(infos) do
		if self.missionItemList_[info.id] then
			self.missionItemList_[info.id]:updateInfo(info)
		end
	end
end

function ActivityBeachSummer:initIsland()
	local isLandData = self.activityData.detail.battles
	local stage = self.activityData.detail.stage or 1

	for i = 1, 5 do
		local index = xyd.checkCondition(self.landGroup_ == 1, i, i + 5)
		local params = {
			stageNow = stage,
			isLandData = isLandData[index],
			index = index
		}
		self["isLandItem" .. i] = ActivityBeachIslandItem.new(self["islandRoot" .. i], params, self)
	end

	if self.landGroup_ == 1 then
		xyd.setUISpriteAsync(self.changeBtn_, nil, "activity_beach_island_next")
	else
		xyd.setUISpriteAsync(self.changeBtn_, nil, "activity_beach_island_pre")
	end
end

function ActivityBeachSummer:updateIsland()
	local isLandData = self.activityData.detail.battles
	local stage = self.activityData.detail.stage or 1

	for i = 1, 5 do
		local index = xyd.checkCondition(self.landGroup_ == 1, i, i + 5)
		local params = {
			stageNow = stage,
			isLandData = isLandData[index],
			index = index
		}

		if self["isLandItem" .. i] then
			self["isLandItem" .. i]:updateParams(params)
		end
	end

	if self.landGroup_ == 1 then
		xyd.setUISpriteAsync(self.changeBtn_, nil, "activity_beach_island_next")
	else
		xyd.setUISpriteAsync(self.changeBtn_, nil, "activity_beach_island_next_pre")
	end
end

function ActivityBeachSummer:onClickChangeBtn()
	if self.inAnim_ then
		return
	end

	local start_time = self.activityData:startTime()
	local openDay = xyd.tables.activityBeachIsland:getOpenDay(6)

	if xyd.getServerTime() - start_time < 86400 * openDay then
		local seconds = 86400 * openDay - (xyd.getServerTime() - start_time)
		local day = math.floor(seconds / xyd.DAY)
		local hour = math.floor(seconds % xyd.DAY / xyd.HOUR)
		local minute = math.floor(seconds % xyd.HOUR / xyd.MINUTE)
		local second = seconds % xyd.MINUTE
		local timeStr = xyd.secondsToString(seconds)

		if day > 0 then
			timeStr = __("DAY_HOUR", day, hour)
		elseif hour > 0 then
			timeStr = __("LOGIN_HANGUP_TEXT03", hour, minute, second)
		elseif minute > 0 then
			timeStr = __("LOGIN_HANGUP_TEXT07", minute, second)
		else
			timeStr = __("SECOND", second)
		end

		xyd.alertTips(__("OPEN_AFTER_TIME", timeStr))
	else
		self.inAnim_ = true
		self.landGroup_ = xyd.checkCondition(self.landGroup_ == 1, 2, 1)

		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_ICE_SECRET, function ()
			xyd.db.misc:setValue({
				value = 1,
				key = "beach_island_next"
			})
		end)

		for i = 1, 5 do
			if self["isLandItem" .. i] then
				self["isLandItem" .. i]:setAlpha(0)
				self:waitForTime(0.1 * i, function ()
					self["isLandItem" .. i]:showChangeAni()
				end)
			end
		end

		self:waitForTime(0.5, function ()
			self.inAnim_ = false
		end)
		self:updateIsland()
		self:updateNextRed()
	end
end

function ActivityBeachSummer:updateNextRed()
	local start_time = self.activityData:startTime()
	local value = xyd.db.misc:getValue("beach_island_next")
	local openDay = xyd.tables.activityBeachIsland:getOpenDay(6)

	if xyd.getServerTime() - start_time >= 86400 * openDay and tonumber(value) ~= 1 then
		self.changeBtnRed_:SetActive(true)
	else
		self.changeBtnRed_:SetActive(false)
	end
end

function ActivityBeachSummerMissionItem:ctor(goItem, params)
	self.id = params.id
	self.isComplete_ = params.is_awarded == 1
	self.complete_value_ = params.complete_value
	self.value = params.value
	self.item = params.award
	self.info_ = params

	ActivityBeachSummerMissionItem.super.ctor(self, goItem)
end

function ActivityBeachSummerMissionItem:initGO()
	ActivityBeachSummerMissionItem.super.initGO(self)
	self:getComponent()
end

function ActivityBeachSummerMissionItem:initUI()
	self:initIcon()
	self:initProgress()

	self.descLabel.text = self.info_.desc
	UIEventListener.Get(self.go).onClick = handler(self, function ()
		if self.isComplete_ then
			return
		end

		local getWayId = xyd.tables.activityBeachIslandMission:getJumpID(self.id)

		if getWayId > 0 then
			xyd.goWay(getWayId, nil, , function ()
				xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_BEACH_SUMMER)
			end)
		end
	end)
end

function ActivityBeachSummerMissionItem:getComponent()
	local transGo = self.go.transform
	self.descLabel = transGo:ComponentByName("descLabel", typeof(UILabel))
	self.progressBar = transGo:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressDesc = transGo:ComponentByName("progressBar/progressLabel", typeof(UILabel))
	self.itemGroup = transGo:NodeByName("itemGroup").gameObject

	if xyd.Global.lang == "zh_tw" or xyd.Global.lang == "ja_jp" then
		self.descLabel.overflowHeight = 30
	end
end

function ActivityBeachSummerMissionItem:initIcon()
	if not self.itemIcon then
		self.itemIcon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			itemID = self.item[1],
			num = self.item[2],
			uiRoot = self.itemGroup.gameObject,
			scale = Vector3(0.5925925925925926, 0.5925925925925926, 1)
		})
	else
		self.itemIcon:setInfo({
			isAddUIDragScrollView = true,
			itemID = self.item[1],
			num = self.item[2],
			scale = Vector3(0.5925925925925926, 0.5925925925925926, 1)
		})
	end
end

function ActivityBeachSummerMissionItem:initProgress()
	if self.complete_value_ <= self.value then
		self.value = self.complete_value_
		self.isComplete_ = true
	end

	self.progressBar.value = math.min(self.value, self.complete_value_) / self.complete_value_
	self.progressDesc.text = self.value .. " / " .. self.complete_value_
end

function ActivityBeachSummerMissionItem:updateInfo(params)
	self.id = params.id
	self.completeNum = params.completeNum
	self.value = params.value
	self.item = params.award
	self.info_ = params

	self:initUI()
	self.itemIcon:setChoose(self.isComplete_)
end

function ActivityBeachIslandItem:ctor(goItem, params, parent)
	self.index_ = params.index
	self.info_ = params
	self.parent_ = parent

	ActivityBeachIslandItem.super.ctor(self, goItem)
end

function ActivityBeachIslandItem:setAlpha(alpha)
	self.imgIcon_.alpha = alpha
end

function ActivityBeachIslandItem:showChangeAni()
	local seq = self:getSequence()
	local targetPosY = self.go.transform.localPosition.y + 50
	local targetPosX = self.go.transform.localPosition.x

	self.go.transform:Y(targetPosY)

	self.imgIcon_.alpha = 1

	seq:Insert(0, self.go.transform:DOLocalMove(Vector3(targetPosX, targetPosY - 55, 0), 0.2))
	seq:Insert(0, self.go.transform:DOScale(Vector3(0.8, 0.8, 1), 0.2))
	seq:Insert(0.2, self.go.transform:DOLocalMove(Vector3(targetPosX, targetPosY - 30, 0), 0.2))
	seq:Insert(0.2, self.go.transform:DOScale(Vector3(1.05, 1.05, 1), 0.2))
	seq:Insert(0.4, self.go.transform:DOLocalMove(Vector3(targetPosX, targetPosY - 50, 0), 0.2))
end

function ActivityBeachIslandItem:updateParams(params)
	self.info_ = params
	self.index_ = params.index

	self:initUI()
end

function ActivityBeachIslandItem:initGO()
	ActivityBeachIslandItem.super.initGO(self)
	self:getComponent()
end

function ActivityBeachIslandItem:initUI()
	ActivityBeachIslandItem.super.initUI(self)

	if self.info_.stageNow < self.index_ and self.info_.stageNow > 0 then
		for i = 1, 3 do
			if self["point" .. i] then
				self["point" .. i]:SetActive(false)
			end

			self["star" .. i].gameObject:SetActive(false)
		end

		self.lockImg_:SetActive(true)
	else
		for i = 1, 3 do
			if self["point" .. i] and (self.index_ < self.info_.stageNow or self.info_.stageNow < 0) then
				self["point" .. i]:SetActive(true)
			elseif self["point" .. i] then
				self["point" .. i]:SetActive(false)
			end

			self["star" .. i].gameObject:SetActive(true)

			if self.info_.isLandData[i] and self.info_.isLandData[i] == 1 then
				xyd.setUISpriteAsync(self["star" .. i], nil, "activity_beach_star_icon")
			else
				xyd.setUISpriteAsync(self["star" .. i], nil, "activity_beach_star_icon2")
			end
		end

		self.lockImg_:SetActive(false)
	end
end

function ActivityBeachIslandItem:getComponent()
	local goTrans = self.go.transform
	self.imgIcon_ = goTrans:GetComponent(typeof(UISprite))
	self.clickBox_ = goTrans:ComponentByName("clickBg", typeof(UIWidget))
	self.lockImg_ = goTrans:NodeByName("lockImg").gameObject

	for i = 1, 3 do
		if self.index_ <= 4 then
			self["point" .. i] = goTrans:NodeByName("pointGroup/point" .. i).gameObject
		end

		self["star" .. i] = goTrans:ComponentByName("starGroup/star" .. i, typeof(UISprite))
	end

	UIEventListener.Get(self.clickBox_.gameObject).onClick = handler(self, self.onClickIsland)
end

function ActivityBeachIslandItem:onClickIsland()
	self.parent_:updateFinger()

	if self.info_.stageNow < self.index_ and self.info_.stageNow > 0 then
		xyd.alertTips(__("ACTIVITY_BEACH_ISLAND_TEXT03"))
	else
		local goIndex = nil

		if self.parent_.landGroup_ == 2 then
			goIndex = self.index_ + 5
		else
			goIndex = self.index_
		end

		xyd.WindowManager.get():openWindow("activity_beach_island_fight_window", {
			id = self.index_,
			challenges = self.info_.isLandData
		})
	end
end

return ActivityBeachSummer
