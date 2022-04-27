local ActivitySpaceExploreCheckAwardWindow = class("ActivitySpaceExploreCheckAwardWindow", import(".BaseWindow"))
local SpaceExploreAwardItem = class("SpaceExploreAwardItem", import("app.components.CopyComponent"))

function SpaceExploreAwardItem:ctor(go, parent)
	self.parent_ = parent
	self.itemList_ = {}

	SpaceExploreAwardItem.super.ctor(self, go)
end

function SpaceExploreAwardItem:initUI()
	SpaceExploreAwardItem.super.initUI(self)
	self:getComponent()
end

function SpaceExploreAwardItem:getComponent()
	self.labelNum_ = self.go:ComponentByName("labelNum", typeof(UILabel))
	self.itemGroup_ = self.go:ComponentByName("itemGroup", typeof(UIGrid))
end

function SpaceExploreAwardItem:update(_, _, id)
	if not id then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id_ = id
	local limitNum = xyd.tables.activitySpaceExploreAwardTable:getLImitNum(self.id_)
	self.labelNum_.text = limitNum
	local awardItem = xyd.tables.activitySpaceExploreAwardTable:getAward(self.id_)

	for idx, itemInfo in ipairs(awardItem) do
		if not self.itemList_[idx] then
			self.itemList_[idx] = xyd.getItemIcon({
				scale = 0.7037037037037037,
				uiRoot = self.itemGroup_.gameObject,
				itemID = itemInfo[1],
				num = itemInfo[2],
				dragScrollView = self.parent_.scrollView_
			})
		else
			NGUITools.Destroy(self.itemList_[idx]:getGameObject())

			self.itemList_[idx] = xyd.getItemIcon({
				scale = 0.7037037037037037,
				uiRoot = self.itemGroup_.gameObject,
				itemID = itemInfo[1],
				num = itemInfo[2],
				dragScrollView = self.parent_.scrollView_
			})
		end

		self.itemList_[idx]:getGameObject().transform:SetSiblingIndex(idx - 1)
		self.itemList_[idx]:setChoose(limitNum <= xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_SPACE_EXPLORE_CRYSTAL))
	end

	for idx, item in ipairs(self.itemList_) do
		if not awardItem[idx] then
			item:getGameObject():SetActive(false)
		else
			item:getGameObject():SetActive(true)
		end
	end

	self.itemGroup_:Reposition()
end

function ActivitySpaceExploreCheckAwardWindow:ctor(name, params)
	ActivitySpaceExploreCheckAwardWindow.super.ctor(self, name, params)

	self.itemNum_ = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_SPACE_EXPLORE_CRYSTAL)
end

function ActivitySpaceExploreCheckAwardWindow:initWindow()
	self:getUIComponent()
	self:layout()
end

function ActivitySpaceExploreCheckAwardWindow:getUIComponent()
	local go = self.window_:NodeByName("groupAction")
	self.titleLabel_ = go:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = go:NodeByName("closeBtn").gameObject
	self.costItemNum_ = go:ComponentByName("costGroup/labelNum", typeof(UILabel))
	self.labelText01_ = go:ComponentByName("groupContent/labelText1", typeof(UILabel))
	self.labelText02_ = go:ComponentByName("groupContent/labelText2", typeof(UILabel))
	self.scrollView_ = go:ComponentByName("groupContent/scrollView", typeof(UIScrollView))
	self.grid_ = go:ComponentByName("groupContent/scrollView/grid", typeof(MultiRowWrapContent))
	self.itemRoot_ = go:NodeByName("item_root").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, self.itemRoot_, SpaceExploreAwardItem, self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivitySpaceExploreCheckAwardWindow:layout()
	self.titleLabel_.text = __("SPACE_EXPLORE_AWARD_LABEL1")
	self.labelText01_.text = __("SPACE_EXPLORE_AWARD_LABEL2")
	self.labelText02_.text = __("LEV_UP_AWARD")
	self.costItemNum_.text = self.itemNum_
	local ids = xyd.tables.activitySpaceExploreAwardTable:getIds()

	table.sort(ids, function (a, b)
		local limitA = xyd.tables.activitySpaceExploreAwardTable:getLImitNum(a)
		local limitB = xyd.tables.activitySpaceExploreAwardTable:getLImitNum(b)
		local valueA = tonumber(a) + 100 * xyd.checkCondition(limitA <= self.itemNum_, 1, 0)
		local valueB = tonumber(b) + 100 * xyd.checkCondition(limitB <= self.itemNum_, 1, 0)

		return valueA < valueB
	end)
	self.multiWrap_:setInfos(ids, {})
end

return ActivitySpaceExploreCheckAwardWindow
