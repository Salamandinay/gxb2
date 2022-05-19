local CollectionSkinWindow = class("CollectionSkinWindow", import(".BaseWindow"))
local PartnerCardRender = class("PartnerCardRender", import("app.components.CopyComponent"))
local PartnerCard = import("app.components.PartnerCard")
local CommonTabBar = import("app.common.ui.CommonTabBar")

function CollectionSkinWindow:ctor(name, params)
	CollectionSkinWindow.super.ctor(self, name, params)

	self.sortParnters_ = {}

	if params and params.chosenGroup then
		self.chosenGroup_ = params.chosenGroup
	else
		self.chosenGroup_ = 0
	end

	if params and params.unable_move then
		self.unableMove = params.unable_move
	else
		self.unableMove = false
	end

	if params and params.collectionInfo then
		self.collectionInfo = params.collectionInfo
	end
end

function CollectionSkinWindow:initWindow()
	CollectionSkinWindow.super.initWindow(self)
	self:getComponent()
	self:initTopGroup()
	self:initLayout()
	self:initData()
	self:register()
end

function CollectionSkinWindow:getComponent()
	local winTrans = self.window_:NodeByName("group")
	self.midGroup_ = winTrans
	local partnerCardRoot = winTrans:NodeByName("partnerCardRoot").gameObject
	self.labelWinTitle_ = winTrans:ComponentByName("topGroup/labelWinTitle", typeof(UILabel))
	self.filterGroup_ = winTrans:NodeByName("filter/filterGroup")
	self.filterGroupCommon = winTrans:NodeByName("filter/filterGroupCommon").gameObject
	self.sortBtn = winTrans:NodeByName("filter/sortBtn").gameObject
	self.sortBtnArrow = self.sortBtn:NodeByName("arrow")
	self.sortBtnLable = self.sortBtn:ComponentByName("label", typeof(UILabel))
	self.sortPop = winTrans:NodeByName("filter/sortPop").gameObject
	self.labelAll_ = self.sortPop:ComponentByName("tab_2/label", typeof(UILabel))
	self.labelWedding_ = self.sortPop:ComponentByName("tab_1/label", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("content", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("content/grid", typeof(MultiRowWrapContent))
	self.wrapContent_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, partnerCardRoot, PartnerCardRender, self)
	self.partnerNone = winTrans:NodeByName("partnerNone").gameObject
	self.labelNoneTips = self.partnerNone:ComponentByName("labelNoneTips", typeof(UILabel))
end

function CollectionSkinWindow:playOpenAnimation(callback)
	CollectionSkinWindow.super.playOpenAnimation(self, function ()
		local y = self.midGroup_.localPosition.y
		self.playOpenAnimation_ = true
		local action1 = self:getSequence()
		self.midGroup_.localPosition.x = -720

		action1:Insert(0.2, self.midGroup_:DOLocalMove(Vector3(50, y, 0), 0.3))
		action1:Insert(0.5, self.midGroup_:DOLocalMove(Vector3(0, y, 0), 0.27))
		action1:AppendCallback(function ()
			self.playOpenAnimation_ = false
		end)

		if callback then
			callback()
		end
	end)
end

function CollectionSkinWindow:initTopGroup()
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}
	self.windowTop_ = import("app.components.WindowTop").new(self.window_, self.name_)

	self.windowTop_:setItem(items)
end

function CollectionSkinWindow:initLayout()
	self.sortPop:SetActive(false)

	self.labelWinTitle_.text = __("COLLECTION_SKIN_WINDOW")
	self.labelAll_.text = __("HOUSE_TEXT_13")
	self.labelWedding_.text = __("COLLECTION_SKIN_WEDDING")
	self.sortBtnLable.text = __("HOUSE_TEXT_13")
	self.filterList_ = {}

	self:initFilter()

	self.labelNoneTips.text = __("NO_SKINS_TIPS")
end

function CollectionSkinWindow:initFilter()
	local params = {
		isCanUnSelected = 1,
		scale = 1,
		gap = 13,
		callback = handler(self, function (self, group)
			self:changeFilter(group)
		end),
		width = self.filterGroupCommon:GetComponent(typeof(UIWidget)).width,
		chosenGroup = self.chosenGroup_
	}
	local partnerFilter = import("app.components.PartnerFilter").new(self.filterGroupCommon.gameObject, params)
	self.partnerFilter = partnerFilter
end

