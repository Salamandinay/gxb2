local PetTrainingLessonItem = class("PetTrainingLessonItem", import("app.components.CopyComponent"))

function PetTrainingLessonItem:ctor(go, params, parent)
	self.parent_ = parent
	self.go = go
	self.id = params.id

	PetTrainingLessonItem.super.ctor(self, go)
end

function PetTrainingLessonItem:initUI()
	local go = self.go
	self.timeLabel = go:ComponentByName("needPart/labelDesc", typeof(UILabel))
	self.label1 = go:ComponentByName("label1", typeof(UILabel))
	self.label2 = go:ComponentByName("label2", typeof(UILabel))
	self.bg = go:ComponentByName("bg", typeof(UISprite))
	self.selectImg = go:ComponentByName("selectImg", typeof(UISprite))
	self.imgLock = go:ComponentByName("imgLock", typeof(UISprite))
	self.itemsGroup = go:NodeByName("itemsGroup").gameObject

	self:initItem()
end

function PetTrainingLessonItem:initItem()
	self.trainingLev = xyd.models.petTraining:getTrainingLevel()
	local missionTime = xyd.tables.petTrainingLessonTable:getTime(self.id)
	local missionName = xyd.tables.petTrainingLessonTextTable:getName(self.id)
	self.missionLev = xyd.tables.petTrainingLessonTable:getLev(self.id)
	self.label1.text = missionName
	self.label2.text = __("PET_TRAINING_TEXT16", self.missionLev)
	self.timeLabel.text = xyd.getRoughDisplayTime(missionTime)

	self.selectImg:SetActive(false)

	if self.trainingLev < self.missionLev then
		self.imgLock:SetActive(true)
		self.label2:SetActive(true)
	else
		self.label2:SetActive(false)
		self.imgLock:SetActive(false)
	end

	local awards = xyd.tables.petTrainingLessonTable:getAwards(self.id)

	for _, award in ipairs(awards) do
		local itemIcon = xyd.getItemIcon({
			scale = 0.6481481481481481,
			itemID = award[1],
			num = award[2],
			uiRoot = self.itemsGroup
		})

		itemIcon:setDragScrollView(self.parent_.scroller)
	end

	UIEventListener.Get(self.bg.gameObject).onClick = handler(self, self.onClickItem)
	UIEventListener.Get(self.imgLock.gameObject).onClick = handler(self, self.onClickLockImg)
end

function PetTrainingLessonItem:setSelected(status)
	self.selectImg:SetActive(status)
end

function PetTrainingLessonItem:onClickLockImg()
	xyd.showToast(__("PET_TRAINING_TEXT25"))
end

function PetTrainingLessonItem:onClickItem()
	local win = xyd.getWindow("pet_training_lesson_window")

	if win then
		win:selelctMission(self.id)
	end
end

local BaseWindow = import(".BaseWindow")
local PetTrainingLessonWindow = class("PetTrainingLessonWindow", BaseWindow)

function PetTrainingLessonWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.selectId = 0
	self.selectMissionItem = nil
	self.pos = params.pos
	self.missionList = {}
end

function PetTrainingLessonWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function PetTrainingLessonWindow:getUIComponent()
	local go = self.window_:NodeByName("groupAction").gameObject
	self.labelWinTitle = go:ComponentByName("title", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.startBtn = go:NodeByName("startBtn").gameObject
	self.startLabel = go:ComponentByName("startBtn/label", typeof(UILabel))
	self.scroller = go:ComponentByName("scroll", typeof(UIScrollView))
	self.itemGroup = go:NodeByName("scroll/itemGroup").gameObject
	self.itemCell = go:NodeByName("pet_training_lesson_item").gameObject
end

function PetTrainingLessonWindow:initUIComponent()
	self.startLabel.text = __("START")

	self.itemCell:SetActive(false)
	NGUITools.DestroyChildren(self.itemGroup.transform)

	local ids = xyd.tables.petTrainingLessonTable:getIds()
	local unlockDatas = {}
	local lockIds = {}
	local trainingLev = xyd.models.petTraining:getTrainingLevel()

	for _, id in ipairs(ids) do
		local rankUnlocked = xyd.tables.petTrainingLessonTable:getRankUnlocked(id)
		local missionLev = xyd.tables.petTrainingLessonTable:getLev(id)

		if missionLev <= trainingLev then
			local data = {
				id = id,
				rank = rankUnlocked
			}

			table.insert(unlockDatas, data)
		else
			table.insert(lockIds, id)
		end
	end

	table.sort(unlockDatas, function (a, b)
		return a.rank < b.rank
	end)

	for _, data in ipairs(unlockDatas) do
		local id = data.id
		local go = NGUITools.AddChild(self.itemGroup, self.itemCell)
		local missionItem = PetTrainingLessonItem.new(go, {
			id = id
		}, self)
		self.missionList[id] = missionItem
	end

	for _, id in ipairs(lockIds) do
		if id then
			local go = NGUITools.AddChild(self.itemGroup, self.itemCell)
			local missionItem = PetTrainingLessonItem.new(go, {
				id = id
			}, self)
			self.missionList[id] = missionItem
		end
	end

	self:waitForFrame(1, function ()
		self.scroller:ResetPosition()
	end)
	self.itemGroup:GetComponent(typeof(UIGrid)):Reposition()
end

function PetTrainingLessonWindow:register()
	PetTrainingLessonWindow.super.register(self)

	UIEventListener.Get(self.startBtn).onClick = handler(self, self.onClickStartBtn)
end

function PetTrainingLessonWindow:onClickStartBtn()
	if self.selectId > 0 then
		xyd.closeWindow("pet_training_lesson_window")
		xyd.openWindow("pet_training_lesson_detail_window", {
			missionId = self.selectId,
			pos = self.pos
		})
	else
		xyd.showToast(__("PET_TRAINING_TEXT31"))
	end
end

function PetTrainingLessonWindow:selelctMission(id)
	if id == self.selectId then
		return
	end

	local missionItem = self.missionList[id]

	if not missionItem then
		return
	end

	if self.selectMissionItem then
		self.selectMissionItem:setSelected(false)
	end

	missionItem:setSelected(true)

	self.selectMissionItem = missionItem
	self.selectId = id
end

return PetTrainingLessonWindow
