local ActivityEquipLevelUp = class("ActivityEquipLevelUp", import(".ActivityContent"))
local ActivityEquipLevelUpItem = class("ActivityEquipLevelUpItem", import("app.components.BaseComponent"))
local CommonTabBar = import("app.common.ui.CommonTabBar")
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local GambleRewardsWindow = import("app.windows.GambleRewardsWindow")
local ActivityEquipLevelUpTable = xyd.tables.activityEquipLevelUpTable

function ActivityEquipLevelUp:ctor(parentGo, params, parent)
	ActivityEquipLevelUp.super.ctor(self, parentGo, params, parent)

	self.chosenGroup = 0
	self.chosenStar = 0
	self.selectedSuit = 0
end

function ActivityEquipLevelUp:getPrefabPath()
	return "Prefabs/Windows/activity/activity_equip_level_up"
end

function ActivityEquipLevelUp:getUIComponent()
	local groupMain = self.go:NodeByName("groupMain").gameObject
	self.textImg = groupMain:ComponentByName("textImg", typeof(UISprite))
	self.promptGroup = groupMain:NodeByName("e:Group").gameObject
	self.leftTime = self.promptGroup:ComponentByName("e:Group/leftTime", typeof(UILabel))
	self.endLabel = self.promptGroup:ComponentByName("e:Group/endLabel", typeof(UILabel))
	self.descLabel = self.promptGroup:ComponentByName("e:Group/descLabel", typeof(UILabel))
	self.shopBtn = groupMain:NodeByName("shopBtn").gameObject
	self.helpBtn = groupMain:NodeByName("helpBtn").gameObject
	local bottom = groupMain:NodeByName("bot").gameObject
	self.resCountLabel = bottom:ComponentByName("resGroup/countLabel", typeof(UILabel))
	self.resAddBtn = bottom:NodeByName("resGroup/addBtn").gameObject
	self.nav = bottom:NodeByName("nav").gameObject
	self.content_1 = bottom:NodeByName("content_1").gameObject
	self.scrollView = self.content_1:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = self.scrollView:ComponentByName("groupContent", typeof(UIGrid))
	self.content_2 = bottom:NodeByName("content_2").gameObject
	self.chooseBtn = self.content_2:NodeByName("chooseBtn").gameObject
	self.btnTitle = self.chooseBtn:ComponentByName("btnTitle", typeof(UILabel))
	self.selectPart = self.content_2:NodeByName("selectPart").gameObject
	self.labelDesc = self.content_2:ComponentByName("labelDesc", typeof(UILabel))
	local groupCost_ = self.content_2:NodeByName("groupCost_").gameObject
	self.btnCompose_ = groupCost_:NodeByName("btnCompose_").gameObject
	self.btnCompose_label = self.btnCompose_:ComponentByName("button_label", typeof(UILabel))
	self.labelLimit = groupCost_:ComponentByName("labelLimit", typeof(UILabel))
	self.labelNum = groupCost_:ComponentByName("labelNum", typeof(UILabel))
	self.itemCost = groupCost_:NodeByName("itemCost").gameObject
	self.groupItems = self.content_2:NodeByName("groupItems").gameObject
	self.labelCost = groupCost_:ComponentByName("labelCost", typeof(UILabel))
	self.content_3 = bottom:NodeByName("content_3").gameObject
	self.groupItems_exchange = self.content_3:NodeByName("groupItems").gameObject
	local groupCost_exchange = self.content_3:NodeByName("groupCost_").gameObject
	self.btnCompose_exchange = groupCost_exchange:NodeByName("btnCompose_").gameObject
	self.btnCompose_label_exchange = self.btnCompose_exchange:ComponentByName("button_label", typeof(UILabel))
	self.labelLimit_exchange = groupCost_exchange:ComponentByName("labelLimit", typeof(UILabel))
	self.labelNum_exchange = groupCost_exchange:ComponentByName("labelNum", typeof(UILabel))
	self.itemCost_exchange = groupCost_exchange:NodeByName("itemCost").gameObject
	self.labelCost_exchange = groupCost_exchange:ComponentByName("labelCost", typeof(UILabel))
	self.tabBar = CommonTabBar.new(self.nav, 3, function (index)
		self.tabIndex = index

		if index == 1 then
			self.content_1:SetActive(true)
			self.content_2:SetActive(false)
			self.content_3:SetActive(false)

			local win = xyd.WindowManager.get():getWindow("activity_equip_level_up_guide_window")

			if win then
				win:clearGuide()
			end
		elseif index == 2 then
			self.content_1:SetActive(false)
			self.content_2:SetActive(true)
			self.content_3:SetActive(false)

			if self:checkGuide() then
				self:specialGuide()
			end
		elseif index == 3 then
			self.content_1:SetActive(false)
			self.content_2:SetActive(false)
			self.content_3:SetActive(true)

			if self.selectedSuit_exchange_base and self.selectedSuit_exchange_base ~= 0 then
				self:updateBasetGroupOfExchange()
			end

			local win = xyd.WindowManager.get():getWindow("activity_equip_level_up_guide_window")

			if win then
				win:clearGuide()
			end
		end
	end, nil, , 12)
end

function ActivityEquipLevelUp:specialGuide()
	xyd.WindowManager.get():openWindow("activity_equip_level_up_guide_window", {
		positionList = {
			self.chooseBtn.transform.position,
			self.item1.transform.position,
			self.star1.transform.position
		}
	})
end

function ActivityEquipLevelUp:checkGuide()
	local res = xyd.db.misc:getValue("activity_equip_level_up_guide")

	if res and tonumber(res) == 1 then
		return false
	else
		return true
	end
end

function ActivityEquipLevelUp:initUI()
	ActivityEquipLevelUp.super.initUI(self)
	self:getUIComponent()
	self:initContent_1()
	self:initContent_2()
	self:initContent_3()
	self:resetPromptGroup()
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function ActivityEquipLevelUp:resetPromptGroup()
	self:waitForFrame(1, function ()
		local height = self.go:GetComponent(typeof(UIWidget)).height

		if height > 890 then
			self.promptGroup:Y((326 - height) / 2)
		end
	end)
end

