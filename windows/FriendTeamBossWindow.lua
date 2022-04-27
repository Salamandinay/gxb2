local BaseWindow = import(".BaseWindow")
local FriendTeamBossWindow = class("FriendTeamBossWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local PlayerIcon = import("app.components.PlayerIcon")
local CountDown = import("app.components.CountDown")
local BaseComponent = import("app.components.BaseComponent")
local FriendTeamBossWeatherTips = class("FriendTeamBossWeatherTips", BaseComponent)

function FriendTeamBossWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "FriendTeamBossWindowSkin2"
	self.currentState = xyd.Global.lang
end

function FriendTeamBossWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()

	if not xyd.models.friendTeamBoss:getTeamInfo() then
		xyd.models.friendTeamBoss:reqInfo()

		local list = xyd.models.chat:getMsgsByType(xyd.MsgType.FRIEND_TEAM_BOSS_CHAT)

		if not list or #list == 0 then
			xyd.models.chat:getFriendTeamBossMsg()
		end
	else
		self.gContent:SetActive(false)
		self:layout()
		self:checkGuide()
		self:checkResult()

		local list = xyd.models.chat:getMsgsByType(xyd.MsgType.FRIEND_TEAM_BOSS_CHAT)

		if not list or #list == 0 then
			xyd.models.chat:getFriendTeamBossMsg()
		end
	end

	if xyd.Global.lang == "de_de" then
		self.gWeather:X(250)
		self.btnDressShow:X(165)
	end

	self:initResItem()
end

function FriendTeamBossWindow:getUIComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("content").gameObject
	self.bg = content:ComponentByName("bg", typeof(UITexture))

	xyd.setUITextureAsync(self.bg, "Textures/friend_team_boss_web/friend_team_boss_bg2")

	self.gContent = content:NodeByName("gContent").gameObject
	self.gWeather = self.gContent:NodeByName("gWeather").gameObject
	self.btnDressShow = self.gContent:NodeByName("btnDressShow").gameObject
	self.weatherBgImage = self.gWeather:NodeByName("weatherBgImage").gameObject
	self.weatherImg = self.gWeather:ComponentByName("weatherImg", typeof(UISprite))
	self.weatherLabel = self.gWeather:ComponentByName("weatherLabel", typeof(UILabel))
	self.gBoss = self.gContent:NodeByName("gBoss").gameObject

	for i = 1, 3 do
		local boss = self.gBoss:NodeByName("gBoss" .. i).gameObject
		self["gBoss" .. i] = boss
		self["lableBossHp" .. i] = boss:ComponentByName("lableBossHp" .. i, typeof(UILabel))
		self["bossImg" .. i] = boss:ComponentByName("imgGroup/bossImg" .. i, typeof(UISprite))
		self["bossFrame" .. i] = boss:ComponentByName("imgGroup/bossFrame" .. i, typeof(UISprite))
	end

	self.btnQuit = self.gContent:NodeByName("btnQuit").gameObject
	self.gEffect2 = self.gContent:ComponentByName("gEffect2", typeof(UISprite))
	self.bot = self.gContent:NodeByName("bot").gameObject
	self.imgFlag = self.bot:ComponentByName("imgFlag", typeof(UISprite))
	self.gPlayers = self.bot:NodeByName("gPlayers").gameObject

	for i = 1, 3 do
		local item = self.gPlayers:NodeByName("item" .. i).gameObject
		self["item" .. i] = item
		self["gItemEffect" .. i] = item:ComponentByName("gItemEffect" .. i, typeof(UISprite))
	end

	self.teamMem = self.bot:NodeByName("teamMem").gameObject
	self.teamMemTable = self.teamMem:GetComponent(typeof(UITable))

	for i = 1, 3 do
		local iconContainer = self.teamMem:NodeByName("pIcon" .. i).gameObject
		self["pIcon" .. i] = PlayerIcon.new(iconContainer)
	end

	self.btnInvite = self.bot:NodeByName("btnInvite").gameObject
	self.btnInviteLabel = self.btnInvite:ComponentByName("button_label", typeof(UILabel))
	self.btnInviteRedPoint = self.btnInvite:NodeByName("redPoint").gameObject
	self.btnMsg = self.bot:NodeByName("btnMsg").gameObject
	self.btnMsgLabel = self.btnMsg:ComponentByName("button_label", typeof(UILabel))
	self.btnMsgRedPoint = self.btnMsg:NodeByName("redPoint").gameObject
	self.teamNameGroup = self.bot:NodeByName("teamNameGroup").gameObject
	self.labelName = self.teamNameGroup:ComponentByName("labelName", typeof(UILabel))
	self.weatherTips = self.gContent:NodeByName("weatherTips").gameObject
	self.top = self.gContent:NodeByName("top").gameObject
	self.leftGroup = self.top:NodeByName("leftGroup").gameObject
	self.LabelLeftNum = self.leftGroup:ComponentByName("LabelLeftNum", typeof(UILabel))
	self.plusBtn = self.leftGroup:NodeByName("btnGroup/plusBtn").gameObject
	self.gCountDown = self.top:NodeByName("gCountDown").gameObject
	self.labelCountDown = self.gCountDown:ComponentByName("labelCountDown", typeof(UILabel))
	local ddl2NumLabel = self.gCountDown:ComponentByName("ddl2Num", typeof(UILabel))
	self.ddl2Num = CountDown.new(ddl2NumLabel)
	self.btnAward = self.top:NodeByName("btnAward").gameObject
	self.btnRecord = self.top:NodeByName("btnRecord").gameObject
	self.helpBtn = self.top:NodeByName("helpBtn").gameObject
	self.gEffect = content:NodeByName("gEffect").gameObject
	self.goModel = content:NodeByName("goModel").gameObject
	self.bgEffect_ = content:NodeByName("bgEffect").gameObject
	self.effectChris1_ = xyd.WindowManager.get():setChristmasEffect(self.bgEffect_, true)
end

function FriendTeamBossWindow:initResItem()
	local winTop = WindowTop.new(self.window_, self.name_, 1, true)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	winTop:setItem(items)
end

function FriendTeamBossWindow:register()
	FriendTeamBossWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_FRIEND_TEAM_BOSS_INFO, function ()
		self:layout()
		self:checkGuide()
		self:checkResult()
	end)
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_ACCEPT_APPLY, handler(self, self.layout))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_ACCEPT_INVITE, handler(self, self.layout))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_EXIT_TEAM, handler(self, self.layout))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_KICKOUT_FRIEND, handler(self, self.layout))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_EXIT_TEAM, handler(self, self.layout))
	self.eventProxy_:addEventListener(xyd.event.MODIFY_FRIEND_TEAM_BOSS_TEAM_INFO, handler(self, self.layout))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_FIGHT, handler(self, self.layout))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_BUY_ATTACK_TIMES, function ()
		self.LabelLeftNum.text = __("LEFT_TIMES", xyd.models.friendTeamBoss:getSelfInfo().can_attack_times)
	end)

	for i = 1, 3 do
		UIEventListener.Get(self["item" .. tostring(i)]).onClick = function ()
			self:onClickInviteFriends()
		end

		UIEventListener.Get(self["gBoss" .. tostring(i)]).onClick = function ()
			self:onClickBoss(i)
		end
	end

	UIEventListener.Get(self.btnMsg).onClick = function ()
		self:onClickMsg()
	end

	UIEventListener.Get(self.btnInvite).onClick = function ()
		if xyd.models.friendTeamBoss:checkInFight() then
			xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_IN_FIGHT"))

			return
		end

		xyd.WindowManager.get():openWindow("friend_team_boss_apply_window")
	end

	UIEventListener.Get(self.btnRecord).onClick = function ()
		self:onClickRecord()
	end

	UIEventListener.Get(self.plusBtn).onClick = function ()
		self:onClickBuyTimes()
	end

	UIEventListener.Get(self.imgFlag.gameObject).onClick = function ()
		self:onClickFlag()
	end

	UIEventListener.Get(self.labelName.gameObject).onClick = function ()
		self:onClickName()
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
		self:onClickBtnAward()
	end

	UIEventListener.Get(self.weatherBgImage).onPress = function (go, isPressed)
		self:handleWeatherTips(isPressed)
	end

	UIEventListener.Get(self.btnDressShow).onClick = function ()
		xyd.WindowManager.get():openWindow("dress_show_buffs_detail_window", {
			function_id = xyd.FunctionID.FRIEND_TEAM_BOSS
		})
	end
