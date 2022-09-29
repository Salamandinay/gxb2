local BaseWindow = import(".BaseWindow")
local DailyMissionWindow = class("DailyMissionWindow", BaseWindow)
local DailyMissionItem = class("DailyMissionItem", import("app.components.CopyComponent"))
local OldSize = {
	w = 720,
	h = 1280
}

function DailyMissionItem:ctor(go)
	DailyMissionItem.super.ctor(self, go)
end

function DailyMissionItem:initUI()
	self.go_ = self.go
	local itemTrans = self.go_.transform
	self.baseWi_ = itemTrans:GetComponent(typeof(UIWidget))
	self.progressBar_ = itemTrans:ComponentByName("progressPart", typeof(UIProgressBar))
	self.progressDesc_ = itemTrans:ComponentByName("progressPart/labelDesc", typeof(UILabel))
	self.btnGo_ = itemTrans:ComponentByName("btnGo", typeof(UISprite))
	self.btnGoLabel_ = itemTrans:ComponentByName("btnGo/label", typeof(UILabel))
	self.btnAward_ = itemTrans:ComponentByName("btnAward", typeof(UISprite))
	self.btnAwardLabel_ = itemTrans:ComponentByName("btnAward/label", typeof(UILabel))
	self.btnAwardMask_ = itemTrans:ComponentByName("btnAward/btnMask", typeof(UISprite))
	self.missionDesc_ = itemTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.groupBg_ = itemTrans:Find("groupBg").gameObject
	self.baseBg_ = itemTrans:Find("imgBg").gameObject
	self.iconRoot_ = itemTrans:Find("itemRoot").gameObject
end

function DailyMissionItem:setInfo(missionInfo, state, parent)
	self.parent_ = parent
	self.missionInfo_ = missionInfo
	self.currentState_ = state
	local mt = xyd.models.mission:getNowMissionTable()
	self.missionDesc_.text = mt:getDesc(missionInfo.mission_id)
	self.completeValuemt_ = mt:getCompleteValue(missionInfo.mission_id)
	self.progressBar_.value = missionInfo.value / self.completeValuemt_
	self.progressDesc_.text = missionInfo.value .. "/" .. self.completeValuemt_
	local itemInfo = mt:getAward(missionInfo.mission_id)

	if not self.iconItem_ then
		self.iconItem_ = xyd.getItemIcon({
			noClickSelected = true,
			labelNumScale = 1.6,
			hideText = true,
			uiRoot = self.iconRoot_,
			itemID = itemInfo[1],
			num = itemInfo[2] + missionInfo.extra,
			scale = Vector3(0.7, 0.7, 0.7)
		})
	else
		for i = 0, self.iconRoot_.transform.childCount - 1 do
			local child = self.iconRoot_.transform:GetChild(i).gameObject

			UnityEngine.Object.Destroy(child)
		end

		self.iconItem_ = xyd.getItemIcon({
			noClickSelected = true,
			labelNumScale = 1.6,
			hideText = true,
			uiRoot = self.iconRoot_,
			itemID = itemInfo[1],
			num = itemInfo[2] + missionInfo.extra,
			scale = Vector3(0.7, 0.7, 0.7)
		})
	end

	self.itemInfo_ = {
		id = itemInfo[1],
		num = itemInfo[2] + missionInfo.extra
	}
	self.btnGoLabel_.text = __("GO")
	self.btnAwardLabel_.text = __("GET2")

	if missionInfo.is_completed == 1 then
		self.btnGo_.gameObject:SetActive(false)
		self.btnAward_.gameObject:SetActive(true)
	else
		self.btnGo_.gameObject:SetActive(true)
		self.btnAward_.gameObject:SetActive(false)

		if state == "special" then
			self.btnAwardMask_.gameObject:SetActive(true)
			self.btnAward_.gameObject:SetActive(true)
			self.btnGo_.gameObject:SetActive(false)
		else
			self.btnAwardMask_.gameObject:SetActive(false)
		end
	end

	if state == "special" then
		self.groupBg_:SetActive(true)
		self.baseBg_:SetActive(false)
	else
		self.groupBg_:SetActive(false)
		self.baseBg_:SetActive(true)

		local dragScrollView = self.baseBg_:GetComponent(typeof(UIDragScrollView))
		dragScrollView = dragScrollView or self.baseBg_:AddComponent(typeof(UIDragScrollView))
		dragScrollView.scrollView = self.parent_.scrollView_
	end

	if missionInfo.is_awarded == 1 then
		self.btnAwardMask_.gameObject:SetActive(true)
		self.btnAward_.gameObject:SetActive(true)
		self.btnGo_.gameObject:SetActive(false)

		self.btnAwardLabel_.text = __("ALREADY_GET_PRIZE")
		self.btnAwardLabel_.color = Color.New2(960513791)
		self.btnAwardLabel_.effectColor = Color.New2(4294967295.0)

		xyd.setUISpriteAsync(self.btnAward_, nil, "white_btn_60_60")
	else
		xyd.setUISpriteAsync(self.btnAward_, nil, "blue_btn_60_60")
	end

	UIEventListener.Get(self.btnGo_.gameObject).onClick = handler(self, self.onClickGo)
	UIEventListener.Get(self.btnAward_.gameObject).onClick = handler(self, self.onClickAward)
