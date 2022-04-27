local ExSkillPreviewWindow = class("ExSkillPreviewWindow", import(".BaseWindow"))
local SkillIcon = import("app.components.SkillIcon")

function ExSkillPreviewWindow:ctor(name, params)
	ExSkillPreviewWindow.super.ctor(self, name, params)

	self.partner = params.partner
	self.skillIcons = {}
	self.chosenIndex = params.chosenIndex or 1
end

function ExSkillPreviewWindow:initWindow()
	ExSkillPreviewWindow.super.initWindow(self)
	self:getComponent()

	self.title.text = __("EX_SKILL_GRADE_UP_PREVIEW")

	self:initSkillItem()
	self:chooseSkill(self.chosenIndex)
	self:register()
end

function ExSkillPreviewWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.title = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.skillGroup = winTrans:NodeByName("skillGroup").gameObject

	for i = 1, 4 do
		self["skillNode" .. i] = self.skillGroup:NodeByName("skillIcon (" .. i .. ")").gameObject
	end

	self.scrollView1 = winTrans:ComponentByName("scrollView1", typeof(UIScrollView))
	self.skillName = winTrans:ComponentByName("skillName", typeof(UILabel))
	self.skillDesc = self.scrollView1:ComponentByName("skillDesc", typeof(UILabel))
	self.scrollView2 = winTrans:ComponentByName("scrollView2", typeof(UIScrollView))
	self.layout = self.scrollView2:ComponentByName("grid", typeof(UILayout))
	self.itemCell = winTrans:NodeByName("ex_skill_preview_item").gameObject

	self.itemCell:SetActive(false)
end

function ExSkillPreviewWindow:initSkillItem()
	local awake = self.partner:getAwake()

	if awake > 0 then
		self.skillList = self.partner:getAwakeSkill(awake)
	else
		self.skillList = self.partner:getSkillIDs()
	end

	for i = 1, 4 do
		local skill = tonumber(self.skillList[i])
		local icon = SkillIcon.new(self["skillNode" .. i])

		icon:setInfo(skill, {
			hideLev = true,
			showGroup = self.previewDesc,
			callback = function ()
				self:chooseSkill(i)
			end
		})
		table.insert(self.skillIcons, icon)
	end
end

function ExSkillPreviewWindow:initBase()
	local awake = self.partner:getAwake()

	if awake > 0 then
		self.skillList = self.partner:getAwakeSkill(awake)
	else
		self.skillList = self.partner:getSkillIDs()
	end

	local st = xyd.tables.skillTable
	local id = tonumber(self.skillList[self.chosenIndex])
	local isPass = st:isPass(id)
	local str = __("SKILL_TEXT_ZHUDONG")

	if isPass and isPass == 1 then
		str = __("SKILL_TEXT_BEIDONG")
	end

	self.skillName.text = __(st:getName(id)) .. str
	self.skillDesc.text = __(st:getDesc(id))
end

function ExSkillPreviewWindow:initPreview()
	local exIDs = xyd.tables.partnerExSkillTable:getExID(self.skillList[self.chosenIndex])

	if not self.items or #self.items ~= #exIDs then
		NGUITools.DestroyChildren(self.layout.transform)

		self.items = {}

		for i = 1, #exIDs do
			local item = NGUITools.AddChild(self.layout.gameObject, self.itemCell)

			item:SetActive(true)
			table.insert(self.items, item)
		end
	end

	for i = 1, #exIDs do
		local labelIndex = self.items[i]:ComponentByName("labelIndex", typeof(UILabel))
		local labelText = self.items[i]:ComponentByName("labelText", typeof(UILabel))
		labelIndex.text = i
		local baseID = self.skillList[self.chosenIndex]
		labelText.text = xyd.tables.partnerExSkillTextTable:getDesc(exIDs[i], xyd.tables.partnerExSkillTable:getDescNum(baseID, i))
		self.items[i]:GetComponent(typeof(UIWidget)).height = math.max(labelText.height + 12, 80)

		if labelText.height == 28 then
			labelText:Y(-25)
		else
			labelText:Y(-12)
		end
	end

	self:waitForFrame(1, function ()
		self.layout:Reposition()
		self.scrollView1:ResetPosition()
		self.scrollView2:ResetPosition()
	end, nil)
end

function ExSkillPreviewWindow:register()
	ExSkillPreviewWindow.super.register(self)
end

function ExSkillPreviewWindow:chooseSkill(index)
	if self.skillIcons[self.chosenIndex] then
		self.skillIcons[self.chosenIndex]:setSelected(false)
	end

	self.chosenIndex = index

	self.skillIcons[self.chosenIndex]:setSelected(true)
	self:initBase()
	self:initPreview()
end

return ExSkillPreviewWindow
