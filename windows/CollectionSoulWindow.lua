local BaseWindow = import(".BaseWindow")
local CollectionSoulWindow = class("CollectionSoulWindow", BaseWindow)
local CollectionSoulItem = class("CollectionAvatarItem", import("app.common.ui.FixedMultiWrapContentItem"))

function CollectionSoulItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.timers_ = {}
	self.sequences_ = {}
	self.waitForTimeKeys_ = {}

	self:initGO()
	self:initUI()
end

function CollectionSoulItem:initUI()
	self.itemIcon = import("app.components.ItemIcon").new(self.go)

	self.itemIcon:setDragScrollView(self.parent.scroller_)
end

function CollectionSoulItem:updateInfo()
	self.data.wndType = xyd.ItemTipsWndType.COLLECTION
	local w = self.itemIcon:getGameObject():GetComponent(typeof(UIWidget))
	local isGrey = xyd.models.collection:isGot(xyd.tables.itemTable:getCollectionId(self.data.itemID))

	if isGrey then
		self.data.whiteMask = false
		self.data.whiteMaskAlpha = 0
	else
		self.data.whiteMask = true
		self.data.whiteMaskAlpha = 0.6
	end

	self.itemIcon:setInfo(self.data)
end

function CollectionSoulWindow:ctor(name, params)
	CollectionSoulWindow.super.ctor(self, name, params)

	self.list_ = {}
	self.identi_to_id = {}
	self.list_by_type_ = {}
	self.cur_choose_group_id_ = 0
	local collectionList = xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.SOUL)

	for i, id in pairs(collectionList) do
		self.list_[i] = {
			item_id = xyd.tables.collectionTable:getItemId(id),
			rank = xyd.tables.collectionTable:getRank(id)
		}
	end

	self.skinName = "CollectionSoulWindowSkin"
	self.list_by_type_[0] = {}

	for i = 1, #self.list_ do
		table.insert(self.identi_to_id, self.list_[i])
	end

	for i = 1, 7 do
		self.list_by_type_[i] = {}
	end

	for key in pairs(self.identi_to_id) do
		local id = self.identi_to_id[key].item_id
		local rank = self.identi_to_id[key].rank
		local qlty = xyd.tables.itemTable:getQuality(id)
		local has = xyd.models.backpack:getItemNumByID(id) > 0

		if not self.list_by_type_[qlty] then
			self.list_by_type_[qlty] = {}
		end

		table.insert(self.list_by_type_[qlty], {
			itemID = id,
			has = has,
			rank = rank
		})
		table.insert(self.list_by_type_[0], {
			itemID = id,
			has = has,
			rank = rank
		})
	end

	for i = 0, #self.list_by_type_ do
		table.sort(self.list_by_type_[i], function (a, b)
			return a.rank < b.rank
		end)
	end

	self.list_ = nil
	self.identi_to_id = nil
end

function CollectionSoulWindow:initWindow()
	CollectionSoulWindow.super.initWindow(self)
	self:getUIComponent()
	self:updateInfo(0)
	self:registerChooseGroup()
	self:initTopGroup()
end

function CollectionSoulWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.scroller_ = self.groupAction:ComponentByName("scroller_", typeof(UIScrollView))
	self.wrapContent = self.scroller_:ComponentByName("wrap_content", typeof(UIWrapContent))
	local itemCell = self.groupAction:NodeByName("item").gameObject
	self.wrapContent_ = import("app.common.ui.FixedMultiWrapContent").new(self.scroller_, self.wrapContent, itemCell, CollectionSoulItem, self)
	self.bottom = self.groupAction:NodeByName("bottom").gameObject
	self.btnCircle = self.bottom:NodeByName("filter/btnCircle").gameObject
	self.labelTitle = self.groupAction:ComponentByName("top/labelTitle_", typeof(UILabel))
	self.labelTitle.text = __("COLLECTION_SOUL_WINDOW")
	self.btn = {}
	self.btnChosen = {}

	for i = 1, 7 do
		self.btn[i] = self.btnCircle:NodeByName("btnCircle" .. tostring(i)).gameObject
		self.btnChosen[i] = self.btnCircle:NodeByName("btnCircle" .. tostring(i) .. "/chosen").gameObject
	end
end

function CollectionSoulWindow:playOpenAnimation(callback)
	self.playOpenAnimation = true
	local action1 = self:getSequence()

	self.groupAction:X(-720)

	local transform = self.groupAction.transform

	action1:Append(transform:DOLocalMoveX(50, 0.3))
	action1:Append(transform:DOLocalMoveX(0, 0.27))
	action1:AppendCallback(function ()
		self.playOpenAnimation = false

		self:setWndComplete()
	end)

	if callback then
		callback()
	end
end

function CollectionSoulWindow:initTopGroup()
	self.windowTop = import("app.components.WindowTop").new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function CollectionSoulWindow:registerChooseGroup()
	for i = 1, 7 do
		UIEventListener.Get(self.btn[i]).onClick = function ()
			self:setChooseState(i)
		end
	end
end

function CollectionSoulWindow:setChooseState(id)
	if id ~= self.cur_choose_group_id_ then
		self.btnChosen[id]:SetActive(true)

		if self.cur_choose_group_id_ ~= 0 then
			self.btnChosen[self.cur_choose_group_id_]:SetActive(false)
		end

		self.cur_choose_group_id_ = id
	elseif id == self.cur_choose_group_id_ then
		self.btnChosen[id]:SetActive(false)

		self.cur_choose_group_id_ = 0
	end

	self:updateInfo(self.cur_choose_group_id_)
end

function CollectionSoulWindow:updateInfo(id)
	local collection = self.list_by_type_[id]

	self.wrapContent_:setInfos(collection, {})
end

return CollectionSoulWindow
