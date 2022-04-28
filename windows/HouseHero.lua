local HouseHero = class("HouseHero", import("app.components.BaseComponent"))
local ModelTable = xyd.tables.modelTable
local HousePartnerTable = xyd.tables.housePartnerTable

function HouseHero:ctor(parentGO)
	HouseHero.super.ctor(self, parentGO)

	self.grids_ = {}
	self.curActionType = 0
	self.partnerInfo_ = nil
	self.heroModel_ = nil
	self.touchKey_ = -1
	self.moveNum_ = 0
	self.maxTimeCount = 15
	self.modelOffY = 25
	self.modelID_ = 0
	self.curModelID_ = 0
	self.isPlayDialog_ = false
	self.houseIdleCount_ = 1
	self.houseIdleNum_ = 0
	self.actions = {
		TOUCH = "hurt",
		IDLE2 = "idle",
		IDLE = "houseidle",
		LIE = "lie",
		TOUCH2 = "hit",
		WALK = "walk",
		SIT = "sit",
		MOVE = "move"
	}
	self.houseMap_ = xyd.HouseMap.get()
end

function HouseHero:getPrefabPath()
	return "Prefabs/Components/house_hero"
end

function HouseHero:initUI()
	HouseHero.super.initUI(self)

	local go = self.go
	self.groupGrid_ = go:NodeByName("groupGrid_").gameObject
	self.heroNode_ = go:NodeByName("heroNode_").gameObject
	self.groupDialog_ = go:NodeByName("groupDialog_").gameObject
	self.imgDialogBg_ = self.groupDialog_:ComponentByName("imgDialogBg_", typeof(UISprite))
	self.labelDialog_ = self.groupDialog_:ComponentByName("labelDialog_", typeof(UILabel))
	self.shadow_ = go:ComponentByName("shadow_", typeof(UISprite))
	self.touchNode_ = go:NodeByName("touchNode_").gameObject

	self.shadow_:SetActive(false)

	self.depthObjs_ = {
		self.go:GetComponent(typeof(UIWidget)),
		self.shadow_,
		self.groupGrid_:GetComponent(typeof(UIWidget)),
		self.heroNode_:GetComponent(typeof(UIWidget)),
		self.imgDialogBg_,
		self.labelDialog_,
		self.touchNode_:GetComponent(typeof(UIWidget))
	}
end

function HouseHero:init(params, partnerInfo, modelID, callback)
	self.curActionType = xyd.HouseItemActionType.NONE
	self.curModelID_ = modelID
	self.info_ = params
	self.partnerInfo_ = partnerInfo

	function self.callback_()
		if callback then
			callback()
		end

		if self.shadow_ then
			self.shadow_:SetActive(false)
		end
	end

	partnerInfo.tableID = partnerInfo.table_id or partnerInfo.tableID
	self.maxTimeCount = xyd.tables.miscTable:getNumber("house_partner_speed", "value") * xyd.FRAME_RATE_30
	self.houseIdleNum_ = HousePartnerTable:houseIdleNum(modelID)

	self:layout()
	self:updatePos()
	self:initGrid()
	self:initModel()
	self:registerEvent()
end

function HouseHero:initDress(params, partnerInfo, modelID, callback)
	self.actions.IDLE = "idle"
	self.curActionType = xyd.HouseItemActionType.NONE
	self.curModelID_ = modelID
	self.info_ = params
	self.partnerInfo_ = partnerInfo

	function self.callback_()
		if callback then
			callback()
		end

		if self.shadow_ then
			self.shadow_:SetActive(false)
		end
	end

	partnerInfo.tableID = xyd.models.selfPlayer.playerID_
	partnerInfo.isPlayer = true
	self.maxTimeCount = xyd.tables.miscTable:getNumber("house_partner_speed", "value") * xyd.FRAME_RATE_30

	self:layout()
	self:updatePos()
	self:initGrid()
	self:initDressModel()
	self:registerEvent()
end

function HouseHero:getPartnerInfo()
	return self.partnerInfo_
end

function HouseHero:isInteract()
	return self.curActionType == xyd.HouseItemActionType.INTERACT
end

function HouseHero:getAnimation()
	if not self:checkModelValid() then
		return ""
	end

	return self.heroModel_:getCurAction()
end

function HouseHero:clearAll()
	if self.heroModel_ then
		self.heroModel_:clearcClip()
		self.heroModel_:destroy()
	end
