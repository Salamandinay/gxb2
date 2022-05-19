local SkillResonateWindow = class("SkillResonateWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local testItem = class("testItem", import("app.components.CopyComponent"))
local SkillIcon = import("app.components.SkillIcon")
local ResItem = import("app.components.ResItem")

function SkillResonateWindow:ctor(name, params)
	SkillResonateWindow.super.ctor(self, name, params)

	self.partner = params.partner
	self.partnerTableID = self.partner:getTableID()
	self.isGuide = params.isGuide
end

function SkillResonateWindow:initWindow()
	self:getUIComponent()
	SkillResonateWindow.super.initWindow(self)
	self:registerEvent()
	self:initTop()
	self:layout()
end

function SkillResonateWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.helpBtn = self.groupAction:NodeByName("helpBtn").gameObject
	self.resetBtn = self.groupAction:NodeByName("resetBtn").gameObject
	self.skillGroupBg1 = self.groupAction:ComponentByName("skillGroupBg1", typeof(UISprite))
	self.skillShowTipsCon = self.skillGroupBg1:NodeByName("skillShowTipsCon").gameObject
	self.circleGroup = self.groupAction:NodeByName("circleGroup").gameObject
	self.bg2 = self.circleGroup:ComponentByName("bg2", typeof(UITexture))

	for i = 1, 4 do
		self["skillGroup" .. i] = self.circleGroup:ComponentByName("skillGroup" .. i, typeof(UISprite))
		self["skillItemCon" .. i] = self["skillGroup" .. i]:NodeByName("skillItemCon").gameObject
		self["upEffectCon" .. i] = self["skillItemCon" .. i]:ComponentByName("upEffectCon", typeof(UITexture))
	end

	self.infoGroup = self.groupAction:NodeByName("infoGroup").gameObject
	self.resonateLevLabel = self.infoGroup:ComponentByName("resonateLevLabel", typeof(UILabel))
	self.levCon = self.infoGroup:NodeByName("levCon").gameObject
	self.levNumBg = self.levCon:ComponentByName("levNumBg", typeof(UISprite))
	self.levNumCenterBg = self.levCon:ComponentByName("levNumCenterBg", typeof(UISprite))
	self.levNumLabel = self.levNumCenterBg:ComponentByName("levNumLabel", typeof(UILabel))
	self.attrCon = self.levCon:NodeByName("attrCon").gameObject

	for i = 1, 3 do
		self["attrCon" .. i] = self.attrCon:ComponentByName("attrCon" .. i, typeof(UISprite))
		self["attrNameLabel" .. i] = self["attrCon" .. i]:ComponentByName("attrNameLabel", typeof(UILabel))
		self["attrNumLabel" .. i] = self["attrCon" .. i]:ComponentByName("attrNumLabel", typeof(UILabel))
	end

	self.detailGroup = self.groupAction:NodeByName("detailGroup").gameObject
	self.detailBigBg = self.detailGroup:NodeByName("detailBigBg").gameObject
	self.name = self.detailGroup:ComponentByName("name", typeof(UILabel))
	self.detailUpCon = self.detailGroup:ComponentByName("detailUpCon", typeof(UISprite))
	self.detailUpConName = self.detailUpCon:ComponentByName("detailUpConName", typeof(UILabel))
	self.detailUpConScroller = self.detailUpCon:NodeByName("detailUpConScroller").gameObject
	self.detailUpConScrollerUIScrollView = self.detailUpCon:ComponentByName("detailUpConScroller", typeof(UIScrollView))
	self.detailUpConDesc = self.detailUpConScroller:ComponentByName("detailUpConDesc", typeof(UILabel))
	self.detailDownCon = self.detailGroup:ComponentByName("detailDownCon", typeof(UISprite))
	self.detailDownConName = self.detailDownCon:ComponentByName("detailDownConName", typeof(UILabel))
	self.detailDownConScroller = self.detailDownCon:NodeByName("detailDownConScroller").gameObject
	self.detailDownConScrollerUIScrollView = self.detailDownCon:ComponentByName("detailDownConScroller", typeof(UIScrollView))
	self.detailDownConDesc = self.detailDownConScroller:ComponentByName("detailDownConDesc", typeof(UILabel))
	self.detailDownConAttrAddLabel = self.detailDownCon:ComponentByName("detailDownConAttrAddLabel", typeof(UILabel))
	self.line = self.detailDownCon:ComponentByName("line", typeof(UIWidget))
	self.detailUpBtnCon = self.detailGroup:NodeByName("detailUpBtnCon").gameObject
	self.detailUpBtnConItems = self.detailUpBtnCon:NodeByName("detailUpBtnConItems").gameObject
	self.detailUpBtnConItemsUIWidget = self.detailUpBtnCon:ComponentByName("detailUpBtnConItems", typeof(UIWidget))

	for i = 1, 2 do
		self["items" .. i] = self.detailUpBtnConItems:NodeByName("items" .. i).gameObject
		self["itemsIcon" .. i] = self["items" .. i]:ComponentByName("icon", typeof(UISprite))
		self["itemsLabel" .. i] = self["items" .. i]:ComponentByName("label", typeof(UILabel))
	end

	self.detailUpBtn = self.detailUpBtnCon:NodeByName("detailUpBtn").gameObject
	self.detailUpBtnBoxCollider = self.detailUpBtnCon:ComponentByName("detailUpBtn", typeof(UnityEngine.BoxCollider))
	self.detailUpBtnLabel = self.detailUpBtn:ComponentByName("detailUpBtnLabel", typeof(UILabel))
	self.detailUpBtnConDesc = self.detailUpBtnCon:ComponentByName("detailUpBtnConDesc", typeof(UILabel))
	self.circleMaskCon = self.groupAction:NodeByName("circleMaskCon").gameObject
end

function SkillResonateWindow:registerEvent()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SKILL_RESONATE_HELP"
		})
	end)
	UIEventListener.Get(self.skillShowTipsCon.gameObject).onClick = handler(self, function ()
		if self.showSkillTipsIndex ~= nil then
			self["skill" .. self.showSkillTipsIndex]:showTips(false, self.skillShowTipsCon)
			self["skill" .. self.showSkillTipsIndex]:setSelected(false)

			self.showSkillTipsIndex = nil
		end
	end)
	UIEventListener.Get(self.detailBigBg.gameObject).onClick = handler(self, function ()
		self.detailGroup.gameObject:SetActive(false)
	end)
	UIEventListener.Get(self.detailUpBtn.gameObject).onClick = handler(self, function ()
		local level = self.exSkills[self.choiceUpSkillIndex]
		local cost = xyd.tables.skillResonateCostTable:getCost(level + 1)

		for i, item in pairs(cost) do
			if xyd.models.backpack:getItemNumByID(item[1]) < item[2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(item[1])))

				break
			end
		end

		local msg = messages_pb.upgrade_partner_ex_skill_req()
		msg.partner_id = self.partner:getPartnerID()
		msg.index = self.choiceUpSkillIndex

		xyd.Backend.get():request(xyd.mid.UPGRADE_PARTNER_EX_SKILL, msg)
	end)
	UIEventListener.Get(self.resetBtn).onClick = handler(self, function ()
		local flag = false

		for i = 1, 4 do
			if self.exSkills[i] > 0 then
				flag = true
			end
		end

		if not flag then
			xyd.showToast(__("SKILL_RESONATE_TEXT07"))

			return
		end

		local resetCost = xyd.tables.miscTable:split2Cost("skill_resonate_reset_cost", "value", "#")

		xyd.alertConfirm(__("SKILL_RESONATE_TEXT08"), function ()
			local selfNum = xyd.models.backpack:getItemNumByID(resetCost[1])

			if selfNum < resetCost[2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(resetCost[1])))
			else
				local msg = messages_pb.reset_partner_ex_skill_req()
				msg.partner_id = self.partner:getPartnerID()

				xyd.Backend.get():request(xyd.mid.RESET_PARTNER_EX_SKILL, msg)
			end
		end, __("SURE"), false, resetCost, __("GUILD_RESET"))
	end)

	self.eventProxy_:addEventListener(xyd.event.UPGRADE_PARTNER_EX_SKILL, handler(self, self.onUpgrade))
	self.eventProxy_:addEventListener(xyd.event.RESET_PARTNER_EX_SKILL, handler(self, self.onReset))