function ActivityEquipLevelUp:initContent_1()
	xyd.setUISpriteAsync(self.textImg, nil, "equip_level_up_logo_" .. xyd.Global.lang, nil, , true)

	self.descLabel.text = __("ACTIVITY_EQUIP_LEVELUP_DESC")
	self.labelDesc.text = __("EQUIP_LEVELUP_TEXT_21")

	if xyd.Global.lang == "en_en" then
		self.descLabel.spacingY = 5
		self.descLabel.height = 125

		self.descLabel:Y(-15)

		self.labelCost.fontSize = 20
	end

	if xyd.Global.lang == "fr_fr" then
		self.descLabel.spacingY = 0
		self.descLabel.width = 300
		self.descLabel.height = 120

		self.descLabel:Y(-13.5)

		self.labelCost.fontSize = 20
	end

	if xyd.Global.lang == "ja_jp" then
		self.descLabel.spacingY = 10
		self.descLabel.height = 112

		self.descLabel:Y(-25)
	end

	if xyd.Global.lang == "de_de" then
		self.descLabel.spacingY = 0
		self.descLabel.width = 300
		self.descLabel.alignment = NGUIText.Alignment.Left

		self.descLabel:Y(-10)
		self.textImg:SetLocalScale(0.9, 0.9, 0.9)
		self.textImg:X(-150)
		self.textImg:Y(-40)

		self.labelDesc.fontSize = 22
		self.labelCost.fontSize = 20
	end

	if xyd.getServerTime() < self.activityData:getEndTime() then
		if xyd.Global.lang == "fr_fr" then
			self.leftTime.color = Color.New2(858690047)
			self.leftTime.effectColor = Color.New2(4294967295.0)
			self.endLabel.color = Color.New2(2986279167.0)
			self.endLabel.effectColor = Color.New2(959734783)
			self.leftTime.text = __("END")

			CountDown.new(self.endLabel, {
				duration = self.activityData:getEndTime() - xyd.getServerTime()
			})
			self.endLabel:X(-20)
		else
			self.endLabel.text = __("END")

			CountDown.new(self.leftTime, {
				duration = self.activityData:getEndTime() - xyd.getServerTime()
			})
		end
	else
		self.leftTime:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.EXCHANGE_EQUIP_SUIT, handler(self, self.onGetExchange))

	UIEventListener.Get(self.resAddBtn).onClick = function ()
		local params = {
			showGetWays = true,
			itemID = xyd.ItemID.METAL_BAERING,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.METAL_BAERING),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.shopBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_equip_level_up_award_window", {
			buy_times = self.activityData.detail.buy_times
		})
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "EQUIP_LEVELUP_HELP"
		})
	end

	self:updateRedMark()
	self:updateContent()
end

function ActivityEquipLevelUp:initContent_2()
	self.tabBar.tabs[1].label.text = __("EQUIP_LEVELUP_TEXT_1")
	self.tabBar.tabs[2].label.text = __("EQUIP_LEVELUP_TEXT_2")
	self.btnTitle.text = __("ALTAR_FILTER_TEXT")
	self.labelLimit.text = __("LIMIT_BUY", 1)
	self.resCountLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.METAL_BAERING)
	self.labelNum.text = ""
	self.btnCompose_label.text = __("LEV_UP")
	self.labelCost.text = __("EQUIP_LEVELUP_TEXT_13")
	self.itemCost_ = xyd.getItemIcon({
		show_has_num = true,
		uiRoot = self.itemCost,
		itemID = xyd.ItemID.STONE_FRAGMENT
	})

	self:initSelectPart()
	self.selectPart:SetActive(false)

	UIEventListener.Get(self.chooseBtn).onClick = function ()
		local win = xyd.WindowManager.get():getWindow("activity_equip_level_up_guide_window")

		if win and not self.itemchosen1.activeSelf then
			win:guide1()
		elseif win then
			win:guide2()
		end

		self.selectPart:SetActive(true)
	end

	UIEventListener.Get(self.btnCompose_).onClick = function ()
		if self.chosenGroup == 0 or self.chosenStar == 0 then
			xyd.showToast(__("EQUIP_LEVELUP_TEXT_3"))

			return
		elseif self.selectedSuit == 0 then
			xyd.showToast(__("EQUIP_LEVELUP_TEXT_7"))

			return
		end

		self:onLevelUp()
	end

	self:initItemPart()
end

function ActivityEquipLevelUp:initContent_3()
	self.tabBar.tabs[1].label.text = __("EQUIP_LEVELUP_TEXT_1")
	self.tabBar.tabs[2].label.text = __("EQUIP_LEVELUP_TEXT_2")
	self.tabBar.tabs[3].label.text = __("EQUIP_LEVELUP_TEXT_15")
	self.labelLimit_exchange.text = __("LIMIT_BUY", 1)
	self.resCountLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.METAL_BAERING)
	self.labelNum_exchange.text = ""
	self.btnCompose_label_exchange.text = __("EQUIP_LEVELUP_TEXT_15")
	self.labelCost_exchange.text = __("EQUIP_LEVELUP_TEXT_13")
	local cost = xyd.tables.miscTable:split2Cost("activity_equip_exchange_cost", "value", "|#")
	self.itemCost_exchange_ = xyd.getItemIcon({
		show_has_num = true,
		uiRoot = self.itemCost_exchange,
		itemID = cost[1][1]
	})

	UIEventListener.Get(self.btnCompose_exchange).onClick = function ()
		if self.selectedSuit_exchange_base == 0 or self.selectedSuit_exchange_base == nil then
			xyd.showToast(__("EQUIP_LEVELUP_TEXT_19"))

			return
		elseif self.selectedSuit_exchange_new == 0 or self.selectedSuit_exchange_new == nil then
			xyd.showToast(__("EQUIP_LEVELUP_TEXT_20"))

			return
		end

		self:onExchange()
	end

	self:initItemPartOfExchange()
end

function ActivityEquipLevelUp:onItemChange(event)
	local data = event.data.items
	local hasEquip = false
	local hasStone = false
	local hasMetal = false

	for i = 1, #data do
		local item = data[i]
		local type = xyd.tables.itemTable:getType(item.item_id)

		if type >= 6 and type <= 12 then
			hasEquip = true
		end

		if item.item_id == xyd.ItemID.STONE_FRAGMENT then
			hasStone = true
		end

		if item.item_id == xyd.ItemID.METAL_BAERING then
			hasMetal = true
		end
	end

	if hasMetal then
		self.resCountLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.METAL_BAERING)
	end

	if self.tabIndex == 1 then
		if hasEquip then
			for i = 1, #self.itemList do
				self.itemList[i]:updateIconNum()
			end
		end
	elseif self.tabIndex == 2 then
		if hasEquip then
			self:updateCostCotent()

			if self.baseItemList then
				for i = 1, #self.baseItemList do
					local hasNum = xyd.models.backpack:getItemNumByID(self.baseItemList[i]:getItemID())

					self:changeItemNum(self.baseItemList[i].labelNum_, hasNum, self.baseItemList[i].needNum)
				end
			end
		end

		if hasStone then
			self:changeStoneNum()
		end
	elseif self.tabIndex == 3 then
		self:updateCostGroupOfExchange()
	end
