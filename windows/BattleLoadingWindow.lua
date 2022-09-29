local BattleLoadingWindow = class("BattleLoadingWindow", import(".BaseWindow"))
local CustomBackgroundTable = xyd.tables.customBackgroundTable
local MonsterTable = xyd.tables.monsterTable
local EquipTable = xyd.tables.equipTable
local PartnerTable = xyd.tables.partnerTable
local PetTable = xyd.tables.petTable
local ModelTable = xyd.tables.modelTable
local SkillTable = xyd.tables.skillTable
local SoundTable = xyd.tables.soundTable
local ResourceEffectTable = xyd.tables.resourceEffectTable

function BattleLoadingWindow:ctor(name, params)
	BattleLoadingWindow.super.ctor(self, name, params)

	self.totalResUrls_ = {}
	self.progress_ = 0
	self.basicProgress_ = 0
	self.modelProgress_ = 0
	self.preloadProgress_ = 0
	self.battleComplete_ = false
	self.basicComplete_ = false
	self.tweenToProgress_ = 0
	self.currRealProgress_ = 0
	self.startTime_ = 0
	self.curTipsID_ = 0
	self.tipsTimeKey = -1
	self.isProgressComplete_ = false
	self.callback = nil
	self.oldTime_ = 0
	self.sounds = {}
	self.battleSound = 0
	self.selectSoundPos = 0
	self.clearRes_ = {}
	self.groupNames_ = {}
	self.heroIDs = {
		54001,
		52005
	}
	self.skillNameStoke = {
		1965690623,
		2787417087.0
	}
	self.petGroup = {
		"ui_pet_energybar",
		"ui_pet_energyfull"
	}
	self.rectColor = {
		nil,
		3041613298.0,
		1581402802,
		2927343346.0,
		3968878834.0,
		2254857458.0,
		2791801778.0,
		1329216946,
		1786220466,
		3865674482.0
	}
	self.labelColor = {
		nil,
		4294177791.0,
		4126403327.0,
		4109303295.0,
		2976200703.0,
		1784043007,
		4143185407.0,
		4261077759.0,
		4093443583.0,
		3161028863.0
	}
	self.labelStrokeColor = {
		nil,
		3041810687.0,
		1983655935,
		1765965311,
		4294967295.0,
		4294967295.0,
		2722194943.0,
		2285185023.0,
		1366273023,
		4294967295.0
	}
end

function BattleLoadingWindow:willClose()
	BattleLoadingWindow.super.willClose(self)
end

function BattleLoadingWindow:adaptX()
	local height = math.min(UnityEngine.Screen.height, xyd.Global.getMaxBgHeight())

	if xyd.Global.getMaxHeight() <= height then
		self.groupBot_:GetComponent(typeof(UIWidget)):SetBottomAnchor(self.window_, 0, 21 - (height - xyd.Global.getMaxHeight()))
	end
end

function BattleLoadingWindow:initWindow()
	BattleLoadingWindow.super.initWindow(self)
	self:getUIComponent()
	self:adaptX()
	self:layout()
	xyd.DownloadController.get():stopDownload()
end

function BattleLoadingWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupMain_ = winTrans:NodeByName("groupMain_").gameObject
	self.bg_ = self.groupMain_:ComponentByName("bg_", typeof(UITexture))
	self.groupBot_ = self.groupMain_:NodeByName("groupBot_").gameObject
	self.bar_ = self.groupBot_:ComponentByName("bar_", typeof(UISlider))
	self.effectGroup = self.groupMain_:NodeByName("effectGroup").gameObject
	self.lableTop_ = self.groupMain_:ComponentByName("lableTop_", typeof(UILabel))
	self.group1 = self.groupMain_:NodeByName("group1").gameObject
	self.img1 = self.group1:ComponentByName("img1", typeof(UITexture))
	self.rect1 = self.group1:ComponentByName("e:Group/rect1", typeof(UISprite))
	self.label1 = self.group1:ComponentByName("e:Group/label1", typeof(UILabel))
	self.group2 = self.groupMain_:NodeByName("group2").gameObject
	self.img2 = self.group2:ComponentByName("img2", typeof(UITexture))
	self.rect2 = self.group2:ComponentByName("e:Group/rect2", typeof(UISprite))
	self.labelcv = self.group2:ComponentByName("e:Group/labelcv", typeof(UILabel))
	self.label2 = self.group2:ComponentByName("label2", typeof(UILabel))
