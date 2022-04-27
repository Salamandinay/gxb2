local ActivityContent = import(".ActivityContent")
local ActivityJackPotMachine = class("ActivityJackPotMachine", ActivityContent)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local JackpotMachineItem = class("JackpotMachineItem", import("app.components.CopyComponent"))
local IconItem = class("IconItem")
local json = require("cjson")
local MACHINE_TYPE = {
	NORMAL = 1,
	SENIOR = 2
}

function ActivityJackPotMachine:ctor(parentGO, params)
	local val = xyd.db.misc:getValue("jackpot_start_position")
	self.positions_ = {}

	if val then
		self.positions_ = json.decode(val)
	end

	if not self.positions_ or not next(self.positions_) then
		self.positions_ = {
			1,
			1,
			1
		}
	end

	self.items = {}

	ActivityJackPotMachine.super.ctor(self, parentGO, params)
end

function ActivityJackPotMachine:getPrefabPath()
	return "Prefabs/Windows/activity/activity_jackpot_machine"
end

function ActivityJackPotMachine:resizeToParent()
	ActivityJackPotMachine.super.resizeToParent(self)
	self:resizePosY(self.btnGiftbag.gameObject, -45, -56)
	self:resizePosY(self.resItemTop.gameObject, -34, -45)
	self:resizePosY(self.jackpotMachine.gameObject, -10, -91)
	self:resizePosY(self.btnHelp.gameObject, -35, -46)
	self:resizePosY(self.btnAward.gameObject, -153, -164)
	self:resizePosY(self.btnPreview.gameObject, -94, -105)
	self:resizePosY(self.guideNode.gameObject, -811, -892)
end

function ActivityJackPotMachine:initUI()
	local privilegeCardGiftID = xyd.tables.miscTable:getNumber("activity_jackpot_gift", "value")
	self.privilegeCardGiftIndex = 1

	for i = 1, #self.activityData.detail.charges do
		if self.activityData.detail.charges[i].table_id == privilegeCardGiftID then
			self.privilegeCardGiftIndex = i

			break
		end
	end

	self.type = (self.activityData.detail.charges[self.privilegeCardGiftIndex].buy_times > 0 or xyd.tables.miscTable:getNumber("activity_jackpot_unlock", "value") <= self.activityData.detail.jackpot_times) and MACHINE_TYPE.SENIOR or MACHINE_TYPE.NORMAL

	if self.activityData.machineType then
		self.type = self.activityData.machineType
		self.activityData.machineType = nil
	end

	self.multipleIndex = 1
	self.multiples = xyd.tables.miscTable:split2Cost("activity_jackpot_energy_bet_num", "value", "|")

	if self.activityData.detail.charges[self.privilegeCardGiftIndex].buy_times > 0 or xyd.tables.miscTable:getNumber("activity_jackpot_unlock", "value") <= self.activityData.detail.jackpot_times then
		xyd.db.misc:setValue({
			value = 1,
			key = "activity_jackpot_tip" .. self.activityData.end_time
		})
	end

	self:getUIComponent()
	ActivityJackPotMachine.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityJackPotMachine:getUIComponent()
	self.jackpotMachine = self.go:ComponentByName("jackpotMachine", typeof(UISprite))
	self.labelMachine = self.jackpotMachine:ComponentByName("labelMachine", typeof(UILabel))
	self.groupItem = self.jackpotMachine:NodeByName("groupItem").gameObject
	self.resItemTop = self.go:ComponentByName("resItemTop", typeof(UISprite))
	self.resItemTopIcon = self.resItemTop:ComponentByName("icon", typeof(UISprite))
	self.resItemTopNum = self.resItemTop:ComponentByName("num", typeof(UILabel))
	self.resItemTopBtn = self.resItemTop:NodeByName("btn").gameObject
	self.resItemBottom = self.jackpotMachine:ComponentByName("resItemBottom", typeof(UISprite))
	self.resItemBottomIcon = self.resItemBottom:ComponentByName("icon", typeof(UISprite))
	self.resItemBottomNum = self.resItemBottom:ComponentByName("num", typeof(UILabel))
	self.resItemBottomBtn = self.resItemBottom:NodeByName("btn").gameObject
	self.btnGiftbag = self.go:NodeByName("btnGiftbag").gameObject
	self.btnGiftbagLabel = self.btnGiftbag:ComponentByName("label", typeof(UILabel))
	self.btnGiftbagRedPoint = self.btnGiftbag:ComponentByName("redPoint", typeof(UISprite))
	self.btnHelp = self.go:NodeByName("btnHelp").gameObject
	self.btnAward = self.go:NodeByName("btnAward").gameObject
	self.btnAwardRedPoint = self.btnAward:ComponentByName("redPoint", typeof(UISprite))
	self.btnPreview = self.go:NodeByName("btnPreview").gameObject
	self.btnNormal = self.jackpotMachine:ComponentByName("btnNormal", typeof(UISprite))
	self.btnNormalText = self.btnNormal:ComponentByName("imgText", typeof(UISprite))
	self.btnSenior = self.jackpotMachine:ComponentByName("btnSenior", typeof(UISprite))
	self.btnSeniorText = self.btnSenior:ComponentByName("imgText", typeof(UISprite))
	self.btnMultiple = self.jackpotMachine:NodeByName("btnMultiple").gameObject
	self.btnMultipleLayout = self.btnMultiple:ComponentByName("layout", typeof(UILayout))
	self.btnMultipleLabel = self.btnMultipleLayout:ComponentByName("label", typeof(UILabel))
	self.btnStart = self.jackpotMachine:ComponentByName("btnStart", typeof(UISprite))
	self.btnStartText = self.btnStart:ComponentByName("imgText", typeof(UISprite))
	self.btnStartRedPoint = self.btnStart:ComponentByName("redPoint", typeof(UISprite))
	self.guideNode = self.go:NodeByName("guideNode").gameObject
	self.mask = self.go:ComponentByName("mask", typeof(UISprite))
	self.jackpot_machine_item = self.go:NodeByName("jackpot_machine_item").gameObject
