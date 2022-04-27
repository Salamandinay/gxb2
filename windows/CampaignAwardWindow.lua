local CampaignAwardWindow = class("CampaignAwardWindow", import(".BaseWindow"))
local AwardItem = class("AwardItem", import("app.components.CopyComponent"))

function AwardItem:ctor(go, parent)
	self.parent_ = parent
	self.items_ = {}

	AwardItem.super.ctor(self, go)
end

function AwardItem:initUI()
	local itemTrans = self.go.transform
	self.btnAward_ = itemTrans:NodeByName("awardBtn").gameObject
	self.btnAwardLabel_ = itemTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.campaignText_ = itemTrans:ComponentByName("campaignText", typeof(UILabel))
	self.awardImg_ = itemTrans:ComponentByName("awardImg", typeof(UISprite))
	self.iconRoot_ = itemTrans:Find("itemsGroup").gameObject
	self.btnAwardLabel_.text = __("GET2")
	UIEventListener.Get(self.btnAward_).onClick = handler(self, self.onClickAward)
end

function AwardItem:update(_, _, params)
	if not params or not params.achievement_id then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id_ = params.achievement_id
	self.isAwarded_ = params.is_awarded
	self.value_ = params.value
	local complete_value = xyd.tables.achievementTable:getCompleteValue(self.id_)

	if self.isAwarded_ and self.isAwarded_ == 1 then
		self.btnAward_:SetActive(false)
		self.awardImg_:SetActive(true)
		xyd.setUISpriteAsync(self.awardImg_, nil, "mission_awarded_" .. tostring(xyd.Global.lang) .. "_png", nil, , true)
	elseif complete_value <= self.value_ then
		self.btnAward_:SetActive(true)
		self.awardImg_:SetActive(false)
		xyd.setEnabled(self.btnAward_, true)
	else
		self.awardImg_:SetActive(false)
		self.btnAward_:SetActive(true)
		xyd.setEnabled(self.btnAward_, false)
	end

	local text = xyd.tables.achievementTypeTable:getDesc(xyd.ACHIEVEMENT_TYPE.CAMPAIGN, complete_value)
	self.campaignText_.text = text

	self:initItems()
end

function AwardItem:initItems()
	local awardItems = xyd.tables.achievementTable:getAward(self.id_)

	NGUITools.DestroyChildren(self.iconRoot_.transform)

	for idx, itemInfo in ipairs(awardItems) do
		self.items_[idx] = xyd.getItemIcon({
			noClickSelected = true,
			hideText = true,
			scale = 0.7962962962962963,
			uiRoot = self.iconRoot_,
			itemID = itemInfo[1],
			num = itemInfo[2],
			dragScrollView = self.parent_.scrollView_
		})
	end

	self:waitForFrame(1, function ()
		self.iconRoot_:GetComponent(typeof(UIGrid)):Reposition()
	end)
end

function AwardItem:onClickAward()
	self.parent_:awardAll()
end

function CampaignAwardWindow:ctor(name, params)
	self.awardItems_ = {}

	CampaignAwardWindow.super.ctor(self, name, params)
end

function CampaignAwardWindow:initWindow()
	CampaignAwardWindow.super.initWindow(self)
	self:getUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "campaign_award_logo_" .. xyd.Global.lang)
	self:updateListInfo()
	self:register()
end

function CampaignAwardWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	local itemPrefab = goTrans:NodeByName("awardItem").gameObject
	self.tipsLabel_ = goTrans:ComponentByName("tipsLabel", typeof(UILabel))
	self.textImg_ = goTrans:ComponentByName("textImg", typeof(UISprite))
	self.scrollView_ = goTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = goTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.missionListWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, itemPrefab, AwardItem, self)
	self.tipsLabel_.text = __("STAGE_ACHIEVEMENT_WINDOW_CLOSE")
end

function CampaignAwardWindow:getNowStage()
	local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)

	if mapInfo then
		return mapInfo.max_stage
	else
		return 0
	end
end

function CampaignAwardWindow:register()
	self.eventProxy_:addEventListener(xyd.event.ACHIEVEMENT_GET_AWARD, handler(self, self.onGetAward))
end

function CampaignAwardWindow:updateListInfo()
	self.listInfo_ = {}
	local achievementData = xyd.models.achievement:getAchievementCampaignData()
	local ids = xyd.tables.achievementTable:getCampaignIds()

	if not achievementData.achieve_id or achievementData.achieve_id == 0 then
		self.finishAll = true
	end

	for idx, id in ipairs(ids) do
		local info = {
			achievement_id = tonumber(id),
			value = achievementData.value,
			is_awarded = xyd.checkCondition(tonumber(id) < tonumber(achievementData.achieve_id) or self.finishAll, 1, 0),
			can_award = xyd.checkCondition(xyd.tables.achievementTable:getCompleteValue(id) <= achievementData.value, 1, 0)
		}

		table.insert(self.listInfo_, info)
	end

	table.sort(self.listInfo_, function (a, b)
		local awight = a.is_awarded * 10000 - a.can_award * 1000 + tonumber(a.achievement_id)
		local bwight = b.is_awarded * 10000 - b.can_award * 1000 + tonumber(b.achievement_id)

		return awight < bwight
	end)
	self.missionListWrap_:setInfos(self.listInfo_, {})

	self.awardItems_ = {}
end

function CampaignAwardWindow:awardAll()
	local needAwardList = {}
	local achievementData = xyd.models.achievement:getAchievementCampaignData()
	local ids = xyd.tables.achievementTable:getCampaignIds()

	if not achievementData.achieve_id or achievementData.achieve_id == 0 then
		return
	end

	for idx, id in ipairs(ids) do
		if achievementData.achieve_id <= tonumber(id) then
			local complete_value = xyd.tables.achievementTable:getCompleteValue(id)

			if complete_value <= achievementData.value then
				table.insert(needAwardList, tonumber(id))
			end
		end
	end

	table.sort(needAwardList)

	self.needAwardList_ = needAwardList

	self:reqNextAward()
end

function CampaignAwardWindow:onGetAward(event)
	local data = event.params.data
	local achievement_type = data.achieve_type

	if achievement_type ~= xyd.ACHIEVEMENT_TYPE.CAMPAIGN then
		return
	end

	local achieveID = data.old_id
	local awrads = xyd.tables.achievementTable:getAward(achieveID)

	for _, info in ipairs(awrads) do
		local item = {
			item_id = info[1],
			item_num = info[2]
		}

		table.insert(self.awardItems_, item)
	end

	for idx, id in ipairs(self.needAwardList_) do
		if id == tonumber(achieveID) then
			table.remove(self.needAwardList_, idx)
		end
	end

	if #self.needAwardList_ <= 0 then
		xyd.models.itemFloatModel:pushNewItems(self.awardItems_)
		self:updateListInfo()

		local win = xyd.WindowManager.get():getWindow("campaign_window")

		if win then
			win:checkCampaignRedState()
		end
	else
		self:reqNextAward()
	end
end

function CampaignAwardWindow:reqNextAward()
	xyd.models.achievement:getAward(xyd.ACHIEVEMENT_TYPE.CAMPAIGN)
end

return CampaignAwardWindow
