local ExploreTrainingRoomWindow = class("ExploreTrainingRoomWindow", import(".BaseWindow"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local PartnerFilter = import("app.components.PartnerFilter")
local HeroIcon = import("app.components.HeroIcon")
local FormationItem = class("FormationItem")
local exploreModel = xyd.models.exploreModel
local trainingTable = xyd.tables.exploreTrainingTable
local atrTexts = {
	__("TRAVEL_MAIN_TEXT03"),
	__("TRAVEL_MAIN_TEXT02"),
	__("TRAVEL_MAIN_TEXT04"),
	__("TRAVEL_MAIN_TEXT05"),
	__("TRAVEL_MAIN_TEXT37")
}

function ExploreTrainingRoomWindow:ctor(name, params)
	ExploreTrainingRoomWindow.super.ctor(self, name, params)

	self.index = 1
	self.data = exploreModel:getTrainRoomsInfo()
end

function ExploreTrainingRoomWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ExploreTrainingRoomWindow:getUIComponent()
	self.resGroup = self.window_:NodeByName("resGroup").gameObject
	local groupMain = self.window_:NodeByName("groupAction").gameObject
	local groupTop = groupMain:NodeByName("groupTop").gameObject
	self.closeBtn = groupTop:NodeByName("closeBtn").gameObject
	self.tipsBtn = groupTop:NodeByName("tipsBtn").gameObject
	self.helpBtn = groupTop:NodeByName("helpBtn").gameObject
	self.levelLabel = groupTop:ComponentByName("levelLabel", typeof(UILabel))
	self.labelTitle = groupTop:ComponentByName("labelTitle", typeof(UILabel))
	self.nav = groupMain:NodeByName("nav").gameObject
	self.tabIconImgList = {}

	for i = 1, 5 do
		local iconImg = self.nav:ComponentByName("tab_" .. i .. "/iconImg", typeof(UISprite))

		table.insert(self.tabIconImgList, iconImg)
	end

	local content = groupMain:NodeByName("content").gameObject
	self.groupPartnerNode = content:NodeByName("groupPartner").gameObject
	self.groupPartner = {}

	for i = 1, 3 do
		local partner = self.groupPartnerNode:ComponentByName("partner_" .. i, typeof(UISprite))
		local item = {
			partnerBg = partner,
			addImg = partner:NodeByName("addImg").gameObject,
			modelNode = partner:NodeByName("model").gameObject,
			lockImg = partner:NodeByName("lockImg").gameObject,
			touchField = partner:NodeByName("touchField").gameObject,
			partnerOnimg = partner:NodeByName("partnerOnImg").gameObject,
			effectNode = partner:NodeByName("effect").gameObject
		}

		table.insert(self.groupPartner, item)
	end

	self.chooseGroup = self.groupPartnerNode:NodeByName("chooseGroup").gameObject
	self.fGroup = self.chooseGroup:NodeByName("fGroup").gameObject
	self.partnerScrollView = self.chooseGroup:ComponentByName("partnerScroller", typeof(UIScrollView))
	self.partnerListWarpContent_ = self.chooseGroup:ComponentByName("partnerScroller/partnerContainer", typeof(MultiRowWrapContent))
	self.heroRoot = self.chooseGroup:NodeByName("hero_root").gameObject
	self.closeBlank = self.chooseGroup:NodeByName("closeBlank").gameObject
	self.closeBlank2 = self.chooseGroup:NodeByName("closeBlank2").gameObject
	self.partnerMultiWrap_ = FixedMultiWrapContent.new(self.partnerScrollView, self.partnerListWarpContent_, self.heroRoot, FormationItem, self)
	local groupAtr = content:NodeByName("groupAtr").gameObject
	self.atrEffect = groupAtr:NodeByName("effect").gameObject
	self.groupLabel1 = {}
	self.groupLabel2 = {}

	for i = 1, 2 do
		local groupLabel = groupAtr:NodeByName("groupLabel" .. i).gameObject
		local labelAtr = groupLabel:ComponentByName("labelAtr", typeof(UILabel))
		local labelCur = groupLabel:ComponentByName("labelCur", typeof(UILabel))
		local labelNext = groupLabel:ComponentByName("labelNext", typeof(UILabel))

		table.insert(self["groupLabel" .. i], labelAtr)
		table.insert(self["groupLabel" .. i], labelCur)
		table.insert(self["groupLabel" .. i], labelNext)
	end

	self.groupCost_ = content:NodeByName("groupCost_").gameObject

	for i = 1, 2 do
		self["labelCost" .. i] = self.groupCost_:ComponentByName("labelCost" .. i, typeof(UILabel))
		self["imgCost" .. i] = self.groupCost_:ComponentByName("imgCost" .. i, typeof(UISprite))
	end

	self.btnLevelUp = content:NodeByName("btnLevelUp").gameObject
	self.iconMax = self.btnLevelUp:NodeByName("iconMax").gameObject
	self.labelBtnLevelUp = self.btnLevelUp:ComponentByName("labelLevelUp", typeof(UILabel))
	self.labelTips = content:ComponentByName("labelTips", typeof(UILabel))
end

function ExploreTrainingRoomWindow:initTop()
	self.resMana_ = require("app.components.ResItem").new(self.resGroup)
	self.resBlue_ = require("app.components.ResItem").new(self.resGroup)

	self.resGroup:GetComponent(typeof(UILayout)):Reposition()
	self.resMana_:setInfo({
		tableId = xyd.ItemID.MANA
	})
	self.resBlue_:setInfo({
		tableId = xyd.ItemID.BLUE_CRYSTAL
	})
	self.resBlue_:hidePlus()
end

function ExploreTrainingRoomWindow:layout()
	self:initTop()
	self:resizeChooseGroup()

	self.tab = require("app.common.ui.CommonTabBar").new(self.nav, 5, function (index)
		xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)
		self:setNavIconImg(index)
		self:updateContent(index)
		self:updateLockImg()
		self:initHeroGroup(index)
	end, nil, {
		chosen = {
			color = Color.New2(1531992831)
		},
		unchosen = {
			color = Color.New2(4244172031.0)
		}
	})
	local prefix = xyd.Global.lang == "fr_fr" and "Niv." or "Lv."
	self.levelLabel.text = prefix .. exploreModel:getTrainLevel()

	for i = 1, 5 do
		self.tab.tabs[i].label.text = prefix .. self.data[i].level
	end

	self.labelBtnLevelUp.text = __("TRAVEL_MAIN_TEXT10")
	local text1 = {
		"TRAVEL_MAIN_TEXT07",
		"TRAVEL_MAIN_TEXT08",
		"TRAVEL_MAIN_TEXT09"
	}

	for i = 1, 3 do
		self.groupLabel1[i].text = __(text1[i])
	end

	self.labelTitle.text = __("TRAVEL_BUILDING_NAME4")

	self.chooseGroup:SetActive(false)
	self:updateContent(self.index)
	self:updateLockImg()
end

function ExploreTrainingRoomWindow:resizeChooseGroup()
	local sWidth, sHeight = xyd.getScreenSize()

	if xyd.Global.maxHeight < sHeight then
		sHeight = xyd.Global.maxHeight
	end

	local widget = self.chooseGroup:GetComponent(typeof(UIWidget))

	if widget then
		local minHeight = 450

		if minHeight < sHeight / 2 - 190 then
			minHeight = sHeight / 2 - 190
		end

		widget.height = minHeight
	end
end

function ExploreTrainingRoomWindow:setNavIconImg(index)
	for i = 1, 5 do
		if i == index then
			xyd.setUISpriteAsync(self.tabIconImgList[i], nil, "nav_icon_" .. i .. "_1")
		else
			xyd.setUISpriteAsync(self.tabIconImgList[i], nil, "nav_icon_" .. i .. "_2")
		end
	end
end

function ExploreTrainingRoomWindow:updateContent(index)
	self.index = index
	local curLev = self.data[self.index].level
	self.groupLabel2[1].text = atrTexts[self.index]

	if xyd.Global.lang == "fr_fr" then
		local fontSize = self.index == 5 and 18 or 20
		self.groupLabel2[1].fontSize = fontSize
	end

	self.groupLabel2[2].text = "+" .. trainingTable:getEffectString(self.index, curLev)

	if curLev < trainingTable:getLvMax(self.index) then
		self.groupLabel2[3].text = "+" .. trainingTable:getEffectString(self.index, curLev + 1)
		self.groupLabel2[3].color = Color.New2(230518015)

		self.iconMax:SetActive(false)
		self.labelBtnLevelUp:SetActive(true)
		self.groupCost_:SetActive(true)
		xyd.applyOrigin(self.btnLevelUp:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnLevelUp, true)
	else
		self.groupLabel2[3].text = "--"
		self.groupLabel2[3].color = Color.New2(2795939583.0)

		self.iconMax:SetActive(true)
		self.labelBtnLevelUp:SetActive(false)
		self.groupCost_:SetActive(false)
		xyd.applyGrey(self.btnLevelUp:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnLevelUp, false)
	end

	local cost = trainingTable:getCost(self.index, curLev)
	local flag = true

	for i = 1, 2 do
		local data = cost[i]
		self["labelCost" .. i].text = xyd.getRoughDisplayNumber(data[2])

		xyd.setUISpriteAsync(self["imgCost" .. i], nil, "icon_" .. data[1])

		if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
			self["labelCost" .. i].color = Color.New2(3981269247.0)
			flag = false
		else
			self["labelCost" .. i].color = Color.New2(1363960063)
		end
	end

	local limit = exploreModel:getTrainingLevelUplimit()
	local minLev = 61

	for i = 1, 5 do
		if i ~= self.index and self.data[i].level < minLev then
			minLev = self.data[i].level
		end
	end

	local maxLev = 0
	local limitLev = 0

	for _, item in ipairs(limit) do
		if item[2] <= minLev then
			maxLev = item[1]
		else
			limitLev = item[2]

			break
		end
	end

	self.labelTips.text = __("TRAVEL_MAIN_TEXT11", limitLev)

	self.labelTips:SetActive(curLev == maxLev and curLev < trainingTable:getLvMax(self.index))

	flag = flag and curLev < maxLev

	if flag then
		xyd.applyOrigin(self.btnLevelUp:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnLevelUp, true)
	else
		xyd.applyGrey(self.btnLevelUp:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnLevelUp, false)
	end
end

function ExploreTrainingRoomWindow:updateLockImg()
	local slotLimit = exploreModel:getTrainingSlotLimit()

	for i = 1, 3 do
		local limLev = slotLimit[i][1]
		local item = self.groupPartner[i]
		local partners = self.data[self.index]

		if limLev <= self.data[self.index].level then
			item.addImg:SetActive(not partners[i] or partners == 0)
			item.touchField:SetActive(true)
			item.lockImg:SetActive(false)
			xyd.setUISpriteAsync(item.partnerBg, nil, "partner_bg_1")
		else
			item.addImg:SetActive(false)
			item.touchField:SetActive(false)
			item.lockImg:SetActive(true)
			xyd.setUISpriteAsync(item.partnerBg, nil, "partner_bg_2")
		end
	end
end

function ExploreTrainingRoomWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_TRAIN_UPGRADE, handler(self, self.onLevelUp))
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_TRAIN_SET_PARTNER, handler(self, self.onSetPartner))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.WindowManager.get():openWindow("explore_help_window", {
			key = "TRAVEL_MAIN_HOUSE_HELP"
		})
	end

	UIEventListener.Get(self.tipsBtn).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.WindowManager.get():openWindow("explore_training_attr_preview_window")
	end

	UIEventListener.Get(self.btnLevelUp).onClick = function ()
		if not self.isPlayAnimation then
			exploreModel:reqTrainingLevelUp(self.index)
		end
	end

	for i = 1, 3 do
		local item = self.groupPartner[i]

		UIEventListener.Get(item.touchField).onClick = function ()
			self:onHeroAddClick(i)
		end
	end

	UIEventListener.Get(self.closeBlank).onClick = function ()
		self.chooseGroup:SetActive(false)
		self:setPartner()

		self.slotIndex = nil
	end

	UIEventListener.Get(self.closeBlank2).onClick = function ()
		self.chooseGroup:SetActive(false)
		self:setPartner()

		self.slotIndex = nil
	end

	local slotLimit = exploreModel:getTrainingSlotLimit()

	for i = 1, 3 do
		local item = self.groupPartner[i]
		local limLev = slotLimit[i][1]

		UIEventListener.Get(item.lockImg).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

			if self.chooseGroup.activeSelf then
				self.chooseGroup:SetActive(false)
				self:setPartner()

				self.slotIndex = nil
			end

			if not xyd.GuideController.get():isPlayGuide() then
				xyd.showToast(__("TRAVEL_MAIN_TEXT43", limLev))
			end
		end
	end
