local ChooseEquipWindow = import(".ChooseEquipWindow")
local ActivityEntranceTestSoulWindow = class("ActivityEntranceTestSoulWindow", ChooseEquipWindow)

function ActivityEntranceTestSoulWindow:ctor(name, params)
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	self.rank = self.activityData:getLevel()

	ChooseEquipWindow.ctor(self, name, params)
end

function ActivityEntranceTestSoulWindow:getUIComponent()
	ActivityEntranceTestSoulWindow.super.getUIComponent(self)

	self.windowTipsLabel_ = self.window_:ComponentByName("content/main_container/labelTips", typeof(UILabel))
	self.windowTipsLabel_.text = __("ENTRANCE_TEST_ARTIFACT_CHOOSE_TIPS")
end

function ActivityEntranceTestSoulWindow:initWindow()
	ActivityEntranceTestSoulWindow.super.initWindow(self)

	self.labelTitle.text = __("CHOOSE_ARTIFACT")
end

function ActivityEntranceTestSoulWindow:sortEquips()
	self.equips = {}
	self.itemHas = {}

	for key, id in pairs(xyd.tables.activityWarmupArenaEquipTable:getIdsByType(xyd.WarmupItemType.SOUL)) do
		local item = nil
		local itemId = xyd.tables.activityWarmupArenaEquipTable:getEquipId(id)
		local itemLev = xyd.tables.activityEntranceTestRankTable:getArtifactLev(self.rank)
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

			self.activityData.dataHasChange = true
			local win = xyd.WindowManager.get():getWindow("activity_entrance_test_partner_window")

			self.activityData:setPartnerTime(self.equipedPartner)
			win:updateData()
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
