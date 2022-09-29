local ActivityRepairConsoleWindow = class("ActivityRepairConsoleWindow", import(".ActivityContent"))
local MissionItem = class("MissionItem", import("app.components.CopyComponent"))
local cjson = require("cjson")

function ActivityRepairConsoleWindow:ctor(parentGO, params)
	self.curNav_ = params.pageType or 1
	self.missionItems_ = {}
	self.itemIcon = {}

	ActivityRepairConsoleWindow.super.ctor(self, parentGO, params)
end

function ActivityRepairConsoleWindow:getPrefabPath()
	return "Prefabs/Windows/activity/activity_repair_console"
end

function ActivityRepairConsoleWindow:initUI()
	ActivityRepairConsoleWindow.super.initUI(self)
	self:getUIComponent()
	self:resize()
	self:updateAwards()
	self:updateCost()
	self:updateMap()
	self:setText()
	self:register()
end

function ActivityRepairConsoleWindow:setText()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_repair_console_logo_" .. xyd.Global.lang)

	self.textLabel1.text = __("ACTIVITY_REPAIR_CONSOLE_TEXT01")
	self.textLabel2.text = __("ACTIVITY_REPAIR_CONSOLE_TEXT02")
	self.awardLabel.text = __("ACTIVITY_REPAIR_CONSOLE_TEXT03")
	self.useBtnLabel.text = __("ACTIVITY_REPAIR_CONSOLE_TEXT04")
end

function ActivityRepairConsoleWindow:updateAwards()
	local round = tonumber(self.activityData.detail_.round)
	local total_rounds = tonumber(xyd.tables.miscTable:getVal("activity_repair_console_max_time", "value"))

	if total_rounds < round then
		round = total_rounds
	end

	local awards = xyd.tables.activityRepairConsoleAwardTable:getAwardsByRound(round)

	for i = 1, 11 do
		local award = awards[i]
		local scale = 66

		if i == 11 then
			scale = 74
		end

		if self.itemIcon[i] then
			self.itemIcon[i]:setInfo({
				show_has_num = true,
				itemID = award[1],
				num = award[2],
				scale = Vector3(scale / 108, scale / 108, 1)
			})
		else
			self.itemIcon[i] = xyd.getItemIcon({
				show_has_num = true,
				itemID = award[1],
				num = award[2],
				uiRoot = self["item" .. i],
				scale = Vector3(scale / 108, scale / 108, 1)
			}, xyd.ItemIconType.ADVANCE_ICON)
		end
	end
end

function ActivityRepairConsoleWindow:setButtons(flag)
	self.useBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = flag
	self.helpBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = flag
	self.addBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = flag
	self.awardBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = flag
	self.nextBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = flag

	for i = 1, 11 do
		self.itemIcon[i]:setNoClick(not flag)
	end
end

