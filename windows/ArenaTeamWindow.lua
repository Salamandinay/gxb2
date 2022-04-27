local BaseWindow = import(".BaseWindow")
local ArenaTeamWindow = class("ArenaTeamWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local WindowTop = import("app.components.WindowTop")
local PlayerIcon = import("app.components.PlayerIcon")
local ArenaTeamWindowItem = class("ArenaTeamWindowItem", import("app.components.CopyComponent"))

function ArenaTeamWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.model_ = xyd.models.arenaTeam
	local needLoadRes = {}

	table.insert(needLoadRes, xyd.getTexturePath("arena_team_scene"))
	table.insert(needLoadRes, xyd.getTexturePath("arena_team_title_bg"))
	table.insert(needLoadRes, xyd.getTexturePath("arena_operator_bg"))
	table.insert(needLoadRes, xyd.getTexturePath("arena_team_title_") .. xyd.Global.lang)
	self:setResourcePaths(needLoadRes)
end

function ArenaTeamWindow:initWindow()
	ArenaTeamWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayout()
	self.model_:reqRankList()
	self:onGetArenaInfo()
	self:registerEvent()
end

function ArenaTeamWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.bg = winTrans:ComponentByName("bg", typeof(UITexture))

	xyd.setUITextureByNameAsync(self.bg, "arena_team_scene")

	self.mainGroup = winTrans:NodeByName("mainGroup").gameObject
	local textGroup = self.mainGroup:NodeByName("top").gameObject
	self.btnHelp = textGroup:NodeByName("btnHelp").gameObject
	local leftTitleImg = textGroup:ComponentByName("leftTitleImg", typeof(UITexture))
	local rightTitleImg = textGroup:ComponentByName("rightTitleImg", typeof(UITexture))

	xyd.setUITextureByNameAsync(leftTitleImg, "arena_team_title_bg")
	xyd.setUITextureByNameAsync(rightTitleImg, "arena_team_title_bg")

	self.imgTitle = textGroup:ComponentByName("imgTitle", typeof(UITexture))

	xyd.setUITextureByNameAsync(self.imgTitle, "arena_team_title_" .. xyd.Global.lang, true)

	self.labelTime = textGroup:ComponentByName("labelTime", typeof(UILabel))
	self.labelDDL = textGroup:ComponentByName("labelDDL", typeof(UILabel))
	self.groupRank = self.mainGroup:NodeByName("groupRank").gameObject
	self.scroller = self.groupRank:ComponentByName("scroller", typeof(UIScrollView))
	self.rankContainer = self.groupRank:NodeByName("scroller/rankContainer").gameObject
	local wrapContent = self.rankContainer:GetComponent(typeof(UIWrapContent))
	self.arena_team_window_item = self.groupRank:NodeByName("scroller/arena_team_window_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, self.arena_team_window_item, ArenaTeamWindowItem, self)

	self.wrapContent:hideItems()

	self.groupDetail = self.mainGroup:NodeByName("groupDetail").gameObject
	local leftDetailImg = self.groupDetail:ComponentByName("leftDetailImg", typeof(UITexture))
	local rightDetailImg = self.groupDetail:ComponentByName("rightDetailImg", typeof(UITexture))

	xyd.setUITextureByNameAsync(leftDetailImg, "arena_operator_bg")
	xyd.setUITextureByNameAsync(rightDetailImg, "arena_operator_bg")

	self.teamInfos = self.groupDetail:NodeByName("teamInfos").gameObject
	self.teamName = self.teamInfos:ComponentByName("teamName", typeof(UILabel))
	self.setting = self.teamInfos:NodeByName("setting").gameObject
	self.labelPower = self.teamInfos:ComponentByName("labelPower", typeof(UILabel))
	self.rankGroup = self.teamInfos:NodeByName("rankGroup").gameObject
	self.labelRank = self.rankGroup:ComponentByName("rankTextGroup/labelRank", typeof(UILabel))
	self.rank = self.rankGroup:ComponentByName("rank", typeof(UILabel))
	self.scoreGroup = self.teamInfos:NodeByName("scoreGroup").gameObject
	self.labelScore = self.scoreGroup:ComponentByName("ScoreTextGroup/labelScore", typeof(UILabel))
	self.score = self.scoreGroup:ComponentByName("score", typeof(UILabel))
	self.teamMem = self.groupDetail:NodeByName("teamMem").gameObject

	for i = 1, 3 do
		self["pIconGroup" .. tostring(i)] = self.teamMem:NodeByName("pIconGroup" .. tostring(i)).gameObject
	end

	self.guideTips = self.groupDetail:NodeByName("guideTips").gameObject
	local tipsTextGroup = self.guideTips:NodeByName("tipsTextGroup").gameObject
	self.arenaTeamTips = tipsTextGroup:ComponentByName("arenaTeamTips", typeof(UILabel))
	self.btnFight = self.groupDetail:NodeByName("btnFight").gameObject
	self.btnAward = self.groupDetail:NodeByName("btnAward").gameObject
	self.btnRecord = self.groupDetail:NodeByName("btnRecord").gameObject
	self.btnFormation = self.groupDetail:NodeByName("btnFormation").gameObject
	self.btnFightLabelDisplay = self.btnFight:ComponentByName("labelDisplay", typeof(UILabel))
	self.btnAwardLabelDisplay = self.btnAward:ComponentByName("labelDisplay", typeof(UILabel))
	self.btnRecordLabelDisplay = self.btnRecord:ComponentByName("labelDisplay", typeof(UILabel))
	self.btnFormationLabelDisplay = self.btnFormation:ComponentByName("labelDisplay", typeof(UILabel))
	self.btnFightRedMark = self.btnFight:ComponentByName("redMark", typeof(UISprite))
	self.seasonOpen = self.groupDetail:NodeByName("seasonOpen").gameObject
	self.leftSeasonImg = self.seasonOpen:ComponentByName("leftSeasonImg", typeof(UITexture))
	self.rightSeasonImg = self.seasonOpen:ComponentByName("rightSeasonImg", typeof(UITexture))

	xyd.setUITextureByNameAsync(self.leftSeasonImg, "arena_operator_bg")
	xyd.setUITextureByNameAsync(self.rightSeasonImg, "arena_operator_bg")

	self.seasonLabel = self.seasonOpen:ComponentByName("seasonLabel", typeof(UILabel))
	self.seasonCountDown = self.seasonOpen:ComponentByName("seasonCountDown", typeof(UILabel))
	self.mask_bg = winTrans:NodeByName("mask_bg").gameObject
end

function ArenaTeamWindow:initLayout()
	local callback = nil

	function callback()
		xyd.WindowManager:get():closeWindow(self.name_, function ()
			if self.params and self.params.lastWindow then
				xyd.WindowManager:get():openWindow(self.params.lastWindow)
			end
		end)
	end

	self.windowTop = WindowTop.new(self.window_, self.name_, 1, true, callback)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)

	self.arenaTeamTips.text = __("ARENA_TEAM_NO_TEAM_TIPS")
	self.labelTime.text = __("REST_TIME")
	self.teamName.text = self.model_:getTeamName()
	self.selfPower = self.model_:getPower()
	self.labelPower.text = tostring(self.selfPower)
	self.labelRank.text = __("RANK")
	self.labelScore.text = __("SCORE")
	self.btnAwardLabelDisplay.text = __("AWARD2")
	self.btnRecordLabelDisplay.text = __("RECORD")
	self.btnFormationLabelDisplay.text = __("DEFFORMATION")

	if xyd.lang == "de_de" then
		self.imgTitle:Y(-6)
		self.labelTime:SetLocalPosition(15, -50, 0)
		self.labelDDL:SetLocalPosition(25, -50, 0)

		self.btnAwardLabelDisplay.fontSize = 18
		self.btnRecordLabelDisplay.fontSize = 18
		self.btnFormationLabelDisplay.fontSize = 18

		self.seasonLabel:X(-30)
		self.seasonCountDown:X(-148)
	elseif xyd.Global.lang == "fr_fr" then
		self.seasonLabel:X(-165)
		self.seasonCountDown:X(42)
	elseif xyd.Global.lang == "ja_jp" then
		self.seasonCountDown:X(-105)
	end

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.ARENA_TEAM
	}, self.btnFightRedMark.gameObject)
