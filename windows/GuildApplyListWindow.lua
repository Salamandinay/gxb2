local BaseWindow = import(".BaseWindow")
local GuildApplyListWindow = class("GuildApplyListWindow", BaseWindow)
local GuildApplyItem = class("GuildApplyItem")

function GuildApplyListWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.items = {}
end

function GuildApplyListWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function GuildApplyListWindow:getUIComponent()
	local go = self.window_:NodeByName("e:Group").gameObject
	self.labelWinTitle = go:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.groupNone = go:NodeByName("groupNone").gameObject
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
	self.scrollView_ = go:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.groupItems = go:NodeByName("e:Scroller/groupItems").gameObject
	self.guild_apply_item = self.window_:NodeByName("guild_apply_item").gameObject

	self.guild_apply_item:SetActive(false)
end

function GuildApplyListWindow:initUIComponent()
	self:setCloseBtn(self.closeBtn)

	self.labelNoneTips.text = __("GUILD_TEXT28")

	NGUITools.DestroyChildren(self.groupItems.transform)

	local members = xyd.models.guild.applyMembers

	for i = 1, #members do
		local data = members[i]
		local item = nil
		local go = NGUITools.AddChild(self.groupItems, self.guild_apply_item)
		item = GuildApplyItem.new(go, data, function ()
			item:removeSelf()

			self.items[data.player_id] = nil
			local members = xyd.models.guild.applyMembers

			self.groupNone:SetActive(#members <= 1)
		end)
		self.items[data.player_id] = item
	end

	self.groupItems:GetComponent(typeof(UIGrid)):Reposition()
	self.scrollView_:ResetPosition()
	self.groupNone:SetActive(#members == 0)
end

function GuildApplyListWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GUILD_ACCEPT, handler(self, self.onAcceptMember))
	self.eventProxy_:addEventListener(xyd.event.GUILD_DELETE_APPLY, handler(self, self.onRefuseMember))
end

function GuildApplyListWindow:onAcceptMember(event)
	self.groupItems:GetComponent(typeof(UIGrid)):Reposition()
	self.scrollView_:ResetPosition()
end

function GuildApplyListWindow:onRefuseMember(event)
	self.groupItems:GetComponent(typeof(UIGrid)):Reposition()
	self.scrollView_:ResetPosition()
end

function GuildApplyItem:ctor(go, data, callback)
	self.go = go
	self.callback = callback
	self.data = data

	self:getUIComponent()
	self:initUIComponent()
end

function GuildApplyItem:getUIComponent()
	local go = self.go
	self.groupAvatar = go:NodeByName("groupAvatar").gameObject
	self.labelText0 = go:ComponentByName("labelText0", typeof(UILabel))
	self.labelText1 = go:ComponentByName("labelText1", typeof(UILabel))
	self.btnAccept = go:NodeByName("btnAccept").gameObject
	self.btnRefuse = go:NodeByName("btnRefuse").gameObject
	self.returnText = go:ComponentByName("returnText", typeof(UILabel))
end

function GuildApplyItem:initUIComponent()
	local data = self.data
	local playerIcon = require("app.components.PlayerIcon").new(self.groupAvatar)

	playerIcon:setInfo({
		avatarID = data.avatar_id,
		avatar_frame_id = data.avatar_frame_id,
		callback = function ()
			xyd.WindowManager.get():openWindow("arena_formation_window", {
				not_show_black_btn = true,
				add_friend = false,
				show_close_btn = true,
				is_robot = false,
				player_id = data.player_id
			})
		end
	})
	playerIcon:SetLocalScale(0.6491228070175439, 0.6491228070175439, 1)

	self.labelText0.text = tostring(data.lev)
	self.labelText1.text = data.player_name

	xyd.setDarkenBtnBehavior(self.btnAccept, self, self.onAccept)
	xyd.setDarkenBtnBehavior(self.btnRefuse, self, self.onRefuse)

	if data.is_return and data.is_return == 1 then
		self.returnText.gameObject:SetActive(true)

		self.returnText.text = __("ACTIVITY_RETURN2_ADD_TEXT11")

		self.labelText1.gameObject:Y(16)
	end
end

function GuildApplyItem:onAccept()
	local members = xyd.models.guild.members
	local max = xyd.tables.guildExpTable:getMember(xyd.models.guild.level)

	if max <= #members then
		xyd.showToast(__("GUILD_TEXT58"))

		return
	end

	if self.callback then
		self.callback()
	end

	xyd.models.guild:guildAccpetMember(self.data.player_id)
end

function GuildApplyItem:onRefuse()
	if self.callback then
		self.callback()
	end

	xyd.models.guild:refuseGuildApply(self.data.player_id)
end

function GuildApplyItem:removeSelf()
	NGUITools.Destroy(self.go.transform)
end

return GuildApplyListWindow
