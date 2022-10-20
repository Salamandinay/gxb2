local BaseWindow = import(".BaseWindow")
local SoulEquip2StrengthenWindow = class("SoulEquip2StrengthenWindow", BaseWindow)
local slot = xyd.models.slot
local CommonTabBar = import("app.common.ui.CommonTabBar")
local AttrLabel = import("app.components.AttrLabel")
local SoulEquip2StrengthenItem = class("SoulEquip2StrengthenItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local WindowTop = import("app.components.WindowTop")
local ItemTips = import(".ItemTips")

function SoulEquip2StrengthenWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curTabIndex = 1
	self.equipID = params.equipID
	self.chooseMaterailEquipHelpArr = {}
	self.filterIndex = 0
	self.sortType = 1
	self.filterAttrs = {}
	self.filterSuit = 0
	self.chooseMateraiItemNum = 0
	self.equip = xyd.models.slot:getSoulEquip(self.equipID)
	self.newExData = {
		ex_attr_ids = self.equip:getReplacesIDs(),
		ex_factor = self.equip:getReplacesFactors()
	}
end

function SoulEquip2StrengthenWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function SoulEquip2StrengthenWindow:getUIComponent()
	self.groupAction = self.window_.transform:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelWindowTitle = self.groupAction:ComponentByName("labelWindowTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UISprite))
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
	self.baseAttrChangeGroup = self.attrChangeGoup:NodeByName("baseAttrChangeGroup").gameObject
	self.baseAttrChangeGroupGrid = self.attrChangeGoup:ComponentByName("baseAttrChangeGroup", typeof(UIGrid))
	self.exAttrChangeGroup = self.attrChangeGoup:NodeByName("exAttrChangeGroup").gameObject
	self.exAttrChangeGroupGrid = self.attrChangeGoup:ComponentByName("exAttrChangeGroup", typeof(UITable))
	self.equip2Item = self.content1:NodeByName("equip2Item").gameObject
	self.equip2Scroller = self.content1:NodeByName("equip2Scroller").gameObject
	self.equip2ScrollView = self.content1:ComponentByName("equip2Scroller", typeof(UIScrollView))
	self.itemGroup = self.equip2Scroller:NodeByName("itemGroup").gameObject
	self.btnLevelUp = self.content1:NodeByName("btnLevelUpStar").gameObject
	self.labelLevelUp = self.btnLevelUp:ComponentByName("label", typeof(UILabel))
	self.sortBtn = self.content1:NodeByName("sortBtn").gameObject
	self.arrow = self.sortBtn:ComponentByName("arrow", typeof(UISprite))
	self.labelBtnSort = self.sortBtn:ComponentByName("labelBtnSort", typeof(UILabel))
	self.sortPop = self.content1:NodeByName("sortPop").gameObject

	for i = 1, 4 do
		self["sortTab" .. i] = self.sortPop:NodeByName("tab_" .. i).gameObject
		self["labelSortTab" .. i] = self["sortTab" .. i]:ComponentByName("label", typeof(UILabel))
		self["sortChosen" .. i] = self["sortTab" .. i]:ComponentByName("chosen", typeof(UISprite))
	end

	self.filterBtn = self.content1:NodeByName("filterBtn").gameObject
	self.arrowfilter = self.filterBtn:ComponentByName("arrow", typeof(UISprite))
	self.labelBtnFilter = self.filterBtn:ComponentByName("labelBtnFilter", typeof(UILabel))
	self.filterPop = self.content1:NodeByName("filterPop").gameObject
	self.filters = self.filterPop:NodeByName("filters").gameObject

	for i = 1, 4 do
		self["btnFilterPos" .. i] = self.filters:NodeByName("btnFilterPos" .. i).gameObject
		self["labelFilterPos" .. i] = self["btnFilterPos" .. i]:ComponentByName("label", typeof(UILabel))
	end

	self.btnFilterSuit = self.filterPop:NodeByName("btnFilterSuit").gameObject
	self.labelFilterSuit = self.btnFilterSuit:ComponentByName("label", typeof(UILabel))
	self.btnFilterAttr = self.filterPop:NodeByName("btnFilterAttr").gameObject
	self.labelFilterAttr = self.btnFilterAttr:ComponentByName("label", typeof(UILabel))
	self.btnAutoSelect = self.filterPop:NodeByName("btnAutoSelect").gameObject
	self.labelAutoSelect = self.btnAutoSelect:ComponentByName("label", typeof(UILabel))
	self.progressGroup = self.content1:ComponentByName("progressGroup", typeof(UIProgressBar))
	self.labelCurLevel = self.progressGroup:ComponentByName("labelCurLevel", typeof(UILabel))
	self.progressBg = self.progressGroup:ComponentByName("progressBg", typeof(UISprite))
	self.progressBar = self.progressGroup:ComponentByName("progressBar", typeof(UISprite))
	self.progressLabel = self.progressGroup:ComponentByName("progressLabel", typeof(UILabel))
	self.imgFullLev = self.content1:ComponentByName("imgFullLev", typeof(UISprite))
	self.itemTipsGroup = self.content1:NodeByName("itemTipsGroup").gameObject
	self.itemTipsPos = self.itemTipsGroup:NodeByName("itemTipsPos").gameObject
	self.content2 = self.bottomGroup:NodeByName("content2").gameObject
	self.attrChangeGoup2 = self.content2:NodeByName("attrChangeGoup").gameObject
	self.otherAttrChangeGroup = self.attrChangeGoup2:NodeByName("otherAttrChangeGroup").gameObject
	self.labelBaseAttr = self.attrChangeGoup2:ComponentByName("labelBaseAttr", typeof(UILabel))
	self.baseAttrChangeGroup2 = self.attrChangeGoup2:NodeByName("baseAttrChangeGroup").gameObject
	self.labelExAttr = self.attrChangeGoup2:ComponentByName("labelExAttr", typeof(UILabel))
	self.exAttrChangeGroup2 = self.attrChangeGoup2:NodeByName("exAttrChangeGroup").gameObject
	self.exAttrChangeGroup2Grid = self.attrChangeGoup2:ComponentByName("exAttrChangeGroup", typeof(UIGrid))
	self.costGroup = self.attrChangeGoup2:NodeByName("costGroup").gameObject
	self.btnGradeUp = self.costGroup:NodeByName("btnGradeUp").gameObject
	self.labelGradeUp = self.btnGradeUp:ComponentByName("label", typeof(UILabel))
	self.costResGroup = self.costGroup:NodeByName("costResGroup").gameObject
	self.iconRes1 = self.costResGroup:ComponentByName("iconRes1", typeof(UISprite))
	self.labelRes1NeedNum = self.iconRes1:ComponentByName("labelRes1NeedNum", typeof(UILabel))
	self.iconRes2 = self.costResGroup:ComponentByName("iconRes2", typeof(UISprite))
	self.labelRes2NeedNum = self.iconRes2:ComponentByName("labelRes2NeedNum", typeof(UILabel))
	self.btnReset = self.content2:NodeByName("btnReset").gameObject
	self.labelFullGrade = self.content2:ComponentByName("labelFullGrade", typeof(UILabel))
	self.content3 = self.bottomGroup:NodeByName("content3").gameObject
	self.labelExAttr3 = self.content3:ComponentByName("labelExAttr", typeof(UILabel))
	self.exAttrChangeGroup3 = self.content3:NodeByName("exAttrChangeGroup").gameObject
	self.exAttrChangeGroup3Grid = self.content3:ComponentByName("exAttrChangeGroup", typeof(UITable))
	self.labeTips = self.content3:ComponentByName("labeTips", typeof(UILabel))
	self.exchangeGroup = self.content3:NodeByName("exchangeGroup").gameObject
	self.oldContent = self.exchangeGroup:NodeByName("oldContent").gameObject
	self.labelTitleOld = self.oldContent:ComponentByName("labelTitle", typeof(UILabel))
	self.labelAttrOld = self.oldContent:ComponentByName("labelAttr", typeof(UILabel))
	self.newContent = self.exchangeGroup:NodeByName("newContent").gameObject
	self.labelTitleNew = self.newContent:ComponentByName("labelTitle", typeof(UILabel))
	self.labelAttrNew = self.newContent:ComponentByName("labelAttr", typeof(UILabel))
	self.effectPos = self.newContent:ComponentByName("effectPos", typeof(UITexture))
	self.costGroup3 = self.content3:NodeByName("costGroup").gameObject
	self.btnExchange = self.costGroup3:NodeByName("btnExchange").gameObject
	self.labelExchang = self.btnExchange:ComponentByName("label", typeof(UILabel))
	self.btnSave = self.costGroup3:NodeByName("btnSave").gameObject
	self.labelSave = self.btnSave:ComponentByName("label", typeof(UILabel))
	self.costResGroup3 = self.costGroup3:NodeByName("costResGroup").gameObject
	self.iconRes31 = self.costResGroup3:ComponentByName("iconRes1", typeof(UISprite))
	self.labelRes31NeedNum = self.iconRes31:ComponentByName("labelRes1NeedNum", typeof(UILabel))
	self.iconRes32 = self.costResGroup3:ComponentByName("iconRes2", typeof(UISprite))
	self.labelRes32NeedNum = self.iconRes32:ComponentByName("labelRes2NeedNum", typeof(UILabel))
	local wrapContent = self.equip2Scroller:ComponentByName("itemGroup", typeof(MultiRowWrapContent))
	self.multiWrap = require("app.common.ui.FixedMultiWrapContent").new(self.equip2ScrollView, wrapContent, self.equip2Item, SoulEquip2StrengthenItem, self)
end

function SoulEquip2StrengthenWindow:register()
	self.eventProxy_:addEventListener(xyd.event.LEV_UP_CHIME, function (event)
	end)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnLevelUp).onClick = function ()
		local flag = self.chooseMateraiItemNum > 0

		if not flag then
			for equipID, value in pairs(self.chooseMaterailEquipHelpArr) do
				local equip = xyd.models.slot:getSoulEquip(equipID)

				if equip or self.chooseMateraiItemNum > 0 then
					flag = true

					break
				end
			end
		end

		if flag then
			xyd.models.slot:reqLevelUpSoulEquip2(self.equipID, self.chooseMateraiItemNum, self.chooseMaterailEquipHelpArr, self.fakeLev - self.equip:getLevel(), function (ex_ids, ex_factors)
				self.equip:setExAttr(ex_ids, ex_factors)

				self.chooseMaterailEquipHelpArr = {}
				self.fakeLev = 0
				self.chooseMateraiItemNum = 0

				self:updateItemTipsGroup(false)
				self:updateContent1()
				self:updateTopGroup()
			end)
		end
	end

	UIEventListener.Get(self.btnAutoSelect).onClick = function ()
		xyd.openWindow("soul_equip_auto_choose_window", {
			equip = self.equip
		})
	end

	UIEventListener.Get(self.btnFilterAttr).onClick = function ()
		xyd.openWindow("soul_equip_sort_window", {
			filterAttrs = self.filterAttrs
		})
	end

	UIEventListener.Get(self.btnFilterSuit).onClick = function ()
		xyd.openWindow("soul_equip_choose_suit_window", {
			curSelectSuitID = self.filterSuit
		})
	end

	for i = 1, 4 do
		UIEventListener.Get(self["btnFilterPos" .. i]).onClick = function ()
			if self.filterIndex == i + 1 then
				self.filterIndex = 0
			else
				self.filterIndex = i + 1
			end

			self:updateContent1()
		end
	end

	UIEventListener.Get(self.sortBtn).onClick = function ()
		if self.filterPop.activeSelf == true then
			self:onClickFilterBtn()
		end

		self:onClickSortBtn()
	end

	UIEventListener.Get(self.filterBtn).onClick = function ()
		if self.sortPop.activeSelf == true then
			self:onClickSortBtn()
		end

		self:onClickFilterBtn()
	end

	UIEventListener.Get(self.btnReset).onClick = function ()
		self:onClickBtnReset()
	end

	UIEventListener.Get(self.btnGradeUp).onClick = function ()
		local cost = xyd.tables.soulEquip2Table:getMaterial(self.equip:getTableID())[self.equip:getQlt()]

		for i = 1, #cost do
			if xyd.models.backpack:getItemNumByID(cost[i][1]) < cost[i][2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[i][1])))

				return
			end
		end

		xyd.models.slot:reqAwakeSoulEquip2(self.equipID, function ()
			self:updateTopGroup()
			self:updateContent2()
		end)
	end

	UIEventListener.Get(self.btnExchange).onClick = function ()
		if self.equip:getLevel() < self.equip:getMaxLevel() then
			xyd.alertTips(__("SOUL_EQUIP_TEXT80"))

			return
		end

		local cost = xyd.tables.miscTable:split2Cost("soul_equip2_ex_cost", "value", "|#")

		for i = 1, #cost do
			local selfNum = xyd.models.backpack:getItemNumByID(cost[i][1])

			if selfNum < cost[i][2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[i][1])))

				return
			end
		end

		if self.haveClick then
			return
		end

		self.haveClick = true

		xyd.models.slot:reqChangeExBuff2(self.equipID, function (ex_ids, ex_factors)
			self.newExData = {
				ex_attr_ids = ex_ids,
				ex_factor = ex_factors
			}

			self.equip:setReplaces(ex_ids, ex_factors)

			local effect = self.onChangeEffect

			if effect == nil then
				effect = xyd.Spine.new(self.effectPos.gameObject)
				self.onChangeEffect = effect

				effect:setInfo("anniuzhuanhuan", function ()
					if not self then
						return
					end

					effect:SetLocalPosition(-160, 9, 0)
					effect:SetLocalScale(0.9140625, 1.2114285714285715, 1)
					effect:play("texiao01", 1)
					effect:play("texiao01", 1, 1, function ()
						self:updateContent3()

						self.haveClick = false
					end, true)
				end)
			else
				effect:play("texiao01", 1, 1, function ()
					self:updateContent3()

					self.haveClick = false
				end, true)
			end
		end)
	end

	UIEventListener.Get(self.btnSave).onClick = function ()
		xyd.models.slot:reqSaveExBuff2(self.equipID, function ()
			self.equip:setExAttr(self.newExData.ex_attr_ids, self.newExData.ex_factor)

			self.newExData.ex_attr_ids = {}
			self.newExData.ex_factor = {}

			self.equip:setReplaces({}, {})
			self:updateContent3()

			local ownerID = self.equip:getOwnerPartnerID()

			if ownerID and ownerID > 0 then
				local owner = xyd.models.slot:getPartner(ownerID)

				if owner then
					owner:updateAttrs()
				end
			end
		end)
	end

	UIEventListener.Get(self.itemTipsGroup).onClick = function ()
		self:updateItemTipsGroup(false)
	end
