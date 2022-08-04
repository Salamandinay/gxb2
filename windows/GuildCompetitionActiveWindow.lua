local GuildCompetitionActiveWindow = class("GuildCompetitionActiveWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local MissiosItem = class("MissiosItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local TASK_TYPE = {
	DAILY = 1,
	ALL_GUILD = 2
}

function GuildCompetitionActiveWindow:ctor(name, params)
	GuildCompetitionActiveWindow.super.ctor(self, name, params)
end

function GuildCompetitionActiveWindow:initWindow()
	self:getUIComponent()
	GuildCompetitionActiveWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
	xyd.db.misc:setValue({
		key = "guidl_competition_mission_red_day_time",
		value = xyd.getServerTime()
	})
end

function GuildCompetitionActiveWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.missionItem = self.groupAction:NodeByName("missionItem").gameObject
	self.upcon = self.groupAction:NodeByName("upcon").gameObject
	self.allProgress = self.upcon:ComponentByName("allProgress", typeof(UISprite))
	self.allProgressUIProgressBar = self.upcon:ComponentByName("allProgress", typeof(UIProgressBar))
	self.activeBg = self.upcon:ComponentByName("activeBg", typeof(UISprite))
	self.activeLabel = self.activeBg:ComponentByName("activeLabel", typeof(UILabel))
	self.pointBg = self.upcon:ComponentByName("pointBg", typeof(UISprite))
	self.pointLabel = self.pointBg:ComponentByName("pointLabel", typeof(UILabel))
	self.showItemCon = self.upcon:NodeByName("showItemCon").gameObject

	for i = 1, 4 do
		self["showItem" .. i] = self.showItemCon:NodeByName("showItem" .. i).gameObject
		self["itemCon" .. i] = self["showItem" .. i]:NodeByName("itemCon").gameObject
		self["itemArrow" .. i] = self["showItem" .. i]:ComponentByName("itemArrow", typeof(UISprite))
		self["itemShowLabel" .. i] = self["showItem" .. i]:ComponentByName("itemShowLabel", typeof(UILabel))
	end

	self.tipsBtn = self.upcon:NodeByName("tipsBtn").gameObject
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.downUpCon = self.downCon:NodeByName("downUpCon").gameObject
	self.downUpNameCon = self.downUpCon:ComponentByName("downUpNameCon", typeof(UISprite))
	self.downUpNameLabel = self.downUpNameCon:ComponentByName("downUpNameLabel", typeof(UILabel))
	self.downUpScrollView = self.downUpCon:NodeByName("scrollView").gameObject
	self.downUpScrollViewUIScrollView = self.downUpCon:ComponentByName("scrollView", typeof(UIScrollView))
	self.downUpGridDaily = self.downUpScrollView:NodeByName("gridDaily").gameObject
	self.downUpGridDailyUIWrapContent = self.downUpScrollView:ComponentByName("gridDaily", typeof(UIWrapContent))
	self.downUpTimeCon = self.downUpCon:NodeByName("downUpTimeCon").gameObject
	self.downUpTimeLabel = self.downUpTimeCon:ComponentByName("downUpTimeLabel", typeof(UILabel))
	self.downUpEffect = self.downUpTimeCon:ComponentByName("downUpEffect", typeof(UITexture))
	self.downUpWrapContent = FixedWrapContent.new(self.downUpScrollViewUIScrollView, self.downUpGridDailyUIWrapContent, self.missionItem, MissiosItem, self)

	self.downUpWrapContent:hideItems()

	self.downDownCon = self.downCon:NodeByName("downDownCon").gameObject
	self.downDownNameCon = self.downDownCon:ComponentByName("downDownNameCon", typeof(UISprite))
	self.downDownNameLabel = self.downDownNameCon:ComponentByName("downDownNameLabel", typeof(UILabel))
	self.downDownScrollView = self.downDownCon:NodeByName("scrollView").gameObject
	self.downDownScrollViewUIScrollView = self.downDownCon:ComponentByName("scrollView", typeof(UIScrollView))
	self.downDownGridDaily = self.downDownScrollViewUIScrollView:NodeByName("gridDaily").gameObject
	self.downDownGridDailyUIWrapContent = self.downDownScrollViewUIScrollView:ComponentByName("gridDaily", typeof(UIWrapContent))
	self.downDownWrapContent = FixedWrapContent.new(self.downDownScrollViewUIScrollView, self.downDownGridDailyUIWrapContent, self.missionItem, MissiosItem, self)

	self.downDownWrapContent:hideItems()
end

function GuildCompetitionActiveWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.tipsBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "GUILD_COMPETITION_ACTIVE_HELP"
		})
	end)

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.GUILD_COMPETITION then
			self:updateItems(true)
		end
	end)
