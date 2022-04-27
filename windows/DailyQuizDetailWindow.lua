local DailyQuizTable = xyd.tables.dailyQuizTable
local DailyQuizDetailItem = class("DailyQuizDetailItem", import("app.components.CopyComponent"))

function DailyQuizDetailItem:ctor(go, parent)
	DailyQuizDetailItem.super.ctor(self, go)

	self.parent = parent

	self:setDragScrollView(parent:getScrollView())

	self.id_ = 0
	self.backpack = xyd.models.backpack
	self.dailyQuiz = xyd.models.dailyQuiz

	self:getUIComponent()
	self:registerEvent()
end

function DailyQuizDetailItem:getUIComponent()
	local groupContent = self.go:NodeByName("groupContent").gameObject
	self.imgDiff_ = groupContent:ComponentByName("imgDiff_", typeof(UISprite))
	self.groupIcons_ = groupContent:NodeByName("groupIcons_").gameObject
	self.labelPower_ = groupContent:ComponentByName("labelPower_", typeof(UILabel))
	self.btnFight_ = groupContent:ComponentByName("btnFight_", typeof(UISprite))
	self.fightLabel = self.btnFight_:ComponentByName("fightLabel", typeof(UILabel))
	self.btnFightMask = self.btnFight_:ComponentByName("btnFightMask", typeof(UISprite))
end

function DailyQuizDetailItem:registerEvent()
	UIEventListener.Get(self.btnFight_.gameObject).onClick = handler(self, self.onFightTouch)
end

function DailyQuizDetailItem:refresh()
	self:layout()
end

function DailyQuizDetailItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id_ = info.id

	self:layout()
end

function DailyQuizDetailItem:layout()
	if not self.id_ or self.id_ <= 0 then
		return
	end

	self.labelPower_.text = xyd.getRoughDisplayNumber(DailyQuizTable:getPower(self.id_))
	local awards = DailyQuizTable:getShowAward(self.id_)

	NGUITools.DestroyChildren(self.groupIcons_.transform)

	for _, str in pairs(awards) do
		local award = xyd.split(str, "#")
		local params = {
			isAddUIDragScrollView = true,
			labelNumScale = 1.25,
			itemID = award[1],
			num = tonumber(award[2]),
			uiRoot = self.groupIcons_.gameObject,
			scale = Vector3(0.64, 0.64, 1)
		}
		local type = DailyQuizTable:getType(self.id_)

		if tonumber(params.itemID) == xyd.ItemID.MANA and type == self.parent:getWindowTypeArr().MANA then
			params.num = math.floor(params.num * (1 + xyd.models.dress:getBuffTypeAttr(xyd.DressBuffAttrType.DAILY_COIN)))
		elseif tonumber(params.itemID) == xyd.ItemID.PARTNER_EXP and type == self.parent:getWindowTypeArr().EXP then
			params.num = math.floor(params.num * (1 + xyd.models.dress:getBuffTypeAttr(xyd.DressBuffAttrType.DAILY_PARTNER_EXP)))
		end

		local icon = xyd.getItemIcon(params)
	end

	self.groupIcons_:GetComponent(typeof(UILayout)):Reposition()

	local difficulty = DailyQuizTable:getDifficulty(self.id_)
	local source = "quiz_diff_" .. tostring(difficulty) .. "_png"

	xyd.setUISpriteAsync(self.imgDiff_, nil, source)

	local lv = DailyQuizTable:getLv(self.id_)

	if self.backpack:getLev() < lv then
		self.fightLabel.text = "lv" .. tostring(lv)

		xyd.setTouchEnable(self.btnFight_, false)
		self.btnFightMask:SetActive(true)
	else
		xyd.setTouchEnable(self.btnFight_, true)
		self.btnFightMask:SetActive(false)

		self.fightLabel.text = __("FIGHT")

		self:updateBtnState()
	end
end