end

function BattleLoadingWindow:layout()
	if self.startTime_ == 0 then
		self.startTime_ = os.time()
	end

	local num = xyd.models.background:getLoadingPicNum()
	local is_effect = xyd.models.background:getIsEffectType(num)

	if is_effect == 1 then
		local picPath = CustomBackgroundTable:getEffectBackground(num)

		xyd.setUITextureByNameAsync(self.bg_, picPath, false)

		local bg_offset = CustomBackgroundTable:getPictureOffset(num)

		self.bg_:SetLocalPosition(bg_offset[1] or 0, -bg_offset[2] or 0, 0)
		xyd.fitFullScreen2(self.bg_)

		local effect_name = CustomBackgroundTable:getEffect(num)
		local animation_name = CustomBackgroundTable:getAnimation(num)
		local offset = CustomBackgroundTable:getOffset(num)
		local effect = xyd.Spine.new(self.effectGroup)
		local rate = 1.21796875

		self.effectGroup:SetLocalScale(self.bg_.height / 1559, self.bg_.height / 1559, 1)
		effect:setInfo(effect_name, function ()
			effect:SetLocalScale(1, 1, 1)
			effect:SetLocalPosition(offset[1] * rate, -offset[2] * rate, 0)
			effect:play(animation_name, 0)
		end)
	else
		local picPath = CustomBackgroundTable:getPicture(num)

		xyd.fitFullScreen2(self.bg_)
		self.bg_:SetLocalPosition(0, 0, 0)
		xyd.setUITextureByNameAsync(self.bg_, picPath, false)
	end

	self.bg_.width = self.bg_.height
	local rect, label, img = nil
	num = num - 3

	if num == 1 then
		self.lableTop_:SetActive(true)

		self.lableTop_.text = __("BATTLE_TIPS_DESC1")
	elseif num == 2 then
		rect = self.rect2
		label = self.label2
		img = self.img2

		self.group2:SetActive(true)
		self.group2:SetLocalPosition(-191, -250, 0)
	elseif num == 4 then
		rect = self.rect2
		label = self.label2
		img = self.img2

		self.group2:SetActive(true)
		self.group2:SetLocalPosition(191, -230, 0)

		rect.width = 338
	elseif num == 5 or num == 6 or num == 10 then
		rect = self.rect2
		label = self.label2
		img = self.img2

		self.group2:SetLocalPosition(-191, 530, 0)
		self.group2:SetActive(true)
	elseif num == 3 or num == 7 or num == 8 or num == 9 then
		rect = self.rect1
		label = self.label1
		img = self.img1

		if xyd.Global.lang == "de_de" then
			img:Y(0)
		end

		self.group1:SetActive(true)
	end

	if rect then
		rect.color = Color.New2(self.rectColor[num])
	end

	if label then
		label.color = Color.New2(self.labelColor[num])
		label.effectColor = Color.New2(self.labelStrokeColor[num])
		label.text = __("BATTLE_LOADING_" .. tostring(num))
	end

	if img then
		local source = "Textures/battle_loading_text_web/battle_loading_" .. num .. "_" .. xyd.Global.lang

		xyd.setUITextureByNameAsync(img, "battle_loading_" .. num .. "_" .. xyd.Global.lang, true)
	end

	if xyd.arrayIndexOf({
		2,
		4,
		5,
		6,
		10
	}, num) > -1 then
		self.labelcv.text = __("BATTLE_LOADING_CV_" .. tostring(num))
	end

	local labelBar = self.bar_:ComponentByName("labelDisplay", typeof(UILabel))

	XYDUtils.AddEventDelegate(self.bar_.onChange, function ()
		local val = self.bar_.value
		local str = tostring(math.floor(val * 100)) .. "%"
		str = "Now loading...  " .. tostring(str)
		labelBar.text = str
	end)
	self.groupBot_:SetActive(true)
	xyd.models.background:updateLoadingPicNum()