end

function GuildCompetitionActiveWindow:layout()
	self.labelTitle.text = __("GUILD_COMPETITION_ACTIVE_TEXT01")
	self.activeLabel.text = __("GUILD_COMPETITION_ACTIVE_TEXT02")
	self.downUpNameLabel.text = __("GUILD_COMPETITION_ACTIVE_TEXT03")
	self.downDownNameLabel.text = __("GUILD_COMPETITION_ACTIVE_TEXT04")

	self:initProgressItemShow()
	self:initTime()

	if xyd.models.guild:isCanUpdateCompetitionActiveMissionCheck() then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.GUILD_COMPETITION)
		xyd.models.guild:setCanUpdateCompetitionActiveMissionCheck(false)
		xyd.models.guild:checkCanUpdateCompetitionActiveMissionWithTime()
		self:updateUpProgress()
	else
		self:updateItems(true)
	end
end

function GuildCompetitionActiveWindow:initTime()
	local timeInfo = xyd.models.guild:getGuildCompetitionLeftTime()

	if timeInfo.type ~= 2 then
		self.downUpTimeCon:SetActive(false)

		return
	end

	local guildCompetitionData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_COMPETITION)
	local startTime = guildCompetitionData:startTime()
	local endTime = guildCompetitionData:getEndTime()
	local timeDis = 0

	if startTime < xyd.getServerTime() and xyd.getServerTime() < endTime then
		local dayArr = xyd.tables.miscTable:split2num("guild_competition_time", "value", "|")

		for i = 1, dayArr[1] + dayArr[2] do
			if xyd.getServerTime() < startTime + i * xyd.DAY_TIME then
				timeDis = startTime + i * xyd.DAY_TIME - xyd.getServerTime()

				break
			end
		end
	end

	if timeDis > 0 then
		self.downUpTimeCon:SetActive(true)

		local countdown = CountDown.new(self.downUpTimeLabel, {
			duration = timeDis,
			callback = handler(self, function ()
				self.downUpTimeLabel.text = "00:00:00"
			end)
		})

		if not self.clockEffect then
			self.clockEffect = xyd.Spine.new(self.downUpEffect.gameObject)

			self.clockEffect:setInfo("fx_ui_shizhong", function ()
				self.clockEffect:play("texiao1", 0)
			end)
		end
	else
		self.downUpTimeCon:SetActive(false)
	end
end

function GuildCompetitionActiveWindow:initProgressItemShow()
	for i = 1, 4 do
		local arard = xyd.tables.guildCompetitionActiveAwardTable:getAwards(i)
		local item = {
			show_has_num = true,
			isShowSelected = false,
			itemID = arard[1],
			num = arard[2],
			scale = Vector3(0.7962962962962963, 0.7962962962962963, 1),
			uiRoot = self["itemCon" .. i]
		}
		local icon = xyd.getItemIcon(item, xyd.ItemIconType.ADVANCE_ICON)
		self["itemShowLabel" .. i].text = tostring(xyd.tables.guildCompetitionActiveAwardTable:getValue(i))
		self["upIcon" .. i] = icon
	end
end

function GuildCompetitionActiveWindow:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.GUILD_COMPETITION then
		return
	end

	self:updateItems()
end

function GuildCompetitionActiveWindow:updateItems(isFirst)
	self:updateUpProgress()
	self:updateDownUpItems(isFirst)
	self:updateDownDownItems(isFirst)
end

