local ArenaAllServer = xyd.models.arenaAllServerNew
local ArenaAllServerAwardTable = xyd.tables.arenaAllServerAwardTable
local cjson = require("cjson")
local CountDown = import("app.components.CountDown")
local DEFEND_END_TIME = 7200
local HonorHallItem = class("HonorHallItem")
local PlayerIcon = import("app.components.PlayerIcon")

function HonorHallItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	xyd.setDragScrollView(go, parent.honorScrollView)
	self:initUI()
	self.go:SetActive(false)
end

function HonorHallItem:getGameObject()
	return self.go
end

function HonorHallItem:initUI()
	self.playerIconPos = self.go:NodeByName("playerIconPos").gameObject
	self.labelPlayerName = self.go:ComponentByName("labelPlayerName", typeof(UILabel))
	self.playerIcon_ = PlayerIcon.new(self.playerIconPos)
end

function HonorHallItem:update(wrapIndex, index, info)
	if not info or type(info) == "number" or not info.player_id then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo()
end

function HonorHallItem:updateInfo()
	if not self.data then
		return
	end

	if not self.data.avatar_frame_id then
		return
	end

	local playerInfo = self.data
	self.labelPlayerName.text = playerInfo.player_name
	local playerIcon = self.playerIcon_

	playerIcon:setInfo({
		scale = 0.8596491228070176,
		avatarID = playerInfo.avatar_id,
		avatar_frame_id = playerInfo.avatar_frame_id,
		lev = playerInfo.lev,
		dragScrollView = self.parent.honorScrollView,
		callback = function ()
			if self.data.player_id ~= xyd.Global.playerID then
				xyd.WindowManager:get():openWindow("arena_formation_window", {
					not_show_black_btn = true,
					show_close_btn = true,
					not_show_mail = true,
					not_show_private_chat = true,
					add_friend = false,
					show_short_bg = true,
					is_robot = false,
					player_id = playerInfo.player_id,
					server_id = playerInfo.server_id
				})
			end
		end
	})
end

local HonorHallSeasonItem = class("HonorHallSeasonItem")

function HonorHallSeasonItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	xyd.setDragScrollView(go, parent.seasonScrollView)
	self:initUI()
end

function HonorHallSeasonItem:getGameObject()
	return self.go
end

function HonorHallSeasonItem:initUI()
	self.label = self.go:ComponentByName("label", typeof(UILabel))
	UIEventListener.Get(self.go).onClick = handler(self, self.onClickSeasonItem)
end

function HonorHallSeasonItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo()
end

function HonorHallSeasonItem:updateInfo()
	self.label.text = __("NEW_ARENA_ALL_SERVER_TEXT_27", self.data)
	local list = ArenaAllServer:getHistoryRank()

	if self.data == self.parent.maxSeason then
		self.go:ComponentByName("line", typeof(UISprite)).gameObject:SetActive(false)
	else
		self.go:ComponentByName("line", typeof(UISprite)).gameObject:SetActive(true)
	end
end

function HonorHallSeasonItem:onClickSeasonItem()
	self.parent:chooseSeason(tonumber(self.data))
end

