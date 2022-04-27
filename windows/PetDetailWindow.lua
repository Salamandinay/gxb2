local BaseWindow = import(".BaseWindow")
local PetDetailWindow = class("PetDetailWindow", BaseWindow)
local CommonTabBar = import("app.common.ui.CommonTabBar")
local PetAttr = class("PetAttr", import("app.components.BaseComponent"))
local PetPasSkill = class("PetPasSkill", import("app.components.BaseComponent"))
local WindowTop = import("app.components.WindowTop")
local GradeGroupItem = class("GradeGroupItem", import("app.components.BaseComponent"))
local PetPasSkillAttr = class("PetPasSkillAttr", import("app.components.CopyComponent"))
local PetGradeUpOk = class("PetGradeUpOk", import("app.components.BaseComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local PetSkillIcon = import("app.components.PetSkillIcon")

function PetDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.petType = params.petType

	if self.petType and self.petType == xyd.PetFormationType.ENTRANCE_TEST then
		self.petModel = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	else
		self.petModel = xyd.models.petSlot
	end

	self.petIDs_ = {}
	self.contents = {}
	self.fakeUseRes = {}
	self.SLIDEHEIGHT = 800
	self.gradeUpPetID = -1
	self.navChosen = 1

	self:initData(params.pet_id)
end

function PetDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initResItem()
	self:updatePet()
	self:refresResItems()
	self:registerEvent()
	self:hideBtn()
end

function PetDetailWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupMain = winTrans:NodeByName("groupMain").gameObject
	local groupMain = self.groupMain
	self.minImgBg = groupMain:ComponentByName("imgMinBg", typeof(UISprite))
	self.imgBg = groupMain:ComponentByName("imgBg", typeof(UITexture))
	self.groupPet = groupMain:NodeByName("groupPet").gameObject
	local groupName = groupMain:NodeByName("groupName").gameObject
	self.labelName = groupName:ComponentByName("labelName", typeof(UILabel))
	local page_guide = groupMain:NodeByName("page_guide").gameObject
	self.arrowLeft = page_guide:ComponentByName("arrowLeft", typeof(UISprite))
	self.arrowRight = page_guide:ComponentByName("arrowRight", typeof(UISprite))
	self.arrowLeftNone = page_guide:ComponentByName("arrowLeftNone", typeof(UISprite))
	self.arrowRightNone = page_guide:ComponentByName("arrowRightNone", typeof(UISprite))
	self.groupBot = groupMain:NodeByName("bottom/groupBot").gameObject
	self.groupContent = self.groupBot:NodeByName("groupContent").gameObject
	local default = self.groupContent:NodeByName("default").gameObject
	self.defaultTab = CommonTabBar.new(default, 2, handler(self, self.onClickNav))
	self.labelAttr = default:ComponentByName("tab_1/label", typeof(UILabel))
	self.labelPasSkill = default:ComponentByName("tab_2/label", typeof(UILabel))
	self.btnReborn = groupMain:NodeByName("bottom/btnReborn").gameObject
	self.effectNode = groupMain:NodeByName("effectNode").gameObject
	self.btnData = groupMain:NodeByName("btnData").gameObject
	self.btnExSkill = groupMain:ComponentByName("bottom/btnExSkill", typeof(UISprite))
	self.labelExSkill = self.btnExSkill:ComponentByName("labelExSkill", typeof(UILabel))
	self.imgTouch = self.groupBot:NodeByName("imgTouch").gameObject
end

function PetDetailWindow:refresResItems()
	BaseWindow.refresResItems(self)
end

function PetDetailWindow:hideBtn()
	if self.petType and self.petType == xyd.PetFormationType.ENTRANCE_TEST then
		self.btnReborn:SetActive(false)
		self.btnData:SetActive(false)
	end
end

function PetDetailWindow:initData(petID)
	local ids = self.petModel:getPetIDs()
	local index = 0

	for i = 1, #ids do
		local id = ids[i]
		local pet = self.petModel:getPetByID(id)

		if pet:getLevel() > 0 then
			table.insert(self.petIDs_, id)
		end

		if id == petID then
			index = #self.petIDs_
		end
	end

	self.currentIdx_ = index
end

function PetDetailWindow:updatePet()
	local id = self.petIDs_[self.currentIdx_]
	self.pet_ = self.petModel:getPetByID(id)

	xyd.setUISpriteAsync(self.btnExSkill, nil, "pet_exskill_" .. id)

	if self.pet_:getExLv() == 0 then
		self.labelExSkill.text = __("PET_EXSKILL_TEXT_02")

		xyd.applyGrey(self.btnExSkill)
	else
		self.labelExSkill.text = __("PET_EXSKILL_TEXT_01", self.pet_:getExLv())

		xyd.applyOrigin(self.btnExSkill)
	end

	self:updateContent()
	self:updatePetImg()
	self:updateTop()
	self:updateArrow()
end

function PetDetailWindow:layout()
	self.labelAttr.text = __("ATTR")
	self.labelPasSkill.text = __("PET_BUFF")
end

function PetDetailWindow:initResItem()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local win = xyd.WindowManager.get():getWindow("choose_pet_window")

	if win then
		local function callback()
			xyd.alert(xyd.AlertType.TIPS, __("IS_IN_BATTLE_FORMATION"))
		end

		local items = {
			{
				hide_plus = true,
				show_tips = true,
				id = xyd.ItemID.MANA,
				callback = callback
			},
			{
				hide_plus = true,
				show_tips = true,
				id = xyd.ItemID.PET_STONE,
				callback = callback
			}
		}

		self.windowTop:setItem(items)
	else
		local items = {
			{
				hide_plus = true,
				show_tips = true,
				id = xyd.ItemID.MANA
			},
			{
				hide_plus = true,
				show_tips = true,
				id = xyd.ItemID.PET_STONE
			}
		}

		self.windowTop:setItem(items)
	end
end

function PetDetailWindow:updateResItem()
	local itemID = nil

	if self.navChosen == 1 then
		itemID = xyd.ItemID.PET_STONE
	else
		itemID = xyd.ItemID.PET_SKILL_EXP
	end

	local function callback()
		xyd.alert(xyd.AlertType.TIPS, __("IS_IN_BATTLE_FORMATION"))
	end

	local win = xyd.WindowManager.get():getWindow("choose_pet_window")
	local items = nil

	if win then
		items = {
			{
				hide_plus = true,
				show_tips = true,
				id = xyd.ItemID.MANA,
				callback = callback
			},
			{
				hide_plus = true,
				show_tips = true,
				id = itemID,
				callback = callback
			}
		}
	else
		items = {
			{
				hide_plus = true,
				show_tips = true,
				id = xyd.ItemID.MANA
			},
			{
				hide_plus = true,
				show_tips = true,
				id = itemID
			}
		}
	end

	self.windowTop:setItem(items)
end

function PetDetailWindow:updateArrow()
	self.arrowLeftNone:SetActive(false)
	self.arrowRightNone:SetActive(false)

	if not self.currentIdx_ or self.currentIdx_ == 0 or self.currentIdx_ == 1 then
		self.arrowLeft:SetActive(false)
		self.arrowLeftNone:SetActive(false)
	else
		self.arrowLeft:SetActive(true)
	end

	if self.currentIdx_ == #self.petIDs_ then
		self.arrowRight:SetActive(false)
		self.arrowRightNone:SetActive(true)
	else
		self.arrowRight:SetActive(true)
	end
end

function PetDetailWindow:updatePetImg()
	local bg_ = xyd.tables.petTable:getPetBg(self.pet_:getPetID())

	self.minImgBg:SetActive(true)
	self.imgBg:SetActive(false)
	xyd.setUISprite(self.minImgBg, nil, tostring(bg_) .. "mini")
	xyd.setUITextureAsync(self.imgBg, "Textures/scenes_web/pet_scene1", function ()
		self.minImgBg:SetActive(false)
		self.imgBg:SetActive(true)
	end)

	local modelID = xyd.tables.petTable:getPetModel(self.pet_:getPetID()) + self.pet_:getGrade() - 1
	local modelName = xyd.tables.modelTable:getModelName(modelID)
	local petDetailPos = xyd.tables.modelTable:getPetDetailPos(modelID)

	if self.dragonbones and self.dragonbones:getName() == modelName then
		return
	elseif self.dragonbones then
		self.dragonbones:destroy()

		self.dragonbones = nil
	end

	self.dragonbones = xyd.Spine.new(self.groupPet)

	self.dragonbones:setInfo(modelName, function ()
		self.dragonbones:SetLocalScale(petDetailPos[1], petDetailPos[1], 1)
		self.dragonbones:play("idle", 0, 1)
	end)
	self.groupPet:SetLocalPosition(0 - petDetailPos[2] / 2, 0 + petDetailPos[3] / 2, 0)
	self.dragonbones:SetLocalPosition(petDetailPos[2], -petDetailPos[3], 0)
end

function PetDetailWindow:registerEvent()
	self.super.register(self)

	UIEventListener.Get(self.btnReborn).onClick = handler(self, self.onRebornTouch)
	UIEventListener.Get(self.btnData).onClick = handler(self, self.onDataTouch)

	UIEventListener.Get(self.btnExSkill.gameObject).onClick = function ()
		if self.isPlayOpenAnimation then
			return
		end

		if self.petType == xyd.PetFormationType.ENTRANCE_TEST then
			local level = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST):getLevel()

			if xyd.tables.activityEntranceTestRankTable:getPetExSkillInherit(level) ~= 1 then
				xyd.alertTips(__("ENTRANCE_TEST_PETCORE_LOCK"))

				return
			end
		end

		local petLv = self.pet_:getLevel()
		local petAttr = self.contents[1]

		if petAttr then
			petLv = petAttr:getLev()

			petAttr:reqLevUp()
		end

		xyd.WindowManager.get():openWindow("pet_evolution_window", {
			petID = self.pet_:getPetID(),
			petLv = petLv,
			petType = self.petType
		})
	end

	UIEventListener.Get(self.arrowLeft.gameObject).onClick = function ()
		if self.isPlayGradeUpAnimation then
			return
		end

		self:onArrowTouch(-1)
	end

	UIEventListener.Get(self.arrowRight.gameObject).onClick = function ()
		if self.isPlayGradeUpAnimation then
			return
		end

		self:onArrowTouch(1)
	end

	UIEventListener.Get(self.groupMain).onDrag = function (go, delta)
		self.slideXY = {
			x = delta.x,
			y = delta.y
		}
		self.isPartnerImgClick = true
	end

	UIEventListener.Get(self.groupMain).onDragEnd = function (go)
		self.isPartnerImgClick = false

		if math.abs(self.slideXY.x) < 50 then
			return
		end

		if self.slideXY.x < 0 then
			self:onArrowTouch(1)
		else
			self:onArrowTouch(-1)
		end
	end

	self.eventProxy_:addEventListener(xyd.event.PET_GRADE_UP, function (event)
		self:onPetGradeUp(event)
	end)
	self.eventProxy_:addEventListener(xyd.event.PET_LEV_UP, function (event)
		self:onPetLevUp(event)
	end)
	self.eventProxy_:addEventListener(xyd.event.PET_SKILL_UP, function (event)
		self:onPetSkillLevUp(event)
	end)
	self.eventProxy_:addEventListener(xyd.event.PET_RESTORE, function (event)
		self:onPetRestore(event)
	end)
	self.eventProxy_:addEventListener(xyd.event.ACTIVE_PET_EXLEVEL, function (event)
		self.labelExSkill.text = __("PET_EXSKILL_TEXT_01", self.pet_:getExLv())

		xyd.applyOrigin(self.btnExSkill)
	end)
	self.eventProxy_:addEventListener(xyd.event.UPGRADE_PET_EXLEVEL, function (event)
		self.labelExSkill.text = __("PET_EXSKILL_TEXT_01", self.pet_:getExLv())

		if self.navChosen == 2 then
			self.contents[self.navChosen]:updateCost()
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.RESET_PET_EXLEVEL, function (event)
		self.labelExSkill.text = __("PET_EXSKILL_TEXT_01", self.pet_:getExLv())

		if self.navChosen == 2 then
			self.contents[self.navChosen]:updateCost()
		end
	end)
end

function PetDetailWindow:onRebornTouch()
	if self.isPlayGradeUpAnimation then
		return
	end

	if self:checkCanReborn() == false then
		xyd.alert(xyd.AlertType.TIPS, __("PET_CANT_RESTORE_TIPS"))

		return
	end

	self:checkSkillChange()

	local petID = self.pet_:getPetID()

	xyd.alert(xyd.AlertType.YES_NO, __("PET_RESTORE_TIPS"), function (yes)
		if yes then
			xyd.models.petSlot:reqRestore(petID)
		end
	end)
end

function PetDetailWindow:onDataTouch()
	local storyDatas = xyd.models.petSlot:getStoryData(self.pet_:getPetID())

	if #storyDatas > 0 then
		xyd.WindowManager.get():openWindow("pet_data_window", {
			petId = self.pet_:getPetID()
		})
	else
		xyd.alertTips(__("THE_PET_HAS_NOT_DATA"))
	end
end

function PetDetailWindow:checkCanReborn()
	local petAttr = self.contents[1]
	local lev = petAttr:getLev()

	if lev > 1 then
		return true
	end

	local petPasSkill = self.contents[2]

	if petPasSkill then
		local pasLev = petPasSkill:getLev(1)

		if pasLev > 1 then
			return true
		end
	else
		local skills = self.pet_:getSkills()

		if skills[1] > 1 then
			return true
		end
	end

	return false
end

function PetDetailWindow:onClickNav(index)
	if self.navChosen == index then
		return
	end

	self.navChosen = index

	self:updateResItem()
	self:checkSkillChange()
	self:updateContent()
end

function PetDetailWindow:onPetRestore(event)
	self.imgTouch:SetActive(true)

	local restoreItems = event.data.restore_items or {}
	self.petRebornEffect_ = xyd.Spine.new(self.effectNode)

	self.petRebornEffect_:setInfo("ui_pet_rebirth", function ()
		if tolua.isnull(self.window_) then
			return
		end

		self.petRebornEffect_:SetLocalPosition(0, 100, 0)
		self:showPetReborn(restoreItems)
	end)
end

function PetDetailWindow:showPetReborn(restoreItems)
	self.petRebornEffect_:play("texiao01", 1, 1, function ()
		self.petRebornEffect_.visible = false

		if #restoreItems > 0 then
			xyd.alertItems(restoreItems)
		end

		self:updatePetImg()
		self:updateContent()

		self.labelExSkill.text = __("PET_EXSKILL_TEXT_02")

		xyd.applyGrey(self.btnExSkill)
		self.imgTouch:SetActive(false)
		self.petRebornEffect_:destroy()

		self.petRebornEffect_ = nil
	end, true)
end

function PetDetailWindow:onArrowTouch(val)
	if val == -1 and self.arrowLeft.gameObject.activeSelf == false or val == 1 and self.arrowRight.gameObject.activeSelf == false then
		return
	end

	if self.isPlay then
		return
	end

	self.currentIdx_ = self.currentIdx_ + val

	self:checkSkillChange()
	self:updatePet()
	self:playSwitchAnimation()
end

function PetDetailWindow:updateTop()
	self.labelName.text = self.pet_:getName()
end

function PetDetailWindow:updateFakeRes(items)
	for i = 1, #items do
		local item = items[i]
		local itemID = items[i].itemID

		if not self.fakeUseRes[item.itemID] then
			self.fakeUseRes[itemID] = 0
		end

		self.fakeUseRes[itemID] = self.fakeUseRes[itemID] + item.itemNum
	end

	self:fixTop()
end

function PetDetailWindow:fixTop()
	local top = self.windowTop
	local itemList = top:getResItemList()
	local i = 1

	while i <= #itemList do
		local item = itemList[i]
		local num = xyd.models.backpack:getItemNumByID(item:getItemID())

		item:setItemNum(num - (self.fakeUseRes[item:getItemID()] or 0))

		i = i + 1
	end
end

function PetDetailWindow:checkItemEnough(itemID, itemNum)
	local fakeNum = self.fakeUseRes[itemID] or 0
	local num = xyd.models.backpack:getItemNumByID(itemID)

	if itemNum <= num - fakeNum then
		return true
	end

	return false
end

function PetDetailWindow:updateContent()
	if not self.contents[self.navChosen] then
		local item = nil

		if self.navChosen == 1 then
			item = PetAttr.new(self.groupContent)
		else
			item = PetPasSkill.new(self.groupContent)
		end

		if item then
			self.contents[self.navChosen] = item
		end
	end

	for i = 1, 2 do
		local item = self.contents[i]

		if i == self.navChosen and item then
			item:setVisible(true)
		elseif item then
			item:setVisible(false)
		end
	end

	if self.contents[self.navChosen] then
		self.contents[self.navChosen]:update(self.pet_, self.petType)
	end
end

function PetDetailWindow:onPetGradeUp()
	self.gradeUpPetID = self.pet_:getPetID()
	self.upgradeEffect_ = xyd.Spine.new(self.effectNode)
	self.isPlayGradeUpAnimation = true

	self.upgradeEffect_:setInfo("ui_pet_upgrade", function ()
		if tolua.isnull(self.window_) then
			return
		end

		self.upgradeEffect_:SetLocalPosition(0, 100, 0)

		if self.gradeUpPetID == self.pet_:getPetID() then
			self:showPetGradeUp()
		end
	end)
end

function PetDetailWindow:showPetGradeUp()
	if not self.upgradeEffect_ then
		return
	end

	self.imgTouch:SetActive(true)
	self.upgradeEffect_:playWithEvent("texiao01", 1, 1, {
		hit = function ()
			self:updatePetImg()
		end,
		Complete = function ()
			self.defaultTab:setTabActive(2, true)

			local petPasSkill = self.contents[2]

			if petPasSkill then
				petPasSkill:setCurIndex(self.pet_:getGrade())
			end

			self:showGradeUpOk()
			self.imgTouch:SetActive(false)
			self.upgradeEffect_:destroy()

			self.upgradeEffect_ = nil
			self.isPlayGradeUpAnimation = false
		end
	}, true)
end

function PetDetailWindow:showGradeUpOk()
	local skillID = self.pet_:getSkillID(self.pet_:getGrade())
	local item = PetGradeUpOk.new(self.window_, {
		skill_id = skillID
	})

	item:playAction(function ()
		self.petGradeUpOk_ = nil

		NGUITools.Destroy(item.go)
	end)

	self.petGradeUpOk_ = item
end

function PetDetailWindow:onPetLevUp(event)
	self.fakeUseRes = {}
	local petAttr = self.contents[1]

	if petAttr and self.navChosen == 1 then
		local petInfo = event.data.pet_info

		if self.pet_:getPetID() == petInfo.pet_id then
			petAttr:levUp()
		end
	end
end

function PetDetailWindow:playLevUpAction()
end

function PetDetailWindow:onPetSkillLevUp(event)
	self.fakeUseRes = {}
	local petPasSkill = self.contents[2]

	if petPasSkill and self.navChosen == 2 then
		local petInfo = event.data.pet_info

		if self.pet_:getPetID() == petInfo.pet_id then
			petPasSkill:levUp()
		end
	end
end

function PetDetailWindow:playSwitchAnimation()
	self.isPlay = true
	self.seq1 = self:getSequence(handler(self, function ()
		self.isPlay = false
	end))
	local seq2 = self:getSequence()
	local groupBot_pos = self.groupContent.transform.localPosition

	self.seq1:Append(self.groupContent.transform:DOLocalMove(Vector3(groupBot_pos.x, groupBot_pos.y - 600, groupBot_pos.z), 0.2))
	self.seq1:Append(self.groupContent.transform:DOLocalMove(groupBot_pos, 0.2))
end

function PetDetailWindow:playOpenAnimation(callback)
	self.isPlayOpenAnimation = true
	self.seqopen1 = self:getSequence()
	self.seqopen2 = self:getSequence()
	self.seqopen4 = self:getSequence(handler(self, function ()
		self:setWndComplete()
		callback()
		self:checkGuide(self.pet_:getLevel())

		self.isPlayOpenAnimation = false
	end))
	local origin_pos = self.groupContent.transform.localPosition

	self.groupContent:SetLocalPosition(720, origin_pos.y, origin_pos.z)
	self.seqopen1:Append(self.groupContent.transform:DOLocalMoveX(-20, 0.2))
	self.seqopen1:Append(self.groupContent.transform:DOLocalMoveX(origin_pos.x, 0.3))

	local pet_origin_pos = self.groupPet.transform.localPosition

	self.groupPet:SetLocalPosition(pet_origin_pos.x - 720, pet_origin_pos.y, pet_origin_pos.z)
	self.seqopen2:Append(self.groupPet.transform:DOLocalMoveX(pet_origin_pos.x + 20, 0.2))
	self.seqopen2:Append(self.groupPet.transform:DOLocalMoveX(pet_origin_pos.x, 0.3))

	local lock_origin_pos = self.btnReborn.transform.localPosition

	self.btnReborn:SetLocalPosition(lock_origin_pos.x + 720, lock_origin_pos.y, lock_origin_pos.z)
	self.seqopen4:Append(self.btnReborn.transform:DOLocalMoveX(lock_origin_pos.x - 20, 0.2):SetDelay(0.1))
	self.seqopen4:Append(self.btnReborn.transform:DOLocalMoveX(lock_origin_pos.x, 0.3))

	self.seqopen3 = self:getSequence()
	local dataBtn_origin_pos = self.btnData.transform.localPosition

	self.btnData:SetLocalPosition(dataBtn_origin_pos.x - 720, dataBtn_origin_pos.y, dataBtn_origin_pos.z)
	self.seqopen3:Append(self.btnData.transform:DOLocalMoveX(dataBtn_origin_pos.x + 20, 0.2):SetDelay(0.1))
	self.seqopen3:Append(self.btnData.transform:DOLocalMoveX(dataBtn_origin_pos.x, 0.3))
end

function PetDetailWindow:checkGuide(lev)
	if self.petType == xyd.PetFormationType.ENTRANCE_TEST then
		return
	end

	local res = xyd.db.misc:getValue("pet_exskill_guide")

	if not res and tonumber(xyd.tables.miscTable:getVal("pet_exskill_open_level")) <= lev then
		xyd.WindowManager:get():openWindow("exskill_guide_window", {
			wnd = self,
			table = xyd.tables.petExskillGuideTable,
			guide_type = xyd.GuideType.PET_EXSKILL
		})
		xyd.db.misc:setValue({
			value = "1",
			key = "pet_exskill_guide"
		})
	end
end

function PetDetailWindow:willClose()
	BaseWindow.willClose(self)
	self:checkSkillChange(true)

	if self.dragonbones then
		self.dragonbones:destroy()

		self.dragonbones = nil
	end

	if self.petGradeUpOk_ then
		self.petGradeUpOk_:dispose()
	end
end

function PetDetailWindow:excuteCallBack(isCloseAll)
	if isCloseAll then
		return
	end

	local win = xyd.WindowManager.get():getWindow("choose_pet_window")

	if win then
		win.window_:SetActive(true)

		if self.tempLevel then
			win:updateInfo(self.tempLevel, self.pet_:getPetID())
		else
			win:updateInfo(0, nil)
		end
	else
		xyd.WindowManager.get():openWindow("pet_window")
	end
end

function PetDetailWindow:checkSkillChange(isClean)
	local petAttr = self.contents[1]

	if petAttr then
		self.tempLevel = petAttr:getLev()
	else
		self.tempLevel = nil
	end

	if isClean == nil then
		isClean = false
	end

	local petAttr = self.contents[1]

	if petAttr then
		petAttr:reqLevUp()
	end

	local petPasSkill = self.contents[2]

	if petPasSkill then
		petPasSkill:reqLevUp()
	end

	if isClean then
		self.contents = {}
	end
end

function PetAttr:ctor(parentGO)
	PetAttr.super.ctor(self, parentGO)

	self.costMana_ = 0
	self.costExp_ = 0
	self.fakeLev_ = 0
	self.clickLevUp_ = false
	self.levUpLongTouchKey_ = -1

	self:layout()
	self:registerEvent()
end

function PetAttr:getScrollView()
	return self.scroller
end

function PetAttr:initUI()
	PetAttr.super.initUI(self)

	local go = self.go
	self.groupMain = go:NodeByName("groupMain").gameObject
	local groupMain = self.groupMain
	local topGroup = groupMain:NodeByName("topGroup").gameObject
	self.labelName = topGroup:ComponentByName("labelName", typeof(UILabel))
	self.labelLev = topGroup:ComponentByName("labelLev", typeof(UILabel))
	self.ns1MultiLabel = topGroup:ComponentByName("ns1:MultiLabel", typeof(UILabel))
	local infoGroup = groupMain:NodeByName("infoGroup").gameObject
	self.gradeGroup = infoGroup:NodeByName("gradeGroup").gameObject
	self.scroller = self.gradeGroup:GetComponent(typeof(UIScrollView))
	self.groupItemContainer = self.gradeGroup:NodeByName("gradeItemContainer").gameObject
	self.labelGrade = infoGroup:ComponentByName("gradeTextGroup/labelGrade", typeof(UILabel))
	self.btnGradeUp = infoGroup:NodeByName("btnGradeUp").gameObject
	self.gMaxLev = groupMain:NodeByName("gMaxLev").gameObject
	self.textMaxLev = self.gMaxLev:ComponentByName("textMaxLev", typeof(UILabel))
	local groupLevUpText = groupMain:NodeByName("groupLevUpText").gameObject
	self.labelLevUp = groupLevUpText:ComponentByName("labelLevUp", typeof(UILabel))
	self.groupLevupCost = groupMain:NodeByName("groupLevupCost").gameObject
	self.labelGoldCost = self.groupLevupCost:ComponentByName("labelGoldCost", typeof(UILabel))
	self.labelExpCost = self.groupLevupCost:ComponentByName("labelExpCost", typeof(UILabel))
	self.btnLevUp = groupMain:NodeByName("btnLevUp").gameObject
	local groupContent = groupMain:NodeByName("groupContent").gameObject
	self.effectCon = groupContent:NodeByName("effectCon").gameObject
	self.groupPetSkillIcon = groupContent:NodeByName("groupPetSkillIcon").gameObject
	self.petSkillIcon = PetSkillIcon.new(self.groupPetSkillIcon)
	local groupText = groupContent:NodeByName("groupText").gameObject
	self.labelSkillLev = groupText:ComponentByName("labelSkillLev", typeof(UILabel))
	self.labelSkillName = groupText:ComponentByName("labelSkillName", typeof(UILabel))
	self.textScorller = groupContent:ComponentByName("textScorller", typeof(UIScrollView))
	self.labelSkillDesc = groupContent:ComponentByName("textScorller/labelSkillDesc", typeof(UILabel))
	self.e_Imageleft = self.groupLevupCost:ComponentByName("e:Imageleft", typeof(UISprite))

	xyd.setUISpriteAsync(self.e_Imageleft, nil, "icon_1")

	self.e_Imageright = self.groupLevupCost:ComponentByName("e:Imageright", typeof(UISprite))

	xyd.setUISpriteAsync(self.e_Imageright, nil, "icon_26")
end

function PetAttr:getPrefabPath()
	return "Prefabs/Components/pet_attr"
end

function PetAttr:layout()
	self.labelGrade.text = __("PET_EVOLVE_TITLE")
	self.labelLevUp.text = __("LEV_UP")
	self.textMaxLev.text = __("MAX_LEV")

	if xyd.Global.lang == "fr_fr" then
		self.ns1MultiLabel.text = "Niv."

		self.ns1MultiLabel.gameObject:X(36.5)
	end
end

function PetAttr:clearLongTouch()
	self.levUpLongTouchFlag = false

	if XYDCo.IsWaitCoroutine("levUpLongTouch") then
		XYDCo.StopWait("levUpLongTouch")
	end

	if XYDCo.IsWaitCoroutine("levUpLongTouchClick") then
		XYDCo.StopWait("levUpLongTouchClick")
	end
end

function PetAttr:registerEvent()
	local function callback(self, isPressed)
		local longTouchFunc = nil

		function longTouchFunc()
			if self.type and self.type == xyd.PetFormationType.ENTRANCE_TEST then
				return
			end

			if self.levUpLongTouchFlag == true then
				if not self:levUpTouch() then
					self:clearLongTouch()

					return
				end

				self:waitForTime(0.2, function ()
					if not self then
						return
					end

					longTouchFunc()
				end, "levUpLongTouchClick")
			end
		end

		if isPressed then
			self.levUpLongTouchFlag = true

			self:waitForTime(0.5, function ()
				if not self then
					return
				end

				if self.levUpLongTouchFlag then
					longTouchFunc()
				end
			end, "levUpLongTouch")
		elseif isPressed ~= nil then
			if self.type and self.type == xyd.PetFormationType.ENTRANCE_TEST then
				xyd.alertTips(__("ENTRANCE_TEST_PET_CANNOT_UPGRADE"))

				return
			end

			self:clearLongTouch()
			self:levUpTouch()
		end
	end

	xyd.setDarkenBtnBehavior(self.btnLevUp, self, callback, callback)

	UIEventListener.Get(self.groupMain).onPress = function (isPressed)
		if not isPressed then
			self:clearLongTouch()
		end
	end

	xyd.setDarkenBtnBehavior(self.btnGradeUp, self, self.gradeUpTouch)
end

function PetAttr:checkItemEnough(itemID, itemNum)
	local wnd = xyd.WindowManager.get():getWindow("pet_detail_window")
	local flag = false

	if wnd then
		flag = wnd:checkItemEnough(itemID, itemNum)
	end

	return flag
end

function PetAttr:levUpTouch()
	if not self:checkItemEnough(xyd.ItemID.PET_STONE, self.costExp_) then
		local name_ = xyd.tables.itemTable:getName(xyd.ItemID.PET_STONE)

		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", name_))
		self:reqLevUp()

		return false
	elseif not self:checkItemEnough(xyd.ItemID.MANA, self.costMana_) then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_MANA"))
		self:reqLevUp()

		return false
	end

	self.fakeLev_ = self.fakeLev_ + 1
	local lev = self:getLev()

	if lev == self.pet_:getMaxLev(self.pet_:getGrade()) or not self:checkLevUpEnough(lev) then
		self:reqLevUp()

		return false
	else
		self:fakeLevUp()

		return true
	end
end

function PetAttr:checkLevUpEnough(lev)
	local flag = true

	if lev < self.pet_:getMaxLev(self.pet_:getGrade()) then
		local cost = xyd.tables.expPetTable:getCostByLev(self.pet_:getTableID(), lev)
		local mana = 0
		local coin = 0

		if cost and cost[1] and cost[1][2] then
			mana = cost[1][2]
		end

		if cost and cost[2] and cost[2][2] then
			coin = cost[2][2]
		end

		if not self:checkItemEnough(xyd.ItemID.MANA, mana) then
			flag = false
		end

		if not self:checkItemEnough(xyd.ItemID.PET_STONE, coin) then
			flag = false
		end
	end

	return flag
end

function PetAttr:reqLevUp()
	if self.fakeLev_ > 0 then
		xyd.models.petSlot:reqLevUp(self.pet_:getPetID(), self.fakeLev_)

		self.fakeLev_ = 0
	end
end

function PetAttr:fakeLevUp()
	local params = {}

	table.insert(params, {
		itemID = xyd.ItemID.PET_STONE,
		itemNum = self.costExp_
	})
	table.insert(params, {
		itemID = xyd.ItemID.MANA,
		itemNum = self.costMana_
	})

	local win = xyd.WindowManager.get():getWindow("pet_detail_window")

	if win then
		win:updateFakeRes(params)
		win:checkGuide(self:getLev())
	end

	self:levUp()
end

function PetAttr:levUp()
	self:update()
	self:playLevUpAction()
end

function PetAttr:dispose()
	PetAttr.super.dispose(self)

	if self.shengjiEffect_ then
		self.shengjiEffect_:destroy()

		self.shengjiEffect_ = nil
	end
end

function PetAttr:playLevUpAction()
	if self.shengjiEffect_ ~= nil and self.isPlayUpSkinEffect ~= nil and self.isPlayUpSkinEffect == true then
		return
	end

	if self.shengjiEffect_ == nil then
		self.shengjiEffect_ = xyd.Spine.new(self.effectCon)
		self.isPlayUpSkinEffect = true

		self.shengjiEffect_:setInfo("ui_pet_skill_up", handler(self, function ()
			self.shengjiEffect_:play("texiao01", 1, 1, function ()
				self.shengjiEffect_:SetActive(false)

				self.isPlayUpSkinEffect = false
			end)
		end))
	else
		self.isPlayUpSkinEffect = true

		self.shengjiEffect_:SetActive(true)
		self.shengjiEffect_:play("texiao01", 1, 1, function ()
			self.shengjiEffect_:SetActive(false)

			self.isPlayUpSkinEffect = false
		end)
	end

	local seq = self:getSequence()
	local tScale = self.labelLev.gameObject.transform.localScale

	seq:Append(self.labelLev.gameObject.transform:DOScale(Vector3(1.27, 1.27, 1), 0.2))
	seq:Append(self.labelLev.gameObject.transform:DOScale(Vector3(1, 1, 1), 0.4))
end

function PetAttr:getLev()
	local lev = self.pet_:getLevel() + self.fakeLev_

	return lev
end

function PetAttr:gradeUpTouch()
	xyd.WindowManager.get():openWindow("pet_grade_up_window", {
		pet = self.pet_
	})
end

function PetAttr:update(pet, petType)
	if pet then
		self.pet_ = pet
	end

	self.labelLev.text = tostring(self:getLev()) .. "/" .. tostring(self.pet_:getMaxLev(self.pet_:getGrade()))
	self.labelName.text = self.pet_:getName()

	self:updateSkill()
	self:updateCost()
	self:updateGrade()

	self.type = petType
end

function PetAttr:updateSkill()
	self.labelSkillLev.text = "LV." .. tostring(self:getLev())

	if xyd.Global.lang == "fr_fr" then
		self.labelSkillLev.text = "Niv." .. tostring(self:getLev())
	end

	local energyID = self.pet_:getEnergyID() + self.fakeLev_
	self.labelSkillName.text = xyd.tables.skillTable:getName(energyID)
	self.labelSkillDesc.text = xyd.tables.skillTable:getDesc(energyID)

	self.petSkillIcon:setInfo(energyID, {})
	self.textScorller:ResetPosition()
end

function PetAttr:updateCost()
	local lev = self:getLev()

	if lev < self.pet_:getMaxLev(self.pet_:getGrade()) then
		local cost = xyd.tables.expPetTable:getCostByLev(self.pet_:getTableID(), lev)
		local mana = 0
		local coin = 0

		if cost and cost[1] and cost[1][2] then
			mana = cost[1][2]
			self.labelGoldCost.text = xyd.getRoughDisplayNumber(mana)
			self.costMana_ = mana
		end

		if cost and cost[2] and cost[2][2] then
			coin = cost[2][2]
			self.labelExpCost.text = xyd.getRoughDisplayNumber(coin)
			self.costExp_ = coin
		end

		local flag = false

		if not self:checkItemEnough(xyd.ItemID.MANA, mana) then
			self.labelGoldCost.color = Color.New2(3422556671.0)
			flag = true
		else
			self.labelGoldCost.color = Color.New2(1432789759)
		end

		if not self:checkItemEnough(xyd.ItemID.PET_STONE, coin) then
			self.labelExpCost.color = Color.New2(3422556671.0)
			flag = true
		else
			self.labelExpCost.color = Color.New2(1432789759)
		end

		if flag and self.fakeLev_ > 0 then
			self:reqLevUp()
		end

		self.groupLevupCost:SetActive(true)
		self.btnLevUp:SetActive(true)
		self.gMaxLev:SetActive(false)
	else
		self.groupLevupCost:SetActive(false)
		self.btnLevUp:SetActive(false)
		self.gMaxLev:SetActive(true)
	end
end

function PetAttr:updateGrade()
	local grade = self.pet_:getGrade()
	local maxLev = self.pet_:getMaxLev(grade)
	local lev = self:getLev()

	if not self.gradeItemList then
		self.gradeItemList = {}
	end

	if maxLev <= lev then
		if self.pet_:getMaxGrade() == grade then
			self.btnGradeUp:SetActive(false)
		else
			self.btnGradeUp:SetActive(true)
		end
	else
		self.btnGradeUp:SetActive(false)
	end

	local max_grade = self.pet_:getMaxGrade()

	for i = 1, max_grade do
		local item = self.gradeItemList[i]

		if not item then
			self.gradeItemList[i] = GradeGroupItem.new(self.groupItemContainer)
			item = self.gradeItemList[i]
		end

		if grade < i then
			item:update({
				hide = true
			})
		else
			item:update({
				hide = false
			})
		end
	end
end

function PetAttr:setVisible(flag)
	self.go:SetActive(flag)
end

function PetPasSkill:ctor(parentGO)
	PetPasSkill.super.ctor(self, parentGO)
	self:setPanelDepth()

	self.costMana_ = 0
	self.costExp_ = 0
	self.fakeLev_ = 0
	self.clickLevUp_ = false
	self.levUpLongTouchKey_ = -1
	self.oldSkillIndex_ = -1
	self.curIndex_ = 1
	self.fakeLevs_ = {}
	self.skillTouchKey_ = -1

	self:layout()
	self:registerEvent()
end

function PetPasSkill:getPrefabPath()
	return "Prefabs/Components/pet_pas_skill"
end

function PetPasSkill:initUI()
	PetPasSkill.super.initUI(self)

	local go = self.go
	self.groupMain = go:NodeByName("groupMain").gameObject
	local groupMain = self.groupMain
	self.imageMaxLev = groupMain:ComponentByName("imageMaxLev", typeof(UISprite))
	self.groupCost = groupMain:NodeByName("groupCost").gameObject
	local costTextGroup = self.groupCost:NodeByName("costTextGroup").gameObject
	self.labelLevUp = costTextGroup:ComponentByName("labelLevUp", typeof(UILabel))
	local costInfoGroup = self.groupCost:NodeByName("costInfoGroup").gameObject
	self.labelGoldCost = costInfoGroup:ComponentByName("labelGoldCost", typeof(UILabel))
	self.labelExpCost = costInfoGroup:ComponentByName("labelExpCost", typeof(UILabel))
	self.btnLevUp = self.groupCost:NodeByName("btnLevUp").gameObject
	self.scroller = groupMain:ComponentByName("scroller", typeof(UIScrollView))
	self.groupAttr = groupMain:NodeByName("scroller/groupAttr")
	local wrapContent = self.groupAttr:GetComponent(typeof(MultiRowWrapContent))
	self.attr_item = groupMain:NodeByName("scroller/pet_pas_skill_attr").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.scroller, wrapContent, self.attr_item, PetPasSkillAttr, self)
	local panel = groupMain:ComponentByName("scroller", typeof(UIPanel))
	local groupSkills = groupMain:NodeByName("groupSkills").gameObject
	self.effectNode = groupSkills:NodeByName("effectNode").gameObject

	for i = 1, 4 do
		self["petSkillIconGroup" .. tostring(i)] = groupSkills:NodeByName("petSkillIconGroup" .. tostring(i)).gameObject
		self["petSkillIcon" .. tostring(i)] = PetSkillIcon.new(self["petSkillIconGroup" .. tostring(i)])
	end

	self.groupTips = groupMain:NodeByName("groupTips").gameObject
	self.e_Imageleft = costInfoGroup:ComponentByName("e:Imageleft", typeof(UISprite))

	xyd.setUISpriteAsync(self.e_Imageleft, nil, "icon_1")

	self.e_Imageright = costInfoGroup:ComponentByName("e:Imageright", typeof(UISprite))

	xyd.setUISpriteAsync(self.e_Imageright, nil, "icon_27")
