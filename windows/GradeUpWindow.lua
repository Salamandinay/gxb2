local BaseWindow = import(".BaseWindow")
local SkillIcon = import("app.components.SkillIcon")
local AttrLabel = import("app.components.AttrLabel")
local GradeUpWindow = class("GradeUpWindow", BaseWindow)

function GradeUpWindow:ctor(name, params)
	GradeUpWindow.super.ctor(self, name, params)

	self.ok_window_params = {}
	self.partner_ = params
	self.backpack_ = xyd.models.backpack
end

function GradeUpWindow:getUIComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("content").gameObject
	local title = content:NodeByName("title").gameObject
	self.closeBtn = title:NodeByName("closeBtn").gameObject
	self.titleName = title:ComponentByName("titleName", typeof(UILabel))
	self.labelRes1 = content:ComponentByName("coinGroup/labelRes1", typeof(UILabel))
	self.labelRes2 = content:ComponentByName("foodGroup/labelRes2", typeof(UILabel))
	local middle = content:NodeByName("middle").gameObject
	self.attrChangeGroup = middle:NodeByName("leftGroup/attrChangeGroup").gameObject
	self.attrChangeGroupGrid = self.attrChangeGroup:GetComponent(typeof(UIGrid))
	local rightGroup = middle:NodeByName("rightGroup").gameObject
	self.labelUnlock = rightGroup:ComponentByName("labelUnlock", typeof(UILabel))
	local skillIconContainer = rightGroup:NodeByName("skillIcon").gameObject
	self.skillIcon = SkillIcon.new(skillIconContainer)
	self.labelNoUnlock = rightGroup:ComponentByName("labelNoUnlock", typeof(UILabel))
	self.skillDesc = content:NodeByName("skillDesc").gameObject
	local costGroup = content:NodeByName("costGroup").gameObject
	self.labelCostRes1 = costGroup:ComponentByName("coinCostGroup/labelCostRes1", typeof(UILabel))
	self.labelCostRes2 = costGroup:ComponentByName("foodCostGroup/labelCostRes2", typeof(UILabel))
	self.btnGradeUp = content:NodeByName("btnGradeUp").gameObject
	self.btnGradeUpLable = self.btnGradeUp:ComponentByName("button_label", typeof(UILabel))
end

function GradeUpWindow:initWindow()
	GradeUpWindow.super.initWindow(self)
	self:getUIComponent()

	if not self.partner_ then
		xyd.WindowManager:get():closeWindow(self)

		return
	end

	self.labelUnlock.text = __("UNLOCK_TEXT")
	self.labelNoUnlock.text = __("NO_UNLOCK_TEXT")
	self.titleName.text = __("GRADE_UP_2")

	xyd.setBgColorType(self.btnGradeUp, xyd.ButtonBgColorType.blue_btn_70_70)

	self.btnGradeUpLable.text = __("GRADE_UP_2")
	local costs = self.partner_:getGradeUpCost()
	local owns = {
		[xyd.ItemID.MANA] = self.backpack_:getItemNumByID(xyd.ItemID.MANA),
		[xyd.ItemID.GRADE_STONE] = self.backpack_:getItemNumByID(xyd.ItemID.GRADE_STONE)
	}
	self.labelRes1.text = xyd.getRoughDisplayNumber(owns[xyd.ItemID.MANA])
	self.labelRes2.text = xyd.getRoughDisplayNumber(owns[xyd.ItemID.GRADE_STONE])
	self.labelCostRes1.text = xyd.getRoughDisplayNumber(costs[xyd.ItemID.MANA])
	self.labelCostRes2.text = xyd.getRoughDisplayNumber(costs[xyd.ItemID.GRADE_STONE])

	if owns[xyd.ItemID.MANA] < costs[xyd.ItemID.MANA] then
		self.labelCostRes1.color = Color.New2(3422556671.0)
	else
		self.labelCostRes1.color = Color.New2(960513791)
	end

	if owns[xyd.ItemID.GRADE_STONE] < costs[xyd.ItemID.GRADE_STONE] then
		self.labelCostRes2.color = Color.New2(3422556671.0)
	else
		self.labelCostRes2.color = Color.New2(960513791)
	end

	local grade = self.partner_:getGrade()
	local skill_id = nil

	for idx = 1, 3 do
		if self.partner_:getPasTier(idx) == grade + 1 then
			skill_id = self.partner_:getSkillID(idx)

			break
		end
	end

	if skill_id ~= nil and skill_id ~= 0 then
		self.skillIcon:setInfo(skill_id, {
			callback = function ()
				self:handleSkillTips()
			end
		})

		UIEventListener.Get(self.skillIcon.go).onSelect = function (go, isSelect)
			if isSelect == false then
				self:clearSkillTips()
			end
		end

		self.ok_window_params.skillId = skill_id

		self.labelNoUnlock:SetActive(false)
	else
		self.labelUnlock:SetActive(false)
		self.labelNoUnlock:SetActive(true)
		self.skillIcon:SetActive(false)
	end

	self:initAttrLabel()
	self:registerEvent()
