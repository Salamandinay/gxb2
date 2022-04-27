local BaseWindow = import(".BaseWindow")
local AwardPreviewWindow = class("AwardPreviewWindow", BaseWindow)

function AwardPreviewWindow:ctor(name, params)
	AwardPreviewWindow.super.ctor(self, name, params)

	self.awards = params.awards
	self.title_ = params.title or __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.hasGotten = params.hasGotten or false
end

function AwardPreviewWindow:initWindow()
	AwardPreviewWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function AwardPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:ComponentByName("groupAction", typeof(UIWidget))
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.itemGroup = groupAction:NodeByName("itemGroup").gameObject
end

function AwardPreviewWindow:initUIComponent()
	self.titleLabel.text = self.title_

	for i = 1, #self.awards do
		local data = self.awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.8888888888888888,
				uiRoot = self.itemGroup,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			if self.hasGotten then
				item:setChoose(true)
			end
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function AwardPreviewWindow:register()
	AwardPreviewWindow.super.register(self)
end

return AwardPreviewWindow
