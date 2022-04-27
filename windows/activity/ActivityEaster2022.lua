local ActivityEaster2022 = class("ActivityEaster2022", import(".ActivityContent"))
local ActivityEaster2022Item = class("ActivityEaster2022Item", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivityEaster2022:ctor(parentGO, params)
	ActivityEaster2022.super.ctor(self, parentGO, params)
end

function ActivityEaster2022:getPrefabPath()
	return "Prefabs/Windows/activity/activity_easter2022"
end

function ActivityEaster2022:resizeToParent()
	ActivityEaster2022.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874

	self:resizePosY(self.bottomGroup, -860, -1023)
	self:resizePosY(self.easterGroup1, 414, 389)
	self:resizePosY(self.easterGroup2, 261, 219)
	self:resizePosY(self.easterGroup3, 114, 56)
	self:resizePosY(self.easterGroup4, -34, -112)
end

function ActivityEaster2022:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_EASTER2022)
	self.resource1 = self.activityData:getResource1()
	self.resource2 = self.activityData:getResource2()

	self:getUIComponent()
	ActivityEaster2022.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityEaster2022:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.titleImg_ = self.groupAction:ComponentByName("titleImg_", typeof(UISprite))
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
	self.btnAwardPreview = self.groupAction:NodeByName("btnAwardPreview").gameObject
	self.btnTask = self.groupAction:NodeByName("btnTask").gameObject
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.item = self.midGroup:NodeByName("item").gameObject
	self.clickMask = self.midGroup:NodeByName("clickMask").gameObject

	for i = 1, 4 do
		self["easterGroup" .. i] = self.midGroup:NodeByName("easterGroup" .. i).gameObject
	end

	for i = 1, 6 do
		self["effectPos" .. i] = self.midGroup:NodeByName("effectGroup/effectPos" .. i).gameObject
	end

	self.knockEffectPos = self.midGroup:NodeByName("effectGroup/knockEffectPos").gameObject
	self.gunEffectPos = self.midGroup:NodeByName("effectGroup/gunEffectPos").gameObject
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.resourcesGroup = self.bottomGroup:NodeByName("resourcesGroup").gameObject
	self.resourceGroup1 = self.resourcesGroup:NodeByName("resourceGroup1").gameObject
	self.iconResource1 = self.resourceGroup1:ComponentByName("icon", typeof(UISprite))
	self.addBtn1 = self.resourceGroup1:NodeByName("addBtn").gameObject
	self.resourceGroup2 = self.resourcesGroup:NodeByName("resourceGroup2").gameObject
	self.iconResource2 = self.resourceGroup2:ComponentByName("icon", typeof(UISprite))
	self.addBtn2 = self.resourceGroup2:NodeByName("addBtn").gameObject
	self.awardProgressGroup = self.bottomGroup:NodeByName("awardProgressGroup").gameObject
	self.progressAwardClickMask = self.awardProgressGroup:NodeByName("clickMask").gameObject
	self.iconPos = self.awardProgressGroup:NodeByName("iconPos").gameObject
	self.btnAwardProgress = self.awardProgressGroup:NodeByName("btnAwardProgress").gameObject
	self.labelNextAward = self.awardProgressGroup:ComponentByName("labelNextAward", typeof(UILabel))
end

