local BaseWindow = import(".BaseWindow")
local GuildCompetitionMainWindow = class("GuildCompetitionMainWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local PngNum = import("app.components.PngNum")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local GuildCompetitionRecordItem = class("GuildCompetitionRecordItem", import("app.components.CopyComponent"))
local PersonItem = class("ValueGiftBagItem", import("app.components.CopyComponent"))
local small_size = 150
local small_y = -441 - 82 * xyd.getScale_Num_shortToLong()
local big_size = 346
local big_y = small_y + 346 - 150

function PersonItem:ctor(goItem, itemdata)
	self.goItem_ = goItem
	self.transGo = goItem.transform

	if itemdata.index == 1 then
		self.goItem_:SetLocalPosition(160, 383, 0)
	elseif itemdata.index == 2 then
		self.goItem_:SetLocalPosition(-166, 187, 0)
	elseif itemdata.index == 3 then
		self.goItem_:SetLocalPosition(186, -253, 0)
	end

	self.partnerId = itemdata.partnerId
	self.bossIndex = itemdata.index
	self.personEffect = self.transGo:ComponentByName("personEffect", typeof(UITexture))
	self.personInfoCon = self.transGo:NodeByName("personInfoCon").gameObject
	self.personInfoBg = self.personInfoCon:ComponentByName("personInfoBg", typeof(UISprite))
	self.personNameText = self.personInfoCon:ComponentByName("personNameText", typeof(UILabel))
	self.progressNameText = self.personInfoCon:ComponentByName("progressNameText", typeof(UILabel))
	self.progress = self.personInfoCon:ComponentByName("progress", typeof(UIProgressBar))
	self.onclickImg = self.personInfoCon:ComponentByName("onclickImg", typeof(UISprite))

	self:initItem(itemdata)
	self:initBaseInfo(itemdata)
end

function PersonItem:initBaseInfo(itemdata)
	local effectName = xyd.tables.modelTable:getModelName(itemdata.modelId)
	local effectScale = xyd.tables.modelTable:getScale(itemdata.modelId)
	local effectScale_x_ratio = -1

	if self.bossIndex == 2 then
		effectScale_x_ratio = 1
	end

	self.Effect_ = xyd.Spine.new(self.personEffect.gameObject)

	self.Effect_:setInfo(effectName, function ()
		self.Effect_:SetLocalScale(effectScale * effectScale_x_ratio, effectScale, effectScale)
		self.Effect_:play("idle", 0)
	end, true)

	UIEventListener.Get(self.onclickImg.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("guild_competition_fight_window", {
			bossIndex = self.bossIndex,
			roundIndex = self:getRoundIndex()
		})
	end)
end

function PersonItem:initItem(itemdata)
	self:updateShow()
end

function PersonItem:updateShow()
	self.progress.value = xyd.models.guild:getGuildCompetitionBossPress(self.bossIndex).provalue
	self.personNameText.text = xyd.tables.partnerTextTable:getName(self.partnerId) .. "(" .. __("GUILD_COMPETITION_ROUND", xyd.models.guild:getGuildCompetitionInfo().boss_info.rounds[self.bossIndex]) .. ")"
end

function PersonItem:getBossInfo()
	return xyd.models.guild:getGuildCompetitionInfo().boss_info
end

function PersonItem:getRoundIndex()
	return tonumber(self:getBossInfo().enemy_lvs[self.bossIndex])
end

function GuildCompetitionRecordItem:ctor(go, parent)
	GuildCompetitionRecordItem.super.ctor(self, go)

	self.parent = parent

	self:getUIComponent()
end

function GuildCompetitionRecordItem:getUIComponent()
	self.recordItem = self.go
	self.recordItemBg = self.recordItem:ComponentByName("recordItemBg", typeof(UISprite))
	self.nameText = self.recordItem:ComponentByName("nameText", typeof(UILabel))
	self.timeText = self.recordItem:ComponentByName("timeText", typeof(UILabel))
	self.detailsText = self.recordItem:ComponentByName("detailsText", typeof(UILabel))
	self.detailsGoBtn = self.recordItem:NodeByName("detailsGoBtn").gameObject
	self.detailsText.text = __("ITEM_DETAIL")

	self.detailsText:SetActive(false)
	self.detailsGoBtn:SetActive(false)

	UIEventListener.Get(self.detailsGoBtn.gameObject).onClick = handler(self, self.onclick)
end

function GuildCompetitionRecordItem:update(index, info)
	local data = info

	if not data then
		self.go:SetActive(false)

		return
	end

	self.info = info

	self.go:SetActive(true)
	self.detailsText:SetActive(true)
	self.detailsGoBtn:SetActive(true)

	local partnerArr = xyd.tables.miscTable:split2num("guild_competition_boss_model", "value", "|")
	local bossName = xyd.tables.partnerTextTable:getName(partnerArr[self.info.boss_id])
	self.nameText.text = __("GUILD_COMPETITION_HURT_TEXT", self.info.show_info.player_name, bossName, xyd.getRoughDisplayNumber3(tonumber(self.info.total_harm)))
	self.timeText.text = xyd.getReceiveTime(self.info.time)
end

function GuildCompetitionRecordItem:onclick()
	if not self.info then
		return
	end

	if #self.info.partners <= 0 then
		xyd.showToast(__("SCHOOL_PRACTISE_RANK_TIP"))

		return
	end

	xyd.WindowManager:get():openWindow("guild_competition_formation_window", {
		player_id = self.info.show_info.player_id,
		player_name = self.info.show_info.player_name,
		avatar_frame = self.info.show_info.avatar_frame_id,
		avatar_id = self.info.show_info.avatar_id,
		info = self.info.partners,
		lev = self.info.show_info.lev,
		pet_id = self.info.pet_id,
		total_harm = self.info.total_harm
	})
end

function GuildCompetitionMainWindow:ctor(name, params)
	GuildCompetitionMainWindow.super.ctor(self, name, params)
end

function GuildCompetitionMainWindow:initWindow()
	GuildCompetitionMainWindow.super.initWindow(self)

	self.showRecordIsSmall = true

	self:getUIComponent()
	self:playEnterEffect()
	self:initUIComponent()
	xyd.models.guild:getGuildCompetitionServerData()
end

function GuildCompetitionMainWindow:getUIComponent()
	local go = self.window_
	self.groupAction = go:NodeByName("groupAction").gameObject
	self.scoreCon = self.groupAction:NodeByName("scoreCon").gameObject
	self.scoreConTextImg = self.scoreCon:ComponentByName("scoreConTextImg", typeof(UISprite))
	self.scoreNumCon = self.scoreCon:NodeByName("scoreNumCon").gameObject
	self.scoreNumCon_pngNum = PngNum.new(self.scoreNumCon)
	self.scoreNumConText = self.scoreCon:ComponentByName("scoreNumConText", typeof(UILabel))
	self.scoreTimeCon = self.scoreCon:ComponentByName("scoreTimeCon", typeof(UILayout))
	self.scorTimeText = self.scoreTimeCon:ComponentByName("scorTimeText", typeof(UILabel))
	self.scorEndText = self.scoreTimeCon:ComponentByName("scorEndText", typeof(UILabel))
	self.recordCon = self.groupAction:NodeByName("recordCon").gameObject
	self.scrollBg = self.recordCon:ComponentByName("scrollBg", typeof(UISprite))
	self.recordBtn = self.recordCon:NodeByName("recordBtn").gameObject
	self.showMoreRecordBtn = self.recordCon:ComponentByName("showMoreRecordBtn", typeof(UISprite))
	self.showMoreRecordBtn_BoxCollider = self.recordCon:ComponentByName("showMoreRecordBtn", typeof(UnityEngine.BoxCollider))
	self.scroll = self.recordCon:NodeByName("scroll").gameObject
	self.scroll_scrollview = self.recordCon:ComponentByName("scroll", typeof(UIScrollView))
	self.titleGroup_wrapContent = self.scroll:ComponentByName("titleGroup", typeof(UIWrapContent))
	self.drag = self.recordCon:NodeByName("drag").gameObject
	self.recordItem = self.recordCon:NodeByName("recordItem").gameObject
	self.scrollBg.height = big_size
	self.wrapContent = FixedWrapContent.new(self.scroll_scrollview, self.titleGroup_wrapContent, self.recordItem, GuildCompetitionRecordItem, self)

	self:waitForFrame(1, function ()
		self.scroll_scrollview:ResetPosition()
	end)

	self.scrollBg.height = small_size
	self.noRecordTipsText = self.recordCon:ComponentByName("noRecordTipsText", typeof(UILabel))
	self.recordNameText = self.recordCon:ComponentByName("recordNameText", typeof(UILabel))
	self.challengeTimesText = self.recordCon:ComponentByName("challengeTimesText", typeof(UILabel))
	self.taskBtn = self.recordCon:NodeByName("taskBtn").gameObject
	self.taskRedPoint = self.taskBtn:ComponentByName("taskRedPoint", typeof(UISprite)).gameObject

	self.taskRedPoint:SetActive(false)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.GUILD_COMPETITION_TASK_RED
	}, self.taskRedPoint)
	self.recordCon:Y(small_y)

	self.personGroupItem = self.groupAction:NodeByName("personGroupItem").gameObject
	self.btnCon = self.groupAction:NodeByName("btnCon").gameObject
	self.rankBtn = self.btnCon:NodeByName("rankBtn").gameObject
	self.awardBtn = self.btnCon:NodeByName("awardBtn").gameObject
	self.helpBtn = self.btnCon:NodeByName("helpBtn").gameObject
	self.effectIsland = self.groupAction:NodeByName("effectIsland").gameObject
	self.effectWater = self.groupAction:NodeByName("effectWater").gameObject
	self.effectLeaf = self.groupAction:NodeByName("effectLeaf").gameObject
	self.effectBird = self.groupAction:NodeByName("effectBird").gameObject
