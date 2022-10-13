local BaseWindow = import(".BaseWindow")
local Activity2LoveDetailWindow = class("Activity2LoveDetailWindow", BaseWindow)

function Activity2LoveDetailWindow:ctor(name, params)
	Activity2LoveDetailWindow.super.ctor(self, name, params)

	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_2LOVE)
end

function Activity2LoveDetailWindow:initWindow()
	self:getUIComponent()
	Activity2LoveDetailWindow.super.initWindow(self)
	self:layout()
	self:register()
end

function Activity2LoveDetailWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.groupContent = self.groupAction:NodeByName("groupContent").gameObject
	self.scrollView = self.groupContent:ComponentByName("scrollView", typeof(UIScrollView))
	self.groupAwards = self.scrollView:NodeByName("groupAwards").gameObject
end

function Activity2LoveDetailWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

function Activity2LoveDetailWindow:layout()
	self.labelTitle.text = __("ACTIVITY_2LOVE_TEXT06")
	local openedCard = {}

	for i = 1, 16 do
		openedCard[self.activityData_.detail_.ids[i]] = 1
	end

	for id = 1, 8 do
		local award = xyd.tables.activity2LoveAwardsTable:getAward(id)
		local icon = xyd.getItemIcon({
			show_has_num = true,
			showGetWays = false,
			scale = 0.7962962962962963,
			notShowGetWayBtn = true,
			itemID = award[1],
			num = award[2],
			uiRoot = self.groupAwards.gameObject,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		if openedCard[id] == 1 and openedCard[id + 8] == 1 then
			icon:setChoose(true)
		end
	end

	self.groupAwards:GetComponent(typeof(UIGrid)):Reposition()
end

return Activity2LoveDetailWindow
