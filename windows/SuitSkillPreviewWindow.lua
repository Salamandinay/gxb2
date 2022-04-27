local SuitSkillPreviewWindow = class("SuitSkillPreviewWindow", import(".BaseWindow"))
local SuitSkillIcon = import("app.components.SuitSkillIcon")

function SuitSkillPreviewWindow:ctor(name, params)
	SuitSkillPreviewWindow.super.ctor(self, name, params)

	self.skill_list_ = params.skill_list
	self.levelUp = params.levelUp
end

function SuitSkillPreviewWindow:initWindow()
	SuitSkillPreviewWindow.super.initWindow(self)
	self:getComponent()

	self.titleLabel_.text = __("EQUIP_LEVELUP_TITLE_2")

	if self.levelUp == 1 then
		self.titleLabel2_.text = __("EQUIP_LEVELUP_TEXT_5")
	else
		self.titleLabel2_.text = __("EQUIP_LEVELUP_TEXT_6")
	end

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		self.titleLabel2_.fontSize = 22
	end

	self:initSkillItem()
	self:updateLayout()
end

function SuitSkillPreviewWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.titleLabel2_ = winTrans:ComponentByName("titleLabel2", typeof(UILabel))
	local contentGroup = winTrans:NodeByName("contentGroup").gameObject
	self.skillGroup_ = contentGroup:NodeByName("skillGroup").gameObject
	self.scrollView = contentGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.nameLabel_ = contentGroup:ComponentByName("nameLabel", typeof(UILabel))
	self.descLabel_ = contentGroup:ComponentByName("descLabel", typeof(UILabel))
	self.groupItems = self.scrollView:ComponentByName("groupItems", typeof(UITable))
	self.descLabel1 = self.groupItems:ComponentByName("labelItem1/descLabel1", typeof(UILabel))
	self.descLabel2 = self.groupItems:ComponentByName("labelItem2/descLabel2", typeof(UILabel))
	self.levelLabel1 = self.groupItems:ComponentByName("labelItem1/levelLabel1", typeof(UILabel))
	self.levelLabel2 = self.groupItems:ComponentByName("labelItem2/levelLabel2", typeof(UILabel))
	self.labelItem3 = self.groupItems:NodeByName("labelItem3").gameObject
	self.descLabel3 = self.labelItem3:ComponentByName("descLabel3", typeof(UILabel))
	self.levelLabel3 = self.labelItem3:ComponentByName("levelLabel3", typeof(UILabel))

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function SuitSkillPreviewWindow:initSkillItem()
	local forLen = 3

	for i = 1, forLen do
		local skill_id = self.skill_list_[i]
		local group = self.skillGroup_:NodeByName("skillGroup" .. i).gameObject
		local icon = SuitSkillIcon.new(group)

		icon:setInfo(skill_id, self.levelUp)
		icon:setTouchListener(function ()
			if self.cur_skill_ then
				self.cur_skill_:active(false)
			end

			self.index_ = i
			self.cur_skill_ = icon

			self.cur_skill_:active(true)
			self:updateLayout()
		end)

		if i == 1 then
			self.index_ = 1
			self.cur_skill_ = icon

			self.cur_skill_:active(true)
		end
	end

	if self.levelUp == 1 then
		self.descLabel1.color = Color.New2(2155905279.0)
		self.descLabel2.color = Color.New2(2155905279.0)

		self.labelItem3:SetActive(false)
	else
		self.labelItem3:SetActive(true)

		for i = 1, 3 do
			if self.levelUp ~= i then
				self["descLabel" .. i].color = Color.New2(2155905279.0)
			end
		end
	end
end

function SuitSkillPreviewWindow:updateLayout()
	if not self.cur_skill_ then
		self.nameLabel_.text = ""
		self.descLabel_.text = ""

		return
	end

	local skillId = self.cur_skill_:skillID()
	local lev = xyd.tables.skillTable:getSkillLev(skillId)
	self.nameLabel_.text = xyd.tables.skillTable:getName(skillId)

	if self.levelUp == lev then
		self.descLabel_.text = xyd.tables.skillTable:getDesc(skillId)
	else
		self.descLabel_.text = xyd.tables.skillTable:getDesc(skillId + 1)
	end

	if self.levelUp == 1 then
		self.descLabel1.text = xyd.tables.skillTable:getDesc(skillId - lev + 2)
		self.descLabel2.text = xyd.tables.skillTable:getDesc(skillId - lev + 3)
		self.levelLabel1.text = 2
		self.levelLabel2.text = 3
	else
		for i = 1, 3 do
			self["descLabel" .. i].text = xyd.tables.skillTable:getDesc(skillId - lev + i)
			self["levelLabel" .. i].text = i
		end
	end

	self.groupItems:Reposition()
	self:waitForFrame(1, function ()
		self.scrollView:ResetPosition()
	end)
end

return SuitSkillPreviewWindow
