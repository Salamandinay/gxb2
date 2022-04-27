local BaseWindow = import(".BaseWindow")
local ShopMapWindow = class("ShopMapWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local CountDown = import("app.components.CountDown")
local shopMapConfig = {
	{
		shopIconName = "shop_cafe",
		name = "shopHero",
		window = "shop_window",
		pos = Vector3(-165, 340, 0),
		size = {
			w = 338,
			h = 305
		},
		params = {
			shopType = xyd.ShopType.SHOP_HERO_NEW
		}
	},
	{
		shopIconName = "shop_skin",
		name = "shopSkin",
		window = "skin_detail_buy_window",
		pos = Vector3(200, 320, 0),
		size = {
			w = 307,
			h = 240
		}
	},
	{
		shopIconName = "shop_market",
		name = "shopMarket",
		window = "market_window",
		pos = Vector3(-135, 50, 0),
		size = {
			w = 349,
			h = 262
		},
		params = {
			shopType = xyd.ShopType.SHOP_BLACK_NEW
		}
	},
	{
		shopIconName = "shop_exchange",
		name = "shopExchange",
		window = "shop_window",
		pos = Vector3(188, -23, 0),
		size = {
			w = 356,
			h = 339
		},
		params = {
			shopType = xyd.ShopType.SHOP_HERO
		}
	},
	{
		shopIconName = "shop_artifact",
		name = "shopArtifact",
		window = "shop_window",
		pos = Vector3(-152, -246, 0),
		size = {
			w = 323,
			h = 290
		},
		params = {
			shopType = xyd.ShopType.ARTIFACT
		}
	},
	{
		shopIconName = "shop_unopen",
		name = "shopUnopen",
		pos = Vector3(215, -315, 0),
		size = {
			w = 311,
			h = 296
		}
	}
}
local titleConfig = {
	shopHero = {
		text = "SHOP_MAP_TEXT01",
		effectIndex = 2,
		pos = Vector3(-47, -138),
		effectPos = {
			-338,
			-1123
		}
	},
	shopSkin = {
		text = "SHOP_MAP_TEXT02",
		effectIndex = 4,
		pos = Vector3(0, -138),
		effectPos = {
			-700,
			-1102
		}
	},
	shopMarket = {
		text = "SHOP_MAP_TEXT03",
		effectIndex = 1,
		pos = Vector3(-35, -108),
		effectPos = {
			-360,
			-835
		}
	},
	shopExchange = {
		text = "SHOP_MAP_TEXT04",
		effectIndex = 5,
		pos = Vector3(0, -118),
		effectPos = {
			-700,
			-760
		}
	},
	shopArtifact = {
		text = "SHOP_MAP_TEXT05",
		effectIndex = 3,
		pos = Vector3(-20, -100),
		effectPos = {
			-350,
			-529
		}
	},
	shopUnopen = {
		text = "SHOP_STREET_TEXT02",
		effectIndex = 6,
		pos = Vector3(0, -115),
		effectPos = {
			-710,
			-466
		}
	}
}

function ShopMapWindow:ctor(name, params)
	ShopMapWindow.super.ctor(self, name, params)

	self.shopRed = {}
	self.artifactTimeOk = false
end

function ShopMapWindow:initWindow()
	ShopMapWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	local windowBg = winTrans:ComponentByName("bg", typeof(UITexture))
	self.uiPanel_ = self.window_:GetComponent(typeof(UIPanel))

	if xyd.isIosTest() then
		xyd.setUITextureAsync(windowBg, "Textures/texture_ios/shop_map_bg_ios_test")
	else
		xyd.setUITextureAsync(windowBg, "Textures/scenes_web/shop_map_bg")
	end

	self.countDownGroup_ = winTrans:NodeByName("countDownGroup").gameObject
	self.countTips_ = winTrans:ComponentByName("countDownGroup/labelTips", typeof(UILabel))
	self.countDownLabel_ = winTrans:ComponentByName("countDownGroup/labelCountDown", typeof(UILabel))
	self.bgEffect_ = winTrans:NodeByName("bgEffect").gameObject
	self.effectChris1_ = xyd.WindowManager.get():setChristmasEffect(self.bgEffect_, true)

	self:initShopList()
	self:initTopPart()
	self:initTimeCount()
	self:updateUpIcon()
	self:playBGSSound()
end

function ShopMapWindow:initShopList()
	local winTrans = self.window_.transform
	self.content_ = winTrans:Find("content").gameObject
	local tempItem = winTrans:Find("itemShop").gameObject

	tempItem:SetActive(false)

	for idx, shopItemData in ipairs(shopMapConfig) do
		local shopItem = NGUITools.AddChild(self.content_, tempItem)
		local boxCollider = shopItem:GetComponent(typeof(UnityEngine.BoxCollider))

		shopItem:SetActive(true)

		shopItem.name = shopItemData.name
		local itemTrans = shopItem.transform
		itemTrans.localPosition = shopItemData.pos
		local shopIcon = itemTrans:ComponentByName("shopIcon", typeof(UISprite))
		local shopTitle = itemTrans:ComponentByName("shopTitleBg/shopTitle", typeof(UILabel))
		local shopTitleBg = itemTrans:ComponentByName("shopTitleBg", typeof(UISprite))
		self.shopRed[idx] = itemTrans:ComponentByName("shopTitleBg/shopRed", typeof(UISprite))

		if xyd.isIosTest() then
			xyd.iosSetUISprite(shopTitleBg, "shop_name_bg_ios_test")

			if shopItemData.name == "shopSkin" then
				shopItemData.window = nil
			end
		end

		local effectGroup = itemTrans:ComponentByName("effectGroup", typeof(UITexture))

		if shopItemData.name == "shopMarket" then
			self.shopMarket_upIcon = shopTitleBg.gameObject:NodeByName("upIcon").gameObject
		end

		local effect = xyd.Spine.new(effectGroup.gameObject)
		shopTitleBg.transform.localPosition = titleConfig[shopItemData.name].pos
		shopItem:GetComponent(typeof(UIWidget)).width = shopItemData.size.w
		shopItem:GetComponent(typeof(UIWidget)).height = shopItemData.size.h
		boxCollider.size = Vector3(shopItemData.size.w, shopItemData.size.h, 0)

		xyd.setUISpriteAsync(shopIcon, nil, shopItemData.shopIconName, function ()
			shopIcon:MakePixelPerfect()
		end, nil)

		shopTitle.text = __(titleConfig[shopItemData.name].text)
		local effectIndex = titleConfig[shopItemData.name].effectIndex
		local effectPos = titleConfig[shopItemData.name].effectPos

		effect:setInfo("shangdianjie", function ()
			effect:SetLocalPosition(effectPos[1], effectPos[2], 10 + idx)
			effect:play("texiao0" .. effectIndex, 0, 1)
			self:waitForTime(0.04, function ()
				shopIcon.gameObject:SetActive(false)
			end, nil)
		end)

		if not shopItemData.params then
			shopItemData.params = {}
		end

		function shopItemData.params.closeCallBack()
			self:playBGSSound()
		end

		UIEventListener.Get(shopItem.gameObject).onClick = handler(self, function ()
			xyd.SoundManager.get():playSound(2141)

			if shopItemData.window then
				if shopItemData.name == "shopArtifact" then
					if self.artifactTimeOk then
						xyd.SoundManager.get():stopBGS()
						xyd.WindowManager.get():openWindow(shopItemData.window, shopItemData.params)
					else
						self:onNoOpenTouch()
					end
				else
					xyd.SoundManager.get():stopBGS()
					xyd.WindowManager.get():openWindow(shopItemData.window, shopItemData.params)
				end
			else
				self:onNoOpenTouch()
			end
		end)
	end

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.COFFEE_SHOP, self.shopRed[1])
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.SKIN_SHOP, self.shopRed[2])
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.ARENA_SHOP
	}, self.shopRed[4])
