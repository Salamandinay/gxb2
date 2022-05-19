local BaseWindow = import(".BaseWindow")
local TavernDetailWindow = class("TavernDetailWindow", BaseWindow)
local missionStatus = {
	UN_DO = 0,
	DOING = 1,
	DONE = 2
}
local tavernModel = xyd.models.tavern
local slotModel = xyd.models.slot
local pubMissionTable = xyd.tables.pubMissionTable
local json = require("cjson")
local TavernDetailItem = class("TavernDetailItem")
local OldSize = {
	w = 720,
	h = 1280
}

function TavernDetailItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = import("app.components.HeroIcon").new(self.uiRoot_)
end

function TavernDetailItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	self.partneId_ = info
	self.partner_ = slotModel:getPartner(info)
	self.tableID_ = self.partner_:getTableID()
	local params = {
		tableID = self.tableID_,
		lev = self.partner_:getLevel(),
		star = self.partner_:getStar(),
		job = self.partner_:getJob(),
		skin_id = self.partner_.skin_id,
		is_vowed = self.partner_.isVowed,
		dragScrollView = self.parent_.heroSelectScrollView_,
		callback = function ()
			self.heroIcon_.selected = false
			local flag = self.parent_:selectHero(info, false, self.uiRoot_.transform.position)

			if flag then
				self.heroIcon_.choose = true
			end
		end
	}

	self.heroIcon_:setInfo(params)

	if self.parent_:checkSelect(info) then
		self.heroIcon_.choose = true
	else
		self.heroIcon_.choose = false
	end
end

function TavernDetailItem:getHeroIcon()
	return self.heroIcon_
end

function TavernDetailItem:getPartnerId()
	return self.partneId_
end

function TavernDetailItem:setShowActive(canShow)
	self.uiRoot_.gameObject:SetActive(canShow)
end

function TavernDetailItem:refresh()
	for _, data in ipairs(self.parent_.chooseGroup_) do
		if data.partner and self.partneId_ == data.partner:getPartnerID() then
			self.heroIcon_.choose = true
			self.heroIcon_.selected = true
		end
	end
end

function TavernDetailItem:getGameObject()
	return self.uiRoot_
end

function TavernDetailWindow:ctor(name, params)
	TavernDetailWindow.super.ctor(self, name, params)

	self.data_ = params
	self.tableID_ = params.table_id
	self.missionID_ = params.mission_id
	self.selectGroup_ = 0
end

