local ActivityHw2022RankWindow = class("ActivityHw2022RankWindow", import(".BaseWindow"))
local GuildBossRankItem = class("GuildBossRankItem", require("app.components.CopyComponent"))
local AwardItem = class("AwardItem")
local CountDown = import("app.components.CountDown")

function GuildBossRankItem:ctor(go, parent, params, noPanel)
	self.parent_ = parent
	self.rankData = params
	self.noPanel_ = noPanel

	GuildBossRankItem.super.ctor(self, go)
	self:getUIComponent()
	self:initUIComponent()
end

function GuildBossRankItem:getUIComponent()
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
	self.labelScoreTips.text = __("SCORE")
end

function GuildBossRankItem:initUIComponent()
	if not self.rankData then
		return
	end

	self.labelName.text = self.rankData.player_name

	if self.rankData.rank <= 3 then
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
	self.labelScore.text = xyd.getRoughDisplayNumber3(tonumber(self.rankData.score))
end

function GuildBossRankItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.rankData = info

	self:initUIComponent()
end

function ActivityHw2022RankWindow:ctor(name, params)
	ActivityHw2022RankWindow.super.ctor(self, name, params)

	self.rankData_ = params.rankData

	self:initRankInfo()
end

function ActivityHw2022RankWindow:initRankInfo()
	self.rank_data_ = self.rankData_.list or {}
	self.self_data_ = {
		rank = -1,
		score = 0
	}

	if self.rankData_.self_rank and self.rankData_.self_rank >= 0 then
		self.self_data_ = {
			rank = self.rankData_.self_rank + 1,
			score = self.rankData_.self_score
		}
	end
end

function ActivityHw2022RankWindow:initWindow()
	ActivityHw2022RankWindow.super.initWindow(self)
	self:getComponent()
	self:initUI()
end

function ActivityHw2022RankWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.winTitle_ = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.navGroup_ = winTrans:NodeByName("navGroup").gameObject
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.rankContent_ = winTrans:NodeByName("rankContent").gameObject
	self.rankItemRoot = winTrans:NodeByName("rankContent/item").gameObject
	self.noneGroup_ = winTrans:NodeByName("rankContent/noneGroup").gameObject
	self.labelNoneTips_ = winTrans:ComponentByName("rankContent/noneGroup/labelNoneTips", typeof(UILabel))
	self.rankScroll_ = winTrans:ComponentByName("rankContent/scrollView", typeof(UIScrollView))
	self.rankGrid_ = winTrans:ComponentByName("rankContent/scrollView/grid", typeof(MultiRowWrapContent))
	self.selfRankRoot_ = winTrans:NodeByName("rankContent/groupSelfRankItem").gameObject
	self.rankWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.rankScroll_, self.rankGrid_, self.rankItemRoot, GuildBossRankItem, self)
	self.awradContent_ = winTrans:NodeByName("awradContent").gameObject
	self.awardScrollView_ = self.awradContent_:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.awardGrid_ = self.awradContent_:ComponentByName("e:Scroller/awardContainer", typeof(UILayout))
	self.labelAward1_ = self.awradContent_:ComponentByName("labelAward1", typeof(UILabel))
	self.labelAward2_ = self.awradContent_:ComponentByName("labelAward2", typeof(UILabel))
	self.labelTimeLeft_ = self.awradContent_:ComponentByName("labelTimeLeft", typeof(UILabel))
	self.effectGroup_ = self.awradContent_:NodeByName("effectGroup").gameObject
	self.awardItemRoot_ = self.awradContent_:NodeByName("item").gameObject
	self.currentRank_ = self.awradContent_:ComponentByName("topItem/currentRank", typeof(UILabel))
	self.itemTitle_ = self.awradContent_:ComponentByName("topItem/itemTitle", typeof(UILabel))
	self.itemGroup_ = self.awradContent_:ComponentByName("topItem/itemGroup", typeof(UILayout))
	self.upGroup = self.rankContent_:NodeByName("upGroup").gameObject
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
		self["groupIcon" .. i] = self["serverInfo" .. i]:ComponentByName("groupIcon" .. i, typeof(UISprite))
		self["downLevelCon" .. i] = self["showCon" .. i]:NodeByName("downLevelCon" .. i).gameObject
		self["downLevelCon" .. i .. "_UILayout"] = self["showCon" .. i]:ComponentByName("downLevelCon" .. i, typeof(UILayout))
		self["labelDesText" .. i] = self["downLevelCon" .. i]:ComponentByName("labelDesText" .. i, typeof(UILabel))
		self["labelDesIcon" .. i] = self["downLevelCon" .. i]:ComponentByName("labelDesIcon" .. i, typeof(UISprite))
		self["labelCurrentNum" .. i] = self["downLevelCon" .. i]:ComponentByName("labelCurrentNum" .. i, typeof(UILabel))
		self["personEffectCon" .. i] = self["showCon" .. i]:NodeByName("personEffectCon" .. i).gameObject
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_HALLOWEEN2022_RANK_HELP"
		})
	end
