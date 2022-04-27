local BaseWindow = import(".BaseWindow")
local WindowTop = import("app.components.WindowTop")
local CollectionStoryDetailWindow = class("CollectionStoryDetailWindow", BaseWindow)
local CollectionTable = xyd.tables.collectionTable
local ItemTable = xyd.tables.itemTable

function CollectionStoryDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.unableMove = false
	self.slideXY = {
		x = 0,
		y = 0
	}
	self.index_ = params.index
end

function CollectionStoryDetailWindow:initWindow()
	local wintrans = self.window_.transform
	self.arrow_left = wintrans:NodeByName("UI/pageGuide/arrow_left").gameObject
	self.arrow_right = wintrans:NodeByName("UI/pageGuide/arrow_right").gameObject
	self.nameText = wintrans:ComponentByName("UI/groupInfo/nameText", typeof(UILabel))
	self.desText = wintrans:ComponentByName("UI/groupInfo/scroller/desText", typeof(UILabel))
	self.gotImg = wintrans:ComponentByName("UI/groupInfo/gotImg", typeof(UISprite))
	self.iconImg = wintrans:ComponentByName("iconImg", typeof(UISprite))
	self.resLabel = wintrans:ComponentByName("UI/groupInfo/resItem/resLabel", typeof(UILabel))
	self.scroller = wintrans:ComponentByName("UI/groupInfo/scroller", typeof(UIScrollView))
	self.scrollerPanel = wintrans:ComponentByName("UI/groupInfo/scroller", typeof(UIPanel))
	self.drag = wintrans:NodeByName("UI/groupInfo/drag").gameObject
	self.touchGroup = wintrans:NodeByName("touchGroup").gameObject

	self:initTopGroup()
	self:updateLayout()
	self:registerEvent()
end

function CollectionStoryDetailWindow:onclickArrow(index)
	if self.index_ + index >= 1 and self.index_ + index <= #CollectionTable:getIdsListByType(xyd.CollectionTableType.STORY) then
		self.index_ = self.index_ + index
	end

	if self.index_ <= 0 then
		self.index_ = #CollectionTable:getIdsListByType(xyd.CollectionTableType.STORY)
	end

	if self.index_ > #CollectionTable:getIdsListByType(xyd.CollectionTableType.STORY) then
		self.index_ = 1
	end

	self.scroller:ResetPosition()
	self:updateLayout()
end

function CollectionStoryDetailWindow:registerEvent()
	UIEventListener.Get(self.arrow_left).onClick = function ()
		self:onclickArrow(-1)
	end

	UIEventListener.Get(self.arrow_right).onClick = function ()
		self:onclickArrow(1)
	end

	UIEventListener.Get(self.touchGroup).onDragStart = function ()
		self:onTouchBegin()
	end

	UIEventListener.Get(self.touchGroup).onDrag = function (go, delta)
		self:onTouchMove(delta)
	end

	UIEventListener.Get(self.touchGroup).onDragEnd = function ()
		self:onTouchEnd()
	end
end

function CollectionStoryDetailWindow:onTouchBegin()
	self.slideXY = {
		x = 0,
		y = 0
	}
end

function CollectionStoryDetailWindow:onTouchEnd()
	if self.unableMove then
		return
	end

	if math.abs(self.slideXY.y) < math.abs(self.slideXY.x) then
		if self.slideXY.x < -50 then
			self:onclickArrow(1)
		end

		if self.slideXY.x > 50 then
			self:onclickArrow(-1)
		end
	end
end

function CollectionStoryDetailWindow:onTouchMove(delta)
	if self.unableMove then
		return
	end

	self.slideXY.x = self.slideXY.x + delta.x
	self.slideXY.y = self.slideXY.y + delta.y
end

function CollectionStoryDetailWindow:initTopGroup()
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

function CollectionStoryDetailWindow:updateLayout()
	if self.index_ == 1 then
		self.arrow_left:SetActive(false)
	else
		self.arrow_left:SetActive(true)
	end

	if self.index_ == #CollectionTable:getIdsListByType(xyd.CollectionTableType.STORY) then
		self.arrow_right:SetActive(false)
	else
		self.arrow_right:SetActive(true)
	end

	local collectionId = CollectionTable:getIdsListByType(xyd.CollectionTableType.STORY)[self.index_]
	self.itemId = CollectionTable:getItemId(collectionId)
	self.nameText.text = ItemTable:getName(self.itemId)
	self.desText.text = ItemTable:getDesc(self.itemId)
	self.resLabel.text = CollectionTable:getCoin(collectionId)
	local gotStr = "collection_got_" .. tostring(xyd.Global.lang)
	local noGotStr = "collection_no_get_" .. tostring(xyd.Global.lang)

	xyd.setUISpriteAsync(self.gotImg, nil, xyd.models.collection:isGot(collectionId) and gotStr or noGotStr)
	xyd.setUISpriteAsync(self.iconImg, nil, tostring(ItemTable:getIcon(self.itemId)) .. "_big")
	self:waitForFrame(1, function ()
		self.scroller:ResetPosition()
	end)
end

return CollectionStoryDetailWindow
