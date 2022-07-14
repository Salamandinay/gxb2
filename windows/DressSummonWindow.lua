local BaseWindow = import(".BaseWindow")
local DressSummonWindow = class("DressSummonWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local NormalSummon = class("NormalSummon", import("app.components.CopyComponent"))
local LimitSummon = class("LimitSummon", import("app.components.CopyComponent"))
local AwardTempItem = class("AwardTempItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")

function AwardTempItem:ctor(go, parent)
	self.parent_ = parent

	AwardTempItem.super.ctor(self, go)
end

function AwardTempItem:update(_, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.itemID_ = info

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon({
			uiRoot = self.go,
			itemID = self.itemID_,
			dragScrollView = self.parent_.scrollView_
		})
	else
		self.itemIcon_:setInfo({
			itemID = self.itemID_
		})
	end

	local isGet = self.parent_:checkHasGot(self.itemID_)

	self.itemIcon_:setChoose(isGet)
end

function DressSummonWindow:ctor(name, params)
	DressSummonWindow.super.ctor(self, name, params)

	self.hasSummoned = false
end

function DressSummonWindow:initWindow()
	BaseWindow.initWindow(self)

	local breakEventNum = xyd.models.summon:getDressBreakNum()

	if not breakEventNum then
		xyd.models.summon:reqDressSummonInfo()
	end

	self.debrisSeqList_ = {}

	self:getUIComponent()
	self:layout()

	local openTime = xyd.db.misc:getValue("dress_summon_window_open")

	if not openTime or not xyd.isSameDay(openTime, xyd.getServerTime()) then
		self:touchPoint()
	end
end

function DressSummonWindow:touchPoint()
	local msg = messages_pb.log_partner_data_touch_req()
	msg.touch_id = xyd.DaDian.DRESS_SUMMON

	xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	xyd.db.misc:setValue({
		key = "dress_summon_window_open",
		value = xyd.getServerTime()
	})
end

function DressSummonWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction").gameObject
	self.normalSummonGroup_ = goTrans:NodeByName("normalSummonGroup").gameObject
	self.limitSummonGroup_ = goTrans:NodeByName("limitSummonGroup").gameObject
end

function DressSummonWindow:layout()
	self:initTopGroup()
	self:initNormalGroup()

	local activityDresssLimit = xyd.models.activity:getActivity(xyd.ActivityID.DRESS_SUMMON_LIMIT)

	if activityDresssLimit then
		self:showArrow()
		self:initLimitGroup()
	end
end

function DressSummonWindow:reqSummonDress(times)
	self.normalSummon_:reqSummonDress(times)
end

function DressSummonWindow:initNormalGroup()
	self.normalSummon_ = NormalSummon.new(self.normalSummonGroup_, self)
end

function DressSummonWindow:initLimitGroup()
	self.limitSummon_ = LimitSummon.new(self.limitSummonGroup_, self)
end

function DressSummonWindow:reqSummonLimitDress(times)
	self.limitSummon_:reqSummonLimitDress(times)
end

function DressSummonWindow:showArrow()
	self.normalSummon_:showArrow()
end

function DressSummonWindow:initTopGroup()
	local winTop = WindowTop.new(self.window_, self.name_, 1, true)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	winTop:setItem(items)
end

function DressSummonWindow:playOpenAnimation(callback)
	DressSummonWindow.super.playOpenAnimation(self, function ()
		local activityDresssLimit = xyd.models.activity:getActivity(xyd.ActivityID.DRESS_SUMMON_LIMIT)

		if self.params_ and self.params_.select and self.params_.select == 1 then
			self:jumpToPart(1)
		elseif activityDresssLimit then
			self:jumpToPart(2)
		end

		if callback then
			callback()
		end
	end)
end

function DressSummonWindow:jumpToPart(index)
	local pos = -1200 * (index - 1)

	self.normalSummonGroup_.transform:X(pos)

	if self.normalSummon_ then
		self.normalSummon_:updateSkipBtn()
	end

	if self.limitSummon_ then
		self.limitSummon_:updateSkipBtn()
	end
end

function DressSummonWindow:cleardebrisSeq()
	if next(self.debrisSeqList_) then
		for i = 1, #self.debrisSeqList_ do
			if not tolua.isnull(self.debrisSeqList_[i]) then
				self.debrisSeqList_[i]:Pause()
				self.debrisSeqList_[i]:Kill(false)
			end
		end

		self.debrisSeqList_ = {}
	end
end

function DressSummonWindow:willClose()
	self:cleardebrisSeq()
	DressSummonWindow.super.willClose(self)
end

function DressSummonWindow:excuteCallBack(isCloseAll)
	if not isCloseAll and self.params_ and self.params_.closeCallBack then
		self.params_.closeCallBack(self.hasSummoned)
	end
end

function NormalSummon:ctor(go, parent)
	self.parent_ = parent

	NormalSummon.super.ctor(self, go)
end

function NormalSummon:initUI()
	self:getUIComponent()
	self:updatePos()
	self:layout()
	self:onRegister()
end

function NormalSummon:getUIComponent()
	local goTrans = self.go.transform
	self.bgImg_ = goTrans:NodeByName("bgImg").gameObject
	self.tipsGroup_ = goTrans:NodeByName("topGroup/tipsGroup").gameObject
	self.tipsLabel_ = goTrans:ComponentByName("topGroup/tipsGroup/tipsLabel", typeof(UILabel))
	self.timeLabel_ = goTrans:ComponentByName("topGroup/tipsGroup/timeLabel", typeof(UILabel))
	self.detailBtn_ = goTrans:NodeByName("topGroup/detailBtn").gameObject
	self.jumpBtn_ = goTrans:NodeByName("topGroup/jumpBtn").gameObject
	self.skipBtn_ = goTrans:NodeByName("topGroup/skipBtn").gameObject
	self.midGroup_ = goTrans:NodeByName("midGroup")
	self.logoImg_ = self.midGroup_:ComponentByName("logoImg", typeof(UISprite))
	self.arrow_left_ = self.midGroup_:NodeByName("arrow_left").gameObject
	self.arrow_right_ = self.midGroup_:NodeByName("arrow_right").gameObject
	self.summonGroup_ = goTrans:NodeByName("summonGroup")
	self.costItemIcon_ = self.summonGroup_:ComponentByName("itemCost/itemIcon", typeof(UISprite))
	self.costItemNum_ = self.summonGroup_:ComponentByName("itemCost/label", typeof(UILabel))
	self.iconPlus_ = self.summonGroup_:NodeByName("itemCost/iconPlus").gameObject
	self.breakEvenLabel_ = self.summonGroup_:ComponentByName("breakEvenLabel", typeof(UILabel))
	self.summonOne_ = self.summonGroup_:NodeByName("senior_summon_one").gameObject
	self.summonOneIcon_ = self.summonGroup_:ComponentByName("senior_summon_one/itemIcon", typeof(UISprite))
	self.summonOneLabelDisplay_ = self.summonGroup_:ComponentByName("senior_summon_one/labelItemDisplay", typeof(UILabel))
	self.summonOneLabelCost_ = self.summonGroup_:ComponentByName("senior_summon_one/labelItemCost", typeof(UILabel))
	self.summonTen_ = self.summonGroup_:NodeByName("senior_summon_ten").gameObject
	self.summonTenIcon_ = self.summonGroup_:ComponentByName("senior_summon_ten/itemIcon", typeof(UISprite))
	self.summonTenLabelDisplay_ = self.summonGroup_:ComponentByName("senior_summon_ten/labelItemDisplay", typeof(UILabel))
	self.summonTenLabelCost_ = self.summonGroup_:ComponentByName("senior_summon_ten/labelItemCost", typeof(UILabel))
	self.awardGroup_ = goTrans:NodeByName("awardGroup")
	self.scrollView_ = self.awardGroup_:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = self.awardGroup_:ComponentByName("scrollView/grid", typeof(UIWrapContent))
	self.tempRoot_ = self.awardGroup_:NodeByName("itemRoot").gameObject
	self.labelTips_ = self.awardGroup_:ComponentByName("labelTips", typeof(UILabel))
	self.multiWrap_ = require("app.common.ui.FixedWrapContent").new(self.scrollView_, self.grid_, self.tempRoot_, AwardTempItem, self)
end

function NormalSummon:updatePos()
	local realHeight = xyd.Global.getRealHeight()

	self.bgImg_.transform:Y(214 - 0.5056179775280899 * (realHeight - 1280))
	self.midGroup_:Y(-560 - 0.8314606741573034 * (realHeight - 1280))
	self.summonGroup_:Y(-710 - 0.8595505617977528 * (realHeight - 1280))
	self.awardGroup_:Y(-910 - 1.0280898876404494 * (realHeight - 1280))
end

function NormalSummon:showArrow()
	self.arrow_left_:SetActive(true)
	self.arrow_right_:SetActive(true)
end

function NormalSummon:layout()
	self:initAwardItems()
	self:updateFreeTimes()
	self:updateItemNum()

	self.labelTips_.text = __("DRESS_SUMMON_LABEL_2")
	self.summonOneLabelDisplay_.text = __("DRESS_SUMMON_X_TIME", 1)
	self.summonTenLabelDisplay_.text = __("DRESS_SUMMON_X_TIME", 10)

	xyd.setUISpriteAsync(self.logoImg_, nil, "dress_summon_logo_" .. xyd.Global.lang)
	self:updateSkipBtn()
	self:updateBreakNum()
end

function NormalSummon:updateItemNum()
	self.costItemNum_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DRESS_SUMMON_CARD)
end

function NormalSummon:updateSkipBtn()
	local img = self.skipBtn_:ComponentByName("", typeof(UISprite))
	local activityData = xyd.models.summon
	local skip = activityData:getDressSkipAnimation()

	if skip then
		xyd.setUISpriteAsync(img, nil, "battle_img_skip")
	else
		xyd.setUISpriteAsync(img, nil, "btn_max")
	end
end

function NormalSummon:updateFreeTimes()
	local cost = xyd.tables.miscTable:split2Cost("dress_gacha_cost1", "value", "#")
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.DRESS_SUMMON_FREE)

	if not activityData then
		self.tipsGroup_.gameObject:SetActive(false)
		self.summonOneIcon_.gameObject:SetActive(true)
		self.summonTenIcon_.gameObject:SetActive(true)

		self.summonOneLabelCost_.text = cost[2]

		self.summonOneLabelCost_.transform:X(15)
	elseif activityData and activityData.detail.can_summon_times <= 0 then
		local updateTime = activityData:startTime()
		local updateBreak = tonumber(xyd.tables.miscTable:split2Cost("dress_gacha_free1", "value", "|")[1])
		local time1 = math.fmod(xyd.getServerTime() - updateTime, updateBreak)
		self.countdown_ = CountDown.new(self.timeLabel_, {
			duration = updateBreak - time1,
			callback = function ()
				xyd.models.activity:reqActivityByID(xyd.ActivityID.DRESS_SUMMON_FREE)
			end
		})
		local endTime = activityData:getEndTime()

		if endTime <= time1 + updateBreak then
			self.tipsGroup_.gameObject:SetActive(false)
		else
			self.tipsGroup_.gameObject:SetActive(true)

			self.tipsLabel_.text = __("DRESS_SUMMON_LABEL_5")
		end

		self.summonOneIcon_.gameObject:SetActive(true)
		self.summonTenIcon_.gameObject:SetActive(true)

		self.summonOneLabelCost_.text = cost[2]

		self.summonOneLabelCost_.transform:X(15)

		self.summonTenLabelCost_.text = 10 * cost[2]

		self.summonTenLabelCost_.transform:X(15)
	else
		self.tipsGroup_.gameObject:SetActive(true)
		self.summonOneIcon_.gameObject:SetActive(false)

		self.tipsLabel_.text = __("DRESS_SUMMON_LABEL_1", activityData.detail.can_summon_times)
		local updateTime = activityData:startTime()
		local updateBreak = tonumber(xyd.tables.miscTable:split2Cost("dress_gacha_free1", "value", "|")[1])
		local time1 = math.fmod(xyd.getServerTime() - updateTime, updateBreak)

		dump(activityData.detail, "activityData")
		print("xyd.getServerTime()", xyd.getServerTime())
		print("math.fmod((xyd.getServerTime()-updateTime),updateBreak)", math.fmod(xyd.getServerTime() - updateTime, updateBreak))

		self.countdown_ = CountDown.new(self.timeLabel_, {
			duration = updateBreak - time1
		})

		if activityData.detail.can_summon_times >= 10 then
			self.summonTenIcon_.gameObject:SetActive(false)

			self.summonTenLabelCost_.text = __("PUB_SPEED_FREE")

			self.summonTenLabelCost_.transform:X(0)
		else
			self.summonTenIcon_.gameObject:SetActive(true)

			self.summonTenLabelCost_.text = 10 * cost[2]

			self.summonTenLabelCost_.transform:X(15)
		end

		self.summonOneLabelCost_.text = __("PUB_SPEED_FREE")

		self.summonOneLabelCost_.transform:X(0)
	end
