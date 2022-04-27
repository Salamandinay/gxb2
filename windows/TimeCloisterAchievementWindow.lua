local TimeCloisterAchievementWindow = class("TimeCloisterAchievementWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local MissionItem = class("MissionItem", import("app.common.ui.FixedWrapContentItem"))
local timeCloister = xyd.models.timeCloisterModel
local achTable = xyd.tables.timeCloisterAchTable
local achTypeTable = xyd.tables.timeCloisterAchTypeTable

function TimeCloisterAchievementWindow:ctor(name, params)
	self.cloister = params.cloister

	TimeCloisterAchievementWindow.super.ctor(self, name, params)
end

function TimeCloisterAchievementWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function TimeCloisterAchievementWindow:getUIComponent()
	local groupMain_ = self.window_
	self.groupTop = groupMain_:NodeByName("groupTop").gameObject
	self.labelTitle = self.groupTop:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelDesc = self.groupTop:ComponentByName("labelDesc", typeof(UILabel))
	self.labelProgress = self.groupTop:ComponentByName("labelProgress", typeof(UILabel))
	self.labelNum = self.groupTop:ComponentByName("labelNum", typeof(UILabel))
	self.scrollView = groupMain_:ComponentByName("scroller_", typeof(UIScrollView))
	local itemGroup = self.scrollView:ComponentByName("itemGroup", typeof(UIWrapContent))
	local missionItem = groupMain_:NodeByName("missionItem").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, itemGroup, missionItem, MissionItem, self)
end

function TimeCloisterAchievementWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function TimeCloisterAchievementWindow:layout()
	self:initTopGroup()

	self.labelTitle.text = __("TIME_CLOISTER_TEXT43", xyd.tables.timeCloisterTable:getName(self.cloister))

	if xyd.Global.lang ~= "zh_tw" then
		self.labelDesc.spacingY = 0
	end

	if xyd.Global.lang == "de_de" then
		self.labelDesc:Y(-80)
	end

	self.labelDesc.text = __("TIME_CLOISTER_TEXT44")
	self.labelProgress.text = __("TIME_CLOISTER_TEXT45")

	self.scrollView:SetActive(false)
end

function TimeCloisterAchievementWindow:initContent(keepPosition)
	self.scrollView:SetActive(true)

	local ids = timeCloister:getAchInfo(self.cloister)
	local curNum = 0
	local totalNum = 0

	for _, data in ipairs(ids) do
		local start_id = achTypeTable:getStart(data.achieve_type)
		local end_id = achTypeTable:getEnd(data.achieve_type)

		if data.achieve_id ~= 0 then
			curNum = curNum + data.achieve_id - start_id
		else
			curNum = curNum + end_id - start_id + 1
		end

		totalNum = totalNum + end_id - start_id + 1
	end

	self.labelNum.text = math.floor(100 * curNum / totalNum) .. "% (" .. curNum .. "/" .. totalNum .. ")"

	table.sort(ids, function (a, b)
		local weighA = 0
		local weighB = 0

		if a.achieve_id == 0 then
			weighA = weighA - 10
		else
			local completeValue = achTable:getCompleteValue(a.achieve_id) or 0

			if completeValue <= tonumber(a.value) then
				weighA = weighA + 10
			end
		end

		if b.achieve_id == 0 then
			weighB = weighB - 10
		else
			local completeValue = achTable:getCompleteValue(b.achieve_id) or 0

			if completeValue <= tonumber(b.value) then
				weighB = weighB + 10
			end
		end

		if weighA == weighB then
			return a.achieve_id < b.achieve_id
		else
			return weighB < weighA
		end
	end)
	self.wrapContent:setInfos(ids, {
		keepPosition = keepPosition
	})
end

function TimeCloisterAchievementWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACHIEVE_INFO, handler(self, self.onGetAchieveInfo))
	self.eventProxy_:addEventListener(xyd.event.TIME_CLOISTER_GET_ACHIEVEMENT_AWARD, handler(self, self.onGetAchievementAward))
end

function TimeCloisterAchievementWindow:onGetAchievementAward(event)
	local awards = achTable:getAwards(event.data.old_id)
	local list = {}

	for _, award in ipairs(awards) do
		table.insert(list, {
			item_id = award[1],
			item_num = award[2]
		})
	end

	xyd.models.itemFloatModel:pushNewItems(list)
	self:initContent(true)
end

function TimeCloisterAchievementWindow:onGetAchieveInfo(event)
	self:initContent()
end

