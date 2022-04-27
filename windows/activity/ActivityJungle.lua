local ActivityContent = import(".ActivityContent")
local ActivityJungle = class("ActivityJungle", ActivityContent)
local ActivityJungleItem = class("ActivityJungleItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local ItemTable = xyd.tables.itemTable
local json = require("cjson")

function ActivityJungle:ctor(name, params)
	self.resourcesID = {
		256,
		257,
		255
	}
	self.maxPointArea1 = 0
	self.maxPointArea2 = 0
	self.maxPointArea3 = 0
	self.exchangeID = 0

	ActivityContent.ctor(self, name, params)
end

function ActivityJungle:getPrefabPath()
	return "Prefabs/Windows/activity/activity_jungle"
end

function ActivityJungle:initUI()
	self:getUIComponent()
	ActivityJungle.super.initUI(self)
	self:initUIComponent()
	self:initShopData()
	self:initExploreData()

	local index = 1
	index = index or 1

	self:updateContent(tonumber(index))
end

function ActivityJungle:getUIComponent()
	self.trans = self.go
	self.Bg__uiTexture = self.trans:ComponentByName("Bg_", typeof(UITexture))
	self.titleImg_ = self.trans:ComponentByName("titleImg_", typeof(UISprite))
	self.helpBtn = self.trans:NodeByName("helpBtn").gameObject
	self.timeGroup = self.trans:NodeByName("timeGroup").gameObject
	self.timeGroup_uiLayout = self.trans:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.navGroup = self.trans:NodeByName("navGroup").gameObject
	self.nav_1 = self.navGroup:NodeByName("nav_1").gameObject
	self.nav_2 = self.navGroup:NodeByName("nav_2").gameObject
	self.navButton1 = self.navGroup:ComponentByName("nav_1", typeof(UIButton))
	self.navLabel1 = self.nav_1:ComponentByName("label_", typeof(UILabel))
	self.navButton2 = self.navGroup:ComponentByName("nav_2", typeof(UIButton))
	self.navLabel2 = self.nav_2:ComponentByName("label_", typeof(UILabel))
	self.redMark_nav_2 = self.nav_2:NodeByName("redMark").gameObject
	self.contentGroup = self.trans:NodeByName("contentGroup").gameObject
	self.scroller = self.contentGroup:NodeByName("scroller").gameObject
	self.scrollView = self.contentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.activity_jungle_item = self.scroller:NodeByName("activity_jungle_item").gameObject
	self.drag = self.contentGroup:NodeByName("drag").gameObject
	self.resourcesGroup = self.trans:NodeByName("resourcesGroup").gameObject
	self.resource_1 = self.resourcesGroup:NodeByName("resource_1").gameObject
	self.resourceLabel1 = self.resource_1:ComponentByName("label_", typeof(UILabel))
	self.addBtn1 = self.resource_1:NodeByName("addBtn").gameObject
	self.resource_2 = self.resourcesGroup:NodeByName("resource_2").gameObject
	self.resourceLabel2 = self.resource_2:ComponentByName("label_", typeof(UILabel))
	self.addBtn2 = self.resource_2:NodeByName("addBtn").gameObject
	self.resource_3 = self.resourcesGroup:NodeByName("resource_3").gameObject
	self.resourceLabel3 = self.resource_3:ComponentByName("label_", typeof(UILabel))
	self.addBtn3 = self.resource_3:NodeByName("addBtn").gameObject
	self.exploreItemGroup = self.trans:NodeByName("exploreItemGroup").gameObject
	self.tipLabel_explore_1 = self.resourcesGroup:NodeByName("tipLabel_explore_1").gameObject
	self.tipLabel_explore_2 = self.exploreItemGroup:NodeByName("tipLabel_explore_2").gameObject
	self.activity_jungle_explore_item1 = self.exploreItemGroup:NodeByName("activity_jungle_explore_item1").gameObject
	self.activity_jungle_explore_item2 = self.exploreItemGroup:NodeByName("activity_jungle_explore_item2").gameObject
	self.activity_jungle_explore_item3 = self.exploreItemGroup:NodeByName("activity_jungle_explore_item3").gameObject
	self.giftBtn1 = self.activity_jungle_explore_item1:NodeByName("giftBtn").gameObject
	self.giftBtn2 = self.activity_jungle_explore_item2:NodeByName("giftBtn").gameObject
	self.giftBtn3 = self.activity_jungle_explore_item3:NodeByName("giftBtn").gameObject
	self.processBtn1 = self.activity_jungle_explore_item1:NodeByName("processBtn").gameObject
	self.redMark_processBtn1 = self.processBtn1:NodeByName("redMark").gameObject
	self.processBtn2 = self.activity_jungle_explore_item2:NodeByName("processBtn").gameObject
	self.redMark_processBtn2 = self.processBtn2:NodeByName("redMark").gameObject
	self.processBtn3 = self.activity_jungle_explore_item3:NodeByName("processBtn").gameObject
	self.redMark_processBtn3 = self.processBtn3:NodeByName("redMark").gameObject
end

function ActivityJungle:resizeToParent()
	ActivityJungle.super.resizeToParent(self)
	self:resizePosY(self.exploreItemGroup, -468, -585)
	self:resizePosY(self.activity_jungle_explore_item1, -68, -48)
	self:resizePosY(self.activity_jungle_explore_item2, -68, -48)
end

function ActivityJungle:initUIComponent()
	xyd.setUISpriteAsync(self.titleImg_, nil, "jungle_logo_" .. xyd.Global.lang)
	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel_.text = __("TEXT_END")
	self.navLabel1.text = __("ACTIVITY_JUNGLE_TEXT01")
	self.navLabel2.text = __("ACTIVITY_JUNGLE_TEXT02")
	self.resourceLabel1.text = xyd.models.backpack:getItemNumByID(self.resourcesID[1])
	self.resourceLabel2.text = xyd.models.backpack:getItemNumByID(self.resourcesID[2])
	self.resourceLabel3.text = xyd.models.backpack:getItemNumByID(self.resourcesID[3])
	self.giftBtn1:ComponentByName("label", typeof(UILabel)).text = __("ACTIVITY_JUNGLE_TEXT04")
	self.giftBtn2:ComponentByName("label", typeof(UILabel)).text = __("ACTIVITY_JUNGLE_TEXT04")
	self.giftBtn3:ComponentByName("label", typeof(UILabel)).text = __("ACTIVITY_JUNGLE_TEXT04")
	self.tipLabel_explore_1:ComponentByName("", typeof(UILabel)).text = __("ACTIVITY_JUNGLE_TEXT03")
	self.tipLabel_explore_2:ComponentByName("", typeof(UILabel)).text = __("ACTIVITY_JUNGLE_TEXT05")

	if xyd.Global.lang == "de_de" then
		self.trans:ComponentByName("timeGroup", typeof(UIWidget)).width = 340
	end

	if xyd.Global.lang == "fr_fr" then
		self.trans:ComponentByName("timeGroup", typeof(UIWidget)).width = 300
	end
end

function ActivityJungle:initShopData()
	local buyTimes = self.activityData.detail.buy_times
	self.shopData = {}
	local ids = xyd.tables.ActivityJungleShopTable:getIDs()

	for i = 1, #ids do
		local id = i
		local isCompleted = xyd.tables.ActivityJungleShopTable:getLimit(id) <= buyTimes[i]

		table.insert(self.shopData, {
			id = tonumber(id),
			awards = xyd.tables.ActivityJungleShopTable:getAwards(id),
			isCompleted = isCompleted,
			cost = xyd.tables.ActivityJungleShopTable:getCost(id),
			limit = xyd.tables.ActivityJungleShopTable:getLimit(id),
			buyTimes = buyTimes[i]
		})
	end

	local function sort_func(a, b)
		if a.isCompleted == b.isCompleted then
			return a.id < b.id
		elseif a.isCompleted then
			return false
		else
			return true
		end
	end

	table.sort(self.shopData, sort_func)

	if self.wrapContent == nil then
		local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.activity_jungle_item, ActivityJungleItem, self)
	end
