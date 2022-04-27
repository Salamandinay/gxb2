local BaseWindow = import(".BaseWindow")
local CheckInPopUpWindow = class("CheckInPopUpWindow", BaseWindow)
local CheckIn = import("app.windows.activity.CheckIn")
local CheckInPopUpItem = CheckIn.CheckInPopUpItem
local json = require("cjson")

function CheckInPopUpWindow:ctor(name, params)
	CheckInPopUpWindow.super.ctor(self, name, params)

	self.itemArray = {}
	self.rewardItems = {}
	self.rewardFloatItems = {}
	self.allitems = {}
	self.roundCount = 15
	self.lineCount = 5
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.CHECKIN)
	self.gotDays = self.activityData.detail.count
	self.onlineDays = self.activityData.detail.online_days
	self.currentState = xyd.Global.lang
	self.showNext = false
	self.isFirstSendMessage = true
end

function CheckInPopUpWindow:getUIComponent()
	local go = self.window_.transform
	self.mainGroup = go:NodeByName("groupAction").gameObject
	self.maskImg = self.mainGroup:NodeByName("maskImg").gameObject
	self.backgroundImg = self.mainGroup:NodeByName("backgroundImg").gameObject
	self.partnerGroup = self.mainGroup:NodeByName("partnerGroup").gameObject
	self.itemBigItemMask = self.mainGroup:NodeByName("itemBigItemMask").gameObject
	self.itemBigFinishMask = self.mainGroup:NodeByName("itemBigFinishMask").gameObject
	self.itemBigcloseMask = self.mainGroup:NodeByName("itemBigcloseMask").gameObject
	self.finisheffecgCon = self.mainGroup:NodeByName("finisheffecgCon").gameObject
	self.partnerTalk = self.mainGroup:NodeByName("partnerTalk").gameObject
	self.partnerTalkText1 = self.partnerTalk:ComponentByName("e:Group/partnerTalkText1", typeof(UILabel))
	self.partnerTalkText2 = self.partnerTalk:ComponentByName("e:Group/partnerTalkText2", typeof(UILabel))
	self.blackboardGroup = self.mainGroup:NodeByName("blackboardGroup").gameObject
	self.lineGroup = self.blackboardGroup:NodeByName("lineGroup").gameObject

	for i = 1, 3 do
		self["line" .. i] = self.lineGroup:NodeByName("line" .. i).gameObject
	end

	self.itemGroup = self.blackboardGroup:NodeByName("itemGroup").gameObject
	self.checkInPopUpItem = self.itemGroup:NodeByName("checkInPopUpItem").gameObject

	for i = 1, 3 do
		self["itemGroup" .. i] = self.itemGroup:NodeByName("itemGroup" .. i).gameObject
		self["effectGroup" .. i] = self.itemGroup:NodeByName("effectGroup" .. i).gameObject
		self["itemGroupLayout" .. i] = self["itemGroup" .. i]:GetComponent(typeof(UILayout))
	end

	self.checkInLocationGroup = self.mainGroup:NodeByName("checkInLocationGroup").gameObject
	self.checkInLocationText = self.checkInLocationGroup:ComponentByName("checkInLocationText", typeof(UILabel))
end

function CheckInPopUpWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	local scale = 1 + 0.1 * self.scale_num_contrary

	self.backgroundImg:SetLocalScale(scale, scale, scale)
	self.partnerTalk:Y(500 + 4 * self.scale_num_contrary)
	self.blackboardGroup:Y(-322 + -89 * self.scale_num_contrary)
	self:setItem()
	self:setEffect()
	self:register()
end

function CheckInPopUpWindow:register()
	CheckInPopUpWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onActivityAward))

	UIEventListener.Get(self.itemBigItemMask.gameObject).onClick = handler(self, self.removeCircleEffect)
	UIEventListener.Get(self.itemBigcloseMask.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.itemBigFinishMask.gameObject).onClick = handler(self, self.removefinishEffect)
end

function CheckInPopUpWindow:removeCircleEffect()
	for i in pairs(self.rewardItems) do
		local effect = self.rewardItems[i]:getEffect()

		if effect then
			effect:stop()
			self.rewardItems[i]:playCompleteFun()
			self.rewardItems[i]:removePlayCompleteFun()
		end
	end

	self.itemBigItemMask:SetActive(false)