end

function ArenaTeamWindow:setHasTeam(value)
	if value then
		self.guideTips:SetActive(false)
		self.teamInfos:SetActive(true)
		self.teamMem:SetActive(true)
	else
		self.guideTips:SetActive(true)
		self.teamInfos:SetActive(false)
		self.teamMem:SetActive(false)
	end
end

function ArenaTeamWindow:onGetArenaInfo()
	if self:checkOpen() then
		if not xyd.models.arenaTeam:getIsJoin() then
			local def_list = self.model_:getDefFormation()

			if def_list and #def_list <= 0 then
				xyd.WindowManager:get():openWindow("battle_formation_window", {
					battleType = xyd.BattleType.ARENA_TEAM_DEF,
					mapType = xyd.MapType.ARENA_TEAM,
					pet = self.model_:getPet(),
					callback = function ()
						xyd.WindowManager.get():closeWindow("arena_team_window")
					end
				})
			end

			self:setHasTeam(false)

			self.btnFightLabelDisplay.text = __("ARENA_TEAM_HALL_WINDOW")
		else
			self:setHasTeam(true)

			self.btnFightLabelDisplay.text = __("FIGHT2")
			local teamInfo = self.model_:getMyTeamInfo()
			local i = 1

			while i <= 3 do
				local player_id_now = teamInfo.players[i].player_id
				local info = {
					avatarID = teamInfo.players[i].avatar_id,
					lev = teamInfo.players[i].lev,
					partners = teamInfo.players[i].partners,
					avatar_frame_id = teamInfo.players[i].avatar_frame_id,
					callback = function ()
						xyd.WindowManager.get():openWindow("arena_team_formation_window", {
							hideBtn = true,
							player_id = player_id_now
						})
					end
				}

				NGUITools.DestroyChildren(self["pIconGroup" .. tostring(i)].transform)

				self["pIcon" .. tostring(i)] = PlayerIcon.new(self["pIconGroup" .. tostring(i)])

				self["pIcon" .. tostring(i)]:setInfo(info)

				if teamInfo.leader_id == teamInfo.players[i].player_id then
					self["pIcon" .. tostring(i)]:setCaptain(true)
				else
					self["pIcon" .. tostring(i)]:setCaptain(false)
				end

				i = i + 1
			end

			self.teamName.text = self.model_:getTeamName()

			if not self.model_:isCaptain() then
				self.setting:SetActive(false)
			end

			self:updataPower()
			self:updateRank()
			self:updateScore()
		end
	end

	self:updateDDL()
	self:setMask(false)
	self.window_:SetActive(true)
	self:checkTeamInfo()
