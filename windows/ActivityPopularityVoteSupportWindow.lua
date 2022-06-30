local BaseWindow = import(".BaseWindow")
local ActivityPopularityVoteSupportWindow = class("ActivityPopularityVoteSupportWindow", BaseWindow)
local CardItem = class("CardItem")

function ActivityPopularityVoteSupportWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.filterIndex = 0
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)
end

function ActivityPopularityVoteSupportWindow:initWindow()
	self:getUIComponent()
	ActivityPopularityVoteSupportWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityPopularityVoteSupportWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("wrapContent", typeof(MultiRowWrapContent))
	local cardItem = self.scrollView:NodeByName("cardItem").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView, wrapContent, cardItem, CardItem, self)
	local filterGroup = groupAction:NodeByName("filterGroup").gameObject

	for i = 1, 7 do
		self["filter" .. i] = filterGroup:NodeByName("group" .. i).gameObject
		self["filterChosen" .. i] = self["filter" .. i]:NodeByName("chosen").gameObject
	end

	self.btnHelp = groupAction:NodeByName("btnHelp").gameObject
	self.groupNone = groupAction:NodeByName("groupNone").gameObject
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
end

function ActivityPopularityVoteSupportWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_POPULARITY_VOTE_TEXT05")
	self.labelNoneTips.text = __("NO_PARTNER")

	for i = 1, 7 do
		self["filterChosen" .. i]:SetActive(i == self.filterIndex)
	end

	self:updateData()
end

function ActivityPopularityVoteSupportWindow:updateData()
	self.infos = {}
	self.tempInfos = {}
	local curPeriod = self.activityData:getCurPeriod()

	dump(curPeriod)

	for i = 1, curPeriod do
		dump(i)
		dump(self.activityData.history)

		for _, list in ipairs(self.activityData.history[i]) do
			for _, item in ipairs(list) do
				local tableID = tonumber(item.table_id)

				if self.filterIndex == 0 or self.filterIndex == xyd.tables.partnerTable:getGroup(tableID) then
					if not self.tempInfos[tableID] then
						self.tempInfos[tableID] = {
							score = 0,
							maxPeriod = 1,
							table_id = tableID
						}
					end

					self.tempInfos[tableID].maxPeriod = i
					self.tempInfos[tableID].score = item.score + self.tempInfos[tableID].score
				end
			end
		end
	end

	for tableID, value in pairs(self.tempInfos) do
		for _, item in pairs(self.activityData.history[curPeriod][1]) do
			if tableID == tonumber(item.table_id) then
				value.isPlayingGame = true
			end
		end

		table.insert(self.infos, value)
	end

	table.sort(self.infos, function (a, b)
		if a.isPlayingGame ~= b.isPlayingGame then
			return a.isPlayingGame
		elseif a.score ~= b.score then
			return b.score < a.score
		else
			return b.table_id < a.table_id
		end
	end)

	if #self.infos <= 0 then
		self.groupNone:SetActive(true)
	else
		self.groupNone:SetActive(false)
	end

	dump(self.infos)
	self.multiWrap_:setInfos(self.infos, {})
	self.multiWrap_:resetPosition()
	self.scrollView:ResetPosition()
end

function ActivityPopularityVoteSupportWindow:onClickFilter(filterIndex)
	if self.filterIndex == filterIndex then
		self.filterIndex = 0
	else
		self.filterIndex = filterIndex
	end

	for i = 1, 7 do
		self["filterChosen" .. i]:SetActive(i == self.filterIndex)
	end

	self:updateData()
end

function ActivityPopularityVoteSupportWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	for i = 1, 7 do
		UIEventListener.Get(self["filter" .. i]).onClick = function ()
			self:onClickFilter(i)
		end
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_POPULARITY_VOTE_TEXT01"
		})
	end
end

function ActivityPopularityVoteSupportWindow:willClose()
	BaseWindow.willClose(self)
end

function CardItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:getUIComponent()
end

function CardItem:getUIComponent()
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.partnerImg = self.go:ComponentByName("partnerImg", typeof(UISprite))
	self.labelName = self.go:ComponentByName("labelName", typeof(UILabel))
	self.labelVote = self.go:ComponentByName("labelVote", typeof(UILabel))
	self.labelVoteNum = self.go:ComponentByName("labelVoteNum", typeof(UILabel))

	UIEventListener.Get(self.go).onClick = function ()
		xyd.openWindow("activity_popularity_vote_support_rank_window", {
			tableID = self.data.table_id,
			score = self.data.score,
			maxPeriod = self.data.maxPeriod
		})
	end
end

function CardItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info
	self.tableID = info.table_id

	self.go:SetActive(true)

	self.labelName.text = xyd.tables.partnerTable:getName(self.tableID)
	self.labelVote.text = __("ACTIVITY_POPULARITY_VOTE_TEXT08")
	self.labelVoteNum.text = info.score

	xyd.setUISpriteAsync(self.partnerImg, nil, xyd.tables.partnerPictureTable:getPartnerCard(self.tableID))
end

function CardItem:getGameObject()
	return self.go
end

return ActivityPopularityVoteSupportWindow
