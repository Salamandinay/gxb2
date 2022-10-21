local BaseWindow = import(".BaseWindow")
local SoulEquipInfoWindow = class("SoulEquipInfoWindow", BaseWindow)
local slot = xyd.models.slot
local CommonTabBar = import("app.common.ui.CommonTabBar")
local AttrLabel = import("app.components.AttrLabel")

function SoulEquipInfoWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.partner = params.partner
	self.combinationEditMode = false
	self.curTabIndex = 1
	self.curSelectEquipPos = 1
	self.curSelectCombinationID = nil
	self.groupAllAttrLables = {}
	self.icons = {}
	self.curCombinationModeData = {}
	self.indexArr = {}
	self.indexHelpArr = {}
	local ids = xyd.tables.soulEquip2BaseBuffTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local buff = xyd.tables.soulEquip2BaseBuffTable:getBuff(id)

		if not self.indexHelpArr[buff] then
			self.indexHelpArr[buff] = 1

			table.insert(self.indexArr, buff)
		end
	end

	ids = xyd.tables.soulEquip2ExBuffTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local buff = xyd.tables.soulEquip2ExBuffTable:getBuff(id)

		if not self.indexHelpArr[buff] then
			self.indexHelpArr[buff] = 1

			table.insert(self.indexArr, buff)
		end
	end
end

function SoulEquipInfoWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function SoulEquipInfoWindow:getUIComponent()
	self.groupAction = self.window_.transform:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelWindowTitle = self.groupAction:ComponentByName("labelWindowTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
	self.topGoup = self.groupAction:NodeByName("topGoup").gameObject
	self.btnDrop = self.topGoup:NodeByName("btnDrop").gameObject
	self.labeDrop = self.btnDrop:ComponentByName("labeDrop", typeof(UILabel))
	self.equip1Group = self.topGoup:NodeByName("equip1Group").gameObject
	self.iconPos1 = self.equip1Group:NodeByName("iconPos").gameObject
	self.equipBg1 = self.iconPos1:ComponentByName("bg", typeof(UISprite))
	self.equipImgChoose1 = self.iconPos1:ComponentByName("imgChoose", typeof(UISprite))
	self.equipimgPlus1 = self.iconPos1:ComponentByName("imgPlus", typeof(UISprite))
	self.equiplabelLevel1 = self.iconPos1:ComponentByName("labelLevel", typeof(UILabel))
	self.equip2Group = self.topGoup:NodeByName("equip2Group").gameObject

	for i = 1, 4 do
		self["iconPos" .. i + 1] = self.equip2Group:NodeByName("iconPos" .. i).gameObject
		self["equipBg" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("bg", typeof(UISprite))
		self["equipImgChoose" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgChoose", typeof(UISprite))
		self["equipimgPlus" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgPlus", typeof(UISprite))
		self["equiplabelLevel" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("labelLevel", typeof(UILabel))
		self["imgIcon" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgIcon", typeof(UISprite))
		self["imgQlt" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgQlt", typeof(UISprite))
		self["imgbg" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgbg", typeof(UISprite))
		self["imgStar" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgStar", typeof(UISprite))
	end

	self.bgHuaWen = self.topGoup:ComponentByName("bg2", typeof(UISprite))
	self.btnCombinationAttr = self.topGoup:NodeByName("btnCombinationAttr").gameObject
	self.btnSaveCombination = self.topGoup:NodeByName("btnSaveCombination").gameObject
	self.labelSaveCombination = self.btnSaveCombination:ComponentByName("label", typeof(UILabel))
	self.btnEditCombination = self.topGoup:NodeByName("btnEditCombination").gameObject
	self.labelEditCombination = self.btnEditCombination:ComponentByName("label", typeof(UILabel))
	self.btnCancelCombination = self.topGoup:NodeByName("btnCancelCombination").gameObject
	self.labelCancelCombination = self.btnCancelCombination:ComponentByName("label", typeof(UILabel))
	self.labelCombinationName = self.topGoup:ComponentByName("labelCombinationName", typeof(UILabel))
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.content1 = self.bottomGroup:NodeByName("content1").gameObject
	self.content2_1 = self.bottomGroup:NodeByName("content2_1").gameObject
	self.content2_2 = self.bottomGroup:NodeByName("content2_2").gameObject
	self.content3 = self.bottomGroup:NodeByName("content3").gameObject
	self.bg2 = self.content1:ComponentByName("bg2", typeof(UISprite))
	self.labelCombinationMode = self.bottomGroup:ComponentByName("labelCombinationMode", typeof(UILabel))
	self.combinationAttrGroup = self.topGoup:NodeByName("combinationAttrGroup").gameObject
	self.groupAllAttrShow = self.combinationAttrGroup:NodeByName("groupAllAttrShow").gameObject
	self.groupAllAttr = self.groupAllAttrShow:NodeByName("groupAllAttr").gameObject
	self.groupAllAttrTable = self.groupAllAttr:ComponentByName("", typeof(UITable))
	self.descScroller = self.combinationAttrGroup:NodeByName("descScroller").gameObject
	self.descScrollView = self.combinationAttrGroup:ComponentByName("descScroller", typeof(UIScrollView))
	self.labelSkillDesc = self.descScroller:ComponentByName("labelSkillDesc", typeof(UILabel))
	self.nav = self.bottomGroup:NodeByName("nav").gameObject

	for i = 1, 3 do
		self["tab" .. i] = self.nav:NodeByName("tab_" .. i).gameObject
		self["labelTab" .. i] = self["tab" .. i]:ComponentByName("label", typeof(UILabel))
	end
end

function SoulEquipInfoWindow:register()
	self.eventProxy_:addEventListener(xyd.event.GUILD_NEW_WAR_FIGHT, handler(self, self.onGetData))

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "SOUL_EQUIP_HELP"
		})
	end

	UIEventListener.Get(self.btnCombinationAttr).onClick = function ()
		self:onClickBtnCombinationAttr()
	end

	UIEventListener.Get(self.btnCancelCombination).onClick = function ()
		self:quitEditombinationMode()
	end

	UIEventListener.Get(self.btnEditCombination).onClick = function ()
		local data = xyd.models.slot:getSoulEquipCombination(self.curSelectCombinationID)

		if not data then
			return
		end

		local equips = {}

		for i = 1, 5 do
			if data.equipIDs[i] then
				equips[i] = xyd.models.slot:getSoulEquip(data.equipIDs[i])
			end
		end

		self:enterEditombinationMode({
			equips = equips,
			name = data.name,
			pos = self.curSelectCombinationID
		})
	end

	UIEventListener.Get(self.btnSaveCombination).onClick = function ()
		if self.combinationEditMode then
			xyd.openWindow("soul_equip_new_suit_window", {
				equips = self.curCombinationModeData.equips,
				oldName = self.curCombinationModeData.name or "",
				pos = self.curCombinationModeData.pos,
				callback = function ()
					if self.combinationEditMode then
						self:quitEditombinationMode()
					else
						self:updateTopGroup()
						self.content3Con:update()
					end
				end
			})
		elseif xyd.models.slot:getSoulEquipCombinationLimitNum() <= xyd.models.slot:getSoulEquipCombinationNum() then
			xyd.alertTips(__("没配，超限"))
		else
			local list = xyd.models.slot:getAllSoulEquipCombination()

			for i = 1, xyd.models.slot:getSoulEquipCombinationLimitNum() do
				if not list[i] then
					xyd.openWindow("soul_equip_new_suit_window", {
						oldName = "",
						equips = self.equips,
						pos = i,
						callback = function ()
							self:updateTopGroup()
							self.content3Con:update()
						end
					})

					return
				end
			end
		end
	end

	for i = 1, 5 do
		UIEventListener.Get(self["iconPos" .. i]).onClick = function ()
			if self.curTabIndex == 2 then
				self.curSelectEquipPos = i

				if self.content2_2Con then
					self.content2_2Con:changeFilterPos(i)
				end

				self:updateTopGroup()
				self:updateContent2()
				self:checkOpenItemTips(i)
			elseif self.curTabIndex == 1 then
				self.curSelectEquipPos = i

				if self.content2_2Con then
					self.content2_2Con:changeFilterPos(i)
				end

				self.tabs:setTabActive(2, true)
				self:checkOpenItemTips(i)
			elseif self.combinationEditMode then
				self.curSelectEquipPos = i

				if self.content2_2Con then
					self.content2_2Con:changeFilterPos(i)
				end

				self.content3:SetActive(false)
				self:updateTopGroup()
				self:updateContent2()
				self:checkOpenItemTips(i)
			elseif self.curSelectCombinationID then
				self:checkOpenItemTips(i)
			end
		end
	end

	UIEventListener.Get(self.btnDrop).onClick = function ()
		self.partner:takeOnSoulEquips({}, function ()
			self:initData()
			self:updateTopGroup()

			if self.curTabIndex == 1 then
				self:updateContent1()
			elseif self.curTabIndex == 2 then
				self:updateContent2()
			elseif self.curTabIndex == 3 then
				self:updateContent3()
			end
		end)
	end
end

function SoulEquipInfoWindow:initData()
	if not self.combinationEditMode then
		self.equips = {}
		local equipIDs = self.partner:getSoulEquips()

		for i = 1, 5 do
			if equipIDs[i] and equipIDs[i] > 0 then
				self.equips[i] = slot:getSoulEquip(equipIDs[i])
			end
		end
	end
end

function SoulEquipInfoWindow:layout()
	self.labelWindowTitle.text = __("SOUL_EQUIP_TEXT01")
	self.labelSaveCombination.text = __("SOUL_EQUIP_TEXT25")
	self.labelEditCombination.text = __("SOUL_EQUIP_TEXT26")
	self.labelCancelCombination.text = __("SOUL_EQUIP_TEXT22")
	self.labeDrop.text = __("SOUL_EQUIP_TEXT06")
	self.labelTab1.text = __("SOUL_EQUIP_TEXT02")
	self.labelTab2.text = __("SOUL_EQUIP_TEXT03")
	self.labelTab3.text = __("SOUL_EQUIP_TEXT04")
	self.labelCombinationMode.text = __("SOUL_EQUIP_TEXT26")

	self:initData()

	self.tabs = CommonTabBar.new(self.nav, 3, function (index)
		if self.curTabIndex ~= index then
			if self.index == 2 then
				self.curSelectEquipPos = 1
			end

			self.curTabIndex = index

			self:onClickTab()
		end
	end)

	self:onClickTab()
end

function SoulEquipInfoWindow:updateTopGroup()
	local equips = nil

	if self.combinationEditMode then
		self.labelCombinationMode:SetActive(true)
		self.btnSaveCombination:SetActive(true)
		self.btnCancelCombination:SetActive(true)
		self.labelCombinationName:SetActive(true)
		self.btnSaveCombination:X(100)
		self.btnCancelCombination:X(-100)
		self.btnEditCombination:SetActive(false)

		self.labelCombinationName.text = self.curCombinationModeData.name
		equips = self.curCombinationModeData.equips

		for i = 1, 5 do
			if equips[i] then
				local id = equips[i]:getSoulEquipID()

				if not xyd.models.slot:getSoulEquip(id) then
					equips[i] = nil
				end
			end
		end
	elseif self.curSelectCombinationID then
		self.labelCombinationMode:SetActive(false)
		self.btnSaveCombination:SetActive(false)
		self.btnCancelCombination:SetActive(false)
		self.btnEditCombination:SetActive(true)
		self.labelCombinationName:SetActive(true)

		equips = {}
		local data = xyd.models.slot:getSoulEquipCombination(self.curSelectCombinationID)
		self.labelCombinationName.text = data.name
		local ids = data.equipIDs

		for i = 1, 5 do
			if ids[i] and ids[i] > 0 then
				equips[i] = xyd.models.slot:getSoulEquip(ids[i])
			end
		end
	else
		self.labelCombinationMode:SetActive(false)
		self.btnSaveCombination:X(0)
		self.btnSaveCombination:SetActive(self.curTabIndex == 3)
		self.btnCancelCombination:SetActive(false)
		self.btnEditCombination:SetActive(false)

		equips = self.equips

		self.labelCombinationName:SetActive(self.curTabIndex == 3)

		self.labelCombinationName.text = __("SOUL_EQUIP_TEXT24")
	end

	for i = 1, 1 do
		if not equips[i] then
			if self.icons[i] then
				self.icons[i]:SetActive(false)
			end
		else
			local params = {
				noClick = true,
				uiRoot = self["iconPos" .. i],
				itemID = equips[i]:getTableID(),
				callback = function ()
				end,
				soulEquipInfo = equips[i]:getSoulEquipInfo()
			}

			if i == 1 then
				params.scale = 1
			else
				params.scale = 1.4054054054054055
			end

			if self.icons[i] then
				self.icons[i]:setInfo(params)
				self.icons[i]:SetActive(true)
			else
				self.icons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			end
		end

		self["equipImgChoose" .. i]:SetActive(i == self.curSelectEquipPos)
	end

	for i = 2, 5 do
		if not equips[i] then
			self["imgIcon" .. i]:SetActive(false)
			self["imgQlt" .. i]:SetActive(false)
			self["imgbg" .. i]:SetActive(false)
			self["imgStar" .. i]:SetActive(false)
			self["equiplabelLevel" .. i]:SetActive(false)
			self["equipBg" .. i]:SetActive(true)
		else
			self["imgIcon" .. i]:SetActive(true)
			self["imgQlt" .. i]:SetActive(true)
			self["imgbg" .. i]:SetActive(true)
			self["imgStar" .. i]:SetActive(true)
			self["equiplabelLevel" .. i]:SetActive(true)
			self["equipBg" .. i]:SetActive(false)

			self["equiplabelLevel" .. i].text = "+" .. equips[i]:getLevel()

			xyd.setUISpriteAsync(self["imgIcon" .. i], nil, xyd.tables.itemTable:getIcon(equips[i]:getTableID()))
			xyd.setUISpriteAsync(self["imgQlt" .. i], nil, "soul_equip_kuang_small_" .. equips[i]:getQlt())
			xyd.setUISpriteAsync(self["imgStar" .. i], nil, "pub_star_require" .. equips[i]:getStar())
		end

		self["equipImgChoose" .. i]:SetActive(i == self.curSelectEquipPos)
	end

	self:updateCombinationAttr()
end

function SoulEquipInfoWindow:updateContent1()
	if not self.content1Con then
		self.content1Con = import("app.components.SoulEquipInfoContent1Con").new(self.content1.gameObject, self)
	else
		self.content1Con:updateAllAttr()
	end
end

function SoulEquipInfoWindow:updateContent2()
	if self.curSelectEquipPos and self.curSelectEquipPos > 1 then
		self.content2_1:SetActive(false)
		self.content2_2:SetActive(true)

		if not self.content2_2Con then
			self.content2_2Con = import("app.components.SoulEquipInfoContent22Con").new(self.content2_2.gameObject, self)
		else
			self.content2_2Con:update()
		end
	else
		self.content2_1:SetActive(true)
		self.content2_2:SetActive(false)

		if not self.content2_1Con then
			self.content2_1Con = import("app.components.SoulEquipInfoContent21Con").new(self.content2_1.gameObject, self)
		else
			self.content2_1Con:update()
		end
	end
end

function SoulEquipInfoWindow:updateContent3()
	if not self.content3Con then
		self.content3Con = import("app.components.SoulEquipInfoContent3Con").new(self.content3.gameObject, self)
	else
		self.content3Con:update()
	end
end

function SoulEquipInfoWindow:onClickTab()
	self.curSelectCombinationID = nil

	self.btnCombinationAttr:SetActive(self.curTabIndex == 3)
	self.content1:SetActive(self.curTabIndex == 1)
	self.content2_1:SetActive(self.curTabIndex == 2)
	self.content2_2:SetActive(self.curTabIndex == 2)
	self.content3:SetActive(self.curTabIndex == 3)
	self.btnDrop:SetActive(self.curTabIndex ~= 3)
	self.btnSaveCombination:SetActive(self.curTabIndex == 3)

	self.showingCombinationAttr = false

	self.combinationAttrGroup:SetActive(false)
	self:updateTopGroup()

	if self.curTabIndex == 1 then
		self:updateContent1()
	elseif self.curTabIndex == 2 then
		self:updateContent2()
	elseif self.curTabIndex == 3 then
		self:updateContent3()
	end
end

function SoulEquipInfoWindow:enterEditombinationMode(data)
	self.combinationEditMode = true

	self.nav:SetActive(false)
	self.labelCombinationMode:SetActive(true)
	self.btnSaveCombination:SetActive(true)
	self.btnCancelCombination:SetActive(true)
	self.content1:SetActive(false)
	self.content2_1:SetActive(true)
	self.content2_2:SetActive(true)
	self.content3:SetActive(false)

	self.curCombinationModeData = data

	self:updateTopGroup()
	self:updateContent2()
end

function SoulEquipInfoWindow:quitEditombinationMode(data)
	self.combinationEditMode = false

	self.nav:SetActive(true)
	self.labelCombinationMode:SetActive(false)
	self.btnSaveCombination:SetActive(false)
	self.btnCancelCombination:SetActive(false)
	self.content1:SetActive(false)
	self.content2_1:SetActive(false)
	self.content2_2:SetActive(false)
	self.content3:SetActive(true)
	self:updateTopGroup()

	self.curCombinationModeData = {}

	self:updateContent3()
end

function SoulEquipInfoWindow:chooseCombination(combinationID)
	self.curSelectCombinationID = combinationID

	if combinationID then
		local combination = xyd.models.slot:getSoulEquipCombination(combinationID)
		self.labelCombinationName.text = combination.name

		self.btnSaveCombination:SetActive(false)
		self.btnEditCombination:SetActive(true)
	else
		self.labelCombinationName.text = __("SOUL_EQUIP_TEXT24")

		self.btnSaveCombination:SetActive(true)
		self.btnEditCombination:SetActive(false)
	end

	self:updateTopGroup()
end

function SoulEquipInfoWindow:onClickBtnCombinationAttr()
	if self.showingCombinationAttr then
		self.showingCombinationAttr = false

		self.combinationAttrGroup:SetActive(false)
	else
		self.showingCombinationAttr = true

		self.combinationAttrGroup:SetActive(true)
	end

	self:updateCombinationAttr()
end

function SoulEquipInfoWindow:updateCombinationAttr()
	if self.showingCombinationAttr then
		local equipIDs = nil

		if self.combinationEditMode then
			equipIDs = {}

			for i = 1, 5 do
				if self.curCombinationModeData.equips[i] then
					equipIDs[i] = self.curCombinationModeData.equips[i]:getSoulEquipID()
				end
			end
		elseif self.curSelectCombinationID then
			equipIDs = {}
			local data = xyd.models.slot:getSoulEquipCombination(self.curSelectCombinationID)
			self.labelCombinationName.text = data.name
			local ids = data.equipIDs

			for i = 1, 5 do
				if ids[i] and ids[i] > 0 then
					equipIDs[i] = ids[i]
				end
			end
		else
			equipIDs = self.partner:getSoulEquips()
		end

		local attrs = xyd.culSoulEquipAttr(equipIDs)
		local attrsHelpArr = {}

		for _, buff in pairs(attrs) do
			attrsHelpArr[buff[1]] = buff[2]
		end

		local i = 1

		for i = 1, #xyd.SoulEquipShowAttr do
			local key = xyd.SoulEquipShowAttr[i]
			local value = attrsHelpArr[key] or 0
			local params = {
				xyd.tables.dBuffTable:getDesc(key),
				xyd.getBuffValue(key, value)
			}

			if xyd.Global.lang == "fr_fr" and (key == "unCrit" or key == "unfree") then
				params[1] = __(string.upper(key))
			end

			local label = self.groupAllAttrLables[i]

			if label == nil then
				label = AttrLabel.new(self.groupAllAttr, "soulEquip1Show", params)
				self.groupAllAttrLables[i] = label
			else
				label:setValue(params)
			end

			if xyd.Global.lang == "de_de" then
				label.labelName.fontSize = 15
			end
		end

		self.groupAllAttrTable:Reposition()

		local curSkillID = xyd.getSoulEquipSkill(equipIDs)

		if curSkillID then
			self.labelSkillDesc.text = xyd.tables.skillTextTable:getDesc(curSkillID)
		else
			self.labelSkillDesc.text = ""
		end
	end
end

function SoulEquipInfoWindow:changefilterAttrs(filterAttr)
	if self.content2_2Con then
		self.content2_2Con:changefilterAttrs(filterAttr)
	end
end

function SoulEquipInfoWindow:changeFilterSuit(filterSuit)
	if self.content2_2Con then
		self.content2_2Con:changeFilterSuit(filterSuit)
	end
end

function SoulEquipInfoWindow:onGetData(event)
	local data = xyd.decodeProtoBuf(event.data)
end

function SoulEquipInfoWindow:checkOpenItemTips(pos)
	local equips = nil

	if self.combinationEditMode then
		equips = self.curCombinationModeData.equips
	elseif self.curSelectCombinationID then
		equips = {}
		local data = xyd.models.slot:getSoulEquipCombination(self.curSelectCombinationID)
		self.labelCombinationName.text = data.name
		local ids = data.equipIDs

		for i = 1, 5 do
			if ids[i] and ids[i] > 0 then
				equips[i] = xyd.models.slot:getSoulEquip(ids[i])
			end
		end
	else
		equips = self.equips
	end

	local equip = equips[pos]

	if equip then
		local partnerID = equip:getOwnerPartnerID()
		local partner = nil

		if partnerID and partnerID > 0 then
			partner = xyd.models.slot:getPartner(partnerID)
		end

		local params = {
			btnLayout = 1,
			itemID = equip:getTableID(),
			midColor = xyd.ButtonBgColorType.red_btn_65_65,
			midLabel = __("REMOVE"),
			midCallback = function ()
				if self.combinationEditMode then
					self.curCombinationModeData.equips[pos] = nil

					self:updateTopGroup()
					self:updateContent2()
				elseif partner then
					partner:takeOffSoulEquip(equip:getSoulEquipID(), function ()
						self:initData()
						self:updateTopGroup()

						if self.curTabIndex == 1 then
							self:updateContent1()
						elseif self.curTabIndex == 2 then
							self:updateContent2()
						elseif self.curTabIndex == 3 then
							self:updateContent3()
						end
					end)
				end

				xyd.WindowManager:get():closeWindow("item_tips_window")
			end,
			upArrowCallback = function ()
				local itemType = xyd.tables.itemTable:getType(equip:getTableID())

				if itemType == xyd.ItemType.SOUL_EQUIP1 then
					xyd.openWindow("soul_equip1_strengthen_window", {
						equipID = equip:getSoulEquipID()
					})
				else
					xyd.openWindow("soul_equip2_strengthen_window", {
						equipID = equip:getSoulEquipID()
					})
				end

				xyd.WindowManager:get():closeWindow("item_tips_window")
			end,
			soulEquipInfo = equip:getSoulEquipInfo(),
			lockClickCallBack = function ()
				local lockFlag = equip:getIsLock()
				local lock = 1

				if lockFlag then
					lock = 0
				end

				xyd.models.slot:reqLockSoulEquip(equip:getSoulEquipID(), lock, function ()
					equip:setLock(lock)

					local win = xyd.getWindow("item_tips_window")

					if win and win.itemTips_ then
						win.itemTips_:setBtnLockState(equip:getIsLock())
					end
				end)
			end,
			lockStateCallBack = function ()
				return equip:getIsLock()
			end
		}

		if partnerID and partnerID > 0 then
			params.equipedOn = partner
		end

		if not self.combinationEditMode and self.curSelectCombinationID then
			params.upArrowCallback = nil
			params.lockStateCallBack = nil
			params.lockClickCallBack = nil
			params.midColor = nil
			params.midCallback = nil
			params.midLabel = nil
			params.btnLayout = 0
		end

		local itemTipsWindow = xyd.WindowManager.get():getWindow("item_tips_window")

		if itemTipsWindow == nil then
			xyd.WindowManager.get():openWindow("item_tips_window", params)
		else
			itemTipsWindow:addTips(params)
		end
	end
end

function SoulEquipInfoWindow:dispose()
	SoulEquipInfoWindow.super.dispose(self)

	local wnd = xyd.getWindow("partner_detail_window")

	if wnd then
		wnd:updateAttr()
	end
end

return SoulEquipInfoWindow
