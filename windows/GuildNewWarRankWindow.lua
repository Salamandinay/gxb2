local GuildNewWarRankWindow = class("GuildNewWarRankWindow", import(".BaseWindow"))
local BaseComponent = import("app.components.BaseComponent")
local AwardItem = class("AwardItem", BaseComponent)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CommonTabBar = require("app.common.ui.CommonTabBar")

function GuildNewWarRankWindow:ctor(name, params)
	GuildNewWarRankWindow.super.ctor(self, name, params)
end

function GuildNewWarRankWindow:initWindow()
	self:getUIComponent()
	GuildNewWarRankWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)

	self:registerEvent()
	self:layout()
end

function GuildNewWarRankWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.awardNode = self.groupAction:NodeByName("awardNode").gameObject
	self.titleGroup = self.groupAction:NodeByName("titleGroup").gameObject
	self.labelWinTitleName = self.titleGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.titleGroup:NodeByName("closeBtn").gameObject
	self.nav = self.titleGroup:NodeByName("nav").gameObject
	self.upgroup = self.awardNode:NodeByName("upgroup").gameObject
	self.labelRank = self.upgroup:ComponentByName("labelRank", typeof(UILabel))
	self.labelTopRank = self.upgroup:ComponentByName("labelTopRank", typeof(UILabel))
	self.topRank = self.upgroup:ComponentByName("topRank", typeof(UILabel))
	self.labelNowAward = self.upgroup:ComponentByName("labelNowAward", typeof(UILabel))
	self.nowAward = self.upgroup:NodeByName("nowAward").gameObject
	self.nowAwardUILayout = self.upgroup:ComponentByName("nowAward", typeof(UILayout))
	self.award_item = self.awardNode:NodeByName("award_item").gameObject
	self.guildscrollerCon = self.awardNode:NodeByName("guildscrollerCon").gameObject
	self.guildScroller = self.guildscrollerCon:NodeByName("guildScroller").gameObject
	self.guildScrollerUIScrollView = self.guildscrollerCon:ComponentByName("guildScroller", typeof(UIScrollView))
	self.guildLabelDesc = self.guildscrollerCon:ComponentByName("guildLabelDesc", typeof(UILabel))
	self.guildClock = self.guildscrollerCon:ComponentByName("guildClock", typeof(UITexture))
	self.guildTimeText = self.guildscrollerCon:ComponentByName("guildTimeText", typeof(UILabel))
	self.guildAwardContainer = self.guildScroller:NodeByName("guildAwardContainer").gameObject
	self.guildAwardContainerUIWrapContent = self.guildScroller:ComponentByName("guildAwardContainer", typeof(UIWrapContent))
	self.guildWrapContent = FixedWrapContent.new(self.guildScrollerUIScrollView, self.guildAwardContainerUIWrapContent, self.award_item, AwardItem, self)

	self.guildWrapContent:hideItems()

	self.myscrollerCon = self.awardNode:NodeByName("myscrollerCon").gameObject
	self.myScroller = self.myscrollerCon:NodeByName("myScroller").gameObject
	self.myScrollerUIScrollView = self.myscrollerCon:ComponentByName("myScroller", typeof(UIScrollView))
	self.myLabelDesc = self.myscrollerCon:ComponentByName("myLabelDesc", typeof(UILabel))
	self.myClock = self.myscrollerCon:ComponentByName("myClock", typeof(UITexture))
	self.myTimeText = self.myscrollerCon:ComponentByName("myTimeText", typeof(UILabel))
	self.myAwardContainer = self.myScroller:NodeByName("myAwardContainer").gameObject
	self.myAwardContainerUIWrapContent = self.myScroller:ComponentByName("myAwardContainer", typeof(UIWrapContent))
	self.myWrapContent = FixedWrapContent.new(self.myScrollerUIScrollView, self.myAwardContainerUIWrapContent, self.award_item, AwardItem, self)

	self.myWrapContent:hideItems()
end

function GuildNewWarRankWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function GuildNewWarRankWindow:layout()
	self.labelWinTitleName.text = __("GUILD_NEW_WAR_TEXT42")
	self.guildLabelDesc.text = __("GUILD_NEW_WAR_TEXT45")
	self.myLabelDesc.text = __("GUILD_NEW_WAR_TEXT46")
	self.guildClockEffect = xyd.Spine.new(self.guildClock.gameObject)

	self.guildClockEffect:setInfo("fx_ui_shizhong", function ()
		self.guildClockEffect:play("texiao1", 0)
		self.guildClockEffect:SetLocalScale(0.9, 0.9, 0.9)
	end)

	self.myClockEffect = xyd.Spine.new(self.myClock.gameObject)

	self.myClockEffect:setInfo("fx_ui_shizhong", function ()
		self.myClockEffect:play("texiao1", 0)
		self.myClockEffect:SetLocalScale(0.9, 0.9, 0.9)
	end)
	self:initNav()
	self:initTimeShow()
