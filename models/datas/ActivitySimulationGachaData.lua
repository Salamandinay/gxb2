local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySimulationGachaData = class("ActivitySimulationGachaData", ActivityData, true)

function ActivitySimulationGachaData:getUpdateTime()
	if not self.detail.start_time then
		return self:getEndTime()
	end

	return self.detail.start_time + xyd.tables.activityTable:getLastTime(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA)
end

function ActivitySimulationGachaData:onAward(data)
	if type(data) == "number" then
		self:onRecharge(data)
	else
		self:onGetActivityAward(data)
	end

	self:updateRedMark()
end

function ActivitySimulationGachaData:onRecharge(giftbagID)
	for i = 1, #self.detail.charges do
		if self.detail.charges[i].table_id == giftbagID then
			self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1

			break
		end
	end
end

function ActivitySimulationGachaData:onGetActivityAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_SIMULATION_GACHA then
		return
	end

	local detail = cjson.decode(data.detail)

	if detail.type == 1 then
		self.detail.tmp_slot = detail.tmp_slot
		self.detail.draw_times = self.detail.draw_times + 1
	elseif detail.type == 2 then
		self.detail.slots[detail.index] = self.detail.tmp_slot
		self.detail.tmp_slot = nil
	elseif detail.type == 3 then
		self.detail.slots[self.exchangeIndex] = {}
		local collectionBefore = xyd.models.slot:getCollectionCopy()
		local new5stars = {}

		for _, partner in ipairs(detail.partners) do
			if not collectionBefore[partner.table_id] then
				table.insert(new5stars, partner.table_id)
			end
		end

		local function callback()
			local params = {
				progressValue = 0,
				type = 9,
				oldBaodiEnergy = 0,
				btnOkCallBack = function ()
					xyd.WindowManager.get():closeWindow("summon_result_window")
				end,
				items = {}
			}

			for _, partner in ipairs(detail.partners) do
				table.insert(params.items, {
					item_id = partner.table_id
				})
			end

			xyd.WindowManager.get():openWindow("summon_result_window", params)

			local msg = messages_pb.get_slot_info_req()

			xyd.Backend.get():request(xyd.mid.GET_SLOT_INFO, msg)
		end

		if #new5stars > 0 then
			xyd.onGetNewPartnersOrSkins({
				showRepeat = false,
				partners = new5stars,
				callback = callback
			})
		else
			callback()
		end
	elseif detail.type == 4 then
		table.insert(self.detail.slots, {})
	elseif detail.type == 5 then
		self.detail.awards[1] = self.detail.awards[1] + 1
		local awards = xyd.tables.miscTable:split2Cost("activity_simulation_gacha_10_giftbag_diamonds", "value", "|#") or {}
		local newItems = {}

		for i = 1, #awards do
			local award = awards[i]

			table.insert(newItems, {
				item_id = award[1],
				item_num = award[2]
			})
		end

		xyd.models.itemFloatModel:pushNewItems(newItems)
	end
end

function ActivitySimulationGachaData:updateRedMark()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA, function ()
		self.holdRed = false
	end)
end

function ActivitySimulationGachaData:getRedMarkState()
	if self.holdRed then
		return self.defRedMark
	end

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		self.defRedMark = false
		local mainWindowViewTime = xyd.db.misc:getValue("activity_simulation_gacha_view_time")
		local exchangeWindowViewTime = xyd.db.misc:getValue("activity_simulation_gacha_exchange_view_time")
		local giftbagWindowViewTime = xyd.db.misc:getValue("activity_simulation_gacha_giftbag_view_time")

		if not mainWindowViewTime or not xyd.isSameDay(tonumber(mainWindowViewTime), xyd.getServerTime()) then
			self.defRedMark = true
		end

		if not exchangeWindowViewTime or not xyd.isSameDay(tonumber(exchangeWindowViewTime), xyd.getServerTime()) then
			for i, slot in pairs(self.detail.slots) do
				if #slot > 0 then
					self.defRedMark = true
				end
			end
		end

		if self.detail.awards[1] == 0 and (not giftbagWindowViewTime or not xyd.isSameDay(tonumber(giftbagWindowViewTime), xyd.getServerTime())) then
			self.defRedMark = true
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SIMULATION_GACHA, self.defRedMark)

	return self.defRedMark
end

function ActivitySimulationGachaData:setExchangeIndex(index)
	self.exchangeIndex = index
end

return ActivitySimulationGachaData
