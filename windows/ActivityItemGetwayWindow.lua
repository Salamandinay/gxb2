local BaseWindow = import("app.windows.BaseWindow")
local ActivityItemGetwayWindow = class("ActivityItemGetwayWindow", BaseWindow)
local GetWayTable = xyd.tables.getWayItemTable
local Backpack = xyd.models.backpack

function ActivityItemGetwayWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.itemID = params.itemID
	self.activityID = params.activityID
	self.params = params
	self.itemNumData = params.activityData
	self.openItemBuyWnd = params.openItemBuyWnd
	self.callback = params.callback
	self.wayItems = {}
	self.openDepthTypeWindowCallBack = params.openDepthTypeWindowCallBack
end

function ActivityItemGetwayWindow:initWindow()
	ActivityItemGetwayWindow.super:initWindow()

	self.groupAction = self.window_.transform:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.itemGroup = self.groupAction:NodeByName("itemGroup").gameObject
	self.itemCell = self.groupAction:NodeByName("activity_item_getway_item").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.title = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))

	self:layout()
	self:RegisterEvent()

	local msg = messages_pb:getway_item_req()

	xyd.Backend.get():request(xyd.mid.GETWAY_ITEM, msg)
end

function ActivityItemGetwayWindow:RegisterEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager:get():closeWindow(self.name_)
	end

	for i = 1, #self.wayItems do
		UIEventListener.Get(self.wayItems[i].btn).onClick = function ()
			self:GoWnd(i)
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GETWAY_ITEM, function (event)
		self.timesList = event.data.infos
		local endId = self.timesList and #self.timesList or 0

		for i = endId, #GetWayTable:getIDs() do
			table.insert(self.timesList, 0)
		end

		self:refreshTimes()
	end)
end

function ActivityItemGetwayWindow:refreshTimes()
	for i = 1, #self.wayItems do
		self.wayItems[i].item:ComponentByName("numGroup/numGroup/label1", typeof(UILabel)).text = self.timesList[self.wayItems[i].id]

		self.wayItems[i].item:ComponentByName("numGroup/numGroup", typeof(UILayout)):Reposition()
		self.wayItems[i].item:ComponentByName("numGroup", typeof(UILayout)):Reposition()
	end
end

