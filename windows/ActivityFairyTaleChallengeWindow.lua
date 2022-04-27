local ActivityFairyTaleChallengeWindow = class("ActivityFairyTaleChallengeWindow", import(".BaseWindow"))
local FairyTaleMissionItem = class("FairyTaleMissionItem", import("app.components.CopyComponent"))
local ChooseBuffItem = class("ChooseBuffItem", import("app.components.CopyComponent"))
local GroupBuffIcon = import("app.components.GroupBuffIcon")
local GroupBuffIconItem = class("GroupBuffIconItem")
local buffIcon = class("buffIcon", import("app.components.CopyComponent"))
local CommonTabBar = require("app.common.ui.CommonTabBar")
local json = require("cjson")
local allWinTrans = nil

function GroupBuffIconItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.groupBuffIcon = GroupBuffIcon.new(self.go, self.parent.buffRenderPanel)

	self.groupBuffIcon:setDragScrollView(self.parent.buffScrollView)

	UIEventListener.Get(self.groupBuffIcon:getGameObject()).onPress = function (go, isPress)
		if isPress then
			local win = xyd.WindowManager.get():getWindow("group_buff_detail_window")

			if win then
				xyd.WindowManager.get():closeWindow("group_buff_detail_window", function ()
					XYDCo.WaitForTime(1, function ()
						local params = {
							buffID = self.info_.buffId,
							type = self.info_.type_
						}

						xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
					end, nil)
				end)
			else
				local params = {
					buffID = self.info_.buffId,
					type = self.info_.type_
				}

				xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
			end
		else
			xyd.WindowManager.get():closeWindow("group_buff_detail_window")
		end
	end
end

function GroupBuffIconItem:getGameObject()
	return self.go
end

function GroupBuffIconItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	if not self.groupBuffIcon then
		self.groupBuffIcon = GroupBuffIcon.new(self.go, self.parent.buffRenderPanel)
	end

	self.groupBuffIcon:setInfo(info.buffId, info.isAct >= 0, info.type_)

	self.info_ = info

	self.go:SetActive(true)
end

function GroupBuffIconItem:getGameObject()
	return self.go
end

function ActivityFairyTaleChallengeWindow:ctor(name, params)
	ActivityFairyTaleChallengeWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)
	self.lev_ = self.activityData.detail.lv
	self.currentSelect_ = 0
	self.contentList_ = {}
	self.missionItemList_ = {}
	self.chooseBuffItemList_ = {}
end

function ActivityFairyTaleChallengeWindow:initWindow()
	ActivityFairyTaleChallengeWindow.super.initWindow(self)
	self:getComponent()
	self:regisetr()

	self.winTitle_.text = __("FAIRY_TALE_CHALLENGE_LEVEL")
	self.levTips_.text = __("FAIRY_TALE_WAR_LEVEL")

	self:onActivityByID()
end

function ActivityFairyTaleChallengeWindow:onActivityByID()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)
	self.lev_ = self.activityData.detail.lv

	self:initNav()
	self:onClickNav(1)
	self:refreshLevInfoPart()
	self:updateMissionRed()
end

