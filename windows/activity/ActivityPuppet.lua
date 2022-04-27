local ActivityContent = import(".ActivityContent")
local ActivityPuppet = class("ActivityPuppet", ActivityContent)
local CountDown = import("app.components.CountDown")
local ActivityPuppetItem = class("ActivityPuppetItem", import("app.components.CopyComponent"))

function ActivityPuppet:ctor(parentGO, params)
	self.items = {}

	ActivityContent.ctor(self, parentGO, params)
end

function ActivityPuppet:getPrefabPath()
	return "Prefabs/Windows/activity/activity_puppet"
end

function ActivityPuppet:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:layout()
	self:initMission(true)
end

function ActivityPuppet:onRegister()
	self:registerEvent(xyd.event.WINDOW_WILL_CLOSE, handler(self, self.onWndClose))
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, function ()
		self:onRefresh()
	end))

	UIEventListener.Get(self.resBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			activityData = self.activityData.detail,
			itemID = xyd.ItemID.JOKER_PUPPET,
			activityID = xyd.ActivityID.ACTIVITY_PUPPET
		})
	end

	UIEventListener.Get(self.storyBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("story_window", {
			is_back = true,
			story_type = xyd.StoryType.ACTIVITY,
			story_id = xyd.tables.activityTable:getPlotId(xyd.ActivityID.ACTIVITY_PUPPET)
		})
	end
end

function ActivityPuppet:onWndClose(event)
	if event.params.windowName == "item_tips_window" then
		return
	end

	self:onRefresh()
end

function ActivityPuppet:onRefresh()
	self.resLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.JOKER_PUPPET)

	self:initMission()
end

function ActivityPuppet:resizeToParent()
	ActivityPuppet.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 867

	self.logoImg:Y(-108 - heightDis * 83 / 178)
	self.contentGroup:Y(-566 - heightDis * 108 / 178)
end

function ActivityPuppet:getUIComponent()
	local go = self.go
	self.itemCell = go:NodeByName("itemCell").gameObject
	self.mainGroup = go:NodeByName("mainGroup").gameObject
	self.logoImg = self.mainGroup:ComponentByName("logoImg", typeof(UISprite))
	self.timeGroup = self.mainGroup:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.storyBtn = self.mainGroup:NodeByName("storyBtn").gameObject
	self.model = self.mainGroup:NodeByName("model").gameObject
	self.contentGroup = self.mainGroup:NodeByName("contentGroup").gameObject
	self.resGroup = self.contentGroup:NodeByName("resGroup").gameObject
	self.resLabel = self.resGroup:ComponentByName("label", typeof(UILabel))
	self.resBtn = self.resGroup:NodeByName("btn").gameObject
	self.descLabel = self.contentGroup:ComponentByName("descLabel", typeof(UILabel))
	self.task = self.contentGroup:NodeByName("task").gameObject
	self.task_UIScrollView = self.contentGroup:ComponentByName("task", typeof(UIScrollView))
	self.task_UIPanel = self.contentGroup:ComponentByName("task", typeof(UIPanel))
	self.missionGroup = self.contentGroup:NodeByName("task/missionGroup").gameObject
	self.missionGroup_UILayout = self.contentGroup:ComponentByName("task/missionGroup", typeof(UILayout))
end

function ActivityPuppet:layout()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_puppet_logo_" .. tostring(xyd.Global.lang))

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		if xyd.Global.lang == "fr_fr" then
			self.timeLabel.color = Color.New2(3733089279.0)
			self.endLabel.color = Color.New2(3979052031.0)
			self.timeLabel.text = __("END")

			CountDown.new(self.endLabel, {
				duration = self.activityData:getUpdateTime() - xyd.getServerTime()
			})
		else
			self.endLabel.text = __("END")

			CountDown.new(self.timeLabel, {
				duration = self.activityData:getUpdateTime() - xyd.getServerTime()
			})
		end
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	if xyd.Global.lang == "de_de" then
		self.endLabel.fontSize = 16
		self.timeLabel.fontSize = 16
	end

	self.timeGroup:Reposition()

	if xyd.Global.lang == "de_de" then
		self:waitForFrame(1, function ()
			self.timeGroup:X(143)
		end)
	end

	self.resLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.JOKER_PUPPET)
	self.descLabel.text = __("ACTIVITY_PUPPET_TEXT01")
	self.effect = xyd.Spine.new(self.model)

	self.effect:setInfo("lvmeng_pifu03_lihui01", function ()
		self.effect:SetLocalPosition(0, -500, 0)
		self.effect:SetLocalScale(0.76, 0.76, 1)
		self.effect:play("animation", 0)
	end)
