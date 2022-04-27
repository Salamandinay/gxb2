local BaseWindow = import(".BaseWindow")
local SkinUnlockWindow = class("SkinUnlockWindow", BaseWindow)
local SkinUnlockWindowItem = class("SkinUnlockWindowItem", import("app.components.BaseComponent"))

function SkinUnlockWindow:ctor(name, params)
	SkinUnlockWindow.super.ctor(self, name, params)

	self.id_ = params.id
	local msg = messages_pb.get_skin_mission_req()
	msg.skin_id = self.id_

	xyd.Backend.get():request(xyd.mid.GET_SKIN_MISSION, msg)
end

function SkinUnlockWindow:initWindow()
	SkinUnlockWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function SkinUnlockWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.scroller_ = groupAction:ComponentByName("scroller_", typeof(UIScrollView))
	self.itemGroup = groupAction:NodeByName("scroller_/itemGroup").gameObject
end

function SkinUnlockWindow:initUIComponent()
	self.titleLabel.text = __("SKIN_UNLOCK_WINDOW_TITLE")
end

function SkinUnlockWindow:register()
	SkinUnlockWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_SKIN_MISSION, handler(self, self.initData))
end

function SkinUnlockWindow:initData(event)
	local list = event.data.mission_list

	for i = 1, #list do
		local item = SkinUnlockWindowItem.new(self.itemGroup, list[i])

		xyd.setDragScrollView(item.go, self.scroller_)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function SkinUnlockWindowItem:ctor(parentGo, params)
	SkinUnlockWindowItem.super.ctor(self, parentGo)

	local go = self.go
	self.titleLabel = go:ComponentByName("titleLabel", typeof(UILabel))
	self.progress = go:ComponentByName("progress", typeof(UISlider))
	self.progress_label = go:ComponentByName("progress/labelDisplay", typeof(UILabel))

	self:setInfos(params)
end

function SkinUnlockWindowItem:getPrefabPath()
	return "Prefabs/Components/skin_unlock_window_item"
end

function SkinUnlockWindowItem:setInfos(params)
	self.id_ = params.table_id
	self.count_ = params.count
	local max = xyd.tables.skinTable:getSum(self.id_)
	self.titleLabel.text = xyd.tables.skinTextTable:getUnlockDesc(self.id_)
	self.progress_label.text = self.count_ .. " / " .. max
	self.progress.value = self.count_ / max
end

return SkinUnlockWindow
