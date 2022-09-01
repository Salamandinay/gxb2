local CommonWrapPreviewAwardWindow = class("CommonWrapPreviewAwardWindow", import(".BaseWindow"))
local CommonWrapPreviewAwardItem = class("CommonWrapPreviewAwardItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function CommonWrapPreviewAwardWindow:ctor(name, params)
	CommonWrapPreviewAwardWindow.super.ctor(self, name, params)

	self.title_text = params.title_text
	self.infos = {}
	local tempTable = params.infos

	for i = 1, #tempTable do
		table.insert(self.infos, tempTable[i])
	end
end

function CommonWrapPreviewAwardWindow:initWindow()
	self:getUIComponent()
	self:initUI()
	self:register()
end

function CommonWrapPreviewAwardWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.groupAction = groupAction
	self.titleLabel = self.groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.scrollerGroup = self.groupAction:NodeByName("scrollerGroup").gameObject
	self.item = self.scrollerGroup:ComponentByName("item", typeof(UISprite))
	self.scroller = self.scrollerGroup:NodeByName("scroller").gameObject
	self.scrollView = self.scrollerGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
end

function CommonWrapPreviewAwardWindow:initUI()
	if self.title_text then
		self.titleLabel.text = self.title_text
	end

	if self.wrapContent == nil then
		local wrapContent = self.scroller:ComponentByName("itemGroup", typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.item.gameObject, CommonWrapPreviewAwardItem, self)
	end

	self.wrapContent:setInfos(self.infos, {})
	self.scrollView:ResetPosition()
end

function CommonWrapPreviewAwardWindow:register()
	CommonWrapPreviewAwardWindow.super.register(self)
end

function CommonWrapPreviewAwardItem:ctor(go, parent)
	CommonWrapPreviewAwardItem.super.ctor(self, go, parent)

	self.parent = parent
end

function CommonWrapPreviewAwardItem:initUI()
	self.labelDesc = self.go:ComponentByName("labelDesc", typeof(UILabel))
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.itemGroupLayout = self.go:ComponentByName("itemGroup", typeof(UILayout))
	self.icons = {}
end

function CommonWrapPreviewAwardItem:updateInfo()
	self.descText = self.data.descText
	self.items = self.data.items
	self.labelDesc.text = self.descText

	for i = 1, math.max(#self.items, #self.icons) do
		local item = self.items[i]

		if item then
			local params = {
				show_has_num = true,
				hideText = false,
				scale = 0.7037037037037037,
				uiRoot = self.itemGroup,
				itemID = item[1],
				num = item[2],
				dragScrollView = self.parent.scrollView
			}

			if not self.icons[i] then
				self.icons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.icons[i]:setInfo(params)
			end

			self.icons[i]:SetActive(true)
		else
			self.icons[i]:SetActive(false)
		end
	end
end

return CommonWrapPreviewAwardWindow
