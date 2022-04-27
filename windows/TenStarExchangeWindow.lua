local TenStarExchangeWindow = class("TenStarExchangeWindow", import(".BaseWindow"))
local HeroIcon = import("app.components.HeroIcon")
local defaultItemID = 940002

function TenStarExchangeWindow:ctor(name, params)
	TenStarExchangeWindow.super.ctor(self, name, params)

	self.tenStarPartner_ = params.partner
end

function TenStarExchangeWindow:initWindow()
	TenStarExchangeWindow.super.initWindow(self)
	self:getComponent()
	self:register()
	self:initContentPart()

	self.titleLabel_.text = __("TEN_STAR_EXCHANGE_WINDOW_TITLE")
end

function TenStarExchangeWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	local conTrans = winTrans:NodeByName("component")
	self.HeroIconRoot1_ = conTrans:NodeByName("HeroIconRoot1").gameObject
	self.HeroIconRoot2_ = conTrans:NodeByName("HeroIconRoot2/heroRoot").gameObject
	self.countLabel2_ = conTrans:ComponentByName("HeroIconRoot2/label", typeof(UILabel))
	self.HeroIconRoot3_ = conTrans:NodeByName("HeroIconRoot3/heroRoot").gameObject
	self.itemIcon3_mask = conTrans:NodeByName("HeroIconRoot3/itemIcon3_mask").gameObject
	self.fiveStarIconAddEffectGroup = conTrans:NodeByName("fiveStarIconAddEffectGroup").gameObject
	self.labelText02_ = conTrans:ComponentByName("labelText02", typeof(UILabel))
	self.exchangeBtn_ = conTrans:NodeByName("exchangeBtn").gameObject
	self.exchangeBtnLabel_ = conTrans:ComponentByName("exchangeBtn/label", typeof(UILabel))
	self.exchangeBtnCostLabel_ = conTrans:ComponentByName("exchangeBtn/costLabel", typeof(UILabel))
	self.starImg_ = conTrans:ComponentByName("HeroIconRoot3/itemIcon3_mask/starImg", typeof(UISprite))
	self.starLabel_ = conTrans:ComponentByName("HeroIconRoot3/itemIcon3_mask/starLabel", typeof(UILabel))

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "en_en" or xyd.Global.lang == "en_en" then
		self.exchangeBtnLabel_:X(20)
	end
end

function TenStarExchangeWindow:register()
	TenStarExchangeWindow.super.register(self)

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "TEN_STAR_EXCHANGE_HELP"
		})
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.HeroIconRoot2_).onClick = handler(self, self.onTouchFiveStarIcon)
	UIEventListener.Get(self.exchangeBtn_).onClick = handler(self, self.onTouchExchange)

	self.eventProxy_:addEventListener(xyd.event.REPLACE_10_STAR, self.onExchangePartner, self)
end

function TenStarExchangeWindow:initContentPart()
	self.itemCost_ = tonumber(xyd.tables.miscTable:split2Cost("activity_10_replace_cost", "value", "#")[2])

	self:initEffect()
	self:initData()
	self:register()
end

function TenStarExchangeWindow:initEffect()
	if not self.addEffect_ then
		self.addEffect_ = xyd.Spine.new(self.fiveStarIconAddEffectGroup)

		self.addEffect_:setInfo("jiahao", function ()
			self.addEffect_:SetLocalScale(0.7, 0.7, 0.7)
			self.addEffect_:play("texiao01", 0)
		end)
	else
		self.addEffect_:play("texiao01", 0)
	end
end

function TenStarExchangeWindow:initData()
	self.optionalList_ = {
		{},
		{}
	}
	self.materialList_ = {
		{},
		{}
	}
	self.tmpMaterialList = {
		{},
		{}
	}
	self.tmpOptionalList = {
		{},
		{}
	}
	self.typicalPartner_ = nil

	self:updateStatus()
	self:initTenStarIcon()
	self:initFiveStarIcon()
	self:initMaterial()
	self.itemIcon3_mask:SetActive(true)

	local star = self.tenStarPartner_:getStar()

	if star == 10 then
		xyd.setUISpriteAsync(self.starImg_, nil, "star_orange_2", function ()
			self.starImg_:MakePixelPerfect()
		end)

		self.starLabel_.text = ""
	else
		xyd.setUISpriteAsync(self.starImg_, nil, "potentiality_avatar_star", function ()
			self.starImg_:MakePixelPerfect()
		end)

		self.starLabel_.text = tostring(star - 10)
	end

	self.fiveStarIconAddEffectGroup:SetActive(true)

	self.exchangeBtnCostLabel_.text = tostring(self.itemCost_)

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.TEN_STAR_EXCHANGE_MATERIAL) < self.itemCost_ then
		self.exchangeBtnCostLabel_.color = Color.New2(3422556671.0)
		self.exchangeBtnCostLabel_.effectColor = Color.New2(68719476735.0)
	else
		self.exchangeBtnCostLabel_.color = Color.New2(4294967295.0)
		self.exchangeBtnCostLabel_.effectColor = Color.New2(943741695)
	end

	self.exchangeBtnLabel_.text = __("EXCHANGE2")
	self.labelText02_.text = __("TEN_STAR_EXCHANGE_TEXT04")
