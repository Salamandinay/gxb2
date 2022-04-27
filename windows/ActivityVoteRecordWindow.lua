local BaseWindow = import(".BaseWindow")
local ActivityVoteRecordWindow = class("ActivityVoteRecordWindow", BaseWindow)
local ActivityVoteRecordWindowItem = class("ActivityVoteRecordWindowItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local HeroIcon = import("app.components.HeroIcon")

function ActivityVoteRecordWindow:ctor(name, params)
	ActivityVoteRecordWindow.super.ctor(self, name, params)

	self.data_list_ = {}
	self.type_ = 0
	self.title_ = params.title
	self.type_ = params.type
	self.activity_id_ = params.activity_id

	self.eventProxy_:addEventListener(xyd.event.GET_SELF_VOTE_LIST, function (event)
		self.data_list_ = event.data.self_vote_list

		self:updateInfo()
	end)

	local msg = messages_pb.get_self_vote_list_req()
	msg.activity_id = self.activity_id_

	xyd.Backend:get():request(xyd.mid.GET_SELF_VOTE_LIST, msg)
end

function ActivityVoteRecordWindow:getUIComponents()
	local win = self.window_
	self.titleLabel = win:ComponentByName("titleLabel", typeof(UILabel))
	self.scroller = win:ComponentByName("scroller", typeof(UIScrollView))
	self.closeBtn = win:NodeByName("closeBtn").gameObject
	self.partnerNone = win:NodeByName("partnerNone").gameObject
	self.labelNoneTips = self.partnerNone:ComponentByName("labelNoneTips", typeof(UILabel))
	local wrapContent = win:ComponentByName("scroller/rankListContainer", typeof(UIWrapContent))
	local item = win:NodeByName("rank_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, item, ActivityVoteRecordWindowItem, self)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityVoteRecordWindow:initWindow()
	BaseWindow.initWindow(self)
	BaseWindow.register(self)
	self:getUIComponents()

	local title = self.title_

	if title then
		self.titleLabel.text = title
	end
end

function ActivityVoteRecordWindow:updateInfo()
	local collection = self.collection
	local data_list = self.data_list_

	if #data_list == 0 then
		self.partnerNone:SetActive(true)

		self.labelNoneTips.text = __("WEDDING_VOTE_TEXT_10")

		return
	end

	table.sort(data_list, function (a, b)
		return b.vote_num < a.vote_num
	end)

	local length = #data_list
	local result = {}

	for i = 1, length do
		local data = data_list[i]
		local item = {
			vote_num = data.vote_num,
			table_id = data.table_id,
			rank = i
		}

		table.insert(result, item)
	end

	self.wrapContent:setInfos(result)
end

function ActivityVoteRecordWindowItem:ctor(go, parent)
	ActivityVoteRecordWindowItem.super.ctor(self, go)
	self.go:SetActive(false)

	self.parent = parent

	self:setDragScrollView(parent.scroller)

	self.item = nil

	self:getUIComponents()

	self.labelDesText.text = __("WEDDING_VOTE_TEXT_9")
end

function ActivityVoteRecordWindowItem:getUIComponents()
	local go = self.go
	self.bgImg = go:ComponentByName("bgImg", typeof(UISprite))
	local rankGroup = go:NodeByName("rankGroup").gameObject
	self.imgRankIcon = rankGroup:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = rankGroup:ComponentByName("labelRank", typeof(UILabel))
	self.avatarGroup = go:NodeByName("avatarGroup").gameObject
	local levelGroup = go:NodeByName("levelGroup").gameObject
	self.labelLevel = levelGroup:ComponentByName("labelLevel", typeof(UILabel))
	self.labelPlayerName = go:ComponentByName("labelPlayerName", typeof(UILabel))
	self.groupLevel_ = go:NodeByName("groupLevel_").gameObject
	self.labelDesText = self.groupLevel_:ComponentByName("labelDesText", typeof(UILabel))
	self.labelCurrentNum = self.groupLevel_:ComponentByName("labelCurrentNum", typeof(UILabel))
end

function ActivityVoteRecordWindowItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	local data = info
	local rank = data.rank
	local count = data.vote_num
	local id = data.table_id

	if rank <= 3 then
		xyd.setUISpriteAsync(self.imgRankIcon, nil, "rank_icon0" .. tostring(rank))
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = tostring(rank)
	end

	if not self.item then
		self.item = HeroIcon.new(self.avatarGroup)
		self.item.scale = 0.6
	end

	self.item:setInfo({
		noWays = true,
		tableID = id
	})

	self.labelCurrentNum.text = tostring(count)
	self.labelPlayerName.text = xyd.tables.partnerTextTable:getName(id)
end

return ActivityVoteRecordWindow
