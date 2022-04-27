local ActivitySearchBook = class("ActivitySearchBook", import(".ActivityContent"))
local ActivitySearchBookItem = class("ActivitySearchBookItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function ActivitySearchBook:ctor(parentGo, params, parent)
	ActivitySearchBook.super.ctor(self, parentGo, params, parent)
end

function ActivitySearchBook:getPrefabPath()
	return "Prefabs/Windows/activity/activity_search_book"
end

function ActivitySearchBook:initUI()
	self:getUIComponent()
	ActivitySearchBook.super.initUI(self)
	xyd.setUISpriteAsync(self.logo, nil, "activity_search_book_logo_" .. tostring(xyd.Global.lang), nil, , true)

	self.textLabel.text = __("NEW_TRIAL_MON")
	self.endLabel.text = __("TEXT_END")
	local duration = self.activityData:getUpdateTime() - xyd.getServerTime()

	if duration < 0 then
		self.endLabel:SetActive(false)
		self.timeLabel:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.timeLabel)

		timeCount:setInfo({
			duration = duration
		})
	end

	self.wrapContent_ = FixedWrapContent.new(self.scrollView, self.wrapContent, self.cloneItem, ActivitySearchBookItem, self)

	self:setItem()
end

function ActivitySearchBook:getUIComponent()
	local go = self.go
	self.logo = go:ComponentByName("logo", typeof(UISprite))
	self.textLabel = go:ComponentByName("textLabel", typeof(UILabel))
	self.timeLabel = go:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = go:ComponentByName("endLabel", typeof(UILabel))
	self.scrollView = go:ComponentByName("scroller_", typeof(UIScrollView))
	self.wrapContent = self.scrollView:ComponentByName("groupContent", typeof(UIWrapContent))
	self.cloneItem = go:NodeByName("cloneItem").gameObject
end

function ActivitySearchBook:setItem()
	local ids = xyd.tables.activitySearchBookTable:getIDs()
	local itemList = {}

	for _, id in pairs(ids) do
		local is_completed = false

		if xyd.tables.activitySearchBookTable:getCompleteValue(id) <= self:getPoint(id) then
			is_completed = true
		end

		local item = {
			id = id,
			isCompleted = is_completed,
			point = self:getPoint(id),
			get_way = xyd.tables.activitySearchBookTable:getJumpWay(id)
		}

		table.insert(itemList, item)
	end

	self.wrapContent_:setInfos(itemList, {})
end

function ActivitySearchBook:getPoint(id)
	local type = xyd.tables.activitySearchBookTable:getType(id)

	return self.activityData.detail["point_" .. type]
end

function ActivitySearchBookItem:ctor(go, parent)
	ActivitySearchBookItem.super.ctor(self, go, parent)
end

function ActivitySearchBookItem:initUI()
	local go = self.go
	self.bg_ = go:NodeByName("bg_").gameObject
	self.progressPrize = go:ComponentByName("progressPrize", typeof(UIProgressBar))
	self.progressLabel = self.progressPrize:ComponentByName("progressLabel", typeof(UILabel))
	self.descLabel = go:ComponentByName("descLabel", typeof(UILabel))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
end

function ActivitySearchBookItem:updateInfo()
	self.descLabel.text = xyd.tables.activitySearchBookTable:getDesc(self.data.id)
	local max = xyd.tables.activitySearchBookTable:getCompleteValue(self.data.id)
	local cur = math.min(self.data.point, max)
	self.getWayId_ = self.data.get_way
	self.progressPrize.value = cur / max
	self.progressLabel.text = cur .. "/" .. max

	self:setIcon()

	if self.getWayId_ and tonumber(self.getWayId_) > 0 then
		local function onClick()
			xyd.goWay(self.getWayId_, nil, , )
		end

		UIEventListener.Get(self.go.gameObject).onClick = onClick
	end
end

function ActivitySearchBookItem:setIcon()
	if self.id == self.data.id then
		return
	end

	self.id = self.data.id
	local awards = xyd.tables.activitySearchBookTable:getAwards(self.data.id)

	NGUITools.DestroyChildren(self.groupIcon.transform)

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = xyd.getItemIcon({
				show_has_num = true,
				labelNumScale = 1.2,
				scale = 0.7,
				uiRoot = self.groupIcon,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			if self.data.isCompleted then
				item:setChoose(true)
			end
		end
	end
end

return ActivitySearchBook
