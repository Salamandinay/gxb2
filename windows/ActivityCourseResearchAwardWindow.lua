local ActivityCourseResearchAwardWindow = class("ActivityCourseResearchAwardWindow", import(".BaseWindow"))
local CommonTabBar = import("app.common.ui.CommonTabBar")
local ActivityCourseResearchAwardItem1 = class("ActivityCourseResearchAwardItem1", import("app.components.CopyComponent"))
local ActivityCourseResearchAwardItem2 = class("ActivityCourseResearchAwardItem2", import("app.components.CopyComponent"))
local cjson = require("cjson")

function ActivityCourseResearchAwardWindow:ctor(name, params)
	ActivityCourseResearchAwardWindow.super.ctor(self, name, params)

	self.cur_select_ = params.cur_select_
	self.activityDetail = xyd.models.activity:getActivity(params.activityID).detail
	self.round = self.activityDetail.round
end

function ActivityCourseResearchAwardWindow:initWindow()
	ActivityCourseResearchAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:register()
	self:initGroup1()
	self:initGroup2()
	self:initNav()

	if self.round then
		if self.round < 3 then
			self.scrollView1:MoveRelative(Vector3(0, 108 * self.round, 0))
		else
			self.scrollView1:MoveRelative(Vector3(0, 216, 0))
		end
	end
end

function ActivityCourseResearchAwardWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.winTitle_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.navGroup_ = winTrans:NodeByName("navGroup").gameObject
	self.group1 = winTrans:NodeByName("group1").gameObject
	self.scrollView1 = self.group1:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid1 = self.scrollView1:ComponentByName("grid", typeof(UIGrid))
	self.group1Label = self.group1:ComponentByName("label", typeof(UILabel))
	self.group2 = winTrans:NodeByName("group2").gameObject
	self.textGroup = self.group2:NodeByName("textGroup").gameObject
	self.scrollView2 = self.textGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.descLabel = self.scrollView2:ComponentByName("label", typeof(UILabel))
	self.textGroupTitle = self.textGroup:ComponentByName("label", typeof(UILabel))
	self.iconGroup = self.group2:NodeByName("iconGroup").gameObject
	self.scrollView3 = self.iconGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid3 = self.scrollView3:ComponentByName("grid", typeof(UIGrid))
	self.iconGroupTitle = self.iconGroup:ComponentByName("label", typeof(UILabel))
	self.itemCell1 = winTrans:NodeByName("itemCell1").gameObject
	self.itemCell2 = winTrans:NodeByName("itemCell2").gameObject
end

function ActivityCourseResearchAwardWindow:register()
	ActivityCourseResearchAwardWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityCourseResearchAwardWindow:initNav()
	local chosen = {
		color = Color.New2(4294967295.0),
		effectColor = Color.New2(1012112383)
	}
	local unchosen = {
		color = Color.New2(960513791),
		effectColor = Color.New2(4294967295.0)
	}
	local colorParams = {
		chosen = chosen,
		unchosen = unchosen
	}
	self.tab_ = CommonTabBar.new(self.navGroup_, 2, function (index)
		self.cur_select_ = index

		self:updateLayout()
	end, nil, colorParams)
	local tableLabels = {
		__("ACTIVITY_COURSE_LEARNING_TEXT06"),
		__("ACTIVITY_COURSE_LEARNING_TEXT07")
	}

	self.tab_:setTexts(tableLabels)
	self.tab_:setTabActive(self.cur_select_, true)

	self.winTitle_.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")

	self:updateNavRed()
end

function ActivityCourseResearchAwardWindow:updateNavRed()
	self.tab_:getRedMark(2):SetActive(false)
	self.tab_:getRedMark(1):SetActive(false)
end

function ActivityCourseResearchAwardWindow:updateLayout()
	self.group1.gameObject:SetActive(self.cur_select_ == 1)
	self.group2.gameObject:SetActive(self.cur_select_ == 2)
end

function ActivityCourseResearchAwardWindow:initGroup1()
	self.group1Label.text = __("ACTIVITY_COURSE_LEARNING_TEXT03")
	local ids = xyd.tables.activityCourseLearningTable:getIds()
	self.items1 = {}

	for _, id in ipairs(ids) do
		local params = {
			id = id,
			awards = xyd.tables.activityCourseLearningTable:getAwards(id),
			is_rewarded = self.activityDetail.awards[tonumber(id)]
		}

		if not self.items1[id] then
			local goRoot = NGUITools.AddChild(self.grid1.gameObject, self.itemCell1)
			self.items1[id] = ActivityCourseResearchAwardItem1.new(goRoot, self)
		end

		self.items1[id]:setInfo(params)
	end

	self.grid1:Reposition()
	self.scrollView1:ResetPosition()
	self.itemCell1:SetActive(false)
