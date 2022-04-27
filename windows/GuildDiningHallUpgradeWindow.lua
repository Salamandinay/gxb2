local BaseWindow = import(".BaseWindow")
local GuildDiningHallUpgradeWindow = class("GuildDiningHallUpgradeWindow", BaseWindow)
local GuildDiningHallUpgradeWindowOrderItem = class("GuildDiningHallUpgradeWindowOrderItem")

function GuildDiningHallUpgradeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.orderList = xyd.models.guild:getDiningHallOrderList()
	self.curLev = #xyd.tables.guildOrderTable:getIDs()
	self.maxLev = self.curLev

	for _, order in pairs(self.orderList) do
		if order.order_lv + 1 < self.curLev and order.start_time == 0 then
			self.curLev = order.order_lv + 1
		end
	end

	self.minLev = self.curLev
	self.curLev = self.maxLev
	self.cost = {}

	for i = self.minLev, self.maxLev do
		if i == self.minLev then
			self.cost[i] = 0
		else
			self.cost[i] = self.cost[i - 1]
		end

		local upCost = xyd.tables.guildOrderTable:getUpCost(i - 1).num

		for _, order in pairs(self.orderList) do
			if order.order_lv < i and order.start_time == 0 then
				self.cost[i] = self.cost[i] + upCost
			end
		end
	end
end

function GuildDiningHallUpgradeWindow:initWindow()
	self:getUIComponent()
	GuildDiningHallUpgradeWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function GuildDiningHallUpgradeWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTip = groupAction:ComponentByName("labelTip", typeof(UILabel))
	self.scrollerView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.orderGroup = self.scrollerView:NodeByName("orderGroup").gameObject
	local arrow = groupAction:NodeByName("arrow").gameObject
	self.arrowLeft = arrow:NodeByName("arrowLeft").gameObject
	self.arrowRight = arrow:NodeByName("arrowRight").gameObject
	self.btnUpgrade = groupAction:NodeByName("btnUpgrade").gameObject
	self.btnUpgradeLabel = self.btnUpgrade:ComponentByName("button_label", typeof(UILabel))
	self.orderItem = winTrans:NodeByName("order_item").gameObject
end

function GuildDiningHallUpgradeWindow:initUIComponent()
	self.labelTitle.text = __("GUILD_MEAL_TEXT3")
	self.labelTip.text = __("GUILD_MEAL_TEXT4")

	for i = self.minLev, self.maxLev do
		local tmp = NGUITools.AddChild(self.orderGroup.gameObject, self.orderItem.gameObject)
		local item = GuildDiningHallUpgradeWindowOrderItem.new(tmp)

		item:setInfo({
			order_lv = i
		})
	end

	self.orderGroup:GetComponent(typeof(UILayout)):Reposition()
	self.scrollerView:ResetPosition()
	self.orderGroup.transform:X(-531 * (self.curLev - self.minLev))

	self.btnUpgradeLabel.text = tostring(self.cost[self.curLev])

	if self.curLev <= self.minLev then
		self.arrowLeft:SetActive(false)
	else
		self.arrowLeft:SetActive(true)
	end

	if self.maxLev <= self.curLev then
		self.arrowRight:SetActive(false)
	else
		self.arrowRight:SetActive(true)
	end
end

function GuildDiningHallUpgradeWindow:onClickArrow(direct)
	if self.isMoving then
		return
	end

	self.isMoving = true
	self.curLev = self.curLev + direct
	self.btnUpgradeLabel.text = tostring(self.cost[self.curLev])

	if self.curLev <= self.minLev then
		self.arrowLeft:SetActive(false)
	else
		self.arrowLeft:SetActive(true)
	end

	if self.maxLev <= self.curLev then
		self.arrowRight:SetActive(false)
	else
		self.arrowRight:SetActive(true)
	end

	local sequence = self:getSequence()

	sequence:Append(self.orderGroup.transform:DOLocalMoveX(-531 * (self.curLev - self.minLev), 0.4))
	sequence:AppendCallback(function ()
		sequence:Kill(false)

		sequence = nil
		self.isMoving = false
	end)
end