function ActivityRepairConsoleWindow:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		self.summonEffect_ = xyd.Spine.new(self.gemItem3.gameObject)

		self.summonEffect_:play("texiao01", 2, 1)

		if event.data.activity_id == xyd.ActivityID.ACTIVITY_REPAIR_CONSOLE then
			local detail = cjson.decode(event.data.detail)
			local type = detail.type
			local items = self.activityData.normalAwards
			local surprise = self.activityData.surpriseAwards

			if type == 0 then
				self:updateCost()
				self:setButtons(false)
				self:waitForTime(0.03333333333333333, function ()
					for j = 1, 4 do
						self:waitForTime((j - 1) * 8 / 30, function ()
							for _, i in pairs(self.activityData.blueCards) do
								self:playCardEffect2(i, "texiao01", 1)
							end
						end)
					end
				end)
				self:waitForTime(0.03333333333333333, function ()
					for _, i in pairs(self.activityData.blueCards) do
						local delay = math.floor(math.random() * 8)

						self:waitForFrame(delay / 30, function ()
							self:playCardEffect(i, "texiao02", 1)
						end)
					end
				end)
				self:waitForTime(1.1666666666666667, function ()
					for _, i in pairs(self.activityData.blueCards) do
						self:playCardEffect(i, nil, 1)
					end

					for _, i in pairs(self.activityData.openCards) do
						self:playCardEffect(i, "texiao03", 1)
					end
				end)
				self:waitForTime(1.4666666666666666, function ()
					for _, i in pairs(self.activityData.openCards) do
						self:updateCard(i, true)
					end
				end)

				local lineTime = 0

				if #self.activityData.activateLines ~= 0 then
					lineTime = 30

					for _, i in pairs(self.activityData.activateLines) do
						self:waitForTime(1.5333333333333334, function ()
							if i >= 1 and i <= 5 then
								self:playLineEffect(i, "texiao01", 1)
								self:playAwardEffect(i, "texiao01", 1)
							end

							if i >= 6 and i <= 10 then
								self:playLineEffect(i, "texiao02", 1)
								self:playAwardEffect(i, "texiao02", 1)
							end

							if i == 11 then
								self:playLineEffect(i, "texiao03", 1)
								self:playAwardEffect(i, "texiao03", 1)
							end

							self:waitForTime(0.8333333333333334, function ()
								self:updateLine(i, true)
							end)
						end)
					end
				end

				self:waitForTime((50 + lineTime) / 30, function ()
					if #surprise ~= 0 then
						xyd.openWindow("gamble_rewards_window", {
							wnd_type = 2,
							isNeedCostBtn = false,
							data = surprise,
							callback = function ()
								xyd.itemFloat(items)

								if self.activityData.jumpToNextRound then
									self:updateAwards()
									self:updateMap()
								end

								if self.activityData.onOpenNextRound then
									xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_REPAIR_CONSOLE_TEXT09"), function (yes)
										if yes then
											local data = cjson.encode({
												type = 1
											})
											local msg = messages_pb.get_activity_award_req()
											msg.activity_id = xyd.ActivityID.ACTIVITY_REPAIR_CONSOLE
											msg.params = data

											xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

											return
										end
									end, __("ACTIVITY_REPAIR_CONSOLE_TEXT11"), false, {}, nil, , , , , , __("ACTIVITY_REPAIR_CONSOLE_TEXT10"))
								end
							end
						})
					else
						xyd.itemFloat(items)
					end

					self:updateMap()
					self:updateAwards()
					self:setButtons(true)
				end)
			else
				self:updateCost()
				self:updateMap()
				self:updateAwards()
			end
		end
	end)
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_REPAIR_CONSOLE_HELP"
		})
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_repair_console_award_window", {})
	end

	UIEventListener.Get(self.addBtn_).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.REPAIR_CONSOLE_ITEM,
			activityData = self.activityData
		})
	end

	UIEventListener.Get(self.useBtn_).onClick = function ()
		local cost = xyd.tables.miscTable:split2Cost("activity_repair_console_cost", "value", "#")

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		local data = cjson.encode({
			type = 0
		})
		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_REPAIR_CONSOLE
		msg.params = data

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
	end

	UIEventListener.Get(self.nextBtn_).onClick = function ()
		xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_REPAIR_CONSOLE_TEXT09"), function (yes)
			if yes then
				local data = cjson.encode({
					type = 1
				})
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.ACTIVITY_REPAIR_CONSOLE
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

				return
			end
		end, __("ACTIVITY_REPAIR_CONSOLE_TEXT11"), false, {}, nil, , , , , , __("ACTIVITY_REPAIR_CONSOLE_TEXT10"))
	end
end

