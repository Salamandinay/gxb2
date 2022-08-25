local ActivityLegendarySkinDetailWindow = class("ActivityLegendarySkinDetailWindow", import(".BaseWindow"))
local AwardRateItem = class("AwardRateItem", import("app.components.CopyComponent"))

function ActivityLegendarySkinDetailWindow:ctor(name, params)
	ActivityLegendarySkinDetailWindow.super.ctor(self, name, params)
end

function ActivityLegendarySkinDetailWindow:initWindow()
	self:getUIComponent()
	ActivityLegendarySkinDetailWindow.super.initWindow(self)
	self:reSize()
	self:register()
	self:layout()
end

function ActivityLegendarySkinDetailWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLable = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("close_button").gameObject
	self.scrollView = self.groupAction:ComponentByName("award_scroller", typeof(UIScrollView))
	self.awardItem1 = self.groupAction:NodeByName("award_scroller/award_item_1").gameObject
	self.awardItem2 = self.groupAction:NodeByName("award_scroller/award_item_2").gameObject
	self.awardItem3 = self.groupAction:NodeByName("award_scroller/award_item_3").gameObject
	self.iconItem = self.groupAction:NodeByName("icon_item").gameObject

	self.iconItem:SetActive(false)
end

function ActivityLegendarySkinDetailWindow:reSize()
end

function ActivityLegendarySkinDetailWindow:register()
	ActivityLegendarySkinDetailWindow.super.register(self)
end

function ActivityLegendarySkinDetailWindow:layout()
	self.titleLable.text = __("ACTIVITY_LEGENDARY_SKIN_TEXT01")

	self:initAwardItem(1, self.awardItem1)
	self:initAwardItem(2, self.awardItem2)
	self:initAwardItem(3, self.awardItem3)
end

function ActivityLegendarySkinDetailWindow:initAwardItem(id, go)
	local titleLabel = go:ComponentByName("title_bg/title_label", typeof(UILabel))

	if xyd.Global.lang == "fr_fr" then
		titleLabel.fontSize = 16
	elseif xyd.Global.lang == "de_de" or xyd.Global.lang == "en_en" then
		titleLabel.fontSize = 18
	end

	local titleBg = go:ComponentByName("title_bg", typeof(UISprite))
	local bg = go:ComponentByName("img_bg", typeof(UISprite))

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "ja_jp" or xyd.Global.lang == "de_de" then
		titleBg.width = 250

		titleBg:X(-190)
	elseif xyd.Global.lang == "en_en" then
		titleBg:X(-220)

		titleBg.width = 180
	end

	local desLabel = go:ComponentByName("des_label", typeof(UILabel))
	local awardList = go:NodeByName("list_grid").gameObject
	titleLabel.text = __("ACTIVITY_LEGENDARY_SKIN_TEXT0" .. id * 2)
	desLabel.text = __("ACTIVITY_LEGENDARY_SKIN_TEXT0" .. id * 2 + 1)
	local awardsData = xyd.tables.activityLengarySkinAwardTable:getBasicAward(id)

	dump(awardsData, "awardsData")
	self:initItems(awardList, awardsData, self.scrollView)
end

function ActivityLegendarySkinDetailWindow:initItems(parentGo, awardsData, scrollView)
	for _, data in ipairs(awardsData) do
		local go = NGUITools.AddChild(parentGo, self.iconItem)
		local rateItem = AwardRateItem.new(go, self)

		rateItem:setInfo(data, scrollView)
		go:SetActive(true)
	end

	local grid = parentGo:GetComponent(typeof(UIGrid))

	grid:Reposition()
end

function AwardRateItem:ctor(goItem, parent)
	AwardRateItem.super.ctor(self, goItem)

	self.parent = parent
end

function AwardRateItem:initUI()
	self.rateLabel = self.go:ComponentByName("rate_label", typeof(UILabel))
	self.iconNode = self.go:NodeByName("item_group").gameObject
end

function AwardRateItem:setInfo(info, scrollView)
	self.rateLabel.text = info.prob * 100 .. "%"
	local itemData = info.itemData

	xyd.getItemIcon({
		scale = 0.7962962962962963,
		uiRoot = self.iconNode,
		itemID = itemData[1],
		num = itemData[2],
		dragScrollView = scrollView
	})

	if info.prob >= 1 then
		self.rateLabel.gameObject:SetActive(false)
	else
		self.rateLabel.gameObject:SetActive(true)
	end
end

return ActivityLegendarySkinDetailWindow