end

function NormalSummon:initAwardItems()
	local dropBoxId1 = tonumber(xyd.tables.miscTable:getVal("dress_gacha_dropbox4"))
	local dropBoxId2 = tonumber(xyd.tables.miscTable:getVal("dress_gacha_dropbox1"))

	if not xyd.tables.dropboxShowTable:getIdsByBoxId(dropBoxId1) then
		local showIDs1 = {
			list = {}
		}
	end

	if not xyd.tables.dropboxShowTable:getIdsByBoxId(dropBoxId2) then
		local showIDs2 = {
			list = {}
		}
	end

	table.sort(showIDs1.list)
	table.sort(showIDs2.list)

	local showIDs = xyd.arrayMerge(showIDs2.list, showIDs1.list)
	local items = {}
	local checkList = {}

	for _, id in ipairs(showIDs) do
		local data = xyd.tables.dropboxShowTable:getItem(id)

		if not checkList[data[1]] then
			table.insert(items, data[1])
		end

		checkList[data[1]] = 1
	end

	self.multiWrap_:setInfos(items, {})
end

function NormalSummon:checkHasGot(id)
	return false
end

function NormalSummon:onRegister()
	UIEventListener.Get(self.detailBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("dress_buy_probability_window", {
			type = xyd.DressBuyProbWndType.BASE
		})
	end

	UIEventListener.Get(self.jumpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("dress_main_window", {
			window_top_close_fun = function ()
			end
		})
		xyd.WindowManager.get():closeWindow("dress_summon_window")
	end

	UIEventListener.Get(self.skipBtn_).onClick = function ()
		local img = self.skipBtn_:ComponentByName("", typeof(UISprite))
		local activityData = xyd.models.summon

		activityData:changeDressSkipAnimation()

		local skip = activityData:getDressSkipAnimation()

		if skip then
			xyd.setUISpriteAsync(img, nil, "battle_img_skip")
		else
			xyd.setUISpriteAsync(img, nil, "btn_max")
		end
	end

	UIEventListener.Get(self.iconPlus_).onClick = function ()
		local params = {
			showGetWays = true,
			notShowGetWayBtn = false,
			show_has_num = false,
			itemID = xyd.ItemID.DRESS_SUMMON_CARD,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.arrow_right_).onClick = handler(self, self.goLimitPart)

	UIEventListener.Get(self.summonOne_).onClick = function ()
		self:reqSummonDress(1)
	end

	UIEventListener.Get(self.summonTen_).onClick = function ()
		self:reqSummonDress(10)
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.updateFreeTimes))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNum))
	self:registerEvent(xyd.event.SUMMON_DRESS, handler(self, self.onSummonResult))
	self:registerEvent(xyd.event.GET_DRESS_SUMMON_INFO, handler(self, self.updateBreakNum))
