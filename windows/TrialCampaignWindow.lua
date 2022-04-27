local BaseWindow = import(".BaseWindow")
local TrialCampaignWindow = class("TrialCampaignWindow", BaseWindow)
local ItemIcon = import("app.components.ItemIcon")
local HeroIcon = import("app.components.HeroIcon")
local PlayerIcon = import("app.components.PlayerIcon")
local BaseComponent = import("app.components.BaseComponent")
local TrialAvatar = class("TrialAvatar", BaseComponent)
local Partner = import("app.models.Partner")

function TrialCampaignWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = params.enemy
	self.stageID = params.stage_id
	self.isClear = params.clear
end

function TrialCampaignWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()
	self:setLayout()
	self:solveMultLang()
end

function TrialCampaignWindow:getUIComponent()
	local trans = self.window_.transform
	self.content = trans:NodeByName("content").gameObject
	self.bgImg = self.content:ComponentByName("bgImg", typeof(UISprite))
	local middle = self.content:NodeByName("middle").gameObject
	self.labelCampaign = middle:ComponentByName("labelCampaign", typeof(UILabel))
	self.newTrialFlag = middle:ComponentByName("newTrialFlag", typeof(UISprite))
	self.labelScore = middle:ComponentByName("groupPower/labelScore", typeof(UILabel))
	self.btnFight = middle:NodeByName("btnFight").gameObject
	self.btnFightLabel = self.btnFight:ComponentByName("button_label", typeof(UILabel))
	self.firstGroup = self.content:NodeByName("firstGroup").gameObject
	self.firstGroupTable = self.firstGroup:GetComponent(typeof(UITable))
	self.imgLine01 = self.firstGroup:NodeByName("imgLine01").gameObject
	self.labelText03 = self.firstGroup:ComponentByName("labelText03", typeof(UILabel))
	self.imgLine02 = self.firstGroup:NodeByName("imgLine02").gameObject
	self.labelText01 = self.content:ComponentByName("labelText01", typeof(UILabel))
	self.labelText02 = self.content:ComponentByName("labelText02", typeof(UILabel))
	self.group01 = self.content:NodeByName("group01").gameObject
	self.group02 = self.content:NodeByName("group02").gameObject
	self.secondGroup = self.content:NodeByName("secondGroup").gameObject
	self.imgLine03 = self.secondGroup:NodeByName("imgLine03").gameObject
	self.labelText04 = self.secondGroup:ComponentByName("labelText04", typeof(UILabel))
	self.imgLine04 = self.secondGroup:NodeByName("imgLine04").gameObject
	self.groupItems = self.content:NodeByName("groupItems").gameObject
	self.closeBtn = self.content:NodeByName("closeBtn").gameObject
end

function TrialCampaignWindow:solveMultLang()
	if xyd.Global.lang == "en_en" then
		for i = 1, 4 do
			local line = self["imgLine0" .. i]
			line:GetComponent(typeof(UIWidget)).width = 180
		end
	end
end

function TrialCampaignWindow:register()
	TrialCampaignWindow.super.register(self)

	if self.isClear then
		return
	end

	UIEventListener.Get(self.btnFight).onClick = function ()
		local fightParams = {
			showSkip = true,
			mapType = xyd.MapType.TRIAL,
			isSkip = xyd.models.trial:isSkipReport(),
			battleType = xyd.BattleType.TRIAL,
			stageId = self.stageID,
			skipState = xyd.models.trial:isSkipReport(),
			btnSkipCallback = function (flag)
				xyd.models.trial:setSkipReport(flag)
			end
		}

		xyd.WindowManager.get():openWindow("battle_formation_trial_window", fightParams)
	end
end

function TrialCampaignWindow:setLayout()
	self:setText()

	local bgName = xyd.tables.newTrialBossScenesTable:getStageSceneDetail(xyd.models.trial:getBossId())

	xyd.setUISpriteAsync(self.bgImg, nil, bgName)

	local useTable = xyd.models.trial:getTableUse()
	local type_ = useTable:getType(self.stageID)

	if type_ == 1 then
		xyd.setUISpriteAsync(self.newTrialFlag, nil, "new_trial_point3")
	elseif type_ == 2 then
		xyd.setUISpriteAsync(self.newTrialFlag, nil, "new_trial_point2")
	elseif type_ == 3 then
		xyd.setUISpriteAsync(self.newTrialFlag, nil, "new_trial_point5")
	end

	self:setItems()

	if self.isClear then
		self.btnFightBoxCollider.enabled = false

		xyd.applyDark(self.btnFight)
	end