end

function ActivityEquipLevelUp:changeStoneNum()
	local costNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.STONE_FRAGMENT)

	if self.chosenGroup == 0 or self.chosenStar == 0 then
		self.labelNum.text = ""

		self.itemCost_.labelNum_:SetActive(false)
	else
		local group = self.chosenGroup .. "0" .. self.chosenStar
		local id = ActivityEquipLevelUpTable:getIdByGroup(group)
		local cost = ActivityEquipLevelUpTable:getCost(id)
		self.labelNum.text = costNum .. "/" .. cost[1][2]

		if costNum < tonumber(cost[1][2]) then
			self.labelNum.color = Color.New2(3422556671.0)
			self.labelNum.effectColor = Color.New2(4294967295.0)
		else
			self.labelNum.color = Color.New2(4294967295.0)
			self.labelNum.effectColor = Color.New2(1027558655)
		end

		self.itemCost_.labelNum_.text = cost[1][2]

		self.itemCost_.labelNum_:SetActive(true)
	end
end

function ActivityEquipLevelUp:confirmBuy()
	local group = self.chosenGroup .. "0" .. self.chosenStar
	local id = ActivityEquipLevelUpTable:getIdByGroup(group)
	local params = json.encode({
		award_id = tonumber(id),
		extra_id = tonumber(self.selectedSuit)
	})

	self.activityData:setChoose(tonumber(id))
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_UP, params)
end

function ActivityEquipLevelUp:onExchange()
	local cost = xyd.tables.miscTable:split2Cost("activity_equip_exchange_cost", "value", "|#")
	local costID = 1
	local costNum = 1
	local star = xyd.tables.equipTable:getStar(self.baseItemInfo_exchage[self.selectedSuit_exchange_base].equips_info[1].itemID)

	if star == 6 then
		costID = cost[1][1]
		costNum = cost[1][2]
	else
		costID = cost[star + 1][1]
		costNum = cost[star + 1][2]
	end

	local hasNum = xyd.models.backpack:getItemNumByID(costID)

	for i = 1, 4 do
		local itemID = self.baseItemInfo_exchage[self.selectedSuit_exchange_base].equips_info[i].itemID
		local hasNum = xyd.models.backpack:getItemNumByID(itemID)
		local needNum = 1

		if hasNum < needNum then
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(itemID)))

			return
		end
	end

	if hasNum < costNum then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(costID)))

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("EQUIP_LEVELUP_TEXT_16"), function (yes)
		if yes then
			self:confirmExchange()
		end
	end)
end

function ActivityEquipLevelUp:onLevelUp()
	local status = self:canLevelUp()

	if status == 0 then
		xyd.alert(xyd.AlertType.YES_NO, __("EQUIP_LEVELUP_TEXT_12"), function (yes)
			if yes then
				self:confirmBuy()
			end
		end)

		return
	end

	local tips = {
		"EQUIP_LEVELUP_TEXT_8",
		__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.STONE_FRAGMENT))
	}

	xyd.alert(xyd.AlertType.TIPS, __(tips[status]))
end

function ActivityEquipLevelUp:canLevelUp()
	local group = self.chosenGroup .. "0" .. self.chosenStar
	local id = ActivityEquipLevelUpTable:getIdByGroup(group)
	local before = ActivityEquipLevelUpTable:getEquipBefore(id)

	for i = 1, #before do
		local data = before[i]

		if xyd.models.backpack:getItemNumByID(data[1]) < 1 then
			return 1
		end
	end

	local suit = xyd.tables.activityEquipLevelUpSuitTable:getSuit(self.selectedSuit)
	local cost = 1

	if self.chosenStar == 1 and self.chosenGroup == tonumber(self.selectedSuit) then
		cost = 2
	end

	for i = 1, #suit do
		local data = suit[i]

		if xyd.models.backpack:getItemNumByID(data[1]) < cost then
			return 1
		end
	end

	local costData = ActivityEquipLevelUpTable:getCost(id)
	local hasNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.STONE_FRAGMENT)

	if hasNum < costData[1][2] then
		return 2
	end

	return 0
end

function ActivityEquipLevelUp:initSelectPart()
	local maskBg = self.selectPart:NodeByName("maskBg").gameObject
	local itemGroup = self.selectPart:NodeByName("gridOfGroup").gameObject
	local starGroup = self.selectPart:NodeByName("gridOfStar").gameObject
	local groupList = {}
	local starList = {}

	for i = 1, 5 do
		local item = itemGroup:NodeByName("itemGroup" .. i).gameObject
		local chosen = item:NodeByName("groupChosen").gameObject
		self["item" .. i] = item
		self["itemchosen" .. i] = chosen

		UIEventListener.Get(item).onClick = function ()
			local wnd = xyd.WindowManager.get():getWindow("activity_equip_level_up_guide_window")

			if wnd then
				wnd:guide2()
			end

			if self.chosenGroup == i then
				groupList[self.chosenGroup]:SetActive(false)

				self.chosenGroup = 0
			else
				if self.chosenGroup ~= 0 then
					groupList[self.chosenGroup]:SetActive(false)
				end

				self.chosenGroup = i

				groupList[self.chosenGroup]:SetActive(true)
			end

			self:updateBaseAndUpContent()

			if self.chosenStar == 1 then
				self:updateCostCotent()
			end
		end

		table.insert(groupList, chosen)
	end

	for j = 1, 3 do
		local star = starGroup:NodeByName("itemStar" .. j).gameObject
		local chosen = star:NodeByName("chosen").gameObject
		self["star" .. j] = star

		UIEventListener.Get(star).onClick = function ()
			local wnd = xyd.WindowManager.get():getWindow("activity_equip_level_up_guide_window")

			if wnd then
				wnd:guide3()
			end

			if self.chosenStar == j then
				starList[self.chosenStar]:SetActive(false)

				self.chosenStar = 0
			else
				if self.chosenStar ~= 0 then
					starList[self.chosenStar]:SetActive(false)
				end

				self.chosenStar = j

				starList[self.chosenStar]:SetActive(true)
			end

			if self.chosenStar == 1 and self.chosenGroup == self.selectedSuit then
				self:updateCostCotent()
			end

			self:updateBaseAndUpContent()
		end

		table.insert(starList, chosen)
	end

	UIEventListener.Get(maskBg).onClick = function ()
		local wnd = xyd.WindowManager.get():getWindow("activity_equip_level_up_guide_window")

		if wnd then
			wnd:clearGuide()
		end

		self.selectPart:SetActive(false)
	end
