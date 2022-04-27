local BaseWindow = import(".BaseWindow")
local EditPictureWindow = class("EditPictureWindow", BaseWindow)
local PartnerCard = import("app.components.PartnerCard")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local PersonPictureItem = class("PersonPictureItem", import("app.common.ui.FixedMultiWrapContentItem"))
local ChosenPartnerItem = class("ChosenPartnerItem", import("app.components.BaseComponent"))
local cjson = require("cjson")
local ItemTable = xyd.tables.itemTable
local PartnerTable = xyd.tables.partnerTable
local PartnerPictureTable = xyd.tables.partnerPictureTable

function EditPictureWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.selfPlayer = xyd.models.selfPlayer
	self.backpack = xyd.models.backpack
	self.items_ = {}
	self.sortState_ = false
	self.sortType = xyd.pictureSortType.DEFAULT
	self.isFirstTouch_ = true
	self.itemClass = PersonPictureItem
	self.confirmCallback_ = params.confirmCallback
	self.chosenPartnerNum = 0
	self.chosenPartnerArray = {}
	self.selectJobIndex = 0
	self.jobSortIsShow = false
	self.selectElementIndex = 7
end

function EditPictureWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initChosenPartnerGroup()
	self:loadFilterFromStorage()
	self:initData(self.sortType)
	self:layout()
	self:registerEvent()
end

function EditPictureWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.sortGroup = groupAction:NodeByName("sortGroup").gameObject
	self.schoolGroup = self.sortGroup:NodeByName("schoolGroup").gameObject

	for i = 1, 6 do
		self["group" .. i] = self.schoolGroup:NodeByName("group" .. i).gameObject
		self["group" .. i .. "_chosen"] = self["group" .. i]:NodeByName("group" .. i .. "_chosen").gameObject
	end

	self.jobGroup = self.sortGroup:NodeByName("jobGroup").gameObject
	self.btnGroup = self.sortGroup:NodeByName("jobGroup/btnGroup").gameObject

	for i = 1, 5 do
		self["jobGroup" .. i] = self.btnGroup:NodeByName("group" .. i).gameObject
		self["jobGroup" .. i .. "_chosen"] = self["jobGroup" .. i]:NodeByName("group" .. i .. "_chosen").gameObject
	end

	self.jobBtn = self.sortGroup:NodeByName("jobBtn").gameObject
	self.sortBtn = self.sortGroup:NodeByName("sortBtn").gameObject
	self.groupSort_ = self.sortGroup:NodeByName("sortPop").gameObject
	self.typeSort = self.groupSort_:NodeByName("typeSort").gameObject
	self.qualitySort = self.groupSort_:NodeByName("qualitySort").gameObject
	self.defaultSort = self.groupSort_:NodeByName("defaultSort").gameObject
	self.scroller_ = groupAction:ComponentByName("scroller_", typeof(UIScrollView))
	local wrapContent = self.scroller_:ComponentByName("groupMain_", typeof(MultiRowWrapContent))
	local item = groupAction:NodeByName("item").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scroller_, wrapContent, item, self.itemClass, self)
	self.sortTap = CommonTabBar.new(nil, 0, handler(self, self.changeSortType))

	self.sortTap:initCustomTabs({
		self.typeSort,
		self.qualitySort,
		self.defaultSort
	}, {
		0,
		1,
		2
	})

	self.sortBtnIcon = self.sortBtn:NodeByName("icon").gameObject
	self.buttomGroup = groupAction:NodeByName("buttomGroup").gameObject
	self.checkBox = self.buttomGroup:ComponentByName("checkBox", typeof(UISprite))
	self.buttomLabel = self.buttomGroup:ComponentByName("label", typeof(UILabel))
	self.itemGroup = self.buttomGroup:NodeByName("itemGroup").gameObject
	self.buttomBtn = self.buttomGroup:NodeByName("btn").gameObject
	self.buttomBtnLabel = self.buttomBtn:ComponentByName("label", typeof(UILabel))
	self.buttomTitle = self.buttomGroup:ComponentByName("topGroup/title", typeof(UILabel))
end

function EditPictureWindow:loadFilterFromStorage()
	local value = xyd.db.misc:getValue("kbn_filter")

	if value then
		local filter = cjson.decode(value)

		if filter and filter.sortType and filter.sortType >= 0 then
			self.sortType = tonumber(filter.sortType)
		else
			self.sortType = xyd.pictureSortType.DEFAULT
		end
	end

	self.sortTap:setTabActive(self.sortType + 1, true)