function ActivityEaster2022:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:updateResGroup()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = json.decode(data.detail)

		if data.activity_id == xyd.ActivityID.ACTIVITY_EASTER2022 then
			if detail.award_type == 3 then
				self:onGetProgressAwardMsg(event)
			else
				self:onGetMsg(event)
			end
		end
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, function (event)
		local id = event.data.act_info.activity_id

		if id == xyd.ActivityID.ACTIVITY_EASTER2022 then
			self:updateRedPoint()

			local win = xyd.WindowManager.get():getWindow("common_activity_task_window")

			if win and win:getWndType() == "ActivityEaster2022" then
				local all_info = {}
				local ids = xyd.tables.activityEaster2022MissionTable:getIDs()

				for i = 1, #ids do
					local id = ids[i]
					local info = {
						id = id,
						desc = string.format(xyd.tables.activityEaster2022MissionTextTable:getDesc(id), xyd.tables.activityEaster2022MissionTable:getValue(id)),
						limitNum = xyd.tables.activityEaster2022MissionTable:getLimit(id),
						curCompleteNum = self.activityData:getCompleteValue(id),
						progressLimitValue = xyd.tables.activityEaster2022MissionTable:getValue(id),
						curProgressValue = self.activityData:getCurProgressValue(id),
						awards = xyd.tables.activityEaster2022MissionTable:getAwrads(id)
					}

					if info.limitNum <= info.curCompleteNum then
						info.state = 2
					else
						info.state = 1
					end

					table.insert(all_info, info)
				end

				win:updateAllInfo(all_info)
			end
		end
	end)

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_EASTER2022_HELP"
		})
	end

	UIEventListener.Get(self.addBtn1).onClick = function ()
		local data = self.activityData:getResource1()

		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			activityData = self.activityData.detail,
			itemID = data[1],
			activityID = xyd.ActivityID.ACTIVITY_EASTER2022
		})
	end

	UIEventListener.Get(self.addBtn2).onClick = function ()
		local all_info = {}
		local ids = xyd.tables.activityEaster2022MissionTable:getIDs()

		for i = 1, #ids do
			local id = ids[i]
			local info = {
				id = id,
				desc = string.format(xyd.tables.activityEaster2022MissionTextTable:getDesc(id), xyd.tables.activityEaster2022MissionTable:getValue(id)),
				limitNum = xyd.tables.activityEaster2022MissionTable:getLimit(id),
				curCompleteNum = self.activityData:getCompleteValue(id),
				progressLimitValue = xyd.tables.activityEaster2022MissionTable:getValue(id),
				curProgressValue = self.activityData:getCurProgressValue(id),
				awards = xyd.tables.activityEaster2022MissionTable:getAwrads(id)
			}

			if info.limitNum <= info.curCompleteNum then
				info.state = 2
			else
				info.state = 1
			end

			table.insert(all_info, info)
		end

		xyd.openWindow("common_activity_task_window", {
			if_sort = true,
			wnd_type = "ActivityEaster2022",
			all_info = all_info,
			title_text = __("MISSION"),
			clickBgCallback = function (id)
				local wayID = xyd.tables.activityEaster2022MissionTable:getGetway(id)

				if wayID and wayID > 0 then
					xyd.goWay(wayID, nil, , function ()
						xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_EASTER2022)
					end)
				end

				xyd.closeWindow("common_activity_task_window")
			end
		})
	end

	UIEventListener.Get(self.btnAwardProgress).onClick = function ()
		self:clickBtnAwardProgress()
	end

	UIEventListener.Get(self.progressAwardClickMask.gameObject).onClick = function ()
		local ids = xyd.tables.activityEaster2022AwardsTable:getIDs()

		for j in pairs(ids) do
			local data = {
				id = j,
				max_value = xyd.tables.activityEaster2022AwardsTable:getPoint(j),
				cur_value = self.activityData:getCurPoint()
			}

			if data.max_value < data.cur_value then
				data.cur_value = data.max_value
			end

			if self.activityData:getProgressAwardRecord(j) == 0 and data.cur_value == data.max_value then
				data.state = 1

				self:getProgressAward(data.id)
				self.progressAwardClickMask:SetActive(false)

				return
			end
		end
	end

	UIEventListener.Get(self.iconResource1.gameObject).onClick = function ()
		self:clickBtnAward(1)
	end

	UIEventListener.Get(self.iconResource2.gameObject).onClick = function ()
		self:clickBtnAward(2)
	end

	UIEventListener.Get(self.btnTask).onClick = function ()
		local all_info = {}
		local ids = xyd.tables.activityEaster2022MissionTable:getIDs()

		for i = 1, #ids do
			local id = ids[i]
			local info = {
				id = id,
				desc = string.format(xyd.tables.activityEaster2022MissionTextTable:getDesc(id), xyd.tables.activityEaster2022MissionTable:getValue(id)),
				limitNum = xyd.tables.activityEaster2022MissionTable:getLimit(id),
				curCompleteNum = self.activityData:getCompleteValue(id),
				progressLimitValue = xyd.tables.activityEaster2022MissionTable:getValue(id),
				curProgressValue = self.activityData:getCurProgressValue(id),
				awards = xyd.tables.activityEaster2022MissionTable:getAwrads(id)
			}

			if info.limitNum <= info.curCompleteNum then
				info.state = 2
			else
				info.state = 1
			end

			table.insert(all_info, info)
		end

		xyd.db.misc:setValue({
			key = "activity_easter2022_task_time_stamp",
			value = xyd.getServerTime()
		})
		self:updateRedPoint()
		xyd.openWindow("common_activity_task_window", {
			if_sort = true,
			wnd_type = "ActivityEaster2022",
			all_info = all_info,
			title_text = __("MISSION"),
			clickBgCallback = function (id)
				local wayID = xyd.tables.activityEaster2022MissionTable:getGetway(id)

				if wayID and wayID > 0 then
					xyd.goWay(wayID, nil, , function ()
						xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_EASTER2022)
					end)
				end

				xyd.closeWindow("common_activity_task_window")
			end
		})
	end

	UIEventListener.Get(self.btnAwardPreview).onClick = function ()
		local data1 = {}
		local data2 = {}
		local dropBoxID = xyd.tables.miscTable:getNumber("activity_easter2022_dropbox2", "value")
		local ids = xyd.tables.dropboxShowTable:getIdsByBoxId(dropBoxID).list

		for i = 1, #ids do
			table.insert(data1, xyd.tables.dropboxShowTable:getItem(ids[i]))
		end

		dropBoxID = xyd.tables.miscTable:getNumber("activity_easter2022_dropbox1", "value")
		ids = xyd.tables.dropboxShowTable:getIdsByBoxId(dropBoxID).list

		for i = 1, #ids do
			table.insert(data2, xyd.tables.dropboxShowTable:getItem(ids[i]))
		end

		local params = {
			groupTitleText1 = __("ACTIVITY_EASTER2022_TEXT07"),
			awardData1 = data1,
			groupTitleText2 = __("ACTIVITY_EASTER2022_TEXT08"),
			awardData2 = data2,
			winTitleText = __("ACTIVITY_AWARD_PREVIEW_TITLE")
		}

		xyd.openWindow("common_activity_award_preview1_window", params)
	end