end

function ActivityJackPotMachine:initUIComponent()
	xyd.setUISpriteAsync(self.btnNormalText, nil, "jackpot_normal_" .. xyd.Global.lang)
	xyd.setUISpriteAsync(self.btnSeniorText, nil, "jackpot_senior_" .. xyd.Global.lang)

	self.resItemBottomNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_ENERGY)
	self.btnGiftbagLabel.text = __("ACTIVITY_JACKPOT_TEXT01")
	self.btnMultipleLabel.text = __("ACTIVITY_JACKPOT_ENERGY_USE") .. self.multiples[self.multipleIndex] * xyd.tables.miscTable:split2Cost("activity_jackpot_draw", "value", "#")[2]

	self.btnMultipleLayout:Reposition()
	self:initMachine(self.type, true)
	self:updateRedPoint()
end

function ActivityJackPotMachine:initMachine(type_, isInit)
	if self.type == type_ and not isInit then
		return
	end

	if self.playSeq then
		self.playSeq:Pause()
		self.playSeq:Kill(false)

		self.playSeq = nil
	end

	self.type = type_
	self.labelMachine.alpha = 1
	self.labelMachine.text = self.type == MACHINE_TYPE.NORMAL and __("ACTIVITY_JACKPOT_MACHINE1") or __("ACTIVITY_JACKPOT_MACHINE2")

	xyd.setUISpriteAsync(self.jackpotMachine, nil, self.type == MACHINE_TYPE.NORMAL and "jackpot_machine" or "jackpot_senior_machine")
	xyd.setUISpriteAsync(self.btnStart, nil, self.type == MACHINE_TYPE.NORMAL and "jackpot_normal_start_btn_up" or "jackpot_senior_start_btn_up")
	xyd.setUISpriteAsync(self.btnStartText, nil, self.type == MACHINE_TYPE.NORMAL and "jackpot_start_" .. xyd.Global.lang or "jackpot_start2_" .. xyd.Global.lang)

	if type_ == MACHINE_TYPE.NORMAL then
		xyd.setUISpriteAsync(self.resItemTopIcon, nil, xyd.tables.itemTable:getIcon(xyd.ItemID.ACTIVITY_JACKPOT_EXCHANGE_ITEM))

		self.resItemTopNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_EXCHANGE_ITEM)
		self.labelMachine.text = __("ACTIVITY_JACKPOT_MACHINE1")

		xyd.setUISpriteAsync(self.btnStart, nil, "jackpot_normal_start_btn_up")
		xyd.setUISpriteAsync(self.btnNormal, nil, "jackpot_normal_btn_down")
		xyd.setUISpriteAsync(self.btnSenior, nil, "jackpot_senior_btn_up")
		self.btnNormalText:Y(15)
		self.btnSeniorText:Y(20)
	else
		xyd.setUISpriteAsync(self.resItemTopIcon, nil, xyd.tables.itemTable:getIcon(xyd.ItemID.ACTIVITY_JACKPOT_SENIOR_EXCHANGE_ITEM))

		self.resItemTopNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_SENIOR_EXCHANGE_ITEM)
		self.labelMachine.text = __("ACTIVITY_JACKPOT_MACHINE2")

		xyd.setUISpriteAsync(self.btnStart, nil, "jackpot_senior_start_btn_up")
		xyd.setUISpriteAsync(self.btnNormal, nil, "jackpot_normal_btn_up")
		xyd.setUISpriteAsync(self.btnSenior, nil, "jackpot_senior_btn_down")
		self.btnNormalText:Y(20)
		self.btnSeniorText:Y(15)
	end

	self:initMachineItems(1, isInit)