end

function FriendTeamBossWindow:handleWeatherTips(isPressed)
	if isPressed then
		self:showWeatherTips()
	else
		self:clearWeatherTips()
	end
end

function FriendTeamBossWindow:updateRedMark()
	local state = false
	local state_ = false
	local state1 = xyd.models.redMark:getRedState(xyd.RedMarkType.FRIEND_TEAM_BOSS_APPLY)
	local state2 = xyd.models.redMark:getRedState(xyd.RedMarkType.FRIEND_TEAM_BOSS_INVITED)
	local state3 = xyd.models.redMark:getRedState(xyd.RedMarkType.FRIEND_TEAM_BOSS_MSG)
	local state4 = xyd.models.redMark:getRedState(xyd.RedMarkType.FRIEND_TEAM_BOSS_MSG2)
	state = state1 or state2
	state_ = state3 or state4

	self.btnInviteRedPoint:SetActive(state)
	self.btnMsgRedPoint:SetActive(state_)
end

function FriendTeamBossWindow:showWeatherTips()
	local weatherID = xyd.models.friendTeamBoss:getWeatherID()

	if weatherID then
		if self.weatherTips.transform.childCount > 0 then
			self.weatherTips:SetActive(true)
		else
			local item = FriendTeamBossWeatherTips.new(self.weatherTips)

			item:setInfo(weatherID)
			self.weatherTips:SetActive(true)
		end
	end
