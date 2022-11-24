local ActivityStarPlanMissionWindow = class("ActivityStarPlanMissionWindow", import(".BaseWindow"))
local MissionItem = class("MissionItem", import("app.components.CopyComponent"))
local cjson = require("cjson")

function ActivityStarPlanMissionWindow:ctor(name, params)
	ActivityStarPlanMissionWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_STAR_PLAN)
	self.missionList = {}
	self.buyTimes_ = self.activityData.detail.times
	self.hasAwarded_ = self.activityData.detail.awards
end

function ActivityStarPlanMissionWindow:initWindow()
	ActivityStarPlanMissionWindow.super.initWindow(self)
	self:getUIComponent()
	self:updateMissionList(true)
	self:register()
end

function ActivityStarPlanMissionWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.missionItem_ = winTrans:NodeByName("missionItem").gameObject
	self.titleLabel_.text = __("ACTIVITY_STAR_PLAN_AWARDS_BUTTON")
end

function ActivityStarPlanMissionWindow:updateMissionList(is_first)
	local ids = xyd.tables.activityStarPlanAwardsTable:getIDs()

	for _, id in ipairs(ids) do
		if not self.missionList[id] then
			local newItemRoot = NGUITools.AddChild(self.grid_.gameObject, self.missionItem_)

			newItemRoot:SetActive(true)

			self.missionList[id] = MissionItem.new(newItemRoot, self)
		end

		self.missionList[id]:setInfo(id, self.buyTimes_, self.hasAwarded_[id])
	end

	if is_first then
		self:waitForFrame(1, function ()
			self.grid_:Reposition()
			self.scrollView_:ResetPosition()
		end)
	end
end

function ActivityStarPlanMissionWindow:register()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function ActivityStarPlanMissionWindow:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.activity_id == xyd.ActivityID.ACTIVITY_STAR_PLAN and event.data.detail and tostring(event.data.detail) ~= "" then
		local details = cjson.decode(event.data.detail)

		if details.type == 4 then
			local id = details.id
			local awards = xyd.tables.activityStarPlanAwardsTable:getAwards(id)
			local itemDatas = {}

			for _, info in ipairs(awards) do
				table.insert(itemDatas, {
					item_id = info[1],
					item_num = info[2]
				})
			end

			xyd.itemFloat(itemDatas)
			self:updateMissionList()
		end
	end
end

function MissionItem:ctor(go, parent)
	self.parent_ = parent
	self.itemList_ = {}

	MissionItem.super.ctor(self, go)
end

function MissionItem:initUI()
	MissionItem.super.initUI(self)
	self:getUIComponent()
end

function MissionItem:getUIComponent()
	local goTrans = self.go
	self.titleLabel_ = goTrans:ComponentByName("titleImg/titleLabel", typeof(UILabel))
	self.awardBtn_ = goTrans:NodeByName("awardBtn").gameObject
	self.awardMask_ = goTrans:NodeByName("awardBtn/mask").gameObject
	self.awardLabel_ = goTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.finishImg_ = goTrans:ComponentByName("finishImg", typeof(UISprite))
	self.itemGrid_ = goTrans:ComponentByName("itemGrid", typeof(UILayout))
	UIEventListener.Get(self.awardBtn_).onClick = handler(self, self.onClickAward)
end

function MissionItem:setInfo(id, buytimes, hasAwarded)
	self.id_ = id
	self.buyTimes_ = buytimes
	self.hasAwarded = hasAwarded
	local needNum = xyd.tables.activityStarPlanAwardsTable:getNum(self.id_)
	local awards = xyd.tables.activityStarPlanAwardsTable:getAwards(self.id_)
	local award_gamble = xyd.tables.activityStarPlanAwardsTable:getGambleID(self.id_)

	if needNum <= self.buyTimes_ then
		self.buyTimes_ = needNum

		self.awardMask_:SetActive(false)
	else
		self.awardMask_:SetActive(true)
	end

	self.titleLabel_.text = __("ACTIVITY_STAR_PLAN_AWARDS_TEXT", needNum, self.buyTimes_ .. "/" .. needNum)
	self.awardLabel_.text = __("GET2")

	for index, itemInfo in ipairs(awards) do
		if not self.itemList_[index] then
			self.itemList_[index] = xyd.getItemIcon({
				scale = 0.7962962962962963,
				uiRoot = self.itemGrid_.gameObject,
				itemID = itemInfo[1],
				num = itemInfo[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent_.scrollView_
			})
		end

		if self.hasAwarded and self.hasAwarded == 1 then
			self.itemList_[index]:setChoose(true)
		end
	end

	if award_gamble and award_gamble[1] and award_gamble[1] > 0 then
		local awardShowID = xyd.tables.activityStarPlanGambleTable:getAwardShow(award_gamble[1])

		if not self.itemList_[#awards + 1] then
			self.itemList_[#awards + 1] = xyd.getItemIcon({
				scale = 0.7962962962962963,
				uiRoot = self.itemGrid_.gameObject,
				itemID = awardShowID,
				num = award_gamble[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent_.scrollView_
			})
		end

		if self.hasAwarded and self.hasAwarded == 1 then
			self.itemList_[#awards + 1]:setChoose(true)
		end
	end

	self.itemGrid_:Reposition()

	if self.hasAwarded and self.hasAwarded == 1 then
		self.awardBtn_:SetActive(false)
		self.finishImg_.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.finishImg_, nil, "mission_awarded_" .. xyd.Global.lang, nil, , true)
	else
		self.awardBtn_:SetActive(true)
		self.finishImg_.gameObject:SetActive(false)
	end
end

function MissionItem:onClickAward()
	local needNum = xyd.tables.activityStarPlanAwardsTable:getNum(self.id_)

	if self.buyTimes_ < needNum then
		return
	end

	if self.hasAwarded and self.hasAwarded == 1 then
		return
	end

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_STAR_PLAN, cjson.encode({
		type = 4,
		id = self.id_
	}))
end

return ActivityStarPlanMissionWindow
