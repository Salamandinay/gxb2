local ActivityContent = import(".ActivityContent")
local ActivityVampireTask = class("ActivityVampireTask", ActivityContent)
local CommonTabBar = import("app.common.ui.CommonTabBar")
local AwardItem = class("AwardItem", import("app.components.CopyComponent"))
local TaskItem = class("TaskItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivityVampireTask:ctor(parentGO, params, parent)
	ActivityVampireTask.super.ctor(self, parentGO, params, parent)
end

function ActivityVampireTask:getPrefabPath()
	return "Prefabs/Windows/activity/activity_vampire_task"
end

function ActivityVampireTask:initUI()
	self:getUIComponent()
	ActivityVampireTask.super.initUI(self)
	self:initUIComponent()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_VAMPIRE_TASK)
end

function ActivityVampireTask:getUIComponent()
	self.trans = self.go
	self.helpBtn = self.trans:NodeByName("helpBtn").gameObject
	self.groupItem1 = self.trans:NodeByName("groupItem1").gameObject
	self.valueCon = self.groupItem1:NodeByName("valueCon").gameObject
	self.itemGroup = self.valueCon:NodeByName("itemGroup").gameObject
	self.itemGroupUILayout = self.valueCon:ComponentByName("itemGroup", typeof(UILayout))
	self.itemGroup1 = self.valueCon:NodeByName("itemGroup1").gameObject
	self.itemGroup1UILayout = self.valueCon:ComponentByName("itemGroup1", typeof(UILayout))
	self.buyLabel = self.valueCon:ComponentByName("buyLabel", typeof(UILabel))
	self.vipLabel = self.valueCon:ComponentByName("vipLabel", typeof(UILabel))
	self.purchaseBtn = self.valueCon:NodeByName("purchaseBtn").gameObject
	self.purchaseBtnBoxCollider = self.valueCon:ComponentByName("purchaseBtn", typeof(UnityEngine.BoxCollider))
	self.button_label = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.nav = self.trans:NodeByName("nav").gameObject
	self.tab_1 = self.nav:NodeByName("tab_1").gameObject
	self.chosen = self.tab_1:ComponentByName("chosen", typeof(UISprite))
	self.unchosen = self.tab_1:ComponentByName("unchosen", typeof(UISprite))
	self.label1 = self.tab_1:ComponentByName("label", typeof(UILabel))
	self.redMark = self.tab_1:ComponentByName("redMark", typeof(UISprite))
	self.tab_2 = self.nav:NodeByName("tab_2").gameObject
	self.label2 = self.tab_2:ComponentByName("label", typeof(UILabel))
	self.contentGroup = self.trans:NodeByName("contentGroup").gameObject
	self.scrollerCon1 = self.contentGroup:NodeByName("scrollerCon1").gameObject
	self.textLabel01 = self.scrollerCon1:ComponentByName("textLabel01", typeof(UILabel))
	self.textLabel02 = self.scrollerCon1:ComponentByName("textLabel02", typeof(UILabel))
	self.scroller1 = self.scrollerCon1:NodeByName("scroller1").gameObject
	self.scroller1UIScrollView = self.scrollerCon1:ComponentByName("scroller1", typeof(UIScrollView))
	self.itemGroup1UIWrapContent = self.scroller1:ComponentByName("itemGroup1", typeof(UIWrapContent))
	self.award_item = self.scrollerCon1:NodeByName("award_item").gameObject
	self.wrapContent1 = import("app.common.ui.FixedWrapContent").new(self.scroller1UIScrollView, self.itemGroup1UIWrapContent, self.award_item, AwardItem, self)
	self.scrollerCon2 = self.contentGroup:NodeByName("scrollerCon2").gameObject
	self.scrollerCon2 = self.contentGroup:NodeByName("scrollerCon2").gameObject
	self.task_item = self.scrollerCon2:NodeByName("task_item").gameObject
	self.scroller2 = self.scrollerCon2:NodeByName("scroller2").gameObject
	self.scroller2UIScrollView = self.scrollerCon2:ComponentByName("scroller2", typeof(UIScrollView))
	self.itemGroup2 = self.scroller2:NodeByName("itemGroup2").gameObject
	self.itemGroup2UIWrapContent = self.scroller2:ComponentByName("itemGroup2", typeof(UIWrapContent))
	self.wrapContent2 = import("app.common.ui.FixedWrapContent").new(self.scroller2UIScrollView, self.itemGroup2UIWrapContent, self.task_item, TaskItem, self)
	self.progressGroup = self.trans:NodeByName("progressGroup").gameObject
	self.progressGroupUISlider = self.trans:ComponentByName("progressGroup", typeof(UISlider))
	self.progressBg = self.progressGroup:ComponentByName("progressBg", typeof(UISprite))
	self.progressBar = self.progressGroup:ComponentByName("progressBar", typeof(UISprite))
	self.progressLabel = self.progressGroup:ComponentByName("progressLabel", typeof(UILabel))
	self.progressLevelLabel = self.progressGroup:ComponentByName("progressLevelLabel", typeof(UILabel))
	self.modelGroup = self.trans:ComponentByName("modelGroup", typeof(UITexture))
