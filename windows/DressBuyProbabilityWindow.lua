local DressBuyProbabilityWindow = class("DressBuyProbabilityWindow", import(".BaseWindow"))
local CommonTabBar = import("app.common.ui.CommonTabBar")
local InfoItem = class("InfoItem")
local dropTable = xyd.tables.dropboxShowTable
local itemTable = xyd.tables.itemTable

function DressBuyProbabilityWindow:ctor(name, params)
	DressBuyProbabilityWindow.super.ctor(self, name, params)

	self.isInitLeft = false
	self.isInitRight = false
	self.type = params.type or 1
end

function DressBuyProbabilityWindow:initWindow()
	self:getUIComponent()
	self:layout()
end

function DressBuyProbabilityWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("content").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.groupNav = groupAction:NodeByName("groupNav").gameObject
	self.content1 = groupAction:NodeByName("content1").gameObject
	self.groupExplain = self.content1:NodeByName("groupExplain").gameObject
	self.labelExplainSubtitle = self.groupExplain:ComponentByName("groupSubtitle/labelName", typeof(UILabel))
	self.labelExplain = self.groupExplain:ComponentByName("scroller_/labelExplain", typeof(UILabel))
	self.groupPreview = self.content1:NodeByName("groupPreview").gameObject
	self.labelPreviewSubtitle = self.groupPreview:ComponentByName("groupSubtitle/labelName", typeof(UILabel))
	self.previewScroller = self.groupPreview:ComponentByName("scroller_", typeof(UIScrollView))
	self.previewScrollerDrag = self.groupPreview:NodeByName("drag").gameObject
	self.previewGrid_ = self.previewScroller:ComponentByName("grid_", typeof(UIGrid))
	self.previewLayout = self.groupPreview:ComponentByName("layout", typeof(UILayout))
	self.probUpItem = self.groupPreview:NodeByName("probUpItem").gameObject

	self.probUpItem:SetActive(false)

	self.content2 = groupAction:NodeByName("content2").gameObject
	self.scroller_2 = self.content2:ComponentByName("scroller_", typeof(UIScrollView))
	self.uiTable = self.scroller_2:ComponentByName("uitable", typeof(UITable))
	self.infoItem = self.content2:NodeByName("infoItem").gameObject

	self.infoItem:SetActive(false)
end

