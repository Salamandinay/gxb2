local GuildCompetitionBossRankWindow = class("GuildCompetitionBossRankWindow", import(".BaseWindow"))
local GuildCompetitionBossRankItem = class("GuildCompetitionBossRankItem", require("app.components.CopyComponent"))
local GuildBossKillAwardItem = class("GuildBossKillAwardItem")
local CountDown = import("app.components.CountDown")

function GuildCompetitionBossRankItem:ctor(go, parent, params, noPanel)
	self.parent_ = parent
	self.rankData = params
	self.noPanel_ = noPanel

	GuildCompetitionBossRankItem.super.ctor(self, go)
	self:getUIComponent()
	self:initUIComponent()
end

function GuildCompetitionBossRankItem:getUIComponent()
	local go = self.go
	self.labelName = go:ComponentByName("labelName", typeof(UILabel))
	self.imgRank = go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	local pIcon = go:NodeByName("pIcon").gameObject
	local renderPanel = self.parent_.rankScroll_:GetComponent(typeof(UIPanel))

	if self.noPanel_ then
		renderPanel = nil
	end

	self.pIcon = require("app.components.PlayerIcon").new(pIcon, renderPanel)
	self.lv = go:ComponentByName("lv", typeof(UILabel))
	self.bgImg_ = go:NodeByName("e:Image").gameObject
	self.labelScore = go:ComponentByName("labelScore", typeof(UILabel))
	self.labelScoreTips = go:ComponentByName("labelScoreTips", typeof(UILabel))
	self.labelScoreTips.text = __("WORLD_BOSS_DESC_TEXT")
end

function GuildCompetitionBossRankItem:initUIComponent()
	if not self.rankData then
		return
	end

	self.labelName.text = self.rankData.player_name

	if self.rankData.rank == -1 then
		self.imgRank:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = __("NO_GET_RANK")
	elseif self.rankData.rank <= 3 then
		xyd.setUISprite(self.imgRank, nil, "rank_icon0" .. self.rankData.rank)
		self.imgRank:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.labelRank.text = tostring(self.rankData.rank)

		self.labelRank:SetActive(true)
		self.imgRank:SetActive(false)
	end

	self.pIcon:setInfo({
		noClick = true,
		avatarID = self.rankData.avatar_id,
		avatar_frame_id = self.rankData.avatar_frame_id
	})

	if self.rankData.hide_bg then
		self.bgImg_:SetActive(false)
	else
		self.bgImg_:SetActive(true)
	end

	self.pIcon:SetLocalScale(0.65, 0.65, 1)

	self.lv.text = tostring(self.rankData.lev)
	local deal_score = self.rankData.score

	if deal_score > 0 and deal_score < 1 then
		deal_score = 1
	elseif deal_score > 1 then
		deal_score = math.floor(deal_score)
	end

	self.labelScore.text = xyd.getRoughDisplayNumber3(tonumber(deal_score))
end

function GuildCompetitionBossRankItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.rankData = info

	self:initUIComponent()
end

function GuildCompetitionBossRankWindow:ctor(name, params)
	GuildCompetitionBossRankWindow.super.ctor(self, name, params)

	self.bossId_ = params.bossId
	self.bossData_ = params.bossData
	self.roundIndex_ = params.roundIndex
	self.isAllGuildAward = params.isAllGuildAward

	if not self.isAllGuildAward then
		self:initRankInfo()
	end

	self.rank_mark = ":"

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "ja_jp" then
		self.rank_mark = " : "
	end
end

function GuildCompetitionBossRankWindow:initRankInfo()
	self.rank_data_ = self.bossData_.list or {}
	self.self_data_ = {
		rank = -1,
		score = 0
	}

	if self.bossData_.self_rank then
		self.self_data_.rank = self.bossData_.self_rank + 1
	end

	if self.bossData_.self_score then
		self.self_data_.score = self.bossData_.self_score
	end
end

function GuildCompetitionBossRankWindow:initWindow()
	self:getComponent()
	GuildCompetitionBossRankWindow.super.initWindow(self)
	self:initUI()
end

function GuildCompetitionBossRankWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.winTitle_ = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.navGroup_ = winTrans:NodeByName("navGroup").gameObject
	self.rankContent_ = winTrans:NodeByName("rankContent").gameObject
	self.rankItemRoot = winTrans:NodeByName("rankContent/item").gameObject
	self.noneGroup_ = winTrans:NodeByName("rankContent/noneGroup").gameObject
	self.labelNoneTips_ = winTrans:ComponentByName("rankContent/noneGroup/labelNoneTips", typeof(UILabel))
	self.rankScroll_ = winTrans:ComponentByName("rankContent/scrollView", typeof(UIScrollView))
	self.rankGrid_ = winTrans:ComponentByName("rankContent/scrollView/grid", typeof(MultiRowWrapContent))
	self.selfRankRoot_ = winTrans:NodeByName("rankContent/groupSelfRankItem").gameObject
	self.rankWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.rankScroll_, self.rankGrid_, self.rankItemRoot, GuildCompetitionBossRankItem, self)
	self.awradContent_ = winTrans:NodeByName("awradContent").gameObject
	self.awardScrollView_ = self.awradContent_:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.awardGrid_ = self.awradContent_:ComponentByName("e:Scroller/awardContainer", typeof(UILayout))
	self.labelAward1_ = self.awradContent_:ComponentByName("labelAward1", typeof(UILabel))
	self.labelAward2_ = self.awradContent_:ComponentByName("labelAward2", typeof(UILabel))
	self.labelTimeLeft_ = self.awradContent_:ComponentByName("labelTimeLeft", typeof(UILabel))

	self.labelTimeLeft_:SetActive(false)

	self.effectGroup_ = self.awradContent_:NodeByName("effectGroup").gameObject
	self.awardItemRoot_ = self.awradContent_:NodeByName("item").gameObject
	self.topItem_ = self.awradContent_:NodeByName("topItem").gameObject
	self.currentRank_ = self.awradContent_:ComponentByName("topItem/currentRank", typeof(UILabel))
	self.itemTitle_ = self.awradContent_:ComponentByName("topItem/itemTitle", typeof(UILabel))
	self.itemGroup_ = self.awradContent_:ComponentByName("topItem/itemGroup", typeof(UILayout))

	if self.isAllGuildAward then
		self.rankContent_:SetActive(false)
		self.navGroup_:SetActive(false)
		self.awradContent_:SetActive(true)
		self.topItem_:Y(330)
	end
end

function GuildCompetitionBossRankWindow:initUI()
	self.winTitle_.text = __("BOOK_RESEARCH_TEXT11")

	if self.isAllGuildAward then
		self.winTitle_.text = __("FRIEND_TEAM_BOSS_AWARD2")
	end

	self.labelNoneTips_.text = __("BOOK_RESEARCH_TEXT12")

	if not self.isAllGuildAward then
		self:initNav()
	else
		self:initAwardAll()
		self:setCountDown()
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function GuildCompetitionBossRankWindow:setCountDown()
	if not self.clockEffect then
		self.clockEffect = xyd.Spine.new(self.effectGroup_)

		self.clockEffect:setInfo("fx_ui_shizhong", function ()
			self.clockEffect:SetLocalScale(1, 1, 1)
			self.clockEffect:SetLocalPosition(0, 0, 0)
			self.clockEffect:play("texiao1", 0)
		end)
	end

	local timeData = xyd.models.guild:getGuildCompetitionLeftTime()

	if self.guildCompetitionTimeCount then
		self.guildCompetitionTimeCount:stopTimeCount()
	end

	self.labelTimeLeft_:SetActive(true)

	if timeData.type == 1 then
		self.labelTimeLeft_.text = __("NO_OPEN")
	elseif timeData.type == 2 then
		self.guildCompetitionTimeCount = CountDown.new(self.labelTimeLeft_, {
			duration = timeData.curEndTime - xyd.getServerTime(),
			callback = handler(self, self.setCountDown)
		})
	else
		self.labelTimeLeft_.text = __("GUILD_COMPETITION_END_TIME")
	end
end

