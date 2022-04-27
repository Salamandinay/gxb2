local BaseWindow = import(".BaseWindow")
local CollectionFrameDetailWindow = class("CollectionFrameDetailWindow", BaseWindow)

function CollectionFrameDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.winType = xyd.CollectionTableType.FRAME
	self.skinName = "CollectionFrameDetailWindowSkin"
	self.currentState = "normal"
	self.winType = params.type
	self.id = params.tableId
	self.tableId = xyd.tables.collectionTable:getItemId(self.id)
end

function CollectionFrameDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
end

function CollectionFrameDetailWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.nameText = self.groupAction:ComponentByName("nameText2", typeof(UILabel))
	self.getWayText = self.groupAction:ComponentByName("getWayText", typeof(UILabel))
	self.gotImg = self.groupAction:ComponentByName("gotImg", typeof(UISprite))
	self.frameNode = self.groupAction:NodeByName("frameNode").gameObject
	self.resItem = self.groupAction:NodeByName("resItem").gameObject
	self.labelResNum = self.resItem:ComponentByName("labelResNum", typeof(UILabel))
end

function CollectionFrameDetailWindow:registerEvent()
end

function CollectionFrameDetailWindow:layout()
	if self.winType == xyd.CollectionTableType.FRAME or self.winType == xyd.CollectionTableType.AVATAR then
		self.nameText.text = xyd.tables.itemTable:getName(self.tableId)
	end

	local item = import("app.components.PlayerIcon").new(self.frameNode)

	if self.winType == xyd.CollectionTableType.FRAME then
		local info = {
			noClick = true,
			avatar_frame_id = self.tableId
		}

		item:setInfo(info)
	elseif self.winType == xyd.CollectionTableType.AVATAR then
		local info = {
			noClick = true,
			avatarID = self.tableId
		}

		item:setInfo(info)
	end

	local gotStr = "collection_got_" .. tostring(xyd.Global.lang)
	local noGotStr = "collection_no_get_" .. tostring(xyd.Global.lang)

	xyd.setUISpriteAsync(self.gotImg, nil, xyd.models.collection:isGot(self.id) and gotStr or noGotStr)

	self.getWayText.text = __("GET_WAYS_TOP_WORDS") .. xyd.tables.collectionTextTable:getDesc(self.id)
	self.labelResNum.text = tostring(xyd.tables.collectionTable:getCoin(self.id))
end

return CollectionFrameDetailWindow
