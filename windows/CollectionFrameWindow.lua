local BaseWindow = import(".BaseWindow")
local CollectionFrameWindow = class("CollectionFrameWindow", BaseWindow)
local CollectionAvatarItem = class("CollectionAvatarItem", import("app.common.ui.FixedMultiWrapContentItem"))
local playerIcon = import("app.components.PlayerIcon")

function CollectionAvatarItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.timers_ = {}
	self.sequences_ = {}
	self.waitForTimeKeys_ = {}

	self:initGO()
	self:initUI()
end

function CollectionAvatarItem:initUI()
	self.playerIcon = playerIcon.new(self.go)

	self.playerIcon:setDragScrollView(self.parent.scroller_)
end

function CollectionAvatarItem:updateInfo()
	local type_ = xyd.tables.collectionTable:getType(self.data)
	local id = xyd.tables.collectionTable:getItemId(self.data)
	local isgrey = not xyd.models.collection:isGot(self.data)

	if type_ == xyd.CollectionTableType.AVATAR then
		self.playerIcon:setInfo({
			avatarID = id,
			grey = isgrey,
			callback = function ()
				xyd.WindowManager.get():openWindow("collection_frame_detail_window", {
					type = type_,
					tableId = self.data
				})
			end
		})
	elseif type_ == xyd.CollectionTableType.FRAME then
		self.playerIcon:setInfo({
			avatar_frame_id = id,
			grey = isgrey,
			callback = function ()
				xyd.WindowManager.get():openWindow("collection_frame_detail_window", {
					type = type_,
					tableId = self.data
				})
			end
		})
	end
end

function CollectionFrameWindow:ctor(name, params)
	CollectionFrameWindow.super.ctor(self, name, params)

	self.skinName = "CollectionFrameWindowSkin"
	self.curSelect = 1
end

function CollectionFrameWindow:initWindow()
	CollectionFrameWindow.super.initWindow(self)
	self:registerEvent()
	self:getUIComponent()
	self:layout()
	self:updateLayout()
	self:initTopGroup()
end

function CollectionFrameWindow:getUIComponent()
	CollectionFrameWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupAction = groupAction
	self.top = groupAction:NodeByName("top").gameObject
	self.labelTitle_ = self.top:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelTitle_.text = __("COLLECTION_FRAME_WINDOW")
	self.groupMid = self.top:NodeByName("groupMid").gameObject
	self.tab = import("app.common.ui.CommonTabBar").new(self.groupMid, 2, function (index)
		self:onTabTouch(index)
	end)

	self.tab:setTexts({
		__("AVATAR_TEXT_1"),
		__("AVATAR_TEXT_2")
	})

	self.groupBody = groupAction:NodeByName("groupBody").gameObject
	self.scroller_ = self.groupBody:ComponentByName("scroller_", typeof(UIScrollView))
	self.wrapContent = self.scroller_:ComponentByName("wrap_content", typeof(UIWrapContent))
	local itemCell = groupAction:NodeByName("item").gameObject
	self.wrapContent_ = import("app.common.ui.FixedMultiWrapContent").new(self.scroller_, self.wrapContent, itemCell, CollectionAvatarItem, self)
	self.groupNone_ = self.groupBody:NodeByName("groupNone_").gameObject
end

function CollectionFrameWindow:initTopGroup()
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

function CollectionFrameWindow:registerEvent()
end

function CollectionFrameWindow:updateLayout()
	self:onTabTouch(self.curSelect)
	self:initData()
end

function CollectionFrameWindow:layout()
end

function CollectionFrameWindow:onTabTouch(i)
	self.curSelect = i

	self:initData()
end

function CollectionFrameWindow:playOpenAnimation(callback)
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

function CollectionFrameWindow:initData()
	local data = {}

	if self.curSelect == 1 then
		data = xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.AVATAR)
	else
		data = xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.FRAME)
	end

	self:sortAvatars(data)

	if #data == 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end

	self.wrapContent_:setInfos(data, {})
end

function CollectionFrameWindow:sortAvatars(avatars)
	table.sort(avatars, function (a, b)
		return a - b < 0
	end)
end

return CollectionFrameWindow
