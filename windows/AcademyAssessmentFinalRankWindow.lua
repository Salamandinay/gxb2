local BaseWindow = import(".BaseWindow")
local AcademyAssessmentFinalRankWindow = class("AcademyAssessmentFinalRankWindow", BaseWindow)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local EntranceRankItem = class("EntranceRankItem", import("app.components.CopyComponent"))
local ArenaAwardItem = class("ArenaAwardItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local WindowTop = import("app.components.WindowTop")
local NAV_TYPE = {
	RANK_NOW = 1,
	AWARD = 2
}

function AcademyAssessmentFinalRankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.cur_select_ = 0
	self.curClickType = NAV_TYPE.RANK_NOW
	self.fortId = 0

	if params and params.fort_id then
		self.fortId = params.fort_id
	end

	self.filter = {}
	self.filterChosen = {}
	self.chosenGroup = -1
	self.chosenGroupLast = -1

	self:getDataInfo(self.fortId)
end

function AcademyAssessmentFinalRankWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	if xyd.models.academyAssessment:getIsNewSeason() and not xyd.db.misc:getValue("academy_assessment_pop_up_window_pop_state" .. xyd.models.academyAssessment.seasonId) then
		xyd.db.misc:setValue({
			value = 1,
			key = "academy_assessment_pop_up_window_pop_state" .. xyd.models.academyAssessment.seasonId
		})
	end

	self:initNav()
	self:onTouch(self.curClickType)
	self:initResItem()
	self:registerEvent()
	xyd.models.academyAssessment:setRedMark()
end

function AcademyAssessmentFinalRankWindow:initResItem()
	local winTop = WindowTop.new(self.window_, self.name_, 50, true)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	winTop:setItem(items)
end

function AcademyAssessmentFinalRankWindow:getDataInfo(groupId)
	if groupId == 7 then
		groupId = 0
	end

	local msg = messages_pb:get_school_rank_list_req()
	msg.fort_id = groupId

	xyd.Backend:get():request(xyd.mid.GET_SCHOOL_RANK_LIST, msg)
end

function AcademyAssessmentFinalRankWindow:registerEvent()
	AcademyAssessmentFinalRankWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_SCHOOL_RANK_LIST, handler(self, function (_, event)
		local rankData = event.data
		local fortType = rankData.map_type

		if fortType == 0 then
			fortType = 7
		end

		self["groupData" .. fortType] = xyd.decodeProtoBuf(rankData)
		self.chosenGroup = fortType

		self:layout(fortType)
		self:changeFilter(fortType)
	end))

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.upgroup_explainBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACADEMY_ASSESSMENT_ONE_CAMP_RANK_AWARD_HELP"
		})
	end)
	UIEventListener.Get(self.helpBtn_.gameObject).onClick = handler(self, function ()
		if tonumber(xyd.tables.miscTable:getNumber("school_practise_new_help_tips", "value")) <= xyd.models.academyAssessment.seasonId then
			xyd.WindowManager:get():openWindow("help_window", {
				key = "ACADEMY_ASSESSMENT_WINDOW_HELP_NEW_2"
			})
		else
			xyd.WindowManager:get():openWindow("help_window", {
				key = "ACADEMY_ASSESSMENT_WINDOW_HELP_NEW"
			})
		end
	end)

	UIEventListener.Get(self.shopBtn_.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("shop_window", {
			shopType = xyd.ShopType.SHOP_ASSESSMENT_ACADEMY
		})
	end

	self.eventProxy_:addEventListener(xyd.event.GET_SCHOOL_USED_PARTNERS, function (event)
		local data = event.data

		if #data.partners <= 0 then
			xyd.showToast(__("SCHOOL_PRACTISE_RANK_TIP"))

			return
		end

		xyd.WindowManager:get():openWindow("academy_assessment_formation_window", {
			player_id = self.otherData.player_id,
			player_name = self.otherData.player_name,
			avatar_frame = self.otherData.avatar_frame_id,
			avatar_id = self.otherData.avatar_id,
			fort_id = self.fortId,
			info = data.partners,
			dress_style = self.otherData.dress_style
		})
	end)
end

function AcademyAssessmentFinalRankWindow:setOtherData(params)
	self.otherData = params
end

function AcademyAssessmentFinalRankWindow:getUIComponent()
	local trans = self.window_.transform
	local groupAction = trans:NodeByName("groupAction").gameObject
	self.winNameName = groupAction:ComponentByName("e:Group/labelWinTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("e:Group/closeBtn").gameObject
	self.nav = groupAction:NodeByName("e:Group/nav").gameObject
	self.groupBg = trans:NodeByName("groupBg").gameObject
	self.bg = self.groupBg:ComponentByName("bg", typeof(UITexture))

	xyd.setUITextureAsync(self.bg, "Textures/academy_assessment_web/academy_assessment_bg")

	self.groupMain = trans:NodeByName("groupMain").gameObject
	local group1 = self.groupMain:NodeByName("group1").gameObject
	self.helpBtn_ = group1:ComponentByName("helpBtn", typeof(UISprite)).gameObject
	self.shopBtn_ = group1:ComponentByName("shopBtn_", typeof(UISprite))
	self.group2 = group1:NodeByName("group2").gameObject
	self.titleBgLeft = self.group2:ComponentByName("imageLeft", typeof(UISprite))
	self.titleBgRight = self.group2:ComponentByName("imageRight", typeof(UISprite))
	self.imgTitle_ = self.group2:ComponentByName("imgTitle_", typeof(UISprite))
	self.tipsText_ = self.group2:ComponentByName("tipsTextCon/tipsText", typeof(UILabel))
	self.tipsNumText_ = self.group2:ComponentByName("tipsTextCon/tipsNumText", typeof(UILabel))
	self.tipsTextCon_ = self.group2:ComponentByName("tipsTextCon", typeof(UILayout)).gameObject
	self.tipsTextCon_layout = self.group2:ComponentByName("tipsTextCon", typeof(UILayout))

	xyd.setUISpriteAsync(self.titleBgLeft, nil, "academy_assessment_title_bg_new", function ()
		self.titleBgLeft:MakePixelPerfect()
	end, nil)
	xyd.setUISpriteAsync(self.titleBgRight, nil, "academy_assessment_title_bg_new", function ()
		self.titleBgRight:MakePixelPerfect()
	end, nil)

	local src = "academy_assessment_logo_" .. tostring(xyd.Global.lang)

	xyd.setUISpriteAsync(self.imgTitle_, nil, src, function ()
		self.imgTitle_:MakePixelPerfect()
	end, nil)
	self.group2:SetLocalPosition(0, -21, 0)

	self.rankNode = groupAction:NodeByName("rankNode").gameObject
	self.activity_sports_rank_item = self.rankNode:NodeByName("activity_sports_rank_item").gameObject
	self.rankListScroller = self.rankNode:NodeByName("rankListScroller").gameObject
	self.rankListScroller_scrollerView = self.rankNode:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListScroller_panel = self.rankNode:ComponentByName("rankListScroller", typeof(UIPanel))
	self.rankListContainer = self.rankNode:NodeByName("rankListScroller/rankListContainer").gameObject
	self.playerRankGroup = self.rankNode:NodeByName("playerRankGroup").gameObject
	local rankListWrapContent = self.rankListScroller:ComponentByName("rankListContainer", typeof(UIWrapContent))
	self.rankNone = self.rankNode:NodeByName("rankNone").gameObject
	self.labelNoneTips = self.rankNone:ComponentByName("labelNoneTips", typeof(UILabel))
	self.wrapContent = FixedWrapContent.new(self.rankListScroller_scrollerView, rankListWrapContent, self.activity_sports_rank_item, EntranceRankItem, self)

	self.wrapContent:setInfos({}, {})

	self.upgroup = self.rankNode:NodeByName("upgroup").gameObject
	self.upgroup_explainBtn = self.upgroup:NodeByName("explainBtn").gameObject
	self.upgroup_upBgImg = self.upgroup:ComponentByName("upBgImg", typeof(UITexture))
	self.upgroup_upExplainText = self.upgroup:ComponentByName("upExplainText", typeof(UILabel))
	self.upgroup_frameCon = self.upgroup:NodeByName("frameCon").gameObject
	self.playerIcon = PlayerIcon.new(self.upgroup_frameCon)

	self.playerIcon:setScale(0.8770491803278688)

	self.awardNode = groupAction:NodeByName("awardNode").gameObject
	self.upgroupAward = self.awardNode:NodeByName("upgroup").gameObject
	self.arena_award_item = self.upgroupAward:NodeByName("arena_award_item").gameObject
	self.labelRank = self.upgroupAward:ComponentByName("labelRank", typeof(UILabel))
	self.labelRankNum = self.upgroupAward:ComponentByName("labelRankNum", typeof(UILabel))
	self.labelTopRank = self.upgroupAward:ComponentByName("labelTopRank", typeof(UILabel))
	self.topRank = self.upgroupAward:ComponentByName("topRank", typeof(UILabel))
	self.labelNowAward = self.upgroupAward:ComponentByName("labelNowAward", typeof(UILabel))
	self.nowAward = self.upgroupAward:NodeByName("nowAward").gameObject
	self.awardItem1 = self.upgroupAward:NodeByName("nowAward/ns1:ItemIcon").gameObject
	self.awardItem2 = self.upgroupAward:NodeByName("nowAward/ns2:ItemIcon").gameObject
	self.labelDesc = self.awardNode:ComponentByName("labelDesc", typeof(UILabel))
	self.clock = self.awardNode:NodeByName("clock").gameObject
	self.ddl2Text = self.awardNode:ComponentByName("ddl2Text", typeof(UILabel))
	self.awardScroller = self.awardNode:NodeByName("awardScroller").gameObject
	self.awardScroller_scrollerView = self.awardNode:ComponentByName("awardScroller", typeof(UIScrollView))
	self.awardScroller_panel = self.awardNode:ComponentByName("awardScroller", typeof(UIPanel))
	self.awardContainer = self.awardNode:NodeByName("awardScroller/awardContainer").gameObject
	self.awardContainer_UILayout = self.awardNode:ComponentByName("awardScroller/awardContainer", typeof(UILayout))
	self.labelRank.text = tostring(__("NOW_SCORE"))

	if xyd.models.academyAssessment.selfScore or xyd.models.academyAssessment.selfScore == nil then
		self.labelRankNum.text = xyd.models.academyAssessment.selfScore or 0
	end

	self.labelNowAward.text = __("NOW_AWARD_ACCORDING_TO_SCORE")
	self.labelTopRank.text = tostring(__("TOP_SCORE"))
	self.labelDesc.text = __("SCORE")
	self.ddl2Text.text = __("AWARD3")

	self.labelTopRank.gameObject:SetActive(false)
	self.topRank.gameObject:SetActive(false)

	if xyd.models.academyAssessment:getIsNewSeason() and xyd.models.academyAssessment.seasonId > 1 and (xyd.models.academyAssessment.historyScore or xyd.models.academyAssessment.historyScore == nil) then
		self.labelTopRank.gameObject:SetActive(true)
		self.topRank.gameObject:SetActive(true)

		self.topRank.text = xyd.models.academyAssessment.historyScore or 0
	end

	local filterGroup = self.rankNode:NodeByName("filterGroup")

	for i = 1, 7 do
		self.filter[i] = filterGroup:NodeByName("group" .. i).gameObject
		UIEventListener.Get(self.filter[i]).onClick = handler(self, function ()
			if self["groupData" .. i] then
				if self.chosenGroup == i then
					return
				end

				self.chosenGroup = i

				self:changeFilter(i)
			else
				self:getDataInfo(i)
			end
		end)
		self.filterChosen[i] = filterGroup:NodeByName("group" .. i .. "/chosen").gameObject
	end

	self.winNameName.text = __("CAMPAIGN_RANK_WINDOW")
	self.tipsText_.text = __("ACADEMY_ASSESSMENT_FINAL_SHOW_TIP")
	self.labelNoneTips.text = __("ACADEMY_ASSESSMEBT_NO_RANK")
	self.upgroup_upExplainText.text = __("ACADEMY_ASSESSMEBT_RANK_AWARD_TIP")
	self.tipsNumText_.text = "00:00:00"

	self:initTime()
	self.tipsTextCon_:SetActive(true)
	self.tipsTextCon_layout:Reposition()
end

function AcademyAssessmentFinalRankWindow:initTime()
	local startTime = xyd.models.academyAssessment.startTime
	local allTime = xyd.tables.miscTable:getNumber("school_practise_season_duration", "value")
	local showTime = xyd.tables.miscTable:getNumber("school_practise_display_duration", "value")
	local durationTime = startTime + allTime - xyd.getServerTime()

	if durationTime > 0 then
		self.setCountDownTime = CountDown.new(self.tipsNumText_, {
			duration = durationTime,
			callback = handler(self, self.timeOver)
		})
	else
		self.tipsNumText_.text = "00:00"
	end
end

function AcademyAssessmentFinalRankWindow:timeOver()
	self.tipsNumText_.text = "00:00"
end

function AcademyAssessmentFinalRankWindow:changeFilter(chosenGroup, isGoOnRefresh)
	local choseType = -1

	if self.curClickType == NAV_TYPE.RANK_NOW then
		choseType = self.chosenGroup
	elseif self.curClickType == NAV_TYPE.RANK_LAST then
		choseType = self.chosenGroup
	end

	if choseType == -1 or chosenGroup == -1 then
		if isGoOnRefresh == nil or isGoOnRefresh == false then
			return
		end
	else
		if self.curClickType == NAV_TYPE.RANK_NOW then
			self.chosenGroup = chosenGroup
		elseif self.curClickType == NAV_TYPE.RANK_LAST then
			self.chosenGroup = chosenGroup
		end

		self:layout(chosenGroup)
	end

	local choseUIType = -1

	if self.curClickType == NAV_TYPE.RANK_NOW then
		choseUIType = self.chosenGroup
	elseif self.curClickType == NAV_TYPE.RANK_LAST then
		choseUIType = self.chosenGroup
	end

	if choseUIType == -1 then
		choseUIType = 7
	end

	for k, v in ipairs(self.filterChosen) do
		if k == choseUIType then
			v:SetActive(true)
		else
			v:SetActive(false)
		end
	end
end

function AcademyAssessmentFinalRankWindow:initNav()
	local index = 2
	local labelStates = {
		chosen = {
			color = Color.New2(4294967295.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	}
	self.tab = CommonTabBar.new(self.nav.gameObject, index, function (index)
		self:updateNav(index)
	end, nil, labelStates)

	self.tab:setTexts(xyd.split(__("ACTIVITY_SPORTS_RANK_LABELS"), "|"))
end

function AcademyAssessmentFinalRankWindow:updateNav(i)
	if self.curClickType == i then
		return
	end

	self.curClickType = i

	self:onTouch(i)
end

function AcademyAssessmentFinalRankWindow:layout(groupId)
	if self.curClickType == NAV_TYPE.RANK_NOW then
		self:initRankList(groupId)
	elseif self.curClickType == NAV_TYPE.AWARD then
		-- Nothing
	end
end

function AcademyAssessmentFinalRankWindow:initRankList(groupId)
	if self.selfRankItem == nil then
		self:refreshSelfRank(groupId)
	else
		self:refreshSelfRank(groupId, true)
	end

	self:refreshFrameCon(groupId)

	local rankData = self["groupData" .. groupId]

	if not rankData then
		return
	end

	if rankData.list == nil or #rankData.list == 0 then
		self.rankListScroller:SetActive(false)
		self.rankNone:SetActive(true)

		return
	end

	self.rankNone:SetActive(false)

	local rankDataList = {}

	for i in pairs(rankData.list) do
		local data = rankData.list[i]
		local rank = i

		if data.rank then
			rank = data.rank
		end

		local params = {
			group = 0,
			avatar_id = data.avatar_id,
			frame_id = data.avatar_frame_id,
			level = data.lev,
			player_name = data.player_name,
			server_id = data.server_id,
			point = data.score,
			rank = rank,
			player_id = data.player_id,
			type = NAV_TYPE.RANK_NOW
		}

		if data.avatar_id then
			table.insert(rankDataList, params)
		end
	end

	self.wrapContent:setInfos(rankDataList, {})
	self.rankListScroller:SetActive(true)
end

function AcademyAssessmentFinalRankWindow:refreshSelfRank(groupId, isRefresh)
	local rankNum = -1

	if self["groupData" .. groupId] and self["groupData" .. groupId].self_rank then
		rankNum = self["groupData" .. groupId] and self["groupData" .. groupId].self_rank
	else
		rankNum = -1
	end

	local rankText = 0

	if rankNum == 0 or rankNum >= 1 then
		rankText = tostring(rankNum + 1)
	elseif rankNum > 0 and rankNum < 1 then
		rankText = tostring(xyd.round(rankNum * 100)) .. "%"
	elseif rankNum == -1 then
		rankText = tostring(-1)
	end

	local selfScore = self["groupData" .. groupId].self_score
	selfScore = selfScore or 0
	local self_item = {
		group = 0,
		hide_bg = true,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		level = xyd.models.backpack:getLev(),
		player_name = xyd.models.selfPlayer:getPlayerName(),
		server_id = xyd.models.selfPlayer:getServerID(),
		point = selfScore,
		rank = rankText,
		player_id = xyd.models.selfPlayer:getPlayerID()
	}

	if isRefresh == nil or isRefresh == false then
		local tmp = NGUITools.AddChild(self.playerRankGroup.gameObject, self.activity_sports_rank_item.gameObject)
		local item = EntranceRankItem.new(tmp, self, self_item)
		self.selfRankItem = item
	elseif isRefresh and isRefresh == true then
		self.selfRankItem:update(nil, self_item)
	end
end

function AcademyAssessmentFinalRankWindow:onTouch(index)
	if index == NAV_TYPE.RANK_NOW then
		self.rankNode:SetActive(true)
		self.awardNode:SetActive(false)
		self:changeFilter(self.chosenGroup, true)
	elseif index == NAV_TYPE.AWARD then
		self.awardNode:SetActive(true)
		self.rankNode:SetActive(false)

		if self.firstInitAward == nil then
			self.firstInitAward = true

			self:layoutAward()
		end
	end
end

function AcademyAssessmentFinalRankWindow:refreshFrameCon(groupId)
	if self.curClickType == NAV_TYPE.RANK_NOW then
		if groupId ~= 7 then
			self.upgroup:SetActive(true)
			xyd.setUITextureAsync(self.upgroup_upBgImg, "Textures/academy_assessment_web/academy_assessment_rank_bg_" .. groupId, function ()
			end, false)
			self.rankListScroller_panel:SetTopAnchor(self.rankNode, 1, -163)
			self.rankNone:Y(-9)

			local reseTinfo = {
				avatar_frame_id = xyd.tables.schoolPractiseFrameTable:getAward(groupId)[1],
				effectLoadCallBck = handler(self, function ()
					if self.curClickType ~= NAV_TYPE.RANK_NOW then
						-- Nothing
					end
				end)
			}

			self.playerIcon:setInfo(reseTinfo)
		else
			self.upgroup:SetActive(false)
			self.rankListScroller_panel:SetTopAnchor(self.rankNode, 1, 15)
			self.rankNone:Y(122)
		end
	elseif self.curClickType == NAV_TYPE.RANK_LAST then
		-- Nothing
	end
end

function AcademyAssessmentFinalRankWindow:layoutAward()
	NGUITools.DestroyChildren(self.nowAward.transform)
	NGUITools.DestroyChildren(self.awardContainer.transform)

	local curScroe = 0

	if xyd.models.academyAssessment.selfScore then
		curScroe = xyd.models.academyAssessment.selfScore
	end

	local awardId = xyd.models.academyAssessment:getAwardPointTable():getScoreId(curScroe)

	if awardId ~= -1 then
		local awardArr = xyd.models.academyAssessment:getAwardPointTable():getAward(awardId)

		for i in pairs(awardArr) do
			local item = awardArr[i]
			local icon = xyd.getItemIcon({
				isAddUIDragScrollView = true,
				hideText = true,
				isShowSelected = false,
				itemID = item[1],
				num = item[2],
				scale = Vector3(0.7, 0.7, 1),
				uiRoot = self.nowAward.gameObject
			})
		end
	end

	local a_t = xyd.models.academyAssessment:getAwardPointTable()

	for i in pairs(a_t:getIds()) do
		local awardItem = NGUITools.AddChild(self.awardContainer.gameObject, self.arena_award_item.gameObject)
		local item = ArenaAwardItem.new(awardItem)

		item:setInfo(i, "award", a_t)
	end

	self.arena_award_item:SetActive(false)

	self.awardScroller_panel.alpha = 0.01

	self:waitForFrame(2, function ()
		self.awardContainer_UILayout:Reposition()
		self.awardScroller_scrollerView:ResetPosition()
		self:waitForFrame(1, function ()
			self.awardScroller_panel.alpha = 1
		end)
	end)
end

function EntranceRankItem:ctor(go, parent, params)
	self.go = go

	self:getUIComponent()

	self.parent = parent

	if params then
		self.params = params
		self.hide_bg_ = params.hide_bg
		self.avatar_id_ = tonumber(params.avatar_id)
		self.frame_id_ = tonumber(params.frame_id)
		self.level_ = tonumber(params.level)
		self.player_name_ = params.player_name
		self.server_id_ = tonumber(params.server_id)
		self.point_ = params.point
		self.rank_ = params.rank
		self.group_ = tonumber(params.group)

		self:update(nil, params)
	end
end

function EntranceRankItem:SetActive(visible)
	self.go:SetActive(visible)
end

function EntranceRankItem:getUIComponent()
	self.bgImg = self.go:NodeByName("bgImg").gameObject
	self.labelGroup = self.go:NodeByName("labelGroup").gameObject
	self.imgRankIcon = self.labelGroup:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = self.labelGroup:ComponentByName("labelRank", typeof(UILabel))
	self.avatarGroup = self.go:NodeByName("avatarGroup").gameObject
	self.playerIcon = self.go:NodeByName("avatarGroup/playerIcon").gameObject
	self.labelPlayerName = self.go:ComponentByName("labelPlayerName", typeof(UILabel))
	self.labelDesText = self.go:ComponentByName("e:Group/labelDesText", typeof(UILabel))
	self.labelCurrentNum = self.go:ComponentByName("e:Group/labelCurrentNum", typeof(UILabel))
	self.serverInfo = self.go:NodeByName("serverInfo").gameObject
	self.serverId = self.go:ComponentByName("serverInfo/serverId", typeof(UILabel))
	self.groupWords = self.go:ComponentByName("groupWords", typeof(UILabel))
	self.groupImg = self.go:ComponentByName("groupImg", typeof(UISprite))
	self.labelDesText.text = __("SCORE")
	self.groupWords.text = __("ACTIVITY_SPORTS_GROUP")
end

function EntranceRankItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.info = info
	local params = info

	self.go:SetActive(true)

	if params then
		self.params = params
		self.hide_bg_ = params.hide_bg
		self.avatar_id_ = tonumber(params.avatar_id)
		self.frame_id_ = tonumber(params.frame_id)
		self.level_ = tonumber(params.level)
		self.player_name_ = params.player_name
		self.server_id_ = tonumber(params.server_id)
		self.point_ = params.point
		self.rank_ = params.rank
		self.group_ = tonumber(params.group)
		self.type_ = tonumber(params.type)

		if not self.pIcon then
			if self.type_ then
				self.pIcon = PlayerIcon.new(self.playerIcon, self.parent.rankListScroller_panel)
			else
				self.pIcon = PlayerIcon.new(self.playerIcon)
			end
		end

		self:layout()
	end
end

function EntranceRankItem:layout()
	if tonumber(self.rank_) ~= nil and tonumber(self.rank_) <= 3 and tonumber(self.rank_) > 0 then
		xyd.setUISpriteAsync(self.imgRankIcon, nil, "rank_icon0" .. self.rank_, nil, )
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = tostring(self.rank_)
	end

	if self.rank_ == "-1" then
		self.labelRank:SetActive(false)
	end

	if self.group_ == 0 then
		self.groupWords:SetActive(false)
		self.groupImg:SetActive(false)
	else
		self.groupWords:SetActive(true)
		self.groupImg:SetActive(true)

		self.groupWords.text = __("ACTIVITY_SPORTS_GROUP")

		xyd.setUISpriteAsync(self.groupImg, nil, "img_group" .. self.group_, nil, )
	end

	self.pIcon:setInfo({
		avatarID = self.avatar_id_,
		avatar_frame_id = self.frame_id_,
		lev = self.level_,
		callback = function ()
			local wnd = xyd.WindowManager:get():getWindow("academy_assessment_final_rank_window")

			if wnd then
				wnd:setOtherData({
					player_id = self.params.player_id,
					player_name = self.params.player_name,
					avatar_frame = self.frame_id_,
					avatar_id = self.avatar_id_,
					dress_style = self.params.dress_style
				})
			end

			local msg = messages_pb:get_school_used_partners_req()

			if self.parent.chosenGroup == 7 then
				msg.fort_id = 0
			else
				msg.fort_id = self.parent.chosenGroup
			end

			msg.other_player_id = self.params.player_id
			msg.is_last = 0

			xyd.Backend:get():request(xyd.mid.GET_SCHOOL_USED_PARTNERS, msg)
		end
	})

	self.labelPlayerName.text = self.player_name_
	self.serverId.text = xyd.getServerNumber(self.server_id_)
	self.labelCurrentNum.text = self.point_

	if self.hide_bg_ then
		self.bgImg:SetActive(false)
	end
end

function ArenaAwardItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function ArenaAwardItem:getUIComponent()
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.imgRank = self.go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = self.go:ComponentByName("labelRank", typeof(UILabel))
	self.awardGroup = self.go:NodeByName("awardGroup")
	self.awardGroup_layout = self.go:ComponentByName("awardGroup", typeof(UILayout))
end

function ArenaAwardItem:setInfo(id, colName, table, notShowSpecial)
	table = table or xyd.models.academyAssessment:getAwardPointTable()

	self.imgRank:SetActive(false)
	self.labelRank:SetActive(true)

	self.labelRank.text = table:getPointText(id)

	NGUITools.DestroyChildren(self.awardGroup.transform)

	local awards = table:getAward(id)

	for i in pairs(awards) do
		local item = awards[i]
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			noClickSelected = true,
			hideText = true,
			isShowSelected = false,
			itemID = item[1],
			num = item[2],
			scale = Vector3(0.7, 0.7, 1),
			uiRoot = self.awardGroup.gameObject
		})
	end

	self.awardGroup_layout:Reposition()
end

return AcademyAssessmentFinalRankWindow
