local BaseWindow = import(".BaseWindow")
local ActivityGrowthPlanChoosePartnerWindow = class("ActivityGrowthPlanChoosePartnerWindow", BaseWindow)
local ActivityGrowthPlanChoosePartnerItem = class("ActivityGrowthPlanChoosePartnerItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ativityGrowthPlanTable = xyd.tables.ativityGrowthPlanTable
local PartnerCard = import("app.components.PartnerCard")
local activityID = xyd.ActivityID.ACTIVITY_GROWTH_PLAN

function ActivityGrowthPlanChoosePartnerWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	if params and params.ActivityID and params.ActivityID == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
		activityID = xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN
	else
		activityID = xyd.ActivityID.ACTIVITY_GROWTH_PLAN
	end

	if activityID == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
		self.preText = "ACTIVITY_NEW_GROWTH_PLAN_TEXT"
	else
		self.preText = "ACTIVITY_GROWTH_PLAN_TEXT"
	end
end

function ActivityGrowthPlanChoosePartnerWindow:initWindow()
	ActivityGrowthPlanChoosePartnerWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(activityID)

	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function ActivityGrowthPlanChoosePartnerWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.content = groupAction:NodeByName("content").gameObject
	self.labelTip = self.content:ComponentByName("labelTip", typeof(UILabel))
	self.contentGroup = self.content:NodeByName("contentGroup").gameObject
	self.awardContentGroup = self.contentGroup:NodeByName("awardContentGroup").gameObject
	self.scroller = self.awardContentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.itemGroupLayout = self.scroller:ComponentByName("itemGroup", typeof(UILayout))
	self.item = self.scroller:NodeByName("item").gameObject
end

function ActivityGrowthPlanChoosePartnerWindow:initUIComponent()
	self.labelTitle_.text = __(self.preText .. "03")
	self.labelTip.text = __(self.preText .. "02")
	local ids = xyd.tables.miscTable:split2Cost("activity_growth_plan_partner", "value", "|")

	if activityID == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
		dump(ids)

		ids = xyd.tables.miscTable:split2Cost("activity_new_growth_plan_partner", "value", "|")
	end

	dump(ids)

	local datas = {}

	for i = 1, #ids do
		local id = ids[i]
		local data = {
			partnerID = id
		}

		table.insert(datas, data)
	end

	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, self.item, ActivityGrowthPlanChoosePartnerItem, self)

	self.wrapContent:setInfos(datas, {})
end

function ActivityGrowthPlanChoosePartnerWindow:register()
	ActivityGrowthPlanChoosePartnerWindow.super.register(self)
end

function ActivityGrowthPlanChoosePartnerItem:ctor(go, parent)
	ActivityGrowthPlanChoosePartnerItem.super.ctor(self, go, parent)

	self.baseItems = {}
	self.extraItems = {}
	self.parent = parent
end

function ActivityGrowthPlanChoosePartnerItem:initUI()
	local go = self.go
	self.bg_ = go:ComponentByName("bg_", typeof(UISprite))
	self.labeDesc = go:ComponentByName("descScroller/labeDesc", typeof(UILabel))
	self.labeTitle = go:ComponentByName("labeTitle", typeof(UILabel))
	self.cardNode = go:NodeByName("cardNode").gameObject
	self.btnSelect = go:NodeByName("btnSelect").gameObject
	self.clickMask = go:NodeByName("clickMask").gameObject
	self.label = self.btnSelect:ComponentByName("label", typeof(UILabel))

	self.cardNode.transform:SetLocalScale(1, 1, 1)

	self.partnerCard = PartnerCard.new(self.cardNode, self.parent.renderPanel)
	self.activityData = xyd.models.activity:getActivity(activityID)

	UIEventListener.Get(self.clickMask).onClick = function ()
		local params = {
			partners = {
				{
					table_id = self.partnerID
				}
			},
			table_id = self.partnerID
		}

		xyd.WindowManager.get():openWindow("guide_detail_window", params)
	end

	UIEventListener.Get(self.btnSelect).onClick = function ()
		self.activityData:choosePartner(self.partnerID)
		xyd.WindowManager.get():closeWindow("activity_growth_plan_choose_partner_window")
	end
end

function ActivityGrowthPlanChoosePartnerItem:updateInfo()
	self.partnerID = self.data.partnerID
	local partner = xyd.models.slot:getPartner(self.partnerID)
	local info = {
		awake = 3,
		tableID = self.partnerID,
		star = xyd.tables.partnerTable:getStar(self.partnerID),
		lev = xyd.tables.partnerTable:getMaxlev(self.partnerID),
		grade = xyd.tables.partnerTable:getMaxGrade(self.partnerID)
	}

	self.partnerCard:setInfo(info)

	self.label.text = __(self.parent.preText .. "03")
	self.labeTitle.text = __("PARTNER_STATION_DESC_TITLE")
	local comment_id = xyd.tables.partnerTable:getCommentID(self.partnerID)
	self.labeDesc.text = xyd.tables.partnerDirectTable:getDesc(comment_id)

	if xyd.Global.lang == "ko_kr" then
		self.labeDesc.text = xyd.replaceSpace(xyd.tables.partnerDirectTable:getDesc(comment_id))
	end
end

return ActivityGrowthPlanChoosePartnerWindow