end

function ActivityPuppet:initMission(isInit)
	local ids = xyd.tables.activityPuppetTable:getIds()
	local data = {}

	for i = 1, #ids do
		local id = ids[i]
		local params = {
			id = id,
			awards = xyd.tables.activityPuppetTable:getAwards(id),
			completeNum = xyd.tables.activityPuppetTable:getPoint(id),
			value = xyd.models.backpack:getItemNumByID(xyd.ItemID.JOKER_PUPPET),
			isCompleted = xyd.tables.activityPuppetTable:getPoint(id) <= xyd.models.backpack:getItemNumByID(xyd.ItemID.JOKER_PUPPET),
			isNew = xyd.tables.activityPuppetTable:getIsNew(id) == 1
		}

		table.insert(data, params)
	end

	table.sort(data, function (a, b)
		if a.isCompleted == b.isCompleted then
			return a.id < b.id
		else
			return not a.isCompleted
		end
	end)

	for i = 1, #data do
		if self.items[i] == nil then
			local tmp = NGUITools.AddChild(self.missionGroup.gameObject, self.itemCell.gameObject)
			local item = ActivityPuppetItem.new(tmp, data[i])

			xyd.setDragScrollView(item.goItem_, self.task_UIScrollView)
			table.insert(self.items, item)
		else
			self.items[i]:updateParams(data[i])
		end
	end

	if isInit then
		self.missionGroup_UILayout:Reposition()
	end
end

function ActivityPuppetItem:ctor(goItem, params)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.id = params.id
	self.completeNum = params.completeNum
	self.value = params.value
	self.awards = params.awards
	self.isNew = params.isNew
	self.isCompleted = params.isCompleted
	self.descLabel = transGo:ComponentByName("descLabel", typeof(UILabel))
	self.progressBar = transGo:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressDesc = transGo:ComponentByName("progressBar/progressLabel", typeof(UILabel))
	self.itemGroup = transGo:NodeByName("itemGroup").gameObject

	ActivityPuppetItem.super.ctor(self, goItem)
end

function ActivityPuppetItem:initUI()
	self:initIcon()
	self:initProgress()

	if xyd.Global.lang == "zh_tw" or xyd.Global.lang == "ja_jp" then
		self.descLabel.overflowHeight = 30
	end

	self.descLabel.text = __("ACTIVITY_PUPPET_TEXT02", self.completeNum)
end

function ActivityPuppetItem:initIcon()
	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i = 1, #self.awards do
		local itemIcon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			itemID = self.awards[i][1],
			num = self.awards[i][2],
			uiRoot = self.itemGroup,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			scale = Vector3(0.5462962962962963, 0.5462962962962963, 1),
			isNew = i == #self.awards and self.isNew
		})

		itemIcon:setChoose(self.isCompleted)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityPuppetItem:initProgress()
	if self.completeNum < self.value then
		self.value = self.completeNum
	end

	self.progressBar.value = self.value / self.completeNum
	self.progressDesc.text = self.value .. " / " .. self.completeNum
end

function ActivityPuppetItem:updateParams(params)
	self.id = params.id
	self.descLabel.text = params.desc
	self.completeNum = params.completeNum
	self.value = params.value
	self.item = params.award

	self:initUI()
end

return ActivityPuppet
