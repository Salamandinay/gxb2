local ActivityContent = import(".ActivityContent")
local ActivityValentine = class("ActivityValentine", ActivityContent)

function ActivityValentine:ctor(parentGO, params, parent)
	ActivityValentine.super.ctor(self, parentGO, params, parent)
end

function ActivityValentine:getPrefabPath()
	return "Prefabs/Windows/activity/activity_valentine"
end

function ActivityValentine:initUI()
	self:getUIComponent()
	ActivityValentine.super.initUI(self)
	self:initUIComponent()
	self:updateAwards()
	self:updateProgress()

	xyd.LAST_MAIN_BEGIN_ID = 755

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_VALENTINE, function ()
		xyd.db.misc:setValue({
			key = "activity_valentine_redmark",
			value = xyd.getServerTime()
		})
	end)
end

function ActivityValentine:getUIComponent()
	local go = self.go
	self.Bg2_ = go:ComponentByName("Bg2_", typeof(UISprite))
	self.imgText_ = go:ComponentByName("imgText_", typeof(UISprite))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel_ = go:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.modelGroup = go:NodeByName("modelGroup").gameObject
	self.modelNode = go:ComponentByName("modelGroup/modelNode", typeof(UITexture))
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.progress = self.awardGroup:ComponentByName("progress", typeof(UISlider))
	self.progressLabel_ = self.awardGroup:ComponentByName("progress/label_", typeof(UILabel))

	for i = 1, 5 do
		self["awardIcon" .. i] = self.awardGroup:ComponentByName("awards/awardIcon" .. i, typeof(UISprite))
	end

	self.goBtn_ = go:NodeByName("goBtn_").gameObject
	self.goLabel_ = go:ComponentByName("goBtn_/button_label", typeof(UILabel))
	self.helpBtn_ = go:NodeByName("helpBtn_").gameObject
	self.recordBtn_ = go:NodeByName("recordBtn_").gameObject
end

function ActivityValentine:initUIComponent()
	self.goLabel_.text = __("ACTIVITY_VALENTINE_START")

	xyd.setUISpriteAsync(self.imgText_, nil, "activity_valentine_text_" .. xyd.Global.lang, nil, , true)
	import("app.components.CountDown").new(self.timeLabel_, {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	})

	local modelID = xyd.tables.miscTable:getNumber("activity_valentine_plot_model_id", "value")
	self.anim = xyd.tables.miscTable:split("activity_valentine_plot_model_animation", "value", "|")
	local modelName = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)
	self.model = xyd.Spine.new(self.modelNode.gameObject)

	self.model:setInfo(modelName, function ()
		self.model:setRenderTarget(self.modelNode, 1)
		self.model:SetLocalPosition(0, -120, 0)
		self.model:SetLocalScale(scale, scale, 1)
		self.model:play(self.anim[1], 0, 1)
	end)

	self.goBtn_effect = self:getSequence()

	self.goBtn_effect:Append(self.goBtn_.transform:DOScale(Vector3(0.8, 0.8, 0.8), 0.8))
	self.goBtn_effect:Append(self.goBtn_.transform:DOScale(Vector3(1, 1, 1), 0.5))
	self.goBtn_effect:SetLoops(-1)
end

function ActivityValentine:updateAwards()
	local awards = self.activityData.detail.awards
	local num = self.activityData.detail.num

	for i = 1, 5 do
		local awardIcon = self["awardIcon" .. i]
		local award = awards[i]

		if award < 1 and i < 5 then
			xyd.setUISpriteAsync(awardIcon, nil, "activity_valentine_award_icon1", nil, , true)
		elseif award == 1 and i < 5 then
			xyd.setUISpriteAsync(awardIcon, nil, "activity_valentine_award_icon2", nil, , true)
			awardIcon:Y(-8)
		elseif award < 1 and i == 5 then
			xyd.setUISpriteAsync(awardIcon, nil, "activity_valentine_award_icon3", nil, , true)
		elseif award == 1 and i == 5 then
			xyd.setUISpriteAsync(awardIcon, nil, "activity_valentine_award_icon4", nil, , true)
			awardIcon:Y(-8)
		end

		if self["award_effect" .. i] then
			self["award_effect" .. i]:Kill()
			awardIcon:SetLocalScale(1, 1, 1)
		end

		if i <= num and award < 1 then
			self["award_effect" .. i] = self:getSequence()

			self["award_effect" .. i]:Append(awardIcon.transform:DOScale(Vector3(0.7, 0.7, 0.7), 0.5))
			self["award_effect" .. i]:Append(awardIcon.transform:DOScale(Vector3(1, 1, 1), 0.3))
			self["award_effect" .. i]:SetLoops(-1)
		end
	end
end

function ActivityValentine:updateProgress()
	local num = self.activityData.detail.num or 0
	self.progress.value = num / 5
	self.progressLabel_.text = __("ACTIVITY_VALENTINE_COLLECT2", num)
end

