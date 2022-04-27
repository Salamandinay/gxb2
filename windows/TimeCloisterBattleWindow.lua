local TimeCloisterBattleWindow = class("TimeCloisterBattleWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local StageItem = class("StageItem", import("app.common.ui.FixedWrapContentItem"))
local timeCloister = xyd.models.timeCloisterModel
local battleTable = xyd.tables.timeCloisterBattleTable

function TimeCloisterBattleWindow:ctor(name, params)
	self.cloister = params.cloister

	TimeCloisterBattleWindow.super.ctor(self, name, params)

	local cloisterInfo = timeCloister:getCloisterInfo()
	local afterTwoCloister = self.cloister + 2

	if cloisterInfo[afterTwoCloister] ~= nil and xyd.tables.timeCloisterTable:getLockType(afterTwoCloister) ~= -1 then
		local afterMaxStage = timeCloister:getMaxStage(afterTwoCloister)

		if not afterMaxStage then
			timeCloister:reqCloisterInfo(afterTwoCloister)
		end
	end

	local lastTwoCloister = self.cloister - 2

	if cloisterInfo[lastTwoCloister] ~= nil and xyd.tables.timeCloisterTable:getLockType(lastTwoCloister) ~= -1 then
		local lastMaxStage = timeCloister:getMaxStage(lastTwoCloister)

		if not lastMaxStage then
			timeCloister:reqCloisterInfo(lastTwoCloister)
		end
	end
end

function TimeCloisterBattleWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function TimeCloisterBattleWindow:getUIComponent()
	local groupMain_ = self.window_
	self.helpBtn = groupMain_:NodeByName("helpBtn").gameObject
	self.labelTitle = groupMain_:ComponentByName("labelTitle_", typeof(UILabel))
	self.scrollView = groupMain_:ComponentByName("scroller_", typeof(UIScrollView))
	local itemGroup = self.scrollView:ComponentByName("itemGroup", typeof(UIWrapContent))
	local stageItem = groupMain_:NodeByName("stageItem").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, itemGroup, stageItem, StageItem, self)
	self.resNode = groupMain_:NodeByName("resNode").gameObject
end

function TimeCloisterBattleWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	self.resItem = import("app.components.ResItem").new(self.resNode)

	self.resItem:setInfo({
		tableId = xyd.ItemID.TIME_CLOISTR_BATTLE,
		callback = function ()
			xyd.WindowManager.get():openWindow("item_purchase_window", {
				exchange_id = 8
			})
		end
	})

	self.labelTime = self.resItem:getTimeLabel()
end

function TimeCloisterBattleWindow:layout()
	self:initTopGroup()

	self.labelTitle.text = __("TIME_CLOISTER_TEXT46", xyd.tables.timeCloisterTable:getName(self.cloister))
	self.isInit = false
	local tecInfo = timeCloister:getTechInfoByCloister(self.cloister)

	if timeCloister:getMaxStage(self.cloister) and tecInfo ~= nil then
		self:initContent()
	else
		self.scrollView:SetActive(false)
	end
end

function TimeCloisterBattleWindow:initContent()
	self.isInit = true
	self.maxStage = timeCloister:getMaxStage(self.cloister)
	local ids = battleTable:getIdsByCloister(self.cloister)
	ids = self:dealSortIds(ids)

	self.wrapContent:setInfos(ids, {})
	self:updateCountdown()
end

function TimeCloisterBattleWindow:dealSortIds(ids)
	local ids_yet = {}
	local ids_not = {}

	for i in pairs(ids) do
		if ids[i] < self.maxStage and ids[i] < ids[#ids] then
			table.insert(ids_yet, ids[i])
		else
			table.insert(ids_not, ids[i])
		end
	end

	for i in pairs(ids_yet) do
		table.insert(ids_not, ids_yet[i])
	end

	return ids_not
end

function TimeCloisterBattleWindow:onCheckInitContent()
	local tecInfo = timeCloister:getTechInfoByCloister(self.cloister)

	if timeCloister:getMaxStage(self.cloister) and tecInfo ~= nil then
		self.scrollView:SetActive(true)
		self:initContent()
	end
end

function TimeCloisterBattleWindow:onGetCloisterInfo(event)
	if not self.isInit then
		self:onCheckInitContent()
	end
end

function TimeCloisterBattleWindow:onGetTecInfo(event)
	if not self.isInit then
		self:onCheckInitContent()
	end
end

function TimeCloisterBattleWindow:onGetBattleResult(event)
	local data = event.data

	if data.battle_result and data.battle_result.is_win == 1 then
		if xyd.TimeCloisterMissionType.THREE <= self.cloister and self.maxStage % 11 == 10 then
			self.isShowClearLastRankTips = true
		end

		self.maxStage = data.stage_id
		local items = self.wrapContent:getItems()

		for _, item in pairs(items) do
			if item.data == self.maxStage or item.data == self.maxStage - 1 then
				item:updateInfo()
			end
		end
	end
end

function TimeCloisterBattleWindow:updateCountdown()
	local num, leftTime = timeCloister:getBattleEnergyAndTime()

	self.resItem:setItemNum(num)

	if leftTime > 0 then
		self.resItem:setTimeLabel(true)
		self.labelTime:setInfo({
			duration = leftTime,
			callback = function ()
				self:updateCountdown()
			end
		})
	else
		self.resItem:setTimeLabel(false)
	end
end

function TimeCloisterBattleWindow:onItemChange(event)
	local data = event.data.items

	for i = 1, #data do
		if data[i].item_id == xyd.ItemID.TIME_CLOISTR_BATTLE then
			self:updateCountdown()
		end
	end
end

function TimeCloisterBattleWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_CLOISTER_INFO, handler(self, self.onGetCloisterInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_TEC_INFO, handler(self, self.onGetTecInfo))
	self.eventProxy_:addEventListener(xyd.event.TIME_CLOISTER_FIGHT, handler(self, self.onGetBattleResult))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))

	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "TIME_CLOISTER_HELP04"
		})
	end)
