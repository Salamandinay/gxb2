local SoulLandMainWindow = class("SoulLandMainWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")

function SoulLandMainWindow:ctor(name, params)
	SoulLandMainWindow.super.ctor(self, name, params)
end

function SoulLandMainWindow:initWindow()
	self:getUIComponent()
	SoulLandMainWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
	xyd.models.soulLand:reqSummonBaseInfo()
	xyd.models.soulLand:reqShopBaseInfo()
	xyd.models.soulLand:reqCheckHangInfo()
end

function SoulLandMainWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.logoCon = self.groupAction:NodeByName("logoCon").gameObject
	self.logoImg = self.logoCon:ComponentByName("logoImg", typeof(UISprite))
	self.timeCon = self.logoCon:NodeByName("timeCon").gameObject
	self.timeConUILayout = self.logoCon:ComponentByName("timeCon", typeof(UILayout))
	self.timeDescLabel = self.timeCon:ComponentByName("timeDescLabel", typeof(UILabel))
	self.timeNumLabel = self.timeCon:ComponentByName("timeNumLabel", typeof(UILabel))
	self.passBtn = self.groupAction:NodeByName("passBtn").gameObject
	self.passBtnUISprite = self.groupAction:ComponentByName("passBtn", typeof(UISprite))
	self.passBtnLabel = self.passBtn:ComponentByName("passBtnLabel", typeof(UILabel))
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.fortCon = self.groupAction:NodeByName("fortCon").gameObject

	for i = 1, 3 do
		self["fort" .. i] = self.fortCon:NodeByName("fort" .. i).gameObject
		self["fortIcon" .. i] = self["fort" .. i]:ComponentByName("fortIcon", typeof(UISprite))
		self["fortLabelLayout" .. i] = self["fort" .. i]:ComponentByName("fortLabelLayout", typeof(UILayout))
		self["fortNameLabel" .. i] = self["fortLabelLayout" .. i]:ComponentByName("fortNameLabel", typeof(UILabel))
		self["fortNumLabel" .. i] = self["fortLabelLayout" .. i]:ComponentByName("fortNumLabel", typeof(UILabel))
		self["fortLabelBg" .. i] = self["fort" .. i]:ComponentByName("fortLabelBg", typeof(UISprite))
	end

	self.topUpBtnsCon = self.groupAction:NodeByName("topUpBtnsCon").gameObject
	self.helpBtn = self.topUpBtnsCon:NodeByName("helpBtn").gameObject
	self.rankBtn = self.topUpBtnsCon:NodeByName("rankBtn").gameObject
	self.dayCon = self.downCon:NodeByName("dayCon").gameObject
	self.dayConBg = self.dayCon:ComponentByName("dayConBg", typeof(UISprite))
	self.dayConLayout = self.dayCon:ComponentByName("dayConLayout", typeof(UILayout))
	self.dayConIcon = self.dayConLayout:ComponentByName("dayConIcon", typeof(UISprite))
	self.dayConNum = self.dayConLayout:ComponentByName("dayConNum", typeof(UILabel))
	self.iconCon = self.downCon:NodeByName("iconCon").gameObject
	self.iconBg = self.iconCon:ComponentByName("iconBg", typeof(UISprite))
	self.iconImg = self.iconCon:ComponentByName("iconImg", typeof(UISprite))
	self.iconNum = self.iconCon:ComponentByName("iconNum", typeof(UILabel))
	self.iconEffect = self.iconCon:ComponentByName("iconEffect", typeof(UITexture))
	self.collectionBtn = self.downCon:NodeByName("collectionBtn").gameObject
	self.collectionLabel = self.collectionBtn:ComponentByName("collectionLabel", typeof(UILabel))
	self.cardBtn = self.downCon:NodeByName("cardBtn").gameObject
	self.cardBtnNameImg = self.cardBtn:ComponentByName("cardBtnNameImg", typeof(UISprite))
	self.cardBtnRedPoint = self.cardBtn:NodeByName("cardBtnRedPoint").gameObject

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.SOUL_LAND_SUMMON_TEN
	}, self.cardBtnRedPoint)

	self.shopBtn = self.downCon:NodeByName("shopBtn").gameObject
	self.shopBtnNameImg = self.shopBtn:ComponentByName("shopBtnNameImg", typeof(UISprite))
	self.passBtnRedPoint = self.passBtn:NodeByName("passBtnRedPoint").gameObject

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.SOUL_LAND_BATTLE_PASS_GET
	}, self.passBtnRedPoint)
end

function SoulLandMainWindow:reSize()
	self:resizePosY(self.downCon, -421, -513)
	self:resizePosY(self.logoCon, 490, 546)
	self:resizePosY(self.topUpBtnsCon, 516, 611)
	self:resizePosY(self.passBtn, 507, 567)
end

function SoulLandMainWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.SOUL_LAND_FIGHT, handler(self, self.onSoulLandFightBack))
	self.eventProxy_:addEventListener(xyd.event.SOUL_LAND_HANG_INFO, handler(self, self.updateHangShow))
	self.eventProxy_:addEventListener(xyd.event.SOUL_LAND_GET_HANG_INFO, handler(self, self.updateHangShow))

	local fortArr = xyd.tables.soulLandTable:getFortArr()

	for i = 1, #fortArr do
		UIEventListener.Get(self["fortIcon" .. i].gameObject).onClick = handler(self, function ()
			xyd.models.soulLand:openFightWindow(i)
		end)
	end

	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SOUL_LAND_HELP"
		})
	end)
	UIEventListener.Get(self.collectionBtn.gameObject).onClick = handler(self, function ()
		local hangInfo = xyd.models.soulLand:getSoulLandHangInfo()

		if hangInfo and hangInfo.economy_items and hangInfo.economy_items[1].item_num then
			xyd.models.soulLand:reqGetAwardHangInfo()
		else
			xyd.alertTips(__("GALAXY_TRIP_TEXT67"))
		end
	end)
	UIEventListener.Get(self.cardBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("soul_land_summon_window", {})
	end)
	UIEventListener.Get(self.shopBtn.gameObject).onClick = handler(self, function ()
		local buyTimes = xyd.models.soulLand:getShopBaseInfo().buy_times

		xyd.WindowManager.get():openWindow("soul_land_shop_window", {
			buy_times = buyTimes
		})
	end)
	UIEventListener.Get(self.passBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("soul_land_battlepass_window", {})
	end)
	UIEventListener.Get(self.rankBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("rank_window", {
			mapType = xyd.MapType.SOUL_LAND
		})
	end)
end

function SoulLandMainWindow:layout()
	self.collectionLabel.text = __("SOUL_LAND_TEXT05")
	self.passBtnLabel.text = xyd.tables.activityTextTable:getTitle(xyd.ActivityID.SOUL_LAND_BATTLE_PASS)

	xyd.setUISpriteAsync(self.passBtnUISprite, nil, xyd.tables.activityTable:getIcon(xyd.ActivityID.SOUL_LAND_BATTLE_PASS), nil, , true)
	self:initTop()
	self:initTime()
	xyd.setUISpriteAsync(self.logoImg, nil, "soul_land_text_logo_" .. xyd.Global.lang)
	xyd.setUISpriteAsync(self.cardBtnNameImg, nil, "soul_land_text_jc_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.shopBtnNameImg, nil, "soul_land_text_sd_" .. xyd.Global.lang, nil, , true)

	local fortArr = xyd.tables.soulLandTable:getFortArr()

	for i = 1, #fortArr do
		local id = fortArr[i][1]
		local pos = xyd.tables.soulLandTable:getXy(id)
		local initPos = {
			0,
			0
		}

		if i == 1 then
			initPos = {
				-63,
				292
			}
		elseif i == 2 then
			initPos = {
				144,
				-11
			}
		elseif i == 3 then
			initPos = {
				-159,
				-125
			}
		end

		self["fort" .. i]:X(initPos[1] + pos[1])
		self["fort" .. i]:Y(initPos[2] + pos[2])

		local fortEnterImg = xyd.tables.soulLandTable:getFortImg(id)

		xyd.setUISpriteAsync(self["fortIcon" .. i], nil, fortEnterImg, nil, , true)
	end

	self:updateLevelShow()
	self:updateHangShow()
	self:initHangEffect()
end

function SoulLandMainWindow:initHangEffect()
	self.hangEffect = xyd.Spine.new(self.iconEffect.gameObject)

	self.hangEffect:setInfo("soul_land_award", function ()
		self.hangEffect:play("texiao01", 0, 0.7)
	end)
end

function SoulLandMainWindow:initTop()
	local resCost = xyd.tables.miscTable:split2num("soul_land_ticket_init", "value", "#")
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			id = resCost[1],
			callback = function ()
				self:onPurchaseTicket()
			end
		}
	}

	self.windowTop:setItem(items)
end

function SoulLandMainWindow:onPurchaseTicket()
	xyd.WindowManager.get():openWindow("item_purchase_window", {
		exchange_id = xyd.ExchangeItem._2TO421
	})
end

function SoulLandMainWindow:initTime()
	self.timeDescLabel.text = __("SOUL_LAND_TEXT01")
	local endTime = xyd.models.soulLand:getEndTime()
	local disTime = endTime - xyd.getServerTime()

	if disTime > 0 then
		self.time = import("app.components.CountDown").new(self.timeNumLabel)

		self.time:setInfo({
			duration = disTime,
			callback = function ()
				self.timeNumLabel.text = "00:00:00"

				self.timeConUILayout:Reposition()
			end
		})
	else
		self.timeNumLabel.text = "00:00:00"
	end

	self.timeConUILayout:Reposition()
end

function SoulLandMainWindow:updateLevelShow()
	local fortArr = xyd.tables.soulLandTable:getFortArr()
	local mapList = xyd.models.soulLand:getMapList()

	for i = 1, #fortArr do
		self["fortNameLabel" .. i].text = __("SOUL_LAND_TEXT03", mapList[i].max_stage, #fortArr[i])

		self["fortNumLabel" .. i]:SetActive(false)
	end
end

function SoulLandMainWindow:onSoulLandFightBack()
	self:updateLevelShow()
	self:updateHangShow()
end

function SoulLandMainWindow:updateHangShow()
	local mapList = xyd.models.soulLand:getMapList()
	local countPoint = 0

	for i in pairs(mapList) do
		countPoint = countPoint + tonumber(mapList[i].max_stage)
	end

	if countPoint > 0 then
		local showAwards = xyd.tables.soulLandAwardTable:getAwardsByPoint(countPoint)
		self.dayConNum.text = __("SOUL_LAND_TEXT04", showAwards[2])
	else
		self.dayConNum.text = __("SOUL_LAND_TEXT04", 0)
	end

	local hangInfo = xyd.models.soulLand:getSoulLandHangInfo()

	if hangInfo and hangInfo.economy_items and hangInfo.economy_items[1] then
		self.iconNum.text = hangInfo.economy_items[1].item_num
	else
		self.iconNum.text = 0
	end

	self.dayConLayout:Reposition()
end

return SoulLandMainWindow
