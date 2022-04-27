function __TS__Number(value)
	local valueType = type(value)

	if valueType == "number" then
		return value
	elseif valueType == "string" then
		local numberValue = tonumber(value)

		if numberValue then
			return numberValue
		end

		if value == "Infinity" then
			return math.huge
		end

		if value == "-Infinity" then
			return -math.huge
		end

		local stringWithoutSpaces = string.gsub(value, "%s", "")

		if stringWithoutSpaces == "" then
			return 0
		end

		return 0 / 0
	elseif valueType == "boolean" then
		return value and 1 or 0
	else
		return 0 / 0
	end
end

function __TS__ArrayPush(arr, ...)
	local items = {
		...
	}

	for ____TS_index = 1, #items do
		local item = items[____TS_index]
		arr[#arr + 1] = item
	end

	return #arr
end

local ActivityContent = import(".ActivityContent")
local DarkGuard = class("DarkGuard", ActivityContent)

function DarkGuard:ctor(params)
	ActivityContent.ctor(self, params)

	self.cost_type = MiscTable:get():split2Cost("activity_guard_item_atk", "value", "#")[0]
	self.BOSS_MAX_HP = MiscTable:get():getNumber("activity_guard_boss_hp", "value")
	self.ITEM_ATTACK = MiscTable:get():split2Cost("activity_guard_item_atk", "value", "#")[1]
	self.textKey = "activity_dark_guard_text_id"
	self.delayTime = 60
	self.curType = -1
	self.floatDelta = 7
	self.isLoadActivity = false
	self.waitTime = 16
	self.effectNameList = {
		"shimo_toushi",
		"shimo_boss"
	}
	self.modelGroupNameList = {
		"itemModelGroup",
		"bossModelGroup"
	}
	self.effectList = {}
	self.curActionTimeOut = nil
	self.effectIndex_ = 1
	self.shadow_default_x = -95
	self.shadow_default_y = -30
	self.costItemNum_ = 0
	self.iconAction = TimelineLite.new()
	self.imgAction = TimelineLite.new()
	self.skinName = "DarkGuardSkin"
end

function DarkGuard:euiComplete()
	ActivityContent.euiComplete(self)

	self.playId = xyd.db.misc:getValue(self.textKey)
	self.bossModelGroup.scaleX = 0.85
	self.bossModelGroup.scaleY = 0.85

	self:initActivityGroup()
end

function DarkGuard:initPlayTextGroup()
	self.playTextGroup.visible = true
	self.activityGroup.visible = false
	self.partnerImg0.scrollRect = egret.Rectangle.new(0, 0, 1000, 1250)
	self.partnerImg1.scrollRect = egret.Rectangle.new(0, 0, 1000, 1250)

	self.playTextGroup:addEventListener(egret.TouchEvent.TOUCH_TAP, self.onTouchPirnterLabel, self)

	if self.playId then
		self.playId = __TS__Number(self.playId)
	else
		self.playId = 1
	end

	self.partnerImg0.alpha = 0.01
	self.partnerImg1.alpha = 0.01

	self:preInitImgStatus(self.playId)
	self:preInitImgStatus(ActivityGuardTable:get():getNext(self.playId))

	local ____TS_obj = self.nextPageImg
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - self.floatDelta

	self:playNextIcon()
	self:playText(true)
end

function DarkGuard:preInitImgStatus(id)
	if id == nil or id == nil then
		return
	end

	if id < 0 then
		return
	end

	local imgID = id % 2
	local img = self["partnerImg" .. tostring(String(_G, imgID))]
	img.alpha = 0.01
	local deltaXY = ActivityGuardTable:get():getPartnerPicXYDelta(id)

	if ActivityGuardTable:get():getSwitchType(id) == 2 then
		img.x = self.width - 50
	else
		img.x = deltaXY[0]
	end

	img.y = deltaXY[1]
	local scale = ActivityGuardTable:get():getScale(id)
	img.scaleX = 0.7 * scale
	img.scaleY = 0.7 * scale
	img.source = tostring(ActivityGuardTable:get():getResPath(id)) .. "_png"
end

function DarkGuard:needPlayText()
	if self.playId < 0 then
		return false
	end

	return true
end

function DarkGuard:playText(skip, same)
	if skip == nil then
		skip = false
	end

	if same == nil then
		same = false
	end

	local lastImg = self["partnerImg" .. tostring(String(_G, (self.playId + 1) % 2))]
	local img = self["partnerImg" .. tostring(String(_G, self.playId % 2))]
	self.isPlaying = true
	self.curPlayPos = 0
	self.printerLabel.text = ""

	if not same then
		self.textTitleLabel.text = ""
	end

	self.targetText = ActivityGuardTextTable:get():getDialog(self.playId)

	self.imgAction:clear()
	self.imgAction:restart()

	local type = ActivityGuardTable:get():getType(self.playId)

	if skip ~= true then
		self.playTextGroup.touchEnabled = false

		self.imgAction:to(lastImg, 0.5, {
			alpha = 0.01
		}):call(function ()
			self:preInitImgStatus(ActivityGuardTable:get():getNext(self.playId))

			self.playTextGroup.touchEnabled = true
		end)
	end

	local animationType = ActivityGuardTable:get():getSwitchType(self.playId)
	local deltaXY = ActivityGuardTable:get():getPartnerPicXYDelta(self.playId)

	if animationType ~= nil then
		if animationType == nil then
			-- Nothing
		elseif animationType == 1 then
			self.imgAction:to(img, 0.2, {
				alpha = 1
			})
		elseif animationType == 2 then
			self.imgAction:to(img, 0.35, {
				alpha = 1,
				x = deltaXY[0]
			})
		end
	end

	self.imgAction:call(function ()
		if not same then
			self:changeType(type)
		end

		self:playTextEffect()
	end)

	self.bgImg.source = tostring(ActivityGuardTable:get():getImagePath(self.playId)) .. "_png"

	self:recordPlayPos()
end

function DarkGuard:setPartnerImg()
	local img = self["partnerImg" .. tostring(String(_G, self.playId % 2))]
	local deltaXY = ActivityGuardTable:get():getPartnerPicXYDelta(self.playId)
	local scale = ActivityGuardTable:get():getScale(self.playId)
	local animationType = ActivityGuardTable:get():getSwitchType(self.playId)
	img.x = deltaXY[0]
	img.y = deltaXY[1]
	img.scaleX = 0.7 * scale
	img.scaleY = 0.7 * scale
end

function DarkGuard:playNextIcon()
	local curX = self.nextPageImg.x
	local curY = self.nextPageImg.y

	self.iconAction:to(self.nextPageImg, 0.6, {
		y = curY + 2 * self.floatDelta
	}):to(self.nextPageImg, 0.6, {
		y = curY
	}):call(function ()
		self:playNextIcon()
	end)
end

function DarkGuard:playNextText()
	local lastID = self.playId
	self.playId = ActivityGuardTable:get():getNext(self.playId)

	self:preInitImgStatus(ActivityGuardTable:get():getNext(self.playId))

	if self.playId > 0 then
		if ActivityGuardTable:get():getResPath(self.playId) == ActivityGuardTable:get():getResPath(lastID) then
			self:playText(true, true)
		else
			self:playText()
		end
	else
		if self.isLoadActivity then
			return
		end

		self.isLoadActivity = true

		self:initActivityGroup()

		local tempLineLite = TimelineLite.new()

		tempLineLite:to(self.playTextGroup, 2, {
			alpha = 0.01
		}):call(function ()
			self.playTextGroup.visible = false
		end)
		self:recordPlayPos()
	end
end

function DarkGuard:recoverScene()
	egret:clearTimeout(self.curTimeoutId)

	self.printerLabel.text = String(_G, self.targetText)
	self.isPlaying = false
	self.curTimeoutId = nil

	self.imgAction:stop()
	self.imgAction:clear()
	self:setPartnerImg()

	local img = self["partnerImg" .. tostring(String(_G, self.playId % 2))]
	local lastImg = self["partnerImg" .. tostring(String(_G, (self.playId + 1) % 2))]
	lastImg.alpha = 0.01
	img.alpha = 1

	self:changeType(ActivityGuardTable:get():getType(self.playId))
end

function DarkGuard:onTouchPirnterLabel(evt)
	if self.isPlaying then
		self:recoverScene()
	else
		self:playNextText()
	end
end

function DarkGuard:playTextEffect()
	self.curTimeoutId = egret:setTimeout(function ()
		local ____TS_obj = self.printerLabel
		local ____TS_index = "text"
		____TS_obj[____TS_index] = tostring(____TS_obj[____TS_index]) .. tostring(self.targetText[self.curPlayPos])
		self.curPlayPos = self.curPlayPos + 1

		if self.curPlayPos < self.targetText.length then
			self:playTextEffect()
		else
			self.isPlaying = false
			self.curTimeoutId = nil
		end
	end, self, self.delayTime)
end

function DarkGuard:recordPlayPos()
	xyd.db.misc:setValue({
		key = self.textKey,
		value = self.playId
	})
end

function DarkGuard:changeType(type)
	if type == 1 then
		self.printerLabel.y = 70
	else
		self.printerLabel.y = 80
		self.textTitleLabel.text = ActivityGuardTextTable:get():getName(self.playId)
	end

	if type == self.curType then
		return
	end

	self["textBgGroup" .. tostring(type)].visible = true
	self["textBgGroup" .. tostring(bit.bxor(type, 1))].visible = false
	self.curType = type
end

function DarkGuard:clearStoryEffect()
	if self.iconAction then
		self.iconAction:stop()
		self.iconAction:clear()

		self.iconAction = nil
	end
end

function DarkGuard:initActivityGroup()
	self.activityGroup.visible = true
	self.textImg.source = "dark_guard_text01_" .. tostring(xyd.Global.lang) .. "_png"
	self.shadow_.scaleY = 1.1
	self.costItemNum_ = Backpack:get():getItemNumByID(self.cost_type)

	self:clearStoryEffect()
	self:loadEffect()
	self:registerEvent()
	self:initBubbleText()
	self:initHpProgress()
	self:initActivityText()
	self:initDamageGroup()
	self:updateBtnLabel(true)
	self:delayAwardEnable(true)
end

function DarkGuard:loadEffect()
	local i = 0

	while i < #self.effectNameList do
		local effect = DragonBones.new(self.effectNameList[i + 1], {
			scaleX = i == 1 and 1.1 or 1,
			scaleY = i == 1 and 1.1 or 1,
			callback = function (____, e)
				if i == 0 then
					effect.touchEnabled = false
				elseif i == 1 then
					effect:play("idle", 0, nil, true)

					effect.touchEnabled = false
				end
			end
		})
		self.effectList[self.effectNameList[i + 1]] = effect

		self[self.modelGroupNameList[i + 1]]:addChild(self.effectList[self.effectNameList[i + 1]])

		i = i + 1
	end
end

function DarkGuard:registerEvent()
	self.fightBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, self.onFightTouch, self)
	self.awardBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, self.onAwardTouch, self)
	self.helpBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, self.onHelpTouch, self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, self.onAward, self)
