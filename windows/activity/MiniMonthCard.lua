local MonthCard = import("app.windows.activity.MonthCard")
local MiniMonthCard = class("MiniMonthCard", MonthCard)

function MiniMonthCard:ctor(parentGO, params)
	MonthCard.ctor(self, parentGO, params)
end

function MiniMonthCard:initUITexture()
	local res_prefix = "Textures/activity_web/month_card/"
	local text_res_prefix = "Textures/activity_text_web/"

	xyd.setUITextureAsync(self.bg, res_prefix .. "mini_month_card_bg01", function ()
	end)
	xyd.setUITextureAsync(self.imgCard, res_prefix .. "mini_month_card", function ()
	end)

	self.imgCard.width = 159
	self.imgCard.height = 188

	xyd.setUITextureAsync(self.contentBg, res_prefix .. "min_des_bg", function ()
	end)
	xyd.setUITextureAsync(self.imgText01, text_res_prefix .. "month_card_text01_" .. xyd.Global.lang, function ()
	end)
	xyd.setUITextureAsync(self.imgText02, res_prefix .. "month_card_icon01", function ()
		self.imgText02:MakePixelPerfect()
	end)
	xyd.setUITextureAsync(self.imgText03, res_prefix .. "month_dimond", function ()
		self.imgText03:MakePixelPerfect()
	end)
end

function MiniMonthCard:setText()
	self.firstText.text = __("MINI_MONTH_CARD_TEXT01")
	self.firstText.color = Color.New2(944410623)
	self.everydayText.text = __("MINI_MONTH_CARD_TEXT02")
	self.everydayText.color = Color.New2(944410623)

	if xyd.Global.lang == "zh_tw" or xyd.Global.lang == "zh_cn" then
		self.firstText.width = 164
		self.firstText.fontSize = 22
		self.everydayText.width = 154
		self.everydayText.fontSize = 22
		self.discountLabel.width = 70
	elseif xyd.Global.lang == "ja_jp" then
		self.discountLabel.width = 70
	elseif xyd.Global.lang == "de_de" then
		self.btnPurchase:GetComponent(typeof(UISprite)).width = 260
		self.originPrice.fontSize = 16
		self.discountLabel.fontSize = 20
	elseif xyd.Global.lang == "en_en" then
		self.originPrice.fontSize = 16
		self.discountLabel.fontSize = 20

		self.discountLabel.transform:Y(3)
	elseif xyd.Global.lang == "fr_fr" then
		self.labelVip:Y(-300)
		self.btnPurchase:Y(-360)

		self.discountLabel.fontSize = 19
	end

	xyd.setUISpriteAsync(self.firstNumImg, nil, "min_first_num")
	xyd.setUISpriteAsync(self.everydayNumImg, nil, "min_everyday_num")

	self.originPrice.text = __("MINI_MONTH_CARD_TEXT04")

	if self.tableID == 1 or self.tableID == 2 then
		self.originPrice:SetActive(false)
		self.eRect:SetActive(false)
		self.curPrice.transform:Y(0)
		self.discountPart:SetActive(false)
		self.discountPart2:SetActive(false)
	else
		self.discountPart:SetActive(true)
		self.discountPart2:SetActive(false)

		self.discountLabel.text = __("MONTHLY_CARD_OFFER_FIRST")
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "MONTH_CARD_HELP2"
		})
	end

	local giftBagID = self.tableID
	self.retLabel.text = __("RET_TIME_TEXT")
	self.retLabel.color = Color.New2(943421439)
	self.curPrice.text = tostring(xyd.tables.giftBagTextTable:getCurrency(giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(giftBagID))
	self.labelVip.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(giftBagID)) .. " VIP EXP"
	self.labelVip.color = Color.New2(712044543)
end

return MiniMonthCard