local HonorHalls = class("HonorHalls", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function HonorHalls:ctor(go)
	HonorHalls.super.ctor(self, go)

	self.curIndex_ = 1
	self.contentTouchPoint = {
		x = 0,
		y = 0
	}
	self.isMove_ = false

	xyd.models.arenaAllServerNew:reqGetHallRank()
end

function HonorHalls:initUI()
	HonorHalls.super.initUI(self)

	local top = self.go:NodeByName("top").gameObject
	self.btnHelp = top:NodeByName("btnHelp").gameObject
	self.imgTitle_ = top:ComponentByName("imgTitle_", typeof(UISprite))
	self.btnRecord_ = top:NodeByName("btnRecord_").gameObject
	self.btnChooseSeason = top:NodeByName("btnChooseSeason").gameObject
	self.seasonScrollerGroup = self.btnChooseSeason:NodeByName("seasonScrollerGroup").gameObject
	self.seasonScrollView = self.seasonScrollerGroup:ComponentByName("seasonScroller", typeof(UIScrollView))
	self.seasonWrapContent = self.seasonScrollView:ComponentByName("itemList_", typeof(UIWrapContent))
	self.seasonItem = self.btnChooseSeason:NodeByName("seasonItem").gameObject
	local group1_ = self.go:NodeByName("group1_").gameObject
	self.groupNone_ = group1_:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	local group2_ = self.go:NodeByName("group2_").gameObject
	self.awardList_ = group2_:NodeByName("main/awardList_").gameObject
	self.awardItem = self.awardList_:NodeByName("item").gameObject

	self.awardItem:SetActive(false)

	self.labelAwardTips_ = group2_:ComponentByName("main/labelAwardTips_", typeof(UILabel))
	self.btnGetAward_ = group2_:NodeByName("main/btnGetAward_").gameObject
	self.btnMask_ = group2_:NodeByName("main/btnMask_").gameObject
	self.imgGet_ = group2_:ComponentByName("main/imgGet_", typeof(UISprite))
	self.awardDrag = group2_:NodeByName("main/awardDrag").gameObject
	self.group3_ = self.go:NodeByName("group3_").gameObject
	self.honorScrollView = self.group3_:ComponentByName("honorScroller", typeof(UIScrollView))
	local top1WrapContent = self.honorScrollView:ComponentByName("top1Group/itemGroup", typeof(UIWrapContent))
	local top4WrapContent = self.honorScrollView:ComponentByName("top4Group/itemGroup", typeof(UIWrapContent))
	local top8WrapContent = self.honorScrollView:ComponentByName("top8Group/itemGroup", typeof(UIWrapContent))
	self.top1Grid = self.honorScrollView:ComponentByName("top1Group/itemGroup", typeof(UIGrid))
	self.top4Grid = self.honorScrollView:ComponentByName("top4Group/itemGroup", typeof(UIGrid))
	self.top8Grid = self.honorScrollView:ComponentByName("top8Group/itemGroup", typeof(UIGrid))
	self.honorItem = self.group3_:NodeByName("honorItem").gameObject
	self.top1WrapContent_ = FixedMultiWrapContent.new(self.honorScrollView, top1WrapContent, self.honorItem, HonorHallItem, self)
	self.top4WrapContent_ = FixedMultiWrapContent.new(self.honorScrollView, top4WrapContent, self.honorItem, HonorHallItem, self)
	self.top8WrapContent_ = FixedMultiWrapContent.new(self.honorScrollView, top8WrapContent, self.honorItem, HonorHallItem, self)

	self:registerEvent()
end

function HonorHalls:setInfo()
	self:layout()
end

function HonorHalls:openAnimation()
end

function HonorHalls:resetPos()
end

function HonorHalls:layout()
	self.labelNoneTips_.text = __("ARENA_ALL_SERVER_TEXT_4")
	self.honorScrollView:ComponentByName("top1Group/titleGroup/labelTitle", typeof(UILabel)).text = __("ARENA_ALL_SERVER_TEXT_17")
	self.honorScrollView:ComponentByName("top4Group/titleGroup/labelTitle", typeof(UILabel)).text = __("ARENA_ALL_SERVER_TEXT_18")
	self.honorScrollView:ComponentByName("top8Group/titleGroup/labelTitle", typeof(UILabel)).text = __("ARENA_ALL_SERVER_TEXT_19")

	xyd.setUISpriteAsync(self.imgTitle_, nil, "arena_as_title_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.imgGet_, nil, "arena_as_get_" .. xyd.Global.lang)
end

function HonorHalls:update()
	self:initRankList()
end

function HonorHalls:registerEvent()
	UIEventListener.Get(self.btnRecord_).onClick = handler(self, self.onRecordTouch)
	UIEventListener.Get(self.btnHelp).onClick = handler(self, self.onHelpTouch)
	UIEventListener.Get(self.btnChooseSeason).onClick = handler(self, self.onChooseSeasonTouch)
end

function HonorHalls:onHelpTouch()
	xyd.WindowManager.get():openWindow("arena_all_server_fight_award_preview_window", {})
end

function HonorHalls:onRecordTouch()
	xyd.WindowManager.get():openWindow("arena_all_server_pre_champion_window")
end

function HonorHalls:onChooseSeasonTouch()
	if not self.seasonWrapContent_ then
		self.seasonWrapContent_ = FixedWrapContent.new(self.seasonScrollView, self.seasonWrapContent, self.seasonItem, HonorHallSeasonItem, self)
	end

	if self.choosingSeason ~= true then
		self.choosingSeason = true

		self.seasonScrollerGroup:SetActive(true)

		local infos = ArenaAllServer:getSeasons()
		local bg = self.seasonScrollerGroup:ComponentByName("bgGroup/bg", typeof(UISprite))

		if #infos < 5 then
			bg.height = 20 + 30 * #infos
		else
			bg.height = 170
		end

		self.seasonWrapContent_:setInfos(infos, {})
		self.seasonScrollView:ResetPosition()

		self.btnChooseSeason:NodeByName("icon1").gameObject.transform.localEulerAngles = Vector3(0, 0, -90)
	else
		self.choosingSeason = false

		self.seasonScrollerGroup:SetActive(false)

		self.btnChooseSeason:NodeByName("icon1").gameObject.transform.localEulerAngles = Vector3(0, 0, 90)
	end

	self.seasonScrollView:Y(-10)
end

function HonorHalls:initRankList()
	local list = ArenaAllServer:getHistoryRank()

	if list == nil or #list == 0 or not list[1] or #list[1].area_list == 0 then
		self.groupNone_:SetActive(true)
		self.group3_:SetActive(false)
		self.btnChooseSeason:SetActive(false)

		self.btnChooseSeason:ComponentByName("labelSeason", typeof(UILabel)).text = "????"

		return
	else
		self.btnChooseSeason:SetActive(true)
		self.groupNone_:SetActive(false)
		self.group3_:SetActive(true)
	end

	local playerInfos = {}
	local top1Infos = {}
	local top4Infos = {}
	local top8Infos = {}

	if not self.chooseSeasonID then
		if #list[1].area_list ~= 0 and list[1].area_list[#list[1].area_list] and list[1].area_list[#list[1].area_list].index then
			self.chooseSeasonID = list[1].area_list[#list[1].area_list].index
			self.maxSeason = self.chooseSeasonID
			self.btnChooseSeason:ComponentByName("labelSeason", typeof(UILabel)).text = __("NEW_ARENA_ALL_SERVER_TEXT_27", self.chooseSeasonID)
		else
			self.btnChooseSeason:ComponentByName("labelSeason", typeof(UILabel)).text = "????"
		end
	end

	for j = 1, #list do
		for i = 1, #list[j].area_list do
			if list[j].area_list[i].index == self.chooseSeasonID then
				for k = 1, #list[j].area_list[i].player_infos do
					table.insert(playerInfos, list[j].area_list[i].player_infos[k])
				end
			end
		end
	end

	for i = 1, #playerInfos do
		if i % 8 == 1 then
			table.insert(top1Infos, playerInfos[i])
		elseif i % 8 <= 4 and i % 8 ~= 0 then
			table.insert(top4Infos, playerInfos[i])
		elseif i % 8 < 8 or i % 8 == 0 then
			table.insert(top8Infos, playerInfos[i])
		end
	end

	if top1Infos and not top1Infos[1] then
		-- Nothing
	end

	local defaultY_top4 = 10
	local defaultY_top8 = -494
	local defaultHeight_top1 = 210
	local defaultHeight_top4 = 486
	local defaultHeight_top8 = 620
	local offset_top1 = math.floor((5 - #top1Infos) / 5) * 134
	self.honorScrollView:ComponentByName("top1Group", typeof(UIWidget)).height = defaultHeight_top1 - offset_top1

	self.honorScrollView:ComponentByName("top4Group", typeof(UIWidget)):Y(defaultY_top4 + offset_top1)

	local offset_top4 = math.floor((15 - #top4Infos) / 5) * 134
	self.honorScrollView:ComponentByName("top4Group", typeof(UIWidget)).height = defaultHeight_top4 - offset_top4

	self.honorScrollView:ComponentByName("top8Group", typeof(UIWidget)):Y(defaultY_top8 + offset_top4 + offset_top1)

	local offset_top8 = math.floor((20 - #top8Infos) / 5) * 134
	self.honorScrollView:ComponentByName("top8Group", typeof(UIWidget)).height = defaultHeight_top8 - offset_top8

	self.top1WrapContent_:setInfos(top1Infos, {})
	self.top4WrapContent_:setInfos(top4Infos, {})
	self.top8WrapContent_:setInfos(top8Infos, {})
	self.top1Grid:Reposition()
	self.top4Grid:Reposition()
	self.top8Grid:Reposition()
end

function HonorHalls:chooseSeason(seasonID)
	self.btnChooseSeason:ComponentByName("labelSeason", typeof(UILabel)).text = __("NEW_ARENA_ALL_SERVER_TEXT_27", seasonID)
	self.choosingSeason = false

	self.seasonScrollerGroup:SetActive(false)

	self.chooseSeasonID = seasonID

	self:initRankList()
end

local ArenaAllServerFightList = class("ArenaAllServerFightList", import("app.components.BaseComponent"))
local AllServerPlayerIcon = import("app.components.AllServerPlayerIcon")

function ArenaAllServerFightList:ctor(parentGo)
	ArenaAllServerFightList.super.ctor(self, parentGo)

	self.curPage_ = 1
	self.roundIndex = 0
	self.arryPath = {
		[2] = {
			{
				sy = 1,
				sx = 1,
				x = -78,
				y = 225
			},
			{
				sy = 1,
				sx = -1,
				x = 78,
				y = 225
			},
			{
				sy = -1,
				sx = 1,
				x = -78,
				y = -225
			},
			{
				sy = -1,
				sx = -1,
				x = 78,
				y = -225
			}
		},
		[3] = {
			{
				sy = 1,
				sx = 1,
				x = 0,
				y = 100
			},
			{
				sy = -1,
				sx = 1,
				x = 0,
				y = -100
			}
		}
	}
end

function ArenaAllServerFightList:getPrefabPath()
	return "Prefabs/Components/arena_all_server_fight_list"
end

function ArenaAllServerFightList:initUI()
	ArenaAllServerFightList.super.initUI(self)

	self.groupPath = self.go:NodeByName("groupPath").gameObject
	self.groupEffect = self.go:NodeByName("groupEffect").gameObject
	self.groupNoneItem = self.go:NodeByName("groupNoneItem").gameObject

	self.groupNoneItem:SetActive(false)

	for i = 1, 4 do
		local img = self.go:ComponentByName("imgRoad" .. i, typeof(UISprite))

		xyd.setUISpriteAsync(img, nil, "arena_as_road")
	end
end

function ArenaAllServerFightList:setInfo(params)
	self.curPage_ = params.cur_page
	self.roundIndex = params.round_index or 0
	self.zone_id_ = params.zone_id or 1

	self:layout()
end

function ArenaAllServerFightList:layout()
	local curPage = self.curPage_

	for i = 1, 8 do
		local group = self.go:NodeByName("groupD" .. i).gameObject
		local index = (curPage - 1) * 8 + i

		self:getItem(0, index, group)
	end

	for i = 1, 4 do
		local group = self.go:NodeByName("groupC" .. i).gameObject
		local index = (curPage - 1) * 4 + i

		self:getItem(1, index, group)
	end

	for i = 1, 2 do
		local group = self.go:NodeByName("groupB" .. i).gameObject
		local index = (curPage - 1) * 2 + i

		self:getItem(2, index, group)
	end

	local group = self.go:NodeByName("groupA1").gameObject
	local index = curPage

	self:getItem(3, index, group)
	self:initPath()
end

function ArenaAllServerFightList:getItem(round, index, parent)
	local rounds = ArenaAllServer:getRounds(self.zone_id_)
	local trueRound = round + self.roundIndex
	local curRoundInfo = rounds[tostring(trueRound)] or {}
	local winIDs = curRoundInfo.win_ids or {}
	local reportIDs = curRoundInfo.report_ids or {}

	if winIDs[index] and winIDs[index] > 0 then
		local isShowVideo = round ~= 0
		local isShowQuiz = false
		local betInfo = ArenaAllServer:getCurRoundBetInfo()
		local curRound = ArenaAllServer:getCurRound()

		if trueRound == curRound - 1 and betInfo and betInfo.win_player_id and betInfo.win_player_id == winIDs[index] then
			isShowQuiz = true
		end

		self:getPlayerItem(winIDs[index], parent, reportIDs[index], isShowVideo, isShowQuiz, trueRound)
	else
		local item = self:getNoneItem(parent, trueRound)

		if trueRound == 6 then
			local effect = xyd.Spine.new(parent)
			local frameBg = item:ComponentByName("imgFrame", typeof(UITexture))

			effect:setInfo("ultimate_arena_frame", function ()
				effect:setRenderTarget(frameBg, 2)
				effect:play("texiao01", 0)
			end)
		end
	end
end

function ArenaAllServerFightList:getNoneItem(parentNode, round)
	local group = NGUITools.AddChild(parentNode, self.groupNoneItem)
	local numSize = 24
	local icon = nil

	if round == 3 and self.roundIndex == 0 then
		icon = xyd.tables.itemTable:getIcon(8065)
	elseif round == 6 and self.roundIndex == 3 then
		icon = xyd.tables.itemTable:getIcon(8067)
		numSize = 28
	else
		icon = "avator_bg"
	end

	local num = math.pow(2, 6 - round)
	local frame = group:ComponentByName("imgFrame", typeof(UISprite))

	xyd.setUISpriteAsync(frame, nil, icon, function ()
		if not tolua.isnull(frame) then
			frame:MakePixelPerfect()
		end
	end)
	xyd.setUISpriteAsync(group:GetComponent(typeof(UISprite)), nil, "arena_as_avatar_none_bg")

	local labelNum = group:ComponentByName("labelNum", typeof(UILabel))
	labelNum.text = num
	labelNum.fontSize = numSize

	return group
end

function ArenaAllServerFightList:getPlayerItem(playerID, parent, reportIDs, isShowVideo, isShowQuiz, trueRound)
	local playerInfo = ArenaAllServer:getBattlePlayerInfo(playerID, self.zone_id_)

	if not playerInfo then
		return self:getNoneItem(parent, trueRound)
	end

	local showVideo = false

	if isShowVideo and reportIDs and reportIDs[1] then
		showVideo = true
	end

	local item = AllServerPlayerIcon.new(parent)

	item:setInfo(playerInfo, {
		canTouchQuiz = true,
		show_effect = true,
		show_video = showVideo,
		report_ids = reportIDs,
		show_quiz = isShowQuiz,
		zone = self.zone_id_
	})
	item:SetLocalPosition(0, 52, 0)

	if self:checkAlive(playerID) == false then
		item:applyGrey()
	else
		self:initPath2(playerID, trueRound)
	end

	return item
end

function ArenaAllServerFightList:checkAlive(playerID)
	local isAlive = ArenaAllServer:checkAlive(playerID, self.zone_id_)

	if isAlive then
		return true
	end

	local flag = false

	if self.roundIndex == 0 then
		local rounds = ArenaAllServer:getRounds(self.zone_id_)
		local roundInfo = rounds[3]

		if roundInfo and roundInfo.win_ids then
			for _, id in ipairs(roundInfo.win_ids) do
				if id == playerID then
					flag = true

					break
				end
			end
		end
	end

	return flag
end

function ArenaAllServerFightList:initPath()
	local round = ArenaAllServer:getCurRound()

	if self.roundIndex == 0 and round == 2 or self.roundIndex == 3 and round == 5 then
		for i = 1, 4 do
			local effect = xyd.Spine.new(self.groupEffect)

			effect:setInfo("ultimate_arena_path", function ()
				effect:SetLocalPosition(self.arryPath[2][i].x, self.arryPath[2][i].y, 0)
				effect:SetLocalScale(self.arryPath[2][i].sx, self.arryPath[2][i].sy, 1)
				effect:play("texiao02", 0)
			end)
		end
	elseif self.roundIndex == 0 and round == 3 or self.roundIndex == 3 and round == 6 then
		for i = 1, 2 do
			local effect = xyd.Spine.new(self.groupEffect)

			effect:setInfo("ultimate_arena_path", function ()
				effect:SetLocalPosition(self.arryPath[3][i].x, self.arryPath[3][i].y, 0)
				effect:SetLocalScale(self.arryPath[3][i].sx, self.arryPath[3][i].sy, 1)
				effect:play("texiao03", 0)
			end)
		end
	end
end

function ArenaAllServerFightList:initPath2(playerID, trueRound)
	local round = trueRound - self.roundIndex

	if round == 0 then
		return
	end

	local rounds = ArenaAllServer:getRounds(self.zone_id_)
	local lastRoundInfo = rounds[trueRound - 1] or {}
	local winIDs = lastRoundInfo.win_ids or {}
	local index = -1

	for i = 1, #winIDs do
		if winIDs[i] == playerID then
			index = i

			break
		end
	end

	if index == -1 then
		return
	end

	local pos = index - (self.curPage_ - 1) * math.pow(2, 4 - round)

	if pos == -1 then
		return
	end

	local arry = {
		"D",
		"C",
		"B"
	}
	local group = self.groupPath:NodeByName("path" .. tostring(arry[round]) .. tostring(pos)).gameObject

	if group then
		group:SetActive(true)
	end
end

local ArenaAllServerFight = class("ArenaAllServerFight", import("app.components.CopyComponent"))

function ArenaAllServerFight:ctor(go, parent)
	self.parent_ = parent

	ArenaAllServerFight.super.ctor(self, go)

	self.curPage_ = 1
	self.contentTouchPoint = {
		x = 0,
		y = 0
	}
	self.isMove_ = false
	self.maxPage_ = 8
	self.curQuizPage_ = -1
end

function ArenaAllServerFight:initUI()
	ArenaAllServerFight.super.initUI(self)

	self.groupContent_ = self.go:NodeByName("groupContent_").gameObject
	self.groupTop_ = self.go:NodeByName("groupTop_").gameObject
	self.btnQuiz = self.groupTop_:NodeByName("btnQuiz").gameObject
	self.btnHelp_ = self.groupTop_:NodeByName("btnHelp_").gameObject
	self.groupTime_ = self.groupTop_:NodeByName("groupTime_").gameObject
	self.labelTips_ = self.groupTop_:ComponentByName("labelTips_", typeof(UILabel))
	self.imgTitle_ = self.groupTop_:ComponentByName("imgTitle_", typeof(UISprite))
	self.labelCountDown_ = self.groupTime_:ComponentByName("labelCountDown_", typeof(UILabel))
	local labelTimeNode_ = self.groupTime_:ComponentByName("labelTime_", typeof(UILabel))
	self.quizRedPoint_ = self.btnQuiz:NodeByName("redPoint").gameObject
	self.labelTime_ = CountDown.new(labelTimeNode_)
	self.groupBottom_ = self.go:NodeByName("groupBottom_").gameObject

	for i = 1, 5 do
		self["btn" .. i] = self.groupBottom_:NodeByName("btn" .. i).gameObject
	end

	self.groupDefends_ = self.go:NodeByName("groupDefends_").gameObject
	self.btnDefend_ = self.groupDefends_:NodeByName("btnDefend_").gameObject
	self.btnRecords_ = self.groupDefends_:NodeByName("btnRecords_").gameObject
	self.defendRedPoint_ = self.btnDefend_:NodeByName("redPoint").gameObject
	self.defendRectMask_ = self.btnDefend_:NodeByName("rectMask").gameObject
	self.groupDefendTime_ = self.groupDefends_:NodeByName("groupDefendTime_").gameObject
	self.labelDefendCountDown_ = self.groupDefendTime_:ComponentByName("labelDefendCountDown_", typeof(UILabel))
	local labelDefendTimeNode_ = self.groupDefendTime_:ComponentByName("labelDefendTime_", typeof(UILabel))
	self.btnZone_ = self.go:NodeByName("groupZones_/btnZone").gameObject
	self.btnZoneLabel_ = self.btnZone_:ComponentByName("button_label", typeof(UILabel))
	self.zoneGroup = self.go:NodeByName("groupZones_/chooseGroup").gameObject

	for i = 1, 5 do
		self["zone" .. tostring(i)] = self.zoneGroup:NodeByName("zone" .. i).gameObject
		self["zoneImg" .. i] = self.zoneGroup:ComponentByName("zone" .. i, typeof(UISprite))
	end

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "ja_jp" then
		self.btnZoneLabel_.fontSize = 18
	end

	self.labelDefendTime_ = CountDown.new(labelDefendTimeNode_)

	self:returnCommonScreen()
	self:registerEvent()
	self:initSortBtn()
end

function ArenaAllServerFight:initSortBtn()
	self.zone_id_ = xyd.models.arenaAllServerNew:getZoneID()
	local zoneNum = ArenaAllServer:getZoneNum()
	self.btnZoneLabel_.text = __("NEW_ARENA_ALL_SERVER_TEXT_17", self.zone_id_)

	for i = 1, 5 do
		local sortBtn = self["zone" .. i]
		sortBtn:ComponentByName("label", typeof(UILabel)).text = __("NEW_ARENA_ALL_SERVER_TEXT_17", i)

		UIEventListener.Get(sortBtn).onClick = function ()
			self:onZoneSelectTouch(i)
		end

		if zoneNum < i then
			sortBtn:SetActive(false)
		end
	end
end

function ArenaAllServerFight:onZoneSelectTouch(index)
	if self.zone_id_ ~= index then
		self.zone_id_ = index
		self.btnZoneLabel_.text = __("NEW_ARENA_ALL_SERVER_TEXT_17", self.zone_id_)

		self:updateZoneChosen()
		self:onZoneTouch()
		self:update()
	end
end

function ArenaAllServerFight:onZoneTouch()
	self:updateZoneChosen()

	local arrow = self.btnZone_:NodeByName("arrow").gameObject
	local scale = arrow.transform.localScale

	arrow.transform:SetLocalScale(scale.x, -1 * scale.y, scale.z)

	arrow.transform.localEulerAngles = -arrow.transform.localEulerAngles

	self:moveGroupSort()
end

function ArenaAllServerFight:updateZoneChosen()
	local zoneNum = ArenaAllServer:getZoneNum()

	for i = 1, 5 do
		local zone = self["zone" .. tostring(i)]
		local label = zone:ComponentByName("label", typeof(UILabel))

		if i == self.zone_id_ then
			if i == 1 then
				xyd.setUISpriteAsync(self["zoneImg" .. i], nil, "partner_sort_bg_chosen_02")
			elseif i == zoneNum then
				xyd.setUISpriteAsync(self["zoneImg" .. i], nil, "partner_sort_bg_chosen_01")
			else
				xyd.setUISpriteAsync(self["zoneImg" .. i], nil, "partner_sort_bg_chosen_03")
			end

			label.color = Color.New2(4294967295.0)
			label.effectStyle = UILabel.Effect.Outline
			label.effectColor = Color.New2(1012112383)
		else
			if i == 1 then
				xyd.setUISpriteAsync(self["zoneImg" .. i], nil, "partner_sort_bg_unchosen_02")
			elseif i == zoneNum then
				xyd.setUISpriteAsync(self["zoneImg" .. i], nil, "partner_sort_bg_unchosen_01")
			else
				xyd.setUISpriteAsync(self["zoneImg" .. i], nil, "partner_sort_bg_unchosen_03")
			end

			label.color = Color.New2(960513791)
			label.effectStyle = UILabel.Effect.None
		end
	end
end

function ArenaAllServerFight:moveGroupSort()
	local w = self.zoneGroup:GetComponent(typeof(UIWidget))
	local height = w.height
	local transform = self.zoneGroup.transform
	local action = DG.Tweening.DOTween.Sequence()
	local arrow = self.btnZone_:NodeByName("arrow").gameObject
	local scaleY = arrow.transform.localScale.y

	if scaleY == 1 then
		action:Append(transform:DOLocalMove(Vector3(0, height + 17, 0), 0.067)):Append(transform:DOLocalMove(Vector3(0, height - 58, 0), 0.1)):Join(xyd.getTweenAlpha(w, 0.01, 0.1)):AppendCallback(function ()
			self.zoneGroup:SetActive(false)
			transform:SetLocalPosition(0, 0, 0)
		end)
	else
		self.zoneGroup:SetActive(true)

		w.alpha = 0.01

		transform:SetLocalPosition(0, height - 58, 0)
		action:Append(transform:DOLocalMove(Vector3(0, height + 17, 0), 0.1)):Join(xyd.getTweenAlpha(w, 1, 0.1)):Append(transform:DOLocalMove(Vector3(0, height, 0), 0.2))
	end
end

function ArenaAllServerFight:returnCommonScreen()
	local stageHeight = xyd.WindowManager.get():getActiveHeight()
	local num = (stageHeight - 1280) / (xyd.Global.getMaxHeight() - 1280)

	if xyd.Global.getMaxHeight() < stageHeight then
		num = 1
	end

	local topRect = self.groupTop_:GetComponent(typeof(UIRect))

	topRect:SetTopAnchor(topRect.topAnchor.target.gameObject, 1, -100 - 40 * (1 + num))
	self.groupContent_:SetLocalPosition(0, -20 + 20 * (1 - num), 0)
end

function ArenaAllServerFight:registerEvent()
	for i = 1, 5 do
		UIEventListener.Get(self["btn" .. tostring(i)]).onClick = function ()
			self:onTouchBot(i)
		end
	end

	UIEventListener.Get(self.btnQuiz).onClick = handler(self, self.onQuizTouch)
	UIEventListener.Get(self.btnHelp_).onClick = handler(self, self.onHelpTouch)
	UIEventListener.Get(self.btnDefend_).onClick = handler(self, self.onDefendTouch)
	UIEventListener.Get(self.btnRecords_).onClick = handler(self, self.onRecordsTouch)
	UIEventListener.Get(self.groupContent_).onDrag = handler(self, self.onContentTouchBegin)
	UIEventListener.Get(self.groupContent_).onDragEnd = handler(self, self.onContentTouchEnd)
	UIEventListener.Get(self.btnZone_).onClick = handler(self, self.onZoneTouch)

	self.eventProxyInner_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_ALL_BATTLE_INFO_NEW, function ()
		if self.parent_:getCurIndex() == 2 then
			self.curFightList_ = self:initCurFightList()
		end
	end)
end

function ArenaAllServerFight:onContentTouchBegin(go, delta)
	self.contentTouchPoint.x = self.contentTouchPoint.x + delta.x
	self.contentTouchPoint.y = self.contentTouchPoint.y + delta.y
end

function ArenaAllServerFight:onRecordsTouch()
	xyd.WindowManager.get():openWindow("arena_all_server_records_window")
end

function ArenaAllServerFight:onHelpTouch()
	local params = {
		key = "NEW_ARENA_ALL_SERVER_HELP"
	}

	xyd.WindowManager.get():openWindow("help_window", params)
end

function ArenaAllServerFight:onContentTouchEnd()
	if math.abs(self.contentTouchPoint.x) > 50 then
		local isAdd = self.contentTouchPoint.x < 0

		if self:checkMove(isAdd) then
			self:moveFightList(isAdd)
			self:updateBot()
		end
	end

	self.contentTouchPoint.x = 0
	self.contentTouchPoint.y = 0
end

function ArenaAllServerFight:updateBot()
	local total = self.maxPage_

	xyd.setBtnLabel(self.btn3, {
		text = xyd.ROMAN_NUM[self.curPage_]
	})

	local leftIndex = self.curPage_ - 1

	if self.curPage_ == 1 then
		leftIndex = total
	end

	xyd.setBtnLabel(self.btn2, {
		text = xyd.ROMAN_NUM[leftIndex]
	})

	local rightIndex = self.curPage_ + 1

	if self.curPage_ == total then
		rightIndex = 1
	end

	xyd.setBtnLabel(self.btn4, {
		text = xyd.ROMAN_NUM[rightIndex]
	})

	if self.curQuizPage_ > -1 then
		for i = 2, 4 do
			self["btn" .. tostring(i)]:NodeByName("imgQuiz").gameObject:SetActive(false)
		end

		if self.curPage_ == self.curQuizPage_ and self.zone_id_ == xyd.models.arenaAllServerNew:getZoneID() then
			self.btn3:NodeByName("imgQuiz").gameObject:SetActive(true)
		else
			self.btn3:NodeByName("imgQuiz").gameObject:SetActive(false)
		end

		if leftIndex == self.curQuizPage_ and self.zone_id_ == xyd.models.arenaAllServerNew:getZoneID() then
			self.btn2:NodeByName("imgQuiz").gameObject:SetActive(true)
		else
			self.btn2:NodeByName("imgQuiz").gameObject:SetActive(false)
		end

		if rightIndex == self.curQuizPage_ and self.zone_id_ == xyd.models.arenaAllServerNew:getZoneID() then
			self.btn4:NodeByName("imgQuiz").gameObject:SetActive(true)
		else
			self.btn4:NodeByName("imgQuiz").gameObject:SetActive(false)
		end
	end
end

function ArenaAllServerFight:checkMove(isAdd)
	if self.isMove_ then
		return false
	end

	self.curPage_ = self.curPage_ + xyd.checkCondition(isAdd, 1, -1)
	local maxLen = self.maxPage_

	if self.curPage_ < 1 then
		self.curPage_ = maxLen
	elseif maxLen < self.curPage_ then
		self.curPage_ = 1
	end

	return true
end

function ArenaAllServerFight:moveFightList(isAdd)
	local oldItem = self.curFightList_
	local newItem = self:initCurFightList()

	if not newItem then
		return
	end

	self.curFightList_ = newItem
	self.isMove_ = true
	local action = DG.Tweening.DOTween.Sequence():OnComplete(function ()
		if oldItem then
			NGUITools.Destroy(oldItem:getGameObject())
		end

		self.isMove_ = false
	end)
	local action2 = DG.Tweening.DOTween.Sequence()
	local width = self.groupContent_:GetComponent(typeof(UIWidget)).width + 200

	if isAdd then
		newItem:SetLocalPosition(width, 0, 0)
		action:Append(oldItem:getGameObject().transform:DOLocalMove(Vector3(-width, 0, 0), 0.5))
		action2:Append(newItem:getGameObject().transform:DOLocalMove(Vector3(0, 0, 0), 0.5))
	else
		newItem:SetLocalPosition(-width, 0, 0)
		action:Append(oldItem:getGameObject().transform:DOLocalMove(Vector3(width, 0, 0), 0.5))
		action2:Append(newItem:getGameObject().transform:DOLocalMove(Vector3(0, 0, 0), 0.5))
	end
end

function ArenaAllServerFight:getInitPage()
	local index = 1
	local curRound = ArenaAllServer:getCurRound()
	local betInfo = ArenaAllServer:getBetInfoByRound(curRound)
	local rounds = ArenaAllServer:getRounds()
	local pickPlayers = ArenaAllServer:getPickPlayers()
	local roundInfo = rounds["0"] or {}
	local winIDs = roundInfo.win_ids or {}

	if curRound <= 3 and pickPlayers and pickPlayers[1] then
		local playerID = pickPlayers[1].player_id

		for i = 1, #winIDs do
			if winIDs[i] == playerID then
				index = math.floor((i - 1) / 8) + 1

				break
			end
		end

		if betInfo and betInfo.win_player_id then
			self.curQuizPage_ = index
		end
	end

	self.curPage_ = index
end

function ArenaAllServerFight:setInfo()
	self:layout()
end

function ArenaAllServerFight:layout()
	self:getInitPage()

	self.curFightList_ = self:initCurFightList()

	xyd.setBtnLabel(self.btnDefend_, {
		text = __("DEFFORMATION")
	})
	xyd.setBtnLabel(self.btnRecords_, {
		text = __("BATTLE_RECORD")
	})
	self:updateBot()
	self:initTime()
	self:updateBtnDefend()

	self.labelCountDown_.text = __("ARENA_ALL_SERVER_TEXT_22")
	self.labelDefendCountDown_.text = __("LOCK_COUNT_DOWN")

	xyd.setUISpriteAsync(self.imgTitle_, nil, "arena_as_final_" .. xyd.Global.lang, function ()
		if not tolua.isnull(self.imgTitle_) then
			self.imgTitle_:MakePixelPerfect()

			if xyd.Global.lang == "ko_kr" then
				self.imgTitle_:Y(17)
			elseif xyd.Global.lang == "de_de" then
				self.imgTitle_:Y(33)
			end
		end
	end)

	local val = xyd.db.misc:getValue("arena_all_server_quiz")

	if val and val ~= "" then
		local data = cjson.decode(val)
		local info = ArenaAllServer:getBetInfoByRound(data.round)

		if info and info.is_win and info.is_win > -1 then
			self.quizRedPoint_:SetActive(true)
		else
			self.quizRedPoint_:SetActive(false)
		end
	else
		self.quizRedPoint_:SetActive(false)
	end
end

function ArenaAllServerFight:updateBtnDefend()
	if not ArenaAllServer:isSelect() then
		self.groupDefends_:SetActive(false)

		return
	end

	self.groupDefends_:SetActive(true)

	local isAlive = true

	if ArenaAllServer:checkAlive(xyd.Global.playerID) or ArenaAllServer:isSelect() and ArenaAllServer:getCurRound() == 0 then
		self.defendRectMask_:SetActive(false)
	else
		self.defendRectMask_:SetActive(true)

		isAlive = false
	end

	if ArenaAllServer:isSetDefend() == false and isAlive then
		self.defendRedPoint_:SetActive(true)
	else
		self.defendRedPoint_:SetActive(false)
	end

	local startTime = ArenaAllServer:getStartTime()

	if xyd.getServerTime() - startTime > 26 * xyd.DAY_TIME then
		self.groupDefends_:SetActive(false)
	end
end

function ArenaAllServerFight:initTime()
	local isRestTime = ArenaAllServer:isRestTime()
	local curRound = ArenaAllServer:getCurRound()

	if isRestTime or curRound > 3 then
		self.groupTime_:SetActive(false)
		self.labelTips_:SetActive(false)
		self.labelDefendCountDown_.gameObject:SetActive(false)
	else
		self.groupTime_:SetActive(true)
		self.labelTips_:SetActive(true)

		local time = ArenaAllServer:getNextFightTime()

		self.labelTime_:setCountDownTime(time)
		self.labelDefendTime_:setCountDownTime(time - DEFEND_END_TIME)

		self.labelTips_.text = __("ARENA_ALL_SERVER_ROUND_TEXT_" .. tostring(curRound))
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelTips_.width = 140
	end
end

function ArenaAllServerFight:update()
	if self.curFightList_ then
		NGUITools.Destroy(self.curFightList_:getGameObject())

		self.curFightList_ = nil
	end

	self:getInitPage()

	self.curFightList_ = self:initCurFightList()

	self:updateBtnDefend()
	self:updateBot()
end

function ArenaAllServerFight:onTouchBot(index)
	if self.isMove_ then
		return false
	end

	local isAdd = false

	if index == 1 or index == 2 then
		self.curPage_ = self.curPage_ - 1
	elseif index == 4 or index == 5 then
		self.curPage_ = self.curPage_ + 1
		isAdd = true
	end

	if self.curPage_ < 1 then
		self.curPage_ = self.maxPage_
	elseif self.maxPage_ < self.curPage_ then
		self.curPage_ = 1
	end

	self:moveFightList(isAdd)
	self:updateBot()
end

function ArenaAllServerFight:onQuizTouch()
	self.quizRedPoint_:SetActive(false)

	local val = xyd.db.misc:getValue("arena_all_server_quiz")

	if val and val ~= "" then
		local data = cjson.decode(val)
		local info = ArenaAllServer:getBetInfoByRound(data.round)

		if info and info.is_win and info.is_win > -1 then
			xyd.db.misc:setValue({
				value = "",
				key = "arena_all_server_quiz"
			})
			xyd.WindowManager.get():openWindow("arena_all_server_quiz_result_window", {
				info = info,
				round = data.round,
				callback = function ()
					xyd.WindowManager.get():openWindow("arena_all_server_quiz_window")
				end
			})

			return
		end
	end

	xyd.WindowManager.get():openWindow("arena_all_server_quiz_window")
end

function ArenaAllServerFight:onDefendTouch()
	if ArenaAllServer:checkAlive(xyd.Global.playerID) == false and (not ArenaAllServer:isSelect() or ArenaAllServer:getCurRound() > 0) then
		xyd.alert(xyd.AlertType.TIPS, __("ARENA_ALL_SERVER_TEXT_33"))

		return
	end

	local time = ArenaAllServer:getNextFightTime()

	if time < DEFEND_END_TIME then
		xyd.alert(xyd.AlertType.TIPS, __("ARENA_ALL_SERVER_TEXT_23"))

		return
	end

	xyd.WindowManager.get():openWindow("arena_all_server_battle_formation_window", {
		battleType = xyd.BattleType.ARENA_ALL_SERVER_DEF_2,
		mapType = xyd.MapType.ARENA_3v3,
		formation = xyd.models.arenaAllServerNew:getDefFormation(),
		timeType = xyd.models.arenaAllServerNew:getFinalTimeGroup()
	})
end

function ArenaAllServerFight:initCurFightList()
	local info = ArenaAllServer:getRounds(self.zone_id_)

	if not info or next(info) == nil then
		ArenaAllServer:reqBattleInfo(self.zone_id_)

		return nil
	else
		local item = ArenaAllServerFightList.new(self.groupContent_)

		item:setInfo({
			cur_page = self.curPage_,
			zone_id = self.zone_id_
		})

		return item
	end
end

local ArenaAllServerFightFinal = class("ArenaAllServerFightFinal", ArenaAllServerFight)

function ArenaAllServerFightFinal:layout()
	ArenaAllServerFightFinal.super.layout(self)
	self.groupBottom_:SetActive(false)
end

function ArenaAllServerFightFinal:initCurFightList()
	local info = ArenaAllServer:getRounds(self.zone_id_)

	if not info or next(info) == nil then
		ArenaAllServer:reqBattleInfo(self.zone_id_)

		return nil
	else
		local item = ArenaAllServerFightList.new(self.groupContent_)

		item:setInfo({
			round_index = 3,
			cur_page = self.curPage_,
			zone_id = self.zone_id_
		})

		return item
	end
end

function ArenaAllServerFightFinal:getInitPage()
end

function ArenaAllServerFightFinal:checkMove()
	return false
end

function ArenaAllServerFightFinal:initTime()
	local isRestTime = ArenaAllServer:isRestTime()
	local curRound = ArenaAllServer:getCurRound()

	if isRestTime or curRound > 6 then
		self.groupTime_:SetActive(false)
		self.labelTips_:SetActive(false)
		self.labelDefendCountDown_.gameObject:SetActive(false)
	else
		self.groupTime_:SetActive(true)
		self.labelTips_:SetActive(true)

		local time = ArenaAllServer:getNextFightTime()

		self.labelTime_:setCountDownTime(time)
		self.labelDefendTime_:setCountDownTime(time - DEFEND_END_TIME)

		self.labelTips_.text = __("ARENA_ALL_SERVER_ROUND_TEXT_" .. tostring(curRound))
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelTips_.width = 140
	end
end

function ArenaAllServerFightFinal:registerEvent()
	for i = 1, 5 do
		UIEventListener.Get(self["btn" .. tostring(i)]).onClick = function ()
			self:onTouchBot(i)
		end
	end

	UIEventListener.Get(self.btnQuiz).onClick = handler(self, self.onQuizTouch)
	UIEventListener.Get(self.btnHelp_).onClick = handler(self, self.onHelpTouch)
	UIEventListener.Get(self.btnDefend_).onClick = handler(self, self.onDefendTouch)
	UIEventListener.Get(self.btnRecords_).onClick = handler(self, self.onRecordsTouch)
	UIEventListener.Get(self.groupContent_).onDrag = handler(self, self.onContentTouchBegin)
	UIEventListener.Get(self.groupContent_).onDragEnd = handler(self, self.onContentTouchEnd)
	UIEventListener.Get(self.btnZone_).onClick = handler(self, self.onZoneTouch)

	self.eventProxyInner_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_ALL_BATTLE_INFO_NEW, function ()
		if self.parent_:getCurIndex() == 3 then
			self.curFightList_ = self:initCurFightList()
		end
	end)
end

local SelfPlayer = xyd.models.selfPlayer
local Backpack = xyd.models.backpack
local Slot = xyd.models.slot
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local ResItem = import("app.components.ResItem")
local BaseComponent = import("app.components.BaseComponent")
local ItemRender = class("ItemRender")
local ArenaWindowItem = class("ArenaWindowItem", BaseComponent)

function ArenaWindowItem:ctor(parentGo, parentItem)
	self.parentItem = parentItem

	ArenaWindowItem.super.ctor(self, parentGo)
	self:getUIComponent()
end

function ArenaWindowItem:getPrefabPath()
	return "Prefabs/Components/arena_window_item"
end

function ArenaWindowItem:getUIComponent()
	local go = self.go
	self.bg = go:ComponentByName("bg", typeof(UISprite))
	self.imgRank = go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	local pIconContainer = go:NodeByName("pIcon").gameObject

	if self.parentItem.parent then
		self.pIcon = PlayerIcon.new(pIconContainer, self.parentItem.parent.scrollView_uipanel)
	else
		self.pIcon = PlayerIcon.new(pIconContainer)
	end

	self.playerName = go:ComponentByName("playerName", typeof(UILabel))
	self.power = go:ComponentByName("power", typeof(UILabel))
	self.labelPoint = go:ComponentByName("labelPoint", typeof(UILabel))
	self.point = go:ComponentByName("point", typeof(UILabel))
	self.serverInfo = go:NodeByName("serverInfo").gameObject
	self.serverId = self.serverInfo:ComponentByName("serverId", typeof(UILabel))
	self.levelImg = go:ComponentByName("levelImg", typeof(UISprite))
	self.levelImg2 = go:ComponentByName("levelImg2", typeof(UISprite))

	self:createChildren()
end

function ArenaWindowItem:setCurrentState(state)
	self.serverInfo:SetActive(false)

	if state == "self" then
		self.bg.height = 109
	end
end

function ArenaWindowItem:setInfo(params)
	if params.is_robot == 1 then
		params.avatar_id = xyd.tables.arenaRobotTable:getAvatar(params.player_id)
		params.lev = xyd.tables.arenaRobotTable:getLev(params.player_id)
		params.player_name = xyd.tables.arenaRobotTable:getName(params.player_id)
		params.power = xyd.tables.arenaRobotTable:getPower(params.player_id)
	elseif params.player_id and params.player_id < 10000 then
		local table_id = params.player_id
		params.lev = xyd.tables.arenaAllServerRobotTable:getLev(table_id)
		params.player_name = xyd.tables.arenaAllServerRobotTable:getName(table_id)
		params.power = xyd.tables.arenaAllServerRobotTable:getPower(table_id)
		params.show_id = xyd.tables.arenaAllServerRobotTable:getShowID(table_id)
		params.score = xyd.tables.arenaAllServerRobotTable:getScore(table_id)
		params.server_id = xyd.tables.arenaAllServerRobotTable:getServerID(table_id)
		params.avatar_id = xyd.tables.arenaAllServerRobotTable:getAvatar(table_id)
	end

	if self.params and params.player_id and self.params.player_id and params.player_id == self.params.player_id and params.lev and self.params.lev and params.lev == self.params.lev and params.power and self.params.power and params.power == self.params.power and params.avatar_id and self.params.avatar_id and params.avatar_id == self.params.avatar_id and params.player_name and self.params.player_name and params.player_name == self.params.player_name and params.rank and self.params.rank and params.rank == self.params.rank and params.score and self.params.score and params.score == self.params.score then
		return
	end

	self.params = params

	self.pIcon:setInfo({
		avatarID = params.avatar_id,
		lev = params.lev,
		avatar_frame_id = params.avatar_frame_id,
		callback = function ()
			if self.params.player_id ~= xyd.Global.playerID then
				if self.currentState == "arena" then
					xyd.WindowManager.get():openWindow("arena_formation_window", {
						player_id = self.params.player_id,
						is_robot = self.params.is_robot
					})
				elseif self.currentState == "arena3v3" then
					if xyd.models.arena3v3:checkOpen() then
						xyd.WindowManager.get():openWindow("arena_3v3_formation_window", {
							player_id = self.params.player_id
						})
					end
				elseif self.currentState == "arena_as" and xyd.models.arenaAllServerScore:getStartTime() - xyd.getServerTime() < 0 then
					xyd.WindowManager.get():openWindow("arena_all_server_formation_window", {
						player_id = self.params.player_id
					})
				end
			end
		end
	})

	if params.state then
		self.currentState = params.state
	else
		self.currentState = "arena"
	end

	self.playerName.text = params.player_name

	if params.rank > 3 then
		self.imgRank:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = params.rank

		if self.currentState == "self" then
			xyd.setUISpriteAsync(self.bg, nil, "rank_bottom_bg")
		else
			xyd.setUISpriteAsync(self.bg, nil, "9gongge17")
		end
	else
		self.imgRank:SetActive(true)
		self.labelRank:SetActive(false)
		xyd.setUISpriteAsync(self.imgRank, nil, "rank_icon0" .. tostring(params.rank))

		local bg = {
			"9gongge30_png",
			"9gongge31_png",
			"9gongge32_png"
		}

		if self.currentState == "self" then
			xyd.setUISpriteAsync(self.bg, nil, "rank_bottom_bg")
		else
			xyd.setUISpriteAsync(self.bg, nil, bg[params.rank])
		end
	end

	self.power.text = params.power
	self.labelPoint.text = __("SCORE")

	if params.score < 2000 then
		self.point.text = math.fmod(params.score, 100)
	else
		self.point.text = params.score - 2000
	end

	self.serverId.text = xyd.getServerNumber(params.server_id)
	local reqType = params.reqType
	local rankType = xyd.tables.arenaAllServerRankTable:getRankType(params.score)
	local level = xyd.tables.arenaAllServerRankTable:getRankLevel(params.score, params.rank)

	if level == 21 or reqType == 5 then
		self.levelImg2.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.levelImg, nil, "as_rank_icon_5", function ()
			self.levelImg.transform:SetLocalScale(1, 1, 1)
		end, nil, true)
	elseif level == 22 or reqType == 6 then
		self.levelImg2.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.levelImg, nil, "as_rank_icon_6", function ()
			self.levelImg.transform:SetLocalScale(1, 1, 1)
		end, nil, true)
	else
		local level_ = math.fmod(level - 1, 5) + 1

		self.levelImg2.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.levelImg, nil, "as_rank_icon_" .. rankType, function ()
			self.levelImg.transform:SetLocalScale(1.2, 1.2, 1)
		end, nil, true)
		xyd.setUISpriteAsync(self.levelImg2, nil, "as_rank_icon_" .. rankType .. "_" .. level_, function ()
			self.levelImg2.transform:SetLocalScale(1.2, 1.2, 1)
		end, nil, true)
	end

	self:setCurrentState(self.currentState)
end

function ArenaWindowItem:getRank()
	return self.params.rank
end

function ArenaWindowItem:createChildren()
end

function ArenaWindowItem:dataChanged()
	self:setInfo(self.data)
end

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ArenaWindowItem.new(go, self)

	self.item:setDragScrollView(parent.scrollView)
end

function ItemRender:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.item.data = info

	self.go:SetActive(true)
	self.item:dataChanged()
end

function ItemRender:getGameObject()
	return self.go
end

local ArenaAllServerScore = class("ArenaAllServerScore", import("app.components.CopyComponent"))

function ArenaAllServerScore:ctor(go)
	self.resItemList = {}
	self.model_ = xyd.models.arenaAllServerScore
	self.rankType_ = self.model_:getRankType()
	self.rankShowType_ = 1

	ArenaAllServerScore.super.ctor(self, go)
end

function ArenaAllServerScore:getUIComponent()
	self.main = self.go.transform
	self.top = self.main:NodeByName("top").gameObject
	self.btnMission = self.top:NodeByName("btnMission").gameObject
	self.btnMissionRed = self.top:NodeByName("btnMission/redPoint").gameObject
	self.btnMissionLabel = self.top:ComponentByName("btnMission/labelMission", typeof(UILabel))
	self.btnHelp = self.top:NodeByName("btnHelp").gameObject
	self.btnRankChange = self.top:NodeByName("btnRankChange").gameObject
	self.btnRankChangeLbael = self.top:ComponentByName("btnRankChange/label", typeof(UILabel))
	self.imgTitle = self.top:ComponentByName("imgTitle_", typeof(UISprite))
	self.labelTips = self.top:ComponentByName("labelTips_", typeof(UILabel))
	self.groupTime_ = self.top:ComponentByName("groupTime_", typeof(UILayout))
	self.labelCountDown_ = self.top:ComponentByName("groupTime_/labelCountDown_", typeof(UILabel))
	self.labelTime_ = self.top:ComponentByName("groupTime_/labelTime_", typeof(UILabel))
	self.groupRank = self.main:NodeByName("groupRank").gameObject
	self.scrollView = self.groupRank:ComponentByName("scrollview", typeof(UIScrollView))
	self.scrollView_uipanel = self.groupRank:ComponentByName("scrollview", typeof(UIPanel))
	self.selfInfoPos = self.groupRank:NodeByName("selfInfoPos").gameObject
	local wrapContent = self.scrollView:ComponentByName("rankContainer", typeof(UIWrapContent))
	local iconContainer = self.scrollView:NodeByName("renderContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, iconContainer, ItemRender, self)

	self.wrapContent:hideItems()

	self.groupDetail = self.main:NodeByName("groupDetail").gameObject
	self.imgDetailBg01 = self.groupDetail:ComponentByName("imgDetailBg01", typeof(UITexture))
	self.imgDetailBg02 = self.groupDetail:ComponentByName("imgDetailBg02", typeof(UITexture))
	local pIconContainer = self.groupDetail:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIconContainer)
	self.labelPower = self.groupDetail:ComponentByName("labelPower", typeof(UILabel))
	self.labelScoreText = self.groupDetail:ComponentByName("labelScore", typeof(UILabel))
	self.labelScore = self.groupDetail:ComponentByName("score", typeof(UILabel))
	local resItemContainer = self.groupDetail:NodeByName("res3").gameObject
	self.res3 = ResItem.new(resItemContainer)
	self.btnFight = self.groupDetail:NodeByName("btnFight").gameObject
	self.btnFightLabel = self.btnFight:ComponentByName("btnFightLabel", typeof(UILabel))
	self.btnAward = self.groupDetail:NodeByName("btnAward").gameObject
	self.btnAwardLabel = self.btnAward:ComponentByName("btnAwardLabel", typeof(UILabel))
	self.btnRecord = self.groupDetail:NodeByName("btnRecord").gameObject
	self.btnRecordLabel = self.btnRecord:ComponentByName("btnRecordLabel", typeof(UILabel))
	self.btnFormation = self.groupDetail:NodeByName("btnFormation").gameObject
	self.btnFormationLabel = self.btnFormation:ComponentByName("btnFormationLabel", typeof(UILabel))
	self.btnFormationRed = self.btnFormation:NodeByName("redPoint").gameObject
	self.seasonOpen = self.groupDetail:NodeByName("seasonOpen").gameObject
	self.imgSeasonOpen01 = self.seasonOpen:ComponentByName("imgSeasonOpen01", typeof(UITexture))
	self.imgSeasonOpen02 = self.seasonOpen:ComponentByName("imgSeasonOpen02", typeof(UITexture))
	self.seasonLabel = self.seasonOpen:ComponentByName("seasonLabel", typeof(UILabel))
	self.seasonCountDown = self.seasonOpen:ComponentByName("seasonCountDown", typeof(UILabel))
	self.levelImg = self.groupDetail:ComponentByName("levelImg", typeof(UISprite))
	self.levelImg2 = self.groupDetail:ComponentByName("levelImg2", typeof(UISprite))

	if xyd.Global.lang == "fr_fr" then
		self.btnRecord:X(250)
		self.btnAward:X(250)
		self.btnFormation:X(250)
	end

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_MISSION, self.btnMissionRed.gameObject)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_DEFEND, self.btnFormationRed.gameObject)

	local realHeight = xyd.Global.getRealHeight()

	self.top.transform:Y(460 + 0.2247191011235955 * (realHeight - 1280))
end

function ArenaAllServerScore:initUI()
	ArenaAllServerScore.super.initUI(self)
	self:getUIComponent()
	self:registerEvent()
end

function ArenaAllServerScore:setInfo()
	self:initLayout()
	self.model_:reqRankList(self.rankType_)
	self:onGetArenaInfo()

	local timer = self:getTimer(function ()
		self:updateDDL()
	end, 1, -1)

	timer:Start()
end

function ArenaAllServerScore:initLayout()
	xyd.setUISpriteAsync(self.imgTitle, nil, "arena_as_final_" .. tostring(xyd.Global.lang), nil, , true)
	xyd.setUITextureByNameAsync(self.imgSeasonOpen01, "arena_operator_bg")
	xyd.setUITextureByNameAsync(self.imgSeasonOpen02, "arena_operator_bg")

	self.seasonLabel.text = __("OPEN_AFTER")
	self.labelTips.text = __("NEW_ARENA_ALL_SERVER_TEXT_1")
	self.btnRankChangeLbael.text = __("NEW_ARENA_ALL_SERVER_TEXT_2")
	self.btnMissionLabel.text = __("ACTIVITY_ICE_SECRET_MISSION_DAILY")

	self.res3:setInfo({
		tableId = xyd.ItemID.ARENA_TICKET
	})
	table.insert(self.resItemList, self.res3)

	local callback = nil

	function callback()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	local avatar = SelfPlayer:getAvatarID()
	local lev = Backpack:getLev()

	self.pIcon:setInfo({
		avatarID = avatar,
		lev = lev,
		avatar_frame_id = SelfPlayer:getAvatarFrameID()
	})
	self.pIcon:setScale(0.8)

	self.selfPower = xyd.models.arenaAllServerScore:getPower()
	self.labelPower.text = tostring(self.selfPower)
	self.labelScoreText.text = __("SCORE")

	if xyd.Global.lang == "fr_fr" then
		self.labelScoreText.fontSize = 14
	end

	if xyd.Global.lang == "de_de" then
		self.imgTitle:SetLocalPosition(22, 0, 0)

		self.btnAwardLabel.fontSize = 18
		self.btnRecordLabel.fontSize = 18
		self.btnFormationLabel.fontSize = 18

		self.seasonLabel:X(-30)
		self.seasonCountDown:X(-148)
	elseif xyd.Global.lang == "fr_fr" then
		self.seasonLabel:X(-165)
		self.seasonCountDown:X(42)
	end

	self.btnFightLabel.text = __("FIGHT2")
	self.btnAwardLabel.text = __("AWARD2")
	self.btnRecordLabel.text = __("RECORD")
	self.btnFormationLabel.text = __("DEFFORMATION")

	self:updateDefendRed()
	self.groupTime_:Reposition()
end

function ArenaAllServerScore:onGetArenaInfo()
	local partners = self.model_:getDefFormation().partners or {}

	if #partners <= 0 and self:checkOpen() then
		xyd.WindowManager.get():openWindow("arena_all_server_battle_formation_window", {
			battleType = xyd.BattleType.ARENA_ALL_SERVER_DEF,
			mapType = xyd.MapType.ARENA_3v3,
			callback = function ()
				xyd.WindowManager.get():closeWindow("arena_all_server_window")
			end
		})
	end

	self:updateDDL()

	local stratTime = self.model_:getStartTime()

	if stratTime - xyd.getServerTime() > 0 and stratTime - xyd.getServerTime() < xyd.DAY_TIME then
		self.labelCountDown_.text = __("NEW_ARENA_ALL_SERVER_TEXT_25")

		xyd.setEnabled(self.btnFight, false)
	elseif xyd.getServerTime() - stratTime >= xyd.DAY_TIME * 19 then
		xyd.setEnabled(self.btnFight, false)
		xyd.setEnabled(self.btnFormation, false)
	end

	self:updateScore()
	self:updateSelfItemInfo()
end

function ArenaAllServerScore:updateAfterFight()
	self:updateScore()
	self:updateSelfItemInfo()

	if self.selfItem and self.selfItem:getRank() <= 50 then
		local reqType = self.rankType_

		if self.rankShowType_ == 2 then
			reqType = 0
		end

		self.model_:reqRankList(reqType)
	end
end

function ArenaAllServerScore:updateSelfItemInfo(selfRank)
	if not self.selfItem then
		self.selfItem = ArenaWindowItem.new(self.selfInfoPos, self)
	end

	local reqType = self.rankType_

	if self.rankShowType_ == 2 then
		reqType = 0
	end

	local info = {
		score = xyd.models.arenaAllServerScore:getScore() or 0,
		player_name = xyd.Global.playerName,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		lev = xyd.models.selfPlayer.level_,
		player_id = xyd.models.selfPlayer.playerID_,
		power = xyd.models.arenaAllServerScore:getPower() or 0,
		server_id = xyd.models.selfPlayer.serverID_,
		rank = selfRank or xyd.models.arenaAllServerScore:getRank(),
		state = "self",
		reqType = reqType
	}
	self.selfItem.data = info

	self.selfItem:dataChanged()
end

function ArenaAllServerScore:updateScore()
	local score = self.model_:getScore()

	if self.rankType_ ~= self.model_:getRankType() then
		self.rankType_ = self.model_:getRankType()

		self.model_:reqRankList(self.rankType_)
		self:updateDefendRed()
	end

	if score < 2000 then
		self.labelScore.text = math.fmod(score, 100)
	else
		self.labelScore.text = score - 2000
	end

	local rankType = self.model_:getRankType(self.model_:getScore())
	local level = self.model_:getRankLevel(self.model_:getScore(), self.model_:getRank())

	if level == 21 then
		self.levelImg2.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.levelImg, nil, "as_rank_icon_5", function ()
			self.levelImg.transform:SetLocalScale(1, 1, 1)
		end, nil, true)
	elseif level == 22 then
		self.levelImg2.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.levelImg, nil, "as_rank_icon_6", function ()
			self.levelImg.transform:SetLocalScale(1, 1, 1)
		end, nil, true)
	else
		local level_ = math.fmod(level - 1, 5) + 1

		self.levelImg2.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.levelImg, nil, "as_rank_icon_" .. rankType, function ()
			self.levelImg.transform:SetLocalScale(1.2, 1.2, 1)
		end, nil, true)
		xyd.setUISpriteAsync(self.levelImg2, nil, "as_rank_icon_" .. rankType .. "_" .. level_, function ()
			self.levelImg2.transform:SetLocalScale(1.2, 1.2, 1)
		end, nil, true)
	end
