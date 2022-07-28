local ActivitySandSearch = class("ActivitySandSearch", import(".ActivityContent"))
local SandItem = class("SandItem", import("app.components.CopyComponent"))
local cjson = require("cjson")

function SandItem:ctor(go, parent, noClick)
	self.parent_ = parent
	self.noClick_ = noClick

	SandItem.super.ctor(self, go)
end

function SandItem:initUI()
	self:getUIComponent()
end

function SandItem:getUIComponent()
	local goTrans = self.go.transform
	self.itemImg = goTrans:ComponentByName("itemImg", typeof(UISprite))
	self.typeImg = goTrans:ComponentByName("typeImg", typeof(UISprite))
	self.effectNode1 = goTrans:NodeByName("effectNode1").gameObject
	self.effectNode2 = goTrans:NodeByName("effectNode2").gameObject
	UIEventListener.Get(self.go).onClick = handler(self, self.onClickItem)
end

function SandItem:setInfo(index, card_id)
	self.index_ = index

	if not card_id or card_id <= 0 then
		xyd.setUISpriteAsync(self.itemImg, nil, "activity_sand_search_item_icon1", nil, , true)
		self.itemImg.gameObject:SetActive(true)
	else
		self.card_id_ = card_id

		self.go:SetActive(false)
	end
end

function SandItem:resetInfo()
	if self.openEffect_ then
		self.openEffect_:destroy()
	end

	self.openEffect_ = nil

	if self.scoreEffect_ then
		self.scoreEffect_:destroy()
	end

	self.scoreEffect_ = nil

	self.go:SetActive(true)
	self.typeImg:SetActive(false)

	self.card_id_ = 0

	xyd.setUISpriteAsync(self.itemImg, nil, "activity_sand_search_item_icon1", nil, , true)
	self.itemImg.gameObject:SetActive(true)
	XYDCo.StopWait("sand_set_false_" .. self.index_)
end

