local BaseWindow = import(".BaseWindow")
local SummonRecordWindow = class("SummonRecordWindow", BaseWindow)
local SummonRecordWindowItem = class("SummonRecordWindowItem", import("app.common.ui.FixedWrapContentItem"))
local SummonRecordWindowIconItem = class("SummonRecordWindowIconItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local HeroIcon = import("app.components.HeroIcon")
local cjson = require("cjson")
local SUMMON_TYPE = {
	GUARANTEE = 5,
	FRIENDSHIP = 4,
	TICKET = 6,
	HIGH = 2,
	NORMAL = 1,
	WISH = 3
}
local SUMMON_TIMES = {
	TEN = 2,
	ONE = 1
}
local itemOffset, mainOffset = nil
local mainScrollerLock = false
local itemScrollerLock = false
local scrollThresholdX = 10
local scrollThresholdY = 5
local itemScrollerList = {}

function SummonRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function SummonRecordWindow:initWindow()
	self:getUIComponent()
	SummonRecordWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
	self:hide()

	local msg = messages_pb:get_summon_log_req()

	xyd.Backend.get():request(xyd.mid.GET_SUMMON_LOG)
end

function SummonRecordWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.helpBtn = groupAction:NodeByName("helpBtn").gameObject
	local groupContent = groupAction:NodeByName("groupContent").gameObject
	self.scrollView = groupContent:ComponentByName("scrollerMain", typeof(UIScrollView))
	self.scrollPanel = groupContent:ComponentByName("scrollerMain", typeof(UIPanel))
	self.drag = groupContent:NodeByName("drag").gameObject
	self.groupItem = self.scrollView:NodeByName("groupItem").gameObject
	local wrapContent = self.groupItem:GetComponent(typeof(UIWrapContent))
	self.item = winTrans:NodeByName("item").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.item, SummonRecordWindowItem, self)
	self.groupNone = groupAction:NodeByName("groupNone").gameObject
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
end

function SummonRecordWindow:onDragStarted()
	if self.scrollView then
		mainOffset = self.scrollView.transform.localPosition.y
		mainScrollerLock = false
		itemScrollerLock = false
		self.checkFinish = false
	end
end

function SummonRecordWindow:onDragFinished()
	if self.scrollView then
		self.scrollView.enabled = true
		self.checkFinish = true

		for i = 1, #itemScrollerList do
			itemScrollerList[i].enabled = false
			itemScrollerList[i].enabled = true
		end

		itemScrollerList = {}
	end
end

function SummonRecordWindow:onDragMoving()
	if self.scrollView then
		if itemScrollerLock and not self.checkFinish then
			for i = 1, #itemScrollerList do
				itemScrollerList[i].enabled = false
			end
		end

		if scrollThresholdY < math.abs(self.scrollView.transform.localPosition.y - mainOffset) then
			itemScrollerLock = true
		end
	end
end

function SummonRecordWindow:initUIComponent()
	self.labelTitle.text = __("GACHA_RECORD_TITLE")
	self.labelNoneTips.text = __("GACHA_RECORD_EMPTY")
end

function SummonRecordWindow:register()
	BaseWindow.register(self)

	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "GACHA_RECORD_HELP"
		})
	end)

	self.eventProxy_:addEventListener(xyd.event.GET_SUMMON_LOG, self.onSummonLog, self)

	self.scrollView.onDragMoving = handler(self, self.onDragMoving)
	self.scrollView.onDragStarted = handler(self, self.onDragStarted)
	self.scrollView.onDragFinished = handler(self, self.onDragFinished)
end

function SummonRecordWindow:onSummonLog(event)
	self:show()

	local list = event.data.list

	if #list == 0 then
		self.groupNone:SetActive(true)
	else
		self.groupNone:SetActive(false)
	end

	local collection = {}

	for i = 1, #list do
		local data = xyd.split(list[i], "#", true)
		local type = SUMMON_TYPE.NORMAL
		local times = SUMMON_TIMES.ONE
		local partners = {}

		if data[1] == 3 or data[1] == 2 or data[1] == 1 then
			type = SUMMON_TYPE.NORMAL
		elseif data[1] == 7 or data[1] == 5 or data[1] == 8 or data[1] == 4 or data[1] == 6 then
			type = SUMMON_TYPE.HIGH
		elseif data[1] == 25 or data[1] == 22 or data[1] == 23 or data[1] == 26 or data[1] == 24 then
			type = SUMMON_TYPE.WISH
		elseif data[1] == 15 or data[1] == 16 then
			type = SUMMON_TYPE.FRIENDSHIP
		elseif data[1] == 9 then
			type = SUMMON_TYPE.GUARANTEE
		else
			type = SUMMON_TYPE.TICKET
		end

		if #data == 2 then
			times = SUMMON_TIMES.ONE
		else
			times = SUMMON_TIMES.TEN
		end

		for i = 2, #data do
			table.insert(partners, data[i])
		end

		table.sort(partners, function (a, b)
			return xyd.tables.partnerTable:getStar(b) < xyd.tables.partnerTable:getStar(a)
		end)
		table.insert(collection, {
			type = type,
			times = times,
			partners = partners
		})
	end

	self.wrapContent:setInfos(collection, {})
	self.scrollView:ResetPosition()
end

function SummonRecordWindowItem:ctor(go, parent)
	SummonRecordWindowItem.super.ctor(self, go, parent)