function CollectionSkinWindow:initData()
	for i = 0, xyd.GROUP_NUM do
		local res = {}
		local sortedPartners = self:getSkinsByGroup(i)

		for _, skinId in ipairs(sortedPartners) do
			local tableList = xyd.tables.partnerPictureTable:getSkinPartner(skinId)
			local params = {
				tableID = xyd.checkCondition(tableList and #tableList > 0, tableList[1], 0),
				group = xyd.tables.itemTable:getGroup(skinId),
				skin_id = skinId
			}

			table.insert(res, params)
		end

		self.sortParnters_[i] = res

		table.sort(self.sortParnters_[i], function (a, b)
			return b.skin_id < a.skin_id
		end)
	end

	self.sortType = 2

	self:updateDataGroup()
end

function CollectionSkinWindow:register()
	CollectionSkinWindow.super.register(self)

	UIEventListener.Get(self.sortBtn).onClick = handler(self, self.onClickSortBtn)
	self.sortTab = CommonTabBar.new(self.sortPop, 2, function (index)
		self:changeSortType(index)
	end)
end

function CollectionSkinWindow:getNowSortedSkins()
	if self.collectionInfo then
		return self.collectionInfo
	end

	local data = self.sortParnters_[self.chosenGroup_]
	local collection = {}

	if self.sortType == 2 then
		collection = data
	else
		for i = 1, #data do
			if xyd.tables.partnerPictureTable:getIsWedding(data[i].skin_id) then
				table.insert(collection, data[i])
			end
		end
	end

	return collection
end

function CollectionSkinWindow:getSkinsByGroup(groupId)
	local collectionIds = xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.SKIN)
	local allIds = {}

	for _, id in ipairs(collectionIds) do
		table.insert(allIds, xyd.tables.collectionTable:getItemId(id))
	end

	if groupId == 0 then
		return allIds
	else
		local ids = {}

		for _, id in ipairs(allIds) do
			local group = xyd.tables.itemTable:getGroup(id)

			if group and group == groupId then
				table.insert(ids, id)
			end
		end

		return ids
	end
end

function CollectionSkinWindow:changeFilter(chosenGroup)
	if self.chosenGroup_ == chosenGroup then
		self.chosenGroup_ = 0
	else
		self.chosenGroup_ = chosenGroup
	end

	self:updateDataGroup()
end

function CollectionSkinWindow:updateDataGroup()
	local collection = self:getNowSortedSkins()

	if next(collection) == nil then
		self.partnerNone:SetActive(true)
	else
		self.partnerNone:SetActive(false)
	end

	self.wrapContent_:setInfos(collection, {})
end

function CollectionSkinWindow:onClickSortBtn()
	local sequence2 = self:getSequence()
	local sortPopTrans = self.sortPop.transform
	local p = self.sortPop:GetComponent(typeof(UIPanel))
	local sortPopY = 92

	local function getter()
		return Color.New(1, 1, 1, p.alpha)
	end

	local function setter(color)
		p.alpha = color.a
	end

	if self.sortPop.activeSelf == true then
		self.sortBtnArrow.transform:SetLocalScale(1, 1, 1)
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY + 17, 0.067))
		sequence2:Insert(0.067, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0.1))
		sequence2:Insert(0.067, sortPopTrans:DOLocalMoveY(sortPopY - 58, 0.1))
		sequence2:Insert(0.167, sortPopTrans:DOLocalMoveY(sortPopY, 0))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil

			self.sortPop:SetActive(false)
		end)
	else
		self.sortPop:SetActive(true)
		self.sortBtnArrow.transform:SetLocalScale(1, -1, 1)
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY - 58, 0))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0))
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY + 17, 0.1))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.1))
		sequence2:Insert(0.1, sortPopTrans:DOLocalMoveY(sortPopY, 0.2))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil
		end)
	end
end

function CollectionSkinWindow:changeSortType(index)
	if index ~= self.sortType then
		self.sortType = index

		self:updateDataGroup()

		self.sortBtnLable.text = index == 2 and __("HOUSE_TEXT_13") or __("COLLECTION_SKIN_WEDDING")
	end
end

function PartnerCardRender:ctor(go, parent)
	self.parent_ = parent
	self.panel_ = self.parent_.scrollView_.gameObject:GetComponent(typeof(UIPanel))

	PartnerCardRender.super.ctor(self, go)
end

function PartnerCardRender:initUI()
	PartnerCardRender.super.initUI(self)

	self.card_ = PartnerCard.new(self.go, self.panel_)

	UIEventListener.Get(self.go).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.WindowManager.get():openWindow("collection_skin_detail_window", {
			skin_id = self.data_.skin_id
		})
	end
end

function PartnerCardRender:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	local collectionId = xyd.tables.itemTable:getCollectionId(info.skin_id)

	if not self.data_ or self.data_.skin_id ~= info.skin_id then
		self.data_ = info

		self.card_:setSkinCard(info)
	end

	if xyd.models.collection:isGot(collectionId) then
		self.card_:applyOrigin()
	else
		self.card_:applyGrey()
	end
end

return CollectionSkinWindow
