local BaseWindow = import(".BaseWindow")
local FairArenaEnemyFormationWindow = class("FairArenaEnemyFormationWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local GroupBuffIcon = import("app.components.GroupBuffIcon")
local RobotTable = xyd.tables.activityFairArenaRobotTable

function FairArenaEnemyFormationWindow:ctor(name, params)
	FairArenaEnemyFormationWindow.super.ctor(self, name, params)

	self.data = params.info
	self.is_history = params.is_history
	self.is_robot = self.data.robot_id

	if self.is_robot then
		self.robot_id = tonumber(self.data.robot_id)
	else
		self.player_info = self.data.player_info
	end
end

function FairArenaEnemyFormationWindow:initWindow()
	FairArenaEnemyFormationWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initPartners()
	self:initBuffs()
	self:register()
end

function FairArenaEnemyFormationWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.Bg_ = winTrans:ComponentByName("Bg_", typeof(UISprite))
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.pNode = winTrans:NodeByName("pIcon").gameObject
	self.pNameLabel_ = winTrans:ComponentByName("pNameLabel_", typeof(UILabel))
	self.severLabel_ = winTrans:ComponentByName("serverGroup/severLabel_", typeof(UILabel))
	self.textLabel_ = winTrans:ComponentByName("textLabel_", typeof(UILabel))
	self.powerLabel_ = winTrans:ComponentByName("powerGroup/powerLabel_", typeof(UILabel))

	for i = 1, 5 do
		self["buffNode" .. i] = winTrans:NodeByName("buffGroup/icon" .. i .. "/buff" .. i).gameObject
	end

	self.heroContainer1 = winTrans:NodeByName("group1/icon1/hero1").gameObject
	self.heroContainer2 = winTrans:NodeByName("group1/icon2/hero2").gameObject
	self.heroContainer3 = winTrans:NodeByName("group2/icon3/hero3").gameObject
	self.heroContainer4 = winTrans:NodeByName("group2/icon4/hero4").gameObject
	self.heroContainer5 = winTrans:NodeByName("group2/icon5/hero5").gameObject
	self.heroContainer6 = winTrans:NodeByName("group2/icon6/hero6").gameObject

	for i = 1, 6 do
		self["hero" .. i] = HeroIcon.new(self["heroContainer" .. i])

		self["hero" .. i]:SetActive(false)
	end

	self.battleBtn_ = winTrans:NodeByName("battleBtn_").gameObject
	self.battleBtnLabel_ = winTrans:ComponentByName("battleBtn_/button_label", typeof(UILabel))
end

function FairArenaEnemyFormationWindow:initUIComponent()
	self.titleLabel_.text = __("FAIR_ARENA_ENEMY")
	self.textLabel_.text = __("DEFFORMATION")
	self.battleBtnLabel_.text = __("FAIR_ARENA_GOTO_FIGHT")
	self.pIcon = PlayerIcon.new(self.pNode)

	if self.is_robot then
		local id = self.robot_id
		self.pNameLabel_.text = RobotTable:getName(id)
		local serverId = RobotTable:getServerID(id)

		if serverId == 0 then
			serverId = xyd.models.selfPlayer:getServerID()
		end

		self.severLabel_.text = xyd.getServerNumber(serverId)

		self.pIcon:setInfo({
			avatarID = RobotTable:getAvatar(id),
			lev = RobotTable:getLev(id)
		})
	else
		self.pNameLabel_.text = self.player_info.player_name
		self.severLabel_.text = xyd.getServerNumber(self.player_info.server_id)

		self.pIcon:setInfo({
			avatarID = self.player_info.avatar_id,
			avatar_frame_id = self.player_info.avatar_frame_id,
			lev = self.player_info.lev
		})
	end

	if self.is_history then
		self.battleBtn_:SetActive(false)

		self.Bg_.height = 365
	end
end

function FairArenaEnemyFormationWindow:initPartners()
	self.partners = {}
	local partners = self.data.partners
	local power = 0

	for i = 1, #partners do
		local params = {
			isHeroBook = true,
			scale = 0.8055555555555556,
			isShowSelected = false,
			tableID = partners[i].table_id,
			lev = partners[i].lv,
			grade = partners[i].grade,
			equips = partners[i].equips
		}
		local partner = Partner.new()

		partner:populate(params)

		power = power + partner:getPower()

		function params.callback()
			xyd.WindowManager.get():openWindow("fair_arena_partner_info_window", {
				partner = partner
			})
		end

		self["hero" .. partners[i].pos]:setInfo(params)
		self["hero" .. partners[i].pos]:SetActive(true)
		table.insert(self.partners, partner)
	end

	self.powerLabel_.text = power
end

function FairArenaEnemyFormationWindow:initBuffs()
	local buffs = self.data.god_skills

	for i = 1, #buffs do
		local icon = GroupBuffIcon.new(self["buffNode" .. i])

		icon:SetLocalScale(0.5714285714285714, 0.6, 1)
		icon:setInfo(buffs[i], true, xyd.GroupBuffIconType.FAIR_ARENA)

		UIEventListener.Get(icon.go).onSelect = function (go, isSelect)
			if isSelect then
				self:onClcikBuffNode(buffs[i], 160, true)
			else
				self:clearBuffTips()
			end
		end
	end

	if #self.partners < 6 then
		return
	end

	local actBuffID = xyd.models.fairArena:getActBuffID(self.partners)

	if actBuffID > 0 then
		self.groupBuff = GroupBuffIcon.new(self.buffNode5)

		self.groupBuff:SetLocalScale(0.5714285714285714, 0.5714285714285714, 1)
		self.groupBuff:setInfo(actBuffID, true)

		UIEventListener.Get(self.groupBuff:getGameObject()).onSelect = function (go, isSelect)
			if isSelect then
				self:onClcikBuffNode(actBuffID, 160)
			else
				self:clearBuffTips()
			end
		end
	end
end

function FairArenaEnemyFormationWindow:register()
	FairArenaEnemyFormationWindow.super.register(self)

	UIEventListener.Get(self.battleBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_battle_formation_window", {
			battleType = xyd.BattleType.FAIR_ARENA
		})
	end)
end

function FairArenaEnemyFormationWindow:onClcikBuffNode(buffID, contenty, isFairType)
	local params = {
		buffID = buffID,
		contenty = contenty
	}

	if isFairType then
		params.type = xyd.GroupBuffIconType.FAIR_ARENA
	end

	local win = xyd.getWindow("group_buff_detail_window")

	if win then
		win:update(params)
	else
		xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
	end
end

function FairArenaEnemyFormationWindow:clearBuffTips()
	xyd.closeWindow("group_buff_detail_window")
end

return FairArenaEnemyFormationWindow
