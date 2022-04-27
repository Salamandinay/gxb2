local ActivityVote2 = class("ActivityVote2", import(".ActivityContent"))
local ActivityVoteItem2 = class("ActivityVoteItem2", import("app.common.ui.FixedMultiWrapContentItem"))
local PartnerFilter = class("PartnerFilter", import("app.components.PartnerFilter"))
local SortType = {
	VOTE_COUNT = 1,
	DEFAULT_SORT = 0
}
local vote2ListTable = xyd.tables.activityWeddingVote2ListTable

function ActivityVote2:ctor(parentGO, params)
	self.table_id_2_vote_count_ = {}
	self.table_id_2_vote_rank_ = {}
	self.defaultList_ = {}
	self.cur_group_ = 0
	self.cur_sort_type_ = SortType.DEFAULT_SORT
	self.activity_vote_story_time = "activity_vote_story_time"

	ActivityVote2.super.ctor(self, parentGO, params)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_VOTE2, function ()
		xyd.db.misc:setValue({
			key = "activity_vote_2_red",
			value = xyd.getServerTime()
		})
	end)
end

function ActivityVote2:getPrefabPath()
	return "Prefabs/Windows/activity/activity_vote2_content"
end

function ActivityVote2:resizeToParent()
	ActivityVote2.super.resizeToParent(self)
	self:resizePosY(self.resultGroup_, -50, -50)
end

function ActivityVote2:initUI()
	self:getUIComponent()
	ActivityVote2.super.initUI(self)

	if self:checkPlayStory() then
		xyd.WindowManager.get():openWindow("story_window", {
			story_id = xyd.tables.activityTable:getPlotId(self.id),
			story_type = xyd.StoryType.ACTIVITY
		})
	end

	self.status_ = self:getCurStatus()
	self.ret_time_ = self:getRetTime(self.status_)

	self:updatePos()
	self:buildCollection()
	self:euiComplete()
end

function ActivityVote2:updatePos()
	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	if p_height >= 1047 then
		p_height = 1047
	end

	self.textImg2_.transform:Y(-6 - (p_height - 869) * 25 / 178)
	self.detailBtn_.transform:Y(-41 + (p_height - 869) * 4 / 178)
	self.partnerGroup_:Y(-86 - (p_height - 869) * 56 / 178)
	self.partnerNameGroup_:Y(-718 - (p_height - 869) * 100 / 178)

	self.scrollView_.transform.localPosition = Vector3(0, -75 * (p_height - 869) / 178, 0)
end

