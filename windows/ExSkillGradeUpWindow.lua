local ExSkillGradeUpWindow = class("ExSkillGradeUpWindow", import(".BaseWindow"))
local SkillIcon = import("app.components.SkillIcon")

function ExSkillGradeUpWindow:ctor(name, params)
	ExSkillGradeUpWindow.super.ctor(self, name, params)

	self.partner = params.partner
	self.skillIcons = {}
	local skills = self.partner:getExSkills()
	self.exSkills = {}

	if skills == nil then
		self.exSkills = {
			0,
			0,
			0,
			0
		}
	else
		for i = 1, 4 do
			if skills[i] then
				table.insert(self.exSkills, skills[i])
			else
				table.insert(self.exSkills, 0)
			end
		end
	end

	self.chosenIndex = 1
end

function ExSkillGradeUpWindow:initWindow()
	self:getComponent()
	ExSkillGradeUpWindow.super.initWindow(self)
	self:initSkillItem()
	self:layout()
	self:chooseSkill(1)
	self:register()
end

function ExSkillGradeUpWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.helpBtn = winTrans:NodeByName("helpBtn").gameObject
	self.title = winTrans:ComponentByName("title", typeof(UILabel))
	self.groupTop = winTrans:NodeByName("groupTop").gameObject
	self.resItem1 = self.groupTop:NodeByName("res_item1").gameObject
	self.resItem2 = self.groupTop:NodeByName("res_item2").gameObject
	self.resIcon1 = self.resItem1:ComponentByName("res_icon", typeof(UISprite))
	self.resIcon2 = self.resItem2:ComponentByName("res_icon", typeof(UISprite))
	self.resLabel1 = self.resItem1:ComponentByName("res_num_label", typeof(UILabel))
	self.resLabel2 = self.resItem2:ComponentByName("res_num_label", typeof(UILabel))
	self.resetBtn = self.groupTop:NodeByName("resetBtn").gameObject
	self.descGroup = winTrans:NodeByName("descGroup").gameObject

	for i = 1, 4 do
		self["skillNode" .. i] = self.descGroup:NodeByName("skillIcon (" .. i .. ")").gameObject
	end

	self.descScroll = self.descGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.skillName = self.descGroup:ComponentByName("skillName", typeof(UILabel))
	self.skillDesc = self.descGroup:ComponentByName("scrollView/skillDesc", typeof(UILabel))
	self.spineNode = self.descGroup:NodeByName("spineNode").gameObject
	self.previewGroup = winTrans:NodeByName("previewGroup").gameObject
	self.previewTitle = self.previewGroup:ComponentByName("title", typeof(UILabel))
	self.previewBtn = self.previewGroup:NodeByName("btn").gameObject
	self.previewSkillGroup = self.previewGroup:NodeByName("skillGroup").gameObject
	self.previewSkillNode = self.previewSkillGroup:NodeByName("skillIcon").gameObject
	self.previewScroll = self.previewSkillGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.previewName = self.previewSkillGroup:ComponentByName("skillName", typeof(UILabel))
	self.previewDesc = self.previewSkillGroup:ComponentByName("scrollView/skillDesc", typeof(UILabel))
	self.previewMaxLabel = self.previewGroup:ComponentByName("label", typeof(UILabel))
	self.costResGroup = self.previewGroup:NodeByName("costResGroup").gameObject
	self.priceIcon1 = self.costResGroup:ComponentByName("icon1", typeof(UISprite))
	self.priceIcon2 = self.costResGroup:ComponentByName("icon2", typeof(UISprite))
	self.priceLabel1 = self.costResGroup:ComponentByName("label1", typeof(UILabel))
	self.priceLabel2 = self.costResGroup:ComponentByName("label2", typeof(UILabel))
	self.groupUp = winTrans:NodeByName("groupUp").gameObject
	self.activeBtn = self.groupUp:NodeByName("activeBtn").gameObject
	self.activeBtnLabel = self.activeBtn:ComponentByName("label", typeof(UILabel))
end

