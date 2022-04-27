local BaseWindow = import(".BaseWindow")
local LifeStartWindow = class("LifeStartWindow", BaseWindow)

function LifeStartWindow:ctor(name, params)
	LifeStartWindow.super.ctor(self, name, params)
end

function LifeStartWindow:initWindow()
	LifeStartWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function LifeStartWindow:getUIComponent()
	local trans = self.window_.transform
	local groupAction = trans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local content = groupAction:NodeByName("content").gameObject
	self.group1 = content:NodeByName("group1").gameObject
	self.labelTitle1 = self.group1:ComponentByName("labelTitle1", typeof(UILabel))
	self.labelDes1 = self.group1:ComponentByName("labelDes1", typeof(UILabel))
	self.houseRedMark = self.group1:ComponentByName("redMark1", typeof(UISprite))
	self.group2 = content:NodeByName("group2").gameObject
	self.labelTitle2 = self.group2:ComponentByName("labelTitle2", typeof(UILabel))
	self.labelDes2 = self.group2:ComponentByName("labelDes2", typeof(UILabel))
	self.group3 = content:NodeByName("group3").gameObject
	self.labelTitle3 = self.group3:ComponentByName("labelTitle3", typeof(UILabel))
	self.labelDes3 = self.group3:ComponentByName("labelDes3", typeof(UILabel))
end

function LifeStartWindow:initUIComponent()
	self.labelTitle.text = __("LIFE_2")
	self.labelTitle1.text = __("MAINWIN_RIGHT_3")
	self.labelDes1.text = __("LIFE_DES1")
	self.labelTitle2.text = __("HOUSE_TEXT_10")
	self.labelDes2.text = __("LIFE_DES2")
	self.labelTitle3.text = __("PERSON_DRESS")
	self.labelDes3.text = __("LIFE_DES3")

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.HOUSE, self.houseRedMark)

	if not xyd.checkFunctionOpen(xyd.FunctionID.DRESS, true) then
		xyd.applyChildrenGrey(self.group3.gameObject)
	end
end

function LifeStartWindow:registerEvent()
	LifeStartWindow.super.register(self)

	local winNames = {
		"house_window",
		"dates_list_window",
		"dress_main_window"
	}
	local window_top_close_funs = {
		[3] = function ()
			xyd.WindowManager.get():openWindow("life_start_window")
		end
	}

	for i = 1, 3 do
		UIEventListener.Get(self["group" .. tostring(i)]).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

			if winNames[i] == "dress_main_window" then
				if xyd.checkFunctionOpen(xyd.FunctionID.DRESS) then
					xyd.WindowManager:get():openWindow(winNames[i], {})
					xyd.WindowManager.get():closeWindow(self.name_)
				end
			else
				xyd.WindowManager:get():openWindow(winNames[i], {
					window_top_close_fun = window_top_close_funs[i]
				})
				xyd.WindowManager.get():closeWindow(self.name_)
			end
		end
	end
end

return LifeStartWindow