function ActivityVote2:getUIComponent()
	local goTrans = self.go.transform
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.rankBtn_ = goTrans:NodeByName("rankBtn").gameObject
	self.recordBtn_ = goTrans:NodeByName("recordBtn").gameObject
	self.awardBtn_ = goTrans:NodeByName("awardBtn").gameObject
	self.textImg_ = goTrans:ComponentByName("actionGroup/textImg", typeof(UISprite))
	local actionGroupTrans = goTrans:NodeByName("actionGroup")
	self.actionGroup_ = actionGroupTrans.gameObject
	self.filterGroup_ = actionGroupTrans:NodeByName("filterGroup").gameObject
	self.countLabel_ = actionGroupTrans:ComponentByName("countLabel", typeof(UILabel))
	local itemRoot = actionGroupTrans:NodeByName("activity_vote2_item").gameObject

	itemRoot:SetActive(false)

	self.scrollView_ = actionGroupTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = actionGroupTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.groupSort_ = actionGroupTrans:NodeByName("groupSort").gameObject
	self.sortBtn_ = actionGroupTrans:NodeByName("groupSort/sortBtn").gameObject
	self.sortBtnLabel_ = actionGroupTrans:ComponentByName("groupSort/sortBtn/label", typeof(UILabel))
	self.sortUpArr_ = actionGroupTrans:NodeByName("groupSort/sortBtn/sortUpArr")
	self.sortPop_ = actionGroupTrans:NodeByName("groupSort/sortPop").gameObject
	self.countSort_ = actionGroupTrans:NodeByName("groupSort/sortPop/countSort").gameObject
	self.countSort_chosenImg = actionGroupTrans:NodeByName("groupSort/sortPop/countSort/chosenImg").gameObject
	self.countSort_label = actionGroupTrans:ComponentByName("groupSort/sortPop/countSort/label", typeof(UILabel))
	self.defaultSort_ = actionGroupTrans:NodeByName("groupSort/sortPop/defaultSort").gameObject
	self.defaultSort_chosenImg = actionGroupTrans:NodeByName("groupSort/sortPop/defaultSort/chosenImg").gameObject
	self.defaultSort_label = actionGroupTrans:ComponentByName("groupSort/sortPop/defaultSort/label", typeof(UILabel))
	self.missionBtn_ = actionGroupTrans:NodeByName("missionBtn").gameObject
	self.missionBtnLabel_ = actionGroupTrans:ComponentByName("missionBtn/label", typeof(UILabel))
	self.missionBtnRedPoint_ = actionGroupTrans:NodeByName("missionBtn/redPoint").gameObject
	self.endLabel_ = actionGroupTrans:ComponentByName("topGroup/endLabel", typeof(UILabel))
	self.timeLabel_ = actionGroupTrans:ComponentByName("topGroup/timeLabel", typeof(UILabel))
	self.historyBtn_ = actionGroupTrans:NodeByName("historyBtn").gameObject
	local resultGroupTrans = goTrans:NodeByName("resultGroup")
	self.resultGroup_ = resultGroupTrans.gameObject
	self.textImg2_ = resultGroupTrans:ComponentByName("bgPanel/textImg2", typeof(UISprite))
	self.detailBtn_ = resultGroupTrans:NodeByName("detailBtn").gameObject
	self.partnerGroup_ = resultGroupTrans:NodeByName("partnerGroup")
	self.partnerNameGroup_ = resultGroupTrans:NodeByName("partnerNameGroup")

	for i = 1, 3 do
		self["partnerImg" .. i] = resultGroupTrans:ComponentByName("partnerGroup/partnerPanel" .. i .. "/partnerImg", typeof(UITexture))
		self["partnerName" .. i] = resultGroupTrans:ComponentByName("partnerNameGroup/namePanel/name" .. i .. "/label", typeof(UILabel))
		self["partnerVote" .. i] = resultGroupTrans:ComponentByName("partnerNameGroup/namePanel/name" .. i .. "/voteNum", typeof(UILabel))
	end

	self.multiWrapActivity_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, itemRoot, ActivityVoteItem2, self)

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.fontSize = 19
		self.timeLabel_.fontSize = 19
	elseif xyd.Global.lang == "de_de" then
		self.endLabel_.fontSize = 18
		self.timeLabel_.fontSize = 18
	end
end

function ActivityVote2:checkPlayStory()
	return false
end

function ActivityVote2:changeBtns(isShow)
	self.helpBtn_:SetActive(isShow)
	self.rankBtn_:SetActive(isShow)
	self.recordBtn_:SetActive(isShow)
	self.awardBtn_:SetActive(isShow)
	self.historyBtn_:SetActive(isShow)
end

function ActivityVote2:getCurStatus()
	local timestamp = xyd.tables.miscTable:split2num("wedding_vote2_time_interval", "value", "|")
	local start_time = self.activityData:startTime()
	local cur_time = xyd.getServerTime() - start_time

	for i = 1, #timestamp do
		local stamp = timestamp[i] * 24 * 60 * 60

		if cur_time < stamp then
			return i - 1
		end
	end

	return #timestamp
end

function ActivityVote2:getRetTime(status)
	local timestamp = xyd.tables.miscTable:split2num("wedding_vote2_time_interval", "value", "|")
	local nextTime = nil

	if status == #timestamp then
		nextTime = timestamp[status] * 24 * 60 * 60
	else
		nextTime = timestamp[status + 1] * 24 * 60 * 60
	end

	local stamp = self.activityData:startTime() + nextTime - xyd.getServerTime()

	return stamp
end

