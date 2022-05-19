local StarryAltarWindow = class("StarryAltarWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local StarryAltarTable = xyd.tables.starryAltarTable
local NORMAL_SUMMON_ID = 1
local ACT_SUMMON_ID = 2

function StarryAltarWindow:ctor(name, params)
	StarryAltarWindow.super.ctor(self, name, params)

	self.summonOneId = NORMAL_SUMMON_ID
	self.summonTenId = NORMAL_SUMMON_ID
	self.chooseIndex = 0
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
	local items = {}

	for _, v in ipairs(self.chooseAwards) do
		local item = {
			v,
			1
		}

		table.insert(items, item)
	end

	xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
		mustChoose = true,
		items = items,
		sureCallback = function (index)
			if index == 0 then
				return
			end

			xyd.models.summon:setStarrySummonAward({
				1
			}, {
				index
			})

			self.chooseIndex = index

			self:updateChooseAward()
		end,
		buttomTitleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT02"),
		titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT01"),
		sureBtnText = __("SURE"),
		cancelBtnText = __("CANCEL"),
		tipsText = __(""),
		selectedIndex = self.chooseIndex
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
	self:setSummonBtn(self.summonOneButton, self.costOne, __("STARRY_ALTAR_TEXT01"))
	self:setSummonBtn(self.summonTenButton, self.costTen, __("STARRY_ALTAR_TEXT02"), 10)
	self:initActivityLayout()
end

function StarryAltarWindow:updateChooseAward()
	if self.chooseIndex > 0 then
		local awardId = self.chooseAwards[self.chooseIndex]

		NGUITools.DestroyChildren(self.iconNode.transform)
		xyd.getItemIcon({
			switch = true,
			scale = 0.8611111111111112,
			uiRoot = self.iconNode,
			itemID = awardId,
			switch_func = self.switchAward
		})
	end
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
		local cost = self.actCost

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
	if self.chooseIndex <= 0 then
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
	local actId = StarryAltarTable:getActivity(ACT_SUMMON_ID)
	self.actId = actId
	self.actCost = StarryAltarTable:getCost(ACT_SUMMON_ID)
	self.normalCost = StarryAltarTable:getCost(NORMAL_SUMMON_ID)
	self.costOne = self.normalCost
	self.costTen = self.normalCost
	self.summonOneId = NORMAL_SUMMON_ID
	self.summonTenId = NORMAL_SUMMON_ID
	self.chooseAwards = StarryAltarTable:getOptionalAwards(NORMAL_SUMMON_ID)
	local isActOpen = false

	if actId then
		isActOpen = xyd.models.activity:isOpen(actId)
	end

	self.isActOpen = isActOpen

	if isActOpen then
		self.actData = xyd.models.activity:getActivity(actId)
		local costItemId = self.actCost[1]
		local hasNum = xyd.models.backpack:getItemNumByID(costItemId)

		if hasNum >= 1 then
			self.summonOneId = ACT_SUMMON_ID
			self.costOne = self.actCost
		end

		if hasNum >= 10 then
			self.summonTenId = ACT_SUMMON_ID
			self.costTen = self.actCost
		end
	end
end

function StarryAltarWindow:onGetStarrySummonInfo(event)
	local params = event.data
	local starrySelects = params.selects
	self.chooseIndex = tonumber(starrySelects[NORMAL_SUMMON_ID]) or 0

	self:updateChooseAward()
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
	local effectName = "texiao01"

	if itemsExtra and #itemsExtra > 0 then
		effectName = "texiao02"
	end

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

	self:setSummonBtn(self.summonOneButton, self.costOne, __("STARRY_ALTAR_TEXT01"))
	self:setSummonBtn(self.summonTenButton, self.costTen, __("STARRY_ALTAR_TEXT02"), 10)

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

return StarryAltarWindow