function TavernDetailWindow:initWindow()
	TavernDetailWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.content_ = winTrans:ComponentByName("content", typeof(UISprite)).transform
	self.heroGroup_ = winTrans:ComponentByName("heroGroup", typeof(UISprite)).transform
	self.btnStart_ = self.content_:ComponentByName("start", typeof(UISprite))
	self.btnLabelStart_ = self.content_:ComponentByName("start/labelDesc", typeof(UILabel))
	self.btnFastStart_ = self.content_:ComponentByName("faststart", typeof(UISprite))
	self.btnLabelFastStart_ = self.content_:ComponentByName("faststart/labelDesc", typeof(UILabel))
	self.conditionsLabel_ = self.content_:ComponentByName("conditionPart/label", typeof(UILabel))
	self.timeLabel_ = self.content_:ComponentByName("timePart/labelTimer", typeof(UILabel))
	self.labelTimeTips_ = self.content_:ComponentByName("timePart/labelDesc", typeof(UILabel))
	self.awardItem_ = self.content_:Find("award").gameObject
	local closeBtn = self.content_:ComponentByName("closeBtn", typeof(UISprite))

	self:layOut()
	self:initConditions()

	UIEventListener.Get(closeBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow("tavern_detail_window")
	end

	UIEventListener.Get(self.content_.gameObject).onClick = function ()
		local MovePosY = 700
		local sequence = DG.Tweening.DOTween.Sequence()

		if self.showHeroGroups_ then
			self.showHeroGroups_ = false

			sequence:Insert(0, self.heroGroup_:DOLocalMove(Vector3(0, -MovePosY, 0) + self.heroGroup_.localPosition, 0.2, false))
		end
	end

	UIEventListener.Get(self.btnFastStart_.gameObject).onClick = handler(self, self.onClickBtnFastStart)
	UIEventListener.Get(self.btnStart_.gameObject).onClick = handler(self, self.onClickBtnStart)
end

function TavernDetailWindow:playCloseAnimation(callback)
	self.heroGroup_.gameObject:SetActive(false)
	TavernDetailWindow.super.playCloseAnimation(self, callback)
end

function TavernDetailWindow:playOpenAnimation(callback)
	if self.data_.status ~= missionStatus.UN_DO then
		self:initMissionHeros()
		self.btnStart_.gameObject:SetActive(false)
		self.btnFastStart_.gameObject:SetActive(false)
	else
		self:initGroupSelects()
		self:initData()
		self:initGropSortHero()
		self:onClickBtnFastStart(nil, true)
	end

	self:changeStartBtn()

	if callback then
		callback()
	end
end

function TavernDetailWindow:layOut()
	self.btnLabelFastStart_.text = __("ONE_KEY_START")
	self.btnLabelStart_.text = __("START")
	local award = self.data_.award
	self.awardIcon_ = xyd.getItemIcon({
		hideText = true,
		itemID = award[1],
		num = award[2],
		uiRoot = self.awardItem_
	})
	self.conditionsLabel_.text = __("CONDITION")

	self:initTime()
end

function TavernDetailWindow:initConditions()
	local conditionConf = {
		group = "img_group",
		star = "pub_star_require",
		job = "pub_job_icon"
	}
	local partnerStar = xyd.tables.pubMissionTable:getPartnerStar(self.tableID_)
	self.tempConditions_ = {}
	self.heroSortGrid_ = self.window_.transform:ComponentByName("content/conditionPart/grid", typeof(UIGrid))
	local conditionsPrefab = self.window_.transform:ComponentByName("content/conditionPart/tempItem", typeof(UISprite))

	conditionsPrefab.gameObject:SetActive(false)

	local function initCondition(type, typeNum, id)
		local iconName = conditionConf[tostring(type)]
		local tempConditions = NGUITools.AddChild(self.heroSortGrid_.gameObject, conditionsPrefab.gameObject)

		tempConditions.gameObject:SetActive(true)

		local conditionIcon = tempConditions.transform:ComponentByName("conditionIcon", typeof(UISprite))
		local selectIcon = tempConditions.transform:ComponentByName("selectIcon", typeof(UISprite))

		selectIcon.gameObject:SetActive(false)
		xyd.setUISpriteAsync(conditionIcon, nil, iconName .. typeNum, function ()
			conditionIcon:MakePixelPerfect()
		end)

		local params = {
			hasOver = false,
			tempConditions = tempConditions,
			selectIcon = selectIcon,
			conditionID = id,
			[tostring(type)] = typeNum
		}

		if tostring(type) ~= "group" then
			local groupBg = tempConditions.transform:ComponentByName("groupBg", typeof(UISprite))

			groupBg.gameObject:SetActive(false)
		end

		table.insert(self.tempConditions_, params)
	end

	if partnerStar > 0 then
		initCondition("star", partnerStar, -1)
	end

	local conditions = self.data_.conditions

	table.sort(conditions, function (a, b)
		return tonumber(b) < tonumber(a)
	end)

	for _, id in ipairs(conditions) do
		local job = xyd.tables.pubConditionTable:getJob(id)
		local groupNum = xyd.tables.pubConditionTable:getGroup(id)

		if job > 0 then
			initCondition("job", job, id)
		end

		if groupNum > 0 then
			initCondition("group", groupNum, id)
		end
	end

	self.heroSortGrid_:Reposition()
end

function TavernDetailWindow:initTime()
	local missionTime = pubMissionTable:getMissionTime(self.tableID_)

	if self.data_.status ~= missionStatus.UN_DO then
		self.labelTimeTips_.gameObject:SetActive(false)
		self.timeLabel_.gameObject:SetActive(true)

		local serverTime = xyd.getServerTime()
		local duration = serverTime - self.data_.start_time
		local leftTime = missionTime - duration

		if leftTime <= 0 then
			leftTime = 0
			self.timeLabel_.text = xyd.secondsToString(leftTime)
		else
			self:setCountDown(leftTime)
		end

		self:initTimePointAction()
	else
		self.labelTimeTips_.gameObject:SetActive(true)
		self.timeLabel_.gameObject:SetActive(false)

		self.labelTimeTips_.text = xyd.getRoughDisplayTime(missionTime)
	end
end

function TavernDetailWindow:setCountDown(leftTime)
	local params = {
		callback = function ()
			self:initTime()
		end,
		duration = leftTime
	}

	if not self.tlabelRefreshTime_ then
		self.tlabelRefreshTime_ = import("app.components.CountDown").new(self.timeLabel_, params)
	else
		self.tlabelRefreshTime_:setInfo(params)
	end
end

function TavernDetailWindow:initTimePointAction()
	local alarmLineTrans = self.window_.transform:ComponentByName("content/timePart/linePos", typeof(UIWidget)).transform
	self.alarmAni_ = DG.Tweening.DOTween.Sequence()
	local angles = 0

	local function playAlarmAni()
		angles = math.fmod(angles + 90, 360)

		self.alarmAni_:Insert(0, alarmLineTrans:DORotate(Vector3(0, 0, angles), 0.2))
	end

	self.timer_ = Timer.New(handler(self, playAlarmAni), 2, -1, false)

	self.timer_:Start()
end

function TavernDetailWindow:initMissionHeros()
	self.heroIconList_ = {}
	local details = json.decode(self.data_.partner_details)
	local temp = self.window_.transform:ComponentByName("content/heroChoosePart/tempItem", typeof(UIWidget))
	local uiRoot = self.window_.transform:ComponentByName("content/heroChoosePart/tempItem/heroIcon", typeof(UIWidget))
	self.heroGrid_ = self.window_.transform:ComponentByName("content/heroChoosePart/grid", typeof(UIGrid))

	temp.gameObject:SetActive(false)

	local power = 0

	for _, info in ipairs(details) do
		local tableID = info.table_id
		local star = xyd.tables.partnerTable:getStar(tableID) + (info.awake or 0)
		local skinID = nil

		if info.show_skin and info.show_skin == 1 and info.equips and info.equips[7] and info.equips[7] > 0 then
			skinID = info.equips[7]
		end

		local tempItem = NGUITools.AddChild(self.heroGrid_.gameObject, uiRoot.gameObject)

		tempItem.gameObject:SetActive(true)

		local copyHero = import("app.components.HeroIcon").new(tempItem)

		copyHero:setInfo({
			noClick = true,
			hideText = true,
			tableID = tableID,
			star = star,
			skin_id = skinID,
			uiRoot = tempItem
		})
		table.insert(self.heroIconList_, copyHero)

		power = power + info.power
	end
end

function TavernDetailWindow:initData()
	self.heroSelectList_ = {}
	self.sortPartner_ = {}
	local heroRoot = self.window_.transform:Find("heroGroup/heroRoot").gameObject
	self.heroWarpContent_ = self.window_.transform:ComponentByName("heroGroup/scrollView/grid", typeof(MultiRowWrapContent))
	self.heroSelectScrollView_ = self.window_.transform:ComponentByName("heroGroup/scrollView", typeof(UIScrollView))
	self.sortPartners_ = slotModel:getSortedPartners()
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.heroSelectScrollView_, self.heroWarpContent_, heroRoot, TavernDetailItem, self)

	self:refreshHeroList()
	self.heroSelectScrollView_:ResetPosition()
