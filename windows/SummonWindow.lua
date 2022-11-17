local MIDDLETYPE = {
	SENIOR = 1,
	WISH = 2
}
local BaseWindow = import(".BaseWindow")
local SummonWindow = class("SummonWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local Partner = import("app.models.Partner")
local CountDown = import("app.components.CountDown")
local Summon = xyd.models.summon
local SummonTable = xyd.tables.summonTable

function SummonWindow:ctor(name, params)
	self.isWish = false
	self.middleConType = -1
	local wishData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)

	if wishData and xyd.getServerTime() < wishData:getEndTime() then
		self.isWish = true
		self.middleConType = MIDDLETYPE.WISH
	end

	if params and params.labelIndex then
		self.middleConType = params.labelIndex
	end

	BaseWindow.ctor(self, name, params)

	self.animationList_ = {}
	self.is_base_free = false
	self.is_senior_free = false
	self.is_wish_free = false
	self.skipAnimation = false
	self.isItemChange = false
	self.isSummon = false
	self.collectionBefore = {}
	params = params or {}
	self.hideBottom = params.hideBottom or false
	self.fiftySummon = true
end

function SummonWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()

	local wishData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)

	if wishData and xyd.getServerTime() < wishData:getEndTime() then
		self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onRefreshWishTimes))
		self:getWishGroupUIComponent()
		self:initWishUIComponent()

		if xyd.GuideController.get():isGuideComplete() and self.middleConType == MIDDLETYPE.WISH then
			self:onNextPage()
			self:initWishGroup(2)
		else
			self:initWishGroup()
		end
	end

	if self:checkSummonGiftBagOpen() then
		self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onRefreshSeniorGiftBagText))
		self.eventProxy_:addEventListener(xyd.event.SUMMON, function ()
			xyd.models.activity:reqActivityByID(xyd.ActivityID.NEW_SUMMON_GIFTBAG)
		end)
		self:getSummonGiftUIComponent()
		self:initSummonGiftUIComponent()
	end

	self:initTop()
	self:onRefresh()
	self:registerEvent()
	self:initEntryBtn()
end

function SummonWindow:getUIComponent()
	local go = self.window_
	self.bg = go:ComponentByName("bg", typeof(UITexture))
	self.topGroup = go:NodeByName("funcGroup/topGroup").gameObject
	self.tips_button = go:ComponentByName("funcGroup/topGroup/tips_button", typeof(UISprite))
	self.baodi_progress = go:ComponentByName("funcGroup/topGroup/baodi_progress", typeof(UIProgressBar))
	self.baodi_progress_thumb = go:ComponentByName("funcGroup/topGroup/baodi_progress/thumb", typeof(UISprite))
	self.baodi_progress_label = go:ComponentByName("funcGroup/topGroup/baodi_progress/labelDisplay", typeof(UILabel))
	self.baodi_tips = go:ComponentByName("funcGroup/topGroup/baodi_tips", typeof(UISprite))
	self.baodi_summon = go:NodeByName("funcGroup/topGroup/baodi_summon").gameObject
	self.help_button = go:NodeByName("funcGroup/topGroup/help_button").gameObject
	self.prob_button = go:NodeByName("funcGroup/topGroup/prob_button").gameObject
	self.groupNormal = go:NodeByName("funcGroup/groupNormal").gameObject
	self.bgNormal = go:ComponentByName("funcGroup/groupNormal/bgNormal", typeof(UISprite))
	self.baseSummonTitle = go:ComponentByName("funcGroup/groupNormal/baseSummonTitle", typeof(UISprite))
	self.base_scroll_label = go:ComponentByName("funcGroup/groupNormal/base_scroll_label", typeof(UILabel))
	self.groupBaseFree = go:NodeByName("funcGroup/groupNormal/groupBaseFree").gameObject
	self.next_base_free_label = go:ComponentByName("funcGroup/groupNormal/groupBaseFree/next_base_free_label", typeof(UILabel))
	self.next_base_free_countdown = go:ComponentByName("funcGroup/groupNormal/groupBaseFree/next_base_free_countdown", typeof(UILabel))
	self.base_summon_one = go:NodeByName("funcGroup/groupNormal/base_summon_one").gameObject
	self.base_summon_ten = go:NodeByName("funcGroup/groupNormal/base_summon_ten").gameObject
	self.groupMiddle = go:NodeByName("funcGroup/groupMiddle").gameObject
	self.groupSenior = go:NodeByName("funcGroup/groupMiddle/groupSenior").gameObject
	self.bgSenior = self.groupSenior:ComponentByName("bgSenior", typeof(UISprite))
	self.seniorSummonTitle = self.groupSenior:ComponentByName("seniorSummonTitle", typeof(UISprite))
	self.senior_cost_group = self.groupSenior:NodeByName("senior_cost_group").gameObject
	self.senior_cost_label = self.senior_cost_group:ComponentByName("cost_label", typeof(UILabel))
	self.act_tips_text = self.groupSenior:ComponentByName("act_tips_text", typeof(UILabel))
	self.senior_inner_bg = self.groupSenior:ComponentByName("senior_inner_bg", typeof(UIWidget))
	self.senior_switch_btn = self.groupSenior:NodeByName("senior_switch_btn").gameObject
	self.auto_altar_group = self.groupSenior:NodeByName("auto_altar_group").gameObject
	self.groupSeniorFree = self.groupSenior:NodeByName("groupSeniorFree").gameObject
	self.next_senior_free_label = self.groupSenior:ComponentByName("groupSeniorFree/next_senior_free_label", typeof(UILabel))
	self.next_senior_free_countdown = self.groupSenior:ComponentByName("groupSeniorFree/next_senior_free_countdown", typeof(UILabel))
	self.senior_summon_one = self.groupSenior:NodeByName("senior_summon_one").gameObject
	self.senior_summon_ten = self.groupSenior:NodeByName("senior_summon_ten").gameObject
	self.senior_cost_group = self.groupSenior:NodeByName("senior_cost_group").gameObject
	self.activityEntryBtn = self.groupSenior:NodeByName("activityEntryBtn").gameObject
	self.activityEntryBtn_label = self.groupSenior:ComponentByName("activityEntryBtn/activityEntryBtn_label", typeof(UILabel))
	self.entryBtn = self.groupSenior:NodeByName("entryBtn").gameObject
	self.entryBtn_label = self.groupSenior:ComponentByName("entryBtn/entryBtn_label", typeof(UILabel))
	self.tipsLabel = self.groupSenior:ComponentByName("tipsLabel", typeof(UILabel))
	self.seniorBuyBtn_ = self.groupSenior:NodeByName("seniorBuyBtn_").gameObject
	self.record_button = self.groupSenior:NodeByName("record_button").gameObject
	self.btnLeft_ = go:NodeByName("funcGroup/groupMiddle/btnLeft_").gameObject
	self.btnLeft_redPoint = go:NodeByName("funcGroup/groupMiddle/btnLeft_/leftRedPoint").gameObject
	self.btnRight_ = go:NodeByName("funcGroup/groupMiddle/btnRight_").gameObject
	self.btnRight_redPoint = go:NodeByName("funcGroup/groupMiddle/btnRight_/rightRedPoint").gameObject
	self.dragMask = go:NodeByName("funcGroup/groupMiddle/dragMask").gameObject
	self.dotGroup = go:NodeByName("funcGroup/groupMiddle/dotGroup").gameObject
	self.dot_1 = self.dotGroup:ComponentByName("dot1", typeof(UISprite))
	self.dot_2 = self.dotGroup:ComponentByName("dot2", typeof(UISprite))
	self.groupFriend = go:NodeByName("funcGroup/groupFriend").gameObject
	self.bgFriend = go:ComponentByName("funcGroup/groupFriend/bgFriend", typeof(UISprite))
	self.friendSummonTitle = go:ComponentByName("funcGroup/groupFriend/friendSummonTitle", typeof(UISprite))
	self.friend_scroll_label = go:ComponentByName("funcGroup/groupFriend/friend_scroll_label", typeof(UILabel))
	self.friend_summon_one = go:NodeByName("funcGroup/groupFriend/friend_summon_one").gameObject
	self.friend_summon_ten = go:NodeByName("funcGroup/groupFriend/friend_summon_ten").gameObject
	self.bgBottom_ = go:ComponentByName("bgBottom_", typeof(UIWidget))
	self.windowMask = go:NodeByName("windowMask").gameObject
	self.groupWish = go:NodeByName("funcGroup/groupMiddle/groupWish").gameObject
	self.limit_summon_ten = self.groupWish:NodeByName("limit_summon_ten").gameObject
	self.groupLimitFree = self.groupWish:NodeByName("groupLimitFree").gameObject
	self.limit_cost_group = self.groupWish:NodeByName("limit_cost_group").gameObject
	self.limit_cost_scroll_label = self.limit_cost_group:ComponentByName("cost_label_1", typeof(UILabel))
	self.limit_cost_ten_label = self.limit_cost_group:ComponentByName("cost_label_2", typeof(UILabel))
	self.limitBuyBtn = self.limit_cost_group:NodeByName("limitBuyBtn").gameObject
	self.limitEndBtn = self.limit_cost_group:NodeByName("limitEndBtn").gameObject
	self.limitEndLabel = self.limit_cost_group:NodeByName("limit_end_label").gameObject
	self.costBgImg = self.groupWish:NodeByName("costBgImg").gameObject
end

function SummonWindow:initUIComponent()
	xyd.setUISpriteAsync(self.seniorSummonTitle, nil, "senior_summon_title_" .. xyd.Global.lang, function ()
		self.seniorSummonTitle:MakePixelPerfect()
	end)
	xyd.setUISpriteAsync(self.baseSummonTitle, nil, "base_summon_title_" .. xyd.Global.lang, function ()
		self.baseSummonTitle:MakePixelPerfect()
	end)
	xyd.setUISpriteAsync(self.friendSummonTitle, nil, "friend_summon_title_" .. xyd.Global.lang, function ()
		self.friendSummonTitle:MakePixelPerfect()
	end)

	if xyd.getServerTime() >= 1673568000 then
		xyd.setUISpriteAsync(self.bgSenior, nil, "summon_super_bg2")
	elseif xyd.getServerTime() >= 1671148800 then
		xyd.setUISpriteAsync(self.bgSenior, nil, "summon_super_bg_3")
	else
		xyd.setUISpriteAsync(self.bgSenior, nil, "summon_super_bg")
	end

	self.skipAnimation = Summon:getSkipAnimation()

	if self.skipAnimation then
		xyd.setUISprite(self.tips_button, nil, "battle_img_skip")
	else
		xyd.setUISprite(self.tips_button, nil, "btn_max")
	end

	self.base_scroll_label.text = Summon:getBaseScrollNum()
	self.senior_cost_label.text = Summon:getSeniorScrollNum()
	self.limit_cost_scroll_label.text = Summon:getSeniorScrollNum()
	self.limit_cost_ten_label.text = Summon:getLimitTenScrollNum()
	self.friend_scroll_label.text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.FRIEND_LOVE))

	xyd.setUITextureByName(self.bg, "summon_scene", false)

	local width = math.min(self.window_:GetComponent(typeof(UIPanel)).width, 1000)

	self.topGroup:SetLocalPosition(width, 462, 0)
	self.groupNormal:SetLocalPosition(-width, 301, 0)
	self.groupSenior:SetLocalPosition(width, 0, 0)
	self.groupFriend:SetLocalPosition(-width, -464, 0)
	self.windowMask:SetActive(false)