function ExSkillGradeUpWindow:layout()
	local path = tostring(xyd.tables.itemTable:getIcon(xyd.ItemID.NORMAL_EXERCISES))

	xyd.setUISpriteAsync(self.resIcon1, nil, path)

	local path = tostring(xyd.tables.itemTable:getIcon(xyd.ItemID.ADVANCED_EXERCISES))

	xyd.setUISpriteAsync(self.resIcon2, nil, path)

	self.resLabel1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.NORMAL_EXERCISES)
	self.resLabel2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ADVANCED_EXERCISES)
	self.title.text = __("EX_SKILL")
	self.activeBtnLabel.text = __("LEV_UP")
	self.previewMaxLabel.text = __("EX_SKILL_GRADE_UP_FULL")
	self.previewTitle.text = __("EX_SKILL_GRADE_UP_PREVIEW")
end

function ExSkillGradeUpWindow:initSkillItem()
	local awake = self.partner:getAwake()

	if awake > 0 then
		self.skillList = self.partner:getAwakeSkill(awake)
	else
		self.skillList = self.partner:getSkillIDs()
	end

	self.skillIcons = {}

	for i = 1, 4 do
		local level = self.exSkills[i]
		local skill = tonumber(self.skillList[i])

		if level > 0 then
			skill = xyd.tables.partnerExSkillTable:getExID(skill)[level]
		end

		NGUITools.DestroyChildren(self["skillNode" .. i].transform)

		local icon = SkillIcon.new(self["skillNode" .. i])

		icon:setInfo(skill, {
			notShowEx = true,
			showLev = true,
			showGroup = self.skillDesc,
			callback = function ()
				if self.chosenIndex ~= i then
					self:chooseSkill(i)
				end
			end
		})

		if i == self.chosenIndex then
			icon:setSelected(true)
		end

		table.insert(self.skillIcons, icon)
	end
end

function ExSkillGradeUpWindow:initPreview()
	NGUITools.DestroyChildren(self.previewSkillNode.transform)

	local level = self.exSkills[self.chosenIndex]

	if level and level >= 5 then
		self.previewSkillGroup:SetActive(false)
		self.previewMaxLabel:SetActive(true)
		self.activeBtn:SetActive(false)
		self.costResGroup:SetActive(false)

		return
	end

	self.previewSkillGroup:SetActive(true)
	self.previewMaxLabel:SetActive(false)
	self.activeBtn:SetActive(true)
	self.costResGroup:SetActive(true)

	local baseID = self.skillList[self.chosenIndex]
	local exID = xyd.tables.partnerExSkillTable:getExID(baseID)[level + 1]
	local icon = SkillIcon.new(self.previewSkillNode)

	icon:setInfo(exID, {
		showLev = true,
		showGroup = self.previewDesc,
		callback = function ()
		end
	})

	local isPass = xyd.tables.skillTable:isPass(exID)
	local str = __("SKILL_TEXT_ZHUDONG")

	if isPass and isPass == 1 then
		str = __("SKILL_TEXT_BEIDONG")
	end

	self.previewName.text = xyd.tables.skillTable:getName(exID)
	self.previewDesc.text = xyd.tables.skillTable:getDesc(exID)
	local costs = xyd.tables.partnerExSkillCostTable:getCost(level + 1)

	for i = 1, 2 do
		local path = tostring(xyd.tables.itemTable:getIcon(costs[i][1]))

		xyd.setUISpriteAsync(self["priceIcon" .. i], nil, path)

		self["priceLabel" .. i].text = costs[i][2]

		if xyd.models.backpack:getItemNumByID(costs[i][1]) < costs[i][2] then
			self["priceLabel" .. i].color = Color.New2(3422556671.0)
		else
			self["priceLabel" .. i].color = Color.New2(960513791)
		end
	end
end

