local CampaignStageDetailWindow = class("CampaignStageDetailWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")

function CampaignStageDetailWindow:ctor(name, params)
	CampaignStageDetailWindow.super.ctor(self, name, params)

	self.callback = nil
	self.groupBuffTable = xyd.tables.groupBuffTable
	self.SlotModel = xyd.models.slot
	self.mapsModel = xyd.models.map
	self.StageTable = xyd.tables.stageTable
	self.FortTable = xyd.tables.fortTable
	self.needBtn_ = true

	if params.needBtn_ == false then
		self.needBtn_ = params.needBtn_
	end

	self.stageId = params.stageId
end

function CampaignStageDetailWindow:initWindow()
	CampaignStageDetailWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.mainGroup = winTrans:Find("main_group")
	self.closeBtn = self.mainGroup:Find("close_btn").gameObject
	self.stageNameLabel = self.mainGroup:ComponentByName("stage_name_label", typeof(UILabel))
	local title1Group = self.mainGroup:Find("title1")
	self.stageRes1Label = title1Group:ComponentByName("stage_res1_label", typeof(UILabel))
	local title2Group = self.mainGroup:Find("title2")
	self.stageRes2Label = title2Group:ComponentByName("stage_res2_label", typeof(UILabel))

	if xyd.Global.lang == "ja_jp" then
		self.stageRes1Label.width = 144

		title1Group:NodeByName("imgLine0").gameObject:X(-80)
		title1Group:NodeByName("imgLine1").gameObject:X(80)

		self.stageRes2Label.width = 192

		title2Group:NodeByName("imgLine0").gameObject:X(-100)
		title2Group:NodeByName("imgLine1").gameObject:X(100)
	elseif xyd.Global.lang == "ko_kr" then
		self.stageRes1Label.width = 126

		title1Group:NodeByName("imgLine0").gameObject:X(-71)
		title1Group:NodeByName("imgLine1").gameObject:X(71)

		self.stageRes2Label.width = 122

		title2Group:NodeByName("imgLine0").gameObject:X(-65)
		title2Group:NodeByName("imgLine1").gameObject:X(65)
	end

	local topGroup = self.mainGroup:Find("top_group")
	local bottomGroup = self.mainGroup:Find("bottom_group")
	self.goldGroup = topGroup:Find("gold_group")
	self.pexpGroup = topGroup:Find("pexp_group")
	self.expGroup = topGroup:Find("exp_group")
	self.layout1 = self.goldGroup:ComponentByName("iconGroup", typeof(UILayout))
	self.upIcon1 = self.goldGroup:NodeByName("iconGroup/upIcon").gameObject
	self.layout2 = self.pexpGroup:ComponentByName("iconGroup", typeof(UILayout))
	self.upIcon2 = self.pexpGroup:NodeByName("iconGroup/upIcon").gameObject
	self.layout3 = self.expGroup:ComponentByName("iconGroup", typeof(UILayout))
	self.upIcon3 = self.expGroup:NodeByName("iconGroup/upIcon").gameObject
	self.goldImg = self.goldGroup:ComponentByName("iconGroup/gold_img", typeof(UISprite))
	self.goldNumLabel = self.goldGroup:ComponentByName("gold_num_label", typeof(UILabel))
	self.pexpNumLabel = self.pexpGroup:ComponentByName("pexp_num_label", typeof(UILabel))
	self.expNumLabel = self.expGroup:ComponentByName("exp_num_label", typeof(UILabel))
	self.goldPlusLabel = self.goldGroup:ComponentByName("gold_plus_label", typeof(UILabel))
	self.pexpPlusLabel = self.pexpGroup:ComponentByName("pexp_plus_label", typeof(UILabel))
	self.expPlusLabel = self.expGroup:ComponentByName("exp_plus_label", typeof(UILabel))
	self.stageHangBtn = bottomGroup:Find("stage_hang_btn").gameObject
	self.stageHangBtnLabel = self.stageHangBtn:ComponentByName("button_label", typeof(UILabel))
	self.itemScroller = bottomGroup:ComponentByName("item_scroller", typeof(UIScrollView))
	self.itemTable = bottomGroup:ComponentByName("item_scroller/item_table", typeof(UIGrid))

	self:register()

	self.mapInfo = self.mapsModel:getMapInfo(xyd.MapType.CAMPAIGN)

	self:initLayOut()
	self:initDropList()
	self:updateUpIcon()
end

