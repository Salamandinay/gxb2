local ActivityHw2022 = class("ActivityHw2022", import(".ActivityContent"))
local cjson = require("cjson")

function ActivityHw2022:ctor(parentGO, params)
	ActivityHw2022.super.ctor(self, parentGO, params)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_HW2022, function ()
		self.activityData.touchTime = xyd.getServerTime()
	end)
	dump(self.activityData.detail)
end

function ActivityHw2022:getPrefabPath()
	return "Prefabs/Windows/activity/activity_hw2022_summon"
end

function ActivityHw2022:onRegister()
	for i = 1, 3 do
		UIEventListener.Get(self["resItem" .. i]).onClick = function ()
			local itemList = {
				xyd.ItemID.ACTIVITY_HW2022_ITEM1,
				xyd.ItemID.ACTIVITY_HW2022_ITEM2,
				xyd.ItemID.ACTIVITY_HW2022_ITEM3
			}

			xyd.WindowManager:get():openWindow("activity_item_getway_window", {
				activityData = self.activityData.detail,
				itemID = itemList[i],
				activityID = xyd.ActivityID.ACTIVITY_HW2022_SHOP
			})
		end
	end

	UIEventListener.Get(self.awardBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("smash_egg_award_window", {
			keyword = "ACTIVITY_HALLOWEEN2022_GAMBLE_TEXT04",
			values = self.activityData.detail.values,
			is_completeds = self.activityData.detail.is_completeds,
			award_table = xyd.tables.activityHw2022SummonAwardsTable
		})
	end)

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_HALLOWEEN2022_GAMBLE_HELP"
		})
	end

	UIEventListener.Get(self.detailBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_hw2022_summon_detail_window", {})
	end

	UIEventListener.Get(self.summon1_).onClick = function ()
		self:summon(1)
	end

	UIEventListener.Get(self.summon2_).onClick = function ()
		self:summon(2)
	end

	UIEventListener.Get(self.rankBtn_).onClick = function ()
		local win = xyd.WindowManager.get():getWindow("activity_hw2022_rank_window")

		if win then
			return
		end

		self.rankBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_HW2022, function ()
			xyd.db.misc:setValue({
				key = "activity_hw2022_rank_touch",
				value = xyd.getServerTime()
			})
			self:updateRedPoint()
		end)

		local params = cjson.encode({
			type = 3
		})

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_HW2022, params)
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNum))
end

function ActivityHw2022:initUI()
	ActivityHw2022.super.initUI(self)
	self:getUIComponent()
	self:layout()
	self:updateItemNum()
	self:updateProgress()
	self:updateHeight()
end

function ActivityHw2022:updateHeight()
	self:resizePosY(self.logoImg_.gameObject, -112, -122)
	self:resizePosY(self.timeGroup_.gameObject, -219, -229)
	self:resizePosY(self.awardBtn_.gameObject, -300, -320)
	self:resizePosY(self.bottomBG_.gameObject, -340, -360)
	self:resizePosY(self.eImage_.gameObject, -130, -221)
	self:resizePosY(self.summon1_.gameObject, -484, -568)
	self:resizePosY(self.summon2_.gameObject, -484, -568)
	self:resizePosY(self.effectRoot1_.gameObject, -459, -525)
	self:resizePosY(self.effectRoot2_.gameObject, -459, -525)
	self:resizePosY(self.labelTips_.gameObject, -118, -134)
	self:resizePosY(self.progressBar_.gameObject, -152, -170)
end

function ActivityHw2022:getUIComponent()
	local goTrans = self.go.transform
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.timeGroup_ = goTrans:NodeByName("timeGroup").gameObject
	self.labelNode_ = goTrans:ComponentByName("timeGroup/labelNode", typeof(UILayout))
	self.timeLabel_ = goTrans:ComponentByName("timeGroup/labelNode/timeLabel", typeof(UILabel))
	self.endLabel_ = goTrans:ComponentByName("timeGroup/labelNode/endLabel", typeof(UILabel))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.detailBtn_ = goTrans:NodeByName("detailBtn").gameObject
	self.rankBtn_ = goTrans:NodeByName("rankBtn").gameObject
	self.rankBtnRed_ = goTrans:NodeByName("rankBtn/redPoint").gameObject
	self.awardBtn_ = goTrans:NodeByName("awardBtn").gameObject
	self.awardBtnLabel_ = goTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.bottomBG_ = goTrans:NodeByName("bottomBG").gameObject
	self.eImage_ = goTrans:NodeByName("bottomBG/image2").gameObject

	for i = 1, 3 do
		self["resItem" .. i] = self.bottomBG_:NodeByName("resItemGroup/res_item" .. i).gameObject
		self["resItemLabel" .. i] = self["resItem" .. i]:ComponentByName("res_num_label", typeof(UILabel))
	end

	self.labelTips_ = self.bottomBG_:ComponentByName("labelTips", typeof(UILabel))
	self.progressBar_ = self.bottomBG_:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressImg_ = self.bottomBG_:ComponentByName("progressBar/img", typeof(UISprite))
	self.labelValue_ = self.bottomBG_:ComponentByName("progressBar/labelValue", typeof(UILabel))
	self.summon1_ = self.bottomBG_:NodeByName("summon1").gameObject
	self.summon1Label_ = self.bottomBG_:ComponentByName("summon1/label", typeof(UILabel))
	self.summon1Red_ = self.bottomBG_:NodeByName("summon1/redPoint").gameObject
	self.summon2_ = self.bottomBG_:NodeByName("summon2").gameObject
	self.summon2Label_ = self.bottomBG_:ComponentByName("summon2/label", typeof(UILabel))
	self.summon2Red_ = self.bottomBG_:NodeByName("summon2/redPoint").gameObject
	self.effectRoot1_ = self.bottomBG_:NodeByName("effectRoot1").gameObject
	self.effectRoot2_ = self.bottomBG_:NodeByName("effectRoot2").gameObject