function ActivityVote2:buildCount()
	local status = self.status_

	if self.status_ > 2 then
		status = 2
	end

	local rank_list = self.activityData.detail.rank_list[status + 1]
	local table_id_2_vote_count_ = self.table_id_2_vote_count_

	for i = 1, #rank_list do
		local data = rank_list[i]
		table_id_2_vote_count_[tonumber(data.table_id)] = tonumber(data.vote_num)
	end
end

function ActivityVote2:buildRank()
	local status = self.status_

	if self.status_ > 2 then
		status = 2
	end

	local rank_list = self.activityData.detail.rank_list[status + 1]

	for i = 1, #rank_list do
		local data = rank_list[i]
		local count = self:getVoteCount(tonumber(data.table_id))
		local rank = 1

		for j = 1, #rank_list do
			if count < self:getVoteCount(tonumber(rank_list[j].table_id)) then
				rank = rank + 1
			end
		end

		self.table_id_2_vote_rank_[tonumber(data.table_id)] = rank
	end
end

function ActivityVote2:getIdsByStatus(status)
	status = math.min(status, 2)

	if status == 0 or status == 1 then
		return vote2ListTable:getIdsByGroup(status + 1)
	else
		return self.activityData.detail.rank_list[status + 1] or {}
	end
end

function ActivityVote2:buildCollection()
	self:buildCount()
	self:buildRank()

	self.idList_ = {}
	local ids = self:getIdsByStatus(self.status_)
	local info_list = {
		[0] = {}
	}

	for i = 1, #ids do
		local id = nil
		id = (type(ids[i]) ~= "number" or ids[i]) and (ids[i].table_id or ids[i])
		local data = {
			id = id,
			count_fun = function ()
				return self:getVoteCount(tonumber(id))
			end,
			activity = self,
			status = self.status_,
			getRank = function ()
				return self:getRank(tonumber(id))
			end
		}
		local group = xyd.tables.partnerTable:getGroup(id)

		if not info_list[group] then
			info_list[group] = {}
		end

		table.insert(info_list[group], data)
		table.insert(info_list[0], data)
	end

	self.itemArray = info_list
end

function ActivityVote2:randSortIds(list)
	local playerId = xyd.models.selfPlayer.playerID_
	local len = #list
	local tempList = {}

	for i = 1, len do
		local seed = tonumber(playerId) + i * 107
		seed = tonumber(string.reverse(tostring(seed)))

		math.randomseed(seed)

		local index = math.ceil(math.random() * len)
		local temp = list[index]
		list[index] = list[i]
		list[i] = temp
	end

	for i = 1, #list do
		tempList[i] = list[i]
	end

	return tempList
end

function ActivityVote2:initResGroup()
	UIEventListener.Get(self.detailBtn_).onClick = function ()
		self.resultGroup_:SetActive(false)
		self.actionGroup_:SetActive(true)
		self:changeBtns(true)
		self:refreshData()
	end

	self.resultGroup_:SetActive(true)
	xyd.setUISpriteAsync(self.textImg2_, nil, "activity_vote_text01_" .. xyd.Global.lang, nil, , true)

	local list = self.activityData.detail.rank_list[3]

	for i = 1, 3 do
		local partnerImg = self["partnerImg" .. i]
		local nameLbael = self["partnerName" .. i]
		local countLabel = self["partnerVote" .. i]

		if list[i] then
			countLabel.text = __("ACTIVITY_VOTE_COUNT", self:getVoteCount(tonumber(list[i].table_id)))
			nameLbael.text = xyd.tables.partnerTable:getName(tonumber(list[i].table_id))
			local pos = xyd.tables.activityWeddingVote2ListTable:getShowPos(tonumber(list[i].table_id))
			local offest = xyd.tables.activityWeddingVote2ListTable:getShowOffset(tonumber(list[i].table_id))
			local scale = xyd.tables.activityWeddingVote2ListTable:getScale(tonumber(list[i].table_id))

			partnerImg.transform:SetLocalScale(0.64 * scale, 0.64 * scale, 0.64 * scale)
			partnerImg.transform:SetLocalPosition(offest[1], offest[2], 0)

			local path = xyd.tables.partnerPictureTable:getPartnerPic(tonumber(list[i].table_id))

			xyd.setUITextureByName(partnerImg, path, true)
		end
	end
end

