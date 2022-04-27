local ActivityCourseResearch = class("ActivityCourseResearch", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")

function ActivityCourseResearch:ctor(parentGO, params, parent)
	ActivityCourseResearch.super.ctor(self, parentGO, params, parent)
end

function ActivityCourseResearch:getPrefabPath()
	return "Prefabs/Windows/activity/activity_course_research"
end

function ActivityCourseResearch:initUI()
	self:getUIComponent()
	ActivityCourseResearch.super.initUI(self)
	self:register()
	self:layout()
end

function ActivityCourseResearch:getUIComponent()
	local goTrans = self.go.transform
	self.Bg_ = goTrans:NodeByName("bg")
	self.titleImg_ = goTrans:ComponentByName("titleImg", typeof(UISprite))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.awardBtn = goTrans:NodeByName("awardBtn").gameObject
	self.costGroup = goTrans:NodeByName("costGroup").gameObject
	self.costLabel = self.costGroup:ComponentByName("label", typeof(UILabel))
	self.costBtn = self.costGroup:NodeByName("btn").gameObject
	self.model = goTrans:NodeByName("model").gameObject
	self.touchField = goTrans:NodeByName("touchField").gameObject
	self.bottomGroup = goTrans:NodeByName("bottomGroup")
	self.summonBtnOne = self.bottomGroup:NodeByName("summonBtnOne").gameObject
	self.summonBtnOneLabel1 = self.summonBtnOne:ComponentByName("labelTips", typeof(UILabel))
	self.summonBtnOneLabel2 = self.summonBtnOne:ComponentByName("labelNum", typeof(UILabel))
	self.summonBtnTen = self.bottomGroup:NodeByName("summonBtnTen").gameObject
	self.summonBtnTenLabel1 = self.summonBtnTen:ComponentByName("labelTips", typeof(UILabel))
	self.summonBtnTenLabel2 = self.summonBtnTen:ComponentByName("labelNum", typeof(UILabel))
	self.progressBar = self.bottomGroup:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressDesc = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.bottomLabel = self.bottomGroup:ComponentByName("label", typeof(UILabel))
	self.awardGroup = goTrans:NodeByName("awardGroup")
	self.awardLabel = self.awardGroup:ComponentByName("label", typeof(UILabel))
	self.awardTouchField = self.awardGroup:NodeByName("touchField").gameObject
	self.awardRedMark = self.awardGroup:NodeByName("redMark").gameObject
	self.awardsLayout = self.awardGroup:ComponentByName("awards", typeof(UILayout))

	for i = 1, 4 do
		self["awardIcon" .. i] = self.awardGroup:NodeByName("awards/icon" .. i).gameObject
	end

	for i = 1, 3 do
		self["awardLabel" .. i] = self.awardGroup:ComponentByName("awards/label" .. i, typeof(UILabel))
	end
end

function ActivityCourseResearch:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.COURSE_RESEARCH_GACHA, handler(self, self.onGetGacha))
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:updateItemNum()
	end)

	UIEventListener.Get(self.costBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.COURSE_COIN,
			activityID = self.id
		})
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_COURSE_LEARNING_HELP"
		})
	end

	UIEventListener.Get(self.awardBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_course_research_award_window", {
			cur_select_ = 1,
			activityID = self.id
		})
	end

	UIEventListener.Get(self.summonBtnOne).onClick = function ()
		self:gacha(1)
	end

	UIEventListener.Get(self.summonBtnTen).onClick = function ()
		self:gacha(10)
	end

	UIEventListener.Get(self.touchField).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_course_research_award_window", {
			cur_select_ = 2,
			activityID = self.id
		})
	end

	UIEventListener.Get(self.awardTouchField).onClick = function ()
		if self:getTrueProgress() < 1 then
			xyd.WindowManager.get():openWindow("activity_course_research_award_window", {
				cur_select_ = 1,
				activityID = self.id
			})
		else
			local id = self.activityData.detail.round + 1 >= 7 and 7 or self.activityData.detail.round + 1

			xyd.WindowManager.get():openWindow("activity_course_research_select_window", {
				awards = xyd.tables.activityCourseLearningTable:getAwards(id),
				roundID = id,
				activityID = self.id
			})
		end
	end
end

