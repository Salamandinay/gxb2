local ActivityYearSummaryWindow = class("ActivityYearSummaryWindow", import(".BaseWindow"))
local copyComponent = import("app.components.CopyComponent")
local ActivityYearSummaryPage1 = class("ActivityYearSummaryPage1", copyComponent)
local ActivityYearSummaryPage2 = class("ActivityYearSummaryPage2", copyComponent)
local ActivityYearSummaryPage3 = class("ActivityYearSummaryPage3", copyComponent)
local ActivityYearSummaryPage4 = class("ActivityYearSummaryPage4", copyComponent)
local ActivityYearSummaryPage5 = class("ActivityYearSummaryPage5", copyComponent)
local ActivityYearSummaryPage6 = class("ActivityYearSummaryPage6", copyComponent)
local ActivityYearSummaryPage7 = class("ActivityYearSummaryPage7", copyComponent)
local ActivityYearSummaryPage8 = class("ActivityYearSummaryPage8", copyComponent)
local PlayerIcon = import("app.components.PlayerIcon")
local pageClassList = {
	ActivityYearSummaryPage1,
	ActivityYearSummaryPage2,
	ActivityYearSummaryPage3,
	ActivityYearSummaryPage4,
	ActivityYearSummaryPage5,
	ActivityYearSummaryPage8,
	ActivityYearSummaryPage6,
	ActivityYearSummaryPage7
}
local pageIndexs = {
	1,
	2,
	3,
	4,
	5,
	8,
	6,
	7
}

function ActivityYearSummaryWindow:ctor(name, params)
	ActivityYearSummaryWindow.super.ctor(self, name, params)

	self.detail = xyd.models.activity:getActivity(xyd.ActivityID.YEARS_SUMMARY).detail
	self.pageNum_ = 1
end

function ActivityYearSummaryWindow:initWindow()
	ActivityYearSummaryWindow.super.initWindow(self)
	self:getComponent()
	self:layout()
	self:register()
end

function ActivityYearSummaryWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject

	for i = 1, #pageIndexs do
		self["pageRoot" .. i] = winTrans:NodeByName("page" .. i).gameObject

		self["pageRoot" .. i]:SetActive(false)
	end

	self.boxGroup = winTrans:NodeByName("nextClickBox").gameObject
	self.boxClider = winTrans:NodeByName("nextClickBox/clickBox").gameObject
	self.tipsLabel = winTrans:ComponentByName("nextClickBox/tipsLabel", typeof(UILabel))

	self.boxGroup:SetActive(true)
	self.tipsLabel.gameObject:SetActive(false)
end

function ActivityYearSummaryWindow:layout()
	self.tipsLabel.text = __("ANNUAL4_REVIEW_SKIP")

	self.pageRoot1:SetActive(true)

	self.page1 = pageClassList[1].new(self.pageRoot1, self)

	self.page1:layout()
	self.page1:openAnimation()
end

function ActivityYearSummaryWindow:register()
	UIEventListener.Get(self.boxClider).onClick = handler(self, self.toNextPage)
end

function ActivityYearSummaryWindow:toNextPage(toNext)
	if self.pageNum_ == #pageIndexs and not self.isInAni then
		self:onClickCloseButton()

		return
	elseif self.pageNum_ == #pageIndexs and self.isInAni then
		if self.page7 then
			self.page7:showFinalText()
		end

		return
	elseif self.isInAni then
		return
	end

	if self.isOpenAni and self["page" .. pageIndexs[self.pageNum_]]:canJumpAni() then
		self["page" .. pageIndexs[self.pageNum_]]:finishAni()

		self.isOpenAni = false

		return
	elseif self.isOpenAni then
		return
	end

	if pageIndexs[self.pageNum_] == 1 and (not tonumber(toNext) or tonumber(toNext) ~= 1) then
		xyd.WindowManager.get():closeWindow("activity_year_summary_window")

		return
	end

	self.tipsLabel.gameObject:SetActive(true)

	local nextPageIndex = self.pageNum_ + 1

	if pageIndexs[nextPageIndex] == 5 and tonumber(self.detail.tower_stage) == 0 and tonumber(self.detail.pr_challenge_win_count) == 0 and tonumber(self.detail.dungeon_stage) == 0 then
		nextPageIndex = self.pageNum_ + 2
	end

	if pageIndexs[nextPageIndex] == 8 and tonumber(self.detail.trial_1_dmg) == 0 and tonumber(self.detail.trial_2_dmg) == 0 and tonumber(self.detail.cloister_score) == 0 and tonumber(self.detail.shrine_score) == 0 then
		nextPageIndex = self.pageNum_ + 2
	end

	local nextPage = pageIndexs[nextPageIndex]

	if not self["page" .. nextPage] then
		self["pageRoot" .. nextPage]:SetActive(true)

		self["page" .. nextPage] = pageClassList[nextPageIndex].new(self["pageRoot" .. nextPage], self)

		self["page" .. nextPage]:layout()
	end

	self["page" .. pageIndexs[self.pageNum_]]:playMoveAni(function ()
		self["page" .. nextPage]:openAnimation()
	end)

	if self.pageNum_ <= #pageIndexs - 1 then
		self.pageNum_ = nextPageIndex
	end
end

function ActivityYearSummaryWindow:willClose()
	for i = 1, #pageIndexs do
		if self["page" .. i] then
			self["page" .. i]:dispose()
		end
	end

	ActivityYearSummaryWindow.super.willClose(self)
end

function ActivityYearSummaryPage1:ctor(gameObject, parent)
	self.parent_ = parent

	ActivityYearSummaryPage1.super.ctor(self, gameObject)
end