end

function EditPictureWindow:layout()
	self.labelTitle_.text = __("EDIT_PICTURE_WINDOW")
	self.buttomLabel.text = __("EDIT_PICTURE_SHOWRANDOM")
	self.buttomBtnLabel.text = __("FOR_SURE")
	self.buttomTitle.text = __("EDIT_PICTURE_MEMBER")

	self.groupSort_:SetActive(false)

	local groupIds = xyd.tables.groupTable:getGroupIds()

	for _, id in ipairs(groupIds) do
		self["group" .. tostring(id) .. "_chosen"]:SetActive(false)
	end

	if self.selectElementIndex < 7 and self.selectElementIndex > 0 then
		self["group" .. tostring(self.selectElementIndex) .. "_chosen"]:SetActive(true)
	end

	for i = 1, 5 do
		self["jobGroup" .. tostring(i) .. "_chosen"]:SetActive(false)
	end

	if self.selectJobIndex > 0 then
		self["jobGroup" .. tostring(self.selectJobIndex) .. "_chosen"]:SetActive(true)
	end

	xyd.setBtnLabel(self.sortBtn, {
		text = __("SORT")
	})
	xyd.setBtnLabel(self.typeSort, {
		name = "label",
		text = __("TYPE")
	})
	xyd.setBtnLabel(self.qualitySort, {
		name = "label",
		text = __("GRADE")
	})
	xyd.setBtnLabel(self.defaultSort, {
		name = "label",
		text = __("EMOTION_DEFAULT_TEXT")
	})
	self.sortBtnIcon:SetLocalScale(1, 1, 1)

	self.showRandom = tonumber(xyd.db.misc:getValue("kbn_show_random")) == 1 and true or false

	xyd.setUISpriteAsync(self.checkBox, nil, "setting_up_" .. (self.showRandom and "pick" or "unpick"))
	self.jobGroup:SetActive(self.jobSortIsShow)

	if self.jobSortIsShow then
		xyd.setUISpriteAsync(self.jobBtn:GetComponent(typeof(UISprite)), nil, "btn_sq")
	else
		xyd.setUISpriteAsync(self.jobBtn:GetComponent(typeof(UISprite)), nil, "btn_zk")
	end
end

function EditPictureWindow:willClose()
	BaseWindow.willClose(self)
	self:willCloseFunc()
end

function EditPictureWindow:willCloseFunc()
	self.backpack:clearNewPictures()
	xyd.EventDispatcher:inner():dispatchEvent({
		name = xyd.event.NEW_PICTURES,
		data = {}
	})
	xyd.db.misc:setValue({
		key = "kbn_filter",
		value = cjson.encode({
			index = self.selectElementIndex,
			sortType = self.sortType
		})
	})

	if self.confirmCallback_ then
		self.confirmCallback_()
	end
end

function EditPictureWindow:initData(type)
	local pictures = self.backpack:getPictures()

	if type == nil then
		self:sortPictures(pictures, self.sortType)
	else
		self:sortPictures(pictures, type)
	end

	self.items_ = {}

	for i = 1, 7 do
		self.items_[i] = {}
	end

	for i = 1, #pictures do
		local id = pictures[i]

		if not PartnerTable:checkPuppetPartner(id) then
			local group_ = 0
			local type_ = ItemTable:getType(id)

			if type_ == xyd.ItemType.SKIN or type_ == xyd.ItemType.KANBAN then
				local tableID = PartnerPictureTable:getSkinPartner(id)[1]
				group_ = PartnerTable:getGroup(tableID)
			else
				group_ = PartnerTable:getGroup(id)
			end

			local isSelect = false

			for i = 1, self.chosenPartnerNum do
				if id == self.chosenPartnerArray[i]:getID() then
					isSelect = true
				end
			end

			local item = {
				callbackFunc = function (id, isSelect)
					return self:onItemClick(id, isSelect)
				end,
				id = id,
				isSelect = isSelect
			}

			table.insert(self.items_[tonumber(group_)], item)
			table.insert(self.items_[7], item)
		end
	end

	for i = 1, 7 do
		table.sort(self.items_[i], function (a, b)
			if ItemTable:getType(a.id) ~= ItemTable:getType(b.id) then
				return ItemTable:getType(a.id) == xyd.ItemType.SKIN
			end

			return b.id < a.id
		end)
	end

	self:changeDataGroup(false)
end

