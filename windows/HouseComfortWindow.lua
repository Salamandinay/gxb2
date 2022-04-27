local HouseComfortWindow = class("HouseComfortWindow", import(".BaseWindow"))
local HouseAwardTable = xyd.tables.houseAwardTable
local MiscTable = xyd.tables.miscTable
local ItemTable = xyd.tables.itemTable

function HouseComfortWindow:ctor(name, params)
	HouseComfortWindow.super.ctor(self, name, params)

	self.canGetAward_ = true
	self.house = xyd.models.house
end

function HouseComfortWindow:initWindow()
	HouseComfortWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function HouseComfortWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelComfort_ = groupAction:ComponentByName("labelComfort_", typeof(UILabel))
	self.labelComfortNum_ = groupAction:ComponentByName("labelComfortNum_", typeof(UILabel))
	self.labelTips_ = groupAction:ComponentByName("labelTips_", typeof(UILabel))
	self.labelNum1 = groupAction:ComponentByName("mid/award1/labelNum1", typeof(UILabel))
	self.labelNum2 = groupAction:ComponentByName("mid/award2/labelNum2", typeof(UILabel))
	self.labelNum3 = groupAction:ComponentByName("mid/award3/labelNum3", typeof(UILabel))
	self.imgIcon1 = groupAction:ComponentByName("mid/award1/imgIcon1", typeof(UISprite))
	self.imgIcon2 = groupAction:ComponentByName("mid/award2/imgIcon2", typeof(UISprite))
	self.imgIcon3 = groupAction:ComponentByName("mid/award3/imgIcon3", typeof(UISprite))
	self.btnGet_ = groupAction:NodeByName("btnGet_").gameObject
end

function HouseComfortWindow:layout()
	self.btnGet_:ComponentByName("button_label", typeof(UILabel)).text = __("GET")
	self.labelComfort_.text = __("HOUSE_TEXT_24")
	self.labelTips_.text = __("HOUSE_TEXT_25")
	self.labelComfortNum_.text = tostring(self.house:getComfortNum())

	self:initAwards()

	self.timer_ = Timer.New(handler(self, self.initAwards), 5, -1)

	self.timer_:Start()
end

function HouseComfortWindow:willClose()
	HouseComfortWindow.super.willClose(self)

	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end
end

function HouseComfortWindow:registerEvent()
	UIEventListener.Get(self.btnGet_).onClick = handler(self, self.onGetTouch)

	self.eventProxy_:addEventListener(xyd.event.HOUSE_GET_AWARDS, handler(self, self.onGetAward))
end

function HouseComfortWindow:onGetTouch()
	if self.canGetAward_ then
		self.house:reqGetAwards()
	end
end

function HouseComfortWindow:onGetAward(event)
	xyd.itemFloat(event.data.hang_items, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end, self.window_)
	self:initAwards()
end

function HouseComfortWindow:initAwards()
	local comfortNum = self.house:getComfortNum()
	local id = HouseAwardTable:getIdByComfort(comfortNum)
	local pAwardItems = HouseAwardTable:award(id)
	local hangTime = self.house:getHangTime()
	local hangUpdateTime = self.house:getHangUpdateTime()

	if hangUpdateTime == 0 then
		hangUpdateTime = hangTime
	end

	local addRate = 0
	local maxHangTime = MiscTable:getNumber("hang_up_time_max", "value")

	if hangTime > 0 then
		local serverTime = xyd.getServerTime()
		local trueMaxHangTime = hangTime + maxHangTime

		if serverTime < trueMaxHangTime then
			trueMaxHangTime = serverTime
		end

		local trueHangTime = trueMaxHangTime - hangUpdateTime

		if maxHangTime < trueHangTime then
			trueHangTime = maxHangTime
		elseif trueHangTime < 0 then
			trueHangTime = 0
		end

		addRate = math.floor(trueHangTime / xyd.HANG_AWARD_TIME)

		if addRate > 0 then
			addRate = addRate - 1
		end
	end

	self.canGetAward_ = false

	for i = 1, #pAwardItems do
		local item = pAwardItems[i]
		local recordItem = self.house:getAwardItem(item[1])
		local recordNum = 0

		if recordItem then
			recordNum = tonumber(recordItem.item_num)
		end

		xyd.setUISpriteAsync(self["imgIcon" .. i], nil, ItemTable:getIcon(item[1]))

		local awardNum = math.floor(item[2] * addRate + recordNum)
		self["labelNum" .. i].text = xyd.getRoughDisplayNumber(awardNum)

		if awardNum > 0 then
			self.canGetAward_ = true
		end
	end
end

return HouseComfortWindow