end

function DailyMissionItem:onClickGo()
	local table = xyd.models.mission:getNowMissionTable()
	local funId = table:getFuncId(self.missionInfo_.mission_id)

	if funId ~= 0 and not xyd.checkFunctionOpen(funId) then
		return
	end

	local goWin = xyd.tables.dailyMissionTable:getGoWindow(self.missionInfo_.mission_id)

	if goWin and goWin == "arena_window" and xyd.models.arena:getIsSettlementing(true) then
		return
	end

	local params = xyd.tables.dailyMissionTable:getGoParams(self.missionInfo_.mission_id)

	xyd.WindowManager.get():closeWindow("daily_mission_window", function ()
		xyd.WindowManager.get():openWindow(goWin, params)
	end)
end

function DailyMissionItem:onClickAward()
	xyd.models.mission:getAward(self.missionInfo_.mission_id)

	local params = {
		{
			hideText = true,
			item_id = tonumber(self.itemInfo_.id),
			item_num = tonumber(self.itemInfo_.num)
		}
	}

	self.parent_:showItemFloat(params)
end

function DailyMissionItem:getMissionInfo()
	return self.missionInfo_
end

function DailyMissionItem:playDisappear(callback)
	local sequene = self:getSequence()

	sequene:Append(self.baseWi_.transform:DOScale(Vector3(1.05, 1.05, 1.05), 0.1))
	sequene:Append(self.baseWi_.transform:DOScale(Vector3(0.01, 0.01, 0.01), 0.16))
	sequene:AppendCallback(function ()
		self.baseWi_.gameObject:SetActive(false)
		callback()
	end)
	sequene:SetAutoKill(false)
end

function DailyMissionItem:playAppear(callback)
	local sequene = self:getSequence()

	self.baseWi_.gameObject:SetActive(true)

	self.baseWi_.alpha = 1
	self.baseWi_.transform.localScale = Vector3(0.5, 0.5, 0.5)

	sequene:Append(self.baseWi_.transform:DOScale(Vector3(1, 1, 1), 0.1))
	sequene:AppendCallback(callback)
	sequene:SetAutoKill(false)
end

function DailyMissionItem:setLocalPosition(localPosition)
	self.go_.transform.localPosition = localPosition
end

function DailyMissionItem:getGameObject()
	return self.go_
end

DailyMissionWindow.DailyMissionItem = DailyMissionItem

function DailyMissionWindow:ctor(name, params)
	DailyMissionWindow.super.ctor(self, name, params)

	self.model_ = xyd.models.mission
	self.table_ = xyd.tables.dailyMissionTable
	self.missionHasList_ = {}
	self.missionList_ = {}
end

function DailyMissionWindow:initWindow()
	DailyMissionWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.content_ = winTrans:ComponentByName("content", typeof(UISprite))
	self.labelTitle_ = self.content_.transform:ComponentByName("topGroup/titleLabel", typeof(UILabel))
	self.labelRefresh_ = self.content_.transform:ComponentByName("labelRefresh", typeof(UILabel))
	self.labelCountDown_ = self.content_.transform:ComponentByName("countDown", typeof(UILabel))
	self.closeBtn_ = self.content_.transform:ComponentByName("topGroup/closeBtn", typeof(UISprite))
	self.groupAllDone_ = self.content_.transform:Find("groupAllDone").gameObject
	self.groupDetails_ = self.content_.transform:Find("groupDetails").gameObject
	self.scrollView_ = self.content_.transform:ComponentByName("groupDetails/scrollView", typeof(UIScrollView))
	self.grid_ = self.content_.transform:ComponentByName("groupDetails/scrollView/grid", typeof(UIGrid))
	self.maskBg_ = winTrans:ComponentByName("maskBg", typeof(UIWidget))
	self.missionItemPrefab_ = winTrans:Find("missionItem").gameObject
	self.itemFloatRoot_ = winTrans:ComponentByName("itemFloatRoot", typeof(UIWidget))
	self.closeBtn = self.content_.transform:ComponentByName("topGroup/closeBtn", typeof(UISprite)).gameObject

	if xyd.Global.lang == "de_de" then
		self.missionItemPrefab_:ComponentByName("missionDesc", typeof(UILabel)).fontSize = 23
		self.missionItemPrefab_:ComponentByName("missionDesc", typeof(UILabel)).overflowWidth = 340
	end

	self.missionItemPrefab_:SetActive(false)

	local activeHeight = xyd.WindowManager.get():getActiveHeight()
	local activeWidth = xyd.WindowManager.get():getActiveWidth()
	local contentTrans = self.content_.transform
	contentTrans.localScale = Vector3(activeWidth / OldSize.w, activeHeight / OldSize.h, 1)
	contentTrans.localPosition = Vector3(0, contentTrans.localPosition.y * activeHeight / OldSize.h, 0)

	self:setCloseBtn(self.maskBg_.gameObject)
	self:register()
