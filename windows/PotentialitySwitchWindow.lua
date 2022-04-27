local PotentialitySwitchWindow = class("PotentialitySwitchWindow", import(".BaseWindow"))
local SkillIcon = class("SkillIcon", import("app.components.SkillIcon"))
local PotentialIcon = class("PotentialIcon", import("app.components.PotentialIcon"))

function PotentialitySwitchWindow:ctor(name, params)
	self.select_row_ = 1
	self.select_col_ = 1
	self.itemList_ = {}

	PotentialitySwitchWindow.super.ctor(self, name, params)

	self.partner_ = params.partner
	self.isEntrance_ = params.isEntrance
end

function PotentialitySwitchWindow:initWindow()
	PotentialitySwitchWindow.super.initWindow(self)
	self:getComponent()

	self.titleLabel_.text = __("POTENTIALITY_SWITCH_WINDOW_TITLE")
	self.activeBtnLabel_.text = __("POTENTIALITY_ACTIVE")
	self.switchBtnLabel_.text = __("POTENTIAL_PLAN_TEXT01")

	self:initSkills()
	self:updateBtn()
	self:updateSkillDesc()
	self:register()
end

function PotentialitySwitchWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.btnHelp_ = winTrans:NodeByName("btnHelp").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.activeBtn_ = winTrans:NodeByName("activeBtn").gameObject
	self.activeBtnLabel_ = winTrans:ComponentByName("activeBtn/label", typeof(UILabel))
	self.switchBtn = winTrans:NodeByName("switchBtn").gameObject
	self.switchBtnLabel_ = winTrans:ComponentByName("switchBtnLabel", typeof(UILabel))
	local groupTrans = winTrans:NodeByName("e:group").gameObject
	self.skillDescGroup_ = groupTrans:NodeByName("skillDescGroup").gameObject
	self.skillTipsLabel_ = groupTrans:ComponentByName("skillTipsLabel", typeof(UILabel))
	self.scrollView = groupTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.skillNameLabel_ = groupTrans:ComponentByName("scrollView/skillNameLabel", typeof(UILabel))
	self.skillDescLabel_ = groupTrans:ComponentByName("scrollView/skillDescLabel", typeof(UILabel))
	self.effectGroup_ = groupTrans:NodeByName("effectGroup").gameObject
	self.itemGroup_ = groupTrans:ComponentByName("itemGroup", typeof(UIGrid))

	if self.isEntrance_ then
		self.switchBtn:SetActive(false)
		self.switchBtnLabel_.gameObject:SetActive(false)
	end
end

function PotentialitySwitchWindow:register()
	PotentialitySwitchWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnHelp_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "POTENTIALITY_SWITCH_HELP"
		})
	end

	UIEventListener.Get(self.activeBtn_).onClick = function ()
		if self.isEntrance_ then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
			activityData.dataHasChange = true
			self.partner_.potentials[self.select_row_] = self.select_col_

			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.CHOOSE_PARTNER_POTENTIAL
			})
		else
			local msg = messages_pb.choose_partner_potential_req()
			msg.awake_index = self.select_row_
			msg.index = self.select_col_
			msg.partner_id = self.partner_:getPartnerID()

			xyd.Backend.get():request(xyd.mid.CHOOSE_PARTNER_POTENTIAL, msg)
		end
	end

	UIEventListener.Get(self.switchBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("potentiality_edit_window", {
			partner = self.partner_
		})
	end

	self.eventProxy_:addEventListener(xyd.event.CHOOSE_PARTNER_POTENTIAL, function ()
		self:updateBtn()
		self:initSkills()

		if not self.effect_ then
			self.effect_ = xyd.Spine.new(self.effectGroup_)

			self.effect_:setInfo("fx_ui_13xing_switch_skill", function ()
				self.effect_:play("texiao01", 1, 1, function ()
					self.effect_:SetActive(false)
				end)
			end)
		else
			self.effect_:SetActive(true)
			self.effect_:play("texiao01", 1, 1, function ()
				self.effect_:SetActive(false)
			end)
		end
	end, self)
	self.eventProxy_:addEventListener(xyd.event.SET_POTENTIALS_BAK, function ()
		self:updateBtn()
		self:initSkills()
	end)
end

function PotentialitySwitchWindow:initSkills()
	local list = xyd.tables.partnerTable:getPotential(self.partner_:getTableID())
	local star = self.partner_:getStar()
	local active_list = self.partner_:getActiveIndex()

	for i = 1, 5 do
		if not self.itemList_[i] then
			self.itemList_[i] = {}
		end

		for j = 1, 3 do
			local skill_id = list[i][j]
			local params = {
				is_mask = true,
				is_active = false,
				show_effect = false,
				is_lock = true
			}

			if i == self.select_row_ and j == self.select_col_ then
				params.is_active = true
			end

			if i < star - 9 then
				params.is_lock = false

				if j == active_list[i] then
					params.is_mask = false
					params.show_effect = false
				end
			end

			local PotentialItem = nil

			if not self.itemList_[i][j] then
				PotentialItem = PotentialIcon.new(self.itemGroup_.gameObject)

				PotentialItem:setTouchListener(function ()
					local olditem = self.itemList_[self.select_row_][self.select_col_]

					if olditem then
						olditem:active(false)
					end

					self.select_row_ = i
					self.select_col_ = j

					PotentialItem:active(true)
					self:updateBtn()
					self:updateSkillDesc()
				end)

				self.itemList_[i][j] = PotentialItem
			else
				PotentialItem = self.itemList_[i][j]
			end

			PotentialItem:setInfo(skill_id, params)
		end
	end
end

function PotentialitySwitchWindow:disableBtn()
	local box = self.activeBtn_:GetComponent(typeof(UnityEngine.BoxCollider))
	local sprite = self.activeBtn_:GetComponent(typeof(UISprite))

	xyd.applyGrey(sprite)
	self.activeBtnLabel_:ApplyGrey()

	box.enabled = false
end

function PotentialitySwitchWindow:enableBtn()
	local box = self.activeBtn_:GetComponent(typeof(UnityEngine.BoxCollider))
	local sprite = self.activeBtn_:GetComponent(typeof(UISprite))

	xyd.applyOrigin(sprite)
	self.activeBtnLabel_:ApplyOrigin()

	box.enabled = true
end

function PotentialitySwitchWindow:updateBtn()
	local row = self.select_row_
	local col = self.select_col_
	local active_list = self.partner_:getActiveIndex()

	if col == active_list[row] then
		self:disableBtn()

		return
	end

	local star = self.partner_:getStar()

	if row >= star - 9 then
		self:disableBtn()

		return
	end

	self:enableBtn()
end

function PotentialitySwitchWindow:updateSkillDesc()
	local type_ = self.select_row_
	local star = self.partner_:getStar()

	if type_ <= star - 10 then
		self.skillTipsLabel_.gameObject:SetActive(false)
	else
		self.skillTipsLabel_.gameObject:SetActive(true)

		self.skillTipsLabel_.text = __("POTENTIALITY_UNLOCK_TEXT1", type_)
	end

	local skill_id = self.itemList_[self.select_row_][self.select_col_]:skillID()
	self.skillNameLabel_.text = xyd.tables.skillTextTable:getName(skill_id)
	self.skillDescLabel_.text = xyd.tables.skillTextTable:getDesc(skill_id)

	if not self.skillIcon then
		self.skillIcon = SkillIcon.new(self.skillDescGroup_)
	end

	self.skillIcon:setInfo(skill_id)
	self.scrollView:ResetPosition()
end

return PotentialitySwitchWindow
