local ActivityPartnerGalleryDetailWindow = class("ActivityPartnerGalleryDetailWindow", import(".BaseWindow"))
local FormationItem = class("FormationItem", import("app.common.ui.FixedMultiWrapContentItem"))
local HeroIcon = import("app.components.HeroIcon")
local PartnerFilter = import("app.components.PartnerFilter")
local pTable = xyd.tables.activityPartnerGalleryPointTable

function ActivityPartnerGalleryDetailWindow:ctor(name, params)
	ActivityPartnerGalleryDetailWindow.super.ctor(self, name, params)

	self.score = params.score
end

function ActivityPartnerGalleryDetailWindow:initWindow()
	self:getUIComponent()
	self:layout()
end

function ActivityPartnerGalleryDetailWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local groupPoint = groupAction:NodeByName("groupPoint").gameObject
	self.labelCurPoint = groupPoint:ComponentByName("labelCurPoint", typeof(UILabel))
	self.progress = groupPoint:ComponentByName("progress", typeof(UISlider))
	self.progressLabel = self.progress:ComponentByName("progressLabel", typeof(UILabel))
	self.scroller = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	local groupContent = self.scroller:ComponentByName("groupContent", typeof(UIWrapContent))
	local itemRoot = groupAction:NodeByName("itemRoot").gameObject
	self.wrapContent_ = import("app.common.ui.FixedMultiWrapContent").new(self.scroller, groupContent, itemRoot, FormationItem, self)
	self.filterGroup = groupAction:NodeByName("filterGroup").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
end

function ActivityPartnerGalleryDetailWindow:layout()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	self.labelCurPoint.text = __("ACTIVITY_PARTNER_GALLERY_POINT")
	self.labelTitle.text = __("ACTIVITY_PARTNER_GALLERY_TITLE")
	local allPoint = pTable:getAllPoint()
	self.progress.value = self.score / allPoint
	self.progressLabel.text = self.score .. "/" .. allPoint
	local params = {
		isCanUnSelected = 1,
		chosenGroup = 0,
		scale = 1,
		gap = 20,
		callback = function (group)
			self:selectGroup(group)
		end,
		width = self.filterGroup:GetComponent(typeof(UIWidget)).width
	}
	local partnerFilter = PartnerFilter.new(self.filterGroup, params)

	self:selectGroup(0)
end

function ActivityPartnerGalleryDetailWindow:selectGroup(group)
	local list = pTable:getPartnerListByGroup(group)

	self.wrapContent_:setInfos(list, {})
end

function FormationItem:ctor(go, parent)
	FormationItem.super.ctor(self, go, parent)
end

function FormationItem:initUI()
	self.heroIcon_1 = HeroIcon.new(self.go)
	self.heroIcon_2 = HeroIcon.new(self.go)

	self.heroIcon_1:setScale(0.7962962962962963)
	self.heroIcon_2:setScale(0.7962962962962963)
end

function FormationItem:setDragScrollView()
end

function FormationItem:updateInfo()
	table.sort(self.data)

	for i = 1, 2 do
		self["heroIcon_" .. i]:setInfo({
			noWays = true,
			tableID = self.data[i],
			dragScrollView = self.parent.scroller
		})

		if not xyd.models.slot:getCollection()[self.data[i]] then
			self["heroIcon_" .. i]:setGrey()
		else
			self["heroIcon_" .. i]:setOrigin()
		end
	end
end

return ActivityPartnerGalleryDetailWindow
