local ActivitySportsRank1Window = class("ActivitySportsRank1Window", import(".BaseWindow"))
local CountDown = import("app.components.CountDown")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local BaseComponent = import("app.components.BaseComponent")
local ArenaAwardItem = class("ArenaAwardItem", BaseComponent)
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ArenaAwardItem.new(go, self.parent)

	self.item:setDragScrollView(parent.navScroller1)
end

function ItemRender:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.item.data = info

	self.go:SetActive(true)
	self.item:setInfo(info)
end

function ItemRender:getGameObject()
	return self.go
end

function ActivitySportsRank1Window:ctor(name, params)
	ActivitySportsRank1Window.super.ctor(self, name, params)

	self.awardList = {}
	self.activityData = params.activityData
	self.timeState = self.activityData:getNowState()

	self:getGroupRankNum()
end

function ActivitySportsRank1Window:getGroupRankNum()
	self.groupRankNum = 1
	local groupPoint = self.activityData.detail.all_group_points[self.activityData.detail.arena_info.group]

	for i = 1, #self.activityData.detail.all_group_points do
		if groupPoint < self.activityData.detail.all_group_points[i] then
			self.groupRankNum = self.groupRankNum + 1
		end
	end
end

function ActivitySportsRank1Window:getUIComponent()
	local trans = self.window_.transform
	local main = trans:NodeByName("main").gameObject
	local title = main:NodeByName("title").gameObject
	self.closeBtn = title:NodeByName("backBtn").gameObject
	self.labelTitle = title:ComponentByName("labelTitle", typeof(UILabel))
	local content = main:NodeByName("content").gameObject
	self.labelDesc = content:ComponentByName("labelDesc", typeof(UILabel))
	self.clock = content:NodeByName("clock").gameObject
	self.ddl1UILabel = content:ComponentByName("ddl1", typeof(UILabel))
	self.ddl1 = CountDown.new(self.ddl1UILabel)
	local ddl2 = content:ComponentByName("ddl2Num", typeof(UILabel))

	ddl2:SetActive(false)

	self.ddl2Text = content:ComponentByName("ddl2Text", typeof(UILabel))
	self.scrollView = content:ComponentByName("scrollview", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("awardContainer", typeof(UIWrapContent))
	local iconContainer = self.scrollView:NodeByName("iconContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, iconContainer, ItemRender, self)
	local top = content:NodeByName("top").gameObject
	self.bg = top:ComponentByName("bg", typeof(UITexture))
	self.bg2 = top:ComponentByName("bg2", typeof(UITexture))
	self.labelRank = top:ComponentByName("labelRank", typeof(UILabel))
	self.labelTopRank = top:ComponentByName("labelTopRank", typeof(UILabel))
	self.topRank = top:ComponentByName("topRank", typeof(UILabel))
	self.labelNowAward = top:ComponentByName("labelNowAward", typeof(UILabel))
	self.nowAward = top:NodeByName("nowAward").gameObject
end

function ActivitySportsRank1Window:initWindow()
	ActivitySportsRank1Window.super.initWindow(self)
	self:getUIComponent()

	local effect = xyd.Spine.new(self.clock)

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao1", 0)
	end)

	local selfAwardInfo = xyd.tables.activitySportsRankAward3Table:getRankInfo(self.groupRankNum)
	self.labelTitle.text = __("AWARD2")
	self.labelRank.text = tostring(__("NOW_RANK")) .. " : " .. tostring(selfAwardInfo.rankText)

	self.labelRank.gameObject:Y(42)

	self.labelNowAward.text = __("NOW_AWARD")

	self.labelNowAward.gameObject:SetLocalPosition(-296, -20, 0)

	self.labelNowAward.overflowMethod = UILabel.Overflow.ShrinkContent
	self.labelNowAward.width = 240
	self.labelTopRank.text = tostring(__("TOP_RANK")) .. ":"
	self.topRank.text = __(1)
	self.labelDesc.text = __("COUNT_DOWN_BY_MAIL")

	self:updateDDL1()
	self.ddl2Text.gameObject:SetActive(false)
	self:layoutAward(selfAwardInfo)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivitySportsRank1Window:updateDDL1()
	local ddl = self.activityData.end_time - 86400
	local endTime = ddl - xyd.getServerTime()

	if endTime > 0 then
		self.ddl1:setInfo({
			duration = endTime
		})
	else
		self.clock.gameObject:SetActive(false)

		self.ddl1UILabel.text = " "
	end
end

function ActivitySportsRank1Window:layoutAward(selfAwardInfo)
	for i = 1, #selfAwardInfo.award do
		local item = selfAwardInfo.award[i]
		local icon = xyd.getItemIcon({
			labelNumScale = 1.6,
			hideText = true,
			scale = 0.7,
			itemID = item.item_id,
			num = item.item_num,
			uiRoot = self.nowAward
		})
	end

	local a_t = xyd.tables.activitySportsRankAward3Table
	local ids = a_t:getIds()

	for i = 1, #ids do
		table.insert(self.awardList, {
			colName = "award",
			id = i,
			table = a_t
		})
	end

	self.wrapContent:setInfos(self.awardList, {})
end

function ArenaAwardItem:ctor(parentGo, parent)
	self.parent_ = parent

	ArenaAwardItem.super.ctor(self, parentGo)

	self.skinName = "ArenaAwardItemSkin"

	self:getUIComponent()
end

function ArenaAwardItem:getPrefabPath()
	return "Prefabs/Components/arena_award_item"
end

function ArenaAwardItem:getUIComponent()
	local go = self.go
	self.imgRank = go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.awardGroupLayout = self.awardGroup:GetComponent(typeof(UILayout))
end

function ArenaAwardItem:setInfo(data)
	local id = data.id
	local colName = data.colName
	local table = data.table
	local info = table:getRankInfo(nil, id)

	if info.rank <= 3 then
		self.imgRank:SetActive(true)
		xyd.setUISpriteAsync(self.imgRank, nil, "rank_icon0" .. info.rank)
		self.labelRank:SetActive(false)
	else
		self.imgRank:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = info.rankText
	end

	NGUITools.DestroyChildren(self.awardGroup.transform)

	for i = 1, #info[colName] do
		local item = info[colName][i]
		local icon = xyd.getItemIcon({
			noClickSelected = true,
			labelNumScale = 1.2,
			hideText = true,
			uiRoot = self.awardGroup,
			itemID = item.item_id,
			num = item.item_num,
			dragScrollView = self.parent_.scrollView
		})

		icon:SetLocalScale(0.7, 0.7, 1)
	end

	self.awardGroupLayout:Reposition()
end

return ActivitySportsRank1Window