end

function DarkGuard:initBubbleText()
	self.bubbleTextGroup.visible = false
end

function DarkGuard:initHpProgress()
	self.hpProgress.maximum = 100
	self.hpProgress.slideDuration = 0

	function self.hpProgress:labelFunction(value, maximum)
		local str = tostring(value) .. "%"

		return str
	end

	self:updateHpProgress()
end

function DarkGuard:initActivityText()
	self.endLabel.text = __(_G, "END_TEXT")

	if self.activityData:getUpdateTime() < xyd:getServerTime() then
		self.timeLabel.visible = false
		self.endLabel.visible = false
	else
		self.timeLabel:setCountDownTime(self.activityData:getUpdateTime() - xyd:getServerTime())
	end

	self.textLabel01.text = __(_G, "DARK_GUARD_TEXT01")
	self.timeLabel.fontFamily = xyd.NUM_FONT
end

function DarkGuard:initDamageGroup()
end

function DarkGuard:onFightTouch(evt)
	if Backpack:get():getItemNumByID(self.cost_type) <= 0 then
		xyd:showToast(__(_G, "NOT_ENOUGH", ItemTextTable:get():getName(self.cost_type)))

		return
	end

	ActivityModel:get():reqAward(xyd.ActivityID.DARK_GUARD)
