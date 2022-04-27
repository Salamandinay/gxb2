local BaseWindow = import(".BaseWindow")
local GuildShopWindow = class("GuildShopWindow", BaseWindow)
local CountDown = import("app.components.CountDown")

function GuildShopWindow:ctor(name, params)
	GuildShopWindow.super.ctor(self, name, params)
end

function GuildShopWindow:initWindow()
	self:getUIComponent()
	GuildShopWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_SHOP)
	self.guildLv = xyd.models.guild.saleLev
	self.giftbagID1 = xyd.tables.guildTraderTable:getMemberID(self.guildLv)
	self.giftbagID2 = xyd.tables.guildTraderTable:getGuildID(self.guildLv)

	self:layout()
	self:updataLimit()
	self:updateGiftBag()
	self:updateBubble()
	self:register()
end

function GuildShopWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.model = groupAction:NodeByName("model").gameObject
	self.textImg = groupAction:ComponentByName("textImg", typeof(UISprite))
	self.helpBtn = groupAction:NodeByName("helpBtn").gameObject
	self.touchField = groupAction:NodeByName("touchField").gameObject
	self.timeLabel = groupAction:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel = groupAction:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.bubble = groupAction:ComponentByName("bubble", typeof(UISprite))
	self.bubbleLabel = self.bubble:ComponentByName("label", typeof(UILabel))

	for i = 1, 3 do
		self["group" .. i] = groupAction:NodeByName("group" .. i).gameObject
		self["btn" .. i] = self["group" .. i]:NodeByName("btn").gameObject
		self["btnLabel" .. i] = self["btn" .. i]:ComponentByName("label", typeof(UILabel))
	end

	self.iconGroup = self.group1:NodeByName("iconGroup").gameObject
	self.limitLabel1 = self.group1:ComponentByName("label", typeof(UILabel))

	for i = 2, 3 do
		self["label" .. i .. "1"] = self["group" .. i]:ComponentByName("label1", typeof(UILabel))
		self["label" .. i .. "2"] = self["group" .. i]:ComponentByName("label2", typeof(UILabel))
		self["label" .. i .. "3"] = self["group" .. i]:ComponentByName("label3", typeof(UILabel))
		self["iconGroup" .. i .. "1"] = self["group" .. i]:NodeByName("iconGroup1").gameObject
		self["iconGroup" .. i .. "2"] = self["group" .. i]:NodeByName("iconGroup2").gameObject
		self["expGroup" .. i] = self["group" .. i]:NodeByName("expGroup").gameObject
		self["guildExpLabel" .. i] = self["expGroup" .. i]:ComponentByName("label", typeof(UILabel))
		self["expLabel" .. i] = self["group" .. i]:ComponentByName("expLabel", typeof(UILabel))
	end

	self["label" .. 3 .. "4"] = self["group" .. 3]:ComponentByName("label4", typeof(UILabel))
end

function GuildShopWindow:layout()
	xyd.setUISpriteAsync(self.textImg, nil, "guild_shop_" .. xyd.Global.lang)

	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.endLabel.text = __("END_TEXT")
	self.label22.text = __("GUILD_ROAM_TEXT10")
	self.label32.text = __("GUILD_ROAM_TEXT10")
	self.label23.text = __("GUILD_ROAM_TEXT11")
	self.label33.text = __("GUILD_ROAM_TEXT11")
	local node = xyd.Spine.new(self.model)

	node:SetLocalScale(1, 1, 1)
	node:setInfo("banila_pifu04_lihui01", function ()
		node:play("animation", 0, 1)
	end, false)
end

function GuildShopWindow:updataLimit()
	local limit1 = 1 - self.activityData.detail.free_charge.awarded
	local limit2 = xyd.tables.miscTable:split2num("guild_shop_buy_limit", "value", "|")[1] - self.activityData.detail.self_buy_times
	local limit3 = xyd.tables.miscTable:split2num("guild_shop_buy_limit", "value", "|")[2] - self.activityData.detail.share_buy_times
	local limit4 = xyd.tables.miscTable:split2num("guild_shop_buy_limit", "value", "|")[3] - xyd.models.guild.giftbagTimes
	self.limitLabel1.text = __("GUILD_ROAM_TEXT07") .. limit1
	self.label21.text = __("GUILD_ROAM_TEXT08") .. limit2
	self.label31.text = __("GUILD_ROAM_TEXT08") .. limit3
	self.label34.text = __("GUILD_ROAM_TEXT09") .. limit4

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
		self.label21.fontSize = 18
		self.label31.fontSize = 18
		self.label23.fontSize = 16
		self.label33.fontSize = 16
		self.label34.fontSize = 18
	end

	if limit1 <= 0 then
		xyd.applyChildrenGrey(self.btn1)
		xyd.setUISpriteAsync(self.btn1:GetComponent(typeof(UISprite)), nil, "benefit_giftbag_btn2")

		self.btn1:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end

	if limit2 <= 0 then
		xyd.applyChildrenGrey(self.btn2)

		self.btn2:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end

	if limit3 <= 0 or limit4 <= 0 then
		xyd.applyChildrenGrey(self.btn3)

		self.btn3:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end

	self.guildExpLabel2.text = xyd.tables.guildTraderTable:getMemberExp(self.guildLv)
	self.guildExpLabel3.text = xyd.tables.guildTraderTable:getGuildExp(self.guildLv)
