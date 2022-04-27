local BaseWindow = import(".BaseWindow")
local AcademyAssessmentRankWindow2 = class("AcademyAssessmentRankWindow2", BaseWindow)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local EntranceRankItem = class("EntranceRankItem", import("app.components.CopyComponent"))
local ArenaAwardItem = class("ArenaAwardItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local NAV_TYPE = {
	RANK_NOW = 1,
	RANK_LAST = 2
}

function AcademyAssessmentRankWindow2:ctor(name, params)
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

function AcademyAssessmentRankWindow2:initWindow()
	self:getUIComponent()
	self.rankListScroller:SetActive(false)
	BaseWindow.initWindow(self)
	self:registerEvent()
	self:initNav()
	self:onTouch(self.curClickType)
end

function AcademyAssessmentRankWindow2:getDataInfo(groupId)
	if groupId == 7 then
		groupId = 0
	end

	local msg = messages_pb:get_school_rank_list_req()
	msg.fort_id = groupId

	xyd.Backend:get():request(xyd.mid.GET_SCHOOL_RANK_LIST, msg)
end

function AcademyAssessmentRankWindow2:registerEvent()
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
		self.navClickCon:SetActive(false)
	end))
	self.eventProxy_:addEventListener(xyd.event.GET_SCHOOL_USED_PARTNERS, function (event)
		local data = event.data

		dump(data.partners)

		if #data.partners <= 0 then
			xyd.showToast(__("SCHOOL_PRACTISE_RANK_TIP"))

			return
		end

		xyd.WindowManager:get():openWindow("academy_assessment_formation_window", {
			player_id = self.otherData.player_id,
			player_name = self.otherData.player_name,
			avatar_frame = self.otherData.avatar_frame,
			avatar_id = self.otherData.avatar_id,
			fort_id = self.fortId,
			info = data.partners,
			dress_style = self.otherData.dress_style
		})
	end)
end

function AcademyAssessmentRankWindow2:setOtherData(params)
	dump(params)

	self.otherData = params
end

function AcademyAssessmentRankWindow2:getUIComponent()
	local trans = self.window_.transform
	local groupAction = trans:NodeByName("groupAction").gameObject
	self.winName = groupAction:ComponentByName("e:Group/labelWinTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("e:Group/closeBtn").gameObject
	self.nav = groupAction:NodeByName("e:Group/nav").gameObject
	self.navClickCon = groupAction:ComponentByName("e:Group/navClickCon", typeof(UISprite)).gameObject
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
	self.upgroup = self.rankNode:NodeByName("upgroup").gameObject
	self.upgroup_explainBtn = self.upgroup:NodeByName("explainBtn").gameObject
	self.upgroup_upBgImg = self.upgroup:ComponentByName("upBgImg", typeof(UITexture))
	self.upgroup_upExplainText = self.upgroup:ComponentByName("upExplainText", typeof(UILabel))
	self.upgroup_frameCon = self.upgroup:NodeByName("frameCon").gameObject
	self.playerIcon = PlayerIcon.new(self.upgroup_frameCon)

	self.playerIcon:setScale(0.8770491803278688)

	self.rankNode_last = groupAction:NodeByName("rankNodeLast").gameObject
	self.activity_sports_rank_item_last = self.rankNode_last:NodeByName("activity_sports_rank_item").gameObject
	self.rankListScroller_last = self.rankNode_last:NodeByName("rankListScroller").gameObject
	self.rankListScroller_scrollerView_last = self.rankNode_last:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListScroller_panel_last = self.rankNode_last:ComponentByName("rankListScroller", typeof(UIPanel))
	self.rankListContainer_last = self.rankNode_last:NodeByName("rankListScroller/rankListContainer").gameObject
	self.playerRankGroup_last = self.rankNode_last:NodeByName("playerRankGroup").gameObject
	local rankListWrapContent_last = self.rankListScroller_last:ComponentByName("rankListContainer", typeof(UIWrapContent))
	self.rankNone_last = self.rankNode_last:NodeByName("rankNone").gameObject
	self.labelNoneTips_last = self.rankNone_last:ComponentByName("labelNoneTips", typeof(UILabel))
	self.wrapContent_last = FixedWrapContent.new(self.rankListScroller_scrollerView_last, rankListWrapContent_last, self.activity_sports_rank_item_last, EntranceRankItem, self)
	self.upgroup_last = self.rankNode_last:NodeByName("upgroup").gameObject
	self.upgroup_explainBtn_last = self.upgroup_last:NodeByName("explainBtn").gameObject
	self.upgroup_upBgImg_last = self.upgroup_last:ComponentByName("upBgImg", typeof(UITexture))
	self.upgroup_upExplainText_last = self.upgroup_last:ComponentByName("upExplainText", typeof(UILabel))
	self.upgroup_frameCon_last = self.upgroup_last:NodeByName("frameCon").gameObject
	self.playerIcon_last = PlayerIcon.new(self.upgroup_frameCon_last)

	self.playerIcon_last:setScale(0.8770491803278688)

	local filterGroup = groupAction:NodeByName("filterGroup")

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

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.upgroup_explainBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACADEMY_ASSESSMENT_ONE_CAMP_RANK_AWARD_HELP"
		})
	end)
	self.winName.text = __("CAMPAIGN_RANK_WINDOW")
	self.labelNoneTips.text = __("ACADEMY_ASSESSMEBT_NO_RANK")
	self.labelNoneTips_last.text = __("ACADEMY_ASSESSMEBT_NO_RANK")
	self.upgroup_upExplainText.text = __("ACADEMY_ASSESSMEBT_RANK_AWARD_TIP")
	self.upgroup_upExplainText_last.text = __("ACADEMY_ASSESSMEBT_RANK_AWARD_TIP")
