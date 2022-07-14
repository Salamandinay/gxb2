local BaseWindow = import(".BaseWindow")
local ActivitySpaceExplporeAwardedWindow = class("ActivitySpaceExplporeAwardedWindow", BaseWindow)
local AwardItemNode = class("ProbabilityRender", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local HeroIcon = import("app.components.HeroIcon")
local ItemIcon = import("app.components.ItemIcon")

function ActivitySpaceExplporeAwardedWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = params.data or {}
	self.winTitle = params.winTitle
	self.labelNone = params.labelNone
end

function ActivitySpaceExplporeAwardedWindow:initWindow()
	ActivitySpaceExplporeAwardedWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function ActivitySpaceExplporeAwardedWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.scrollView = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.itemGroup = winTrans:NodeByName("scrollView/itemGroup").gameObject
	self.itemNode = winTrans:NodeByName("scrollView/itemNode").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.itemNode, AwardItemNode, self)
	self.noneGroup = winTrans:NodeByName("noneGroup").gameObject
	self.noneImg = self.noneGroup:ComponentByName("noneImg", typeof(UISprite))
	self.noneLabel = self.noneGroup:ComponentByName("noneLabel", typeof(UILabel))
end

function ActivitySpaceExplporeAwardedWindow:initUIComponent()
	self.titleLabel.text = self.winTitle or __("SPACE_EXPLORE_TEXT_17")
	self.noneLabel.text = __("ACTIVITY_SPACE_AWARD_NONE_TEXT")

	if self.labelNone then
		self.noneLabel.text = self.labelNone
	end

	local collection = {}

	for item_id, num in pairs(self.data) do
		table.insert(collection, {
			item_id = item_id,
			num = num
		})
	end

	table.sort(collection, function (a, b)
		return tonumber(a.item_id) < tonumber(b.item_id)
	end)
	self.wrapContent:setInfos(collection, {})

	if #collection == 0 then
		self.noneGroup.gameObject:SetActive(true)
	end

	self.scrollView:ResetPosition()
end

function ActivitySpaceExplporeAwardedWindow:register()
	ActivitySpaceExplporeAwardedWindow.super.register(self)
end

function AwardItemNode:ctor(go, parent)
	AwardItemNode.super.ctor(self, go, parent)
end

function AwardItemNode:initUI()
	self.itemNode = ItemIcon.new(self.go)
	self.heroNode = HeroIcon.new(self.go)

	self.itemNode:SetActive(false)
	self.heroNode:SetActive(false)
end

function AwardItemNode:setDragScrollView()
end

function AwardItemNode:updateInfo()
	self.itemID = self.data.item_id
	self.num = self.data.num
	local params = {
		scale = 0.7962962962962963,
		itemID = self.itemID,
		num = self.num,
		dragScrollView = self.parent.scrollView
	}
	local type_ = xyd.tables.itemTable:getType(self.itemID)

	if type_ ~= xyd.ItemType.HERO_DEBRIS and type_ ~= xyd.ItemType.HERO and type_ ~= xyd.ItemType.HERO_RANDOM_DEBRIS and type_ ~= xyd.ItemType.SKIN then
		self.itemNode:SetActive(true)
		self.heroNode:SetActive(false)
		self.itemNode:setInfo(params)
	else
		self.itemNode:SetActive(false)
		self.heroNode:SetActive(true)
		self.heroNode:setInfo(params)
	end
end

return ActivitySpaceExplporeAwardedWindow