end

function TavernDetailWindow:initGropSortHero()
	self.heroGroupSelectList_ = {}
	local gridSortGroup = self.window_.transform:ComponentByName("heroGroup/topSeletPart/grid", typeof(UIGrid))
	local tempItem = self.window_.transform:ComponentByName("heroGroup/topSeletPart/itemSelet", typeof(UISprite))
	local itemSeletCon = self.window_.transform:NodeByName("heroGroup/topSeletPart/itemSeletCon").gameObject

	tempItem.gameObject:SetActive(false)

	local params = {
		isCanUnSelected = 1,
		scale = 1,
		gap = 13,
		callback = handler(self, function (self, group)
			if self.selectGroup_ ~= group then
				self.selectGroup_ = group
			else
				self.selectGroup_ = 0
			end

			self:refreshHeroList(group)
		end),
		width = itemSeletCon:GetComponent(typeof(UIWidget)).width,
		chosenGroup = self.selectGroup_
	}
	local partnerFilter = import("app.components.PartnerFilter").new(itemSeletCon.gameObject, params)
	self.partnerFilter = partnerFilter
end

function TavernDetailWindow:refreshHeroList()
	local selectPartners = self.sortPartners_["0_" .. self.selectGroup_]

	self.multiWrap_:setInfos(selectPartners, {})