end

function ExploreTrainingRoomWindow:onItemChange(event)
	local items = event.data.items

	for _, item in ipairs(items) do
		if item.item_id == xyd.ItemID.BLUE_CRYSTAL then
			self.resBlue_:updateNum()
		elseif item.item_id == xyd.ItemID.MANA then
			self.resMana_:updateNum()

			local data = trainingTable:getCost(self.index, self.data[self.index].level)[1]

			if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
				self.labelCost1.color = Color.New2(3981269247.0)
			else
				self.labelCost1.color = Color.New2(1363960063)
			end
		end
	end
end

function ExploreTrainingRoomWindow:onLevelUp(event)
	xyd.SoundManager.get():playSound(xyd.SoundID.UPDATE_BUILDING)

	self.data = exploreModel:getTrainRoomsInfo()
	local table_id = tonumber(event.data.table_id)
	self.levelLabel.text = __("TRAVEL_MAIN_TEXT13", exploreModel:getTrainLevel())
	local effect_ = xyd.Spine.new(self.atrEffect)
	self.isPlayAnimation = true

	effect_:setInfo("fx_ui_saoxing", function ()
		effect_:SetLocalScale(0.91, 0.7, 1)
		effect_:SetLocalPosition(15, -8, 0)
		effect_:play("texiao01", 1, 1, function ()
			self.isPlayAnimation = false

			effect_:destroy()

			if self and self.atrEffect then
				NGUITools.DestroyChildren(self.atrEffect.transform)
			end
		end)
	end)

	local partners = self.data[table_id].partners
	local slotLimit = exploreModel:getTrainingSlotLimit()

	for i = 1, 3 do
		if partners[i] and partners[i] ~= 0 then
			NGUITools.DestroyChildren(self.groupPartner[i].effectNode.transform)

			local effect1 = xyd.Spine.new(self.groupPartner[i].effectNode)
			local effect2 = xyd.Spine.new(self.groupPartner[i].effectNode)

			effect1:setInfo("travel_other", function ()
				effect1:SetLocalPosition(0, 90, 0)
				effect1:setRenderTarget(self.groupPartner[i].partnerBg:GetComponent(typeof(UIWidget)), 2)
				effect1:play("travel_other_02_1", 1, 1)
			end, true)
			effect2:setInfo("travel_other", function ()
				effect2:SetLocalPosition(0, 90, 0)
				effect2:setRenderTarget(self.groupPartner[i].partnerBg:GetComponent(typeof(UIWidget)), 200)
				effect2:play("travel_other_02_2", 1, 1)
			end, true)
		end

		local limLev = slotLimit[i][1]

		if self.data[table_id].level == limLev then
			self.groupPartner[i].lockImg:SetActive(false)

			local effect = xyd.Spine.new(self.groupPartner[i].effectNode)

			effect:setInfo("travel_other", function ()
				effect:SetLocalPosition(0, 100, 0)
				effect:play("travel_other_04", 1, 1, function ()
					self:updateLockImg()
				end)
			end, true)
		end
	end

	self.tab.tabs[table_id].label.text = "Lv." .. self.data[table_id].level

	if table_id == self.index then
		self:updateContent(table_id)
	end
