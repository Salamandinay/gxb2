local BaseWindow = import(".BaseWindow")
local CollectionFaceDetailWindow = class("CollectionFaceDetailWindow", BaseWindow)
local EmotionTable = xyd.tables.emotionTable
local EmotionGifTable = xyd.tables.emotionGifTable
local CollectionTable = xyd.tables.collectionTable
local CollectionTextTable = xyd.tables.collectionTextTable

function CollectionFaceDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.emoTable = nil
	self.currentState = "emotion"
	self.id = params.id

	if params.isGif then
		self.emoTable = EmotionGifTable
	else
		self.emoTable = EmotionTable
	end
end

function CollectionFaceDetailWindow:initWindow()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.nameText = self.groupAction:ComponentByName("nameText2", typeof(UILabel))
	self.getWayText = self.groupAction:ComponentByName("getWayText", typeof(UILabel))
	self.gotImg = self.groupAction:ComponentByName("gotImg", typeof(UISprite))
	self.emotionImg = self.groupAction:ComponentByName("emotionImg", typeof(UISprite))
	self.resItem = self.groupAction:NodeByName("resItem").gameObject
	self.labelResNum = self.resItem:ComponentByName("labelResNum", typeof(UILabel))

	self:layout()
end

function CollectionFaceDetailWindow:layout()
	xyd.setUISpriteAsync(self.emotionImg, nil, self.emoTable:getImg(self.id) .. "_big_png", nil, )

	self.emotionImg.depth = 2
	local collectionId = self.emoTable:getCollectionId(self.id)
	self.nameText.text = CollectionTextTable:getName(collectionId)
	self.labelResNum.text = CollectionTable:getCoin(collectionId)
	local gotStr = "collection_got_" .. tostring(xyd.Global.lang)
	local noGotStr = "collection_no_get_" .. tostring(xyd.Global.lang)

	xyd.setUISpriteAsync(self.gotImg, nil, xyd.models.collection:isGot(collectionId) and gotStr or noGotStr)

	self.getWayText.text = __("GET_WAYS_TOP_WORDS") .. CollectionTextTable:getDesc(collectionId)
end

return CollectionFaceDetailWindow