end

function NormalSummon:reqSummonDress(times)
	local cost = xyd.tables.miscTable:split2Cost("dress_gacha_cost1", "value", "#")
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.DRESS_SUMMON_FREE)
	local free_times = 0

	if activityData and activityData.detail.can_summon_times then
		free_times = activityData.detail.can_summon_times
	end

	self.summonTen_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	local type_ = 1

	if times <= free_times then
		type_ = 2
		activityData.detail.can_summon_times = activityData.detail.can_summon_times - times
	end

	if type_ == 1 and xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] * times then
		xyd.alertTips(__("SWEETY_HOUSE_NEED_MORE", xyd.tables.itemTable:getName(cost[1])))

		return
	end

	local msg = messages_pb.summon_req()
	msg.summon_id = type_
	msg.times = times

	xyd.Backend:get():request(xyd.mid.SUMMON_DRESS, msg)
end

function NormalSummon:onSummonResult(event)
	if event.data.summon_id ~= 1 and event.data.summon_id ~= 2 then
		return
	end

	local haveCool = false
	self.parent_.hasSummoned = true
	local items = event.data.summon_result.items

	xyd.models.dress:updateDynamics(event.data.dyn_count, xyd.DressBuffAttrType.SUMMON)

	local transfer = event.data.transfer or {}
	local params = {}

	if #items > 0 then
		for i in ipairs(items) do
			if items[i].item_id and items[i].item_id ~= 0 then
				table.insert(params, {
					item_num = items[i].item_num,
					item_id = items[i].item_id,
					index = i
				})
			end
		end
	end

	for i = 1, #params do
		local itemID = params[i].item_id
		local quality = xyd.tables.itemTable:getQuality(itemID)

		if tonumber(quality) >= 6 then
			params[i].cool = 1
			haveCool = true
		else
			params[i].cool = 0
		end
	end

	for i, itemData in ipairs(params) do
		if transfer[itemData.index] and transfer[itemData.index] == 1 then
			local dressId = xyd.tables.senpaiDressItemTable:getDressId(itemData.item_id)
			local debrisData = xyd.tables.senpaiDressTable:getDressHand(dressId)
			local index = itemData.index
			params[i] = {
				item_num = debrisData[2],
				item_id = debrisData[1],
				index = index,
				cool = itemData.cool
			}
		end
	end

	local name = nil

	if #params == 1 then
		if haveCool then
			name = "dress_gacha_02"
		else
			name = "dress_gacha_01"
		end
	elseif haveCool then
		name = "dress_gacha_04"
	else
		name = "dress_gacha_03"
	end

	local function skipCallBack()
		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			wnd_type = 5,
			type = 1,
			data = params
		}, function ()
			self.summonTen_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		end)
		self:updateBreakNum()
		self:updateFreeTimes()
	end

	local activityData = xyd.models.summon
	local skip = activityData:getDressSkipAnimation()

	if skip then
		skipCallBack()
	else
		xyd.openWindow("dress_summon_effect_res_window", {
			callback = skipCallBack,
			animationName = name
		})
	end
