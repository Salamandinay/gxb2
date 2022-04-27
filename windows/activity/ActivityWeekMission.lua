local ActivityWeekMission = class("ActivityWeekMission", import(".ActivityContent"))
local ActivityWeekMissionItem = class("ActivityWeekMissionItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local json = require("cjson")

function ActivityWeekMission:ctor(parentGo, params, parent)
	self.chosenDay = 1
	self.chosenType = 1

	ActivityWeekMission.super.ctor(self, parentGo, params, parent)
	self.activityData:reqActivity()

	local nowTime = xyd.db.misc:getValue("week_mission_dadian")

	if not nowTime or not xyd.isToday(tonumber(nowTime)) then
		local msg = messages_pb.log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.WEEK_MISSION
		msg.desc = tostring(xyd.Global.playerID)

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
		xyd.db.misc:setValue({
			key = "week_mission_dadian",
			value = xyd.getServerTime()
		})
	end
end

function ActivityWeekMission:getPrefabPath()
	return "Prefabs/Windows/activity/activity_week_mission"
end

function ActivityWeekMission:resizeToParent()
	ActivityWeekMission.super.resizeToParent(self)

	local widget = self.go:GetComponent(typeof(UIWidget))

	if widget.height < 900 then
		self.topGroup:Y(50)
		self.textImg:Y(-150)
		self.middleGroup:Y(-350)
		self.line_:Y(-502)
		self.scrollView_panel:SetRect(0, 30, 530, 477)
		self.scrollView:ResetPosition()
	end
end

function ActivityWeekMission:getUIComponent()
	local go = self.go
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	local topGroup = go:NodeByName("topGroup").gameObject
	self.topGroup = topGroup
	self.textImg = topGroup:ComponentByName("textImg", typeof(UISprite))
	self.timeGroup = topGroup:NodeByName("timeGroup").gameObject
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))

	if xyd.Global.lang == "de_de" then
		self.endLabel.fontSize = 16
		self.timeLabel.fontSize = 16

		self.timeGroup:Y(-210)
	elseif xyd.Global.lang == "en_en" then
		self.timeGroup:Y(-215)
	elseif xyd.Global.lang == "fr_fr" then
		self.endLabel.fontSize = 22
		self.timeLabel.fontSize = 22
	end

	local progerssGroup = topGroup:NodeByName("progressGroup").gameObject
	self.progressBar = progerssGroup:ComponentByName("progressBar", typeof(UIProgressBar))
	self.pointLabel = self.progressBar:ComponentByName("pointLabel", typeof(UILabel))
	self.giftItemList = {}

	for i = 1, 4 do
		local giftItem = progerssGroup:NodeByName("giftItemGroup/giftItem" .. i).gameObject
		local itemIcon = giftItem:ComponentByName("itemIcon", typeof(UISprite))
		local effectNode = giftItem:NodeByName("effect").gameObject
		local numLabel = giftItem:ComponentByName("numLabel", typeof(UILabel))
		local list = {
			giftItem = giftItem,
			itemIcon = itemIcon,
			effectNode = effectNode,
			numLabel = numLabel
		}

		table.insert(self.giftItemList, list)
	end

	local middleGroup = go:NodeByName("middleGroup").gameObject
	self.middleGroup = middleGroup
	self.line_ = middleGroup:NodeByName("line1").gameObject
	local dayGroup = middleGroup:NodeByName("dayGroup").gameObject
	self.dayItemList = {}

	for i = 1, 7 do
		local dayItem = dayGroup:NodeByName("dayItem" .. i).gameObject
		local dayLabel = dayItem:ComponentByName("dayLabel", typeof(UILabel))
		local redPoint = dayItem:NodeByName("redPoint").gameObject
		local lock = dayItem:NodeByName("lock").gameObject
		local selected = dayItem:NodeByName("selected").gameObject
		local completed1 = dayItem:NodeByName("completed1").gameObject
		local completed2 = dayItem:NodeByName("completed2").gameObject
		local list = {
			dayItem = dayItem,
			dayLabel = dayLabel,
			redPoint = redPoint,
			lock = lock,
			selected = selected,
			completed1 = completed1,
			completed2 = completed2
		}

		table.insert(self.dayItemList, list)
	end

	local typeGroup = middleGroup:NodeByName("typeGroup").gameObject
	self.typeItemList = {}

	for i = 1, 4 do
		local typeItem = typeGroup:NodeByName("typeItem" .. i).gameObject
		local selected = typeItem:NodeByName("selected").gameObject
		local redPoint = typeItem:NodeByName("redPoint").gameObject
		local completed = typeItem:NodeByName("completed").gameObject
		local list = {
			typeItem = typeItem,
			selected = selected,
			redPoint = redPoint,
			completed = completed
		}

		table.insert(self.typeItemList, list)
	end

	self.scrollView_panel = middleGroup:ComponentByName("scroller_", typeof(UIPanel))
	self.scrollView = middleGroup:ComponentByName("scroller_", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("groupContent", typeof(UIWrapContent))
	local contentItem = middleGroup:NodeByName("contentItem").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, contentItem, ActivityWeekMissionItem, self)
