local ActivityChristmasSale = class("ActivityChristmasSale", import(".ActivityContent"))
local ActivityChristmasSaleItem = class("ActivityChristmasSaleItem")
local CountDown = import("app.components.CountDown")
local ReplaceIcon = import("app.components.ReplaceIcon")
local json = require("cjson")
local ActivityChristmasSaleAwardsTable = xyd.tables.activityChristmasSaleAwardsTable

function ActivityChristmasSale:ctor(parentGO, params, parent)
	ActivityChristmasSale.super.ctor(self, parentGO, params, parent)
end

function ActivityChristmasSale:getPrefabPath()
	return "Prefabs/Windows/activity/activity_christmas_sale"
end

function ActivityChristmasSale:resizeToParent()
	ActivityChristmasSale.super.resizeToParent(self)
end

function ActivityChristmasSale:initUI()
	self:getUIComponent()
	ActivityChristmasSale.super.initUI(self)
	self:setText()
	self:setContent()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function ActivityChristmasSale:getUIComponent()
	local go = self.go
	self.imgText = go:ComponentByName("imgText", typeof(UISprite))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.labelTime = go:ComponentByName("timeGroup/labelTime", typeof(UILabel))
	self.labelEnd = go:ComponentByName("timeGroup/labelEnd", typeof(UILabel))
	self.labelDesc = go:ComponentByName("labelDesc", typeof(UILabel))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.preViewBtn = go:NodeByName("preViewBtn").gameObject
	self.bottomBg = go:ComponentByName("bottomBg", typeof(UISprite))
	self.scrollView = go:ComponentByName("scroller", typeof(UIScrollView))
	self.item = go:NodeByName("item").gameObject
	self.groupContent = self.scrollView:NodeByName("groupContent").gameObject
	self.resGroup = go:NodeByName("resGroup").gameObject
	self.addBtn = self.resGroup:NodeByName("addBtn").gameObject
	self.countLabel = self.resGroup:ComponentByName("countLabel", typeof(UILabel))
end

function ActivityChristmasSale:setText()
	self.labelDesc.text = __("ACTIVITY_CHRISTMAS_SALE_DESC")
	self.labelEnd.text = __("END")
	self.countLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DEER_CANDY)

	xyd.setUISpriteAsync(self.imgText, nil, "christmas_sale_logo_text_" .. xyd.Global.lang, nil, , true)

	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.labelEnd:SetActive(false)
		self.labelTime:SetActive(false)
	else
		local timeCount = CountDown.new(self.labelTime)

		timeCount:setInfo({
			duration = duration
		})
	end

	if xyd.Global.lang == "de_de" then
		self.timeGroup:GetComponent(typeof(UILayout)).gap = Vector2(10, 0)
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelDesc.width = 330

		self.labelDesc:X(7)
	end
end

function ActivityChristmasSale:onRegister()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_CHRISTMAS_SALE_HELP"
		})
	end

	UIEventListener.Get(self.preViewBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("award_look_window_new")
	end

	UIEventListener.Get(self.addBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			activityData = self.activityData.detail,
			itemID = xyd.ItemID.DEER_CANDY,
			activityID = xyd.ActivityID.ACTIVITY_CHRISTMAS_SALE
		})
	end
end

function ActivityChristmasSale:setContent()
	local ids = ActivityChristmasSaleAwardsTable:getIds()
	local limits = self.activityData.detail.limits
	local cost = self.activityData.detail.cost
	local list = {}

	for _, id in pairs(ids) do
		table.insert(list, {
			id = id,
			leftTimes = ActivityChristmasSaleAwardsTable:getLimit(id) - limits[id].limit,
			cost = cost
		})
	end

	table.sort(list, function (a, b)
		if a.leftTimes == 0 and b.leftTimes ~= 0 then
			return false
		elseif a.leftTimes ~= 0 and b.leftTimes == 0 then
			return true
		else
			return a.id < b.id
		end
	end)

	self.contentList = {}

	for _, item in pairs(list) do
		local tmp = NGUITools.AddChild(self.groupContent, self.item)
		local child = ActivityChristmasSaleItem.new(tmp, self, item)
		self.contentList[item.id] = child
	end

	self:waitForFrame(1, function ()
		self.scrollView:ResetPosition()
	end)
