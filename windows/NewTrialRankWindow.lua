local BaseWindow = import(".BaseWindow")
local NewTrialRankWindow = class("NewTrialRankWindow", BaseWindow)
local NewTrialRankWindowItem = class("NewTrialRankWindowItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")

function NewTrialRankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function NewTrialRankWindow:initWindow()
	NewTrialRankWindow.super.initWindow(self)
	self:getUIComponent()
	self:registerEvent()

	self.boss_id = xyd.models.trial:getBossId()

	self:onClickNav(self.boss_id)
end

function NewTrialRankWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("groupAction").gameObject
	self.labelWinTitle_ = groupMain:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite))
	self.rankNone = groupMain:NodeByName("rankNone").gameObject
	self.labelNoneTips = self.rankNone:ComponentByName("labelNoneTips", typeof(UILabel))
	self.navGroup_ = groupMain:NodeByName("navGroup").gameObject

	for i = 1, 2 do
		self["nav" .. i] = self.navGroup_:NodeByName("nav" .. i).gameObject
		self["navName" .. i] = self["nav" .. i]:ComponentByName("labelName", typeof(UILabel))
		self["navSelectImg" .. i] = self["nav" .. i]:NodeByName("selectImg").gameObject
	end

	self.navName1.text = __("NEW_TRIAL_VOLCAN_SECRET")
	self.navName2.text = __("NEW_TRIAL_SEA_SECRET")
	self.group1 = groupMain:NodeByName("group1").gameObject
	self.scroller = self.group1:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollerPanel = self.group1:ComponentByName("scroller", typeof(UIPanel))
	self.groupMain = self.scroller:NodeByName("groupMain").gameObject
	self.selfItemNode = self.group1:NodeByName("selfItemNode").gameObject
	local wrapContent = self.scroller:ComponentByName("groupMain", typeof(UIWrapContent))
	local item = self.scroller:NodeByName("new_trial_rank_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, item, NewTrialRankWindowItem, self)

	self.wrapContent:hideItems()

	self.selfItemBg_ = self.selfItemNode:NodeByName("bgImg3").gameObject
	local tempGo = NGUITools.AddChild(self.selfItemNode:NodeByName("bgImg3").gameObject, item)

	tempGo.transform:Y(48)

	self.selfItem = NewTrialRankWindowItem.new(tempGo, self)

	self.selfItemBg_.transform:SetLocalScale(1, 0, 1)
	self.rankNone:SetActive(false)

	UIEventListener.Get(self.closeBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow("new_trial_rank_window")
	end

	self.labelWinTitle_.text = __("RANK")
end

function NewTrialRankWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.TRIAL_GET_RANK_LIST, handler(self, self.layout))

	for i = 1, 2 do
		UIEventListener.Get(self["nav" .. i]).onClick = function ()
			self:onClickNav(i)
		end
	end
end

function NewTrialRankWindow:onClickNav(index)
	self.boss_id = index

	for i = 1, 2 do
		self["navSelectImg" .. i]:SetActive(i == self.boss_id)
	end

	if not xyd.models.trial:reqRankInfo(self.boss_id) then
		self:layout()
	end
end

function NewTrialRankWindow:layout()
	self.data_ = xyd.models.trial:getRankData(self.boss_id)

	if not self.data_ or not self.data_.list or #self.data_.list <= 0 then
		self.rankNone:SetActive(true)

		self.labelNoneTips.text = __("TRIAL_NO_RANK")
	else
		self.rankNone:SetActive(false)
	end

	if not self.data_ or not self.data_.list or #self.data_.list <= 0 then
		self.wrapContent:setInfos({})

		return
	end

	self.scrollerPanel.enabled = false
	local list = self.data_.list

	self.wrapContent:setInfos(list)

	self.group1:GetComponent(typeof(UIWidget)).height = 677

	if self.data_.score and tonumber(self.data_.score) > 0 then
		self:initSelfRank()
		self.selfItemBg_.transform:SetLocalScale(1, 1, 1)
	else
		self.selfItemBg_.transform:SetLocalScale(1, 0, 1)

		self.group1:GetComponent(typeof(UIWidget)).height = 773
	end

	self.scrollerPanel.enabled = true
end

function NewTrialRankWindow:initSelfRank()
	local selfParams = {
		player_id = xyd.Global.playerID,
		score = self.data_.score,
		rank = self.data_.rank,
		player_name = xyd.Global.playerName,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		lev = xyd.models.backpack:getLev(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		server_id = xyd.models.selfPlayer:getServerID()
	}

	self.selfItem:update(self.data_.rank, selfParams)
	self.selfItem.go:ComponentByName("e:Image", typeof(UISprite)):SetActive(false)
	self.selfItem:setSelfItemState()
end

function NewTrialRankWindowItem:ctor(go, parent)
	self.parent = parent

	NewTrialRankWindowItem.super.ctor(self, go)
	self:setDragScrollView(parent.scroller)
	self:getUIComponent()

	self.playerIcon = nil
end

function NewTrialRankWindowItem:getUIComponent()
	self.go:SetLocalScale(0.95, 0.95, 0.95)

	self.avatarGroup = self.go:NodeByName("avatarGroup").gameObject
	self.labelPlayerName = self.go:ComponentByName("labelPlayerName", typeof(UILabel))

	self.labelPlayerName.transform:SetLocalPosition(-42, 20, 0)

	local group1 = self.go:NodeByName("group1").gameObject
	self.imgRankIcon = group1:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = group1:ComponentByName("labelRank", typeof(UILabel))
	local groupLev = self.go:NodeByName("groupLev").gameObject
	self.labelLevel = groupLev:ComponentByName("labelLevel", typeof(UILabel))
	local groupScore = self.go:NodeByName("groupScore").gameObject
	self.labelDesc = groupScore:ComponentByName("labelDesc", typeof(UILabel))
	self.labelScore = groupScore:ComponentByName("labelScore", typeof(UILabel))
	self.go:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	self.serverGroup = self.go:NodeByName("serverGroup").gameObject

	self.serverGroup:SetActive(true)

	self.serverId = self.serverGroup:ComponentByName("label", typeof(UILabel))

	UIEventListener.Get(self.go).onClick = function ()
		if self.data_ then
			xyd.WindowManager.get():openWindow("trial_formation_window", {
				player_id = self.data_.player_id,
				player_name = self.data_.player_name,
				avatar_frame = self.data_.avatar_frame_id,
				avatar_id = self.data_.avatar_id,
				server_id = self.data_.server_id,
				dress_style = self.data_.dress_style or {},
				boss_id = self.parent.boss_id
			})
		end
	end
end

function NewTrialRankWindowItem:update(index, info)
	local data = info

	if not data then
		self.go:SetActive(false)

		return
	end

	self.data_ = data

	self.go:SetActive(true)

	self.labelPlayerName.text = data.player_name
	self.labelDesc.text = __("WORLD_BOSS_DESC_TEXT")
	self.labelLevel.text = data.lev
	self.labelScore.text = tostring(data.score)

	if not data.server_id then
		self.serverId.text = "S999"
	else
		self.serverId.text = xyd.getServerNumber(data.server_id)
	end

	local rank = index

	if rank <= 3 then
		xyd.setUISprite(self.imgRankIcon, nil, "rank_icon0" .. tostring(rank))
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)

		self.labelRank.text = tostring(rank)

		self.labelRank:SetActive(true)
	end

	if not self.playerIcon then
		self.playerIcon = PlayerIcon.new(self.avatarGroup, self.parent.scroller.gameObject:GetComponent(typeof(UIPanel)))

		self.playerIcon.go:SetLocalScale(0.65, 0.65, 1)
	end

	self.playerIcon:setInfo({
		noClick = true,
		avatarID = data.avatar_id,
		avatar_frame_id = data.avatar_frame_id
	})
end

function NewTrialRankWindowItem:setSelfItemState()
	self.go:GetComponent(typeof(UIButtonScale)).enabled = false
	UIEventListener.Get(self.go).onClick = nil
end

return NewTrialRankWindow