function ActivityCourseResearch:getTrueProgress()
	local progress = self.activityData.detail.progress

	if progress < xyd.tables.activityCourseLearningTable:getLastLevel() then
		return math.floor((progress - math.min(self.activityData.detail.round, xyd.tables.activityCourseLearningTable:getLastLevel() - 1)) * 1000 + 0.5) / 1000
	else
		return 1
	end
end

function ActivityCourseResearch:onAward(event)
	if event.data.activity_id == self.id then
		local data = require("cjson").decode(event.data.detail)
		local item = {
			item_id = data.items.item_id,
			item_num = data.items.item_num
		}

		xyd.models.itemFloatModel:pushNewItems({
			data.items
		})

		self.activityData.detail.progress = data.info.progress
		self.activityData.detail.round = data.info.round
		self.activityData.detail.awards = data.info.awards

		self:updateProgress()
		xyd.models.activity:updateRedMarkCount(self.id, function ()
		end)
	end
end

function ActivityCourseResearch:gacha(num, isRepeat)
	self.gachaNum = num
	local hasNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.COURSE_COIN)

	if self:getTrueProgress() >= 1 then
		xyd.showToast(__("ACTIVITY_COURSE_LEARNING_TEXT08"))

		return
	end

	self.reawardProgressLastValue = math.min(self:getTrueProgress(), 1)

	local function summonLimitPartner(num)
		local msg = messages_pb.course_research_gacha_req()
		msg.activity_id = self.id
		msg.num = num

		xyd.Backend.get():request(xyd.mid.COURSE_RESEARCH_GACHA, msg)
	end

	if num == 1 then
		local cost = xyd.tables.miscTable:split2Cost("activity_course_learning_cost", "value", "#")

		if cost[2] <= hasNum then
			summonLimitPartner(1)
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return false
		end
	elseif num == 10 then
		local cost = xyd.tables.miscTable:split2Cost("activity_course_learning_cost", "value", "#")

		if hasNum >= cost[2] * 10 then
			summonLimitPartner(10)
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return false
		end
	end
end

function ActivityCourseResearch:layout()
	xyd.setUISpriteAsync(self.titleImg_, nil, "activity_course_research_" .. xyd.Global.lang)

	if xyd.Global.lang == "ko_kr" then
		self.titleImg_:Y(-75)
	end

	self:updateItemNum()
	self:updateProgress()

	self.effect = xyd.Spine.new(self.model)

	self.effect:setInfo("course_learning_book", function ()
		self.effect:play("texiao01", 0, 1)
	end)

	self.summonBtnOneLabel1.text = __("ACTIVITY_COURSE_LEARNING_TEXT02", 1)
	self.summonBtnOneLabel2.text = xyd.tables.miscTable:split2Cost("activity_course_learning_cost", "value", "#")[2]
	self.summonBtnTenLabel1.text = __("ACTIVITY_COURSE_LEARNING_TEXT02", 10)
	self.summonBtnTenLabel2.text = xyd.tables.miscTable:split2Cost("activity_course_learning_cost", "value", "#")[2] * 10

	for i = 1, 3 do
		self["awardLabel" .. i].text = __("ACTIVITY_COURSE_LEARNING_TEXT05")
	end
end

function ActivityCourseResearch:updateItemNum()
	self.costLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.COURSE_COIN)
end

function ActivityCourseResearch:updateProgress()
	self.progressBar.value = math.min(self:getTrueProgress(), 1)
	self.progressDesc.text = string.format("%0.1f", math.min(self:getTrueProgress() * 100, 100)) .. "%"
	local str = __("ACTIVITY_COURSE_LEARNING_TEXT01", self.activityData.detail.round + 1)
	local str = string.gsub(str, "0x(%w+)", "%1")
	local str = string.gsub(str, " size=(%w+)", "][size=%1")
	self.bottomLabel.text = str

	if self:getTrueProgress() < 1 then
		self.awardLabel.text = __("ACTIVITY_COURSE_LEARNING_TEXT03")

		if self.awardLabel.height > 22 then
			self.awardLabel:Y(72)
		else
			self.awardLabel:Y(68)
		end

		self.awardRedMark:SetActive(false)
	else
		self.awardLabel.text = __("ACTIVITY_COURSE_LEARNING_TEXT04")

		if self.awardLabel.height > 22 then
			self.awardLabel:Y(72)
		else
			self.awardLabel:Y(68)
		end

		self.awardRedMark:SetActive(true)
	end

	local id = self.activityData.detail.round + 1 >= 7 and 7 or self.activityData.detail.round + 1
	local awards = xyd.tables.activityCourseLearningTable:getAwards(id)
	self.icons = {}

	for i = 1, 4 do
		NGUITools.DestroyChildren(self["awardIcon" .. i].transform)

		if i <= #awards then
			local icon = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.7962962962962963,
				showGetWays = false,
				itemID = awards[i][1],
				num = awards[i][2],
				uiRoot = self["awardIcon" .. i],
				dragScrollView = self.scrollerView,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			table.insert(self.icons, icon)
		else
			self["awardIcon" .. i]:SetActive(false)
			self["awardLabel" .. i - 1]:SetActive(false)
		end
	end

	self.awardsLayout:Reposition()
