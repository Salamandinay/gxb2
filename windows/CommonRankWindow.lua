local BaseWindow = import(".BaseWindow")
local CommonRankWindow = class("CommonRankWindow", BaseWindow)
local CommonRankWindowItem = class("CommonRankWindowItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local cjson = require("cjson")

function CommonRankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = params.activityData
	self.type = params.type
end

function CommonRankWindow:initWindow()
	CommonRankWindow.super.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self:onClickNav()
end

function CommonRankWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("groupAction").gameObject
	self.labelWinTitle_ = groupMain:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite))
	self.rankNone = groupMain:NodeByName("rankNone").gameObject
	self.labelNoneTips = self.rankNone:ComponentByName("labelNoneTips", typeof(UILabel))
	self.group1 = groupMain:NodeByName("group1").gameObject
	self.scroller = self.group1:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollerPanel = self.group1:ComponentByName("scroller", typeof(UIPanel))
	self.groupMain = self.scroller:NodeByName("groupMain").gameObject
	self.selfItemNode = self.group1:NodeByName("selfItemNode").gameObject
	local wrapContent = self.scroller:ComponentByName("groupMain", typeof(UIWrapContent))
	local item = self.group1:NodeByName("new_trial_rank_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, item, CommonRankWindowItem, self)

	self.wrapContent:hideItems()

	self.selfItemBg_ = self.selfItemNode:NodeByName("bgImg3").gameObject
	local tempGo = NGUITools.AddChild(self.selfItemNode:NodeByName("bgImg3").gameObject, item)

	tempGo.transform:Y(48)

	self.selfItem = CommonRankWindowItem.new(tempGo, self)

	self.selfItemBg_.transform:SetLocalScale(1, 0, 1)
	self.rankNone:SetActive(false)

	UIEventListener.Get(self.closeBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.labelWinTitle_.text = __("RANK")
end

function CommonRankWindow:registerEvent()
	if self.type == xyd.ActivityID.ACTIVITY_INVITATION_SENIOR then
		self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
			local data = event.data

			if data.activity_id == xyd.ActivityID.ACTIVITY_INVITATION_SENIOR then
				local detail = nil

				if data and data.detail and data.detail ~= {} and data.detail ~= "" then
					detail = cjson.decode(data.detail)
				else
					detail = {
						award_type = 7
					}
				end

				local type = detail.award_type

				if type == 7 then
					self:layout()
				end
			end
		end)
	end
end

function CommonRankWindow:onClickNav()
	if not self.activityData:reqRankInfo() then
		self:layout()
	end
end

function CommonRankWindow:layout()
	self.data_ = self.activityData:getRankData()

	if not self.data_ or not self.data_.list or #self.data_.list <= 0 then
		self.rankNone:SetActive(true)

		self.labelNoneTips.text = __("TRIAL_NO_RANK")
	else
		self.rankNone:SetActive(false)
	end

	if self.data_ and self.data_.score and tonumber(self.data_.score) > 0 then
		self.selfItemBg_.transform:SetLocalScale(1, 1, 1)
		self:updateSelfRank()
	else
		self.selfItemBg_.transform:SetLocalScale(1, 0, 1)

		self.group1:GetComponent(typeof(UIWidget)).height = 773
	end

	if not self.data_ or not self.data_.list or #self.data_.list <= 0 then
		self.wrapContent:setInfos({})

		return
	end

	self.scrollerPanel.enabled = false
	local list = self.data_.list

	self.wrapContent:setInfos(list)

	self.group1:GetComponent(typeof(UIWidget)).height = 677

	dump(self.data_)

	self.scrollerPanel.enabled = true
end

function CommonRankWindow:updateSelfRank()
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
	self.selfItem:setSelfState()
	self.selfItem.go:ComponentByName("e:Image", typeof(UISprite)):SetActive(false)
end

function CommonRankWindowItem:ctor(go, parent)
	self.parent = parent

	CommonRankWindowItem.super.ctor(self, go)
	self:setDragScrollView(parent.scroller)
	self:getUIComponent()

	self.playerIcon = nil
end

function CommonRankWindowItem:getUIComponent()
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
	self.groupScoreUILayout = self.go:ComponentByName("groupScore", typeof(UILayout))
	self.labelDesc = groupScore:ComponentByName("labelDesc", typeof(UILabel))
	self.labelScore = groupScore:ComponentByName("labelScore", typeof(UILabel))
	self.go:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	self.serverGroup = self.go:NodeByName("serverGroup").gameObject

	self.serverGroup:SetActive(true)

	self.serverId = self.serverGroup:ComponentByName("label", typeof(UILabel))

	UIEventListener.Get(self.go).onClick = function ()
		if self.data_ then
			if self.data_.player_id == xyd.Global.playerID then
				return
			end

			local wnd = xyd.getWindow("arena_formation_window")

			if wnd then
				xyd.closeWindow("arena_formation_window")
			end

			xyd.WindowManager.get():openWindow("arena_formation_window", {
				is_robot = false,
				player_id = self.data_.player_id
			})
		end
	end
end

function CommonRankWindowItem:update(index, info)
	local data = info

	if not data then
		self.go:SetActive(false)

		return
	end

	self.data_ = data

	self.go:SetActive(true)

	self.labelPlayerName.text = data.player_name
	self.labelDesc.text = __("SCORE")
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
	self.groupScoreUILayout:Reposition()
end

function CommonRankWindowItem:setSelfState()
	UIEventListener.Get(self.go).onClick = nil
end

function CommonRankWindow:willClose()
	CommonRankWindow.super.willClose(self)

	local wnd = xyd.getWindow("arena_formation_window")

	if wnd then
		xyd.closeWindow("arena_formation_window")
	end
end

return CommonRankWindow
