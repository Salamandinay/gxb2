local BaseWindow = import(".BaseWindow")
local TowerVideoWindow = class("TowerVideoWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local json = require("cjson")

function TowerVideoWindow:ctor(name, params)
	self.state = params.state

	if not self.state then
		self.state = xyd.CommonViewState.TOWER
	end

	TowerVideoWindow.super.ctor(self, name, params)

	self.records = {}
	self.stageID = params.stage

	if self.state == xyd.CommonViewState.TOWER then
		if not xyd.models.towerMap:getTowerRecord(self.stageID) then
			xyd.models.towerMap:reqStageRecord(self.stageID)
		end
	elseif self.state == xyd.CommonViewState.SOUL_LAND and not xyd.models.soulLand:getSoulLandRecord(self.stageID) then
		xyd.models.soulLand:reqStageRecord(self.stageID)
	end
end

function TowerVideoWindow:initWindow()
	TowerVideoWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()

	if self.state == xyd.CommonViewState.TOWER then
		if xyd.models.towerMap:getTowerRecord(self.stageID) then
			self:onTowerRecord()
		end
	elseif self.state == xyd.CommonViewState.SOUL_LAND and xyd.models.soulLand:getSoulLandRecord(self.stageID) then
		self:onTowerRecord()
	end
end

function TowerVideoWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupOld = winTrans:NodeByName("group_old").gameObject
	self.labelWinTitle = self.groupOld:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.groupOld:NodeByName("closeBtn").gameObject
	local videoGroup = self.groupOld:NodeByName("videoGroup").gameObject

	for i = 1, 3 do
		self["group" .. i] = videoGroup:NodeByName("group" .. i).gameObject
	end

	self.groupNew = winTrans:NodeByName("group_new").gameObject
	self.labelWinTitle_ = self.groupNew:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn_ = self.groupNew:NodeByName("closeBtn").gameObject
	local videoGroup_ = self.groupNew:NodeByName("videoGroup").gameObject

	for i = 1, 3 do
		self["group_" .. i] = videoGroup_:NodeByName("group" .. i).gameObject
	end
end

function TowerVideoWindow:initUIComponent()
	self.labelWinTitle.text = __("TowerVideoWindow")
	self.labelWinTitle_.text = __("TOWER_VIDEO_WINDOW")

	for i = 1, 3 do
		self["group" .. i]:SetActive(false)
		self["group_" .. i]:SetActive(false)
	end

	self.groupNew:SetActive(false)
end

function TowerVideoWindow:register()
	TowerVideoWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.TOWER_RECORDS, self.onTowerRecord, self)
	self.eventProxy_:addEventListener(xyd.event.SOUL_LAND_RECORDS, self.onTowerRecord, self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:onClickCloseButton()
	end
end

function TowerVideoWindow:onTowerRecord()
	local records = nil

	if self.state == xyd.CommonViewState.TOWER then
		records = xyd.models.towerMap:getTowerRecord(self.stageID)
	elseif self.state == xyd.CommonViewState.SOUL_LAND then
		records = xyd.models.soulLand:getSoulLandRecord(self.stageID)
	end

	if not records then
		return
	end

	self.records = records

	if not self:checkIsNew() then
		self:initOldGroup()
	else
		self:initNewGroup()
	end
end

function TowerVideoWindow:checkIsNew()
	for i = 1, #self.records do
		local formation = self.records[i].formation

		if not formation then
			return false
		else
			formation = json.decode(self.records[i].formation)

			if not formation.partners then
				return false
			end
		end
	end

	return true
end

function TowerVideoWindow:initOldGroup()
	self.groupOld:SetActive(true)

	local records = self.records
	local count = math.min(#records, 3)

	for i = 1, count do
		self:initBaseContent(i)
	end
end

function TowerVideoWindow:initNewGroup()
	self.groupNew:SetActive(true)

	local records = self.records
	local count = math.min(#records, 3)

	for i = 1, count do
		self:initBaseContent(i, true)

		local group = self["group_" .. i]
		local formation = json.decode(records[i].formation)
		self.heroIcon1 = group:NodeByName("heroGroup1/icon1/hero1").gameObject
		self.heroIcon2 = group:NodeByName("heroGroup1/icon2/hero2").gameObject
		self.heroIcon3 = group:NodeByName("heroGroup2/icon3/hero3").gameObject
		self.heroIcon4 = group:NodeByName("heroGroup2/icon4/hero4").gameObject
		self.heroIcon5 = group:NodeByName("heroGroup2/icon5/hero5").gameObject
		self.heroIcon6 = group:NodeByName("heroGroup2/icon6/hero6").gameObject

		for j = 1, 6 do
			self["hero" .. j] = HeroIcon.new(self["heroIcon" .. j])
		end

		local power = 0
		local posList = {}
		local partners = formation.partners
		local pet_id = 0

		if formation.pet then
			pet_id = formation.pet.pet_id
		end

		for j = 1, #partners do
			local data = partners[j]
			local pos = data.pos
			local partner = Partner.new()
			posList[pos] = true

			partner:populate(data)

			local pInfo = partner:getInfo()
			pInfo.noClick = true
			pInfo.scale = 0.6388888888888888

			self["hero" .. pos]:setInfo(pInfo, pet_id)

			power = power + partner:getPower()
		end

		for j = 1, 6 do
			if posList[j] then
				self["hero" .. j]:SetActive(true)
			else
				self["hero" .. j]:SetActive(false)
			end
		end

		group:ComponentByName("labelPower", typeof(UILabel)).text = power
	end
end

function TowerVideoWindow:initBaseContent(index, isNew)
	local group = self["group" .. index]

	if isNew then
		group = self["group_" .. index]
		group:ComponentByName("labelText01", typeof(UILabel)).text = __("DEFFORMATION")
	end

	local data = self.records[index]

	group:SetActive(true)

	group:ComponentByName("LabelPlayerName", typeof(UILabel)).text = data.player_name
	local groupAvatar = group:NodeByName("groupAvatar").gameObject
	local btnVideo = group:NodeByName("btnVideo").gameObject
	local playerIcon = PlayerIcon.new(groupAvatar)

	playerIcon:setInfo({
		scale = 0.6929824561403509,
		noClick = true,
		avatarID = data.avatar_id,
		avatar_frame_id = data.avatar_frame_id,
		lev = data.lev
	})

	UIEventListener.Get(btnVideo).onClick = function ()
		if self.state == xyd.CommonViewState.TOWER then
			local data = xyd.models.towerMap:getTowerReport(self.stageID, self.records[index].record_id)

			if data then
				xyd.EventDispatcher:inner():dispatchEvent({
					name = xyd.event.TOWER_REPORT,
					data = data
				})
			else
				xyd.models.towerMap:reqTowerReport(self.stageID, self.records[index].record_id)
			end
		elseif self.state == xyd.CommonViewState.SOUL_LAND then
			local data = xyd.models.soulLand:getSoulLandReport(self.stageID, self.records[index].record_id)

			if data then
				xyd.EventDispatcher:inner():dispatchEvent({
					name = xyd.event.SOUL_LAND_REPORT,
					data = data
				})
			else
				xyd.models.soulLand:reqSoulLandReport(self.stageID, self.records[index].record_id)
			end
		end
	end
end

return TowerVideoWindow
