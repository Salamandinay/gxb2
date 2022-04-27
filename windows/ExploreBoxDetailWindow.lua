local ExploreBoxDetailWindow = class("ExploreBoxDetailWindow", import(".BaseWindow"))
local boxTable = xyd.tables.adventureBoxTable
local boxNum = 6

function ExploreBoxDetailWindow:ctor(name, params)
	ExploreBoxDetailWindow.super.ctor(self, name, params)

	self.curBoxIndex = 1
end

function ExploreBoxDetailWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ExploreBoxDetailWindow:getUIComponent()
	local groupMain = self.window_:NodeByName("groupMain").gameObject
	local groupTop = groupMain:NodeByName("groupTop").gameObject
	self.labelTitle = groupTop:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupTop:NodeByName("closeBtn").gameObject
	local groupMiddle = groupMain:NodeByName("groupMiddle").gameObject
	self.leftArrow = groupMiddle:NodeByName("leftArrow").gameObject
	self.rightArrow = groupMiddle:NodeByName("rightArrow").gameObject
	self.boxGrid = groupMiddle:ComponentByName("boxPanel/boxGrid", typeof(UIGrid))
	self.boxItem = groupMiddle:NodeByName("boxItem").gameObject
	local groupBottom = groupMain:NodeByName("groupBottom").gameObject
	self.scrollerView = groupBottom:ComponentByName("scroller_", typeof(UIScrollView))
	self.labelFixAward = self.scrollerView:ComponentByName("labelFixAward", typeof(UILabel))
	self.fixAwardContent = self.scrollerView:ComponentByName("fixAwardContent", typeof(UIGrid))
	self.labelRanAward = self.scrollerView:ComponentByName("labelRanAward", typeof(UILabel))
	self.ranAwardContent = self.scrollerView:ComponentByName("ranAwardContent", typeof(UIGrid))
	self.labelTips = groupBottom:ComponentByName("labelTips", typeof(UILabel))
	self.awardItem = groupBottom:NodeByName("awardItem").gameObject
end

function ExploreBoxDetailWindow:layout()
	self.labelFixAward.text = __("TRAVEL_MAIN_TEXT32")
	self.labelRanAward.text = __("TRAVEL_MAIN_TEXT33")
	self.labelTips.text = __("TRAVEL_MAIN_TEXT34")

	if xyd.Global.lang == "fr_fr" then
		self.labelTips.fontSize = 18
	end

	local ids = boxTable:getIDs()
	self.boxList = {}

	for _, id in ipairs(ids) do
		local box = NGUITools.AddChild(self.boxGrid.gameObject, self.boxItem)

		xyd.setUISpriteAsync(box:GetComponent(typeof(UISprite)), nil, "icon_bx_" .. id)

		UIEventListener.Get(box).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
			self:moveBox(id)
		end

		if self.curBoxIndex == id then
			box:SetLocalScale(1.05, 1.05, 1.05)
		else
			box:SetLocalScale(0.756, 0.756, 0.756)
		end

		table.insert(self.boxList, box)
	end

	self.boxGrid:Reposition()
	self:updateContent()
end

function ExploreBoxDetailWindow:moveBox(index)
	if self.curBoxIndex == index or self.isMove then
		return
	else
		local detla = 1 - index
		self.isMove = true

		self.boxList[self.curBoxIndex]:SetLocalScale(0.756, 0.756, 0.756)

		self.curBoxIndex = index

		self.boxList[self.curBoxIndex]:SetLocalScale(1.05, 1.05, 1.05)

		local sequence = self:getSequence()

		sequence:Append(self.boxGrid.transform:DOLocalMoveX(170 * detla, 0.4))
		sequence:AppendCallback(function ()
			sequence:Kill(false)

			sequence = nil
			self.isMove = false

			self:updateContent()
		end)
	end
end

function ExploreBoxDetailWindow:updateContent()
	self.labelTitle.text = __("TRAVEL_MAIN_TEXT24", self.curBoxIndex)

	NGUITools.DestroyChildren(self.fixAwardContent.transform)

	local fixAwards = boxTable:getFixAward(self.curBoxIndex)

	for _, item in ipairs(fixAwards) do
		local awardItem = NGUITools.AddChild(self.fixAwardContent.gameObject, self.awardItem)
		local iconNode = awardItem:NodeByName("icon").gameObject
		local probLabel = awardItem:ComponentByName("probLabel", typeof(UILabel))

		xyd.getItemIcon({
			scale = 0.9,
			uiRoot = iconNode,
			itemID = item[1],
			num = item[2],
			dragScrollView = self.scrollerView
		})

		probLabel.text = "100%"
	end

	self.fixAwardContent:Reposition()
	NGUITools.DestroyChildren(self.ranAwardContent.transform)

	local ranAwards = self:getRanAwards()

	for _, items in ipairs(ranAwards) do
		local awardItem = NGUITools.AddChild(self.ranAwardContent.gameObject, self.awardItem)
		local iconNode = awardItem:NodeByName("icon").gameObject
		local probLabel = awardItem:ComponentByName("probLabel", typeof(UILabel))
		local item = items.item

		xyd.getItemIcon({
			scale = 0.9,
			uiRoot = iconNode,
			itemID = item[1],
			num = item[2],
			dragScrollView = self.scrollerView
		})

		probLabel.text = items.prob .. "%"
	end

	self.ranAwardContent:Reposition()
end

function ExploreBoxDetailWindow:getRanAwards()
	local awards = {}
	local dropboxID1 = boxTable:getRandAwardId1(self.curBoxIndex)
	local drop1 = xyd.tables.dropboxShowTable:getIdsByBoxId(dropboxID1)

	for i = 1, #drop1.list do
		local id = drop1.list[i]
		local item = xyd.tables.dropboxShowTable:getItem(id)
		local weight = xyd.tables.dropboxShowTable:getWeight(id)

		table.insert(awards, {
			item = item,
			prob = weight / drop1.all_weight * 100
		})
	end

	return awards
end

function ExploreBoxDetailWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.leftArrow).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		if self.curBoxIndex == 1 then
			return
		else
			self:moveBox(self.curBoxIndex - 1)
		end
	end

	UIEventListener.Get(self.rightArrow).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		if self.curBoxIndex == boxNum then
			return
		else
			self:moveBox(self.curBoxIndex + 1)
		end
	end
end

return ExploreBoxDetailWindow
