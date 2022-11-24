local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ActivityTuringMission4 = class("ActivityTuringMission4", ActivityContent)
local ActivityTuringMission4Item = class("ActivityTuringMission4Item", import("app.components.CopyComponent"))
local ActivityTuringMissionTable = xyd.tables.activityTuringMissionTable

function ActivityTuringMission4:ctor(parentGO, params)
	self.currentState = xyd.Global.lang
	self.data = {}

	ActivityContent.ctor(self, parentGO, params)
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_TURING_MISSION4)
end

function ActivityTuringMission4:resizeToParent()
	ActivityTuringMission4.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874
end

function ActivityTuringMission4:getPrefabPath()
	return "Prefabs/Windows/activity/activity_turing_mission4"
end

function ActivityTuringMission4:initUI()
	self:getUIComponent()
	ActivityTuringMission4.super.initUI(self)
	xyd.setUISpriteAsync(self.textImg, nil, "activity_turing_mission4_logo_" .. xyd.Global.lang, nil, , true)
	self:setText()

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.FOOL_CLOCK_COIN)
end

function ActivityTuringMission4:getUIComponent()
	local go = self.go
	self.activityGroup = go:NodeByName("main").gameObject
	self.textImg = self.activityGroup:ComponentByName("textImg", typeof(UISprite))
	self.textLabel = self.activityGroup:ComponentByName("textLabel", typeof(UILabel))
	self.timerGroup = self.activityGroup:NodeByName("timerGroup").gameObject
	self.timeLabel = self.timerGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timerGroup:ComponentByName("endLabel", typeof(UILabel))
	self.scroller = self.activityGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollerPanel = self.activityGroup:ComponentByName("scroller", typeof(UIPanel))
	self.scrollerPanel.depth = self.scrollerPanel.depth + 1
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.groupItem_uigrid = self.groupItem:GetComponent(typeof(UIGrid))
	self.itemCell = go:NodeByName("itemCell").gameObject
	self.resItem = self.activityGroup:ComponentByName("resItem", typeof(UISprite))
	self.resNum = self.resItem:ComponentByName("num", typeof(UILabel))
	self.btnPlus = self.resItem:NodeByName("plus").gameObject
end

function ActivityTuringMission4:setText()
	if xyd.Global.lang == "de_de" then
		self.textLabel.width = 520
	end

	self.endLabel.text = __("TEXT_END")
	self.textLabel.text = __("TURING_MISSION04_TEXT01")
end

function ActivityTuringMission4:setItem()
	local ids = ActivityTuringMissionTable:getIDs()
	local data = {}

	for i = 1, #ids do
		local id = ids[i]
		local is_completed = false

		if ActivityTuringMissionTable:getLimit(id) <= self.activityData.detail.tasks[id] then
			is_completed = true
		end

		local param = {
			id = id,
			isCompleted = is_completed,
			point = self.activityData.detail.values[id],
			missionPoint = self.activityData.detail.tasks[id],
			scroller = self.scroller
		}

		table.insert(data, param)
	end

	table.sort(data, function (a, b)
		if a.isCompleted ~= b.isCompleted then
			return b.isCompleted
		else
			return a.id < b.id
		end
	end)
	self.scroller:ResetPosition()
	self.groupItem_uigrid:Y(252)
	NGUITools.DestroyChildren(self.groupItem.transform)

	for i = 1, #data do
		local tmp = NGUITools.AddChild(self.groupItem, self.itemCell)
		local item = ActivityTuringMission4Item.new(tmp, data[i], self)
	end

	self.groupItem_uigrid:Reposition()
	self.scroller:ResetPosition()
	self.itemCell:SetActive(false)
end

function ActivityTuringMission4:onRegister()
	self:registerEvent(xyd.event.WINDOW_WILL_CLOSE, function (event)
		self:onWindowClose(event)
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, function (event)
		self:onActivityByID(event)
	end)

	UIEventListener.Get(self.btnPlus).onClick = function ()
		local getWayId = xyd.GoWayId.ACTIVITY_FOOL_CLOCK

		if getWayId > 0 then
			xyd.goWay(getWayId, nil, , )
		end
	end

	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.FOOL_CLOCK_COIN)
	end)
end

