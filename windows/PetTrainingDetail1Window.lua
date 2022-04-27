local PetTrainingDetail1Window = class("PetTrainingDetail1Window", import(".BaseWindow"))

function PetTrainingDetail1Window:ctor(name, params)
	PetTrainingDetail1Window.super.ctor(self, name, params)
end

function PetTrainingDetail1Window:initWindow()
	self:getUIComponent()
	PetTrainingDetail1Window.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function PetTrainingDetail1Window:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.titleLabel = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.levLabel = self.groupAction:ComponentByName("title_icon/lev_label", typeof(UILabel))
	self.label1 = self.groupAction:ComponentByName("label_1", typeof(UILabel))
	self.label2 = self.groupAction:ComponentByName("label_2", typeof(UILabel))
	self.dataGroup1 = self.groupAction:NodeByName("dataGroup1").gameObject
	self.dataGroup2 = self.groupAction:NodeByName("dataGroup2").gameObject
	self.dataLabel1 = self.groupAction:ComponentByName("data_label1", typeof(UILabel))
	self.dataLabel2 = self.groupAction:ComponentByName("data_label2", typeof(UILabel))

	self.dataLabel1:SetActive(false)
	self.dataLabel2:SetActive(false)
end

function PetTrainingDetail1Window:reSize()
end

function PetTrainingDetail1Window:registerEvent()
end

function PetTrainingDetail1Window:layout()
	self.titleLabel.text = __("PEW_TRAINNG_HANGUP_TEXT03")
	self.label1.text = __("PEW_TRAINNG_HANGUP_TEXT03")
	self.label2.text = __("PEW_TRAINNG_HANGUP_TEXT04")
	self.allLev = xyd.models.petSlot:getAllPetLev()
	self.levLabel.text = self.allLev
	local levExtraDatas = xyd.tables.miscTable:split2Cost("pet_training_hangup_awards2_coefficient", "value", "|#")
	local pointK = 0

	for k, extraData in ipairs(levExtraDatas) do
		local lev = extraData[1]
		local extra = extraData[2]
		local isGreen = false
		local nextExtraData = nil

		if k < #levExtraDatas then
			nextExtraData = levExtraDatas[k + 1]
		end

		if pointK == 0 and tonumber(lev) <= self.allLev and (not nextExtraData or self.allLev < nextExtraData[1]) then
			pointK = k
			isGreen = true
		end

		local labelGo = self.dataLabel1.gameObject

		if isGreen then
			labelGo = self.dataLabel2.gameObject
		end

		local go1 = NGUITools.AddChild(self.dataGroup1, labelGo)
		local label1 = go1:GetComponent(typeof(UILabel))
		label1.text = lev

		go1:SetActive(true)

		local go2 = NGUITools.AddChild(self.dataGroup2, labelGo)
		local label2 = go2:GetComponent(typeof(UILabel))
		label2.text = "+" .. (extra - 1) * 100 .. "%"

		go2:SetActive(true)
	end
end

return PetTrainingDetail1Window
