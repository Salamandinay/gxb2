local BaseModel = import(".BaseModel")
local GMcommand = class("GMcommand", BaseModel)
local cjson = require("cjson")
local CommandEnums = {
	"partner table_id",
	"partner_max table_id",
	"item item_id item_num",
	"fight stage_id",
	"alert_error",
	"show_log",
	"message_push",
	"alert_cache",
	"garbage_collect",
	"dungeon dungeon_id",
	"fight battle_id",
	"guildexp",
	"show_subscription",
	"os_type",
	"app_version",
	"garbage_warn",
	"is_review",
	"pet table_id",
	"buy giftbagid",
	"guild_skill 1",
	"item_all",
	"guildboss",
	"partner_all star",
	"clear_localstorage",
	"game_frame"
}

function GMcommand:ctor()
	BaseModel.ctor(self)

	self.IN_TEST = false
	self.summon_count_ = 0
	self.test_table_ids_ = {}
	self.summon_result_ = {}
	self.fromReplaceId = -1
	self.desReplaceId = -1
	self.subScriptionType = 2

	self:registerEvent(xyd.event.SUMMON, function (self, event)
		if not self.IN_TEST then
			return
		end

		local list = event.data.summon_result.partners

		for i = 1, #list do
			local id = list[i].table_id

			if xyd.arrayIndexOf(self.test_table_ids_, id) > -1 then
				if self.summon_result_[id] then
					local ____TS_obj = self.summon_result_
					local ____TS_index = id
					____TS_obj[____TS_index] = ____TS_obj[____TS_index] + 1
				else
					self.summon_result_[id] = 1
				end
			end
		end

		if self.summon_count_ <= 0 then
			print(" =========================> summon_result")

			local str = ""
			local PartnerTextTable = xyd.tables.partnerTextTable

			for key, _ in pairs(self.summon_count_) do
				str = tostring(str) .. tostring(tostring(PartnerTextTable:getName(key)) .. " : " .. tostring(self.summon_result_[key])) .. " "
			end

			xyd.alert(xyd.AlertType.CONFIRM, str)
			print(" ========================> end result")

			return
		end

		self:doTenSummon()
	end, self)
	self:registerEvent(xyd.event.PROPHET_REPLACE_SAVE, function (self, event)
		if not self.IN_TEST then
			return
		end

		XYDCo.WaitForTime(0.5, function ()
			self:testReplace(self.fromReplaceId)
		end, nil)
	end, self)
	self:registerEvent(xyd.event.PROPHET_REPLACE, function (self, event)
		if not self.IN_TEST then
			return
		end

		local replace_id = event.data.replace_id

		if replace_id ~= self.desReplaceId then
			local msg = messages_pb:prophet_replace_save_req()
			msg.partner_id = 1
			msg.is_save = 0

			xyd.Backend.get():request(xyd.mid.PROPHET_REPLACE_SAVE, msg)
		else
			self.IN_TEST = false

			xyd.alert(xyd.AlertType.CONFIRM, "換出來了呢，哥")
		end
	end, self)
end

function GMcommand:subScription()
	return self.subScriptionType
end

function GMcommand:garbageWarn()
	return self.garbageWarn_
end

function GMcommand:checkTestGm(texts)
	if texts[1] == "test_index" then
		xyd.db.misc:setValue({
			key = "test_index",
			playerId = -1,
			value = texts[2]
		})
		reportLog2("test_index: " .. texts[2])

		return true
	elseif texts[1] == "fight_test" then
		xyd.WindowManager.get():openWindow("battle_test_window")

		return true
	elseif texts[1] == "fight_test_close" then
		xyd.closeWindow("battle_window")
		xyd.closeWindow("battle_win_window")
		xyd.closeWindow("battle_fail_window")
		xyd.closeWindow("battle_fail_v2_window")
		xyd.closeWindow("battle_win_v2_window")
		xyd.WindowManager.get():resumeHideAllWindow()

		return true
	end

	return false
end

