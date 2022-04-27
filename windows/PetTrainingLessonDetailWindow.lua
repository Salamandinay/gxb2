local PetIcon = import("app.components.PetIcon")
local PetChooseItem = class("PetChooseItem", import("app.components.CopyComponent"))

function PetChooseItem:ctor(go, params, parent)
	self.parent_ = parent
	self.go = go
	self.petId = params.petId

	PetChooseItem.super.ctor(self, go)
end

function PetChooseItem:initUI()
	local go = self.go
	self.petIconGroup = go:NodeByName("petIcon").gameObject

	self:initItem()
end

function PetChooseItem:initItem()
	if self.petId > 0 then
		local petInfo = xyd.models.petSlot:getPetByID(self.petId)
		local icon = PetIcon.new(self.petIconGroup)
		local data = {
			scale = 1,
			pet_id = self.petId,
			grade = petInfo.grade,
			lev = petInfo.lev,
			callback = function ()
				self:onClickItem()
			end
		}

		icon:setInfo(data)
	else
		UIEventListener.Get(self.go).onClick = handler(self, self.onClickItem)
	end
end

function PetChooseItem:onClickItem()
	local win = xyd.getWindow("pet_training_lesson_detail_window")
	local ids = xyd.models.petSlot:getPetIDs()
	local excludPets = xyd.models.petTraining:getMissionPets()
	local pets = {}
	local count = 0

	for _, id in ipairs(ids) do
		if count >= 3 then
			break
		end

		local petInfo = xyd.models.petSlot:getPetByID(id)

		if petInfo.lev ~= 0 then
			if not next(excludPets) or xyd.arrayIndexOf(excludPets, id) <= 0 then
				count = count + 1

				table.insert(pets, id)
			end
		end
	end

	if not next(pets) then
		xyd.showToast(__("PET_TRAINING_TEXT26"))

		return
	end

	local selectPets = {}

	if win then
		if win:getMissionRun() then
			return
		end

		selectPets = win:getSelectPets()
	else
		return
	end

	xyd.WindowManager.get():openWindow("choose_pet_window", {
		notShowDetail = true,
		type = xyd.PetFormationType.Battle3v3,
		select = selectPets,
		excludPets = xyd.models.petTraining:getMissionPets()
	})
end

local BaseWindow = import(".BaseWindow")
local PetTrainingLessonDetailWindow = class("PetTrainingLessonDetailWindow", BaseWindow)

function PetTrainingLessonDetailWindow:ctor(name, params)
	PetTrainingLessonDetailWindow.super.ctor(self, name, params)

	self.data_ = params
	self.missionID = params.missionId
	self.pos = params.pos
	self.petTraining = xyd.models.petTraining
	self.selectPets = {}
end

function PetTrainingLessonDetailWindow:initWindow()
	PetTrainingLessonDetailWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.content_ = winTrans:NodeByName("content").gameObject
	self.conditionsLabel_ = self.content_:ComponentByName("conditionPart/label", typeof(UILabel))
	self.petChoosesGroup_ = self.content_:NodeByName("petChooseGroup").gameObject
	self.tempItem_ = self.content_:NodeByName("tempItem").gameObject
	self.awardGroup_ = self.content_:NodeByName("awardGroup").gameObject
	self.onBtn_ = self.content_:NodeByName("onBtn").gameObject
	self.startBtn_ = self.content_:NodeByName("startBtn").gameObject
	self.cancelBtn_ = self.content_:NodeByName("cancelBtn").gameObject
	self.startLabel_ = self.content_:ComponentByName("startBtn/labelDesc", typeof(UILabel))
	self.onLabel_ = self.content_:ComponentByName("onBtn/labelDesc", typeof(UILabel))
	self.cancelLabel_ = self.content_:ComponentByName("cancelBtn/labelDesc", typeof(UILabel))
	self.alarmLabel_ = self.content_:ComponentByName("timePart/labelDesc", typeof(UILabel))
	self.closeBtn = self.content_:NodeByName("closeBtn").gameObject

	self:layOut()
	self:register()
	self:onFormation(nil, true)
end

function PetTrainingLessonDetailWindow:layOut()
	local missionTime = xyd.tables.petTrainingLessonTable:getTime(self.missionID)
	self.alarmLabel_.text = xyd.getRoughDisplayTime(missionTime)
	self.startLabel_.text = __("START")
	self.onLabel_.text = __("ONE_KEY_START")
	self.cancelLabel_.text = __("CANCEL_2")

	self.tempItem_:SetActive(false)

	self.isMissionRun = self.petTraining:isMissionRun(self.missionID, self.pos)

	if self.isMissionRun then
		self.startBtn_:SetActive(false)
		self.onBtn_:SetActive(false)
		self.cancelBtn_:SetActive(true)
	else
		self.startBtn_:SetActive(true)
		self.onBtn_:SetActive(true)
		self.cancelBtn_:SetActive(false)
	end

	self:initPets()
