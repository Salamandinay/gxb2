local ExploreTrainingAttrPreviewWindow = class("ExploreTrainingAttrPreviewWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local AttrItem = class("AttrItem")
local trainTable = xyd.tables.exploreTrainingTable

function ExploreTrainingAttrPreviewWindow:ctor(name, params)
	ExploreTrainingAttrPreviewWindow.super.ctor(self, name, params)
end

function ExploreTrainingAttrPreviewWindow:initWindow()
	self:getUIComponent()
	self:layout()
	ExploreTrainingAttrPreviewWindow.super.register(self)
end

function ExploreTrainingAttrPreviewWindow:getUIComponent()
	local groupMain = self.window_:NodeByName("groupMain").gameObject
	self.closeBtn = groupMain:NodeByName("closeBtn").gameObject
	self.labelTitle = groupMain:ComponentByName("labelTitle", typeof(UILabel))
	self.scroller_ = groupMain:ComponentByName("scroller_", typeof(UIScrollView))
	local attrItem = groupMain:NodeByName("attrItem").gameObject
	local wrapContent = self.scroller_:ComponentByName("groupContent", typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scroller_, wrapContent, attrItem, AttrItem, self)
end

function ExploreTrainingAttrPreviewWindow:layout()
	self.labelTitle.text = __("TRAVEL_MAIN_TEXT64")
	local maxLv = trainTable:getLvMax(1)
	local info = {}

	for i = 1, maxLv do
		info[i] = i
	end

	self.wrapContent:setInfos(info)
end

function AttrItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	for i = 1, 6 do
		self["label_" .. i] = go:ComponentByName("label_" .. i, typeof(UILabel))
	end

	self.bg = go:NodeByName("bg").gameObject
end

function AttrItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.label_1.text = info

	self.bg:SetActive(info % 2 == 1)

	for i = 1, 5 do
		self["label_" .. i + 1].text = trainTable:getEffectString(i, info)
	end
end

function AttrItem:getGameObject()
	return self.go
end

return ExploreTrainingAttrPreviewWindow
