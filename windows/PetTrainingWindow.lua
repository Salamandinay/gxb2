local PetIcon = import("app.components.PetIcon")
local PngNum = import("app.components.PngNum")
local CountDown = import("app.components.CountDown")
local BaseWindow = import(".BaseWindow")
local PetTrainingWindow = class("PetTrainingWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")

function PetTrainingWindow:ctor(name, params)
	PetTrainingWindow.super.ctor(self, name, params)

	self.icons = {}
	self.chosenIcon = nil
	self.chosenPet = nil
	self.isMissionShow = false
	self.petTrainingModel = xyd.models.petTraining
end

function PetTrainingWindow:getUIComponent()
	local trans = self.window_.transform
	self.topGroup = trans:NodeByName("topGroup").gameObject
	self.topActionGroup = self.topGroup:NodeByName("topActionGroup").gameObject
	self.detailBtn = self.topActionGroup:NodeByName("detailBtn").gameObject
	self.helpBtn = self.topActionGroup:NodeByName("helpBtn").gameObject
	self.levLabel = self.topActionGroup:ComponentByName("levLabel", typeof(UILabel))
	self.progressBar = self.topActionGroup:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.petIconBtn = self.topActionGroup:NodeByName("petIconBtn").gameObject
	self.awardBtn = self.topActionGroup:NodeByName("awardBtn").gameObject
	self.hangLabel = self.topActionGroup:ComponentByName("hang_label", typeof(UILabel))
	self.awardGroup1 = self.topActionGroup:NodeByName("award_group_1").gameObject
	self.awardGroup2 = self.topActionGroup:NodeByName("award_group_2").gameObject
	self.bottomGroup = trans:NodeByName("bottomGroup").gameObject
	self.scroller = self.bottomGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:ComponentByName("itemGroup", typeof(UIGrid))
	self.timesLabel = self.bottomGroup:ComponentByName("timesLabel", typeof(UILabel))
	self.fightBtn = self.bottomGroup:NodeByName("fightBtn").gameObject
	self.fightBtnLabel = self.fightBtn:ComponentByName("label", typeof(UILabel))
	self.midGroup = trans:NodeByName("midGroup").gameObject
	self.petGroup = self.midGroup:NodeByName("petGroup").gameObject
	self.petModel = self.petGroup:NodeByName("model").gameObject
	self.strengthGroup = self.petGroup:NodeByName("strengthGroup").gameObject
	self.strengthLabel = self.petGroup:ComponentByName("strengthGroup/label", typeof(UILabel))
	self.strengthBg = self.strengthGroup:ComponentByName("bg", typeof(UISprite))
	self.strengthBtn = self.petGroup:NodeByName("strengthGroup/btn").gameObject
	self.bossGroup = self.midGroup:NodeByName("bossGroup").gameObject
	self.bossModel = self.bossGroup:NodeByName("model").gameObject
	self.damageGroup = self.bossGroup:NodeByName("damageGroup").gameObject
	self.bossSwitchBtn = self.bossGroup:NodeByName("btn").gameObject
	self.bossSwitchBtnRedMark = self.bossSwitchBtn:ComponentByName("redMark", typeof(UISprite))
	self.bossLabel = self.bossGroup:ComponentByName("label", typeof(UILabel))
	self.bossHp = self.bossGroup:ComponentByName("progressBar", typeof(UIProgressBar))
	self.bossAwardBtn = self.bossGroup:NodeByName("awardBtn").gameObject
end

function PetTrainingWindow:initWindow()
	self:getUIComponent()
	self:refreshLevel()
	self:initPetIcon()
	self:initModel()
	self:initMisson()
	self:layout()
	self:registerEvent()
end

function PetTrainingWindow:layout()
	self.windowTop = WindowTop.new(self.window_, self.name_, 6000, true, function ()
		self:onClickCloseButton()
	end)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)

	self.fightBtnLabel.text = __("FIGHT")
	self.bossHp.value = self.petTrainingModel:getBossHp() / xyd.tables.petTrainingBossTable:getHp(self.petTrainingModel:getBossID())

	if xyd.Global.lang == "fr_fr" then
		self.strengthBg.width = 240
		self.strengthLabel.width = 190

		self.strengthLabel:X(-40)
	end

	self:refreshLabel()