end

function SoulEquip2StrengthenWindow:layout()
	self.labelWindowTitle.text = __("SOUL_EQUIP_TEXT01")
	self.labelTab1.text = __("SOUL_EQUIP_TEXT59")
	self.labelTab2.text = __("SOUL_EQUIP_TEXT60")
	self.labelTab3.text = __("SOUL_EQUIP_TEXT61")
	self.labelBtnFilter.text = __("SOUL_EQUIP_TEXT63")
	self.labelLevelUp.text = __("SOUL_EQUIP_TEXT48")
	self.labelGradeUp.text = __("SOUL_EQUIP_TEXT88")
	self.labelExchang.text = __("SOUL_EQUIP_TEXT89")
	self.labelBaseAttr.text = __("SOUL_EQUIP_TEXT70")
	self.labelExAttr.text = __("SOUL_EQUIP_TEXT71")
	self.labeTips.text = __("SOUL_EQUIP_TEXT75")
	self.labelTitleOld.text = __("SOUL_EQUIP_TEXT76")
	self.labelTitleNew.text = __("SOUL_EQUIP_TEXT77")
	self.labelAutoSelect.text = __("SOUL_EQUIP_TEXT62")
	self.labelExAttr3.text = __("SOUL_EQUIP_TEXT74")
	self.labelFullGrade.text = __("SOUL_EQUIP_TEXT73")
	self.labelSave.text = __("SOUL_EQUIP_TEXT25")
	self.labelSortTab1.text = __("SOUL_EQUIP_TEXT12")
	self.labelSortTab2.text = __("SOUL_EQUIP_TEXT13")
	self.labelSortTab3.text = __("SOUL_EQUIP_TEXT14")
	self.labelSortTab4.text = __("SOUL_EQUIP_TEXT15")
	self.labelFilterPos1.text = __("SOUL_EQUIP_TEXT16")
	self.labelFilterPos2.text = __("SOUL_EQUIP_TEXT17")
	self.labelFilterPos3.text = __("SOUL_EQUIP_TEXT18")
	self.labelFilterPos4.text = __("SOUL_EQUIP_TEXT19")
	self.labelFilterSuit.text = __("SOUL_EQUIP_TEXT09")
	self.labelFilterAttr.text = __("SOUL_EQUIP_TEXT10")
	self.tabs = CommonTabBar.new(self.nav, 3, function (index)
		if self.curTabIndex ~= index then
			self.curTabIndex = index

			self:onClickTab()
		end
	end)
	self.sortTab = CommonTabBar.new(self.sortPop, 4, function (index)
		if self.sortType ~= index then
			self:onClickSortBtn()
		end

		self.sortType = index

		self:updateContent1()
	end)
	self.winTop = WindowTop.new(self.window_, self.name_, 1, false)
	local items = {
		{
			id = 1
		},
		{
			id = 426
		}
	}

	self.winTop:setItem(items)
	self.winTop:hideBg()
	xyd.setUISpriteAsync(self.imgFullLev, nil, "pet_skill_max_" .. xyd.Global.lang)
	self:onClickTab()
