local BaseWindow = import(".BaseWindow")
local ActivityAllStarsPrayAwardGotWindow = class("ActivityAllStarsPrayAwardGotWindow", BaseWindow)

function ActivityAllStarsPrayAwardGotWindow:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.info = params.info

	dump(self.info)
end

function ActivityAllStarsPrayAwardGotWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:layout()
end

function ActivityAllStarsPrayAwardGotWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.groupContent = self.groupAction:NodeByName("groupContent").gameObject
	self.scrollView = self.groupContent:ComponentByName("scrollView", typeof(UIScrollView))
	self.groupAwards = self.scrollView:NodeByName("groupAwards").gameObject
end

function ActivityAllStarsPrayAwardGotWindow:layout()
	self.labelTitle.text = __("ACTIVITY_PARY_ALL_AWARDS")

	for itemID, num in pairs(self.info) do
		xyd.getItemIcon({
			show_has_num = true,
			showGetWays = false,
			notShowGetWayBtn = true,
			itemID = itemID,
			num = num,
			uiRoot = self.groupAwards.gameObject,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self.groupAwards:GetComponent(typeof(UIGrid)):Reposition()
end

return ActivityAllStarsPrayAwardGotWindow