function DailyQuizDetailItem:onFightTouch()
	if self.dailyQuiz:checkCanFight(self.id_) then
		local fightParams = {
			showSkip = true,
			battleType = xyd.BattleType.DAILY_QUIZ,
			quizID = self.id_,
			btnSkipCallback = function (flag)
				xyd.models.dailyQuiz:setSkipReport(flag)
			end,
			skipState = xyd.models.dailyQuiz:isSkipReport()
		}
		local quizType = DailyQuizTable:getType(self.id_)
		local quizData = self.dailyQuiz:getDataByType(quizType)

		if self.id_ <= quizData.cur_quiz_id then
			xyd.models.dailyQuiz:reqSweep(self.id_)
		else
			xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
		end
	else
		xyd.alert(xyd.AlertType.TIPS, __("DAILY_QUIZ_FIGHT_TIPS"))
	end
end

function DailyQuizDetailItem:updateBtnState()
	local quizType = DailyQuizTable:getType(self.id_)
	local quizData = self.dailyQuiz:getDataByType(quizType)

	if not quizData then
		return
	end

	self:updateLabel()
end

function DailyQuizDetailItem:updateLabel()
	if self.backpack:getLev() < DailyQuizTable:getLv(self.id_) then
		return
	end

	local quizType = DailyQuizTable:getType(self.id_)
	local quizData = self.dailyQuiz:getDataByType(quizType)

	if self.id_ <= quizData.cur_quiz_id then
		self.fightLabel.text = __("GET2")
	else
		self.fightLabel.text = __("FIGHT")
	end
end

local BaseWindow = import(".BaseWindow")
local DailyQuizDetailWindow = class("DailyQuizDetailWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function DailyQuizDetailWindow:ctor(name, params)
	DailyQuizDetailWindow.super.ctor(self, name, params)

	self.curIndex_ = 1
	self.windowType = {
		EXP = 2,
		HERO = 3,
		MANA = 1
	}
	self.quizItems = {}
	self.dailyQuiz = xyd.models.dailyQuiz
	self.backpack = xyd.models.backpack
	self.curIndex_ = params.index
end

function DailyQuizDetailWindow:getWindowTypeArr()
	return self.windowType
end

function DailyQuizDetailWindow:initWindow()
	DailyQuizDetailWindow.super.initWindow(self)
	self:getUIComponent()
	self:initData()
	self:initTime()
	self:layout()
	self:registerEvent()
end

function DailyQuizDetailWindow:getUIComponent()
	local trans = self.window_.transform
	local groupMain = trans:NodeByName("groupAction").gameObject
	local groupTop = groupMain:NodeByName("groupTop").gameObject
	self.labelTitle_ = groupTop:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = groupTop:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.btnHelp_ = groupMain:ComponentByName("btnHelp_", typeof(UISprite))
	local groupTime = groupMain:NodeByName("groupTime").gameObject
	self.labelTips2_ = groupTime:ComponentByName("labelTips2_", typeof(UILabel))
	local labelTime_ = groupTime:ComponentByName("labelTime_", typeof(UILabel))
	self.labelTime_ = require("app.components.CountDown").new(labelTime_)
	local groupDown = groupMain:NodeByName("groupDown").gameObject
	self.scroller = groupDown:ComponentByName("scroller", typeof(UIScrollView))
	self.groupMain_ = self.scroller:NodeByName("groupMain_").gameObject
	local wrapContent = self.scroller:ComponentByName("groupMain_", typeof(UIWrapContent))
	local item = self.scroller:NodeByName("daily_quiz_detail_item").gameObject
	self.item = self.scroller:ComponentByName("daily_quiz_detail_item", typeof(UIWidget))
	self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, item, DailyQuizDetailItem, self)
end

function DailyQuizDetailWindow:playOpenAnimation(callback)
	local function call()
		if callback then
			callback()
		end

		self:initQuizItems()
	end

	DailyQuizDetailWindow.super:playOpenAnimation(call)
end

function DailyQuizDetailWindow:layout()
	self.labelTitle_.text = __("DAILY_QUIZ_DETAIL_TITLE_" .. tostring(self.curIndex_))
	self.labelTips2_.text = __("DAILY_QUIZ_TIME_COUNT")
end

function DailyQuizDetailWindow:initTime()
	if self.dailyQuiz:getEndTime() > 0 then
		local duration = self.dailyQuiz:getEndTime() - xyd:getServerTime()

		self.labelTime_:setInfo({
			duration = duration,
			callback = function ()
				self.dailyQuiz:reqDailyQuizInfo()
			end
		})
		self.labelTime_:SetActive(true)
	else
		self.labelTime_:SetActive(false)
	end
