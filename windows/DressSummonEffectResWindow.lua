local BaseWindow = import(".BaseWindow")
local DressSummonEffectResWindow = class("DressSummonEffectResWindow", BaseWindow)
local PartnerTable = xyd.tables.partnerTable
local PartnerSummonEffect = import("app.components.PartnerSummonEffect")

function DressSummonEffectResWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = params.callback
	self.animationName = params.animationName
end

function DressSummonEffectResWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function DressSummonEffectResWindow:getUIComponent()
	local go = self.window_
	self.effectPos = go:NodeByName("effectPos").gameObject
	self.skipMask = go:NodeByName("clickMask").gameObject
end

function DressSummonEffectResWindow:layout()
	self.effectPos:SetActive(false)

	self.resultEffect = xyd.Spine.new(self.effectPos)

	self.resultEffect:setInfo("dress_gacha", function ()
		self.effectPos:SetActive(true)
		self.resultEffect:play(self.animationName, 1, 1, function ()
			self.callback()
			xyd.closeWindow("dress_summon_effect_res_window")
		end, true)
	end)
end

function DressSummonEffectResWindow:registerEvent()
	UIEventListener.Get(self.skipMask).onClick = function ()
		self.resultEffect:stop()
		self.callback()
		xyd.closeWindow("dress_summon_effect_res_window")
	end
end

return DressSummonEffectResWindow
