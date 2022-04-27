local BaseWindow = import(".BaseWindow")
local HeroChallengeTeamWindow = class("HeroChallengeTeamWindow", BaseWindow)
local PartnerCard = import("app.components.PartnerCard")
local HeroChallengeTeamItem = class("HeroChallengeTeamItem")

function HeroChallengeTeamItem:ctor(go, parent)
	self.go = go
	self.parent = parent
end

function HeroChallengeTeamItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info

	self:initItem()
end

function HeroChallengeTeamItem:initItem()
	NGUITools.DestroyChildren(self.go.transform)

	local hero = self.data.hero
	local params = {
		noClick = true,
		itemID = hero:getHeroTableID(),
		lev = hero:getLevel()
	}
	local info = {
		tableID = hero:getHeroTableID(),
		star = hero:getStar(),
		lev = hero:getLevel()
	}
	local icon = PartnerCard.new(self.go)

	icon:setInfo(info)
	icon:setDragScrollView(self.parent.scrollView)
	icon:setTouchListener(handler(self, self.onClick))
	icon.go.transform:SetLocalScale(0.93, 0.93, 1)
end

function HeroChallengeTeamItem:onClick()
	dump(self.data.hero)
	xyd.WindowManager.get():openWindow("partner_info", {
		notShowWays = true,
		partner = self.data.hero
	})
end

function HeroChallengeTeamItem:getGameObject()
	return self.go
end

function HeroChallengeTeamWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.showResetRedPoint_ = false
	self.skinName = "HeroChallengeTeamWindowSkin"
	self.fortId_ = params.fort_id
	self.showResetRedPoint_ = params.show_red_point
	self.showRedChess_ = params.show_red_chess
end

function HeroChallengeTeamWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()
	self:initList()
end

function HeroChallengeTeamWindow:getUIComponent()
	local trans = self.window_.transform
	self.content = trans:NodeByName("groupAction").gameObject
	self.labelTitle_ = self.content:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = self.content:NodeByName("closeBtn").gameObject
	self.btnReset = self.content:NodeByName("btnReset").gameObject
	self.btnResetLabel = self.btnReset:ComponentByName("button_label", typeof(UILabel))
	self.btnResetRedIcon = self.content:NodeByName("btnReset/redIcon").gameObject
	self.btnBuy = self.content:NodeByName("btnBuy").gameObject
	self.btnBuyLabel = self.btnBuy:ComponentByName("button_label", typeof(UILabel))
	self.btnBuyRedIcon = self.content:NodeByName("btnBuy/redIcon").gameObject
	self.btnExchange = self.content:NodeByName("btnExchange").gameObject
	self.btnExchangeLabel = self.btnExchange:ComponentByName("button_label", typeof(UILabel))
	self.btnExchangeRedIcon = self.content:NodeByName("btnExchange/redIcon").gameObject
	self.sanLabel_ = self.content:ComponentByName("sanLabel", typeof(UILabel))
	self.hpBar_ = self.content:ComponentByName("hpBar", typeof(UIProgressBar))
	self.hpBarLabel_ = self.content:ComponentByName("hpBar/label", typeof(UILabel))
	local scrollView = self.content:ComponentByName("e:Scroller", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("groupItems", typeof(MultiRowWrapContent))
	local cardContainer = scrollView:NodeByName("cardContainer").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent, cardContainer, HeroChallengeTeamItem, self)
end

function HeroChallengeTeamWindow:setLayout()
	self.labelTitle_.text = __("HERO_CHALLENGE_TEAM_TITLE")

	xyd.setBgColorType(self.btnReset, xyd.ButtonBgColorType.blue_btn_60_60)

	self.btnResetLabel.text = __("RESET")

	if xyd.tables.partnerChallengeChessTable:getFortType(self.fortId_) == xyd.HeroChallengeFort.CHESS then
		self.btnBuy:SetActive(true)
		self.btnExchange:SetActive(true)
		self.btnReset.transform:X(210)

		self.btnBuyLabel.text = __("CHESS_GET_PARTNER")
		self.btnExchangeLabel.text = __("CHESS_EXCHANGE")
		self.sanLabel_.text = __("CHESS_HPLABEL")

		self.sanLabel_.gameObject:SetActive(true)
		self.hpBar_.gameObject.transform:SetLocalScale(1, 1, 1)

		local hp = xyd.models.heroChallenge:getHp(self.fortId_)
		self.hprate_ = 100 / xyd.tables.miscTable:getVal("partner_challenge_chess_hp", "value")
		local hpnow = hp * self.hprate_

		if hp < 0 then
			self.hpBar_.value = 0
			self.hpBarLabel_.text = 0
		else
			self.hpBar_.value = hpnow / 100
			self.hpBarLabel_.text = hp
		end

		local cur = xyd.models.heroChallenge:getCurrentStage(self.fortId_)

		if cur == -1 then
			xyd.applyChildrenGrey(self.btnBuy)
			xyd.applyChildrenGrey(self.btnExchange)

			self.btnBuy:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.btnExchange:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		end
	else
		self.hpBar_.gameObject.transform:SetLocalScale(1, 0, 1)
	end

	self:updateRedPoint()
