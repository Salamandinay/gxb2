local BaseWindow = import(".BaseWindow")
local GrowthDiaryWindow = class("GrowthDiaryWindow", BaseWindow)
local MissionItem = class("MissionItem", import("app.components.CopyComponent"))

function MissionItem:ctor(go, parent)
	self.parent_ = parent

	MissionItem.super.ctor(self, go)
end

function MissionItem:initUI()
	self.go_ = self.go
	local itemTrans = self.go_.transform
	self.baseWi_ = itemTrans:GetComponent(typeof(UIWidget))
	self.progressPart = itemTrans:ComponentByName("progressPart", typeof(UIProgressBar))
	self.progressDesc_ = itemTrans:ComponentByName("progressPart/labelDesc", typeof(UILabel))
	self.btnGo_ = itemTrans:NodeByName("jumpBtn").gameObject
	self.btnGoLabel_ = itemTrans:ComponentByName("jumpBtn/label", typeof(UILabel))
	self.btnGoMask_ = itemTrans:NodeByName("jumpBtn/mask").gameObject
	self.btnAward_ = itemTrans:NodeByName("awardBtn").gameObject
	self.btnAwardLabel_ = itemTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.btnAwardMask_ = itemTrans:NodeByName("awardBtn/mask").gameObject
	self.awardImg_ = itemTrans:ComponentByName("awardImg", typeof(UISprite))
	self.missionDesc_ = itemTrans:ComponentByName("descLabel", typeof(UILabel))
	self.specailImg = itemTrans:NodeByName("specailImg").gameObject
	self.iconRoot_ = itemTrans:Find("itemRoot").gameObject

	UIEventListener.Get(self.btnGo_).onClick = function ()
		self:jumpFunction()
	end

	UIEventListener.Get(self.btnAward_).onClick = function ()
		self:awardFunction()
	end
end

function MissionItem:setInfo(data)
	if not data then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.missionData_ = data
	self.missionID_ = self.missionData_.mission_id
	self.missionDesc_.text = xyd.tables.grouthDiaryMissionTable:getDesc(self.missionID_)
	self.btnGoLabel_.text = __("GO")
	self.btnAwardLabel_.text = __("GROWTH_DIARY_TEXT12")
	local is_awarded = self.missionData_.is_awarded == 1
	local is_compelete = self.missionData_.is_completed == 1
	local completeValue = xyd.tables.grouthDiaryMissionTable:getCompleteValue(self.missionID_)

	if is_compelete then
		self.progressPart.value = 1

		self.btnGo_:SetActive(false)
		self.btnAward_:SetActive(not is_awarded)

		self.progressDesc_.text = completeValue .. "/" .. completeValue
	else
		self.progressPart.value = self.missionData_.value / completeValue

		self.btnGo_:SetActive(true)
		self.btnAward_:SetActive(false)

		self.progressDesc_.text = self.missionData_.value .. "/" .. completeValue
	end

	local awardItem = xyd.tables.grouthDiaryMissionTable:getAward(self.missionID_)

	NGUITools.DestroyChildren(self.iconRoot_.transform)

	local itemIcon = xyd.getItemIcon({
		notShowGetWayBtn = true,
		noClickSelected = true,
		scale = 0.7037037037037037,
		uiRoot = self.iconRoot_,
		itemID = awardItem[1],
		num = awardItem[2]
	})

	itemIcon:setChoose(is_awarded)

	if xyd.tables.grouthDiaryMissionTable:getSpecial(self.missionID_) == 1 then
		self.specailImg:SetActive(true)
	else
		self.specailImg:SetActive(false)
	end

	local isUnlock = self.parent_.chapter_ <= xyd.models.growthDiary:getChapter()

	self.btnAwardMask_:SetActive(is_awarded or not isUnlock)
	self.btnGoMask_:SetActive(not isUnlock)
	xyd.setUISpriteAsync(self.awardImg_, nil, "mission_awarded_" .. xyd.Global.lang)
	self.awardImg_.gameObject:SetActive(is_awarded)
end

function MissionItem:jumpFunction()
	local isUnlock = self.parent_.chapter_ <= xyd.models.growthDiary:getChapter()

	if not isUnlock then
		xyd.alertTips(__("GROWTH_DIARY_TEXT06"))
	end

	local jumpID = xyd.tables.grouthDiaryMissionTable:getGetWay(self.missionID_)
	local funId = xyd.tables.getWayTable:getFunctionId(jumpID)

	if funId ~= 0 and not xyd.checkFunctionOpen(funId) then
		return
	end

	xyd.goWay(jumpID, nil, , function ()
		xyd.models.growthDiary:clearTime()
		xyd.WindowManager.get():openWindow("growth_dairy_window", {})
	end)
	self.parent_:close()
