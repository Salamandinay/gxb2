local ActivityHw2022SummonDetailWindow = class("ActivityHw2022SummonDetailWindow", import(".BaseWindow"))
local CommonTabBar = import("app.common.ui.CommonTabBar")

function ActivityHw2022SummonDetailWindow:ctor(name, params)
	ActivityHw2022SummonDetailWindow.super.ctor(self, name, params)

	self.curIndex_ = 1
end

function ActivityHw2022SummonDetailWindow:initWindow()
	ActivityHw2022SummonDetailWindow.super.initWindow(self)
	self:getUIComponent()
	self:initNav()
	self:updateLayout()
end

function ActivityHw2022SummonDetailWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.navRoot_ = winTrans:NodeByName("nav").gameObject
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.labelTips1_ = winTrans:ComponentByName("scrollView/labelTips1", typeof(UILabel))
	self.labelTips2_ = winTrans:ComponentByName("scrollView/labelTips2", typeof(UILabel))
	self.itemGrid1_ = winTrans:ComponentByName("scrollView/itemGrid1", typeof(UIGrid))
	self.itemGrid2_ = winTrans:ComponentByName("scrollView/itemGrid2", typeof(UIGrid))
	self.itemRoot_ = winTrans:NodeByName("itemRoot").gameObject
	self.labelTips1_.text = __("ACTIVITY_HALLOWEEN2022_GAMBLE_PREVIEW01")

	if xyd.Global.lang == "ja_jp" then
		self.labelTips1_.width = 300
	end

	self.labelTips2_.text = __("ACTIVITY_HALLOWEEN2022_GAMBLE_PREVIEW02")
	self.titleLabel_.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_AWARD_PREVIEW")

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function ActivityHw2022SummonDetailWindow:initNav()
	self.tabBar = CommonTabBar.new(self.navRoot_, 2, function (index)
		self:changeTopTap(index)
	end)

	self.tabBar:setTexts({
		__("ACTIVITY_HALLOWEEN2022_GAMBLE_BUTTON02"),
		__("ACTIVITY_HALLOWEEN2022_GAMBLE_BUTTON03")
	})
end

function ActivityHw2022SummonDetailWindow:changeTopTap(index)
	if self.curIndex_ ~= index then
		self.curIndex_ = index

		self:updateLayout()
	end
end

function ActivityHw2022SummonDetailWindow:updateLayout()
	local awards = xyd.tables.activityHw2022GambleTable:getAwards(self.curIndex_)
	local weidgt = xyd.tables.activityHw2022GambleTable:getWeight(self.curIndex_)
	local dropboxID = xyd.tables.activityHw2022GambleTable:getDropboxID(self.curIndex_)

	NGUITools.DestroyChildren(self.itemGrid1_.transform)
	NGUITools.DestroyChildren(self.itemGrid2_.transform)

	local totalWeidgt = 0

	for _, value in ipairs(weidgt) do
		totalWeidgt = totalWeidgt + value
	end

	for index, award in ipairs(awards) do
		local newRoot = NGUITools.AddChild(self.itemGrid1_.gameObject, self.itemRoot_)
		local rateLabel = newRoot:ComponentByName("labelRate", typeof(UILabel))

		newRoot:SetActive(true)
		rateLabel.gameObject:SetActive(true)
		print("weidgt[index]   ", weidgt[index])

		rateLabel.text = math.floor(weidgt[index] / totalWeidgt * 1000) / 10 .. "%"

		xyd.getItemIcon({
			scale = 0.7962962962962963,
			uiRoot = newRoot,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.scrollView_
		})
	end

	self:waitForFrame(1, function ()
		self.itemGrid1_:Reposition()
	end)

	local info = xyd.tables.dropboxShowTable:getIdsByBoxId(dropboxID)
	local all_proba = info.all_weight
	local list = info.list
	local sort_func = nil

	if self.params then
		sort_func = self.params.sort_func
	end

	xyd.tables.dropboxShowTable:sort(list, sort_func)

	local collect = {}

	for i = 1, #list do
		local table_id = list[i]
		local weight = xyd.tables.dropboxShowTable:getWeight(table_id)

		if weight then
			table.insert(collect, {
				table_id = table_id,
				all_proba = all_proba
			})
		end
	end

	for index, item in ipairs(collect) do
		local newRoot = NGUITools.AddChild(self.itemGrid2_.gameObject, self.itemRoot_)

		newRoot:SetActive(true)

		local data = xyd.tables.dropboxShowTable:getItem(item.table_id)

		xyd.getItemIcon({
			scale = 0.7962962962962963,
			uiRoot = newRoot,
			itemID = data[1],
			num = data[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.scrollView_
		})
	end

	self:waitForFrame(1, function ()
		self.itemGrid2_:Reposition()
		self.scrollView_:ResetPosition()
	end)
end

return ActivityHw2022SummonDetailWindow
