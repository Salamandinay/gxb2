local AdventureLevelUpWindow = class("AdventureLevelUpWindow", import(".BaseWindow"))
local advenTable = xyd.tables.exploreAdventureTable
local adventureMaxLevel = 10

function AdventureLevelUpWindow:ctor(name, params)
	AdventureLevelUpWindow.super.ctor(self, name, params)
end

function AdventureLevelUpWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function AdventureLevelUpWindow:getUIComponent()
	local groupMain = self.window_:NodeByName("groupMain").gameObject
	self.clostBtn = groupMain:NodeByName("closeBtn").gameObject
	self.labelTitle = groupMain:ComponentByName("labelTitle", typeof(UILabel))
	self.btnLevelUp = groupMain:NodeByName("btnLevelUp").gameObject
	self.iconMax = self.btnLevelUp:NodeByName("iconMax").gameObject
	self.labelBtnLevelUp = self.btnLevelUp:ComponentByName("labelLevelUp", typeof(UILabel))

	for i = 1, 2 do
		local groupLabel = groupMain:NodeByName("groupLabel" .. i).gameObject
		self["labelLevel" .. i] = groupLabel:ComponentByName("labelLevel", typeof(UILabel))
		local labelItemList = {}

		for j = 1, 3 do
			labelItemList[j] = {}
			local labelItem = groupLabel:NodeByName("labelItem" .. j).gameObject
			labelItemList[j].labelName = labelItem:ComponentByName("labelName", typeof(UILabel))
			labelItemList[j].labelNum = labelItem:ComponentByName("labelNum", typeof(UILabel))
		end

		self["labelItemList" .. i] = labelItemList
		local boxLabelItemList = {}

		for j = 1, 4 do
			boxLabelItemList[j] = {}
			local boxLabelItem = groupLabel:NodeByName("boxLabelItem" .. j).gameObject
			boxLabelItemList[j].labelName = boxLabelItem:ComponentByName("labelName", typeof(UILabel))
			boxLabelItemList[j].labelNum = boxLabelItem:ComponentByName("labelNum", typeof(UILabel))
		end

		self["boxLabelItemList" .. i] = boxLabelItemList
	end

	self.groupLabel3 = groupMain:NodeByName("groupLabel3").gameObject
	self.groupLabelLimit = {}

	for i = 1, 3 do
		self.groupLabelLimit[i] = {}
		local labelItem = self.groupLabel3:NodeByName("labelItem" .. i).gameObject
		self.groupLabelLimit[i].labelName = labelItem:ComponentByName("labelName", typeof(UILabel))
		self.groupLabelLimit[i].labelNum = labelItem:ComponentByName("labelNum", typeof(UILabel))
	end
end

function AdventureLevelUpWindow:layout()
	self.labelTitle.text = __("TRAVEL_BUILDING_NAME5")
	self.labelBtnLevelUp.text = __("TRAVEL_MAIN_TEXT10")

	if xyd.Global.lang == "ja_jp" then
		self:languageAdjust1(-100, 100)
		self:languageAdjust2(-200, 200)
	elseif xyd.Global.lang == "en_en" then
		self:languageAdjust1(-110, 110)
		self:languageAdjust2(-250, 250)
	elseif xyd.Global.lang == "fr_fr" then
		self:languageAdjust1(-110, 110)
		self:languageAdjust2(-265, 265)
	elseif xyd.Global.lang == "ko_kr" then
		self:languageAdjust1(-102, 102)
		self:languageAdjust2(-200, 200)
	elseif xyd.Global.lang == "de_de" then
		self:languageAdjust2(-230, 230)
	end

	self:updateContent()
end

function AdventureLevelUpWindow:languageAdjust1(x1, x2)
	for i = 1, 2 do
		local boxLabelItemList = self["boxLabelItemList" .. i]

		for j = 1, 4 do
			local boxLabelItem = boxLabelItemList[j]

			boxLabelItem.labelName:X(x1)
			boxLabelItem.labelNum:X(x2)
		end
	end
end

function AdventureLevelUpWindow:languageAdjust2(x1, x2)
	for i = 1, 3 do
		self.groupLabelLimit[i].labelName:X(x1)
		self.groupLabelLimit[i].labelNum:X(x2)
	end
end

