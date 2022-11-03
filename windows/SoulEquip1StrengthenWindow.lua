local BaseWindow = import(".BaseWindow")
local SoulEquip1StrengthenWindow = class("SoulEquip1StrengthenWindow", BaseWindow)
local slot = xyd.models.slot
local CommonTabBar = import("app.common.ui.CommonTabBar")
local AttrLabel = import("app.components.AttrLabel")
local SoulEquip1ExItem = class("SoulEquip1ExItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local WindowTop = import("app.components.WindowTop")

function SoulEquip1StrengthenWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curTabIndex = 1
	self.equipID = params.equipID
	self.chooseMaterailEquipIDs = {}
	self.fakeLev = 0
	self.fakeUseRes = {}
end

function SoulEquip1StrengthenWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function SoulEquip1StrengthenWindow:getUIComponent()
	self.groupAction = self.window_.transform:NodeByName("groupAction").gameObject
	self.labelWindowTitle = self.groupAction:ComponentByName("labelWindowTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.topGoup = self.groupAction:NodeByName("topGoup").gameObject
	self.labelName = self.topGoup:ComponentByName("labelName", typeof(UILabel))
	self.iconPos = self.topGoup:NodeByName("iconPos").gameObject
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.nav = self.bottomGroup:NodeByName("nav").gameObject

	for i = 1, 3 do
		self["tab" .. i] = self.nav:NodeByName("tab_" .. i).gameObject
		self["labelTab" .. i] = self["tab" .. i]:ComponentByName("label", typeof(UILabel))
	end

	self.content1 = self.bottomGroup:NodeByName("content1").gameObject
	self.attrChangeGoup = self.content1:NodeByName("attrChangeGoup").gameObject
	self.bg3 = self.attrChangeGoup:ComponentByName("bg3", typeof(UISprite))
	self.otherAttrChangeGroup = self.attrChangeGoup:NodeByName("otherAttrChangeGroup").gameObject
	self.otherAttrChangeGroupGrid = self.attrChangeGoup:ComponentByName("otherAttrChangeGroup", typeof(UIGrid))
	self.labelBaseAttr = self.attrChangeGoup:ComponentByName("labelBaseAttr", typeof(UILabel))
	self.img = self.labelBaseAttr:ComponentByName("img", typeof(UISprite))
	self.baseAttrChangeGroup = self.attrChangeGoup:NodeByName("baseAttrChangeGroup").gameObject
	self.baseAttrChangeGroupGrid = self.attrChangeGoup:ComponentByName("baseAttrChangeGroup", typeof(UIGrid))
	self.chooseGroup = self.content1:NodeByName("chooseGroup").gameObject
	self.btnLevelUpStar = self.chooseGroup:NodeByName("btnLevelUpStar").gameObject
	self.labelLevelUpStar = self.btnLevelUpStar:ComponentByName("label", typeof(UILabel))
	self.iconPosMetarial = self.chooseGroup:NodeByName("iconPos").gameObject
	self.btnPlus = self.iconPosMetarial:NodeByName("btnPlus").gameObject
	self.labelNeedNum = self.iconPosMetarial:ComponentByName("labelNeedNum", typeof(UILabel))
	self.imgFullStar = self.chooseGroup:ComponentByName("imgFullStar", typeof(UISprite))
	self.content2 = self.bottomGroup:NodeByName("content2").gameObject
	self.attrChangeGoup2 = self.content2:NodeByName("attrChangeGoup").gameObject
	self.levelChangeGroup = self.attrChangeGoup2:NodeByName("levelChangeGroup").gameObject
	self.levelChangeGroupGrid = self.attrChangeGoup2:ComponentByName("levelChangeGroup", typeof(UIGrid))
	self.labelBaseAttr2 = self.attrChangeGoup2:ComponentByName("labelBaseAttr", typeof(UILabel))
	self.baseAttrChangeGroup2 = self.attrChangeGoup2:NodeByName("baseAttrChangeGroup").gameObject
	self.baseAttrChangeGroup2Grid = self.attrChangeGoup2:ComponentByName("baseAttrChangeGroup", typeof(UIGrid))
	self.labelEXAttr = self.attrChangeGoup2:ComponentByName("labelEXAttr", typeof(UILabel))
	self.otherAttrChangeGroup2 = self.attrChangeGoup2:NodeByName("otherAttrChangeGroup").gameObject
	self.otherAttrChangeGroup2Grid = self.attrChangeGoup2:ComponentByName("otherAttrChangeGroup", typeof(UIGrid))
	self.costGroup = self.content2:NodeByName("costGroup").gameObject
	self.btnLevelUp = self.costGroup:NodeByName("btnLevelUp").gameObject
	self.labelLevelUp = self.btnLevelUp:ComponentByName("label", typeof(UILabel))
	self.costResGroup = self.costGroup:NodeByName("costResGroup").gameObject
	self.iconRes1 = self.costResGroup:ComponentByName("iconRes1", typeof(UISprite))
	self.labelRes1NeedNum = self.iconRes1:ComponentByName("labelRes1NeedNum", typeof(UILabel))
	self.iconRes2 = self.costResGroup:ComponentByName("iconRes2", typeof(UISprite))
	self.labelRes2NeedNum = self.iconRes2:ComponentByName("labelRes2NeedNum", typeof(UILabel))
	self.levUpEffectPos = self.costResGroup:ComponentByName("levUpEffectPos", typeof(UITexture))
	self.imgFullLevel = self.content2:ComponentByName("imgFullLevel", typeof(UISprite))
	self.content3 = self.bottomGroup:NodeByName("content3").gameObject
	self.exItem = self.content3:NodeByName("exItem").gameObject
	self.exScroller = self.content3:NodeByName("exScroller").gameObject
	self.exScrollView = self.content3:ComponentByName("exScroller", typeof(UIScrollView))
	self.itemGroup = self.exScroller:NodeByName("itemGroup").gameObject
	self.labelTips = self.content3:ComponentByName("labelTips", typeof(UILabel))
	local wrapContent = self.exScroller:ComponentByName("itemGroup", typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.exScrollView, wrapContent, self.exItem, SoulEquip1ExItem, self)
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
end

function SoulEquip1StrengthenWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "SOUL_EQUIP1_STRENGTHEN_HELP"
		})
	end

	UIEventListener.Get(self.btnLevelUpStar).onClick = function ()
		self:onClickBtnLevelUpStar()
	end

	UIEventListener.Get(self.btnLevelUp).onClick = function ()
		self:onClickBtnLevelUp()
	end

	UIEventListener.Get(self.btnLevelUp).onPress = handler(self, self.onLongTouchBtnLevleUp)

	UIEventListener.Get(self.btnPlus).onClick = function ()
		local equipIDList = {}
		local nextStar = math.min(self.equip:getStar() + 1, self.equip:getMaxStar())
		local materail = xyd.tables.soulEquip1Table:getMaterial(self.equip:getTableID())[self.equip:getStar()]
		local equips = xyd.models.slot:getSoulEquip1s()

		for equipID, equip in pairs(equips) do
			if equip:getTableID() == materail[1] and equipID ~= self.equip:getSoulEquipID() and equip:getAwake() < 1 and (not equip:getOwnerPartnerID() or equip:getOwnerPartnerID() <= 0) then
				table.insert(equipIDList, {
					equipID = equipID
				})
			end
		end

		local chooseEquipIDs = {}

		for key, equipID in pairs(self.chooseMaterailEquipIDs) do
			chooseEquipIDs[equipID] = 1
		end

		xyd.openWindow("choose_soul_equip_window", {
			equipIDList = equipIDList,
			chooseEquipIDs = chooseEquipIDs,
			needNum = materail[2],
			callbalck = function (chooseEquipIDs)
				self.chooseMaterailEquipIDs = {}

				for equipID, value in pairs(chooseEquipIDs) do
					table.insert(self.chooseMaterailEquipIDs, equipID)
				end

				self:updateContent1()
			end
		})
	end
