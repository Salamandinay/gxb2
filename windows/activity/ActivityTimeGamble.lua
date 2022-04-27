local ActivityTimeGamble = class("ActivityTimeGamble", import(".ActivityContent"))
local myTable = xyd.tables.activityTimeGambleTable
local cjson = require("cjson")

function ActivityTimeGamble:ctor(parentGo, params, parent)
	ActivityTimeGamble.super.ctor(self, parentGo, params, parent)

	self.lastNum = 1
	self.curActionIndex_ = 1
	self.skinModel = nil
end

function ActivityTimeGamble:getPrefabPath()
	return "Prefabs/Windows/activity/activity_time_gamble"
end

function ActivityTimeGamble:resizeToParent()
	ActivityTimeGamble.super.resizeToParent(self)
end

function ActivityTimeGamble:initUI()
	self:getUIComponent()
	ActivityTimeGamble.super.initUI(self)
	self:layout()
	self:register()
	self:loadSkinModel()
end

function ActivityTimeGamble:getUIComponent()
	local go = self.go
	self.groupTop = go:NodeByName("groupTop").gameObject
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.groupBottom = go:NodeByName("groupBottom").gameObject
	self.Mask_ = go:NodeByName("Mask_").gameObject
	self.logoImg = self.groupTop:ComponentByName("logoImg", typeof(UISprite))
	self.helpBtn = self.groupTop:NodeByName("helpBtn").gameObject
	self.probBtn = self.groupTop:NodeByName("probBtn").gameObject
	self.shopBtn = self.groupTop:NodeByName("shopBtn").gameObject
	self.shopBtnRed = self.groupTop:NodeByName("shopBtn/redPoint").gameObject
	self.shopCostGroup = self.groupTop:NodeByName("shopCostGroup").gameObject
	self.resGroup = self.groupTop:NodeByName("resGroup").gameObject
	self.shopItemNumLabel = self.shopCostGroup:ComponentByName("label", typeof(UILabel))
	self.resNumLabel = self.resGroup:ComponentByName("countLabel", typeof(UILabel))
	self.addBtn = self.resGroup:NodeByName("addBtn").gameObject
	self.girlModel = self.groupMain:NodeByName("girlModel").gameObject
	self.mainBg = self.groupMain:NodeByName("mainBg").gameObject
	self.groupItems = self.groupMain:NodeByName("groupItems").gameObject
	self.buyTipsLabel = self.groupMain:ComponentByName("buyTipsLabel", typeof(UILabel))

	for i = 1, 12 do
		local iGroup = self.groupItems:NodeByName("item_" .. i).gameObject
		self["itemGroup" .. i] = iGroup:NodeByName("itemGroup").gameObject
		self["itemBgImg" .. i] = iGroup:ComponentByName("itemBgImg", typeof(UISprite))
		self["uiRoot" .. i] = iGroup.transform:Find("iconRoot").gameObject
		self["itemBgImg" .. i].alpha = 0.01
	end

	self.skipBtn = self.groupBottom:ComponentByName("skipBtn", typeof(UISprite))
	self.btnBuyOne = self.groupBottom:NodeByName("btnBuyOne").gameObject
	self.costNumOne = self.btnBuyOne:ComponentByName("costNum", typeof(UILabel))
	self.costDescOne = self.btnBuyOne:ComponentByName("costDesc", typeof(UILabel))
	self.btnBuyTen = self.groupBottom:NodeByName("btnBuyTen").gameObject
	self.costNumTen = self.btnBuyTen:ComponentByName("costNum", typeof(UILabel))
	self.costDescTen = self.btnBuyTen:ComponentByName("costDesc", typeof(UILabel))
	self.gambleDescLabel = self.groupBottom:ComponentByName("gambleDescLabel", typeof(UILabel))
	self.refreshBtn = self.groupBottom:NodeByName("refreshBtn").gameObject
	self.refreshIcon = self.refreshBtn:NodeByName("costIcon").gameObject
	self.labelCost = self.refreshBtn:ComponentByName("labelCost", typeof(UILabel))
	self.labelFree = self.refreshBtn:ComponentByName("labelFree", typeof(UILabel))