end

function ActivityCourseResearch:onGetGacha(event)
	local showGolden = false

	for i = 1, #event.data.items do
		self.activityData.detail.progress = self.activityData.detail.progress + math.floor(event.data.progress[i] * 1000 + 0.5) / 1000

		if event.data.progress[i] == 1 then
			showGolden = true
		end
	end

	local function func()
		local data = {}

		for i = 1, #event.data.items do
			local color = nil

			if math.floor(event.data.progress[i] * 100 * 100 + 0.5) / 100 > 1 then
				color = Color.New2(4579583)
			elseif math.floor(event.data.progress[i] * 100 * 100 + 0.5) / 100 < 1 then
				color = Color.New2(775772415)
			else
				color = Color.New2(6799359)
			end

			table.insert(data, {
				item_id = event.data.items[i].item_id,
				item_num = event.data.items[i].item_num,
				belowText = math.floor(event.data.progress[i] * 100 * 100 + 0.5) / 100 .. "%",
				belowTextColor = color
			})
		end

		self:updateProgress()

		local cost = xyd.tables.miscTable:split2Cost("activity_course_learning_cost", "value", "#")
		local str = __("ACTIVITY_COURSE_LEARNING_TEXT01", self.activityData.detail.round + 1)
		local str = string.gsub(str, "0x(%w+)", "%1")
		local str = string.gsub(str, " size=(%w+)", "][size=%1")

		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			wnd_type = 4,
			data = data,
			cost = {
				cost[1],
				cost[2] * self.gachaNum
			},
			buyCallback = function (cost)
				self:gacha(self.gachaNum)

				self.skip = true
			end,
			btnLabelText = self.gachaNum == 1 and "GAMBLE_BUY_ONE" or "GAMBLE_BUY_TEN",
			progressValue = math.min(self:getTrueProgress(), 1),
			progressLastValue = self.reawardProgressLastValue,
			progressText = string.format("%0.1f", math.min(self:getTrueProgress() * 100, 100)) .. "%",
			progressLastText = string.format("%0.1f", self.reawardProgressLastValue * 100) .. "%",
			progressRoundText = str,
			showGolden = showGolden
		}, function ()
			self.summonBtnOne:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			self.summonBtnTen:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			self.helpBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			self.awardBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			self.costBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			self.touchField:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			self.awardTouchField:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			for i = 1, #self.icons do
				self.icons[i]:setNoClick(false)
			end
		end)

		self.skip = false

		xyd.models.activity:updateRedMarkCount(self.id, function ()
		end)
	end

	if not self.skip then
		self.summonBtnOne:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.summonBtnTen:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.helpBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.awardBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.costBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.touchField:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.awardTouchField:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		for i = 1, #self.icons do
			self.icons[i]:setNoClick(true)
		end

		xyd.MainController.get():removeEscListener()
		self.effect:play("texiao02", 1, 1, function ()
			func()
			self.effect:play("texiao01", 0, 1)
			xyd.MainController.get():addEscListener()
		end)
	else
		func()
	end
end

function ActivityCourseResearch:resizeToParent()
	ActivityCourseResearch.super.resizeToParent(self)

	local height = self.go:GetComponent(typeof(UIWidget)).height

	if xyd.Global.lang == "zh_tw" then
		self.go:Y(-10)
		self.Bg_:Y(-515)
	end

	self.costGroup:Y(-135 - 0.174 * (height - 869))
	self.bottomGroup:Y(-869 - 0.663 * (height - 869))
	self.awardGroup:Y(-780 - 0.674 * (height - 869))
	self.model:Y(-430 - 0.4 * (height - 869))
end

return ActivityCourseResearch