end

function SoulEquip1StrengthenWindow:layout()
	self.labelWindowTitle.text = __("SOUL_EQUIP_TEXT01")
	self.labelLevelUpStar.text = __("SOUL_EQUIP_TEXT44")
	self.labelLevelUp.text = __("SOUL_EQUIP_TEXT48")
	self.labelTips.text = __("SOUL_EQUIP_TEXT49")
	self.labelBaseAttr.text = __("SOUL_EQUIP_TEXT43")
	self.labelBaseAttr2.text = __("SOUL_EQUIP_TEXT43")
	self.labelEXAttr.text = __("SOUL_EQUIP_TEXT46")
	self.labelTab1.text = __("SOUL_EQUIP_TEXT36")
	self.labelTab2.text = __("SOUL_EQUIP_TEXT37")
	self.labelTab3.text = __("SOUL_EQUIP_TEXT38")
	self.equip = xyd.models.slot:getSoulEquip(self.equipID)
	self.tabs = CommonTabBar.new(self.nav, 3, function (index)
		if self.fakeLev > 0 and not self.hasSendLevleUpMsg then
			self:cleanFakeLev()

			self.hasSendLevleUpMsg = true
		end

		if self.curTabIndex ~= index then
			self.curTabIndex = index

			self:onClickTab()
		end
	end)
	self.winTop = WindowTop.new(self.window_, self.name_, 1, false)
	local items = {
		{
			id = 1
		},
		{
			id = 417
		}
	}

	self.winTop:setItem(items)
	self.winTop:hideBg()
	xyd.setUISpriteAsync(self.imgFullStar, nil, "pet_skill_max_" .. xyd.Global.lang)
	xyd.setUISpriteAsync(self.imgFullLevel, nil, "pet_skill_max_" .. xyd.Global.lang)
	self:onClickTab()
