local BaseWindow = import(".BaseWindow")
local GuildWarAwardWindow = class("GuildWarAwardWindow", BaseWindow)
local ItemRender = class("ItemRender")
local ArenaAwardItem = class("ArenaAwardItem", import("app.components.BaseComponent"))

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ArenaAwardItem.new(go)

	self.item:setDragScrollView(parent.scrollView_)
end

function ItemRender:update(index, realIndex, info)
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

function GuildWarAwardWindow:ctor(name, params)
	GuildWarAwardWindow.super.ctor(self, name, params)

	self.model_ = xyd.models.guildWar
end

function ArenaAwardItem:ctor(parentGo)
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
	local table = xyd.tables.guildWarRankAwardTable
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
			num = item.item_num
		})

		icon:SetLocalScale(0.7, 0.7, 1)
	end

	self.awardGroupLayout:Reposition()
end

function GuildWarAwardWindow:initWindow()
	GuildWarAwardWindow.super.initWindow(self)

	self.closeBtn = self.window_:ComponentByName("main/title/backBtn", typeof(UISprite)).gameObject
	self.winTitle_ = self.window_:ComponentByName("main/title/labelTitle", typeof(UILabel))
	self.content_ = self.window_:NodeByName("main/content").gameObject
	local conTrans = self.content_.transform
	self.timeCountLabel_ = conTrans:ComponentByName("ddlTime", typeof(UILabel))
	self.labelDesc_ = conTrans:ComponentByName("labelDesc", typeof(UILabel))
	self.labelRank_ = conTrans:ComponentByName("top/labelRank", typeof(UILabel))
	self.labelTopRank_ = conTrans:ComponentByName("top/labelTopRank", typeof(UILabel))
	self.topRank_ = conTrans:ComponentByName("top/topRank", typeof(UILabel))
	self.labelNowAward_ = conTrans:ComponentByName("top/labelNowAward", typeof(UILabel))
	self.gridNowAward_ = conTrans:ComponentByName("top/gridNowAward", typeof(UIGrid))
	self.scrollView_ = conTrans:ComponentByName("scrollview", typeof(UIScrollView))
	self.grid_ = conTrans:ComponentByName("scrollview/awardContainer", typeof(MultiRowWrapContent))
	self.scrollItemRoot_ = conTrans:NodeByName("scrollview/itemRoot").gameObject
	self.warpcontent_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, self.scrollItemRoot_, ItemRender, self)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow("guild_war_award_window")
	end
end

function GuildWarAwardWindow:playOpenAnimation(callback)
	GuildWarAwardWindow.super.playOpenAnimation(self, function ()
		if callback then
			callback()
		end

		self:layout()
	end)
end

function GuildWarAwardWindow:layout()
	local selfAwardInfo = xyd.tables.guildWarRankAwardTable:getRankInfo(self.model_:getRank())
	self.winTitle_.text = __("AWARD2")
	self.labelRank_.text = __("NOW_RANK") .. " : " .. tostring(selfAwardInfo.rankText)
	self.labelNowAward_.text = __("NOW_AWARD")
	self.labelTopRank_.text = __("TOP_RANK") .. " : "

	self:initAlarmAni()

	self.labelDesc_.text = __("ARENA_RANK_DESC2")

	self:updateDDL1()
	self:layoutAward(selfAwardInfo)
end

function GuildWarAwardWindow:initAlarmAni()
	local alarmLineTrans = self.window_.transform:ComponentByName("main/content/alarmIcon/linePos", typeof(UIWidget)).transform
	self.alarmAni1_ = DG.Tweening.DOTween.Sequence()
	local angles = 0

	local function playAlarmAni1()
		angles = math.fmod(angles + 90, 360)

		self.alarmAni1_:Insert(0, alarmLineTrans:DORotate(Vector3(0, 0, angles), 0.2))
	end

	self.timer_ = Timer.New(handler(self, playAlarmAni1), 2, -1, false)

	self.timer_:Start()
end

function GuildWarAwardWindow:willClose()
	GuildWarAwardWindow.super.willClose(self)

	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end

	if self.alarmAni1_ then
		self.alarmAni1_:Kill(false)

		self.alarmAni1_ = nil
	end
end

function GuildWarAwardWindow:updateDDL1()
	local ddl = self.model_:getInfo().week_start_time + 518400 - 21600
	local endTime = ddl - xyd.getServerTime()
	local params = {
		duration = endTime
	}

	if not self.timeCount_ then
		self.timeCount_ = import("app.components.CountDown").new(self.timeCountLabel_, params)
	else
		self.tlabelRefreshTime_:setInfo(params)
	end
end

function GuildWarAwardWindow:layoutAward(selfAwardInfo)
	dump(selfAwardInfo)

	for _, itemInfo in ipairs(selfAwardInfo.award) do
		xyd.getItemIcon({
			labelNumScale = 1.6,
			scale = 0.7,
			uiRoot = self.gridNowAward_.gameObject,
			itemID = itemInfo.item_id,
			num = itemInfo.item_num
		})
	end

	self.gridNowAward_:Reposition()

	local ids = xyd.tables.guildWarRankAwardTable:getIds()
	local data = {}

	for i = 1, #ids do
		table.insert(data, {
			colName = "seasonAward",
			id = i
		})
	end

	self.warpcontent_:setInfos(data, {})
end

return GuildWarAwardWindow