end

function ActivityVampireTask:initUIComponent()
	self.textLabel01.text = __("ACTIVITY_VAMPIRE_TASK_AWARD01")
	self.textLabel02.text = __("ACTIVITY_VAMPIRE_TASK_AWARD02")
	self.buyLabel.text = __("ACTIVITY_VAMPIRE_TASK_GIFTBAG")
	self.giftBagId = xyd.tables.miscTable:getNumber("activity_vampire_giftbag", "value")
	self.levItemId = xyd.tables.miscTable:getNumber("activity_vampire_battlepass_item", "value")
	local picParams = xyd.tables.miscTable:split2Cost("activity_vampire_task_pic", "value", "|#")
	local picPos = picParams[3]
	local picScale = picParams[2]

	xyd.setUITextureByNameAsync(self.modelGroup, xyd.tables.partnerPictureTable:getPartnerPic(picParams[1][1]), true)
	self.modelGroup.gameObject.transform:SetLocalScale(picScale[1], picScale[2], 1)
	self.modelGroup:X(picPos[1])
	self.modelGroup:Y(picPos[2])
	self:updateLev()
	self:initNav()
	self:register()
	self:initUp()
	self:updatePurchaseBtnState()
end

function ActivityVampireTask:initNav()
	local labelStates = {
		chosen = {
			color = Color.New2(1347109631)
		},
		unchosen = {
			color = Color.New2(1347109631)
		}
	}
	self.tabBar = CommonTabBar.new(self.nav, 2, function (index)
		self:updateIndex(index)

		if not self.firstPlayButtonSound then
			self.firstPlayButtonSound = true
		else
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		end
	end, nil, labelStates)

	self.tabBar:setTexts({
		__("ACTIVITY_VAMPIRE_TASK_LABEL01"),
		__("ACTIVITY_VAMPIRE_TASK_LABEL02")
	})
end

function ActivityVampireTask:updateIndex(index)
	self.index = index

	for i = 1, 2 do
		if index == i then
			self["tab_" .. i]:Y(-348.5)
			self["scrollerCon" .. i].gameObject:SetActive(true)

			if index == 1 then
				self:updateFirstScroller()
			elseif index == 2 then
				self:updateSecondScroller()
			end
		else
			self["tab_" .. i]:Y(-358)
			self["scrollerCon" .. i].gameObject:SetActive(false)
		end
	end
end

function ActivityVampireTask:resizeToParent()
	ActivityVampireTask.super.resizeToParent(self)
end

function ActivityVampireTask:register()
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_VAMPIRE_TASK_HELP"
		})
	end)
	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.giftBagId)
	end)

	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, self.onRecharge, self)
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))
	self.eventProxyInner_:addEventListener(xyd.event.WINDOW_WILL_CLOSE, self.onWindowClose, self)
end

function ActivityVampireTask:onWindowClose(event)
	local name = event.params.windowName

	if name == "vip_window" or name == "midas_window" then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_VAMPIRE_TASK)
	end
end

function ActivityVampireTask:onItemChange(event)
	local items = xyd.decodeProtoBuf(event.data).items

	for _, item in ipairs(items) do
		if item.item_id == self.levItemId then
			local lev = self.lev

			self:updateLev()
			self:getActivityData():setIsCheckOld(true)
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_VAMPIRE_TASK, function ()
				self:getActivityData():setIsCheckOld(false)
			end)

			if self.index == 1 and lev ~= self.lev then
				self:updateFirstScroller()
			end
		end
	end
end

function ActivityVampireTask:onRecharge(event)
	local giftbagID = event.data.giftbag_id

	if giftbagID ~= self.giftBagId then
		return
	end

	self:updatePurchaseBtnState()

	if self.index == 1 then
		self:updateFirstScroller()
	end