end

function ActivityEaster2022:initUIComponent()
	self.resourceGroup1:ComponentByName("icon/label_", typeof(UILabel)).text = "× " .. self.resource1[2]
	self.resourceGroup2:ComponentByName("icon/label_", typeof(UILabel)).text = "× " .. self.resource2[2]
	self.btnTask:ComponentByName("label", typeof(UILabel)).text = __("MISSION")

	xyd.setUISpriteAsync(self.titleImg_, nil, "activity_easter2022_logo_" .. xyd.Global.lang)
	self:updateAwardGroup()
	self:updateResGroup()
	self:updateAwardProgressGroup()
	self:updateRedPoint()
	self:initEffect()
end

function ActivityEaster2022:initEffect()
	if not self.eggEffect then
		self.eggEffect = {}

		for i = 1, 6 do
			self.eggEffect[i] = xyd.Spine.new(self["effectPos" .. i])

			self.eggEffect[i]:setInfo("easter2022_egg2", function ()
				self.eggEffect[i]:play("animation", 0)
				self["effectPos" .. i]:SetActive(false)
			end)
		end
	end

	if not self.knockEffect then
		self.knockEffect = {}
		self.knockEffect = xyd.Spine.new(self.knockEffectPos)

		self.knockEffect:setInfo("easter2022_stone", function ()
			self.knockEffect:play("texiao01", 0)
			self.knockEffectPos:SetActive(false)
		end)
	end

	if not self.gunEffect then
		self.gunEffect = {}
		self.gunEffect = xyd.Spine.new(self.gunEffectPos)

		self.gunEffect:setInfo("easter2022_laser", function ()
			self.gunEffect:play("texiao01", 0)
			self.gunEffectPos:SetActive(false)
		end)
	end
end

function ActivityEaster2022:updateAwardGroup()
	local datas = {}

	for i = 1, 4 do
		for j = 1, 6 do
			local data = self.activityData:getEggData(i, j)

			if not self.awardItems then
				self.awardItems = {}
			end

			if not self.awardItems[i] then
				self.awardItems[i] = {}
			end

			if not self.awardItems[i][j] then
				local awardItemObj = NGUITools.AddChild(self["easterGroup" .. i]:NodeByName("grid").gameObject, self.item)
				self.awardItems[i][j] = ActivityEaster2022Item.new(awardItemObj, self)
			end

			self.awardItems[i][j]:setInfo(data)
		end

		self["easterGroup" .. i]:ComponentByName("grid", typeof(UIGrid)):Reposition()
	end
end

function ActivityEaster2022:updateResGroup()
	local res1Data = self.activityData:getResource1()
	self.resourceGroup1:ComponentByName("label_", typeof(UILabel)).text = xyd.models.backpack:getItemNumByID(res1Data[1])
	local res2Data = self.activityData:getResource2()
	self.resourceGroup2:ComponentByName("label_", typeof(UILabel)).text = xyd.models.backpack:getItemNumByID(res2Data[1])
end

function ActivityEaster2022:updateRedPoint()
	self.btnTask:NodeByName("redPoint").gameObject:SetActive(self.activityData:checkRedMarkOfTask())
	self.activityData:getRedMarkState()
end

