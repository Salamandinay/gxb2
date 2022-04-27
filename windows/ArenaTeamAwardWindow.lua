local BaseWindow = import(".BaseWindow")
local ArenaTeamAwardWindow = class("ArenaTeamAwardWindow", BaseWindow)
local ArenaAwardItem = class("ArenaAwardItem", import("app.components.BaseComponent"))

function ArenaTeamAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model_ = xyd.models.arenaTeam
end

function ArenaTeamAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("groupAction").gameObject
	local topGroup = mainGroup:NodeByName("topGroup").gameObject
	self.backBtn = topGroup:NodeByName("backBtn").gameObject
	self.labelTitle = topGroup:ComponentByName("labelTitle", typeof(UILabel))
	local infoGroup = mainGroup:NodeByName("infoGroup").gameObject
	local awardGroup = infoGroup:NodeByName("awardGroup").gameObject
	local leftBg = awardGroup:ComponentByName("leftBg", typeof(UITexture))
	local rightBg = awardGroup:ComponentByName("rightBg", typeof(UITexture))

	xyd.setUITextureAsync(leftBg, "Textures/arena_web/arena_award_bg", function ()
	end)
	xyd.setUITextureAsync(rightBg, "Textures/arena_web/arena_award_bg", function ()
	end)

	self.labelRank = awardGroup:ComponentByName("labelRank", typeof(UILabel))
	self.nowAward = awardGroup:NodeByName("nowAward").gameObject
	self.labelDesc = infoGroup:ComponentByName("labelDesc", typeof(UILabel))
	self.scroller = infoGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.awardContainer = infoGroup:NodeByName("scroller/vs/awardContainer").gameObject
end

function ArenaTeamAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	local rank = self.model_:getRank()
	local selfAwardInfo = nil

	if rank > 0 then
		selfAwardInfo = xyd.tables.arenaRankAwardTeamTable:getRankInfo(self.model_:getRank())
		local flow = __("ARENA_TEAM_RANK_DESC_NEW", tostring(selfAwardInfo.rankText))
		self.labelRank.text = flow
	else
		local a_t = xyd.tables.arenaRankAwardTeamTable
		selfAwardInfo = a_t:getRankInfo(nil, a_t.ids_[#a_t.ids_])
		self.labelRank.text = __("ARENA_TEAM_AWARDS_NO_TEAM_TIPS")
	end

	self.labelDesc.text = __("ARENA_RANK_DESC2")
	self.labelTitle.text = __("AWARD2")

	self:layoutAward(selfAwardInfo)
	self:registerEvent()
end

function ArenaTeamAwardWindow:registerEvent()
	ArenaTeamAwardWindow.super.register(self)

	UIEventListener.Get(self.backBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ArenaTeamAwardWindow:layoutAward(selfAwardInfo)
	NGUITools.DestroyChildren(self.nowAward.transform)
	NGUITools.DestroyChildren(self.awardContainer.transform)

	for i = 1, #selfAwardInfo.award do
		local item = selfAwardInfo.award[i]
		local icon = xyd.getItemIcon({
			labelNumScale = 1.2,
			hideText = true,
			itemID = item.item_id,
			num = item.item_num,
			uiRoot = self.nowAward
		})
	end

	local a_t = xyd.tables.arenaRankAwardTeamTable

	for i = 1, #a_t.ids_ do
		local awardItem = ArenaAwardItem.new(self.awardContainer, self)

		awardItem:setInfo({
			colName = "award",
			id = i
		})
	end

	self.nowAward:GetComponent(typeof(UILayout)):Reposition()
	self.awardContainer:GetComponent(typeof(UILayout)):Reposition()
end

function ArenaTeamAwardWindow:getScrollerView()
	return self.scroller
end

function ArenaAwardItem:ctor(parentGo, parent)
	ArenaAwardItem.super.ctor(self, parentGo)

	self.parent = parent

	self:setDragScrollView(parent:getScrollerView())
	self:getUIComponent()
end

function ArenaAwardItem:getPrefabPath()
	return "Prefabs/Components/arena_team_award_item"
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
	local table = xyd.tables.arenaRankAwardTeamTable
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
			dragScrollView = self.parent:getScrollerView()
		})
	end

	self.awardGroupLayout:Reposition()
end

return ArenaTeamAwardWindow