function SandItem:playTypeAni(card_id, total_ids, stepNum, from_type)
	self.effectNode1:SetActive(true)
	self.effectNode2:SetActive(true)
	self.effectNode2.transform:X(0)
	self.effectNode2.transform:Y(-40)
	self.effectNode1.transform:X(-3.5)
	self.effectNode1.transform:Y(-45.5)

	local isSmart = self.parent_.smartResNum_ and self.parent_.smartResNum_ >= 1
	local timeScale1 = 0.5
	local timeScale2 = 0.6
	local timeScale = 1

	if isSmart then
		timeScale1 = 0.25
		timeScale2 = 0.3
		timeScale = 2
	end

	local function setter_2(value)
		self.typeImg.alpha = value
	end

	self.typeImg.alpha = 1

	if not self.openEffect_ then
		self.openEffect_ = xyd.Spine.new(self.effectNode1)

		self.openEffect_:setInfo("fx_sand_shovel", function ()
			if not from_type or from_type == 1 then
				self.openEffect_:play("texiao01", 1, timeScale)
				self:waitForTime(0.38, function ()
					self.itemImg.gameObject:SetActive(false)
				end)
				self:waitForTime(1.9, function ()
					local moveSequnce = self:getSequence(function ()
					end)

					moveSequnce:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter_2), 1, 0, 0.75))
				end)
			elseif from_type == 2 or from_type == 3 then
				self.itemImg.gameObject:SetActive(false)
				self.openEffect_:play("texiao02", 1, timeScale)
			elseif from_type == 4 then
				self.itemImg.gameObject:SetActive(false)
				self.openEffect_:play("texiao03", 1, timeScale)
			end
		end)
	end

	local type = xyd.tables.activitySandSearchGambleTable:getType(card_id)

	if type == 1 then
		self.effectNode2:SetActive(true)
		xyd.setUISpriteAsync(self.typeImg, nil, "activity_sand_search_type_" .. card_id, nil, , true)
		self:waitForTime(0.45, function ()
			self.typeImg.gameObject:SetActive(true)

			if not self.scoreEffect_ then
				self.scoreEffect_ = xyd.Spine.new(self.effectNode2)

				self.scoreEffect_:setInfo("fx_sand_light", function ()
					self.scoreEffect_:play("texiao01", 1, timeScale)
				end)
			end
		end)
		self:waitForTime(timeScale1, function ()
			self.parent_:playScoreUp(card_id, self.effectNode2)
		end)
	elseif type == 2 then
		if not self.scoreEffect_ then
			self.scoreEffect_ = xyd.Spine.new(self.effectNode2)

			self.scoreEffect_:setInfo("fx_sand_ball", function ()
				self:waitForTime(0.5, function ()
					self.scoreEffect_:play("texiao01", 1, timeScale)
				end)
			end)
		end

		self:waitForTime(timeScale1 + 0.5, function ()
			stepNum = stepNum + 1
			local next_ids = total_ids[stepNum]

			for index, index_id in ipairs(next_ids) do
				self.parent_:playCardAni2(index_id, total_ids, stepNum, type, index == #next_ids)
			end
		end)
	elseif type == 3 then
		if not self.scoreEffect_ then
			self.scoreEffect_ = xyd.Spine.new(self.effectNode2)

			self.scoreEffect_:setInfo("fx_sand_crab", function ()
				self:waitForTime(0.5, function ()
					self.scoreEffect_:play("texiao01", 1, timeScale)

					stepNum = stepNum + 1
					local next_ids = total_ids[stepNum]

					if next_ids[1] < self.index_ then
						table.sort(next_ids, function (a, b)
							return tonumber(b) < tonumber(a)
						end)
					else
						table.sort(next_ids, function (a, b)
							return tonumber(a) < tonumber(b)
						end)
					end

					local aniLong = #next_ids
					local stepTime = 3 * timeScale2 / aniLong
					local endPos = next_ids[aniLong]

					self.parent_:playCardAni3(self.index_, endPos, self.effectNode2)

					for index, index_id in ipairs(next_ids) do
						self:waitForTime(index * stepTime, function ()
							self.parent_:playCardAni2(index_id, total_ids, stepNum, type, index == #next_ids)
						end)
					end
				end)
			end)
		end
	elseif type == 4 then
		if not self.scoreEffect_ then
			self.scoreEffect_ = xyd.Spine.new(self.effectNode2)

			self.scoreEffect_:setInfo("fx_sand_tab", function ()
				self:waitForTime(0.5, function ()
					self.scoreEffect_:play("texiao01", 1, timeScale)
				end)
			end)
		end

		self:waitForTime(timeScale1 + 0.5, function ()
			stepNum = stepNum + 1
			local next_ids = total_ids[stepNum]

			for index, index_id in ipairs(next_ids) do
				self.parent_:playCardAni2(index_id, total_ids, stepNum, type, index == #next_ids)
			end
		end)
	end

	self:waitForTime(4 * timeScale1, function ()
		self.go:SetActive(false)
	end, "sand_set_false_" .. self.index_)
end

function SandItem:onClickItem()
	print("self.parent_.isInAnimation_   ", self.parent_.isInAnimation_)

	if self.parent_.isInAnimation_ or self.noClick_ then
		return
	end

	if not self.card_id_ or self.card_id_ <= 0 then
		self.parent_:onClickCard(self.index_)
	end
end

function ActivitySandSearch:ctor(parentGO, params)
	self.mapItemList_ = {}
	self.mapItemList2_ = {}
	self.scoreUpNum_ = 0

	ActivitySandSearch.super.ctor(self, parentGO, params)
end

function ActivitySandSearch:getPrefabPath()
	return "Prefabs/Windows/activity/activity_sand_search"
end

function ActivitySandSearch:initUI()
	self:getUIComponent()
	self:updateLabelNums()
	self:initProgress()
	self:updateSmartIcon()
	self:updateCardItemList()
	self:initCardItemNext()
	self:initSmartMap()
	self:register()

	local readHelp = tonumber(xyd.db.misc:getValue("activity_sand_read_help"))

	if not readHelp or readHelp ~= 1 then
		xyd.db.misc:setValue({
			value = 1,
			key = "activity_sand_read_help"
		})
		xyd.WindowManager.get():openWindow("activity_sand_search_help_window", {})
	end
end

function ActivitySandSearch:initSmartMap()
	self.smartMap_ = {}

	for i = 1, 49 do
		self.smartMap_[i] = i
	end

	self.smartIndex_ = 1

	for i = 1, 49 do
		local index = math.floor(math.random() * 48) + 1
		local temp = self.smartMap_[index]
		self.smartMap_[index] = self.smartMap_[i]
		self.smartMap_[i] = temp
	end
end

function ActivitySandSearch:loadRes()
	local res = xyd.getEffectFilesByNames({
		"fx_sand_shovel",
		"fx_sand_light",
		"fx_sand_ball",
		"fx_sand_crab"
	})
	local allHasRes = xyd.isAllPathLoad(res)

	if allHasRes then
		return
	else
		ResCache.DownloadAssets("activity_sand_search", res, function (success)
			xyd.WindowManager.get():closeWindow("res_loading_window")

			if tolua.isnull(self.go) then
				return
			end
		end, function (progress)
			local loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			if progress >= 1 and not loading_win then
				return
			end

			if not loading_win then
				xyd.WindowManager.get():openWindow("res_loading_window", {})
			end

			loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			loading_win:setLoadWndName("activity_sand_search_load")
			loading_win:setLoadProgress("activity_sand_search_load", progress)
		end, 1)
	end
end

function ActivitySandSearch:getUIComponent()
	self:loadRes()

	local goTrans = self.go.transform
	self.logoImg = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.awardBtn_ = goTrans:NodeByName("awardBtn").gameObject
	self.smartPart_ = goTrans:NodeByName("smartPart").gameObject
	self.smartIcon_ = goTrans:NodeByName("smartPart/icon").gameObject
	self.smartLabel_ = goTrans:ComponentByName("smartPart/label", typeof(UILabel))
	self.itemGroup1 = goTrans:NodeByName("itemGroup1").gameObject
	self.itemNumLabel1_ = goTrans:ComponentByName("itemGroup1/label", typeof(UILabel))
	self.itemGroup2 = goTrans:NodeByName("itemGroup2").gameObject
	self.itemNumLabel2_ = goTrans:ComponentByName("itemGroup2/label", typeof(UILabel))
	self.roundNumNode_ = goTrans:NodeByName("roundNumNode").gameObject
	self.cardGrid_ = goTrans:ComponentByName("cardGrid", typeof(UIGrid))
	self.cardGrid2_ = goTrans:ComponentByName("cardGrid2", typeof(UIGrid))
	self.cardItem_ = goTrans:NodeByName("cardItem").gameObject
	local progressPart = goTrans:NodeByName("progressPart")
	self.progressBar_ = progressPart:ComponentByName("progressBar", typeof(UIProgressBar))
	self.labelPoint_ = progressPart:ComponentByName("scoreBg/labelScore", typeof(UILabel))
	self.addPoint_ = progressPart:ComponentByName("scoreBg/addScore", typeof(UILabel))
	local awardGrid = progressPart:NodeByName("awardGrid")

	for i = 1, 3 do
		self["awardItem" .. i] = awardGrid:NodeByName("awardItem" .. i).gameObject
		self["awardIcon" .. i] = awardGrid:ComponentByName("awardItem" .. i .. "/icon", typeof(UISprite))
		self["awardLabel" .. i] = awardGrid:ComponentByName("awardItem" .. i .. "/label", typeof(UILabel))
		self["heroBg" .. i] = awardGrid:NodeByName("awardItem" .. i .. "/heroBg").gameObject
		self["heroGroup" .. i] = awardGrid:ComponentByName("awardItem" .. i .. "/heroBg/imgCamp_", typeof(UISprite))
		self["awardLabelPoint" .. i] = awardGrid:ComponentByName("awardItem" .. i .. "/labelPoint", typeof(UILabel))
		self["groupStars_" .. i] = awardGrid:NodeByName("awardItem" .. i .. "/heroBg/groupStars_").gameObject
		self["groupRedStars_" .. i] = awardGrid:NodeByName("awardItem" .. i .. "/heroBg/groupRedStars_").gameObject
		self["awardSelect" .. i] = awardGrid:NodeByName("awardItem" .. i .. "/imgChoose_").gameObject

		UIEventListener.Get(self["awardItem" .. i]).onClick = function ()
			self:onClickAwardItem(i)
		end
	end

	if not self.stageNum_ then
		self.stageNum_ = import("app.components.PngNum").new(self.roundNumNode_)
	end

	self:resizePosY(self.cardGrid_, -275, -300)
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_sand_search_logo_" .. xyd.Global.lang)
end

function ActivitySandSearch:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.db.misc:setValue({
			value = 1,
			key = "activity_sand_read_help"
		})
		xyd.WindowManager.get():openWindow("activity_sand_search_help_window", {})
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_sand_search_check_award_window", {})
	end

	UIEventListener.Get(self.itemGroup1).onClick = function ()
		local data = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SAND_SHOP)

		if not data then
			xyd.showToast(__("ACTIVITY_OPEN_TEXT"))
		else
			local win = xyd.WindowManager.get():getWindow("activity_window")
			local newParams = xyd.tables.activityTable:getWindowParams(xyd.ActivityID.ACTIVITY_SAND_SHOP)
			newParams.activity_type = xyd.tables.activityTable:getType(newParams.activity_ids[1])
			newParams.select = xyd.ActivityID.ACTIVITY_SAND_SHOP

			if win then
				xyd.goToActivityWindowAgain(newParams)
			else
				xyd.WindowManager.get():openWindow("activity_window", newParams)
			end
		end
	end

	UIEventListener.Get(self.itemGroup2).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.SAND_SEARCH_ITEM1,
			activityData = self.activityData
		})
	end

	UIEventListener.Get(self.smartPart_).onClick = handler(self, self.onClickSmartIcon)

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.updateLabelNums))
end

