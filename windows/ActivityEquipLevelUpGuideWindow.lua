local ActivityEquipLevelUpGuideWindow = class("ActivityEquipLevelUpGuideWindow", import(".BaseWindow"))

function ActivityEquipLevelUpGuideWindow:ctor(name, params)
	ActivityEquipLevelUpGuideWindow.super.ctor(self, name, params)

	self.positionList_ = params.positionList

	dump(self.positionList_)
end

function ActivityEquipLevelUpGuideWindow:initWindow()
	ActivityEquipLevelUpGuideWindow.super.initWindow(self)
	self:getUIComponent()
	self:initHand()
end

function ActivityEquipLevelUpGuideWindow:getUIComponent()
	for i = 1, 3 do
		self["guideRoot" .. i] = self.window_:NodeByName("groupAction/guideRoot" .. i).gameObject
		self["guideRoot" .. i].transform.position = self.positionList_[i]
	end
end

function ActivityEquipLevelUpGuideWindow:initHand()
	for i = 1, 3 do
		self["hand" .. i] = xyd.Spine.new(self["guideRoot" .. i])

		self["hand" .. i]:setInfo("fx_ui_dianji", function ()
			self["hand" .. i]:SetLocalScale(1.1, 1.1, 1.1)
			self["hand" .. i]:play("texiao01", 0, 1)
		end)
	end
end

function ActivityEquipLevelUpGuideWindow:guide1()
	self.guideRoot2:SetActive(true)
	self.guideRoot3:SetActive(false)
	self.guideRoot1:SetActive(false)
end

function ActivityEquipLevelUpGuideWindow:guide2()
	self.guideRoot3:SetActive(true)
	self.guideRoot2:SetActive(false)
	self.guideRoot1:SetActive(false)
end

function ActivityEquipLevelUpGuideWindow:guide3()
	xyd.db.misc:setValue({
		value = "1",
		key = "activity_equip_level_up_guide"
	})
	xyd.WindowManager.get():closeWindow(self.name_)
end

function ActivityEquipLevelUpGuideWindow:clearGuide()
	self.guideRoot3:SetActive(false)
	self.guideRoot2:SetActive(false)
	self.guideRoot1:SetActive(false)
end

return ActivityEquipLevelUpGuideWindow
