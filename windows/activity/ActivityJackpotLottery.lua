local ActivityContent = import(".ActivityContent")
local ActivityJackpotLottery = class("ActivityJackpotLottery", ActivityContent)
local IconItem = class("IconItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivityJackpotLottery:ctor(parentGO, params, parent)
	ActivityJackpotLottery.super.ctor(self, parentGO, params, parent)
end

function ActivityJackpotLottery:getPrefabPath()
	return "Prefabs/Windows/activity/activity_jackpot_lottery"
end

function ActivityJackpotLottery:initUI()
	self:getUIComponent()
	ActivityJackpotLottery.super.initUI(self)
	self:initUIComponent()

	local privilegeCardGiftID = xyd.tables.miscTable:getNumber("activity_jackpot_gift", "value")
	self.isOwnPrivilegeCard = false
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.JACKPOT_MACHINE)

	for i = 1, #activityData.detail.charges do
		if activityData.detail.charges[i].table_id == privilegeCardGiftID and activityData.detail.charges[i].buy_times > 0 then
			self.isOwnPrivilegeCard = true

			break
		end
	end
end

function ActivityJackpotLottery:getUIComponent()
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.helpBtn = self.groupAction:NodeByName("helpBtn").gameObject
	self.resCon = self.groupAction:NodeByName("resCon").gameObject
	self.resGroup1 = self.resCon:NodeByName("resGroup1").gameObject
	self.resLabel1 = self.resGroup1:ComponentByName("label", typeof(UILabel))
	self.resBtn1 = self.resGroup1:NodeByName("btn").gameObject
	self.resGroup2 = self.resCon:NodeByName("resGroup2").gameObject
	self.resLabel2 = self.resGroup2:ComponentByName("label", typeof(UILabel))
	self.resBtn2 = self.resGroup2:NodeByName("btn").gameObject
	self.allCon = self.groupAction:NodeByName("allCon").gameObject
	self.upCon = self.allCon:NodeByName("upCon").gameObject
	self.upConMask = self.upCon:NodeByName("upConMask").gameObject
	self.upLeftBtn = self.upConMask:NodeByName("upLeftBtn").gameObject
	self.upLeftBtn_button_label = self.upLeftBtn:ComponentByName("button_label", typeof(UILabel))
	self.upLeftBtn_item_cost = self.upLeftBtn:ComponentByName("itemIcon/labelItemCost", typeof(UILabel))
	self.upRightBtn = self.upConMask:NodeByName("upRightBtn").gameObject
	self.upRightBtn_button_label = self.upRightBtn:ComponentByName("button_label", typeof(UILabel))
	self.upRightBtn_item_cost = self.upRightBtn:ComponentByName("itemIcon/labelItemCost", typeof(UILabel))
	self.upShowBtn = self.upConMask:NodeByName("upShowBtn").gameObject
	self.upScrollView = self.upCon:ComponentByName("upScrollView", typeof(UIScrollView))
	self.upScrollCon = self.upScrollView:NodeByName("upScrollCon").gameObject
	self.downCon = self.allCon:NodeByName("downCon").gameObject
	self.downLeftBtn = self.downCon:NodeByName("downLeftBtn").gameObject
	self.downLeftBtn_button_label = self.downLeftBtn:ComponentByName("button_label", typeof(UILabel))
	self.downLeftBtn_item_cost = self.downLeftBtn:ComponentByName("itemIcon/labelItemCost", typeof(UILabel))
	self.downRightBtn = self.downCon:NodeByName("downRightBtn").gameObject
	self.downRightBtn_button_label = self.downRightBtn:ComponentByName("button_label", typeof(UILabel))
	self.downRightBtn_item_cost = self.downRightBtn:ComponentByName("itemIcon/labelItemCost", typeof(UILabel))
	self.downShowBtn = self.downCon:NodeByName("downShowBtn").gameObject
	self.downAwardBtn = self.downCon:NodeByName("downAwardBtn").gameObject
	self.downAwardBtnRedPoint = self.downAwardBtn:ComponentByName("redPoint", typeof(UISprite))
	self.downScrollView = self.downCon:ComponentByName("downScrollView", typeof(UIScrollView))
	self.downScrollCon = self.downScrollView:NodeByName("downScrollCon").gameObject
	self.itemEgCon = self.groupAction:NodeByName("itemEgCon").gameObject

	self.itemEgCon:SetActive(false)

	self.longCon = self.groupAction:NodeByName("longCon").gameObject

	self.longCon:SetActive(false)
