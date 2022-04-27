local ItemLockWindow = class("ItemLockWindow", import(".BaseWindow"))

function ItemLockWindow:ctor(name, params)
	ItemLockWindow.super.ctor(self, name, params)
end

function ItemLockWindow:initWindow()
	ItemLockWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function ItemLockWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_all = winTrans:NodeByName("e:Skin/group_all").gameObject
	self.group_close = winTrans:ComponentByName("e:Skin/group_all/group_close", typeof(UISprite))
	self.anna = winTrans:ComponentByName("e:Skin/group_all/portrait", typeof(UISprite))
	self.group_all.transform:ComponentByName("title", typeof(UILabel)).text = __("ITEM_USE_TITLE")
	self.group_all.transform:ComponentByName("tips", typeof(UILabel)).text = __("ITEM_USE_TIPS")
end

function ItemLockWindow:initUIComponent()
	xyd.setUISpriteAsync(self.anna, xyd.MappingData.bg_nvzhujue, "bg_nvzhujue")
	xyd.setNormalBtnBehavior(self.group_close.gameObject, self, self.close)
end

return ItemLockWindow
