local ActivityContent = import(".ActivityContent")
local ActivityEquipLevelAntique = class("ActivityEquipLevelAntique", ActivityContent)
local CommonTabBar = import("app.common.ui.CommonTabBar")
local LevupItem = class("LevupItem")
local json = require("cjson")
local antiqueTable = xyd.tables.acitiviyEquipLevelAntiqueTable

function ActivityEquipLevelAntique:ctor(parentGO, params, parent)
	ActivityEquipLevelAntique.super.ctor(self, parentGO, params, parent)
end

function ActivityEquipLevelAntique:getPrefabPath()
	return "Prefabs/Windows/activity/activity_equip_level_antique"
end

function ActivityEquipLevelAntique:initUI()
	self:getUIComponent()
	ActivityEquipLevelAntique.super.initUI(self)
	self:layout()
end

function ActivityEquipLevelAntique:resizeToParent()
	ActivityEquipLevelAntique.super.resizeToParent(self)
end

function ActivityEquipLevelAntique:getUIComponent()
	local go = self.go
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.textLogo = go:ComponentByName("textLogo", typeof(UISprite))
	self.timeGroup = self.textLogo:ComponentByName("timeGroup", typeof(UILayout))
	self.labelTime = self.timeGroup:ComponentByName("labelTime", typeof(UILabel))
	self.labelEnd = self.timeGroup:ComponentByName("labelEnd", typeof(UILabel))
	self.countLabel = go:ComponentByName("resGroup/countLabel", typeof(UILabel))
	self.addBtn = go:NodeByName("resGroup/addBtn").gameObject
	local groupBottom = go:NodeByName("groupBottom").gameObject
	self.nav = groupBottom:NodeByName("nav").gameObject
	self.content1 = groupBottom:NodeByName("content1").gameObject

	for i = 1, 3 do
		self["levup_item_node_" .. i] = self.content1:NodeByName("levup_item_" .. i).gameObject
	end

	self.content2 = groupBottom:NodeByName("content2").gameObject
	self.decoItemRoot = self.content2:NodeByName("decoItem/itemRoot").gameObject

	for i = 1, 3 do
		local item = self.content2:NodeByName("item_" .. i).gameObject
		self["reverseItem_" .. i] = item
		self["reverseImgIcon_" .. i] = item:ComponentByName("imgIcon", typeof(UISprite))
		self["reverseLabelNum_" .. i] = item:ComponentByName("labelNum_", typeof(UILabel))
	end

	self.btnReturn = self.content2:NodeByName("btnReturn").gameObject
	self.btnReturnLabel = self.btnReturn:ComponentByName("label", typeof(UILabel))
	self.labelPreview = self.content2:ComponentByName("labelPreview", typeof(UILabel))
end

