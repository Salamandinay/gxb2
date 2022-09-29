local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ActivityRepairMission = class("ActivityRepairMission", ActivityContent)
local FundItem = class("FundItem", import("app.components.CopyComponent"))
ActivityRepairMission.FundItem = FundItem

function ActivityRepairMission:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	if self.activityData:isFirstTimeEnter() == true then
		local msg = messages_pb:get_activity_info_by_id_req()
		msg.activity_id = self.id

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
		self.activityData:setFirstTimeEnter(false)
	end

	self.currentState = xyd.Global.lang
	self.data = {}

	self:getUIComponent()
	self:euiComplete()
	self:checkIfMove()
end

function ActivityRepairMission:onRegister()
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.updateData))
end

function ActivityRepairMission:updateData(event)
	local data = event.data

	if data.activity_id ~= self.id then
		return
	end

	self:setItem()
	self:checkIfMove()
end

function ActivityRepairMission:getPrefabPath()
	return "Prefabs/Windows/activity/repair_mission"
end

function ActivityRepairMission:getUIComponent()
	local go = self.go
	self.activityGroup = go:NodeByName("activityGroup").gameObject
	self.imgBg = self.activityGroup:ComponentByName("imgBg_", typeof(UISprite))
	self.log = self.activityGroup:ComponentByName("logo", typeof(UISprite))
	self.descLabel = self.activityGroup:ComponentByName("descLabel", typeof(UILabel))
	self.timeGroup = self.activityGroup:NodeByName("timeGroup").gameObject
	self.labelTime = self.timeGroup:ComponentByName("endtime", typeof(UILabel))
	self.endText_ = self.timeGroup:ComponentByName("endText", typeof(UILabel))
	self.fundGroup = self.activityGroup:NodeByName("fundGroup").gameObject
	self.fundGroupWidget = self.activityGroup:ComponentByName("fundGroup", typeof(UIWidget))
	self.e_Scroller = self.fundGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.e_Scroller_uiPanel = self.fundGroup:ComponentByName("scroller", typeof(UIPanel))
	self.e_Scroller_uiPanel.depth = self.e_Scroller_uiPanel.depth + 1
	self.groupItem = self.e_Scroller_uiPanel:NodeByName("groupItem")
	self.groupItem_uigrid = self.groupItem:GetComponent(typeof(UIGrid))
	self.fundItem = go.transform:Find("fund_item")
end

function ActivityRepairMission:euiComplete()
	xyd.setUISpriteAsync(self.log, nil, "activity_repair_mission_logo_" .. xyd.Global.lang, nil, , true)
	self:setText()
	self:setItem()

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.labelTime, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.labelTime:SetActive(false)
		self.endText_:SetActive(false)
	end
end

function ActivityRepairMission:setText()
	self.endText_.text = __("TEXT_END")

	if xyd.Global.lang == "fr_fr" then
		self.endText_.transform:SetSiblingIndex(0)
		self.labelTime.transform:SetSiblingIndex(1)
	end
end

function ActivityRepairMission:setItem()
	local ids = xyd.tables.activityRepairMissionTable:getIDs()
	self.data = {}

	for i, v in pairs(ids) do
		local id = ids[i]
		local is_completed = self.activityData.detail.missions[id].is_completed
		local limit = xyd.tables.activityRepairMissionTable:getLimit(id)
		local awards_info = xyd.tables.activityRepairMissionTable:getAwards(id)
		local value = self.activityData.detail.missions[id].value
		local maxValue = xyd.tables.activityRepairMissionTable:getComplete(id)
		local awardTimes = self.activityData.detail.missions[i].is_awarded ~= 0
		local text = xyd.stringFormat(xyd.tables.activityRepairConsoleMissionTextTable:getDesc(id), is_completed)
		local realValue = math.min(value, maxValue) / maxValue
		local gotten = false

		if is_completed > 0 and value == 0 or limit <= is_completed or realValue == 1 then
			gotten = true
			realValue = 1
			value = maxValue
		end

		local param = {
			id = id,
			max_point = maxValue,
			point = value,
			awards = awards_info,
			text = text,
			realValue = realValue,
			gotten = gotten,
			get_way = xyd.tables.activityRepairMissionTable:getJumpWay(id)
		}

		table.insert(self.data, param)
	end

	table.sort(self.data, function (a, b)
		return tonumber(a.id) < tonumber(b.id)
	end)

	local tempArr = {}

	NGUITools.DestroyChildren(self.groupItem.transform)

	for i in ipairs(self.data) do
		local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.fundItem.gameObject)

		table.insert(tempArr, tmp)

		local item = FundItem.new(tmp, self.data[i])
	end

	self.fundItem:SetActive(false)
end

function ActivityRepairMission:checkIfMove()
	self.fundGroupWidget.height = #self.data * self.groupItem_uigrid.cellHeight + 18

	self:resizePosY(self.fundGroup, -400, -580)
	self.groupItem_uigrid:Reposition()
	self.e_Scroller:ResetPosition()
end

function FundItem:ctor(goItem, itemdata)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.getWayId_ = itemdata.get_way
	self.id_ = tonumber(itemdata.id)
	self.imgbg = transGo:ComponentByName("e:Image", typeof(UITexture))
	self.imgSprite = transGo:ComponentByName("e:Image", typeof(UISprite))
	self.progressBar_ = transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.labelTitle_ = transGo:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup_ = transGo:Find("itemsGroup")

	self:initItem(itemdata)
	self:initBaseInfo(itemdata)
end

function FundItem:initBaseInfo(itemdata)
	self.labelTitle_.text = itemdata.text

	if xyd.Global.lang == "fr_fr" then
		self.labelTitle_.fontSize = 20
	end

	if xyd.Global.lang == "ko_kr" then
		self.labelTitle_.width = 400
	end
end

function FundItem:initItem(itemdata)
	self.progressBar_.value = itemdata.realValue

	if self.progressBar_.value == 1 then
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb_2", nil, , true)
	else
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb", nil, , true)
	end

	self.progressDesc.text = math.min(itemdata.point, itemdata.max_point) .. "/" .. itemdata.max_point
	local scaleNum = 0.7

	for i, reward in pairs(itemdata.awards) do
		scaleNum = i == 1 and 0.7 or 0.6
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_.gameObject,
			scale = Vector3(scaleNum, scaleNum, 1),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		icon:setChoose(itemdata.gotten)
	end

	if self.getWayId_ and tonumber(self.getWayId_) > 0 then
		local function onClick()
			xyd.goWay(self.getWayId_, nil, , function ()
				xyd.WindowManager.get():closeWindow("activity_window")
			end)
		end

		UIEventListener.Get(self.goItem_.gameObject).onClick = onClick
	end
end

return ActivityRepairMission
