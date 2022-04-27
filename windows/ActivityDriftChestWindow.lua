local BaseWindow = import(".BaseWindow")
local ActivityDriftChestWindow = class("ActivityDriftChestWindow", BaseWindow)

function ActivityDriftChestWindow:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.paramsItems = params.items
	self.items = {}

	for i, v in pairs(self.paramsItems) do
		table.insert(self.items, {
			itemID = tonumber(i),
			itemNum = tonumber(v)
		})
	end

	table.sort(self.items, function (a, b)
		return a.itemID < b.itemID
	end)
end

function ActivityDriftChestWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityDriftChestWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.title = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject

	for i = 1, 9 do
		self["iconGroup" .. i] = self.groupAction:NodeByName("iconGroup" .. i)
	end

	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
end

function ActivityDriftChestWindow:layout()
	self.title.text = __("ACTIVITY_LAFULI_DRIFT_SPOILS")

	for i = 1, #self.items do
		local icon = xyd.getItemIcon({
			showNum = true,
			itemID = tonumber(self.items[i].itemID),
			num = tonumber(self.items[i].itemNum),
			uiRoot = self["iconGroup" .. i].gameObject,
			scale = Vector3(0.7, 0.7, 1)
		})
	end
end

function ActivityDriftChestWindow:register()
	BaseWindow.register(self)
end

return ActivityDriftChestWindow