function ActivityEaster2022:updateAwardProgressGroup()
	local ids = xyd.tables.activityEaster2022AwardsTable:getIDs()
	local cur_value = tonumber(self.activityData:getCurPoint())
	local nextID = nil
	local finish = false

	for id = 1, #ids do
		local needValue = xyd.tables.activityEaster2022AwardsTable:getPoint(id)

		if self.activityData:getProgressAwardRecord(id) == 0 then
			nextID = id

			if needValue <= cur_value then
				finish = true
			end

			break
		end
	end

	nextID = nextID or #ids

	if nextID then
		local awards = xyd.tables.activityEaster2022AwardsTable:getAwards(nextID)
		local params = {
			notShowGetWayBtn = true,
			scale = 0.7037037037037037,
			uiRoot = self.iconPos,
			itemID = awards[1][1],
			num = awards[1][2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		if self.progressAwardIcon then
			self.progressAwardIcon:SetActive(true)
			self.progressAwardIcon:setInfo(params)
		else
			self.progressAwardIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		end

		if finish then
			self.progressAwardIcon:setEffect(true, "fx_ui_bp_available")
		else
			self.progressAwardIcon:setEffect(false)
		end

		local leftTime = xyd.tables.activityEaster2022AwardsTable:getPoint(nextID) - cur_value

		if finish then
			self.labelNextAward.text = __("ACTIVITY_EASTER2022_TEXT02")
		elseif leftTime > 0 then
			self.labelNextAward.text = __("ACTIVITY_EASTER2022_TEXT01", leftTime)
		else
			self.labelNextAward.text = __("ACTIVITY_EASTER2022_TEXT03")
		end

		self.progressAwardClickMask:SetActive(finish)
	end
end

function ActivityEaster2022:clickBtnAwardProgress()
	local all_info = {}
	local ids = xyd.tables.activityEaster2022AwardsTable:getIDs()

	for j in pairs(ids) do
		local data = {
			id = j,
			max_value = xyd.tables.activityEaster2022AwardsTable:getPoint(j)
		}
		data.name = __("ACTIVITY_EASTER2022_TEXT09", math.floor(data.max_value))
		data.cur_value = self.activityData:getCurPoint()

		if data.max_value < data.cur_value then
			data.cur_value = data.max_value
		end

		data.items = xyd.tables.activityEaster2022AwardsTable:getAwards(j)

		if self.activityData:getProgressAwardRecord(j) == 0 then
			if data.cur_value == data.max_value then
				data.state = 1
			else
				data.state = 2
			end
		else
			data.state = 3
		end

		table.insert(all_info, data)
	end

	xyd.WindowManager.get():openWindow("common_progress_award_window", {
		if_sort = true,
		all_info = all_info,
		title_text = __("LIMIT_TIME_CALL_AWARD"),
		click_callBack = function (info)
			if self.activityData:getEndTime() <= xyd.getServerTime() then
				xyd.alertTips(__("ACTIVITY_END_YET"))

				return
			end

			self:getProgressAward(info.id)
		end,
		wnd_type = xyd.CommonProgressAwardWindowType.ACTIVITY_EASTER2022
	})
end

function ActivityEaster2022:clickBtnAward(type)
	local singleCost = nil

	if type == 1 then
		singleCost = self.activityData:getResource1()
	elseif type == 2 then
		singleCost = self.activityData:getResource2()
	end

	local resNum = xyd.models.backpack:getItemNumByID(singleCost[1])

	if resNum < singleCost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(singleCost[1])))

		return
	end

	if type == 2 then
		self:getAward(1, type)

		return
	end

	local titleText = ""

	if type == 1 then
		titleText = __("ACTIVITY_EASTER2022_TEXT04")
	else
		titleText = __("ACTIVITY_EASTER2022_TEXT06")
	end

	local singleMaxTime = self.activityData:getSingleDrawLimit(type)
	local canDrawTime = math.floor(resNum / singleCost[2])
	local select_max_num = math.min(canDrawTime, singleMaxTime)
	local timeStamp = xyd.db.misc:getValue("activity_easter2022_use_time_stamp" .. type)

	if timeStamp and xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
		self:getAward(canDrawTime, type)
	else
		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			needTips = true,
			select_max_num = select_max_num,
			show_max_num = select_max_num * singleCost[2],
			select_multiple = singleCost[2],
			icon_info = {
				height = 45,
				width = 45,
				name = xyd.tables.itemTable:getIcon(singleCost[1])
			},
			title_text = titleText,
			explain_text = __("ACTIVITY_EASTER2022_TEXT05"),
			sure_callback = function (num)
				self:getAward(num, type)

				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end
			end,
			labelNeverText = __("ACTIVITY_EASTER2022_TEXT10"),
			hasSelectCallback = function ()
				xyd.db.misc:setValue({
					key = "activity_easter2022_use_time_stamp" .. type,
					value = xyd.getServerTime()
				})
			end
		})
	end
end

