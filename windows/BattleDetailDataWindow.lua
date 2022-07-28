local BattleDetailItem = class("BattleDetailItem")
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")
local PetIcon = import("app.components.PetIcon")

function BattleDetailItem:ctor(node, params)
	self.battleType = params.battleType
	self.go = node
	self.MonsterTable = xyd.tables.monsterTable
	self.id_ = params.id
	self.leftNum_ = 0
	self.rightNum_ = 0
	self.battleData_ = params.battleData
	self.leftPartner_ = params.leftPartner
	self.rightPartner_ = params.rightPartner
	self.maxDamage_ = params.maxDamage
	self.maxHeal_ = params.maxHeal

	self:initUI()
	self:initLayout()
	self:refreshProgressBar(params.showType, true)
end

function BattleDetailItem:initUI()
	self.leftGroup = self.go:NodeByName("e:Group/leftGroup").gameObject
	self.leftProgressBar = self.leftGroup:ComponentByName("leftProgressBar", typeof(UISlider))
	self.leftThumb = self.leftGroup:ComponentByName("leftProgressBar/thumb", typeof(UISprite))
	self.labelLeftNum = self.leftGroup:ComponentByName("labelLeftNum", typeof(UILabel))
	self.rightGroup = self.go:NodeByName("e:Group/rightGroup").gameObject
	self.rightProgressBar = self.rightGroup:ComponentByName("rightProgressBar", typeof(UISlider))
	self.rightThumb = self.rightGroup:ComponentByName("rightProgressBar/thumb", typeof(UISprite))
	self.labelRightNum = self.rightGroup:ComponentByName("labelRightNum", typeof(UILabel))
	self.bgImg = self.go:ComponentByName("e:Group/bgImg", typeof(UISprite))
	self.bgImg0 = self.go:ComponentByName("e:Group/bgImg0", typeof(UISprite))
end

function BattleDetailItem:refreshProgressBar(showType, needDuration)
	self.showType_ = showType

	if self.showType_ == 1 then
		xyd.setUISpriteAsync(self.leftThumb, xyd.Atlas.COMMON_UI, "battle_detail_progress_1")
		xyd.setUISpriteAsync(self.rightThumb, xyd.Atlas.COMMON_UI, "battle_detail_progress_1")

		self.TotalNum_ = self.maxDamage_

		if self.leftPartner_ then
			self.leftNum_ = xyd.getBattleNum(self.leftPartner_.hurt.hurt)
		end

		if self.rightPartner_ then
			self.rightNum_ = xyd.getBattleNum(self.rightPartner_.hurt.hurt)
		end
	else
		xyd.setUISpriteAsync(self.leftThumb, xyd.Atlas.COMMON_UI, "battle_detail_progress_2")
		xyd.setUISpriteAsync(self.rightThumb, xyd.Atlas.COMMON_UI, "battle_detail_progress_2")

		self.TotalNum_ = self.maxHeal_

		if self.leftPartner_ then
			self.leftNum_ = xyd.getBattleNum(self.leftPartner_.hurt.heal)
		end

		if self.rightPartner_ then
			self.rightNum_ = xyd.getBattleNum(self.rightPartner_.hurt.heal)
		end
	end

	local leftSequence = DG.Tweening.DOTween.Sequence()
	local rightSequence = DG.Tweening.DOTween.Sequence()
	local duration = 0

	if needDuration then
		duration = 0.7
	end

	local leftNum = self.leftNum_
	local rightNum = self.rightNum_
	local limitDuration = tonumber(xyd.tables.miscTable:getVal("limit_duration_time_rate"))

	if self.leftPartner_ then
		local rate = self.leftNum_ / self.maxDamage_
		local tmpDuration = duration * rate

		if limitDuration > rate * 100 then
			tmpDuration = 0
		end

		local bar1 = self.leftProgressBar
		bar1.value = 0

		local function setter(value)
			bar1.value = value
		end

		local labelLeftNum = self.labelLeftNum

		local function setter2(value)
			labelLeftNum.text = xyd.getDisplayNumber(math.ceil(value))
		end

		local to = 0

		if self.TotalNum_ > 0 then
			to = self.leftNum_ / self.TotalNum_
		end

		leftSequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, to, tmpDuration))
		leftSequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, leftNum, tmpDuration))
		leftSequence:OnComplete(function ()
			labelLeftNum.text = xyd.getDisplayNumber(self.leftNum_)
		end)
	end

	if self.rightPartner_ then
		local rate = self.rightNum_ / self.maxDamage_
		local tmpDuration = duration * rate

		if limitDuration > rate * 100 then
			tmpDuration = 0
		end

		local bar2 = self.rightProgressBar
		bar2.value = 0

		local function setter(value)
			bar2.value = value
		end

		local labelRightNum = self.labelRightNum

		local function setter2(value)
			labelRightNum.text = xyd.getDisplayNumber(math.ceil(value))
		end

		local to = 0

		if self.TotalNum_ > 0 then
			to = self.rightNum_ / self.TotalNum_
		end

		rightSequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, to, tmpDuration))
		rightSequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, rightNum, tmpDuration))
		rightSequence:OnComplete(function ()
			labelRightNum.text = xyd.getDisplayNumber(self.rightNum_)
		end)
	end

	self.leftSequence_ = leftSequence
	self.rightSequence_ = rightSequence