end

function SummonWindow:initTop()
	local function closecallback()
		self:onClickCloseButton()
	end

	self.windowTop = WindowTop.new(self.window_, self.name_, nil, true, closecallback)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.SENIOR_SUMMON_SCROLL
		}
	}

	self.windowTop:setItem(items)
end

function SummonWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.SUMMON, handler(self, self.onSummonEvent))
	self.eventProxy_:addEventListener(xyd.event.SUMMON_WISH, handler(self, self.onSummonEvent))
	self.eventProxy_:addEventListener(xyd.event.SUMMON_WISH, function ()
		xyd.models.activity:reqActivityByID(xyd.ActivityID.WISH_CAPSULE)
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_SUMMON_INFO, handler(self, self.onRefresh))
	self.eventProxy_:addEventListener(xyd.event.ITEM_EXCHANGE, handler(self, self.onRefresh))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))

	self.timer_ = Timer.New(handler(self, self.updateTimer), 1, -1, false)

	self.timer_:Start()
	xyd.setDarkenBtnBehavior(self.prob_button, self, function ()
		xyd.WindowManager.get():openWindow("summon_drop_probability_window")
	end)
	xyd.setDarkenBtnBehavior(self.base_summon_one, self, function ()
		self:onBaseSummon(1)
	end)
	xyd.setDarkenBtnBehavior(self.base_summon_ten, self, function ()
		self:onBaseSummon(10)
	end)
	xyd.setDarkenBtnBehavior(self.senior_summon_one, self, function ()
		self:onSeniorSummon(1)
	end)
	xyd.setDarkenBtnBehavior(self.senior_summon_ten, self, function ()
		self:onSeniorSummon(10)
	end)
	xyd.setDarkenBtnBehavior(self.friend_summon_one, self, function ()
		self:onFriendSummon(1)
	end)
	xyd.setDarkenBtnBehavior(self.friend_summon_ten, self, function ()
		self:onFriendSummon(10)
	end)
	xyd.setDarkenBtnBehavior(self.limit_summon_ten, self, function ()
		self:onLimitSummonTen()
	end)
	xyd.setDarkenBtnBehavior(self.baodi_summon, self, self.onBaodiSummon)
	xyd.setDarkenBtnBehavior(self.baodi_tips.gameObject, self, self.onbaoditips)
	xyd.setDarkenBtnBehavior(self.help_button, self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SUMMON_HELP_1"
		})
	end)
	xyd.setDarkenBtnBehavior(self.tips_button.gameObject, self, self.onClickSkip)
	xyd.setDarkenBtnBehavior(self.seniorBuyBtn_, self, function ()
		xyd.openWindow("buy_senior_scroll_window")
	end)
	xyd.setDarkenBtnBehavior(self.limitBuyBtn, self, function ()
		xyd.openWindow("buy_senior_scroll_window")
	end)
	xyd.setDarkenBtnBehavior(self.record_button, self, function ()
		xyd.WindowManager.get():openWindow("summon_record_window")
	end)
end

function SummonWindow:checkEntryOpen()
	if not xyd.GuideController.get():isGuideComplete() then
		return false
	end

	return false
end

function SummonWindow:checkSummonGiftBagOpen()
	local summonGiftData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_SUMMON_GIFTBAG)

	if summonGiftData and xyd.getServerTime() < summonGiftData:getEndTime() then
		return true
	else
		return false
	end
end

function SummonWindow:initEntryBtn()
	self.activityEntryBtn:SetActive(false)

	if self:checkEntryOpen() then
		if not self.entryEffect then
			self.entryEffect = xyd.Spine.new(self.entryBtn)

			self.entryEffect:setInfo("fx_ui_warmup_entrance_kaixi", function ()
				self.entryEffect:SetLocalPosition(0, 10, 0)
				self.entryEffect:play("idle", 0)
			end)
		end

		UIEventListener.Get(self.entryBtn).onClick = function ()
			local msg = messages_pb.log_partner_warmup_req()
			msg.activity_id = xyd.ActivityID.NEW_PARTNER_WARMUP
			msg.type_id = 1

			xyd.Backend.get():request(xyd.mid.LOG_PARTNER_WARMUP, msg)
			xyd.openWindow("new_partner_warming_up_entry_window", {})
		end

		self.entryBtn:SetActive(true)

		self.entryBtn_label.text = __("NEW_PARTNER_WARMING_UP_ENTRANCE")
	elseif xyd.models.activity:getActivity(xyd.ActivityID.ENERGY_SUMMON) then
		local data = xyd.models.activity:getActivity(xyd.ActivityID.ENERGY_SUMMON)

		self.activityEntryBtn:SetActive(true)

		self.activityEntryBtn_label.text = __("ACTIVITY_ENERGY_SUMMON_ENTRY_LABEL")

		xyd.setDarkenBtnBehavior(self.activityEntryBtn, self, function ()
			xyd.openWindow("activity_energy_summon_window")

			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.ENERGY_SUMMON * 100 + 3

			xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)
		end)
	end

	if xyd.tables.miscTable:getNumber("warmup_no_partner", "value") <= xyd.getServerTime() then
		self.tipsLabel:SetActive(false)
	end

	if xyd.getServerTime() < xyd.tables.miscTable:getNumber("warmup_no_partner", "value") then
		self.tipsLabel:SetActive(true)

		self.tipsLabel.text = __("NEW_PARTNER_WARMUP_NO_PARTNER_TIPS")
	end

	if xyd.models.activity:getActivity(xyd.ActivityID.NEW_SUMMON_GIFTBAG) then
		self.tipsLabel:SetActive(false)
	end
end

function SummonWindow:onWarmUpClose(event)
	local win_name = event.params.windowName

	if win_name ~= "new_partner_warming_up_entry_window" then
		return
	end

	if self.entryEffect then
		self.entryEffect:play("click", 1, nil, function ()
			self.entryEffect:play("idle", 0)
		end)
	end
end

function SummonWindow:onClickSkip()
	self.skipAnimation = not self.skipAnimation

	if self.skipAnimation then
		xyd.setUISprite(self.tips_button, nil, "battle_img_skip")
	else
		xyd.setUISprite(self.tips_button, nil, "btn_max")
	end

	Summon:setSkipAnimation(self.skipAnimation)
end

function SummonWindow:onSummonEvent(event)
	self.isSummon = true

	if not self.isItemChange then
		self.summonEvent = event
	else
		self:onSummon(event)

		self.isSummon = false
		self.summonEvent = nil
	end

	local summon_id = event.data.summon_id

	if summon_id == xyd.SummonType.SENIOR_FREE or summon_id == xyd.SummonType.WISH_FREE then
		xyd.models.summon:updateRedPoint()
	end

	if summon_id == xyd.SummonType.ACT_LIMIT_TEN then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.WISH_CAPSULE)
	end

	self.senior_summon_one:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	self.senior_summon_ten:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

	if self.wish_summon_one then
		self.wish_summon_one:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end

	if self.wish_summon_ten then
		self.wish_summon_ten:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end

	self.base_summon_one:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	self.base_summon_ten:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	self.limit_summon_ten:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
end

function SummonWindow:onItemChange()
	self.isItemChange = true

	if self.isSummon then
		self:onSummon(self.summonEvent)
	end
end

function SummonWindow:onRefresh(summonIndex)
	self:updateTimer()

	local summonType = xyd.SummonType
	local baseScrollNum = Summon:getBaseScrollNum()
	local seniorScrollNum = Summon:getSeniorScrollNum()
	self.oldBaodiEnergy = self.baodi_progress_value or 0
	local baodiEnergyNum = Summon:getBaodiEnergyNum()
	self.base_scroll_label.text = baseScrollNum
	self.senior_cost_label.text = seniorScrollNum
	self.limit_cost_scroll_label.text = Summon:getSeniorScrollNum()
	self.limit_cost_ten_label.text = Summon:getLimitTenScrollNum()
	self.friend_scroll_label.text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.FRIEND_LOVE))

	self:setSummonBtn(self.base_summon_ten, {
		xyd.ItemID.BASE_SUMMON_SCROLL,
		10
	}, __("SUMMON_X_TIME", 10))

	local friendCost1 = SummonTable:getCost(summonType.FRIEND)
	local friendCost10 = SummonTable:getCost(summonType.FRIEND_TEN)

	self:setSummonBtn(self.friend_summon_one, friendCost1, __("SUMMON_X_TIME", 1))
	self:setSummonBtn(self.friend_summon_ten, friendCost10, __("SUMMON_X_TIME", 10))

	if self.is_base_free then
		self:setSummonLabel(self.base_summon_one, __("FREE3"), __("SUMMON_X_TIME", 1))
	else
		self:setSummonBtn(self.base_summon_one, {
			xyd.ItemID.BASE_SUMMON_SCROLL,
			1
		}, __("SUMMON_X_TIME", 1))
	end

	if self.is_senior_free then
		self:setSummonLabel(self.senior_summon_one, __("FREE3"), __("SUMMON_X_TIME2", 1))
	elseif seniorScrollNum < 1 and xyd.Global.lang ~= "ja_jp" then
		local cost = SummonTable:getCost(summonType.SENIOR_CRYSTAL)

		self:setSummonBtn(self.senior_summon_one, cost, __("SUMMON_X_TIME2", 1))
	else
		self:setSummonBtn(self.senior_summon_one, {
			xyd.ItemID.SENIOR_SUMMON_SCROLL,
			1
		}, __("SUMMON_X_TIME2", 1))
	end

	if seniorScrollNum < 10 and xyd.Global.lang ~= "ja_jp" then
		local cost = SummonTable:getCost(summonType.SENIOR_CRYSTAL_TEN)

		self:setSummonBtn(self.senior_summon_ten, cost, __("SUMMON_X_TIME2", 10))
	else
		self:setSummonBtn(self.senior_summon_ten, {
			xyd.ItemID.SENIOR_SUMMON_SCROLL,
			10
		}, __("SUMMON_X_TIME2", 10))
	end

	local baodiCost = SummonTable:getCost(summonType.BAODI)

	self:refreshBaodi()

	self.baodi_progress.value = math.min(1, baodiEnergyNum / baodiCost[2])
	self.baodi_progress_value = baodiEnergyNum
	self.baodi_progress_label.text = baodiEnergyNum .. "/" .. baodiCost[2]

	if self.isWish then
		self:refreshWishGroup()
	end

	self:refreshLimitTen(summonIndex)