end

function SummonRecordWindowItem:initUI()
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.summonTypeIcon = self.go:ComponentByName("icon", typeof(UISprite))
	self.devideLine = self.go:ComponentByName("devideLine", typeof(UISprite))
	self.scroller = self.go:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollPanel = self.go:ComponentByName("scroller", typeof(UIPanel))
	self.drag = self.go:ComponentByName("drag", typeof(UIDragScrollView))
	self.groupPartner = self.scroller:NodeByName("groupPartner").gameObject
	local wrapContent = self.groupPartner:GetComponent(typeof(UIWrapContent))
	self.item = self.go:NodeByName("iconItem").gameObject
	self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, self.item, SummonRecordWindowIconItem, self)
end

function SummonRecordWindowItem:registerEvent()
	self.scroller.onDragMoving = handler(self, self.onDragMoving)
	self.scroller.onDragStarted = handler(self, self.onDragStarted)
	self.scroller.onDragFinished = handler(self, self.onDragFinished)
end

function SummonRecordWindowItem:onDragStarted()
	if self.scroller then
		itemOffset = self.scroller.transform.localPosition.x
		mainScrollerLock = false
		itemScrollerLock = false
		self.checkFinish = false
		itemScrollerList[#itemScrollerList + 1] = self.scroller
	end
end

function SummonRecordWindowItem:onDragFinished()
	if self.scroller and self.parent.scrollView then
		self.scroller.enabled = true
		self.checkFinish = true
		self.parent.scrollView.enabled = true
	end
end

function SummonRecordWindowItem:onDragMoving()
	if self.scroller and self.parent.scrollView then
		if mainScrollerLock and not self.checkFinish then
			self.parent.scrollView.enabled = false
		end

		if scrollThresholdX < math.abs(self.scroller.transform.localPosition.x - itemOffset) then
			mainScrollerLock = true
		end
	end
end

function SummonRecordWindowItem:updateInfo()
	local type = self.data.type
	local times = self.data.times
	local partners = self.data.partners

	if type == SUMMON_TYPE.NORMAL then
		xyd.setUISpriteAsync(self.summonTypeIcon, nil, "summon_record_normal_icon", nil, , true)
	elseif type == SUMMON_TYPE.HIGH then
		xyd.setUISpriteAsync(self.summonTypeIcon, nil, "summon_record_high_icon", nil, , true)
	elseif type == SUMMON_TYPE.WISH then
		xyd.setUISpriteAsync(self.summonTypeIcon, nil, "summon_record_wish_icon")
	elseif type == SUMMON_TYPE.FRIENDSHIP then
		xyd.setUISpriteAsync(self.summonTypeIcon, nil, "summon_record_friendship_icon", nil, , true)
	elseif type == SUMMON_TYPE.GUARANTEE then
		xyd.setUISpriteAsync(self.summonTypeIcon, nil, "summon_record_guarantee_icon", nil, , true)
	else
		xyd.setUISpriteAsync(self.summonTypeIcon, nil, "summon_record_ticket_icon", nil, , true)
	end

	xyd.setUISpriteAsync(self.devideLine, nil, "summon_record_item_line")
	xyd.setUISpriteAsync(self.bg, nil, "9gongge17")

	local collection = {}
	local exist5Star = false

	for i = 1, #partners do
		table.insert(collection, {
			partnerID = partners[i]
		})

		if xyd.tables.partnerTable:getStar(partners[i]) >= 5 then
			exist5Star = true
		end
	end

	if exist5Star and #partners == 1 then
		self.scrollPanel:SetLeftAnchor(self.bg.gameObject, 0, 92)

		self.scroller.padding = Vector3(10, 0)
	elseif exist5Star then
		self.scrollPanel:SetLeftAnchor(self.bg.gameObject, 0, 107)

		self.scroller.padding = Vector3(-5, 0)
	else
		self.scrollPanel:SetLeftAnchor(self.bg.gameObject, 0, 107)

		self.scroller.padding = Vector3(10, 0)
	end

	self.wrapContent:setInfos(collection, {})
	self.scroller:ResetPosition()
end

function SummonRecordWindowIconItem:ctor(go, parent)
	SummonRecordWindowIconItem.super.ctor(self, go, parent)
end

function SummonRecordWindowIconItem:initUI()
	self.icon = self.go:NodeByName("icon").gameObject
	self.iconBg = self.go:ComponentByName("iconBg", typeof(UISprite))

	self.iconBg:SetActive(false)
end

function SummonRecordWindowIconItem:updateInfo()
	local partnerID = self.data.partnerID

	if self.heroIcon then
		self.heroIcon:setInfo({
			noClick = true,
			scale = 0.7962962962962963,
			itemID = partnerID
		})

		if xyd.tables.partnerTable:getStar(partnerID) >= 5 then
			self.iconBg:SetActive(true)
		else
			self.iconBg:SetActive(false)
		end
	else
		self.heroIcon = HeroIcon.new(self.icon)

		self.heroIcon:setInfo({
			noClick = true,
			scale = 0.7962962962962963,
			itemID = partnerID
		})

		if xyd.tables.partnerTable:getStar(partnerID) >= 5 then
			self.iconBg:SetActive(true)
		else
			self.iconBg:SetActive(false)
		end
	end
end

return SummonRecordWindow