function ActivityFairyTaleChallengeWindow:getComponent()
	allWinTrans = self.window_.transform
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.winTitle_ = winTrans:ComponentByName("winTitle", typeof(UILabel))
	self.navGroup_ = winTrans:NodeByName("navGroup").gameObject
	self.buffRedPoint_ = self.navGroup_:NodeByName("tab_2/redPoint").gameObject
	local levShowGroup = winTrans:NodeByName("levShowGroup")
	self.levNum_ = levShowGroup:ComponentByName("levIcon/levNum", typeof(UILabel))
	self.levProgress_ = levShowGroup:ComponentByName("progressBar", typeof(UIProgressBar))
	self.levProgressLabel_ = levShowGroup:ComponentByName("labelNum", typeof(UILabel))
	self.levTips_ = levShowGroup:ComponentByName("levTips", typeof(UILabel))
	self.missionGroup_ = winTrans:NodeByName("missionGroup").gameObject
	self.scrollViewMission_ = self.missionGroup_:ComponentByName("scrollViewMission", typeof(UIScrollView))
	self.gridMission_ = self.missionGroup_:ComponentByName("scrollViewMission/grid", typeof(UIGrid))
	self.missionItemRoot_ = self.missionGroup_:NodeByName("missionItem").gameObject
	self.emptyText = self.missionGroup_:ComponentByName("emptyText", typeof(UILabel))
	self.buffChooseGroup_ = winTrans:NodeByName("buffChooseGroup").gameObject
	self.scrollViewBuff_ = self.buffChooseGroup_:ComponentByName("buffGroup/scrollViewBuff", typeof(UIScrollView))
	self.gridBuffList_ = self.buffChooseGroup_:ComponentByName("buffGroup/scrollViewBuff/grid", typeof(UIWrapContent))
	local buffRoot = self.buffChooseGroup_:NodeByName("buffGroup/buffRoot").gameObject
	self.buffWrapContent = require("app.common.ui.FixedWrapContent").new(self.scrollViewBuff_, self.gridBuffList_, buffRoot, GroupBuffIconItem, self)
	self.scrollViewBuffChoose_ = self.buffChooseGroup_:ComponentByName("buffListScroll", typeof(UIScrollView))
	self.gridBuffChoose_ = self.buffChooseGroup_:ComponentByName("buffListScroll/grid", typeof(UIGrid))
	self.chooseBuffItemRoot_ = self.buffChooseGroup_:NodeByName("chooseBuffItem").gameObject
	self.contentList_[1] = self.missionGroup_
	self.contentList_[2] = self.buffChooseGroup_
end

function ActivityFairyTaleChallengeWindow:updateMissionRed()
	local lev = self.activityData.detail.lv
	local buff_ids = self.activityData.detail.buff_ids
	local isRed = false

	if lev >= 3 then
		for i = 3, lev do
			if #buff_ids[i] <= 0 then
				isRed = true
			end
		end
	end

	self.buffRedPoint_:SetActive(isRed)
end

function ActivityFairyTaleChallengeWindow:initNav()
	local index = 2
	local labelText = {
		__("FAIRY_TALE_CHALLENGE_MISSION"),
		__("FAIRY_TALE_BATTLE_BUFF")
	}
	local labelStates = {
		chosen = {
			color = Color.New2(4294967295.0),
			effectColor = Color.New2(2606316799.0)
		},
		unchosen = {
			color = Color.New2(1985431807),
			effectColor = Color.New2(4294967295.0)
		}
	}
	self.tab = CommonTabBar.new(self.navGroup_.gameObject, index, function (index)
		self:onClickNav(index)
	end, nil, labelStates)

	self.tab:setTexts(labelText)
end

function ActivityFairyTaleChallengeWindow:onClickNav(index)
	if self.currentSelect_ == index then
		return
	else
		self.currentSelect_ = index
	end

	for i = 1, 2 do
		self.contentList_[i]:SetActive(i == self.currentSelect_)
	end

	if self.currentSelect_ == 1 then
		self:refreshMissionPart()
	else
		self:refreshChooseBuffPart()
	end
end

function ActivityFairyTaleChallengeWindow:regisetr()
	ActivityFairyTaleChallengeWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.eventProxy_:addEventListener(xyd.event.FAIRY_SELECT_BUFF, handler(self, self.onBuffChange))
end