end

function ExploreTrainingRoomWindow:onSetPartner(event)
	self.data = exploreModel:getTrainRoomsInfo()
end

function ExploreTrainingRoomWindow:initHeroGroup(index)
	local partners = self.data[index].partners
	self.slotHeroList = {}

	for i = 1, 3 do
		if self.groupPartner[i].modelEffect then
			self.groupPartner[i].modelEffect:destroy()

			self.groupPartner[i].modelEffect = nil
		end

		if partners[i] and partners[i] ~= 0 then
			self.groupPartner[i].addImg:SetActive(false)

			local partner = xyd.models.slot:getPartner(partners[i])
			local partnerInfo = partner:getInfo()
			self.slotHeroList[i] = partner:getPartnerID()
			local modelID = xyd.getModelID(partnerInfo.tableID, false, partner:getSkinID(), 1)
			local name = xyd.tables.modelTable:getModelName(modelID)
			local scale = xyd.tables.modelTable:getScale(modelID)
			self.groupPartner[i].modelEffect = xyd.Spine.new(self.groupPartner[i].modelNode)

			self.groupPartner[i].modelEffect:setInfo(name, function ()
				self.groupPartner[i].modelEffect:setRenderTarget(nil, i)
				self.groupPartner[i].modelEffect:SetLocalScale(scale, scale, scale)
				self.groupPartner[i].modelEffect:setToSetupPose()
				self.groupPartner[i].modelEffect:play("attack", 1, 1, function ()
					self.groupPartner[i].modelEffect:play("idle", 0)
				end)
			end, true)
		end
	end