end

function BattleDetailItem:clearAction()
	if self.leftSequence_ and self.leftSequence_:IsPlaying() then
		self.leftSequence_:Kill(false)

		self.leftSequence_ = nil
		self.labelLeftNum.text = xyd.getDisplayNumber(self.leftNum_)
	end

	if self.rightSequence_ and self.rightSequence_:IsPlaying() then
		self.rightSequence_:Kill(false)

		self.rightSequence_ = nil
		self.labelRightNum.text = xyd.getDisplayNumber(self.rightNum_)
	end
end

function BattleDetailItem:getIcon(data, parentGo)
	local icon = nil

	if not data.pet_id then
		local tableId = data.table_id
		local lev = data.level
		local partnerInfo = nil

		if data.isMonster then
			lev = self.MonsterTable:getShowLev(tableId)
			local pTableID = self.MonsterTable:getPartnerLink(tableId)
			local star = xyd.tables.partnerTable:getStar(pTableID)
			partnerInfo = {
				noClick = true,
				tableID = pTableID,
				lev = lev,
				star = star,
				skin_id = data.skin_id or self.MonsterTable:getSkin(tableId)
			}
		else
			local partner = Partner.new()

			partner:populate({
				table_id = tableId,
				lev = lev,
				awake = data.awake,
				show_skin = data.show_skin,
				is_vowed = data.is_vowed,
				equips = {
					0,
					0,
					0,
					0,
					0,
					0,
					data.skin_id
				}
			})

			partnerInfo = partner:getInfo()
			partnerInfo.noClick = true
		end

		icon = HeroIcon.new(parentGo)

		icon:setInfo(partnerInfo)

		icon.scale = 0.6

		if data.is_die then
			icon:setGrey()
		end
	else
		icon = PetIcon.new(parentGo)
		data.scale = 0.6

		icon:setInfo(data)
	end

	return icon
end

function BattleDetailItem:initLayout()
	if self.leftPartner_ then
		self.leftGroup:SetActive(true)

		local heroIcon = self:getIcon(self.leftPartner_, self.leftGroup)

		heroIcon:SetLocalPosition(-104, 0, 0)
	else
		self.leftGroup:SetActive(false)
	end

	if self.rightPartner_ then
		self.rightGroup:SetActive(true)

		local heroIcon = self:getIcon(self.rightPartner_, self.rightGroup)

		heroIcon:SetLocalPosition(104, 0, 0)
	else
		self.rightGroup:SetActive(false)
	end

	if self.id_ % 2 == 0 then
		self.bgImg.alpha = 0.3
		self.bgImg0.alpha = 0.3
	else
		self.bgImg.alpha = 1
		self.bgImg0.alpha = 1
	end
end

local BattleDetailDataWindow = class("BattleDetailDataWindow", import(".BaseWindow"))

function BattleDetailDataWindow:ctor(name, params)
	BattleDetailDataWindow.super.ctor(self, name, params)

	self.callback = nil
	self.StageTable = xyd.tables.stageTable
	self.itemList = {}

	if params and params.listener ~= nil then
		self.callback = params.listener
	end

	self.battleType = params.battleType
	self.battleParams = params.battle_params
	self.showType = 1
end

function BattleDetailDataWindow:initWindow()
	BattleDetailDataWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayout()
	self:registerEvent()
end

function BattleDetailDataWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainObj = winTrans:NodeByName("groupAction").gameObject
	self.damageBtn = mainObj:NodeByName("damageBtn").gameObject
	self.healBtn = mainObj:NodeByName("healBtn").gameObject
	self.labelSelf = mainObj:ComponentByName("labelSelf", typeof(UILabel))
	self.labelEnemy = mainObj:ComponentByName("labelEnemy", typeof(UILabel))
	self.imgBattle_ = mainObj:ComponentByName("imgBattle_", typeof(UISprite))
	self.listGrid_ = mainObj:NodeByName("listGroup/scrollview/grid").gameObject
	self.battleDetailItem_ = mainObj:NodeByName("listGroup/scrollview/BattleDetailItem").gameObject

	self.battleDetailItem_:SetActive(false)
	self:setCloseBtn(mainObj:NodeByName("closeBtn").gameObject)
end

function BattleDetailDataWindow:registerEvent()
	UIEventListener.Get(self.damageBtn).onClick = function ()
		if self.showType == 2 then
			self.showType = 1

			self:clearItemAction()
			self:changeColor(self.damageBtn, true)
			self:changeColor(self.healBtn, false)
			self:refreshListGroup()
		end
	end

	UIEventListener.Get(self.healBtn).onClick = function ()
		if self.showType == 1 then
			self.showType = 2

			self:clearItemAction()
			self:changeColor(self.damageBtn, false)
			self:changeColor(self.healBtn, true)
			self:refreshListGroup()
		end
	end
end