end

function HouseHero:canResetZorder()
	if self.curActionType == xyd.HouseItemActionType.INTERACT or self.curActionType == xyd.HouseItemActionType.MOVE then
		return false
	end

	return true
end

function HouseHero:initGrid()
	local houseGrid = xyd.HouseGrid.get()
	local info = self:getInfo()

	NGUITools.DestroyChildren(self.groupGrid_.transform)

	for row = 0, info:width() - 1 do
		for col = 0, info:length() - 1 do
			local item = houseGrid:getColorItem(row, col, info.cur_grid_type, xyd.HouseGridColorType.GREEN, self.groupGrid_)
			self.grids_[row * info:length() + col] = item
		end
	end

	local pos = houseGrid:getPiexlPosition(info.coord_x, info.coord_y, info.cur_grid_type)
	local selfPos = self:getGameObject().transform.localPosition
	local x = pos.x - selfPos.x
	local y = pos.y - selfPos.y

	self.groupGrid_:SetLocalPosition(x, y, 0)
	self:updateGridColor()
	self:showGrid(false)
end

function HouseHero:showGrid(flag)
	self.groupGrid_:SetActive(flag)
end

function HouseHero:updateGridColor()
	local info = self:getInfo()
	local result = self.houseMap_:checkHeroPosValid(self:getInfo())
	local houseGrid = xyd.HouseGrid.get()
	local parentDepth = self.groupGrid_:GetComponent(typeof(UIWidget)).depth

	for row = 0, info:width() - 1 do
		for col = 0, info:length() - 1 do
			local item = self.grids_[row * info:length() + col]

			if not result.flag then
				local icon = houseGrid:getColorIcon(info.cur_grid_type, xyd.HouseGridColorType.RED)

				xyd.setUISpriteAsync(item:GetComponent(typeof(UISprite)), nil, icon)
			else
				local color = xyd.checkCondition(result.interact, xyd.HouseGridColorType.BLUE, xyd.HouseGridColorType.GREEN)
				local icon = houseGrid:getColorIcon(info.cur_grid_type, color)

				xyd.setUISpriteAsync(item:GetComponent(typeof(UISprite)), nil, icon)
			end

			item:GetComponent(typeof(UISprite)).depth = parentDepth
		end
	end
end

function HouseHero:initModel()
	local partnerInfo = self.partnerInfo_
	local scale = xyd.getModelScale(partnerInfo.tableID, false, partnerInfo.skin_id, 1)
	local modelID = self.curModelID_
	local effectName = ModelTable:getModelName(modelID)
	self.heroModel_ = xyd.Spine.new(self.heroNode_)

	self.heroModel_:setInfo(effectName, function ()
		self.heroModel_:SetLocalPosition(0, self.modelOffY, 0)
		self.heroModel_:SetLocalScale(scale, scale, 1)
		self.heroModel_:setPlayNeedStop(true)
		self.heroModel_:setNoStopResumeSetupPose(true)
		self.shadow_:SetActive(true)

		local info = self:getInfo()
		local shade = ModelTable:getShadePos(modelID)
		local diretion = info.is_flip == 0 and 1 or -1
		local scaleMisc = xyd.tables.miscTable:split2num("house_shadow", "value", "|")
		local scaleX = shade[3] * scaleMisc[1]
		local scaleY = shade[3] * scaleMisc[2]

		self.shadow_:SetLocalPosition(shade[1] * diretion, shade[2] + self.modelOffY + 27, 0)
		self.shadow_:SetLocalScale(scaleX, scaleY, 1)
		self:setSpineLevel()

		if self.callback_ then
			self.callback_()
		end
	end)

	self.modelID_ = modelID
end

function HouseHero:initDressModel()
	self.modelOffY = 0
	self.heroModel_ = import("app.components.SenpaiModel").new(self.heroNode_)
	local scale = xyd.getModelScale(self.partnerInfo_.tableID, false)

	self.heroModel_:setModelInfo({
		ids = xyd.models.dress:getEffectEquipedStyles()
	})
	self.heroModel_:SetLocalScale(scale, scale, scale)

	local shadeScale = xyd.split(xyd.tables.miscTable:getVal("house_senpai_shadow_scale"), "|")

	self.shadow_:SetActive(true)
	self.shadow_:SetLocalScale(shadeScale[1], shadeScale[2], 1)
	table.insert(self.depthObjs_, self.heroModel_.headNode:GetComponent(typeof(UIWidget)))
	table.insert(self.depthObjs_, self.heroModel_.bodyNode:GetComponent(typeof(UIWidget)))
	table.insert(self.depthObjs_, self.heroModel_.footNode:GetComponent(typeof(UIWidget)))

	self.modelID_ = self.curModelID_
