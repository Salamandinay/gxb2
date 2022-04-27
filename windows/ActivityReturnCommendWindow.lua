local MissionType = {
	GUIDE = 2,
	FRIEND = 1
}
local BaseWindow = import(".BaseWindow")
local ActivityReturnCommendWindow = class("ActivityReturnCommendWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local CountDown = require("app.components.CountDown")
local CommonTabBar = require("app.common.ui.CommonTabBar")
local FriendClass = class("FriendClass", import("app.components.CopyComponent"))
local FriendModel = xyd.models.friend
local GuideClass = class("GuideClass", import("app.components.CopyComponent"))

function ActivityReturnCommendWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curMissionType = -1
	self.friendClass = nil
	self.guideClass = nil
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.RETURN)
end

function ActivityReturnCommendWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	if not self.friendClass then
		self.friendClass = FriendClass.new(self.friendCon, nil)
	end

	if not self.guideClass then
		self.guideClass = GuideClass.new(self.guideCon, nil)
	end

	self:initTopGroup()
	self:initNav()
	self:layout()
	self:registerEvent()

	if not xyd.models.guild:isLoaded() then
		xyd.models.guild:reqGuildInfo()
	end

	xyd.models.guild:reqGuildFresh()
end

function ActivityReturnCommendWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAll = trans:NodeByName("groupAll").gameObject
	self.upGroup = self.groupAll:NodeByName("upGroup").gameObject
	self.logoImg = self.upGroup:ComponentByName("logoImg", typeof(UITexture))
	self.helpBtn = self.upGroup:NodeByName("helpBtn").gameObject
	self.actTimeExplain = self.upGroup:ComponentByName("timeGroup/actTimeExplain", typeof(UILabel))
	self.actTimeText = self.upGroup:ComponentByName("timeGroup/actTimeText", typeof(UILabel))
	self.tipsCon = self.groupAll:NodeByName("tipsCon").gameObject
	self.tipsText = self.tipsCon:ComponentByName("tipsText", typeof(UILabel))
	self.navCon = self.groupAll:NodeByName("navCon").gameObject
	self.nav = self.navCon:NodeByName("nav").gameObject
	self.downGroup = self.groupAll:NodeByName("downGroup").gameObject
	self.friendCon = self.downGroup:NodeByName("friendCon").gameObject
	self.guideCon = self.downGroup:NodeByName("guideCon").gameObject
end

function ActivityReturnCommendWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
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

function ActivityReturnCommendWindow:getWindowTop()
	return self.windowTop
end

function ActivityReturnCommendWindow:initNav()
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

function ActivityReturnCommendWindow:updateNav(i)
	if self.curMissionType == i then
		return
	end

	self.curMissionType = i

	if self.curMissionType == MissionType.FRIEND then
		self:choiceFriend()
	elseif self.curMissionType == MissionType.GUIDE then
		self:choiceGuide()
	end
end

function ActivityReturnCommendWindow:layout()
	self.upGroup:Y(509 + 46 * self.scale_num_contrary)

	self.actTimeExplain.text = __("ACTIVITY_PLAYER_RETURN_ALLTIME")
	self.tipsText.text = __("ACTIVITY_RETURN_COMMEND_TIPS")

	xyd.setUITextureByNameAsync(self.logoImg, "activity_return_mission_logo_" .. xyd.Global.lang, true)

	self.actTimeText.text = "00:00:00"
	local countdown_allTime = self.activityData:getEndTime() - xyd.getServerTime()

	if countdown_allTime > 0 then
		self.countdown_all = CountDown.new(self.actTimeText, {
			duration = countdown_allTime,
			callback = handler(self, self.timeOver_all)
		})
	end
end

function ActivityReturnCommendWindow:timeOver_all()
	self.actTimeText.text = "00:00:00"
end

function ActivityReturnCommendWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.FRIEND_RECOMMEND_LIST, handler(self, self.choiceFriend))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_APPLY, handler(self, self.onApply))

	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_RETURN_WINDOW_HELP"
		})
	end)

	self.eventProxy_:addEventListener(xyd.event.GET_INFO_BY_GUILD_ID, function (self, event)
		xyd.WindowManager.get():openWindow("guild_apply_detail_window", {
			data = event.data.guild_info
		})
	end, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_GET_INFO, self.onGuildInfo, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_REFRESH, self.onGuildsRefresh, self)
end