end

function ActivityHw2022:layout()
	self.labelTips_.text = __("ACTIVITY_HALLOWEEN2022_GAMBLE_TEXT01")
	self.summon1Label_.text = __("ACTIVITY_HALLOWEEN2022_GAMBLE_BUTTON02")
	self.summon2Label_.text = __("ACTIVITY_HALLOWEEN2022_GAMBLE_BUTTON03")

	if xyd.Global.lang == "fr_fr" then
		self.summon2Label_.width = 140
	end

	self.awardBtnLabel_.text = __("ACTIVITY_HALLOWEEN2022_GAMBLE_BUTTON01")

	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_hw2022_summon_logo_" .. xyd.Global.lang)

	self.endLabel_.text = __("END")
	local endTime = self.activityData:getEndTime()
	local timeCount = import("app.components.CountDown").new(self.timeLabel_)

	timeCount:setInfo({
		duration = endTime - xyd:getServerTime()
	})

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
		self.labelNode_:Reposition()
	end

	self.effect1_ = xyd.Spine.new(self.effectRoot1_)

	self.effect1_:setInfo("activity_halloween2022", function ()
		self.effect1_:play("idle01", 0, 1)
	end)

	self.effect2_ = xyd.Spine.new(self.effectRoot2_)

	self.effect2_:setInfo("activity_halloween2022", function ()
		self.effect2_:play("idle02", 0, 1)
	end)
	self:updateRedPoint()
end

function ActivityHw2022:updateRedPoint()
	for type = 1, 2 do
		local costs = xyd.tables.activityHw2022GambleTable:getCost(type)
		local redState = true

		for _, cost in ipairs(costs) do
			if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
				redState = false
			end
		end

		self["summon" .. type .. "Red_"]:SetActive(redState)
	end

	local touchTime = tonumber(xyd.db.misc:getValue("activity_hw2022_rank_touch"))

	if not touchTime or not xyd.isSameDay(touchTime, xyd.getServerTime()) then
		self.rankBtnRed_:SetActive(true)
	else
		self.rankBtnRed_:SetActive(false)
	end
end

function ActivityHw2022:updateItemNum()
	self.resItemLabel1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_HW2022_ITEM1)
	self.resItemLabel2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_HW2022_ITEM2)
	self.resItemLabel3.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_HW2022_ITEM3)
end

function ActivityHw2022:onGetAward(event)
	local data = event.data
	local data_ = xyd.decodeProtoBuf(data)

	if data_.detail then
		local info = require("cjson").decode(data_.detail)

		if info.type == 3 then
			self.rankBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			xyd.WindowManager.get():openWindow("activity_hw2022_rank_window", {
				rankData = info.list
			})
		else
			local function callback()
				local items = info.items

				xyd.openWindow("gamble_rewards_window", {
					isNeedCostBtn = false,
					data = items
				})
				self:waitForFrame(5, function ()
					self.summon1_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
					self.summon2_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
				end)
				self:updateProgress()
			end

			if info.type == 1 then
				self.effect1_:play("hit01", 1, 1, function ()
					self.effect1_:play("idle01", 0, 1)
					callback()
				end)
			elseif info.type == 2 then
				self.effect2_:play("hit02", 1, 1, function ()
					self.effect2_:play("idle02", 0, 1)
					callback()
				end)
			end
		end
	end

	self:updateRedPoint()
end

function ActivityHw2022:updateProgress()
	local limitTime = tonumber(xyd.tables.miscTable:getVal("activity_halloween2022_insure"))
	self.labelValue_.text = self.activityData.detail.times .. "/" .. limitTime
	self.progressBar_.value = self.activityData.detail.times / limitTime

	if limitTime <= self.activityData.detail.times then
		xyd.setUISpriteAsync(self.progressImg_, nil, "activity_hw2022_summon_progress3")
	else
		xyd.setUISpriteAsync(self.progressImg_, nil, "activity_hw2022_summon_progress2")
	end
end

function ActivityHw2022:summon(type)
	local costs = xyd.tables.activityHw2022GambleTable:getCost(type)

	for _, cost in ipairs(costs) do
		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("ACTIVITY_HALLOWEEN2022_GAMBLE_TEXT05", xyd.tables.itemTable:getName(cost[1])))

			return
		end
	end

	xyd.WindowManager.get():openWindow("activity_hw2022_summon_window", {
		type = type,
		costs = costs,
		callback = function (nun)
			self.summon1_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.summon2_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			local params = cjson.encode({
				type = type,
				num = nun
			})

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_HW2022, params)
		end
	})
end

return ActivityHw2022