end

function ActivityVampireTask:onActivityByID(event)
	local id = event.data.act_info.activity_id

	if id == xyd.ActivityID.ACTIVITY_VAMPIRE_TASK then
		if self.index == 2 then
			self:updateSecondScroller()
		end

		self:updateLev()
	end
end

function ActivityVampireTask:updatePurchaseBtnState()
	if self:getActivityData().detail.charges[1].buy_times > 0 then
		xyd.applyChildrenGrey(self.purchaseBtn.gameObject)

		self.purchaseBtnBoxCollider.enabled = false
	else
		xyd.applyChildrenOrigin(self.purchaseBtn.gameObject)

		self.purchaseBtnBoxCollider.enabled = true
	end
end

function ActivityVampireTask:initUp()
	local bagId = self.giftBagId
	self.vipLabel.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(bagId)) .. " VIP EXP"
	self.button_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(bagId) .. " " .. xyd.tables.giftBagTextTable:getCharge(bagId))
	local scaleNum = 0.6666666666666666
	local giftId = xyd.tables.giftBagTable:getGiftID(bagId)
	local awardArr = xyd.tables.giftTable:getAwards(giftId)

	for i, reward in pairs(awardArr) do
		if reward[1] ~= xyd.ItemID.EXP and reward[1] ~= xyd.ItemID.VIP_EXP then
			local icon = xyd.getItemIcon({
				isAddUIDragScrollView = true,
				isShowSelected = false,
				itemID = reward[1],
				num = reward[2],
				uiRoot = self.itemGroup.gameObject,
				scale = Vector3(scaleNum, scaleNum, 1)
			})
		end
	end

	self.itemGroupUILayout:Reposition()
end

function ActivityVampireTask:updateLev()
	local num = xyd.models.backpack:getItemNumByID(self.levItemId)
	local lev = xyd.tables.activityVampireBattlepassTable:getLev(num)
	self.lev = lev
	self.progressLevelLabel.text = "Lv." .. lev

	if xyd.Global.lang == "fr_fr" then
		self.progressLevelLabel.text = "Niv." .. lev

		self.progressLevelLabel:X(-10)
	end

	if lev == 0 then
		self.progressGroupUISlider.value = num / xyd.tables.activityVampireBattlepassTable:getCostTotal(lev + 1)
		self.progressLabel.text = num .. "/" .. xyd.tables.activityVampireBattlepassTable:getCostTotal(lev + 1)
	elseif lev == #xyd.tables.activityVampireBattlepassTable:getIDs() then
		self.progressGroupUISlider.value = 1
		self.progressLabel.text = __("ACTIVITY_SPACE_MAX_LEVEL")
	else
		local curTotalNum = xyd.tables.activityVampireBattlepassTable:getCostTotal(lev)
		local nextTotalNum = xyd.tables.activityVampireBattlepassTable:getCostTotal(lev + 1)
		local curAllNum = nextTotalNum - curTotalNum
		self.progressGroupUISlider.value = (num - curTotalNum) / curAllNum
		self.progressLabel.text = num - curTotalNum .. "/" .. curAllNum
	end
end

function ActivityVampireTask:getLev()
	return self.lev
end

function ActivityVampireTask:getActivityData()
	return self.activityData
end

function ActivityVampireTask:updateFirstScroller()
	local index = 1
	local arr = {}
	local ids = xyd.tables.activityVampireBattlepassTable:getIDs()

	for i, id in pairs(ids) do
		table.insert(arr, {
			id = id
		})
	end

	if not self.firstSetInfo1 then
		self["wrapContent" .. index]:setInfos(arr, {})
		self.scroller1UIScrollView:ResetPosition()

		self.firstSetInfo1 = true
		local jumpToId = -1
		local buy_times = self:getActivityData().detail.charges[1].buy_times

		for i, id in pairs(ids) do
			if id <= self.lev then
				if self:getActivityData().detail.awarded[id] == 0 then
					jumpToId = id

					break
				end

				if buy_times > 0 and self:getActivityData().detail.paid_awarded[id] == 0 then
					jumpToId = id

					break
				end
			end
		end

		if jumpToId == -1 then
			jumpToId = self.lev

			if jumpToId > #ids then
				jumpToId = #ids
			end
		end

		if jumpToId <= 1 then
			jumpToId = -1
		end

		if jumpToId ~= -1 then
			local initialValue = self.scroller1.transform.localPosition.y

			self:waitForFrame(2, function ()
				local sp = self.scroller1UIScrollView.gameObject:GetComponent(typeof(SpringPanel))
				sp = sp or self.scroller1UIScrollView.gameObject:AddComponent(typeof(SpringPanel))

				sp.Begin(sp.gameObject, Vector3(0, initialValue + self:GetJumpToInfoDis(arr[jumpToId]), 0), 8)
			end)
		end

		return
	end

	self["wrapContent" .. index]:setInfos(arr, {
		keepPosition = true
	})
