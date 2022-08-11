local ActivityContent = class("ActivityContent", import("app.components.BaseComponent"))

function ActivityContent:ctor(parentGO, params, parent)
	self.scale_num_ = 1
	self.id = params.id
	self.type = params.type or xyd.tables.activityTable:getType(self.id)
	self.activityData = xyd.models.activity:getActivity(self.id)
	self.parent_ = parent
	local stageHeight = xyd.WindowManager.get():getActiveHeight()
	local num = (stageHeight - 1280) / (xyd.Global:getMaxHeight() - 1280)

	if xyd.Global:getMaxHeight() < stageHeight then
		num = 1
	end

	self.scale_num_ = 1 - num
	self.scale_num_contrary = 1 - self.scale_num_

	if not xyd.db.misc:getValue("ActivityFirstRedMark_" .. self.id .. "_" .. self.activityData.end_time) then
		xyd.db.misc:setValue({
			value = "1",
			key = "ActivityFirstRedMark_" .. self.id .. "_" .. self.activityData.end_time
		})
	end

	print("self.id             ", self.id)
	ActivityContent.super.ctor(self, parentGO)
end

function ActivityContent:resizeToParent()
	if not self.parentWidget then
		return
	end

	local widget = self.go:GetComponent(typeof(UIWidget))
	widget.width = self.parentWidget.width
	widget.height = self.parentWidget.height
end

function ActivityContent:initUI()
	local widgetNode = self.parentGo:GetComponent(typeof(UIPanel))

	if not widgetNode then
		__TRACE("Parent game object mast hava UIWidget Component")

		return
	end

	self.parentWidget = widgetNode

	if not self.offsetDepth then
		self.offsetDepth = widgetNode.depth
	end

	self:resizeToParent()
end

function ActivityContent:setDepth(depth)
	local windowLayer = xyd.tables.windowTable:getLayerType("activity_window")

	if not depth or depth == 0 then
		return
	end

	local function setChildrenDepth(go, depth)
		for i = 1, go.transform.childCount do
			local child = go.transform:GetChild(i - 1).gameObject
			local panel = child:GetComponent(typeof(UIPanel))

			if panel then
				panel.depth = depth + panel.depth
			end

			if child.transform.childCount > 0 then
				setChildrenDepth(child, depth)
			end
		end
	end

	setChildrenDepth(self.go, depth)
end

function ActivityContent:itemFloat(items)
	if not self.parent_ then
		self.parent_ = xyd.getWindow("activity_window")
	end

	if self.parent_ then
		self.parent_:itemFloat(items)
	end
end

function ActivityContent:resizePosY(obj, y_short, y_phoneX)
	obj:Y(y_short + (y_phoneX - y_short) * self.scale_num_contrary)
end

function ActivityContent:getActivityContentID()
	return self.id
end

return ActivityContent
