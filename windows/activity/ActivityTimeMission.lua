local ActivityTimeMission = class("ActivityTimeMission", import(".ActivityContent"))
local CommonTabBar = require("app.common.ui.CommonTabBar")
local ActivityTimeMissionItem = class("ActivityTimeMissionItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivityTimeMission:ctor(parentGo, params, parent)
	self.itemsArr = {}
	self.isCanClickBtn = true

	ActivityTimeMission.super.ctor(self, parentGo, params, parent)
end

function ActivityTimeMission:getPrefabPath()
	return "Prefabs/Windows/activity/activity_time_mission"
end

function ActivityTimeMission:resizeToParent()
	ActivityTimeMission.super.resizeToParent(self)
end

function ActivityTimeMission:initUI()
	self:getUIComponent()
	ActivityTimeMission.super.initUI(self)
	self:register()
	self:layout()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_TIME_MISSION)
end

function ActivityTimeMission:getUIComponent()
	self.trans = self.go
	self.topNode = self.trans:NodeByName("topNode").gameObject
	self.logoNode = self.topNode:NodeByName("logoNode").gameObject
	self.logo = self.logoNode:ComponentByName("logo", typeof(UISprite))
	self.group = self.logoNode:NodeByName("group").gameObject
	self.group_layout = self.logoNode:ComponentByName("group", typeof(UILayout))
	self.countDown = self.group:ComponentByName("countDown", typeof(UILabel))
	self.overWords = self.group:ComponentByName("overWords", typeof(UILabel))
	self.logoBg = self.logoNode:ComponentByName("logoBg", typeof(UISprite))

	xyd.setUISpriteAsync(self.logo, nil, "activity_time_mission_logo_" .. xyd.Global.lang, nil, )

	self.helpBtn = self.topNode:NodeByName("helpBtn").gameObject
	self.pointBtn = self.topNode:NodeByName("pointBtn").gameObject
	self.pointRedPoint = self.pointBtn:NodeByName("redPoint").gameObject
	self.pointBtnLabel = self.pointBtn:ComponentByName("pointBtnLabel", typeof(UILabel))
	self.pointBtnLabel.text = __("ACTIVITY_TIME_MISSION_AWARD")
	self.showPointCon = self.topNode:ComponentByName("showPointCon", typeof(UISprite))
	self.showPointLayout = self.showPointCon:ComponentByName("showPointLayout", typeof(UILayout))
	self.showPointIcon = self.showPointLayout:ComponentByName("showPointIcon", typeof(UISprite))
	self.showPointLabel = self.showPointLayout:ComponentByName("showPointLabel", typeof(UILabel))

	if xyd.Global.lang == "fr_fr" then
		self.pointBtn:X(257)

		self.pointBtnLabel.width = 170
	end

	self.groupNav = self.trans:NodeByName("groupNav").gameObject
	self.navBox = self.groupNav:ComponentByName("navBox", typeof(UnityEngine.BoxCollider))
	self.nav = self.groupNav:NodeByName("nav").gameObject

	for i = 1, 7 do
		self["tab_" .. i] = self.nav:NodeByName("tab_" .. i).gameObject
		self["tab_chosen_" .. i] = self["tab_" .. i]:ComponentByName("chosen", typeof(UISprite))
		self["tab_unchosen_" .. i] = self["tab_" .. i]:ComponentByName("unchosen", typeof(UISprite))
		self["tab_mask_" .. i] = self["tab_" .. i]:ComponentByName("mask", typeof(UISprite))
		self["tab_redPoint_" .. i] = self["tab_" .. i]:NodeByName("redPoint").gameObject
		local chosen_img = "activity_time_mission_lab5"
		local unchosen_img = "activity_time_mission_lab6"

		if i == 1 or i == 7 then
			chosen_img = "activity_time_mission_lab2"
			unchosen_img = "activity_time_mission_lab3"
		end

		local timeDis = xyd.getServerTime() - self.activityData:startTime()
		local maskImg = "activity_time_mission_lab4"

		if i == 7 then
			maskImg = "activity_time_mission_lab1"
		end

		if math.ceil(timeDis / 86400) < i then
			self["tab_mask_" .. i].gameObject:SetActive(true)
		else
			self["tab_mask_" .. i].gameObject:SetActive(false)
		end

		xyd.setUISpriteAsync(self["tab_chosen_" .. i], nil, chosen_img, nil, )
		xyd.setUISpriteAsync(self["tab_unchosen_" .. i], nil, unchosen_img, nil, )
		xyd.setUISpriteAsync(self["tab_mask_" .. i], nil, maskImg, nil, )
	end

	self.groupDetail = self.trans:NodeByName("groupDetail").gameObject
	self.scrollView = self.groupDetail:ComponentByName("scrollView", typeof(UIScrollView))
	self.gridDaily = self.scrollView:ComponentByName("gridDaily", typeof(UILayout))
	self.missionItem = self.groupDetail:NodeByName("missionItem").gameObject
	self.missionItemAllDone = self.groupDetail:NodeByName("missionItemAllDone").gameObject
	self.progressPart = self.missionItemAllDone:ComponentByName("progressPart", typeof(UIProgressBar))
	self.labelDesc = self.progressPart.gameObject:ComponentByName("labelDesc", typeof(UILabel))
	self.missionDesc = self.missionItemAllDone:ComponentByName("missionDesc", typeof(UILabel))
	self.itemRoot = self.missionItemAllDone:ComponentByName("itemRoot", typeof(UIGrid))
	self.btnAward = self.missionItemAllDone:NodeByName("btnAward").gameObject
	self.btnAward_box = self.missionItemAllDone:ComponentByName("btnAward", typeof(UnityEngine.BoxCollider))
	self.btnAward_label = self.btnAward:ComponentByName("label", typeof(UILabel))
	self.btnGo = self.missionItemAllDone:NodeByName("btnGo").gameObject
	self.btnGo_label = self.btnGo:ComponentByName("label", typeof(UILabel))
	self.imgAward = self.missionItemAllDone:ComponentByName("imgAward", typeof(UISprite))
	self.btnGoPointCon = self.missionItemAllDone:NodeByName("btnGoPointCon").gameObject
	self.btnGoPointCon_layout = self.missionItemAllDone:ComponentByName("btnGoPointCon", typeof(UILayout))
	self.btnGoPointIcon = self.btnGoPointCon:NodeByName("btnGoPointIcon").gameObject
	self.btnGoPointLabel = self.btnGoPointCon:ComponentByName("btnGoPointLabel", typeof(UILabel))
	self.btnAward_label.text = __("GET2")
	self.btnGo_label.text = __("GO")

	xyd.setUISpriteAsync(self.imgAward, nil, "mission_awarded_" .. xyd.Global.lang, nil, )