end

function FriendTeamBossWindow:clearWeatherTips()
	self.weatherTips:SetActive(false)
end

function FriendTeamBossWindow:onClickBuyTimes()
	if not xyd.models.friendTeamBoss:checkInFight() then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_CANNOT_BUY_TIMES"))

		return
	end

	local price = xyd.split(xyd.tables.miscTable:getVal("govern_team_buy_price"), "#", true)

	if xyd.models.backpack:getItemNumByID(price[1]) <= price[2] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(price[1])))

		return
	end

	if xyd.models.friendTeamBoss:getSelfInfo().can_buy_acttack_times <= 0 then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_BUY_LIMIT"))

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("FRIEND_TEAM_BOSS_BUY_TIPS"), function (yes_no)
		if yes_no then
			xyd.models.friendTeamBoss:buyTimes()
		end
	end)
end

function FriendTeamBossWindow:onClickBtnAward()
	xyd.WindowManager.get():openWindow("friend_team_boss_award_window")
end

function FriendTeamBossWindow:onClickName()
end

function FriendTeamBossWindow:onClickFlag()
	if xyd.models.friendTeamBoss:getTeamInfo().leader_id == xyd.models.selfPlayer:getPlayerID() then
		xyd.WindowManager.get():openWindow("friend_team_boss_team_edit_window")
	end
end

function FriendTeamBossWindow:onClickQuit()
	xyd.models.friendTeamBoss:exitTeam()
end

function FriendTeamBossWindow:onClickRecord()
	xyd.WindowManager.get():openWindow("friend_team_boss_record_window")
end

function FriendTeamBossWindow:onClickInviteFriends()
	if xyd.models.friendTeamBoss:checkInFight() then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_IN_FIGHT"))

		return
	end

	if xyd.models.friendTeamBoss:getTeamInfo().leader_id ~= xyd.models.selfPlayer:getPlayerID() then
		return
	end

	xyd.WindowManager.get():openWindow("friend_team_boss_invite_friends_window")
end

function FriendTeamBossWindow:onClickBoss(index)
	if not xyd.models.friendTeamBoss:checkInFight() then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_IN_TEAMUP"))
		xyd.models.friendTeamBoss:reqInfo()

		return
	end

	if xyd.models.friendTeamBoss:getTeamInfo()["boss_" .. tostring(index) .. "_hp"] <= 0 then
		return
	end

	local team_info = xyd.models.friendTeamBoss:getTeamInfo()

	xyd.WindowManager.get():openWindow("friend_team_boss_info_window", {
		index = index
	})
end

function FriendTeamBossWindow:onClickIcon(index)
	local player_id = xyd.models.friendTeamBoss:getTeamInfo().player_ids[index]

	if player_id and player_id ~= xyd.models.selfPlayer:getPlayerID() then
		xyd.WindowManager.get():openWindow("friend_team_boss_single_formation_window", {
			is_robot = false,
			player_id = player_id
		})
	end
end

function FriendTeamBossWindow:onClickMsg()
	xyd.WindowManager.get():openWindow("friend_team_boss_msg_window")
end

function FriendTeamBossWindow:checkResult()
	local self_info = xyd.models.friendTeamBoss:getSelfInfo()

	if self_info.last_change_type ~= xyd.FriendBossResult.NO_RESULT then
		local oldCount = tonumber(xyd.db.misc:getValue("FriendTeamBoss")) or 0

		if self_info.team_boss_count > oldCount + 1 then
			if not xyd.models.friendTeamBoss:checkInFight() then
				xyd.WindowManager.get():openWindow("friend_team_boss_result_window")
			end

			xyd.db.misc:addOrUpdate({
				key = "FriendTeamBoss",
				value = tostring(self_info.team_boss_count - 1)
			})
		end
	end
end