function GuildDiningHallUpgradeWindow:onClickUpgrade()
	local cost = self.cost[self.curLev]

	if xyd.isItemAbsence(xyd.ItemID.CRYSTAL, cost) then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_CRYSTAL"))

		return
	end

	local timeStamp = xyd.db.misc:getValue("guild_dining_hall_onekey_upgrade_time_stamp")

	if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
		xyd.WindowManager.get():openWindow("gamble_tips_window", {
			type = "guild_dining_hall_onekey_upgrade",
			text = __("GUILD_MEAL_TEXT5", cost),
			callback = function (yes)
				xyd.models.guild:reqDiningHallUpgradeAllOrder(self.curLev)

				local win = xyd.WindowManager.get():getWindow("guild_dininghall")

				if win then
					win:upgradeAllOrder(self.curLev)
				end

				self:close()
			end
		})
	else
		for _, order in pairs(self.orderList) do
			for i = order.order_lv, self.curLev - 1 do
				xyd.models.guild:reqDiningHallUpgradeOrder(order.order_id)
			end
		end

		local win = xyd.WindowManager.get():getWindow("guild_dininghall")

		if win then
			win:upgradeAllOrder(self.curLev)
		end

		self:close()
	end
end

function GuildDiningHallUpgradeWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.arrowLeft).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:onClickArrow(-1)
	end

	UIEventListener.Get(self.arrowRight).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:onClickArrow(1)
	end

	UIEventListener.Get(self.btnUpgrade).onClick = function ()
		self:onClickUpgrade()
	end
end

function GuildDiningHallUpgradeWindowOrderItem:ctor(go)
	self.go = go

	self:getUIComponent()

	self.starsItems = {}
end

function GuildDiningHallUpgradeWindowOrderItem:getUIComponent()
	self.timeInterval = self.go:ComponentByName("time/timeInterval", typeof(UILabel))
	self.timeLabel = self.go:ComponentByName("time/timeLabel", typeof(UILabel))
	self.clockEffect = self.go:NodeByName("clockEffect").gameObject
	self.imgClock = self.clockEffect:ComponentByName("imgClock", typeof(UISprite))
	self.imgFood = self.go:ComponentByName("imgFood", typeof(UISprite))
	self.starGroup = self.go:NodeByName("starGroup").gameObject
	self.awardGroup = self.go:NodeByName("awardGroup").gameObject
end

function GuildDiningHallUpgradeWindowOrderItem:setInfo(params)
	self.order_lv = params.order_lv
	local clockEffect = xyd.Spine.new(self.clockEffect)

	clockEffect:setInfo("fx_ui_shizhong", function ()
		clockEffect:setRenderTarget(self.imgClock, 1)
		clockEffect:play("texiao1", 0, 1)
	end)

	self.timeInterval.text = tostring(xyd.tables.guildOrderTable:getTime(self.order_lv) / 3600)
	self.timeLabel.text = __("HOUR")

	xyd.setUISprite(self.imgFood, nil, xyd.tables.guildOrderTable:getPic(self.order_lv))

	for i = 1, self.order_lv do
		if not self.starsItems[i] then
			local star = NGUITools.AddChild(self.starGroup, "star_" .. i)
			local sp = star:AddComponent(typeof(UISprite))

			xyd.setUISprite(sp, xyd.Atlas.COMMON_UI, "partner_star_yellow")
			sp:MakePixelPerfect()

			sp.depth = self.starGroup:GetComponent(typeof(UIWidget)).depth + 2
			self.starsItems[i] = star
		else
			self.starsItems[i]:SetActive(true)
		end
	end

	if self.order_lv < #self.starsItems then
		for j = self.order_lv, #self.starsItems do
			self.starsItems[j]:SetActive(false)
		end
	end

	self.starGroup:GetComponent(typeof(UILayout)):Reposition()
	NGUITools.DestroyChildren(self.awardGroup.transform)

	local awards = xyd.tables.guildOrderTable:getAwards(self.order_lv)
	local gInfo = xyd.models.guild.base_info
	local MillLev = xyd.tables.guildMillTable:getIdByGold(gInfo.gold)
	local factor = math.floor((xyd.tables.guildMillTable:getFactor(MillLev) or 10000) / 10000 * 10) / 10

	for i = 1, #awards do
		awards[i].num = awards[i].num * factor

		if awards[i].num > 10000 then
			awards[i].num = awards[i].num + 1
		end
	end

	for i = 1, #awards do
		local item = xyd.getItemIcon({
			noClickSelected = true,
			scale = 0.7037037037037037,
			uiRoot = self.awardGroup,
			itemID = awards[i].itemID,
			num = awards[i].num
		})
	end

	self.awardGroup:GetComponent(typeof(UILayout)):Reposition()
end

return GuildDiningHallUpgradeWindow