end

function PetPasSkill:getScrollView()
	return self.scroller
end

function PetPasSkill:layout()
	self.labelLevUp.text = __("LEV_UP")

	xyd.setUISpriteAsync(self.imageMaxLev, nil, "pet_skill_max_" .. tostring(xyd.Global.lang), function ()
		self.imageMaxLev:MakePixelPerfect()
	end)
end

function PetPasSkill:updateAttr()
	local attrs = self:getAttrs()
	local infos = {}

	for attr in pairs(attrs) do
		table.insert(infos, {
			buff = attrs[attr].name,
			num = attrs[attr].value
		})
	end

	self.wrapContent:setInfos(infos, {})
end

function PetPasSkill:registerEvent()
	for i = 1, 4 do
		local btn = self["petSkillIconGroup" .. tostring(i)]

		if btn then
			UIEventListener.Get(btn).onPress = function (go, isPressed)
				if isPressed then
					self:onTouchBegin(i)
				elseif XYDCo.IsWaitCoroutine("ShowTips") then
					XYDCo.StopWait("ShowTips")
					self:onTouchSkill(i)
				else
					self:onTouchEnd()
				end
			end
		end
	end

	UIEventListener.Get(self.groupMain).onPress = function (go, isPressed)
		if not isPressed then
			self:onTouchEnd()
			self:clearLongTouch()
		end
	end

	local function callback(self, isPressed)
		local longTouchFunc = nil

		function longTouchFunc()
			if self.type and self.type == xyd.PetFormationType.ENTRANCE_TEST then
				return
			end

			if not self:levUpTouch() then
				self.clearLongTouch()

				return
			end

			self:waitForTime(0.2, function ()
				if not self then
					return
				end

				longTouchFunc()
			end, "levUpLongTouchClick")
		end

		if isPressed then
			self:waitForTime(0.5, function ()
				if not self then
					return
				end

				longTouchFunc()
			end, "levUpLongTouch")
		elseif isPressed ~= nil then
			if self.type and self.type == xyd.PetFormationType.ENTRANCE_TEST then
				xyd.alertTips(__("ENTRANCE_TEST_PET_CANNOT_UPGRADE"))

				return
			end

			self:clearLongTouch()
			self:levUpTouch()
		end
	end

	xyd.setDarkenBtnBehavior(self.btnLevUp, self, callback, callback)
