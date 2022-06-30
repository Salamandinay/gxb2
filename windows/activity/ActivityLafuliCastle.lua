local ActivityLafuliCastle = class("ActivityLafuliCastle", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")
local progress1MaxPoint = xyd.tables.miscTable:split2Cost("activity_lflcastle_score_max", "value", "|")[1]
local progress2MaxPoint = xyd.tables.miscTable:split2Cost("activity_lflcastle_score_max", "value", "|")[2]
local resItemID1 = xyd.tables.miscTable:split2Cost("activity_lflcastle_score", "value", "|")[1]
local resItemID2 = xyd.tables.miscTable:split2Cost("activity_lflcastle_score", "value", "|")[2]
local partnerAwardEnergy = xyd.tables.miscTable:getNumber("activity_lflcastle_energy", "value")

function ActivityLafuliCastle:ctor(parentGO, params)
	ActivityLafuliCastle.super.ctor(self, parentGO, params)
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_LAFULI_CASTLE)
end

function ActivityLafuliCastle:getPrefabPath()
	return "Prefabs/Windows/activity/activity_lafuli_castle"
end

function ActivityLafuliCastle:resizeToParent()
	ActivityLafuliCastle.super.resizeToParent(self)
	self:resizePosY(self.castle, -468.5, -517.5)
	self:resizePosY(self.imgText, -2, -14)
	self:resizePosY(self.timeGroup, -164, -170)
	self:resizePosY(self.groupProgress1, -420, -482)
	self:resizePosY(self.groupProgress2, -420, -482)
	self:resizePosY(self.groupPartnerAward, -805, -950)
	self:resizePosY(self.resItem1, -676, -803)
	self:resizePosY(self.resItem2, -676, -803)
	self:resizePosY(self.btnTask, -823, -968)
end

function ActivityLafuliCastle:initUI()
	self:getUIComponent()
	ActivityLafuliCastle.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityLafuliCastle:getUIComponent()
	local go = self.go
	self.imgText = go:ComponentByName("imgText", typeof(UISprite))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.castle = go:NodeByName("castle").gameObject
	self.groupCastle = self.castle:NodeByName("groupCastle").gameObject

	for i = 1, 5 do
		self["castle" .. i] = self.groupCastle:NodeByName("castle" .. i).gameObject
	end

	self.groupFigure = self.castle:NodeByName("groupFigure").gameObject

	for i = 1, 5 do
		self["figure" .. i] = self.groupFigure:NodeByName("figure" .. i).gameObject
	end

	self.showEffectNode = self.castle:NodeByName("showEffect").gameObject
	self.boxColliders = self.castle:NodeByName("boxColliders").gameObject

	for i = 1, 11 do
		self["collider" .. i] = self.boxColliders:NodeByName("collider" .. i).gameObject
	end

	self.groupProgress1 = go:ComponentByName("groupProgress1", typeof(UISprite))
	self.labelProgress1 = self.groupProgress1:ComponentByName("labelProgress", typeof(UILabel))
	self.labelPoint1 = self.groupProgress1:ComponentByName("labelPoint", typeof(UILabel))
	self.progress1ScrollView = self.groupProgress1:ComponentByName("scrollView", typeof(UIScrollView))
	self.progress1ItemGroup = self.progress1ScrollView:NodeByName("itemGroup").gameObject
	self.groupProgress2 = go:ComponentByName("groupProgress2", typeof(UISprite))
	self.labelProgress2 = self.groupProgress2:ComponentByName("labelProgress", typeof(UILabel))
	self.labelPoint2 = self.groupProgress2:ComponentByName("labelPoint", typeof(UILabel))
	self.progress2ScrollView = self.groupProgress2:ComponentByName("scrollView", typeof(UIScrollView))
	self.progress2ItemGroup = self.progress2ScrollView:NodeByName("itemGroup").gameObject
	self.groupPartnerAward = go:ComponentByName("groupPartnerAward", typeof(UISprite))
	self.progressBar = self.groupPartnerAward:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressImg = self.progressBar:ComponentByName("progressImg", typeof(UISprite))
	self.progressNum = self.progressBar:ComponentByName("progressNum", typeof(UILabel))
	self.labelTip = self.groupPartnerAward:ComponentByName("labelTip", typeof(UILabel))
	self.parnterAwardEffectNode = self.groupPartnerAward:NodeByName("effect").gameObject
	self.resItem1 = go:ComponentByName("resItem1", typeof(UISprite))
	self.resNum1 = self.resItem1:ComponentByName("resNum", typeof(UILabel))
	self.resPlus1 = self.resItem1:NodeByName("resPlus").gameObject
	self.resEffectNode1 = self.resItem1:NodeByName("effect").gameObject
	self.resItem2 = go:ComponentByName("resItem2", typeof(UISprite))
	self.resNum2 = self.resItem2:ComponentByName("resNum", typeof(UILabel))
	self.resPlus2 = self.resItem2:NodeByName("resPlus").gameObject
	self.resEffectNode2 = self.resItem2:NodeByName("effect").gameObject
	self.btnHelp = go:NodeByName("btnHelp").gameObject
	self.btnTask = go:NodeByName("btnTask").gameObject
	self.labelTask = self.btnTask:ComponentByName("labelTask", typeof(UILabel))
	self.bubbleTask = self.btnTask:ComponentByName("bubbleTask", typeof(UISprite))
	self.itemCell = go:NodeByName("itemCell").gameObject