end

function SoulEquip1StrengthenWindow:updateTopGroup()
	local params = {
		scale = 0.8981481481481481,
		uiRoot = self.iconPos,
		itemID = self.equip:getTableID(),
		callback = function ()
		end,
		soulEquipInfo = self.equip:getSoulEquipInfo(),
		soulEquipInfo = self.equip:getSoulEquipInfo()
	}
	params.soulEquipInfo.lev = params.soulEquipInfo.lev + self.fakeLev

	if self.equipIcon then
		self.equipIcon:setInfo(params)
		self.equipIcon:SetActive(true)
	else
		self.equipIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	end

	self.labelName.text = xyd.tables.itemTable:getName(self.equip:getTableID())
	self.labelName.color = xyd.getQualityColor(self.equip:getQlt())
end

function SoulEquip1StrengthenWindow:updateContent1()
	local state = nil

	if self.equip:getMaxStar() <= self.equip:getStar() then
		self.imgFullStar:SetActive(true)
		self.btnLevelUpStar:SetActive(false)
		self.iconPosMetarial:SetActive(false)

		state = "soulEquip1LevelUp"
	else
		self.imgFullStar:SetActive(false)
		self.btnLevelUpStar:SetActive(true)
		self.iconPosMetarial:SetActive(true)

		state = "soulEquipChange"
	end

	NGUITools.DestroyChildren(self.otherAttrChangeGroup.transform)
	NGUITools.DestroyChildren(self.baseAttrChangeGroup.transform)

	local nextStar = math.min(self.equip:getStar() + 1, self.equip:getMaxStar())
	local params = {
		__("SOUL_EQUIP_TEXT39"),
		self.equip:getStar(),
		nextStar
	}

	if false then
		params.state = state

		self.content1StarAttr:setInfo(params)
	else
		self.content1StarAttr = AttrLabel.new(self.otherAttrChangeGroup, state, params)
	end

	local params = {
		__("SOUL_EQUIP_TEXT40"),
		xyd.tables.miscTable:split2Cost("soul_equip1_star_lvl", "value", "|")[self.equip:getStar()],
		xyd.tables.miscTable:split2Cost("soul_equip1_star_lvl", "value", "|")[nextStar]
	}

	if false then
		params.state = state

		self.content1LevelAttr:setInfo(params)
	else
		self.content1LevelAttr = AttrLabel.new(self.otherAttrChangeGroup, state, params)
	end

	local params = {
		__("SOUL_EQUIP_TEXT41"),
		__("SOUL_EQUIP_TEXT42", xyd.tables.miscTable:split2Cost("soul_equip1_ex_num", "value", "|")[self.equip:getStar()]),
		__("SOUL_EQUIP_TEXT42", xyd.tables.miscTable:split2Cost("soul_equip1_ex_num", "value", "|")[nextStar])
	}

	if false then
		params.state = state

		self.content1ExNumAttr:setInfo(params)
	else
		self.content1ExNumAttr = AttrLabel.new(self.otherAttrChangeGroup, state, params)
	end

	self.otherAttrChangeGroupGrid:Reposition()

	for i = 1, 3 do
		local baseAttr = xyd.tables.soulEquip1Table:getBaseSingle(self.equip:getTableID(), i)

		if baseAttr and baseAttr[2] and tonumber(baseAttr[2]) > 0 then
			local singleGrow = xyd.tables.soulEquip1Table:getGrowSingle(self.equip:getTableID(), i)
			local attrValue = baseAttr[2] + singleGrow[2] * (self.equip:getLevel() + self.fakeLev)
			local params = {
				xyd.tables.dBuffTable:getDesc(baseAttr[1]),
				xyd.getBuffValue(baseAttr[1], attrValue * xyd.tables.soulEquip1Table:getStarGrow(self.equip:getTableID())[self.equip:getStar()]),
				xyd.getBuffValue(baseAttr[1], attrValue * xyd.tables.soulEquip1Table:getStarGrow(self.equip:getTableID())[nextStar])
			}

			if xyd.Global.lang == "fr_fr" and (baseAttr[1] == "unCrit" or baseAttr[1] == "unfree") then
				params[1] = __(string.upper(baseAttr[1]))
			end

			if false then
				params.state = state

				self["content1BaseAttr" .. i]:setInfo(params)
			else
				self["content1BaseAttr" .. i] = AttrLabel.new(self.baseAttrChangeGroup, state, params)
			end
		else
			local params = {
				"",
				""
			}

			if false then
				params.state = state

				self["content1BaseAttr" .. i]:setInfo(params)
			else
				self["content1BaseAttr" .. i] = AttrLabel.new(self.baseAttrChangeGroup, "soulEquip1LevelUp", params)
			end
		end
	end

	self.baseAttrChangeGroupGrid:Reposition()

	if self.equip:getStar() < self.equip:getMaxStar() then
		local materail = xyd.tables.soulEquip1Table:getMaterial(self.equip:getTableID())[self.equip:getStar()]
		self.labelNeedNum.text = #self.chooseMaterailEquipIDs .. "/" .. materail[2]
		local params = {
			scale = 1,
			uiRoot = self.iconPosMetarial,
			itemID = materail[1],
			callback = function ()
			end,
			soulEquipInfo = {}
		}

		if materail[2] <= #self.chooseMaterailEquipIDs then
			if self.materialEquipIcon then
				self.materialEquipIcon:SetActive(true)
			end

			if self.materialEquipIcon then
				self.materialEquipIcon:setInfo(params)
			else
				self.materialEquipIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			end
		elseif self.materialEquipIcon then
			self.materialEquipIcon:SetActive(false)
		end
	end