function EditPictureWindow:changeDataGroup(keepPosition)
	if self.selectJobIndex ~= 0 then
		local data = self:jobFilter()

		self.multiWrap_:setInfos(data, {
			keepPosition = keepPosition
		})
	else
		self.multiWrap_:setInfos(self.items_[self.selectElementIndex], {
			keepPosition = keepPosition
		})
	end
end

function EditPictureWindow:jobFilter()
	local data = {}

	for i = 1, #self.items_[self.selectElementIndex] do
		local item = self.items_[self.selectElementIndex][i]
		local job = 0
		local type_ = ItemTable:getType(item.id)

		if type_ == xyd.ItemType.SKIN or type_ == xyd.ItemType.KANBAN then
			local tableID = PartnerPictureTable:getSkinPartner(item.id)[1]
			job = PartnerTable:getJob(tableID)
		else
			job = PartnerTable:getJob(item.id)
		end

		if job == self.selectJobIndex then
			table.insert(data, item)
		end
	end

	return data
end

function EditPictureWindow:initChosenPartnerGroup()
	NGUITools.DestroyChildren(self.itemGroup.transform)

	local initChosenArray = xyd.models.selfPlayer:getAllChosenPartner()

	for i = 1, 6 do
		local params = {
			itemID = initChosenArray[i]
		}
		local chosenPerson = ChosenPartnerItem.new(self.itemGroup)

		chosenPerson:setInfo(params)
		table.insert(self.chosenPartnerArray, chosenPerson)

		if params.itemID ~= nil then
			self.chosenPartnerNum = self.chosenPartnerNum + 1
		end
	end
end

function EditPictureWindow:sortPictures(pictures, type_)
	local itemTable = ItemTable
	local partnerTable = PartnerTable

	table.sort(pictures, function (a, b)
		local aTmpType = itemTable:getType(a)
		local bTmpType = itemTable:getType(b)
		local aType = (aTmpType == xyd.ItemType.SKIN or aTmpType == xyd.ItemType.KANBAN) and 1 or 0
		local bType = (bTmpType == xyd.ItemType.SKIN or bTmpType == xyd.ItemType.KANBAN) and 1 or 0
		local aStar = partnerTable:getStar(a)
		local bStar = partnerTable:getStar(b)
		local aGroup = partnerTable:getGroup(a)
		local bGroup = partnerTable:getGroup(b)

		if type_ == xyd.pictureSortType.DEFAULT then
			if aType ~= bType then
				return aType - bType < 0
			elseif aStar ~= bStar then
				return aStar - bStar < 0
			elseif aGroup ~= bGroup then
				return aGroup - bGroup < 0
			else
				return a - b > 0
			end
		elseif type_ == xyd.pictureSortType.TYPE then
			if aType ~= bType then
				return bType - aType < 0
			elseif aStar ~= bStar then
				return aStar - bStar > 0
			elseif aGroup ~= bGroup then
				return aGroup - bGroup < 0
			else
				return a - b > 0
			end
		elseif type_ == xyd.pictureSortType.QUALITY then
			if aType == 0 and bType == 0 then
				if aStar ~= bStar then
					return bStar - aStar < 0
				elseif aGroup ~= bGroup then
					return aGroup - bGroup < 0
				else
					return a - b > 0
				end
			else
				return aType - bType < 0
			end
		end
	end)
end

function EditPictureWindow:registerEvent()
	self:register()

	for i = 1, 6 do
		UIEventListener.Get(self["group" .. i]).onClick = function ()
			self:changeGroup(i)
		end
	end

	for i = 1, 5 do
		UIEventListener.Get(self["jobGroup" .. i]).onClick = function ()
			self:changeJobGroup(i)
		end
	end

	UIEventListener.Get(self.sortBtn).onClick = handler(self, self.onClickSortBtn)
	UIEventListener.Get(self.buttomBtn).onClick = handler(self, self.onClickbuttomBtn)

	for i = 1, #self.chosenPartnerArray do
		UIEventListener.Get(self.chosenPartnerArray[i].go).onClick = handler(self, function ()
			if self.chosenPartnerArray[i]:getID() ~= nil then
				local id = self.chosenPartnerArray[i]:getID()

				self:onItemClick(id, true)
				self:unSelectForMainGroup(id)
			end
		end)
	end

	UIEventListener.Get(self.checkBox.gameObject).onClick = handler(self, function ()
		self.showRandom = not self.showRandom

		xyd.setUISpriteAsync(self.checkBox, nil, "setting_up_" .. (self.showRandom and "pick" or "unpick"))
	end)
	UIEventListener.Get(self.jobBtn).onClick = handler(self, function ()
		self.jobSortIsShow = not self.jobSortIsShow

		self:layout()
	end)