end

function PetTrainingLessonDetailWindow:getMissionRun()
	return self.isMissionRun
end

function PetTrainingLessonDetailWindow:initPets(pets)
	NGUITools.DestroyChildren(self.petChoosesGroup_.transform)

	pets = pets or {}

	if self.isMissionRun then
		local missionInfo = self.petTraining:getMissionInfo(self.pos)
		pets = missionInfo.pets
	end

	for i = 1, 3 do
		local petId = tonumber(pets[i]) or 0
		local go = NGUITools.AddChild(self.petChoosesGroup_, self.tempItem_)
		local petItem = PetChooseItem.new(go, {
			petId = petId
		}, self)
	end

	self.petChoosesGroup_:GetComponent(typeof(UIGrid)):Reposition()
	self:initAward(pets)
end

function PetTrainingLessonDetailWindow:initAward(pets)
	local awards = xyd.tables.petTrainingLessonTable:getAwards(self.missionID)
	local extraRate = 1

	NGUITools.DestroyChildren(self.awardGroup_.transform)

	local levSum = 0

	if pets and next(pets) then
		for _, petId in ipairs(pets) do
			local petInfo = xyd.models.petSlot:getPetByID(petId)
			local lv = tonumber(petInfo.lev)
			levSum = levSum + lv
		end

		local extraDatas = xyd.tables.miscTable:split2Cost("pet_training_lesson_award", "value", "|#")

		for _, data in ipairs(extraDatas) do
			local lv = data[1]
			local rate = data[2]

			if lv <= levSum then
				extraRate = rate
			end
		end
	end

	for _, award in ipairs(awards) do
		local itemId = award[1]
		local itemNum = math.floor(award[2] * extraRate)
		local itemIcon = xyd.getItemIcon({
			scale = 0.8981481481481481,
			itemID = itemId,
			num = itemNum,
			uiRoot = self.awardGroup_
		})
	end

	self.awardGroup_:GetComponent(typeof(UIGrid)):Reposition()

	self.conditionsLabel_.text = __("PET_TRAINING_TEXT17", tostring((extraRate - 1) * 100) .. "%")
end

function PetTrainingLessonDetailWindow:register()
	PetTrainingLessonDetailWindow.super.register(self)

	UIEventListener.Get(self.onBtn_).onClick = handler(self, self.onFormation)
	UIEventListener.Get(self.startBtn_).onClick = handler(self, self.onClickBtnStart)
	UIEventListener.Get(self.cancelBtn_).onClick = handler(self, self.onClickBtnCancel)
end

function PetTrainingLessonDetailWindow:onClickBtnStart()
	if #self.selectPets == 0 then
		xyd.showToast(__("PET_TRAINING_TEXT27"))

		return
	end

	self.petTraining:startMission(self.missionID, self.pos, self.selectPets)
	xyd.closeWindow("pet_training_lesson_detail_window")
end

function PetTrainingLessonDetailWindow:onFormation(evt, isAuto)
	local ids = xyd.models.petSlot:getPetIDs()
	local excludPets = xyd.models.petTraining:getMissionPets()
	local pets = {}
	local count = 0

	for _, id in ipairs(ids) do
		if count >= 3 then
			break
		end

		local petInfo = xyd.models.petSlot:getPetByID(id)

		if petInfo.lev ~= 0 then
			if not next(excludPets) or xyd.arrayIndexOf(excludPets, id) <= 0 then
				count = count + 1

				table.insert(pets, id)
			end
		end
	end

	if not next(pets) then
		if not isAuto then
			xyd.showToast(__("PET_TRAINING_TEXT26"))
		end

		return
	end

	if xyd.arrayEqual(pets, self.selectPets) then
		return
	end

	self.selectPets = pets

	self:initPets(pets)
end

function PetTrainingLessonDetailWindow:onClickBtnCancel()
	xyd.alert(xyd.AlertType.YES_NO, __("PET_TRAINING_TEXT28"), function (yes_no)
		if yes_no then
			self.petTraining:cancelMission(self.missionID, self.pos)
			xyd.closeWindow("pet_training_lesson_detail_window")
		end
	end)
end

function PetTrainingLessonDetailWindow:onChoosePet(pets)
	if not self.selectPets then
		self.selectPets = {}
	end

	local tmp = {}

	for i = 1, 4 do
		local petId = tonumber(pets[i]) or 0

		if petId > 0 then
			table.insert(tmp, petId)
		end
	end

	if xyd.arrayEqual(tmp, self.selectPets) then
		return
	end

	self.selectPets = tmp

	self:initPets(tmp)
end

function PetTrainingLessonDetailWindow:getSelectPets()
	local tmp = {
		0
	}

	for i = 2, 4 do
		local petId = tonumber(self.selectPets[i - 1]) or 0
		tmp[i] = petId
	end

	return tmp
end

return PetTrainingLessonDetailWindow
