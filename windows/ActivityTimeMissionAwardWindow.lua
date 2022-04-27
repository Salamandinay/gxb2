local ActivityTimeMissionAwardWindow = class("ActivityTimeMissionAwardWindow", import(".BaseWindow"))
local ActivityTimePointAwardItem = class("ActivityTimePointAwardItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivityTimeMissionAwardWindow:ctor(name, params)
	self.itemsArr = {}
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_TIME_MISSION)

	ActivityTimeMissionAwardWindow.super.ctor(self, name, params)
end

function ActivityTimeMissionAwardWindow:initWindow()
	self:getUIComponent()
	ActivityTimeMissionAwardWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function ActivityTimeMissionAwardWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelTitle_ = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.gridDaily = self.scrollView:ComponentByName("gridDaily", typeof(UILayout))
	self.missionItem = self.groupAction:NodeByName("missionItem").gameObject
end

function ActivityTimeMissionAwardWindow:layout()
	local mission_items = xyd.tables.activityTimePointAwardTable:getIDs()

	for i = 1, #mission_items do
		self.missionItem:SetActive(true)

		local itemRootNew = NGUITools.AddChild(self.gridDaily.gameObject, self.missionItem)
		local missionItemNew = ActivityTimePointAwardItem.new(itemRootNew, self, i)

		table.insert(self.itemsArr, missionItemNew)
		self.missionItem:SetActive(false)
	end

	self.gridDaily:Reposition()
	self.scrollView:ResetPosition()
	self:setTitle(__("ACTIVITY_TIME_MISSION_AWARD"))
end

function ActivityTimeMissionAwardWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityTimeMissionAwardWindow:onAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_TIME_MISSION then
		return
	end

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_TIME_MISSION)
	local detail = json.decode(data.detail)

	if detail.type == 2 then
		for i in pairs(self.itemsArr) do
			self.itemsArr[i]:updateGetAwardState(detail.table_id)
		end
	end
end

function ActivityTimePointAwardItem:ctor(go, parent, id)
	self.parent = parent
	self.id = id

	ActivityTimePointAwardItem.super.ctor(self, go)
end

function ActivityTimePointAwardItem:initUI()
	self.go_ = self.go
	local itemTrans = self.go.transform
	self.baseWi_ = itemTrans:GetComponent(typeof(UIWidget))
	self.progressBar_ = itemTrans:ComponentByName("progressPart", typeof(UIProgressBar))
	self.progressDesc_ = itemTrans:ComponentByName("progressPart/labelDesc", typeof(UILabel))
	self.btnGo_ = itemTrans:ComponentByName("btnGo", typeof(UISprite))
	self.btnGoLabel_ = itemTrans:ComponentByName("btnGo/label", typeof(UILabel))
	self.btnAward_ = itemTrans:ComponentByName("btnAward", typeof(UISprite))
	self.btnAward_box_ = itemTrans:ComponentByName("btnAward", typeof(UnityEngine.BoxCollider))
	self.btnAwardLabel_ = itemTrans:ComponentByName("btnAward/label", typeof(UILabel))
	self.btnAwardMask_ = itemTrans:ComponentByName("btnAward/btnMask", typeof(UISprite))
	self.missionDesc_ = itemTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.baseBg_ = itemTrans:ComponentByName("imgBg", typeof(UISprite))
	self.iconRoot_ = itemTrans:ComponentByName("itemRoot", typeof(UIGrid))
	self.awardImg_ = itemTrans:ComponentByName("imgAward", typeof(UISprite))
	self.btnGoPointCon = itemTrans:NodeByName("btnGoPointCon").gameObject
	self.btnGoPointCon_layout = itemTrans:ComponentByName("btnGoPointCon", typeof(UILayout))
	self.btnGoPointIcon = self.btnGoPointCon:NodeByName("btnGoPointIcon").gameObject
	self.btnGoPointLabel = self.btnGoPointCon:ComponentByName("btnGoPointLabel", typeof(UILabel))

	self.btnGoPointCon:SetActive(false)
	xyd.setUISpriteAsync(self.awardImg_, nil, "mission_awarded_" .. xyd.Global.lang, nil, )

	self.btnAwardLabel_.text = __("GET2")
	self.btnGoLabel_.text = __("GO")
	UIEventListener.Get(self.btnAward_.gameObject).onClick = handler(self, self.onTouchGetAward)

	self.btnGo_:SetActive(false)
	self:updateInfo(self.id)
end

function ActivityTimePointAwardItem:onTouchGetAward()
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_TIME_MISSION, json.encode({
		type = 2,
		table_id = self.id
	}))
end

function ActivityTimePointAwardItem:updateInfo(id)
	self.missionDesc_.text = __("ACTIVITY_TIME_MISSION_POINT", xyd.tables.activityTimePointAwardTable:getPoint(id))

	NGUITools.DestroyChildren(self.iconRoot_.gameObject.transform)

	local awards = xyd.tables.activityTimePointAwardTable:getAwards(id)

	for i, data in pairs(awards) do
		local item = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = data[1],
			num = data[2],
			scale = Vector3(0.7037037037037037, 0.7037037037037037, 1),
			uiRoot = self.iconRoot_.gameObject
		}
		local icon = xyd.getItemIcon(item)

		icon:setInfo(item)
	end

	self.iconRoot_:Reposition()
	self:updateState(id)
end

function ActivityTimePointAwardItem:updateState(id)
	self.activityData = self.parent.activityData
	self.btnAward_box_.enabled = true
	local selfPoint = xyd.tables.activityTimePointAwardTable:getPoint(id)

	if self.activityData.detail.p_awards[id] == 1 then
		self.btnAward_:SetActive(false)
		self.awardImg_:SetActive(true)
	else
		self.btnAward_:SetActive(true)
		self.awardImg_:SetActive(false)

		if self.activityData.detail.point < selfPoint then
			self.btnAward_box_.enabled = false

			xyd.applyChildrenGrey(self.btnAward_.gameObject)
		end
	end

	if selfPoint <= self.activityData.detail.point then
		self.progressDesc_.text = selfPoint .. "/" .. selfPoint
		self.progressBar_.value = 1
	else
		self.progressDesc_.text = self.activityData.detail.point .. "/" .. selfPoint
		self.progressBar_.value = self.activityData.detail.point / selfPoint
	end
end

function ActivityTimePointAwardItem:updateGetAwardState(id)
	if self.id ~= id then
		return
	else
		self:updateState(id)
	end
end

return ActivityTimeMissionAwardWindow