end

function EditPictureWindow:unSelectForMainGroup(itemID)
	for i = 1, #self.items_ do
		for j = 1, #self.items_[i] do
			local item = self.items_[i][j]

			if tonumber(itemID) == tonumber(item.id) then
				item.isSelect = false

				break
			end
		end
	end

	self:changeDataGroup(true)
end

function EditPictureWindow:onClickbuttomBtn()
	if self.chosenPartnerNum == 0 then
		xyd.showToast(__("EDIT_PICTURE_SELECT"))

		return
	end

	local chosenArray = {}

	for i = 1, #self.chosenPartnerArray do
		local id = self.chosenPartnerArray[i]:getID()

		if id ~= nil then
			table.insert(chosenArray, id)
		else
			break
		end
	end

	xyd.models.selfPlayer:editPictures(chosenArray)

	local val = false

	if self.showRandom then
		val = true
	end

	xyd.db.misc:setValue({
		key = "kbn_show_random",
		value = val
	})

	local win = xyd.WindowManager.get():getWindow("main_window")

	win:initPartnerSwitchArrow()
	xyd.WindowManager.get():closeWindow("edit_picture_window")
end

function EditPictureWindow:onItemClick(id, isSelect)
	if isSelect then
		return self:unSelect(id)
	end

	if self.chosenPartnerNum >= 6 then
		xyd.showToast(__("EDIT_PICTURE_LIMIT"))

		return false
	end

	local params = {
		itemID = id
	}
	self.chosenPartnerNum = self.chosenPartnerNum + 1

	self.chosenPartnerArray[self.chosenPartnerNum]:setInfo(params)

	return true
end

function EditPictureWindow:unSelect(id)
	if id == nil then
		return false
	end

	local len = #self.chosenPartnerArray

	for i = 1, len do
		if self.chosenPartnerArray[i]:getID() == id then
			for j = i + 1, len do
				local params = {
					itemID = self.chosenPartnerArray[j]:getID()
				}

				self.chosenPartnerArray[j - 1]:setInfo(params)
			end
		end
	end

	self.chosenPartnerArray[len]:setGrey()

	self.chosenPartnerNum = self.chosenPartnerNum - 1

	return true
end

function EditPictureWindow:changeGroup(index)
	if self.selectElementIndex == index then
		self.selectElementIndex = 7
	else
		self.selectElementIndex = index
	end

	for i = 1, 6 do
		if self.selectElementIndex == i then
			self["group" .. tostring(i) .. "_chosen"]:SetActive(true)
		else
			self["group" .. tostring(i) .. "_chosen"]:SetActive(false)
		end
	end

	self:changeDataGroup(false)
end

function EditPictureWindow:changeJobGroup(index)
	if self.selectJobIndex == index then
		self.selectJobIndex = 0
	else
		self.selectJobIndex = index
	end

	for i = 1, xyd.PartnerJob.LENGTH do
		if self.selectJobIndex == i then
			self["jobGroup" .. i .. "_chosen"]:SetActive(true)
		else
			self["jobGroup" .. i .. "_chosen"]:SetActive(false)
		end
	end

	self:changeDataGroup(false)
end

function EditPictureWindow:onClickSortBtn()
	self.sortState_ = not self.sortState_

	self:movegroupSort_()

	local scaleY = self.sortState_ == true and -1 or 1

	self.sortBtnIcon:SetLocalScale(1, scaleY, 1)
end

function EditPictureWindow:movegroupSort_()
	local height = self.groupSort_:GetComponent(typeof(UIPanel)).height - 68
	local groupSort = self.groupSort_.transform

	if self.sortState_ then
		self.groupSort_:SetActive(true)
		self.groupSort_:SetLocalPosition(groupSort.localPosition.x, height - 58, 0)

		local sequence = self:getSequence()

		sequence:Append(groupSort:DOLocalMoveY(height + 17, 0.1)):Append(groupSort:DOLocalMoveY(height, 0.2))
	else
		local sequence = self:getSequence()

		sequence:Append(groupSort:DOLocalMoveY(height + 17, 0.067)):Append(groupSort:DOLocalMoveY(height - 58, 0.1)):AppendCallback(function ()
			self.groupSort_:SetActive(false)
		end)
	end
end