function ActivityReturnCommendWindow:choiceFriend()
	if self.guideClass then
		self.guideClass:getGo():SetActive(false)
	end

	if not self.friendClass then
		return
	end

	self.friendClass:getGo():SetActive(true)

	if FriendModel:getRecommendList() and #FriendModel:getRecommendList() > 0 then
		self.friendClass:update()
	else
		FriendModel:reqRecommendList()
	end
end

function ActivityReturnCommendWindow:onApply(event)
	local friend_id = event.data.friend_id or 0

	if FriendModel:isShowApplyTips(friend_id) then
		FriendModel:setShowApplyTipsID(-1)
		xyd.alertTips(__("FRIEND_APPLY_SUCCESS"))
	end

	if self.friendClass then
		self.friendClass:update(friend_id, true)
	end
end

function ActivityReturnCommendWindow:choiceGuide()
	if self.friendClass then
		self.friendClass:getGo():SetActive(false)
	end

	if not self.guideClass then
		return
	end

	self.guideClass:removeAll()
	self.guideClass:getGo():SetActive(true)
	self.guideClass:reqGuilds()
end

function ActivityReturnCommendWindow:onGuildInfo()
	if self.guideClass then
		self.guideClass:resetLayout()
	end
end

function ActivityReturnCommendWindow:onGuildsRefresh()
	if self.guideClass then
		self.guideClass:resetLayout()
	end
end

local FriendSearchItem = class("FriendSearchItem")

