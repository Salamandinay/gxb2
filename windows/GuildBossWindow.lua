local BaseWindow = import(".BaseWindow")
local GuildBossWindow = class("GuildBossWindow", BaseWindow)
local GuildBossRankItem = class("GuildBossRankItem", require("app.components.CopyComponent"))

function GuildBossWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.costNum = 0
	self.bossId_ = params.bossId or 0
end

function GuildBossWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()

	self.bossData_ = xyd.models.guild:getBossInfo(self.bossId_)

	if self.bossData_ then
		self:refresh()
	else
		xyd.models.guild:reqBossInfo(self.bossId_)
	end
end

function GuildBossWindow:getUIComponent()
	local go = self.window_:NodeByName("groupAction").gameObject
	self.labelWinTitle = go:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.midGroup = go:NodeByName("midGroup").gameObject
	self.guild_boss_card = self.midGroup:NodeByName("guild_boss_card").gameObject
	self.labelID = self.midGroup:ComponentByName("labelID", typeof(UILabel))
	local labelFightTime = self.midGroup:ComponentByName("labelFightTime", typeof(UILabel))
	self.labelFightTime = require("app.components.CountDown").new(labelFightTime)
	local btnFight = self.midGroup:NodeByName("btnFight").gameObject
	self.btnFight = require("app.components.SummonButton").new(btnFight)
	self.helpBtn = self.midGroup:NodeByName("helpBtn").gameObject
	self.btnAward = self.midGroup:NodeByName("btnAward").gameObject
	self.hpProgress = self.midGroup:ComponentByName("hpProgress", typeof(UIProgressBar))
	self.hpProgressLabel = self.midGroup:ComponentByName("hpProgress/label", typeof(UILabel))
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	self.damageRankContainer = go:NodeByName("e:Scroller/damageRankContainer").gameObject
	self.groupNone_ = go:NodeByName("e:Image/groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	self.item = self.window_:NodeByName("item").gameObject

	self.item:SetActive(false)
	self.guild_boss_card:SetActive(false)
end

function GuildBossWindow:initUIComponent()
	local GuildBossCard = require("app.windows.GuildGymWindow").GuildBossCard
	self.labelID.text = xyd.tables.guildBossTextTable:getShowWord(self.bossId_)
	self.labelRank.text = __("DAMAGE_RANK")

	self.btnFight:getGameObject():SetActive(false)
	self.hpProgress:SetActive(false)

	self.card = GuildBossCard.new(self.guild_boss_card, {})

	self.card:addParentDepth()
	self.card:updateBossID(self.bossId_)
	self.guild_boss_card:SetActive(true)

	local updateTime = xyd.models.guild:getFightUpdateTime()

	if xyd.getServerTime() < updateTime then
		self.labelFightTime:setInfo({
			duration = updateTime - xyd.getServerTime()
		})

		self.labelTimeVisible = true
	else
		self.labelTimeVisible = false
	end

	self.midGroup:SetActive(true)
	self.groupNone_:SetActive(false)

	self.labelNoneTips_.text = __("NO_RANK_DATA")
end

function GuildBossWindow:register()
	BaseWindow.register(self)
	xyd.setDarkenBtnBehavior(self.btnAward, self, self.onClickAwardBtn)
	xyd.setDarkenBtnBehavior(self.btnFight:getGameObject(), self, self.onClickFightBtn)
	self.eventProxy_:addEventListener(xyd.event.GUILD_BOSS_INFO, self.refreshData, self)
end

function GuildBossWindow:refreshData()
	self.bossData_ = xyd.models.guild:getBossInfo(self.bossId_)

	if self.bossData_ then
		self:refresh()
	else
		xyd.WindowManager.get():closeWindow(self)
	end
end

function GuildBossWindow:refresh()
	self.bossInfo_ = self.bossData_.bossInfo
	self.bossRank_ = self.bossData_.bossRank

	if not self.bossInfo_ then
		return
	end

	self:updateProgressBar()
	self:updateFightBtn()
	self:updateRank()
	self.labelFightTime:SetActive(self.labelTimeVisible)
end

function GuildBossWindow:updateRank()
	if self.bossRank_.length == 0 then
		self.groupNone_:SetActive(true)
	else
		local rank_info = {
			"score",
			"player_name",
			"avatar_id",
			"avatar_frame_id",
			"lev",
			"player_id",
			"power",
			"server_id"
		}

		NGUITools.DestroyChildren(self.damageRankContainer.transform)

		for i = 1, #self.bossRank_ do
			local rankData = {}

			for _, k in ipairs(rank_info) do
				rankData[k] = self.bossRank_[i][k]
			end

			rankData.rank = i
			local go = NGUITools.AddChild(self.damageRankContainer, self.item)
			local rankItem = GuildBossRankItem.new(go, rankData)
		end

		self.damageRankContainer:GetComponent(typeof(UILayout)):Reposition()
	end
end

function GuildBossWindow:updateFightBtn()
	local res = xyd.models.guild:getFightCost()
	local updateTime = xyd.models.guild:getFightUpdateTime()

	if xyd.getServerTime() < updateTime then
		if res.fightTimes > 3 then
			self.btnFight:setCostIcon()
			xyd.setUISprite(self.btnFight:getGameObject():GetComponent(typeof(UISprite)), nil, "prop_btn_mid")
			xyd.setBtnLabel(self.btnFight:getGameObject(), {
				strokeColor = 4294967295.0,
				textColor = 1012112383,
				text = __("FIGHT")
			})
			xyd.setEnabled(self.btnFight:getGameObject(), false)
		else
			self.btnFight:setCostIcon({
				2,
				res.costNum
			})
			xyd.setUISprite(self.btnFight:getGameObject():GetComponent(typeof(UISprite)), nil, "blue_btn_65_65")
			xyd.setBtnLabel(self.btnFight:getGameObject(), {
				strokeColor = 1012112383,
				textColor = 4294967295.0,
				text = __("REVIVE")
			})
			xyd.setEnabled(self.btnFight:getGameObject(), true)

			if xyd.Global.lang == "de_de" then
				self.btnFight.label:X(30)
			end
		end
	else
		self.btnFight:setCostIcon()
		xyd.setUISprite(self.btnFight:getGameObject():GetComponent(typeof(UISprite)), nil, "blue_btn_65_65")
		xyd.setBtnLabel(self.btnFight:getGameObject(), {
			strokeColor = 1012112383,
			textColor = 4294967295.0,
			text = __("FIGHT")
		})
	end

	self.btnFight:SetActive(true)

	if xyd.Global.lang == "fr_fr" then
		self.btnFight.go:NodeByName("itemIcon"):X(-65)
	end
end

function GuildBossWindow:updateProgressBar()
	local percentNum = 0
	local nowTotalHp = 0
	local enemies = self.bossInfo_.enemies

	for i = 1, #enemies do
		local status = enemies[i].status

		if status.true_hp == nil then
			percentNum = 1

			break
		end

		nowTotalHp = nowTotalHp + tonumber(status.true_hp)
	end

	local totalHp = xyd.tables.guildBossTable:getTotalHp(self.bossId_)

	if percentNum ~= 1 then
		percentNum = nowTotalHp / totalHp
	end

	self.hpProgress.value = percentNum
	self.hpProgressLabel.text = tostring(math.ceil(percentNum * 100)) .. "%"

	self.hpProgress:SetActive(true)
end

function GuildBossWindow:onClickFightBtn()
	local fightTime = xyd.models.guild:getGuildBossTime()[2] or 0

	if xyd.isToday(fightTime) then
		xyd.alertTips(__("GUILD_BOSS_CANT_FIGHT"))

		return
	end

	local hasNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)

	if self.costNum <= hasNum then
		local fightParams = {
			forceConfirm = 1,
			alpha = 0.7,
			no_close = true,
			mapType = xyd.MapType.GUILD_BOSS,
			battleType = xyd.BattleType.GUILD_BOSS,
			bossId = self.bossId_
		}

		xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
	else
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))
	end
end

function GuildBossWindow:onClickAwardBtn()
	xyd.WindowManager.get():openWindow("guild_boss_award_window", {
		bossId = self.bossId_
	})
end

function GuildBossRankItem:ctor(go, params)
	GuildBossRankItem.super.ctor(self, go)

	self.rankData = params

	self:getUIComponent()
	self:initUIComponent()
end

function GuildBossRankItem:getUIComponent()
	local go = self.go
	self.labelName = go:ComponentByName("labelName", typeof(UILabel))
	self.imgRank = go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	local pIcon = go:NodeByName("pIcon").gameObject
	self.pIcon = require("app.components.PlayerIcon").new(pIcon)
	self.lv = go:ComponentByName("lv", typeof(UILabel))
	self.labelScore = go:ComponentByName("labelScore", typeof(UILabel))
end

function GuildBossRankItem:initUIComponent()
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
	self.pIcon:SetLocalScale(0.65, 0.65, 1)

	self.lv.text = tostring(self.rankData.lev)
	self.labelScore.text = xyd.getRoughDisplayNumber2(tonumber(self.rankData.score))
end

return GuildBossWindow
