local ActivityContent = import(".ActivityContent")
local ActivityEnergySummon = class("ActivityEnergySummon", ActivityContent)

function ActivityEnergySummon:ctor(parentGO, params, parent)
	self.isEnergyFull = false

	ActivityEnergySummon.super.ctor(self, parentGO, params, parent)
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ENERGY_SUMMON)
end

function ActivityEnergySummon:getPrefabPath()
	return "Prefabs/Windows/activity/activity_energy_summon"
end

function ActivityEnergySummon:getUIComponent()
	local go = self.go
	local group = go:NodeByName("e:Group").gameObject
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.infoBtn = go:NodeByName("infoBtn").gameObject
	self.redMark = go:ComponentByName("infoBtn/redMark", typeof(UISprite))
	self.helpBtn_0 = go:NodeByName("helpBtn_0").gameObject
	self.imgText_0 = group:ComponentByName("imgText_0", typeof(UITexture))
	self.contentBg = group:ComponentByName("contentBg", typeof(UISprite))
	local groupContent = group:NodeByName("groupContent").gameObject
	self.imgText_1 = groupContent:ComponentByName("imgText_1", typeof(UITexture))
	self.labelDesc_0 = groupContent:ComponentByName("labelDesc_0", typeof(UILabel))
	local groupBottom = groupContent:NodeByName("groupBottom").gameObject
	self.groupReward = groupBottom:NodeByName("groupReward").gameObject
	self.labelDesc_2 = groupBottom:ComponentByName("groupReward/labelDesc_2", typeof(UILabel))
	self.labelDesc_3 = groupBottom:ComponentByName("groupReward/labelDesc_3", typeof(UILabel))
	self.groupReward_1 = groupBottom:NodeByName("groupReward/groupReward_1").gameObject
	self.groupReward_2 = groupBottom:NodeByName("groupReward/groupReward_2").gameObject
	self.labelVip = groupBottom:ComponentByName("labelVip", typeof(UILabel))
	self.labelLimit = groupBottom:ComponentByName("labelLimit", typeof(UILabel))
	self.buyBtn = groupBottom:NodeByName("buyBtn").gameObject
	self.button_label = groupBottom:ComponentByName("buyBtn/button_label", typeof(UILabel))
	local progresses = group:NodeByName("progresses").gameObject
	self.groupBtn = group:NodeByName("groupBtn").gameObject

	for i = 1, 4 do
		self["bar_" .. tostring(i)] = progresses:ComponentByName("bar_" .. tostring(i), typeof(UISlider))
	end

	self.labelProgress = progresses:ComponentByName("labelProgress", typeof(UILabel))
	self.effectNode = progresses:NodeByName("effectNode").gameObject
end

function ActivityEnergySummon:initUIComponent()
	local res_prefix_text = "Textures/activity_text_web/"
	self.giftBagId = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ENERGY_SUMMON)[1]
	self.data = self.activityData
	self.labelDesc_0.text = __("ACTIVITY_ENERGY_SUMMON_DESC_0")

	if xyd.Global.lang ~= "zh_tw" then
		self.labelDesc_0.fontSize = 16
	end

	self.labelDesc_2.text = __("ACTIVITY_ENERGY_SUMMON_DESC_INSTANT_AWARD")

	xyd.setUITextureAsync(self.imgText_0, res_prefix_text .. "activity_energy_summon_logo_1_" .. xyd.Global.lang)
	xyd.setUITextureAsync(self.imgText_1, res_prefix_text .. "activity_energy_summon_logo_" .. xyd.Global.lang)

	self.labelVip.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(self.giftBagId)) .. "VIP EXP"
	self.button_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagId)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagId))
	local parent = self.go.transform.parent:GetComponent(typeof(UIPanel)).height
	self.contentBg.height = parent * 0.787 - 220

	self.contentBg:Y(-110 + (867 - parent) * 0.6)
	self.imgText_1:Y(230 + (867 - parent) * 0.28)
	self.labelDesc_0:Y(135 + (867 - parent) * 0.31)
	self.groupReward:Y(75 + (867 - parent) * 0.62)

	self.groupReward:ComponentByName("e:Image", typeof(UISprite)).height = 87 + (parent - 867) * 0.11

	self.labelVip:Y(15 + (867 - parent) * 0.73)
	self.labelLimit:Y(-10 + (867 - parent) * 0.79)
	self.buyBtn:Y(-55 + (867 - parent) * 0.815)
end