function ActivityEaster2022:showAward1(playTime)
	self.effectPos1.gameObject.transform.position = Vector3.New(-1000, 0, 0)

	self.effectPos1:SetActive(true)

	self.knockEffectPos.gameObject.transform.position = Vector3.New(-1000, 0, 0)

	self.knockEffectPos:SetActive(true)

	local row = 0
	local col = 0

	self.clickMask:SetActive(true)

	if self.awardShowSequence then
		self.awardShowSequence:Kill(false)

		self.awardShowSequence = nil
	end

	self.awardShowSequence = self:getSequence()

	if self.playData[playTime] then
		for key, value in pairs(self.playData[playTime]) do
			for i = 1, #value do
				local r = value[i][2]
				local c = value[i][1]

				self.awardItems[r][c]:playAwardEffect(true)

				row = r
				col = c
			end
		end
	end

	self:waitForTime(1, function ()
		self.eggEffect[1]:play("animation", 1, 1, function ()
			local datas = {}

			if self.playData[playTime] then
				for key, value in pairs(self.playData[playTime]) do
					for i = 1, #value do
						local r = value[i][2]
						local c = value[i][1]

						if not datas[r] then
							datas[r] = {}
						end

						table.insert(datas[r], c)
					end
				end
			end

			self.doingMaxTimeRow = 0
			self.doingMaxTime = 0

			for i = 1, 4 do
				if not datas[i] then
					datas[i] = {}
				end

				self:playRoundAnimation1(i, datas[i], playTime, function ()
					if playTime < #self.playData then
						self:showAward1(playTime + 1)
					end
				end)
			end

			self.effectPos1:SetActive(false)
		end)
	end)
	self.knockEffect:play("texiao01", 1, 1, function ()
		self.knockEffectPos:SetActive(false)
		self.awardShowSequence:AppendCallback(function ()
		end)

		if playTime == 1 then
			xyd.itemFloat(self.tempAward)
		end
	end)
end

function ActivityEaster2022:playRoundAnimation1(row, cols, playTime, callback)
	local beginX = self.awardItems[row][1]:getRoot().transform.localPosition.x
	local colRecords = {}
	local helpCount = 1

	for i = 1, 6 do
		colRecords[i] = i

		for j = 1, #cols do
			if i < cols[j] and helpCount <= colRecords[i] then
				colRecords[i] = colRecords[i] + 1
			elseif cols[j] == i then
				colRecords[i] = helpCount
				helpCount = helpCount + 1
			end
		end
	end

	local temp = self.awardItems[row]
	self.awardItems[row] = {}

	for j = 1, 6 do
		local newCol = colRecords[j]
		self.awardItems[row][newCol] = temp[j]

		if newCol < helpCount then
			self.awardItems[row][newCol]:getRoot():X(beginX - 110 * (helpCount - newCol))

			if self.activityData:getEggData(row, newCol) > 0 and (playTime == nil or not self.playData[playTime + 1] or not self.playData[playTime + 1][row] or #self.playData[playTime + 1][row] == 0) then
				self.awardItems[row][newCol]:setInfo(self.activityData:getEggData(row, newCol))
			else
				self.awardItems[row][newCol]:setInfo(0)
			end

			self.awardItems[row][newCol]:getWidget().alpha = 1

			self.awardItems[row][newCol]:setBgAlpha(1)
			self.awardItems[row][newCol]:setLabelNum(false)
		end
	end

	if self["roundSequence" .. row] then
		self["roundSequence" .. row]:Kill(false)

		self["roundSequence" .. row] = nil
	end

	self["roundSequence" .. row] = self:getSequence()

	for j = 1, 6 do
		local oldIndex = 0

		for i = 1, 6 do
			if colRecords[i] == j then
				oldIndex = i

				break
			end
		end

		local desPosX = beginX + 110 * (j - 1)
		local desPosY = self.awardItems[row][j]:getRoot().transform.localPosition.y
		local needTime = math.ceil((desPosX - self.awardItems[row][j]:getRoot().transform.localPosition.x - 10) / 110) * 0.5

		if needTime > 0 then
			self.awardItems[row][j]:setLabelNum(false)

			if self.doingMaxTimeRow < needTime then
				self.doingMaxTimeRow = needTime
				self.doingMaxTimeRow = row
			end

			self["roundSequence" .. row]:Insert(0, self.awardItems[row][j]:getRoot().gameObject.transform:DOLocalRotate(Vector3(0, 0, -360 * needTime / 0.5), needTime, DG.Tweening.RotateMode.FastBeyond360))
			self["roundSequence" .. row]:Insert(0, self.awardItems[row][j]:getRoot().gameObject.transform:DOLocalMove(Vector3(desPosX, desPosY, 0), needTime, false))
		end
	end

	self["roundSequence" .. row]:AppendCallback(function ()
		if row == self.doingMaxTimeRow then
			self.clickMask:SetActive(false)

			for i = 1, 4 do
				for j = 1, 6 do
					self.awardItems[i][j]:setLabelNum(true)
				end
			end

			if callback then
				callback()
			end
		end
	end)
end

function ActivityEaster2022:showAward2(row)
	self.gunEffectPos.transform.position = self.awardItems[row][1]:getIconPosition()

	self.gunEffectPos:X(0)
	self.gunEffectPos:SetActive(true)

	self.doingMaxTimeRow = 0

	for i = 1, 6 do
		self["effectPos" .. i].gameObject.transform.position = Vector3.New(-1000, -1000, 0)

		self["effectPos" .. i]:SetActive(true)
	end

	self.clickMask:SetActive(true)

	if self.awardShowSequence then
		self.awardShowSequence:Kill(false)

		self.awardShowSequence = nil
	end

	self.awardShowSequence = self:getSequence()

	self:waitForTime(0.5, function ()
		for i = 1, 6 do
			self.awardItems[row][i]:setBgAlpha(0.01)
			self.awardItems[row][i]:playAwardEffect(false)
			self.eggEffect[i]:play("animation", 1, 1, function ()
				self["effectPos" .. i]:SetActive(false)

				if i == 6 then
					for j = 1, 4 do
						if j == row then
							xyd.itemFloat(self.tempAward)
							self:playRoundAnimation1(j, {
								1,
								2,
								3,
								4,
								5,
								6
							})
						else
							self:playRoundAnimation1(j, {})
						end
					end
				end
			end)
		end
	end)
	self.gunEffect:play("texiao01", 1, 1, function ()
		self.gunEffectPos:SetActive(false)

		for i = 1, 6 do
		end

		self.awardShowSequence:AppendCallback(function ()
		end)
	end)
end

function ActivityEaster2022:getAward(num, type)
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_EASTER2022, json.encode({
		award_type = type,
		num = num
	}))
