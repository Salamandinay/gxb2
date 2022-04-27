local BaseWindow = import(".BaseWindow")
local ActivitySecretTreasureHuntEventWindow = class("ActivitySecretTreasureHuntEventWindow", BaseWindow)
local ActivitySecretTreasureHuntEventItem = class("ActivitySecretTreasureHuntEventItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ItemTable = xyd.tables.itemTable

function ActivitySecretTreasureHuntEventWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT)
end

function ActivitySecretTreasureHuntEventWindow:getPrefabPath()
	return "Prefabs/Windows/activity_secret_treasure_hunt_event_window"
end

function ActivitySecretTreasureHuntEventWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:Register()
	self:initUIComponent()
	self:initData()
end

function ActivitySecretTreasureHuntEventWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.content = self.groupAction:NodeByName("content").gameObject
	self.contentGroup = self.content:NodeByName("contentGroup").gameObject
	self.awardContentGroup = self.contentGroup:NodeByName("awardContentGroup").gameObject
	self.bg_ = self.awardContentGroup:ComponentByName("bg_", typeof(UISprite))
	self.drag = self.awardContentGroup:NodeByName("drag").gameObject
	self.scroller = self.awardContentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.item = self.scroller:NodeByName("item").gameObject
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.itemGroup_layout = self.scroller:ComponentByName("itemGroup", typeof(UILayout))
	self.labelLeft = self.awardContentGroup:ComponentByName("labelLeft", typeof(UILabel))
	self.labelRight = self.awardContentGroup:ComponentByName("labelRight", typeof(UILabel))
end

function ActivitySecretTreasureHuntEventWindow:addTitle()
	self.labelWinTitle.text = __("ACTIVITY_SECTRETTREASURE_TEXT15")
end

function ActivitySecretTreasureHuntEventWindow:initUIComponent()
	self.labelLeft.text = __("ACTIVITY_SECTRETTREASURE_TEXT15")
	self.labelRight.text = __("ACTIVITY_SECTRETTREASURE_TEXT26")
end

function ActivitySecretTreasureHuntEventWindow:initData()
	self.data = {}
	local ids = xyd.tables.activitySecretTreasureHuntEventTextTable:getIDs()
	self.maxId = #ids

	for i = 1, #ids do
		local id = tonumber(i)
		local iconName = xyd.tables.activitySecretTreasureEventTable:getIcon(id)
		local title = xyd.tables.activitySecretTreasureHuntEventTextTable:getName(id)
		local desc = xyd.tables.activitySecretTreasureHuntEventTextTable:getDes(id)
		local showID = xyd.tables.activitySecretTreasureHuntEventTextTable:getShowID(id)

		table.insert(self.data, {
			id = tonumber(id),
			iconName = iconName,
			title = title,
			desc = desc,
			maxId = self.maxId,
			showID = showID
		})
	end

	local function sort_func(a, b)
		return a.showID < b.showID
	end

	table.sort(self.data, sort_func)

	if self.items == nil then
		self.items = {}

		for i = 1, #self.data do
			local item = NGUITools.AddChild(self.itemGroup, self.item)
			local item = ActivitySecretTreasureHuntEventItem.new(item)

			item:setInfo(self.data[i])
			table.insert(self.items, item)
		end
	else
		for i = 1, #self.data do
			self.items[i]:setInfo(self.data[i])
		end
	end

	self.itemGroup_layout:Reposition()
	self.scroller:ResetPosition()
end

function ActivitySecretTreasureHuntEventWindow:Register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow("activity_secret_treasure_hunt_event_window")
	end
end

function ActivitySecretTreasureHuntEventItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function ActivitySecretTreasureHuntEventItem:getUIComponent()
	self.bg_ = self.go:ComponentByName("bg_", typeof(UISprite))
	self.eventIcon = self.go:ComponentByName("eventIcon", typeof(UISprite))
	self.line = self.go:ComponentByName("line", typeof(UISprite))
	self.labeDesc = self.go:ComponentByName("labeDesc", typeof(UILabel))
	self.labeDesc_copy = self.go:ComponentByName("labeDesc_copy", typeof(UILabel))
	self.labeTitle = self.go:ComponentByName("labeTitle", typeof(UILabel))
end

function ActivitySecretTreasureHuntEventItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	self.id = params.id
	self.iconName = params.iconName
	self.title = params.title
	self.desc = params.desc
	self.labeDesc.text = self.desc
	self.labeDesc_copy.text = self.desc
	self.labeTitle.text = self.title

	xyd.setUISpriteAsync(self.eventIcon, nil, self.iconName)

	local height = self.labeDesc.height

	if height > 70 then
		self.bg_.height = self.bg_.height + height - 70
		self.go:ComponentByName("", typeof(UIWidget)).height = self.bg_.height

		self.eventIcon:Y(-60 - (height - 70) / 2)
		self.line:Y(-60 - (height - 70) / 2)
	end
end

return ActivitySecretTreasureHuntEventWindow