end

function SoulEquip1StrengthenWindow:updateContent2()
	local state = nil

	if self.equip:getMaxLevelInMaxStar() <= self.equip:getLevel() + self.fakeLev then
		self.costGroup:SetActive(false)
		self.imgFullLevel:SetActive(true)

		state = "soulEquip1LevelUp"
	else
		self.costGroup:SetActive(true)

		local nextLevel = self.equip:getLevel() + self.fakeLev + 1

		if self.equip:getMaxLevel() < nextLevel then
			xyd.applyChildrenGrey(self.btnLevelUp.gameObject)
		else
			xyd.applyChildrenOrigin(self.btnLevelUp.gameObject)
		end

		state = "soulEquipChange"
	end

	NGUITools.DestroyChildren(self.levelChangeGroup.transform)
	NGUITools.DestroyChildren(self.baseAttrChangeGroup2.transform)
	NGUITools.DestroyChildren(self.otherAttrChangeGroup2.transform)

	local nextLevel = math.min(self.equip:getLevel() + self.fakeLev + 1, self.equip:getMaxLevelInMaxStar())
	local params = {
		__("SOUL_EQUIP_TEXT12"),
		self.equip:getLevel() + self.fakeLev,
		nextLevel
	}

	if false then
		params.state = state

		self.content2LevelAttr:setInfo(params)
	else
		self.content2LevelAttr = AttrLabel.new(self.levelChangeGroup, state, params)
	end

	for i = 1, 3 do
		local baseAttr = xyd.tables.soulEquip1Table:getBaseSingle(self.equip:getTableID(), i)

		if baseAttr and baseAttr[2] and tonumber(baseAttr[2]) > 0 then
			local singleGrow = xyd.tables.soulEquip1Table:getGrowSingle(self.equip:getTableID(), i)
			local attrValue = baseAttr[2] + singleGrow[2] * (self.equip:getLevel() + self.fakeLev)
			local params = {
				xyd.tables.dBuffTable:getDesc(baseAttr[1]),
				xyd.getBuffValue(baseAttr[1], attrValue * xyd.tables.soulEquip1Table:getStarGrow(self.equip:getTableID())[self.equip:getStar()]),
				xyd.getBuffValue(baseAttr[1], (attrValue + singleGrow[2]) * xyd.tables.soulEquip1Table:getStarGrow(self.equip:getTableID())[self.equip:getStar()])
			}

			if xyd.Global.lang == "fr_fr" and (baseAttr[1] == "unCrit" or baseAttr[1] == "unfree") then
				params[1] = __(string.upper(baseAttr[1]))
			end

			if false then
				params.state = state

				self["content2BaseAttr" .. i]:setInfo(params)
			else
				self["content2BaseAttr" .. i] = AttrLabel.new(self.baseAttrChangeGroup2, state, params)
			end
		else
			local params = {
				"",
				""
			}

			if false then
				params.state = state

				self["content2BaseAttr" .. i]:setInfo(params)
			else
				self["content2BaseAttr" .. i] = AttrLabel.new(self.baseAttrChangeGroup2, "soulEquip1LevelUp", params)
			end
		end
	end

	local exAttrs = self.equip:getExAttr(self.fakeLev)
	local exIDs = self.equip:getExAttrIDs()

	for i = 1, self.equip:getMaxExNum() do
		if exAttrs and exAttrs[i] then
			local params = {
				xyd.tables.dBuffTable:getDesc(exAttrs[i][1]),
				xyd.getBuffValue(exAttrs[i][1], exAttrs[i][2]),
				xyd.getBuffValue(exAttrs[i][1], exAttrs[i][2] + xyd.tables.soulEquip1ExBuffTable:getGrow(exIDs[i]))
			}

			if xyd.Global.lang == "fr_fr" and (exAttrs[i][1] == "unCrit" or exAttrs[i][1] == "unfree") then
				params[1] = __(string.upper(exAttrs[i][1]))
			end

			if false then
				params.state = state

				self["content2BaseAttr" .. i]:setInfo(params)
			else
				self["content2BaseAttr" .. i] = AttrLabel.new(self.otherAttrChangeGroup2, state, params)
			end
		else
			local params = {}
			local ids = xyd.tables.miscTable:split2Cost("soul_equip1_ex_num", "value", "|")
			local unlockStar = 0

			for j = 1, #ids do
				if ids[j] == i then
					params[1] = __("SOUL_EQUIP_TEXT47", j)
					params[2] = __("SOUL_EQUIP_TEXT47", j)
					unlockStar = j

					break
				end
			end

			if unlockStar <= self.equip:getStar() then
				params[1] = ""
				params[2] = __("SOUL_EQUIP_TEXT57")

				if false then
					params.state = "soulEquip1LevelUp"

					self["content2BaseAttr" .. i]:setInfo(params)
				else
					self["content2BaseAttr" .. i] = AttrLabel.new(self.otherAttrChangeGroup2, "soulEquip1LevelUp", params)
				end
			elseif false then
				params.state = "soulEquip1Lock"

				self["content2BaseAttr" .. i]:setInfo(params)
			else
				self["content2BaseAttr" .. i] = AttrLabel.new(self.otherAttrChangeGroup2, "soulEquip1Lock", params)
			end
		end
	end

	self.levelChangeGroupGrid:Reposition()
	self.baseAttrChangeGroup2Grid:Reposition()
	self.otherAttrChangeGroup2Grid:Reposition()

	local cost = xyd.tables.expSoulEquip1Table:getCost(nextLevel)

	for i = 1, 2 do
		if xyd.models.backpack:getItemNumByID(cost[i][1]) - self:getFakeUseRes(cost[i][1]) < cost[i][2] then
			self["labelRes" .. i .. "NeedNum"].color = Color.New2(3422556671.0)
		else
			self["labelRes" .. i .. "NeedNum"].color = Color.New2(960513791)
		end
	end

	self.labelRes1NeedNum.text = cost[1][2]
	self.labelRes2NeedNum.text = cost[2][2]

	xyd.setUISpriteAsync(self.iconRes1, nil, xyd.tables.itemTable:getIcon(cost[1][1]))
	xyd.setUISpriteAsync(self.iconRes2, nil, xyd.tables.itemTable:getIcon(cost[2][1]))
