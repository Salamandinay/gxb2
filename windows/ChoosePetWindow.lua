local choosePetItem = class("choosePetItem", import("app.components.CopyComponent"))

function choosePetItem:ctor(go, id, parentWindow, selectIndex, petFormationType, notShowDetail)
	choosePetItem.super.ctor(self, go)

	self.id_ = id
	self.parentWindow = parentWindow
	self.selectIndex = selectIndex
	self.petFormationType = petFormationType
	local trans = go.transform
	self.selfgo = go
	self.modelGroup = trans:Find("model_group")
	self.maskImg = trans:ComponentByName("mask_img", typeof(UISprite))
	self.bgImg = trans:ComponentByName("bg", typeof(UISprite))
	self.selectImg = trans:ComponentByName("select_img", typeof(UISprite))
	self.borderImg0 = trans:ComponentByName("border0", typeof(UISprite))
	self.borderImg1 = trans:ComponentByName("border1", typeof(UISprite))
	self.okBtnImg = trans:ComponentByName("ok_btn", typeof(UISprite))
	self.okBtn = trans:Find("ok_btn").gameObject
	self.labelOkBtn = trans:ComponentByName("ok_btn/button_label", typeof(UILabel))
	self.jumpBtn = trans:NodeByName("jump_btn").gameObject
	self.coreIcon = trans:ComponentByName("core_icon", typeof(UISprite))
	self.coreLevelLabel = trans:ComponentByName("core_icon/core_level_label", typeof(UILabel))
	self.levelLabel = trans:ComponentByName("level_label", typeof(UILabel))
	self.notShowDetail = notShowDetail

	if self.petFormationType == xyd.PetFormationType.HeroChallenge then
		self.petModel = xyd.models.heroChallenge
	elseif self.petFormationType == xyd.PetFormationType.ENTRANCE_TEST then
		self.petModel = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	else
		self.petModel = xyd.models.petSlot
	end

	local pet = self.petModel:getPetByID(id)

	if not pet then
		return
	end

	self:setDragScrollView(parentWindow.petScrollView)
	self:setModel()

	local grade = pet:getGrade()
	local strs = xyd.tables.miscTable:split("pet_frame_use", "value", "|")
	local source = strs[grade + 1]

	xyd.setUISpriteAsync(self.borderImg0, nil, source)
	xyd.setUISpriteAsync(self.borderImg1, nil, source)

	local bgSource = xyd.tables.petTable:getCardBg(id)

	xyd.setUISpriteAsync(self.bg, nil, bgSource)
	self:updateInfo(nil)

	if pet:getLevel() <= 0 then
		self.labelOkBtn.text = __("CHOOSE_PET_TEXT01")

		self.selectImg:SetActive(false)
		xyd.setBgColorType(self.okBtn, xyd.ButtonBgColorType.blue_btn_60_60)
		xyd.applyChildrenGrey(self.go)
		xyd.setTouchEnable(self.okBtn, false)

		return
	end

	local wnd = xyd.WindowManager.get():getWindow("choose_pet_window") or xyd.WindowManager.get():getWindow("station_choose_pet_window")

	if not wnd then
		return
	end

	xyd.setTouchEnable(self.okBtn, true)
	self:setSelected(self.selectIndex ~= -1)

	UIEventListener.Get(self.okBtn).onClick = handler(self, self.onTouch)
	UIEventListener.Get(self.jumpBtn).onClick = handler(self, self.onCilckJumpBtn)
end

function choosePetItem:setModel()
	local pet = self.petModel:getPetByID(self.id_)
	local modelName = pet:getModelName()

	if self.petSpine and self.petSpine:getName() == modelName then
		return
	elseif self.petSpine then
		self.petSpine:destroy()
	end

	local pos = xyd.tables.modelTable:getPetCardPos(pet:getModelID())
	self.petSpine = xyd.Spine.new(self.modelGroup.gameObject)

	self.petSpine:setInfo(modelName, function ()
		self.petSpine:SetLocalPosition(pos[2], -pos[3] + 204, 0)
		self.petSpine:SetLocalScale(pos[1], pos[1], 1)
		self.petSpine:play("idle", 0)

		local pet = self.petModel:getPetByID(self.id_)

		if pet:getLevel() <= 0 then
			self.petSpine.spAnim.fillColor = Vector4(0, 0, 0, 1)
			self.petSpine.spAnim.fillPhase = 1
		else
			self.petSpine.spAnim.fillPhase = 0
		end

		local firstOne_y = self.parentWindow.fistPetItem_y

		if self.parentWindow and not tolua.isnull(self.parentWindow.window_) then
			self.petSpine:setClipAreaWithScroller(self.parentWindow.petScrollView.gameObject, self.selfgo.gameObject, firstOne_y, Vector4(2, 8, 0, 0), Vector2(-12, -15))
		end
	end)
