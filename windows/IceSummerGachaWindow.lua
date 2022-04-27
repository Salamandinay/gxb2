local BaseWindow = import("app.windows.BaseWindow")
local IceSummerGachaWindow = class("IceSummerGachaWindow", BaseWindow)

function IceSummerGachaWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.limit = params.num
	self.callBack_ = params.callback
end

function IceSummerGachaWindow:initWindow()
	IceSummerGachaWindow.super:initWindow()

	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.title = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.label = self.groupAction:ComponentByName("label", typeof(UILabel))
	self.selectGroup = self.groupAction:NodeByName("selectGroup").gameObject
	self.btn = self.groupAction:NodeByName("btn").gameObject
	self.btnLabel = self.btn:ComponentByName("button_label", typeof(UILabel))
	self.selectGroup = self.groupAction:NodeByName("selectGroup").gameObject
	self.selectNum_ = import("app.components.SelectNum").new(self.selectGroup, "minmax")

	self.selectNum_:setKeyboardPos(0, -380)

	self.selectNum_.inputLabel.text = "1"

	self:layout()
	self:RegisterEvent()
end

function IceSummerGachaWindow:layout()
	self.title.text = __("ACTIVITY_DOLL_MAKE_BUTTON")
	self.label.text = __("ACTIVITY_ICE_SUMMER_INPUT")
	self.btnLabel.text = __("CONFIRM")

	local function callback(num)
	end

	self.selectNum_:setInfo({
		clearNotCallback = true,
		minNum = 1,
		notCallback = true,
		curNum = 1,
		maxNum = self.limit,
		callback = callback,
		maxCallback = function ()
		end
	})
end

function IceSummerGachaWindow:RegisterEvent()
	UIEventListener.Get(self.btn).onClick = handler(self, function ()
		if self.callBack_ then
			self.callBack_(tonumber(self.selectNum_.inputLabel.text))
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

return IceSummerGachaWindow