function ActivitySandSearch:onClickSmartIcon()
	if self.stage_id < 3 then
		xyd.alertTips(__("ACTIVITY_SAND_TEXT03"))

		return
	end

	if not self.smartResNum_ or self.smartResNum_ <= 0 then
		xyd.WindowManager.get():openWindow("activity_lafuli_drift_auto_window", {
			parent = self,
			itemID = xyd.ItemID.SAND_SEARCH_ITEM1,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.SAND_SEARCH_ITEM1),
			titleLabel = __("ACTIVITY_SAND_TEXT01"),
			descLabel = __("ACTIVITY_SAND_TEXT02"),
			callback = function (curNum)
				xyd.alertYesNo(__("ACTIVITY_SAND_TEXT04"), function (yes_no)
					if yes_no then
						self.smartResNum_ = curNum

						self:updateSmartIcon()
						self:startSmartOpen()
					end
				end)
			end
		})
	else
		self.smartResNum_ = 0

		self:updateSmartIcon()
	end
end

function ActivitySandSearch:startSmartOpen()
	local mapInfo = self.activityData:getMapInfo()

	if not self.smartIndex_ then
		self.smartIndex_ = 1
	end

	local cardInfo = mapInfo[self.smartMap_[self.smartIndex_]]

	if cardInfo and cardInfo > 0 then
		self.smartIndex_ = self.smartIndex_ + 1

		self:startSmartOpen()
	elseif self.smartMap_[self.smartIndex_] then
		if self.smartIndex_ > 49 then
			self.smartIndex_ = 1
		end

		self:onClickCard(self.smartMap_[self.smartIndex_], true)

		self.smartIndex_ = self.smartIndex_ + 1
		self.smartResNum_ = self.smartResNum_ - 1

		if self.smartResNum_ <= 0 then
			self:updateSmartIcon()
		end
	end
