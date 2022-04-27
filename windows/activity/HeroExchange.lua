local ActivityContent = import(".ActivityContent")
local HeroExchange = class("HeroExchange", ActivityContent)
local HeroIcon = import("app.components.HeroIcon")

function HeroExchange:ctor(parentGo, params, parent)
	ActivityContent.ctor(self, parentGo, params, parent)
end

function HeroExchange:getPrefabPath()
	return "Prefabs/Windows/activity/hero_exchange"
end

function HeroExchange:getUIComponent()
	local group = self.go:NodeByName("e:Group").gameObject
	self.timeLabel = group:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = group:ComponentByName("endLabel", typeof(UILabel))
	self.textLabel01 = group:ComponentByName("contentGroup/textLabel01", typeof(UILabel))
	self.textLabel02 = group:ComponentByName("contentGroup/textLabel02", typeof(UILabel))
	self.groupItem = group:NodeByName("e:Group/groupItem").gameObject
	self.groupItem_UILayout = self.groupItem:GetComponent(typeof(UILayout))
	self.windowBtn = group:NodeByName("e:Group/windowBtn").gameObject
	self.button_label = self.windowBtn:ComponentByName("button_label", typeof(UILabel))
	self.textImg = group:ComponentByName("textImg", typeof(UITexture))
end

function HeroExchange:initUI()
	ActivityContent.initUI(self)
	self:getUIComponent()

	UIEventListener.Get(self.windowBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("shop_window", {
			shopType = xyd.ShopType.SHOP_HERO
		})
	end

	self:setText()
	self:setItems()

	if xyd:getServerTime() < self.activityData:getUpdateTime() then
		self.timeLabel:SetActive(true)
		self.endLabel:SetActive(true)

		local timeCount = import("app.components.CountDown").new(self.timeLabel)

		timeCount:setInfo({
			duration = self.activityData:getUpdateTime() - xyd:getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	xyd.setUITextureByNameAsync(self.textImg, "hero_exchange_text01_" .. xyd.Global.lang, true)

	if xyd.Global.lang == "fr_fr" then
		self.textImg:X(105)
		self.textLabel02:Y(-175)

		self.textLabel02.width = 230

		self.textLabel02:Y(-185)
		self.endLabel:X(210)
	elseif xyd.Global.lang == "zh_tw" or xyd.Global.lang == "ja_jp" then
		self.textImg:X(95)
		self.textLabel01:SetLocalPosition(180, -130, 0)
	elseif xyd.Global.lang == "ko_kr" then
		self.textImg:Y(-10)
		self.textLabel01:SetLocalPosition(185, -130, 0)
		self.textLabel02:Y(-185)
	elseif xyd.Global.lang == "de_de" then
		self.textImg:Y(-10)

		self.textLabel02.width = 300

		self.textLabel02:Y(-185)
		self.timeLabel:X(45)
		self.endLabel:X(165)
	end
end

function HeroExchange:setText()
	self.textLabel01.text = __("HERO_EXCHANGE_TEXT01")
	self.textLabel02.text = __("HERO_EXCHANGE_TEXT02")
	self.button_label.text = __("EXCHANGE")
	self.endLabel.text = __("TEXT_END")
end

function HeroExchange:setItems()
	local ids = xyd.tables.activityShopHeroTable:getIDs()

	for i = 1, #ids do
		local data = xyd.tables.activityShopHeroTable:getItem(ids[i])
		local item = {
			itemID = data[1],
			num = data[2]
		}
		local icon = HeroIcon.new(self.groupItem)

		icon:setInfo(item)

		local width = icon.go:GetComponent(typeof(UIWidget)).width

		icon.go:SetLocalScale(117 / width, 117 / width, 117 / width)

		if #ids > 4 then
			icon:setScale(0.8)

			if #ids == 5 then
				self.groupItem_UILayout.gap = Vector2(25, 0)
			elseif #ids == 6 then
				self.groupItem_UILayout.gap = Vector2(20, 0)
			end
		end
	end
end

return HeroExchange
