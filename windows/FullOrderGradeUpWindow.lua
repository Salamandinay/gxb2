local BaseWindow = import(".BaseWindow")
local SkillIcon = import("app.components.SkillIcon")
local AttrLabel = import("app.components.AttrLabel")
local FullOrderGradeUpWindow = class("FullOrderGradeUpWindow", BaseWindow)

function FullOrderGradeUpWindow:ctor(name, params)
	FullOrderGradeUpWindow.super.ctor(self, name, params)

	self.ok_window_params = {
		type = "full_grade_up",
		skillIds = {}
	}
	self.partner_ = params
	self.oldGrade = self.partner_:getGrade()
	self.backpack_ = xyd.models.backpack
end

function FullOrderGradeUpWindow:initWindow()
	FullOrderGradeUpWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initResItem()
	self:initSkillIcon()
	self:initAttrLabel()
	self:register()
end

function FullOrderGradeUpWindow:getUIComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("content").gameObject
	local title = content:NodeByName("title").gameObject
	self.closeBtn = title:NodeByName("closeBtn").gameObject
	self.titleName = title:ComponentByName("titleName", typeof(UILabel))
	local topGroup = content:NodeByName("topGroup").gameObject

	for i = 1, 3 do
		self["resItem" .. i] = topGroup:NodeByName("resItem" .. i).gameObject
	end

	local middle = content:NodeByName("middle").gameObject
	self.attrChangeGroup = middle:NodeByName("leftGroup/attrChangeGroup").gameObject
	self.attrChangeGroupGrid = self.attrChangeGroup:GetComponent(typeof(UIGrid))
	local rightGroup = middle:NodeByName("rightGroup").gameObject
	self.labelUnlock = rightGroup:ComponentByName("labelUnlock", typeof(UILabel))
	self.skillGroup = rightGroup:NodeByName("skillGroup").gameObject
	self.skillDesc = content:NodeByName("skillDesc").gameObject
	local costGroup = content:NodeByName("bottomGroup/costGroup").gameObject

	for i = 1, 3 do
		self["costItem" .. i] = costGroup:NodeByName("costItem" .. i).gameObject
	end

	self.btnGradeUp = content:NodeByName("btnGradeUp").gameObject
	self.btnGradeUpLable = self.btnGradeUp:ComponentByName("button_label", typeof(UILabel))
end

function FullOrderGradeUpWindow:initUIComponent()
	if not self.partner_ then
		xyd.WindowManager:get():closeWindow(self)

		return
	end

	self.labelUnlock.text = __("UNLOCK_TEXT")
	self.titleName.text = __("ONE_KEY_UPGRADE_TITLE")

	xyd.setBgColorType(self.btnGradeUp, xyd.ButtonBgColorType.blue_btn_70_70)

	self.btnGradeUpLable.text = __("ONE_KEY_UPGRADE")
end

function FullOrderGradeUpWindow:initResItem()
	self.owns = {
		self.backpack_:getItemNumByID(xyd.ItemID.MANA),
		self.backpack_:getItemNumByID(xyd.ItemID.GRADE_STONE),
		self.backpack_:getItemNumByID(xyd.ItemID.PARTNER_EXP)
	}

	for i = 1, 3 do
		self["resItem" .. i]:ComponentByName("labelRes", typeof(UILabel)).text = xyd.getRoughDisplayNumber(self.owns[i])
	end

	local PartnerTable = xyd.tables.partnerTable
	local partnerID = self.partner_:getTableID()
	local partnerGrade = self.partner_:getGrade()
	local partnerLevel = self.partner_:getLevel()
	local maxLevel = xyd.tables.miscTable:getVal("one_click_upgrade_level")
	local costMANA = xyd.tables.expPartnerTable:getAllMoney(maxLevel) - xyd.tables.expPartnerTable:getAllMoney(partnerLevel)
	local costEXP = xyd.tables.expPartnerTable:getAllExp(maxLevel) - xyd.tables.expPartnerTable:getAllExp(partnerLevel)
	local costSTONE = 0
	local maxGrade = 5

	if PartnerTable:getStar(partnerID) >= 6 then
		maxGrade = 6
	end

	self.grade = maxGrade

	for i = partnerGrade + 1, maxGrade do
		local GradeUpCost = PartnerTable:getGradeUpCost(partnerID, i)
		costMANA = costMANA + GradeUpCost[xyd.ItemID.MANA]
		costSTONE = costSTONE + GradeUpCost[xyd.ItemID.GRADE_STONE]
	end

	self.costs = {
		costMANA,
		costSTONE,
		costEXP
	}

	for i = 1, 3 do
		self["costItem" .. i]:ComponentByName("labelCost", typeof(UILabel)).text = xyd.getRoughDisplayNumber(self.costs[i])
	end

	for i = 1, 3 do
		if self.owns[i] < self.costs[i] then
			self["costItem" .. i]:ComponentByName("labelCost", typeof(UILabel)).color = Color.New2(3422556671.0)
		else
			self["costItem" .. i]:ComponentByName("labelCost", typeof(UILabel)).color = Color.New2(960513791)
		end
	end
end

