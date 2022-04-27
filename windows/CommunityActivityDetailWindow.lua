local BaseWindow = import(".BaseWindow")
local CommunityActivityDetailWindow = class("CommunityActivityDetailWindow", BaseWindow)

function CommunityActivityDetailWindow:ctor(name, params)
	CommunityActivityDetailWindow.super.ctor(self, name, params)

	self.content = params.content
	self.link = params.link
end

function CommunityActivityDetailWindow:initWindow()
	self:getUIComponent()
	CommunityActivityDetailWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function CommunityActivityDetailWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	local contentGroup = groupAction:NodeByName("contentGroup").gameObject
	self.scroller = contentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.labelDesc = self.scroller:ComponentByName("labelDesc", typeof(UILabel))
	self.labelTip = self.scroller:ComponentByName("labelTip", typeof(UILabel))
	self.btnJump = groupAction:NodeByName("btnJump").gameObject
	self.btnJumpLabel = self.btnJump:ComponentByName("button_label", typeof(UILabel))
end

function CommunityActivityDetailWindow:initUIComponent()
	self.labelTitle.text = __("SETTING_UP_TAP_4")
	self.btnJumpLabel.text = __("SNS_ACTIVITY_HTTP_BTN01")
	self.labelTip.text = __("SNS_ACTIVITY_TEXT02")
	self.labelDesc.text = self.content
end

function CommunityActivityDetailWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnJump).onClick = function ()
		UnityEngine.Application.OpenURL(self.link)

		local msg = messages_pb.log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.COMMUNITY_ACTIVITY_LINK

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end
end

return CommunityActivityDetailWindow
