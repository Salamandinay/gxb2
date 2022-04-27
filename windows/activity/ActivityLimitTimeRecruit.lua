local LimitTimeRecruit = class("LimitTimeRecruit", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")

function LimitTimeRecruit:ctor(parentGO, params, parent)
	LimitTimeRecruit.super.ctor(self, parentGO, params, parent)
end

function LimitTimeRecruit:getPrefabPath()
	return "Prefabs/Windows/activity/activity_time_limit_recruit"
end

function LimitTimeRecruit:initUI()
	self:getUIComponent()
	LimitTimeRecruit.super.initUI(self)
	self:initLayout()
	self:register()
	xyd.db.misc:setValue({
		key = "activity_time_limit_call",
		value = xyd.getServerTime()
	})
	self.activityData:ondailyRed()
end

function LimitTimeRecruit:getUIComponent()
	self.trans = self.go.transform
	self.bg = self.trans:ComponentByName("bg", typeof(UITexture))
	self.titleImg = self.trans:ComponentByName("titleImg", typeof(UISprite))
	self.timeGroup = self.trans:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.costGroup = self.trans:NodeByName("costGroup").gameObject
	self.costLabel = self.costGroup:ComponentByName("costLabel", typeof(UILabel))
	self.costPlusBtn = self.costGroup:ComponentByName("plusIcon", typeof(UISprite)).gameObject
	self.summonBtnOne = self.trans:NodeByName("summonBtnOne").gameObject
	self.btnOneTips = self.summonBtnOne:ComponentByName("labelTips", typeof(UILabel))
	self.btnOneNum = self.summonBtnOne:ComponentByName("labelNum", typeof(UILabel))
	self.summonBtnTen = self.trans:NodeByName("summonBtnTen").gameObject
	self.btnTenTips = self.summonBtnTen:ComponentByName("labelTips", typeof(UILabel))
	self.btnTenNum = self.summonBtnTen:ComponentByName("labelNum", typeof(UILabel))
	self.labelHit = self.trans:ComponentByName("labelHit", typeof(UILabel))
	self.helpBtn = self.trans:NodeByName("helpBtn").gameObject
	self.previewBtn = self.trans:NodeByName("previewBtn").gameObject
	self.giftbagBtn = self.trans:NodeByName("giftbagBtn").gameObject
	self.giftbagBtnRedPoint = self.giftbagBtn:ComponentByName("redPoint", typeof(UISprite))
	self.giftbagBtnLabel = self.giftbagBtn:ComponentByName("label", typeof(UILabel))
	self.awardBtn = self.trans:NodeByName("awardBtn").gameObject
	self.awardBtnRedPoint = self.awardBtn:ComponentByName("redPoint", typeof(UISprite))
	self.awardBtnLabel = self.awardBtn:ComponentByName("label", typeof(UILabel))
	self.shopBtn = self.trans:NodeByName("shopBtn").gameObject
	self.shopBtnRedPoint = self.shopBtn:ComponentByName("redPoint", typeof(UISprite))
	self.costGroup2 = self.trans:NodeByName("costGroup2").gameObject
	self.costLabel2 = self.costGroup2:ComponentByName("label", typeof(UILabel))
end

function LimitTimeRecruit:initLayout()
	xyd.setUISpriteAsync(self.titleImg, nil, "activity_time_limit_call_logo_" .. xyd.Global.lang, nil, , true)

	self.btnOneTips.text = __("GACHA_LIMIT_CALL_TIMES", 1)
	self.btnTenTips.text = __("GACHA_LIMIT_CALL_TIMES", 10)
	self.btnOneNum.text = "1"
	self.btnTenNum.text = "10"
	self.giftbagBtnLabel.text = __("ACTIVITY_LIMIT_GACHA_TEXT01")
	self.awardBtnLabel.text = __("ACTIVITY_LIMIT_GACHA_TEXT02")
	self.endLabel.text = __("TEXT_END")

	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd:getServerTime()
	})
	self:updateActivityData()
	self:updateItemNum()
	self:updateAwardBtnRedPoint()
	self:updateShopBtnRedPoint()
end

function LimitTimeRecruit:updateActivityData()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.TIME_LIMIT_CALL)
	self.activityDetail = self.activityData.detail
end

function LimitTimeRecruit:updateItemNum()
	self.costLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_ICON2)
	self.costLabel2.text = "x" .. xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_AWARD_ICON2)
	local totalHitTime = xyd.tables.miscTable:split2num("activity_limit_gacha_security_time", "value", "|")[1]
	self.labelHit.text = __("GACHA_LIMIT_CALL_TEXT_1", totalHitTime - self.activityData.detail.hit_times, xyd.tables.partnerTable:getName(52017))