end

function ActivityTimeMission:layout()
	self.tab = CommonTabBar.new(self.nav.gameObject, 7, function (index)
		self:updateNav(index)
	end)
	local dateLabelArr = {}

	for i = 1, 7 do
		table.insert(dateLabelArr, __("ACTIVITY_TIME_MISSION_DAY", i))
	end

	self.tab:setTexts(dateLabelArr)

	self.overWords.text = __("END")
	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.countDown.text = "00:00:00"
	else
		local timeCount = import("app.components.CountDown").new(self.countDown)

		timeCount:setInfo({
			duration = duration,
			callback = handler(self, self.overTime)
		})
	end

	self.group_layout:Reposition()
	self:updatePointShow()
end

function ActivityTimeMission:updateTabPoint(index)
	if not index then
		self.tabPointArr = {
			0,
			0,
			0,
			0,
			0,
			0,
			0
		}

		for i, value in pairs(self.activityData.detail.m_awards) do
			local compelte_num = xyd.tables.activityTimeMissionTable:getComplete(i)

			if value == 0 and compelte_num <= self.activityData.detail.values[i] then
				local time = xyd.tables.activityTimeMissionTable:getTime(i)

				if self.tabPointArr[time] == 0 then
					self.tabPointArr[time] = 1
				end
			end
		end
	else
		for k = 1, 7 do
			if self.tabPointArr[k] == 0 then
				local mission_items = xyd.tables.activityTimeMissionTabTable:getIds(k)
				self.tabPointArr[k] = 0

				for i, id in pairs(mission_items) do
					local compelte_num = xyd.tables.activityTimeMissionTable:getComplete(id)

					if self.activityData.detail.m_awards[id] == 0 and compelte_num <= self.activityData.detail.values[id] then
						self.tabPointArr[k] = 1

						break
					end
				end
			end
		end

		local mission_items = xyd.tables.activityTimeMissionTabTable:getIds(index)
		self.tabPointArr[index] = 0

		for i, id in pairs(mission_items) do
			local compelte_num = xyd.tables.activityTimeMissionTable:getComplete(id)

			if self.activityData.detail.m_awards[id] == 0 and compelte_num <= self.activityData.detail.values[id] then
				self.tabPointArr[index] = 1

				break
			end
		end
	end

	for i in pairs(self.tabPointArr) do
		if not self["tab_mask_" .. i].gameObject.activeSelf then
			self["tab_redPoint_" .. i]:SetActive(self.tabPointArr[i] == 1)
		else
			self["tab_redPoint_" .. i]:SetActive(false)
		end
	end
