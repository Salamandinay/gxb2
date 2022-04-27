local BaseWindow = import(".BaseWindow")
local WindowTop = import("app.components.WindowTop")
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local CollectionFaceWindow = class("CollectionFaceWindow", BaseWindow)
local CollectionFaceItem = class("CollectionFaceItem", import("app.common.ui.FixedMultiWrapContentItem"))
local EmotionTable = xyd.tables.emotionTable
local EmotionGifTable = xyd.tables.emotionGifTable
local CollectionTable = xyd.tables.collectionTable

function CollectionFaceWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.list_ = {}
	self.identi_to_id = {}
	self.list_by_type_ = {}
	self.cur_choose_group_id_ = nil
	self.sourceArr = {}
	self.sortType = -1
	self.btnNum = 3
	self.touch_cnt = 0
	self.sortStation = false
	self.picNum = EmotionTable:getLength()
	self.gifNum = EmotionGifTable:getLength()
	self.awardNum = #EmotionGifTable:getAwardIds()

	if params and params.type then
		self.sortType = params.type
	end
end

function CollectionFaceWindow:initWindow()
	local winTrans = self.window_.transform
	self.filterLabel1_ = winTrans:ComponentByName("middle/filter/filterGroup/filterPanel/groupSort/filterCmpt1/labelTips", typeof(UILabel))
	self.filterLabel2_ = winTrans:ComponentByName("middle/filter/filterGroup/filterPanel/groupSort/filterCmpt2/labelTips", typeof(UILabel))
	self.filterLabel3_ = winTrans:ComponentByName("middle/filter/filterGroup/filterPanel/groupSort/filterCmpt3/labelTips", typeof(UILabel))
	self.btnLabel_ = winTrans:ComponentByName("middle/filter/filterGroup/btnSort/btnLabel", typeof(UILabel))
	self.labelWinTitle = winTrans:ComponentByName("middle/top/titleLabel", typeof(UILabel))
	self.filterImg1_ = winTrans:ComponentByName("middle/filter/filterGroup/filterPanel/groupSort/filterCmpt1/filterImg", typeof(UISprite))
	self.filterImg2_ = winTrans:ComponentByName("middle/filter/filterGroup/filterPanel/groupSort/filterCmpt2/filterImg", typeof(UISprite))
	self.filterImg3_ = winTrans:ComponentByName("middle/filter/filterGroup/filterPanel/groupSort/filterCmpt3/filterImg", typeof(UISprite))
	self.btnImg_ = winTrans:ComponentByName("middle/filter/filterGroup/btnSort/btnImg", typeof(UISprite))
	self.filterBtn_ = winTrans:ComponentByName("middle/filter/filterGroup/btnSort", typeof(UISprite)).gameObject
	self.groupSort_ = winTrans:NodeByName("middle/filter/filterGroup/filterPanel/groupSort").gameObject
	self.partnersGroup_ = winTrans:NodeByName("middle/contentGroup/scroller/partnersGroup").gameObject
	self.middle_ = winTrans:NodeByName("middle").gameObject
	self.scrollView_ = winTrans:ComponentByName("middle/contentGroup/scroller", typeof(UIScrollView))
	self.scrollPanel_ = winTrans:ComponentByName("middle/contentGroup/scroller", typeof(UIPanel))
	self.wrapContent_ = winTrans:ComponentByName("middle/contentGroup/scroller/partnersGroup", typeof(UIWrapContent))
	local itemCell = winTrans:NodeByName("middle/contentGroup/item").gameObject

	itemCell:SetActive(false)

	self.multiWrap_ = FixedMultiWrapContent.new(self.scrollView_, self.wrapContent_, itemCell, CollectionFaceItem, self)

	self.groupSort_:SetActive(false)
	self:layout()
	self:register()
	self:initTopGroup()
end

function CollectionFaceWindow:layout()
	self.filterLabel1_.text = __("EMOTION_DEFAULT_TEXT")
	self.filterLabel2_.text = __("EMOTION_DYNAMIC_TEXT")
	self.filterLabel3_.text = __("PERSON_SPECIAL")
	self.btnLabel_.text = __("SCREEN_TYPE")

	self:addTitle()
	self:updateLayout()
end

