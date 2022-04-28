local BaseWindow = import(".BaseWindow")
local BattlePassBuyWindow = class("BattlePassBuyWindow", BaseWindow)

function BattlePassBuyWindow:ctor(name, params)
	BattlePassBuyWindow.super.ctor(self, name, params)

	self.showType = params.showType
	self.sound = {}
	self.awardListTop_ = {}
	self.awardListDown_ = {}
	self.gitBigs = {
		106,
		107,
		108
	}

	if xyd.models.activity:getBattlePassId() == xyd.ActivityID.BATTLE_PASS_2 then
		self.gitBigs = {
			121,
			122,
			123
		}
	end

	local needLoadRes = xyd.getEffectFilesByNames({
		"fx_ui_bp_purchase_trans",
		"fx_ui_battlepass_blackgold",
		"fx_ui_battlepass_silver"
	})

	self:setResourcePaths(needLoadRes)
end

function BattlePassBuyWindow:playOpenAnimation(callback)
	BattlePassBuyWindow.super.playOpenAnimation(self, function ()
		if self.effect ~= nil then
			self.effect:destroy()
		end

		self.effect = xyd.Spine.new(self.effectBgGroup_.gameObject)
		local effect2 = "fx_bp_gold"
		local effect1 = "fx_bp_silver"

		self.bottomGroup_:SetLocalPosition(860, -204, 0)
		self.topGroup_:SetLocalPosition(-860, 230, 0)
		self.lastTimeBg_:SetLocalPosition(-1101, 495, 0)
		self.bottomGroup_:SetActive(true)
		self.topGroup_:SetActive(true)
		self.clickTip_:SetActive(true)

		self.actionTweenTop = self:getSequence()

		self.actionTweenTop:Append(self.topGroup_.transform:DOLocalMoveX(0, 0.3))
		self.actionTweenTop:Insert(0, self.lastTimeBg_.transform:DOLocalMoveX(-250, 0.3))
		self.actionTweenTop:AppendCallback(function ()
			self.actionTweenTop:Kill(true)
		end)

		self.actionTweenBottom = self:getSequence()

		self.actionTweenBottom:Append(self.bottomGroup_.transform:DOLocalMoveX(0, 0.3))
		self.actionTweenBottom:AppendCallback(function ()
			self.actionTweenBottom:Kill(true)
		end)

		self.effect1 = xyd.Spine.new(self.groupEffectBottom_.gameObject)

		self.effect1:setInfo(effect2, function ()
			if self.effect1 == nil or tolua.isnull(self.window_) then
				return
			end

			self.effect1:setRenderTarget(self.groupEffectBottom_:GetComponent(typeof(UITexture)), 2)
			self.effect1:SetLocalScale(0.6, 0.6, 0.6)
			self.effect1:SetLocalPosition(40, -270, 0)
			self.effect1:play("texiao01", 0)
		end)

		if self.effect2 ~= nil then
			self.effect2:destroy()
		end

		self.effect2 = xyd.Spine.new(self.groupEffectTop_.gameObject)

		self.effect2:setInfo(effect1, function ()
			if self.effect2 == nil or tolua.isnull(self.window_) then
				return
			end

			self.effect2:setRenderTarget(self.groupEffectTop_:GetComponent(typeof(UITexture)), 2)
			self.effect2:SetLocalScale(0.6, 0.6, 0.6)
			self.effect2:SetLocalPosition(-10, -235, 0)
			self.effect2:play("texiao01", 0)
		end)
	end)
end

