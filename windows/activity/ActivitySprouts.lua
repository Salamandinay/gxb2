local ActivityContent = import(".ActivityContent")
local ActivitySprouts = class("ActivitySprouts", ActivityContent)

function ActivitySprouts:ctor(parentGO, params)
	ActivitySprouts.super.ctor(self, parentGO, params)
	xyd.models.activity:reqActivityByID(xyd.ActivityID.SPROUTS)
end

function ActivitySprouts:getPrefabPath()
	return "Prefabs/Windows/activity/activity_sprouts"
end

function ActivitySprouts:initUI()
	ActivitySprouts.super.initUI(self)
	self:getUIComponent()
	self:initUIComponent()
	self:cloudAnimation()
	self:checkFirst()
end

function ActivitySprouts:getUIComponent()
	local go = self.go
	self.imgTitle = go:ComponentByName("imgTitle", typeof(UISprite))
	self.bgGroup = go:NodeByName("bgGroup")
	self.skyGroup = self.bgGroup:NodeByName("skyGroup")
	self.cloudGroup = go:NodeByName("cloudGroup").gameObject
	self.groupBtn = go:NodeByName("groupBtn").gameObject
	self.helpBtn = self.groupBtn:NodeByName("helpBtn").gameObject
	self.storyBtn = self.groupBtn:NodeByName("storyBtn").gameObject
	self.awardBtn = self.groupBtn:NodeByName("awardBtn").gameObject
	self.iconGroup = go:NodeByName("iconGroup").gameObject
	self.iconLabel = self.iconGroup:ComponentByName("label", typeof(UILabel))
	self.iconBtn = self.iconGroup:NodeByName("btn").gameObject
	self.heightGroup = go:NodeByName("heightGroup").gameObject
	self.heightLabel = self.heightGroup:ComponentByName("label", typeof(UILabel))
	self.bottomGroup = go:NodeByName("bottomGroup").gameObject
	self.progress = self.bottomGroup:ComponentByName("progress", typeof(UISlider))
	self.progressLabel = self.bottomGroup:ComponentByName("progress/label", typeof(UILabel))
	self.tipBtn = self.bottomGroup:NodeByName("tipBtn").gameObject
	self.tipLabel = self.bottomGroup:ComponentByName("tipLabel", typeof(UILabel))
	self.awardIcon = self.bottomGroup:NodeByName("awardIcon").gameObject
	self.irrigateBtn1 = self.bottomGroup:NodeByName("irrigateBtn1").gameObject
	self.irrigateBtn1_label = self.irrigateBtn1:ComponentByName("button_label", typeof(UILabel))
	self.irrigateBtn10 = self.bottomGroup:NodeByName("irrigateBtn10").gameObject
	self.irrigateBtn10_label = self.irrigateBtn10:ComponentByName("button_label", typeof(UILabel))
	self.harvestBtn = self.bottomGroup:NodeByName("harvestBtn").gameObject
	self.harvestLabel = self.harvestBtn:ComponentByName("label", typeof(UILabel))
	self.harvestRed = self.harvestBtn:ComponentByName("redPoint", typeof(UISprite))
end

function ActivitySprouts:initUIComponent()
	xyd.setUISpriteAsync(self.imgTitle, nil, "activity_sprouts_text_" .. xyd.Global.lang, nil, , true)

	self.harvestLabel.text = __("ACTIVITY_SPROUTS_BTN_AWARD")
	self.irrigateBtn1_label.text = "X1"
	self.irrigateBtn10_label.text = "X10"
	self.awardInfo = xyd.tables.miscTable:split2Cost("activity_sprouts_point_award", "value", "|#")

	xyd.getItemIcon({
		show_has_num = false,
		scale = 0.7,
		uiRoot = self.awardIcon,
		itemID = tonumber(self.awardInfo[2][1]),
		num = tonumber(self.awardInfo[2][2])
	})

	if xyd.Global.lang == "fr_fr" then
		self.tipLabel:Y(0)
	end