function ActivityRepairConsoleWindow:getUIComponent()
	local goTrans = self.go.transform
	self.logoBg_ = goTrans:NodeByName("logo/logoBg").gameObject
	self.logoImg_ = goTrans:NodeByName("logo/logoImg").gameObject
	self.bg1_ = goTrans:NodeByName("bgGroup/bg1").gameObject
	self.textLabel1_ = goTrans:NodeByName("textLabel").gameObject
	self.textLabel2_ = goTrans:NodeByName("textLabel2").gameObject
	self.useBtnGroup_ = goTrans:NodeByName("useBtnGroup").gameObject
	self.resGroup_ = goTrans:NodeByName("resGroup").gameObject
	self.awardGroup_ = goTrans:NodeByName("awardGroup").gameObject
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.awardBtn_ = goTrans:NodeByName("awardGroup/awardsButton").gameObject
	self.addBtn_ = goTrans:NodeByName("resGroup/addBtn").gameObject
	self.useBtn_ = goTrans:NodeByName("useBtnGroup/useBtn").gameObject
	self.nextBtn_ = goTrans:NodeByName("contentGroup/nextBtn").gameObject
	self.logoImg = goTrans:ComponentByName("logo/logoImg", typeof(UISprite))
	self.textLabel1 = goTrans:ComponentByName("textLabel", typeof(UILabel))
	self.textLabel2 = goTrans:ComponentByName("textLabel2", typeof(UILabel))
	self.awardLabel = goTrans:ComponentByName("awardGroup/awardsButton/Label", typeof(UILabel))
	self.useBtnLabel = goTrans:ComponentByName("useBtnGroup/useBtn/useBtnLabel", typeof(UILabel))
	self.costLabel = goTrans:ComponentByName("resGroup/countLabel", typeof(UILabel))
	self.contentGroup = goTrans:NodeByName("contentGroup").gameObject
	self.gemGroup = self.contentGroup:NodeByName("gemGroup").gameObject

	for i = 1, 25 do
		self["gemItem" .. i] = self.gemGroup:ComponentByName("gemItem" .. i, typeof(UISprite))
		self["gemEffectRoot" .. i] = self.gemGroup:NodeByName("gemItem" .. i .. "/effectRoot").gameObject
		self["gemEffectRoot2_" .. i] = self.gemGroup:NodeByName("gemItem" .. i .. "/effectRoot2").gameObject
	end

	self.lineGroup = self.contentGroup:NodeByName("lineGroup").gameObject

	for i = 1, 11 do
		self["lineEffectRoot" .. i] = self.lineGroup:NodeByName("lineNode" .. i .. "/effectRoot").gameObject
	end

	self.awardGroup = self.contentGroup:NodeByName("awardGroup").gameObject

	for i = 1, 11 do
		self["awardItem" .. i] = self.awardGroup:NodeByName("awardItem" .. i).gameObject
		self["awardEffectRoot" .. i] = self["awardItem" .. i]:NodeByName("effectGroup").gameObject
		self["bgImg" .. i] = self["awardItem" .. i]:ComponentByName("bgImg", typeof(UISprite))
		self["item" .. i] = self["awardItem" .. i]:NodeByName("item").gameObject
	end
end

function ActivityRepairConsoleWindow:resize()
	self:resizePosY(self.logoBg_, 65, -15)
	self:resizePosY(self.logoImg_, -1, -56)
	self:resizePosY(self.textLabel1_, -112, -198)
	self:resizePosY(self.contentGroup, 0, -96)
	self:resizePosY(self.textLabel2_, -790, -900)
	self:resizePosY(self.useBtnGroup_, 0, -125)
	self:resizePosY(self.resGroup_, 2, -105)
	self:resizePosY(self.awardGroup_, -848, -975)
	self:resizePosY(self.bg1_, 82, 0)
end

function ActivityRepairConsoleWindow:playCardEffect(index, name, loop_time, callback)
	if not self.cardEffects_ then
		self.cardEffects_ = {}
	end

	if not self.cardEffects_[index] then
		self.cardEffects_[index] = xyd.Spine.new(self["gemEffectRoot" .. index])

		self.cardEffects_[index]:setInfo("fx_repair_console_active", function ()
			if name then
				self.cardEffects_[index]:play(name, loop_time)
			else
				self.cardEffects_[index]:stop()
			end
		end)
	elseif name then
		self.cardEffects_[index]:play(name, loop_time)
	else
		self.cardEffects_[index]:stop()
	end

	if callback then
		self:waitForTime(1, function ()
			callback()
		end)
	end
end

function ActivityRepairConsoleWindow:playCardEffect2(index, name, loop_time, callback)
	if not self.cardEffects2_ then
		self.cardEffects2_ = {}
	end

	if not self.cardEffects2_[index] then
		self.cardEffects2_[index] = xyd.Spine.new(self["gemEffectRoot2_" .. index])

		self.cardEffects2_[index]:setInfo("fx_repair_console_active", function ()
			if name then
				self.cardEffects2_[index]:play(name, loop_time)
			else
				self.cardEffects2_[index]:stop()
			end
		end)
	elseif name then
		self.cardEffects2_[index]:play(name, loop_time)
	else
		self.cardEffects2_[index]:stop()
	end

	if callback then
		self:waitForTime(1, function ()
			callback()
		end)
	end
end

function ActivityRepairConsoleWindow:playLineEffect(index, name, loop_time, callback)
	if not self.lineEffects_ then
		self.lineEffects_ = {}
	end

	if not self.lineEffects_[index] then
		self.lineEffects_[index] = xyd.Spine.new(self["lineEffectRoot" .. index])

		self.lineEffects_[index]:setInfo("fx_repair_console_success1", function ()
			self.lineEffects_[index]:play(name, loop_time, 1, function ()
				self.lineEffects_[index]:SetActive(false)
			end)
		end)
	else
		self.lineEffects_[index]:SetActive(true)
		self.lineEffects_[index]:play(name, loop_time, 1, function ()
			self.lineEffects_[index]:SetActive(false)
		end)
	end

	if callback then
		self:waitForTime(1, function ()
			callback()
		end)
	end
