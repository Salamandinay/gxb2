local ArenaNewSeasonServerRankWindow = class("ArenaNewSeasonServerRankWindow", import(".BaseWindow"))
local ArenaNewSeasonServerRankItem = class("testItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaNewSeasonServerRankWindow:ctor(name, params)
	ArenaNewSeasonServerRankWindow.super.ctor(self, name, params)

	self.infos = params.infos
end

function ArenaNewSeasonServerRankWindow:initWindow()
	self:getUIComponent()
	ArenaNewSeasonServerRankWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function ArenaNewSeasonServerRankWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.topBgImg2 = self.groupAction:ComponentByName("topBgImg2", typeof(UISprite))
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.middleGroup = self.groupAction:NodeByName("middleGroup").gameObject
	self.rankListScroller = self.middleGroup:NodeByName("rankListScroller").gameObject
	self.rankListScrollerUIScrollView = self.middleGroup:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListScrollerUIPanel = self.middleGroup:ComponentByName("rankListScroller", typeof(UIPanel))
	self.rankListContainer = self.rankListScroller:NodeByName("rankListContainer").gameObject
	self.rankListContainerUIWrapContent = self.rankListScroller:ComponentByName("rankListContainer", typeof(UIWrapContent))
	self.container = self.rankListScroller:NodeByName("container").gameObject
	self.arena_new_season_server_rank_item = self.groupAction:NodeByName("arena_new_season_server_rank_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.rankListScrollerUIScrollView, self.rankListContainerUIWrapContent, self.arena_new_season_server_rank_item, ArenaNewSeasonServerRankItem, self)

	self.wrapContent:setInfos({}, {})
end

function ArenaNewSeasonServerRankWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function ArenaNewSeasonServerRankWindow:layout()
	local slaveIds = xyd.models.arena:getSlaveIds()

	if slaveIds ~= nil and #slaveIds > 0 then
		table.sort(slaveIds)
	end

	local allInfoArr = {}

	for i in pairs(slaveIds) do
		allInfoArr[tostring(slaveIds[i])] = {
			serverId = slaveIds[i]
		}
	end

	local firstInfo = nil
	local otherIdArr = {}
	local selfServerId = tonumber(xyd.models.selfPlayer:getServerID())

	for i, info in pairs(self.infos) do
		if tonumber(info.server_id) == selfServerId then
			firstInfo = info
		elseif not info.is_robot or info.is_robot ~= 1 then
			table.insert(otherIdArr, info)
		end
	end

	for i in pairs(otherIdArr) do
		local checkServerId = otherIdArr[i].server_id

		if allInfoArr[tostring(checkServerId)] then
			allInfoArr[tostring(checkServerId)].info = otherIdArr[i]
		end
	end

	local setInfos = {}

	for i in pairs(slaveIds) do
		if slaveIds[i] ~= selfServerId then
			table.insert(setInfos, allInfoArr[tostring(slaveIds[i])])
		end
	end

	if firstInfo then
		if firstInfo.is_robot and firstInfo.is_robot == 1 then
			table.insert(setInfos, 1, {
				serverId = selfServerId
			})
		else
			table.insert(setInfos, 1, {
				serverId = selfServerId,
				info = firstInfo
			})
		end
	else
		table.insert(setInfos, 1, {
			serverId = selfServerId
		})
	end

	if #setInfos <= 6 then
		local length = #setInfos

		if length < 1 then
			length = 1
		end

		self.topBgImg2.height = 83 + 113 * length
	end

	self:waitForFrame(2, function ()
		self.wrapContent:setInfos(setInfos, {})
		self.rankListScrollerUIScrollView:ResetPosition()
	end)
end

function ArenaNewSeasonServerRankItem:ctor(goItem, parent)
	self.goItem_ = goItem
	self.parent = parent
	self.selfServerId = tonumber(xyd.models.selfPlayer:getServerID())

	ArenaNewSeasonServerRankItem.super.ctor(self, goItem)
end

function ArenaNewSeasonServerRankItem:initUI()
	self:getUIComponent()
end

function ArenaNewSeasonServerRankItem:getUIComponent()
	self.bgImg = self.go:ComponentByName("bgImg", typeof(UISprite))
	self.rankGroup = self.go:NodeByName("rankGroup").gameObject
	self.imgRankIcon = self.rankGroup:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = self.rankGroup:ComponentByName("labelRank", typeof(UILabel))
	self.avatarGroup = self.go:NodeByName("avatarGroup").gameObject
	self.powerGroup = self.go:NodeByName("powerGroup").gameObject
	self.powerIcon = self.powerGroup:ComponentByName("powerIcon", typeof(UISprite))
	self.poweLabel = self.powerGroup:ComponentByName("poweLabel", typeof(UILabel))
	self.labelPlayerName = self.go:ComponentByName("labelPlayerName", typeof(UILabel))
	self.serverInfo = self.go:NodeByName("serverInfo").gameObject
	self.bg_ = self.serverInfo:ComponentByName("bg_", typeof(UISprite))
	self.icon_ = self.serverInfo:ComponentByName("icon_", typeof(UISprite))
	self.serverId = self.serverInfo:ComponentByName("serverId", typeof(UILabel))
	self.serverTips = self.serverInfo:ComponentByName("serverTips", typeof(UILabel))

	if not self.pIcon then
		self.pIcon = PlayerIcon.new(self.avatarGroup, self.parent.rankListScrollerUIPanel)
	end
end

function ArenaNewSeasonServerRankItem:update(index, allInfo)
	if not allInfo then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	local info = allInfo.info
	local serverId = allInfo.serverId
	self.serverId.text = xyd.getServerNumber(serverId)

	if self.selfServerId == tonumber(serverId) then
		xyd.setUISpriteAsync(self.bgImg, nil, "9gongge51")
		self.serverId.gameObject:Y(12)

		self.serverTips.text = __("ARENA_NEW_SEASON_SERVER_MY_SERVER")

		self.serverTips.gameObject:SetActive(true)
	else
		xyd.setUISpriteAsync(self.bgImg, nil, "9gongge17")
		self.serverId.gameObject:Y(0)
		self.serverTips.gameObject:SetActive(false)
	end

	if info then
		self.rankGroup.gameObject:SetActive(true)
		self.avatarGroup.gameObject:SetActive(true)
		self.powerGroup.gameObject:SetActive(true)
		self.labelPlayerName.gameObject:SetActive(true)
	else
		self.rankGroup.gameObject:SetActive(false)
		self.avatarGroup.gameObject:SetActive(false)
		self.powerGroup.gameObject:SetActive(false)
		self.labelPlayerName.gameObject:SetActive(false)

		return
	end

	self.poweLabel.text = info.power
	self.labelPlayerName.text = info.player_name

	self.pIcon:setInfo({
		noClick = false,
		avatarID = info.avatar_id,
		lev = info.lev,
		avatar_frame_id = info.avatar_frame_id,
		callback = function ()
			if info.player_id ~= xyd.Global.playerID then
				xyd.WindowManager.get():openWindow("arena_formation_window", {
					player_id = info.player_id,
					is_robot = info.is_robot
				})
			end
		end
	})
end

return ArenaNewSeasonServerRankWindow
