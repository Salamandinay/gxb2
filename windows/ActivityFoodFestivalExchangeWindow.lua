local BaseWindow = import(".BaseWindow")
local ActivityFoodFestivalExchangeWindow = class("ActivityFoodFestivalExchangeWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")
local Backpack = xyd.models.backpack

function ActivityFoodFestivalExchangeWindow:ctor(name, params)
	if params == nil then
		params = nil
	end

	self.curNum_ = 0
	self.callback = params.callback
	self.awards = params.awards
	self.costs = params.costs
	self.limit = params.limit

	BaseWindow.ctor(self, name, params)
end

function ActivityFoodFestivalExchangeWindow:initUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.bg_ = groupAction:ComponentByName("bg_", typeof(UISprite))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	local mainGroup = groupAction:NodeByName("mainGroup").gameObject
	self.groupRes = mainGroup:NodeByName("groupRes").gameObject
	self.reslabel = self.groupRes:ComponentByName("reslabel", typeof(UILabel))
	self.groupResTwo = mainGroup:NodeByName("groupRes2").gameObject
	self.groupRes1 = self.groupResTwo:NodeByName("groupRes1").gameObject
	self.reslabel1 = self.groupRes1:ComponentByName("reslabel", typeof(UILabel))
	self.groupRes2 = self.groupResTwo:NodeByName("groupRes2").gameObject
	self.reslabel2 = self.groupRes2:ComponentByName("reslabel", typeof(UILabel))
	self.groupRewards = mainGroup:NodeByName("groupRewards").gameObject
	self.btnCompose_ = mainGroup:NodeByName("btnCompose_").gameObject
	local selectNum_ = mainGroup:NodeByName("selectNum_").gameObject
	self.selectNum = SelectNum.new(selectNum_, "minmax")
end

function ActivityFoodFestivalExchangeWindow:layout()
	self.labelTitle_.text = __("ACTIVITY_FOOD_FESTIVAL_EXHCANGE_WINDOW")
	self.btnCompose_:ComponentByName("button_label", typeof(UILabel)).text = __("CONFIRM")
end

function ActivityFoodFestivalExchangeWindow:initAward()
	NGUITools.DestroyChildren(self.groupRewards.transform)

	for i = 1, #self.awards do
		local data = self.awards[i]

		xyd.getItemIcon({
			uiRoot = self.groupRewards,
			itemID = data[1],
			num = data[2]
		})
	end

	self.groupRewards:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityFoodFestivalExchangeWindow:initResItem()
	if #self.costs == 1 then
		local data = self.costs[1]
		local sprite = xyd.tables.itemTable:getIcon(data[1])
		local uiSprite = self.groupRes:ComponentByName("resItem", typeof(UISprite))
		local hasNum = Backpack:getItemNumByID(data[1])

		xyd.setUISpriteAsync(uiSprite, nil, sprite, function ()
		end, false)

		self.curNum_ = math.floor(hasNum / data[2])

		if hasNum < data[2] * self.curNum_ then
			self.reslabel.text = "[c][cc0011]" .. hasNum .. "[-][/c]/" .. tostring(data[2] * self.curNum_)
		else
			self.reslabel.text = hasNum .. "/" .. tostring(data[2] * self.curNum_)
		end

		self.groupRes:Y(-39)
		self.groupRes:SetActive(true)
		self.groupResTwo:SetActive(false)

		self.bg_.height = 440

		self.btnCompose_:Y(-110)
	elseif #self.costs == 2 then
		for i = 1, 2 do
			local data = self.costs[i]
			local sprite = xyd.tables.itemTable:getIcon(data[1])
			local uiSprite = self["groupRes" .. i]:ComponentByName("resItem", typeof(UISprite))
			local hasNum = Backpack:getItemNumByID(data[1])

			xyd.setUISpriteAsync(uiSprite, nil, sprite, function ()
			end, false)

			self.curNum_ = math.floor(hasNum / data[2])

			if hasNum < data[2] * self.curNum_ then
				self["reslabel" .. i].text = "[c][cc0011]" .. hasNum .. "[-][/c]/" .. tostring(data[2] * self.curNum_)
			else
				self["reslabel" .. i].text = hasNum .. "/" .. tostring(data[2] * self.curNum_)
			end
		end

		self.groupRes:SetActive(false)
		self.groupResTwo:SetActive(true)

		self.bg_.height = 440

		self.btnCompose_:Y(-110)
	elseif #self.costs == 3 then
		local data = self.costs[1]
		local sprite = xyd.tables.itemTable:getIcon(data[1])
		local uiSprite = self.groupRes:ComponentByName("resItem", typeof(UISprite))
		local hasNum = Backpack:getItemNumByID(data[1])

		xyd.setUISpriteAsync(uiSprite, nil, sprite, function ()
		end, false)

		self.curNum_ = math.floor(hasNum / data[2])

		if hasNum < data[2] * self.curNum_ then
			self.reslabel.text = "[c][cc0011]" .. hasNum .. "[-][/c]/" .. tostring(data[2] * self.curNum_)
		else
			self.reslabel.text = hasNum .. "/" .. tostring(data[2] * self.curNum_)
		end

		for i = 1, 2 do
			local data = self.costs[i + 1]
			local sprite = xyd.tables.itemTable:getIcon(data[1])
			local uiSprite = self["groupRes" .. i]:ComponentByName("resItem", typeof(UISprite))
			local hasNum = Backpack:getItemNumByID(data[1])

			xyd.setUISpriteAsync(uiSprite, nil, sprite, function ()
			end, false)

			self.curNum_ = math.floor(hasNum / data[2])

			if hasNum < data[2] * self.curNum_ then
				self["reslabel" .. i].text = "[c][cc0011]" .. hasNum .. "[-][/c]/" .. tostring(data[2] * self.curNum_)
			else
				self["reslabel" .. i].text = hasNum .. "/" .. tostring(data[2] * self.curNum_)
			end
		end

		self.groupRes:Y(-91)
		self.groupRes:SetActive(true)
		self.groupResTwo:SetActive(true)

		self.bg_.height = 490

		self.btnCompose_:Y(-164)
	end