end

function ArenaTeamWindow:updataPower()
	self.selfPower = self.model_:getPower()
	self.labelPower.text = tostring(self.selfPower)
end

function ArenaTeamWindow:updateRank()
	self.rank.text = tostring(self.model_:getRank())
end

function ArenaTeamWindow:updateScore()
	self.score.text = tostring(self.model_:getScore())
end

function ArenaTeamWindow:checkOpen()
	local startTime = self.model_:getStartTime() - xyd.getServerTime()

	return startTime < 0
end

function ArenaTeamWindow:updateDDL()
	local ddl = self.model_:getDDL() - xyd.getServerTime()

	if ddl <= 0 then
		self.labelDDL.text = "00:00:00"
	else
		self.labelDDL.text = xyd.secondsToString(ddl)
	end

	local startTime = self.model_:getStartTime() - xyd:getServerTime()

	if startTime > 0 then
		self.seasonOpen:SetActive(true)

		self.seasonLabel.text = __("OPEN_AFTER")
		self.seasonCountDown.text = xyd.secondsToString(startTime)

		self.labelDDL:SetActive(false)
		self.labelTime:SetActive(false)

		if self.seasonCount == nil then
			self.seasonCount = CountDown.new(self.seasonCountDown, {
				duration = math.floor(startTime)
			})
		else
			self.seasonCount:setInfo({
				duration = math.floor(startTime)
			})
		end

		self.btnRecord:SetActive(false)

		if startTime > xyd.TimePeriod.DAY_TIME * (xyd.ARENA_WAIT_TIME.ARENA_TEAM - 1) then
			self.btnRecord:SetActive(true)
		end
	else
		self.seasonOpen:SetActive(false)
		self.labelDDL:SetActive(true)
		self.labelTime:SetActive(true)

		if self.count == nil then
			self.count = CountDown.new(self.labelDDL, {
				duration = ddl
			})
		else
			self.count:setInfo({
				duration = ddl
			})
		end

		self.btnRecord:SetActive(true)
	end
end

function ArenaTeamWindow:onGetRankList()
	local ranklist = self.model_:getRankList()

	for i = 1, #ranklist do
		ranklist[i].rank = i
	end

	self.wrapContent:setInfos(ranklist, {})
