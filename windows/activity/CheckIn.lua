local ActivityContent = import(".ActivityContent")
local CheckIn = class("CheckIn", ActivityContent)
local CheckInPopUpItem = class("CheckInPopUpItem", import("app.components.CopyComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
CheckIn.CheckInPopUpItem = CheckInPopUpItem
local json = require("cjson")

function CheckIn:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.itemArray = {}
	self.rewardItems = {}
	self.rewardFloatItems = {}
	self.roundCount = 15
	self.lineCount = 5
	self.showNext = false
	self.currentState = xyd.Global.lang
	self.gotDays = self.activityData.detail.count
	self.onlineDays = self.activityData.detail.online_days

	self:getUIComponent()
	self:initUIComponent()
end

function CheckIn:getPrefabPath()
	return "Prefabs/Windows/activity/check_in"
end

function CheckIn:getUIComponent()
	local go = self.go
	self.mainGroup = go:NodeByName("mainGroup").gameObject
	self.partnerTalk = self.mainGroup:NodeByName("partnerTalk").gameObject
	self.partnerTalkText1 = self.partnerTalk:ComponentByName("e:Group/partnerTalkText1", typeof(UILabel))
	self.partnerTalkText2 = self.partnerTalk:ComponentByName("e:Group/partnerTalkText2", typeof(UILabel))
	self.partnerGroup = self.mainGroup:NodeByName("partnerGroup").gameObject
	self.blackboardGroup = self.mainGroup:NodeByName("blackboardGroup").gameObject
	self.lineGroup = self.blackboardGroup:NodeByName("lineGroup").gameObject

	for i = 1, 3 do
		self["line" .. i] = self.lineGroup:NodeByName("line" .. i).gameObject
	end

	self.itemGroup = self.blackboardGroup:NodeByName("itemGroup").gameObject
	self.checkInPopUpItem = self.itemGroup:NodeByName("checkInPopUpItem").gameObject

	for i = 1, 3 do
		self["itemGroup" .. i] = self.itemGroup:NodeByName("itemGroup" .. i).gameObject
	end

	self.checkInLocationGroup = self.mainGroup:NodeByName("checkInLocationGroup").gameObject
	self.checkInLocationText = self.checkInLocationGroup:ComponentByName("checkInLocationText", typeof(UILabel))
	self.vipGroup = self.blackboardGroup:NodeByName("vipGroup").gameObject
	self.levelGroup = self.vipGroup:NodeByName("levelGroup").gameObject
	self.levelImg = self.vipGroup:ComponentByName("levelImg", typeof(UISprite))
end

function CheckIn:initUIComponent()
	self:initItem()
	self:setEffect()
	self:setVip()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onActivityAward))

	if xyd.isIosTest() then
		self.go:NodeByName("mainGroup/blackboardGroup/blackboardImg"):GetComponent("AsyncUITexture").enabled = false
		self.go:NodeByName("mainGroup/backgroundImg"):GetComponent("AsyncUITexture").enabled = false
		self.go:NodeByName("mainGroup/partnerTalk/e:Group/partnerTalkImg"):GetComponent("AsyncUITexture").enabled = false

		xyd.setUITexture(self.go:ComponentByName("mainGroup/blackboardGroup/blackboardImg", typeof(UITexture)), "Textures/texture_ios/check_in_bg_hb_ios_test")
		xyd.iosSetUISprite(self.go:ComponentByName("mainGroup/checkInLocationGroup/checkInLocationImg", typeof(UISprite)), "check_in_bg_qd_ios_test")
		xyd.setUITexture(self.go:ComponentByName("mainGroup/backgroundImg", typeof(UITexture)), "Textures/texture_ios/check_in_bg_ios_test")
		xyd.setUITexture(self.go:ComponentByName("mainGroup/partnerTalk/e:Group/partnerTalkImg", typeof(UITexture)), "Textures/texture_ios/check_in_bubble_ios_test")
		self.go:NodeByName("mainGroup/blackboardGroup/lineGroup"):SetActive(false)
	end
