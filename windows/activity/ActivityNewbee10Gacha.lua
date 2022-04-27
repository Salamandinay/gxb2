local ActivityNewbee10Gacha = class("ActivityNewbee10Gacha", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local ActivityState = {
	BUY_STAGE_2 = 2,
	AWARD_STAGE_2 = 7,
	NOT_BUY = 0,
	AWARD_STAGE_1 = 6,
	AWARD_STAGE_4 = 9,
	BUY_STAGE_1 = 1,
	AWARD_STAGE_3 = 8,
	BUY_STAGE_3 = 3,
	BUY_STAGE_4 = 4,
	AWARD_STAGE_5 = 10,
	BUY_STAGE_5 = 5
}
local GiftBagTextTable = xyd.tables.giftBagTextTable

function ActivityNewbee10Gacha:ctor(parentGO, params, parent)
	ActivityNewbee10Gacha.super.ctor(self, parentGO, params, parent)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEWBEE_10GACHA, function ()
		xyd.db.misc:setValue({
			key = "newbee_10gacha_open_window_time",
			value = xyd.getServerTime()
		})
		xyd.db.misc:setValue({
			value = 0,
			key = "newbee_10gacha_get_new"
		})
	end)
end

function ActivityNewbee10Gacha:getPrefabPath()
	return "Prefabs/Windows/activity/activity_newbee_10gacha"
end

function ActivityNewbee10Gacha:initUI()
	ActivityNewbee10Gacha.super.initUI(self)
	self:getUIComponent()
	self:updatePos()
	self:checkNowStage()
	self:layout()
	self:updateBtnState()
	self:register()
end

function ActivityNewbee10Gacha:updatePos()
	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	if p_height >= 1047 then
		p_height = 1047
	end

	self.tipsImg_.transform:Y(-637 - (p_height - 869) * 121 / 178)
	self.bgImg2_.transform:Y(-394 - (p_height - 869) * 43 / 178)
end

function ActivityNewbee10Gacha:getUIComponent()
	local goTrans = self.go.transform
	self.titleImg_ = goTrans:ComponentByName("titleImg", typeof(UISprite))
	self.tipsImg_ = goTrans:ComponentByName("tipsImg", typeof(UISprite))
	self.timeGroup = goTrans:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = goTrans:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel_ = goTrans:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.bgImg2_ = goTrans:NodeByName("bgImg2")
	self.labelVipExp_ = goTrans:ComponentByName("bottomGroup/labelVipExp", typeof(UILabel))

	for i = 1, 4 do
		self["preViewBtn" .. i] = goTrans:NodeByName("previewGroup/preViewGroup" .. i .. "/preViewBtn").gameObject
		self["prePartnerName" .. i] = goTrans:ComponentByName("previewGroup/preViewGroup" .. i .. "/labelName", typeof(UILabel))
	end

	self.summonBtn = goTrans:NodeByName("bottomGroup/summonBtn").gameObject
	self.summonBtnTips = self.summonBtn:ComponentByName("labelTips", typeof(UILabel))
	self.summonlabelNum = self.summonBtn:ComponentByName("labelNum", typeof(UILabel))
	self.preBtn = goTrans:NodeByName("preBtn").gameObject
	self.helpBtn = goTrans:NodeByName("helpBtn").gameObject
end

function ActivityNewbee10Gacha:layout()
	xyd.setUISpriteAsync(self.titleImg_, nil, "newbee_10gacha_logo_" .. xyd.Global.lang, nil, , true)

	if xyd.Global.lang == "de_de" then
		self.endLabel_.fontSize = 16
		self.timeLabel_.fontSize = 16
	end

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
		self.timeGroup:Reposition()
	end

	self.endLabel_.text = __("END")
	local endTime = self.activityData:getEndTime()
	local timeCount = CountDown.new(self.timeLabel_)

	timeCount:setInfo({
		duration = endTime - xyd:getServerTime()
	})

	local partnerIds = xyd.tables.miscTable:split2num("newbee_10gacha_partner_jump", "value", "|")

	for i = 1, 4 do
		self["prePartnerName" .. i].text = xyd.tables.partnerTable:getName(partnerIds[i])
	end

	self.summonBtnTips.text = __("SUMMON_X_TIME2", 10)
end

