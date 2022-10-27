local BaseWindow = import(".BaseWindow")
local GuildNewWarRecordWindow = class("GuildNewWarRecordWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local GuildNewWarRecordItem = class("GuildNewWarRecordItem", import("app.common.ui.FixedWrapContentItem"))
local PlayerIcon = import("app.components.PlayerIcon")

function GuildNewWarRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)
	self.data = {}
	self.newData = {}
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)
end

function GuildNewWarRecordWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function GuildNewWarRecordWindow:getUIComponent()
	self.groupAction = self.window_.transform:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelWindowTitle = self.groupAction:ComponentByName("labelWindowTitle", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.drag = self.midGroup:NodeByName("drag").gameObject
	self.scroller = self.midGroup:NodeByName("scroller").gameObject
	self.scrollView = self.midGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.container = self.scroller:NodeByName("container").gameObject
	self.item = self.scroller:NodeByName("item").gameObject
	self.groupNone = self.midGroup:NodeByName("groupNone").gameObject
	self.labelNone = self.groupNone:ComponentByName("labelNone", typeof(UILabel))
	self.panel = self.groupAction:NodeByName("panel").gameObject
	self.clickMask = self.panel:NodeByName("clickMask").gameObject
	local wrapContent = self.scroller:ComponentByName("container", typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.item, GuildNewWarRecordItem, self)
end

function GuildNewWarRecordWindow:register()
	self.eventProxy_:addEventListener(xyd.event.GUILD_NEW_WAR_FIGHT, handler(self, self.onGetData))

	UIEventListener.Get(self.btnClose).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function GuildNewWarRecordWindow:layout()
	self.labelWindowTitle.text = __("GUILD_NEW_WAR_TEXT70")
	self.labelNone.text = __("ARENA_NO_RECORD")

	self.wrapContent:setInfos({})
	self.scrollView:ResetPosition()
end

function GuildNewWarRecordWindow:onGetData(event)
	local data = xyd.decodeProtoBuf(event.data)
	local records = data.record_ids
	local tempInfo = self.activityData:getTempBattleEnemyInfo()
	local battleID = data.battle_reports[#data.battle_reports].info.battle_id
	local showInfo = self.activityData:getShowInfoByBattleID(battleID)
	local reduceBraveHP = 0
	local winTime = 0
	local lostTime = 0

	if data.battle_reports and data.battle_reports[#data.battle_reports] then
		for i = 1, #data.battle_reports do
			if data.battle_reports[i].isWin == 1 then
				winTime = winTime + 1
			else
				lostTime = lostTime + 1
			end
		end

		reduceBraveHP = xyd.tables.miscTable:split2num("guild_new_war_courage_reduce", "value", "|")[winTime + 1]
	end

	local data = {
		time = xyd.getServerTime(),
		record_ids = records,
		scoreSelf = self.activityData.tempAddSelfScore or 0,
		scoreEnemy = reduceBraveHP or 0,
		is_win = lostTime <= winTime,
		player_id = tempInfo.player_id or tempInfo.playerID,
		info_detail = tempInfo,
		event_data = event.data
	}

	table.insert(self.newData, data)

	if not self.waiting then
		self.waiting = true

		self:waitForTime(0.8, function ()
			local nowBraveHP = self.activityData.mapInfo[self.activityData.tempRecordNodeID].flagInfos[self.activityData.tempRecordFlagID].braveHP

			if self.activityData:getLeftFightTime() == 0 or not self.activityData.leftFightTime or nowBraveHP <= 0 then
				dump("leftFightTime重置")
				self:cancelMask()
			else
				self.waiting = false

				for i = 1, #self.newData do
					if not self.data[i] then
						self.data[i] = self.newData[i]
					end
				end

				dump("setInfos重置")
				self.wrapContent:setInfos(self.data)
				self.scrollView:ResetPosition()
			end
		end)
	end
end

function GuildNewWarRecordWindow:cancelMask()
	for i = 1, #self.newData do
		if not self.data[i] then
			self.data[i] = self.newData[i]
		end
	end

	self.panel:SetActive(false)
	self.wrapContent:setInfos(self.data)
	self.scrollView:ResetPosition()
end

function GuildNewWarRecordItem:ctor(go, parent)
	GuildNewWarRecordItem.super.ctor(self, go, parent)

	self.parent = parent
end

function GuildNewWarRecordItem:initUI()
	self.pIconPos = self.go:NodeByName("pIcon").gameObject
	self.playerName = self.go:ComponentByName("playerName", typeof(UILabel))
	self.time = self.go:ComponentByName("time", typeof(UILabel))
	self.labelTextPoint1 = self.go:ComponentByName("labelTextPoint1", typeof(UILabel))
	self.labelPoint1 = self.go:ComponentByName("labelPoint1", typeof(UILabel))
	self.loseImage = self.go:ComponentByName("loseImage", typeof(UISprite))
	self.winImage = self.go:ComponentByName("winImage", typeof(UISprite))
	self.video = self.go:ComponentByName("video", typeof(UISprite))
	self.labelTextPoint2 = self.go:ComponentByName("labelTextPoint2", typeof(UILabel))
	self.labelPoint2 = self.go:ComponentByName("labelPoint2", typeof(UILabel))

	self:register()
end

function GuildNewWarRecordItem:register()
	UIEventListener.Get(self.video.gameObject).onClick = function ()
		self:onclickVideo()
	end
end

function GuildNewWarRecordItem:updateInfo()
	local params = self.data

	if xyd.Global.lang == "fr_fr" then
		self.time.fontSize = 14
	end

	if not self.pIcon then
		local pIconContainer = self.go:NodeByName("pIcon").gameObject
		self.pIcon = PlayerIcon.new(pIconContainer)
	end

	if params.is_robot == 1 then
		local avatar = xyd.tables.arenaRobotTable:getAvatar(params.player_id)
		local lev = xyd.tables.arenaRobotTable:getLev(params.player_id)
		local name = xyd.tables.arenaRobotTable:getName(params.player_id)

		self.pIcon:setInfo({
			avatarID = avatar,
			lev = lev
		})

		self.playerName.text = name
	else
		self.pIcon:setInfo({
			avatarID = params.info_detail.avatar_id,
			lev = params.info_detail.lev,
			avatar_frame_id = params.info_detail.avatar_frame_id,
			callback = function ()
				self:onclickAvatar()
			end
		})

		self.playerName.text = params.info_detail.player_name
	end

	self.time.text = params.time
	local resTime = xyd.getServerTime() - params.time
	local min = resTime / 60
	local hour = min / 60
	local day = hour / 24

	if day >= 1 then
		self.time.text = __("DAY_BEFORE", math.floor(day))
	elseif hour >= 1 then
		self.time.text = __("HOUR_BEFORE", math.floor(hour))
	elseif min >= 1 then
		self.time.text = __("MIN_BEFORE", math.floor(min))
	else
		self.time.text = __("SECOND_BEFORE")
	end

	self.labelTextPoint1.text = __("GUILD_NEW_WAR_TEXT71")
	self.labelTextPoint2.text = __("GUILD_NEW_WAR_TEXT72")
	local scoreSelf = 0
	local scoreEnemy = 0

	if params.scoreSelf then
		scoreSelf = params.scoreSelf > 0 and "+" .. tostring(params.scoreSelf) or params.scoreSelf
	end

	if params.scoreEnemy then
		scoreEnemy = params.scoreEnemy > 0 and "-" .. tostring(params.scoreEnemy) or params.scoreEnemy
	end

	self.labelPoint1.text = scoreSelf
	self.labelPoint2.text = scoreEnemy

	if params.is_win == true then
		self.currentState = "win"

		self:setState("win")
	else
		self.currentState = "lose"

		self:setState("lose")
	end
end

function GuildNewWarRecordItem:setState(state)
	if state == "win" then
		self.winImage:SetActive(true)
		self.loseImage:SetActive(false)

		self.labelPoint1.color = Color.New2(915996927)
		self.labelPoint2.color = Color.New2(3422556671.0)
	else
		self.winImage:SetActive(false)
		self.loseImage:SetActive(true)

		self.labelPoint1.color = Color.New2(915996927)
		self.labelPoint2.color = Color.New2(3422556671.0)
	end
end

function GuildNewWarRecordItem:onclickVideo()
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.GUILD_NEW_WAR_FIGHT_RECORD,
		data = self.data.event_data
	})
end

function GuildNewWarRecordItem:onclickAvatar()
	xyd.WindowManager:get():openWindow("arena_3v3_record_detail_window", {
		report_ids = self.data.record_ids,
		model = self.activityData,
		windowType = xyd.Record3v3Type.GUILD_NEW_WAR
	})
end

return GuildNewWarRecordWindow