end

function NormalSummon:goLimitPart()
	self.parent_:jumpToPart(2)
end

function NormalSummon:updateBreakNum()
	local breakEventNum = xyd.models.summon:getDressBreakNum() or 0
	local maxNum = tonumber(xyd.tables.miscTable:getVal("dress_gacha_max_drop"))
	local showNum = math.fmod(breakEventNum, maxNum)
	self.breakEvenLabel_.text = __("DRESS_SUMMON_LABEL_4", maxNum - showNum)
end

function LimitSummon:ctor(go, parent)
	self.parent_ = parent
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.DRESS_SUMMON_LIMIT)

	LimitSummon.super.ctor(self, go)
end

function LimitSummon:initUI()
	self:getUIComponent()
	self:updatePos()
	self:layout()
	self:onRegister()
	self:updateBreakNum()
end

function LimitSummon:getUIComponent()
	local goTrans = self.go.transform
	self.bgImg_ = goTrans:NodeByName("bgImg").gameObject
	self.tipsGroup_ = goTrans:NodeByName("topGroup/tipsGroup").gameObject
	self.tipsLabel_ = goTrans:ComponentByName("topGroup/tipsGroup/tipsLabel", typeof(UILabel))
	self.topTimeLabel_ = goTrans:ComponentByName("topGroup/tipsGroup/timeLabel", typeof(UILabel))
	self.detailBtn_ = goTrans:NodeByName("topGroup/detailBtn").gameObject
	self.jumpBtn_ = goTrans:NodeByName("topGroup/jumpBtn").gameObject
	self.skipBtn_ = goTrans:NodeByName("topGroup/skipBtn").gameObject
	self.midGroup_ = goTrans:NodeByName("midGroup")
	self.logoImg_ = self.midGroup_:ComponentByName("logoImg", typeof(UISprite))
	self.arrow_left_ = self.midGroup_:NodeByName("arrow_left").gameObject
	self.arrow_right_ = self.midGroup_:NodeByName("arrow_right").gameObject
	self.limitTipsLabel_ = self.midGroup_:ComponentByName("label", typeof(UILabel))
	self.timeLabel_ = self.midGroup_:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel_ = self.midGroup_:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.summonGroup_ = goTrans:NodeByName("summonGroup")
	self.costItemIcon1_ = self.summonGroup_:ComponentByName("itemCost1/itemIcon", typeof(UISprite))
	self.costItemNum1_ = self.summonGroup_:ComponentByName("itemCost1/label", typeof(UILabel))
	self.iconPlus1_ = self.summonGroup_:NodeByName("itemCost1/iconPlus").gameObject
	self.costItemIcon2_ = self.summonGroup_:ComponentByName("itemCost2/itemIcon", typeof(UISprite))
	self.costItemNum2_ = self.summonGroup_:ComponentByName("itemCost2/label", typeof(UILabel))
	self.iconPlus2_ = self.summonGroup_:NodeByName("itemCost2/iconPlus").gameObject
	self.breakEvenLabel_ = self.summonGroup_:ComponentByName("breakEvenLabel", typeof(UILabel))
	self.summonOne_ = self.summonGroup_:NodeByName("senior_summon_one").gameObject
	self.summonOneIcon_ = self.summonGroup_:ComponentByName("senior_summon_one/itemIcon", typeof(UISprite))
	self.summonOneLabelDisplay_ = self.summonGroup_:ComponentByName("senior_summon_one/labelItemDisplay", typeof(UILabel))
	self.summonOneLabelCost_ = self.summonGroup_:ComponentByName("senior_summon_one/labelItemCost", typeof(UILabel))
	self.summonTen_ = self.summonGroup_:NodeByName("senior_summon_ten").gameObject
	self.summonTenIcon_ = self.summonGroup_:ComponentByName("senior_summon_ten/itemIcon", typeof(UISprite))
	self.summonTenLabelDisplay_ = self.summonGroup_:ComponentByName("senior_summon_ten/labelItemDisplay", typeof(UILabel))
	self.summonTenLabelCost_ = self.summonGroup_:ComponentByName("senior_summon_ten/labelItemCost", typeof(UILabel))
	self.awardGroup_ = goTrans:NodeByName("awardGroup")
	self.scrollView_ = self.awardGroup_:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = self.awardGroup_:ComponentByName("scrollView/grid", typeof(UIWrapContent))
	self.tempRoot_ = self.awardGroup_:NodeByName("itemRoot").gameObject
	self.labelTips_ = self.awardGroup_:ComponentByName("labelTips", typeof(UILabel))

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		self.labelTips_.transform:Y(-5)
	end

	self.multiWrap_ = require("app.common.ui.FixedWrapContent").new(self.scrollView_, self.grid_, self.tempRoot_, AwardTempItem, self)
	self.showGroup_ = goTrans:NodeByName("showGroup")
	self.effectRoot1_ = goTrans:NodeByName("showGroup/showPart1/effectRoot").gameObject
	self.effectRoot2_ = goTrans:NodeByName("showGroup/showPart2/effectRoot").gameObject
