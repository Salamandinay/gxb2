local ActivityPromotionLadder = class("ActivityPromotionLadder", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")
local HeroIcon = import("app.components.HeroIcon")
local cjson = require("cjson")
local partnerPicture = xyd.tables.miscTable:split("activity_promotion_ladder_picture", "value", "|")
local costItemID = xyd.ItemID.PROMOTION_CERTIFICATE
local costMultiple = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_star", "value", "|#")
local costBase = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_basenum", "value", "#")
local costIncreaseInterval = xyd.tables.miscTable:getNumber("activity_promotion_ladder_interval", "value")
local costIncrease = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_increasenum", "value", "#")
local materialPartnerTableID = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_material", "value", "|")
local targetPartnerTableID = xyd.tables.miscTable:getNumber("activity_promotion_ladder_target", "value")
local targetIndex = 1

function ActivityPromotionLadder:ctor(parentGO, params)
	ActivityPromotionLadder.super.ctor(self, parentGO, params)
end

function ActivityPromotionLadder:getPrefabPath()
	return "Prefabs/Windows/activity/activity_promotion_ladder"
end

function ActivityPromotionLadder:resizeToParent()
	ActivityPromotionLadder.super.resizeToParent(self)
	self:resizePosY(self.bg, 108, 0)
	self:resizePosY(self.textImg, 0, -54)
	self:resizePosY(self.resItem, -311, -485)
	self:resizePosY(self.groupContent, -606.5, -780.5)
end

function ActivityPromotionLadder:initUI()
	self:getUIComponent()
	ActivityPromotionLadder.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityPromotionLadder:getUIComponent()
	local go = self.go
	self.bg = go:NodeByName("bg").gameObject
	self.textImg = go:ComponentByName("textImg", typeof(UISprite))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.partnerPicture = go:ComponentByName("partnerPicture", typeof(UITexture))
	self.btnHelp = go:NodeByName("btnHelp").gameObject
	self.btnDetail = go:NodeByName("btnDetail").gameObject
	self.resItem = go:NodeByName("resItem").gameObject
	self.resIcon = self.resItem:NodeByName("icon").gameObject
	self.resNum = self.resItem:ComponentByName("num", typeof(UILabel))
	self.resPlus = self.resItem:NodeByName("btnPlus").gameObject
	self.groupContent = go:NodeByName("groupContent").gameObject
	self.btnPromote = self.groupContent:NodeByName("btnPromote").gameObject
	self.labelPromote = self.btnPromote:ComponentByName("label", typeof(UILabel))
	self.labelPromoteNum = self.btnPromote:ComponentByName("num", typeof(UILabel))
	self.labelTip = self.groupContent:ComponentByName("labelTip", typeof(UILabel))
	self.groupMaterial = self.groupContent:NodeByName("groupMaterial").gameObject
	self.modelMaterial = self.groupMaterial:NodeByName("modelMaterial").gameObject
	self.materialDefault = self.groupMaterial:NodeByName("iconDefault").gameObject
	self.iconMaterial = self.groupMaterial:NodeByName("iconMaterial").gameObject
	self.groupTarget = self.groupContent:NodeByName("groupTarget").gameObject
	self.modelTarget = self.groupTarget:NodeByName("modelTarget").gameObject
	self.targetDefault = self.groupTarget:NodeByName("iconDefault").gameObject
	self.iconTarget = self.groupTarget:NodeByName("iconTarget").gameObject
end

function ActivityPromotionLadder:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "activity_promotion_ladder_text_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
	end

	xyd.setUITextureByNameAsync(self.partnerPicture, partnerPicture[1], true)
	self.partnerPicture:SetLocalPosition(partnerPicture[3], partnerPicture[4], 0)
	self.partnerPicture:SetLocalScale(partnerPicture[2], partnerPicture[2], 1)

	self.resNum.text = xyd.models.backpack:getItemNumByID(costItemID)
	self.labelPromote.text = __("EXCHANGE2")
	self.labelTip.text = __("ACTIVITY_PROMOTION_LADDER_TEXT09")

	self:update(true)
end

function ActivityPromotionLadder:update(init)
	if init then
		self:loadPartner()
	end

	self:updateData()
	self:updateModelAndIcon()
	self:updateBtn()
end

function ActivityPromotionLadder:updateData()
	if not self.materialPartnerTableIDList then
		self.materialPartnerTableIDList = {}

		for i in pairs(materialPartnerTableID) do
			local tableIDList = xyd.tables.partnerTable:getHeroList(materialPartnerTableID[i])

			table.insert(self.materialPartnerTableIDList, tableIDList)
		end
	end

	if not self.costMultiple then
		self.costMultiple = {}

		for u, v in pairs(costMultiple) do
			self.costMultiple[v[1]] = v[2]
		end
	end

	if not self.targetPartnerTableIDList then
		self.targetPartnerTableIDList = xyd.tables.partnerTable:getHeroList(targetPartnerTableID)
	end

	if not self.materialPartner then
		self.costNum = 0
	else
		local costNum = 0

		for i = 1, self.costMultiple[self.materialPartner:getStar()] do
			costNum = costNum + costBase[2] + math.floor((self.activityData.detail.times + i - 1) / costIncreaseInterval) * costIncrease[2]
		end

		self.costNum = costNum
	end

	local partners = xyd.models.slot:getPartners()
	self.materialPartnerList = {}

	for i, partner in pairs(partners) do
		local tableID = partner:getTableID()

		for _, idList in pairs(self.materialPartnerTableIDList) do
			for __, id in pairs(idList) do
				if id == tableID then
					table.insert(self.materialPartnerList, partner)
				end
			end
		end
	end

	table.sort(self.materialPartnerList, function (a, b)
		local tableIDa = a:getTableID()
		local tableIDb = b:getTableID()
		local starA = a:getStar()
		local starB = b:getStar()

		if tableIDa ~= tableIDb then
			return tableIDb < tableIDa
		elseif starA ~= starB then
			return starB < starA
		else
			return b:getLevel() < a:getLevel()
		end
	end)
end

function ActivityPromotionLadder:updateModelAndIcon()
	if not self.materialPartner then
		NGUITools.DestroyChildren(self.modelMaterial.transform)
		NGUITools.DestroyChildren(self.modelTarget.transform)

		self.materialModel = xyd.Spine.new(self.modelMaterial)

		self.materialModel:setInfo("fx_guanghuan", function ()
			self.materialModel:SetLocalPosition(0, 98, 0)
			self.materialModel:play("texiao01", 0, 1)
		end)

		local targetModelID = xyd.tables.partnerTable:getModelID(targetPartnerTableID)
		local targetModelName = xyd.tables.modelTable:getModelName(targetModelID)
		local targetModelScale = xyd.tables.modelTable:getScale(targetModelID)
		self.targetModel = xyd.Spine.new(self.modelTarget)

		self.targetModel:setInfo(targetModelName, function ()
			self.targetModel:SetLocalScale(targetModelScale, targetModelScale, 1)
			self.targetModel:play("idle", 0, 1)
		end)

		if self.materialHeroIcon then
			self.materialHeroIcon:SetActive(false)
		end

		if self.targetHeroIcon then
			self.targetHeroIcon:SetActive(false)
		end

		return
	end

	NGUITools.DestroyChildren(self.modelMaterial.transform)
	NGUITools.DestroyChildren(self.modelTarget.transform)

	local materialModelID = xyd.tables.partnerTable:getModelID(self.materialPartner:getTableID())
	local materialModelName = xyd.tables.modelTable:getModelName(materialModelID)
	local materialModelScale = xyd.tables.modelTable:getScale(materialModelID)
	self.materialModel = xyd.Spine.new(self.modelMaterial)

	self.materialModel:setInfo(materialModelName, function ()
		self.materialModel:SetLocalScale(materialModelScale, materialModelScale, 1)
		self.materialModel:play("idle", 0, 1)
	end)

	local materialStar = self.materialPartner:getStar()

	if materialStar >= 10 then
		self.correctedTargetTableID = self.targetPartnerTableIDList[3]
	elseif materialStar >= 6 then
		self.correctedTargetTableID = self.targetPartnerTableIDList[2]
	else
		self.correctedTargetTableID = self.targetPartnerTableIDList[1]
	end

	local targetModelID = xyd.tables.partnerTable:getModelID(self.correctedTargetTableID)
	local targetModelName = xyd.tables.modelTable:getModelName(targetModelID)
	local targetModelScale = xyd.tables.modelTable:getScale(targetModelID)
	self.targetModel = xyd.Spine.new(self.modelTarget)

	self.targetModel:setInfo(targetModelName, function ()
		self.targetModel:SetLocalScale(targetModelScale, targetModelScale, 1)
		self.targetModel:play("idle", 0, 1)
	end)

	if not self.materialHeroIcon then
		self.materialHeroIcon = HeroIcon.new(self.iconMaterial.gameObject)
	else
		self.materialHeroIcon:SetActive(true)
	end

	self.materialHeroIcon:setInfo(self.materialPartner:getInfo())
	self.materialHeroIcon:setNoClick(true)

	if not self.targetHeroIcon then
		self.targetHeroIcon = HeroIcon.new(self.iconTarget.gameObject)
	else
		self.targetHeroIcon:SetActive(true)
	end

	local targetInfo = {
		star = self.materialPartner:getStar(),
		group = xyd.tables.partnerTable:getGroup(self.correctedTargetTableID),
		tableID = self.correctedTargetTableID,
		lev = self.materialPartner:getLevel()
	}

	self.targetHeroIcon:setInfo(targetInfo)
	self.targetHeroIcon:setNoClick(true)
end

function ActivityPromotionLadder:updateBtn()
	if not self.materialPartner then
		xyd.setEnabled(self.btnPromote.gameObject, false)

		self.labelPromoteNum.text = 0
	else
		xyd.setEnabled(self.btnPromote.gameObject, true)

		self.labelPromoteNum.text = self.costNum
	end
end

function ActivityPromotionLadder:register()
	UIEventListener.Get(self.btnHelp.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_PROMOTION_LADDER_TEXT01"
		})
	end

	UIEventListener.Get(self.btnDetail.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_promotion_ladder_detail_window")
	end

	UIEventListener.Get(self.modelMaterial.gameObject).onClick = function ()
		if not self.materialPartner then
			local params = {
				needNum = 1,
				notPlaySaoguang = true,
				noClickSelected = true,
				type = "ACTIVITY_PROMOTION_LADDER",
				isShowLovePoint = false,
				benchPartners = self.materialPartnerList,
				partners = self.materialPartner and {
					self.materialPartner:getPartnerID()
				} or nil
			}

			function params.confirmCallback()
				local win = xyd.WindowManager:get():getWindow("choose_partner_window")
				local selectPartnerID = (win:getSelected() or {})[1]

				if selectPartnerID then
					self.materialPartner = xyd.models.slot:getPartner(selectPartnerID)
				else
					self.materialPartner = nil
				end

				self:recordPartner()
				self:update()
			end

			params.mTableIDList = materialPartnerTableID

			function params.debrisCloseCallBack()
				self:updateData()

				params.benchPartners = self.materialPartnerList

				xyd.WindowManager:get():openWindow("choose_partner_window", params)
			end

			xyd.WindowManager:get():openWindow("choose_partner_window", params)

			return
		end

		local collection = {
			{
				table_id = self.materialPartner:getTableID()
			}
		}
		local params = {
			partners = collection,
			table_id = self.materialPartner:getTableID()
		}

		xyd.WindowManager.get():openWindow("guide_detail_window", params, function ()
			xyd.WindowManager.get():closeWindowsOnLayer(6)
		end)
	end

	UIEventListener.Get(self.modelTarget.gameObject).onClick = function ()
		local correctedTableID = nil
		local materialStar = self.materialPartner and self.materialPartner:getStar() or 5

		if materialStar >= 10 then
			correctedTableID = self.targetPartnerTableIDList[3]
		elseif materialStar >= 6 then
			correctedTableID = self.targetPartnerTableIDList[2]
		else
			correctedTableID = self.targetPartnerTableIDList[1]
		end

		local collection = {
			{
				table_id = correctedTableID
			}
		}
		local params = {
			partners = collection,
			table_id = correctedTableID
		}

		xyd.WindowManager.get():openWindow("guide_detail_window", params, function ()
			xyd.WindowManager.get():closeWindowsOnLayer(6)
		end)
	end

	UIEventListener.Get(self.resIcon.gameObject).onClick = function ()
		local params = {
			notShowGetWayBtn = true,
			showGetWays = false,
			show_has_num = true,
			itemID = costItemID,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.materialDefault.gameObject).onLongPress = function ()
	end

	UIEventListener.Get(self.targetDefault.gameObject).onLongPress = function ()
	end

	UIEventListener.Get(self.materialDefault.gameObject).onClick = function ()
		local params = {
			needNum = 1,
			notPlaySaoguang = true,
			noClickSelected = true,
			type = "ACTIVITY_PROMOTION_LADDER",
			isShowLovePoint = false,
			benchPartners = self.materialPartnerList,
			partners = self.materialPartner and {
				self.materialPartner:getPartnerID()
			} or nil
		}

		function params.confirmCallback()
			local win = xyd.WindowManager:get():getWindow("choose_partner_window")
			local selectPartnerID = (win:getSelected() or {})[1]

			if selectPartnerID then
				self.materialPartner = xyd.models.slot:getPartner(selectPartnerID)
			else
				self.materialPartner = nil
			end

			self:recordPartner()
			self:update()
		end

		params.mTableIDList = materialPartnerTableID

		function params.debrisCloseCallBack()
			self:updateData()

			params.benchPartners = self.materialPartnerList

			xyd.WindowManager:get():openWindow("choose_partner_window", params)
		end

		xyd.WindowManager:get():openWindow("choose_partner_window", params)
	end

	UIEventListener.Get(self.resPlus.gameObject).onClick = function ()
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_PROMOTION_TEST),
			select = xyd.ActivityID.ACTIVITY_PROMOTION_TEST
		})
	end

	UIEventListener.Get(self.btnPromote.gameObject).onClick = function ()
		if xyd.models.backpack:getItemNumByID(costItemID) < self.costNum then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(costItemID)))

			return
		end

		local index = 1
		local tableID = self.materialPartner:getTableID()

		for _, idList in pairs(self.materialPartnerTableIDList) do
			for __, id in pairs(idList) do
				if id == tableID then
					index = _
				end
			end
		end

		local params = {
			partner_id = self.materialPartner:getPartnerID(),
			index = index,
			replace_index = targetIndex,
			replace_id = targetPartnerTableID
		}

		xyd.alertYesNo(__("ACTIVITY_PROMOTION_LADDER_TEXT12"), function (yes)
			if yes then
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_PROMOTION_LADDER, cjson.encode(params))
				self.activityData:recordPromoteTimes(self.costMultiple[self.materialPartner:getStar()])

				self.materialPartner = nil

				self:recordPartner()
			end
		end)
	end

	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(costItemID)
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function ()
		self:update()
	end)
	self:registerEvent(xyd.event.GET_SLOT_INFO, function ()
		self:updateData()
	end)
end

function ActivityPromotionLadder:loadPartner()
	local partnerID = tonumber(xyd.db.misc:getValue("activity_promotion_ladder_partner_record"))

	if partnerID and partnerID ~= 0 then
		self.materialPartner = xyd.models.slot:getPartner(partnerID)
	end

	if self.materialPartner then
		local isLastIssue = true
		local materialTableID = self.materialPartner:getTableID()

		for i in pairs(materialPartnerTableID) do
			local tableIDList = xyd.tables.partnerTable:getHeroList(materialPartnerTableID[i])

			for j in pairs(tableIDList) do
				if tableIDList[j] == materialTableID then
					isLastIssue = false
				end
			end
		end

		if isLastIssue then
			self.materialPartner = nil
		end
	end
end

function ActivityPromotionLadder:recordPartner()
	xyd.db.misc:setValue({
		key = "activity_promotion_ladder_partner_record",
		value = self.materialPartner and self.materialPartner:getPartnerID() or 0
	})
end

return ActivityPromotionLadder
