local RecommendType = {
	GUILD = 2,
	FRIEND = 1
}
local BaseWindow = import(".BaseWindow")
local ActivityReturnCommunityWindow = class("ActivityReturnCommunityWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local CommonTabBar = require("app.common.ui.CommonTabBar")
local FriendItem = class("FriendItem", import("app.components.CopyComponent"))
local FriendModel = xyd.models.friend
local GuildModel = xyd.models.guild
local GuildItem = class("GuildItem", import("app.components.CopyComponent"))

function ActivityReturnCommunityWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curType = -1
	self.guildRecommentList = {}
	self.friendApplyCount = 0
	self.guildApplyCount = 0
end

function ActivityReturnCommunityWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:initTopGroup()
	self:initNav()
	self:layout()
	self:registerEvent()

	if not GuildModel:isLoaded() then
		GuildModel:reqGuildInfo()
	else
		self.guildRecommentList = GuildModel.guildsList
	end
end

function ActivityReturnCommunityWindow:getUIComponent()
	local go = self.window_
	self.tipsCon = go:NodeByName("tipsCon").gameObject
	self.tipsCon2 = go:NodeByName("tipsCon2").gameObject
	self.tipsText = self.tipsCon:ComponentByName("tipsText", typeof(UILabel))
	self.tipsText2 = self.tipsCon2:ComponentByName("tipsText", typeof(UILabel))
	self.nav = go:NodeByName("navCon/nav").gameObject
	self.downGroup = go:NodeByName("downGroup").gameObject
	self.friendCon = self.downGroup:NodeByName("friendCon").gameObject
	self.guildCon = self.downGroup:NodeByName("guildCon").gameObject
	self.friendItem = self.friendCon:NodeByName("friendItem").gameObject
	self.friendExplainText = self.friendCon:ComponentByName("groupText/explainText", typeof(UILabel))
	self.friendExplainNumText = self.friendCon:ComponentByName("groupText/explainNumText", typeof(UILabel))
	self.friendTextLayout = self.friendCon:ComponentByName("groupText", typeof(UILayout))
	self.friendResetBtn = self.friendCon:NodeByName("resetBtn").gameObject
	self.friendResetBtnText = self.friendCon:ComponentByName("resetBtn/text", typeof(UILabel))
	self.friendScrollView = self.friendCon:ComponentByName("Scroller", typeof(UIScrollView))
	self.friendGroupItem = self.friendCon:NodeByName("Scroller/groupItem").gameObject
	self.friendItemLayout = self.friendGroupItem:GetComponent(typeof(UILayout))
	self.guildItem = self.guildCon:NodeByName("guildItem").gameObject
	self.guildExplainText = self.guildCon:ComponentByName("explainText", typeof(UILabel))
	self.guildResetBtn = self.guildCon:NodeByName("resetBtn").gameObject
	self.guildResetBtn_text = self.guildCon:ComponentByName("resetBtn/text", typeof(UILabel))
	self.guildScroller = self.guildCon:NodeByName("Scroller").gameObject
	self.guildScrollView = self.guildCon:ComponentByName("Scroller", typeof(UIScrollView))
	self.guildGroupItem = self.guildCon:NodeByName("Scroller/groupItem").gameObject
	self.guildItemLayout = self.guildGroupItem:GetComponent(typeof(UILayout))
	self.noneCon = self.guildCon:NodeByName("noneCon").gameObject
	self.noneText = self.guildCon:ComponentByName("noneCon/noneText", typeof(UILabel))
	self.allBg = go:NodeByName("allBg").gameObject
end

function ActivityReturnCommunityWindow:layout()
	self.tipsText.text = __("ACTIVITY_RESIDENT_RETURN_RECOMMENT1")
	self.tipsText2.text = __("ACTIVITY_RESIDENT_RETURN_RECOMMENT2")
	self.friendExplainText.text = __("FRIEND_NUM")
	local list = FriendModel:getFriendList()
	self.friendExplainNumText.text = tostring(#list) .. "/" .. xyd.tables.miscTable:getVal("friend_max_num")

	self.friendTextLayout:Reposition()

	self.friendResetBtnText.text = __("REFRESH")
	self.scroller = self.friendCon:NodeByName("Scroller").gameObject
	self.guildExplainText.text = __("ACT_RETURN_FRIEND_NAV_2")
	self.guildResetBtn_text.text = __("REFRESH")
	self.noneText.text = __("ACTIVITY_RETURN_COMMEND_HAS_GUILD")

	self.allBg:Y(-80 + 80 * self.scale_num_contrary)

	UIEventListener.Get(self.friendResetBtn.gameObject).onClick = handler(self, function ()
		local cd = 2
		local curCd = xyd.getServerTime() - (self.lastFriendRefreshTime or 0)

		if curCd >= 0 and curCd < cd then
			xyd.alert(xyd.AlertType.TIPS, __("REFRESH_LIMIT_TIME", curCd))

			return
		else
			self.lastFriendRefreshTime = xyd.getServerTime()
		end

		FriendModel:reqRecommendList()
	end)
	UIEventListener.Get(self.guildResetBtn.gameObject).onClick = handler(self, self.onClickGuildRefresh)

	self:updateNav(RecommendType.FRIEND)
end

function ActivityReturnCommunityWindow:onClickGuildRefresh()
	local cd = 2
	local curCd = xyd.getServerTime() - (self.lastGuildRefreshTime or 0)

	if curCd >= 0 and curCd < cd then
		xyd.alert(xyd.AlertType.TIPS, __("REFRESH_LIMIT_TIME", curCd))

		return
	else
		self.lastGuildRefreshTime = xyd.getServerTime()
	end

	self:guildRefresh()
end

function ActivityReturnCommunityWindow:guildRefresh()
	self.guildRecommentList = GuildModel.guildsList

	if not next(self.guildRecommentList) then
		GuildModel:reqGuildFresh()
	else
		self:layoutGuild()
	end
end

function ActivityReturnCommunityWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50, nil, function ()
		xyd.WindowManager.get():openWindow("activity_resident_return_main_window")
		self:close()
	end)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function ActivityReturnCommunityWindow:initNav()
	local index = 2
	local labelText = {}
	local labelStates = {
		chosen = {
			color = Color.New2(4278124287.0),
			effectColor = Color.New2(1030530815)
		},
		unchosen = {
			color = Color.New2(1348707327),
			effectColor = Color.New2(4278124287.0)
		}
	}
	self.tab = CommonTabBar.new(self.nav.gameObject, index, function (index)
		self:updateNav(index)
	end, nil, labelStates)

	table.insert(labelText, __("ACT_RETURN_FRIEND_NAV_1"))
	table.insert(labelText, __("ACT_RETURN_FRIEND_NAV_2"))
	self.tab:setTexts(labelText)
end

function ActivityReturnCommunityWindow:updateNav(i)
	if self.curType == i then
		return
	end

	self.curType = i

	if self.curType == RecommendType.FRIEND then
		self:chooseFriend()
	elseif self.curType == RecommendType.GUILD then
		self:chooseGuild()
	end
end

function ActivityReturnCommunityWindow:layoutFriend()
	local list = FriendModel:getRecommendList()
	self.friendApplyCount = #list
	self.itemRecommendList_ = {}

	if not self.refreshDoing_ then
		self.refreshDoing_ = true

		for i = 0, self.friendItemLayout.transform.childCount - 1 do
			local child = self.friendItemLayout.transform:GetChild(i).gameObject

			UnityEngine.Object.Destroy(child)
		end

		for idx, info in ipairs(list) do
			self:waitForFrame(1, function ()
				if not FriendModel:checkIsFriend(info.player_id) then
					local itemRoot = NGUITools.AddChild(self.friendItemLayout.gameObject, self.friendItem)

					itemRoot:SetActive(true)

					local item = FriendItem.new(itemRoot, self)

					item:update(info)

					self.itemRecommendList_[info.player_id] = item
				end

				self.friendItemLayout:Reposition()

				if idx == #list then
					self.friendScrollView:ResetPosition()

					self.refreshDoing_ = false
				end
			end, nil)
		end
	end
end

function ActivityReturnCommunityWindow:layoutGuild()
	for i = 0, self.guildItemLayout.transform.childCount - 1 do
		local child = self.guildItemLayout.transform:GetChild(i).gameObject

		UnityEngine.Object.Destroy(child)
	end

	if GuildModel.guildID and GuildModel.guildID > 0 then
		self.noneCon:SetActive(true)
		self.guildScroller:SetActive(false)
		self.guildResetBtn:SetActive(false)
	else
		self.noneCon:SetActive(false)
		self.guildScroller:SetActive(true)
		self.guildResetBtn:SetActive(true)
		self:waitForFrame(1, function ()
			local guildsList = self.guildRecommentList
			self.guildApplyCount = #self.guildRecommentList

			for i = 1, #guildsList do
				local go = NGUITools.AddChild(self.guildGroupItem, self.guildItem)
				local item = GuildItem.new(go, guildsList[i])

				self.guildItemLayout:Reposition()
			end

			self.guildScrollView:ResetPosition()
		end, nil)
	end
end

function ActivityReturnCommunityWindow:updateFriendList(friend_id)
	if self.itemRecommendList_[friend_id] then
		local item = self.itemRecommendList_[friend_id]

		item:applyGrey()

		self.friendApplyCount = self.friendApplyCount - 1

		if self.friendApplyCount == 0 then
			FriendModel:reqRecommendList()
		end
	end
end

function ActivityReturnCommunityWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.FRIEND_RECOMMEND_LIST, handler(self, self.layoutFriend))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_APPLY, handler(self, self.onFriendApply))
	self.eventProxy_:addEventListener(xyd.event.GET_INFO_BY_GUILD_ID, function (self, event)
		xyd.WindowManager.get():openWindow("guild_apply_detail_window", {
			data = event.data.guild_info
		})
	end, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_GET_INFO, self.onGuildInfo, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_REFRESH, self.onGuildsRefresh, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_SINGLE_REFRESH, function ()
		self.guildApplyCount = self.guildApplyCount - 1

		if self.guildApplyCount == 0 then
			self:guildRefresh()
		end
	end)
