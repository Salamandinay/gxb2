local BaseWindow = import(".BaseWindow")
local AcademyAssessmentAwardWindow = class("AcademyAssessmentAwardWindow", BaseWindow)
local ArenaAwardItem = class("ArenaAwardItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")

function AcademyAssessmentAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.cur_select_ = 0
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
end

function AcademyAssessmentAwardWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:layout()
end

function AcademyAssessmentAwardWindow:getUIComponent()
	local trans = self.window_.transform
	local groupAction = trans:NodeByName("groupAction").gameObject
	self.winName = groupAction:ComponentByName("e:Group/labelWinTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("e:Group/closeBtn").gameObject
	self.awardNode = groupAction:NodeByName("awardNode").gameObject
	self.upgroup = self.awardNode:NodeByName("upgroup").gameObject
	self.arena_award_item = self.upgroup:NodeByName("arena_award_item").gameObject
	self.labelRank = self.upgroup:ComponentByName("labelRank", typeof(UILabel))
	self.labelRankNum = self.upgroup:ComponentByName("labelRankNum", typeof(UILabel))
	self.labelTopRank = self.upgroup:ComponentByName("labelTopRank", typeof(UILabel))
	self.topRank = self.upgroup:ComponentByName("topRank", typeof(UILabel))
	self.labelNowAward = self.upgroup:ComponentByName("labelNowAward", typeof(UILabel))
	self.nowAward = self.upgroup:NodeByName("nowAward").gameObject
	self.awardItem1 = self.upgroup:NodeByName("nowAward/ns1:ItemIcon").gameObject
	self.awardItem2 = self.upgroup:NodeByName("nowAward/ns2:ItemIcon").gameObject
	self.labelDesc = self.awardNode:ComponentByName("labelDesc", typeof(UILabel))
	self.clock = self.awardNode:NodeByName("clock").gameObject
	self.ddl2Text = self.awardNode:ComponentByName("ddl2Text", typeof(UILabel))
	self.awardScroller = self.awardNode:NodeByName("awardScroller").gameObject
	self.awardScroller_scrollerView = self.awardNode:ComponentByName("awardScroller", typeof(UIScrollView))
	self.awardScroller_panel = self.awardNode:ComponentByName("awardScroller", typeof(UIPanel))
	self.awardContainer = self.awardNode:NodeByName("awardScroller/awardContainer").gameObject
	self.awardContainer_UILayout = self.awardNode:ComponentByName("awardScroller/awardContainer", typeof(UILayout))
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	self.winName.text = __("SETTLEMENT_AWARD")
	self.labelRank.text = tostring(__("NOW_SCORE"))

	if xyd.models.academyAssessment.selfScore or xyd.models.academyAssessment.selfScore == nil then
		self.labelRankNum.text = xyd.models.academyAssessment.selfScore or 0
	end

	self.labelNowAward.text = __("NOW_AWARD_ACCORDING_TO_SCORE")

	if xyd.Global.lang == "fr_fr" then
		self.labelNowAward.overflowMethod = UILabel.Overflow.ResizeFreely

		self.nowAward:X(50)
	end

	self.labelTopRank.text = tostring(__("TOP_SCORE"))
	self.labelDesc.text = __("PUT_OUT_AWARD_ACCORDING_TO_SCORE")

	self.labelTopRank.gameObject:SetActive(false)
	self.topRank.gameObject:SetActive(false)

	if xyd.models.academyAssessment:getIsNewSeason() and xyd.models.academyAssessment.seasonId > 1 and (xyd.models.academyAssessment.historyScore or xyd.models.academyAssessment.historyScore == nil) then
		self.labelTopRank.gameObject:SetActive(true)
		self.topRank.gameObject:SetActive(true)

		self.topRank.text = xyd.models.academyAssessment.historyScore or 0
	end
end

function AcademyAssessmentAwardWindow:layout()
	self:initAwardLayout()
end

function AcademyAssessmentAwardWindow:initAwardLayout()
	self.summonEffect_ = xyd.Spine.new(self.clock.gameObject)

	self.summonEffect_:setInfo("fx_ui_shizhong", function ()
		self.summonEffect_:setRenderTarget(self.clock:GetComponent(typeof(UITexture)), 1)
		self.summonEffect_:play("texiao1", 0)
		self:updateDDL1()
		self:layoutAward()
	end)
end

function AcademyAssessmentAwardWindow:layoutAward()
	NGUITools.DestroyChildren(self.nowAward.transform)
	NGUITools.DestroyChildren(self.awardContainer.transform)

	local curScroe = 0

	if xyd.models.academyAssessment.selfScore then
		curScroe = xyd.models.academyAssessment.selfScore
	end

	local awardId = xyd.models.academyAssessment:getAwardPointTable():getScoreId(curScroe)

	if awardId ~= -1 then
		local awardArr = xyd.models.academyAssessment:getAwardPointTable():getAward(awardId)

		for i in pairs(awardArr) do
			local item = awardArr[i]
			local icon = xyd.getItemIcon({
				isAddUIDragScrollView = true,
				hideText = true,
				isShowSelected = false,
				itemID = item[1],
				num = item[2],
				scale = Vector3(0.7, 0.7, 1),
				uiRoot = self.nowAward.gameObject
			})
		end
	end

	local a_t = xyd.models.academyAssessment:getAwardPointTable()

	for i in pairs(a_t:getIds()) do
		local awardItem = NGUITools.AddChild(self.awardContainer.gameObject, self.arena_award_item.gameObject)
		local item = ArenaAwardItem.new(awardItem)

		item:setInfo(i, "award", a_t)
	end

	self.awardContainer_UILayout:Reposition()
	self.arena_award_item:SetActive(false)
end

function AcademyAssessmentAwardWindow:updateDDL1()
	local startTime = xyd.models.academyAssessment.startTime
	local allTime = xyd.tables.miscTable:getNumber("school_practise_season_duration", "value")
	local showTime = xyd.tables.miscTable:getNumber("school_practise_display_duration", "value")
	local durationTime = startTime + allTime - showTime - xyd.getServerTime()

	if durationTime > 0 then
		self.setCountDownTime = CountDown.new(self.ddl2Text, {
			duration = durationTime,
			callback = handler(self, self.timeOver)
		})
	else
		self.ddl2Text.text = "00:00"
	end
end

function AcademyAssessmentAwardWindow:timeOver()
	self.ddl2Text.text = "00:00"
end

function ArenaAwardItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function ArenaAwardItem:getUIComponent()
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.imgRank = self.go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = self.go:ComponentByName("labelRank", typeof(UILabel))
	self.awardGroup = self.go:NodeByName("awardGroup")
	self.awardGroup_layout = self.go:ComponentByName("awardGroup", typeof(UILayout))
end

function ArenaAwardItem:setInfo(id, colName, table, notShowSpecial)
	table = table or xyd.models.academyAssessment:getAwardPointTable()

	self.imgRank:SetActive(false)
	self.labelRank:SetActive(true)

	self.labelRank.text = table:getPointText(id)

	NGUITools.DestroyChildren(self.awardGroup.transform)

	local awards = table:getAward(id)

	for i in pairs(awards) do
		local item = awards[i]
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			noClickSelected = true,
			hideText = true,
			isShowSelected = false,
			itemID = item[1],
			num = item[2],
			scale = Vector3(0.7, 0.7, 1),
			uiRoot = self.awardGroup.gameObject
		})
	end

	self.awardGroup_layout:Reposition()
end

return AcademyAssessmentAwardWindow
