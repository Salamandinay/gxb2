local BaseWindow = import(".BaseWindow")
local ActivityMonthlyHikeAwardWindow2 = class("ActivityMonthlyHikeAwardWindow2", BaseWindow)
local MonthlyHikeBatteItem = class("MonthlyHikeBatteItem", import("app.components.CopyComponent"))

function MonthlyHikeBatteItem:ctor(go, parent)
	self.parent_ = parent

	MonthlyHikeBatteItem.super.ctor(self, go)
end

function MonthlyHikeBatteItem:initUI()
	self:getUIComponent()
end

function MonthlyHikeBatteItem:getUIComponent()
	local goTrans = self.go.transform
	self.goHeight = self.go:GetComponent(typeof(UIWidget))
	self.labelStageText = goTrans:ComponentByName("title/labelStageText", typeof(UILabel))
	self.labelStage = goTrans:ComponentByName("title/labelStage", typeof(UILabel))
	self.labelAward = goTrans:ComponentByName("title2/labelCount", typeof(UILabel))
	self.groupHarm = goTrans:NodeByName("groupHarm").gameObject
	self.labelHarmText = goTrans:ComponentByName("groupHarm/labelHarmText", typeof(UILabel))
	self.labelHarm = goTrans:ComponentByName("groupHarm/labelHarm", typeof(UILabel))
	self.groupItem = goTrans:ComponentByName("groupItem", typeof(UIGrid))
	self.costLabel_ = goTrans:ComponentByName("costPart/label", typeof(UILabel))
	self.bg_ = goTrans:ComponentByName("bg", typeof(UIWidget))
end

function MonthlyHikeBatteItem:setInfo(params)
	self.items = params.items or {}
	self.harm = params.harm
	self.stageID = params.stageID
	self.chapterID = xyd.tables.activityMonthlyStageTable:getChapter(self.stageID)
	self.useNum = params.useNum

	self:setText()
	self:initData()

	for i, v in pairs(self.items) do
		local data = self.items[i]
		local icon = xyd.getItemIcon({
			itemID = data.item_id,
			num = data.item_num,
			uiRoot = self.groupItem.gameObject,
			dragscorllView = self.parent_.scrollView_
		})

		icon:setItemIconSize(130, 130)
	end

	self.groupItem:Reposition()

	if #self.items <= 5 then
		self.bg_.height = 346
		self.goHeight.height = 346
	else
		self.bg_.height = 468
		self.goHeight.height = 468
	end

	self.parent_.grid_:Reposition()
	self.parent_.scrollView_:ResetPosition()
end

function MonthlyHikeBatteItem:initData()
	local tmpData = {}

	for i, item in pairs(self.items) do
		if item.item_id ~= nil and item.item_num ~= nil then
			if tmpData[tonumber(item.item_id)] == nil then
				tmpData[tonumber(item.item_id)] = tonumber(item.item_num)
			else
				tmpData[tonumber(item.item_id)] = tmpData[tonumber(item.item_id)] + tonumber(item.item_num)
			end
		end
	end

	self.items = {}

	for i, v in pairs(tmpData) do
		if v ~= nil then
			table.insert(self.items, {
				item_id = i,
				item_num = v
			})
		end
	end

	table.sort(self.items, function (a, b)
		return tonumber(a.item_id) < tonumber(b.item_id)
	end)
end

function MonthlyHikeBatteItem:setText()
	self.labelAward.text = __("TRIAL_TEXT07")
	self.labelHarmText.text = __("WORLD_BOSS_SWEEP_TEXT06")
	self.labelHarm.text = tostring(self.harm)
	self.costLabel_.text = "x" .. self.useNum
	local stageIndex = xyd.arrayIndexOf(xyd.tables.activityMonthlyChapterTable:getStageIDs(self.chapterID), self.stageID)
	self.labelStageText.text = __("WORLD_BOSS_SWEEP_TEXT07", self.chapterID .. "-" .. stageIndex)
end

function ActivityMonthlyHikeAwardWindow2:ctor(name, params)
	ActivityMonthlyHikeAwardWindow2.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.MONTHLY_HIKE)
	self.callback = params.callback or nil
	self.items = params.items or {}
	self.itemTable = xyd.tables.itemTable
	self.title = params.title or __("BATTLE_STATISTICS_TITLE")
	self.score = params.score
	self.harm = params.harm
	self.stageID = params.stageID
	self.chapterID = xyd.tables.activityMonthlyStageTable:getChapter(self.stageID)
	self.useNum = params.useNum
	self.totlaUseNum = self.useNum