end

function ActivityTimeGamble:updateShopRed()
	local shopRedState = self.activityData:getShopState()

	self.shopBtnRed:SetActive(shopRedState)
end

function ActivityTimeGamble:layout()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_time_gamble_" .. xyd.Global.lang)

	local skipValue = tonumber(xyd.db.misc:getValue("ActivityTimeGamble:skipAnimation")) or 0
	self.skipAnimation = false

	if skipValue == 1 then
		self.skipAnimation = true
	end

	if self.skipAnimation then
		xyd.setUISprite(self.skipBtn, nil, "battle_img_skip")
	else
		xyd.setUISprite(self.skipBtn, nil, "btn_max")
	end

	self.shopItemNumLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.TIME_DEBRIS)
	self.isPlayAnimation = false

	self:setRrefreshLabel()

	self.gambleCost = xyd.split(xyd.tables.miscTable:getVal("activity_time_gamble_cost"), "#", true)
	self.resNumLabel.text = xyd.models.backpack:getItemNumByID(self.gambleCost[1])
	self.costNumOne.text = self.gambleCost[2]
	self.costNumTen.text = self.gambleCost[2] * 10
	self.costDescOne.text = __("GAMBLE_BUY_ONE")
	self.costDescTen.text = __("GAMBLE_BUY_TEN")
	local restTimes = 50 - self.activityData.detail_.times
	self.gambleDescLabel.text = __("ACTIVITY_TIME_GAMBLE_NUM", restTimes)
	self.gambleList = {}
	self.gambleListData = {}
	self.isInitGamble = false

	self:updateGamble()
	self:updateShopRed()
end

function ActivityTimeGamble:setRrefreshLabel()
	self.refreshFreeTimes = tonumber(xyd.tables.miscTable:getVal("activity_time_refresh_free"))
	local refreshTimes = self.activityData.detail_.refresh

	if refreshTimes < self.refreshFreeTimes then
		self.refreshIcon:SetActive(false)
		self.labelCost:SetActive(false)
		self.labelFree:SetActive(true)

		self.labelFree.text = self.refreshFreeTimes - refreshTimes .. "/" .. self.refreshFreeTimes
	else
		self.refreshCost = xyd.split(xyd.tables.miscTable:getVal("activity_time_refresh_pay"), "#", true)
		self.labelCost.text = self.refreshCost[2]

		self.refreshIcon:SetActive(true)
		self.labelCost:SetActive(true)
		self.labelFree:SetActive(false)
	end
end

function ActivityTimeGamble:updateGamble()
	local awards = self.activityData.detail_.awards

	if not self.isInitGamble then
		for i, str in ipairs(awards) do
			local pos = i
			local prob = myTable:getProb(i) * 100
			local smalltips = __("GAMBLE_ITEM_RATE", tostring(prob))
			local data = xyd.split(str, "#", true)
			local item = xyd.getItemIcon({
				itemID = data[1],
				num = data[2],
				uiRoot = self["itemGroup" .. pos],
				scale = Vector3(0.6, 0.6, 0.6),
				wndType = xyd.ItemTipsWndType.GAMBLE,
				smallTips = smalltips
			})

			if data[3] then
				item:setChoose(true)
			end

			local itemData = {
				itemID = data[1],
				num = data[2]
			}

			table.insert(self.gambleListData, itemData)
			table.insert(self.gambleList, item)
		end

		self.isInitGamble = true
	else
		for i, str in ipairs(awards) do
			local data = xyd.split(str, "#", true)

			self.gambleList[i]:setInfo({
				show_has_num = true,
				itemID = data[1],
				num = data[2]
			})

			if data[3] then
				self.gambleList[i]:setChoose(true)
			else
				self.gambleList[i]:setChoose(false)
			end
		end
	end

	self:playStandbyAction()
