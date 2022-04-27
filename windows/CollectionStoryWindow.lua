local BaseWindow = import(".BaseWindow")
local CollectionStoryWindow = class("CollectionStoryWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local CollectionStoryItem = class("CollectionStoryItem", import("app.common.ui.FixedMultiWrapContentItem"))
local CollectionTable = xyd.tables.collectionTable
local ItemTable = xyd.tables.itemTable
local Collection = xyd.models.collection

function CollectionStoryWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.list_ = {}
	self.PRE_ADD_NUM = 15

	self:getListData()
end

function CollectionStoryWindow:getListData()
	self.list_ = {}

	for i = 1, #CollectionTable:getIdsListByType(xyd.CollectionTableType.STORY) do
		table.insert(self.list_, {
			index = i
		})
	end

	while #self.list_ < self.PRE_ADD_NUM do
		table.insert(self.list_, {
			index = -1
		})
	end
end

function CollectionStoryWindow:initWindow()
	CollectionStoryWindow.super:initWindow()

	local winTrans = self.window_.transform
	self.middle_ = winTrans:NodeByName("window").gameObject
	self.itemGroup_ = winTrans:ComponentByName("window/contentGroup/scroller/itemGroup", typeof(UIWrapContent))
	self.scroller_ = winTrans:ComponentByName("window/contentGroup/scroller", typeof(UIScrollView))
	local itemCell = winTrans:NodeByName("window/contentGroup/itemCell").gameObject
	self.multiWrap_ = FixedMultiWrapContent.new(self.scroller_, self.itemGroup_, itemCell, CollectionStoryItem, self)
	self.labelWinTitle = winTrans:ComponentByName("window/top/titleLabel", typeof(UILabel))

	self:initTopGroup()
	self:updateDisplay()
end

function CollectionStoryWindow:initTopGroup()
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

function CollectionStoryWindow:updateDisplay()
	self.multiWrap_:setInfos(self.list_, {})
	self:addTitle()
end

function CollectionStoryWindow:playOpenAnimation(callback)
	if callback then
		callback()
	end

	self.middle_:SetLocalPosition(-1000, 16, 0)
	self:waitForTime(0.2, function ()
		local sequence = self:getSequence()

		sequence:Append(self.middle_.transform:DOLocalMoveX(50, 0.3)):Append(self.middle_.transform:DOLocalMoveX(0, 0.27)):AppendCallback(handler(self, function ()
			sequence:Kill(false)

			sequence = nil

			self:setWndComplete()
		end))
	end, nil)
end

function CollectionStoryItem:ctor(go, parentGo)
	CollectionStoryItem.super.ctor(self, go, parentGo)
end

function CollectionStoryItem:initUI()
	local itemTrans = self.go.transform
	self.bg_ = itemTrans:ComponentByName("bg", typeof(UISprite))
	self.label_ = itemTrans:ComponentByName("label", typeof(UILabel))
	self.icon_ = itemTrans:ComponentByName("icon", typeof(UISprite))
	self.isGot = -1
end

function CollectionStoryItem:updateInfo()
	if self.data.index < 0 then
		self.label_.text = ""

		self.bg_:SetActive(false)

		return
	end

	self.bg_:SetActive(true)

	local collectionId = CollectionTable:getIdsListByType(xyd.CollectionTableType.STORY)[self.data.index]
	local itemId = CollectionTable:getItemId(collectionId)

	xyd.setUISpriteAsync(self.icon_, nil, "icon_" .. itemId)

	if self.isGot ~= -1 then
		if self.isGot then
			xyd.applyOrigin(self.icon_)

			self.bg_.color = Color.New(1, 1, 1, 1)
		else
			xyd.applyGrey(self.icon_)

			self.bg_.color = Color.New(0, 0, 0, 1)
		end
	elseif Collection:isGot(ItemTable:getCollectionId(itemId)) then
		xyd.applyOrigin(self.icon_)

		self.bg_.color = Color.New(1, 1, 1, 1)
		self.isGot = true
	else
		xyd.applyGrey(self.icon_)

		self.bg_.color = Color.New(0, 0, 0, 1)
		self.isGot = false
	end

	self.label_.text = ItemTable:getName(itemId)
end

function CollectionStoryItem:registerEvent()
	UIEventListener.Get(self:getGameObject()).onClick = handler(self, self.onSortTouch)
end

function CollectionStoryItem:onSortTouch()
	if self.data.index >= 0 then
		xyd.WindowManager.get():openWindow("collection_story_detail_window", {
			index = self.data.index
		})
	end
end

return CollectionStoryWindow