end

function PetPasSkill:clearLongTouch()
	if XYDCo.IsWaitCoroutine("levUpLongTouch") then
		XYDCo.StopWait("levUpLongTouch")
	end

	if XYDCo.IsWaitCoroutine("levUpLongTouchClick") then
		XYDCo.StopWait("levUpLongTouchClick")
	end
end

function PetPasSkill:levUpLongTouch(flag)
	if flag == nil then
		flag = true
	end

	self.clickLevUp_ = flag

	if flag then
		self.levUpLongTouchKey_ = egret:setTimeout(function ()
			if not self.stage then
				return
			end

			if not self.levUpLongTouchTimer then
				self.levUpLongTouchTimer = egret.Timer.new(200)

				self.levUpLongTouchTimer:addEventListener(egret.TimerEvent.TIMER, self.levUpTouch, self)
			end

			if self.clickLevUp_ then
				self.levUpLongTouchTimer:start()
			end
		end, self, 500)
	else
		if self.levUpLongTouchTimer then
			self.levUpLongTouchTimer:stop()
		end

		if self.levUpLongTouchKey_ > -1 then
			egret:clearTimeout(self.levUpLongTouchKey_)

			self.levUpLongTouchKey_ = -1
		end
	end
end

function PetPasSkill:levUpTouch()
	if self:checkCanLevUp() then
		self.fakeLevs_[self.curIndex_] = (self.fakeLevs_[self.curIndex_] or 0) + 1
		local curLev = self:getLev()
		local skillID = self:getSkillID()

		if self:getCurMaxLev() <= curLev or not self:checkLevUpEnough(curLev) then
			self:reqLevUp()

			return false
		else
			self:fakeLevUp()

			return true
		end
	else
		self:reqLevUp()

		return false
	end
