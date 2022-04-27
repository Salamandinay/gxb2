local CampaignAlertWindow = class("CampaignAlertWindow", import(".BaseWindow"))

function CampaignAlertWindow:ctor(name, params)
	CampaignAlertWindow.super.ctor(self, name, params)

	self.callback = nil
	self.StageTable = xyd.tables.stageTable
	self.mapsModel = xyd.models.map
	self.backPackModel = xyd.models.backpack
	self.stageId_ = params.stageId
end

function CampaignAlertWindow:initWindow()
	CampaignAlertWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.mainGroup = winTrans:Find("main")
	self.requireLabel = self.mainGroup:ComponentByName("require_label", typeof(UILabel))
	self.line1Label = self.mainGroup:ComponentByName("line1_label", typeof(UILabel))
	self.line2Label = self.mainGroup:ComponentByName("line2_label", typeof(UILabel))
	self.line3Label = self.mainGroup:ComponentByName("line3_label", typeof(UILabel))

	self:initLayOut()
end

function CampaignAlertWindow:initLayOut()
	local lv = self.StageTable:getLv(self.stageId_)
	local playerLv = self.backPackModel:getLev()
	local power = self.StageTable:getPower(self.stageId_)
	local teamPower = self.mapsModel:getTeamPower()
	self.mapInfo = self.mapsModel:getMapInfo(xyd.MapType.CAMPAIGN)
	self.maxStage = self.mapInfo.max_stage == 0 and 1 or self.mapInfo.max_stage
	self.requireLabel.text = __("CAMPAIGN_REQUIRE")
	self.line1Label.text = __("CAMPAIGN_REQUIRE_1", lv)

	if playerLv < lv then
		self.line1Label.color = Color.New(0.8, 0, 0.06666666666666667, 1)
	else
		self.line1Label.color = Color.New(0.5019607843137255, 0.5019607843137255, 0.5019607843137255, 1)
	end

	self.line2Label.text = __("CAMPAIGN_REQUIRE_2", power)

	if teamPower < power then
		self.line2Label.color = Color.New(0.8, 0, 0.06666666666666667, 1)
	else
		self.line2Label.color = Color.New(0.5019607843137255, 0.5019607843137255, 0.5019607843137255, 1)
	end

	self.line3Label.text = __("CAMPAIGN_REQUIRE_3")

	if self.stageId_ > self.maxStage + 1 then
		self.line3Label.color = Color.New(0.8, 0, 0.06666666666666667, 1)
	else
		self.line3Label.color = Color.New(0.5019607843137255, 0.5019607843137255, 0.5019607843137255, 1)
	end
end

function CampaignAlertWindow:willClose()
	CampaignAlertWindow.super.willClose(self)
end

return CampaignAlertWindow
