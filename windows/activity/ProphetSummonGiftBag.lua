local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ProphetSummonGiftBag = class("ProphetSummonGiftBag", ActivityContent)
local ProphetSummonGiftBagItem = class("ValueGiftBagItem", import("app.components.CopyComponent"))
local ActivityTreeTable = xyd.tables.activityTreeTable

function ProphetSummonGiftBag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.currentState = xyd.Global.lang
	self.data = {}

	self:getUIComponent()
	self:euiComplete()
	self:checkIfMove()
end

function ProphetSummonGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/prophet_summon_giftbag"
end

function ProphetSummonGiftBag:getUIComponent()
	local go = self.go
	self.activityGroup = go:NodeByName("main").gameObject
	self.textImg = self.activityGroup:ComponentByName("textImg", typeof(UISprite))
	self.textLabel = self.activityGroup:ComponentByName("textLabel", typeof(UILabel))
	self.timerGroup = self.activityGroup:NodeByName("timerGroup").gameObject
	self.timeLabel = self.timerGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timerGroup:ComponentByName("endLabel", typeof(UILabel))
	self.scroller = self.activityGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollerPanel = self.activityGroup:ComponentByName("scroller", typeof(UIPanel))
	self.scrollerPanel.depth = self.scrollerPanel.depth + 1
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.groupItem_uigrid = self.groupItem:GetComponent(typeof(UIGrid))
	self.btn = self.activityGroup:NodeByName("btn").gameObject
	self.btnLabel = self.btn:ComponentByName("label", typeof(UILabel))
	self.roundLabel = self.activityGroup:ComponentByName("roundBg/label", typeof(UILabel))
	self.itemCell = go:NodeByName("itemCell").gameObject
end

function ProphetSummonGiftBag:euiComplete()
	xyd.setUISpriteAsync(self.textImg, nil, "prophet_summon_giftbag_text01_" .. xyd.Global.lang, nil, , true)
	self:setText()
	self:setItem()
	self:eventRegister()

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	if xyd.Global.lang == "de_de" then
		self.timeLabel:X(-45)
		self.endLabel:X(-35)
		self.textImg:X(110)
	end

	if xyd.Global.lang == "fr_fr" then
		self.textLabel.width = 400

		self.textLabel:X(-65)
	end
end

function ProphetSummonGiftBag:setText()
	self.endLabel.text = __("TEXT_END")
	self.textLabel.text = __("PROPHET_SUMMON_GIFTBAG_TEXT01")
	self.roundLabel.text = __("WISHING_POOL_GIFTBAG_TEXT02", self.activityData.detail.circle_times, xyd.tables.activityTable:getRound(self.id)[2])
	self.btnLabel.text = __("GO_TO_PROPHET")
end

function ProphetSummonGiftBag:setItem()
	local ids = ActivityTreeTable:getIDs()
	self.data = {}

	for i, v in pairs(ids) do
		local id = ids[i]
		local is_completed = false

		if ActivityTreeTable:getPoint(tonumber(id)) <= self.activityData.detail.point or xyd.tables.activityTable:getRound(self.id)[2] <= self.activityData.detail.circle_times then
			is_completed = true
		end

		local param = {
			id = id,
			isCompleted = is_completed,
			point = self.activityData.detail.point,
			limit_point = ActivityTreeTable:getPoint(id)
		}

		table.insert(self.data, param)
	end

	table.sort(self.data, function (a, b)
		if a.isCompleted == b.isCompleted then
			return tonumber(a.id) < tonumber(b.id)
		else
			return b.isCompleted
		end
	end)
	NGUITools.DestroyChildren(self.groupItem.transform)

	for i in ipairs(self.data) do
		local tmp = NGUITools.AddChild(self.groupItem, self.itemCell)
		local item = ProphetSummonGiftBagItem.new(tmp, self.data[i], self.scroller)
	end

	self.groupItem_uigrid:Reposition()
	self.itemCell:SetActive(false)
end

function ProphetSummonGiftBag:eventRegister()
	UIEventListener.Get(self.btn).onClick = function ()
		xyd.goWay(xyd.GoWayId.prophet)
	end

	self.eventProxyInner_:addEventListener(xyd.event.WINDOW_WILL_CLOSE, self.onWindowClose, self)
end

function ProphetSummonGiftBag:onWindowClose(event)
	if event.params.windowName == "prophet_window" then
		self:setItem()
		self:setText()
	end
end

function ProphetSummonGiftBag:checkIfMove()
	if #self.data * self.groupItem_uigrid.cellHeight <= self.scrollerPanel.height then
		self.scroller.enabled = false
	end
end

function ProphetSummonGiftBagItem:ctor(goItem, itemdata, scroller)
	self.goItem_ = goItem
	self.scrollerView = scroller
	local transGo = goItem.transform
	self.id_ = tonumber(itemdata.id)
	self.ifLock_ = itemdata.ifLock
	self.imgbg = transGo:ComponentByName("e:Image", typeof(UITexture))
	self.progressBar_ = transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.labelTitle_ = transGo:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup_ = transGo:Find("itemsGroup")

	self:initItem(itemdata)
	self:initBaseInfo(itemdata)
end

function ProphetSummonGiftBagItem:initBaseInfo(itemdata)
	self.labelTitle_.text = __("SUMMON_GIFTBAG_TEXT01", itemdata.limit_point)
end

function ProphetSummonGiftBagItem:initItem(itemdata)
	if itemdata.isCompleted then
		self.progressBar_.value = 1
	else
		self.progressBar_.value = math.min(itemdata.point, itemdata.limit_point) / itemdata.limit_point
	end

	if itemdata.limit_point < itemdata.point or itemdata.isCompleted then
		self.progressDesc.text = itemdata.limit_point .. "/" .. itemdata.limit_point
	else
		self.progressDesc.text = itemdata.point .. "/" .. itemdata.limit_point
	end

	local awards = ActivityTreeTable:getAwards(self.id_)

	for i, reward in pairs(awards) do
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_.gameObject,
			dragScrollView = self.scrollerView
		})

		icon:setScale(0.6666666666666666)

		if itemdata.isCompleted then
			icon:setChoose(true)
		end
	end
end

return ProphetSummonGiftBag
