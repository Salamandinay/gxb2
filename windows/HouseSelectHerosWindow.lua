local HouseSelectHeroItem = class("HouseSelectHeroItem")
local HeroIcon = import("app.components.HeroIcon")

function HouseSelectHeroItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.slot = xyd.models.slot

	self:initUI()
end

function HouseSelectHeroItem:getGameObject()
	return self.go
end

function HouseSelectHeroItem:initUI()
	self.heroIcon_ = HeroIcon.new(self.go)

	self.heroIcon_:setDragScrollView(self.parent.scrollView)
end

function HouseSelectHeroItem:update(wrapIndex, index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info

	self:updateInfo()
end

function HouseSelectHeroItem:updateInfo()
	local partner = self.slot:getPartner(self.data.partner_id)
	local noJob = self.data.noJob
	local tableID = partner:getTableID()
	local params = {
		isShowLovePoint = true,
		tableID = tableID,
		lev = partner:getLevel(),
		star = partner:getStar(),
		skin_id = partner.skin_id,
		is_vowed = partner.is_vowed,
		love_point = partner.love_point,
		callback = function ()
			self.heroIcon_.selected = false
			local pos = self:getGameObject().transform.position
			local flag = self.data.parent:selectHero(self.data.partner_id, pos)

			if flag then
				self.heroIcon_:setFloorLabel(flag, "F" .. self.parent.curFloor_)
			end
		end
	}

	self.heroIcon_:setInfo(params)

	local floor = self.data.parent:getFloorAndPos(self.data.partner_id)

	if floor then
		self.heroIcon_:setFloorLabel(true, "F" .. floor)
	else
		self.heroIcon_:setFloorLabel(false)
	end
end

function HouseSelectHeroItem:getHeroIcon()
	return self.heroIcon_
end

local HouseSelectHerosWindow = class("HouseSelectHerosWindow", import(".BaseWindow"))
local HousePartnerTable = xyd.tables.housePartnerTable

function HouseSelectHerosWindow:ctor(name, params)
	HouseSelectHerosWindow.super.ctor(self, name, params)

	self.items_ = {}
	self.selectIndex = 0
	self.house = xyd.models.house
	self.slot = xyd.models.slot
	self.curFloor_ = params.floor or 1
	self.otherFloorHeros_ = {}
	self.herosByFloor = {}
	self.curSelectHeroIcons = {}
	self.openDormNum = self.house:getOpenDormNum()
end

function HouseSelectHerosWindow:initWindow()
	HouseSelectHerosWindow.super.initWindow(self)
	self:getUIComponent()
	self:initData()
	self:layout()
	self:changeFloor(self.curFloor_)
	self:changeGroup(0)
	self:registerEvent()
	self:initFilter()
end

function HouseSelectHerosWindow:initFilter()
	local params = {
		isCanUnSelected = 1,
		scale = 0.95,
		gap = 13,
		callback = handler(self, function (self, group)
			self:changeGroup(group)
		end),
		width = self.groupBtns:GetComponent(typeof(UIWidget)).width,
		chosenGroup = self.selectIndex
	}
	local partnerFilter = import("app.components.PartnerFilter").new(self.groupBtns.gameObject, params)
	self.partnerFilter = partnerFilter
end

function HouseSelectHerosWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupHeros_ = winTrans:NodeByName("groupHeros_").gameObject
	self.groupBtns = self.groupHeros_:NodeByName("groupBtns").gameObject
	local scrollView = self.groupHeros_:ComponentByName("scroller_", typeof(UIScrollView))
	self.scrollView_ = scrollView
	local wrapContent = scrollView:ComponentByName("itemList_", typeof(MultiRowWrapContent))
	local scrolltem = scrollView:NodeByName("item").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent, scrolltem, HouseSelectHeroItem, self)
	self.groupTop_ = winTrans:NodeByName("groupTop_").gameObject
	self.labelTitle_ = self.groupTop_:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = self.groupTop_:NodeByName("closeBtn").gameObject
	self.labelTips_ = self.groupTop_:ComponentByName("labelTips_", typeof(UILabel))
	self.btnCancel_ = self.groupTop_:NodeByName("btnCancel_").gameObject
	self.btnSure_ = self.groupTop_:NodeByName("btnSure_").gameObject

	for i = 1, 5 do
		self["groupHero" .. i] = self.groupTop_:NodeByName("groupSelectHeros/groupHero" .. i).gameObject
	end

	self.groupNav = self.groupTop_:NodeByName("groupNav").gameObject

	for i = 1, 2 do
		local tab = self.groupNav:NodeByName("tab_" .. i).gameObject
		self["tab_" .. i] = tab
		self["tab_chosen_" .. i] = tab:NodeByName("chosen").gameObject
		self["tabLabel_" .. i] = tab:ComponentByName("label", typeof(UILabel))
	end

	self.imgStay = self.groupNav:ComponentByName("imgStay", typeof(UISprite))
	self.tab_lock_2 = self.tab_2:NodeByName("lock").gameObject
	self.tab_unchosen_2 = self.tab_2:ComponentByName("unchosen", typeof(UISprite))
	self.tab_redPoint_2 = self.tab_2:NodeByName("redPoint").gameObject
	self.chooseBtn = self.groupTop_:NodeByName("chooseBtn").gameObject
	self.chosenImg = self.chooseBtn:NodeByName("chosenImg").gameObject
	self.chooseRedPoint = self.chooseBtn:NodeByName("redPoint").gameObject
