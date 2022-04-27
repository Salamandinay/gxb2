local IceSecretBossChallenge = class("IceSecretBossChallenge", import(".ActivityContent"))
local Partner = import("app.models.Partner")
local SkillIcon = import("app.components.SkillIcon")

function IceSecretBossChallenge:ctor(parentGO, params, parent)
	IceSecretBossChallenge.super.ctor(self, parentGO, params, parent)
	xyd.models.redMark:setMark(xyd.RedMarkType.ICE_SECRET_BOSS_CHALLENGE, false)
end

function IceSecretBossChallenge:getPrefabPath()
	return "Prefabs/Windows/activity/ice_secret_boss_challenge"
end

function IceSecretBossChallenge:initUI()
	self:getUIComponent()
	IceSecretBossChallenge.super.initUI(self)
	self:initUIComponent()
	self:updateContent()
end

function IceSecretBossChallenge:getUIComponent()
	local go = self.go
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.textImg_ = self.contentGroup:ComponentByName("textImg_", typeof(UISprite))
	local bg_box_ = self.contentGroup:NodeByName("bg_box_").gameObject
	self.tipsLabel1_ = bg_box_:ComponentByName("tipsLabel1_", typeof(UILabel))
	self.itemicon = bg_box_:NodeByName("itemicon").gameObject
	self.boxEffect = bg_box_:NodeByName("boxEffect").gameObject
	self.skillGroup = self.contentGroup:NodeByName("skillGroup").gameObject
	self.skillDesc = self.contentGroup:NodeByName("skillDesc").gameObject
	self.challengeBtn = self.contentGroup:NodeByName("challengeBtn").gameObject
	self.tipsLayout = self.contentGroup:ComponentByName("tips", typeof(UILayout))
	self.tipsLabel2_ = self.contentGroup:ComponentByName("tips/tipsLabel2_", typeof(UILabel))
	self.numLabel_ = self.contentGroup:ComponentByName("tips/numLabel_", typeof(UILabel))
end

function IceSecretBossChallenge:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "ice_secret_boss_challenge_text_" .. xyd.Global.lang, function ()
		self.textImg_:MakePixelPerfect()
	end)

	self.tipsLabel1_.text = __("ACTIVITY_ICE_SECRET_BOSS_TEXT03")
	self.tipsLabel2_.text = __("ACTIVITY_ICE_SECRET_BOSS_TEXT01")
	self.challengeBtn:ComponentByName("button_label", typeof(UILabel)).text = __("FIGHT3")
	local effect = xyd.Spine.new(self.boxEffect)

	effect:setInfo("fx_ice_flash", function ()
		effect:play(nil, 0)
	end)

	self.skillItems_ = {}
	local skills = xyd.tables.miscTable:split2num("activity_ice_secret_skill", "value", "|")

	for key = 1, #skills do
		local icon = SkillIcon.new(self.skillGroup)

		icon:setInfo(skills[key], {
			scale = 0.7,
			showGroup = self.skillDesc,
			pressCallback = function (go, isPressed)
				if isPressed then
					icon:showTips(true, icon.showGroup, true)
				elseif not isPressed then
					self:clearSkillTips()
				end
			end
		})
		table.insert(self.skillItems_, icon)
	end

	self.skillGroup:GetComponent(typeof(UILayout)):Reposition()

	local itemID = xyd.tables.activityIceSecretBossRewardTable:getReward(1)[1]
	local award = xyd.getItemIcon({
		scale = 1.28,
		show_has_num = true,
		uiRoot = self.itemicon,
		itemID = itemID
	})
end

function IceSecretBossChallenge:resizeToParent()
	IceSecretBossChallenge.super.resizeToParent(self)
	self.go:Y(-520)

	local height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.contentGroup:Y((1045 - height) * 0.9)

	if xyd.Global.lang ~= "zh_tw" or xyd.Global.lang ~= "ko_kr" then
		self.skillDesc:X(40)
	end
end

function IceSecretBossChallenge:updateContent()
	self.times = self.activityData.detail.challenge_times
	self.numLabel_.text = self.times

	self.tipsLayout:Reposition()
end

function IceSecretBossChallenge:onRegister()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.openWindow("ice_secret_boss_challenge_help_window")
	end

	UIEventListener.Get(self.challengeBtn).onClick = handler(self, self.onChallenge)

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id == xyd.ActivityID.ICE_SECRET_BOSS_CHALLENGE then
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ICE_SECRET_BOSS_CHALLENGE)
		end
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.updateContent))
end

function IceSecretBossChallenge:onChallenge()
	if self.times > 0 then
		xyd.WindowManager.get():openWindow("battle_formation_window", {
			showSkip = false,
			battleType = xyd.BattleType.ICE_SECRET_BOSS,
			mapType = xyd.MapType.TRIAL
		})
	else
		xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_ICE_SECRET_BOSS_TEXT02"))
	end
end

function IceSecretBossChallenge:clearSkillTips()
	for _, item in ipairs(self.skillItems_) do
		item:showTips(false, item.showGroup)
	end
end

return IceSecretBossChallenge