function ActivityFairyTaleChallengeWindow:refreshLevInfoPart()
	self.lev_ = self.activityData.detail.lv
	self.levNum_.text = self.lev_
	self.nowMissionList_ = xyd.tables.activityFairyTaleLevelTable:getMissionIds(self.lev_)
	self.emptyText.text = __("FAIRY_TALE_MISSION_ENPTY")

	if self:isCompleteMission() == false then
		self.emptyText.gameObject:SetActive(false)
		self.scrollViewMission_.gameObject:SetActive(true)

		local progressValue = self:getMissionProgress() or 0
		local value = progressValue / #self.nowMissionList_

		if value > 1 then
			value = 1
		end

		self.levProgress_.value = value
		self.levProgressLabel_.text = __("FAIRY_TALE_EXP", progressValue, #self.nowMissionList_)
	else
		self.levProgress_.value = 1
		self.levProgressLabel_.text = __("FAIRY_TALE_EXP", "--", "--")

		self.emptyText.gameObject:SetActive(true)
		self.scrollViewMission_.gameObject:SetActive(false)
	end
end

function ActivityFairyTaleChallengeWindow:getMissionProgress()
	local value = 0

	for _, missionId in ipairs(self.nowMissionList_) do
		for i in pairs(self.activityData.detail.mission_infos) do
			if self.activityData.detail.mission_infos[i].table_id == missionId and self.activityData.detail.mission_infos[i].is_completed == 1 then
				value = value + 1
			end
		end
	end

	return value
end

function ActivityFairyTaleChallengeWindow:isCompleteMission()
	if not self.activityData.detail.mission_infos or self.activityData.detail.mission_infos == nil or type(self.activityData.detail.mission_infos) == "userdata" or #self.activityData.detail.mission_infos == 0 or self.nowMissionList_ == nil or #self.nowMissionList_ == 0 then
		return true
	end

	return false
end

function ActivityFairyTaleChallengeWindow:refreshMissionPart(keepPosition)
	self.nowMissionList_ = xyd.tables.activityFairyTaleLevelTable:getMissionIds(self.lev_)

	if self:isCompleteMission() then
		self.emptyText.gameObject:SetActive(true)
		self.scrollViewMission_.gameObject:SetActive(false)

		self.levProgress_.value = 1
		self.levProgressLabel_.text = __("FAIRY_TALE_EXP", "--", "--")
	else
		local missionParamsArr = {}

		for i = 1, #self.nowMissionList_ do
			local params = {
				id = self.nowMissionList_[i]
			}

			for j in pairs(self.activityData.detail.mission_infos) do
				if self.activityData.detail.mission_infos[j].table_id == self.nowMissionList_[i] then
					params.value = self.activityData.detail.mission_infos[j].value
					params.is_completed = self.activityData.detail.mission_infos[j].is_completed

					table.insert(missionParamsArr, params)

					break
				end
			end

			if not self.missionItemList_[i] then
				local newRoot = NGUITools.AddChild(self.gridMission_.gameObject, self.missionItemRoot_)

				newRoot:SetActive(true)

				self.missionItemList_[i] = FairyTaleMissionItem.new(newRoot, self)
			end
		end

		table.sort(missionParamsArr, function (a, b)
			if a.is_completed == b.is_completed then
				return a.id < b.id
			end

			return a.is_completed < b.is_completed
		end)

		for i in pairs(missionParamsArr) do
			self.missionItemList_[i]:setInfo(missionParamsArr[i])
		end

		self.gridMission_:Reposition()

		if not keepPosition then
			self.scrollViewMission_:ResetPosition()
		end
	end
end

function ActivityFairyTaleChallengeWindow:refreshChooseBuffPart()
	self:refreshAllBuff()
	self:refreshBuffShowList()
	self:refreshBuffChooseList()
end

function ActivityFairyTaleChallengeWindow:refreshAllBuff()
	local buffList = self.activityData.detail.buff_ids
	local buffIds = {}

	for _, ids in pairs(buffList) do
		if ids ~= nil and type(ids) ~= "userdata" then
			for _, id in pairs(ids) do
				table.insert(buffIds, id)
			end
		end
	end

	self.choosenBuffs_ = buffIds
end

function ActivityFairyTaleChallengeWindow:refreshBuffShowList(keepPosition)
	local buffIds = xyd.tables.activityFairyTaleBuffTable:getShowIds()
	local buffInfos = {}
	local isActices = {}

	for i = 1, #buffIds do
		print("測試初始化的id:", buffIds[i])

		local params = {
			buffId = buffIds[i],
			type_ = xyd.GroupBuffIconType.FAIRY_TALE,
			isAct = self:checkisAct(buffIds[i])
		}

		if params.isAct >= 0 then
			table.insert(isActices, params)
		else
			table.insert(buffInfos, params)
		end
	end

	table.sort(isActices, function (a, b)
		return a.isAct < b.isAct
	end)
	table.sort(buffInfos, function (a, b)
		return a.buffId < b.buffId
	end)

	for i in pairs(buffInfos) do
		table.insert(isActices, buffInfos[i])
	end

	self.buffWrapContent:setInfos(isActices, {
		keepPosition = keepPosition
	})
end

function ActivityFairyTaleChallengeWindow:checkisAct(id)
	return xyd.arrayIndexOf(self.choosenBuffs_, id)
end

function ActivityFairyTaleChallengeWindow:refreshBuffChooseList(keepPosition)
	self.lev_ = self.activityData.detail.lv
	local levIds = xyd.tables.activityFairyTaleLevelTable:getIds()

	for i = 2, #levIds do
		if not self.chooseBuffItemList_[i] then
			local itemRoot = NGUITools.AddChild(self.gridBuffChoose_.gameObject, self.chooseBuffItemRoot_)

			itemRoot:SetActive(true)

			self.chooseBuffItemList_[i] = ChooseBuffItem.new(itemRoot, self)
		end

		self.chooseBuffItemList_[i]:setInfo(levIds[i])
	end

	self.gridBuffChoose_:Reposition()

	if not keepPosition then
		self.scrollViewBuffChoose_:ResetPosition()
	end

	self.chooseBuffItemRoot_:SetActive(false)
end

function ActivityFairyTaleChallengeWindow:getChooseBuffStatus(levID)
	if self.activityData.detail.buff_ids[levID] ~= nil and type(self.activityData.detail.buff_ids[levID]) ~= "userdata" then
		local choosenBuff = self.activityData.detail.buff_ids[levID][1]
		local buffCanChoose = xyd.tables.activityFairyTaleLevelTable:getSkillIds(levID)

		if choosenBuff and choosenBuff > 0 then
			return xyd.checkCondition(xyd.arrayIndexOf(buffCanChoose, choosenBuff) >= 0, choosenBuff, -1)
		end
	end

	return -1
end

function ActivityFairyTaleChallengeWindow:onBuffChange(event)
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)

	self:refreshAllBuff()
	self:refreshBuffShowList(true)
	self:refreshBuffChooseList(true)
	self:updateMissionRed()
