local BaseWindow = import(".BaseWindow")
local ActivityEnergySummonWindow = class("ActivityEnergySummonWindow", BaseWindow)
local ActivityModel = xyd.models.activity
local json = require("cjson")

function ActivityEnergySummonWindow:ctor(name, params)
	self.data = ActivityModel:getActivity(xyd.ActivityID.ENERGY_SUMMON)
	self.isEnergyFull = false

	if self.data:getLimitEnergy() <= self.data:getEnergy() then
		xyd.db.misc:setValue({
			key = "activity_energy_summon_info_btn",
			value = self.data:getEndTime()
		})
	end

	ActivityEnergySummonWindow.super.ctor(self, name, params)
	ActivityModel:reqActivityByID(xyd.ActivityID.ENERGY_SUMMON)
end

function ActivityEnergySummonWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.labelDesc_0 = groupAction:ComponentByName("labelDesc_0", typeof(UILabel))
	self.labelDesc_1 = groupAction:ComponentByName("labelDesc_1", typeof(UILabel))
	self.labelDesc_2 = groupAction:ComponentByName("labelDesc_2", typeof(UILabel))
	self.labelProgress = groupAction:ComponentByName("labelProgress", typeof(UILabel))
	self.drawBar_ = groupAction:ComponentByName("drawBar_", typeof(UISlider))
	self.drawBar_label = groupAction:ComponentByName("drawBar_/labelDisplay", typeof(UILabel))
	self.groupReward = groupAction:ComponentByName("groupReward", typeof(UILayout))
	self.groupBtn = groupAction:NodeByName("groupBtn").gameObject
	self.effectNode = groupAction:NodeByName("progresses/effectNode").gameObject

	for i = 1, 4 do
		self["bar_" .. tostring(i)] = groupAction:ComponentByName("progresses/" .. "bar_" .. tostring(i), typeof(UISlider))
	end
end

function ActivityEnergySummonWindow:initWindow()
	ActivityEnergySummonWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ActivityEnergySummonWindow:layout()
	self.labelTitle.text = __("ACTIVITY_ENERGY_SUMMON_WINDOW")
	self.labelDesc_0.text = __("ACTIVITY_ENERGY_CRITICAL_DESC")
	self.labelDesc_1.text = __("ACTIVITY_ENERGY_SUMMON_HAS_SUMMON")
	self.labelDesc_2.text = __("ACTIVITY_ENERGY_SUMMON_DESC")
end

function ActivityEnergySummonWindow:registerEvent()
	BaseWindow.register(self)

	UIEventListener.Get(self.groupBtn).onClick = handler(self, self.draw)

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityEnergySummonWindow:draw()
	local canSummonNum = xyd.models.slot:getCanSummonNum()

	if canSummonNum < 1 then
		local function callback()
			xyd.openWindow("slot_window", {}, function ()
				xyd.WindowManager.get():closeAllWindows({
					slot_window = true,
					main_window = true,
					loading_window = true,
					guide_window = true
				})
			end)
		end

		xyd.openWindow("partner_slot_increase_window")

		return false
	end

	if self.data:getEnergy() < self.data:getLimitEnergy() then
		xyd.alert(xyd.AlertType.TIPS, __("ENERGY_NOT_ENOUGH"))

		return false
	end

	if self.data.detail.charges[1].buy_times < 1 and self.data:getSummonTimes() > 0 then
		xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_ENERGY_SUMMON_BUY_CARD"))

		return false
	end

	xyd.db.misc:setValue({
		value = 0,
		key = "activity_energy_summon_info_btn"
	})
	ActivityModel:reqAward(xyd.ActivityID.ENERGY_SUMMON)

	return true
end

function ActivityEnergySummonWindow:onActivityByID(event)
	local id = event.data.act_info.activity_id
	local data = ActivityModel:getActivity(id)

	data:setData(event.data.act_info)
	self:updateContent()
end

function ActivityEnergySummonWindow:onAward(event)
	local detail = json.decode(event.data.detail)

	self:drawEffect(function ()
		xyd.onGetNewPartnersOrSkins({
			destory_res = false,
			partners = {
				detail.items[1].table_id
			},
			callback = function ()
			end
		})
		self:updateContent()
	end)
end

function ActivityEnergySummonWindow:updateContent()
	self:initDrawTimes()
	self:initAward()
	self:initProgress()
	self:updateEffectNode(true)
end

function ActivityEnergySummonWindow:initDrawTimes()
	local draw = self.data:getDrawTimes()
	local limitDraw = self.data:getLimitDraw()
	self.drawBar_.value = draw / limitDraw
	self.drawBar_label.text = tostring(draw) .. "/" .. tostring(limitDraw)
end

function ActivityEnergySummonWindow:initAward()
	local datas = xyd.tables.miscTable:split2Cost("act_summon_energy_pool", "value", "|#")

	NGUITools.DestroyChildren(self.groupReward.transform)

	local awards = self.data:getAwarded()
	local itemTable = xyd.tables.itemTable

	for i = 1, #datas do
		local data = datas[i]
		local partnerCost = itemTable:partnerCost(data[1])
		local item = xyd.getItemIcon({
			scale = 0.7,
			not_show_ways = true,
			itemID = partnerCost[1],
			uiRoot = self.groupReward.gameObject
		})

		for __, award in ipairs(awards) do
			if tonumber(data[1]) == tonumber(award) then
				item:setChoose(true)
			end
		end
	end

	self.groupReward:Reposition()

	self.groupReward.gap = Vector2(0, 26)
end

function ActivityEnergySummonWindow:initProgress()
	local energy = self.data:getEnergy()
	local limitEnergy = self.data:getLimitEnergy()
	self.labelProgress.text = tostring(energy) .. "/" .. tostring(limitEnergy)

	self:updateBar()
end

function ActivityEnergySummonWindow:updateBar()
	local percent = self.data:getEnergy() / self.data:getLimitEnergy()

	for i = 1, 4 do
		self["bar_" .. tostring(i)].value = percent
	end
end

function ActivityEnergySummonWindow:updateEffectNode(force)
	if force == "nil" then
		force = false
	end

	local isFull = false

	if self.data:getLimitEnergy() <= self.data:getEnergy() then
		isFull = true
	end

	if not force and isFull == self.isEnergyFull then
		return
	end

	self.isEnergyFull = isFull
	local texiaoName = "texiao01"

	if isFull then
		texiaoName = "texiao02"
	end

	NGUITools.DestroyChildren(self.effectNode.transform)

	self.effect = xyd.Spine.new(self.effectNode)

	self.effect:setInfo("fx_energy_summon1", function ()
		self.effect:play(texiaoName, 0)
	end)
end

function ActivityEnergySummonWindow:drawEffect(callback)
	if not self.effect then
		return
	end

	self.effectNode:Y(100)
	self.effect:play("texiao03", 1, 1, function ()
		if callback then
			callback()
			self.effectNode:Y(-170)
		end
	end)
end

return ActivityEnergySummonWindow