end

function ActivityJungle:initExploreData()
	for i = 1, 3 do
		self["exploreData" .. i] = {}
		local ids = xyd.tables.ActivityJungleAwardsTable:getIDs()

		for j = 1, #ids do
			local id = ids[j]
			local isCompleted = false
			local area = xyd.tables.ActivityJungleAwardsTable:getArea(id)
			local point = xyd.tables.ActivityJungleAwardsTable:getPoint(id)

			if area == i then
				if self["maxPointArea" .. i] < point then
					self["maxPointArea" .. i] = point
				end

				table.insert(self["exploreData" .. i], {
					id = tonumber(id),
					awards = xyd.tables.ActivityJungleAwardsTable:getAwards(id),
					isCompleted = isCompleted,
					point = point,
					area = area
				})
			end
		end
	end
end

function ActivityJungle:updateContent(index)
	self:updateRedMask()

	if index == 1 then
		self.navLabel1.color = Color.New2(47244640255.0)
		self.navLabel1.effectColor = Color.New2(1012112383)
		self.navLabel2.color = Color.New2(960513791)
		self.navLabel2.effectColor = Color.New2(4294967295.0)

		self.navButton1:SetEnabled(false)
		self.navButton2:SetEnabled(true)
		self.tipLabel_explore_1:SetActive(false)
		self.exploreItemGroup:SetActive(false)
		self.resource_1:SetActive(true)
		self.resource_2:SetActive(true)
		self.resource_3:SetActive(false)
		self.itemGroup:SetActive(true)
		self.wrapContent:setInfos(self.shopData, {})

		self.resourceLabel1.text = xyd.models.backpack:getItemNumByID(self.resourcesID[1])
		self.resourceLabel2.text = xyd.models.backpack:getItemNumByID(self.resourcesID[2])
	else
		self.navLabel1.color = Color.New2(960513791)
		self.navLabel1.effectColor = Color.New2(4294967295.0)
		self.navLabel2.color = Color.New2(47244640255.0)
		self.navLabel2.effectColor = Color.New2(1012112383)

		self.navButton1:SetEnabled(true)
		self.navButton2:SetEnabled(false)
		self.tipLabel_explore_1:SetActive(true)
		self.exploreItemGroup:SetActive(true)
		self.resource_1:SetActive(false)
		self.resource_2:SetActive(false)
		self.resource_3:SetActive(true)
		self.itemGroup:SetActive(false)
		self:updateExploreProgress()

		self.resourceLabel3.text = xyd.models.backpack:getItemNumByID(self.resourcesID[3])
	end