end

function GuildShopWindow:updateGiftBag()
	self.expLabel2.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftbagID1) .. " VIP EXP"
	self.expLabel3.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftbagID2) .. " VIP EXP"
	self.btnLabel1.text = __("MIDAS_TEXT03")
	self.btnLabel2.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftbagID1)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftbagID1))
	self.btnLabel3.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftbagID2)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftbagID2))

	self:updateItems()
end

function GuildShopWindow:updateItems()
	local award1 = xyd.tables.guildTraderTable:getFreeAward(self.guildLv)
	local award21 = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.giftbagID1))
	local award31 = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.giftbagID2))
	local award22 = xyd.tables.guildTraderTable:getMemberAward(self.guildLv)
	local award32 = xyd.tables.guildTraderTable:getGuildAward(self.guildLv)

	NGUITools.DestroyChildren(self.iconGroup.transform)

	for i = 1, #award1 do
		if award1[i][1] ~= xyd.ItemID.GUILD_EXP and award1[i][1] ~= xyd.ItemID.VIP_EXP then
			local icon1 = xyd.getItemIcon({
				show_has_num = true,
				itemID = award1[i][1],
				num = award1[i][2],
				uiRoot = self.iconGroup,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				scale = Vector3(0.65, 0.65, 1)
			})
		end
	end

	self.iconGroup:GetComponent(typeof(UILayout)):Reposition()
	NGUITools.DestroyChildren(self.iconGroup21.transform)

	for i = 1, #award21 do
		if award21[i][1] ~= xyd.ItemID.GUILD_EXP and award21[i][1] ~= xyd.ItemID.VIP_EXP then
			local icon21 = xyd.getItemIcon({
				show_has_num = true,
				itemID = award21[i][1],
				num = award21[i][2],
				uiRoot = self.iconGroup21,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				scale = Vector3(0.65, 0.65, 1)
			})
		end
	end

	self.iconGroup21:GetComponent(typeof(UILayout)):Reposition()
	NGUITools.DestroyChildren(self.iconGroup31.transform)

	for i = 1, #award31 do
		if award31[i][1] ~= xyd.ItemID.GUILD_EXP and award31[i][1] ~= xyd.ItemID.VIP_EXP then
			local icon31 = xyd.getItemIcon({
				show_has_num = true,
				itemID = award31[i][1],
				num = award31[i][2],
				uiRoot = self.iconGroup31,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				scale = Vector3(0.65, 0.65, 1)
			})
		end
	end

	self.iconGroup31:GetComponent(typeof(UILayout)):Reposition()
	NGUITools.DestroyChildren(self.iconGroup22.transform)

	for i = 1, #award22 do
		if award22[i][1] ~= xyd.ItemID.GUILD_EXP and award22[i][1] ~= xyd.ItemID.VIP_EXP then
			local icon22 = xyd.getItemIcon({
				show_has_num = true,
				itemID = award22[i][1],
				num = award22[i][2],
				uiRoot = self.iconGroup22,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				scale = Vector3(0.65, 0.65, 1)
			})
		end
	end

	self.iconGroup22:GetComponent(typeof(UILayout)):Reposition()
	NGUITools.DestroyChildren(self.iconGroup32.transform)

	for i = 1, #award32 do
		if award32[i][1] ~= xyd.ItemID.GUILD_EXP and award32[i][1] ~= xyd.ItemID.VIP_EXP then
			local icon32 = xyd.getItemIcon({
				show_has_num = true,
				itemID = award32[i][1],
				num = award32[i][2],
				uiRoot = self.iconGroup32,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				scale = Vector3(0.65, 0.65, 1)
			})
		end
	end

	self.iconGroup32:GetComponent(typeof(UILayout)):Reposition()
end