end

function PetTrainingWindow:refreshLabel()
	if self.chosenPet and self.petTrainingModel:getPetBattleTimes() and self.petTrainingModel:getPetBattleTimes()[math.floor(self.chosenPet.petID / 100)] then
		self.strengthLabel.text = __("PET_TRAINING_TEXT11", xyd.tables.miscTable:getNumber("pet_training_pet_energy", "value") - self.petTrainingModel:getPetBattleTimes()[math.floor(self.chosenPet.petID / 100)])
	else
		self.strengthLabel.text = __("PET_TRAINING_TEXT11", xyd.tables.miscTable:getNumber("pet_training_pet_energy", "value"))
	end

	self.bossLabel.text = xyd.tables.petTrainingTextTable:getBoss(self.petTrainingModel:getBossID())

	if self.chosenPet then
		if xyd.tables.miscTable:getNumber("pet_training_boss_limit", "value") - self.petTrainingModel:getBattleTimes() > 0 then
			self.timesLabel.text = __("PET_TRAINING_TEXT13", xyd.tables.miscTable:getNumber("pet_training_boss_limit", "value") - self.petTrainingModel:getBattleTimes())
		elseif self.petTrainingModel:getBuyTimeTimes() < xyd.tables.miscTable:getNumber("pet_training_energy_buy_limit", "value") then
			self.timesLabel.text = __("PET_TRAINING_TEXT21")
		else
			self.timesLabel.text = __("PET_TRAINING_TEXT22")

			xyd.applyChildrenGrey(self.fightBtn)

			self.fightBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		end
	else
		xyd.applyChildrenGrey(self.fightBtn)

		self.fightBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		self.timesLabel:SetActive(false)
		self.strengthGroup:SetActive(false)
	end
end

