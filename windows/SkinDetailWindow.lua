local GuideDetailWindow = import("app.windows.GuideDetailWindow")
local SkinDetailWindow = class("SkinDetailWindow", GuideDetailWindow)
local MiscTable = xyd.tables.miscTable
local PartnerTable = xyd.tables.partnerTable
local SkillIcon = import("app.components.SkillIcon")
local Partner = import("app.models.Partner")
local PartnerCard = import("app.components.PartnerCard")

function SkinDetailWindow:ctor(name, params)
	params.isNeedSkill = false

	SkinDetailWindow.super.ctor(self, name, params)
end

function SkinDetailWindow:getUIComponent()
	SkinDetailWindow.super.getUIComponent(self)

	local winTrans = self.window_
	local top_right = winTrans:NodeByName("top_right").gameObject

	top_right:SetActive(false)

	local bottom = winTrans:NodeByName("bottom").gameObject
	self.groupInfo = bottom:NodeByName("groupInfo").gameObject
	self.nav = self.groupInfo:NodeByName("nav").gameObject
	self.startCon = self.playerNameGroup:NodeByName("partner_name_tag/stars").gameObject

	self.startCon:SetActive(false)
end

function SkinDetailWindow:firstInit()
	self:updateData()
	self:registerEvent()
	self:updateLoveIcon()
end

function SkinDetailWindow:updateNameTag()
	self.partnerNameTag:setInfo(self.partner_)
	self.startCon:SetActive(false)

	if self.skinIDs ~= nil then
		local currentSkinID = self.skinIDs[self.currentSkin]
		local name = xyd.tables.equipTextTable:getName(currentSkinID)

		self.partnerNameTag:setOnlySkinName(name)
	end
end

function SkinDetailWindow:onClickNav(index)
	SkinDetailWindow.super.onClickNav(self, 2)
	self.nav:SetActive(false)
end

function SkinDetailWindow:setSkinBtn()
	local skinID = self.partner_:getSkinID()
	local currentSkinID = self.skinIDs[self.currentSkin]
	local card = self.skinCards[self.currentSkin]

	card:showSkinNum()

	for i = 1, #self.skinCards do
		local card = self.skinCards[i]

		if self.currentSkin == i then
			card:setSkinCollect(true)
		else
			card:setSkinCollect(false)
		end
	end

	self.skinState = -1

	if xyd.tables.shopSkinTable:itemCanBuy(currentSkinID) == false then
		self.btnSelectPicture:SetActive(false)
		self.btnSkinDetail:SetActive(false)
		self.btnSkinOff:SetActive(false)
		self.btnSkinUnlock:SetActive(false)
		self.btnSkinOn:SetActive(false)
		self.textGroup:SetActive(true)
		self.btnBuy:SetActive(false)

		self.wayDescLabel.text = __("SKIN_TEXT18")

		if currentSkinID == 7007 then
			self.wayLabel.text = __("SKIN_TEXT23")
		elseif currentSkinID == 7047 then
			self.wayLabel.text = __("SKIN_TEXT25")
		elseif xyd.tables.partnerTable:checkIsWeddingSkin(currentSkinID) then
			self.wayLabel.text = __("SKIN_TEXT24")
		else
			self.wayLabel.text = __("SKIN_TEXT21")
		end
	else
		self.textGroup:SetActive(false)
		self.btnBuy:SetActive(true)

		local cost = xyd.tables.shopSkinTable:costByItemID(currentSkinID)

		xyd.setUISpriteAsync(self.btnBuy_imgCost, nil, tostring(xyd.tables.itemTable:getIcon(cost[1])), nil, )

		self.btnBuyLabel.text = __("SKIN_TEXT26")
	end

	self:loadSkinModel()
end

function SkinDetailWindow:updateSkill()
	SkinDetailWindow.super.super.updateSkill(self)
end

function SkinDetailWindow:initVars()
	SkinDetailWindow.super.initVars(self)

	local item = self.currentSortedPartners_[self.currentIdx_]
	self.skinID = item.skin_id
end