end

function GuildNewWarRankWindow:initNav()
	local index = 2
	self.tab = CommonTabBar.new(self.nav.gameObject, index, function (index)
		self:updateNav(index)
	end)

	self.tab:setTexts({
		__("GUILD_NEW_WAR_TEXT43"),
		__("GUILD_NEW_WAR_TEXT44")
	})
	self.tab:setTabActive(1, true, false)
end

function GuildNewWarRankWindow:updateNav(index)
	local awards = {}
	local maohao = ": "

	if xyd.Global.lang == "fr_fr" then
		maohao = " : "
	end

	if index == 1 then
		if not self.isInitGuildAward then
			self:initGuildAwardList()

			self.isInitGuildAward = true
		end

		local rank = self.activityData:getGuildRank()
		self.labelRank.text = __("GUILD_NEW_WAR_TEXT76") .. maohao .. rank
		self.labelNowAward.text = __("GUILD_NEW_WAR_TEXT77") .. maohao

		self.guildscrollerCon.gameObject:X(0)
		self.myscrollerCon.gameObject:X(2000)

		if rank > 0 then
			awards = xyd.tables.guildNewWarGuildRankTable:getAwardsWithRank(rank)
		else
			self.labelRank.text = __("GUILD_NEW_WAR_TEXT76") .. maohao .. "--"
		end

		if not self.isFirstScrollGuild then
			self.guildScrollerUIScrollView:MoveRelative(Vector3(0, -150, 0))
			self.guildScrollerUIScrollView:Scroll(0.1)

			self.isFirstScrollGuild = true
		end
	elseif index == 2 then
		if not self.isInitMyAward then
			self:initMyGuildAward()

			self.isInitMyAward = true
		end

		local rank = self.activityData:getMyRank()
		self.labelRank.text = __("GUILD_NEW_WAR_TEXT76") .. maohao .. rank
		self.labelNowAward.text = __("GUILD_NEW_WAR_TEXT77") .. maohao

		self.guildscrollerCon.gameObject:X(2000)
		self.myscrollerCon.gameObject:X(0)

		if rank > 0 then
			awards = xyd.tables.guildNewWarPersonRankTable:getAwardsWithRank(rank)
		else
			self.labelRank.text = __("GUILD_NEW_WAR_TEXT76") .. maohao .. "--"
		end

		if not self.isFirstScrollMy then
			self.myScrollerUIScrollView:MoveRelative(Vector3(0, -150, 0))
			self.myScrollerUIScrollView:Scroll(0.1)

			self.isFirstScrollMy = true
		end
	end

	if not self.upAwardArr then
		self.upAwardArr = {}
	end

	for i, awardInfo in pairs(awards) do
		local item = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = awardInfo[1],
			num = awardInfo[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			scale = Vector3(0.7037037037037037, 0.7037037037037037, 1),
			uiRoot = self.nowAward.gameObject
		}

		if not self.upAwardArr[i] then
			self.upAwardArr[i] = xyd.getItemIcon(item, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.upAwardArr[i]:setInfo(item)
		end

		self.upAwardArr[i]:SetActive(true)
	end

	for i = #awards + 1, #self.upAwardArr do
		self.upAwardArr[i]:SetActive(false)
	end

	self.nowAwardUILayout:Reposition()
end

function GuildNewWarRankWindow:initTimeShow()
	local guild_new_war_time_interval = xyd.tables.miscTable:split2num("guild_new_war_time_interval", "value", "|")

	local function initGuildTime()
		local endTime = self.activityData:getEndTime() - guild_new_war_time_interval[#guild_new_war_time_interval] * xyd.DAY_TIME
		local disTime = endTime - xyd.getServerTime()

		if disTime > 0 then
			disTime = disTime + 1
			self.guildTime = import("app.components.CountDown").new(self.guildTimeText)

			self.guildTime:setInfo({
				duration = disTime,
				callback = function ()
					self.guildTimeText.text = "00:00:00"
				end
			})
		else
			self.guildTimeText.gameObject:X(2000)
			self.guildClock.gameObject:X(2000)
		end
	end

	local function changePosMyTime()
		self.myTimeText.gameObject:X(2000)
		self.myClock.gameObject:X(2000)
	end

	local function initMyTime()
		local curPeriod, endTime = self.activityData:getCurPeriod()

		if curPeriod == xyd.GuildNewWarPeroid.ATTACHING1 or curPeriod == xyd.GuildNewWarPeroid.ATTACHING2 then
			endTime = xyd.getTomorrowTime() + (self.activityData:getReadyTimeDay() - 1) * xyd.DAY_TIME + xyd.DAY_TIME * self.activityData:getFightingTimeDay()
		elseif curPeriod == xyd.GuildNewWarPeroid.READY1 or curPeriod == xyd.GuildNewWarPeroid.READY2 then
			endTime = endTime + xyd.DAY_TIME * self.activityData:getFightingTimeDay()
		elseif curPeriod ~= xyd.GuildNewWarPeroid.FIGHTING1 then
			if curPeriod ~= xyd.GuildNewWarPeroid.FIGHTING2 then
				endTime = 0
			end
		end

		local disTime = endTime - xyd.getServerTime()

		if disTime > 1 then
			self.myTime = import("app.components.CountDown").new(self.myTimeText)

			self.myTime:setInfo({
				duration = disTime,
				callback = function ()
					self.myTimeText.text = "00:00:00"
				end
			})
		else
			changePosMyTime()
		end
	end

	local timeState = self.activityData:getCurPeriod()

	if timeState == xyd.GuildNewWarPeroid.BEGIN_RELAX then
		changePosMyTime()
	elseif timeState == xyd.GuildNewWarPeroid.END_RELAX then
		changePosMyTime()
	elseif timeState == xyd.GuildNewWarPeroid.NORMAL_RELAX then
		changePosMyTime()
	else
		initMyTime()
	end

	initGuildTime()
end

function GuildNewWarRankWindow:initGuildAwardList()
	local list = {}
	local ids = xyd.tables.guildNewWarGuildRankTable:getIDs()

	for i, id in pairs(ids) do
		local info = {
			showStr = xyd.tables.guildNewWarGuildRankTable:getRankFront(id),
			awards = xyd.tables.guildNewWarGuildRankTable:getSeasonAwards(id)
		}

		if i <= 3 then
			info.showIconStr = "rank_icon0" .. id
		end

		table.insert(list, info)
	end

	self.guildWrapContent:setInfos(list, {})
	self.guildScrollerUIScrollView:ResetPosition()
end

function GuildNewWarRankWindow:initMyGuildAward()
	local list = {}
	local ids = xyd.tables.guildNewWarPersonRankTable:getIDs()

	for i, id in pairs(ids) do
		local info = {
			showStr = xyd.tables.guildNewWarPersonRankTable:getRankFront(id),
			awards = xyd.tables.guildNewWarPersonRankTable:getPersonAwards(id)
		}

		if i <= 3 then
			info.showIconStr = "rank_icon0" .. id
		end

		table.insert(list, info)
	end

	self.myWrapContent:setInfos(list, {})
	self.myScrollerUIScrollView:ResetPosition()
end

function AwardItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:getUIComponent()
end

function AwardItem:getUIComponent()
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.imgRank = self.go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = self.go:ComponentByName("labelRank", typeof(UILabel))
	self.awardGroup = self.go:NodeByName("awardGroup").gameObject
	self.awardGroupUILayout = self.go:ComponentByName("awardGroup", typeof(UILayout))
end

function AwardItem:update(index, data)
	if not data then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.info = data

	if self.info.showIconStr then
		self.imgRank:SetActive(true)

		self.labelRank.text = " "

		xyd.setUISpriteAsync(self.imgRank, nil, self.info.showIconStr, nil, , true)
	else
		self.imgRank:SetActive(false)

		self.labelRank.text = self.info.showStr
	end

	if not self.itemArr then
		self.itemArr = {}
	end

	local awards = self.info.awards

	for i, awardInfo in pairs(awards) do
		local item = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = awardInfo[1],
			num = awardInfo[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			scale = Vector3(0.7037037037037037, 0.7037037037037037, 1),
			uiRoot = self.awardGroup.gameObject
		}

		if not self.itemArr[i] then
			self.itemArr[i] = xyd.getItemIcon(item, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.itemArr[i]:setInfo(item)
		end

		self.itemArr[i]:SetActive(true)
	end

	for i = #awards + 1, #self.itemArr do
		self.itemArr[i]:SetActive(false)
	end

	self.awardGroupUILayout:Reposition()
end

function AwardItem:getGameObject()
	return self.go
end

return GuildNewWarRankWindow