end

function SkillResonateWindow:layout()
	self.resonateLevLabel.text = __("SKILL_RESONATE_TEXT02")
	self.detailUpBtnLabel.text = __("LEV_UP")

	self:updateSkillShow()

	if self.isGuide then
		self.resetBtn.gameObject:SetActive(false)
	end
end

function SkillResonateWindow:initTop()
	if self.isGuide then
		return
	end

	self.windowTop = WindowTop.new(self.window_, self.name_, 600, false)
	local items = {
		{
			id = xyd.ItemID.SKILL_RESONATE_LIGHT_STONE
		},
		{
			id = xyd.ItemID.SKILL_RESONATE_DARK_STONE
		}
	}

	self.windowTop:setItem(items)
	self.windowTop:hideBg()
end

function SkillResonateWindow:onUpgrade(event)
	self.partner:updateExSkills(event.data.partner_info.ex_skills)

	self.exSkills = self.partner:getExSkills()
	local skills = self.partner:getExSkills()

	if skills and next(skills) ~= nil then
		self.exSkills = skills
	else
		self.exSkills = {
			0,
			0,
			0,
			0
		}
	end

	self.skillBaseList = self.partner:getSkillIDs()

	if self.exSkills[self.choiceUpSkillIndex] >= #xyd.tables.partnerExSkillTable:getExID(tonumber(self.skillBaseList[self.choiceUpSkillIndex])) then
		xyd.showToast(__("SKILL_RESONATE_TEXT06"))
		self.detailGroup:SetActive(false)
		self:updateSkillShow()
		self:showUpEffect()
	else
		self:updateSkillShow()
		self:updateUpLevelCon()
		self:showUpEffect()
	end
