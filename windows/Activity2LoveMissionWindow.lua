local BaseWindow = import(".BaseWindow")
local Activity2LoveMissionWindow = class("Activity2LoveMissionWindow", BaseWindow)
local Activity2LoveMissionItem1 = class("Activity2LoveMissionItem1", import("app.components.CopyComponent"))

function Activity2LoveMissionItem1:ctor(go, parent)
	self.parent_ = parent

	Activity2LoveMissionItem1.super.ctor(self, go)
end

function Activity2LoveMissionItem1:initUI()
	Activity2LoveMissionItem1.super.initUI(self)
	self:getComponent()
end

function Activity2LoveMissionItem1:getComponent()
	local goTrans = self.go.transform
	self.progressBar_ = goTrans:ComponentByName("progressPart", typeof(UIProgressBar))
	self.progressLabel_ = goTrans:ComponentByName("progressPart/labelDesc", typeof(UILabel))
	self.progressValue_ = goTrans:ComponentByName("progressPart/progressValue", typeof(UISprite))
	self.missionDesc_ = goTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.itemRoot_ = goTrans:ComponentByName("itemRoot", typeof(UILayout))
	self.btnAward_ = goTrans:NodeByName("btnAward").gameObject
	self.btnAwardLabel_ = goTrans:ComponentByName("btnAward/label", typeof(UILabel))
	self.btnAwardMask_ = goTrans:NodeByName("btnAward/btnMask").gameObject
	self.imgAward_ = goTrans:ComponentByName("imgAward", typeof(UISprite))
	self.btnAwardLabel_.text = __("ACTIVITY_2LOVE_TEXT09")
end

function Activity2LoveMissionItem1:getAwards()
	local params = {
		table_id = self.params_.id
	}
	self.parent_.tmpTableID = self.params_.id

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ARCTIC_EXPEDITION, require("cjson").encode(params))
end

function Activity2LoveMissionItem1:setInfo(params)
	self.params_ = params

	if params.complete_value <= params.value then
		self.progressBar_.value = 1
		self.progressLabel_.text = params.complete_value .. "/" .. params.complete_value
	else
		self.progressBar_.value = params.value / params.complete_value
		self.progressLabel_.text = params.value .. "/" .. params.complete_value
	end

	self.missionDesc_.text = __("ACTIVITY_2LOVE_TEXT07", params.complete_value)

	if params.is_completeds > 0 then
		self.imgAward_.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.imgAward_, nil, "mission_awarded_" .. xyd.Global.lang)
		xyd.setUISpriteAsync(self.progressValue_, nil, "activity_2love_progress_green")
		self.btnAward_:SetActive(false)
	else
		self.imgAward_.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.progressValue_, nil, "activity_2love_progress_yellow")
		xyd.setEnabled(self.btnAward_, true)
	end

	NGUITools.DestroyChildren(self.itemRoot_.transform)

	for i = 1, #params.awards do
		local item = params.awards[i]
		local icon = xyd.getItemIcon({
			labelNumScale = 1.2,
			hideText = true,
			uiRoot = self.itemRoot_.gameObject,
			itemID = item[1],
			num = item[2],
			dragScrollView = self.parent_.scrollView_
		})

		if params.is_completeds > 0 then
			icon:setChoose(true)
		end

		icon:SetLocalScale(0.65, 0.65, 1)
	end

	UIEventListener.Get(self.btnAward_).onClick = function ()
		if params.getway == 243 then
			local needStage = 17
			local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
			local maxStage = nil

			if mapInfo then
				maxStage = mapInfo.max_stage
			else
				maxStage = 0
			end

			if needStage > maxStage then
				local fortId = xyd.tables.stageTable:getFortID(needStage)
				local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(needStage))

				xyd.showToast(__("FUNC_OPEN_STAGE", text))

				return
			end
		end

		xyd.goWay(params.getway, nil, , function ()
		end)
		xyd.WindowManager.get():closeWindow("activity_2love_window")
		self.parent_:close()
	end

	self.itemRoot_:Reposition()
end

function Activity2LoveMissionWindow:ctor(name, params)
	Activity2LoveMissionWindow.super.ctor(self, name, params)

	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_2LOVE)

	dump(self.activityData_)

	self.missionItemList_ = {}
end

function Activity2LoveMissionWindow:initWindow()
	Activity2LoveMissionWindow.super.initWindow(self)
	self:getUIComponent()
	self:register()
	self:initMissionList()
end

function Activity2LoveMissionWindow:register()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, function ()
		self:initMissionList()
	end)
end

function Activity2LoveMissionWindow:getUIComponent()
	local winTrans = self.window_.transform:NodeByName("groupAction")
	self.missionItemRoot_ = self.window_.transform:NodeByName("missionItem").gameObject
	self.titleLabel_ = winTrans:ComponentByName("topGroup/titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("topGroup/closeBtn").gameObject
	self.countDownLabel_ = winTrans:ComponentByName("countDown", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("groupDetails/scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("groupDetails/scrollView/grid", typeof(UILayout))
	self.titleLabel_.text = __("ACTIVITY_2LOVE_TEXT10")
end

function Activity2LoveMissionWindow:initMissionList()
	local ids = xyd.tables.activity2LoveMissionTable:getIDs()
	local infolist1 = {}
	local missionValue = self.activityData_.detail.point

	for _, id in ipairs(ids) do
		local completeValue = xyd.tables.activity2LoveMissionTable:getCompleteValue(id)
		local isCompleted = 0

		if completeValue <= missionValue then
			isCompleted = 1
		end

		local params = {
			id = id,
			awards = xyd.tables.activity2LoveMissionTable:getAwards(id),
			value = missionValue,
			complete_value = completeValue,
			is_completeds = isCompleted,
			getway = xyd.tables.activity2LoveMissionTable:getGetWayID(id)
		}

		table.insert(infolist1, params)
	end

	table.sort(infolist1, function (a, b)
		local valueA = a.is_completeds * 100 + a.id
		local valueB = b.is_completeds * 100 + b.id

		return valueA < valueB
	end)

	for index, info in ipairs(infolist1) do
		local newItem = NGUITools.AddChild(self.grid_.gameObject, self.missionItemRoot_)

		newItem:SetActive(true)

		local missionItem = Activity2LoveMissionItem1.new(newItem, self)

		missionItem:setInfo(info)

		self.missionItemList_[info.id] = missionItem
	end

	self.grid_:Reposition()
	self.scrollView_:ResetPosition()
end

return Activity2LoveMissionWindow