end

function LimitSummon:updatePos()
	local realHeight = xyd.Global.getRealHeight()

	self.bgImg_.transform:Y(214 - 0.5056179775280899 * (realHeight - 1280))
	self.midGroup_:Y(-560 - 0.8314606741573034 * (realHeight - 1280))
	self.summonGroup_:Y(-710 - 0.8595505617977528 * (realHeight - 1280))
	self.awardGroup_:Y(-910 - 1.0280898876404494 * (realHeight - 1280))
	self.showGroup_:Y(-382 - 0.5617977528089888 * (realHeight - 1280))
end

function LimitSummon:layout()
	self:initAwardItems()
	self:updateFreeTimes()
	self:updateItemNum()
	self:initEffect()

	self.labelTips_.text = __("DRESS_SUMMON_LABEL_6")
	self.summonOneLabelDisplay_.text = __("DRESS_SUMMON_X_TIME", 1)
	self.summonTenLabelDisplay_.text = __("DRESS_SUMMON_X_TIME", 10)
	self.limitTipsLabel_.text = __("DRESS_SUMMON_LABEL_3")
	self.countdownEnd_ = CountDown.new(self.timeLabel_, {
		key = "ACTIVITY_END_COUNT",
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	})

	xyd.setUISpriteAsync(self.logoImg_, nil, "dress_summon_limit_logo_" .. xyd.Global.lang, nil, false, true)
	self:updateSkipBtn()
