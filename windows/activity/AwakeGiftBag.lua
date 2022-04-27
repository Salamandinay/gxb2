local ActivityContent = import(".ActivityContent")
local AwakeGiftBag = class("AwakeGiftBag", ActivityContent)
local AwakeGiftBagItem = class("AwakeGiftBagItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function AwakeGiftBag:ctor(parentGO, params, parent)
	AwakeGiftBag.super.ctor(self, parentGO, params, parent)
end

function AwakeGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/awake_giftbag"
end

function AwakeGiftBag:initUI()
	self:getUIComponent()
	AwakeGiftBag.super.initUI(self)
	self:initUIComponent()
	self:setItems()
end

function AwakeGiftBag:getUIComponent()
	local go = self.go
	self.labelTime = go:ComponentByName("labelTime", typeof(UILabel))
	self.endLabel = go:ComponentByName("endLabel", typeof(UILabel))
	self.desLabel = go:ComponentByName("desLabel", typeof(UILabel))
	self.textImg = go:ComponentByName("textImg", typeof(UISprite))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.scrollView = self.contentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.giftbagItem = self.contentGroup:NodeByName("scroller/giftbag_item").gameObject
	self.itemGroup = self.contentGroup:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.giftbagItem, AwakeGiftBagItem, self)
end

function AwakeGiftBag:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "awake_giftbag_text01_" .. xyd.Global.lang, function ()
		self.textImg:MakePixelPerfect()
	end)

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = import("app.components.CountDown").new(self.labelTime, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.labelTime:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.endLabel.text = __("TEXT_END")
	self.desLabel.text = __("AWAKE_GIFTBAG_TEXT01")
end

function AwakeGiftBag:setItems()
	local ids = xyd.tables.activityCompose10Table:getIDs()
	local items = {}

	for i in pairs(ids) do
		local id = ids[i]
		local params = {
			id = i,
			cur_times = self.activityData.detail.times[i],
			limit_times = xyd.tables.activityCompose10Table:getLimit(id),
			star = xyd.tables.activityCompose10Table:getStar(id),
			awards = xyd.tables.activityCompose10Table:getAwards(id)
		}

		table.insert(items, params)
	end

	self.wrapContent:setInfos(items, {})
end

function AwakeGiftBag:resizeToParent()
	AwakeGiftBag.super.resizeToParent(self)
	self.go:Y(-435)

	local height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.contentGroup:Y(1045 - height - 500)

	if xyd.Global.lang == "en_en" then
		self.desLabel.width = 360
		self.desLabel.spacingY = 5
		self.desLabel.alignment = NGUIText.Alignment.Left
	end

	if xyd.Global.lang == "ja_jp" then
		self.desLabel.width = 300
		self.desLabel.spacingY = 10
		self.desLabel.alignment = NGUIText.Alignment.Left
	end

	if xyd.Global.lang == "ko_kr" then
		self.desLabel.width = 360
		self.desLabel.alignment = NGUIText.Alignment.Left
	end

	if xyd.Global.lang == "de_de" then
		self.desLabel.width = 340
		self.desLabel.spacingY = 10
		self.desLabel.alignment = NGUIText.Alignment.Left
	end
end

function AwakeGiftBagItem:ctor(go, parent)
	AwakeGiftBagItem.super.ctor(self, go, parent)
end

function AwakeGiftBagItem:initUI()
	local go = self.go
	self.labelText01 = go:ComponentByName("labelText01", typeof(UILabel))
	self.labelText02 = go:ComponentByName("labelText02", typeof(UILabel))
	self.labelText03 = go:ComponentByName("labelText03", typeof(UILabel))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.labelText02.text = __("SHENXUE_GIFTBAG_ITEM_TEXT01")
end

function AwakeGiftBagItem:updateInfo()
	self.id_ = self.data.id
	self.cur_times = self.data.cur_times
	self.limit_times = self.data.limit_times
	self.star = self.data.star
	self.awards = self.data.awards
	self.labelText01.text = __("AWAKE_GIFTBAG_STAR", self.star)
	self.labelText03.text = __("SHENXUE_GIFTBAG_TIMES", self.cur_times, self.limit_times)

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i in pairs(self.awards) do
		local data = self.awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = xyd.getItemIcon({
				show_has_num = true,
				noClick = false,
				scale = 0.75,
				uiRoot = self.itemGroup,
				itemID = data[1],
				num = data[2],
				dragScrollView = self.parent.scrollView
			})

			if self.cur_times == self.limit_times then
				item:setChoose(true)
			end
		end
	end
end

return AwakeGiftBag