end

function ActivitySandSearch:onAward(event)
	if not event.data then
		return
	end

	local id = event.data.activity_id

	if id ~= xyd.ActivityID.ACTIVITY_SAND_SEARCH then
		return
	end

	local data = cjson.decode(event.data.detail)
	local items = data.items
	local mapInfo = data.map
	local callback = nil

	if items and #items > 0 then
		function callback()
			xyd.itemFloat(items)
		end
	end

	self.isInAnimation_ = true

	self:playCardAni(data.total_ids, callback, mapInfo)
end

function ActivitySandSearch:playCardAni(total_ids, callback, mapInfo)
	local id_list = total_ids[1]
	local mapInfo = mapInfo or self.activityData:getMapInfo()
	local timeScale = 1.2

	if self.smartResNum_ and tonumber(self.smartResNum_) >= 1 then
		timeScale = 0.6
	end

	for index, card_index in ipairs(id_list) do
		local card_id = tonumber(mapInfo[card_index])

		self.mapItemList_[card_index]:playTypeAni(card_id, total_ids, 1, nil, index == #id_list)
	end

	local addTime = 0

	if #total_ids > 1 then
		addTime = 0.5
	end

	local stage_id = self.activityData:getStageID()

	if self.stage_id < stage_id then
		self:waitForTime(#total_ids * timeScale * 1.2 + addTime + 0.1, function ()
			self:changeMapAni()
		end)
		self:waitForTime(#total_ids * timeScale * 1.2 + addTime, function ()
			self.labelPoint_.text = tonumber(self.labelPoint_.text) + self.scoreUpNum_
			self.scoreUpNum_ = 0

			self:updateProgress()
		end)
	elseif self.smartResNum_ and tonumber(self.smartResNum_) >= 1 then
		self:waitForTime(#total_ids * timeScale * 1.2 + addTime + 0.1, function ()
			self:startSmartOpen()
		end)
		self:waitForTime(#total_ids * timeScale * 1.2 + addTime, function ()
			self.labelPoint_.text = tonumber(self.labelPoint_.text) + self.scoreUpNum_
			self.scoreUpNum_ = 0

			self:updateProgress()

			self.isInAnimation_ = false
		end)
	else
		self:waitForTime(#total_ids * timeScale * 1.2 + addTime, function ()
			self.labelPoint_.text = tonumber(self.labelPoint_.text) + self.scoreUpNum_
			self.scoreUpNum_ = 0

			self:updateProgress()

			self.isInAnimation_ = false
		end)
	end

	self:waitForTime(#total_ids * timeScale * 1.8 + addTime, function ()
		if callback then
			callback()
		end
	end)
end

function ActivitySandSearch:playCardAni2(card_index, total_ids, step_num, from_type)
	local mapInfo = self.activityData:getMapInfo()
	local card_id = tonumber(mapInfo[card_index])

	self.mapItemList_[card_index]:playTypeAni(card_id, total_ids, step_num, from_type)
end

function ActivitySandSearch:playCardAni3(start_index, end_index, node)
	local moveX = (end_index - start_index) * 98
	local moveSequnce = self:getSequence(function ()
		node.gameObject:SetActive(false)
	end)
	local startX = node.transform.localPosition.x

	local function setter1(value)
		node.transform:X(startX + moveX * value)
	end

	local timeScale = 1.6

	if self.smartResNum_ and tonumber(self.smartResNum_) >= 1 then
		timeScale = 0.8
	end

	moveSequnce:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, timeScale):SetEase(DG.Tweening.Ease.Linear))
