local ActivityVoteHistoryWindow = class("ActivityVoteHistoryWindow", import(".BaseWindow"))
local HistoryItem = class("HistoryItem", import("app.components.CopyComponent"))
local PartnerCard = import("app.components.PartnerCard")
local Partner = import("app.models.Partner")

function HistoryItem:ctor(go, id)
	self.id_ = id

	HistoryItem.super.ctor(self, go)
end

function HistoryItem:initUI()
	HistoryItem.super.initUI(self)
	self:getComponent()
	self:layout()
end

function HistoryItem:getComponent()
	local goTrans = self.go.transform
	self.titleLabel_ = goTrans:ComponentByName("titleBg/titleLabel", typeof(UILabel))

	for i = 1, 3 do
		self["partnerName" .. i] = goTrans:ComponentByName("partner" .. i .. "/partnerName", typeof(UILabel))
		self["partnerRank" .. i] = goTrans:ComponentByName("partner" .. i .. "/rankLabel", typeof(UILabel))
		self["partnerCardRoot" .. i] = goTrans:NodeByName("partner" .. i .. "/partnerCardRoot").gameObject
	end
end

function HistoryItem:layout()
	self.titleLabel_.text = __("WEDDING_VOTE_RANK_SESSION", self.id_)

	for i = 1, 3 do
		local partnerTableId = xyd.tables.activityWeddingVote2RankTable:getRankPartner(self.id_, i)
		self["partnerRank" .. i].text = "No." .. i
		self["partnerName" .. i].text = xyd.tables.partnerTable:getName(partnerTableId)
		local card = PartnerCard.new(self["partnerCardRoot" .. i])
		local tmpPartner = Partner.new()

		tmpPartner:populate({
			is_vowed = 1,
			tableID = partnerTableId,
			star = xyd.tables.partnerTable:getStar(partnerTableId)
		})
		card:setInfo(nil, tmpPartner, true)
	end

	if xyd.Global.lang == "fr_fr" then
		self.titleLabel_.fontSize = 24
	end
end

function ActivityVoteHistoryWindow:ctor(name, params)
	ActivityVoteHistoryWindow.super.ctor(self, name, params)
end

function ActivityVoteHistoryWindow:initWindow()
	ActivityVoteHistoryWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
end

function ActivityVoteHistoryWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.timeLabel_ = winTrans:ComponentByName("timeLabel", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.tempItemRoot_ = winTrans:NodeByName("historyItem").gameObject
end

function ActivityVoteHistoryWindow:layout()
	self.titleLabel_.text = __("WEDDING_VOTE_RANK_TITLE")

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	local ids = xyd.tables.activityWeddingVote2RankTable:getIds()

	table.sort(ids, function (a, b)
		return b < a
	end)

	for _, id in ipairs(ids) do
		local itemRoot = NGUITools.AddChild(self.grid_.gameObject, self.tempItemRoot_)

		itemRoot:SetActive(true)
		HistoryItem.new(itemRoot, id)
	end

	self:waitForFrame(1, function ()
		self.grid_:Reposition()
		self.scrollView_:ResetPosition()
	end)
end

return ActivityVoteHistoryWindow