end

function ActivityJungle:onRegister()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.USE_JUNGLE_ITEM, handler(self, self.onGetUseJungleItem))
	self:registerEvent(xyd.event.GET_JUNGLE_AWARD, handler(self, self.onGetJungleAward))

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_JUNGLE_HELP"
		})
	end

	UIEventListener.Get(self.addBtn1).onClick = function ()
		self:updateContent(2)
	end

	UIEventListener.Get(self.addBtn2).onClick = function ()
		local params = {
			showGetWays = true,
			itemID = self.resourcesID[2],
			itemNum = xyd.models.backpack:getItemNumByID(self.resourcesID[2]),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.addBtn3).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			activityData = self.activityData.detail,
			itemID = self.resourcesID[3],
			activityID = xyd.ActivityID.ActivityJungle
		})
	end

	UIEventListener.Get(self.nav_1).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
		self:updateContent(1)
	end

	UIEventListener.Get(self.nav_2).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
		xyd.db.misc:setValue({
			value = false,
			key = "ExploreRedMark_nav_2"
		})
		self:updateContent(2)
		self:updateRedMask()
	end

	for i = 1, 3 do
		UIEventListener.Get(self["giftBtn" .. i]).onClick = function ()
			local singleCost = self.activityData.singleCost[2]
			local num = xyd.models.backpack:getItemNumByID(self.resourcesID[3])

			if num < singleCost then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.resourcesID[3])))

				return
			end

			local resource_num = xyd.models.backpack:getItemNumByID(self.resourcesID[3])
			local select_max_num = math.floor(resource_num / singleCost)
			local now_point = self.activityData.detail.points[i]
			local left_point = self["maxPointArea" .. i] - now_point
			local show_max_num = resource_num

			if left_point > 0 then
				select_max_num = math.min(math.floor(left_point / singleCost), math.floor(resource_num / singleCost))
			end

			if left_point <= 0 then
				local timeStamp = xyd.db.misc:getValue("jungle_explore_time_stamp")

				if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
					xyd.WindowManager.get():openWindow("gamble_tips_window", {
						type = "jungle_explore",
						callback = function ()
							xyd.WindowManager.get():openWindow("common_use_cost_window", {
								select_max_num = select_max_num,
								show_max_num = resource_num,
								select_multiple = singleCost,
								icon_info = {
									height = 45,
									width = 45,
									name = "icon_" .. self.resourcesID[3]
								},
								title_text = __("TIPS"),
								explain_text = __("ACTIVITY_JUNGLE_TEXT06"),
								sure_callback = function (num)
									self:useJungleItem(i, num * singleCost)

									local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

									if common_use_cost_window_wd then
										xyd.WindowManager.get():closeWindow("common_use_cost_window")
									end
								end
							})
						end,
						text = __("ACTIVITY_JUNGLE_TEXT09")
					})

					return
				end
			end

			xyd.WindowManager.get():openWindow("common_use_cost_window", {
				select_max_num = select_max_num,
				show_max_num = resource_num,
				select_multiple = singleCost,
				icon_info = {
					height = 45,
					width = 45,
					name = "icon_" .. self.resourcesID[3]
				},
				title_text = __("ACTIVITY_JUNGLE_TEXT02"),
				explain_text = __("ACTIVITY_JUNGLE_TEXT06"),
				sure_callback = function (num)
					self:useJungleItem(i, num * singleCost)

					local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

					if common_use_cost_window_wd then
						xyd.WindowManager.get():closeWindow("common_use_cost_window")
					end
				end
			})
		end

		UIEventListener.Get(self["processBtn" .. i]).onClick = function ()
			xyd.db.misc:setValue({
				value = false,
				key = "ExploreProgressRedMark" .. i
			})
			self:updateRedMask()

			local activityData = xyd.models.activity:getActivity(self.id)
			local all_info = {}
			local ids = xyd.tables.ActivityJungleAwardsTable:getIDs()

			for j in pairs(ids) do
				if xyd.tables.ActivityJungleAwardsTable:getArea(j) == i then
					local data = {
						id = j,
						max_value = xyd.tables.ActivityJungleAwardsTable:getPoint(j)
					}
					data.name = __("ACTIVITY_JUNGLE_TEXT08", math.floor(data.max_value))
					data.cur_value = tonumber(activityData.detail.points[i])

					if data.max_value < data.cur_value then
						data.cur_value = data.max_value
					end

					data.items = xyd.tables.ActivityJungleAwardsTable:getAwards(j)

					if activityData.detail.awarded[j] == 0 then
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
			end

			xyd.WindowManager.get():openWindow("common_progress_award_window", {
				if_sort = true,
				all_info = all_info,
				title_text = __("ACTIVITY_JUNGLE_TEXT07"),
				click_callBack = function (info)
					if self.activityData:getEndTime() <= xyd.getServerTime() then
						xyd.alertTips(__("ACTIVITY_END_YET"))

						return
					end

					self:GetJungleAward(info.id)
				end,
				wnd_type = xyd.CommonProgressAwardWindowType.ACTIVITY_JUNGLE
			})
		end
	end