end

function HouseHero:updateScale()
	local partnerInfo = self.partnerInfo_
	local scale = xyd.getModelScale(partnerInfo.tableID, false, partnerInfo.skin_id, 1)

	self.heroModel_:SetLocalScale(scale, scale, 1)
	self:updateScaleX()
end

function HouseHero:changeModelRender(node, targetDelta)
	node = node or self.heroNode_
	targetDelta = targetDelta or 0

	self.heroModel_:setRenderTarget(node:GetComponent(typeof(UIWidget)), targetDelta)
end

function HouseHero:checkModelValid()
	return self.heroModel_ and self.heroModel_:isValid()
end

function HouseHero:idle()
	if not self:checkModelValid() or self.curActionType ~= xyd.HouseItemActionType.NONE then
		return
	end

	self.curActionType = xyd.HouseItemActionType.IDLE

	if self.houseIdleNum_ > 0 then
		self:checkResetState()
		self.heroModel_:play(self.actions.IDLE2, 0)
		self:checkResetStatePlayAtFrame()
	else
		self:checkResetState()
		self.heroModel_:play(self.actions.IDLE, 0)
		self:checkResetStatePlayAtFrame()
	end
end

function HouseHero:specialIdle(callback)
	if self.houseIdleNum_ < self.houseIdleCount_ then
		self.houseIdleCount_ = 1

		if callback then
			callback()
		end

		return
	end

	self:checkResetState()
	self.heroModel_:play(self.actions.IDLE .. self.houseIdleCount_, 1, 1, function ()
		self.houseIdleCount_ = self.houseIdleCount_ + 1

		self:specialIdle(callback)
	end)
	self:checkResetStatePlayAtFrame()
end

function HouseHero:interactIdle()
	if not self:checkModelValid() then
		return
	end

	local idleName = self.actions.IDLE

	if not self.heroModel_:hasAnimationName(idleName) then
		idleName = self.actions.IDLE2
	end

	self:checkResetState()
	self.heroModel_:play(idleName, 0)
	self:checkResetStatePlayAtFrame()
end

function HouseHero:touch()
	if not self:checkModelValid() or self.curActionType == xyd.HouseItemActionType.INTERACT then
		return
	end

	self.curActionType = xyd.HouseItemActionType.TOUCH
	local actionName = self.actions.TOUCH

	if self.heroModel_:hasAnimationName(self.actions.TOUCH2) then
		actionName = self.actions.TOUCH2
	end

	self:checkResetState()
	self.heroModel_:play(actionName, 1, 1, function ()
		self.curActionType = xyd.HouseItemActionType.NONE
	end)
	self:checkResetStatePlayAtFrame()

	if not self.partnerInfo_.isPlayer then
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.CLICK_HOUSE_HERO,
			data = {
				tableID = self.partnerInfo_.tableID,
				skinID = self.partnerInfo_.skin_id
			}
		})
	end
end

function HouseHero:move()
	if not self:checkModelValid() then
		return
	end

	if self.heroModel_.isClip_ then
		self:clearcClip()
	end

	self:updateScale()
	self:checkResetState()
	self.heroModel_:play(self.actions.MOVE, 0)
	self:checkResetStatePlayAtFrame()
end

function HouseHero:walk()
	if not self:checkModelValid() then
		return
	end

	if self.heroModel_:getCurAction() == self.actions.WALK then
		return
	end

	if self.curModelID_ == 5500702 or self.curModelID_ == 65601801 or self.curModelID_ == 5600801 or self.curModelID_ == 75600801 then
		self.heroModel_:setToSetupPose()
	end

	self:checkResetState()
	self.heroModel_:play(self.actions.WALK, 0)
	self:checkResetStatePlayAtFrame()
end

function HouseHero:sit()
	if not self:checkModelValid() then
		return
	end

	self:checkResetState()
	self.heroModel_:play(self.actions.SIT, 0)
	self:checkResetStatePlayAtFrame()
end

