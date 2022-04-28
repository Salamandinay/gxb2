local BaseWindow = import(".BaseWindow")
local GameAssistantResultWindow = class("GameAssistantResultWindow", BaseWindow)
local GameAssistantResultItem = class("GameAssistantResultItem", import("app.components.CopyComponent"))
local GameAssistantDinnerOrderItem = class("GameAssistantDinnerOrderItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local BaseComponent = import("app.components.BaseComponent")
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")

function GameAssistantResultWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model = xyd.models.gameAssistant
	self.chooseTab = params.curTab or 0
	self.inWitchTab = params.inWitchTab
	self.iSDoing = true
	self.isFinish = false
	self.itemArr = {}
	self.orderItems = {}
	self.tempItems = {}
end

function GameAssistantResultWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.btnClose = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.labelDoingState = self.groupAction:ComponentByName("labelDoingState", typeof(UILabel))
	self.scrollView = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.scroller = self.groupAction:NodeByName("scroller").gameObject
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.itemGroupLayout = self.scroller:ComponentByName("itemGroup", typeof(UILayout))
	self.item = self.scroller:NodeByName("item").gameObject
	self.orderItem = self.scroller:NodeByName("orderItem").gameObject
	self.btnSure = self.groupAction:NodeByName("btnSure").gameObject
	self.labelSure = self.btnSure:ComponentByName("label", typeof(UILabel))
	self.btnStop = self.groupAction:NodeByName("btnStop").gameObject
	self.labelStop = self.btnStop:ComponentByName("label", typeof(UILabel))
end

function GameAssistantResultWindow:register()
	UIEventListener.Get(self.btnClose).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
		xyd.openWindow("game_assistant_window", {
			curTabIndex = self.inWitchTab
		})
	end

	UIEventListener.Get(self.btnStop).onClick = function ()
		self.iSDoing = false
	end

	self.eventProxy_:addEventListener(xyd.event.MIDAS_BUY_2, handler(self, self.onGetMidasMsg))
	self.eventProxy_:addEventListener(xyd.event.GET_HANG_ITEM, handler(self, self.onGetCampaignMsg))
	self.eventProxy_:addEventListener(xyd.event.HOUSE_GET_AWARDS, handler(self, self.onGetHouseMsg))
	self.eventProxy_:addEventListener(xyd.event.QUIZ_BUY, handler(self, self.onGetDailyQuizBuyMsg))
	self.eventProxy_:addEventListener(xyd.event.QUIZ_SWEEP, handler(self, self.onGetDailyQuizAwardMsg))
	self.eventProxy_:addEventListener(xyd.event.SUMMON, handler(self, self.onGetSummonMsg))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_GET_GIFTS, handler(self, self.onGetGetFriendMsg))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_SEND_GIFTS, handler(self, self.onGetSendFriendMsg))
	self.eventProxy_:addEventListener(xyd.event.BATCH_COMPLETE_PUB_MISSIONS, handler(self, self.onGetTavernMsg))
	self.eventProxy_:addEventListener(xyd.event.GAMBLE_GET_AWARD, handler(self, self.onGetGambleMsg))
	self.eventProxy_:addEventListener(xyd.event.ARENA_FIGHT_BATCH, handler(self, self.onGetArenaMsg))
	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_GET_AWARD, handler(self, self.onGetDressShowMsg))
	self.eventProxy_:addEventListener(xyd.event.SCHOOL_PRACTICE_BUY_TICKETS, handler(self, self.onGetAcademyAssessmentTicketMsg))
	self.eventProxy_:addEventListener(xyd.event.SCHOOL_PRACTICE_SWEEP, handler(self, self.onGetAcademyAssessmentMsg))
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_BUILDING_GET_OUT, handler(self, self.onGetExploreAwardMsg))
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_BUY_BREAD, handler(self, self.onGetExploreNBreadMsg))
	self.eventProxy_:addEventListener(xyd.event.BUY_SHOP_ITEM_BATCH, handler(self, self.onGetMarketMsg))
	self.eventProxy_:addEventListener(xyd.event.PET_TRAINING_GET_AWARD, handler(self, self.onGetPetHangAwardMsg))
	self.eventProxy_:addEventListener(xyd.event.PET_TRAINING_BUY_TIMES, handler(self, self.onGetPetBuyTicketMsg))
	self.eventProxy_:addEventListener(xyd.event.PET_TRAINING_FIGHT, handler(self, self.onGetPetChallengeMsg))
	self.eventProxy_:addEventListener(xyd.event.GUILD_CHECKIN, handler(self, self.onGetGuildSignInMsg))
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_COMPLETE_ORDER, handler(self, self.onGetGuildDinnerGetAwardMsg))
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_START_ORDER, handler(self, self.onGetGuildDinnerBeginOrderBeforeMsg))
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_NEW_ORDERS, handler(self, self.onGetGuildDinnerGetOrderMsg))
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_UPGRADE_ORDER, handler(self, self.onGetGuildDinnerLevelUpOrderMsg))
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_START_ORDER, handler(self, self.onGetGuildDinnerBeginOrderAfterMsg))
	self.eventProxy_:addEventListener(xyd.event.GUILD_BOSS_FIGHT, handler(self, self.onGetGuildGymMsg))
	self.eventProxy_:addEventListener(xyd.event.GET_MISSION_LIST, handler(self, self.onGetMissionMsg))
	self.eventProxy_:addEventListener(xyd.event.GET_MISSION_AWARDS, handler(self, self.onGetMissionAwardMsg))
end

function GameAssistantResultWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()

	self.presetData = self.model:getPresetData()
	self.todayHaveDoneData = self.model:getTodayHaveDoneData()
	self.ifCanDo = self.model:getIfCanDoData()
	self.labelTitle.text = __("GAME_ASSISTANT_TEXT91")
	self.labelDoingState.text = __("GAME_ASSISTANT_TEXT64")
	self.labelStop.text = __("GAME_ASSISTANT_TEXT66")
	self.labelSure.text = __("GAME_ASSISTANT_TEXT67")
	local timeStamp_dadian = xyd.db.misc:getValue("gameAssistant_dadian_timeStamp") or 0

	if not xyd.isSameDay(xyd.getServerTime(), tonumber(timeStamp_dadian)) then
		local msg = messages_pb:log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.GAME_ASSISTANT
		msg.desc = json.encode({
			time = xyd.getServerTime(),
			tab = self.chooseTab,
			crystal = self.model.totalCost[xyd.ItemID.CRYSTAL],
			gold = self.model.totalCost[xyd.ItemID.MANA]
		})

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
		xyd.db.misc:setValue({
			key = "gameAssistant_dadian_timeStamp",
			value = xyd.getServerTime()
		})
	end

	self:beginDoTasks()
end

function GameAssistantResultWindow:beginDoTasks()
	if self.chooseTab == 1 then
		self:doMidas()
	elseif self.chooseTab == 2 then
		self:doAcademyAssessment()
	elseif self.chooseTab == 3 then
		self:doExploreAward()
	elseif self.chooseTab == 4 then
		self:doGuildSignIn()
	else
		self:doMidas()
	end
end

function GameAssistantResultWindow:doMidas()
	local flag = false
	self.midaBuyTimes = xyd.models.midas.buy_times

	if self.ifCanDo.midas.free then
		self.model:buyMidas(1)

		self.midasFlag1 = true
		self.todayHaveDoneData.midas.free = true
		flag = true
	end

	if self.ifCanDo.midas.paid then
		self.oldMidaBuyTime = xyd.models.midas.buy_times
		self.midasFlag2 = self.model:buyMidas(2)
		flag = self.midasFlag2 or flag

		if self.midasFlag2 then
			self.todayHaveDoneData.midas.paid = self.presetData.midas.paid
		end
	end

	if not flag then
		self:doCampaign()
	end
end

function GameAssistantResultWindow:onGetMidasMsg(event)
	local data = event.data
	local params = {}
	local flag = false
	local baseNum = xyd.tables.midasTable:getGoldNew(xyd.models.backpack:getLev()) * (1 + xyd.tables.vipTable:extraMidas(xyd.models.backpack:getVipLev()))

	if data.buy_times == self.midaBuyTimes then
		self.midasFlag1 = false

		table.insert(self.tempItems, {
			item_id = 1,
			item_num = baseNum
		})

		if xyd.models.midas.is_free_award == 0 then
			self.midasFlag1 = true

			self.model:buyMidas(1)
		end
	else
		self.midaBuyTimes = data.buy_times
		local num = 0
		self.midasFlag2 = false

		for i = self.oldMidaBuyTime + 1, data.buy_times do
			num = num + baseNum * xyd.tables.midasBuyCoinTable:getMultiple(i)
		end

		table.insert(self.tempItems, {
			item_id = 1,
			item_num = num
		})
	end

	if not self.midasFlag1 and not self.midasFlag2 then
		params.items = self.tempItems

		self:createItem(params, __("GAME_ASSISTANT_TEXT08"))
		self:waitForTime(0.2, function ()
			self.tempItems = {}

			self:doCampaign()
		end)
	end
end

function GameAssistantResultWindow:doCampaign()
	local flag = false
	self.tempItems = {}

	if self.ifCanDo.campaign then
		flag = true
		self.campaignProtoNum = 1
		self.mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
		local dropItems = self.mapInfo.drop_items

		if dropItems and #dropItems > 0 then
			self.campaignProtoNum = self.campaignProtoNum + 1
		end

		self.model:reqCampaignAward()

		self.todayHaveDoneData.capaign = true
	end

	if not flag then
		self:doHouse()
	end
end

function GameAssistantResultWindow:onGetCampaignMsg(event)
	local data = event.data
	self.campaignProtoNum = self.campaignProtoNum - 1

	for i = 1, #data.award_items do
		table.insert(self.tempItems, data.award_items[i])
	end

	if self.campaignProtoNum == 0 then
		local params = {
			items = self.tempItems
		}

		self:createItem(params, __("GAME_ASSISTANT_TEXT101"))
		self:waitForTime(0.2, function ()
			self.tempItems = {}

			self:doHouse()
		end)
	end
end

function GameAssistantResultWindow:doHouse()
	local flag = false

	if self.ifCanDo.house then
		self.model:reqHouseAward()

		self.todayHaveDoneData.house = true
		flag = true
	end

	if not flag then
		self:doDailyQuizBuy()
	end
end

function GameAssistantResultWindow:onGetHouseMsg(event)
	local params = {}
	local data = event.data
	params.items = data.hang_items

	self:createItem(params, __("GAME_ASSISTANT_TEXT102"))
	self:waitForTime(0.2, function ()
		self:doDailyQuizBuy()
	end)
end

function GameAssistantResultWindow:doDailyQuizBuy()
	local flag = false
	self.haveBuyDailyQuizNum = 0

	for i = 1, 3 do
		if self.ifCanDo.dailyQuiz.paid[i] then
			local data = xyd.models.dailyQuiz:getDataByType(i)

			self.model:buyDailyQuizTime(i, self.presetData.dailyQuiz.paid[i] - data.limit_times)

			self.haveBuyDailyQuizNum = self.haveBuyDailyQuizNum + 1
			self.haveBuyDailyQuiz = true
			flag = true
			self.todayHaveDoneData.dailyQuiz.paid[i] = self.presetData.dailyQuiz.paid[i]
		end
	end

	if not flag then
		self:doDailyQuizAward()
	end