function BattlePassBuyWindow:initWindow()
	BattlePassBuyWindow.super.initWindow(self)

	local goTrans = self.window_:NodeByName("groupAction")
	self.effectGroup_ = goTrans:NodeByName("effectGroup").gameObject
	self.effectBgGroup_ = goTrans:NodeByName("effectGroup/effectBgGroup")
	self.clickTip_ = goTrans:ComponentByName("clickTip", typeof(UILabel))
	self.closeGroup_ = goTrans:NodeByName("effectGroup").gameObject
	self.topGroup_ = goTrans:NodeByName("topNode")
	self.helpBtn_ = self.topGroup_:ComponentByName("helpBtn", typeof(UISprite))
	self.titleImgTop_ = self.topGroup_:ComponentByName("titleImg", typeof(UISprite))
	self.groupEffectTop_ = self.topGroup_:NodeByName("groupEffect").gameObject
	self.vipLabelTop_ = self.topGroup_:ComponentByName("vipLabel", typeof(UILabel))
	self.buyBtnTop_ = self.topGroup_:NodeByName("buyBtn").gameObject
	self.mask1_ = self.buyBtnTop_:NodeByName("mask").gameObject
	self.buyBtnLabelTop_ = self.topGroup_:ComponentByName("buyBtn/label", typeof(UILabel))
	self.bottomGroup_ = goTrans:NodeByName("bottomNode")
	self.titleImgBottom_ = self.bottomGroup_:ComponentByName("titleImg", typeof(UISprite))
	self.groupEffectBottom_ = self.bottomGroup_:NodeByName("groupEffect").gameObject
	self.vipLabelBottom_ = self.bottomGroup_:ComponentByName("vipLabel2", typeof(UILabel))
	self.buyBtnBottom_ = self.bottomGroup_:NodeByName("buyBtn2").gameObject
	self.mask2_ = self.buyBtnBottom_:NodeByName("mask").gameObject
	self.labelShow_ = self.bottomGroup_:ComponentByName("buyBtn2/labelShow", typeof(UILabel))
	self.labelBefore_ = self.bottomGroup_:ComponentByName("buyBtn2/labelBefore", typeof(UILabel))
	self.itemGroup = self.bottomGroup_:NodeByName("itemGroup").gameObject
	self.awardTipWords_ = self.bottomGroup_:ComponentByName("awardTipWords", typeof(UILabel))
	self.desBottomLabel1 = self.bottomGroup_:ComponentByName("desGroup/labelGroup/desBottomLabel1", typeof(UILabel))
	self.desBottomLabel2 = self.bottomGroup_:ComponentByName("desGroup/labelGroup/desBottomLabel2", typeof(UILabel))
	self.desTopLabel1 = self.topGroup_:ComponentByName("desGroup/labelGroup/desTopLabel1", typeof(UILabel))
	self.desTopLabel2 = self.topGroup_:ComponentByName("desGroup/labelGroup/desTopLabel2", typeof(UILabel))
	self.lastTimeBg_ = goTrans:NodeByName("lastTimeBg").gameObject
	self.lastTimeLabel_ = goTrans:ComponentByName("lastTimeBg/timeLimitLabel", typeof(UILabel))

	self:layout()
	self:register()
	self.bottomGroup_:SetActive(false)
	self.topGroup_:SetActive(false)
	self.clickTip_:SetActive(false)
	self.lastTimeBg_:SetActive(false)
	self.effectBgGroup_:SetActive(false)

	if xyd.Global.lang == "de_de" then
		self.clickTip_.fontSize = 18
	end

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "en_en" then
		self.clickTip_.transform:Y(self.clickTip_.transform.localPosition.y + 45)
		goTrans:Y(80)
		self.effectGroup_.transform:Y(-54)
	elseif xyd.Global.lang == "fr_fr" then
		self.clickTip_.transform:Y(self.clickTip_.transform.localPosition.y + 35)
		goTrans:Y(70)
		self.effectGroup_.transform:Y(-44)
	elseif xyd.Global.lang == "ja_jp" then
		self.clickTip_.transform:Y(self.clickTip_.transform.localPosition.y + 32)
	end
end

function BattlePassBuyWindow:register()
	BattlePassBuyWindow.super.register(self)

	UIEventListener.Get(self.closeGroup_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.helpBtn_.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "BP_PURCHASE_HELP"
		})
	end

	UIEventListener.Get(self.buyBtnTop_.gameObject).onClick = function ()
		if self.showType == "noGift" then
			xyd.SdkManager.get():showPayment(self.gitBigs[1])
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.buyBtnBottom_.gameObject).onClick = function ()
		if self.showType == "noGift" then
			xyd.SdkManager.get():showPayment(self.gitBigs[3])
		elseif self.showType == "buyOne" then
			xyd.SdkManager.get():showPayment(self.gitBigs[2])
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onCharge))
end

function BattlePassBuyWindow:onCharge()
	xyd.WindowManager.get():closeWindow(self.name_)
end