function EditPictureWindow:changeSortType(sortType)
	if sortType ~= self.sortType then
		self.sortType = sortType

		self:initData()
	end

	if not self.isFirstTouch_ then
		self:onClickSortBtn()
	end

	self.isFirstTouch_ = false
end

function PersonPictureItem:ctor(go, parentGo)
	PersonPictureItem.super.ctor(self, go, parentGo)
end

function PersonPictureItem:initUI()
	self.imgAlert_ = self.go:NodeByName("imgAlert_").gameObject
	self.imgSelect_ = self.go:NodeByName("imgSelect_").gameObject
	self.blackMaskImg = self.go:NodeByName("blackMaskImg").gameObject
	self.partnerCard_ = PartnerCard.new(self.go)

	self.partnerCard_:SetLocalScale(0.9, 0.9, 1)
end

function PersonPictureItem:registerEvent()
	UIEventListener.Get(self.go).onClick = handler(self, self.onTouchPicture)
end

function PersonPictureItem:updateInfo()
	local itemID = self.data.id
	local type_ = ItemTable:getType(itemID)

	if type_ == xyd.ItemType.SKIN or type_ == xyd.ItemType.KANBAN then
		local tableID = PartnerPictureTable:getSkinPartner(itemID)[1]
		local group = PartnerTable:getGroup(tableID)
		local info = {
			is_equip = false,
			skin_id = itemID,
			tableID = tableID,
			group = group
		}

		self.partnerCard_:resetData()
		self.partnerCard_:setSkinCard(info)
	else
		local info = {
			tableID = itemID,
			star = PartnerTable:getStar(itemID)
		}

		self.partnerCard_:resetData()
		self.partnerCard_:setInfo(info)
	end

	if self.data.isSelect then
		self.imgSelect_:SetActive(true)
		self.blackMaskImg:SetActive(true)
	else
		self.imgSelect_:SetActive(false)
		self.blackMaskImg:SetActive(false)
	end
end

function PersonPictureItem:onTouchPicture()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	local res = self.data.callbackFunc(self.data.id, self.data.isSelect)

	if res then
		if self.data.isSelect then
			self.data.isSelect = false

			self.imgSelect_:SetActive(false)
			self.blackMaskImg:SetActive(false)
		else
			self.data.isSelect = true

			self.imgSelect_:SetActive(true)
			self.blackMaskImg:SetActive(true)
		end
	end
end

function PersonPictureItem:getID()
	return self.data.id
end

function ChosenPartnerItem:ctor(parentGO)
	ChosenPartnerItem.super.ctor(self, parentGO)
end

function ChosenPartnerItem:getPrefabPath()
	return "Prefabs/Components/chosen_partner_item"
end

function ChosenPartnerItem:initUI()
	ChosenPartnerItem.super.initUI(self)
	self:getComponent()
end

function ChosenPartnerItem:getComponent()
	local goTrans = self.go.transform
	self.groupIcon = goTrans:ComponentByName("groupIcon", typeof(UISprite))
	self.frameImg = goTrans:ComponentByName("frameImg", typeof(UISprite))
	self.partnerImg = goTrans:ComponentByName("partnerImg", typeof(UISprite))
	self.nullImg = goTrans:ComponentByName("nullImg", typeof(UISprite))
end

function ChosenPartnerItem:setInfo(params)
	self.itemID = params.itemID

	self:layout()
end

function ChosenPartnerItem:layout()
	if self.itemID then
		local type = ItemTable:getType(self.itemID)
		local tableID, group = nil

		if type == xyd.ItemType.SKIN or type == xyd.ItemType.KANBAN then
			tableID = PartnerPictureTable:getSkinPartner(self.itemID)[1]
			group = PartnerTable:getGroup(tableID)
		else
			group = PartnerTable:getGroup(self.itemID)
		end

		self.frameImg:SetActive(true)
		self.groupIcon:SetActive(true)
		self.partnerImg:SetActive(true)
		xyd.setUISpriteAsync(self.partnerImg, nil, PartnerPictureTable:getPartnerCard(self.itemID))
		xyd.setUISpriteAsync(self.groupIcon, nil, "img_group" .. group .. "_png")
	else
		self.frameImg:SetActive(false)
		self.groupIcon:SetActive(false)
		self.partnerImg:SetActive(false)
	end
end

function ChosenPartnerItem:setGrey()
	self.itemID = nil

	self:layout()
end

function ChosenPartnerItem:getID()
	return self.itemID
end

return EditPictureWindow