function MissionItem:initUI()
	local itemTrans = self.go.transform
	self.btnPreview = itemTrans:NodeByName("btnPreview").gameObject
	self.btnGo = itemTrans:NodeByName("btnGo").gameObject
	self.btnGoLabel = self.btnGo:ComponentByName("label", typeof(UILabel))
	self.btnAward = itemTrans:NodeByName("btnAward").gameObject
	self.btnAwardLabel = self.btnAward:ComponentByName("label", typeof(UILabel))
	self.missionDesc = itemTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.itemRoot = itemTrans:NodeByName("itemRoot").gameObject
	self.awardImg = itemTrans:ComponentByName("imgAward", typeof(UISprite))

	xyd.setUISpriteAsync(self.awardImg, nil, "mission_awarded_" .. xyd.Global.lang, nil, )

	self.btnAwardLabel.text = __("GET2")
	self.btnGoLabel.text = __("GO")
	self.itemIconList = {}
	UIEventListener.Get(self.btnAward).onClick = handler(self, self.onTouchGetAward)
	UIEventListener.Get(self.btnGo).onClick = handler(self, self.onTouchGo)
	UIEventListener.Get(self.btnPreview).onClick = handler(self, self.onTouchPreview)
end

function MissionItem:updateInfo()
	local achieve_id = self.data.achieve_id

	if achieve_id ~= 0 and not achTable:getCompleteValue(achieve_id) then
		self.go:SetActive(false)

		return
	end

	if achieve_id == 0 then
		achieve_id = achTypeTable:getEnd(self.data.achieve_type)
	end

	local dataValue = self.data.value
	local style = achTypeTable:getStyle(self.data.achieve_type)
	local completeValue = achTable:getCompleteValue(achieve_id)

	if style == 2 then
		local start_id = achTypeTable:getStart(self.data.achieve_type)
		local start_complete = achTable:getCompleteValue(start_id)
		completeValue = completeValue - (start_complete - 1)

		if tonumber(completeValue) < tonumber(dataValue) then
			dataValue = dataValue - (start_complete - 1)
		end
	end

	self.missionDesc.text = xyd.stringFormat(achTable:getDesc(achieve_id), xyd.getRoughDisplayNumber(completeValue)) .. "[c][369900] (" .. xyd.getRoughDisplayNumber(tonumber(dataValue)) .. "/" .. xyd.getRoughDisplayNumber(completeValue) .. ")"

	if tonumber(dataValue) < completeValue then
		self.btnGo:SetActive(true)
		self.btnAward:SetActive(false)
		self.awardImg:SetActive(false)
	elseif self.data.achieve_id == 0 then
		self.btnGo:SetActive(false)
		self.btnAward:SetActive(false)
		self.awardImg:SetActive(true)
	elseif completeValue <= tonumber(dataValue) then
		self.btnGo:SetActive(false)
		self.btnAward:SetActive(true)
		self.awardImg:SetActive(false)
	end

	local awards = achTable:getAwards(achieve_id)
	local len = math.max(#awards, #self.itemIconList)

	for i = 1, len do
		if awards[i] and self.itemIconList[i] then
			self.itemIconList[i]:SetActive(true)
			self.itemIconList[i]:setInfo({
				itemID = awards[i][1],
				num = awards[i][2]
			})
		elseif awards[i] and not self.itemIconList[i] then
			self.itemIconList[i] = xyd.getItemIcon({
				scale = 0.7962962962962963,
				uiRoot = self.itemRoot,
				itemID = awards[i][1],
				num = awards[i][2],
				dragScrollView = self.parent.scrollView
			})
		elseif not awards[i] and self.itemIconList[i] then
			self.itemIconList[i]:SetActive(false)
		end
	end

	self.itemRoot:GetComponent(typeof(UILayout)):Reposition()
end

function MissionItem:onTouchGetAward()
	timeCloister:reqAchievementAward(self.data.achieve_type)
end

function MissionItem:onTouchGo()
	local cloister = self.parent.cloister
	local styleType = achTypeTable:getStyle(self.data.achieve_type)

	if styleType == 2 or self.data.achieve_type == 20 then
		timeCloister:reqTechInfo(cloister)
		timeCloister:reqCloisterInfo(cloister)
		xyd.WindowManager.get():openWindow("time_cloister_battle_window", {
			cloister = cloister
		})
	elseif self.parent.cloister == timeCloister:getChosenCloister() then
		local timeCloisterMainWindow = xyd.WindowManager.get():getWindow("time_cloister_main_window")

		if timeCloisterMainWindow then
			timeCloisterMainWindow:openProbeWindow(cloister)
		end
	end

	xyd.WindowManager.get():closeWindow("time_cloister_achievement_window")
end

function MissionItem:onTouchPreview()
	xyd.WindowManager.get():openWindow("time_cloister_achievement_detail_window", {
		achieve_id = self.data.achieve_id,
		achieve_type = self.data.achieve_type,
		value = self.data.value
	})
end

return TimeCloisterAchievementWindow