end

function ActivityMonthlyHikeAwardWindow2:initWindow()
	ActivityMonthlyHikeAwardWindow2.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:setText()
	self.btnSure_:SetActive(false)
	self:addBattleData()
end

function ActivityMonthlyHikeAwardWindow2:getUIComponent()
	local winTrans = self.window_.transform
	self.main = winTrans:NodeByName("groupAction").gameObject
	self.bg = self.main:ComponentByName("bg", typeof(UISprite))
	self.labelTitle_ = self.main:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelTips_ = self.main:ComponentByName("labelTips", typeof(UILabel))
	self.scrollView_ = self.main:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = self.main:ComponentByName("scrollView/grid", typeof(UILayout))
	self.battleDataNode_ = self.main:NodeByName("battleDataNode").gameObject
	self.maskPanel_ = self.main:NodeByName("maskPanel").gameObject
	self.btnStop_ = self.main:NodeByName("maskPanel/btnStop").gameObject
	self.btnStopLabel_ = self.main:ComponentByName("maskPanel/btnStop/button_label", typeof(UILabel))
	self.btnSure_ = self.main:NodeByName("btnSure_").gameObject
	self.btnSure_button_label = self.main:ComponentByName("btnSure_/button_label", typeof(UILabel))
end

function ActivityMonthlyHikeAwardWindow2:initUIComponent()
	UIEventListener.Get(self.btnSure_.gameObject).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnStop_).onClick = function ()
		self.maskPanel_.gameObject:SetActive(false)
		self.btnSure_:SetActive(true)

		self.labelTips_.text = __("WORLD_BOSS_SWEEP_TEXT04", self.totlaUseNum)

		if next(self.waitForTimeKeys_) then
			for i = 1, #self.waitForTimeKeys_ do
				XYDCo.StopWait(self.waitForTimeKeys_[i])
			end

			self.waitForTimeKeys_ = {}
		end
	end
end

function ActivityMonthlyHikeAwardWindow2:addBattleData()
	local newRoot = NGUITools.AddChild(self.grid_.gameObject, self.battleDataNode_)
	local newDataItem = MonthlyHikeBatteItem.new(newRoot, self)

	newRoot.transform:SetSiblingIndex(0)
	newDataItem:setInfo({
		items = self.items or {},
		harm = self.harm,
		stageID = self.stageID,
		useNum = self.useNum
	})

	local nextStage = xyd.tables.activityMonthlyStageTable:getNextID(self.stageID)
	local tempBattleData = self.activityData:getTempSweepInfo()
	local resTime = tempBattleData.times - self.useNum

	if nextStage and nextStage > 0 and resTime > 0 then
		self:waitForTime(1.5, function ()
			self:askNextBattle()
		end)
	else
		self.maskPanel_.gameObject:SetActive(false)
		self.btnSure_:SetActive(true)

		if next(self.waitForTimeKeys_) then
			for i = 1, #self.waitForTimeKeys_ do
				XYDCo.StopWait(self.waitForTimeKeys_[i])
			end

			self.waitForTimeKeys_ = {}
		end

		self.labelTips_.text = __("WORLD_BOSS_SWEEP_TEXT04", self.totlaUseNum)
	end
end

function ActivityMonthlyHikeAwardWindow2:addNewItem(params)
	self.items = params.items or {}
	self.harm = params.harm
	self.useNum = params.useNum
	self.totlaUseNum = self.totlaUseNum + self.useNum

	self:addBattleData()
end

function ActivityMonthlyHikeAwardWindow2:askNextBattle()
	local tempBattleData = self.activityData:getTempSweepInfo()
	self.stageID = xyd.tables.activityMonthlyStageTable:getNextID(self.stageID)

	xyd.models.activity:fightBossNew(xyd.ActivityID.MONTHLY_HIKE, tempBattleData.partners, tempBattleData.petID, tempBattleData.times - self.useNum, tempBattleData.isSweep)
end

function ActivityMonthlyHikeAwardWindow2:setText()
	self.btnSure_button_label.text = __("WORLD_BOSS_SWEEP_TEXT03")
	self.btnStopLabel_.text = __("WORLD_BOSS_SWEEP_TEXT02")
	self.labelTitle_.text = self.title
	self.labelTips_.text = __("WORLD_BOSS_SWEEP_TEXT01")
end

function ActivityMonthlyHikeAwardWindow2:willClose()
	if self.callback then
		self:callback()
	end

	BaseWindow.willClose(self)
end

return ActivityMonthlyHikeAwardWindow2
