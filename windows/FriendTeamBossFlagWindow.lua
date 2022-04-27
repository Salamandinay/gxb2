local BaseWindow = import(".BaseWindow")
local FriendTeamBossFlagWindow = class("FriendTeamBossFlagWindow", BaseWindow)

function FriendTeamBossFlagWindow:ctor(params)
	BaseWindow.ctor(self, params)

	self.skinName = "GuildFlagWindowSkin"
	self.callback = params.callback
end

function FriendTeamBossFlagWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()
end

function FriendTeamBossFlagWindow:getUIComponent()
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

function FriendTeamBossFlagWindow:setLayout()
	local ids = xyd.tables.friendTeamBossIconTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local path = xyd.tables.friendTeamBossIconTable:getIcon(id)
		local icon = NGUITools.AddChild(self.groupItems, self.itemContainer)
		local dragScrollView = icon:AddComponent(typeof(UIDragScrollView))
		dragScrollView.scrollView = self.scrollView
		local sp = icon:GetComponent(typeof(UISprite))

		xyd.setUISpriteAsync(sp, nil, string.sub(path, 1, #path - 4))

		UIEventListener.Get(icon).onClick = function ()
			self:chooseIcon(id)
		end
	end

	self.groupItemsGrid:Reposition()
	self.eventProxy_:addEventListener(xyd.event.MODIFY_FRIEND_TEAM_BOSS_TEAM_INFO, function ()
		xyd.WindowManager.get():closeWindow(self)
	end)
end

function FriendTeamBossFlagWindow:chooseIcon(id)
	tonumber(xyd.tables.miscTable:getVal("govern_team_modify_interval"))

	if xyd.getServerTime() - xyd.models.friendTeamBoss:getTeamInfo().last_modify_time < tonumber(xyd.tables.miscTable:getVal("govern_team_modify_interval")) then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_MODIFY_LIMIT"))

		return
	end

	local wnd = xyd.WindowManager.get():getWindow("friend_team_boss_team_edit_window")

	if wnd then
		wnd:setFlag(id)
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

return FriendTeamBossFlagWindow
