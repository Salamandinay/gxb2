local ActivityLostSpaceAwardNewWindow = class("ActivityLostSpaceAwardNewWindow", import(".BaseWindow"))
local LittleItem = class("LittleItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function ActivityLostSpaceAwardNewWindow:ctor(name, params)
	ActivityLostSpaceAwardNewWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LOST_SPACE)
	self.activityLostSpaceGiftData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LOST_SPACE_GIFTBAG)
	self.activityID = params.activityID
end

function ActivityLostSpaceAwardNewWindow:initWindow()
	self:getUIComponent()
	ActivityLostSpaceAwardNewWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function ActivityLostSpaceAwardNewWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel = self.groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.groupContent = self.groupAction:ComponentByName("groupContent", typeof(UISprite))
	self.textCol1 = self.groupContent:ComponentByName("textCol1", typeof(UILabel))
	self.textCol2 = self.groupContent:ComponentByName("textCol2", typeof(UILabel))
	self.textCol3 = self.groupContent:ComponentByName("textCol3", typeof(UILabel))
	self.iconCol2 = self.groupContent:ComponentByName("iconCol2", typeof(UISprite))
	self.iconCol3 = self.groupContent:ComponentByName("iconCol3", typeof(UISprite))
	self.scrollView = self.groupContent:NodeByName("scrollView").gameObject
	self.scrollViewUIScrollView = self.groupContent:ComponentByName("scrollView", typeof(UIScrollView))
	self.scrollViewUIPanel = self.groupContent:ComponentByName("scrollView", typeof(UIPanel))
	self.wrapContent = self.scrollView:NodeByName("wrapContent").gameObject
	self.wrapContentUIWrapContent = self.scrollView:ComponentByName("wrapContent", typeof(UIWrapContent))
	self.item_root = self.groupAction:NodeByName("item_root").gameObject
	self.wrapContentList = FixedWrapContent.new(self.scrollViewUIScrollView, self.wrapContentUIWrapContent, self.item_root, LittleItem, self)
	self.btnCon = self.groupAction:NodeByName("btnCon").gameObject
	self.btnGoActivity = self.btnCon:NodeByName("btnGoActivity").gameObject
	self.btnGoActivityLabel = self.btnGoActivity:ComponentByName("btnGoActivityLabel", typeof(UILabel))
	self.btnGoUnLock = self.btnCon:NodeByName("btnGoUnLock").gameObject
	self.btnGoUnLockLabel = self.btnGoUnLock:ComponentByName("btnGoUnLockLabel", typeof(UILabel))
end

function ActivityLostSpaceAwardNewWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.btnGoUnLock.gameObject).onClick = handler(self, function ()
		local lostSpaceMapWd = xyd.WindowManager.get():getWindow("activity_lost_space_map_window")

		if lostSpaceMapWd then
			xyd.WindowManager.get():closeWindow("activity_lost_space_map_window")
		end

		xyd.goWay(xyd.GoWayId.ACTIVITY_LOST_SPACE_GIFTBAG)
		self:close()
	end)
	UIEventListener.Get(self.btnGoActivity.gameObject).onClick = handler(self, function ()
		xyd.goWay(xyd.GoWayId.ACTIVITY_LOST_SPACE)
		self:close()
	end)
end

function ActivityLostSpaceAwardNewWindow:layout()
	self.titleLabel.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.textCol1.text = __("ACTIVITY_LOST_SPACE_TEXT01")
	self.textCol2.text = __("ACTIVITY_LOST_SPACE_TEXT02")
	self.textCol3.text = __("ACTIVITY_LOST_SPACE_TEXT03")
	self.btnGoUnLockLabel.text = __("ACTIVITY_LOST_SPACE_TEXT04")
	self.btnGoActivityLabel.text = __("ACTIVITY_LOST_SPACE_TEXT05")

	xyd.setUISpriteAsync(self.iconCol2, nil, "activity_lost_space_icon_djbx90_2")
	xyd.setUISpriteAsync(self.iconCol3, nil, "activity_lost_space_icon_djb2x90")

	if self.activityID == xyd.ActivityID.ACTIVITY_LOST_SPACE then
		self.btnGoActivity.gameObject:SetActive(false)

		if self.activityLostSpaceGiftData:checkBuy() then
			self.btnGoUnLock.gameObject:SetActive(false)
		else
			self.btnGoUnLock.gameObject:SetActive(true)
		end
	elseif self.activityID == xyd.ActivityID.ACTIVITY_LOST_SPACE_GIFTBAG then
		self.btnGoActivity.gameObject:SetActive(true)
		self.btnGoUnLock.gameObject:SetActive(false)
	end

	local arr = {}
	local jumpToId = -1

	for i = 1, 30 do
		local temp = {
			index = i
		}

		table.insert(arr, temp)
	end

	if self.activityData.detail.stage_id <= 30 then
		jumpToId = self.activityData.detail.stage_id
	else
		jumpToId = 30
	end

	self.wrapContentList:setInfos(arr, {})
	self.scrollViewUIScrollView:ResetPosition()

	if jumpToId > 3 then
		local initialValue = self.scrollViewUIScrollView.gameObject.transform.localPosition.y

		self:waitForFrame(2, function ()
			local sp = self.scrollViewUIScrollView.gameObject:GetComponent(typeof(SpringPanel))
			sp = sp or self.scrollViewUIScrollView.gameObject:AddComponent(typeof(SpringPanel))

			sp.Begin(sp.gameObject, Vector3(0, initialValue + self:GetJumpToInfoDis(arr[jumpToId]), 0), 8)
		end)
	end
