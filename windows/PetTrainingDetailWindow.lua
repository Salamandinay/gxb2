local BaseWindow = import(".BaseWindow")
local PetTrainingDetailWindow = class("PetTrainingDetailWindow", BaseWindow)
local PetTrainingDetailItem = class("PetTrainingDetailItem")

function PetTrainingDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function PetTrainingDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function PetTrainingDetailWindow:getUIComponent()
	local go = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle = go:ComponentByName("title", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.scroller = go:ComponentByName("scroll", typeof(UIScrollView))
	self.itemGroup = go:NodeByName("scroll/itemGroup").gameObject
	self.itemCell = go:NodeByName("pet_training_detail_item").gameObject
end

function PetTrainingDetailWindow:initUIComponent()
	self:initItems()

	self.labelTitle.text = __("PET_TRAINING_TEXT14")
end

function PetTrainingDetailWindow:initItems()
	local ids = xyd.tables.petTrainingTextTable:getIDs()

	for i = 1, #ids do
		if ids[i] ~= 1 then
			local go = NGUITools.AddChild(self.itemGroup, self.itemCell)
			local awardItem = PetTrainingDetailItem.new(go, {
				text = xyd.tables.petTrainingTextTable:getDesc(ids[i]),
				id = ids[i]
			}, self)
		end
	end

	self.itemCell:SetActive(false)
	self.itemGroup:GetComponent(typeof(UIGrid)):Reposition()
end

function PetTrainingDetailWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.closeWindow(self.name_)
	end
end

function PetTrainingDetailItem:ctor(go, params, parent)
	self.parent_ = parent
	self.go = go
	self.text = params.text
	self.id = params.id

	self:getUIComponent()
	self:initUIComponent()
end

function PetTrainingDetailItem:getUIComponent()
	local go = self.go
	self.levLabel = go:ComponentByName("levLabel", typeof(UILabel))
	self.label1 = go:ComponentByName("label1", typeof(UILabel))
	self.label2 = go:ComponentByName("label2", typeof(UILabel))
end

function PetTrainingDetailItem:initUIComponent()
	self.levLabel.text = self.id

	if xyd.Global.lang == "fr_fr" then
		self.label1.text = "Niv." .. self.id
	else
		self.label1.text = "Lv" .. self.id
	end

	self.label2.text = self.text
end

return PetTrainingDetailWindow