end

function SoulEquip1StrengthenWindow:updateContent3()
	local star = self.equip:getStar()
	local maxStar = self.equip:getMaxStar()
	local maxExNum = self.equip:getMaxExNum()
	local exAttrs = self.equip:getExAttr(self.fakeLev)
	local exIDs = self.equip:getExAttrIDs()
	local data = {}

	for i = 1, maxExNum do
		table.insert(data, {
			index = i,
			exID = exIDs[i],
			exAttr = exAttrs[i]
		})
	end

	self.wrapContent:setInfos(data, {})
	self.exScrollView:ResetPosition()
end

function SoulEquip1StrengthenWindow:onClickTab()
	self.content1:SetActive(self.curTabIndex == 1)
	self.content2:SetActive(self.curTabIndex == 2)
	self.content3:SetActive(self.curTabIndex == 3)
	self:updateTopGroup()

	if self.curTabIndex == 1 then
		self:updateContent1()
	elseif self.curTabIndex == 2 then
		self:updateContent2()
	elseif self.curTabIndex == 3 then
		self:updateContent3()
	end
end

function SoulEquip1StrengthenWindow:onClickBtnLevelUpStar()
	local nextStar = math.min(self.equip:getStar() + 1, self.equip:getMaxStar())
	local materail = xyd.tables.soulEquip1Table:getMaterial(self.equip:getTableID())[self.equip:getStar()]

	if #self.chooseMaterailEquipIDs < materail[2] then
		return
	end

	local materialEquipIDs = {}

	for key, equipID in pairs(self.chooseMaterailEquipIDs) do
		table.insert(materialEquipIDs, equipID)
	end

	xyd.models.slot:reqAwakeSoulEquip1(self.equip:getSoulEquipID(), materialEquipIDs, function (items)
		if items then
			xyd.itemFloat(items, nil, , 7000)
		end

		self.chooseMaterailEquipIDs = {}

		self:updateTopGroup()
		self:updateContent1()
	end)
