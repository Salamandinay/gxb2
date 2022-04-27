local ActivityUseItemWindow = class("ActivityUseItemWindow", import(".BaseWindow"))

function ActivityUseItemWindow:ctor(name, params)
	self.titleText = params.titleText
	self.tipsText = params.tipsText
	self.useText = params.useText
	self.useTips = params.useTips
	self.onceUseMax = params.onceUseMax or 100
	self.curUsed = 0
	self.usedTotal = 0
	self.itemList = params.itemList
	self.useFunction = params.useFunction
	self.eventID = params.eventID
	self.languageList = params.languageList or {}

	ActivityUseItemWindow.super.ctor(self, name, params)
end

function ActivityUseItemWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:languageChange()
	self:registerEvent()
end

function ActivityUseItemWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction/groupMain").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.groupTips = groupAction:ComponentByName("groupTips", typeof(UILayout))
	self.labelTips = self.groupTips:ComponentByName("labelTips", typeof(UILabel))
	self.tipsImg = self.groupTips:ComponentByName("tipsImg", typeof(UISprite))

	for i = 1, 2 do
		local item = groupAction:NodeByName("itemGroup" .. i).gameObject
		self["SelectNumNode_" .. i] = item:NodeByName("selectNum").gameObject
		self["ItemIcon_" .. i] = item:NodeByName("itemIcon").gameObject
		self["BtnUse_" .. i] = item:NodeByName("btnUse").gameObject
		self["BtnUseLabel_" .. i] = self["BtnUse_" .. i]:ComponentByName("labelUse", typeof(UILabel))
	end

	self.loadingComponent = groupAction:NodeByName("loadingComponent").gameObject
	self.loadingEffect = self.loadingComponent:NodeByName("loadingEffect").gameObject
	self.loadingText = self.loadingComponent:ComponentByName("loadingText", typeof(UILabel))
end

function ActivityUseItemWindow:layout()
	self.labelTitle.text = self.titleText
	self.labelTips.text = self.tipsText

	xyd.setUISpriteAsync(self.tipsImg, nil, tostring(xyd.tables.itemTable:getIcon(self.itemList[1][1])) .. "_small")

	for i = 1, 2 do
		self["BtnUseLabel_" .. i].text = self.useText
		local num = xyd.models.backpack:getItemNumByID(tonumber(self.itemList[i][1]))

		xyd.getItemIcon({
			uiRoot = self["ItemIcon_" .. i],
			itemID = self.itemList[i][1],
			num = num
		})

		self["CurNum_" .. i] = num > 0 and 1 or 0
		self["SelectNum_" .. i] = require("app.components.SelectNum").new(self["SelectNumNode_" .. i], "tavern")

		self["SelectNum_" .. i]:setInfo({
			minNum = 0,
			maxNum = num,
			curNum = self["CurNum_" .. i],
			callback = function (num)
				self["CurNum_" .. i] = num
			end
		})

		UIEventListener.Get(self["BtnUse_" .. i]).onClick = function ()
			if self["CurNum_" .. i] > 0 then
				self.curUsedItemIndex = i

				if self.onceUseMax <= self["CurNum_" .. i] then
					self.loadingText.text = __("PUB_MISSION_AUTO_TEXT04", xyd.tables.itemTextTable:getName(self.itemList[i][1]))
					local effect = xyd.Spine.new(self.loadingEffect)

					effect:setInfo("loading", function ()
						effect:SetLocalScale(0.95, 0.95, 0.95)
						effect:play("idle", 0, 1)
					end)

					self.effect = effect

					self.loadingComponent:SetActive(true)
				end

				self.curUsed = math.min(self.onceUseMax, self["CurNum_" .. i] - self.usedTotal)
				self.usedTotal = self.usedTotal + self.curUsed
				self.time = 0
				self.timeKey = xyd.models.selfPlayer:addGlobalTimer(function ()
					self.time = self.time + 0.1
				end, 0.1)

				self.useFunction(self.itemList[i][1], self.curUsed)

				if self.useTips then
					xyd.showToast(self.useTips)
				end
			else
				local params = {
					alertType = xyd.AlertType.TIPS,
					message = __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.itemList[i][1]))
				}

				xyd.WindowManager.get():openWindow("alert_window", params)
			end
		end

		self["SelectNum_" .. i]:setKeyboardPos(0, -207)
	end
end

function ActivityUseItemWindow:languageChange()
	for lan, change in pairs(self.languageList) do
		if xyd.Global.lang == lan then
			if change.fontSize then
				self.labelTips.fontSize = change.fontSize
			end

			if change.width then
				self.labelTips.width = change.width
			end
		end
	end
end

function ActivityUseItemWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	self.eventProxy_:addEventListener(self.eventID, handler(self, self.useCallback))
end

function ActivityUseItemWindow:useCallback(event)
	if self.usedTotal < self["CurNum_" .. self.curUsedItemIndex] then
		self.curUsed = math.min(self.onceUseMax, self["CurNum_" .. self.curUsedItemIndex] - self.usedTotal)
		self.usedTotal = self.usedTotal + self.curUsed

		self.useFunction(self.itemList[self.curUsedItemIndex][1], self.curUsed)
	else
		xyd.models.selfPlayer:removeGlobalTimer(self.timeKey)

		if self.onceUseMax <= self.usedTotal then
			if self.time < 1 then
				self:waitForTime(1 - self.time, function ()
					self:hideEffect(function ()
						self:close()
					end)
				end)
			else
				self:hideEffect(function ()
					self:close()
				end)
			end
		else
			self:close()
		end
	end
end

function ActivityUseItemWindow:hideEffect(callback)
	if self.loadingComponent.activeSelf then
		local action = self:getSequence()

		local function setter(value)
			self.loadingComponent:GetComponent(typeof(UIWidget)).alpha = value

			if self.effect and self.effect.spAnim then
				self.effect.spAnim:setAlpha(value)
			end
		end

		action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 1))
		action:AppendCallback(callback)
	else
		callback()
	end
end

function ActivityUseItemWindow:excuteCallBack(isCloseAll)
	if not isCloseAll and self.params_ and self.params_.closeCallBack and self.usedTotal > 0 then
		self.params_.closeCallBack()
	end
end

return ActivityUseItemWindow