end

function SummonWindow:refreshBaodi()
	local baodiEnergyNum = Summon:getBaodiEnergyNum()
	local baodiCost = SummonTable:getCost(xyd.SummonType.BAODI)
	local vipNeed = SummonTable:getVipNeed(xyd.SummonType.BAODI)
	local vip = xyd.models.backpack:getVipLev()

	if not self.effect1 then
		self.effect1 = xyd.Spine.new(self.baodi_progress_thumb.gameObject)

		self.effect1:setInfo("fx_ui_niudanfaguang", function ()
			self.effect1:setRenderTarget(self.baodi_progress_thumb:GetComponent(typeof(UIWidget)), 1)
			self.effect1:SetLocalScale(0.9, 1, 1)
			self.effect1:SetLocalPosition(-20, 2, 0)
		end)
	end

	if not self.effect2 then
		self.effect2 = xyd.Spine.new(self.baodi_summon)

		self.effect2:setInfo("fx_ui_niudan", function ()
			self.effect2:SetLocalScale(1, 1, 1)
			self.effect2:setRenderTarget(self.baodi_summon:GetComponent(typeof(UIWidget)), 1)
		end)
	end

	if baodiEnergyNum < baodiCost[2] or vip < vipNeed then
		self.baodi_tips:SetActive(true)
		self.baodi_summon:SetActive(false)
		self.effect1:stop()
		self.effect1:SetActive(false)
		self.effect2:stop()
		self.effect2:SetActive(false)
	else
		self.baodi_tips:SetActive(false)
		self.baodi_summon:SetActive(true)
		self.effect1:play("texiao01", 0, 1, nil, true)
		self.effect2:play("texiao01", 0, 1, nil, true)
	end
end

function SummonWindow:isHasNew5Stars(event)
	local partners = event.data.summon_result.partners
	local new5stars = {}
	local wishData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)
	local wishID = -1

	if wishData and wishData.detail and wishData.detail.select_id then
		wishID = wishData.detail.select_id
	end

	local i = 1

	while i <= #partners do
		local np = Partner.new()

		np:populate(partners[i])

		local shows = xyd.tables.miscTable:split2num("activity_gacha_partner_show", "value", "|")

		if np:getStar() == 5 and not self.collectionBefore[np:getTableID()] or table.indexof(shows, np:getTableID()) or np:getTableID() == wishID then
			table.insert(new5stars, partners[i])
		end

		i = i + 1
	end

	return new5stars
end

function SummonWindow:onSummon(event)
	local new5stars = self:isHasNew5Stars(event)

	local function effectCallBack()
		self.topGroup:SetLocalPosition(0, 462, 0)
		self.groupNormal:SetLocalPosition(0, 301, 0)
		self.groupMiddle:X(0)
		self.groupFriend:SetLocalPosition(0, -464, 0)
		xyd.WindowManager.get():closeWindow("summon_res_window")

		local summonIndex = tonumber(event.data.index) or 0

		self:onRefresh(summonIndex)

		local has5star = false
		local partners = event.data.summon_result.partners or {}
		local items = {}

		for i, partner in ipairs(partners) do
			local item_id = partner.table_id
			local star = xyd.tables.partnerTable:getStar(item_id)

			if star == 5 then
				has5star = true
			end

			table.insert(items, {
				item_num = 1,
				item_id = item_id,
				partnerId = partner.partner_id
			})
		end

		local freeType = {
			self.is_base_free,
			self.is_senior_free,
			[5] = self.is_wish_free
		}
		local params = {
			items = items,
			progressValue = Summon:getBaodiEnergyNum(),
			oldBaodiEnergy = self.oldBaodiEnergy,
			type = self.lastSummonType,
			free = freeType[self.lastSummonType],
			summonIndex = tonumber(event.data.index) or 0,
			summonId = tonumber(event.data.summon_id) or 0
		}

		if xyd.WindowManager.get():isOpen("summon_result_window") then
			local win = xyd.WindowManager.get():getWindow("summon_result_window")

			win:updateWindow(params)
		else
			xyd.WindowManager.get():openWindow("summon_result_window", params)
		end

		if has5star then
			local evaluate_have_closed = xyd.db.misc:getValue("evaluate_have_closed") or false
			local lastTime = xyd.db.misc:getValue("evaluate_last_time") or 0

			if not evaluate_have_closed and lastTime and xyd.getServerTime() - lastTime > 3 * xyd.DAY_TIME then
				local win = xyd.getWindow("main_window")

				win:setHasEvaluateWindow(true, xyd.EvaluateFromType.FIVE_STAR)
			end
		end

		self:allowClick()
	end

	if xyd.isIosTest() then
		new5stars = {}
	end

	local summonIndex = tonumber(event.data.index) or 0

	if self.skipAnimation or summonIndex > 0 then
		if xyd.WindowManager.get():isOpen("summon_result_window") then
			local win = xyd.WindowManager.get():getWindow("summon_result_window")

			win:playDisappear(function ()
				if #new5stars > 0 then
					xyd.WindowManager.get():openWindow("summon_res_window", {}, function (reswin)
						if reswin then
							reswin:playEffect(new5stars, event.data.summon_id, effectCallBack, true, "summon_window")
						else
							effectCallBack()
						end
					end)
				else
					effectCallBack()
				end
			end, self.lastSummonType, summonIndex)
		elseif #new5stars > 0 then
			xyd.WindowManager.get():openWindow("summon_res_window", {}, function (reswin)
				if reswin then
					reswin:playEffect(new5stars, event.data.summon_id, effectCallBack, true, "summon_window")
				else
					effectCallBack()
				end
			end)
		else
			effectCallBack()
		end
	else
		self:playAnimation(function ()
			xyd.WindowManager.get():openWindow("summon_res_window", {}, function (win)
				if win then
					win:playEffect(event.data.summon_result.partners, event.data.summon_id, effectCallBack, false, "summon_window")
				else
					effectCallBack()
				end
			end)
		end)
	end

	self:updateActTips()
end

function SummonWindow:playAnimation(callback)
	local sequence = self:getSequence()

	table.insert(self.animationList_, sequence)
	sequence:Append(self.topGroup.transform:DOLocalMoveY(-862, 0.2))
	sequence:Insert(0, self.groupNormal.transform:DOLocalMoveX(-900, 0.2))
	sequence:Insert(0, self.groupMiddle.transform:DOLocalMoveX(900, 0.2))
	sequence:Insert(0, self.groupFriend.transform:DOLocalMoveX(-900, 0.2))
	sequence:AppendCallback(callback)
end

function SummonWindow:playOpenAnimation(callback)
	local function setter(value)
		self.bgBottom_.alpha = value
	end

	local function bgSetter(value)
		self.bg.alpha = value
	end

	local wishData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)

	if wishData and xyd.getServerTime() < wishData:getEndTime() and self.middleConType == MIDDLETYPE.WISH and xyd.GuideController.get():isGuideComplete() then
		self.groupSenior.transform:X(-710)
	end

	self:waitForFrame(1, function ()
		local sequence = self:getSequence(function ()
			self:setWndComplete()
		end)

		sequence:Append(self.topGroup.transform:DOLocalMoveX(-50, 0.3))
		sequence:Append(self.topGroup.transform:DOLocalMoveX(0, 0.27))
		sequence:Insert(0, self.groupNormal.transform:DOLocalMoveX(50, 0.3))
		sequence:Insert(0.3, self.groupNormal.transform:DOLocalMoveX(0, 0.27))

		if wishData and xyd.getServerTime() < wishData:getEndTime() then
			if xyd.GuideController.get():isGuideComplete() and self.middleConType == MIDDLETYPE.WISH then
				self.groupSenior.transform:X(-710)
				sequence:Insert(0, self.groupWish.transform:DOLocalMoveX(-50, 0.3))
				sequence:Insert(0.3, self.groupWish.transform:DOLocalMoveX(0, 0.27))
			else
				sequence:Insert(0, self.groupSenior.transform:DOLocalMoveX(-50, 0.3))
				sequence:Insert(0.3, self.groupSenior.transform:DOLocalMoveX(0, 0.27))
			end
		else
			sequence:Insert(0, self.groupSenior.transform:DOLocalMoveX(-50, 0.3))
			sequence:Insert(0.3, self.groupSenior.transform:DOLocalMoveX(0, 0.27))
		end

		sequence:Insert(0, self.groupFriend.transform:DOLocalMoveX(50, 0.3))
		sequence:Insert(0.3, self.groupFriend.transform:DOLocalMoveX(0, 0.27))

		if self.hideBottom then
			sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.2))
		end

		sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(bgSetter), 0.01, 0.3, 0.2))
		sequence:AppendCallback(callback)
	end, nil)
end

function SummonWindow:willClose()
	BaseWindow.willClose(self)

	if self.timer_ then
		self.timer_:Stop()
	end

	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end
end

function SummonWindow:onbaoditips()
	xyd.WindowManager.get():openWindow("help_window", {
		key = "SUMMON_HELP_3"
	})
end

function SummonWindow:onFriendSummon(num)
	self.collectionBefore = xyd.deepCopy(xyd.models.slot:getCollection())
	self.isItemChange = false
	self.isSummon = false
	local heartNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.FRIEND_LOVE)
	local canSummonNum = xyd.models.slot:getCanSummonNum()

	if canSummonNum < num then
		xyd.openWindow("partner_slot_increase_window")

		return false
	end

	if num == 1 then
		local cost = SummonTable:getCost(xyd.SummonType.FRIEND)

		if cost[2] <= heartNum then
			self:summonPartner(xyd.SummonType.FRIEND)
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.FRIEND_LOVE)))

			return false
		end
	elseif num == 10 then
		local cost = SummonTable:getCost(xyd.SummonType.FRIEND_TEN)

		if cost[2] <= heartNum then
			self:summonPartner(xyd.SummonType.FRIEND_TEN)
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.FRIEND_LOVE)))

			return false
		end
	end

	self.lastSummonType = 4

	return true
end

