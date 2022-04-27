local BaseWindow = import(".BaseWindow")
local ActivitySportsFightWindow = class("ActivitySportsFightWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local PngNum = import("app.components.PngNum")
local ActivitySportsFightItem = class("ActivitySportsFightItem", import("app.components.CopyComponent"))

function ActivitySportsFightItem:ctor(parentGo, parent)
	self.parent_ = parent

	ActivitySportsFightItem.super.ctor(self, parentGo)
end

function ActivitySportsFightItem:initUI()
	self:getComponent()
	ActivitySportsFightItem.super.initUI(self)
	self:createChildren()
end

function ActivitySportsFightItem:getComponent()
	self.goTrans = self.go.transform
	self.bg = self.goTrans:ComponentByName("bg", typeof(UISprite))
	self.selectedImg = self.goTrans:ComponentByName("selectedImg", typeof(UITexture))
	self.groupImg = self.goTrans:ComponentByName("groupImg", typeof(UISprite))
	self.pIcon = self.goTrans:NodeByName("pIcon").gameObject
	local PlayerIcon = import("app.components.PlayerIcon")
	self.pIcon = PlayerIcon.new(self.pIcon)
	self.playerName = self.goTrans:ComponentByName("playerName", typeof(UILabel))
	self.power = self.goTrans:ComponentByName("power", typeof(UILabel))
	self.labelPoint = self.goTrans:ComponentByName("labelPoint", typeof(UILabel))
	self.point = self.goTrans:ComponentByName("point", typeof(UILabel))
	self.serverInfo = self.goTrans:NodeByName("serverInfo").gameObject
	self.serverId = self.serverInfo:ComponentByName("serverId", typeof(UILabel))
end

function ActivitySportsFightItem:setSelect(isSelect)
	self.selectedImg:SetActive(isSelect)
end

function ActivitySportsFightItem:update(index, params)
	if not params then
		return
	end

	self.params = params

	self.pIcon:setInfo({
		avatarID = params.avatar_id,
		lev = params.lev,
		avatar_frame_id = params.avatar_frame_id,
		callback = function ()
			xyd.WindowManager.get():openWindow("activity_sports_enemy_window", {
				matchInfo = self.params
			})
		end
	})

	self.playerName.text = params.player_name

	if xyd.Global.lang ~= "zh_tw" then
		self.serverInfo:Y(-15)
	else
		self.serverInfo:Y(23)
	end

	self.itemIndex = index
	self.power.text = params.power
	self.labelPoint.text = __("SCORE")
	self.point.text = params.score
	self.serverId.text = xyd.getServerNumber(params.server_id)

	if not params.server_id then
		self.serverId.text = "S999"
	end

	self:setSelect(false)

	if params.group then
		xyd.setUISpriteAsync(self.groupImg, nil, "sports_group_shaddow_" .. tostring(params.group), nil, )
	end
end

function ActivitySportsFightItem:createChildren()
	UIEventListener.Get(self.go.gameObject).onClick = function ()
		local win = xyd.WindowManager.get():getWindow("activity_sports_fight_window")

		if win then
			win:selectItem(self.itemIndex)
		end
	end
end

function ActivitySportsFightWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.enemyList = {}
	self.selectIndex = -1
	self.clickRank = false
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPORTS)
	self.itemList = {}
end

function ActivitySportsFightWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:registerEvent()
end

function ActivitySportsFightWindow:playOpenAnimation(callback)
	self:updateLayout()

	local msg = messages_pb:sports_get_match_infos_req()
	msg.activity_id = xyd.ActivityID.SPORTS

	xyd.Backend:get():request(xyd.mid.SPORTS_GET_MATCH_INFOS, msg)
	ActivitySportsFightWindow.super.playOpenAnimation(self, callback)
end

function ActivitySportsFightWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.imgBg = self.groupAction:ComponentByName("imgBg", typeof(UISprite))
	self.e_Group = self.groupAction:NodeByName("e:Group").gameObject
	self.closeBtn = self.e_Group:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.e_Group:ComponentByName("labelWinTitle", typeof(UILabel))
	self.helpBtn0 = self.e_Group:NodeByName("helpBtn0").gameObject
	self.rankNode = self.groupAction:NodeByName("rankNode").gameObject
	self.rankListScroller = self.rankNode:NodeByName("rankListScroller").gameObject
	self.rankListScroller_scrollview = self.rankNode:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListContainer = self.rankListScroller:NodeByName("rankListContainer").gameObject
	self.rankListContainer_layout = self.rankListScroller:ComponentByName("rankListContainer", typeof(UILayout))
	self.drag = self.rankNode:NodeByName("drag").gameObject
	self.groupNone = self.rankNode:NodeByName("groupNone").gameObject
	self.labelNone = self.groupNone:ComponentByName("labelNone", typeof(UILabel))
	self.guess2btn = self.rankNode:NodeByName("guess2btn").gameObject
	self.guess2btn_label = self.guess2btn:ComponentByName("button_label", typeof(UILabel))
	self.guess2btnicon = self.guess2btn:ComponentByName("guess2btnicon", typeof(UISprite))
	self.guess2btn_uilayout = self.rankNode:ComponentByName("guess2btn", typeof(UILayout))
	self.update2btn = self.rankNode:NodeByName("update2btn").gameObject
	self.update2btn_label = self.update2btn:ComponentByName("button_label", typeof(UILabel))
	self.update2btnicon = self.update2btn:ComponentByName("update2btnicon", typeof(UISprite))
	self.tipWords = self.groupAction:ComponentByName("tipWords", typeof(UILabel))
	self.tiliNode = self.groupAction:NodeByName("tiliNode").gameObject
	self.noEnemyWords = self.groupAction:ComponentByName("noEnemyWords", typeof(UILabel))
	self.tiliText = self.tiliNode:ComponentByName("tiliText", typeof(UILabel))
	self.groupDetail = self.groupAction:NodeByName("groupDetail").gameObject
	self.pIconCon = self.groupDetail:NodeByName("pIcon").gameObject
	self.labelPower = self.groupDetail:ComponentByName("labelPower", typeof(UILabel))
	self.rankGroupAll = self.groupDetail:NodeByName("rankGroupAll").gameObject
	self.rankGroup = self.rankGroupAll:NodeByName("rankGroup").gameObject
	self.labelRank = self.rankGroup:ComponentByName("labelRank", typeof(UILabel))
	self.rank = self.rankGroupAll:ComponentByName("rank", typeof(UILabel))
	self.scoreGroupAll = self.groupDetail:NodeByName("scoreGroupAll").gameObject
	self.scoreGroup = self.scoreGroupAll:NodeByName("scoreGroup").gameObject
	self.labelScore = self.scoreGroup:ComponentByName("labelScore", typeof(UILabel))
	self.score = self.scoreGroupAll:ComponentByName("score", typeof(UILabel))
	self.upCenterImg = self.groupDetail:ComponentByName("upCenterImg", typeof(UISprite))
	self.scoreImg = self.groupDetail:ComponentByName("scoreImg", typeof(UITexture))
	self.scoreNode = self.groupDetail:NodeByName("scoreNode").gameObject
	self.scoreNode = PngNum.new(self.scoreNode)
	self.btnAward = self.groupDetail:NodeByName("btnAward").gameObject
	self.btnAward_icon = self.btnAward:ComponentByName("icon", typeof(UISprite))
	self.btnAward_label = self.btnAward:ComponentByName("button_label", typeof(UILabel))
	self.btnRecord = self.groupDetail:NodeByName("btnRecord").gameObject
	self.btnRecord_icon = self.btnRecord:ComponentByName("icon", typeof(UISprite))
	self.btnRecord_label = self.btnRecord:ComponentByName("button_label", typeof(UILabel))
	self.btnFormation = self.groupDetail:NodeByName("btnFormation").gameObject
	self.btnFormation_icon = self.btnFormation:ComponentByName("icon", typeof(UISprite))
	self.btnFormation_label = self.btnFormation:ComponentByName("button_label", typeof(UILabel))
	self.seasonOpen = self.groupDetail:NodeByName("seasonOpen").gameObject
	self.seasonLabel = self.seasonOpen:ComponentByName("seasonLabel", typeof(UILabel))
	self.seasonCountDown = self.seasonOpen:ComponentByName("seasonCountDown", typeof(UILabel))
	self.energyTips = self.groupAction:NodeByName("energyTips").gameObject
	self.labelNextEnergy = self.energyTips:ComponentByName("labelNextEnergy", typeof(UILabel))
	self.energyCountDown = self.energyTips:ComponentByName("energyCountDown", typeof(UILabel))
	self.activity_sports_fight_item = self.groupAction:NodeByName("activity_sports_fight_item").gameObject
end

function ActivitySportsFightWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))

	UIEventListener.Get(self.guess2btn.gameObject).onClick = handler(self, function ()
		if self.selectIndex < 0 then
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.TIPS,
				message = __("ACTIVITY_SPORTS_SELECT_HERO_TIP_2")
			})

			return
		end

		if self.activityData.detail.arena_info.energy <= 0 then
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.TIPS,
				message = __("FRIEND_NO_TILI")
			})

			return
		end

		local enemyId = self.matchData.match_infos[self.selectIndex + 5 * (self.matchData.fight_index - 1)].player_id

		xyd.WindowManager.get():openWindow("battle_formation_window", {
			showSkip = true,
			battleType = xyd.BattleType.SPORTS_PVP,
			mapType = xyd.MapType.SPORTS_PVP,
			enemy_id = enemyId,
			skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("sports_skip_report")) == 1, true, false),
			btnSkipCallback = function (flag)
				local value = xyd.checkCondition(flag == true, 1, 0)

				xyd.db.misc:setValue({
					key = "sports_skip_report",
					value = value
				})
			end
		})
	end)
	UIEventListener.Get(self.update2btn.gameObject).onClick = handler(self, self.updateEnemyList)
	UIEventListener.Get(self.helpBtn0.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_SPORTS_FIGHT_WINDOW_HELP"
		})
	end)
	UIEventListener.Get(self.btnAward.gameObject).onClick = handler(self, function ()
		self.clickRank = true

		self:getRankListInfo()
	end)
	UIEventListener.Get(self.btnRecord.gameObject).onClick = handler(self, function ()
		local msg = messages_pb:sports_get_arena_records_req()
		msg.activity_id = xyd.ActivityID.SPORTS

		xyd.Backend:get():request(xyd.mid.SPORTS_GET_ARENA_RECORDS, msg)
	end)
	UIEventListener.Get(self.btnFormation.gameObject).onClick = handler(self, self.openFormationWnd)

	UIEventListener.Get(self.closeBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.eventProxy_:addEventListener(xyd.event.SPORTS_GET_RANK_LIST, handler(self, self.openRankWindow))
	self.eventProxy_:addEventListener(xyd.event.SPORTS_FIGHT, handler(self, self.sportsFight))
	self.eventProxy_:addEventListener(xyd.event.SPORTS_GET_MATCH_INFOS, handler(self, self.onMatchInfo))
	self.eventProxy_:addEventListener(xyd.event.SPORTS_GET_RANK_LIST, handler(self, self.updateRank))
	self.eventProxy_:addEventListener(xyd.event.SPORTS_GET_ARENA_RECORDS, function (____, event)
		xyd.WindowManager.get():openWindow("activity_sports_fight_record_window", {
			eventData = event.data,
			playerGroup = self.activityData.detail.arena_info.group
		})
	end, self)

	UIEventListener.Get(self.tiliNode.gameObject).onPress = function (go, isPress)
		if isPress then
			self.energyTips:SetActive(true)
		else
			self.energyTips:SetActive(false)
		end
	end
end

function ActivitySportsFightWindow:onActivityByID()
	self:updateTili()
	self:layout()
end

function ActivitySportsFightWindow:getRankListInfo()
	local rankType = xyd.ActivitySportsRankType.FIGHT_POINT_2

	if self.activityData:getNowState() <= 3 then
		rankType = xyd.ActivitySportsRankType.FIGHT_POINT_1
	end

	local msg = messages_pb:sports_get_rank_list_req()
	msg.activity_id = xyd.ActivityID.SPORTS
	msg.rank_type = rankType

	xyd.Backend.get():request(xyd.mid.SPORTS_GET_RANK_LIST, msg)
end

function ActivitySportsFightWindow:updateLayout()
	self:selectItem(-1)
	self:updateTili()
	self:layout()
	self:updatePower()

	if self:checkNeedSetFormation() then
		self:openFormationWnd(nil, true)
	end
end

function ActivitySportsFightWindow:selectItem(index)
	self.selectIndex = index

	for i, child in pairs(self.itemList) do
		if child.itemIndex == index then
			child:setSelect(true)
		else
			child:setSelect(false)
		end
	end
end

function ActivitySportsFightWindow:openRankWindow(event)
	if self.clickRank then
		xyd.WindowManager.get():openWindow("activity_sports_rank_window", {
			rankData = event.data,
			activityData = self.activityData
		})

		self.clickRank = false
	end
end

function ActivitySportsFightWindow:sportsFight(event)
	local a = 0
	self.activityData.detail.arena_info.point = event.data.score
	self.activityData.detail.arena_info.energy = self.activityData.detail.arena_info.energy - 1
	self.matchData.fight_index = self.matchData.fight_index + 1

	if math.ceil(#self.matchData.match_infos / 5) < self.matchData.fight_index then
		local msg = messages_pb:sports_get_match_infos_req()
		msg.activity_id = xyd.ActivityID.SPORTS

		xyd.Backend.get():request(xyd.mid.SPORTS_GET_MATCH_INFOS, msg)
	end

	self:getEnemyList()
	self:updateLayout()
	self:updateRank(event)

	self.selectIndex = -1
end

function ActivitySportsFightWindow:updateEnemyList()
	self.matchData.fight_index = self.matchData.fight_index + 1

	if math.ceil(#self.matchData.match_infos / 5) < self.matchData.fight_index then
		self.matchData.fight_index = 1
	end

	self:getEnemyList()

	self.selectIndex = -1
end

function ActivitySportsFightWindow:onMatchInfo(event)
	self.matchData = event.data

	self:getEnemyList()
end

function ActivitySportsFightWindow:updateRank(event)
	if not event.data.rank_type or event.data.rank_type > 6 then
		self.activityData.selfRank = event.data.rank
	end

	if event.data.total_num then
		self.activityData.totalRankNum = event.data.total_num
	end

	self:updateRankText()
end

function ActivitySportsFightWindow:checkNeedSetFormation()
	local length = #self.activityData.detail.arena_info.partners

	if length == nil or length == 0 then
		return true
	end

	return false
end

function ActivitySportsFightWindow:updatePower()
	local power = 0

	for i, p in ipairs(self.activityData.detail.arena_info.partners) do
		power = power + p.power
	end

	self.labelPower.text = tostring(power) .. ""
end

function ActivitySportsFightWindow:updateTili()
	local point = self.activityData.detail.arena_info.point
	self.tiliText.text = tostring(self.activityData.detail.arena_info.energy) .. "/" .. tostring(xyd.tables.activitySportsEnergyTable:getMaxByScore(point))
end

function ActivitySportsFightWindow:getEnemyList()
	self.enemyList = {}
	local startIndex = (self.matchData.fight_index - 1) * 5 + 1

	if self.matchData.fight_index ~= 0 then
		for i = startIndex, startIndex + 4 do
			if i <= #self.matchData.match_infos then
				table.insert(self.enemyList, self.matchData.match_infos[i])

				if not self.matchData.match_infos[i].group then
					local randomGroup = self.activityData.detail.arena_info.group

					while randomGroup == self.activityData.detail.arena_info.group or randomGroup == 7 do
						randomGroup = math.floor(math.random() * 6 + 0.5) + 1
					end

					self.matchData.match_infos[i].group = randomGroup
					self.matchData.match_infos[i].player_name = __("ACTIVITY_SPORTS_ROBOT_NAME", __("GROUP_" .. tostring(randomGroup)))
				elseif self.matchData.match_infos[i].is_robot then
					self.matchData.match_infos[i].player_name = __("ACTIVITY_SPORTS_ROBOT_NAME", __("GROUP_" .. tostring(self.matchData.match_infos[i].group)))
				end
			end
		end

		self.guess2btn:SetActive(true)
	else
		self.guess2btn:SetActive(false)
	end

	if self.activityData:getNowState() == xyd.ActivitySportsTime.FIGHT_SUPER and not self.activityData.detail.arena_info.elite_select or self.activityData:getNowState() == xyd.ActivitySportsTime.ASSEMBLE or self.activityData:getNowState() == xyd.ActivitySportsTime.CALCULATION or self.activityData:getNowState() == xyd.ActivitySportsTime.SHOW then
		self.noEnemyWords:SetActive(true)
		self.guess2btn:SetActive(false)

		self.enemyList = {}
		self.labelNone.text = __("ACTIVITY_SPORTS_NOT_ENTER_600")
	else
		self.noEnemyWords:SetActive(false)
	end

	if #self.enemyList == 0 then
		self.guess2btn:SetActive(false)
	end

	if #self.itemList == 0 then
		for i in ipairs(self.enemyList) do
			local tmp = NGUITools.AddChild(self.rankListContainer.gameObject, self.activity_sports_fight_item.gameObject)
			local item = ActivitySportsFightItem.new(tmp, self)

			table.insert(self.itemList, item)
			item:update(i, self.enemyList[i])
		end
	else
		for i in ipairs(self.enemyList) do
			self.itemList[i]:update(i, self.enemyList[i])
		end
	end

	self.rankListContainer_layout:Reposition()
	self.rankListScroller_scrollview:ResetPosition()
end

function ActivitySportsFightWindow:layout()
	local avatar = xyd.models.selfPlayer:getAvatarID()
	local lev = xyd.models.backpack:getLev()
	local PlayerIcon = import("app.components.PlayerIcon")

	if not self.pIcon then
		self.pIcon = PlayerIcon.new(self.pIconCon)
	end

	self.pIcon:setInfo({
		avatarID = avatar,
		lev = lev,
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID()
	})
	self.pIcon:setScale(0.8)

	self.noEnemyWords.text = __("ACTIVITY_SPORTS_CANT_FIGHT")
	self.labelRank.text = __("RANK")
	self.labelScore.text = __("ACTIVITY_SPORTS_GROUP")
	self.guess2btn_label.text = __("FIGHT2")

	self.guess2btn_uilayout:Reposition()
	xyd.setUITextureByNameAsync(self.scoreImg, "activity_sports_score_" .. xyd.Global.lang, true)

	self.labelNextEnergy.text = __("NEXT_ENERGY")
	local nextTime = xyd.getServerTime() - self.activityData.detail.arena_info.energy_time
	local point = self.activityData.detail.arena_info.point
	local cdTime = xyd.tables.activitySportsEnergyTable:getCdByPoint(point)

	if self.setCountDownTime then
		self.setCountDownTime:dispose()

		self.setCountDownTime = nil
	end

	self.setCountDownTime = CountDown.new(self.energyCountDown, {
		duration = cdTime - nextTime % cdTime,
		callback = function ()
			self.energyCountDown.text = "00:00:00"

			self:waitForTime(2, function ()
				xyd.models.activity:reqActivityByID(xyd.ActivityID.SPORTS)
			end)
		end
	})

	if nextTime < 0 then
		self.energyCountDown.text = "00:00:00"
	end

	self.btnAward_label.text = __("AWARD2")
	self.btnRecord_label.text = __("RECORD")

	if xyd.Global.lang == "de_de" then
		self.btnAward_label.fontSize = 18
		self.btnRecord_label.fontSize = 18
	end

	self.btnFormation_label.text = __("DEFFORMATION")
	self.tipWords.text = __("ACTIVITY_SPORTS_SELECT_HERO_TIP")

	self:updateScore()
	self:updateRankText()
end

function ActivitySportsFightWindow:updateRankText()
	local selfAwardInfo = xyd.tables.activitySportsRankAward2Table:getRankInfo(self.activityData.selfRank)

	if self.activityData:getNowState() <= 3 then
		selfAwardInfo = xyd.tables.activitySportsRankAward1Table:getRankInfo(self.activityData.selfRank, self.activityData.totalRankNum)
	end

	self.rank.text = selfAwardInfo.rankText

	if self.activityData:getNowState() <= 3 and self.activityData.selfRank and self.activityData.selfRank <= 100 then
		self.rank.text = self.activityData.selfRank
	end
end

function ActivitySportsFightWindow:updateScore()
	self.score.text = __("GROUP_" .. tostring(self.activityData.detail.arena_info.group))
	local score = self.activityData.detail.arena_info.point

	self.scoreNode:setInfo({
		iconName = "activity_sports",
		num = score
	})

	local win = xyd.WindowManager.get():getWindow("activity_sports_window")

	if win then
		win:updateScore()
	end
end

function ActivitySportsFightWindow:openFormationWnd(event, isForce)
	local params = {
		battleType = xyd.BattleType.SPORTS_PVP_DEF,
		formation = self.activityData.detail.arena_info.partners,
		pet = self.activityData.detail.arena_info.pet.pet_id,
		mapType = xyd.MapType.SPORTS_PVP
	}

	if isForce then
		function params.callback()
			xyd.WindowManager.get():closeWindow("activity_sports_fight_window")
		end
	end

	xyd.WindowManager.get():openWindow("battle_formation_window", params)
end

function ActivitySportsFightWindow:handleEnergyTips(event)
	if self.activityData:getNowState() == xyd.ActivitySportsTime.SHOW then
		return
	end

	self.energyTips:SetActive(true)
end

return ActivitySportsFightWindow
