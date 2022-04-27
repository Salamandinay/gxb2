local ArcticExpeditionRecordWindow = class("ArcticExpeditionRecordWindow", import(".BaseWindow"))
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local Monster = import("app.models.Monster")
local ArcticExpeditionRecordItem = class("ArcticExpeditionRecordItem", import("app.components.CopyComponent"))
local ReportHero = import("lib.battle.ReportHero")

function ArcticExpeditionRecordItem:ctor(go, parent)
	self.parent_ = parent

	ArcticExpeditionRecordItem.super.ctor(self, go, parent)
end

function ArcticExpeditionRecordItem:initUI()
	ArcticExpeditionRecordItem.super.initUI(self)
	self:getUIComponent()
end

function ArcticExpeditionRecordItem:playOpenAnimation(isover)
	local sequnce = self:getSequence(function ()
		if isover then
			self.parent_.maskImg_:SetActive(false)
			xyd.setEnabled(self.parent_.sureBtn_, true)
		end
	end, true)
	local mainWidgt = self.main:GetComponent(typeof(UIWidget))

	local function setter1(value)
		mainWidgt.alpha = value
	end

	local function setter2(value)
		self.resultIcon.alpha = value
	end

	local function setter3(value)
		self.resultLabel.alpha = value
	end

	local function setter4(value)
		self.resHpLabel.alpha = value
	end

	local resImg = self.resHp:GetComponent(typeof(UISprite))
	resImg.alpha = 0

	local function setter6(value)
		resImg.alpha = value
	end

	local function setter5(value)
		self.resHpValueImg.alpha = value
	end

	self.parent_.gContainer_:Reposition()
	self.parent_.scrollview_:ResetPosition()
	self:waitForFrame(1, function ()
		self.parent_:Reset()
	end)
	self:waitForFrame(2, function ()
		self.parent_:Reset()
	end)
	self:waitForFrame(3, function ()
		self.parent_:Reset()
	end)
	self:waitForFrame(4, function ()
		self.parent_:Reset()
	end)
	self:waitForFrame(5, function ()
		self.parent_:Reset()
	end)
	sequnce:Insert(0, self.main.transform:DOScale(Vector3(1, 1, 1), 0.13333333333333333))
	sequnce:Insert(0.13333333333333333, self.main.transform:DOScale(Vector3(1.03, 0.99, 1), 0.1))
	sequnce:Insert(0.23333333333333334, self.main.transform:DOScale(Vector3(0.99, 1.03, 1), 0.13333333333333333))
	sequnce:Insert(0.36666666666666664, self.main.transform:DOScale(Vector3(1, 1, 1), 0.1))
	sequnce:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.2))

	if self.params_.battle_report.isWin and self.params_.battle_report.isWin == 1 then
		self.effect1_:setInfo("fx_ept_success", function ()
			self.effect1_:play("texiao01", 1, 1)
		end)
		self.effect2_:setInfo("fx_ept_success", function ()
			self:waitForFrame(20, function ()
				self.effect2_:play("texiao02", 1, 1)
			end)
		end)
		self.effect3_:setInfo("fx_ept_success", function ()
			self:waitForFrame(29, function ()
				self.effect3_:play("texiao04", 1, 1)
			end)
		end)
		self.resHp.gameObject:SetActive(false)
		sequnce:Insert(0.5333333333333333, self.resultIcon.transform:DOLocalMove(Vector3(325, 27.2, 0), 0.13333333333333333))
		sequnce:Insert(0.5333333333333333, self.resultIcon.transform:DOScale(Vector3(1, 1, 1), 0.13333333333333333))
		sequnce:Insert(0.6666666666666666, self.resultIcon.transform:DOLocalMove(Vector3(325, 16, 0), 0.1))
		sequnce:Insert(0.6666666666666666, self.resultIcon.transform:DOScale(Vector3(1, 1.08, 0.94), 0.1))
		sequnce:Insert(0.7666666666666667, self.resultIcon.transform:DOLocalMove(Vector3(325, 17.3, 0), 0.1))
		sequnce:Insert(0.7666666666666667, self.resultIcon.transform:DOScale(Vector3(0.94, 1.04, 0.94), 0.1))
		sequnce:Insert(0.8666666666666667, self.resultIcon.transform:DOLocalMove(Vector3(325, 16, 0), 0.1))
		sequnce:Insert(0.8666666666666667, self.resultIcon.transform:DOScale(Vector3(1, 1, 1), 0.1))
		sequnce:Insert(0.5333333333333333, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.13333333333333333))
		sequnce:Insert(0.9666666666666667, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 0.3333333333333333))
	else
		self.resultIcon.transform:Y(41.6)

		self.resultIcon.transform.localScale = Vector3(0.8, 0.8, 0.8)

		self.resHp.transform:Y(-29.4)
		self.effect1_:setInfo("fx_ept_fail", function ()
			self.effect1_:play("texiao01", 1, 1)
		end)
		self.effect2_:setInfo("fx_ept_fail", function ()
			self:waitForFrame(16, function ()
				self.effect2_:SetLocalPosition(0, -16, 0)
				self.effect2_:play("texiao02", 1, 1)
			end)
		end)
		self.effect3_:setInfo("fx_ept_fail", function ()
			self:waitForFrame(48, function ()
				self.effect3_:play("texiao03", 1, 1)
			end)
		end)
		sequnce:Insert(0.5333333333333333, self.resultIcon.transform:DOLocalMove(Vector3(325, 43.6, 0), 0.13333333333333333))
		sequnce:Insert(0.5333333333333333, self.resultIcon.transform:DOScale(Vector3(1, 1, 1), 0.13333333333333333))
		sequnce:Insert(0.6666666666666666, self.resultIcon.transform:DOLocalMove(Vector3(325, 16, 0), 0.3))
		sequnce:Insert(0.5333333333333333, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.13333333333333333))
		sequnce:Insert(1.1, self.resHp.transform:DOLocalMove(Vector3(325, -33, 0), 0.4666666666666667))
		sequnce:Insert(1.6, self.resHpValueImg.transform:DOScale(Vector3(1, 1, 1), 0.3333333333333333))
		sequnce:Insert(1.6, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter5), 0, 1, 0.13333333333333333))
		sequnce:Insert(1.6, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter4), 0, 1, 0.13333333333333333))
		sequnce:Insert(1.6, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter6), 0, 1, 0.13333333333333333))
	end