function ExSkillGradeUpWindow:register()
	ExSkillGradeUpWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.UPGRADE_PARTNER_EX_SKILL, handler(self, self.onUpgrade))
	self.eventProxy_:addEventListener(xyd.event.RESET_PARTNER_EX_SKILL, handler(self, self.onReset))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))

	UIEventListener.Get(self.activeBtn).onClick = handler(self, function ()
		local level = self.exSkills[self.chosenIndex]
		local costs = xyd.tables.partnerExSkillCostTable:getCost(level + 1)

		for i = 1, 2 do
			if costs and xyd.models.backpack:getItemNumByID(costs[i][1]) < costs[i][2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(costs[i][1])))

				return
			end
		end

		local msg = messages_pb.upgrade_partner_ex_skill_req()
		msg.partner_id = self.partner:getPartnerID()
		msg.index = self.chosenIndex

		xyd.Backend.get():request(xyd.mid.UPGRADE_PARTNER_EX_SKILL, msg)
	end)
	UIEventListener.Get(self.previewBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("exskill_preview_window", {
			partner = self.partner,
			chosenIndex = self.chosenIndex
		})
	end)
	UIEventListener.Get(self.resItem1).onClick = handler(self, function ()
		local params = {
			showGetWays = true,
			show_has_num = true,
			itemID = xyd.ItemID.NORMAL_EXERCISES,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.NORMAL_EXERCISES),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)
	UIEventListener.Get(self.resItem2).onClick = handler(self, function ()
		local params = {
			showGetWays = true,
			show_has_num = true,
			itemID = xyd.ItemID.ADVANCED_EXERCISES,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.ADVANCED_EXERCISES),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)
	UIEventListener.Get(self.resetBtn).onClick = handler(self, function ()
		local flag = false

		for i = 1, 4 do
			if self.exSkills[i] > 0 then
				flag = true
			end
		end

		if not flag then
			xyd.showToast(__("NO_EX_SKILL_RESET"))

			return
		end

		local resetCost = xyd.tables.miscTable:split2Cost("partner_exskill_reset_cost", "value", "#")

		xyd.alertConfirm(__("EX_SKILL_RESET_TIPS"), function ()
			local selfNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)

			if selfNum < resetCost[2] then
				xyd.alertTips(__("NOT_ENOUGH_CRYSTAL"))
			else
				local msg = messages_pb.reset_partner_ex_skill_req()
				msg.partner_id = self.partner:getPartnerID()

				xyd.Backend.get():request(xyd.mid.RESET_PARTNER_EX_SKILL, msg)
			end
		end, __("SURE"), false, resetCost, __("GUILD_RESET"))
	end)
end

function ExSkillGradeUpWindow:onUpgrade(event)
	xyd.showToast(__("EX_SKILL_GRADE_UP_SUCCESS"))
	self.partner:updateExSkills(event.data.partner_info.ex_skills)

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

	self.spineNode:X(self["skillNode" .. self.chosenIndex].transform.localPosition.x)
	self.spineNode:Y(self["skillNode" .. self.chosenIndex].transform.localPosition.y)

	self.effect = xyd.Spine.new(self.spineNode)

	self.effect:setInfo("exskill_lvlup", function ()
		self.effect:play("texiao01", 1, 1, function ()
			self:initSkillItem()
			self:chooseSkill(self.chosenIndex)
		end)
	end)
end

function ExSkillGradeUpWindow:onReset(event)
	xyd.showToast(__("EX_SKILL_RESET_SUCCESS"))
	self.partner:updateExSkills(event.data.partner_info.ex_skills)

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

	self:initSkillItem()
	self:chooseSkill(self.chosenIndex)
end

function ExSkillGradeUpWindow:onItemChange(event)
	self.resLabel1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.NORMAL_EXERCISES)
	self.resLabel2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ADVANCED_EXERCISES)
end

function ExSkillGradeUpWindow:chooseSkill(index)
	local st = xyd.tables.skillTable
	local level = self.exSkills[index]
	local id = tonumber(self.skillList[index])

	if level > 0 then
		id = xyd.tables.partnerExSkillTable:getExID(id)[level]
	end

	local isPass = st:isPass(id)
	local str = __("SKILL_TEXT_ZHUDONG")

	if isPass and isPass == 1 then
		str = __("SKILL_TEXT_BEIDONG")
	end

	self.skillName.text = st:getName(id)
	self.skillDesc.text = st:getDesc(id)

	if self.chosenIndex then
		self.skillIcons[self.chosenIndex]:setSelected(false)
	end

	self.chosenIndex = index

	self.skillIcons[index]:setSelected(true)
	self:initPreview()
	self:waitForFrame(1, function ()
		self.descScroll:ResetPosition()
		self.previewScroll:ResetPosition()
	end, nil)
end

function ExSkillGradeUpWindow:close(callback, skipAnimation)
	if xyd.getWindow("exskill_guide_window") then
		return
	end

	ExSkillGradeUpWindow.super.close(self, callback, skipAnimation)
end

return ExSkillGradeUpWindow