function FriendClass:ctor(goItem, itemdata)
	FriendClass.super.ctor(self, goItem)

	self.goItem_ = goItem
	local transGo = goItem.transform
	self.friendRecommendItemRoot_ = transGo:NodeByName("FriendSearchItem").gameObject
	self.explainText = transGo:ComponentByName("explainText", typeof(UILabel))
	self.explainNumText = transGo:ComponentByName("explainText/explainNumText", typeof(UILabel))
	self.explainText.text = __("FRIEND_NUM")
	local list = FriendModel:getFriendList()
	self.explainNumText.text = tostring(#list) .. "/" .. xyd.tables.miscTable:getVal("friend_max_num")
	self.resetBtn = transGo:NodeByName("resetBtn").gameObject
	self.resetBtn_text = transGo:ComponentByName("resetBtn/text", typeof(UILabel))
	self.resetBtn_text.text = __("REFRESH")
	self.applyBtn = transGo:NodeByName("applyBtn").gameObject
	self.applyBtn_text = transGo:ComponentByName("applyBtn/text", typeof(UILabel))
	self.applyBtn_text.text = __("ACTIVITY_RETURN_COMMEND_ALL_APPLY")
	self.scroller = transGo:NodeByName("Scroller").gameObject
	self.scroller_scrollView = transGo:ComponentByName("Scroller", typeof(UIScrollView))
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.friendRecommendGrid_ = self.groupItem:GetComponent(typeof(UILayout))
	self.recommendIdList_ = {}
	self.itemRecommendList_ = {}
	UIEventListener.Get(self.resetBtn.gameObject).onClick = handler(self, function ()
		FriendModel:reqRecommendList()
	end)
	UIEventListener.Get(self.applyBtn.gameObject).onClick = handler(self, function ()
		local isGoOn = true

		for _, playerId in ipairs(self.recommendIdList_) do
			local item = self.itemRecommendList_[playerId]

			if item ~= nil then
				isGoOn = item:onApply()
			end

			if isGoOn == false then
				break
			end
		end
	end)
end

function FriendClass:getGo()
	return self.goItem_
end

function FriendClass:update(playerID, isAction)
	if playerID and isAction then
		self:playDisappear(playerID)
	elseif FriendModel:getRecommendList() and #FriendModel:getRecommendList() > 0 then
		self:updateRecommendList()
	else
		FriendModel:reqRecommendList()
	end
end

function FriendClass:playDisappear(id)
	local item = self.itemRecommendList_[id]

	if item and item:getPlayerID() == id then
		item:playDisappear()
	end
end

function FriendClass:updateRecommendList()
	local tempPlayerIDList = {}
	local list = FriendModel:getRecommendList()

	for _, playerId in ipairs(self.recommendIdList_) do
		local item = self.itemRecommendList_[playerId]

		if item ~= nil then
			item:SetActive(false)
		end
	end

	if not self.refreshDoing_ then
		self.refreshDoing_ = true

		for i = 0, self.friendRecommendGrid_.transform.childCount - 1 do
			local child = self.friendRecommendGrid_.transform:GetChild(i).gameObject

			UnityEngine.Object.Destroy(child)
		end

		for idx, info in ipairs(list) do
			self:waitForFrame(1, function ()
				local item = self.recommendIdList_[info.player_id]

				if not item and not FriendModel:checkIsFriend(info.player_id) then
					local itemRoot = NGUITools.AddChild(self.friendRecommendGrid_.gameObject, self.friendRecommendItemRoot_)

					itemRoot:SetActive(true)

					item = FriendSearchItem.new(itemRoot, self)

					item:update(nil, , info, 1)

					self.itemRecommendList_[info.player_id] = item

					table.insert(tempPlayerIDList, info.player_id)
				elseif item and not FriendModel:checkIsFriend(info.player_id) then
					item:SetActive(true)
				elseif item then
					item:SetActive(false)
				end

				self.friendRecommendGrid_:Reposition()

				if idx == #list then
					self.scroller_scrollView:ResetPosition()

					self.refreshDoing_ = false
				end
			end, nil)
		end
	end

	self.recommendIdList_ = tempPlayerIDList
end

function FriendSearchItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.curType_ = 1
	self.btnGroup_ = {}
	local itemTrans = self.uiRoot_.transform
	self.labelLv_ = itemTrans:ComponentByName("detialGroup/labelLv", typeof(UILabel))
	self.labelName_ = itemTrans:ComponentByName("detialGroup/labelName", typeof(UILabel))
	self.btnApply_ = itemTrans:ComponentByName("btnGroup/group1/btnApply", typeof(UISprite))
	self.btnApply_BoxCollider = itemTrans:ComponentByName("btnGroup/group1/btnApply", typeof(UnityEngine.BoxCollider))
	self.btnAgree_ = itemTrans:ComponentByName("btnGroup/group2/btnAgree", typeof(UISprite))
	self.btnRefuse_ = itemTrans:ComponentByName("btnGroup/group2/btnRefuse", typeof(UISprite))
	self.labelDisplay_ = itemTrans:ComponentByName("btnGroup/group1/btnApply/label", typeof(UILabel))
	self.playIconPos_ = itemTrans:Find("playIconPos").gameObject
	local btnGroup1 = itemTrans:Find("btnGroup/group1").gameObject
	local btnGroup2 = itemTrans:Find("btnGroup/group2").gameObject
	self.label1 = itemTrans:ComponentByName("label1", typeof(UISprite))
	self.label1_text = itemTrans:ComponentByName("label1/labelText1", typeof(UILabel))
	self.label2 = itemTrans:ComponentByName("label2", typeof(UISprite))
	self.label2_text = itemTrans:ComponentByName("label2/labelText2", typeof(UILabel))
	self.playIconPos_ = itemTrans:Find("playIconPos").gameObject
	self.btnGroup_[1] = btnGroup1
	self.btnGroup_[2] = btnGroup2

	self:registerEvent()
end

function FriendSearchItem:update(index, realIndex, info, setType)
	self.curType_ = setType or info.item_type

	if not self.curType_ then
		self.curType_ = 1
	end

	self.data_ = info

	for idx, btnGroup in ipairs(self.btnGroup_) do
		btnGroup:SetActive(idx == self.curType_)
	end

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

function FriendSearchItem:registerEvent()
	UIEventListener.Get(self.btnApply_.gameObject).onClick = handler(self, self.onApply)
end

function FriendSearchItem:onApply()
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

function FriendSearchItem:playDisappear()
	xyd.applyChildrenGrey(self.btnApply_.gameObject)

	self.btnApply_BoxCollider.enabled = false
end

function FriendSearchItem:getPlayerID()
	return self.data_.player_id or 0
end

function FriendSearchItem:SetActive(bool)
	self.uiRoot_:SetActive(bool)
end

local GuildRecommendItem = class("GuildRecommendItem", import("app.components.CopyComponent"))

function GuideClass:ctor(goItem, itemdata)
	GuideClass.super.ctor(self, goItem)

	self.goItem_ = goItem
	local transGo = goItem.transform
	self.guild_recommend_item = transGo:NodeByName("guild_recommend_item").gameObject
	self.explainText = transGo:ComponentByName("explainText", typeof(UILabel))
	self.explainText.text = __("ACT_RETURN_FRIEND_NAV_2")
	self.resetBtn = transGo:NodeByName("resetBtn").gameObject
	self.resetBtn_text = transGo:ComponentByName("resetBtn/text", typeof(UILabel))
	self.resetBtn_text.text = __("REFRESH")
	self.applyBtn = transGo:NodeByName("applyBtn").gameObject
	self.applyBtn_text = transGo:ComponentByName("applyBtn/text", typeof(UILabel))
	self.applyBtn_text.text = __("ACTIVITY_RETURN_COMMEND_ALL_APPLY")
	self.scroller = transGo:NodeByName("Scroller").gameObject
	self.scroller_scrollView = transGo:ComponentByName("Scroller", typeof(UIScrollView))
	self.groupItems = self.scroller:NodeByName("groupItem").gameObject
	self.friendRecommendGrid_ = self.groupItems:GetComponent(typeof(UILayout))
	self.noneCon = transGo:NodeByName("noneCon").gameObject
	self.noneText = transGo:ComponentByName("noneCon/noneText", typeof(UILabel))
	self.noneText.text = __("ACTIVITY_RETURN_COMMEND_HAS_GUILD")

	self.noneCon:Y(76 + -76 * xyd.getScale_Num_shortToLong())

	UIEventListener.Get(self.resetBtn.gameObject).onClick = handler(self, function ()
		self:reqGuilds()
	end)
end

function GuideClass:getGo()
	return self.goItem_
end

function GuideClass:setLayout()
	self:removeAll()
	self:waitForFrame(1, function ()
		local guildsList = xyd.models.guild.guildsList

		for i = 1, #guildsList do
			local go = NGUITools.AddChild(self.groupItems, self.guild_recommend_item)
			local item = GuildRecommendItem.new(go, guildsList[i])

			item:addParentDepth()
			self.friendRecommendGrid_:Reposition()
		end

		self.scroller_scrollView:ResetPosition()
	end, nil)
end

function GuideClass:removeAll()
	for i = 0, self.friendRecommendGrid_.transform.childCount - 1 do
		local child = self.friendRecommendGrid_.transform:GetChild(i).gameObject

		UnityEngine.Object.Destroy(child)
	end
end

function GuideClass:reqGuilds()
	xyd.models.guild:reqGuildFresh()
end

function GuideClass:resetLayout()
	if xyd.models.guild.guildID and xyd.models.guild.guildID > 0 then
		self.noneCon:SetActive(true)
		self.scroller:SetActive(false)
	else
		self.scroller:SetActive(true)
		self.noneCon:SetActive(false)
		self:setLayout()
	end
end

function GuildRecommendItem:ctor(go, data)
	GuildRecommendItem.super.ctor(self, go)

	self.data = data

	self:getUIComponent()
	self:initUIComponent()
	self:onRegisterEvent()
end

function GuildRecommendItem:getUIComponent()
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

function GuildRecommendItem:initUIComponent()
	xyd.setBgColorType(self.btnApply.gameObject, xyd.ButtonBgColorType.blue_btn_60_60)

	local lev = xyd.tables.guildExpTable:getLev(self.data.exp)
	self.labelText0.text = self.data.num .. "/" .. xyd.tables.guildExpTable:getMember(lev)
	self.labelText1.text = self.data.name
	self.labelText2.text = __("GUILD_TEXT25")
	self.labelText3.text = tostring(lev)

	xyd.setUISprite(self.imgIcon01, nil, xyd.tables.guildIconTable:getIcon(self.data.flag))

	self.btnApply_label.text = __("HERO_CHALLENGE_TEAM_TITLE")
end

function GuildRecommendItem:onRegisterEvent()
	xyd.setDarkenBtnBehavior(self.btnApply.gameObject, self, self.reqApply)
	self:registerEvent(xyd.event.GUILD_SINGLE_REFRESH, handler(self, self.refreshBtn))
end

function GuildRecommendItem:refreshBtn(event)
	if event.data and event.data.guild_id ~= self.data.guild_id then
		return
	end

	xyd.setEnabled(self.btnApply.gameObject, false)
	xyd.applyGrey(self.btnApply)

	self.btnApply_label.text = __("GUILD_TEXT27")
end

function GuildRecommendItem:reqApply()
	local msg = messages_pb:get_info_by_guild_id_req()
	msg.guild_id = self.data.guild_id

	xyd.Backend:get():request(xyd.mid.GET_INFO_BY_GUILD_ID, msg)
end

return ActivityReturnCommendWindow