function PetTrainingWindow:refreshLevel()
	self.level = self.petTrainingModel:getTrainingLevel()
	self.levLabel.text = self.level
	local ids = xyd.tables.petTrainingTable:getIds()

	if self.level == ids[#ids] then
		self.progressBar.value = 1

		self.progressLabel:SetActive(false)
	else
		local max = xyd.tables.petTrainingTable:getExp(self.level + 1) - xyd.tables.petTrainingTable:getExp(self.level)
		local val = xyd.models.backpack:getItemNumByID(xyd.ItemID.PET_TRAINING_EXP) - xyd.tables.petTrainingTable:getExp(self.level)
		self.progressBar.value = val / max
		self.progressLabel.text = val .. "/" .. max
	end

	local data = xyd.db.misc:getValue("pet_training_new_boss")

	if tonumber(data) == 1 then
		self.bossSwitchBtnRedMark:SetActive(true)
	else
		self.bossSwitchBtnRedMark:SetActive(false)
	end
end

function PetTrainingWindow:initPetIcon()
	local ids = xyd.models.petSlot:getPetIDs()
	local maxIndex = 0

	table.sort(ids, function (a, b)
		local petA = xyd.models.petSlot:getPetByID(a)
		local scoreA = petA:getScore()
		local IDA = petA:getPetID()
		local petB = xyd.models.petSlot:getPetByID(b)
		local scoreB = petB:getScore()
		local IDB = petB:getPetID()

		if scoreA ~= scoreB then
			return scoreB < scoreA
		else
			return IDA < IDB
		end
	end)

	for i = 1, #ids do
		local pet = xyd.models.petSlot:getPetByID(ids[i])
		local petID = pet:getPetID()
		local petLev = pet:getLevel()

		if xyd.tables.miscTable:getNumber("pet_training_boss_level", "value") <= petLev and (self.petTrainingModel:getPetBattleTimes() == nil or self.petTrainingModel:getPetBattleTimes()[math.floor(petID / 100)] == nil or xyd.tables.miscTable:getNumber("pet_training_pet_energy", "value") - self.petTrainingModel:getPetBattleTimes()[math.floor(petID / 100)] > 0) then
			maxIndex = i

			break
		end
	end

	if maxIndex == 0 then
		maxIndex = 1
	end

	for i = 1, #ids do
		local pet = xyd.models.petSlot:getPetByID(ids[i])

		if pet.lev > 0 then
			local icon = PetIcon.new(self.itemGroup.gameObject)
			local data = {
				pet_id = pet.petID,
				lev = pet.lev,
				grade = pet.grade,
				scrollView = self.scroller,
				callback = function ()
					if pet:getLevel() < xyd.tables.miscTable:getNumber("pet_training_boss_level", "value") then
						xyd.showToast(__("PET_EXSKILL_TIPS_02", xyd.tables.miscTable:getNumber("pet_training_boss_level", "value")))
					else
						if self.chosenIcon then
							self.chosenIcon:setChosen(false)
						end

						self.chosenIcon = icon
						self.chosenPet = pet

						icon:setChosen(true)
						self:changeModel()
					end
				end
			}

			icon:setInfo(data)

			if i == maxIndex and xyd.tables.miscTable:getNumber("pet_training_boss_level", "value") <= pet.lev then
				icon:setChosen(true)

				self.chosenIcon = icon
				self.chosenPet = pet
			end

			if pet:getLevel() < xyd.tables.miscTable:getNumber("pet_training_boss_level", "value") then
				icon:setMask(true)
			end

			table.insert(self.icons, icon)
		end
	end

	self.itemGroup:Reposition()
end

function PetTrainingWindow:initModel()
	if self.chosenPet then
		self.petEffect = xyd.Spine.new(self.petModel)

		self.petEffect:setInfo(self.chosenPet:getModelName(), function ()
			local xy = xyd.tables.petTable:getTrainingXY(self.chosenPet:getPetID())
			local scale = xyd.tables.petTable:getTrainingScale(self.chosenPet:getPetID())

			self.petEffect:SetLocalScale(scale[1], scale[2], 1)
			self.petEffect:SetLocalPosition(xy[1], xy[2], 0)
			self.petEffect:play("idle", 0, 1)
		end, true)
	else
		local ids = xyd.models.petSlot:getPetIDs()

		table.sort(ids, function (a, b)
			local petA = xyd.models.petSlot:getPetByID(a)
			local scoreA = petA:getScore()
			local petB = xyd.models.petSlot:getPetByID(b)
			local scoreB = petB:getScore()

			return scoreB < scoreA
		end)

		local pet = xyd.models.petSlot:getPetByID(ids[1])
		self.petEffect = xyd.Spine.new(self.petModel)

		self.petEffect:setInfo(pet:getModelName(), function ()
			local xy = xyd.tables.petTable:getTrainingXY(pet:getPetID())
			local scale = xyd.tables.petTable:getTrainingScale(pet:getPetID())

			self.petEffect:SetLocalScale(scale[1], scale[2], 1)
			self.petEffect:SetLocalPosition(xy[1], xy[2], 0)
			self.petEffect:play("idle", 0, 1)
		end, true)
	end

	self.bossEffect = xyd.Spine.new(self.bossModel)

	self.bossEffect:setInfo("muzhuangren", function ()
		self.bossEffect:SetLocalScale(0.34, 0.34, 1)
		self.bossEffect:SetLocalPosition(0, -150, 0)
		self.bossEffect:play("idle", 0, 1)
	end, true)
end

function PetTrainingWindow:changeModel()
	self.petEffect:destroy()

	self.petEffect = xyd.Spine.new(self.petModel)

	self.petEffect:setInfo(self.chosenPet:getModelName(), function ()
		local xy = xyd.tables.petTable:getTrainingXY(self.chosenPet:getPetID())
		local scale = xyd.tables.petTable:getTrainingScale(self.chosenPet:getPetID())

		self.petEffect:SetLocalScale(scale[1], scale[2], 1)
		self.petEffect:SetLocalPosition(xy[1], xy[2], 0)
		self.petEffect:play("idle", 0, 1)
	end, true)

	if self.petTrainingModel:getPetBattleTimes() and self.petTrainingModel:getPetBattleTimes()[math.floor(self.chosenPet.petID / 100)] then
		self.strengthLabel.text = __("PET_TRAINING_TEXT11", xyd.tables.miscTable:getNumber("pet_training_pet_energy", "value") - self.petTrainingModel:getPetBattleTimes()[math.floor(self.chosenPet.petID / 100)])
	else
		self.strengthLabel.text = __("PET_TRAINING_TEXT11", xyd.tables.miscTable:getNumber("pet_training_pet_energy", "value"))
	end
end

function PetTrainingWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self:refreshLevel()
	end)
	self.eventProxy_:addEventListener(xyd.event.PET_TRAINING_FIGHT, handler(self, self.onFight))
	self.eventProxy_:addEventListener(xyd.event.PET_TRAINING_SELECT_BOSS, handler(self, self.onSelectBoss))
	self.eventProxy_:addEventListener(xyd.event.PET_TRAINING_BUY_TIMES, handler(self, self.refreshLabel))
	self.eventProxy_:addEventListener(xyd.event.PET_TRAINING_GET_AWARD, handler(self, self.onGetTrainingAward))

	UIEventListener.Get(self.detailBtn).onClick = function ()
		xyd.openWindow("pet_training_detail2_window")
	end

	UIEventListener.Get(self.awardBtn).onClick = function ()
		if self.lastHangRound == 0 then
			xyd.alertTips(__("PEW_TRAINNG_HANGUP_TEXT10"))
		else
			self.petTrainingModel:reqTrainingAward()
		end
	end

	UIEventListener.Get(self.petIconBtn).onClick = function ()
		xyd.openWindow("pet_training_detail1_window")
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.openWindow("help_window", {
			key = "PET_TRAINING_HELP"
		})
	end

	UIEventListener.Get(self.fightBtn).onClick = function ()
		if self.onFighting then
			return
		end

		if xyd.tables.miscTable:getNumber("pet_training_boss_limit", "value") - self.petTrainingModel:getBattleTimes() > 0 then
			if self.petTrainingModel:getPetBattleTimes() and self.petTrainingModel:getPetBattleTimes()[math.floor(self.chosenPet.petID / 100)] and xyd.tables.miscTable:getNumber("pet_training_pet_energy", "value") <= self.petTrainingModel:getPetBattleTimes()[math.floor(self.chosenPet.petID / 100)] then
				xyd.showToast(__("PET_TRAINING_TEXT24"))
			else
				self.lastHp = self.petTrainingModel:getBossHp()

				self.petTrainingModel:fight(self.chosenPet.petID)
				xyd.SoundManager.get():playSound(2138)

				self.onFighting = true
			end
		elseif self.petTrainingModel:getBuyTimeTimes() < xyd.tables.miscTable:getNumber("pet_training_energy_buy_limit", "value") then
			xyd.showToast(__("PET_TRAINING_TEXT23"))
		end
	end

	UIEventListener.Get(self.bossSwitchBtn).onClick = function ()
		local data = xyd.db.misc:getValue("pet_training_new_boss")

		if tonumber(data) == 1 then
			self.bossSwitchBtnRedMark:SetActive(false)
			xyd.db.misc:setValue({
				value = 0,
				key = "pet_training_new_boss"
			})
		end

		xyd.openWindow("pet_training_boss_select_window", {
			boss_id = self.petTrainingModel:getBossID()
		})
	end

	UIEventListener.Get(self.bossAwardBtn).onClick = function ()
		xyd.openWindow("pet_training_boss_award_window")
	end

	UIEventListener.Get(self.strengthBtn).onClick = function ()
		if xyd.tables.miscTable:getNumber("pet_training_energy_buy_limit", "value") <= self.petTrainingModel:getBuyTimeTimes() then
			xyd.showToast(__("PET_TRAINING_TEXT18", xyd.tables.miscTable:getNumber("pet_training_energy_buy_limit", "value")))
		else
			xyd.alert(xyd.AlertType.YES_NO, __("PET_TRAINING_TEXT19", xyd.tables.miscTable:split2Cost("pet_training_energy_buy_cost", "value", "|#")[self.petTrainingModel:getBuyTimeTimes() + 1][2]), function (yes)
				if yes then
					self.petTrainingModel:buyTimes(self.chosenPet:getPetID())
				end
			end)
		end
	end