end

function ExploreTrainingRoomWindow:setPartner()
	local partnerID = 0

	if self.slotHeroList[self.slotIndex] then
		partnerID = self.slotHeroList[self.slotIndex]
	end

	if partnerID ~= self.data[self.index].partners[self.slotIndex] then
		exploreModel:setTrainPartner(self.index, self.slotIndex, partnerID)
	end

	self.groupPartner[self.slotIndex].partnerOnimg:SetActive(false)
end

function ExploreTrainingRoomWindow:onHeroAddClick(index)
	if self.slotIndex then
		self:setPartner()

		if self.slotIndex == index and self.chooseGroup.activeSelf then
			self.chooseGroup:SetActive(false)

			self.slotIndex = nil

			return
		end
	end

	self.slotIndex = index

	self.groupPartner[self.slotIndex].partnerOnimg:SetActive(true)

	self.selectedItem = nil
	self.selectedItemInfo = nil

	self.chooseGroup:SetLocalPosition(0, -1090, 0)
	self.chooseGroup:SetActive(true)

	local sequence = self:getSequence()

	sequence:Append(self.chooseGroup.transform:DOLocalMoveY(-276, 0.5))
	sequence:AppendCallback(function ()
		sequence:Kill(true)
	end)
	self:initPartnerList()