function SummonWindow:onBaseSummon(num)
	self.collectionBefore = xyd.deepCopy(xyd.models.slot:getCollection())
	self.isItemChange = false
	self.isSummon = false
	local summonType = xyd.SummonType
	local baseScrollNum = Summon:getBaseScrollNum()
	local canSummonNum = xyd.models.slot:getCanSummonNum()

	if canSummonNum < num then
		xyd.openWindow("partner_slot_increase_window")

		return false
	end

	if num == 1 then
		if self.is_base_free then
			self:summonPartner(summonType.BASE_FREE)
		elseif num <= baseScrollNum then
			self:summonPartner(summonType.BASE)
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.BASE_SUMMON_SCROLL)))

			return false
		end
	elseif num == 10 and num <= baseScrollNum then
		self:summonPartner(summonType.BASE_TEN)
	else
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.BASE_SUMMON_SCROLL)))

		return false
	end

	self.lastSummonType = 1

	return true
end

function SummonWindow:onSeniorSummon(num, costType)
	self.collectionBefore = xyd.deepCopy(xyd.models.slot:getCollection())
	self.isItemChange = false
	self.isSummon = false
	local summonType = xyd.SummonType
	local seniorScrollNum = Summon:getSeniorScrollNum()
	local canSummonNum = xyd.models.slot:getCanSummonNum()
	local isFifty = Summon:getFiftySummonStatus()
	local index = 0

	if isFifty then
		index = Summon:getFiftySummonTimes() + 1
	end

	local val = 1

	if index == 1 then
		val = 5
	end

	local checkNum = num

	if num == 10 then
		checkNum = num * val
	end

	if canSummonNum < checkNum then
		xyd.openWindow("partner_slot_increase_window")

		return false
	end

	if costType then
		if costType == summonType.SENIOR_CRYSTAL then
			local cost = SummonTable:getCost(summonType.SENIOR_CRYSTAL)

			if cost[2] <= Summon:getCrystalNum() then
				local timeStamp = xyd.db.misc:getValue("summon_time_stamp")

				if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
					xyd.openWindow("gamble_tips_window", {
						type = "summon",
						wndType = self.curWindowType_,
						text = __("SUMMON_CONFIRM", 1, cost[2]),
						callback = function ()
							self:summonPartner(summonType.SENIOR_CRYSTAL)
						end
					})

					return
				else
					self:summonPartner(summonType.SENIOR_CRYSTAL)

					return true
				end
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

				return false
			end
		elseif costType == summonType.SENIOR_CRYSTAL_TEN then
			local cost = SummonTable:getCost(summonType.SENIOR_CRYSTAL_TEN)

			if cost[2] * val <= Summon:getCrystalNum() then
				local timeStamp = xyd.db.misc:getValue("summon_time_stamp")

				if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
					xyd.openWindow("gamble_tips_window", {
						type = "summon",
						wndType = self.curWindowType_,
						text = __("SUMMON_CONFIRM", 10 * val, cost[2] * val),
						callback = function ()
							self:summonPartner(summonType.SENIOR_CRYSTAL_TEN, nil, index)
						end
					})

					return
				else
					self:summonPartner(summonType.SENIOR_CRYSTAL_TEN, nil, index)

					return true
				end
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

				return false
			end
		elseif costType == summonType.SENIOR_SCROLL then
			if num <= seniorScrollNum then
				self:summonPartner(summonType.SENIOR_SCROLL)

				return true
			else
				if xyd.Global.lang ~= "ja_jp" then
					xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.SENIOR_SUMMON_SCROLL)))
				else
					xyd.alertConfirm(__("SENIOR_SCROLL_IF_BUY"), function ()
						xyd.WindowManager.get():openWindow("slot_window", {}, function ()
							if xyd.WindowManager.get():getWindow("summon_result_window") then
								xyd.WindowManager.get():closeWindow("summon_result_window")
							end

							xyd.WindowManager.get():openWindow("buy_senior_scroll_window")
						end)
					end, __("BUY"))
				end

				return false
			end
		elseif costType == summonType.SENIOR_SCROLL_TEN then
			if seniorScrollNum >= num * val then
				self:summonPartner(summonType.SENIOR_SCROLL_TEN, nil, index)

				return true
			else
				if xyd.Global.lang ~= "ja_jp" then
					xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.SENIOR_SUMMON_SCROLL)))
				else
					xyd.alertConfirm(__("SENIOR_SCROLL_IF_BUY"), function ()
						xyd.WindowManager.get():openWindow("slot_window", {}, function ()
							if xyd.WindowManager.get():getWindow("summon_result_window") then
								xyd.WindowManager.get():closeWindow("summon_result_window")
							end

							xyd.WindowManager.get():openWindow("buy_senior_scroll_window")
						end)
					end, __("BUY"))
				end

				return false
			end
		end
	end

	if num == 1 then
		if self.is_senior_free then
			self:summonPartner(summonType.SENIOR_FREE)
		elseif num <= seniorScrollNum then
			self:summonPartner(summonType.SENIOR_SCROLL)
		elseif xyd.Global.lang ~= "ja_jp" then
			local crystalNum = Summon:getCrystalNum()
			local SummonTable = SummonTable
			local cost = SummonTable:getCost(summonType.SENIOR_CRYSTAL)

			if cost[2] <= crystalNum then
				local timeStamp = xyd.db.misc:getValue("summon_time_stamp")

				if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
					xyd.openWindow("gamble_tips_window", {
						type = "summon",
						wndType = self.curWindowType_,
						text = __("SUMMON_CONFIRM", 1, cost[2]),
						callback = function ()
							self:summonPartner(summonType.SENIOR_CRYSTAL)
						end
					})
				else
					self:summonPartner(summonType.SENIOR_CRYSTAL)
				end
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

				return false
			end
		else
			xyd.alertConfirm(__("SENIOR_SCROLL_IF_BUY"), function ()
				xyd.WindowManager.get():openWindow("buy_senior_scroll_window")
			end, __("BUY"))

			return false
		end
	elseif num == 10 then
		if seniorScrollNum >= num * val then
			self:summonPartner(summonType.SENIOR_SCROLL_TEN, nil, index)
		elseif xyd.Global.lang ~= "ja_jp" then
			local crystalNum = Summon:getCrystalNum()
			local SummonTable = SummonTable
			local cost = SummonTable:getCost(summonType.SENIOR_CRYSTAL_TEN)

			if crystalNum >= cost[2] * val then
				local timeStamp = xyd.db.misc:getValue("summon_time_stamp")

				if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
					xyd.openWindow("gamble_tips_window", {
						type = "summon",
						wndType = self.curWindowType_,
						text = __("SUMMON_CONFIRM", 10 * val, cost[2] * val),
						callback = function ()
							self:summonPartner(summonType.SENIOR_CRYSTAL_TEN, nil, index)
						end
					})
				else
					self:summonPartner(summonType.SENIOR_CRYSTAL_TEN, nil, index)
				end
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

				return false
			end
		else
			xyd.alertConfirm(__("SENIOR_SCROLL_IF_BUY"), function ()
				xyd.WindowManager.get():openWindow("buy_senior_scroll_window")
			end, __("BUY"))

			return false
		end
	end

	self.lastSummonType = 2

	return true
end

function SummonWindow:onLimitSummonTen()
	local wishData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)

	if wishData == nil or wishData and wishData:getEndTime() < xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))

		return
	end

	if wishData and wishData.detail and wishData.detail.select_id and wishData.detail.select_id == 0 then
		xyd.WindowManager.get():openWindow("wish_capsule_select_window")

		return
	end

	self.collectionBefore = xyd.deepCopy(xyd.models.slot:getCollection())
	self.isItemChange = false
	self.isSummon = false
	local summonType = xyd.SummonType
	local limitTenScrollNum = Summon:getLimitTenScrollNum()
	local canSummonNum = xyd.models.slot:getCanSummonNum()

	if canSummonNum < 10 then
		xyd.openWindow("partner_slot_increase_window")

		return false
	end

	local cost = SummonTable:getCost(xyd.SummonType.ACT_LIMIT_TEN)

	if cost[2] <= limitTenScrollNum then
		self:summonPartner(summonType.ACT_LIMIT_TEN)

		self.lastSummonType = 8

		return true
	else
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

		return false
	end
end

function SummonWindow:onBaodiSummon()
	if xyd.Global.lang == "ja_jp" then
		xyd.GiftbagPushController2.get():clickGoldEgg()
	end

	self.collectionBefore = xyd.deepCopy(xyd.models.slot:getCollection())
	self.isItemChange = false
	self.isSummon = false
	local canSummonNum = xyd.models.slot:getCanSummonNum()

	if canSummonNum < 1 then
		xyd.openWindow("partner_slot_increase_window")

		return false
	end

	local summonType = xyd.SummonType

	self:summonPartner(summonType.BAODI)

	self.lastSummonType = 3

	return true
end

function SummonWindow:updateTimer()
	local summonType = xyd.SummonType
	local nowTime = xyd.getServerTime()
	local baseFreeTime = Summon:getBaseSummonFreeTime()
	local seniorFreeTime = Summon:getSeniorSummonFreeTime()
	local baseInterval = SummonTable:getFreeTimeInterval(summonType.BASE_FREE)
	local seniorInterval = SummonTable:getFreeTimeInterval(summonType.SENIOR_FREE)

	if baseInterval > nowTime - baseFreeTime then
		self.next_base_free_label.text = __("FREE2")
		self.next_base_free_countdown.text = xyd.secondsToString(baseFreeTime + baseInterval - nowTime)

		self.groupBaseFree:SetActive(true)

		self.is_base_free = false
	else
		self.next_base_free_label.text = __("FREE2")

		self.groupBaseFree:SetActive(false)

		self.is_base_free = true

		self:setSummonLabel(self.base_summon_one, __("FREE3"))
	end

	if nowTime - seniorFreeTime < SummonTable:getFreeTimeInterval(summonType.SENIOR_FREE) then
		self.next_senior_free_label.text = __("FREE2")
		self.next_senior_free_countdown.text = xyd.secondsToString(seniorFreeTime + seniorInterval - nowTime)

		self.groupSeniorFree:SetActive(true)

		self.is_senior_free = false
	else
		self.next_senior_free_label.text = __("FREE2")

		self.groupSeniorFree:SetActive(false)

		self.is_senior_free = true

		self:setSummonLabel(self.senior_summon_one, __("FREE3"))
	end

	if self.isWish then
		self:updateWishTimer()
	end
end

function SummonWindow:willCloseAnimation(callback)
	local width = math.min(self.window_:GetComponent(typeof(UIPanel)).width, 1000)
	local sequence = self:getSequence()

	sequence:Append(self.groupFriend.transform:DOLocalMoveX(-9, 0.14))
	sequence:Append(self.groupFriend.transform:DOLocalMoveX(-width, 0.15))
	sequence:Insert(0, self.groupMiddle.transform:DOLocalMoveX(-50, 0.14))
	sequence:Insert(0.14, self.groupMiddle.transform:DOLocalMoveX(width, 0.15))
	sequence:Insert(0, self.groupNormal.transform:DOLocalMoveX(50, 0.14))
	sequence:Insert(0.14, self.groupNormal.transform:DOLocalMoveX(-width, 0.15))
	sequence:Insert(0, self.topGroup.transform:DOLocalMoveX(-50, 0.14))
	sequence:Insert(0.3, self.topGroup.transform:DOLocalMoveX(width, 0.15))
	sequence:AppendCallback(function ()
		self.bg:SetActive(true)
		self.bgBottom_:SetActive(true)
		callback()
	end)