end

function ActivityLafuliCastle:initUIComponent()
	self:initText()
	self:initTasks()
	self:initEffect()
	self:updateAll()
end

function ActivityLafuliCastle:initText()
	xyd.setUISpriteAsync(self.imgText, nil, "activity_lafuli_castle_text_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
	end

	self.labelProgress1.text = __("ACTIVITY_LAFULI_CASTLE_TEXT01")
	self.labelProgress2.text = __("ACTIVITY_LAFULI_CASTLE_TEXT01")
	self.labelTask.text = __("ACTIVITY_LAFULI_CASTLE_TEXT02")
	self.labelTip.text = __("ACTIVITY_LAFULI_CASTLE_TEXT03", partnerAwardEnergy)

	if xyd.Global.lang == "zh_tw" then
		self.progressBar:Y(21)

		self.labelTip.spacingY = 3
	end

	if xyd.Global.lang == "ja_jp" then
		self.labelTip.spacingY = 3
		self.labelTask.fontSize = 20
	end

	if xyd.Global.lang == "ko_kr" then
		self.labelTip.width = 260
	end
end

function ActivityLafuliCastle:initTasks()
	self.awardIcons = {}
	local ids = xyd.tables.activityLflcastleAwardTable:getIDs()

	for i = 1, #ids do
		local type = xyd.tables.activityLflcastleAwardTable:getType(i)
		local award = xyd.tables.activityLflcastleAwardTable:getAward(i)
		local point = xyd.tables.activityLflcastleAwardTable:getCount(i)
		local parentGO = type == 1 and self.progress1ItemGroup.gameObject or self.progress2ItemGroup.gameObject
		local scrollView = type == 1 and self.progress1ScrollView or self.progress2ScrollView
		local item = NGUITools.AddChild(parentGO, self.itemCell)
		local labelPoint = item:ComponentByName("labelPoint", typeof(UILabel))
		local iconNode = item:NodeByName("icon").gameObject
		labelPoint.text = point
		local icon = xyd.getItemIcon({
			showGetWays = false,
			notShowGetWayBtn = true,
			show_has_num = true,
			scale = 0.5648148148148148,
			itemID = award[1],
			num = award[2],
			uiRoot = iconNode.gameObject,
			dragScrollView = scrollView,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
		self.awardIcons[i] = icon
	end

	self.progress1ItemGroup:GetComponent(typeof(UIGrid)):Reposition()
	self.progress2ItemGroup:GetComponent(typeof(UIGrid)):Reposition()
	self.progress1ScrollView:ResetPosition()
	self.progress2ScrollView:ResetPosition()
end

function ActivityLafuliCastle:updateAll()
	self:updateBackground()
	self:updateTasks()
	self:updatePartnerAward()
	self:updateResItem()
	self:updateTaskBtn()
end

function ActivityLafuliCastle:updateBackground()
	local ids = xyd.tables.activityLflcastleProgressTable:getIDs()

	for i = 1, #ids do
		local point = xyd.tables.activityLflcastleProgressTable:getCount(i)
		local type = xyd.tables.activityLflcastleProgressTable:getType(i)
		local object = xyd.tables.activityLflcastleProgressTable:getObject(i)

		if self.activityData.detail.points[type] < point then
			self[object]:SetActive(false)
		elseif not self.notFirstInit then
			self[object]:SetActive(true)

			self["curStage" .. type] = i
		elseif not self["curStage" .. type] or self["curStage" .. type] < i then
			self["curStage" .. type] = i

			self:playShowEffect(i)

			return
		end
	end
end

function ActivityLafuliCastle:initEffect()
	self.resUseEffect1 = xyd.Spine.new(self.resEffectNode1)

	self.resUseEffect1:setInfo("fx_lflcastle_click")

	self.resUseEffect2 = xyd.Spine.new(self.resEffectNode2)

	self.resUseEffect2:setInfo("fx_lflcastle_click")

	self.showEffect = xyd.Spine.new(self.showEffectNode)

	self.showEffect:setInfo("fx_lflcastle_show")
end

function ActivityLafuliCastle:playShowEffect(i)
	local object = xyd.tables.activityLflcastleProgressTable:getObject(i)
	local position = self[object].transform.localPosition

	self.showEffectNode:SetLocalPosition(position.x, position.y, position.z)
	self.showEffect:playWithEvent("texiao01", 1, 1, {
		show = function ()
			self[object]:SetActive(true)
		end,
		Complete = function ()
			self:updateBackground()
		end
	})
end

function ActivityLafuliCastle:updateTasks()
	self.labelPoint1.text = self.activityData.detail.points[1] .. "/" .. progress1MaxPoint
	self.labelPoint2.text = self.activityData.detail.points[2] .. "/" .. progress2MaxPoint
	self.taskNumofType2 = 0
	self.taskNumofType1 = 0
	self.curTaskIDofType2 = 0
	self.curTaskIDofType1 = 0

	for i = 1, #self.awardIcons do
		local type = xyd.tables.activityLflcastleAwardTable:getType(i)
		self["taskNumofType" .. type] = self["taskNumofType" .. type] + 1

		if self.activityData.detail.awards[i] == 1 then
			self.awardIcons[i]:setChoose(true)
			self.awardIcons[i]:setCallBack(nil)

			if self.awardIcons[i]:getIconType() == "hero_icon" then
				self.awardIcons[i]:setBackEffect(false)
			else
				self.awardIcons[i]:setEffect(false)
			end
		else
			local point = xyd.tables.activityLflcastleAwardTable:getCount(i)
			local taskPoint = type == 1 and self.activityData.detail.points[1] or self.activityData.detail.points[2]

			if point <= taskPoint then
				local function callback()
					local params = {
						type = 2,
						id = i
					}

					self.activityData:sendReq(params)
				end

				self.awardIcons[i]:setCallBack(callback)

				if self.awardIcons[i]:getIconType() == "hero_icon" then
					self.awardIcons[i]:setBackEffect(true, "fx_ui_bp_available", nil, {
						target_ = self.awardIcons[i]:getPartExample("gEffect"):GetComponent(typeof(UITexture))
					})
				else
					self.awardIcons[i]:setEffect(true, "fx_ui_bp_available")
				end
			end

			if self["curTaskIDofType" .. type] == 0 then
				self["curTaskIDofType" .. type] = self["taskNumofType" .. type]
			end
		end
	end

	self.curTaskIDofType1 = math.max(self.curTaskIDofType1, 1)
	self.curTaskIDofType2 = math.max(self.curTaskIDofType2, 1)
	local dis1 = math.min(83 + 106 * self.curTaskIDofType1, 83 + 106 * self.taskNumofType1 - 379)
	local dis2 = math.min(83 + 106 * self.curTaskIDofType2, 83 + 106 * self.taskNumofType2 - 379)

	if self.notFirstInit then
		self.progress1ScrollView.transform.localPosition = Vector3(0, dis1, 0)
		self.progress2ScrollView.transform.localPosition = Vector3(0, dis2, 0)
	else
		local sp1 = self.progress1ScrollView:GetComponent(typeof(SpringPanel))

		sp1.Begin(sp1.gameObject, Vector3(0, dis1, 0), 16)

		local sp2 = self.progress2ScrollView:GetComponent(typeof(SpringPanel))

		sp2.Begin(sp2.gameObject, Vector3(0, dis2, 0), 16)
	end

	self.notFirstInit = true
end

function ActivityLafuliCastle:updatePartnerAward()
	self.progressNum.text = self.activityData.detail.energy .. "/" .. partnerAwardEnergy
	self.progressBar.value = math.min(self.activityData.detail.energy, partnerAwardEnergy) / partnerAwardEnergy

	if partnerAwardEnergy <= self.activityData.detail.energy then
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_lafuli_castle_jdt4")

		if not self.parnterAwardEffect then
			self.parnterAwardEffect = xyd.Spine.new(self.parnterAwardEffectNode.gameObject)

			self.parnterAwardEffect:setInfo("fx_ui_bp_available", function ()
				self.parnterAwardEffect:SetLocalScale(0.6666666666666666, 0.6666666666666666, 1)
				self.parnterAwardEffect:play("texiao01", 0)
			end)
		else
			self.parnterAwardEffect:SetActive(true)
		end

		if not self.progressEffect then
			self.progressEffect = xyd.Spine.new(self.progressBar.gameObject)

			self.progressEffect:setInfo("dagon_jingdutiao", function ()
				self.progressEffect:SetLocalPosition(123, 0.6, 0)
				self.progressEffect:SetLocalScale(1.15, 1, 1)
				self.progressEffect:setRenderTarget(self.progressNum:GetComponent(typeof(UIWidget)), 0)
				self.progressEffect:play("texiao01", 0)
			end)
		else
			self.progressEffect:SetActive(true)
		end
	else
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_lafuli_castle_jdt3")

		if self.parnterAwardEffect then
			self.parnterAwardEffect:SetActive(false)
		end

		if self.progressEffect then
			self.progressEffect:SetActive(false)
		end
	end
end

function ActivityLafuliCastle:updateResItem()
	self.resNum1.text = xyd.models.backpack:getItemNumByID(resItemID1)

	if xyd.models.backpack:getItemNumByID(resItemID1) <= 0 then
		xyd.setUISpriteAsync(self.resItem1, nil, "activity_lafuli_castle_bubble2")
		self.resPlus1:SetActive(true)
		self.resNum1:SetActive(false)
	else
		xyd.setUISpriteAsync(self.resItem1, nil, "activity_lafuli_castle_bubble4")
		self.resPlus1:SetActive(false)
		self.resNum1:SetActive(true)
	end

	self.resNum2.text = xyd.models.backpack:getItemNumByID(resItemID2)

	if xyd.models.backpack:getItemNumByID(resItemID2) <= 0 then
		xyd.setUISpriteAsync(self.resItem2, nil, "activity_lafuli_castle_bubble3")
		self.resPlus2:SetActive(true)
		self.resNum2:SetActive(false)
	else
		xyd.setUISpriteAsync(self.resItem2, nil, "activity_lafuli_castle_bubble5")
		self.resPlus2:SetActive(false)
		self.resNum2:SetActive(true)
	end
end

function ActivityLafuliCastle:updateTaskBtn()
	if self.activityData.detail.m_point > 0 then
		self.bubbleTask:SetActive(true)
	else
		self.bubbleTask:SetActive(false)
	end
end

function ActivityLafuliCastle:register()
	UIEventListener.Get(self.btnHelp.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_LAFULI_CASTLE_HELP"
		})
	end

	UIEventListener.Get(self.btnTask.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_lafuli_castle_task_window")
	end

	UIEventListener.Get(self.bubbleTask.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_lafuli_castle_task_window")
	end

	UIEventListener.Get(self.groupPartnerAward.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_lafuli_castle_partner_award_window")
	end

	UIEventListener.Get(self.resItem1.gameObject).onClick = function ()
		if xyd.models.backpack:getItemNumByID(resItemID1) <= 0 then
			return
		end

		local params = {
			index = 1,
			type = 1,
			num = xyd.models.backpack:getItemNumByID(resItemID1)
		}

		self.activityData:sendReq(params)
		self.resUseEffect1:play("texiao01", 1)
	end

	UIEventListener.Get(self.resItem2.gameObject).onClick = function ()
		if xyd.models.backpack:getItemNumByID(resItemID2) <= 0 then
			return
		end

		local params = {
			index = 2,
			type = 1,
			num = xyd.models.backpack:getItemNumByID(resItemID2)
		}

		self.activityData:sendReq(params)
		self.resUseEffect2:play("texiao02", 1)
	end

	UIEventListener.Get(self.resPlus1.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = resItemID1
		})
	end

	UIEventListener.Get(self.resPlus2.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = resItemID2
		})
	end

	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:updateResItem()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function ()
		self:updateAll()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, function ()
		self:updateAll()
	end)

	for i = 1, 11 do
		UIEventListener.Get(self["collider" .. i].gameObject).onClick = function ()
			if i ~= 11 then
				local point = xyd.tables.activityLflcastleProgressTable:getCount(i)
				local type = xyd.tables.activityLflcastleProgressTable:getType(i)

				if self.activityData.detail.points[type] < point then
					xyd.alertTips(__("ACTIVITY_LAFULI_CASTLE_TEXT" .. 14 + type, point - self.activityData.detail.points[type]))
				end
			end

			if self.onSequence then
				return
			end

			self.onSequence = true
			local position = self.castle.transform.localPosition
			local sequence = self:getSequence()

			sequence:Insert(0, self.castle.transform:DOLocalMove(Vector3(position.x, position.y - 4, 0), 0.06666666666666667):SetEase(DG.Tweening.Ease.InOutSine))
			sequence:Insert(0.06666666666666667, self.castle.transform:DOLocalMove(Vector3(position.x, position.y + 2, 0), 0.1):SetEase(DG.Tweening.Ease.InOutSine))
			sequence:Insert(0.16666666666666666, self.castle.transform:DOLocalMove(Vector3(position.x, position.y, 0), 0.06666666666666667):SetEase(DG.Tweening.Ease.InOutSine))

			self.onSequence = false
		end
	end
end

function ActivityLafuliCastle:getSequence(complete)
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

return ActivityLafuliCastle
