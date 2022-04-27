local ActivityTimeGambleDropWindow = class("ActivityTimeGambleDropWindow", import(".BaseWindow"))
local ActivityTimeGambleDropItem = class("ActivityTimeGambleDropItem", import("app.components.CopyComponent"))
local RomanNum = {
	"I",
	"II",
	"III",
	"IV",
	"V",
	"VI",
	"VII",
	"VIII",
	"IX",
	"X",
	"XI",
	"XII"
}
local colorIndex = {
	Color.New2(3245614847.0),
	Color.New2(2927403519.0),
	Color.New2(3160704767.0),
	Color.New2(1532732927)
}

function ActivityTimeGambleDropItem:ctor(go, info, index, parent)
	self.parent_ = parent

	ActivityTimeGambleDropItem.super.ctor(self, go)

	self.info_ = info
	self.index_ = index

	table.sort(self.info_)
	self:initUI()
	self:layout()
end

function ActivityTimeGambleDropItem:initUI()
	self.bg = self.go:ComponentByName("bg", typeof(UIWidget))
	self.numItem = self.go:NodeByName("numItem").gameObject
	self.groupNum = self.go:ComponentByName("groupNum", typeof(UIGrid))
	self.groupItem = self.go:ComponentByName("groupItem", typeof(UIGrid))
end

function ActivityTimeGambleDropItem:layout()
	for _, id in ipairs(self.info_) do
		local newNum = NGUITools.AddChild(self.groupNum.gameObject, self.numItem)
		local newNumBg = newNum:GetComponent(typeof(UISprite))
		local newNumLabel = newNum:ComponentByName("numLabel", typeof(UILabel))
		newNumLabel.text = RomanNum[id]
		newNumLabel.color = colorIndex[self.index_]

		xyd.setUISpriteAsync(newNumBg, nil, "activity_time_gamble_drop_num_bg" .. self.index_)
	end

	local dropBoxID = xyd.tables.activityTimeGambleTable:getDropboxId(self.info_[1])
	local showIDs = xyd.tables.dropboxShowTable:getIdsByBoxId(dropBoxID)

	table.sort(showIDs.list, function (a, b)
		return tonumber(b) < tonumber(a)
	end)

	for _, showID in ipairs(showIDs.list) do
		local itemData = xyd.tables.dropboxShowTable:getItem(showID)

		xyd.getItemIcon({
			show_has_num = true,
			notShowGetWayBtn = true,
			scale = 0.7962962962962963,
			uiRoot = self.groupItem.gameObject,
			itemID = itemData[1],
			num = itemData[2],
			dragScrollView = self.parent_.scrollView_
		})
	end

	self.bg.height = 73 + math.ceil(#showIDs.list / 6) * 95

	self.groupNum:Reposition()
	self.groupItem:Reposition()
end

function ActivityTimeGambleDropWindow:ctor(name, params)
	ActivityTimeGambleDropWindow.super.ctor(self, name, params)
end

function ActivityTimeGambleDropWindow:initWindow()
	ActivityTimeGambleDropWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
end

function ActivityTimeGambleDropWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.labelWinTitle_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.gridList_ = winTrans:ComponentByName("scrollView/grid", typeof(UITable))
	self.dropItemRoot_ = winTrans:NodeByName("dropItem").gameObject
end

function ActivityTimeGambleDropWindow:layout()
	self.labelWinTitle_.text = __("ACTIVITY_TIME_REFRESH_ITEM")

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	local showList = xyd.tables.activityTimeGambleTable:getShowGroup()

	self.scrollView_:ResetPosition()

	for idx, itemInfo in ipairs(showList) do
		local newItemRoot = NGUITools.AddChild(self.gridList_.gameObject, self.dropItemRoot_)

		ActivityTimeGambleDropItem.new(newItemRoot, itemInfo, idx, self)
		self.gridList_:Reposition()

		if idx == #showList then
			self:waitForFrame(1, function ()
				self.scrollView_:ResetPosition()
			end)
		end
	end
end

return ActivityTimeGambleDropWindow