end

function ActivityWeekMission:initUI()
	self:getUIComponent()
	ActivityWeekMission.super.initUI(self)
	self:updateCompletedList()
	self:initTopGroup()
	self:initMiddleGroup()
	self:updateContent(false)
	self:updateRedMark()
end

function ActivityWeekMission:updateCompletedList()
	if not self.dayCompletedList then
		self.dayCompletedList = {}
	end

	if not self.typeCompletedList then
		self.typeCompletedList = {}

		for i = 1, 7 do
			table.insert(self.typeCompletedList, {})
		end
	end

	local missions = self.activityData.detail.missions

	for day = 1, 7 do
		local completed = true

		for type = 1, 3 do
			local missionList = xyd.tables.activityWeekMissionTable:getMissionList(day, type)
			local flag = true

			for i = 1, #missionList do
				local id = tonumber(missionList[i])

				if missions[id].is_awarded == 0 then
					flag = false

					break
				end
			end

			self.typeCompletedList[day][type] = flag
			completed = completed and flag
		end

		local diaMissionList = xyd.tables.activityWeekExchangeTable:getMissionList(day)
		local diaFlag = true

		for _, id in pairs(diaMissionList) do
			if self.activityData.detail.buy_times[tonumber(id)] == 0 then
				diaFlag = false

				break
			end
		end

		self.typeCompletedList[day][4] = diaFlag
		self.dayCompletedList[day] = completed and diaFlag
	end
end

function ActivityWeekMission:initTopGroup()
	xyd.setUISpriteAsync(self.textImg, nil, "activity_week_mission_text_" .. xyd.Global.lang, nil, , true)

	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.endLabel:SetActive(false)
		self.timeLabel:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.timeLabel)

		timeCount:setInfo({
			duration = duration
		})

		self.endLabel.text = __("END_TEXT")
	end

	local ids = xyd.tables.activityWeekScoreTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local point = xyd.tables.activityWeekScoreTable:getPoint(id)
		self.giftItemList[i].numLabel.text = point

		UIEventListener.Get(self.giftItemList[i].giftItem).onClick = function ()
			local nowPoint = self.activityData.detail.point
			local pointAwarded = self.activityData.detail.point_awarded

			if point <= nowPoint and pointAwarded[i] == 0 then
				local msg = messages_pb.get_new_rookie_point_award_req()
				msg.activity_id = xyd.ActivityID.WEEK_MISSION
				msg.id = tonumber(id)

				xyd.Backend.get():request(xyd.mid.GET_NEW_ROOKIE_POINT_AWARD, msg)
			else
				xyd.WindowManager.get():openWindow("activity_award_preview_window", {
					awards = xyd.tables.activityWeekScoreTable:getAward(id)
				})
			end
		end
	end

	self:updateProgressGroup()
end

function ActivityWeekMission:updateProgressGroup()
	local pointAwarded = self.activityData.detail.point_awarded
	local nowPoint = self.activityData.detail.point
	local ids = xyd.tables.activityWeekScoreTable:getIDs()

	for i = 1, #pointAwarded do
		xyd.setUISpriteAsync(self.giftItemList[i].itemIcon, nil, "activtity_week_mission_gift_" .. i .. "_" .. pointAwarded[i])

		local id = ids[i]
		local point = xyd.tables.activityWeekScoreTable:getPoint(id)

		if point <= nowPoint and pointAwarded[i] == 0 and not self.giftItemList[i].effect then
			local effect = xyd.Spine.new(self.giftItemList[i].effectNode)

			effect:setInfo("new_trial_baoxiang", function ()
				effect:play("texiao0" .. tostring(i * 2 - 1), 0)
			end)

			self.giftItemList[i].effect = effect

			self.giftItemList[i].itemIcon:SetActive(false)
		end
	end

	self.progressBar.value = nowPoint / 100
	self.pointLabel.text = nowPoint