end

function GuildCompetitionMainWindow:initUIComponent()
	self.noRecordTipsText.text = __("TOWER_RECORD_TIP_1")
	self.recordNameText.text = __("BATTLE_RECORD")
	self.scoreNumConText.text = __("BOOK_RESEARCH_TEXT12")

	xyd.setUISpriteAsync(self.scoreConTextImg, nil, "guild_competition_rank_" .. xyd.Global.lang, nil, )
	self:initEffect()
	self:initRecordBtn()
	self:initTopGroup()
	self:registerEvent()
	self:updateBaseShow()
	self:updateGuildCompetitionTime()
	self:updateInfoAuto()
end

function GuildCompetitionMainWindow:playEnterEffect()
	local leftTop_y = 474 + 89 * self.scale_num_contrary

	self.scoreCon:Y(leftTop_y + 500)

	self.leftTop_Tween = self:getSequence()

	self.leftTop_Tween:Append(self.scoreCon.transform:DOLocalMoveY(leftTop_y, 0.5))
	self.leftTop_Tween:AppendCallback(function ()
		self.leftTop_Tween:Kill(true)
	end)

	local rightTop_y = 532 + 89 * self.scale_num_contrary

	self.btnCon:Y(leftTop_y + 500)

	self.btnCon_Tween = self:getSequence()

	self.btnCon_Tween:Append(self.btnCon.transform:DOLocalMoveY(rightTop_y, 0.5))
	self.btnCon_Tween:AppendCallback(function ()
		self.btnCon_Tween:Kill(true)
	end)

	self.showMoreRecordBtn_BoxCollider.enabled = false
	local leftDown_y = -441 + -82 * self.scale_num_contrary

	self.recordCon:Y(leftDown_y - 500)

	self.recordCon_Tween = self:getSequence()

	self.recordCon_Tween:Append(self.recordCon.transform:DOLocalMoveY(leftDown_y, 0.5))
	self.recordCon_Tween:AppendCallback(function ()
		self.showMoreRecordBtn_BoxCollider.enabled = true

		self.recordCon_Tween:Kill(true)
	end)