end

function ActivityVampireTask:GetJumpToInfoDis(info)
	local currIndex = nil

	for index, info2 in ipairs(self.wrapContent1:getInfos()) do
		if info2 == info then
			currIndex = index

			break
		end
	end

	if not currIndex then
		return
	end

	local panel = self.scroller1UIScrollView:GetComponent(typeof(UIPanel))
	local height = panel.baseClipRegion.w
	local itemSize = self.wrapContent1:getWrapContent().itemSize
	local lastIndex = #self.wrapContent1:getInfos()
	local height2 = lastIndex * itemSize

	if height >= height2 then
		return 0
	end

	local displayNum = math.ceil(height / itemSize)
	local half = math.floor(displayNum / 2)
	local maxDeltaY = height2 - height
	local deltaY = (currIndex - 1) * itemSize
	deltaY = math.min(deltaY, maxDeltaY)

	return deltaY
end

function ActivityVampireTask:getReward()
	local param = {
		batches = {}
	}
	local ids = xyd.tables.activityVampireBattlepassTable:getIDs()

	for i in pairs(ids) do
		if ids[i] <= self.lev then
			if self:getActivityData().detail.awarded[i] == 0 then
				table.insert(param.batches, {
					index = 1,
					id = ids[i]
				})
			end

			if self:getActivityData().detail.paid_awarded[i] == 0 and self:getActivityData().detail.charges[1].buy_times > 0 then
				table.insert(param.batches, {
					index = 2,
					id = ids[i]
				})
			end
		end
	end

	local param2 = json.encode(param)

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_VAMPIRE_TASK, param2)
end

function ActivityVampireTask:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_VAMPIRE_TASK then
		return
	end

	if self.index == 1 then
		self:updateFirstScroller()
	end
end

function ActivityVampireTask:updateSecondScroller()
	local index = 2
	local arr = {}
	local ids = xyd.tables.activityVampireTaskTable:getIDs()
	local yetArr = {}

	for i in pairs(ids) do
		if ids[i] ~= 5 then
			local limit = xyd.tables.activityVampireTaskTable:getLimit(ids[i])

			if limit <= self:getActivityData().detail.mission_awarded[ids[i]] then
				table.insert(yetArr, {
					id = ids[i]
				})
			else
				table.insert(arr, {
					id = ids[i]
				})
			end
		end
	end

	for i in pairs(yetArr) do
		table.insert(arr, yetArr[i])
	end

	if not self.firstInitTask then
		self["wrapContent" .. index]:setInfos(arr, {})
		self.scroller2UIScrollView:ResetPosition()

		self.firstInitTask = true
	else
		self["wrapContent" .. index]:setInfos(arr, {
			keepPosition = true
		})
	end
end

function AwardItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.freeItemsArr = {}
	self.paidItemsArr = {}

	AwardItem.super.ctor(self, go)
end

function AwardItem:initUI()
	self.award_item = self.go
	self.scoreLabel = self.award_item:ComponentByName("scoreLabel_", typeof(UILabel))
	self.baseAwardGroup = self.award_item:NodeByName("baseAwardGroup").gameObject
	self.baseAwardGroupUILayout = self.award_item:ComponentByName("baseAwardGroup", typeof(UILayout))
	self.extraAwardGroup = self.award_item:NodeByName("extraAwardGroup").gameObject
	self.extraAwardGroupUILayout = self.award_item:ComponentByName("extraAwardGroup", typeof(UILayout))
	self.bg = self.award_item:ComponentByName("bg", typeof(UISprite))
end

