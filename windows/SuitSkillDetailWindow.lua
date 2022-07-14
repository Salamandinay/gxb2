local SuitSkillDetailWindow = class("SuitSkillDetailWindow", import(".BaseWindow"))
local SuitSkillIcon = import("app.components.SuitSkillIcon")

function SuitSkillDetailWindow:ctor(name, params)
	SuitSkillDetailWindow.super.ctor(self, name, params)

	self.partner_id = params.partner_id
	self.skill_list_ = params.skill_list
	self.enough = params.enough
	self.index_ = params.skillIndex or 1
	self.justShow = params.justShow
	self.partner_ = params.partner
	self.isFake_ = params.fakeSkill
	self.quickItem_ = params.quickItem
end

function SuitSkillDetailWindow:initWindow()
	SuitSkillDetailWindow.super.initWindow(self)
	self:getComponent()

	self.titleLabel_.text = __("SUIT_SKILL_DETAIL_WINDOW_TITLE")
	self.confirmBtnLabel_.text = __("SUIT_SKILL_DETAIL_WINDOW_BTN")

	self:initSkillItem()
	self:updateLayout()

	UIEventListener.Get(self.confirmBtn_).onClick = handler(self, self.onClickConfirmBtn)

	if not self.enough then
		xyd.setTouchEnable(self.confirmBtn_, false)
		xyd.applyGrey(self.confirmBtn_:GetComponent(typeof(UISprite)))
		self.confirmBtnLabel_:ApplyGrey()
	end

	if self.justShow then
		self.bg_.height = 390

		self.confirmBtn_:SetActive(false)
	end
end

function SuitSkillDetailWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.bg_ = winTrans:ComponentByName("e:image", typeof(UISprite))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.confirmBtn_ = winTrans:NodeByName("confirmBtn").gameObject
	self.confirmBtnLabel_ = winTrans:ComponentByName("confirmBtn/label", typeof(UILabel))
	self.skillGroup_ = winTrans:NodeByName("contentGroup/skillGroup").gameObject
	self.scrollView = winTrans:ComponentByName("contentGroup/scrollView", typeof(UIScrollView))
	self.nameLabel_ = winTrans:ComponentByName("contentGroup/scrollView/scrollGroup/nameLabel", typeof(UILabel))
	self.descLabel_ = winTrans:ComponentByName("contentGroup/scrollView/scrollGroup/descLabel", typeof(UILabel))

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function SuitSkillDetailWindow:initSkillItem()
	local forLen = 3

	for i = 1, forLen do
		local skill_data = self.skill_list_[i]
		local group = self.skillGroup_:NodeByName("skillGroup" .. i).gameObject
		local icon = SuitSkillIcon.new(group)

		icon:setInfo(skill_data)
		icon:setTouchListener(function ()
			if self.cur_skill_ then
				self.cur_skill_:active(false)
			end

			self.index_ = i
			self.cur_skill_ = icon

			self.cur_skill_:active(true)
			self:updateLayout()
		end)

		if i == self.index_ then
			self.cur_skill_ = icon

			self.cur_skill_:active(true)
		end
	end
end

function SuitSkillDetailWindow:updateLayout()
	if not self.cur_skill_ then
		self.nameLabel_.text = ""
		self.descLabel_.text = ""

		return
	end

	self.nameLabel_.text = xyd.tables.skillTable:getName(self.cur_skill_:skillID())
	self.descLabel_.text = xyd.tables.skillTable:getDesc(self.cur_skill_:skillID())

	self.scrollView:ResetPosition()
end

function SuitSkillDetailWindow:onClickConfirmBtn()
	if self.isFake_ then
		self.partner_.skill_index = self.index_
		local win = xyd.WindowManager.get():getWindow("activity_entrance_test_partner_window")

		if win then
			win:updateSuitStatus()
			win:updateEquipRed()
		end

		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
		self.partner_.time = xyd.getServerTime()

		activityData:setPartnerTime(self.partner_)

		activityData.dataHasChange = true

		activityData:setSkillIndex(self.partner_:getTableID(), self.index_)
	elseif self.quickItem_ then
		self.partner_.skill_index = self.index_

		self.quickItem_:updateSuitStatus()

		local win = xyd.WindowManager.get():getWindow("quick_formation_partner_detail_window")

		if win then
			win:updateWindowShow()
		end
	else
		xyd.models.slot:changeSuitSkill(self.partner_id, self.index_)
	end

	local wnd = xyd.WindowManager.get():getWindow("item_tips_window")

	if wnd then
		wnd:close()
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

return SuitSkillDetailWindow