end

function choosePetItem:onTouch()
	local id = self.id_
	local pet = self.petModel:getPetByID(id)

	if not pet or pet:getLevel() <= 0 then
		return
	end

	local wnd = xyd.WindowManager.get():getWindow("choose_pet_window") or xyd.WindowManager.get():getWindow("station_choose_pet_window")

	if not wnd then
		return
	end

	wnd:selectPet(self.id_, self.selectIndex)
end

function choosePetItem:updateInfo(fakeLevel)
	if self.petFormationType == xyd.PetFormationType.HeroChallenge then
		self.petModel = xyd.models.heroChallenge
	elseif self.petFormationType == xyd.PetFormationType.ENTRANCE_TEST then
		self.petModel = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	else
		self.petModel = xyd.models.petSlot
	end

	local pet = self.petModel:getPetByID(self.id_)

	if pet:getExLv() > 0 then
		self.selfgo.transform:NodeByName("core_icon").gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.coreIcon, nil, "pet_exskill_" .. self.id_)

		self.coreLevelLabel.text = __("PET_EXSKILL_TEXT_01", pet:getExLv())
	else
		self.selfgo.transform:NodeByName("core_icon").gameObject:SetActive(false)
	end

	if fakeLevel ~= nil then
		self.levelLabel.text = __("PET_EXSKILL_TEXT_01", fakeLevel)
	else
		self.levelLabel.text = __("PET_EXSKILL_TEXT_01", pet:getLevel())
	end

	local modelName = pet:getModelName()

	if self.petSpine and self.petSpine:getName() == modelName then
		return
	elseif self.petSpine then
		self.petSpine:destroy()
	end

	local pos = xyd.tables.modelTable:getPetCardPos(pet:getModelID())
	self.petSpine = xyd.Spine.new(self.modelGroup.gameObject)

	self.petSpine:setInfo(modelName, function ()
		self.petSpine:SetLocalPosition(pos[2], -pos[3] + 204, 0)
		self.petSpine:SetLocalScale(pos[1], pos[1], 1)
		self.petSpine:play("idle", 0)

		local pet = self.petModel:getPetByID(self.id_)

		if pet:getLevel() <= 0 then
			self.petSpine.spAnim.fillColor = Vector4(0, 0, 0, 1)
			self.petSpine.spAnim.fillPhase = 1
		else
			self.petSpine.spAnim.fillPhase = 0
		end

		local firstOne_y = self.parentWindow.fistPetItem_y

		if self.parentWindow and not tolua.isnull(self.parentWindow.window_) then
			self.petSpine:setClipAreaWithScroller(self.parentWindow.petScrollView.gameObject, self.selfgo.gameObject, firstOne_y, Vector4(2, 8, 0, 0), Vector2(-12, -15))
		end
	end)
end

function choosePetItem:onCilckJumpBtn()
	if self.notShowDetail then
		return
	end

	xyd.WindowManager.get():openWindow("pet_detail_window", {
		pet_id = self.id_,
		petType = self.petFormationType
	})

	local win = xyd.WindowManager.get():getWindow("choose_pet_window")

	if win then
		win.window_:SetActive(false)
	end
end

function choosePetItem:setSelectIndex(index)
	self.selectIndex = index

	self:setSelected(self.selectIndex ~= -1)
end

function choosePetItem:setSelected(status)
	if status then
		self.labelOkBtn.text = __("CANCEL")
		local selectSource = "pet_icon0" .. self.selectIndex - 1

		xyd.setUISpriteAsync(self.selectImg, nil, selectSource)
		self.selectImg:SetActive(true)
		self.maskImg:SetActive(true)
		xyd.setBgColorType(self.okBtn, xyd.ButtonBgColorType.white_btn_60_60)
	else
		self.labelOkBtn.text = __("CHOOSE_PET_TEXT02")

		self.selectImg:SetActive(false)
		self.maskImg:SetActive(false)
		xyd.setBgColorType(self.okBtn, xyd.ButtonBgColorType.blue_btn_60_60)
	end
end

