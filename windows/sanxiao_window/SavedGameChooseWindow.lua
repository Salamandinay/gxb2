local SavedGameChooseWindow = class("SavedGameChooseWindow", import(".BaseWindow"))

function SavedGameChooseWindow:ctor(name, params)
	SavedGameChooseWindow.super.ctor(self, name, params)

	self._isRequesting = false
end

function SavedGameChooseWindow:initWindow()
	SavedGameChooseWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function SavedGameChooseWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_all = winTrans:NodeByName("group_all").gameObject
	self.btn_close = winTrans:ComponentByName("group_all/btn_close", typeof(UISprite))
	self.title_label = winTrans:ComponentByName("group_all/title_label", typeof(UILabel))
	self.desc_label = winTrans:ComponentByName("group_all/desc_label", typeof(UILabel))
	self.btn_left = winTrans:NodeByName("group_all/left_group/btn_left").gameObject
	self.left_btn_label = self.btn_left.transform:ComponentByName("btn_label", typeof(UILabel))
	self.left_label1 = winTrans:ComponentByName("group_all/left_group/left_label1", typeof(UILabel))
	self.left_label2 = winTrans:ComponentByName("group_all/left_group/left_label2", typeof(UILabel))
	self.left_level_label = winTrans:ComponentByName("group_all/left_group/left_level_group/left_level_label", typeof(UILabel))
	self.left_gem_label = winTrans:ComponentByName("group_all/left_group/left_gem_group/left_gem_label", typeof(UILabel))
	self.left_star_label = winTrans:ComponentByName("group_all/left_group/left_star_group/left_star_label", typeof(UILabel))
	self.btn_right = winTrans:NodeByName("group_all/right_group/btn_right").gameObject
	self.right_btn_label = self.btn_right.transform:ComponentByName("btn_label", typeof(UILabel))
	self.right_label1 = winTrans:ComponentByName("group_all/right_group/right_label1", typeof(UILabel))
	self.right_label2 = winTrans:ComponentByName("group_all/right_group/right_label2", typeof(UILabel))
	self.right_level_label = winTrans:ComponentByName("group_all/right_group/right_level_group/right_level_label", typeof(UILabel))
	self.right_gem_label = winTrans:ComponentByName("group_all/right_group/right_gem_group/right_gem_label", typeof(UILabel))
	self.right_star_label = winTrans:ComponentByName("group_all/right_group/right_star_group/right_star_label", typeof(UILabel))
end

function SavedGameChooseWindow:initUIComponent()
	self:setDefaultBgClick(function ()
		self:onBtnClose()
	end)
	xyd.setDarkenBtnBehavior(self.btn_close.gameObject, self, self.onBtnClose)
	xyd.setDarkenBtnBehavior(self.btn_left, self, self.onBtnLeft)
	xyd.setDarkenBtnBehavior(self.btn_right, self, self.onBtnRight)

	local playerInfoModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYER_INFO)
	self.left_level_label.text = tostring(playerInfoModel.data.current_level)
	self.left_gem_label.text = tostring(playerInfoModel.data.gems)
	self.left_star_label.text = tostring(playerInfoModel.data.stars)
	self.right_level_label.text = tostring(self.params_.current_level)
	self.right_gem_label.text = tostring(self.params_.gems)
	self.right_star_label.text = tostring(self.params_.stars)
	local timeInfo = os.date("!*t", self.params_.last_log_time)
	local year = tostring(timeInfo.year)
	local month = tostring(timeInfo.month)
	local day = tostring(timeInfo.day)
	local hour = tostring(timeInfo.hour)
	local min = tostring(timeInfo.min)
	self.right_label2.text = __("SAVED_CHOOSE_LAST_SYNC") .. "\n" .. year .. "." .. month .. "." .. day .. " " .. hour .. ":" .. min
	self.title_label.text = __("SAVED_CHOOSE_TITLE")
	self.desc_label.text = __("SAVED_CHOOSE_DESC")
	self.left_label1.text = __("SAVED_CHOOSE_LOCAL")
	self.right_label1.text = __("SAVED_CHOOSE_SERVER")
	self.left_label2.text = __("SAVED_CHOOSE_PROGRESS")
	self.left_btn_label.text = __("CHOOSE")
	self.right_btn_label.text = __("CHOOSE")
end

function SavedGameChooseWindow:onBtnRight()
	if self._isRequesting then
		return
	end

	self._isRequesting = true

	local function callback()
		self._isRequesting = false

		self:close()
	end

	xyd.DataPlatform.get():chooseServerStorage(self.params_, callback)
end

function SavedGameChooseWindow:onBtnLeft()
	if self._isRequesting then
		return
	end

	self._isRequesting = true

	local function complete()
		self._isRequesting = false

		self:close()
	end

	xyd.DataPlatform.get():chooseLocalStorage(complete)
end

function SavedGameChooseWindow:onBtnClose()
	if self._isRequesting then
		return
	end

	self:close()
end

return SavedGameChooseWindow