end

function LimitSummon:initEffect()
	local suitID = xyd.tables.miscTable:split2num("dress_gacha_activity_show", "value", "|")[1]
	local styleList1 = xyd.tables.senpaiDressGroupTable:getStyleUnit(suitID)
	local styleList2 = {}

	for _, id in ipairs(styleList1) do
		local dressid = xyd.tables.senpaiDressStyleTable:getDressId(id)
		local style2 = xyd.tables.senpaiDressTable:getStyles(dressid)[2]

		if style2 and style2 ~= 0 then
			table.insert(styleList2, style2)
		else
			table.insert(styleList2, id)
		end
	end

	self.effect1_ = import("app.components.SenpaiModel").new(self.effectRoot1_)

	self.effect1_:setModelInfo({
		ids = styleList1
	})

	self.effect2_ = import("app.components.SenpaiModel").new(self.effectRoot2_)

	self.effect2_:setModelInfo({
		ids = styleList2
	})
end

function LimitSummon:updateItemNum()
	self.costItemNum1_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DRESS_SUMMON_CARD)
	self.costItemNum2_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DRESS_SUMMON_LIMIT_CARD)
end

function LimitSummon:updateSkipBtn()
	local img = self.skipBtn_:ComponentByName("", typeof(UISprite))
	local activityData = xyd.models.summon
	local skip = activityData:getDressSkipAnimation()

	if skip then
		xyd.setUISpriteAsync(img, nil, "battle_img_skip")
	else
		xyd.setUISpriteAsync(img, nil, "btn_max")
	end
end

