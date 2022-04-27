local ExploreBaseBuildingWindow = class("ExploreBaseBuildingWindow", import(".BaseWindow"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local PartnerFilter = import("app.components.PartnerFilter")
local HeroIcon = import("app.components.HeroIcon")
local FormationItem = class("FormationItem")
local exploreModel = xyd.models.exploreModel
local buildingMaxLevel = 50

function ExploreBaseBuildingWindow:ctor(name, params)
	ExploreBaseBuildingWindow.super.ctor(self, name, params)

	self.buildingType = params.buildingType or self.buildingType
	self.data = exploreModel:getBuildsInfo()[self.buildingType]
end

function ExploreBaseBuildingWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ExploreBaseBuildingWindow:getUIComponent()
	self.resGroup = self.window_:NodeByName("resGroup").gameObject
	local groupMain = self.window_:NodeByName("groupAction").gameObject
	local groupTop = groupMain:NodeByName("groupTop").gameObject
	self.closeBtn = groupTop:NodeByName("closeBtn").gameObject
	self.labelTitle = groupTop:ComponentByName("labelTitle", typeof(UILabel))
	local groupMiddle = groupMain:NodeByName("groupMiddle").gameObject
	self.lpEffect = groupMiddle:NodeByName("effect").gameObject
	self.groupLabelMiddle = {}

	for i = 1, 2 do
		self["imgBuilding" .. i] = groupMiddle:ComponentByName("group" .. i .. "/building", typeof(UITexture))
		local groupFormation = groupMiddle:NodeByName("group" .. i .. "/groupFormation").gameObject
		self.groupLabelMiddle[i] = {
			groupFormation:ComponentByName("labelLevel", typeof(UILabel))
		}

		for j = 1, 2 do
			local groupLabel = groupFormation:NodeByName("groupLabel" .. j).gameObject
			local labelName = groupLabel:ComponentByName("labelName", typeof(UILabel))
			local labelNum = groupLabel:ComponentByName("labelNum", typeof(UILabel))

			table.insert(self.groupLabelMiddle[i], labelName)
			table.insert(self.groupLabelMiddle[i], labelNum)
		end
	end

	local groupBottom = groupMain:NodeByName("groupBottom").gameObject
	self.groupHero_1 = groupBottom:NodeByName("groupHero_1").gameObject
	self.groupHero = {}

	for i = 1, 2 do
		for j = 1, 2 do
			local groupHero = groupBottom:NodeByName("groupHero_" .. j).gameObject
			local heroRoot = groupHero:NodeByName("hero_root_" .. i).gameObject
			local addImg = heroRoot:NodeByName("addImg").gameObject
			local lockImg = heroRoot:NodeByName("lockImg").gameObject
			local icon_root = heroRoot:NodeByName("icon_root").gameObject
			local effect = heroRoot:NodeByName("effect").gameObject
			local item = {
				addImg = addImg,
				lockImg = lockImg,
				icon_root = icon_root,
				effect = effect,
				icon_bg = heroRoot:GetComponent(typeof(UISprite))
			}

			table.insert(self.groupHero, item)
		end
	end

	self.labelOutput = groupBottom:ComponentByName("groupHero_1/labelOutput", typeof(UILabel))
	self.labelStay = groupBottom:ComponentByName("groupHero_2/labelStay", typeof(UILabel))
	self.groupCost_ = groupBottom:NodeByName("groupCost_").gameObject

	for i = 1, 2 do
		self["labelCost" .. i] = self.groupCost_:ComponentByName("labelCost" .. i, typeof(UILabel))
		self["imgCost" .. i] = self.groupCost_:ComponentByName("imgCost" .. i, typeof(UISprite))
	end

	self.btnLevelUp = groupBottom:NodeByName("btnLevelUp").gameObject
	self.iconMax = self.btnLevelUp:NodeByName("iconMax").gameObject
	self.labelBtnLevelUp = self.btnLevelUp:ComponentByName("labelLevelUp", typeof(UILabel))
	self.labelTips = groupBottom:ComponentByName("labelTips", typeof(UILabel))
	self.chooseGroup = groupBottom:NodeByName("chooseGroup").gameObject
	self.fGroup = self.chooseGroup:NodeByName("fGroup").gameObject
	self.partnerScrollView = self.chooseGroup:ComponentByName("partnerScroller", typeof(UIScrollView))
	self.partnerListWarpContent_ = self.chooseGroup:ComponentByName("partnerScroller/partnerContainer", typeof(MultiRowWrapContent))
	self.heroRoot = self.chooseGroup:NodeByName("hero_root").gameObject
	self.closeBlank = self.chooseGroup:NodeByName("closeBlank").gameObject
	self.closeBlank2 = self.chooseGroup:NodeByName("closeBlank2").gameObject
	self.partnerMultiWrap_ = FixedMultiWrapContent.new(self.partnerScrollView, self.partnerListWarpContent_, self.heroRoot, FormationItem, self)
end

function ExploreBaseBuildingWindow:initTop()
	self.resMana_ = require("app.components.ResItem").new(self.resGroup)
	self.resWood_ = require("app.components.ResItem").new(self.resGroup)

	self.resGroup:GetComponent(typeof(UILayout)):Reposition()
	self.resMana_:setInfo({
		tableId = xyd.ItemID.MANA
	})
	self.resWood_:setInfo({
		tableId = xyd.ItemID.SUPER_WOOD
	})
	self.resWood_:hidePlus()
end

function ExploreBaseBuildingWindow:layout()
	self:initTop()
	self.chooseGroup:SetActive(false)

	self.labelBtnLevelUp.text = __("TRAVEL_MAIN_TEXT10")

	self:initHeroGroup()
	self:updateContent()
	self:updateLockImg()
end

function ExploreBaseBuildingWindow:updateContent()
	local levelUpCost = self.exploreTable:getLevelUpCost(self.data.level)
	local flag = true

	if self.data.level < buildingMaxLevel then
		for i = 1, 2 do
			local data = levelUpCost[i]
			self["labelCost" .. i].text = xyd.getRoughDisplayNumber(data[2])

			xyd.setUISpriteAsync(self["imgCost" .. i], nil, "icon_" .. data[1])

			if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
				self["labelCost" .. i].color = Color.New2(3981269247.0)
				flag = false
			else
				self["labelCost" .. i].color = Color.New2(1363960063)
			end
		end
	else
		self.groupCost_:SetActive(false)
		self.labelBtnLevelUp:SetActive(false)
		self.iconMax:SetActive(true)
	end

	local limit = exploreModel:getBuildingsLevelUplimit()
	local trainLevel = exploreModel:getTrainLevel()
	local maxLev = 0
	local limitLev = 0

	for _, item in ipairs(limit) do
		if item[2] <= trainLevel then
			maxLev = item[1]
		else
			limitLev = item[2]

			break
		end
	end

	self.labelTips.text = __("TRAVEL_MAIN_TEXT20", limitLev)

	self.labelTips:SetActive(self.data.level < buildingMaxLevel and self.data.level == maxLev)

	flag = flag and self.data.level < maxLev

	if flag then
		xyd.applyOrigin(self.btnLevelUp:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnLevelUp, true)
	else
		xyd.applyGrey(self.btnLevelUp:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnLevelUp, false)
	end
end

function ExploreBaseBuildingWindow:updateLockImg()
	local slotLimit = exploreModel:getBuildingSlotLimit()

	for i = 1, 4 do
		local limLev = slotLimit[i][1]
		local item = self.groupHero[i]

		if limLev <= self.data.level then
			item.addImg:SetActive(true)
			item.lockImg:SetActive(false)
			xyd.setUISpriteAsync(item.icon_bg:GetComponent(typeof(UISprite)), nil, "icon_frame_1")
		else
			xyd.setUISpriteAsync(item.icon_bg:GetComponent(typeof(UISprite)), nil, "icon_frame_2")
			item.addImg:SetActive(false)
			item.lockImg:SetActive(true)
		end
	end
end

function ExploreBaseBuildingWindow:initHeroGroup()
	local partners = self.data.partners
	self.slotHeroList = {}
	self.slotHeroIconList = {}

	for i = 1, 4 do
		if partners[i] and partners[i] ~= 0 then
			local heroIcon = HeroIcon.new(self.groupHero[i].icon_root)
			self.slotHeroList[i] = partners[i]
			local partner = xyd.models.slot:getPartner(partners[i])
			local partnerInfo = {
				noClickSelected = true,
				scale = 0.9,
				partnerID = partner:getPartnerID(),
				tableID = partner:getTableID(),
				lev = partner:getLevel(),
				star = partner:getStar(),
				skin_id = partner.skin_id,
				is_vowed = partner.is_vowed
			}

			heroIcon:setInfo(partnerInfo)
			heroIcon:setNoClick(true)

			self.slotHeroIconList[i] = heroIcon
		end
	end

	self:updateOutAndStayFactor()
end

function ExploreBaseBuildingWindow:updateOutAndStayFactor()
	self.outFactor = 0
	self.stayFactor = 0

	for i = 1, 4 do
		if self.slotHeroList[i] then
			local partnerID = self.slotHeroList[i]
			local partner = xyd.models.slot:getPartner(partnerID)

			if i % 2 == 0 then
				self.stayFactor = self.stayFactor + xyd.tables.exploreFacilityAddTable:getStayAdd(self.buildingType, partner:getStar())
			else
				self.outFactor = self.outFactor + xyd.tables.exploreFacilityAddTable:getOutAdd(self.buildingType, partner:getStar())
			end
		end
	end

	self.labelOutput.text = __("TRAVEL_MAIN_TEXT18") .. "[c][54a759]+" .. self.outFactor .. "%[-][/c]"
	self.labelStay.text = __("TRAVEL_MAIN_TEXT19") .. "[c][54a759]+" .. self.stayFactor .. "%[-][/c]"

	self:updateOutAndStay()
end

function ExploreBaseBuildingWindow:onLevelUp(event)
	xyd.SoundManager.get():playSound(xyd.SoundID.UPDATE_BUILDING)

	self.data = exploreModel:getBuildsInfo()[self.buildingType]

	NGUITools.DestroyChildren(self.lpEffect.transform)

	local lpEffect = xyd.Spine.new(self.lpEffect)

	lpEffect:setInfo("travel_other", function ()
		lpEffect:play("travel_other_05", 1, 1)
	end)

	local slotLimit = exploreModel:getBuildingSlotLimit()

	for i = 2, 4 do
		local limLev = slotLimit[i][1]

		if self.data.level == limLev then
			self.groupHero[i].lockImg:SetActive(false)

			local effect = xyd.Spine.new(self.groupHero[i].effect)

			effect:setInfo("travel_other", function ()
				effect:play("travel_other_04", 1, 1, function ()
					self:updateLockImg()
				end)
			end)
		end
	end

	self:updateContent()
	self:updateOutAndStay()
end

function ExploreBaseBuildingWindow:onSetPartner(event)
	self.data = exploreModel:getBuildsInfo()[self.buildingType]
end

function ExploreBaseBuildingWindow:onItemChange(event)
	local items = event.data.items

	for _, item in ipairs(items) do
		if item.item_id == xyd.ItemID.SUPER_WOOD then
			self.resWood_:updateNum()
		elseif item.item_id == xyd.ItemID.MANA then
			self.resMana_:updateNum()

			local data = self.exploreTable:getLevelUpCost(self.data.level)[1]

			if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
				self.labelCost1.color = Color.New2(3981269247.0)
			else
				self.labelCost1.color = Color.New2(1363960063)
			end
		end
	end
end

function ExploreBaseBuildingWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_BUILDING_UPGRADE, handler(self, self.onLevelUp))
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_BUILDING_SET_PARTNER, handler(self, self.onSetPartner))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnLevelUp).onClick = function ()
		exploreModel:reqBuildingLevelUp(self.buildingType)
	end

	for i = 1, 4 do
		local item = self.groupHero[i]

		UIEventListener.Get(item.addImg).onClick = function ()
			self:onHeroAddClick(i)
		end
	end

	UIEventListener.Get(self.closeBlank).onClick = function ()
		self.chooseGroup:SetActive(false)
		self:setBuildingPartner()

		self.slotIndex = nil
	end

	UIEventListener.Get(self.closeBlank2).onClick = function ()
		self.chooseGroup:SetActive(false)
		self:setBuildingPartner()

		self.slotIndex = nil
	end
