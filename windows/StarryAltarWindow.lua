local StarryAltarWindow = class("StarryAltarWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local StarryAltarTable = xyd.tables.starryAltarTable
local NORMAL_SUMMON1_ID = 1
local NORMAL_SUMMON2_ID = 3
local ACT_SUMMON1_ID = 4
local ACT_SUMMON2_ID = 5
local ACT_SUMMON1_NEWCOST_ID = 6
local ACT_SUMMON2_NEWCOST_ID = 7

function StarryAltarWindow:ctor(name, params)
	StarryAltarWindow.super.ctor(self, name, params)

	self.summonOneId = NORMAL_SUMMON1_ID
	self.summonTenId = NORMAL_SUMMON1_ID
	self.chooseMode = xyd.db.misc:getValue("starry_altar_mode") or 1
	self.chooseMode = tonumber(self.chooseMode)
end

function StarryAltarWindow:initWindow()
	self:getUIComponent()
	self:checkSummonId()
	StarryAltarWindow.super.initWindow(self)
	self:reSize()
	self:layout()
	self:register()
	xyd.models.summon:reqStarrySummonInfo()
end

function StarryAltarWindow:getUIComponent()
	self.helpButton = self.window_:NodeByName("help_button").gameObject
	self.recordButton = self.window_:NodeByName("record_button").gameObject
	self.probButton = self.window_:NodeByName("prob_button").gameObject
	self.summonOneButton = self.window_:NodeByName("starry_summon_one").gameObject
	self.summonTenButton = self.window_:NodeByName("starry_summon_ten").gameObject
	self.starryAltarTitle = self.window_:ComponentByName("starry_altar_title", typeof(UISprite))
	self.mainAwardGroup = self.window_:NodeByName("main_award_group").gameObject
	self.iconNode = self.window_:NodeByName("main_award_group/icon_node").gameObject
	self.switchButton = self.window_:NodeByName("main_award_group/switch_button").gameObject
	self.mainActGroup = self.window_:NodeByName("main_act_group").gameObject
	self.mainActNode = self.window_:NodeByName("main_act_group/act_icon").gameObject
	self.actDesLabel = self.window_:ComponentByName("main_act_group/act_des_label", typeof(UILabel))
	self.actTimeLabel = self.window_:ComponentByName("main_act_group/act_time_label", typeof(UILabel))
	self.actAwardGrid = self.window_:ComponentByName("main_act_group/act_award_group", typeof(UIGrid))
	self.mask = self.window_:NodeByName("mask").gameObject
	self.centerProb = self.window_:NodeByName("center_prob").gameObject
	self.summonEffectNode = self.window_:NodeByName("summon_effect_node").gameObject
	self.labelTips = self.window_:ComponentByName("tipsGroup/labelTips", typeof(UILabel))
	self.groupBg = self.window_:ComponentByName("groupBg", typeof(UISprite))
end

function StarryAltarWindow:reSize()
end

function StarryAltarWindow:register()
	StarryAltarWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_STARRY_SUMMON_INFO, handler(self, self.onGetStarrySummonInfo))
	self.eventProxy_:addEventListener(xyd.event.STARRY_SUMMON, handler(self, self.onStarrySummon))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.updateActivityLayout))

	UIEventListener.Get(self.helpButton).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "STARRY_ALTAR_HELP_1"
		})
	end)
	UIEventListener.Get(self.recordButton).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("summon_record_window", {
			isStarry = true
		})
	end)
	UIEventListener.Get(self.centerProb).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("starry_rate_detail_window")
	end)
	UIEventListener.Get(self.probButton).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("starry_rate_detail_window")
	end)
	UIEventListener.Get(self.switchButton).onClick = handler(self, function ()
		self:switchAward()
	end)

	xyd.setDarkenBtnBehavior(self.summonOneButton, self, function ()
		self:starrySummon(self.summonOneId, 1)
	end)
	xyd.setDarkenBtnBehavior(self.summonTenButton, self, function ()
		self:starrySummon(self.summonTenId, 10)
	end)

	UIEventListener.Get(self.iconNode).onClick = handler(self, function ()
		self:switchAward()
	end)
	UIEventListener.Get(self.mainActNode).onClick = handler(self, function ()
		xyd.goWay(214, nil, , function ()
			xyd.WindowManager.get():closeWindow(self.name_)
		end)
	end)