end

function ArenaAllServerScore:updateDefendRed()
	xyd.models.arenaAllServerScore:updateDefendRed()
end

function ArenaAllServerScore:updateDDL()
	local ddl = self.model_:getDDL() - xyd.getServerTime()
	local startTime = self.model_:getStartTime()
	local startTime2 = xyd.models.arenaAllServerNew:getStartTime()

	if startTime - xyd.getServerTime() > 0 and startTime - xyd.getServerTime() < xyd.DAY_TIME then
		self.labelCountDown_.text = __("NEW_ARENA_ALL_SERVER_TEXT_25")
		self.labelTime_.text = xyd.getRoughDisplayTime(startTime - xyd.getServerTime())
	elseif ddl <= 0 then
		self.labelCountDown_.gameObject:SetActive(false)

		self.labelTime_.text = __("GUILD_COMPETITION_END_TIME")

		self.groupTime_:Reposition()
	else
		self.labelCountDown_.text = __("REST_TIME")
		self.labelTime_.text = xyd.getRoughDisplayTime(ddl)
	end

	if xyd.getServerTime() - startTime > 25 * xyd.DAY_TIME then
		self.seasonOpen:SetActive(true)

		self.seasonCountDown.text = xyd.getRoughDisplayTime(startTime + 28 * xyd.DAY_TIME - xyd.getServerTime())

		self.labelTime_:SetActive(false)
		self.btnRecord:SetActive(false)
	else
		self.seasonOpen:SetActive(false)
		self.labelTime_:SetActive(true)
		self.btnRecord:SetActive(true)
	end
