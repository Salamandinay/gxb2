local DungeonShopWindow = class("DungeonShopWindow", import(".BaseWindow"))
local DungeonShopTable = xyd.tables.dungeonShopTable

function DungeonShopWindow:ctor(name, params)
	DungeonShopWindow.super.ctor(self, name, params)

	self.level = {
		"primary_",
		"medium_",
		"senior_"
	}
end

function DungeonShopWindow:initWindow()
	DungeonShopWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function DungeonShopWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.labelTitle_ = winTrans:ComponentByName("groupAction/labelTitle_", typeof(UILabel))

	for i = 1, 3 do
		self["shop" .. i] = winTrans:NodeByName("groupAction/shop" .. i).gameObject
		self["btnBuy" .. i] = self["shop" .. i]:NodeByName("btnBuy" .. i).gameObject
		self["imgShop" .. i] = self["shop" .. i]:ComponentByName("imgShop" .. i, typeof(UISprite))
	end

	self.groupNoBusiness = winTrans:NodeByName("groupAction/groupNoBusiness").gameObject
	self.labelNoBuzinessMan = self.groupNoBusiness:ComponentByName("labelNoBuzinessMan", typeof(UILabel))
end

function DungeonShopWindow:layout()
	self.labelNoBuzinessMan.text = __("NO_BUSINESS_MAN")
	self.labelTitle_.text = __("DUNGEON_SHOP")
	local count = {
		0,
		0,
		0,
		0
	}
	local total = 1
	local shopItems = xyd.models.dungeon:getShopItems()

	if #shopItems <= 0 then
		self.groupNoBusiness:SetActive(true)
		self.shop1:SetActive(false)
		self.shop2:SetActive(false)
		self.shop3:SetActive(false)
	else
		for i = 1, #shopItems do
			local id = shopItems[i]
			local type_ = DungeonShopTable:getType(id)

			if type_ then
				count[type_] = count[type_] + 1
			end
		end

		local posY = {
			143,
			-19,
			-180
		}

		for i = 1, 3 do
			if count[i] ~= 0 then
				xyd.setUISpriteAsync(self["imgShop" .. tostring(i)], nil, "dungeon_" .. tostring(self.level[i]) .. tostring(xyd.Global.lang), nil, false, true)
				self["shop" .. tostring(i)]:SetLocalPosition(0, posY[total], 0)

				self["btnBuy" .. tostring(i)]:ComponentByName("button_label", typeof(UILabel)).text = __("BUY")
				total = total + 1
			else
				self["shop" .. tostring(i)]:SetActive(false)
			end
		end
	end
end

function DungeonShopWindow:registerEvent()
	self:register()

	for i = 1, 3 do
		UIEventListener.Get(self["btnBuy" .. tostring(i)]).onClick = function ()
			local params = {
				index = i
			}

			xyd.WindowManager.get():openWindow("dungeon_shop_detail_window", params)
		end
	end
end

return DungeonShopWindow