function GuildShopWindow:updateBubble()
	if next(self.waitForTimeKeys_) then
		for i = 1, #self.waitForTimeKeys_ do
			if self.waitForTimeKeys_[i] == "guild_shop_bubble" then
				table.remove(self.waitForTimeKeys_, i)
				XYDCo.StopWait("guild_shop_bubble")
			end
		end
	end

	self.bubbleLabel.text = __("GUILD_ROAM_TEXT0" .. math.random(4))
	self.bubble.height = self.bubbleLabel.height + 50

	if self.sequence then
		self:delSequene(self.sequence)
	end

	self.sequence = self:getSequence()
	local w = self.bubble:GetComponent(typeof(UIWidget))
	local getter, setter = xyd.getTweenAlphaGeterSeter(w)

	self.sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0))
	self.sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.5))
	self.sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 5))
	self.sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0.5))
	self.sequence:AppendCallback(function ()
		self:waitForTime(9, function ()
			self:updateBubble()
		end, "guild_shop_bubble")
	end)
end

function GuildShopWindow:register()
	GuildShopWindow.super.register(self)

	UIEventListener.Get(self.touchField).onClick = handler(self, function ()
		self:updateBubble()
	end)
	UIEventListener.Get(self.btn1).onClick = handler(self, function ()
		if xyd.isSameDay(self.activityData.detail.change_guild_time, xyd.getServerTime()) then
			xyd.showToast(__("GUILD_ROAM_TEXT05"))

			return
		end

		local msg = messages_pb.daily_giftbag_free_req()
		msg.activity_id = xyd.ActivityID.GUILD_SHOP

		xyd.Backend.get():request(xyd.mid.DAILY_GIFTBAG_FREE, msg)
	end)
	UIEventListener.Get(self.btn2).onClick = handler(self, function ()
		local limit2 = xyd.tables.miscTable:split2num("guild_shop_buy_limit", "value", "|")[1] - self.activityData.detail.self_buy_times

		if limit2 <= 0 then
			xyd.showToast(__("GUILD_ROAM_TEXT06"))
		else
			self.buyIndex = 2

			xyd.SdkManager.get():showPayment(self.giftbagID1)
		end
	end)
	UIEventListener.Get(self.btn3).onClick = handler(self, function ()
		if xyd.isSameDay(self.activityData.detail.change_guild_time, xyd.getServerTime()) then
			xyd.showToast(__("GUILD_ROAM_TEXT05"))

			return
		end

		self.buyIndex = 3
		local msg = messages_pb:guild_get_info_req()

		xyd.Backend.get():request(xyd.mid.GUILD_GET_INFO, msg)
	end)
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.openWindow("help_window", {
			key = "GUILD_ROAM_HELP"
		})
	end)

	self.eventProxy_:addEventListener(xyd.event.GUILD_GET_INFO, function ()
		self.guildLv = xyd.models.guild.saleLev
		self.giftbagID1 = xyd.tables.guildTraderTable:getMemberID(self.guildLv)
		self.giftbagID2 = xyd.tables.guildTraderTable:getGuildID(self.guildLv)

		if self.buyIndex == 3 then
			local limit3 = xyd.tables.miscTable:split2num("guild_shop_buy_limit", "value", "|")[2] - self.activityData.detail.share_buy_times
			local limit4 = xyd.tables.miscTable:split2num("guild_shop_buy_limit", "value", "|")[3] - xyd.models.guild.giftbagTimes

			if limit3 <= 0 or limit4 <= 0 then
				xyd.showToast(__("GUILD_ROAM_TEXT06"))
			else
				xyd.SdkManager.get():showPayment(self.giftbagID2)
			end
		elseif self.buyIndex == nil then
			self:updataLimit()
			self:updateGiftBag()
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, function (event)
		if self.buyIndex == 2 then
			self.activityData.detail.self_buy_times = self.activityData.detail.self_buy_times + 1
			xyd.models.activity:getActivity(xyd.ActivityID.GUILD_SHOP).detail.self_buy_times = self.activityData.detail.self_buy_times
		elseif self.buyIndex == 3 then
			self.activityData.detail.share_buy_times = self.activityData.detail.share_buy_times + 1
			xyd.models.activity:getActivity(xyd.ActivityID.GUILD_SHOP).detail.share_buy_times = self.activityData.detail.share_buy_times
		end

		self.buyIndex = nil
		local msg = messages_pb:guild_get_info_req()

		xyd.Backend.get():request(xyd.mid.GUILD_GET_INFO, msg)
	end)
	self.eventProxy_:addEventListener(xyd.event.DAILY_GIFTBAG_FREE, function (event)
		xyd.models.itemFloatModel:pushNewItems(event.data.items)

		self.activityData.detail.free_charge.awarded = self.activityData.detail.free_charge.awarded + 1
		xyd.models.activity:getActivity(xyd.ActivityID.GUILD_SHOP).detail.free_charge.awarded = self.activityData.detail.free_charge.awarded

		self:updataLimit()
	end)
end

function GuildShopWindow:playCloseAnimation(callback)
	self:waitForTime(0.1, function ()
		self.model:SetActive(false)
	end)
	GuildShopWindow.super.playCloseAnimation(self, callback)
end

return GuildShopWindow
