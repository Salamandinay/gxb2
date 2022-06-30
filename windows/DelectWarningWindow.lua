local DelectWarningWindow = class("DelectWarningWindow", import(".BaseWindow"))
local md5 = require("md5")

function DelectWarningWindow:ctor(name, params)
	DelectWarningWindow.super.ctor(self, name, params)

	self.resTime = 5
end

function DelectWarningWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:register()
end

function DelectWarningWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.tipsLabel_ = winTrans:ComponentByName("tipsGroup/label", typeof(UILabel))
	self.labelDesc_ = winTrans:ComponentByName("labelDesc", typeof(UILabel))
	self.deleteBtn_ = winTrans:NodeByName("deleteBtn").gameObject
	self.deleteBtnLabel_ = winTrans:ComponentByName("deleteBtn/label", typeof(UILabel))
	self.backBtn_ = winTrans:NodeByName("backBtn").gameObject
	self.backBtnLabel_ = winTrans:ComponentByName("backBtn/label", typeof(UILabel))
end

function DelectWarningWindow:register()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.backBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.deleteBtn_).onClick = function ()
		local url = nil

		if XYDUtils.IsTest() then
			url = "https://testyotmhome.game168.com.tw"
		else
			url = "https://yottagames.com"
		end

		local langue = string.sub(xyd.Global.lang, 1, 2)
		local uid = xyd.models.selfPlayer.uid_
		local workorder = md5.sumhexa(uid .. "_workorder")
		local web = url .. "/" .. langue .. "/workorder/game_submit_email?game_id=115&workorder_sign=" .. workorder .. "&uid=" .. uid

		UnityEngine.Application.OpenURL(web)
		xyd.models.deviceNotify:setDeleteMark()
	end
end

function DelectWarningWindow:layout()
	self.tipsLabel_.text = __("DELETE_ACCOUNT_TEXT03")
	self.labelDesc_.text = __("DELETE_ACCOUNT_TEXT04")
	self.backBtnLabel_.text = __("DELETE_ACCOUNT_TEXT06")

	xyd.setEnabled(self.deleteBtn_, false)

	self.deleteBtnLabel_.text = self.resTime
	self.timer_ = Timer.New(handler(self, self.onTime), 1, -1, false)

	self.timer_:Start()
end

function DelectWarningWindow:onTime()
	if self.window_ and not tolua.isnull(self.window_) then
		self.resTime = self.resTime - 1
		self.deleteBtnLabel_.text = self.resTime

		if self.resTime <= 0 then
			xyd.setEnabled(self.deleteBtn_, true)

			self.deleteBtnLabel_.text = __("DELETE_ACCOUNT_TEXT05")

			self.timer_:Stop()
		end
	end
end

return DelectWarningWindow
