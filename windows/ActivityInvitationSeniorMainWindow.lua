local ActivityInvitationSeniorMainWindow = class("ActivityInvitationSeniorMainWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")

function ActivityInvitationSeniorMainWindow:ctor(name, params)
	ActivityInvitationSeniorMainWindow.super.ctor(self, name, params)

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_INVITATION_SENIOR)
	self.curState = activityData:getState()
end

function ActivityInvitationSeniorMainWindow:initWindow()
	self:getUIComponent()
	ActivityInvitationSeniorMainWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function ActivityInvitationSeniorMainWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.oldCon = self.groupAction:NodeByName("oldCon").gameObject
	self.newCon = self.groupAction:NodeByName("newCon").gameObject
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.nameImg = self.upCon:ComponentByName("nameImg", typeof(UISprite))
	self.tipsBtn = self.upCon:NodeByName("tipsBtn").gameObject
	self.rankBtn = self.upCon:NodeByName("rankBtn").gameObject
	self.stateBtn = self.upCon:NodeByName("stateBtn").gameObject
	self.stateBtnLabel = self.stateBtn:ComponentByName("stateBtnLabel", typeof(UILabel))
	self.stateBtnRedPoint = self.stateBtn:NodeByName("stateBtnRedPoint").gameObject
end

function ActivityInvitationSeniorMainWindow:getGameObject()
	return self.window_
end

function ActivityInvitationSeniorMainWindow:reSize()
	self:resizePosY(self.tipsBtn.gameObject, 4, 32)
	self:resizePosY(self.rankBtn.gameObject, 4, 32)
	self:resizePosY(self.bg.gameObject, -55.9, -1)
	self:resizePosY(self.upCon.gameObject, 528, 584)
	self:resizePosY(self.newCon.gameObject, -171, -134)
end

function ActivityInvitationSeniorMainWindow:registerEvent()
	UIEventListener.Get(self.tipsBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "INVITATION_HELP"
		})
	end)
	UIEventListener.Get(self.rankBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("common_rank_window", {
			activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_INVITATION_SENIOR),
			type = xyd.ActivityID.ACTIVITY_INVITATION_SENIOR
		})
	end)
end

function ActivityInvitationSeniorMainWindow:layout()
	self:initTop()

	self.stateBtnLabel.text = __("INVITATION_SWITCH")

	if self.curState == xyd.ActivityInvitationSeniorState.OLD then
		self.oldItem = import("app.components.ActivityInvitationSeniorOldItem").new(self.oldCon.gameObject, self)

		self.oldCon:SetActive(true)
		self.newCon:SetActive(false)
		xyd.setUISpriteAsync(self.nameImg, nil, "invitation_senior_text_logo_yq_" .. xyd.Global.lang, nil, , true)
		xyd.setUITextureByNameAsync(self.bg, "invitation_senior_bg_xsyq")
		self.rankBtn:SetActive(true)
	elseif self.curState == xyd.ActivityInvitationSeniorState.NEW then
		self.newItem = import("app.components.ActivityInvitationSeniorNewItem").new(self.newCon.gameObject, self)

		self.oldCon:SetActive(false)
		self.newCon:SetActive(true)
		xyd.setUISpriteAsync(self.nameImg, nil, "invitation_senior_text_logo_rx_" .. xyd.Global.lang, nil, , true)
		xyd.setUITextureByNameAsync(self.bg, "invitation_senior_bg_xsrx")
		self.rankBtn:SetActive(false)
	end
end

function ActivityInvitationSeniorMainWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)
end

return ActivityInvitationSeniorMainWindow