end

function ActivityJackPotMachine:initMachineItems(mode, isInit, callback)
	local positions = self.positions_
	local next_positions = xyd.tables.activityJackpotMachineTable:getPositions(mode)
	local animation_type = xyd.tables.activityJackpotMachineTable:getAnimationType(mode)
	self.is_play_ = 3

	for i = 1, 3 do
		local item = self.items[i]

		if not item then
			local go = NGUITools.AddChild(self.groupItem.gameObject, self.jackpot_machine_item)
			item = JackpotMachineItem.new(go, self)
			self.items[i] = item
		end

		local type_ = 1

		if i == 2 and animation_type == 2 then
			type_ = 2
		end

		local itemParams = {
			times = 2,
			start_pos = positions[i],
			type_ = type_,
			end_pos = next_positions[i],
			machineType = self.type
		}

		item:init(itemParams)

		if isInit then
			positions[i] = next_positions[i]
		end
	end

	if isInit then
		self.groupItem:GetComponent(typeof(UILayout)):Reposition()
	else
		xyd.db.misc:setValue({
			key = "jackpot_start_position",
			value = json.encode(positions)
		})

		local function new_callback()
			self.is_play_ = self.is_play_ - 1

			if self.is_play_ == 0 and callback then
				callback()
			end
		end

		local t = self:getTimeInterval()

		for i = 1, 3 do
			self:waitForTime(t, function ()
				self.items[i]:play(new_callback)
			end)

			t = t + self:getTimeInterval()
		end
	end
end

function ActivityJackPotMachine:getTimeInterval()
	local interval = math.random(100) / 100 * 0.2 + 0.2

	return interval
end

function ActivityJackPotMachine:updateRedPoint()
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.JACKPOT_MACHINE, function ()
	end)
	self.btnGiftbagRedPoint:SetActive(false)
	self.btnStartRedPoint:SetActive(false)
	self.btnAwardRedPoint:SetActive(false)

	local freeIDs = xyd.tables.activityJackpotExchangeTable:getIDs()

	for i = 1, #freeIDs do
		if self.activityData.detail.buy_times[freeIDs[i]] < xyd.tables.activityJackpotExchangeTable:getLimit(freeIDs[i]) and not self.activityData.giftbagRed then
			self.btnGiftbagRedPoint:SetActive(true)
		end
	end

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_ENERGY) > 0 then
		self.btnStartRedPoint:SetActive(true)
	end

	local ids = xyd.tables.activityJackpotAwardTable:getIDs()

	for i = 1, #ids do
		if self.activityData.detail.award_ids[i] == 0 and xyd.tables.activityJackpotAwardTable:getComplete(ids[i]) <= tonumber(self.activityData.detail.senior_energy) then
			self.btnAwardRedPoint:SetActive(true)
		end
	end
end

function ActivityJackPotMachine:sendreq()
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.JACKPOT_MACHINE
	msg.params = json.encode({
		award_type = 1,
		jackpot_type = self.type,
		use_energy = self.multiples[self.multipleIndex]
	})

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
	xyd.setUISpriteAsync(self.btnStart, nil, self.type == MACHINE_TYPE.NORMAL and "jackpot_normal_start_btn_down" or "jackpot_senior_start_btn_down")
	self.btnStartText:Y(12)
	self.mask:SetActive(true)
end