end

function SkillResonateWindow:onReset(event)
	xyd.showToast(__("EX_SKILL_RESET_SUCCESS"))
	self.partner:updateExSkills(event.data.partner_info.ex_skills)

	self.exSkills = self.partner:getExSkills()
	local skills = self.partner:getExSkills()

	if skills and next(skills) ~= nil then
		self.exSkills = skills
	else
		self.exSkills = {
			0,
			0,
			0,
			0
		}
	end

	self:updateSkillShow()
	self:updateUpLevelCon()
end

function SkillResonateWindow:updateSkillShow()
	local skills = self.partner:getExSkills()

	if skills and next(skills) ~= nil then
		self.exSkills = skills
	else
		self.exSkills = {
			0,
			0,
			0,
			0
		}
	end

	local allLevel = 0
	self.skillBaseList = self.partner:getSkillIDs()

	for index, level in pairs(self.exSkills) do
		if not self["skill" .. index] then
			self["skill" .. index] = SkillIcon.new(self["skillItemCon" .. index])
		end

		local skill = tonumber(self.skillBaseList[index])

		if level > 0 then
			skill = xyd.tables.partnerExSkillTable:getExID(skill)[level]
		end

		self["skill" .. index]:setInfo(skill, {
			showGroup = false,
			showLev = true,
			callback = function ()
				if self.isGuide then
					return
				end

				local function circleCallBack()
					if level >= #xyd.tables.partnerExSkillTable:getExID(tonumber(self.skillBaseList[index])) then
						self["skill" .. index]:showTips(true, self.skillShowTipsCon)
						self["skill" .. index]:setSelected(true)

						self.showSkillTipsIndex = index
					else
						self.choiceUpSkillIndex = index

						self.detailGroup:SetActive(true)
						self:updateUpLevelCon()
					end
				end

				self:circle(index, circleCallBack)
			end
		})

		self["skill" .. index]:getGameObject().transform.localEulerAngles = Vector3(0, 0, 0 + (index - 1) * 90)
		allLevel = allLevel + level
	end

	allLevel = allLevel + 4
	self.levNumLabel.text = tostring(allLevel)
	self.allLevel = allLevel
	local attrs = xyd.tables.skillResonateEffectTable:getEffectInfo(self.partnerTableID, allLevel)
	local effect = attrs.effect

	for i in pairs(effect) do
		self["attrCon" .. i].gameObject:SetActive(true)

		self["attrNameLabel" .. i].text = __(string.upper(effect[i][1]))
		local num = effect[i][2]
		num = string.format("%.1f", num * 100 / xyd.tables.dBuffTable:getFactor(effect[i][1]))
		self["attrNumLabel" .. i].text = tostring(num) .. "%"
	end

	for i = #effect + 1, 3 do
		self["attrCon" .. i].gameObject:SetActive(false)
	end