end

function PetPasSkill:checkLevUpEnough(lev)
	local flag = true
	local skillID = self:getSkillID()
	local maxLev = xyd.MAX_PET_PAS_SKILL_LEV

	if lev < maxLev then
		local cost = xyd.tables.petSkillTable:getCost(skillID)
		local mana = 0
		local coin = 0

		if cost and cost[1] and cost[1][2] then
			mana = cost[1][2]
		end

		if cost and cost[2] and cost[2][2] then
			coin = cost[2][2]
		end

		if not self:checkItemEnough(xyd.ItemID.MANA, mana) then
			flag = false
		end

		if not self:checkItemEnough(xyd.ItemID.PET_SKILL_EXP, coin) then
			flag = false
		end
	end

	return flag
end

function PetPasSkill:getCurMaxLev()
	local exLv = self.pet_:getExLv()
	local addList = xyd.split(xyd.tables.miscTable:getVal("pet_exlevel_add_pas"), "|", true)
	local index = math.floor(exLv / 5)

	if index == 0 then
		index = 1
	end

	return xyd.BASE_PET_PAS_SKILL_LEV + addList[index]
end

function PetPasSkill:fakeLevUp()
	local params = {}

	table.insert(params, {
		itemID = xyd.ItemID.PET_SKILL_EXP,
		itemNum = self.costExp_
	})
	table.insert(params, {
		itemID = xyd.ItemID.MANA,
		itemNum = self.costMana_
	})

	local win = xyd.WindowManager.get():getWindow("pet_detail_window")

	if win then
		win:updateFakeRes(params)
	end

	self:levUp()
