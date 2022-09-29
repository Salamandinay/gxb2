local BaseWindow = import(".BaseWindow")
local GameAssistantWindow = class("GameAssistantWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local BaseComponent = import("app.components.BaseComponent")
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")
local SelectNum = import("app.components.SelectNum")
local PngNum = import("app.components.PngNum")
local tabTitle = {
	__("GAME_ASSISTANT_TEXT02"),
	__("GAME_ASSISTANT_TEXT03"),
	__("GAME_ASSISTANT_TEXT04"),
	__("GAME_ASSISTANT_TEXT05")
}
local numColorMap = {
	"friend_team_boss_brown",
	"friend_team_boss_grey",
	"friend_team_boss_yellow",
	"friend_team_boss_blue",
	"friend_team_boss_yellow",
	"friend_team_boss_yellow",
	"friend_team_boss_yellow",
	"friend_team_boss_yellow"
}

function GameAssistantWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model = xyd.models.gameAssistant
	local timeStamp_gambleData = xyd.db.misc:getValue("gameAssistant_req_gambleData")

	if not timeStamp_gambleData or xyd.getServerTime(-tonumber(timeStamp_gambleData)) > xyd.SECOND * 5 then
		xyd.models.gamble:reqGambleInfo(1)
		xyd.db.misc:setValue({
			key = "gameAssistant_req_gambleData",
			value = xyd.getServerTime()
		})
	end

	local timeStamp_dungeonData = xyd.db.misc:getValue("gameAssistant_req_DungeonData")

	if not timeStamp_dungeonData or xyd.getServerTime() - tonumber(timeStamp_dungeonData) > xyd.SECOND * 5 then
		xyd.models.dungeon:reqDungeonInfo()
		xyd.db.misc:setValue({
			key = "gameAssistant_req_DungeonData",
			value = xyd.getServerTime()
		})
	end

	if xyd.models.guild.guildID > 0 and #xyd.models.guild:getDiningHallOrderList() == 0 then
		local msg = messages_pb:guild_dininghall_order_list_req()
		msg.no_award = 1

		xyd.Backend.get():request(xyd.mid.GUILD_DININGHALL_ORDER_LIST, msg)
	end

	if params then
		self.curTabIndex = params.curTabIndex or 1
	else
		self.curTabIndex = 1
	end
end

function GameAssistantWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.btnClose = self.groupAction:NodeByName("closeBtn").gameObject
	self.btnHelp = self.groupAction:NodeByName("helpBtn").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.labelCurLabel = self.groupAction:ComponentByName("labelCurLabel", typeof(UILabel))
	self.scroller = self.groupAction:NodeByName("scroller").gameObject
	self.scrollView = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.content1 = self.scroller:NodeByName("content1").gameObject
	self.midasPart = self.content1:NodeByName("midasPart").gameObject
	self.campaignPart = self.content1:NodeByName("campaignPart").gameObject
	self.hoursePart = self.content1:NodeByName("hoursePart").gameObject
	self.dailyQuizPart = self.content1:NodeByName("dailyQuizPart").gameObject
	self.summonPart = self.content1:NodeByName("summonPart").gameObject
	self.freindPart = self.content1:NodeByName("freindPart").gameObject
	self.arenaPart = self.content1:NodeByName("arenaPart").gameObject
	self.tavernPart = self.content1:NodeByName("tavernPart").gameObject
	self.gamblePart = self.content1:NodeByName("gamblePart").gameObject
	self.marketPart = self.content1:NodeByName("marketPart").gameObject
	self.dressShowPart = self.content1:NodeByName("dressShowPart").gameObject
	self.content2 = self.scroller:NodeByName("content2").gameObject
	self.dungeonPart = self.content2:NodeByName("dungeonPart").gameObject
	self.academyAssessmentPart = self.content2:NodeByName("AcademyAssessmentPart").gameObject
	self.content3 = self.scroller:NodeByName("content3").gameObject
	self.explorePart = self.content3:NodeByName("explorePart").gameObject
	self.petPart = self.content3:NodeByName("petPart").gameObject
	self.content4 = self.scroller:NodeByName("content4").gameObject
	self.guildTerritoryPart = self.content4:NodeByName("guildTerritoryPart").gameObject
	self.guildDinnerHallPart = self.content4:NodeByName("guildDinnerHallPart").gameObject
	self.guildGymPart = self.content4:NodeByName("guildGymPart").gameObject
	self.tabGroup = self.groupAction:NodeByName("tabGroup").gameObject

	for i = 1, 4 do
		self["tab" .. i] = self.tabGroup:NodeByName("tab" .. i).gameObject
	end

	self.btnDoAllTab = self.groupAction:NodeByName("btnDoAllTab").gameObject
	self.btnCurTab = self.groupAction:NodeByName("btnCurTab").gameObject
end

function GameAssistantWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()

	self.presetData = self.model:getPresetData()
	self.todayHaveDoneData = self.model:getTodayHaveDoneData()
	self.labelTitle.text = __("GAME_ASSISTANT_TEXT01")
	self.groupAction:ComponentByName("btnDoAllTab/label", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT07")
	self.groupAction:ComponentByName("btnCurTab/label", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT06")
	local timeStamp = xyd.db.misc:getValue("gameAssistant_todayHaveDoneData_timeStamp")

	if not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime()) then
		self.model:onSystemUpdate()
	end

	local flag = self.model:checkMarketNeedClear()

	self:chooseTab(self.curTabIndex)

	if flag then
		xyd.WindowManager.get():openWindow("gamble_tips_window", {
			hideGroupChoose = true,
			type = "game_assistant_market_clear",
			callback = function ()
				xyd.openWindow("game_assistant_market_window", {
					shopType = xyd.ShopType.SHOP_BLACK_NEW
				})
			end,
			closeCallback = function ()
			end,
			text = __("GAME_ASSISTANT_TEXT109"),
			btnYesText_ = __("YES"),
			btnNoText_ = __("NO")
		})
	end
end

function GameAssistantWindow:register()
	self.eventProxy_:addEventListener(xyd.event.DUNGEON_START, handler(self, self.onDungeonStart))
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_ORDER_LIST, function (event)
		local data = event.data
		local awards = data.awards

		if awards and awards[1] then
			self.model:setOrderAwards(awards)
		end
	end)

	UIEventListener.Get(self.trans:NodeByName("WINDOWBG").gameObject).onClick = function ()
		local wnd = xyd.getWindow("main_window")

		if wnd then
			wnd:playHideGameAssistantBtnAnimation()
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnClose).onClick = function ()
		local wnd = xyd.getWindow("main_window")

		if wnd then
			wnd:playHideGameAssistantBtnAnimation()
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		local fortId = xyd.tables.stageTable:getFortID(xyd.tables.functionTable:getOpenValue(xyd.FunctionID.GAME_ASSISTANT))
		local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(xyd.tables.functionTable:getOpenValue(xyd.FunctionID.GAME_ASSISTANT)))

		xyd.openWindow("help_window", {
			key = "GAME_ASSISTANT_HELP01",
			values = {
				text
			}
		})
	end

	UIEventListener.Get(self.btnDoAllTab).onClick = function ()
		local flag = self.model:jungeIfCanDo(0)

		if flag == false then
			xyd.alertTips(__("GAME_ASSISTANT_TIPS02"))

			return
		end

		local function callbackExcute(flag)
			if flag == true then
				if xyd.models.dailyQuiz:isAllMaxLev() then
					xyd.WindowManager.get():openWindow("daily_quiz2_window")
				else
					xyd.WindowManager.get():openWindow("daily_quiz_window")
				end

				xyd.WindowManager.get():closeWindow(self.name_)
			else
				local timeStamp = xyd.db.misc:getValue("game_assistant_crystal_time_stamp")
				local tipsTextY, tipsHeight = nil

				if xyd.Global.lang == "de_de" then
					tipsTextY = 60
					tipsHeight = 100
				end

				if (not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true)) and xyd.models.gameAssistant:getTotalCostCrystal() > 0 then
					xyd.WindowManager.get():openWindow("gamble_tips_window", {
						type = "game_assistant_crystal",
						callback = function ()
							self:checkArenaFormation(function ()
								xyd.openWindow("game_assistant_result_window", {
									inWitchTab = self.curTabIndex
								})
								xyd.WindowManager.get():closeWindow(self.name_)
							end)
						end,
						closeCallback = function ()
						end,
						text = __("GAME_ASSISTANT_TIPS03", xyd.models.gameAssistant:getTotalCostCrystal()),
						btnNoText_ = __("NO"),
						btnYesText_ = __("YES"),
						labelNeverText = __("GAMBLE_REFRESH_NOT_SHOW_TODAY"),
						tipsTextY = tipsTextY,
						tipsHeight = tipsHeight
					})

					return
				else
					self:checkArenaFormation(function ()
						xyd.openWindow("game_assistant_result_window", {
							inWitchTab = self.curTabIndex
						})
						xyd.WindowManager.get():closeWindow(self.name_)
					end)

					return
				end
			end
		end

		if self.model.ifCanDo.dailyQuiz.free then
			local needTips = false

			for j = 1, 3 do
				local ids = xyd.tables.dailyQuizTable:getIDsByType(j)
				local curSweepLev = xyd.tables.dailyQuizTable:getLv(xyd.models.dailyQuiz:getDataByType(j).cur_quiz_id)

				if curSweepLev then
					for i = 1, #ids do
						local id = ids[i]
						local lv = xyd.tables.dailyQuizTable:getLv(id)

						if lv < xyd.models.backpack:getLev() and curSweepLev < lv then
							needTips = true

							break
						end
					end
				end
			end

			if needTips then
				xyd.alertYesNo(__("GAME_ASSISTANT_TIPS01"), callbackExcute, __("YES"), false, nil, , , , , )

				return
			end
		end

		callbackExcute(false)
	end

	UIEventListener.Get(self.btnCurTab).onClick = function ()
		local flag = self.model:jungeIfCanDo(self.curTabIndex)

		if flag == false then
			xyd.alertTips(__("GAME_ASSISTANT_TIPS02"))

			return
		end

		local function callbackExcute(flag)
			if flag == true then
				if xyd.models.dailyQuiz:isAllMaxLev() then
					xyd.WindowManager.get():openWindow("daily_quiz2_window")
				else
					xyd.WindowManager.get():openWindow("daily_quiz_window")
				end

				xyd.WindowManager.get():closeWindow(self.name_)
			else
				local timeStamp = xyd.db.misc:getValue("game_assistant_crystal_time_stamp")
				local tipsTextY, tipsHeight = nil

				if xyd.Global.lang == "de_de" then
					tipsTextY = 60
					tipsHeight = 100
				end

				if (not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true)) and xyd.models.gameAssistant:getTotalCostCrystal() > 0 then
					xyd.WindowManager.get():openWindow("gamble_tips_window", {
						type = "game_assistant_crystal",
						callback = function ()
							self:checkArenaFormation(function ()
								xyd.openWindow("game_assistant_result_window", {
									curTab = self.curTabIndex,
									inWitchTab = self.curTabIndex
								})
								xyd.WindowManager.get():closeWindow(self.name_)
							end)
						end,
						closeCallback = function ()
						end,
						text = __("GAME_ASSISTANT_TIPS03", xyd.models.gameAssistant:getTotalCostCrystal()),
						btnNoText_ = __("NO"),
						btnYesText_ = __("YES"),
						labelNeverText = __("GAMBLE_REFRESH_NOT_SHOW_TODAY"),
						tipsTextY = tipsTextY,
						tipsHeight = tipsHeight
					})

					return
				else
					self:checkArenaFormation(function ()
						xyd.openWindow("game_assistant_result_window", {
							curTab = self.curTabIndex,
							inWitchTab = self.curTabIndex
						})
						xyd.WindowManager.get():closeWindow(self.name_)
					end)

					return
				end
			end
		end

		if self.model.ifCanDo.dailyQuiz.free then
			local needTips = false

			for j = 1, 3 do
				local ids = xyd.tables.dailyQuizTable:getIDsByType(j)
				local curSweepLev = xyd.tables.dailyQuizTable:getLv(xyd.models.dailyQuiz:getDataByType(j).cur_quiz_id)

				if curSweepLev then
					for i = 1, #ids do
						local id = ids[i]
						local lv = xyd.tables.dailyQuizTable:getLv(id)

						if lv < xyd.models.backpack:getLev() and curSweepLev < lv then
							needTips = true

							break
						end
					end
				end
			end

			if needTips then
				xyd.alertYesNo(__("GAME_ASSISTANT_TIPS01"), callbackExcute, __("YES"), false, nil, , , , , )

				return
			end
		end

		callbackExcute(false)
	end

	for i = 1, 4 do
		UIEventListener.Get(self["tab" .. i]).onClick = function ()
			self:chooseTab(i)
		end
	end
