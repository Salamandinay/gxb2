local InvitationDailyGiftWindow = class("InvitationDailyGiftWindow", import(".BaseWindow"))

function InvitationDailyGiftWindow:ctor(name, params)
	InvitationDailyGiftWindow.super.ctor(self, name, params)

	self.textSenderName = params.textSenderName
	self.textReceiverName = params.textReceiverName
	self.icons = {}
end

function InvitationDailyGiftWindow:initWindow()
	self:getUIComponent()
	self:initUI()
	self:register()
end

function InvitationDailyGiftWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.groupAction = groupAction
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.mainGroup = self.groupAction:NodeByName("mainGroup").gameObject
	self.labelTips = self.mainGroup:ComponentByName("labelTips", typeof(UILabel))
	self.labelContent = self.mainGroup:ComponentByName("labelContent", typeof(UILabel))
	self.labelReceiverName = self.mainGroup:ComponentByName("labelReceiverName", typeof(UILabel))
	self.labelSenderName = self.mainGroup:ComponentByName("labelSenderName", typeof(UILabel))
	self.itemGroup = self.mainGroup:NodeByName("itemGroup").gameObject
	self.itemGroupLayout = self.mainGroup:ComponentByName("itemGroup", typeof(UILayout))
	self.btnSure = self.mainGroup:NodeByName("btnSure").gameObject
	self.labelSure = self.btnSure:ComponentByName("labelSure", typeof(UILabel))
end

function InvitationDailyGiftWindow:initUI()
	self.labelSure.text = __("INVITATION_GIFT_TEXT01")
	self.labelTips.text = __("INVITATION_TEXT14")
	self.labelSenderName.text = self.textSenderName
	self.labelReceiverName.text = self.textReceiverName
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_INVITATION_SENIOR)
	local textContentArr = {}
	local ids = xyd.tables.activityInvitationGiftTextTable:getIDs()
	local selfLev = xyd.models.backpack:getLev()

	for i = 1, #ids do
		local id = ids[i]
		local lev = xyd.tables.activityInvitationGiftTextTable:getLv(id)

		if lev <= selfLev then
			table.insert(textContentArr, xyd.tables.activityInvitationGiftTextTable:getText(id))
		end
	end

	self.labelContent.text = textContentArr[xyd.random(1, #textContentArr, {
		int = true
	})]
	local items = xyd.tables.miscTable:split2Cost("invitation_daily_gift", "value", "|#")

	for i = 1, #items do
		local item = items[i]

		if item then
			local params = {
				show_has_num = true,
				hideText = false,
				scale = 0.7037037037037037,
				uiRoot = self.itemGroup,
				itemID = item[1],
				num = item[2]
			}

			if not self.icons[i] then
				self.icons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.icons[i]:setInfo(params)
			end

			self.icons[i]:SetActive(true)
		end
	end

	self.itemGroupLayout:Reposition()
end

function InvitationDailyGiftWindow:register()
	InvitationDailyGiftWindow.super.register(self)

	UIEventListener.Get(self.btnSure.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function InvitationDailyGiftWindow:willClose()
	InvitationDailyGiftWindow.super.willClose(self)
	self.activityData:reqGetDailyAward()
end

return InvitationDailyGiftWindow