end

function ActivitySandSearch:updateSmartIcon()
	self.smartLabel_.text = __("ACTIVITY_SAND_TEXT01")

	if self.smartResNum_ and tonumber(self.smartResNum_) >= 1 then
		local roundNum = 0

		local function setter1(value)
			self.smartIcon_.transform.localEulerAngles = Vector3(0, 0, value)
		end

		function self.playAni2_()
			if self.sequence1_ then
				self.sequence1_:Kill(false)

				self.sequence1_ = nil
			end

			self.sequence2_ = self:getSequence()

			self.sequence2_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), -360 * roundNum, (roundNum + 1) * -360, 2):SetEase(DG.Tweening.Ease.Linear))

			roundNum = roundNum + 1

			self.sequence2_:AppendCallback(function ()
				self.playAni1_()
			end)
		end

		function self.playAni1_()
			self.sequence1_ = self:getSequence()

			if self.sequence2_ then
				self.sequence2_:Kill(false)

				self.sequence2_ = nil
			end

			self.sequence1_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), -360 * roundNum, -360 * (roundNum + 1), 2):SetEase(DG.Tweening.Ease.Linear))

			roundNum = roundNum + 1

			self.sequence1_:AppendCallback(function ()
				self.playAni2_()
			end)
		end

		self.playAni1_()

		return
	end

	local roundNum = 0

	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end
