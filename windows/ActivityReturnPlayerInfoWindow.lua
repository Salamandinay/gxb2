local ActivityReturnPlayerInfoWindow = class("ActivityReturnPlayerInfoWindow", import(".BaseWindow"))

function ActivityReturnPlayerInfoWindow:ctor(name, params)
	ActivityReturnPlayerInfoWindow.super.ctor(self, name, params)

	self.playerData_ = params.playerData
	self.callback_ = params.callback
end

function ActivityReturnPlayerInfoWindow:initWindow()
	ActivityReturnPlayerInfoWindow.super.initWindow(self)
	self:getComponent()
	self:layoutUI()
	self:register()
end

function ActivityReturnPlayerInfoWindow:getComponent()
	local winTrans = self.window_:NodeByName("actionGroup").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.winTitle_ = winTrans:ComponentByName("winTitle", typeof(UILabel))
	self.playerIconRoot_ = winTrans:NodeByName("playerIconRoot").gameObject
	self.tipsLabel_ = winTrans:ComponentByName("tipsLabel", typeof(UILabel))
	self.playerName_ = winTrans:ComponentByName("playerName", typeof(UILabel))
	self.btnYes_ = winTrans:NodeByName("btnYes").gameObject
	self.btnYesLabel_ = winTrans:ComponentByName("btnYes/label", typeof(UILabel))
	self.btnNo_ = winTrans:NodeByName("btnNo").gameObject
	self.btnNoLabel_ = winTrans:ComponentByName("btnNo/label", typeof(UILabel))
end

function ActivityReturnPlayerInfoWindow:layoutUI()
	self.winTitle_.text = __("ACTIVITY_RETURN_APPLY_CONFIRM_WINDOW")
	self.btnYesLabel_.text = __("YES")
	self.btnNoLabel_.text = __("NO")
	self.tipsLabel_.text = __("ACTIVITY_RETURN_APPLY_CONFIRM_TIPS", self.playerData_.player_id)
	self.playerName_.text = self.playerData_.player_name
	local playerInfo = {
		avatarID = self.playerData_.avatar_id,
		avatar_frame_id = self.playerData_.avatar_frame_id,
		lev = self.playerData_.lev,
		callback = function ()
			xyd.WindowManager.get():openWindow("arena_formation_window", {
				is_robot = false,
				player_id = self.playerData_.player_id
			})
		end
	}

	if not self.teamerIcon_ then
		self.teamerIcon_ = import("app.components.PlayerIcon").new(self.playerIconRoot_)

		self.teamerIcon_:setInfo(playerInfo)
	else
		self.teamerIcon_:setInfo(playerInfo)
	end
end

function ActivityReturnPlayerInfoWindow:register()
	UIEventListener.Get(self.btnYes_).onClick = function ()
		self.callback_(true)
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnNo_).onClick = function ()
		self.callback_(false)
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

return ActivityReturnPlayerInfoWindow
