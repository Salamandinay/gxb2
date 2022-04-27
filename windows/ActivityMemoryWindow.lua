local ActivityModel = xyd.models.activity
local ActivityMemoryWindow = class("StoryMemoryWindow", import(".StoryMemoryWindow"))
local BaseWindow = import(".BaseWindow")

function ActivityMemoryWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.source_list_ = {}
	self.fort_id_ = params.fort_id
end

local StoryMemoryItem = ActivityMemoryWindow.super.getWindowItem()
local ActivityMemoryWindowItem = class("ActivityMemoryWindowItem", StoryMemoryItem)

function ActivityMemoryWindowItem:ctor(go, parent)
	ActivityMemoryWindowItem.super.ctor(self, go, parent)
end

function ActivityMemoryWindowItem:onClick()
	if self.lock_ then
		xyd:showToast(__("LOCK_MEMORY"))

		return
	end

	xyd.WindowManager.get():openWindow("story_window", {
		story_type = xyd.StoryType.ACTIVITY,
		story_list = xyd.tables.activityPlotListTable:getMemoryPlotId(self.id_)
	})
end

function ActivityMemoryWindowItem:update(index, realIndex, info)
	ActivityMemoryWindowItem.super.update(self, index, realIndex, info)
end

function ActivityMemoryWindowItem:updateLayout()
	local id = self.id_
	self.titleLable_.text = __(xyd.tables.activityPlotListTextTable:getName(id))
	local iconName = tostring(xyd.tables.activityPlotListTable:getChapterIcon(id))

	xyd.setUISpriteAsync(self.iconImg_, nil, iconName, nil, )
end

function ActivityMemoryWindow:initWindow()
	BaseWindow.initWindow(self)

	self.windowTop = import("app.components.WindowTop").new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)

	local winTrans = self.window_.transform
	local main = winTrans:NodeByName("main").gameObject
	self.scrollView_ = main:ComponentByName("mid/scrollview", typeof(UIScrollView))
	self.wrapContent_ = main:ComponentByName("mid/scrollview/grid", typeof(MultiRowWrapContent))
	local itemRoot = main:ComponentByName("mid/storyMemoryWindowItem", typeof(UIWidget)).gameObject
	self.multiWrapStory_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.wrapContent_, itemRoot, ActivityMemoryWindowItem, self)

	self:initSource()
	XYDCo.WaitForFrame(1, function ()
		self:updateList()
	end, nil)
end

function ActivityMemoryWindow:checkLock(id)
	if ActivityModel:checkPlot(tonumber(id)) then
		return false
	end

	return true
end

function ActivityMemoryWindow:updateList()
	self.multiWrapStory_:setInfos(self.source_list_, {})
	self.multiWrapStory_:resetScrollView()
end

function ActivityMemoryWindow:initSource()
	local ids = xyd.tables.activityPlotListTable:getIdsByFort(self.fort_id_)

	for i = 1, #ids do
		local id = ids[i]

		table.insert(self.source_list_, {
			id = id,
			lock = self:checkLock(id)
		})
	end

	table.sort(self.source_list_, function (a, b)
		return tonumber(a.id) < tonumber(b.id)
	end)
end

return ActivityMemoryWindow