end

function ActivityChristmasSale:onAward(event)
	if event.data.activity_id == xyd.ActivityID.ACTIVITY_CHRISTMAS_SALE then
		local awardId = self.activityData.awardId
		local awardNum = self.activityData.awardNum or 1
		local items = {}
		local fixAwards = ActivityChristmasSaleAwardsTable:getAwards(awardId, 0)

		for i = 1, #fixAwards do
			local data = fixAwards[i]

			table.insert(items, {
				item_id = tonumber(data[1]),
				item_num = tonumber(data[2]) * awardNum
			})
		end

		local temp = self.activityData.detail[tostring(awardId)]
		local opAwardsIndexs = xyd.split(temp, "|", true)
		local opAwardsnum = ActivityChristmasSaleAwardsTable:getOpAwardsNum(awardId)

		for i = 1, opAwardsnum do
			local awards = ActivityChristmasSaleAwardsTable:getAwards(awardId, i)
			local index = opAwardsIndexs[i]
			local data = awards[index][1]

			table.insert(items, {
				item_id = tonumber(data[1]),
				item_num = tonumber(data[2]) * awardNum
			})
		end

		self:itemFloat(items)

		local awardId = self.activityData.awardId
		local leftTimes = ActivityChristmasSaleAwardsTable:getLimit(awardId) - self.activityData.detail.limits[awardId].limit

		self.contentList[awardId]:updateLeftTimes(leftTimes)

		for _, item in pairs(self.contentList) do
			item:updateCost()
		end

		self.activityData.awardNum = nil
	end
end

function ActivityChristmasSale:onItemChange(event)
	local items = event.data.items

	for _, item in ipairs(items) do
		if item.item_id == xyd.ItemID.DEER_CANDY then
			self.countLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DEER_CANDY)
		end
	end
end

function ActivityChristmasSaleItem:ctor(go, parent, params)
	self.go = go
	self.parent = parent
	self.data = params
	self.isLock = self.data.cost < ActivityChristmasSaleAwardsTable:getRequirement(self.data.id)

	self:initUI()
end

function ActivityChristmasSaleItem:initUI()
	self:getUIComponent()
	self:setText()
	self:initIcon()
	self:setIcon()

	UIEventListener.Get(self.purchaseBtn).onClick = handler(self, self.onExchange)

	xyd.setDragScrollView(self.purchaseBtn, self.parent.scrollView)
end

function ActivityChristmasSaleItem:getUIComponent()
	local group1 = self.go:NodeByName("group1").gameObject
	self.showLayout = group1:ComponentByName("e:Group", typeof(UILayout))
	self.groupAward = group1:NodeByName("e:Group/groupAward").gameObject
	self.add = group1:NodeByName("e:Group/add").gameObject
	self.groupOpAward = group1:NodeByName("e:Group/groupOpAward").gameObject
	self.add = group1:NodeByName("e:Group/add").gameObject
	self.purchaseBtn = group1:NodeByName("purchaseBtn").gameObject
	self.button_label = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.button_icon = self.purchaseBtn:ComponentByName("icon_", typeof(UISprite))
	self.redMark = self.purchaseBtn:NodeByName("redMark").gameObject

	self.redMark:SetActive(false)

	local group2 = self.go:NodeByName("group2").gameObject
	self.labelLimit = group2:ComponentByName("labelLimit", typeof(UILabel))
end

function ActivityChristmasSaleItem:setText()
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", self.data.leftTimes)
end

