local ArcticPartnerFineDetailWindow = class("ArcticPartnerFineDetailWindow", import(".BaseWindow"))
local HeroIcon = import("app.components.HeroIcon")

function ArcticPartnerFineDetailWindow:ctor(name, params)
	ArcticPartnerFineDetailWindow.super.ctor(self, name, params)

	self.partnerID_ = params.partner_id
end

function ArcticPartnerFineDetailWindow:initWindow()
	self:getUIComponent()
	self:layout()
end

function ArcticPartnerFineDetailWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.partnerIconRoot_ = winTrans:NodeByName("playerIcon").gameObject
	self.partnerStateName_ = winTrans:ComponentByName("partnerStateName", typeof(UILabel))
	self.partnerStateDesc_ = winTrans:ComponentByName("partnerStateDesc", typeof(UILabel))
	self.tipsLabel_ = winTrans:ComponentByName("tipsLabel", typeof(UILabel))
	self.progressState_ = winTrans:ComponentByName("progressState", typeof(UIProgressBar))
	self.progressStateLbael_ = winTrans:ComponentByName("progressState/label", typeof(UILabel))
	self.fineLayout_ = winTrans:ComponentByName("fineLayout", typeof(UILayout))
	self.layoutWidget = winTrans:ComponentByName("fineLayout", typeof(UIWidget))
end

function ArcticPartnerFineDetailWindow:layout()
	local partnerInfo = xyd.models.slot:getPartner(self.partnerID_)
	self.heroIcon_ = HeroIcon.new(self.partnerIconRoot_)

	self.heroIcon_:setInfo(partnerInfo)
	self.heroIcon_:setScale(0.6944444444444444)
	self.heroIcon_:getPartExample("stateImg")

	local state = xyd.models.activity:getArcticPartnerState(self.partnerID_)
	local value = xyd.models.activity:getArcticPartnerValue(self.partnerID_)
	local maxValue = xyd.tables.miscTable:getVal("expedition_girls_labor", "value")

	self.heroIcon_:updateStateImg(state)

	self.partnerStateName_.text = xyd.tables.activityEptLaborText:getStateName(state)
	self.partnerStateDesc_.text = xyd.tables.activityEptLaborText:getBrief(state)
	self.tipsLabel_.text = __("ARCTIC_EXPEDITION_TEXT_18")
	self.progressState_.value = value / tonumber(maxValue)
	self.progressStateLbael_.text = value .. "/" .. maxValue
	local height = 0

	for i = 1, 4 do
		local newItem = self.fineLayout_:NodeByName("fineItem" .. i).gameObject
		local stateImg = newItem:ComponentByName("stateImg", typeof(UISprite))
		local descLabel = newItem:ComponentByName("descLabel", typeof(UILabel))
		descLabel.text = xyd.tables.activityEptLaborText:getDetailText(i)

		xyd.setUISpriteAsync(stateImg, nil, "expedition_partner_state_icon_small_" .. i)

		height = height + descLabel.height
	end

	self.fineLayout_:Reposition()
	self.window_:NodeByName("groupAction").transform:Y((180 + height) / 2)
end

return ArcticPartnerFineDetailWindow
