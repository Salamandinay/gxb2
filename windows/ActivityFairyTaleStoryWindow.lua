local ActivityFairyTaleStoryWindow = class("ActivityFairyTaleStoryWindow", import(".BaseWindow"))
local fairyStoryItem = class("fairyStoryItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivityFairyTaleStoryWindow:ctor(name, params)
	ActivityFairyTaleStoryWindow.super.ctor(self, name, params)

	self.mapId_ = params.map_id
	self.unlockValue = params.value
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)
end

function ActivityFairyTaleStoryWindow:initWindow()
	ActivityFairyTaleStoryWindow.super.initWindow(self)
	self:getComponent()
	self:refreshStoryList()
	self:regisetr()

	self.winTitle_.text = __("ACTIVITY_FAIRY_TALE_STORY_WINDOW")

	self.eventProxy_:addEventListener(xyd.event.GET_FAIRY_PLOT_AWARD, handler(self, self.awardBack))
end

function ActivityFairyTaleStoryWindow:awardBack(event)
	local mapid = xyd.tables.activityFairyTalePlotListTable:getMapType(event.data.table_id)
	self.maxPlayId = xyd.tables.activityFairyTalePlotListTable:getNextId(event.data.table_id)

	self.activityData:updatePlotList(mapid, self.maxPlayId)

	local itemsArr = {}

	table.insert(itemsArr, {
		item_id = event.data.items.item_id,
		item_num = event.data.items.item_num
	})
	xyd.itemFloat(itemsArr, nil, , 6500)
	self.activityData:updateMission(6)

	local mapWin = xyd.WindowManager.get():getWindow("activity_fairy_tale_map")

	if mapWin then
		mapWin:updatePlotRedPoint()
	end
end

function ActivityFairyTaleStoryWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.winTitle_ = winTrans:ComponentByName("winTitle", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	local storyItemRoot = self.window_:NodeByName("storyItem").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, storyItemRoot, fairyStoryItem, self)
end

function ActivityFairyTaleStoryWindow:refreshStoryList()
	local storyIds = xyd.tables.activityFairyTalePlotListTable:getIdsByMapId(self.mapId_)
	local canPlayMaxId = self.activityData.detail.plot_ids[self.mapId_]
	self.maxPlayId = canPlayMaxId

	table.sort(storyIds)

	local infos = {}

	for _, id in ipairs(storyIds) do
		local params = {
			id = id,
			is_awarded = self:checkHasAward(id)
		}

		table.insert(infos, params)
	end

	self.multiWrap_:setInfos(infos, {})
end

function ActivityFairyTaleStoryWindow:checkHasAward(id)
	local canPlayMaxId = self.activityData.detail.plot_ids[self.mapId_]

	if id < canPlayMaxId or canPlayMaxId == -1 then
		return true
	end

	return false
end

function ActivityFairyTaleStoryWindow:regisetr()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function fairyStoryItem:ctor(parentGo, parent)
	self.parent_ = parent
	self.awardIconArr_ = {}

	fairyStoryItem.super.ctor(self, parentGo)
end

function fairyStoryItem:initUI()
	fairyStoryItem.super.initUI(self)
	self:getComponent()
	self:register()
end

function fairyStoryItem:getComponent()
	local goTrans = self.go.transform
	self.awardRoot_ = goTrans:NodeByName("award").gameObject
	self.awardRoot_layout = goTrans:ComponentByName("award", typeof(UILayout))
	self.titleLabel_ = goTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.storyImg_ = goTrans:ComponentByName("storyImg", typeof(UISprite))
	self.imgLock_ = goTrans:NodeByName("lockCon/imgLock").gameObject
	self.lockCon_ = goTrans:NodeByName("lockCon").gameObject
	self.redPoint_ = goTrans:NodeByName("redPoint").gameObject
end

function fairyStoryItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.info = info
	self.id_ = info.id
	self.hasAwarded_ = info.is_awarded
	self.plotId_ = xyd.tables.activityFairyTalePlotListTable:getPlotIdById(self.id_)
	self.award_ = xyd.tables.activityFairyTalePlotListTable:getAward(self.id_)
	self.unLockValue_ = xyd.tables.activityFairyTalePlotListTable:getUnlockById(self.id_)
	local imgName = xyd.tables.activityFairyTalePlotListTable:getChapterIcon(self.id_)

	xyd.setUISpriteAsync(self.storyImg_, nil, imgName, nil, )

	self.titleLabel_.text = xyd.tables.activityFairyTalePlotTextTable:getTitle(self.id_)

	for i in pairs(self.award_) do
		local params = {
			uiRoot = self.awardRoot_,
			itemID = self.award_[i][1],
			num = self.award_[i][2]
		}

		if not self.awardIconArr_[i] then
			self.awardIconArr_[i] = xyd.getItemIcon(params)
		else
			self.awardIconArr_[i]:setInfo(params)
		end

		self.awardIconArr_[i]:setChoose(self.hasAwarded_)
	end

	self.awardRoot_layout:Reposition()

	self.hasLock_ = self.parent_.unlockValue < self.unLockValue_

	self.lockCon_:SetActive(self.hasLock_)

	if self.hasAwarded_ == false and self.hasLock_ == false then
		self.redPoint_:SetActive(true)
	else
		self.redPoint_:SetActive(false)
	end
end

function fairyStoryItem:register()
	self:registerEvent(xyd.event.GET_FAIRY_PLOT_AWARD, handler(self, self.awardBack))

	UIEventListener.Get(self.go).onClick = function ()
		if not self.hasLock_ then
			if self.id_ <= self.parent_.maxPlayId or self.parent_.maxPlayId == -1 then
				xyd.WindowManager.get():openWindow("story_window", {
					story_type = xyd.StoryType.ACTIVITY,
					story_id = self.plotId_,
					callback = function ()
						local msg = messages_pb:get_fairy_plot_award_req()
						msg.activity_id = xyd.ActivityID.FAIRY_TALE
						msg.table_id = self.id_

						xyd.Backend.get():request(xyd.mid.GET_FAIRY_PLOT_AWARD, msg)
					end
				})
			else
				xyd.showToast(__("FAIRY_TALE_STORY_NEED_BEFORE"))
			end
		else
			xyd.showToast(__("FAIRY_TALE_STORY_UNLOCK", self.unLockValue_))
		end
	end
end

function fairyStoryItem:awardBack(event)
	if self.id_ == event.data.table_id then
		for i in pairs(self.awardIconArr_) do
			if self.awardIconArr_[i] then
				self.awardIconArr_[i]:setChoose(true)
			end
		end

		self.redPoint_:SetActive(false)
	end
end

return ActivityFairyTaleStoryWindow