function ActivityVote2:getVoteCount(id)
	return self.table_id_2_vote_count_[id] or 0
end

function ActivityVote2:getRank(id)
	return self.table_id_2_vote_rank_[id] or 999
end

function ActivityVote2:updateCount(table_id, num)
	local list = self.activityData.detail.rank_list

	for j = 1, 3 do
		local flag = false

		for i = 1, #list do
			if list[j][i].table_id == table_id then
				self.activityData.detail.rank_list[j][i].vote_num = self.activityData.detail.rank_list[j][i].vote_num + tonumber(num)
				flag = true
			end

			if not flag then
				table.insert(self.activityData.detail.rank_list, {
					{
						table_id = table_id,
						vote_num = num
					}
				})
			end
		end
	end

	self.table_id_2_vote_count_[tonumber(table_id)] = tonumber(self.table_id_2_vote_count_[table_id]) + tonumber(num)

	self:buildRank()
end

function ActivityVote2:euiComplete()
	if xyd.Global.lang == "fr_fr" then
		self.missionBtnLabel_.fontSize = 22
	end

	if self.status_ == 3 then
		self:onTouchSortType(SortType.DEFAULT_SORT, false)
	else
		self:onTouchSortType(self.cur_sort_type_, false)
	end

	if self.status_ == 4 then
		self:initResGroup()
		self.countLabel_:SetActive(false)
		self.actionGroup_:SetActive(false)
		self:changeBtns(false)
		self.resultGroup_:SetActive(true)

		self.endLabel_.text = __("RET_TIME_TEXT")
	elseif self.status_ == 3 then
		self.countLabel_:SetActive(false)
		self.actionGroup_:SetActive(true)
		self:changeBtns(true)
		self.resultGroup_:SetActive(false)

		self.endLabel_.text = __("ACTIVITY_VOTE_END_TEXT")
	else
		self.actionGroup_:SetActive(true)
		self:changeBtns(true)
		self.resultGroup_:SetActive(false)

		if self.status_ == 0 then
			self.endLabel_.text = __("WEDDING_VOTE_TEXT_20")
		elseif self.status_ == 1 then
			self.endLabel_.text = __("WEDDING_VOTE_TEXT_21")
		else
			self.endLabel_.text = __("WEDDING_VOTE_TEXT_22")
		end
	end

	if self.status_ >= 2 then
		self.groupSort_:SetActive(false)
		self.filterGroup_:SetActive(false)
		self.scrollView_:GetComponent(typeof(UIPanel)):SetTopAnchor(self.go.gameObject, 1, -240 + 80 * self.scale_num_)
		self.scrollView_:GetComponent(typeof(UIPanel)):SetBottomAnchor(self.go.gameObject, 0, 80)
	end

	if self.ret_time_ and self.ret_time_ > 0 then
		local params = {
			duration = self.ret_time_
		}

		if not self.tiemCount_ then
			self.tiemCount_ = import("app.components.CountDown").new(self.timeLabel_, params)
		else
			self.tiemCount_:setInfo(params)
		end
	end

	self.sortBtnLabel_.text = __("SORT")
	self.defaultSort_label.text = __("WEDDING_VOTE_TEXT_14")
	self.countSort_label.text = __("WEDDING_VOTE_TEXT_2")

	if self.status_ ~= 4 then
		self.missionBtnLabel_.text = __("WEDDING_VOTE_TEXT_3")
	else
		self.missionBtnLabel_.text = __("ACTIVITY_VOTE_RETURN")
	end

	self.countLabel_.text = __("WEDDING_VOTE_TEXT_15", xyd.models.backpack:getItemNumByID(self:getItemType()))

	xyd.setUISpriteAsync(self.textImg_, nil, "activity_vote_text01_" .. xyd.Global.lang, nil, , true)
	self:updateRedPoint()
	self.sortPop_:SetActive(false)
	self:register()
end