end

function GuildCompetitionMainWindow:initEffect()
	self.effectIsland_ = xyd.Spine.new(self.effectIsland)

	self.effectIsland_:setInfo("sky_island_float", function ()
		self.effectIsland_:play("texiao01", 0)
	end)

	self.effectLeaf_ = xyd.Spine.new(self.effectLeaf)

	self.effectLeaf_:setInfo("sky_island_leaf", function ()
		self.effectLeaf_:play("texiao01", 0)
	end)

	self.effectWater_ = xyd.Spine.new(self.effectWater)

	self.effectWater_:setInfo("sky_island_water", function ()
		self.effectWater_:play("texiao01", 0)
	end)

	self.effectBird_ = xyd.Spine.new(self.effectBird)

	self.effectBird_:setInfo("sky_island_bird", function ()
		self.effectBird_:play("texiao01", 0)
	end)
end

function GuildCompetitionMainWindow:updateInfoAuto()
	self:waitForTime(30, function ()
		local guildCompetitionRankWindow = xyd.WindowManager.get():getWindow("guild_competition_fight_window")
		local guildCompetitionBossRankWindow = xyd.WindowManager.get():getWindow("guild_competition_boss_rank_window")

		if not guildCompetitionRankWindow and not guildCompetitionBossRankWindow then
			xyd.models.guild:getGuildCompetitionServerData()
		end

		self:updateGetRecordList()
		self:updateInfoAuto()
	end)