end

function PetTrainingWindow:initMisson()
	self.petIconBtn = self.topActionGroup:NodeByName("petIconBtn").gameObject
	local petIconLabel = self.petIconBtn:ComponentByName("btn_label", typeof(UILabel))
	self.allPetLev = xyd.models.petSlot:getAllPetLev()
	petIconLabel.text = self.allPetLev
	self.awardBtn = self.topActionGroup:NodeByName("awardBtn").gameObject
	local awardBtnLabel = self.awardBtn:ComponentByName("btn_label", typeof(UILabel))
	awardBtnLabel.text = __("ACTIVITY_GROWTH_PLAN_TEXT07")

	self:refreshTrainingAward()
end

function PetTrainingWindow:refreshTrainingAward()
	local levExtraDatas = xyd.tables.miscTable:split2Cost("pet_training_hangup_awards2_coefficient", "value", "|#")
	local extraNum = 1

	for _, extraData in ipairs(levExtraDatas) do
		local lev = extraData[1]
		local extra = extraData[2]

		if tonumber(lev) <= self.allPetLev then
			extraNum = tonumber(extra)
		else
			break
		end
	end

	local cycleTime = xyd.tables.miscTable:getVal("pet_training_hangup_cycle")
	local maxHangTime = xyd.tables.petTrainingNewAwardsTable:getTime(self.level)
	local hangStartTime = self.petTrainingModel:getHangTime()
	local nowTime = xyd.getServerTime(true)
	self.hangTime = math.min(nowTime - hangStartTime, maxHangTime)
	self.lastHangRound = math.floor(self.hangTime / cycleTime)
	local duration = maxHangTime - self.hangTime

	if duration > 0 then
		if not self.hangCountDown then
			self.hangCountDown = CountDown.new(self.hangLabel)
		end

		local params = {
			key = "PEW_TRAINNG_HANGUP_TEXT01",
			duration = duration,
			callback = function ()
				self.hangLabel.text = __("PEW_TRAINNG_HANGUP_TEXT02")
			end,
			doOnTime = function ()
				self.hangTime = self.hangTime + 1
				self.hangTime = math.min(self.hangTime, maxHangTime)
				local newRound = math.floor(self.hangTime / cycleTime)

				if newRound ~= self.lastHangRound then
					self.lastHangRound = newRound
					self.awardIcon1 = self:initHangAward(1, self.hangTime, extraNum, cycleTime)
					self.awardIcon2 = self:initHangAward(2, self.hangTime, extraNum, cycleTime)
				end
			end
		}

		self.hangCountDown:setInfo(params)
	else
		self.hangLabel.text = __("PEW_TRAINNG_HANGUP_TEXT02")
	end

	self.awardIcon1 = self:initHangAward(1, self.hangTime, extraNum, cycleTime)
	self.awardIcon2 = self:initHangAward(2, self.hangTime, extraNum, cycleTime)