end

function ActivityTimeMission:updatePointRedPoint()
	for i, value in pairs(self.activityData.detail.p_awards) do
		local needPoint = xyd.tables.activityTimePointAwardTable:getPoint(i)

		if value == 0 and needPoint <= self.activityData.detail.point then
			self.pointRedPoint:SetActive(true)

			return
		end
	end

	self.pointRedPoint:SetActive(false)
end

function ActivityTimeMission:overTime()
	self.countDown.text = "00:00:00"

	self.group_layout:Reposition()
end

function ActivityTimeMission:register()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_TIME_MISSION_HELP"
		})
	end

	UIEventListener.Get(self.btnAward.gameObject).onClick = handler(self, self.onTouchGetAward)
	UIEventListener.Get(self.btnGo.gameObject).onClick = handler(self, self.onTouchGo)
	UIEventListener.Get(self.pointBtn.gameObject).onClick = handler(self, self.onTouchPointBtn)

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	for i = 1, 7 do
		UIEventListener.Get(self["tab_mask_" .. i].gameObject).onClick = handler(self, function ()
			local timeDis = xyd.getServerTime() - self.activityData:startTime()

			xyd.showToast(__("ACTIVITY_TIME_MISSION_UNLOCK", i - math.ceil(timeDis / 86400)))
		end)
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))
	self:registerEvent(xyd.event.MIDAS_BUY_2, handler(self, self.onMidas))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function ActivityTimeMission:onMidas()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_TIME_MISSION)
end

function ActivityTimeMission:onItemChange(event)
	if self.isOnAwardToItemChange then
		return
	end

	local data = event.data.items

	for i = 1, #data do
		local item = data[i]

		if item.item_id == xyd.ItemID.CRYSTAL then
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_TIME_MISSION)
		end
	end
end

function ActivityTimeMission:onActivityByID(event)
	local id = event.data.act_info.activity_id

	if id ~= self.id then
		return
	end

	self.activityData = xyd.models.activity:getActivity(self.id)

	self:updatePointShow()
	self:updateTabPoint()
	self:updatePointRedPoint()

	if not self.isFirstInit then
		local defaultDayIndex = 1

		for i = 1, 7 do
			if not self["tab_mask_" .. i].gameObject.activeSelf then
				local isFinish = true
				local ids = xyd.tables.activityTimeMissionTabTable:getIds(i)

				for j in pairs(ids) do
					if self.activityData.detail.m_awards[ids[j]] == 0 then
						isFinish = false

						break
					end
				end

				if isFinish then
					defaultDayIndex = defaultDayIndex + 1
				else
					break
				end
			end
		end

		if defaultDayIndex > 7 then
			defaultDayIndex = 7
		end

		if self["tab_mask_" .. defaultDayIndex].gameObject.activeSelf then
			defaultDayIndex = defaultDayIndex - 1
		end

		self.tab:setTabActive(defaultDayIndex, true, false)

		self.isFirstInit = true
	else
		self:updateNav(self.chose_index)
	end
end

