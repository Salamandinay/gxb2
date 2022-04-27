local BaseWindow = import(".BaseWindow")
local ActivityEveryDayAwardWindow = class("ActivityEveryDayAwardWindow", BaseWindow)

function ActivityEveryDayAwardWindow:ctor(name, params)
	self.items_ = params.items
	self.status_ = params.status
	self.title_ = params.title

	BaseWindow.ctor(self, name, params)
end

function ActivityEveryDayAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.itemGroup = groupAction:NodeByName("itemGroup").gameObject
end

function ActivityEveryDayAwardWindow:initUIComponent()
	self.labelTitle.text = self.title_
	local items = self.items_

	for i = 1, #items do
		local item = items[i]
		local icon = xyd.getItemIcon({
			uiRoot = self.itemGroup,
			itemID = item.item_id,
			num = item.item_num
		})

		icon:setChoose(self.status_)
	end

	local layout = self.itemGroup:GetComponent(typeof(UILayout))

	if #items == 4 then
		layout.gap = Vector2(30, 0)
	end

	layout:Reposition()
end

function ActivityEveryDayAwardWindow:initWindow()
	ActivityEveryDayAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

return ActivityEveryDayAwardWindow