end

function ActivityTimeGamble:register()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_TIME_GAMBLE_HELP"
		})
	end

	UIEventListener.Get(self.probBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_time_gamble_drop_window", {})
	end

	UIEventListener.Get(self.skipBtn.gameObject).onClick = function ()
		self.skipAnimation = not self.skipAnimation
		local setValue = 0

		if self.skipAnimation then
			setValue = 1
		end

		xyd.db.misc:setValue({
			key = "ActivityTimeGamble:skipAnimation",
			value = setValue
		})

		if self.skipAnimation then
			xyd.setUISprite(self.skipBtn, nil, "battle_img_skip")
		else
			xyd.setUISprite(self.skipBtn, nil, "btn_max")
		end
	end

	UIEventListener.Get(self.shopBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_time_gamble_shop_window")
	end

	UIEventListener.Get(self.addBtn).onClick = function ()
		local itemID = self.gambleCost[1]

		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = itemID,
			activityID = xyd.ActivityID.ACTIVITY_TIME_GAMBLE
		})
	end

	UIEventListener.Get(self.btnBuyOne).onClick = function ()
		if not self.isPlayAnimation then
			self:gambleTimes(1)
		end
	end

	UIEventListener.Get(self.btnBuyTen).onClick = function ()
		if not self.isPlayAnimation then
			self:gambleTimes(10)
		end
	end

	UIEventListener.Get(self.refreshBtn).onClick = handler(self, self.refreshTouch)

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self:registerEvent(xyd.event.TIME_REFRESH, handler(self, self.onRefresh))
end

function ActivityTimeGamble:gambleTimes(num)
	self.lastNum = num
	local need = self.gambleCost[2] * num

	if need <= xyd.models.backpack:getItemNumByID(self.gambleCost[1]) then
		local params = cjson.encode({
			type = 2,
			num = num
		})

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_TIME_GAMBLE, params)
		self.Mask_:SetActive(true)
	else
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.gambleCost[1])))
	end
end

function ActivityTimeGamble:refreshTouch()
	if self.isPlayAnimation then
		return
	end

	local function sendMessage(isCost)
		local msg = messages_pb.time_refresh_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_TIME_GAMBLE
		msg.is_cost = isCost

		xyd.Backend.get():request(xyd.mid.TIME_REFRESH, msg)
	end

	local refreshTimes = self.activityData.detail_.refresh

	if refreshTimes < self.refreshFreeTimes then
		xyd.alertYesNo(__("ACTIVITY_TIME_REFRESH_FREE", self.refreshFreeTimes - refreshTimes), function (flag)
			if flag then
				sendMessage(0)
			end
		end)
	else
		local hasNum = xyd.models.backpack:getItemNumByID(self.refreshCost[1])
		local needCost = self.refreshCost[2]

		if hasNum < needCost then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

			return
		else
			local timeStamp = xyd.db.misc:getValue("activity_time_gamble_time_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				xyd.WindowManager.get():openWindow("gamble_tips_window", {
					type = "activity_time_gamble",
					text = __("GAMBLE_REFRESH_CONFIRM", self.refreshCost[2]),
					callback = function ()
						sendMessage(1)
					end
				})
			else
				sendMessage(1)
			end
		end
	end
end