function ActivityTimeMission:onAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_TIME_MISSION then
		return
	end

	self.activityData = xyd.models.activity:getActivity(self.id)
	local detail = json.decode(data.detail)

	if detail.type == 1 then
		if tonumber(detail.table_id) == self.allDown_id then
			self:updateState(self.allDown_id)

			if self.isOnAwardToItemChange then
				self.isOnAwardToItemChange = false
			end
		else
			for i in pairs(self.itemsArr) do
				if self.itemsArr[i]:getGameObject().activeSelf and self.itemsArr[i].id == detail.table_id then
					self.itemsArr[i]:updateGetAwardState(detail.table_id)
					self:playDisappear(function ()
						self.gridDaily:Reposition()
						self.scrollView:ResetPosition()

						local itemsTemp = {}

						for j in pairs(self.itemsArr) do
							if self.itemsArr[j].id ~= detail.table_id then
								table.insert(itemsTemp, self.itemsArr[j])
							else
								NGUITools.Destroy(self.itemsArr[j]:getGameObject().transform)
							end
						end

						self.itemsArr = itemsTemp

						self.missionItem:SetActive(true)

						local itemRootNew = NGUITools.AddChild(self.gridDaily.gameObject, self.missionItem)
						local missionItemNew = ActivityTimeMissionItem.new(itemRootNew, self)

						self.missionItem:SetActive(false)
						missionItemNew:updateInfo(detail.table_id)
						table.insert(self.itemsArr, missionItemNew)
						self.gridDaily:Reposition()
						self.scrollView:ResetPosition()

						self.navBox.enabled = false

						if self.isOnAwardToItemChange then
							self.isOnAwardToItemChange = false
						end
					end, self.itemsArr[i]:getGameObject())

					break
				end
			end
		end
	end

	self:updatePointRedPoint()
	self:updatePointShow()
	self:updateTabPoint(self.chose_index)
end

function ActivityTimeMission:onTouchGetAward()
	if self.allDown_id == nil then
		return
	end

	if not self.isCanClickBtn then
		return
	end

	self.isOnAwardToItemChange = true

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_TIME_MISSION, json.encode({
		type = 1,
		table_id = self.allDown_id
	}))
end

function ActivityTimeMission:onTouchGo()
	local goWay = xyd.tables.activityTimeMissionTable:getGetway(self.allDown_id)

	if goWay and goWay > 0 then
		xyd.goWay(goWay, nil, , function ()
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_TIME_MISSION)
		end)
	end
end

function ActivityTimeMission:onTouchPointBtn()
	xyd.WindowManager.get():openWindow("activity_time_mission_award_window")
end

function ActivityTimeMission:updateNav(index)
	self.isCanClickBtn = false

	self:waitForFrame(5, function ()
		self.isCanClickBtn = true
	end)

	self.chose_index = index
	local mission_items = xyd.tables.activityTimeMissionTabTable:getIds(index)
	local temp_items_arr = {}

	table.insert(temp_items_arr, mission_items[1])

	for i = 2, #mission_items do
		if self.activityData.detail.m_awards[mission_items[i]] == 0 then
			local compelte_num = xyd.tables.activityTimeMissionTable:getComplete(mission_items[i])

			if compelte_num <= self.activityData.detail.values[mission_items[i]] then
				table.insert(temp_items_arr, mission_items[i])
			end
		end
	end

	for i = 2, #mission_items do
		if self.activityData.detail.m_awards[mission_items[i]] == 0 then
			local compelte_num = xyd.tables.activityTimeMissionTable:getComplete(mission_items[i])

			if self.activityData.detail.values[mission_items[i]] < compelte_num then
				table.insert(temp_items_arr, mission_items[i])
			end
		end
	end

	for i = 2, #mission_items do
		if self.activityData.detail.m_awards[mission_items[i]] == 1 then
			table.insert(temp_items_arr, mission_items[i])
		end
	end

	if #self.itemsArr < #temp_items_arr - 1 then
		self.missionItem:SetActive(true)

		for i = #self.itemsArr + 1, #temp_items_arr - 1 do
			local itemRootNew = NGUITools.AddChild(self.gridDaily.gameObject, self.missionItem)
			local missionItemNew = ActivityTimeMissionItem.new(itemRootNew, self)

			table.insert(self.itemsArr, missionItemNew)
		end

		self.missionItem:SetActive(false)
	elseif #self.itemsArr > #temp_items_arr - 1 then
		for i in pairs(self.itemsArr) do
			if i <= #temp_items_arr - 1 then
				self.itemsArr:getGameObject():SetActive(true)
			else
				self.itemsArr:getGameObject():SetActive(false)
			end
		end
	end

	for i = 1, #temp_items_arr - 1 do
		self.itemsArr[i]:updateInfo(temp_items_arr[i + 1])
	end

	self.gridDaily:Reposition()
	self.scrollView:ResetPosition()
	self:updateAllDown(index)