end

function PetPasSkill:levUp()
	self:update()
	self:playLevUpAction()
end

function PetPasSkill:dispose()
	PetPasSkill.super.dispose(self)

	if self.shengjiEffect_ then
		self.shengjiEffect_:destroy()

		self.shengjiEffect_ = nil
	end
end

function PetPasSkill:playLevUpAction()
	if self.oldSkillIndex_ ~= -1 and self.oldSkillIndex_ ~= self.curIndex_ then
		self.oldSkillIndex_ = self.curIndex_

		return
	elseif self.isPlayShengjiEffect_ then
		return
	end

	self.isPlayShengjiEffect_ = true

	if not self.shengjiEffect_ then
		self.shengjiEffect_ = xyd.Spine.new(self.effectNode)

		self.shengjiEffect_:setInfo("ui_pet_skill_up", handler(self, function ()
			self.shengjiEffect_:play("texiao01", 1, 1, function ()
				self.shengjiEffect_:SetActive(false)

				self.isPlayShengjiEffect_ = false
			end)
		end))
	else
		self.shengjiEffect_:SetActive(true)
		self.shengjiEffect_:play("texiao01", 1, 1, function ()
			self.shengjiEffect_:SetActive(false)

			self.isPlayShengjiEffect_ = false
		end, true)
	end

	local x = self["petSkillIconGroup" .. tostring(self.curIndex_)]:X()

	self.effectNode:SetLocalPosition(x, 0, 0)