end

function FairyTaleMissionItem:ctor(Go, parent)
	self.parent_ = parent

	FairyTaleMissionItem.super.ctor(self, Go)
end

function FairyTaleMissionItem:initUI()
	FairyTaleMissionItem.super.initUI(self)
	self:getComponent()
	self:regisetr()
end

function FairyTaleMissionItem:getComponent()
	local goTrans = self.go.transform
	self.nameLabel_ = goTrans:ComponentByName("missionName", typeof(UILabel))
	self.missionProgress_ = goTrans:ComponentByName("progressBar", typeof(UIProgressBar))
	self.missionProgressLabel_ = goTrans:ComponentByName("progressBar/labelNum", typeof(UILabel))
	self.goBtn_ = goTrans:NodeByName("btnGo").gameObject
	self.goBtnBox_ = goTrans:ComponentByName("btnGo", typeof(UnityEngine.BoxCollider))
	self.goBtnLabel_ = goTrans:ComponentByName("btnGo/labelBtn", typeof(UILabel))
end

function FairyTaleMissionItem:setInfo(params)
	self.id_ = params.id
	self.value_ = params.value or 0
	self.completeValue_ = xyd.tables.activityFairyTaleMissionTable:getCompleteValue(self.id_)
	self.nameLabel_.text = __(xyd.tables.activityFairyTaleMissionTable:getName(self.id_))
	self.missionProgress_.value = xyd.checkCondition(self.value_ / self.completeValue_ > 1, 1, self.value_ / self.completeValue_)
	self.missionProgressLabel_.text = xyd.checkCondition(self.completeValue_ < self.value_, self.completeValue_, self.value_) .. "/" .. self.completeValue_

	if self.completeValue_ <= self.value_ then
		self.goBtnBox_.enabled = false
		self.goBtnLabel_.text = __("PUB_MISSION_COMPLETE")
	else
		self.goBtnBox_.enabled = true
		self.goBtnLabel_.text = __("GO")
	end