function ActivityYearSummaryPage1:initUI()
	local goTrans = self.go.transform
	self.animRoot1 = goTrans:ComponentByName("animRoot1", typeof(UIWidget))
	self.playerIconRoot = goTrans:NodeByName("animRoot1/playerIconRoot").gameObject
	self.playerIconWidgt = self.playerIconRoot:GetComponent(typeof(UIWidget))
	self.playerName = goTrans:ComponentByName("animRoot1/playerIconRoot/playerName", typeof(UILabel))
	self.title1 = goTrans:ComponentByName("title1", typeof(UILabel))
	self.title2 = goTrans:ComponentByName("animRoot1/title2", typeof(UILabel))
	self.animRoot2 = goTrans:ComponentByName("animRoot2", typeof(UIWidget))
	self.title3 = goTrans:ComponentByName("animRoot2/title3", typeof(UILabel))
	self.logoRoot = goTrans:NodeByName("logoRoot").gameObject
	self.logoRootWidgt = self.logoRoot:GetComponent(typeof(UIWidget))
	self.btnNext = goTrans:NodeByName("btnNext").gameObject
	self.btnNextWidgt = self.btnNext:GetComponent(typeof(UIWidget))
	self.btnNextLabel = goTrans:ComponentByName("btnNext/label", typeof(UILabel))
	self.labelTips = goTrans:ComponentByName("labelTips", typeof(UILabel))
	self.bg = goTrans:ComponentByName("bg", typeof(UIWidget))
end

function ActivityYearSummaryPage1:layout()
	self.title1.text = __("ANNUAL4_REVIEW_1_1")
	self.title2.text = __("ANNUAL4_REVIEW_1_2")
	self.title3.text = __("ANNUAL4_REVIEW_1_3")
	self.btnNextLabel.text = __("ANNUAL4_REVIEW_1_4")
	self.labelTips.text = __("ANNUAL4_REVIEW_1_5")

	if not self.logoEffect then
		self.logoEffect = xyd.Spine.new(self.logoRoot)

		self.logoEffect:setInfo("loading1_zi", function ()
			self.logoEffect:SetLocalScale(0.65, 0.65, 0)

			if xyd.Global.lang == "ko_kr" or xyd.Global.lang == "ja_jp" then
				self.logoEffect:SetLocalPosition(-310, -200, 0)
			else
				self.logoEffect:SetLocalPosition(-340, -200, 0)
			end

			local aniName = "title_" .. xyd.Global.lang

			self.logoEffect:playAtTime(aniName, 1, 2.4)
		end)
	end

	self.playerName.text = xyd.Global.playerName
	self.playerIcon = PlayerIcon.new(self.playerIconRoot)

	self.playerIcon:setInfo({
		noClick = true,
		avatarID = xyd.models.selfPlayer:getAvatarID(),
		lev = xyd.models.backpack:getLev(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID()
	})

	UIEventListener.Get(self.btnNext).onClick = function ()
		self.parent_:toNextPage(1)
	end
end

function ActivityYearSummaryPage1:canJumpAni()
	return true
end

function ActivityYearSummaryPage1:openAnimation()
	self.parent_.isOpenAni = true
	self.seq_ = self:getSequence(function ()
		self.parent_.isOpenAni = false
	end)

	local function setter2(value)
		self.bg.alpha = value
	end

	local function setter4(value)
		self.title1.alpha = value
	end

	local function setter5(value)
		self.playerIconWidgt.alpha = value
	end

	local function setter6(value)
		self.title2.alpha = value
	end

	local function setter7(value)
		self.logoRootWidgt.alpha = value
	end

	local function setter8(value)
		self.animRoot2.alpha = value
	end

	local function setter9(value)
		self.btnNextWidgt.alpha = value
	end

	local function setter10(value)
		self.labelTips.alpha = value
	end

	self.seq_:Insert(0.06666666666666667, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.2))
	self.seq_:Insert(0.06666666666666667, self.bg.transform:DOLocalMove(Vector3(0, 0, 0), 0.26666666666666666))
	self.seq_:Insert(0.3333333333333333, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter4), 0, 1, 0.13333333333333333))
	self.seq_:Insert(0.36666666666666664, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter5), 0, 1, 0.16666666666666666))
	self.seq_:Insert(0.36666666666666664, self.playerIconWidgt.transform:DOScale(Vector3(1.1, 1.1, 1.1), 0.16666666666666666))
	self.seq_:Insert(0.5333333333333333, self.playerIconWidgt.transform:DOScale(Vector3(0.98, 0.98, 1), 0.16666666666666666))
	self.seq_:Insert(0.7, self.playerIconWidgt.transform:DOScale(Vector3(1, 1, 1), 0.23333333333333334))
	self.seq_:Insert(0.43333333333333335, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter6), 0, 1, 0.16666666666666666))
	self.seq_:Insert(0.43333333333333335, self.title2.transform:DOScale(Vector3(1.1, 1.1, 1.1), 0.16666666666666666))
	self.seq_:Insert(0.6, self.title2.transform:DOScale(Vector3(0.98, 0.98, 1), 0.16666666666666666))
	self.seq_:Insert(0.7666666666666667, self.title2.transform:DOScale(Vector3(1, 1, 1), 0.23333333333333334))
	self.seq_:Insert(0.5, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter7), 0, 1, 0.16666666666666666))
	self.seq_:Insert(0.5, self.logoRootWidgt.transform:DOScale(Vector3(1.1, 1.1, 1.1), 0.16666666666666666))
	self.seq_:Insert(0.6666666666666666, self.logoRootWidgt.transform:DOScale(Vector3(0.98, 0.98, 1), 0.16666666666666666))
	self.seq_:Insert(0.8333333333333334, self.logoRootWidgt.transform:DOScale(Vector3(1, 1, 1), 0.23333333333333334))
	self.seq_:Insert(1.1, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter8), 0, 1, 0.2))
	self.seq_:Insert(1.1, self.title3.transform:DOLocalMove(Vector3(0, -28, 0), 0.26666666666666666))
	self.seq_:Insert(1.6666666666666667, self.btnNext.transform:DOScale(Vector3(1.05, 1.05, 1.05), 0.23333333333333334))
	self.seq_:Insert(1.9, self.btnNext.transform:DOScale(Vector3(1, 1, 1), 0.16666666666666666))
	self.seq_:Insert(1.6666666666666667, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter9), 0, 1, 0.23333333333333334))
	self.seq_:Insert(1.8, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter10), 0, 1, 0.36666666666666664))
end