end

function CheckInPopUpWindow:removefinishEffect()
	if self.finishCallback then
		self.finishCallback()
		self.itemBigFinishMask:SetActive(false)
	end
end

function CheckInPopUpWindow:setEffect()
	if xyd.isIosTest() then
		local partner = NGUITools.AddChild(self.mainGroup, "partner"):AddComponent(typeof(UITexture))

		xyd.setUITextureAsync(partner, "Textures/partner_picture_web/partner_picture_11001")

		partner.depth = 3
		partner.height = 1000
		partner.width = 1000

		partner:Y(100)
	else
		local effect = xyd.Spine.new(self.partnerGroup.gameObject)

		effect:setInfo("guanggao02_lihui01", function ()
			effect:setRenderTarget(self.partnerGroup:GetComponent(typeof(UITexture)), 1)
			effect:SetLocalScale(0.9, 0.9, 0.9)
			effect:SetLocalPosition(0, -576 + -6 * self.scale_num_contrary, 0)
			effect:play("animation", 0)
		end)
	end
end

function CheckInPopUpWindow:initData()
	self.realRoundStartDay = math.floor(self.gotDays / self.roundCount) * self.roundCount + 1
end

function CheckInPopUpWindow:setItem()
	NGUITools.DestroyChildren(self.itemGroup1.transform)
	NGUITools.DestroyChildren(self.itemGroup2.transform)
	NGUITools.DestroyChildren(self.itemGroup3.transform)

	self.rewardFloatItems = {}
	self.rewardItems = {}
	self.allitems = {}
	self.gotDays = self.activityData.detail.count
	self.onlineDays = self.activityData.detail.online_days

	self:initText(self.gotDays, self.onlineDays)

	local id = math.floor(self.gotDays / 15) * 15

	self:initData()

	self.canGetNum = 0

	self.checkInPopUpItem:SetActive(true)

	for i = 0, self.roundCount do
		local posId = i
		local groupId = math.floor(i / self.lineCount) + 1
		local realDay = self.realRoundStartDay + i
		local params = {
			gotDays = self.gotDays,
			onlineDays = self.onlineDays,
			realDay = realDay,
			posId = posId
		}

		if groupId > 3 then
			break
		end

		if self["itemGroup" .. groupId] then
			local tmp = NGUITools.AddChild(self["itemGroup" .. groupId].gameObject, self.checkInPopUpItem.gameObject)
			local cItem = CheckInPopUpItem.new(tmp, self, params)

			table.insert(self.allitems, cItem)
			cItem:getGo():SetLocalScale(0.95, 0.95, 0.95)

			if cItem:isCanGet() then
				self.canGetNum = self.canGetNum + 1

				if not self.itemIcon_0 then
					self.itemIcon_0 = cItem
				end

				cItem.isGetAward = true

				table.insert(self.rewardItems, cItem)

				local rewardItem = {
					item_id = cItem.itemID,
					item_num = cItem.num,
					posId = posId
				}

				table.insert(self.rewardFloatItems, rewardItem)
			end
		end
	end

	for i = 1, 3 do
		self["itemGroupLayout" .. i]:Reposition()
	end

	self.checkInPopUpItem:SetActive(false)
end

function CheckInPopUpWindow:initText(gotDays, onlineDays)
	self.checkInLocationText.text = __("CHECKIN_POPUP_TITLE")
	self.partnerTalkText1.text = xyd.replaceSpace(__("CHECKIN_POPUP_TEXT1"))
	self.partnerTalkText2.text = xyd.replaceSpace(__("CHECKIN_POPUP_TEXT2"))

	self:updateText()
end

function CheckInPopUpWindow:updateText()
	if self.gotDays < self.onlineDays then
		self.partnerTalkText1:SetActive(true)
		self.partnerTalkText2:SetActive(false)
	else
		self.partnerTalkText1:SetActive(false)
		self.partnerTalkText2:SetActive(true)
	end
end