function ActivityValentine:onRegister()
	ActivityValentine.super.onRegister(self)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.ACTIVITY_VALENTINE_PLOT, handler(self, self.onUpdate))

	UIEventListener.Get(self.modelGroup).onClick = handler(self, self.onClickModel)
	UIEventListener.Get(self.goBtn_).onClick = handler(self, self.goStory)
	UIEventListener.Get(self.helpBtn_).onClick = handler(self, function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_VALENTINE_HELP"
		})
	end)
	UIEventListener.Get(self.recordBtn_).onClick = handler(self, function ()
		xyd.openWindow("activity_valentine_record_window")
	end)

	for i = 1, 5 do
		UIEventListener.Get(self["awardIcon" .. i].gameObject).onClick = handler(self, function ()
			self:reqAward(i)
		end)
	end
end

function ActivityValentine:goStory()
	local beginId = {
		1
	}
	local lastId = xyd.db.misc:getValue("activity_valentine_last_id")

	if lastId and tonumber(lastId) > 0 and self:checkValid(lastId) then
		beginId = xyd.tables.activityPlotListTable:getMemoryPlotId(tonumber(lastId))
	end

	if self:checkLast() then
		beginId = {
			xyd.LAST_MAIN_BEGIN_ID
		}
	end

	xyd.WindowManager.get():openWindow("story_window", {
		jumpToSelect = true,
		story_type = xyd.StoryType.ACTIVITY_VALENTINE,
		story_list = beginId
	})
end

function ActivityValentine:reqAward(index)
	local awards = xyd.tables.activityValentineAwardTable:getAward(index)
	local num = self.activityData.detail.num
	local flag = self.activityData.detail.awards[index] == 1

	if index <= num and not flag then
		local params = require("cjson").encode({
			table_id = index
		})
		self.reqAwardIndex = index

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_VALENTINE, params)
	else
		xyd.openWindow("activity_award_preview_window", {
			awards = {
				awards
			},
			hasGotten = flag
		})
	end
end

function ActivityValentine:onAward(event)
	if not self.reqAwardIndex then
		print("error")

		return
	end

	local items = require("cjson").decode(event.data.detail).items

	if self.reqAwardIndex < 5 then
		xyd.models.itemFloatModel:pushNewItems(items)
	else
		local skins = {}

		for i = 1, #items do
			if xyd.tables.itemTable:getType(items[i].item_id) == xyd.ItemType.SKIN then
				for j = 1, items[i].item_num do
					table.insert(skins, items[i].item_id)

					items[i].cool = 1
				end
			end
		end

		local function effect_callback()
			xyd.openWindow("gamble_rewards_window", {
				wnd_type = 2,
				data = items
			})
		end

		if #skins > 0 then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = skins,
				callback = effect_callback
			})
		else
			effect_callback()
		end
	end

	self.reqAwardIndex = nil

	self:updateAwards()
end

function ActivityValentine:onUpdate(event)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_VALENTINE, function ()
		self.activityData.detail = event.data
	end)
	self:updateAwards()
	self:updateProgress()
	xyd.db.misc:setValue({
		value = 0,
		key = "activity_valentine_last_id"
	})

	local lastId = xyd.db.misc:getValue("activity_valentine_first_end")

	if lastId and tonumber(lastId) > 0 then
		local name = xyd.tables.activityPlotListTextTable:getName(tonumber(lastId))

		xyd.alertTips(__("ACTIVITY_VALENTINE_UNLOCK_TIPS", name))
		xyd.db.misc:setValue({
			value = 0,
			key = "activity_valentine_first_end"
		})
	end
end

function ActivityValentine:checkLast()
	local num = self.activityData.detail.num
	local openDay = xyd.tables.activityValentinePlotTable:getOpenDay(xyd.LAST_MAIN_BEGIN_ID)
	local pastDays = (xyd.getServerTime() - self.activityData.start_time) / xyd.TimePeriod.DAY_TIME

	if openDay <= pastDays and num == 4 then
		return true
	end

	return false
end

function ActivityValentine:checkValid(id)
	local record_ids = self.activityData.detail.plot_ids
	local record_type = {}

	for i = 1, #record_ids do
		table.insert(record_type, xyd.tables.activityValentinePlotTable:getEndType(record_ids[i]))
	end

	local Id = tonumber(id) % 157

	if xyd.arrayIndexOf(record_type, Id) == -1 then
		return true
	else
		xyd.db.misc:setValue({
			value = 0,
			key = "activity_valentine_last_id"
		})

		return false
	end
end

function ActivityValentine:onClickModel()
	local rand = math.random()
	local index = 2

	if rand >= 0.5 then
		index = 3
	end

	self.model:play(self.anim[index], 1, 1, function ()
		self.model:play(self.anim[1], 0, 1)
	end)
end

function ActivityValentine:resizeToParent()
	ActivityValentine.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.Bg2_:Y(-5 - (p_height - 873) * 0.11)
	self.imgText_:Y(-165 - (p_height - 874) * 0.11)
	self.timeGroup:Y(-255 - (p_height - 874) * 0.11)
	self.modelGroup:Y(-590 - (p_height - 874) * 0.91)
	self.awardGroup:Y(-778 - (p_height - 874) * 0.95)
	self.goBtn_:Y(-628 - (p_height - 874) * 0.86)
end

return ActivityValentine
