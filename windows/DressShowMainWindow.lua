local BaseWindow = import(".BaseWindow")
local DressShowMainWindow = class("DressShowMainWindow", BaseWindow)
local SlotGroupItem = class("SlotGroupItem", import("app.components.CopyComponent"))
local SlotItem = class("SlotItem", import("app.components.CopyComponent"))
local WindowTop = import("app.components.WindowTop")

function SlotItem:ctor(go, parent)
	self.parent_ = parent

	SlotItem.super.ctor(self, go)
end

function SlotItem:initUI()
	SlotItem.super.initUI(self)
	self:getUIComponent()
end

function SlotItem:getUIComponent()
	local goTrans = self.go.transform
	self.dressIcon = goTrans:ComponentByName("dressIcon", typeof(UISprite))
	self.scroeGroup = goTrans:NodeByName("scroeGroup").gameObject
	self.scoreLabel = goTrans:ComponentByName("scroeGroup/scoreLabel", typeof(UILabel))
	self.lockImg = goTrans:NodeByName("lockImg").gameObject
	self.addImg = goTrans:NodeByName("addImg").gameObject
	UIEventListener.Get(self.go).onClick = handler(self, self.onClickFunction)
end

function SlotItem:setInfo(slot_data)
	self.index_ = slot_data.index
	self.dress_state = slot_data.dress_state
	self.slot_id = slot_data.slot_id

	if self.dress_state == -1 then
		if self:getParent():checkUnlcokBefore(self.index_) then
			self.lockImg:SetActive(false)
			self.addImg:SetActive(true)
		else
			self.lockImg:SetActive(true)
			self.addImg:SetActive(false)
		end

		self.dressIcon.gameObject:SetActive(false)
		self.scroeGroup:SetActive(false)
	elseif self.dress_state == 0 then
		self.lockImg:SetActive(false)
		self.addImg:SetActive(false)
		self.scroeGroup:SetActive(false)
		self.dressIcon.gameObject:SetActive(false)
	elseif self.dress_state > 0 then
		self.dressIcon.gameObject:SetActive(true)
		self.scroeGroup:SetActive(true)
		self.lockImg:SetActive(false)
		self.addImg:SetActive(false)

		local image = xyd.models.dress:getImgByDressItemId(self.dress_state)

		xyd.setUISpriteAsync(self.dressIcon, nil, image, nil, true)

		if self.parent_.index_ == 1 then
			self.scoreLabel.text = xyd.tables.senpaiDressItemTable:getBase1(self.dress_state)
		elseif self.parent_.index_ == 2 then
			self.scoreLabel.text = xyd.tables.senpaiDressItemTable:getBase2(self.dress_state)
		elseif self.parent_.index_ == 3 then
			self.scoreLabel.text = xyd.tables.senpaiDressItemTable:getBase3(self.dress_state)
		end
	end
end

function SlotItem:getParent()
	return self.parent_
end

function SlotItem:onClickFunction()
	if self.dress_state == -1 then
		if self:getParent():checkUnlcokBefore(self.index_) then
			if xyd.models.dressShow:checkUnlockCondition(self.slot_id) then
				local data = xyd.tables.dressShowWindowTable:getShowCaseBySlot(self.slot_id)

				xyd.models.dressShow:unLockSlot(data.show_id, data.index)
			else
				local unlockType = xyd.tables.dressShowSlotTable:getUnlockType(self.slot_id)
				local unlockNum = xyd.tables.dressShowSlotTable:getUnlockNum(self.slot_id)
				local valueNow = xyd.models.dressShow:getUnlockValueNow(self.slot_id)
				local text = xyd.tables.dressShowWindowUnlockTextTable:getText1(unlockType, valueNow, unlockNum)

				xyd.alertTips(text)
			end
		else
			xyd.alertTips(__("SHOW_WINDOW_TEXT15"))
		end
	else
		self:getParent():openChooseWindow(self.index_)
	end
end

function SlotGroupItem:ctor(go, parent)
	self.parent_ = parent
	self.slotItemList_ = {}

	SlotGroupItem.super.ctor(self, go)
end

function SlotGroupItem:checkUnlcokBefore(index)
	if index == 1 then
		return true
	else
		return xyd.models.dressShow:checkUnlcok(self.slot_ids[index - 1])
	end
end

function SlotGroupItem:openChooseWindow(index)
	xyd.WindowManager.get():openWindow("dress_show_choose_window", {
		index = index,
		slot_list = self.slot_ids,
		group_type = self.index_
	})
