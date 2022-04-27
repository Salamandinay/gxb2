local BaseWindow = import(".BaseWindow")
local FriendTeamBossInviteFriendsWindow = class("FriendTeamBossInviteFriendsWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local BaseComponent = import("app.components.BaseComponent")
local PlayerIcon = import("app.components.PlayerIcon")
local FriendTeamBossInviteFriendItem = class("FriendTeamBossInviteFriendItem", BaseComponent)
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = FriendTeamBossInviteFriendItem.new(go)

	self.item:setDragScrollView(parent.scrollView)
end

function ItemRender:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.item.data = info

	self.go:SetActive(true)
	self.item:update()
end

function ItemRender:getGameObject()
	return self.go
end

function FriendTeamBossInviteFriendsWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.index = 0
	self.list = {}
	self.skinName = "FriendTeamBossInviteFriendsWindowSkin"
end

function FriendTeamBossInviteFriendsWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()

	local list = xyd.models.friend:getFriendList()

	if #list <= 0 then
		self.wrapContent:setInfos({})
		xyd.models.friend:getInfo()
	else
		self:layout()
	end
end

function FriendTeamBossInviteFriendsWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	local topGroup = content:NodeByName("topGroup").gameObject
	self.closeBtn = topGroup:NodeByName("closeBtn").gameObject
	self.labelWinTitle = topGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.scrollView = middleGroup:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("gContainer", typeof(UIWrapContent))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, itemContainer, ItemRender, self)
	self.groupNone = content:NodeByName("groupNone").gameObject
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
end

function FriendTeamBossInviteFriendsWindow:layout()
	local friendList = xyd.models.friend:getFriendList() or {}
	local selfSeverID = xyd.models.selfPlayer:getServerID()
	local list = {}

	for i = 1, #friendList do
		table.insert(list, friendList[i])
	end

	if #list > 0 then
		self.list = self:sortFriend(list)
	end

	if self.list and #self.list > 0 then
		self.groupNone:SetActive(false)
	else
		self.groupNone:SetActive(true)

		self.labelNoneTips.text = __("ARENA_TEAM_NO_FRIEND")
	end

	self.wrapContent:setInfos(self.list)
end

function FriendTeamBossInviteFriendsWindow:sortFriend(list)
	local lst = {}
	local open_type = xyd.tables.functionTable:getOpenType(xyd.FunctionID.FRIEND_TEAM_BOSS)
	local open_value = xyd.tables.functionTable:getOpenValue(xyd.FunctionID.FRIEND_TEAM_BOSS)
	local selfSeverID = xyd.models.selfPlayer:getServerID()

	for i = 1, #list do
		if open_type == 1 and list[i].lev and open_value <= list[i].lev or open_type == 2 and list[i].campaign_stage and open_value <= list[i].campaign_stage and xyd.tables.serverMapTable:getHostMix(selfSeverID) == xyd.tables.serverMapTable:getHostMix(list[i].server_id) then
			table.insert(lst, list[i])
		end
	end

	table.sort(lst, function (a, b)
		local aPower = a.arena_power and a.arena_power or xyd.models.arena:getPower() < 0
		local bPower = b.arena_power and b.arena_power or 0

		if xyd.models.arena:getPower() < aPower or xyd.models.arena:getPower() < bPower then
			return bPower < aPower
		else
			return b.last_time < a.last_time
		end
	end)

	return lst
end

function FriendTeamBossInviteFriendsWindow:timerFunc()
end

function FriendTeamBossInviteFriendsWindow:register()
	FriendTeamBossInviteFriendsWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.FRIEND_GET_INFO, handler(self, self.layout))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_INVITE_FRIEND, function ()
		xyd.alert(xyd.AlertType.TIPS, __("GUILD_WAR_SEND_SUCCESS"))
	end)
end

function FriendTeamBossInviteFriendsWindow:onGetTeamInfo(event)
	local data = event.data

	xyd.WindowManager:get():openWindow("friend_team_boss_formation_window", data)
end

function FriendTeamBossInviteFriendItem:ctor(parentGo)
	FriendTeamBossInviteFriendItem.super.ctor(self, parentGo)

	self.skinName = "FriendTeamBossApplyItemSkin1"

	self:getUIComponent()
