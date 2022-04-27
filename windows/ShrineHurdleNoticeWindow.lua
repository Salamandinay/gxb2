local ShrineHurdleNoticeWindow = class("ShrineHurdleNoticeWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ResItem = import("app.components.ResItem")
local shopModel = xyd.models.shop
local PlayerIcon = import("app.components.PlayerIcon")
local RankItem = class("RankItem", require("app.components.CopyComponent"))
local AchievementItem = class("AchievementItem", import("app.components.CopyComponent"))
local AwardItem = class("AwardItem", import("app.components.CopyComponent"))

function AwardItem:ctor(go, parent)
	AwardItem.super.ctor(self, go)

	self.go = go
	self.parent = parent

	self:getUIComponent()
	self:setDragScrollView(parent.scroller)
end

function AwardItem:getUIComponent()
	self.imgRank = self.go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = self.go:ComponentByName("labelRank", typeof(UILabel))
	self.awardGroup = self.go:NodeByName("awardGroup").gameObject
	self.awardGroupLayout = self.awardGroup:GetComponent(typeof(UILayout))
end

function AwardItem:update(index, info)
	local id = info.id
	local table = xyd.tables.shrineHurdleRankTable

	if table:getRank(id) <= 3 then
		self.imgRank:SetActive(true)
		xyd.setUISpriteAsync(self.imgRank, nil, "rank_icon0" .. table:getRank(id))
		self.labelRank:SetActive(false)
	else
		self.imgRank:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = table:getShow(id)
	end

	NGUITools.DestroyChildren(self.awardGroup.transform)

	local awards = table:getAwards(info.selectType, id)

	for i = 1, #awards do
		local item = awards[i]
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			labelNumScale = 1.2,
			noClickSelected = true,
			notShowGetWayBtn = true,
			hideText = true,
			show_has_num = true,
			uiRoot = self.awardGroup,
			itemID = item[1],
			num = item[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		icon:SetLocalScale(0.7, 0.7, 1)
	end

	self.awardGroupLayout:Reposition()
end

function RankItem:ctor(go, parent, params)
	self.parent_ = parent

	RankItem.super.ctor(self, go)

	self.info = params

	self:getUIComponent()
	self:initUIComponent()
end

function RankItem:getUIComponent()
	self.labelGroup = self.go:NodeByName("labelGroup").gameObject
	self.imgRankIcon = self.labelGroup:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = self.labelGroup:ComponentByName("labelRank", typeof(UILabel))
	self.avatarGroup = self.go:NodeByName("avatarGroup").gameObject
	self.playerIcon = self.go:NodeByName("avatarGroup/playerIcon").gameObject
	self.labelPlayerName = self.go:ComponentByName("labelPlayerName", typeof(UILabel))
	self.labelDesText = self.go:ComponentByName("scoreNode/labelDesText", typeof(UILabel))
	self.labelCurrentNum = self.go:ComponentByName("scoreNode/labelCurrentNum", typeof(UILabel))
	self.serverId = self.go:ComponentByName("serverInfo/serverId", typeof(UILabel))
	self.labelDesText.text = __("SHRINE_NOTICE_TEXT07")
	self.pIcon = PlayerIcon.new(self.playerIcon)
end

function RankItem:initUIComponent()
	if not self.info then
		return
	end

	self.labelPlayerName.text = self.info.player_name

	if self.info.rank <= 3 and self.info.score > 0 then
		xyd.setUISprite(self.imgRankIcon, nil, "rank_icon0" .. self.info.rank)
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	elseif self.info.score > 0 then
		self.labelRank.text = tostring(self.info.rank)

		self.labelRank:SetActive(true)
		self.imgRankIcon:SetActive(false)
	else
		self.labelRank.text = " "

		self.labelRank:SetActive(true)
		self.imgRankIcon:SetActive(false)
	end

	self.pIcon:setInfo({
		noClick = true,
		avatarID = self.info.avatar_id,
		avatar_frame_id = self.info.avatar_frame_id,
		lev = self.info.lev
	})
	self.pIcon:AddUIDragScrollView(self.parent_.rankListScroller_scrollerView)

	local server_id = self.server_id_ or self.info.server_id
	self.serverId.text = xyd.getServerNumber(server_id)

	if self.point_ then
		self.labelCurrentNum.text = self.point_
	elseif self.info.score then
		self.labelCurrentNum.text = self.info.score
	else
		self.labelCurrentNum.text = "0"
	end
end

function RankItem:update(_, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.info = info
	local params = info

	self.go:SetActive(true)

	if params then
		self.avatar_id_ = tonumber(params.avatar_id)
		self.frame_id_ = tonumber(params.avatar_frame_id)
		self.level_ = tonumber(params.lev)
		self.player_name_ = params.player_name
		self.server_id_ = tonumber(params.server_id)
		self.point_ = params.score
		self.rank_ = params.rank
	end

	self:initUIComponent()
end

local AchievementTable = xyd.tables.shrineAchievementTable
local AchievementTypeTable = xyd.tables.shrineAchievementTypeTable

function AchievementItem:ctor(go, parent)
	self.parent_ = parent

	AchievementItem.super.ctor(self, go)

	self.itemsRootList_ = {}
	self.itemID_ = {}
	self.itemNum_ = {}
	local itemTrans = self.go.transform
	self.progressBar_ = itemTrans:ComponentByName("progress", typeof(UIProgressBar))
	self.progressDesc_ = itemTrans:ComponentByName("progress/labelDisplay", typeof(UILabel))
	self.btnAward_ = itemTrans:NodeByName("btnAward").gameObject
	self.btnAwardImg_ = self.btnAward_:GetComponent(typeof(UISprite))
	self.btnAwardLabel_ = itemTrans:ComponentByName("btnAward/button_label", typeof(UILabel))
	self.missionDesc_ = itemTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.imgAward_ = itemTrans:ComponentByName("imgAward", typeof(UISprite))
	self.iconRoot1_ = itemTrans:Find("itemIcon1").gameObject
	self.iconRoot2_ = itemTrans:Find("itemIcon2").gameObject
	self.itemsRootList_[1] = self.iconRoot1_
	self.itemsRootList_[2] = self.iconRoot2_
	self.collectionBefore_ = {}

	self:layout()
	self:registerEvent()
end

function AchievementItem:registerEvent()
	UIEventListener.Get(self.btnAward_).onClick = handler(self, self.onClickAward)
end

function AchievementItem:onClickAward()
	if self.data_.mission_id then
		xyd.models.shrine:getMissionAward(self.data_.mission_id)
	else
		xyd.models.shrine:getAchieveAward(self.data_.achieve_type)
	end
end

function AchievementItem:getAchievementInfo()
	return self.data_
end

function AchievementItem:layout()
	xyd.setUISpriteAsync(self.imgAward_, nil, "mission_awarded_" .. tostring(xyd.Global.lang) .. "_png", nil, )
end

function AchievementItem:update(_, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	local hasChange = false
	local useKey = "mission_id"

	if info.achieve_id then
		useKey = "achieve_id"
	end

	if not self.data_ or info[useKey] ~= self.data_[useKey] then
		hasChange = true
	end

	self.data_ = info
	local achieve_id = info[useKey]
	local infoKey = info[useKey]

	if achieve_id == 0 and useKey == "achieve_id" then
		achieve_id = AchievementTypeTable:getEndAchievement(info.achieve_type)
	end

	local complete_value, text = nil
	local progressValue = info.value

	if useKey == "achieve_id" then
		complete_value = AchievementTable:getCompleteValue(achieve_id) or 0
		text = AchievementTypeTable:getDesc(info.achieve_type, complete_value)
		self.itemsInfo_ = AchievementTable:getAward(achieve_id)

		if xyd.Global.lang == "fr_fr" then
			self.missionDesc_.fontSize = 14
		end
	else
		complete_value = xyd.tables.shrineMissionTable:getComplete(achieve_id) or 0
		text = xyd.tables.shrineMissionTable:getDesc(achieve_id, complete_value)
		self.itemsInfo_ = xyd.tables.shrineMissionTable:getAwards(achieve_id)
	end

	self.missionDesc_.text = text

	if complete_value < progressValue then
		progressValue = complete_value
	end

	self.progressDesc_.text = progressValue .. "/" .. complete_value
	self.progressBar_.value = tonumber(progressValue) / tonumber(complete_value)

	self.iconRoot1_:SetActive(false)
	self.iconRoot2_:SetActive(false)

	for idx, itemInfo in ipairs(self.itemsInfo_) do
		local itemRoot = self.itemsRootList_[idx]

		itemRoot:SetActive(true)

		if not self.itemID_[idx] or not self.itemNum_[idx] or self.itemID_[idx] ~= itemInfo[1] and self.itemID_[idx] ~= xyd.tables.itemTable:partnerCost(itemInfo[1])[1] or self.itemNum_[idx] ~= itemInfo[2] then
			for i = 0, itemRoot.transform.childCount - 1 do
				local child = itemRoot.transform:GetChild(i).gameObject

				NGUITools.Destroy(child)
			end

			self.itemNum_[idx] = itemInfo[2]
			local type_ = xyd.tables.itemTable:getType(itemInfo[1])
			self.itemID_[idx] = itemInfo[1]
			self.iconItem_ = xyd.getItemIcon({
				isAddUIDragScrollView = true,
				labelNumScale = 1.6,
				noClickSelected = true,
				notShowGetWayBtn = true,
				hideText = true,
				show_has_num = true,
				scale = 0.7,
				uiRoot = itemRoot,
				itemID = itemInfo[1],
				num = itemInfo[2],
				dragScrollView = self.parent_.scrollView_,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	end

	if infoKey == 0 or info.is_awarded and info.is_awarded == 1 then
		self.btnAward_:SetActive(false)
		self.imgAward_.gameObject:SetActive(true)

		self.btnAwardLabel_.text = __("GET2")
	elseif complete_value <= info.value then
		self.btnAward_:SetActive(true)
		self.imgAward_.gameObject:SetActive(false)
		xyd.setEnabled(self.btnAward_, true)
		xyd.setUISpriteAsync(self.btnAwardImg_, nil, "blue_btn_54_54")

		self.btnAwardLabel_.text = __("GET2")
		self.btnAwardLabel_.effectColor = Color.New2(1012112383)
		self.btnAwardLabel_.color = Color.New2(4278124287.0)
	else
		self.btnAward_:SetActive(true)
		self.imgAward_.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.btnAwardImg_, nil, "blue_btn_54_54")
		xyd.setEnabled(self.btnAward_, false)

		self.btnAwardLabel_.text = __("GET2")
		self.btnAwardLabel_.color = Color.New2(4278124287.0)
	end
end

function AchievementItem:getGameObject()
	return self.go
end

function ShrineHurdleNoticeWindow:ctor(name, params)
	ShrineHurdleNoticeWindow.super.ctor(self, name, params)

	self.curNav_ = 1
	self.curRankNav_ = 0
	self.rankDataTriggers = {}
	self.sortStation = false
	self.itemList_ = {
		{},
		{}
	}
	self.groupList_ = {
		{},
		{}
	}
	self.firstClickNav = {}
end

function ShrineHurdleNoticeWindow:getComponent()
	self.groupAction = self.window_.transform:NodeByName("groupAction")
	self.nav = self.groupAction:NodeByName("nav").gameObject
	self.closeBtn_ = self.groupAction:NodeByName("closeBtn").gameObject
	self.filterGroup = self.groupAction:NodeByName("filterGroup").gameObject
	self.btnSort = self.filterGroup:NodeByName("btnSort").gameObject
	self.btnImg = self.btnSort:NodeByName("btnImg").gameObject
	self.btnSortLabel = self.btnSort:ComponentByName("btnLabel", typeof(UILabel))
	self.filterPanel = self.filterGroup:NodeByName("filterPanel").gameObject
	self.groupSort = self.filterPanel:NodeByName("groupSort").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.missionItem = self.window_.transform:NodeByName("missionItem").gameObject
	self.awardItem = self.window_.transform:NodeByName("awardItem").gameObject
	self.rankItem = self.window_.transform:NodeByName("rankItem").gameObject
	self.missionNode = self.groupAction:NodeByName("missionNode").gameObject
	self.missionTimeWords = self.missionNode:ComponentByName("missionTimeWords", typeof(UILabel))
	self.missionTimeText = self.missionNode:ComponentByName("missionTimeText", typeof(UILabel))
	self.missionListScroller = self.missionNode:ComponentByName("missionListScroller", typeof(UIScrollView))
	self.missionListContainer = self.missionListScroller:ComponentByName("missionListContainer", typeof(UIWrapContent))
	self.missionTimeEndWords = self.missionNode:ComponentByName("missionTimeEndWords", typeof(UILabel))
	self.rankNode = self.groupAction:NodeByName("rankNode").gameObject
	self.rankListScroller = self.rankNode:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListContainer = self.rankListScroller:ComponentByName("rankListContainer", typeof(UIWrapContent))
	self.playerRankGroup = self.rankNode:NodeByName("playerRankGroup").gameObject
	self.playerRankContainer = self.playerRankGroup:NodeByName("playerRankContainer").gameObject
	self.noneGroup = self.rankNode:NodeByName("noneGroup").gameObject
	self.labelNoneTips = self.noneGroup:ComponentByName("labelNoneTips", typeof(UILabel))
	self.awardNode = self.groupAction:NodeByName("awardNode").gameObject
	self.upgroup = self.awardNode:NodeByName("upgroup").gameObject
	self.labelRank = self.upgroup:ComponentByName("labelRank", typeof(UILabel))
	self.labelNowAward = self.upgroup:ComponentByName("labelNowAward", typeof(UILabel))
	self.nowAward = self.upgroup:NodeByName("nowAward").gameObject
	self.awardClock = self.awardNode:NodeByName("clock").gameObject
	self.ddl2Text = self.awardNode:ComponentByName("ddl2Text", typeof(UILabel))
	self.awardScroller = self.awardNode:ComponentByName("awardScroller", typeof(UIScrollView))
	self.awardContainer = self.awardScroller:ComponentByName("awardContainer", typeof(UIWrapContent))
	self.achieveNode = self.groupAction:NodeByName("achieveNode").gameObject
	self.achieveListScroller = self.achieveNode:ComponentByName("achieveListScroller", typeof(UIScrollView))
	self.achieveListContainer = self.achieveListScroller:ComponentByName("achieveListContainer", typeof(UIWrapContent))
	self.missionWrapContent = FixedWrapContent.new(self.missionListScroller, self.missionListContainer, self.missionItem, AchievementItem, self)
	self.rankWrapContent = FixedWrapContent.new(self.rankListScroller, self.rankListContainer, self.rankItem, RankItem, self)
	self.awardsWrapContent = FixedWrapContent.new(self.awardScroller, self.awardContainer, self.awardItem, AwardItem, self)
	self.achieveWrapContent = FixedWrapContent.new(self.achieveListScroller, self.achieveListContainer, self.missionItem, AchievementItem, self)

	self.missionWrapContent:hideItems()
	self.rankWrapContent:hideItems()
	self.awardsWrapContent:hideItems()
	self.achieveWrapContent:hideItems()

	self.nodes = {
		self.missionNode,
		self.rankNode,
		self.awardNode,
		self.achieveNode
	}
	local chosen = {
		color = Color.New2(4160223231.0),
		effectColor = Color.New2(1012112383)
	}
	local unchosen = {
		color = Color.New2(4160223231.0),
		effectColor = Color.New2(876106751)
	}
	local colorParams = {
		chosen = chosen,
		unchosen = unchosen
	}
	self.tab = import("app.common.ui.CommonTabBar").new(self.nav, 4, function (index)
		xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
		self:onTouchNav(index)
	end, nil, colorParams)
	local tabText = {
		__("SHRINE_NOTICE_TAB1"),
		__("SHRINE_NOTICE_TAB2"),
		__("SHRINE_NOTICE_TAB3"),
		__("SHRINE_NOTICE_TAB4")
	}

	self.tab:setTexts(tabText)
end

function ShrineHurdleNoticeWindow:initWindow()
	ShrineHurdleNoticeWindow.super.initWindow(self)
	self:getComponent()
	self:register()
	self:layout()
end

function ShrineHurdleNoticeWindow:register()
	ShrineHurdleNoticeWindow.super.register(self)

	UIEventListener.Get(self.btnSort).onClick = handler(self, self.onSortTouch)

	for i = 1, 4 do
		UIEventListener.Get(self.groupSort:ComponentByName("filterCmpt" .. i .. "/filterImg", typeof(UISprite)).gameObject).onClick = function ()
			self:onSortSelectTouch(i - 1)
		end
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.eventProxy_:addEventListener(xyd.event.SHRINE_ACHIEVEMENT_GET_AWARD, handler(self, self.onGetAchieveAward))
	self.eventProxy_:addEventListener(xyd.event.UPDATE_SHRINE_NOTICE, handler(self, self.updatePageByTag))
end

function ShrineHurdleNoticeWindow:updatePageByTag(event)
	local params = event.params

	if params.tag == xyd.ShrineNoticeTag.ACHIEVE then
		self:initAchievements()
	else
		if params.tag == xyd.ShrineNoticeTag.MISSION then
			local leftTime = xyd.models.shrineHurdleModel:getEndTime() - xyd.getServerTime() + 5

			if leftTime > 0 then
				self.missionTimeEndWords:SetActive(false)
				self.missionTimeText:SetActive(true)
				self.missionTimeWords:SetActive(true)

				if not self.missionLabelCount_ then
					self.missionLabelCount_ = import("app.components.CountDown").new(self.missionTimeText)
				end

				self.missionLabelCount_:setInfo({
					duration = leftTime,
					callback = function ()
						if self.curNav_ == xyd.ShrineNoticeTag.MISSION and leftTime > 0 then
							xyd.models.shrine:getMissionData()
						else
							xyd.models.shrine.missions_ = {}
						end
					end
				})
			else
				self.missionTimeEndWords:SetActive(true)
				self.missionTimeText:SetActive(false)
				self.missionTimeWords:SetActive(false)
			end

			self:initMissions()

			return
		end

		if params.tag == xyd.ShrineNoticeTag.RANK then
			local type = params.type or self.curRankNav_

			self:initRank(type)
		elseif params.tag == xyd.ShrineNoticeTag.AWARDS then
			local leftTime = xyd.models.shrineHurdleModel:getEndTime() - xyd.getServerTime() + 5

			if not self.awardLabelCount_ then
				self.awardLabelCount_ = import("app.components.CountDown").new(self.ddl2Text)
			end

			if leftTime <= 0 then
				self.awardLabelCount_:SetActive(false)
				self.awardClock:SetActive(false)
			end

			self.awardLabelCount_:setInfo({
				duration = leftTime,
				callback = function ()
					if self.curNav_ == xyd.ShrineNoticeTag.AWARDS and leftTime > 0 then
						self:getRankData()
						self:initAwards(self.curRankNav_)
					end
				end
			})
			self:initAwards(params.type or self.curRankNav_)
		end
	end
end

function ShrineHurdleNoticeWindow:onGetAchieveAward(event)
	local data = event.params.data

	if data and tostring(data) ~= nil then
		local achieveID = data.old_id
		local awards = xyd.tables.shrineAchievementTable:getAward(achieveID)
		local items = {}

		for _, info in ipairs(awards) do
			local item = {
				item_id = info[1],
				item_num = info[2]
			}

			table.insert(items, item)
		end

		xyd.models.itemFloatModel:pushNewItems(items)
	end

	self:updatePageByTag({
		params = {
			tag = xyd.ShrineNoticeTag.ACHIEVE
		}
	})
end

function ShrineHurdleNoticeWindow:onSortSelectTouch(index)
	if self.curRankNav_ ~= index then
		self.curRankNav_ = index

		self:getRankData()

		if self.curNav_ == xyd.ShrineNoticeTag.RANK then
			self:initRank(self.curRankNav_)
		else
			self:initAwards(self.curRankNav_)
		end
	end

	self:onSortTouch()
end

function ShrineHurdleNoticeWindow:getRankData()
	if self.rankDataTriggers[self.curRankNav_] then
		return
	end

	self.rankDataTriggers[self.curRankNav_] = true

	xyd.models.shrine:getRankListData(self.curRankNav_)
end

function ShrineHurdleNoticeWindow:onSortTouch()
	if self.sortStation then
		self.btnImg.gameObject:SetLocalScale(1, -1, 1)
	else
		self.btnImg.gameObject:SetLocalScale(1, 1, 1)
	end

	if self.curRankNav_ == 0 then
		self.btnSortLabel.text = __("SHRINE_NOTICE_TEXT02")
	else
		self.btnSortLabel.text = xyd.models.shrine:getRankName(self.curRankNav_)
	end

	self:moveGroupSort()
end

function ShrineHurdleNoticeWindow:closeTabs()
	if not self.sortStation then
		self:onSortTouch()
	end
end

function ShrineHurdleNoticeWindow:moveGroupSort()
	local height = self.groupSort:GetComponent(typeof(UIWidget)).height + 20
	local groupSort = self.groupSort.transform

	if self.sortStation then
		self.groupSort:SetActive(true)

		self.groupSort:GetComponent(typeof(UIWidget)).alpha = 0.01
		local sequence = self:getSequence()

		sequence:Append(groupSort:DOScaleY(1, 0.1)):Join(xyd.getTweenAlpha(self.groupSort:GetComponent(typeof(UIWidget)), 1, 0.1))

		self.sortStation = not self.sortStation
	else
		local sequence = self:getSequence()

		sequence:Append(groupSort:DOScaleY(0, 0.1)):Join(xyd.getTweenAlpha(self.groupSort:GetComponent(typeof(UIWidget)), 0.01, 0.1)):AppendCallback(function ()
			self.groupSort:SetActive(false)
		end)

		self.sortStation = not self.sortStation
	end
end

function ShrineHurdleNoticeWindow:initMissions()
	local missions = xyd.models.shrine:getMissions()

	self.missionWrapContent:setInfos(missions, {})
end

function ShrineHurdleNoticeWindow:initAchievements()
	local achievements = xyd.models.shrine:getAchievementList()

	self.achieveWrapContent:setInfos(achievements, {})
end

function ShrineHurdleNoticeWindow:initRank(type)
	local rankList = xyd.models.shrine:getRankList(type)
	local list = rankList.list or {}

	self:updateSelfAwards(type)
	self:initSelfRank(type)
	self.rankWrapContent:setInfos(list, {})
	self.noneGroup:SetActive(#list == 0)
end

function ShrineHurdleNoticeWindow:initAwards(type)
	local list = xyd.models.shrine:getAwardsList(type)

	self:updateSelfAwards(type)
	self:initSelfRank(type)
	self.awardsWrapContent:setInfos(list)
end

function ShrineHurdleNoticeWindow:initSelfRank(type)
	local rankList = xyd.models.shrine:getRankList(type)

	NGUITools.DestroyChildren(self.playerRankContainer.transform)

	if rankList.score > 0 then
		self.playerRankGroup:SetActive(true)
		self.rankItem:SetActive(true)
		self.rankItem:NodeByName("bgImg"):SetActive(false)

		local self_item = {
			isSelf = true,
			score = rankList.score,
			player_name = xyd.models.selfPlayer:getPlayerName(),
			avatar_id = xyd.models.selfPlayer:getAvatarID(),
			avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
			lev = xyd.models.backpack:getLev(),
			server_id = xyd.models.selfPlayer:getServerID(),
			rank = rankList.rank
		}
		local tmp = NGUITools.AddChild(self.playerRankContainer.gameObject, self.rankItem.gameObject)
		local item = RankItem.new(tmp, self, self_item)
	else
		self.playerRankGroup:SetActive(false)
	end
end

function ShrineHurdleNoticeWindow:updateSelfAwards(type)
	local rankList = xyd.models.shrine:getRankList(type)

	NGUITools.DestroyChildren(self.nowAward.transform)

	if rankList.score > 0 then
		local ids = xyd.tables.shrineHurdleRankTable:getIDs()
		local needId = #ids

		for i = 1, #ids do
			needId = i

			if rankList.rank < xyd.tables.shrineHurdleRankTable:getRank(ids[i]) then
				break
			end
		end

		local awards = xyd.tables.shrineHurdleRankTable:getAwards(type, needId)

		for i = 1, #awards do
			local item = awards[i]
			local icon = xyd.getItemIcon({
				isAddUIDragScrollView = true,
				labelNumScale = 1.6,
				notShowGetWayBtn = true,
				hideText = true,
				show_has_num = true,
				scale = 0.7,
				uiRoot = self.nowAward,
				itemID = item[1],
				num = item[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	end

	XYDCo.WaitForFrame(1, function ()
		self.nowAward:GetComponent(typeof(UILayout)):Reposition()
	end, nil)

	local selfRank = tonumber(rankList.rank) or 0

	if selfRank > 0 then
		self.nowAward:SetActive(true)

		self.labelRank.text = tostring(__("SHRINE_NOTICE_TEXT03", tostring(rankList.rank)))
	else
		self.labelRank.text = tostring(__("SHRINE_NOTICE_TEXT03", __("SHRINE_NOTICE_TEXT05")))

		self.nowAward:SetActive(false)
	end
end

function ShrineHurdleNoticeWindow:layout()
	for i = 1, 4 do
		local str = __("SHRINE_NOTICE_TEXT02")

		if i > 1 then
			str = xyd.models.shrine:getRankName(i - 1)
		end

		self.groupSort:ComponentByName("filterCmpt" .. i .. "/labelTips", typeof(UILabel)).text = str
	end

	self.labelNowAward.text = __("SHRINE_NOTICE_TEXT04")
	self.missionTimeEndWords.text = __("SHRINE_NOTICE_TEXT06")
	self.missionTimeWords.text = __("SHRINE_NOTICE_TEXT01")
	self.labelNoneTips.text = __("ACADEMY_ASSESSMEBT_NO_RANK")

	self:initTime()

	if xyd.models.shrine:getRedType() == 1 then
		self.curNav_ = 4
	end

	self:onTouchNav(self.curNav_)
end

function ShrineHurdleNoticeWindow:initTime()
	local clockEffect = xyd.Spine.new(self.awardClock)

	clockEffect:setInfo("fx_ui_shizhong", function ()
		clockEffect:play("texiao1", 0)
	end)
end

function ShrineHurdleNoticeWindow:onTouchNav(index)
	self.curNav_ = index

	self.tab:setTabActive(self.curNav_, true)

	for k, v in ipairs(self.nodes) do
		if self.curNav_ == k then
			v:SetActive(true)
		else
			v:SetActive(false)
		end
	end

	self:closeTabs()
	self.filterGroup:SetActive(false)

	if index == xyd.ShrineNoticeTag.RANK or index == xyd.ShrineNoticeTag.AWARDS then
		self.filterGroup:SetActive(true)
	end

	local needTrigger = true

	if index == xyd.ShrineNoticeTag.MISSION then
		if not next(xyd.models.shrine:getMissions()) or not self.firstClickNav[index] then
			xyd.models.shrine:getMissionData()

			needTrigger = false
		end
	elseif index == xyd.ShrineNoticeTag.RANK then
		self.noneGroup:SetActive(false)
		self:getRankData()
	elseif index == xyd.ShrineNoticeTag.AWARDS then
		self:getRankData()
	elseif index == xyd.ShrineNoticeTag.ACHIEVE and (not next(xyd.models.shrine:getAchievementList()) or not self.firstClickNav[index]) then
		xyd.models.shrine:getAchieveData()

		needTrigger = false
	end

	self.firstClickNav[index] = true

	if needTrigger then
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.UPDATE_SHRINE_NOTICE,
			params = {
				tag = index
			}
		})
	end
end

function ShrineHurdleNoticeWindow:getSortData(shopInfo, shopType)
	local pointArr = xyd.tables.miscTable:split2num("collection_point_level", "value", "|")
	local pointParams = {}
	local list = {}

	for i = 1, #pointArr do
		pointParams[pointArr[i]] = i
		list[i] = {}
	end

	for idx, item in ipairs(shopInfo.items) do
		local tempItem = {
			item = item.item,
			cost = item.cost,
			shopType = shopType,
			buy_times = item.buy_times,
			collection_point = item.collection_point,
			index = idx
		}

		if pointParams[item.collection_point] then
			table.insert(list[pointParams[item.collection_point]], tempItem)
		end
	end

	return list
end

function ShrineHurdleNoticeWindow:buyItemRes(evt)
	xyd.SoundManager.get():playSound(xyd.SoundID.BUY_ITEM)

	local params = evt.data
	local index = params.index
	local items = params.items
	local num = params.num
	local buyItem = items[index]
	local itemData = buyItem.item

	xyd.alertItems({
		{
			item_id = itemData[1],
			item_num = itemData[2] * num
		}
	})
end

return ShrineHurdleNoticeWindow
