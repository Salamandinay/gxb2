local BaseWindow = import(".BaseWindow")
local ActivityAwardPreViewWindow = class("ActivityAwardPreViewWindow", BaseWindow)

function ActivityAwardPreViewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.awards = params.awards
	self.title_ = params.title
	self.des = params.des
	self.hasGotten = params.hasGotten or false
end

function ActivityAwardPreViewWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setText()
	self:setItem()
	self.eventProxy_:addEventListener(xyd.event.WINDOW_WILL_OPEN, function (event)
		local windowName = event.params.windowName

		if windowName ~= "item_tips_window" then
			xyd.closeWindow("activity_award_preview_window")
		end
	end)
end

function ActivityAwardPreViewWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:ComponentByName("groupAction", typeof(UIWidget))
	self.groupAward = self.groupAction:ComponentByName("groupAward", typeof(UIWidget))
	self.titleLabel = self.groupAward:ComponentByName("titleLabel", typeof(UILabel))
	self.desLabel = self.groupAward:ComponentByName("desLabel", typeof(UILabel))
	self.itemGroup = self.groupAward:NodeByName("itemGroup").gameObject
end

function ActivityAwardPreViewWindow:setText()
	self.titleLabel.text = self.title_ or __("ACTIVITY_AWARD_PREVIEW_TITLE")

	if self.des then
		self.desLabel:SetActive(true)

		self.desLabel.text = self.des
		self.groupAward.height = 297

		self.itemGroup:Y(-199)
	else
		self.desLabel:SetActive(false)
	end
end

function ActivityAwardPreViewWindow:setItem()
	local awardsLen = #self.awards

	if self.des then
		if awardsLen < 3 then
			self.groupAward.width = 580
			self.desLabel.width = 500
		end
	elseif awardsLen == 1 or awardsLen == 2 then
		self.groupAward.width = 350
	elseif awardsLen == 3 then
		self.groupAward.width = 410
	elseif awardsLen == 4 then
		self.groupAward.width = 538
	elseif awardsLen == 5 then
		self.groupAward.width = 676
	end

	for i = 1, #self.awards do
		local data = self.awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = {
				show_has_num = true,
				isShowSelected = false,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				clickCloseWnd = {
					"activity_award_preview_window"
				},
				uiRoot = self.itemGroup
			}
			local icon = xyd.getItemIcon(item)

			if not self.des then
				icon:setScale(97 / xyd.DEFAULT_ITEM_SIZE)
			end

			if self.hasGotten then
				icon:setChoose(true)
			end
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

return ActivityAwardPreViewWindow