end

function DarkGuard:onAward(evt)
	local real_data = JSON:parse(evt.data.detail)
	self.items = real_data.items

	self:playHit()
	self:updateBtnLabel()
end

function DarkGuard:onAwardTouch(evt)
	local pre = "activity_guard_random_award_"
	local len = MiscTable:get():getNumber(tostring(pre) .. "num", "value")
	local randomItems = {}
	local i = 1

	while len >= i do
		local cur = tostring(pre) .. tostring(String(_G, i))
		local data = MiscTable:get():split2Cost(cur, "value", "#")

		__TS__ArrayPush(randomItems, data)

		i = i + 1
	end

	local items = MiscTable:get():split2Cost("activity_guard_fixed_award", "value", "|#")

	App.WindowManager:openWindow("dark_guard_award_preview_window", {
		randomItems = randomItems,
		items = items
	})
end

function DarkGuard:onHelpTouch(evt)
	local params = {
		key = "DARK_GUARD_HELP",
		title = __(_G, "DARK_GUARD_HELP_TITLE")
	}

	App.WindowManager:openWindow("help_window", params)
end

function DarkGuard:playWait()
	self.effectList[self.effectNameList[2]]:play("idle", 0, nil, true)
end

function DarkGuard:playHurt()
	self.curActionTimeOut = egret:setTimeout(function ()
		self.effectList[self.effectNameList[2]]:play("hurt", 1, function ()
			self:playWait()
		end, true)

		self.fightBtn.touchEnabled = true

		self:updateHpProgress()
	end, self, self.waitTime)

	egret:setTimeout(function ()
		self:playDamage()
	end, self, 530)