end

function GuildCompetitionMainWindow:updateGuildCompetitionTime()
	if xyd.models.guild:getGuildCompetitionInfo() then
		local timeData = xyd.models.guild:getGuildCompetitionLeftTime()

		if timeData.type == 1 then
			self.scorTimeText.gameObject:SetActive(true)
			self.scorTimeText:SetActive(true)

			local params = {
				duration = timeData.curEndTime - xyd.getServerTime(),
				callback = handler(self, self.updateGuildCompetitionTime)
			}

			if self.guildCompetitionTimeCount then
				self.guildCompetitionTimeCount:stopTimeCount()
				self:waitForTime(1, function ()
					self.guildCompetitionTimeCount:setInfo(params)
				end)
			else
				local CountDown = import("app.components.CountDown")
				self.guildCompetitionTimeCount = CountDown.new(self.scorTimeText, params)
			end

			self.scorEndText.text = __("OPEN_AFTER")

			if xyd.Global.lang == "fr_fr" then
				self.scorEndText.gameObject.transform:SetSiblingIndex(0)
				self.scorTimeText.gameObject.transform:SetSiblingIndex(1)

				self.scorEndText.fontSize = 19
				self.scorTimeText.fontSize = 19
			end

			self.challengeTimesText.gameObject:SetActive(false)
		elseif timeData.type == 2 then
			self.scorTimeText.gameObject:SetActive(true)
			self.scorTimeText:SetActive(true)

			local params = {
				duration = timeData.curEndTime - xyd.getServerTime(),
				callback = handler(self, self.updateGuildCompetitionTime)
			}

			if self.guildCompetitionTimeCount then
				self.guildCompetitionTimeCount:stopTimeCount()
				self:waitForTime(1, function ()
					self.guildCompetitionTimeCount:setInfo(params)
				end)
			else
				local CountDown = import("app.components.CountDown")
				self.guildCompetitionTimeCount = CountDown.new(self.scorTimeText, params)
			end

			self.challengeTimesText.gameObject:SetActive(true)

			self.scorEndText.text = __("TEXT_END")
		else
			self.scorTimeText.gameObject:SetActive(false)

			self.scorEndText.text = __("GUILD_COMPETITION_END_TIME")
		end
	else
		self.scorTimeText.gameObject:SetActive(false)

		self.scorEndText.text = __("GUILD_COMPETITION_END_TIME")
	end

	self.scoreTimeCon:Reposition()
	self:initRecordBtn()
