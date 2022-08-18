local CommonRankWithAwardWindow = class("CommonRankWithAwardWindow", import(".BaseWindow"))
local RankItem = class("RankItem", require("app.components.CopyComponent"))
local AwardItem = class("AwardItem")
local CountDown = import("app.components.CountDown")
local rankTable = xyd.tables.timeCloisterBattleRankTable

function RankItem:ctor(go, parent, params, noPanel)
	self.parent_ = parent
	self.rankData = params
	self.noPanel_ = noPanel

	RankItem.super.ctor(self, go)
	self:getUIComponent()
	self:initUIComponent()
end

function RankItem:getUIComponent()
	local go = self.go
	self.labelName = go:ComponentByName("labelName", typeof(UILabel))
	self.imgRank = go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	local pIcon = go:NodeByName("pIcon").gameObject
	local renderPanel = self.parent_.rankScroll_:GetComponent(typeof(UIPanel))

	if self.noPanel_ then
		renderPanel = nil
	end

	self.pIcon = require("app.components.PlayerIcon").new(pIcon, renderPanel)
	self.lv = go:ComponentByName("lv", typeof(UILabel))
	self.bgImg_ = go:NodeByName("e:Image").gameObject
	self.labelScore = go:ComponentByName("labelScore", typeof(UILabel))
	self.labelScoreTips = go:ComponentByName("labelScoreTips", typeof(UILabel))
	self.labelScoreTips.text = self.parent_.RankDescText or __("WORLD_BOSS_DESC_TEXT")
end

function RankItem:initUIComponent()
	if not self.rankData then
		return
	end

	self.labelName.text = self.rankData.player_name

	if self.rankData.rank and self.rankData.rank <= 3 then
		xyd.setUISprite(self.imgRank, nil, "rank_icon0" .. self.rankData.rank)
		self.imgRank:SetActive(true)
		self.labelRank:SetActive(false)
	else
		if self.rankData.rank then
			self.labelRank.text = tostring(self.rankData.rank)
		end

		self.labelRank:SetActive(true)
		self.imgRank:SetActive(false)
	end

	self.pIcon:setInfo({
		noClick = true,
		avatarID = self.rankData.avatar_id,
		avatar_frame_id = self.rankData.avatar_frame_id
	})

	if self.rankData.hide_bg then
		self.bgImg_:SetActive(false)
	else
		self.bgImg_:SetActive(true)
	end

	self.pIcon:SetLocalScale(0.65, 0.65, 1)

	self.lv.text = tostring(self.rankData.lev)

	if self.rankData.score then
		self.labelScore.text = xyd.getRoughDisplayNumber3(tonumber(self.rankData.score))
	else
		self.labelScore.text = 0
	end
end

function RankItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.rankData = info

	self:initUIComponent()
end

function CommonRankWithAwardWindow:ctor(name, params)
	CommonRankWithAwardWindow.super.ctor(self, name, params)

	self.rankData = params.rankData
	self.awardData = params.awardData
	self.durationTime = params.durationTime
	self.wndType = params.wndType
	self.timeDescText = params.timeDescText
	self.RankDescText = params.RankDescText
end

function CommonRankWithAwardWindow:initWindow()
	CommonRankWithAwardWindow.super.initWindow(self)
	self:getComponent()
	self:initUI()
	self:registerEvent()
end

function CommonRankWithAwardWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.winTitle_ = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.navGroup_ = winTrans:NodeByName("navGroup").gameObject
	self.rankContent_ = winTrans:NodeByName("rankContent").gameObject
	self.rankItemRoot = winTrans:NodeByName("rankContent/item").gameObject
	self.noneGroup_ = winTrans:NodeByName("rankContent/noneGroup").gameObject
	self.labelNoneTips_ = winTrans:ComponentByName("rankContent/noneGroup/labelNoneTips", typeof(UILabel))
	self.rankScroll_ = winTrans:ComponentByName("rankContent/scrollView", typeof(UIScrollView))
	self.rankGrid_ = winTrans:ComponentByName("rankContent/scrollView/grid", typeof(MultiRowWrapContent))
	self.selfRankRoot_ = winTrans:NodeByName("rankContent/groupSelfRankItem").gameObject
	self.rankWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.rankScroll_, self.rankGrid_, self.rankItemRoot, RankItem, self)
	self.awradContent_ = winTrans:NodeByName("awradContent").gameObject
	self.awardScrollView_ = self.awradContent_:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.awardGrid_ = self.awradContent_:ComponentByName("e:Scroller/awardContainer", typeof(UILayout))
	self.labelAward1_ = self.awradContent_:ComponentByName("labelAward1", typeof(UILabel))
	self.labelAward2_ = self.awradContent_:ComponentByName("labelAward2", typeof(UILabel))
	self.labelTimeLeft_ = self.awradContent_:ComponentByName("labelTimeLeft", typeof(UILabel))
	self.effectGroup_ = self.awradContent_:NodeByName("effectGroup").gameObject
	self.awardItemRoot_ = self.awradContent_:NodeByName("item").gameObject
	self.currentRank_ = self.awradContent_:ComponentByName("topItem/currentRank", typeof(UILabel))
	self.itemTitle_ = self.awradContent_:ComponentByName("topItem/itemTitle", typeof(UILabel))
	self.itemGroup_ = self.awradContent_:ComponentByName("topItem/itemGroup", typeof(UILayout))
end

function CommonRankWithAwardWindow:initUI()
	self.winTitle_.text = __("BOOK_RESEARCH_TEXT11")
	self.labelNoneTips_.text = __("BOOK_RESEARCH_TEXT12")

	self:initNav()
	self:setCountDown()
	self:initRankList()
end