end

function SoulEquip1StrengthenWindow:onClickBtnLevelUp()
	local nextLevel = self.equip:getLevel() + self.fakeLev + 1

	if self.equip:getMaxLevel() < nextLevel then
		xyd.alertTips(__("SOUL_EQUIP_TEXT86"))

		return
	end

	local cost = xyd.tables.expSoulEquip1Table:getCost(nextLevel)

	for i = 1, #cost do
		if xyd.models.backpack:getItemNumByID(cost[i][1]) - self:getFakeUseRes(cost[i][1]) < cost[i][2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[i][1])))

			return
		end
	end

	for i = 1, 2 do
		self.fakeUseRes[cost[i][1]] = self.fakeUseRes[cost[i][1]] + cost[i][2]
	end

	local list = self.winTop:getResItemList()

	for i = 1, #list do
		local itemID = list[i]:getItemID()

		list[i]:setItemNum(xyd.models.backpack:getItemNumByID(itemID) - self:getFakeUseRes(itemID))
	end

	self.fakeLev = self.fakeLev + 1

	if self.equip:getLevel() + self.fakeLev == self.equip:getMaxLevel() then
		self:cleanFakeLev(function ()
			self:updateTopGroup()
			self:updateContent2()
		end)

		return
	end

	self:updateTopGroup()
	self:updateContent2()
end

function SoulEquip1StrengthenWindow:getFakeUseRes(itemID)
	if not self.fakeUseRes[itemID] then
		self.fakeUseRes[itemID] = 0
	end

	return self.fakeUseRes[itemID]
end

function SoulEquip1StrengthenWindow:cleanFakeLev(callback)
	if self.fakeLev <= 0 then
		if callback then
			callback()
		end

		return
	end

	xyd.models.slot:reqLevelUpSoulEquip1(self.equip:getSoulEquipID(), self.fakeLev, function ()
		if self then
			self.fakeLev = 0
			self.hasSendLevleUpMsg = false
			self.fakeUseRes = {}
		end

		if callback then
			callback()
		end
	end)
end

function SoulEquip1StrengthenWindow:onLongTouchBtnLevleUp(go, isPressed)
	local longTouchFunc = nil

	function longTouchFunc()
		if self.maxLev <= self.equip:getLevel() + self.fakeLev then
			self.levUpLongTouchFlag = false

			return
		end

		self:onClickBtnComfirmLevelUp()

		if self.levUpLongTouchFlag == true then
			XYDCo.WaitForTime(0.05, function ()
				if not self or not go or go.activeSelf == false then
					return
				end

				longTouchFunc()
			end, "soulEquip1LevUpLongTouchClick")
		end
	end

	XYDCo.StopWait("soulEquip1LevUpLongTouchClick")

	if isPressed then
		self.levUpLongTouchFlag = true

		XYDCo.WaitForTime(0.5, function ()
			if not self then
				return
			end

			if self.levUpLongTouchFlag then
				longTouchFunc()
			end
		end, "soulEquip1LevUpLongTouchClick")
	else
		self.levUpLongTouchFlag = false
	end