end

function ActivityWeekMission:initMiddleGroup()
	local nowDay = math.min(self.activityData:getNowDays(), 7)
	self.chosenDay = nowDay

	for i = 1, 7 do
		local item = self.dayItemList[i]
		item.dayLabel.text = __("ACTIVITY_WEEK_DATE", i)

		item.lock:SetActive(nowDay < i)

		if nowDay < i then
			xyd.setUISprite(item.dayItem:GetComponent(typeof(UISprite)), nil, "wk_day_locked")
		else
			xyd.setUISprite(item.dayItem:GetComponent(typeof(UISprite)), nil, "wk_day")
		end

		if i ~= self.chosenDay then
			item.selected:SetActive(false)
			item.completed1:SetActive(false)
			item.completed2:SetActive(self.dayCompletedList[i])
		else
			item.dayLabel:Y(5)
			item.redPoint:Y(34)
			item.selected:SetActive(true)
			item.completed1:SetActive(self.dayCompletedList[i])
			item.completed2:SetActive(false)
		end

		UIEventListener.Get(item.dayItem).onClick = function ()
			if i <= nowDay then
				if self.chosenDay ~= i then
					self.dayItemList[self.chosenDay].selected:SetActive(false)
					self.dayItemList[self.chosenDay].redPoint:Y(16)
					self.dayItemList[self.chosenDay].dayLabel:Y(-10)
					self.dayItemList[self.chosenDay].completed1:SetActive(false)
					self.dayItemList[self.chosenDay].completed2:SetActive(self.dayCompletedList[self.chosenDay])

					self.chosenDay = i

					item.selected:SetActive(true)
					item.dayLabel:Y(5)
					item.redPoint:Y(34)
					item.completed1:SetActive(self.dayCompletedList[i])
					item.completed2:SetActive(false)
					self.typeItemList[self.chosenType].selected:SetActive(false)
					self:getStartChosenType(self.chosenDay)
					self.typeItemList[self.chosenType].selected:SetActive(true)
					self:updateContent(false)
					self:updateTagRedMark()

					for j = 1, 4 do
						self.typeItemList[j].completed:SetActive(self.typeCompletedList[self.chosenDay][j])
					end
				end
			else
				xyd.showToast(__("ACTIVITY_WEEK_LOCKING"))
			end
		end
	end

	self:getStartChosenType(nowDay)

	for i = 1, 4 do
		local item = self.typeItemList[i]

		if i ~= self.chosenType then
			item.selected:SetActive(false)
		end

		item.completed:SetActive(self.typeCompletedList[self.chosenDay][i])

		UIEventListener.Get(item.typeItem).onClick = function ()
			if self.chosenType ~= i then
				self.typeItemList[self.chosenType].selected:SetActive(false)

				self.chosenType = i

				item.selected:SetActive(true)
				self:updateContent(false)
			end
		end
	end
end

function ActivityWeekMission:getStartChosenType(day)
	local dayMissionList = xyd.tables.activityWeekMissionTable:getMissionListByDay(day)
	local missions = self.activityData.detail.missions

	for i = 1, #dayMissionList do
		local list = dayMissionList[i]

		for j = 1, #list do
			local id = tonumber(list[j])

			if missions[id].is_completed == 0 then
				self.chosenType = i

				return
			end
		end
	end

	local diaMissionList = xyd.tables.activityWeekExchangeTable:getMissionList(day)

	for _, id in pairs(diaMissionList) do
		if self.activityData.detail.buy_times[tonumber(id)] == 0 then
			self.chosenType = 4

			return
		end
	end

	self.chosenType = 1
end

function ActivityWeekMission:updateCompletedView()
	for day = 1, 7 do
		local item = self.dayItemList[day]

		if day ~= self.chosenDay then
			item.completed1:SetActive(false)
			item.completed2:SetActive(self.dayCompletedList[day])
		else
			item.completed1:SetActive(self.dayCompletedList[day])
			item.completed2:SetActive(false)
		end
	end

	for j = 1, 4 do
		self.typeItemList[j].completed:SetActive(self.typeCompletedList[self.chosenDay][j])
	end
end