end

function CheckIn:setEffect()
	if xyd.isIosTest() then
		local partner = NGUITools.AddChild(self.mainGroup, "partner"):AddComponent(typeof(UITexture))

		xyd.setUITextureAsync(partner, "Textures/partner_picture_web/partner_picture_11001")

		partner.depth = 3
		partner.height = 1000
		partner.width = 1000

		partner:Y(-250)
	else
		local effect = xyd.Spine.new(self.partnerGroup.gameObject)

		effect:setInfo("guanggao02_lihui01", function ()
			effect:setRenderTarget(self.partnerGroup:GetComponent(typeof(UITexture)), 1)
			effect:SetLocalScale(0.8, 0.8, 0.8)
			effect:SetLocalPosition(0, -974 + 6 * self.scale_num_contrary, 0)
			effect:play("animation", 0)
		end)
	end
end

function CheckIn:setVip()
	local vip = xyd.models.backpack:getVipLev()
	local nums = {}

	if xyd.tables.vipTable:judgeLoginDouble(vip) then
		self.vipGroup:SetActive(true)
		NGUITools.DestroyChildren(self.levelGroup.transform)

		while vip > 0 do
			table.insert(nums, vip % 10)

			vip = math.floor(vip / 10)
		end

		while #nums > 0 do
			local num = nums[#nums]

			table.remove(nums)

			local sprite = NGUITools.AddChild(self.levelGroup.gameObject, self.levelImg.gameObject):GetComponent(typeof(UISprite))

			xyd.setUISpriteAsync(sprite, nil, "player_vip_num_" .. num, nil, , true)
		end
	else
		self.vipGroup:SetActive(false)
	end
end

function CheckIn:initData()
	self.realRoundStartDay = math.floor(self.gotDays / self.roundCount) * self.roundCount + 1
end

function CheckIn:initItem()
	NGUITools.DestroyChildren(self.itemGroup1.transform)
	NGUITools.DestroyChildren(self.itemGroup2.transform)
	NGUITools.DestroyChildren(self.itemGroup3.transform)

	self.rewardFloatItems = {}
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

				if xyd.tables.checkInTable:judgeDoubleAward(cItem.showId) and xyd.tables.vipTable:judgeLoginDouble(xyd.models.backpack:getVipLev()) then
					rewardItem.item_num = rewardItem.item_num * 2
				end

				table.insert(self.rewardFloatItems, rewardItem)
			end

			if i == 0 then
				self.firstItem = cItem
			end
		end
	end

	self.checkInPopUpItem:SetActive(false)
end

function CheckIn:initText(gotDays, onlineDays)
	self.checkInLocationText.text = __("CHECKIN_POPUP_TITLE")
	self.partnerTalkText1.text = __("CHECKIN_POPUP_TEXT1")
	self.partnerTalkText2.text = __("CHECKIN_POPUP_TEXT2")

	self:updateText()
end

function CheckIn:updateText()
	if self.gotDays < self.onlineDays then
		self.partnerTalkText1:SetActive(true)
		self.partnerTalkText2:SetActive(false)
	else
		self.partnerTalkText1:SetActive(false)
		self.partnerTalkText2:SetActive(true)
	end
end

function CheckIn:getAwards()
	if #self.rewardItems <= 0 then
		return
	end

	local data = {
		num = tonumber(self.canGetNum)
	}
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.CHECKIN
	msg.params = json.encode(data)

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function CheckIn:onActivityAward(event)
	local id = event.data.activity_id

	if id ~= self.activityData.id then
		return
	end

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.CHECKIN)

	self.activityData:onAward(event.data)

	self.gotDays = self.activityData.detail.count
	self.onlineDays = self.activityData.detail.online_days

	self:playCircleAnimation()
end

