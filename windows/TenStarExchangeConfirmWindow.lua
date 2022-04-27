local TenStarExchangeConfirmWindow = class("TenStarExchangeConfirmWindow", import(".BaseWindow"))
local HeroIcon = import("app.components.HeroIcon")

function TenStarExchangeConfirmWindow:ctor(name, params)
	TenStarExchangeConfirmWindow.super.ctor(self, name, params)

	self.callback_ = params.callback
	self.partnerID_ = params.partner_id or 0
	self.replaceID_ = params.replace_id or 0
end

function TenStarExchangeConfirmWindow:initWindow()
	TenStarExchangeConfirmWindow.super.initWindow(self)
	self:getComponent()
	self:layouUI()
	self:register()
end

function TenStarExchangeConfirmWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.heroLeftIconRoot_ = winTrans:NodeByName("heroLeftIcon").gameObject
	self.heroRightIconRoot_ = winTrans:NodeByName("heroRightIcon").gameObject
	self.titleLabel_ = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.btnNo_ = winTrans:NodeByName("btnNo").gameObject
	self.btnNoLabel_ = winTrans:ComponentByName("btnNo/label", typeof(UILabel))
	self.btnYes_ = winTrans:NodeByName("btnYes").gameObject
	self.btnYesLabel_ = winTrans:ComponentByName("btnYes/label", typeof(UILabel))
end

function TenStarExchangeConfirmWindow:register()
	TenStarExchangeConfirmWindow.super.register(self)

	UIEventListener.Get(self.btnNo_).onClick = function ()
		if self.callback_ then
			self.callback_(false)
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnYes_).onClick = function ()
		if self.callback_ then
			self.callback_(true)
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function TenStarExchangeConfirmWindow:layouUI()
	local partner = xyd.models.slot:getPartner(self.partnerID_)
	self.btnNoLabel_.text = __("NO")
	self.btnYesLabel_.text = __("YES")
	self.titleLabel_.text = __("EXCHANGE3")
	partner.noClick = true
	partner.isUnique = true
	self.heroLeftIcon_ = HeroIcon.new(self.heroLeftIconRoot_)

	self.heroLeftIcon_:setInfo(partner)

	local params = {
		noClick = true,
		isUnique = true,
		tableID = self.replaceID_,
		group = partner:getGroup(),
		lev = partner:getLevel(),
		star = partner:getStar()
	}
	self.heroRightIcon_ = HeroIcon.new(self.heroRightIconRoot_)

	self.heroRightIcon_:setInfo(params)

	UIEventListener.Get(self.heroLeftIconRoot_).onClick = function ()
		xyd.WindowManager.get():openWindow("partner_info", {
			table_id = partner:getTableID(),
			lev = partner:getLevel(),
			grade = partner:getStar()
		})
	end

	UIEventListener.Get(self.heroRightIconRoot_).onClick = function ()
		xyd.WindowManager.get():openWindow("partner_info", {
			table_id = self.replaceID_,
			lev = partner:getLevel(),
			grade = partner:getStar()
		})
	end
end

return TenStarExchangeConfirmWindow