end

function ActivitySandSearch:updateLabelNums()
	self.itemNumLabel1_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.SAND_SEARCH_ITEM2)
	self.itemNumLabel2_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.SAND_SEARCH_ITEM1)
end

function ActivitySandSearch:initProgress()
	local point = self.activityData:getPoint()
	self.stage_id = self.activityData:getStageID()
	self.labelPoint_.text = point
	local pointStage = xyd.tables.activitySandSearchAwardTable:getPointStage()
	local progressValue = 1
	local valueStage = {
		0,
		0.2,
		0.59,
		1
	}
	self.awardItemList_ = {}

	for i = 3, 1, -1 do
		local awardItem = xyd.tables.activitySandSearchAwardTable:getAward(self.stage_id, i)
		self.awardItemList_[i] = awardItem

		xyd.setUISpriteAsync(self["awardIcon" .. i], nil, xyd.tables.itemTable:getIcon(awardItem[1]))

		self["awardLabel" .. i].text = xyd.getRoughDisplayNumber(awardItem[2])

		if pointStage[i] <= point then
			xyd.applyGrey(self["awardIcon" .. i])

			self["awardLabel" .. i].color = Color.New2(1212696831)

			self["awardSelect" .. i]:SetActive(true)
		else
			xyd.applyOrigin(self["awardIcon" .. i])

			self["awardLabel" .. i].color = Color.New2(2956140543.0)

			self["awardSelect" .. i]:SetActive(false)

			if pointStage[i - 1] and pointStage[i - 1] <= point then
				progressValue = valueStage[i] + (valueStage[i + 1] - valueStage[i]) * (point - pointStage[i - 1]) / (pointStage[i] - pointStage[i - 1])
			else
				progressValue = valueStage[i + 1] * point / pointStage[i]
			end
		end

		local type_ = xyd.tables.itemTable:getType(awardItem[1])

		if type_ == xyd.ItemType.HERO_DEBRIS or type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.HERO_RANDOM_DEBRIS or type_ == xyd.ItemType.SKIN then
			local group = xyd.tables.itemTable:getGroup(awardItem[1])
			local qlt = xyd.tables.itemTable:getQuality(awardItem[1])

			self["heroBg" .. i]:SetActive(true)

			if group and group > 0 then
				self["heroGroup" .. i].gameObject:SetActive(true)
				xyd.setUISprite(self["heroGroup" .. i], xyd.Atlas.COMMON_UI, "img_group" .. tostring(group))
			else
				self["heroGroup" .. i].gameObject:SetActive(false)
			end

			if qlt == 6 and type_ == 3 then
				self["groupStars_" .. i]:SetActive(false)
				self["groupRedStars_" .. i]:SetActive(true)
			elseif qlt == 5 and type_ == 3 then
				self["groupStars_" .. i]:SetActive(true)
				self["groupRedStars_" .. i]:SetActive(false)
			else
				self["groupStars_" .. i]:SetActive(false)
				self["groupRedStars_" .. i]:SetActive(false)
			end
		else
			self["heroBg" .. i]:SetActive(false)
		end

		self["awardLabelPoint" .. i].text = pointStage[i]
	end

	self.progressBar_.value = progressValue

	self.stageNum_:setInfo({
		iconName = "activity_sand_search_round",
		num = self.stage_id
	})