end

function TenStarExchangeWindow:updateStatus()
	local star = self.tenStarPartner_:getStar()
	local needNum = xyd.tables.miscTable:split2num("replace_10_cost_hero", "value", "|")[star - 9]
	local hasNum = #self.materialList_[2]
	local label = self.countLabel2_
	label.text = hasNum .. "/" .. needNum

	if needNum <= hasNum then
		label.color = Color.New2(2986279167.0)
		label.effectColor = Color.New2(960513791)

		xyd.applyChildrenOrigin(self.HeroIconRoot2_)
	else
		label.color = Color.New2(3422556671.0)
		label.effectColor = Color.New2(4294967295.0)
	end

	self:endFiveStarTouch()
end

function TenStarExchangeWindow:initMaterial()
	self.optionalList_[2] = {}
	self.materialList_[2] = {}
	self.tmpMaterialList[2] = {}
	self.tmpOptionalList[2] = {}
	local group = self.tenStarPartner_:getGroup()
	local slot_arr = xyd.models.slot:getListByGroupAndStar(group, 5)

	for i = 1, #slot_arr do
		local cur = slot_arr[i]
		cur.noClick = false
		local replace_id = xyd.tables.partnerTable:getStar10(cur:getTableID())

		if replace_id and replace_id ~= 0 and xyd.tables.partnerTable:getStar(cur:getTableID()) == 5 and replace_id ~= self.tenStarPartner_:getTableID() then
			table.insert(self.optionalList_[2], cur)
		end
	end
end

function TenStarExchangeWindow:initTenStarIcon()
	if not self.itemIcon1 then
		self.itemIcon1 = HeroIcon.new(self.HeroIconRoot1_)
	end

	self.itemIcon1:setInfo(self.tenStarPartner_:getInfo())
end

function TenStarExchangeWindow:initFiveStarIcon()
	xyd.applyChildrenGrey(self.HeroIconRoot2_)

	local star = self.tenStarPartner_:getStar()
	local cost_list = xyd.tables.miscTable:split2num("replace_10_cost_hero", "value", "|")
	self.countLabel2_.text = "0/" .. tostring(cost_list[star - 9])
	self.countLabel2_.color = Color.New2(3422556671.0)
	self.countLabel2_.effectColor = Color.New2(68719476735.0)
	self.typicalPartner_ = nil

	if not self.itemIcon2 then
		self.itemIcon2 = HeroIcon.new(self.HeroIconRoot2_)
	end

	self.itemIcon2:setInfo({
		hideDebris = true,
		noClick = true,
		itemID = defaultItemID,
		group = self.tenStarPartner_:getGroup()
	})
end

function TenStarExchangeWindow:onExchangePartner(event)
	local item = {}
	local data = event.data
	local partner = xyd.models.slot:getPartner(data.partner_id)

	table.insert(item, {
		item_num = 1,
		item_id = data.replace_table_id,
		star = partner:getStar()
	})
	xyd.WindowManager.get():openWindow("alert_award_window", {
		items = item,
		title = __("ACQUIRE_AVATAR"),
		callback = function ()
			xyd.alertItems(data.items)
		end
	})
	xyd.WindowManager.get():closeWindow("ten_star_exchange_window")
end