end

function ArcticExpeditionRecordItem:getUIComponent()
	local trans = self.go.transform
	self.effectRoot1 = trans:NodeByName("effectRoot1").gameObject
	self.main = trans:NodeByName("main").gameObject
	self.effectRoot2 = self.main:NodeByName("resultIcon/effectRoot2").gameObject
	self.effectRoot3 = self.main:NodeByName("effectRoot3").gameObject
	self.effect1_ = xyd.Spine.new(self.effectRoot1)
	self.effect2_ = xyd.Spine.new(self.effectRoot2)
	self.effect3_ = xyd.Spine.new(self.effectRoot3)
	self.bgImg = self.main:ComponentByName("bg", typeof(UITexture))
	self.matchNum = self.main:ComponentByName("title/matchNum", typeof(UILabel))
	self.video = self.main:NodeByName("title/video").gameObject
	self.detail = self.main:NodeByName("title/detail").gameObject
	self.bg = self.main:ComponentByName("bg", typeof(UITexture))
	self.resultIcon = self.main:ComponentByName("resultIcon", typeof(UISprite))
	self.resultLabel = self.main:ComponentByName("resultLabel", typeof(UILabel))
	self.resHp = self.main:ComponentByName("resHp", typeof(UIProgressBar))
	self.resHpValueImg = self.main:ComponentByName("resHp/e:image", typeof(UISprite))
	self.resHpLabel = self.main:ComponentByName("resHp/resLabel", typeof(UILabel))
	local cnt = 1
	self.groupInfo1 = self.main:NodeByName("groupInfo1").gameObject
	self.serverId = self.groupInfo1:ComponentByName("serverId1", typeof(UILabel))
	self.groupImg = self.groupInfo1:ComponentByName("groupImg", typeof(UISprite))
	self.groupInfo2 = self.main:NodeByName("groupInfo2").gameObject

	self.groupInfo2:SetActive(false)

	self.enemyName2 = self.main:ComponentByName("groupInfo2/serverId2", typeof(UILabel))
	local pIcon = self.main:NodeByName("pIcon1").gameObject
	self.pIcon1 = PlayerIcon.new(pIcon)
	self.cellImg = self.main:ComponentByName("cellImg", typeof(UISprite))
	self.pName1 = self.main:ComponentByName("pName1", typeof(UILabel))
	self.pName2 = self.main:ComponentByName("pName2", typeof(UILabel))
	self.pName2Text = self.main:ComponentByName("pName2Text", typeof(UILabel))

	for i = 1, 2 do
		local grid1 = self.main:NodeByName("grid" .. i .. "_1").gameObject
		local grid2 = self.main:NodeByName("grid" .. i .. "_2").gameObject

		for j = 1, 2 do
			local root = grid1:NodeByName("e:Group/hero" .. cnt).gameObject
			self["hero" .. cnt] = HeroIcon.new(root)

			self["hero" .. cnt]:SetActive(false)

			cnt = cnt + 1
		end

		for j = 3, 6 do
			local root = grid2:NodeByName("e:Group/hero" .. cnt).gameObject
			self["hero" .. cnt] = HeroIcon.new(root)

			self["hero" .. cnt]:SetActive(false)

			cnt = cnt + 1
		end
	end

	self.pName2Text.text = __("ARCTIC_EXPEDITION_TEXT_16")
	UIEventListener.Get(self.video).onClick = handler(self, self.onClickVideo)
	UIEventListener.Get(self.detail).onClick = handler(self, self.onClickDetail)
