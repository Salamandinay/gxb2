local BaseWindow = import(".BaseWindow")
local ArcticExpeditionMissionWindow = class("ArcticExpeditionMissionWindow", BaseWindow)
local ArcticMissionItem1 = class("ArcticMissionItem1", import("app.components.CopyComponent"))
local ArcticMissionItem2 = class("ArcticMissionItem2", import("app.components.CopyComponent"))

function ArcticMissionItem1:ctor(go, parent)
	self.parent_ = parent

	ArcticMissionItem1.super.ctor(self, go)
end

function ArcticMissionItem1:initUI()
	ArcticMissionItem1.super.initUI(self)
	self:getComponent()
end

function ArcticMissionItem1:getComponent()
	local goTrans = self.go.transform
	self.progressBar_ = goTrans:ComponentByName("progressPart", typeof(UIProgressBar))
	self.progressLabel_ = goTrans:ComponentByName("progressPart/labelDesc", typeof(UILabel))
	self.missionDesc_ = goTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.itemRoot_ = goTrans:ComponentByName("itemRoot", typeof(UILayout))
	self.btnAward_ = goTrans:NodeByName("btnAward").gameObject
	self.btnAwardLabel_ = goTrans:ComponentByName("btnAward/label", typeof(UILabel))
	self.btnAwardMask_ = goTrans:NodeByName("btnAward/btnMask").gameObject
	self.imgAward_ = goTrans:ComponentByName("imgAward", typeof(UISprite))
	self.btnAwardLabel_.text = __("GET2")

	UIEventListener.Get(self.btnAward_).onClick = function ()
		self:getAwards()
	end
end

function ArcticMissionItem1:getAwards()
	local params = {
		table_id = self.params_.id
	}
	self.parent_.tmpTableID = self.params_.id

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ARCTIC_EXPEDITION, require("cjson").encode(params))
end

function ArcticMissionItem1:setInfo(params)
	self.params_ = params

	if params.complete_value <= params.value then
		self.progressBar_.value = 1
		self.progressLabel_.text = params.complete_value .. "/" .. params.complete_value
	else
		self.progressBar_.value = params.value / params.complete_value
		self.progressLabel_.text = params.value .. "/" .. params.complete_value
	end

	self.missionDesc_.text = params.desc

	if params.is_completeds and params.is_completeds > 0 then
		xyd.setEnabled(self.btnAward_, true)

		if params.is_awarded and params.is_awarded > 0 then
			self.imgAward_.gameObject:SetActive(true)
			xyd.setUISpriteAsync(self.imgAward_, nil, "mission_awarded_" .. xyd.Global.lang)
			self.btnAward_:SetActive(false)
		else
			self.imgAward_.gameObject:SetActive(false)
			self.btnAward_:SetActive(true)
		end
	else
		self.imgAward_.gameObject:SetActive(false)
		xyd.setEnabled(self.btnAward_, false)
	end

	NGUITools.DestroyChildren(self.itemRoot_.transform)
	self:waitForFrame(1, function ()
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

			icon:SetLocalScale(0.7, 0.7, 1)
		end

		self.itemRoot_:Reposition()
	end)
end

function ArcticMissionItem2:ctor(go, parent)
	self.parent_ = parent

	ArcticMissionItem2.super.ctor(self, go)
end

function ArcticMissionItem2:initUI()
	ArcticMissionItem2.super.initUI(self)
	self:getComponent()
end

function ArcticMissionItem2:getComponent()
	local goTrans = self.go.transform
	self.progressBar_ = goTrans:ComponentByName("progressPart", typeof(UIProgressBar))
	self.progressLabel_ = goTrans:ComponentByName("progressPart/labelDesc", typeof(UILabel))
	self.missionDesc_ = goTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.itemRoot_ = goTrans:ComponentByName("itemRoot", typeof(UILayout))
	self.btnAward_ = goTrans:NodeByName("btnAward").gameObject
	self.btnAwardLabel_ = goTrans:ComponentByName("btnAward/label", typeof(UILabel))
	self.btnAwardMask_ = goTrans:NodeByName("btnAward/btnMask").gameObject
	self.limitNum_ = goTrans:ComponentByName("limitNum", typeof(UILabel))

	UIEventListener.Get(self.btnAward_).onClick = function ()
		self:getAwards()
	end
end

function ArcticMissionItem2:getAwards()
	local params = {
		table_id = self.params_.id
	}
	self.parent_.tmpTableID = self.params_.id

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ARCTIC_EXPEDITION, require("cjson").encode(params))
end

function ArcticMissionItem2:setInfo(params)
	self.params_ = params

	if params.is_awarded < params.limit_time and params.is_awarded < params.is_completeds and params.is_completeds > 0 then
		self.progressBar_.value = 1
		self.progressLabel_.text = params.complete_value .. "/" .. params.complete_value
	elseif params.limit_time <= params.is_awarded then
		self.progressBar_.value = 1
		self.progressLabel_.text = params.complete_value .. "/" .. params.complete_value
	else
		self.progressBar_.value = math.floor(math.fmod(params.value, params.complete_value)) / params.complete_value
		self.progressLabel_.text = math.floor(math.fmod(params.value, params.complete_value)) .. "/" .. params.complete_value
	end

	self.missionDesc_.text = params.desc
	self.limitNum_.text = __("ACTIVITY_PRAY_COMPLETE") .. " " .. params.is_awarded .. "/" .. params.limit_time

	if params.is_awarded and params.limit_time <= params.is_awarded then
		xyd.setEnabled(self.btnAward_, false)

		self.btnAwardLabel_.text = __("GET2")
	elseif params.is_completeds <= params.is_awarded then
		xyd.setEnabled(self.btnAward_, false)

		self.btnAwardLabel_.text = __("GET2")
	else
		self.btnAwardLabel_.text = __("GET2") .. "x" .. params.is_completeds - params.is_awarded

		xyd.setEnabled(self.btnAward_, true)
	end

	self.btnAward_:SetActive(true)
	NGUITools.DestroyChildren(self.itemRoot_.transform)
	self:waitForFrame(1, function ()
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

			icon:SetLocalScale(0.7, 0.7, 1)
		end

		self.itemRoot_:Reposition()
	end)
	self.itemRoot_:Reposition()
