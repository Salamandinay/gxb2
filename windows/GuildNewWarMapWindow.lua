local BaseWindow = import(".BaseWindow")
local GuildNewWarMapWindow = class("GuildNewWarMapWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")
local WindowTop = import("app.components.WindowTop")

function GuildNewWarMapWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function GuildNewWarMapWindow:initWindow()
	GuildNewWarMapWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)

	self.activityData:reqFlagInfo()

	self.roleModels = {}

	self:getUIComponent()
	self:reSize()
	self:registerEvent()
	self:layout()
end

function GuildNewWarMapWindow:reSize()
	self:resizePosY(self.rightGroup, 130, 12)
	self:resizePosY(self.btnClose, 109, -9)
	self:resizePosY(self.tiaofuGroup, 266, 148)
end

function GuildNewWarMapWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.btnHelp = self.topGroup:NodeByName("content/btnHelp").gameObject
	self.toatlInfoPanel = self.topGroup:NodeByName("content/toatlInfoPanel").gameObject
	self.content = self.toatlInfoPanel:NodeByName("content").gameObject
	self.bg = self.content:ComponentByName("bg", typeof(UISprite))
	self.imgVS = self.content:ComponentByName("imgVS", typeof(UISprite))
	self.progressGroup = self.topGroup:NodeByName("content/progressGroup").gameObject
	self.progressBar = self.progressGroup:ComponentByName("progressBar", typeof(UISprite))
	self.progressImg1 = self.progressBar:ComponentByName("progressImg1", typeof(UISprite))
	self.progressImg2 = self.progressBar:ComponentByName("progressImg2", typeof(UISprite))
	self.imgPoint = self.progressBar:ComponentByName("imgPoint", typeof(UISprite))
	self.readyTimeGroup = self.progressGroup:NodeByName("readyTimeGroup").gameObject
	self.readyTimeGroupLayout = self.progressGroup:ComponentByName("readyTimeGroup", typeof(UILayout))
	self.readyTimeDescLabel_ = self.readyTimeGroup:ComponentByName("descLabel_", typeof(UILabel))
	self.readyTimeTimeLabel_ = self.readyTimeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.battleTimeGroup = self.progressGroup:NodeByName("battleTimeGroup").gameObject
	self.battleTimeGroupLayout = self.progressGroup:ComponentByName("battleTimeGroup", typeof(UILayout))
	self.battleTimeDescLabel_ = self.battleTimeGroup:ComponentByName("descLabel_", typeof(UILabel))
	self.battleTimeTimeLabel_ = self.battleTimeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.guildInfo1 = self.content:NodeByName("guildInfo1").gameObject
	self.guildInfo2 = self.content:NodeByName("guildInfo2").gameObject
	self.btnExpend = self.content:NodeByName("btnExpend").gameObject
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.btnClose = self.bottomGroup:NodeByName("content/btnClose").gameObject
	self.labelClose = self.btnClose:ComponentByName("labelClose", typeof(UILabel))
	self.rightGroup = self.bottomGroup:ComponentByName("content/rightGroup", typeof(UIGrid))
	self.btnDefFormation = self.bottomGroup:NodeByName("content/rightGroup/btnDefFormation").gameObject
	self.labelDefFormation = self.btnDefFormation:ComponentByName("labelDefFormation", typeof(UILabel))
	self.btnDefFormationRedPoint = self.btnDefFormation:ComponentByName("redPoint", typeof(UISprite))
	self.btnRecord = self.bottomGroup:NodeByName("content/rightGroup/btnRecord").gameObject
	self.labelRecord = self.btnRecord:ComponentByName("labelRecord", typeof(UILabel))
	self.btnRecordRedPoint = self.btnRecord:ComponentByName("redPoint", typeof(UISprite))
	self.btnChat = self.bottomGroup:NodeByName("content/rightGroup/btnChat").gameObject
	self.labelChat = self.btnChat:ComponentByName("labelChat", typeof(UILabel))
	self.btnChatRedPoint = self.btnChat:ComponentByName("redPoint", typeof(UISprite))
	self.btnAward = self.bottomGroup:NodeByName("content/rightGroup/btnAward").gameObject
	self.labelAward = self.btnAward:ComponentByName("labelAward", typeof(UILabel))
	self.btnRank = self.bottomGroup:NodeByName("content/rightGroup/btnRank").gameObject
	self.labelRank = self.btnRank:ComponentByName("labelRank", typeof(UILabel))
	self.tiaofuGroup = self.bottomGroup:NodeByName("content/tiaofuGroup").gameObject
	self.labelAttackTime = self.tiaofuGroup:ComponentByName("labelAttackTime", typeof(UILabel))
	self.labelSelfPoint = self.tiaofuGroup:ComponentByName("labelSelfPoint", typeof(UILabel))
	self.mapGoup = self.groupAction:NodeByName("mapGoup").gameObject
	self.mapScroller = self.mapGoup:NodeByName("mapScroller").gameObject
	self.mapPanel = self.mapGoup:ComponentByName("mapScroller", typeof(UIPanel))
	self.mapScrollview = self.mapGoup:ComponentByName("mapScroller", typeof(UIScrollView))
	self.nodeGroup = self.mapScroller:NodeByName("nodeGroup").gameObject
	self.imgAim = self.mapScroller:ComponentByName("imgAim", typeof(UISprite))

	for i = 1, 12 do
		self["mapNode" .. i] = self.nodeGroup:NodeByName("mapNode" .. i).gameObject
	end

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.GUILD_NEW_WAR_BATTLE_MESSAGE_RED
	}, self.btnRecordRedPoint.gameObject)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.GUILD_NEW_WAR_CHAT_RED
	}, self.btnChatRedPoint.gameObject)
