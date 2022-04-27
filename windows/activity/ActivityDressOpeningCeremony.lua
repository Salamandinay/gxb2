local ActivityDressOpeningCeremonyItem = class("ActivityDressOpeningCeremonyItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ActivityContent = import(".ActivityContent")
local ActivityDressOpeningCeremony = class("ActivityDressOpeningCeremony", ActivityContent)
local CountDown = import("app.components.CountDown")
local AdvanceIcon = import("app.components.AdvanceIcon")

function ActivityDressOpeningCeremony:ctor(name, params)
	ActivityContent.ctor(self, name, params)
end

function ActivityDressOpeningCeremony:getPrefabPath()
	return "Prefabs/Windows/activity/activity_dress_opening_ceremony"
end

function ActivityDressOpeningCeremony:initUI()
	self:getUIComponent()
	ActivityDressOpeningCeremony.super.initUI(self)
	self:layout()
	self:onRegisterEvent()
	self:updateTime()
	xyd.models.activity:reqActivityByID(self.id)
end

function ActivityDressOpeningCeremony:getUIComponent()
	self.trans = self.go
	self.imgBg = self.trans:ComponentByName("imgBg", typeof(UISprite))
	self.imgTitle = self.trans:ComponentByName("imgTitle", typeof(UISprite))
	self.group1 = self.trans:NodeByName("group1").gameObject
	self.scroller = self.group1:NodeByName("scroller").gameObject
	self.scroller_UIScrollView = self.group1:ComponentByName("scroller", typeof(UIScrollView))
	self.itemsGroup = self.scroller:NodeByName("itemsGroup").gameObject
	self.itemsGroup_UIWrapContent = self.scroller:ComponentByName("itemsGroup", typeof(UIWrapContent))
	self.drag = self.group1:NodeByName("drag").gameObject
	self.scroller1 = self.trans:NodeByName("scroller1").gameObject
	self.scroller1_UIScrollView = self.trans:ComponentByName("scroller1", typeof(UIScrollView))
	self.labelDesc = self.scroller1:ComponentByName("labelDesc", typeof(UILabel))
	self.labelDesc2 = self.trans:ComponentByName("labelDesc2", typeof(UILabel))
	self.labelBg = self.trans:ComponentByName("labelBg", typeof(UISprite))
	self.timeGroup = self.trans:NodeByName("timeGroup").gameObject
	self.timeGroupBg = self.timeGroup:ComponentByName("timeGroupBg", typeof(UISprite))
	self.timeTextLayout = self.timeGroup:NodeByName("timeTextLayout").gameObject
	self.timeTextLayout_UILayout = self.timeGroup:ComponentByName("timeTextLayout", typeof(UILayout))
	self.timeText1 = self.timeTextLayout:ComponentByName("timeText1", typeof(UILabel))
	self.timeText2 = self.timeTextLayout:ComponentByName("timeText2", typeof(UILabel))
	self.opening_ceremony_item = self.trans:NodeByName("opening_ceremony_item").gameObject
	self.goBtn = self.trans:NodeByName("goBtn").gameObject
	self.goBtnLabel = self.goBtn:ComponentByName("goBtnLabel", typeof(UILabel))
	self.wrapContent = FixedWrapContent.new(self.scroller_UIScrollView, self.itemsGroup_UIWrapContent, self.opening_ceremony_item, ActivityDressOpeningCeremonyItem, self)

	self.wrapContent:setInfos({}, {})
end

function ActivityDressOpeningCeremony:onRegisterEvent()
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, function (self, event)
		local id = event.data.act_info.activity_id

		if id ~= self.id then
			return
		end

		self:initData()
	end))

	UIEventListener.Get(self.goBtn.gameObject).onClick = handler(self, function ()
		xyd.goWay(xyd.GoWayId.ACTIVITY_DRESS_OPENING_CEREMONY, function ()
			xyd.WindowManager.get():closeWindow("activity_window")
		end, nil, )
	end)
end

function ActivityDressOpeningCeremony:layout()
	xyd.setUISpriteAsync(self.imgTitle, nil, "dress_opening_ceremony_text_" .. tostring(xyd.Global.lang), nil, , true)

	self.goBtnLabel.text = __("ACTIVITY_DRESS_GACHA_AWARD_JUMP")
	self.labelDesc2.text = __("ACTIVITY_DRESS_GACHA_AWARD_HELP")
	self.timeText2.text = __("TEXT_END")

	if self.labelDesc2.height > 92 then
		self.labelDesc2.gameObject:SetActive(false)

		self.labelDesc.text = __("ACTIVITY_DRESS_GACHA_AWARD_HELP")

		self.scroller1.gameObject:SetActive(true)
		self.scroller1_UIScrollView:ResetPosition()
	end

	if xyd.Global.lang == "ko_kr" then
		self.labelDesc2.fontSize = 19
	end