function ActivityEquipLevelAntique:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "activity_equip_level_antique_" .. xyd.Global.lang)

	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.labelEnd:SetActive(false)
		self.labelTime:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.labelTime)

		timeCount:setInfo({
			duration = duration
		})

		self.labelEnd.text = __("END")

		if xyd.Global.lang == "fr_fr" then
			self.labelEnd.transform:SetSiblingIndex(0)
			self.labelTime.transform:SetSiblingIndex(1)
		end
	end

	if xyd.Global.lang == "de_de" then
		self.labelEnd.fontSize = 22
		self.labelTime.fontSize = 22
		self.timeGroup.gap = Vector2(14, 0)
	end

	self.timeGroup:Reposition()
	self:initContent1()
	self:initContent2()

	self.tabBar = CommonTabBar.new(self.nav, 2, function (index)
		self:changeToggle(index)
	end, nil, {
		chosen = {
			color = Color.New2(4294967295.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	}, 10)

	self.tabBar:setTexts({
		__("ACTIVITY_ANTIQUE_LEVELUP_TEXT01"),
		__("ACTIVITY_ANTIQUE_LEVELUP_TEXT02")
	})
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_ANTIQUE_LEVELUP_HELP"
		})
	end

	UIEventListener.Get(self.addBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("artifact_decompose_window")
	end
end

function ActivityEquipLevelAntique:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_ANTIQUE then
		return
	end

	local detail = json.decode(event.data.detail)

	if detail.is_rollback ~= 1 then
		local type = antiqueTable:getType(detail.award_id)
		local award = antiqueTable:getAward(detail.award_id)

		self.levupItemList[type]:setMainAntique(0)

		for i = 1, 3 do
			if i ~= type then
				self.levupItemList[i]:setMainAntique(self.levupItemList[i].itemID_1)
			end
		end

		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			wnd_type = 2,
			data = {
				{
					item_id = award[1],
					item_num = award[2]
				}
			},
			callback = function ()
				if next(detail.return_item) then
					xyd.alertItems({
						detail.return_item
					})
				end
			end
		})
	else
		self:setReturn(0)

		local reverse = antiqueTable:getReverse(detail.award_id)
		local items = {}

		for _, data in ipairs(reverse) do
			table.insert(items, {
				item_id = data[1],
				item_num = data[2]
			})
		end

		xyd.alertItems(items)

		for i = 1, 3 do
			self.levupItemList[i]:setMainAntique(0)
		end
	end
end

function ActivityEquipLevelAntique:onItemChange(event)
	local data = event.data.items

	for i = 1, #data do
		local item = data[i]

		if item.item_id == xyd.ItemID.ACTIVITY_EQUIP_LEVEL_ANTIQUE_COST then
			self.countLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_EQUIP_LEVEL_ANTIQUE_COST)

			for j = 1, 3 do
				self.levupItemList[j]:setLabelCostColor()
			end
		end
	end
end

function ActivityEquipLevelAntique:changeToggle(index)
	xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

	if index == 1 then
		self.content1:SetActive(true)
		self.content2:SetActive(false)
	else
		self.content1:SetActive(false)
		self.content2:SetActive(true)
	end
end

function ActivityEquipLevelAntique:initContent1()
	self.levupItemList = {}

	for i = 1, 3 do
		local item = LevupItem.new(self["levup_item_node_" .. i], self, i)

		table.insert(self.levupItemList, item)
	end

	self.countLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_EQUIP_LEVEL_ANTIQUE_COST)
end

function ActivityEquipLevelAntique:initContent2()
	self.btnReturnLabel.text = __("ACTIVITY_ANTIQUE_LEVELUP_TEXT02")
	self.labelPreview.text = __("ACTIVITY_ANTIQUE_LEVELUP_TEXT14")
	self.returnItemID = 0
	self.returnIndex = 0
	self.reverseItemsList = {}
	local list = {}
	local ids = antiqueTable:getIDs()

	for _, id in ipairs(ids) do
		local award = antiqueTable:getAward(id)
		local timeStamp = antiqueTable:getIsShow(id)

		if not timeStamp or timeStamp <= 0 or xyd.getServerTime() >= timeStamp then
			table.insert(list, award[1])
		end
	end

	UIEventListener.Get(self.decoItemRoot).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_antique_choose_window", {
			type = 4,
			antiques = list,
			now_antique = self.returnItemID,
			callback = function (itemID)
				self:setReturn(itemID)
			end
		})
	end

	for i = 1, 3 do
		UIEventListener.Get(self["reverseItem_" .. i]).onClick = function ()
			if self.reverseItemsList[i] then
				xyd.WindowManager.get():openWindow("item_tips_window", {
					show_has_num = true,
					itemID = self.reverseItemsList[i][1],
					itemNum = self.reverseItemsList[i][2],
					wndType = xyd.ItemTipsWndType.NORMAL
				})
			end
		end
	end

	UIEventListener.Get(self.btnReturn).onClick = function ()
		if self.returnItemID == 0 then
			xyd.showToast(__("ACTIVITY_ANTIQUE_LEVELUP_TEXT07"))
		else
			xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_ANTIQUE_LEVELUP_TEXT08"), function (yes)
				if yes then
					local params = json.encode({
						is_rollback = 1,
						award_id = tonumber(self.returnIndex)
					})

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_ANTIQUE, params)
				end
			end)
		end
	end