end

function LimitTimeRecruit:updateAwardBtnRedPoint()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.TIME_LIMIT_CALL)

	activityData:updateRedMarkPoint()
	activityData:updateRedMarkPartner()

	self.needRed2 = activityData:getRedMarkPartner()
	self.needRed1 = activityData:getRedMarkPoint()

	if self.needRed2 or self.needRed1 then
		self.awardBtnRedPoint:SetActive(true)
	else
		self.awardBtnRedPoint:SetActive(false)
	end
end

function LimitTimeRecruit:updateShopBtnRedPoint()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.TIME_LIMIT_CALL)

	activityData:updateAwardRedMark()

	local awardRed = activityData:getAwardRedMark()

	if awardRed then
		self.shopBtnRedPoint:SetActive(true)
	else
		self.shopBtnRedPoint:SetActive(false)
	end
end

function LimitTimeRecruit:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateAwardBtnRedPoint))
	self:registerEvent(xyd.event.LIMIT_GACHA_SHOP, handler(self, self.updateShopBtnRedPoint))
	self:registerEvent(xyd.event.SUMMON, handler(self, self.onSummonEvent))
	self:registerEvent(xyd.event.BOSS_BUY, handler(self, self.onItemChange))
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:updateShopBtnRedPoint()

		self.costLabel2.text = "x" .. xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_AWARD_ICON2)
	end)

	UIEventListener.Get(self.costGroup).onClick = function ()
		local maxNumBeen = self.activityDetail.buy_times
		maxNumBeen = maxNumBeen or 0
		local maxNumCanBuy = xyd.tables.miscTable:getNumber("activity_limit_gacha_limit", "value") - maxNumBeen

		if maxNumCanBuy <= 0 then
			maxNumCanBuy = 0
		end

		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			activityData = self.activityDetail,
			maxNumCanBuy = maxNumCanBuy,
			itemID = xyd.ItemID.LIMIT_GACHA_ICON2,
			activityID = xyd.ActivityID.TIME_LIMIT_CALL
		})
	end

	UIEventListener.Get(self.costPlusBtn).onClick = function ()
		local maxNumBeen = self.activityDetail.buy_times
		maxNumBeen = maxNumBeen or 0
		local maxNumCanBuy = xyd.tables.miscTable:getNumber("activity_limit_gacha_limit", "value") - maxNumBeen

		if maxNumCanBuy <= 0 then
			maxNumCanBuy = 0
		end

		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			activityData = self.activityDetail,
			maxNumCanBuy = maxNumCanBuy,
			itemID = xyd.ItemID.LIMIT_GACHA_ICON2,
			activityID = xyd.ActivityID.TIME_LIMIT_CALL
		})
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_LIMIT_GACHA_HELP"
		})
	end

	UIEventListener.Get(self.previewBtn).onClick = function ()
		xyd.openWindow("drop_probability_window", {
			box_id = ItemTable:getDropBoxShow(self.itemID)
		})
	end

	UIEventListener.Get(self.giftbagBtn).onClick = function ()
		xyd.db.misc:setValue({
			key = "activity_time_limit_call_giftbag",
			value = xyd.getServerTime()
		})
		self.giftbagBtnRedPoint:SetActive(false)
		xyd.WindowManager.get():openWindow("activity_time_limit_call_giftbag_window", {})
	end

	UIEventListener.Get(self.awardBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_time_limit_call_award_window", {})
	end

	UIEventListener.Get(self.shopBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_limit_gacha_award_window", {})
	end

	UIEventListener.Get(self.summonBtnOne).onClick = function ()
		self:onSeniorSummon(1)
	end

	UIEventListener.Get(self.summonBtnTen).onClick = function ()
		self:onSeniorSummon(10)
	end
end

function LimitTimeRecruit:onSeniorSummon(num)
	local canSummonNum = xyd.models.slot:getCanSummonNum()
	self.collectionBefore_ = xyd.models.slot:getCollectionCopy()

	if self:isPartnerFullAndBuyLimit(num, canSummonNum) then
		return
	end

	if canSummonNum < num then
		xyd.openWindow("partner_slot_increase_window")

		return false
	end

	local hasNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_ICON2)

	local function summonLimitPartner(num, type)
		local msg = messages_pb.summon_req()
		msg.summon_id = type

		if num then
			msg.times = num
		end

		msg.is_jump = 1

		xyd.Backend.get():request(xyd.mid.SUMMON, msg)
	end

	if num == 1 then
		local cost = xyd.tables.summonTable:getCost(xyd.SummonType.TIME_LIMIT_CALL)

		if cost[2] <= hasNum then
			summonLimitPartner(1, xyd.SummonType.TIME_LIMIT_CALL)
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.LIMIT_GACHA_ICON2)))

			return false
		end
	elseif num == 10 then
		local cost = xyd.tables.summonTable:getCost(xyd.SummonType.TIME_LIMIT_CALL_TEN)

		if cost[2] <= hasNum then
			summonLimitPartner(10, xyd.SummonType.TIME_LIMIT_CALL_TEN)
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.LIMIT_GACHA_ICON2)))

			return false
		end
	end
