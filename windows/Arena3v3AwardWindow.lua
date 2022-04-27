local BaseWindow = import(".BaseWindow")
local Arena3v3AwardWindow = class("Arena3v3AwardWindow", BaseWindow)
local ArenaRankAward3v3Table = xyd.tables.arenaRankAward3v3Table
local Arena3v3 = xyd.models.arena3v3
local Arena = xyd.models.arena
local CountDown = import("app.components.CountDown")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local BaseComponent = import("app.components.BaseComponent")
local ArenaAwardItem = class("ArenaAwardItem", BaseComponent)
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ArenaAwardItem.new(go, parent.scrollView)

	self.item:setDragScrollView(parent.scrollView)
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

function Arena3v3AwardWindow:ctor(name, params)
	Arena3v3AwardWindow.super.ctor(self, name, params)

	self.model_ = Arena3v3
	self.awardList = {}
end

function Arena3v3AwardWindow:getUIComponent()
	local trans = self.window_.transform
	local main = trans:NodeByName("main").gameObject
	local title = main:NodeByName("title").gameObject
	self.closeBtn = title:NodeByName("backBtn").gameObject
	self.labelTitle = title:ComponentByName("labelTitle", typeof(UILabel))
	local content = main:NodeByName("content").gameObject
	self.labelDesc = content:ComponentByName("labelDesc", typeof(UILabel))
	self.clock = content:NodeByName("clock").gameObject
	local ddl1 = content:ComponentByName("ddl1", typeof(UILabel))
	self.ddl1 = CountDown.new(ddl1)
	local ddl2 = content:ComponentByName("ddl2Num", typeof(UILabel))
	self.ddl2Num = CountDown.new(ddl2)
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

function Arena3v3AwardWindow:initWindow()
	Arena3v3AwardWindow.super.initWindow(self)
	self:getUIComponent()

	local effect = xyd.Spine.new(self.clock)

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao1", 0)
	end)

	local selfAwardInfo = ArenaRankAward3v3Table:getRankInfo(self.model_:getRank())
	self.labelTitle.text = __("AWARD2")
	self.labelRank.text = tostring(__("NOW_RANK")) .. ": " .. tostring(selfAwardInfo.rankText)
	self.labelNowAward.text = __("NOW_AWARD")
	self.labelTopRank.text = tostring(__("TOP_RANK")) .. ":"
	self.topRank.text = __(self.model_:getTopRank())
	self.labelDesc.text = __("ARENA_RANK_DESC2")

	if xyd.Global.lang == "fr_fr" then
		self.labelRank.text = tostring(__("NOW_RANK")) .. " : " .. tostring(selfAwardInfo.rankText)
		self.labelTopRank.text = tostring(__("TOP_RANK")) .. " :"

		self.nowAward:X(0)
	end

	self:updateDDL1()
	self:updateDDL2()
	self.ddl2:SetActive(false)
	self:layoutAward(selfAwardInfo)
	self:registerEvent()
end

function Arena3v3AwardWindow:registerEvent()
	Arena3v3AwardWindow.super.register(self)
end

function Arena3v3AwardWindow:layoutAward(selfAwardInfo)
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

	local a_t = ArenaRankAward3v3Table

	for i = 1, #a_t.ids_ do
		table.insert(self.awardList, {
			colName = "award",
			id = i
		})
	end

	self.wrapContent:setInfos(self.awardList, {})
end

function Arena3v3AwardWindow:updateDDL1()
	local ddl = Arena3v3:getDDL()
	local endTime = ddl - xyd.getServerTime()

	self.ddl1:setInfo({
		duration = endTime
	})
end

function Arena3v3AwardWindow:updateDDL2()
	local ddl = Arena:getDDL()
	local endTime = ddl - xyd.getServerTime()

	if endTime / 3600 > 24 then
		self.ddl2 = self.ddl2Text

		self.ddl2Num:SetActive(false)
		self.ddl2:SetActive(true)

		self.ddl2.text = xyd.getRoughDisplayTime(endTime)
	else
		self.ddl2 = self.ddl2Num

		self.ddl2Text:SetActive(false)
		self.ddl2:SetActive(true)
		self.ddl2:setInfo({
			duration = endTime
		})
	end
end

function ArenaAwardItem:ctor(parentGo, scrollView)
	ArenaAwardItem.super.ctor(self, parentGo)

	self.scrollView = scrollView

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
	local table = xyd.tables.arenaRankAward3v3Table
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
			dragScrollView = self.scrollView
		})

		icon:SetLocalScale(0.7, 0.7, 1)
	end

	self.awardGroupLayout:Reposition()
end

return Arena3v3AwardWindow