function DressBuyProbabilityWindow:layout()
	self.labelTitle.text = __("DRESS_BUY_WINDOW_TEXT01")

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	self.tabBar = CommonTabBar.new(self.groupNav, 2, function (index)
		self:changeToggle(index)
	end, nil, {
		chosen = {
			color = Color.New2(4278124287.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	})

	self.tabBar:setTexts({
		__("DRESS_BUY_WINDOW_TEXT02"),
		__("DRESS_BUY_WINDOW_TEXT03")
	})
end

function DressBuyProbabilityWindow:prepareAwards()
	local list = {}

	if self.type == xyd.DressBuyProbWndType.BASE then
		list = {
			tonumber(xyd.tables.miscTable:getVal("dress_gacha_dropbox1")),
			tonumber(xyd.tables.miscTable:getVal("dress_gacha_dropbox4"))
		}
	elseif self.type == xyd.DressBuyProbWndType.LIMIT then
		list = {
			tonumber(xyd.tables.miscTable:getVal("dress_gacha_dropbox3")),
			tonumber(xyd.tables.miscTable:getVal("dress_gacha_dropbox2")),
			tonumber(xyd.tables.miscTable:getVal("dress_gacha_dropbox5"))
		}
	end

	self.awardsList = {}
	self.allWeight = 0

	for _, dropBoxID in ipairs(list) do
		local ids = dropTable:getIdsByBoxId(dropBoxID)

		table.sort(ids.list)

		self.allWeight = self.allWeight + ids.all_weight

		for _, id in ipairs(ids.list) do
			local award = dropTable:getItem(id)
			local weight = dropTable:getWeight(id)
			local qlt = itemTable:getQuality(award[1])

			if not self.awardsList[qlt] then
				self.awardsList[qlt] = {
					qltWeight = 0,
					list = {}
				}
			end

			self.awardsList[qlt].qltWeight = self.awardsList[qlt].qltWeight + weight

			table.insert(self.awardsList[qlt].list, {
				item_id = award[1],
				weight = weight
			})
		end
	end
end

function DressBuyProbabilityWindow:changeToggle(index)
	xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

	if index == 1 then
		self.content1:SetActive(true)
		self.content2:SetActive(false)

		if not self.isInitLeft then
			self.isInitLeft = true

			self:initLeft()
		end
	else
		self.content1:SetActive(false)
		self.content2:SetActive(true)

		if not self.isInitRight then
			self.isInitRight = true

			self:initRight()
		end
	end
end

function DressBuyProbabilityWindow:initLeft()
	self.labelExplainSubtitle.text = __("DRESS_BUY_WINDOW_TEXT04")

	if self.type == xyd.DressBuyProbWndType.BASE then
		self.labelExplain.text = __("DRESS_BUY_WINDOW_TEXT05")
		self.labelPreviewSubtitle.text = __("DRESS_BUY_WINDOW_TEXT07")

		self.previewLayout:SetActive(false)

		local dropBoxID = tonumber(xyd.tables.miscTable:getVal("dress_gacha_dropbox1"))
		local ids = dropTable:getIdsByBoxId(dropBoxID)

		for _, id in ipairs(ids.list) do
			local item = dropTable:getItem(id)

			xyd.getItemIcon({
				itemID = item[1],
				uiRoot = self.previewGrid_.gameObject,
				dragScrollView = self.previewScroller
			})
		end

		self.previewGrid_:Reposition()
	else
		self.labelExplain.text = __("DRESS_BUY_WINDOW_TEXT06")
		self.labelPreviewSubtitle.text = __("DRESS_BUY_WINDOW_TEXT08")

		self.previewScroller:SetActive(false)
		self.previewScrollerDrag:SetActive(false)

		local showList = xyd.split(xyd.tables.miscTable:getVal("dress_gacha_show"), "#")
		local text = {
			__("DRESS_BUY_WINDOW_TEXT09"),
			__("DRESS_BUY_WINDOW_TEXT10")
		}

		for i, listStr in ipairs(showList) do
			local ids = xyd.split(listStr, "|", true)
			local itemRoot = NGUITools.AddChild(self.previewLayout.gameObject, self.probUpItem)
			local itemGroup = itemRoot:ComponentByName("itemGroup", typeof(UILayout))
			local label = itemRoot:ComponentByName("labelTitle", typeof(UILabel))
			label.text = text[i]

			if xyd.Global.lang == "de_de" then
				label:Y(77)
			end

			for _, id in ipairs(ids) do
				xyd.getItemIcon({
					itemID = id,
					uiRoot = itemGroup.gameObject
				})
			end

			itemGroup:Reposition()
		end

		self.previewLayout:Reposition()

		if #showList == 1 then
			self.groupExplain:GetComponent(typeof(UIWidget)).height = 353
			self.groupPreview:GetComponent(typeof(UIWidget)).height = 239

			self.groupPreview:Y(-60)
		end
	end
end

function DressBuyProbabilityWindow:initRight()
	self:prepareAwards()

	self.infoItemList = {}
	local len = #xyd.split(xyd.tables.miscTable:getVal("dress_common_fragment_qlt_item_ids"), "|")
	local text = {
		__("DRESS_BUY_WINDOW_TEXT16"),
		__("DRESS_BUY_WINDOW_TEXT15"),
		__("DRESS_BUY_WINDOW_TEXT14"),
		__("DRESS_BUY_WINDOW_TEXT13"),
		__("DRESS_BUY_WINDOW_TEXT12"),
		__("DRESS_BUY_WINDOW_TEXT11")
	}
	local show = false

	for i = len, 1, -1 do
		if self.awardsList[i] then
			local itemRoot = NGUITools.AddChild(self.uiTable.gameObject, self.infoItem)
			local item = InfoItem.new(itemRoot, self)
			self.awardsList[i].text = text[i]
			self.awardsList[i].id = i

			item:setInfo(self.awardsList[i])

			self.infoItemList[i] = item

			if not show then
				show = true
			else
				item:hide()
			end
		else
			self.infoItemList[i] = ""
		end
	end

	self.uiTable:Reposition()
	self.scroller_2:ResetPosition()
end

function DressBuyProbabilityWindow:playExpand(id, delta)
	local actItem = self.infoItemList[id]
	actItem.imgArr_.transform.localEulerAngles = Vector3(0, 0, 0)
	local sequence = self:getSequence()

	sequence:Append(actItem.groupContent.transform:DOScale(1, 0.1))
	sequence:Join(actItem.downLine.transform:DOLocalMoveY(-37 - delta, 0.1))

	for i = id - 1, 1, -1 do
		if self.infoItemList[i] ~= "" then
			local originY = self.infoItemList[i].go.transform.localPosition.y

			sequence:Join(self.infoItemList[i].go.transform:DOLocalMoveY(originY - delta, 0.1))
		end
	end

	sequence:AppendCallback(function ()
		sequence:Kill(false)

		sequence = nil
	end)
end

function DressBuyProbabilityWindow:playHide(id, delta)
	local actItem = self.infoItemList[id]
	actItem.imgArr_.transform.localEulerAngles = Vector3(0, 0, 90)
	local sequence = self:getSequence()

	sequence:Append(actItem.groupContent.transform:DOScale(Vector3(1, 0, 1), 0.1))
	sequence:Join(actItem.downLine.transform:DOLocalMoveY(-37, 0.1))

	for i = id - 1, 1, -1 do
		if self.infoItemList[i] ~= "" then
			local originY = self.infoItemList[i].go.transform.localPosition.y

			sequence:Join(self.infoItemList[i].go.transform:DOLocalMoveY(originY + delta, 0.1))
		end
	end

	sequence:AppendCallback(function ()
		sequence:Kill(false)

		sequence = nil
	end)
end

function InfoItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.groupTitle = go:NodeByName("groupTitle").gameObject
	self.labelTitle = self.groupTitle:ComponentByName("labelTitle", typeof(UILabel))
	self.imgArr_ = self.groupTitle:NodeByName("imgArr").gameObject
	self.downLine = go:NodeByName("downLine").gameObject
	self.groupContent = go:NodeByName("groupContent").gameObject
	self.grid_ = self.groupContent:ComponentByName("grid", typeof(UIGrid))
	self.probItem = go:NodeByName("probItem").gameObject

	self.probItem:SetActive(false)
	xyd.setDragScrollView(self.groupTitle, self.parent.scroller_2)

	UIEventListener.Get(self.groupTitle).onClick = function ()
		if self.isShow then
			self.parent:playHide(self.id, -37 - self.downLineY)
		else
			self.parent:playExpand(self.id, -37 - self.downLineY)
		end

		self.isShow = not self.isShow
	end
end

function InfoItem:setInfo(info)
	self.labelTitle.text = info.text
	self.id = info.id

	for _, data in ipairs(info.list) do
		local item = NGUITools.AddChild(self.grid_.gameObject, self.probItem)
		local itemRoot = item:NodeByName("itemRoot").gameObject
		local label = item:ComponentByName("probLabel", typeof(UILabel))
		local prob = data.weight * 100 / self.parent.allWeight
		label.text = prob - prob % 0.01 .. "%"

		xyd.getItemIcon({
			uiRoot = itemRoot,
			itemID = data.item_id,
			dragScrollView = self.parent.scroller_2
		})
	end

	self.grid_:Reposition()

	local lines = math.ceil(#info.list / 5)
	self.groupContent:GetComponent(typeof(UISprite)).height = 34 + lines * 137
	self.downLineY = -63 - 137 * lines

	self.downLine:Y(self.downLineY)

	self.isShow = true
end

function InfoItem:hide()
	self.downLine:Y(-37)
	self.groupContent:SetLocalScale(1, 0, 1)

	self.isShow = false
	self.imgArr_.transform.localEulerAngles = Vector3(0, 0, 90)
end

return DressBuyProbabilityWindow