end

function ArcticExpeditionRecordItem:setInfo(params, cell_id, self_info, index)
	self.cellId_ = cell_id
	self.params_ = params
	self.self_info = self_info
	self.cellType_ = xyd.tables.arcticExpeditionCellsTable:getCellType(self.cellId_)
	self.cellFunctionId_ = xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(self.cellType_)
	local cellImg = xyd.tables.arcticExpeditionCellsTypeTable:getIconImg(self.cellType_)
	local cellName = xyd.tables.arcticExpeditionCellsTypeTable:getCellName(self.cellType_)
	self.pName2.text = cellName

	xyd.setUISpriteAsync(self.cellImg, nil, cellImg)

	local isWin = params.battle_report.isWin

	if isWin == 1 then
		self:setState(1)
	else
		self:setState(0)
	end

	if self.parent_.isMine_ then
		self.resultLabel.text = __("ARCTIC_EXPEDITION_TEXT_17")
	elseif self.parent_.changeNum < index then
		self.resultLabel.text = __("ARCTIC_EXPEDITION_TEXT_17")
	else
		self.resultLabel.text = __("ARCTIC_EXPEDITION_TEXT_24")
	end

	self.matchNum.text = __("MATCH_NUM", index)

	self.pIcon1:setInfo(self_info or {})
	self.pIcon1:setScale(0.8)

	self.serverId.text = xyd.getServerNumber(self_info.server_id)
	self.pName1.text = self_info.player_name
	local teamA = params.battle_report.teamA
	local teamB = params.battle_report.teamB
	local petA = params.battle_report.petA
	local petB = params.battle_report.petB
	local petIDA = 0
	local petIDB = 0

	if petA then
		petIDA = petA.pet_id
	end

	if petB then
		petIDB = petB.pet_id
	end

	local group = self_info.group or 1

	xyd.setUISpriteAsync(self.groupImg, nil, "arctic_expedition_cell_group_icon_" .. group)

	local posHas = {}

	for i = 1, #teamA do
		local index = teamA[i].pos
		posHas[index] = true
		local partner = Partner.new()

		partner:populate(teamA[i])

		local info = partner:getInfo()
		info.dragScrollView = self.parent_.scrollview_
		info.scale = 0.6

		self["hero" .. index]:setInfo(info, petIDA)
		self["hero" .. index]:setNoClick(true)
		self["hero" .. index]:SetActive(true)
	end

	local totalHp = 0
	local resHp = 0
	local beforeHp = 0
	xyd.Battle.godPosSkill = {}

	for i = 1, 6 do
		if teamB[i] then
			local index = teamB[i].pos + 6
			posHas[index] = true
			local partner = Partner.new()

			if teamB[i].isMonster then
				partner = Monster.new()

				partner:populateWithTableID(teamB[i].table_id)
			else
				partner:populate(teamB[i])
			end

			local hero = ReportHero.new()

			hero:populateWithTableID(teamB[i].table_id)

			local class = hero:className()
			local fighter = xyd.Battle.requireFighter(class).new()

			fighter:populateWithHero(hero)
			fighter:setTeamType(xyd.TeamType.B)
			fighter:setPos(index)

			if teamB[i].status then
				fighter.status = teamB[i].status
			end

			if teamB[i].change_attr then
				fighter.change_attr = teamB[i].change_attr
			end

			fighter:initHp()

			local hp = fighter:getHpLimit()
			totalHp = totalHp + hp
			beforeHp = beforeHp + hp * teamB[i].status.hp / 100
			local info = partner:getInfo()
			info.scale = 0.6
			info.dragScrollView = self.parent_.scrollview_

			self["hero" .. index]:setInfo(info, petIDB)
			self["hero" .. index]:setNoClick(true)
			self["hero" .. index]:SetActive(true)
		end
	end

	for i = 1, 12 do
		if not posHas[i] then
			self["hero" .. i]:SetActive(false)
		else
			self["hero" .. i]:SetActive(true)
		end
	end

	if params.battle_report.total_harm then
		resHp = beforeHp - params.battle_report.total_harm
	end

	local dieInfo = params.battle_report.die_info or {}

	if isWin == 1 then
		for i = 1, #teamB do
			local index = teamB[i].pos + 6

			self["hero" .. index]:setGrey()
		end

		for i = 1, #teamA do
			local index = teamA[i].pos

			if xyd.arrayIndexOf(dieInfo, index) > 0 then
				self["hero" .. index]:setGrey()
			end
		end
	else
		local showNum = math.floor((1 - resHp / totalHp) * 100)
		self.resHp.value = showNum / 100
		self.resHpLabel.text = tostring(showNum) .. "%"

		for i = 1, #teamA do
			local index = teamA[i].pos

			self["hero" .. index]:setGrey()
		end

		for i = 1, #teamB do
			local index = teamB[i].pos + 6

			if xyd.arrayIndexOf(dieInfo, index) > 0 then
				self["hero" .. index]:setGrey()
			end
		end
	end

	local battleReport = params.battle_report

	if battleReport and battleReport.random_seed and battleReport.random_seed > 0 then
		self.isSimple = true

		self.detail:SetActive(true)
	end