end

function ActivityHw2022RankWindow:initUI()
	self.winTitle_.text = __("BOOK_RESEARCH_TEXT11")
	self.labelNoneTips_.text = __("BOOK_RESEARCH_TEXT12")

	self:initNav()
	self:setCountDown()

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityHw2022RankWindow:setCountDown()
	local tomorrowTime = xyd.getTomorrowTime()
	local tomorrowWeekDay = os.date("%w", tomorrowTime)

	if tomorrowWeekDay == 0 then
		tomorrowWeekDay = 7
	end

	local fridayTime = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_HW2022):getEndTime()
	local params = {
		duration = fridayTime - xyd.getServerTime()
	}
	local effect = xyd.Spine.new(self.effectGroup_)

	if xyd.Global.lang == "fr_fr" then
		self.effectGroup_.transform:X(195)
	end

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao1", 0)
	end)

	self.labelRefreshTime_ = CountDown.new(self.labelTimeLeft_, params)
end

function ActivityHw2022RankWindow:playOpenAnimation(callback)
	ActivityHw2022RankWindow.super.playOpenAnimation(self, function ()
		self:initRankList()

		if callback then
			callback()
		end
	end)
end

function ActivityHw2022RankWindow:initNav()
	self.tab = import("app.common.ui.CommonTabBar").new(self.navGroup_, 2, function (index)
		self:updateLayout(index)
	end)

	self.tab:setTexts({
		__("ACTIVITY_HALLOWEEN2022_RANK_TEXT01"),
		__("ACTIVITY_HALLOWEEN2022_RANK_TEXT02")
	})
end

function ActivityHw2022RankWindow:updateLayout(index)
	self.rankContent_:SetActive(index == 1)
	self.awradContent_:SetActive(index == 2)

	if index == 2 and not self.hasInitAward_ then
		self:initAward()
	end
end

function ActivityHw2022RankWindow:initRankList()
	if not self.rank_data_ or #self.rank_data_ == 0 then
		self.noneGroup_:SetActive(true)

		return
	else
		self.noneGroup_:SetActive(false)
	end

	self:updateThree(self.rank_data_)

	self.rankListInfo_ = {}

	if self.self_data_.rank == -1 then
		self.selfRankRoot_.transform:SetLocalScale(1, 0, 1)
	else
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

		local selfRankItem = GuildBossRankItem.new(newRoot, self, params, true)

		selfRankItem:setDepth(15)
	end

	for i = 4, #self.rank_data_ do
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

function ActivityHw2022RankWindow:updateThree(rankData)
	for i = 1, 3 do
		if rankData[i] then
			self["showCon" .. i].gameObject:SetActive(true)

			self["labelPlayerName" .. i].text = tostring(rankData[i].player_name)
			self["labelDesText" .. i].text = __("ACTIVITY_HALLOWEEN2022_RANK_TEXT04")
			self["serverId" .. i].text = xyd.getServerNumber(rankData[i].server_id)
			self["labelCurrentNum" .. i].text = tostring(math.ceil(rankData[i].score or 0))

			if rankData[i].group then
				xyd.setUISpriteAsync(self["groupIcon" .. i], nil, "arctic_expedition_cell_group_icon_" .. rankData[i].group, function ()
				end, nil, )
			end

			if i == 2 or i == 3 then
				while true do
					if self["labelPlayerName" .. i].width > 208 then
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

			local styles = rankData[i].dress_style
			styles = styles or xyd.tables.miscTable:split2num("robot_dress_unit", "value", "|")

			self["personEffect" .. i]:setModelInfo({
				ids = styles
			})

			self["showConPlayer" .. i] = rankData[i].player_id

			if not self["showCon" .. i .. "addEvent"] then
				self["showCon" .. i .. "addEvent"] = true
				UIEventListener.Get(self["showCon" .. i].gameObject).onClick = handler(self, function ()
					if self["showConPlayer" .. i] ~= xyd.Global.playerID then
						xyd.models.arena:reqEnemyInfo(self["showConPlayer" .. i])
					end
				end)
			end
		else
			self["showCon" .. i].gameObject:SetActive(false)
		end
	end