function FullOrderGradeUpWindow:initSkillIcon()
	local grade = self.partner_:getGrade()
	local skill_ids = {}

	for idx = 1, 3 do
		if grade < self.partner_:getPasTier(idx) then
			table.insert(skill_ids, self.partner_:getSkillID(idx))
		end
	end

	if #skill_ids > 0 then
		for i = 1, #skill_ids do
			self["skillIcon" .. i] = SkillIcon.new(self.skillGroup)

			self["skillIcon" .. i]:setInfo(skill_ids[i], {
				callback = function ()
					self:handleSkillTips(i)
				end
			})

			UIEventListener.Get(self["skillIcon" .. i].go).onSelect = function (go, isSelect)
				if isSelect == false then
					self:clearSkillTips(i)
				end
			end

			table.insert(self.ok_window_params.skillIds, skill_ids[i])
		end
	else
		self.labelUnlock:SetActive(false)
		self.skillGroup:SetActive(false)
	end

	self:setSkillIconPosition()
end

function FullOrderGradeUpWindow:setSkillIconPosition()
	if not self.skillIcon2 then
		return
	end

	local depth = self.skillGroup:GetComponent(typeof(UIWidget)).depth

	if not self.skillIcon3 then
		self.skillIcon1:SetLocalScale(0.9, 0.9, 1)
		self.skillIcon2:SetLocalScale(0.9, 0.9, 1)
		self.skillIcon1:setDepth(depth + 1)
		self.skillIcon2:setDepth(depth + 10)
		self.skillIcon1:SetLocalPosition(-35, 10, 0)
		self.skillIcon2:SetLocalPosition(20, -25, 0)
	else
		self.skillIcon1:SetLocalScale(0.85, 0.85, 1)
		self.skillIcon2:SetLocalScale(0.85, 0.85, 1)
		self.skillIcon3:SetLocalScale(0.85, 0.85, 1)
		self.skillIcon1:setDepth(depth + 1)
		self.skillIcon2:setDepth(depth + 10)
		self.skillIcon3:setDepth(depth + 20)
		self.skillIcon1:SetLocalPosition(-60, 15, 0)
		self.skillIcon2:SetLocalPosition(-15, -15, 0)
		self.skillIcon3:SetLocalPosition(30, -45, 0)
	end
end

function FullOrderGradeUpWindow:initAttrLabel()
	self.ok_window_params.attrParams = {}
	local partnerLev = self.partner_:getLevel()
	local newmaxGrade = self.grade
	self.partner_.grade = self.grade
	local newmaxLev = nil

	if newmaxGrade == 5 then
		newmaxLev = 100
	elseif newmaxGrade == 6 then
		newmaxLev = 140
	else
		local newmaxLev = xyd.tables.miscTable:getVal("one_click_upgrade_level")
	end

	NGUITools.DestroyChildren(self.attrChangeGroup.transform)
	AttrLabel.new(self.attrChangeGroup, "change", {
		"TOP_LEV_UP",
		partnerLev,
		newmaxLev
	})
	table.insert(self.ok_window_params.attrParams, {
		"TOP_LEV_UP",
		partnerLev,
		newmaxLev
	})

	local attr_enums = {
		"power",
		"hp",
		"atk",
		"arm"
	}
	local attrs = self.partner_:getBattleAttrs()
	local new_attrs = self.partner_:getBattleAttrs({
		level = xyd.tables.miscTable:getVal("one_click_upgrade_level"),
		grade = newmaxGrade
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

	self.attrChangeGroupGrid:Reposition()
end

function FullOrderGradeUpWindow:register()
	FullOrderGradeUpWindow.super.register(self)

	UIEventListener.Get(self.btnGradeUp).onClick = handler(self, self.onclickBtnGradeUp)
end

function FullOrderGradeUpWindow:onclickBtnGradeUp()
	if self.owns[1] < self.costs[1] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.MANA)))

		return
	end

	if self.owns[2] < self.costs[2] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.GRADE_STONE)))

		return
	end

	if self.owns[3] < self.costs[3] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.PARTNER_EXP)))

		return
	end

	local timeStamp = xyd.db.misc:getValue("full_order_grade_up_time_stamp")

	if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
		xyd.WindowManager.get():openWindow("gamble_tips_window", {
			type = "full_order_grade_up",
			wndType = self.curWindowType_,
			callback = function ()
				self:fullGradeUp()
			end
		})
	else
		self:fullGradeUp()
	end
end

function FullOrderGradeUpWindow:fullGradeUp()
	self.partner_:fullOrderGradeUp()
	xyd.WindowManager:get():openWindow("grade_up_ok_window", self.ok_window_params)
	self:close()
end

function FullOrderGradeUpWindow:handleSkillTips(i)
	self["skillIcon" .. i]:showTips(true, self.skillDesc, true)
end

function FullOrderGradeUpWindow:clearSkillTips(i)
	self["skillIcon" .. i]:showTips(false, self.skillDesc)
end

function FullOrderGradeUpWindow:willClose()
	FullOrderGradeUpWindow.super.willClose(self)

	self.partner_.grade = self.oldGrade
end

return FullOrderGradeUpWindow