function ActivityNewbee10Gacha:updateBtnState()
	local stage = 1

	if self.stage_ == ActivityState.NOT_BUY or self.stage_ == ActivityState.BUY_STAGE_1 then
		stage = 1
	elseif self.stage_ == ActivityState.AWARD_STAGE_1 or self.stage_ == ActivityState.BUY_STAGE_2 then
		stage = 2
	elseif self.stage_ == ActivityState.AWARD_STAGE_2 or self.stage_ == ActivityState.BUY_STAGE_3 then
		stage = 3
	elseif self.stage_ == ActivityState.AWARD_STAGE_3 or self.stage_ == ActivityState.BUY_STAGE_4 then
		stage = 4
	elseif self.stage_ == ActivityState.AWARD_STAGE_4 or self.stage_ == ActivityState.BUY_STAGE_5 or self.stage_ == ActivityState.AWARD_STAGE_5 then
		stage = 5
	end

	xyd.setUISpriteAsync(self.tipsImg_, nil, "newbee_10gacha_tips_" .. stage .. "_" .. xyd.Global.lang)

	self.giftBagIds = xyd.tables.activityTable:getGiftBag(self.id)
	self.giftBagId = self.giftBagIds[stage]

	if self.stage_ == ActivityState.BUY_STAGE_1 or self.stage_ == ActivityState.BUY_STAGE_2 or self.stage_ == ActivityState.BUY_STAGE_3 or self.stage_ == ActivityState.BUY_STAGE_4 or self.stage_ == ActivityState.BUY_STAGE_5 then
		self.labelVipExp_.gameObject:SetActive(false)

		self.summonlabelNum.text = __("ALREADY_BUY")
	elseif self.stage_ == ActivityState.AWARD_STAGE_5 then
		self.labelVipExp_.gameObject:SetActive(false)

		self.summonlabelNum.text = __("ALREADY_BUY")

		xyd.setEnabled(self.summonBtn, false)
	else
		self.labelVipExp_.gameObject:SetActive(true)

		self.labelVipExp_.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagId) .. " VIP EXP"
		self.summonlabelNum.text = GiftBagTextTable:getCurrency(self.giftBagId) .. " " .. GiftBagTextTable:getCharge(self.giftBagId)
	end
end

function ActivityNewbee10Gacha:register()
	for i = 1, 4 do
		UIEventListener.Get(self["preViewBtn" .. i]).onClick = function ()
			self:onclickPreViewBtn(i)
		end
	end

	UIEventListener.Get(self.summonBtn).onClick = handler(self, self.onClickBtnSummon)
	UIEventListener.Get(self.preBtn).onClick = handler(self, self.onClickPreBtn)

	UIEventListener.Get(self.helpBtn).onClick = function ()
		local stage = 1

		if self.stage_ == ActivityState.NOT_BUY or self.stage_ == ActivityState.BUY_STAGE_1 then
			stage = 1
		elseif self.stage_ == ActivityState.AWARD_STAGE_1 or self.stage_ == ActivityState.BUY_STAGE_2 then
			stage = 2
		elseif self.stage_ == ActivityState.AWARD_STAGE_2 or self.stage_ == ActivityState.BUY_STAGE_3 then
			stage = 3
		elseif self.stage_ == ActivityState.AWARD_STAGE_3 or self.stage_ == ActivityState.BUY_STAGE_4 then
			stage = 4
		elseif self.stage_ == ActivityState.AWARD_STAGE_4 or self.stage_ == ActivityState.BUY_STAGE_5 or self.stage_ == ActivityState.AWARD_STAGE_5 then
			stage = 5
		end

		xyd.WindowManager.get():openWindow("help_window", {
			key = "NEWBEE_10GACHA_HELP0" .. stage
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function ActivityNewbee10Gacha:onclickPreViewBtn(index)
	local partnersList = xyd.tables.miscTable:split2num("newbee_10gacha_partner_jump", "value", "|")
	local tableID = nil

	if #partnersList > 0 then
		tableID = partnersList[index]
	end

	local collection = {
		{
			table_id = tableID
		}
	}
	local params = {
		partners = collection,
		table_id = tableID
	}

	xyd.WindowManager.get():openWindow("guide_detail_window", params)
end

function ActivityNewbee10Gacha:onAward(event)
	local partners = json.decode(event.data.detail).partners
	local items = {}

	xyd.models.slot:addPartners(partners)

	for i, partner in ipairs(partners) do
		local item_id = partner.table_id
		local cool = 0

		if xyd.tables.partnerTable:getStar(item_id) >= 5 or xyd.tables.partnerTable:getStar(item_id) == 1 then
			cool = 1
		end

		table.insert(items, {
			item_num = 1,
			item_id = item_id,
			cool = cool
		})
	end

	self.activityData.detail.info.awards[self.stage_] = 1

	local function callback()
		xyd.WindowManager.get():closeWindow("summon_res_window")
		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			wnd_type = 2,
			data = items,
			callback = function ()
				xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEWBEE_10GACHA, function ()
					xyd.db.misc:setValue({
						value = 0,
						key = "newbee_10gacha_get_new"
					})
				end)
				self:checkNowStage()

				if self.stage_ ~= ActivityState.AWARD_STAGE_5 then
					xyd.alertConfirm(__("NEWBEE_10GACHA_TIPS"), function ()
						self:updateBtnState()
					end, __("FOR_SURE"))
				else
					self:updateBtnState()
				end
			end
		})
	end

	xyd.WindowManager.get():openWindow("summon_res_window", {}, function (win)
		if win then
			win:playEffect(partners, 7, callback, false)
		else
			callback()
		end
	end)