end

function ActivityJackpotLottery:initUIComponent()
	self.resLabel1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_EXCHANGE_ITEM)
	self.resLabel2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_SENIOR_EXCHANGE_ITEM)
	self.upCostOne = xyd.tables.miscTable:split2num("activity_jackpot_normal", "value", "#")
	self.downCostOne = xyd.tables.miscTable:split2num("activity_jackpot_updated", "value", "#")
	self.upItems = {}
	self.downItems = {}
	local upIDs = xyd.tables.activityJackpotGambleTable:getByType(1)
	local downIDs = xyd.tables.activityJackpotGambleTable:getByType(2)

	for i = 1, #upIDs do
		if i % 5 == 1 then
			if self.longGo then
				self.longGo:GetComponent(typeof(UIGrid)):Reposition()
			end

			local longCon = NGUITools.AddChild(self.upScrollCon.gameObject, self.longCon)
			self.longGo = longCon:NodeByName("grid").gameObject
			longCon:GetComponent(typeof(UIWidget)).width = 570

			xyd.setDragScrollView(self.longGo, self.upScrollView)
		end

		local id = upIDs[i]
		local curNum = 0

		for _, info in pairs(self.activityData.detail.awards) do
			if id == tonumber(info.id) then
				curNum = info.num
			end
		end

		local go = NGUITools.AddChild(self.longGo.gameObject, self.itemEgCon)
		local item = IconItem.new(go, self.upScrollView, {
			id = id,
			curNum = curNum
		})

		xyd.setDragScrollView(go, self.upScrollView)
		table.insert(self.upItems, item)
	end

	self.upScrollCon:GetComponent(typeof(UILayout)):Reposition()
	self.upScrollView:ResetPosition()

	for i = 1, #downIDs do
		if i % 5 == 1 then
			if self.longGo then
				self.longGo:GetComponent(typeof(UIGrid)):Reposition()
			end

			local longCon = NGUITools.AddChild(self.downScrollCon.gameObject, self.longCon)
			self.longGo = longCon:NodeByName("grid").gameObject
			longCon:GetComponent(typeof(UIWidget)).width = 555

			xyd.setDragScrollView(self.longGo, self.downScrollView)
		end

		local id = downIDs[i]
		local curNum = 0

		for _, info in pairs(self.activityData.detail.senior_awards) do
			if id == tonumber(info.id) then
				curNum = info.num
			end
		end

		local go = NGUITools.AddChild(self.longGo.gameObject, self.itemEgCon)
		local item = IconItem.new(go, self.downScrollView, {
			id = id,
			curNum = curNum
		})

		xyd.setDragScrollView(go, self.downScrollView)
		table.insert(self.downItems, item)
	end

	self.downScrollCon:GetComponent(typeof(UILayout)):Reposition()
	self.downScrollView:ResetPosition()
	self:updateBtnShow()
end

function ActivityJackpotLottery:resizeToParent()
	ActivityJackpotLottery.super.resizeToParent(self)
	self:resizePosY(self.resGroup2.gameObject, -395, -503)
	self:resizePosY(self.upCon.gameObject, -161, -246)
	self:resizePosY(self.downCon.gameObject, -609, -719)
end