function TenStarExchangeWindow:onTouchFiveStarIcon()
	if not self.tenStarPartner_ then
		xyd.showToast(__("TEN_STAR_EXCHANGE_TEXT02"))

		return
	end

	self.curID_ = 2
	local tmpMaterialList = self.tmpMaterialList[2]
	local tmpOptionalList = self.tmpOptionalList[2]
	local materialList = self.materialList_[2]
	local optionalList = self.optionalList_[2]
	tmpMaterialList = {}
	tmpOptionalList = {}
	local isInMaterial = {}

	for i = 1, #materialList do
		table.insert(tmpMaterialList, materialList[i])

		isInMaterial[materialList[i]:getPartnerID()] = true
	end

	for i = 1, #optionalList do
		if not isInMaterial[optionalList[i]:getPartnerID()] then
			table.insert(tmpOptionalList, optionalList[i])
		end
	end

	local function selectCallback(id, pInfo, choose, partner)
		local typical = self.typicalPartner_

		if not partner or not typical then
			self.typicalPartner_ = partner
		end
	end

	local function extraJudge(partner)
		local typical = self.typicalPartner_

		if not typical then
			return true
		else
			local id = typical:getTableID()

			if partner:getTableID() ~= id then
				xyd.showToast(__("TEN_STAR_EXCHANGE_TEXT01"))

				return false
			end

			return true
		end
	end

	local params = {
		hideDetail = true,
		confirmCallback = function (_, materialList, _, optionalList)
			self:confirmCallback(materialList, optionalList)
		end,
		selectCallback = function (id, pInfo, choose, partner)
			selectCallback(id, pInfo, choose, partner)
		end,
		optionalList = {
			needNum = xyd.tables.miscTable:split2num("replace_10_cost_hero", "value", "|")[self.tenStarPartner_:getStar() - 9],
			pList = tmpOptionalList
		},
		materialList = tmpMaterialList,
		extraJudge = extraJudge
	}

	xyd.WindowManager.get():openWindow("shenxue_select_window", params)
end

function TenStarExchangeWindow:confirmCallback(materialList, optionalList)
	self.materialList_[2] = {}

	for i = 1, #materialList do
		table.insert(self.materialList_[2], materialList[i])
	end

	self:updateStatus()
end

function TenStarExchangeWindow:endFiveStarTouch()
	local typical = self.typicalPartner_

	if not typical then
		self:initFiveStarIcon()
		xyd.applyChildrenGrey(self.HeroIconRoot2_)

		if not self.itemIcon3 then
			self.itemIcon3 = HeroIcon.new(self.HeroIconRoot3_)
		end

		if self.itemIcon3 then
			self.itemIcon3:SetActive(false)
		end

		self.itemIcon3_mask:SetActive(true)
	elseif self.itemIcon2 then
		self.itemIcon2:setInfo({
			noClick = true,
			itemID = typical:getTableID()
		})

		local pInfo = self.tenStarPartner_:getInfo()
		pInfo.skin_id = nil
		pInfo.is_vowed = 0
		pInfo.isVowed = 0
		pInfo.tableID = xyd.tables.partnerTable:getStar10(self.typicalPartner_:getTableID())

		if not self.itemIcon3 then
			self.itemIcon3 = HeroIcon.new(self.HeroIconRoot3_)
		end

		self.itemIcon3:setInfo(pInfo)
		self.itemIcon3:SetActive(true)
		self.itemIcon3_mask:SetActive(false)
	end
end

function TenStarExchangeWindow:onTouchExchange()
	if #self.materialList_[2] < xyd.tables.miscTable:split2num("replace_10_cost_hero", "value", "|")[self.tenStarPartner_:getStar() - 9] then
		xyd.showToast(__("SHELTER_NOT_ENOUGH_MATERIAL"))

		return
	end

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.TEN_STAR_EXCHANGE_MATERIAL) < self.itemCost_ then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(xyd.ItemID.TEN_STAR_EXCHANGE_MATERIAL)))

		return
	end

	if xyd.tables.partnerTable:getStar10(self.typicalPartner_:getTableID()) == self.tenStarPartner_:getTableID() then
		xyd.showToast(__("TEN_STAR_EXCHANGE_TEXT06"))

		return
	end

	local function callback(yes)
		if not yes then
			return
		end

		local msg = messages_pb.replace_10_star_req()

		for i = 1, #self.materialList_[2] do
			table.insert(msg.material_ids, self.materialList_[2][i]:getPartnerID())
		end

		msg.partner_id = self.tenStarPartner_:getPartnerID()

		xyd.Backend.get():request(xyd.mid.REPLACE_10_STAR, msg)
	end

	xyd.WindowManager.get():openWindow("ten_star_exchange_confirm_window", {
		callback = callback,
		partner_id = self.tenStarPartner_:getPartnerID(),
		replace_id = xyd.tables.partnerTable:getStar10(self.typicalPartner_:getTableID())
	})
end

return TenStarExchangeWindow