end

function GradeUpWindow:initAttrLabel()
	self.ok_window_params.attrParams = {}
	local maxLev = self.partner_:getMaxLev(self.partner_:getGrade())
	local newMaxLev = self.partner_:getMaxLev(self.partner_:getGrade() + 1)

	NGUITools.DestroyChildren(self.attrChangeGroup.transform)
	AttrLabel.new(self.attrChangeGroup, "change", {
		"TOP_LEV_UP",
		maxLev,
		newMaxLev
	})
	table.insert(self.ok_window_params.attrParams, {
		"TOP_LEV_UP",
		maxLev,
		newMaxLev
	})

	local attr_enums = {
		"power",
		"hp",
		"atk",
		"arm"
	}
	local attrs = self.partner_:getBattleAttrs()
	self.partner_.grade = self.partner_.grade + 1
	local new_attrs = self.partner_:getBattleAttrs({
		grade = self.partner_.grade
	})

	for _, v in ipairs(attr_enums) do
		local params = {
			v,
			attrs[v],
			new_attrs[v]
		}

		table.insert(self.ok_window_params.attrParams, params)

		params[1] = string.upper(params[1])

		AttrLabel.new(self.attrChangeGroup, "change", params)
	end

	self.partner_.grade = self.partner_.grade - 1

	self.attrChangeGroupGrid:Reposition()
end

function GradeUpWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnGradeUp).onClick = handler(self, self.onclickBtnGradeUp)
end

function GradeUpWindow:onclickBtnGradeUp()
	local costs = self.partner_:getGradeUpCost()
	local owns = {
		[xyd.ItemID.MANA] = self.backpack_:getItemNumByID(xyd.ItemID.MANA),
		[xyd.ItemID.GRADE_STONE] = self.backpack_:getItemNumByID(xyd.ItemID.GRADE_STONE)
	}

	if owns[xyd.ItemID.MANA] < costs[xyd.ItemID.MANA] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.MANA)))

		return
	end

	if owns[xyd.ItemID.GRADE_STONE] < costs[xyd.ItemID.GRADE_STONE] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.GRADE_STONE)))

		return
	end

	self.partner_:gradeUp()
	xyd.WindowManager:get():openWindow("grade_up_ok_window", self.ok_window_params)

	local evaluate_have_closed = xyd.db.misc:getValue("evaluate_have_closed") or false
	local lastTime = xyd.db.misc:getValue("evaluate_last_time") or 0

	if not evaluate_have_closed and lastTime and xyd.getServerTime() - lastTime > 3 * xyd.DAY_TIME then
		local win = xyd.getWindow("main_window")

		win:setHasEvaluateWindow(true, xyd.EvaluateFromType.GRADE)
	end

	self:close()
end

function GradeUpWindow:handleSkillTips()
	self.skillIcon:showTips(true, self.skillDesc, true)
end

function GradeUpWindow:clearSkillTips()
	self.skillIcon:showTips(false, self.skillDesc)
end

return GradeUpWindow