end

function ActivityReturnCommunityWindow:chooseFriend()
	self.guildCon:SetActive(false)
	self.friendCon:SetActive(true)

	if self.friendItemLayout.transform.childCount ~= 0 then
		self.friendScrollView:ResetPosition()
	elseif FriendModel:getRecommendList() and #FriendModel:getRecommendList() > 0 then
		self:layoutFriend()
	else
		FriendModel:reqRecommendList()
	end
end

function ActivityReturnCommunityWindow:onFriendApply(event)
	local friend_id = event.data.friend_id or 0

	if FriendModel:isShowApplyTips(friend_id) then
		FriendModel:setShowApplyTipsID(-1)
		xyd.alertTips(__("FRIEND_APPLY_SUCCESS"))
	end

	self:updateFriendList(friend_id)
end

function ActivityReturnCommunityWindow:chooseGuild()
	self.friendCon:SetActive(false)
	self.guildCon:SetActive(true)

	if not next(self.guildRecommentList) and GuildModel.guildID == 0 then
		if not next(self.guildRecommentList) then
			GuildModel:reqGuildFresh()
		else
			self:layoutGuild()
		end
	elseif self.guildItemLayout.transform.childCount == 0 then
		self:layoutGuild()
	else
		self.guildScrollView:ResetPosition()
	end
