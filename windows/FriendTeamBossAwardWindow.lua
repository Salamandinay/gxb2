local BaseWindow = import(".BaseWindow")
local FriendTeamBossAwardWindow = class("FriendTeamBossAwardWindow", BaseWindow)
local ItemIcon = import("app.components.ItemIcon")
local BaseComponent = import("app.components.BaseComponent")
local FriendTeamBossAwardItem = class("FriendTeamBossAwardItem", BaseComponent)
local FriendTeamBossAwardItem2 = class("FriendTeamBossAwardItem2", BaseComponent)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = FriendTeamBossAwardItem2.new(go)

	self.item:setDragScrollView(parent.navScroller2)
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

function FriendTeamBossAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "FriendTeamBossAwardWindowSkin"
end

function FriendTeamBossAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	self.nav1Label.text = __("FRIEND_TEAM_BOSS_AWARD1")
	self.nav2Label.text = __("FRIEND_TEAM_BOSS_AWARD2")

	xyd.setUITextureAsync(self.leftImage, "Textures/friend_team_boss_web/arena_award_bg")
	xyd.setUITextureAsync(self.rightImage, "Textures/friend_team_boss_web/arena_award_bg")
	self:layoutAward()
	self:layoutAllAward()

	if xyd.models.friendTeamBoss:checkInFight() then
		self:onClickNav(1)
	else
		self:onClickNav(2)
	end

	self:register()
end

function FriendTeamBossAwardWindow:getUIComponent()
	local trans = self.window_.transform
	self.content = trans:NodeByName("content").gameObject
	local topGroup = self.content:NodeByName("topGroup").gameObject
	self.closeBtn = topGroup:NodeByName("closeBtn").gameObject
	self.labelWinTitle = topGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.nav1 = self.content:NodeByName("nav1").gameObject
	self.nav1Label = self.nav1:ComponentByName("label", typeof(UILabel))
	self.nav2 = self.content:NodeByName("nav2").gameObject
	self.nav2Label = self.nav2:ComponentByName("label", typeof(UILabel))
	local group = self.content:NodeByName("group").gameObject
	local middleGroup = group:NodeByName("middleGroup").gameObject
	self.leftImage = middleGroup:ComponentByName("leftImage", typeof(UITexture))
	self.rightImage = middleGroup:ComponentByName("rightImage", typeof(UITexture))
	self.labelRank = middleGroup:ComponentByName("labelRank", typeof(UILabel))
	self.labelTopRank = middleGroup:ComponentByName("labelTopRank", typeof(UILabel))
	self.labelNowAward = middleGroup:ComponentByName("labelNowAward", typeof(UILabel))
	self.nowAward = middleGroup:NodeByName("nowAward").gameObject
	self.labelDesc = group:ComponentByName("labelDesc", typeof(UILabel))
	self.navScroller1 = group:ComponentByName("navScroller1", typeof(UIScrollView))
	self.awardContainer = self.navScroller1:NodeByName("awardContainer")
	self.navScroller2 = group:ComponentByName("navScroller2", typeof(UIScrollView))
	local wrapContent2 = self.navScroller2:ComponentByName("awardContainer2", typeof(UIWrapContent))
	local iconContainer2 = self.navScroller2:NodeByName("iconContainer").gameObject
	self.wrapContent2 = FixedWrapContent.new(self.navScroller2, wrapContent2, iconContainer2, ItemRender, self)
end