end

function ActivitySprouts:cloudAnimation()
	local pos = {
		{
			time2 = 100,
			x = 600,
			time1 = 43
		},
		{
			time2 = 114.54545454545455,
			x = 630,
			time1 = 72
		},
		{
			time2 = 121.66666666666667,
			x = 730,
			time1 = 44
		}
	}

	for i = 1, 3 do
		local cloudTrans = self.cloudGroup:NodeByName("cloud" .. i)
		local seq = self:getSequence()

		seq:Append(cloudTrans:DOLocalMoveX(pos[i].x, pos[i].time1):SetEase(DG.Tweening.Ease.Linear)):AppendCallback(function ()
			cloudTrans:X(-600)

			local seqLoop = self:getSequence()

			seqLoop:Append(cloudTrans:DOLocalMoveX(-pos[i].x, pos[i].time2):SetEase(DG.Tweening.Ease.Linear)):SetLoops(-1)
		end)
	end
end

function ActivitySprouts:checkFirst()
	self.MAX_HEIGHT = tonumber(xyd.tables.miscTable:getVal("activity_sprouts_limit"))

	self.bgGroup:SetLocalPosition(0, -1054, 0)
	self.skyGroup:SetLocalPosition(0, -10 * math.min(xyd.models.backpack:getItemNumByID(xyd.ItemID.SPROUTS_POINT), self.MAX_HEIGHT), 0)

	local value = tonumber(xyd.db.misc:getValue("activity_sprouts_first"))

	if not value then
		self.bgGroup:SetLocalPosition(0, 0, 0)
		self.iconGroup:SetActive(false)
		self.heightGroup:SetActive(false)
		self.bottomGroup:SetActive(false)
		self.groupBtn:SetActive(false)
		self.imgTitle:SetActive(false)
		xyd.db.misc:setValue({
			value = 1,
			key = "activity_sprouts_first"
		})
		self:showStory(function ()
			self:waitForTime(1, function ()
				local sequence = self:getSequence()

				sequence:Append(self.bgGroup:DOLocalMoveY(self.bgGroup.localPosition.y - 1054, 2))
				sequence:AppendCallback(function ()
					sequence:Kill(false)

					sequence = nil

					self.iconGroup:SetActive(true)
					self.heightGroup:SetActive(true)
					self.bottomGroup:SetActive(true)
					self.groupBtn:SetActive(true)
					self.imgTitle:SetActive(true)
				end)
			end, xyd.getTimeKey())
		end)
	end
end

function ActivitySprouts:onRegister()
	ActivitySprouts.super.onRegister(self)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.update))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.ACTIVITY_SPROUTS_SELECT_AWARD, handler(self, self.updateRedMark1))
	self:registerEvent(xyd.event.ACTIVITY_SPROUTS_PERSON_AWARD, handler(self, self.updateRedMark2))

	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_SPROUTTS_HELP"
		})
	end)
	UIEventListener.Get(self.storyBtn).onClick = handler(self, function ()
		xyd.alertYesNo(__("ACTIVITY_SPROUTS_STORY_TIP"), function (yes)
			if yes then
				self:showStory()
			end
		end)
	end)
	UIEventListener.Get(self.awardBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("sprouts_item_award_window")
	end)
	UIEventListener.Get(self.tipBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_SPROUTS_NEW_HELP"
		})
	end)
	UIEventListener.Get(self.iconBtn).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			activityData = self.activityData.detail_,
			itemID = xyd.ItemID.SPROUTS_ITEM,
			activityID = xyd.ActivityID.SPROUTS
		})
	end)
	UIEventListener.Get(self.irrigateBtn1).onClick = handler(self, function ()
		self:onIrrigate(1)
	end)
	UIEventListener.Get(self.irrigateBtn10).onClick = handler(self, function ()
		self:onIrrigate(10)
	end)
	UIEventListener.Get(self.harvestBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("sprouts_point_award_window")
	end)
end

