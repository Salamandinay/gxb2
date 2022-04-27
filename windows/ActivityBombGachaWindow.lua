local BaseWindow = import("app.windows.BaseWindow")
local ActivityBombGachaWindow = class("ActivityBombGachaWindow", BaseWindow)

function ActivityBombGachaWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.num = params.num
	self.skip = false
	self.onPlay = false
end

function ActivityBombGachaWindow:initWindow()
	ActivityBombGachaWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.itemLabel = self.groupAction:ComponentByName("groupItem/label", typeof(UILabel))
	self.itemBtn = self.groupAction:NodeByName("groupItem/btn").gameObject
	self.probabilityBtn = self.groupAction:NodeByName("probabilityBtn").gameObject
	self.skipBtn = self.groupAction:NodeByName("skipBtn").gameObject
	self.helpBtn = self.groupAction:NodeByName("helpBtn").gameObject
	self.oneBtn = self.groupAction:NodeByName("oneBtn").gameObject
	self.oneLabel = self.oneBtn:ComponentByName("label", typeof(UILabel))
	self.oneLabel2 = self.oneBtn:ComponentByName("label2", typeof(UILabel))
	self.oneIcon = self.oneBtn:ComponentByName("costImg", typeof(UISprite))
	self.tenBtn = self.groupAction:NodeByName("tenBtn").gameObject
	self.tenLabel = self.tenBtn:ComponentByName("label", typeof(UILabel))
	self.tenLabel2 = self.tenBtn:ComponentByName("label2", typeof(UILabel))
	self.tenIcon = self.tenBtn:ComponentByName("costImg", typeof(UISprite))
	self.descLabel = self.groupAction:ComponentByName("label", typeof(UILabel))
	self.model = self.groupAction:NodeByName("model").gameObject
	self.progressBar = self.groupAction:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel = self.groupAction:ComponentByName("progressBar/progressLabel", typeof(UILabel))
	local value = xyd.db.misc:getValue("bomb_skip")

	if value and value == "1" then
		self.skip = true

		xyd.setUISprite(self.skipBtn:GetComponent(typeof(UISprite)), nil, "battle_img_skip")
	end

	self:layout()
	self:RegisterEvent()
end

function ActivityBombGachaWindow:layout()
	local maxExp = xyd.tables.miscTable:getNumber("activity_bomb_make_lv", "value")
	self.progressLabel.text = self.num % maxExp .. "/" .. maxExp
	self.progressBar.value = math.min(self.num % maxExp / maxExp, 1)
	self.oneLabel.text = __("ACTIVITY_BOMB_MAKE")
	self.tenLabel.text = __("ACTIVITY_BOMB_10_MAKE")
	self.oneLabel2.text = xyd.tables.miscTable:split2Cost("activity_bomb_make_cost", "value", "#")[2]
	self.tenLabel2.text = xyd.tables.miscTable:split2Cost("activity_bomb_make_cost", "value", "#")[2] * 10
	self.descLabel.text = __("ACTIVITY_BOMB_LEVEL", math.floor(self.num / maxExp))
	self.itemLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.FIREWORK_DUST)

	xyd.setUISpriteAsync(self.oneIcon, nil, "icon_" .. xyd.tables.miscTable:split2Cost("activity_bomb_make_cost", "value", "#")[1])
	xyd.setUISpriteAsync(self.tenIcon, nil, "icon_" .. xyd.tables.miscTable:split2Cost("activity_bomb_make_cost", "value", "#")[1])

	self.itemBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.skipBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.helpBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.oneBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.tenBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.spineModel = xyd.Spine.new(self.model)

	self.spineModel:setInfo("pipiluo_activity", function ()
		self.spineModel:play("idle", 0)

		self.itemBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		self.skipBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		self.helpBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		self.oneBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		self.tenBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end)
end

function ActivityBombGachaWindow:onClickCloseButton()
	if self.onPlay then
		return
	end

	ActivityBombGachaWindow.super.onClickCloseButton(self)
end