end

function TimeCloisterBattleWindow:showClearLastRankTips()
	if self.isShowClearLastRankTips then
		if xyd.TimeCloisterMissionType.THREE <= self.cloister then
			local lastTipsCloister = self.cloister - 2

			if timeCloister:getMaxStage(lastTipsCloister) % 11 == 0 then
				local isShowClearLastRankTipsLocal = xyd.db.misc:getValue("is_show_clear_last_rank_tips_" .. lastTipsCloister)

				if not isShowClearLastRankTipsLocal then
					xyd.alertConfirm(__("TIME_CLOISTER_TEXT116", xyd.tables.timeCloisterTextTable:getName(lastTipsCloister)), nil, __("SURE"))
					xyd.db.misc:setValue({
						value = "1",
						key = "is_show_clear_last_rank_tips_" .. lastTipsCloister
					})
				end
			end
		end

		self.isShowClearLastRankTips = false
	end
end

function StageItem:initUI()
	local go = self.go
	self.btnPreview = go:NodeByName("btnPreview").gameObject
	self.btnPreview_UISprite = go:ComponentByName("btnPreview", typeof(UISprite))
	self.titleLabel = go:ComponentByName("titleLabel", typeof(UILabel))
	self.ruleLabel = go:ComponentByName("ruleLabel", typeof(UILabel))
	self.itemRoot = go:NodeByName("itemRoot").gameObject
	self.mask = go:NodeByName("mask").gameObject
	self.imgLock = go:NodeByName("imgLock").gameObject
	self.btnChallenge = go:NodeByName("btnChallenge").gameObject
	self.btnChallengeLabel = self.btnChallenge:ComponentByName("label", typeof(UILabel))
	self.costLabel = self.btnChallenge:ComponentByName("costLabel", typeof(UILabel))
	self.imgComplete = go:NodeByName("imgComplete").gameObject
	local groupAtrr = go:NodeByName("groupAttr").gameObject
	self.labelAtrr_1 = groupAtrr:ComponentByName("labelAtk", typeof(UILabel))
	self.labelAtrr_2 = groupAtrr:ComponentByName("labelDef", typeof(UILabel))
	self.labelAtrr_3 = groupAtrr:ComponentByName("labelSpd", typeof(UILabel))
	self.itemIconList = {}

	if xyd.Global.lang == "ko_kr" then
		self.ruleLabel.fontSize = 18
	end

	self.btnChallengeLabel.text = __("FIGHT")
	self.costLabel.text = xyd.split(xyd.tables.miscTable:getVal("time_cloister_fight_energy_cost"), "#", true)[2]
	UIEventListener.Get(self.mask).onClick = handler(self, self.onClickMask)
	UIEventListener.Get(self.btnChallenge).onClick = handler(self, self.goToChallenge)
	UIEventListener.Get(self.btnPreview).onClick = handler(self, self.onClickPreview)
end

