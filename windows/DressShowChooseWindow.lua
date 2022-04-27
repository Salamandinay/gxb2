local BaseWindow = import(".BaseWindow")
local DressShowChooseWindow = class("DressShowChooseWindow", BaseWindow)
local ItemContent = class("ItemContent", import("app.components.CopyComponent"))
local dressShow = xyd.models.dressShow
local choosenState = {
	choosen_other = 3,
	not_choosen = 4,
	choosen_in_group = 2,
	choosen = 1
}

function ItemContent:ctor(go, parent, isCopy, index)
	self.parent_ = parent
	self.index_ = index
	self.isCopy_ = isCopy

	ItemContent.super.ctor(self, go)
end

function ItemContent:initUI()
	self.iconGroup_ = self.go:NodeByName("iconGroup").gameObject
	self.scoreLabel_ = self.go:ComponentByName("scoreLabel", typeof(UILabel))
	self.choosenGroup = self.go:NodeByName("choosenGroup").gameObject
	self.selectImg1 = self.choosenGroup:NodeByName("select1").gameObject
	self.selectImg2 = self.choosenGroup:NodeByName("select2").gameObject
	self.showImg = self.choosenGroup:ComponentByName("showImg", typeof(UISprite))

	if self.isCopy_ then
		self.scoreLabel_.gameObject:SetActive(false)
		self.go:NodeByName("e:image").gameObject:SetActive(false)
	end
end

function ItemContent:getDressId()
	return self.info.style_id
end

function ItemContent:getDressItemId()
	return self.info.dress_item_id
end

function ItemContent:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.style_id = info.style_id
	self.info = info
	local params = {
		isAddUIDragScrollView = true,
		uiRoot = self.iconGroup_,
		itemID = info.dress_item_id,
		callback = function ()
			self:onClickFunction()
		end
	}

	if not self.dressIcon then
		self.dressIcon = xyd.getItemIcon(params)
	else
		self.dressIcon:setInfo(params)
	end

	self.scoreLabel_.text = self:getScore()

	self:updateChoosenState()
end

function ItemContent:getScore()
	if self.parent_.groupType_ == 1 then
		return xyd.tables.senpaiDressItemTable:getBase1(self.info.dress_item_id)
	elseif self.parent_.groupType_ == 2 then
		return xyd.tables.senpaiDressItemTable:getBase2(self.info.dress_item_id)
	elseif self.parent_.groupType_ == 3 then
		return xyd.tables.senpaiDressItemTable:getBase3(self.info.dress_item_id)
	end
end

function ItemContent:onClickFunction()
	if self.isCopy_ then
		if self.parent_.slotList_[self.index_] == self.parent_.slot_id_ then
			self.parent_:clearSelect(self.index_)
			self.parent_:updateScore()
		else
			self.parent_:onClickSlot(self.index_)
		end
	else
		local choosen, value = self.parent_:checkChooseState(self.info.dress_item_id)
		local textList = {
			"A",
			"B",
			"C",
			"D",
			"E"
		}

		if choosen == choosenState.choosen then
			local index = self.parent_:getChoosenSlotIndex(self.info.dress_item_id)

			self.parent_:clearSelect(index)
		elseif choosen == choosenState.choosen_in_group then
			xyd.alertYesNo(__("SHOW_WINDOW_TEXT28", textList[value]), function (yes)
				if yes then
					self.parent_.needUpdateEquips = true
					local choosenSlot = self.parent_:getChoosenSlot(self.info.dress_item_id)

					xyd.models.dressShow:clearSlot(choosenSlot)
					self.parent_:chooseDressItem(self.info.dress_item_id)
					self:updateChoosenState()
					self.parent_:updateScore()
				end
			end)
		elseif choosen == choosenState.choosen_other then
			local choosenSlot = value
			local showCase = xyd.tables.dressShowWindowTable:getShowCaseBySlot(choosenSlot)
			local index = math.fmod(showCase.index - 1, 5) + 1

			xyd.alertYesNo(__("SHOW_WINDOW_TEXT29", showCase.show_id, __("SHOW_WINDOW_TEXT" .. math.modf((showCase.index - 1) / 5) + 1 + 9), textList[index]), function (yes_no)
				if yes_no then
					xyd.models.dressShow:clearSlot(choosenSlot)
					self.parent_:chooseDressItem(self.info.dress_item_id)
					self:updateChoosenState()
					self.parent_:updateScore()
				end
			end)
		else
			self.parent_:chooseDressItem(self.info.dress_item_id, self.go.transform.position)
		end

		self:updateChoosenState()
		self.parent_:updateScore()
	end