end

function ExploreTrainingRoomWindow:initPartnerList()
	if not self.initPartnerFilter then
		self.initPartnerFilter = true
		self.selectGroup = 0
		local params = {
			isCanUnSelected = 1,
			chosenGroup = 0,
			scale = 0.83,
			gap = 20,
			callback = function (group)
				self:onSelectGroup(group)
			end,
			width = self.fGroup:GetComponent(typeof(UIWidget)).width
		}
		local partnerFilter = PartnerFilter.new(self.fGroup.gameObject, params)

		for i = 1, partnerFilter.groupNum do
			local filterNode = partnerFilter["filterGroup" .. i]

			xyd.setUISpriteAsync(filterNode:ComponentByName("unchosen", typeof(UISprite)), nil, "explore_partner_unchosen")
			xyd.setUISpriteAsync(filterNode:ComponentByName("group" .. i .. "_chosen", typeof(UISprite)), nil, "explore_partner_chosen")
		end
	end

	self:iniPartnerData(self.selectGroup)
end

function ExploreTrainingRoomWindow:onSelectGroup(group)
	self.selectGroup = group
	self.selectedItem = nil
	self.selectedItemInfo = nil

	self:iniPartnerData(self.selectGroup)
end

function ExploreTrainingRoomWindow:iniPartnerData(group)
	local list = self:getPartnerList(group)

	if xyd.GuideController.get():isPlayGuide() then
		list[1].dragScrollView = nil
	end

	self.partnerList = list

	self.partnerMultiWrap_:setInfos(list, {})
end

