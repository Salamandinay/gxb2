local BaseWindow = import(".BaseWindow")
local ActivityAllStarPrayExchangeItemWindow = class("ActivityAllStarPrayExchangeItemWindow", BaseWindow)

function ActivityAllStarPrayExchangeItemWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "ActivityAllStarsPrayExchangeItemWindowSkin"
	self.activityData = params.activityData
	self.itemCon = params.itemCon
end

function ActivityAllStarPrayExchangeItemWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	ActivityAllStarPrayExchangeItemWindow.super.register(self)
	self:createChildren()
end

function ActivityAllStarPrayExchangeItemWindow:getUIComponent()
	local winTrans = self.window_.transform
	local allGroup = winTrans:NodeByName("groupAction").gameObject
	self.titleLabel = allGroup:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = allGroup:NodeByName("closeBtn").gameObject

	for i = 0, 1 do
		self["itemIcon" .. i] = allGroup:NodeByName("e:Group" .. i .. "/itemIcon" .. i).gameObject
		self["descLabel" .. i] = allGroup:ComponentByName("e:Group" .. i .. "/descLabel" .. i, typeof(UILabel))
		self["buyBtn" .. i] = allGroup:ComponentByName("e:Group" .. i .. "/buyBtn" .. i, typeof(UISprite))
		self["buyBtn" .. i .. "_button_label"] = allGroup:ComponentByName("e:Group" .. i .. "/buyBtn" .. i .. "/button_label", typeof(UILabel))
		self["buyBtn" .. i .. "_button_icon"] = allGroup:ComponentByName("e:Group" .. i .. "/buyBtn" .. i .. "/button_icon", typeof(UISprite))
	end
end

function ActivityAllStarPrayExchangeItemWindow:createChildren()
	self.titleLabel.text = __("ACTIVITY_PRAY_BUY")
	local list = {
		{},
		{}
	}
	local list1 = xyd.split(xyd.tables.miscTable:getString("activity_pray_buy_price", "value"), "|")
	local list2 = {}

	for i in ipairs(list1) do
		local t = xyd.split(list1[i], "-")

		for k, j in ipairs(t) do
			table.insert(list[i], xyd.split(j, "#"))
		end
	end

	self.eventProxy_:addEventListener(xyd.event.ALL_STAR_PRAY_BUY, function ()
		xyd.WindowManager.get():closeWindow("limit_purchase_item_window")
		xyd.WindowManager.get():closeWindow("activity_all_star_pray_exchange_item_window")
	end)

	for i = 1, 2 do
		local data = list[i][1]
		local get_data = list[i][2]
		UIEventListener.Get(self["buyBtn" .. tostring(i - 1)].gameObject).onClick = handler(self, function ()
			local not_enough_key = "PERSON_NO_CRYSTAL"
			local params = {
				limitKey = "ACTIVITY_WORLD_BOSS_LIMIT",
				needTips = true,
				titleKey = "ACTIVITY_PRAY_BUY",
				buyType = tonumber(get_data[1]),
				buyNum = tonumber(get_data[2]),
				costType = tonumber(data[1]),
				costNum = tonumber(data[2]),
				purchaseCallback = function (evt, num)
					local msg = messages_pb.all_star_pray_buy_req()
					msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
					msg.num = num
					msg.type = i

					xyd.Backend.get():request(xyd.mid.ALL_STAR_PRAY_BUY, msg)

					if tonumber(xyd.models.backpack:getItemNumByID(tonumber(data[1]))) < tonumber(data[2]) then
						xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(tonumber(data[1]))))

						return
					end

					xyd.itemFloat({
						{
							item_id = tonumber(get_data[1]),
							item_num = tonumber(get_data[2]) * num
						}
					}, nil, , 6002)
				end,
				limitNum = self:getBuyTime(i),
				notEnoughKey = not_enough_key,
				eventType = xyd.event.BOSS_BUY
			}

			if i == 2 then
				function params.maxCallback()
					xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(tonumber(data[1]))))
				end
			else
				function params.showWindowCallback()
					xyd.WindowManager.get():openWindow("vip_window")
				end
			end

			xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
		end)
		self["descLabel" .. tostring(i - 1)].text = __("ACTIVITY_PRAY_BUY_TIPS0" .. tostring(i))
		local icon = xyd.getItemIcon({
			itemID = tonumber(get_data[1]),
			num = tonumber(get_data[2]),
			uiRoot = self["itemIcon" .. tostring(i - 1)].gameObject
		})

		xyd.setUISpriteAsync(self["buyBtn" .. tostring(i - 1) .. "_button_icon"], nil, tostring(xyd.tables.itemTable:getIcon(tonumber(data[1]))), nil, )

		self["buyBtn" .. tostring(i - 1) .. "_button_label"].text = data[2]
	end
end

function ActivityAllStarPrayExchangeItemWindow:getBuyTime(i)
	if i == 1 then
		return xyd.tables.miscTable:split2num("activity_pray_buy_limit", "value", "|")[i] - self.activityData.detail.buy_times
	else
		return xyd.tables.miscTable:split2num("activity_pray_buy_limit", "value", "|")[i]
	end
end

return ActivityAllStarPrayExchangeItemWindow
