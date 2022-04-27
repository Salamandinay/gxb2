local BaseWindow = import(".BaseWindow")
local DailyQuiz2Window = class("DailyQuiz2Window", BaseWindow)
local DailyQuizTable = xyd.tables.dailyQuizTable
local Backpack = xyd.models.backpack

function DailyQuiz2Window:ctor(name, params)
	DailyQuiz2Window.super.ctor(self, name, params)

	self.dailyQuiz = xyd.models.dailyQuiz
end

function DailyQuiz2Window:getUIComponent()
	local trans = self.window_.transform
	local groupMain = trans:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupMain:ComponentByName("labelTitle_", typeof(UILabel))
	self.upIcon = groupMain:NodeByName("labelTitle_/upIcon").gameObject
	self.content_ = groupMain:NodeByName("content_").gameObject
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.helpBtn_ = groupMain:NodeByName("helpBtn").gameObject
	local group1 = self.content_:NodeByName("group1").gameObject
	self.groupTouch1 = group1:NodeByName("groupTouch1").gameObject
	local groupLeft1 = group1:NodeByName("groupLeft1").gameObject
	self.labelTips1 = groupLeft1:ComponentByName("labelTips1", typeof(UILabel))
	self.label1 = groupLeft1:ComponentByName("label1", typeof(UILabel))
	local groupTimes1 = groupLeft1:NodeByName("groupTimes1").gameObject
	self.labelLeftCount1 = groupTimes1:ComponentByName("labelLeftCount1", typeof(UILabel))
	self.btnBuyTimes1 = groupTimes1:ComponentByName("btnBuyTimes1", typeof(UISprite))
	local group2 = self.content_:NodeByName("group2").gameObject
	self.groupTouch2 = group2:NodeByName("groupTouch2").gameObject
	local groupLeft2 = group2:NodeByName("groupLeft2").gameObject
	self.labelTips2 = groupLeft2:ComponentByName("labelTips2", typeof(UILabel))
	self.label2 = groupLeft2:ComponentByName("label2", typeof(UILabel))
	local groupTimes2 = groupLeft2:NodeByName("groupTimes2").gameObject
	self.labelLeftCount2 = groupTimes2:ComponentByName("labelLeftCount2", typeof(UILabel))
	self.btnBuyTimes2 = groupTimes2:ComponentByName("btnBuyTimes2", typeof(UISprite))
	local group3 = self.content_:NodeByName("group3").gameObject
	self.groupTouch3 = group3:NodeByName("groupTouch3").gameObject
	local groupLeft3 = group3:NodeByName("groupLeft3").gameObject
	self.labelTips3 = groupLeft3:ComponentByName("labelTips3", typeof(UILabel))
	self.label3 = groupLeft3:ComponentByName("label3", typeof(UILabel))
	local groupTimes3 = groupLeft3:NodeByName("groupTimes3").gameObject
	self.labelLeftCount3 = groupTimes3:ComponentByName("labelLeftCount3", typeof(UILabel))
	self.btnBuyTimes3 = groupTimes3:ComponentByName("btnBuyTimes3", typeof(UISprite))
	self.btnBuy = groupMain:NodeByName("btnBuy").gameObject
	self.btnBuyLabel = self.btnBuy:ComponentByName("labelBuy", typeof(UILabel))
end

function DailyQuiz2Window:initWindow()
	DailyQuiz2Window.super.initWindow(self)
	self:getUIComponent()
	self:registerEvent()

	if #self.dailyQuiz:getQuizzes() > 0 then
		self:layout()
	else
		self.dailyQuiz:reqDailyQuizInfo()
		self.content_:SetActive(false)
	end

	self:updateUpIcon()
end

