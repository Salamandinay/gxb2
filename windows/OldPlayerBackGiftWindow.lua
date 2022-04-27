local BaseWindow = import(".BaseWindow")
local OldPlayerBackGiftWindow = class("OldPlayerBackGiftWindow", BaseWindow)

function OldPlayerBackGiftWindow:ctor(name, params)
	OldPlayerBackGiftWindow.super.ctor(self, name, params)

	self.skinName = "OldPlayerBackGiftWindowSkin"
	self.currentState = xyd.Global.lang
end

function OldPlayerBackGiftWindow:initWindow()
	OldPlayerBackGiftWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function OldPlayerBackGiftWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.btnAward_ = self.groupAction:NodeByName("btnAward_").gameObject
	self.button_label = self.btnAward_:ComponentByName("button_label", typeof(UILabel))
	self.label1 = self.groupAction:ComponentByName("label1", typeof(UILabel))
	self.label2 = self.groupAction:ComponentByName("label2", typeof(UILabel))
end

function OldPlayerBackGiftWindow:layout()
	local lastLoginTime = xyd.models.selfPlayer:getLastLoginTime()
	local deltaDay = math.floor((xyd.getServerTime() - lastLoginTime) / 86400)
	self.label1.text = __("OLD_PLAYER_BACK_TEXT01", xyd.Global.playerName)
	self.label2.text = __("OLD_PLAYER_BACK_TEXT02", deltaDay)
	self.button_label.text = __("OLD_PLAYER_BACK_TEXT03")
end

function OldPlayerBackGiftWindow:registerEvent()
	UIEventListener.Get(self.btnAward_).onClick = function ()
		local msg = messages_pb.get_callback_award_req()

		xyd.Backend.get():request(xyd.mid.GET_CALLBACK_AWARD, msg)
	end

	self.eventProxy_:addEventListener(xyd.event.GET_CALLBACK_AWARD, handler(self, self.onAward))
end

function OldPlayerBackGiftWindow:onAward()
	if xyd.models.selfPlayer:ifCallback() then
		xyd.models.selfPlayer:setCallback(0)
	end

	local awards = xyd.tables.giftTable:getAwards(50002)
	local params = {}

	for _, award in ipairs(awards) do
		table.insert(params, {
			hideText = true,
			item_id = award[1],
			item_num = award[2]
		})
	end

	xyd.models.itemFloatModel:pushNewItems(params)
	xyd.closeWindow(self.name_)
end

return OldPlayerBackGiftWindow