end

function ActivityTimeMission:updateAllDown(index)
	local mission_items = xyd.tables.activityTimeMissionTabTable:getIds(index)
	local id = mission_items[1]
	self.allDown_id = id
	self.missionDesc.text = xyd.tables.activityTimeMissionTextTable:getDesc(id)

	NGUITools.DestroyChildren(self.itemRoot.gameObject.transform)

	local awards = xyd.tables.activityTimeMissionTable:getAwards(id)

	for i, data in pairs(awards) do
		local item = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = data[1],
			num = data[2],
			scale = Vector3(0.7037037037037037, 0.7037037037037037, 1),
			uiRoot = self.itemRoot.gameObject
		}
		local icon = xyd.getItemIcon(item)

		icon:setInfo(item)
	end

	self.itemRoot:Reposition()
	self:updateState(id)
end

function ActivityTimeMission:updateState(id)
	if self.activityData.detail.m_awards[id] == 1 then
		self.imgAward:SetActive(true)
		self.btnAward:SetActive(false)
		self.btnGoPointCon:SetActive(false)
		self.btnGo:SetActive(false)

		local compelte_num = xyd.tables.activityTimeMissionTable:getComplete(id)
		self.labelDesc.text = compelte_num .. "/" .. compelte_num
		self.progressPart.value = 1
	else
		self.imgAward:SetActive(false)

		self.btnAward_box.enabled = true

		xyd.applyChildrenOrigin(self.btnAward)

		local compelte_num = xyd.tables.activityTimeMissionTable:getComplete(id)

		if compelte_num <= self.activityData.detail.values[id] then
			self.btnGo:SetActive(false)
			self.btnAward:SetActive(true)
			self.btnGoPointCon:SetActive(true)

			self.labelDesc.text = compelte_num .. "/" .. compelte_num
			self.progressPart.value = 1
			local can_get_point = xyd.tables.activityTimeMissionTable:getPoint(id)

			if can_get_point and can_get_point > 0 then
				self.btnGoPointLabel.text = "+" .. can_get_point

				self.btnGoPointCon_layout:Reposition()
				self.btnAward:Y(-35.6)
			else
				self.btnAward:Y(-21.18)
			end
		else
			self.btnGoPointCon:SetActive(false)

			self.labelDesc.text = self.activityData.detail.values[id] .. "/" .. compelte_num
			self.progressPart.value = self.activityData.detail.values[id] / compelte_num
			local goWay = xyd.tables.activityTimeMissionTable:getGetway(id)

			if goWay and goWay > 0 then
				self.btnGo:SetActive(true)
				self.btnAward:SetActive(false)
			else
				self.btnGo:SetActive(false)
				self.btnAward:SetActive(true)
				xyd.applyChildrenGrey(self.btnAward)

				self.btnAward_box.enabled = false
			end

			local can_get_point = xyd.tables.activityTimeMissionTable:getPoint(id)

			if can_get_point and can_get_point > 0 then
				self.btnGoPointCon:SetActive(true)

				self.btnGoPointLabel.text = "+" .. can_get_point

				self.btnGoPointCon_layout:Reposition()
				self.btnAward:Y(-35.6)
				self.btnGo:Y(-35.6)
			else
				self.btnAward:Y(-21.18)
				self.btnGo:Y(-21.18)
			end
		end
	end
end

function ActivityTimeMission:updatePointShow()
	self.showPointLabel.text = "x" .. self.activityData.detail.point

	self.showPointLayout:Reposition()
end

function ActivityTimeMission:playDisappear(callback, item)
	local sequene = self:getSequence()

	sequene:Append(item.transform:DOScale(Vector3(1.05, 1.05, 1.05), 0.1))
	sequene:Append(item.transform:DOScale(Vector3(0.01, 0.01, 0.01), 0.16))
	sequene:AppendCallback(function ()
		sequene:Kill(false)
		item.gameObject:SetActive(false)
		callback()
	end)
end

function ActivityTimeMissionItem:ctor(go, parent)
	self.parent = parent

	ActivityTimeMissionItem.super.ctor(self, go)
end