end

function SoulEquip2StrengthenWindow:updateTopGroup()
	local params = {
		scale = 0.8981481481481481,
		uiRoot = self.iconPos,
		itemID = self.equip:getTableID(),
		callback = function ()
		end,
		soulEquipInfo = self.equip:getSoulEquipInfo()
	}

	if self.equipIcon then
		self.equipIcon:setInfo(params)
		self.equipIcon:SetActive(true)
	else
		self.equipIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	end

	self.labelName.text = xyd.tables.itemTable:getName(self.equip:getTableID())
	self.labelName.color = xyd.getQualityColor(self.equip:getQlt())

	self.winTop.go:SetActive(self.curTabIndex ~= 1)
end

function SoulEquip2StrengthenWindow:updateProgressGroup()
	local lev = self.equip:getLevel()
	local maxLev = self.equip:getMaxLevel()
	self.fakeExp = self.equip:getCurExp()
	self.fakeLev = lev

	for equipID, value in pairs(self.chooseMaterailEquipHelpArr) do
		local equip = xyd.models.slot:getSoulEquip(equipID)
		local exp = xyd.tables.soulEquip2Table:getExp(equip:getTableID())

		if equip:getLevel() > 0 then
			dump(exp)
			dump(equip:getLevel())
			dump(xyd.tables.expSoulEquip2Table:getCost(equip:getLevel()))
			dump(xyd.tables.miscTable:getNumber("soul_equip2_lvl_exp_cost", "value"))

			exp = exp + xyd.tables.expSoulEquip2Table:getAllExp(equip:getLevel()) * xyd.tables.miscTable:getNumber("soul_equip2_lvl_exp_cost", "value")
		end

		self.fakeExp = self.fakeExp + exp
	end

	local itemSoulEquipMaterial = xyd.tables.miscTable:split2Cost("soul_equip2_sp_item", "value", "#")
	local itemSoulEquipSingleExp = itemSoulEquipMaterial[3]
	self.fakeExp = self.fakeExp + itemSoulEquipSingleExp * self.chooseMateraiItemNum

	for i = 1, 99999 do
		if self.fakeLev < maxLev and xyd.tables.expSoulEquip2Table:getCost(self.fakeLev + 1) <= self.fakeExp then
			self.fakeExp = self.fakeExp - xyd.tables.expSoulEquip2Table:getCost(self.fakeLev + 1)
			self.fakeLev = self.fakeLev + 1
		else
			break
		end
	end

	if maxLev <= self.fakeLev then
		self.fakeExp = 0
	end

	local nextLevel = math.min(self.fakeLev + 1, maxLev)

	if xyd.Global.lang == "fr_fr" then
		self.labelCurLevel.text = "Niv." .. " " .. self.fakeLev .. "/" .. maxLev
	else
		self.labelCurLevel.text = "Lv." .. " " .. self.fakeLev .. "/" .. maxLev
	end

	self.progressGroup.value = self.fakeExp / xyd.tables.expSoulEquip2Table:getCost(nextLevel)
	self.progressLabel.text = self.fakeExp .. "/" .. xyd.tables.expSoulEquip2Table:getCost(nextLevel)
