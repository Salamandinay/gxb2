local BaseWindow = import(".BaseWindow")
local ActivityFishingCollectWindow = class("ActivityFishingCollectWindow", BaseWindow)

function ActivityFishingCollectWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.fishDatas = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FISHING).detail.fishs

	for i = 1, #self.fishDatas do
		if self.fishDatas[i].num ~= 0 then
			if self.fishDatas[i].max == 0 then
				self.fishDatas[i].max = self.fishDatas[i].min
			end

			if self.fishDatas[i].min == 0 then
				self.fishDatas[i].min = self.fishDatas[i].max
			end
		end
	end

	self.curInfoID = 0
end

function ActivityFishingCollectWindow:initWindow()
	self:getUIComponent()
	ActivityFishingCollectWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityFishingCollectWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.groupMain = self.groupAction:NodeByName("groupMain").gameObject
	self.scrollView = self.groupMain:ComponentByName("scrollView", typeof(UIScrollView))
	self.groupItems = self.scrollView:NodeByName("groupItems").gameObject

	for i = 1, 6 do
		self["item" .. i] = self.groupItems:ComponentByName("item" .. i, typeof(UISprite))
	end
end

function ActivityFishingCollectWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_FISH_BOOK")

	for i = 1, 6 do
		xyd.setDragScrollView(self["item" .. i].gameObject, self.scrollView)

		local groupInfo = self["item" .. i]:NodeByName("groupInfo").gameObject

		groupInfo:SetActive(false)

		if self.fishDatas[i].num == 0 then
			xyd.applyChildrenGrey(self["item" .. i].gameObject)
		end
	end
end

function ActivityFishingCollectWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	for i = 1, 6 do
		UIEventListener.Get(self["item" .. i].gameObject).onClick = function ()
			self:showInfo(i)
		end
	end
end

function ActivityFishingCollectWindow:showInfo(index)
	if self.fishDatas[index].num == 0 then
		xyd.alertTips(__("ACTIVITY_FISH_UNLOCK_TIPS"))
	elseif self.curInfoID == index then
		self.curInfoID = 0
		local groupInfo = self["item" .. index]:NodeByName("groupInfo").gameObject

		groupInfo:SetActive(false)

		for i = index + 1 + index % 2, 6 do
			self["item" .. i].gameObject:SetLocalPosition(self["item" .. i].gameObject.transform.localPosition.x, self["item" .. i].gameObject.transform.localPosition.y + 313, 0)
		end

		self.scrollView:ResetPosition()
	else
		if self.curInfoID ~= 0 then
			local groupInfo = self["item" .. self.curInfoID]:NodeByName("groupInfo").gameObject

			groupInfo:SetActive(false)

			for i = self.curInfoID + 1 + self.curInfoID % 2, 6 do
				self["item" .. i].gameObject:SetLocalPosition(self["item" .. i].gameObject.transform.localPosition.x, self["item" .. i].gameObject.transform.localPosition.y + 313, 0)
			end

			self.scrollView:ResetPosition()
		end

		self.curInfoID = index
		local groupInfo = self["item" .. self.curInfoID]:NodeByName("groupInfo").gameObject

		groupInfo:SetActive(true)
		xyd.setDragScrollView(groupInfo, self.scrollView)

		local labelName = groupInfo:ComponentByName("labelName", typeof(UILabel))
		local imgFish = groupInfo:ComponentByName("imgFish", typeof(UISprite))
		local labelNum = groupInfo:ComponentByName("labelNum", typeof(UILabel))
		local labelMaxLen = groupInfo:ComponentByName("labelMaxLen", typeof(UILabel))
		local labelMinLen = groupInfo:ComponentByName("labelMinLen", typeof(UILabel))
		local dataNum = groupInfo:ComponentByName("dataNum", typeof(UILabel))
		local dataMaxLen = groupInfo:ComponentByName("dataMaxLen", typeof(UILabel))
		local dataMinLen = groupInfo:ComponentByName("dataMinLen", typeof(UILabel))
		local iconMax = groupInfo:ComponentByName("iconMax", typeof(UISprite))
		local iconMin = groupInfo:ComponentByName("iconMin", typeof(UISprite))
		local labelDesc = groupInfo:ComponentByName("labelDesc", typeof(UILabel))
		labelName.text = xyd.tables.activityFishingTextTable:getName(index)

		xyd.setUISpriteAsync(imgFish, nil, xyd.tables.activityFishingMainTable:getPic(index), function ()
			imgFish.transform.localScale = Vector3(0.6, 0.6, 1)
		end, nil, true)

		labelNum.text = __("ACTIVITY_FISH_BOOK_TEXT01")
		labelMaxLen.text = __("ACTIVITY_FISH_BOOK_TEXT02")
		labelMinLen.text = __("ACTIVITY_FISH_BOOK_TEXT03")
		dataNum.text = tostring(self.fishDatas[index].num)
		dataMaxLen.text = string.format("%.2f", self.fishDatas[index].max) .. "cm"
		dataMinLen.text = string.format("%.2f", self.fishDatas[index].min) .. "cm"
		local goldLenRange = xyd.tables.activityFishingMainTable:getRange1(index)
		local silverLenRange = xyd.tables.activityFishingMainTable:getRange2(index)

		if goldLenRange[2][1] <= self.fishDatas[index].max then
			xyd.setUISpriteAsync(iconMax, nil, "activity_fishing_icon_gold")
		elseif silverLenRange[2][1] <= self.fishDatas[index].max then
			xyd.setUISpriteAsync(iconMax, nil, "activity_fishing_icon_silver")
		end

		if self.fishDatas[index].min <= goldLenRange[1][2] then
			xyd.setUISpriteAsync(iconMin, nil, "activity_fishing_icon_gold")
		elseif self.fishDatas[index].min <= silverLenRange[1][2] then
			xyd.setUISpriteAsync(iconMin, nil, "activity_fishing_icon_silver")
		end

		labelDesc.text = xyd.tables.activityFishingTextTable:getDesc(index)

		for i = index + 1 + index % 2, 6 do
			self["item" .. i].gameObject:SetLocalPosition(self["item" .. i].gameObject.transform.localPosition.x, self["item" .. i].gameObject.transform.localPosition.y - 313, 0)
		end

		if index == 5 or index == 6 then
			self.scrollView:MoveRelative(Vector3(0, 309, 0))
		end
	end
end

return ActivityFishingCollectWindow
