local ArenaAllServerPreChampionItem = class("ArenaAllServerPreChampionItem")
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaAllServerPreChampionItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	xyd.setDragScrollView(go, parent.scrollView)
	self:initUI()
	self:registerEvent()
end

function ArenaAllServerPreChampionItem:getGameObject()
	return self.go
end

function ArenaAllServerPreChampionItem:initUI()
	self.bg = self.go:ComponentByName("bgImg", typeof(UISprite))
	self.labelRank = self.go:ComponentByName("labelRank", typeof(UILabel))
	self.imgRankIcon = self.labelRank:ComponentByName("imgRankIcon", typeof(UISprite))
	self.avatarGroup = self.go:NodeByName("avatarGroup").gameObject
	self.labelPlayerName = self.go:ComponentByName("labelPlayerName", typeof(UILabel))
	self.labelGuildName = self.go:ComponentByName("labelGuildName", typeof(UILabel))
	self.labelTime = self.go:ComponentByName("labelTime", typeof(UILabel))
	self.labelTimeNum = self.go:ComponentByName("labelTimeNum", typeof(UILabel))
end

function ArenaAllServerPreChampionItem:registerEvent()
end

function ArenaAllServerPreChampionItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo()
end

function ArenaAllServerPreChampionItem:updateInfo()
	if not self.data then
		return
	end

	local playerInfo = self.data.show_info

	if not playerInfo then
		return
	end

	self.labelTime.text = __("NEW_ARENA_ALL_SERVER_TEXT_18")
	self.labelTimeNum.text = self.data.score_id
	self.labelPlayerName.text = playerInfo.player_name

	if playerInfo.guild_name then
		self.labelGuildName.text = playerInfo.guild_name
		self.labelGuildName.color = Color.New2(1549556991)
	else
		self.labelGuildName.text = __("ARENA_ALL_SERVER_TEXT_14")
		self.labelGuildName.color = Color.New2(2290583551.0)
	end

	if self.data.rank > 3 then
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = self.data.rank

		xyd.setUISpriteAsync(self.bg, nil, "9gongge17")

		self.labelTimeNum.color = Color.New2(1549556991)
	else
		self.imgRankIcon:SetActive(true)

		local labelColor = {
			3932029183.0,
			3950575871.0,
			3870490879.0
		}
		self.labelTimeNum.color = Color.New2(labelColor[self.data.rank])

		xyd.setUISpriteAsync(self.imgRankIcon, nil, "rank_icon0" .. tostring(self.data.rank))

		local bg = {
			"9gongge30",
			"9gongge31",
			"9gongge32"
		}

		xyd.setUISpriteAsync(self.bg, nil, bg[self.data.rank])
	end

	if not self.playerIcon then
		self.playerIcon = PlayerIcon.new(self.avatarGroup)
	end

	self.playerIcon:setInfo({
		scale = 0.7807017543859649,
		noClick = true,
		avatarID = playerInfo.avatar_id,
		avatar_frame_id = playerInfo.avatar_frame_id,
		lev = playerInfo.lev,
		dragScrollView = self.parent.scrollView
	})
end

function ArenaAllServerPreChampionItem:onTouch()
	self.data.player_infos = self.data.show_info

	xyd.WindowManager.get():openWindow("arena_all_server_final_8_window", self.data)
end

local ArenaAllServerPreChampionWindow = class("ArenaAllServerPreChampionWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function ArenaAllServerPreChampionWindow:ctor(name, params)
	ArenaAllServerPreChampionWindow.super.ctor(self, name, params)
end

function ArenaAllServerPreChampionWindow:initWindow()
	ArenaAllServerPreChampionWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	self:initList()
end

function ArenaAllServerPreChampionWindow:getUIComponent()
	local winTrans = self.window_.transform
	local main = winTrans:NodeByName("main").gameObject
	self.labelTitle_ = main:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = main:NodeByName("closeBtn").gameObject
	self.helpBtn = main:NodeByName("helpBtn").gameObject
	self.groupNone_ = main:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
end

function ArenaAllServerPreChampionWindow:layout()
	self.labelNoneTips_.text = __("ARENA_ALL_SERVER_TEXT_4")
	self.labelTitle_.text = __("ARENA_ALL_SERVER_TEXT_21")
end

function ArenaAllServerPreChampionWindow:registerEvent()
	self:register()
end

function ArenaAllServerPreChampionWindow:initList()
	xyd.models.arenaAllServerNew:reqGetHallRank()

	self.data_ = xyd.models.arenaAllServerNew:getHallRank()

	if not self.data_ then
		self.groupNone_:SetActive(true)

		return
	end

	if #self.data_ == 0 then
		self.groupNone_:SetActive(true)

		return
	end

	local rankInfo = {}

	for key, value in pairs(self.data_) do
		value.sourceKey = key

		table.insert(rankInfo, value)
	end

	local function sort_func(a, b)
		if a.score_id == b.score_id then
			return a.sourceKey < b.sourceKey
		else
			return b.score_id < a.score_id
		end
	end

	table.sort(rankInfo, sort_func)

	for key, value in pairs(rankInfo) do
		value.rank = key
	end

	if #rankInfo == 0 then
		self.groupNone_:SetActive(true)
	else
		self.scrollView = self.window_:ComponentByName("main/scroller", typeof(UIScrollView))
		local wrapContent = self.scrollView:ComponentByName("itemList", typeof(UIWrapContent))
		local item = self.scrollView:NodeByName("championItem").gameObject
		self.wrapContent_ = FixedWrapContent.new(self.scrollView, wrapContent, item, ArenaAllServerPreChampionItem, self)

		self.wrapContent_:setInfos(rankInfo, {})
	end
end

return ArenaAllServerPreChampionWindow