end

function GameAssistantResultWindow:onGetDailyQuizBuyMsg(event)
	local data = event.data
	local params = {}
	self.haveBuyDailyQuizNum = self.haveBuyDailyQuizNum - 1

	if self.haveBuyDailyQuizNum == 0 then
		self:doDailyQuizAward()
	end
end

function GameAssistantResultWindow:doDailyQuizAward()
	local flag = false

	if self.haveBuyDailyQuiz or self.ifCanDo.dailyQuiz.free then
		self.awardTimeDailyQuiz = self.model:reqDailyQuizAward()
		flag = true
		self.todayHaveDoneData.dailyQuiz.free = self.todayHaveDoneData.dailyQuiz.free or self.presetData.dailyQuiz.free
	end

	if not flag or self.awardTimeDailyQuiz == 0 then
		self:doSummon()
	end
end

function GameAssistantResultWindow:onGetDailyQuizAwardMsg(event)
	local data = event.data
	local params = {}
	self.awardTimeDailyQuiz = self.awardTimeDailyQuiz - 1

	for i = 1, #data.items do
		if #self.tempItems == 0 then
			table.insert(self.tempItems, data.items[i])
		else
			for j = 1, #self.tempItems do
				if self.tempItems[j].item_id == data.items[i].item_id then
					self.tempItems[j].item_num = self.tempItems[j].item_num + data.items[i].item_num

					break
				elseif j == #self.tempItems then
					table.insert(self.tempItems, data.items[i])
				end
			end
		end
	end

	if self.awardTimeDailyQuiz == 0 then
		params.items = self.tempItems

		self:createItem(params, __("GAME_ASSISTANT_TEXT14"))
		self:waitForTime(0.2, function ()
			xyd.db.misc:setValue({
				key = "daily_quize_redmark",
				value = xyd.getServerTime()
			})
			xyd.models.dailyQuiz:updateRedMark()

			self.tempItems = {}

			self:doSummon()
		end)
	end
end

function GameAssistantResultWindow:doSummon()
	local flag = false

	if self.ifCanDo.summon.normal then
		if self.presetData.summon.normal == 0 then
			flag = self.model:reqBaseSummon(true)
		else
			flag = self.model:reqBaseSummon(false)
		end

		self.summonFlag1 = flag
		self.todayHaveDoneData.summon.normal = true
	end

	if self.ifCanDo.summon.senior then
		if self.presetData.summon.senior == 0 then
			self.summonFlag2 = self.model:reqSeniorSummon(true)
			flag = self.summonFlag2 or flag
		else
			self.summonFlag2 = self.model:reqSeniorSummon(false)
			flag = self.summonFlag2 or flag
		end

		self.todayHaveDoneData.summon.senior = true
	end

	if not flag then
		self:doFriend()
	end
end

function GameAssistantResultWindow:onGetSummonMsg(event)
	local params = {}
	local data = event.data
	local itemID = data.summon_result.partners[1].table_id

	table.insert(self.tempItems, {
		item_num = 1,
		item_id = itemID
	})

	if data.summon_id == xyd.SummonType.BASE_FREE or data.summon_id == xyd.SummonType.BASE then
		params.items = self.tempItems

		self:createItem(params, __("GAME_ASSISTANT_TEXT19"))

		self.tempItems = {}
		self.summonFlag1 = false
	elseif data.summon_id == xyd.SummonType.SENIOR_FREE or data.summon_id == xyd.SummonType.SENIOR_SCROLL then
		params.items = self.tempItems

		self:createItem(params, __("GAME_ASSISTANT_TEXT18"))

		self.tempItems = {}
		self.summonFlag2 = false
	end

	if not self.summonFlag1 and not self.summonFlag2 then
		self:waitForTime(0.2, function ()
			self.tempItems = {}

			self:doFriend()
		end)
	end
end

function GameAssistantResultWindow:doFriend()
	local flag = false

	if self.ifCanDo.friend then
		self.sendFriendFlag, self.getFriendFlag = self.model:reqFriendLove()
		self.todayHaveDoneData.friend = true
	end

	if not self.sendFriendFlag and not self.getFriendFlag then
		self:doArena()
	end
end

function GameAssistantResultWindow:onGetGetFriendMsg(event)
	local data = event.data
	self.getFriendFlag = false
	local fids = data.friend_ids
	local params = {
		items = {
			{
				item_id = xyd.ItemID.FRIEND_LOVE,
				item_num = #fids
			}
		}
	}

	self:createItem(params, __("GAME_ASSISTANT_TEXT20"))

	self.haveCreateFreindItem = true

	if not self.sendFriendFlag and not self.getFriendFlag then
		self:waitForTime(0.2, function ()
			self:doArena()
		end)
	end
end

function GameAssistantResultWindow:onGetSendFriendMsg(event)
	local data = event.data
	self.sendFriendFlag = false

	if not self.sendFriendFlag and not self.getFriendFlag then
		if not self.haveCreateFreindItem then
			self:createItem(data, __("GAME_ASSISTANT_TEXT20"))
		end

		self:waitForTime(0.2, function ()
			self:doArena()
		end)
	end
end

function GameAssistantResultWindow:doArena()
	local flag = false

	if self.ifCanDo.arena then
		flag = self.model:reqArenaBattle()
		self.todayHaveDoneData.arena = true
	end

	if not flag then
		self:doTavern()
	end
end