function ExploreTrainingRoomWindow:getPartnerList(group)
	local partnerList = xyd.models.slot:getSortedPartners()[tostring(xyd.partnerSortType.STAR) .. "_" .. tostring(group)]
	local exceptedList = {}
	local list = {}
	self.data = exploreModel:getTrainRoomsInfo()
	local selectID = self.slotHeroList[self.slotIndex] or 0

	for i = 1, 5 do
		local partners = self.data[i].partners

		for sIndex, partnerId in ipairs(partners) do
			if partnerId ~= 0 and partnerId ~= selectID then
				exceptedList[partnerId] = 1
				local partner = xyd.models.slot:getPartner(partnerId)
				local partnerInfo = partner:getInfo()
				partnerInfo.selectIndex = i
				partnerInfo.slotIndex = sIndex
				partnerInfo.dragScrollView = self.partnerScrollView

				if not xyd.GuideController.get():isPlayGuide() and group == 0 then
					table.insert(list, partnerInfo)
				end
			end
		end
	end

	if selectID > 0 then
		local sPartner = xyd.models.slot:getPartner(selectID)

		if sPartner then
			local sPartnerInfo = sPartner:getInfo()
			sPartnerInfo.isSelected = true
			sPartnerInfo.dragScrollView = self.partnerScrollView

			table.insert(list, sPartnerInfo)

			exceptedList[selectID] = 1
		end
	end

	for _, partnerId in ipairs(partnerList) do
		if partnerId ~= selectID and exceptedList[partnerId] ~= 1 then
			local partner = xyd.models.slot:getPartner(partnerId)
			local partnerInfo = partner:getInfo()
			partnerInfo.dragScrollView = self.partnerScrollView

			table.insert(list, partnerInfo)
		end
	end

	return list
end

function ExploreTrainingRoomWindow:offSlot(formationItem)
	local partnerInfo = formationItem:getInfo()
	local selectIndex = partnerInfo.selectIndex
	local slotIndex = partnerInfo.slotIndex

	if selectIndex == self.index then
		self.slotHeroList[slotIndex] = nil

		NGUITools.DestroyChildren(self.groupPartner[slotIndex].effectNode.transform)
		NGUITools.DestroyChildren(self.groupPartner[slotIndex].modelNode.transform)
		self.groupPartner[slotIndex].addImg:SetActive(true)
	end

	exploreModel:setTrainPartner(selectIndex, slotIndex, 0)
end

function ExploreTrainingRoomWindow:setSelectHero(formationItem)
	if not self.selectedItem then
		self.selectedItem = formationItem
		self.selectedItemInfo = formationItem:getInfo()
	end
end

function ExploreTrainingRoomWindow:selectHero(item, isSame)
	if isSame then
		self.selectedItem = nil
		self.selectedItemInfo = nil
		self.slotHeroList[self.slotIndex] = nil

		self.groupPartner[self.slotIndex].modelEffect:destroy()

		self.groupPartner[self.slotIndex].modelEffect = nil

		self.groupPartner[self.slotIndex].addImg:SetActive(true)
		item:setChoose(false)
	else
		self.groupPartner[self.slotIndex].addImg:SetActive(false)

		if self.selectedItem then
			self.selectedItem:setChoose(false)
			self.selectedItem:setSelected(false)
		end

		if self.selectedItemInfo then
			local infoIndex = self.selectedItemInfo.infoIndex
			self.partnerList[infoIndex].isSelected = false

			self.partnerMultiWrap_:updateInfo(infoIndex, self.partnerList[infoIndex])
		end

		self.selectedItem = item
		local partnerInfo = item:getInfo()

		item:setChoose(true)

		self.selectedItemInfo = partnerInfo
		local index = self.slotIndex
		self.slotHeroList[index] = partnerInfo.partnerID
		local partner = xyd.models.slot:getPartner(partnerInfo.partnerID)
		local modelID = xyd.getModelID(partnerInfo.tableID, false, partner:getSkinID(), 1)
		local name = xyd.tables.modelTable:getModelName(modelID)
		local scale = xyd.tables.modelTable:getScale(modelID)

		if self.groupPartner[index].modelEffect then
			self.groupPartner[index].modelEffect:destroy()
		end

		NGUITools.DestroyChildren(self.groupPartner[index].effectNode.transform)

		local effect1 = xyd.Spine.new(self.groupPartner[index].effectNode)
		local effect2 = xyd.Spine.new(self.groupPartner[index].effectNode)

		effect1:setInfo("travel_other", function ()
			effect1:SetLocalPosition(0, 90, 0)
			effect1:play("travel_other_03_1", 1, 1)
		end)
		effect2:setInfo("travel_other", function ()
			effect2:SetLocalPosition(0, 90, 0)
			effect2:play("travel_other_03_2", 1, 1)
		end)

		self.groupPartner[index].modelEffect = xyd.Spine.new(self.groupPartner[index].modelNode)

		self.groupPartner[index].modelEffect:setInfo(name, function ()
			self.groupPartner[index].modelEffect:setRenderTarget(nil, index)
			self.groupPartner[index].modelEffect:setToSetupPose()
			self.groupPartner[index].modelEffect:startAtFrame(2)
			self.groupPartner[index].modelEffect:SetLocalScale(scale, scale, scale)
			self.groupPartner[index].modelEffect:play("attack", 1, 1, function ()
				self.groupPartner[index].modelEffect:play("idle", 0)
			end)
		end, true)
	end
