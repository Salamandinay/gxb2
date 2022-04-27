local BaseWindow = import(".BaseWindow")
local AnniversaryCakeAwardWindow = class("AwardSelectWindow", BaseWindow)
local AnniversaryCakeEndAwardItem = class("AnniversaryCakeEndAwardItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function AnniversaryCakeAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.currentRound = params.currentRound
end

function AnniversaryCakeAwardWindow:initWindow()
	self:getUIComponent()
	AnniversaryCakeAwardWindow.super.initWindow(self)
	self:layout()
	self:initItemGroupAll()
end

function AnniversaryCakeAwardWindow:getUIComponent()
	self.trans = self.window_
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.operationBg = self.groupAction:ComponentByName("operationBg", typeof(UISprite))
	self.labelWinTitle_ = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.awardScroller = self.groupAction:ComponentByName("awardScroller", typeof(UIScrollView))
	self.awardScroller_uipanel = self.groupAction:ComponentByName("awardScroller", typeof(UIPanel))
	self.itemGroupAll = self.awardScroller:NodeByName("itemGroupAll").gameObject
	local wrapContent = self.awardScroller:ComponentByName("itemGroupAll", typeof(MultiRowWrapContent))
	self.drag = self.groupAction:NodeByName("drag").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.anniversary_cake_end_award_item = self.groupAction:NodeByName("anniversary_cake_end_award_item").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.awardScroller, wrapContent, self.anniversary_cake_end_award_item, AnniversaryCakeEndAwardItem, self)
end

function AnniversaryCakeAwardWindow:layout()
	self.labelWinTitle_.text = __("ANNIVERSARY_CAKE_END_AWARD")
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function AnniversaryCakeAwardWindow:initItemGroupAll()
	local awardsList = self:getAwardList()

	self.wrapContent:setInfos(awardsList, {})
end

function AnniversaryCakeAwardWindow:getAwardList()
	local awardList = {}
	local ids = xyd.tables.activityHalloweenAwardTable:finalAwardIds()
	self.maxRound = #ids

	for turnId in pairs(ids) do
		local item = xyd.tables.activityHalloweenAwardTable:getAwards(ids[turnId])
		local params = {
			itemId = item[1][1],
			itemNum = item[1][2],
			turn = turnId
		}

		table.insert(awardList, params)
	end

	return awardList
end

function AnniversaryCakeEndAwardItem:ctor(go, parent)
	AnniversaryCakeEndAwardItem.super.ctor(self, go, parent)
end

function AnniversaryCakeEndAwardItem:initUI()
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.selectedGrey = self.go:ComponentByName("selectedGrey", typeof(UISprite))
	self.selectedMark = self.go:ComponentByName("selectedMark", typeof(UISprite))
	self.currentMark = self.go:ComponentByName("currentMark", typeof(UISprite))
	self.turnsLabel = self.go:ComponentByName("turnsLabel", typeof(UILabel))
end

function AnniversaryCakeEndAwardItem:updateInfo()
	if not self.data.itemId then
		return
	end

	if self.itemIcon and self.turn and self.turn == self.data.turn then
		return
	end

	self.turn = self.data.turn
	self.itemIcon = xyd.getItemIcon({
		show_has_num = true,
		noClickSelected = true,
		uiRoot = self.itemGroup.gameObject,
		itemID = self.data.itemId,
		num = self.data.itemNum,
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		panel = self.parent.awardScroller_uipanel
	})

	self.itemIcon:AddUIDragScrollView()
	self.itemIcon:setScale(0.9)

	if self.data.turn == self.parent.currentRound then
		xyd.setUISpriteAsync(self.currentMark, nil, "anniversary_cake_current_turn_" .. tostring(xyd.Global.lang), nil, )
		self.currentMark:SetActive(true)
	else
		self.currentMark:SetActive(false)
	end

	if self.data.turn < self.parent.currentRound then
		self.selectedGrey:SetActive(true)
		self.selectedMark:SetActive(true)
	else
		self.selectedGrey:SetActive(false)
		self.selectedMark:SetActive(false)
	end

	if self.turn ~= self.parent.maxRound then
		self.turnsLabel.text = __("ROUNDS", self.data.turn)
	else
		self.turnsLabel.text = __("MAX_ROUNDS", self.data.turn)
	end
end

return AnniversaryCakeAwardWindow