function HouseHero:sleep()
	if not self:checkModelValid() then
		return
	end

	if self.curModelID_ == 65601901 or self.curModelID_ == 5600901 or self.curModelID_ == 75600901 then
		self.heroModel_:setToSetupPose()
	end

	self:checkResetState()
	self.heroModel_:play(self.actions.LIE, 0)
	self:checkResetStatePlayAtFrame()
end

function HouseHero:playActionByName(actionName, count, ignoreStage)
	if count == nil then
		count = 1
	end

	if actionName == "move" then
		self:move()
	else
		if not self:checkModelValid() or not actionName then
			return
		end

		self:checkResetState()
		self.heroModel_:play(actionName, count)
		self:checkResetStatePlayAtFrame()
	end
end

function HouseHero:getInfo()
	return self.info_
end

function HouseHero:updateNormalPos()
	local info = self:getInfo()
	local pos = self.houseMap_:getMapPosByInfo(info)

	self:SetLocalPosition(pos.x, pos.y, 0)
	self:updateScaleX()
	self:changeTouchNodePos(xyd.HouseItemInteractType.NONE)
end

function HouseHero:updatePos()
	if self.curActionType == xyd.HouseItemActionType.NONE then
		local info = self:getInfo()
		local result = self.houseMap_:checkHeroPosInteract(info)

		if not result.flag then
			self:updateNormalPos()
		else
			self:interact(result.item)
		end
	else
		self:updateNormalPos()
	end
end

function HouseHero:updateScaleX()
	local info = self:getInfo()

	if self.heroModel_ then
		local scaleX = info.is_flip == 0 and 1 or -1
		local x, y, z = self.heroModel_:GetLocalScale()

		self.heroModel_:SetLocalScale(math.abs(x) * scaleX, y, 1)
	end

	if self.shadow_ and self.modelID_ > 0 then
		local shade = nil

		if self.modelID_ == xyd.models.selfPlayer.playerID_ then
			shade = {
				0,
				-27
			}
		else
			shade = ModelTable:getShadePos(self.modelID_)
		end

		local diretion = info.is_flip == 0 and 1 or -1
		local x = shade[1] * diretion
		local y = shade[2] + self.modelOffY + 27

		self.shadow_:SetLocalPosition(x, y, 0)

		if self.curActionType == xyd.HouseItemActionType.INTERACT then
			self.shadow_:SetActive(false)
		else
			self.shadow_:SetActive(true)
		end
	end
end

function HouseHero:layout()
end

function HouseHero:changeTouchNodePos(type)
	if not self.touchNode_ then
		return
	end

	if type == xyd.HouseItemInteractType.SLEEP then
		local direct = self:getInfo().is_flip == 1 and -1 or 1
	end
end

function HouseHero:registerEvent()
	if self.houseMap_:checkHeroCanTouch() then
		UIEventListener.Get(self.touchNode_).onClick = handler(self, self.onTouch)
		UIEventListener.Get(self.touchNode_).onPress = handler(self, self.onTouchBegin)
	end
end

function HouseHero:onTouch()
	if self.curActionType == xyd.HouseItemActionType.INTERACT or self:isPlayDialog() then
		return
	end

	self:touch()
end

function HouseHero:onTouchBegin(go, isPressd)
	if isPressd then
		if self:isPlayDialog() then
			return
		end

		XYDCo.WaitForTime(0.5, function ()
			self:longTouch()
		end, "onTouchBegin")

		UIEventListener.Get(self.touchNode_).onDrag = handler(self, self.onTouchMove)
		local info = self:getInfo()

		info:setRecordInfo(info.coord_x, info.coord_y, info.is_flip, info.grid_type_index)

		if self.curActionType ~= xyd.HouseItemActionType.INTERACT then
			self.curActionType = xyd.HouseItemActionType.TOUCH_BEGIN
		end
	else
		self:onTouchEnd()
	end
end

function HouseHero:longTouch()
	self.curActionType = xyd.HouseItemActionType.MOVE

	self.houseMap_:longTouchHeroItem(self)
	self:move()
end

function HouseHero:onTouchMove(go, delta)
	if self.curActionType == xyd.HouseItemActionType.MOVE then
		self.houseMap_:moveHeroItem(delta.x, delta.y, self)
		self:updateGridColor()
		self:showGrid(true)
		self.heroModel_:SetLocalPosition(0, 100, 0)
	end
end

