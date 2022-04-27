local BaseWindow = import(".BaseWindow")
local SmashEggAwardWindow = class("SmashEggAwardWindow", BaseWindow)
local AwardItem = class("ProbabilityRender", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local AwardTable = xyd.tables.activitySmashEggAwardsTable

function SmashEggAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function SmashEggAwardWindow:initWindow()
	SmashEggAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function SmashEggAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelWinTitle = groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.labelDes = groupAction:ComponentByName("labelDes", typeof(UILabel))
	self.scrollView = groupAction:ComponentByName("mainGroup/scrollView", typeof(UIScrollView))
	self.awardGroup = groupAction:NodeByName("mainGroup/scrollView/awardGroup").gameObject
	self.awardItem = groupAction:NodeByName("mainGroup/scrollView/warm_up_award_item").gameObject
	local wrapContent = self.awardGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.awardItem, AwardItem, self)
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
end

function SmashEggAwardWindow:initUIComponent()
	self.labelDes.text = __("WEDDING_VOTE_TEXT_16")
	local ids = AwardTable:getIDs()
	local collection_ = {}

	for i, _ in pairs(ids) do
		table.insert(collection_, {
			id = ids[i],
			value = self.params_.values[i],
			is_completed = self.params_.is_completeds[i]
		})
	end

	table.sort(collection_, function (a, b)
		if a.is_completed == b.is_completed then
			return a.id < b.id
		else
			return a.is_completed < b.is_completed
		end
	end)
	self.wrapContent:setInfos(collection_, {})
end

function SmashEggAwardWindow:addTitle()
	self.labelWinTitle.text = __("DRIFT_BOTTLE_AWARD_WINDOW")
end

function AwardItem:ctor(go, parent)
	AwardItem.super.ctor(self, go, parent)
end

function AwardItem:initUI()
	local go = self.go
	self.labelReadyNum = go:ComponentByName("labelReadyNum", typeof(UILabel))
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.progress = go:ComponentByName("progress", typeof(UISlider))
	self.progressLabel = go:ComponentByName("progress/labelDisplay", typeof(UILabel))

	self:setDragScrollView()
end

function AwardItem:updateInfo()
	self.id = self.data.id
	self.value = self.data.value or 0
	self.is_completed = self.data.is_completed
	local value_ = AwardTable:getValue(self.id)
	local itemId = xyd.tables.activitySmashEggTable:getCost(value_[1])[1]
	self.labelReadyNum.text = __("DRIFT_BOTTLE_TEXT_06", value_[2], xyd.tables.itemTable:getName(itemId))

	NGUITools.DestroyChildren(self.awardGroup.transform)

	local awardData = AwardTable:getAwards(self.id)

	for i = 1, #awardData do
		local award = awardData[i]
		local item = xyd.getItemIcon({
			scale = 0.7037037037037037,
			not_show_ways = true,
			uiRoot = self.awardGroup,
			itemID = award[1],
			num = award[2],
			dragScrollView = self.parent.scrollView,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			isNew = xyd.tables.itemTable:getType(award[1]) == xyd.ItemType.SKIN
		})

		if self.is_completed == 1 then
			item:setChoose(true)
		else
			item:setChoose(false)
		end
	end

	self.awardGroup:GetComponent(typeof(UILayout)):Reposition()

	self.progress.value = self.value / value_[2]
	self.progressLabel.text = math.min(self.value, value_[2]) .. " / " .. value_[2]
end

return SmashEggAwardWindow