end

function PetPasSkill:checkItemEnough(itemID, itemNum)
	local wnd = xyd.WindowManager.get():getWindow("pet_detail_window")
	local flag = false

	if wnd then
		flag = wnd:checkItemEnough(itemID, itemNum)
	end

	return flag
end

function PetPasSkill:checkCanLevUp()
	local curMaxLev = self:getCurMaxLev()

	if curMaxLev <= self:getLev() then
		local addList = xyd.split(xyd.tables.miscTable:getVal("pet_exlevel_add_pas"), "|", true)
		local curAdd = curMaxLev - xyd.BASE_PET_PAS_SKILL_LEV
		local nextAddIndex = 1

		for i = 1, #addList do
			if curAdd < addList[i] then
				nextAddIndex = i

				break
			end
		end

		xyd.showToast(__("PET_EXSKILL_TIPS_01", nextAddIndex * 5))

		return false
	end

	if not self:checkItemEnough(xyd.ItemID.PET_SKILL_EXP, self.costExp_) then
		local name_ = xyd.tables.itemTable:getName(xyd.ItemID.PET_SKILL_EXP)

		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", name_))

		return
	elseif not self:checkItemEnough(xyd.ItemID.MANA, self.costMana_) then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_MANA"))

		return
	end

	return true
end

