local ActivityChildrenTask = class("ActivityChildrenTask", import(".ActivityContent"))
local ActivityChildrenTaskItem = class("ActivityChildrenTaskItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")

function ActivityChildrenTaskItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	ActivityChildrenTaskItem.super.ctor(self, go)
end

function ActivityChildrenTaskItem:initUI()
	self.task_item = self.go
	self.progressBarUIProgressBar = self.task_item:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressLabel = self.progressBarUIProgressBar.transform:ComponentByName("progressLabel", typeof(UILabel))
	self.itemRoot = self.task_item:NodeByName("itemRoot").gameObject
	self.labelDesc = self.task_item:ComponentByName("labelDesc", typeof(UILabel))
	self.limitGroup = self.task_item:ComponentByName("limitGroup", typeof(UILayout))
	self.completeLable = self.task_item:ComponentByName("limitGroup/labelLimit", typeof(UILabel))
	self.completeNum = self.task_item:ComponentByName("limitGroup/labelNum", typeof(UILabel))
	UIEventListener.Get(self.go.gameObject).onClick = handler(self, function ()
		if self.data_.get_way and self.data_.get_way > 0 then
			xyd.goWay(self.data_.get_way, nil, , function ()
				xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_CHILDREN_TASK)
			end)
		end
	end)
end

function ActivityChildrenTaskItem:setInfo(data)
	if not data then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.data_ = data
	self.id = data.id
	self.labelDesc.text = self.data_.desc
	self.value = self.data_.value
	self.completeLable.text = __("ACTIVITY_VAMPIRE_TASK_TEXT01") .. " : "

	if not self.awardItem_ then
		self.awardItem_ = xyd.getItemIcon({
			scale = 0.6018518518518519,
			uiRoot = self.itemRoot,
			itemID = self.data_.award[1],
			num = self.data_.award[2]
		})
	end

	if self.data_.limit <= self.data_.is_completed then
		self.completeNum.text = self.data_.limit .. "/" .. self.data_.limit
		self.completeNum.color = Color.New2(362565375)
		self.progressBarUIProgressBar.value = 1
		self.progressLabel.text = self.data_.complete_value .. "/" .. self.data_.complete_value

		self.awardItem_:setChoose(true)
	else
		self.completeNum.color = Color.New2(3525795839.0)
		self.completeNum.text = self.data_.is_completed .. "/" .. self.data_.limit
		self.progressBarUIProgressBar.value = self.data_.value / self.data_.complete_value
		self.progressLabel.text = self.data_.value .. "/" .. self.data_.complete_value

		self.awardItem_:setChoose(false)
	end

	self.limitGroup:Reposition()
end

function ActivityChildrenTask:ctor(parentGO, params)
	self.missionItems_ = {}
	self.awardItems_ = {}

	ActivityChildrenTask.super.ctor(self, parentGO, params)
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_CHILDREN_TASK)
	dump(self.activityData.detail)
end

function ActivityChildrenTask:getPrefabPath()
	return "Prefabs/Windows/activity/activity_children_task"
end

function ActivityChildrenTask:initUI()
	self:getUIComponent()
	ActivityChildrenTask.super.initUI(self)
	self:updateTime()
	self:updateAwardList()
	self:updateMissionList()
	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_children_task_logo_" .. xyd.Global.lang)
	self:register()
end

function ActivityChildrenTask:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_CHILDREN_TASK_HELP"
		})
	end

	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))
end

function ActivityChildrenTask:onActivityByID(event)
	local id = event.data.act_info.activity_id

	if id == xyd.ActivityID.ACTIVITY_CHILDREN_TASK then
		self:updateTime()
		self:updateAwardList()
		self:updateMissionList()
	end
end

function ActivityChildrenTask:getUIComponent()
	local go = self.go.transform
	self.bg4_ = go:NodeByName("bgPanel/imgBg4").gameObject
	self.logoImg_ = go:ComponentByName("logoImg", typeof(UISprite))
	self.helpBtn_ = go:NodeByName("helpBtn").gameObject
	self.timeGroup_ = go:ComponentByName("bgPanel/timeGroup", typeof(UILayout))
	self.timeLabel_ = go:ComponentByName("bgPanel/timeGroup/timeLabel", typeof(UILabel))
	self.timeText_ = go:ComponentByName("bgPanel/timeGroup/timeText", typeof(UILabel))
	self.scoreLabel_ = go:ComponentByName("bgPanel2/scroePart/label", typeof(UILabel))
	self.scrollViewProgress_ = go:ComponentByName("scrollViewProgress", typeof(UIScrollView))
	self.gridProgress_ = go:ComponentByName("scrollViewProgress/itemGrid", typeof(UIGrid))
	self.awardItem_ = go:NodeByName("scrollViewProgress/awardItem").gameObject
	self.progressItem_ = go:ComponentByName("scrollViewProgress/progressItem", typeof(UIProgressBar))
	self.scrollViewMission_ = go:ComponentByName("scrollViewMission", typeof(UIScrollView))
	self.gridMission_ = go:ComponentByName("scrollViewMission/grid", typeof(UIGrid))
	self.missionItem_ = go:NodeByName("scrollViewMission/missionItem").gameObject