function ActivityItemGetwayWindow:GoWnd(index)
	local id = self.wayItems[index].id
	local function_id = GetWayTable:getFunctionId(id)

	if not xyd.checkFunctionOpen(function_id) then
		return
	end

	local windows = GetWayTable:getGoWindow(id)

	if xyd.arrayIndexOf(windows, "arena_window") > 0 and xyd.models.arena:getIsSettlementing(true) then
		return
	end

	if self.callback then
		self.callback()
	end

	local params = GetWayTable:getGoParam(id)
	local close = false
	local openWindowDepthTypes = {}

	for i in pairs(windows) do
		close = true
		local windowName = windows[i]

		if windowName == "activity_window" then
			local data = xyd.models.activity:getActivity(params[i].select)

			if not data then
				xyd.showToast(__("ACTIVITY_OPEN_TEXT"))

				close = false
			else
				local win = xyd.WindowManager.get():getWindow(windowName)
				local newParams = xyd.tables.activityTable:getWindowParams(params[i].select)

				if newParams ~= nil then
					params[i].onlyShowList = newParams.activity_ids
					params[i].activity_type = xyd.tables.activityTable:getType(newParams.activity_ids[1])
				end

				if win then
					xyd.goToActivityWindowAgain(params[i])
				else
					xyd.WindowManager.get():openWindow(windowName, params[i])
				end

				if xyd.WindowManager.get():getWindow("activity_childhood_shop_gacha_window") then
					xyd.WindowManager.get():closeWindow("activity_childhood_shop_gacha_window")
				end
			end
		elseif windowName == "item_buy_window" then
			local maxNumCanBuy = 0

			if self.params.maxNumCanBuy then
				maxNumCanBuy = self.params.maxNumCanBuy
			end

			if self.activityID == xyd.ActivityID.TIME_LIMIT_CALL then
				xyd.WindowManager.get():openWindow("item_buy_window", {
					hide_min_max = false,
					item_no_click = false,
					cost = xyd.tables.miscTable:split2Cost("activity_limit_gacha_buy", "value", "|#")[1],
					max_num = xyd.checkCondition(maxNumCanBuy == 0, 1, maxNumCanBuy),
					itemParams = {
						num = 1,
						itemID = xyd.ItemID.LIMIT_GACHA_ICON2
					},
					buyCallback = function (num)
						if maxNumCanBuy <= 0 then
							xyd.showToast(__("FULL_BUY_SLOT_TIME"))

							xyd.WindowManager.get():getWindow("item_buy_window").skipClose = true

							return
						end

						local msg = messages_pb:boss_buy_req()
						msg.activity_id = xyd.ActivityID.TIME_LIMIT_CALL
						msg.num = num

						xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
					end,
					maxCallback = function ()
						xyd.showToast(__("FULL_BUY_SLOT_TIME"))
					end,
					limitText = __("BUY_GIFTBAG_LIMIT", tostring(self.itemNumData.buy_times) .. "/" .. tostring(xyd.tables.miscTable:getNumber("activity_limit_gacha_limit", "value")))
				})
			else
				self.openItemBuyWnd()
			end
		elseif windowName == "activity_jackpot_machine_giftbag_window" then
			xyd.WindowManager.get():openWindow(windowName, params[i])
		elseif windowName == "activity_lafuli_castle_task_window" then
			xyd.WindowManager.get():openWindow(windowName)
		else
			if xyd.WindowManager.get():getWindow("activity_window") then
				xyd.WindowManager.get():closeWindow("activity_window")
			end

			xyd.WindowManager.get():openWindow(windowName, params[i])
		end

		if close then
			local layerType = xyd.tables.windowTable:getLayerType(windowName)

			if layerType and layerType > 0 then
				table.insert(openWindowDepthTypes, {
					layerType = layerType,
					windowName = windowName
				})
			end
		end
	end

	if close then
		xyd.WindowManager.get():closeWindow(self.window_.name)

		if self.openDepthTypeWindowCallBack then
			for i in pairs(openWindowDepthTypes) do
				self.openDepthTypeWindowCallBack(openWindowDepthTypes[i])
			end
		end
	end
end

function ActivityItemGetwayWindow:layout()
	self.title.text = __("ACTIVITY_EASTER_EGG_GETWAY_WINDOW")
	local ways = xyd.tables.itemTable:getActivtyWays(self.itemID) or {}
	local itemNum = #ways

	for _, way in ipairs(ways) do
		local windows = GetWayTable:getGoWindow(way)
		local params = GetWayTable:getGoParam(way)
		local show = true

		for i in pairs(windows) do
			local windowName = windows[i]

			if windowName == "activity_window" then
				local data = xyd.models.activity:getActivity(params[i].select)

				if not data then
					show = false
					itemNum = itemNum - 1
				end
			end
		end

		if show then
			local item = NGUITools.AddChild(self.itemGroup, self.itemCell)
			item:ComponentByName("label1", typeof(UILabel)).text = xyd.tables.getWayItemTextTable:getName(way)
			local btn = item:NodeByName("btn").gameObject
			btn:ComponentByName("label", typeof(UILabel)).text = __("GO")

			if not windows or #windows == 0 then
				btn:SetActive(false)
			end

			table.insert(self.wayItems, {
				item = item,
				id = way,
				btn = btn
			})
		end
	end

	self.itemGroup:GetComponent(typeof(UIWidget)).height = 86 * itemNum - 8
	self.groupAction:GetComponent(typeof(UIWidget)).height = 86 * itemNum + 100

	self.itemCell:SetActive(false)
	XYDCo.WaitForFrame(1, function ()
		self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	end, nil)
end

return ActivityItemGetwayWindow