function CampaignStageDetailWindow:updateUpIcon()
	for i = 1, 2 do
		if xyd.models.activity:isResidentReturnAddTime() then
			self["upIcon" .. i]:SetActive(xyd.models.activity:isResidentReturnAddTime())

			local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.HANG_UP)

			xyd.setUISpriteAsync(self["upIcon" .. i].gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_" .. return_multiple, nil, , )
		else
			self["upIcon" .. i]:SetActive(xyd.getReturnBackIsDoubleTime())
			xyd.setUISpriteAsync(self["upIcon" .. i].gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_2", nil, , )
		end

		self["layout" .. i]:Reposition()
	end

	self:changeShowText()
end

function CampaignStageDetailWindow:register()
	CampaignStageDetailWindow.super.register(self)

	UIEventListener.Get(self.stageHangBtn).onClick = handler(self, self.onClickStageHang)
end

function CampaignStageDetailWindow:initLayOut()
	if self.needBtn_ == false then
		self.stageHangBtn:SetActive(false)
	else
		self.stageHangBtn:SetActive(true)
	end

	local fortId = self.StageTable:getFortID(self.stageId)
	self.stageNameLabel.text = __("STAGE_NAME", fortId, self.StageTable:getName(self.stageId))
	self.stageRes1Label.text = __("STAGE_RES")
	self.stageRes2Label.text = __("STAGE_ITEM")

	self:solvePlusEffect()

	self.stageHangBtnLabel.text = __("STAGE_HANG")
end

function CampaignStageDetailWindow:changeShowText()
	local goldData = xyd.split(self.StageTable:getGold(self.stageId), "#")
	local pExpData = xyd.split(self.StageTable:getExpPartner(self.stageId), "#")
	local expData = xyd.split(self.StageTable:getExpPlayer(self.stageId), "#")
	local goldNum = goldData[2]
	local expNum = pExpData[2]
	local returnBackData = xyd.models.activity:getActivity(xyd.ActivityID.RETURN)

	if xyd.models.activity:isResidentReturnAddTime() then
		-- Nothing
	elseif xyd.getReturnBackIsDoubleTime() then
		goldNum = goldNum * 2
		expNum = expNum * 2
	end

	self.goldNumLabel.text = __("STAGE_RES_NUM", goldNum)
	self.pexpNumLabel.text = __("STAGE_RES_NUM", expNum)
	self.expNumLabel.text = __("STAGE_RES_NUM", expData[2])
end

function CampaignStageDetailWindow:solvePlusEffect()
	local goldData = xyd.split(self.StageTable:getGold(self.stageId), "#")
	local pExpData = xyd.split(self.StageTable:getExpPartner(self.stageId), "#")
	local expData = xyd.split(self.StageTable:getExpPlayer(self.stageId), "#")
	local goldNum = goldData[2]
	local expNum = pExpData[2]
	local returnBackData = xyd.models.activity:getActivity(xyd.ActivityID.RETURN)

	if xyd.models.activity:isResidentReturnAddTime() then
		-- Nothing
	elseif xyd.getReturnBackIsDoubleTime() then
		goldNum = goldNum * 2
		expNum = expNum * 2
	end

	local vip_lev = xyd.models.backpack:getVipLev()
	self.goldNumLabel.text = __("STAGE_RES_NUM", goldNum)
	self.pexpNumLabel.text = __("STAGE_RES_NUM", expNum)
	self.expNumLabel.text = __("STAGE_RES_NUM", expData[2])
	local goldPlus = 0
	local pexpPlus = 0
	local expPlus = 0

	if vip_lev >= 1 then
		local count = tonumber(xyd.tables.vipTable:extraOutput(vip_lev))

		self.stageNameLabel:Y(340)

		self.mainGroup:GetComponent(typeof(UIWidget)).height = self.mainGroup:GetComponent(typeof(UIWidget)).height + 27
		self.goldGroup:GetComponent(typeof(UIWidget)).height = self.goldGroup:GetComponent(typeof(UIWidget)).height + 27
		self.pexpGroup:GetComponent(typeof(UIWidget)).height = self.pexpGroup:GetComponent(typeof(UIWidget)).height + 27
		self.expGroup:GetComponent(typeof(UIWidget)).height = self.expGroup:GetComponent(typeof(UIWidget)).height + 27
		self.goldPlusLabel.text = __("STAGE_OUTPUT_ADDITION_VIP", xyd.round(count * 100)) .. "\n"
		self.pexpPlusLabel.text = __("STAGE_OUTPUT_ADDITION_VIP", xyd.round(count * 100)) .. "\n"
		self.expPlusLabel.text = __("STAGE_OUTPUT_ADDITION_VIP", xyd.round(count * 100)) .. "\n"
		goldPlus = goldPlus + count
		pexpPlus = pexpPlus + count
		expPlus = expPlus + count
	end

	local cardInfo = xyd.models.activity:getActivity(xyd.ActivityID.MANA_WEEK_CARD)

	if xyd.models.activity:isManaCardPurchased() then
		self.stageNameLabel:Y(340)

		self.mainGroup:GetComponent(typeof(UIWidget)).height = self.mainGroup:GetComponent(typeof(UIWidget)).height + 27
		self.goldGroup:GetComponent(typeof(UIWidget)).height = self.goldGroup:GetComponent(typeof(UIWidget)).height + 27
		self.pexpGroup:GetComponent(typeof(UIWidget)).height = self.pexpGroup:GetComponent(typeof(UIWidget)).height + 27
		self.expGroup:GetComponent(typeof(UIWidget)).height = self.expGroup:GetComponent(typeof(UIWidget)).height + 27
		goldPlus = goldPlus + xyd.tables.miscTable:getNumber("subscription_rate_gold", "value")
		pexpPlus = pexpPlus + xyd.tables.miscTable:getNumber("subscription_rate_juice", "value")
		self.goldImg.transform.localScale = Vector3.one
		self.goldPlusLabel.text = self.goldPlusLabel.text .. __("STAGE_OUTPUT_ADDITION_SUB", xyd.round(xyd.tables.miscTable:getNumber("subscription_rate_gold", "value") * 100))
		self.pexpPlusLabel.text = self.pexpPlusLabel.text .. __("STAGE_OUTPUT_ADDITION_SUB", xyd.round(xyd.tables.miscTable:getNumber("subscription_rate_juice", "value") * 100))

		xyd.setUISpriteAsync(self.goldImg, xyd.Atlas.CAMPAIGIN, "weekly_card_icon")
	else
		self.goldImg.transform.localScale = Vector3.one * 0.7

		xyd.setUISpriteAsync(self.goldImg, xyd.Atlas.ICON, "icon_1")
	end
end

function CampaignStageDetailWindow:onClickStageHang()
	self.mapsModel:hang(self.stageId)
	xyd.closeWindow(self.name_)
end

function CampaignStageDetailWindow:initDropList()
	NGUITools.DestroyChildren(self.itemTable.transform)

	local idList = xyd.split(self.StageTable:getDropShow(self.stageId), "|")
	local actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox3", "value", "|")
	local found = false
	local activityItemMap = {}

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			local tmpIds = xyd.split(self.StageTable:getDropShowActivity3(self.stageId), "|", true)

			table.insertto(idList, tmpIds)

			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			found = true

			break
		end
	end

	actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox2", "value", "|")

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			local tmpIds = xyd.split(self.StageTable:getDropShowActivity2(self.stageId), "|", true)

			table.insertto(idList, tmpIds)

			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			found = true

			break
		end
	end

	actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox", "value", "|")

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			local tmpIds = xyd.split(self.StageTable:getDropShowActivity(self.stageId), "|", true)

			table.insertto(idList, tmpIds)

			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			break
		end
	end

	actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox4", "value", "|")

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			local tmpIds = xyd.split(self.StageTable:getDropShowActivity4(self.stageId), "|", true)

			table.insertto(idList, tmpIds)

			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			break
		end
	end

	table.sort(idList, function (a, b)
		local actIda = activityItemMap[a] or 0
		local actIdb = activityItemMap[b] or 0

		if actIda > 0 and actIdb > 0 or actIda == 0 and actIdb == 0 then
			return b < a
		else
			return actIda > 0
		end
	end)

	self.itemIconList = {}

	for _, itemId in ipairs(idList) do
		if tonumber(itemId) > 0 then
			local itemIcon = xyd.getItemIcon({
				showSellLable = false,
				itemID = itemId,
				uiRoot = self.itemTable.gameObject,
				dragScrollView = self.itemScroller,
				activityTag = activityItemMap[itemId],
				wndType = xyd.ItemTipsWndType.CAMPAIGN_HANG
			})

			table.insert(self.itemIconList, itemIcon)
		end
	end

	self.itemTable:Reposition()
	self.itemScroller:ResetPosition()
end

function CampaignStageDetailWindow:willClose()
	CampaignStageDetailWindow.super.willClose(self)
end

function CampaignStageDetailWindow:iosTestChangeUI()
	xyd.setUISprite(self.mainGroup:ComponentByName("bgImg4", typeof(UISprite)), nil, "9gongge21_ios_test")
	xyd.setUISprite(self.closeBtn:GetComponent(typeof(UISprite)), nil, "close_btn_2_ios_test")
	xyd.setUISprite(self.mainGroup:ComponentByName("title1/imgLine0", typeof(UISprite)), nil, "trial_line_ios_test")
	xyd.setUISprite(self.mainGroup:ComponentByName("title1/imgLine1", typeof(UISprite)), nil, "trial_line_ios_test")
	xyd.setUISprite(self.mainGroup:ComponentByName("title2/imgLine0", typeof(UISprite)), nil, "trial_line_ios_test")
	xyd.setUISprite(self.mainGroup:ComponentByName("title2/imgLine1", typeof(UISprite)), nil, "trial_line_ios_test")
	xyd.iosSetUISprite(self.goldGroup:ComponentByName("e:Image", typeof(UISprite)), "guild_bg06_ios_test")
	xyd.iosSetUISprite(self.expGroup:ComponentByName("e:Image", typeof(UISprite)), "guild_bg06_ios_test")
	xyd.iosSetUISprite(self.pexpGroup:ComponentByName("e:Image", typeof(UISprite)), "guild_bg06_ios_test")
	xyd.setUISprite(self.stageHangBtn:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65_ios_test")
	xyd.setUISprite(self.mainGroup:ComponentByName("bottom_group/e:Image", typeof(UISprite)), nil, "9gongge23_ios_test")
end

return CampaignStageDetailWindow
