local BaseWindow = import(".BaseWindow")
local FairArenaRecordWindow = class("FairArenaRecordWindow", BaseWindow)
local RecordItem = class("RecordItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local CommonTabBar = import("app.common.ui.CommonTabBar")

function FairArenaRecordWindow:ctor(name, params)
	FairArenaRecordWindow.super.ctor(self, name, params)
end

function FairArenaRecordWindow:initWindow()
	FairArenaRecordWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initData()
	self:updateLayout(1, 1)
	self:register()
end

function FairArenaRecordWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	local playerGroup = winTrans:NodeByName("playerGroup")
	self.pNode = playerGroup:NodeByName("pIcon").gameObject
	self.nameLabel_ = playerGroup:ComponentByName("nameLabel_", typeof(UILabel))
	self.serverLabel_ = playerGroup:ComponentByName("serverGroup/serverLabel_", typeof(UILabel))
	self.scoreTextLabel_ = playerGroup:ComponentByName("scoreTextLabel_", typeof(UILabel))
	self.rankTextLabel_ = playerGroup:ComponentByName("rankTextLabel_", typeof(UILabel))
	self.scoreLabel_ = playerGroup:ComponentByName("scoreLabel_", typeof(UILabel))
	self.rankLabel_ = playerGroup:ComponentByName("rankLabel_", typeof(UILabel))
	self.signatureLabel_ = playerGroup:ComponentByName("signatureGroup/signatureLabel_", typeof(UILabel))
	self.nav = winTrans:NodeByName("nav").gameObject
	local mainGroup = winTrans:NodeByName("mainGroup")
	self.scrollView = mainGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.itemGroup = mainGroup:NodeByName("scroller_/itemGroup").gameObject
	self.recordItem = mainGroup:NodeByName("scroller_/item").gameObject
	self.tipLabel_ = mainGroup:ComponentByName("tipLabel_", typeof(UILabel))
	local sortGroup = mainGroup:NodeByName("sortGroup").gameObject
	self.sortBtn1 = sortGroup:NodeByName("sortBtn1_").gameObject
	self.sortBtn1Label_ = self.sortBtn1:ComponentByName("label", typeof(UILabel))
	self.sortBtn2 = sortGroup:NodeByName("sortBtn2_").gameObject
	self.sortBtn2Label_ = self.sortBtn2:ComponentByName("label", typeof(UILabel))
end

function FairArenaRecordWindow:initUIComponent()
	self.data = xyd.models.fairArena:getArenaInfo()
	local serverId = xyd.models.selfPlayer:getServerID()
	self.titleLabel_.text = __("FAIR_ARENA_HISTORY")
	self.nameLabel_.text = xyd.Global.playerName
	self.serverLabel_.text = xyd.getServerNumber(serverId)
	self.scoreTextLabel_.text = __("FAIR_ARENA_POINT_NOW")
	self.rankTextLabel_.text = __("FAIR_ARENA_RANK_NOW")
	self.tipLabel_.text = __("FAIR_ARENA_NOTES_SCORE")
	self.sortBtn1Label_.text = __("FAIR_ARENA_SORT_TIME")
	self.sortBtn2Label_.text = __("FAIR_ARENA_SORT_SCORE")
	self.scoreLabel_.text = self.data.score or 0

	if self.data.self_rank then
		self.rankLabel_.text = self.data.self_rank + 1
	else
		self.rankLabel_.text = ""
	end

	self.signatureLabel_.text = xyd.models.selfPlayer:getSignature()
	self.pIcon = PlayerIcon.new(self.pNode)

	self.pIcon:setInfo({
		avatarID = xyd.models.selfPlayer:getAvatarID(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		lev = xyd.models.backpack:getLev()
	})

	self.navGroup = CommonTabBar.new(self.nav, 2, function (index)
		if self.navFlag1 then
			self:updateLayout(index, self.type)
		end

		self.navFlag1 = true
	end)

	self.navGroup:setTexts({
		__("FAIR_ARENA_EXPLORE"),
		__("FAIR_ARENA_DEMO")
	})
	self:setSortBtn(self.sortBtn1, true)
	self:setSortBtn(self.sortBtn2, false)
end

function FairArenaRecordWindow:initData()
	local data = self.data.history_explore
	self.collection1 = {}
	self.collection2 = {}
	local ind = {
		1,
		1
	}

	for i = 1, #data do
		local type = data[i].explore_type

		table.insert(self["collection" .. type], {
			id = ind[type],
			explore_type = data[i].explore_type,
			explore_stage = data[i].explore_stage,
			partner_infos = data[i].partner_infos,
			buffs = data[i].buffs
		})

		ind[type] = ind[type] + 1
	end
end

function FairArenaRecordWindow:updateLayout(index, type)
	if not self.wrapContent then
		local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.recordItem, RecordItem, self)
	end

	local collection = self["collection" .. index]

	if type == 1 then
		table.sort(collection, function (a, b)
			return b.id < a.id
		end)
	else
		table.sort(collection, function (a, b)
			return b.explore_stage < a.explore_stage
		end)
	end

	self.wrapContent:setInfos(collection, {})

	self.index = index
	self.type = type

	self.tipLabel_:SetActive(index == 2)
end

function FairArenaRecordWindow:register()
	FairArenaRecordWindow.super.register(self)

	for i = 1, 2 do
		UIEventListener.Get(self["sortBtn" .. i]).onClick = handler(self, function ()
			self:updateLayout(self.index, i)

			if i == 1 then
				self:setSortBtn(self.sortBtn1, true)
				self:setSortBtn(self.sortBtn2, false)
			else
				self:setSortBtn(self.sortBtn1, false)
				self:setSortBtn(self.sortBtn2, true)
			end
		end)
	end
end

function FairArenaRecordWindow:setSortBtn(btn, flag)
	if flag then
		btn:GetComponent(typeof(UIButton)):SetEnabled(false)

		local label = btn:ComponentByName("label", typeof(UILabel))
		label.color = Color.New2(4294967295.0)
		label.effectStyle = UILabel.Effect.Outline
		label.effectColor = Color.New2(1012112383)
	else
		btn:GetComponent(typeof(UIButton)):SetEnabled(true)

		local label = btn:ComponentByName("label", typeof(UILabel))
		label.color = Color.New2(960513791)
		label.effectStyle = UILabel.Effect.None
	end
end

function RecordItem:ctor(go, parent)
	RecordItem.super.ctor(self, go, parent)
end

function RecordItem:initUI()
	local go = self.go
	self.label_ = go:ComponentByName("label_", typeof(UILabel))
	self.stageLabel_ = go:ComponentByName("icon_/stageLabel_", typeof(UILabel))
	self.icon_ = go:ComponentByName("icon_", typeof(UISprite))
	self.scoreTextLabel_ = go:ComponentByName("scoreTextLabel_", typeof(UILabel))
	self.scoreLabel_ = go:ComponentByName("scoreLabel_", typeof(UILabel))
	self.formationBtn_ = go:NodeByName("formationBtn_").gameObject
	self.formationBtnLabel_ = self.formationBtn_:ComponentByName("button_label", typeof(UILabel))
	self.scoreTextLabel_.text = __("FAIR_ARENA_POINT")
	self.formationBtnLabel_.text = __("PARTNER_STATION_LINEUP_C")

	if xyd.Global.lang == "de_de" then
		self.label_:X(-285)
		self.icon_:Y(-10)
	end

	if xyd.Global.lang == "fr_fr" then
		self.label_:X(-287)

		self.label_.fontSize = 24
	end
end

function RecordItem:registerEvent()
	UIEventListener.Get(self.formationBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_record_detail_window", {
			partner_infos = self.partner_infos,
			god_skills = self.buffs,
			stage = self.stage
		})
	end)
end

function RecordItem:updateInfo()
	self.id = self.data.id
	self.stage = self.data.explore_stage
	self.type = self.data.explore_type
	self.partner_infos = self.data.partner_infos
	self.buffs = self.data.buffs

	if self.type == 1 then
		self.label_.text = __("FAIR_ARENA_HISTORY_EXPLORE", self.id)
	else
		self.label_.text = __("FAIR_ARENA_HISTORY_DEMO", self.id)
	end

	self.scoreLabel_.text = xyd.tables.activityFairArenaLevelTable:getScore(self.stage)
	self.stageLabel_.text = __("FAIR_ARENA_TITLE_GIFT", self.stage - 1)
	local style = xyd.tables.activityFairArenaLevelTable:getStyle(self.stage)

	xyd.setUISpriteAsync(self.icon_, nil, "fair_arena_awardbox_icon" .. style)
end

return FairArenaRecordWindow