end

function SkillResonateWindow:updateUpLevelCon()
	if not self.detailGroup.activeSelf then
		return
	end

	self.skillBaseList = self.partner:getSkillIDs()
	local level = self.exSkills[self.choiceUpSkillIndex]
	local skillBaseId = tonumber(self.skillBaseList[self.choiceUpSkillIndex])
	local upSkillId = skillBaseId
	local downSkillId = skillBaseId

	if level > 0 then
		upSkillId = xyd.tables.partnerExSkillTable:getExID(skillBaseId)[level]
	end

	downSkillId = xyd.tables.partnerExSkillTable:getExID(skillBaseId)[level + 1]
	local skillLev = self.exSkills[self.choiceUpSkillIndex] + 1
	local nameStr = xyd.tables.skillTable:getName(upSkillId)
	local isPass = xyd.tables.skillTable:isPass(upSkillId)
	local str = nameStr .. " " .. __("SKILL_TEXT_ZHUDONG")

	if isPass and isPass == 1 then
		str = nameStr .. " " .. __("SKILL_TEXT_BEIDONG")
	end

	self.name.text = str
	self.detailUpConName.text = "Lv." .. skillLev
	self.detailDownConName.text = "Lv." .. skillLev + 1

	if xyd.Global.lang == "fr_fr" then
		self.detailUpConName.text = "Niv." .. skillLev
		self.detailDownConName.text = "Niv." .. skillLev + 1
	end

	self.detailUpConDesc.text = xyd.tables.skillTable:getDesc(upSkillId)
	self.detailDownConDesc.text = xyd.tables.partnerExSkillTextTable:getDesc(downSkillId, xyd.tables.partnerExSkillTable:getDescNum(skillBaseId, level + 1))

	self.detailUpConScrollerUIScrollView:ResetPosition()
	self.detailDownConScrollerUIScrollView:ResetPosition()

	local cost = xyd.tables.skillResonateCostTable:getCost(level + 1)

	for i = 1, 2 do
		self["items" .. i].gameObject:SetActive(false)
	end

	for i, item in pairs(cost) do
		self["items" .. i].gameObject:SetActive(true)
		xyd.setUISpriteAsync(self["itemsIcon" .. i], nil, xyd.tables.itemTable:getIcon(item[1]), function ()
			self["itemsIcon" .. i].gameObject:SetLocalScale(0.4, 0.4, 0.4)
		end, nil, true)

		self["itemsLabel" .. i].text = tostring(xyd.getRoughDisplayNumber(item[2]))

		if xyd.models.backpack:getItemNumByID(item[1]) < item[2] then
			self["itemsLabel" .. i].color = Color.New2(3422556671.0)
		else
			self["itemsLabel" .. i].color = Color.New2(960513791)
		end
	end

	if #cost == 1 then
		self.detailUpBtnConItemsUIWidget.width = 240

		self["items" .. 1].gameObject:X(-43)
	elseif #cost == 2 then
		self.detailUpBtnConItemsUIWidget.width = 354

		self["items" .. 1].gameObject:X(-149)
		self["items" .. 2].gameObject:X(18)
	end

	local nextEffect = xyd.tables.skillResonateEffectTable:getNextEffectInfo(self.partnerTableID, self.allLevel)

	if next(nextEffect) ~= nil then
		self.line.gameObject:Y(-50)

		self.line.alpha = 1
		local num = nextEffect.effect_show[2]
		num = string.format("%.1f", num * 100 / xyd.tables.dBuffTable:getFactor(nextEffect.effect_show[1]))
		self.detailDownConAttrAddLabel.text = __("SKILL_RESONATE_TEXT03", __(string.upper(nextEffect.effect_show[1])), "+" .. num .. "%")
	else
		self.detailDownConAttrAddLabel.text = ""

		self.line.gameObject:Y(-81)

		self.line.alpha = 0.011
	end

	self:waitForFrame(2, function ()
		self.detailDownConScrollerUIScrollView:ResetPosition()
	end)
	self:checkIsCanUpWithOtherSkill()
