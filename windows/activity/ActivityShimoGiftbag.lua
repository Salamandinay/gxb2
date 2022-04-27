local ActivityShimoGiftbag = class("ActivityShimoGiftbag", import(".ActivityContent"))
local CountDown = require("app.components.CountDown")

function ActivityShimoGiftbag:ctor(parentGo, params, parent)
	ActivityShimoGiftbag.super.ctor(self, parentGo, params, parent)

	self.boughtID = nil
end

function ActivityShimoGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_shimo_giftbag"
end

function ActivityShimoGiftbag:initUI()
	self:getUIComponent()
	ActivityShimoGiftbag.super.initUI(self)
	xyd.setUISpriteAsync(self.imgText, nil, "activity_lafuli_giftbag_logo_" .. xyd.Global.lang)
	self:initText()

	for i = 1, 6 do
		self:initItem(i)
	end
end

function ActivityShimoGiftbag:resizeToParent()
	ActivityShimoGiftbag.super.resizeToParent(self)

	local height = self.go:GetComponent(typeof(UIWidget)).height

	self.bg2:Y(-0.235 * (height - 869) - 183)
	self.textGroup:Y(-0.066 * (height - 869) - 130)
	self.mainGroup:Y(-0.617 * (height - 869) - 702)

	for i = 4, 6 do
		self["item" .. i]:Y(-0.197 * (height - 869) - 25)
	end
end

function ActivityShimoGiftbag:getUIComponent()
	local go = self.go
	self.bg2 = go:NodeByName("bg2").gameObject
	self.textGroup = go:NodeByName("textGroup").gameObject
	self.imgText = self.textGroup:ComponentByName("imgText", typeof(UISprite))
	self.timeGroup = self.textGroup:NodeByName("timeGroup").gameObject
	self.timeLabel = self.textGroup:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel = self.textGroup:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.mainGroup = go:NodeByName("mainGroup").gameObject

	for i = 1, 6 do
		self["item" .. i] = self.mainGroup:NodeByName("item (" .. i .. ")").gameObject
	end
end

function ActivityShimoGiftbag:initText()
	self.endLabel.text = __("END")

	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	if xyd.Global.lang == "de_de" then
		self.timeLabel.fontSize = 16
		self.endLabel.fontSize = 16
	end

	xyd.setUISpriteAsync(self.imgText, nil, "activity_shimo_giftbag_logo_" .. xyd.Global.lang)
end