end

function PetTrainingWindow:initHangAward(pos, hangTime, extraNum, cycleTime)
	local awards = xyd.tables.petTrainingNewAwardsTable:getAward(self.level, pos)
	local awardNum = math.floor(awards[2] * math.floor(hangTime / cycleTime) * extraNum)
	local iconParams = {
		scale = 0.5462962962962963,
		show_has_num = true,
		itemID = awards[1],
		num = awardNum
	}
	local icon = nil

	if self["awardIcon" .. pos] then
		icon = self["awardIcon" .. pos]

		icon:setInfo(iconParams)
	else
		iconParams.uiRoot = self["awardGroup" .. pos]
		icon = xyd.getItemIcon(iconParams)
	end

	return icon
end

function PetTrainingWindow:getNumView(num)
	local pngNum = PngNum.new(self.damageGroup)
	local iconName = "battle_normal"
	local isAbbr = false

	pngNum:setInfo({
		isShowAdd = true,
		iconName = iconName,
		num = num,
		isAbbr = isAbbr
	})

	pngNum.scale = 0.9

	return pngNum
end

function PetTrainingWindow:playDamageNum(num)
	local view = self:getNumView(num)
	local transform = view:getGameObject().transform
	local scaleX = transform.localScale.x
	local scaleY = transform.localScale.y
	local x_ = transform.localPosition.x
	local y_ = transform.localPosition.y
	local sequence = self:getSequence()

	view:getGameObject():SetActive(true)

	local w = view:getGameObject():GetComponent(typeof(UIWidget))

	local function getter()
		return w.color
	end

	local function setter(value)
		w.color = value
	end

	sequence:Append(transform:DOScale(Vector3(scaleX * 1.25, scaleY * 1.25, 1), 0.067))
	sequence:Append(transform:DOScale(Vector3(scaleX * 0.9, scaleY * 0.9, 1), 0.1))
	sequence:Append(transform:DOScale(Vector3(scaleX * 1.05, scaleY * 1.05, 1), 0.1))
	sequence:Append(transform:DOScale(Vector3(scaleX * 0.95, scaleY * 0.95, 1), 0.067))
	sequence:Append(transform:DOScale(Vector3(scaleX, scaleY, 1), 0.067))
	sequence:AppendInterval(0.1)
	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0.8))
	sequence:Join(transform:DOLocalMove(Vector3(x_, y_ + 40, 0), 0.8))
	sequence:AppendCallback(function ()
		NGUITools.Destroy(view:getGameObject())
	end)