end

function TavernDetailWindow:initGroupSelects()
	self.chooseGroup_ = {}
	local maxNum = pubMissionTable:getPartnerNum(self.tableID_)
	local heroPrefab = self.window_.transform:ComponentByName("content/heroChoosePart/tempItem", typeof(UIWidget))

	heroPrefab.gameObject:SetActive(false)

	local heroShowGrid = self.window_.transform:ComponentByName("content/heroChoosePart/grid", typeof(UIGrid))

	for i = 1, maxNum do
		local tempShowHero = NGUITools.AddChild(heroShowGrid.gameObject, heroPrefab.gameObject)

		tempShowHero.gameObject:SetActive(true)

		local heroIcon = tempShowHero.transform:Find("heroIcon").gameObject

		table.insert(self.chooseGroup_, {
			flag = false,
			group = heroIcon
		})

		UIEventListener.Get(tempShowHero.gameObject).onClick = function ()
			self:showHeros()
		end
	end

	heroShowGrid:Reposition()
end

function TavernDetailWindow:showHeros()
	local MovePosY = 700
	local sequence = DG.Tweening.DOTween.Sequence()

	if self.showHeroGroups_ then
		self.showHeroGroups_ = false

		sequence:Insert(0, self.heroGroup_:DOLocalMove(Vector3(0, -MovePosY, 0) + self.heroGroup_.localPosition, 0.2, false))
	else
		self.showHeroGroups_ = true

		sequence:Insert(0, self.heroGroup_:DOLocalMove(Vector3(0, MovePosY, 0) + self.heroGroup_.localPosition, 0.2, false))
	end
end

function TavernDetailWindow:selectHero(partner_id, notMove, posBefore)
	if self:checkSelect(partner_id) then
		local params = {
			alertType = xyd.AlertType.TIPS,
			message = __("PUB_START_MISSION_6")
		}

		xyd.WindowManager.get():openWindow("alert_window", params)

		return true
	end

	local emptyRootData = self:getEmptyGroup()

	if not emptyRootData then
		local params = {
			alertType = xyd.AlertType.TIPS,
			message = __("PUB_MISSION_FULL_HERO")
		}

		xyd.WindowManager.get():openWindow("alert_window", params)

		return false
	end

	local pos = nil

	if not notMove then
		pos = emptyRootData.group.transform.localPosition
		emptyRootData.group.transform.position = posBefore
	end

	local partner = slotModel:getPartner(partner_id)
	local tableID = partner:getTableID()
	local copyHero = import("app.components.HeroIcon").new(emptyRootData.group)
	local params = {
		tableID = tableID,
		star = partner:getStar(),
		is_vowed = partner.isVowed,
		skin_id = partner.skin_id,
		callback = function ()
			copyHero.selected = false
			local item = self:getHeroIconByID(partner_id)

			if not item then
				UnityEngine.Object.Destroy(copyHero:getIconRoot())
			else
				item:getHeroIcon().choose = false

				UnityEngine.Object.Destroy(copyHero:getIconRoot())
			end

			emptyRootData.flag = false
			emptyRootData.partner = nil

			self:updateConditions()
			self:changeStartBtn()
		end
	}

	copyHero:setInfo(params)

	emptyRootData.flag = true
	emptyRootData.partner = partner

	self:updateConditions()
	self:changeStartBtn()

	if not notMove then
		local sequence = DG.Tweening.DOTween.Sequence()

		sequence:Insert(0, emptyRootData.group.transform:DOLocalMove(pos, 0.2, false))
	end

	return true
end

function TavernDetailWindow:getEmptyGroup()
	for _, data in ipairs(self.chooseGroup_) do
		if not data.flag then
			return data
		end
	end

	return nil
end