function GameAssistantResultWindow:onGetArenaMsg(event)
	local data = event.data
	local battleResults = data.battle_results
	local params = {}

	for j = 1, #battleResults do
		local index = battleResults[j].index
		local items = battleResults[j].items[index]

		if not params.items then
			params.items = {}
		end

		table.insert(params.items, items)
	end

	if params.items and #params.items > 0 then
		self:createItem(params, __("GAME_ASSISTANT_TEXT73", #battleResults))
	end

	self:waitForTime(0.2, function ()
		self:doTavern()
	end)
end

function GameAssistantResultWindow:doTavern()
	local flag = false

	if self.ifCanDo.tavern then
		flag = self.model:reqComplteTavern(self.presetData.tavern)
		self.todayHaveDoneData.tavern = true
	end

	if not flag then
		self:doGamble()
	end
end

function GameAssistantResultWindow:onGetTavernMsg(event)
	local infos = event.data.pub_infos
	local params = {}
	local data = {}
	local awards = {}

	for _, info in ipairs(infos) do
		table.insert(awards, {
			item_id = info.award[1],
			item_num = info.award[2]
		})
	end

	params.items = awards

	self:createItem(params, __("GAME_ASSISTANT_TEXT23"))
	self:waitForTime(0.2, function ()
		self:doGamble()
	end)
end

function GameAssistantResultWindow:doGamble()
	local flag = false

	if self.ifCanDo.gamble then
		self.todayHaveDoneData.gamble = self.presetData.gamble
		flag = self.model:reqGamble()
		self.gamebleTime = 2
	end

	if not flag then
		self:doMarket()
	end
end

function GameAssistantResultWindow:onGetGambleMsg(event)
	local data = event.data
	local params = {}
	local awards = event.data.awards
	local type = event.data.gamble_type
	local items = xyd.models.gamble:getAwards(type, awards)
	local flag = false
	self.gamebleTime = self.gamebleTime - 1

	for i = 1, #items do
		table.insert(self.tempItems, items[i])
	end

	if self.gamebleTime == 0 then
		params.items = self.tempItems

		self:createItem(params, __("GAME_ASSISTANT_TEXT26"))
		self:waitForTime(0.2, function ()
			self.tempItems = {}

			self:doMarket()
		end)
	end
end

function GameAssistantResultWindow:doMarket()
	local flag = false

	if self.ifCanDo.market then
		flag = self.model:reqMarket()
		self.todayHaveDoneData.marketHasBuy = true
	end

	if not flag then
		self:doDressShow()
	end
end

function GameAssistantResultWindow:onGetMarketMsg(event)
	local data = event.data
	local params = {
		items = self.model:getTempBuyMarketItems()
	}

	self:createItem(params, __("GAME_ASSISTANT_TEXT27"))
	self:waitForTime(0.2, function ()
		self:doDressShow()
	end)
end

function GameAssistantResultWindow:doDressShow()
	local flag = false

	if self.ifCanDo.dressShow then
		flag = self.model:reqDressShowAward()
		self.todayHaveDoneData.dressShow = self.presetData.dressShow
	end

	if self.chooseTab == 1 then
		self:doGetMission()
	elseif not flag then
		self:doAcademyAssessment()
	end
end

function GameAssistantResultWindow:onGetDressShowMsg(event)
	local awardItems = {}
	local params = {}
	local data = xyd.decodeProtoBuf(event.data)
	local results = data.results

	if results then
		for i = 1, #results do
			local items = results[i].items

			if items and #items > 0 then
				for j = 1, #items do
					table.insert(awardItems, items[j])
				end
			end
		end
	end

	if #awardItems > 0 then
		params.items = awardItems

		self:createItem(params, __("GAME_ASSISTANT_TEXT30"))

		if self.chooseTab == 1 then
			self:doGetMission()
		else
			self:waitForTime(0.2, function ()
				self:doAcademyAssessment()
			end)
		end
	elseif self.chooseTab == 1 then
		self:doGetMission()
	else
		self:doAcademyAssessment()
	end
end

function GameAssistantResultWindow:doAcademyAssessment()
	local flag = false
	local fort = self.presetData.academyAssessment.fort

	if self.ifCanDo.academyAssessment.paid then
		self.oldTicketNumAcademyAssessment = self.model:getMaxCanSweepAcademyAssessment()
		self.realBuyTicketNumAcademyAssessment = self.model:buyTicketAcademyAssessment(self.presetData.academyAssessment.paid - xyd.models.academyAssessment:getBuySweepTimes())

		if self.realBuyTicketNumAcademyAssessment > 0 then
			self.needBuyAcademyAssessmentTicket = true
			flag = true
		end
	end

	if not self.ifCanDo.academyAssessment.paid and self.ifCanDo.academyAssessment.free then
		local time = math.min(self.model:getMaxCanSweepAcademyAssessment(), self.presetData.academyAssessment.free)

		self.model:freeSweepAcademyAssessment(fort, time)

		self.todayHaveDoneData.academyAssessment.free = self.todayHaveDoneData.academyAssessment.free + time
		flag = true
	end

	if self.chooseTab == 2 then
		self:doGetMission()
	elseif not flag then
		self:doExploreAward()
	end
end

function GameAssistantResultWindow:onGetAcademyAssessmentTicketMsg(event)
	self.needBuyAcademyAssessmentTicket = false
	local fort = self.presetData.academyAssessment.fort
	local paidTimes = self.realBuyTicketNumAcademyAssessment
	local freeTimes = math.min(self.oldTicketNumAcademyAssessment, self.presetData.academyAssessment.free)

	self.model:freeSweepAcademyAssessment(fort, paidTimes + freeTimes)

	self.todayHaveDoneData.academyAssessment.free = self.todayHaveDoneData.academyAssessment.free + freeTimes
	self.todayHaveDoneData.academyAssessment.paid = self.todayHaveDoneData.academyAssessment.paid + paidTimes
end

function GameAssistantResultWindow:onGetAcademyAssessmentMsg(event)
	local data = event.data

	self:createItem(data, __("GAME_ASSISTANT_TEXT36"))

	if self.chooseTab == 2 then
		self:doGetMission()
	else
		self:waitForTime(0.2, function ()
			self:doExploreAward()
		end)
	end
end

function GameAssistantResultWindow:doExploreAward()
	local flag = false

	if self.ifCanDo.explore.award then
		self.model:reqExploreAward()

		flag = true
	end

	if not flag then
		self:doExploreBread()
	end
end

function GameAssistantResultWindow:onGetExploreAwardMsg(event)
	local params = {}
	local data = event.data

	if data.items and #data.items > 0 then
		params.items = data.items
	end

	if params.items and #params.items > 0 then
		self:createItem(params, __("GAME_ASSISTANT_TEXT82"))
		self:waitForTime(0.2, function ()
			self:doExploreBread()
		end)
	else
		self:doExploreBread()
	end
end

function GameAssistantResultWindow:doExploreBread()
	local flag = false

	if self.ifCanDo.explore.bread then
		self.model:reqBuyBreadExplore(self.presetData.explore.bread - self.model:getBuyTimeBreadExplore())

		self.todayHaveDoneData.explore.bread = self.presetData.explore.bread
		flag = true
	end

	if not flag then
		self:doPetMission()
	end
end

function GameAssistantResultWindow:onGetExploreNBreadMsg(event)
	local data = event.data

	self:createItem(data, __("GAME_ASSISTANT_TEXT83"))
	self:waitForTime(0.2, function ()
		self:doPetMission()
	end)
end

function GameAssistantResultWindow:doPetMission()
	local flag = false
	self.tempItems = {}

	if self.ifCanDo.pet.award then
		flag = self.model:getPetHangAward()
	end

	if not flag then
		self:doPetBuyTicket()
	end
end

function GameAssistantResultWindow:onGetPetHangAwardMsg(event)
	local data = event.data
	local items = data.items

	for key, value in pairs(items) do
		if value and value.item_id then
			table.insert(self.tempItems, value)
		end
	end

	local params = {
		items = self.tempItems
	}

	self:createItem(params, __("GAME_ASSISTANT_TEXT78"))
	self:waitForTime(0.2, function ()
		self.tempItems = {}

		self:doPetBuyTicket()
	end)
end

function GameAssistantResultWindow:doPetBuyTicket()
	local flag = false
	local baseTime = xyd.tables.miscTable:getNumber("pet_training_boss_limit", "value")
	local buyTimes = xyd.models.petTraining:getBuyTimeTimes() or 0

	if self.ifCanDo.pet.fight and self.presetData.pet.fight - buyTimes - baseTime > 0 then
		self.hasBuyPetTicketNum = 0
		self.oldPetBuyTime = xyd.models.petTraining:getBuyTimeTimes()
		self.buyPetTicket = self.model:buyChallengeTiliPet()
		flag = true
	end

	if not flag then
		self:doPetChallenge()
	end
end

function GameAssistantResultWindow:onGetPetBuyTicketMsg(event)
	local data = event.data
	self.hasBuyPetTicketNum = self.hasBuyPetTicketNum + 1
	local baseTime = xyd.tables.miscTable:getNumber("pet_training_boss_limit", "value")

	if self.presetData.pet.fight <= self.hasBuyPetTicketNum + self.oldPetBuyTime + baseTime then
		self:createItem({}, __("GAME_ASSISTANT_TEXT80", self.hasBuyPetTicketNum))
		self:doPetChallenge()
	end
end

function GameAssistantResultWindow:doPetChallenge()
	local flag = false

	if self.ifCanDo.pet.fight then
		self.lastHp = xyd.models.petTraining:getBossHp()
		local baseTime = xyd.tables.miscTable:getNumber("pet_training_boss_limit", "value")
		local buyTimes = xyd.models.petTraining:getBuyTimeTimes() or 0
		local battleTimes = xyd.models.petTraining:getBattleTimes() or 0
		local leftChallengTime = baseTime - battleTimes
		local allChallengTime = baseTime + buyTimes
		local haveDoneChallengTime = allChallengTime - leftChallengTime
		flag = self.model:completeAllChallengePet(self.presetData.pet.fight - haveDoneChallengTime)
		self.todayHaveDoneData.pet.fight = self.presetData.pet.fight
	end

	if self.chooseTab == 3 and not flag then
		self:doGetMission()
	elseif not flag then
		self:doGuildSignIn()
	end
end

function GameAssistantResultWindow:onGetPetChallengeMsg(event)
	local data = event.data
	local params = {
		items = {}
	}
	local harm = data.harm
	local bossMaxHp = xyd.tables.petTrainingBossTable:getHp(xyd.models.petTraining:getBossID())
	local bossRebornTime = data.reborn_count or 0
	local attackTime = xyd.models.gameAssistant.petChallengeTime

	for i = 1, bossRebornTime do
		local items = xyd.tables.petTrainingBossTable:getFinalAwards(xyd.models.petTraining:getBossID())

		for i = 1, #items do
			table.insert(params.items, {
				item_id = items[i][1],
				item_num = items[i][2]
			})
		end
	end

	for i = 1, attackTime - bossRebornTime do
		local items = xyd.tables.petTrainingBossTable:getBattleAwards(xyd.models.petTraining:getBossID())

		for i = 1, #items do
			table.insert(params.items, {
				item_id = items[i][1],
				item_num = items[i][2]
			})
		end
	end

	self:createItem(params, __("GAME_ASSISTANT_TEXT81"))

	if self.chooseTab == 3 then
		self:doGetMission()
	else
		self:waitForTime(0.2, function ()
			self:doGuildSignIn()
		end)
	end
end

function GameAssistantResultWindow:doGuildSignIn()
	local flag = false

	if self.ifCanDo.guild.signIn then
		self.model:reqCheckInGuild()

		self.todayHaveDoneData.guild.signIn = true
		flag = true
	end

	if not flag then
		self:doGuildDinnerGetAward()
	end
end

function GameAssistantResultWindow:onGetGuildSignInMsg(event)
	local data = event.data
	local params = {}
	local cost = xyd.tables.miscTable:split2Cost("guild_sign_in_show", "value", "|#")
	local items_multiple = 1

	if xyd.models.activity:isResidentReturnAddTime() then
		items_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.GUILD)
	end

	local items = {}

	for i = 1, #cost do
		local data = cost[i]
		local num = tonumber(data[2]) * items_multiple
		local item = {
			hideText = true,
			item_id = data[1],
			item_num = num
		}

		table.insert(items, item)
	end

	params.items = items

	self:createItem(params, __("GAME_ASSISTANT_TEXT84"))
	self:waitForTime(0.2, function ()
		self:doGuildDinnerGetAward()
	end)
end

function GameAssistantResultWindow:doGuildDinnerGetAward()
	local flag = false
	local serverTime = xyd.getServerTime()
	local orderList = xyd.models.guild:getDiningHallOrderList()
	self.needGetGuildDinnerAward = 0
	self.guildDinnerAward = {}
	local ids = {}

	if self.ifCanDo.guild.order then
		for key, order in pairs(orderList) do
			local endTime = order.start_time + xyd.tables.guildOrderTable:getTime(order.order_lv)

			if order.start_time > 0 and endTime < serverTime then
				self.needGetGuildDinnerAward = self.needGetGuildDinnerAward + 1

				table.insert(ids, order.order_id)

				flag = true
			end
		end

		for i = 1, #ids do
			xyd.models.guild:reqDiningHallCompleteOrder(ids[i])
		end
	end

	if not flag then
		if self.model.orderAwards then
			local params = {
				items = self.model.orderAwards
			}

			self:createItem(params, __("GAME_ASSISTANT_TEXT103"))
			self.model:setOrderAwards(nil)
		end

		self:doGuildDinnerBeginOrderBefore()
	end
end

function GameAssistantResultWindow:onGetGuildDinnerGetAwardMsg(event)
	local data = event.data
	local params = {}
	self.needGetGuildDinnerAward = self.needGetGuildDinnerAward - 1

	for key, item in pairs(data.awards) do
		table.insert(self.guildDinnerAward, item)
	end

	if self.needGetGuildDinnerAward == 0 then
		params.items = self.guildDinnerAward

		self:createItem(params, __("GAME_ASSISTANT_TEXT103"))
		self:waitForTime(0.2, function ()
			self:doGuildDinnerBeginOrderBefore()
		end)
	end
end

function GameAssistantResultWindow:doGuildDinnerBeginOrderBefore()
	local flag = false
	local orderList = xyd.models.guild:getDiningHallOrderList()
	self.isInAfterStage = false
	self.beginOrders = {}
	local ids = {}
	self.beginOrderList = {
		orderDatas = {}
	}

	if self.ifCanDo.guild.order then
		for key, order in pairs(orderList) do
			if order.start_time == 0 then
				table.insert(ids, order.order_id)
				table.insert(self.beginOrders, order.order_id)

				flag = true
			end
		end

		self.beginOrderBeforeNum = #ids

		for i = 1, #ids do
			xyd.models.guild:reqDiningHallStartOrder(ids[i])
		end
	end

	if not flag then
		self:doGuildDinnerGetOrder()
	end
end

function GameAssistantResultWindow:onGetGuildDinnerBeginOrderBeforeMsg(event)
	local data = event.data

	if self.isInAfterStage == true then
		return
	end

	self.beginOrderBeforeNum = self.beginOrderBeforeNum - 1

	table.insert(self.beginOrderList.orderDatas, data.order_info)

	if self.beginOrderBeforeNum == 0 then
		self:doGuildDinnerGetOrder()
	end
end

function GameAssistantResultWindow:doGuildDinnerGetOrder()
	local flag = false
	local gSelfInfo = xyd.models.guild.self_info
	gSelfInfo.order_time = gSelfInfo.order_time or 0
	local tmp = xyd.getServerTime()
	local tmp2 = tonumber(xyd.tables.miscTable:getVal("guild_order_cd"))

	if tmp < gSelfInfo.order_time + tmp2 then
		self.todayHaveDoneData.guild.order = true

		self:doGuildDinnerLevelUpOrder()

		return
	end

	if self.ifCanDo.guild.order then
		xyd.models.guild:reqDiningHallNewOrders()

		flag = true
	end

	if not flag then
		self:doGuildDinnerLevelUpOrder()
	end
end

function GameAssistantResultWindow:onGetGuildDinnerGetOrderMsg(event)
	local data = event.data

	self:doGuildDinnerLevelUpOrder()
end

function GameAssistantResultWindow:doGuildDinnerLevelUpOrder()
	local flag = false

	if self.ifCanDo.guild.level then
		local orderList = xyd.models.guild:getDiningHallOrderList()
		local costNum = self.model:getLevelUpOrderCost()
		self.levelOrderNum = 0
		self.haveLevelOrderNum = 0
		local desLev = self.presetData.guild.level

		for _, order in pairs(orderList) do
			if order.start_time == 0 and order.order_lv < desLev then
				self.levelOrderNum = self.levelOrderNum + 1
			end
		end

		if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < costNum then
			self:doGuildDinnerBeginOrderAfter()

			return
		end

		if self.levelOrderNum > 0 then
			self.model:reqLevelUpOrder()

			self.todayHaveDoneData.guild.level = self.presetData.guild.level
			flag = true
		end
	end

	if not flag then
		self:doGuildDinnerBeginOrderAfter()
	end
end

function GameAssistantResultWindow:onGetGuildDinnerLevelUpOrderMsg(event)
	local data = event.data
	self.haveLevelOrderNum = self.haveLevelOrderNum + 1

	if self.levelOrderNum == self.haveLevelOrderNum then
		self:createItem(data, __("GAME_ASSISTANT_TEXT86", self.haveLevelOrderNum))
		self:waitForTime(0.2, function ()
			self:doGuildDinnerBeginOrderAfter()
		end)
	end
end

function GameAssistantResultWindow:doGuildDinnerBeginOrderAfter()
	local flag = false
	self.isInAfterStage = true
	local orderList = xyd.models.guild:getDiningHallOrderList()
	self.beginOrders = {}
	local ids = {}

	if self.ifCanDo.guild.order then
		for key, order in pairs(orderList) do
			if order.start_time == 0 then
				table.insert(ids, order.order_id)
				table.insert(self.beginOrders, order.order_id)

				flag = true
			end
		end

		self.beginOrderBeforeNum = #ids

		for i = 1, #ids do
			xyd.models.guild:reqDiningHallStartOrder(ids[i])
		end
	end

	if not flag then
		if #self.beginOrders > 0 then
			self:createItem(self.beginOrderList, __("GAME_ASSISTANT_TEXT87"))
		end

		self:doGuildGym()
	end
end

function GameAssistantResultWindow:onGetGuildDinnerBeginOrderAfterMsg(event)
	if not self.isInAfterStage then
		return
	end

	local data = event.data
	self.beginOrderBeforeNum = self.beginOrderBeforeNum - 1

	table.insert(self.beginOrderList.orderDatas, data.order_info)

	if self.beginOrderBeforeNum == 0 then
		self:createItem(self.beginOrderList, __("GAME_ASSISTANT_TEXT87"))
		self:waitForTime(0.2, function ()
			self:doGuildGym()
		end)
	end
end

function GameAssistantResultWindow:doGuildGym()
	local flag = false

	if self.ifCanDo.guild.gym then
		local leftTime = xyd.models.guild:getFinalBossLeftCount()

		if leftTime > 0 then
			self.gymBattleTime = leftTime

			for i = 1, leftTime do
				self.model:reqGuildFightBoss()

				self.todayHaveDoneData.guild.gym = true
				flag = true
			end
		end
	end

	if not flag then
		self:doGetMission()
	end
end

function GameAssistantResultWindow:onGetGuildGymMsg(event)
	local data = event.data
	data = xyd.decodeProtoBuf(data)
	local params = {
		battle_report = data.battle_report,
		items = data.awards,
		total_harm = data.total_harm
	}

	self:createItem(params, __("GAME_ASSISTANT_TEXT88", self.gymBattleTime))

	self.gymBattleTime = self.gymBattleTime - 1
	local guildModel = xyd.models.guild

	guildModel:updateBossInfo({
		event_data = data,
		map_type = xyd.MapType.GUILD_BOSS,
		battle_type = xyd.MapType.GUILD_BOSS
	})

	if self.gymBattleTime == 0 then
		self:doGetMission()
	end
end

function GameAssistantResultWindow:doGetMission()
	self.haveReqMissonData = true

	xyd.models.mission:getData()
end

function GameAssistantResultWindow:onGetMissionMsg(event)
	if self.haveReqMissonData == true then
		self:doBattlePassMission()

		self.haveReqMissonData = false
	end
end

function GameAssistantResultWindow:doBattlePassMission()
	local flag = false
	self.tempItems = {}
	local missions = xyd.models.mission:getMissionList()
	local reqMissionList = {}

	for idx, missionData in ipairs(missions) do
		if xyd.tables.battlePassMissionTable:getType(missionData.mission_id) == 1 and missionData.is_completed == 1 and missionData.is_awarded ~= 1 then
			table.insert(reqMissionList, missionData.mission_id)
		end
	end

	if #reqMissionList > 0 then
		xyd.models.mission:reqAwardList(reqMissionList)

		flag = true
	end

	if not flag then
		self:finishAllTask()
	end
end

function GameAssistantResultWindow:onGetMissionAwardMsg(event)
	local data = event.data
	local items = {}
	local params = {}
	local reqMissionList = {}
	local missionIDs = event.data.result
	local missions = xyd.models.mission:getMissionList()

	for _, data in ipairs(missionIDs) do
		local mission_id = data.mission_id
		local awards = xyd.models.mission:getNowMissionTable():getAward(mission_id, xyd.models.activity:getBattlePassId())

		for i = 1, 2 do
			local itemNum = awards[i * 2]

			if itemNum then
				local num = awards[i * 2]
				local itemId = awards[i * 2 - 1]

				if itemId == 117 then
					itemId = 223
				end

				if i == 1 then
					for idx, missionData in ipairs(missions) do
						if xyd.tables.battlePassMissionTable:getType(missionData.mission_id) == 1 and missionData.mission_id == mission_id then
							num = num + missionData.extra
						end
					end
				end

				table.insert(self.tempItems, {
					item_id = itemId,
					item_num = num
				})
			end
		end
	end

	local finalMissionData = xyd.models.mission:getFinalMissionInfo()

	if finalMissionData.is_completed == 1 and finalMissionData.is_awarded ~= 1 then
		table.insert(reqMissionList, finalMissionData.mission_id)
	end

	if #reqMissionList > 0 then
		xyd.models.mission:reqAwardList({
			finalMissionData.mission_id
		})
	end

	if #self.tempItems > 0 and #reqMissionList <= 0 then
		params.items = self.tempItems

		self:createItem(params, __("GAME_ASSISTANT_TEXT96"))
	end

	self:finishAllTask()
end

function GameAssistantResultWindow:finishAllTask()
	self.btnSure:SetActive(true)
	self.btnStop:SetActive(false)

	self.labelDoingState.text = __("GAME_ASSISTANT_TEXT65")
end

function GameAssistantResultWindow:createItem(data, title)
	local tmp = NGUITools.AddChild(self.itemGroup.gameObject, self.item)
	local item = GameAssistantResultItem.new(tmp, self)

	table.insert(self.itemArr, item)
	item:setInfo(data, title)
	tmp.transform:SetSiblingIndex(0)
	self.itemGroupLayout:Reposition()
end

function GameAssistantResultItem:ctor(go, parent)
	GameAssistantResultItem.super.ctor(self, go, parent)

	self.parent = parent
	self.icons = {}
	self.orderItems = {}
end

function GameAssistantResultItem:initUI()
	self.labelTitle = self.go:ComponentByName("labelTitle", typeof(UILabel))
	self.labelFinish = self.go:ComponentByName("labelFinish", typeof(UILabel))
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.itemGroupGrid = self.go:ComponentByName("itemGroup", typeof(UIGrid))
	self.battleGroup = self.go:NodeByName("battleGroup").gameObject
	self.labelDamage = self.battleGroup:ComponentByName("labelDamage", typeof(UILabel))
	self.btnDetail = self.battleGroup:NodeByName("btnDetail").gameObject
	self.orderGroup = self.go:NodeByName("orderGroup").gameObject
	self.orderGroupGrid = self.go:ComponentByName("orderGroup", typeof(UIGrid))
end

function GameAssistantResultItem:setInfo(data, title)
	local itemHeight = 100
	local haveSomething = false
	self.labelTitle.text = title

	if data.items then
		self.itemGroup:SetActive(true)

		local items = data.items

		for i = 1, #items do
			local item = items[i]
			local params = {
				show_has_num = false,
				scale = 0.7037037037037037,
				notShowGetWayBtn = true,
				uiRoot = self.itemGroup,
				itemID = item.item_id or item[1],
				num = item.item_num or item[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView
			}
			self.icons[i] = AdvanceIcon.new(params)
		end

		self.itemGroupGrid:Reposition()

		haveSomething = true
		itemHeight = itemHeight + math.ceil(#items / 6) * 91

		if not data.battle_report and not data.orderDatas then
			itemHeight = itemHeight - 44
		end
	end

	if data.battle_report then
		self.battleGroup:SetActive(true)

		self.labelDamage.text = "[c][5e6996]" .. __("FRIEND_HARM") .. "[-][/c]" .. "[c][71d766]" .. xyd.getDisplayNumber(data.total_harm) .. "[-][/c]"

		UIEventListener.Get(self.btnDetail).onClick = function ()
			xyd.WindowManager.get():openWindow("battle_detail_data_window", {
				alpha = 0.7,
				battle_params = data.battle_report,
				real_battle_report = data.battle_report
			})
		end

		haveSomething = true

		self.itemGroup:Y(-140)

		self.itemGroupGrid.pivot = UIWidget.Pivot.Top

		self.itemGroup:X(0)
		self.itemGroupGrid:Reposition()
	end

	if data.orderDatas then
		self.orderGroup:SetActive(true)

		local orderDatas = data.orderDatas

		for i = 1, #orderDatas do
			local orderData = orderDatas[i]
			local tmp = NGUITools.AddChild(self.orderGroup.gameObject, self.parent.orderItem)
			local item = GameAssistantDinnerOrderItem.new(tmp, self.orderGroup)

			table.insert(self.orderItems, item)
			item:setInfo(orderData)
		end

		self.orderGroupGrid:Reposition()

		haveSomething = true
		itemHeight = itemHeight + math.ceil(#orderDatas / 4) * 134
	end

	if not haveSomething then
		self.labelFinish:SetActive(true)

		self.labelFinish.text = __("GAME_ASSISTANT_TEXT90")
	end

	self.go:ComponentByName("", typeof(UISprite)).height = itemHeight
end

function GameAssistantDinnerOrderItem:ctor(go, parent)
	GameAssistantDinnerOrderItem.super.ctor(self, go, parent)

	self.parent = parent
	self.icons = {}
end

function GameAssistantDinnerOrderItem:initUI()
	self.progress = self.go:ComponentByName("progress", typeof(UISprite))
	self.label = self.progress:ComponentByName("label", typeof(UILabel))
	self.thumb = self.progress:ComponentByName("thumb", typeof(UISprite))
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.imgFood = self.go:ComponentByName("imgFood", typeof(UISprite))
	self.starGroup = self.go:NodeByName("starGroup").gameObject
	self.starGroupLayout = self.go:ComponentByName("starGroup", typeof(UILayout))

	for i = 1, 6 do
		self["star" .. i] = self.starGroup:ComponentByName("star_" .. i, typeof(UISprite))
	end

	self.labelTime = self.go:ComponentByName("labelTime", typeof(UILabel))
end

function GameAssistantDinnerOrderItem:setInfo(data)
	local lev = data.order_lv
	local start_time = data.start_time
	local serverTime = xyd.getServerTime()
	local endTime = start_time + xyd.tables.guildOrderTable:getTime(lev)

	xyd.setUISpriteAsync(self.imgFood, nil, xyd.tables.guildOrderTable:getPic(lev))

	self.labelTime.text = __("HOUR", tostring(xyd.tables.guildOrderTable:getTime(lev) / 3600))
	self.label.text = xyd.secondsToString(endTime - serverTime)

	for i = 1, 6 do
		if i <= lev then
			self["star" .. i]:SetActive(true)
		else
			self["star" .. i]:SetActive(false)
		end
	end

	CountDown.new(self.label, {
		duration = endTime - serverTime
	})
end

return GameAssistantResultWindow