end

function ActivityRepairConsoleWindow:playAwardEffect(index, name, loop_time, callback)
	if not self.awardEffects_ then
		self.awardEffects_ = {}
	end

	if not self.awardEffects_[index] then
		self.awardEffects_[index] = xyd.Spine.new(self["lineEffectRoot" .. index])

		self.awardEffects_[index]:setInfo("fx_repair_console_success2", function ()
			self.awardEffects_[index]:play(name, loop_time, 1, function ()
				self.awardEffects_[index]:SetActive(false)
			end)
		end)
	else
		self.awardEffects_[index]:SetActive(true)
		self.awardEffects_[index]:play(name, loop_time, 1, function ()
			self.awardEffects_[index]:SetActive(false)
		end)
	end

	if callback then
		self:waitForTime(1, function ()
			callback()
		end)
	end
end

function ActivityRepairConsoleWindow:updateCost()
	local itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.REPAIR_CONSOLE_ITEM)
	self.costLabel.text = itemNum
end

function ActivityRepairConsoleWindow:checkLine(line)
	local targets = xyd.tables.activityRepairConsoleAwardTable:getTarget(line)

	for i = 1, 5 do
		local target = targets[i]

		if self.activityData.detail_.map_data[target] == 0 then
			return false
		end
	end

	return true
end

function ActivityRepairConsoleWindow:setLineActive(line, flag)
	self.lineGroup = self.contentGroup:NodeByName("lineGroup").gameObject
	local tmpLineNode = self.lineGroup:NodeByName("lineNode" .. line).gameObject

	for j = 1, 5 do
		local tmpLineItem = tmpLineNode:ComponentByName("lineItem" .. line .. "_" .. j, typeof(UISprite))

		if flag then
			if line <= 10 then
				xyd.setUISpriteAsync(tmpLineItem, nil, "activity_repair_console_wire_on")
			else
				xyd.setUISpriteAsync(tmpLineItem, nil, "activity_repair_console_diagonal_on")
			end
		elseif line <= 10 then
			xyd.setUISpriteAsync(tmpLineItem, nil, "activity_repair_console_wire_off")
		else
			xyd.setUISpriteAsync(tmpLineItem, nil, "activity_repair_console_diagonal_off")
		end
	end
end

function ActivityRepairConsoleWindow:updateCard(card, isJumpRound)
	if isJumpRound or self.mapData[card] == 1 then
		xyd.setUISpriteAsync(self["gemItem" .. card], nil, "activity_repair_console_gem_on")
	else
		xyd.setUISpriteAsync(self["gemItem" .. card], nil, "activity_repair_console_gem_off")
	end
end

function ActivityRepairConsoleWindow:updateLine(line, isJumpRound)
	if isJumpRound or self:checkLine(line) then
		if line == 11 then
			xyd.setUISpriteAsync(self["bgImg" .. line], nil, "activity_repair_console_bg_next_on")
			self["item" .. line]:SetActive(false)
			self.nextBtn_:SetActive(true)
		else
			self.itemIcon[line]:setChoose(true)
			xyd.setUISpriteAsync(self["bgImg" .. line], nil, "activity_repair_console_award_on")
		end

		self:setLineActive(line, true)
	else
		if line == 11 then
			xyd.setUISpriteAsync(self["bgImg" .. line], nil, "activity_repair_console_bg_next_off")
			self["item" .. line]:SetActive(true)
			self.nextBtn_:SetActive(false)
		else
			self.itemIcon[line]:setChoose(false)
			xyd.setUISpriteAsync(self["bgImg" .. line], nil, "activity_repair_console_award_off")
		end

		self:setLineActive(line, false)
	end
end

function ActivityRepairConsoleWindow:updateMap()
	self.mapData = self.activityData.detail_.map_data
	local round = tonumber(self.activityData.detail_.round)

	for i = 1, 25 do
		self:updateCard(i, false)
	end

	for i = 1, 11 do
		self:updateLine(i, false)
	end
end

function ActivityRepairConsoleWindow:updateEffect()
end

function ActivityRepairConsoleWindow:onActivityByID()
	self:updateCost()
	self:updateMap()
end

return ActivityRepairConsoleWindow