end

function HouseSelectHerosWindow:playOpenAnimation(callback)
	callback()

	local height = xyd.getWindow("house_window").window_:GetComponent(typeof(UIPanel)).height
	local sequence1 = self:getSequence()
	local transform = self.groupTop_.transform

	transform:SetLocalPosition(0, 500, 0)

	if height > 1280 then
		sequence1:Append(transform:DOLocalMove(Vector3(0, 229, 0), 0.5))
	else
		sequence1:Append(transform:DOLocalMove(Vector3(0, 140, 0), 0.5))
	end

	local w = self.groupHeros_:GetComponent(typeof(UIRect))
	local target = self.window_

	local function setter(value)
		w:SetTopAnchor(target, 1, value)
		w:SetBottomAnchor(target, 0, 0)
		self.scrollView_:ResetPosition()
	end

	local sequence2 = self:getSequence(function ()
		self.scrollView_:ResetPosition()
	end)

	sequence2:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), -1080, -760, 0.5))
end

function HouseSelectHerosWindow:layout()
	self.btnSure_:ComponentByName("button_label", typeof(UILabel)).text = __("SAVE")
	self.btnCancel_:ComponentByName("button_label", typeof(UILabel)).text = __("CANCEL_2")
	self.labelTitle_.text = __("HOUSE_TEXT_22")
	self.labelTips_.text = __("HOUSE_TEXT_62")
	self.tabLabel_1.text = "F1"
	self.tabLabel_2.text = "F2"
	local headId = xyd.models.dress:getEquipedStyles()[1]
	local dressID = xyd.tables.senpaiDressStyleTable:getDressId(headId)
	local list = xyd.tables.senpaiDressTable:getStyles(dressID)
	local type = 1

	for i = 1, #list do
		if list[i] == headId then
			type = i

			break
		end
	end

	local source = type == 1 and "house_dress_girl" or "house_dress_boy"

	xyd.setUISpriteAsync(self.imgStay, nil, source, nil, , true)

	if self.senpaiFloor == 0 then
		self.imgStay:SetActive(false)
	else
		self.imgStay:SetActive(true)
		self.imgStay:X(self.senpaiFloor == 1 and -136 or 201)
	end

	if self.openDormNum < 2 then
		self.tab_lock_2:SetActive(true)
		xyd.setUISpriteAsync(self.tab_unchosen_2, nil, "nav_btn_grey_right")
	else
		self.tab_lock_2:SetActive(false)
	end

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.HOUSE_NEW_FLOOR_2
	}, self.tab_redPoint_2)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.SENPAI_FIRST_IN_HOUSE
	}, self.chooseRedPoint)
end

function HouseSelectHerosWindow:changeFloor(index)
	if self.openDormNum < index then
		xyd.alertTips(__("HOUSE_TEXT_57", xyd.models.house:getOpenComfortNum()))

		return
	end

	if index == 2 and not xyd.db.misc:getValue("house_new_floor_2") then
		xyd.db.misc:setValue({
			value = 1,
			key = "house_new_floor_2"
		})
		xyd.models.redMark:setMark(xyd.RedMarkType.HOUSE_NEW_FLOOR_2, false)
	end

	self.curFloor_ = index

	self:changeToggleState()
	self:updateCurSelectHero()
	self.chosenImg:SetActive(self.curFloor_ == self.senpaiFloor)
end

