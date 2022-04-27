local BaseWindow = import(".BaseWindow")
local FriendTeamBossRecordWindow = class("FriendTeamBossRecordWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local BaseComponent = import("app.components.BaseComponent")
local FriendTeamBossRecordItem = class("FriendTeamBossRecordItem", BaseComponent)
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = FriendTeamBossRecordItem.new(go)

	self.item:setDragScrollView(parent.scrollView)
end

function ItemRender:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)
	self.item:setInfo(info)
end

function ItemRender:getGameObject()
	return self.go
end

function FriendTeamBossRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "ArenaRecordSkin"
	self.model_ = xyd.models.friendTeamBoss
end

function FriendTeamBossRecordWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	self.labelTitle.text = __("BATTLE_RECORD")
	self.labelNone.text = __("ARENA_NO_RECORD")

	self:register()
	self.model_:reqRecord()
end

function FriendTeamBossRecordWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.labelTitle = content:ComponentByName("topGroup/labelTitle", typeof(UILabel))
	self.backBtn = content:NodeByName("backBtn").gameObject
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.scrollView = middleGroup:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("container", typeof(UIWrapContent))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, itemContainer, ItemRender, self)
	self.groupNone = middleGroup:NodeByName("groupNone").gameObject
	self.labelNone = self.groupNone:ComponentByName("labelNone", typeof(UILabel))
end

function FriendTeamBossRecordWindow:register()
	FriendTeamBossRecordWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_GET_RECORDS, handler(self, self.onGetData))

	UIEventListener.Get(self.backBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function FriendTeamBossRecordWindow:onGetData(event)
	local data = xyd.decodeProtoBuf(event.data).records or {}

	dump(data, "所有数据")

	if #data == 0 then
		self.groupNone:SetActive(true)
	else
		self.groupNone:SetActive(false)
	end

	self.wrapContent:setInfos(data)
end

local PlayerIcon = import("app.components.PlayerIcon")

function FriendTeamBossRecordItem:ctor(parentGo)
	FriendTeamBossRecordItem.super.ctor(self, parentGo)

	self.skinName = "FriendTeamBossRecordItemSkin"

	self:getUIComponent()
end

function FriendTeamBossRecordItem:getPrefabPath()
	return "Prefabs/Components/friend_team_boss_record_item"
end

function FriendTeamBossRecordItem:getUIComponent()
	local pIconContainer = self.go:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIconContainer)
	local pIcon2Container = self.go:NodeByName("pIcon2").gameObject
	self.pIcon2 = PlayerIcon.new(pIcon2Container)
	self.labelDmg = self.go:ComponentByName("labelDmg", typeof(UILabel))
	self.dmg = self.go:ComponentByName("dmg", typeof(UILabel))
	self.video = self.go:NodeByName("video").gameObject
	self.loseImage = self.go:NodeByName("loseImage").gameObject
	self.winImage = self.go:NodeByName("winImage").gameObject

	self:createChildren()
end

function FriendTeamBossRecordItem:setState(state)
	if state == "win" then
		self.winImage:SetActive(true)
		self.loseImage:SetActive(false)
	else
		self.winImage:SetActive(false)
		self.loseImage:SetActive(true)
	end
end

function FriendTeamBossRecordItem:setInfo(params)
	self.params = params
	local index = params.boss_index
	local avatar = xyd.tables.friendTeamBossTable:getBossAvatar(xyd.models.friendTeamBoss:getSelfInfo().boss_level, index)

	self.pIcon2:setInfo({})
	self.pIcon2:setAvatarPath(avatar)
	self.pIcon:setInfo({
		avatarID = params.info_detail.avatar_id,
		lev = params.info_detail.lev,
		avatar_frame_id = params.info_detail.avatar_frame_id
	})

	self.labelDmg.text = __("DAMAGE")

	dump(params, "测试==========")

	self.dmg.text = tostring(params.percent * 1) .. "%"

	if params.is_win and params.is_win == 1 then
		self:setState("win")
	else
		self:setState("lose")
	end
end

function FriendTeamBossRecordItem:createChildren()
	self:register()
end

function FriendTeamBossRecordItem:register()
	UIEventListener.Get(self.video).onClick = function ()
		self:onclickVideo()
	end
end

function FriendTeamBossRecordItem:onclickVideo()
	xyd.models.friendTeamBoss:reqReport(self.params.record_id)
end

function FriendTeamBossRecordItem:onclickAvatar()
	xyd.WindowManager.get():openWindow("arena_formation_window", {
		add_friend = false,
		player_id = self.params.player_id
	})
end

return FriendTeamBossRecordWindow