function PetPasSkill:update(pet, petType)
	if pet then
		self.pet_ = pet
		self.curIndex_ = 1
		self.fakeLevs_ = {}
		self.oldSkillIndex_ = -1
	end

	self:updateSkills()
	self:updateCost()
	self:updateAttr()
	self:updateBtnSelect()

	self.type = petType
end

function PetPasSkill:setCurIndex(val)
	if self.curIndex_ == val then
		return
	end

	self.curIndex_ = val

	self:update()
end

function PetPasSkill:checkSkillUnLock(index)
	local lev = self:getLev(index)

	if lev and lev > 0 then
		return true
	end

	return false
end

function PetPasSkill:updateSkills()
	local skills = self.pet_:getSkills()
	local i = 1

	while i <= 4 do
		local skillID = self:getSkillID(i)
		local btn = self["petSkillIcon" .. tostring(i)]

		if btn then
			local info = {
				showLev = true,
				unlocked = self:checkSkillUnLock(i),
				lev = self:getLev(i),
				unlockGrade = i
			}

			btn:setInfo(skillID, info)
		end

		i = i + 1
	end
end

function PetPasSkill:getLev(index)
	local curIndex = index and function ()
		return index
	end or function ()
		return self.curIndex_
	end()
	local skills = self.pet_:getSkills()
	local lev = (skills[curIndex] or 0) + (self.fakeLevs_[curIndex] or 0)

	return lev
end

function PetPasSkill:getSkillID(id)
	local index = nil

	if not id or id == 0 then
		index = self.curIndex_
	else
		index = id
	end

	local skillID = self.pet_:getSkillID(index)
	local lev = self:getLev(index)
	local trueSkillID = skillID

	if lev > 0 then
		trueSkillID = xyd.tables.petSkillTable:getIdByLev(skillID, lev)
	end

	return trueSkillID
end

function PetPasSkill:getAttrs()
	local skillIDs = self.pet_:getPasSkillIDs()
	local attr = {}
	local i = 1

	while i <= 4 do
		if self:checkSkillUnLock(i) then
			local skillID = self:getSkillID(i)
			local effects = xyd.tables.petSkillTable:getEffect(skillID)

			for k, v in pairs(effects) do
				local isHave = false
				local index = nil

				for j in pairs(attr) do
					if attr[j].name == v[1] then
						isHave = true
						index = j

						break
					end
				end

				if isHave == false then
					local params = {
						value = 0,
						name = v[1]
					}

					table.insert(attr, params)

					index = #attr
				end

				attr[index].value = attr[index].value + v[2]
			end
		end

		i = i + 1
	end

	return attr
end