end

function ItemContent:updateChoosenState()
	if not self.isCopy_ and self.info then
		local choosen = self.parent_:checkChooseState(self.info.dress_item_id)

		self.choosenGroup:SetActive(true)

		if choosen == choosenState.choosen then
			self.selectImg2:SetActive(false)
			self.selectImg1:SetActive(true)
			self.showImg.gameObject:SetActive(false)
		elseif choosen == choosenState.choosen_in_group then
			self.selectImg2:SetActive(true)
			self.selectImg1:SetActive(false)
			self.showImg.gameObject:SetActive(false)
		elseif choosen == choosenState.choosen_other then
			self.selectImg2:SetActive(false)
			self.selectImg1:SetActive(false)
			self.showImg.gameObject:SetActive(true)

			local choosenSlot = self.parent_:getChoosenSlot(self.info.dress_item_id)
			local data = xyd.tables.dressShowWindowTable:getShowCaseBySlot(choosenSlot)
			local show_id = data.show_id

			xyd.setUISpriteAsync(self.showImg, nil, "dress_show_select_num_" .. show_id, nil, , true)
		else
			self.choosenGroup:SetActive(false)
		end
	else
		self.choosenGroup:SetActive(false)
	end
end

function ItemContent:getDressId()
	return self.dress_id
end

function ItemContent:setIsMustUpdate(state)
	self.isMustUpdate = state
end

function DressShowChooseWindow:ctor(name, params)
	DressShowChooseWindow.super.ctor(self, name, params)

	self.slotList_ = params.slot_list or {
		1,
		2,
		3,
		4,
		5
	}
	self.groupType_ = params.group_type
	self.slotShowItemList_ = {}
	self.downChangeShowQuality = -1

	if params.index then
		self.slot_id_ = self.slotList_[params.index]
	else
		self.slot_id_ = self.slotList_[1]
	end
end

function DressShowChooseWindow:initCopyDressItemList()
	self.copyDressItemDataList_ = {}

	for index, slot_id in ipairs(self.slotList_) do
		local dress_item_id = xyd.models.dressShow:getDressItem(slot_id)

		if dress_item_id and dress_item_id > 0 then
			self.copyDressItemDataList_[slot_id] = dress_item_id
			local dress_id = xyd.tables.senpaiDressItemTable:getDressId(dress_item_id)
			local style_id = xyd.tables.senpaiDressTable:getStyles(dress_id)[1]
			local local_choice = xyd.models.dress:getLocalChoice(dress_id)

			if local_choice then
				local all_styles = xyd.tables.senpaiDressTable:getStyles(dress_id)

				for k in pairs(all_styles) do
					if all_styles[k] == local_choice then
						style_id = xyd.tables.senpaiDressTable:getStyles(dress_id)[k]

						break
					end
				end
			end

			local data = {
				style_id = style_id,
				dress_id = dress_id,
				dress_item_id = dress_item_id,
				name = xyd.tables.itemTable:getName(dress_item_id)
			}

			if not self.slotShowItemList_[index] then
				local newRoot = NGUITools.AddChild(self["dressRoot" .. index], self.leadskin_choose_item)
				self.slotShowItemList_[index] = ItemContent.new(newRoot, self, true, index)
			end

			self.slotShowItemList_[index]:update(nil, , data)
		end
	end
end

function DressShowChooseWindow:initWindow()
	self:getUIComponent()

	self.scoreText.text = __("SHOW_WINDOW_TEXT43")
	self.titleLabel_.text = __("SHOW_WINDOW_TEXT" .. self.groupType_ + 9)
	self.labelSlotScoreText_.text = __("SHOW_WINDOW_TEXT25")
	self.sureLabel_.text = __("SHOW_WINDOW_TEXT26")

	self:initCopyDressItemList()
	self:updateSlotState()
	self:downChangeOnQualityBtn(self.downChangeShowQuality, true)
	self:updateDesPart()
	self:updateScore()
	self:register()