end

function StarryAltarWindow:switchAward()
	xyd.WindowManager:get():openWindow("starry_select_award_window", {
		sureCallback = function (mode, index)
			self.chooseIndex = index
			self.chooseMode = mode

			self:checkSummonId()

			if mode == 1 then
				xyd.models.summon:setStarrySummonAward({
					self.summonOneId
				}, {
					index
				})
			end

			self:updateChooseAward()
			self:updateModeContent()
			self:saveData()
		end,
		curMode = self.chooseMode,
		curSelectAwardIndex = self.chooseIndex
	})
end

function StarryAltarWindow:layout()
	xyd.setUISpriteAsync(self.starryAltarTitle, nil, "starry_altar_" .. xyd.Global.lang)
	self:initTop()

	self.summonEffect_ = xyd.Spine.new(self.summonEffectNode)

	self.summonEffect_:setInfo("starry_altar", function ()
		self.summonEffect_:SetLocalPosition(0, 115, 0)
		self.summonEffect_:play("idle", 0)
	end)
	self:initActivityLayout()
end

function StarryAltarWindow:updateChooseAward()
	local params = {
		switch = true,
		scale = 0.8611111111111112,
		uiRoot = self.iconNode,
		switch_func = self.switchAward
	}

	self.groupBg:SetActive(false)

	if self.chooseMode == 1 and self.chooseIndex > 0 then
		local awardId = self.chooseAward
		params.itemID = awardId

		if not self.specialIcon then
			self.specialIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.specialIcon:setInfo(params)
		end

		self.groupBg:SetActive(true)
		xyd.setUISpriteAsync(self.groupBg, nil, "starry_star_img_" .. self.chooseIndex)
	elseif self.chooseMode == 2 then
		local award = self.chooseAward
		params.itemID = award[1]
		params.num = award[2]

		if not self.specialIcon then
			self.specialIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.specialIcon:setInfo(params)
		end
	end
end

function StarryAltarWindow:updateModeContent()
	if self.chooseMode == 0 then
		self.labelTips.text = __("STARRY_ALTAR_TEXT17")
	elseif self.chooseMode == 1 then
		self.labelTips.text = __("STARRY_ALTAR_TEXT18")
	else
		self.labelTips.text = __("STARRY_ALTAR_TEXT19", self.leftTimeToSpecialAward)
	end

	self:setSummonBtn(self.summonOneButton, self.costOne, __("STARRY_ALTAR_TEXT01"))
	self:setSummonBtn(self.summonTenButton, self.costTen, __("STARRY_ALTAR_TEXT02"), 10)
end

function StarryAltarWindow:setSummonBtn(go, cost, text, times)
	times = times or 1
	local labelDisplay = go:ComponentByName("labelItemDisplay", typeof(UILabel))
	local costLabel = go:ComponentByName("labelItemCost", typeof(UILabel))
	local itemIcon = go:ComponentByName("itemIcon", typeof(UISprite))

	if text then
		labelDisplay.text = text

		if xyd.Global.lang == "fr_fr" then
			labelDisplay.fontSize = 28
		elseif xyd.Global.lang == "en_en" then
			labelDisplay.fontSize = 24
		end
	end

	if cost then
		costLabel.text = tostring(cost[2] * times)

		itemIcon:SetActive(true)

		local sp = xyd.tables.itemTable:getSmallIcon(cost[1])

		xyd.setUISprite(itemIcon, nil, sp)

		local pos = costLabel.transform.localPosition

		costLabel:SetLocalPosition(15, pos.y, pos.z)
	end
end

function StarryAltarWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			id = xyd.ItemID.STARRY_ALTAR_COIN
		}
	}

	if self.isActOpen then
		local cost = StarryAltarTable:getCost(ACT_SUMMON1_NEWCOST_ID)

		table.insert(items, {
			id = cost[1]
		})
	end

	self.windowTop:setItem(items)
end