function ActivityEnergySummon:initUI()
	ActivityContent.initUI(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
	self:updateContent()
	self:updateRedMark()
end

function ActivityEnergySummon:register()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		local params = {
			key = "ACTIVITY_ENERGY_SUMMON_HELP_1"
		}

		xyd.openWindow("help_window", params)
	end

	UIEventListener.Get(self.helpBtn_0).onClick = function ()
		local params = {
			key = "ACTIVITY_ENERGY_SUMMON_HELP_0"
		}

		xyd.openWindow("help_window", params)
	end

	UIEventListener.Get(self.infoBtn).onClick = function ()
		xyd.openWindow("activity_energy_summon_window")

		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = xyd.ActivityID.ENERGY_SUMMON * 100 + 3

		xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)

		if self.redMark.gameObject.activeSelf then
			xyd.db.misc:setValue({
				key = "activity_energy_summon_info_btn",
				value = self.data:getEndTime()
			})
		end
	end

	UIEventListener.Get(self.groupBtn).onClick = function ()
		xyd.openWindow("activity_energy_summon_window")

		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = xyd.ActivityID.ENERGY_SUMMON * 100 + 3

		xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)
	end

	UIEventListener.Get(self.buyBtn).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagId)
	end

	UIEventListener.Get(self.effectNode).onClick = function ()
		xyd.openWindow("activity_energy_summon_window")
		xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, {
			activity_id = xyd.ActivityID.ENERGY_SUMMON * 100 + 2
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))
end

function ActivityEnergySummon:updateContent()
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", xyd.tables.activityDragonBoatTable:getLimit(self.giftBagId) - self.data.detail.charges[1].buy_times)
	self.labelProgress.text = tostring(self.data:getEnergy()) .. "/" .. tostring(self.data:getLimitEnergy())

	if self.data.detail.charges[1].buy_times > 0 then
		self.labelDesc_3.text = __("ACTIVITY_ENERGY_SUMMON_DESC_HAS_BUFA")

		xyd.applyGrey(self.buyBtn:GetComponent(typeof(UISprite)))

		UIEventListener.Get(self.buyBtn).onClick = nil
	else
		self.labelDesc_3.text = __("ACTIVITY_ENERGY_SUMMON_DESC_BUFA")

		xyd.applyOrigin(self.buyBtn:GetComponent(typeof(UISprite)))
	end

	self:updateInfoRedPoint()
	self:updateReward()
	self:updateBar()
	self:updateEffectNode(true)
end

function ActivityEnergySummon:updateInfoRedPoint()
	local TodayVisit = tonumber(xyd.db.misc:getValue("activity_energy_summon_info_btn"))

	if TodayVisit == nil then
		TodayVisit = 0
	end

	local InfoRedPoint = self.data:getLimitEnergy() <= self.data:getEnergy() and TodayVisit < self.data:getEndTime() - 1

	self.redMark:SetActive(InfoRedPoint)
end

function ActivityEnergySummon:updateReward()
	NGUITools.DestroyChildren(self.groupReward_1.transform)

	local giftId = xyd.tables.giftBagTable:getGiftID(self.giftBagId)
	local awards = xyd.tables.giftTable:getAwards(giftId)

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = xyd.getItemIcon({
				not_show_ways = true,
				scale = 0.7,
				itemID = data[1],
				num = data[2],
				uiRoot = self.groupReward_1
			})
		end
	end

	NGUITools.DestroyChildren(self.groupReward_2.transform)

	local itemID = xyd.tables.miscTable:getNumber("act_summon_energy_item", "value")
	local num = self.data:getExEnergy()
	local item = xyd.getItemIcon({
		not_show_ways = true,
		scale = 0.7,
		itemID = itemID,
		num = num,
		uiRoot = self.groupReward_2
	})

	self.groupReward_1:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityEnergySummon:updateBar()
	local percent = self.data:getEnergy() / self.data:getLimitEnergy()

	for i = 1, 4 do
		self["bar_" .. tostring(i)].value = percent
	end
end

function ActivityEnergySummon:updateEffectNode(force)
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

	if self.effect then
		self.effect:play(texiaoName, 0)

		return
	end

	self.effect = xyd.Spine.new(self.effectNode)

	self.effect:setInfo("fx_energy_summon1", function ()
		self.effect:play(texiaoName, 0)
	end)
end

function ActivityEnergySummon:onActivityByID(event)
	local id = event.data.act_info.activity_id
	local data = xyd.models.activity:getActivity(id)

	data:setData(event.data.act_info)
	self:updateContent()
end

function ActivityEnergySummon:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	self:updateContent()
end

function ActivityEnergySummon:updateRedMark()
	local function callback()
		if self.data:getLimitEnergy() <= self.data:getEnergy() then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ENERGY_SUMMON, function ()
				xyd.db.misc:setValue({
					key = "activity_energy_summon",
					value = self.activityData:getEndTime()
				})
			end)
		end
	end

	self:waitForTime(0.5, callback)
end

function ActivityEnergySummon:onAward(event)
	self:updateContent()
end

return ActivityEnergySummon
