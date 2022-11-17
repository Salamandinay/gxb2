local ActivityContent = import(".ActivityContent")
local ActivityAltarCharge = class("ActivityAltarCharge", ActivityContent)
local BottleItem = class("BottleItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local RomaList = {
	"Ⅰ",
	"Ⅱ",
	"Ⅲ",
	"Ⅳ",
	"Ⅴ"
}

function BottleItem:ctor(go, parent, i)
	self.parent_ = parent
	self.index_ = i

	BottleItem.super.ctor(self, go)
end

function BottleItem:initUI()
	BottleItem.super.initUI(self)
	self:getUIComponent()
	self:layout()
end

function BottleItem:getUIComponent()
	local goTrans = self.go.transform
	self.progressBar = goTrans:GetComponent(typeof(UIProgressBar))
	self.bottleItemImg = goTrans:ComponentByName("bottleImg", typeof(UISprite))
	self.bottleItemValueImg = goTrans:ComponentByName("valueImg", typeof(UISprite))
	self.bottleItemUpImg = goTrans:ComponentByName("upImg", typeof(UISprite))
	self.bottleItemShowImg = goTrans:ComponentByName("showImg", typeof(UISprite))
end

function BottleItem:onRegister()
	UIEventListener.Get(self.go).onClick = function ()
		self.parent_.centerOn_:CenterOn(self.go.transform)
	end
end

function BottleItem:layout()
	local nowStage = self.parent_.activityData:getNowStage()
	local preNum = xyd.tables.activityStarAltarCostTable:getNum(self.index_ - 1) or 0
	local nowNum = xyd.tables.activityStarAltarCostTable:getNum(self.index_)
	local posYlist1 = {
		-80,
		-88,
		-75,
		-72,
		-64
	}
	local posYlist2 = {
		-54,
		-38,
		-46.5,
		-36,
		-41
	}
	local valueList = {
		0.5,
		0.6,
		0.5,
		0.5,
		0.4
	}

	xyd.setUISpriteAsync(self.bottleItemImg, nil, "star_bottle_big_" .. self.index_ .. "_1", nil, , true)
	xyd.setUISpriteAsync(self.bottleItemValueImg, nil, "star_bottle_big_" .. self.index_ .. "_2", nil, , true)
	xyd.setUISpriteAsync(self.bottleItemUpImg, nil, "star_bottle_big_" .. self.index_ .. "_3", nil, , true)

	local value = self.parent_.activityData:getNowValue()

	if nowStage < self.index_ then
		self.progressBar.value = 0

		self.bottleItemShowImg.gameObject:SetActive(false)
	elseif self.index_ < nowStage then
		self.progressBar.value = 1

		self.bottleItemShowImg.gameObject:SetActive(false)
	else
		local progressValue = (value - preNum) / (nowNum - preNum)

		if progressValue < 0.25 then
			self.progressBar.value = 0

			self.bottleItemShowImg.gameObject:SetActive(false)
		elseif progressValue >= 0.25 and progressValue < 0.5 then
			self.progressBar.value = 0.25

			self.bottleItemShowImg.gameObject:SetActive(true)
			xyd.setUISpriteAsync(self.bottleItemShowImg, nil, "star_bottle_big_" .. self.index_ .. "_4", nil, , true)
			self.bottleItemShowImg.transform:Y(posYlist1[self.index_])
		elseif progressValue >= 0.5 and progressValue < 1 then
			self.progressBar.value = valueList[self.index_]

			self.bottleItemShowImg.gameObject:SetActive(true)
			xyd.setUISpriteAsync(self.bottleItemShowImg, nil, "star_bottle_big_" .. self.index_ .. "_5", nil, , true)

			if self.index_ == 5 then
				self.bottleItemShowImg.transform:X(4.1)
			end

			self.bottleItemShowImg.transform:Y(posYlist2[self.index_])
		else
			self.progressBar.value = 1

			self.bottleItemShowImg.gameObject:SetActive(false)
		end
	end
end

function ActivityAltarCharge:ctor(parentGO, params)
	ActivityAltarCharge.super.ctor(self, parentGO, params)
end

function ActivityAltarCharge:initUI()
	ActivityAltarCharge.super.initUI(self)

	self.awardItemList_ = {}
	self.cur_center_ = self.activityData:getNowStage()

	self:getUIComponent()
	self:layout()
	self:updatePage()
	self:initBottleList()
	self:updateAwardList()
	self:updateRedPoint()
end

function ActivityAltarCharge:updatePage()
	self.arrow_left_:SetActive(self.cur_center_ > 1)
	self.arrow_right_:SetActive(self.cur_center_ < 5)
end