end

function DarkGuard:playHit()
	self.isPlayingSound = true
	self.fightBtn.touchEnabled = false
	local effectName_ = function ()
		local ____TS_tmp = self.effectIndex_
		self.effectIndex_ = ____TS_tmp + 1

		return ____TS_tmp
	end() % 2 == 0 and "texiao01" or "texiao02"

	self.effectList[self.effectNameList[1]]:play(effectName_, 1, function ()
	end, true, 1.7)

	if self.curActionTimeOut then
		egret:clearTimeout(self.curActionTimeOut)
	end

	if self:isDead() then
		self:playDead()
	else
		self:playHurt()
	end
end

function DarkGuard:wrapCallBack(callback, target)
	if not callback then
		return
	end

	if self.curActionTimeOut then
		egret:clearTimeout(self.curActionTimeOut)
	end

	egret:setTimeout(function ()
		callback(_G)

		self.curActionTimeOut = nil
	end, self, self.waitTime)
end

function DarkGuard:isDead()
	if self.activityData.detail.hp == self.BOSS_MAX_HP then
		return true
	end

	return false
end

function DarkGuard:playDead()
	self.curActionTimeOut = egret:setTimeout(function ()
		self.effectList[self.effectNameList[2]]:play("hurt", 1, function ()
			self.curActionTimeOut = egret:setTimeout(function ()
				self.effectList[self.effectNameList[2]]:play("dead", 1, function ()
					App.WindowManager:openWindow("alert_award_window", {
						items = self.items,
						callback = function ()
							self.fightBtn.touchEnabled = true

							self:updateHpProgress()
							self:playWait()

							self.shadow_.x = self.shadow_default_x
							self.shadow_.y = self.shadow_default_y
						end
					}, function ()
						local act_win = xyd.WindowManager:get():getWindow("activity_window")

						if act_win then
							local windowTop = act_win:getWindowTop()

							windowTop:setCanRefresh(true)
							windowTop:refresResItems()
							windowTop:setCanRefresh(false)
						end
					end)
				end, true, 1)

				local action = TimelineLite.new()

				egret:setTimeout(function ()
					action:to(self.shadow_, 0.12, {
						x = -700
					})
				end, self, self.waitTime + 1670)
			end, self, self.waitTime)
		end, true)
		self:updateHpProgress(100)
	end, self, self.waitTime)

	egret:setTimeout(function ()
		self:playDamage()
	end, self, 530)
