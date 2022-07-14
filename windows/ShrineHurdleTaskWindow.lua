local ShrineHurdleNoticeWindow = class("ShrineHurdleNoticeWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ResItem = import("app.components.ResItem")
local shopModel = xyd.models.shop
local PlayerIcon = import("app.components.PlayerIcon")
local AchievementItem = class("AchievementItem", import("app.components.CopyComponent"))
local AchievementTable = xyd.tables.shrineAchievementTable
local AchievementTypeTable = xyd.tables.shrineAchievementTypeTable

function AchievementItem:ctor(go, parent)
	self.parent_ = parent

	AchievementItem.super.ctor(self, go)

	self.itemsRootList_ = {}
	self.itemID_ = {}
	self.itemNum_ = {}
	local itemTrans = self.go.transform
	self.progressBar_ = itemTrans:ComponentByName("progress", typeof(UIProgressBar))
	self.progressDesc_ = itemTrans:ComponentByName("progress/labelDisplay", typeof(UILabel))
	self.btnAward_ = itemTrans:NodeByName("btnAward").gameObject
	self.btnAwardImg_ = self.btnAward_:GetComponent(typeof(UISprite))
	self.btnAwardLabel_ = itemTrans:ComponentByName("btnAward/button_label", typeof(UILabel))
	self.missionDesc_ = itemTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.imgAward_ = itemTrans:ComponentByName("imgAward", typeof(UISprite))
	self.iconRoot1_ = itemTrans:Find("itemIcon1").gameObject
	self.iconRoot2_ = itemTrans:Find("itemIcon2").gameObject
	self.itemsRootList_[1] = self.iconRoot1_
	self.itemsRootList_[2] = self.iconRoot2_
	self.collectionBefore_ = {}

	self:layout()
	self:registerEvent()
end

function AchievementItem:registerEvent()
	UIEventListener.Get(self.btnAward_).onClick = handler(self, self.onClickAward)
end

function AchievementItem:onClickAward()
	if self.data_.mission_id then
		self.parent_.activityData:getMissionAward(self.data_.mission_id)
	end
end

function AchievementItem:getAchievementInfo()
	return self.data_
end

function AchievementItem:layout()
	xyd.setUISpriteAsync(self.imgAward_, nil, "mission_awarded_" .. tostring(xyd.Global.lang) .. "_png", nil, )
end

function AchievementItem:update(_, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	local hasChange = false
	local useKey = "mission_id"

	if info.achieve_id then
		useKey = "achieve_id"
	end

	if not self.data_ or info[useKey] ~= self.data_[useKey] then
		hasChange = true
	end

	self.data_ = info
	local achieve_id = info[useKey]
	local infoKey = info[useKey]

	if achieve_id == 0 and useKey == "achieve_id" then
		achieve_id = AchievementTypeTable:getEndAchievement(info.achieve_type)
	end

	local complete_value, text = nil
	local progressValue = info.value

	if useKey == "achieve_id" then
		complete_value = AchievementTable:getCompleteValue(achieve_id) or 0
		text = AchievementTypeTable:getDesc(info.achieve_type, complete_value)
		self.itemsInfo_ = AchievementTable:getAward(achieve_id)

		if xyd.Global.lang == "fr_fr" then
			self.missionDesc_.fontSize = 14
		end
	else
		complete_value = xyd.tables.activityChimeMissionTable:getCompleteValue(achieve_id) or 0
		text = xyd.tables.activityChimeMissionTextTable:getDesc(achieve_id)
		text = string.gsub(text, "{1}", complete_value)
		self.itemsInfo_ = xyd.tables.activityChimeMissionTable:getAwards(achieve_id)
	end

	self.missionDesc_.text = text

	if complete_value < progressValue then
		progressValue = complete_value
	end

	self.progressDesc_.text = progressValue .. "/" .. complete_value
	self.progressBar_.value = tonumber(progressValue) / tonumber(complete_value)

	self.iconRoot1_:SetActive(false)
	self.iconRoot2_:SetActive(false)

	for idx, itemInfo in ipairs(self.itemsInfo_) do
		local itemRoot = self.itemsRootList_[idx]

		itemRoot:SetActive(true)

		if not self.itemID_[idx] or not self.itemNum_[idx] or self.itemID_[idx] ~= itemInfo[1] and self.itemID_[idx] ~= xyd.tables.itemTable:partnerCost(itemInfo[1])[1] or self.itemNum_[idx] ~= itemInfo[2] then
			for i = 0, itemRoot.transform.childCount - 1 do
				local child = itemRoot.transform:GetChild(i).gameObject

				NGUITools.Destroy(child)
			end

			self.itemNum_[idx] = itemInfo[2]
			local type_ = xyd.tables.itemTable:getType(itemInfo[1])
			self.itemID_[idx] = itemInfo[1]
			self.iconItem_ = xyd.getItemIcon({
				isAddUIDragScrollView = true,
				labelNumScale = 1.6,
				noClickSelected = true,
				notShowGetWayBtn = true,
				hideText = true,
				show_has_num = true,
				scale = 0.7,
				uiRoot = itemRoot,
				itemID = itemInfo[1],
				num = itemInfo[2],
				dragScrollView = self.parent_.scrollView_,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	end

	if infoKey == 0 or info.is_awarded and info.is_awarded == 1 then
		self.btnAward_:SetActive(false)
		self.imgAward_.gameObject:SetActive(true)

		self.btnAwardLabel_.text = __("GET2")
	elseif complete_value <= info.value then
		self.btnAward_:SetActive(true)
		self.imgAward_.gameObject:SetActive(false)
		xyd.setEnabled(self.btnAward_, true)
		xyd.setUISpriteAsync(self.btnAwardImg_, nil, "blue_btn_54_54")

		self.btnAwardLabel_.text = __("GET2")
		self.btnAwardLabel_.effectColor = Color.New2(1012112383)
		self.btnAwardLabel_.color = Color.New2(4278124287.0)
	else
		self.btnAward_:SetActive(true)
		self.imgAward_.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.btnAwardImg_, nil, "blue_btn_54_54")
		xyd.setEnabled(self.btnAward_, false)

		self.btnAwardLabel_.text = __("GET2")
		self.btnAwardLabel_.color = Color.New2(4278124287.0)
	end
end

function AchievementItem:getGameObject()
	return self.go
end

function ShrineHurdleNoticeWindow:ctor(name, params)
	ShrineHurdleNoticeWindow.super.ctor(self, name, params)

	self.rankDataTriggers = {}
	self.sortStation = false
	self.itemList_ = {
		{},
		{}
	}
	self.groupList_ = {
		{},
		{}
	}
	self.firstClickNav = {}
end

function ShrineHurdleNoticeWindow:getComponent()
	self.groupAction = self.window_.transform:NodeByName("groupAction")
	self.closeBtn_ = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.missionItem = self.window_.transform:NodeByName("missionItem").gameObject
	self.missionNode = self.groupAction:NodeByName("missionNode").gameObject
	self.timeGroup = self.missionNode:NodeByName("timeGroup").gameObject
	self.timeGroupLayout = self.missionNode:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.missionListScroller = self.missionNode:ComponentByName("missionListScroller", typeof(UIScrollView))
	self.missionListContainer = self.missionListScroller:ComponentByName("missionListContainer", typeof(UIWrapContent))
	self.missionWrapContent = FixedWrapContent.new(self.missionListScroller, self.missionListContainer, self.missionItem, AchievementItem, self)

	self.missionWrapContent:hideItems()
	self.missionNode:SetActive(true)
end

function ShrineHurdleNoticeWindow:initWindow()
	ShrineHurdleNoticeWindow.super.initWindow(self)
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_CHIME)
	self:getComponent()
	self:register()

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_CHIME)

	self:layout()
end

function ShrineHurdleNoticeWindow:register()
	ShrineHurdleNoticeWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_CHIME then
			self:updateTaskGroup()
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if type(event) == "number" then
			-- Nothing
		elseif event.activity_id ~= xyd.ActivityID.ACTIVITY_CHIME then
			local data = event.data
			local info = require("cjson").decode(data.detail)
			local type = info.type

			if type == xyd.ActivityChimeReqType.COMMON then
				-- Nothing
			elseif type == xyd.ActivityChimeReqType.TASK then
				local awards = xyd.tables.activityChimeMissionTable:getAwards(info.table_id)
				local items = {}

				for i = 1, #awards do
					table.insert(items, {
						item_id = awards[i][1],
						item_num = awards[i][2]
					})
				end

				xyd.models.itemFloatModel:pushNewItems(items)
				self:updateTaskGroup()
			end
		end
	end)