end

function ActivityEaster2022:onGetMsg(event)
	local data = event.data
	local detail = json.decode(data.detail)
	local result = detail.result
	local type = detail.award_type
	local specialPos = self.activityData:getTempSpecialPos()
	self.tempAward = {}
	self.tempNormalEggPoses = {}

	if type == 1 then
		for i = 1, #result do
			table.insert(self.tempAward, {
				item_id = result[i].item[1],
				item_num = result[i].item[2]
			})
		end

		self.specialPosOffset = {}
		local oldSpecialPosArr = self.activityData:getOldPosArr()
		local newSpecialPosArr = self.activityData.detail.pos_arr

		for i = 1, 4 do
			self.specialPosOffset[i] = oldSpecialPosArr[i] - newSpecialPosArr[i]
		end

		self.tempRecord = {
			0,
			0,
			0,
			0
		}

		for i = 1, #result do
			self.tempRecord[result[i].xy[2]] = self.tempRecord[result[i].xy[2]] + 1
		end

		self.playTime = 1
		self.playData = {
			{}
		}
		local needHelp = 0
		local canHelp = {
			0,
			0,
			0,
			0
		}
		local leftCount = 0

		for i = 1, 4 do
			self.playData[self.playTime][i] = {}

			if self.specialPosOffset[i] == 0 then
				if newSpecialPosArr[i] == 1 and detail.result[#detail.result].is_big == true and detail.result[#detail.result].xy[2] == i then
					if self.tempRecord[i] > 6 then
						self.playData[1][i] = {
							{
								2,
								i
							},
							{
								3,
								i
							},
							{
								4,
								i
							},
							{
								5,
								i
							},
							{
								6,
								i
							}
						}

						for k = 1, self.tempRecord[i] - 6 do
							local x = 1 + k % 5
							local playTime = math.ceil(k / 5) + 1

							if not self.playData[playTime] then
								self.playData[playTime] = {}
							end

							if not self.playData[playTime][i] then
								self.playData[playTime][i] = {}
							end

							table.insert(self.playData[playTime][i], {
								x,
								i
							})
						end

						table.insert(self.playData[math.ceil((self.tempRecord[i] - 6) / 5) + 1][i], {
							6,
							i
						})
					else
						table.insert(self.playData[1][i], {
							oldSpecialPosArr[i],
							i
						})

						for k = 1, 6 do
							if k ~= oldSpecialPosArr[i] and #self.playData[1][i] < self.tempRecord[i] then
								table.insert(self.playData[1][i], {
									k,
									i
								})
							end
						end
					end
				elseif self.tempRecord[i] <= newSpecialPosArr[i] - 1 then
					if newSpecialPosArr[i] - 1 > 0 then
						if self.tempRecord[i] == 1 then
							table.insert(self.playData[1][i], {
								xyd.random(1, newSpecialPosArr[i] - 1, {
									int = true
								}),
								i
							})
						else
							for k = 1, self.tempRecord[i] do
								table.insert(self.playData[1][i], {
									k,
									i
								})
							end
						end
					end
				else
					for k = 1, self.tempRecord[i] do
						local x = 1 + k % (newSpecialPosArr[i] - 1)
						local playTime = math.ceil(k / (newSpecialPosArr[i] - 1))

						if not self.playData[playTime] then
							self.playData[playTime] = {}
						end

						if not self.playData[playTime][i] then
							self.playData[playTime][i] = {}
						end

						table.insert(self.playData[playTime][i], {
							x,
							i
						})
					end
				end
			elseif self.specialPosOffset[i] > 0 then
				if self.tempRecord[i] > 6 then
					for k = 1, 6 do
						if k ~= oldSpecialPosArr[i] then
							table.insert(self.playData[1][i], {
								k,
								i
							})
						end
					end

					for k = 1, self.tempRecord[i] - 6 do
						local x = 1 + k % 5
						local playTime = math.ceil(k / 5) + 1

						if not self.playData[playTime] then
							self.playData[playTime] = {}
						end

						if not self.playData[playTime][i] then
							self.playData[playTime][i] = {}
						end

						table.insert(self.playData[playTime][i], {
							x,
							i
						})
					end

					table.insert(self.playData[math.ceil((self.tempRecord[i] - 6) / 5) + 1][i], {
						6,
						i
					})
				else
					table.insert(self.playData[1][i], {
						oldSpecialPosArr[i],
						i
					})

					for k = 1, 6 do
						if k ~= oldSpecialPosArr[i] and #self.playData[1][i] < self.tempRecord[i] then
							table.insert(self.playData[1][i], {
								k,
								i
							})
						end
					end
				end
			else
				if self.tempRecord[i] == 1 then
					table.insert(self.playData[1][i], {
						xyd.random(oldSpecialPosArr[i] + 1, 6, {
							int = true
						}),
						i
					})
				else
					for k = 6, 7 - (newSpecialPosArr[i] - oldSpecialPosArr[i]), -1 do
						table.insert(self.playData[1][i], {
							k,
							i
						})
					end
				end

				local left = self.tempRecord[i] - (newSpecialPosArr[i] - oldSpecialPosArr[i])

				for k = 1, math.min(left, oldSpecialPosArr[i] - 1) do
					table.insert(self.playData[1][i], {
						k,
						i
					})
				end

				if left > oldSpecialPosArr[i] - 1 then
					for k = 1, left - (oldSpecialPosArr[i] - 1) do
						local x = 1 + k % (newSpecialPosArr[i] - 1)
						local playTime = math.ceil(k / (newSpecialPosArr[i] - 1)) + 1

						if not self.playData[playTime] then
							self.playData[playTime] = {}
						end

						if not self.playData[playTime][i] then
							self.playData[playTime][i] = {}
						end

						table.insert(self.playData[playTime][i], {
							x,
							i
						})
					end
				end
			end
		end

		self:showAward1(1)
	else
		for i = 1, #result[1].items do
			local row = result[1].y
			local col = 1

			if row ~= specialPos[2] or col ~= specialPos[1] then
				table.insert(self.tempNormalEggPoses, {
					col,
					row
				})
			end

			table.insert(self.tempAward, {
				item_id = result[1].items[i][1],
				item_num = result[1].items[i][2]
			})
		end

		self:showAward2(specialPos[2], specialPos[1])
	end

	self:updateAwardProgressGroup()
	self:updateRedPoint()
end

function ActivityEaster2022:getProgressAward(tableID)
	self.award_id = tableID

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_EASTER2022, json.encode({
		award_type = 3,
		award_id = tableID
	}))
