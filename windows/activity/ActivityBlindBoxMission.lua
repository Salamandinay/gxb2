local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ActivityBlindBoxMission = class("ActivityBlindBoxMission", ActivityContent)
local FundItem = class("FundItem", import("app.components.CopyComponent"))
ActivityBlindBoxMission.FundItem = FundItem

function ActivityBlindBoxMission:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
	xyd.db.misc:setValue({
		key = "activity_blind_box_mission_last_view_time",
		value = xyd.getServerTime()
	})

	if self.activityData:isFirstTimeEnter() == true then
		local msg = messages_pb:get_activity_info_by_id_req()
		msg.activity_id = self.id

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
		self.activityData:setFirstTimeEnter(false)
	end

	self.itemInfoList = {}

	self:getUIComponent()
	self:register()
	self:layout()
end

function ActivityBlindBoxMission:getPrefabPath()
	return "Prefabs/Windows/activity/activity_blind_box_mission"
end

function ActivityBlindBoxMission:getUIComponent()
	local go = self.go
	self.activityGroup = go:NodeByName("activityGroup").gameObject
	self.bg = self.activityGroup:ComponentByName("bg", typeof(UISprite))
	self.logo = self.activityGroup:ComponentByName("logo", typeof(UISprite))
	self.fundGroup = self.activityGroup:NodeByName("fundGroup").gameObject
	self.scrollerView = self.fundGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollerViewPanel = self.fundGroup:ComponentByName("scroller", typeof(UIPanel))
	self.scrollerViewPanel.depth = self.scrollerViewPanel.depth + 1
	self.groupItem = self.scrollerView:NodeByName("groupItem")
	self.groupItemUIGrid = self.scrollerView:ComponentByName("groupItem", typeof(UIGrid))
	self.fundItem = go.transform:Find("fund_item")
end

function ActivityBlindBoxMission:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onVIPExpChange))
end

function ActivityBlindBoxMission:onVIPExpChange(event)
	for i = 1, #event.data.items do
		local itemId = event.data.items[i].item_id

		if itemId == xyd.ItemID.VIP_EXP then
			local msg = messages_pb:get_activity_info_by_id_req()
			msg.activity_id = self.id

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
			self:layout()

			break
		end
	end
end

function ActivityBlindBoxMission:layout()
	self:setText()
	self:setTexture()
	self:setItem()
end

function ActivityBlindBoxMission:setText()
end

function ActivityBlindBoxMission:setTexture()
	xyd.setUISpriteAsync(self.logo, nil, "activity_blind_box_mission_logo_" .. xyd.Global.lang, nil, , true)
end

function ActivityBlindBoxMission:onRegister()
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.updateData))
end

function ActivityBlindBoxMission:updateData(event)
	local data = event.data

	if data.activity_id ~= self.id then
		return
	end

	self:setItem()
end

function ActivityBlindBoxMission:setItem()
	local ids = xyd.tables.activityBlindBoxMissionTable:getIDs()
	self.itemInfoList = {}

	for i, v in pairs(ids) do
		local id_ = ids[i]
		local progressNow_ = self.activityData:getVipExp()
		local progressMax_ = xyd.tables.activityBlindBoxMissionTable:getNum(id_)
		local jumpWay_ = xyd.tables.activityBlindBoxMissionTable:getJumpWay(id_)
		local awards_ = xyd.tables.activityBlindBoxMissionTable:getAwards(id_)
		local text_ = __("ACTIVITY_BLIND_BOX_MISSION", progressMax_)
		local get_ = false

		if progressMax_ <= progressNow_ then
			get_ = true
		end

		local param = {
			id = id_,
			text = text_,
			progressNow = progressNow_,
			progressMax = progressMax_,
			jumpWay = jumpWay_,
			awards = awards_,
			get = get_
		}

		table.insert(self.itemInfoList, param)
	end

	table.sort(self.itemInfoList, function (a, b)
		return tonumber(a.id) < tonumber(b.id)
	end)

	local tempInfoList1 = {}
	local tempInfoList2 = {}

	for i, info in ipairs(self.itemInfoList) do
		if info.get == true then
			table.insert(tempInfoList2, info)
		else
			table.insert(tempInfoList1, info)
		end
	end

	for i, info in ipairs(tempInfoList2) do
		table.insert(tempInfoList1, info)
	end

	NGUITools.DestroyChildren(self.groupItem.transform)

	for i in ipairs(tempInfoList1) do
		local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.fundItem.gameObject)
		local item = FundItem.new(tmp, tempInfoList1[i])
	end

	self.fundItem:SetActive(false)
	self.groupItemUIGrid:Reposition()
	self.scrollerView:ResetPosition()
end

function FundItem:ctor(go, itemInfo)
	self.go = go
	self.JumpWay = itemInfo.JumpWay
	self.id = tonumber(itemInfo.id)

	self:getUIComponent()
	self:initItem(itemInfo)
end

function FundItem:getUIComponent()
	self.progressBar = self.go:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressImg = self.go:ComponentByName("progressBar/progressImg", typeof(UISprite))
	self.progressDesc = self.go:ComponentByName("progressBar/progressLabel", typeof(UILabel))
	self.labelTitle = self.go:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup = self.go:NodeByName("itemsGroup").gameObject
end

function FundItem:initItem(itemInfo)
	self.labelTitle.text = itemInfo.text
	self.progressDesc.text = math.min(itemInfo.progressNow, itemInfo.progressMax) .. "/" .. itemInfo.progressMax
	self.progressBar.value = math.min(itemInfo.progressNow / itemInfo.progressMax, 1)

	if self.progressBar.value == 1 then
		xyd.setUISpriteAsync(self.progressImg, nil, "jindu_xinxi_1", nil, , true)

		local Color1 = Color.New2(75665919)
		self.progressDesc.effectColor = Color1
	else
		xyd.setUISpriteAsync(self.progressImg, nil, "jindu_xinxi_2", nil, , true)

		local Color1 = Color.New2(3077511935.0)
		self.progressDesc.effectColor = Color1
	end

	local scaleNum = 0.7

	for i, reward in pairs(itemInfo.awards) do
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup,
			scale = Vector3(scaleNum, scaleNum, 1),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		icon:setChoose(itemInfo.get)
	end

	if itemInfo.jumpWay and tonumber(itemInfo.jumpWay) > 0 then
		local function onClick()
			xyd.goWay(itemInfo.jumpWay, nil, , function ()
			end)
		end

		UIEventListener.Get(self.go).onClick = onClick
	end
end

return ActivityBlindBoxMission