end

function SummonWindow:setSummonBtn(go, cost, text)
	local labelDisplay = go:ComponentByName("labelItemDisplay", typeof(UILabel))
	local costLabel = go:ComponentByName("labelItemCost", typeof(UILabel))
	local itemIcon = go:ComponentByName("itemIcon", typeof(UISprite))

	if text then
		labelDisplay.text = text

		if xyd.Global.lang == "de_de" and (text == __("SUMMON_X_TIME2", 10) or text == __("SUMMON_X_TIME2", 1)) then
			labelDisplay.fontSize = 18

			labelDisplay:SetLocalPosition(labelDisplay.transform.localPosition.x, 12, labelDisplay.transform.localPosition.z)
		end
	end

	if cost then
		costLabel.text = tostring(cost[2])

		itemIcon:SetActive(true)

		local sp = xyd.tables.itemTable:getSmallIcon(cost[1])

		xyd.setUISprite(itemIcon, nil, sp)

		local pos = costLabel.transform.localPosition

		costLabel:SetLocalPosition(15, pos.y, pos.z)
	end
end

function SummonWindow:setSummonLabel(go, text1, text2)
	local labelDisplay = go:ComponentByName("labelItemDisplay", typeof(UILabel))
	local costLabel = go:ComponentByName("labelItemCost", typeof(UILabel))
	local itemIcon = go:ComponentByName("itemIcon", typeof(UISprite))

	if text2 then
		labelDisplay.text = text2

		if xyd.Global.lang == "de_de" and (text2 == __("SUMMON_X_TIME2", 10) or text2 == __("SUMMON_X_TIME2", 1)) then
			labelDisplay.fontSize = 18

			labelDisplay:SetLocalPosition(labelDisplay.transform.localPosition.x, 12, labelDisplay.transform.localPosition.z)
		end
	end

	itemIcon:SetActive(false)

	costLabel.text = text1
	local pos = costLabel.transform.localPosition

	costLabel:SetLocalPosition(0, pos.y, pos.z)
end

function SummonWindow:initWishGroup(page)
	if page == nil then
		page = 1
	end

	xyd.setUISpriteAsync(self.wishSummonTitle, nil, "wish_capsule_summon_text01_" .. xyd.Global.lang)

	if xyd.getServerTime() < xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE):getUpdateTime() then
		local countDown = CountDown.new(self.wishTimeLabel, {
			duration = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE):getUpdateTime() - xyd.getServerTime()
		})
		self.wishEndLabel.text = __("END_TEXT")
	else
		self.wishEndLabel:SetActive(false)
		self.wishTimeLabel:SetActive(false)
	end

	if xyd.Global.lang == "de_de" then
		self.wishTimeLabel.fontSize = 16
		self.wishEndLabel.fontSize = 16
	end

	local limitTenLabel = self.groupLimitFree:ComponentByName("next_senior_free_label", typeof(UILabel))
	limitTenLabel.text = __("LIMITED_FOR_ACTIVITY")
	UIEventListener.Get(self.btnLeft_.gameObject).onClick = handler(self, self.onLastPage)
	UIEventListener.Get(self.btnRight_.gameObject).onClick = handler(self, self.onNextPage)

	UIEventListener.Get(self.record_button_wish).onClick = function ()
		xyd.WindowManager.get():openWindow("summon_record_window")
	end

	UIEventListener.Get(self.wishTipsBtn).onClick = function ()
		xyd.openWindow("wish_capsule_tips_window", {
			times = self.times
		})
	end

	UIEventListener.Get(self.wishExchangeBtn).onClick = function ()
		local wishData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)

		xyd.WindowManager.get():openWindow("wish_capsule_select_window", {
			titleText = "WISH_GACHA_TEXT11",
			selectChoiceId = wishData.detail.select_id
		})
	end

	self.wishExchangeBtnLabel.text = __("WISH_GACHA_TEXT9")

	self.dotGroup:SetActive(true)
	self.dragMask:SetActive(true)

	UIEventListener.Get(self.dragMask).onDragStart = function ()
		self.delta_ = 0
	end

	UIEventListener.Get(self.dragMask).onDrag = function (go, delta)
		self:onDrag(go, delta)
	end

	xyd.setDarkenBtnBehavior(self.wish_summon_one, self, function ()
		self:onWishSummon(1)
	end)
	xyd.setDarkenBtnBehavior(self.wish_summon_ten, self, function ()
		self:onWishSummon(10)
	end)

	if page == 1 then
		self:waitForTime(0.5, function ()
			self.btnLeft_:SetActive(false)
			self.btnRight_:SetActive(true)
			self:btnPageRedPointUpdate()
			self:playPage()
		end)
	else
		self:waitForTime(0.5, function ()
			self.btnLeft_:SetActive(true)
			self.btnRight_:SetActive(false)
			self:btnPageRedPointUpdate()
			self:playPage()
		end)
	end

	if xyd.Global.lang == "ja_jp" then
		xyd.setDarkenBtnBehavior(self.wishBuyBtn_, self, function ()
			xyd.openWindow("buy_senior_scroll_window")
		end)
		self.wishBuyBtn_:SetActive(true)
	end
end

function SummonWindow:btnPageRedPointUpdate()
	self.btnRight_redPoint:SetActive(self.is_wish_free)
	self.btnLeft_redPoint:SetActive(self.is_senior_free)
end

function SummonWindow:getWishGroupUIComponent()
	local go = self.window_
	self.groupWish = go:NodeByName("funcGroup/groupMiddle/groupWish").gameObject

	self.groupWish:SetActive(true)

	self.wishSummonTitle = self.groupWish:ComponentByName("wishSummonTitle", typeof(UISprite))
	self.wish_scroll_label = self.groupWish:ComponentByName("wish_scroll_label", typeof(UILabel))
	self.groupWishFree = self.groupWish:NodeByName("groupWishFree").gameObject
	self.next_wish_free_label = self.groupWish:ComponentByName("groupWishFree/next_wish_free_label", typeof(UILabel))
	self.next_wish_free_countdown = self.groupWish:ComponentByName("groupWishFree/next_wish_free_countdown", typeof(UILabel))
	self.wish_summon_one = self.groupWish:NodeByName("wish_summon_one").gameObject
	self.wish_summon_ten = self.groupWish:NodeByName("wish_summon_ten").gameObject
	self.record_button_wish = self.groupWish:NodeByName("record_button").gameObject
	self.wishBtnCon = self.groupWish:NodeByName("wishBtnCon").gameObject
	self.wishBtnImg = self.wishBtnCon:NodeByName("wishBtnImg").gameObject
	self.wishBtn_button_label = self.wishBtnCon:ComponentByName("button_label", typeof(UILabel))
	self.wishBtnEffectCon = self.wishBtnCon:NodeByName("wishBtnEffectCon").gameObject
	self.wishHeroCon = self.groupWish:NodeByName("wishHeroCon").gameObject
	self.wishHeroImg = self.wishHeroCon:NodeByName("wishHeroImg").gameObject
	self.wishHeroTouchField = self.wishHeroCon:NodeByName("wishHeroTouchField").gameObject

	self.wishHeroTouchField:SetActive(false)

	self.wishHeroEffectCon = self.wishHeroCon:NodeByName("wishHeroEffectCon").gameObject
	self.probLabel1 = self.wishHeroCon:ComponentByName("probLabel1", typeof(UILabel))
	self.probLabel2 = self.wishHeroCon:ComponentByName("probLabel2", typeof(UILabel))
	self.probLabel3 = self.wishHeroCon:ComponentByName("probLabel3", typeof(UILabel))
	self.probNum1 = self.wishHeroCon:ComponentByName("probNum1", typeof(UILabel))
	self.probNum2 = self.wishHeroCon:ComponentByName("probNum2", typeof(UILabel))
	self.probIcon = self.wishHeroCon:ComponentByName("probIcon", typeof(UISprite))
	self.wishTipsBtn = self.wishHeroCon:NodeByName("wishTipsBtn").gameObject
	self.psLabel = self.wishHeroCon:ComponentByName("psLabel", typeof(UILabel))
	self.wishBuyBtn_ = self.groupWish:NodeByName("wishBuyBtn_").gameObject
	self.wishTimeLabel = self.groupWish:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.wishEndLabel = self.groupWish:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.wishExchangeBtn = self.groupWish:NodeByName("wishExchangeBtn").gameObject
	self.wishExchangeBtnLabel = self.wishExchangeBtn:ComponentByName("button_label", typeof(UILabel))

	xyd.models.activity:reqActivityByID(xyd.ActivityID.WISH_CAPSULE)
	self:refreshWishEnterEffect()
end

function SummonWindow:refreshWishEnterEffect(isPlayGuangZhu)
	local wishData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)

	if not wishData then
		return
	end

	if wishData and wishData.detail and wishData.detail.select_id and wishData.detail.select_id == 0 then
		self.wishBtnCon:SetActive(true)
		self.wishHeroCon:SetActive(false)
		self.wishExchangeBtn:SetActive(false)

		self.wishBtn_button_label.text = __("WISH_GACHA_TIPS_2")

		xyd.setDarkenBtnBehavior(self.wishBtnImg, self, function ()
			if wishData == nil or wishData and wishData:getEndTime() < xyd.getServerTime() then
				xyd.alertTips(__("ACTIVITY_END_YET"))

				return
			end

			xyd.WindowManager.get():openWindow("wish_capsule_select_window")
		end)

		self.wishEffect = xyd.Spine.new(self.wishBtnEffectCon.gameObject)

		self.wishEffect:setInfo("fx_guanghuan", function ()
			self.wishEffect:setRenderTarget(self.wishBtnEffectCon:GetComponent(typeof(UITexture)), 1)
			self.wishEffect:play("texiao01", 0)
		end)
	elseif isPlayGuangZhu ~= nil and isPlayGuangZhu == true then
		if self.wishEffect then
			if self.wishEffect:getName() == "fx_guanghuan" then
				self.wishEffect:play("texiao02", 1, 1, function ()
					self.wishBtnImg:SetActive(false)
					self.wishEffect:destroy()

					self.wishEffect = xyd.Spine.new(self.wishBtnEffectCon.gameObject)

					self.wishEffect:setInfo("fx_guangzhu", function ()
						self.wishEffect:setRenderTarget(self.wishBtnEffectCon:GetComponent(typeof(UITexture)), 1)
						self.wishEffect:SetLocalPosition(0, -90, 0)
						self.wishEffect:play("texiao", 1, 1, function ()
							self.wishEffect:destroy()
							self:playWishHeroEffect()
						end)
					end)
				end)
			end
		else
			self:playWishHeroEffect()
		end
	elseif wishData and wishData.detail and wishData.detail.select_id then
		if self.wishEffect then
			self.wishEffect:destroy()
		end

		self:playWishHeroEffect()
	end