end

function SlotGroupItem:initUI()
	SlotGroupItem.super.initUI(self)
	self:getUIComponent()
end

function SlotGroupItem:getUIComponent()
	local goTrans = self.go.transform
	self.showItemList_ = goTrans:ComponentByName("showItemList", typeof(UILayout))
	self.titleGroup_ = goTrans:ComponentByName("titleGroup", typeof(UILayout))
	self.titleLabel_ = goTrans:ComponentByName("titleGroup/titleLabel", typeof(UILabel))
	self.titleNum_ = goTrans:ComponentByName("titleGroup/titleNum", typeof(UILabel))
	self.showDressItem_ = goTrans:NodeByName("showDressItem").gameObject
end

function SlotGroupItem:setInfo(params)
	self.index_ = params.index
	self.slot_ids = params.slot_ids
	local dressNum = 0

	for i = 1, 5 do
		if not self.slotItemList_[i] then
			local newRoot = NGUITools.AddChild(self.showItemList_.gameObject, self.showDressItem_)
			self.slotItemList_[i] = SlotItem.new(newRoot, self)
		end

		local slot_data = {
			slot_id = self.slot_ids[i],
			dress_state = xyd.models.dressShow:getSlotState(self.slot_ids[i]),
			index = i
		}

		if slot_data.dress_state >= 0 then
			dressNum = dressNum + 1
		end

		self.slotItemList_[i]:setInfo(slot_data)
	end

	self.showItemList_:Reposition()

	self.titleLabel_.text = __("SHOW_WINDOW_TEXT" .. self.index_ + 9)
	self.titleNum_.text = dressNum .. "/5"

	self.titleGroup_:Reposition()
end

function DressShowMainWindow:ctor(name, params)
	DressShowMainWindow.super.ctor(self, name, params)

	self.showCaseId_ = params.show_case_id
	self.slotList_ = xyd.tables.dressShowWindowTable:getSlotIDs(self.showCaseId_)
	self.slotGroupItemList_ = {}
	self.awardItemList_ = {}
end

function DressShowMainWindow:initWindow()
	DressShowMainWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initTopGroup()
	self:register()
end

function DressShowMainWindow:initTopGroup()
	self.windowTop_ = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop_:setItem(items)
end

function DressShowMainWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.showGroupList_ = winTrans:ComponentByName("showGroupList", typeof(UIGrid))
	self.showGroupItem_ = winTrans:NodeByName("showGroupItem").gameObject
	self.infoGroup_ = winTrans:NodeByName("infoGroup")
	self.detailBtn = self.infoGroup_:NodeByName("detailBtn").gameObject
	self.stateImg = self.infoGroup_:ComponentByName("stateImg", typeof(UISprite))
	self.showCaseLabel_ = self.infoGroup_:ComponentByName("showCaseLabel", typeof(UILabel))
	self.rightBtn_ = self.infoGroup_:NodeByName("rightBtn").gameObject
	self.rightBtnSprite_ = self.rightBtn_:GetComponent(typeof(UISprite))
	self.leftBtn_ = self.infoGroup_:NodeByName("leftBtn").gameObject
	self.leftBtnSprite_ = self.leftBtn_:GetComponent(typeof(UISprite))

	for i = 1, 4 do
		self["labelName" .. i] = self.infoGroup_:ComponentByName("large" .. i .. "/labelName", typeof(UILabel))

		if i ~= 4 then
			self["labelValue" .. i] = self.infoGroup_:ComponentByName("large" .. i .. "/labelValue", typeof(UILabel))
		else
			self.awardRoot = self.infoGroup_:ComponentByName("large" .. i .. "/awardRoot", typeof(UILayout))
		end
	end

	local realHeight = xyd.Global.getRealHeight()
	local gapHeight = (realHeight - 1280) / 178 * 23 + 240
	self.showGroupList_.cellHeight = gapHeight
end