function HouseHero:onTouchEnd(event)
	UIEventListener.Get(self.touchNode_).onDrag = nil

	XYDCo.StopWait("onTouchBegin")

	if self.curActionType == xyd.HouseItemActionType.MOVE or self.curActionType == xyd.HouseItemActionType.TOUCH_BEGIN then
		self.curActionType = xyd.HouseItemActionType.NONE

		self:checkCurPosValid()

		if self.curActionType ~= xyd.HouseItemActionType.INTERACT then
			self.houseMap_:updateHeroMapGridNum(self:getInfo())
		end

		self.houseMap_:updateAllHeroZOrder()
		self:showGrid(false)

		if self.heroModel_ and self:checkNeedSetupPose() then
			self.heroModel_:setToSetupPose()
		end

		self:initIdle2Action()

		self.moveData_ = nil
	end

	self.heroModel_:SetLocalPosition(0, self.modelOffY, 0)
end

function HouseHero:checkNeedSetupPose()
	return self.curModelID_ == 5400701 or self.curModelID_ == 75600601 or self.curModelID_ == 65601601 or self.curModelID_ == 5600601
end

function HouseHero:checkCurPosValid()
	local info = self:getInfo()
	local recordInfo = info.recordInfo_
	local result = self.houseMap_:checkHeroPosValid(self:getInfo())

	if result.flag == false then
		info:updateCoord(recordInfo.coord_x, recordInfo.coord_y)
		self:updatePos()

		return false
	elseif result.interact then
		if not self:checkHeroCanInteract() then
			info:updateCoord(recordInfo.coord_x, recordInfo.coord_y)
			self:updatePos()

			return false
		end

		self:updatePos()
	end

	return true
end

function HouseHero:interact(item)
	item:addHeroNode(self)

	local itemInfo = item:getInfo()
	local info = self:getInfo()
	local partnerInfo = self.partnerInfo_
	local modelID = self.curModelID_
	local offsetPos = {
		x = 0,
		y = 0
	}

	if itemInfo.interact == xyd.HouseItemInteractType.SIT then
		info.is_flip = itemInfo.is_flip
		local sitOffset = HousePartnerTable:sitPosOffset(modelID)
		offsetPos.x = sitOffset[1]
		offsetPos.y = sitOffset[2]

		self:sit()
		self:changeTouchNodePos(xyd.HouseItemInteractType.SIT)
	elseif itemInfo.interact == xyd.HouseItemInteractType.SLEEP then
		info.is_flip = itemInfo.is_flip
		local lieOffset = HousePartnerTable:liePosOffset(modelID)
		offsetPos.x = lieOffset[1]
		offsetPos.y = lieOffset[2]

		self:sleep()
		self:changeTouchNodePos(xyd.HouseItemInteractType.SLEEP)
	elseif itemInfo.interact == xyd.HouseItemInteractType.IDLE then
		info.is_flip = itemInfo.is_flip
		local idleOffset = HousePartnerTable:idlePosOffset(modelID)
		offsetPos.x = idleOffset[1]
		offsetPos.y = idleOffset[2]

		self:interactIdle()
	else
		self:interactIdle()
	end

	if itemInfo.item_id == 1050016 then
		self.heroModel_:SetLocalScale(0.1, 0.1, 1)
	end

	local flipDiretion = itemInfo:getInteractDiretion(itemInfo:getPointXyIndex(self))

	if flipDiretion == 1 and info.is_flip == 1 then
		info.is_flip = 0
	elseif flipDiretion == 1 then
		info.is_flip = 1
	elseif flipDiretion == 2 then
		info.is_flip = 0
	end

	local pointXy = itemInfo:getFreePointXy(self)
	local x_, y_ = nil

	if info.is_flip == 1 then
		x_ = -(pointXy.x + offsetPos.x)
	else
		x_ = pointXy.x + offsetPos.x
	end

	y_ = pointXy.y + offsetPos.y

	self:SetLocalPosition(x_, -y_, 0)

	info.parent = item
	self.curActionType = xyd.HouseItemActionType.INTERACT

	self:updateScaleX()
	item:showEffect()
end

function HouseHero:playAction(isNewUpdateZorder)
	if self.curActionType ~= xyd.HouseItemActionType.NONE or not self:checkModelValid() then
		return
	end

	if self.moveData_ then
		self:playMoveAction(isNewUpdateZorder)
	else
		self:initAutoAction(isNewUpdateZorder)
	end

	if isNewUpdateZorder then
		self.shadow_:SetActive(true)
	end