function SkinDetailWindow:updatePartnerSkin()
	local tableID = self.partner_:getTableID()
	local showIDs = xyd.tables.partnerTable:getShowIds(tableID)
	local showID = self.partner_:getShowID()
	self.skinIDs = {}
	self.skinCards = {}
	local dressSkinID = self.partner_:getSkinID()

	NGUITools.DestroyChildren(self.groupSkinCards.transform)

	self.skinState = -1
	local skinIDs = xyd.tables.partnerTable:getSkins(tostring(tableID))

	if xyd.Global.isReview == 1 then
		skinIDs = {}
	end

	for i = 1, #skinIDs do
		local skinID = skinIDs[i]
		local showTime = xyd.tables.partnerPictureTable:getShowTime(skinID)

		if showTime and showTime <= xyd.getServerTime() then
			local card = PartnerCard.new(self.groupSkinCards)

			card:setTouchListener(function ()
				self:setMultiSkinState(i)
			end)

			local group = self.partner_:getGroup()
			local data = {
				is_equip = false,
				tableID = tableID,
				group = group,
				skin_id = skinID
			}

			card:setSkinCard(data)

			if skinID == dressSkinID then
				card:setSkinCollect(true)
			end

			card:setDisplay()
			card:showSkinNum()
			table.insert(self.skinCards, card)
			table.insert(self.skinIDs, skinID)
		end
	end

	self.groupSkinCardsGrid:Reposition()

	if dressSkinID == 0 then
		if showID and showID ~= self.partner_:getTableID() then
			self.currentSkin = xyd.arrayIndexOf(self.skinIDs, showID)
		else
			local star = self.partner_:getStar()

			if star <= 5 then
				self.currentSkin = 1
			elseif star < 10 then
				self.currentSkin = 2
			else
				self.currentSkin = 3
			end
		end
	else
		self.currentSkin = xyd.arrayIndexOf(self.skinIDs, dressSkinID)
	end

	local isShow = self.partner_:isShowSkin()

	if dressSkinID == 0 then
		self.btnSetSkinVisible:SetActive(false)
	else
		local btnSetSkinVisibleSprite = self.btnSetSkinVisible:GetComponent(typeof(UISprite))

		self.btnSetSkinVisible:SetActive(true)

		if isShow then
			btnSetSkinVisibleSprite.spriteName = "skin_btn02"
		else
			btnSetSkinVisibleSprite.spriteName = "skin_btn01"
		end
	end

	for i = 1, #self.skinCards do
		local card = self.skinCards[i].go

		UIEventListener.Get(card).onDragStart = function ()
			self:onScrollBegin()
		end

		UIEventListener.Get(card).onDrag = function (go, delta)
			self:onScrollMove(delta)
		end

		UIEventListener.Get(card).onDragEnd = function (go)
			self:onScrollEnd()
		end
	end

	for k, v in pairs(self.skinIDs) do
		if v == self.skinID then
			self.currentSkin = k
		end
	end

	self:setSkinState(0)
end

function SkinDetailWindow:loadSkinModel()
	local skinID = self.partner_:getSkinID()
	local currentSkinID = self.skinIDs[self.currentSkin]
	local tableID = self.partner_:getTableID()
	local modelID = 0
	local curStar = self.partner_:getStar()
	local hero_list = xyd.tables.partnerTable:getHeroList(self.partner_:getTableID())
	modelID = xyd.tables.equipTable:getSkinModel(currentSkinID)
	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)

	if self.skinModel and self.skinModel:getName() == name or self.navChosen ~= 3 then
		return
	end

	NGUITools.DestroyChildren(self.groupModel.transform)

	local model = xyd.Spine.new(self.groupModel)

	model:setInfo(name, function ()
		model:SetLocalPosition(0, 0, 0)
		model:SetLocalScale(scale, scale, 1)
		model:setRenderTarget(self.groupModel:GetComponent(typeof(UIWidget)), 100)

		if self.navChosen == 3 then
			model:play("idle", 0)
		end

		self.skinModel = model
	end)
end

function SkinDetailWindow:choiceBuySkin(flag)
	if flag == true then
		self:buySkin()
	end
end

function SkinDetailWindow:buySkin()
	local currentSkinID = self.skinIDs[self.currentSkin]
	local cost = xyd.tables.shopSkinTable:costByItemID(currentSkinID)

	if cost == nil or cost[1] == nil then
		return
	end

	if xyd.isItemAbsence(cost[1], cost[2]) == false then
		local id = xyd.tables.shopSkinTable:idByItemID(currentSkinID)
		self.recordBuyItem = {
			item_num = 1,
			item_id = currentSkinID
		}

		xyd.models.shop:buyShopItem(xyd.ShopType.SHOP_SKIN, id, 1)
	end
end

return SkinDetailWindow