end

function ActivityReturnCommunityWindow:onGuildInfo()
	self.guildRecommentList = GuildModel.guildsList

	self:layoutGuild()
end

function ActivityReturnCommunityWindow:onGuildsRefresh()
	self:onGuildInfo()
end

function FriendItem:ctor(go)
	self.go = go
	self.labelLv_ = go:ComponentByName("detialGroup/labelLv", typeof(UILabel))
	self.labelName_ = go:ComponentByName("detialGroup/labelName", typeof(UILabel))
	self.btnApply_ = go:ComponentByName("btnGroup/group1/btnApply", typeof(UISprite))
	self.btnApply_BoxCollider = go:ComponentByName("btnGroup/group1/btnApply", typeof(UnityEngine.BoxCollider))
	self.labelDisplay_ = go:ComponentByName("btnGroup/group1/btnApply/label", typeof(UILabel))
	self.playIconPos_ = go:NodeByName("playIconPos").gameObject
	self.btnGroup_ = go:NodeByName("btnGroup/group1").gameObject
	self.label1 = go:ComponentByName("label1", typeof(UISprite))
	self.label1_text = go:ComponentByName("label1/labelText1", typeof(UILabel))
	self.label2 = go:ComponentByName("label2", typeof(UISprite))
	self.label2_text = go:ComponentByName("label2/labelText2", typeof(UILabel))
	self.playIconPos_ = go:NodeByName("playIconPos").gameObject

	self:registerEvent()