end

function ArcticExpeditionRecordItem:onClickVideo()
	xyd.BattleController:arcticExpeditionSingleBattle(self.params_, self.parent_.cellId_, self.self_info)
end

function ArcticExpeditionRecordItem:onClickDetail()
	local die_info = nil
	local battleReport = self.params_.battle_report

	if battleReport and battleReport.random_seed and battleReport.random_seed > 0 then
		local report = xyd.BattleController.get():createReport(battleReport)
		die_info = report.die_info
	end

	die_info = {}

	xyd.WindowManager.get():openWindow("battle_detail_data_window", {
		alpha = 0.7,
		battle_params = self.params_.battle_report,
		real_battle_report = self.params_.battle_report,
		die_info = die_info
	})
end

function ArcticExpeditionRecordItem:setState(state)
	if state == 1 then
		xyd.setUITextureByNameAsync(self.bgImg, "arctic_expedition_record_bg_win")
		xyd.setUISpriteAsync(self.resultIcon, nil, "arctic_win")

		self.matchNum.effectColor = Color.New2(2742695167.0)
	else
		xyd.setUITextureByNameAsync(self.bgImg, "arctic_expedition_record_bg_lose")
		xyd.setUISpriteAsync(self.resultIcon, nil, "arctic_lose")

		self.matchNum.effectColor = Color.New2(1047573503)
	end
