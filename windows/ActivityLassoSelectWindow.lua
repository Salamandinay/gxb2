local ActivityLassoSelectWindow = class("ActivityLassoSelectWindow", import(".BaseWindow"))
local json = require("cjson")

function ActivityLassoSelectWindow:ctor(name, params)
	ActivityLassoSelectWindow.super.ctor(self, name, params)

	self.itemIcons = {}
	self.selectIndex = 0
	self.selectIndexs = {}
	self.parentItem = params.parentItem
	self.round = self.parentItem.info

	if self.round > 26 then
		self.round = 26
	end
end

function ActivityLassoSelectWindow:initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
	self:initSelect()
end

function ActivityLassoSelectWindow:initSelect()
	local selectIndexStr = xyd.db.misc:getValue("activity_lasso_select_index")

	if selectIndexStr then
		self.selectIndexs = json.decode(selectIndexStr)

		if self.selectIndexs[self.round .. ""] and self.selectIndexs.start_time == self.activityData.start_time then
			self.selectIndex = self.selectIndexs[self.round .. ""]

			self:selectItem()
		end
	end
end

function ActivityLassoSelectWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelWinTitle_ = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.cancelBtn = self.groupAction:NodeByName("cancelBtn").gameObject
	self.okBtn = self.groupAction:NodeByName("okBtn").gameObject
	self.okBtnWords = self.okBtn:ComponentByName("btnWords", typeof(UILabel))
	self.cancelBtnWords = self.cancelBtn:ComponentByName("btnWords", typeof(UILabel))
	self.tipsWords = self.groupAction:ComponentByName("tipsWords", typeof(UILabel))
	self.roundText = self.groupAction:ComponentByName("roundText", typeof(UILabel))
	self.iconNode = self.groupAction:NodeByName("groupItem/iconNode").gameObject
	self.awardsContainer = self.groupAction:NodeByName("awardsContainer").gameObject
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LASSO)
end

function ActivityLassoSelectWindow:layout()
	self.labelWinTitle_.text = __("ACTIVITY_HALLOWEEN_AWARD")
	self.okBtnWords.text = __("SURE")
	self.cancelBtnWords.text = __("CANCEL_2")
	local round = self.round

	if self.round < self.activityData.detail.round then
		round = self.activityData.detail.round
	end

	self.roundText.text = __("ACTIVITY_ICE_SECRET_ROUNDS", round)
	self.tipsWords.text = __("FAIR_ARENA_NOTES_PRESS")
	local awards = xyd.tables.activityLassoAwardsTable:getAwards(self.round)

	for k, v in ipairs(awards) do
		local itemIcon = xyd.getItemIcon({
			noClick = false,
			uiRoot = self.awardsContainer,
			itemID = v[1],
			num = v[2]
		})

		table.insert(self.itemIcons, itemIcon)

		UIEventListener.Get(itemIcon:getGameObject()).onClick = handler(self, function ()
			self.selectIndex = k

			self:selectItem()
		end)
		UIEventListener.Get(itemIcon:getGameObject()).onLongPress = handler(self, function ()
			local params = {
				notShowGetWayBtn = true,
				show_has_num = true,
				itemID = v[1],
				itemNum = v[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			xyd.WindowManager.get():openWindow("item_tips_window", params)
		end)
	end
end

function ActivityLassoSelectWindow:selectItem()
	for k, v in ipairs(self.itemIcons) do
		if k == self.selectIndex then
			v:setChoose(true)
		else
			v:setChoose(false)
		end
	end

	NGUITools.DestroyChildren(self.iconNode.transform)

	local awards = xyd.tables.activityLassoAwardsTable:getAwards(self.round)

	if self.selectIndex < 0 or self.selectIndex > #awards then
		return
	end

	local itemIcon = xyd.getItemIcon({
		show_has_num = true,
		noClickSelected = true,
		noClick = false,
		notShowGetWayBtn = true,
		uiRoot = self.iconNode,
		itemID = awards[self.selectIndex][1],
		num = awards[self.selectIndex][2],
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})
end

function ActivityLassoSelectWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.cancelBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.okBtn.gameObject).onClick = handler(self, function ()
		self:setBigAward()
	end)
end

function ActivityLassoSelectWindow:setBigAward()
	if self.selectIndexs.start_time ~= self.activityData.start_time then
		self.selectIndexs = {}
	end

	self.selectIndexs[self.round .. ""] = self.selectIndex
	local arr = {}

	for k, v in pairs(self.selectIndexs) do
		arr[k .. ""] = tonumber(v) or 0
	end

	arr.start_time = self.activityData.start_time

	if self.selectIndex > 0 then
		xyd.db.misc:setValue({
			key = "activity_lasso_select_index",
			value = json.encode(arr)
		})
		self.parentItem:updateLayout()
		self:close()
	else
		xyd.alertTips(__("ACTIVITY_LASSO_TIPS"))
	end
end

return ActivityLassoSelectWindow