end

function FriendItem:update(info)
	self.data_ = info
	self.labelName_.text = self.data_.player_name
	self.labelDisplay_.text = __("FRIEND_APPLY")
	local playerInfo = {
		avatarID = self.data_.avatar_id,
		avatar_frame_id = self.data_.avatar_frame_id,
		callback = function ()
			xyd.WindowManager.get():openWindow("arena_formation_window", {
				is_robot = false,
				player_id = self.data_.player_id
			})
		end,
		lev = self.data_.lev
	}

	if not self.playerIcon_ then
		self.playerIcon_ = import("app.components.PlayerIcon").new(self.playIconPos_)

		self.playerIcon_:setScale(1)
		self.playerIcon_:setInfo(playerInfo)

		self.playerIcon_.go.transform.localPosition = Vector3(32, -56, 0)
	else
		self.playerIcon_:setInfo(playerInfo)
	end

	local labelNum = 1
	local targetPower = xyd.tables.miscTable:getNumber("activity_return_recommend_reason4", "value")

	if targetPower <= self.data_.arena_power and labelNum < 3 then
		xyd.setUISpriteAsync(self["label" .. labelNum], nil, "station_label_pink", nil, )

		self["label" .. labelNum .. "_text"].text = __("ACTIVITY_RETURN_COMMEND_LABEL_POWER")
		self["label" .. labelNum .. "_text"].effectColor = Color.New2(3765474047.0)
		labelNum = labelNum + 1
	end

	local targetLev = xyd.tables.miscTable:getNumber("activity_return_recommend_reason1", "value")

	if targetLev <= self.data_.lev and labelNum < 3 then
		xyd.setUISpriteAsync(self["label" .. labelNum], nil, "station_label_orange", nil, )

		self["label" .. labelNum .. "_text"].text = __("ACTIVITY_RETURN_COMMEND_LABEL_LEV")
		self["label" .. labelNum .. "_text"].effectColor = Color.New2(3515703039.0)
		labelNum = labelNum + 1
	end

	local targetActiveTime = xyd.tables.miscTable:getNumber("activity_return_recommend_reason3", "value")

	if targetActiveTime > xyd.getServerTime() - self.data_.last_time and labelNum < 3 then
		xyd.setUISpriteAsync(self["label" .. labelNum], nil, "station_label_green", nil, )

		self["label" .. labelNum .. "_text"].text = __("ACTIVITY_RETURN_COMMEND_LABEL_ACTIVE")
		self["label" .. labelNum .. "_text"].effectColor = Color.New2(1050309375)
		labelNum = labelNum + 1
	end

	if labelNum == 1 then
		self.label1.gameObject:SetActive(false)
		self.label2.gameObject:SetActive(false)
	elseif labelNum == 2 then
		self.label1.gameObject:SetActive(true)
		self.label2.gameObject:SetActive(false)
	else
		self.label1.gameObject:SetActive(true)
		self.label2.gameObject:SetActive(true)
	end