end

function DarkGuard:playDamage()
	local view = PngNum.new()

	self.damageGroup:addChild(view)

	local action = TimelineLite.new()
	local iconName = "battle_heath"

	view:setInfo({
		isShowAdd = true,
		iconName = iconName,
		num = self.ITEM_ATTACK
	})

	view.scale = 0.7
	view.anchorOffsetX = view.width / 2
	view.anchorOffsetY = view.height / 2
	view.alpha = 1

	action:to(view, 0.2, {
		scaleY = view.scaleY * 2,
		scaleX = view.scaleX * 2
	}):to(view, 0.2, {
		scaleY = view.scaleY * 0.8,
		scaleX = view.scaleX * 0.8
	}):to(view, 0.15, {
		scaleY = view.scaleY * 1.6,
		scaleX = view.scaleX * 1.6
	}):to(view, 0.15, {
		scaleY = view.scaleY * 1,
		scaleX = view.scaleX * 1
	}):to(view, 0.5, {
		alpha = 0,
		delay = 0.2
	}):call(function ()
		self.damageGroup:removeChild(view)
	end)
end

function DarkGuard:playBubbleText(type)
	self.effectList[self.effectNameList[2]].touchEnabled = false
	self.bubbleTextLabel.text = ActivityBossDialogueTextTable:get():getDialogue(xyd.ActivityID.DARK_GUARD, type)
	self.bubbleTextGroup.visible = true
	local action = TimelineLite.new()

	action:to(self.bubbleTextGroup, 0.3, {
		scaleY = 1.1,
		scaleX = 1.1
	}):to(self.bubbleTextGroup, 0.16, {
		scaleY = 1,
		scaleX = 1
	}):to(self.bubbleTextGroup, 0.56, {
		scaleY = 1,
		scaleX = 1
	}):to(self.bubbleTextGroup, 0.5, {
		scaleY = 0.01,
		scaleX = 0.01
	}):call(function ()
		self.effectList[self.effectNameList[2]].touchEnabled = true
	end)
end

function DarkGuard:updateHpProgress(value)
	if value == nil then
		value = nil
	end

	if value ~= nil then
		self.hpProgress.value = value
	else
		self.hpProgress.value = 100 - math.floor(self.activityData.detail.hp * 100 / self.BOSS_MAX_HP)
	end
end

function DarkGuard:updateBtnLabel(isInit)
	if isInit == nil then
		isInit = false
	end

	self.fightBtn.labelDisplay.text = isInit and function ()
		return String(_G, self.costItemNum_)
	end or function ()
		return String(_G, function ()
			local ____TS_tmp = self.costItemNum_ - 1
			self.costItemNum_ = ____TS_tmp

			return ____TS_tmp
		end())
	end()
end

function DarkGuard:onRemove()
	ActivityContent.onRemove(self)

	if self.curTimeoutId then
		egret:clearTimeout(self.curTimeoutId)
	end

	if self.curActionTimeOut then
		egret:clearTimeout(self.curActionTimeOut)
	end

	if self.iconAction then
		self.iconAction:stop()
		self.iconAction:clear()

		self.iconAction = nil
	end

	self:delayAwardEnable(false)
end

function DarkGuard:delayAwardEnable(active)
	if active == nil then
		active = false
	end

	local act_win = xyd.WindowManager:get():getWindow("activity_window")

	if act_win then
		local windowTop = act_win:getWindowTop()

		windowTop:setCanRefresh(not active)

		if not active then
			windowTop:refresResItems()
		end
	end
end

return DarkGuard
