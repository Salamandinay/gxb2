local DungeonSelectItem = class("DungeonSelectItem")
local HeroIcon = import("app.components.HeroIcon")

function DungeonSelectItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.slot = xyd.models.slot

	self:initUI()
end

function DungeonSelectItem:getGameObject()
	return self.go
end

function DungeonSelectItem:initUI()
	self.heroIcon_ = HeroIcon.new(self.go)

	self.heroIcon_:setDragScrollView(self.parent.scrollView)
end

function DungeonSelectItem:update(wrapIndex, index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info

	self:updateInfo()
end

function DungeonSelectItem:updateInfo()
	local partner = self.slot:getPartner(self.data.partner_id)
	local noJob = self.data.noJob
	local tableID = partner:getTableID()
	local params = {
		tableID = tableID,
		lev = partner:getLevel(),
		star = partner:getStar(),
		partnerID = self.data.partner_id,
		skin_id = partner.skin_id,
		is_vowed = partner.is_vowed,
		callback = function ()
			self.heroIcon_.selected = false
			local pos = self:getGameObject().transform.position
			local flag = self.data.parent:selectHero(self.data.partner_id, pos)

			if flag then
				self.heroIcon_.choose = true
			end
		end
	}

	self.heroIcon_:setInfo(params)

	if self.data.parent:checkSelect(self.data.partner_id) then
		self.heroIcon_.choose = true
	else
		self.heroIcon_.choose = false
	end
end

function DungeonSelectItem:getHeroIcon()
	return self.heroIcon_
end

local DungeonSelectHerosWindow = class("DungeonSelectHerosWindow", import(".BaseWindow"))

function DungeonSelectHerosWindow:ctor(name, params)
	DungeonSelectHerosWindow.super.ctor(self, name, params)

	self.items_ = {}
	self.selectIndex = 0
	self.totalPower_ = 0
	self.chooseGroup = {}
	self.copyIconList_ = {}
	self.dungeon = xyd.models.dungeon
	self.slot = xyd.models.slot
end

function DungeonSelectHerosWindow:initWindow()
	DungeonSelectHerosWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initData()
	self:changeDataGroup()
	self:initGroupSelects()
	self:changePower()
	self:registerEvent()
	self:initFilter()
end

function DungeonSelectHerosWindow:initFilter()
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

function DungeonSelectHerosWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupHeros_ = winTrans:NodeByName("groupHeros_").gameObject
	self.groupBtns = self.groupHeros_:NodeByName("groupBtns").gameObject
	local scrollView = self.groupHeros_:ComponentByName("scroller_", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("itemList_", typeof(MultiRowWrapContent))
	local scrolltem = scrollView:NodeByName("item").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent, scrolltem, DungeonSelectItem, self)
	self.groupTop_ = winTrans:NodeByName("groupTop_").gameObject
	self.labelTitle_ = self.groupTop_:ComponentByName("labelTitle_", typeof(UILabel))
	self.btnClose_ = self.groupTop_:NodeByName("btnClose_").gameObject
	self.labelForce_ = self.groupTop_:ComponentByName("labelForce_", typeof(UILabel))
	self.btnSure_ = self.groupTop_:NodeByName("btnSure_").gameObject

	for i = 1, 5 do
		self["groupHero" .. i] = self.groupTop_:NodeByName("grid/groupHero" .. i).gameObject
	end
end

function DungeonSelectHerosWindow:layout()
	self.btnSure_:ComponentByName("button_label", typeof(UILabel)).text = __("DUNGEON_FIGHT")
	self.labelTitle_.text = __("DUNGEON_HERO_TITLE")
end

function DungeonSelectHerosWindow:initData()
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
end

function DungeonSelectHerosWindow:changeDataGroup()
	local infos = self.items_[self.selectIndex] or {}

	self.multiWrap_:setInfos(infos, {})
end

function DungeonSelectHerosWindow:initGroupSelects()
	for i = 1, 5 do
		local group = self["groupHero" .. tostring(i)]

		table.insert(self.chooseGroup, {
			flag = false,
			group = group
		})
	end
end

function DungeonSelectHerosWindow:registerEvent()
	UIEventListener.Get(self.btnSure_).onClick = handler(self, self.sureTouch)
	UIEventListener.Get(self.btnClose_).onClick = handler(self, self.closeTouch)
end

function DungeonSelectHerosWindow:sureTouch()
	if self.totalPower_ == 0 then
		xyd.alert(xyd.AlertType.TIPS, __("DUNGEON_START_ERROR"))

		return
	end

	local chooseGroup = self.chooseGroup
	local partnerIDs = {}

	for i = 1, #chooseGroup do
		local partner = chooseGroup[i].partner

		if partner then
			table.insert(partnerIDs, partner:getPartnerID())
		end
	end

	self.dungeon:reqStart(partnerIDs)
	xyd.WindowManager.get():closeWindow(self.name_)
end

function DungeonSelectHerosWindow:changeGroup(index)
	if self.selectIndex == index then
		self.selectIndex = 0
	else
		self.selectIndex = index
	end

	self:changeDataGroup()
end

function DungeonSelectHerosWindow:selectHero(partnerID, pos)
	if self:checkSelect(partnerID) then
		self:clickSelectHero(partnerID)

		return false
	end

	local data = self:getEmptyGroup()

	if data == nil then
		xyd.alert(xyd.AlertType.TIPS, __("DUNGEON_FULL_HERO"))

		return false
	end

	local partner = self.slot:getPartner(partnerID)
	local tableID = partner:getTableID()
	local parent = data.group
	local copyHero = HeroIcon.new(parent)

	table.insert(self.copyIconList_, copyHero)
	copyHero:setInfo({
		tableID = tableID,
		partnerID = partnerID,
		star = partner:getStar(),
		is_vowed = partner.is_vowed,
		skin_id = partner.skin_id,
		lev = partner:getLevel(),
		callback = function ()
			self:unSelectHero(copyHero, data)
		end
	})

	data.flag = true
	data.partner = partner

	self:changePower()

	local nPos = parent.transform:InverseTransformPoint(pos)

	copyHero:SetLocalPosition(nPos.x, nPos.y, 0)
	copyHero:getGameObject().transform:DOLocalMove(Vector3(0, 0, 0), 0.2)

	return true
end

function DungeonSelectHerosWindow:clickSelectHero(partnerID)
	local data = self:checkSelect(partnerID)

	if not data then
		return
	end

	local selectIcon = nil

	for i = 1, #self.copyIconList_ do
		local icon = self.copyIconList_[i]

		if icon:getPartnerInfo().partnerID == partnerID then
			selectIcon = icon

			break
		end
	end

	if selectIcon then
		self:unSelectHero(selectIcon, data)
	end
end

function DungeonSelectHerosWindow:unSelectHero(copyHero, data)
	local index = xyd.arrayIndexOf(self.copyIconList_, copyHero)

	if index > -1 then
		table.remove(self.copyIconList_, index)
	end

	copyHero.selected = false
	local item = self:getHeroIconByID(data.partner:getPartnerID())
	local action = DG.Tweening.DOTween.Sequence()
	local obj = copyHero:getGameObject()

	if not item then
		action:Append(obj.transform:DOLocalMove(Vector3(-200, -200, 0), 0.2)):AppendCallback(function ()
			NGUITools.Destroy(obj)
		end)
	else
		item:getHeroIcon().choose = false
		local pos = item:getGameObject().transform.position
		local nPos = obj.transform.parent.transform:InverseTransformPoint(pos)

		action:Append(obj.transform:DOLocalMove(Vector3(nPos.x, nPos.y, 0), 0.2)):AppendCallback(function ()
			NGUITools.Destroy(obj)
		end)
	end

	xyd.setTouchEnable(obj, false)

	data.flag = false
	data.partner = nil

	self:changePower()
end

function DungeonSelectHerosWindow:changePower()
	local power = 0

	for i = 1, #self.chooseGroup do
		local data = self.chooseGroup[i]

		if data.flag == true and data.partner ~= nil then
			power = power + data.partner:getPower()
		end
	end

	self.totalPower_ = power
	self.labelForce_.text = power
end

function DungeonSelectHerosWindow:getHeroIconByID(id)
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

function DungeonSelectHerosWindow:getEmptyGroup()
	for i = 1, #self.chooseGroup do
		local data = self.chooseGroup[i]

		if data.flag == false then
			return data
		end
	end

	return nil
end

function DungeonSelectHerosWindow:checkSelect(id)
	for i = 1, #self.chooseGroup do
		local data = self.chooseGroup[i]

		if data.partner and data.partner:getPartnerID() == id then
			return data
		end
	end

	return nil
end

function DungeonSelectHerosWindow:closeTouch()
	xyd.WindowManager.get():closeWindow(self.name_)
	xyd.WindowManager.get():closeWindow("dungeon_window")
end

function DungeonSelectHerosWindow:onClickEscBack()
	DungeonSelectHerosWindow.super.onClickEscBack(self)
	self:closeTouch()
end

return DungeonSelectHerosWindow