end

function SoulEquip2StrengthenWindow:updateItemTipsGroup(show, params)
	NGUITools.DestroyChildren(self.itemTipsPos.transform)

	self.tips = nil

	self.itemTipsGroup:SetActive(show)

	if show then
		self.tips = ItemTips.new(self.itemTipsPos, params)
	end
end

function SoulEquip2StrengthenWindow:updateContent1(notUpdateWrapContent)
	for i = 1, 4 do
		self.sortTab:setTabEnable(i, false)
	end

	local textArr = {
		[0] = __("SOUL_EQUIP_TEXT11"),
		__("SOUL_EQUIP_TEXT12"),
		__("SOUL_EQUIP_TEXT13"),
		__("SOUL_EQUIP_TEXT14"),
		__("SOUL_EQUIP_TEXT15")
	}
	self.labelBtnSort.text = textArr[self.sortType]

	for i = 1, 4 do
		self.sortTab:setTabEnable(i, true)
	end

	if #self.filterAttrs > 0 then
		self.labelFilterAttr.text = xyd.tables.dBuffTable:getDesc(self.filterAttrs[1])
	else
		self.labelFilterAttr.text = __("SOUL_EQUIP_TEXT10")
	end

	self:updatePosFilter()

	local lev = self.equip:getLevel()
	local maxLev = self.equip:getMaxLevel()
	local nextLevel = math.min(lev + 1, maxLev)

	self:updateProgressGroup()

	local state = "soulEquipChange"

	if self.fakeLev <= lev then
		state = "soulEquip1LevelUp"
	end

	local baseAttrID = self.equip:getBaseAttrID()
	local baseAttr = self.equip:getBaseAttr()[1]
	local nextLevBaseAttr = self.equip:getBaseAttr(self.fakeLev - lev)[1]
	local params = {
		xyd.tables.dBuffTable:getDesc(baseAttr[1]),
		xyd.getBuffValue(baseAttr[1], baseAttr[2]),
		xyd.getBuffValue(baseAttr[1], nextLevBaseAttr[2])
	}

	if xyd.Global.lang == "fr_fr" and (baseAttr[1] == "unCrit" or baseAttr[1] == "unfree") then
		params[1] = __(string.upper(baseAttr[1]))
	end

	NGUITools.DestroyChildren(self.baseAttrChangeGroup.transform)

	self.content1BaseAttr = nil

	if self.content1BaseAttr then
		params.state = state

		self.content1BaseAttr:setInfo(params)
	else
		self.content1BaseAttr = AttrLabel.new(self.baseAttrChangeGroup, state, params)
	end

	NGUITools.DestroyChildren(self.exAttrChangeGroup.transform)

	local exAttr = self.equip:getExAttr()

	for i = 1, 4 do
		local attr = exAttr[i]

		if attr and attr[2] and attr[2] > 0 then
			state = "soulEquip2Show"
			local params = {
				xyd.tables.dBuffTable:getDesc(attr[1]),
				xyd.getBuffValue(attr[1], attr[2])
			}

			if xyd.Global.lang == "fr_fr" and (attr[1] == "unCrit" or attr[1] == "unfree") then
				params[1] = __(string.upper(attr[1]))
			end

			self["content1ExAttr" .. i] = nil

			if self["content1ExAttr" .. i] then
				params.state = state

				self["content1ExAttr" .. i]:setInfo(params)
			else
				self["content1ExAttr" .. i] = AttrLabel.new(self.exAttrChangeGroup, state, params)
			end
		else
			self["content1ExAttr" .. i] = nil
			local params = {
				"",
				__("SOUL_EQUIP_TEXT32", xyd.tables.miscTable:split2Cost("soul_equip2_ex_buff_lvl", "value", "#")[i - #self.equip:getInitExAttr()])
			}

			if self["content1ExAttr" .. i] then
				params.state = state

				self["content1ExAttr" .. i]:setInfo(params)
			else
				self["content1ExAttr" .. i] = AttrLabel.new(self.exAttrChangeGroup, "soulEquip2Lock", params)
			end
		end
	end

	self.exAttrChangeGroupGrid:Reposition()

	local data = {}
	local equips = xyd.models.slot:getSoulEquip2s()

	for id, equip in pairs(equips) do
		local pos = equip:getPos()

		if self.filterIndex == 0 or pos == self.filterIndex then
			local flag = true

			if self.filterSuit > 0 and self.filterSuit ~= xyd.tables.soulEquip2Table:getGroup(equip:getTableID()) then
				flag = false
			end

			if #self.filterAttrs > 0 and not equip:containAttr(self.filterAttrs) then
				flag = false
			end

			if flag then
				table.insert(data, {
					equip = equip
				})
			end
		end
	end

	if maxLev <= lev then
		self.sortBtn:SetActive(false)
		self.btnLevelUp:SetActive(false)
		self.filterBtn:SetActive(false)
		self.sortPop:SetActive(false)
		self.filterPop:SetActive(false)
		self.equip2Scroller:SetActive(false)
		self.imgFullLev:SetActive(true)

		return
	end

	if notUpdateWrapContent then
		return
	end

	local sortFunc = nil

	if self.sortType == 1 then
		function sortFunc(a, b)
			local aLevel = a.equip:getLevel()
			local bLevel = b.equip:getLevel()
			local aStar = a.equip:getStar()
			local bStar = b.equip:getStar()
			local aQlt = a.equip:getQlt()
			local bQlt = b.equip:getQlt()

			if aLevel ~= bLevel then
				return bLevel < aLevel
			elseif aStar ~= bStar then
				return aStar < bStar
			elseif aQlt ~= bQlt then
				return bQlt < aQlt
			else
				return a.equip:getSoulEquipID() < b.equip:getSoulEquipID()
			end
		end
	elseif self.sortType == 2 then
		function sortFunc(a, b)
			local aLevel = a.equip:getLevel()
			local bLevel = b.equip:getLevel()
			local aStar = a.equip:getStar()
			local bStar = b.equip:getStar()
			local aQlt = a.equip:getQlt()
			local bQlt = b.equip:getQlt()

			if aStar ~= bStar then
				return aStar < bStar
			elseif aLevel ~= bLevel then
				return bLevel < aLevel
			elseif aQlt ~= bQlt then
				return bQlt < aQlt
			else
				return a.equip:getSoulEquipID() < b.equip:getSoulEquipID()
			end
		end
	elseif self.sortType == 3 then
		function sortFunc(a, b)
			local aLevel = a.equip:getLevel()
			local bLevel = b.equip:getLevel()
			local aStar = a.equip:getStar()
			local bStar = b.equip:getStar()
			local aQlt = a.equip:getQlt()
			local bQlt = b.equip:getQlt()

			if aQlt ~= bQlt then
				return bQlt < aQlt
			elseif aLevel ~= bLevel then
				return bLevel < aLevel
			elseif aStar ~= bStar then
				return aStar < bStar
			else
				return a.equip:getSoulEquipID() < b.equip:getSoulEquipID()
			end
		end
	else
		function sortFunc(a, b)
			local aGetTime = a.equip:getGetTime()
			local bGetTime = b.equip:getGetTime()
			local aLevel = a.equip:getLevel()
			local bLevel = b.equip:getLevel()
			local aStar = a.equip:getStar()
			local bStar = b.equip:getStar()
			local aQlt = a.equip:getQlt()
			local bQlt = b.equip:getQlt()

			if aGetTime ~= bGetTime then
				return bGetTime < aGetTime
			elseif aLevel ~= bLevel then
				return bLevel < aLevel
			elseif aStar ~= bStar then
				return bStar < aStar
			elseif aQlt ~= bQlt then
				return bQlt < aQlt
			else
				return a.equip:getSoulEquipID() < b.equip:getSoulEquipID()
			end
		end
	end

	table.sort(data, sortFunc)

	local newData = {}
	local itemMaterial = xyd.tables.miscTable:split2Cost("soul_equip2_sp_item", "value", "#")
	local itemID = itemMaterial[1]

	if xyd.models.backpack:getItemNumByID(itemID) > 0 then
		table.insert(newData, {
			itemID = itemID
		})
	end

	for key, value in pairs(data) do
		table.insert(newData, value)
	end

	self.equip2ScrollView:SetActive(#newData > 0)
	self.multiWrap:setInfos(newData, {})
	self.equip2ScrollView:ResetPosition()
end

function SoulEquip2StrengthenWindow:updateContent2()
	local state = nil
	local qlt = self.equip:getQlt()
	local nextQlt = math.min(self.equip:getMaxQlt(), qlt + 1)

	if nextQlt <= qlt then
		self.costGroup:SetActive(false)
		self.labelFullGrade:SetActive(true)

		state = "soulEquip1LevelUp"
	else
		self.costGroup:SetActive(true)
		self.labelFullGrade:SetActive(false)

		state = "soulEquipChange"
	end

	NGUITools.DestroyChildren(self.otherAttrChangeGroup.transform)

	local params = {
		__("SOUL_EQUIP_TEXT69"),
		__("TIME_CLOISTER_TEXT" .. 71 + qlt),
		__("TIME_CLOISTER_TEXT" .. 71 + nextQlt)
	}
	self.contentQltAttr = nil

	if self.contentQltAttr then
		params.state = state

		self.contentQltAttr:setInfo(params)
	else
		self.contentQltAttr = AttrLabel.new(self.otherAttrChangeGroup, state, params)
	end

	NGUITools.DestroyChildren(self.baseAttrChangeGroup2.transform)

	local baseAttrID = self.equip:getBaseAttrID()
	local baseAttr = self.equip:getBaseAttr()[1]
	local nowQltFactor = xyd.tables.soulEquip2BaseBuffTable:getQltGrow(baseAttrID)[qlt]
	local nextQltFactor = xyd.tables.soulEquip2BaseBuffTable:getQltGrow(baseAttrID)[nextQlt]
	local nextBaseAttr = self.equip:getBaseAttr(1)[1]
	local params = {
		xyd.tables.dBuffTable:getDesc(baseAttr[1]),
		xyd.getBuffValue(baseAttr[1], baseAttr[2]),
		xyd.getBuffValue(baseAttr[1], baseAttr[2] * nextQltFactor / nowQltFactor)
	}

	if xyd.Global.lang == "fr_fr" and (baseAttr[1] == "unCrit" or baseAttr[1] == "unfree") then
		params[1] = __(string.upper(baseAttr[1]))
	end

	self.content2BaseAttr = nil

	if self.content2BaseAttr then
		params.state = state

		self.content2BaseAttr:setInfo(params)
	else
		self.content2BaseAttr = AttrLabel.new(self.baseAttrChangeGroup2, state, params)
	end

	NGUITools.DestroyChildren(self.exAttrChangeGroup2.transform)

	local exAttr = self.equip:getExAttr()

	for i = 1, 4 do
		local attr = exAttr[i]

		if attr and attr[2] and attr[2] > 0 then
			if nextQlt <= qlt then
				state = "soulEquip1LevelUp"
			else
				state = "soulEquipChange"
			end

			local params = {
				xyd.tables.dBuffTable:getDesc(attr[1]),
				xyd.getBuffValue(attr[1], attr[2]),
				xyd.getBuffValue(attr[1], attr[2] * nextQltFactor / nowQltFactor)
			}

			if xyd.Global.lang == "fr_fr" and (attr[1] == "unCrit" or attr[1] == "unfree") then
				params[1] = __(string.upper(attr[1]))
			end

			self["content2ExAttr" .. i] = nil

			if self["content2ExAttr" .. i] then
				params.state = state

				self["content2ExAttr" .. i]:setInfo(params)
			else
				self["content2ExAttr" .. i] = AttrLabel.new(self.exAttrChangeGroup2, state, params)
			end
		else
			local params = {
				"",
				__("SOUL_EQUIP_TEXT32", xyd.tables.miscTable:split2Cost("soul_equip2_ex_buff_lvl", "value", "#")[i - #self.equip:getInitExAttr()])
			}
			state = "soulEquip1Lock"
			self["content2ExAttr" .. i] = nil

			if self["content2ExAttr" .. i] then
				params.state = state

				self["content2ExAttr" .. i]:setInfo(params)
			else
				self["content2ExAttr" .. i] = AttrLabel.new(self.exAttrChangeGroup2, state, params)
			end
		end
	end

	self.exAttrChangeGroup2Grid:Reposition()

	if qlt < nextQlt then
		local cost = xyd.tables.soulEquip2Table:getMaterial(self.equip:getTableID())[qlt]

		for i = 1, 2 do
			if xyd.models.backpack:getItemNumByID(cost[i][1]) < cost[i][2] then
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
end

function SoulEquip2StrengthenWindow:updateContent3()
	local state = nil

	NGUITools.DestroyChildren(self.exAttrChangeGroup3.transform)

	local exAttr = self.equip:getInitExAttr()

	for i = 1, 4 do
		local attr = exAttr[i]

		if attr and attr[2] and attr[2] > 0 then
			state = "soulEquip2Show"
			local params = {
				xyd.tables.dBuffTable:getDesc(attr[1]),
				xyd.getBuffValue(attr[1], attr[2])
			}

			if xyd.Global.lang == "fr_fr" and (attr[1] == "unCrit" or attr[1] == "unfree") then
				params[1] = __(string.upper(attr[1]))
			end

			self["content2ExAttr" .. i] = nil

			if self["content2ExAttr" .. i] then
				params.state = state

				self["content2ExAttr" .. i]:setInfo(params)
			else
				self["content2ExAttr" .. i] = AttrLabel.new(self.exAttrChangeGroup3, state, params)
			end
		else
			local params = {
				"",
				""
			}
			state = "soulEquip2Lock"
			self["content2ExAttr" .. i] = nil

			if self["content2ExAttr" .. i] then
				params.state = state

				self["content2ExAttr" .. i]:setInfo(params)
			else
				self["content2ExAttr" .. i] = AttrLabel.new(self.exAttrChangeGroup3, state, params)
			end
		end
	end

	self.exAttrChangeGroup3Grid:Reposition()

	self.labelAttrOld.text = ""
	local exAttr = self.equip:getExAttr()

	for i = 1, #exAttr do
		local attr = exAttr[i]

		if attr and attr[2] and attr[2] > 0 then
			if i > 1 then
				self.labelAttrOld.text = self.labelAttrOld.text .. "\n"
			end

			local bt = xyd.tables.dBuffTable
			local valueText = nil

			if bt:isShowPercent(attr[1]) then
				local factor = bt:getFactor(attr[1])
				valueText = string.format("%.2f", attr[2] * 100 / bt:getFactor(attr[1]))
				valueText = tostring(valueText) .. "%"
			else
				valueText = math.floor(attr[2])
			end

			self.labelAttrOld.text = self.labelAttrOld.text .. "+" .. valueText .. " " .. xyd.tables.dBuffTable:getDesc(attr[1])
		end
	end

	if not self.newExData.ex_attr_ids[1] then
		self.labelAttrNew.text = __("SOUL_EQUIP_TEXT57")

		self.btnSave:SetActive(false)
		self.btnExchange:X(0)
	else
		self.labelAttrNew.text = ""

		self.btnSave:SetActive(true)
		self.btnSave:X(140)
		self.btnExchange:X(-140)

		local newExAttr = {}
		local baseAttrID = self.equip:getBaseAttrID()
		local starFactor = xyd.tables.soulEquip2BaseBuffTable:getStarGrow(baseAttrID)[self.equip:getStar()]
		local qltFactor = xyd.tables.soulEquip2BaseBuffTable:getQltGrow(baseAttrID)[self.equip:getQlt()]

		for i = 1, #self.newExData.ex_attr_ids do
			local exID = self.newExData.ex_attr_ids[i]
			local buff = xyd.tables.soulEquip2ExBuffTable:getBuff(exID)
			local baseAttr = xyd.tables.soulEquip2ExBuffTable:getBase(exID)
			local buffValue = baseAttr * starFactor * qltFactor * self.newExData.ex_factor[i]
			newExAttr[i] = {
				buff,
				buffValue
			}
		end

		local allnewAttr = {}
		local allnewHelpAttr = {}
		local initexAttr = self.equip:getInitExAttr()

		for i = 1, #initexAttr do
			local attr = initexAttr[i]

			if not allnewHelpAttr[attr[1]] then
				table.insert(allnewAttr, attr)

				allnewHelpAttr[attr[1]] = #allnewAttr
			else
				allnewAttr[allnewHelpAttr[attr[1]]][2] = allnewAttr[allnewHelpAttr[attr[1]]][2] + attr[2]
			end
		end

		for i = 1, #newExAttr do
			local attr = newExAttr[i]

			if not allnewHelpAttr[attr[1]] then
				table.insert(allnewAttr, attr)

				allnewHelpAttr[attr[1]] = #allnewAttr
			else
				allnewAttr[allnewHelpAttr[attr[1]]][2] = allnewAttr[allnewHelpAttr[attr[1]]][2] + attr[2]
			end
		end

		for i = 1, #allnewAttr do
			local attr = allnewAttr[i]

			if attr and attr[2] and attr[2] > 0 then
				if i > 1 then
					self.labelAttrNew.text = self.labelAttrNew.text .. "\n"
				end

				local bt = xyd.tables.dBuffTable
				local valueText = nil

				if bt:isShowPercent(attr[1]) then
					local factor = bt:getFactor(attr[1])
					valueText = string.format("%.2f", attr[2] * 100 / bt:getFactor(attr[1]))
					valueText = tostring(valueText) .. "%"
				else
					valueText = math.floor(attr[2])
				end

				self.labelAttrNew.text = self.labelAttrNew.text .. "+" .. valueText .. " " .. xyd.tables.dBuffTable:getDesc(attr[1])
			end
		end
	end

	local cost = xyd.tables.miscTable:split2Cost("soul_equip2_ex_cost", "value", "|#")

	for i = 1, 2 do
		if xyd.models.backpack:getItemNumByID(cost[i][1]) < cost[i][2] then
			self["labelRes3" .. i .. "NeedNum"].color = Color.New2(3422556671.0)
		else
			self["labelRes3" .. i .. "NeedNum"].color = Color.New2(960513791)
		end
	end

	self.labelRes31NeedNum.text = cost[1][2]
	self.labelRes32NeedNum.text = cost[2][2]

	xyd.setUISpriteAsync(self.iconRes31, nil, xyd.tables.itemTable:getIcon(cost[1][1]))
	xyd.setUISpriteAsync(self.iconRes32, nil, xyd.tables.itemTable:getIcon(cost[2][1]))

	if self.equip:getLevel() < self.equip:getMaxLevel() then
		xyd.applyChildrenGrey(self.btnExchange.gameObject)
	else
		xyd.applyChildrenOrigin(self.btnExchange.gameObject)
	end
end

function SoulEquip2StrengthenWindow:onClickTab()
	self.content1:SetActive(self.curTabIndex == 1)
	self.content2:SetActive(self.curTabIndex == 2)
	self.content3:SetActive(self.curTabIndex == 3)

	local items = nil

	self:updateTopGroup()

	if self.curTabIndex == 1 then
		items = {
			{
				id = 1
			},
			{
				id = 426
			}
		}

		self:updateContent1()
	elseif self.curTabIndex == 2 then
		items = {
			{
				id = 1
			},
			{
				id = 419
			}
		}

		self:updateContent2()
	elseif self.curTabIndex == 3 then
		items = {
			{
				id = 1
			},
			{
				id = 420
			}
		}

		self:updateContent3()
	end

	self.winTop:setItem(items)
	self.winTop:hideBg()
end

function SoulEquip2StrengthenWindow:onClickSortBtn()
	local sequence2 = self:getSequence()
	local sortPopTrans = self.sortPop.transform
	local p = self.sortPop:GetComponent(typeof(UIPanel))
	local sortPopY = -532

	local function getter()
		return Color.New(1, 1, 1, p.alpha)
	end

	local function setter(color)
		p.alpha = color.a
	end

	if self.sortPop.activeSelf == true then
		self.arrow.transform:SetLocalScale(1, 1, 1)
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY + 17, 0.067))
		sequence2:Insert(0.067, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0.1))
		sequence2:Insert(0.067, sortPopTrans:DOLocalMoveY(sortPopY - 58, 0.1))
		sequence2:Insert(0.167, sortPopTrans:DOLocalMoveY(sortPopY, 0))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil

			self.sortPop:SetActive(false)
		end)
	else
		self.sortPop:SetActive(true)
		self.arrow.transform:SetLocalScale(1, -1, 1)
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY - 58, 0))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0))
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY + 17, 0.1))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.1))
		sequence2:Insert(0.1, sortPopTrans:DOLocalMoveY(sortPopY, 0.2))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil
		end)
	end
