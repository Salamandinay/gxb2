local BaseWindow = import(".BaseWindow")
local FriendTeamBossResultWindow = class("FriendTeamBossResultWindow", BaseWindow)

function FriendTeamBossResultWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "FriendTeamBossResultWindowSkin"
end

function FriendTeamBossResultWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()

	local effectName = nil
	local selfInfo = xyd.models.friendTeamBoss:getSelfInfo()

	if selfInfo.last_change_type == xyd.FriendBossResult.KILL then
		effectName = "govern_result_success"
	elseif selfInfo.last_change_type == xyd.FriendBossResult.PEACE then
		effectName = "govern_result_success"
	elseif selfInfo.last_change_type == xyd.FriendBossResult.FAIL then
		effectName = "govern_result_defeat"
	end

	local effect = xyd.Spine.new(self.gEffect.gameObject)

	effect:setInfo(effectName, function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao01_" .. tostring(xyd.Global.lang), 1, 1, function ()
			effect:play("texiao02_" .. tostring(xyd.Global.lang), 0)
			self:layout()
			self:playEffect2()
		end)
	end)
	self:register()
end

function FriendTeamBossResultWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("content").gameObject
	self.gEffect = content:ComponentByName("gEffect", typeof(UITexture))
	self.gBoss = content:NodeByName("gBoss").gameObject
	self.levLabel2 = self.gBoss:ComponentByName("levLabel2", typeof(UILabel))
	self.bossImg = self.gBoss:ComponentByName("bossImg", typeof(UISprite))
	self.levLabel = self.gBoss:ComponentByName("levLabel", typeof(UILabel))
	self.btnSure = content:NodeByName("btnSure").gameObject
	self.btnSureLabel = self.btnSure:ComponentByName("button_label", typeof(UILabel))
end

function FriendTeamBossResultWindow:playEffect2()
	local effect = xyd.Spine.new(self.gEffect.gameObject)

	effect:setInfo("govern_result_baozha", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao01", 1)
	end)
end

function FriendTeamBossResultWindow:layout()
	xyd.setUISpriteAsync(self.bossImg, nil, "friend_team_boss_head" .. tostring(math.ceil((xyd.models.friendTeamBoss:getTeamInfo().boss_level + 1) / 10)))

	self.levLabel.text = xyd.models.friendTeamBoss:getTeamInfo().boss_level
	self.btnSureLabel.text = __("SURE")
	self.levLabel2.text = __("FRIEND_TEAM_BOSS_LEVEL")

	local function playNormal(obj, callback)
		xyd.SoundManager.get():playSound(xyd.SoundID.GAMEBLE_NORMAL)
		obj:SetActive(true)

		local trans = obj.transform

		trans:SetLocalScale(0.36, 0.36, 0)

		local getter, setter = xyd.getTweenAlphaGeterSeter(trans:GetComponent(typeof(UIWidget)))
		local sequence = self:getSequence()

		sequence:Append(trans:DOScale(Vector3(1.2, 1.2, 1), 0.13))
		sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.13))
		sequence:Append(trans:DOScale(Vector3(0.9, 0.9, 1), 0.16))
		sequence:Append(trans:DOScale(Vector3(1, 1, 1), 0.16))
		sequence:AppendCallback(function ()
			sequence:Kill(false)

			sequence = nil

			if callback then
				callback()
			end
		end)
	end

	playNormal(self.gBoss)
end

function FriendTeamBossResultWindow:register()
	UIEventListener.Get(self.btnSure).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

return FriendTeamBossResultWindow