end

function ExploreBaseBuildingWindow:setBuildingPartner()
	local partnerID = 0

	if self.slotHeroList[self.slotIndex] then
		partnerID = self.slotHeroList[self.slotIndex]
	end

	if partnerID ~= self.data.partners[self.slotIndex] then
		exploreModel:setBuildingPartner(self.buildingType, self.slotIndex, partnerID)
	end
end

function ExploreBaseBuildingWindow:onHeroAddClick(index)
	if self.slotIndex then
		self:setBuildingPartner()

		if self.slotIndex == index and self.chooseGroup.activeSelf then
			self.chooseGroup:SetActive(false)

			self.slotIndex = nil

			return
		end
	end

	self.slotIndex = index
	self.selectedItem = nil
	self.selectedItemInfo = nil

	self.chooseGroup:SetLocalPosition(0, -1090, 0)
	self.chooseGroup:SetActive(true)

	local sequence = self:getSequence()

	sequence:Append(self.chooseGroup.transform:DOLocalMoveY(-197, 0.5))
	sequence:AppendCallback(function ()
		sequence:Kill(true)
	end)
	self:initPartnerList()
end

function ExploreBaseBuildingWindow:initPartnerList()
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

function ExploreBaseBuildingWindow:onSelectGroup(group)
	self.selectGroup = group
	self.selectedItem = nil
	self.selectedItemInfo = nil

	self:iniPartnerData(self.selectGroup)
