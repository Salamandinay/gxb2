local BaseWindow = import(".BaseWindow")
local PetGradeUpWindow = class("PetGradeUpWindow", BaseWindow)
local PetSkillIcon = import("app.components.PetSkillIcon")

function PetGradeUpWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.pet_ = params.pet
	self.backpack_ = xyd.models.backpack
	self.skinName = "PetGradeUpWindowSkin"
end

function PetGradeUpWindow:initWindow()
	BaseWindow.initWindow(self)

	if not self.pet_ then
		xyd.WindowManager:get():closeWindow(self)

		return
	end

	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function PetGradeUpWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("groupAction").gameObject
	self.groupMain = groupMain
	self.titleName = groupMain:ComponentByName("titleName", typeof(UILabel))
	self.labelLevLimit = groupMain:ComponentByName("gradeGroup/labelLevLimit", typeof(UILabel))
	local changeGroup = groupMain:NodeByName("changeGroup").gameObject
	self.labelLevNew = changeGroup:ComponentByName("labelLevNew", typeof(UILabel))
	self.labelLevOld = changeGroup:ComponentByName("labelLevOld", typeof(UILabel))
	local midGroup = groupMain:NodeByName("midGroup").gameObject
	self.labelUnlock = midGroup:ComponentByName("labelUnlock", typeof(UILabel))
	self.petSkillIconGroup = midGroup:NodeByName("petSkillIconGroup").gameObject
	self.petSkillIcon = PetSkillIcon.new(self.petSkillIconGroup)
	local groupLevupCost = groupMain:NodeByName("groupLevupCost").gameObject
	self.labelCostRes1 = groupLevupCost:ComponentByName("labelCostRes1", typeof(UILabel))
	self.labelCostRes2 = groupLevupCost:ComponentByName("labelCostRes2", typeof(UILabel))
	self.btnGradeUp = groupMain:NodeByName("btnGradeUp").gameObject
	self.btnLabel = self.btnGradeUp:ComponentByName("btnLabel", typeof(UILabel))
	self.closeBtn = groupMain:NodeByName("closeBtn").gameObject
	self.skillDesc = groupMain:NodeByName("skillDesc").gameObject
end

function PetGradeUpWindow:layout()
	self.titleName.text = __("PET_EVOLVE_TITLE")
	self.btnLabel.text = __("PET_EVOLVE_TITLE")
	self.labelUnlock.text = __("PET_BUFF_UNLOCK")
	local costs = self.pet_:getGradeUpCost()
	local owns = {
		[xyd.ItemID.MANA] = self.backpack_:getItemNumByID(xyd.ItemID.MANA),
		[xyd.ItemID.PET_STONE] = self.backpack_:getItemNumByID(xyd.ItemID.PET_STONE)
	}
	self.labelCostRes1.text = xyd.getRoughDisplayNumber(costs[xyd.ItemID.MANA])
	self.labelCostRes2.text = xyd.getRoughDisplayNumber(costs[xyd.ItemID.PET_STONE])

	if owns[xyd.ItemID.MANA] < costs[xyd.ItemID.MANA] then
		self.labelCostRes1.color = Color.New2(3422556671.0)
	else
		self.labelCostRes1.color = Color.New2(1432789759)
	end

	if owns[xyd.ItemID.PET_STONE] < costs[xyd.ItemID.PET_STONE] then
		self.labelCostRes2.color = Color.New2(3422556671.0)
	else
		self.labelCostRes2.color = Color.New2(1432789759)
	end

	local grade = self.pet_:getGrade()
	local skill_id = nil
	local idx = 1

	while idx <= 4 do
		if self.pet_:getPasTier(idx) == grade + 1 then
			skill_id = self.pet_:getSkillID(idx)

			break
		end

		idx = idx + 1
	end

	self.petSkillIcon:setInfo(skill_id)

	self.labelLevLimit.text = __("PET_LEV_LIMIT")
	self.labelLevOld.text = tostring(self.pet_:getLevel())
	self.labelLevNew.text = tostring(self.pet_:getMaxLev(self.pet_:getGrade() + 1))
end

function PetGradeUpWindow:registerEvent()
	PetGradeUpWindow.super.register(self)

	UIEventListener.Get(self.petSkillIconGroup).onPress = function (go, isPressed)
		print("group on press: " .. tostring(isPressed))

		if isPressed then
			self:handleSkillTips()
		else
			self:clearSkillTips()
		end
	end

	UIEventListener.Get(self.groupMain).onPress = function (go, isPressed)
		if not isPressed then
			self:clearSkillTips()
		end
	end

	xyd.setDarkenBtnBehavior(self.btnGradeUp, self, handler(self, self.onclickBtnGradeUp))
end

function PetGradeUpWindow:onclickBtnGradeUp()
	local costs = self.pet_:getGradeUpCost()
	local owns = {
		[xyd.ItemID.MANA] = self.backpack_:getItemNumByID(xyd.ItemID.MANA),
		[xyd.ItemID.PET_STONE] = self.backpack_:getItemNumByID(xyd.ItemID.PET_STONE)
	}
	local tips = ""
	local flag = false

	if owns[xyd.ItemID.MANA] < costs[xyd.ItemID.MANA] then
		tips = __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.MANA))
		flag = true
	elseif owns[xyd.ItemID.PET_STONE] < costs[xyd.ItemID.PET_STONE] then
		tips = __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.PET_STONE))
		flag = true
	end

	if flag then
		xyd.alert(xyd.AlertType.TIPS, tips)

		return
	end

	xyd.models.petSlot:reqGradeUp(self.pet_:getPetID())
	print("close name" .. tostring(self.name_))
	xyd.WindowManager.get():closeWindow(self.name_)
end

function PetGradeUpWindow:handleSkillTips(event)
	self.petSkillIcon:showTips(true, self.skillDesc)
end

function PetGradeUpWindow:clearSkillTips()
	self.petSkillIcon:showTips(false, self.skillDesc)
end

return PetGradeUpWindow
