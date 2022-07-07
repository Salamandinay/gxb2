local BaseWindow = import(".BaseWindow")
local AwardPreviewWithChangeWindow = class("AwardSelectWindow", BaseWindow)
local AwardPreviewWithChangeItem = class("AwardPreviewWithChangeItem", import("app.components.CopyComponent"))

function AwardPreviewWithChangeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.dropBoxId = params.dropBoxId
end

function AwardPreviewWithChangeWindow:initWindow()
	self:getUIComponent()
	AwardPreviewWithChangeWindow.super.initWindow(self)
	self:layout()
	self:initItemGroupAll()
end

function AwardPreviewWithChangeWindow:getUIComponent()
	self.trans = self.window_
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.operationBg = self.groupAction:ComponentByName("operationBg", typeof(UISprite))
	self.labelWinTitle_ = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.explainText = self.groupAction:ComponentByName("explainText", typeof(UILabel))
	self.itemGroupAll = self.groupAction:NodeByName("itemGroupAll").gameObject
	self.itemGroupAll_grid = self.groupAction:ComponentByName("itemGroupAll", typeof(UIGrid))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.item = self.groupAction:NodeByName("item").gameObject
end

function AwardPreviewWithChangeWindow:layout()
	self.labelWinTitle_.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.explainText.text = __("ACTIVITY_4BIRTHDAY_TEXT07")
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function AwardPreviewWithChangeWindow:initItemGroupAll()
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
	self.bg.height = math.ceil(#awardsList / 5) * 140 + 157

	NGUITools.DestroyChildren(self.itemGroupAll.transform)

	for i in ipairs(awardsList) do
		local tmp = NGUITools.AddChild(self.itemGroupAll.gameObject, self.item.gameObject)
		local item = AwardPreviewWithChangeItem.new(tmp, awardsList[i], self)

		table.insert(self.tempArr, item)
	end

	self.itemGroupAll_grid:Reposition()
end

function AwardPreviewWithChangeItem:ctor(go, data, parent)
	AwardPreviewWithChangeItem.super.ctor(self, go, parent)

	self.parent = parent
	self.data = data

	self:initUIComponent()
end

function AwardPreviewWithChangeItem:initUIComponent()
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.selectedGrey = self.go:ComponentByName("selectedGrey", typeof(UISprite))
	self.selectedMark = self.go:ComponentByName("selectedMark", typeof(UISprite))
	self.currentMark = self.go:ComponentByName("currentMark", typeof(UISprite))
	self.turnsLabel = self.go:ComponentByName("turnsLabel", typeof(UILabel))

	self:updateInfo()
end

function AwardPreviewWithChangeItem:updateInfo()
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
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})
	local strArr = xyd.split(self.data[3], "%.", false, true)

	if #strArr == 2 and strArr[2] == "00" then
		self.turnsLabel.text = strArr[1] .. "%"
	else
		self.turnsLabel.text = self.data[3] .. "%"
	end
end

return AwardPreviewWithChangeWindow
