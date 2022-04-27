local ActivityIceSecretShowWindow = class("ActivityIceSecretShowWindow", import(".BaseWindow"))

function ActivityIceSecretShowWindow:ctor(name, params)
	ActivityIceSecretShowWindow.super.ctor(self, name, params)
	xyd.db.misc:setValue({
		key = "activity_ice_secret_show",
		value = xyd.getServerTime()
	})

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ICE_SECRET)
end

function ActivityIceSecretShowWindow:willOpen()
	ActivityIceSecretShowWindow.super.willOpen(self)
end

function ActivityIceSecretShowWindow:initWindow()
	ActivityIceSecretShowWindow.super.initWindow(self)
	self:getComponent()
	self:initTime()
	xyd.setUITextureByNameAsync(self.logoImg_, "ice_secret_show_logo_" .. xyd.Global.lang, true)
end

function ActivityIceSecretShowWindow:getComponent()
	local goTrans = self.window_:NodeByName("actionGroup").gameObject
	self.actionGroup_ = goTrans
	self.touchBox_ = goTrans:GetComponent(typeof(UnityEngine.BoxCollider))
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UITexture))
	self.timeLabel_ = goTrans:ComponentByName("logoImg/timeLabel", typeof(UILabel))
	self.countLabel_ = goTrans:ComponentByName("logoImg/countLabel", typeof(UILabel))
	self.effectGroup_ = goTrans:NodeByName("effectGroup").gameObject
	self.touchBox_.enabled = false

	for i = 1, 5 do
		self["card" .. i] = goTrans:NodeByName("effectGroup/groupCard/node" .. i .. "/card" .. i)
		self["node" .. i] = goTrans:NodeByName("effectGroup/groupCard/node" .. i)
	end

	UIEventListener.Get(self.actionGroup_).onClick = function ()
		local sequence = self:getSequence()

		sequence:Append(self.actionGroup_.transform:DOScale(Vector3(0, 0, 0), 0.2))
		sequence:AppendCallback(function ()
			xyd.WindowManager.get():closeWindow(self.name_)
		end)
	end
end

function ActivityIceSecretShowWindow:initTime()
	self.timeLabel_.text = __("END")
	local params = {
		duration = tonumber(self.activityData:getEndTime() - xyd.getServerTime())
	}
	self.timeCount_ = import("app.components.CountDown").new(self.countLabel_, params)
end

function ActivityIceSecretShowWindow:playOpenAnimation(callback)
	if self.effect_ then
		self.effect_:destroy()
	end

	self.touchBox_.enabled = false

	ActivityIceSecretShowWindow.super.playOpenAnimation(self, function ()
		self.effect_ = xyd.Spine.new(self.effectGroup_)

		self.effect_:setPlayNeedStop()
		self.effect_:setInfo("fx_ice_card", function ()
			for i = 1, 5 do
				local k = tostring(i)

				if i == 1 then
					k = ""
				end

				self.effect_:followBone("bone" .. k, self["node" .. i])
				self.effect_:followSlot("juese" .. i, self["card" .. i])
			end

			self:waitForTime(0.2, function ()
				self.effect_:play("texiao01", 1, 1, function ()
					self.touchBox_.enabled = true
				end)
			end)
			self.effect_:setSeparatorDuration(11)
		end)

		if callback then
			callback()
		end
	end)
end

function ActivityIceSecretShowWindow:didClose()
	ActivityIceSecretShowWindow.super.didClose(self)

	xyd.MainController.get().openPopWindowNum = xyd.MainController.get().openPopWindowNum - 1
end

return ActivityIceSecretShowWindow