end

function ActivityEquipLevelUp:initItemPart()
	self.baseList = {}
	self.costList = {}
	self.upList = {}

	for i = 1, 4 do
		local item = self.groupItems:NodeByName("item" .. i).gameObject
		local base = item:NodeByName("base/itemIcon").gameObject
		local baseAdd = item:NodeByName("base/add").gameObject
		local cost = item:NodeByName("cost/itemIcon").gameObject
		local costAdd = item:NodeByName("cost/add").gameObject
		local up = item:NodeByName("up/itemIcon").gameObject
		local upAdd = item:NodeByName("up/add").gameObject
		local effectBase = xyd.Spine.new(baseAdd)

		effectBase:setInfo("jiahao", function ()
			effectBase:SetLocalScale(0.5, 0.5, 0.5)
			effectBase:SetLocalPosition(20, -20, 0)
			effectBase:play("texiao01", 0)
		end)

		local effectCost = xyd.Spine.new(costAdd)

		effectCost:setInfo("jiahao", function ()
			effectCost:SetLocalScale(0.5, 0.5, 0.5)
			effectCost:SetLocalPosition(20, -20, 0)
			effectCost:play("texiao01", 0)
		end)

		local effectUp = xyd.Spine.new(upAdd)

		effectUp:setInfo("jiahao", function ()
			effectUp:SetLocalScale(0.5, 0.5, 0.5)
			effectUp:SetLocalPosition(20, -20, 0)
			effectUp:play("texiao01", 0)
		end)

		UIEventListener.Get(base).onClick = handler(self, self.onBlankItemClick)
		UIEventListener.Get(cost).onClick = handler(self, self.onCostItemClick)
		UIEventListener.Get(up).onClick = handler(self, self.onBlankItemClick)

		table.insert(self.baseList, base)
		table.insert(self.costList, cost)
		table.insert(self.upList, up)
	end
end

function ActivityEquipLevelUp:initItemPartOfExchange()
	self.baseList_exchange = {}
	self.newList_exchange = {}

	for i = 1, 4 do
		local item = self.groupItems_exchange:NodeByName("item" .. i).gameObject
		local baseItem = item:NodeByName("baseItem/itemIcon").gameObject
		local baseItemAdd = item:NodeByName("baseItem/add").gameObject
		local newItem = item:NodeByName("newItem/itemIcon").gameObject
		local newItemAdd = item:NodeByName("newItem/add").gameObject
		local effectBase = xyd.Spine.new(baseItemAdd)

		effectBase:setInfo("jiahao", function ()
			effectBase:SetLocalScale(0.5, 0.5, 0.5)
			effectBase:SetLocalPosition(20, -20, 0)
			effectBase:play("texiao01", 0)
		end)

		self.base_equip_info = {}
		local baseData = {}
		local ids = xyd.tables.equipTable:getIDs()

		for key, value in pairs(ids) do
			local id = value

			if xyd.tables.equipTable:getJob(id) ~= nil and xyd.tables.equipTable:getJob(id) > 0 then
				table.insert(baseData, id)
			end
		end

		local function sort_func(a, b)
			if xyd.tables.equipTable:getStar(a) ~= xyd.tables.equipTable:getStar(b) then
				return xyd.tables.equipTable:getStar(a) < xyd.tables.equipTable:getStar(b)
			elseif xyd.tables.equipTable:getJob(a) ~= xyd.tables.equipTable:getJob(b) then
				return xyd.tables.equipTable:getJob(a) < xyd.tables.equipTable:getJob(b)
			else
				return xyd.tables.equipTable:getPos(a) < xyd.tables.equipTable:getPos(b)
			end
		end

		table.sort(baseData, sort_func)

		for i = 1, #baseData / 4 do
			self.base_equip_info[i] = {}

			table.insert(self.base_equip_info[i], baseData[4 * (i - 1) + 1])
			table.insert(self.base_equip_info[i], baseData[4 * (i - 1) + 2])
			table.insert(self.base_equip_info[i], baseData[4 * (i - 1) + 3])
			table.insert(self.base_equip_info[i], baseData[4 * (i - 1) + 4])
		end

		UIEventListener.Get(baseItem).onClick = handler(self, self.onBaseItemClick)
		UIEventListener.Get(newItem).onClick = handler(self, self.onNewtemClick)

		table.insert(self.baseList_exchange, baseItem)
		table.insert(self.newList_exchange, newItem)
	end
end

function ActivityEquipLevelUp:onBlankItemClick()
	xyd.showToast(__("EQUIP_LEVELUP_TEXT_3"))

	local win = xyd.WindowManager.get():getWindow("activity_equip_level_up_guide_window")

	if win and not self.itemchosen1.activeSelf then
		win:guide1()
	elseif win then
		win:guide2()
	end

	self.selectPart:SetActive(true)
end

function ActivityEquipLevelUp:onCostItemClick()
	if self.chosenStar == 0 or self.chosenGroup == 0 then
		xyd.showToast(__("EQUIP_LEVELUP_TEXT_3"))

		local win = xyd.WindowManager.get():getWindow("activity_equip_level_up_guide_window")

		if win and not self.itemchosen1.activeSelf then
			win:guide1()
		elseif win then
			win:guide2()
		end

		self.selectPart:SetActive(true)
	else
		xyd.WindowManager.get():openWindow("activity_equip_level_up_choose_window", {
			show_num = true,
			selectedSuit = self.selectedSuit,
			chosenGroup = self.chosenGroup,
			chosenStar = self.chosenStar,
			callback = function (id)
				local suit = xyd.tables.activityEquipLevelUpSuitTable:getSuit(id)

				if not self.suitList then
					self.suitList = {}

					for i = 1, 4 do
						local item = xyd.getItemIcon({
							uiRoot = self.costList[i]
						})

						table.insert(self.suitList, item)
					end
				end

				if self.selectedSuit ~= id then
					self.selectedSuit = id

					for i = 1, 4 do
						self.suitList[i]:setInfo({
							scale = 0.7,
							noClick = true,
							itemID = suit[i][1],
							num = suit[i][2]
						})

						local hasNum = xyd.models.backpack:getItemNumByID(suit[i][1])

						if self.chosenStar == 1 and self.chosenGroup == tonumber(self.selectedSuit) then
							hasNum = hasNum - 1 > 0 and hasNum - 1 or 0
						end

						self:changeItemNum(self.suitList[i].labelNum_, hasNum, suit[i][2])
					end
				end
			end
		})
	end
