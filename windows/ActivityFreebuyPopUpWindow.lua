local BaseWindow = import(".BaseWindow")
local ActivityFreebuyPopUpWindow = class("ActivityFreebuyPopUpWindow", BaseWindow)
local json = require("cjson")

function ActivityFreebuyPopUpWindow:ctor(name, params)
	ActivityFreebuyPopUpWindow.super.ctor(self, name, params)

	self.selectState_ = false
end

function ActivityFreebuyPopUpWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityFreebuyPopUpWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.logoImg_ = winTrans:ComponentByName("logoImg", typeof(UISprite))
	self.label1_ = winTrans:ComponentByName("labelGroup1/label", typeof(UILabel))
	self.label2_ = winTrans:ComponentByName("labelGroup2/label", typeof(UILabel))
	self.jumpBtn_ = winTrans:NodeByName("jumpBtn").gameObject
	self.jumpBtnLabel_ = winTrans:ComponentByName("jumpBtn/label", typeof(UILabel))
	self.selectLabel_ = winTrans:ComponentByName("selectGroup/label", typeof(UILabel))
	self.selectImg_ = winTrans:ComponentByName("selectGroup/selectImg", typeof(UISprite))
	self.selectGroup_ = winTrans:NodeByName("selectGroup").gameObject
end

function ActivityFreebuyPopUpWindow:layout()
	self.label1_.text = __("ACTIVITY_FREEBUY_TEXT05")
	self.label2_.text = __("ACTIVITY_FREEBUY_TEXT06")

	if xyd.Global.lang == "fr_fr" then
		self.label2_.fontSize = 18
	end

	self.jumpBtnLabel_.text = __("ACTIVITY_BEACH_MAIN_WINDOW_TEXT02")
	self.selectLabel_.text = __("GAMBLE_REFRESH_NOT_SHOW_TODAY")

	xyd.setUISpriteAsync(self.logoImg_, nil, "freebuy_title_" .. xyd.Global.lang)
	self:updateSelectImg()
end

function ActivityFreebuyPopUpWindow:register()
	UIEventListener.Get(self.selectGroup_).onClick = function ()
		self.selectState_ = not self.selectState_

		self:updateSelectImg()
	end

	UIEventListener.Get(self.jumpBtn_).onClick = function ()
		local params = {
			activity_type = 2,
			select = 284,
			activity_type2 = 1
		}

		xyd.goToActivityWindowAgain(params)
		self:close()
	end
end

function ActivityFreebuyPopUpWindow:updateSelectImg()
	if self.selectState_ then
		xyd.setUISpriteAsync(self.selectImg_, nil, "setting_up_pick")
	else
		xyd.setUISpriteAsync(self.selectImg_, nil, "setting_up_unpick")
	end
end

function ActivityFreebuyPopUpWindow:willClose()
	if self.selectState_ then
		xyd.db.misc:setValue({
			key = "freebuy_popup_time",
			value = xyd.getServerTime()
		})
	end
end

function ActivityFreebuyPopUpWindow:didClose()
	ActivityFreebuyPopUpWindow.super.didClose(self)

	xyd.MainController.get().openPopWindowNum = xyd.MainController.get().openPopWindowNum - 1
end

return ActivityFreebuyPopUpWindow