end

function ArcticExpeditionRecordWindow:ctor(name, params)
	ArcticExpeditionRecordWindow.super.ctor(self, name, params)

	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)
	self.isMine_, self.changeNum = self.activityData_:getBattleShowType()
	self.cellId_ = params.cell_id
	self.battleData_ = params.battle_info
	self.score_ = params.score
	self.stepNum_ = 1
	self.recordItemList_ = {}
	self.heroIconList_ = {}
end

function ArcticExpeditionRecordWindow:initWindow()
	self:getComponent()
	self:regisetr()
	self:initLayout()
end

function ArcticExpeditionRecordWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.bgImg_ = winTrans:ComponentByName("bg", typeof(UIWidget))
	self.labelTitle_ = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.line2_ = winTrans:ComponentByName("line2", typeof(UIWidget))
	self.maskBg_ = winTrans:NodeByName("maskBg").gameObject
	self.maskImg_ = winTrans:NodeByName("maskPanel/maskImg").gameObject
	self.selfInfoGroup_ = winTrans:NodeByName("selfInfoGroup").gameObject
	self.labelWinNumText_ = self.selfInfoGroup_:ComponentByName("attr_label_large/labelName", typeof(UILabel))
	self.labelWinNum_ = self.selfInfoGroup_:ComponentByName("attr_label_large/labelValue", typeof(UILabel))
	self.labelWinScoreText_ = self.selfInfoGroup_:ComponentByName("attr_label_large2/labelName", typeof(UILabel))
	self.labelWinScore_ = self.selfInfoGroup_:ComponentByName("attr_label_large2/labelValue", typeof(UILabel))

	for i = 1, 6 do
		self["heroRoot" .. i] = self.selfInfoGroup_:NodeByName("heroGroup/container_" .. i).gameObject
	end

	self.sureBtn_ = self.selfInfoGroup_:NodeByName("sureBtn").gameObject
	self.sureBtnLabel_ = self.selfInfoGroup_:ComponentByName("sureBtn/label", typeof(UILabel))
	self.scrollview_ = winTrans:ComponentByName("scrollview", typeof(UIScrollView))
	self.gContainer_ = winTrans:ComponentByName("scrollview/gContainer", typeof(UILayout))
	self.ArcticRecordItemRoot_ = winTrans:NodeByName("scrollview/ArcticRecordItem").gameObject

	xyd.setEnabled(self.sureBtn_, false)
end

function ArcticExpeditionRecordWindow:regisetr()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.sureBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ARCTIC_EXPEDITION_HELP_BATTLE"
		})
	end
end

function ArcticExpeditionRecordWindow:onClickEscBack()
end

function ArcticExpeditionRecordWindow:initLayout()
	self.labelTitle_.text = __("ARCTIC_EXPEDITION_TEXT_13")
	self.sureBtnLabel_.text = __("SURE")
	self.labelWinNumText_.text = __("ARCTIC_EXPEDITION_TEXT_14")
	self.labelWinScoreText_.text = __("ARCTIC_EXPEDITION_TEXT_15")
	local era = self.activityData_:getEra()
	local winTime = 0

	for _, info in ipairs(self.battleData_) do
		if info.battle_report.isWin and info.battle_report.isWin == 1 then
			winTime = winTime + 1
		end
	end

	self.labelWinNum_.text = winTime .. "/" .. xyd.tables.arcticExpeditionEraTable:getWinLimit(era)
	self.labelWinScore_.text = math.floor(self.score_ * 10) / 10

	self:initHeroList()
end

function ArcticExpeditionRecordWindow:Reset()
	if self.window_ and not tolua.isnull(self.window_) then
		self.gContainer_:Reposition()
		self.scrollview_:ResetPosition()
	end
