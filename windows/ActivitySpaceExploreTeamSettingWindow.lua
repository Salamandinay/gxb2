local BaseWindow = import(".BaseWindow")
local ActivitySpaceExploreTeamSettingWindow = class("ActivitySpaceExploreTeamSettingWindow", BaseWindow)

function ActivitySpaceExploreTeamSettingWindow:ctor(name, params)
	ActivitySpaceExploreTeamSettingWindow.super.ctor(self, name, params)
end

function ActivitySpaceExploreTeamSettingWindow:initWindow()
	ActivitySpaceExploreTeamSettingWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function ActivitySpaceExploreTeamSettingWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject

	for i = 1, 2 do
		self["item" .. i] = winTrans:NodeByName("item" .. i).gameObject
		self["btnSprite_" .. i] = self["item" .. i]:ComponentByName("btn_", typeof(UISprite))
		self["textLabel_" .. i] = self["item" .. i]:ComponentByName("textLabel_", typeof(UILabel))
	end
end

function ActivitySpaceExploreTeamSettingWindow:initUIComponent()
	self.titleLabel_.text = __("SPACE_EXPLORE_TEXT_19")
	self.textLabel_1.text = __("SPACE_EXPLORE_TEXT_20")
	self.textLabel_2.text = __("SPACE_EXPLORE_TEXT_21")
	self["isChange" .. 1] = 0
	self["isChange" .. 2] = 0

	for i = 1, 2 do
		self["flag" .. i] = tonumber(xyd.db.misc:getValue("activity_space_explore_team_window_flag" .. i)) or 0
		local sprite = "setting_up_unpick"

		if self["flag" .. i] == 1 then
			sprite = "setting_up_pick"
		end

		xyd.setUISpriteAsync(self["btnSprite_" .. i], nil, sprite)

		self["isChange" .. i] = tonumber(self["flag" .. i])
		self["isNew" .. i] = tonumber(self["flag" .. i])
	end
end

function ActivitySpaceExploreTeamSettingWindow:register()
	ActivitySpaceExploreTeamSettingWindow.super.register(self)

	for i = 1, 2 do
		UIEventListener.Get(self["item" .. i]).onClick = handler(self, function ()
			self:onClickBtn(i)
		end)
	end
end

function ActivitySpaceExploreTeamSettingWindow:onClickBtn(index)
	self["flag" .. index] = math.abs(self["flag" .. index] - 1)
	local sprite = "setting_up_unpick"

	if self["flag" .. index] == 1 then
		sprite = "setting_up_pick"
	end

	xyd.setUISpriteAsync(self["btnSprite_" .. index], nil, sprite)
	xyd.db.misc:setValue({
		key = "activity_space_explore_team_window_flag" .. index,
		value = tostring(self["flag" .. index])
	})

	self["isNew" .. index] = tonumber(self["flag" .. index])
end

function ActivitySpaceExploreTeamSettingWindow:excuteCallBack(isCloseAll)
	for i = 1, 2 do
		if self["isChange" .. i] ~= self["isNew" .. i] then
			self["isChange" .. i] = 1
		else
			self["isChange" .. i] = 0
		end
	end

	if not isCloseAll and self.params_ and self.params_.closeCallBack then
		self.params_.closeCallBack(self["isChange" .. 1], self["isChange" .. 2])
	end
end

function ActivitySpaceExploreTeamSettingWindow:willClose()
	local mapWd = xyd.WindowManager.get():getWindow("activity_space_explore_map_window")

	if mapWd then
		mapWd:checkIfCanUpPartner()
	end

	ActivitySpaceExploreTeamSettingWindow.super.willClose(self)
end

return ActivitySpaceExploreTeamSettingWindow