end

function AcademyAssessmentRankWindow2:changeFilter(chosenGroup, isGoOnRefresh)
	local choseType = -1

	if self.curClickType == NAV_TYPE.RANK_NOW then
		choseType = self.chosenGroup
	elseif self.curClickType == NAV_TYPE.RANK_LAST then
		choseType = self.chosenGroup
	end

	if chosenGroup == -1 or choseType == -1 then
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

function AcademyAssessmentRankWindow2:initNav()
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

	self.tab:setTexts(xyd.split(__("ACADEMY_ASSESSMEBT_RANK_NAME"), "|"))
end

function AcademyAssessmentRankWindow2:updateNav(i)
	if self.curClickType == i then
		return
	end

	self.curClickType = i

	self:onTouch(i)
end

function AcademyAssessmentRankWindow2:layout(groupId)
	if self.curClickType == NAV_TYPE.RANK_NOW then
		self:initRankList(groupId)
	elseif self.curClickType == NAV_TYPE.RANK_LAST then
		self:initRankListLast(groupId)
	end
end

function AcademyAssessmentRankWindow2:initRankList(groupId)
	if self.selfRankItem == nil then
		self:refreshSelfRank(groupId)
	else
		self:refreshSelfRank(groupId, true)
	end

	local rankData = self["groupData" .. groupId]

	if not rankData then
		return
	end

	if rankData.list == nil or #rankData.list == 0 then
		self.rankListScroller:SetActive(false)
		self.rankNone:SetActive(true)

		return
	end

	self.rankListScroller:SetActive(true)
	self.rankNone:SetActive(false)
	self:refreshFrameCon(groupId)

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
			type = NAV_TYPE.RANK_NOW,
			player_id = data.player_id,
			dress_style = data.dress_style
		}

		if data.avatar_id then
			table.insert(rankDataList, params)
		end
	end

	self.wrapContent:setInfos(rankDataList, {})
end

function AcademyAssessmentRankWindow2:initRankListLast(groupId)
	if self.selfRankItem_last == nil then
		self:refreshSelfRankLast(groupId)
	else
		self:refreshSelfRankLast(groupId, true)
	end

	self:refreshFrameCon(groupId)

	local rankData = self["groupData" .. groupId]

	if not rankData then
		return
	end

	if rankData.list_last == nil or #rankData.list_last == 0 then
		self.rankListScroller_last:SetActive(false)
		self.rankNone_last:SetActive(true)

		return
	end

	self.rankListScroller_last:SetActive(true)
	self.rankNone_last:SetActive(false)

	local rankDataList = {}

	for i in pairs(rankData.list_last) do
		local data = rankData.list_last[i]
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
			type = NAV_TYPE.RANK_LAST,
			player_id = data.player_id,
			dress_style = data.dress_style
		}

		if data.avatar_id then
			table.insert(rankDataList, params)
		end
	end

	self.wrapContent_last:setInfos(rankDataList, {})
end

function AcademyAssessmentRankWindow2:refreshSelfRank(groupId, isRefresh)
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
		player_id = xyd.models.selfPlayer:getPlayerID(),
		dress_style = xyd.models.dress:getEquipedStyles()
	}

	if isRefresh == nil or isRefresh == false then
		local tmp = NGUITools.AddChild(self.playerRankGroup.gameObject, self.activity_sports_rank_item.gameObject)
		local item = EntranceRankItem.new(tmp, self, self_item)
		self.selfRankItem = item
	elseif isRefresh and isRefresh == true then
		self.selfRankItem:update(nil, self_item)
	end