end

function SoulEquip1StrengthenWindow:dispose()
	SoulEquip1StrengthenWindow.super.dispose(self)

	if self.fakeLev > 0 and not self.hasSendLevleUpMsg then
		self:cleanFakeLev(function ()
			local wnd = xyd.getWindow("soul_equip_info_window")

			if wnd then
				wnd:onClickTab()
			end

			local wnd2 = xyd.getWindow("backpack_window")

			if wnd2 then
				wnd2.is_soulequip_first_data = true

				wnd2:onTabTouch(xyd.BackpackShowType.SOUL_EUQIP)
			end
		end)

		self.hasSendLevleUpMsg = true
	else
		local wnd = xyd.getWindow("soul_equip_info_window")

		if wnd then
			wnd:onClickTab()
		end

		local wnd2 = xyd.getWindow("backpack_window")

		if wnd2 then
			wnd2.is_soulequip_first_data = true

			wnd2:onTabTouch(xyd.BackpackShowType.SOUL_EUQIP)
		end
	end
end

function SoulEquip1ExItem:ctor(go, parent)
	SoulEquip1ExItem.super.ctor(self, go, parent)

	self.parent = parent
end

function SoulEquip1ExItem:initUI()
	self.exItem = self.go
	self.labelAttr = self.exItem:ComponentByName("labelAttr", typeof(UILabel))
	self.btnExchange = self.exItem:NodeByName("btnExchange").gameObject
	self.labelExchange = self.btnExchange:ComponentByName("label", typeof(UILabel))
	self.labelExItemName = self.exItem:ComponentByName("labelName", typeof(UILabel))
	self.btnExchangeCollider = self.btnExchange:GetComponent(typeof(UnityEngine.BoxCollider))

	UIEventListener.Get(self.btnExchange.gameObject).onClick = function ()
		xyd.openWindow("soul_equip_ex_preview_window", {
			equip = self.parent.equip,
			slotIndex = self.data.index,
			oldExID = self.data.exID
		})
	end
end

function SoulEquip1ExItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo(index)
end

function SoulEquip1ExItem:updateInfo(index)
	self.labelExItemName.text = __("SOUL_EQUIP_TEXT" .. 49 + self.data.index)

	if self.data.exID and self.data.exID > 0 then
		xyd.applyChildrenOrigin(self.go.gameObject)

		self.btnExchangeCollider.enabled = true
		self.labelExchange.text = __("SOUL_EQUIP_TEXT56")
		local key = self.data.exAttr[1]
		local value = self.data.exAttr[2]
		local bt = xyd.tables.dBuffTable

		if bt:isShowPercent(key) then
			local factor = bt:getFactor(key)
			value = string.format("%.2f", value * 100 / bt:getFactor(key))
			value = tostring(value) .. "%"
		else
			value = math.floor(value)
		end

		local params = {
			xyd.tables.dBuffTable:getDesc(key),
			value
		}
		self.labelAttr.text = "+" .. value .. " " .. xyd.tables.dBuffTable:getDesc(key)
	elseif xyd.tables.miscTable:split2Cost("soul_equip1_ex_num", "value", "|")[self.parent.equip:getStar()] < self.data.index then
		xyd.applyChildrenGrey(self.go.gameObject)

		self.btnExchangeCollider.enabled = false
		self.labelExchange.text = __("SOUL_EQUIP_TEXT55")
		local arr = xyd.tables.miscTable:split2Cost("soul_equip1_ex_num", "value", "|")

		for i = 1, #arr do
			if arr[i] == self.data.index then
				self.labelAttr.text = __("SOUL_EQUIP_TEXT47", i)

				break
			end
		end
	else
		xyd.applyChildrenOrigin(self.go.gameObject)

		self.btnExchangeCollider.enabled = true
		self.labelExchange.text = __("SOUL_EQUIP_TEXT55")
		self.labelAttr.text = __("SOUL_EQUIP_TEXT57")
	end
end

return SoulEquip1StrengthenWindow