end

function ActivityEaster2022:onGetProgressAwardMsg(event)
	local awards = xyd.tables.activityEaster2022AwardsTable:getAwards(self.award_id)
	local infos = {}

	for i = 1, #awards do
		table.insert(infos, {
			item_id = awards[i][1],
			item_num = awards[i][2]
		})
	end

	xyd.models.itemFloatModel:pushNewItems(infos)

	local common_progress_award_window_wn = xyd.WindowManager.get():getWindow("common_progress_award_window")

	if common_progress_award_window_wn and common_progress_award_window_wn:getWndType() == xyd.CommonProgressAwardWindowType.ACTIVITY_EASTER2022 then
		common_progress_award_window_wn:updateItemState(tonumber(self.award_id), 3)
	end

	self:updateAwardProgressGroup()
	self:updateRedPoint()
end

function ActivityEaster2022:dispose()
	ActivityEaster2022.super.dispose(self)
end

function ActivityEaster2022Item:ctor(go, parent)
	self.go = go
	self.parent = parent

	ActivityEaster2022Item.super.ctor(self, go)
	self:initUI()
end

function ActivityEaster2022Item:initUI()
	self:getUIComponent()
end

function ActivityEaster2022Item:getUIComponent()
	self.iconPos = self.go:NodeByName("iconPos").gameObject
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.eggEffectPos = self.go:ComponentByName("eggEffectPos", typeof(UITexture))
	self.knockEffectPos = self.go:ComponentByName("knockEffectPos", typeof(UITexture))
	self.labelNum = self.go:ComponentByName("labelNum", typeof(UILabel))