end

function GuildCompetitionMainWindow:registerEvent()
	UIEventListener.Get(self.rankBtn.gameObject).onClick = handler(self, function ()
		local msg = messages_pb:guild_competition_guild_rank_req()
		msg.activity_id = xyd.ActivityID.GUILD_COMPETITION

		xyd.Backend.get():request(xyd.mid.GUILD_COMPETITION_GUILD_RANK, msg)
	end)
	UIEventListener.Get(self.awardBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("guild_competition_boss_rank_window", {
			isAllGuildAward = true
		})
	end)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "GUILD_COMPETITION_HELP"
		})
	end)
	UIEventListener.Get(self.recordBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("guild_competition_record_window", {
			isAllGuildAward = true
		})
	end)
	UIEventListener.Get(self.taskBtn.gameObject).onClick = handler(self, function ()
		local timeInfo = xyd.models.guild:getGuildCompetitionLeftTime()

		if timeInfo.type == 1 then
			local duration = timeInfo.curEndTime - xyd.getServerTime()
			local hour = duration / 3600
			local secType = xyd.SecondsStrType.NORMAL

			if hour > 48 then
				secType = xyd.SecondsStrType.NOMINU
			else
				secType = xyd.SecondsStrType.NORMAL
			end

			xyd.alertTips(__("GUILD_COMPETITION_START_TIME", xyd.secondsToString(duration, secType)))

			return
		end

		xyd.WindowManager.get():openWindow("guild_competition_active_window", {})
	end)
	UIEventListener.Get(self.showMoreRecordBtn.gameObject).onClick = handler(self, self.showRecordBtnClick)

	self.eventProxy_:addEventListener(xyd.event.GUILD_COMPETITION_GUILD_RANK, handler(self, function (__, event)
		local data = xyd.decodeProtoBuf(event.data)

		xyd.WindowManager.get():openWindow("guild_competition_rank_window", {
			guildRankData = data
		})
	end))
	self.eventProxy_:addEventListener(xyd.event.GUILD_COMPETITION_LOG, handler(self, function (__, event)
		local data = xyd.decodeProtoBuf(event.data)

		self:updateShowRecord(data.list)
	end))
end

function GuildCompetitionMainWindow:initRecordBtn()
	self.recordBtn:SetActive(false)

	if xyd.models.guild:getGuildCompetitionInfo() then
		local timeData = xyd.models.guild:getGuildCompetitionLeftTime()

		if timeData.type == 2 and (xyd.models.guild.guildJob == xyd.GUILD_JOB.LEADER or xyd.models.guild.guildJob == xyd.GUILD_JOB.VICE_LEADER) then
			self.recordBtn:SetActive(true)
		end
	end
end

function GuildCompetitionMainWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function GuildCompetitionMainWindow:updateBaseShow(bossIndex)
	local overChallengeTimes = xyd.tables.miscTable:getNumber("guild_competition_personal_limit", "value") - tonumber(xyd.models.guild:getGuildCompetitionInfo().times)
	overChallengeTimes = xyd.checkCondition(overChallengeTimes < 0, 0, overChallengeTimes)
	self.challengeTimesText.text = __("GUILD_BOSS_TEXT01", overChallengeTimes)

	self:updateRank()
	self:updatePersonGroup(bossIndex)
	self:updateGetRecordList()
end

