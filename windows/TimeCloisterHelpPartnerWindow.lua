local TimeCloisterHelpPartnerWindow = class("TimeCloisterHelpPartnerWindow", import(".BaseWindow"))
local Partner = import("app.models.Partner")
local AttrLabel = import("app.components.AttrLabel")
local SkillIcon = import("app.components.SkillIcon")
local CommonStaticList = import("app.common.ui.CommonStaticList")
local SpecialSkillItem = class("SpecialSkillItem", import("app.common.ui.CommonStaticListItem"))
local timeCloister = xyd.models.timeCloisterModel
local tecTable = xyd.tables.timeCloisterTecTable
local tecTextTable = xyd.tables.timeCloisterTecTextTable

function TimeCloisterHelpPartnerWindow:ctor(name, params)
	TimeCloisterHelpPartnerWindow.super.ctor(self, name, params)

	self.group = params.group
	self.cloister = params.cloister
	self.partnerTecLev = params.partnerTecLev
	self.tecId = params.tecId
	self.specialSkillInfos = params.specialSkillInfos
end

function TimeCloisterHelpPartnerWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function TimeCloisterHelpPartnerWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.infoCon = self.upCon:NodeByName("infoCon").gameObject
	self.nameText = self.infoCon:ComponentByName("nameText", typeof(UILabel))
	self.levText = self.infoCon:ComponentByName("levText", typeof(UILabel))
	self.levelCon = self.infoCon:NodeByName("levelCon").gameObject
	self.labelLevUp = self.levelCon:ComponentByName("labelLevUp", typeof(UILabel))
	self.powerCon = self.infoCon:NodeByName("powerCon").gameObject
	self.content1BattleIcon = self.powerCon:ComponentByName("content1BattleIcon", typeof(UISprite))
	self.labelBattlePoint = self.powerCon:ComponentByName("labelBattlePoint", typeof(UILabel))
	self.jobCon = self.infoCon:NodeByName("jobCon").gameObject
	self.jobIcon = self.jobCon:ComponentByName("jobIcon", typeof(UISprite))
	self.labelJob = self.jobCon:ComponentByName("labelJob", typeof(UILabel))
	self.groupLevupCost = self.infoCon:NodeByName("groupLevupCost").gameObject
	self.levupBg = self.groupLevupCost:ComponentByName("levupBg", typeof(UISprite))
	self.costIcon = self.groupLevupCost:ComponentByName("costIcon", typeof(UISprite))
	self.labelGoldCost = self.groupLevupCost:ComponentByName("labelGoldCost", typeof(UILabel))
	self.btnPartnerLevUp = self.infoCon:NodeByName("btnLevUp").gameObject
	self.btnLevUpRedPoint = self.btnPartnerLevUp:ComponentByName("redPoint", typeof(UISprite))
	self.attr = self.infoCon:NodeByName("attr").gameObject
	self.labelHp = self.attr:ComponentByName("labelHp", typeof(UILabel))
	self.labelAtk = self.attr:ComponentByName("labelAtk", typeof(UILabel))
	self.labelDef = self.attr:ComponentByName("labelDef", typeof(UILabel))
	self.labelSpd = self.attr:ComponentByName("labelSpd", typeof(UILabel))
	self.attrDetail = self.attr:ComponentByName("attrDetail", typeof(UISprite))
	self.e_Image2 = self.infoCon:ComponentByName("e_Image2", typeof(UISprite))
	self.partnerCon = self.infoCon:NodeByName("partnerCon").gameObject
	self.groupAllAttrShow = self.infoCon:NodeByName("groupAllAttrShow").gameObject
	self.attrClickBg = self.groupAllAttrShow:ComponentByName("attrClickBg", typeof(UISprite))
	self.e_Group = self.groupAllAttrShow:NodeByName("e:Group").gameObject
	self.groupAllAttr = self.e_Group:NodeByName("groupAllAttr").gameObject
	self.infoMaxGroup = self.upCon:NodeByName("infoMaxGroup").gameObject
	self.infoImgMaxLev = self.infoMaxGroup:ComponentByName("infoImgMaxLev", typeof(UISprite))
	self.infoTextMaxLev = self.infoMaxGroup:ComponentByName("infoTextMaxLev", typeof(UILabel))
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.bg1_ = self.downCon:ComponentByName("bg1_", typeof(UISprite))
	self.commonSkillCon = self.downCon:NodeByName("commonSkillCon").gameObject
	self.commonSkillConUILayout = self.downCon:ComponentByName("commonSkillCon", typeof(UILayout))
	self.skillMask = self.downCon:ComponentByName("skillMask", typeof(UISprite)).gameObject
	self.skillDesc = self.downCon:NodeByName("skillDesc").gameObject
	self.downNameLabel = self.downCon:ComponentByName("downNameLabel", typeof(UILabel))
	self.specialSkillCon = self.downCon:NodeByName("specialSkillCon").gameObject
	self.specialSkillConUILayout = self.downCon:ComponentByName("specialSkillCon", typeof(UILayout))
	self.specialItem = self.downCon:NodeByName("specialItem").gameObject
	self.descLabel1 = self.downCon:ComponentByName("descLabel1", typeof(UILabel))
	self.descLabel2 = self.downCon:ComponentByName("descLabel2", typeof(UILabel))
	self.resRoot = self.downCon:NodeByName("resRoot").gameObject
	self.helpBtn = self.downCon:NodeByName("helpBtn").gameObject
	self.levelUpGroup = self.downCon:NodeByName("levelUpGroup").gameObject
	self.nameLabel = self.levelUpGroup:ComponentByName("nameLabel", typeof(UILabel))
	self.numLabel = self.levelUpGroup:ComponentByName("numLabel", typeof(UILabel))
	self.levelUpLabel = self.levelUpGroup:ComponentByName("levelUpLabel", typeof(UILabel))
	self.textMaxLev = self.levelUpGroup:ComponentByName("maxGroup/textMaxLev", typeof(UILabel))
	self.groupCost = self.levelUpGroup:NodeByName("groupCost").gameObject
	self.costImg1 = self.groupCost:ComponentByName("costImg1", typeof(UISprite))
	self.labelCost1 = self.groupCost:ComponentByName("labelCost1", typeof(UILabel))
	self.btnLevUp = self.levelUpGroup:NodeByName("btnLevUp").gameObject
	self.skillDescLabel = self.levelUpGroup:ComponentByName("scroller_/descLabel", typeof(UILabel))
	self.groupPreview = self.levelUpGroup:NodeByName("groupPreview").gameObject
	self.previewLabel = self.groupPreview:ComponentByName("previewLabel", typeof(UILabel))
	self.btnPreview = self.groupPreview:NodeByName("btnPreview").gameObject
	self.mask = self.downCon:NodeByName("mask").gameObject
	self.upEffectCon = self.groupAction:ComponentByName("upEffectCon", typeof(UITexture))