function CheckInPopUpWindow:getAwards()
	if #self.rewardItems <= 0 then
		for i in pairs(self.allitems) do
			if self.allitems[i].action then
				self.allitems[i].action:Kill(true)
			end
		end

		self:close()

		return
	end

	if not self.isFirstSendMessage then
		return
	end

	if self.isFirstSendMessage then
		self.isFirstSendMessage = false
	end

	local data = {
		num = tonumber(self.canGetNum)
	}
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.CHECKIN
	msg.params = json.encode(data)

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function CheckInPopUpWindow:getAwardsAuto()
	local data = {
		num = tonumber(self.canGetNum)
	}
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.CHECKIN
	msg.params = json.encode(data)

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function CheckInPopUpWindow:onActivityAward(event)
	local id = event.data.activity_id

	if id ~= self.activityData.id then
		return
	end

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.CHECKIN)

	self.activityData:onAward(event.data)

	self.gotDays = self.activityData.detail.count
	self.onlineDays = self.activityData.detail.online_days

	self:initData()

	if self.gotDays ~= 0 and self.gotDays % self.roundCount == 0 then
		self.showNext = true
	else
		self.showNext = false
	end

	self:playCircleAnimation(self.showNext)
end

function CheckInPopUpWindow:playCircleAnimation(showNext)
	xyd.SoundManager.get():playSound(2140)

	if #self.rewardItems > 0 then
		self.itemBigItemMask:SetActive(true)
	end

	for i = #self.rewardItems, 1, -1 do
		local itemData = self.rewardFloatItems[i]
		local posId = itemData.posId
		local groupId = math.floor(posId / self.lineCount) + 1
		local itemNum = (posId + 1) % self.lineCount

		if itemNum == 0 then
			itemNum = self.lineCount
		end

		itemNum = itemNum - 1

		if self["itemGroup" .. groupId] then
			local effect = xyd.Spine.new(self.rewardItems[i]:getEffectCon().gameObject)

			local function playComplete()
				local isLast = i == 1

				self.rewardItems[i]:refreshItem({
					gotDays = self.gotDays,
					onlineDays = self.onlineDays
				})

				if isLast then
					xyd.itemFloat(self.rewardFloatItems, nil, , 6000)

					if showNext then
						self:updateText()
						self:waitForTime(2, function ()
							self:playFinishAnimation()
						end)
					else
						self:setCloseWindow()
					end

					self.itemBigItemMask:SetActive(false)
				end

				effect:SetActive(false)
				effect:destroy()
				self.rewardItems[i]:removeEffect()
				self.rewardItems[i]:removePlayCompleteFun()
			end

			self:waitForTime(2, function ()
				if self.rewardItems[i].isPlayCircleEffectComplete == false then
					playComplete()

					self.rewardItems[i].isPlayCircleEffectComplete = true

					if effect then
						effect:destroy()
					end
				end
			end)
			effect:setInfo("fx_login_circle", function ()
				if self.rewardItems[i].isPlayCircleEffectComplete == false then
					effect:setRenderTarget(self.rewardItems[i]:getEffectCon():GetComponent(typeof(UITexture)), 1)
					self.rewardItems[i]:setEffect(effect)
					self.rewardItems[i]:setPlayCompleteFun(playComplete)
					effect:play("texiao01", 1, 1, playComplete)

					self.rewardItems[i].isPlayCircleEffectComplete = true
				end
			end, true)

			self.rewardItems[i].isGetAward = false
		end
	end
end

