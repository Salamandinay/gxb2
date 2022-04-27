local ActivityContent = import(".ActivityContent")
local ActivityScratchCard = class("ActivityScratchCard", ActivityContent)
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local modelGirlName = "luxun_10_lihui01"

function ActivityScratchCard:ctor(parentGO, params, parent)
	ActivityScratchCard.super.ctor(self, parentGO, params, parent)
end

function ActivityScratchCard:getPrefabPath()
	return "Prefabs/Windows/activity/activity_scratch_card"
end

function ActivityScratchCard:initUI()
	self:getUIComponent()
	ActivityScratchCard.super.initUI(self)
	self:initUIComponent()
	self:initModel()
	self:updateItemCount()
end

function ActivityScratchCard:getUIComponent()
	local go = self.go
	self.textImg = go:ComponentByName("textImg", typeof(UITexture))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.listBtn = go:NodeByName("listBtn").gameObject
	self.timeGroupLayout = go:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel = go:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel = go:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.modelGroup = go:ComponentByName("modelGroup", typeof(UITexture))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	local resGroup = self.contentGroup:NodeByName("resGroup").gameObject
	self.countLabel = resGroup:ComponentByName("countLabel", typeof(UILabel))
	self.addBtn = resGroup:NodeByName("addBtn").gameObject
	self.singleCountBtn = self.contentGroup:NodeByName("singleCountBtn").gameObject
	self.tenCountBtn = self.contentGroup:NodeByName("tenCountBtn").gameObject
end

function ActivityScratchCard:initUIComponent()
	xyd.setUITextureByNameAsync(self.textImg, "activity_scratch_text01_" .. xyd.Global.lang, true)

	self.singleCountBtn:ComponentByName("button_label", typeof(UILabel)).text = __("ACTIVITY_SCRATCH_CARD_ONE")
	self.tenCountBtn:ComponentByName("button_label", typeof(UILabel)).text = __("ACTIVITY_SCRATCH_CARD_TEN")
	self.endLabel.text = __("END_TEXT")

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		CountDown.new(self.timeLabel, {
			duration = self.activityData:getEndTime() - xyd.getServerTime()
		})
	else
		self.endLabel:SetActive(false)
		self.timeLabel:SetActive(false)
	end

	self.timeGroupLayout:Reposition()
end

function ActivityScratchCard:initModel()
	NGUITools.DestroyChildren(self.modelGroup.transform)

	self.modelGirl = xyd.Spine.new(self.modelGroup.gameObject)

	self.modelGirl:setInfo(modelGirlName, function ()
		self.modelGirl:setRenderTarget(self.modelGroup, 1)
		self.modelGirl:play("idle", 0)
	end)
end

function ActivityScratchCard:updateItemCount()
	self.countLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.SCRATCH_CARD_TICKET) or 0
end

function ActivityScratchCard:resizeToParent()
	ActivityScratchCard.super.resizeToParent(self)
	self.go:Y(-520)

	local height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.contentGroup:Y(-235 - 1.1 * (height - 867))
end

function ActivityScratchCard:onRegister()
	ActivityScratchCard.super.onRegister(self)

	UIEventListener.Get(self.singleCountBtn).onClick = function ()
		self:onClickBtn(1)
	end

	UIEventListener.Get(self.tenCountBtn).onClick = function ()
		self:onClickBtn(10)
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		local params = {
			key = "ACTIVITY_SCRATCH_CARD_HELP"
		}

		xyd.openWindow("help_window", params)
	end

	UIEventListener.Get(self.listBtn).onClick = function ()
		xyd.openWindow("activity_scratch_card_record_window", {
			records = self.activityData.detail.records
		})
	end

	UIEventListener.Get(self.addBtn).onClick = function ()
		if self:getBuyTime() <= 0 then
			xyd.showToast(__("ACTIVITY_SCRATCH_CARD_LIMIT"))

			return
		end

		local data = xyd.tables.miscTable:split2Cost("scratch_card_buy_cost", "value", "#")
		local flag = self:getBuyTime() > xyd.models.backpack:getItemNumByID(data[1]) / data[2]

		xyd.openWindow("limit_purchase_item_window", {
			limitKey = "ACTIVITY_SCRATCH_CARD_LIMIT",
			needTips = true,
			buyNum = 1,
			titleKey = "ACTIVITY_SCRATCH_CARD_BUY_TITLE",
			buyType = xyd.ItemID.SCRATCH_CARD_TICKET,
			costType = data[1],
			costNum = data[2],
			purchaseCallback = function (evt, num)
				if xyd.models.backpack:getItemNumByID(data[1]) < data[2] * num then
					xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(data[1])))

					return
				end

				local msg = messages_pb.boss_buy_req()
				msg.activity_id = xyd.ActivityID.ACTIVITY_SCRATCH_CARD
				msg.num = num

				xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
			end,
			limitNum = self:getBuyTime(),
			notEnoughKey = flag and "PERSON_NO_CRYSTAL" or "ACTIVITY_WORLD_BOSS_LIMIT",
			eventType = xyd.event.BOSS_BUY,
			showWindowCallback = function ()
				if flag then
					xyd.openWindow("vip_window")
				end
			end,
			confirmText = flag and __("BUY") or __("SURE")
		})
	end

	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateItemCount))
	self:registerEvent(xyd.event.BOSS_BUY, function (event)
		if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SCRATCH_CARD then
			return
		end

		self.activityData.detail.buy_times = event.data.buy_times

		self:updateItemCount()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local detail = json.decode(event.data.detail)

		if self.modelGirl then
			self.modelGirl:play("touch", 1, nil, function ()
				self.modelGirl:play("idle", 0)
				self:showScratch(detail.items, detail.awards)
			end)
		end
	end)
end

function ActivityScratchCard:onClickBtn(count)
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.SCRATCH_CARD_TICKET) < count then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(xyd.ItemID.SCRATCH_CARD_TICKET)))

		return
	end

	xyd.setTouchEnable(self.singleCountBtn, false)
	xyd.setTouchEnable(self.tenCountBtn, false)
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SCRATCH_CARD, json.encode({
		num = count
	}))
end

function ActivityScratchCard:getBuyTime()
	return xyd.tables.miscTable:getNumber("scratch_card_buy_limit", "value") - self.activityData.detail.buy_times
end

function ActivityScratchCard:showScratch(items, awards)
	xyd.openWindow("scratch_card_window", {
		items = items,
		awards = awards
	})
	xyd.setTouchEnable(self.singleCountBtn, true)
	xyd.setTouchEnable(self.tenCountBtn, true)
end

return ActivityScratchCard