end

function ActivityNewbee10Gacha:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	self:checkNowStage()
	self:updateBtnState()
end

function ActivityNewbee10Gacha:checkNowStage()
	local awardData = self.activityData.detail.info.awards
	self.stage_ = ActivityState.NOT_BUY

	for i = 1, 5 do
		if awardData[i] and awardData[i] == 0 then
			self.stage_ = i

			break
		elseif awardData[i] and awardData[i] == 1 and not awardData[i + 1] then
			self.stage_ = i + 5
		end
	end
end

function ActivityNewbee10Gacha:onClickBtnSummon()
	local stage = 1

	if self.stage_ == ActivityState.NOT_BUY or self.stage_ == ActivityState.BUY_STAGE_1 then
		stage = 1
	elseif self.stage_ == ActivityState.AWARD_STAGE_1 or self.stage_ == ActivityState.BUY_STAGE_2 then
		stage = 2
	elseif self.stage_ == ActivityState.AWARD_STAGE_2 or self.stage_ == ActivityState.BUY_STAGE_3 then
		stage = 3
	elseif self.stage_ == ActivityState.AWARD_STAGE_3 or self.stage_ == ActivityState.BUY_STAGE_4 then
		stage = 4
	elseif self.stage_ == ActivityState.AWARD_STAGE_4 or self.stage_ == ActivityState.BUY_STAGE_5 or self.stage_ == ActivityState.AWARD_STAGE_5 then
		stage = 5
	end

	if self.stage_ > 0 and self.stage_ <= ActivityState.BUY_STAGE_5 then
		local canSummonNum = xyd.models.slot:getCanSummonNum()
		self.collectionBefore_ = xyd.models.slot:getCollectionCopy()

		if self:isPartnerFullAndBuyLimit(10, canSummonNum) then
			return
		end

		if canSummonNum < 10 then
			xyd.alertConfirm(__("PARTNER_LIST_FULL"), function ()
				xyd.WindowManager.get():openWindow("slot_window", {}, function ()
					xyd.WindowManager.get():closeAllWindows({
						slot_window = true,
						main_window = true,
						loading_window = true,
						guide_window = true
					})
				end)
			end, __("BUY"))

			return false
		end

		local params = json.encode({
			index = tonumber(self.stage_)
		})

		xyd.db.misc:setValue({
			value = 1,
			key = "newbee_10gacha_get_new"
		})
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.NEWBEE_10GACHA, params)
	elseif self.stage_ == ActivityState.NOT_BUY then
		local giftBagIds = xyd.tables.activityTable:getGiftBag(self.id)

		xyd.SdkManager.get():showPayment(giftBagIds[1])
	elseif self.stage_ == ActivityState.AWARD_STAGE_1 or self.stage_ == ActivityState.AWARD_STAGE_2 or self.stage_ == ActivityState.AWARD_STAGE_3 or self.stage_ == ActivityState.AWARD_STAGE_4 then
		local giftBagIds = xyd.tables.activityTable:getGiftBag(self.id)

		xyd.SdkManager.get():showPayment(giftBagIds[stage])
	end
end

function ActivityNewbee10Gacha:isPartnerFullAndBuyLimit(num, canSummonNum)
	local buyAlreadyTime = xyd.models.slot:getBuySlotTimes()
	local buyLimitTime = xyd.tables.miscTable:getNumber("herobag_buy_limit", "value")

	if canSummonNum < num and buyLimitTime <= buyAlreadyTime then
		xyd.alertConfirm(__("PARTNER_LIST_FULL_WITHOUT_BUY_LIMIT"), function ()
			xyd.openWindow("altar_window", {}, function ()
				xyd.WindowManager.get():closeAllWindows({
					altar_window = true,
					main_window = true,
					loading_window = true,
					guide_window = true
				})
			end)
		end, __("GO_TO_TRANSFER"))

		return true
	end

	return false
end

function ActivityNewbee10Gacha:onClickPreBtn()
	local stage = 1

	if self.stage_ == ActivityState.NOT_BUY or self.stage_ == ActivityState.BUY_STAGE_1 then
		stage = 1
	elseif self.stage_ == ActivityState.AWARD_STAGE_1 or self.stage_ == ActivityState.BUY_STAGE_2 then
		stage = 2
	elseif self.stage_ == ActivityState.AWARD_STAGE_2 or self.stage_ == ActivityState.BUY_STAGE_3 then
		stage = 3
	elseif self.stage_ == ActivityState.AWARD_STAGE_3 or self.stage_ == ActivityState.BUY_STAGE_4 then
		stage = 4
	elseif self.stage_ == ActivityState.AWARD_STAGE_4 or self.stage_ == ActivityState.BUY_STAGE_5 or self.stage_ == ActivityState.AWARD_STAGE_5 then
		stage = 5
	end

	xyd.WindowManager.get():openWindow("newbee_probability_window", {
		stage = stage
	})
end

return ActivityNewbee10Gacha
