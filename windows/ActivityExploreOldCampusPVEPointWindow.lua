local BaseWindow = import(".BaseWindow")
local ActivityExploreOldCampusPVEPointWindow = class("ActivityExploreOldCampusPVEPointWindow", BaseWindow)
local AwardItem = class("AwardItem", import("app.components.CopyComponent"))
local PlayerIcon = import("app.components.PlayerIcon")

function ActivityExploreOldCampusPVEPointWindow:ctor(name, params)
	ActivityExploreOldCampusPVEPointWindow.super.ctor(self, name, params)
end

function ActivityExploreOldCampusPVEPointWindow:initWindow()
	ActivityExploreOldCampusPVEPointWindow.super.initWindow(self)

	self.itemArr = {}
	self.canGetIds = {}

	self:getUIComponent()
	self:initData()
end

function ActivityExploreOldCampusPVEPointWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("groupAction").gameObject
	self.labelWinTitle_ = groupMain:ComponentByName("labelWinTitle", typeof(UILabel))
	self.descTitle_ = groupMain:ComponentByName("descTitle", typeof(UILabel))
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite))
	local group1 = groupMain:NodeByName("group1").gameObject
	self.scroller_ = group1:ComponentByName("scroller", typeof(UIScrollView))
	self.scroller_UIpanel = group1:ComponentByName("scroller", typeof(UIPanel))
	self.grid_ = self.scroller_:ComponentByName("grid", typeof(UIGrid))
	self.itemRoot = group1:NodeByName("awardItem").gameObject

	UIEventListener.Get(self.closeBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.labelWinTitle_.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_AWARD_PREVIEW")
	self.descTitle_.text = __("OLD_SCHOOL_SCORE_GET_AWARD_TEXT")
end

function ActivityExploreOldCampusPVEPointWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityExploreOldCampusPVEPointWindow:initData()
	local ids = xyd.models.oldSchool:getOldBuildingAward1Table():getIds()

	for _, id in ipairs(ids) do
		local params = {
			isCanGetAward = false,
			isReceive = false,
			id = id,
			award = xyd.models.oldSchool:getOldBuildingAward1Table():getAwards(id),
			point = xyd.models.oldSchool:getOldBuildingAward1Table():getPoint(id)
		}

		if params.point <= tonumber(xyd.models.oldSchool:getAllInfo().score) then
			if xyd.models.oldSchool:getAllInfo().awards[id] == 0 then
				table.insert(self.canGetIds, id)

				params.isCanGetAward = true
			else
				params.isReceive = true
			end
		end

		local go = NGUITools.AddChild(self.grid_.gameObject, self.itemRoot)
		local awardItem = AwardItem.new(go, self)

		awardItem:setInfo(params)
		table.insert(self.itemArr, awardItem)
	end

	self.grid_:Reposition()
	self.scroller_:ResetPosition()
end

function ActivityExploreOldCampusPVEPointWindow:updateAwardBack(event)
	local dataInfo = xyd.decodeProtoBuf(event.data)

	for i in pairs(dataInfo.table_ids) do
		self.itemArr[dataInfo.table_ids[i]].isCanGetAward = false
		self.itemArr[dataInfo.table_ids[i]].isReceive = true

		self.itemArr[dataInfo.table_ids[i]]:updateItemState()
	end
end

function AwardItem:ctor(go, parent)
	AwardItem.super.ctor(self, go)

	self.parent = parent
end

function AwardItem:initUI()
	self:getUIComponent()
end

function AwardItem:getUIComponent()
	self.pointLabel_ = self.go:ComponentByName("pointText", typeof(UILabel))
	self.awardGrid_ = self.go:ComponentByName("awardGroup", typeof(UIGrid))
end

function AwardItem:setInfo(date)
	if not date then
		self.go:SetActive(false)

		return
	end

	self.itemArr = {}
	self.info = date
	self.isCanGetAward = self.info.isCanGetAward
	self.isReceive = self.info.isReceive

	self.go:SetActive(true)

	self.pointLabel_.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_REACH_SCORE", date.point)
	self.awardsData = date.award

	for i = 1, #self.awardsData do
		local itemData = self.awardsData[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			uiRoot = self.awardGrid_.gameObject,
			itemID = itemId,
			dragScrollView = self.parent.scroller_,
			num = itemNum
		})

		itemIcon:SetLocalScale(0.72, 0.72, 1)
		table.insert(self.itemArr, itemIcon)
	end

	self.awardGrid_:Reposition()
	self:updateItemState()
end

function AwardItem:updateItemState()
	for i, icon in pairs(self.itemArr) do
		if self.isCanGetAward == true then
			function icon.callback()
				if xyd.models.oldSchool:getChallengeEndTime() <= xyd.getServerTime() then
					xyd.alertTips(__("ACTIVITY_END_YET"))

					return
				end

				local msg = messages_pb:old_building_get_score_award_req()

				for k in pairs(self.parent.canGetIds) do
					table.insert(msg.table_ids, self.parent.canGetIds[k])
				end

				xyd.Backend.get():request(xyd.mid.OLD_BUILDING_GET_SCORE_AWARD, msg)
			end

			local effect = "fx_ui_bp_available"

			icon:setEffect(true, effect, {
				effectPos = Vector3(0, 5, 0),
				panel_ = self.parent.scroller_UIpanel
			})
		else
			icon.callback = nil

			icon:setEffectState(false)

			if self.isReceive == true then
				icon:setChoose(true)
			end
		end
	end
end

return ActivityExploreOldCampusPVEPointWindow
