local BaseWindow = import(".BaseWindow")
local ActivityLafuliCastleTaskWindow = class("ActivityLafuliCastleTaskWindow", BaseWindow)
local ActivityLafuliCastleTaskItem = class("ActivityLafuliCastleTaskItem", import("app.components.CopyComponent"))
local activityID = xyd.ActivityID.ACTIVITY_LAFULI_CASTLE
local taskAwardLimit = xyd.tables.miscTable:getNumber("activity_lflcastle_task_award_limit", "value")
local taskAwardItemID = xyd.tables.miscTable:split2Cost("activity_lflcastle_score", "value", "|")[2]

function ActivityLafuliCastleTaskWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(activityID)
end

function ActivityLafuliCastleTaskWindow:initWindow()
	self:getUIComponent()
	ActivityLafuliCastleTaskWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityLafuliCastleTaskWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.helpBtn = groupAction:NodeByName("helpBtn").gameObject
	local groupTop = groupAction:ComponentByName("groupTop", typeof(UISprite))
	self.groupTip = groupTop:NodeByName("groupTip").gameObject
	self.labelTip1 = self.groupTip:ComponentByName("labelTip1", typeof(UILabel))
	self.labelTip2 = self.groupTip:ComponentByName("labelTip2", typeof(UILabel))
	self.imgTicket = self.groupTip:NodeByName("imgTicket").gameObject
	self.labelTipEx = groupTop:ComponentByName("labelTipEx", typeof(UILabel))
	self.awardGroup = groupTop:ComponentByName("awardGroup", typeof(UISprite))
	self.awardNode = self.awardGroup:NodeByName("awardNode").gameObject
	self.groupLimit = groupTop:NodeByName("groupLimit").gameObject
	self.labelLimit = self.groupLimit:ComponentByName("labelLimit", typeof(UILabel))
	self.labelNum = self.groupLimit:ComponentByName("labelNum", typeof(UILabel))
	self.btnAward = groupTop:NodeByName("btnAward").gameObject
	self.labelAward = self.btnAward:ComponentByName("labelAward", typeof(UILabel))
	local mainGroup = groupAction:NodeByName("mainGroup").gameObject
	self.labelTip3 = mainGroup:ComponentByName("labelTip3", typeof(UILabel))
	self.scroller = mainGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.itemCell = winTrans:NodeByName("itemCell").gameObject

	self.itemCell:SetActive(false)
end

function ActivityLafuliCastleTaskWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_LAFULI_CASTLE_TEXT06")
	self.labelTip1.text = __("ACTIVITY_LAFULI_CASTLE_TEXT07")
	self.labelLimit.text = __("ACTIVITY_LAFULI_CASTLE_TEXT09")
	self.labelAward.text = __("GET2")
	self.labelTip3.text = __("ACTIVITY_LAFULI_CASTLE_TEXT10")
	local textData = __("ACTIVITY_LAFULI_CASTLE_TEXT08", taskAwardLimit)
	textData = xyd.split(textData, "|")

	if #textData > 1 then
		self.groupTip:Y(145)

		self.labelTip2.text = textData[1]
		self.labelTipEx.text = textData[2]
	else
		self.labelTip2.text = textData[1]
	end

	if xyd.Global.lang == "ko_kr" or xyd.Global.lang == "ja_jp" then
		self.imgTicket.transform:SetSiblingIndex(0)
	end

	if xyd.Global.lang == "ko_kr" then
		self.labelTip1.fontSize = 18
		self.labelTip2.fontSize = 18
	end

	if xyd.Global.lang == "ja_jp" then
		self.labelTip1.fontSize = 18
		self.labelTip2.fontSize = 18
	end

	self.groupTip:GetComponent(typeof(UILayout)):Reposition()

	local ids = xyd.tables.activityLflcastleTaskTable:getIDs()

	for i = 1, #ids do
		local params = {
			id = ids[i],
			curComplete = self.activityData.detail.is_completeds[i],
			curPoint = self.activityData.detail.values[i]
		}
		local go = NGUITools.AddChild(self.groupItem, self.itemCell)
		local item = ActivityLafuliCastleTaskItem.new(go, self)

		item:setInfo(params)
	end

	self.groupItem:GetComponent(typeof(UILayout)):Reposition()
	self.scroller:ResetPosition()
	self:updateState()
