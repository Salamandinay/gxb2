local DailyQuizBatchBuyWindow = class("DailyQuizBatchBuyWindow", import(".BaseWindow"))
local SelectNum = import("app.components.SelectNum")
local DailyQuizTable = xyd.tables.dailyQuizTable
local Backpack = xyd.models.backpack

function DailyQuizBatchBuyWindow:ctor(name, params)
	DailyQuizBatchBuyWindow.super.ctor(self, name, params)

	self.dailyQuiz = xyd.models.dailyQuiz

	for i = 1, 3 do
		self["purchaseNum_" .. i] = 0
		self["leftTimes_" .. i] = 0
	end
end

function DailyQuizBatchBuyWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function DailyQuizBatchBuyWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelCost = groupAction:ComponentByName("groupCost/labelCost", typeof(UILabel))
	self.btnSure = groupAction:NodeByName("btnSure").gameObject
	self.btnSureLabel = self.btnSure:ComponentByName("btnSureLabel", typeof(UILabel))

	for i = 1, 3 do
		local group = groupAction:NodeByName("group" .. i).gameObject
		self["labelBuyTimes_" .. i] = group:ComponentByName("labelBuyTimes", typeof(UILabel))
		self["groupBuyTimes_" .. i] = group:ComponentByName("groupBuyTimes", typeof(UILayout))
		self["labelType_" .. i] = self["groupBuyTimes_" .. i]:ComponentByName("labelType", typeof(UILabel))
		self["labelLeftTimes_" .. i] = self["groupBuyTimes_" .. i]:ComponentByName("labelLeftTimes", typeof(UILabel))
		local selectNumRoot = group:NodeByName("selectNum").gameObject
		self["selectNum_" .. i] = SelectNum.new(selectNumRoot, "minmax")
	end
end

function DailyQuizBatchBuyWindow:layout()
	self.labelTitle.text = __("DAILY_QUIZ_TEXT01")
	self.btnSureLabel.text = __("CONFIRM")
	self.labelType_1.text = __("MANA_QUIZ2", self:getRomanNum(1))
	self.labelType_2.text = __("EXP_QUIZ2", self:getRomanNum(2))
	self.labelType_3.text = __("HERO_QUIZ2", self:getRomanNum(3))

	for i = 1, 3 do
		self["labelBuyTimes_" .. i].text = __("DAILY_QUIZ_TEXT04")
		local data = self.dailyQuiz:getDataByType(i)
		self["labelLeftTimes_" .. i].text = __("DAILY_QUIZ_LEFT_COUNT") .. data.limit_times - data.fight_times
		self["leftTimes_" .. i] = data.limit_times - data.fight_times
		local vip = Backpack:getVipLev()
		local maxBuyTimes = xyd.tables.vipTable:getQuizBuyTimes(vip)
		local maxCanBuy = maxBuyTimes - data.buy_times
		local params = {
			delForceZero = true,
			minNum = 0,
			curNum = 0,
			maxNum = maxCanBuy,
			callback = function (input)
				self["purchaseNum_" .. i] = input

				self:updateCost()
			end,
			minCallback = function ()
				self["selectNum_" .. i].curNum_ = 0

				self["selectNum_" .. i]:changeCurNum()
			end
		}

		self["selectNum_" .. i]:setInfo(params)
		self["selectNum_" .. i]:setFontSize(26)
		self["selectNum_" .. i]:setBtnPos(112)
		self["selectNum_" .. i]:setMaxAndMinBtnPos(186)
		self["selectNum_" .. i]:setSelectBGSize(140, 40)
		self["selectNum_" .. i]:setKeyboardPos(0, -200)
	end
end

function DailyQuizBatchBuyWindow:getRomanNum(index)
	local data = self.dailyQuiz:getDataByType(index)

	if not data then
		return nil
	end

	local ids = DailyQuizTable:getIDsByType(index)

	for i = 1, #ids do
		if data.cur_quiz_id == ids[i] then
			return xyd.ROMAN_NUM[i]
		end
	end

	return nil
end

function DailyQuizBatchBuyWindow:updateCost()
	local costs = xyd.split(xyd.tables.miscTable:getVal("quiz_buy_cost"), "#", true)
	local costItemID = costs[1]
	local costNum = costs[2]
	local buyNum = 0

	for i = 1, 3 do
		buyNum = buyNum + self["purchaseNum_" .. i]
	end

	self.totalCost = costNum * buyNum
	local total = Backpack:getItemNumByID(costItemID)

	if total < self.totalCost then
		self.labelCost.text = "[c][cc0011]" .. xyd.getRoughDisplayNumber(total) .. "[-][/c]" .. "/" .. self.totalCost
	else
		self.labelCost.text = "[c][5E6996]" .. xyd.getRoughDisplayNumber(total) .. "[-][/c]" .. "/" .. self.totalCost
	end
end

function DailyQuizBatchBuyWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.btnSure).onClick = handler(self, function ()
		local costs = xyd.split(xyd.tables.miscTable:getVal("quiz_buy_cost"), "#", true)
		local costItemID = costs[1]

		if xyd.isItemAbsence(costItemID, self.totalCost) then
			return
		end

		local leftTimes = 0

		for i = 1, 3 do
			local data = self.dailyQuiz:getDataByType(i)
			leftTimes = leftTimes + data.limit_times - data.fight_times
		end

		if leftTimes == 0 and self.totalCost == 0 then
			xyd.showToast(__("DAILY_QUIZ_TEXT03"))

			return
		end

		self.dailyQuiz:reqBuyAndSweep({
			self.purchaseNum_1,
			self.purchaseNum_2,
			self.purchaseNum_3
		})
		self:close()
	end)
end

return DailyQuizBatchBuyWindow