end

function ActivityHw2022RankWindow:initAward()
	self.hasInitAward_ = true
	self.labelAward1_.text = tostring(__("GUILD_BOSS_AWARD_2")) .. " :"
	self.labelAward2_.text = tostring(__("ACTIVITY_HALLOWEEN2022_RANK_TEXT03"))

	self:initKillAward()
	self:initBattleAward()
end

function ActivityHw2022RankWindow:initKillAward()
	local rankMaxId = xyd.tables.activityHw2022RankTable:getMaxID()

	for i = 1, rankMaxId do
		local rank = xyd.tables.activityHw2022RankTable:getRank(i)
		local awardsData = xyd.tables.activityHw2022RankTable:getAwards(i)
		local go = NGUITools.AddChild(self.awardGrid_.gameObject, self.awardItemRoot_)
		local awardItem = AwardItem.new(go, {
			awardsData = awardsData,
			rank = rank,
			id = i
		}, self)
	end

	self.awardGrid_:Reposition()
	self.awardScrollView_:ResetPosition()
end

function ActivityHw2022RankWindow:initBattleAward()
	local rank = self.self_data_.rank

	if rank == -1 then
		self.currentRank_.text = __("NOW_RANK") .. "-"
		self.itemTitle_.text = __("NOW_AWARD") .. "-"
	else
		local rankText = xyd.tables.activityHw2022RankTable:getShowByRank(rank)

		if rankText and rankText ~= "" then
			self.currentRank_.text = __("NOW_RANK") .. " : " .. rankText
			self.itemTitle_.text = __("NOW_AWARD")
		else
			self.currentRank_.text = __("NOW_RANK") .. " : " .. rank
			self.itemTitle_.text = __("NOW_AWARD") .. "-"
		end
	end

	local awardsDataList = xyd.tables.activityHw2022RankTable:getAwardsByRank(rank)

	for i = 1, #awardsDataList do
		local itemData = awardsDataList[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			wndType = 5,
			showSellLable = false,
			uiRoot = self.itemGroup_.gameObject,
			itemID = itemId,
			num = itemNum,
			scale = Vector3(0.72, 0.72, 1)
		})
	end

	self.itemGroup_:Reposition()
end

function AwardItem:ctor(go, params, parent)
	self.parent_ = parent
	self.go = go
	self.awardsData = params.awardsData
	self.rank = params.rank
	self.id = params.id

	self:getUIComponent()
	self:initUIComponent()
end

function AwardItem:getUIComponent()
	local go = self.go
	self.itemTitle = go:ComponentByName("itemTitle", typeof(UILabel))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.rankImg = go:ComponentByName("rankImg", typeof(UISprite))
end

function AwardItem:initUIComponent()
	if self.rank <= 3 then
		xyd.setUISprite(self.rankImg, nil, "rank_icon0" .. self.rank)
		self.rankImg:SetActive(true)
		self.itemTitle:SetActive(false)
	else
		self.rankImg:SetActive(false)
		self.itemTitle:SetActive(true)

		self.itemTitle.text = xyd.tables.activityHw2022RankTable:getShowRank(self.id)
	end

	for i = 1, #self.awardsData do
		local itemData = self.awardsData[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			wndType = 5,
			uiRoot = self.itemGroup,
			itemID = itemId,
			dragScrollView = self.parent_.scroller,
			num = itemNum
		})

		itemIcon:SetLocalScale(0.72, 0.72, 1)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

return ActivityHw2022RankWindow
