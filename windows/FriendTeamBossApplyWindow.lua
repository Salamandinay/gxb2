local BaseWindow = import(".BaseWindow")
local FriendTeamBossApplyWindow = class("FriendTeamBossApplyWindow", BaseWindow)
local CommonTabBar = import("app.common.ui.CommonTabBar")
local PlayerIcon = import("app.components.PlayerIcon")
local BaseComponent = import("app.components.BaseComponent")
local FriendTeamBossInviteItem = class("FriendTeamBossInviteItem", BaseComponent)
local FriendTeamBossApplyItem = class("FriendTeamBossApplyItem", BaseComponent)
local FriendTeamBossTeamItem = class("FriendTeamBossTeamItem", BaseComponent)
local CountDown = import("app.components.CountDown")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
end

function ItemRender:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	if not self.item then
		self.item = self.parent.itemClass.new(self.go)
	end

	self.item.data = info

	self.go:SetActive(true)
	self.item:dataChanged()
end

function ItemRender:getGameObject()
	return self.go
end

function FriendTeamBossApplyWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curSelect_ = 1
	self.items = {}
	self.skinName = "FriendTeamBossApplyWindowSkin"
end

function FriendTeamBossApplyWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:onClickNav(1, true)
	self:register()
end

function FriendTeamBossApplyWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	local topGroup = content:NodeByName("topGroup").gameObject
	self.labelWinTitle = topGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = topGroup:NodeByName("closeBtn").gameObject
	self.nav = content:NodeByName("nav").gameObject
	self.tabBar = CommonTabBar.new(self.nav, 3, function (index)
		self:onClickNav(index)
	end)
	self.labelDesc = content:ComponentByName("labelDesc", typeof(UILabel))
	self.labelLevel = content:ComponentByName("labelLevel", typeof(UILabel))

	for i = 1, 3 do
		local toggleContent = content:NodeByName("toggleContent" .. i).gameObject
		self["toggleContent" .. i] = toggleContent
		self["scrollView" .. i] = toggleContent:ComponentByName("scroller", typeof(UIScrollView))
		local gContainer = self["scrollView" .. i]:ComponentByName("gContainer", typeof(UIWrapContent))
		local itemContainer = self["scrollView" .. i]:NodeByName("itemContainer").gameObject
		self["wrapContent" .. i] = FixedWrapContent.new(self["scrollView" .. i], gContainer, itemContainer, ItemRender, self)
	end

	self.btnQuit = content:NodeByName("btnQuit").gameObject
	self.groupNone = content:NodeByName("groupNone").gameObject
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
end

function FriendTeamBossApplyWindow:layout()
	self.tabBar.tabs[1].label.text = __("FRIEND_APPLY")
	self.tabBar.tabs[2].label.text = __("FRIEND_INVITE")
	self.tabBar.tabs[3].label.text = __("FRIEND_TEAM")

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.FRIEND_TEAM_BOSS_APPLY, self.tabBar.tabs[1].redMark)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.FRIEND_TEAM_BOSS_INVITED, self.tabBar.tabs[2].redMark)

	if xyd.models.friendTeamBoss:checkInFight() or xyd.models.friendTeamBoss:getTeamInfo().leader_id == xyd.models.selfPlayer:getPlayerID() then
		self.btnQuit:SetActive(false)
	end
end

function FriendTeamBossApplyWindow:playOpenAnimation(callback)
	local call = nil

	function call()
		if callback then
			callback()
		end

		xyd.models.friendTeamBoss:reqInviteList()
	end

	BaseWindow.playOpenAnimation(self, call)
end

function FriendTeamBossApplyWindow:register()
	FriendTeamBossApplyWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_GET_APPLY_LIST, handler(self, self.onGetInfo))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_GET_FRIEND_TEAM_LIST, handler(self, self.onGetInfo))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_GET_INVITE_LIST, handler(self, self.onGetInfo))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_ACCEPT_APPLY, handler(self, self.onAcceptApply))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_ACCEPT_INVITE, handler(self, self.onAcceptInvite))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_REFUSE_APPLY, handler(self, self.onRefuseApply))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_REFUSE_INVITE, handler(self, self.onRefuseInvite))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_APPLY_TEAM, handler(self, self.onApply))

	UIEventListener.Get(self.btnQuit).onClick = function ()
		self:onClickQuit()
	end
end