end

function TimeCloisterHelpPartnerWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.UPGRADE_SKILL, handler(self, self.onUpgradeSkill))

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.attrDetail.gameObject).onClick = handler(self, function ()
		self:updateGroupAllAttr()
		self.groupAllAttrShow:SetActive(true)
	end)
	UIEventListener.Get(self.attrClickBg.gameObject).onClick = handler(self, function ()
		self.groupAllAttrShow:SetActive(false)
	end)

	UIEventListener.Get(self.mask).onClick = function ()
		self.levelUpGroup:SetActive(false)
		self.mask:SetActive(false)
	end

	UIEventListener.Get(self.btnPartnerLevUp.gameObject).onClick = function ()
		local cost = self:getUpCost()[1]

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
		else
			timeCloister:reqUpgradeSkill(self.cloister, self.tecId)

			self.isUpgradeSkill = true
		end
	end

	UIEventListener.Get(self.btnLevUp).onClick = function ()
		local cost = tecTable:getUpgradeCost(self.curSkillID)[self.info[self.curSkillID].curLv + 1]

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
		else
			timeCloister:reqUpgradeSkill(self.cloister, self.curSkillID)

			self.isUpgradeSkill = true
		end
	end

	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "TIME_CLOISTER_HELP05"
		})
	end)

	UIEventListener.Get(self.btnPreview.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("time_cloister_tech_levup_preview_window", {
			skill_id = self.curSkillID,
			curLv = self.info[self.curSkillID].curLv,
			maxLv = self.info[self.curSkillID].maxLv
		})
	end
end

function TimeCloisterHelpPartnerWindow:layout()
	self.info = timeCloister:getTechInfoByCloister(self.cloister)[self.group]
	self.resItem = require("app.components.ResItem").new(self.resRoot)

	self.resItem:setInfo({
		tableId = xyd.ItemID.TIME_CLOISTR_DREAM_POINT
	})

	self.descLabel1.text = __("TIME_CLOISTER_TEXT65")
	self.descLabel2.text = __("TIME_CLOISTER_TEXT66")
	self.levelUpLabel.text = __("TIME_CLOISTER_TEXT41")
	self.previewLabel.text = __("TIME_CLOISTER_TEXT42")
	self.textMaxLev.text = __("MAX_LEV")
	self.infoTextMaxLev.text = __("MAX_LEV")
	self.downNameLabel.text = __("TIME_CLOISTER_TEXT85")
	self.groupAllAttrLables = {}
	self.skillIcons = {}
	self.gradeItems = {}
	self.labelLevUp.text = __("LEV_UP")
	local needTableId = xyd.tables.timeCloisterPartnerTable:checkLeveltoId(self.partnerTecLev)
	local parnertId = xyd.tables.timeCloisterPartnerTable:getTableId(needTableId)
	self.upCost = xyd.tables.timeCloisterTecTable:getUpgradeCostSpecial(self.tecId)

	self:initPartnerEffect(parnertId)
	self:update(needTableId)
end

function TimeCloisterHelpPartnerWindow:update(needTableId)
	needTableId = needTableId or xyd.tables.timeCloisterPartnerTable:checkLeveltoId(self.partnerTecLev)

	self:updatePartnerUpRenPoint()
	self:updateAttr(needTableId)
	self:updateSkill()
	self:updateSpecialSkill()
end

function TimeCloisterHelpPartnerWindow:updatePartnerUpRenPoint()
	local cost = self:getUpCost()[1]

	if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
		self.btnLevUpRedPoint.gameObject:SetActive(true)

		self.labelGoldCost.color = Color.New2(960513791)
	else
		self.btnLevUpRedPoint.gameObject:SetActive(false)

		self.labelGoldCost.color = Color.New2(3422556671.0)
	end
end

function TimeCloisterHelpPartnerWindow:initPartnerEffect(parnertId)
	local modelID = xyd.tables.partnerTable:getModelID(parnertId)
	local effectName = xyd.tables.modelTable:getModelName(modelID)
	local effectScale = xyd.tables.modelTable:getScale(modelID)
	local effectScale_x_ratio = 1
	self.partnerEffect = xyd.Spine.new(self.partnerCon.gameObject)

	self.partnerEffect:setInfo(effectName, function ()
		self.partnerEffect:SetLocalScale(effectScale * effectScale_x_ratio, effectScale, effectScale)
		self.partnerEffect:play("idle", 0)
	end, true)
end

function TimeCloisterHelpPartnerWindow:updateAttr(needTableId)
	local partner = Partner.new()
	local parnertId = xyd.tables.timeCloisterPartnerTable:getTableId(needTableId)
	local lev = xyd.tables.timeCloisterPartnerTable:getLevel(needTableId)
	local showLev = self.partnerTecLev

	if self.partnerTecLev == 0 then
		showLev = 0
	end

	partner:populate({
		isHeroBook = true,
		table_id = parnertId,
		lev = showLev,
		awake = xyd.tables.timeCloisterPartnerTable:getAwake(needTableId),
		grade = xyd.tables.timeCloisterPartnerTable:getGrade(needTableId)
	})

	self.partner = partner
	local attrs = partner:getBattleAttrs()
	self.labelHp.text = ": " .. tostring(attrs.hp)
	self.labelAtk.text = ": " .. tostring(attrs.atk)
	self.labelDef.text = ": " .. tostring(attrs.arm)
	self.labelSpd.text = ": " .. tostring(attrs.spd)
	self.labelBattlePoint.text = partner:getPower()

	if xyd.Global.lang == "fr_fr" then
		self.levText.text = "Niv：" .. showLev
	else
		self.levText.text = "Lv：" .. showLev
	end

	local job = xyd.tables.partnerTable:getJob(parnertId)

	xyd.setUISpriteAsync(self.jobIcon, nil, "job_icon" .. job)

	self.labelJob.text = xyd.tables.jobTextTable:getName(job)
	self.nameText.text = xyd.tables.partnerTable:getName(parnertId)
	local cost = self:getUpCost()

	xyd.setUISpriteAsync(self.costIcon, nil, xyd.tables.itemTable:getIcon(cost[1][1]))

	self.labelGoldCost.text = tostring(cost[1][2])
end

function TimeCloisterHelpPartnerWindow:getUpCost()
	if self.partnerTecLev == self.upCost[#self.upCost][2][1] then
		self.btnPartnerLevUp.gameObject:SetActive(false)
		self.groupLevupCost.gameObject:SetActive(false)

		return {
			{
				0,
				1
			}
		}
	end

	for i in pairs(self.upCost) do
		if self.partnerTecLev < self.upCost[i][2][1] then
			return self.upCost[i]
		end
	end
end

function TimeCloisterHelpPartnerWindow:updateGroupAllAttr()
	local attrs = self.partner:getBattleAttrs()
	local bt = xyd.tables.dBuffTable
	local i = 0

	for _, key in pairs(xyd.AttrSuffix) do
		i = i + 1
		local value = attrs[key] or 0

		if bt:isShowPercent(key) then
			local factor = bt:getFactor(key)
			value = string.format("%.1f", value * 100 / bt:getFactor(key))
			value = tostring(value) .. "%"
		end

		local params = {
			string.upper(key),
			value
		}
		local label = self.groupAllAttrLables[i]

		if label == nil then
			label = AttrLabel.new(self.groupAllAttr, "large", params, attrs)
			self.groupAllAttrLables[i] = label
		else
			label:setValue(params, attrs)
		end

		if xyd.Global.lang == "de_de" then
			label.labelName.fontSize = 15
		end
	end
end

function TimeCloisterHelpPartnerWindow:updateSkill()
	local awake = self.partner:getAwake()
	local skill_ids = nil

	if awake > 0 then
		skill_ids = self.partner:getAwakeSkill(awake)
	else
		skill_ids = self.partner:getSkillIDs()
	end

	local grade = self.partner:getGrade()
	local skills = self.partner:getExSkills()
	local exSkills = nil

	if skills and next(skills) ~= nil then
		exSkills = skills
	else
		exSkills = {
			0,
			0,
			0,
			0
		}
	end

	for key = 1, #skill_ids do
		local icon = nil

		if tonumber(key) > #self.skillIcons then
			icon = SkillIcon.new(self.commonSkillCon)
			self.skillIcons[key] = icon

			UIEventListener.Get(icon.go).onSelect = function (go, isSelect)
				if isSelect == false then
					self:clearSkillTips()
				end
			end
		else
			icon = self.skillIcons[key]
		end

		icon.go:SetActive(true)

		local level = exSkills[key]

		if level and level > 0 then
			skill_ids[key] = xyd.tables.partnerExSkillTable:getExID(skill_ids[key])[level]
		end

		if key == 1 then
			icon:setInfo(skill_ids[key], {
				unlocked = true,
				showGroup = self.skillDesc,
				callback = function ()
					self:handleSkillTips(icon)
				end
			})
		else
			local needGrade = self.partner:getPasTier(key - 1)

			if needGrade ~= nil and grade < needGrade then
				icon:setInfo(skill_ids[key], {
					unlocked = false,
					unlockGrade = needGrade,
					showGroup = self.skillDesc,
					callback = function ()
						self:handleSkillTips(icon)
					end
				})
			else
				icon:setInfo(skill_ids[key], {
					unlocked = true,
					showGroup = self.skillDesc,
					callback = function ()
						self:handleSkillTips(icon)
					end
				})
			end
		end
	end

	for i = #skill_ids + 1, #self.skillIcons do
		local icon = self.skillIcons[i]

		icon.go:SetActive(false)
	end

	self.commonSkillConUILayout:Reposition()
end

function TimeCloisterHelpPartnerWindow:handleSkillTips(icon)
	if self.showSkillTips then
		return
	end

	self.showSkillTips = true
	self.showSkillIcon = icon

	icon:showTips(true, icon.showGroup, true)
	self.skillMask:SetActive(true)
end

function TimeCloisterHelpPartnerWindow:clearSkillTips()
	if self.showSkillIcon then
		self.showSkillIcon:showTips(false, self.showSkillIcon.showGroup)
	end

	self.showSkillTips = false

	self.skillMask:SetActive(false)
end

function TimeCloisterHelpPartnerWindow:updateSpecialSkill()
	local params = {
		cloneItem = self.specialItem,
		parentClass = self,
		itemClass = SpecialSkillItem
	}

	if not self.staticList then
		self.staticList = CommonStaticList.new(self.specialSkillCon, params)
	end

	self.staticList:setInfos(self.specialSkillInfos, {
		rePosition = true
	})
	self:updateDownPos()
end

function TimeCloisterHelpPartnerWindow:updateDownPos()
	local isAllMax = true

	for i in pairs(self.specialSkillInfos) do
		if self.specialSkillInfos[i].data.curLv < self.specialSkillInfos[i].data.maxLv then
			isAllMax = false

			break
		end
	end

	if isAllMax then
		self.specialSkillCon.gameObject:Y(-146)
	end
end

function TimeCloisterHelpPartnerWindow:updateLevelUpGroup()
	if self.handTipsID == self.curSkillID then
		self.handNode:SetActive(false)
	end

	local info = self.info[self.curSkillID]
	self.nameLabel.text = tecTextTable:getName(self.curSkillID)

	if xyd.Global.lang == "fr_fr" then
		self.numLabel.text = "Niv." .. info.curLv .. "/" .. info.maxLv
	else
		self.numLabel.text = "Lv: " .. info.curLv .. "/" .. info.maxLv
	end

	local num = tecTable:getNum(self.curSkillID)
	local nums = ""
	local descText = ""

	if tecTable:getType(self.curSkillID) == 3 then
		nums = num[math.min(info.curLv + 1, info.maxLv)] or ""
	else
		nums = num[math.max(info.curLv, 1)] or ""
	end

	descText = xyd.stringFormat(tecTextTable:getDesc(self.curSkillID), nums)
	local cost = tecTable:getUpgradeCost(self.curSkillID)[math.min(info.curLv + 1, info.maxLv)]

	xyd.setUISpriteAsync(self.costImg1, nil, xyd.tables.itemTable:getIcon(cost[1]), nil)

	self.labelCost1.text = cost[2]

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		self.labelCost1.color = Color.New2(3422556671.0)
	else
		self.labelCost1.color = Color.New2(960513791)
	end

	local isLock = false

	for i in pairs(info.pre_id) do
		if self.info[info.pre_id[i]].curLv < xyd.tables.timeCloisterTecTable:getPreLv(self.curSkillID)[i] then
			isLock = true

			break
		end
	end

	if isLock then
		self.groupCost:SetActive(true)
		self.btnLevUp:SetActive(true)
		xyd.applyGrey(self.btnLevUp:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnLevUp, false)

		local unLockType = tecTable:getUnlockType(self.curSkillID)

		if unLockType == xyd.TimeCloisterUnLockType.EVENT_NUM then
			local sum_events = timeCloister:getSumEvents()
			local unLockNum = tecTable:getUnlockNum(self.curSkillID)
			descText = "[c][cc0011]" .. xyd.stringFormat(tecTextTable:getUnlockDesc(self.curSkillID), sum_events[tostring(unLockNum[1])] or 0) .. "[-][/c]\n\n" .. descText
		elseif tecTextTable:getUnlockDesc(self.curSkillID) ~= "" then
			descText = "[c][cc0011]" .. tecTextTable:getUnlockDesc(self.curSkillID) .. "[-][/c]\n\n" .. descText
		end
	elseif info.curLv < info.maxLv then
		self.groupCost:SetActive(true)
		self.btnLevUp:SetActive(true)
		xyd.applyOrigin(self.btnLevUp:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnLevUp, true)
	else
		self.groupCost:SetActive(false)
		self.btnLevUp:SetActive(false)
	end

	self.skillDescLabel.text = descText

	if info.maxLv > 1 then
		self.groupPreview:SetActive(true)
	else
		self.groupPreview:SetActive(false)
	end
end

function TimeCloisterHelpPartnerWindow:onTouchSpecial(id)
	if self.mask.activeSelf then
		self.levelUpGroup:SetActive(false)
		self.mask:SetActive(false)

		self.curSkillID = 0
	else
		self.curSkillID = id

		self:updateLevelUpGroup()
		self.levelUpGroup:SetActive(true)
		self.mask:SetActive(true)
	end
end

function TimeCloisterHelpPartnerWindow:willClose()
	TimeCloisterHelpPartnerWindow.super.willClose(self)

	if self.isUpgradeSkill then
		timeCloister:reqCardInfo(true)
	end

	local time_cloister_tech_wd = xyd.WindowManager.get():getWindow("time_cloister_tech_window")

	if time_cloister_tech_wd then
		time_cloister_tech_wd:setLabelActive(true)
	end
end

function TimeCloisterHelpPartnerWindow:onUpgradeSkill(event)
	local skill_id = event.data.skill_id
	self.info = timeCloister:getTechInfoByCloister(self.cloister)[self.group]

	for i in pairs(self.specialSkillInfos) do
		if self.specialSkillInfos[i].id == skill_id then
			self.specialSkillInfos[i].data.curLv = self.info[self.specialSkillInfos[i].id].curLv

			break
		end
	end

	if skill_id == self.tecId then
		self.partnerTecLev = self.info[self.tecId].curLv

		self:update()

		if not self.levUpEffect then
			self.levUpEffect = xyd.Spine.new(self.upEffectCon.gameObject)

			self.levUpEffect:setInfo("shenji", function ()
				self.levUpEffect:play("texiao", 1, 1)
			end)
		elseif self.levUpEffect then
			self.levUpEffect:play("texiao", 1, 1)
		end
	end

	self:updatePartnerUpRenPoint()
	self.staticList:setInfos(self.specialSkillInfos, {})

	if self.levelUpGroup.activeSelf and self.curSkillID == skill_id then
		self:updateLevelUpGroup()
	end

	self:updateDownPos()
	self.resItem:updateNum()
end

function SpecialSkillItem:getUIComponent()
	self.skillCon = self.go:ComponentByName("skillCon", typeof(UITexture))
	self.skillConBg = self.go:ComponentByName("skillConBg", typeof(UISprite))
	self.levText = self.go:ComponentByName("levText", typeof(UILabel))
	self.btnItemLevUp = self.go:NodeByName("btnLevUp").gameObject
	self.redPoint = self.btnItemLevUp:ComponentByName("redPoint", typeof(UISprite)).gameObject
end

function SpecialSkillItem:initUI()
	SpecialSkillItem.super.initUI(self)

	UIEventListener.Get(self.skillConBg.gameObject).onClick = handler(self, function ()
		self.parent:onTouchSpecial(self.info.id)
	end)
	UIEventListener.Get(self.btnItemLevUp.gameObject).onClick = handler(self, function ()
		self.parent:onTouchSpecial(self.info.id)
	end)
end

function SpecialSkillItem:update(info)
	self.info = info
	local img = tecTable:getImg(info.id)

	xyd.setUITextureByNameAsync(self.skillCon, img, false)

	self.levText.text = "LV." .. info.data.curLv .. "/" .. info.data.maxLv

	if xyd.Global.lang == "fr_fr" then
		self.levText.text = "Niv." .. info.data.curLv .. "/" .. info.data.maxLv
	end

	if tonumber(info.data.curLv) <= 0 then
		xyd.setUISpriteAsync(self.skillConBg, nil, "skill_icon_lock_bg")
	else
		xyd.setUISpriteAsync(self.skillConBg, nil, "skill_icon_bg")
	end

	if info.data.maxLv <= info.data.curLv then
		self.redPoint.gameObject:SetActive(false)
		self.btnItemLevUp.gameObject:SetActive(false)
	end

	if self.parent.info[info.data.pre_id[1]].curLv <= 0 then
		xyd.applyGrey(self.btnItemLevUp:GetComponent(typeof(UISprite)))
		self.redPoint.gameObject:SetActive(false)
	else
		xyd.applyOrigin(self.btnItemLevUp:GetComponent(typeof(UISprite)))

		local isLock = false

		for i in pairs(info.data.pre_id) do
			if self.parent.info[info.data.pre_id[i]].curLv < xyd.tables.timeCloisterTecTable:getPreLv(info.id)[i] then
				isLock = true

				break
			end
		end

		if isLock then
			self.redPoint.gameObject:SetActive(false)
		elseif info.data.curLv < info.data.maxLv then
			local cost = xyd.tables.timeCloisterTecTable:getUpgradeCost(info.id)[tonumber(info.data.curLv) + 1]

			if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
				self.redPoint.gameObject:SetActive(true)
			else
				self.redPoint.gameObject:SetActive(false)
			end
		end
	end
end

return TimeCloisterHelpPartnerWindow
