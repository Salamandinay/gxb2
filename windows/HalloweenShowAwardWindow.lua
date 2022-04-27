local BaseWindow = import(".BaseWindow")
local HalloweenShowAwardWindow = class("AwardSelectWindow", BaseWindow)
local HalloweenShowAwardItem = class("HalloweenShowAwardItem", import("app.components.CopyComponent"))

function HalloweenShowAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.currentRound = params.currentRound
	self.dropBoxId = xyd.tables.miscTable:getNumber("activity_lasso_dropbox", "value")

	if self.currentRound < 15 then
		local arr = xyd.tables.miscTable:split2num("activity_lasso_gamble", "value", "|")
		self.dropBoxId = arr[self.currentRound]
	end
end

function HalloweenShowAwardWindow:initWindow()
	self:getUIComponent()
	HalloweenShowAwardWindow.super.initWindow(self)
	self:layout()
	self:initItemGroupAll()
end

function HalloweenShowAwardWindow:getUIComponent()
	self.trans = self.window_
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.operationBg = self.groupAction:ComponentByName("operationBg", typeof(UISprite))
	self.labelWinTitle_ = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.explainText = self.groupAction:ComponentByName("explainText", typeof(UILabel))
	self.awardScroller = self.groupAction:ComponentByName("awardScroller", typeof(UIScrollView))
	self.awardScroller_uipanel = self.groupAction:ComponentByName("awardScroller", typeof(UIPanel))
	self.itemGroupAll = self.awardScroller:NodeByName("itemGroupAll").gameObject
	self.itemGroupAll_layout = self.awardScroller:ComponentByName("itemGroupAll", typeof(UILayout))
	self.drag = self.groupAction:NodeByName("drag").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.anniversary_cake_end_award_item = self.groupAction:NodeByName("anniversary_cake_end_award_item").gameObject
end

function HalloweenShowAwardWindow:layout()
	self.labelWinTitle_.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.explainText.text = __("ACTIVITY_HALLOWEEN_TEXT4")
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function HalloweenShowAwardWindow:initItemGroupAll()
	local showDropBox = xyd.tables.dropboxShowTable:getIdsByBoxId(self.dropBoxId)
	local awardsList = {}
	self.allweight = showDropBox.all_weight

	for k, v in ipairs(showDropBox.list) do
		local item = xyd.tables.dropboxShowTable:getItem(v)
		local weight = xyd.tables.dropboxShowTable:getWeight(v)

		table.insert(awardsList, {
			item[1],
			item[2],
			string.format("%.2f", weight * 100 / self.allweight)
		})
	end

	self.tempArr = {}

	if #awardsList == 4 then
		self.itemGroupAll_layout.gap = Vector2(35, 0)
	else
		self.itemGroupAll_layout.gap = Vector2(24, 0)
	end

	NGUITools.DestroyChildren(self.itemGroupAll.transform)

	for i in ipairs(awardsList) do
		local tmp = NGUITools.AddChild(self.itemGroupAll.gameObject, self.anniversary_cake_end_award_item.gameObject)
		local item = HalloweenShowAwardItem.new(tmp, awardsList[i], self)

		table.insert(self.tempArr, item)
	end

	self.itemGroupAll_layout:Reposition()
	self.awardScroller:ResetPosition()
end

function HalloweenShowAwardItem:ctor(go, data, parent)
	HalloweenShowAwardItem.super.ctor(self, go, parent)

	self.parent = parent
	self.data = data

	self:initUIComponent()
end

function HalloweenShowAwardItem:initUIComponent()
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.selectedGrey = self.go:ComponentByName("selectedGrey", typeof(UISprite))
	self.selectedMark = self.go:ComponentByName("selectedMark", typeof(UISprite))
	self.currentMark = self.go:ComponentByName("currentMark", typeof(UISprite))
	self.turnsLabel = self.go:ComponentByName("turnsLabel", typeof(UILabel))

	self:updateInfo()
end

function HalloweenShowAwardItem:updateInfo()
	if not self.data[1] then
		return
	end

	if self.itemIcon then
		NGUITools.DestroyChildren(self.itemGroup.transform)
	end

	self.itemIcon = xyd.getItemIcon({
		show_has_num = true,
		noClickSelected = true,
		notShowGetWayBtn = true,
		uiRoot = self.itemGroup.gameObject,
		itemID = self.data[1],
		num = self.data[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		panel = self.parent.awardScroller_uipanel
	})
	local strArr = xyd.split(self.data[3], "%.", false, true)

	if #strArr == 2 and strArr[2] == "00" then
		self.turnsLabel.text = strArr[1] .. "%"
	else
		self.turnsLabel.text = self.data[3] .. "%"
	end
end

return HalloweenShowAwardWindow