end

function ActivityEquipLevelAntique:setReturn(itemID)
	self.returnItemID = itemID

	if itemID ~= 0 then
		if not self.returnItem then
			self.returnItem = xyd.getItemIcon({
				num = 1,
				uiRoot = self.decoItemRoot,
				itemID = itemID
			})

			self.returnItem:setNoClick(true)
		else
			self.returnItem:setInfo({
				num = 1,
				itemID = itemID
			})
			self.returnItem:SetActive(true)
		end

		local ids = antiqueTable:getIDs()

		for _, id in ipairs(ids) do
			local award = antiqueTable:getAward(id)

			if award[1] == self.returnItemID then
				self.returnIndex = id
				self.reverseItemsList = antiqueTable:getReverse(id)

				break
			end
		end

		for i = 1, 3 do
			xyd.setUISpriteAsync(self["reverseImgIcon_" .. i], nil, xyd.tables.itemTable:getIcon(self.reverseItemsList[i][1]))

			self["reverseLabelNum_" .. i].text = self.reverseItemsList[i][2]
		end
	else
		if self.returnItem then
			self.returnItem:SetActive(false)
		end

		self.reverseItemsList = {}
		self.returnIndex = 0

		for i = 1, 3 do
			self["reverseImgIcon_" .. i].atlas = nil
			self["reverseLabelNum_" .. i].text = ""
		end
	end
end

function LevupItem:ctor(go, parent, type)
	self.go = go
	self.parent = parent
	self.type = type
	self.item_1 = go:NodeByName("item_1").gameObject
	self.imgIcon = self.item_1:ComponentByName("imgIcon", typeof(UISprite))
	self.addImg_1 = self.item_1:NodeByName("add").gameObject
	self.labelNum_1 = self.item_1:ComponentByName("labelNum_", typeof(UILabel))

	for i = 2, 3 do
		local item = go:NodeByName("item_" .. i).gameObject
		self["item_" .. i] = item
		self["imgBorder_" .. i] = item:ComponentByName("imgBorder_", typeof(UISprite))
		self["addImg_" .. i] = item:NodeByName("add").gameObject
		self["imgIcon_" .. i] = item:ComponentByName("imgIcon", typeof(UISprite))
		self["groupStars_" .. i] = item:NodeByName("groupStars_").gameObject
		self["labelNum_" .. i] = item:ComponentByName("labelNum_", typeof(UILabel))

		for j = 1, 6 do
			self["star_" .. i .. "_" .. j] = self["groupStars_" .. i]:NodeByName("star" .. j).gameObject
		end
	end

	self.labelCost = go:ComponentByName("groupCost/labelCost", typeof(UILabel))
	self.btnLevup = go:NodeByName("btnLevup").gameObject
	self.btnLevupLabel = self.btnLevup:ComponentByName("labelLevup", typeof(UILabel))

	self:initUI()
end

function LevupItem:initUI()
	self.awardIndex = 0
	self.itemID_1 = 0
	self.itemID_2 = 0
	self.itemID_3 = 0

	self.groupStars_2:SetActive(false)
	self.groupStars_3:SetActive(false)
	xyd.setUISpriteAsync(self.imgIcon, nil, "activity_equip_level_antique_none", function ()
		self.imgIcon:SetLocalScale(1.2857142857142858, 1.2409638554216869, 1)
	end, nil, true)

	local ids = antiqueTable:getIDsByType(self.type)
	self.cost = antiqueTable:getCost3(ids[1])
	self.labelCost.text = self.cost[2]
	self.btnLevupLabel.text = __("ACTIVITY_ANTIQUE_LEVELUP_TEXT01")

	self:setLabelCostColor()

	UIEventListener.Get(self.item_1).onClick = handler(self, self.selectMainAntique)
	UIEventListener.Get(self.item_2).onClick = handler(self, self.selectMainCost)
	UIEventListener.Get(self.item_3).onClick = handler(self, self.selectOtherCost)
	UIEventListener.Get(self.btnLevup).onClick = handler(self, self.levupClick)