function ActivitySprouts:update(event)
	if event then
		self.activityData:setData(event.data.act_info)
	end

	local height = self.activityData.detail_.height or 0
	local times = self.activityData.detail_.times or 0
	local score = self.activityData.detail_.score or 0
	local limit = xyd.tables.miscTable:split2Cost("activity_sprouts_10_award", "value", "|#")[1][1]
	local progress_limit = tonumber(self.awardInfo[1][1])
	self.heightLabel.text = height .. "m"
	self.iconLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.SPROUTS_ITEM)
	self.tipLabel.text = __("ACTIVITY_SPROUTS_NEW_TEXT01", limit - times % limit)
	self.progress.value = score % progress_limit / progress_limit
	self.progressLabel.text = score % progress_limit .. "/" .. progress_limit

	self:updateRedMark()
end

function ActivitySprouts:onIrrigate(val)
	if val <= xyd.models.backpack:getItemNumByID(xyd.ItemID.SPROUTS_ITEM) then
		local params = require("cjson").encode({
			num = val
		})

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.SPROUTS, params)
	else
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.SPROUTS_ITEM)))
	end
end

function ActivitySprouts:onAward(event)
	local data = require("cjson").decode(event.data.detail)
	local bigAwardID = tonumber(self.awardInfo[2][1])
	local bigAward = {}
	local items = {}
	local height = 0

	for i = 1, #data.items do
		if data.items[i].item_id == xyd.ItemID.SPROUTS_POINT then
			height = height + data.items[i].item_num
		else
			local item = {
				item_id = data.items[i].item_id,
				item_num = data.items[i].item_num
			}

			if data.items[i].item_id ~= bigAwardID then
				table.insert(items, item)
			else
				table.insert(bigAward, item)
			end
		end
	end

	if #items > 0 then
		local num = 1

		if #items > 2 then
			num = 10
		end

		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			wnd_type = 4,
			data = items,
			cost = {
				171,
				num
			},
			buyCallback = function (cost)
				local num = cost[2]
				local hasNum = xyd.models.backpack:getItemNumByID(cost[1])

				if num <= hasNum then
					local params = require("cjson").encode({
						num = num
					})

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.SPROUTS, params)
				else
					xyd.alertTips(__("SHELTER_NOT_ENOUGH_MATERIAL"))

					return false
				end
			end
		})
	end

	if #bigAward > 0 then
		xyd.models.itemFloatModel:pushNewItems(bigAward)
	end

	xyd.alertTips(__("ACTIVITY_SPROUTTS_GROW", height), nil, , , , , 300)
	self:growAnimation()
	self:update()
end

function ActivitySprouts:growAnimation()
	local height = math.min(xyd.models.backpack:getItemNumByID(xyd.ItemID.SPROUTS_POINT), self.MAX_HEIGHT)
	local sq = self:getSequence()

	sq:Append(self.skyGroup:DOLocalMoveY(height * -10, 1))
	sq:AppendCallback(function ()
		sq:Kill(false)

		sq = nil
	end)
end

function ActivitySprouts:showStory(callback)
	xyd.WindowManager.get():openWindow("story_window", {
		is_back = true,
		story_type = xyd.StoryType.ACTIVITY,
		story_id = xyd.tables.activityTable:getPlotId(xyd.ActivityID.SPROUTS),
		callback = callback
	})
end

function ActivitySprouts:updateRedMark()
	self.harvestRed:SetActive(self.activityData:getRedMarkState2() or self.activityData:getRedMarkState3())
	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SPROUTS, self.activityData:getRedMarkState())
end

function ActivitySprouts:updateRedMark1(event)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.SPROUTS, function ()
		local table_id = event.data.table_id
		self.activityData.detail_.awards[table_id] = 1
	end)
	self:updateRedMark()
end

function ActivitySprouts:updateRedMark2(event)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.SPROUTS, function ()
		local table_id = event.data.table_id
		self.activityData.detail_.pr_awards[table_id] = 1
	end)
	self:updateRedMark()
end

return ActivitySprouts