function FriendTeamBossWindow:checkGuide()
	local res = xyd.db.misc:getValue("friend_team_boss_guide")

	if res then
		return
	else
		xyd.WindowManager.get():openWindow("friend_team_boss_guide_window", {
			wnd = self
		})
		xyd.db.misc:addOrUpdate({
			value = "1",
			key = "friend_team_boss_guide"
		})
	end
end

function FriendTeamBossWindow:layout()
	self.gContent:SetActive(true)

	local teamInfo = xyd.models.friendTeamBoss:getTeamInfo()
	local iconName = xyd.tables.friendTeamBossIconTable:getIcon(teamInfo.team_icon)

	xyd.setUISpriteAsync(self.imgFlag, nil, string.sub(iconName, 1, #iconName - 4))

	self.labelName.text = __("FRIEND_TEAM_BOSS_TEAM_NAME", teamInfo.team_name)
	self.btnInviteLabel.text = __("INVITE")
	self.btnMsgLabel.text = __("MSG")
	self.LabelLeftNum.text = __("LEFT_TIMES", xyd.models.friendTeamBoss:getSelfInfo().can_attack_times)

	self:layoutCountDown()
	self.btnQuit:SetActive(false)

	for i = 1, 3 do
		if not teamInfo.arena_defence_info[i] then
			self["pIcon" .. tostring(i)]:SetActive(false)
			self:layoutEmptyItem(i, true)
		else
			self["pIcon" .. tostring(i)]:SetActive(true)
			self:layoutEmptyItem(i, false)

			local info = {
				avatar_id = teamInfo.arena_defence_info[i].avatar_id,
				avatar_frame_id = teamInfo.arena_defence_info[i].avatar_frame_id,
				callback = function ()
					self:onClickIcon(i)
				end
			}

			self["pIcon" .. tostring(i)]:setInfo(info)

			if teamInfo.leader_id == teamInfo.arena_defence_info[i].player_id then
				self["pIcon" .. tostring(i)]:setCaptain(true)
			else
				self["pIcon" .. tostring(i)]:setCaptain(false)
			end
		end
	end

	if xyd.models.friendTeamBoss:checkInFight() then
		self:layoutBoss()
		self.gBoss:SetActive(true)
	else
		self.gBoss:SetActive(false)
	end

	local weatherID = xyd.models.friendTeamBoss:getWeatherID()

	xyd.setUISprite(self.weatherImg, "friend_team_boss", xyd.tables.friendTeamBossWeatherTable:getWeatherIcon(weatherID))

	self.weatherLabel.text = xyd.tables.friendTeamBossWeatherTable:getWeatherName(weatherID)

	if not xyd.models.friendTeamBoss:checkInFight() then
		self.gWeather:SetActive(false)
	end

	self:playEffect()
	self:updateRedMark()
end

function FriendTeamBossWindow:playEffect()
	if self.gEffect.transform.childCount > 0 then
		return
	end

	local effect1 = xyd.Spine.new(self.gEffect)

	effect1:setInfo("govern_team_bird", function ()
		effect1:SetLocalScale(1, 1, 1)
		effect1:SetLocalPosition(0, 0, 0)
		effect1:play("texiao01", 0)
	end)

	local effect2 = xyd.Spine.new(self.gEffect2.gameObject)

	effect2:setInfo("govern_team_sun", function ()
		effect2:SetLocalScale(1, 1, 1)
		effect2:SetLocalPosition(0, 0, 0)
		effect2:play("texiao01", 0)
	end)

	local effect3 = xyd.Spine.new(self.gEffect)

	effect3:setInfo("govern_team_water", function ()
		effect3:SetLocalScale(1.5, 1.5, 1)
		effect3:SetLocalPosition(0, -41, 0)
		effect3:play("texiao01", 0)
	end)
end

function FriendTeamBossWindow:layoutCountDown()
	if xyd.models.friendTeamBoss:checkInFight() then
		local time = xyd.models.friendTeamBoss:getTime2End()

		if time <= 0 then
			return
		end

		self.ddl2Num:setInfo({
			duration = time,
			callback = function ()
				self:layoutCountDown()
			end
		})
		self.ddl2Num:setLayout({
			textColor = Color.New2(4292361471.0),
			effectColor = Color.New2(1229350143)
		})

		self.labelCountDown.text = __("FRIEND_TEAM_BOSS_COUNT_DOWN_DESC_2")
	else
		local time = xyd.models.friendTeamBoss:getTime2TeamEnd()

		if time <= 0 then
			return
		end

		self.ddl2Num:setInfo({
			duration = time,
			callback = function ()
				self:layoutCountDown()
			end
		})
		self.ddl2Num:setLayout({
			textColor = Color.New2(2986279167.0),
			effectColor = Color.New2(1614629119)
		})

		self.labelCountDown.text = __("FRIEND_TEAM_BOSS_COUNT_DOWN_DESC_1")
	end
end

function FriendTeamBossWindow:layoutEmptyItem(index, isShow)
	self["item" .. tostring(index)]:SetActive(isShow)

	if isShow and not xyd.models.friendTeamBoss:checkInFight() then
		if self["gItemEffect" .. tostring(index)].transform.childCount <= 0 then
			local plusEffect = xyd.Spine.new(self["gItemEffect" .. index].gameObject)

			plusEffect:setInfo("jiahao", function ()
				plusEffect:SetLocalPosition(0, 0, 0)
				plusEffect:SetLocalScale(1.01, 0.95, 1)
				plusEffect:play("texiao01", 0)
			end)

			self["plusEffect" .. index] = plusEffect

			return
		end

		if self["plusEffect" .. index]:isValid() then
			self["plusEffect" .. index]:play("texiao01", 0)
		end
	end
end

function FriendTeamBossWindow:bossMove()
	local transform = self.gBoss.transform
	local pos = transform.localPosition
	self.bossY = self.bossY + 5

	transform:SetLocalPosition(pos.x, self.bossY, pos.z)

	if not self.bossMoveSequence then
		self.bossMoveSequence = DG.Tweening.DOTween.Sequence()

		self.bossMoveSequence:Append(transform:DOLocalMoveY(self.bossY - 5, 3))
		self.bossMoveSequence:Append(transform:DOLocalMoveY(self.bossY, 3))
		self.bossMoveSequence:AppendCallback(function ()
			self.bossMoveSequence:Restart()
		end)
	end
end

function FriendTeamBossWindow:applyBossGrey(index)
	self["lableBossHp" .. index]:ApplyGrey()
	xyd.applyGrey(self["bossImg" .. index])
	xyd.applyGrey(self["bossFrame" .. index])
end

function FriendTeamBossWindow:applyBossOrigin(index)
	self["lableBossHp" .. index]:ApplyOrigin()
	xyd.applyOrigin(self["bossImg" .. index])
	xyd.applyOrigin(self["bossFrame" .. index])
end

function FriendTeamBossWindow:layoutBoss()
	local teamInfo = xyd.models.friendTeamBoss:getTeamInfo()

	for i = 1, 3 do
		local hpp = 0

		if teamInfo["boss_" .. tostring(i) .. "_hp"] <= 0 then
			self:applyBossGrey(i)
		else
			self:applyBossOrigin(i)

			hpp = teamInfo["boss_" .. tostring(i) .. "_hp"]
		end

		self["lableBossHp" .. tostring(i)].text = tostring(__("HP")) .. ":" .. tostring(hpp) .. "%"
		local xy = xyd.tables.friendTeamBossTable:getBossPos(teamInfo.boss_level, i)
		local gBoss = self["gBoss" .. i]
		local gBossWidget = gBoss:GetComponent(typeof(UIWidget))
		local bossGroupWidget = self.gBoss:GetComponent(typeof(UIWidget))

		gBoss.transform:SetLocalPosition(xy.x - bossGroupWidget.width / 2, bossGroupWidget.height / 2 - xy.y - gBossWidget.height / 2, 0)
	end

	self.bossY = self.gBoss.transform.localPosition.y

	self:bossMove()
end

function FriendTeamBossWindow:willClose()
	BaseWindow.willClose(self)

	if self.bossMoveSequence then
		self.bossMoveSequence:Kill(false)

		self.bossMoveSequence = nil
	end

	if self.effectChris1_ then
		self.effectChris1_:destroy()
	end
end

function FriendTeamBossWeatherTips:ctor(parentGo)
	FriendTeamBossWeatherTips.super.ctor(self, parentGo)

	self.skinName = "FriendTeamBossWeatherTipsSkin"

	self:getUIComponent()
end

function FriendTeamBossWeatherTips:getPrefabPath()
	return "Prefabs/Components/friend_team_boss_weather_tips"
end

function FriendTeamBossWeatherTips:getUIComponent()
	local content = self.go:NodeByName("content").gameObject
	self.skillName = content:ComponentByName("skillName", typeof(UILabel))
	self.desc = content:ComponentByName("desc", typeof(UILabel))
end

function FriendTeamBossWeatherTips:setInfo(id)
	local st = xyd.tables.friendTeamBossWeatherTable
	self.skillName.text = __(st:getWeatherName(id))
	self.desc.text = __(st:getWeatherDesc(id))
end

return FriendTeamBossWindow