end

function LevupItem:setMainAntique(itemID)
	self.itemID_1 = itemID

	if itemID ~= 0 then
		self.addImg_1:SetActive(false)

		self.labelNum_1.text = "1"
		local source = xyd.tables.itemTable:getIcon(itemID)

		xyd.setUISpriteAsync(self.imgIcon, nil, source, nil, , true)

		local ids = antiqueTable:getIDsByType(self.type)

		for _, id in ipairs(ids) do
			local award = antiqueTable:getAward(id)

			if award[1] == self.itemID_1 then
				self.awardIndex = id

				break
			end
		end

		local cost = antiqueTable:getCost1(self.awardIndex)
		local itemID_2 = cost[1]
		local source2 = xyd.tables.itemTable:getIcon(itemID_2)
		local qlt = xyd.tables.itemTable:getQuality(itemID_2)

		xyd.setUISpriteAsync(self.imgIcon_2, nil, source2)
		xyd.setUISpriteAsync(self.imgBorder_2, nil, "quality_" .. qlt)
		self.groupStars_2:SetActive(true)

		local starNum = xyd.tables.equipTable:getStar(itemID_2)

		for i = 1, 6 do
			self["star_2_" .. i]:SetActive(i > 6 - starNum)
		end

		if xyd.models.backpack:getItemNumByID(itemID_2) > 0 then
			self:setMainCost(itemID_2)
		else
			self:setMainCost(0)
		end

		xyd.setUISpriteAsync(self.imgBorder_3, nil, "quality_6")
		xyd.setUISpriteAsync(self.imgIcon_3, nil, source2)
		self.groupStars_3:SetActive(false)

		local costs = antiqueTable:getCost2(self.awardIndex)
		local flag = false

		for _, data in ipairs(costs) do
			if data[1] ~= itemID_2 and xyd.models.backpack:getItemNumByID(data[1]) > 0 or data[1] == itemID_2 and xyd.models.backpack:getItemNumByID(data[1]) > 1 then
				self:setOtherCost(data[1])

				flag = true

				break
			end
		end

		if not flag then
			self:setOtherCost(0)
		end
	else
		self.awardIndex = 0
		self.labelNum_1.text = ""

		self.addImg_1:SetActive(true)
		xyd.setUISpriteAsync(self.imgIcon, nil, "activity_equip_level_antique_none", function ()
			self.imgIcon:SetLocalScale(1.2857142857142858, 1.2409638554216869, 1)
		end, nil, true)

		self.itemID_2 = 0

		xyd.setUISpriteAsync(self.imgBorder_2, nil, "partner_artifact")

		self.imgIcon_2.atlas = nil

		self.groupStars_2:SetActive(false)
		self.addImg_2:SetActive(true)

		self.labelNum_2.text = ""
		self.labelNum_3.text = ""
		self.itemID_3 = 0

		self.addImg_3:SetActive(true)
		xyd.setUISpriteAsync(self.imgBorder_3, nil, "partner_artifact")

		self.imgIcon_3.atlas = nil

		self.groupStars_3:SetActive(false)
	end
end

function LevupItem:setMainCost(itemID)
	self.itemID_2 = itemID

	self.addImg_2:SetActive(itemID == 0)

	if itemID > 0 then
		xyd.applyOrigin(self.imgIcon_2)
		xyd.applyOrigin(self.imgBorder_2)
		xyd.applyChildrenOrigin(self.groupStars_2)

		self.labelNum_2.text = "1"
	else
		xyd.applyGrey(self.imgIcon_2)
		xyd.applyGrey(self.imgBorder_2)
		xyd.applyChildrenGrey(self.groupStars_2)

		self.labelNum_2.text = ""
	end