function CheckIn:playCircleAnimation()
	for i = #self.rewardItems, 1, -1 do
		local effect = xyd.Spine.new(self.rewardItems[i]:getEffectCon().gameObject)

		effect:setInfo("fx_login_circle", function ()
			effect:setRenderTarget(self.rewardItems[i]:getEffectCon():GetComponent(typeof(UITexture)), 1)
			effect:play("texiao01", 1, 1, function ()
				if i == 1 then
					xyd.models.itemFloatModel:pushNewItems(self.rewardFloatItems)
				end

				self.rewardItems[i]:refreshItem({
					gotDays = self.gotDays,
					onlineDays = self.onlineDays
				})
				effect:SetActive(false)
				effect:destroy()
			end)
		end, true)
		self:updateText()

		self.rewardItems[i].isGetAward = false
	end
end

function CheckInPopUpItem:ctor(go, checkIn, params)
	CheckInPopUpItem.super.ctor(self, go)

	self.checkIn = checkIn
	self.canGet = false
	self.hasGotten = false

	self:getUIComponent()

	self.gotDays = params.gotDays
	self.onlineDays = params.onlineDays
	self.realDay = params.realDay
	self.showId = self.realDay
	local loginLoopMax = xyd.getCheckTableLimit.LIMIT
	local loginLoopExclude = tonumber(xyd.tables.miscTable:getVal("login_loop_exclude"))
	local loopCount = loginLoopMax - loginLoopExclude

	if loginLoopMax < self.showId then
		self.showId = self.showId - loginLoopMax

		if self.showId % loopCount == 0 then
			self.showId = loginLoopMax
		else
			self.showId = self.showId % loopCount + loginLoopExclude
		end
	end

	self.id = params.posId + 1
	self.isGetAward = false

	if self.gotDays < self.realDay and self.realDay <= self.onlineDays then
		self.canGet = true
	else
		self.canGet = false
	end

	if self.realDay <= self.gotDays then
		self.hasGotten = true
	else
		self.hasGotten = false
	end

	local award = xyd.tables.checkInTable:getRewards(self.showId)
	self.itemID = award[1]
	self.num = award[2]
	self.isPlayCircleEffectComplete = false

	self:createChildren()
end

function CheckInPopUpItem:getGo()
	return self.go
end

function CheckInPopUpItem:getEffectCon()
	return self.effectGroup
end

function CheckInPopUpItem:getUIComponent()
	local go = self.go
	self.mainGroup = go:NodeByName("mainGroup").gameObject
	self.backgroundImg = self.mainGroup:ComponentByName("backgroundImg", typeof(UITexture))
	self.numImg = self.mainGroup:ComponentByName("numImg", typeof(UITexture))
	self.effectGroup = self.mainGroup:NodeByName("effectGroup").gameObject
	self.doubleMark = self.mainGroup:NodeByName("doubleMark").gameObject
	self.contentGroup = self.mainGroup:NodeByName("contentGroup").gameObject
	self.iconGroup = self.contentGroup:NodeByName("iconGroup").gameObject
	self.maskImg = self.contentGroup:NodeByName("maskImg").gameObject
	self.circleImg = self.contentGroup:NodeByName("circleImg").gameObject
end

function CheckInPopUpItem:createChildren()
	self:setIcon()
end

function CheckInPopUpItem:addEventWithGetAwards()
	if self.isGetAward then
		self.checkIn:getAwards()
	end
end

function CheckInPopUpItem:onTouchEnd()
	self.contentGroup:SetLocalScale(1, 1, 1)

	self.action = DG.Tweening.DOTween.Sequence()

	self.action:Append(self.contentGroup.transform:DOScale(1.2, 0.1))
	self.action:Append(self.contentGroup.transform:DOScale(0.95, 0.1))
	self.action:Append(self.contentGroup.transform:DOScale(1, 0.1))
	self.action:AppendCallback(function ()
		self.action:Kill(true)
	end)
	self:addEventWithGetAwards()
end