function CheckInPopUpWindow:playOpenAnimation(callback)
	CheckInPopUpWindow.super.playOpenAnimation(self, callback)
	self:waitForTime(0.2, function ()
		self.leftUpLabelConAction = DG.Tweening.DOTween.Sequence()

		self.leftUpLabelConAction:Append(self.checkInLocationGroup.transform:DOScale(Vector3(1, 1.1, 1), 0.20800000000000002))
		self.leftUpLabelConAction:Append(self.checkInLocationGroup.transform:DOScale(Vector3(1, 0.95, 1), 0.20800000000000002))
		self.leftUpLabelConAction:Append(self.checkInLocationGroup.transform:DOScale(Vector3(1, 1, 1), 0.29900000000000004))
		self.leftUpLabelConAction:AppendCallback(function ()
			self.leftUpLabelConAction:Kill(true)
		end)
	end)
	self.partnerGroup:X(-1000)
	self:waitForTime(0.2, function ()
		self.partnerGroupAction = DG.Tweening.DOTween.Sequence()

		for i = 1, 11 do
			self.partnerGroupAction:Append(self.partnerGroup.transform:DOLocalMoveX(-10 * math.pow(i - 11, 2), 0.045))
		end

		self.partnerGroupAction:AppendCallback(function ()
			self.partnerGroupAction:Kill(true)
		end)
	end)
	self.blackboardGroup:X(1000)
	self:waitForTime(0.395, function ()
		self.blackboardGroupAction = DG.Tweening.DOTween.Sequence()

		for i = 1, 13 do
			self.blackboardGroupAction:Append(self.blackboardGroup.transform:DOLocalMoveX(10 * math.pow(i - 13, 2), 0.03))
		end

		self.blackboardGroupAction:AppendCallback(function ()
			self.blackboardGroupAction:Kill(true)

			UIEventListener.Get(self.backgroundImg.gameObject).onClick = handler(self, self.getAwards)
		end)
	end)
end

function CheckInPopUpWindow:playFinishAnimation()
	local function complete()
		self.finishAnimation:stop()
		self.finishAnimation:SetActive(false)
		self:setItem()
		self:getAwardsAuto()
		self:setCloseWindow()
		self.maskImg:SetActive(false)
		self.itemBigFinishMask:SetActive(false)
	end

	self.finishCallback = complete

	self.maskImg:SetActive(true)
	self.itemBigFinishMask:SetActive(true)

	self.finishAnimation = xyd.Spine.new(self.finisheffecgCon.gameObject)

	self.finishAnimation:setInfo("fx_login_finish", function ()
		self.finishAnimation:setRenderTarget(self.finisheffecgCon:GetComponent(typeof(UITexture)), 1)
		self.finishAnimation:play("texiao01", 1, 1, complete)
	end)
end

function CheckInPopUpWindow:setCloseWindow()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.CHECKIN)
	self.gotDays = self.activityData.detail.count
	self.onlineDays = self.activityData.detail.online_days

	if self.gotDays == self.onlineDays then
		self.itemBigcloseMask:SetActive(true)
		self:waitForTime(2, function ()
			self:close()
		end)
	end
end

function CheckInPopUpWindow:willOpen()
	CheckInPopUpWindow.super.willOpen(self)
end

function CheckInPopUpWindow:didClose()
	CheckInPopUpWindow.super.didClose(self)

	xyd.MainController.get().openPopWindowNum = xyd.MainController.get().openPopWindowNum - 1
end

function CheckInPopUpWindow:iosTestChangeUI()
	local winTrans = self.window_.transform
	self.backgroundImg:GetComponent("AsyncUITexture").enabled = false

	xyd.setUITexture(self.backgroundImg:GetComponent(typeof(UITexture)), "Textures/texture_ios/check_in_bg_ios_test")

	self.partnerTalkImg = winTrans:NodeByName("groupAction/partnerTalk/e:Group/partnerTalkImg").gameObject
	self.partnerTalkImg:GetComponent("AsyncUITexture").enabled = false

	xyd.setUITexture(self.partnerTalkImg:GetComponent(typeof(UITexture)), "Textures/texture_ios/check_in_bubble_ios_test")

	self.blackboardImg = winTrans:NodeByName("groupAction/blackboardGroup/blackboardImg").gameObject
	self.blackboardImg:GetComponent("AsyncUITexture").enabled = false

	xyd.setUITexture(self.blackboardImg:GetComponent(typeof(UITexture)), "Textures/texture_ios/check_in_bg_hb_ios_test")
	winTrans:NodeByName("groupAction/blackboardGroup/lineGroup"):SetActive(false)
	xyd.setUITextureByNameAsync(winTrans:ComponentByName("groupAction/checkInLocationGroup/checkInLocationImg", typeof(UITexture)), "check_in_bg_qd_ios_test")
end

return CheckInPopUpWindow