end

function TrialCampaignWindow:setText()
	self.labelText01.text = __("HEAD_POS")
	self.labelText02.text = __("BACK_POS")
	self.labelScore.text = self.data.power
	self.labelText03.text = __("TRIAL_TEXT04")
	self.labelText04.text = __("TRIAL_TEXT05")
	self.labelCampaign.text = __("TRIAL_TEXT08", self.stageID)
	self.btnFightLabel.text = __("TRIAL_TEXT06")

	xyd.setBgColorType(self.btnFight, xyd.ButtonBgColorType.blue_btn_70_70)
end

function TrialCampaignWindow:setItems()
	local enemys = self.data.partners
	local petID = 0

	if self.data.pet then
		petID = self.data.pet.pet_id
	end

	local group01_cnt = 0
	local group02_cnt = 0

	for i = 1, #enemys do
		local enemy = enemys[i]
		local partner = Partner.new()

		partner:populate(enemy)

		local params = partner:getInfo()
		params.noClick = true
		params.status = enemy.status
		params.is_empty = false
		params.pet_id = petID

		if self.isClear then
			params.status = {
				hp = 0
			}
		end

		if enemy.pos <= 2 then
			TrialAvatar.new(self.group01, params)

			group01_cnt = group01_cnt + 1
		else
			TrialAvatar.new(self.group02, params)

			group02_cnt = group02_cnt + 1
		end
	end

	for i = group01_cnt, 1 do
		local params = {
			is_empty = true
		}

		TrialAvatar.new(self.group01, params)
	end

	for i = group02_cnt, 3 do
		local params = {
			is_empty = true
		}

		TrialAvatar.new(self.group02, params)
	end

	local useTable = xyd.models.trial:getTableUse()
	local awards = useTable:getRewards(self.stageID)

	for i = 1, #awards do
		local award = awards[i]
		local itemData = {
			itemID = award[1],
			num = award[2]
		}
		local item = ItemIcon.new(self.groupItems)

		item:setInfo(itemData)
		item:setLabelNumScale(1.2)

		local itemWidget = item.go:GetComponent(typeof(UIWidget))

		item:setScale(76 / itemWidget.height)
	end
end

function TrialAvatar:ctor(parentGo, partnerInfo)
	self.partnerInfo = partnerInfo

	TrialAvatar.super.ctor(self, parentGo)
end

function TrialAvatar:getPrefabPath()
	return "Prefabs/Components/trial_avatar"
end

function TrialAvatar:initUI()
	TrialAvatar.super.initUI(self)

	local go = self.go
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.emptyImg = self.groupIcon:ComponentByName("emptyImg", typeof(UISprite))
	self.progress = self.go:ComponentByName("progress", typeof(UIProgressBar))
	self.progress.value = 0

	self:setChildren()
end

function TrialAvatar:setChildren()
	self.emptyImg:SetActive(self.partnerInfo.is_empty)

	if self.partnerInfo.is_empty then
		return
	end

	self.heroIcon = HeroIcon.new(self.groupIcon)

	self.heroIcon:setInfo(self.partnerInfo, self.partnerInfo.pet_id)

	local groupIconWidget = self.groupIcon:GetComponent(typeof(UIWidget))
	local heroIconWidget = self.heroIcon.go:GetComponent(typeof(UIWidget))

	self.heroIcon.go:SetLocalScale(groupIconWidget.width / heroIconWidget.width, groupIconWidget.height / heroIconWidget.height, 1)

	if not self.partnerInfo.status.hp then
		self.progress.value = 1
	else
		self.progress.value = self.partnerInfo.status.hp / 100
	end

	if self.progress.value == 0 then
		self:applyGrey()
	end
end

function TrialAvatar:applyGrey()
	self.heroIcon:setGrey()
	xyd.applyGrey(self.emptyImg)
end

function TrialAvatar:applyOrigin()
	self.heroIcon:setOrigin()
	xyd.applyOrigin(self.emptyImg)
end

return TrialCampaignWindow
