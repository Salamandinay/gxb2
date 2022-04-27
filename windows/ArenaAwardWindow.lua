local BaseWindow = import(".BaseWindow")
local ArenaAwardWindow = class("ArenaAwardWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local BaseComponent = import("app.components.BaseComponent")
local ArenaAwardItem = class("ArenaAwardItem", BaseComponent)
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ArenaAwardItem.new(go, parent.navScroller1)

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

function ArenaAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "ArenaAwardWindowSkin"
	self.model_ = xyd.models.arena
	self.awardList = {}
	self.seasonAwardList = {}
	self.table = xyd.tables.arenaRankAwardTable

	if xyd.models.arena:getIsOld() ~= nil then
		self.table = xyd.tables.arenaRankNewAwardTable
	end
end

function ArenaAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	xyd.setUITextureAsync(self.bgImage1, "Textures/arena_web/arena_award_bg")
	xyd.setUITextureAsync(self.bgImage2, "Textures/arena_web/arena_award_bg")

	self.labelNav1 = self.nav1Label
	self.labelNav2 = self.nav2Label
	local selfAwardInfo = self.table:getRankInfo(self.model_:getRank())
	self.labelTitle.text = __("AWARD2")
	self.labelRank.text = tostring(__("NOW_RANK")) .. ": " .. tostring(selfAwardInfo.rankText)
	self.labelNowAward.text = __("NOW_AWARD")
	self.labelTopRank.text = tostring(__("TOP_RANK")) .. ":"
	self.labelNav1.text = __("DAILY_AWARD")
	self.labelNav2.text = __("SEASON_AWARD")

	self.vsSelfAward:X(self.labelNowAward.transform.localPosition.x + self.labelNowAward.width + 45)

	if xyd.Global.lang == "fr_fr" then
		self.topRank.fontSize = 20
		self.labelTopRank.fontSize = 20

		self.topRankGroup:X(300)

		self.labelRank.text = tostring(__("NOW_RANK")) .. " : " .. tostring(selfAwardInfo.rankText)
		self.labelTopRank.text = tostring(__("TOP_RANK")) .. " :"
		self.labelRank.fontSize = 20

		self.labelRank:X(-310)
		self.labelNowAward:X(-310)
	end

	local effect = xyd.Spine.new(self.clock.gameObject)

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao1", 0)
	end)

	self.topRank.text = __(self.model_:getTopRank())

	self:updateDDL1()
	self:updateDDL2()
	self:onclickNav(1)
	self.ddl2:SetActive(false)
	self:layoutAward(selfAwardInfo)
	self:register()
end

function ArenaAwardWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	local titleGroup = content:NodeByName("titleGroup").gameObject
	self.backBtn = titleGroup:NodeByName("backBtn").gameObject
	self.labelTitle = titleGroup:ComponentByName("labelTitle", typeof(UILabel))
	local topGroup = content:NodeByName("topGroup").gameObject
	self.nav1 = topGroup:NodeByName("nav1").gameObject
	self.nav1Label = self.nav1:ComponentByName("label", typeof(UILabel))
	self.nav2 = topGroup:NodeByName("nav2").gameObject
	self.nav2Label = self.nav2:ComponentByName("label", typeof(UILabel))
	local middleGroup = topGroup:NodeByName("middleGroup").gameObject
	local rankGroup = middleGroup:NodeByName("rankGroup").gameObject
	self.bgImage1 = rankGroup:ComponentByName("bgImage1", typeof(UITexture))
	self.bgImage2 = rankGroup:ComponentByName("bgImage2", typeof(UITexture))
	self.labelRank = rankGroup:ComponentByName("labelRank", typeof(UILabel))
	local group = rankGroup:NodeByName("group").gameObject
	self.topRankGroup = group
	self.labelTopRank = group:ComponentByName("labelTopRank", typeof(UILabel))
	self.topRank = group:ComponentByName("topRank", typeof(UILabel))
	self.labelNowAward = rankGroup:ComponentByName("labelNowAward", typeof(UILabel))
	self.vsSelfAward = rankGroup:NodeByName("vsSelfAward").gameObject
	self.nowAward = self.vsSelfAward:NodeByName("nowAward").gameObject
	self.nowSeasonAward = self.vsSelfAward:NodeByName("nowSeasonAward").gameObject
	self.labelDesc = middleGroup:ComponentByName("labelDesc", typeof(UILabel))
	self.clock = middleGroup:ComponentByName("clock", typeof(UITexture))
	local ddl1Label = middleGroup:ComponentByName("ddl1", typeof(UILabel))
	self.ddl1 = CountDown.new(ddl1Label)
	local ddl2NumLabel = middleGroup:ComponentByName("ddl2Num", typeof(UILabel))
	self.ddl2Num = CountDown.new(ddl2NumLabel)
	self.ddl2Text = middleGroup:ComponentByName("ddl2Text", typeof(UILabel))
	self.navScroller1 = content:ComponentByName("navScroller1", typeof(UIScrollView))
	local wrapContent1 = self.navScroller1:ComponentByName("awardContainer1", typeof(UIWrapContent))
	local iconContainer1 = self.navScroller1:NodeByName("iconContainer1").gameObject
	self.wrapContent1 = FixedWrapContent.new(self.navScroller1, wrapContent1, iconContainer1, ItemRender, self)
end

