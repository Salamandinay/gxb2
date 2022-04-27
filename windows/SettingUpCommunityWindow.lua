local BaseWindow = import(".BaseWindow")
local SettingUpCommunityWindow = class("SettingUpCommunityWindow", BaseWindow)
local LinkItem = class("LinkItem", import("app.components.CopyComponent"))
local CommunityTable = xyd.tables.communityTable

function SettingUpCommunityWindow:ctor(name, params)
	SettingUpCommunityWindow.super.ctor(self, name, params)
end

function SettingUpCommunityWindow:initWindow()
	SettingUpCommunityWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	SettingUpCommunityWindow.super.register(self)
end

function SettingUpCommunityWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg_ = groupAction:ComponentByName("bg_", typeof(UISprite))
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.contentGroup = groupAction:NodeByName("contentGroup").gameObject
	self.linkItem = groupAction:NodeByName("link_item").gameObject
end

function SettingUpCommunityWindow:initUIComponent()
	self.labelTitle.text = __("SETTING_UP_TAP_4")
	local ids = CommunityTable:getIds()
	self.bg_.height = (self.linkItem:GetComponent(typeof(UISprite)).height + 15) * #ids + 150
	self.bg_:GetComponent(typeof(UnityEngine.BoxCollider)).size = Vector3(680, self.bg_.height, 0)

	for i = 1, #ids do
		local tempGo = NGUITools.AddChild(self.contentGroup, self.linkItem)
		local item = LinkItem.new(tempGo)

		item:setInfo(ids[i])
	end

	self.contentGroup:GetComponent(typeof(UILayout)):Reposition()
end

function LinkItem:ctor(go)
	LinkItem.super.ctor(self, go)

	self.go = go
	self.icon = go:ComponentByName("icon", typeof(UISprite))
	self.label = go:ComponentByName("label", typeof(UILabel))
end

function LinkItem:setInfo(id)
	local name = CommunityTable:getName(id)
	local img = CommunityTable:getIcon(id)
	local link = CommunityTable:getLink(id)
	self.label.text = name

	xyd.setUISpriteAsync(self.icon, nil, img)

	UIEventListener.Get(self.go).onClick = function ()
		UnityEngine.Application.OpenURL(link)
	end
end

return SettingUpCommunityWindow