end

function ExploreBaseBuildingWindow:iniPartnerData(group)
	local list = self:getPartnerList(group)

	if xyd.GuideController.get():isPlayGuide() then
		list[1].dragScrollView = nil
	end

	self.partnerList = list

	self.partnerMultiWrap_:setInfos(list, {})
end

function ExploreBaseBuildingWindow:getPartnerList(group)
	local partnerList = xyd.models.slot:getSortedPartners()[tostring(xyd.partnerSortType.STAR) .. "_" .. tostring(group)]
	local exceptedList = {}
	local buildingsInfo = exploreModel:getBuildsInfo()
	self.data = exploreModel:getBuildsInfo()[self.buildingType]
	local curPartnerId = self.slotHeroList[self.slotIndex] or 0
	local list = {}

	local function getPartnerInfo(partnerID)
		local partner = xyd.models.slot:getPartner(partnerID)
		local partnerInfo = {
			noClickSelected = true,
			isSelected = false,
			partnerID = partner:getPartnerID(),
			tableID = partner:getTableID(),
			lev = partner:getLevel(),
			star = partner:getStar(),
			skin_id = partner.skin_id,
			is_vowed = partner.is_vowed,
			dragScrollView = self.partnerScrollView
		}

		return partnerInfo
	end

	for i = 1, 3 do
		local partners = buildingsInfo[i].partners

		for sIndex, partnerId in ipairs(partners) do
			if partnerId ~= 0 and partnerId ~= curPartnerId then
				exceptedList[partnerId] = 1
				local partnerInfo = getPartnerInfo(partnerId)
				partnerInfo.buildingType = i
				partnerInfo.slotIndex = sIndex

				if not xyd.GuideController.get():isPlayGuide() and group == 0 then
					table.insert(list, partnerInfo)
				end
			end
		end
	end

	if curPartnerId > 0 then
		exceptedList[curPartnerId] = 1
		local cPartnerInfo = getPartnerInfo(curPartnerId)
		cPartnerInfo.isSelected = true

		table.insert(list, cPartnerInfo)
	end

	for _, partnerId in ipairs(partnerList) do
		if exceptedList[partnerId] ~= 1 then
			local partnerInfo = getPartnerInfo(partnerId)
			partnerInfo.isSelected = false

			table.insert(list, partnerInfo)
		end
	end

	return list
