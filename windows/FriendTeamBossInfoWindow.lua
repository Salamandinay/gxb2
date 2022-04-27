local BaseWindow = import(".BaseWindow")
local FriendTeamBossInfoWindow = class("FriendTeamBossInfoWindow", BaseWindow)
local SkillIcon = import("app.components.SkillIcon")

function FriendTeamBossInfoWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.skinName = "FriendTeamBossInfoWindowSkin2"
end

function FriendTeamBossInfoWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
	self:playAnimation()
end

function FriendTeamBossInfoWindow:getUIComponent()
	local trans = self.window_.transform
	self.anim = trans:GetComponent(typeof(UnityEngine.Animator))
	self.bossImg = trans:ComponentByName("bossImg", typeof(UISprite))
	self.descLabel = trans:ComponentByName("lace6/descLabel", typeof(UISprite))
	self.gInfo = trans:NodeByName("gInfo").gameObject
	self.gLabels = self.gInfo:NodeByName("gLabels").gameObject
	self.bossName = self.gLabels:ComponentByName("bossName", typeof(UILabel))
	self.bossLevel = self.gLabels:ComponentByName("bossLevel", typeof(UILabel))
	self.gSkills = self.gInfo:NodeByName("gSkills").gameObject
	self.gSkillDesc = trans:NodeByName("gSkillDesc").gameObject
	self.btnFight = trans:NodeByName("e:Group/btnFight").gameObject
	self.btnFightLabel = self.btnFight:ComponentByName("button_label", typeof(UILabel))
	self.closeBtn = trans:NodeByName("closeGroup/closeBtn").gameObject
end

function FriendTeamBossInfoWindow:playAnimation()
	self.anim.enabled = true
end

function FriendTeamBossInfoWindow:layout()
	local bossID = xyd.models.friendTeamBoss:getTeamInfo().boss_level
	self.btnFightLabel.text = __("FIGHT")
	local bossImgPath = self.params.index == 1 and "friend_team_boss" or "friend_team_boss2"

	xyd.setUISpriteAsync(self.bossImg, nil, bossImgPath, nil, , true)
	xyd.setUISpriteAsync(self.descLabel, nil, "friend_team_boss_bg_10_" .. tostring(xyd.Global.lang), function (arg1, arg2, arg3)
		if xyd.Global.lang == "en_en" then
			self.descLabel:X(-160)
		elseif xyd.Global.lang == "de_de" then
			self.descLabel:X(-130)
		end
	end, false, true)

	if bossID then
		local bossName = self.params.index == 1 and "FRIEND_TEAM_BOSS_NAME1" or "FRIEND_TEAM_BOSS_NAME2"
		self.bossName.text = __(bossName)
		self.bossLevel.text = "Lv." .. tostring(bossID)
		local skillIds = xyd.tables.friendTeamBossTable:getBossSkill(bossID, self.params.index) or {}

		for i = 1, #skillIds do
			local item = SkillIcon.new(self.gSkills)

			item:SetLocalScale(0.8, 0.8, 1)
			item:setInfo(skillIds[i], {
				showGroup = self.gSkillDesc,
				callback = function ()
					self:handleSkillTips(item)
				end
			})

			UIEventListener.Get(item.go).onSelect = function (go, onSelect)
				if onSelect == false then
					self:clearSkillTips(item)
				end
			end
		end
	end
end

function FriendTeamBossInfoWindow:handleSkillTips(icon)
	icon:showTips(true, self.gSkillDesc, true)
end

function FriendTeamBossInfoWindow:clearSkillTips(icon)
	icon:showTips(false, self.gSkillDesc)
end

function FriendTeamBossInfoWindow:register()
	FriendTeamBossInfoWindow.super.register(self)

	UIEventListener.Get(self.btnFight).onClick = function ()
		if xyd.models.friendTeamBoss:getSelfInfo().can_attack_times <= 0 then
			xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_ATTACK_LIMIT"))

			return
		end

		local params = {
			battleType = xyd.BattleType.FRIEND_TEAM_BOSS,
			mapType = xyd.MapType.ARENA,
			index = self.params.index
		}

		xyd.WindowManager.get():openWindow("battle_formation_window", params)
	end
end

return FriendTeamBossInfoWindow