end

function ActivityEquipLevelUp:onBaseItemClick()
	xyd.WindowManager.get():openWindow("common_equip_suit_choose_window", {
		show_num = true,
		show_select_group = true,
		title_text = __("EQUIP_LEVELUP_TEXT_17"),
		selectedSuit = self.selectedSuit_exchange_base,
		items_info = self:getBaseItemInfo(),
		callback = function (info)
			local id = info.id

			if not self.baseItemList_exchange then
				self.baseItemList_exchange = {}

				for i = 1, 4 do
					local item = xyd.getItemIcon({
						noClick = false,
						uiRoot = self.baseList_exchange[i]
					})

					table.insert(self.baseItemList_exchange, item)
				end
			end

			if self.selectedSuit_exchange_base == nil or self.selectedSuit_exchange_base == 0 then
				self.ArrowSequence = self:getSequence()

				self.ArrowSequence:Append(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item1/arrow", typeof(UISprite)), 1, 1)):Join(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item2/arrow", typeof(UISprite)), 1, 1)):Join(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item3/arrow", typeof(UISprite)), 1, 1)):Join(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item4/arrow", typeof(UISprite)), 1, 1))
			end

			if self.WenHaoSequence == nil then
				self.WenHaoSequence = self:getSequence()

				self.WenHaoSequence:Append(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item1/newItem/add", typeof(UISprite)), 1, 1)):Join(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item2/newItem/add", typeof(UISprite)), 1, 1)):Join(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item3/newItem/add", typeof(UISprite)), 1, 1)):Join(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item4/newItem/add", typeof(UISprite)), 1, 1)):Append(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item1/newItem/add", typeof(UISprite)), 0, 1)):Join(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item2/newItem/add", typeof(UISprite)), 0, 1)):Join(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item3/newItem/add", typeof(UISprite)), 0, 1)):Join(xyd.getTweenAlpha(self.groupItems_exchange:ComponentByName("item4/newItem/add", typeof(UISprite)), 0, 1))
				self.WenHaoSequence:SetLoops(-1)
			end

			if self.selectedSuit_exchange_base ~= id then
				self.selectedSuit_exchange_base = id

				self:updateBasetGroupOfExchange()
			end

			self.selectedSuit_exchange_new = nil

			for i = 1, 4 do
				NGUITools.DestroyChildren(self.newList_exchange[i].transform)
			end

			self:updateCostGroupOfExchange()
		end
	})
end

function ActivityEquipLevelUp:onNewtemClick()
	if self.selectedSuit_exchange_base == 0 or self.selectedSuit_exchange_base == nil then
		return
	end

	xyd.WindowManager.get():openWindow("common_equip_suit_choose_window", {
		show_num = false,
		show_select_group = false,
		title_text = __("EQUIP_LEVELUP_TEXT_18"),
		selectedSuit = self.selectedSuit_exchange_new,
		items_info = self:getNewItemInfo(),
		callback = function (info)
			local id = info.id

			if not self.newItemList_exchange or self.selectedSuit_exchange_new == nil or self.selectedSuit_exchange_new == 0 then
				self.newItemList_exchange = {}

				for i = 1, 4 do
					local item = xyd.getItemIcon({
						noClick = false,
						uiRoot = self.newList_exchange[i]
					})

					table.insert(self.newItemList_exchange, item)
				end
			end

			if self.selectedSuit_exchange_new ~= id then
				self.selectedSuit_exchange_new = id

				for i = 1, 4 do
					local itemID = info.equips_info[i].itemID

					self.newItemList_exchange[i]:setInfo({
						scale = 0.7,
						num = 1,
						noClick = true,
						itemID = itemID
					})
				end
			end
		end
	})
end

function ActivityEquipLevelUp:getBaseItemInfo()
	if self.baseItemInfo_exchage then
		return self.baseItemInfo_exchage
	end

	self.baseItemInfo_exchage = {}

	for i = 1, #self.base_equip_info do
		local tempdata = {
			id = i,
			equips_info = {}
		}

		for j = 1, 4 do
			local tempdata2 = {
				itemID = 0,
				needNum = 1,
				itemID = self.base_equip_info[i][j]
			}

			table.insert(tempdata.equips_info, tempdata2)
		end

		table.insert(self.baseItemInfo_exchage, tempdata)
	end

	return self.baseItemInfo_exchage
end

function ActivityEquipLevelUp:getNewItemInfo()
	if self.selectedSuit_exchange_base == nil or self.selectedSuit_exchange_base == 0 then
		return nil
	end

	self.newItemInfo_exchage = {}

	for i = 1, #self.baseItemInfo_exchage do
		if xyd.tables.equipTable:getStar(self.baseItemInfo_exchage[self.selectedSuit_exchange_base].equips_info[1].itemID) == xyd.tables.equipTable:getStar(self.baseItemInfo_exchage[i].equips_info[1].itemID) and self.selectedSuit_exchange_base ~= self.baseItemInfo_exchage[i].id then
			table.insert(self.newItemInfo_exchage, self.baseItemInfo_exchage[i])
		end
	end

	return self.newItemInfo_exchage
end

function ActivityEquipLevelUp:updateCostCotent()
	if self.selectedSuit ~= 0 then
		local suit = xyd.tables.activityEquipLevelUpSuitTable:getSuit(self.selectedSuit)

		for i = 1, 4 do
			local hasNum = xyd.models.backpack:getItemNumByID(suit[i][1])

			if self.chosenStar == 1 and self.chosenGroup == tonumber(self.selectedSuit) then
				hasNum = hasNum - 1 > 0 and hasNum - 1 or 0
			end

			self:changeItemNum(self.suitList[i].labelNum_, hasNum, suit[i][2])
		end
	end
end

function ActivityEquipLevelUp:changeItemNum(label, hasNum, needNum)
	label.text = hasNum .. "/" .. needNum

	if hasNum < needNum then
		label.color = Color.New2(3422556671.0)
		label.effectColor = Color.New2(4294967295.0)
	else
		label.color = Color.New2(4294967295.0)
		label.effectColor = Color.New2(1027558655)
	end
