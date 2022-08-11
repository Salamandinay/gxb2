local BaseWindow = import(".BaseWindow")
local PetStartWindow = class("PetStartWindow", BaseWindow)

function PetStartWindow:ctor(name, params)
	PetStartWindow.super.ctor(self, name, params)

	self.petSlot = xyd.models.petSlot
end

function PetStartWindow:getUIComponent()
	local trans = self.window_.transform
	local groupMain = trans:NodeByName("groupAction").gameObject
	self.labelTitle = groupMain:ComponentByName("labelTitle_", typeof(UILabel))
	self.content_ = groupMain:NodeByName("content_").gameObject
	self.closeBtn = groupMain:NodeByName("closeBtn").gameObject
	self.group1 = self.content_:NodeByName("group1").gameObject
	self.groupDes1 = self.group1:NodeByName("groupDes1").gameObject
	self.labelDes1 = self.groupDes1:ComponentByName("labelDes1", typeof(UILabel))
	self.labelTitle1 = self.groupDes1:ComponentByName("labelTitle1", typeof(UILabel))
	self.group2 = self.content_:NodeByName("group2").gameObject
	self.groupDes2 = self.group2:NodeByName("groupDes2").gameObject
	self.labelDes2 = self.groupDes2:ComponentByName("labelDes2", typeof(UILabel))
	self.labelTitle2 = self.groupDes2:ComponentByName("labelTitle2", typeof(UILabel))
	self.missionRedMark = self.group2:ComponentByName("redMark", typeof(UISprite))
	local isShow = xyd.models.petTraining:getRedMarkStatus()

	self.missionRedMark:SetActive(isShow)
end

function PetStartWindow:initWindow()
	PetStartWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function PetStartWindow:layout()
	self.labelDes1.text = __("PET_TRAINING_TEXT03")
	self.labelTitle1.text = __("PET_TRAINING_TEXT01")
	self.labelDes2.text = __("PET_TRAINING_TEXT04")
	self.labelTitle2.text = __("PET_TRAINING_TEXT02")
	self.labelTitle.text = __("PET")
end

function PetStartWindow:registerEvent()
	PetStartWindow.super.register(self)

	local winNames = {
		"pet_window",
		"pet_training_window"
	}

	for i = 1, 2 do
		UIEventListener.Get(self["group" .. tostring(i)]).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
			xyd.WindowManager.get():closeWindow("pet_start_window", nil, , true)

			local winName = winNames[i]

			xyd.WindowManager:get():openWindow(winName)
		end
	end
end

return PetStartWindow