function FriendTeamBossAwardWindow:layoutAward()
	NGUITools.DestroyChildren(self.nowAward.transform)
	NGUITools.DestroyChildren(self.awardContainer.transform)

	local teamInfo = xyd.models.friendTeamBoss:getTeamInfo()
	local table_ = xyd.tables.friendTeamBossAwardTable

	if #table_:getDownAward(teamInfo.boss_level) > 0 then
		local item = FriendTeamBossAwardItem.new(self.awardContainer.gameObject)
		local awards = table_:getDownAward(teamInfo.boss_level)

		item:setInfo({
			label = __("FRIEND_TEAM_BOSS_DOWN_AWARD"),
			items = awards
		})
	end

	if #table_:getRelegationAward(teamInfo.boss_level) > 0 then
		local item = FriendTeamBossAwardItem.new(self.awardContainer.gameObject)
		local awards = table_:getRelegationAward(teamInfo.boss_level)

		item:setInfo({
			label = __("FRIEND_TEAM_BOSS_RELEGATION_AWARD"),
			items = awards
		})
	end

	if #table_:getUpAward(teamInfo.boss_level) > 0 then
		local item = FriendTeamBossAwardItem.new(self.awardContainer.gameObject)
		local awards = table_:getUpAward(teamInfo.boss_level)

		item:setInfo({
			label = __("FRIEND_TEAM_BOSS_Up_AWARD"),
			items = awards
		})

		for i = 1, #awards do
			local it = ItemIcon.new(self.nowAward)

			it:setInfo({
				hideText = true,
				itemID = awards[i][1],
				num = awards[i][2]
			})
			it:SetLocalScale(0.7, 0.7, 1)
		end
	else
		local awards = table_:getRelegationAward(teamInfo.boss_level)

		for i = 1, #awards do
			local it = ItemIcon.new(self.nowAward)

			it:setInfo({
				hideText = true,
				itemID = awards[i][1],
				num = awards[i][2]
			})
			it:SetLocalScale(0.7, 0.7, 1)
		end
	end
end

function FriendTeamBossAwardWindow:layoutAllAward()
	local ids = xyd.tables.friendTeamBossAwardTable:getIDs()
	local data = {}

	for i = #ids, 1, -1 do
		table.insert(data, {
			id = ids[i]
		})
	end

	self.wrapContent2:setInfos(data, {})
end

function FriendTeamBossAwardWindow:register()
	FriendTeamBossAwardWindow.super.register(self)

	UIEventListener.Get(self.nav1).onClick = function ()
		self:onClickNav(1)
	end

	UIEventListener.Get(self.nav2).onClick = function ()
		self:onClickNav(2)
	end
end

function FriendTeamBossAwardWindow:setNavState(index, state)
	local nav = self["nav" .. index]
	local label = self["nav" .. index .. "Label"]
	local sprite = nav:GetComponent(typeof(UISprite))

	if state == "selected" then
		xyd.setUISprite(sprite, nil, "blue_btn_65_65")

		label.color = Color.New2(4294967295.0)
		label.effectColor = Color.New2(473916927)
	else
		xyd.setUISprite(sprite, nil, "white_btn_65_65")

		label.color = Color.New2(960513791)
		label.effectColor = Color.New2(4294967295.0)
	end
end

function FriendTeamBossAwardWindow:onClickNav(index)
	if index == 1 then
		if not xyd.models.friendTeamBoss:checkInFight() then
			xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_IN_TEAMUP"))

			return
		end

		local hpp = xyd.models.friendTeamBoss:getTeamInfo().boss_1_hp
		self.labelRank.text = __("FRIEND_TEAM_BOSS_PROCESS", tostring(hpp) .. "%")
		self.labelNowAward.text = __("FRIEND_TEAM_BOSS_KILL_AWARD")
		self.labelDesc.text = __("ARENA_RANK_DESC2")

		self.labelTopRank:SetActive(false)
	else
		self.labelRank.text = __("TEAM_LEV", xyd.models.friendTeamBoss:getTeamInfo().boss_level)
		self.labelTopRank.text = __("FRIEND_TEAM_BOSS_TOP_LEVEL", xyd.models.friendTeamBoss:getSelfInfo().history_max_boss_lev)
		self.labelDesc.text = __("FRIEND_TEAM_BOSS_RANK_DESC")

		self.labelTopRank:SetActive(true)
	end

	self["navScroller" .. tostring(index)]:SetActive(true)
	self:setNavState(index, "selected")
	self["navScroller" .. tonumber(3 - index)]:SetActive(false)
	self:setNavState(tonumber(3 - index), "unSelected")