function BattlePassBuyWindow:layout()
	self.clickTip_.text = xyd.replaceSpace(__("BP_PURCHASE_WINDOW_TIP"))

	xyd.setUISpriteAsync(self.titleImgTop_, nil, "bp_buy_logo_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.titleImgBottom_, nil, "bp_buy_logo2_" .. xyd.Global.lang, nil, , true)

	self.awardTipWords_.text = __("BP_INSTANT_REWARD")
	self.desBottomLabel1.text = __("BP_PURCHASE_JPTIPS1")
	self.desBottomLabel2.text = __("BP_PURCHASE_JPTIPS2")
	self.desTopLabel1.text = __("BP_PURCHASE_JPTIPS1")
	self.desTopLabel2.text = __("BP_PURCHASE_JPTIPS2")

	self.awardTipWords_:Y(15)

	if xyd.Global.lang == "en_en" then
		self.desBottomLabel1:SetActive(false)
		self.desBottomLabel2:X(-80)
		self.desTopLabel1:SetActive(false)
		self.desTopLabel2:X(-80)
	elseif xyd.Global.lang == "fr_fr" then
		self.desBottomLabel1:X(-150)

		self.desBottomLabel1.fontSize = 20
		self.desBottomLabel2.fontSize = 16
		self.desTopLabel1.fontSize = 20
		self.desTopLabel2.fontSize = 16

		self.desBottomLabel2:X(-25)
		self.desTopLabel1:X(-120)
		self.desTopLabel2:X(0)
	elseif xyd.Global.lang == "de_de" then
		self.desBottomLabel1:X(-145)
		self.desBottomLabel2:X(-30)

		self.desBottomLabel1.fontSize = 20
		self.desBottomLabel2.fontSize = 16

		self.desTopLabel1:X(-145)
		self.desTopLabel2:X(-30)

		self.desTopLabel1.fontSize = 20
		self.desTopLabel2.fontSize = 16
	end

	self:updateLayout()
	self:checkLastTime()
end

function BattlePassBuyWindow:checkLastTime()
	local activityId = xyd.models.activity:getBattlePassId()
	self.activityData = xyd.models.activity:getActivity(activityId)
	local endTime = self.activityData:getEndTime()
	local lastTimeList = xyd.tables.miscTable:split2num("battle_pass_time", "value", "|")

	if xyd.DAY < endTime - xyd.getServerTime() and endTime - xyd.getServerTime() <= xyd.DAY * lastTimeList[1] then
		local day = math.floor((endTime - xyd.getServerTime()) / xyd.DAY)

		self.lastTimeBg_:SetActive(true)

		self.lastTimeLabel_.text = __("BP_BUY_LAST_DAY", day)
	elseif endTime - xyd.getServerTime() <= xyd.DAY then
		local leftHour = math.floor((endTime - xyd.getServerTime()) % xyd.DAY / xyd.HOUR)

		self.lastTimeBg_:SetActive(true)

		self.lastTimeLabel_.text = __("BP_BUY_LAST_HOUR", leftHour)
	end
end

function BattlePassBuyWindow:updateLayout()
	local battlePassTable = xyd.models.activity:getBattlePassTable(xyd.BATTLE_PASS_TABLE.MAIN)
	local awards2 = battlePassTable:getCoreAward(3)
	local scales = {
		0.65,
		0.7962962962962963
	}

	for i = 1, 2 do
		local ItemIconSpecil = nil
		local iconItem = xyd.getItemIcon({
			itemID = awards2[i][1],
			num = awards2[i][2],
			scale = scales[i],
			itemIconSpecil = ItemIconSpecil,
			uiRoot = self.itemGroup
		})
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

	self.buyBtnLabelTop_.text = xyd.tables.giftBagTextTable:getCurrency(106) .. "" .. xyd.tables.giftBagTextTable:getCharge(106)
	local secondGiftId = nil
	local switch = {
		noGift = function ()
			secondGiftId = self.gitBigs[3]
		end,
		buyAll = function ()
			secondGiftId = self.gitBigs[2]

			xyd.applyGrey(self.buyBtnBottom_:GetComponent(typeof(UISprite)))
			xyd.applyGrey(self.buyBtnTop_:GetComponent(typeof(UISprite)))
			self.mask1_:SetActive(true)
			self.mask2_:SetActive(true)
		end,
		buyOne = function ()
			secondGiftId = self.gitBigs[2]

			xyd.applyGrey(self.buyBtnTop_:GetComponent(typeof(UISprite)))
			self.mask1_:SetActive(true)
			self.mask2_:SetActive(false)
		end,
		buyTop = function ()
			secondGiftId = self.gitBigs[3]

			xyd.applyGrey(self.buyBtnBottom_:GetComponent(typeof(UISprite)))
			xyd.applyGrey(self.buyBtnTop_:GetComponent(typeof(UISprite)))
			self.mask1_:SetActive(true)
			self.mask2_:SetActive(true)
		end
	}

	switch[self.showType]()

	self.vipLabelTop_.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(self.gitBigs[1])) .. "VIP EXP"
	self.vipLabelBottom_.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(secondGiftId)) .. "VIP EXP"
	self.labelShow_.text = xyd.tables.giftBagTextTable:getCurrency(secondGiftId) .. " " .. xyd.tables.giftBagTextTable:getCharge(secondGiftId)
	self.labelBefore_.text = __("BP_GOLD_PRICE")
end

function BattlePassBuyWindow:excuteCallBack()
	BattlePassBuyWindow.super.excuteCallBack(self)
end

function BattlePassBuyWindow:willClose()
	BattlePassBuyWindow.super.willClose(self)

	if self.effect then
		self.effect:setToSetupPose()
		self.effect:destroy()
	end

	if self.effect1 then
		self.effect1:setToSetupPose()
		self.effect1:destroy()
	end

	if self.effect2 then
		self.effect2:setToSetupPose()
		self.effect2:destroy()
	end
end

return BattlePassBuyWindow