end

function ArenaAllServerScore:checkOpen()
	local openTime = xyd.getServerTime() - self.model_:getStartTime()

	return openTime >= -xyd.DAY_TIME and openTime < 19 * xyd.DAY_TIME
end

function ArenaAllServerScore:onGetRankList()
	local reqType = self.rankType_

	if self.rankShowType_ == 2 then
		reqType = 0
	end

	local ranklist, selfRank = self.model_:getRankList(reqType)
	local infos = {}

	if ranklist then
		for i = 1, #ranklist do
			infos[i] = {
				score = ranklist[i].score,
				player_name = ranklist[i].player_name,
				avatar_id = ranklist[i].avatar_id,
				avatar_frame_id = ranklist[i].avatar_frame_id,
				lev = ranklist[i].lev,
				player_id = ranklist[i].player_id,
				power = ranklist[i].power,
				server_id = ranklist[i].server_id,
				rank = i,
				state = "arena_as",
				reqType = reqType
			}
		end
	end

	self.wrapContent:setInfos(infos, {})
	self:updateSelfItemInfo(selfRank)
end

function ArenaAllServerScore:registerEvent()
	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "NEW_ARENA_ALL_SERVER_HELP"
		})
	end

	UIEventListener.Get(self.btnRankChange).onClick = function ()
		if self.rankShowType_ == 1 then
			self.rankShowType_ = 2
			local ranklist = self.model_:getRankList(0)
			local reqTime = self.model_:getReqRankTime(0)

			if ranklist and #ranklist > 0 and reqTime and xyd.getServerTime() - reqTime < 60 then
				self:onGetRankList()
			else
				self.model_:reqRankList(0)
			end

			self.btnRankChangeLbael.text = __("NEW_ARENA_ALL_SERVER_TEXT_3")
		else
			self.rankShowType_ = 1
			local ranklist = self.model_:getRankList(self.rankType_)
			local reqTime = self.model_:getReqRankTime(self.rankType_)

			if ranklist and #ranklist > 0 and reqTime and xyd.getServerTime() - reqTime < 60 then
				self:onGetRankList()
			else
				self.model_:reqRankList(self.rankType_)
			end

			self.btnRankChangeLbael.text = __("NEW_ARENA_ALL_SERVER_TEXT_2")
		end
	end

	UIEventListener.Get(self.btnFight).onClick = function ()
		xyd.WindowManager.get():openWindow("arena_3v3_choose_player_window", {
			isAs = true,
			power = self.selfPower
		})
	end

	UIEventListener.Get(self.btnRecord).onClick = function ()
		xyd.WindowManager.get():openWindow("arena_3v3_record_window", {
			isAs = true
		})
	end

	UIEventListener.Get(self.btnFormation).onClick = function ()
		xyd.WindowManager.get():openWindow("arena_all_server_battle_formation_window", {
			battleType = xyd.BattleType.ARENA_ALL_SERVER_DEF,
			mapType = xyd.MapType.ARENA_3v3,
			formation = xyd.models.arenaAllServerScore:getDefFormation()
		})
	end

	self.eventProxyInner_:addEventListener(xyd.event.GET_ARENA_ALL_SERVER_INFO, handler(self, self.onGetArenaInfo))
	self.eventProxyInner_:addEventListener(xyd.event.GET_RANK_ALL_SERVER_LIST, handler(self, self.onGetRankList))
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_EXCHANGE, handler(self, self.onBuyCard))
	self.eventProxyInner_:addEventListener(xyd.event.SET_PARTNERS_ALL_SERVER, function ()
		self:updateScore()
	end)
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.res3:updateNum()
	end)

	UIEventListener.Get(self.btnMission.gameObject).onClick = function ()
		local stratTime = self.model_:getStartTime()

		if xyd.getServerTime() - stratTime >= xyd.DAY_TIME * 19 then
			xyd.alertTips(__("GUILD_WAR_RANK_MATCH_END"))

			return
		end

		local ids = xyd.models.arenaAllServerScore:getMissionValues()
		local all_info = {}
		local awardable_table_ids = {}

		for i in pairs(ids) do
			local data = {
				id = i,
				max_value = xyd.tables.arenaAllServerMissionTable:getComplete(i)
			}
			data.name = xyd.tables.arenaAllServerMissionTextTable:getDesc(i, data.max_value)
			data.cur_value = ids[i]

			if data.max_value < data.cur_value then
				data.cur_value = data.max_value
			end

			data.items = xyd.tables.arenaAllServerMissionTable:getAwards(i)

			if xyd.models.arenaAllServerScore:getAwards()[i] == 0 then
				if data.cur_value == data.max_value then
					data.state = 1

					table.insert(awardable_table_ids, data.id)
				else
					data.state = 2
				end
			else
				data.state = 3
			end

			table.insert(all_info, data)
		end

		local arena_all_server_score_mission_time_show = xyd.db.misc:getValue("arena_all_server_score_mission_time_show")

		if not arena_all_server_score_mission_time_show or arena_all_server_score_mission_time_show and tonumber(arena_all_server_score_mission_time_show) <= xyd.getServerTime() - xyd.DAY_TIME then
			xyd.db.misc:setValue({
				key = "arena_all_server_score_mission_time_show",
				value = xyd.getServerTime()
			})
			xyd.models.arenaAllServerScore:checkMissionValue()
		end

		xyd.WindowManager.get():openWindow("common_progress_award_window", {
			if_sort = true,
			all_info = all_info,
			title_text = __("DAILY_MISSION"),
			click_callBack = function (info)
				if xyd.models.arenaAllServerScore:checkInfoOtherDay() then
					local common_progress_award_window_wd = xyd.WindowManager.get():getWindow("common_progress_award_window")

					if common_progress_award_window_wd and common_progress_award_window_wd:getWndType() == xyd.CommonProgressAwardWindowType.ARENA_ALL_SERVER_SCORE_MISSION_WINDOW then
						xyd.WindowManager.get():closeWindow("common_progress_award_window")
						xyd.alertTips(__("NEW_ARENA_ALL_MISSION_REFRESH"))
					end

					return
				end

				local msg = messages_pb:arena_all_server_get_batch_awards_req()

				for i = 1, #awardable_table_ids do
					table.insert(msg.table_ids, awardable_table_ids[i])
				end

				xyd.Backend.get():request(xyd.mid.ARENA_ALL_SERVER_GET_BATCH_AWARDS, msg)
			end,
			wnd_type = xyd.CommonProgressAwardWindowType.ARENA_ALL_SERVER_SCORE_MISSION_WINDOW
		})
	end

	UIEventListener.Get(self.btnAward.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("arena_all_score_server_award_window")
	end
end

function ArenaAllServerScore:onBuyCard(event)
	local getItems = {
		item_id = event.data.item_id,
		item_num = event.data.item_num
	}

	xyd.alertItems({
		getItems
	})
	self.res3:updateNum()
end

local ArenaAllServerWindow = class("ArenaAllServerWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")

function ArenaAllServerWindow:ctor(name, params)
	ArenaAllServerWindow.super.ctor(self, name, params)

	self.curIndex_ = 1
	self.contents_ = {}
end

function ArenaAllServerWindow:initWindow()
	ArenaAllServerWindow.super.initWindow(self)
	self:getUIComponent()
	self:checkOpenIndex()
	self:initLayout()
	self:registerEvent()
	ArenaAllServer:reqBattleInfo()
	ArenaAllServer:reqGetHistoryRank()

	local needLoadRes = {}

	table.insert(needLoadRes, xyd.getSpritePath("arena_as_title_" .. xyd.Global.lang))
	table.insert(needLoadRes, xyd.getSpritePath("arena_as_get_" .. xyd.Global.lang))
	table.insert(needLoadRes, xyd.getSpritePath("arena_as_road"))
	table.insert(needLoadRes, xyd.getSpritePath("arena_as_avatar_none_bg"))
	table.insert(needLoadRes, xyd.getSpritePath("arena_as_final_" .. xyd.Global.lang))
	self:setResourcePaths(needLoadRes)
	xyd.models.arenaAllServerScore:checkInfoOtherDay()
end

function ArenaAllServerWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.bg_ = winTrans:ComponentByName("bg_", typeof(UITexture))

	for i = 1, 4 do
		self["nav" .. i] = winTrans:NodeByName("nav/nav" .. i).gameObject
	end

	self.honorHallsNode_ = winTrans:NodeByName("honor_halls").gameObject
	self.arenaAllserverFightNode_ = winTrans:NodeByName("arena_allserver_fight").gameObject
	self.arenaAllserverScoreNode_ = winTrans:NodeByName("arena_allserver_score").gameObject
end

function ArenaAllServerWindow:checkOpenIndex()
	local scoreEndTime = xyd.models.arenaAllServerScore:getDDL()

	if xyd.getServerTime() < scoreEndTime then
		self.curIndex_ = 4
	else
		self.curIndex_ = ArenaAllServer:getCurBattleType()
	end
end

function ArenaAllServerWindow:initLayout()
	self:initResItem()
	self:changeTopTap()
	self:updateContent()

	self.nav1:ComponentByName("labelTips", typeof(UILabel)).text = __("ARENA_ALL_SERVER_TEXT_1")
	self.nav2:ComponentByName("labelTips", typeof(UILabel)).text = __("ARENA_ALL_SERVER_TEXT_2")
	self.nav3:ComponentByName("labelTips", typeof(UILabel)).text = __("ARENA_ALL_SERVER_TEXT_3")
	self.nav4:ComponentByName("labelTips", typeof(UILabel)).text = __("NEW_ARENA_ALL_SERVER_TEXT_1")
end

function ArenaAllServerWindow:initResItem()
	self.windowTop = WindowTop.new(self.window_, self.name_, 100, true)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
	self.windowTop:setCanRefresh(true)
end

function ArenaAllServerWindow:getWindowTop()
	return self.windowTop
end

function ArenaAllServerWindow:registerEvent()
	self:register()

	for i = 1, 4 do
		UIEventListener.Get(self["nav" .. tostring(i)]).onClick = function ()
			local scoreEndTime = xyd.models.arenaAllServerScore:getDDL()

			if xyd.getServerTime() < scoreEndTime and i == 2 then
				xyd.alert(xyd.AlertType.TIPS, __("NEW_ARENA_ALL_SERVER_TEXT_24"))

				return
			end

			if xyd.getServerTime() < scoreEndTime + 3 * xyd.DAY_TIME and i == 3 then
				xyd.alert(xyd.AlertType.TIPS, __("ARENA_ALL_SERVER_TEXT_31"))

				return
			end

			self.curIndex_ = i

			self:changeTopTap()
			self:updateContent()
		end
	end

	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_ALL_BATTLE_INFO, handler(self, self.onGetBattleInfo))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_HISTORY_RANK_NEW, handler(self, self.onGetHistoryRank))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_HALL_AWARD, handler(self, self.onGetHallAward))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_SET_TEAMS_NEW, handler(self, self.onSetTeams))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_BET, handler(self, self.onBet))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_CHANGE_BET, handler(self, self.onBet))
