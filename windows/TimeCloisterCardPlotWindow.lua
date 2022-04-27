local BaseWindow = import(".BaseWindow")
local TimeCloisterCardPlotWindow = class("TimeCloisterCardPlotWindow", BaseWindow)

function TimeCloisterCardPlotWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.card_id = params.card_id
	self.itemsObj = {}
end

function TimeCloisterCardPlotWindow:initWindow()
	TimeCloisterCardPlotWindow.super.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function TimeCloisterCardPlotWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scroller = groupAction:NodeByName("scroller").gameObject
	self.scroller_UIScrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.groupItems = groupAction:ComponentByName("scroller/groupItems", typeof(UILayout))
	self.groupContent = groupAction:NodeByName("groupContent").gameObject
end

function TimeCloisterCardPlotWindow:registerEvent()
	self:register()
end

function TimeCloisterCardPlotWindow:layout()
	if not self.card_id then
		return
	end

	local all_ids = {}
	local has_ids = {}
	local no_ids = {}
	local first_id = xyd.tables.timeCloisterCardTable:getFirstId(self.card_id)

	if first_id and first_id > 0 then
		local search_id = first_id

		while true do
			local next_id = xyd.tables.timeCloisterCardTable:getNextId(search_id)

			table.insert(all_ids, search_id)

			if search_id <= self.card_id then
				table.insert(has_ids, search_id)
			else
				table.insert(no_ids, search_id)
			end

			if not next_id or next_id <= 0 then
				break
			else
				search_id = next_id
			end
		end
	end

	for i = 1, #all_ids do
		local tmp = NGUITools.AddChild(self.groupItems.gameObject, self.groupContent.gameObject)
		tmp.name = "groupContent" .. i

		table.insert(self.itemsObj, tmp.gameObject)
	end

	for i in pairs(self.itemsObj) do
		self["labelTitle" .. i] = self.itemsObj[i]:ComponentByName("labelTitle", typeof(UILabel))
		self["labelText" .. i] = self.itemsObj[i]:ComponentByName("labelText", typeof(UILabel))
	end

	for i in pairs(has_ids) do
		self["labelText" .. i].text = xyd.tables.timeCloisterCardTextTable:getDesc(has_ids[i])

		xyd.setLabel(self["labelText" .. i], {
			color = 1549556991,
			size = 20,
			textAlign = NGUIText.Alignment.Left
		})

		self["labelTitle" .. i].text = xyd.tables.timeCloisterCardTextTable:getName(has_ids[i])
	end

	for i in pairs(no_ids) do
		self["labelText" .. i + #has_ids].text = xyd.tables.timeCloisterCardTextTable:getUnlockDesc(no_ids[i])

		xyd.setLabel(self["labelText" .. i + #has_ids], {
			color = 2998055679.0,
			size = 24,
			textAlign = NGUIText.Alignment.Center
		})

		self["labelTitle" .. i + #has_ids].text = xyd.tables.timeCloisterCardTextTable:getName(no_ids[i])
	end

	XYDCo.WaitForFrame(1, function ()
		if not tolua.isnull(self.window_) then
			self.groupItems:Reposition()
			self.scroller_UIScrollView:ResetPosition()
		end
	end, nil)
end

return TimeCloisterCardPlotWindow