end

function ArenaTeamWindow:setMask(flag)
	self.mask_bg:SetActive(flag)
end

function ArenaTeamWindow:registerEvent()
	BaseWindow.register(self)
	xyd.setDarkenBtnBehavior(self.btnHelp, self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ARENA_TEAM_HELP"
		})
	end)
	xyd.setDarkenBtnBehavior(self.btnFight, self, function ()
		if xyd.models.arenaTeam:getIsJoin() then
			if self.model_:isCaptain() then
				xyd.WindowManager.get():openWindow("arena_team_choose_player_window", {
					power = self.selfPower
				})
			else
				xyd.alert(xyd.AlertType.CONFIRM, __("ARENA_TEAM_LEADER_ONLY"))
			end
		elseif xyd.models.arenaTeam:getTeamId() and xyd.models.arenaTeam:getTeamId() > 0 then
			if #self.model_:getDefFormation() > 0 then
				xyd.WindowManager.get():openWindow("arena_team_my_team_window", {})
			end
		else
			xyd.WindowManager.get():openWindow("arena_team_hall_window", {})
		end
	end)
	xyd.setDarkenBtnBehavior(self.btnAward, self, function ()
		xyd.WindowManager.get():openWindow("arena_team_award_window", {})
	end)
	xyd.setDarkenBtnBehavior(self.btnRecord, self, function ()
		if self.guideTips.activeSelf then
			xyd.alert(xyd.AlertType.TIPS, __("ARENA_TEAM_RECORD_NO_TEAM_TIPS"))
		else
			xyd.WindowManager.get():openWindow("arena_team_record_window", {})
		end
	end)
	xyd.setDarkenBtnBehavior(self.btnFormation, self, function ()
		xyd.WindowManager.get():openWindow("battle_formation_window", {
			battleType = xyd.BattleType.ARENA_TEAM_DEF,
			formation = self.model_:getDefFormation(),
			mapType = xyd.MapType.ARENA_TEAM,
			pet = self.model_:getPet()
		})
	end)
	xyd.setDarkenBtnBehavior(self.setting, self, function ()
		xyd.WindowManager.get():openWindow("arena_team_change_team_window", {})
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ARENA_TEAM_INFO, handler(self, self.onGetArenaInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_ARENA_TEAM_RANK_LIST, handler(self, self.onGetRankList))
	self.eventProxy_:addEventListener(xyd.event.SET_ARENA_TEAM_PARTNERS, function ()
		self:updateRank()
		self:updateScore()
	end)
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_JOIN_TEAM, function ()
		self:onGetArenaInfo()
		self.model_:reqRankList()
	end)
end

function ArenaTeamWindow:playOpenAnimations(callback)
	local seq1 = DG.Tweening.DOTween.Sequence():OnComplete(function ()
		self:setWndComplete()
	end)
	local seq2 = DG.Tweening.DOTween.Sequence()
	local seq3 = DG.Tweening.DOTween.Sequence()
	local rank_pos = self.groupRank.transform.localPosition
	local detail_pos = self.groupDetail.transform.localPosition

	self.groupRank:setLocalPosition(-720, rank_pos.y, rank_pos.z)
	self.groupDetail:setLocalPosition(-720, detail_pos.y, detail_pos.z)
	seq1:Append(self.groupRank.transform:DOLocalMove(Vector3(50, rank_pos.y, rank_pos.z), 0.3))
	seq1:Append(self.groupRank.transform:DOLocalMove(rank_pos, 0.27))
	seq2:Append(self.groupDetail.transform:DOLocalMove(Vector3(50, detail_pos.y, detail_pos.z), 0.3))
	seq2:Append(self.groupDetail.transform:DOLocalMove(detail_pos, 0.27))

	local w = self.bg.gameObject:GetComponent(typeof(UIWidget))
	w.alpha = 0.01

	seq3:Append(xyd.getTweenAlpha(self.bg, 1, 0.2))
	callback()
end