end

function ArcticExpeditionRecordWindow:playOpenAnimation(callback)
	ArcticExpeditionRecordWindow.super.playOpenAnimation(self, function ()
		if callback then
			callback()
		end

		self:showReportAnimation(true)
	end)
end

function ArcticExpeditionRecordWindow:showReportAnimation(isFirst)
	self.isInOpenAnimation_ = true
	local newItem = NGUITools.AddChild(self.gContainer_.gameObject, self.ArcticRecordItemRoot_)

	newItem.transform:SetSiblingIndex(0)

	local self_info = {
		server_id = xyd.models.selfPlayer:getServerID(),
		player_name = xyd.Global.playerName,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		lev = xyd.models.backpack:getLev(),
		group = self.activityData_:getSelfGroup()
	}
	local stepNum = self.stepNum_

	if stepNum + 1 > #self.battleData_ then
		self.isInOpenAnimation_ = false
	else
		self:waitForTime(2, function ()
			self:showReportAnimation()
		end)
	end

	local newRecordItem = ArcticExpeditionRecordItem.new(newItem, self)

	newRecordItem:setInfo(self.battleData_[self.stepNum_], self.cellId_, self_info, stepNum)
	newRecordItem:playOpenAnimation(not self.isInOpenAnimation_)
	self:waitForTime(1.2, function ()
		self:updateHeroFineList(stepNum)
	end)

	self.stepNum_ = self.stepNum_ + 1
end

function ArcticExpeditionRecordWindow:updateHeroFineList(stepNum)
	local recordInfo = self.battleData_[stepNum]

	if not recordInfo then
		return
	end

	local fightList = self.activityData_:getFightPartnerList()
	local teamA = recordInfo.battle_report.teamA

	for i = 1, #teamA do
		local index = teamA[i].pos
		local partner_id = fightList[index]
		local stateBefore = xyd.models.activity:getArcticPartnerState(partner_id)

		self.activityData_:changePartnerFine(partner_id, -1)

		local stateValue = xyd.models.activity:getArcticPartnerValue(partner_id)
		local stateNow = xyd.models.activity:getArcticPartnerState(partner_id)
		local maxValue = xyd.tables.miscTable:getVal("expedition_girls_labor", "value")

		if self.heroIconList_[i] then
			self.heroIconList_[i]:updateStateValue(stateValue / maxValue)

			if stateBefore ~= stateNow then
				self.heroIconList_[i]:showStateImgChangeAni(stateNow)
			end
		end
	end
end

function ArcticExpeditionRecordWindow:checkInAnimation(recordIndex)
	if recordIndex and recordIndex <= self.stepNow_ and self.isInAnimation_ then
		return true
	else
		return false
	end
end

function ArcticExpeditionRecordWindow:initHeroList()
	local heroList = self.activityData_:getFightPartnerList()
	local maxValue = xyd.tables.miscTable:getVal("expedition_girls_labor", "value")

	for i = 1, 6 do
		local partner = Partner.new()
		local partnerID = heroList[i]

		if partnerID and partnerID > 0 then
			local partnerState = xyd.models.activity:getArcticPartnerState(partnerID)
			local partnerValue = xyd.models.activity:getArcticPartnerValue(partnerID)
			local partnerInfo = xyd.models.slot:getPartner(partnerID)
			local heroIcon = HeroIcon.new(self["heroRoot" .. i])

			heroIcon:setInfo(partnerInfo)
			heroIcon:setNoClick(true)
			heroIcon:getPartExample("progressWithIcon")
			heroIcon:updateStateValue(partnerValue / maxValue)
			heroIcon:updateStateImg(partnerState)
			heroIcon:setClickStateImg(function ()
				xyd.WindowManager.get():openWindow("arctic_partner_fine_detail_window", {
					partner_id = partnerID
				})
			end)

			self.heroIconList_[i] = heroIcon
		end
	end
end

function ArcticExpeditionRecordWindow:willClose()
	self.activityData_:getArcPartnerInfos()
end

return ArcticExpeditionRecordWindow