end

function GuildNewWarMapWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GUILD_NEW_WAR_FIGHT, function (event)
		local data = xyd.decodeProtoBuf(event.data)

		self:updateCountDown()
		self:updateGuildInfo()
		self:updateMapNodes()
	end)
	self.eventProxy_:addEventListener(xyd.event.GUILD_NEW_WAR_SWEEP, function (event)
		local data = xyd.decodeProtoBuf(event.data)

		self:updateCountDown()
		self:updateGuildInfo()
	end)
	self.eventProxy_:addEventListener(xyd.event.GUILD_NEW_WAR_SET_TEAMS, function (event)
		self:updateRedPoint()
	end)

	UIEventListener.Get(self.btnHelp.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "GUILD_NEW_WAR_HELP01"
		})
	end

	UIEventListener.Get(self.btnClose.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnDefFormation:NodeByName("btnDefFormation").gameObject).onClick = function ()
		local needStage = xyd.tables.miscTable:getNumber("guild_new_war_join_limit", "value")
		local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
		local maxStage = nil

		if mapInfo then
			maxStage = mapInfo.max_stage
		else
			maxStage = 0
		end

		if needStage <= maxStage then
			xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
				showSkip = false,
				battleType = xyd.BattleType.GUILD_NEW_WAR_DEF,
				formation = self.activityData:getDefFormation()
			})
		else
			local fortId = xyd.tables.stageTable:getFortID(needStage)
			local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(needStage))

			xyd.showToast(__("FUNC_OPEN_STAGE", text))
		end
	end

	UIEventListener.Get(self.btnChat:NodeByName("btnChat").gameObject).onClick = function ()
		xyd.db.misc:setValue({
			key = "guild_new_war_chat_red_time",
			value = xyd.getServerTime()
		})
		self.activityData:checkChatBtnRedPoint()

		local wnd = xyd.WindowManager.get():openWindow("chat_window")

		wnd:onTopTouch(7)
		wnd:specialShowGuildLabFromGuildNewWar()
	end

	UIEventListener.Get(self.btnRecord:NodeByName("btnRecord").gameObject).onClick = function ()
		local function messageBack(data)
			xyd.WindowManager.get():openWindow("guild_new_war_fight_info_window", {
				messageInfo = data
			})
		end

		self.activityData:reqMessageInfoList(messageBack)
	end

	UIEventListener.Get(self.btnRank:NodeByName("btnRank").gameObject).onClick = function ()
		local function rankBack(data)
			xyd.WindowManager.get():openWindow("guild_new_war_main_rank_window", {
				state = xyd.GuildNewWarMainRankType.RANK_RANK,
				guildInfo = data
			})
		end

		self.activityData:reqGuildRankList(rankBack)
	end

	UIEventListener.Get(self.btnAward:NodeByName("btnAward").gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("guild_new_war_rank_window")
	end

	UIEventListener.Get(self.btnExpend.gameObject).onClick = function ()
		if not self.expandState then
			self.expandState = false
		end

		self.expandState = not self.expandState

		if self.expandStateMoveSequence then
			self.expandStateMoveSequence:Kill(false)

			self.expandStateMoveSequence = nil
		end

		self.expandStateMoveSequence = self:getSequence()
		local oldX = self.content.gameObject.transform.localPosition.x
		local btnImg = self.btnExpend:ComponentByName("", typeof(UISprite))

		if self.expandState then
			xyd.setUISpriteAsync(btnImg, nil, "guild_new_war_btn_xiala_1")
			self.expandStateMoveSequence:Insert(0, self.content.gameObject.transform:DOLocalMove(Vector3(oldX, 211, 0), 0.3, false))
		else
			xyd.setUISpriteAsync(btnImg, nil, "guild_new_war_btn_xiala_2")
			self.expandStateMoveSequence:Insert(0, self.content.gameObject.transform:DOLocalMove(Vector3(oldX, 72, 0), 0.3, false))
		end
	end
end

function GuildNewWarMapWindow:layout()
	self.labelAward.text = __("GUILD_NEW_WAR_TEXT13")
	self.labelClose.text = __("RETURN")
	self.labelDefFormation.text = __("GUILD_NEW_WAR_TEXT18")
	self.labelRecord.text = __("GUILD_NEW_WAR_TEXT19")
	self.labelChat.text = __("GUILD_NEW_WAR_TEXT20")
	self.labelAward.text = __("GUILD_NEW_WAR_TEXT21")
	self.labelRank.text = __("GUILD_NEW_WAR_TEXT94")

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		self.labelDefFormation.fontSize = 17
		self.labelRecord.fontSize = 17
		self.labelChat.fontSize = 17
		self.labelAward.fontSize = 17
		self.labelRank.fontSize = 17
	end

	local winTop = WindowTop.new(self.window_, self.name_, 1, true)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	winTop:setItem(items)

	self.windowTop = winTop

	self:updateCountDown()
	self:updateGuildInfo()
	self:updateMapNodes()
	self:updateAimImage()
	self:updateRedPoint()
	self.topGroup:SetActive(false)
	self:waitForFrame(1, function ()
		self.topGroup:SetActive(true)
	end)
	self.activityData:reqMessageInfoList(nil)
	self.activityData:checkChatBtnRedPoint()
end

function GuildNewWarMapWindow:updateCountDown()
	local nowTime = xyd.getServerTime()
	local curPeriod, curPeriodEndTime = nil
	curPeriod, curPeriodEndTime = self.activityData:getCurPeriod()
	local nowTime = xyd.getServerTime()
	local duration1 = 0
	local duration2 = 0
	local duration3 = 0

	if curPeriod == xyd.GuildNewWarPeroid.READY1 or curPeriod == xyd.GuildNewWarPeroid.READY2 then
		duration2 = curPeriodEndTime - nowTime

		self.btnRank:SetActive(false)

		self.btnDefFormation:ComponentByName("bg", typeof(UISprite)).width = 161
		self.btnChat:ComponentByName("bg", typeof(UISprite)).width = 154
		self.btnRank:ComponentByName("bg", typeof(UISprite)).width = 154
		self.btnRecord:ComponentByName("bg", typeof(UISprite)).width = 154
		self.btnAward:ComponentByName("bg", typeof(UISprite)).width = 154

		if xyd.Global.lang == "fr_fr" then
			self.labelAward.width = 130
		elseif xyd.Global.lang == "ja_jp" then
			self.labelRecord.width = 130
		elseif xyd.Global.lang == "de_de" then
			self.labelRecord.width = 130
			self.labelDefFormation.width = 120
			self.labelChat.width = 120
			self.labelRank.width = 120
			self.labelAward.width = 120
		elseif xyd.Global.lang ~= "ko_kr" and xyd.Global.lang ~= "zh_tw" then
			self.labelDefFormation.height = 52
			self.labelRecord.height = 52
			self.labelAward.height = 52
			self.labelChat.height = 52
			self.labelRank.height = 52

			if xyd.Global.lang ~= "en_en" then
				self.labelDefFormation.fontSize = 20
				self.labelRecord.fontSize = 20
				self.labelAward.fontSize = 20
				self.labelChat.fontSize = 20
				self.labelRank.fontSize = 20
			end
		end

		self.rightGroup.cellWidth = 154

		self.rightGroup:Reposition()
		self.tiaofuGroup:SetActive(false)
	elseif curPeriod == xyd.GuildNewWarPeroid.FIGHTING1 or curPeriod == xyd.GuildNewWarPeroid.FIGHTING2 then
		duration3 = curPeriodEndTime - nowTime

		self.btnRank:SetActive(true)

		self.btnDefFormation:ComponentByName("bg", typeof(UISprite)).width = 143
		self.btnChat:ComponentByName("bg", typeof(UISprite)).width = 150
		self.btnRank:ComponentByName("bg", typeof(UISprite)).width = 118
		self.btnRecord:ComponentByName("bg", typeof(UISprite)).width = 118
		self.btnAward:ComponentByName("bg", typeof(UISprite)).width = 118

		if xyd.Global.lang == "fr_fr" then
			self.labelAward.width = 125
			self.labelRank.width = 110
			self.labelRecord.fontSize = 17
			self.labelDefFormation.fontSize = 17
			self.labelAward.fontSize = 17
			self.labelChat.fontSize = 17
			self.labelRank.fontSize = 17
		elseif xyd.Global.lang == "de_de" then
			self.labelRecord.width = 110
			self.labelRecord.fontSize = 16
			self.labelDefFormation.fontSize = 16
			self.labelAward.fontSize = 16
			self.labelChat.fontSize = 16
			self.labelRank.fontSize = 16
		elseif xyd.Global.lang == "ja_jp" then
			self.labelRecord.width = 110
			self.labelRecord.fontSize = 18
			self.labelDefFormation.fontSize = 18
			self.labelAward.fontSize = 18
			self.labelChat.fontSize = 18
			self.labelRank.fontSize = 18
		elseif xyd.Global.lang == "en_en" then
			self.labelRecord.height = 52
			self.labelDefFormation.height = 52
			self.labelAward.height = 52
			self.labelChat.height = 52
			self.labelRank.height = 52
		end

		self.rightGroup:X(58)

		self.rightGroup.cellWidth = 118

		self.rightGroup:Reposition()
		self.tiaofuGroup:SetActive(true)

		local helpData2 = xyd.tables.miscTable:split2Cost("guild_new_war_attack_times", "value", "|")
		local leftTime = self.activityData:getLeftAttackTime()
		local selfPoint = self.activityData:getSelfPoint()
		self.labelSelfPoint.text = __("GUILD_NEW_WAR_TEXT37", selfPoint)
		self.labelAttackTime.text = __("GUILD_NEW_WAR_TEXT38", leftTime, helpData2[2])
	end

	self.readyTimeGroup:SetActive(duration2 > 0)

	if duration2 > 0 and not self.countDown2 then
		self.countDown2 = CountDown.new(self.readyTimeTimeLabel_, {
			duration = duration2,
			callback = function ()
				self:updateCountDown()
			end
		})
		self.readyTimeDescLabel_.text = __("GUILD_NEW_WAR_TEXT08")

		self.readyTimeGroupLayout:Reposition()
	end

	self.battleTimeGroup:SetActive(duration3 > 0)

	if duration3 > 0 and not self.countDown3 then
		self.countDown3 = CountDown.new(self.battleTimeTimeLabel_, {
			duration = duration3,
			callback = function ()
				self:updateCountDown()
			end
		})
		self.battleTimeDescLabel_.text = __("GUILD_NEW_WAR_TEXT09")

		self.battleTimeGroupLayout:Reposition()
	end

	if duration2 > 0 then
		self.progressImg1.fillAmount = 1 - duration2 / xyd.DAY_TIME
	else
		self.progressImg1.fillAmount = 1
	end

	if duration3 > 0 then
		self.progressImg2.fillAmount = 1 - duration3 / (2 * xyd.DAY_TIME)

		self.imgPoint:SetActive(true)
	else
		self.progressImg2.fillAmount = 0

		self.imgPoint:SetActive(false)
	end
end

function GuildNewWarMapWindow:updateGuildInfo()
	local data = self.activityData:getVsTotalData()

	for i = 1, 2 do
		local info = data.baseInfo[i]
		local guild = self["guildInfo" .. i]
		local labelGuildName = guild:ComponentByName("labelName", typeof(UILabel))
		local flagGuild = guild:ComponentByName("imgFlag", typeof(UISprite))
		local labelPoint = guild:ComponentByName("labelPoint", typeof(UILabel))
		local labelMvp = guild:ComponentByName("labelMvp", typeof(UILabel))
		labelGuildName.text = info.guildName

		xyd.setUISpriteAsync(flagGuild, nil, xyd.tables.guildIconTable:getIcon(info.flag))

		labelPoint.text = info.point

		if info.MvpName then
			labelMvp.text = info.MvpName
		else
			labelMvp.text = __("GUILD_NEW_WAR_TEXT47")
		end
	end
end

function GuildNewWarMapWindow:updateMapNodes()
	local datas = self.activityData:getMapNodeDatas()
	local curPeriod = self.activityData:getCurPeriod()

	for i = 1, 12 do
		local data = datas[i]
		local node = self["mapNode" .. i]
		local labelState = node:ComponentByName("label", typeof(UILabel))
		local rolePos = node:ComponentByName("rolePos", typeof(UITexture))
		local imgFlag = node:ComponentByName("bg", typeof(UISprite))
		local progressGroup = node:NodeByName("progressGroup").gameObject
		local progressBar = progressGroup:ComponentByName("progressBar", typeof(UISprite))
		local progressBarCom = progressGroup:ComponentByName("progressBar", typeof(UIProgressBar))
		local progressImg = progressBar:ComponentByName("progressImg", typeof(UISprite))
		local labelProgressValue = progressGroup:ComponentByName("labelProgressValue", typeof(UILabel))

		labelProgressValue:SetActive(false)

		imgFlag.depth = 110 + 10 * i - 1
		rolePos.depth = 110 + 10 * i

		if not self.roleModels[i] then
			self.roleModels[i] = import("app.components.SenpaiModel").new(rolePos.gameObject)

			UIEventListener.Get(node.gameObject).onClick = function ()
				xyd.WindowManager:get():openWindow("guild_new_war_preview_window", {
					nodeIndex = i
				})
			end
		end

		local isDestoy = true

		for j = 1, #data.flagInfos do
			if data.flagInfos[j].HP > 0 then
				isDestoy = false
			end
		end

		local spriteName = self.activityData:getFlagImgName(i <= 6, i, isDestoy)

		xyd.setUISpriteAsync(imgFlag, nil, spriteName, function ()
			imgFlag.gameObject.transform.localScale = Vector3(0.8476190476190476, 0.8476190476190476, 0)
		end, nil, true)

		if data.dress_style then
			rolePos:SetActive(true)
			self.roleModels[i]:setModelInfo({
				isNewClipShader = true,
				ids = data.dress_style,
				panel = self.mapPanel,
				pos = Vector3(0, -150, 0),
				textureSize = Vector2(2, 300)
			})
		else
			rolePos:SetActive(false)
		end

		if curPeriod == xyd.GuildNewWarPeroid.READY1 or curPeriod == xyd.GuildNewWarPeroid.READY2 then
			labelState:SetActive(true)
			progressGroup:SetActive(false)

			labelState.text = __("GUILD_NEW_WAR_TEXT17", data.curMemberNum, data.limitMemberNum)

			if data.curMemberNum <= 0 then
				rolePos:SetActive(false)
			else
				rolePos:SetActive(true)
			end
		elseif curPeriod == xyd.GuildNewWarPeroid.FIGHTING1 or curPeriod == xyd.GuildNewWarPeroid.FIGHTING2 then
			labelState:SetActive(false)
			progressGroup:SetActive(true)

			progressBarCom.value = data.curFlagNum / data.maxFlagNum
			labelProgressValue.text = data.curFlagNum .. "/" .. data.maxFlagNum

			if data.curFlagNum <= 0 then
				progressGroup:SetActive(false)
			end

			if data.curMemberNum <= 0 then
				rolePos:SetActive(false)
			else
				rolePos:SetActive(true)
			end
		end
	end
end

function GuildNewWarMapWindow:updateAimImage()
	local baseInfo = self.activityData:getBaseInfo()
	local aimNodeID = baseInfo.rally

	if aimNodeID and aimNodeID > 0 then
		aimNodeID = aimNodeID + 6
		self.imgAim.gameObject.transform.parent = self["mapNode" .. aimNodeID].gameObject.transform

		self.imgAim:X(10)
		self.imgAim:Y(-100)
		self.imgAim:SetActive(true)
	else
		self.imgAim:SetActive(false)
	end
end

function GuildNewWarMapWindow:updateRedPoint()
	self.btnDefFormationRedPoint:SetActive(self.activityData:checkRedPointSelfDefFormation())
end

return GuildNewWarMapWindow