end

function ExploreBaseBuildingWindow:offSlot(formationItem)
	local partnerInfo = formationItem:getInfo()
	local buildingType = partnerInfo.buildingType
	local slotIndex = partnerInfo.slotIndex

	if buildingType == self.buildingType then
		NGUITools.DestroyChildren(self.groupHero[slotIndex].icon_root.transform)

		self.slotHeroList[slotIndex] = nil
		self.slotHeroIconList[slotIndex] = nil
	end

	exploreModel:setBuildingPartner(buildingType, slotIndex, 0)
end

function ExploreBaseBuildingWindow:setSelectHero(formationItem)
	if not self.selectedItem then
		self.selectedItem = formationItem
		self.selectedItemInfo = formationItem:getInfo()
	end
end

function ExploreBaseBuildingWindow:selectHero(item, isSame)
	if isSame then
		NGUITools.DestroyChildren(self.groupHero[self.slotIndex].icon_root.transform)

		self.selectedItem = nil
		self.selectedItemInfo = nil
		self.slotHeroList[self.slotIndex] = nil
		self.slotHeroIconList[self.slotIndex] = nil

		item:setChoose(false)
	else
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
		local info = item:getInfo()

		item:setChoose(true)

		self.selectedItemInfo = info
		local index = self.slotIndex

		function info.callback()
			self:onHeroAddClick(index)
		end

		info.scale = 0.9
		self.slotHeroList[self.slotIndex] = info.partnerID
		local heroIcon = self.slotHeroIconList[self.slotIndex]

		if not heroIcon then
			heroIcon = HeroIcon.new(self.groupHero[self.slotIndex].icon_root)
			self.slotHeroIconList[self.slotIndex] = heroIcon
		end

		heroIcon:setInfo(info)
	end

	self:updateOutAndStayFactor()