end

function PetTrainingWindow:onFight()
	self:refreshLabel()

	local sequence = self:getSequence()
	local x = self.petModel.transform.localPosition.x
	local y = self.petModel.transform.localPosition.y

	sequence:Insert(0, self.petModel.transform:DOLocalRotate(Vector3(0, 0, 4.12), 0.08333333333333333))
	sequence:Insert(0, self.petModel.transform:DOLocalMove(Vector3(x - 27.63, y, 0), 0.08333333333333333))
	sequence:Insert(0.08333333333333333, self.petModel.transform:DOLocalRotate(Vector3(0, 0, 359.94), 0.03333333333333333))
	sequence:Insert(0.08333333333333333, self.petModel.transform:DOLocalMove(Vector3(x + 218.9, y, 0), 0.03333333333333333))
	sequence:Insert(0.11666666666666667, self.petModel.transform:DOLocalRotate(Vector3(0, 0, 359.33), 0.1))
	sequence:Insert(0.11666666666666667, self.petModel.transform:DOLocalMove(Vector3(x + 222.5, y, 0), 0.1))
	sequence:InsertCallback(0.11666666666666667, function ()
		self.bossEffect:play("hurt", 1, 1, function ()
			self.bossEffect:play("idle", 0, 1)
		end)
	end)
	sequence:Insert(0.21666666666666667, self.petModel.transform:DOLocalRotate(Vector3(0, 0, 360), 0.05))
	sequence:Insert(0.21666666666666667, self.petModel.transform:DOLocalMove(Vector3(x, y, 0), 0.05))
	sequence:InsertCallback(0.4166666666666667, function ()
		self.onFighting = false
		self.bossHp.value = self.petTrainingModel:getBossHp() / xyd.tables.petTrainingBossTable:getHp(self.petTrainingModel:getBossID())
		local damageNum = self.lastHp
		local data = {}

		if self.lastHp <= self.petTrainingModel:getBossHp() then
			local items = xyd.tables.petTrainingBossTable:getFinalAwards(self.petTrainingModel:getBossID())

			for i = 1, #items do
				table.insert(data, {
					item_id = items[i][1],
					item_num = items[i][2]
				})
			end
		else
			damageNum = self.lastHp - self.petTrainingModel:getBossHp()
			local items = xyd.tables.petTrainingBossTable:getBattleAwards(self.petTrainingModel:getBossID())

			for i = 1, #items do
				table.insert(data, {
					item_id = items[i][1],
					item_num = items[i][2]
				})
			end
		end

		self:playDamageNum(-damageNum)
		xyd.models.itemFloatModel:pushNewItems(data)
	end)
end

function PetTrainingWindow:onSelectBoss(event)
	self.bossLabel.text = xyd.tables.petTrainingTextTable:getBoss(self.petTrainingModel:getBossID())
	self.bossHp.value = self.petTrainingModel:getBossHp() / xyd.tables.petTrainingBossTable:getHp(self.petTrainingModel:getBossID())
end

function PetTrainingWindow:onGetTrainingAward(event)
	self:refreshLevel()
	self:refreshTrainingAward()

	local items = event.data.items
	local itemsData = {}

	for _, item in ipairs(items) do
		table.insert(itemsData, {
			item_id = item.item_id,
			item_num = item.item_num
		})
	end

	xyd.models.itemFloatModel:pushNewItems(itemsData)
end

return PetTrainingWindow