end

function SoulEquip2StrengthenWindow:changefilterAttrs(filterAttrs)
	self.filterAttrs = filterAttrs

	self:updateContent1()
end

function SoulEquip2StrengthenWindow:changeFilterSuit(filterSuit)
	self.filterSuit = filterSuit or 0

	self:updateContent1()
end

function SoulEquip2StrengthenWindow:onClickFilterBtn()
	local sequence2 = self:getSequence()
	local filterPopTrans = self.filterPop.transform
	local p = self.filterPop:GetComponent(typeof(UIPanel))
	local filterPopY = -525

	local function getter()
		return Color.New(1, 1, 1, p.alpha)
	end

	local function setter(color)
		p.alpha = color.a
	end

	if self.filterPop.activeSelf == true then
		self.arrowfilter.transform:SetLocalScale(1, 1, 1)
		sequence2:Insert(0, filterPopTrans:DOLocalMoveY(filterPopY + 17, 0.067))
		sequence2:Insert(0.067, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0.1))
		sequence2:Insert(0.067, filterPopTrans:DOLocalMoveY(filterPopY - 58, 0.1))
		sequence2:Insert(0.167, filterPopTrans:DOLocalMoveY(filterPopY, 0))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil

			self.filterPop:SetActive(false)
		end)
	else
		self.filterPop:SetActive(true)
		self.arrowfilter.transform:SetLocalScale(1, -1, 1)
		sequence2:Insert(0, filterPopTrans:DOLocalMoveY(filterPopY - 58, 0))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0))
		sequence2:Insert(0, filterPopTrans:DOLocalMoveY(filterPopY + 17, 0.1))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.1))
		sequence2:Insert(0.1, filterPopTrans:DOLocalMoveY(filterPopY, 0.2))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil
		end)
	end
