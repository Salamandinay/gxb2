local BaseWindow = import(".BaseWindow")
local GuildFlagWindow = class("GuildFlagWindow", BaseWindow)

function GuildFlagWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = params.callback
end

function GuildFlagWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()
end

function GuildFlagWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("content").gameObject
	self.labelWinTitle = content:ComponentByName("titleGroup/labelWinTitle", typeof(UILabel))
	self.closeBtn = content:NodeByName("closeBtn").gameObject
	self.scrollView = content:ComponentByName("scroller", typeof(UIScrollView))
	self.groupItems = self.scrollView:NodeByName("groupItems").gameObject
	self.groupItemsGrid = self.groupItems:GetComponent(typeof(UIGrid))
	self.itemContainer = self.scrollView:NodeByName("itemContainer").gameObject

	self.itemContainer:SetActive(false)
end

function GuildFlagWindow:setLayout()
	local ids = xyd.tables.guildIconTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local path = xyd.tables.guildIconTable:getIcon(id)
		local icon = NGUITools.AddChild(self.groupItems, self.itemContainer)
		local dragScrollView = icon:AddComponent(typeof(UIDragScrollView))
		dragScrollView.scrollView = self.scrollView
		local sp = icon:GetComponent(typeof(UISprite))

		xyd.setUISpriteAsync(sp, nil, string.sub(path, 1, #path - 4))

		UIEventListener.Get(icon).onClick = function ()
			self:chooseIcon(id)
		end
	end
end

function GuildFlagWindow:chooseIcon(id)
	if self.callback then
		self:callback(id)
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	xyd.models.guild:editFlag(id)
	xyd.WindowManager:get():closeWindow(self.name_)
end

return GuildFlagWindow