end

function FairyTaleMissionItem:regisetr()
	UIEventListener.Get(self.goBtn_).onClick = function ()
		if self.value_ < self.completeValue_ then
			local mapWin = xyd.WindowManager.get():getWindow("activity_fairy_tale_map")
			local type = xyd.tables.activityFairyTaleMissionTable:getMissionType(self.id_)

			if type == 6 then
				if mapWin then
					mapWin:openStoryWindow()
					xyd.WindowManager.get():closeWindow(self.parent_.name_)
				end
			elseif type == 8 then
				if mapWin.mapId_ == 6 then
					local cellId = mapWin:getTargetCell(type)

					if cellId then
						local cellType = xyd.tables.activityFairyTaleCellTable:getCellType(cellId)

						xyd.WindowManager.get():openWindow("activity_fairy_tale_cell_detail_window", {
							map_id = mapWin.mapId_,
							cellType = cellType,
							cell_id = cellId
						})
						xyd.WindowManager.get():closeWindow(self.parent_.name_)
					else
						xyd.showToast(__("FAIRY_TALE_MISSION_TIPS1"))
					end
				else
					xyd.showToast(__("FAIRY_TALE_MISSION_TIPS2"))
				end
			else
				local cellId = mapWin:getTargetCell(type)

				if cellId then
					local cellType = xyd.tables.activityFairyTaleCellTable:getCellType(cellId)

					xyd.WindowManager.get():openWindow("activity_fairy_tale_cell_detail_window", {
						map_id = mapWin.mapId_,
						cellType = cellType,
						cell_id = cellId
					})
					xyd.WindowManager.get():closeWindow(self.parent_.name_)
				else
					xyd.showToast(__("FAIRY_TALE_MISSION_TIPS1"))
				end
			end
		end
	end
end

function ChooseBuffItem:ctor(parentGo, parent)
	self.parent_ = parent
	self.skillItemList_ = {}

	ChooseBuffItem.super.ctor(self, parentGo)
end

function ChooseBuffItem:initUI()
	ChooseBuffItem.super.initUI(self)
	self:getComponent()
end

function ChooseBuffItem:getComponent()
	local goTrans = self.go.transform
	self.levNum_ = goTrans:ComponentByName("levImg/levNum", typeof(UILabel))
	self.iconGroup_ = goTrans:ComponentByName("iconGroup", typeof(UIGrid))
	self.potentialRoot_ = goTrans:NodeByName("potential_icon").gameObject
end

function ChooseBuffItem:setInfo(id)
	self.id_ = id
	self.levNum_.text = self.id_
	self.chooseIds_ = xyd.tables.activityFairyTaleLevelTable:getSkillIds(self.id_)
	self.chooseStatus_ = self.parent_:getChooseBuffStatus(self.id_)

	for index, skillId in ipairs(self.chooseIds_) do
		if not self.skillItemList_[index] then
			local iconRoot = NGUITools.AddChild(self.iconGroup_.gameObject, self.potentialRoot_)

			iconRoot:SetActive(true)

			self.skillItemList_[index] = buffIcon.new(iconRoot, self.parent_)
		end

		local params = {
			id = skillId,
			is_active = self.chooseStatus_ == skillId,
			is_lock = self.parent_.lev_ < self.id_,
			level = self.id_,
			type_ = xyd.GroupBuffIconType.FAIRY_TALE,
			buffId = skillId
		}

		self.skillItemList_[index]:setInfo(params)
	end
end

function buffIcon:ctor(parentGo, parent)
	self.parent_ = parent

	buffIcon.super.ctor(self, parentGo)
end

function buffIcon:initUI()
	buffIcon.super.initUI(self)
	self:getComponent()