function ArenaTeamWindow:checkTeamInfo()
	local teamInfo = xyd.models.arenaTeam:getMyTeamInfo()

	if teamInfo == nil then
		if xyd.WindowManager.get():isOpen("arena_team_my_team_window") then
			xyd.WindowManager.get():closeWindow("arena_team_my_team_window")
		end

		if xyd.WindowManager.get():isOpen("arena_team_invite_window") then
			xyd.WindowManager.get():closeWindow("arena_team_invite_window")
		end

		if xyd.WindowManager.get():isOpen("arena_team_apply_window") then
			xyd.WindowManager.get():closeWindow("arena_team_apply_window")
		end

		if xyd.WindowManager.get():isOpen("arena_team_formation_window") then
			xyd.WindowManager.get():closeWindow("arena_team_formation_window")
		end
	else
		if xyd.WindowManager.get():isOpen("arena_team_hall_window") then
			xyd.WindowManager.get():closeWindow("arena_team_hall_window")
		end

		if xyd.WindowManager.get():isOpen("arena_team_invitation_window") then
			xyd.WindowManager.get():closeWindow("arena_team_invitation_window")
		end

		if xyd.WindowManager.get():isOpen("arena_team_create_window") then
			xyd.WindowManager.get():closeWindow("arena_team_create_window")
		end

		local myTeamWnd = xyd.WindowManager.get():getWindow("arena_team_my_team_window")

		if myTeamWnd then
			myTeamWnd:initTeam()
		end
	end
end

function ArenaTeamWindow:getScrollerView()
	return self.scroller
end

function ArenaTeamWindowItem:ctor(go, parent)
	ArenaTeamWindowItem.super.ctor(self, go)

	self.parent = parent

	self:setDragScrollView(parent:getScrollerView())
	self:getUIComponent()
	self:registerEvent()
end

function ArenaTeamWindowItem:getUIComponent()
	local go = self.go
	self.bg = go:ComponentByName("bg", typeof(UISprite))
	self.imgRank = go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	local iconGroup = go:NodeByName("iconGroup").gameObject

	for i = 1, 3 do
		self["pIconGroup" .. tostring(i)] = iconGroup:NodeByName("pIconGroup" .. tostring(i)).gameObject
	end

	self.teamName = go:ComponentByName("teamName", typeof(UILabel))
	self.power = go:ComponentByName("power", typeof(UILabel))
	self.labelPoint = go:ComponentByName("labelPoint", typeof(UILabel))
	self.point = go:ComponentByName("point", typeof(UILabel))
	local serverInfo = go:NodeByName("serverInfo").gameObject
	self.serverInfo = serverInfo
	self.serverId = serverInfo:ComponentByName("serverId", typeof(UILabel))
end

function ArenaTeamWindowItem:setInfo(params)
	self.params = params
	local i = 1

	while i <= 3 do
		local info = {
			avatarID = params.player_infos[i].avatar_id,
			lev = params.player_infos[i].lev,
			avatar_frame_id = params.player_infos[i].avatar_frame_id
		}

		self["pIcon" .. tostring(i)]:setInfo(info)

		i = i + 1
	end

	self.teamName.text = params.team_name

	if params.rank > 3 then
		self.imgRank:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = params.rank

		xyd.setUISpriteAsync(self.bg, nil, "9gongge17", function ()
		end)
	else
		self.imgRank:SetActive(true)
		self.labelRank:SetActive(false)
		xyd.setUISpriteAsync(self.imgRank, nil, "rank_icon0" .. tostring(params.rank), function ()
		end)

		local bg = {
			"9gongge30_png",
			"9gongge31_png",
			"9gongge32_png"
		}

		xyd.setUISpriteAsync(self.bg, nil, bg[params.rank], function ()
		end)
	end

	self.power.text = tostring(params.power)
	self.labelPoint.text = __("SCORE")
	self.point.text = params.score
	self.serverId.text = xyd.getServerNumber(params.server_id)

	self.serverInfo:SetActive(xyd.models.arenaTeam:isShowServerId(params.server_id))
end

function ArenaTeamWindowItem:registerEvent()
	UIEventListener.Get(self.go).onClick = function ()
		if xyd.models.arenaTeam:checkOpen() then
			xyd.WindowManager.get():openWindow("arena_team_formations_window", {
				player_id = self.params.player_ids[1]
			})
		end
	end
end

function ArenaTeamWindowItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	for i = 1, 3 do
		if not self["pIcon" .. tostring(i)] then
			self["pIcon" .. tostring(i)] = PlayerIcon.new(self["pIconGroup" .. tostring(i)], self.parent:getScrollerView().gameObject:GetComponent(typeof(UIPanel)))
		end
	end

	self.go:SetActive(true)
	self:setInfo(info)
end

return ArenaTeamWindow