function GuildCompetitionMainWindow:updateRank()
	if xyd.models.guild:getGuildCompetitionInfo().guild_rank then
		self.scoreNumCon:SetActive(true)
		self.scoreNumConText:SetActive(false)
		self.scoreNumCon_pngNum:setInfo({
			isAbbr = false,
			iconName = "guild_competition",
			num = tonumber(xyd.models.guild:getGuildCompetitionInfo().guild_rank) + 1
		})
	else
		self.scoreNumCon:SetActive(false)
		self.scoreNumConText:SetActive(true)
	end
end

function GuildCompetitionMainWindow:updateGetRecordList()
	local msg = messages_pb:guild_competition_log_req()
	msg.activity_id = xyd.ActivityID.GUILD_COMPETITION
	msg.num = 30

	xyd.Backend.get():request(xyd.mid.GUILD_COMPETITION_LOG, msg)
end

function GuildCompetitionMainWindow:updateShowRecord(list)
	list = list or {}
	self.list = list

	if list and #list > 0 then
		self.scroll:SetActive(true)

		if not self.firstInit then
			self.wrapContent:setInfos(list)

			self.firstInit = true

			self.scroll_scrollview:ResetPosition()
		else
			self.wrapContent:setInfos(list, {
				keepPosition = true
			})
		end

		self.scroll_scrollview.enabled = false

		self.noRecordTipsText:SetActive(false)
	else
		self.scroll:SetActive(false)
		self.noRecordTipsText:SetActive(true)
	end

	if not self.showRecordIsSmall then
		self.scroll_scrollview.enabled = true
	end
end

function GuildCompetitionMainWindow:showRecordBtnClick()
	if self.isShowRecordMoving == true then
		return
	end

	self.isShowRecordMoving = true
	self.sequence = self:getSequence()

	if not self.showRecordIsSmall and self.list and #self.list > 0 then
		self.wrapContent:resetPosition()

		self.scroll_scrollview.enabled = false
	end

	local function showRecordSizeChange(num)
		if self.showRecordIsSmall then
			self.scrollBg.height = small_size + (big_size - small_size) * num

			self.recordCon:Y(small_y + (big_y - small_y) * num)
		else
			self.scrollBg.height = big_size - (big_size - small_size) * num

			self.recordCon:Y(big_y - (big_y - small_y) * num)
		end
	end

	self.sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(showRecordSizeChange), 0, 1, 0.2))
	self.sequence:AppendCallback(function ()
		self.sequence:Kill(true)

		if self.showRecordIsSmall then
			if self.list and #self.list then
				self.scroll_scrollview.enabled = true
			end

			xyd.setUISpriteAsync(self.showMoreRecordBtn, nil, "guild_competition_down", nil, )
		else
			xyd.setUISpriteAsync(self.showMoreRecordBtn, nil, "guild_competition_up", nil, )
		end

		self.showRecordIsSmall = not self.showRecordIsSmall
		self.isShowRecordMoving = false
	end)
end

function GuildCompetitionMainWindow:updatePersonGroup(index)
	if not self.personItemArr then
		self.personItemArr = {}
		local partnerArr = xyd.tables.miscTable:split2num("guild_competition_boss_model", "value", "|")

		for i in pairs(partnerArr) do
			local bossInfo = {
				partnerId = partnerArr[i],
				modelId = xyd.tables.partnerTable:getModelID(partnerArr[i]),
				index = i
			}
			local tmp = NGUITools.AddChild(self.groupAction.gameObject, self.personGroupItem.gameObject)
			local item = PersonItem.new(tmp, bossInfo)

			table.insert(self.personItemArr, item)
		end
	elseif index then
		self.personItemArr[index]:updateShow()
	else
		for i in pairs(self.personItemArr) do
			self.personItemArr[i]:updateShow()
		end
	end
end

function GuildCompetitionMainWindow:willClose()
	if self.guildCompetitionTimeCount then
		self.guildCompetitionTimeCount:stopTimeCount()
	end

	GuildCompetitionMainWindow.super.willClose(self)
end

return GuildCompetitionMainWindow