function ActivityTimeMissionItem:initUI()
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

	xyd.setUISpriteAsync(self.awardImg_, nil, "mission_awarded_" .. xyd.Global.lang, nil, )

	self.btnAwardLabel_.text = __("GET2")
	self.btnGoLabel_.text = __("GO")
	UIEventListener.Get(self.btnAward_.gameObject).onClick = handler(self, self.onTouchGetAward)
	UIEventListener.Get(self.btnGo_.gameObject).onClick = handler(self, self.onTouchGo)
end

function ActivityTimeMissionItem:onTouchGetAward()
	if self.id == nil then
		return
	end

	if not self.parent.isCanClickBtn then
		return
	end

	self.parent.isOnAwardToItemChange = true
	self.parent.navBox.enabled = true

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_TIME_MISSION, json.encode({
		type = 1,
		table_id = self.id
	}))
end

function ActivityTimeMissionItem:onTouchGo()
	local goWay = xyd.tables.activityTimeMissionTable:getGetway(self.id)

	if goWay and goWay > 0 then
		xyd.goWay(goWay, nil, , function ()
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_TIME_MISSION)
		end)
	end
end

function ActivityTimeMissionItem:updateInfo(id)
	self.id = id
	self.missionDesc_.text = xyd.tables.activityTimeMissionTextTable:getDesc(id)

	NGUITools.DestroyChildren(self.iconRoot_.gameObject.transform)

	local awards = xyd.tables.activityTimeMissionTable:getAwards(id)

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

function ActivityTimeMissionItem:updateState(id)
	self.activityData = self.parent.activityData

	if self.activityData.detail.m_awards[id] == 1 then
		self.awardImg_:SetActive(true)
		self.btnAward_:SetActive(false)
		self.btnGoPointCon:SetActive(false)
		self.btnGo_:SetActive(false)

		local compelte_num = xyd.tables.activityTimeMissionTable:getComplete(id)
		self.progressDesc_.text = compelte_num .. "/" .. compelte_num
		self.progressBar_.value = 1
	else
		self.awardImg_:SetActive(false)

		self.btnAward_box_.enabled = true

		xyd.applyChildrenOrigin(self.btnAward_.gameObject)

		local compelte_num = xyd.tables.activityTimeMissionTable:getComplete(id)

		if compelte_num <= self.activityData.detail.values[id] then
			self.btnGo_:SetActive(false)
			self.btnAward_:SetActive(true)
			self.btnGoPointCon:SetActive(true)

			self.progressDesc_.text = compelte_num .. "/" .. compelte_num
			self.progressBar_.value = 1
			local can_get_point = xyd.tables.activityTimeMissionTable:getPoint(id)

			if can_get_point and can_get_point > 0 then
				self.btnGoPointLabel.text = "+" .. can_get_point

				self.btnGoPointCon_layout:Reposition()
				self.btnAward_:Y(-13.6)
			else
				self.btnAward_:Y(-0.6)
			end
		else
			self.btnGoPointCon:SetActive(false)

			self.progressDesc_.text = self.activityData.detail.values[id] .. "/" .. compelte_num
			self.progressBar_.value = self.activityData.detail.values[id] / compelte_num
			local goWay = xyd.tables.activityTimeMissionTable:getGetway(id)

			if goWay and goWay > 0 then
				self.btnGo_:SetActive(true)
				self.btnAward_:SetActive(false)
			else
				self.btnGo_:SetActive(false)
				self.btnAward_:SetActive(true)
				xyd.applyChildrenGrey(self.btnAward_.gameObject)

				self.btnAward_box_.enabled = false
			end

			local can_get_point = xyd.tables.activityTimeMissionTable:getPoint(id)

			if can_get_point and can_get_point > 0 then
				self.btnGoPointCon:SetActive(true)

				self.btnGoPointLabel.text = "+" .. can_get_point

				self.btnGoPointCon_layout:Reposition()
				self.btnAward_:Y(-13.6)
				self.btnGo_:Y(-13.6)
			else
				self.btnAward_:Y(-0.6)
				self.btnGo_:Y(-0.6)
			end
		end
	end
end

function ActivityTimeMissionItem:updateGetAwardState(id)
	if self.id ~= id then
		return
	else
		self:updateState(id)
	end
end

return ActivityTimeMission
