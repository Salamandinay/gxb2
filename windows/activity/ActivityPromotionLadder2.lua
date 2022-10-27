local ActivityPromotionLadder2 = class("ActivityPromotionLadder2", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local cjson = require("cjson")
local partnerPicture = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_picture2", "value", "|#", false)
local costItemID = xyd.ItemID.PROMOTION_CERTIFICATE
local costMultiple = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_star2", "value", "|#")
local costBase = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_basenum2", "value", "#")
local costIncreaseInterval = xyd.tables.miscTable:getNumber("activity_promotion_ladder_interval2", "value")
local costIncrease = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_increasenum2", "value", "#")
local materialPartner5StarTableID = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_material2", "value", "|")
local targetPartner5StarTableID = xyd.tables.miscTable:split2Cost("activity_promotion_ladder_target2", "value", "|")

function ActivityPromotionLadder2:ctor(parentGO, params)
	ActivityPromotionLadder2.super.ctor(self, parentGO, params)
end

function ActivityPromotionLadder2:getPrefabPath()
	return "Prefabs/Windows/activity/activity_promotion_ladder2"
end

function ActivityPromotionLadder2:resizeToParent()
	ActivityPromotionLadder2.super.resizeToParent(self)
	self:resizePosY(self.bg, 108, 0)
	self:resizePosY(self.textImg, 0, -54)
	self:resizePosY(self.resItem, -311, -485)
	self:resizePosY(self.groupContent, -606.5, -780.5)
end

function ActivityPromotionLadder2:initUI()
	self:getUIComponent()
	ActivityPromotionLadder2.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityPromotionLadder2:getUIComponent()
	local go = self.go
	self.bg = go:NodeByName("bg").gameObject
	self.textImg = go:ComponentByName("textImg", typeof(UISprite))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.partnerPicture = go:ComponentByName("partnerPicture", typeof(UITexture))
	self.partnerPictureLoop = go:ComponentByName("partnerPictureLoop", typeof(UITexture))
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
	self.modelLoop = self.groupTarget:ComponentByName("modelLoop", typeof(UITexture))
	self.targetDefault = self.groupTarget:NodeByName("iconDefault").gameObject
	self.iconTarget = self.groupTarget:NodeByName("iconTarget").gameObject
	self.groupArrow = self.groupTarget:NodeByName("groupArrow").gameObject
	self.arrowLeft = self.groupArrow:NodeByName("arrowLeft").gameObject
	self.arrowRight = self.groupArrow:NodeByName("arrowRight").gameObject
	self.arrowRightRedMark = self.arrowRight:NodeByName("redMark").gameObject
	self.btnExchangeMaterail = self.groupMaterial:NodeByName("btnExchangeMaterail").gameObject
	self.btnExchangeTarget = self.groupTarget:NodeByName("btnExchangeTarget").gameObject
	self.btnChooseTarget = self.groupTarget:NodeByName("btnChooseTarget").gameObject
end

function ActivityPromotionLadder2:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "activity_promotion_ladder_text_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
	end

	self.resNum.text = xyd.models.backpack:getItemNumByID(costItemID)
	self.labelPromote.text = __("EXCHANGE2")
	self.labelTip.text = __("ACTIVITY_PROMOTION_LADDER_TEXT09")

	if tonumber(xyd.db.misc:getValue("activity_promotion_ladder2_arrow_red" .. self.activityData:getUpdateTime())) ~= 1 then
		self.arrowRightRedMark:SetActive(true)
	end

	self.targetIndex = 0

	self.partnerPicture:SetActive(true)
	self:playPartnerPictureLoopEffect()
	self:update(true)
end

function ActivityPromotionLadder2:playPartnerPictureLoopEffect()
	if not self.showIndex then
		self.showIndex = 1
	end

	local pictureInfo = partnerPicture[self.showIndex] or partnerPicture[1]

	xyd.setUITextureByNameAsync(self.partnerPictureLoop, pictureInfo[1], true)
	self.partnerPictureLoop:SetLocalPosition(pictureInfo[3], pictureInfo[4], 0)
	self.partnerPictureLoop:SetLocalScale(pictureInfo[2], pictureInfo[2], 1)
end

function ActivityPromotionLadder2:update(init)
	if init then
		self:loadTarget()
	end

	self:updateData()
	self:updateModelAndIcon()
	self:updateBtn()
end

function ActivityPromotionLadder2:updateData()
	if not self.materialPartnerTableIDList then
		self.materialPartnerTableIDList = {}

		for i in pairs(materialPartner5StarTableID) do
			local tableIDList = xyd.tables.partnerTable:getHeroList(materialPartner5StarTableID[i])

			table.insert(self.materialPartnerTableIDList, tableIDList)
		end
	end

	if not self.targetPartnerTableIDList then
		self.targetPartnerTableIDList = {}

		for i in pairs(targetPartner5StarTableID) do
			local tableIDList = xyd.tables.partnerTable:getHeroList(targetPartner5StarTableID[i])

			table.insert(self.targetPartnerTableIDList, tableIDList)
		end
	end

	if not self.costMultiple then
		self.costMultiple = {}

		for u, v in pairs(costMultiple) do
			self.costMultiple[v[1]] = v[2]
		end
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

function ActivityPromotionLadder2:updateModelAndIcon()
	NGUITools.DestroyChildren(self.modelMaterial.transform)
	NGUITools.DestroyChildren(self.modelTarget.transform)

	if not self.materialPartner then
		self.materialModel = xyd.Spine.new(self.modelMaterial)

		self.materialModel:setInfo("fx_guanghuan", function ()
			self.materialModel:SetLocalPosition(0, 98, 0)
			self.materialModel:play("texiao01", 0, 1)
		end)

		if self.materialHeroIcon then
			self.materialHeroIcon:SetActive(false)
		end
	else
		local materialModelID = xyd.tables.partnerTable:getModelID(self.materialPartner:getTableID())
		local materialModelName = xyd.tables.modelTable:getModelName(materialModelID)
		local materialModelScale = xyd.tables.modelTable:getScale(materialModelID)
		self.materialModel = xyd.Spine.new(self.modelMaterial)

		self.materialModel:setInfo(materialModelName, function ()
			self.materialModel:SetLocalScale(materialModelScale, materialModelScale, 1)
			self.materialModel:play("idle", 0, 1)
		end)

		if not self.materialHeroIcon then
			self.materialHeroIcon = HeroIcon.new(self.iconMaterial.gameObject)
		else
			self.materialHeroIcon:SetActive(true)
		end

		self.materialHeroIcon:setInfo(self.materialPartner:getInfo())
		self.materialHeroIcon:setNoClick(true)
	end

	dump(self.targetIndex)

	if not self.targetIndex or self.targetIndex == 0 then
		dump(self.targetIndex)

		self.targetModel = xyd.Spine.new(self.modelTarget)

		self.targetModel:setInfo("fx_guanghuan", function ()
			self.targetModel:SetLocalPosition(0, 98, 0)
			self.targetModel:play("texiao01", 0, 1)
		end)

		if self.targetHeroIcon then
			self.targetHeroIcon:SetActive(false)
		end
	else
		local targetModelID = xyd.tables.partnerTable:getModelID(self:getTargetTableID())
		local targetModelName = xyd.tables.modelTable:getModelName(targetModelID)
		local targetModelScale = xyd.tables.modelTable:getScale(targetModelID)
		self.targetModel = xyd.Spine.new(self.modelTarget)

		self.targetModel:setInfo(targetModelName, function ()
			self.targetModel:SetLocalScale(targetModelScale, targetModelScale, 1)
			self.targetModel:play("idle", 0, 1)
		end)

		if not self.targetHeroIcon then
			self.targetHeroIcon = HeroIcon.new(self.iconTarget.gameObject)
		else
			self.targetHeroIcon:SetActive(true)
		end

		local star = xyd.tables.partnerTable:getStar(self:getTargetTableID())
		local lev = nil

		if self.materialPartner then
			lev = self.materialPartner:getLevel()
			star = self.materialPartner:getStar()
		end

		local targetPartnerInfo = {
			star = star,
			group = xyd.tables.partnerTable:getGroup(self:getTargetTableID()),
			tableID = self:getTargetTableID(),
			lev = lev
		}

		self.targetHeroIcon:setInfo(targetPartnerInfo)
		self.targetHeroIcon:setNoClick(true)
	end
end

function ActivityPromotionLadder2:updateBtn()
	if not self.materialPartner or not self.targetIndex then
		xyd.setEnabled(self.btnPromote.gameObject, false)

		self.labelPromoteNum.text = 0
	else
		xyd.setEnabled(self.btnPromote.gameObject, true)

		self.labelPromoteNum.text = self.costNum
	end

	if not self.materialPartner then
		self.btnExchangeMaterail:SetActive(false)
	else
		self.btnExchangeMaterail:SetActive(true)
	end

	if not self.targetIndex or self.targetIndex <= 0 then
		self.btnExchangeTarget:SetActive(false)
	else
		self.btnExchangeTarget:SetActive(true)
	end
end

function ActivityPromotionLadder2:selectMaterialPartner()
	local params = {
		needNum = 1,
		notPlaySaoguang = true,
		noClickSelected = true,
		type = "ACTIVITY_PROMOTION_LADDER2",
		isShowLovePoint = false,
		benchPartners = self.materialPartnerList,
		partners = self.materialPartner and {
			self.materialPartner:getPartnerID()
		} or nil,
		confirmCallback = function ()
			local win = xyd.WindowManager:get():getWindow("choose_partner_window")
			local selectPartnerID = (win:getSelected() or {})[1]

			if selectPartnerID then
				self.materialPartner = xyd.models.slot:getPartner(selectPartnerID)
			else
				self.materialPartner = nil
			end

			self:recordPartner()
			self:update()
		end,
		mTableIDList = materialPartner5StarTableID
	}

	function params.debrisCloseCallBack()
		self:updateData()

		params.benchPartners = self.materialPartnerList

		xyd.WindowManager:get():openWindow("choose_partner_window", params)
	end

	xyd.WindowManager:get():openWindow("choose_partner_window", params)
end

function ActivityPromotionLadder2:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function ()
		self.targetIndex = 0

		self:update()
	end)
	self:registerEvent(xyd.event.GET_SLOT_INFO, handler(self, self.updateData))
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(costItemID)
	end)

	UIEventListener.Get(self.btnHelp.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_PROMOTION_LADDER_TEXT01"
		})
	end

	UIEventListener.Get(self.btnDetail.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_promotion_ladder_detail_window", {
			activityID = xyd.ActivityID.ACTIVITY_PROMOTION_LADDER2
		})
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

	UIEventListener.Get(self.resPlus.gameObject).onClick = function ()
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_PROMOTION_TEST),
			select = xyd.ActivityID.ACTIVITY_PROMOTION_TEST
		})
	end

	UIEventListener.Get(self.materialDefault.gameObject).onClick = function ()
		self:selectMaterialPartner()
	end

	UIEventListener.Get(self.modelMaterial.gameObject).onClick = function ()
		self:onclickMaterialModel()
	end

	UIEventListener.Get(self.modelTarget.gameObject).onClick = function ()
		self:onclickTargetModel()
	end

	UIEventListener.Get(self.btnPromote.gameObject).onClick = function ()
		if not self.materialPartner then
			return
		end

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
			replace_index = self.targetIndex,
			replace_id = targetPartner5StarTableID[self.targetIndex]
		}

		xyd.alertYesNo(__("ACTIVITY_PROMOTION_LADDER_TEXT12"), function (yes)
			if yes then
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_PROMOTION_LADDER2, cjson.encode(params))
				self.activityData:recordPromoteTimes(self.costMultiple[self.materialPartner:getStar()])
				self.activityData:countOriginStarMaterial(self.materialPartner)

				self.materialPartner = nil

				self:recordPartner()
			end
		end)
	end

	UIEventListener.Get(self.btnExchangeMaterail.gameObject).onClick = function ()
		self:selectMaterialPartner()
	end

	UIEventListener.Get(self.btnExchangeTarget.gameObject).onClick = function ()
		self:onclickTargetModel()
	end
