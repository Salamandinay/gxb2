local ActivityContent = import(".ActivityContent")
local ActivityFoodFestival = class("ActivityFoodFestival", ActivityContent)
local ActivityFoodFestivalItem = class("ActivityFoodFestivalItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ActivityFoodFestivalRewardTable = xyd.tables.activityFoodFestivalRewardTable
local ItemTable = xyd.tables.itemTable
local json = require("cjson")

function ActivityFoodFestival:ctor(parentGO, params, parent)
	self.resItems = {
		212,
		213,
		214
	}
	self.pageType = 1
	local pageType = xyd.getWindow("activity_window").params_.pageType

	if pageType then
		self.pageType = pageType
	else
		self.pageType = 1
	end

	ActivityFoodFestival.super.ctor(self, parentGO, params, parent)
end

function ActivityFoodFestival:getPrefabPath()
	return "Prefabs/Windows/activity/activity_food_festival"
end

function ActivityFoodFestival:getUIComponent()
	local go = self.go
	local groupMain = go:NodeByName("groupMain").gameObject
	self.topGroup = groupMain:NodeByName("topGroup").gameObject
	self.textImg = self.topGroup:ComponentByName("textImg", typeof(UISprite))
	self.helpBtn = self.topGroup:NodeByName("helpBtn").gameObject
	self.endLabel = self.topGroup:ComponentByName("endLabel", typeof(UILabel))
	self.descLabel = self.topGroup:ComponentByName("descLabel", typeof(UILabel))
	self.leftTime = self.topGroup:ComponentByName("leftTime", typeof(UILabel))
	self.tag_1 = groupMain:NodeByName("tag_1").gameObject
	self.tag_2 = groupMain:NodeByName("tag_2").gameObject
	self.tag_bg_1 = self.tag_1:ComponentByName("bg_", typeof(UISprite))
	self.tag_bg_2 = self.tag_2:ComponentByName("bg_", typeof(UISprite))
	self.tag_label_1 = self.tag_1:ComponentByName("labelDisplay", typeof(UILabel))
	self.tag_label_2 = self.tag_2:ComponentByName("labelDisplay", typeof(UILabel))
	self.mainGroup = groupMain:NodeByName("mainGroup").gameObject
	self.bg_2 = self.mainGroup:ComponentByName("bg_2", typeof(UISprite))
	self.groupRes = self.mainGroup:NodeByName("groupRes").gameObject

	for i = 1, 3 do
		self["resItem_" .. i] = self.groupRes:NodeByName("resItem_" .. i).gameObject
	end

	self.scrollGroup = self.mainGroup:NodeByName("scrollGroup").gameObject
	self.scrollView = self.scrollGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = self.scrollGroup:NodeByName("scroller/groupContent").gameObject
	self.scrollerItem = self.scrollGroup:NodeByName("scroller/activity_food_festival_item").gameObject
	local wrapContent = self.groupContent:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.scrollerItem, ActivityFoodFestivalItem, self)
end