function LimitSummon:updateFreeTimes()
	local cost = xyd.tables.miscTable:split2Cost("dress_gacha_cost2", "value", "|#")
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.DRESS_SUMMON_LIMIT_FREE)

	xyd.setUISpriteAsync(self.summonOneIcon_, nil, "icon_259")
	xyd.setUISpriteAsync(self.summonTenIcon_, nil, "icon_259")

	if not activityData then
		self.tipsGroup_.gameObject:SetActive(false)

		self.summonOneLabelCost_.text = cost[1][2]

		self.summonOneLabelCost_.transform:X(15)

		self.summonTenLabelCost_.text = 10 * cost[1][2]

		self.summonTenLabelCost_.transform:X(15)
		self.summonOneIcon_.gameObject:SetActive(true)
		self.summonTenIcon_.gameObject:SetActive(true)
	elseif activityData and activityData.detail.can_summon_times <= 0 then
		local updateTime = activityData:startTime()
		local updateBreak = tonumber(xyd.tables.miscTable:split2Cost("dress_gacha_free2", "value", "|")[1])
		local time1 = math.fmod(xyd.getServerTime() - updateTime, updateBreak)
		self.countdown_ = CountDown.new(self.topTimeLabel_, {
			duration = updateBreak - time1,
			callback = function ()
				xyd.models.activity:reqActivityByID(xyd.ActivityID.DRESS_SUMMON_LIMIT_FREE)
			end
		})
		local endTime = activityData:getEndTime()

		if endTime <= time1 + updateBreak then
			self.tipsGroup_.gameObject:SetActive(false)
		else
			self.tipsGroup_.gameObject:SetActive(true)

			self.tipsLabel_.text = __("DRESS_SUMMON_LABEL_5")
		end

		self.summonOneIcon_.gameObject:SetActive(true)
		self.summonTenIcon_.gameObject:SetActive(true)

		self.summonOneLabelCost_.text = cost[1][2]

		self.summonOneLabelCost_.transform:X(15)

		self.summonTenLabelCost_.text = 10 * cost[1][2]

		self.summonTenLabelCost_.transform:X(15)
	else
		self.tipsGroup_.gameObject:SetActive(true)
		self.summonOneIcon_.gameObject:SetActive(false)

		self.tipsLabel_.text = __("DRESS_SUMMON_LABEL_1", activityData.detail.can_summon_times)
		local updateTime = activityData:startTime()
		local updateBreak = tonumber(xyd.tables.miscTable:split2Cost("dress_gacha_free2", "value", "|")[1])
		local time1 = math.fmod(xyd.getServerTime() - updateTime, updateBreak)
		self.countdown_ = CountDown.new(self.topTimeLabel_, {
			duration = updateBreak - time1,
			callback = function ()
				xyd.models.activity:reqActivityByID(xyd.ActivityID.DRESS_SUMMON_LIMIT_FREE)
			end
		})

		if activityData.detail.can_summon_times >= 10 then
			self.summonTenIcon_.gameObject:SetActive(false)

			self.summonTenLabelCost_.text = __("PUB_SPEED_FREE")

			self.summonTenLabelCost_.transform:X(0)
		else
			self.summonTenIcon_.gameObject:SetActive(true)

			self.summonTenLabelCost_.text = 10 * cost[1][2]

			self.summonTenLabelCost_.transform:X(15)
		end

		self.summonOneLabelCost_.text = __("PUB_SPEED_FREE")

		self.summonOneLabelCost_.transform:X(0)
	end
end

function LimitSummon:initAwardItems(keepPosition)
	local dropBoxId = tonumber(xyd.tables.miscTable:getVal("dress_gacha_dropbox3"))

	if not xyd.tables.dropboxShowTable:getIdsByBoxId(dropBoxId) then
		local showIDs = {
			list = {}
		}
	end

	table.sort(showIDs.list)

	local items = {}
	local checkList = {}

	for _, id in ipairs(showIDs.list) do
		local data = xyd.tables.dropboxShowTable:getItem(id)

		if not checkList[data[1]] then
			table.insert(items, data[1])
		end

		checkList[data[1]] = 1
	end

	self.bigItems = items

	self.multiWrap_:setInfos(items, {
		keepPosition = keepPosition
	})
end

function LimitSummon:checkHasGot(id)
	local records = self.activityData.detail.records

	if xyd.arrayIndexOf(records, id) > 0 then
		return true
	else
		return false
	end
end

function LimitSummon:onRegister()
	UIEventListener.Get(self.detailBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("dress_buy_probability_window", {
			type = xyd.DressBuyProbWndType.LIMIT
		})
	end

	UIEventListener.Get(self.jumpBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow("dress_summon_window")
		xyd.WindowManager.get():openWindow("dress_main_window", {
			window_top_close_fun = function ()
			end
		})
	end

	UIEventListener.Get(self.skipBtn_).onClick = function ()
		local img = self.skipBtn_:ComponentByName("", typeof(UISprite))
		local activityData = xyd.models.summon

		activityData:changeDressSkipAnimation()

		local skip = activityData:getDressSkipAnimation()

		if skip then
			xyd.setUISpriteAsync(img, nil, "battle_img_skip")
		else
			xyd.setUISpriteAsync(img, nil, "btn_max")
		end
	end

	UIEventListener.Get(self.iconPlus1_).onClick = function ()
		local params = {
			showGetWays = true,
			notShowGetWayBtn = false,
			show_has_num = false,
			itemID = xyd.ItemID.DRESS_SUMMON_CARD,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.iconPlus2_).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.DRESS_SUMMON_LIMIT_CARD,
			activityID = xyd.ActivityID.DRESS_SUMMON_LIMIT
		})
	end

	UIEventListener.Get(self.summonOne_).onClick = function ()
		self:reqSummonLimitDress(1)
	end

	UIEventListener.Get(self.summonTen_).onClick = function ()
		self:reqSummonLimitDress(10)
	end

	UIEventListener.Get(self.arrow_left_).onClick = handler(self, self.goNormalPart)

	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.updateFreeTimes))
	self:registerEvent(xyd.event.SUMMON_DRESS, handler(self, self.onSummonResult))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNum))
	self:registerEvent(xyd.event.GET_DRESS_SUMMON_INFO, handler(self, self.updateBreakNum))