end

function ArcticExpeditionMissionWindow:ctor(name, params)
	ArcticExpeditionMissionWindow.super.ctor(self, name, params)

	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)
	self.missionItemList_ = {}
end

function ArcticExpeditionMissionWindow:initWindow()
	ArcticExpeditionMissionWindow.super.initWindow(self)
	self:getUIComponent()
	self:regisetr()

	self.scoreLabel_.text = math.ceil(self.activityData_:getScore())

	if not self.activityData_:needUpdateMissionInfo() then
		self:initMissionList()
	end
end

function ArcticExpeditionMissionWindow:regisetr()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, function ()
		self:initMissionList()
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id == xyd.ActivityID.ARCTIC_EXPEDITION then
			local items = require("cjson").decode(event.data.detail).items

			xyd.models.itemFloatModel:pushNewItems(items)

			if self.tmpTableID and self.tmpTableID > 0 then
				self.activityData_.detail.awards[self.tmpTableID] = self.activityData_.detail.is_completeds[self.tmpTableID]
				local id = self.tmpTableID
				local params = {
					id = id,
					awards = xyd.tables.arcticExpeditionTaskTable:getAwards(id) or {},
					desc = xyd.tables.arcticExpeditionTaskTable:getDesc(id),
					value = self.activityData_.detail.values[tonumber(id)] or 0,
					is_completeds = self.activityData_.detail.is_completeds[tonumber(id)] or 0,
					is_awarded = self.activityData_.detail.awards[tonumber(id)] or 0,
					complete_value = xyd.tables.arcticExpeditionTaskTable:getCompleteValue(id) or 1,
					limit_time = xyd.tables.arcticExpeditionTaskTable:getLimitTime(id) or 1
				}

				self.missionItemList_[self.tmpTableID]:setInfo(params)

				self.tmpTableID = nil

				self.activityData_:getRedMarkState()

				local win = xyd.WindowManager.get():getWindow("arctic_expedition_main_window")

				if win then
					win:updateMissionRed()
				end
			end
		end
	end)
end

function ArcticExpeditionMissionWindow:getUIComponent()
	local winTrans = self.window_.transform:NodeByName("groupAction")
	self.missionItemRoot_ = self.window_.transform:NodeByName("missionItem").gameObject
	self.missionItemRoot2_ = self.window_.transform:NodeByName("missionItem2").gameObject
	self.titleLabel_ = winTrans:ComponentByName("topGroup/titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("topGroup/closeBtn").gameObject
	self.countDownLabel_ = winTrans:ComponentByName("countDown", typeof(UILabel))
	self.scoreLabel_ = winTrans:ComponentByName("iconGroup/label", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("groupDetails/scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("groupDetails/scrollView/grid", typeof(UILayout))
	self.titleLabel_.text = __("ARCTIC_EXPEDITION_TEXT_70")
end

function ArcticExpeditionMissionWindow:initMissionList()
	local ids = xyd.tables.arcticExpeditionTaskTable:getIDs()
	local infolist1 = {}
	local infolist2 = {}

	for _, id in ipairs(ids) do
		local params = {
			id = id,
			awards = xyd.tables.arcticExpeditionTaskTable:getAwards(id) or {},
			desc = xyd.tables.arcticExpeditionTaskTable:getDesc(id),
			value = self.activityData_.detail.values[tonumber(id)] or 0,
			is_completeds = self.activityData_.detail.is_completeds[tonumber(id)] or 0,
			is_awarded = self.activityData_.detail.awards[tonumber(id)] or 0,
			complete_value = xyd.tables.arcticExpeditionTaskTable:getCompleteValue(id) or 1,
			limit_time = xyd.tables.arcticExpeditionTaskTable:getLimitTime(id) or 1
		}

		if params.limit_time <= 1 then
			table.insert(infolist1, params)
		else
			table.insert(infolist2, params)
		end
	end

	for index, info in ipairs(infolist2) do
		local newItem = NGUITools.AddChild(self.grid_.gameObject, self.missionItemRoot2_)

		newItem:SetActive(true)

		local missionItem = ArcticMissionItem2.new(newItem, self)

		missionItem:setInfo(info)

		self.missionItemList_[info.id] = missionItem
	end

	table.sort(infolist1, function (a, b)
		local valueA = a.is_completeds * 100 + a.id - 1000 * a.is_awarded
		local valueB = b.is_completeds * 100 + b.id - 1000 * b.is_awarded

		return valueA > valueB
	end)

	for index, info in ipairs(infolist1) do
		local newItem = NGUITools.AddChild(self.grid_.gameObject, self.missionItemRoot_)

		newItem:SetActive(true)

		local missionItem = ArcticMissionItem1.new(newItem, self)

		missionItem:setInfo(info)

		self.missionItemList_[info.id] = missionItem
	end

	self.grid_:Reposition()
	self.scrollView_:ResetPosition()
end

return ArcticExpeditionMissionWindow