end

function HeroChallengeTeamWindow:initList()
	local data = {}
	local heros = xyd.models.heroChallenge:getHeros(self.fortId_)

	for _, hero in pairs(heros) do
		table.insert(data, {
			hero = hero,
			fortID = self.fortId_
		})
	end

	self.multiWrap_:setInfos(data, {})
end

function HeroChallengeTeamWindow:register()
	HeroChallengeTeamWindow.super.register(self)

	UIEventListener.Get(self.btnReset).onClick = function ()
		self:onResetTouch()
	end

	UIEventListener.Get(self.btnBuy).onClick = function ()
		self:onBuyTouch()
	end

	UIEventListener.Get(self.btnExchange).onClick = function ()
		self:onExchangeTouch()
	end
end

function HeroChallengeTeamWindow:onBuyTouch()
	local hpNow = xyd.models.heroChallenge:getHp(self.fortId_)

	if hpNow > 0 then
		if xyd.models.heroChallenge:getCurrentStage(self.fortId) ~= -1 then
			xyd.WindowManager.get():openWindow("hero_challenge_chess_get_partner_window", {
				fort_id = self.fortId_
			}, function ()
				xyd.WindowManager.get():closeWindow(self.name_)
			end)
		end
	else
		xyd.alertTips(__("CHESS_HP_NOT_ENOUGH"))
	end
end

function HeroChallengeTeamWindow:onExchangeTouch()
	local hpNow = xyd.models.heroChallenge:getHp(self.fortId_)

	if hpNow > 0 then
		if xyd.models.heroChallenge:getCurrentStage(self.fortId) ~= -1 then
			xyd.WindowManager.get():openWindow("hero_challenge_chess_exchange_window", {
				fort_id = self.fortId_
			}, function ()
				xyd.WindowManager.get():closeWindow(self.name_)
			end)
		else
			xyd.applyChildrenGrey(self.btnBuy)
			xyd.applyChildrenGrey(self.btnExchange)

			self.btnBuy:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.btnExchange:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		end
	else
		xyd.alertTips(__("CHESS_HP_NOT_ENOUGH"))
	end
end

function HeroChallengeTeamWindow:onResetTouch()
	local cost = xyd.tables.miscTable:split2Cost("challenge_reset_cost", "value", "#")

	if xyd.models.heroChallenge:getTicket() < cost[2] then
		xyd.alert(xyd.AlertType.TIPS, __("HERO_CHALLENGE_TIPS2", cost[2]))

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("HERO_CHALLENGE_TIPS3"), function (yes)
		if yes then
			if xyd.tables.partnerChallengeChessTable:getFortType(self.fortId_) == xyd.HeroChallengeFort.CHESS then
				xyd.models.heroChallenge:reqResetFortChess(self.fortId_)
			else
				xyd.models.heroChallenge:reqResetFort(self.fortId_)
			end

			xyd.closeWindow(self.name_)
		end
	end)
end

function HeroChallengeTeamWindow:updateRedPoint()
	if self.showRedChess_ and xyd.tables.partnerChallengeChessTable:getFortType(self.fortId_) == xyd.HeroChallengeFort.CHESS then
		local cur = xyd.models.heroChallenge:getCurrentStage(self.fortId_)

		if cur ~= -1 then
			self.btnBuyRedIcon:SetActive(true)
		end
	end

	if self.showResetRedPoint_ and not self.showRedChess_ then
		self.btnResetRedIcon:SetActive(true)
	end

	local wnd = xyd.WindowManager.get():getWindow("hero_challenge_detail_window")

	if wnd then
		wnd:setRedPoint(false)
	end
end

return HeroChallengeTeamWindow