end

function ArenaAllServerWindow:refresResItems()
	ArenaAllServerWindow.super.refresResItems(self)

	local item = self.contents_[xyd.ArenaAllServerWndType.HONOR_HALLS]
end

function ArenaAllServerWindow:onGetBattleInfo()
	local item = self.contents_[xyd.ArenaAllServerWndType.KNOCKOUT]

	if item then
		item:update()
	end

	local item2 = self.contents_[xyd.ArenaAllServerWndType.FINAL]

	if item2 then
		item2:update()
	end
end

function ArenaAllServerWindow:onBet()
	local item = self.contents_[xyd.ArenaAllServerWndType.KNOCKOUT]

	if item then
		item:update()
	end

	local item2 = self.contents_[xyd.ArenaAllServerWndType.FINAL]

	if item2 then
		item2:update()
	end
end

function ArenaAllServerWindow:onGetHallAward(event)
	if event.data.award then
		xyd:itemFloat(event.data.award)
	end
end

function ArenaAllServerWindow:onGetHistoryRank()
	local item = self.contents_[xyd.ArenaAllServerWndType.HONOR_HALLS]

	if not item then
		local item1 = HonorHalls.new(self.honorHallsNode_)
		self.contents_[xyd.ArenaAllServerWndType.HONOR_HALLS] = item1
		item = self.contents_[xyd.ArenaAllServerWndType.HONOR_HALLS]

		item:setInfo()
	end

	if item then
		item:update()
	end