function GuildCompetitionBossRankWindow:willClose()
	if self.guildCompetitionTimeCount then
		self.guildCompetitionTimeCount:stopTimeCount()
	end

	GuildCompetitionBossRankWindow.super.willClose(self)
end

function GuildCompetitionBossRankWindow:playOpenAnimation(callback)
	GuildCompetitionBossRankWindow.super.playOpenAnimation(self, function ()
		if not self.isAllGuildAward then
			self:initRankList()
		end

		if callback then
			callback()
		end
	end)
end

function GuildCompetitionBossRankWindow:initNav()
	self.tab = import("app.common.ui.CommonTabBar").new(self.navGroup_, 2, function (index)
		self:updateLayout(index)
	end)

	self.tab:setTexts({
		__("RANK"),
		__("AWARD3")
	})
end

function GuildCompetitionBossRankWindow:updateLayout(index)
	self.rankContent_:SetActive(index == 1)
	self.awradContent_:SetActive(index == 2)

	if index == 2 and not self.hasInitAward_ then
		self:initAward()
	end
end

function GuildCompetitionBossRankWindow:initRankList()
	self.selfRankRoot_.transform:SetLocalScale(1, 1, 1)

	local params = {
		hide_bg = true,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		lev = xyd.models.backpack:getLev(),
		player_name = xyd.models.selfPlayer:getPlayerName(),
		score = self.self_data_.score,
		rank = self.self_data_.rank
	}
	local newRoot = NGUITools.AddChild(self.selfRankRoot_, self.rankItemRoot)

	newRoot.transform:SetLocalPosition(0, 49, 0)

	local selfRankItem = GuildCompetitionBossRankItem.new(newRoot, self, params, true)

	selfRankItem:setDepth(15)

	if not self.rank_data_ or #self.rank_data_ == 0 then
		self.noneGroup_:SetActive(true)

		return
	else
		self.noneGroup_:SetActive(false)
	end

	self.rankListInfo_ = {}

	for i = 1, #self.rank_data_ do
		local data = self.rank_data_[i]
		local params = {
			avatar_id = data.avatar_id,
			avatar_frame_id = data.avatar_frame_id,
			lev = data.lev,
			player_name = data.player_name,
			score = data.score,
			rank = i
		}

		table.insert(self.rankListInfo_, params)
	end

	self.rankWrap_:setInfos(self.rankListInfo_, {})
end

function GuildCompetitionBossRankWindow:initAward()
	self.hasInitAward_ = true
	self.labelAward1_.text = tostring(__("GUILD_BOSS_AWARD_2")) .. ":"

	self.labelAward1_:SetActive(false)

	self.labelAward2_.text = tostring(__("GUILD_COMPETITION_EVERY_BOSS_AWARD"))

	self:initKillAward()
	self:initBattleAward()
end

function GuildCompetitionBossRankWindow:initKillAward()
	local rankMaxId = #xyd.tables.guildCompetitionPersonalRankTable:getIds()

	for i = 1, rankMaxId do
		local rank = xyd.tables.guildCompetitionPersonalRankTable:getRank(i)
		local awardsData = xyd.tables.guildCompetitionPersonalRankTable:getAwards(rank)
		local go = NGUITools.AddChild(self.awardGrid_.gameObject, self.awardItemRoot_)
		local awardItem = GuildBossKillAwardItem.new(go, {
			awardsData = awardsData,
			rank = rank,
			id = i
		}, self)
	end

	self.awardGrid_:Reposition()
	self.awardScrollView_:ResetPosition()
end