end

function ActivityFoodFestivalExchangeWindow:initSelectNum()
	local data = self.costs[1]
	local id = data[1]
	local hasNum = Backpack:getItemNumByID(id)
	local maxNum = math.floor(Backpack:getItemNumByID(self.costs[1][1]) / self.costs[1][2])

	for i = 1, #self.costs do
		local data = self.costs[i]
		maxNum = math.min(maxNum, math.floor(Backpack:getItemNumByID(data[1]) / data[2]))
	end

	if self.limit > 0 and self.limit < maxNum then
		maxNum = self.limit
	end

	local function callback(num)
		self.curNum_ = num

		self:updateResItem()
	end

	self.selectNum:setInfo({
		curNum = 1,
		maxNum = maxNum,
		callback = callback
	})
	self.selectNum:setKeyboardPos(0, -335)
end

function ActivityFoodFestivalExchangeWindow:register()
	BaseWindow.register(self)

	UIEventListener.Get(self.btnCompose_).onClick = handler(self, self.composeItem)
end

function ActivityFoodFestivalExchangeWindow:initWindow()
	BaseWindow.initWindow(self)
	self:initUIComponent()
	self:layout()
	self:initAward()
	self:initResItem()
	self:initSelectNum()
	self:register()
end

function ActivityFoodFestivalExchangeWindow:updateResItem()
	if #self.costs == 1 then
		local data = self.costs[1]
		local hasNum = Backpack:getItemNumByID(data[1])

		if hasNum < data[2] * self.curNum_ then
			self.reslabel.text = "[c][cc0011]" .. hasNum .. "[-][/c]/" .. tostring(data[2] * self.curNum_)
		else
			self.reslabel.text = hasNum .. "/" .. tostring(data[2] * self.curNum_)
		end
	elseif #self.costs == 2 then
		for i = 1, 2 do
			local data = self.costs[i]
			local hasNum = Backpack:getItemNumByID(data[1])

			if hasNum < data[2] * self.curNum_ then
				self["reslabel" .. i].text = "[c][cc0011]" .. hasNum .. "[-][/c]/" .. tostring(data[2] * self.curNum_)
			else
				self["reslabel" .. i].text = hasNum .. "/" .. tostring(data[2] * self.curNum_)
			end
		end
	elseif #self.costs == 3 then
		local data = self.costs[1]
		local hasNum = Backpack:getItemNumByID(data[1])

		if hasNum < data[2] * self.curNum_ then
			self.reslabel.text = "[c][cc0011]" .. hasNum .. "[-][/c]/" .. tostring(data[2] * self.curNum_)
		else
			self.reslabel.text = hasNum .. "/" .. tostring(data[2] * self.curNum_)
		end

		for i = 1, 2 do
			local data = self.costs[i + 1]
			local hasNum = Backpack:getItemNumByID(data[1])

			if hasNum < data[2] * self.curNum_ then
				self["reslabel" .. i].text = "[c][cc0011]" .. hasNum .. "[-][/c]/" .. tostring(data[2] * self.curNum_)
			else
				self["reslabel" .. i].text = hasNum .. "/" .. tostring(data[2] * self.curNum_)
			end
		end
	end
end

function ActivityFoodFestivalExchangeWindow:composeItem()
	if self.callback then
		self.callback(self.curNum_)
	end
end

return ActivityFoodFestivalExchangeWindow
