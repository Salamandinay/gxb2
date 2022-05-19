local ActivityStarAltarMission = class("ActivityStarAltarMission", import(".ActivityContent"))
local StarAltarMissionItem = class("StarAltarMissionItem", import("app.components.CopyComponent"))
local StarAltarShopItem = class("StarAltarShopItem", import("app.components.CopyComponent"))
local cjson = require("cjson")

function StarAltarMissionItem:ctor(go, parent, type)
	self.go = go
	self.parent = parent
	self.awardItemsArr = {}
	self.type_ = type

	StarAltarMissionItem.super.ctor(self, go)
end

function StarAltarMissionItem:initUI()
	self.task_item = self.go
	self.progressBarUIProgressBar = self.task_item:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressLabel = self.progressBarUIProgressBar.transform:ComponentByName("progressLabel", typeof(UILabel))
	self.itemsGroup = self.task_item:NodeByName("awardGroup").gameObject
	self.itemsGroupUILayout = self.task_item:ComponentByName("awardGroup", typeof(UILayout))
	self.labelDesc = self.task_item:ComponentByName("labelDesc", typeof(UILabel))
	self.limitGroup = self.task_item:ComponentByName("limitGroup", typeof(UILayout))
	self.completeLable = self.task_item:ComponentByName("limitGroup/labelLimit", typeof(UILabel))
	self.completeNum = self.task_item:ComponentByName("limitGroup/limit", typeof(UILabel))
	self.bg = self.task_item:ComponentByName("bg", typeof(UISprite))
	UIEventListener.Get(self.bg.gameObject).onClick = handler(self, function ()
		if self.data_.get_way and self.data_.get_way > 0 then
			xyd.goWay(self.data_.get_way, nil, , function ()
				xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_STAR_ALTAR_MISSION)
			end)
		end
	end)
end