function AdventureLevelUpWindow:updateContent()
	local info = xyd.models.exploreModel:getExploreInfo()
	local curLv = info.lv

	if curLv < adventureMaxLevel then
		for i = 1, 2 do
			local lv = curLv + i - 1
			self["labelLevel" .. i].text = __("TRAVEL_MAIN_TEXT13", lv)
			local labelItemList = self["labelItemList" .. i]
			labelItemList[1].labelName.text = __("TRAVEL_MAIN_TEXT22")
			labelItemList[1].labelNum.text = advenTable:getSlotNum(lv)
			labelItemList[2].labelName.text = __("TRAVEL_MAIN_TEXT23")
			labelItemList[2].labelNum.text = advenTable:getEnemyLv(lv)
			labelItemList[3].labelName.text = __("TRAVEL_MAIN_TEXT35")
			local rewardBoxRate = advenTable:getRewardBoxRate(lv)

			for j = 1, 4 do
				local boxLabelItem = self["boxLabelItemList" .. i][j]

				if j <= #rewardBoxRate then
					local data = rewardBoxRate[j]
					boxLabelItem.labelName.text = __("TRAVEL_MAIN_TEXT24", data[1])
					boxLabelItem.labelNum.text = data[2] .. "%"
				else
					boxLabelItem.labelName.text = ""
					boxLabelItem.labelNum.text = ""
				end
			end
		end

		local limit = advenTable:getLevelUpLimit(curLv)
		local usedChests = info.used_chests
		local flag = true

		for j = 1, 3 do
			if j <= #limit then
				local data = limit[j]
				self.groupLabelLimit[j].labelName.text = __("TRAVEL_MAIN_TEXT36", data[1], data[2])
				local usedNum = usedChests[data[1]] or 0

				if usedNum < data[2] then
					flag = false
					self.groupLabelLimit[j].labelNum.text = "[c][ed4d58]" .. usedNum .. "[-][/c]/" .. data[2]
				else
					self.groupLabelLimit[j].labelNum.text = usedNum .. "/" .. data[2]
				end
			else
				self.groupLabelLimit[j].labelName.text = ""
				self.groupLabelLimit[j].labelNum.text = ""
			end
		end

		self.iconMax:SetActive(false)
		self.labelBtnLevelUp:SetActive(true)

		if flag then
			xyd.applyOrigin(self.btnLevelUp:GetComponent(typeof(UISprite)))
			xyd.setTouchEnable(self.btnLevelUp, true)
		else
			xyd.applyGrey(self.btnLevelUp:GetComponent(typeof(UISprite)))
			xyd.setTouchEnable(self.btnLevelUp, false)
		end
	else
		self.labelLevel1.text = __("TRAVEL_MAIN_TEXT13", curLv)
		self.labelItemList1[1].labelName.text = __("TRAVEL_MAIN_TEXT22")
		self.labelItemList1[1].labelNum.text = advenTable:getSlotNum(curLv)
		self.labelItemList1[2].labelName.text = __("TRAVEL_MAIN_TEXT23")
		self.labelItemList1[2].labelNum.text = advenTable:getEnemyLv(curLv)
		self.labelItemList1[3].labelName.text = __("TRAVEL_MAIN_TEXT35")
		local rewardBoxRate = advenTable:getRewardBoxRate(curLv)

		for j = 1, 4 do
			local boxLabelItem = self.boxLabelItemList1[j]

			if j <= #rewardBoxRate then
				local data = rewardBoxRate[j]
				boxLabelItem.labelName.text = __("TRAVEL_MAIN_TEXT24", data[1])
				boxLabelItem.labelNum.text = data[2] .. "%"
			else
				boxLabelItem.labelName.text = ""
				boxLabelItem.labelNum.text = ""
			end
		end

		self.labelLevel2.text = __("TRAVEL_MAIN_TEXT44")
		self.labelLevel2.color = Color.New2(4160023551.0)
		self.labelItemList2[1].labelName.text = "-- -- --"
		self.labelItemList2[1].labelNum.text = "--"
		self.labelItemList2[2].labelName.text = "-- -- --"
		self.labelItemList2[2].labelNum.text = "--"
		self.labelItemList2[3].labelName.text = "-- -- --"

		for i = 1, 3 do
			self.labelItemList2[i].labelName.color = Color.New2(2795939583.0)
			self.labelItemList2[i].labelNum.color = Color.New2(2795939583.0)
		end

		for j = 1, 3 do
			self.groupLabelLimit[j].labelName.text = ""
			self.groupLabelLimit[j].labelNum.text = ""
		end

		self.iconMax:SetActive(true)
		self.labelBtnLevelUp:SetActive(false)
		xyd.applyGrey(self.btnLevelUp:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnLevelUp, false)
	end
end

function AdventureLevelUpWindow:registerEvent()
	UIEventListener.Get(self.clostBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnLevelUp).onClick = function ()
		xyd.models.exploreModel:reqAdventureLevelUp()
	end

	self.eventProxy_:addEventListener(xyd.event.EXPLORE_ADVENTURE_UPGRADE, handler(self, self.updateContent))
end

return AdventureLevelUpWindow
