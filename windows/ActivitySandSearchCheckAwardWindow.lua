local ActivitySandSearchCheckAwardWindow = class("ActivitySandSearchCheckAwardWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local AwardItem = class("AwardItem", import("app.components.CopyComponent"))
local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SAND_SEARCH)

function AwardItem:ctor(go, parent)
	self.parent_ = parent
	self.itemList_ = {}

	AwardItem.super.ctor(self, go)
end

function AwardItem:initUI()
	AwardItem.super.initUI(self)
	self:getUIComponent()
end

function AwardItem:getUIComponent()
	local goTrans = self.go.transform
	self.labelRound_ = goTrans:ComponentByName("labelRound", typeof(UILabel))

	for i = 1, 3 do
		self["itemRoot" .. i] = goTrans:NodeByName("itemRoot" .. i).gameObject
	end
end

function AwardItem:update(_, id)
	if not id then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.labelRound_.text = id

	if id >= 31 then
		self.labelRound_.text = "31+"
	end

	local point = activityData:getPoint()
	local stage_id = activityData:getStageID()
	local pointStage = xyd.tables.activitySandSearchAwardTable:getPointStage()

	for i = 1, 3 do
		local awardItem = xyd.tables.activitySandSearchAwardTable:getAward(id, i)

		NGUITools.DestroyChildren(self["itemRoot" .. i].transform)
		self:waitForFrame(1, function ()
			self.itemList_[i] = xyd.getItemIcon({
				notShowGetWayBtn = true,
				scale = 0.7037037037037037,
				uiRoot = self["itemRoot" .. i],
				itemID = awardItem[1],
				num = awardItem[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent_.scrollView_
			})

			if (id < stage_id or stage_id == id and pointStage[i] <= point) and id < 31 then
				self.itemList_[i]:setChoose(true)
			else
				self.itemList_[i]:setChoose(false)
			end
		end)
	end
end

function ActivitySandSearchCheckAwardWindow:ctor(name, params)
	ActivitySandSearchCheckAwardWindow.super.ctor(self, name, params)
end

function ActivitySandSearchCheckAwardWindow:initWindow()
	self:getUIComponent()
	self:layout()
end

function ActivitySandSearchCheckAwardWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLbale_ = winTrans:ComponentByName("titleLbale", typeof(UILabel))
	self.contentGroup_ = winTrans:NodeByName("contentGroup").gameObject
	self.labelTips1_ = winTrans:ComponentByName("labelTips1", typeof(UILabel))
	self.labelTips2_ = winTrans:ComponentByName("labelTips2", typeof(UILabel))
	self.scrollView_ = self.contentGroup_:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = self.contentGroup_:ComponentByName("scrollView/grid", typeof(UIWrapContent))
	self.item_ = self.contentGroup_:NodeByName("awardItem").gameObject

	for i = 1, 3 do
		self["scoreLabel" .. i] = self.contentGroup_:ComponentByName("scoreLable" .. i, typeof(UILabel))
	end

	self.boxWrapContent = FixedWrapContent.new(self.scrollView_, self.grid_, self.item_, AwardItem, self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function ActivitySandSearchCheckAwardWindow:layout()
	local pointStage = xyd.tables.activitySandSearchAwardTable:getPointStage()

	for i = 1, 3 do
		self["scoreLabel" .. i].text = pointStage[i]
	end

	self.titleLbale_.text = __("ACTIVITY_SAND_TEXT05")
	self.labelTips1_.text = __("ACTIVITY_SAND_TEXT06")
	self.labelTips2_.text = __("ACTIVITY_SAND_TEXT07")
	local idList = {}

	for i = 1, 31 do
		idList[i] = i
	end

	self.boxWrapContent:setInfos(idList, {})
end

return ActivitySandSearchCheckAwardWindow