end

function ActivitySandSearch:onClickAwardItem(index)
	xyd.WindowManager.get():openWindow("item_tips_window", {
		notShowGetWayBtn = true,
		show_has_num = true,
		itemID = self.awardItemList_[index][1],
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})
end

function ActivitySandSearch:updateCardItemList()
	local mapInfo = self.activityData:getMapInfo()

	for index, card_id in ipairs(mapInfo) do
		if not self.mapItemList_[index] then
			local ItemNew = NGUITools.AddChild(self.cardGrid_.gameObject, self.cardItem_)

			ItemNew:SetActive(true)

			self.mapItemList_[index] = SandItem.new(ItemNew, self)
		end

		self.mapItemList_[index]:setInfo(index, card_id)
	end

	self.cardGrid_:Reposition()
end

function ActivitySandSearch:resetMap()
	local point = 0
	local pointStage = xyd.tables.activitySandSearchAwardTable:getPointStage()

	self:initSmartMap()

	self.stage_id = self.activityData:getStageID()

	self.stageNum_:setInfo({
		iconName = "activity_sand_search_round",
		num = self.stage_id
	})

	for i = 3, 1, -1 do
		local awardItem = xyd.tables.activitySandSearchAwardTable:getAward(self.stage_id, i)
		self.awardItemList_[i] = awardItem
		local icon = xyd.tables.itemTable:getIcon(awardItem[1])

		xyd.setUISpriteAsync(self["awardIcon" .. i], nil, icon)

		self["awardLabel" .. i].text = xyd.getRoughDisplayNumber(awardItem[2])

		if pointStage[i] <= point then
			xyd.applyGrey(self["awardIcon" .. i])

			self["awardLabel" .. i].color = Color.New2(1212696831)

			self["awardSelect" .. i]:SetActive(true)
		else
			xyd.applyOrigin(self["awardIcon" .. i])

			self["awardLabel" .. i].color = Color.New2(2956140543.0)

			self["awardSelect" .. i]:SetActive(false)
		end

		self["awardLabelPoint" .. i].text = pointStage[i]
		local type_ = xyd.tables.itemTable:getType(awardItem[1])

		if type_ == xyd.ItemType.HERO_DEBRIS or type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.HERO_RANDOM_DEBRIS or type_ == xyd.ItemType.SKIN then
			self["heroBg" .. i]:SetActive(true)

			local group = xyd.tables.itemTable:getGroup(awardItem[1])

			self["heroBg" .. i]:SetActive(true)

			local qlt = xyd.tables.itemTable:getQuality(awardItem[1])

			if group and group > 0 then
				self["heroGroup" .. i].gameObject:SetActive(true)
				xyd.setUISprite(self["heroGroup" .. i], xyd.Atlas.COMMON_UI, "img_group" .. tostring(group))
			else
				self["heroGroup" .. i].gameObject:SetActive(false)
			end

			if qlt == 6 and type_ == 3 then
				self["groupStars_" .. i]:SetActive(false)
				self["groupRedStars_" .. i]:SetActive(true)
			elseif qlt == 5 and type_ == 3 then
				self["groupStars_" .. i]:SetActive(true)
				self["groupRedStars_" .. i]:SetActive(false)
			else
				self["groupStars_" .. i]:SetActive(false)
				self["groupRedStars_" .. i]:SetActive(false)
			end
		else
			self["heroBg" .. i]:SetActive(false)
		end
	end

	for index, mapItem in ipairs(self.mapItemList_) do
		mapItem:resetInfo()
	end
end

function ActivitySandSearch:initCardItemNext()
	self:waitForTime(1, function ()
		for index = 1, 49 do
			if not self.mapItemList2_[index] then
				local ItemNew = NGUITools.AddChild(self.cardGrid2_.gameObject, self.cardItem_)

				ItemNew:SetActive(true)

				self.mapItemList2_[index] = SandItem.new(ItemNew, self, true)
			end

			self.mapItemList2_[index]:setInfo(index, 0)
		end

		self.cardGrid2_:Reposition()
	end)