function ActivityWeekMission:updateContent(flag)
	local itemList = {}

	if self.chosenType ~= 4 then
		local missionList = xyd.tables.activityWeekMissionTable:getMissionList(self.chosenDay, self.chosenType)
		local missions = self.activityData.detail.missions

		for i = 1, #missionList do
			local id = tonumber(missionList[i])
			local item = {
				isDiamondMission = false,
				id = id,
				is_awarded = missions[id].is_awarded,
				isCompleted = missions[id].is_completed,
				value = missions[id].value
			}

			table.insert(itemList, item)
		end

		table.sort(itemList, function (a, b)
			if a.is_awarded == b.is_awarded then
				if a.is_completed == b.is_completed then
					return a.id < b.id
				else
					return a.is_completed == 1
				end
			else
				return a.is_awarded == 0
			end
		end)
	else
		local missionList = xyd.tables.activityWeekExchangeTable:getMissionList(self.chosenDay)
		local buyTimes = self.activityData.detail.buy_times

		for i = 1, #missionList do
			local id = missionList[i]
			local limit = xyd.tables.activityWeekExchangeTable:getLimit(id)
			local item = {
				isDiamondMission = true,
				id = tonumber(id),
				leftTimes = limit - buyTimes[tonumber(id)]
			}

			table.insert(itemList, item)
		end

		table.sort(itemList, function (a, b)
			if a.leftTimes == b.leftTimes then
				return a.id < b.id
			else
				return a.leftTimes == 1
			end
		end)
	end

	self.wrapContent:setInfos(itemList, {
		keepPosition = flag
	})
end

function ActivityWeekMission:updateRedMark()
	local nowDay = math.min(self.activityData:getNowDays(), 7)

	for i = 1, nowDay do
		self.dayItemList[i].redPoint:SetActive(self.activityData:hasDayRedPoint(i))
	end

	self:updateTagRedMark()
end

function ActivityWeekMission:updateTagRedMark()
	for i = 1, 4 do
		self.typeItemList[i].redPoint:SetActive(self.activityData:hasTagRedPoint(self.chosenDay, i))
	end
end

function ActivityWeekMission:onRegister()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_WEEK_MISSION_HELP"
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.GET_NEW_ROOKIE_MISSION_AWARD, handler(self, self.onMissionAward))
	self:registerEvent(xyd.event.GET_NEW_ROOKIE_POINT_AWARD, handler(self, self.onPointAward))
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.refresh))
end

function ActivityWeekMission:refresh(event)
	if event.data.activity_id == xyd.ActivityID.WEEK_MISSION then
		self:updateContent(true)
		self:updateRedMark()
	end
end

function ActivityWeekMission:onAward()
	local awards = xyd.tables.activityWeekExchangeTable:getAward(self.activityData.diamondID)
	local items = {}

	for i = 1, #awards do
		table.insert(items, {
			item_id = awards[i][1],
			item_num = tonumber(awards[i][2])
		})
	end

	xyd.models.itemFloatModel:pushNewItems(items)
	self:updateCompletedList()
	self:updateCompletedView()
	self:updateContent(false)
	self:updateProgressGroup()
	self:updateRedMark()
end

function ActivityWeekMission:onMissionAward()
	local awards = xyd.tables.activityWeekMissionTable:getAward(self.activityData.missionID)
	local items = {}

	for i = 1, #awards do
		table.insert(items, {
			item_id = awards[i][1],
			item_num = tonumber(awards[i][2])
		})
	end

	xyd.models.itemFloatModel:pushNewItems(items)
	self:updateCompletedList()
	self:updateCompletedView()
	self:updateContent(false)
	self:updateProgressGroup()
	self:updateRedMark()
end

function ActivityWeekMission:onPointAward(event)
	local id = event.data.id
	local awards = xyd.tables.activityWeekScoreTable:getAward(id)
	local items = {}

	for i = 1, #awards do
		table.insert(items, {
			item_id = awards[i][1],
			item_num = tonumber(awards[i][2])
		})
	end

	if self.giftItemList[id].effect then
		self.giftItemList[id].effect:play("texiao0" .. tostring(id * 2), 1, 1, function ()
			self.giftItemList[id].effect:destroy()
			xyd.models.itemFloatModel:pushNewItems(items)
			self.giftItemList[id].itemIcon:SetActive(true)
			xyd.setUISpriteAsync(self.giftItemList[id].itemIcon, nil, "activtity_week_mission_gift_" .. id .. "_1")
		end)
	end
end

function ActivityWeekMissionItem:ctor(go, parent)
	ActivityWeekMissionItem.super.ctor(self, go, parent)
end