function DressShowMainWindow:updateShowCaseInfo()
	self.labelValue1.text = __("SHOW_WINDOW_TEXT02", self.showCaseId_)
	local totalSlot = 0
	local slot1 = 0
	local slot2 = 0
	local slot3 = 0
	local score1 = 0
	local score2 = 0
	local score3 = 0

	for j = 1, 5 do
		local slot_id1 = self.slotList_[j]
		local slot_id2 = self.slotList_[j + 5]
		local slot_id3 = self.slotList_[j + 10]
		local dress_item1 = xyd.models.dressShow:getSlotState(slot_id1)
		local dress_item2 = xyd.models.dressShow:getSlotState(slot_id2)
		local dress_item3 = xyd.models.dressShow:getSlotState(slot_id3)

		if dress_item1 > 0 then
			slot1 = slot1 + 1
			score1 = score1 + xyd.tables.senpaiDressItemTable:getBase1(dress_item1)
		elseif dress_item1 == 0 then
			slot1 = slot1 + 1
		end

		if dress_item2 > 0 then
			slot2 = slot2 + 1
			score2 = score2 + xyd.tables.senpaiDressItemTable:getBase2(dress_item2)
		elseif dress_item2 == 0 then
			slot2 = slot2 + 1
		end

		if dress_item3 > 0 then
			slot3 = slot3 + 1
			score3 = score3 + xyd.tables.senpaiDressItemTable:getBase3(dress_item3)
		elseif dress_item3 == 0 then
			slot3 = slot3 + 1
		end
	end

	totalSlot = slot1 + slot2 + slot3
	self.labelValue2.text = totalSlot .. " ([c][1ebc1b]" .. slot1 .. "+" .. slot2 .. "+" .. slot3 .. "[-][/c])"
	local score = xyd.models.dressShow:getScore(self.showCaseId_)
	local level = xyd.models.dressShow:getLevelByScore(score)

	xyd.setUISpriteAsync(self.stateImg, nil, "dress_show_level_" .. level, nil, , true)

	self.labelValue3.text = score .. " ([c][1ebc1b]" .. score1 .. "+" .. score2 .. "+" .. score3 .. "[-][/c])"
	local awards = xyd.tables.dressShowAwardTable:getAwardsByGroupAndScore(self.showCaseId_, score)

	for index, item in ipairs(self.awardItemList_) do
		if index > #awards then
			item:SetActive(false)
		end
	end

	for index, data in ipairs(awards) do
		local params = {
			scale = 0.7037037037037037,
			uiRoot = self.awardRoot.gameObject,
			itemID = data[1],
			num = data[2],
			showNum = data[2]
		}

		if not self.awardItemList_[index] then
			self.awardItemList_[index] = xyd.getItemIcon(params)
		else
			self.awardItemList_[index]:setInfo(params)
		end
	end

	self.awardRoot:Reposition()
end

function DressShowMainWindow:register()
	DressShowMainWindow.super.register(self)

	UIEventListener.Get(self.rightBtn_).onClick = function ()
		self:onChangePage(1)
	end

	UIEventListener.Get(self.leftBtn_).onClick = function ()
		self:onChangePage(-1)
	end

	UIEventListener.Get(self.detailBtn).onClick = function ()
		xyd.openWindow("dress_show_award_window", {
			group = self.showCaseId_
		})
	end

	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_GET_INFO, handler(self, self.onGetShowInfo))
	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_UNLOCK_SLOT, handler(self, self.onUnlockSlot))
	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_EQUIP_ONE, handler(self, self.updateEquipList))
	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_EQUIPS, handler(self, self.updateEquipList))
end

function DressShowMainWindow:updateEquipList()
	for i = 1, 3 do
		self:updateSlotList(i)
	end

	self:updateShowCaseInfo()
end

function DressShowMainWindow:onUnlockSlot(event)
	local win = xyd.WindowManager.get():getWindow("dress_show_choose_window")
	local index = event.data.index
	local group = math.ceil(index / 5)

	if not win then
		local slot_id = self.slotList_[index]
		local unlockType = xyd.tables.dressShowSlotTable:getUnlockType(slot_id)
		local unlockNum = xyd.tables.dressShowSlotTable:getUnlockNum(slot_id)
		local valueNow = xyd.models.dressShow:getUnlockValueNow(slot_id)
		local text = xyd.tables.dressShowWindowUnlockTextTable:getText2(unlockType, valueNow, unlockNum)

		xyd.alertConfirm(text)
	end

	self:updateSlotList(group)
	self:updateShowCaseInfo()
end

function DressShowMainWindow:updateSlotList(group)
	local slot_ids = {}

	for j = 1, 5 do
		table.insert(slot_ids, self.slotList_[j + (group - 1) * 5])
	end

	local params = {
		index = group,
		slot_ids = slot_ids
	}

	self.slotGroupItemList_[group]:setInfo(params)
end