function CommonRankWithAwardWindow:registerEvent()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function CommonRankWithAwardWindow:setCountDown()
	local effect = xyd.Spine.new(self.effectGroup_)

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao1", 0)
	end)

	self.labelRefreshTime_ = CountDown.new(self.labelTimeLeft_, {
		duration = self.durationTime
	})
end

function CommonRankWithAwardWindow:initNav()
	self.tab = import("app.common.ui.CommonTabBar").new(self.navGroup_, 2, function (index)
		self:updateLayout(index)
	end)

	self.tab:setTexts({
		__("RANK"),
		__("AWARD3")
	})
end

function CommonRankWithAwardWindow:updateLayout(index)
	self.rankContent_:SetActive(index == 1)
	self.awradContent_:SetActive(index == 2)

	if index == 2 and not self.hasInitAward_ then
		self:initAward()
	end
end

function CommonRankWithAwardWindow:initRankList()
	NGUITools.DestroyChildren(self.selfRankRoot_.transform)

	local rankInfo = self.rankData
	self.rank_data_ = rankInfo.list
	self.self_data_ = {
		rank = rankInfo.self_rank,
		score = rankInfo.self_score,
		num = rankInfo.num,
		isNoSelfRank = rankInfo.isNoSelfRank
	}

	for i = 1, #self.rank_data_ do
		local info = self.rank_data_[i]

		if info.player_id == xyd.Global.playerID then
			self.self_data_ = {
				rank = i,
				score = info.score,
				num = rankInfo.num,
				isNoSelfRank = rankInfo.isNoSelfRank
			}
		end
	end

	if not self.rank_data_ or #self.rank_data_ == 0 then
		self.noneGroup_:SetActive(true)

		return
	else
		self.noneGroup_:SetActive(false)
	end

	self.selfRankRoot_.transform:SetLocalScale(1, 1, 1)

	local params = {
		isSelf = true,
		hide_bg = true,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		lev = xyd.models.backpack:getLev(),
		player_name = xyd.models.selfPlayer:getPlayerName(),
		score = self.self_data_.score,
		rank = self.self_data_.rank,
		num = self.self_data_.num,
		cloister = self.cloister,
		isNoSelfRank = self.self_data_.isNoSelfRank
	}
	local newRoot = NGUITools.AddChild(self.selfRankRoot_, self.rankItemRoot)

	newRoot.transform:SetLocalPosition(0, 49, 0)

	local selfRankItem = RankItem.new(newRoot, self, params, true)

	selfRankItem:setDepth(15)

	self.rankListInfo_ = {}

	for i = 1, #self.rank_data_ do
		local data = self.rank_data_[i]
		local params = {
			avatar_id = data.avatar_id,
			avatar_frame_id = data.avatar_frame_id,
			lev = data.lev,
			player_name = data.player_name,
			score = data.score,
			rank = i,
			num = self.self_data_.num
		}

		table.insert(self.rankListInfo_, params)
	end

	self.rankWrap_:setInfos(self.rankListInfo_, {})
end

function CommonRankWithAwardWindow:initAward()
	self.hasInitAward_ = true
	self.labelAward2_.text = self.timeDescText or tostring(__("GUILD_BOSS_TEXT03"))

	self:initAwardList()
	self:initSelfAward()
end

function CommonRankWithAwardWindow:initAwardList()
	local list = self.awardData.list

	for i = 1, #list do
		local data = list[i]
		local go = NGUITools.AddChild(self.awardGrid_.gameObject, self.awardItemRoot_)
		local awardItem = AwardItem.new(go, {
			awardsData = data.items,
			rank = data.rank,
			id = i,
			titleText = data.titleText
		}, self)
	end

	self.awardGrid_:Reposition()
	self.awardScrollView_:ResetPosition()
end

function CommonRankWithAwardWindow:initSelfAward()
	local selfAwardData = self.awardData.self_data
	self.itemTitle_.text = __("NOW_AWARD")
	local rankText = selfAwardData.rankText

	if selfAwardData.isNoSelfRank then
		rankText = ""
	end

	self.currentRank_.text = __("NOW_RANK") .. " : " .. rankText

	if selfAwardData.isNoSelfRank then
		return
	end

	local awardData = selfAwardData.awards

	for _, info in ipairs(awardData) do
		local params = {
			labelNumScale = 1.6,
			hideText = true,
			itemID = info[1],
			num = info[2],
			uiRoot = self.itemGroup_.gameObject
		}
		local itemIcon = xyd.getItemIcon(params)

		itemIcon:SetLocalScale(0.72, 0.72, 1)
	end

	self.itemGroup_:Reposition()
end

function AwardItem:ctor(go, params, parent)
	self.parent_ = parent
	self.go = go
	self.awardsData = params.awardsData
	self.rank = params.rank
	self.id = params.id
	self.titleText = params.titleText

	self:getUIComponent()
	self:initUIComponent()
end

function AwardItem:getUIComponent()
	local go = self.go
	self.itemTitle = go:ComponentByName("itemTitle", typeof(UILabel))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.rankImg = go:ComponentByName("rankImg", typeof(UISprite))
end

function AwardItem:initUIComponent()
	if self.rank <= 3 then
		xyd.setUISprite(self.rankImg, nil, "rank_icon0" .. self.rank)
		self.rankImg:SetActive(true)
		self.itemTitle:SetActive(false)
	else
		self.rankImg:SetActive(false)
		self.itemTitle:SetActive(true)

		self.itemTitle.text = self.titleText
	end

	for i = 1, #self.awardsData do
		local itemData = self.awardsData[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			uiRoot = self.itemGroup,
			itemID = itemId,
			dragScrollView = self.parent_.awardScrollView_,
			num = itemNum
		})

		itemIcon:SetLocalScale(0.72, 0.72, 1)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

return CommonRankWithAwardWindow