function TavernDetailWindow:getHeroIconByID(partner_id)
	local items = self.multiWrap_:getItems()

	for _, heroItem in ipairs(items) do
		if heroItem:getPartnerId() == partner_id then
			return heroItem
		end
	end

	return nil
end

function TavernDetailWindow:updateConditions()
	local jobs = {}
	local groups = {}
	local maxStar = 0

	for _, data in ipairs(self.chooseGroup_) do
		local partner = data.partner

		if partner then
			local star = partner:getStar()

			if maxStar < star then
				maxStar = star
			end

			groups[partner:getGroup()] = true
			jobs[partner:getJob()] = true
		end
	end

	for _, condition in ipairs(self.tempConditions_) do
		local bingoImg = condition.selectIcon

		bingoImg.gameObject:SetActive(false)

		condition.hasOver = false

		if condition.job and jobs[condition.job] then
			bingoImg.gameObject:SetActive(true)

			condition.hasOver = true
		end

		if condition.group and groups[condition.group] then
			bingoImg.gameObject:SetActive(true)

			condition.hasOver = true
		end

		if condition.star and condition.star <= maxStar then
			bingoImg.gameObject:SetActive(true)

			condition.hasOver = true
		end
	end
end

function TavernDetailWindow:changeStartBtn()
	if not self:checkCanStart() then
		self.btnStart_.color = Color.New2(2560137471.0)
	else
		self.btnStart_.color = Color.New2(4294967295.0)
	end
end

function TavernDetailWindow:checkCanStart()
	for _, condition in ipairs(self.tempConditions_) do
		if not condition.hasOver then
			return false
		end
	end

	for _, data in ipairs(self.chooseGroup_) do
		if not data.flag then
			return false
		end
	end

	return true
end

function TavernDetailWindow:onClickBtnStart()
	if not self:checkCanStart() then
		self:showCantStartTips()

		return
	end

	local partnerIDs = {}

	for _, data in ipairs(self.chooseGroup_) do
		local partner = data.partner

		if partner then
			table.insert(partnerIDs, partner:getPartnerID())
		end
	end

	tavernModel:startMission(self.missionID_, partnerIDs)
	xyd.WindowManager.get():closeWindow("tavern_detail_window")
end

function TavernDetailWindow:onClickBtnFastStart(_, noNeedTips)
	if self:checkCanStart() then
		return
	end

	local partners = self:getCanUsePartners()
	local needNum = pubMissionTable:getPartnerNum(self.tableID_)

	if needNum > #partners and not noNeedTips then
		local params = {
			alertType = xyd.AlertType.TIPS,
			message = __("PUB_MISSION_TIPS")
		}

		xyd.WindowManager.get():openWindow("alert_window", params)
	end

	local tmpSelect = {}
	local tmpConditions = {}
	local tmpSelectStar = {}
	local flag = false

	local function hasNumberInList(list, num)
		for _, Num in ipairs(list) do
			if Num == num then
				return true
			end
		end

		return false
	end

	for i = #partners, 1, -1 do
		local partnerID = partners[i]

		if not tavernModel:checkHeroIsSelect(partnerID) then
			local partner = slotModel:getPartner(partnerID)

			if partner then
				local star = partner:getStar()
				tmpSelectStar[partnerID] = star

				for _, data in ipairs(self.tempConditions_) do
					if not hasNumberInList(tmpConditions, data.conditionID) and (data.group and data.group == partner:getGroup() or data.job and data.job == partner:getJob() or data.star and data.star <= star) then
						table.insert(tmpConditions, data.conditionID)

						if not hasNumberInList(tmpSelect, partnerID) then
							table.insert(tmpSelect, partnerID)
						end
					end
				end

				if #tmpConditions == #self.tempConditions_ then
					flag = true

					break
				end
			end
		end
	end

	if flag then
		for _, data in ipairs(self.chooseGroup_) do
			local group = data.group
			local childNum = group.transform.childCount

			if childNum > 0 then
				local item = group.transform:GetChild(0)

				if item.name == "hero_icon" then
					NGUITools.Destroy(item)
				end
			end

			data.flag = false
			data.partner = nil
		end

		if needNum > #tmpSelect then
			local count = needNum - #tmpSelect

			for i = #partners, 0, -1 do
				local partnerID = partners[i]
				local partner = slotModel:getPartner(partnerID)

				if partner and not hasNumberInList(tmpSelect, partnerID) and not tavernModel:checkHeroIsSelect(partnerID) then
					table.insert(tmpSelect, partnerID)

					local star = partner:getStar()
					tmpSelectStar[partnerID] = star
					count = count - 1
				end

				if count <= 0 then
					break
				end
			end
		end

		table.sort(tmpSelect, function (a, b)
			local starA = tmpSelectStar[a] or 0
			local starB = tmpSelectStar[b] or 0

			return starA > starB
		end)

		for _, partnerID in ipairs(tmpSelect) do
			self:selectHero(partnerID, true)
		end

		self:refreshHeroList()
	elseif not noNeedTips then
		self:showOneKeyTips(tmpConditions)
	end