function ActivityBombGachaWindow:RegisterEvent()
	UIEventListener.Get(self.itemBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.FIREWORK_DUST,
			activityID = xyd.ActivityID.ACTIVITY_BOMB,
			callback = function ()
				xyd.closeWindow(self.name_)
			end
		})
	end)
	UIEventListener.Get(self.probabilityBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_bomb_probability_window")
	end)
	UIEventListener.Get(self.skipBtn).onClick = handler(self, function ()
		if self.skip then
			self.skip = false

			xyd.setUISprite(self.skipBtn:GetComponent(typeof(UISprite)), nil, "btn_max")
		else
			self.skip = true

			xyd.setUISprite(self.skipBtn:GetComponent(typeof(UISprite)), nil, "battle_img_skip")
		end
	end)
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_BOMB_HELP"
		})
	end)
	local cost = xyd.tables.miscTable:split2Cost("activity_bomb_make_cost", "value", "#")
	UIEventListener.Get(self.oneBtn).onClick = handler(self, function ()
		if self.onPlay then
			return
		end

		if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
			self.onPlay = true
			local msg = messages_pb:boss_buy_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_BOMB
			msg.num = 1

			xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)

			self.itemBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.skipBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.helpBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.oneBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.tenBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
		end
	end)
	UIEventListener.Get(self.tenBtn).onClick = handler(self, function ()
		if self.onPlay then
			return
		end

		if cost[2] * 10 <= xyd.models.backpack:getItemNumByID(cost[1]) then
			self.onPlay = true
			local msg = messages_pb:boss_buy_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_BOMB
			msg.num = 10

			xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)

			self.itemBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.skipBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.helpBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.oneBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.tenBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
		end
	end)

	self.eventProxy_:addEventListener(xyd.event.BOSS_BUY, function (event)
		if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_BOMB then
			return
		end

		local data = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_BOMB)
		data.detail.num = data.detail.num + event.data.buy_times * xyd.tables.miscTable:split2Cost("activity_bomb_make_cost", "value", "#")[2]
		self.num = self.num + event.data.buy_times * xyd.tables.miscTable:split2Cost("activity_bomb_make_cost", "value", "#")[2]
		local maxExp = xyd.tables.miscTable:getNumber("activity_bomb_make_lv", "value")
		local cost = xyd.tables.miscTable:split2Cost("activity_bomb_make_cost", "value", "#")

		local function func()
			self.progressLabel.text = self.num % maxExp .. "/" .. maxExp
			self.progressBar.value = math.min(self.num % maxExp / maxExp, 1)
			self.descLabel.text = __("ACTIVITY_BOMB_LEVEL", math.floor(self.num / maxExp))
			self.itemLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.FIREWORK_DUST)
			local ids = xyd.tables.activityBombMakeTable:getIds()
			local award = xyd.tables.activityBombMakeTable:getAward(ids[#ids])
			local tempItems = {}
			local isCool = 0

			if tonumber(event.data.items[1].item_id) == award[1] and tonumber(event.data.items[1].item_num) == award[2] or tonumber(event.data.items[1].item_id) == award[1] and tonumber(event.data.items[1].item_num) == award[2] * 10 then
				isCool = 1
			end

			table.insert(tempItems, {
				item_id = event.data.items[1].item_id,
				item_num = event.data.items[1].item_num,
				cool = isCool
			})
			xyd.openWindow("gamble_rewards_window", {
				btnLabelText2 = "ACTIVITY_BOMB_10_MAKE",
				btnLabelText = "ACTIVITY_BOMB_MAKE",
				wnd_type = 4,
				data = tempItems,
				cost = {
					cost[1],
					cost[2]
				},
				cost2 = {
					cost[1],
					cost[2] * 10
				},
				buyCallback = function (a, b, isTen)
					xyd.closeWindow("gamble_rewards_window")

					if cost[2] * (isTen and 10 or 1) <= xyd.models.backpack:getItemNumByID(cost[1]) then
						self.onPlay = true
						local msg = messages_pb:boss_buy_req()
						msg.activity_id = xyd.ActivityID.ACTIVITY_BOMB
						msg.num = isTen and 10 or 1

						xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)

						self.itemBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
						self.skipBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
						self.helpBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
						self.oneBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
						self.tenBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
					else
						xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
					end
				end
			})

			if not self.skip then
				self.spineModel:play("idle", 0)
			end

			self.itemBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			self.skipBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			self.helpBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			self.oneBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			self.tenBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			self.onPlay = false
		end

		if self.skip then
			func()
		else
			local item = event.data.items[1]
			local ids = xyd.tables.activityBombMakeTable:getIds()
			local fail = xyd.tables.activityBombMakeTable:getAward(ids[1])
			local success = xyd.tables.activityBombMakeTable:getAward(ids[#ids])

			if item.item_id == fail[1] and tonumber(item.item_num) == fail[2] * event.data.buy_times then
				self.spineModel:play("fail", 1, 1, function ()
					func()
				end)
			elseif item.item_id == success[1] and tonumber(item.item_num) == success[2] * event.data.buy_times then
				self.spineModel:play("surprise", 1, 1, function ()
					func()
				end)
			else
				self.spineModel:play("success", 1, 1, function ()
					func()
				end)
			end
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function (event)
		self.itemLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.FIREWORK_DUST)
	end)
end

function ActivityBombGachaWindow:willClose()
	ActivityBombGachaWindow.super.willClose(self)

	if self.skip then
		xyd.db.misc:setValue({
			value = "1",
			key = "bomb_skip"
		})
	else
		xyd.db.misc:setValue({
			value = "0",
			key = "bomb_skip"
		})
	end
end

return ActivityBombGachaWindow