end

function LimitSummon:goNormalPart()
	self.parent_:jumpToPart(1)
end

function LimitSummon:updateBreakNum()
	local breakEventNum = xyd.models.summon:getDressLimitBreakNum() or 0
	local maxNum = tonumber(xyd.tables.miscTable:getVal("dress_gacha_max_drop"))
	local showNum = math.fmod(breakEventNum, maxNum)
	self.breakEvenLabel_.text = __("DRESS_SUMMON_LABEL_4", maxNum - showNum)
end

function LimitSummon:reqSummonLimitDress(times)
	local cost = xyd.tables.miscTable:split2Cost("dress_gacha_cost2", "value", "|#")
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.DRESS_SUMMON_LIMIT_FREE)
	local free_times = 0

	if activityData then
		free_times = activityData.detail.can_summon_times
	end

	local type_ = nil

	if times <= free_times then
		type_ = 4
		activityData.detail.can_summon_times = activityData.detail.can_summon_times - times
	end

	if type_ ~= 4 then
		if xyd.models.backpack:getItemNumByID(cost[2][1]) < cost[2][2] * times then
			xyd.alertTips(__("SWEETY_HOUSE_NEED_MORE", xyd.tables.itemTable:getName(cost[2][1])))

			return
		elseif xyd.models.backpack:getItemNumByID(cost[2][1]) >= cost[2][2] * times then
			type_ = 3
		end
	end

	self.summonTen_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	local msg = messages_pb.summon_req()
	msg.summon_id = type_
	msg.times = times

	xyd.Backend:get():request(xyd.mid.SUMMON_DRESS, msg)
end

function LimitSummon:onSummonResult(event)
	if event.data.summon_id == 1 or event.data.summon_id == 2 then
		return
	end

	self.parent_.hasSummoned = true
	local haveCool = false
	local items = event.data.summon_result.items

	xyd.models.dress:updateDynamics(event.data.dyn_count, xyd.DressBuffAttrType.SUMMON)

	local transfer = event.data.transfer or {}
	local params = {}

	if #items > 0 then
		for i in ipairs(items) do
			if items[i].item_id and items[i].item_id ~= 0 then
				if xyd.arrayIndexOf(self.bigItems, items[i].item_id) then
					table.insert(self.activityData.detail.records, items[i].item_id)
				end

				table.insert(params, {
					item_num = items[i].item_num,
					item_id = items[i].item_id,
					index = i
				})
			end
		end
	end

	local hasGotAll = true

	for _, itemID in ipairs(self.bigItems) do
		if xyd.arrayIndexOf(self.activityData.detail.records, itemID) <= 0 then
			hasGotAll = false

			break
		end
	end

	if hasGotAll then
		self.activityData.detail.records = {}
	end

	self:initAwardItems(true)

	for i = 1, #params do
		local itemID = params[i].item_id
		local quality = xyd.tables.itemTable:getQuality(itemID)

		if tonumber(quality) >= 6 then
			params[i].cool = 1
			haveCool = true
		else
			params[i].cool = 0
		end
	end

	for i, itemData in ipairs(params) do
		if transfer[itemData.index] and transfer[itemData.index] == 1 then
			local dressId = xyd.tables.senpaiDressItemTable:getDressId(itemData.item_id)
			local debrisData = xyd.tables.senpaiDressTable:getDressHand(dressId)
			local index = itemData.index
			params[i] = {
				item_num = debrisData[2],
				item_id = debrisData[1],
				index = index,
				cool = itemData.cool
			}
		end
	end

	local name = nil

	if #params == 1 then
		if haveCool then
			name = "dress_gacha_02"
		else
			name = "dress_gacha_01"
		end
	elseif haveCool then
		name = "dress_gacha_04"
	else
		name = "dress_gacha_03"
	end

	local function skipCallBack()
		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			wnd_type = 5,
			type = 2,
			data = params
		}, function ()
			self.summonTen_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		end)
		self:updateBreakNum()
		self:updateFreeTimes()
	end

	local activityData = xyd.models.summon
	local skip = activityData:getDressSkipAnimation()

	if skip then
		skipCallBack()
	else
		xyd.openWindow("dress_summon_effect_res_window", {
			callback = skipCallBack,
			animationName = name
		})
	end
end

return DressSummonWindow