function GuildCompetitionActiveWindow:updateUpProgress()
	local boss_info = xyd.models.guild:getGuildCompetitionInfo().boss_info
	local point = boss_info.point
	local awardIds = xyd.tables.guildCompetitionActiveAwardTable:getIDs()
	local maxPoint = xyd.tables.guildCompetitionActiveAwardTable:getValue(#awardIds)

	if maxPoint <= point then
		self.allProgressUIProgressBar.value = 1
	else
		self.allProgressUIProgressBar.value = point / maxPoint
	end

	self.pointLabel.text = point

	for i in pairs(awardIds) do
		local littlePoint = xyd.tables.guildCompetitionActiveAwardTable:getValue(awardIds[i])

		if littlePoint <= point then
			self["upIcon" .. i]:setChoose(true)
		end
	end
end

function GuildCompetitionActiveWindow:updateDownUpItems(isFirst)
	local ids = xyd.tables.guildCompetitionMissionTable:getIdsWithType(TASK_TYPE.DAILY)
	local setInfosArr = {}

	for i in pairs(ids) do
		table.insert(setInfosArr, {
			tableId = ids[i]
		})
	end

	if isFirst then
		self.downUpWrapContent:setInfos(setInfosArr, {})
	else
		self.downUpWrapContent:setInfos(setInfosArr, {
			keepPosition = true
		})
	end

	if isFirst then
		self.downUpScrollViewUIScrollView:ResetPosition()
	end
end

function GuildCompetitionActiveWindow:updateDownDownItems(isFirst)
	local ids = xyd.tables.guildCompetitionMissionTable:getIdsWithType(TASK_TYPE.ALL_GUILD)
	local setInfosArr = {}

	for i in pairs(ids) do
		table.insert(setInfosArr, {
			tableId = ids[i]
		})
	end

	local canGetArr = {}
	local noArr = {}
	local yetArr = {}

	for i, info in pairs(setInfosArr) do
		local infoValue = xyd.models.guild:getGuildCompetitionMissionInfo(info.tableId)

		if infoValue.is_awarded == 1 then
			table.insert(yetArr, info)
		elseif infoValue.is_completed == 1 then
			table.insert(canGetArr, info)
		else
			table.insert(noArr, info)
		end
	end

	for i, info in pairs(noArr) do
		table.insert(canGetArr, info)
	end

	for i, info in pairs(yetArr) do
		table.insert(canGetArr, info)
	end

	if isFirst then
		self.downDownWrapContent:setInfos(canGetArr, {})
	else
		self.downDownWrapContent:setInfos(canGetArr, {
			keepPosition = true
		})
	end

	if isFirst then
		self.downDownScrollViewUIScrollView:ResetPosition()
	end
end

function GuildCompetitionActiveWindow:willClose()
	GuildCompetitionActiveWindow.super.willClose(self)
	xyd.models.guild:checkGuildCompetitionMissionRed()
end

function MissiosItem:ctor(go, parent)
	self.parent = parent

	MissiosItem.super.ctor(self, go)
end

function MissiosItem:getUIComponent()
	self.progressPartUIProgressBar = self.go:ComponentByName("progressPart", typeof(UIProgressBar))
	self.labelDescUILabel = self.progressPartUIProgressBar:ComponentByName("labelDesc", typeof(UILabel))
	self.progressValueUISprite = self.progressPartUIProgressBar:ComponentByName("progressValue", typeof(UISprite))
	self.missionDescUILabel = self.go:ComponentByName("missionDesc", typeof(UILabel))
	self.itemRoot = self.go:NodeByName("itemRoot").gameObject
	self.itemRootUILayout = self.go:ComponentByName("itemRoot", typeof(UILayout))
	self.btnAward = self.go:NodeByName("btnAward").gameObject
	self.btnAwardUISprite = self.go:ComponentByName("btnAward", typeof(UISprite))
	self.btnAwardLabelUILabel = self.btnAward:ComponentByName("label", typeof(UILabel))
	self.btnAwardBoxCollider = self.btnAward:GetComponent(typeof(UnityEngine.BoxCollider))
	self.btnMask = self.btnAward:NodeByName("btnMask").gameObject
	self.btnMaskUISprite = self.btnAward:ComponentByName("btnMask", typeof(UISprite))
	self.btnGo = self.go:NodeByName("btnGo").gameObject
	self.btnGoUISprite = self.go:ComponentByName("btnGo", typeof(UISprite))
	self.btnGoLabelUILabel = self.btnGo:ComponentByName("label", typeof(UILabel))
	self.imgAwardUISprite = self.go:ComponentByName("imgAward", typeof(UISprite))
	self.btnGoPointCon = self.go:NodeByName("btnGoPointCon").gameObject
	self.btnGoPointConUILayout = self.go:ComponentByName("btnGoPointCon", typeof(UILayout))
	self.btnGoPointIcon = self.btnGoPointCon:NodeByName("btnGoPointIcon").gameObject
	self.btnGoPointIconUISprite = self.btnGoPointCon:ComponentByName("btnGoPointIcon", typeof(UISprite))
	self.btnGoPointLabelUILabel = self.btnGoPointCon:ComponentByName("btnGoPointLabel", typeof(UILabel))

	xyd.setUISpriteAsync(self.imgAwardUISprite, nil, "mission_awarded_" .. xyd.Global.lang, nil, )
end

function MissiosItem:initUI()
	self:getUIComponent()
	MissiosItem.super.initUI(self)
	self.btnGo:SetActive(false)

	UIEventListener.Get(self.btnAward.gameObject).onClick = handler(self, function ()
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.GUILD_COMPETITION, json.encode({
			table_id = self.tableId
		}))
	end)
	self.btnAwardLabelUILabel.text = __("GET2")
