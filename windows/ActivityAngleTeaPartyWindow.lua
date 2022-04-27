local BaseWindow = import(".BaseWindow")
local ActivityAngleTeaPartyWindow = class("ActivityAngleTeaPartyWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local WindowTop = require("app.components.WindowTop")

function ActivityAngleTeaPartyWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_ANGLE_TEA_PARTY)
	self.id = xyd.ActivityID.ACTIVITY_ANGLE_TEA_PARTY
	self.giftBagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
end

function ActivityAngleTeaPartyWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:initTopGroup()
	self:registerEvent()
	self:layout()
end

function ActivityAngleTeaPartyWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.modelGroup = self.groupAction:NodeByName("modelGroup").gameObject
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.logoImg = self.topGroup:ComponentByName("logoImg", typeof(UISprite))
	self.timeGroup = self.topGroup:NodeByName("timeGroup").gameObject
	self.countdown = self.timeGroup:ComponentByName("countdown", typeof(UILabel))
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.helpBtn = self.groupAction:NodeByName("helpBtn").gameObject
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.giftbagGroup = self.midGroup:NodeByName("giftbagGroup").gameObject
	self.giftbagBg = self.giftbagGroup:ComponentByName("giftbagBg", typeof(UISprite))
	self.giftbagTitleLabel = self.giftbagGroup:ComponentByName("giftbagTitleLabel", typeof(UILabel))
	self.giftbagDescLabel = self.giftbagGroup:ComponentByName("giftbagDescLabel", typeof(UILabel))
	self.giftbagAwardGroup = self.giftbagGroup:NodeByName("giftbagAwardGroup").gameObject
	self.giftbagAwardGroup_UILayout = self.giftbagGroup:ComponentByName("giftbagAwardGroup", typeof(UILayout))
	self.giftbagBuyBtn = self.giftbagGroup:NodeByName("giftbagBuyBtn").gameObject
	self.giftbagBuyBtnLabel = self.giftbagBuyBtn:ComponentByName("giftbagBuyBtnLabel", typeof(UILabel))
	self.giftbagTipLabel = self.giftbagGroup:ComponentByName("giftbagTipLabel", typeof(UILabel))
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.progressGroup = self.bottomGroup:NodeByName("progressGroup").gameObject
	self.progressBar = self.progressGroup:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressValueImg = self.progressBar:ComponentByName("progressValueImg", typeof(UISprite))
	self.progressBarLabel = self.progressBar:ComponentByName("progressBarLabel", typeof(UILabel))
	self.awardNodeGroup = self.progressGroup:NodeByName("awardNodeGroup").gameObject

	for i = 1, 4 do
		self["Node" .. i] = self.awardNodeGroup:NodeByName("Node" .. i).gameObject
		self["barNodeImg" .. i] = self["Node" .. i]:ComponentByName("barNodeImg", typeof(UISprite))
		self["cupNode" .. i] = self["Node" .. i]:NodeByName("cupNode").gameObject
		self["awardNode" .. i] = self["Node" .. i]:NodeByName("awardNode").gameObject
	end

	self.gotoBtn = self.bottomGroup:NodeByName("gotoBtn").gameObject
	self.gotoBtnLabel = self.gotoBtn:ComponentByName("gotoBtnLabel", typeof(UILabel))
end

function ActivityAngleTeaPartyWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function ActivityAngleTeaPartyWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		self:onGetAward(event)
	end)
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, function (event)
		if self.activityData.detail.charges[1].limit_times <= self.activityData.detail.charges[1].buy_times then
			xyd.applyGrey(self.giftbagBuyBtn:GetComponent(typeof(UISprite)))
			self.giftbagBuyBtnLabel:ApplyGrey()
			xyd.setTouchEnable(self.giftbagBuyBtn, false)
			self:updateState()
		end
	end)

	for i = 1, 4 do
		UIEventListener.Get(self["awardNode" .. i]:NodeByName("clickMask").gameObject).onClick = handler(self, function ()
			self:getAward(i)
		end)
		UIEventListener.Get(self["awardNode" .. i]:NodeByName("clickMask1").gameObject).onClick = handler(self, function ()
			if self.activityData.detail.awarded[i] ~= 1 then
				xyd.alertTips(__("ACTIVITY_TEA_TEXT5"))
			end
		end)
		UIEventListener.Get(self["cupNode" .. i]:NodeByName("clickMask1").gameObject).onClick = handler(self, function ()
			xyd.alertTips(__("ACTIVITY_TEA_TEXT6"))
		end)
		UIEventListener.Get(self["cupNode" .. i]:NodeByName("clickMask").gameObject).onClick = handler(self, function ()
			if self.activityData:getNowCharterState() == i - 1 then
				local battleIds = self.activityData.awardTable:getBattleID(i)

				if battleIds[1] ~= nil and battleIds[2] then
					local story_id = xyd.tables.activityPlotListTable:getPlotIDs(tonumber(self.activityData.plotIDs[i]))
					self.activityData.nowPlotID = story_id
					local battleId1 = battleIds[1]
					local battleId2 = battleIds[2]

					xyd.BattleController.get():frontBattleBy2BattleId(battleId1, battleId2, xyd.BattleType.ACTIVITY_ANGLE_TEA_PARTY, 1)
				else
					local story_id = xyd.tables.activityPlotListTable:getPlotIDs(tonumber(self.activityData.plotIDs[i]))

					xyd.WindowManager.get():openWindow("story_window", {
						is_back = true,
						story_type = xyd.StoryType.ACTIVITY,
						story_id = story_id[2]
					})
				end

				self.activityData:setNowCharterState(i)
				self:updateState()
			else
				xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_TEA_TEXT3"))
			end
		end)
	end

	UIEventListener.Get(self.gotoBtn).onClick = handler(self, function ()
		xyd.db.misc:setValue({
			key = "angle_tea_party_goto_red_mask_timestamp",
			value = xyd.getServerTime()
		})
		self.activityData:getRedMarkState()

		local getwayID = xyd.tables.miscTable:split2Cost("activity_tea_getway", "value", "|")[1]

		self:goWay(getwayID, nil, , function ()
			xyd.closeWindow("activity_angle_tea_party_window")
		end)
	end)
	UIEventListener.Get(self.giftbagBuyBtn).onClick = handler(self, function ()
		self.giftBagID = xyd.tables.activityTable:getGiftBag(self.id)[1]

		xyd.SdkManager.get():showPayment(self.giftBagID)
	end)
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_TEA_TEXT1"
		})
	end)
end