end

function MissionItem:awardFunction()
	local isUnlock = self.parent_.chapter_ <= xyd.models.growthDiary:getChapter()

	if self.missionData_.is_awarded ~= 1 and isUnlock then
		xyd.models.growthDiary:reqAward(self.missionID_)
	elseif not isUnlock then
		xyd.alertTips(__("GROWTH_DIARY_TEXT08"))
	end
end

function GrowthDiaryWindow:ctor(name, params)
	GrowthDiaryWindow.super.ctor(self, name, params)

	self.chapter_ = xyd.models.growthDiary:getChapter() or 1
	self.chapterAwardList_ = {}
	self.missionList_ = {}
end

function GrowthDiaryWindow:initWindow()
	self:getUIComponent()
	self:updatePageBtn()

	if not xyd.models.growthDiary:reqMissionData() then
		self:updateTopAward()
		self:updateMissionList()
		self:initProgress()
	end

	self:register()
end

function GrowthDiaryWindow:getUIComponent()
	local winTran = self.window_:NodeByName("groupAction")
	self.labelTitle_ = winTran:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn_ = winTran:NodeByName("closeBtn").gameObject
	self.contentGroup_ = winTran:NodeByName("contentGroup")
	self.contentGroupWidgt = winTran:ComponentByName("contentGroup", typeof(UIWidget))
	self.chapterTitle_ = self.contentGroup_:ComponentByName("chapterTitle", typeof(UILabel))
	self.rightBtn = self.contentGroup_:NodeByName("rightBtn").gameObject
	self.leftBtn = self.contentGroup_:NodeByName("leftBtn").gameObject

	for i = 1, 4 do
		self["progress" .. i] = self.contentGroup_:ComponentByName("progressGroup/progressBar" .. i, typeof(UIProgressBar))
	end

	self.progressLabel_ = self.contentGroup_:ComponentByName("progressGroup/progressLabel", typeof(UILabel))
	self.progressValueLabel_ = self.contentGroup_:ComponentByName("progressGroup/progressValue", typeof(UILabel))
	self.awardPart_ = self.contentGroup_:NodeByName("awardPart")
	self.awardLabel_ = self.awardPart_:ComponentByName("awardLabel", typeof(UILabel))
	self.itemGrid_ = self.awardPart_:ComponentByName("itemGrid", typeof(UILayout))
	self.awardBtn_ = self.awardPart_:NodeByName("awardBtn").gameObject
	self.awardBtnSprite_ = self.awardPart_:ComponentByName("awardBtn", typeof(UISprite))
	self.awardBtnLabel_ = self.awardPart_:ComponentByName("awardBtn/label", typeof(UILabel))
	self.awardBtnMask_ = self.awardPart_:NodeByName("awardBtn/mask").gameObject
	self.aawrdBtnRed_ = self.awardPart_:NodeByName("awardBtn/redPoint").gameObject
	self.awardTipsLabel_ = self.awardPart_:ComponentByName("tipsLabel", typeof(UILabel))
	self.labelTip1_ = self.contentGroup_:ComponentByName("labelTip1", typeof(UILabel))
	self.labelTip2_ = self.contentGroup_:ComponentByName("labelTip2", typeof(UILabel))
	self.misssionGrid = self.contentGroup_:ComponentByName("misssionGrid", typeof(UILayout))
	self.missionItem = self.contentGroup_:NodeByName("missionItem").gameObject
	self.labelTitle_.text = __("GROWTH_DIARY_TITLE")
	self.progressLabel_.text = __("GROWTH_DIARY_TEXT02")
	local tips = xyd.split(__("GROWTH_DIARY_TEXT09"), "|")
	self.awardLabel_.text = __("GROWTH_DIARY_TEXT03")
	self.labelTip1_.text = tips[1]
	self.labelTip2_.text = tips[2]
end

