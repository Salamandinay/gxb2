local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ActivityCollectCoralBranch = class("ActivityCollectCoralBranch", ActivityContent)
local ActivityCollectCoralBranchItem = class("ValueGiftBagItem", import("app.components.CopyComponent"))

function ActivityCollectCoralBranch:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
	self:getUIComponent()

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.LAFULI_DRIFT)

	self:euiComplete()
end

function ActivityCollectCoralBranch:getPrefabPath()
	return "Prefabs/Windows/activity/collect_coral_branch"
end

function ActivityCollectCoralBranch:getUIComponent()
	local go = self.go
	self.activityGroup = go:NodeByName("main").gameObject
	self.textImg = self.activityGroup:ComponentByName("textImg", typeof(UITexture))
	self.textLabel = self.activityGroup:ComponentByName("textLabel", typeof(UILabel))
	self.timerGroup = self.activityGroup:NodeByName("timerGroup").gameObject
	self.timeLabel = self.timerGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timerGroup:ComponentByName("endLabel", typeof(UILabel))
	self.scroller = self.activityGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollerPanel = self.activityGroup:ComponentByName("scroller", typeof(UIPanel))
	self.scrollerPanel.depth = self.scrollerPanel.depth + 1
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.groupItem_uigrid = self.groupItem:GetComponent(typeof(UIGrid))
	self.costLabel = self.activityGroup:ComponentByName("costGroup/label", typeof(UILabel))
	self.costBtn = self.activityGroup:NodeByName("costGroup/btn").gameObject
	self.roundLabel = self.activityGroup:ComponentByName("roundLabel", typeof(UILabel))
	self.itemCell = go:NodeByName("itemCell").gameObject
end

function ActivityCollectCoralBranch:euiComplete()
	xyd.setUITextureByNameAsync(self.textImg, "activity_lafuli_drift_title_" .. xyd.Global.lang, true)
	self:setText()
	self:setItem()
	self:eventRegister()

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	if xyd.Global.lang == "fr_fr" then
		self.timerGroup:X(150)
	elseif xyd.Global.lang == "ja_jp" then
		self.timerGroup:X(153)
	end
end

function ActivityCollectCoralBranch:setText()
	self.endLabel.text = __("TEXT_END")
	self.textLabel.text = __("ACTIVITY_LAFULI_BRANCH_TEXT")
	self.roundLabel.text = __("ACTIVITY_LAFULI_DRIFT_ROUND", math.floor(self.activityData.detail.point / 300))
	self.costLabel.text = self.activityData.detail.point

	if xyd.Global.lang == "fr_fr" then
		self.textLabel.width = 340
		self.textLabel.fontSize = 21

		self.textLabel:X(19)
		self.textLabel:Y(-208)
	end
end

function ActivityCollectCoralBranch:setItem()
	local ids = xyd.tables.activityDriftAwardTable:getIDs()
	local awards = {}

	for i = 1, #ids do
		table.insert(awards, {
			awards = xyd.tables.activityDriftAwardTable:getAwards(ids[i]),
			point = xyd.tables.activityDriftAwardTable:getPoint(ids[i]),
			curPoint = self.activityData.detail.point
		})
	end

	table.sort(awards, function (a, b)
		local maxPoint = xyd.tables.activityDriftAwardTable:getPoint(xyd.tables.activityDriftAwardTable:getIDs()[#xyd.tables.activityDriftAwardTable:getIDs()])

		if a.point <= math.fmod(a.curPoint, maxPoint) == (b.point <= math.fmod(b.curPoint, maxPoint)) then
			return a.point < b.point
		else
			return math.fmod(a.curPoint, maxPoint) < a.point
		end
	end)
	NGUITools.DestroyChildren(self.groupItem.transform)

	for i in ipairs(awards) do
		local tmp = NGUITools.AddChild(self.groupItem, self.itemCell)
		local item = ActivityCollectCoralBranchItem.new(tmp, awards[i], self.scroller)
	end

	self.groupItem_uigrid:Reposition()
	self.itemCell:SetActive(false)
end

function ActivityCollectCoralBranch:eventRegister()
	UIEventListener.Get(self.costBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow("activity_window", function ()
			xyd.openWindow("activity_window", {
				activity_type = xyd.tables.activityTable:getType2(xyd.ActivityID.LAFULI_DRIFT),
				select = xyd.ActivityID.LAFULI_DRIFT
			})
		end)
	end
end

function ActivityCollectCoralBranchItem:ctor(goItem, itemdata, scroller)
	self.goItem_ = goItem
	self.scrollerView = scroller
	local transGo = goItem.transform
	self.imgbg = transGo:ComponentByName("e:Image", typeof(UITexture))
	self.progressBar_ = transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.labelTitle_ = transGo:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup_ = transGo:Find("itemsGroup")

	self:initItem(itemdata)
end

function ActivityCollectCoralBranchItem:initItem(itemdata)
	self.progressBar_.value = math.min(itemdata.point, itemdata.curPoint - math.floor(itemdata.curPoint / 300) * 300) / itemdata.point
	local max = math.floor(itemdata.curPoint / 300) * 300 + itemdata.point
	self.progressDesc.text = itemdata.curPoint .. "/" .. max
	self.labelTitle_.text = __("ACTIVITY_LAFULI_DRIFT_POINT", math.floor(itemdata.curPoint / 300) * 300 + itemdata.point)

	for _, reward in pairs(itemdata.awards) do
		local icon = xyd.getItemIcon({
			show_has_num = true,
			showGetWays = false,
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_.gameObject,
			dragScrollView = self.scrollerView,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		icon:setScale(0.7)

		if itemdata.point <= itemdata.curPoint - math.floor(itemdata.curPoint / 300) * 300 then
			icon:setChoose(true)
		end
	end
end

return ActivityCollectCoralBranch