end

function ArenaAllServerWindow:onSetTeams()
	local item = self.contents_[xyd.ArenaAllServerWndType.KNOCKOUT]

	if item then
		item:updateBtnDefend()
	end

	local item2 = self.contents_[xyd.ArenaAllServerWndType.FINAL]

	if item2 then
		item2:updateBtnDefend()
	end
end

function ArenaAllServerWindow:changeTopTap()
	local index = self.curIndex_

	for i = 1, 4 do
		local nav = self["nav" .. tostring(i)]
		local selected = nav:NodeByName("selected").gameObject
		local label = nav:ComponentByName("labelTips", typeof(UILabel))
		local params = {
			color = 960513791,
			strokeColor = 4294967295.0
		}

		if i == index then
			selected:SetActive(true)
			xyd.setTouchEnable(nav, false)

			params.color = 4294967295.0
			params.strokeColor = 1012112383
		else
			selected:SetActive(false)
			xyd.setTouchEnable(nav, true)
		end

		xyd.setLabel(label, params)
	end

	local src = "arena_as_bg" .. tostring(index)

	if index == 4 then
		src = "arena_as_bg" .. 2
	end

	xyd.setUITextureByNameAsync(self.bg_, tostring(src))
end

function ArenaAllServerWindow:updateScorePartInfo()
	if self.contents_[4] then
		self.contents_[4]:updateAfterFight()
	end
