local StarryRateDetailWindow = class("StarryRateDetailWindow", import(".BaseWindow"))
local AwardRateItem = class("AwardRateItem", import("app.components.CopyComponent"))
local StarryAltarTable = xyd.tables.starryAltarTable
local NORMAL_SUMMON1_ID = 1
local NORMAL_SUMMON2_ID = 3
local ACT_SUMMON1_ID = 4
local ACT_SUMMON2_ID = 5
local ACT_SUMMON1_NEWCOST_ID = 6
local ACT_SUMMON2_NEWCOST_ID = 7

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
	self.scrollView = self.groupAction:ComponentByName("award_scroller", typeof(UIScrollView))
	self.awardItem1 = self.groupAction:NodeByName("award_scroller/award_item_1").gameObject
	self.awardItem2 = self.groupAction:NodeByName("award_scroller/award_item_2").gameObject
	self.awardItem3 = self.groupAction:NodeByName("award_scroller/award_item_3").gameObject
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
	self.realMode1ID = nil
	self.realMode2ID = nil
	local actId = StarryAltarTable:getActivity(ACT_SUMMON1_NEWCOST_ID)
	local isActOpen = false

	if actId then
		isActOpen = xyd.models.activity:isOpen(actId)
	end

	if isActOpen then
		self.realMode1ID = ACT_SUMMON1_ID
		self.realMode2ID = ACT_SUMMON2_ID
	else
		self.realMode1ID = NORMAL_SUMMON1_ID
		self.realMode2ID = NORMAL_SUMMON2_ID
	end

	self:initAwardItem(1, self.awardItem1)
	self:initAwardItem(2, self.awardItem2)
	self:initAwardItemBig(3, self.awardItem3)

	if xyd.Global.lang == "fr_fr" then
		self.awardItem1:ComponentByName("des_label4", typeof(UILabel)):Y(-218)
		self.awardItem1:ComponentByName("des_label5", typeof(UILabel)):Y(-242)
	end
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

	local desLabel, awardGroup = nil

	if id ~= 1 then
		desLabel = go:ComponentByName("des_label", typeof(UILabel))

		if xyd.Global.lang == "fr_fr" then
			desLabel.width = 600
			desLabel.height = 50
		end

		awardGroup = go:NodeByName("award_group").gameObject

		if xyd.Global.lang ~= "zh_tw" then
			awardGroup:Y(-52)
		end
	end

	local weight = StarryAltarTable:getWeight(self.realMode1ID)
	local awardsData = {}

	if id == 1 then
		local mainAwardGroup = go:NodeByName("main_award_group1").gameObject
		awardGroup = go:NodeByName("award_group1").gameObject
		titleLabel.text = __("STARRY_ALTAR_TEXT07")
		local textArr = {
			__("STARRY_ALTAR_TEXT20"),
			__("STARRY_ALTAR_TEXT14"),
			__("STARRY_ALTAR_TEXT08"),
			__("STARRY_ALTAR_TEXT15"),
			__("STARRY_ALTAR_TEXT16")
		}

		for i = 1, 5 do
			desLabel = go:ComponentByName("des_label" .. i, typeof(UILabel))
			desLabel.text = textArr[i]
		end

		local optionalAwards = StarryAltarTable:getOptionalAwards(self.realMode1ID)
		local win = xyd.getWindow("starry_altar_window")
		local chooseIndex = win.chooseIndex or 0

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
			self:initItems(awardGroup, awardsData)
		end

		awardGroup = go:NodeByName("award_group2").gameObject
		awardsData = {}
		local data = {
			itemData = StarryAltarTable:getType2Award(self.realMode2ID)[2],
			prob = StarryAltarTable:getType2Award(self.realMode2ID)[1][1] - (win.leftTimeToSpecialAward or 0) .. "/" .. StarryAltarTable:getType2Award(self.realMode2ID)[1][1]
		}

		table.insert(awardsData, data)
		self:initItems(awardGroup, awardsData)
	else
		titleLabel.text = __("STARRY_ALTAR_TEXT09")
		desLabel.text = __("STARRY_ALTAR_TEXT10")
		local extraAward = StarryAltarTable:getExtraAward(self.realMode1ID)
		local data = {
			itemData = extraAward,
			prob = weight[1] * 100 .. "%"
		}
		awardsData = {
			data
		}

		self:initItems(awardGroup, awardsData)
	end
end

function StarryRateDetailWindow:initAwardItemBig(id, go)
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
	titleLabel.text = __("STARRY_ALTAR_TEXT11")
	desLabel.text = __("STARRY_ALTAR_TEXT12")
	local awardsData = StarryAltarTable:getBasicAward(self.realMode1ID)
	bg.height = 211 + (math.ceil(#awardsData / 6) - 1) * 120
	go:ComponentByName("", typeof(UIWidget)).height = bg.height + 9

	self:initItems(awardList, awardsData, self.scrollView)
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