local ChoosePetWindow = class("ChoosePetWindow", import(".BaseWindow"))

function ChoosePetWindow:ctor(name, params)
	ChoosePetWindow.super.ctor(self, name, params)

	self.selectIDs = params.select or {
		0,
		0,
		0,
		0
	}
	self.petFormationType = params.type or xyd.PetFormationType.Battle1v1

	if self.petFormationType == xyd.PetFormationType.HeroChallenge then
		self.petModel = xyd.models.heroChallenge
	elseif self.petFormationType == xyd.PetFormationType.ENTRANCE_TEST then
		self.petModel = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	elseif self.petFormationType == xyd.PetFormationType.Battle5v5 then
		self.petModel = xyd.models.petSlot
		self.selectIDs = params.select or {
			0,
			0,
			0,
			0,
			0,
			0,
			0
		}
	else
		self.petModel = xyd.models.petSlot
	end

	self.params = params
	self.excludPets = params.excludPets or {}
end

function ChoosePetWindow:initWindow()
	ChoosePetWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.mainGroup = winTrans:Find("groupAction")
	self.choosePetItem = self.mainGroup:Find("choose_pet_item")

	self.choosePetItem:SetActive(false)

	self.closeBtn = self.mainGroup:Find("close_btn").gameObject
	self.labelWinTitle = self.mainGroup:ComponentByName("title_label", typeof(UILabel))
	self.labelTip = self.mainGroup:ComponentByName("tip_label", typeof(UILabel))
	self.contentGroup = self.mainGroup:Find("content")
	self.petScrollView = self.contentGroup:ComponentByName("pet_scroller", typeof(UIScrollView))
	self.petRenderPanel = self.contentGroup:ComponentByName("pet_scroller", typeof(UIPanel))
	self.petListGrid = self.contentGroup:ComponentByName("pet_scroller/pet_list_grid", typeof(UIGrid))

	self:initPetList()
	self:register()

	self.labelTip.text = __("CHOOSE_PET_TITLE")
end

function ChoosePetWindow:initPetList()
	self.choosePetItemList = {}

	NGUITools.DestroyChildren(self.petListGrid.transform)

	local ids = self.petModel:getPetIDs()

	table.sort(ids, function (a, b)
		local petA = self.petModel:getPetByID(a)
		local petB = self.petModel:getPetByID(b)
		local scoreA = petB:getGrade() < petA:getGrade() and 1000 or 0
		local scoreB = petA:getGrade() < petB:getGrade() and 1000 or 0
		scoreA = petB:getLevel() < scoreA + petA:getLevel() and 100 or 0

		if petA:getLevel() < scoreB + petB:getLevel() then
			scoreB = 100
		else
			scoreB = 0
		end

		if petA:getTableID() < petB:getTableID() then
			scoreA = scoreA + 10
		else
			scoreB = scoreB + 10
		end

		return scoreA > scoreB
	end)

	local data = {}
	local count = 0
	local notShowDetail = self.params.notShowDetail or false

	for _, id in ipairs(ids) do
		if next(self.excludPets) and xyd.arrayIndexOf(self.excludPets, id) > 0 then
			-- Nothing
		else
			count = count + 1
			local time = xyd.tables.petTable:getShowTime(id)

			if not time or xyd.getServerTime() >= time then
				local go = NGUITools.AddChild(self.petListGrid.gameObject, self.choosePetItem.gameObject)

				go:SetActive(true)

				go.name = "pet_item_" .. id

				if count == 1 then
					local noOne_y = self.contentGroup.transform:InverseTransformPoint(go.transform.position).y
					self.fistPetItem_y = noOne_y
				end

				local selectIndex = xyd.arrayIndexOf(self.selectIDs, id)
				local choosePetItem = choosePetItem.new(go, id, self, selectIndex, self.petFormationType, notShowDetail)

				table.insert(self.choosePetItemList, choosePetItem)
			end
		end
	end
end

function ChoosePetWindow:register()
	ChoosePetWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_PET_LIST, self.onGetList, self)
end

function ChoosePetWindow:onGetList()
	self:initPetList()
end

function ChoosePetWindow:selectPet(petID, selectIndex)
	local isSelected = selectIndex ~= -1
	local index = -1
	local oldPet = -1

	if isSelected then
		self.selectIDs[selectIndex] = 0
	else
		index = self:getAvaliablePos()

		if index == -1 then
			return
		end

		oldPet = self.selectIDs[index]
		self.selectIDs[index] = petID
	end

	for _, petItem in ipairs(self.choosePetItemList) do
		if oldPet > 0 and petItem.id_ == oldPet then
			petItem:setSelectIndex(-1)
		end

		if petItem.id_ == petID then
			petItem:setSelectIndex(index)
		end
	end