end

function SummonWindow:playWishHeroEffect()
	local wishData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)

	self.wishBtnCon:SetActive(false)
	self.wishHeroCon:SetActive(true)
	self.wishExchangeBtn:SetActive(true)

	self.probLabel1.text = __("WISH_GACHA_TEXT3")
	self.psLabel.text = ""
	local modelID = xyd.tables.partnerTable:getModelID(tonumber(wishData.detail.select_id))
	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)

	if modelID == 5501101 then
		self.wishHeroEffectCon:X(60)
	else
		self.wishHeroEffectCon:X(0)
	end

	if self.wishHeroeffect then
		self.wishHeroeffect:destroy()
	end

	self.wishHeroeffect = xyd.Spine.new(self.wishHeroEffectCon.gameObject)

	self.wishHeroeffect:setInfo(name, function ()
		self.wishHeroeffect:setRenderTarget(self.wishHeroEffectCon:GetComponent(typeof(UITexture)), 1)
		self.wishHeroeffect:SetLocalScale(scale, scale, scale)
		self.wishHeroeffect:play("idle", 0, 1)
	end)
	self.wishHeroTouchField:SetActive(true)

	UIEventListener.Get(self.wishHeroTouchField).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("partner_info", {
			notShowWays = true,
			table_id = wishData.detail.select_id
		})
	end)
end

function SummonWindow:refreshWishGroup()
	local seniorScrollNum = Summon:getSeniorScrollNum()
	self.wish_scroll_label.text = seniorScrollNum

	if self.is_wish_free then
		self:setSummonLabel(self.wish_summon_one, __("FREE3"), __("SUMMON_X_TIME2", 1))
	elseif seniorScrollNum < 1 and xyd.Global.lang ~= "ja_jp" then
		local cost = SummonTable:getCost(xyd.SummonType.WISH_CRYSTAL)

		self:setSummonBtn(self.wish_summon_one, cost, __("SUMMON_X_TIME2", 1))
	else
		self:setSummonBtn(self.wish_summon_one, {
			xyd.ItemID.SENIOR_SUMMON_SCROLL,
			1
		}, __("SUMMON_X_TIME2", 1))
	end

	if seniorScrollNum < 10 and xyd.Global.lang ~= "ja_jp" then
		local cost = SummonTable:getCost(xyd.SummonType.WISH_CRYSTAL_TEN)

		self:setSummonBtn(self.wish_summon_ten, cost, __("SUMMON_X_TIME2", 10))
	else
		self:setSummonBtn(self.wish_summon_ten, {
			xyd.ItemID.SENIOR_SUMMON_SCROLL,
			10
		}, __("SUMMON_X_TIME2", 10))
	end
end

function SummonWindow:onRefreshWishTimes(event)
	if event.data.activity_id ~= xyd.ActivityID.WISH_CAPSULE then
		return
	end

	local wishData = require("cjson").decode(event.data.act_info.detail)
	self.times = tonumber(wishData.times) or 0

	if self.times >= 100 then
		self.probLabel1:SetActive(true)
		self.probIcon:SetActive(true)
		self.probNum1:SetActive(true)

		self.probNum1.text = __("WISH_GACHA_NUM" .. tostring(math.floor(self.times / 100) + 5))
	else
		self.probLabel1:SetActive(false)
		self.probIcon:SetActive(false)
		self.probNum1:SetActive(false)
	end

	self.probNum2.text = self.times .. "/" .. __("WISH_GACHA_NUM" .. math.floor(self.times / 100) + 1)
	local temp_text = nil

	if self.times < 400 then
		temp_text = __("WISH_GACHA_TEXT4")

		if xyd.Global.lang == "en_en" then
			self.probNum2:X(-68)
			self.probLabel2:X(-60)
		elseif xyd.Global.lang == "fr_fr" then
			self.probNum2:X(-68)
			self.probLabel2:X(-60)
			self.probLabel2:Y(-253)
		elseif xyd.Global.lang == "de_de" then
			self.probNum2:X(-53)
			self.probLabel2:X(-45)
			self.probLabel2:Y(-253)
		elseif xyd.Global.lang == "zh_tw" then
			self.probNum2:X(-25)
			self.probLabel2:X(-17)
		elseif xyd.Global.lang == "ja_jp" then
			self.probNum2:X(-65)
			self.probLabel2:X(-57)
		elseif xyd.Global.lang == "ko_kr" then
			self.probNum2:X(-35)
			self.probLabel2:X(-27)
		end
	else
		temp_text = __("WISH_GACHA_TEXT5")

		if xyd.Global.lang == "en_en" then
			self.probNum2:X(-28)
			self.probLabel2:X(-20)
			self.probLabel2:Y(-254)
		elseif xyd.Global.lang == "fr_fr" then
			self.probNum2:X(-38)
			self.probLabel2:X(-30)
		elseif xyd.Global.lang == "ko_kr" then
			-- Nothing
		elseif xyd.Global.lang == "de_de" then
			self.probNum2:X(-53)
			self.probLabel2:X(-45)
			self.probLabel2:Y(-254)
		elseif xyd.Global.lang == "zh_tw" then
			self.probNum2:X(-10)
			self.probLabel2:X(-2)
		elseif xyd.Global.lang == "ja_jp" then
			self.probNum2:X(-45)
			self.probLabel2:X(-37)
		elseif xyd.Global.lang == "ko_kr" then
			self.probNum2:X(-25)
			self.probLabel2:X(-17)
		end
	end

	local probLabel2_text = xyd.split(temp_text, "|")
	self.probLabel2.text = probLabel2_text[1]
	self.probLabel3.text = probLabel2_text[2] or ""
end

function SummonWindow:onDrag(go, delta)
	self.delta_ = delta.x

	if self.delta_ > 50 and self.groupSenior.transform.localPosition.x == -710 then
		self:onLastPage()
	end

	if self.delta_ < -50 and self.groupSenior.transform.localPosition.x == 0 then
		self:onNextPage()
	end
end

function SummonWindow:onNextPage()
	self.btnLeft_:SetActive(true)
	self.btnRight_:SetActive(false)

	local sequence = self:getSequence()

	sequence:Append(self.groupSenior.transform:DOLocalMoveX(-710, 0.3))
	sequence:Insert(0, self.groupWish.transform:DOLocalMoveX(0, 0.3))
	xyd.setUISpriteAsync(self.dot_1, nil, "wish_capsule_dot0")
	xyd.setUISpriteAsync(self.dot_2, nil, "wish_capsule_dot1")
	self:btnPageRedPointUpdate()
end

function SummonWindow:onLastPage()
	self.btnLeft_:SetActive(false)
	self.btnRight_:SetActive(true)

	local sequence = self:getSequence()

	sequence:Append(self.groupSenior.transform:DOLocalMoveX(0, 0.3))
	sequence:Insert(0, self.groupWish.transform:DOLocalMoveX(710, 0.3))
	xyd.setUISpriteAsync(self.dot_1, nil, "wish_capsule_dot1")
	xyd.setUISpriteAsync(self.dot_2, nil, "wish_capsule_dot0")
	self:btnPageRedPointUpdate()
end

function SummonWindow:initWishUIComponent()
	local width = math.min(self.window_:GetComponent(typeof(UIPanel)).width, 1000)

	self.groupWish:SetLocalPosition(width, 0, 0)

	if xyd.Global.lang == "en_en" then
		-- Nothing
	elseif xyd.Global.lang == "fr_fr" then
		-- Nothing
	elseif xyd.Global.lang == "ja_jp" then
		-- Nothing
	elseif xyd.Global.lang == "ko_kr" then
		-- Nothing
	elseif xyd.Global.lang == "de_de" then
		self.probIcon:Y(-162)
		self.probNum1:Y(-172)
	end
end