end

function MissiosItem:update(index, info)
	local data = info

	if not data then
		self.go:SetActive(false)

		return
	end

	self.tableId = data.tableId
	self.missionDescUILabel.text = xyd.tables.guildCompetitionMissionTextTable:getDesc(self.tableId)
	local awards = xyd.tables.guildCompetitionMissionTable:getAwards(self.tableId)

	if not self.items then
		self.items = {}
	end

	for i, award in pairs(awards) do
		local item = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = award[1],
			num = award[2],
			scale = Vector3(0.5740740740740741, 0.5740740740740741, 1),
			uiRoot = self.itemRoot.gameObject
		}

		if not self.items[i] then
			local icon = xyd.getItemIcon(item, xyd.ItemIconType.ADVANCE_ICON)
			self.items[i] = icon
		else
			self.items[i]:setInfo(item)
		end

		self.items[i]:getGameObject():SetActive(true)
	end

	for i = #awards + 1, #self.items do
		self.items[i]:getGameObject():SetActive(false)
	end

	self.itemRootUILayout:Reposition()

	local active = xyd.tables.guildCompetitionMissionTable:getActive(self.tableId)

	if active and active > 0 then
		self.btnGoPointCon.gameObject:SetActive(true)

		self.btnGoPointLabelUILabel.text = "+" .. active

		self.btnGoPointConUILayout:Reposition()
		self.itemRoot.gameObject:Y(13.3)
	else
		self.btnGoPointCon.gameObject:SetActive(false)
		self.itemRoot.gameObject:Y(0)
	end

	local info = xyd.models.guild:getGuildCompetitionMissionInfo(self.tableId)
	local curNum = info.value
	local needNum = xyd.tables.guildCompetitionMissionTable:getCompleteValue(self.tableId)

	self.imgAwardUISprite.gameObject:SetActive(false)

	self.btnAwardBoxCollider.enabled = true

	xyd.applyChildrenOrigin(self.btnAward.gameObject)

	for i = 1, #self.items do
		self.items[i]:setChoose(false)
	end

	if needNum <= curNum or info.is_awarded == 1 or info.is_completed == 1 then
		self.progressPartUIProgressBar.value = 1
		self.labelDescUILabel.text = needNum .. "/" .. needNum

		self.btnAward:SetActive(true)

		if info.is_awarded == 1 then
			self.btnAward:SetActive(false)
			self.imgAwardUISprite.gameObject:SetActive(true)

			for i = 1, #self.items do
				self.items[i]:setChoose(true)
			end
		end
	else
		self.progressPartUIProgressBar.value = curNum / needNum
		self.labelDescUILabel.text = curNum .. "/" .. needNum

		self.btnAward:SetActive(true)
		xyd.applyChildrenGrey(self.btnAward.gameObject)

		self.btnAwardBoxCollider.enabled = false
	end
end

return GuildCompetitionActiveWindow
