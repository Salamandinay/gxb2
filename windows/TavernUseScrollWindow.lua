local TavernUseScrollWindow = class("TavernUseScrollWindow", import(".BaseWindow"))

function TavernUseScrollWindow:ctor(name, params)
	TavernUseScrollWindow.super.ctor(self, name, params)
end

function TavernUseScrollWindow:initWindow()
	self.onceUseMax = 100
	self.newMissions = {}

	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function TavernUseScrollWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	local list = {
		"normal",
		"senior"
	}

	for _, str in ipairs(list) do
		local item = groupAction:NodeByName(str).gameObject
		self[str .. "SelectNumNode"] = item:NodeByName("selectNum").gameObject
		self[str .. "ItemIcon"] = item:NodeByName("itemIcon").gameObject
	end

	self.BtnUse = groupAction:NodeByName("btnUse").gameObject
	self.BtnUseLabel = self.BtnUse:ComponentByName("labelUse", typeof(UILabel))
	self.loadingComponent = groupAction:NodeByName("loadingComponent").gameObject
	self.loadingEffect = self.loadingComponent:NodeByName("loadingEffect").gameObject
	self.loadingText = self.loadingComponent:ComponentByName("loadingText", typeof(UILabel))
end

function TavernUseScrollWindow:layout()
	self.labelTitle.text = __("PUB_MISSION_AUTO_TEXT03")
	self.BtnUseLabel.text = __("USE")

	if xyd.Global.lang == "fr_fr" then
		self.labelTitle.fontSize = 22
	end

	local normal = xyd.tables.pubScrollTable:getCost(1)
	local senior = xyd.tables.pubScrollTable:getCost(2)
	local list = {
		normal = normal,
		senior = senior
	}

	for str, data in pairs(list) do
		local num = xyd.models.backpack:getItemNumByID(tonumber(data[1]))

		xyd.getItemIcon({
			uiRoot = self[str .. "ItemIcon"],
			itemID = data[1],
			num = num
		})

		self[str .. "UsedTotal"] = 0
		self[str .. "CurNum"] = num > 0 and 1 or 0
		self[str .. "SelectNum"] = require("app.components.SelectNum").new(self[str .. "SelectNumNode"], "tavern")

		self[str .. "SelectNum"]:setInfo({
			delForceZero = true,
			minNum = 0,
			maxNum = num,
			curNum = self[str .. "CurNum"],
			callback = function (num)
				self[str .. "CurNum"] = num
			end
		})

		UIEventListener.Get(self.BtnUse).onClick = function ()
			local ticketEnoughFlag = false

			for str, data in pairs(list) do
				if self[str .. "CurNum"] > 0 then
					ticketEnoughFlag = true

					if self.onceUseMax <= self[str .. "CurNum"] then
						self.loadingText.text = __("PUB_MISSION_AUTO_TEXT04", xyd.tables.itemTextTable:getName(data[1]))
						local effect = xyd.Spine.new(self.loadingEffect)

						effect:setInfo("loading", function ()
							effect:SetLocalScale(0.95, 0.95, 0.95)
							effect:play("idle", 0, 1)
						end)

						self.effect = effect

						self.loadingComponent:SetActive(true)
					end

					local curUsed = math.min(self.onceUseMax, self[str .. "CurNum"] - self[str .. "UsedTotal"])
					self[str .. "UsedTotal"] = self[str .. "UsedTotal"] + curUsed
					self.time = 0
					self.timeKey = xyd.models.selfPlayer:addGlobalTimer(function ()
						self.time = self.time + 0.1
					end, 0.1)

					xyd.models.tavern:useScroll(str == "normal" and 1 or 2, curUsed)

					break
				end
			end

			if ticketEnoughFlag == false then
				xyd.alert(xyd.AlertType.TIPS, __("PUB_MISSION_AUTO_TEXT001"))
			end
		end
	end

	self.normalSelectNum:setKeyboardPos(0, -207)
	self.seniorSelectNum:setKeyboardPos(0, -207)
end

function TavernUseScrollWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	self.eventProxy_:addEventListener(xyd.event.PUB_USE_SCROLL, handler(self, self.useCallback))
end

function TavernUseScrollWindow:useCallback(event)
	local missionInfos = event.data.mission_infos

	for _, missionInfo in ipairs(missionInfos) do
		local missionID = missionInfo.mission_id

		table.insert(self.newMissions, missionID)
	end

	self.isComplete = true
	self.usedTotal = 0
	local normal = xyd.tables.pubScrollTable:getCost(1)
	local senior = xyd.tables.pubScrollTable:getCost(2)
	local list = {
		normal = normal,
		senior = senior
	}

	for str, data in pairs(list) do
		self.usedTotal = self.usedTotal + self[str .. "UsedTotal"]

		if self[str .. "UsedTotal"] < self[str .. "CurNum"] then
			local curUsed = math.min(self.onceUseMax, self[str .. "CurNum"] - self[str .. "UsedTotal"])
			self[str .. "UsedTotal"] = self[str .. "UsedTotal"] + curUsed

			xyd.models.tavern:useScroll(str == "normal" and 1 or 2, curUsed)

			self.isComplete = false
		end
	end

	if self.isComplete then
		xyd.models.selfPlayer:removeGlobalTimer(self.timeKey)

		if self.usedTotal >= 100 then
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

function TavernUseScrollWindow:hideEffect(callback)
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

function TavernUseScrollWindow:excuteCallBack(isCloseAll)
	if not isCloseAll and self.params_ and self.params_.closeCallBack then
		self.params_.closeCallBack(self.newMissions)
	end
end

return TavernUseScrollWindow