function SummonWindow:onWishSummon(num, constType)
	local wishData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)

	if wishData == nil or wishData and wishData:getEndTime() < xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))

		return
	end

	if wishData and wishData.detail and wishData.detail.select_id and wishData.detail.select_id == 0 then
		xyd.WindowManager.get():openWindow("wish_capsule_select_window")

		return
	end

	self.collectionBefore = xyd.deepCopy(xyd.models.slot:getCollection())
	self.isItemChange = false
	self.isSummon = false
	local summonType = xyd.SummonType
	local seniorScrollNum = Summon:getSeniorScrollNum()
	local canSummonNum = xyd.models.slot:getCanSummonNum()

	if canSummonNum < num then
		xyd.openWindow("partner_slot_increase_window")

		return false
	end

	if constType then
		if constType == summonType.WISH_CRYSTAL then
			local cost = SummonTable:getCost(summonType.WISH_CRYSTAL)

			if cost[2] <= Summon:getCrystalNum() then
				local timeStamp = xyd.db.misc:getValue("wish_summon_time_stamp")

				if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
					xyd.openWindow("gamble_tips_window", {
						type = "wish_summon",
						text = __("SUMMON_CONFIRM", 1, cost[2]),
						callback = function ()
							self:summonPartner(summonType.WISH_CRYSTAL)
						end
					})

					return
				else
					self:summonPartner(summonType.WISH_CRYSTAL)

					return true
				end
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

				return false
			end
		elseif constType == summonType.WISH_CRYSTAL_TEN then
			local cost = SummonTable:getCost(summonType.WISH_CRYSTAL_TEN)

			if cost[2] <= Summon:getCrystalNum() then
				local timeStamp = xyd.db.misc:getValue("wish_summon_time_stamp")

				if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
					xyd.openWindow("gamble_tips_window", {
						type = "wish_summon",
						text = __("SUMMON_CONFIRM", 1, cost[2]),
						callback = function ()
							self:summonPartner(summonType.WISH_CRYSTAL_TEN)
						end
					})

					return
				else
					self:summonPartner(summonType.WISH_CRYSTAL_TEN)

					return true
				end
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

				return false
			end
		elseif constType == summonType.WISH_SCROLL then
			if num <= seniorScrollNum then
				self:summonPartner(summonType.WISH_SCROLL)

				return true
			else
				if xyd.Global.lang ~= "ja_jp" then
					xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.SENIOR_SUMMON_SCROLL)))
				else
					xyd.alertConfirm(__("SENIOR_SCROLL_IF_BUY"), function ()
						xyd.WindowManager.get():openWindow("slot_window", {}, function ()
							if xyd.WindowManager.get():getWindow("summon_result_window") then
								xyd.WindowManager.get():closeWindow("summon_result_window")
							end

							xyd.WindowManager.get():openWindow("buy_senior_scroll_window")
						end)
					end, __("BUY"))
				end

				return false
			end
		elseif constType == summonType.WISH_SCROLL_TEN then
			if num <= seniorScrollNum then
				self:summonPartner(summonType.WISH_SCROLL_TEN)

				return true
			else
				if xyd.Global.lang ~= "ja_jp" then
					xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.SENIOR_SUMMON_SCROLL)))
				else
					xyd.alertConfirm(__("SENIOR_SCROLL_IF_BUY"), function ()
						xyd.WindowManager.get():openWindow("slot_window", {}, function ()
							if xyd.WindowManager.get():getWindow("summon_result_window") then
								xyd.WindowManager.get():closeWindow("summon_result_window")
							end

							xyd.WindowManager.get():openWindow("buy_senior_scroll_window")
						end)
					end, __("BUY"))
				end

				return false
			end
		end
	end

	if num == 1 then
		if self.is_wish_free then
			self:summonPartner(summonType.WISH_FREE)
		elseif num <= seniorScrollNum then
			self:summonPartner(summonType.WISH_SCROLL)
		elseif xyd.Global.lang ~= "ja_jp" then
			local crystalNum = Summon:getCrystalNum()
			local SummonTable = SummonTable
			local cost = SummonTable:getCost(summonType.WISH_CRYSTAL)

			if cost[2] <= crystalNum then
				local timeStamp = xyd.db.misc:getValue("wish_summon_time_stamp")

				if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
					xyd.openWindow("gamble_tips_window", {
						type = "wish_summon",
						text = __("SUMMON_CONFIRM", 1, cost[2]),
						callback = function ()
							self:summonPartner(summonType.WISH_CRYSTAL)
						end
					})
				else
					self:summonPartner(summonType.WISH_CRYSTAL)
				end
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

				return false
			end
		else
			xyd.alertConfirm(__("SENIOR_SCROLL_IF_BUY"), function ()
				xyd.WindowManager.get():openWindow("buy_senior_scroll_window")
			end, __("BUY"))

			return false
		end
	elseif num == 10 then
		if num <= seniorScrollNum then
			self:summonPartner(summonType.WISH_SCROLL_TEN)
		elseif xyd.Global.lang ~= "ja_jp" then
			local crystalNum = Summon:getCrystalNum()
			local SummonTable = SummonTable
			local cost = SummonTable:getCost(summonType.WISH_CRYSTAL_TEN)

			if cost[2] <= crystalNum then
				local timeStamp = xyd.db.misc:getValue("wish_summon_time_stamp")

				if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
					xyd.openWindow("gamble_tips_window", {
						type = "wish_summon",
						text = __("SUMMON_CONFIRM", 1, cost[2]),
						callback = function ()
							self:summonPartner(summonType.WISH_CRYSTAL_TEN)
						end
					})
				else
					self:summonPartner(summonType.WISH_CRYSTAL_TEN)
				end
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

				return false
			end
		else
			xyd.alertConfirm(__("SENIOR_SCROLL_IF_BUY"), function ()
				xyd.WindowManager.get():openWindow("buy_senior_scroll_window")
			end, __("BUY"))

			return false
		end
	end

	self.lastSummonType = 5

	return true
end

function SummonWindow:updateWishTimer()
	local summonType = xyd.SummonType
	local nowTime = xyd.getServerTime()
	local wishFreeTime = Summon:getWishSummonFreeTime()
	local wishInterval = SummonTable:getFreeTimeInterval(summonType.WISH_FREE)

	if nowTime - wishFreeTime < SummonTable:getFreeTimeInterval(summonType.WISH_FREE) then
		self.next_wish_free_label.text = __("FREE2")
		self.next_wish_free_countdown.text = xyd.secondsToString(wishFreeTime + wishInterval - nowTime)

		self.groupWishFree:SetActive(true)

		self.is_wish_free = false
	else
		self.next_wish_free_label.text = __("FREE2")

		self.groupWishFree:SetActive(false)

		self.is_wish_free = true

		self:setSummonLabel(self.wish_summon_one, __("FREE3"))
	end
end

function SummonWindow:playPage()
	local positionLeft = -320
	local positionRight = 320

	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	function self.playAni2_()
		self.sequence2_ = self:getSequence()

		self.sequence2_:Insert(0, self.btnLeft_.transform:DOLocalMoveX(positionLeft - 10, 1))
		self.sequence2_:Insert(1, self.btnLeft_.transform:DOLocalMoveX(positionLeft + 10, 1))
		self.sequence2_:Insert(0, self.btnRight_.transform:DOLocalMoveX(positionRight + 10, 1))
		self.sequence2_:Insert(1, self.btnRight_.transform:DOLocalMoveX(positionRight - 10, 1))
		self.sequence2_:AppendCallback(function ()
			self.playAni1_()
		end)
	end

	function self.playAni1_()
		self.sequence1_ = self:getSequence()

		self.sequence1_:Insert(0, self.btnLeft_.transform:DOLocalMoveX(positionLeft - 10, 1))
		self.sequence1_:Insert(1, self.btnLeft_.transform:DOLocalMoveX(positionLeft + 10, 1))
		self.sequence1_:Insert(0, self.btnRight_.transform:DOLocalMoveX(positionRight + 10, 1))
		self.sequence1_:Insert(1, self.btnRight_.transform:DOLocalMoveX(positionRight - 10, 1))
		self.sequence1_:AppendCallback(function ()
			self.playAni2_()
		end)
	end

	self.playAni1_()
end

function SummonWindow:iosTestChangeUI()
	local go = self.window_

	go:ComponentByName("bgBottom_/bg_", typeof(UISprite)):SetActive(false)
	go:ComponentByName("bgBottom_/bg2_", typeof(UISprite)):SetActive(false)

	local iosBG = NGUITools.AddChild(go, "iosBG"):AddComponent(typeof(UITexture))
	iosBG.height = go:GetComponent(typeof(UIPanel)).height
	iosBG.width = go:GetComponent(typeof(UIPanel)).width

	xyd.setUITexture(iosBG, "Textures/texture_ios/bg_ios_test")
	xyd.setUISprite(self.tips_button, nil, "btn_max_ios_test")
	xyd.setUISprite(self.baodi_tips, nil, "baodi_tips_icon_ios_test")
	xyd.setUISprite(self.baodi_summon:GetComponent(typeof(UISprite)), nil, "baodi_tips_icon_ios_test")
	xyd.setUISprite(self.baodi_progress:ComponentByName("bg", typeof(UISprite)), nil, "summon_progressbar_bg_ios_test")
	xyd.setUISprite(self.baodi_progress_thumb, nil, "summon_prgressbar_thumb_ios_test")
	xyd.setUISprite(self.help_button:GetComponent(typeof(UISprite)), nil, "help_2_ios_test")
	xyd.setUISprite(self.prob_button:GetComponent(typeof(UISprite)), nil, "check_white_btn_ios_test")
	xyd.setUISprite(self.bgNormal, nil, "summon_normal_bg_ios_test")
	xyd.setUISprite(self.bgFriend, nil, "summon_friendly_bg_ios_test")
	xyd.setUISprite(self.bgSenior, nil, "summon_super_bg_ios_test")
	xyd.setUISprite(self.seniorSummonTitle, nil, "senior_summon_title_" .. xyd.Global.lang .. "_ios_test")
	xyd.setUISprite(self.baseSummonTitle, nil, "base_summon_title_" .. xyd.Global.lang .. "_ios_test")
	xyd.setUISprite(self.friendSummonTitle, nil, "friend_summon_title_" .. xyd.Global.lang .. "_ios_test")
	xyd.setUISprite(self.groupBaseFree:GetComponent(typeof(UISprite)), nil, "summon_normal_free_bg_ios_test")
	xyd.setUISprite(self.base_summon_one:GetComponent(typeof(UISprite)), nil, "summon_btn_bg_1_ios_test")
	xyd.setUISprite(self.base_summon_ten:GetComponent(typeof(UISprite)), nil, "summon_btn_bg_1_ios_test")
	xyd.setUISprite(self.groupSeniorFree:GetComponent(typeof(UISprite)), nil, "summon_super_free_bg_ios_test")
	xyd.setUISprite(self.senior_summon_one:GetComponent(typeof(UISprite)), nil, "summon_btn_bg_2_ios_test")
	xyd.setUISprite(self.senior_summon_ten:GetComponent(typeof(UISprite)), nil, "summon_btn_bg_2_ios_test")
	xyd.setUISprite(self.friend_summon_one:GetComponent(typeof(UISprite)), nil, "summon_btn_bg_1_ios_test")
	xyd.setUISprite(self.friend_summon_ten:GetComponent(typeof(UISprite)), nil, "summon_btn_bg_1_ios_test")
	self.tips_button:SetActive(false)

	self.skipAnimation = true
end

function SummonWindow:getSummonGiftUIComponent()
	local seniorWishTextGroup = self.groupSenior:NodeByName("seniorWishTextGroup").gameObject
	self.senior_probLabel1 = seniorWishTextGroup:ComponentByName("probLabel1", typeof(UILabel))
	self.senior_probLabel2 = seniorWishTextGroup:ComponentByName("probLabel2", typeof(UILabel))
	self.senior_probLabel3 = seniorWishTextGroup:ComponentByName("probLabel3", typeof(UILabel))
	self.clickProbLabel1 = seniorWishTextGroup:NodeByName("probLabel1/e:image").gameObject
	self.senior_probNum1 = seniorWishTextGroup:ComponentByName("probNum1", typeof(UILabel))
	self.senior_probNum2 = seniorWishTextGroup:ComponentByName("probNum2", typeof(UILabel))
	self.senior_probIcon = seniorWishTextGroup:ComponentByName("probIcon", typeof(UISprite))
	self.senior_wishTipsBtn = seniorWishTextGroup:NodeByName("wishTipsBtn").gameObject

	seniorWishTextGroup:SetActive(true)
	xyd.models.activity:reqActivityByID(xyd.ActivityID.NEW_SUMMON_GIFTBAG)
end