function GrowthDiaryWindow:initProgress()
	local ids = xyd.tables.grouthDiaryMissionTable:getIDsByChapter(self.chapter_)

	table.sort(ids)

	self.progressValue = 0

	for index, id in ipairs(ids) do
		local missionData = xyd.models.growthDiary:getMissionInfo(id)

		if missionData.is_awarded == 1 then
			self.progressValue = self.progressValue + 1
		end
	end

	self.progressValueLabel_.text = "[c][e56092]" .. self.progressValue .. "/[-][c][4e4752]4"

	for i = 1, 4 do
		self["progress" .. i].value = xyd.checkCondition(i <= self.progressValue, 1, 0)
	end

	self.isInAnim_ = false
end

function GrowthDiaryWindow:updatePageBtn()
	local length = #xyd.tables.grouthDiaryMissionTable:getIDsByChapter()

	if self.chapter_ <= 1 then
		self.leftBtn:SetActive(false)
		self.rightBtn:SetActive(true)
	elseif length <= self.chapter_ then
		self.rightBtn:SetActive(false)
		self.leftBtn:SetActive(true)
	else
		self.leftBtn:SetActive(true)
		self.rightBtn:SetActive(true)
	end
end

function GrowthDiaryWindow:register()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.leftBtn).onClick = function ()
		if self.chapter_ <= 1 then
			return
		end

		if self.isInAnim_ then
			return
		end

		self:changePageAni(-1)
	end

	UIEventListener.Get(self.rightBtn).onClick = function ()
		local length = #xyd.tables.grouthDiaryMissionTable:getIDsByChapter()

		if length <= self.chapter_ then
			return
		end

		if self.isInAnim_ then
			return
		end

		self:changePageAni(1)
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		local isUnlock = self.chapter_ <= xyd.models.growthDiary:getChapter()
		local isAwarded = xyd.models.growthDiary:checkChapterAwarded(self.chapter_)

		if not isAwarded then
			if not isUnlock then
				xyd.alertTips(__("GROWTH_DIARY_TEXT06"))

				return
			elseif xyd.models.growthDiary:checkCanAward(self.chapter_) then
				xyd.models.growthDiary:reqChapterAward(self.chapter_)
			else
				xyd.alertTips(__("GROWTH_DIARY_TEXT05"))
			end
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_GROWTH_MISSIONS, handler(self, self.onGetMissionList))
	self.eventProxy_:addEventListener(xyd.event.GET_GROWTH_CHAPTER_AWARDS, handler(self, self.onGetChapterAwards))
	self.eventProxy_:addEventListener(xyd.event.GET_GROWTH_MISSIONS_AWARDS, handler(self, self.onGetMissionAwards))
end

function GrowthDiaryWindow:onGetMissionAwards(event)
	local id = event.data.mission_ids[1]
	local awardItem = xyd.tables.grouthDiaryMissionTable:getAward(id)
	local items = {}

	table.insert(items, {
		item_id = awardItem[1],
		item_num = awardItem[2]
	})
	xyd.itemFloat(items)

	local ids = xyd.tables.grouthDiaryMissionTable:getIDsByChapter(self.chapter_)

	table.sort(ids)

	local index = xyd.arrayIndexOf(ids, id)
	local missionData = xyd.models.growthDiary:getMissionInfo(id)

	if self.missionList_[index] then
		self.missionList_[index]:setInfo(missionData)
	end

	self:playProgressAni()
	self:updateTopAward()
end

function GrowthDiaryWindow:playProgressAni()
	self.progressValue = self.progressValue + 1

	if self.progressValue > 4 then
		self.progressValue = 4
	end

	self.progressValueLabel_.text = "[c][e56092]" .. self.progressValue .. "/[-][c][4e4752]4"
	local progressPart = self["progress" .. self.progressValue]

	local function setter1(value)
		progressPart.value = value
	end

	local sequence = self:getSequence()

	sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.8))
end

function GrowthDiaryWindow:onGetChapterAwards(event)
	local chapter_id = event.data.id
	local awards = xyd.tables.grouthDiaryMissionTable:getChapterAwards(chapter_id)
	local items = {}

	for _, item in ipairs(awards) do
		table.insert(items, {
			item_id = item[1],
			item_num = item[2]
		})
	end

	xyd.alertItems(items, function ()
		local length = #xyd.tables.grouthDiaryMissionTable:getIDsByChapter()

		if length >= chapter_id + 1 then
			self:changePageAni(1)
		end
	end)
end