end

function FriendTeamBossAwardItem:ctor(parentGo)
	FriendTeamBossAwardItem.super.ctor(self, parentGo)

	self.skinName = "FriendTeamBossAwardItemSkin"
	self.currentState = xyd.Global.lang

	self:getUIComponent()
end

function FriendTeamBossAwardItem:getPrefabPath()
	return "Prefabs/Components/friend_team_boss_award_item"
end

function FriendTeamBossAwardItem:getUIComponent()
	self.textLabel = self.go:ComponentByName("textLabel", typeof(UILabel))
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
end

function FriendTeamBossAwardItem:setInfo(params)
	self.textLabel.text = params.label

	for i = 1, #params.items do
		local item = ItemIcon.new(self.itemGroup)

		item:setInfo({
			hideText = true,
			itemID = params.items[i][1],
			num = params.items[i][2]
		})
		item:SetLocalScale(0.7, 0.7, 0.7)
	end
end

local PngNum = import("app.components.PngNum")

function FriendTeamBossAwardItem2:ctor(parentGo)
	FriendTeamBossAwardItem2.super.ctor(self, parentGo)
	self:getUIComponent()

	self.numColorMap = {
		"friend_team_boss_brown",
		"friend_team_boss_grey",
		"friend_team_boss_yellow",
		"friend_team_boss_blue"
	}
	self.skinName = "FriendTeamBossAwardItemSkin2"
	self.itemGroupItems = {}
end

function FriendTeamBossAwardItem2:getPrefabPath()
	return "Prefabs/Components/friend_team_boss_award_item2"
end

function FriendTeamBossAwardItem2:getUIComponent()
	local content = self.go:NodeByName("content").gameObject
	self.numBg = content:ComponentByName("numBg", typeof(UISprite))
	self.numLabelContainer = content:NodeByName("numLabel").gameObject
	self.numLabel = PngNum.new(self.numLabelContainer)
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject

	xyd.setUISpriteAsync(self.numBg, nil, "boss_award_bg_8")
end

function FriendTeamBossAwardItem2:update()
	self:setInfo(self.data.id)
end

function FriendTeamBossAwardItem2:setInfo(id)
	self.num = id
	local awards = xyd.tables.friendTeamBossAwardTable:getRelegationAward(id)

	for i = 1, #awards do
		if i <= #self.itemGroupItems then
			local item = self.itemGroupItems[i]

			item:setInfo({
				hideText = true,
				isAddUIDragScrollView = true,
				itemID = awards[i][1],
				num = awards[i][2]
			})
			item:setScale(0.7)
			item:SetActive(true)
		else
			local item = ItemIcon.new(self.itemGroup)

			item:setInfo({
				hideText = true,
				isAddUIDragScrollView = true,
				itemID = awards[i][1],
				num = awards[i][2]
			})
			item:setScale(0.7)
			item:SetActive(true)

			self.itemGroupItems[i] = item
		end
	end

	for i = #awards + 1, self.itemGroup.transform.childCount do
		local item = self.itemGroupItems[i]

		item:SetActive(false)
	end

	self:setNum()
end

function FriendTeamBossAwardItem2:setNum()
	local numFont = math.floor((self.num - 1) / 10) + 1

	if numFont > 4 then
		numFont = 4
	end

	self.numLabel:setInfo({
		iconName = self.numColorMap[numFont],
		num = self.num
	})

	local imgNum = math.ceil(self.num / 10)

	if imgNum > 8 then
		imgNum = 8
	end

	xyd.setUISprite(self.numBg, nil, "boss_award_bg_" .. tostring(imgNum))
end

return FriendTeamBossAwardWindow