function BattleDetailDataWindow:changeColor(button, blue)
	local sprite = button:GetComponent(typeof(UISprite))
	local label = button:ComponentByName("button_label", typeof(UILabel))

	if blue then
		xyd.setUISpriteAsync(sprite, xyd.Atlas.COMMON_Btn, "blue_btn_60_60")

		label.color = Color.New2(4278124287.0)
		label.effectColor = Color.New2(1012112383)
	else
		xyd.setUISpriteAsync(sprite, xyd.Atlas.COMMON_Btn, "white_btn_60_60")

		label.color = Color.New2(960513791)
		label.effectColor = Color.New2(4294967295.0)
	end
end

function BattleDetailDataWindow:getTeamInfo(team, dieInfo, isTeamB)
	dieInfo = dieInfo or {}
	local infos = {}

	for i = 1, #team do
		local is_die = false
		local pos = team[i].pos

		if isTeamB then
			pos = pos + 6
		end

		if xyd.arrayIndexOf(dieInfo, pos) > 0 then
			is_die = true
		end

		local info = {
			table_id = team[i].table_id,
			pos = team[i].pos,
			grade = team[i].grade,
			level = team[i].level,
			awake = team[i].awake,
			isMonster = team[i].isMonster,
			status = team[i].status,
			initMp = team[i].initMp,
			show_skin = team[i].show_skin,
			skin_id = team[i].skin_id,
			is_vowed = team[i].is_vowed,
			love_point = team[i].love_point,
			equips = team[i].equips,
			potentials = team[i].potentials,
			is_die = is_die
		}

		table.insert(infos, info)
	end

	return infos
end

function BattleDetailDataWindow:getPetInfo(pet)
	if not pet then
		return
	end

	local info = {
		pet_id = pet.pet_id,
		lv = pet.lv,
		grade = pet.grade,
		skills = pet.skills
	}

	return info
end

function BattleDetailDataWindow:initLayout()
	self.labelSelf.text = __("SELF")
	self.labelEnemy.text = __("ENEMY")
	self.damageBtn:ComponentByName("button_label", typeof(UILabel)).text = __("DAMAGE")
	self.healBtn:ComponentByName("button_label", typeof(UILabel)).text = __("HEAL")
	local battleReport = self.params_.real_battle_report or self.battleParams.battle_report
	local die_info = battleReport.die_info

	if self.params_.die_info then
		die_info = self.params_.die_info
	end

	local hurts = battleReport.hurts
	local teamA = self:getTeamInfo(battleReport.teamA, die_info)
	local teamB = self:getTeamInfo(battleReport.teamB, die_info, true)
	local petA = self:getPetInfo(battleReport.petA)
	local petB = self:getPetInfo(battleReport.petB)

	self.imgBattle_:SetActive(true)
	self.healBtn:SetActive(true)
	self.damageBtn:SetActive(true)

	local maxDamage = 0
	local maxHeal = 0
	local hurtList = {}

	for _, hurtData in ipairs(hurts) do
		local pos = hurtData.pos
		hurtList[pos] = hurtData
		local hurt = xyd.getBattleNum(hurtData.hurt)
		local heal = xyd.getBattleNum(hurtData.heal)

		if maxDamage <= hurt then
			maxDamage = hurt
		end

		if maxHeal <= heal then
			maxHeal = heal
		end
	end

	table.sort(teamA, function (a, b)
		return a.pos < b.pos
	end)
	table.sort(teamB, function (a, b)
		return a.pos < b.pos
	end)

	for i = 1, 7 do
		local leftPartner = teamA[i] or nil
		local rightPartner = teamB[i] or nil

		if leftPartner then
			local pos = leftPartner.pos
			leftPartner.hurt = hurtList[pos]
		elseif i == #teamA + 1 and petA and petA.pet_id then
			leftPartner = petA
			leftPartner.hurt = hurtList[13]
		end

		if rightPartner then
			local pos = rightPartner.pos + 6
			rightPartner.hurt = hurtList[pos]
		elseif i == #teamB + 1 and petB and petB.pet_id then
			rightPartner = petB
			rightPartner.hurt = hurtList[14]
		end

		local params = {
			id = i,
			leftPartner = leftPartner,
			rightPartner = rightPartner,
			maxDamage = maxDamage,
			maxHeal = maxHeal,
			showType = self.showType,
			battleType = battleReport.battle_type
		}
		local node = NGUITools.AddChild(self.listGrid_, self.battleDetailItem_)

		node:SetActive(true)

		local dataItem = BattleDetailItem.new(node, params)

		table.insert(self.itemList, dataItem)
	end
end

function BattleDetailDataWindow:refreshListGroup()
	for i = 1, #self.itemList do
		local item = self.itemList[i]

		item:refreshProgressBar(self.showType, false)
	end
end

function BattleDetailDataWindow:willClose()
	BattleDetailDataWindow.super.willClose(self)
	self:clearItemAction()
end

function BattleDetailDataWindow:clearItemAction()
	for i = 1, #self.itemList do
		local item = self.itemList[i]

		item:clearAction()
	end
end

return BattleDetailDataWindow