end

function ActivityJungle:updateExploreProgress()
	for i = 1, 3 do
		local now_point = self.activityData.detail.points[i]
		local left_point = self["maxPointArea" .. i] - now_point
		local completeGroup = self["processBtn" .. i]:NodeByName("completeGroup").gameObject
		local processValue = Mathf.Floor(now_point / self["maxPointArea" .. i] * 100)
		local valueLabel = self["processBtn" .. i]:ComponentByName("processLabel", typeof(UILabel))
		local processRadio = self["processBtn" .. i]:ComponentByName("", typeof(UISprite))
		processRadio.fillAmount = processValue / 100

		if left_point > 0 then
			valueLabel.text = processValue .. "%"

			completeGroup:SetActive(false)
		end

		if left_point <= 0 then
			completeGroup:SetActive(true)
			valueLabel:SetActive(false)
		end
	end
end

function ActivityJungle:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local allItem = {}

	if data and data.activity_id == xyd.ActivityID.ACTIVITY_JUNGLE then
		local awards = xyd.tables.ActivityJungleShopTable:getAwards(self.activityData.exchangeID)

		for i = 1, #awards do
			local award = awards[i]
			local item = {
				item_id = award[1],
				item_num = award[2] * self.activityData.exchangeTime
			}

			table.insert(allItem, item)
		end

		xyd.models.itemFloatModel:pushNewItems(allItem)
		self:initShopData()
		self.wrapContent:setInfos(self.shopData, {
			keepPosition = true
		})

		self.resourceLabel1.text = xyd.models.backpack:getItemNumByID(self.resourcesID[1])
		self.resourceLabel2.text = xyd.models.backpack:getItemNumByID(self.resourcesID[2])
	end