end

function ActivityPromotionLadder2:getTargetTableID(index)
	local targetIndex = self.targetIndex or 1

	if index then
		targetIndex = index
	end

	local starIndex = 1

	if self.materialPartner then
		local star = self.materialPartner:getStar()

		if star == 5 then
			starIndex = 1
		elseif star < 10 then
			starIndex = 2
		else
			starIndex = 3
		end
	end

	return self.targetPartnerTableIDList[targetIndex][starIndex]
end

function ActivityPromotionLadder2:recordPartner()
	xyd.db.misc:setValue({
		key = "activity_promotion_ladder2_partner_record" .. self.activityData:getUpdateTime(),
		value = self.materialPartner and self.materialPartner:getPartnerID() or 0
	})
end

function ActivityPromotionLadder2:loadTarget()
	local targetIndex = tonumber(xyd.db.misc:getValue("activity_promotion_ladder2_target_record" .. self.activityData:getUpdateTime()))

	if targetIndex then
		self.targetIndex = targetIndex
	end
end

function ActivityPromotionLadder2:recordTarget()
	xyd.db.misc:setValue({
		key = "activity_promotion_ladder2_target_record" .. self.activityData:getUpdateTime(),
		value = self.targetIndex or 1
	})
end

function ActivityPromotionLadder2:getSequence(complete)
	local sequence = DG.Tweening.DOTween.Sequence():OnComplete(function ()
		if complete then
			complete()
		end
	end)

	if not self.sequence_ then
		self.sequence_ = {}
	end

	table.insert(self.sequence_, sequence)

	return sequence
