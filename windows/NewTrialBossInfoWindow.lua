local NewTrialBossInfoWindow = class("NewTrialBossInfoWindow", import(".BaseWindow"))
local SkillIcon = import("app.components.SkillIcon")

function NewTrialBossInfoWindow:ctor(name, params)
	NewTrialBossInfoWindow.super.ctor(self, name, params)
end

function NewTrialBossInfoWindow:initWindow()
	NewTrialBossInfoWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:playAnimation()
end

function NewTrialBossInfoWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.lace1 = goTrans:NodeByName("lace1")
	self.lace2 = goTrans:NodeByName("lace2")
	self.lace3 = goTrans:NodeByName("lace3")
	self.lace4 = goTrans:NodeByName("lace4")
	self.lace6 = goTrans:NodeByName("lace6")
	self.lace7 = goTrans:NodeByName("gInfo/lace7")
	self.lace8 = goTrans:NodeByName("gInfo/lace8")
	self.spriteName = goTrans:ComponentByName("lace6/labelName", typeof(UISprite))
	self.lace11 = goTrans:NodeByName("lace11")
	self.closeBtn = goTrans:NodeByName("closeBtn").gameObject
	self.fightBtn = goTrans:NodeByName("fightBtn").gameObject
	self.fightBtnLabel = goTrans:ComponentByName("fightBtn/label", typeof(UILabel))
	self.bossImg = goTrans:ComponentByName("bossImg", typeof(UITexture))
	self.groupSkill = goTrans:NodeByName("groupSkill").gameObject
	self.bossName = goTrans:ComponentByName("gInfo/bossName", typeof(UILabel))
	self.gSkill = goTrans:NodeByName("gInfo/groupSkill").gameObject

	if xyd.models.trial:getBossId() == 2 then
		self.groupSkill:Y(-260)
	end

	UIEventListener.Get(self.fightBtn).onClick = function ()
		xyd.models.trial:setSkipReport(false)
		xyd.WindowManager.get():openWindow("battle_formation_trial_window", self.params_)
	end

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function NewTrialBossInfoWindow:playAnimation()
	self.lace1:SetLocalPosition(-1000, -533, 0)
	self.lace2:SetLocalPosition(1500, -700, 0)
	self.lace3:SetLocalPosition(-1024, -693, 0)
	self.lace4:SetLocalPosition(2000, -652, 0)
	self.lace6:SetLocalPosition(-1309, 101, 0)
	self.lace7:SetLocalPosition(-1000, 42, 0)
	self.lace8:SetLocalPosition(1000, -72, 0)
	self.lace11:SetLocalPosition(-1059, -808, 0)

	local bossNameY = xyd.checkCondition(xyd.models.trial:getBossId() == 2, -20, 34)
	local groupSkillY = xyd.checkCondition(xyd.models.trial:getBossId() == 2, -116, -70)
	local lace6Y = xyd.checkCondition(xyd.models.trial:getBossId() == 2, 600, 442)

	self.bossName.transform:SetLocalPosition(-1000, bossNameY, 0)
	self.bossImg.transform:SetLocalPosition(-1000, 0, 0)
	self.gSkill.transform:SetLocalPosition(1000, -70, 0)

	self.fightBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	local fightSprite = self.fightBtn:GetComponent(typeof(UISprite))
	local closeSprite = self.closeBtn:GetComponent(typeof(UISprite))
	fightSprite.alpha = 0
	closeSprite.alpha = 0
	self.action = self:getSequence()

	self.action:Insert(0, self.lace1:DOLocalMove(Vector3(65, 525, 0), 0.4))
	self.action:Insert(0.1, self.lace2:DOLocalMove(Vector3(153, 156, 0), 0.4))
	self.action:Insert(0.2, self.lace3:DOLocalMove(Vector3(352, 307, 0), 0.4))
	self.action:Insert(0.3, self.lace4:DOLocalMove(Vector3(167, -143, 0), 0.4))
	self.action:Insert(0.4, self.bossImg.transform:DOLocalMove(Vector3(0, 0, 0), 0.4))
	self.action:Insert(0.5, self.lace6:DOLocalMove(Vector3(-64, lace6Y, 0), 0.4))
	self.action:Insert(0.6, self.lace7:DOLocalMove(Vector3(0, 42, 0), 0.4))
	self.action:Insert(0.7, self.lace8:DOLocalMove(Vector3(0, -72, 0), 0.4))
	self.action:Insert(0.8, self.bossName.transform:DOLocalMove(Vector3(0, bossNameY, 0), 0.4))
	self.action:Insert(0.9, self.gSkill.transform:DOLocalMove(Vector3(0, groupSkillY, 0), 0.4))
	self.action:Insert(1, self.lace11:DOLocalMove(Vector3(141, -208, 0), 0.4))
	self.action:Insert(1.1, self.closeBtn.transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.13))
	self.action:Insert(1.23, self.closeBtn.transform:DOScale(Vector3(0.9, 0.9, 0.9), 0.16))
	self.action:Insert(1.4, self.closeBtn.transform:DOScale(Vector3(1, 1, 1), 0.16))
	self.action:InsertCallback(1.1, function ()
		fightSprite.alpha = 1
		closeSprite.alpha = 1
	end)
	self.action:Insert(1.1, self.fightBtn.transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.13))
	self.action:Insert(1.23, self.fightBtn.transform:DOScale(Vector3(0.9, 0.9, 0.9), 0.16))
	self.action:Insert(1.4, self.fightBtn.transform:DOScale(Vector3(1, 1, 1), 0.16))
	self.action:AppendCallback(function ()
		self.fightBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

		self.action:Kill(true)

		self.action = nil
	end)
end

function NewTrialBossInfoWindow:layout()
	local bossID = xyd.tables.newTrialBossScenesTable:getPartnerId(xyd.models.trial:getBossId())
	local bossName = xyd.tables.newTrialBossScenesTable:getBossImg(xyd.models.trial:getBossId())
	self.fightBtnLabel.text = __("FIGHT")

	xyd.setUITextureAsync(self.bossImg, "Textures/partner_picture_web/" .. bossName)

	if xyd.models.trial:getBossId() == 2 then
		xyd.setUISpriteAsync(self.spriteName, nil, "new_trial_boss_text_" .. xyd.Global.lang, function ()
		end, false, true)
	else
		xyd.setUISpriteAsync(self.spriteName, nil, "friend_team_boss_bg_10_" .. xyd.Global.lang, function ()
			if xyd.Global.lang == "en_en" then
				self.spriteName:X(-100)
			end
		end, false, true)
	end

	self.skillItems_ = {}

	if bossID then
		self.bossName.text = xyd.tables.partnerTextTable:getName(bossID)
		local skillIds = {
			xyd.tables.partnerTable:getEnergyID(bossID)
		}

		for i = 1, 3 do
			table.insert(skillIds, xyd.tables.partnerTable:getPasSkill(bossID, i))
		end

		for i = 1, #skillIds do
			local item = SkillIcon.new(self.gSkill)

			item:setScale(0.8, 0.8, 0.8)
			item:setInfo(skillIds[i], {
				showGroup = self.groupSkill,
				pressCallback = function (go, isPressed)
					if isPressed then
						item:showTips(true, item.showGroup, true)
					elseif not isPressed then
						self:clearSkillTips()
					end
				end
			})
			table.insert(self.skillItems_, item)
		end
	end
end

function NewTrialBossInfoWindow:clearSkillTips()
	for _, item in ipairs(self.skillItems_) do
		item:showTips(false, item.showGroup)
	end
end

return NewTrialBossInfoWindow