function GuildCompetitionBossRankWindow:initBattleAward()
	self.itemTitle_.text = __("NOW_AWARD")
	local rank = self.self_data_.rank

	if rank == -1 then
		self.currentRank_.text = __("NOW_RANK") .. self.rank_mark .. " -"
		self.itemTitle_.text = __("NOW_AWARD") .. " -"
	else
		self.currentRank_.text = __("NOW_RANK") .. self.rank_mark .. rank
		local awardData = xyd.tables.guildCompetitionPersonalRankTable:getAwards(rank)

		if #awardData > 0 then
			for _, info in pairs(awardData) do
				local params = {
					labelNumScale = 1.6,
					hideText = true,
					itemID = info[1],
					num = info[2],
					uiRoot = self.itemGroup_.gameObject
				}
				local itemIcon = xyd.getItemIcon(params)

				itemIcon:SetLocalScale(0.72, 0.72, 1)
			end

			self.itemGroup_:Reposition()

			if #awardData >= 4 and self.itemTitle_.width > 198 then
				self.itemTitle_.overflowMethod = UILabel.Overflow.ShrinkContent
				self.itemTitle_.width = 200
				self.itemTitle_.height = 70
			end
		else
			self.itemTitle_.text = __("NOW_AWARD") .. " -"
		end
	end
end

function GuildCompetitionBossRankWindow:initAwardAll()
	self.labelAward1_.text = tostring(__("GUILD_BOSS_AWARD_2")) .. ":"

	self.labelAward1_:SetActive(false)

	self.labelAward2_.text = tostring(__("GUILD_COMPETITION_ALL_GUILD_AWARD"))

	self:initKillAwardAll()
	self:initBattleAwardAll()
end

function GuildCompetitionBossRankWindow:initKillAwardAll()
	local rankMaxId = #xyd.tables.guildCompetitionGroupRankTable:getIds()

	for i = 1, rankMaxId do
		local rank = xyd.tables.guildCompetitionGroupRankTable:getRank(i)
		local awardsData = {}
		local normalAward = xyd.tables.guildCompetitionGroupRankTable:getItems(i)
		local frameAward = xyd.tables.guildCompetitionGroupRankTable:getFrame(i)

		if frameAward ~= nil then
			for _, info in pairs(frameAward) do
				table.insert(awardsData, info)
			end
		end

		if normalAward ~= nil then
			for _, info in pairs(normalAward) do
				table.insert(awardsData, info)
			end
		end

		local go = NGUITools.AddChild(self.awardGrid_.gameObject, self.awardItemRoot_)
		local awardItem = GuildBossKillAwardItem.new(go, {
			awardsData = awardsData,
			rank = rank,
			id = i
		}, self)
	end

	self.awardGrid_:Reposition()
	self:waitForFrame(1, function ()
		self.awardScrollView_:ResetPosition()
	end)
end

function GuildCompetitionBossRankWindow:initBattleAwardAll()
	self.itemTitle_.text = __("NOW_AWARD")
	local rank = xyd.models.guild:getGuildCompetitionInfo().guild_rank
	rank = not rank and -1 or rank + 1

	if rank == -1 then
		self.currentRank_.text = __("NOW_RANK") .. self.rank_mark .. " -"
		self.itemTitle_.text = __("NOW_AWARD") .. " -"
	else
		local rankMaxId = #xyd.tables.guildCompetitionGroupRankTable:getIds()
		local search_id = -1

		for i = 1, rankMaxId do
			local is_percentage = xyd.tables.guildCompetitionGroupRankTable:getIsPercentage(i)

			if not is_percentage or is_percentage and is_percentage == 0 then
				local target_rank = xyd.tables.guildCompetitionGroupRankTable:getRank(i)

				if rank <= target_rank then
					search_id = i

					break
				end
			end
		end

		if search_id == -1 then
			for i = 1, rankMaxId do
				local is_percentage = xyd.tables.guildCompetitionGroupRankTable:getIsPercentage(i)

				if is_percentage and is_percentage == 1 then
					local target_value = xyd.tables.guildCompetitionGroupRankTable:getRank(i)
					local search_value = (xyd.models.guild:getGuildCompetitionInfo().guild_rank + 1) / xyd.models.guild:getGuildCompetitionInfo().guild_rank_sum

					if search_value > 1 then
						search_value = 1
					end

					if target_value >= search_value * 100 then
						search_id = i

						break
					end
				end
			end
		end

		if search_id == -1 then
			search_id = rankMaxId
		end

		self.currentRank_.text = __("NOW_RANK") .. self.rank_mark .. xyd.tables.guildCompetitionGroupRankTable:getShow(search_id)
		local is_percentage = xyd.tables.guildCompetitionGroupRankTable:getIsPercentage(search_id)
		local show_text = xyd.tables.guildCompetitionGroupRankTable:getShow(search_id)

		if is_percentage and is_percentage == 1 then
			self.currentRank_.text = __("NOW_RANK") .. self.rank_mark .. tostring(tonumber(show_text) * 100) .. "%"
		else
			self.currentRank_.text = __("NOW_RANK") .. self.rank_mark .. show_text
		end

		local awardData = {}
		local normalAward = xyd.tables.guildCompetitionGroupRankTable:getItems(search_id)
		local frameAward = xyd.tables.guildCompetitionGroupRankTable:getFrame(search_id)

		if frameAward ~= nil then
			for _, info in pairs(frameAward) do
				table.insert(awardData, info)
			end
		end

		if normalAward ~= nil then
			for _, info in pairs(normalAward) do
				table.insert(awardData, info)
			end
		end

		if #awardData > 0 then
			for _, info in pairs(awardData) do
				local params = {
					labelNumScale = 1.6,
					hideText = true,
					itemID = info[1],
					num = info[2],
					uiRoot = self.itemGroup_.gameObject
				}
				local itemIcon = xyd.getItemIcon(params)

				if xyd.getItemIconType(info[1]) == 1 then
					itemIcon:SetLocalScale(0.64, 0.64, 1)
				else
					itemIcon:SetLocalScale(0.72, 0.72, 1)
				end
			end

			self.itemGroup_:Reposition()

			if #awardData >= 4 and self.itemTitle_.width > 198 then
				self.itemTitle_.overflowMethod = UILabel.Overflow.ShrinkContent
				self.itemTitle_.width = 200
				self.itemTitle_.height = 70
			end
		else
			self.itemTitle_.text = __("NOW_AWARD") .. " -"
		end
	end