function ActivityJackPotMachine:register()
	UIEventListener.Get(self.btnGiftbag.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_jackpot_machine_giftbag_window")
		self.activityData:setGiftbagRed(true)
		self:updateRedPoint()
	end

	UIEventListener.Get(self.btnHelp.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_JACKPOT_HELP_TEXT"
		})
	end

	UIEventListener.Get(self.btnAward.gameObject).onClick = function ()
		local all_info = {}
		local ids = xyd.tables.activityJackpotAwardTable:getIDs()

		for i = 1, #ids do
			local info = {
				id = ids[i],
				max_value = xyd.tables.activityJackpotAwardTable:getComplete(ids[i])
			}
			info.cur_value = math.min(tonumber(self.activityData.detail.senior_energy), info.max_value)
			info.name = __("ACTIVITY_JACKPOT_AWARDS", math.floor(info.max_value))
			info.items = xyd.tables.activityJackpotAwardTable:getAwards(ids[i])
			info.isNew = {}

			for i, item in ipairs(info.items) do
				if xyd.tables.itemTable:getType(item[1]) == xyd.ItemType.SKIN then
					info.isNew[i] = true
				end
			end

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
				msg.activity_id = xyd.ActivityID.JACKPOT_MACHINE
				msg.params = json.encode({
					award_type = 3,
					award_id = info.id
				})

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

				local activityData = xyd.models.activity:getActivity(xyd.ActivityID.JACKPOT_MACHINE)

				activityData:setAwardTableID(info.id)
			end,
			wnd_type = xyd.CommonProgressAwardWindowType.JACKPOT_MACHINE
		})
	end

	UIEventListener.Get(self.btnPreview.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_jackpot_machine_preview_window", {
			type = self.type
		})
	end

	UIEventListener.Get(self.btnNormal.gameObject).onClick = function ()
		self:initMachine(MACHINE_TYPE.NORMAL, true)
	end

	UIEventListener.Get(self.btnSenior.gameObject).onClick = function ()
		self:initMachine(MACHINE_TYPE.SENIOR, true)

		if self.guide then
			self.guide:destroy()

			self.guide = nil
		end
	end

	UIEventListener.Get(self.btnMultiple.gameObject).onClick = function ()
		self.multipleIndex = self.multipleIndex % #self.multiples + 1
		self.btnMultipleLabel.text = __("ACTIVITY_JACKPOT_ENERGY_USE") .. self.multiples[self.multipleIndex] * xyd.tables.miscTable:split2Cost("activity_jackpot_draw", "value", "#")[2]

		self.btnMultipleLayout:Reposition()
	end

	UIEventListener.Get(self.resItemBottomBtn.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.ACTIVITY_JACKPOT_ENERGY
		})
	end

	UIEventListener.Get(self.btnStart.gameObject).onClick = function ()
		if self.type == MACHINE_TYPE.SENIOR and self.activityData.detail.charges[self.privilegeCardGiftIndex].buy_times == 0 and self.activityData.detail.jackpot_times < xyd.tables.miscTable:getNumber("activity_jackpot_unlock", "value") then
			local message = __("ACTIVITY_JACKPOT_TIPS", xyd.tables.miscTable:getNumber("activity_jackpot_unlock", "value") - self.activityData.detail.jackpot_times)

			local function callback()
				xyd.WindowManager.get():openWindow("activity_jackpot_machine_giftbag_window")
				self.activityData:setGiftbagRed(true)
				self:updateRedPoint()
			end

			local confirmText = __("NEW_RECHARGE_TEXT08")

			xyd.alertConfirm(message, callback, confirmText)

			return
		end

		local cost = xyd.tables.miscTable:split2Cost("activity_jackpot_draw", "value", "#")

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] * self.multiples[self.multipleIndex] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		if self.type == MACHINE_TYPE.NORMAL then
			local guideFlag = self.activityData:getSeniorMachineGuideFlag()

			if not guideFlag and (self.activityData.detail.charges[self.privilegeCardGiftIndex].buy_times ~= 0 or xyd.tables.miscTable:getNumber("activity_jackpot_unlock", "value") <= self.activityData.detail.jackpot_times) then
				local params = {
					tipsHeightOffset = 0,
					alertType = xyd.AlertType.YES_NO,
					message = __("ACTIVITY_JACKPOT_WARN"),
					callback = function (flag)
						if flag then
							self.guide = xyd.Spine.new(self.guideNode.gameObject)

							self.guide:setInfo("fx_ui_dianji", function ()
								self.guide:play("texiao01", 0)
							end)
						else
							self:sendreq()
						end
					end,
					confirmText = __("ACTIVITY_JACKPOT_WARN_BUTTON02"),
					cancelText = __("ACTIVITY_JACKPOT_WARN_BUTTON01")
				}

				xyd.WindowManager.get():openWindow("all_stars_pray_alert_window", params)
				self.activityData:setSeniorMachineGuideFlag(true)

				return
			end
		end

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_max_num = math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / (cost[2] * self.multiples[self.multipleIndex])),
			show_max_num = xyd.models.backpack:getItemNumByID(cost[1]),
			select_multiple = cost[2] * self.multiples[self.multipleIndex],
			icon_info = {
				height = 34,
				width = 34,
				name = "icon_" .. cost[1]
			},
			title_text = __("ACTIVITY_JACKPOT_MACHINE_TITLE"),
			explain_text = __("ACTIVITY_JACKPOT_MACHINE_TEXT"),
			sure_callback = function (num)
				self.batchTime = num

				if self.batchTime and self.batchTime > 0 then
					self.batchTime = self.batchTime - 1

					self:sendreq()
				end

				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end
			end
		})
	end

	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.resItemBottomNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_ENERGY)
	end)

	UIEventListener.Get(self.resItemTopBtn.gameObject).onClick = function ()
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY),
			select = xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id ~= xyd.ActivityID.JACKPOT_MACHINE then
			return
		end

		self:updateRedPoint()

		local detail = json.decode(event.data.detail)

		if detail.award_type == 1 then
			self.award = detail.items

			local function callback()
				xyd.itemFloat(self.award)
				self.mask:SetActive(false)
				xyd.setUISpriteAsync(self.btnStart, nil, self.type == MACHINE_TYPE.NORMAL and "jackpot_normal_start_btn_up" or "jackpot_senior_start_btn_up")
				self.btnStartText:Y(16.5)

				self.resItemTopNum.text = self.type == MACHINE_TYPE.NORMAL and xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_EXCHANGE_ITEM) or xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_SENIOR_EXCHANGE_ITEM)
				self.labelMachine.text = xyd.tables.itemTable:getName(self.award[1].item_id) .. "X" .. xyd.getRoughDisplayNumber(self.award[1].item_num)

				if not self.playSeq then
					self.playSeq = self:getSequence(function ()
						self.playSeq:Pause()
						self.playSeq:Kill(false)

						self.playSeq = nil
						self.labelMachine.alpha = 1
						self.labelMachine.text = self.type == MACHINE_TYPE.NORMAL and __("ACTIVITY_JACKPOT_MACHINE1") or __("ACTIVITY_JACKPOT_MACHINE2")
					end)
				end

				local function setter(value)
					self.labelMachine.alpha = value
				end

				self.playSeq:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.02, 2))

				if xyd.tables.miscTable:getNumber("activity_jackpot_unlock", "value") <= self.activityData.detail.jackpot_times and not xyd.db.misc:getValue("activity_jackpot_tip" .. self.activityData.end_time) then
					self.batchTime = 0
					local message = __("ACTIVITY_JACKPOT_TEXT02")

					local function callback()
						self:initMachine(MACHINE_TYPE.SENIOR, true)
					end

					local confirmText = __("ACTIVITY_JACKPOT_UPDATE_BUTTON")

					xyd.alertConfirm(message, callback, confirmText)
					xyd.db.misc:setValue({
						value = 1,
						key = "activity_jackpot_tip" .. self.activityData.end_time
					})
				end

				if self.batchTime and self.batchTime > 0 then
					self.batchTime = self.batchTime - 1

					self:sendreq()
				end
			end

			self:initMachineItems(detail.award_id, false, callback)
		end
	end)
	self:registerEvent(xyd.event.RECHARGE, function (event)
		local giftBagID = event.data.giftbag_id
		local privilegeCardGiftID = xyd.tables.miscTable:getNumber("activity_jackpot_gift", "value")

		if giftBagID == privilegeCardGiftID and not xyd.db.misc:getValue("activity_jackpot_tip" .. self.activityData.end_time) then
			local message = __("ACTIVITY_JACKPOT_TEXT02")

			local function callback()
				self:initMachine(MACHINE_TYPE.SENIOR, true)
			end

			local confirmText = __("ACTIVITY_JACKPOT_UPDATE_BUTTON")

			xyd.alertConfirm(message, callback, confirmText)
			xyd.db.misc:setValue({
				value = 1,
				key = "activity_jackpot_tip" .. self.activityData.end_time
			})
		end
	end)