end

function SoulEquip2StrengthenWindow:onClickBtnReset()
	if self.equip:getAwake() <= 0 then
		xyd.alertTips(__("SOUL_EQUIP_TEXT84"))

		return
	end

	local resetCost = xyd.tables.miscTable:split2Cost("star_origin_reset_cost", "value", "#")

	xyd.alertConfirm(__("SOUL_EQUIP_TEXT72"), function ()
		local selfNum = xyd.models.backpack:getItemNumByID(resetCost[1])

		if selfNum < resetCost[2] then
			xyd.alertTips(__("NOT_ENOUGH_CRYSTAL"))
		else
			xyd.models.slot:reqSoulEquipResetAwake2(self.equipID, function ()
				self:updateTopGroup()
				self:updateContent2()
			end)
		end
	end, __("SURE"), false, resetCost, __("GUILD_RESET"))
end

function SoulEquip2StrengthenWindow:updatePosFilter()
	for i = 1, 4 do
		if i == self.filterIndex - 1 then
			xyd.setUISpriteAsync(self["btnFilterPos" .. i]:ComponentByName("", typeof(UISprite)), nil, "emotion_choose_btn")

			self["labelFilterPos" .. i].color = Color.New2(4278124287.0)
			self["labelFilterPos" .. i].effectColor = Color.New2(960513791)
		else
			xyd.setUISpriteAsync(self["btnFilterPos" .. i]:ComponentByName("", typeof(UISprite)), nil, "emotion_unchoose_btn")

			self["labelFilterPos" .. i].color = Color.New2(960513791)
			self["labelFilterPos" .. i].effectColor = Color.New2(4278124287.0)
		end
	end
