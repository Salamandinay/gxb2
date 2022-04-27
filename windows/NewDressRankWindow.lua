local NewDressRankWindow = class("NewDressRankWindow", import(".BaseWindow"))
local RankItem = class("EntranceRankItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")

function NewDressRankWindow:ctor(name, params)
	NewDressRankWindow.super.ctor(self, name, params)

	self.rank_info = params.rank_info
	self.rank_info = xyd.decodeProtoBuf(params.rank_info)

	if not self.rank_info.list then
		self.rank_info.list = {}
	end
end

function NewDressRankWindow:initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function NewDressRankWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.topBgImg2 = self.groupAction:ComponentByName("topBgImg2", typeof(UISprite))
	self.labelWinTitle_ = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.upGroup = self.groupAction:NodeByName("upGroup").gameObject
	self.upGroupBg = self.upGroup:ComponentByName("upGroupBg", typeof(UITexture))
	self.upGroupPanel = self.upGroup:NodeByName("upGroupPanel").gameObject

	for i = 1, 3 do
		self["personCon" .. i] = self.upGroupPanel:NodeByName("personCon" .. i).gameObject
		self["defaultCon" .. i] = self["personCon" .. i]:NodeByName("defaultCon" .. i).gameObject
		self["showCon" .. i] = self["personCon" .. i]:NodeByName("showCon" .. i).gameObject
		self["nameCon" .. i] = self["showCon" .. i]:NodeByName("nameCon" .. i).gameObject
		self["nameCon" .. i .. "_UILayout"] = self["showCon" .. i]:ComponentByName("nameCon" .. i, typeof(UILayout))
		self["upLevelGroup" .. i] = self["nameCon" .. i]:NodeByName("upLevelGroup" .. i).gameObject
		self["upLabelLevel" .. i] = self["upLevelGroup" .. i]:ComponentByName("upLabelLevel" .. i, typeof(UILabel))
		self["labelPlayerName" .. i] = self["nameCon" .. i]:ComponentByName("labelPlayerName" .. i, typeof(UILabel))
		self["serverInfo" .. i] = self["showCon" .. i]:NodeByName("serverInfo" .. i).gameObject
		self["serverId" .. i] = self["serverInfo" .. i]:ComponentByName("serverId" .. i, typeof(UILabel))
		self["downLevelCon" .. i] = self["showCon" .. i]:NodeByName("downLevelCon" .. i).gameObject
		self["downLevelCon" .. i .. "_UILayout"] = self["showCon" .. i]:ComponentByName("downLevelCon" .. i, typeof(UILayout))
		self["labelDesText" .. i] = self["downLevelCon" .. i]:ComponentByName("labelDesText" .. i, typeof(UILabel))
		self["labelCurrentNum" .. i] = self["downLevelCon" .. i]:ComponentByName("labelCurrentNum" .. i, typeof(UILabel))
		self["personEffectCon" .. i] = self["showCon" .. i]:NodeByName("personEffectCon" .. i).gameObject
	end

	self.middleGroup = self.groupAction:NodeByName("middleGroup").gameObject
	self.rankListScroller = self.middleGroup:NodeByName("rankListScroller").gameObject
	self.rankListScroller_UIScrollView = self.middleGroup:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListContainer = self.rankListScroller:NodeByName("rankListContainer").gameObject
	self.rankListContainer_UIWrapContent = self.rankListScroller:ComponentByName("rankListContainer", typeof(UIWrapContent))
	self.playerRankGroup = self.middleGroup:NodeByName("playerRankGroup").gameObject
	self.bgImg = self.playerRankGroup:ComponentByName("bgImg", typeof(UISprite))
	self.rank_item = self.middleGroup:NodeByName("rank_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.rankListScroller_UIScrollView, self.rankListContainer_UIWrapContent, self.rank_item, RankItem, self)

	self.wrapContent:setInfos({}, {})
end

function NewDressRankWindow:layout()
	self.labelWinTitle_.text = __("CAMPAIGN_RANK")

	for i = 1, 3 do
		self["labelDesText" .. i].text = __("ACTIVITY_SPACE_LEVEL_TEXT")
	end

	self:updateThree()
	self:updateFourAfter()
	self:updateSelf()
end

function NewDressRankWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function NewDressRankWindow:updateThree()
	local ids = xyd.tables.activitySpaceExploreMapTable:getIds()

	for i = 1, 3 do
		if self.rank_info.list[i] then
			self["showCon" .. i].gameObject:SetActive(true)

			self["upLabelLevel" .. i].text = tostring(self.rank_info.list[i].lev)
			self["labelPlayerName" .. i].text = tostring(self.rank_info.list[i].player_name)
			self["serverId" .. i].text = xyd.getServerNumber(self.rank_info.list[i].server_id)

			if tonumber(self.rank_info.list[i].score) > #ids then
				self.rank_info.list[i].score = #ids
			end

			self["labelCurrentNum" .. i].text = tostring(self.rank_info.list[i].score)

			if i == 2 or i == 3 then
				while true do
					if self["labelPlayerName" .. i].width > 200 then
						self["labelPlayerName" .. i].fontSize = self["labelPlayerName" .. i].fontSize - 1
					else
						break
					end
				end
			end

			self["nameCon" .. i .. "_UILayout"]:Reposition()
			self["downLevelCon" .. i .. "_UILayout"]:Reposition()

			if not self["personEffect" .. i] then
				self["personEffect" .. i] = import("app.components.SenpaiModel").new(self["personEffectCon" .. i])
			end

			self["personEffect" .. i]:setModelInfo({
				ids = self.rank_info.list[i].dress_style
			})

			UIEventListener.Get(self["showCon" .. i].gameObject).onClick = handler(self, function ()
				if self.rank_info.list[i].player_id ~= xyd.Global.playerID then
					xyd.WindowManager:get():openWindow("arena_formation_window", {
						not_show_private_chat = true,
						show_close_btn = true,
						not_show_black_btn = true,
						add_friend = false,
						not_show_mail = true,
						is_robot = false,
						player_id = self.rank_info.list[i].player_id,
						server_id = self.rank_info.list[i].server_id
					})
				end
			end)
		else
			self["showCon" .. i].gameObject:SetActive(false)
		end
	end
end

function NewDressRankWindow:updateFourAfter()
	if #self.rank_info.list >= 4 then
		local four_after_arr = {}

		for i in pairs(self.rank_info.list) do
			self.rank_info.list[i].rank = i

			if i >= 4 then
				table.insert(four_after_arr, self.rank_info.list[i])
			end
		end

		self.wrapContent:setInfos(four_after_arr, {})
	end
end

function NewDressRankWindow:updateSelf()
	local tmp = NGUITools.AddChild(self.playerRankGroup.gameObject, self.rank_item.gameObject)

	if self.rank_info.self_rank and self.rank_info.self_score then
		local itemSelf = RankItem.new(tmp, self)
		local info = {
			avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
			avatar_id = xyd.models.selfPlayer:getAvatarID(),
			lev = xyd.models.backpack:getLev(),
			player_id = xyd.Global.playerID,
			player_name = xyd.models.selfPlayer:getPlayerName(),
			score = self.rank_info.self_score,
			rank = self.rank_info.self_rank + 1,
			server_id = xyd.models.selfPlayer:getServerID()
		}

		if info.rank > 50 then
			local percentArr = {
				0.01,
				0.05,
				0.1,
				0.2,
				0.4,
				0.6,
				0.8,
				1
			}
			local num = tonumber(self.rank_info.num)
			local rank = tonumber(info.rank)
			local percent = rank / num

			if num < rank then
				info.percentStr = "100%"
			else
				for i in pairs(percentArr) do
					if percent <= percentArr[i] then
						info.percentStr = percentArr[i] * 100 .. "%"

						break
					end
				end
			end
		end

		itemSelf:update(999, info)
		itemSelf:setBgVisible(false)
	end
end

function RankItem:ctor(go, parent)
	RankItem.super.ctor(self, go, parent)

	self.go = go
	self.parent = parent
end

function RankItem:initUI()
	self:getUIComponent()

	self.labelDesText.text = __("ACTIVITY_SPACE_LEVEL_TEXT")
end

function RankItem:getUIComponent()
	self.rank_item = self.go
	self.space = self.rank_item:NodeByName("space").gameObject
	self.bgImg = self.rank_item:ComponentByName("bgImg", typeof(UISprite))
	self.rankGroup = self.rank_item:NodeByName("rankGroup").gameObject
	self.imgRankIcon = self.rankGroup:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = self.rankGroup:ComponentByName("labelRank", typeof(UILabel))
	self.avatarGroup = self.rank_item:NodeByName("avatarGroup").gameObject
	self.levelGroup = self.rank_item:NodeByName("levelGroup").gameObject
	self.labelLevel = self.levelGroup:ComponentByName("labelLevel", typeof(UILabel))
	self.labelPlayerName = self.rank_item:ComponentByName("labelPlayerName", typeof(UILabel))
	self.groupLevel_ = self.rank_item:NodeByName("groupLevel_").gameObject
	self.labelDesText = self.groupLevel_:ComponentByName("labelDesText", typeof(UILabel))
	self.labelCurrentNum = self.groupLevel_:ComponentByName("labelCurrentNum", typeof(UILabel))
	self.serverInfo = self.rank_item:NodeByName("serverInfo").gameObject
	self.bg_ = self.serverInfo:ComponentByName("bg_", typeof(UISprite))
	self.icon_ = self.serverInfo:ComponentByName("icon_", typeof(UISprite))
	self.serverId = self.serverInfo:ComponentByName("serverId", typeof(UILabel))
	self.pIcon = PlayerIcon.new(self.avatarGroup)
end

function RankItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	if self.player_id and info.player_id and info.player_id == self.player_id then
		return
	end

	self.info = info
	self.player_id = info.player_id

	if not self.info.avatar_frame_id then
		self.info.avatar_frame_id = 0
	end

	self.pIcon:setInfo({
		scale = 0.65,
		avatarID = self.info.avatar_id,
		avatar_frame_id = self.info.avatar_frame_id,
		lev = self.info.lev,
		callback = function ()
			if self.info.player_id ~= xyd.Global.playerID then
				xyd.WindowManager:get():openWindow("arena_formation_window", {
					not_show_private_chat = true,
					show_close_btn = true,
					not_show_black_btn = true,
					add_friend = false,
					not_show_mail = true,
					is_robot = false,
					player_id = self.info.player_id,
					server_id = self.info.server_id
				})
			end
		end,
		dragScrollView = self.parent.rankListScroller_UIScrollView
	})

	if self.info.lev then
		self.labelLevel.text = tostring(self.info.lev)
	end

	if self.info.player_name then
		self.labelPlayerName.text = tostring(self.info.player_name)
	end

	if self.info.server_id then
		self.serverId.text = xyd.getServerNumber(self.info.server_id)
	end

	if self.info.score then
		local ids = xyd.tables.activitySpaceExploreMapTable:getIds()

		if tonumber(self.info.score) > #ids then
			self.info.score = #ids
		end

		self.labelCurrentNum.text = tostring(self.info.score)
	end

	self:updateRank()
end

function RankItem:updateRank()
	if self.info.percentStr then
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = tostring(self.info.percentStr)

		return
	end

	if tonumber(self.info.rank) ~= nil and tonumber(self.info.rank) <= 3 and tonumber(self.info.rank) > 0 then
		xyd.setUISpriteAsync(self.imgRankIcon, nil, "rank_icon0" .. self.info.rank, nil, )
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	elseif self.info.rank then
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = tostring(self.info.rank)
	elseif not self.info.rank or self.info.rank == 0 then
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(false)
	end
end

function RankItem:getGameObject()
	return self.go
end

function RankItem:setBgVisible(visible)
	return self.bgImg.gameObject:SetActive(visible)
end

return NewDressRankWindow