end

function ShrineHurdleNoticeWindow:layout()
	self.endLabel_.text = __("END")

	if not self.missionLabelCount_ then
		self.missionLabelCount_ = import("app.components.CountDown").new(self.timeLabel_)
	end

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	self.timeGroupLayout:Reposition()
	self.missionLabelCount_:setInfo({
		duration = self.activityData:getEndTime() - xyd.getServerTime(),
		callback = function ()
		end
	})
end

function ShrineHurdleNoticeWindow:updateTaskGroup()
	local missions = {}
	local ids = xyd.tables.activityChimeMissionTable:getIDs()

	for i = 1, #ids do
		local mission = {
			mission_id = i,
			is_completed = self.activityData:getIsCompleteByTaskID(i) or 0,
			is_awarded = self.activityData:getIsAwardedByTaskID(i),
			value = self.activityData:getValueByTaskID(i)
		}

		table.insert(missions, mission)
	end

	table.sort(missions, function (a, b)
		if a.is_awarded ~= b.is_awarded then
			return a.is_awarded < b.is_awarded
		elseif a.is_completed ~= b.is_completed then
			return b.is_completed < a.is_completed
		else
			return a.mission_id < b.mission_id
		end
	end)
	dump(missions)
	self.missionWrapContent:setInfos(missions, {})
end

return ShrineHurdleNoticeWindow