end

function HouseHero:initAutoAction(isNewUpdateZorder)
	local rand = math.random()

	if rand < 0.2 then
		self:initIdle2Action(isNewUpdateZorder)
	else
		self:initMoveAction(isNewUpdateZorder)
	end
end

function HouseHero:initIdle2Action(isNewUpdateZorder)
	if not self.heroModel_ or self.curActionType ~= xyd.HouseItemActionType.NONE then
		return
	end

	if isNewUpdateZorder then
		self.houseMap_:updateAllHeroZOrder()
		self:setSpineLevel()
	end

	self.curActionType = xyd.HouseItemActionType.IDLE2

	if self.houseIdleNum_ > 0 then
		self.houseIdleCount_ = 1

		self:specialIdle(function ()
			if self.curActionType == xyd.HouseItemActionType.IDLE2 then
				self.curActionType = xyd.HouseItemActionType.NONE
			end
		end)
	else
		self:checkResetState()
		self.heroModel_:play(self.actions.IDLE, 2, 1, function ()
			if self.curActionType == xyd.HouseItemActionType.IDLE2 then
				self.curActionType = xyd.HouseItemActionType.NONE
			end
		end)
		self:checkResetStatePlayAtFrame()
	end
end

function HouseHero:initMoveAction(isNewUpdateZorder)
	local info = self:getInfo()

	if not self.heroModel_ or self.curActionType ~= xyd.HouseItemActionType.NONE then
		return
	end

	self.moveNum_ = self.moveNum_ + 1

	if self.moveNum_ > 6 then
		self.moveData_ = nil
		self.moveNum_ = 0

		return false
	end

	local directIndex = nil

	if self.moveData_ then
		directIndex = self.moveData_.index
	end

	local moveData = self.houseMap_:initMoveAction(self, directIndex)

	if moveData then
		self.moveData_ = moveData

		self:updateMoveData()
	else
		self.moveData_ = nil

		self:idle()
	end

	if isNewUpdateZorder then
		self.houseMap_:updateAllHeroZOrder()
		self:setSpineLevel()
	end
end

function HouseHero:updateMoveData()
	local duration = self.maxTimeCount
	local pos = self:getGameObject().transform.localPosition
	local speedX = (self.moveData_.x - pos.x) / duration
	local speedY = (self.moveData_.y - pos.y) / duration
	self.moveData_.speedX = speedX
	self.moveData_.speedY = speedY
	self.moveData_.timeCount = 0
end

function HouseHero:playMoveAction(isNewUpdateZorder)
	local direct = self.moveData_
	local info = self:getInfo()

	if direct.timeCount == 0 then
		if direct.direct_x > 0 then
			info.is_flip = 0
		elseif direct.direct_x < 0 then
			info.is_flip = 1
		end

		if direct.direct_y > 0 then
			info.is_flip = 1
		elseif direct.direct_y < 0 then
			info.is_flip = 0
		end

		self:updateScaleX()
		self.houseMap_:resetHeroMapGridNum(info)
		info:updateCoord(direct.direct_x + info.coord_x, direct.direct_y + info.coord_y)
	end

	self:walk()

	if direct.interact then
		self.moveData_ = nil

		return self:updatePos()
	end

	if direct.timeCount == 0 or isNewUpdateZorder then
		self.houseMap_:updateHeroMapGridNum(info)
		self.houseMap_:updateAllHeroZOrder()
		self:setSpineLevel()
	end

	direct.timeCount = direct.timeCount + 1
	local pos = self:getGameObject().transform.localPosition

	self:SetLocalPosition(pos.x + direct.speedX, pos.y + direct.speedY, 0)

	if self.maxTimeCount <= direct.timeCount then
		self:SetLocalPosition(direct.x, direct.y, 0)
		self:updatePos()
		self:initMoveAction()
	end
end

function HouseHero:checkHeroCanInteract()
	if not self:checkModelValid() then
		return false
	end

	local needNames = {
		self.actions.SIT,
		self.actions.LIE
	}

	for i = 1, #needNames do
		local effectName = needNames[i]

		if not self.heroModel_:hasAnimationName(effectName) then
			return false
		end
	end

	return true
end