end

function buffIcon:getComponent()
	local goTrans = self.go.transform
	self.bg_ = goTrans:ComponentByName("bg", typeof(UISprite))
	self.img_ = goTrans:ComponentByName("img", typeof(UISprite))
	self.mask_ = goTrans:NodeByName("mask").gameObject
	self.effectGroup_ = goTrans:NodeByName("effectGroup").gameObject
	self.lockImg_ = goTrans:NodeByName("lockImg").gameObject
	self.activeImg_ = goTrans:NodeByName("activeImg").gameObject
	self.groupPreLoad_ = goTrans:NodeByName("groupPreLoad").gameObject
	self.imgCircle_ = goTrans:NodeByName("groupPreLoad/imgCircle_").gameObject
end

function buffIcon:addClick()
	if not self.info_.is_lock and not self.info_.is_active then
		UIEventListener.Get(self.go).onClick = function ()
			xyd.WindowManager.get():openWindow("potentiality_choose_window", {
				awake_index = 1,
				winNameText = __("FAIRY_TALE_CONFIRM_CHANGE_BUFF"),
				skill_list = {
					self.id_
				},
				type = xyd.ActivityID.FAIRY_TALE,
				callBack = function ()
					local msg = messages_pb:fairy_select_buff_req()
					msg.activity_id = xyd.ActivityID.FAIRY_TALE
					msg.lv = self.info_.level
					local buffIds = xyd.tables.activityFairyTaleLevelTable:getSkillIds(self.info_.level)

					for i in pairs(buffIds) do
						if buffIds[i] == self.id_ then
							msg.select_index = i

							break
						end
					end

					xyd.Backend.get():request(xyd.mid.FAIRY_SELECT_BUFF, msg)
				end
			})
		end
	else
		UIEventListener.Get(self.go).onClick = function ()
			if self.info_.is_lock or self.info_.is_active then
				local win = xyd.WindowManager.get():getWindow("group_buff_detail_window")

				if win then
					xyd.WindowManager.get():closeWindow("group_buff_detail_window", function ()
						XYDCo.WaitForTime(1, function ()
							local params = {
								buffID = self.info_.buffId,
								type = self.info_.type_
							}

							if allWinTrans then
								local posy = allWinTrans.transform:InverseTransformPoint(self.go.transform.position).y
								params.contenty = posy + 50
							end

							xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
						end, nil)
					end)
				else
					local params = {
						buffID = self.info_.buffId,
						type = self.info_.type_
					}

					if allWinTrans then
						local posy = allWinTrans.transform:InverseTransformPoint(self.go.transform.position).y
						params.contenty = posy + 50
					end

					xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
				end
			end
		end
	end
end

function buffIcon:setInfo(params)
	self.id_ = params.id
	self.info_ = params
	self.unlockGrade_ = params.unlockGrade

	if self.id_ == -1 then
		self:setIconSource("potentiality_unknow")
	else
		self:setIconSource(xyd.tables.activityFairyTaleBuffTable:getFx(self.id_))
	end

	self.lockImg_:SetActive(params.is_lock)
	self.activeImg_:SetActive(params.is_active)
	self.mask_:SetActive(params.is_lock or params.is_active == false)
	self:addClick()
end

function buffIcon:active(flag)
	self.activeImg_:SetActive(flag)
end

function buffIcon:setIconSource(source)
	local function action()
		if not self.imgCircle_ then
			self.loadTimer_:Stop()

			return
		end

		local angles = self.imgCircle_.transform.localEulerAngles + Vector3(0, 0, -5)
		self.imgCircle_.transform.localEulerAngles = angles
	end

	self.groupPreLoad_:SetActive(true)

	self.loadTimer_ = self:getTimer(action, 0.1, -1)

	self.loadTimer_:Start()
	xyd.setUISpriteAsync(self.img_, nil, source, function ()
		self.groupPreLoad_:SetActive(false)
		self.loadTimer_:Stop()
	end)
end

return ActivityFairyTaleChallengeWindow
