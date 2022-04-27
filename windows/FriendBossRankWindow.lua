local BaseWindow = import(".BaseWindow")
local FriendBossRankWindow = class("FriendBossRankWindow", BaseWindow)
local FriendModel = xyd.models.friend
local OldSize = {
	w = 720,
	h = 1280
}
local FriendBossRankItem = class("FriendBossRankItem")

function FriendBossRankItem:ctor(go, parent)
	self.parent_ = parent
	self.go_ = go
	self.imgRankIcon_ = self.go_:ComponentByName("rankGroup/imgRankIcon", typeof(UISprite))
	self.rankLable_ = self.go_:ComponentByName("rankGroup/labelRank", typeof(UILabel))
	self.playerName_ = self.go_:ComponentByName("labelPlayerName", typeof(UILabel))
	self.avatarGroup_ = self.go_:ComponentByName("avatarGroup", typeof(UIWidget))
	self.progressBar_ = self.go_:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel_ = self.go_:ComponentByName("progressBar/labelDesc", typeof(UILabel))
end

function FriendBossRankItem:update(index, realIndex, info)
	if not info then
		self.go_:SetActive(false)

		return
	end

	self.go_:SetActive(true)

	self.data_ = info.data
	self.rank_ = info.rank

	if self.rank_ <= 3 then
		xyd.setUISpriteAsync(self.imgRankIcon_, nil, "rank_icon0" .. self.rank_, nil, )
		self.imgRankIcon_.gameObject:SetActive(true)
		self.rankLable_.gameObject:SetActive(false)
	else
		self.imgRankIcon_.gameObject:SetActive(false)

		self.rankLable_.text = tostring(self.rank_)

		self.rankLable_.gameObject:SetActive(true)
	end

	local playerInfo = {
		avatarID = self.data_.avatar_id,
		lev = self.data_.lev
	}

	if not self.playerIcon_ then
		self.playerIcon_ = import("app.components.PlayerIcon").new(self.avatarGroup_.gameObject)

		self.playerIcon_:setInfo(playerInfo)
	else
		self.playerIcon_:setInfo(playerInfo)
	end

	self.playerName_.text = self.data_.player_name
	local maxDamage = self.data_.maxDamage or 1
	self.progressBar_.value = math.floor(self.data_.score / maxDamage)
	self.progressLabel_.text = self.data_.score
end

function FriendBossRankItem:getGameObject()
	return self.go_.gameObject
end

function FriendBossRankWindow:ctor(name, params)
	FriendBossRankWindow.super.ctor(self, name, params)
end

function FriendBossRankWindow:initWindow()
	FriendBossRankWindow.super.initWindow(self)

	self.content_ = self.window_:ComponentByName("content", typeof(UISprite))
	local contentTrans = self.content_.transform
	local sWidth, sHeight = xyd.getScreenSize()
	local activeHeight = xyd.WindowManager.get():getActiveHeight()
	local activeWidth = xyd.WindowManager.get():getActiveWidth()

	if sHeight / sWidth <= 1.4 then
		contentTrans.localScale = Vector3(1.15, 1.15, 1.15)
		contentTrans.localPosition = Vector3(0, contentTrans.localPosition.y * 1.15, 0)
	else
		contentTrans.localScale = Vector3(activeWidth / OldSize.w, activeHeight / OldSize.h, 1)
		contentTrans.localPosition = Vector3(0, contentTrans.localPosition.y * activeHeight / OldSize.h, 0)
	end

	self.WarpContent_ = contentTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.scrollView_ = contentTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.closeBtn = contentTrans:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	local friendBossRankItemRoot = contentTrans:ComponentByName("friendBossRankItem", typeof(UIWidget)).gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.WarpContent_, friendBossRankItemRoot, FriendBossRankItem, self)
	self.labelWinTitle_ = contentTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.groupNone_ = contentTrans:NodeByName("groupNone").gameObject
	self.labelNoneTips_ = contentTrans:ComponentByName("groupNone/labelNoneTips", typeof(UILabel))
	self.labelWinTitle_.text = __("FRIEND_BOSS_RANK_WINDOW")

	self:register()
end

function FriendBossRankWindow:register()
	FriendBossRankWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.FRIEND_GET_BOSS_RANK, self.onGetBossRank, self)
end

function FriendBossRankWindow:playOpenAnimation(callback)
	local function afterAction()
		self:layout()
		FriendModel:getBossRank()
		callback()
	end

	FriendBossRankWindow.super.playOpenAnimation(self, afterAction)
end

function FriendBossRankWindow:layout()
	self.labelNoneTips_.text = __("FRIEND_BOSS_NO_HARM_INFO")
end

function FriendBossRankWindow:onGetBossRank(event)
	local list = event.data.list
	local maxDamage = 0
	local rankList = {}
	local newList = {}

	for i = 1, #list do
		newList[i] = {
			data = list[i],
			rank = i
		}

		if maxDamage <= tonumber(list[i].score) then
			maxDamage = tonumber(list[i].score)
		end
	end

	self.multiWrap_:setInfos(newList, {})
	self.multiWrap_:resetScrollView()

	if #list <= 0 then
		self.groupNone_:SetActive(true)
	end
end

return FriendBossRankWindow
