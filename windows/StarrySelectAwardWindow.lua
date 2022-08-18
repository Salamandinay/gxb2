local BaseWindow = import(".BaseWindow")
local StarrySelectAwardWindow = class("StarrySelectAwardWindow", BaseWindow)
local StarryAltarTable = xyd.tables.starryAltarTable
local NORMAL_SUMMON1_ID = 1
local NORMAL_SUMMON2_ID = 3
local ACT_SUMMON1_ID = 4
local ACT_SUMMON2_ID = 5
local ACT_SUMMON1_NEWCOST_ID = 6
local ACT_SUMMON2_NEWCOST_ID = 7

function StarrySelectAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curMode = params.curMode or 1
	self.curSelectAwardIndex = params.curSelectAwardIndex or 1

	if self.curSelectAwardIndex == 0 then
		self.curSelectAwardIndex = 1
	end

	self.sureCallback = params.sureCallback
end

function StarrySelectAwardWindow:initWindow()
	self.icons = {}
	self.effectList = {}

	self:initData()
	self:getUIComponent()
	StarrySelectAwardWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function StarrySelectAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.btnArrowLeft = self.groupAction:NodeByName("btnArrowLeft").gameObject
	self.btnArrowRight = self.groupAction:NodeByName("btnArrowRight").gameObject
	self.btnCancel = self.groupAction:NodeByName("btnCancel").gameObject
	self.labelCancel = self.btnCancel:ComponentByName("labelCancel", typeof(UILabel))
	self.btnSure = self.groupAction:NodeByName("btnSure").gameObject
	self.labelSure = self.btnSure:ComponentByName("labelSure", typeof(UILabel))
	self.descGroup = self.groupAction:NodeByName("descGroup").gameObject
	self.labelDesc = self.descGroup:ComponentByName("labelDesc", typeof(UILabel))
	self.line = self.descGroup:ComponentByName("line", typeof(UISprite))
	self.labelTitle = self.descGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.btnSwitch = self.descGroup:NodeByName("btnSwitch").gameObject
	self.btnDetail = self.groupAction:NodeByName("btnDetail").gameObject
	self.iconPos = self.groupAction:NodeByName("iconPos").gameObject
	self.modelPos = self.groupAction:ComponentByName("modelPos", typeof(UITexture))
end

function StarrySelectAwardWindow:register()
	UIEventListener.Get(self.btnDetail).onClick = handler(self, function ()
		local awards = StarryAltarTable:getOptionalAwards(self.mode1TableID)
		local partnerTableID = awards[self.curSelectAwardIndex]

		xyd.WindowManager.get():openWindow("partner_info", {
			noWays = true,
			table_id = partnerTableID,
			star = xyd.tables.partnerTable:getStar(partnerTableID)
		})
	end)
	UIEventListener.Get(self.btnSure).onClick = handler(self, function ()
		self.sureCallback(self.curMode, self.curSelectAwardIndex)
		xyd.closeWindow(self.name_)
	end)
	UIEventListener.Get(self.btnCancel).onClick = handler(self, function ()
		xyd.closeWindow(self.name_)
	end)
	UIEventListener.Get(self.btnSwitch).onClick = handler(self, function ()
		self.curMode = xyd.checkCondition(self.curMode == 1, 2, 1)

		self:updateContent()
	end)
	UIEventListener.Get(self.btnArrowLeft).onClick = handler(self, function ()
		local awards = StarryAltarTable:getOptionalAwards(self.mode1TableID)
		self.curSelectAwardIndex = self.curSelectAwardIndex - 1

		if self.curSelectAwardIndex <= 0 then
			self.curSelectAwardIndex = #awards
		end

		self:updateContent()
	end)
	UIEventListener.Get(self.btnArrowRight).onClick = handler(self, function ()
		local awards = StarryAltarTable:getOptionalAwards(self.mode1TableID)
		self.curSelectAwardIndex = self.curSelectAwardIndex + 1

		if self.curSelectAwardIndex > #awards then
			self.curSelectAwardIndex = 1
		end

		self:updateContent()
	end)
end

function StarrySelectAwardWindow:initUIComponent()
	self.labelSure.text = __("SURE")
	self.labelCancel.text = __("CANCEL")

	self:updateContent()
end

function StarrySelectAwardWindow:initData()
	local actId = StarryAltarTable:getActivity(ACT_SUMMON1_NEWCOST_ID)
	local isActOpen = false

	if actId then
		isActOpen = xyd.models.activity:isOpen(actId)
		self.activityData = xyd.models.activity:getActivity(actId)
	end

	self.isActOpen = isActOpen

	if not isActOpen then
		self.mode1TableID = NORMAL_SUMMON1_ID
		self.mode2TableID = NORMAL_SUMMON2_ID

		return
	end

	self.mode1TableID = ACT_SUMMON1_ID
	self.mode2TableID = ACT_SUMMON2_ID
end

function StarrySelectAwardWindow:updateContent()
	if self.curMode == 1 then
		self.labelTitle.text = __("STARRY_ALTAR_TEXT14")
		self.labelDesc.text = __("STARRY_ALTAR_TEXT18")

		self.btnDetail:SetActive(true)

		local awards = StarryAltarTable:getOptionalAwards(self.mode1TableID)

		if #awards > 0 then
			self.btnArrowLeft:SetActive(true)
			self.btnArrowRight:SetActive(true)

			if self.curSelectAwardIndex <= 1 then
				self.btnArrowLeft:SetActive(false)
			end

			if self.curSelectAwardIndex >= #awards then
				self.btnArrowRight:SetActive(false)
			end
		end

		self.iconPos:SetActive(false)

		if self.curModelEffect then
			self.curModelEffect:SetActive(false)
		end

		if self.curSelectAwardIndex > 0 then
			local partnerTableID = awards[self.curSelectAwardIndex]
			local modelID = xyd.tables.partnerTable:getModelID(partnerTableID)
			local name = xyd.tables.modelTable:getModelName(modelID)
			local scale = xyd.tables.modelTable:getScale(modelID)

			if not self.effectList[partnerTableID] then
				self.effectList[partnerTableID] = xyd.Spine.new(self.modelPos.gameObject)

				self.effectList[partnerTableID]:setInfo(name, function ()
					self.effectList[partnerTableID]:SetLocalPosition(0, -98, 0)
					self.effectList[partnerTableID]:SetLocalScale(scale, scale, 1)
					self.effectList[partnerTableID]:play("idle", 0)
				end, true)
			else
				self.effectList[partnerTableID]:SetActive(true)
			end

			self.curModelEffect = self.effectList[partnerTableID]
		end
	else
		self.labelTitle.text = __("STARRY_ALTAR_TEXT15")
		self.labelDesc.text = __("STARRY_ALTAR_TEXT16")

		if self.curModelEffect then
			self.curModelEffect:SetActive(false)
		end

		self.btnDetail:SetActive(false)
		self.btnArrowLeft:SetActive(false)
		self.btnArrowRight:SetActive(false)
		self.iconPos:SetActive(true)

		local award = StarryAltarTable:getType2Award(self.mode2TableID)[2]
		local params = {
			noClickSelected = true,
			uiRoot = self.iconPos,
			itemID = award[1],
			num = award[2]
		}

		if not self.icons[1] then
			self.icons[1] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.icons[1]:setInfo(params)
		end
	end

	xyd.setUITextureByNameAsync(self.bg, "starry_bg_jlxz_" .. self.curSelectAwardIndex)
end

return StarrySelectAwardWindow