function DailyQuiz2Window:updateUpIcon()
	if xyd.models.activity:isResidentReturnAddTime() then
		self.upIcon:SetActive(xyd.models.activity:isResidentReturnAddTime())

		local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.DAILY_QUIZ)

		xyd.setUISpriteAsync(self.upIcon.gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_" .. return_multiple, nil, , )
	else
		self.upIcon:SetActive(xyd.getReturnBackIsDoubleTime() or xyd.getIsQuizDoubleDrop())
		xyd.setUISpriteAsync(self.upIcon.gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_2", nil, , )
	end
end

function DailyQuiz2Window:getRomanNum(index)
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

function DailyQuiz2Window:updateSubTitle()
	self.labelTips1.text = __("MANA_QUIZ", self:getRomanNum(1))
	self.labelTips2.text = __("EXP_QUIZ", self:getRomanNum(2))
	self.labelTips3.text = __("HERO_QUIZ", self:getRomanNum(3))

	if xyd.Global.lang == "de_de" then
		self.labelTips1.fontSize = 36
		self.labelTips2.fontSize = 36
		self.labelTips3.fontSize = 36
	end
end

function DailyQuiz2Window:layout()
	self.labelTitle_.text = __("DAILY_QUIZ_TITLE")

	self:updateSubTitle()
	self:updateBuyBtn()

	for i = 1, 3 do
		self["label" .. tostring(i)].text = __("DAILY_QUIZ_LEFT_COUNT")

		self:updateCountLabel(i)
	end

	self.btnBuyLabel.text = __("DAILY_QUIZ_TEXT01")
end

function DailyQuiz2Window:updateBuyBtn()
	local totalLimits = 0
	local totalFights = 0
	local canBuyTimes = 0

	for i = 1, 3 do
		local data = self.dailyQuiz:getDataByType(i)
		totalLimits = totalLimits + data.limit_times
		totalFights = totalFights + data.fight_times
		local vip = Backpack:getVipLev()
		local maxBuyTimes = xyd.tables.vipTable:getQuizBuyTimes(vip)
		canBuyTimes = canBuyTimes + maxBuyTimes - data.buy_times
	end

	if totalLimits <= totalFights and canBuyTimes <= 0 then
		xyd.applyChildrenGrey(self.btnBuy)
		xyd.setTouchEnable(self.btnBuy, false)
	end
end

function DailyQuiz2Window:updateCountLabel(index)
	if not index then
		return
	end

	local data = self.dailyQuiz:getDataByType(index)
	local leftCount = tostring(self:getLeftCount(data)) .. "/" .. tostring(self:getTotalCount(data))

	if self:getTotalCount(data) == 0 and self:getLeftCount(data) == 0 then
		leftCount = "2/2"
	end

	self["labelLeftCount" .. tostring(index)].text = leftCount
end

function DailyQuiz2Window:getLeftCount(data_)
	local leftCount = 0

	if data_ then
		leftCount = self:getTotalCount(data_) - data_.fight_times
	end

	return leftCount
end

function DailyQuiz2Window:getTotalCount(data_)
	local totalCount = 0

	if data_ then
		totalCount = data_.limit_times
	end

	return totalCount
end

function DailyQuiz2Window:registerEvent()
	DailyQuiz2Window.super.register(self)

	for i = 1, 3 do
		UIEventListener.Get(self["groupTouch" .. tostring(i)]).onClick = function ()
			local params = {
				index = i
			}

			if self.dailyQuiz:getEndTime() > 0 then
				local duration = self.dailyQuiz:getEndTime() - xyd:getServerTime()

				if duration <= 0 then
					self.dailyQuiz:clearData()
				end
			end

			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
			xyd.WindowManager:get():openWindow("daily_quiz_detail_window", params)
		end

		UIEventListener.Get(self["btnBuyTimes" .. tostring(i)].gameObject).onClick = function ()
			self:onBuyTouch(i)
		end
	end

	UIEventListener.Get(self.helpBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "DAILY_QUIZ_HELP_4"
		})
	end)

	UIEventListener.Get(self.btnBuy).onClick = function ()
		xyd.WindowManager:get():openWindow("daily_quiz_batch_buy_window")
	end

	self.eventProxy_:addEventListener(xyd.event.GET_QUIZ_LIST, handler(self, self.onDailyQuizInfo))
	self.eventProxy_:addEventListener(xyd.event.QUIZ_BUY, handler(self, self.onBuy))
	self.eventProxy_:addEventListener(xyd.event.QUIZ_SWEEP, handler(self, self.onSweep))
	self.eventProxy_:addEventListener(xyd.event.QUIZ_FIGHT, handler(self, self.onSweep))
	self.eventProxy_:addEventListener(xyd.event.QUIZ_BUY_AND_SWEEP, handler(self, self.onBuyAndSweep))
end

function DailyQuiz2Window:onClickSweep(index)
	local data = self.dailyQuiz:getDataByType(index)

	if data and self.dailyQuiz:checkCanFight(data.cur_quiz_id) then
		local leftTimes = data.limit_times - data.fight_times

		if leftTimes > 1 then
			xyd.WindowManager.get():openWindow("daily_quiz_get_window", {
				quiz_id = data.cur_quiz_id,
				leftTimes = leftTimes
			})
		else
			self.dailyQuiz:reqSweep(data.cur_quiz_id, 1)
		end
	else
		xyd.alert(xyd.AlertType.TIPS, __("DAILY_QUIZ_FIGHT_TIPS"))
	end
end

function DailyQuiz2Window:onBuyTouch(index)
	local data_ = self.dailyQuiz:getDataByType(index)

	if not data_ then
		return
	end

	local buyTimes = data_.buy_times
	local vip = Backpack:getVipLev()
	local maxBuyTimes = xyd.tables.vipTable:getQuizBuyTimes(vip)

	if maxBuyTimes <= buyTimes then
		xyd.alert(xyd.AlertType.TIPS, __("DAILY_QUIZ_BUY_TIPS_1", vip, maxBuyTimes))

		return
	else
		xyd.WindowManager:get():openWindow("daily_quiz_buy_window", {
			quiz_type = index,
			buy_times = buyTimes
		})
	end
end

function DailyQuiz2Window:onBuy(event)
	local data = event.data

	xyd.alert(xyd.AlertType.TIPS, __("DAILY_QUIZ_BUY_TIPS_3"))
	self:updateCountLabel(data.quiz.quiz_type)
end

function DailyQuiz2Window:onSweep(event)
	local data = event.data

	self:updateCountLabel(data.quiz_type)
end

function DailyQuiz2Window:onBuyAndSweep(event)
	local quizs = event.data.quizzes

	for i = 1, #quizs do
		self:updateCountLabel(quizs[i].quiz_type)
	end

	self:updateBuyBtn()
end

function DailyQuiz2Window:onDailyQuizInfo()
	self:layout()
	self.content_:SetActive(true)
end

return DailyQuiz2Window
