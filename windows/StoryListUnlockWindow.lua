local BaseWindow = import(".BaseWindow")
local StoryListUnlockWindow = class("StoryListUnlockWindow", BaseWindow)

function StoryListUnlockWindow:ctor(name, params)
	StoryListUnlockWindow.super.ctor(self, name, params)
end

function StoryListUnlockWindow:initWindow()
	StoryListUnlockWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
	self:resizeToParent()
end

function StoryListUnlockWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupActionTrans = winTrans:NodeByName("groupAction")
	self.titleLabel = groupActionTrans:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = groupActionTrans:NodeByName("closeBtn").gameObject
	self.labelText01 = groupActionTrans:ComponentByName("labelText01", typeof(UILabel))
	self.labelText02 = groupActionTrans:ComponentByName("labelText02", typeof(UILabel))
	self.labelText03 = groupActionTrans:ComponentByName("labelText03", typeof(UILabel))
	self.labelText04 = groupActionTrans:ComponentByName("labelText04", typeof(UILabel))
	self.goBtn = groupActionTrans:NodeByName("goBtn").gameObject
	self.goBtnLabel = self.goBtn:ComponentByName("button_label", typeof(UILabel))
	self.unlockBtn = groupActionTrans:NodeByName("unlockBtn").gameObject
	self.unlockBtnLabel = self.unlockBtn:ComponentByName("button_label", typeof(UILabel))
	self.unlockBtnNum = self.unlockBtn:ComponentByName("iconNum", typeof(UILabel))
end

function StoryListUnlockWindow:initUIComponent()
	self.titleLabel.text = __("PLOT_UNLOCK_TITLE1")
	self.labelText02.text = __("PLOT_UNLOCK_DESC1")
	self.labelText03.text = __("PLOT_UNLOCK_TITLE2")
	self.goBtnLabel.text = __("PLOT_UNLOCK_GO_TO_MAIN")
	self.unlockBtnLabel.text = __("PLOT_UNLOCK_CONSUME")
	self.isActivity = self.params_.isActivity
	self.listId = self.params_.listId
	self.table = xyd.tables.mainPlotListTable
	self.textTable = xyd.tables.mainPlotListTextTable

	if self.isActivity then
		self.table = xyd.tables.activityPlotListTable
		self.textTable = xyd.tables.activityPlotListTextTable
		self.labelText04.text = __("PLOT_UNLOCK_DESC3")
	else
		local fort_id = self.table:getFortID(self.listId)

		if fort_id and fort_id ~= "" then
			self.labelText04.text = __("PLOT_UNLOCK_DESC2", fort_id)
		else
			self.labelText04.text = __("PLOT_UNLOCK_DESC3")
		end
	end

	self.labelText01.text = self.textTable:getName(self.listId)
	self.unlockBtnNum.text = self.table:getUnlockCost(self.listId)[2]

	if self.isActivity or self.table:getStageID(self.listId) == 0 then
		self.goBtn:SetActive(false)
		self.unlockBtn:X(0)
	end
end

function StoryListUnlockWindow:register()
	StoryListUnlockWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.UNLOCK_MAIN_PLOT, self.onUnlock, self)
	self.eventProxy_:addEventListener(xyd.event.UNLOCK_ACTIVITY_PLOT, self.onUnlock, self)

	UIEventListener.Get(self.unlockBtn).onClick = handler(self, self.reqUnlock)

	UIEventListener.Get(self.goBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("campaign_window", nil, function ()
			xyd.WindowManager.get():closeWindow("story_list_unlock_window")
			xyd.WindowManager.get():closeWindow("story_list_window")
			xyd.WindowManager.get():closeWindow("setting_up_window")
		end)
	end
end

function StoryListUnlockWindow:reqUnlock()
	local cost = self.table:getUnlockCost(self.listId)[2]

	if xyd.models.storyListModel:getKeys() < cost then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.STORY_UNLOCK_ICON)))

		return
	end

	xyd.alertYesNo(__("PLOT_UNLOCK_CONFIRM"), function (yes)
		if yes then
			if not self.isActivity then
				xyd.models.storyListModel:reqUnlock(self.listId)
			else
				xyd.models.storyListModel:reqUnlockActivity(self.listId)
			end
		end
	end)
end

function StoryListUnlockWindow:onUnlock(event)
	local story_type = xyd.tables.mainPlotListTable:getStroyType(self.listId)
	local story_list = xyd.tables.mainPlotListTable:getMemoryPlotId(self.listId)

	if self.isActivity then
		story_type = xyd.tables.activityPlotListTable:getStroyType(self.listId)
		story_list = xyd.tables.activityPlotListTable:getMemoryPlotId(self.listId)
	end

	xyd.WindowManager.get():openWindow("story_window", {
		story_type = story_type,
		story_list = story_list
	}, function ()
		xyd.WindowManager.get():closeWindow("story_list_unlock_window")
	end)
end

function StoryListUnlockWindow:resizeToParent()
	if xyd.Global.lang == "en_en" then
		self.labelText01:Y(142)

		self.unlockBtnLabel.fontSize = 20
	elseif xyd.Global.lang == "fr_fr" then
		self.labelText01:Y(142)
	elseif xyd.Global.lang == "zh_tw" then
		self.unlockBtnLabel.height = 30
	elseif xyd.Global.lang == "ja_jp" then
		self.labelText01:Y(135)

		self.unlockBtnLabel.fontSize = 20
	elseif xyd.Global.lang == "ko_kr" then
		self.unlockBtnLabel.width = 140
	elseif xyd.Global.lang == "de_de" then
		self.labelText01:Y(135)
	end
end

return StoryListUnlockWindow
