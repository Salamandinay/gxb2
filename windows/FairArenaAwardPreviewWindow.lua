local BaseWindow = import(".BaseWindow")
local FairArenaAwardPreviewWindow = class("FairArenaAwardPreviewWindow", BaseWindow)

function FairArenaAwardPreviewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.stage = params.stage
end

function FairArenaAwardPreviewWindow:initWindow()
	FairArenaAwardPreviewWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function FairArenaAwardPreviewWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.tipsLabel1_ = winTrans:ComponentByName("tipsLabel1_", typeof(UILabel))
	self.tipsLabel2_ = winTrans:ComponentByName("tipsLabel2_", typeof(UILabel))
	self.itemGroup = winTrans:ComponentByName("itemGroup", typeof(UILayout))
	self.scoreTextLabel_ = winTrans:ComponentByName("scoreGroup/scoreTextLabel_", typeof(UILabel))
	self.scoreLabel_ = winTrans:ComponentByName("scoreGroup/scoreLabelCon_/scoreLabel_", typeof(UILabel))
	self.scoreGroup_UILayout = winTrans:ComponentByName("scoreGroup", typeof(UILayout))
end

function FairArenaAwardPreviewWindow:initUIComponent()
	self.titleLabel_.text = __("FAIR_ARENA_AWARDS_PREVIEW")
	self.tipsLabel1_.text = __("FAIR_ARENA_DESC_AWARDS_LEVEL", self.stage - 1)
	self.tipsLabel2_.text = __("FAIR_ARENA_NOTES_AWARDS_LEVEL")
	self.scoreTextLabel_.text = __("FAIR_ARENA_POINT")

	self.tipsLabel2_:SetActive(xyd.models.fairArena:checkTest())

	self.scoreLabel_.text = "+" .. xyd.tables.activityFairArenaLevelTable:getScore(self.stage)

	self:waitForFrame(2, function ()
		self.scoreGroup_UILayout:Reposition()
	end)

	local awards = xyd.tables.activityFairArenaLevelTable:getAwards(self.stage)

	for i = 1, #awards do
		local award = awards[i]
		local item = xyd.getItemIcon({
			uiRoot = self.itemGroup.gameObject,
			itemID = award[1],
			num = award[2]
		})
	end

	self.itemGroup:Reposition()
end

function FairArenaAwardPreviewWindow:register()
	FairArenaAwardPreviewWindow.super.register(self)
end

return FairArenaAwardPreviewWindow