end

function LimitTimeRecruit:isPartnerFullAndBuyLimit(num, canSummonNum)
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

function LimitTimeRecruit:onSummonEvent(event)
	local partners = event.data.summon_result.partners or {}
	local items = {}

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

	local itemData = event.data.award

	table.insert(items, {
		item_id = itemData.item_id,
		item_num = itemData.item_num or 1
	})

	if event.data.summon_id == xyd.SummonType.TIME_LIMIT_CALL or event.data.summon_id == xyd.SummonType.TIME_LIMIT_CALL_TEN then
		self:updateActivityData()
		self:updateItemNum()
		self:updateAwardBtnRedPoint()
	else
		return
	end

	local function callback()
		local num = 1

		if #items > 2 then
			num = 10
		end

		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			wnd_type = 4,
			data = items,
			cost = {
				xyd.ItemID.LIMIT_GACHA_ICON2,
				num
			},
			buyCallback = function (cost)
				local num = cost[2]
				local canSummonNum = xyd.models.slot:getCanSummonNum()

				if canSummonNum < num then
					xyd.openWindow("partner_slot_increase_window")

					return false
				end

				local hasNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_ICON2)

				local function summonLimitPartner(num, type)
					local msg = messages_pb.summon_req()
					msg.summon_id = type

					if num then
						msg.times = num
					end

					msg.is_jump = 1

					xyd.Backend.get():request(xyd.mid.SUMMON, msg)
				end

				local type = xyd.SummonType.TIME_LIMIT_CALL
				local cost = xyd.tables.summonTable:getCost(xyd.SummonType.TIME_LIMIT_CALL)

				if num == 10 then
					type = xyd.SummonType.TIME_LIMIT_CALL_TEN
					cost = xyd.tables.summonTable:getCost(xyd.SummonType.TIME_LIMIT_CALL_TEN)
				end

				if cost[2] <= hasNum then
					summonLimitPartner(num, type)
				else
					xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.LIMIT_GACHA_ICON2)))

					return false
				end
			end
		})
	end

	local specPartner = {}
	local specPartnerID = xyd.tables.miscTable:getNumber("activity_limit_gacha_partner_show", "value")

	for i, partner in ipairs(partners) do
		local item_id = partner.table_id

		if item_id == specPartnerID then
			table.insert(specPartner, item_id)
		end
	end

	if #specPartner > 0 then
		xyd.WindowManager.get():openWindow("summon_effect_res_window", {
			partners = {
				specPartnerID
			},
			callback = callback
		})
	else
		local new5stars = xyd.isHasNew5Stars2(items, self.collectionBefore_)

		if #new5stars > 0 then
			xyd.WindowManager.get():openWindow("summon_effect_res_window", {
				partners = new5stars,
				callback = callback
			})
		else
			callback()
		end
	end
end

function LimitTimeRecruit:onItemChange(event)
	if event.data.buy_times and event.data.buy_times > 0 then
		xyd.alertTips(__("PURCHASE_SUCCESS"))

		self.activityDetail.buy_times = event.data.buy_times
	end

	self:updateActivityData()
	self:updateItemNum()
	self:updateAwardBtnRedPoint()
end

function LimitTimeRecruit:resizeToParent()
	LimitTimeRecruit.super.resizeToParent(self)

	local stageHeight = xyd.Global.getRealHeight()
	local num = (stageHeight - 1280) / (xyd.Global.getMaxHeight() - 1280)

	if xyd.Global.getMaxHeight() < stageHeight then
		num = 1
	end

	local scale_num = 1 - num

	self.labelHit:Y(-960 + 156 * scale_num)
	self.summonBtnOne:Y(-907 + 156 * scale_num)
	self.summonBtnTen:Y(-907 + 156 * scale_num)
	self.titleImg:Y(-448 + 138 * scale_num)
	self.timeGroup:Y(-774 + 138 * scale_num)
	self.costGroup:Y(-839 + 161 * scale_num)
	self.giftbagBtn:Y(-983 + 175 * scale_num)
end

return LimitTimeRecruit