end

function ActivityJackPotMachine:testPlayer()
	math.randomseed(tostring(xyd.getServerTime() * 1000):reverse():sub(1, 6))

	local ids = xyd.tables.activityJackpotMachineTable:getIDs()
	local award_id = math.random(#ids)

	local function callback()
	end

	self:initMachineItems(award_id, false, callback)
end

function JackpotMachineItem:ctor(go, parent)
	JackpotMachineItem.super.ctor(self, go)

	self.parent = parent
	self.singleHeight = 137

	self:getUIComponent()
end

function JackpotMachineItem:getUIComponent()
	self.scroller = self.go:ComponentByName("scroller", typeof(UIScrollView))
	self.layout = self.scroller:NodeByName("layout").gameObject
	self.icon = self.go:NodeByName("icon").gameObject
	self.listWarpContent_ = self.go:ComponentByName("scroller/layout", typeof(UIWrapContent))
	self.iconWrap_ = FixedWrapContent.new(self.scroller, self.listWarpContent_, self.icon, IconItem, self)
end

function JackpotMachineItem:init(params)
	self.start_pos_ = params.start_pos or 1
	self.end_pos_ = params.end_pos
	self.type_ = params.type_
	self.times_ = params.times
	self.machineType = params.machineType

	if self.type_ == 1 then
		self:constructAnimation1()
	else
		self:constructAnimation2()
	end
end

function JackpotMachineItem:updateImages(imgUrls)
	self:waitForFrame(2, function ()
		self.iconWrap_:setInfos(imgUrls)
		self.scroller:MoveAbsolute(Vector3(0, 169, 0))
		self.scroller:ResetPosition()
	end)
end

function JackpotMachineItem:play(callback)
	local function complete()
		if callback then
			callback()
		end
	end

	local function setter(value)
		if self.scroller and value ~= nil then
			self.scroller.transform.localPosition = Vector3(0, value, 0)
			local co = self.scroller.panel.clipOffset
			co.y = -value
			self.scroller.panel.clipOffset = co
		end
	end

	local speed = self.singleHeight / 0.06
	local startYPos = self.scroller.transform.localPosition.y
	local endYPos = startYPos + self.y2_

	if self.type_ == 1 then
		if not self.playSeq1 then
			self.playSeq1 = self.parent:getSequence()
		end

		if self.firstOne then
			self.playSeq1:Restart()
		end

		self.playSeq1:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), startYPos, endYPos, self.y2_ / speed)):Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), endYPos, endYPos + 10, 10 / speed)):Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), endYPos + 10, endYPos - 6, 0.1)):Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), endYPos - 6, endYPos, 0.13)):AppendCallback(function ()
			complete()
		end)

		self.firstOne = true

		self.playSeq1:SetAutoKill(false)
	elseif self.type_ == 2 then
		if not self.playSeq2 then
			self.playSeq2 = self.parent:getSequence()
		end

		if self.firstTwo then
			self.playSeq2:Restart()
		end

		self.playSeq2:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), startYPos, endYPos, self.y2_ / speed)):Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), endYPos, endYPos + 10, 10 / speed)):Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), endYPos + 10, endYPos - 6, 0.1)):Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), endYPos - 6, endYPos, 0.13)):AppendCallback(function ()
			complete()
		end)

		self.firstTwo = true

		self.playSeq2:SetAutoKill(false)
	end