function ActivityJackpotLottery:onRegister()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_JACKPOT_DRAW_HELP"
		})
	end)
	UIEventListener.Get(self.upLeftBtn.gameObject).onClick = handler(self, function ()
		if xyd.models.backpack:getItemNumByID(self.upCostOne[1]) < self.upCostOne[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.upCostOne[1])))

			return
		end

		local timeStamp = xyd.db.misc:getValue("jackpot_lottery_time_stamp")

		if self.isOwnPrivilegeCard and (not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime())) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				hideGroupChoose = true,
				type = "jackpot_lottery",
				text = __("ACTIVITY_JACKPOT_EXCHANGE_TIPS"),
				btnYesText = __("ACTIVITY_JACKPOT_EXCHANGE_BUTTON01"),
				btnNoText_ = __("ACTIVITY_JACKPOT_EXCHANGE_BUTTON02"),
				closeCallback = function ()
					local transfer = xyd.tables.miscTable:split2Cost("activity_jackpot_transfer", "value", "|#")
					local cost = transfer[1]
					local award = transfer[2]
					local params = {
						notEnoughKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_NOT_ENOUGH",
						hasMaxMin = false,
						titleKey = "ACTIVITY_JACKPOT_EXCHANGE_TITLE",
						buyType = award[1],
						buyNum = award[2],
						costType = cost[1],
						costNum = cost[2],
						purchaseCallback = function (_, num)
							xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY, json.encode({
								award_type = 3,
								num = num
							}))
							xyd.WindowManager.get():closeWindow("limit_purchase_item_window")
							xyd.itemFloat({
								{
									item_id = xyd.ItemID.ACTIVITY_JACKPOT_SENIOR_EXCHANGE_ITEM,
									item_num = num
								}
							})
						end,
						limitNum = math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]),
						eventType = xyd.event.GET_ACTIVITY_AWARD
					}

					xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
				end,
				callback = function ()
					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY, json.encode({
						num = 1,
						award_type = 1
					}))
				end
			})
		else
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY, json.encode({
				num = 1,
				award_type = 1
			}))
		end
	end)
	UIEventListener.Get(self.upRightBtn.gameObject).onClick = handler(self, function ()
		if xyd.models.backpack:getItemNumByID(self.upCostOne[1]) < self.upYetTimes * self.upCostOne[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.upCostOne[1])))

			return
		end

		local timeStamp = xyd.db.misc:getValue("jackpot_lottery_time_stamp")

		if self.isOwnPrivilegeCard and (not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime())) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				hideGroupChoose = true,
				type = "jackpot_lottery",
				text = __("ACTIVITY_JACKPOT_EXCHANGE_TIPS"),
				btnYesText = __("ACTIVITY_JACKPOT_EXCHANGE_BUTTON01"),
				btnNoText_ = __("ACTIVITY_JACKPOT_EXCHANGE_BUTTON02"),
				closeCallback = function ()
					local transfer = xyd.tables.miscTable:split2Cost("activity_jackpot_transfer", "value", "|#")
					local cost = transfer[1]
					local award = transfer[2]
					local params = {
						notEnoughKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_NOT_ENOUGH",
						hasMaxMin = false,
						titleKey = "ACTIVITY_JACKPOT_EXCHANGE_TITLE",
						buyType = award[1],
						buyNum = award[2],
						costType = cost[1],
						costNum = cost[2],
						purchaseCallback = function (_, num)
							xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY, json.encode({
								award_type = 3,
								num = num
							}))
							xyd.WindowManager.get():closeWindow("limit_purchase_item_window")
							xyd.itemFloat({
								{
									item_id = xyd.ItemID.ACTIVITY_JACKPOT_SENIOR_EXCHANGE_ITEM,
									item_num = num
								}
							})
						end,
						limitNum = math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]),
						eventType = xyd.event.GET_ACTIVITY_AWARD
					}

					xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
				end,
				callback = function ()
					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY, json.encode({
						award_type = 1,
						num = self.upYetTimes
					}))
				end
			})
		else
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY, json.encode({
				award_type = 1,
				num = self.upYetTimes
			}))
		end
	end)
	UIEventListener.Get(self.downLeftBtn.gameObject).onClick = handler(self, function ()
		if xyd.models.backpack:getItemNumByID(self.downCostOne[1]) < self.downCostOne[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.downCostOne[1])))

			return
		end

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY, json.encode({
			num = 1,
			award_type = 2
		}))
	end)
	UIEventListener.Get(self.downRightBtn.gameObject).onClick = handler(self, function ()
		if xyd.models.backpack:getItemNumByID(self.downCostOne[1]) < self.downYetTimes * self.downCostOne[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.downCostOne[1])))

			return
		end

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY, json.encode({
			award_type = 2,
			num = self.downYetTimes
		}))
	end)

	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.resLabel1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_EXCHANGE_ITEM)
		self.resLabel2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_SENIOR_EXCHANGE_ITEM)
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, function (_, event)
		if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY then
			return
		end

		self:updateBtnShow()
		self:updateItemsNum()
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY, function ()
		end)
	end))

	UIEventListener.Get(self.resBtn1.gameObject).onClick = handler(self, function ()
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.JACKPOT_MACHINE)

		activityData:setMachineType(1)
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.JACKPOT_MACHINE),
			select = xyd.ActivityID.JACKPOT_MACHINE
		})
	end)
	UIEventListener.Get(self.resBtn2.gameObject).onClick = handler(self, function ()
		local transfer = xyd.tables.miscTable:split2Cost("activity_jackpot_transfer", "value", "|#")
		local cost = transfer[1]
		local award = transfer[2]
		local privilegeCardGiftID = xyd.tables.miscTable:getNumber("activity_jackpot_gift", "value")

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] or not self.isOwnPrivilegeCard then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.JACKPOT_MACHINE)

			activityData:setMachineType(2)
			xyd.goToActivityWindowAgain({
				activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.JACKPOT_MACHINE),
				select = xyd.ActivityID.JACKPOT_MACHINE
			})
		else
			local params = {
				notEnoughKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_NOT_ENOUGH",
				hasMaxMin = false,
				titleKey = "ACTIVITY_JACKPOT_EXCHANGE_TITLE",
				buyType = award[1],
				buyNum = award[2],
				costType = cost[1],
				costNum = cost[2],
				purchaseCallback = function (_, num)
					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY, json.encode({
						award_type = 3,
						num = num
					}))
					xyd.WindowManager.get():closeWindow("limit_purchase_item_window")
					xyd.itemFloat({
						{
							item_id = xyd.ItemID.ACTIVITY_JACKPOT_SENIOR_EXCHANGE_ITEM,
							item_num = num
						}
					})
				end,
				limitNum = math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]),
				eventType = xyd.event.GET_ACTIVITY_AWARD
			}

			xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
		end
	end)
	UIEventListener.Get(self.upShowBtn.gameObject).onClick = handler(self, function ()
		self:openShowAllWindow(1)
	end)
	UIEventListener.Get(self.downShowBtn.gameObject).onClick = handler(self, function ()
		self:openShowAllWindow(2)
	end)

	UIEventListener.Get(self.downAwardBtn.gameObject).onClick = function ()
		local all_info = {}
		local ids = xyd.tables.activityJackpotAwardTable:getIDs()

		for i = 1, #ids do
			local info = {
				id = ids[i],
				max_value = xyd.tables.activityJackpotAwardTable:getComplete(ids[i])
			}
			info.cur_value = math.min(tonumber(self.activityData.detail.senior_times), info.max_value)
			info.name = __("ACTIVITY_JACKPOT_AWARDS", math.floor(info.max_value))
			info.items = xyd.tables.activityJackpotAwardTable:getAwards(ids[i])

			if self.activityData.detail.award_ids[i] == 0 then
				if info.cur_value == info.max_value then
					info.state = 1
				else
					info.state = 2
				end
			else
				info.state = 3
			end

			table.insert(all_info, info)
		end

		xyd.WindowManager.get():openWindow("common_progress_award_window", {
			if_sort = true,
			all_info = all_info,
			title_text = __("ACTIVITY_FISH_BUTTON02"),
			click_callBack = function (info)
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY
				msg.params = json.encode({
					award_type = 4,
					award_id = info.id
				})

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

				local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY)

				activityData:setAwardTableID(info.id)
			end,
			wnd_type = xyd.CommonProgressAwardWindowType.ACTIVITY_JACKPOT_LOTTERY
		})
	end