function ActivityWeekMissionItem:initUI()
	local go = self.go
	self.descLabel = go:ComponentByName("descLabel", typeof(UILabel))
	self.progressLabel = go:ComponentByName("progressLabel", typeof(UILabel))
	self.getButton = go:NodeByName("getButton").gameObject
	self.buttonLabel = self.getButton:ComponentByName("button_label", typeof(UILabel))
	self.costIcon = self.getButton:NodeByName("costIcon").gameObject
	self.redPoint = self.getButton:NodeByName("redPoint").gameObject
	self.iconGroup = go:NodeByName("iconGroup").gameObject
end

function ActivityWeekMissionItem:updateInfo()
	local id = self.data.id

	NGUITools.DestroyChildren(self.iconGroup.transform)

	if not self.data.isDiamondMission then
		local completeShow = xyd.tables.activityWeekMissionTable:getCompleteShow(id)
		local textType = xyd.tables.activityWeekMissionTable:getTextType(id)
		local desc = xyd.tables.activityWeekMissionTextTable:getDesc(textType, completeShow)
		local awards = xyd.tables.activityWeekMissionTable:getAward(id)
		self.descLabel.text = desc
		local value = self.data.value
		local type_ = xyd.tables.activityWeekMissionTable:getType(id)

		if tonumber(type_) == 10 then
			value = math.floor(value / 100)
		elseif tonumber(type_) == 19 then
			value = self.data.isCompleted
		end

		self.progressLabel.text = value .. "/" .. completeShow

		self.costIcon:SetActive(false)

		for i = 1, #awards do
			local item = xyd.getItemIcon({
				scale = 0.7,
				uiRoot = self.iconGroup,
				itemID = awards[i][1],
				num = awards[i][2]
			})

			item:setDragScrollView(self.parent.scrollView)

			if self.data.is_awarded == 1 then
				item:setChoose(true)
			else
				item:setChoose(false)
			end
		end

		self.buttonLabel:X(0)

		if self.data.is_awarded == 1 then
			self.buttonLabel.text = __("ALREADY_GET_PRIZE")

			xyd.setUISpriteAsync(self.getButton:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65")
			xyd.applyGrey(self.getButton:GetComponent(typeof(UISprite)))
			xyd.setTouchEnable(self.getButton, false)
			self.buttonLabel:ApplyOrigin()

			self.buttonLabel.color = Color.New2(4294967295.0)
			self.buttonLabel.effectColor = Color.New2(1012112383)

			self.buttonLabel:ApplyGrey()
			self.redPoint:SetActive(false)
		elseif self.data.isCompleted == 1 then
			self.buttonLabel.text = __("GET2")

			xyd.setUISpriteAsync(self.getButton:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65")
			xyd.applyOrigin(self.getButton:GetComponent(typeof(UISprite)))
			xyd.setTouchEnable(self.getButton, true)
			self.buttonLabel:ApplyOrigin()

			self.buttonLabel.color = Color.New2(4294967295.0)
			self.buttonLabel.effectColor = Color.New2(1012112383)

			self.redPoint:SetActive(true)
		else
			self.buttonLabel.text = __("GO")

			xyd.setUISpriteAsync(self.getButton:GetComponent(typeof(UISprite)), nil, "prop_btn_mid")
			xyd.applyOrigin(self.getButton:GetComponent(typeof(UISprite)))
			xyd.setTouchEnable(self.getButton, true)
			self.buttonLabel:ApplyOrigin()

			self.buttonLabel.color = Color.New2(1012112383)
			self.buttonLabel.effectColor = Color.New2(4294967295.0)

			self.redPoint:SetActive(false)
		end
	else
		local desc = xyd.tables.activityWeekExchangeTable:getDesc(id)
		local awards = xyd.tables.activityWeekExchangeTable:getAward(id)
		local cost = xyd.tables.activityWeekExchangeTable:getCost(id)
		self.descLabel.text = desc
		self.progressLabel.text = __("LIMIT_BUY", self.data.leftTimes)

		xyd.setUISpriteAsync(self.getButton:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65")

		if #cost == 0 then
			self.buttonLabel.text = __("GET2")

			self.costIcon:SetActive(false)
			self.redPoint:SetActive(self.data.leftTimes > 0)
			self.buttonLabel:X(0)
		else
			self.buttonLabel:X(18)

			self.buttonLabel.text = cost[2]

			self.costIcon:SetActive(true)
			self.redPoint:SetActive(false)
		end

		for i = 1, #awards do
			local item = xyd.getItemIcon({
				scale = 0.7,
				uiRoot = self.iconGroup,
				itemID = awards[i][1],
				num = awards[i][2]
			})

			item:setDragScrollView(self.parent.scrollView)

			if self.data.leftTimes > 0 then
				item:setChoose(false)
			else
				item:setChoose(true)
			end
		end

		if self.data.leftTimes > 0 then
			xyd.applyOrigin(self.getButton:GetComponent(typeof(UISprite)))
			xyd.setTouchEnable(self.getButton, true)
			self.buttonLabel:ApplyOrigin()

			self.buttonLabel.color = Color.New2(4294967295.0)
			self.buttonLabel.effectColor = Color.New2(1012112383)
		else
			if #cost == 0 then
				self.buttonLabel.text = __("ALREADY_GET_PRIZE")
			else
				self.buttonLabel.text = __("ALREADY_BUY")
			end

			self.buttonLabel:X(0)
			self.costIcon:SetActive(false)
			xyd.applyGrey(self.getButton:GetComponent(typeof(UISprite)))
			xyd.setTouchEnable(self.getButton, false)
			self.buttonLabel:ApplyOrigin()

			self.buttonLabel.color = Color.New2(4294967295.0)
			self.buttonLabel.effectColor = Color.New2(1012112383)

			self.buttonLabel:ApplyGrey()
		end
	end

	self.iconGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityWeekMissionItem:registerEvent()
	UIEventListener.Get(self.getButton).onClick = function ()
		if self.data.isDiamondMission then
			local vipLev = xyd.models.backpack:getVipLev()
			local vipLimit = xyd.tables.activityWeekExchangeTable:getVipLimit(self.data.id)
			local hasDiamond = xyd.models.backpack:getCrystal()

			if vipLev < vipLimit then
				xyd.showToast(__("GAMBLE_NEED_VIP", vipLimit))
			else
				local cost = xyd.tables.activityWeekExchangeTable:getCost(self.data.id)

				if #cost == 0 then
					local params = json.encode({
						award_id = self.data.id
					})

					self.parent.activityData:setChooseDiamond(self.data.id)
					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.WEEK_MISSION, params)
				elseif hasDiamond < cost[2] then
					xyd.showToast(__("NOT_ENOUGH_CRYSTAL"))
				else
					xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
						if yes then
							local params = json.encode({
								award_id = self.data.id
							})

							self.parent.activityData:setChooseDiamond(self.data.id)
							xyd.models.activity:reqAwardWithParams(xyd.ActivityID.WEEK_MISSION, params)
						end
					end)
				end
			end
		elseif self.data.isCompleted == 1 then
			local msg = messages_pb.get_new_rookie_mission_award_req()
			msg.activity_id = xyd.ActivityID.WEEK_MISSION
			msg.id = self.data.id

			self.parent.activityData:setChooseMission(self.data.id)
			xyd.Backend.get():request(xyd.mid.GET_NEW_ROOKIE_MISSION_AWARD, msg)
		else
			self:jumpWindow()
		end
	end
end

function ActivityWeekMissionItem:jumpWindow()
	local fucId = xyd.tables.activityWeekMissionTable:getFucId(self.data.id)

	if fucId ~= 0 and not self:checkFuncOpen(fucId) then
		xyd.showFuncNotOpenGuide(fucId)

		return
	end

	local goWindows = xyd.tables.activityWeekMissionTable:getGoWindow(self.data.id)
	local goParams = xyd.tables.activityWeekMissionTable:getGoParams(self.data.id)
	local closeParams = xyd.tables.activityWeekMissionTable:getGoParams(self.data.id)

	function closeParams.closeCallBack()
		self.parent.activityData:reqActivity()
	end

	local type_ = xyd.tables.activityWeekMissionTable:getType(self.data.id)

	if type_ == 13 then
		if xyd.models.guild.guildID > 0 then
			xyd.WindowManager.get():openWindow(goWindows[1], closeParams)
		else
			xyd.WindowManager.get():openWindow("guild_join_window", closeParams)
		end
	elseif #goWindows == 1 then
		xyd.WindowManager.get():openWindow(goWindows[1], closeParams)
	else
		xyd.WindowManager.get():openWindow(goWindows[1], closeParams, function ()
			xyd.WindowManager.get():openWindow(goWindows[2], goParams)
		end)
	end
end

function ActivityWeekMissionItem:checkFuncOpen(fucId)
	return xyd.checkFunctionOpen(fucId, true)
end

return ActivityWeekMission