function ActivityVote2:updateRedPoint()
	local missionRedStatus = false
	local detail = self.activityData.detail
	local mission_count = detail.mission_count
	local mission_awarded = detail.mission_awarded

	for i = 1, #mission_count do
		if xyd.tables.activityWeddingVote2MissionTable:getComplete(i) <= mission_count[i] and (not mission_awarded[i] or mission_awarded[i] == 0) then
			missionRedStatus = true

			break
		end
	end

	if self.status_ ~= 0 and self.status_ ~= 1 and self.status_ ~= 2 then
		missionRedStatus = false
	end

	self.missionBtnRedPoint_:SetActive(missionRedStatus)
end

function ActivityVote2:updateInfo()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_VOTE2)
end

function ActivityVote2:register()
	self.eventProxyInner_:addEventListener(xyd.event.WEDDING_DRESS_VOTE, handler(self, self.onDressVote))
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, self.updateRedPoint, self)
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.countLabel_.text = __("WEDDING_VOTE_TEXT_15", xyd.models.backpack:getItemNumByID(self:getItemType()))

		self:updateRedPoint()
	end)
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function ()
		self:updateRedPoint()
	end)
	self.eventProxyInner_:addEventListener(xyd.event.RED_POINT, handler(self, self.onRedPoint))
	self.eventProxyInner_:addEventListener(xyd.event.RED_POINT, handler(self, self.onRedPoint))

	UIEventListener.Get(self.sortBtn_).onClick = handler(self, self.onClickSortBtn)

	UIEventListener.Get(self.missionBtn_).onClick = function ()
		if self.status_ ~= 4 then
			self:onTouchMissionBtn()
		else
			self.resultGroup_:SetActive(true)
			self.actionGroup_:SetActive(false)
			self:changeBtns(false)
		end
	end

	UIEventListener.Get(self.recordBtn_).onClick = handler(self, self.onTouchRecord)

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_vote_award_window", {
			item_id = self:getItemType(),
			table = xyd.tables.activityWeddingVote2AwardTable,
			vote_awarded = self.activityData.detail.vote_awarded
		})
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			isEast = false,
			key = "WEDDING_VOTE_TEXT_13"
		})
	end

	UIEventListener.Get(self.historyBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_vote_history_window")
	end

	UIEventListener.Get(self.rankBtn_).onClick = function ()
		local list = self.activityData.detail.rank_list

		if not list or tostring(list) == "" then
			list = {}
		end

		xyd.WindowManager.get():openWindow("activity_vote_rank_window", {
			rank_list = list
		})
	end

	UIEventListener.Get(self.defaultSort_).onClick = function ()
		xyd.db.misc:setValue({
			key = "activity_vote_sort_type",
			value = SortType.DEFAULT_SORT
		})
		self:onTouchSortType(SortType.DEFAULT_SORT, true)
	end

	UIEventListener.Get(self.countSort_).onClick = function ()
		xyd.db.misc:setValue({
			key = "activity_vote_sort_type",
			value = SortType.VOTE_COUNT
		})
		self:onTouchSortType(SortType.VOTE_COUNT, true)
	end

	local function filter_callback(group)
		return self:updateDataProvider(group)
	end

	local PartnerPartlyFilter = PartnerFilter:getPartnerPartlyFilter()
	self.fliter = PartnerPartlyFilter.new(self.filterGroup_, {
		gap = 16,
		callback = filter_callback
	})
end

function ActivityVote2:refreshData()
	local data = self.itemArray[self.cur_group_]

	if not self.initOver then
		self.initOver = true

		self:waitForTime(0.06666666666666667, function ()
			self.multiWrapActivity_:setInfos(data, {})
		end)
	else
		self.multiWrapActivity_:setInfos(data, {})
	end
end

function ActivityVote2:onTouchRecord()
	xyd.WindowManager.get():openWindow("activity_vote_record_window", {
		title = __("WEDDING_VOTE_TEXT_8"),
		activity_id = self.activityData.id
	})
end

function ActivityVote2:onTouchMissionBtn()
	if self.status_ ~= 0 and self.status_ ~= 1 and self.status_ ~= 2 then
		xyd.showToast(__("WEDDING_VOTE_TEXT_19"))

		return
	end

	xyd.WindowManager.get():openWindow("activity_vote_mission_window", {
		activity_data = self.activityData,
		table = xyd.tables.activityWeddingVote2MissionTable,
		activityContent = self
	})
end

function ActivityVote2:onClickSortBtn()
	if not self.sortBtnState_ then
		self.sortBtnState_ = 1
	end

	if not self.doMoveSortPop_ then
		self:moveSortPop()

		self.sortBtnState_ = -self.sortBtnState_
		self.sortUpArr_.localScale = Vector3(1, self.sortBtnState_, 1)
	end
end

function ActivityVote2:moveSortPop()
	self.doMoveSortPop_ = true
	local height = 126
	local countBox = self.countSort_:GetComponent(typeof(UnityEngine.BoxCollider))
	local defaultBox = self.defaultSort_:GetComponent(typeof(UnityEngine.BoxCollider))
	countBox.enabled = false
	defaultBox.enabled = false
	local sequence = self:getSequence()

	local function setter(value)
		self.sortPop_:GetComponent(typeof(UIWidget)).alpha = value
	end

	if self.sortBtnState_ == -1 then
		sequence:Insert(0, self.sortPop_.transform:DOScale(Vector3(1.05, 1.05, 1), 0.067))
		sequence:Insert(0.067, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 0.1))
		sequence:Insert(0.067, self.sortPop_.transform:DOScale(Vector3(0.2, 0.2, 1), 0.1))
		sequence:AppendCallback(function ()
			countBox.enabled = true
			defaultBox.enabled = true
			self.doMoveSortPop_ = false

			self.sortPop_:SetActive(false)
		end)
	else
		self.sortPop_:SetActive(true)
		sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.01, 1, 0.1))
		sequence:Insert(0, self.sortPop_.transform:DOScale(Vector3(1.05, 1.05, 1), 0.1))
		sequence:Insert(0.1, self.sortPop_.transform:DOScale(Vector3(1, 1, 1), 0.2))
		sequence:AppendCallback(function ()
			countBox.enabled = true
			defaultBox.enabled = true
			self.doMoveSortPop_ = false
		end)
	end