function ActivityAltarCharge:onRegister()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_STAR_ALTAR_GAMBLE_HELP"
		})
	end

	UIEventListener.Get(self.arrow_left_).onClick = function ()
		self.centerOn_:CenterOn(self.bottleItemList_[self.cur_center_ - 1].go.transform)
	end

	UIEventListener.Get(self.arrow_right_).onClick = function ()
		self.centerOn_:CenterOn(self.bottleItemList_[self.cur_center_ + 1].go.transform)
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_START_ALTAR_CHARGE, function ()
			xyd.db.misc:setValue({
				key = "star_altar_giftbag_click_time",
				value = xyd.getServerTime()
			})
			self:updateRedPoint()
			xyd.WindowManager.get():openWindow("activity_star_charge_window", {
				type = 2
			})
		end)
	end

	UIEventListener.Get(self.jumpBtn_).onClick = function ()
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_START_ALTAR_CHARGE, function ()
			xyd.db.misc:setValue({
				key = "star_altar_jump_click_time",
				value = xyd.getServerTime()
			})
			xyd.goWay(213, nil, function ()
				xyd.WindowManager.get():closeWindow("activity_window")
			end)
		end)
	end
end

function ActivityAltarCharge:getPrefabPath()
	return "Prefabs/Windows/activity/activity_star_charge"
end

function ActivityAltarCharge:getUIComponent()
	local goTrans = self.go.transform
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.awardBtn_ = goTrans:NodeByName("awardBtn").gameObject
	self.awardBtnLabel_ = goTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.awardBtnRed_ = goTrans:NodeByName("awardBtn/redPoint").gameObject
	self.timeGroup_ = goTrans:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = goTrans:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel_ = goTrans:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.arrow_left_ = goTrans:NodeByName("page_guide/arrow_left").gameObject
	self.arrow_right_ = goTrans:NodeByName("page_guide/arrow_right").gameObject
	self.bottleItem = goTrans:NodeByName("bottleItem").gameObject
	self.scrollView = goTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid = goTrans:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.centerOn_ = goTrans:ComponentByName("scrollView/grid", typeof(UICenterOnChild))
	self.centerOn_.onCenter = handler(self, self.onCenter)
	self.stageGroup_ = goTrans:NodeByName("stageGroup").transform

	for i = 1, 4 do
		self["stageLine" .. i] = self.stageGroup_:ComponentByName("stageNameGroup/line" .. i, typeof(UISprite))
	end

	for i = 1, 5 do
		self["nameImg" .. i] = self.stageGroup_:ComponentByName("stageNameGroup/nameItem" .. i, typeof(UISprite))
		self["nameLabel" .. i] = self.stageGroup_:ComponentByName("stageNameGroup/nameItem" .. i .. "/nameLabel", typeof(UILabel))
		self["smallBottle" .. i] = self.stageGroup_:ComponentByName("bottleGroup/bollte" .. i, typeof(UISprite))
		self["smallBottleSelect" .. i] = self.stageGroup_:NodeByName("bottleGroup/bollte" .. i .. "/select").gameObject
		self["smallBottleName" .. i] = self.stageGroup_:ComponentByName("bottleGroup/bollte" .. i .. "/labelName", typeof(UILabel))
	end

	self.bottomImg_ = goTrans:NodeByName("bottomImg").gameObject
	self.tipsLabel_ = goTrans:ComponentByName("bottomImg/tipsLabel", typeof(UILabel))
	self.awardGroup_ = goTrans:ComponentByName("bottomImg/awardGroup", typeof(UILayout))
	self.progressBar_ = goTrans:ComponentByName("bottomImg/progressBar", typeof(UIProgressBar))
	self.progressValueLabel_ = goTrans:ComponentByName("bottomImg/progressBar/valueLabel", typeof(UILabel))
	self.jumpBtn_ = goTrans:NodeByName("bottomImg/jumpBtn").gameObject
	self.jumpBtnLabel_ = goTrans:ComponentByName("bottomImg/jumpBtn/label", typeof(UILabel))
	self.jumpBtnRed_ = goTrans:NodeByName("bottomImg/jumpBtn/redPoint").gameObject

	self:resizePosY(self.bottomImg_, -634, -800)
	self:resizePosY(self.stageGroup_, 0, -60)
end

