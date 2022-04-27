local ActivityResidentReturnPopWindow = class("ActivityResidentReturnPopWindow", import(".BaseWindow"))

function ActivityResidentReturnPopWindow:ctor(name, params)
	ActivityResidentReturnPopWindow.super.ctor(self, name, params)
end

function ActivityResidentReturnPopWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ActivityResidentReturnPopWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.personImg = self.groupAction:ComponentByName("personImg", typeof(UISprite))
	self.goText = self.personImg:ComponentByName("goText", typeof(UILabel))
	self.logoImg = self.groupAction:ComponentByName("logoImg", typeof(UISprite))
	self.dateCon = self.groupAction:NodeByName("dateCon").gameObject
	self.yearText = self.dateCon:ComponentByName("yearText", typeof(UILabel))
	self.monthText = self.dateCon:ComponentByName("monthText", typeof(UILabel))
	self.dayText = self.dateCon:ComponentByName("dayText", typeof(UILabel))
	self.markText = self.dateCon:ComponentByName("markText", typeof(UILabel))
	self.effectCon = self.groupAction:ComponentByName("effectCon", typeof(UITexture))
end

function ActivityResidentReturnPopWindow:layout()
	xyd.setUISpriteAsync(self.logoImg, nil, "resident_return_main_logo_" .. xyd.Global.lang, nil, )

	self.goText.text = __("ACTIVITY_RETURN_RESIDENT_POP_GO")
	local returnData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN)

	if xyd.models.activity:isResidentReturnTimeIn() then
		local start_time = returnData:getReturnStartTime()
		local timeDesc = os.date("*t", start_time)
		self.yearText.text = tostring(timeDesc.year)
		self.monthText.text = tostring(timeDesc.month)
		self.dayText.text = tostring(timeDesc.day)

		if #self.monthText.text == 1 then
			self.monthText.text = "0" .. self.monthText.text
		end

		if #self.dayText.text == 1 then
			self.dayText.text = "0" .. self.dayText.text
		end
	else
		self.dateCon:SetActive(false)
	end

	self.effect = xyd.Spine.new(self.effectCon.gameObject)

	self.effect:setInfo("return2_fall", function ()
		self.effect:play("texiao01", 0, 1, function ()
		end)
	end)
end

function ActivityResidentReturnPopWindow:registerEvent()
	UIEventListener.Get(self.bg.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():clearStackWindow()
		xyd.WindowManager.get():openWindow("activity_resident_return_main_window")
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ActivityResidentReturnPopWindow:didClose()
	ActivityResidentReturnPopWindow.super.didClose(self)

	xyd.MainController.get().openPopWindowNum = xyd.MainController.get().openPopWindowNum - 1
end

return ActivityResidentReturnPopWindow