function ActivityYearSummaryPage1:finishAni()
	self.seq_:Pause()
	self.seq_:Kill(false)

	self.bg.alpha = 1
	self.title1.alpha = 1
	self.playerIconWidgt.alpha = 1
	self.title2.alpha = 1
	self.logoRootWidgt.alpha = 1
	self.animRoot2.alpha = 1
	self.btnNextWidgt.alpha = 1
	self.labelTips.alpha = 1
	self.bg.transform.localPosition = Vector3(0, 0, 0)
	self.playerIconWidgt.transform.localScale = Vector3(1, 1, 1)
	self.title2.transform.localScale = Vector3(1, 1, 1)
	self.logoRoot.transform.localScale = Vector3(1, 1, 1)
	self.title3.transform.localPosition = Vector3(0, -28, 0)
	self.btnNext.transform.localScale = Vector3(1, 1, 1)
	self.parent_.isOpenAni = false
end

function ActivityYearSummaryPage1:playMoveAni(callback)
	self.parent_.isInAni = true
	local goTrans = self.go.transform
	local seq = self:getSequence()

	seq:Insert(0, goTrans:DOLocalMove(Vector3(-1000, -1000, 0), 0.6))
	seq:Insert(0, goTrans:DOLocalRotate(Vector3(0, 0, -60), 0.6))
	seq:InsertCallback(0.4, function ()
		self.parent_.isInAni = false

		if callback then
			callback()
		end
	end)
end

function ActivityYearSummaryPage2:ctor(gameObject, parent)
	self.parent_ = parent

	ActivityYearSummaryPage2.super.ctor(self, gameObject)
end

function ActivityYearSummaryPage2:initUI()
	local goTrans = self.go.transform
	self.animRoot1 = goTrans:ComponentByName("animRoot1", typeof(UIWidget))
	self.playerIconRoot = goTrans:NodeByName("animRoot1/playerIconRoot").gameObject
	self.playerName = goTrans:ComponentByName("animRoot1/playerName", typeof(UILabel))
	self.title1 = goTrans:ComponentByName("label1", typeof(UILabel))
	self.title2 = goTrans:ComponentByName("label2", typeof(UILabel))
	self.title2.alpha = 0
	self.animRoot1.alpha = 0
	self.title1.alpha = 0
end

function ActivityYearSummaryPage2:layout()
	local ctrTime = self.parent_.detail.created_time
	self.title1.text = __("ANNUAL4_REVIEW_2_1", xyd.getDisplayTime2(ctrTime, xyd.TimestampStrType.DATE))
	self.title2.text = __("ANNUAL4_REVIEW_2_2", self.parent_.detail.star_5_num)
	local group7PartnerNum = 0
	local collection = xyd.models.slot:getCollection()

	for k, v in pairs(collection) do
		if v and xyd.tables.partnerTable:getGroup(k) == 7 then
			group7PartnerNum = group7PartnerNum + 1
		end
	end

	if group7PartnerNum ~= 0 then
		self.title2.text = self.title2.text .. "\n" .. __("ANNUAL4_REVIEW_2_3", group7PartnerNum)
	end

	self.playerName.text = xyd.Global.playerName
	self.playerIcon = PlayerIcon.new(self.playerIconRoot)

	self.playerIcon:setInfo({
		noClick = true,
		avatarID = xyd.models.selfPlayer:getAvatarID(),
		lev = xyd.models.backpack:getLev(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID()
	})
end

function ActivityYearSummaryPage2:playMoveAni(callback)
	self.parent_.isInAni = true
	local goTrans = self.go.transform
	local seq = self:getSequence()

	seq:Insert(0, goTrans:DOLocalMove(Vector3(-1000, -1000, 0), 0.6))
	seq:Insert(0, goTrans:DOLocalRotate(Vector3(0, 0, -60), 0.6))
	seq:InsertCallback(0.4, function ()
		self.parent_.isInAni = false

		if callback then
			callback()
		end
	end)
end

function ActivityYearSummaryPage2:canJumpAni()
	return true
end

function ActivityYearSummaryPage2:finishAni()
	self.parent_.isInAni = false
	self.title2.alpha = 1
	self.animRoot1.alpha = 1
	self.title1.alpha = 1

	self.seq_:Pause()
	self.seq_:Kill(false)
end

function ActivityYearSummaryPage2:openAnimation()
	self.parent_.isOpenAni = true
	self.seq_ = self:getSequence(function ()
		self.parent_.isOpenAni = false
	end)

	local function setter1(value)
		self.animRoot1.alpha = value
		self.title1.alpha = value
	end

	local function setter2(value)
		self.title2.alpha = value
	end

	self.seq_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.26666666666666666))
	self.seq_:Insert(0.43333333333333335, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.26666666666666666))
end

function ActivityYearSummaryPage3:ctor(gameObject, parent)
	self.parent_ = parent

	ActivityYearSummaryPage3.super.ctor(self, gameObject)
end

function ActivityYearSummaryPage3:initUI()
	local goTrans = self.go.transform
	self.title1 = goTrans:ComponentByName("label1", typeof(UILabel))
	self.title2 = goTrans:ComponentByName("label2", typeof(UILabel))
	self.guildIcon = goTrans:ComponentByName("guildIcon", typeof(UISprite))
	self.title2.alpha = 0
	self.guildIcon.alpha = 0
	self.title1.alpha = 0
end