end

function SoulEquip2StrengthenWindow:autoSelect(onlyMaterial, starArr, TargetLevel)
	local data = {}
	self.chooseMaterailEquipHelpArr = {}
	self.chooseMateraiItemNum = 0
	local lev = self.equip:getLevel()
	local maxLev = TargetLevel
	local fakeExp = self.equip:getCurExp()
	local fakeLev = lev
	local targetExp = fakeExp

	for i = 1, 99999 do
		if fakeLev < maxLev then
			targetExp = targetExp + xyd.tables.expSoulEquip2Table:getCost(fakeLev + 1)
			fakeLev = fakeLev + 1
		else
			break
		end
	end

	local itemMaterial = xyd.tables.miscTable:split2Cost("soul_equip2_sp_item", "value", "#")
	local itemID = itemMaterial[1]
	local itemSoulEquipSingleExp = itemMaterial[3]
	local curItemNum = xyd.models.backpack:getItemNumByID(itemID)
	local needNum = math.ceil((targetExp - fakeExp) / itemSoulEquipSingleExp)
	self.chooseMateraiItemNum = math.min(curItemNum, needNum)

	if needNum <= curItemNum then
		self:updateContent1()

		return
	end

	fakeExp = fakeExp + self.chooseMateraiItemNum * itemSoulEquipSingleExp

	if not onlyMaterial then
		local equips = xyd.models.slot:getSoulEquip2s()

		for id, equip in pairs(equips) do
			local pos = equip:getPos()

			if self.filterIndex == 0 or pos == self.filterIndex then
				local flag = true

				if self.filterSuit > 0 and self.filterSuit ~= xyd.tables.soulEquip2Table:getGroup(equip:getTableID()) then
					flag = false
				end

				if #self.filterAttrs > 0 and not equip:containAttr(self.filterAttrs) then
					flag = false
				end

				if flag then
					table.insert(data, {
						equip = equip
					})
				end
			end
		end

		local function sortFunc(a, b)
			local aLevel = a.equip:getLevel()
			local bLevel = b.equip:getLevel()
			local aStar = a.equip:getStar()
			local bStar = b.equip:getStar()
			local aQlt = a.equip:getQlt()
			local bQlt = b.equip:getQlt()

			if aLevel ~= bLevel then
				return aLevel < bLevel
			elseif aStar ~= bStar then
				return aStar < bStar
			elseif aQlt ~= bQlt then
				return aQlt < bQlt
			else
				return a.equip:getSoulEquipID() < b.equip:getSoulEquipID()
			end
		end

		table.sort(data, sortFunc)

		for k, v in pairs(data) do
			if targetExp <= fakeExp then
				self:updateContent1()

				return
			end

			local equip = v.equip
			local exp = xyd.tables.soulEquip2Table:getExp(equip:getTableID())
			fakeExp = fakeExp + exp
			self.chooseMaterailEquipHelpArr[equip:getSoulEquipID()] = true
		end
	end

	if #data == 0 and self.chooseMateraiItemNum == 0 then
		xyd.alertTips(__("SOUL_EQUIP_TEXT34"))
	end
end