function FriendTeamBossApplyWindow:onClickQuit()
	xyd.alert(xyd.AlertType.YES_NO, __("FRIEND_TEAM_BOSS_QUIT"), function (yes)
		if not yes then
			return
		end

		xyd.models.friendTeamBoss:exitTeam()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function FriendTeamBossApplyWindow:onClickNav(index, first)
	local old_index = self.curSelect_

	if old_index == index and not first then
		return
	end

	self.curSelect_ = index
	self.labelDesc.text = __("FRIEND_APPLY_DESC_" .. tostring(index))
	self.labelLevel.text = __("FRIEND_TEAM_BOSS_NOW_LEVEL", xyd.models.friendTeamBoss:getSelfInfo().boss_level)

	if self.curSelect_ == 1 then
		if #xyd.models.friendTeamBoss:getApplyList() > 0 then
			self:onGetInfo()
		else
			xyd.models.friendTeamBoss:reqApplyPlayerList()
		end
	elseif self.curSelect_ == 2 then
		if #xyd.models.friendTeamBoss:getInviteList() > 0 then
			self:onGetInfo()
		else
			xyd.models.friendTeamBoss:reqInviteList()
		end
	elseif self.curSelect_ == 3 then
		if #xyd.models.friendTeamBoss:getFriendTeamList() > 0 then
			self:onGetInfo()
		else
			xyd.models.friendTeamBoss:reqTeamList()
		end
	end
end

function FriendTeamBossApplyWindow:onGetInfo()
	self.groupNone:SetActive(false)

	for i = 1, 3 do
		if i == self.curSelect_ then
			self["toggleContent" .. i]:SetActive(true)
		else
			self["toggleContent" .. i]:SetActive(false)
		end
	end

	if self.curSelect_ == 1 then
		self.itemClass = FriendTeamBossApplyItem
		local list = xyd.models.friendTeamBoss:getApplyList()

		if xyd.models.friendTeamBoss:getTeamInfo().leader_id ~= xyd.models.selfPlayer:getPlayerID() then
			list = {}
		end

		if not list or #list == 0 then
			self.groupNone:SetActive(true)

			self.labelNoneTips.text = __("FRIEND_TEAM_BOSS_NO_APPLY")
		end

		self.wrapContent1:setInfos(list)
	elseif self.curSelect_ == 2 then
		self.itemClass = FriendTeamBossInviteItem
		local list = xyd.models.friendTeamBoss:getInviteList()

		if not list or #list == 0 then
			self.groupNone:SetActive(true)

			self.labelNoneTips.text = __("FRIEND_TEAM_BOSS_NO_INVATE")
		end

		self.wrapContent2:setInfos(list)
	elseif self.curSelect_ == 3 then
		self.itemClass = FriendTeamBossTeamItem
		local list = xyd.models.friendTeamBoss:getFriendTeamList()

		if not list or #list == 0 then
			self.groupNone:SetActive(true)

			self.labelNoneTips.text = __("FRIEND_TEAM_BOSS_NO_TEAM")
		end

		self.wrapContent3:setInfos(list)
	end
end

function FriendTeamBossApplyWindow:onAcceptInvite(event)
	local list = xyd.models.friendTeamBoss:getInviteList()

	self.wrapContent2:setInfos(list)
end

function FriendTeamBossApplyWindow:onRefuseInvite(event)
	local list = xyd.models.friendTeamBoss:getInviteList()

	self.wrapContent2:setInfos(list)
end

function FriendTeamBossApplyWindow:onAcceptApply(event)
	local list = xyd.models.friendTeamBoss:getApplyList()

	self.wrapContent1:setInfos(list)
end

function FriendTeamBossApplyWindow:onRefuseApply(event)
	local list = xyd.models.friendTeamBoss:getApplyList()

	self.wrapContent1:setInfos(list)
end

function FriendTeamBossApplyWindow:onApply(event)
	local list = xyd.models.friendTeamBoss:getFriendTeamList()

	self.wrapContent3:setInfos(list)
end

function FriendTeamBossApplyWindow:willClose(params, skipAnimation, force)
	BaseWindow.willClose(self, params, skipAnimation, force)

	self.items = {}
end

function FriendTeamBossInviteItem:ctor(parentGo)
	FriendTeamBossInviteItem.super.ctor(self, parentGo)

	self.skinName = "FriendTeamBossApplyItemSkin1"

	self:getUIComponent()
end

function FriendTeamBossInviteItem.getPrefabPath()
	return "Prefabs/Components/friend_team_boss_apply_item1"
end

function FriendTeamBossInviteItem:getUIComponent()
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

	self:createChildren()
end

function FriendTeamBossInviteItem:createChildren()
	local w = self.groupIcon_:GetComponent(typeof(UIWidget))
	local img = NGUITools.AddChild(self.groupIcon_, "img")
	local sp = img:AddComponent(typeof(UISprite))
	sp.width = w.width
	sp.height = w.height
	sp.depth = w.depth + 1
	self.avatar = sp

	self:registerEvent()
end

function FriendTeamBossInviteItem:dataChanged()
	self:layout()
end

function FriendTeamBossInviteItem:layout()
	local name = xyd.tables.friendTeamBossIconTable:getIcon(self.data.team_icon)

	xyd.setUISpriteAsync(self.avatar, nil, string.sub(name, 1, #name - 4))

	self.labelName.text = __("FRIEND_TEAM_BOSS_TEAM_NAME", self.data.team_name)
	self.labelDesc.text = __("TEAM_LEV", self.data.boss_level)

	xyd.setBgColorType(self.btnRefuse, xyd.ButtonBgColorType.white_btn_70_70)
	xyd.setBgColorType(self.btnAccept, xyd.ButtonBgColorType.blue_btn_60_60)

	self.btnRefuseLabel.text = __("REFUSE_INVITE")
	self.btnAcceptLabel.text = __("ACCEPT_INVITE")
end

function FriendTeamBossInviteItem:registerEvent()
	UIEventListener.Get(self.btnCheck).onClick = function ()
		self:onClickCheck()
	end

	UIEventListener.Get(self.btnRefuse).onClick = function ()
		self:onClickRefuse()
	end

	UIEventListener.Get(self.btnAccept).onClick = function ()
		self:onClickApply()
	end
end

function FriendTeamBossInviteItem:onClickCheck()
	xyd.WindowManager.get():openWindow("friend_team_boss_team_formation_window", {
		team_id = self.data.team_id
	})
end

function FriendTeamBossInviteItem:onClickRefuse()
	xyd.models.friendTeamBoss:refuseInvite(self.data.team_id)
end

function FriendTeamBossInviteItem:onClickApply()
	if xyd.models.friendTeamBoss:getSelfInfo().weekly_join_times <= 0 then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_JOIN_LIMIT"))

		return
	end

	if #xyd.models.friendTeamBoss:getTeamInfo().player_ids > 1 and xyd.models.friendTeamBoss:getTeamInfo().leader_id == xyd.models.selfPlayer:getPlayerID() then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_CAN_ACCEPT_INVITE"))

		return
	end

	xyd.models.friendTeamBoss:acceptInvite(self.data.team_id)
end

function FriendTeamBossApplyItem:ctor(parentGo)
	FriendTeamBossApplyItem.super.ctor(self, parentGo)

	self.skinName = "FriendTeamBossApplyItemSkin1"

	self:getUIComponent()
end

function FriendTeamBossApplyItem.getPrefabPath()
	return "Prefabs/Components/friend_team_boss_apply_item1"
end

function FriendTeamBossApplyItem:getUIComponent()
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

	self:createChildren()
end

function FriendTeamBossApplyItem:createChildren()
	local icon = PlayerIcon.new(self.groupIcon_)
	self.playerIcon_ = icon

	self:registerEvent()
end

function FriendTeamBossApplyItem:dataChanged()
	self:layout()
end

function FriendTeamBossApplyItem:layout()
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

	self.labelName.text = self.data.player_name
	self.labelDesc.text = __("TEAM_LEV", self.data.boss_level)

	xyd.setBgColorType(self.btnRefuse, xyd.ButtonBgColorType.white_btn_70_70)
	xyd.setBgColorType(self.btnAccept, xyd.ButtonBgColorType.blue_btn_60_60)

	self.btnRefuseLabel.text = __("REFUSE_INVITE")
	self.btnAcceptLabel.text = __("ACCEPT_INVITE")
end

function FriendTeamBossApplyItem:registerEvent()
	UIEventListener.Get(self.btnCheck).onClick = function ()
		self:onClickCheck()
	end

	UIEventListener.Get(self.btnRefuse).onClick = function ()
		self:onClickRefuse()
	end

	UIEventListener.Get(self.btnAccept).onClick = function ()
		self:onClickApply()
	end
end

function FriendTeamBossApplyItem:onClickCheck()
	xyd.WindowManager.get():openWindow("arena_formation_window", {
		is_robot = false,
		player_id = self.data.player_id
	})
end

function FriendTeamBossApplyItem:onClickRefuse()
	xyd.models.friendTeamBoss:refuseApply(self.data.player_id)
end

function FriendTeamBossApplyItem:onClickApply()
	if #xyd.models.friendTeamBoss:getTeamInfo().player_ids >= 3 then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_JOIN_LIMIT3"))

		return
	end

	xyd.models.friendTeamBoss:acceptApply(self.data.player_id)
end

function FriendTeamBossTeamItem:ctor(parentGo)
	FriendTeamBossTeamItem.super.ctor(self, parentGo)

	self.skinName = "FriendTeamBossApplyItemSkin2"

	self:getUIComponent()
end

function FriendTeamBossTeamItem.getPrefabPath()
	return "Prefabs/Components/friend_team_boss_apply_item2"
end

function FriendTeamBossTeamItem:getUIComponent()
	local content = self.go:NodeByName("content").gameObject
	self.groupIcon_ = content:NodeByName("groupIcon_").gameObject
	self.labelName = content:ComponentByName("labelName", typeof(UILabel))
	self.labelDesc = content:ComponentByName("labelDesc", typeof(UILabel))
	self.labelMember = content:ComponentByName("labelMember", typeof(UILabel))
	self.btnCheck = content:NodeByName("btnCheck").gameObject
	local btnGroup = content:NodeByName("btnGroup").gameObject
	self.btnAccept = btnGroup:NodeByName("btnAccept").gameObject
	self.btnAcceptLabel = self.btnAccept:ComponentByName("button_label", typeof(UILabel))
	local cd = content:ComponentByName("CD", typeof(UILabel))
	self.CD = CountDown.new(cd)

	self:createChildren()
end

function FriendTeamBossTeamItem:createChildren()
	local w = self.groupIcon_:GetComponent(typeof(UIWidget))
	local img = NGUITools.AddChild(self.groupIcon_, "img")
	local sp = img:AddComponent(typeof(UISprite))
	sp.width = w.width
	sp.height = w.height
	sp.depth = w.depth + 1
	self.avatar = sp

	self:registerEvent()
end

function FriendTeamBossTeamItem:dataChanged()
	self:layout()
end

function FriendTeamBossTeamItem:layout()
	local name = xyd.tables.friendTeamBossIconTable:getIcon(self.data.team_icon)

	xyd.setUISpriteAsync(self.avatar, "guild_flag", string.sub(name, 1, #name - 4))

	self.labelName.text = __("FRIEND_TEAM_BOSS_TEAM_NAME", self.data.team_name)
	self.labelDesc.text = __("TEAM_LEV", self.data.boss_level)
	self.labelMember.text = tostring(__("MEMBER")) .. " : " .. tostring(#self.data.player_ids) .. "/3"

	xyd.setBgColorType(self.btnAccept, xyd.ButtonBgColorType.blue_btn_60_60)

	self.btnAcceptLabel.text = __("APPLY_TEAM")
	local cd = self.data.last_apply_time + tonumber(xyd.tables.miscTable:getVal("govern_team_apply_interval")) - xyd.getServerTime()

	if cd > 0 then
		self.btnAccept:SetActive(false)
		self.CD:SetActive(true)
		self.CD:setInfo({
			duration = cd
		})
	else
		self.btnAccept:SetActive(true)
		self.CD:SetActive(false)
	end
end

function FriendTeamBossTeamItem:registerEvent()
	UIEventListener.Get(self.btnCheck).onClick = function ()
		self:onClickCheck()
	end

	UIEventListener.Get(self.btnAccept).onClick = function ()
		self:onClickApply()
	end
end

function FriendTeamBossTeamItem:onClickCheck()
	xyd.WindowManager:get():openWindow("friend_team_boss_team_formation_window", {
		team_id = self.data.team_id
	})
end

function FriendTeamBossTeamItem:onClickApply()
	if #xyd.models.friendTeamBoss:getTeamInfo().player_ids > 1 then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_JOIN_LIMIT2"))

		return
	end

	xyd.models.friendTeamBoss:applyTeam(self.data.team_id)

	self.data.last_apply_time = xyd.getServerTime()

	self:dataChanged()
end

return FriendTeamBossApplyWindow