end

function ActivityJackpotLottery:updateBtnShow()
	self.upYetTimes = 0

	for i = 1, #self.activityData.detail.awards do
		self.upYetTimes = self.upYetTimes + self.activityData.detail.awards[i].num
	end

	self.upYetTimes = self.upYetTimes > 10 and 10 or self.upYetTimes

	self.upLeftBtn:NodeByName("redPoint").gameObject:SetActive(self.upCostOne[2] <= xyd.models.backpack:getItemNumByID(self.upCostOne[1]))
	self.upRightBtn:NodeByName("redPoint").gameObject:SetActive(xyd.models.backpack:getItemNumByID(self.upCostOne[1]) >= self.upCostOne[2] * self.upYetTimes)

	self.downYetTimes = 0

	for i = 1, #self.activityData.detail.senior_awards do
		self.downYetTimes = self.downYetTimes + self.activityData.detail.senior_awards[i].num
	end

	self.downYetTimes = self.downYetTimes > 10 and 10 or self.downYetTimes

	self.downLeftBtn:NodeByName("redPoint").gameObject:SetActive(self.downCostOne[2] <= xyd.models.backpack:getItemNumByID(self.downCostOne[1]))
	self.downRightBtn:NodeByName("redPoint").gameObject:SetActive(xyd.models.backpack:getItemNumByID(self.downCostOne[1]) >= self.downCostOne[2] * self.downYetTimes)

	self.upLeftBtn_button_label.text = __("ACTIVITY_3BIRTHDAY_TEXT12", 1)
	self.upRightBtn_button_label.text = __("ACTIVITY_3BIRTHDAY_TEXT12", self.upYetTimes)
	self.downLeftBtn_button_label.text = __("ACTIVITY_3BIRTHDAY_TEXT12", 1)
	self.downRightBtn_button_label.text = __("ACTIVITY_3BIRTHDAY_TEXT12", self.downYetTimes)
	self.upLeftBtn_item_cost.text = self.upCostOne[2]
	self.upRightBtn_item_cost.text = self.upCostOne[2] * self.upYetTimes
	self.downLeftBtn_item_cost.text = self.downCostOne[2]
	self.downRightBtn_item_cost.text = self.downCostOne[2] * self.downYetTimes

	self.downAwardBtnRedPoint:SetActive(false)

	local ids = xyd.tables.activityJackpotAwardTable:getIDs()

	for i = 1, #ids do
		if self.activityData.detail.award_ids[i] == 0 and xyd.tables.activityJackpotAwardTable:getComplete(ids[i]) <= tonumber(self.activityData.detail.senior_times) then
			self.downAwardBtnRedPoint:SetActive(true)
		end
	end