function SoulEquip2StrengthenWindow:dispose()
	SoulEquip2StrengthenWindow.super.dispose(self)

	local wnd = xyd.getWindow("soul_equip_info_window")

	if wnd then
		wnd:onClickTab()
	end
end

function SoulEquip2StrengthenItem:ctor(go, parent)
	SoulEquip2StrengthenItem.super.ctor(self, go, parent)

	self.parent = parent
end

function SoulEquip2StrengthenItem:initUI()
	self.iconPos = self.go:NodeByName("iconPos").gameObject
end

function SoulEquip2StrengthenItem:update(wrapIndex, index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info

	self:updateInfo(wrapIndex, index)
end

function SoulEquip2StrengthenItem:updateInfo(wrapIndex, index)
	local params = nil

	if self.data.itemID then
		params = {
			scale = 0.9166666666666666,
			uiRoot = self.iconPos,
			itemID = self.data.itemID,
			num = xyd.models.backpack:getItemNumByID(self.data.itemID),
			callback = function ()
				self:onClickIcon()
			end,
			dragScrollView = self.parent.equip2ScrollView
		}
	else
		self.equip = self.data.equip
		params = {
			scale = 0.9166666666666666,
			uiRoot = self.iconPos,
			itemID = self.equip:getTableID(),
			soulEquipInfo = self.equip:getSoulEquipInfo(),
			partner_id = self.equip:getOwnerPartnerID(),
			callback = function ()
				self:onClickIcon()
			end,
			dragScrollView = self.parent.equip2ScrollView
		}
	end

	if self.icon then
		self.icon:setInfo(params)
		self.icon:SetActive(true)
	else
		self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	end

	self:checkChoose()
end

function SoulEquip2StrengthenItem:onClickIcon()
	if self.data.itemID then
		local itemMaterial = xyd.tables.miscTable:split2Cost("soul_equip2_sp_item", "value", "#")
		local itemID = itemMaterial[1]
		local itemSoulEquipSingleExp = itemMaterial[3]
		local curNumInit = self.parent.chooseMateraiItemNum
		local curItemNum = xyd.models.backpack:getItemNumByID(itemID)
		local targetExp = xyd.tables.expSoulEquip2Table:getAllExp(self.parent.equip:getMaxLevel())
		local fakeExp = self.parent.fakeExp

		if self.parent.fakeLev > 0 then
			fakeExp = fakeExp + xyd.tables.expSoulEquip2Table:getAllExp(self.parent.fakeLev)
		end

		local needNum = nil
		needNum = math.ceil((targetExp - fakeExp) / itemSoulEquipSingleExp) + curNumInit
		local max_num = math.min(curItemNum, needNum)
		local params = {
			itemNum = 1,
			minNum = 0,
			itemID = self.data.itemID,
			callback = function (num)
				self.parent.chooseMateraiItemNum = num

				self:checkChoose()
				self.parent:updateContent1(true)
			end,
			maxLimitNum = max_num,
			curNumInit = curNumInit,
			tipsLabelText = __("沒配"),
			maxLimitTips = __("SOUL_EQUIP_TEXT92")
		}

		xyd.WindowManager.get():openWindow("artifact_offer_window", params)
	elseif self.equip:getIsLock() or self.equip:getSoulEquipID() == self.parent.equip:getSoulEquipID() then
		self:openItemTips(true)

		return
	elseif self.parent.chooseMaterailEquipHelpArr[self.equip:getSoulEquipID()] then
		self.parent.chooseMaterailEquipHelpArr[self.equip:getSoulEquipID()] = nil

		self.parent:updateContent1(true)
		self:openItemTips(false)
	else
		if self.parent.equip:getMaxLevel() <= self.parent.fakeLev then
			xyd.alertTips(__("SOUL_EQUIP_TEXT92"))

			return
		end

		if self.equip:getOwnerPartnerID() and self.equip:getOwnerPartnerID() > 0 then
			self:openItemTips(true)

			local owner = xyd.models.slot:getPartner(self.equip:getOwnerPartnerID())

			if owner then
				xyd.alertYesNo(__("ACTIVITY_ANTIQUE_LEVELUP_TEXT16"), function (flag)
					if flag == true then
						owner:takeOffSoulEquip(self.equip:getSoulEquipID(), function ()
							self.parent.chooseMaterailEquipHelpArr[self.equip:getSoulEquipID()] = true

							self:checkChoose()
							self.parent:updateContent1(true)
						end)
					else
						return
					end
				end, __("YES"), false, nil, , , , , )
			else
				self.parent.chooseMaterailEquipHelpArr[self.equip:getSoulEquipID()] = true

				self.parent:updateContent1(true)
			end
		else
			self:openItemTips(true)

			self.parent.chooseMaterailEquipHelpArr[self.equip:getSoulEquipID()] = true

			self.parent:updateContent1(true)
		end
	end

	self:checkChoose()
end

function SoulEquip2StrengthenItem:checkChoose()
	if self.data.itemID then
		if self.parent.chooseMateraiItemNum > 0 then
			self.icon:setLock(false)
			self.icon:setChoose(true)
		else
			self.icon:setLock(false)
			self.icon:setChoose(false)
		end
	elseif self.parent.chooseMaterailEquipHelpArr[self.equip:getSoulEquipID()] then
		self.icon:setLock(false)
		self.icon:setChoose(true)
	elseif self.equip:getIsLock() then
		self.icon:setChoose(false)
		self.icon:setLock(true)
	else
		self.icon:setLock(false)
		self.icon:setChoose(false)
	end
end

function SoulEquip2StrengthenItem:openItemTips(show)
	if self.equip then
		local params = {
			btnLayout = 0,
			noShowSoulEquipSuit = true,
			choose_equip = true,
			itemID = self.equip:getTableID(),
			soulEquipInfo = self.equip:getSoulEquipInfo(),
			lockClickCallBack = function ()
				local lockFlag = self.equip:getIsLock()
				local lock = 1

				if lockFlag then
					lock = 0
				end

				xyd.models.slot:reqLockSoulEquip(self.equip:getSoulEquipID(), lock, function ()
					self.equip:setLock(lock)

					local win = xyd.getWindow("item_tips_window")

					if self.parent.tips then
						self.parent.tips:setBtnLockState(self.equip:getIsLock())
					end

					if not lockFlag then
						self.parent.chooseMaterailEquipHelpArr[self.equip:getSoulEquipID()] = nil
					end

					self.parent:updateContent1(true)
					self:checkChoose()
				end)
			end,
			lockStateCallBack = function ()
				return self.equip:getIsLock()
			end
		}

		if self.equip:getOwnerPartnerID() and self.equip:getOwnerPartnerID() > 0 then
			local owner = xyd.models.slot:getPartner(self.equip:getOwnerPartnerID())

			if owner then
				params.equipedOn = owner
				params.equipedPartner = owner
			end
		end

		self.parent:updateItemTipsGroup(show, params)
	end
end

return SoulEquip2StrengthenWindow