end

function ChoosePetWindow:getSelectedPos(petID)
	if self.petFormationType == xyd.PetFormationType.Battle1v1 or self.petFormationType == xyd.PetFormationType.HeroChallenge then
		return 1
	else
		for pos, id in ipairs(self.selectIDs) do
			if id == petID then
				return pos
			end
		end
	end
end

function ChoosePetWindow:getAvaliablePos()
	if self.petFormationType == xyd.PetFormationType.Battle1v1 or self.petFormationType == xyd.PetFormationType.HeroChallenge or self.petFormationType == xyd.PetFormationType.ENTRANCE_TEST then
		return 1
	else
		local defaultNum = #self.selectIDs

		if self.petFormationType == xyd.PetFormationType.EXPLORE_OLD_CAMPUS then
			defaultNum = 1 + self.params.levelNum
		elseif self.petFormationType == xyd.PetFormationType.Battle5v5 then
			if self.params.pet_limit_num then
				defaultNum = self.params.pet_limit_num + 1
			elseif self.params.subsitLevel then
				defaultNum = xyd.tables.arenaAllServerRankTable:getPetNum(self.params.subsitLevel) + 1
			else
				defaultNum = xyd.tables.arenaAllServerRankTable:getPetNum(xyd.models.arenaAllServerScore:getRankLevel()) + 1
			end
		end

		for i = 2, defaultNum do
			if self.selectIDs[i] == 0 then
				return i
			end
		end
	end

	return -1
end

function ChoosePetWindow:willClose(params)
	ChoosePetWindow.super.willClose(self, params)

	local wnd1v1 = xyd.WindowManager.get():getWindow("battle_formation_window")

	if wnd1v1 then
		wnd1v1:onChoosePet(self.selectIDs)
	end

	local wndstation = xyd.WindowManager.get():getWindow("station_battle_formation_window")

	if wndstation then
		wndstation:onChoosePet(self.selectIDs)
	end

	local wnd3v3 = xyd.WindowManager.get():getWindow("arena_3v3_battle_formation_window")

	if wnd3v3 then
		wnd3v3:onChoosePet(self.selectIDs)
	end

	local wndAcademy = xyd.WindowManager.get():getWindow("academy_assessment_battle_formation_window")

	if wndAcademy then
		wndAcademy:onChoosePet(self.selectIDs)
	end

	local wnd = xyd.WindowManager.get():getWindow("activity_fairy_tale_formation_window")

	if wnd then
		wnd:onChoosePet(self.selectIDs)
	end

	local wndAllArena = xyd.WindowManager.get():getWindow("arena_all_server_battle_formation_window")

	if wndAllArena then
		wndAllArena:onChoosePet(self.selectIDs)
	end

	local friendBossBattleFormationWin = xyd.WindowManager.get():getWindow("friend_boss_battle_formation_window")

	if friendBossBattleFormationWin then
		friendBossBattleFormationWin:onChoosePet(self.selectIDs)
	end

	local wndTrial = xyd.WindowManager.get():getWindow("battle_formation_trial_window")

	if wndTrial then
		wndTrial:onChoosePet(self.selectIDs)
	end

	local wndExplore = xyd.WindowManager.get():getWindow("adventure_battle_formation_window")

	if wndExplore then
		wndExplore:onChoosePet(self.selectIDs)
	end

	local wndPetTrainLessionDetail = xyd.WindowManager.get():getWindow("pet_training_lesson_detail_window")

	if wndPetTrainLessionDetail then
		wndPetTrainLessionDetail:onChoosePet(self.selectIDs)
	end

	local quickFormationWindow = xyd.WindowManager.get():getWindow("quick_formation_window")

	if quickFormationWindow then
		quickFormationWindow:onChoosePet(self.selectIDs)
	end
end

function ChoosePetWindow:updateInfo(fakeLevel, id)
	for _, petItem in ipairs(self.choosePetItemList) do
		if id ~= nil and tonumber(petItem.id_) == tonumber(id) then
			petItem:updateInfo(fakeLevel)
		else
			petItem:updateInfo(nil)
		end
	end
end

return ChoosePetWindow