function SummonWindow:initSummonGiftUIComponent()
	UIEventListener.Get(self.senior_wishTipsBtn).onClick = function ()
		xyd.openWindow("summon_senior_giftbag_tips_window", {
			times = self.senior_times
		})
	end

	UIEventListener.Get(self.clickProbLabel1).onClick = function ()
		xyd.openWindow("summon_senior_giftbag_tips_window", {
			times = self.senior_times
		})
	end

	self.senior_probLabel1.text = __("SUMMON_RATE")
	local endTime = xyd.tables.miscTable:getNumber("gacha_10drawcard_endtime", "value")
	local nowTime = xyd.getServerTime()
	local leftTime = endTime - nowTime

	if leftTime > 0 then
		local label = self.limitEndLabel:GetComponent(typeof(UILabel))
		label.text = __("LIMIT_ACT_LEFT_TIME", xyd.getRoughDisplayTime(leftTime))

		UIEventListener.Get(self.limitEndBtn).onPress = function (go, isPressed)
			if isPressed then
				self.limitEndLabel:SetActive(true)
			else
				self.limitEndLabel:SetActive(false)
			end
		end
	end

	self:updateActTips()
end

function SummonWindow:updateActTips()
	self.act_tips_text.text = ""
	self.senior_inner_bg.height = 230

	if self:checkSummonGiftBagOpen() then
		self.senior_inner_bg.height = 255
		local index = Summon:getFortyIndex()

		if index >= 0 then
			index = xyd.tables.miscTable:getNumber("gacha_ensure_guarantee_star5_times", "value") - index
			self.act_tips_text.text = __("GACHA_ENSURE_STAR5_TEXT01", index)
		end
	end
end

function SummonWindow:refreshLimitTen(summonIndex)
	if Summon:getLimitTenScrollNum() > 0 then
		self.wish_summon_ten:SetActive(false)

		local cost = SummonTable:getCost(xyd.SummonType.ACT_LIMIT_TEN)

		self:setSummonBtn(self.limit_summon_ten, cost, __("SUMMON_X_TIME2", 10))

		if self.wish_scroll_label then
			self.wish_scroll_label.gameObject:SetActive(false)
		end

		self.limit_summon_ten:SetActive(true)

		if self.costBgImg then
			self.costBgImg:SetActive(false)
		end

		self.limit_cost_group:SetActive(true)
		self.groupLimitFree:SetActive(true)
		self.seniorBuyBtn_:SetActive(false)

		if xyd.Global.lang == "ja_jp" then
			self.limitBuyBtn:SetActive(true)
		else
			self.limitBuyBtn:SetActive(false)
		end

		if self.senior_switch_btn then
			self.senior_switch_btn:SetActive(false)
		end
	else
		if self.costBgImg then
			self.costBgImg:SetActive(true)
		end

		if self.wish_summon_ten then
			self.wish_summon_ten:SetActive(true)
		end

		if self.wish_scroll_label then
			self.wish_scroll_label.gameObject:SetActive(true)
		end

		self.limit_summon_ten:SetActive(false)
		self.limit_cost_group:SetActive(false)
		self.groupLimitFree:SetActive(false)
		self.limitBuyBtn:SetActive(false)

		if xyd.Global.lang == "ja_jp" then
			self.seniorBuyBtn_:SetActive(true)
		else
			self.seniorBuyBtn_:SetActive(false)
		end

		self:initFiftySummon(summonIndex)
	end

	self:initAutoAltar()
end

function SummonWindow:initAutoAltar()
	local summonGiftData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_SUMMON_GIFTBAG)

	if not summonGiftData or summonGiftData:getEndTime() < xyd.getServerTime() then
		Summon:setFiftySummonStatus(false)
		Summon:setAutoAltarStatus(false)

		return
	end

	local vip = xyd.models.backpack:getVipLev()

	if xyd.tables.vipTable:canAutoAltar(vip) then
		self.auto_altar_group:SetActive(true)

		self.autoAltarLabel = self.auto_altar_group:ComponentByName("auto_altar_label", typeof(UILabel))
		self.autoAltarBtn = self.auto_altar_group:NodeByName("auto_btn").gameObject
		self.autoAltarLabel.text = __("GACHA_AUTOTRANSFER_TEXT01")
		self.autoSelectImg = self.autoAltarBtn:NodeByName("img_select").gameObject

		local function refreshAutoAltarStatus(status)
			self.autoSelectImg:SetActive(status)
		end

		UIEventListener.Get(self.autoAltarBtn).onClick = handler(self, function ()
			local autoAltarStatus = Summon:getAutoAltarStatus()
			autoAltarStatus = not autoAltarStatus

			Summon:setAutoAltarStatus(autoAltarStatus)
			refreshAutoAltarStatus(autoAltarStatus)
		end)
		local autoAltarStatus = Summon:getAutoAltarStatus()

		refreshAutoAltarStatus(autoAltarStatus)

		return
	end

	self.auto_altar_group:SetActive(false)
	Summon:setAutoAltarStatus(false)
end

function SummonWindow:initFiftySummon(summonIndex)
	summonIndex = tonumber(summonIndex) or 0

	if summonIndex >= 1 and summonIndex < 5 then
		return
	end

	local summonGiftData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_SUMMON_GIFTBAG)

	if not summonGiftData or summonGiftData:getEndTime() < xyd.getServerTime() then
		Summon:setFiftySummonStatus(false)
		Summon:setAutoAltarStatus(false)

		return
	end

	local vip = xyd.models.backpack:getVipLev()
	self.slotNum_ = xyd.tables.vipTable:getSlotBase(vip)
	self.switchLabel = self.senior_switch_btn:ComponentByName("switch_label", typeof(UILabel))

	if xyd.tables.vipTable:canFiftySummon(vip) then
		self.senior_switch_btn:SetActive(true)

		local fiftySummonStatus = Summon:getFiftySummonStatus()

		local function refreshFiftySummon(status)
			local seniorScrollNum = Summon:getSeniorScrollNum()
			local summonType = xyd.SummonType
			local btnLabel = "×1"
			local val = 1

			if status then
				btnLabel = "×5"
				val = 5
			end

			if seniorScrollNum < 10 and xyd.Global.lang ~= "ja_jp" then
				local cost = SummonTable:getCost(summonType.SENIOR_CRYSTAL_TEN)

				self:setSummonBtn(self.senior_summon_ten, {
					cost[1],
					cost[2] * val
				}, __("SUMMON_X_TIME2", 10 * val))
			else
				self:setSummonBtn(self.senior_summon_ten, {
					xyd.ItemID.SENIOR_SUMMON_SCROLL,
					10 * val
				}, __("SUMMON_X_TIME2", 10 * val))
			end

			self.switchLabel.text = btnLabel
		end

		local seniorScrollNum = Summon:getSeniorScrollNum()

		if seniorScrollNum >= 10 and seniorScrollNum < 50 then
			Summon:setFiftySummonStatus(false)

			fiftySummonStatus = false
		end

		refreshFiftySummon(fiftySummonStatus)

		UIEventListener.Get(self.senior_switch_btn).onClick = handler(self, function ()
			local seniorScrollNum = Summon:getSeniorScrollNum()

			if seniorScrollNum >= 10 and seniorScrollNum < 50 then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.SENIOR_SUMMON_SCROLL)))

				return
			end

			local fiftySummonStatus = Summon:getFiftySummonStatus()
			fiftySummonStatus = not fiftySummonStatus

			Summon:setFiftySummonStatus(fiftySummonStatus)
			refreshFiftySummon(fiftySummonStatus)
		end)

		return
	end

	Summon:setFiftySummonStatus(false)
end

function SummonWindow:onRefreshSeniorGiftBagText(event)
	if event.data.activity_id ~= xyd.ActivityID.NEW_SUMMON_GIFTBAG then
		return
	end

	local summonGiftData = require("cjson").decode(event.data.act_info.detail)
	self.senior_times = tonumber(summonGiftData.times) or 0

	self.senior_probLabel1:SetActive(true)
	self.senior_probIcon:SetActive(true)
	self.senior_probNum1:SetActive(true)

	self.senior_probNum1.text = "x" .. math.floor(self.senior_times / 100) + 1
	self.senior_probNum2.text = self.senior_times .. "/" .. __("WISH_GACHA_NUM" .. math.floor(self.senior_times / 100) + 1)

	if self.senior_times < 400 then
		self:resetSeniorTextPosition(0)
	else
		self:resetSeniorTextPosition(1)
	end
end

function SummonWindow:resetSeniorTextPosition(flag)
	if flag == 0 then
		self.senior_probLabel2.text = __("WISH_GACHA_TEXT4")

		if xyd.Global.lang == "en_en" then
			self.senior_probNum2:X(-68)
			self.senior_probLabel2:X(-60)

			self.senior_probLabel2.width = 180
		elseif xyd.Global.lang == "fr_fr" then
			self.senior_probNum2:X(-68)
			self.senior_probLabel2:X(-60)
			self.senior_probLabel2:Y(-230)

			self.senior_probLabel2.width = 180
		elseif xyd.Global.lang == "ja_jp" then
			self.senior_probNum2:X(-60)
			self.senior_probLabel2:X(-50)

			self.senior_probLabel2.width = 160
		else
			self.senior_probNum2:X(-30)
			self.senior_probLabel2:X(-22)

			self.senior_probLabel2.width = 120
		end
	else
		self.senior_probLabel2.text = __("WISH_GACHA_TEXT5")

		if xyd.Global.lang == "zh_tw" then
			self.senior_probNum2:X(-10)
			self.senior_probLabel2:X(0)
		elseif xyd.Global.lang == "ja_jp" then
			self.senior_probNum2:X(-40)
			self.senior_probLabel2:X(-32)

			self.senior_probLabel2.width = 130
		elseif xyd.Global.lang == "de_de" then
			self.senior_probNum2:X(-40)
			self.senior_probLabel2:X(-32)

			self.senior_probLabel2.width = 140
		else
			self.senior_probNum2:X(-30)
			self.senior_probLabel2:X(-22)

			self.senior_probLabel2.width = 120
		end
	end
end

function SummonWindow:isPartnerFullAndBuyLimit(num, canSummonNum)
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

function SummonWindow:summonPartner(id, times, index)
	self:stopClick()
	Summon:summonPartner(id, times, index)
end

function SummonWindow:stopClick()
	self.senior_summon_one:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.senior_summon_ten:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

	if self.wish_summon_one then
		self.wish_summon_one:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end

	if self.wish_summon_ten then
		self.wish_summon_ten:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end

	self.base_summon_one:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.base_summon_ten:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.limit_summon_ten:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

	xyd.MainController.get():removeEscListener()
	self.windowMask:SetActive(true)

	local win = xyd.WindowManager.get():getWindow("main_window")

	if win then
		win:setStopClickBottomBtn(true)
	end
end

function SummonWindow:allowClick()
	xyd.MainController.get():addEscListener()
	self.windowMask:SetActive(false)

	local win = xyd.WindowManager.get():getWindow("main_window")

	if win then
		win:setStopClickBottomBtn(false)
	end
end

return SummonWindow