end

function ActivitySandSearch:onClickCard(index, is_smart)
	if self.smartResNum_ and self.smartResNum_ > 0 and not is_smart then
		return
	end

	local cost = xyd.split(xyd.tables.miscTable:getVal("activity_sand_cost"), "#", true)

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

		return
	end

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SAND_SEARCH, cjson.encode({
		type = 1,
		id = index
	}))
end

function ActivitySandSearch:playScoreUp(card_id, node)
	self.addPoint_.gameObject:SetActive(true)

	local addNum = xyd.tables.activitySandSearchGambleTable:getParams(card_id)
	self.scoreUpNum_ = self.scoreUpNum_ + addNum
	self.addPoint_.text = "+" .. self.scoreUpNum_
	local localPos = node.transform:InverseTransformPoint(self.labelPoint_.transform.position)
	local tragetPosition = node.transform.localPosition
	local startX = tragetPosition.x
	local startY = tragetPosition.y
	local xChange = localPos.x - tragetPosition.x
	local yChange = localPos.y - tragetPosition.y - 80
	local tweenAni = self:getSequence(function ()
		node:SetActive(false)
		self:waitForTime(0.2, function ()
			self.addPoint_.gameObject:SetActive(false)
		end)
	end)

	local function setter1(value)
		node.transform:SetLocalPosition(startX + xChange * value, startY + yChange * value, 0)
	end

	tweenAni:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 1))
end

function ActivitySandSearch:updateProgress()
	local point = self.activityData:getPoint()
	local pointStage = xyd.tables.activitySandSearchAwardTable:getPointStage()
	local progressValue = 1
	local valueStage = {
		0,
		0.2,
		0.59,
		1
	}

	for i = 3, 1, -1 do
		if pointStage[i] <= point then
			xyd.applyGrey(self["awardIcon" .. i])

			self["awardLabel" .. i].color = Color.New2(1212696831)

			self["awardSelect" .. i]:SetActive(true)
		else
			xyd.applyOrigin(self["awardIcon" .. i])

			self["awardLabel" .. i].color = Color.New2(2956140543.0)

			self["awardSelect" .. i]:SetActive(false)

			if pointStage[i - 1] and pointStage[i - 1] <= point then
				progressValue = valueStage[i] + (valueStage[i + 1] - valueStage[i]) * (point - pointStage[i - 1]) / (pointStage[i] - pointStage[i - 1])
			else
				progressValue = valueStage[i + 1] * point / pointStage[i]
			end
		end
	end

	local valueBefore = tonumber(self.progressBar_.value)
	local tweenAni = self:getSequence()

	local function setter1(value)
		self.progressBar_.value = valueBefore + (progressValue - valueBefore) * value
	end

	tweenAni:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.8))
end

function ActivitySandSearch:changeMapAni()
	self.isInAnimation_ = true
	local changeMapSeq = self:getSequence(function ()
		self.labelPoint_.text = 0
		self.progressBar_.value = 0

		self:resetMap()
		self.cardGrid_.gameObject:SetActive(false)
		self.cardGrid_.transform:SetLocalPosition(-300, -275, 0)
		self:waitForTime(0.1, function ()
			self.cardGrid2_.transform:SetLocalPosition(1000, -275, 0)
			self.cardGrid_.gameObject:SetActive(true)

			if self.smartResNum_ and self.smartResNum_ > 1 then
				self:startSmartOpen()
			end
		end)
		self:waitForTime(1, function ()
			self.isInAnimation_ = false
		end)
	end)

	changeMapSeq:Insert(0, self.cardGrid_.transform:DOLocalMove(Vector3(-1300, -275, 0), 1))
	changeMapSeq:Insert(0, self.cardGrid2_.transform:DOLocalMove(Vector3(-300, -275, 0), 1))
end

return ActivitySandSearch
