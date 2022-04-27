local AutoAdventureSetupWindow = class("AutoAdventureSetupWindow", import(".BaseWindow"))

function AutoAdventureSetupWindow:ctor(name, params)
	AutoAdventureSetupWindow.super.ctor(self, name, params)
end

function AutoAdventureSetupWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function AutoAdventureSetupWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.tipsBtn = groupAction:NodeByName("tipsBtn").gameObject
	self.setUpItemList = {}
	local group1 = groupAction:NodeByName("group1").gameObject
	self.labelEventDeal_1 = group1:ComponentByName("labelEventDeal", typeof(UILabel))

	for i = 1, 3 do
		local item = group1:NodeByName("settingItem_" .. i).gameObject
		local select = item:NodeByName("select").gameObject
		local labelSetting = item:ComponentByName("labelSetting", typeof(UILabel))

		table.insert(self.setUpItemList, {
			item = item,
			select = select,
			labelSetting = labelSetting
		})
	end

	self.spSetUpItemList = {}
	local group2 = groupAction:NodeByName("group2").gameObject
	self.labelEventDeal_2 = group2:ComponentByName("labelEventDeal", typeof(UILabel))

	for i = 1, 2 do
		local item = group2:NodeByName("settingItem_" .. i).gameObject
		local select = item:NodeByName("select").gameObject
		local labelSetting = item:ComponentByName("labelSetting", typeof(UILabel))

		table.insert(self.spSetUpItemList, {
			item = item,
			select = select,
			labelSetting = labelSetting
		})
	end
end

function AutoAdventureSetupWindow:layout()
	self.labelTitle.text = __("TRAVEL_NEW_TEXT02")
	self.labelEventDeal_1.text = __("TRAVEL_NEW_TEXT03")
	self.labelEventDeal_2.text = __("TRAVEL_NEW_TEXT07")
	self.setUpList = xyd.models.exploreModel:getSetUpList()
	local setUpLabel = {
		__("TRAVEL_NEW_TEXT04"),
		__("TRAVEL_NEW_TEXT05"),
		__("TRAVEL_NEW_TEXT06")
	}

	for i = 1, 3 do
		self.setUpItemList[i].labelSetting.text = setUpLabel[i]

		self.setUpItemList[i].select:SetActive(tonumber(self.setUpList[i]) == 1)
	end

	self.spSetUpList = xyd.models.exploreModel:getSpSetUpList()
	local spSetUpLabel = {
		__("TRAVEL_NEW_TEXT08"),
		__("TRAVEL_NEW_TEXT09")
	}

	for i = 1, 2 do
		self.spSetUpItemList[i].labelSetting.text = spSetUpLabel[i]

		self.spSetUpItemList[i].select:SetActive(tonumber(self.spSetUpList[i]) == 1)
	end
end

function AutoAdventureSetupWindow:registerEvent()
	UIEventListener.Get(self.tipsBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("explore_help_window", {
			key = "TRAVEL_NEW_TEXT14"
		})
	end

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	for i = 1, 3 do
		UIEventListener.Get(self.setUpItemList[i].item).onClick = function ()
			self.setUpList[i] = tonumber(self.setUpList[i]) == 1 and 0 or 1

			self.setUpItemList[i].select:SetActive(tonumber(self.setUpList[i]) == 1)
			xyd.models.exploreModel:setSetUpList()
		end
	end

	for i = 1, 2 do
		UIEventListener.Get(self.spSetUpItemList[i].item).onClick = function ()
			self.spSetUpList[i] = tonumber(self.spSetUpList[i]) == 1 and 0 or 1

			self.spSetUpItemList[i].select:SetActive(tonumber(self.spSetUpList[i]) == 1)
			xyd.models.exploreModel:setSpSetUpList()
		end
	end
end

return AutoAdventureSetupWindow