end

function DailyMissionWindow:playOpenAnimation(callback)
	local function afterAction()
		self.model_:getData()
		callback()
	end

	DailyMissionWindow.super.playOpenAnimation(self, afterAction)
end

function DailyMissionWindow:register()
	DailyMissionWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_MISSION_AWARD, handler(self, self.onMissionAward))
	self.eventProxy_:addEventListener(xyd.event.GET_MISSION_LIST, handler(self, self.onUpdateWindow))
end

function DailyMissionWindow:onUpdateWindow()
	self.endTime_ = self.model_:getEndTime()
	self.labelTitle_.text = __("DAILY_MISSION")
	self.labelRefresh_.text = __("REFRESH_TIME") .. ":"

	self:updateCountDown()

	if not self.timer_ then
		self.timer_ = Timer.New(handler(self, self.updateCountDown), 1, -1, false)

		self.timer_:Start()
	else
		self.timer_:Stop()
		self.timer_:Start()
	end

	self:initMissions()
end

function DailyMissionWindow:updateCountDown()
	self.labelCountDown_.text = xyd.secondsToString(self.endTime_ - xyd:getServerTime())
end

function DailyMissionWindow:initMissions()
	if self.model_:showFinalMission() then
		self.groupAllDone_:SetActive(true)

		self.groupDetails_.transform.localPosition = Vector3(0, 240, 0)
		local item = NGUITools.AddChild(self.groupAllDone_, self.missionItemPrefab_)

		item:SetActive(true)

		if not self.missionSpecialItem_ then
			self.missionSpecialItem_ = DailyMissionItem.new(item)
		end

		self.missionSpecialItem_:setInfo(self.model_:getFinalMissionInfo(), "special", self)
	else
		self.groupAllDone_:SetActive(false)

		self.groupDetails_.transform.localPosition = Vector3(0, 369, 0)
	end

	local missions = self.model_:getMissionList()

	for idx, mission in ipairs(missions) do
		XYDCo.WaitForFrame(idx, function ()
			if not self.missionHasList_[mission.mission_id] then
				local item = NGUITools.AddChild(self.grid_.gameObject, self.missionItemPrefab_)

				item:SetActive(true)

				local missionItem = DailyMissionItem.new(item)

				missionItem:setInfo(mission, "normal", self)

				self.missionHasList_[mission.mission_id] = missionItem
			else
				self.missionHasList_[mission.mission_id]:setInfo(mission, "normal", self)
			end

			self.grid_:Reposition()

			if idx == #missions or idx == 1 then
				self.scrollView_:ResetPosition()
			end
		end, nil)
	end
end

function DailyMissionWindow:onMissionAward(event)
	local missions = self.model_:getMissionList()
	local mission_id = event.data.mission_id
	local item = self.missionHasList_[mission_id]
	local index = -1

	for idx, mission in ipairs(missions) do
		if mission.mission_id == mission_id then
			index = idx
		end
	end

	if item and index >= 1 then
		item:playDisappear(function ()
			local itemRootNew = NGUITools.AddChild(self.grid_.gameObject, self.missionItemPrefab_)
			local missionItemNew = DailyMissionItem.new(itemRootNew)

			missionItemNew:setInfo(missions[index], "normal", self)

			self.missionHasList_[mission_id] = missionItemNew

			missionItemNew:playAppear()
			self.grid_:Reposition()
		end)
	elseif self.model_:showFinalMission() and self.missionSpecialItem_ then
		self.missionSpecialItem_:setInfo(self.model_:getFinalMissionInfo(), "special", self)
	end
end

function DailyMissionWindow:showItemFloat(params)
	self.itemFloat_ = import("app.components.ItemFloat").new(self.itemFloatRoot_.gameObject)

	self.itemFloat_:setInfo(params)
	self.itemFloat_:playGetAni()
end

function DailyMissionWindow:willClose()
	DailyMissionWindow.super.willClose(self)

	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end
end

return DailyMissionWindow
