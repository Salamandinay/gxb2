local DeleteAccountCountWindow = class("DeleteAccountCountWindow", import(".BaseWindow"))
local md5 = require("md5")
local CountDown = import("app.components.CountDown")

function DeleteAccountCountWindow:ctor(name, params)
	DeleteAccountCountWindow.super.ctor(self, name, params)

	self.endTime_ = params.due_time
	self.server_time_ = params.server_time
	self.uid_ = params.uid
end

function DeleteAccountCountWindow:initWindow()
	self:getUIComponent()
	self:layout()
end

function DeleteAccountCountWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.tipsLabel_ = winTrans:ComponentByName("tipsGroup/label", typeof(UILabel))
	self.backBtn_ = winTrans:NodeByName("backBtn").gameObject
	self.backBtnLabel_ = winTrans:ComponentByName("backBtn/label", typeof(UILabel))
	self.timeLabel_ = winTrans:ComponentByName("label", typeof(UILabel))
	UIEventListener.Get(self.backBtn_).onClick = handler(self, self.onClickBack)
end

function DeleteAccountCountWindow:layout()
	self.tipsLabel_.text = __("DELETE_ACCOUNT_TEXT03")

	if self.endTime_ <= self.server_time_ then
		self.timeLabel_.text = __("DELETE_ACCOUNT_TEXT11")
		self.backBtnLabel_.text = __("SURE")
		self.isDelete_ = true
	else
		self.backBtnLabel_.text = __("DELETE_ACCOUNT_TEXT12")
		self.countDown_ = CountDown.new(self.timeLabel_)

		self.countDown_:setInfo({
			key = "DELETE_ACCOUNT_TEXT10",
			duration = self.endTime_ - self.server_time_,
			secondStrType = xyd.SecondsStrType.ALL,
			callback = function ()
				self.timeLabel_.text = __("DELETE_ACCOUNT_TEXT11")
				self.backBtnLabel_.text = __("SURE")
				self.isDelete_ = true
			end
		})
	end
end

function DeleteAccountCountWindow:onClickBack()
	if self.isDelete_ then
		return
	end

	local url = nil

	if XYDUtils.IsTest() then
		url = "https://testyotmhome.game168.com.tw"
	else
		url = "https://yottagames.com"
	end

	local langue = string.sub(xyd.Global.lang, 1, 2)
	local uid = self.uid_
	local workorder = md5.sumhexa(uid .. "_workorder")
	local web = url .. "/" .. langue .. "/workorder/game_cancel_process?game_id=115&workorder_sign=" .. workorder .. "&uid=" .. uid

	UnityEngine.Application.OpenURL(web)
	xyd.models.deviceNotify:setDeleteMark2()
end

return DeleteAccountCountWindow