end

function DressShowChooseWindow:updateScore()
	local score = 0

	for slot, value in pairs(self.copyDressItemDataList_) do
		if value and value > 0 then
			if self.groupType_ == 1 then
				score = xyd.tables.senpaiDressItemTable:getBase1(value) + score
			elseif self.groupType_ == 2 then
				score = xyd.tables.senpaiDressItemTable:getBase2(value) + score
			elseif self.groupType_ == 3 then
				score = xyd.tables.senpaiDressItemTable:getBase3(value) + score
			end
		end
	end

	self.scoreLabel.text = score

	self.scoreGroup:Reposition()
	self:updateChoosenScore()
end

function DressShowChooseWindow:updateDesPart()
	local index = xyd.arrayIndexOf(self.slotList_, self.slot_id_)

	self.boxArrow_.transform:X(self["dress" .. index].localPosition.x)

	local indexText = {
		"A",
		"B",
		"C",
		"D",
		"E"
	}
	self.labelSlot_.text = __("SHOW_WINDOW_TEXT24", indexText[index])
	local addTypes = xyd.tables.dressShowSlotTable:getAddType(self.slot_id_)
	local textList = {}

	for i = 1, #addTypes do
		local addType = addTypes[i]
		local addNum = xyd.tables.dressShowSlotTable:getAddNum(self.slot_id_)[i]
		textList[i] = xyd.tables.dressShowWindowSlotAddTextTable:getText(addType, addNum)
	end

	if #addTypes == 1 then
		self.labelDesc_.text = __("SHOW_WINDOW_TEXT16", textList[1])
	else
		self.labelDesc_.text = __("SHOW_WINDOW_TEXT17", textList[1], textList[2])
	end
end

function DressShowChooseWindow:updateChoosenScore()
	local dress_item_id = self.copyDressItemDataList_[self.slot_id_]

	if not dress_item_id or dress_item_id <= 0 then
		self.labelSlotScore_.text = 0
	else
		local score = 0

		if self.groupType_ == 1 then
			score = xyd.tables.senpaiDressItemTable:getBase1(dress_item_id) + score
		elseif self.groupType_ == 2 then
			score = xyd.tables.senpaiDressItemTable:getBase2(dress_item_id) + score
		elseif self.groupType_ == 3 then
			score = xyd.tables.senpaiDressItemTable:getBase3(dress_item_id) + score
		end

		self.labelSlotScore_.text = score
	end
end

function DressShowChooseWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.choosenGroup_ = winTrans:NodeByName("choosenGroup")
	self.titleLabel_ = self.choosenGroup_:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = self.choosenGroup_:NodeByName("closeBtn").gameObject
	self.sureBtn_ = self.choosenGroup_:NodeByName("sureBtn").gameObject
	self.sureLabel_ = self.sureBtn_:ComponentByName("label", typeof(UILabel))

	for i = 1, 5 do
		self["dress" .. i] = self.choosenGroup_:NodeByName("dressList/dressRoot" .. i)
		self["dressRoot" .. i] = self.choosenGroup_:NodeByName("dressList/dressRoot" .. i .. "/iconRoot").gameObject
		self["dressRootAddImg" .. i] = self.choosenGroup_:NodeByName("dressList/dressRoot" .. i .. "/addImg").gameObject
		self["dressRootLockImg" .. i] = self.choosenGroup_:NodeByName("dressList/dressRoot" .. i .. "/lockImg").gameObject
		self["dressRootChoosen" .. i] = self["dress" .. i]:NodeByName("chooseImg").gameObject
	end

	self.scoreGroup = self.choosenGroup_:ComponentByName("scoreGroup", typeof(UILayout))
	self.scoreLabel = self.choosenGroup_:ComponentByName("scoreGroup/scoreLabel", typeof(UILabel))
	self.scoreText = self.choosenGroup_:ComponentByName("scoreGroup/scoreText", typeof(UILabel))
	self.boxDes_ = self.choosenGroup_:NodeByName("boxDes").gameObject
	self.labelSlot_ = self.boxDes_:ComponentByName("labelSlot", typeof(UILabel))
	self.labelDesc_ = self.boxDes_:ComponentByName("descGroup/descLabel", typeof(UILabel))
	self.labelSlotScoreText_ = self.boxDes_:ComponentByName("scoreGroup/scoreText", typeof(UILabel))
	self.labelSlotScore_ = self.boxDes_:ComponentByName("scoreGroup/scoreLabel", typeof(UILabel))
	self.boxArrow_ = self.choosenGroup_:NodeByName("boxArrow").gameObject
	self.downTweenCon_ = winTrans:NodeByName("downTweenCon").gameObject
	self.leadskin_choose_item = self.downTweenCon_:NodeByName("leadskin_choose_item").gameObject
	self.downChangeScroll = self.downTweenCon_:NodeByName("downChangeScroll").gameObject
	self.bg_ = self.downChangeScroll:ComponentByName("bg_", typeof(UISprite))
	self.mainGroup = self.downChangeScroll:NodeByName("mainGroup").gameObject
	self.mainGroup_UIWidget = self.downChangeScroll:ComponentByName("mainGroup", typeof(UIWidget))
	self.itemScroller = self.mainGroup:NodeByName("itemScroller").gameObject
	self.itemScroller_UIScrollView = self.mainGroup:ComponentByName("itemScroller", typeof(UIScrollView))
	self.itemGroup = self.itemScroller:NodeByName("itemGroup").gameObject
	self.itemGroup_UIWrapContent = self.itemScroller:ComponentByName("itemGroup", typeof(UIWrapContent))
	self.downChangebtnCircles = self.downTweenCon_:NodeByName("downChangebtnCircles").gameObject
	self.downChangedivider = self.downChangebtnCircles:ComponentByName("downChangedivider", typeof(UISprite))
	self.downChangebtnQualityChosen = self.downChangebtnCircles:NodeByName("downChangebtnQualityChosen").gameObject
	self.noneGroup = self.mainGroup:NodeByName("noneGroup").gameObject
	self.noneGroupLabel = self.noneGroup:ComponentByName("label", typeof(UILabel))

	for i = 0, 5 do
		self["downChangebtnCircle" .. i] = self.downChangebtnCircles:NodeByName("downChangebtnCircle" .. i).gameObject
	end

	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.itemScroller_UIScrollView, self.itemGroup_UIWrapContent, self.leadskin_choose_item, ItemContent, self)

	self.multiWrap_:setInfos({}, {})
end

function DressShowChooseWindow:clearSelect(index)
	self.slotShowItemList_[index] = nil
	self.copyDressItemDataList_[self.slotList_[index]] = nil

	if self.showTweenSequence then
		self.showTweenSequence:Kill(true)
	end

	NGUITools.DestroyChildren(self["dressRoot" .. index].transform)
	self:updateChoosenState()
end

function DressShowChooseWindow:chooseDressItem(dress_item_id, position)
	self.copyDressItemDataList_[self.slot_id_] = dress_item_id

	self:updateChoosenState(nil, , true)

	local index = xyd.arrayIndexOf(self.slotList_, self.slot_id_)

	if not self.slotShowItemList_[index] then
		local newRoot = NGUITools.AddChild(self["dressRoot" .. index], self.leadskin_choose_item)
		self.slotShowItemList_[index] = ItemContent.new(newRoot, self, true, index)
	end

	local dress_id = xyd.tables.senpaiDressItemTable:getDressId(dress_item_id)
	local style_id = xyd.tables.senpaiDressTable:getStyles(dress_id)[1]
	local local_choice = xyd.models.dress:getLocalChoice(dress_id)

	if local_choice then
		local all_styles = xyd.tables.senpaiDressTable:getStyles(dress_id)

		for k in pairs(all_styles) do
			if all_styles[k] == local_choice then
				style_id = xyd.tables.senpaiDressTable:getStyles(dress_id)[k]

				break
			end
		end
	end

	local data = {
		style_id = style_id,
		dress_id = dress_id,
		dress_item_id = dress_item_id,
		name = xyd.tables.itemTable:getName(dress_item_id)
	}

	self.slotShowItemList_[index]:update(nil, , data)

	if position then
		local pos = self["dress" .. index].transform:InverseTransformPoint(position)

		if not self.slotShowItemList_[index]:getGameObject() then
			return
		end

		self.slotShowItemList_[index]:getGameObject():SetLocalPosition(pos.x, pos.y, pos.z)

		local tween = self:getSequence()

		tween:Append(self.slotShowItemList_[index]:getGameObject().transform:DOLocalMove(Vector3(0, 0, 0), 0.2))
		tween:AppendCallback(function ()
			if tween then
				tween:Kill(true)
			end

			self.showTweenSequence = nil
		end)

		self.showTweenSequence = tween
	end