end

function ActivityLafuliCastleTaskWindow:updateState()
	self.labelNum.text = self.activityData.detail.times .. "/" .. taskAwardLimit

	self.groupLimit:GetComponent(typeof(UILayout)):Reposition()
	NGUITools.DestroyChildren(self.awardNode.transform)

	local icon = xyd.getItemIcon({
		show_has_num = true,
		showGetWays = false,
		scale = 0.7592592592592593,
		notShowGetWayBtn = true,
		itemID = taskAwardItemID,
		num = self.activityData.detail.m_point,
		uiRoot = self.awardNode.gameObject,
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})

	if self.activityData.detail.m_point > 0 then
		icon:setEffect(true, "fx_ui_bp_available")
		xyd.setEnabled(self.btnAward.gameObject, true)
	else
		icon:setMask(true)
		icon:setAlpha(0.5)
		xyd.setEnabled(self.btnAward.gameObject, false)
	end
end

function ActivityLafuliCastleTaskWindow:register()
	ActivityLafuliCastleTaskWindow.super.register(self)

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_LAFULI_CASTLE_TEXT12"
		})
	end

	UIEventListener.Get(self.btnAward.gameObject).onClick = function ()
		if self.activityData.detail.m_point <= 0 then
			return
		end

		local params = {
			type = 3,
			num = self.activityData.detail.m_point
		}

		self.activityData:sendReq(params)
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateState))
end

function ActivityLafuliCastleTaskItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.labelDesc = self.go:ComponentByName("labelDesc", typeof(UILabel))
	self.progressBar = self.go:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.groupItem = self.go:NodeByName("groupItem").gameObject
	self.imgTicket = self.go:NodeByName("imgTicket").gameObject
	self.labelTicket = self.imgTicket:ComponentByName("labelTicket", typeof(UILabel))
	self.labelLimit = self.go:ComponentByName("labelLimit", typeof(UILabel))
	self.labelNum = self.go:ComponentByName("labelNum", typeof(UILabel))
	self.imgFinish = self.go:ComponentByName("imgFinish", typeof(UISprite))
end

function ActivityLafuliCastleTaskItem:setInfo(params)
	self.id = params.id
	self.curComplete = params.curComplete
	self.curPoint = params.curPoint
	local taskPoint = xyd.tables.activityLflcastleTaskTable:getPoint(self.id)
	local completePoint = xyd.tables.activityLflcastleTaskTable:getComplete(self.id)
	local limitComplete = xyd.tables.activityLflcastleTaskTable:getLimit(self.id)
	local awards = xyd.tables.activityLflcastleTaskTable:getAwards(self.id)
	self.labelDesc.text = xyd.tables.activityLflcastleTaskTextTable:getDesc(self.id)
	self.progressBar.value = self.curPoint % completePoint / completePoint
	self.progressLabel.text = self.curPoint % completePoint .. "/" .. completePoint

	if taskPoint and taskPoint ~= 0 then
		self.labelTicket.text = taskPoint
	else
		self.imgTicket:SetActive(false)
	end

	for i = 1, #awards do
		local award = awards[i]
		local icon = xyd.getItemIcon({
			showGetWays = false,
			notShowGetWayBtn = true,
			show_has_num = true,
			scale = 0.6296296296296297,
			itemID = award[1],
			num = award[2],
			uiRoot = self.groupItem,
			dragScrollView = self.parent.scroller,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	if taskPoint and taskPoint ~= 0 then
		local ticket = NGUITools.AddChild(self.groupItem, self.imgTicket)
		local labelTicket = ticket:ComponentByName("labelTicket", typeof(UILabel))
		self.labelTicket.text = taskPoint
	end

	self.groupItem:GetComponent(typeof(UILayout)):Reposition()

	self.labelLimit.text = __("ACTIVITY_LAFULI_CASTLE_TEXT11")
	self.labelNum.text = self.curComplete .. "/" .. limitComplete

	if limitComplete <= self.curComplete then
		self.progressBar.value = 1
		self.progressLabel.text = completePoint .. "/" .. completePoint
	end
end

return ActivityLafuliCastleTaskWindow