end

function TavernDetailWindow:showOneKeyTips(tmpConditions)
	local function hasNumberInList(list, num)
		for _, Num in ipairs(list) do
			if Num == num then
				return true
			end
		end

		return false
	end

	local tips = ""

	for _, data in ipairs(self.tempConditions_) do
		if not hasNumberInList(tmpConditions, data.conditionID) then
			local group = data.group
			local job = data.job
			local star = data.star

			if not data.hasOver then
				local tmpTips = ""

				if group then
					tmpTips = __("PUB_START_MISSION_3", xyd.tables.groupTable:getName(group))
				end

				if job then
					tmpTips = __("PUB_START_MISSION_2", xyd.tables.jobTable:getName(job))
				end

				if star then
					tmpTips = __("PUB_START_MISSION_4", star)
				end

				if tmpTips ~= "" then
					if tips ~= "" then
						tips = tips .. "\n"
					end

					tips = tips .. tmpTips
				end
			end
		end
	end

	local params = {
		alertType = xyd.AlertType.TIPS,
		message = tips
	}

	xyd.WindowManager.get():openWindow("alert_window", params)
end

function TavernDetailWindow:checkSelect(partnerId)
	for _, data in ipairs(self.chooseGroup_) do
		if data.partner and data.partner:getPartnerID() == partnerId then
			return true
		end

		if tavernModel:checkHeroIsSelect(partnerId) then
			return true
		end
	end

	return false
end

function TavernDetailWindow:showCantStartTips()
	local tips = ""

	if self.tempConditions_ then
		for _, data in ipairs(self.tempConditions_) do
			local group = data.group
			local job = data.job
			local star = data.star

			if not data.hasOver then
				local tmpTips = ""

				if group then
					tmpTips = __("PUB_START_MISSION_3", xyd.tables.groupTable:getName(group))
				end

				if job then
					tmpTips = __("PUB_START_MISSION_2", xyd.tables.jobTable:getName(job))
				end

				if star then
					tmpTips = __("PUB_START_MISSION_4", star)
				end

				if tmpTips ~= "" then
					if tips ~= "" then
						tips = tips .. "\n"
					end

					tips = tips .. tmpTips
				end
			end
		end
	end

	if tips == "" then
		local needNum = pubMissionTable:getPartnerNum(self.tableID_)
		tips = __("PUB_MISSION_NEED_NUM", needNum)
	end

	local params = {
		alertType = xyd.AlertType.TIPS,
		message = tips
	}

	xyd.WindowManager.get():openWindow("alert_window", params)
end

function TavernDetailWindow:getCanUsePartners()
	local function hasNumberInList(list, num)
		for _, Num in ipairs(list) do
			if Num == num then
				return true
			end
		end

		return false
	end

	local sortPartners = slotModel:getSortedPartners()
	local partners = sortPartners[xyd.partnerSortType.LEV .. "_" .. 0]
	local validPartners = {}

	for _, partnerID in ipairs(partners) do
		if not tavernModel:checkHeroIsSelect(partnerID) and not hasNumberInList(validPartners, partnerID) then
			table.insert(validPartners, partnerID)
		end
	end

	return validPartners
end

function TavernDetailWindow:willClose()
	TavernDetailWindow.super.willClose(self)

	if self.tlabelRefreshTime_ then
		self.tlabelRefreshTime_:stopTimeCount()

		self.tlabelRefreshTime_ = nil
	end

	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end
end

return TavernDetailWindow
