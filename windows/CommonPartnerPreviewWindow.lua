local BaseWindow = import(".BaseWindow")
local CommonPartnerPreviewWindow = class("CommonPartnerPreviewWindow", BaseWindow)

function CommonPartnerPreviewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.partnerTableIDs = params.partnerTableIDs
	self.titleText = params.titleText
	self.windowTitleText = params.windowTitleText
	self.iconCallback = params.iconCallback
	self.tipsText = params.tipsText
end

function CommonPartnerPreviewWindow:initWindow()
	self.icons = {}

	self:getUIComponent()
	CommonPartnerPreviewWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function CommonPartnerPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.winBg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelWindowTitle = self.groupAction:ComponentByName("labelWindowTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.groupMain = self.groupAction:NodeByName("groupMain").gameObject
	self.groupMaterial = self.groupMain:NodeByName("groupMaterial").gameObject
	self.bg = self.groupMaterial:ComponentByName("bg", typeof(UISprite))
	self.fgx = self.groupMaterial:ComponentByName("fgx", typeof(UISprite))
	self.labelTitle = self.groupMaterial:ComponentByName("labelTitle", typeof(UILabel))
	self.itemGroup = self.groupMaterial:NodeByName("itemGroup").gameObject
	self.itemGroupGrid = self.groupMaterial:ComponentByName("itemGroup", typeof(UIGrid))
	self.labelTips = self.groupMaterial:ComponentByName("bottomGroup/labelTips", typeof(UILabel))
end

function CommonPartnerPreviewWindow:initUIComponent()
	self.labelWindowTitle.text = self.windowTitleText
	self.labelTitle.text = self.titleText

	for index, tableID in ipairs(self.partnerTableIDs) do
		local params = {
			noClickSelected = true,
			noClick = true,
			uiRoot = self.itemGroup,
			itemID = tableID,
			callback = self.iconCallback
		}

		if not self.icons[index] then
			self.icons[index] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.icons[index]:setInfo(params)
		end
	end

	self.itemGroupGrid:Reposition()

	local tipsTextHeight = 0

	if self.tipsText then
		self.labelTips.text = self.tipsText
		tipsTextHeight = self.labelTips.height + 5
	end

	self.bg.height = 178 + (math.ceil(#self.partnerTableIDs / 5) - 1) * 127
	self.winBg.height = 264 + (math.ceil(#self.partnerTableIDs / 5) - 1) * 127 + tipsTextHeight
end

return CommonPartnerPreviewWindow