end

function JackpotMachineItem:constructAnimation1()
	local imgUrls = {}
	local start_r = self:getRightPos(self.start_pos_)
	self.y1_ = 0
	self.y2_ = 0
	self.itemCount = 0

	table.insert(imgUrls, self:getIconSource(self:getLeftPos(self.start_pos_), false))
	table.insert(imgUrls, self:getIconSource(self.start_pos_, false))
	table.insert(imgUrls, self:getIconSource(self:getRightPos(self.start_pos_), false))

	self.y2_ = self.y2_ + 2 * self.singleHeight
	self.itemCount = self.itemCount + 2

	if start_r ~= 3 then
		for i = self:getRightPos(start_r), 3 do
			table.insert(imgUrls, self:getIconSource(i, true))

			self.y2_ = self.y2_ + self.singleHeight
			self.itemCount = self.itemCount + 1
		end
	end

	local ids = xyd.tables.activityJackpotListTable:getIDs()

	for i = 1, self.times_ do
		for j = 1, #ids do
			local id = ids[j]

			table.insert(imgUrls, self:getIconSource(id, true))

			self.y2_ = self.y2_ + self.singleHeight
			self.itemCount = self.itemCount + 1
		end
	end

	local end_l = self:getLeftPos(self.start_pos_)

	if end_l ~= 1 then
		for i = 1, end_l do
			table.insert(imgUrls, self:getIconSource(i, true))

			self.y2_ = self.y2_ + self.singleHeight
			self.itemCount = self.itemCount + 1
		end
	end

	table.insert(imgUrls, self:getIconSource(self:getLeftPos(self.end_pos_), false))

	self.y2_ = self.y2_ + self.singleHeight
	self.itemCount = self.itemCount + 1

	table.insert(imgUrls, self:getIconSource(self.end_pos_, false))
	table.insert(imgUrls, self:getIconSource(self:getRightPos(self.end_pos_), false))
	self:updateImages(imgUrls)