function ActivityTimeGamble:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_TIME_GAMBLE then
		return
	end

	local params = {}
	local detail = cjson.decode(event.data.detail)

	if detail.type == 2 then
		local restTimes = 50 - self.activityData.detail_.times
		self.gambleDescLabel.text = __("ACTIVITY_TIME_GAMBLE_NUM", restTimes)
		local tableIds = detail.table_ids
		local awardIndex = tableIds[1]
		local isCool = false
		local bigRewardParams = nil

		for _, id in ipairs(tableIds) do
			local cool = myTable:getCool(id)
			local itemData = self.gambleListData[id]
			local param = {
				item_num = itemData.num,
				item_id = itemData.itemID
			}

			if cool == 1 then
				param.cool = 1
				isCool = true
			end

			if id == 12 then
				bigRewardParams = param
			else
				table.insert(params, param)
			end
		end

		if bigRewardParams then
			table.insert(params, bigRewardParams)
		end

		local adds = detail.adds
		local allNum = 0

		for _, addNum in ipairs(adds) do
			allNum = allNum + addNum
		end

		if allNum > 0 then
			table.insert(params, {
				item_num = allNum,
				item_id = xyd.ItemID.TIME_DEBRIS
			})
		end

		local call2 = nil

		local function call1()
			if self.timer2_ then
				self.timer2_:Stop()

				self.timer2_ = nil
			end

			self.Mask_:SetActive(false)
			self:playStandbyAction()

			self.isPlayAnimation = false

			for _, id in ipairs(tableIds) do
				local cool = myTable:getCool(id)
				local itemData = self.gambleListData[id]

				if cool == 1 then
					self.gambleList[id]:setChoose(true)
				end
			end

			local wndType = 4
			local sureCallback = nil
			local refreshAwards = self.activityData.detail_.refreshAwards

			if refreshAwards and next(refreshAwards) then
				wndType = 2

				function sureCallback()
					self.activityData:refreshAwardsData()

					local function reset()
						for i = 1, 12 do
							NGUITools.DestroyChildren(self["itemGroup" .. i].transform)
						end

						self:setRrefreshLabel()

						self.gambleList = {}
						self.gambleListData = {}
						self.isInitGamble = false

						self:updateGamble()
					end

					xyd.alertConfirm(__("ACTIVITY_TIME_REFRESH_TIPS"))

					local restTimes = 50 - self.activityData.detail_.times
					self.gambleDescLabel.text = __("ACTIVITY_TIME_GAMBLE_NUM", restTimes)

					reset()
				end
			end

			xyd.WindowManager.get():openWindow("gamble_rewards_window", {
				data = params,
				wnd_type = wndType,
				cost = {
					self.gambleCost[1],
					self.lastNum * self.gambleCost[2],
					self.lastNum
				},
				buyCallback = function (cost)
					self:gambleTimes(cost[3])
				end,
				sureCallback = sureCallback
			})
		end

		if self.skipAnimation then
			call1()
		else
			self.isPlayAnimation = true

			self:playAwardAction(awardIndex, call1, call2, isCool)
		end
	end

	self.needUpdateRed_ = true

	if self.needUpdateRed_ and self.hasChangeItem_ then
		self:updateShopRed()

		self.needUpdateRed_ = false
		self.hasChangeItem_ = false
	end
end

function ActivityTimeGamble:onItemChange(event)
	local data = event.data.items

	for _, item in ipairs(data) do
		if item.item_id == self.gambleCost[1] then
			self.resNumLabel.text = xyd.models.backpack:getItemNumByID(self.gambleCost[1])
		end

		if item.item_id == xyd.ItemID.TIME_DEBRIS then
			self.shopItemNumLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.TIME_DEBRIS)
			self.hasChangeItem_ = true

			if self.needUpdateRed_ and self.hasChangeItem_ then
				self:updateShopRed()

				self.needUpdateRed_ = false
				self.hasChangeItem_ = false
			end
		end
	end
end

function ActivityTimeGamble:onRefresh(event)
	self:playRefreshAction()
end

function ActivityTimeGamble:playRefreshAction()
	self:clearTimer()

	if not self.refreshTimer_ then
		self.refreshTimer_ = self:getTimer(handler(self, self.refreshByTimer), 0.1, -1)
	end

	self.isPlayAnimation = true
	self.refreshCount = 0

	self.refreshTimer_:Start()
end