end

function GameAssistantWindow:chooseTab(index)
	if index == 3 and xyd.models.exploreModel:getExploreInfo().lv < self.model.limitLevs[2] and xyd.models.petTraining:getTrainingLevel() < self.model.limitLevs[1] then
		xyd.alertTips(__("GAME_ASSISTANT_TIPS06", self.model.limitLevs[1], self.model.limitLevs[2]))

		return
	end

	if index == 4 and (xyd.models.guild.guildID <= 0 or xyd.models.guild.level < self.model.limitLevs[3]) then
		xyd.alertTips(__("GAME_ASSISTANT_TIPS07", self.model.limitLevs[3]))

		return
	end

	self.curTabIndex = index

	for i = 1, 4 do
		self["content" .. i]:SetActive(i == index)
	end

	self.labelCurLabel.text = tabTitle[index]

	self:updateTab()
	self:updateContent()
	self.scrollView:ResetPosition()
end

function GameAssistantWindow:updateTab()
	local trainLevel = xyd.models.petTraining:getTrainingLevel()

	if trainLevel and trainLevel < self.model.limitLevs[1] and xyd.models.exploreModel:getExploreInfo() and xyd.models.exploreModel:getExploreInfo().lv < self.model.limitLevs[2] then
		xyd.setUISpriteAsync(self.tab3:ComponentByName("bg", typeof(UISprite)), nil, "gameAssistant_btn_yxzs_glzc")
	else
		xyd.setUISpriteAsync(self.tab3:ComponentByName("bg", typeof(UISprite)), nil, "gameAssistant_btn_yxzs_glzc")
	end

	if xyd.models.guild.guildID > 0 and self.model.limitLevs[3] <= xyd.models.guild.level then
		xyd.setUISpriteAsync(self.tab4:ComponentByName("bg", typeof(UISprite)), nil, "gameAssistant_btn_yxzs_glzc")
	else
		xyd.setUISpriteAsync(self.tab4:ComponentByName("bg", typeof(UISprite)), nil, "gameAssistant_btn_yxzs_glzc")
	end

	for i = 1, 4 do
		if self.curTabIndex == i then
			xyd.setUISpriteAsync(self["tab" .. i]:ComponentByName("bg", typeof(UISprite)), nil, "gameAssistant_btn_yxzs_gl")
		else
			xyd.setUISpriteAsync(self["tab" .. i]:ComponentByName("bg", typeof(UISprite)), nil, "gameAssistant_btn_yxzs_glzc")
		end
	end
end

function GameAssistantWindow:updateContent()
	if self.curTabIndex == 1 then
		self:updateMidasPart()
		self:updateCampaignPart()
		self:updateHousePart()
		self:updateDailyQuizPart()
		self:updateSummonPart()
		self:updateFreindPart()
		self:updateArenaPart()
		self:updateTavernPart()
		self:updateGamblePart()
		self:updateMarketPart()
		self:updateDressShowPart()
	elseif self.curTabIndex == 2 then
		self:updateDungeonPart()
		self:updateAcademyAssessmentPart()
	elseif self.curTabIndex == 3 then
		self:updateExplorePart()
		self:updatePetPart()
	elseif self.curTabIndex == 4 then
		self:updateGuildTerritoryPart()
		self:updateGuildDinnerHallPart()
		self:updateGuildGymPart()
	end
end