end

function FriendTeamBossInviteFriendItem:getPrefabPath()
	return "Prefabs/Components/friend_team_boss_apply_item3"
end

function FriendTeamBossInviteFriendItem:getUIComponent()
	local content = self.go:NodeByName("content").gameObject
	self.groupIcon_ = content:NodeByName("groupIcon_").gameObject
	self.labelName = content:ComponentByName("labelName", typeof(UILabel))
	self.labelDesc = content:ComponentByName("labelDesc", typeof(UILabel))
	self.btnCheck = content:NodeByName("btnCheck").gameObject
	local btnGroup = content:NodeByName("btnGroup").gameObject
	self.btnRefuse = btnGroup:NodeByName("btnRefuse").gameObject
	self.btnRefuseLabel = self.btnRefuse:ComponentByName("button_label", typeof(UILabel))
	self.btnAccept = btnGroup:NodeByName("btnAccept").gameObject
	self.btnAcceptLabel = self.btnAccept:ComponentByName("button_label", typeof(UILabel))
	self.tipLabel = content:ComponentByName("labelTip", typeof(UILabel))

	self:createChildren()
end

function FriendTeamBossInviteFriendItem:createChildren()
	self.playerIcon_ = PlayerIcon.new(self.groupIcon_)

	self:register()
end

function FriendTeamBossInviteFriendItem:update()
	self:layout()
end

function FriendTeamBossInviteFriendItem:layout()
	self.playerIcon_:setInfo({
		avatarID = self.data.avatar_id,
		avatar_frame_id = self.data.avatar_frame_id,
		callback = function ()
			xyd.WindowManager.get():openWindow("arena_formation_window", {
				is_robot = false,
				player_id = self.data.player_id
			})
		end
	})
	self.btnCheck:SetActive(false)
	xyd.setBgColorType(self.btnRefuse, xyd.ButtonBgColorType.white_btn_70_70)
	xyd.setBgColorType(self.btnAccept, xyd.ButtonBgColorType.blue_btn_60_60)

	self.btnRefuseLabel.text = __("CHECK_TEAM")
	self.btnAcceptLabel.text = __("ARENA_TEAM_INVITE")
	self.labelName.text = self.data.player_name
	local power = self.data.arena_power or 0
	local str = __("TIP_FORMATION")

	if xyd.models.arena:getPower() < power then
		str = __("TIP_STRONG")
	elseif math.max(xyd.getServerTime() - (self.data.last_time or 0), 0) < 259200 then
		str = __("TIP_ACTIVE")
	end

	self.labelDesc.text = __("INVITE_TIPS", str)

	self.tipLabel:SetActive(false)
end

function FriendTeamBossInviteFriendItem:register()
	UIEventListener.Get(self.btnRefuse).onClick = function ()
		self:onClickCheck()
	end

	UIEventListener.Get(self.btnAccept).onClick = function ()
		self:onClickApply()
	end
end

function FriendTeamBossInviteFriendItem:onClickCheck()
	xyd.WindowManager.get():openWindow("friend_team_boss_team_formation_window", {
		player_id = self.data.player_id
	})
end

function FriendTeamBossInviteFriendItem:onClickApply()
	local selfSeverID = xyd.models.selfPlayer:getServerID()
	local freindSeverID = self.data.server_id

	print(xyd.tables.serverMapTable:getHostMix(selfSeverID))
	print(xyd.tables.serverMapTable:getHostMix(freindSeverID))

	if xyd.tables.serverMapTable:getHostMix(selfSeverID) ~= xyd.tables.serverMapTable:getHostMix(freindSeverID) then
		xyd.alertTips(__("FRIEND_TEAM_BOSS_INVITE_TIPS"))

		return
	end

	local teamInfo = xyd.models.friendTeamBoss:getTeamInfo()

	if xyd.arrayIndexOf(teamInfo.player_ids, self.data.player_id) >= 0 then
		xyd.alert(xyd.AlertType.TIPS, __("PLAYER_ALREADY_IN_TEAM"))

		return
	end

	xyd.models.friendTeamBoss:invitePlayer(self.data.player_id)
end

return FriendTeamBossInviteFriendsWindow