end

function ActivityCourseResearchAwardWindow:initGroup2()
	self.descLabel.text = __("ACTIVITY_COURSE_LEARNING_TEXT14")
	self.textGroupTitle.text = __("ACTIVITY_COURSE_LEARNING_TEXT13")
	self.iconGroupTitle.text = __("ACTIVITY_COURSE_LEARNING_TEXT15")
	local ids = xyd.tables.dropboxShowTable:getIdsByBoxId(xyd.tables.miscTable:getNumber("activity_course_learning_award1", "value")).list
	local weight = xyd.tables.dropboxShowTable:getIdsByBoxId(xyd.tables.miscTable:getNumber("activity_course_learning_award1", "value")).all_weight
	self.items2 = {}

	table.sort(ids)

	for _, id in ipairs(ids) do
		local params = {
			id = id,
			award = xyd.tables.dropboxShowTable:getItem(id),
			probobility = xyd.tables.dropboxShowTable:getWeight(id) / weight
		}

		if not self.items2[id] then
			local goRoot = NGUITools.AddChild(self.grid3.gameObject, self.itemCell2)
			self.items2[id] = ActivityCourseResearchAwardItem2.new(goRoot, self)
		end

		self.items2[id]:setInfo(params)
	end

	self.grid3:Reposition()
	self.scrollView3:ResetPosition()
	self.itemCell2:SetActive(false)
end

function ActivityCourseResearchAwardItem1:ctor(parentGo, parent)
	self.parent_ = parent

	ActivityCourseResearchAwardItem1.super.ctor(self, parentGo)
end

function ActivityCourseResearchAwardItem1:initUI()
	ActivityCourseResearchAwardItem1.super.initUI(self)

	local goTrans = self.go.transform
	self.awardGroup = goTrans:ComponentByName("awardGroup", typeof(UILayout))

	for i = 1, 4 do
		self["icon" .. i] = self.awardGroup:NodeByName("icon" .. i).gameObject
	end

	for i = 1, 3 do
		self["label" .. i] = self.awardGroup:ComponentByName("label" .. i, typeof(UILabel))
		self["label" .. i].text = __("ACTIVITY_COURSE_LEARNING_TEXT05")
	end

	self.label = goTrans:ComponentByName("label", typeof(UILabel))
end

function ActivityCourseResearchAwardItem1:setInfo(info)
	for i = 1, 4 do
		if info.awards[i] then
			NGUITools.DestroyChildren(self["icon" .. i].transform)

			local icon = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.6481481481481481,
				itemID = info.awards[i][1],
				num = info.awards[i][2],
				uiRoot = self["icon" .. i],
				dragScrollView = self.parent_.scrollView1,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			if i == tonumber(info.is_rewarded) then
				icon:setChoose(true)
			end
		else
			self["icon" .. i]:SetActive(false)
			self["label" .. i - 1]:SetActive(false)
		end
	end

	self.awardGroup:Reposition()

	if #info.awards == 4 then
		self.awardGroup:X(95)
	elseif #info.awards == 3 then
		self.awardGroup:X(149)
	elseif #info.awards == 2 then
		self.awardGroup:X(202)
	elseif #info.awards == 1 then
		self.awardGroup:X(256)
	end

	if tonumber(info.id) == xyd.tables.activityCourseLearningTable:getLastLevel() then
		self.label.text = __("ACTIVITY_COURSE_LEARNING_TEXT12", info.id)
	else
		self.label.text = __("ACTIVITY_COURSE_LEARNING_TEXT11", info.id)
	end
end

function ActivityCourseResearchAwardItem2:ctor(parentGo, parent)
	self.parent_ = parent

	ActivityCourseResearchAwardItem2.super.ctor(self, parentGo)
end

function ActivityCourseResearchAwardItem2:initUI()
	ActivityCourseResearchAwardItem2.super.initUI(self)

	local goTrans = self.go.transform
	self.icon = goTrans:NodeByName("icon").gameObject
	self.label = goTrans:ComponentByName("label", typeof(UILabel))
end

function ActivityCourseResearchAwardItem2:setInfo(info)
	NGUITools.DestroyChildren(self.icon.transform)

	local icon = xyd.getItemIcon({
		show_has_num = true,
		scale = 1,
		itemID = info.award[1],
		num = info.award[2],
		uiRoot = self.icon,
		dragScrollView = self.parent_.scrollView3,
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})
	self.label.text = info.probobility * 100 .. "%"
end

return ActivityCourseResearchAwardWindow