function StarryAltarWindow:updateActivityLayout()
	local missionId = 2
	local limit = xyd.tables.activityStarAltarMissionTable:getLimit(missionId)

	if self.actData.detail.is_completeds[missionId] < limit then
		local value = self.actData.detail.values[missionId]
		local completeValue = xyd.tables.activityStarAltarMissionTable:getCompValue(missionId)
		local actName = xyd.tables.activityTextTable:getTitle(self.actId)
		self.actDesLabel.text = __("STARRY_ALTAR_TEXT03", actName, completeValue - value)
	else
		self.mainActGroup:SetActive(false)
	end
end

function StarryAltarWindow:initActivityLayout()
	if self.isActOpen then
		local missionId = 2
		local limit = xyd.tables.activityStarAltarMissionTable:getLimit(missionId)

		if self.actData.detail.is_completeds[missionId] < limit then
			xyd.models.activity:reqActivityByID(self.actId)

			local CountDown = import("app.components.CountDown")
			self.countTime = CountDown.new(self.actTimeLabel)

			self.mainActGroup:SetActive(true)

			local endTime = self.actData:getEndTime()

			self.countTime:setCountDownTime(endTime - xyd.getServerTime() + 1)

			local awardDatas = xyd.tables.activityStarAltarMissionTable:getAward(missionId)

			for _, data in ipairs(awardDatas) do
				xyd.getItemIcon({
					scale = 0.8333333333333334,
					uiRoot = self.actAwardGrid.gameObject,
					itemID = data[1],
					itemNum = data[2]
				})
			end
		else
			self.mainActGroup:SetActive(false)
		end
	else
		self.mainActGroup:SetActive(false)
	end
end

function StarryAltarWindow:starrySummon(summonId, times)
	if self.chooseMode <= 0 then
		xyd.alertConfirm(__("STARRY_ALTAR_TEXT17"))

		return
	end

	if self.chooseMode == 1 and self.chooseIndex <= 0 then
		xyd.alertConfirm(__("STARRY_ALTAR_TEXT13"))

		return
	end

	local canSummonNum = xyd.models.slot:getCanSummonNum()

	if canSummonNum < times then
		xyd.openWindow("partner_slot_increase_window")

		return false
	end

	local cost = StarryAltarTable:getCost(summonId)

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] * times then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

		return
	end

	xyd.setTouchEnable(self.summonOneButton, false)
	xyd.setTouchEnable(self.summonTenButton, false)
	xyd.models.summon:starrySummon(summonId, times)
end

function StarryAltarWindow:checkSummonId()
	local normalID, actCost1ID, actCost2ID = nil

	if self.chooseMode == 1 then
		normalID = NORMAL_SUMMON1_ID
		actCost1ID = ACT_SUMMON1_ID
		actCost2ID = ACT_SUMMON1_NEWCOST_ID
	elseif self.chooseMode == 2 then
		normalID = NORMAL_SUMMON2_ID
		actCost1ID = ACT_SUMMON2_ID
		actCost2ID = ACT_SUMMON2_NEWCOST_ID
	end

	local actId = StarryAltarTable:getActivity(actCost2ID)
	local isActOpen = false

	if actId then
		isActOpen = xyd.models.activity:isOpen(actId)
		self.actId = actId
	end

	self.isActOpen = isActOpen

	if not isActOpen then
		self.summonOneId = normalID
		self.summonTenId = normalID
		self.mode1ID = NORMAL_SUMMON1_ID
		self.mode2ID = NORMAL_SUMMON2_ID
	else
		self.actData = xyd.models.activity:getActivity(actId)
		local cost2 = StarryAltarTable:getCost(actCost2ID)
		local hasNum = xyd.models.backpack:getItemNumByID(cost2[1])
		self.mode1ID = ACT_SUMMON1_ID
		self.mode2ID = ACT_SUMMON2_ID

		if hasNum >= 1 then
			self.summonOneId = actCost2ID
			self.costOne = StarryAltarTable:getCost(actCost2ID)
		else
			self.summonOneId = actCost1ID
			self.costOne = StarryAltarTable:getCost(actCost1ID)
		end

		if hasNum >= 10 then
			self.summonTenId = actCost2ID
			self.costTen = StarryAltarTable:getCost(actCost2ID)
		else
			self.summonTenId = actCost1ID
			self.costTen = StarryAltarTable:getCost(actCost1ID)
		end
	end

	if not self.chooseIndex or self.chooseIndex == 0 then
		self.chooseIndex = #StarryAltarTable:getOptionalAwards(self.summonOneId)

		xyd.models.summon:setStarrySummonAward({
			self.summonOneId
		}, {
			self.chooseIndex
		})
	end

	if self.chooseMode == 1 then
		if self.chooseIndex and self.chooseIndex > 0 then
			self.chooseAward = StarryAltarTable:getOptionalAwards(self.summonOneId)[self.chooseIndex]
		end
	elseif self.chooseMode == 2 then
		self.chooseAward = StarryAltarTable:getType2Award(self.summonOneId)[2]
	end

	self.costOne = StarryAltarTable:getCost(self.summonOneId)
	self.costTen = StarryAltarTable:getCost(self.summonTenId)
