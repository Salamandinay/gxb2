local BaseWindow = import(".BaseWindow")
local ActivityRecallLotteryAwakeWindow = class("ActivityRecallLotteryAwakeWindow", BaseWindow)
local cjson = require("cjson")

function ActivityRecallLotteryAwakeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RECALL_LOTTERY)
end

function ActivityRecallLotteryAwakeWindow:initWindow()
	self:getUIComponent()
	ActivityRecallLotteryAwakeWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityRecallLotteryAwakeWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.resItem = groupAction:ComponentByName("resItem", typeof(UISprite))
	self.resNum = self.resItem:ComponentByName("num", typeof(UILabel))
	self.resPlus = self.resItem:NodeByName("btnPlus").gameObject
	self.btnAwake = groupAction:NodeByName("btnAwake").gameObject
	self.labelAwake = self.btnAwake:ComponentByName("labelAwake", typeof(UILabel))
	local groupContent = groupAction:NodeByName("groupContent").gameObject
	self.progressLabel = groupContent:ComponentByName("progressLabel", typeof(UILabel))
	self.progressNum = groupContent:ComponentByName("progressNum", typeof(UILabel))
	self.progressBar = groupContent:ComponentByName("progressBar", typeof(UIProgressBar))

	for i = 1, 3 do
		self["award" .. i] = groupContent:ComponentByName("award" .. i, typeof(UISprite))
		self["labelPoint" .. i] = self["award" .. i]:ComponentByName("labelPoint", typeof(UILabel))
		self["imgMask" .. i] = self["award" .. i]:NodeByName("imgMask").gameObject
		self["imgChoose" .. i] = self["award" .. i]:NodeByName("imgChoose").gameObject
	end

	local modelGroup = groupAction:NodeByName("model").gameObject
	self.platformBg = modelGroup:NodeByName("platformBg_").gameObject

	for i = 1, 3 do
		self["modelNode" .. i] = modelGroup:NodeByName("scroller_/model_" .. i).gameObject
	end

	self.leftArrow = modelGroup:NodeByName("leftArrow").gameObject
	self.rightArrow = modelGroup:NodeByName("rightArrow").gameObject
end

function ActivityRecallLotteryAwakeWindow:initUIComponent()
	self.labelAwake.text = __("ACTIVITY_VAMPIRE_GAMBLE_BUTTON05")
	self.progressLabel.text = __("ACTIVITY_VAMPIRE_GAMBLE_TEXT03")
	self.progressNum.text = math.min(100, self.activityData.detail.point) .. "/100"
	self.progressBar.value = math.min(100, self.activityData.detail.point) / 100
	self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.RECALL_FEATHER)

	for i = 1, 3 do
		self["labelPoint" .. i].text = xyd.tables.activityVampireGrowTable:getPoint(i)
	end

	local windowBG = self.window_.transform:NodeByName("WINDOWBG"):GetComponent(typeof(UISprite))
	windowBG.color = Color.New2(204)

	for i = 1, 3 do
		self["award" .. i]:NodeByName("imgIcon").gameObject:SetActive(false)
		self["award" .. i]:ComponentByName("labelNum", typeof(UILabel)):SetActive(true)

		self["award" .. i]:ComponentByName("labelNum", typeof(UILabel)).text = "x" .. xyd.tables.activityVampireGrowTable:getAward(i)[1][2]
		self["award" .. i .. "Icon"] = xyd.getItemIcon({
			noClick = true,
			scale = 0.5185185185185185,
			uiRoot = self["award" .. i].gameObject,
			itemID = xyd.tables.activityVampireGrowTable:getAward(i)[1][1]
		})
	end

	self:updateAwards()
	self:initModel()
end

function ActivityRecallLotteryAwakeWindow:updateAwards()
	if not self.awardEffect then
		self.awardEffect = {}
	end

	for i = 1, 3 do
		if self.activityData.detail.gets[i] ~= 0 then
			self["imgMask" .. i]:SetActive(true)
			self["imgChoose" .. i]:SetActive(true)

			if i == 3 then
				self.award3Icon:setEffect(false)
			elseif self.awardEffect[i] then
				self.awardEffect[i]:SetActive(false)
			end
		else
			self["imgMask" .. i]:SetActive(false)
			self["imgChoose" .. i]:SetActive(false)

			if xyd.tables.activityVampireGrowTable:getPoint(i) <= self.activityData.detail.point then
				if i == 3 then
					self.award3Icon:setEffect(true, "fx_ui_bp_available", {})
				elseif not self.awardEffect[i] then
					self.awardEffect[i] = xyd.Spine.new(self["award" .. i].gameObject)

					self.awardEffect[i]:setInfo("fx_ui_bp_available", function ()
						self.awardEffect[i]:play("texiao01", 0)
						self.awardEffect[i]:SetLocalScale(0.55, 0.55, 1)
						self.awardEffect[i]:SetLocalPosition(0, 6, 0)
						self.awardEffect[i]:setRenderTarget(self["award" .. i], 1)
					end)
				else
					self.awardEffect[i]:SetActive(true)
				end
			end
		end
	end
end