function ActivityYearSummaryPage3:layout()
	local friendNum = self.parent_.detail.friend_num
	local guildFriendNum = self.parent_.detail.guild_members_num
	local baseGuildInfo = xyd.models.guild:getBaseInfo()

	if not xyd.models.guild.guildID or tonumber(xyd.models.guild.guildID) <= 0 then
		self.guildIcon.gameObject:SetActive(false)
		self.title2.transform:Y(self.title2.transform.localPosition.y + 48)

		self.title2.text = __("ANNUAL4_REVIEW_3_6")
	elseif tonumber(guildFriendNum) == 1 then
		local flagName = xyd.tables.guildIconTable:getIcon(baseGuildInfo.flag)

		xyd.setUISpriteAsync(self.guildIcon, nil, flagName)

		self.title2.text = __("ANNUAL4_REVIEW_3_5", baseGuildInfo.name, __("GUILD_JOB" .. tostring(xyd.models.guild.guildJob)))
	else
		local flagName = xyd.tables.guildIconTable:getIcon(baseGuildInfo.flag)

		xyd.setUISpriteAsync(self.guildIcon, nil, flagName)

		self.title2.text = __("ANNUAL4_REVIEW_3_4", baseGuildInfo.name, __("GUILD_JOB" .. tostring(xyd.models.guild.guildJob)), guildFriendNum)
	end

	if not friendNum or tonumber(friendNum) == 0 then
		self.title1.text = __("ANNUAL4_REVIEW_3_3")
	elseif tonumber(friendNum) <= 3 then
		self.title1.text = __("ANNUAL4_REVIEW_3_1", friendNum)
	else
		self.title1.text = __("ANNUAL4_REVIEW_3_2", friendNum)
	end

	if xyd.Global.lang == "fr_fr" then
		self.title2.spacingY = 8
	end
end

function ActivityYearSummaryPage3:playMoveAni(callback)
	self.parent_.isInAni = true
	local goTrans = self.go.transform
	local seq = self:getSequence()

	seq:Insert(0, goTrans:DOLocalMove(Vector3(-1000, -1000, 0), 0.6))
	seq:Insert(0, goTrans:DOLocalRotate(Vector3(0, 0, -60), 0.6))
	seq:InsertCallback(0.4, function ()
		self.parent_.isInAni = false

		if callback then
			callback()
		end
	end)
end

function ActivityYearSummaryPage3:canJumpAni()
	return true
end

function ActivityYearSummaryPage3:finishAni()
	self.parent_.isInAni = false
	self.title2.alpha = 1
	self.guildIcon.alpha = 1
	self.title1.alpha = 1

	self.seq_:Pause()
	self.seq_:Kill(false)
end

function ActivityYearSummaryPage3:openAnimation()
	self.parent_.isOpenAni = true
	self.seq_ = self:getSequence(function ()
		self.parent_.isOpenAni = false
	end)

	local function setter1(value)
		self.title1.alpha = value
	end

	local function setter2(value)
		self.guildIcon.alpha = value
		self.title2.alpha = value
	end

	self.seq_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.26666666666666666))
	self.seq_:Insert(0.43333333333333335, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.26666666666666666))
end

function ActivityYearSummaryPage4:ctor(gameObject, parent)
	self.parent_ = parent

	ActivityYearSummaryPage4.super.ctor(self, gameObject)
end

function ActivityYearSummaryPage4:initUI()
	local goTrans = self.go.transform
	self.title1 = goTrans:ComponentByName("label1", typeof(UILabel))
	self.title2 = goTrans:ComponentByName("label2", typeof(UILabel))
	self.img1 = goTrans:ComponentByName("e:image1", typeof(UIWidget))
	self.img3 = goTrans:ComponentByName("e:image", typeof(UIWidget))
	self.img1.alpha = 0
	self.title1.alpha = 0
	self.title2.alpha = 0
end

function ActivityYearSummaryPage4:layout()
	local wed_count = tonumber(self.parent_.detail.wed_count)
	local can_wed_count = tonumber(self.parent_.detail.can_wed_count)
	local totalNum = xyd.tables.partnerTable:get5PartnerNum()
	local totalNum10 = xyd.tables.partnerTable:get10PartnerNum()
	local percent = math.floor(1000 * tonumber(self.parent_.detail.gallery_5) / totalNum) / 10

	if percent < 30 then
		self.title1.text = __("ANNUAL4_REVIEW_4_1", self.parent_.detail.gallery_5, percent .. "%") .. "\\n" .. __("ANNUAL4_REVIEW_4_2")
	elseif percent > 90 then
		self.title1.text = __("ANNUAL4_REVIEW_4_1", self.parent_.detail.gallery_5, percent .. "%") .. "\\n" .. __("ANNUAL4_REVIEW_4_3")
	else
		self.title1.text = __("ANNUAL4_REVIEW_4_1", self.parent_.detail.gallery_5, percent .. "%")
	end

	if self.parent_.detail.gallery_10 and tonumber(self.parent_.detail.gallery_10) > 0 then
		self.title1.text = self.title1.text .. "\\n" .. __("ANNUAL4_REVIEW_4_4", self.parent_.detail.gallery_10, math.floor(1000 * tonumber(self.parent_.detail.gallery_10) / 10 / totalNum10) .. "%")
	end

	if wed_count == 0 and can_wed_count == 0 then
		self.title2.text = __("ANNUAL4_REVIEW_4_8")
	elseif wed_count == 0 then
		if can_wed_count == 1 then
			self.title2.text = __("ANNUAL4_REVIEW_4_7_1", can_wed_count)
		else
			self.title2.text = __("ANNUAL4_REVIEW_4_7", can_wed_count)
		end
	else
		self.title2.text = __("ANNUAL4_REVIEW_4_5", wed_count)

		if can_wed_count > 0 then
			if can_wed_count == 1 then
				self.title2.text = self.title2.text .. "\\n" .. __("ANNUAL4_REVIEW_4_6_1", can_wed_count)
			else
				self.title2.text = self.title2.text .. "\\n" .. __("ANNUAL4_REVIEW_4_6", can_wed_count)
			end
		end
	end

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		self.title2.transform:Y(-170)

		self.title1.spacingY = 2
		self.title2.spacingY = 6

		self.img1.transform:Y(-110)
		self.img3.transform:Y(-45)
	elseif xyd.Global.lang == "en_en" then
		self.img3.transform:Y(-25)
		self.img1.transform:Y(-90)
		self.title2.transform:Y(-150)
	end
end

function ActivityYearSummaryPage4:playMoveAni(callback)
	self.parent_.isInAni = true
	local goTrans = self.go.transform
	local seq = self:getSequence()

	seq:Insert(0, goTrans:DOLocalMove(Vector3(-1000, -1000, 0), 0.6))
	seq:Insert(0, goTrans:DOLocalRotate(Vector3(0, 0, -60), 0.6))
	seq:InsertCallback(0.4, function ()
		self.parent_.isInAni = false

		if callback then
			callback()
		end
	end)
end

