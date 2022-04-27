local ActivityVoteRankWindow = class("ActivityVoteRankWindow", import(".BaseWindow"))
local ActivityVoteRankWindowItem = class("ActivityVoteRankWindowItem", import("app.components.CopyComponent"))
local CommonTabBar = import("app.common.ui.CommonTabBar")
local HeroIcon = import("app.components.HeroIcon")

function ActivityVoteRankWindow:ctor(name, params)
	ActivityVoteRankWindow.super.ctor(self, name, params)

	self.rank_list_ = params.rank_list
	self.rankList_ = {
		{},
		{}
	}

	for i = 1, 2 do
		for _, data in ipairs(self.rank_list_[i]) do
			table.insert(self.rankList_[i], {
				table_id = data.table_id,
				vote_num = data.vote_num
			})
		end
	end

	self.cur_select_ = 1
end

function ActivityVoteRankWindow:initWindow()
	ActivityVoteRankWindow.super.initWindow(self)
	self:getComponent()
	self:layout()
	self:initTopGroup()
end

function ActivityVoteRankWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.labelWinTitle_ = winTrans:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.navGroup_ = winTrans:NodeByName("navGroup").gameObject
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	local itemRoot = winTrans:NodeByName("ActivityVoteRankWindowItem").gameObject

	itemRoot:SetActive(false)

	self.wrapContent_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, itemRoot, ActivityVoteRankWindowItem, self)
	self.groupNone_ = winTrans:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = winTrans:ComponentByName("groupNone_/labelNoneTips", typeof(UILabel))

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityVoteRankWindow:initTopGroup()
	self.tab_ = CommonTabBar.new(self.navGroup_, 2, function (index)
		self.cur_select_ = index

		self:onTouch(index)
	end)
	local tableLabels = {
		__("ACTIVITY_VOTE_NEW_NAV_TEXT1"),
		__("ACTIVITY_VOTE_NEW_NAV_TEXT2")
	}

	self.tab_:setTexts(tableLabels)
end

function ActivityVoteRankWindow:layout()
	for i = 1, 2 do
		if self.rankList_[i] and #self.rankList_[i] >= 1 then
			table.sort(self.rankList_[i], function (a, b)
				return tonumber(b.vote_num) < tonumber(a.vote_num)
			end)

			for j = 1, #self.rankList_[i] do
				self.rankList_[i][j].rank = j
			end
		end
	end

	self.labelWinTitle_.text = __("ACTIVITY_VOTE_RANK_WINDOW")
	self.labelNoneTips_.text = __("WEDDING_VOTE_TEXT_10")

	self:refreshData()
end

function ActivityVoteRankWindow:refreshData()
	local data = self.rankList_[self.cur_select_]

	self.wrapContent_:setInfos(data, {})
end

function ActivityVoteRankWindow:onTouch()
	self:refreshData()

	if self.rankList_[self.cur_select_] and #self.rankList_[self.cur_select_] <= 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end
end

function ActivityVoteRankWindowItem:ctor(go, parent)
	self.parent_ = parent

	ActivityVoteRankWindowItem.super.ctor(self, go)
end

function ActivityVoteRankWindowItem:initUI()
	ActivityVoteRankWindowItem.super.initUI(self)
	self:getComponent()

	self.labelDesText_.text = __("WEDDING_VOTE_TEXT_9")
end

function ActivityVoteRankWindowItem:getComponent()
	local goTrans = self.go.transform
	self.imgRankIcon_ = goTrans:ComponentByName("rankGroup/imgRankIcon", typeof(UISprite))
	self.labelRank_ = goTrans:ComponentByName("rankGroup/labelRank", typeof(UILabel))
	self.avatarGroup_ = goTrans:NodeByName("avatarGroup").gameObject
	self.labelGroup_ = goTrans:NodeByName("labelGroup")

	if xyd.Global.lang == "zh_tw" or xyd.Global.lang == "ja_jp" then
		self.labelGroup_:X(240)
	else
		self.labelGroup_:X(210)
	end

	self.labelDesText_ = goTrans:ComponentByName("labelGroup/labelDesText", typeof(UILabel))
	self.labelCurrentNum_ = goTrans:ComponentByName("labelGroup/labelCurrentNum", typeof(UILabel))
	self.labelPlayerName_ = goTrans:ComponentByName("labelPlayerName", typeof(UILabel))
end

function ActivityVoteRankWindowItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info
	local rank = info.rank
	local count = info.vote_num
	local id = info.table_id

	if rank <= 3 then
		xyd.setUISpriteAsync(self.imgRankIcon_, nil, "rank_icon0" .. rank)
		self.imgRankIcon_.gameObject:SetActive(true)
		self.labelRank_.gameObject:SetActive(false)
	else
		self.imgRankIcon_.gameObject:SetActive(false)
		self.labelRank_.gameObject:SetActive(true)

		self.labelRank_.text = rank
	end

	if not self.item_ then
		self.item_ = HeroIcon.new(self.avatarGroup_)
	end

	self.item_:setInfo({
		noWays = true,
		tableID = id
	})
	self.item_:setScale(0.6)

	self.labelCurrentNum_.text = count
	self.labelPlayerName_.text = xyd.tables.partnerTextTable:getName(id)
end

return ActivityVoteRankWindow
