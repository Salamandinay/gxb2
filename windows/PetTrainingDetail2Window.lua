local PetTrainingDetail2Window = class("PetTrainingDetail2Window", import(".BaseWindow"))

function PetTrainingDetail2Window:ctor(name, params)
	PetTrainingDetail2Window.super.ctor(self, name, params)
end

function PetTrainingDetail2Window:initWindow()
	self:getUIComponent()
	PetTrainingDetail2Window.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function PetTrainingDetail2Window:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.titleLabel = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.levLabel = self.groupAction:ComponentByName("title_icon/lev_label", typeof(UILabel))
	self.label1 = self.groupAction:ComponentByName("label_1", typeof(UILabel))
	self.label2 = self.groupAction:ComponentByName("label_2", typeof(UILabel))
	self.label3 = self.groupAction:ComponentByName("label_3", typeof(UILabel))
	self.label4 = self.groupAction:ComponentByName("label_4", typeof(UILabel))
	self.dataGroup1 = self.groupAction:NodeByName("dataGroup1").gameObject
	self.dataGroup2 = self.groupAction:NodeByName("dataGroup2").gameObject
	self.dataGroup3 = self.groupAction:NodeByName("dataGroup3").gameObject
	self.dataGroup4 = self.groupAction:NodeByName("dataGroup4").gameObject
	self.dataLabel1 = self.groupAction:ComponentByName("data_label1", typeof(UILabel))
	self.dataLabel2 = self.groupAction:ComponentByName("data_label2", typeof(UILabel))

	self.dataLabel1:SetActive(false)
	self.dataLabel2:SetActive(false)
end

function PetTrainingDetail2Window:reSize()
end

function PetTrainingDetail2Window:registerEvent()
end

function PetTrainingDetail2Window:layout()
	self.titleLabel.text = __("PEW_TRAINNG_HANGUP_TEXT05")
	self.label1.text = __("PEW_TRAINNG_HANGUP_TEXT06")
	self.label2.text = __("PEW_TRAINNG_HANGUP_TEXT07")
	self.label3.text = __("PEW_TRAINNG_HANGUP_TEXT07")
	self.label4.text = __("PEW_TRAINNG_HANGUP_TEXT08")
	self.lev = xyd.models.petTraining:getTrainingLevel()
	self.levLabel.text = self.lev
	local ids = xyd.tables.petTrainingNewAwardsTable:getIds()

	for _, id in ipairs(ids) do
		local labelGo = self.dataLabel1.gameObject

		if id == self.lev then
			labelGo = self.dataLabel2.gameObject
		end

		local go1 = NGUITools.AddChild(self.dataGroup1, labelGo)
		local label1 = go1:GetComponent(typeof(UILabel))
		label1.text = id

		go1:SetActive(true)

		local go2 = NGUITools.AddChild(self.dataGroup2, labelGo)
		local label2 = go2:GetComponent(typeof(UILabel))
		local award1 = xyd.tables.petTrainingNewAwardsTable:getAward(id, 2)
		label2.text = award1[2]

		go2:SetActive(true)

		local go3 = NGUITools.AddChild(self.dataGroup3, labelGo)
		local label3 = go3:GetComponent(typeof(UILabel))
		local award2 = xyd.tables.petTrainingNewAwardsTable:getAward(id, 1)
		label3.text = award2[2]

		go3:SetActive(true)

		local go4 = NGUITools.AddChild(self.dataGroup4, labelGo)
		local label4 = go4:GetComponent(typeof(UILabel))
		label4.text = xyd.tables.petTrainingNewAwardsTable:getDesc(id) / 60

		go4:SetActive(true)
	end
end

return PetTrainingDetail2Window