end

local FORMATION_ICON_NAME = {
	"explore_icon_5",
	"explore_icon_4",
	"explore_icon_6",
	"explore_icon_7",
	"explore_icon_8"
}

function FormationItem:ctor(go, parent)
	self.go = go
	self.onImage = self.go:ComponentByName("on_image", typeof(UISprite))
	self.parent = parent
	self.heroIcon = HeroIcon.new(self.go)

	local function longPressCallback()
		self:showPartnerDetail()
	end

	self.heroIcon:setLongPressListener(longPressCallback)

	self.info = nil
end

function FormationItem:showPartnerDetail()
	if not self.info then
		return
	end

	local params = {
		sort_key = "0_0",
		unable_move = true,
		isLongTouch = true,
		ifSchool = false,
		not_open_slot = true,
		if3v3 = false,
		partner_id = self.info.partnerID,
		table_id = self.info.tableID,
		battleData = self.params_,
		skin_id = self.info.skin_id
	}

	xyd.openWindow("partner_detail_window", params)
end

function FormationItem:update(wrapIndex, infoIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.onImage:SetActive(false)

	self.info = info
	self.info.infoIndex = infoIndex

	self.go:SetActive(true)

	self.isSelected = info.isSelected

	local function callback1()
		self.isSelected = not self.isSelected
		self.info.isSelected = self.isSelected

		self.parent:selectHero(self, not self.isSelected)
	end

	local function callback2()
		xyd.alertYesNo(__("TRAVEL_NEW_TEXT17"), function (yes)
			if yes then
				self.parent:offSlot(self)

				self.info.callback = callback1
				self.info.selectIndex = nil
				self.info.slotIndex = nil

				self:setOtherSelect(false)
				self.heroIcon:setInfo(self.info)
			end
		end)
	end

	self.info.callback = callback1

	if self.info.selectIndex and self.info.selectIndex > 0 then
		self.info.callback = callback2
	end

	self.info.noClickSelected = true

	self.heroIcon:setInfo(self.info)
	self:setChoose(self.isSelected)

	if self.isSelected then
		self.parent:setSelectHero(self)
	end

	if self.info.selectIndex and self.info.selectIndex > 0 then
		self:setOtherSelect(true)
	end
end

function FormationItem:setOtherSelect(status)
	if status then
		xyd.setUISpriteAsync(self.onImage, nil, FORMATION_ICON_NAME[self.info.selectIndex or 1])
	end

	self.onImage:SetActive(status)
	self.heroIcon:setMask(status)
end

function FormationItem:getGameObject()
	return self.go
end

function FormationItem:setChoose(status)
	if self.heroIcon then
		self.heroIcon:setChoose(status)
	end
end

function FormationItem:getInfo()
	return self.info
end

function FormationItem:setSelected(flag)
	self.isSelected = flag
	self.info.isSelected = flag
	self.info.selectIndex = nil
	self.info.slotIndex = nil
end

return ExploreTrainingRoomWindow
