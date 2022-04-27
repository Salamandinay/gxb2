local BaseWindow = import(".BaseWindow")
local CommonItemAwardWindow = class("CommonItemAwardWindow", BaseWindow)
local CommonAwardItem = class("CommonAwardItem", import("app.components.CopyComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function CommonItemAwardWindow:ctor(name, params)
	CommonItemAwardWindow.super.ctor(self, name, params)

	self.fixed_awards = params.fixed_awards
	self.probability_awards = params.probability_awards
	self.title_text = params.title_text
	self.explain1_text = params.explain1_text
	self.explain2_text = params.explain2_text
end

function CommonItemAwardWindow:initWindow()
	CommonItemAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function CommonItemAwardWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.labelTitle = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.label1 = winTrans:ComponentByName("label1", typeof(UILabel))
	self.label2 = winTrans:ComponentByName("label2", typeof(UILabel))
	self.awardIcon = winTrans:NodeByName("awardIcon").gameObject
	self.awardIcon_UILayout = winTrans:ComponentByName("awardIcon", typeof(UILayout))
	self.scroller = winTrans:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.itemGroup_UIWrapContent = self.scroller:ComponentByName("itemGroup", typeof(UIWrapContent))
	self.dropItem = winTrans:NodeByName("scroller/dropItem").gameObject
	self.bg2_ = winTrans:ComponentByName("bg2_", typeof(UISprite))
	self.Bg_ = winTrans:ComponentByName("Bg_", typeof(UISprite))
	self.wrapContent_ = FixedMultiWrapContent.new(self.scroller, self.itemGroup_UIWrapContent, self.dropItem, CommonAwardItem, self)
end

function CommonItemAwardWindow:initUIComponent()
	self.labelTitle.text = self.title_text
	self.label1.text = self.explain1_text
	self.label2.text = self.explain2_text

	for i in pairs(self.fixed_awards) do
		xyd.getItemIcon({
			show_has_num = false,
			uiRoot = self.awardIcon,
			itemID = tonumber(self.fixed_awards[i][1]),
			num = tonumber(self.fixed_awards[i][2])
		})
	end

	self.awardIcon_UILayout:Reposition()

	if #self.probability_awards <= 5 then
		self.bg2_.height = 154
		self.Bg_.height = 479
	end

	self.wrapContent_:setInfos(self.probability_awards, {})
	self:waitForFrame(1, function ()
		self.scroller:ResetPosition()
	end)
end

function CommonAwardItem:ctor(go, parent)
	CommonAwardItem.super.ctor(self, go, parent)
end

function CommonAwardItem:initUI()
	local go = self.go
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.label = go:ComponentByName("label", typeof(UILabel))
end

function CommonAwardItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.item_id and self.item_num and info and self.item_id == info[1] and self.item_num == info[2] then
		return
	end

	self.info = info
	self.item_id = self.info[1]
	self.item_num = self.info[2]

	if info[3] then
		self.label.text = tostring(info[3])
	end

	if not self.icon_ then
		self.icon_ = xyd.getItemIcon({
			show_has_num = false,
			noClickSelected = true,
			uiRoot = self.groupIcon,
			itemID = info[1],
			num = info[2]
		})
	else
		self.icon_:setInfo({
			show_has_num = false,
			noClickSelected = true,
			itemID = info[1],
			num = info[2]
		})
	end

	self.icon_:AddUIDragScrollView()
end

return CommonItemAwardWindow
