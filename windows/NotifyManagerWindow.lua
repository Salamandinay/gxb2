local BaseWindow = import(".BaseWindow")
local NotifyManagerWindow = class("NotifyManagerWindow", BaseWindow)
local NotifyManagerItem = class("NotifyManagerItem", import("app.components.CopyComponent"))

function NotifyManagerWindow:ctor(name, params)
	NotifyManagerWindow.super.ctor(self, name, params)
end

function NotifyManagerWindow:initWindow()
	NotifyManagerWindow.super.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self:setLayout()
end

function NotifyManagerWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupTitle = groupAction:NodeByName("groupTitle").gameObject
	self.closeBtn = self.groupTitle:NodeByName("closeBtn").gameObject
	self.labelTitle_ = self.groupTitle:ComponentByName("labelTitle_", typeof(UILabel))
	self.groupForm = groupAction:NodeByName("groupForm").gameObject
	self.itemscroller = self.groupForm:NodeByName("itemscroller").gameObject
	self.itemsgroup = self.itemscroller:NodeByName("itemsgroup").gameObject
	self.item = self.groupForm:NodeByName("item").gameObject

	if xyd.Global.lang == "ja_jp" then
		self.item:ComponentByName("labelname", typeof(UILabel)).fontSize = 20
	end
end

function NotifyManagerWindow:registerEvent()
	self:register()
end

function NotifyManagerWindow:setLayout()
	self.labelTitle_.text = __("NOTIFY")
	local ids = xyd.tables.deviceNotifyCategoryTable:getIDs()

	for _, id in pairs(ids) do
		local params = {
			type = 1,
			id = id,
			include_list = xyd.tables.deviceNotifyCategoryTable:getInclude(id)
		}
		local go = NGUITools.AddChild(self.itemsgroup, self.item)

		NotifyManagerItem.new(go, params)
	end
end

function NotifyManagerItem:ctor(go, params)
	self.includeList = {}
	self.id = params.id
	self.includeList = params.include_list
	self.currentState = xyd.Global.lang
	self.type_ = params.type

	NotifyManagerItem.super.ctor(self, go)
end

function NotifyManagerItem:initUI()
	self.labelname = self.go:ComponentByName("labelname", typeof(UILabel))
	self.btn = self.go:NodeByName("btn").gameObject
	self.img = self.go:NodeByName("btn/imgSelect").gameObject

	self.img:SetActive(false)
	self:setLayout()
end

function NotifyManagerItem:setLayout()
	if self.type_ == 1 then
		self.labelname.text = xyd.tables.deviceNotifyCategoryTextTable:getPushCategory(self.id)
		self.isopen = xyd.models.deviceNotify:isOpen(self.id)

		self.img:SetActive(self.isopen)

		UIEventListener.Get(self.btn).onClick = function ()
			self.isopen = not self.isopen

			self.img:SetActive(self.isopen)
			xyd.models.deviceNotify:switchDeviceNotify(self.id, self.isopen)
		end
	end
end

return NotifyManagerWindow