function StarAltarMissionItem:setInfo(data)
	if not data then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.data_ = data
	self.id = data.id

	if self.type_ == 1 then
		xyd.setUISpriteAsync(self.bg, nil, "activity_star_altar_bg1")

		self.bg.width = 710
	else
		xyd.setUISpriteAsync(self.bg, nil, "activity_star_altar_bg2")

		self.bg.width = 680
	end

	self.labelDesc.text = self.data_.desc
	self.value = self.data_.value
	self.completeLable.text = __("ACTIVITY_VAMPIRE_TASK_TEXT01") .. " : "

	for index, itemData in ipairs(self.data_.awards) do
		if not self.awardItemsArr[index] then
			self.awardItemsArr[index] = xyd.getItemIcon({
				scale = 0.6018518518518519,
				uiRoot = self.itemsGroup,
				itemID = itemData[1],
				num = itemData[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		else
			self.awardItemsArr[index]:setInfo({
				scale = 0.6018518518518519,
				uiRoot = self.itemsGroup,
				itemID = itemData[1],
				num = itemData[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	end

	self.itemsGroupUILayout:Reposition()

	if self.data_.limit <= self.data_.is_completed then
		self.completeNum.text = self.data_.limit .. "/" .. self.data_.limit
		self.completeNum.color = Color.New2(1569849855)
		self.progressBarUIProgressBar.value = 1
		self.progressLabel.text = self.data_.complete_value .. "/" .. self.data_.complete_value

		for _, item in ipairs(self.awardItemsArr) do
			item:setChoose(true)
		end
	else
		self.completeNum.color = Color.New2(2889360639.0)
		self.completeNum.text = self.data_.is_completed .. "/" .. self.data_.limit
		self.progressBarUIProgressBar.value = self.data_.value / self.data_.complete_value
		self.progressLabel.text = self.data_.value .. "/" .. self.data_.complete_value

		for _, item in ipairs(self.awardItemsArr) do
			item:setChoose(false)
		end
	end

	self.limitGroup:Reposition()
end

function StarAltarShopItem:ctor(go, parent)
	self.parent = parent

	StarAltarMissionItem.super.ctor(self, go)
end

function StarAltarShopItem:initUI()
	local go = self.go
	self.itemRoot = go:NodeByName("itemRoot")
	self.buyBtn = go:NodeByName("buyBtn").gameObject
	self.label = go:ComponentByName("buyBtn/label", typeof(UILabel))
	self.limitLabel = go:ComponentByName("limitLabel", typeof(UILabel))

	UIEventListener.Get(self.buyBtn).onClick = function ()
		self:onClickBuy()
	end
end

function StarAltarShopItem:setInfo(data)
	self.data_ = data
	self.label.text = self.data_.cost[2]
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.data_.limit - self.data_.buy_times)

	if self.data_.limit - self.data_.buy_times <= 0 then
		xyd.setEnabled(self.buyBtn, false)
	else
		xyd.setEnabled(self.buyBtn, true)
	end

	NGUITools.DestroyChildren(self.itemRoot)
	self:waitForFrame(1, function ()
		xyd.getItemIcon({
			scale = 0.9074074074074074,
			uiRoot = self.itemRoot.gameObject,
			itemID = self.data_.item[1],
			num = self.data_.item[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end)
end

function StarAltarShopItem:onClickBuy()
	local cost = self.data_.cost

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
		if yes then
			local data = cjson.encode({
				num = 1,
				award_id = self.data_.id
			})
			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_STAR_ALTAR_MISSION
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
			self.parent.activityData:setAwardID(self.data_.id)
		end
	end)
end

function ActivityStarAltarMission:ctor(parentGO, params)
	self.shopItems_ = {}
	self.missionItems_ = {}

	ActivityStarAltarMission.super.ctor(self, parentGO, params)
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_STAR_ALTAR_MISSION)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_STAR_ALTAR_MISSION, function ()
		self.activityData.onClickNav(1)
	end)
	dump(self.activityData.detail)
end

function ActivityStarAltarMission:getPrefabPath()
	return "Prefabs/Windows/activity/activity_star_altar"
end

function ActivityStarAltarMission:initUI()
	self:getUIComponent()
	ActivityStarAltarMission.super.initUI(self)
	self:layout()
	self:register()
end

function ActivityStarAltarMission:getUIComponent()
	local go = self.go
	self.logoImg = go:ComponentByName("logoImg", typeof(UISprite))
	self.timeLabel = go:ComponentByName("timeLabel", typeof(UILabel))
	self.resItemClickBox_ = go:NodeByName("resGroup/bg_").gameObject
	self.resItemNum_ = go:ComponentByName("resGroup/countLabel", typeof(UILabel))
	self.navGroup_ = go:NodeByName("navGroup").gameObject

	for i = 1, 2 do
		self["nav" .. i] = self.navGroup_:NodeByName("nav" .. i).gameObject
		self["navLabel" .. i] = self["nav" .. i]:ComponentByName("label", typeof(UILabel))
		self["navSelect" .. i] = self["nav" .. i]:NodeByName("select").gameObject
		self["redPoint" .. i] = self["nav" .. i]:NodeByName("redPoint").gameObject

		UIEventListener.Get(self["nav" .. i]).onClick = function ()
			self:onClickNav(i)
		end
	end

	self.missionPart_ = go:ComponentByName("content/missionPart", typeof(UIScrollView))
	self.missionGrid_ = go:ComponentByName("content/missionPart/grid", typeof(UIGrid))
	self.missionItem_ = self.missionPart_.transform:NodeByName("missionItem").gameObject
	self.exchangePart_ = go:NodeByName("content/exchangePart")
	self.exchangeGrid_ = go:ComponentByName("content/exchangePart/grid", typeof(UIGrid))
	self.exchangeItem_ = self.exchangePart_.transform:NodeByName("exchangeItem").gameObject
	self.helpBtn = go:NodeByName("helpBtn").gameObject
end

function ActivityStarAltarMission:resizeToParent()
	ActivityStarAltarMission.super.resizeToParent(self)

	local height = self.go:GetComponent(typeof(UIWidget)).height

	self.exchangeGrid_.transform:Y((height - 874) / 178 * -80 + 210)
end

function ActivityStarAltarMission:register()
	UIEventListener.Get(self.resItemClickBox_).onClick = function ()
		local params = {
			notShowGetWayBtn = true,
			show_has_num = false,
			itemID = xyd.ItemID.STAR_ALTER_EXCHANGE_COIN,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.STAR_ALTER_EXCHANGE_COIN),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_STAR_ALTAR_MISSION_HELP"
		})
	end

	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id == xyd.ActivityID.ACTIVITY_STAR_ALTAR_MISSION and self.activityData.awardID then
			local award = xyd.tables.activityStarAltarExchangeTable:getAward(self.activityData.awardID)
			local awardItem = {}

			table.insert(awardItem, {
				item_id = award[1],
				item_num = award[2]
			})
			xyd.models.itemFloatModel:pushNewItems(awardItem)

			self.activityData.detail.buy_times[self.activityData.awardID] = self.activityData.detail.buy_times[self.activityData.awardID] + 1

			self:updateContent()
			self:updateRedPoint()
			self:updateResItem()
		end
	end)
end

function ActivityStarAltarMission:onClickNav(index)
	if self.chooseIndex_ == index then
		return
	else
		self.chooseIndex_ = index

		for i = 1, 2 do
			self["navSelect" .. i]:SetActive(i == index)

			if i == index then
				self["navLabel" .. i].color = Color.New2(3907117055.0)
			else
				self["navLabel" .. i].color = Color.New2(1010253567)
			end
		end
	end

	self:updateContent()
	self:updateRedPoint()
end

function ActivityStarAltarMission:layout()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_star_altar_logo_" .. xyd.Global.lang)

	self.navLabel1.text = __("ACTIVITY_STAR_ALTAR_MISSION_TITLE01")
	self.navLabel2.text = __("ACTIVITY_STAR_ALTAR_MISSION_TITLE02")

	self:onClickNav(1)
	self:waitForFrame(2, function ()
		self.missionGrid_:Reposition()
	end)
	self:updateResItem()
end

function ActivityStarAltarMission:updateResItem()
	self.resItemNum_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.STAR_ALTER_EXCHANGE_COIN)
end

function ActivityStarAltarMission:onActivityByID(event)
	local id = event.data.act_info.activity_id

	if id == xyd.ActivityID.ACTIVITY_STAR_ALTAR_MISSION then
		self:updateContent()
		self:updateRedPoint()
		self:updateResItem()
	end
end

function ActivityStarAltarMission:updateContent()
	if self.chooseIndex_ == 1 then
		self.missionPart_.gameObject:SetActive(true)
		self.exchangePart_:SetActive(false)
		self:updateMissionList()
	else
		self.missionPart_.gameObject:SetActive(false)
		self.exchangePart_:SetActive(true)
		self:updateItemList()
	end
end

function ActivityStarAltarMission:updateRedPoint()
	self.redPoint1:SetActive(self.activityData:getRedStateMission())
	self.redPoint2:SetActive(self.activityData:getRedStateShop())
end

function ActivityStarAltarMission:updateMissionList()
	local missionIds = xyd.tables.activityStarAltarMissionTable:getIDs()
	local missionData = {}

	for i = 1, #missionIds do
		local params = {
			id = tonumber(missionIds[i])
		}
		params.is_completed = self.activityData.detail.is_completeds[params.id]
		params.value = self.activityData.detail.values[params.id]
		params.limit = xyd.tables.activityStarAltarMissionTable:getLimit(params.id)
		params.complete_value = xyd.tables.activityStarAltarMissionTable:getCompValue(params.id)
		params.activity_id = xyd.tables.activityStarAltarMissionTable:getActivityID(params.id)
		params.get_way = xyd.tables.activityStarAltarMissionTable:getGetWay(params.id)
		params.awards = xyd.tables.activityStarAltarMissionTable:getAward(params.id)
		params.desc = xyd.tables.activityStarAltarMissionTable:getDesc(params.id)

		table.insert(missionData, params)
	end

	table.sort(missionData, function (a, b)
		local avalue = a.id
		local bvalue = b.id

		if a.limit <= a.is_completed then
			avalue = avalue + 1000
		end

		if b.limit <= b.is_completed then
			bvalue = bvalue + 1000
		end

		return avalue < bvalue
	end)

	for index, data in ipairs(missionData) do
		local type = xyd.checkCondition(data.id == 1, 1, 0)
		local activityData = xyd.models.activity:getActivity(data.activity_id)

		if not self.missionItems_[data.id] then
			local rootNew = NGUITools.AddChild(self.missionGrid_.gameObject, self.missionItem_)

			rootNew:SetActive(true)

			self.missionItems_[data.id] = StarAltarMissionItem.new(rootNew, self, type)
		end

		self.missionItems_[data.id]:setInfo(data)

		if not activityData and data.id ~= 1 then
			self.missionItems_[data.id].go:SetActive(false)
		else
			self.missionItems_[data.id].go:SetActive(true)
		end
	end

	self.missionItems_[1].go.transform:SetSiblingIndex(0)
	self:waitForFrame(1, function ()
		self.missionGrid_:Reposition()
		self.missionPart_:ResetPosition()
	end)
end

function ActivityStarAltarMission:updateItemList()
	local itemIDs = xyd.tables.activityStarAltarExchangeTable:getIDs()
	local shopData = {}

	for i = 1, #itemIDs do
		local params = {
			id = i,
			item = xyd.tables.activityStarAltarExchangeTable:getAward(i),
			cost = xyd.tables.activityStarAltarExchangeTable:getCost(i),
			limit = xyd.tables.activityStarAltarExchangeTable:getLimit(i),
			buy_times = self.activityData.detail.buy_times[i]
		}

		table.insert(shopData, params)
	end

	for index, data in ipairs(shopData) do
		if not self.shopItems_[data.id] then
			local rootNew = NGUITools.AddChild(self.exchangeGrid_.gameObject, self.exchangeItem_)

			rootNew:SetActive(true)

			self.shopItems_[data.id] = StarAltarShopItem.new(rootNew, self)
		end

		self.shopItems_[data.id]:setInfo(data)
	end

	self:waitForFrame(1, function ()
		self.exchangeGrid_:Reposition()
	end)
end

return ActivityStarAltarMission