end

function ActivityJungle:onGetUseJungleItem(event)
	local data = xyd.decodeProtoBuf(event.data)
	local allItem = {}

	for i = 1, #self.activityData.item_info do
		local award = self.activityData.item_info[i]
		local item = {
			item_id = award.item_id,
			item_num = award.item_num
		}

		table.insert(allItem, item)
	end

	xyd.models.itemFloatModel:pushNewItems(allItem)
	self:initShopData()
	self:updateContent(2)
end

function ActivityJungle:onGetJungleAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local allItem = {}
	local awards = xyd.tables.ActivityJungleAwardsTable:getAwards(self.activityData.awardedID)

	for i = 1, #awards do
		local award = awards[i]
		local item = {
			item_id = award[1],
			item_num = award[2]
		}

		table.insert(allItem, item)
	end

	xyd.models.itemFloatModel:pushNewItems(allItem)
	self:initShopData()
	self:updateContent(2)
end

function ActivityJungle:useJungleItem(area, num)
	local msg = messages_pb:use_jungle_item_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_JUNGLE
	msg.num = num
	msg.area = area

	xyd.Backend.get():request(xyd.mid.USE_JUNGLE_ITEM, msg)

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_JUNGLE)
end

function ActivityJungle:GetJungleAward(id)
	local msg = messages_pb:get_jungle_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_JUNGLE
	msg.id = tonumber(id)

	xyd.Backend.get():request(xyd.mid.GET_JUNGLE_AWARD, msg)

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_JUNGLE)
end

function ActivityJungle:updateRedMask()
	if self.activityData:getRedMarkState() or xyd.db.misc:getValue("ExploreRedMark_nav_2") == nil then
		self.redMark_nav_2:SetActive(true)
	else
		self.redMark_nav_2:SetActive(false)
	end

	for i = 1, 3 do
		if self.activityData:getExploreProgressRedMarkState(i) then
			self["redMark_processBtn" .. i]:SetActive(true)
		else
			self["redMark_processBtn" .. i]:SetActive(false)
		end
	end
end

function ActivityJungleItem:ctor(go, parent)
	ActivityJungleItem.super.ctor(self, go, parent)
end

function ActivityJungleItem:initUI()
	local go = self.go
	self.exchangeBtn = go:NodeByName("exchangeBtn").gameObject
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.awardItemGroup = self.itemGroup:NodeByName("awardItemGroup").gameObject
	self.requestmentItemGroup = self.itemGroup:NodeByName("requestmentItemGroup").gameObject
	self.groupCost_1 = self.requestmentItemGroup:NodeByName("groupCost_1").gameObject
	self.groupCost_2 = self.requestmentItemGroup:NodeByName("groupCost_2").gameObject
	self.labelLimit = self.go:ComponentByName("label", typeof(UILabel))
	self.exchangeLabel = self.exchangeBtn:ComponentByName("exchangeLabel", typeof(UILabel))
	self.exchangeLabel.text = __("EXCHANGE")