end

function ActivityEquipLevelUp:updateBaseAndUpContent()
	if self.chosenGroup == 0 or self.chosenStar == 0 then
		if self.baseItemList then
			for i = 1, 4 do
				NGUITools.DestroyChildren(self.baseList[i].transform)
				NGUITools.DestroyChildren(self.upList[i].transform)
				xyd.setTouchEnable(self.baseList[i], true)
				xyd.setTouchEnable(self.upList[i], true)
			end

			self.baseItemList = nil
			self.upItemList = nil
			self.labelNum.text = ""

			self.itemCost_.labelNum_:SetActive(false)
		end
	else
		local group = self.chosenGroup .. "0" .. self.chosenStar
		local id = ActivityEquipLevelUpTable:getIdByGroup(group)
		local cost = ActivityEquipLevelUpTable:getCost(id)
		local before = ActivityEquipLevelUpTable:getEquipBefore(id)
		local after = ActivityEquipLevelUpTable:getAwards(id)
		local costNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.STONE_FRAGMENT)
		self.labelNum.text = costNum .. "/" .. cost[1][2]

		if costNum < tonumber(cost[1][2]) then
			self.labelNum.color = Color.New2(3422556671.0)
			self.labelNum.effectColor = Color.New2(4294967295.0)
		else
			self.labelNum.color = Color.New2(960513791)
			self.labelNum.effectColor = Color.New2(4294967295.0)
		end

		self.itemCost_.labelNum_.text = cost[1][2]

		self.itemCost_.labelNum_:SetActive(true)

		if not self.baseItemList then
			self.baseItemList = {}
			self.upItemList = {}

			for i = 1, 4 do
				local itemBase = xyd.getItemIcon({
					uiRoot = self.baseList[i]
				})
				local itemUp = xyd.getItemIcon({
					uiRoot = self.upList[i]
				})

				table.insert(self.baseItemList, itemBase)
				table.insert(self.upItemList, itemUp)
				xyd.setTouchEnable(self.baseList[i], false)
				xyd.setTouchEnable(self.upList[i], false)
			end
		end

		for i = 1, 4 do
			self.baseItemList[i]:setInfo({
				scale = 0.7,
				itemID = before[i][1],
				num = before[i][2],
				levelUp = self.chosenStar
			})

			local hasNum = xyd.models.backpack:getItemNumByID(before[i][1])
			self.baseItemList[i].needNum = before[i][2]

			self:changeItemNum(self.baseItemList[i].labelNum_, hasNum, before[i][2])
			self.upItemList[i]:setInfo({
				scale = 0.7,
				itemID = after[i][1],
				num = after[i][2],
				levelUp = self.chosenStar
			})
		end
	end
end

function ActivityEquipLevelUp:updateRedMark()
	self:waitForTime(0.5, function ()
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_UP, function ()
			self.activityData.isShowRedMark = false
		end)
	end)
end

function ActivityEquipLevelUp:updateContent()
	self.itemList = {}
	local ids = ActivityEquipLevelUpTable:getListByType(1)
	local buyTimes = self.activityData.detail.buy_times
	self.idx = {}

	for i = 1, #ids do
		local id = ids[i]
		local limit = ActivityEquipLevelUpTable:getLimit(id)
		local leftTime = limit - buyTimes[tonumber(id)]

		table.insert(self.idx, {
			id = id,
			leftTime = leftTime
		})
	end

	local ids2 = ActivityEquipLevelUpTable:getListByType(2)
	local buyTimes2 = self.activityData.detail.buy_times2
	local limit = ActivityEquipLevelUpTable:getLimit(ids2[1])

	table.insert(self.idx, {
		id = ids2[1],
		leftTime = limit - buyTimes2
	})
	table.sort(self.idx, function (a, b)
		return a.leftTime == b.leftTime and a.id < b.id or b.leftTime < a.leftTime
	end)

	for i = 1, #self.idx do
		local id = self.idx[i].id
		local item = ActivityEquipLevelUpItem.new(self.groupContent.gameObject, {
			id = id,
			leftTime = self.idx[i].leftTime,
			parent = self
		})
		self.itemList[id] = item
	end
end

function ActivityEquipLevelUp:updateCostGroupOfExchange()
	if self.selectedSuit_exchange_base == nil or self.selectedSuit_exchange_base == 0 then
		self.labelNum_exchange:SetActive(false)

		return
	end

	local cost = xyd.tables.miscTable:split2Cost("activity_equip_exchange_cost", "value", "|#")
	local costID = 1
	local costNum = 1
	local star = xyd.tables.equipTable:getStar(self.baseItemInfo_exchage[self.selectedSuit_exchange_base].equips_info[1].itemID)

	if star == 6 then
		costID = cost[1][1]
		costNum = cost[1][2]
	else
		costID = cost[star + 1][1]
		costNum = cost[star + 1][2]
	end

	if self.selectedSuit_exchange_base ~= 0 and self.selectedSuit_exchange_base ~= nil then
		local hasNum = xyd.models.backpack:getItemNumByID(costID)
		self.labelNum_exchange.text = costNum .. "/" .. hasNum

		if hasNum < costNum then
			self.labelNum_exchange.color = Color.New2(3422556671.0)
			self.labelNum_exchange.effectColor = Color.New2(4294967295.0)
		else
			self.labelNum_exchange.color = Color.New2(960513791)
			self.labelNum_exchange.effectColor = Color.New2(4294967295.0)
		end

		self.labelNum_exchange:SetActive(true)
	else
		self.labelNum_exchange:SetActive(false)
	end
end

function ActivityEquipLevelUp:updateBasetGroupOfExchange()
	if self.selectedSuit_exchange_base == nil or self.selectedSuit_exchange_base == 0 then
		return
	end

	for i = 1, 4 do
		local itemID = self.baseItemInfo_exchage[self.selectedSuit_exchange_base].equips_info[i].itemID
		local hasNum = xyd.models.backpack:getItemNumByID(itemID)
		local needNum = 1

		self.baseItemList_exchange[i]:setInfo({
			scale = 0.7,
			noClick = true,
			itemID = itemID,
			num = xyd.models.backpack:getItemNumByID(itemID)
		})

		if hasNum < needNum then
			self.baseItemList_exchange[i].labelNum_.color = Color.New2(3422556671.0)
			self.baseItemList_exchange[i].labelNum_.effectStyle = UILabel.Effect.Outline
			self.baseItemList_exchange[i].labelNum_.effectColor = Color.New2(4294967295.0)
		else
			self.baseItemList_exchange[i].labelNum_.color = Color.New2(4294967295.0)
			self.baseItemList_exchange[i].labelNum_.effectStyle = UILabel.Effect.Outline
			self.baseItemList_exchange[i].labelNum_.effectColor = Color.New2(1027558655)
		end

		self.baseItemList_exchange[i].labelNum_.text = hasNum .. "/" .. needNum
	end