function PetPasSkill:updateCost()
	local lev = self:getLev()
	local skillID = self:getSkillID()
	local maxLev = xyd.MAX_PET_PAS_SKILL_LEV

	if lev < maxLev then
		local cost = xyd.tables.petSkillTable:getCost(skillID)
		local mana = 0
		local coin = 0

		if cost and cost[1] and cost[1][2] then
			mana = cost[1][2]
			self.labelGoldCost.text = xyd.getRoughDisplayNumber(mana)
			self.costMana_ = mana
		end

		if cost and cost[2] and cost[2][2] then
			coin = cost[2][2]
			self.labelExpCost.text = xyd.getRoughDisplayNumber(coin)
			self.costExp_ = coin
		end

		local flag = false

		if not self:checkItemEnough(xyd.ItemID.MANA, mana) then
			self.labelGoldCost.color = Color.New2(3422556671.0)
			flag = true
		else
			self.labelGoldCost.color = Color.New2(1432789759)
		end

		if not self:checkItemEnough(xyd.ItemID.PET_SKILL_EXP, coin) then
			self.labelExpCost.color = Color.New2(3422556671.0)
			flag = true
		else
			self.labelExpCost.color = Color.New2(1432789759)
		end

		if flag then
			self:reqLevUp()
		end

		self.groupCost:SetActive(true)
		self.imageMaxLev:SetActive(false)

		local curMaxLev = self:getCurMaxLev()

		if curMaxLev < maxLev and lev == curMaxLev then
			xyd.applyGrey(self.btnLevUp:GetComponent(typeof(UISprite)))
		else
			xyd.applyOrigin(self.btnLevUp:GetComponent(typeof(UISprite)))
		end
	else
		self.groupCost:SetActive(false)
		self.imageMaxLev:SetActive(true)
	end
end

function PetPasSkill:reqLevUp()
	local num = self.fakeLevs_[self.curIndex_] or 0
	local flag = false

	if num > 0 then
		xyd.models.petSlot:reqPetSkillUp(self.pet_:getPetID(), self.curIndex_, num)

		self.fakeLevs_[self.curIndex_] = 0
		flag = true
	end

	return flag
end

function PetPasSkill:setVisible(flag)
	self.go:SetActive(flag)
end

function PetPasSkill:updateBtnSelect()
	local i = 1

	while i <= 4 do
		local btn = self["petSkillIcon" .. tostring(i)]

		if i == self.curIndex_ then
			btn:setSelect(true)
		else
			btn:setSelect(false)
		end

		i = i + 1
	end
end

function PetPasSkill:onTouchSkill(index)
	if self:checkSkillUnLock(index) and self.curIndex_ ~= index then
		self.oldSkillIndex_ = self.curIndex_
		local flag = self:reqLevUp()
		self.curIndex_ = index

		self:updateCost()
		self:updateBtnSelect()

		if not flag then
			self.oldSkillIndex_ = self.curIndex_
		end
	end
end

function PetPasSkill:onTouchBegin(index)
	if XYDCo.IsWaitCoroutine("ShowTips") then
		XYDCo.StopWait("ShowTips")
	end

	self.choseIndex = index

	self:waitForTime(0.15, function ()
		self:showSkillTips(true, index)
	end, "ShowTips")
end

function PetPasSkill:showSkillTips(flag, index)
	local btn = self["petSkillIcon" .. tostring(index)]

	if btn then
		btn:showTips(flag, self.groupTips, flag)
	end
end

function PetPasSkill:onTouchEnd(event)
	if XYDCo.IsWaitCoroutine("ShowTips") then
		XYDCo.StopWait("ShowTips")
	end

	self:showSkillTips(false, self.choseIndex)
	self:levUpLongTouch(false)
end

function PetPasSkillAttr:ctor(go, petPasSkill)
	PetPasSkillAttr.super.ctor(self, go)

	self.petPasSkill = petPasSkill

	self:setDragScrollView(petPasSkill:getScrollView())
	self:getUIComponent()
end

function PetPasSkillAttr:getUIComponent()
	local go = self.go
	local attrGroup = go:NodeByName("attrGroup").gameObject
	self.labelName = attrGroup:ComponentByName("labelName", typeof(UILabel))
	self.labelNum = go:ComponentByName("labelNum", typeof(UILabel))
end

function PetPasSkillAttr:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data_ = info

	self:layout()
end

function PetPasSkillAttr:layout()
	local buff = self.data_.buff
	local bt = xyd.tables.dBuffTable
	local value = self.data_.num

	if bt:isShowPercent(buff) then
		local factor = tonumber(bt:getFactor(buff))
		value = string.format("%.1f", value * 100 / tonumber(bt:getFactor(buff)))
		value = value .. "%"
	end

	self.labelNum.text = "+" .. value
	self.labelName.text = __(string.upper(buff))
end

function PetGradeUpOk:ctor(parentGO, params)
	PetGradeUpOk.super.ctor(self, parentGO)
	self:setPanelDepth()

	self.skillId = params.skill_id

	self:layout()
end

function PetGradeUpOk:getPrefabPath()
	return "Prefabs/Components/pet_grade_up_ok"
end

function PetGradeUpOk:initUI()
	PetGradeUpOk.super.initUI(self)

	local go = self.go
	local panel = go:GetComponent(typeof(UIPanel))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.labelUnlock = go:ComponentByName("labelUnlock", typeof(UILabel))
	self.labelSkillName = go:ComponentByName("labelSkillName", typeof(UILabel))
	self.skillIcon_ = PetSkillIcon.new(self.groupIcon)
end

function PetGradeUpOk:layout()
	self.labelSkillName.text = __(xyd.tables.petSkillTable:getName(self.skillId))
	self.labelUnlock.text = __("SKILL_UNLOCK")
end

function PetGradeUpOk:playAction(callback)
	local sIcon = self.skillIcon_

	sIcon:setInfo(self.skillId)
	self.groupIcon:SetActive(false)
	self.labelSkillName:SetActive(false)
	self.labelUnlock:SetActive(false)
	self:waitForTime(0.3, function ()
		self.labelUnlock:SetActive(true)

		local seq = self:getSequence()
		self.labelUnlock.alpha = 0.01

		seq:Append(xyd.getTweenAlpha(self.labelUnlock, 1, 0.1))
	end, "PetGradeUpOkLabelUnlock")
	self:waitForTime(0.5, function ()
		self.groupIcon:SetActive(true)

		local seq = self:getSequence()

		seq:Append(self.groupIcon.transform:DOScale(Vector3(1.2, 1.2, 1), 0.1))
		seq:Append(self.groupIcon.transform:DOScale(Vector3(0.95, 0.95, 1), 0.1))
		seq:Append(self.groupIcon.transform:DOScale(Vector3(1, 1, 1), 0.1))
	end, "PetGradeUpOkGroupIcon")
	self:waitForTime(0.7, function ()
		self.labelSkillName:SetActive(true)

		local seq = self:getSequence()
		self.labelSkillName.alpha = 0.01

		self.labelSkillName:SetLocalScale(0.6, 0.6, 1)
		seq:Append(xyd.getTweenAlpha(self.labelSkillName, 1, 0.2))
		seq:Join(self.labelSkillName.transform:DOScale(Vector3(1, 1, 1), 0.2))
	end, nil)
	self:waitForTime(1.3, function ()
		callback()
	end, "PetGradeUpOkCallback")
end

function GradeGroupItem:ctor(parentGO)
	GradeGroupItem.super.ctor(self, parentGO)
end

function GradeGroupItem:initUI()
	GradeGroupItem.super.initUI(self)
	self:getUIComponent()
end

function GradeGroupItem:getUIComponent()
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.img = self.go:ComponentByName("img", typeof(UISprite))
end

function GradeGroupItem:getPrefabPath()
	return "Prefabs/Components/grade_item"
end

function GradeGroupItem:update(info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	if info.hide == false then
		self.img:SetActive(true)
	else
		self.img:SetActive(false)
	end
end

return PetDetailWindow