end

function ActivityJungleItem:updateInfo()
	self.buyTimes = tonumber(self.data.buyTimes)
	self.id = self.data.id
	self.awards = self.data.awards
	self.cost = self.data.cost
	self.isCompleted = self.data.isCompleted
	self.limit = self.data.limit
	self.labelLimit.text = __("LIMIT_BUY", self.limit - self.buyTimes)

	NGUITools.DestroyChildren(self.awardItemGroup.transform)

	for i = 1, #self.awards do
		local data = self.awards[i]
		local icon = xyd.getItemIcon({
			show_has_num = true,
			hideText = true,
			scale = 0.7,
			uiRoot = self.awardItemGroup,
			itemID = data[1],
			num = data[2],
			dragScrollView = self.parent.scrollView
		})

		if self.isCompleted then
			icon:setChoose(true)
		end
	end

	self.awardItemGroup:GetComponent(typeof(UILayout)):Reposition()

	for i = 1, 2 do
		local groupCost = self["groupCost_" .. i]

		groupCost:SetActive(false)
	end

	for i = 1, #self.cost do
		local data = self.cost[i]
		local groupCost = self["groupCost_" .. i]

		xyd.setUISpriteAsync(groupCost:ComponentByName("costRes", typeof(UISprite)), nil, ItemTable:getIcon(data[1]))

		groupCost:ComponentByName("costLabel", typeof(UILabel)).text = data[2]

		if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
			groupCost:ComponentByName("costLabel", typeof(UILabel)).color = Color.New2(4280030207.0)
		else
			groupCost:ComponentByName("costLabel", typeof(UILabel)).color = Color.New2(960513791)
		end

		groupCost:SetActive(true)
	end

	if self.buyTimes < self.limit then
		xyd.applyChildrenOrigin(self.exchangeBtn.gameObject)

		self.exchangeBtn:ComponentByName("", typeof(UnityEngine.BoxCollider)).enabled = true

		UIEventListener.Get(self.exchangeBtn).onClick = function ()
			self:onExchange()
		end
	else
		self.exchangeBtn:ComponentByName("", typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.exchangeBtn.gameObject)
	end
end

function ActivityJungleItem:onExchange()
	for i = 1, #self.cost do
		local data = self.cost[i]
		local num = xyd.models.backpack:getItemNumByID(data[1])

		if num < data[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(data[1])))

			return
		end
	end

	local select_multiple = self.cost[1][2]
	local costItemId = self.cost[1][1]
	local leftTimes = self.limit - self.buyTimes
	local costItemNum = xyd.models.backpack:getItemNumByID(costItemId)

	if leftTimes == 0 then
		return
	end

	if leftTimes <= 5 then
		local timeStamp = xyd.db.misc:getValue("jungle_shop_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "jungle_shop",
				callback = function ()
					self:exchange(1)
				end,
				text = __("CONFIRM_BUY")
			})

			return
		end

		self:exchange(1)

		return
	end

	local select_max_num = leftTimes

	if Mathf.Floor(costItemNum / select_multiple) < select_max_num then
		select_max_num = Mathf.Floor(costItemNum / select_multiple)
	end

	xyd.WindowManager.get():openWindow("common_use_cost_window", {
		select_max_num = select_max_num,
		show_max_num = costItemNum,
		select_multiple = select_multiple,
		icon_info = {
			height = 45,
			width = 45,
			name = "icon_" .. costItemId
		},
		title_text = __("BUY"),
		explain_text = __("ACTIVITY_ICE_SUMMER_INPUT"),
		sure_callback = function (num)
			local buy_time = num

			self:exchange(buy_time)

			local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

			if common_use_cost_window_wd then
				xyd.WindowManager.get():closeWindow("common_use_cost_window")
			end
		end
	})
end

function ActivityJungleItem:exchange(num)
	local params = {
		award_id = self.id,
		num = num
	}

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_JUNGLE, json.encode(params))

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_JUNGLE)

	activityData:setExchangeInfo(self.id, num)
end

return ActivityJungle