end

function FriendItem:registerEvent()
	UIEventListener.Get(self.btnApply_.gameObject).onClick = handler(self, self.onApply)
end

function FriendItem:onApply()
	if self.btnApply_BoxCollider.enabled == true then
		if FriendModel:isFullFriends() then
			xyd.alertTips(__("SELF_MAX_FRIENDS"))

			return false
		elseif FriendModel:checkIsFriend(self.data_.player_id) then
			xyd.alertTips(__("PLAYER_IS_FRIEND"))
		else
			FriendModel:applyFriend(self.data_.player_id, true)
		end
	end

	return true
end

function FriendItem:applyGrey()
	xyd.applyChildrenGrey(self.btnApply_.gameObject)

	self.btnApply_BoxCollider.enabled = false
end

function FriendItem:getPlayerID()
	return self.data_.player_id or 0
end

function FriendItem:SetActive(bool)
	self.go:SetActive(bool)
end

function GuildItem:ctor(go, data)
	GuildItem.super.ctor(self, go)

	self.data = data

	self:getUIComponent()
	self:initUIComponent()
	self:onRegisterEvent()
end

function GuildItem:getUIComponent()
	local go = self.go
	self.imgIcon01 = go:ComponentByName("imgIcon01", typeof(UISprite))
	self.imgIcon02 = go:ComponentByName("imgIcon02", typeof(UISprite))
	self.labelText0 = go:ComponentByName("labelText0", typeof(UILabel))
	self.labelText1 = go:ComponentByName("labelText1", typeof(UILabel))
	self.labelText2 = go:ComponentByName("labelText2", typeof(UILabel))
	self.labelText3 = go:ComponentByName("labelText3", typeof(UILabel))
	self.btnApply = go:ComponentByName("btnApply", typeof(UISprite))
	self.btnApply_label = self.btnApply:ComponentByName("button_label", typeof(UILabel))
end

function GuildItem:initUIComponent()
	xyd.setBgColorType(self.btnApply.gameObject, xyd.ButtonBgColorType.blue_btn_60_60)

	local lev = xyd.tables.guildExpTable:getLev(self.data.exp)
	self.labelText0.text = self.data.num .. "/" .. xyd.tables.guildExpTable:getMember(lev)
	self.labelText1.text = self.data.name
	self.labelText2.text = __("GUILD_TEXT25")
	self.labelText3.text = tostring(lev)

	xyd.setUISprite(self.imgIcon01, nil, xyd.tables.guildIconTable:getIcon(self.data.flag))

	self.btnApply_label.text = __("HERO_CHALLENGE_TEAM_TITLE")
end

function GuildItem:onRegisterEvent()
	UIEventListener.Get(self.btnApply.gameObject).onClick = handler(self, self.reqApply)

	self:registerEvent(xyd.event.GUILD_SINGLE_REFRESH, handler(self, self.refreshBtn))
end

function GuildItem:refreshBtn(event)
	if event.data and event.data.guild_id ~= self.data.guild_id then
		return
	end

	xyd.setEnabled(self.btnApply.gameObject, false)
	xyd.applyGrey(self.btnApply)

	self.btnApply_label.text = __("GUILD_TEXT27")
end

function GuildItem:reqApply()
	local msg = messages_pb:get_info_by_guild_id_req()
	msg.guild_id = self.data.guild_id

	xyd.Backend:get():request(xyd.mid.GET_INFO_BY_GUILD_ID, msg)
end

return ActivityReturnCommunityWindow