end

function AcademyAssessmentRankWindow2:refreshSelfRankLast(groupId, isRefresh)
	local rankNum = -1

	if self["groupData" .. groupId] and self["groupData" .. groupId].self_rank_last then
		rankNum = self["groupData" .. groupId] and self["groupData" .. groupId].self_rank_last
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

	local selfScore = self["groupData" .. groupId].self_score_last
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
		player_id = xyd.models.selfPlayer:getPlayerID(),
		dress_style = xyd.models.dress:getEquipedStyles()
	}

	if isRefresh == nil or isRefresh == false then
		local tmp = NGUITools.AddChild(self.playerRankGroup_last.gameObject, self.activity_sports_rank_item.gameObject)
		local item = EntranceRankItem.new(tmp, self, self_item)
		self.selfRankItem_last = item
	elseif isRefresh and isRefresh == true then
		self.selfRankItem_last:update(nil, self_item)
	end
end

function AcademyAssessmentRankWindow2:onTouch(index)
	if index == NAV_TYPE.RANK_NOW then
		self.rankNode:SetActive(true)
		self.rankNode_last:SetActive(false)
		self:changeFilter(self.chosenGroup, true)
	elseif index == NAV_TYPE.RANK_LAST then
		self.rankNode:SetActive(false)
		self.rankNode_last:SetActive(true)

		if self.firstInitLast == nil then
			self:initRankListLast(self.chosenGroup)

			self.firstInitLast = true

			self:changeFilter(self.chosenGroup)
		else
			self:changeFilter(self.chosenGroup, true)
		end
	end
end

function AcademyAssessmentRankWindow2:refreshFrameCon(groupId)
	if self.curClickType == NAV_TYPE.RANK_NOW then
		if groupId ~= 7 then
			self.upgroup:SetActive(true)
			xyd.setUITextureAsync(self.upgroup_upBgImg, "Textures/academy_assessment_web/academy_assessment_rank_bg_" .. groupId, function ()
			end, false)
			self.rankListScroller_panel:SetAnchor(self.rankNode, 0, 4, 0, 85, 1, -4, 1, -163)
			self.rankNone:Y(-9)

			local reseTinfo = {
				avatar_frame_id = xyd.tables.schoolPractiseFrameTable:getAward(groupId)[1]
			}

			self.playerIcon:setInfo(reseTinfo)
		else
			self.upgroup:SetActive(false)
			self.rankListScroller_panel:SetAnchor(self.rankNode, 0, 4, 0, 85, 1, -4, 1, 15)
			self.rankNone:Y(122)
		end
	elseif self.curClickType == NAV_TYPE.RANK_LAST then
		if groupId ~= 7 then
			self.upgroup_last:SetActive(true)
			xyd.setUITextureAsync(self.upgroup_upBgImg_last, "Textures/academy_assessment_web/academy_assessment_rank_bg_" .. groupId, function ()
			end, false)
			self.rankListScroller_panel_last:SetAnchor(self.rankNode_last, 0, 4, 0, 85, 1, -4, 1, -163)
			self.rankNone_last:Y(-9)

			local reseTinfo = {
				avatar_frame_id = xyd.tables.schoolPractiseFrameTable:getAward(groupId)[1]
			}

			self.playerIcon_last:setInfo(reseTinfo)
		else
			self.upgroup_last:SetActive(false)
			self.rankListScroller_panel_last:SetAnchor(self.rankNode_last, 0, 4, 0, 85, 1, -4, 1, 15)
			self.rankNone_last:Y(122)
		end
	end
end

function EntranceRankItem:ctor(go, parent, params)
	self.go = go

	self:getUIComponent()

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

		self:update(nil, params)
	end

	self.parent = parent
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
				if self.type_ == NAV_TYPE.RANK_NOW then
					self.pIcon = PlayerIcon.new(self.playerIcon, self.parent.rankListScroller_panel)
				elseif self.type_ == NAV_TYPE.RANK_LAST then
					self.pIcon = PlayerIcon.new(self.playerIcon, self.parent.rankListScroller_panel_last)
				end
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
			local wnd = xyd.WindowManager:get():getWindow("academy_assessment_rank_window2")

			if wnd then
				print(self.params.player_id)
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

			msg.is_last = self.parent.curClickType - 1
			msg.other_player_id = self.params.player_id

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

return AcademyAssessmentRankWindow2
