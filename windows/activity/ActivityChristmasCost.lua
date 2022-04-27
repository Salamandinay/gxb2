local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ActivityChristmasCost = class("ActivityChristmasCost", ActivityContent)
local ActivityChristmasCostItem = class("ValueGiftBagItem", import("app.components.CopyComponent"))

function ActivityChristmasCost:ctor(parentGO, params, parent)
	ActivityChristmasCost.super.ctor(self, parentGO, params, parent)
end

function ActivityChristmasCost:getPrefabPath()
	return "Prefabs/Windows/activity/christmas_cost"
end

function ActivityChristmasCost:initUI()
	self:getUIComponent()
	ActivityChristmasCost.super.initUI(self)
	self:initUIComponent()
end

function ActivityChristmasCost:getUIComponent()
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
	self.costLabel = self.activityGroup:ComponentByName("costGroup/label", typeof(UILabel))
	self.costBtn = self.activityGroup:NodeByName("costGroup/btn").gameObject
	self.itemCell = go:NodeByName("itemCell").gameObject
end

function ActivityChristmasCost:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "christmas_cost_title_" .. xyd.Global.lang, nil, , true)
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
end

function ActivityChristmasCost:setText()
	if xyd.Global.lang == "de_de" then
		self.textLabel.width = 450
	end

	self.endLabel.text = __("TEXT_END")
	self.textLabel.text = __("ACTIVITY_SOCKS_AWARD_TEXT")
	self.costLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.CHRISTMAS_SOCK_2)
end

function ActivityChristmasCost:setItem()
	local ids = xyd.tables.activityChristmasSocksAwardTable:getIDs()
	local awards = {}

	for i = 1, #ids do
		table.insert(awards, {
			awards = xyd.tables.activityChristmasSocksAwardTable:getAwards(ids[i]),
			point = xyd.tables.activityChristmasSocksAwardTable:getPoint(ids[i]),
			curPoint = self.activityData.detail.times
		})
	end

	table.sort(awards, function (a, b)
		local maxPoint = xyd.tables.activityChristmasSocksAwardTable:getPoint(xyd.tables.activityChristmasSocksAwardTable:getIDs()[#xyd.tables.activityChristmasSocksAwardTable:getIDs()])

		if a.point <= math.fmod(a.curPoint, maxPoint) == (b.point <= math.fmod(b.curPoint, maxPoint)) then
			return a.point < b.point
		else
			return math.fmod(a.curPoint, maxPoint) < a.point
		end
	end)
	NGUITools.DestroyChildren(self.groupItem.transform)

	for i in ipairs(awards) do
		local tmp = NGUITools.AddChild(self.groupItem, self.itemCell)
		local item = ActivityChristmasCostItem.new(tmp, awards[i], self.scroller)
	end

	self.groupItem_uigrid:Reposition()
	self.itemCell:SetActive(false)
end

function ActivityChristmasCost:eventRegister()
	UIEventListener.Get(self.costBtn).onClick = function ()
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType2(xyd.ActivityID.ACTIVITY_SANTA_VISIT),
			select = xyd.ActivityID.ACTIVITY_SANTA_VISIT
		})
	end
end

function ActivityChristmasCost:resizeToParent()
	ActivityChristmasCost.super.resizeToParent(self)
end

function ActivityChristmasCostItem:ctor(goItem, itemdata, scroller)
	self.goItem_ = goItem
	self.scrollerView = scroller
	local transGo = goItem.transform
	self.imgbg = transGo:ComponentByName("e:Image", typeof(UITexture))
	self.progressBar_ = transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.labelTitle_ = transGo:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup_ = transGo:Find("itemsGroup")

	self:initItem(itemdata)
end

function ActivityChristmasCostItem:initItem(itemdata)
	self.progressBar_.value = math.min(itemdata.point, itemdata.curPoint) / itemdata.point
	local max = itemdata.point
	self.progressDesc.text = itemdata.curPoint .. "/" .. max

	if xyd.Global.lang == "fr_fr" then
		self.labelTitle_.fontSize = 22
	end

	self.labelTitle_.text = __("ACTIVITY_SOCKS_GAMBLE_AWARD", itemdata.point)

	for _, reward in pairs(itemdata.awards) do
		local params = {
			show_has_num = true,
			showGetWays = false,
			isActiveFrameEffect = false,
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_.gameObject,
			dragScrollView = self.scrollerView,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		if xyd.tables.itemTable:getIcon(params.itemID) == "artfact_115" then
			params.isNew = true
		end

		local icon = xyd.getItemIcon(params)

		icon:setScale(0.7)

		if itemdata.point <= itemdata.curPoint then
			icon:setChoose(true)
		end
	end
end

return ActivityChristmasCost