end

function ShopMapWindow:playBGSSound()
	xyd.SoundManager.get():playSound(2145)
end

function ShopMapWindow:onNoOpenTouch()
	local params = {
		alertType = xyd.AlertType.TIPS,
		message = __("SHOP_STREET_TEXT01")
	}

	xyd.WindowManager.get():openWindow("alert_window", params)
end

function ShopMapWindow:initTopPart()
	self.windowTop_ = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop_:setItem(items)
end

function ShopMapWindow:willClose()
	if self.effectChris1_ then
		self.effectChris1_:destroy()
	end

	xyd.SoundManager.get():stopBGS()
	ShopMapWindow.super.willClose(self)
end

function ShopMapWindow:initTimeCount()
	local endTime = tonumber(xyd.tables.miscTable:getVal("artifact_shop_start_time"))

	if endTime <= xyd.getServerTime() then
		self.countDownGroup_:SetActive(false)

		self.artifactTimeOk = true
	else
		self.countDownGroup_:SetActive(true)

		self.countTips_.text = __("ARTIFACT_OPEN_TIPS")
		self.timeLabel = CountDown.new(self.countDownLabel_, {
			duration = endTime - xyd.getServerTime(),
			callback = function ()
				self.countDownGroup_:SetActive(false)

				self.artifactTimeOk = true
			end
		})
	end
end

function ShopMapWindow:updateUpIcon()
	if xyd.models.activity:isResidentReturnAddTime() then
		self.shopMarket_upIcon:SetActive(xyd.models.activity:isResidentReturnAddTime())

		local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.WELFARE_SOCIETY)

		xyd.setUISpriteAsync(self.shopMarket_upIcon.gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_" .. return_multiple, nil, , )
	else
		self.shopMarket_upIcon:SetActive(false)
	end
end

return ShopMapWindow