end

function StarryAltarWindow:onGetStarrySummonInfo(event)
	local params = event.data
	local starrySelects = params.selects
	local type_2 = params.type_2 or 0
	self.chooseIndex = tonumber(starrySelects[xyd.checkCondition(self.mode1ID > 1, 2, 1)]) or 0
	self.leftTimeToSpecialAward = StarryAltarTable:getType2Award(self.mode2ID)[1][1] - type_2

	self:checkSummonId()
	self:updateChooseAward()
	self:updateModeContent()
end

function StarryAltarWindow:onStarrySummon(event)
	local data = event.data
	local summonId = data.summon_id
	local summonResult = data.summon_result
	local items = summonResult.items
	local itemsExtra = summonResult.items_extra
	local partners = summonResult.partners
	local index = data.index
	local summonInfo = data.summon_info
	local type_2 = summonInfo.type_2 or 0
	local effectName = "texiao01"

	if itemsExtra and #itemsExtra > 0 then
		effectName = "texiao02"
	end

	self.leftTimeToSpecialAward = StarryAltarTable:getType2Award(self.mode2ID)[1][1] - type_2

	self:checkSummonId()

	local times = 1
	local nextSummonId = self.summonOneId
	local showItems = {}
	local lastTimes = 0

	for i, _ in ipairs(items) do
		local data = {
			item_id = items[i].item_id,
			item_num = items[i].item_num
		}
		lastTimes = lastTimes + 1

		table.insert(showItems, data)
	end

	for i, _ in ipairs(itemsExtra) do
		local data = {
			item_id = itemsExtra[i].item_id,
			item_num = itemsExtra[i].item_num
		}

		table.insert(showItems, data)
	end

	local showPartners = {}

	for i, _ in ipairs(partners) do
		local data = {
			item_num = 1,
			cool = 1,
			item_id = partners[i].table_id
		}

		table.insert(showPartners, partners[i].table_id)
		table.insert(showItems, data)
	end

	if lastTimes == 10 then
		nextSummonId = self.summonTenId
		times = 10
	end

	self:updateChooseAward()
	self:updateModeContent()

	if #partners > 0 then
		xyd.models.activity:reqActivityByID(self.actId)
	end

	if self.summonEffect_ then
		self.mask:SetActive(true)
		self.summonEffect_:play(effectName, 1, 1, function ()
			local function effectCallBack()
				self.summonEffect_:play("idle", 0)
				self.mask:SetActive(false)
				xyd.setTouchEnable(self.summonOneButton, true)
				xyd.setTouchEnable(self.summonTenButton, true)

				local params = {
					wnd_type = 6,
					data = showItems,
					type = nextSummonId,
					buyCallback = function ()
						self:starrySummon(nextSummonId, times)
					end,
					sureCallback = function ()
					end
				}

				xyd.WindowManager.get():openWindow("gamble_rewards_window", params)
			end

			if #partners > 0 then
				xyd.WindowManager.get():openWindow("summon_effect_res_window", {
					partners = showPartners,
					callback = effectCallBack
				})
			else
				effectCallBack()
			end
		end)
	end
end

function StarryAltarWindow:saveData()
	xyd.db.misc:setValue({
		key = "starry_altar_mode",
		value = self.chooseMode
	})
	xyd.db.misc:setValue({
		key = "starry_altar_choose_award",
		value = self.chooseIndex
	})
end

return StarryAltarWindow