end

function ActivityChildrenTask:updateTime()
	local countdownTime = self.activityData:getUpdateTime() - xyd.getServerTime()

	if not self.time_ then
		self.time_ = CountDown.new(self.timeLabel_, {
			duration = countdownTime
		})
	else
		self.time_:setInfo({
			duration = countdownTime
		})
	end

	self.timeText_.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.timeText_.transform:SetSiblingIndex(0)
		self.timeGroup_:Reposition()
	end
end

function ActivityChildrenTask:updateAwardList()
	local max_score = xyd.tables.activityChildrenCollectAwardTable:getMaxPoint() or 0
	local point = xyd.models.backpack:getItemNumByID(365)
	self.scoreLabel_.text = point .. "/" .. max_score
	local ids = xyd.tables.activityChildrenCollectAwardTable:getIDs()
	local award_id = 0

	for index, id in ipairs(ids) do
		local need_point = xyd.tables.activityChildrenCollectAwardTable:getPoint(id)
		local award = xyd.tables.activityChildrenCollectAwardTable:getAward(id)

		if not self.awardItems_[index] then
			local newRoot = NGUITools.AddChild(self.gridProgress_.gameObject, self.awardItem_)

			newRoot:SetActive(true)

			local labelPoint = newRoot:ComponentByName("labelScore", typeof(UILabel))
			labelPoint.text = need_point
			self.awardItems_[index] = xyd.getItemIcon({
				scale = 0.6018518518518519,
				uiRoot = newRoot,
				itemID = award[1],
				num = award[2],
				dragScrollView = self.scrollViewProgress_
			})

			self.awardItems_[index]:setDepth(20)
		else
			self.awardItems_[index]:setInfo({
				scale = 0.6018518518518519,
				itemID = award[1],
				num = award[2],
				dragScrollView = self.scrollViewProgress_
			})
		end

		if need_point <= point then
			self.awardItems_[index]:setChoose(true)

			award_id = id
		else
			self.awardItems_[index]:setChoose(false)
		end
	end

	local needPoint1, needPoint2 = nil

	if award_id > 0 then
		needPoint1 = xyd.tables.activityChildrenCollectAwardTable:getPoint(award_id)
	else
		needPoint1 = 0
	end

	if award_id < #ids then
		needPoint2 = xyd.tables.activityChildrenCollectAwardTable:getPoint(award_id + 1)
		self.progressItem_.value = award_id / #ids + 1 / #ids * (point - needPoint1) / (needPoint2 - needPoint1)
	else
		self.progressItem_.value = 1
	end
end

function ActivityChildrenTask:updateMissionList()
	local ids = xyd.tables.activityChildrenTaskTable:getIDs()
	local missionData = {}

	for index, id in ipairs(ids) do
		local params = {
			id = id
		}
		params.is_completed = self.activityData.detail.is_completeds[params.id] or 0
		params.value = self.activityData.detail.values[params.id] or 0
		params.limit = xyd.tables.activityChildrenTaskTable:getLimit(params.id)
		params.complete_value = xyd.tables.activityChildrenTaskTable:getCompValue(params.id)
		params.get_way = xyd.tables.activityChildrenTaskTable:getGetWay(params.id)
		params.award = xyd.tables.activityChildrenTaskTable:getAward(params.id)
		params.desc = xyd.tables.activityChildrenTaskTable:getDesc(params.id)

		table.insert(missionData, params)
	end

	table.sort(missionData, function (a, b)
		local avalue = a.id
		local bvalue = b.id

		if a.limit <= a.is_completed then
			avalue = avalue + 1000
		end

		if b.limit <= b.is_completed then
			bvalue = bvalue + 1000
		end

		return avalue < bvalue
	end)

	for index, data in ipairs(missionData) do
		if not self.missionItems_[data.id] then
			local rootNew = NGUITools.AddChild(self.gridMission_.gameObject, self.missionItem_)

			rootNew:SetActive(true)

			self.missionItems_[data.id] = ActivityChildrenTaskItem.new(rootNew, self)

			self.missionItems_[data.id]:setDepth(200 - 10 * index)
		end

		self.missionItems_[data.id]:setInfo(data)
	end

	self:waitForFrame(1, function ()
		self.gridMission_:Reposition()
		self.scrollViewMission_:ResetPosition()
	end)
end

return ActivityChildrenTask
