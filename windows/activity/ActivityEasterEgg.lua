local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ActivityEasterEgg = class("ActivityEasterEgg", ActivityContent)

function ActivityEasterEgg:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.point = self.activityData.detail.point
	self.usedItem = 0
	self.isFirst = xyd.checkCondition(tonumber(xyd.db.misc:getValue("esater_egg_first_touch")), false, true)

	self:getUIComponent()
	self:initUIComponet()
	self:registEvent()
end

function ActivityEasterEgg:getPrefabPath()
	return "Prefabs/Windows/activity/activity_easter_egg"
end

function ActivityEasterEgg:getUIComponent()
	local go = self.go
	self.mainGroup = go:NodeByName("main").gameObject
	self.helpBtn = self.mainGroup:NodeByName("helpBtn").gameObject
	self.textImg = self.mainGroup:ComponentByName("textImg", typeof(UITexture))
	self.timeLabel = self.mainGroup:ComponentByName("timerGroup/timeLabel", typeof(UILabel))
	self.endLabel = self.mainGroup:ComponentByName("timerGroup/endLabel", typeof(UILabel))
	self.itemNum = self.mainGroup:ComponentByName("itemGroup/label", typeof(UILabel))
	self.itemGetBtn = self.mainGroup:NodeByName("itemGroup/btn").gameObject
	self.effectNode = self.mainGroup:NodeByName("effectNode").gameObject
	self.buttomGroup = self.mainGroup:NodeByName("buttomGroup").gameObject
	self.progressBar_ = self.buttomGroup:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressDesc = self.progressBar_:ComponentByName("progressLabel", typeof(UILabel))
	self.iconGroup = self.buttomGroup:NodeByName("iconGroup").gameObject
	self.buttomLabel = self.buttomGroup:ComponentByName("label", typeof(UILabel))
	self.useBtn = self.buttomGroup:NodeByName("btn1").gameObject
	self.btnLabel = self.useBtn:ComponentByName("label", typeof(UILabel))
	self.awardBtn = self.buttomGroup:NodeByName("btn2").gameObject
	self.redMark = self.awardBtn:ComponentByName("redMark", typeof(UISprite))
	self.bubble = self.mainGroup:NodeByName("bubble").gameObject
	self.bubbleLabel = self.bubble:ComponentByName("bubbleLabel", typeof(UILabel))

	self.bubble:SetActive(false)
end

function ActivityEasterEgg:initUIComponet()
	self:layout()
	self:refresh()
end

function ActivityEasterEgg:layout()
	xyd.setUITextureByNameAsync(self.textImg, "activity_easter_egg_logo_" .. xyd.Global.lang, true)

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	if xyd.Global.lang == "de_de" then
		self.timeLabel:X(-70)
		self.endLabel:X(-10)

		self.endLabel.width = 120
		self.bubbleLabel.width = 250
	end

	self.buttomLabel.text = __("BALLOON_INTIMACY")
	self.endLabel.text = __("END")
	self.btnLabel.text = __("ACTIVITY_EASTER_EGG_OPEN_EGG")

	self.redMark:SetActive(self.isFirst)
end

function ActivityEasterEgg:refresh()
	local nextId = self:getNextId(self.point)
	local nextPoint = xyd.tables.activityEasterEggPointTable:getPoint(nextId)
	local awards = xyd.tables.activityEasterEggPointTable:getAwards(nextId)
	self.progressBar_.value = math.min(self.point, nextPoint) / nextPoint
	self.progressDesc.text = math.min(self.point, nextPoint) .. "/" .. nextPoint
	self.itemNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.PINK_BALLOON)

	NGUITools.DestroyChildren(self.iconGroup.transform)

	local icon = xyd.getItemIcon({
		show_has_num = true,
		itemID = awards[1],
		num = awards[2],
		uiRoot = self.iconGroup,
		scale = Vector3(0.7, 0.7, 1)
	})
end

function ActivityEasterEgg:getNextId(point)
	local ids = xyd.tables.activityEasterEggPointTable:getIDs()
	local max = 0

	for id in ipairs(ids) do
		local nextPoint = xyd.tables.activityEasterEggPointTable:getPoint(id)

		if point < nextPoint then
			return id
		end

		if max < id then
			max = id
		end
	end

	return max
end

function ActivityEasterEgg:registEvent()
	UIEventListener.Get(self.awardBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_easter_egg_award_window", {
			point = self.point
		})

		if self.isFirst then
			xyd.db.misc:setValue({
				value = 1,
				key = "esater_egg_first_touch"
			})

			self.isFirst = false

			self.redMark:SetActive(self.isFirst)
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.EASTER_EGG, function ()
				self.activityData.isShowRedPoint = xyd.checkCondition(tonumber(xyd.db.misc:getValue("esater_egg_first_touch")), false, true) or xyd.models.backpack:getItemNumByID(xyd.ItemID.PINK_BALLOON) > 0
			end)
		end
	end)
	UIEventListener.Get(self.useBtn).onClick = handler(self, function ()
		if xyd.isItemAbsence(xyd.ItemID.PINK_BALLOON, 1, true) then
			xyd.WindowManager.get():openWindow("activity_item_getway_window", {
				itemID = xyd.ItemID.PINK_BALLOON,
				activityID = xyd.ActivityID.EASTER_EGG
			})
		else
			xyd.WindowManager.get():openWindow("activity_easter_egg_gacha_window", {
				parent = self
			})
		end
	end)
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_EASTER_EGG_HELP"
		})
	end)
	UIEventListener.Get(self.itemGetBtn).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.PINK_BALLOON,
			activityID = xyd.ActivityID.EASTER_EGG
		})
	end)

	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.EASTER_EGG, function ()
			self.activityData.isShowRedPoint = xyd.checkCondition(tonumber(xyd.db.misc:getValue("esater_egg_first_touch")), false, true) or xyd.models.backpack:getItemNumByID(xyd.ItemID.PINK_BALLOON) > 0
		end)
		self:refresh()
	end)
	self:registerEvent(xyd.event.OPEN_EASTER_EGG, function (event)
		local params = event.data
		self.activityData.detail.point = params.point
		self.point = params.point

		xyd.itemFloat(params.items, nil, , 6500)
		self:showBubble(params.items)
		self:refresh()
	end)
end

function ActivityEasterEgg:showBubble(items)
	local effect = xyd.Spine.new(self.effectNode)

	effect:setInfo("givepresent", function ()
		effect:play("texiao01", 1, 1, function ()
			effect:destroy()
		end)
	end)

	local type = 1

	if self.usedItem > 3 then
		type = 3
	else
		local bonus = xyd.tables.miscTable:split2Cost("activity_easter_egg_show_bonus", "value", "|#")

		for i = 1, #items do
			for j = 1, #bonus do
				if items[i].item_id == bonus[j][1] then
					type = 2
					self.bubbleLabel.text = __("BALLOON_GET_TEXT" .. type)

					self.bubble:SetActive(true)

					self.usedItem = 0

					return
				end
			end
		end
	end

	self.bubbleLabel.text = __("BALLOON_GET_TEXT" .. type)

	self.bubble:SetActive(true)

	self.usedItem = 0
end

return ActivityEasterEgg