function ActivityAngleTeaPartyWindow:layout()
	self:resizePosY(self.topGroup, 582, 644)
	self:resizePosY(self.midGroup, 6, -11)
	self:setTimeShow()
	self:createEffect()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_angle_tea_party_logo_" .. xyd.Global.lang)

	self.giftbagDescLabel.text = __("ACTIVITY_TEA_TEXT2")
	self.giftbagTitleLabel.text = __("ACTIVITY_TEA_TITLE3")
	self.giftbagTipLabel.text = __("MONTH_CARD_VIP", xyd.tables.giftBagTable:getVipExp(self.giftBagID))
	self.giftbagBuyBtnLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagID))
	self.gotoBtnLabel.text = __("ACTIVITY_TEA_TITLE1")
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	local awards = xyd.tables.giftTable:getAwards(self.giftID)

	for i = 1, #awards do
		local award = awards[i]

		if award[1] ~= 8 and xyd.tables.itemTable:getType(award[1]) ~= 12 then
			local icon = xyd.getItemIcon({
				show_has_num = true,
				hideText = false,
				scale = 0.6018518518518519,
				uiRoot = self.giftbagAwardGroup,
				itemID = award[1],
				num = award[2]
			})
		end

		if xyd.tables.itemTable:getType(award[1]) == 12 then
			local icon = xyd.getItemIcon({
				show_has_num = true,
				isNew = true,
				hideText = false,
				scale = 0.6296296296296297,
				uiRoot = self.giftbagAwardGroup,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	end

	self.giftbagAwardGroup_UILayout:Reposition()

	for i = 1, 4 do
		self["awardIconImg" .. i] = self["awardNode" .. i]:ComponentByName("awardIconImg", typeof(UISprite))
		self["awardIconRedMask" .. i] = self["awardNode" .. i]:ComponentByName("redMask", typeof(UISprite))
		self["cupAwardedMask" .. i] = self["cupNode" .. i]:ComponentByName("awardMask", typeof(UISprite))
		self["awardIconNumLabe" .. i] = self["awardNode" .. i]:ComponentByName("awardNumLabel", typeof(UILabel))

		if i == 4 then
			local icon = xyd.getItemIcon({
				isNew = false,
				hideText = true,
				show_has_num = false,
				scale = 0.6018518518518519,
				uiRoot = self["awardIconImg" .. i].gameObject,
				itemID = self.activityData.awards[i][1][1]
			})
			self.heroIcon = icon
		else
			xyd.setUISpriteAsync(self["awardIconImg" .. i], nil, "icon_" .. self.activityData.awards[i][1][1])
		end

		self["awardIconNumLabe" .. i].text = self.activityData.awards[i][1][2]
		self["cupNode" .. i]:ComponentByName("cupNumLabel", typeof(UILabel)).text = self.activityData.needPoints[i]
	end

	self:updateState()
end

function ActivityAngleTeaPartyWindow:setTimeShow()
	CountDown.new(self.countdown, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.timeLabel.text = __("END_TEXT")
end

function ActivityAngleTeaPartyWindow:createEffect()
	for i = 1, 4 do
		self["cupEffect" .. i] = xyd.Spine.new(self["cupNode" .. i]:NodeByName("cupEffectNode").gameObject)

		self["cupEffect" .. i]:setInfo("fx_act_icon_2", function ()
			self["cupEffect" .. i]:setRenderTarget(self["cupNode" .. i]:ComponentByName("cupImg", typeof(UISprite)), 1)
			self["cupEffect" .. i]:play("texiao01", 0)
		end)
	end

	self:loadModel()
end

function ActivityAngleTeaPartyWindow:goWay(id, wndCallback, callback, closeCallBack)
	local getWayID = id
	local function_id = xyd.tables.getWayTable:getFunctionId(getWayID)
	local windows = xyd.tables.getWayTable:getGoWindow(getWayID)
	local params = xyd.tables.getWayTable:getGoParam(getWayID)

	if not xyd.checkFunctionOpen(function_id) then
		return false
	end

	if callback then
		callback()
	end

	for i = 1, #windows do
		local windowName = windows[i]

		if windowName ~= "activity_window" then
			if closeCallBack then
				if params[i] then
					params[i].closeCallBack = closeCallBack
				else
					params[i] = {
						closeCallBack = closeCallBack
					}
				end
			end

			xyd.WindowManager.get():openWindow(windowName, params[i], wndCallback, nil)
		end
	end
end

function ActivityAngleTeaPartyWindow:loadModel()
	local partnerID = 56006
	local modelID = 5600606
	local scale = xyd.tables.modelTable:getScale(modelID)
	local name = xyd.tables.modelTable:getModelName(modelID)

	if self.skinModel then
		return
	end

	if self.skinModel then
		self.skinModel:destroy()
	end

	local model = xyd.Spine.new(self.modelGroup)

	model:setInfo("luxifeier_pifu05_lihui01", function ()
		model:SetLocalPosition(0, 0, 0)
		model:SetLocalScale(scale, scale, 1)
		model:setRenderTarget(self.modelGroup:GetComponent(typeof(UITexture)), 1)
		model:play("animation", 0)
	end)

	self.skinModel = model
end

function ActivityAngleTeaPartyWindow:updateState()
	if self.activityData.detail.charges[1].limit_times <= self.activityData.detail.charges[1].buy_times then
		xyd.applyGrey(self.giftbagBuyBtn:GetComponent(typeof(UISprite)))
		self.giftbagBuyBtnLabel:ApplyGrey()
		xyd.setTouchEnable(self.giftbagBuyBtn, false)
	end

	if self.activityData:checkRedPoint_goto() == true then
		self.gotoBtn:NodeByName("redMask").gameObject:SetActive(true)
	else
		self.gotoBtn:NodeByName("redMask").gameObject:SetActive(false)
	end

	for i = 1, 4 do
		if self.activityData.needPoints[i] <= self.activityData.detail.point or self.activityData.detail.charges[1].buy_times > 0 then
			self["barNodeImg" .. i].gameObject:SetActive(true)
		else
			self["barNodeImg" .. i].gameObject:SetActive(false)
		end

		if self.activityData.detail.awarded[i] ~= 1 then
			if self.activityData:checkRedPoint_award(i) == true then
				self["awardNode" .. i]:NodeByName("clickMask").gameObject:SetActive(true)
				self["awardIconRedMask" .. i]:SetActive(true)
			else
				self["awardNode" .. i]:NodeByName("clickMask").gameObject:SetActive(false)
				self["awardIconRedMask" .. i]:SetActive(false)
			end
		else
			xyd.applyGrey(self["awardIconImg" .. i])

			if i == 4 then
				self.heroIcon:setGrey()
			end

			self["awardIconRedMask" .. i]:SetActive(false)
			self["awardNode" .. i]:NodeByName("clickMask").gameObject:SetActive(false)
		end

		if i <= self.activityData:getNowCharterState() then
			self["cupNode" .. i]:NodeByName("awardedImg").gameObject:SetActive(true)
			self["cupAwardedMask" .. i]:SetActive(true)
			self["cupNode" .. i]:NodeByName("clickMask1").gameObject:SetActive(false)
		else
			self["cupNode" .. i]:NodeByName("awardedImg").gameObject:SetActive(false)
			self["cupAwardedMask" .. i]:SetActive(false)
			self["cupNode" .. i]:NodeByName("clickMask1").gameObject:SetActive(true)
		end
	end

	self:checkRedPoint()
	self:updateProgress()
	self.activityData:getRedMarkState()
end

function ActivityAngleTeaPartyWindow:checkRedPoint()
	for i = 1, 4 do
		if self.activityData:checkRedPoint_cup(i) == true then
			self["cupNode" .. i]:NodeByName("clickMask").gameObject:SetActive(true)
			self["cupNode" .. i]:NodeByName("redMask").gameObject:SetActive(true)
			self["cupNode" .. i]:NodeByName("cupEffectNode").gameObject:SetActive(true)
		else
			self["cupNode" .. i]:NodeByName("clickMask").gameObject:SetActive(false)
			self["cupNode" .. i]:NodeByName("redMask").gameObject:SetActive(false)
			self["cupNode" .. i]:NodeByName("cupEffectNode").gameObject:SetActive(false)
		end
	end
end

function ActivityAngleTeaPartyWindow:updateProgress()
	if self.activityData.detail.charges[1].buy_times > 0 then
		self.progressBar.value = self.activityData.needPoints[4] / self.activityData.needPoints[4]
		self.progressBarLabel.text = self.activityData.needPoints[4] .. "/" .. self.activityData.needPoints[4]
	else
		local values = {
			0.17,
			0.27,
			0.31,
			0.25
		}
		local totalEnergy = self.activityData.detail.point
		local value = 0

		for i = 1, 4 do
			local id = i
			local needEnergy = self.activityData.needPoints[id]

			if i == 1 then
				if totalEnergy < needEnergy then
					value = value + values[1] * totalEnergy / needEnergy
				elseif needEnergy <= totalEnergy then
					value = value + values[1]
				end
			elseif totalEnergy < needEnergy then
				if xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id - 1) < totalEnergy then
					value = value + (totalEnergy - self.activityData.needPoints[id - 1]) / (needEnergy - self.activityData.needPoints[id - 1]) * values[i]
				end
			elseif needEnergy <= totalEnergy then
				value = value + values[i]
			end
		end

		self.progressBar.value = math.min(value, 1)
		self.progressBarLabel.text = math.min(self.activityData.needPoints[4], self.activityData.detail.point) .. "/" .. self.activityData.needPoints[4]
	end
end

function ActivityAngleTeaPartyWindow:getAward(id)
	local data = require("cjson").encode({
		award_id = id
	})
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_ANGLE_TEA_PARTY
	msg.params = data

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

	self.tempAwardID = id
end

function ActivityAngleTeaPartyWindow:onGetAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_ANGLE_TEA_PARTY then
		return
	end

	local items = self.activityData.awards[self.tempAwardID]
	local infos = {}

	for i = 1, #items do
		local item = {
			item_id = items[i][1],
			item_num = items[i][2]
		}

		table.insert(infos, item)
	end

	xyd.models.itemFloatModel:pushNewItems(infos)

	self.activityData.detail.awarded[self.tempAwardID] = 1
	self.tempAwardID = nil

	self:updateState()
end

return ActivityAngleTeaPartyWindow