function ActivityYearSummaryPage4:canJumpAni()
	return true
end

function ActivityYearSummaryPage4:finishAni()
	self.parent_.isOpenAni = false
	self.img1.alpha = 1
	self.title1.alpha = 1
	self.title2.alpha = 1

	self.seq_:Pause()
	self.seq_:Kill(false)
end

function ActivityYearSummaryPage4:openAnimation()
	self.parent_.isOpenAni = true
	self.seq_ = self:getSequence(function ()
		self.parent_.isOpenAni = false
	end)

	local function setter1(value)
		self.title1.alpha = value
	end

	local function setter3(value)
		self.img1.alpha = value
	end

	local function setter2(value)
		self.title2.alpha = value
	end

	self.seq_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.26666666666666666))
	self.seq_:Insert(0.43333333333333335, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 0.26666666666666666))
	self.seq_:Insert(0.5333333333333333, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.26666666666666666))
end

function ActivityYearSummaryPage5:ctor(gameObject, parent)
	self.parent_ = parent
	self.itemsNum = 3

	ActivityYearSummaryPage5.super.ctor(self, gameObject)
end

function ActivityYearSummaryPage5:initUI()
	local goTrans = self.go.transform
	self.title1 = goTrans:ComponentByName("label1", typeof(UILabel))
	self.title2 = goTrans:ComponentByName("label2", typeof(UILabel))
	self.title3 = goTrans:ComponentByName("label3", typeof(UILabel))
	self.layoutWidgt = goTrans:ComponentByName("layout", typeof(UIWidget))
	self.part1_ = goTrans:NodeByName("layout/part1").gameObject
	self.part2_ = goTrans:NodeByName("layout/part2").gameObject
	self.part3_ = goTrans:NodeByName("layout/part3").gameObject
	self.title1_2 = goTrans:ComponentByName("layout/part1/label1-2", typeof(UILabel))
	self.title2_2 = goTrans:ComponentByName("layout/part2/label2-2", typeof(UILabel))
	self.title3_2 = goTrans:ComponentByName("layout/part3/label3-2", typeof(UILabel))
	self.title1_1 = goTrans:ComponentByName("layout/part1/label1-1", typeof(UILabel))
	self.title2_1 = goTrans:ComponentByName("layout/part2/label2-1", typeof(UILabel))
	self.title3_1 = goTrans:ComponentByName("layout/part3/label3-1", typeof(UILabel))
	self.layoutWidgt.alpha = 0
	self.title1.alpha = 0
	self.title2.alpha = 0
	self.title3.alpha = 0
end

function ActivityYearSummaryPage5:layout()
	self.title1.text = __("ANNUAL4_REVIEW_5_1")
	self.title2.text = self.parent_.detail.total_power
	self.title3.text = __("ANNUAL4_REVIEW_5_2")
	self.title1_1.text = __("ANNUAL4_REVIEW_5_3", self.parent_.detail.tower_stage)

	if tonumber(self.parent_.detail.tower_percent) > 0.5 then
		self.title1_2.text = __("ANNUAL4_REVIEW_5_6", self.parent_.detail.tower_percent * 100 .. "%")
	else
		self.title1_1.transform:Y(self.title1_1.transform.localPosition.y - 20)
	end

	if tonumber(self.parent_.detail.dungeon_percent) > 0.5 then
		self.title2_2.text = __("ANNUAL4_REVIEW_5_6", self.parent_.detail.dungeon_percent * 100 .. "%")
	else
		self.title2_1.transform:Y(self.title2_1.transform.localPosition.y - 20)
	end

	self.title2_1.text = __("ANNUAL4_REVIEW_5_4", self.parent_.detail.dungeon_stage)
	self.title3_1.text = __("ANNUAL4_REVIEW_5_5", self.parent_.detail.pr_challenge_win_count)
	self.title3_2.text = __("ANNUAL4_REVIEW_5_7", self.parent_.detail.pr_challenge_win_count, xyd.getPrChallengeNum())

	if tonumber(self.parent_.detail.pr_challenge_win_count) == 0 then
		self.part3_:SetActive(false)

		self.itemsNum = self.itemsNum - 1

		if tonumber(self.parent_.detail.dungeon_stage) == 0 then
			self.part2_:SetActive(false)

			self.itemsNum = self.itemsNum - 1
		end
	end

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "en_en" then
		self.title1.transform:Y(300)
	end

	if xyd.Global.lang == "de_de" then
		self.title1_1.spacingY = 0
		self.title2_1.spacingY = 0
		self.title3_1.spacingY = 0
		self.title1_1.fontSize = 15
		self.title2_1.fontSize = 15
		self.title3_1.fontSize = 15
	end

	if xyd.Global.lang == "fr_fr" then
		self.title1_1.spacingY = 6
		self.title2_1.spacingY = 6
		self.title3_1.spacingY = 6
		self.title1_1.fontSize = 15
		self.title2_1.fontSize = 15
		self.title3_1.fontSize = 15
	end

	self:updateItemsPos()
end

function ActivityYearSummaryPage5:updateItemsPos()
	if self.itemsNum == 2 then
		self.part1_:NodeByName("bg"):SetActive(false)
		self.part2_:NodeByName("bg"):SetActive(false)
		self.part1_:NodeByName("bg2"):SetActive(true)
		self.part2_:NodeByName("bg2"):SetActive(true)
		self.part1_.transform:Y(200)
		self.part2_.transform:Y(-45)
	elseif self.itemsNum == 1 then
		self.part1_:NodeByName("bg"):SetActive(false)
		self.part1_:NodeByName("bg1"):SetActive(true)
		self.part1_.transform:Y(150)
	end
end

function ActivityYearSummaryPage5:playMoveAni(callback)
	self.parent_.isInAni = true
	local goTrans = self.go.transform
	local seq = self:getSequence()

	seq:Insert(0, goTrans:DOLocalMove(Vector3(-1000, -1000, 0), 0.6))
	seq:Insert(0, goTrans:DOLocalRotate(Vector3(0, 0, -60), 0.6))
	seq:InsertCallback(0.4, function ()
		self.parent_.isInAni = false

		if callback then
			callback()
		end
	end)