function GameAssistantWindow:updateMidasPart()
	if not self.initMidasPart then
		self.initMidasPart = true
		self.midasPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT08")
		self.midasPart:ComponentByName("freeMidasGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT09")

		self:initGroup1(self.midasPart:NodeByName("freeMidasGroup/content").gameObject, self.presetData.midas, "free")

		self.midasPart:ComponentByName("paidMidasGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT10")
		self.midasPart:ComponentByName("paidMidasGroup/content/labelDesc", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT11")
		local labelCost = self.midasPart:ComponentByName("paidMidasGroup/content/ResGroup/label", typeof(UILabel))
		local numPos = self.midasPart:NodeByName("paidMidasGroup/content/numPos").gameObject
		local data = self.model:getMidasData()
		local buyTimes = data.buy_time
		local curNum = 0
		curNum = self.presetData.midas.paid
		self.midasSelectNum = SelectNum.new(numPos, "minmax", {})

		self.midasSelectNum:setInfo({
			delForceZero = true,
			minNum = 0,
			notCallback = true,
			maxNum = data.left_canBuy + buyTimes,
			curNum = curNum,
			maxCallback = function ()
				self.presetData.midas.paid = data.left_canBuy + buyTimes
				labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/" .. xyd.getRoughDisplayNumber(self.model:buyMidasTotalCost(self.presetData.midas.paid))
				local msg = messages_pb.log_partner_data_touch_req()
				msg.touch_id = xyd.DaDian.GAMEASSISTANT
				msg.desc = tostring(self.presetData.midas.paid)

				xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
			end,
			callback = function (num)
				self.presetData.midas.paid = num
				labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/" .. xyd.getRoughDisplayNumber(self.model:buyMidasTotalCost(self.presetData.midas.paid))
				local msg = messages_pb.log_partner_data_touch_req()
				msg.touch_id = xyd.DaDian.GAMEASSISTANT
				msg.desc = tostring(self.presetData.midas.paid)

				xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
			end
		})
		self.midasSelectNum:setFontSize(24, 24)
		self.midasSelectNum:setKeyboardPos(0, -180)
		self.midasSelectNum:SetNilAnchor()
		self.midasSelectNum:setSelectBGSize(140, 40)
		self.midasSelectNum:setBtnPos(111)
		self.midasSelectNum:setMaxAndMinBtnPos(190)
		self.midasSelectNum:setMaxNum(data.left_canBuy + buyTimes)
		self.midasSelectNum:setCurNum(curNum)
		self.midasSelectNum:changeCurNum()
	end
end

function GameAssistantWindow:updateCampaignPart()
	if not self.initCampaignPart then
		self.initCampaignPart = true
		self.campaignPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT12")

		self:initGroup1(self.campaignPart:NodeByName("content").gameObject, self.presetData, "campaign")
	end
end

function GameAssistantWindow:updateHousePart()
	if not self.initHousePart then
		self.initHousePart = true
		self.hoursePart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT13")

		self:initGroup1(self.hoursePart:NodeByName("content").gameObject, self.presetData, "house")
	end
end

function GameAssistantWindow:updateDailyQuizPart()
	if not self.initDailyQuizPart then
		self.initDailyQuizPart = true
		self.dailyQuizPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT14")
		self.dailyQuizPart:ComponentByName("freeQuizGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT15")
		self.dailyQuizPart:ComponentByName("paidQuizGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT16")
		local labelCost = self.dailyQuizPart:ComponentByName("paidQuizGroup/content/ResGroup/label", typeof(UILabel))
		self.dailyQuizPart:ComponentByName("paidQuizGroup/content/group1/labelDesc", typeof(UILabel)).text = __("MANA_QUIZ", self:getRomanNum(1))
		self.dailyQuizPart:ComponentByName("paidQuizGroup/content/group2/labelDesc", typeof(UILabel)).text = __("EXP_QUIZ", self:getRomanNum(2))
		self.dailyQuizPart:ComponentByName("paidQuizGroup/content/group3/labelDesc", typeof(UILabel)).text = __("HERO_QUIZ", self:getRomanNum(3))

		for i = 1, 3 do
			local numPos = self.dailyQuizPart:NodeByName("paidQuizGroup/content/group" .. i .. "/numPos").gameObject
			local maxNum = self.model:getMaxCanBuyDailyQuizTime(i)
			local curNum = self.presetData.dailyQuiz.paid[i]
			self["dailyQuizSelectNum" .. i] = SelectNum.new(numPos, "minmax", {})

			self["dailyQuizSelectNum" .. i]:setInfo({
				delForceZero = true,
				minNum = 0,
				maxNum = maxNum,
				curNum = curNum,
				maxCallback = function ()
					self.presetData.dailyQuiz.paid[i] = maxNum
					labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/" .. xyd.getRoughDisplayNumber(self.model:getCostNum(self.presetData.dailyQuiz.paid[1] - xyd.models.dailyQuiz:getDataByType(1).limit_times) + self.model:getCostNum(self.presetData.dailyQuiz.paid[2] - xyd.models.dailyQuiz:getDataByType(1).limit_times) + self.model:getCostNum(self.presetData.dailyQuiz.paid[3] - xyd.models.dailyQuiz:getDataByType(1).limit_times))
				end,
				minCallback = function ()
					self.presetData.dailyQuiz.paid[i] = 0
					labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/" .. 0
				end,
				callback = function (num)
					self.presetData.dailyQuiz.paid[i] = num
					labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/" .. xyd.getRoughDisplayNumber(self.model:getCostNum(self.presetData.dailyQuiz.paid[1] - xyd.models.dailyQuiz:getDataByType(1).limit_times) + self.model:getCostNum(self.presetData.dailyQuiz.paid[2] - xyd.models.dailyQuiz:getDataByType(1).limit_times) + self.model:getCostNum(self.presetData.dailyQuiz.paid[3] - xyd.models.dailyQuiz:getDataByType(1).limit_times))
				end
			})
			self["dailyQuizSelectNum" .. i]:setFontSize(24, 24)
			self["dailyQuizSelectNum" .. i]:setKeyboardPos(0, -180)
			self["dailyQuizSelectNum" .. i]:SetNilAnchor()
			self["dailyQuizSelectNum" .. i]:setSelectBGSize(140, 40)
			self["dailyQuizSelectNum" .. i]:setBtnPos(111)
			self["dailyQuizSelectNum" .. i]:setMaxAndMinBtnPos(190)
			self["dailyQuizSelectNum" .. i]:setMaxNum(maxNum)
			self["dailyQuizSelectNum" .. i]:setCurNum(self.presetData.dailyQuiz.paid[i])
			self["dailyQuizSelectNum" .. i]:changeCurNum()
		end
	end
end

function GameAssistantWindow:updateSummonPart()
	if not self.initSummonPart then
		self.initSummonPart = true
		self.summonPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT17")
		self.summonPart:ComponentByName("paidSummonGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT18")

		self:initGroup2(self.summonPart:NodeByName("paidSummonGroup/content").gameObject, self.presetData.summon, "senior")

		self.summonPart:ComponentByName("freeSummonGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT19")

		self:initGroup2(self.summonPart:NodeByName("freeSummonGroup/content").gameObject, self.presetData.summon, "normal")
	end
end

function GameAssistantWindow:updateFreindPart()
	if not self.initFreindPart then
		self.initFreindPart = true
		self.freindPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT20")

		self:initGroup1(self.freindPart:NodeByName("content").gameObject, self.presetData, "friend")
	end
end

function GameAssistantWindow:updateArenaPart()
	if not self.initArenaPart then
		self.initArenaPart = true
		self.arenaPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT21")
		self.arenaPart:ComponentByName("battleGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT22")
		self.arenaPart:ComponentByName("btnBattleFormation/label", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT61")
		local root = self.arenaPart:NodeByName("battleGroup/content").gameObject
		root:ComponentByName("btnYes/label", typeof(UILabel)).text = __("YES")
		root:ComponentByName("btnNo/label", typeof(UILabel)).text = __("NO")

		if self.presetData.arena then
			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
		else
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
		end

		UIEventListener.Get(root:NodeByName("btnYes").gameObject).onClick = function ()
			if self.presetData.arena == true then
				return
			end

			local arenaBattleFormationInfo = self.presetData.arenaBattleFormationInfo

			if not arenaBattleFormationInfo.partners or #arenaBattleFormationInfo.partners == 0 then
				xyd.alertTips(__("GAME_ASSISTANT_TIPS10"))
				xyd.WindowManager.get():openWindow("battle_formation_window", {
					alpha = 0.01,
					battleType = xyd.BattleType.GAME_ASSISTANT_ARENA,
					pet = xyd.models.arena:getPet(),
					callback = function ()
						arenaBattleFormationInfo = self.presetData.arenaBattleFormationInfo

						if not arenaBattleFormationInfo.partners or #arenaBattleFormationInfo.partners == 0 then
							xyd.models.gameAssistant.presetData.arena = false

							xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
							xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
						else
							xyd.models.gameAssistant.presetData.arena = true

							xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
							xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
						end
					end
				})

				return
			end

			xyd.models.gameAssistant.presetData.arena = true

			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
		end

		UIEventListener.Get(root:NodeByName("btnNo").gameObject).onClick = function ()
			if self.presetData.arena == false then
				return
			end

			self.presetData.arena = false

			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
		end

		UIEventListener.Get(self.arenaPart:NodeByName("btnBattleFormation").gameObject).onClick = function ()
			local arenaBattleFormationInfo = self.presetData.arenaBattleFormationInfo

			xyd.WindowManager.get():openWindow("battle_formation_window", {
				alpha = 0.01,
				battleType = xyd.BattleType.GAME_ASSISTANT_ARENA,
				pet = xyd.models.arena:getPet(),
				callback = function ()
					arenaBattleFormationInfo = self.presetData.arenaBattleFormationInfo

					if not arenaBattleFormationInfo.partners or #arenaBattleFormationInfo.partners == 0 then
						xyd.models.gameAssistant.presetData.arena = false

						xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
						xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
					else
						xyd.models.gameAssistant.presetData.arena = true

						xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
						xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
					end
				end
			})
		end
	end
end

function GameAssistantWindow:updateTavernPart()
	if not self.initTavernPart then
		self.initTavernPart = true
		self.tavernPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT23")
		self.tavernPart:ComponentByName("chooseGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT24")

		for i = 1, 7 do
			UIEventListener.Get(self.tavernPart:NodeByName("chooseGroup/btnContent/star" .. i .. "/btnIcon").gameObject).onClick = function ()
				self.presetData.tavern[i] = not self.presetData.tavern[i]

				self.tavernPart:NodeByName("chooseGroup/btnContent/star" .. i .. "/chosen").gameObject:SetActive(self.presetData.tavern[i])
			end
		end
	end

	for i = 1, 7 do
		self.tavernPart:NodeByName("chooseGroup/btnContent/star" .. i .. "/chosen").gameObject:SetActive(self.presetData.tavern[i])
	end
end

function GameAssistantWindow:updateGamblePart()
	if not self.initGamblePart then
		self.initGamblePart = true
		self.gamblePart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT26")
		self.gamblePart:ComponentByName("content/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT104")

		self:initGroup2(self.gamblePart:NodeByName("content").gameObject, self.presetData, "gamble")

		self.gamblePart:NodeByName("content").gameObject:ComponentByName("btnYes/label", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT105")
		self.gamblePart:NodeByName("content").gameObject:ComponentByName("btnFree/label", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT106")

		if xyd.Global.lang == "en_en" or xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
			self.gamblePart:NodeByName("content").gameObject:ComponentByName("btnYes/label", typeof(UILabel)).width = 100
			self.gamblePart:NodeByName("content").gameObject:ComponentByName("btnYes/label", typeof(UILabel)).height = 60
			self.gamblePart:NodeByName("content").gameObject:ComponentByName("btnYes/label", typeof(UILabel)).pivot = UIWidget.Pivot.Center
			self.gamblePart:NodeByName("content").gameObject:ComponentByName("btnFree/label", typeof(UILabel)).width = 100
			self.gamblePart:NodeByName("content").gameObject:ComponentByName("btnFree/label", typeof(UILabel)).height = 60
			self.gamblePart:NodeByName("content").gameObject:ComponentByName("btnFree/label", typeof(UILabel)).pivot = UIWidget.Pivot.Center
		end
	end
end

function GameAssistantWindow:updateMarketPart()
	if not self.initMarketPart then
		self.marketIcons = {}
		self.initMarketPart = true
		self.marketPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT27")
		self.marketPart:ComponentByName("content/labelNone", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT28")
		self.marketPart:ComponentByName("content/btnChoose/label", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT29")
		local btnMarket = self.marketPart:NodeByName("content/btnChoose").gameObject

		UIEventListener.Get(btnMarket).onClick = function ()
			xyd.openWindow("game_assistant_market_window", {
				shopType = xyd.ShopType.SHOP_BLACK_NEW
			})
		end
	end

	local shopInfo = xyd.models.shop:getShopInfo(xyd.ShopType.SHOP_BLACK_NEW)
	local itemNum = #self.presetData.market
	local itemGroup = self.marketPart:NodeByName("content/itemGroup").gameObject
	local itemGroupGrid = itemGroup:ComponentByName("", typeof(UIGrid))
	local num = math.max(itemNum, #self.marketIcons)

	for i = 1, #self.marketIcons do
		self.marketIcons[i]:SetActive(false)
	end

	local count = 1
	local costManaNum = 0
	local costCrystalNum = 0

	for index, value in pairs(self.presetData.market) do
		index = tonumber(index)
		value = tonumber(value)

		if type(value) == "number" and value > 0 then
			local info = shopInfo.items[index]
			local item = shopInfo.items[index].item
			local cost = shopInfo.items[index].cost
			local itemParams = {
				scale = 0.6944444444444444,
				uiRoot = itemGroup,
				itemID = item[1],
				num = item[2],
				dragScrollView = self.scrollView
			}

			if cost[1] == 1 then
				costManaNum = costManaNum + cost[2]
			end

			if cost[1] == 2 then
				costCrystalNum = costCrystalNum + cost[2]
			end

			if not self.marketIcons[count] then
				self.marketIcons[count] = AdvanceIcon.new(itemParams)
			else
				self.marketIcons[count]:SetActive(true)
				self.marketIcons[count]:setInfo(itemParams)
			end

			count = count + 1
		end
	end

	itemGroupGrid:Reposition()
	self.marketPart:ComponentByName("content/labelNone", typeof(UILabel)):SetActive(count == 1)

	self.marketPart:ComponentByName("content/Res1Group/label", typeof(UILabel)).text = xyd.getRoughDisplayNumber(costManaNum)
	self.marketPart:ComponentByName("content/Res2Group/label", typeof(UILabel)).text = xyd.getRoughDisplayNumber(costCrystalNum)
	local contentBg = self.marketPart:ComponentByName("content", typeof(UISprite))

	if count - 1 > 21 then
		self.marketPart:NodeByName("content/Res1Group").gameObject:Y(-478)
		self.marketPart:NodeByName("content/Res2Group").gameObject:Y(-478)
		self.marketPart:NodeByName("content/btnChoose").gameObject:Y(-534)
		self.marketPart:NodeByName("content/imgLine").gameObject:Y(-441)

		contentBg.height = 575

		self.dressShowPart:Y(-2709)
	else
		self.marketPart:NodeByName("content/Res1Group").gameObject:Y(-325)
		self.marketPart:NodeByName("content/Res2Group").gameObject:Y(-325)
		self.marketPart:NodeByName("content/btnChoose").gameObject:Y(-394)
		self.marketPart:NodeByName("content/imgLine").gameObject:Y(-283)

		contentBg.height = 446

		self.dressShowPart:Y(-2579)
	end
end

function GameAssistantWindow:updateDressShowPart()
	if not self.initDressShowPart then
		self.initDressShowPart = true
		self.dressShowPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT30")

		self:initGroup1(self.dressShowPart:NodeByName("content").gameObject, self.presetData, "dressShow")
	end
end

function GameAssistantWindow:updateDungeonPart()
	if not self.initDungeonPart then
		self.initDungeonPart = true
		self.dungeonPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT33")
		self.dungeonPart:ComponentByName("battleGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT34")
		local root = self.dungeonPart:NodeByName("battleGroup/content").gameObject
		self.presetData.dungeon = false
		root:ComponentByName("btnYes/label", typeof(UILabel)).text = __("YES")
		root:ComponentByName("btnNo/label", typeof(UILabel)).text = __("NO")

		if self.presetData.dungeon then
			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
		else
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
		end

		UIEventListener.Get(root:NodeByName("btnYes").gameObject).onClick = function ()
			if self.presetData.dungeon == true then
				return
			end

			if not self.model:dungeonIsOpen() then
				xyd.alertTips(__("GAME_ASSISTANT_TEXT93"))

				return
			end

			if self.model:dungeonNeedSetPartners() then
				xyd.openWindow("dungeon_select_heros_window")

				return
			end

			self.presetData.dungeon = true

			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
		end

		UIEventListener.Get(root:NodeByName("btnNo").gameObject).onClick = function ()
			if self.presetData.dungeon == false then
				return
			end

			self.presetData.dungeon = false

			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
		end

		self.dungeonPart:ComponentByName("shopGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT100")
		self.dungeonPart:ComponentByName("shopGroup/content/btnShop/label", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT35")

		UIEventListener.Get(self.dungeonPart:NodeByName("shopGroup/content/btnShop").gameObject).onClick = function ()
			if not self.model:dungeonIsOpen() then
				xyd.alertTips(__("GAME_ASSISTANT_TEXT93"))

				return
			end

			if self.model:dungeonNeedSetPartners() then
				xyd.alertTips(__("GAME_ASSISTANT_TEXT97"))

				return
			end

			local shopItems = xyd.models.dungeon:getShopItems()

			if not shopItems or #shopItems == 0 then
				xyd.alertTips(__("GAME_ASSISTANT_TEXT95"))

				return
			end

			xyd.WindowManager.get():openWindow("game_assistant_dungeon_shop_window")
		end
	end
end

function GameAssistantWindow:updateAcademyAssessmentPart()
	local isOpen = xyd.models.academyAssessment:checkFunctionOpen(xyd.FunctionID.ACADEMY_ASSESSMENT, true)
	local startTime = xyd.models.academyAssessment.startTime or 0
	local allTime = xyd.tables.miscTable:getNumber("school_practise_season_duration", "value")
	local showTime = xyd.tables.miscTable:getNumber("school_practise_display_duration", "value")
	local isInShowTime = false

	if xyd.getServerTime() < startTime + allTime - showTime and startTime <= xyd.getServerTime() then
		-- Nothing
	elseif xyd.getServerTime() < startTime + allTime and xyd.getServerTime() >= startTime + allTime - showTime then
		isInShowTime = true
	else
		isOpen = false
	end

	if not isOpen or isInShowTime then
		self.presetData.academyAssessment.fort = 0
	end

	if not self.initAssessmentPart then
		self.initAssessmentPart = true
		self.academyAssessmentPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT36")
		self.academyAssessmentPart:ComponentByName("chooseGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT37")
		self.academyAssessmentPart:ComponentByName("chooseGroup/labelNone", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT70")
		self.academyAssessmentPage = PngNum.new(self.academyAssessmentPart:NodeByName("chooseGroup/BgTimeNum").gameObject)

		for i = 1, 6 do
			UIEventListener.Get(self.academyAssessmentPart:NodeByName("chooseGroup/filterGroup/group" .. i).gameObject).onClick = function ()
				if not isOpen then
					xyd.alertTips(__("GAME_ASSISTANT_TEXT93"))

					return
				end

				if isInShowTime then
					xyd.alertTips(__("SCHOOL_PRACTICE_DISPLAY"))

					return
				end

				if self.presetData.academyAssessment.fort == i then
					self.academyAssessmentPart:NodeByName("chooseGroup/filterGroup/group" .. self.presetData.academyAssessment.fort .. "/chosen").gameObject:SetActive(false)

					self.presetData.academyAssessment.fort = 0
				elseif self.presetData.academyAssessment.fort == 0 then
					self.presetData.academyAssessment.fort = i

					self.academyAssessmentPart:NodeByName("chooseGroup/filterGroup/group" .. self.presetData.academyAssessment.fort .. "/chosen").gameObject:SetActive(true)
				else
					self.academyAssessmentPart:NodeByName("chooseGroup/filterGroup/group" .. self.presetData.academyAssessment.fort .. "/chosen").gameObject:SetActive(false)

					self.presetData.academyAssessment.fort = i

					self.academyAssessmentPart:NodeByName("chooseGroup/filterGroup/group" .. self.presetData.academyAssessment.fort .. "/chosen").gameObject:SetActive(true)
				end

				self:updateAcademyAssessmentPart()
			end
		end

		self.academyAssessmentPart:ComponentByName("freeGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT38")
		local numPos = self.academyAssessmentPart:NodeByName("freeGroup/numPos").gameObject
		local maxNum = 0
		local curNum = 0
		self.presetData.academyAssessment.free = self.model:getMaxChoosefreeSweepAcademyAssessment()
		self.academyAssessmentFreeSelectNum = SelectNum.new(numPos, "minmax", {})

		self.academyAssessmentFreeSelectNum:setInfo({
			delForceZero = true,
			minNum = 0,
			notCallback = true,
			maxNum = maxNum,
			curNum = curNum,
			callback = function (num)
				if not isOpen then
					self.academyAssessmentFreeSelectNum:setCurNum(0)
					xyd.alertTips(__("GAME_ASSISTANT_TEXT93"))

					return
				end

				if isInShowTime then
					self.academyAssessmentFreeSelectNum:setCurNum(0)
					xyd.alertTips(__("SCHOOL_PRACTICE_DISPLAY"))

					return
				end

				self.presetData.academyAssessment.free = num
			end
		})
		self.academyAssessmentFreeSelectNum:setFontSize(24, 24)
		self.academyAssessmentFreeSelectNum:setKeyboardPos(0, 180)
		self.academyAssessmentFreeSelectNum:SetNilAnchor()
		self.academyAssessmentFreeSelectNum:setSelectBGSize(140, 40)
		self.academyAssessmentFreeSelectNum:setBtnPos(111)
		self.academyAssessmentFreeSelectNum:setMaxAndMinBtnPos(190)
		self.academyAssessmentFreeSelectNum:setMaxNum(0)
		self.academyAssessmentFreeSelectNum:setCurNum(0)

		self.academyAssessmentPart:ComponentByName("paidGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT39")
		local labelCost = self.academyAssessmentPart:ComponentByName("paidGroup/ResGroup/label", typeof(UILabel))
		local numPos = self.academyAssessmentPart:NodeByName("paidGroup/numPos").gameObject
		local maxNum = 0
		local curNum = 0
		self.academyAssessmentPaidSelectNum = SelectNum.new(numPos, "minmax", {})

		self.academyAssessmentPaidSelectNum:setInfo({
			delForceZero = true,
			minNum = 0,
			notCallback = true,
			maxNum = maxNum,
			curNum = curNum,
			callback = function (num)
				if not isOpen then
					self.academyAssessmentPaidSelectNum:setCurNum(0)
					xyd.alertTips(__("GAME_ASSISTANT_TEXT93"))

					return
				end

				if isInShowTime then
					self.academyAssessmentFreeSelectNum:setCurNum(0)
					xyd.alertTips(__("SCHOOL_PRACTICE_DISPLAY"))

					return
				end

				self.presetData.academyAssessment.paid = num
				labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/" .. xyd.getRoughDisplayNumber(self.model:getCostNumAcademyAssessment(math.max(0, self.presetData.academyAssessment.paid - xyd.models.academyAssessment:getBuySweepTimes())))
			end
		})
		self.academyAssessmentPaidSelectNum:setFontSize(24, 24)
		self.academyAssessmentPaidSelectNum:setKeyboardPos(0, 180)
		self.academyAssessmentPaidSelectNum:SetNilAnchor()
		self.academyAssessmentPaidSelectNum:setSelectBGSize(140, 40)
		self.academyAssessmentPaidSelectNum:setBtnPos(111)
		self.academyAssessmentPaidSelectNum:setMaxAndMinBtnPos(190)
		self.academyAssessmentPaidSelectNum:setMaxNum(0)
		self.academyAssessmentPaidSelectNum:setCurNum(0)
	end

	self.academyAssessmentPart:NodeByName("chooseGroup/BgTimeNum").gameObject:SetActive(self.presetData.academyAssessment.fort > 0)
	self.academyAssessmentPart:NodeByName("chooseGroup/labelNone").gameObject:SetActive(self.presetData.academyAssessment.fort == 0)

	self.academyAssessmentPart:ComponentByName("paidGroup/ResGroup/label", typeof(UILabel)).text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/0"

	if self.presetData.academyAssessment.fort == 0 then
		self.academyAssessmentFreeSelectNum:setMaxNum(0)
		self.academyAssessmentFreeSelectNum:setCurNum(0)
		self.academyAssessmentPaidSelectNum:setMaxNum(0)
		self.academyAssessmentPaidSelectNum:setCurNum(0)
		self.academyAssessmentPart:NodeByName("chooseGroup/BgTimeNum").gameObject:SetActive(false)
		self.academyAssessmentPart:NodeByName("chooseGroup/labelNone").gameObject:SetActive(true)
	else
		local curStageID = self.model:getCurStageIDIndexAcademyAssessment(self.presetData.academyAssessment.fort)
		local index = 0

		if curStageID == -1 then
			index = #xyd.tables.academyAssessmentNewTable2:getIdsByFort(self.presetData.academyAssessment.fort)
		else
			index = xyd.tables.academyAssessmentNewTable2:getSchoolSort(curStageID) - 1
		end

		print(curStageID)

		if not curStageID or index <= 0 then
			self.presetData.academyAssessment.paid = 0
			self.presetData.academyAssessment.free = 0

			self.academyAssessmentFreeSelectNum:setMaxNum(0)
			self.academyAssessmentFreeSelectNum:setCurNum(0)
			self.academyAssessmentPaidSelectNum:setMaxNum(0)
			self.academyAssessmentPaidSelectNum:setCurNum(0)
			self.academyAssessmentPart:NodeByName("chooseGroup/BgTimeNum").gameObject:SetActive(false)
			self.academyAssessmentPart:NodeByName("chooseGroup/labelNone").gameObject:SetActive(true)
			xyd.alertTips(__("GAME_ASSISTANT_TEXT70"))
		else
			self.academyAssessmentPart:NodeByName("chooseGroup/BgTimeNum").gameObject:SetActive(true)
			self.academyAssessmentPart:NodeByName("chooseGroup/labelNone").gameObject:SetActive(false)

			self.academyAssessmentPart:ComponentByName("paidGroup/ResGroup/label", typeof(UILabel)).text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/" .. xyd.getRoughDisplayNumber(self.model:getCostNumAcademyAssessment(math.max(0, self.presetData.academyAssessment.paid - xyd.models.academyAssessment:getBuySweepTimes())))
			local iconName = numColorMap[math.floor((index - 1) / 10) + 1]

			if index > 80 then
				iconName = numColorMap[math.floor(7.9) + 1]
			end

			self.academyAssessmentPage:setInfo({
				iconName = iconName,
				num = index
			})

			local bgName = "boss_award_bg_" .. tostring(math.ceil(index / 10))

			if index > 80 then
				bgName = "boss_award_bg_8"
			end

			xyd.setUISpriteAsync(self.academyAssessmentPart:ComponentByName("chooseGroup/BgTimeNum", typeof(UISprite)), nil, bgName)
			self.academyAssessmentFreeSelectNum:setMaxNum(self.model:getMaxChoosefreeSweepAcademyAssessment())
			self.academyAssessmentFreeSelectNum:setCurNum(self.presetData.academyAssessment.free)
			self.academyAssessmentPaidSelectNum:setMaxNum(self.model:getMaxBuyTicketAcademyAssessment() + xyd.models.academyAssessment:getBuySweepTimes())
			self.academyAssessmentPaidSelectNum:setCurNum(self.presetData.academyAssessment.paid)
		end
	end

	for i = 1, 6 do
		if self.presetData.academyAssessment.fort == i then
			self.academyAssessmentPart:NodeByName("chooseGroup/filterGroup/group" .. i .. "/chosen").gameObject:SetActive(true)
		else
			self.academyAssessmentPart:NodeByName("chooseGroup/filterGroup/group" .. i .. "/chosen").gameObject:SetActive(false)
		end
	end
end

function GameAssistantWindow:updateExplorePart()
	if not self.initExplorePart then
		self.initExplorePart = true
		self.explorePart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT48")

		self.explorePart:NodeByName("mask").gameObject:SetActive(xyd.models.exploreModel:getExploreInfo().lv < self.model.limitLevs[2])

		self.explorePart:ComponentByName("awardGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT49")
		local root = self.explorePart:NodeByName("awardGroup/content").gameObject
		root:ComponentByName("btnYes/label", typeof(UILabel)).text = __("YES")
		root:ComponentByName("btnNo/label", typeof(UILabel)).text = __("NO")

		if self.presetData.explore.award then
			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
		else
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
		end

		UIEventListener.Get(root:NodeByName("btnYes").gameObject).onClick = function ()
			if self.presetData.explore.award == true then
				return
			end

			if xyd.models.exploreModel:getExploreInfo().lv < self.model.limitLevs[2] then
				xyd.alertTips(__("GAME_ASSISTANT_TIPS05", self.model.limitLevs[2]))

				return
			end

			self.presetData.explore.award = true

			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
		end

		UIEventListener.Get(root:NodeByName("btnNo").gameObject).onClick = function ()
			if self.presetData.explore.award == false then
				return
			end

			self.presetData.explore.award = false

			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
		end

		UIEventListener.Get(self.explorePart:NodeByName("mask").gameObject).onClick = function ()
			xyd.alertTips(__("GAME_ASSISTANT_TIPS05", self.model.limitLevs[2]))
		end

		self.explorePart:ComponentByName("shopGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT50")
		local vipLv = xyd.models.backpack:getVipLev()
		local limitList = xyd.split(xyd.tables.miscTable:getVal("travel_buy_time_limit"), "|", true)
		local limitTimes = limitList[vipLv + 1]
		local buyTimes = self.model:getBuyTimeBreadExplore()
		self.explorePart:ComponentByName("shopGroup/content/labelDesc", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT52", buyTimes, limitTimes)
		local labelCost = self.explorePart:ComponentByName("shopGroup/content/ResGroup/label", typeof(UILabel))
		local numPos = self.explorePart:NodeByName("shopGroup/content/numPos").gameObject
		local maxNum = limitTimes
		local curNum = self.presetData.explore.bread
		self.explorePaidSelectNum = SelectNum.new(numPos, "minmax", {})

		self.explorePaidSelectNum:setInfo({
			delForceZero = true,
			minNum = 0,
			maxNum = maxNum,
			curNum = curNum,
			callback = function (num)
				self.presetData.explore.bread = num
				labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/" .. xyd.getRoughDisplayNumber(self.model:getCostNumExplore(self.presetData.explore.bread - buyTimes))
			end
		})
		self.explorePaidSelectNum:setFontSize(24, 24)
		self.explorePaidSelectNum:setKeyboardPos(0, -180)
		self.explorePaidSelectNum:SetNilAnchor()
		self.explorePaidSelectNum:setSelectBGSize(140, 40)
		self.explorePaidSelectNum:setBtnPos(111)
		self.explorePaidSelectNum:setMaxAndMinBtnPos(190)
		self.explorePaidSelectNum:setMaxNum(maxNum)
		self.explorePaidSelectNum:setCurNum(curNum)
		self.explorePaidSelectNum:changeCurNum()
	end
end

function GameAssistantWindow:updatePetPart()
	if not self.initPetPart then
		self.initPetPart = true
		self.petPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT43")
		local trainLevel = xyd.models.petTraining:getTrainingLevel()

		self.petPart:NodeByName("mask").gameObject:SetActive(xyd.models.petTraining:getTrainingLevel() < self.model.limitLevs[1])

		self.petPart:ComponentByName("awardGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT44")
		self.petPart:ComponentByName("challengeGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT46")

		for i = 1, 2 do
			local root = nil

			if i == 1 then
				root = self.petPart:NodeByName("awardGroup/content").gameObject
			else
				root = self.petPart:NodeByName("challengeGroup/content").gameObject
			end

			local t = self.presetData.pet
			local key = nil

			if i == 1 then
				key = "award"
			else
				key = "challenge"
			end

			root:ComponentByName("btnYes/label", typeof(UILabel)).text = __("YES")
			root:ComponentByName("btnNo/label", typeof(UILabel)).text = __("NO")

			if t[key] then
				xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
			else
				xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
			end

			UIEventListener.Get(root:NodeByName("btnYes").gameObject).onClick = function ()
				if t[key] == true then
					return
				end

				if trainLevel < self.model.limitLevs[1] then
					xyd.alertTips(__("GAME_ASSISTANT_TIPS04", self.model.limitLevs[1]))

					return
				end

				t[key] = true

				xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
				xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
			end

			UIEventListener.Get(root:NodeByName("btnNo").gameObject).onClick = function ()
				if t[key] == false then
					return
				end

				t[key] = false

				xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
				xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
			end
		end

		UIEventListener.Get(self.petPart:NodeByName("mask").gameObject).onClick = function ()
			xyd.alertTips(__("GAME_ASSISTANT_TIPS04", self.model.limitLevs[1]))
		end

		self.petPart:ComponentByName("paidGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT46")
		local labelCost = self.petPart:ComponentByName("paidGroup/content/ResGroup/label", typeof(UILabel))
		labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/" .. "0"
		local buyTime = 0
		local numPos = self.petPart:NodeByName("paidGroup/content/numPos").gameObject
		local maxNum = 0
		local curNum = 0
		local baseTime = xyd.tables.miscTable:getNumber("pet_training_boss_limit", "value")

		if self.model.limitLevs[1] <= trainLevel then
			buyTime = xyd.models.petTraining:getBuyTimeTimes() or 0
			maxNum = self.model:getMaxCanBuyTimePet() + buyTime + baseTime
			curNum = self.presetData.pet.fight
			labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/" .. xyd.getRoughDisplayNumber(self.model:getCostNumPet(curNum - buyTime - baseTime))
		end

		self.petPaidSelectNum = SelectNum.new(numPos, "minmax", {})

		self.petPaidSelectNum:setInfo({
			delForceZero = true,
			minNum = 0,
			notCallback = true,
			maxNum = maxNum,
			curNum = curNum,
			callback = function (num)
				if trainLevel < self.model.limitLevs[1] then
					xyd.alertTips(__("GAME_ASSISTANT_TIPS04", self.model.limitLevs[1]))
					self.petPaidSelectNum:setCurNum(0)

					return
				end

				self.presetData.pet.fight = num
				labelCost.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)) .. "/" .. xyd.getRoughDisplayNumber(self.model:getCostNumPet(self.presetData.pet.fight - (xyd.models.petTraining:getBuyTimeTimes() or 0) - baseTime))
			end
		})
		self.petPaidSelectNum:setFontSize(24, 24)
		self.petPaidSelectNum:setKeyboardPos(0, 180)
		self.petPaidSelectNum:SetNilAnchor()
		self.petPaidSelectNum:setSelectBGSize(140, 40)
		self.petPaidSelectNum:setBtnPos(111)
		self.petPaidSelectNum:setMaxAndMinBtnPos(190)
		self.petPaidSelectNum:setCurNum(curNum)
	end
end

function GameAssistantWindow:updateGuildTerritoryPart()
	if not self.initGuildTerritoryPart then
		self.initGuildTerritoryPart = true
		self.guildTerritoryPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT54")
		self.guildTerritoryPart:ComponentByName("signInGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT55")

		self:initGroup1(self.guildTerritoryPart:NodeByName("signInGroup/content").gameObject, self.presetData.guild, "signIn")
	end
end

function GameAssistantWindow:updateGuildDinnerHallPart()
	if not self.initGuildDinnerHallPart then
		self.initGuildDinnerHallPart = true
		local hallLev = xyd.tables.guildMillTable:getIdByGold(xyd.models.guild.base_info.gold)

		if hallLev < self.model.limitLevs[4] then
			self.presetData.guild.order = false
			self.presetData.guild.level = 0
		end

		self.guildDinnerHallPart:NodeByName("mask").gameObject:SetActive(hallLev < self.model.limitLevs[4])

		self.guildDinnerHallPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT56")
		self.guildDinnerHallPart:ComponentByName("getOrderGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT57")
		self.guildDinnerHallPart:ComponentByName("levelUpOrderGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT58")
		local root = self.guildDinnerHallPart:NodeByName("getOrderGroup/content").gameObject
		local costLabel = self.guildDinnerHallPart:ComponentByName("levelUpOrderGroup/ResGroup/label", typeof(UILabel))
		root:ComponentByName("btnYes/label", typeof(UILabel)).text = __("YES")
		root:ComponentByName("btnNo/label", typeof(UILabel)).text = __("NO")

		if self.presetData.guild.order then
			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
		else
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
		end

		UIEventListener.Get(root:NodeByName("btnYes").gameObject).onClick = function ()
			if self.presetData.guild.order == true then
				return
			end

			if hallLev < self.model.limitLevs[4] then
				xyd.alertTips(__("GAME_ASSISTANT_TIPS08", self.model.limitLevs[4]))

				self.presetData.guild.order = false

				xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
				xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")

				return
			end

			self.presetData.guild.order = true

			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
		end

		UIEventListener.Get(root:NodeByName("btnNo").gameObject).onClick = function ()
			if self.presetData.guild.order == false then
				return
			end

			self.presetData.guild.order = false

			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
		end

		for i = 2, 6 do
			UIEventListener.Get(self.guildDinnerHallPart:NodeByName("levelUpOrderGroup/starGroup/star" .. i .. "/btnIcon").gameObject).onClick = function ()
				if hallLev < self.model.limitLevs[4] then
					xyd.alertTips(__("GAME_ASSISTANT_TIPS08", self.model.limitLevs[4]))

					return
				end

				if self.presetData.guild.level == 0 then
					self.presetData.guild.level = i

					self.guildDinnerHallPart:NodeByName("levelUpOrderGroup/starGroup/star" .. self.presetData.guild.level .. "/chosen").gameObject:SetActive(true)

					costLabel.text = "≤" .. xyd.getRoughDisplayNumber(self.model:getLevelUpOrderCost())
				elseif self.presetData.guild.level == i then
					self.guildDinnerHallPart:NodeByName("levelUpOrderGroup/starGroup/star" .. self.presetData.guild.level .. "/chosen").gameObject:SetActive(false)

					self.presetData.guild.level = 0
					costLabel.text = "0"
				else
					self.guildDinnerHallPart:NodeByName("levelUpOrderGroup/starGroup/star" .. self.presetData.guild.level .. "/chosen").gameObject:SetActive(false)

					self.presetData.guild.level = i

					self.guildDinnerHallPart:NodeByName("levelUpOrderGroup/starGroup/star" .. self.presetData.guild.level .. "/chosen").gameObject:SetActive(true)

					costLabel.text = "≤ " .. xyd.getRoughDisplayNumber(self.model:getLevelUpOrderCost())
				end
			end
		end
	end

	for i = 2, 6 do
		self.guildDinnerHallPart:NodeByName("levelUpOrderGroup/starGroup/star" .. i .. "/chosen").gameObject:SetActive(self.presetData.guild.level == i)
	end

	local costLabel = self.guildDinnerHallPart:ComponentByName("levelUpOrderGroup/ResGroup/label", typeof(UILabel))
	costLabel.text = "≤ " .. xyd.getRoughDisplayNumber(self.model:getLevelUpOrderCost())

	if costLabel.text == "≤ 0" then
		costLabel.text = "0"
	end
end

function GameAssistantWindow:updateGuildGymPart()
	if not self.initGuildGymPart then
		self.initGuildGymPart = true
		local isOpen = false

		if xyd.models.guild.bossID == xyd.GUILD_FINAL_BOSS_ID then
			local time_ = xyd.tables.miscTable:getNumber("guild_final_boss_begin_time", "value")
			local serverTime = xyd.getServerTime()

			if time_ <= serverTime then
				isOpen = true
			end
		end

		self.guildGymPart:NodeByName("mask").gameObject:SetActive(not isOpen)

		self.guildGymPart:ComponentByName("labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT60")
		self.guildGymPart:ComponentByName("btnBattleFormation/label", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT61")
		self.guildGymPart:ComponentByName("bossGroup/labelTiltle", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT62")

		self:initGroup1(self.guildGymPart:NodeByName("bossGroup/content").gameObject, self.presetData.guild, "gym")

		local root = self.guildGymPart:NodeByName("bossGroup/content").gameObject
		root:ComponentByName("btnYes/label", typeof(UILabel)).text = __("YES")
		root:ComponentByName("btnNo/label", typeof(UILabel)).text = __("NO")

		if self.presetData.guild.gym then
			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
		else
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
		end

		UIEventListener.Get(root:NodeByName("btnYes").gameObject).onClick = function ()
			if self.presetData.guild.gym == true then
				return
			end

			local guildBattleFormationInfo = self.presetData.guildBattleFormationInfo

			if not guildBattleFormationInfo.partners or #guildBattleFormationInfo.partners == 0 then
				xyd.alertTips(__("GAME_ASSISTANT_TIPS10"))

				if xyd.models.guild.bossID ~= xyd.GUILD_FINAL_BOSS_ID then
					xyd.alertTips(__("GAME_ASSISTANT_TIPS09"))

					return
				end

				xyd.WindowManager.get():openWindow("battle_formation_window", {
					forceConfirm = 1,
					alpha = 0.7,
					no_close = true,
					mapType = xyd.MapType.GUILD_BOSS,
					battleType = xyd.BattleType.GAME_ASSISTANT_GUILD,
					bossId = xyd.GUILD_FINAL_BOSS_ID,
					callback = function ()
						guildBattleFormationInfo = self.presetData.guildBattleFormationInfo

						if not guildBattleFormationInfo.partners or #guildBattleFormationInfo.partners == 0 then
							xyd.models.gameAssistant.presetData.guild.gym = false

							xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
							xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
						else
							xyd.models.gameAssistant.presetData.guild.gym = true

							xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
							xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
						end
					end
				})

				return
			end

			self.presetData.guild.gym = true

			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
		end

		UIEventListener.Get(root:NodeByName("btnNo").gameObject).onClick = function ()
			if self.presetData.guild.gym == false then
				return
			end

			self.presetData.guild.gym = false

			xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
			xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
		end

		local guildBattleFormationInfo = self.presetData.guildBattleFormationInfo

		UIEventListener.Get(self.guildGymPart:NodeByName("btnBattleFormation").gameObject).onClick = function ()
			if xyd.models.guild.bossID ~= xyd.GUILD_FINAL_BOSS_ID then
				xyd.alertTips(__("GAME_ASSISTANT_TIPS09"))

				return
			end

			xyd.WindowManager.get():openWindow("battle_formation_window", {
				forceConfirm = 1,
				alpha = 0.7,
				no_close = true,
				mapType = xyd.MapType.GUILD_BOSS,
				battleType = xyd.BattleType.GAME_ASSISTANT_GUILD,
				bossId = xyd.GUILD_FINAL_BOSS_ID,
				callback = function ()
					guildBattleFormationInfo = self.presetData.guildBattleFormationInfo

					if not guildBattleFormationInfo.partners or #guildBattleFormationInfo.partners == 0 then
						xyd.models.gameAssistant.presetData.guild.gym = false

						xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
						xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
					else
						xyd.models.gameAssistant.presetData.guild.gym = true

						xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
						xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
					end
				end
			})
		end
	end
end

function GameAssistantWindow:initGroup1(root, table, key)
	root:ComponentByName("btnYes/label", typeof(UILabel)).text = __("YES")
	root:ComponentByName("btnNo/label", typeof(UILabel)).text = __("NO")

	if table[key] then
		xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
	else
		xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
	end

	UIEventListener.Get(root:NodeByName("btnYes").gameObject).onClick = function ()
		if table[key] == true then
			return
		end

		table[key] = true

		xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
		xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
	end

	UIEventListener.Get(root:NodeByName("btnNo").gameObject).onClick = function ()
		if table[key] == false then
			return
		end

		table[key] = false

		xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
		xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
	end
end

function GameAssistantWindow:initGroup2(root, table, key)
	root:ComponentByName("btnYes/label", typeof(UILabel)).text = __("YES")
	root:ComponentByName("btnNo/label", typeof(UILabel)).text = __("NO")
	root:ComponentByName("btnFree/label", typeof(UILabel)).text = __("FREE2")

	if table[key] == 1 then
		xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
	elseif table[key] == 2 then
		xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
	elseif table[key] == 0 then
		xyd.setUISpriteAsync(root:ComponentByName("btnFree", typeof(UISprite)), nil, "setting_up_lan2")
	end

	UIEventListener.Get(root:NodeByName("btnYes").gameObject).onClick = function ()
		if table[key] == 1 then
			return
		end

		table[key] = 1

		xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
		xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
		xyd.setUISpriteAsync(root:ComponentByName("btnFree", typeof(UISprite)), nil, "setting_up_lan1")
	end

	UIEventListener.Get(root:NodeByName("btnNo").gameObject).onClick = function ()
		if table[key] == 2 then
			return
		end

		table[key] = 2

		xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
		xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
		xyd.setUISpriteAsync(root:ComponentByName("btnFree", typeof(UISprite)), nil, "setting_up_lan1")
	end

	UIEventListener.Get(root:NodeByName("btnFree").gameObject).onClick = function ()
		if table[key] == 0 then
			return
		end

		table[key] = 0

		xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
		xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
		xyd.setUISpriteAsync(root:ComponentByName("btnFree", typeof(UISprite)), nil, "setting_up_lan2")
	end
end

function GameAssistantWindow:getRomanNum(index)
	local data = xyd.models.dailyQuiz:getDataByType(index)

	if not data then
		return nil
	end

	local ids = xyd.tables.dailyQuizTable:getIDsByType(index)

	for i = 1, #ids do
		if data.cur_quiz_id == ids[i] then
			return xyd.ROMAN_NUM[i]
		end
	end

	return nil
end

function GameAssistantWindow:onDungeonStart(event)
	local root = self.dungeonPart:NodeByName("battleGroup/content").gameObject
	self.presetData.dungeon = true

	xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
	xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")

	local sweepAwards = event.data.sweep_awards

	if sweepAwards and (sweepAwards.items and #sweepAwards.items > 0 or sweepAwards.drugs and #sweepAwards.drugs > 0) then
		local items = sweepAwards.items

		for _, item in ipairs(sweepAwards.drugs) do
			local id = xyd.tables.dungeonDrugTable:getId(item.item_id)

			table.insert(items, {
				item_id = id,
				item_num = item.item_num
			})
		end

		xyd.alertItems(items)
	end

	xyd.alertTips(__("GAME_ASSISTANT_TEXT94"))
end

function GameAssistantWindow:checkArenaFormation(callbalck)
	if self.model.ifCanDo.arena and self.model:checkIfNeedResetFormation(self.presetData.arenaBattleFormationInfo.partners) then
		xyd.WindowManager.get():closeWindow("gamble_tips_window", function ()
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "game_assistant_arena",
				callback = function ()
					xyd.WindowManager.get():openWindow("battle_formation_window", {
						alpha = 0.01,
						battleType = xyd.BattleType.GAME_ASSISTANT_ARENA,
						pet = xyd.models.arena:getPet(),
						callback = function ()
							local arenaBattleFormationInfo = self.presetData.arenaBattleFormationInfo
							local root = self.arenaPart:NodeByName("battleGroup/content").gameObject

							if not arenaBattleFormationInfo.partners or #arenaBattleFormationInfo.partners == 0 then
								xyd.models.gameAssistant.presetData.arena = false

								xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
								xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
							else
								xyd.models.gameAssistant.presetData.arena = true

								xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
								xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
							end
						end
					})
				end,
				closeCallback = function ()
					self:checkGuildFormation(callbalck)
				end,
				text = __("GAME_ASSISTANT_TEXT107"),
				btnYesText_ = __("YES"),
				btnNoText_ = __("NO")
			})
		end)
	else
		self:checkGuildFormation(callbalck)
	end
end

function GameAssistantWindow:checkGuildFormation(callbalck)
	if self.model.ifCanDo.guild.gym and self.model:checkIfNeedResetFormation(self.presetData.guildBattleFormationInfo.partners) then
		xyd.WindowManager.get():closeWindow("gamble_tips_window", function ()
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "game_assistant_gym",
				callback = function ()
					xyd.WindowManager.get():openWindow("battle_formation_window", {
						forceConfirm = 1,
						alpha = 0.7,
						no_close = true,
						mapType = xyd.MapType.GUILD_BOSS,
						battleType = xyd.BattleType.GAME_ASSISTANT_GUILD,
						bossId = xyd.GUILD_FINAL_BOSS_ID,
						callback = function ()
							local root = self.guildGymPart:NodeByName("bossGroup/content").gameObject
							local guildBattleFormationInfo = self.presetData.guildBattleFormationInfo

							if not guildBattleFormationInfo.partners or #guildBattleFormationInfo.partners == 0 then
								xyd.models.gameAssistant.presetData.guild.gym = false

								xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan1")
								xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan2")
							else
								xyd.models.gameAssistant.presetData.guild.gym = true

								xyd.setUISpriteAsync(root:ComponentByName("btnYes", typeof(UISprite)), nil, "setting_up_lan2")
								xyd.setUISpriteAsync(root:ComponentByName("btnNo", typeof(UISprite)), nil, "setting_up_lan1")
							end
						end
					})
				end,
				closeCallback = function ()
					callbalck()
				end,
				text = __("GAME_ASSISTANT_TEXT108"),
				btnNoText_ = __("NO"),
				btnYesText_ = __("YES")
			})
		end)

		return true
	else
		callbalck()

		return false
	end
end

function GameAssistantWindow:willClose()
	GameAssistantWindow.super.willClose(self)
	xyd.models.gameAssistant:saveData()
end

return GameAssistantWindow