function CollectionFaceWindow:register()
	UIEventListener.Get(self.filterBtn_).onClick = handler(self, self.onSortTouch)

	for i = 1, self.btnNum do
		UIEventListener.Get(self.window_.transform:ComponentByName("middle/filter/filterGroup/filterPanel/groupSort/filterCmpt" .. i .. "/filterImg", typeof(UISprite)).gameObject).onClick = function ()
			self:onSortSelectTouch(i)
		end
	end
end

function CollectionFaceWindow:updateBtns()
	for i = 1, self.btnNum do
		if i == self.sortType then
			if i == 1 then
				xyd.setUISpriteAsync(self["filterImg" .. tostring(i) .. "_"], nil, "partner_sort_bg_chosen_01")
			elseif i == self.btnNum then
				xyd.setUISpriteAsync(self["filterImg" .. tostring(i) .. "_"], nil, "partner_sort_bg_chosen_02")
			else
				xyd.setUISpriteAsync(self["filterImg" .. tostring(i) .. "_"], nil, "partner_sort_bg_chosen_03")
			end

			self["filterLabel" .. tostring(i) .. "_"].color = Color.New2(4294967295.0)
			self["filterLabel" .. tostring(i) .. "_"].effectColor = Color.New2(473916927)
		else
			if i == 1 then
				xyd.setUISpriteAsync(self["filterImg" .. tostring(i) .. "_"], nil, "partner_sort_bg_unchosen_01")
			elseif i == self.btnNum then
				xyd.setUISpriteAsync(self["filterImg" .. tostring(i) .. "_"], nil, "partner_sort_bg_unchosen_02")
			else
				xyd.setUISpriteAsync(self["filterImg" .. tostring(i) .. "_"], nil, "partner_sort_bg_unchosen_03")
			end

			self["filterLabel" .. tostring(i) .. "_"].color = Color.New2(960513791)
			self["filterLabel" .. tostring(i) .. "_"].effectColor = Color.New2(4294967295.0)
		end
	end
end

function CollectionFaceWindow:playOpenAnimation(callback)
	if callback then
		callback()
	end

	self.middle_:SetLocalPosition(-1000, 16, 0)
	self:waitForTime(0.2, function ()
		local sequence = self:getSequence()

		sequence:Append(self.middle_.transform:DOLocalMoveX(50, 0.3):SetEase(DG.Tweening.Ease.InOutSine))
		sequence:Append(self.middle_.transform:DOLocalMoveX(0, 0.27):SetEase(DG.Tweening.Ease.InOutSine))
		sequence:AppendCallback(handler(self, function ()
			sequence:Kill(false)

			sequence = nil

			self:setWndComplete()
		end))
	end, nil)
end

function CollectionFaceWindow:updateLayout()
	self:updateBtns()

	self.sourceArr = {}
	local type = self.sortType - 1
	local curLang = xyd.Global.lang == "zh_tw" and "zh_tw" or "en_en"

	if type == xyd.EmotionType.GIF then
		local ids = EmotionGifTable:getCanUseIds()

		for i = 1, self.gifNum do
			local id = ids[i]
			local collectionId = EmotionGifTable:getCollectionId(id)

			if CollectionTable:getItemId(collectionId) then
				local itemParams = {
					giftTable = true,
					grey = false,
					source = tostring(EmotionGifTable:getImg(id)) .. "_" .. tostring(curLang) .. "_png",
					id = id
				}

				table.insert(self.sourceArr, itemParams)
			end
		end
	elseif type == xyd.EmotionType.AWARD then
		local ids = EmotionGifTable:getAwardIds()

		for i = 1, self.awardNum do
			local id = ids[i]
			local collectionId = EmotionGifTable:getCollectionId(id)

			if CollectionTable:getItemId(collectionId) then
				local itemParams = {
					giftTable = true,
					grey = false,
					source = tostring(EmotionGifTable:getImg(id)) .. "_" .. tostring(curLang) .. "_png",
					id = id
				}
				local num = xyd.models.backpack:getItemNumByID(EmotionGifTable:getItemId(id))

				if num <= 0 then
					itemParams.grey = true
				end

				table.insert(self.sourceArr, itemParams)
			end
		end
	elseif type == xyd.EmotionType.NORMAL then
		for i = 1, self.picNum do
			local collectionId = EmotionTable:getCollectionId(i)

			if CollectionTable:getItemId(collectionId) then
				local itemParams = {
					giftTable = false,
					grey = false,
					source = tostring(EmotionTable:getImg(i)) .. "_" .. tostring(curLang) .. "_png",
					id = i
				}

				table.insert(self.sourceArr, itemParams)
			end
		end
	else
		for id in ipairs(EmotionTable:getIds()) do
			local collectionId = EmotionTable:getCollectionId(id)

			if CollectionTable:getItemId(collectionId) then
				local itemParams = {
					giftTable = false,
					grey = false,
					source = tostring(EmotionTable:getImg(id)) .. "_" .. tostring(curLang) .. "_png",
					id = id
				}

				table.insert(self.sourceArr, itemParams)
			end
		end

		for _, id in ipairs(EmotionGifTable:getIds()) do
			local collectionId = EmotionGifTable:getCollectionId(id)

			if CollectionTable:getItemId(collectionId) then
				local itemParams = {
					giftTable = true,
					grey = false,
					source = tostring(EmotionGifTable:getImg(id)) .. "_" .. tostring(curLang) .. "_png",
					id = id
				}

				table.insert(self.sourceArr, itemParams)
			end
		end
	end

	self.multiWrap_:setInfos(self.sourceArr, {})