end

function ActivityVote2:onRedPoint(event)
	local id = event.data.function_id

	if id == xyd.FunctionID.ACTIVITY_VOTE then
		self.missionBtnRedPoint_:SetActive(true)
	end
end

function ActivityVote2:onDressVote(event)
	local list = event.data.rank_list
	local status = event.data.period
	self.activityData.detail.rank_list[status] = event.data.rank_list
	local table_id_2_vote_count = self.table_id_2_vote_count_

	for i = 1, #list do
		local data = list[i]
		table_id_2_vote_count[tonumber(data.table_id)] = tonumber(data.vote_num)
	end

	self:buildRank()
	self:onTouchSortType(self.cur_sort_type_, false)
end

function ActivityVote2:getItemType()
	local items = xyd.tables.miscTable:split2Cost("wedding_vote2_cost", "value", "|#")
	local status = math.min(2, self.status_)

	return items[status + 1][1]
end

function ActivityVote2:getActivityId()
	return self.id
end

function ActivityVote2:dispose()
	ActivityVote2.super.dispose(self)

	if self.tiemCount_ then
		self.tiemCount_:stopTimeCount()

		self.tiemCount_ = nil
	end
end

function ActivityVote2:updateDataProvider(group)
	if not self.itemArray[group] or #self.itemArray[group] <= 0 then
		xyd.showToast(__("ACTIVITY_VOTE_EMPTY"))

		return false
	end

	if self.cur_group_ ~= group then
		self.cur_group_ = group

		self:refreshData()
	end

	return true
end