end

local FORMATION_ICON_NAME = {
	"explore_icon_1",
	"explore_icon_2",
	"explore_icon_3"
}

function FormationItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.heroIcon = HeroIcon.new(self.go)
	self.onImage = self.go:ComponentByName("on_image", typeof(UISprite))
	self.info = nil
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
		xyd.alertYesNo(__("TRAVEL_NEW_TEXT18"), function (yes)
			if yes then
				self.parent:offSlot(self)

				self.info.callback = callback1
				self.info.buildingType = nil
				self.info.slotIndex = nil

				self:setOtherSelect(false)
				self.heroIcon:setInfo(self.info)
			end
		end)
	end

	self.info.callback = callback1

	if self.info.buildingType and self.info.buildingType > 0 then
		self.info.callback = callback2
	end

	self.info.noClickSelected = true

	self.heroIcon:setInfo(self.info)
	self:setChoose(self.isSelected)

	if self.isSelected then
		self.parent:setSelectHero(self)
	end

	if self.info.buildingType and self.info.buildingType > 0 then
		self:setOtherSelect(true)
	end
end

function FormationItem:setOtherSelect(status)
	if status then
		xyd.setUISpriteAsync(self.onImage, nil, FORMATION_ICON_NAME[self.info.buildingType or 1])
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
	self.info.buildingType = nil
	self.info.slotIndex = nil
end

return ExploreBaseBuildingWindow