function HouseHero:isRide()
	local partnerInfo = self.partnerInfo_
	local modelID = xyd.getModelID(partnerInfo.tableID, false, partnerInfo.skin_id, 1)

	return HousePartnerTable:isRide(modelID)
end

function HouseHero:hideDialog()
	self.groupDialog_:SetActive(false)
end

function HouseHero:showDialog()
	local partnerInfo = self.partnerInfo_
	local scale = xyd.getModelScale(partnerInfo.tableID, false, partnerInfo.skin_id, 1)
	local y_ = self.heroModel_:getBone("Phead").Y

	self.groupDialog_:Y(y_ * scale + 20)
	self.groupDialog_:SetActive(true)
end

function HouseHero:playDialog(str)
	if not self:checkModelValid() then
		return false
	end

	self.labelDialog_.text = str

	self:showDialog()

	return true
end

function HouseHero:isPlayDialog()
	return self.isPlayDialog_
end

function HouseHero:setPlayDialog(flag)
	self.isPlayDialog_ = flag

	if not flag and self.curActionType == xyd.HouseItemActionType.WAIT_DIALOG then
		self.curActionType = xyd.HouseItemActionType.NONE
	end
end

function HouseHero:canPlayDialog()
	if self:isPlayDialog() or self.curActionType == xyd.HouseItemActionType.MOVE or self.curActionType == xyd.HouseItemActionType.TOUCH or self.curActionType == xyd.HouseItemActionType.TOUCH_BEGIN then
		return false
	end

	return true
end

function HouseHero:playDialogMove(params)
	if self.moveData_ and self.moveData_.timeCount < self.maxTimeCount then
		self:playMoveAction()

		return
	end

	self.moveData_ = nil

	if params.endIndex <= params.index then
		params.is_end = true

		self:checkResetState()
		self.heroModel_:play(self.actions.IDLE, 0)
		self:checkResetStatePlayAtFrame()

		return
	end

	local nextPos = params.path[params.index]
	params.index = params.index + 1
	local info = self:getInfo()
	local pos = self.houseMap_:getHeroPosByCoord(nextPos.x, nextPos.y)
	local newMoveData = {
		interact = false,
		index = 0,
		x = pos.x,
		y = pos.y,
		direct_x = nextPos.x - info.coord_x,
		direct_y = nextPos.y - info.coord_y
	}
	self.moveData_ = newMoveData

	self:updateMoveData()
end

function HouseHero:stopMoveWaitDialog(flag)
	self.curActionType = xyd.HouseItemActionType.WAIT_DIALOG
end

function HouseHero:checkRoundHasFreeGrid()
	local result = self.houseMap_:getRoundFreeGrids(self)

	return result
end

function HouseHero:resumeFree(pos)
	local info = self:getInfo()

	info:updateCoord(pos.x, pos.y)

	self.curActionType = xyd.HouseItemActionType.NONE

	self.houseMap_:longTouchHeroItem(self)

	self.moveData_ = nil

	self.houseMap_:updateAllHeroZOrder()

	return true
end

function HouseHero:changeColor(color)
	if self.heroModel_ then
		self.heroModel_:setAlpha(color.a)
	end
end

function HouseHero:setClip(clipTransform, centerPos, radius)
	if self.heroModel_ then
		self.heroModel_:setClip(clipTransform, centerPos, radius)
	end
end

function HouseHero:clearcClip()
	if self.heroModel_ then
		self.heroModel_:clearcClip()
	end
end

function HouseHero:updateDepthObj(depth, node, targetDelta)
	local maxDepath = HouseHero.super.updateDepthObj(self, depth)

	if node then
		self.heroModel_:setRenderTarget(node:GetComponent(typeof(UIWidget)), targetDelta)
	end

	return maxDepath
end

function HouseHero:setSpineLevel()
	if self.heroModel_ then
		self.heroModel_:setRenderTarget(self.heroNode_.gameObject:GetComponent(typeof(UIWidget)), 0)
	end
end

function HouseHero:checkResetState()
	local resetState = xyd.tables.modelTable:getHouseResetState(self.curModelID_)

	if resetState and resetState == 1 then
		self.heroModel_:setToSetupPose()
	end
end

function HouseHero:checkResetStatePlayAtFrame()
	local resetState = xyd.tables.modelTable:getHouseResetState(self.curModelID_)

	if resetState and resetState == 1 then
		self.heroModel_:startAtFrame(0)
	end
end

return HouseHero
