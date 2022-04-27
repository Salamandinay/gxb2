local AdventureBoxPreviewWindow = class("AdventureBoxPreviewWindow", import(".BaseWindow"))

function AdventureBoxPreviewWindow:ctor(name, params)
	AdventureBoxPreviewWindow.super.ctor(self, name, params)

	self.boxID = params.boxID
	self.boxIndex = params.boxIndex
	self.boxUpdateTime = params.updateTime
	self.boxList = params.boxList or {}
end

function AdventureBoxPreviewWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function AdventureBoxPreviewWindow:getUIComponent()
	local groupMain = self.window_:NodeByName("groupMain").gameObject
	self.closeBtn = groupMain:NodeByName("closeBtn").gameObject
	self.labelTitle = groupMain:ComponentByName("labelTitle", typeof(UILabel))
	self.labelCost = groupMain:ComponentByName("groupCost_/labelCost", typeof(UILabel))
	self.btnOpen = groupMain:NodeByName("btnOpen").gameObject
	self.labelOpen = self.btnOpen:ComponentByName("labelOpen", typeof(UILabel))
	self.timeLabel1 = groupMain:ComponentByName("timeGroup/timeLabel1", typeof(UILabel))
	self.timeLabel2 = groupMain:ComponentByName("timeGroup/timeLabel2", typeof(UILabel))
	self.scroller = groupMain:ComponentByName("scroller", typeof(UIScrollView))
	self.awardsContent = self.scroller:ComponentByName("awardsContent", typeof(UIGrid))
end

function AdventureBoxPreviewWindow:layout()
	self.labelTitle.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.labelOpen.text = __("TRAVEL_MAIN_TEXT53")

	if next(self.boxList) then
		self:setBoxs()
	else
		self:setSingleBox()
	end
end

function AdventureBoxPreviewWindow:setSingleBox()
	self.timeLabel1.text = __("COUNT_DOWN2")
	local boxTable = xyd.tables.adventureBoxTable
	local cost = boxTable:getCost(self.boxID)
	self.labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(tonumber(cost[1]))) .. "/" .. cost[2]

	if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
		self.labelCost.text = "[c][ED4D58]" .. xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(tonumber(cost[1]))) .. "[-][/c]" .. "/" .. cost[2]
	end

	local lastTime = boxTable:getTimeCost(self.boxID)
	local duration = self.boxUpdateTime + lastTime - xyd.getServerTime()

	if duration > 0 then
		self.timeLabelCount_ = import("app.components.CountDown").new(self.timeLabel2)

		self.timeLabelCount_:setInfo({
			duration = duration,
			callback = function ()
				self:close()
			end
		})
	else
		self:close()
	end

	local awards = boxTable:getFixAward(self.boxID)
	local ranAward1 = xyd.split2(xyd.models.exploreModel:getExploreInfo().award_ids[self.boxIndex], {
		"|",
		"#"
	}, true)

	for _, award in ipairs(ranAward1) do
		table.insert(awards, award)
	end

	for _, item in ipairs(awards) do
		xyd.getItemIcon({
			uiRoot = self.awardsContent.gameObject,
			itemID = item[1],
			num = item[2],
			dragScrollView = self.scroller
		})
	end
end

function AdventureBoxPreviewWindow:setBoxs()
	self.timeLabel1:SetActive(false)
	self.timeLabel2:SetActive(false)

	local boxTable = xyd.tables.adventureBoxTable
	local costAll = {
		0,
		0
	}
	local awardsAll = {}

	for _, item in ipairs(self.boxList) do
		local cost = boxTable:getCost(item.boxID)
		costAll[1] = cost[1]
		costAll[2] = costAll[2] + tonumber(cost[2])
		local awards = boxTable:getFixAward(item.boxID)

		for _, award in ipairs(awards) do
			if not awardsAll[award[1]] then
				awardsAll[award[1]] = 0
			end

			awardsAll[award[1]] = awardsAll[award[1]] + award[2]
		end

		local ranAward1 = xyd.split2(xyd.models.exploreModel:getExploreInfo().award_ids[item.boxIndex], {
			"|",
			"#"
		}, true)

		for _, award in ipairs(ranAward1) do
			if not awardsAll[award[1]] then
				awardsAll[award[1]] = 0
			end

			awardsAll[award[1]] = awardsAll[award[1]] + award[2]
		end
	end

	self.labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(tonumber(costAll[1]))) .. "/" .. costAll[2]

	if xyd.models.backpack:getItemNumByID(tonumber(costAll[1])) < tonumber(costAll[2]) then
		self.labelCost.text = "[c][ED4D58]" .. xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(tonumber(costAll[1]))) .. "[-][/c]" .. "/" .. costAll[2]
	end

	for item_id, item_num in pairs(awardsAll) do
		xyd.getItemIcon({
			uiRoot = self.awardsContent.gameObject,
			itemID = item_id,
			num = item_num,
			dragScrollView = self.scroller
		})
	end
end

function AdventureBoxPreviewWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnOpen).onClick = function ()
		if next(self.boxList) then
			self:openBoxs()
		else
			self:openSingleBox()
		end
	end
end

function AdventureBoxPreviewWindow:openSingleBox()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	local cost = xyd.tables.adventureBoxTable:getCost(self.boxID)

	if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(cost[1]))))
	else
		local timeStamp = xyd.db.misc:getValue("adventure_box_open_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("explore_buy_tips_window", {
				timeStampKey = "adventure_box_open_stamp",
				text = __("TRAVEL_MAIN_TEXT57", cost[2]),
				yesCallBack = function ()
					xyd.models.exploreModel:reqOpenAdventureChest(self.boxIndex, 1)
					self:close()
				end
			})
		else
			xyd.models.exploreModel:reqOpenAdventureChest(self.boxIndex, 1)
			self:close()
		end
	end
end

function AdventureBoxPreviewWindow:openBoxs()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	local costAll = {
		0,
		0
	}

	for _, item in ipairs(self.boxList) do
		local cost = xyd.tables.adventureBoxTable:getCost(item.boxID)
		costAll[1] = cost[1]
		costAll[2] = tonumber(cost[2]) + costAll[2]
	end

	if xyd.models.backpack:getItemNumByID(tonumber(costAll[1])) < tonumber(costAll[2]) then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(costAll[1]))))
	else
		local list = {}

		for _, item in ipairs(self.boxList) do
			table.insert(list, item.boxIndex)
		end

		local timeStamp = xyd.db.misc:getValue("adventure_box_open_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("explore_buy_tips_window", {
				timeStampKey = "adventure_box_open_stamp",
				text = __("TRAVEL_MAIN_TEXT57", costAll[2]),
				yesCallBack = function ()
					xyd.models.exploreModel:bacthChestOpen(list)
					self:close()
				end
			})
		else
			xyd.models.exploreModel:bacthChestOpen(list)
			self:close()
		end
	end
end

return AdventureBoxPreviewWindow