end

function ActivityEaster2022Item:setInfo(params)
	if not params then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.tableID = params

	if self.tableID > 0 then
		self.isSpecial = true
		self.award = xyd.tables.dropboxShowTable:getItem(self.tableID)

		xyd.setUISpriteAsync(self.bg, nil, "activity_easter2022_icon_dan2")
		self.iconPos:SetActive(true)

		local params2 = {
			notShowGetWayBtn = true,
			show_has_num = false,
			uiRoot = self.iconPos,
			itemID = self.award[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		if not self.icon then
			self.icon = xyd.getItemIcon(params2, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.icon:setInfo(params2)
		end

		local type = xyd.tables.itemTable:getType(params2.itemID)

		if type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_RANDOM_DEBRIS or type == xyd.ItemType.SKIN then
			self.icon:setScale(0.7037037037037037)
		else
			self.icon:showBorderBg(false)
			self.icon:setScale(0.7962962962962963)
		end

		self.labelNum:SetActive(true)

		self.labelNum.text = "×" .. xyd.getRoughDisplayNumber(self.award[2])
	else
		self.isSpecial = false
		self.award = nil

		xyd.setUISpriteAsync(self.bg, nil, "activity_easter2022_icon_dan1")
		self.labelNum:SetActive(false)
		self.iconPos:SetActive(false)
	end

	if self.award then
		self.item_id = self.award[1]
		self.item_num = self.award[2]
	else
		self.item_id = nil
		self.item_num = nil
	end
end

function ActivityEaster2022Item:getRoot()
	return self.go.gameObject
end

function ActivityEaster2022Item:getIsSpecial()
	return self.isSpecial
end

function ActivityEaster2022Item:getIconPosition()
	return self.iconPos.gameObject.transform.position
end

function ActivityEaster2022Item:getWidget()
	return self.go:ComponentByName("", typeof(UIWidget))
end

function ActivityEaster2022Item:setBgAlpha(num)
	self.bg.alpha = num
end

function ActivityEaster2022Item:setLabelNum(flag)
	if self.isSpecial then
		self.labelNum:SetActive(flag)
	end
end

function ActivityEaster2022Item:playAwardEffect(needResEffect)
	local function callback()
		if self.isSpecial then
			if self.eggEffect1 then
				self.eggEffect1:SetActive(false)
			end

			if not self.eggEffect2 then
				self.eggEffectPos:SetActive(true)

				self.eggEffect2 = xyd.Spine.new(self.eggEffectPos.gameObject)

				self.eggEffect2:setInfo("easter2022_egg2", function ()
					self.bg.alpha = 0.01

					self.eggEffect2:play("animation", 1, 1, function ()
						self.eggEffectPos:SetActive(false)
					end)
				end)
			else
				self.eggEffect2:SetActive(true)
				self.eggEffectPos:SetActive(true)

				self.bg.alpha = 0.01

				self.eggEffect2:play("animation", 1, 1, function ()
					self.eggEffectPos:SetActive(false)
				end)
			end
		else
			if self.eggEffect2 then
				self.eggEffect2:SetActive(false)
			end

			if not self.eggEffect1 then
				self.eggEffectPos:SetActive(true)

				self.eggEffect1 = xyd.Spine.new(self.eggEffectPos.gameObject)

				self.eggEffect1:setInfo("easter2022_egg1", function ()
					self.bg.alpha = 0.01

					self.eggEffect1:play("animation", 1, 1, function ()
						self.eggEffectPos:SetActive(false)
					end)
				end)
			else
				self.eggEffect1:SetActive(true)
				self.eggEffectPos:SetActive(true)

				self.bg.alpha = 0.01

				self.eggEffect1:play("animation", 1, 1, function ()
					self.eggEffectPos:SetActive(false)
				end)
			end
		end
	end

	if needResEffect then
		if not self.knockEffect then
			self.knockEffectPos:SetActive(true)

			self.knockEffect = xyd.Spine.new(self.knockEffectPos.gameObject)

			self.knockEffect:setInfo("easter2022_stone", function ()
				self.knockEffect:play("texiao01", 1, 1, function ()
					self.knockEffectPos:SetActive(false)
				end)
				self.parent:waitForTime(1, function ()
					callback()
				end)
			end)
		else
			self.knockEffectPos:SetActive(true)
			self.knockEffect:play("texiao01", 1, 1, function ()
				self.knockEffectPos:SetActive(false)
			end)
			self.parent:waitForTime(1, function ()
				callback()
			end)
		end
	else
		callback()
	end
end

return ActivityEaster2022