function AwardItem:update(index, data)
	if not data then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.id = data.id
	self.scoreLabel.text = data.id
	local freeItems = xyd.tables.activityVampireBattlepassTable:getFreeAward(self.id)

	for i in pairs(freeItems) do
		local params = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = freeItems[i][1],
			num = freeItems[i][2],
			scale = Vector3(0.7962962962962963, 0.7962962962962963, 1),
			uiRoot = self.baseAwardGroup.gameObject
		}

		if not self.freeItemsArr[i] then
			local itemIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)

			table.insert(self.freeItemsArr, itemIcon)
		else
			self.freeItemsArr[i]:setInfo(params)
		end

		self.freeItemsArr[i]:setCallBack(nil)
		self.freeItemsArr[i]:setChoose(false)
		self.freeItemsArr[i]:setMask(false)

		if self:isLock() then
			self.freeItemsArr[i]:setMask(true)
		else
			self.freeItemsArr[i]:setMask(false)
		end

		if not self:isLock() then
			if self.parent:getActivityData().detail.awarded[self.id] == 0 then
				self.freeItemsArr[i]:setEffect(true, "fx_ui_bp_available")
				self.freeItemsArr[i]:setCallBack(handler(self, self.getAward))
			else
				self.freeItemsArr[i]:setEffect(false)
				self.freeItemsArr[i]:setChoose(true)
			end
		else
			self.freeItemsArr[i]:setEffect(false)
		end
	end

	for i = 1, #freeItems do
		self.freeItemsArr[i]:SetActive(true)
	end

	if #freeItems < #self.freeItemsArr then
		for i = #freeItems + 1, #self.freeItemsArr do
			self.freeItemsArr[i]:SetActive(false)
		end
	end

	self.baseAwardGroupUILayout:Reposition()

	local paidItems = xyd.tables.activityVampireBattlepassTable:getPaidAward(self.id)

	for i in pairs(paidItems) do
		local params = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = paidItems[i][1],
			num = paidItems[i][2],
			scale = Vector3(0.7962962962962963, 0.7962962962962963, 1),
			uiRoot = self.extraAwardGroup.gameObject
		}

		if not self.paidItemsArr[i] then
			local itemIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)

			table.insert(self.paidItemsArr, itemIcon)
		else
			self.paidItemsArr[i]:setInfo(params)
		end

		self.paidItemsArr[i]:setCallBack(nil)
		self.paidItemsArr[i]:setChoose(false)
		self.paidItemsArr[i]:setLock(false)
		self.paidItemsArr[i]:setMask(false)

		if self.parent:getActivityData().detail.charges[1].buy_times > 0 then
			if self:isLock() then
				self.paidItemsArr[i]:setMask(true)
			else
				self.paidItemsArr[i]:setMask(false)
			end
		else
			self.paidItemsArr[i]:setLock(true)
		end

		if not self:isLock() then
			if self.parent:getActivityData().detail.paid_awarded[self.id] == 0 then
				self.paidItemsArr[i]:setEffect(true, "fx_ui_bp_available")

				if self.parent:getActivityData().detail.charges[1].buy_times > 0 then
					self.paidItemsArr[i]:setCallBack(handler(self, self.getAward))
				end
			else
				self.paidItemsArr[i]:setEffect(false)
				self.paidItemsArr[i]:setChoose(true)
			end
		else
			self.paidItemsArr[i]:setEffect(false)
		end
	end

	for i = 1, #paidItems do
		self.paidItemsArr[i]:SetActive(true)
	end

	if #paidItems < #self.paidItemsArr then
		for i = #paidItems + 1, #self.paidItemsArr do
			self.paidItemsArr[i]:SetActive(false)
		end
	end

	self.extraAwardGroupUILayout:Reposition()

	if self:isLock() then
		xyd.setUISpriteAsync(self.bg, nil, "activity_vampire_task_item_bg2")

		self.scoreLabel.color = Color.New2(1513101823)
		self.scoreLabel.effectColor = Color.New2(3096804607.0)
	else
		xyd.setUISpriteAsync(self.bg, nil, "activity_vampire_task_item_bg1")

		self.scoreLabel.color = Color.New2(2067734271)
		self.scoreLabel.effectColor = Color.New2(4294967295.0)
	end
end

function AwardItem:isLock()
	if self.id <= self.parent:getLev() then
		return false
	else
		return true
	end
end

function AwardItem:getAward()
	self.parent:getReward()
end

function TaskItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.awardItemsArr = {}

	TaskItem.super.ctor(self, go)
end