end

function DressShowChooseWindow:updateChoosenState()
	local items = self.multiWrap_:getItems()

	for _, item in ipairs(items) do
		item:updateChoosenState()
	end
end

function DressShowChooseWindow:register()
	DressShowChooseWindow.super.register(self)

	for k = 0, 5 do
		UIEventListener.Get(self["downChangebtnCircle" .. k]).onClick = function ()
			self:downChangeOnQualityBtn(k)
		end
	end

	for i = 1, 5 do
		UIEventListener.Get(self["dress" .. i].gameObject).onClick = function ()
			self:onClickSlot(i)
		end
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.sureBtn_).onClick = handler(self, self.onClickSure)

	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_UNLOCK_SLOT, handler(self, self.onUnlockSlot))
	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_EQUIP_ONE, handler(self, self.updateList))
	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_EQUIPS, handler(self, self.onEquips))
end

function DressShowChooseWindow:onClickSure()
	local slotID = self.slotList_[1]
	local showCase = xyd.tables.dressShowWindowTable:getShowCaseBySlot(slotID)
	local show_id = showCase.show_id
	local slot_list = xyd.tables.dressShowWindowTable:getSlotIDs(show_id)
	local sender_ids = {}

	for index, slot_id in ipairs(slot_list) do
		if self.copyDressItemDataList_[slot_id] and self.copyDressItemDataList_[slot_id] > 0 and xyd.arrayIndexOf(self.slotList_, slot_id) > 0 then
			table.insert(sender_ids, self.copyDressItemDataList_[slot_id])
		elseif xyd.arrayIndexOf(self.slotList_, slot_id) > 0 then
			table.insert(sender_ids, 0)
		elseif xyd.models.dressShow:getSlotItemByIndex(show_id, index) > 0 then
			table.insert(sender_ids, xyd.models.dressShow:getSlotItemByIndex(show_id, index))
		else
			table.insert(sender_ids, 0)
		end
	end

	xyd.models.dressShow:equips(show_id, sender_ids)
end

function DressShowChooseWindow:onEquips()
	xyd.alertTips(__("SHOW_WINDOW_TEXT27", __("SHOW_WINDOW_TEXT" .. 9 + self.groupType_)))
	self:close()
end

function DressShowChooseWindow:checkChooseState(dress_item_id)
	local dress_id = xyd.tables.senpaiDressItemTable:getDressId(dress_item_id)
	local show_slot = xyd.models.dressShow:getShowSlotByItem(dress_id)

	for index, slot_id in ipairs(self.slotList_) do
		local item_id = self.copyDressItemDataList_[slot_id]

		if xyd.tables.senpaiDressItemTable:getDressId(item_id) == dress_id then
			show_slot = slot_id

			break
		end
	end

	if (not self.copyDressItemDataList_[show_slot] or xyd.tables.senpaiDressItemTable:getDressId(self.copyDressItemDataList_[show_slot]) ~= dress_id) and xyd.arrayIndexOf(self.slotList_, show_slot) > 0 then
		show_slot = 0
	end

	if show_slot == self.slot_id_ then
		return choosenState.choosen, show_slot
	elseif xyd.arrayIndexOf(self.slotList_, show_slot) > 0 then
		return choosenState.choosen_in_group, xyd.arrayIndexOf(self.slotList_, show_slot)
	elseif show_slot and show_slot > 0 then
		return choosenState.choosen_other, show_slot
	else
		return choosenState.not_choosen
	end
end

function DressShowChooseWindow:getChoosenSlot(dress_item_id)
	local dress_id = xyd.tables.senpaiDressItemTable:getDressId(dress_item_id)
	local show_slot = xyd.models.dressShow:getShowSlotByItem(dress_id)

	for index, slot_id in ipairs(self.slotList_) do
		local item_id = self.copyDressItemDataList_[slot_id]

		if xyd.tables.senpaiDressItemTable:getDressId(item_id) == dress_id then
			show_slot = slot_id

			break
		end
	end

	return show_slot or 0