function ActivityTuringMission4:onWindowClose(event)
	local name = event.params.windowName

	if name == "item_tips_window" then
		return
	end

	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_TURING_MISSION4)
end

function ActivityTuringMission4:onActivityByID(event)
	local id = event.data.act_info.activity_id

	if id == xyd.ActivityID.ACTIVITY_TURING_MISSION4 then
		self:setItem()
	end
end

function ActivityTuringMission4Item:ctor(parentGo, params)
	self.parent = parentGo
	self.scrollerView = params.scroller
	self.id = params.id
	self.point = params.point
	self.missionPoint = params.missionPoint
	self.isCompleted = params.isCompleted

	ActivityTuringMission4Item.super.ctor(self, parentGo)
end

function ActivityTuringMission4Item:initUI()
	ActivityTuringMission4Item.super.initUI(self)
	self:getUIComponent()
	self:initText()
	self:initItem()
	self:registEvent()
end

function ActivityTuringMission4Item:registEvent()
	UIEventListener.Get(self.touchField).onClick = handler(self, function ()
		local wayID = ActivityTuringMissionTable:getGetway(self.id)

		if wayID and wayID > 0 then
			xyd.goWay(wayID)
		end
	end)

	xyd.setDragScrollView(self.touchField, self.scrollerView)
end

function ActivityTuringMission4Item:getUIComponent()
	local transGo = self.go.transform
	self.progressBar_ = transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.labelTitle_ = transGo:ComponentByName("labelTitle", typeof(UILabel))
	self.label1 = transGo:ComponentByName("label1", typeof(UILabel))
	self.label2 = transGo:ComponentByName("label2", typeof(UILabel))
	self.tipsBtn = transGo:ComponentByName("tipsBtn", typeof(UISprite))
	self.tipsBg = transGo:ComponentByName("tipsBg", typeof(UISprite))
	self.tipsContent = transGo:ComponentByName("tipsContent", typeof(UILabel))
	self.itemsGroup_ = transGo:Find("itemsGroup")
	self.itemsGroup_UILayout = transGo:ComponentByName("itemsGroup", typeof(UILayout))
	self.touchField = transGo:NodeByName("touchField").gameObject
end

function ActivityTuringMission4Item:initText()
	self.labelTitle_.text = xyd.tables.activityTuringTextTable:getDesc(self.id)
	local limit = ActivityTuringMissionTable:getCompleteValue(self.id)
	self.progressBar_.value = self.point / limit
	self.progressDesc.text = self.point .. "/" .. limit

	if self.isCompleted then
		self.progressBar_.value = 1
		self.progressDesc.text = limit .. "/" .. limit
	end

	self.label1.text = __("TURING_TASK_LIMIT")
	self.label2.text = self.missionPoint .. "/" .. ActivityTuringMissionTable:getLimit(self.id)

	if limit == 1 then
		self.labelTitle_.fontSize = 20

		self.progressBar_:SetActive(false)
		self.labelTitle_:Y(0)
	end
end

function ActivityTuringMission4Item:initItem()
	local awards = ActivityTuringMissionTable:getAwards(self.id)

	for i, reward in pairs(awards) do
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_.gameObject,
			dragScrollView = self.scrollerView
		})

		icon:setScale(0.6)

		if self.isCompleted then
			icon:setChoose(true)
		end
	end

	self.itemsGroup_UILayout:Reposition()

	if xyd.tables.activityTuringMissionTable:getTips(self.id) == 0 then
		self.tipsBtn:SetActive(false)
	else
		self.tipsBtn:SetActive(true)

		self.labelTipsText = xyd.tables.activityTuringTextTable:getText(self.id)
		self.tipsContent.text = self.labelTipsText

		xyd.setUISpriteAsync(self.tipsBg, nil, "turing_mission_bg_tips")

		UIEventListener.Get(self.tipsBtn.gameObject).onPress = function (go, isPressed)
			if isPressed then
				self.tipsBg.gameObject:SetActive(true)
				self.tipsContent.gameObject:SetActive(true)
			else
				self.tipsBg.gameObject:SetActive(false)
				self.tipsContent.gameObject:SetActive(false)
			end
		end
	end
end

return ActivityTuringMission4
