local ActivityResidentReturnGrowWindow = class("ActivityResidentReturnGrowWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local ShowItem = class("ShowItem", import("app.components.CopyComponent"))

function ActivityResidentReturnGrowWindow:ctor(name, params)
	ActivityResidentReturnGrowWindow.super.ctor(self, name, params)
end

function ActivityResidentReturnGrowWindow:initWindow()
	self.isOpenMainWindow = true

	self:getUIComponent()
	self:reSize()
	self:layout()
	self:registerEvent()
	self:checkRed()
end

function ActivityResidentReturnGrowWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.logoImg = self.groupAction:ComponentByName("logoImg", typeof(UISprite))
	self.timeGroup = self.logoImg:NodeByName("timeGroup").gameObject
	self.timeGroup_UILayout = self.logoImg:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLeftText = self.timeGroup:ComponentByName("timeLeftText", typeof(UILabel))
	self.timeRightText = self.timeGroup:ComponentByName("timeRightText", typeof(UILabel))
	self.timeGroupBg = self.logoImg:ComponentByName("timeGroupBg", typeof(UISprite))
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.downConBg = self.downCon:ComponentByName("downConBg", typeof(UISprite))
	self.scroll = self.downCon:NodeByName("scroll").gameObject
	self.scroll_UIScrollView = self.downCon:ComponentByName("scroll", typeof(UIScrollView))
	self.valueGroup = self.scroll:NodeByName("valueGroup").gameObject
	self.valueGroup_UILayout = self.scroll:ComponentByName("valueGroup", typeof(UILayout))
	self.helpBtn = self.groupAction:NodeByName("helpBtn").gameObject
	self.show_item = self.downCon:NodeByName("show_item").gameObject
end

function ActivityResidentReturnGrowWindow:reSize()
	self:resizePosY(self.downCon, -264, -418)
	self:resizePosY(self.groupAction.gameObject, 0, 81)
end

function ActivityResidentReturnGrowWindow:resizePosY(obj, y_short, y_phoneX)
	obj:Y(y_short + (y_phoneX - y_short) * self.scale_num_contrary)
end

function ActivityResidentReturnGrowWindow:checkRed()
	local localGrowAddTime = xyd.db.misc:getValue("activity_resident_return_growadd_red_time")

	if not localGrowAddTime or localGrowAddTime and not xyd.isSameDay(tonumber(localGrowAddTime), xyd.getServerTime()) then
		xyd.db.misc:setValue({
			key = "activity_resident_return_growadd_red_time",
			value = xyd.getServerTime()
		})
	end

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN)

	if activityData then
		activityData:setRedMarkState(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_1)
	end
end

function ActivityResidentReturnGrowWindow:layout()
	self:initTop()
	xyd.setUISpriteAsync(self.logoImg, nil, "resident_return_grow_logo_" .. xyd.Global.lang, nil, )

	for i = 1, #xyd.tables.activityReturn2AddTable:getIDs() do
		local tmp = NGUITools.AddChild(self.valueGroup.gameObject, self.show_item.gameObject)
		local item = ShowItem.new(tmp, i, self)
	end

	self.valueGroup_UILayout:Reposition()
	self:waitForFrame(1, function ()
		self.scroll_UIScrollView:ResetPosition()
	end)
	self:initTimeShow()
end

function ActivityResidentReturnGrowWindow:initTop()
	local function callback()
		xyd.WindowManager.get():openWindow("activity_resident_return_main_window")
		xyd.WindowManager:get():closeWindow(self.name_)
	end

	self.windowTop = WindowTop.new(self.window_, self.name_, 50, nil, callback)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)
end

function ActivityResidentReturnGrowWindow:initTimeShow()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN)
	local startTime = activityData:getReturnStartTime()
	self.timeRightText.text = __("END")
	local duration = startTime + xyd.tables.miscTable:getNumber("activity_return2_time1", "value") - xyd.getServerTime()

	if duration < 0 then
		self.timeLeftText.text = "00:00:00"
	else
		local timeCount = import("app.components.CountDown").new(self.timeLeftText)

		timeCount:setInfo({
			duration = duration,
			callback = handler(self, self.overTime)
		})
	end

	self.timeGroup_UILayout:Reposition()
end

function ActivityResidentReturnGrowWindow:overTime()
	self.timeLeftText.text = "00:00:00"

	self.timeGroup_UILayout:Reposition()
end

function ActivityResidentReturnGrowWindow:registerEvent()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_RETURN2_ADD_TEXT02"
		})
	end)
end

function ShowItem:ctor(goItem, index, parent)
	self.goItem_ = goItem
	self.parent = parent
	self.showItemBg = self.goItem_:ComponentByName("showItemBg", typeof(UISprite))
	self.showText = self.goItem_:ComponentByName("showText", typeof(UILabel))
	self.showUpIcon = self.goItem_:ComponentByName("showUpIcon", typeof(UISprite))

	self:initItem(index)
	self:initBaseInfo(index)
end

function ShowItem:initBaseInfo(index)
	local multiple = xyd.tables.activityReturn2AddTable:getMultiple(index)

	xyd.setUISpriteAsync(self.showUpIcon, nil, "common_tips_up_" .. multiple, nil, )

	local str_key = xyd.tables.activityReturn2AddTable:getTranslation(index)
	self.showText.text = __(str_key)

	if self.showText.width > 350 then
		self.showText.overflowMethod = UILabel.Overflow.ShrinkContent
		self.showText.width = 350
		self.showText.height = 40
	end
end

function ShowItem:initItem(index)
	UIEventListener.Get(self.showItemBg.gameObject).onClick = handler(self, function ()
		xyd.goWay(xyd.tables.activityReturn2AddTable:getGetwayId(index), nil, , function ()
		end)
	end)
end

return ActivityResidentReturnGrowWindow