function ArenaAwardWindow:layoutAward(selfAwardInfo)
	NGUITools.DestroyChildren(self.nowAward.transform)
	NGUITools.DestroyChildren(self.nowSeasonAward.transform)
	dump(selfAwardInfo.award)

	for i = 1, #selfAwardInfo.award do
		local item = selfAwardInfo.award[i]
		local icon = xyd.getItemIcon({
			labelNumScale = 1.6,
			hideText = true,
			uiRoot = self.nowAward,
			itemID = item.item_id,
			num = item.item_num
		})

		icon:SetLocalScale(0.7, 0.7, 1)
	end

	local arenaIsLast = xyd.models.arena:getIsLast()
	local isLast = false

	if xyd.models.arena:getIsOld() == nil and arenaIsLast ~= nil and arenaIsLast == 1 then
		isLast = true
	end

	for i = 1, #selfAwardInfo.seasonAward do
		local item = selfAwardInfo.seasonAward[i]
		local param = {
			labelNumScale = 1.6,
			hideText = true,
			uiRoot = self.nowSeasonAward,
			itemID = item.item_id,
			num = item.item_num
		}

		if isLast then
			local timeDis = xyd.models.arena:getDDL() + 1 - xyd.models.arena:getStartTime()

			if timeDis > 0 then
				local timeDisDay = math.ceil(timeDis / xyd.DAY_TIME)
				param.num = math.floor(param.num * timeDisDay / 15)
			end
		end

		local icon = xyd.getItemIcon(param)

		icon:SetLocalScale(0.7, 0.7, 1)
	end

	local a_t = self.table

	for i = 1, #a_t.ids_ do
		table.insert(self.awardList, {
			colName = "award",
			id = i
		})
		table.insert(self.seasonAwardList, {
			colName = "seasonAward",
			id = i
		})
	end

	self.wrapContent1:setInfos(self.awardList, {})
end

function ArenaAwardWindow:register()
	UIEventListener.Get(self.backBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.nav1).onClick = function ()
		self:onclickNav(1)
	end

	UIEventListener.Get(self.nav2).onClick = function ()
		self:onclickNav(2)
	end
end

function ArenaAwardWindow:setNavState(index, state)
	local nav = self["nav" .. index]
	local label = self["nav" .. index .. "Label"]
	local sprite = nav:GetComponent(typeof(UISprite))

	if state == "selected" then
		xyd.setUISprite(sprite, nil, "blue_btn_65_65")

		label.color = Color.New2(4294967295.0)
		label.effectColor = Color.New2(473916927)
	else
		xyd.setUISprite(sprite, nil, "white_btn_65_65")

		label.color = Color.New2(960513791)
		label.effectColor = Color.New2(4294967295.0)
	end
end

function ArenaAwardWindow:onclickNav(index)
	self.labelDesc.text = __("ARENA_RANK_DESC" .. tostring(index))

	if index == 1 then
		self.nowAward:SetActive(true)
		self.nowSeasonAward:SetActive(false)
	else
		self.nowAward:SetActive(false)
		self.nowSeasonAward:SetActive(true)
	end

	self:setNavState(index, "selected")
	self:setNavState(3 - index, "unSelected")
	self["ddl" .. tostring(index)]:SetActive(true)
	self["ddl" .. tostring(3 - index)]:SetActive(false)

	if index == 1 then
		self.wrapContent1:setInfos(self.awardList, {})
	else
		self.wrapContent1:setInfos(self.seasonAwardList, {})
	end
end

function ArenaAwardWindow:updateDDL1()
	local serverTime = xyd.getServerTime()
	local t1 = xyd.getGMTWeekStartTime(serverTime)
	local weekday = xyd.getGMTWeekDay(serverTime)
	local endTime = t1 + (weekday - 1) * 24 * 3600 - 10800 - serverTime

	while endTime < 0 do
		endTime = endTime + 86400
	end

	self.ddl1:setInfo({
		duration = endTime
	})
end

function ArenaAwardWindow:updateDDL2()
	local ddl = xyd.models.arena:getDDL()
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
	local table = xyd.tables.arenaRankAwardTable

	if xyd.models.arena:getIsOld() ~= nil then
		table = xyd.tables.arenaRankNewAwardTable
	end

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

	local arenaIsLast = xyd.models.arena:getIsLast()
	local isLast = false

	if xyd.models.arena:getIsOld() == nil and arenaIsLast ~= nil and arenaIsLast == 1 then
		isLast = true
	end

	NGUITools.DestroyChildren(self.awardGroup.transform)

	for i = 1, #info[colName] do
		local item = info[colName][i]
		local param = {
			noClickSelected = true,
			labelNumScale = 1.2,
			hideText = true,
			uiRoot = self.awardGroup,
			itemID = item.item_id,
			num = item.item_num,
			dragScrollView = self.scrollView
		}

		if colName == "seasonAward" and isLast then
			local timeDis = xyd.models.arena:getDDL() + 1 - xyd.models.arena:getStartTime()

			if timeDis > 0 then
				local timeDisDay = math.ceil(timeDis / xyd.DAY_TIME)
				param.num = math.floor(param.num * timeDisDay / 15)
			end
		end

		local icon = xyd.getItemIcon(param)

		icon:SetLocalScale(0.7, 0.7, 1)
	end

	if #info[colName] == 3 then
		self.awardGroup.gameObject:X(0)
	elseif #info[colName] == 4 then
		self.awardGroup.gameObject:X(-40)
	end

	self.awardGroupLayout:Reposition()
end

return ArenaAwardWindow