end

function ActivityYearSummaryPage5:canJumpAni()
	return true
end

function ActivityYearSummaryPage5:finishAni()
	self.parent_.isOpenAni = false
	self.layoutWidgt.alpha = 1
	self.title1.alpha = 1
	self.title2.alpha = 1
	self.title3.alpha = 1

	self.seq_:Pause()
	self.seq_:Kill(false)
end

function ActivityYearSummaryPage5:openAnimation()
	self.parent_.isOpenAni = true
	self.seq_ = self:getSequence(function ()
		self.parent_.isOpenAni = false
	end)

	local function setter1(value)
		self.title1.alpha = value
		self.title2.alpha = value
	end

	local function setter3(value)
		self.layoutWidgt.alpha = value
	end

	local function setter2(value)
		self.title3.alpha = value
	end

	self.seq_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.26666666666666666))
	self.seq_:Insert(0.4, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.26666666666666666))
	self.seq_:Insert(0.7333333333333333, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 0.2))
end

function ActivityYearSummaryPage6:ctor(gameObject, parent)
	self.parent_ = parent

	ActivityYearSummaryPage6.super.ctor(self, gameObject)
end

function ActivityYearSummaryPage6:initUI()
	local goTrans = self.go.transform
	self.title1 = goTrans:ComponentByName("label1", typeof(UILabel))
	self.title2 = goTrans:ComponentByName("label2", typeof(UILabel))
	self.title3 = goTrans:ComponentByName("label3", typeof(UILabel))
	self.title3_1 = goTrans:ComponentByName("label3-1", typeof(UILabel))
	self.title2_1 = goTrans:ComponentByName("label2-1", typeof(UILabel))
	self.attrNode = goTrans:NodeByName("attrNode/node").gameObject
	self.heroNode = goTrans:NodeByName("heroNode/node").gameObject
	self.title1.alpha = 0
	self.title2.alpha = 0
	self.title2_1.alpha = 0
	self.title3.alpha = 0
	self.title3_1.alpha = 0
end

function ActivityYearSummaryPage6:layout()
	self.title1.text = __("ANNUAL4_REVIEW_6_1", self.parent_.detail.collect_point) .. "\\n" .. __("ANNUAL4_REVIEW_6_2")
	self.title2.text = __("ANNUAL4_REVIEW_6_3", self.parent_.detail.dress_score)
	self.title2_1.text = " "
	self.title3.text = __("ANNUAL4_REVIEW_6_4", self.parent_.detail.skin_num)
	self.title3_1.text = " "

	self:initDress()
end

function ActivityYearSummaryPage6:initDress()
	local iconClass = require("app.components.ThreeAttrComponent")
	self.attr_map = iconClass.new(self.attrNode)
	local params = {
		max_value = xyd.models.dress:getThreeMaxValue(),
		value_arr = xyd.models.dress:getAttrs(),
		text_arr = {
			__("PERSON_DRESS_ATTR_1"),
			__("PERSON_DRESS_ATTR_2"),
			__("PERSON_DRESS_ATTR_3")
		}
	}

	self.attr_map:setInfo(params)
	self.attr_map:SetLocalPosition(0, 0, 0)

	self.normalModel_ = import("app.components.SenpaiModel").new(self.heroNode)

	self.normalModel_:setModelInfo({
		isNewClipShader = true,
		ids = xyd.models.dress:getEffectEquipedStyles()
	})

	if not xyd.checkFunctionOpen(xyd.FunctionID.DRESS, true) then
		self.attrNode.gameObject:SetActive(false)
		self.heroNode.gameObject:SetActive(false)
	end
end

function ActivityYearSummaryPage6:playMoveAni(callback)
	self.parent_.isInAni = true
	local goTrans = self.go.transform
	local seq = self:getSequence()

	seq:Insert(0, goTrans:DOLocalMove(Vector3(-1000, -1000, 0), 0.6))
	seq:Insert(0, goTrans:DOLocalRotate(Vector3(0, 0, -60), 0.6))
	seq:InsertCallback(0.4, function ()
		self.parent_.isInAni = false

		if callback then
			callback()
		end
	end)
end

function ActivityYearSummaryPage6:canJumpAni()
	return true
end

function ActivityYearSummaryPage6:finishAni()
	self.parent_.isOpenAni = false
	self.title1.alpha = 1
	self.title2.alpha = 1
	self.title2_1.alpha = 1
	self.title3.alpha = 1
	self.title3_1.alpha = 1

	self.seq_:Pause()
	self.seq_:Kill(false)
end

function ActivityYearSummaryPage6:openAnimation()
	self.parent_.isOpenAni = true
	self.seq_ = self:getSequence(function ()
		self.parent_.isOpenAni = false
	end)

	local function setter1(value)
		self.title1.alpha = value
	end

	local function setter3(value)
		self.title3.alpha = value
		self.title3_1.alpha = value
	end

	local function setter2(value)
		self.title2.alpha = value
		self.title2_1.alpha = value
	end

	self.seq_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.26666666666666666))
	self.seq_:Insert(0.43333333333333335, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.23333333333333334))
	self.seq_:Insert(0.7666666666666667, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 0.23333333333333334))
end

function ActivityYearSummaryPage7:ctor(gameObject, parent)
	self.parent_ = parent

	ActivityYearSummaryPage7.super.ctor(self, gameObject)
end

function ActivityYearSummaryPage7:initUI()
	local goTrans = self.go.transform
	self.title1 = goTrans:ComponentByName("title1", typeof(UILabel))
	self.title2 = goTrans:ComponentByName("title2", typeof(UILabel))
	self.playerIconRoot = goTrans:NodeByName("playerIconRoot").gameObject
	self.playerName = goTrans:ComponentByName("playerName", typeof(UILabel))
	self.logoRoot = goTrans:NodeByName("logoRoot").gameObject

	if xyd.Global.lang == "de_de" then
		self.title1.spacingY = 2
	elseif xyd.Global.lang == "en_en" then
		self.title1.spacingY = 2
	elseif xyd.Global.lang == "fr_fr" then
		self.title1.spacingY = 2
	end
end