function ActivityTimeGamble:refreshByTimer()
	self.refreshCount = self.refreshCount + 1

	if self.refreshCount > 13 then
		self:clearTimer()

		self.isPlayAnimation = false

		local function reset()
			for i = 1, 12 do
				NGUITools.DestroyChildren(self["itemGroup" .. i].transform)
			end

			self:setRrefreshLabel()

			self.gambleList = {}
			self.gambleListData = {}
			self.isInitGamble = false

			self:updateGamble()
		end

		reset()

		return
	end

	local index = self.curActionIndex_
	self.curActionIndex_ = self.curActionIndex_ + 1

	if self.curActionIndex_ > 12 then
		self.curActionIndex_ = 1
	end

	local selectBg = self["itemBgImg" .. index]
	local sequene = self:getSequence()

	local function getter()
		return selectBg.color
	end

	local function setter(value)
		selectBg.color = value
	end

	selectBg.gameObject:SetActive(true)

	selectBg.alpha = 1

	sequene:Insert(0.1, DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0.3))
	sequene:SetAutoKill(false)
end

function ActivityTimeGamble:playAwardAction(awardIndex, call1, call2, isCool)
	self:clearTimer()

	local finalIndex = nil

	if awardIndex - 5 < 0 then
		finalIndex = 12 + awardIndex - 5 + 1
	else
		finalIndex = awardIndex - 5 + 1
	end

	local num = 24 + finalIndex - self.curActionIndex_ + 1
	local count = 0

	local function onAwardTime()
		count = count + 1

		if count < num then
			local sequene = self:getSequence()
			local index = self.curActionIndex_
			local selectBg = self["itemBgImg" .. index]

			local function getter()
				return selectBg.color
			end

			local function setter(value)
				selectBg.color = value
			end

			selectBg.gameObject:SetActive(true)

			selectBg.alpha = 1

			sequene:Insert(0.1, DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0.5))
			sequene:AppendCallback(function ()
				selectBg.gameObject:SetActive(false)
			end)
			sequene:SetAutoKill(false)

			self.curActionIndex_ = self.curActionIndex_ + 1

			if self.curActionIndex_ > 12 then
				self.curActionIndex_ = 1
			end

			return
		end

		if not self.timer2_ then
			if call1 then
				call1()

				return
			end

			local index = self.curActionIndex_
			local objs = {}
			local finalIndex = index

			for i = 0, 4 do
				local curIndex = index + i > 12 and index + i - 12 or index + i
				local selectBg = self["itemBgImg" .. curIndex]

				selectBg.gameObject:SetActive(true)

				selectBg.alpha = 0

				table.insert(objs, selectBg)

				finalIndex = curIndex

				if awardIndex == finalIndex then
					break
				end
			end

			objs[1].alpha = 1

			local function showEffect()
				if isCool then
					local itemIcon = self.gambleList[awardIndex]
					local itemData = self.gambleListData[awardIndex]
					local selectBg = self["itemBgImg" .. awardIndex]

					if not itemData.dajiangEffect then
						local effect = xyd.Spine.new(self["uiRoot" .. awardIndex])

						effect:setInfo("fx_dajiangtexiao", function ()
							effect:SetLocalPosition(0, 0, 0)
							effect:SetLocalScale(1, 1, 1)
							effect:setRenderTarget(itemIcon:getIconSprite(), 1)
							effect:play("texiao", 1, 1, function ()
								effect:SetActive(false)
							end)
						end)

						itemData.dajiangEffect = effect
					else
						local dajiangEffect = itemData.dajiangEffect

						dajiangEffect:SetActive(true)
						dajiangEffect:play("texiao", 1, 1, function ()
							dajiangEffect:SetActive(false)
						end)
					end
				end
			end

			local actions = {}
			local length = #objs

			for i = 1, #objs do
				table.insert(actions, {
					alpha = 0,
					obj = objs[i],
					delay = 0.2 + i * 0.1,
					miss = 0.2 + i * 0.1
				})
			end

			table.insert(actions, {
				delay = 0.6,
				alpha = 0,
				obj = objs[length]
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 1,
				obj = objs[length]
			})
			table.insert(actions, {
				call = showEffect
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 0,
				obj = objs[length]
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 1,
				obj = objs[length]
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 0,
				obj = objs[length]
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 1,
				obj = objs[length]
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 0,
				obj = objs[length]
			})

			if call1 then
				call1()
			end

			local function timer2Func()
				local action = actions[1]

				if action then
					if action.call then
						action.call()
						table.remove(actions, 1)

						if actions[1] and actions[1].obj then
							actions[1].obj.alpha = 1
						end
					else
						action.delay = action.delay - 0.1

						if action.delay <= 0 then
							action.obj.alpha = action.alpha == 1 and 0 or 1
							local sequene2 = self:getSequence()
							local miss = action.miss or 0.2

							local function getter()
								return action.obj.color
							end

							local function setter(value)
								action.obj.color = value
							end

							action.obj.gameObject:SetActive(true)

							action.obj.alpha = 1

							sequene2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, action.alpha, miss))
							sequene2:SetAutoKill(false)
							table.remove(actions, 1)

							if actions[1] and actions[1].obj then
								actions[1].obj.alpha = 1
							end
						end
					end
				end

				if #actions <= 0 and call2 then
					call2()
				end
			end

			self.timer2_ = self:getTimer(timer2Func, 0.1, -1)

			self.timer2_:Start()
		end

		self.curActionIndex_ = self.curActionIndex_ + 4

		if self.curActionIndex_ > 12 then
			self.curActionIndex_ = self.curActionIndex_ - 12
		end
	end

	self.rewardTimer_ = self:getTimer(onAwardTime, 0.1, -1)

	self.rewardTimer_:Start()
