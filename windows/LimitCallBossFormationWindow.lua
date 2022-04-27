local BaseWindow = import(".BaseWindow")
local TrialFormationWindow = import(".TrialFormationWindow")
local LimitCallBossFormationWindow = class("LimitCallBossFormationWindow", TrialFormationWindow)

function LimitCallBossFormationWindow:ctor(name, params)
	LimitCallBossFormationWindow.super.ctor(self, name, params)
end

function LimitCallBossFormationWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponents()
	self:registerEvent()

	local msg = messages_pb.limit_gacha_boss_activity_get_partner_infos_req()
	msg.other_player_id = self.params_.player_id
	msg.activity_id = xyd.ActivityID.LIMIT_CALL_BOSS

	xyd.Backend:get():request(xyd.mid.LIMIT_GACHA_BOSS_ACTIVITY_GET_PARTNER_INFOS, msg)
end

function LimitCallBossFormationWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.LIMIT_GACHA_BOSS_ACTIVITY_GET_PARTNER_INFOS, handler(self, self.onGetInfo))
end

function LimitCallBossFormationWindow:onGetInfo(event)
	local partners = event.data.partners
	self.buffIds = {}
	self.petId = 0
	self.info = {}

	if partners then
		self.info = partners
	end

	self:layout()
end

return LimitCallBossFormationWindow