end

function BattleLoadingWindow:setBattleData(data)
	self.data_ = data

	self:checkComplete()

	local battleReport = data.battle_report

	if data.event_data and data.event_data.battle_report then
		battleReport = data.event_data.battle_report
	end

	local herosA = battleReport.teamA
	local herosB = battleReport.teamB
	local petA = battleReport.petA
	local petB = battleReport.petB
	xyd.Global.curBattleInfo = {
		title = "battle",
		teamA = herosA,
		teamB = herosB,
		battle_id = battleReport.info.battle_id
	}
	local subNames = {}
	local skillIDs = {}
	local ids = {}

	for _, hero in ipairs(herosA) do
		local modelName = xyd.getModelNameByID(hero.table_id, hero.isMonster, hero.skin_id, hero.show_skin)

		if xyd.arrayIndexOf(subNames, modelName) == -1 then
			table.insert(subNames, modelName)
		end

		local heroID = hero.table_id

		if hero.isMonster then
			heroID = MonsterTable:getPartnerLink(heroID)
		end

		if xyd.arrayIndexOf(ids, heroID) == -1 then
			table.insert(ids, {
				heroID = heroID,
				skinID = hero.skin_id or 0
			})
		end

		local skillIndex = 0

		if hero.skin_id and hero.skin_id > 0 and hero.show_skin == 1 then
			skillIndex = EquipTable:getFxIndex(hero.skin_id)
		end

		table.insert(skillIDs, {
			skills = self:getSkillIDs(hero.table_id, hero.isMonster),
			skillIndex = skillIndex + 1
		})
	end

	if battleReport.info.battle_id ~= 100001 then
		local index = math.random(1, #herosA)
		local heroID = nil

		if herosA[index] then
			heroID = herosA[index].table_id

			if herosA[index].isMonster then
				heroID = MonsterTable:getPartnerLink(heroID)
			end

			local sound = PartnerTable:getBattleSound(heroID, herosA[index].skin_id)

			if sound then
				local soundID = sound.id

				if soundID > 0 then
					self.battleSound = soundID
					self.selectSoundPos = herosA[index].pos
				end
			end
		end
	end

	for _, hero in ipairs(herosB) do
		local modelName = xyd.getModelNameByID(hero.table_id, hero.isMonster, hero.skin_id, hero.show_skin)

		if xyd.arrayIndexOf(subNames, modelName) == -1 then
			table.insert(subNames, modelName)
		end

		local heroID = hero.table_id

		if hero.isMonster then
			heroID = MonsterTable:getPartnerLink(heroID)
		end

		if xyd.arrayIndexOf(ids, heroID) == -1 then
			table.insert(ids, {
				heroID = heroID,
				skinID = hero.skin_id or 0
			})
		end

		local skillIndex = 0

		if hero.skin_id and hero.skin_id > 0 and hero.show_skin == 1 then
			skillIndex = EquipTable:getFxIndex(hero.skin_id)
		end

		table.insert(skillIDs, {
			skills = self:getSkillIDs(hero.table_id, hero.isMonster),
			skillIndex = skillIndex + 1
		})
	end

	if petA and tostring(petA) ~= "" and petA.pet_id then
		local modelID = PetTable:getModelID(petA.pet_id) + petA.grade - 1
		local modelName = ModelTable:getModelName(modelID)

		if xyd.arrayIndexOf(subNames, modelName) == -1 then
			table.insert(subNames, modelName)
		end

		table.insert(skillIDs, {
			skillIndex = 1,
			skills = {
				PetTable:getEnergyID(petA.pet_id) + petA.lv - 1
			}
		})
	end

	if petB and tostring(petB) ~= "" and petB.pet_id then
		local modelID = PetTable:getModelID(petB.pet_id) + petB.grade - 1
		local modelName = ModelTable:getModelName(modelID)

		if xyd.arrayIndexOf(subNames, modelName) == -1 then
			table.insert(subNames, modelName)
		end

		table.insert(skillIDs, {
			skillIndex = 1,
			skills = {
				PetTable:getEnergyID(petB.pet_id) + petB.lv - 1
			}
		})
	end

	if self:checkInGuide(battleReport.info.battle_id) then
		table.insert(subNames, "buff_guide")
	else
		table.insert(subNames, "buff")
	end

	local sounds = self:getSounds(skillIDs, ids, battleReport.info.battle_id)
	local battleType = data.battle_type
	local map = self:getMap(battleReport.info.battle_id, battleType)
	local slotImg = self:getSlotImg(battleReport.info.battle_id)
	local others = xyd.arrayMerge(sounds, map)
	local stageId = data.stage_id

	if slotImg and slotImg ~= "" then
		table.insert(others, slotImg)
	end

	if data.event_data and data.event_data.stage_id then
		stageId = data.event_data.stage_id
	end

	local storyRes = self:getStoryRes(stageId, battleType)
	others = xyd.arrayMerge(others, storyRes)

	if xyd.tables.stageTable:isShowBattleEffect(stageId) or battleType == xyd.BattleType.HERO_CHALLENGE then
		local effects = xyd.getEffectFilesByNames({
			xyd.Battle.effect_battlecover
		})
		others = xyd.arrayMerge(others, effects)
	elseif battleType == xyd.BattleType.TIME_CLOISTER_EXTRA or battleType == xyd.BattleType.TIME_CLOISTER_BATTLE then
		local effects = xyd.getEffectFilesByNames({
			xyd.Battle.effect_battle_time_cloister
		})
		others = xyd.arrayMerge(others, effects)
	end

	local enemyInfo = nil

	if data.event_data.enemy_info then
		enemyInfo = data.event_data.enemy_info
	end

	local selfInfo = nil

	if data.event_data.self_info then
		selfInfo = data.event_data.self_info
	end

	local styleList = self:getSenpaiDressList(enemyInfo, selfInfo, battleType)

	if styleList and next(styleList) then
		local styleNames = xyd.getSenpaiModelResByIDs(styleList)
		local effects = xyd.getEffectFilesByNames(styleNames)
		others = xyd.arrayMerge(others, effects)
		local path1 = xyd.getSpritePath("pvp_vs_bg_red")
		local path2 = xyd.getSpritePath("pvp_vs_bg_blue")

		table.insert(others, path1)
		table.insert(others, path2)
	end

	self:loadBattleResource(subNames, others)
end

function BattleLoadingWindow:getSenpaiDressList(enemyInfo, selfInfo, battleType)
	if not enemyInfo and not enemyInfo then
		return {}
	end

	if not enemyInfo.dress_style and not selfInfo.dress_style then
		return {}
	end

	if not xyd.checkShowPvpWindow(battleType) then
		return {}
	end

	local styleList = {}
	local dressIds = xyd.tables.senpaiDressSlotTable:getIDs()

	for i = 1, #dressIds do
		local enemyStyleID, selfStyleID = nil

		if enemyInfo.dress_style and enemyInfo.dress_style[i] then
			enemyStyleID = tonumber(enemyInfo.dress_style[i])
		else
			enemyStyleID = xyd.tables.senpaiDressSlotTable:getDefaultStyle(dressIds[i])
		end

		if enemyStyleID and xyd.arrayIndexOf(styleList, enemyStyleID) == -1 then
			table.insert(styleList, enemyStyleID)
		end

		if selfInfo.dress_style and selfInfo.dress_style[i] then
			selfStyleID = tonumber(selfInfo.dress_style[i])
		else
			selfStyleID = xyd.tables.senpaiDressSlotTable:getDefaultStyle(dressIds[i])
		end

		if selfStyleID and xyd.arrayIndexOf(styleList, selfStyleID) == -1 then
			table.insert(styleList, selfStyleID)
		end
	end

	return styleList
end

function BattleLoadingWindow:checkInGuide(battleId)
	return battleId == 100001 or battleId == 100002
end

function BattleLoadingWindow:getStoryRes(stageId, battleType)
	if xyd.Global.isReview == 1 then
		return {}
	end

	local plotIds = {}
	local storyType = xyd.StoryType.MAIN

	if stageId and battleType == xyd.BattleType.CAMPAIGN then
		plotIds = xyd.tables.mainPlotListTable:getPlotIDsByStageID(stageId)
	elseif stageId and battleType == xyd.BattleType.HERO_CHALLENGE and xyd.models.heroChallenge:checkPlayStory(stageId) then
		plotIds = xyd.tables.partnerChallengeTable:plotId(stageId)
		storyType = xyd.StoryType.PARTNER
	elseif stageId and battleType == xyd.BattleType.LIBRARY_WATCHER_STAGE_FIGHT then
		plotIds = xyd.tables.activityNewStoryTable:getPlotIds(stageId)
		storyType = xyd.StoryType.MAIN
	end

	local res_ = self:getStoryResByPlotIds(plotIds, storyType)

	return res_
end

function BattleLoadingWindow:getStoryResByPlotIds(plotIds, storyType)
	if not plotIds or #plotIds == 0 then
		return {}
	end

	local res_ = {}

	if plotIds then
		for i = 2, 3 do
			if plotIds[i] then
				local tmpRes = xyd.getStoryLoadRes(plotIds[i], storyType, {}, {})
				res_ = xyd.arrayMerge(res_, tmpRes)
			end
		end
	end

	if plotIds and plotIds[2] > 0 then
		local effects = xyd.getEffectFilesByNames({
			xyd.Battle.effect_switch
		})
		res_ = xyd.arrayMerge(res_, effects)
	end

	return res_
end

function BattleLoadingWindow:getMap(battleID, battleType)
	if battleType == xyd.BattleType.TRIAL then
		return {
			xyd.getTexturePath("battle_map_trial_1")
		}
	elseif self.data_.battle_type == xyd.BattleType.GUILD_WAR then
		return {
			xyd.getTexturePath("battle_map_13_1")
		}
	end

	if battleID == 1 then
		return {
			xyd.getTexturePath("battle_map_2_1")
		}
	end

	local maps = xyd.tables.battleTable:getMap(battleID)
	local res = {}

	for _, map in ipairs(maps) do
		table.insert(res, xyd.getTexturePath(map))
	end

	return res
end

function BattleLoadingWindow:getSlotImg(battleID)
	local res = xyd.tables.battleTable:getBossMap(battleID)

	return xyd.getTexturePath(res)
end

function BattleLoadingWindow:getSounds(skillIDs, ids, battleID)
	local sounds = {}

	if xyd.SoundManager.get():isEffectOn() then
		for _, data in ipairs(skillIDs) do
			local index = data.skillIndex
			local skills = data.skills

			for _, skill in ipairs(skills) do
				local id = SkillTable:getSound(skill, index)

				if id > 0 then
					local res = xyd.getSoundPath(id)

					if res and xyd.arrayIndexOf(sounds, res) == -1 then
						table.insert(sounds, res)
					end
				end
			end
		end

		for _, soundData in ipairs(ids) do
			local sound = PartnerTable:getSkillSound(soundData.heroID, soundData.skinID)
			local soundID = sound.id

			if soundID > 0 then
				local res = xyd.getSoundPath(soundID)

				if res and xyd.arrayIndexOf(sounds, res) == -1 then
					table.insert(sounds, res)
				end
			end
		end

		if battleID ~= 100001 and self.battleSound > 0 then
			local res = xyd.getSoundPath(self.battleSound)

			if res and xyd.arrayIndexOf(sounds, res) == -1 then
				table.insert(sounds, res)
			end
		end

		table.insert(sounds, xyd.getSoundPath(xyd.SoundID.BATTLE))
	end

	self.sounds = sounds

	return sounds
end

function BattleLoadingWindow:getSkillIDs(tableID, isMonster)
	local heroTableID = tableID

	if isMonster then
		heroTableID = MonsterTable:getPartnerLink(tableID)
	end

	local res = {}

	table.insert(res, PartnerTable:getPugongID(heroTableID))
	table.insert(res, PartnerTable:getEnergyID(heroTableID))

	for i = 1, 3 do
		local skillID = PartnerTable:getPasSkill(heroTableID, i)

		if skillID and skillID > 0 then
			table.insert(res, skillID)
		end
	end

	return res
end

function BattleLoadingWindow:loadBattleResource(groupNames, others)
	self.groupNames_ = groupNames
	local datas = self:getHeroEffectFile(groupNames)
	others = xyd.arrayMerge(others, datas)

	local function completeFunc(isSuccess)
		if not isSuccess then
			xyd.BattleController.get():resourceLoadError()
		else
			self:preLoadRes()
		end
	end

	local function progressFunc(progress)
		local val = 100 * progress
		self.modelProgress_ = val

		self:changeProgress()
	end

	xyd.BattleEffectFactory.get():setLoadData(others)

	self.totalResUrls_ = others

	ResCache.DownloadAssets("battle_load_res", others, completeFunc, progressFunc, 0.1)
end

function BattleLoadingWindow:preLoadRes()
	ResManager.PreloadABsByPathAsync("battle_effect_pre_load_urls" .. xyd.getServerTime(), self.totalResUrls_, function ()
		self.battleComplete_ = true

		self:checkComplete()
	end, function (progress)
		local val = 100 * progress
		self.preloadProgress_ = val

		self:changeProgress2()
	end)
end

function BattleLoadingWindow:initEffectData()
	local groupNames = self.groupNames_

	for i = 1, #groupNames do
		local names = ResourceEffectTable:getResNames(groupNames[i])

		for _, name in ipairs(names) do
			-- Nothing
		end
	end
end

function BattleLoadingWindow:getHeroEffectFile(groupNames)
	local datas = {}

	for i = 1, #groupNames do
		local names = ResourceEffectTable:getResNames(groupNames[i])
		local files = xyd.getEffectFilesByNames(names)
		datas = xyd.arrayMerge(datas, files)
	end

	local battleReport = self.data_.battle_report

	if self.data_.event_data and self.data_.event_data.battle_report then
		battleReport = self.data_.event_data.battle_report
	end

	local petA = battleReport.petA

	if petA then
		local files = xyd:getEffectFilesByNames(self.petGroup)
		datas = xyd.arrayMerge(datas, files)
	end

	return datas
end

function BattleLoadingWindow:initTexture()
end

function BattleLoadingWindow:loadBasicRes()
end

function BattleLoadingWindow:changeProgress()
	local progress = self.modelProgress_ * 0.85

	self:updateBar(progress)
end

function BattleLoadingWindow:changeProgress2()
	local progress = self.preloadProgress_ * 0.1 + 85

	self:updateBar(progress)
end

function BattleLoadingWindow:changeProgress3()
	self:updateBar(100)
end

function BattleLoadingWindow:updateBar(progress)
	self:playAction(progress)
end

function BattleLoadingWindow:playAction(val)
	local bar = self.bar_

	if self.action then
		self.action:Pause()
		self.action:Kill(false)

		self.action = nil
	end

	local function setter(value)
		bar.value = value
	end

	local curVal = bar.value
	local newVal = tonumber(val) / 100
	local sequence1 = self:getSequence()

	sequence1:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), curVal, newVal, 1):SetEase(DG.Tweening.Ease.Linear))
	sequence1:AppendCallback(function ()
		if val == 100 then
			self.isProgressComplete_ = true

			if self.callback then
				self.callback()
			end
		end
	end)

	self.action = sequence1
end

function BattleLoadingWindow:playActionEnd(val, callback)
end

function BattleLoadingWindow:checkComplete()
	if self.battleComplete_ and not self.isOpenBattle_ then
		self.isOpenBattle_ = true
		self.data_.battle_sound = self.battleSound
		self.data_.sound_pos = self.selectSoundPos

		self:changeProgress3()
		xyd.WindowManager.get():openWindow("battle_window", self.data_)
		xyd.DownloadController.get():resumeDownload()
	end
end

function BattleLoadingWindow:setCallBack(callback)
	if self.isProgressComplete_ then
		callback()
	else
		self.callback = callback
	end
end

function BattleLoadingWindow:clearRes()
end

return BattleLoadingWindow