end

function ActivityTimeGamble:playStandbyAction()
	self:clearTimer()

	if not self.standbyTimer_ then
		self.standbyTimer_ = self:getTimer(handler(self, self.standbyTimer), 1, -1)
	end

	self.standbyTimer_:Start()
end

function ActivityTimeGamble:standbyTimer()
	local index = self.curActionIndex_
	self.curActionIndex_ = self.curActionIndex_ + 1

	if self.curActionIndex_ > 12 then
		self.curActionIndex_ = 1
	end

	local selectBg = self["itemBgImg" .. index]
	local sequene = self:getSequence()

	local function getter()
		return selectBg.color
	end

	local function setter(value)
		selectBg.color = value
	end

	selectBg.gameObject:SetActive(true)

	selectBg.alpha = 1

	sequene:Insert(1, DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0.2))
	sequene:SetAutoKill(false)
end

function ActivityTimeGamble:clearTimer()
	if self.rewardTimer_ then
		self.rewardTimer_:Stop()

		self.rewardTimer_ = nil
	end

	if self.refreshTimer_ then
		self.refreshTimer_:Stop()

		self.refreshTimer_ = nil
	end

	if self.standbyTimer_ then
		self.standbyTimer_:Stop()

		self.standbyTimer_ = nil
	end
end

function ActivityTimeGamble:loadSkinModel()
	local partnerID = xyd.tables.miscTable:getVal("activity_time_partner_id")
	local modelID = xyd.tables.partnerTable:getModelID(partnerID)
	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)

	if self.skinModel then
		self.skinModel:play("idle", 0)
	else
		local model = xyd.Spine.new(self.girlModel)

		model:setInfo(name, function ()
			self.modelID = modelID

			model:SetLocalPosition(0, 0, 0)
			model:SetLocalScale(scale, scale, 1)
			model:play("idle", 0)
		end)

		self.skinModel = model
	end

	if self.bgModel then
		self.bgModel:play("animation", 0)
	else
		local model = xyd.Spine.new(self.mainBg)

		model:setInfo("magic_circle", function ()
			model:SetLocalPosition(0, 0, 0)
			model:SetLocalScale(1, 1, 1)
			model:play("animation", 0)
		end)

		self.bgModel = model
	end
end

return ActivityTimeGamble