end

function ActivityEquipLevelUp:updateItem()
	NGUITools.DestroyChildren(self.groupContent.gameObject.transform)
	self:updateContent()
	self.groupContent:Reposition()
end

function ActivityEquipLevelUp:confirmExchange()
	local from_job = xyd.tables.equipTable:getJob(self.baseItemInfo_exchage[self.selectedSuit_exchange_base].equips_info[1].itemID)
	local to_job = xyd.tables.equipTable:getJob(self.baseItemInfo_exchage[self.selectedSuit_exchange_new].equips_info[1].itemID)
	local star = xyd.tables.equipTable:getStar(self.baseItemInfo_exchage[self.selectedSuit_exchange_base].equips_info[1].itemID)
	local msg = messages_pb:exchange_equip_suit_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_UP
	msg.from_job = from_job
	msg.to_job = to_job
	msg.star = star

	xyd.Backend.get():request(xyd.mid.EXCHANGE_EQUIP_SUIT, msg)
end

function ActivityEquipLevelUp:onGetExchange(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.result == "OK" then
		local tempItems = {}

		for i = 1, 4 do
			local isCool = 0

			table.insert(tempItems, {
				item_num = 1,
				item_id = self.baseItemInfo_exchage[self.selectedSuit_exchange_new].equips_info[i].itemID,
				cool = isCool
			})
		end

		local params = {
			data = tempItems,
			wnd_type = GambleRewardsWindow.WindowType.NORMAL
		}

		xyd.WindowManager.get():openWindow("gamble_rewards_window", params)

		for i = 1, 4 do
			local itemID = self.baseItemInfo_exchage[self.selectedSuit_exchange_base].equips_info[i].itemID

			self.baseItemList_exchange[i]:setInfo({
				scale = 0.7,
				noClick = true,
				itemID = itemID,
				num = xyd.models.backpack:getItemNumByID(itemID)
			})

			local hasNum = xyd.models.backpack:getItemNumByID(itemID)
			local costNum = 1
			self.baseItemList_exchange[i].labelNum_.text = hasNum .. "/" .. costNum

			if hasNum < costNum then
				self.baseItemList_exchange[i].labelNum_.color = Color.New2(3422556671.0)
				self.baseItemList_exchange[i].labelNum_.effectColor = Color.New2(4294967295.0)
			else
				self.baseItemList_exchange[i].labelNum_.color = Color.New2(960513791)
				self.baseItemList_exchange[i].labelNum_.effectColor = Color.New2(4294967295.0)
			end
		end

		self:updateCostGroupOfExchange()
	end
end

function ActivityEquipLevelUp:onAward(event)
	while #self.activityData.choose_queue > 0 do
		local id = table.remove(self.activityData.choose_queue, 1)
		local type_ = ActivityEquipLevelUpTable:getType(id)

		if type_ == 1 then
			self.itemList[tostring(id)]:startLevelUpEff(function ()
				self:onCompeleteAnime(tostring(id))
			end)
		elseif type_ == 2 then
			self.itemList[tostring(id)]:startLevelUpEff(function ()
				self:onCompeleteAnime(tostring(self.activityData.selectSuit))
			end)
		else
			self:onCompeleteAnime(tostring(id))
		end
	end
end

function ActivityEquipLevelUp:onCompeleteAnime(id)
	local afterData = ActivityEquipLevelUpTable:getAwards(id)
	local tempItems = {}

	for _, item in ipairs(afterData) do
		local isCool = 0

		table.insert(tempItems, {
			item_id = item[1],
			item_num = item[2],
			cool = isCool
		})
	end

	local params = {
		data = tempItems,
		wnd_type = GambleRewardsWindow.WindowType.NORMAL
	}

	xyd.WindowManager.get():openWindow("gamble_rewards_window", params)

	local type_ = ActivityEquipLevelUpTable:getType(id)

	if type_ == 1 or type_ == 2 then
		self:updateItem()
	end
end

function ActivityEquipLevelUpItem:ctor(parentGo, params)
	self.parent = params.parent
	self.id = params.id
	self.type = ActivityEquipLevelUpTable:getType(self.id)
	self.leftTime = tonumber(params.leftTime)
	self.selectedSuit = 0

	ActivityEquipLevelUpItem.super.ctor(self, parentGo)
end

function ActivityEquipLevelUpItem:getPrefabPath()
	return "Prefabs/Windows/activity/activity_equip_level_up_item"
end

function ActivityEquipLevelUpItem:initUI()
	ActivityEquipLevelUpItem.super.initUI(self)
	self:getUIComponent()

	local beforeData = ActivityEquipLevelUpTable:getEquipBefore(self.id)
	self.iconList = {}

	for i = 1, #beforeData do
		local data = beforeData[i]
		local before = self.groupItems:NodeByName("item" .. i .. "/before").gameObject
		local icon = xyd.getItemIcon({
			scale = 0.7,
			uiRoot = before,
			itemID = data[1],
			num = data[2]
		})
		local hasNum = xyd.models.backpack:getItemNumByID(data[1])
		icon.labelNum_.text = hasNum .. "/" .. data[2]

		if hasNum < data[2] then
			icon.labelNum_.color = Color.New2(3422556671.0)
			icon.labelNum_.effectStyle = UILabel.Effect.Outline
			icon.labelNum_.effectColor = Color.New2(4294967295.0)
		else
			icon.labelNum_.color = Color.New2(4294967295.0)
		end

		table.insert(self.iconList, icon)
		icon:setDragScrollView(self.parent.scrollView)
	end

	local afterData = ActivityEquipLevelUpTable:getAwards(self.id)
	self.afterList = {}

	for i = 1, #afterData do
		local after = self.groupItems:NodeByName("item" .. i .. "/after/itemIcon").gameObject

		if self.type ~= 2 then
			local data = afterData[i]
			local icon = xyd.getItemIcon({
				scale = 0.7,
				uiRoot = after,
				itemID = data[1],
				num = data[2]
			})

			xyd.setTouchEnable(after, false)
			icon:setDragScrollView(self.parent.scrollView)
		else
			local add = self.groupItems:NodeByName("item" .. i .. "/after/add").gameObject
			local effect = xyd.Spine.new(add)

			effect:setInfo("jiahao", function ()
				effect:SetLocalScale(0.5, 0.5, 0.5)
				effect:SetLocalPosition(20, -20, 0)
				effect:play("texiao01", 0)
			end)

			local dragScrollView = after:AddComponent(typeof(UIDragScrollView))
			dragScrollView.scrollView = self.parent.scrollView
			UIEventListener.Get(after).onClick = handler(self, self.onSuitChooseClick)
		end

		table.insert(self.afterList, after)
	end

	local costData = ActivityEquipLevelUpTable:getCost(self.id)

	for i = 1, #costData do
		local data = costData[i]
		self["labelCost" .. i].text = xyd.getRoughDisplayNumber(data[2])
		self["labelCost" .. i].color = data[2] <= xyd.models.backpack:getItemNumByID(data[1]) and Color.New2(960513791) or Color.New2(3422556671.0)
	end

	self.labelLimit.text = __("LIMIT_BUY", self.leftTime)
	self.button_label.text = __("LEV_UP")

	if self.leftTime > 0 then
		UIEventListener.Get(self.btnCompose_).onClick = function ()
			if self.type == 2 and self.selectedSuit == 0 then
				xyd.showToast(__("EQUIP_LEVELUP_TEXT_4"))

				return
			end

			self:onLevelUp()
		end
	else
		xyd.applyGrey(self.btnCompose_:GetComponent(typeof(UISprite)))
		self.button_label:ApplyGrey()
		xyd.setTouchEnable(self.btnCompose_, false)
	end
end

function ActivityEquipLevelUpItem:getUIComponent()
	local go = self.go:NodeByName("e:Group").gameObject
	self.groupItems = go:NodeByName("groupItems").gameObject
	self.groupCost_ = go:NodeByName("groupCost_").gameObject
	self.groupEff = go:NodeByName("groupEff").gameObject
	self.btnCompose_ = self.groupCost_:NodeByName("btnCompose_").gameObject
	self.button_label = self.btnCompose_:ComponentByName("button_label", typeof(UILabel))
	self.labelCost1 = self.groupCost_:ComponentByName("groupCost1/labelCost1", typeof(UILabel))
	self.labelCost2 = self.groupCost_:ComponentByName("groupCost2/labelCost2", typeof(UILabel))
	self.labelLimit = self.groupCost_:ComponentByName("labelLimit", typeof(UILabel))
end

function ActivityEquipLevelUpItem:confirmBuy()
	local params = nil

	if self.type ~= 2 then
		params = json.encode({
			award_id = tonumber(self.id)
		})
	else
		params = json.encode({
			award_id = tonumber(self.selectedSuit + 2)
		})

		self.parent.activityData:setSelectSuit(tonumber(self.selectedSuit + 2))
	end

	self.parent.activityData:setChoose(tonumber(self.id))
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_UP, params)
end