function ActivityYearSummaryPage7:layout()
	self.playerName.text = xyd.Global.playerName
	self.playerIcon = PlayerIcon.new(self.playerIconRoot)

	self.playerIcon:setInfo({
		noClick = true,
		avatarID = xyd.models.selfPlayer:getAvatarID(),
		lev = xyd.models.backpack:getLev(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID()
	})

	if not self.logoEffect then
		self.logoEffect = xyd.Spine.new(self.logoRoot)

		self.logoEffect:setInfo("loading1_zi", function ()
			self.logoEffect:SetLocalScale(0.6, 0.6, 0)

			if xyd.Global.lang == "ko_kr" or xyd.Global.lang == "ja_jp" then
				self.logoEffect:SetLocalPosition(-310, -440, 0)
			else
				self.logoEffect:SetLocalPosition(-310, -440, 0)
			end

			local aniName = "title_" .. xyd.Global.lang

			self.logoEffect:playAtTime(aniName, 1, 2.4)
		end)
	end

	self.title2.text = __("ANNUAL4_REVIEW_7_2")
	local texts = xyd.split(__("ANNUAL4_REVIEW_7_1"), "|")

	for i, text in ipairs(texts) do
		if not self.curStr then
			self.curStr = text
		else
			self.curStr = self.curStr .. "\\n" .. text
		end
	end

	self.title1.text = ""
	self.curStrPos = 1

	self:showLabelEffect()
	self.parent_.tipsLabel.gameObject:SetActive(false)
end

function ActivityYearSummaryPage7:playMoveAni(callback)
	self.parent_:onClickCloseButton()

	if callback then
		callback()
	end
end

function ActivityYearSummaryPage7:showLabelEffect()
	self.textEffectTimeoutId = "textEffect"
	self.parent_.isInAni = true
	local waitTime = 0.04

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		waitTime = 0.01
	end

	self:waitForTime(waitTime, function ()
		if not self.go or tolua.isnull(self.go) then
			return
		end

		local count = 1
		local c = string.sub(self.curStr, self.curStrPos, self.curStrPos)

		if c then
			if string.byte(c) > 128 then
				count = 3
				c = string.sub(self.curStr, self.curStrPos, self.curStrPos + 2)
			end

			if c == "\\" then
				count = 2
				c = string.sub(self.curStr, self.curStrPos, self.curStrPos + 1)
			end

			self.title1.text = self.title1.text .. c
		end

		self.curStrPos = self.curStrPos + count

		if self.curStrPos <= #self.curStr then
			self.textEffectTimeoutId = "textEffect" .. c

			self:showLabelEffect()
		else
			self.parent_.isInAni = false
			self.textEffectTimeoutId = nil
		end
	end, self.textEffectTimeoutId)
end

function ActivityYearSummaryPage7:showFinalText()
	if self.hasFinish_ then
		return
	end

	if next(self.waitForTimeKeys_) then
		for i = 1, #self.waitForTimeKeys_ do
			XYDCo.StopWait(self.waitForTimeKeys_[i])
		end

		self.waitForTimeKeys_ = {}
	end

	self.hasFinish_ = true
	self.textEffectTimeoutId = nil
	self.title1.text = self.curStr
	self.parent_.isInAni = false
end

function ActivityYearSummaryPage7:canJumpAni()
	return true
end

function ActivityYearSummaryPage7:finishAni()
end

function ActivityYearSummaryPage7:openAnimation()
end

function ActivityYearSummaryPage8:ctor(gameObject, parent)
	self.parent_ = parent
	self.itemsNum = 3

	ActivityYearSummaryPage8.super.ctor(self, gameObject)
end

function ActivityYearSummaryPage8:initUI()
	local goTrans = self.go.transform
	self.title1 = goTrans:ComponentByName("label1", typeof(UILabel))
	self.title2 = goTrans:ComponentByName("label2", typeof(UILabel))
	self.title3 = goTrans:ComponentByName("label3", typeof(UILabel))
	self.layoutWidgt = goTrans:ComponentByName("layout", typeof(UIWidget))
	self.part1_ = goTrans:NodeByName("layout/part1").gameObject
	self.part2_ = goTrans:NodeByName("layout/part2").gameObject
	self.part3_ = goTrans:NodeByName("layout/part3").gameObject
	self.title1_2 = goTrans:ComponentByName("layout/part1/label1-2", typeof(UILabel))
	self.title2_2 = goTrans:ComponentByName("layout/part2/label2-2", typeof(UILabel))
	self.title3_2 = goTrans:ComponentByName("layout/part3/label3-2", typeof(UILabel))
	self.title1_1 = goTrans:ComponentByName("layout/part1/label1-1", typeof(UILabel))
	self.title2_1 = goTrans:ComponentByName("layout/part2/label2-1", typeof(UILabel))
	self.title3_1 = goTrans:ComponentByName("layout/part3/label3-1", typeof(UILabel))
	self.layoutWidgt.alpha = 0
	self.title1.alpha = 0
	self.title2.alpha = 0
	self.title3.alpha = 0
	self.bookNode = self.part1_:NodeByName("bookNode").gameObject
	self.bookImg1 = self.bookNode:NodeByName("img1").gameObject
	self.bookImg2 = self.bookNode:NodeByName("img2").gameObject
	self.exchangeBtn = self.bookNode:NodeByName("btn").gameObject
end

function ActivityYearSummaryPage8:getCloisterNum(num)
	local result = {}
	local ids = xyd.tables.timeCloisterAchTypeTable:getIDs()
	local types = {
		61,
		77,
		73
	}
	local maxIndex = 1
	local needProgress = num

	if num > 9999 then
		maxIndex = 3
		needProgress = math.floor(num / 10000)
	elseif num > 99 then
		maxIndex = 2
		needProgress = math.floor(num / 100)
	end

	result.name = xyd.tables.timeCloisterTextTable:getName(maxIndex)
	result.percent = math.floor(needProgress / types[maxIndex] * 1000) / 10 .. "%"

	return result
end

function ActivityYearSummaryPage8:layout()
	self.selectBook = 1
	local onlyOne = false
	self.title1.text = __("ANNUAL4_REVIEW_5_1")
	self.title2.text = self.parent_.detail.total_power
	self.title3.text = __("ANNUAL4_REVIEW_5_2")

	if tonumber(self.parent_.detail.cloister_percent) > 0.5 then
		self.title2_2.text = __("ANNUAL4_REVIEW_5_6", self.parent_.detail.cloister_percent * 100 .. "%")
	else
		self.title2_1.transform:Y(self.title2_1.transform.localPosition.y - 20)
	end

	if tonumber(self.parent_.detail.shrine_percent) > 0.5 then
		self.title3_2.text = __("ANNUAL4_REVIEW_5_6", self.parent_.detail.shrine_percent * 100 .. "%")
	else
		self.title3_1.transform:Y(self.title3_1.transform.localPosition.y - 20)
	end

	local cloisterResult = self:getCloisterNum(tonumber(self.parent_.detail.cloister_score))
	self.title2_1.text = ""

	if cloisterResult.name then
		self.title2_1.text = __("ANNUAL4_REVIEW_5_10", cloisterResult.name, cloisterResult.percent)
	end

	self.title3_1.text = __("ANNUAL4_REVIEW_5_11", self.parent_.detail.shrine_score)

	if self.parent_.detail.trial_1_dmg == 0 and self.parent_.detail.trial_2_dmg > 0 then
		self.selectBook = 2
		onlyOne = true
	elseif self.parent_.detail.trial_2_dmg == 0 and self.parent_.detail.trial_1_dmg > 0 then
		onlyOne = true
	end

	if onlyOne then
		self.exchangeBtn:SetActive(false)
	end

	if tonumber(self.parent_.detail.shrine_score) == 0 then
		self.part3_:SetActive(false)

		self.itemsNum = self.itemsNum - 1

		if tonumber(self.parent_.detail.cloister_score) == 0 then
			self.part2_:SetActive(false)

			self.itemsNum = self.itemsNum - 1
		end
	end

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "en_en" then
		self.title1.transform:Y(300)
	end

	if xyd.Global.lang == "fr_fr" then
		self.title2_2.transform:Y(-30)

		self.title1_1.spacingY = 6
		self.title2_1.spacingY = 6
		self.title3_1.spacingY = 6
		self.title1_1.fontSize = 15
		self.title2_1.fontSize = 15
		self.title3_1.fontSize = 15
	end

	if xyd.Global.lang == "de_de" then
		self.title1_1.spacingY = 0
		self.title2_1.spacingY = 0
		self.title3_1.spacingY = 0
		self.title1_1.fontSize = 15
		self.title2_1.fontSize = 15
		self.title3_1.fontSize = 15
	end

	UIEventListener.Get(self.exchangeBtn).onClick = function ()
		if self.selectBook == 1 then
			self.selectBook = 2
		else
			self.selectBook = 1
		end

		self:updateBookItem()
	end

	self:updateBookItem()
	self:updateItemsPos()
end

function ActivityYearSummaryPage8:updateBookItem()
	self.bookImg1:SetActive(false)
	self.bookImg2:SetActive(false)
	self.bookNode:NodeByName("img" .. self.selectBook).gameObject:SetActive(true)

	if self.selectBook == 1 then
		self.title1_1.text = __("ANNUAL4_REVIEW_5_8", self.parent_.detail.trial_1_dmg)

		if tonumber(self.parent_.detail.trial_1_percent) > 0.5 then
			self.title1_2.text = __("ANNUAL4_REVIEW_5_6", self.parent_.detail.trial_1_percent * 100 .. "%")
		else
			self.title1_1.transform:Y(0)
		end
	else
		self.title1_1.text = __("ANNUAL4_REVIEW_5_9", self.parent_.detail.trial_2_dmg)

		if tonumber(self.parent_.detail.trial_2_percent) > 0.5 then
			self.title1_2.text = __("ANNUAL4_REVIEW_5_6", self.parent_.detail.trial_2_percent * 100 .. "%")
		else
			self.title1_1.transform:Y(0)
		end
	end
end

function ActivityYearSummaryPage8:updateItemsPos()
	if self.itemsNum == 2 then
		self.part1_:NodeByName("bg"):SetActive(false)
		self.part2_:NodeByName("bg"):SetActive(false)
		self.part1_:NodeByName("bg2"):SetActive(true)
		self.part2_:NodeByName("bg2"):SetActive(true)
		self.part1_.transform:Y(185)
		self.part2_.transform:Y(-35)
	elseif self.itemsNum == 1 then
		self.part1_:NodeByName("bg"):SetActive(false)
		self.part1_:NodeByName("bg1"):SetActive(true)
		self.part1_.transform:Y(150)
	end
end

function ActivityYearSummaryPage8:playMoveAni(callback)
	self.parent_.isInAni = true
	local goTrans = self.go.transform
	local seq = self:getSequence()

	seq:Insert(0, goTrans:DOLocalMove(Vector3(-1000, -1000, 0), 0.6))
	seq:Insert(0, goTrans:DOLocalRotate(Vector3(0, 0, -60), 0.6))
	seq:InsertCallback(0.4, function ()
		self.parent_.isInAni = false

		if callback then
			callback()
		end
	end)
end

function ActivityYearSummaryPage8:canJumpAni()
	return true
end

function ActivityYearSummaryPage8:finishAni()
	self.parent_.isOpenAni = false
	self.layoutWidgt.alpha = 1
	self.title1.alpha = 1
	self.title2.alpha = 1
	self.title3.alpha = 1

	self.seq_:Pause()
	self.seq_:Kill(false)
end

function ActivityYearSummaryPage8:openAnimation()
	self.parent_.isOpenAni = true
	self.seq_ = self:getSequence(function ()
		self.parent_.isOpenAni = false
	end)

	local function setter1(value)
		self.title1.alpha = value
		self.title2.alpha = value
	end

	local function setter3(value)
		self.layoutWidgt.alpha = value
	end

	local function setter2(value)
		self.title3.alpha = value
	end

	self.seq_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.26666666666666666))
	self.seq_:Insert(0.4, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.26666666666666666))
	self.seq_:Insert(0.7333333333333333, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 0.2))
end

return ActivityYearSummaryWindow