function DressShowMainWindow:layout()
	self:updatePageBtn()

	for i = 1, 4 do
		self["labelName" .. i].text = __("SHOW_WINDOW_TEXT0" .. i + 5)
	end

	self.showCaseLabel_.text = __("SHOW_WINDOW_TEXT05")

	if not xyd.models.dressShow:getShowCaseInfo(self.showCaseId_) then
		self:updateShowCaseInfo()
		self:updateShowSlot()

		if xyd.models.dressShow:updateDressItemInCase(self.showCaseId_) then
			xyd.alertTips(__("SHOW_WINDOW_TEXT47"))
		end
	else
		xyd.setEnabled(self.leftBtn_, false)
		xyd.setUISpriteAsync(self.leftBtnSprite_, nil, "partner_detail_arrow_grey")
		xyd.setUISpriteAsync(self.rightBtnSprite_, nil, "partner_detail_arrow_grey")
		xyd.setEnabled(self.rightBtn_, false)
	end
end

function DressShowMainWindow:onGetShowInfo()
	if xyd.models.dressShow:updateDressItemInCase(self.showCaseId_) then
		xyd.alertTips(__("SHOW_WINDOW_TEXT47"))
	end

	self:updateShowCaseInfo()
	self:updateShowSlot()
	self:updatePageBtn()
end

function DressShowMainWindow:onChangePage(change_num)
	if self.showCaseId_ + change_num > 0 and self.showCaseId_ + change_num <= 4 then
		self.showCaseId_ = self.showCaseId_ + change_num
		self.slotList_ = xyd.tables.dressShowWindowTable:getSlotIDs(self.showCaseId_)
	end

	if not xyd.models.dressShow:getShowCaseInfo(self.showCaseId_) then
		self:updateShowCaseInfo()
		self:updateShowSlot()
		self:updatePageBtn()

		if xyd.models.dressShow:updateDressItemInCase(self.showCaseId_) then
			xyd.alertTips(__("SHOW_WINDOW_TEXT47"))
		end
	else
		xyd.setEnabled(self.leftBtn_, false)
		xyd.setEnabled(self.rightBtn_, false)
		xyd.setUISpriteAsync(self.leftBtnSprite_, nil, "partner_detail_arrow_grey")
		xyd.setUISpriteAsync(self.rightBtnSprite_, nil, "partner_detail_arrow_grey")
	end
end

function DressShowMainWindow:updatePageBtn()
	local leftPage = self.showCaseId_ - 1
	local rightPage = self.showCaseId_ + 1

	if leftPage > 0 then
		local function_id = xyd.tables.dressShowWindowTable:getFunctionID(leftPage)

		if xyd.checkFunctionOpen(function_id, true) then
			xyd.setEnabled(self.leftBtn_, true)
			xyd.setUISpriteAsync(self.leftBtnSprite_, nil, "partner_detail_arrow")
		else
			xyd.setEnabled(self.leftBtn_, false)
			xyd.setUISpriteAsync(self.leftBtnSprite_, nil, "partner_detail_arrow_grey")
		end
	else
		xyd.setEnabled(self.leftBtn_, false)
		xyd.setUISpriteAsync(self.leftBtnSprite_, nil, "partner_detail_arrow_grey")
	end

	if rightPage and rightPage <= 4 then
		local function_id = xyd.tables.dressShowWindowTable:getFunctionID(rightPage)

		if xyd.checkFunctionOpen(function_id, true) then
			xyd.setEnabled(self.rightBtn_, true)
			xyd.setUISpriteAsync(self.rightBtnSprite_, nil, "partner_detail_arrow")
		else
			xyd.setEnabled(self.rightBtn_, false)
			xyd.setUISpriteAsync(self.rightBtnSprite_, nil, "partner_detail_arrow_grey")
		end
	else
		xyd.setEnabled(self.rightBtn_, false)
		xyd.setUISpriteAsync(self.rightBtnSprite_, nil, "partner_detail_arrow_grey")
	end
end

function DressShowMainWindow:updateShowSlot()
	for i = 1, 3 do
		if not self.slotGroupItemList_[i] then
			local newRoot = NGUITools.AddChild(self.showGroupList_.gameObject, self.showGroupItem_)
			self.slotGroupItemList_[i] = SlotGroupItem.new(newRoot, self)
		end

		self:updateSlotList(i)
	end

	self.showGroupList_:Reposition()
end

return DressShowMainWindow
