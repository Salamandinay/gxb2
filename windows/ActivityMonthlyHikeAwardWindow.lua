local BaseWindow = import(".BaseWindow")
local ActivityMonthlyHikeAwardWindow = class("ActivityMonthlyHikeAwardWindow", BaseWindow)

function ActivityMonthlyHikeAwardWindow:ctor(name, params)
	ActivityMonthlyHikeAwardWindow.super.ctor(self, name, params)

	self.callback = params.callback or nil
	self.items = params.items or {}
	self.itemTable = xyd.tables.itemTable
	self.title = params.title or __("BATTLE_STATISTICS_TITLE")
	self.score = params.score
	self.harm = params.harm
	self.stageID = params.stageID
	self.chapterID = xyd.tables.activityMonthlyStageTable:getChapter(self.stageID)
	self.useNum = params.useNum
end

function ActivityMonthlyHikeAwardWindow:initWindow()
	ActivityMonthlyHikeAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function ActivityMonthlyHikeAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.main = winTrans:NodeByName("groupAction").gameObject
	self.bg = self.main:ComponentByName("bg", typeof(UISprite))
	self.labelTitle_ = self.main:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelStageText = self.main:ComponentByName("title/labelStageText", typeof(UILabel))
	self.labelStage = self.main:ComponentByName("title/labelStage", typeof(UILabel))
	self.labelAward = self.main:ComponentByName("title2/labelCount", typeof(UILabel))
	self.groupHarm = self.main:NodeByName("groupHarm").gameObject
	self.labelHarmText = self.main:ComponentByName("groupHarm/labelHarmText", typeof(UILabel))
	self.labelHarm = self.main:ComponentByName("groupHarm/labelHarm", typeof(UILabel))
	self.scrollview = self.main:ComponentByName("award_part/scrollview", typeof(UIScrollView))
	self.drag_ = self.main:NodeByName("award_part/drag").gameObject
	self.groupItem = self.main:ComponentByName("award_part/scrollview/groupItem", typeof(UIGrid))
	self.drag_uiWidget = self.drag_:GetComponent(typeof(UIWidget))
	self.drag_uiWidget.depth = self.scrollview:GetComponent(typeof(UIPanel)).depth + 1
	self.btnSure_ = self.main:NodeByName("btnSure_").gameObject
	self.btnSure_button_label = self.main:ComponentByName("btnSure_/button_label", typeof(UILabel))
	self.closeBtn_ = self.main:NodeByName("closeBtn").gameObject
	self.costLabel_ = self.main:ComponentByName("costPart/label", typeof(UILabel))
end

function ActivityMonthlyHikeAwardWindow:initUIComponent()
	self:setText()
	self:setItem()

	UIEventListener.Get(self.btnSure_.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ActivityMonthlyHikeAwardWindow:setText()
	self.btnSure_button_label.text = __("SURE_2")
	self.labelTitle_.text = self.title
	self.labelAward.text = __("TRIAL_TEXT07")

	if self.harm ~= nil then
		self.labelHarmText.text = __("FRIEND_HARM")
		self.labelHarm.text = tostring(self.harm)
	else
		self.labelHarm:SetActive(false)
		self.labelHarmText:SetActive(false)
	end
end

function ActivityMonthlyHikeAwardWindow:initData()
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

function ActivityMonthlyHikeAwardWindow:setItem()
	self:initData()

	for i, v in pairs(self.items) do
		local data = self.items[i]
		local icon = xyd.getItemIcon({
			itemID = data.item_id,
			num = data.item_num,
			uiRoot = self.groupItem.gameObject
		})

		icon:setItemIconSize(130, 130)

		if self.drag_uiWidget.height < math.ceil(#self.items / 5) * 130 then
			icon:AddUIDragScrollView()
		end
	end

	self.groupItem:Reposition()
	self.scrollview:ResetPosition()

	self.costLabel_.text = "x" .. self.useNum
	local stageIndex = xyd.arrayIndexOf(xyd.tables.activityMonthlyChapterTable:getStageIDs(self.chapterID), self.stageID)
	self.labelStageText.text = __("WORLD_BOSS_SWEEP_TEXT07", self.chapterID .. "-" .. stageIndex)
end

function ActivityMonthlyHikeAwardWindow:willClose()
	if self.callback then
		self:callback()
	end

	BaseWindow.willClose(self)
end

return ActivityMonthlyHikeAwardWindow