end

function JackpotMachineItem:constructAnimation2()
	local imgUrls = {}
	local start_r = self:getRightPos(self.start_pos_)
	self.y1_ = 0
	self.y2_ = 0
	self.itemCount = 0

	table.insert(imgUrls, self:getIconSource(self:getLeftPos(self.start_pos_), false))
	table.insert(imgUrls, self:getIconSource(self.start_pos_, false))
	table.insert(imgUrls, self:getIconSource(self:getRightPos(self.start_pos_), false))

	self.y2_ = self.y2_ + 2 * self.singleHeight
	self.itemCount = self.itemCount + 2

	if start_r ~= 3 then
		for i = self:getRightPos(start_r), 3 do
			table.insert(imgUrls, self:getIconSource(i, true))

			self.y2_ = self.y2_ + self.singleHeight
			self.itemCount = self.itemCount + 1
		end
	end

	local ids = xyd.tables.activityJackpotListTable:getIDs()

	for i = 1, self.times_ do
		for j = 1, #ids do
			local id = ids[j]

			table.insert(imgUrls, self:getIconSource(id, true))

			self.y2_ = self.y2_ + self.singleHeight
			self.itemCount = self.itemCount + 1
		end
	end

	for j = 1, #ids do
		local id = ids[j]

		table.insert(imgUrls, self:getIconSource(id, false))

		self.y2_ = self.y2_ + self.singleHeight
		self.itemCount = self.itemCount + 1
	end

	self.y1_ = self.y2_ + self.singleHeight * 1.5
	local end_l = self:getLeftPos(self.start_pos_)

	if end_l ~= 1 then
		for i = 1, end_l do
			table.insert(imgUrls, self:getIconSource(i, false))

			self.y2_ = self.y2_ + self.singleHeight
			self.itemCount = self.itemCount + 1
		end
	end

	table.insert(imgUrls, self:getIconSource(self:getLeftPos(self.end_pos_), false))

	self.y2_ = self.y2_ + self.singleHeight
	self.itemCount = self.itemCount + 1

	table.insert(imgUrls, self:getIconSource(self.end_pos_, false))
	table.insert(imgUrls, self:getIconSource(self:getRightPos(self.end_pos_), false))
	self:updateImages(imgUrls)
end

function JackpotMachineItem:getLeftPos(id)
	id = id - 1

	if id < 1 then
		id = 3
	end

	return id
end

function JackpotMachineItem:getRightPos(id)
	id = id + 1

	if id > 3 then
		id = 1
	end

	return id
end

function JackpotMachineItem:getIconSource(id, v)
	local res = nil

	if v then
		if self.machineType == 1 then
			res = xyd.tables.activityJackpotListTable:getUsePicVague(id)
		else
			res = xyd.tables.activityJackpotListTable:getUpdatedUsePicVague(id)
		end
	elseif self.machineType == 1 then
		res = xyd.tables.activityJackpotListTable:getUsePic(id)
	else
		res = xyd.tables.activityJackpotListTable:getUpdatedUsePic(id)
	end

	return {
		img = res
	}
end

function IconItem:ctor(go, parent)
	self.go = go
	self.onImage = self.go:GetComponent(typeof(UISprite))
	self.parent = parent
end

function IconItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	xyd.setUISpriteAsync(self.onImage, nil, info.img)
	self.go:SetActive(true)
end

function IconItem:getGameObject()
	return self.go
end

return ActivityJackPotMachine
