local CampaignHangItemWindow = class("CampaignHangItemWindow", import(".BaseWindow"))

function CampaignHangItemWindow:ctor(name, params)
	CampaignHangItemWindow.super.ctor(self, name, params)

	self.callback = nil
	self.groupBuffTable = xyd.tables.groupBuffTable
	self.SlotModel = xyd.models.slot
	self.mapsModel = xyd.models.map
	self.StageTable = xyd.tables.stageTable
	self.FortTable = xyd.tables.fortTable
	self.stageId = params.stageId
end

function CampaignHangItemWindow:initWindow()
	CampaignHangItemWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.mainGroup = winTrans:Find("main")
	self.getItemBtn = self.mainGroup:Find("get_item_btn").gameObject
	self.buttonLabel = self.mainGroup:ComponentByName("get_item_btn/button_label", typeof(UILabel))
	self.labelWinTitle = self.mainGroup:ComponentByName("title_label", typeof(UILabel))
	self.containerGroup = self.mainGroup:Find("container_group")
	self.itemListScroller = self.containerGroup:ComponentByName("item_list_scroller", typeof(UIScrollView))
	self.itemListGrid = self.containerGroup:ComponentByName("item_list_scroller/item_list_grid", typeof(UIGrid))

	self:initLayOut()
	self.mapsModel:getHangItem(2)
end

function CampaignHangItemWindow:initLayOut()
	self.buttonLabel.text = __("GET2")
	UIEventListener.Get(self.getItemBtn).onClick = handler(self, self.onClickStageHang)
	self.mapInfo = self.mapsModel:getMapInfo(xyd.MapType.CAMPAIGN)
	local dropItems = self.mapInfo.drop_items

	if #dropItems > 0 then
		local activityItemMap = self:getActivityItemMap()

		table.sort(dropItems, function (a, b)
			local actIda = activityItemMap[a.item_id] or 0
			local actIdb = activityItemMap[b.item_id] or 0

			if actIda > 0 and actIdb > 0 or actIda == 0 and actIdb == 0 then
				return b.item_id < a.item_id
			else
				return actIda > 0
			end
		end)

		self.itemIconList = {}

		for _, itemData in ipairs(dropItems) do
			local itemId = itemData.item_id
			local itemNum = itemData.item_num
			local itemIcon = xyd.getItemIcon({
				showSellLable = false,
				itemID = itemId,
				num = itemNum,
				uiRoot = self.itemListGrid.gameObject,
				dragScrollView = self.itemListScroller,
				activityTag = activityItemMap[itemData.item_id],
				wndType = xyd.ItemTipsWndType.CAMPAIGN_HANG
			})

			table.insert(self.itemIconList, itemIcon)
		end

		self.itemListGrid:Reposition()
		self.itemListScroller:ResetPosition()
	end
end

function CampaignHangItemWindow:onClickStageHang()
	xyd.closeWindow(self.name_)
end

function CampaignHangItemWindow:willClose()
	CampaignHangItemWindow.super.willClose(self)
end

function CampaignHangItemWindow:getActivityItemMap()
	local activityItemMap = {}
	local actIds, tmpIds = nil
	tmpIds = xyd.split(xyd.tables.stageTable:getDropShowActivity(self.stageId), "|", true)
	actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox", "value", "|")

	for _, itemID in pairs(tmpIds) do
		activityItemMap[itemID] = actIds[1]
	end

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			break
		end
	end

	tmpIds = xyd.split(xyd.tables.stageTable:getDropShowActivity2(self.stageId), "|", true)
	actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox2", "value", "|")

	for _, itemID in pairs(tmpIds) do
		activityItemMap[itemID] = actIds[1]
	end

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			break
		end
	end

	tmpIds = xyd.split(xyd.tables.stageTable:getDropShowActivity3(self.stageId), "|", true)
	actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox3", "value", "|")

	for _, itemID in pairs(tmpIds) do
		activityItemMap[itemID] = actIds[1]
	end

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			break
		end
	end

	tmpIds = xyd.split(xyd.tables.stageTable:getDropShowActivity4(self.stageId), "|", true)
	actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox4", "value", "|")

	for _, itemID in pairs(tmpIds) do
		activityItemMap[itemID] = actIds[1]
	end

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			break
		end
	end

	return activityItemMap
end

return CampaignHangItemWindow