function ActivityAltarCharge:layout()
	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_star_altar_charge_logo_" .. xyd.Global.lang)

	self.awardBtnLabel_.text = __("ACTIVITY_STAR_ALTAR_GAMBLE_BUTTON02")

	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel_.text = __("END")
	self.jumpBtnLabel_.text = __("ACTIVITY_STAR_ALTAR_GAMBLE_BUTTON01")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	self.timeGroup_:Reposition()

	self.tipsLabel_.text = __("ACTIVITY_STAR_ALTAR_GAMBLE_TEXT02")
	local nowStage = self.activityData:getNowStage()

	for i = 1, 5 do
		self["smallBottleName" .. i].text = __("ACTIVITY_STAR_ALTAR_GAMBLE_TEXT01")
		self["nameLabel" .. i].text = RomaList[i]

		if i < nowStage then
			xyd.setUISpriteAsync(self["smallBottle" .. i], nil, "star_bottle_" .. i .. "_4")
			self["smallBottleSelect" .. i]:SetActive(false)
			xyd.setUISpriteAsync(self["nameImg" .. i], nil, "activity_star_altar_charge_point3")
		elseif nowStage < i then
			xyd.setUISpriteAsync(self["nameImg" .. i], nil, "activity_star_altar_charge_point2")
			xyd.setUISpriteAsync(self["smallBottle" .. i], nil, "star_bottle_" .. i .. "_1")
			self["smallBottleSelect" .. i]:SetActive(false)

			self["nameLabel" .. i].effectColor = Color.New2(1820035071)
		elseif i == nowStage then
			xyd.setUISpriteAsync(self["nameImg" .. i], nil, "activity_star_altar_charge_point1")

			local value = self.activityData:getNowValue()
			local preNum = xyd.tables.activityStarAltarCostTable:getNum(i - 1) or 0
			local nowNum = xyd.tables.activityStarAltarCostTable:getNum(i)

			if (value - preNum) / (nowNum - preNum) < 0.25 then
				xyd.setUISpriteAsync(self["smallBottle" .. i], nil, "star_bottle_" .. i .. "_1")
			elseif (value - preNum) / (nowNum - preNum) >= 0.25 and (value - preNum) / (nowNum - preNum) < 0.5 then
				xyd.setUISpriteAsync(self["smallBottle" .. i], nil, "star_bottle_" .. i .. "_2")
			elseif (value - preNum) / (nowNum - preNum) >= 0.5 and (value - preNum) / (nowNum - preNum) < 1 then
				xyd.setUISpriteAsync(self["smallBottle" .. i], nil, "star_bottle_" .. i .. "_3")
			else
				xyd.setUISpriteAsync(self["smallBottle" .. i], nil, "star_bottle_" .. i .. "_4")
			end

			self["smallBottleSelect" .. i]:SetActive(true)
		end
	end

	for i = 1, 4 do
		if i < nowStage then
			xyd.setUISpriteAsync(self["stageLine" .. i], nil, "activity_star_altar_charge_xyp_line2", nil, , true)
		else
			xyd.setUISpriteAsync(self["stageLine" .. i], nil, "activity_star_altar_charge_xyp_line1", nil, , true)
		end
	end
end

function ActivityAltarCharge:initBottleList()
	self.bottleItemList_ = {}

	for i = 1, 5 do
		local newRoot = NGUITools.AddChild(self.grid.gameObject, self.bottleItem)

		newRoot:SetActive(true)

		newRoot.name = i
		self.bottleItemList_[i] = BottleItem.new(newRoot, self, i)

		self.grid:Reposition()
	end

	self.scrollView:MoveRelative(Vector3(-(self.activityData:getNowStage() - 1) * 420, 0, 0))
	self:waitForTime(0.5, function ()
		self.centerOn_.enabled = true

		self.centerOn_:CenterOn(self.bottleItemList_[self.activityData:getNowStage()].go.transform)
	end)
end

function ActivityAltarCharge:onCenter(target)
	if not target then
		return
	end

	local name = target.gameObject.name
	self.cur_center_ = tonumber(name)

	self:updatePage()
	self:updateAwardList()
end

function ActivityAltarCharge:updateAwardList()
	local value = self.activityData:getNowValue()
	local nowStage = self.activityData:getNowStage()
	local preNum = xyd.tables.activityStarAltarCostTable:getNum(self.cur_center_ - 1) or 0
	local nowNum = xyd.tables.activityStarAltarCostTable:getNum(self.cur_center_)
	self.progressValueLabel_.text = math.min(math.max(value - preNum, 0), nowNum - preNum) .. "/" .. nowNum - preNum
	self.progressBar_.value = (value - preNum) / (nowNum - preNum)
	local awards = xyd.tables.activityStarAltarCostTable:getAwards(self.cur_center_)

	for index, award in ipairs(awards) do
		if not self.awardItemList_[index] then
			self.awardItemList_[index] = xyd.getItemIcon({
				scale = 0.8333333333333334,
				uiRoot = self.awardGroup_.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.awardItemList_[index]:setInfo({
				scale = 0.8333333333333334,
				itemID = award[1],
				num = award[2]
			})
		end

		self.awardItemList_[index]:setChoose(self.cur_center_ < nowStage or (value - preNum) / (nowNum - preNum) >= 1 and nowStage == self.cur_center_)
	end

	self:waitForFrame(1, function ()
		self.awardGroup_:Reposition()
	end)
end

function ActivityAltarCharge:updateRedPoint()
	self.awardBtnRed_:SetActive(self.activityData:getAwardRed())
	self.jumpBtnRed_:SetActive(self.activityData:getJumpRed())
end

return ActivityAltarCharge
