local ChooseEquipWindow = import(".ChooseEquipWindow")
local ActivityEntranceTestSoulWindow = class("ActivityEntranceTestSoulWindow", ChooseEquipWindow)

function ActivityEntranceTestSoulWindow:ctor(name, params)
	self.windowType = params.windowType or xyd.TestCrystalOrSoulWindowType.ENTRANCE_TEST

	if self.windowType == xyd.TestCrystalOrSoulWindowType.ENTRANCE_TEST then
		self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
		self.rank = self.activityData:getLevel()
	end

	ChooseEquipWindow.ctor(self, name, params)
end

function ActivityEntranceTestSoulWindow:getUIComponent()
	ActivityEntranceTestSoulWindow.super.getUIComponent(self)

	self.windowTipsLabel_ = self.window_:ComponentByName("content/main_container/labelTips", typeof(UILabel))

	if self.windowType == xyd.TestCrystalOrSoulWindowType.ENTRANCE_TEST then
		self.windowTipsLabel_.text = __("ENTRANCE_TEST_ARTIFACT_CHOOSE_TIPS")
	elseif self.windowType == xyd.TestCrystalOrSoulWindowType.GUILD_COMPETITION_SPECIAL then
		self.windowTipsLabel_.text = __("GUILD_COMPETITION_PARTNER_TEXT04")
	end
end

function ActivityEntranceTestSoulWindow:initWindow()
	ActivityEntranceTestSoulWindow.super.initWindow(self)

	self.labelTitle.text = __("CHOOSE_ARTIFACT")
end

function ActivityEntranceTestSoulWindow:sortEquips()
	self.equips = {}
	self.itemHas = {}

	if self.windowType == xyd.TestCrystalOrSoulWindowType.ENTRANCE_TEST then
		for key, id in pairs(xyd.tables.activityWarmupArenaEquipTable:getIdsByType(xyd.WarmupItemType.SOUL)) do
			local item = nil
			local itemId = xyd.tables.activityWarmupArenaEquipTable:getEquipId(id)
			local itemID = itemId
			local rank = xyd.tables.activityWarmupArenaEquipTable:getRank(id)
			item = {
				itemID = itemID,
				rank = rank
			}

			if tonumber(self.equipedPartner.equipments[6]) == tonumber(itemId) then
				item.partner_id = self.equipedPartner.partnerID
			end

			if not self.itemHas[itemID] then
				table.insert(self.equips, item)

				self.itemHas[itemID] = true
			end
		end
	elseif self.windowType == xyd.TestCrystalOrSoulWindowType.GUILD_COMPETITION_SPECIAL then
		local artifactList = xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.SOUL)

		for i, id in pairs(artifactList) do
			local item_id = xyd.tables.collectionTable:getItemId(id)
			local rank = xyd.tables.collectionTable:getRank(id)
			local hasGot = xyd.models.collection:isGot(xyd.tables.itemTable:getCollectionId(item_id))
			local lev1 = xyd.tables.equipTable:getItemLev(item_id)

			if lev1 == 36 then
				local pinkItemID = xyd.tables.equipTable:getSoulByIdAndLev(item_id, 39)
				local hasGotPink = xyd.models.collection:isGot(xyd.tables.itemTable:getCollectionId(pinkItemID))

				if hasGotPink and xyd.tables.equipTable:getItemLev(pinkItemID) == 39 then
					lev1 = 39
					rank = xyd.tables.collectionTable:getRank(pinkItemID)
				end

				local itemID = xyd.tables.equipTable:getSoulByIdAndLev(item_id, lev1)
				local item = {
					itemID = itemID,
					rank = rank
				}

				if tonumber(self.equipedPartner.equipments[6]) == tonumber(itemID) then
					item.partner_id = self.equipedPartner.partnerID
				end

				if not self.itemHas[itemID] then
					table.insert(self.equips, item)

					self.itemHas[itemID] = true
				end
			end
		end
	end

	table.sort(self.equips, function (a, b)
		local aLev = xyd.tables.equipTable:getItemLev(a.itemID)
		local bLev = xyd.tables.equipTable:getItemLev(b.itemID)

		if aLev < bLev then
			return false
		elseif aLev == bLev and a.itemID <= b.itemID then
			return false
		end

		return true
	end)
end

function ActivityEntranceTestSoulWindow:onclickIcon(itemID, partner_id)
	if self.now_equip and self.now_equip > 0 then
		local params = {
			btnLayout = 0,
			equipedOn = self.equipedOn,
			equipedPartner = self.equipedPartner,
			itemID = self.now_equip
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	local params = {
		btnLayout = 1,
		itemID = itemID,
		midColor = xyd.ButtonBgColorType.blue_btn_65_65,
		midCallback = function ()
			self.equipedPartner.equipments[6] = itemID

			xyd.WindowManager.get():closeWindow(self.name_)

			if self.windowType == xyd.TestCrystalOrSoulWindowType.ENTRANCE_TEST then
				self.activityData.dataHasChange = true
				local win = xyd.WindowManager.get():getWindow("activity_entrance_test_partner_window")

				self.activityData:setPartnerTime(self.equipedPartner)
				win:updateData()
			elseif self.windowType == xyd.TestCrystalOrSoulWindowType.GUILD_COMPETITION_SPECIAL then
				local win = xyd.WindowManager.get():getWindow("guild_competition_special_partner_window")

				win:updateData()
			end

			xyd.WindowManager.get():closeWindow("item_tips_window")
		end,
		midLabel = self.equipedOn and __("REPLACE") or __("EQUIP_ON")
	}
	local itemTipsWindow = xyd.WindowManager.get():getWindow("item_tips_window")

	if itemTipsWindow == nil then
		xyd.WindowManager.get():openWindow("item_tips_window", params)
	else
		itemTipsWindow:addTips(params)
	end
end

return ActivityEntranceTestSoulWindow
