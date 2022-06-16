local ActivityLostSpaceMaskWindow = class("ActivityLostSpaceMaskWindow", import(".BaseWindow"))

function ActivityLostSpaceMaskWindow:ctor(name, params)
	ActivityLostSpaceMaskWindow.super.ctor(self, name, params)

	self.types = params.types
	self.anotherType = params.anotherType
end

function ActivityLostSpaceMaskWindow:initWindow()
	self:getUIComponent()
	ActivityLostSpaceMaskWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function ActivityLostSpaceMaskWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.effecCon = self.groupAction:ComponentByName("effecCon", typeof(UITexture))
	self.label = self.groupAction:ComponentByName("label", typeof(UILabel))
	self.allMask = self.groupAction:NodeByName("allMask").gameObject
end

function ActivityLostSpaceMaskWindow:registerEvent()
end

function ActivityLostSpaceMaskWindow:layout()
	self.effects = {}
	self.index = 1
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LOST_SPACE)

	self:show(self.index)
end

function ActivityLostSpaceMaskWindow:show(index)
	self.allMask.gameObject:SetActive(true)

	self.index = index
	local type = self.types[index]

	if not self.effects[index] then
		self.effects[index] = xyd.Spine.new(self.effecCon.gameObject)
	end

	self.effecCon.gameObject:Y(100)
	self.label.gameObject:Y(-146)

	self.label.width = 518

	if type == xyd.ActivityLostSpaceMaskType.EXIT_SHOW then
		self.effects[index]:setInfo("fx_lost_space_export", function ()
			self.effects[index]:play("texiao04", 0, 1)
		end)

		self.label.text = __("ACTIVITY_LOST_SPACE_SKILL_MASK_EXIT_SHOW")

		xyd.SoundManager:get():playSound(xyd.SoundID.ACTIVITY_LOST_SPACE_SOUND_BIG_EVENT)
	elseif type == xyd.ActivityLostSpaceMaskType.GET_FINIAL_AWARD then
		self.effecCon.gameObject:Y(-183)
		self.label.gameObject:Y(-193)
		self.effects[index]:setInfo("fx_lost_space_box", function ()
			self.effects[index]:play("texiao01", 1, 1)
		end)

		self.label.text = __("ACTIVITY_LOST_SPACE_SKILL_MASK_GET_AWARD")

		xyd.SoundManager:get():playSound(xyd.SoundID.ACTIVITY_LOST_SPACE_SOUND_OPEN_BOX)
	elseif type == xyd.ActivityLostSpaceMaskType.TREASURE_PART_SHOW then
		self.effects[index]:setInfo("fx_lost_space_export", function ()
			self.effects[index]:play("texiao06", 0, 1)
		end)

		self.label.text = __("ACTIVITY_LOST_SPACE_SKILL_MASK_TREASURE_PART_SHOW")

		xyd.SoundManager:get():playSound(xyd.SoundID.ACTIVITY_LOST_SPACE_SOUND_BIG_EVENT)
	elseif type == xyd.ActivityLostSpaceMaskType.TREASURE_SHOW then
		self.effects[index]:setInfo("fx_lost_space_export", function ()
			self.effects[index]:play("texiao05", 0, 1)
		end)

		if xyd.Global.lang == "fr_fr" then
			self.label.width = 530
		end

		self.label.text = __("ACTIVITY_LOST_SPACE_SKILL_MASK_TREASURE_SHOW")

		xyd.SoundManager:get():playSound(xyd.SoundID.ACTIVITY_LOST_SPACE_SOUND_BIG_EVENT)
	elseif type == xyd.ActivityLostSpaceMaskType.TREASURE_PART_SHOW_ENTER then
		self.effects[index]:setInfo("fx_lost_space_export", function ()
			self.effects[index]:play("texiao06", 0, 1)
		end)

		if xyd.Global.lang == "fr_fr" then
			self.label.width = 530
		end

		self.label.text = __("ACTIVITY_LOST_SPACE_SKILL_MASK_TREASURE_PART_SHOW_ENTER")

		xyd.SoundManager:get():playSound(xyd.SoundID.ACTIVITY_LOST_SPACE_SOUND_BIG_EVENT)
	end

	self:waitForTime(1, function ()
		self.allMask:SetActive(false)
	end)
	self:waitForTime(3, function ()
		if self.index == index then
			self:close()
		end
	end)
end

function ActivityLostSpaceMaskWindow:close(callback, skipAnimation)
	if self.index < #self.types then
		if self.effects[self.index] then
			self.effects[self.index]:SetActive(false)
		end

		self:show(self.index + 1)

		return
	end

	if xyd.arrayIndexOf(self.types, xyd.ActivityLostSpaceMaskType.GET_FINIAL_AWARD) > 0 then
		local stage_id = self.activityData.detail.stage_id - 1

		if stage_id < 1 then
			stage_id = 1
		end

		local award = xyd.tables.activityLostSpaceAwardsTable:getAward(stage_id)
		local param = {
			isNeedCostBtn = false,
			data = {
				{
					item_id = award[1],
					item_num = award[2]
				}
			},
			wnd_type = xyd.GambleWindowType.ACTIVITY
		}

		if xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LOST_SPACE_GIFTBAG):checkBuy() then
			local highAwards = xyd.tables.activityLostSpaceAwardsTable:getExtraAward(stage_id)

			table.insert(param.data, {
				item_id = highAwards[1],
				item_num = highAwards[2]
			})
		end

		if self.anotherType then
			function param.closeCallBackFun()
				xyd.WindowManager.get():openWindow("activity_lost_space_mask_window", {
					types = {
						self.anotherType
					}
				})
			end
		end

		xyd.WindowManager.get():openWindow("gamble_rewards_window", param)
	end

	ActivityLostSpaceMaskWindow.super.close(self, callback, skipAnimation)
end

return ActivityLostSpaceMaskWindow