function TaskItem:initUI()
	self.task_item = self.go
	self.progressBar = self.task_item:ComponentByName("progressBar_", typeof(UISprite))
	self.progressBarUIProgressBar = self.task_item:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = self.progressBar:ComponentByName("progressImg", typeof(UISprite))
	self.progressLabel = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.tipsBtn = self.task_item:ComponentByName("tipsBtn", typeof(UISprite))
	self.tips = self.task_item:NodeByName("tips").gameObject
	self.itemsGroup = self.task_item:NodeByName("itemsGroup").gameObject
	self.itemsGroupUILayout = self.task_item:ComponentByName("itemsGroup", typeof(UILayout))
	self.labelTitle = self.task_item:ComponentByName("labelTitle", typeof(UILabel))
	self.completeNum = self.task_item:ComponentByName("completeNum", typeof(UILabel))
	self.bg = self.task_item:ComponentByName("e:Image", typeof(UISprite))
	self.tipsBg = self.tips:ComponentByName("bg_", typeof(UISprite))
	self.tipsContent = self.tips:ComponentByName("content", typeof(UILabel))
	UIEventListener.Get(self.bg.gameObject).onClick = handler(self, function ()
		xyd.goWay(xyd.tables.activityVampireTaskTable:getGetway(self.id), nil, , function ()
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_VAMPIRE_TASK)
		end)
	end)
end

function TaskItem:update(index, data)
	if not data then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.id = data.id
	self.labelTitle.text = xyd.tables.activityVampireTaskTextTable:getBrief(self.id)

	if xyd.tables.activityVampireTaskTable:getTips(self.id) == 0 then
		self.tipsBtn:SetActive(false)
	else
		self.tipsBtn:SetActive(true)

		self.labelTipsText = xyd.tables.activityVampireTaskTextTable:getText(self.id)
		self.tipsContent.text = self.labelTipsText
		self.tipsBg.width = self.tipsContent.width + 30

		UIEventListener.Get(self.tipsBtn.gameObject).onPress = function (go, isPressed)
			if isPressed then
				self.tips:SetActive(true)
			else
				self.tips:SetActive(false)
			end
		end
	end

	local limit = xyd.tables.activityVampireTaskTable:getLimit(self.id)
	local curLimitNum = self.parent:getActivityData().detail.mission_awarded[self.id]
	local completeValue = xyd.tables.activityVampireTaskTable:getCompleteValue(self.id)
	local curCompleteValue = self.parent:getActivityData().detail.completes[self.id]

	if limit <= curLimitNum then
		self.completeNum.text = xyd.Global.lang == "fr_fr" and __("ACTIVITY_VAMPIRE_TASK_TEXT01") .. " : " .. "[c][5d9201]" .. limit .. "/" .. limit .. "[-][/c]" or __("ACTIVITY_VAMPIRE_TASK_TEXT01") .. ": " .. "[c][5d9201]" .. limit .. "/" .. limit .. "[-][/c]"
		self.progressBarUIProgressBar.value = 1
		self.progressLabel.text = completeValue .. "/" .. completeValue
	else
		self.completeNum.text = xyd.Global.lang == "fr_fr" and __("ACTIVITY_VAMPIRE_TASK_TEXT01") .. " : " .. "[c][ac3824]" .. curLimitNum .. "/" .. limit .. "[-][/c]" or __("ACTIVITY_VAMPIRE_TASK_TEXT01") .. ": " .. "[c][5d9201]" .. curLimitNum .. "/" .. limit .. "[-][/c]"
		local value = curCompleteValue / completeValue

		if value > 1 then
			value = 1
		end

		self.progressBarUIProgressBar.value = value
		self.progressLabel.text = curCompleteValue .. "/" .. completeValue
	end

	local awardItems = xyd.tables.activityVampireTaskTable:getAward(self.id)

	for i in pairs(awardItems) do
		local params = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = awardItems[i][1],
			num = awardItems[i][2],
			scale = Vector3(0.6018518518518519, 0.6018518518518519, 1),
			uiRoot = self.itemsGroup.gameObject
		}

		if not self.awardItemsArr[i] then
			local itemIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)

			table.insert(self.awardItemsArr, itemIcon)
		else
			self.awardItemsArr[i]:setInfo(params)
		end

		if limit <= curLimitNum then
			self.awardItemsArr[i]:setChoose(true)
		else
			self.awardItemsArr[i]:setChoose(false)
		end
	end

	for i = 1, #awardItems do
		self.awardItemsArr[i]:SetActive(true)
	end

	if #awardItems < #self.awardItemsArr then
		for i = #awardItems + 1, #self.awardItemsArr do
			if self.awardItemsArr[i] then
				self.awardItemsArr[i]:SetActive(false)
			end
		end
	end

	self.itemsGroupUILayout:Reposition()
end

return ActivityVampireTask
