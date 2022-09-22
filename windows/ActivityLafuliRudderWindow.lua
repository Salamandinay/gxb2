local BaseWindow = import(".BaseWindow")
local ActivityLafuliRudderWindow = class("ActivityLafuliRudderWindow", BaseWindow)
local ActivityLafuliRudderWindowItem = class("ActivityLafuliRudderWindowItem", import("app.components.CopyComponent"))

function ActivityLafuliRudderWindow:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.params = params
end

function ActivityLafuliRudderWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setItem()
	self:register()
end

function ActivityLafuliRudderWindow:getUIComponent()
	local go = self.window_.transform
	self.activityGroup = go:NodeByName("groupAction").gameObject
	self.scroller = self.activityGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollerPanel = self.activityGroup:ComponentByName("scroller", typeof(UIPanel))
	self.scrollerPanel.depth = self.scrollerPanel.depth + 1
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.groupItem_uigrid = self.groupItem:GetComponent(typeof(UIGrid))
	self.closeBtn = self.activityGroup:NodeByName("closeBtn").gameObject
	self.title = self.activityGroup:ComponentByName("title", typeof(UILabel))
	self.itemCell = go:NodeByName("itemCell").gameObject
end

function ActivityLafuliRudderWindow:setItem()
	self.title.text = __("ACTIVITY_LAFULI_RUDDER_TITLE")
	local ids = xyd.tables.activityLafuliRudderTable:getIDs()
	local awards = {}

	for i = 1, #ids do
		table.insert(awards, {
			awards = xyd.tables.activityLafuliRudderTable:getAwards(ids[i]),
			point = xyd.tables.activityLafuliRudderTable:getNum(ids[i]),
			curPoint = self.params.point
		})
	end

	table.sort(awards, function (a, b)
		if a.point <= a.curPoint == (b.point <= b.curPoint) then
			return a.point < b.point
		else
			return a.curPoint < a.point
		end
	end)
	NGUITools.DestroyChildren(self.groupItem.transform)

	for i in ipairs(awards) do
		local tmp = NGUITools.AddChild(self.groupItem, self.itemCell)
		local item = ActivityLafuliRudderWindowItem.new(tmp, awards[i], self.scroller)
	end

	self.groupItem_uigrid:Reposition()
	self.itemCell:SetActive(false)
end

function ActivityLafuliRudderWindow:register()
	BaseWindow.register(self)
end

function ActivityLafuliRudderWindowItem:ctor(goItem, itemdata, scroller)
	self.goItem_ = goItem
	self.scrollerView = scroller
	local transGo = goItem.transform
	self.imgbg = transGo:ComponentByName("e:Image", typeof(UITexture))
	self.progressBar_ = transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.labelTitle_ = transGo:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup_ = transGo:Find("itemsGroup")

	self:initItem(itemdata)
end

function ActivityLafuliRudderWindowItem:initItem(itemdata)
	local max = itemdata.point

	if max <= itemdata.curPoint then
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb_2")
	else
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb")
	end

	self.progressBar_.value = math.min(itemdata.point, itemdata.curPoint) / itemdata.point
	local max = itemdata.point
	self.progressDesc.text = math.min(itemdata.point, itemdata.curPoint) .. "/" .. max
	self.labelTitle_.text = __("ACTIVITY_LAFULI_RUDDER_TEXT", itemdata.point)

	for _, reward in pairs(itemdata.awards) do
		local icon = xyd.getItemIcon({
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_.gameObject
		})

		icon:setScale(0.65)

		if itemdata.point <= itemdata.curPoint then
			icon:setChoose(true)
		end
	end
end

return ActivityLafuliRudderWindow