function ActivityVote2:onTouchSortType(type, need_event)
	self.cur_sort_type_ = type

	self.countSort_chosenImg:SetActive(type == SortType.VOTE_COUNT)
	self.defaultSort_chosenImg:SetActive(type == SortType.DEFAULT_SORT)

	if type == SortType.VOTE_COUNT then
		self.countSort_label.color = Color.New2(4294967295.0)
		self.countSort_label.effectStyle = UILabel.Effect.None
		self.defaultSort_label.color = Color.New2(235802367)
		self.defaultSort_label.effectStyle = UILabel.Effect.Outline
		self.defaultSort_label.effectColor = Color.New2(4294967295.0)
	else
		self.defaultSort_label.color = Color.New2(4294967295.0)
		self.defaultSort_label.effectStyle = UILabel.Effect.None
		self.countSort_label.color = Color.New2(235802367)
		self.countSort_label.effectStyle = UILabel.Effect.Outline
		self.countSort_label.effectColor = Color.New2(4294967295.0)
	end

	local cur_group_ = self.cur_group_

	for i = 0, 6 do
		local list = self.itemArray[i]

		if list and #list > 0 then
			if type == SortType.DEFAULT_SORT then
				if not self.defaultList_[i] then
					self.defaultList_[i] = self:randSortIds(list)
				else
					for j = 1, #self.defaultList_[i] do
						list[j] = self.defaultList_[i][j]
					end
				end
			elseif type == SortType.VOTE_COUNT then
				table.sort(list, function (a, b)
					if a and b then
						return b.count_fun(b.id) < a.count_fun(a.id)
					else
						return false
					end
				end)
			end
		end
	end

	self:refreshData()

	if need_event then
		self:onClickSortBtn()
	end
end

function ActivityVoteItem2:initUI()
	self.partnerImg = self.go:ComponentByName("partnerImg", typeof(UISprite))
	self.mask = self.partnerImg:NodeByName("mask").gameObject
	self.cardBg = self.go:ComponentByName("cardBg", typeof(UISprite))
	self.winImg = self.go:NodeByName("winImg").gameObject
	self.rankImg = self.go:ComponentByName("rankImg", typeof(UISprite))
	self.rankLabel = self.rankImg:ComponentByName("rankLabel", typeof(UILabel))
	self.partnerNameLabel = self.go:ComponentByName("partnerNameLabel", typeof(UILabel))
	self.getVoteLabel = self.go:ComponentByName("getVoteLabel", typeof(UILabel))
	self.voetNumLabel = self.go:ComponentByName("voetNumLabel", typeof(UILabel))
	self.btnVote = self.go:NodeByName("btnVote").gameObject
	self.voteLabel = self.btnVote:ComponentByName("voteLabel", typeof(UILabel))
	self.getVoteLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT1")
	self.voteLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT2")

	self.mask:SetActive(false)
	self.winImg:SetActive(false)
	self.go:SetLocalScale(0.7904761904761904, 0.7912371134020618, 1)
end

function ActivityVoteItem2:updateInfo()
	xyd.setUISpriteAsync(self.cardBg, nil, "activity_popularity_vote_card_1")
	xyd.setUISpriteAsync(self.partnerImg, nil, xyd.tables.partnerPictureTable:getPartnerCard(self.data.id))

	local rank = self.data.getRank(self.data.id)
	local score = self.data.count_fun(self.data.id)

	if (self.data.status < 2 and rank <= 4 or rank <= 3) and score and score > 0 then
		self.rankImg:SetActive(true)
		xyd.setUISpriteAsync(self.rankImg, nil, "activity_popularity_vote_rank_" .. rank)

		self.rankLabel.text = rank
	else
		self.rankImg:SetActive(false)
	end

	self.partnerNameLabel.text = xyd.tables.partnerTable:getName(self.data.id)

	if self.data.status ~= 3 then
		self.voetNumLabel.text = score or 0
	else
		self.voetNumLabel.text = "--"

		self.rankImg:SetActive(false)
	end

	xyd.setDragScrollView(self.btnVote, self.parent.scrollView_)
end

function ActivityVoteItem2:registerEvent()
	UIEventListener.Get(self.btnVote).onClick = function ()
		if self.data and self.data.id then
			local count = self.data.count_fun(self.data.id)

			xyd.WindowManager.get():openWindow("activity_do_vote_window", {
				id = self.data.id,
				count = self.data.count_fun(self.data.id),
				activity = self.parent,
				table = xyd.tables.activityWeddingVote2ListTable,
				cardSortFun = function (ids)
					if #ids == 3 then
						local swap = ids[3]
						ids[3] = ids[2]
						ids[2] = swap
					end

					local centerIndex = #ids >= 2 and 2 or 1

					return ids, centerIndex
				end
			})
		end
	end
end

return ActivityVote2