function GrowthDiaryWindow:changePageAni(addNum)
	self.isInAnim_ = true

	local function setter1(value)
		if self.contentGroupWidgt and not tolua.isnull(self.contentGroupWidgt) then
			self.contentGroupWidgt.alpha = value
		end
	end

	self.sequence2_ = self:getSequence()
	self.sequence1_ = self:getSequence(function ()
		self.chapter_ = self.chapter_ + addNum

		self:updatePageBtn()

		if not xyd.models.growthDiary:reqMissionData(self.chapter_) then
			self:updateTopAward()
			self:updateMissionList()
			self:initProgress()
		end

		self.sequence2_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.6))
	end)

	self.sequence1_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 1, 0, 0.4))
end

function GrowthDiaryWindow:updateTopAward()
	self.chapterTitle_.text = __("GROWTH_DIARY_TEXT01", self.chapter_)
	local isAwarded = xyd.models.growthDiary:checkChapterAwarded(self.chapter_)
	local awards = xyd.tables.grouthDiaryMissionTable:getChapterAwards(self.chapter_)
	local isUnlock = self.chapter_ <= xyd.models.growthDiary:getChapter()

	NGUITools.DestroyChildren(self.itemGrid_.transform)

	for i = 1, #awards do
		local awardItem = awards[i]
		local icon = xyd.getItemIcon({
			noClickSelected = true,
			notShowGetWayBtn = true,
			scale = 0.7037037037037037,
			itemID = awardItem[1],
			num = awardItem[2],
			uiRoot = self.itemGrid_.gameObject
		})

		icon:setChoose(isAwarded)
	end

	self.aawrdBtnRed_:SetActive(false)

	if xyd.models.growthDiary:checkCanAward(self.chapter_) and not isAwarded then
		self.awardBtnSprite_.color = Color.New2(4294967295.0)
		self.awardBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		self.awardBtn_:GetComponent(typeof(UIButtonScale)).enabled = true
		self.awardBtnLabel_.text = __("GROWTH_DIARY_TEXT12")
		self.awardBtnLabel_.color = Color.New2(4278124287.0)
		self.awardBtnLabel_.effectStyle = UILabel.Effect.Outline8
		self.awardBtnLabel_.effectColor = Color.New2(1012112383)

		self.awardBtnMask_:SetActive(false)
		self.aawrdBtnRed_:SetActive(true)
	elseif not isAwarded and not xyd.models.growthDiary:checkCanAward(self.chapter_) then
		self.awardBtnLabel_.text = __("GROWTH_DIARY_TEXT12")
		self.awardBtnSprite_.color = Color.New2(4294967295.0)
		self.awardBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		self.awardBtn_:GetComponent(typeof(UIButtonScale)).enabled = false
		self.awardBtnLabel_.color = Color.New2(4278124287.0)
		self.awardBtnLabel_.effectStyle = UILabel.Effect.Outline8
		self.awardBtnLabel_.effectColor = Color.New2(1012112383)

		self.awardBtnMask_:SetActive(true)
	else
		self.awardBtnSprite_.color = Color.New2(255)
		self.awardBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		self.awardBtn_:GetComponent(typeof(UIButtonScale)).enabled = false
		self.awardBtnLabel_.text = __("GROWTH_DIARY_TEXT11")
		self.awardBtnLabel_.color = Color.New2(4294967295.0)
		self.awardBtnLabel_.effectStyle = UILabel.Effect.Outline8
		self.awardBtnLabel_.effectColor = Color.New2(1414812927)

		self.awardBtnMask_:SetActive(false)
	end

	if not isUnlock then
		self.awardBtnLabel_.text = __("GROWTH_DIARY_TEXT10")
	end

	if isAwarded then
		self.awardBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end

	self.itemGrid_:Reposition()
end

function GrowthDiaryWindow:onGetMissionList()
	self:updateTopAward()
	self:updateMissionList()
	self:initProgress()
end

function GrowthDiaryWindow:updateMissionList()
	local ids = xyd.tables.grouthDiaryMissionTable:getIDsByChapter(self.chapter_)

	table.sort(ids)

	for index, id in ipairs(ids) do
		if not self.missionList_[index] then
			local uiRoot = NGUITools.AddChild(self.misssionGrid.gameObject, self.missionItem)

			uiRoot:SetActive(true)

			self.missionList_[index] = MissionItem.new(uiRoot, self)
		end

		local missionData = xyd.models.growthDiary:getMissionInfo(id)

		self.missionList_[index]:setInfo(missionData)
	end

	self.misssionGrid:Reposition()
end

return GrowthDiaryWindow