function ActivityShimoGiftbag:initItem(i)
	local item = self["item" .. i]
	self["btn" .. i] = item:NodeByName("buyBtn").gameObject
	local btnLabel = self["btn" .. i]:ComponentByName("button_label", typeof(UILabel))
	local dumpIcon = item:NodeByName("dumpIcon").gameObject
	local dumpLabel = dumpIcon:ComponentByName("dumpLabel", typeof(UILabel))
	local dumpLabelNum = dumpIcon:ComponentByName("dumpLabelNum", typeof(UILabel))
	local limitLabel = item:ComponentByName("limitLabel", typeof(UILabel))
	local VIPlabel = item:ComponentByName("VIPLabel", typeof(UILabel))

	dumpIcon:SetActive(false)

	if i == 1 then
		local data = xyd.tables.miscTable:split2Cost("activity_pet_giftbag_cost", "value", "@|#")
		btnLabel.text = data[1][1][2]
		local limit = xyd.tables.miscTable:getNumber("activity_pet_giftbag_limit", "value") - self.activityData.detail.buy_times[1]
		limitLabel.text = __("BUY_GIFTBAG_LIMIT") .. tostring(limit)

		VIPlabel:SetActive(false)

		if limit == 0 then
			xyd.applyChildrenGrey(self["btn" .. i])

			self["btn" .. i]:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		end

		local iconGroups = item:NodeByName(#data[2] .. "icon").gameObject

		for i = 1, #data[2] do
			NGUITools.DestroyChildren(iconGroups:NodeByName("icon" .. (i + 3) % 3 + 1).transform)

			local icon = xyd.getItemIcon({
				show_has_num = true,
				itemID = data[2][i][1],
				num = data[2][i][2],
				uiRoot = iconGroups:NodeByName("icon" .. (i + 3) % 3 + 1).gameObject,
				scale = Vector3(0.6, 0.6, 1),
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			icon:setChoose(false)
		end
	else
		local giftbagID = xyd.tables.activityTable:getGiftBag(self.id)[i - 1]
		btnLabel.text = xyd.tables.giftBagTextTable:getCurrency(giftbagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(giftbagID)
		dumpLabel.text = __("ACTIVITY_WARMUP_PACK_TEXT05")
		dumpLabelNum.text = "[size=18]+[size=21]" .. 960 .. "[size=14]%"
		local limit = xyd.tables.giftBagTable:getBuyLimit(giftbagID) - self.activityData.detail.charges[i - 1].buy_times
		limitLabel.text = __("BUY_GIFTBAG_LIMIT") .. tostring(limit)

		if limit == 0 then
			xyd.applyChildrenGrey(self["btn" .. i])

			self["btn" .. i]:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		end

		local awards = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(giftbagID))
		local iconGroups = item:NodeByName(#awards - 1 .. "icon").gameObject

		for i = 1, #awards do
			if awards[i][1] ~= xyd.ItemID.VIP_EXP then
				NGUITools.DestroyChildren(iconGroups:NodeByName("icon" .. (i + 3) % 3 + 1).transform)

				local icon = xyd.getItemIcon({
					show_has_num = true,
					itemID = awards[i][1],
					num = awards[i][2],
					uiRoot = iconGroups:NodeByName("icon" .. (i + 3) % 3 + 1).gameObject,
					scale = Vector3(0.6, 0.6, 1),
					wndType = xyd.ItemTipsWndType.ACTIVITY
				})

				icon:setChoose(false)
			else
				VIPlabel.text = "+" .. awards[i][2] .. " VIP EXP"
			end
		end
	end
end

function ActivityShimoGiftbag:onRegister()
	for i = 1, 6 do
		UIEventListener.Get(self["btn" .. i]).onClick = function ()
			if i == 1 then
				local data = xyd.tables.miscTable:split2Cost("activity_pet_giftbag_cost", "value", "@|#")

				if xyd.models.backpack:getItemNumByID(data[1][1][1]) < data[1][1][2] then
					xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(data[1][1][1])))

					return
				end

				xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
					if not yes then
						return
					end

					local msg = messages_pb.get_activity_award_req()
					msg.activity_id = xyd.ActivityID.ACTIVITY_SHIMO_GIFTBAG

					xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
				end)
			else
				xyd.SdkManager.get():showPayment(xyd.tables.activityTable:getGiftBag(self.id)[i - 1])
			end

			self.boughtID = i
		end
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityShimoGiftbag:onAward()
	if self.boughtID and self.boughtID == 1 then
		self.activityData.detail.buy_times[1] = self.activityData.detail.buy_times[1] + 1

		self:initItem(self.boughtID)

		self.boughtID = nil
		local data = xyd.tables.miscTable:split2Cost("activity_pet_giftbag_cost", "value", "@|#")
		local awards = data[2]
		local params = {}

		for i = 1, #awards do
			table.insert(params, {
				item_id = awards[i][1],
				item_num = awards[i][2]
			})
		end

		xyd.models.itemFloatModel:pushNewItems(params)
	end
end

function ActivityShimoGiftbag:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	if self.boughtID then
		self.activityData.detail.charges[self.boughtID - 1].buy_times = self.activityData.detail.charges[self.boughtID - 1].buy_times + 1

		self:initItem(self.boughtID)

		self.boughtID = nil
	end
end

return ActivityShimoGiftbag