function ActivityRecallLotteryAwakeWindow:initModel()
	local partnerIDs = (xyd.tables.miscTable:split2Cost("recall_lottery_awake_partner", "value", "|#") or xyd.tables.miscTable:split2Cost("gacha_ensure_partner", "value", "|#"))[1]

	for i = 1, 3 do
		local modelID = xyd.tables.partnerTable:getModelID(partnerIDs[i])
		local modelName = xyd.tables.modelTable:getModelName(modelID)
		local scale = xyd.tables.modelTable:getScale(modelID)
		self["modelEffect" .. i] = xyd.Spine.new(self["modelNode" .. i])

		self["modelEffect" .. i]:setInfo(modelName, function ()
			self["modelEffect" .. i]:SetLocalScale(scale, scale, 1)
			self["modelEffect" .. i]:play("idle", 0, 1)

			if i ~= 1 then
				self["modelNode" .. i]:SetActive(false)
			end
		end)
	end

	self.curModel = 1
	self.curAction = "attack"

	UIEventListener.Get(self.leftArrow).onClick = function ()
		if self.isMoving then
			return
		end

		self.isMoving = true
		self.onEffect = false
		local nextModel = self.curModel - 1

		if nextModel <= 0 then
			nextModel = 3
		end

		self["modelEffect" .. self.curModel]:stop()
		self["modelNode" .. self.curModel]:SetActive(false)
		self["modelNode" .. nextModel]:SetActive(true)
		self["modelEffect" .. nextModel]:play("idle", 0, 1)
		self["modelEffect" .. nextModel]:startAtFrame(0)
		self:waitForTime(0.3, function ()
			self.curModel = nextModel
			self.curAction = "attack"
			self.isMoving = false
		end)
	end

	UIEventListener.Get(self.rightArrow).onClick = function ()
		if self.isMoving then
			return
		end

		self.isMoving = true
		self.onEffect = false
		local nextModel = self.curModel + 1

		if nextModel >= 4 then
			nextModel = 1
		end

		self["modelEffect" .. self.curModel]:stop()
		self["modelNode" .. self.curModel]:SetActive(false)
		self["modelNode" .. nextModel]:SetActive(true)
		self["modelEffect" .. nextModel]:play("idle", 0, 1)
		self["modelEffect" .. nextModel]:startAtFrame(0)
		self:waitForTime(0.3, function ()
			self.curModel = nextModel
			self.curAction = "attack"
			self.isMoving = false
		end)
	end

	UIEventListener.Get(self.platformBg).onClick = function ()
		if self.onEffect then
			return
		end

		self.onEffect = true

		if self.curAction == "attack" then
			self["modelEffect" .. self.curModel]:play("attack", 1, nil, function ()
				self.curAction = "skill"
				self.onEffect = false
			end)
		else
			self["modelEffect" .. self.curModel]:play("skill", 1, nil, function ()
				self.curAction = "attack"
				self.onEffect = false
			end)
		end
	end
end

function ActivityRecallLotteryAwakeWindow:register()
	ActivityRecallLotteryAwakeWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.RECALL_FEATHER)
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = xyd.decodeProtoBuf(event.data)

		if data.activity_id ~= xyd.ActivityID.ACTIVITY_RECALL_LOTTERY then
			return
		end

		self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RECALL_LOTTERY)
		local detail = cjson.decode(data.detail)

		if detail.type == 2 then
			self.progressNum.text = math.min(100, self.activityData.detail.point) .. "/100"
			self.progressBar.value = math.min(100, self.activityData.detail.point) / 100
		elseif detail.type == 3 then
			local awards = xyd.tables.activityVampireGrowTable:getAward(detail.id)
			local items = {}

			for i = 1, #awards do
				local award = awards[i]

				table.insert(items, {
					item_id = award[1],
					item_num = award[2]
				})
			end

			xyd.models.itemFloatModel:pushNewItems(items)
		end

		self:updateAwards()
	end)

	UIEventListener.Get(self.resPlus).onClick = function ()
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_VAMPIRE_TASK),
			select = xyd.ActivityID.ACTIVITY_VAMPIRE_TASK
		})
		self:close()
	end

	UIEventListener.Get(self.btnAwake).onClick = function ()
		if self.activityData.detail.point >= 100 then
			xyd.alertTips(__("ACTIVITY_VAMPIRE_GAMBLE_TEXT04"))

			return
		end

		local cost = xyd.tables.miscTable:split2Cost("activity_vampire_awake", "value", "|#")[1]

		if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_RECALL_LOTTERY, cjson.encode({
				type = 2,
				num = math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2])
			}))
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
		end
	end

	for i = 1, 3 do
		UIEventListener.Get(self["award" .. i].gameObject).onClick = function ()
			if self.activityData.detail.gets[i] ~= 0 then
				return
			elseif xyd.tables.activityVampireGrowTable:getPoint(i) <= self.activityData.detail.point then
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_RECALL_LOTTERY, cjson.encode({
					type = 3,
					id = i
				}))
			else
				xyd.WindowManager.get():openWindow("activity_award_preview_window", {
					awards = xyd.tables.activityVampireGrowTable:getAward(i)
				})
			end
		end
	end
end

return ActivityRecallLotteryAwakeWindow
