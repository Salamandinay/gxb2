local StarryRateDetailWindow = class("StarryRateDetailWindow", import(".BaseWindow"))
local AwardRateItem = class("AwardRateItem", import("app.components.CopyComponent"))
local StarryAltarTable = xyd.tables.starryAltarTable
local NORMAL_SUMMON_ID = 1
local ACT_SUMMON_ID = 2

function StarryRateDetailWindow:ctor(name, params)
	StarryRateDetailWindow.super.ctor(self, name, params)
end

function StarryRateDetailWindow:initWindow()
	self:getUIComponent()
	StarryRateDetailWindow.super.initWindow(self)
	self:reSize()
	self:register()
	self:layout()
end

function StarryRateDetailWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLable = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("close_button").gameObject
	self.awardItem1 = self.groupAction:NodeByName("award_item_1").gameObject
	self.awardItem2 = self.groupAction:NodeByName("award_item_2").gameObject
	self.awardItem3 = self.groupAction:NodeByName("award_item_3").gameObject
	self.iconItem = self.groupAction:NodeByName("icon_item").gameObject

	self.iconItem:SetActive(false)
end

function StarryRateDetailWindow:reSize()
end

function StarryRateDetailWindow:register()
	StarryRateDetailWindow.super.register(self)
end

function StarryRateDetailWindow:layout()
	self.titleLable.text = __("STARRY_ALTAR_TEXT06")

	self:initAwardItem(1, self.awardItem1)
	self:initAwardItem(2, self.awardItem2)
	self:initAwardItemBig(3, self.awardItem3)
end

function StarryRateDetailWindow:initAwardItem(id, go)
	local titleLabel = go:ComponentByName("title_bg/title_label", typeof(UILabel))

	if xyd.Global.lang == "fr_fr" then
		titleLabel.fontSize = 16
	elseif xyd.Global.lang == "de_de" or xyd.Global.lang == "en_en" then
		titleLabel.fontSize = 18
	end

	local titleBg = go:ComponentByName("title_bg", typeof(UISprite))

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "ja_jp" or xyd.Global.lang == "de_de" then
		titleBg:X(-190)

		titleBg.width = 250
	elseif xyd.Global.lang == "en_en" then
		titleBg:X(-220)

		titleBg.width = 180
	end

	local desLabel = go:ComponentByName("des_label", typeof(UILabel))

	if xyd.Global.lang == "fr_fr" then
		desLabel.width = 600
		desLabel.height = 50
	end

	local awardGroup = go:NodeByName("award_group").gameObject

	if xyd.Global.lang ~= "zh_tw" then
		awardGroup:Y(-52)
	end

	local weight = StarryAltarTable:getWeight(NORMAL_SUMMON_ID)
	local awardsData = {}

	if id == 1 then
		local mainAwardGroup = go:NodeByName("main_award_group").gameObject
		titleLabel.text = __("STARRY_ALTAR_TEXT07")
		desLabel.text = __("STARRY_ALTAR_TEXT08")
		local optionalAwards = StarryAltarTable:getOptionalAwards(NORMAL_SUMMON_ID)
		local selects = xyd.models.summon:getStarrySelects()
		local chooseIndex = tonumber(selects[NORMAL_SUMMON_ID]) or 0

		if chooseIndex > 0 then
			mainAwardGroup:SetActive(false)

			local data = {
				itemData = {
					optionalAwards[chooseIndex],
					1
				},
				prob = weight[2] * 100 .. "%"
			}

			table.insert(awardsData, data)
		end
	else
		titleLabel.text = __("STARRY_ALTAR_TEXT09")
		desLabel.text = __("STARRY_ALTAR_TEXT10")
		local extraAward = StarryAltarTable:getExtraAward(NORMAL_SUMMON_ID)
		local data = {
			itemData = extraAward,
			prob = weight[1] * 100 .. "%"
		}
		awardsData = {
			data
		}
	end

	self:initItems(awardGroup, awardsData)
end

function StarryRateDetailWindow:initAwardItemBig(id, go)
	local titleLabel = go:ComponentByName("title_bg/title_label", typeof(UILabel))

	if xyd.Global.lang == "fr_fr" then
		titleLabel.fontSize = 16
	elseif xyd.Global.lang == "de_de" or xyd.Global.lang == "en_en" then
		titleLabel.fontSize = 18
	end

	local titleBg = go:ComponentByName("title_bg", typeof(UISprite))

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "ja_jp" or xyd.Global.lang == "de_de" then
		titleBg.width = 250

		titleBg:X(-190)
	elseif xyd.Global.lang == "en_en" then
		titleBg:X(-220)

		titleBg.width = 180
	end

	local desLabel = go:ComponentByName("des_label", typeof(UILabel))
	local awardList = go:NodeByName("award_scroller/list_grid").gameObject
	local scrollView = go:ComponentByName("award_scroller", typeof(UIScrollView))
	titleLabel.text = __("STARRY_ALTAR_TEXT11")
	desLabel.text = __("STARRY_ALTAR_TEXT12")
	local awardsData = StarryAltarTable:getBasicAward(NORMAL_SUMMON_ID)

	self:initItems(awardList, awardsData, scrollView)
end

function StarryRateDetailWindow:initItems(parentGo, awardsData, scrollView)
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
	self.rateLabel.text = info.prob
	local itemData = info.itemData

	xyd.getItemIcon({
		scale = 0.7962962962962963,
		uiRoot = self.iconNode,
		itemID = itemData[1],
		num = itemData[2],
		dragScrollView = scrollView
	})
end

return StarryRateDetailWindow
