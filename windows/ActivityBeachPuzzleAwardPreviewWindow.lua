local BaseWindow = import(".BaseWindow")
local ActivityBeachPuzzleAwardPreviewWindow = class("ActivityBeachPuzzleAwardPreviewWindow", BaseWindow)
local ActivityBeachPuzzleProbabilityAwardItem = class("ActivityBeachPuzzleProbabilityAwardItem")
local ActivityBeachPuzzleCumulationAwardItem = class("ActivityBeachPuzzleCumulationAwardItem")

function ActivityBeachPuzzleAwardPreviewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.round = params.round or 0
end

function ActivityBeachPuzzleAwardPreviewWindow:initWindow()
	self:getUIComponent()
	ActivityBeachPuzzleAwardPreviewWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityBeachPuzzleAwardPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local groupMain = groupAction:NodeByName("groupMain").gameObject
	self.scrollView = groupMain:ComponentByName("scroll_", typeof(UIScrollView))
	self.layout = self.scrollView:ComponentByName("layout", typeof(UILayout))
	self.probabilityGroup = self.layout:NodeByName("probabilityGroup").gameObject
	self.probabilityAwardItem = winTrans:NodeByName("probabilityAwardItem").gameObject
	self.cumulationGroup = self.layout:NodeByName("cumulationGroup").gameObject
	self.cumulationAwardItem = winTrans:NodeByName("cumulationAwardItem").gameObject
end

function ActivityBeachPuzzleAwardPreviewWindow:initUIComponent()
	self.labelTitle_.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")

	self:initProbabilityGroup()
	self:initCumulationGroup()
	self.layout:Reposition()
	self.scrollView:ResetPosition()
end

function ActivityBeachPuzzleAwardPreviewWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

function ActivityBeachPuzzleAwardPreviewWindow:initProbabilityGroup()
	local groupContent = self.probabilityGroup:NodeByName("groupContent").gameObject
	local labelTitle_ = groupContent:ComponentByName("labelTitle_", typeof(UILabel))
	local awardGroup = groupContent:NodeByName("awardGroup").gameObject
	labelTitle_.text = __("ACTIVITY_BEACH_PUZZLE_TEXT05")
	local dropboxID = xyd.tables.miscTable:getNumber("activity_beach_puzzle_dropbox", "value")
	local datas = xyd.tables.dropboxShowTable:getIdsByBoxId(dropboxID)

	table.sort(datas.list)

	for i in pairs(datas.list) do
		local award = xyd.tables.dropboxShowTable:getItem(datas.list[i])
		local weight = xyd.tables.dropboxShowTable:getWeight(datas.list[i])

		if weight then
			award[3] = math.floor(weight * 100 / datas.all_weight * 10) / 10
			award[3] = tostring(award[3]) .. "%"
		end

		local tmp = NGUITools.AddChild(awardGroup.gameObject, self.probabilityAwardItem.gameObject)
		local item = ActivityBeachPuzzleProbabilityAwardItem.new(tmp)

		item:setInfo(award)
	end

	awardGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityBeachPuzzleAwardPreviewWindow:initCumulationGroup()
	local groupContent = self.cumulationGroup:NodeByName("groupContent").gameObject
	local labelTitle_ = groupContent:ComponentByName("labelTitle_", typeof(UILabel))
	local awardGroup = groupContent:NodeByName("awardGroup").gameObject
	labelTitle_.text = __("ACTIVITY_BEACH_PUZZLE_TEXT06")
	local data = {}
	local ids = xyd.tables.activityBeachPuzzleTable:getIDs()

	for i = 1, #ids do
		table.insert(data, {
			id = ids[i],
			round = self.round
		})

		local isRepeat = xyd.tables.activityBeachPuzzleTable:getIsRepeat(ids[i])

		if isRepeat == 1 then
			data[#data].repeatId = i

			break
		end
	end

	table.sort(data, function (a, b)
		if a.round < a.id == (b.round < b.id) then
			return a.id < b.id
		else
			return b.id < a.id
		end
	end)

	for i = 1, #data do
		local tmp = NGUITools.AddChild(awardGroup.gameObject, self.cumulationAwardItem.gameObject)
		local item = ActivityBeachPuzzleCumulationAwardItem.new(tmp)

		item:setInfo(data[i])
	end

	awardGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityBeachPuzzleProbabilityAwardItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function ActivityBeachPuzzleProbabilityAwardItem:getUIComponent()
	self.icon_ = self.go:NodeByName("icon_").gameObject
	self.labelProbability_ = self.go:ComponentByName("labelProbability_", typeof(UILabel))
end

function ActivityBeachPuzzleProbabilityAwardItem:setInfo(data)
	self.data = data

	if data[3] then
		self.labelProbability_.text = tostring(data[3])
	end

	xyd.getItemIcon({
		show_has_num = true,
		notShowGetWayBtn = true,
		scale = 0.8981481481481481,
		uiRoot = self.icon_,
		itemID = data[1],
		num = data[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})
end

function ActivityBeachPuzzleCumulationAwardItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function ActivityBeachPuzzleCumulationAwardItem:getUIComponent()
	self.labelTitle_ = self.go:ComponentByName("labelTitle_", typeof(UILabel))
	self.progressBar_ = self.go:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressLabel_ = self.progressBar_:ComponentByName("progressLabel_", typeof(UILabel))
	self.awardGroup = self.go:NodeByName("awardGroup").gameObject
end

function ActivityBeachPuzzleCumulationAwardItem:setInfo(data)
	self.id = data.id
	self.round = data.round
	local isRepeat = xyd.tables.activityBeachPuzzleTable:getIsRepeat(self.id)

	if isRepeat == 1 then
		self.labelTitle_.text = __("ACTIVITY_BEACH_PUZZLE_TEXT08", data.repeatId)
		self.progressBar_.value = math.min(self.round, self.id) / self.id
		self.progressLabel_.text = self.round .. "/" .. self.id
	else
		self.labelTitle_.text = __("ACTIVITY_BEACH_PUZZLE_TEXT07", self.id)
		self.progressBar_.value = math.min(self.round, self.id) / self.id
		self.progressLabel_.text = math.min(self.round, self.id) .. "/" .. self.id
	end

	NGUITools.DestroyChildren(self.awardGroup.transform)

	local awards = xyd.tables.activityBeachPuzzleTable:getFinalAward(self.id)
	local icon = xyd.getItemIcon({
		show_has_num = true,
		notShowGetWayBtn = true,
		scale = 0.7037037037037037,
		uiRoot = self.awardGroup,
		itemID = awards[1],
		num = awards[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})

	icon:setChoose(self.id <= self.round)
	self.awardGroup:GetComponent(typeof(UILayout)):Reposition()
end

return ActivityBeachPuzzleAwardPreviewWindow