end

function ArenaAllServerWindow:getCurIndex()
	return self.curIndex_
end

function ArenaAllServerWindow:updateContent()
	if not self.contents_[self.curIndex_] then
		local item = nil

		if self.curIndex_ == xyd.ArenaAllServerWndType.HONOR_HALLS then
			item = HonorHalls.new(self.honorHallsNode_)
		elseif self.curIndex_ == xyd.ArenaAllServerWndType.KNOCKOUT then
			local node = NGUITools.AddChild(self.window_, self.arenaAllserverFightNode_)
			item = ArenaAllServerFight.new(node, self)
		elseif self.curIndex_ == xyd.ArenaAllServerWndType.FINAL then
			local node = NGUITools.AddChild(self.window_, self.arenaAllserverFightNode_)
			item = ArenaAllServerFightFinal.new(node, self)
		elseif self.curIndex_ == xyd.ArenaAllServerWndType.SCORE then
			local node = NGUITools.AddChild(self.window_, self.arenaAllserverScoreNode_)
			item = ArenaAllServerScore.new(node)
		end

		item:SetActive(true)
		item:setInfo()

		self.contents_[self.curIndex_] = item
	elseif self.curIndex_ == 1 and self.contents_[self.curIndex_] then
		self.contents_[self.curIndex_]:resetPos()
	end

	for i = 1, 4 do
		if self.contents_[i] then
			self.contents_[i]:SetActive(false)
		end
	end

	self.contents_[self.curIndex_]:SetActive(true)

	if self.curIndex_ == 1 then
		self.contents_[self.curIndex_]:openAnimation()
		self.contents_[self.curIndex_]:update()
	end
end

return ArenaAllServerWindow