function ActivityFoodFestival:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "activity_food_festival2_web_" .. xyd.Global.lang)

	local CountDown = import("app.components.CountDown")

	CountDown.new(self.leftTime, {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")
	self.descLabel.text = __("ACTIVITY_FOOD_FESTIVIAL_DESC")
	self.tag_label_1.text = __("ACTIVITY_FOOD_FESTIVAL_FOOD")
	self.tag_label_2.text = __("ACTIVITY_FOOD_FESTIVAL_STORE")
	local ids = ActivityFoodFestivalRewardTable:getIds()
	local buyTimes = self.activityData.detail.buy_times
	self.sortedDatas = self:sortIds(ids, buyTimes)

	if self:hasLeftLimit() and self.pageType == 1 then
		self.pageType = 1

		xyd.setUISpriteAsync(self.tag_bg_1, nil, "activity_food_festival2_web_bg_xkhdxxsg_yeqian_1")
		xyd.setUISpriteAsync(self.tag_bg_2, nil, "activity_food_festival2_web_bg_xkhdxxsg_yeqian_2")

		self.tag_label_1.color = Color.New2(1146189823)
		self.tag_label_2.color = Color.New2(1917407999)
	else
		self.pageType = 2

		xyd.setUISpriteAsync(self.tag_bg_1, nil, "activity_food_festival2_web_bg_xkhdxxsg_yeqian_2")
		xyd.setUISpriteAsync(self.tag_bg_2, nil, "activity_food_festival2_web_bg_xkhdxxsg_yeqian_1")

		self.tag_label_1.color = Color.New2(1917407999)
		self.tag_label_2.color = Color.New2(1146189823)
	end

	local redIcon = self.tag_2:ComponentByName("redIcon", typeof(UISprite))

	redIcon:SetActive(self.activityData:getRedMarkState())
end

function ActivityFoodFestival:resizeToParent()
	ActivityFoodFestival.super.resizeToParent(self)
end

function ActivityFoodFestival:register()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		local params = {
			key = "ACTIVITY_FOOD_FESTIVIAL_HELP"
		}

		xyd.openWindow("help_window", params)
	end

	UIEventListener.Get(self.tag_1).onClick = function ()
		self:updatePage(1)
	end

	UIEventListener.Get(self.tag_2).onClick = function ()
		local msg = messages_pb.record_activity_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_FOOD_FESTIVAL * 100 + 2

		xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)
		self:updatePage(2)
	end

	for i = 1, #self.resItems do
		local resItem = self["resItem_" .. i]

		UIEventListener.Get(resItem).onClick = function ()
			local params = {
				notShowNotSell = true,
				showGetWays = false,
				show_has_num = true,
				itemID = self.resItems[i],
				wndType = xyd.ItemTipsWndType.BACKPACK
			}

			xyd.openWindow("item_tips_window", params)
		end
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.getAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateResItem))
end

function ActivityFoodFestival:updateContent()
	self.itemList = {}
	local buyTimes = self.activityData.detail.buy_times
	local sortedDatas = self.sortedDatas

	for i = 1, #sortedDatas do
		local id = sortedDatas[i].id
		local type = ActivityFoodFestivalRewardTable:getType(id)

		if type == self.pageType then
			table.insert(self.itemList, {
				id = id,
				buyTimes = buyTimes[id]
			})
		end
	end

	self.wrapContent:setInfos(self.itemList, {})

	if self.pageType == 1 then
		self.groupRes:SetActive(true)

		for i = 1, #self.resItems do
			local num = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(self.resItems[i]))
			self["resItem_" .. i]:ComponentByName("LabelResNum", typeof(UILabel)).text = num
		end

		self.scrollGroup:ComponentByName("scroller", typeof(UIPanel)):SetTopAnchor(self.mainGroup, 1, -75)
		self.scrollView:ResetPosition()
	else
		self.groupRes:SetActive(false)
		self:updateRedMark()
		self.scrollGroup:ComponentByName("scroller", typeof(UIPanel)):SetTopAnchor(self.mainGroup, 1, -10)
		self.scrollView:ResetPosition()
	end
end

function ActivityFoodFestival:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initUIComponent()
	self:register()
	self:waitForFrame(1, function ()
		self:updateContent()
	end)
end

function ActivityFoodFestival:hasLeftLimit()
	for i = 1, #self.sortedDatas do
		local data = self.sortedDatas[i]
		local type = ActivityFoodFestivalRewardTable:getType(data.id)

		if type == 1 then
			local limit = ActivityFoodFestivalRewardTable:getLimit(data.id)

			if data.times < limit then
				return true
			end
		end
	end

	return false
end

function ActivityFoodFestival:updatePage(index)
	if self.pageType == index then
		return
	end

	if index == 1 then
		xyd.setUISpriteAsync(self.tag_bg_1, nil, "activity_food_festival2_web_bg_xkhdxxsg_yeqian_1")
		xyd.setUISpriteAsync(self.tag_bg_2, nil, "activity_food_festival2_web_bg_xkhdxxsg_yeqian_2")

		self.tag_label_1.color = Color.New2(1146189823)
		self.tag_label_2.color = Color.New2(1917407999)
	else
		xyd.setUISpriteAsync(self.tag_bg_1, nil, "activity_food_festival2_web_bg_xkhdxxsg_yeqian_2")
		xyd.setUISpriteAsync(self.tag_bg_2, nil, "activity_food_festival2_web_bg_xkhdxxsg_yeqian_1")

		self.tag_label_1.color = Color.New2(1917407999)
		self.tag_label_2.color = Color.New2(1146189823)
	end

	self.pageType = index

	self.scrollView:StopMove()
	self:updateContent()