end

function ActivityLostSpaceAwardNewWindow:GetJumpToInfoDis(info)
	local currIndex = nil

	for index, info2 in ipairs(self.wrapContentList:getInfos()) do
		if info2 == info then
			currIndex = index

			break
		end
	end

	if not currIndex then
		return
	end

	local panel = self.scrollViewUIPanel
	local height = panel.baseClipRegion.w
	local itemSize = self.wrapContentList:getWrapContent().itemSize
	local lastIndex = #self.wrapContentList:getInfos()
	local height2 = lastIndex * itemSize

	if height >= height2 then
		return 0
	end

	local displayNum = math.ceil(height / itemSize)
	local half = math.floor(displayNum / 2)
	local maxDeltaY = height2 - height
	local deltaY = (currIndex - 1) * itemSize
	deltaY = math.min(deltaY, maxDeltaY)

	return deltaY
end

function LittleItem:ctor(goItem, parent)
	self.goItem_ = goItem
	self.parent = parent

	LittleItem.super.ctor(self, goItem)
end

function LittleItem:getUIComponent()
	self.name = self.go:ComponentByName("name", typeof(UILabel))
	self.baseItemGroup = self.go:NodeByName("baseItemGroup").gameObject
	self.baseItemGroupUILayout = self.go:ComponentByName("baseItemGroup", typeof(UILayout))
	self.highItemGroup = self.go:NodeByName("highItemGroup").gameObject
	self.highItemGroupUILayout = self.go:ComponentByName("highItemGroup", typeof(UILayout))
end

function LittleItem:initUI()
	self:getUIComponent()
end

function LittleItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.index = info.index
	local allLength = #xyd.tables.activityLostSpaceAwardsTable:getIDs()
	local baseAwards = xyd.tables.activityLostSpaceAwardsTable:getAward(self.index)
	local baseParams = {
		isAddUIDragScrollView = true,
		isShowSelected = false,
		uiRoot = self.baseItemGroup.gameObject,
		itemID = baseAwards[1],
		num = baseAwards[2]
	}

	if not self.baseIcon then
		self.baseIcon = xyd.getItemIcon(baseParams, xyd.ItemIconType.ADVANCE_ICON)
	else
		self.baseIcon:SetActive(true)
		self.baseIcon:setInfo(baseParams)
	end

	self.baseIcon:setScale(0.7037037037037037)

	if self.index < 30 then
		if self.index < self.parent.activityData.detail.stage_id then
			self.baseIcon:setChoose(true)
		else
			self.baseIcon:setChoose(false)
		end
	elseif self.parent.activityData.detail.stage_id <= allLength then
		self.baseIcon:setChoose(false)
	else
		self.baseIcon:setChoose(true)
	end

	local highAwards = xyd.tables.activityLostSpaceAwardsTable:getExtraAward(self.index)
	local highParams = {
		isAddUIDragScrollView = true,
		isShowSelected = false,
		uiRoot = self.highItemGroup.gameObject,
		itemID = highAwards[1],
		num = highAwards[2]
	}

	if not self.highIcon then
		self.highIcon = xyd.getItemIcon(highParams, xyd.ItemIconType.ADVANCE_ICON)
	else
		self.highIcon:SetActive(true)
		self.highIcon:setInfo(highParams)
	end

	self.highIcon:setScale(0.7037037037037037)

	if self.index == 30 then
		self.name.text = __("ACTIVITY_LOST_SPACE_AWARD_NUM", "30 - " .. allLength)
	else
		self.name.text = __("ACTIVITY_LOST_SPACE_AWARD_NUM", tostring(self.index))
	end

	if self.parent.activityLostSpaceGiftData:checkBuy() then
		if self.index < 30 then
			if self.index < self.parent.activityData.detail.stage_id then
				self.highIcon:setChoose(true)
			else
				self.highIcon:setChoose(false)
			end
		elseif self.parent.activityData.detail.stage_id <= allLength then
			self.highIcon:setChoose(false)
		else
			self.highIcon:setChoose(true)
		end
	else
		self.highIcon:setLock(true)
	end
end

return ActivityLostSpaceAwardNewWindow