end

function ActivityJackpotLottery:updateItemsNum(type)
	for i = 1, #self.upItems do
		local index = -1

		for j, info in pairs(self.activityData.detail.awards) do
			if tonumber(info.id) == self.upItems[i].id then
				index = j

				break
			end
		end

		self.upItems[i]:updateNum(index == -1 and 0 or self.activityData.detail.awards[index].num)
	end

	for i = 1, #self.downItems do
		local index = -1

		for j, info in pairs(self.activityData.detail.senior_awards) do
			if tonumber(info.id) == self.downItems[i].id then
				index = j

				break
			end
		end

		self.downItems[i]:updateNum(index == -1 and 0 or self.activityData.detail.senior_awards[index].num)
	end
end

function ActivityJackpotLottery:openShowAllWindow(type)
	local awards = type == 1 and self.activityData.detail.awards or self.activityData.detail.senior_awards
	local ids = xyd.tables.activityJackpotGambleTable:getByType(type)
	local datas = {}

	for i = 1, #ids do
		local curNum = 0

		for _, info in pairs(awards) do
			if ids[i] == tonumber(info.id) then
				curNum = info.num
			end
		end

		table.insert(datas, {
			items = xyd.tables.activityJackpotGambleTable:getAwards(ids[i]),
			num = xyd.tables.activityJackpotGambleTable:getNum(ids[i]),
			cur_num = curNum
		})
	end

	xyd.WindowManager.get():openWindow("activity_wine_award_preview_window", datas)
end

function IconItem:ctor(go, scrollView, info)
	self.id = info.id
	self.curNum = info.curNum
	self.scrollView = scrollView

	IconItem.super.ctor(self, go)
end

function IconItem:initUI()
	self.itemCon = self.go:NodeByName("itemCon").gameObject
	self.hasNumLabel = self.go:ComponentByName("hasNumLabel", typeof(UILabel))
	self.maxNum = xyd.tables.activityJackpotGambleTable:getNum(self.id)
	local award = xyd.tables.activityJackpotGambleTable:getAwards(self.id)

	xyd.getItemIcon({
		show_has_num = true,
		scale = 0.7592592592592593,
		uiRoot = self.itemCon,
		itemID = award[1],
		num = award[2],
		dragScrollView = self.scrollView
	})

	self.hasNumLabel.text = tostring(self.curNum) .. "/" .. tostring(self.maxNum)

	if self.curNum == 0 then
		self.hasNumLabel.color = Color.New2(3422556671.0)
	else
		self.hasNumLabel.color = Color.New2(4294967295.0)
	end
end

function IconItem:updateNum(curNum)
	self.curNum = curNum
	self.hasNumLabel.text = tostring(self.curNum) .. "/" .. tostring(self.maxNum)

	if self.curNum == 0 then
		self.hasNumLabel.color = Color.New2(3422556671.0)
	else
		self.hasNumLabel.color = Color.New2(4294967295.0)
	end
end

return ActivityJackpotLottery
