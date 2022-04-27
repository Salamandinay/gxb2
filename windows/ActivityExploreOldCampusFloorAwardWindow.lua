local BaseWindow = import(".BaseWindow")
local ActivityExploreOldCampusFloorAwardWindow = class("ActivityExploreOldCampusFloorAwardWindow", BaseWindow)
local ShowAwardItem = class("ShowAwardItem", import("app.components.CopyComponent"))

function ActivityExploreOldCampusFloorAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ActivityExploreOldCampusFloorAwardWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	self.itemArr = {}
	self.canGetIds = {}

	self:initUIComponent()
	self:register()
end

function ActivityExploreOldCampusFloorAwardWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.groupAction_widget = trans:ComponentByName("groupAction", typeof(UIWidget))
	self.bgImg = self.groupAction:ComponentByName("bgImg", typeof(UISprite))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.exlpainLabel = self.groupAction:ComponentByName("exlpainLabel", typeof(UILabel))
	self.awardGroup = self.groupAction:ComponentByName("awardGroup", typeof(UILayout))
	self.awardItem = self.groupAction:NodeByName("awardItem").gameObject
	self.eImage_ = self.groupAction:ComponentByName("e:image", typeof(UISprite))
end

function ActivityExploreOldCampusFloorAwardWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_AWARD_PREVIEW")
	self.exlpainLabel.text = __("OLD_SCHOOL_FLOOR_GET_AWARD_TEXT")
	local floorLevelIds = xyd.models.oldSchool:getOldBuildingTableTable():getStage(self.params_.floor_id)
	self.groupAction_widget.height = #floorLevelIds * 100 + 200
	local passNum = 0
	passNum = self.params_.complete_num

	self.awardItem:SetActive(true)

	for i in pairs(floorLevelIds) do
		local tmp = NGUITools.AddChild(self.awardGroup.gameObject, self.awardItem.gameObject)
		local isReceive = false

		if xyd.models.oldSchool:getAllInfo().floor_infos[self.params_.floor_id].awards[i] == 1 then
			isReceive = true
		end

		local isCanGetAward = false

		if i <= passNum and isReceive == false then
			isCanGetAward = true

			table.insert(self.canGetIds, i)
		end

		local item = ShowAwardItem.new(tmp, i, floorLevelIds[i], self, isReceive, isCanGetAward)

		table.insert(self.itemArr, item)
	end

	if #self.itemArr == 3 then
		self.eImage_.height = 330
	else
		self.eImage_.height = 230
	end

	self.awardItem:SetActive(false)

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ActivityExploreOldCampusFloorAwardWindow:register()
end

function ActivityExploreOldCampusFloorAwardWindow:updateAwardBack(event)
	if event.data.floor_id ~= tonumber(self.params_.floor_id) then
		return
	end

	local dataInfo = xyd.decodeProtoBuf(event.data)

	for i in pairs(dataInfo.indexes) do
		self.itemArr[dataInfo.indexes[i]].isCanGetAward = false
		self.itemArr[dataInfo.indexes[i]].isReceive = true

		self.itemArr[dataInfo.indexes[i]]:updateItemState()
	end
end

function ShowAwardItem:ctor(goItem, index, levelId, parent, isReceive, isCanGetAward)
	self.goItem_ = goItem
	self.levelId = levelId
	self.index = index
	self.parent = parent
	self.isReceive = isReceive
	self.isCanGetAward = isCanGetAward
	self.itemArr = {}
	self.levelLabel = self.goItem_:ComponentByName("levelLabel", typeof(UILabel))
	self.iconGroup = self.goItem_:ComponentByName("iconGroup", typeof(UILayout))

	self:initItem(levelId)
	self:initEvent(levelId)
end

function ShowAwardItem:initEvent(levelId)
end

function ShowAwardItem:getItemObj()
	return self.goItem_
end

function ShowAwardItem:initItem(levelId)
	self.levelLabel.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_COMPLETE_LEVELS", self.index)
	local awardsArr = xyd.models.oldSchool:getOldBuildingTableTable():getAwards(self.parent.params_.floor_id)
	local selfAwardArr = awardsArr[self.index]

	for i in pairs(selfAwardArr) do
		local item = {
			show_has_num = true,
			scale = 0.6481481481481481,
			isShowSelected = false,
			itemID = selfAwardArr[i][1],
			num = selfAwardArr[i][2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			uiRoot = self.iconGroup.gameObject
		}
		local icon = xyd.getItemIcon(item)

		table.insert(self.itemArr, icon)

		if self.isReceive == true then
			icon:setChoose(true)
		end
	end

	self:updateItemState()
	self.iconGroup:Reposition()
end

function ShowAwardItem:updateItemState()
	for i, icon in pairs(self.itemArr) do
		if self.isCanGetAward == true then
			function icon.callback()
				if xyd.models.oldSchool:getChallengeEndTime() <= xyd.getServerTime() then
					xyd.alertTips(__("ACTIVITY_END_YET"))

					return
				end

				local msg = messages_pb:old_building_get_floor_award_req()
				msg.table_id = self.parent.params_.floor_id

				for k in pairs(self.parent.canGetIds) do
					table.insert(msg.indexes, self.parent.canGetIds[k])
				end

				xyd.Backend.get():request(xyd.mid.OLD_BUILDING_GET_FLOOR_AWARD, msg)
			end

			local effect = "fx_ui_bp_available"

			icon:setEffect(true, effect, {
				effectPos = Vector3(0, 5, 0)
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

return ActivityExploreOldCampusFloorAwardWindow
