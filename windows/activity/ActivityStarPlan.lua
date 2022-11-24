local ActivityStarPlan = class("ActivityStarPlan", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")
local StepTime = 1.5
local cjson = require("cjson")

function ActivityStarPlan:ctor(parentGO, params)
	ActivityStarPlan.super.ctor(self, parentGO, params)
	dump(self.activityData.detail)
end

function ActivityStarPlan:getPrefabPath()
	return "Prefabs/Windows/activity/activity_star_plan"
end

function ActivityStarPlan:initUI()
	ActivityStarPlan.super.initUI(self)
	self.activityData:checkUpdateList()
	self:getUIComponent()
	self:layout()
	self:updateBoxItems()
	self:updateRedPoint()
	self:initBoxAni()
	self:register()
end

function ActivityStarPlan:getUIComponent()
	local goTrans = self.go.transform
	self.logoImg_ = goTrans:ComponentByName("content/panel3/logoImg", typeof(UISprite))
	self.shopBtn_ = goTrans:NodeByName("content/panel3/shopBtn").gameObject
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.detailBtn_ = goTrans:NodeByName("detailBtn").gameObject
	self.content_ = goTrans:NodeByName("content")
	self.resetBtn_ = self.content_:NodeByName("resetBtn").gameObject
	self.timeGroup_ = self.content_:ComponentByName("panel3/timeGroup", typeof(UILayout))
	self.timeBg_ = self.content_:NodeByName("panel3/timeBg").gameObject
	self.timeLabel_ = self.content_:ComponentByName("panel3/timeGroup/timeLabel", typeof(UILabel))
	self.endLabel_ = self.content_:ComponentByName("panel3/timeGroup/endLabel", typeof(UILabel))
	self.awardBtn_ = self.content_:NodeByName("panel3/awardBtn").gameObject
	self.awardBtnLabel_ = self.content_:ComponentByName("panel3/awardBtn/label", typeof(UILabel))
	self.awardBtnRedpoint_ = self.content_:NodeByName("panel3/awardBtn/redPoint").gameObject
	self.btnBuyOne_ = self.content_:NodeByName("panel3/btnBuyOne").gameObject
	self.btnBuyOneRed_ = self.content_:NodeByName("panel3/btnBuyOne/redPoint").gameObject
	self.btnBuyOneLabel_ = self.content_:ComponentByName("panel3/btnBuyOne/costDesc", typeof(UILabel))
	self.btnBuyTen_ = self.content_:NodeByName("panel3/btnBuyTen").gameObject
	self.btnBuyTenRed_ = self.content_:NodeByName("panel3/btnBuyTen/redPoint").gameObject
	self.btnBuyTenLabel_ = self.content_:ComponentByName("panel3/btnBuyTen/costDesc", typeof(UILabel))
	self.resItemLabel_ = self.content_:ComponentByName("panel3/resItemGroup/numLabel", typeof(UILabel))
	self.btnMask_ = goTrans:NodeByName("content/panel3/btnMask").gameObject
	self.resItemAdd_ = self.content_:NodeByName("panel3/resItemGroup/addBtn").gameObject

	for i = 1, 4 do
		self["boxItemNumLabel" .. i] = self.content_:ComponentByName("boxItemGroup/item" .. i .. "/label", typeof(UILabel))
	end

	self.effectRoot1 = self.content_:NodeByName("effectPanel2/effectRoot1").gameObject
	self.itemPanel2_ = self.content_:ComponentByName("effectPanel2", typeof(UIPanel))
	self.itemPanel_ = self.content_:ComponentByName("itemPanel", typeof(UIPanel))
	self.effectRoot2 = self.content_:NodeByName("itemPanel/effectRoot2").gameObject
	self.itemGroup = self.content_:NodeByName("itemPanel/itemGroup").gameObject
	self.showAwardItem = self.content_:ComponentByName("itemPanel/showAwardItem", typeof(UISprite))

	for i = 1, 7 do
		self["showItem" .. i] = self.itemGroup:ComponentByName(i, typeof(UISprite))
	end
end

function ActivityStarPlan:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_STAR_PLAN_HELP"
		})
	end

	UIEventListener.Get(self.btnBuyOne_).onClick = function ()
		self:buyBox(1)
	end

	UIEventListener.Get(self.btnBuyTen_).onClick = function ()
		self:buyBox(10)
	end

	UIEventListener.Get(self.shopBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_star_plan_shop_window", {})
	end

	UIEventListener.Get(self.resItemAdd_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = 454,
			activityID = xyd.ActivityID.ACTIVITY_STAR_PLAN,
			activityData = self.activityData,
			openItemBuyWnd = handler(self, self.getAddCallback)
		})
	end

	UIEventListener.Get(self.resetBtn_).onClick = function ()
		xyd.alertYesNo(__("ACTIVITY_STAR_PLAN_TIPS01"), function (yes_no)
			if yes_no then
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_STAR_PLAN, cjson.encode({
					type = 5
				}))
			end
		end)
	end

	UIEventListener.Get(self.detailBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_star_plan_dropbox_window", {})
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_star_plan_mission_window", {})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function ActivityStarPlan:layout()
	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_star_plan_logo_" .. xyd.Global.lang)

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel_.text = __("END")

	self.timeGroup_:Reposition()

	self.handEffect_ = xyd.Spine.new(self.effectRoot1)

	self.handEffect_:setInfo("activity_star_plan", function ()
		self.handEffect_:setRenderPanel(self.itemPanel2_)
		self.handEffect_:play("texiao03", 0, 1)
	end)

	self.handEffect2_ = xyd.Spine.new(self.effectRoot2)

	self.handEffect2_:setInfo("activity_star_plan", function ()
		self.handEffect2_:setRenderPanel(self.itemPanel_)
		self.handEffect2_:play("texiao02", 0, 1)
		self.handEffect2_:followSlot("hit", self.showAwardItem.gameObject)
		self.handEffect2_:followBone("hit", self.showAwardItem.gameObject)
	end)

	self.btnBuyOneLabel_.text = __("ACTIVITY_STAR_PLAN_BUTTON01")
	self.btnBuyTenLabel_.text = __("ACTIVITY_STAR_PLAN_BUTTON02")
	self.awardBtnLabel_.text = __("ACTIVITY_STAR_PLAN_AWARDS_BUTTON")

	self:resizePosY(self.logoImg_.gameObject, 443, 520)
	self:resizePosY(self.shopBtn_.gameObject, 449, 571)
	self:resizePosY(self.content_.gameObject, -518, -640)
	self:resizePosY(self.btnBuyOne_.gameObject, -314, -326)
	self:resizePosY(self.btnBuyTen_.gameObject, -314, -326)
	self:resizePosY(self.awardBtn_.gameObject, -288, -307)
	self:resizePosY(self.timeGroup_.gameObject, 374, 422)
	self:resizePosY(self.timeBg_.gameObject, 378, 426)
end

function ActivityStarPlan:updateBoxItems()
	local boxInfo = self.activityData:getBoxInfo()

	for i = 1, 4 do
		self["boxItemNumLabel" .. i].text = "x" .. (boxInfo[i] or 0)
	end

	self.resItemLabel_.text = xyd.models.backpack:getItemNumByID(454)
end

function ActivityStarPlan:updateRedPoint()
	local shopRed = self.activityData:checkShopRed()

	if shopRed then
		self.awardBtnRedpoint_:SetActive(true)
	else
		self.awardBtnRedpoint_:SetActive(false)
	end

	self.btnBuyOneRed_:SetActive(xyd.models.backpack:getItemNumByID(454) >= 1)
	self.btnBuyTenRed_:SetActive(xyd.models.backpack:getItemNumByID(454) >= 10)
end

function ActivityStarPlan:initBoxAni()
	self.aniIndexNow_ = 0
	self.itemList_ = xyd.cloneTable(self.activityData.detail.list)

	self:boxItemStep()

	self.timer_ = Timer.New(handler(self, self.boxItemStep), StepTime, -1, false)

	self.timer_:Start()
end

function ActivityStarPlan:boxItemStep()
	self:fixBoxItemPos()
	self:updateBoxItemImg()

	if self.needShowGet_ then
		self.needShowGet_ = false

		self:showGetAni()
	end

	self.sequence1_ = self:getSequence()

	self.sequence1_:Insert(0, self.itemGroup.transform:DOLocalMove(Vector3((self.aniIndexNow_ + 1) * 176, -114, 0), StepTime, false):SetEase(DG.Tweening.Ease.Linear))
	self.sequence1_:SetAutoKill(true)

	self.aniIndexNow_ = self.aniIndexNow_ + 1
end

function ActivityStarPlan:resetBoxItemList()
	self.timer_:Stop()

	self.aniIndexNow_ = 0

	if self.sequence1_ then
		self.sequence1_:Kill(true)
	end

	self.itemGroup.transform:X(0)
	self:updateBoxItemImg()
	self:boxItemStep()
	self.timer_:Start()
end

function ActivityStarPlan:updateBoxItemImg()
	for i = 1, 7 do
		if self.targetIndex_ and self.targetIndex_ == i then
			local pic = xyd.tables.activityStarPlanGambleTable:getPic(self.awardItemTableID)

			xyd.setUISpriteAsync(self["showItem" .. i], nil, pic, nil, , true)
		else
			local posIndex = 8 - i + self.aniIndexNow_
			local moveNum = math.floor((posIndex - 2) / 7)
			local matchNum = math.max(#self.itemList_, 7)
			local realIndex = math.fmod(i + moveNum * 7 - 1, matchNum) + 1
			local item_table_id = self.itemList_[realIndex]

			if item_table_id and item_table_id > 0 then
				local pic = xyd.tables.activityStarPlanGambleTable:getPic(item_table_id)

				xyd.setUISpriteAsync(self["showItem" .. i], nil, pic, nil, , true)
				self["showItem" .. i].gameObject:SetActive(true)
			else
				self["showItem" .. i].gameObject:SetActive(false)
			end
		end
	end
end

function ActivityStarPlan:fixBoxItemPos()
	for i = 1, 7 do
		local posIndex = 8 - i + self.aniIndexNow_
		local moveNum = math.floor((posIndex - 2) / 7)

		self["showItem" .. i].transform:X(352 - i * 176 - moveNum * 7 * 176)
	end
end

function ActivityStarPlan:showGetAni()
	local centerIndex = 0

	for i = 1, 7 do
		if math.fmod(8 - i + self.aniIndexNow_, 7) == 4 then
			centerIndex = i

			break
		end
	end

	self.targetIndex_ = centerIndex
	local pic = xyd.tables.activityStarPlanGambleTable:getPic(self.awardItemTableID)

	xyd.setUISpriteAsync(self.showAwardItem, nil, pic, nil, , true)
	xyd.setUISpriteAsync(self["showItem" .. centerIndex], nil, pic, nil, , true)
	self["showItem" .. centerIndex].gameObject:SetActive(true)
	self:waitForTime(2 * StepTime - 0.8, function ()
		self.handEffect2_:play("texiao01", 1, 1, function ()
			self.handEffect2_:play("texiao02", 0, 1)
			self.showAwardItem.gameObject:SetActive(false)
		end)
	end)
	self:waitForTime(2 * StepTime - 0.3, function ()
		self["showItem" .. centerIndex].gameObject:SetActive(false)
		self.showAwardItem.gameObject:SetActive(true)
	end)
	self:waitForTime(2 * StepTime + 0.8, function ()
		self:showAwards()
		self.showAwardItem.gameObject:SetActive(false)
		self["showItem" .. centerIndex].gameObject:SetActive(true)
		self.btnMask_:SetActive(false)
		self.activityData:checkUpdateList()

		self.itemList_ = xyd.cloneTable(self.activityData.detail.list)
		self.awardItemTableID = nil
		self.targetIndex_ = nil

		self:resetBoxItemList()
		self:updateBoxItems()
		self:updateRedPoint()
	end)
end

function ActivityStarPlan:showAwards()
	local awardsData = {}

	if self.tempAwardItems then
		for _, award in pairs(self.tempAwardItems) do
			if tonumber(award.item_id) == 456 or tonumber(award.item_id) == 455 then
				award.cool = 1
			end

			table.insert(awardsData, {
				item_id = award.item_id,
				item_num = award.item_num,
				cool = award.cool
			})
		end

		xyd.openWindow("gamble_rewards_window", {
			wnd_type = 2,
			data = awardsData
		})
	end
end

function ActivityStarPlan:dispose()
	ActivityStarPlan.super.dispose(self)

	if self.timer_ then
		self.timer_:Stop()
	end
end

function ActivityStarPlan:onGetAward(event)
	local id = event.data.activity_id

	if id ~= xyd.ActivityID.ACTIVITY_STAR_PLAN then
		return
	end

	if event.data.detail and tostring(event.data.detail) ~= "" then
		local details = cjson.decode(event.data.detail)

		if details.type == 5 then
			self.itemList_ = details.list

			for i = 1, 7 do
				self["showItem" .. i].gameObject:SetActive(true)
			end

			self:resetBoxItemList()
			self:updateBoxItems()
		elseif details.type == 1 then
			xyd.alertTips(__("PURCHASE_SUCCESS"))
			self:updateBoxItems()
			self:updateRedPoint()
		elseif details.type == 3 then
			xyd.alertTips(__("ACTIVITY_STAR_PLAN_TIPS02"))
			self.btnMask_:SetActive(true)

			self.needShowGet_ = true
			self.tempAwardItems = details.items
			local awardsIndex = details.awards[1]
			self.awardItemTableID = self.itemList_[awardsIndex]
		elseif details.type == 4 then
			self.itemList_ = details.list

			self:resetBoxItemList()
			self:updateBoxItems()
		end
	end

	self:updateRedPoint()
end

function ActivityStarPlan:buyBox(times)
	if xyd.models.backpack:getItemNumByID(454) < times then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(454)))

		return
	end

	if times > #self.itemList_ then
		xyd.alertTips(__("ACTIVITY_STAR_PLAN_TIPS03"))

		return
	end

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_STAR_PLAN, cjson.encode({
		type = 3,
		num = times
	}))