function StageItem:updateInfo()
	self.titleLabel.text = battleTable:getName(self.data)

	if xyd.Global.lang == "fr_fr" and battleTable:getNext(self.data) == -1 then
		self.ruleLabel:Y(52)
	else
		self.ruleLabel:Y(44)
	end

	self.ruleLabel.text = battleTable:getDesc(self.data)

	if self.data < self.parent.maxStage then
		self.mask:SetActive(false)
		self.imgLock:SetActive(false)
		self.btnChallenge:SetActive(false)
		self.imgComplete:SetActive(true)
	elseif self.data == self.parent.maxStage then
		local need_tec = battleTable:getTec(self.data)
		local lock = false

		if need_tec[1] then
			local tecInfo = timeCloister:getTechInfoByCloister(self.parent.cloister)
			local group = xyd.tables.timeCloisterTecTable:getGroup(need_tec[1])
			lock = tecInfo[group][need_tec[1]].curLv < need_tec[2]
		end

		self.imgLock:SetActive(lock)
		self.mask:SetActive(lock)
		self.btnChallenge:SetActive(true)
		self.imgComplete:SetActive(false)
	else
		self.btnChallenge:SetActive(true)
		self.imgComplete:SetActive(false)
		self.imgLock:SetActive(true)
		self.mask:SetActive(true)
	end

	local awards = battleTable:getAwards(self.data)
	local len = math.max(#awards, #self.itemIconList)

	for i = 1, len do
		if awards[i] and self.itemIconList[i] then
			self.itemIconList[i]:SetActive(true)
			self.itemIconList[i]:setInfo({
				itemID = awards[i][1],
				num = awards[i][2]
			})
			self.itemIconList[i]:setChoose(self.data < self.parent.maxStage)
		elseif awards[i] and not self.itemIconList[i] then
			self.itemIconList[i] = xyd.getItemIcon({
				scale = 0.5925925925925926,
				uiRoot = self.itemRoot,
				itemID = awards[i][1],
				num = awards[i][2]
			})

			self.itemIconList[i]:setChoose(self.data < self.parent.maxStage)
		elseif not awards[i] and self.itemIconList[i] then
			self.itemIconList[i]:SetActive(false)
		end
	end

	self.itemRoot:GetComponent(typeof(UILayout)):Reposition()

	local base = battleTable:getBase(self.data)

	for i = 1, 3 do
		self["labelAtrr_" .. i].text = ": " .. base[i]
	end

	local next_id = battleTable:getNext(self.data)

	if next_id ~= -1 then
		xyd.setUISpriteAsync(self.btnPreview_UISprite, nil, "attr_exclamation", nil, , )
	else
		xyd.setUISpriteAsync(self.btnPreview_UISprite, nil, "btn_award", nil, , )
	end
end

function StageItem:goToChallenge()
	local function goBattle()
		local cost = xyd.split(xyd.tables.miscTable:getVal("time_cloister_fight_energy_cost"), "#", true)
		local num = timeCloister:getBattleEnergyAndTime()

		if num < cost[2] then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		local fightParams = {
			showSkip = true,
			battleType = xyd.BattleType.TIME_CLOISTER_BATTLE,
			skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("time_cloister_battle_skip_report")) == 1, true, false),
			btnSkipCallback = function (flag)
				local valuedata = xyd.checkCondition(flag, 1, 0)

				xyd.db.misc:setValue({
					key = "time_cloister_battle_skip_report",
					value = valuedata
				})
			end,
			cloister = self.parent.cloister,
			stage = self.data
		}

		if self.parent.cloister == xyd.TimeCloisterMissionType.TWO then
			local techInfo = timeCloister:getTechInfoByCloister(self.parent.cloister)

			if techInfo[3] then
				local partnerTecLev = techInfo[3][xyd.TimeCloisterSpecialTecId.PARTNER_3_TEC].curLv

				if partnerTecLev > 0 then
					fightParams.cloisterExtraPartnerId = "-" .. self.parent.cloister
				end
			end
		end

		xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
	end

	local next_id = battleTable:getNext(self.data)
	local cloisterInfo = timeCloister:getCloisterInfo()
	local afterTwoCloister = self.parent.cloister + 2

	if next_id == -1 and cloisterInfo[afterTwoCloister] ~= nil then
		local afterMaxStage = timeCloister:getMaxStage(afterTwoCloister)

		if afterMaxStage ~= nil and afterMaxStage % 11 == 0 then
			if cloisterInfo[afterTwoCloister].state == xyd.CloisterState.UN_OPEN then
				goBattle()
			elseif cloisterInfo[afterTwoCloister].state == xyd.CloisterState.LOCK then
				goBattle()
			else
				xyd.alertYesNo(__("TIME_CLOISTER_TEXT117"), function (yes_no)
					if yes_no then
						goBattle()
					end
				end)
			end
		else
			goBattle()
		end
	else
		goBattle()
	end
end

function StageItem:onClickMask()
	local text = ""
	local next_stage = battleTable:getNext(self.parent.maxStage)

	print("test:", self.data)

	if next_stage <= self.data then
		text = __("TIME_CLOISTER_TEXT47")
	end

	local need_tec = battleTable:getTec(self.data)

	if need_tec[1] then
		local tecInfo = timeCloister:getTechInfoByCloister(self.parent.cloister)
		local group = xyd.tables.timeCloisterTecTable:getGroup(need_tec[1])

		if tecInfo[group][need_tec[1]].curLv < need_tec[2] then
			if text ~= "" then
				text = text .. "\n" .. __("TIME_CLOISTER_TEXT48")
			else
				text = __("TIME_CLOISTER_TEXT48")
			end
		end
	end

	xyd.showToast(text)
end

function StageItem:onClickPreview()
	local next_id = battleTable:getNext(self.data)

	if next_id ~= -1 then
		xyd.WindowManager.get():openWindow("time_cloister_battle_enemy_detail_window", {
			stageID = self.data,
			monsters = battleTable:getBattleId(self.data),
			cloister = self.parent.cloister
		})
	else
		timeCloister:reqCloisterRankList(self.parent.cloister)
		xyd.WindowManager.get():openWindow("time_cloister_battle_rank_window", {
			cloister = self.parent.cloister
		})
	end
end

return TimeCloisterBattleWindow