end

function DressShowChooseWindow:getChoosenSlotIndex(dress_item_id)
	local dress_id = xyd.tables.senpaiDressItemTable:getDressId(dress_item_id)

	for index, slot_id in ipairs(self.slotList_) do
		if xyd.tables.senpaiDressItemTable:getDressId(self.copyDressItemDataList_[slot_id]) == dress_id then
			return index
		end
	end

	return -1
end

function DressShowChooseWindow:updateSlotState()
	for i = 1, 5 do
		local slot_id = self.slotList_[i]

		if xyd.models.dressShow:checkUnlcok(slot_id) then
			self["dressRootAddImg" .. i]:SetActive(false)
			self["dressRootLockImg" .. i]:SetActive(false)
		elseif i > 1 and xyd.models.dressShow:checkUnlcok(self.slotList_[i - 1]) then
			self["dressRootAddImg" .. i]:SetActive(true)
			self["dressRootLockImg" .. i]:SetActive(false)
		else
			self["dressRootAddImg" .. i]:SetActive(false)
			self["dressRootLockImg" .. i]:SetActive(true)
		end
	end

	local index = xyd.arrayIndexOf(self.slotList_, self.slot_id_)

	for j = 1, 5 do
		if j == index then
			self["dressRootChoosen" .. j]:SetActive(true)
		else
			self["dressRootChoosen" .. j]:SetActive(false)
		end
	end
end

function DressShowChooseWindow:onClickSlot(i)
	local slot_id = self.slotList_[i]

	if xyd.models.dressShow:checkUnlcok(slot_id) and self.slot_id_ ~= slot_id then
		self.slot_id_ = slot_id

		self:updateDownChangeScroller(self.downChangeShowQuality, self.slot_id_)
	elseif i > 1 and not xyd.models.dressShow:checkUnlcok(self.slotList_[i - 1]) then
		xyd.alertTips(__("SHOW_WINDOW_TEXT15"))

		return
	elseif xyd.models.dressShow:checkUnlockCondition(slot_id) then
		local data = xyd.tables.dressShowWindowTable:getShowCaseBySlot(slot_id)

		xyd.models.dressShow:unLockSlot(data.show_id, data.index)
	elseif not xyd.models.dressShow:checkUnlcok(slot_id) then
		local unlockType = xyd.tables.dressShowSlotTable:getUnlockType(slot_id)
		local unlockNum = xyd.tables.dressShowSlotTable:getUnlockNum(slot_id)
		local valueNow = xyd.models.dressShow:getUnlockValueNow(slot_id)

		if valueNow < 0 then
			valueNow = 0
		end

		local text = xyd.tables.dressShowWindowUnlockTextTable:getText1(unlockType, valueNow, unlockNum)

		xyd.alertTips(text)

		return
	end

	for j = 1, 5 do
		if j == i then
			self["dressRootChoosen" .. j]:SetActive(true)
		else
			self["dressRootChoosen" .. j]:SetActive(false)
		end
	end

	self:updateDesPart()
	self:updateChoosenState()
	self:updateScore()
end

function DressShowChooseWindow:onUnlockSlot(event)
	local totalIndex = event.data.index
	local index = math.fmod(totalIndex - 1, 5) + 1
	local slot_id = self.slotList_[index]
	local unlockType = xyd.tables.dressShowSlotTable:getUnlockType(slot_id)
	local unlockNum = xyd.tables.dressShowSlotTable:getUnlockNum(slot_id)
	local valueNow = xyd.models.dressShow:getUnlockValueNow(slot_id)

	if valueNow < 0 then
		valueNow = 0
	end

	local text = xyd.tables.dressShowWindowUnlockTextTable:getText2(unlockType, valueNow, unlockNum)

	xyd.alertConfirm(text)
	self:updateSlotState()
	self:onClickSlot(index)
end