end

function ActivityPromotionLadder2:dispose()
	ActivityPromotionLadder2.super.dispose(self)

	if self.sequence_ then
		for i = 1, #self.sequence_ do
			if self.sequence_[i] then
				self.sequence_[i]:Kill(false)

				self.sequence_[i] = nil
			end
		end
	end
end

function ActivityPromotionLadder2:onclickMaterialModel()
	if not self.materialPartner then
		self:selectMaterialPartner()
	else
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
end

function ActivityPromotionLadder2:onclickTargetModel()
	local benchPartners = {}
	local choosedPartner = nil

	for i in pairs(targetPartner5StarTableID) do
		local tableID = self:getTargetTableID(i)
		local star = xyd.tables.partnerTable:getStar(tableID)
		local lev = nil

		if self.materialPartner then
			lev = self.materialPartner:getLevel()
			star = self.materialPartner:getStar()
		end

		local np = Partner.new()

		np:populate({
			partner_id = i,
			table_id = tableID,
			star = star,
			lev = lev
		})

		np.index = i

		table.insert(benchPartners, np)

		if self.targetIndex and self.targetIndex == i then
			choosedPartner = i
		end
	end

	local params = {
		needNum = 1,
		type = "ACTIVITY_PROMOTION_LADDER2",
		showBtnDebris = false,
		benchPartners = benchPartners,
		partners = {
			choosedPartner
		},
		confirmCallback = function ()
			local win = xyd.WindowManager:get():getWindow("choose_partner_window")

			dump(win:getSelected())

			local selectIndex = (win:getSelected() or {})[1]

			dump(selectIndex)

			if selectIndex then
				self.targetIndex = selectIndex
			else
				self.targetIndex = 0
			end

			self:recordTarget()
			self:update()
		end,
		titleText = __("ACTIVITY_PROMOTION_LADDER_TEXT13")
	}

	xyd.WindowManager:get():openWindow("choose_partner_window", params)
end

return ActivityPromotionLadder2
