local BaseWindow = import(".BaseWindow")
local BackgroundGroupWindow = class("BackgroundGroupWindow", BaseWindow)
local PictureCard = class("PictureCard", import("app.components.CopyComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local WindowTop = import("app.components.WindowTop")

function BackgroundGroupWindow:ctor(name, params)
	self.isCollection = params.isCollection

	BaseWindow.ctor(self, name, params)

	self.group_id_ = params.group_id
end

function BackgroundGroupWindow:initWindow()
	BackgroundGroupWindow.super.initWindow(self)
	self:getUIComponent()

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
	self.windowTop:setTitle(__("BIG_MAP"))
	self:buildCollection()
	self.eventProxy_:addEventListener(xyd.event.BUY_BACKGROUND, function (event)
		self:buildCollection()
	end)

	self.groupLabel.text = self:getGroupName()
end

function BackgroundGroupWindow:getUIComponent()
	local winTrans = self.window_.transform
	local contentGroup = winTrans:NodeByName("contentGroup").gameObject
	self.groupLabel = contentGroup:ComponentByName("groupLabel", typeof(UILabel))
	self.scroller = contentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.item = contentGroup:NodeByName("scroller/item").gameObject
	self.itemGroup = contentGroup:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scroller, wrapContent, self.item, PictureCard, self)
end

function BackgroundGroupWindow:getGroupName()
	return xyd.tables.customBackgroundTypeTextTable:getName(self.group_id_)
end

function BackgroundGroupWindow:buildCollection()
	local list = xyd.tables.customBackgroundTable:getBackGroundList()
	local model = xyd.models.background
	local collection_list = {}

	for i = 1, #list do
		local id = list[i]
		local params = {
			is_new = model:checkNew(id, xyd.tables.customBackgroundTable:getType(id)),
			need_red = model:checkRedIcon(id),
			state = model:getCardState(id, self.isCollection),
			id = tonumber(id),
			in_use = model:checkInUse(id),
			isCollection = self.isCollection
		}

		table.insert(collection_list, params)
	end

	self.wrapContent:setInfos(collection_list, {})
end

function BackgroundGroupWindow:getScrollView()
	return self.scroller
end

function PictureCard:ctor(go, parent)
	PictureCard.super.ctor(self, go)

	self.parent = parent

	self:setDragScrollView(parent:getScrollView())
	self:getUIComponent()
	self:registerEvent()
end

function PictureCard:getUIComponent()
	local go = self.go
	self.bgImg = go:ComponentByName("bgImg", typeof(UISprite))
	self.frameImg = go:ComponentByName("frameImg", typeof(UISprite))
	self.lockImg = go:ComponentByName("lockImg", typeof(UISprite))
	self.newImg = go:ComponentByName("newImg", typeof(UISprite))
	self.redIcon = go:ComponentByName("redIcon", typeof(UISprite))
end

function PictureCard:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	local data = info
	self.is_new_ = data.is_new
	self.need_red_ = data.need_red
	self.state_ = data.state
	self.id_ = data.id
	self.in_use_ = data.in_use
	self.isCollection = data.isCollection

	self:updateLayout()
end

function PictureCard:updateLayout()
	xyd.setUISpriteAsync(self.bgImg, nil, self:getImgSource(), function ()
	end)
	self.newImg:SetActive(self.is_new_)
	self.redIcon:SetActive(self.need_red_)
	self.lockImg:SetActive(false)

	self.bgImg.alpha = 1

	if self.state_ ~= 2 then
		self.bgImg.alpha = 0.5

		if self.state_ == 0 then
			self.lockImg:SetActive(true)
		end
	end

	self:updateUseState()
end

function PictureCard:updateUseState()
	if self.in_use_ then
		xyd.setUISpriteAsync(self.frameImg, nil, "background_card_bg_large_light", function ()
		end)
	else
		xyd.setUISpriteAsync(self.frameImg, nil, "background_card_bg_large", function ()
		end)
	end
end

function PictureCard:getImgSource()
	return tostring(xyd.tables.customBackgroundTable:getSmallPicture(self.id_))
end

function PictureCard:registerEvent()
	UIEventListener.Get(self.go).onClick = function (go)
		local type = xyd.tables.customBackgroundTable:getType(self.id_)

		xyd.models.background:resetNew(self.id_, type)
		xyd.models.background:resetRed(self.id_)

		local win = xyd.WindowManager.get():getWindow("background_window")

		win:refreshState(self.id_, {})

		local group_win = xyd.WindowManager.get():getWindow("background_group_window")

		if group_win then
			group_win:buildCollection()
		end

		xyd.WindowManager.get():openWindow("background_preview_window", {
			id = self.id_,
			isCollection = self.isCollection
		})
	end
end

return BackgroundGroupWindow
