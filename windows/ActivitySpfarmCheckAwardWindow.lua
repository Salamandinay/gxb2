local ActivitySpfarmCheckAwardWindow = class("ActivitySpfarmCheckAwardWindow", import(".BaseWindow"))
local SpaceExploreAwardItem = class("SpaceExploreAwardItem", import("app.components.CopyComponent"))
local json = require("cjson")

function SpaceExploreAwardItem:ctor(go, parent)
	self.parent_ = parent
	self.itemList_ = {}

	SpaceExploreAwardItem.super.ctor(self, go)
end

function SpaceExploreAwardItem:initUI()
	SpaceExploreAwardItem.super.initUI(self)
	self:getComponent()
end

function SpaceExploreAwardItem:getComponent()
	self.itemIcon_ = self.go:ComponentByName("itemIcon", typeof(UISprite))
	self.labelNum_ = self.go:ComponentByName("labelNum", typeof(UILabel))
	self.itemGroup_ = self.go:ComponentByName("itemGroup", typeof(UIGrid))
end

function SpaceExploreAwardItem:update(_, _, id)
	if not id then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id_ = id
	local level = xyd.tables.activitySpfarmAwardTable:getLevel(self.id_)
	local levelNow = self.parent_.activityData_:getFamousNum()
	local is_awarded = self.parent_:checkIsAwarded(self.id_)
	local funcClick = nil

	if not is_awarded then
		if levelNow >= level then
			function funcClick()
				self.parent_:reqAward()
			end
		end
	end

	self.labelNum_.text = level
	local awardItem = xyd.tables.activitySpfarmAwardTable:getAwards(self.id_)

	for idx, itemInfo in ipairs(awardItem) do
		if not self.itemList_[idx] then
			self.itemList_[idx] = xyd.getItemIcon({
				notPlaySaoguang = true,
				scale = 0.7037037037037037,
				isShowSelected = false,
				uiRoot = self.itemGroup_.gameObject,
				itemID = itemInfo[1],
				num = itemInfo[2],
				dragScrollView = self.parent_.scrollView_,
				callback = funcClick
			})
		else
			NGUITools.Destroy(self.itemList_[idx]:getGameObject())

			self.itemList_[idx] = xyd.getItemIcon({
				notPlaySaoguang = true,
				scale = 0.7037037037037037,
				isShowSelected = false,
				uiRoot = self.itemGroup_.gameObject,
				itemID = itemInfo[1],
				num = itemInfo[2],
				dragScrollView = self.parent_.scrollView_,
				callback = funcClick
			})
		end

		self.itemList_[idx]:getGameObject().transform:SetSiblingIndex(idx - 1)
		self.itemList_[idx]:setChoose(is_awarded)

		if not is_awarded and level <= levelNow then
			local effect = "bp_available"

			self.itemList_[idx]:setEffect(true, effect, {
				effectPos = Vector3(0, -2, 0),
				effectScale = Vector3(1.1, 1.1, 1.1),
				target = self.parent_.scrollView_.panel
			})
		else
			self.itemList_[idx]:setEffect(false)
		end
	end

	for idx, item in ipairs(self.itemList_) do
		if not awardItem[idx] then
			item:getGameObject():SetActive(false)
		else
			item:getGameObject():SetActive(true)
		end
	end

	self.itemGroup_:Reposition()

	local famousLevelArr = xyd.tables.miscTable:split2num("activity_spfarm_gate_style", "value", "|")

	for i = #famousLevelArr, 1, -1 do
		if famousLevelArr[i] <= level then
			local imgStr = "activity_spfarm_gate_3"

			if i == 2 then
				imgStr = "activity_spfarm_gate_2"
			elseif i == 1 then
				imgStr = "activity_space_explore_bg_m_1"
			end

			xyd.setUISpriteAsync(self.itemIcon_, nil, imgStr)

			break
		end
	end
end

function ActivitySpfarmCheckAwardWindow:ctor(name, params)
	ActivitySpfarmCheckAwardWindow.super.ctor(self, name, params)

	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
	self.itemNum_ = self.activityData_:getFamousNum()
end

function ActivitySpfarmCheckAwardWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivitySpfarmCheckAwardWindow:getUIComponent()
	local go = self.window_:NodeByName("groupAction")
	self.titleLabel_ = go:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = go:NodeByName("closeBtn").gameObject
	self.costItemNum_ = go:ComponentByName("costGroup/labelNum", typeof(UILabel))
	self.imgGo_ = go:NodeByName("costGroup/imgGo").gameObject
	self.labelText01_ = go:ComponentByName("groupContent/labelText1", typeof(UILabel))
	self.labelText02_ = go:ComponentByName("groupContent/labelText2", typeof(UILabel))
	self.scrollView_ = go:ComponentByName("groupContent/scrollView", typeof(UIScrollView))
	self.grid_ = go:ComponentByName("groupContent/scrollView/grid", typeof(MultiRowWrapContent))
	self.itemRoot_ = go:NodeByName("item_root").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, self.itemRoot_, SpaceExploreAwardItem, self)
end

function ActivitySpfarmCheckAwardWindow:layout()
	self.titleLabel_.text = __("ACTIVITY_SPFARM_TEXT97")
	self.labelText01_.text = __("ACTIVITY_SPFARM_TEXT63")
	self.labelText02_.text = __("LEV_UP_AWARD")
	self.costItemNum_.text = self.itemNum_
	local ids = xyd.tables.activitySpfarmAwardTable:getIds()

	self.multiWrap_:setInfos(ids, {})
end

function ActivitySpfarmCheckAwardWindow:register()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.imgGo_).onClick = function ()
		if self.itemNum_ == 15 then
			xyd.alertConfirm(__("ACTIVITY_SPFARM_TEXT107"), nil, __("SURE"))
		else
			xyd.alertConfirm(__("ACTIVITY_SPFARM_TEXT98"), nil, __("SURE"))
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function ActivitySpfarmCheckAwardWindow:checkIsAwarded(id)
	local awards = self.activityData_.detail.awards

	if awards and awards[id] and tonumber(awards[id]) > 0 then
		return true
	end

	return false
end

function ActivitySpfarmCheckAwardWindow:reqAward()
	local reqList = {}
	local ids = xyd.tables.activitySpfarmAwardTable:getIds()

	for _, id in ipairs(ids) do
		local level = xyd.tables.activitySpfarmAwardTable:getLevel(id)
		local levelNow = self.activityData_:getFamousNum()
		local is_awarded = self:checkIsAwarded(id)

		if not is_awarded and level <= levelNow then
			table.insert(reqList, id)
		end
	end

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
		type = xyd.ActivitySpfarmType.GET_AWARD,
		award_ids = reqList
	}))
end

function ActivitySpfarmCheckAwardWindow:onGetAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SPFARM then
		return
	end

	local info = json.decode(event.data.detail)
	local type = info.type

	if type == xyd.ActivitySpfarmType.GET_AWARD then
		local ids = xyd.tables.activitySpfarmAwardTable:getIds()

		self.multiWrap_:setInfos(ids, {
			keepPosition = true
		})
	end
end

return ActivitySpfarmCheckAwardWindow