function HouseSelectHerosWindow:changeToggleState()
	if self.curFloor_ == 1 then
		self.tab_chosen_1:SetActive(true)
		self.tab_chosen_2:SetActive(false)

		self.tabLabel_1.color = Color.New2(4278124287.0)
		self.tabLabel_1.effectColor = Color.New2(1012112383)
		self.tabLabel_2.color = Color.New2(960513791)
		self.tabLabel_2.effectColor = Color.New2(4294967295.0)
	else
		self.tab_chosen_1:SetActive(false)
		self.tab_chosen_2:SetActive(true)

		self.tabLabel_2.color = Color.New2(4278124287.0)
		self.tabLabel_2.effectColor = Color.New2(1012112383)
		self.tabLabel_1.color = Color.New2(960513791)
		self.tabLabel_1.effectColor = Color.New2(4294967295.0)
	end
end

function HouseSelectHerosWindow:initData()
	local sortPartners = self.slot:getSortedPartners()

	for i = 0, xyd.GROUP_NUM do
		local collection = {}
		self.items_[i] = collection
		local partners = sortPartners[tostring(xyd.partnerSortType.LEV) .. "_" .. i]

		for _, id in ipairs(partners) do
			table.insert(collection, {
				noJob = true,
				partner_id = id,
				parent = self
			})
		end
	end

	local ids = self.house:getHeroIDs()

	for i = 1, 2 do
		self.herosByFloor[i] = {}

		for j = 1, 5 do
			table.insert(self.herosByFloor[i], ids[j + (i - 1) * 5] or 0)
		end
	end

	for i = 1, 5 do
		local group = self["groupHero" .. tostring(i)]
		local icon = HeroIcon.new(group)

		table.insert(self.curSelectHeroIcons, icon)
	end

	self.senpaiFloor = self.house:getSenpaiFloor()
end

function HouseSelectHerosWindow:changeDataGroup()
	local infos = self.items_[self.selectIndex] or {}

	self.multiWrap_:setInfos(infos, {})
end

function HouseSelectHerosWindow:registerEvent()
	self:register()

	for i = 1, 2 do
		UIEventListener.Get(self["tab_" .. i]).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)
			self:changeFloor(i)
		end
	end

	UIEventListener.Get(self.btnSure_).onClick = handler(self, self.sureTouch)
	UIEventListener.Get(self.btnCancel_).onClick = handler(self, self.cancelTouch)

	for i = 1, 5 do
		local obj = self["groupHero" .. i]:NodeByName("e:Image").gameObject

		UIEventListener.Get(obj).onClick = function ()
			xyd.showToast(__("HOUSE_TEXT_63"))
		end
	end

	UIEventListener.Get(self.chooseBtn).onClick = function ()
		if not xyd.db.misc:getValue("senpai_first_in_house") then
			xyd.db.misc:setValue({
				value = 1,
				key = "senpai_first_in_house"
			})
			xyd.models.redMark:setMark(xyd.RedMarkType.SENPAI_FIRST_IN_HOUSE, false)
		end

		local oldFloor = self.senpaiFloor

		if self.senpaiFloor == self.curFloor_ then
			self.senpaiFloor = 0

			self.chosenImg:SetActive(false)
		else
			self.senpaiFloor = self.curFloor_

			self.chosenImg:SetActive(true)
		end

		if self.senpaiFloor == 0 then
			self.imgStay:SetActive(false)
		elseif oldFloor ~= 0 then
			self.imgStay:SetActive(true)

			local des = self.senpaiFloor == 1 and -136 or 201

			self.imgStay.transform:DOLocalMove(Vector3(des, 0, 0), 0.2)
		else
			self.imgStay:SetActive(true)
			self.imgStay:X(self.senpaiFloor == 1 and -136 or 201)
		end
	end
end

function HouseSelectHerosWindow:cancelTouch()
	xyd.WindowManager.get():closeWindow(self.name_)
end

function HouseSelectHerosWindow:sureTouch()
	local partners = {}

	for _, ids in ipairs(self.herosByFloor) do
		for _, id in ipairs(ids) do
			table.insert(partners, id)
		end
	end

	self.house:reqSaveHeros(partners, self.senpaiFloor)
	xyd.WindowManager.get():closeWindow(self.name_)
end

function HouseSelectHerosWindow:changeGroup(index)
	if self.selectIndex == index then
		self.selectIndex = 0
	else
		self.selectIndex = index
	end

	self:changeDataGroup()
end

function HouseSelectHerosWindow:updateCurSelectHero()
	local partners = self.herosByFloor[self.curFloor_]

	for i = 1, 5 do
		if partners[i] > 0 then
			local partnerID = partners[i]
			local partner = self.slot:getPartner(partnerID)
			local tableID = partner:getTableID()

			self.curSelectHeroIcons[i]:setInfo({
				isShowLovePoint = true,
				tableID = tableID,
				partnerID = partnerID,
				star = partner:getStar(),
				love_point = partner.love_point,
				is_vowed = partner.is_vowed,
				skin_id = partner.skin_id,
				lev = partner:getLevel(),
				callback = function ()
					self:unSelectHero(i)
				end
			})
			self.curSelectHeroIcons[i]:SetActive(true)
			self.curSelectHeroIcons[i]:SetLocalPosition(0, 0, 0)
		else
			self.curSelectHeroIcons[i]:SetActive(false)
		end
	end
