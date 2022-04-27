local ActivitySimulationGacha = class("ActivitySimulationGacha", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function ActivitySimulationGacha:ctor(parentGO, params)
	ActivitySimulationGacha.super.ctor(self, parentGO, params)
	xyd.db.misc:setValue({
		key = "activity_simulation_gacha_view_time",
		value = xyd.getServerTime()
	})
end

function ActivitySimulationGacha:getPrefabPath()
	return "Prefabs/Windows/activity/activity_simulation_gacha"
end

function ActivitySimulationGacha:resizeToParent()
	ActivitySimulationGacha.super.resizeToParent(self)
	self:resizePosY(self.imgBg, 56, 0)
	self:resizePosY(self.imgText, 17, 0)
	self:resizePosY(self.groupTime, -119, -136)
	self:resizePosY(self.btnGiftbag, -45, -67)
	self:resizePosY(self.preview1, -177, -212)
	self:resizePosY(self.preview2, -475, -543)
	self:resizePosY(self.preview3, -615, -683)
	self:resizePosY(self.preview4, -648, -787)
	self:resizePosY(self.imgMb, -720, -865)
	self:resizePosY(self.imgMb2, -728, -873)
	self:resizePosY(self.imgTip, -714, -859)
	self:resizePosY(self.labelTip, -753, -898)
	self:resizePosY(self.btnGacha, -820, -984)
	self:resizePosY(self.btnExchange, -811, -984)
end

function ActivitySimulationGacha:initUI()
	self:getUIComponent()
	ActivitySimulationGacha.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivitySimulationGacha:getUIComponent()
	local go = self.go
	self.imgBg = go:NodeByName("imgBg").gameObject
	self.imgText = go:ComponentByName("imgText", typeof(UISprite))
	self.groupTime = go:NodeByName("groupTime").gameObject
	self.labelTime = self.groupTime:ComponentByName("labelTime", typeof(UILabel))
	self.labelEnd = self.groupTime:ComponentByName("labelEnd", typeof(UILabel))
	self.imgMb = go:ComponentByName("imgMb", typeof(UISprite))
	self.imgMb2 = go:ComponentByName("imgMb2", typeof(UISprite))
	self.imgTip = go:ComponentByName("imgTip", typeof(UISprite))
	self.labelTip = go:ComponentByName("labelTip", typeof(UILabel))
	self.groupPreview = go:NodeByName("groupPreview").gameObject

	for i = 1, 4 do
		self["preview" .. i] = self.groupPreview:NodeByName("partner" .. i).gameObject
		self["preViewBtn" .. i] = self["preview" .. i]:NodeByName("preViewBtn").gameObject
		self["partnerName" .. i] = self["preview" .. i]:ComponentByName("partnerName", typeof(UILabel))
	end

	self.btnGacha = go:NodeByName("btnGacha").gameObject
	self.labelGacha = self.btnGacha:ComponentByName("labelGacha", typeof(UILabel))
	self.btnGachaRed = self.btnGacha:ComponentByName("redPoint", typeof(UISprite))
	self.btnGiftbag = go:NodeByName("btnGiftbag").gameObject
	self.labelGiftbag = self.btnGiftbag:ComponentByName("labelGiftbag", typeof(UILabel))
	self.btnGiftbagRed = self.btnGiftbag:ComponentByName("redPoint", typeof(UISprite))
	self.btnExchange = go:NodeByName("btnExchange").gameObject
	self.labelExchange = self.btnExchange:ComponentByName("labelExchange", typeof(UILabel))
	self.btnExchangeRed = self.btnExchange:ComponentByName("redPoint", typeof(UISprite))
	self.btnHelp = go:NodeByName("btnHelp").gameObject
	self.btnDrop = go:NodeByName("btnDrop").gameObject
end

function ActivitySimulationGacha:initUIComponent()
	xyd.setUISpriteAsync(self.imgText, nil, "activity_simulation_gacha_text_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.imgTip, nil, "activity_simulation_gacha_tip_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.labelTime, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.labelEnd.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.labelEnd.transform:SetSiblingIndex(0)
	end

	self.labelTip.text = __("ACTIVITY_SIMULATION_GACHA_TEXT01", self.activityData.detail.draw_times)
	self.labelGacha.text = __("ACTIVITY_SIMULATION_GACHA_TEXT03")
	self.labelGiftbag.text = __("ACTIVITY_SIMULATION_GACHA_GIFTBAG")
	self.labelExchange.text = __("ACTIVITY_SIMULATION_GACHA_TEXT02")

	if xyd.Global.lang == "en_en" then
		self.labelGacha:Y(-5)
		self.labelGacha:X(0)
	elseif xyd.Global.lang == "fr_fr" then
		self.labelGacha:Y(-5)
		self.labelGacha:X(0)

		self.labelGiftbag.overflowWidth = 134

		self.btnGiftbag:X(283)
		self.btnExchange:X(-280)
	elseif xyd.Global.lang == "de_de" then
		self.labelGacha:Y(-14)
		self.labelGacha:X(0)
	elseif xyd.Global.lang == "ko_kr" then
		self.labelGacha:Y(-14)
		self.labelGacha:X(0)
	elseif xyd.Global.lang == "ja_jp" then
		self.labelGacha:Y(-17)
	elseif xyd.Global.lang == "zh_tw" then
		self.labelGacha:Y(-15)
		self.labelGacha:X(0)
	end

	local partnerIDs = xyd.tables.miscTable:split2Cost("activity_simulation_gacha_10_partner_id", "value", "|")

	for i = 1, 4 do
		self["partnerName" .. i].text = xyd.tables.partnerTable:getName(partnerIDs[i])
	end

	self:updateRedMark()

	local flashBack = tonumber(xyd.db.misc:getValue("activity_simulation_gacha_flashback") or 0)

	if flashBack and flashBack == 1 and self.activityData.detail.tmp_slot and #self.activityData.detail.tmp_slot > 0 then
		local params = {
			showSummonBtn = true,
			type = 9,
			btnSummonRightSprite = "blue_btn70_70",
			progressValue = 0,
			oldBaodiEnergy = 0,
			btnOkCallBack = function ()
				if self.isSendReq then
					return
				end

				xyd.db.misc:setValue({
					value = 0,
					key = "activity_simulation_gacha_flashback"
				})
				xyd.WindowManager.get():closeWindow("summon_result_window")
			end,
			btnSummonLeftCallBack = function ()
				if self.isSendReq then
					return
				end

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA, cjson.encode({
					type = 1
				}))
			end,
			btnSummonRightCallBack = function ()
				if self.isSendReq then
					return
				end

				xyd.WindowManager:get():openWindow("activity_simulation_gacha_record_window")
			end,
			btnOKText = __("ACTIVITY_SIMULATION_GACHA_TEXT32"),
			btnSummonLeftText = __("ACTIVITY_SIMULATION_GACHA_TEXT27"),
			btnSummonRightText = __("ACTIVITY_SIMULATION_GACHA_TEXT04"),
			btnSummonRightLabelColor = Color.New2(4294967295.0),
			btnSummonRightLabelEffectColor = Color.New2(1012112383),
			items = {}
		}

		table.sort(self.activityData.detail.tmp_slot, function (a, b)
			return a % 107 < b % 107
		end)

		for _, partnerID in ipairs(self.activityData.detail.tmp_slot) do
			table.insert(params.items, {
				item_id = partnerID
			})
		end

		local win = xyd.WindowManager.get():getWindow("summon_result_window")

		if win then
			win:playDisappear(function ()
				win:updateWindow(params)
			end, 9)
		else
			xyd.WindowManager.get():openWindow("summon_result_window", params)
		end
	end
end

function ActivitySimulationGacha:updateRedMark()
	self.activityData:updateRedMark()
	self.btnGachaRed:SetActive(false)
	self.btnGiftbagRed:SetActive(false)
	self.btnExchangeRed:SetActive(false)

	local giftbagWindowViewTime = xyd.db.misc:getValue("activity_simulation_gacha_giftbag_view_time")

	if self.activityData.detail.awards[1] == 0 and (not giftbagWindowViewTime or not xyd.isSameDay(tonumber(giftbagWindowViewTime), xyd.getServerTime())) then
		self.btnGiftbagRed:SetActive(true)
	end

	local exchangeWindowViewTime = xyd.db.misc:getValue("activity_simulation_gacha_exchange_view_time")

	if not exchangeWindowViewTime or not xyd.isSameDay(tonumber(exchangeWindowViewTime), xyd.getServerTime()) then
		for i, slot in pairs(self.activityData.detail.slots) do
			if #slot > 0 then
				self.btnExchangeRed:SetActive(true)
			end
		end
	end
end

function ActivitySimulationGacha:register()
	UIEventListener.Get(self.btnHelp.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_SIMULATION_GACHA_HELP1"
		})
	end

	UIEventListener.Get(self.btnDrop.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("newbee_gacha_pool_drob_prob_window", {
			boxId = {
				xyd.tables.miscTable:getNumber("activity_simulation_gacha_10_dropbox1", "value"),
				xyd.tables.miscTable:getNumber("activity_simulation_gacha_10_dropbox2", "value"),
				xyd.tables.miscTable:getNumber("activity_simulation_gacha_10_dropbox3", "value"),
				xyd.tables.miscTable:getNumber("activity_simulation_gacha_10_dropbox4", "value")
			}
		})
	end

	UIEventListener.Get(self.btnGacha.gameObject).onClick = function ()
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA, cjson.encode({
			type = 1
		}))
		xyd.db.misc:setValue({
			value = 1,
			key = "activity_simulation_gacha_flashback"
		})
	end

	UIEventListener.Get(self.btnGiftbag.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_simulation_gacha_giftbag_window")
		xyd.db.misc:setValue({
			key = "activity_simulation_gacha_giftbag_view_time",
			value = xyd.getServerTime()
		})
		self:updateRedMark()
	end

	UIEventListener.Get(self.btnExchange.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_simulation_gacha_exchange_window")
		xyd.db.misc:setValue({
			key = "activity_simulation_gacha_exchange_view_time",
			value = xyd.getServerTime()
		})
		self:updateRedMark()
	end

	for i = 1, 4 do
		UIEventListener.Get(self["preViewBtn" .. i].gameObject).onClick = function ()
			local partnerID = xyd.tables.miscTable:split2Cost("activity_simulation_gacha_10_partner_id", "value", "|")[i]

			xyd.WindowManager.get():openWindow("partner_info", {
				noWays = true,
				table_id = partnerID
			})
		end
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SIMULATION_GACHA then
			return
		end

		local detail = cjson.decode(event.data.detail)

		if detail.type == 1 then
			local params = {
				showSummonBtn = true,
				type = 9,
				btnSummonRightSprite = "blue_btn70_70",
				progressValue = 0,
				oldBaodiEnergy = 0,
				btnOkCallBack = function ()
					if self.isSendReq then
						return
					end

					xyd.db.misc:setValue({
						value = 0,
						key = "activity_simulation_gacha_flashback"
					})
					xyd.WindowManager.get():closeWindow("summon_result_window")
				end,
				btnSummonLeftCallBack = function ()
					if self.isSendReq then
						return
					end

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA, cjson.encode({
						type = 1
					}))
				end,
				btnSummonRightCallBack = function ()
					if self.isSendReq then
						return
					end

					xyd.WindowManager:get():openWindow("activity_simulation_gacha_record_window")
				end,
				btnOKText = __("ACTIVITY_SIMULATION_GACHA_TEXT32"),
				btnSummonLeftText = __("ACTIVITY_SIMULATION_GACHA_TEXT27"),
				btnSummonRightText = __("ACTIVITY_SIMULATION_GACHA_TEXT04"),
				btnSummonRightLabelColor = Color.New2(4294967295.0),
				btnSummonRightLabelEffectColor = Color.New2(1012112383),
				items = {}
			}

			table.sort(self.activityData.detail.tmp_slot, function (a, b)
				return a % 107 < b % 107
			end)

			for _, partnerID in ipairs(self.activityData.detail.tmp_slot) do
				table.insert(params.items, {
					item_id = partnerID
				})
			end

			local win = xyd.WindowManager.get():getWindow("summon_result_window")

			if win then
				win:playDisappear(function ()
					win:updateWindow(params)
				end, 9)
			else
				xyd.WindowManager.get():openWindow("summon_result_window", params)
			end
		end

		self.labelTip.text = __("ACTIVITY_SIMULATION_GACHA_TEXT01", self.activityData.detail.draw_times)

		self:updateRedMark()
	end)
end

return ActivitySimulationGacha