end

function ActivityFoodFestival:updateRedMark()
	local redIcon = self.tag_2:ComponentByName("redIcon", typeof(UISprite))

	redIcon:SetActive(self.activityData:getRedMarkState())
	self:waitForTime(0.5, function ()
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_FOOD_FESTIVAL, function ()
			xyd.db.misc:setValue({
				key = "activity_food_festival2",
				value = xyd.getServerTime()
			})
		end)
		redIcon:SetActive(self.activityData:getRedMarkState())
	end)
end

function ActivityFoodFestival:updateResItem()
	for i = 1, #self.resItems do
		local num = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(self.resItems[i]))
		self["resItem_" .. i]:ComponentByName("LabelResNum", typeof(UILabel)).text = num
	end
end

function ActivityFoodFestival:sortIds(ids, buyTimes)
	local sorted = {}

	for i = 1, #ids do
		local id = ids[i]
		local limit = ActivityFoodFestivalRewardTable:getLimit(id)
		local leftTimes = limit - tonumber(buyTimes[id])
		local data = {
			id = id,
			times = tonumber(buyTimes[id]),
			leftTimes = leftTimes
		}

		table.insert(sorted, data)
	end

	table.sort(sorted, function (a, b)
		if a.leftTimes == 0 and b.leftTimes ~= 0 then
			return false
		end

		if b.leftTimes == 0 and a.leftTimes ~= 0 then
			return true
		end

		return a.id < b.id
	end)

	return sorted
end

function ActivityFoodFestival:getAward(event)
	while #self.activityData.choose_queue > 0 do
		local id = table.remove(self.activityData.choose_queue, 1)
		local num = table.remove(self.activityData.choose_num, 1)

		self:onCompeleteAnime(id, num)
	end
end

function ActivityFoodFestival:onCompeleteAnime(id, num)
	local afterData = ActivityFoodFestivalRewardTable:getAwards(id)
	local tmpItems = {}

	for _, item in ipairs(afterData) do
		local isCool = 0
		local type = ItemTable:getType(item[1])

		if type == xyd.ItemType.SKIN then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = {
					tonumber(item[1])
				}
			})
		end

		table.insert(tmpItems, {
			item_id = item[1],
			item_num = tonumber(item[2]) * num,
			cool = isCool
		})
	end

	self:itemFloat(tmpItems)

	local info = {
		id = id,
		buyTimes = self.activityData.detail.buy_times[id]
	}
	local items = self.wrapContent:getItems()

	for i = 1, #items do
		if items[i].id == id then
			items[i]:update(nil, , info)
		end
	end
end

function ActivityFoodFestivalItem:ctor(go, parent)
	ActivityFoodFestivalItem.super.ctor(self, go, parent)

	self.parent = parent
end

function ActivityFoodFestivalItem:initUI()
	local go = self.go
	local mainGroup = go:NodeByName("mainGroup").gameObject
	self.groupAfter = mainGroup:NodeByName("groupAfter").gameObject
	self.eqaulIcon = mainGroup:NodeByName("eqaulIcon").gameObject
	self.groupCost_ = mainGroup:NodeByName("groupCost_").gameObject
	self.groupCost_1 = self.groupCost_:NodeByName("groupCost_1").gameObject
	self.groupCost_2 = self.groupCost_:NodeByName("groupCost_2").gameObject
	self.groupCost_3 = self.groupCost_:NodeByName("groupCost_3").gameObject
	self.groupEff = mainGroup:NodeByName("groupEff").gameObject
	self.btnCompose_ = mainGroup:NodeByName("btnCompose_").gameObject
	self.labelLimit = mainGroup:ComponentByName("labelLimit", typeof(UILabel))
end

