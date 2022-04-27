local ItemTips = import(".ItemTips")
local ItemCollectionTips = class("ItemCollectionTips", ItemTips)

function ItemCollectionTips:ctor(parentGO, params)
	ItemCollectionTips.super.ctor(self, parentGO, params)
end

function ItemCollectionTips:getPrefabPath()
	return "Prefabs/Windows/item_collection_tips"
end

function ItemCollectionTips:initLayout()
	self:getUIComponent()
	self:initUIComponent()
end

function ItemCollectionTips:getUIComponent()
	ItemCollectionTips.super.getUIComponent(self)

	self.gotImg = self.groupMain_:ComponentByName("gotImg", typeof(UISprite))
	self.resItem = self.groupMain_:NodeByName("resItem").gameObject
	self.labelResNum = self.resItem:ComponentByName("labelResNum", typeof(UILabel))
end

function ItemCollectionTips:initUIComponent()
	local gotStr = "collection_got_" .. tostring(xyd.Global.lang)
	local noGotStr = "collection_no_get_" .. tostring(xyd.Global.lang)
	local collectionid = xyd.tables.itemTable:getCollectionId(self.itemID)

	xyd.setUISpriteAsync(self.gotImg, nil, xyd.models.collection:isGot(collectionid) and gotStr or noGotStr)

	self.labelResNum.text = tostring(xyd.tables.collectionTable:getCoin(collectionid))

	ItemCollectionTips.super.initUIComponent(self)
	self.btnDesc_:SetActive(false)
end

function ItemCollectionTips:initDesc()
	local data = self:getDesc()

	if data.text ~= "" then
		local label = xyd.getLabel({
			w = 420,
			s = 22,
			uiRoot = self.groupDesc_,
			c = data.color,
			t = data.text
		})
		label.spacingY = 5

		table.insert(self.descs_, label)
	end

	self:showArtifactDesc()

	if xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.ARTIFACT then
		local skinDes = xyd.tables.equipTextTable:getSkinDesc(self.itemID)

		if skinDes and skinDes ~= "" then
			self:getArtiDesc()

			self.groupDescName_.text = __("ARTIFACT_STORY")
			self.groupDescLabel_.text = skinDes

			self.groupDescPart_:SetActive(true)
			self.groupDescBg_.transform:SetLocalScale(1, 1, 1)

			local height = self.groupDescLabel_.height + 80

			if height >= 412 then
				height = 412
			end

			self.go.transform:Y(height / 2)

			self.groupDescBg_.height = height

			self:waitForFrame(1, function ()
				self.groupDescBg_.transform:Y(-self.groupMain_.transform.localPosition.y - 5)
			end)
		end
	end

	local offY = 8
	local i = 0

	while i < #self.descs_ do
		local label = self.descs_[i + 1]

		if label.text == __("NOT_SELL") then
			label.color = Color.New2(4278190335.0)
		end

		if i == 0 then
			label.height = label.height + 8
		end

		label.pivot = UIWidget.Pivot.TopLeft

		label:SetLocalPosition(0, -offY, 0)

		if label.text ~= "" then
			offY = offY + label.height + 13
		else
			offY = offY + 13
		end

		i = i + 1
	end

	self.descOffY = offY
end

function ItemCollectionTips:getArtiDesc()
	local go = self.go
	self.groupDescPart_ = go:NodeByName("groupDesc").gameObject
	self.groupDescBg_ = go:ComponentByName("groupDesc/bg", typeof(UIWidget))
	self.groupDescName_ = self.groupDescPart_:ComponentByName("bg/scrollView/labelName", typeof(UILabel))
	self.groupDescLabel_ = self.groupDescPart_:ComponentByName("bg/scrollView/labelDesc", typeof(UILabel))
end

return ItemCollectionTips