end

function ActivityDressOpeningCeremony:updateTime()
	local durationTime = self.activityData:getEndTime() - xyd.getServerTime()

	if durationTime > 0 then
		self.setRankCountDownTime = CountDown.new(self.timeText1, {
			duration = durationTime,
			callback = handler(self, self.timeOver)
		})
	else
		self.timeText1.text = "00:00:00"
	end
end

function ActivityDressOpeningCeremony:timeOver()
	self.timeText1.text = "00:00:00"
end

function ActivityDressOpeningCeremony:initData()
	local arr = {}
	local ids = xyd.tables.activityDressGachaAwardTable:getRankIDs()
	local complete_arr = {}
	local not_complete_arr = {}

	for i in pairs(ids) do
		local is_complete = self.activityData.detail.mission_completes[ids[i]]

		if is_complete and is_complete == 1 then
			table.insert(complete_arr, ids[i])
		else
			table.insert(not_complete_arr, ids[i])
		end
	end

	for i in pairs(complete_arr) do
		table.insert(not_complete_arr, complete_arr[i])
	end

	for i in pairs(not_complete_arr) do
		local params = {
			id = not_complete_arr[i]
		}

		table.insert(arr, params)
	end

	self:waitForFrame(1, function ()
		self.wrapContent:setInfos(arr, {})
		self:waitForFrame(1, function ()
			self.scroller_UIScrollView:ResetPosition()
		end)
	end)
end

function ActivityDressOpeningCeremonyItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.opening_ceremony_item = self.go
	self.progressBar_ = self.opening_ceremony_item:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = self.progressBar_:ComponentByName("progressImg", typeof(UISprite))
	self.progressLabel = self.progressBar_:ComponentByName("progressLabel", typeof(UILabel))
	self.itemsGroup = self.opening_ceremony_item:NodeByName("itemsGroup").gameObject
	self.labelTitle = self.opening_ceremony_item:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup_UILayout = self.opening_ceremony_item:ComponentByName("itemsGroup", typeof(UILayout))
	self.itemsArr = {}
	self.itemsArrRoot = {}
end

function ActivityDressOpeningCeremonyItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.id and self.id == info.id then
		return
	end

	self.id = info.id
	self.labelTitle.text = xyd.tables.activityDressGachaAwardTextTable:getTaskDesc(self.id)
	local max_num = xyd.tables.activityDressGachaAwardTable:getPoint(self.id)
	local now_num = self.parent.activityData.detail.mission_values[self.id] or 0
	local value = now_num / max_num

	if value > 1 then
		value = 1
		self.progressLabel.text = max_num .. "/" .. max_num
	else
		self.progressLabel.text = now_num .. "/" .. max_num
	end

	self.progressBar_.value = value
	local awards = xyd.tables.activityDressGachaAwardTable:getAward(self.id)

	for i in pairs(awards) do
		if not self.itemsArr[i] then
			local iconRoot = NGUITools.AddChild(self.itemsGroup.gameObject, "icon_i")
			iconRoot:AddComponent(typeof(UIWidget)).depth = 40

			iconRoot.gameObject:SetLocalScale(0.7, 0.7, 1)

			local icon = AdvanceIcon.new({
				isAddUIDragScrollView = true,
				uiRoot = iconRoot.gameObject,
				itemID = awards[i][1],
				num = awards[i][2]
			})

			table.insert(self.itemsArr, icon)
			table.insert(self.itemsArrRoot, iconRoot)
		else
			self.itemsArr[i]:setInfo({
				isAddUIDragScrollView = true,
				uiRoot = self.itemsArrRoot[i].gameObject,
				itemID = awards[i][1],
				num = awards[i][2]
			})
			self.itemsArr[i]:SetActive(true)
		end

		if value == 1 then
			self.itemsArr[i]:setChoose(true)
		else
			self.itemsArr[i]:setChoose(false)
		end
	end

	for i = #awards + 1, #self.itemsArr do
		self.itemsArr[i]:SetActive(false)
	end

	self.itemsGroup_UILayout:Reposition()
end

return ActivityDressOpeningCeremony