end

function ActivityStarPlan:getAddCallback()
	if self.activityData:getBuyLeftTime() <= 0 then
		xyd.showToast(__("ACTIVITY_WORLD_BOSS_LIMIT"))

		return
	end

	local costData = xyd.split2(xyd.tables.miscTable:getVal("activity_star_plan_buy"), {
		"|",
		"#"
	})
	local leftTime = self.activityData:getBuyLeftTime()
	local cost = costData[1]
	local canBuyTime = xyd.models.backpack:getItemNumByID(tonumber(cost[1])) / tonumber(cost[2])

	if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(tonumber(cost[1]))))

		return
	end

	xyd.WindowManager.get():openWindow("limit_purchase_item_window", {
		imgExchangeHeight = 38,
		imgExchangeWidth = 38,
		needTips = true,
		limitKey = "限制",
		buyNum = 1,
		hasMaxMin = true,
		buyType = 454,
		notEnoughKey = "PERSON_NO_CRYSTAL",
		costType = tonumber(cost[1]),
		costNum = tonumber(cost[2]),
		descLabel = __("ACTIVITY_SOCKS_CHANGE_BUY_TEXT", leftTime, costData[2][1]),
		purchaseCallback = function (evt, num)
			if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) * num then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(tonumber(cost[1]))))

				return
			end

			self.activityData.sendMsg = {
				type = 1,
				num = num
			}

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_STAR_PLAN, cjson.encode({
				type = 1,
				num = num
			}))
		end,
		titleKey = __("ACTIVITY_STAR_PLAN_BUY_TEXT01"),
		limitNum = math.min(leftTime, canBuyTime),
		eventType = xyd.event.GET_ACTIVITY_AWARD
	})
end

return ActivityStarPlan