function DressShowChooseWindow:updateList(event)
	local data = xyd.decodeProtoBuf(event.data)
	local totalIndex = data.index
	local index = math.fmod(totalIndex - 1, 5) + 1
	local slot_id = self.slotList_[index]

	if self.needUpdateEquips then
		self.copyDressItemDataList_[slot_id] = nil
		self.slotShowItemList_[index] = nil

		if self.showTweenSequence then
			self.showTweenSequence:Kill(true)
		end

		NGUITools.DestroyChildren(self["dressRoot" .. index].transform)
		self:updateChoosenState()

		self.needUpdateEquips = false
	end
end

function DressShowChooseWindow:downChangeOnQualityBtn(index, isInit)
	local isPlaySoundId = true

	if self.downChangeShowQuality ~= index or index == -1 or isInit then
		if index == -1 then
			index = 0
		end

		isPlaySoundId = false
		local pos = self["downChangebtnCircle" .. index].transform.localPosition

		self.downChangebtnQualityChosen:SetLocalPosition(pos.x, pos.y, pos.z)

		self.downChangeShowQuality = index
	elseif self.downChangeShowQuality == index then
		if self.downChangeShowQuality == 0 then
			return
		else
			self:downChangeOnQualityBtn(0)

			return
		end
	end

	self.downChangebtnQualityChosen:SetActive(index ~= 0)

	if isPlaySoundId then
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
	end

	self:updateDownChangeScroller(index)
end

function DressShowChooseWindow:updateDownChangeScroller(pos, slot_id, keepPosition)
	slot_id = slot_id or self.slot_id_
	pos = pos or self.downChangeShowQuality
	keepPosition = keepPosition or false
	pos = pos or 0

	if not self.areadyChnageList then
		self.areadyChnageList = {}
	end

	local downChangeList = {}
	local dressItemIdList = xyd.models.dress:getDressItems()[pos]

	if #dressItemIdList <= 0 then
		self.noneGroup:SetActive(true)

		self.noneGroupLabel.text = __("PERSON_DRESS_MAIN_" .. pos + 16)

		self.multiWrap_:setInfos({}, {})
	else
		self.noneGroup:SetActive(false)

		for _, dress_item in ipairs(dressItemIdList) do
			local dress_item_id = dress_item.itemID
			local dress_id = xyd.tables.senpaiDressItemTable:getDressId(dress_item_id)
			local style_id = xyd.tables.senpaiDressTable:getStyles(dress_id)[1]
			local local_choice = xyd.models.dress:getLocalChoice(dress_id)

			if local_choice then
				local all_styles = xyd.tables.senpaiDressTable:getStyles(dress_id)

				for k in pairs(all_styles) do
					if all_styles[k] == local_choice then
						style_id = xyd.tables.senpaiDressTable:getStyles(dress_id)[k]

						break
					end
				end
			end

			local params = {
				style_id = style_id,
				dress_id = dress_id,
				name = xyd.tables.itemTable:getName(dress_item_id),
				dress_item_id = dress_item_id
			}

			if dressShow:checkDressAddType(params.dress_id, params.dress_item_id, self.slot_id_) then
				table.insert(downChangeList, params)
			end
		end

		self:sortDownChangeList(downChangeList)
		self.multiWrap_:setInfos(downChangeList, {
			keepPosition = keepPosition
		})

		if not keepPosition then
			self.itemScroller_UIScrollView:ResetPosition()
		end
	end
end

function DressShowChooseWindow:sortDownChangeList(list)
	local sortFuncList = {
		function (a, b)
			local num1 = xyd.tables.senpaiDressItemTable:getBase1(a.dress_item_id)
			local num2 = xyd.tables.senpaiDressItemTable:getBase1(b.dress_item_id)

			return num2 < num1
		end,
		function (a, b)
			local num1 = xyd.tables.senpaiDressItemTable:getBase2(a.dress_item_id)
			local num2 = xyd.tables.senpaiDressItemTable:getBase2(b.dress_item_id)

			return num2 < num1
		end,
		function (a, b)
			local num1 = xyd.tables.senpaiDressItemTable:getBase3(a.dress_item_id)
			local num2 = xyd.tables.senpaiDressItemTable:getBase3(b.dress_item_id)

			return num2 < num1
		end
	}
	local sortFunc = sortFuncList[self.groupType_]

	table.sort(list, function (a, b)
		return sortFunc(a, b)
	end)
end

return DressShowChooseWindow