end

function LevupItem:setOtherCost(itemID)
	self.itemID_3 = itemID

	if itemID ~= 0 then
		xyd.applyOrigin(self.imgIcon_3)
		xyd.applyOrigin(self.imgBorder_3)
		self.addImg_3:SetActive(false)

		local starNum = xyd.tables.equipTable:getStar(self.itemID_3)

		for i = 1, 6 do
			self["star_3_" .. i]:SetActive(i > 6 - starNum)
		end

		self.groupStars_3:SetActive(true)

		self.labelNum_3.text = "1"
	else
		xyd.applyGrey(self.imgIcon_3)
		xyd.applyGrey(self.imgBorder_3)
		self.groupStars_3:SetActive(false)
		self.addImg_3:SetActive(true)

		self.labelNum_3.text = ""
	end
end

function LevupItem:setLabelCostColor()
	if xyd.models.backpack:getItemNumByID(self.cost[1]) < self.cost[2] then
		self.labelCost.color = Color.New2(3828429311.0)
	else
		self.labelCost.color = Color.New2(960513791)
	end
end

function LevupItem:selectMainAntique()
	local ids = antiqueTable:getIDsByType(self.type)
	local list = {}

	for _, id in ipairs(ids) do
		local award = antiqueTable:getAward(id)
		local timeStamp = antiqueTable:getIsShow(id)

		if not timeStamp or timeStamp <= 0 or xyd.getServerTime() >= timeStamp then
			table.insert(list, award[1])
		end
	end

	xyd.WindowManager.get():openWindow("activity_antique_choose_window", {
		type = 1,
		antiques = list,
		now_antique = self.itemID_1,
		callback = function (itemID)
			self:setMainAntique(itemID)
		end
	})
end

function LevupItem:selectMainCost()
	if self.itemID_1 == 0 then
		xyd.showToast(__("ACTIVITY_ANTIQUE_LEVELUP_TEXT04"))
	else
		local list = {}
		local cost = antiqueTable:getCost1(self.awardIndex)

		table.insert(list, cost[1])
		xyd.WindowManager.get():openWindow("activity_antique_choose_window", {
			type = 2,
			antiques = list,
			now_antique = self.itemID_2,
			callback = function (itemID)
				self:setMainCost(itemID)
			end,
			cost_item = self.itemID_3
		})
	end
end

function LevupItem:selectOtherCost()
	if self.itemID_1 == 0 then
		xyd.showToast(__("ACTIVITY_ANTIQUE_LEVELUP_TEXT04"))
	else
		local list = {}
		local cost = antiqueTable:getCost2(self.awardIndex)

		for _, data in ipairs(cost) do
			table.insert(list, data[1])
		end

		xyd.WindowManager.get():openWindow("activity_antique_choose_window", {
			type = 3,
			antiques = list,
			now_antique = self.itemID_3,
			callback = function (itemID)
				self:setOtherCost(itemID)
			end,
			cost_item = self.itemID_2
		})
	end
end

function LevupItem:levupClick()
	if self.itemID_1 == 0 then
		xyd.showToast(__("ACTIVITY_ANTIQUE_LEVELUP_TEXT04"))
	elseif self.itemID_2 == 0 or self.itemID_3 == 0 then
		xyd.showToast(__("ACTIVITY_ANTIQUE_LEVELUP_TEXT05"))
	elseif not xyd.isItemAbsence(self.cost[1], self.cost[2], true) then
		xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_ANTIQUE_LEVELUP_TEXT06"), function (yes)
			if yes then
				local params = json.encode({
					is_rollback = 0,
					award_id = tonumber(self.awardIndex),
					selected_costs = {
						{
							item_num = 1,
							item_id = self.itemID_3
						}
					}
				})

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_ANTIQUE, params)
			end
		end)
	end
end

return ActivityEquipLevelAntique
