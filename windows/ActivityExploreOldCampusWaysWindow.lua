local BaseWindow = import(".BaseWindow")
local ActivityExploreOldCampusWaysWindow = class("ActivityExploreOldCampusWaysWindow", BaseWindow)
local BuffsItem = class("BuffsItem", import("app.components.CopyComponent"))
local skillIconSmall = import("app.components.SkillIconSmall")
local BUFFS_TYPE = {
	SECOND_POINT = 3,
	FIRST_POINT = 2,
	DEFAULT = 1,
	THIRD_POINT = 4
}
local TYPE_LENGTH = 4

function ActivityExploreOldCampusWaysWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ActivityExploreOldCampusWaysWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	self.itemArr = {}

	self:initUIComponent()
	self:register()
end

function ActivityExploreOldCampusWaysWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.bgImg = self.groupAction:ComponentByName("bgImg", typeof(UISprite))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.buffsScroller = self.groupAction:NodeByName("buffsScroller").gameObject
	self.buffsScroller_uipanel = self.groupAction:ComponentByName("buffsScroller", typeof(UIPanel))
	self.buffsScroller_scrollView = self.groupAction:ComponentByName("buffsScroller", typeof(UIScrollView))
	self.buffsContainer = self.buffsScroller:NodeByName("buffsContainer").gameObject
	self.buffsContainer_layout = self.buffsScroller:ComponentByName("buffsContainer", typeof(UILayout))
	self.tipsCon = self.groupAction:NodeByName("tipsCon").gameObject
	self.awardItem = self.groupAction:NodeByName("awardItem").gameObject
end

function ActivityExploreOldCampusWaysWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_EXPLORE_CAMPUS_3")

	self.awardItem:SetActive(true)

	for i = 1, TYPE_LENGTH do
		local tmp = NGUITools.AddChild(self.buffsContainer.gameObject, self.awardItem.gameObject)
		local item = BuffsItem.new(tmp, i, self)

		table.insert(self.itemArr, item)
	end

	self.awardItem:SetActive(false)
	self.buffsScroller_scrollView:ResetPosition()
	self:updateBuffs()
end

function ActivityExploreOldCampusWaysWindow:updateBuffs()
	for i in pairs(self.itemArr) do
		self.itemArr[i]:updateItemBuffs()
	end
end

function ActivityExploreOldCampusWaysWindow:register()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ActivityExploreOldCampusWaysWindow:showTipsCon(buff_id, posy)
	xyd.WindowManager.get():openWindow("activity_explore_old_campus_ways_alert_window", {
		buff_id = buff_id,
		posy = posy
	})
end

function BuffsItem:ctor(goItem, index, parent)
	self.goItem_ = goItem
	self.parent = parent
	self.index = index
	self.buffsItemArr = {}
	self.goItem_widget = self.goItem_:GetComponent(typeof(UIWidget))
	self.levelLabel = self.goItem_:ComponentByName("levelLabel", typeof(UILabel))
	self.iconGroup = self.goItem_:ComponentByName("iconGroup", typeof(UIGrid))
	self.lineImgRight = self.goItem_:ComponentByName("lineImgRight", typeof(UIWidget))
	self.lineImgLeft = self.goItem_:ComponentByName("lineImgLeft", typeof(UIWidget))

	self:initItem()
	self:initEvent()
end

function BuffsItem:initEvent()
end

function BuffsItem:getItemObj()
	return self.goItem_
end

function BuffsItem:initItem()
	local finalBuffArr = {}
	local buffsArr = xyd.tables.oldBuildingBuffTable:getBuffBelongArr(xyd.models.oldSchool:seasonType())
	local buffTable = xyd.tables.oldBuildingBuffTable
	local maxIndex = xyd.models.oldSchool:getAllInfo().max_index

	for i in pairs(buffsArr) do
		if buffTable:getType(buffsArr[i]) == self.index then
			table.insert(finalBuffArr, {
				buff_id = buffsArr[i],
				point = buffTable:getPoint(buffsArr[i])
			})
		end
	end

	if self.index == BUFFS_TYPE.DEFAULT then
		self.levelLabel.text = __("OLD_SCHOLL_BUFF_NAME1")
	elseif self.index == BUFFS_TYPE.FIRST_POINT then
		self.levelLabel.text = __("OLD_SCHOLL_BUFF_NAME2")
	elseif self.index == BUFFS_TYPE.SECOND_POINT then
		self.levelLabel.text = __("OLD_SCHOLL_BUFF_NAME3")
	elseif self.index == BUFFS_TYPE.THIRD_POINT then
		self.levelLabel.text = __("OLD_SCHOOL_FLOOR_11_TEXT08")
	end

	self.lineImgRight.width = 226 + (86 - self.levelLabel.width) / 2
	self.lineImgLeft.width = self.lineImgRight.width
	self.goItem_widget.height = 46 + math.ceil(#finalBuffArr / 6) * self.iconGroup.cellHeight

	table.sort(finalBuffArr, function (a, b)
		if a.point == b.point then
			return a.buff_id < b.buff_id
		end

		return math.abs(a.point) < math.abs(b.point)
	end)

	for i in pairs(finalBuffArr) do
		local isLock = false
		local lockState = buffTable:needUnlock(tonumber(finalBuffArr[i].buff_id))
		local needPoint = buffTable:getUnlockCost(tonumber(finalBuffArr[i].buff_id))[1]
		local maxIdex = xyd.models.oldSchool:getAllInfo().max_index

		if maxIdex < 8 and self.index == BUFFS_TYPE.THIRD_POINT then
			isLock = true
		elseif lockState and lockState == 1 and tonumber(xyd.models.oldSchool:getAllInfo().max_score) < needPoint then
			isLock = true
		end

		local params = {
			dragScrollView = self.parent.buffsScroller_scrollView,
			callBack = function (buff_id)
				xyd.WindowManager.get():openWindow("activity_explore_old_campus_way_buy_window", {
					id = finalBuffArr[i].buff_id,
					area_id = self.parent.params_.area_id
				})
			end,
			score = finalBuffArr[i].point,
			isLock = isLock,
			tipsCallBack = function (buff_id, posy)
				self.parent:showTipsCon(buff_id, posy)
			end,
			posTransform = self.parent.window_.transform
		}
		local skillIcon = skillIconSmall.new(self.iconGroup.gameObject)

		skillIcon:setInfo(finalBuffArr[i].buff_id, params)

		local arrInfo = {
			icon = skillIcon,
			id = finalBuffArr[i].buff_id
		}

		table.insert(self.buffsItemArr, arrInfo)
	end

	self.iconGroup:Reposition()
end

function BuffsItem:updateItemBuffs()
	for i, value in pairs(self.buffsItemArr) do
		local isLock = false
		local buffTable = xyd.tables.oldBuildingBuffTable
		local lockState = buffTable:needUnlock(tonumber(self.buffsItemArr[i].id))
		local needPoint = buffTable:getUnlockCost(tonumber(self.buffsItemArr[i].id))[1]
		local maxIdex = xyd.models.oldSchool:getAllInfo().max_index

		if maxIdex < 8 and self.index == BUFFS_TYPE.THIRD_POINT then
			isLock = true
		elseif lockState and lockState == 1 and tonumber(xyd.models.oldSchool:getAllInfo().max_score) < needPoint then
			isLock = true
		end

		if isLock == true then
			value.icon:setLock(true)
		else
			value.icon:setLock(false)
		end

		value.icon:setTipsClickOpen(true)
	end
end

return ActivityExploreOldCampusWaysWindow