end

function DailyQuizDetailWindow:initData()
	self.data_ = self.dailyQuiz:getDataByType(self.curIndex_)
end

function DailyQuizDetailWindow:updateLabel()
	self.wrapContent:refresh()
end

function DailyQuizDetailWindow:getLeftCount()
	local leftCount = 0

	if self.data_ then
		leftCount = self:getTotalCount() - self.data_.fight_times
	end

	return leftCount
end

function DailyQuizDetailWindow:getTotalCount()
	local totalCount = 0

	if self.data_ then
		totalCount = self.data_.limit_times
	end

	return totalCount
end

function DailyQuizDetailWindow:registerEvent()
	DailyQuizDetailWindow.super.register(self)

	UIEventListener.Get(self.btnHelp_.gameObject).onClick = handler(self, self.onHelpTouch)

	self.eventProxy_:addEventListener(xyd.event.GET_QUIZ_LIST, handler(self, self.onDailyQuizInfo))
	self.eventProxy_:addEventListener(xyd.event.QUIZ_FIGHT, handler(self, self.onFight))
	self.eventProxy_:addEventListener(xyd.event.QUIZ_SWEEP, handler(self, self.onSweep))
end

function DailyQuizDetailWindow:onDailyQuizInfo()
	self:initData()
	self:updateLabel()
	self:initTime()
end

function DailyQuizDetailWindow:onFight()
	self:initData()
	self:updateLabel()
end

function DailyQuizDetailWindow:onSweep()
	self:initData()
	self:updateLabel()
end

function DailyQuizDetailWindow:onHelpTouch()
	local params = {
		key = "DAILY_QUIZ_HELP_" .. tostring(self.curIndex_)
	}

	xyd.WindowManager:get():openWindow("help_window", params)
end

function DailyQuizDetailWindow:onBuyTouch()
	if not self.data_ then
		return
	end

	local buyTimes = self.data_.buy_times
	local vip = self.backpack:getVipLev()
	local maxBuyTimes = xyd.tables.vipTable:getQuizBuyTimes(vip)

	if maxBuyTimes <= buyTimes then
		xyd.alert(xyd.AlertType.TIPS, __("DAILY_QUIZ_BUY_TIPS_1", vip, maxBuyTimes))

		return
	else
		xyd.WindowManager:get():openWindow("daily_quiz_buy_window", {
			quiz_type = self.curIndex_,
			buy_times = buyTimes
		})
	end
end

function DailyQuizDetailWindow:initQuizItems()
	self.quizItems = {}
	local ids = DailyQuizTable:getIDsByType(self.curIndex_)
	local totalHeight = 12
	local infos = {}
	local index = ids[1]
	local timer = nil

	local function onTime()
		if ids[#ids] < index then
			self:updateScrollPos(totalHeight)
			timer:Stop()

			return
		end

		table.insert(infos, {
			id = index
		})
		self.wrapContent:setInfos(infos)

		index = index + 1
		totalHeight = totalHeight + self.item.height + 10
	end

	timer = self:getTimer(onTime, 0.03, -1)

	timer:Start()
end

function DailyQuizDetailWindow:updateScrollPos(totalHeight)
	local ids = DailyQuizTable:getIDsByType(self.curIndex_)
	local midLev = DailyQuizTable:getLv(ids[4])
	local maxLev = DailyQuizTable:getLv(ids[7])
	local curLev = self.backpack:getLev()
	local curStage = nil

	for i = 4, 7 do
		if curLev < DailyQuizTable:getLv(ids[i]) then
			curStage = i - 1

			break
		end
	end

	if maxLev <= curLev then
		self.scroller:MoveRelative(Vector3(0, totalHeight - 622, 0))
	elseif midLev <= curLev then
		if curStage == 4 then
			self.scroller:MoveRelative(Vector3(0, 79, 0))
		elseif curStage == 5 then
			self.scroller:MoveRelative(Vector3(0, 187, 0))
		elseif curStage == 6 then
			self.scroller:MoveRelative(Vector3(0, 295, 0))
		end
	end
end

function DailyQuizDetailWindow:getScrollView()
	return self.scroller
end

return DailyQuizDetailWindow