function GMcommand:request(text)
	dump(text)

	local endStr = string.sub(text, #text)

	if endStr == "\n" then
		text = string.sub(text, #text - 1)
	end

	local texts = xyd.split(text, " ")

	if self:checkTestGm(texts) then
		return
	end

	if texts[1] == "partner" and xyd.models.slot:getCanSummonNum() < 1 then
		xyd.alert(xyd.AlertType.TIPS, "战姬格子数不足")

		return
	end

	if (texts[1] == "partner" or texts[1] == "partner_max") and not tonumber(texts[2]) then
		local name = texts[2]
		local ids = xyd.tables.partnerTable:getTableIDByName(texts[2])

		if #ids > 0 then
			for i = 1, #ids do
				local str = texts[1] .. " " .. ids[i]

				self:requestText(str)
			end
		end

		XYDCo.WaitForTime(1, function ()
			xyd.models.slot.isloaded = false

			xyd.models.slot:getData()
		end, nil)

		return
	elseif texts[1] == "partner" or texts[1] == "partner_max" then
		XYDCo.WaitForTime(1, function ()
			xyd.models.slot.isloaded = false

			xyd.models.slot:getData()
		end, nil)
	end

	local str = texts[1]

	if string.find(str, "alert_error") then
		xyd.Global.isAlertError = not xyd.Global.isAlertError

		return
	end

	if string.find(str, "show_log") then
		return
	end

	if string.find(str, "message_push") then
		return
	end

	if string.find(str, "alert_cache") then
		return
	end

	if str:find("notice_2") then
		local i = 0

		for i = 1, tonumber(texts[2]) do
			xyd.models.chat:test("good good study, day day up~")
		end

		return
	end

	if string.find(str, "notice") then
		local i = 0

		for i = 1, tonumber(texts[2]) do
			xyd.models.floatMessage2:showNotice({
				broadcast_type = 1,
				player_name = "jzx",
				player_id = 111111111,
				table_id = 542005
			})
		end

		return
	end

	if string.find(str, "item_all") then
		local ids = xyd.tables.itemTable:getIDs()

		for _, id in ipairs(ids) do
			local limit = 999
			local reqStr_ = "item " .. tostring(id) .. " " .. tostring(limit)

			self:requestText(reqStr_)
		end

		return
	end

	if string.find(str, "story") then
		xyd.WindowManager.get():openWindow("story_window", {
			story_id = tonumber(texts[3]),
			story_type = tonumber(texts[2])
		})

		return
	end

	if string.find(str, "summon_effect") then
		local type = texts[2]
		local ids = xyd.split(texts[3], ",")

		if type == 1 then
			xyd.openWindow("summon_effect_res_window", {
				destory_res = false,
				partners = ids,
				callback = function ()
				end
			})
		else
			xyd.openWindow("summon_effect_res_window", {
				destory_res = false,
				skins = ids,
				callback = function ()
				end
			})
		end

		return
	end

	if string.find(str, "test_summon") then
		self:testSummon(tonumber(texts[2]), xyd.split(texts[3], ","))

		return
	end

	if string.find(str, "game_frame") then
		local val = tonumber(texts[2] or 30)

		UnityEngine.PlayerPrefs.SetInt("__GAME_FRAME_RATE__", val)
		xyd.updateFrameRate(val)

		return
	end

	if string.find(str, "test_prophet") then
		self:testProphet(tonumber(texts[2]), tonumber(texts[3]))

		return
	end

	if string.find(str, "test_replace") then
		self.fromReplaceId = 1

		self:testReplace(self.fromReplaceId)

		self.desReplaceId = tonumber(texts[2])

		return
	end

	self:requestText(text)
end

function GMcommand:requestText(text)
	local msg = messages_pb.gm_commond_req()
	msg.command = text

	xyd.Backend.get():request(xyd.mid.GM_COMMOND, msg)
end

function GMcommand:onRegister()
	BaseModel.onRegister(self)
	self:registerEvent(xyd.event.GM_COMMOND, self.onResponse, self)
end

function GMcommand:onResponse(event)
	local data = event.data

	if not tolua.isnull(data.partner_info) then
		xyd.models.slot:gmAddPartner(data.partner_info, true)
	end

	if tostring(data.battle_result) ~= "" and (not data.battle_result.stage_id or data.battle_result.stage_id ~= 1) then
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.MAP_FIGHT,
			data = data.battle_result
		})
	end
end

function GMcommand:registerkeyboardEvent()
end

function GMcommand:testSummon(count, table_ids)
	self.IN_TEST = true

	self:requestText("item 2 " .. tostring(2200 * count))

	self.test_table_ids_ = table_ids
	local i = 0

	while i < #self.test_table_ids_ do
		self.test_table_ids_[i + 1] = __TS__Number(self.test_table_ids_[i + 1])
		i = i + 1
	end

	self.summon_count_ = count * 10

	self:doTenSummon()
end

function GMcommand:doTenSummon()
	self:decompose()

	self.summon_count_ = self.summon_count_ - 10

	xyd.models.summon:summonPartner(xyd.SummonType.SENIOR_CRYSTAL_TEN, 1)
end

function GMcommand:getFromReplaceId(partner_id)
	local group = xyd.tables.partnerTable:getGroup(partner_id)
	local partners = xyd.models.slot:getPartners()

	for key in pairs(partners) do
		if xyd.tables.partnerTable:get():getGroup(partners[key].tableID) == group then
			return __TS__Number(key)
		end
	end

	return -1
end

function GMcommand:testReplace(partner_id)
	local partner = xyd.models.slot:getPartner(partner_id)
	local cost = xyd.tables.partnerReplaceTable:getCost(partner:getTableID())

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.BRANCH) < cost[2] then
		xyd.showToast("檔案當不夠呢，哥")

		return
	end

	self.IN_TEST = true
	local msg = messages_pb:prophet_replace_req()
	msg.partner_id = partner_id

	xyd.Backend.get():request(xyd.mid.PROPHET_REPLACE, msg)
end

function GMcommand:testProphet(group_id, times)
	self:requestText("item 20 " .. tostring(times * 10))
	self:doProphet(group_id, times)
end

function GMcommand:doProphet(group_id, times)
	if times <= 0 then
		return
	end

	for i = 1, times do
		xyd.models.prophet.currentGroup_ = group_id
		xyd.models.prophet.is10Times_ = true

		xyd.models.prophet:reqProphetSummon()
	end
end

function GMcommand:decompose()
	local msg = messages_pb.decompose_partners_req()
	local ids = xyd.tables.partnerTable:getIds()
	local ret = 10

	for i = 1, #ids do
		local table_id = ids[i]
		local list = xyd.models.slot:getListByTableID(table_id)

		for j = 1, #list do
			if ret == 0 then
				break
			end

			ret = ret - 1
			local data = list[j]

			table.insert(msg.partner_ids, data:getPartnerID())
		end
	end

	xyd.Backend:get():request(xyd.mid.DECOMPOSE_PARTNERS, msg)
end

return GMcommand
