local BaseWindow = import("app.windows.BaseWindow")
local ActivityCommonGetwayWindow = class("ActivityCommonGetwayWindow", BaseWindow)
local GetWayTable = xyd.tables.getWayTable

function ActivityCommonGetwayWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.itemID = params.itemID
	self.values = params.values
	self.table = params.tTable
	self.wayItems = {}
end

function ActivityCommonGetwayWindow:initWindow()
	ActivityCommonGetwayWindow.super:initWindow()

	self.groupAction = self.window_.transform:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.itemGroup = self.groupAction:NodeByName("itemGroup").gameObject
	self.itemCell = self.groupAction:NodeByName("getway_item").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.title = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))

	self:layout()
	self:RegisterEvent()
end

function ActivityCommonGetwayWindow:RegisterEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager:get():closeWindow(self.name_)
	end

	for i = 1, #self.wayItems do
		UIEventListener.Get(self.wayItems[i].btn).onClick = function ()
			self:GoWnd(i)
		end
	end
end

function ActivityCommonGetwayWindow:GoWnd(index)
	local id = self.wayItems[index].way
	local function_id = GetWayTable:getFunctionId(id)

	if not xyd.checkFunctionOpen(function_id) then
		return
	end

	local windows = GetWayTable:getGoWindow(id)
	local params = GetWayTable:getGoParam(id)

	for i in pairs(windows) do
		local windowName = windows[i]

		xyd.WindowManager.get():openWindow(windowName, params[i])
	end

	local closeWnds = GetWayTable:getCloseWindow(id)

	for _, wndName in pairs(closeWnds) do
		local win = xyd.WindowManager.get():getWindow(wndName)

		if win then
			win:close()
		end
	end

	self:close()
	xyd.WindowManager.get():closeWindow("activity_window")
end

function ActivityCommonGetwayWindow:layout()
	self.title.text = __("ACTIVITY_EASTER_EGG_GETWAY_WINDOW")
	local ids = self.table:getIDs()
	local itemNum = #ids

	for _, id in ipairs(ids) do
		local item = NGUITools.AddChild(self.itemGroup, self.itemCell)
		local value = self.values[id] and self.values[id] or 0
		local limit = self.table:getLimit(id)
		value = math.min(value, limit)
		local label = item:ComponentByName("label1", typeof(UILabel))
		label.text = xyd.stringFormat(self.table:getDesc(id), value)

		if xyd.Global.lang == "fr_fr" then
			label.fontSize = 18
		end

		local btn = item:NodeByName("btn").gameObject
		btn:ComponentByName("label", typeof(UILabel)).text = __("GO")

		table.insert(self.wayItems, {
			item = item,
			way = self.table:getGetway(id),
			btn = btn
		})
	end

	self.itemGroup:GetComponent(typeof(UIWidget)).height = 86 * itemNum - 8
	self.groupAction:GetComponent(typeof(UIWidget)).height = 86 * itemNum + 100

	self.itemCell:SetActive(false)
	XYDCo.WaitForFrame(1, function ()
		self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	end, nil)
end

return ActivityCommonGetwayWindow
