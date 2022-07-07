local ActivityContent = import(".ActivityContent")
local ActivityTripleFirstCharge = class("ActivityTripleFirstCharge", ActivityContent)
local CountDown = import("app.components.CountDown")

function ActivityTripleFirstCharge:ctor(parentGo, params, parent)
	ActivityTripleFirstCharge.super.ctor(self, parentGo, params, parent)
end

function ActivityTripleFirstCharge:getPrefabPath()
	return "Prefabs/Windows/activity/activity_triple_first_charge"
end

function ActivityTripleFirstCharge:initUI()
	self:getUIComponent()
	ActivityTripleFirstCharge.super.initUI(self)
	self:layout()
	self:register()
end

function ActivityTripleFirstCharge:getUIComponent()
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:NodeByName("bg").gameObject
	self.logoStrImg = self.groupAction:ComponentByName("logoStrImg", typeof(UITexture))
	self.timeGroup = self.groupAction:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.timeWords = self.timeGroup:ComponentByName("timeWords", typeof(UILabel))
	self.bottomNode = self.groupAction:NodeByName("bottomNode").gameObject
	self.chargeBtn = self.bottomNode:NodeByName("chargeBtn").gameObject
	self.buttonWords = self.chargeBtn:ComponentByName("buttonWords", typeof(UILabel))
	self.desWords1 = self.bottomNode:ComponentByName("desWords1", typeof(UILabel))
	self.desWords2 = self.bottomNode:ComponentByName("desWords2", typeof(UILabel))
end

function ActivityTripleFirstCharge:layout()
	self.timeWords.text = __("END")
	self.buttonWords.text = __("GOTO_RECHARGE")
	self.desWords1.text = __("ACTIVITY_TRIPLE_FIRST_RECHARGE_DESC")
	self.desWords2.text = __("ACTIVITY_TRIPLE_FIRST_RECHARGE_TIPS")

	CountDown.new(self.timeLabel, {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	})
	xyd.setUITextureAsync(self.logoStrImg, "Textures/activity_text_web/activity_triple_first_charge_logo_" .. xyd.Global.lang)

	if xyd.Global.lang == "fr_fr" then
		self.timeWords.transform:SetSiblingIndex(0)
	end
end

function ActivityTripleFirstCharge:register()
	UIEventListener.Get(self.chargeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("vip_window")
	end)
end

function ActivityTripleFirstCharge:resizeToParent()
	ActivityTripleFirstCharge.super.resizeToParent(self)
	self:resizePosY(self.logoStrImg, -120, -165)
	self:resizePosY(self.timeGroup, -207, -255)
	self:resizePosY(self.bottomNode, -602, -680)
end

return ActivityTripleFirstCharge
