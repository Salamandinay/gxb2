local BaseWindow = import(".BaseWindow")
local NewTrialBattlepassSelectAwardWindow = class("NewTrialBattlepassSelectAwardWindow", BaseWindow)

function NewTrialBattlepassSelectAwardWindow:ctor(name, params)
	NewTrialBattlepassSelectAwardWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS)
	self.itemList_ = {}
end

function NewTrialBattlepassSelectAwardWindow:initWindow()
	NewTrialBattlepassSelectAwardWindow.super.initWindow()
	self:getUIComponent()
	self:layout()
	self:register()
end

function NewTrialBattlepassSelectAwardWindow:register()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.sureBtn_).onClick = function ()
		if self.selectIndex_ and self.selectIndex_ > 0 then
			self.activityData:reqSelectIndex(self.selectIndex_)
			self:close()
		else
			xyd.alertTips(__("NEW_TRIAL_BATTLEPASS_TEXT11"))
		end
	end
end

function NewTrialBattlepassSelectAwardWindow:layout()
	self.sureBtnLabel_.text = __("SURE")
	self.titleLabel_.text = __("NEW_TRIAL_BATTLEPASS_SELECT_TEXT01")
	self.labelTips_.text = __("NEW_TRIAL_BATTLEPASS_SELECT_TEXT02")
	self.labelTips2_.text = __("NEW_TRIAL_BATTLEPASS_TEXT01")
	local freeOpAwards = xyd.tables.newTrialBattlePassAwardsTable:getFreeOptionalAwards(1)

	if self.activityData:getIndexChoose() > 0 then
		self.selectIndex_ = self.activityData:getIndexChoose()
		local freeOpItem = freeOpAwards[self.activityData:getIndexChoose()]
		self.selectItem_ = xyd.getItemIcon({
			showNum = false,
			notShowGetWayBtn = true,
			scale = 1,
			uiRoot = self.selectGroup_.gameObject,
			itemID = freeOpItem[1]
		})
	end

	for index, item in ipairs(freeOpAwards) do
		self.itemList_[index] = xyd.getItemIcon({
			showNum = false,
			notShowGetWayBtn = true,
			scale = 1,
			uiRoot = self.itemGroup_.gameObject,
			itemID = item[1],
			callback = function ()
				if index ~= self.selectIndex_ then
					self:chooseIndex(index)
				end
			end
		})
	end

	self.itemGroup_:Reposition()
end

function NewTrialBattlepassSelectAwardWindow:chooseIndex(index)
	self.selectIndex_ = index

	if self.selectItem_ then
		NGUITools.Destroy(self.selectItem_:getGameObject())

		self.selectItem_ = nil
	end

	local freeOpAwards = xyd.tables.newTrialBattlePassAwardsTable:getFreeOptionalAwards(1)
	self.selectItem_ = xyd.getItemIcon({
		showNum = false,
		notShowGetWayBtn = true,
		scale = 1,
		uiRoot = self.selectGroup_.gameObject,
		itemID = freeOpAwards[self.selectIndex_][1]
	})

	self:updateAwardList()
end

function NewTrialBattlepassSelectAwardWindow:updateAwardList()
	for index, item in ipairs(self.itemList_) do
		if index == self.selectIndex_ then
			item:setChoose(true)
		else
			item:setChoose(false)
		end
	end
end

function NewTrialBattlepassSelectAwardWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.sureBtn_ = winTrans:NodeByName("sureBtn").gameObject
	self.sureBtnLabel_ = winTrans:ComponentByName("sureBtn/label", typeof(UILabel))
	self.labelTips_ = winTrans:ComponentByName("labelTips", typeof(UILabel))
	self.selectGroup_ = winTrans:NodeByName("selectGroup").gameObject
	self.awardGroup_ = winTrans:NodeByName("awardGroup").gameObject
	self.labelTips2_ = self.awardGroup_:ComponentByName("labelTips", typeof(UILabel))
	self.itemGroup_ = self.awardGroup_:ComponentByName("itemGroup", typeof(UILayout))
end

return NewTrialBattlepassSelectAwardWindow
