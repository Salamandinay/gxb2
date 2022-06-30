local PotentialityChooseWindow = class("PotentialityChooseWindow", import(".BaseWindow"))
local PotentialIcon = import("app.components.PotentialIcon")

function PotentialityChooseWindow:ctor(name, params)
	PotentialityChooseWindow.super.ctor(self, name, params)
	dump(params)

	self.skill_list_ = params.skill_list
	self.partner_ = params.partner
	self.awake_index_ = params.awake_index
	self.isEntrance_ = params.isEntrance
	self.type = params.type or "default"
	self.quickItem_ = params.quickItem

	if params.callBack then
		self.callBack = params.callBack
	end

	if params.winNameText then
		self.winNameText = params.winNameText
	end
end

function PotentialityChooseWindow:initWindow()
	PotentialityChooseWindow.super.initWindow(self)
	self:getComponent()

	self.titleLabel_.text = __("POTENTIALITY_CHOOSE_WINDOW_TITLE")

	if self.winNameText then
		self.titleLabel_.text = self.winNameText
	end

	self.confirmBtnLabel_.text = __("POTENTIALITY_CHOOSE_WINDOW_CONFIRM")

	self:initSkillItem()
	self:updateLayout()

	UIEventListener.Get(self.confirmBtn_).onClick = handler(self, self.onClickConfirmBtn)

	self.eventProxy_:addEventListener(xyd.event.CHOOSE_PARTNER_POTENTIAL, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function PotentialityChooseWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
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

function PotentialityChooseWindow:initSkillItem()
	local forLen = 3

	if self.type == xyd.ActivityID.FAIRY_TALE then
		forLen = #self.skill_list_

		self.skillGroup_:NodeByName("skillGroup" .. 1).gameObject:SetLocalPosition(0, 0, 0)
	end

	for i = 1, forLen do
		local skill_data = self.skill_list_[i]
		local group = self.skillGroup_:NodeByName("skillGroup" .. i).gameObject
		local icon = PotentialIcon.new(group)

		icon:setInfo(skill_data, {
			type = self.type
		})
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
end

function PotentialityChooseWindow:updateLayout()
	if not self.cur_skill_ then
		self.nameLabel_.text = ""
		self.descLabel_.text = ""

		return
	end

	if self.type == "default" or self.type == "potentials_bak" then
		self.nameLabel_.text = xyd.tables.skillTextTable:getName(self.cur_skill_:skillID())
		self.descLabel_.text = xyd.tables.skillTextTable:getDesc(self.cur_skill_:skillID())
	elseif self.type == xyd.ActivityID.FAIRY_TALE then
		self.nameLabel_.text = xyd.tables.activityFairyTaleBuffTextTable:getName(self.cur_skill_:skillID())
		self.descLabel_.text = xyd.tables.activityFairyTaleBuffTextTable:getDesc(self.cur_skill_:skillID())
	end

	self.scrollView:ResetPosition()
end

function PotentialityChooseWindow:onClickConfirmBtn()
	if self.type == "default" then
		local index = self.index_

		if self.isEntrance_ then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
			activityData.dataHasChange = true
			self.partner_.potentials[self.awake_index_] = index

			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.CHOOSE_PARTNER_POTENTIAL
			})
		elseif self.quickItem_ then
			self.partner_.potentials[self.awake_index_] = index

			self.quickItem_:updatePotentials(self.awake_index_, index)

			local win = xyd.WindowManager.get():getWindow("quick_formation_partner_detail_window")

			if win then
				win:updateWindowShow()
			end
		else
			local msg = messages_pb.choose_partner_potential_req()
			msg.awake_index = self.awake_index_
			msg.index = index
			msg.partner_id = self.partner_:getPartnerID()

			xyd.Backend.get():request(xyd.mid.CHOOSE_PARTNER_POTENTIAL, msg)
		end
	elseif self.type == xyd.ActivityID.FAIRY_TALE then
		if self.callBack then
			self.callBack()
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	elseif self.type == "potentials_bak" then
		if self.callBack then
			self.callBack(self.index_, self.awake_index_)
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

return PotentialityChooseWindow