end

function SkillResonateWindow:checkIsCanUpWithOtherSkill()
	local upCheckArr = xyd.tables.miscTable:split2num("skill_resonate_level_limit", "value", "|")
	local level = self.exSkills[self.choiceUpSkillIndex] + 1
	local checkLev = upCheckArr[level] + 1
	local isCanUp = true

	for index, lev in pairs(self.exSkills) do
		if index ~= self.choiceUpSkillIndex and checkLev > lev + 1 then
			isCanUp = false

			break
		end
	end

	if isCanUp then
		self.detailUpBtnConDesc.text = ""

		xyd.applyChildrenOrigin(self.detailUpBtn.gameObject)

		self.detailUpBtnBoxCollider.enabled = true
	else
		self.detailUpBtnConDesc.text = __("SKILL_RESONATE_TEXT05", checkLev)

		xyd.applyChildrenGrey(self.detailUpBtn.gameObject)

		self.detailUpBtnBoxCollider.enabled = false
	end
end

function SkillResonateWindow:circle(index, callback)
	self.circleMaskCon:SetActive(true)

	if not self.circlePosIndex then
		self.circlePosIndex = {
			1,
			2,
			3,
			4
		}
	end

	local posIndex = xyd.arrayIndexOf(self.circlePosIndex, index)
	local changeNum = 0
	local newPosArr = {}

	if posIndex == 1 then
		changeNum = 0
	elseif posIndex == 2 then
		changeNum = 90
		newPosArr[1] = self.circlePosIndex[2]
		newPosArr[2] = self.circlePosIndex[3]
		newPosArr[3] = self.circlePosIndex[4]
		newPosArr[4] = self.circlePosIndex[1]
	elseif posIndex == 3 then
		changeNum = 180
		newPosArr[1] = self.circlePosIndex[3]
		newPosArr[2] = self.circlePosIndex[4]
		newPosArr[3] = self.circlePosIndex[1]
		newPosArr[4] = self.circlePosIndex[2]
	elseif posIndex == 4 then
		changeNum = -90
		newPosArr[1] = self.circlePosIndex[4]
		newPosArr[2] = self.circlePosIndex[1]
		newPosArr[3] = self.circlePosIndex[2]
		newPosArr[4] = self.circlePosIndex[3]
	end

	if changeNum == 0 then
		callback()
		self.circleMaskCon:SetActive(false)

		return
	end

	local nowZ = self.circleGroup.gameObject.transform.localEulerAngles.z
	local iconNowZAarr = {}

	for i = 1, 4 do
		iconNowZAarr[i] = self["skillItemCon" .. i].gameObject.transform.localEulerAngles.z
	end

	local sequence = self:getSequence()

	local function setter(value)
		self.circleGroup.gameObject.transform.localEulerAngles = Vector3(0, 0, nowZ + changeNum * value)

		for i = 1, 4 do
			self["skillItemCon" .. i].gameObject.transform.localEulerAngles = Vector3(0, 0, iconNowZAarr[i] - changeNum * value)
		end
	end

	sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.3):SetEase(DG.Tweening.Ease.Linear))
	sequence:AppendCallback(function ()
		sequence:Kill(false)

		self.circlePosIndex = newPosArr

		callback()
		self.circleMaskCon:SetActive(false)
	end)
end

function SkillResonateWindow:showUpEffect()
	if not self["upEffect" .. self.choiceUpSkillIndex] then
		self["upEffect" .. self.choiceUpSkillIndex] = xyd.Spine.new(self["upEffectCon" .. self.choiceUpSkillIndex].gameObject)

		self["upEffect" .. self.choiceUpSkillIndex]:setInfo("exskill_lvlup", function ()
			self["upEffect" .. self.choiceUpSkillIndex]:play("texiao01", 1, 1)
		end)
	else
		self["upEffect" .. self.choiceUpSkillIndex]:play("texiao01", 1, 1)
	end
end

return SkillResonateWindow
