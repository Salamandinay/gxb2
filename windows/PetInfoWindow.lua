local BaseWindow = import(".BaseWindow")
local PetInfoWindow = class("PetInfoWindow", BaseWindow)
local PetSkillIcon = import("app.components.PetSkillIcon")

function PetInfoWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.id = params.id
end

function PetInfoWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function PetInfoWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("groupAction").gameObject
	local topGroup = groupMain:NodeByName("topGroup").gameObject
	self.labelWinTitle_ = topGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = topGroup:NodeByName("closeBtn").gameObject
	local infoGroup = groupMain:NodeByName("infoGroup").gameObject
	self.petSkillIconGroup = infoGroup:NodeByName("petSkillIconGroup").gameObject
	self.petSkillIcon = PetSkillIcon.new(self.petSkillIconGroup)
	local textGroup = infoGroup:NodeByName("textGroup").gameObject
	self.labelSkillLev = textGroup:ComponentByName("labelSkillLev", typeof(UILabel))
	self.labelSkillName = textGroup:ComponentByName("labelSkillName", typeof(UILabel))
	self.scroller = infoGroup:NodeByName("scroller").gameObject
	self.scroller_UIScrollView = infoGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.e_Group_UIGrid = self.scroller:ComponentByName("e:Group", typeof(UIGrid))
	self.labelSkillDesc = self.e_Group_UIGrid.gameObject:ComponentByName("labelSkillDesc", typeof(UILabel))
	local groupSkills = groupMain:NodeByName("groupSkills").gameObject

	for i = 1, 4 do
		self["groupPetSkillIcon" .. tostring(i)] = groupSkills:NodeByName("groupPetSkillIcon" .. tostring(i)).gameObject
		self["petSkillIcon" .. tostring(i)] = PetSkillIcon.new(self["groupPetSkillIcon" .. tostring(i)])
	end

	self.groupTips = groupMain:NodeByName("groupTips").gameObject
end

function PetInfoWindow:layout()
	self.labelWinTitle_.text = xyd.tables.petTable:getName(self.id)
	local level = xyd.tables.petTable:getMaxlev(self.id)
	self.labelSkillLev.text = "Lv." .. tostring(xyd.tables.petTable:getMaxlev(self.id))
	local energyID = xyd.tables.petTable:getEnergyID(self.id) + level - 1
	self.labelSkillName.text = xyd.tables.skillTable:getName(energyID)
	self.labelSkillDesc.text = xyd.tables.skillTable:getDesc(energyID)

	self.scroller_UIScrollView:ResetPosition()
	self.petSkillIcon:setInfo(energyID, {})
	self:updateSkills()
end

function PetInfoWindow:updateSkills()
	local level = 30
	local res = {}

	for i = 1, 4 do
		local skillID = xyd.tables.petTable:getPasSkill(self.id, i)

		if skillID and skillID ~= 0 then
			table.insert(res, skillID)
		end
	end

	for i = 1, 4 do
		local skillID = res[i]
		local level = xyd.tables.petSkillTable:getMaxSkillLev(skillID)
		local btn = self["petSkillIcon" .. tostring(i)]

		if btn then
			local info = {
				unlocked = true,
				showLev = true,
				lev = level,
				unlockGrade = i
			}

			btn:setInfo(skillID + level - 1, info)
		end
	end
end

function PetInfoWindow:registerEvent()
	self.super.register(self)

	for i = 1, 4 do
		local btn = self["groupPetSkillIcon" .. tostring(i)]

		UIEventListener.Get(btn).onPress = function (gameObject, state)
			print("press btn " .. tostring(i) .. " is current " .. tostring(state))
			self:showSkillTips(state, i)
		end
	end
end

function PetInfoWindow:showSkillTips(flag, index)
	local btn = self["petSkillIcon" .. tostring(index)]

	if flag then
		if btn then
			btn:showTips(flag, self.groupTips, flag)
		end
	else
		if btn then
			btn:showTips(flag, self.groupTips, flag)
		end

		self.groupTips:SetActive(false)
	end
end

return PetInfoWindow