function ActivityChristmasSaleItem:initIcon()
	local fixAwards = ActivityChristmasSaleAwardsTable:getAwards(self.data.id, 0)
	self.fixAwardsIcon = {}

	for i = 1, #fixAwards do
		local data = fixAwards[i]
		local icon = xyd.getItemIcon({
			show_has_num = true,
			wndType = 5,
			scale = 0.7407407407407407,
			itemID = tonumber(data[1]),
			num = tonumber(data[2]),
			uiRoot = self.groupAward,
			isNew = xyd.tables.itemTable:getType(tonumber(data[1])) == xyd.ItemType.ARTIFACT
		})

		icon:setDragScrollView(self.parent.scrollView)
		table.insert(self.fixAwardsIcon, icon)
	end

	self.add:X(self.add.transform.localPosition.x + 87 * (#self.fixAwardsIcon - 1))
	self.groupOpAward:X(self.groupOpAward.transform.localPosition.x + 87 * (#self.fixAwardsIcon - 1))

	self.opAwardsnum = ActivityChristmasSaleAwardsTable:getOpAwardsNum(self.data.id)

	if self.opAwardsnum == 0 then
		self.add:SetActive(false)

		return
	end

	self.opAwardsIcon = {}

	for i = 1, self.opAwardsnum do
		local icon = ReplaceIcon.new(self.groupOpAward, {
			scrollView = self.parent.scrollView,
			callback = function ()
				self:openSelectWindow(i)
			end
		})

		icon:SetLocalScale(0.7407407407407407, 0.7407407407407407, 0.7407407407407407)
		icon:setDragScrollView(self.parent.scrollView)
		table.insert(self.opAwardsIcon, icon)

		UIEventListener.Get(icon:getGameObject()).onClick = function ()
			if icon.itemID then
				return
			end

			self:openSelectWindow(i)
		end
	end
end

function ActivityChristmasSaleItem:setIcon()
	if self.data.leftTimes == 0 and self.opAwardsnum ~= 0 then
		self:setOpAward()
	else
		self:setBtn()
	end
end

function ActivityChristmasSaleItem:setBtn()
	if self.data.leftTimes == 0 then
		self.button_icon:SetActive(true)
		xyd.setUISpriteAsync(self.button_icon, nil, xyd.tables.itemTable:getSmallIconNew(xyd.ItemID.DEER_CANDY), nil, , true)
		xyd.applyGrey(self.purchaseBtn:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.purchaseBtn, false)

		self.button_label.text = ActivityChristmasSaleAwardsTable:getCost(self.data.id)[2]

		self.button_label:ApplyGrey()
		self:setBtnPosition()
	elseif self.isLock then
		self.button_icon:SetActive(true)
		xyd.setUISpriteAsync(self.button_icon, nil, "awake_lock", nil, , true)

		self.button_label.text = self.data.cost .. "/" .. ActivityChristmasSaleAwardsTable:getRequirement(self.data.id)

		self:setBtnPosition()
	else
		self.button_icon:SetActive(true)
		xyd.setUISpriteAsync(self.button_icon, nil, xyd.tables.itemTable:getSmallIconNew(xyd.ItemID.DEER_CANDY), nil, , true)

		self.button_label.text = ActivityChristmasSaleAwardsTable:getCost(self.data.id)[2]

		self:setBtnPosition()
	end
end

function ActivityChristmasSaleItem:setBtnPosition()
	local width1 = self.button_icon.width
	local width2 = self.button_label.width

	self.button_label:X(width1 / 2 + 5.5)
	self.button_icon:X(-5.5 - width2 / 2)
end

function ActivityChristmasSaleItem:setOpAward(opAwards)
	if opAwards then
		self.opAwards = opAwards
		self.selectAwardsNum = #opAwards
	elseif self.data.leftTimes == 0 then
		local temp = self.parent.activityData.detail[tostring(self.data.id)]
		local opAwardsIndexs = xyd.split(temp, "|", true)
		self.selectAwardsNum = self.opAwardsnum
		self.opAwards = {}

		for i = 1, self.opAwardsnum do
			local awards = ActivityChristmasSaleAwardsTable:getAwards(self.data.id, i)
			local index = opAwardsIndexs[i]

			table.insert(self.opAwards, awards[index][1])
		end
	else
		local temp = self.parent.activityData.detail[tostring(self.data.id)]
		local opAwardsIndexs = xyd.split(temp, "|", true)

		for i = 1, self.opAwardsnum do
			local awards = ActivityChristmasSaleAwardsTable:getAwards(self.data.id, i)
			local index = opAwardsIndexs[i]
			local buyTimes = self.parent.activityData.detail.limits[self.data.id]["limit" .. i][index]

			if buyTimes == tonumber(awards[index][2][1]) then
				self.opAwards[i] = nil
				self.selectAwardsNum = self.selectAwardsNum - 1
			end
		end
	end

	for i = 1, self.opAwardsnum do
		if self.opAwards[i] then
			local data = self.opAwards[i]

			if self.opAwardsIcon[i].itemID ~= data[1] then
				self.opAwardsIcon[i]:setIcon(data[1], tonumber(data[2]))
			end
		else
			self.opAwardsIcon[i]:setIcon(nil, )
		end
	end

	self:setBtn()
end

function ActivityChristmasSaleItem:onExchange()
	if self.data.leftTimes == 0 then
		return
	elseif self.isLock then
		xyd.showToast(__("ACTIVITY_CHRISTMAS_SALE_NEED_COST", ActivityChristmasSaleAwardsTable:getRequirement(self.data.id), xyd.tables.itemTable:getName(xyd.ItemID.DEER_CANDY)))
	elseif self.opAwardsnum == 0 or self.opAwards and self.selectAwardsNum == self.opAwardsnum then
		if self.data.id == 1 then
			local cost = ActivityChristmasSaleAwardsTable:getCost(self.data.id)

			if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(cost[1]))))

				return
			end

			xyd.WindowManager.get():openWindow("common_use_cost_window", {
				select_max_num = math.min(math.floor(xyd.models.backpack:getItemNumByID(tonumber(cost[1])) / tonumber(cost[2])), self.data.leftTimes),
				show_max_num = math.floor(xyd.models.backpack:getItemNumByID(tonumber(cost[1]))),
				select_multiple = tonumber(cost[2]),
				icon_info = {
					height = 34,
					name = "icon_194",
					width = 34
				},
				title_text = __("ACTIVITY_BLACKFRIDAYSHOP_TEXT1"),
				explain_text = __("ACTIVITY_BLACKFRIDAYSHOP_TEXT2"),
				sure_callback = function (num)
					local params = json.encode({
						table_id = tonumber(self.data.id),
						num = num
					})

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_CHRISTMAS_SALE, params)
					self.parent.activityData:setAwardNum(num)
					self.parent.activityData:setAwardId(self.data.id)

					local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

					if common_use_cost_window_wd then
						xyd.WindowManager.get():closeWindow("common_use_cost_window")
					end
				end
			})
		else
			local canBuy = tonumber(ActivityChristmasSaleAwardsTable:getCost(self.data.id)[2]) <= xyd.models.backpack:getItemNumByID(xyd.ItemID.DEER_CANDY)

			if canBuy then
				xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_CHANGE"), function (yes)
					if yes then
						local params = json.encode({
							table_id = tonumber(self.data.id)
						})

						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_CHRISTMAS_SALE, params)
						self.parent.activityData:setAwardId(self.data.id)
					end
				end)
			else
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.DEER_CANDY)))
			end
		end
	else
		self:openSelectWindow(1)
	end
end

function ActivityChristmasSaleItem:openSelectWindow(index)
	xyd.WindowManager.get():openWindow("activity_christmas_sale_award_select_window", {
		item = self,
		index = index,
		opAwards = self.opAwards,
		id = self.data.id,
		leftTimes = self.data.leftTimes
	})
end

function ActivityChristmasSaleItem:updateCost()
	if not self.isLock then
		return
	end

	self.data.cost = self.parent.activityData.detail.cost
	self.isLock = self.data.cost < ActivityChristmasSaleAwardsTable:getRequirement(self.data.id)

	self:setBtn()
end

function ActivityChristmasSaleItem:updateLeftTimes(leftTimes)
	self.data.leftTimes = leftTimes

	self:setText()

	if leftTimes == 0 or self.opAwardsnum == 0 then
		self:setBtn()
	else
		self:setOpAward()
	end
end

return ActivityChristmasSale