function ActivityFoodFestivalItem:updateInfo()
	self.id = tonumber(self.data.id)
	self.buyTimes = tonumber(self.data.buyTimes)
	self.type = ActivityFoodFestivalRewardTable:getType(self.id)
	local afterData = ActivityFoodFestivalRewardTable:getAwards(self.id)

	NGUITools.DestroyChildren(self.groupAfter.transform)

	for i = 1, #afterData do
		local data = afterData[i]
		local type = ItemTable:getType(data[1])
		local item = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7,
			uiRoot = self.groupAfter,
			itemID = tonumber(data[1]),
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			num = data[2],
			dragScrollView = self.parent.scrollView,
			isNew = ActivityFoodFestivalRewardTable:getIsNew(self.id) and i == 1
		})
	end

	self.groupAfter:GetComponent(typeof(UILayout)):Reposition()

	local limit = ActivityFoodFestivalRewardTable:getLimit(self.id)
	local resIcon = self.btnCompose_:ComponentByName("resIcon", typeof(UISprite))
	local button_label = self.btnCompose_:ComponentByName("button_label", typeof(UILabel))
	self.labelLimit.text = __("LIMIT_BUY", limit - self.buyTimes .. "/" .. limit)

	if self.buyTimes < limit then
		xyd.setEnabled(self.btnCompose_, true)
		xyd.applyOrigin(resIcon)

		UIEventListener.Get(self.btnCompose_).onClick = handler(self, self.onExchange)
	else
		xyd.setEnabled(self.btnCompose_, false)
		xyd.applyGrey(resIcon)
	end

	resIcon:SetActive(false)

	if self.type == 1 then
		self.eqaulIcon:SetActive(true)
		self.groupCost_:SetActive(true)
		self.groupCost_2:SetActive(false)
		self.groupCost_3:SetActive(false)

		local costData = ActivityFoodFestivalRewardTable:getCost(self.id)

		for i = 1, #costData do
			local groupCost = self["groupCost_" .. i]
			local data = costData[i]

			xyd.setUISpriteAsync(groupCost:ComponentByName("costRes", typeof(UISprite)), nil, ItemTable:getIcon(data[1]))

			groupCost:ComponentByName("costLabel", typeof(UILabel)).text = data[2]

			groupCost:SetActive(true)
		end

		self.groupCost_:GetComponent(typeof(UILayout)):Reposition()

		button_label.text = __("EXCHANGE")

		button_label:X(0)
	else
		self.eqaulIcon:SetActive(false)
		self.groupCost_:SetActive(false)

		local costData = ActivityFoodFestivalRewardTable:getCost(self.id)[1]

		xyd.setUISpriteAsync(resIcon, nil, ItemTable:getIcon(costData[1]) .. "_small")

		button_label.text = costData[2]

		button_label:X(10)
		resIcon:SetActive(true)
	end
end

function ActivityFoodFestivalItem:onExchange()
	local flag = true
	local costData = ActivityFoodFestivalRewardTable:getCost(self.id)

	for i = 1, #costData do
		local data = costData[i]

		if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
			flag = false

			break
		end
	end

	local limit = ActivityFoodFestivalRewardTable:getLimit(self.id)

	if not flag then
		if self.type == 1 then
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_ACTIVITY_ITEMS"))
		else
			xyd.alert(xyd.AlertType.YES_NO, __("CRYSTAL_NOT_ENOUGH"), function (flag)
				if flag then
					xyd.openWindow("vip_window")
				end
			end)
		end

		return
	end

	if self.type == 2 then
		xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
			if not yes then
				return
			end

			self:exchange(1)
		end)
	elseif limit - self.buyTimes == 1 then
		xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_CHANGE"), function (yes)
			if not yes then
				return
			end

			self:exchange(1)
		end)
	else
		self:openExchange()
	end
end

function ActivityFoodFestivalItem:openExchange()
	xyd.openWindow("activity_food_festival_exchange_window", {
		callback = function (num)
			self:exchange(num)
		end,
		awards = ActivityFoodFestivalRewardTable:getAwards(self.id),
		costs = ActivityFoodFestivalRewardTable:getCost(self.id),
		limit = ActivityFoodFestivalRewardTable:getLimit(self.id) - self.buyTimes
	})
end

function ActivityFoodFestivalItem:exchange(num)
	local params = {
		award_id = self.id,
		num = num
	}

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FOOD_FESTIVAL, json.encode(params))

	local activityData = self.parent.activityData

	activityData:setChoose(self.id, num)
	xyd.closeWindow("activity_food_festival_exchange_window")
end

return ActivityFoodFestival
