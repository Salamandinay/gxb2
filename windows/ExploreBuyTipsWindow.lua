local ExploreBuyTipsWindow = class("ExploreBuyTipsWindow", import(".BaseWindow"))

function ExploreBuyTipsWindow:ctor(name, params)
	ExploreBuyTipsWindow.super.ctor(self, name, params)

	self.hasSelect = false
	self.text = params.text
	self.yesCallBack = params.yesCallBack
	self.timeStampKey = params.timeStampKey
	self.noTodayTips = params.noTodayTips or false
end

function ExploreBuyTipsWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ExploreBuyTipsWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTips = groupAction:ComponentByName("labelTips", typeof(UILabel))
	self.labelText = groupAction:ComponentByName("labelText", typeof(UILabel))
	self.groupNoTips = groupAction:NodeByName("groupNoTips").gameObject
	self.imgSelect = self.groupNoTips:NodeByName("imgBg/imgSelect").gameObject
	self.labelNoTips = self.groupNoTips:ComponentByName("labelNoTips", typeof(UILabel))
	self.btnNO = groupAction:NodeByName("btnNO").gameObject
	self.labelNO = self.btnNO:ComponentByName("labelNO", typeof(UILabel))
	self.btnYES = groupAction:NodeByName("btnYES").gameObject
	self.labelYES = self.btnYES:ComponentByName("labelYES", typeof(UILabel))
end

function ExploreBuyTipsWindow:layout()
	self.labelTips.text = __("TIPS")
	self.labelText.text = self.text

	if self.noTodayTips then
		self.groupNoTips:SetActive(false)
		self.labelText:Y(20)
	end

	self.labelNoTips.text = __("GAMBLE_REFRESH_NOT_SHOW_TODAY")
	self.labelYES.text = __("YES")
	self.labelNO.text = __("NO")

	self.imgSelect:SetActive(false)

	if xyd.Global.lang == "en_en" then
		self.labelText.width = 500
	end
end

function ExploreBuyTipsWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.groupNoTips).onClick = function ()
		self.hasSelect = not self.hasSelect

		self.imgSelect:SetActive(self.hasSelect)
	end

	UIEventListener.Get(self.btnNO).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnYES).onClick = function ()
		if self.hasSelect and self.timeStampKey then
			xyd.db.misc:setValue({
				key = self.timeStampKey,
				value = xyd.getServerTime()
			})
		end

		self:close()

		if self.yesCallBack then
			self.yesCallBack()
		end
	end
end

return ExploreBuyTipsWindow