function CheckInPopUpItem:setIcon()
	local icon = nil
	local callback = handler(self, self.onTouchEnd)
	local attach_callback = handler(self, self.onTouchEnd)

	if self.canGet and not self.hasGotten then
		attach_callback = nil
	elseif self.hasGotten then
		attach_callback = nil
		self.isGetAward = true
	else
		callback = nil
	end

	local item = {
		hideText = true,
		isShowSelected = false,
		itemID = self.itemID,
		num = self.num,
		uiRoot = self.iconGroup.gameObject,
		callback = callback,
		attach_callback = attach_callback,
		scale = Vector3(0.8055555555555556, 0.8055555555555556, 0.8055555555555556)
	}
	icon = xyd.getItemIcon(item)
	self.icon = icon

	self:setLayout()
end

function CheckInPopUpItem:setLayout()
	if xyd.tables.checkInTable:judgeDoubleAward(self.showId) and xyd.tables.vipTable:judgeLoginDouble(xyd.models.backpack:getVipLev()) then
		self.doubleMark:SetActive(true)
	else
		self.doubleMark:SetActive(false)
	end

	if xyd.isIosTest() then
		if self.canGet and not self.hasGotten then
			xyd.setUITextureByNameAsync(self.numImg, "check_in__sz_" .. self.id .. "_1_ios_test", true)
			xyd.setUITextureByNameAsync(self.backgroundImg, "check_in_bg_qd_5_ios_test", true)
		elseif self.hasGotten then
			xyd.setUITextureByNameAsync(self.numImg, "check_in__sz_" .. self.id .. "_2_ios_test", true)
			xyd.setUITextureByNameAsync(self.backgroundImg, "check_in_bg_qd_4_ios_test", true)
			self.maskImg:SetActive(true)
			self.circleImg:SetActive(true)
		else
			xyd.setUITextureByNameAsync(self.numImg, "check_in__sz_" .. self.id .. "_ios_test", true)
			xyd.setUITextureByNameAsync(self.backgroundImg, "check_in_bg_qd_" .. math.ceil(self.id / 5) .. "_ios_test", true)
		end

		return
	end

	if self.canGet and not self.hasGotten then
		xyd.setUITextureByNameAsync(self.numImg, "check_in_pop_up_num_" .. self.id .. "_1", true)
		xyd.setUITextureByNameAsync(self.backgroundImg, "check_in_pop_up_frame_can_get", true)
	elseif self.hasGotten then
		xyd.setUITextureByNameAsync(self.numImg, "check_in_pop_up_num_" .. self.id .. "_2", true)
		xyd.setUITextureByNameAsync(self.backgroundImg, "check_in_pop_up_frame_has_gotten", true)
		self.maskImg:SetActive(true)
		self.circleImg:SetActive(true)
	else
		xyd.setUITextureByNameAsync(self.numImg, "check_in_pop_up_num_" .. self.id, true)
		xyd.setUITextureByNameAsync(self.backgroundImg, "check_in_pop_up_frame_" .. math.ceil(self.id / 5), true)
	end
end

function CheckInPopUpItem:canGetAndHasNotGotten()
	return self.canGet and not self.hasGotten
end

function CheckInPopUpItem:isHasGotten()
	return self.hasGotten
end

function CheckInPopUpItem:isCanGet()
	return self.canGet
end

function CheckInPopUpItem:setEffect(effect)
	self.effect = effect
end

function CheckInPopUpItem:removeEffect()
	self.effect = nil
end

function CheckInPopUpItem:getEffect()
	return self.effect
end

function CheckInPopUpItem:setPlayCompleteFun(fun)
	self.fun = fun
end

function CheckInPopUpItem:playCompleteFun()
	if self.fun then
		self.fun()

		self.fun = nil
	end
end

function CheckInPopUpItem:removePlayCompleteFun()
	self.fun = nil
end

function CheckInPopUpItem:refreshItem(params)
	self.gotDays = params.gotDays
	self.onlineDays = params.onlineDays

	if self.gotDays < self.realDay and self.realDay <= self.onlineDays then
		self.canGet = true
	else
		self.canGet = false
	end

	if self.realDay <= self.gotDays then
		self.hasGotten = true
	else
		self.hasGotten = false
	end

	self:setLayout()
end

return CheckIn
