local ArenaAllScoreServerAwardWindow = class("ArenaAllScoreServerAwardWindow", import(".BaseWindow"))
local CountDown = import("app.components.CountDown")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CopyComponent = import("app.components.CopyComponent")
local ArenaAllScoreServerAwardItem = class(" ArenaAllScoreServerAwardItem", CopyComponent)

function ArenaAllScoreServerAwardWindow:ctor(name, params)
	ArenaAllScoreServerAwardWindow.super.ctor(self, name, params)

	self.awardList = {}
end

function ArenaAllScoreServerAwardWindow:getUIComponent()
	local trans = self.window_.transform
	local groupAction = trans:NodeByName("groupAction").gameObject
	local title = groupAction:NodeByName("title").gameObject
	self.closeBtn = title:NodeByName("backBtn").gameObject
	self.labelTitle = title:ComponentByName("labelTitle", typeof(UILabel))
	local content = groupAction:NodeByName("content").gameObject
	self.labelDesc = content:ComponentByName("labelDesc", typeof(UILabel))
	self.clock = content:NodeByName("clock").gameObject
	local ddl1 = content:ComponentByName("ddl1", typeof(UILabel))
	self.ddl1Text = content:ComponentByName("ddl1", typeof(UILabel))
	self.ddl1 = CountDown.new(ddl1)
	local ddl2 = content:ComponentByName("ddl2Num", typeof(UILabel))

	ddl2:SetActive(false)

	self.ddl2Text = content:ComponentByName("ddl2Text", typeof(UILabel))
	self.scrollView = content:ComponentByName("scrollview", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("awardContainer", typeof(UIWrapContent))
	local arena_all_score_server_award_item = groupAction:NodeByName("arena_all_score_server_award_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, arena_all_score_server_award_item, ArenaAllScoreServerAwardItem, self)
	local top = content:NodeByName("top").gameObject
	self.bg = top:ComponentByName("bg", typeof(UITexture))
	self.bg2 = top:ComponentByName("bg2", typeof(UITexture))
	self.labelRank = top:ComponentByName("labelRank", typeof(UILabel))
	self.labelTopRank = top:ComponentByName("labelTopRank", typeof(UILabel))
	self.topRank = top:ComponentByName("topRank", typeof(UILabel))
	self.labelNowAward = top:ComponentByName("labelNowAward", typeof(UILabel))
	self.nowAward = top:NodeByName("nowAward").gameObject
	self.nowAwardLayout = self.nowAward:GetComponent(typeof(UILayout))
end

function ArenaAllScoreServerAwardWindow:initWindow()
	self:getUIComponent()
	ArenaAllScoreServerAwardWindow.super.initWindow(self)

	self.labelTitle.text = __("AWARD2")
	local level = xyd.tables.arenaAllServerRankTable:getLevel(xyd.models.arenaAllServerScore:getRankLevel())
	local level_num = xyd.tables.arenaAllServerRankTable:getLevelNum(xyd.models.arenaAllServerScore:getRankLevel())
	self.labelRank.text = tostring(__("NEW_ARENA_ALL_SERVER_TEXT_13")) .. "  " .. __("NEW_ARENA_ALL_SERVER_RANK_" .. level, level_num)
	self.labelNowAward.text = __("NEW_ARENA_ALL_SERVER_TEXT_14")
	self.labelDesc.text = __("NEW_ARENA_ALL_SERVER_TEXT_15")

	self:updateDDL1()
	self.ddl2Text.gameObject:SetActive(false)
	self:layoutAward()

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ArenaAllScoreServerAwardWindow:updateDDL1()
	if not xyd.models.arenaAllServerScore:isInOpentime() then
		self.ddl1Text.gameObject:SetActive(false)

		return
	end

	local effect = xyd.Spine.new(self.clock)

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao1", 0)
	end)

	local ddl = xyd.models.arenaAllServerScore:getDDL()
	local endTime = ddl - xyd.getServerTime()

	if endTime > 0 then
		self.ddl1:setInfo({
			duration = endTime
		})
	end
end

function ArenaAllScoreServerAwardWindow:layoutAward()
	local ids = xyd.tables.arenaAllServerRankTable:getIdsSort()
	local infos = {}

	for i in pairs(ids) do
		table.insert(infos, {
			id = ids[i]
		})
	end

	self.wrapContent:setInfos(infos, {})
	self.scrollView:ResetPosition()

	local id = xyd.models.arenaAllServerScore:getRankLevel()
	local awards = xyd.tables.arenaAllServerRankTable:getSeasonAwards(id)

	for i in pairs(awards) do
		local params = {
			noClickSelected = true,
			labelNumScale = 1.2,
			hideText = true,
			uiRoot = self.nowAward,
			itemID = awards[i][1],
			num = awards[i][2]
		}
		local icon = xyd.getItemIcon(params)

		icon:SetLocalScale(0.7, 0.7, 1)
	end

	self.nowAwardLayout:Reposition()
end

function ArenaAllScoreServerAwardItem:ctor(parentGo, parent)
	self.parent_ = parent
	self.itemArr = {}

	ArenaAllScoreServerAwardItem.super.ctor(self, parentGo)
end

function ArenaAllScoreServerAwardItem:initUI()
	self:getUIComponent()
	ArenaAllScoreServerAwardItem.super.initUI(self)
end

function ArenaAllScoreServerAwardItem:getUIComponent()
	local go = self.go
	self.imgRank = go:ComponentByName("imgRank", typeof(UISprite))
	self.imgRank2 = go:ComponentByName("imgRank2", typeof(UISprite))
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.awardGroupLayout = self.awardGroup:GetComponent(typeof(UILayout))
	self.name = go:ComponentByName("name", typeof(UILabel))

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "de_de" or xyd.Global.lang == "ko_kr" then
		self.name.fontSize = 20
	end
end

function ArenaAllScoreServerAwardItem:update(_, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.id and info and info.id and self.id == info.id then
		return
	end

	self.id = info.id
	local level = xyd.tables.arenaAllServerRankTable:getLevel(self.id)
	local level_num = xyd.tables.arenaAllServerRankTable:getLevelNum(self.id)

	xyd.setUISpriteAsync(self.imgRank, nil, "as_rank_icon_" .. level, nil, , )

	if self.id < 21 then
		self.imgRank2.gameObject:SetActive(true)

		local little_level = math.fmod(tonumber(self.id) - 1, 5) + 1
		local img2_name = "as_rank_icon_" .. level .. "_" .. little_level

		xyd.setUISpriteAsync(self.imgRank2, nil, img2_name, nil, , true)
	else
		self.imgRank2.gameObject:SetActive(false)
	end

	self.name.text = __("NEW_ARENA_ALL_SERVER_RANK_" .. level, level_num)
	local awards = xyd.tables.arenaAllServerRankTable:getSeasonAwards(self.id)

	for i in pairs(awards) do
		local params = {
			noClickSelected = true,
			labelNumScale = 1.2,
			hideText = true,
			uiRoot = self.awardGroup,
			itemID = awards[i][1],
			num = awards[i][2],
			dragScrollView = self.parent_.scrollView
		}

		if self.itemArr[i] then
			self.itemArr[i]:getGameObject():SetActive(true)
			self.itemArr[i]:setInfo(params)
		else
			local icon = xyd.getItemIcon(params)

			icon:SetLocalScale(0.7, 0.7, 1)
			table.insert(self.itemArr, icon)
		end
	end

	for i = #self.itemArr + 1, #awards do
		if self.itemArr[i] then
			self.itemArr[i]:getGameObject():SetActive(false)
		end
	end

	self.awardGroupLayout:Reposition()
end

return ArenaAllScoreServerAwardWindow