end

function GuildBossKillAwardItem:ctor(go, params, parent)
	self.parent_ = parent
	self.go = go
	self.awardsData = params.awardsData
	self.rank = params.rank
	self.id = params.id

	self:getUIComponent()
	self:initUIComponent()
end

function GuildBossKillAwardItem:getUIComponent()
	local go = self.go
	self.itemTitle = go:ComponentByName("itemTitle", typeof(UILabel))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.rankImg = go:ComponentByName("rankImg", typeof(UISprite))
end

function GuildBossKillAwardItem:initUIComponent()
	if self.parent_.isAllGuildAward then
		if self.rank <= 3 and self.id <= 3 then
			xyd.setUISprite(self.rankImg, nil, "rank_icon0" .. self.rank)
			self.rankImg:SetActive(true)
			self.itemTitle:SetActive(false)
		else
			self.rankImg:SetActive(false)
			self.itemTitle:SetActive(true)

			local is_percentage = xyd.tables.guildCompetitionGroupRankTable:getIsPercentage(self.id)
			local show_text = xyd.tables.guildCompetitionGroupRankTable:getShow(self.id)

			if is_percentage and is_percentage == 1 then
				self.itemTitle.text = tostring(tonumber(show_text) * 100) .. "%"
			else
				self.itemTitle.text = show_text
			end
		end
	elseif self.rank <= 3 then
		xyd.setUISprite(self.rankImg, nil, "rank_icon0" .. self.rank)
		self.rankImg:SetActive(true)
		self.itemTitle:SetActive(false)
	else
		self.rankImg:SetActive(false)
		self.itemTitle:SetActive(true)

		self.itemTitle.text = xyd.tables.guildCompetitionPersonalRankTable:getShow(self.id)
	end

	for i = 1, #self.awardsData do
		local itemData = self.awardsData[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			uiRoot = self.itemGroup,
			itemID = itemId,
			dragScrollView = self.parent_.scroller,
			num = itemNum
		})

		itemIcon:AddUIDragScrollView()

		if xyd.getItemIconType(itemId) == 1 then
			itemIcon:SetLocalScale(0.64, 0.64, 1)
		else
			itemIcon:SetLocalScale(0.72, 0.72, 1)
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

return GuildCompetitionBossRankWindow