end

function CollectionFaceWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_)
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

function CollectionFaceWindow:getWindowTop()
	return self.windowTop
end

function CollectionFaceWindow:onSortSelectTouch(index)
	local index_ = index

	if self.sortType == index_ then
		self.sortType = -1
	else
		self.sortType = index_
	end

	self:updateLayout()
	self:onSortTouch()
end

function CollectionFaceWindow:onSortTouch()
	if self.sortStation then
		self.btnImg_.gameObject:SetLocalScale(1, 1, 1)
	else
		self.btnImg_.gameObject:SetLocalScale(1, -1, 1)
	end

	self:moveGroupSort()
end

function CollectionFaceWindow:moveGroupSort()
	local height = self.groupSort_:GetComponent(typeof(UIWidget)).height - 72
	local groupSort = self.groupSort_.transform

	if self.sortStation then
		local sequence = self:getSequence()

		sequence:Append(groupSort:DOLocalMoveY(height + 17, 0.067)):Append(groupSort:DOLocalMoveY(height - 58, 0.1)):Join(xyd.getTweenAlpha(self.groupSort_:GetComponent(typeof(UIWidget)), 0.01, 0.1)):AppendCallback(function ()
			self.groupSort_:SetActive(false)
		end)

		self.sortStation = not self.sortStation
	else
		self.groupSort_:SetActive(true)

		self.groupSort_:GetComponent(typeof(UIWidget)).alpha = 0.01

		self.groupSort_:SetLocalPosition(groupSort.localPosition.x, height - 58, 0)

		local sequence = self:getSequence()

		sequence:Append(groupSort:DOLocalMoveY(height + 17, 0.1)):Join(xyd.getTweenAlpha(self.groupSort_:GetComponent(typeof(UIWidget)), 1, 0.1)):Append(groupSort:DOLocalMoveY(height, 0.2))

		self.sortStation = not self.sortStation
	end
end

function CollectionFaceItem:ctor(go, parentGo)
	CollectionFaceItem.super.ctor(self, go, parentGo)
end

function CollectionFaceItem:initUI()
	local itemTrans = self.go.transform
	self.img_ = itemTrans:ComponentByName("img", typeof(UISprite))
	self.label_ = itemTrans:ComponentByName("label", typeof(UILabel))
end

function CollectionFaceItem:updateInfo()
	xyd.setUISpriteAsync(self.img_, nil, self.data.source)

	local table = nil

	if not self.data.giftTable then
		table = EmotionTable
	else
		table = EmotionGifTable
	end

	local collectionId = table:getCollectionId(self.data.id)

	if xyd.models.collection:isGot(collectionId) then
		xyd.applyOrigin(self.img_)
	else
		xyd.applyGrey(self.img_)
	end

	self.label_.text = xyd.tables.collectionTextTable:getName(collectionId)
end

function CollectionFaceItem:registerEvent()
	UIEventListener.Get(self:getGameObject()).onClick = handler(self, self.clickItem)
end

function CollectionFaceItem:clickItem()
	xyd.WindowManager.get():openWindow("collection_face_detail_window", {
		id = self.data.id,
		isGif = self.data.giftTable
	})
end

return CollectionFaceWindow