end

function HouseSelectHerosWindow:selectHero(partnerID, pos)
	local curPos = self:checkSelect(partnerID)

	if type(curPos) == "number" and curPos > 0 then
		self:unSelectHero(curPos)

		return false
	end

	local indexPos = self:getEmptyPos()

	if indexPos == nil then
		xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_61"))

		return false
	end

	local function selectPartner()
		local partner = self.slot:getPartner(partnerID)
		local tableID = partner:getTableID()
		self.herosByFloor[self.curFloor_][indexPos] = partnerID
		local copyHero = self.curSelectHeroIcons[indexPos]

		copyHero:setInfo({
			isShowLovePoint = true,
			tableID = tableID,
			partnerID = partnerID,
			star = partner:getStar(),
			love_point = partner.love_point,
			is_vowed = partner.is_vowed,
			skin_id = partner.skin_id,
			lev = partner:getLevel(),
			callback = function ()
				self:unSelectHero(indexPos)
			end
		})
		copyHero:SetActive(true)

		local nPos = self["groupHero" .. indexPos].transform:InverseTransformPoint(pos)

		copyHero:SetLocalPosition(nPos.x, nPos.y, 0)
		copyHero:getGameObject().transform:DOLocalMove(Vector3(0, 0, 0), 0.2)
	end

	if curPos == -1 then
		xyd.alert(xyd.AlertType.YES_NO, __("HOUSE_TEXT_60"), function (yes)
			if yes then
				local floor, p = self:getFloorAndPos(partnerID)
				self.herosByFloor[floor][p] = 0

				selectPartner()

				local item = self:getHeroIconByID(partnerID)

				item:getHeroIcon():setFloorLabel(true, "F" .. self.curFloor_)
			end
		end)
	else
		local partner = self.slot:getPartner(partnerID)
		local modelID = xyd.getModelID(partner:getTableID(), false, partner.skin_id, 1)

		if HousePartnerTable:checkCanAdd(modelID) == false then
			xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_34"))

			return false
		end

		selectPartner()

		return true
	end
end

function HouseSelectHerosWindow:unSelectHero(indexPos)
	local partner_id = self.herosByFloor[self.curFloor_][indexPos]
	self.herosByFloor[self.curFloor_][indexPos] = 0
	local item = self:getHeroIconByID(partner_id)
	local action = self:getSequence()
	local obj = self.curSelectHeroIcons[indexPos]

	obj:SetLocalPosition(0, 0, 0)

	if not item then
		action:Append(obj:getGameObject().transform:DOLocalMove(Vector3(-200, -200, 0), 0.2)):AppendCallback(function ()
			obj:SetActive(false)
		end)
	else
		item:getHeroIcon():setFloorLabel(false)

		local pos = item:getGameObject().transform.position
		local nPos = self["groupHero" .. indexPos].transform:InverseTransformPoint(pos)

		action:Append(obj:getGameObject().transform:DOLocalMove(Vector3(nPos.x, nPos.y, 0), 0.2)):AppendCallback(function ()
			obj:SetActive(false)
		end)
	end
end

function HouseSelectHerosWindow:getHeroIconByID(id)
	local items = self.multiWrap_:getItems()
	local child = nil

	for i = 1, #items do
		if items[i].data.partner_id == id then
			child = items[i]

			break
		end
	end

	return child
end

function HouseSelectHerosWindow:getEmptyPos()
	for pos, partner_id in ipairs(self.herosByFloor[self.curFloor_]) do
		if partner_id == 0 then
			return pos
		end
	end

	return nil
end

function HouseSelectHerosWindow:checkSelect(id)
	for pos, partner_id in ipairs(self.herosByFloor[self.curFloor_]) do
		if partner_id == id then
			return pos
		end
	end

	for floor, list in ipairs(self.herosByFloor) do
		if floor ~= self.curFloor_ then
			for _, partner_id in ipairs(list) do
				if partner_id == id then
					return -1
				end
			end
		end
	end

	return false
end

function HouseSelectHerosWindow:getFloorAndPos(id)
	for floor, list in ipairs(self.herosByFloor) do
		for pos, partner_id in ipairs(list) do
			if partner_id == id then
				return floor, pos
			end
		end
	end

	return false
end

return HouseSelectHerosWindow