function ActivityEquipLevelUpItem:onLevelUp()
	local status = self:canLevelUp()
	local costDatas = ActivityEquipLevelUpTable:getCost(self.id)

	if status == 0 then
		xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_EQUIP_LEVEL_UP_CONFIRM_BUY", xyd.getRoughDisplayNumber(costDatas[1][2]), xyd.getRoughDisplayNumber(costDatas[2][2])), function (yes)
			if yes then
				self:confirmBuy()
			end
		end)

		return
	end

	local tips = {
		"NOT_ENOUGH_EQUIP",
		"NOT_ENOUGH_MANA",
		"NOT_ENOUGH_CRYSTAL"
	}

	xyd.alert(xyd.AlertType.TIPS, __(tips[status]))
end

function ActivityEquipLevelUpItem:canLevelUp()
	local beforeData = ActivityEquipLevelUpTable:getEquipBefore(self.id)

	for i = 1, #beforeData do
		local data = beforeData[i]

		if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
			return 1
		end
	end

	local costData = ActivityEquipLevelUpTable:getCost(self.id)

	for i = 1, #costData do
		local data = costData[i]

		if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
			return i + 1
		end
	end

	return 0
end

function ActivityEquipLevelUpItem:startLevelUpEff(compeleteFunc)
	local effect = xyd.Spine.new(self.groupEff)

	effect:setInfo("fx_equip_up", function ()
		effect:SetLocalPosition(0, 131, 0)
		effect:play("texiao01", 1, 1, compeleteFunc)
	end)
end

function ActivityEquipLevelUpItem:onSuitChooseClick()
	xyd.WindowManager.get():openWindow("activity_equip_level_up_choose_window", {
		show_num = false,
		selectedSuit = self.selectedSuit,
		callback = function (id)
			local suit = xyd.tables.activityEquipLevelUpSuitTable:getSuit(id)

			if not self.suitList then
				self.suitList = {}

				for i = 1, 4 do
					local item = xyd.getItemIcon({
						uiRoot = self.afterList[i]
					})

					table.insert(self.suitList, item)
				end
			end

			if self.selectedSuit ~= id then
				for i = 1, 4 do
					self.suitList[i]:setInfo({
						scale = 0.7,
						noClick = true,
						itemID = suit[i][1],
						num = suit[i][2]
					})
				end

				self.selectedSuit = id
			end
		end
	})
end

function ActivityEquipLevelUpItem:updateIconNum()
	local beforeData = ActivityEquipLevelUpTable:getEquipBefore(self.id)

	for i = 1, #beforeData do
		local data = beforeData[i]
		local icon = self.iconList[i]
		local hasNum = xyd.models.backpack:getItemNumByID(data[1])
		icon.labelNum_.text = hasNum .. "/" .. data[2]

		if hasNum < data[2] then
			icon.labelNum_.color = Color.New2(3422556671.0)
			icon.labelNum_.effectStyle = UILabel.Effect.Outline
			icon.labelNum_.effectColor = Color.New2(4294967295.0)
		else
			icon.labelNum_.color = Color.New2(4294967295.0)
		end
	end
end

function ActivityEquipLevelUp:dispose()
	ActivityEquipLevelUp.super.dispose(self)
	xyd.WindowManager.get():closeWindow("activity_equip_level_up_guide_window")
end

return ActivityEquipLevelUp
