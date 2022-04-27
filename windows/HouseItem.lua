local HouseItem = class("HouseItem", import("app.components.BaseComponent"))
local HouseFurnitureTable = xyd.tables.houseFurnitureTable
local HouseFurnitureEffectTable = xyd.tables.houseFurnitureEffectTable

function HouseItem:ctor(parentGO, parent)
	self.parent_ = parent

	HouseItem.super.ctor(self, parentGO)

	self.itemID_ = 0
	self.grids_ = {}
	self.curActionType = 0
	self.isPosValid_ = true
	self.curTexiaoID = 0
	self.houseMap_ = xyd.HouseMap.get()
	self.hashCode = 0
	self.houseboard_ = {}
end

function HouseItem:getPrefabPath()
	return "Prefabs/Components/house_item"
end

function HouseItem:initUI()
	HouseItem.super.initUI(self)

	local go = self.go
	self.img0 = go:ComponentByName("img0", typeof(UISprite))
	self.img1 = go:ComponentByName("img1", typeof(UISprite))
	self.groupGrid_ = go:NodeByName("groupGrid_").gameObject
	self.groupSpecial_ = go:NodeByName("groupSpecial_").gameObject
	self.heroNode = go:NodeByName("heroNode").gameObject
	self.groupSpecialEffect_ = go:NodeByName("groupSpecialEffect_").gameObject
	self.effectNode = go:NodeByName("effect").gameObject
	self.depthIn = go:NodeByName("depthIn").gameObject
	self.depthObjs_ = {
		self.go:GetComponent(typeof(UIWidget)),
		self.groupGrid_:GetComponent(typeof(UIWidget)),
		self.groupSpecial_:GetComponent(typeof(UIWidget)),
		self.groupSpecialEffect_:GetComponent(typeof(UIWidget)),
		self.img0,
		self.heroNode:GetComponent(typeof(UIWidget)),
		self.effectNode:GetComponent(typeof(UIWidget)),
		self.depthIn:GetComponent(typeof(UIWidget)),
		self.img1
	}
	self.heroEffectdepthObjs_ = {
		self.img1
	}
end

function HouseItem:init(params)
	self.curActionType = xyd.HouseItemActionType.NONE
	self.itemID_ = params.item_id
	self.info_ = params

	self:layout()
	self:updatePos()
	self:registerEvent()
end

function HouseItem:updateByInfo(info)
	self.itemID_ = info.item_id
	self.info_ = info

	self:updatePos()
	self:setImg()
end

function HouseItem:getInfo()
	return self.info_
end

function HouseItem:updatePos()
	local info = self:getInfo()
	local pos = self.houseMap_:getMapPosByInfo(info)

	self:SetLocalPosition(pos.x, pos.y, 0)
	self:updateScaleX()
	self:updatePosByParent(info.parent)
	self:showEffect()
end

function HouseItem:updatePosByParent(parentItem)
	if not parentItem then
		return
	end

	local parentInfo = parentItem:getInfo()

	if parentInfo:getPileOffsetX() ~= nil then
		local pos = self:getGameObject().transform.localPosition
		local x = pos.x + (parentInfo:getPileOffsetX() or 0)
		local y = pos.y - (parentInfo:getPileOffsetY() or 0)

		self:SetLocalPosition(x, y, 0)
	end
end

function HouseItem:updateScaleX()
	local info = self:getInfo()
	local flipImg = HouseFurnitureTable:getFlipImg(self.itemID_)

	for i = 1, #self.imgs_ do
		local img = self.imgs_[i]
		local scaleX = xyd.checkCondition(info.is_flip == 0, 1, -1)

		if info.cur_grid_type == xyd.HouseGridType.RIGHT_WALL and (not flipImg or not flipImg[1]) then
			scaleX = -1 * scaleX
		end

		img:SetLocalScale(scaleX, 1, 1)
	end

	self:setNormalImg()
end

function HouseItem:layout()
	self.imgs_ = {
		self.img0,
		self.img1
	}

	for i = 1, #self.imgs_ do
		local img = self.imgs_[i]

		if self.info_.cur_grid_type == xyd.HouseGridType.FLOOR then
			img.pivot = UIWidget.Pivot.Bottom
		else
			img.pivot = UIWidget.Pivot.Center
		end
	end

	self:setImg()
end

function HouseItem:registerEvent()
	if self:checkCanTouch() then
		UIEventListener.Get(self.img0.gameObject).onClick = handler(self, self.onTouch)

		UIEventListener.Get(self.img0.gameObject).onDragStart = function ()
			if not self.isStart_ then
				self.parent_.curWnd_:onScrollTouchBegin()
			end
		end

		UIEventListener.Get(self.img0.gameObject).onDrag = function (go, delta)
			if not self.isStart_ then
				self.parent_.curWnd_:onTouchMove(delta)
			end
		end

		UIEventListener.Get(self.img0.gameObject).onDragEnd = function (go)
			if not self.isStart_ then
				self.parent_.curWnd_:onTouchEnd()
			end
		end
	end

	local delay = self:checkTimeAction()

	if delay > 0 then
		self.houseMap_:addTimeAction(self, delay)
	end
end

function HouseItem:setTouchEnable(flag)
	xyd.setTouchEnable(self.img0.gameObject, flag)
end

function HouseItem:checkCanTouch()
	return self.info_.special_type ~= xyd.HouseItemSpecialType.FLOOR_OR_WALL_PAPER
end

function HouseItem:onTouch(event)
	local flag = self.houseMap_:touchItem(self)

	if flag then
		self:changeStaus(true)
	end
end

function HouseItem:onTouchMove(delta)
	self.curActionType = xyd.HouseItemActionType.MOVE
	local info = self:getInfo()

	self.houseMap_:moveItem(delta.x, delta.y, info)
	self:updateGridColor()
end

function HouseItem:setImg()
	if self.info_.special_type ~= xyd.HouseItemSpecialType.FLOOR_OR_WALL_PAPER then
		self:setNormalImg()
	else
		self:initSpecialImg()
	end
end

function HouseItem:setNormalImg()
	if self.info_.special_type == xyd.HouseItemSpecialType.FLOOR_OR_WALL_PAPER then
		return
	end

	local info = self:getInfo()
	local iconPaths = HouseFurnitureTable:getImg(self.itemID_)
	local iconFloors = HouseFurnitureTable:getFurnitureFloor(self.itemID_)
	local interactImgs = HouseFurnitureTable:interactImg(self.itemID_)

	if info.is_flip == 1 or info.cur_grid_type == xyd.HouseGridType.RIGHT_WALL then
		local flipImgs = HouseFurnitureTable:getFlipImg(self.itemID_)

		if #flipImgs > 0 and flipImgs[1] then
			iconPaths = flipImgs
		end
	end

	if #info.interactHeros > 0 and #interactImgs > 0 and interactImgs[1] ~= "" then
		iconPaths = interactImgs
	end

	local offsetPos = info.offset_pos
	local direct = info.is_flip == 1 and -1 or 1

	for i = 1, #iconPaths do
		local floor = iconFloors[i] or 0
		local img = self["img" .. tostring(floor)]

		xyd.setUISpriteAsync(img, nil, iconPaths[i], function ()
			img:MakePixelPerfect()
		end)

		local x = 0
		local y = 0

		if offsetPos[1] then
			x = offsetPos[1] * direct
		end

		if info.cur_grid_type == xyd.HouseGridType.FLOOR then
			y = offsetPos[2] or 0
		else
			y = offsetPos[2] or 0
		end

		img:SetActive(true)
		img:SetLocalPosition(x, y, 0)
	end
end

function HouseItem:initSpecialImg()
	local houseGrid = xyd.HouseGrid.get()
	local info = self:getInfo()
	local power = 6
	local isWall = false

	self.groupSpecial_:SetActive(true)
	self.groupSpecialEffect_:SetActive(true)
	NGUITools.DestroyChildren(self.groupSpecial_.transform)
	NGUITools.DestroyChildren(self.groupSpecialEffect_.transform)

	self.houseboard_ = {}

	for _, gridType in ipairs(info.grid_type) do
		local size = houseGrid:getMaxSizeByGridType(gridType, power)
		local c_length = size.c_length
		local c_with = size.c_with
		local anchor = houseGrid:getIconAnchor(gridType, power, true)

		for coordY = 0, c_with - 1 do
			for coordX = 0, c_length - 1 do
				local img = self:getImgByCoord(coordX, coordY, anchor, gridType)
				local pos = houseGrid:getPiexlPosition(coordX, coordY, gridType, power, true)

				img:SetLocalPosition(pos.x, pos.y, 0)
				self:initSpecialEffect(pos, gridType)
			end
		end

		if gridType ~= xyd.HouseGridType.FLOOR then
			self:initHousePillar(gridType)

			isWall = true
		end
	end

	if isWall then
		self:initHouseBoard(xyd.HouseGridType.FLOOR)
	end
end

function HouseItem:hideHouseBoard()
	for i = 1, #self.houseboard_ do
		if self.houseboard_[i] then
			self.houseboard_[i]:SetActive(false)
		end
	end
end

function HouseItem:showHouseBoard()
	for i = 1, #self.houseboard_ do
		if self.houseboard_[i] then
			self.houseboard_[i]:SetActive(true)
		end
	end
end

function HouseItem:getImgByCoord(coordX, coordy, anchor, gridType)
	local stuix = ""
	local imgSetType = HouseFurnitureTable:imgSetType(self.itemID_)

	if gridType ~= xyd.HouseGridType.FLOOR and imgSetType == 0 then
		if coordX == 0 then
			stuix = "_1"
		else
			stuix = "_2"
		end
	elseif imgSetType == 3 then
		local flag = (coordX + coordy) % 2 == 1
		stuix = flag and "_1" or "_2"
	end

	local img = NGUITools.AddChild(self.groupSpecial_, "s_img")
	local sp = img:AddComponent(typeof(UISprite))
	sp.depth = self.groupSpecial_:GetComponent(typeof(UIWidget)).depth + 1

	if gridType ~= xyd.HouseGridType.FLOOR then
		sp.type = UIBasicSprite.Type.Sliced

		xyd.setUISpriteOffsetType(sp, xyd.SpriteOffsetType.Left_Right)
	end

	local imgPath = HouseFurnitureTable:getImg(self.itemID_)[1] .. stuix

	xyd.setUISpriteAsync(sp, nil, imgPath, function ()
		if sp then
			sp:MakePixelPerfect()
		end
	end)

	if anchor.pivot then
		sp.pivot = anchor.pivot
	end

	img:SetLocalScale(anchor.scaleX, 1, 1)

	if imgSetType == 1 then
		local flag = (coordX + coordy) % 2 == 1
		local scaleX = xyd.checkCondition(flag, -1, 1)

		img:SetLocalScale(anchor.scaleX * scaleX, 1, 1)
	end

	return img
end

function HouseItem:initHousePillar(gridType)
	local houseGrid = xyd.HouseGrid.get()
	local img = NGUITools.AddChild(self.groupSpecial_, "house_pillar")
	local imgSp = img:AddComponent(typeof(UISprite))
	imgSp.depth = self.groupSpecial_:GetComponent(typeof(UIWidget)).depth
	imgSp.pivot = UIWidget.Pivot.TopLeft

	xyd.setUISpriteAsync(imgSp, nil, "house_pillar", function ()
		imgSp:MakePixelPerfect()
	end)

	local size = houseGrid:getMaxSizeByGridType(gridType)
	local pos = houseGrid:getPiexlPosition(size.c_length, size.c_with, gridType, 1, true)
	local x_ = 0
	local y_ = pos.y + 40

	if gridType == xyd.HouseGridType.LEFT_WALL then
		x_ = pos.x - 82
	else
		x_ = pos.x - 3
	end

	img:SetLocalPosition(x_, y_, 0)
	table.insert(self.houseboard_, img)
end

function HouseItem:initHouseBoard(gridType)
	local houseGrid = xyd.HouseGrid.get()
	local power = 6
	local depth = self.groupSpecial_:GetComponent(typeof(UIWidget)).depth
	local size = houseGrid:getMaxSizeByGridType(gridType, power)

	local function getImg(index, parentGO)
		local iconPath = "house_board_1"

		if index > 0 then
			iconPath = "house_board_2"
		end

		local img = NGUITools.AddChild(parentGO, "house_board")
		local imgSp = img:AddComponent(typeof(UISprite))
		imgSp.depth = depth
		imgSp.pivot = UIWidget.Pivot.TopLeft
		imgSp.type = UIBasicSprite.Type.Sliced

		xyd.setUISpriteOffsetType(imgSp, xyd.SpriteOffsetType.Left_Right)
		xyd.setUISpriteAsync(imgSp, nil, iconPath, function ()
			imgSp:MakePixelPerfect()
		end)

		return img
	end

	for coordX = 0, size.c_length - 1 do
		local img = getImg(coordX, self.groupSpecial_)

		table.insert(self.houseboard_, img)

		local pos = houseGrid:getPiexlPosition(coordX, size.c_with, gridType, power, false)
		local x_ = 0
		local y_ = 0

		if coordX == 0 then
			x_ = pos.x - 25
			y_ = pos.y - 25
		else
			x_ = pos.x
			y_ = pos.y - 23
		end

		img:SetLocalPosition(x_, y_, 0)
	end

	for coordY = 0, size.c_with - 1 do
		local img = getImg(coordY, self.groupSpecial_)

		table.insert(self.houseboard_, img)

		local pos = houseGrid:getPiexlPosition(size.c_length, coordY, gridType, power, false)
		local x_ = 0
		local y_ = 0

		if coordY == 0 then
			x_ = pos.x + 25
			y_ = pos.y - 25
		else
			x_ = pos.x
			y_ = pos.y - 23
		end

		img:SetLocalPosition(x_, y_, 0)
		img:SetLocalScale(-1, 1, 1)
	end
end

function HouseItem:initGrid()
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
end

function HouseItem:updateGridColor()
	local info = self:getInfo()
	local result = self.houseMap_:getInvalidGrids(info)
	local houseGrid = xyd.HouseGrid.get()
	self.isPosValid_ = result.isValid
	local invalidGrids = result.invalidGrids
	local colorGrids = result.colorGrids

	for row = 0, info:width() - 1 do
		for col = 0, info:length() - 1 do
			local item = self.grids_[row * info:length() + col]

			if invalidGrids[tostring(col) .. "#" .. tostring(row)] then
				local icon = houseGrid:getColorIcon(info.cur_grid_type, xyd.HouseGridColorType.RED)

				xyd.setUISpriteAsync(item:GetComponent(typeof(UISprite)), nil, icon)
			else
				local color = colorGrids[tostring(col) .. "#" .. tostring(row)] or xyd.HouseGridColorType.GREEN
				local icon = houseGrid:getColorIcon(info.cur_grid_type, color)

				xyd.setUISpriteAsync(item:GetComponent(typeof(UISprite)), nil, icon)
			end
		end
	end

	if result.isValid and result.parentItem then
		self:updatePosByParent(result.parentItem)
	end
end

function HouseItem:changeStaus(isStart)
	local toAlpha = 1

	if isStart then
		toAlpha = 0.7

		self.groupGrid_:SetActive(true)

		self.isStart_ = true
	else
		toAlpha = 1

		self.groupGrid_:SetActive(false)

		self.isStart_ = false
		self.curActionType = xyd.HouseItemActionType.NONE
	end

	for i = 1, #self.imgs_ do
		local img = self.imgs_[i]
		img.alpha = toAlpha
	end

	if isStart == false then
		-- Nothing
	end
end

function HouseItem:updateFilp(isAction)
	if isAction == nil then
		isAction = true
	end

	if isAction then
		self.curActionType = xyd.HouseItemActionType.FLIP
	end

	self:updatePos()
	self:initGrid()
end

function HouseItem:checkNoAction()
	return self.curActionType == xyd.HouseItemActionType.NONE
end

function HouseItem:isPosValid()
	return self.isPosValid_
end

function HouseItem:getCenterPos()
	local selfPos = self:getGameObject().transform.localPosition
	local pos = {
		x = selfPos.x,
		y = selfPos.y
	}
	local info = self:getInfo()

	if info.cur_grid_type == xyd.HouseGridType.FLOOR then
		local tmpCenterPos = xyd.HouseGrid.get():getPiexlPosition(info:length() / 2, info:width() / 2, info.cur_grid_type)
		pos.x = pos.x - tmpCenterPos.x
		pos.y = pos.y - tmpCenterPos.y

		if info:getPileOffsetX() ~= nil then
			pos.x = pos.x + (info:getPileOffsetX() or 0)
			pos.y = pos.y - (info:getPileOffsetY() or 0)
		end
	end

	return pos
end

function HouseItem:getChildStartIndex()
	return 5
end

function HouseItem:playSetEffect()
	local info = self:getInfo()
	local texiao = HouseFurnitureTable:effectType(info.item_id)

	if not texiao or texiao == "" then
		return
	end

	if self.furnitureSet_ then
		return
	end

	local pos = self:getCenterPos()
	local selfPos = self.go.transform.localPosition
	local x = pos.x - selfPos.x
	local y = pos.y - selfPos.y
	self.furnitureSet_ = xyd.Spine.new(self.effectNode)

	self.furnitureSet_:setInfo("furniture_set", function ()
		self.furnitureSet_:SetLocalPosition(x, y, 0)
		self.furnitureSet_:SetLocalScale(1, 1, 1)
		self.furnitureSet_:play(texiao, 1, 1, function ()
			self.furnitureSet_:destroy()

			self.furnitureSet_ = nil
		end)
	end)
	self:showEffect()
end

function HouseItem:showEffect(flag)
	if flag == nil then
		flag = true
	end

	local info = self:getInfo()

	if info.special_type == xyd.HouseItemSpecialType.FLOOR_OR_WALL_PAPER then
		return
	end

	if self.showEffect_ then
		self.showEffect_:SetActive(false)
	end

	if flag == false then
		self:resumeBeforeEffect()

		return
	end

	if self.curActionType == xyd.HouseItemActionType.NONE then
		self:showIdleEffect()
	elseif self.curActionType == xyd.HouseItemActionType.INTERACT then
		self:showInteractEffect()
	end
end

function HouseItem:resumeBeforeEffect()
	self.img0.alpha = 1

	if self.showEffect_ then
		self.showEffect_:destroy()

		self.showEffect_ = nil
	end
end

function HouseItem:showIdleEffect()
	local info = self:getInfo()
	local texiaoID = HouseFurnitureTable:furnitureEffectIdle(info.item_id)

	if not texiaoID or texiaoID <= 0 then
		return
	end

	self:initEffect(texiaoID)
end

function HouseItem:showInteractEffect()
	local info = self:getInfo()
	local texiaoID = HouseFurnitureTable:furnitureEffectInteract(info.item_id)

	if not texiaoID or texiaoID <= 0 then
		return
	end

	self:initEffect(texiaoID)
end

function HouseItem:initEffect(texiaoID)
	local effectName = HouseFurnitureEffectTable:effectName(texiaoID)
	self.curTexiaoID = texiaoID

	if self.showEffect_ and self.showEffect_:getName() == effectName then
		self.showEffect_:SetActive(true)
		self:playEffect(texiaoID)

		return
	end

	if self.showEffect_ then
		self.showEffect_:destroy()

		self.showEffect_ = nil
	end

	local effect = xyd.Spine.new(self.effectNode)
	self.showEffect_ = effect

	effect:setInfo(effectName, function ()
		self:playEffect(texiaoID)
	end)
end

function HouseItem:updateEffectPos()
	local effect = self.showEffect_

	if not effect then
		return
	end

	local texiaoID = self.curTexiaoID
	local texiaoXy = HouseFurnitureEffectTable:pos(texiaoID)
	local isFlip = self:getInfo().is_flip
	local offX = texiaoXy[1] or 0
	local offY = texiaoXy[2] or 0

	if isFlip == 1 then
		offX = -offX
	end

	local pos = self:getCenterPos()
	local selfPos = self:getGameObject().transform.localPosition
	local x_ = pos.x - selfPos.x + offX
	local y_ = pos.y - selfPos.y - offY

	effect:SetLocalPosition(x_, y_, 0)

	local scale_ = HouseFurnitureEffectTable:scale(texiaoID)
	local info = self:getInfo()
	local scaleX = info.is_flip == 0 and scale_ or -scale_

	effect:SetLocalScale(scaleX, scale_, 1)
end

function HouseItem:playEffect(texiaoID)
	local effectName = HouseFurnitureEffectTable:effectName(texiaoID)
	local action = HouseFurnitureEffectTable:action(texiaoID)
	local effect = self.showEffect_
	local count = HouseFurnitureEffectTable:count(texiaoID)
	local listenEventName = HouseFurnitureEffectTable:event(texiaoID)
	local slotName = HouseFurnitureEffectTable:slotName(texiaoID)
	local isClip = HouseFurnitureEffectTable:isClip(texiaoID)
	local heroPos = HouseFurnitureEffectTable:heroPos(texiaoID)
	local isHideImg = HouseFurnitureEffectTable:isHideImg(texiaoID)
	local nextAction = HouseFurnitureEffectTable:nextAction(texiaoID)
	self.isClip_ = isClip

	if isHideImg then
		self.img0.alpha = 0.01
	else
		self.img0.alpha = 1
	end

	local completeCallback = nil

	if count > 0 and nextAction == 0 then
		function completeCallback()
			self:unInteractHero()
		end
	else
		function completeCallback()
			self:playEffect(nextAction)
		end
	end

	local listenEvent = nil

	if listenEventName ~= "" then
		function listenEvent()
			self:playEffectEvent(texiaoID, listenEventName)
		end
	end

	effect:setPlayNeedStop(true)
	effect:playWithEvent(action, count, 1, {
		Complete = completeCallback,
		[listenEventName] = listenEvent
	})
	effect:startAtFrame(0)
	effect:setSeparatorDuration(5)

	local interactHeros = self:getInfo().interactHeros

	if slotName and slotName ~= "" and #interactHeros > 0 then
		local item = interactHeros[1]

		if item then
			effect:followSlot(slotName, self.heroNode, {
				isClearEvent = true,
				rotation = true,
				colorCallback = function (color)
					item:changeColor(color)
					self:showEffectClip(texiaoID)
				end,
				activeCallback = function (isActive)
					item:SetActive(isActive)
				end
			})
			effect:followBone(slotName, self.heroNode, {
				rotation = false
			})

			local itemPos = item:getGameObject().transform.localPosition

			item:SetLocalPosition(itemPos.x + heroPos[1], itemPos.y - heroPos[2], 0)
			item:changeModelRender(self.effectNode, 1)
			self:showEffectClip(texiaoID)

			self.curEffectHero_ = item
		end
	end

	self:updateEffectPos()
end

function HouseItem:initEffectMask(id)
end

function HouseItem:showEffectClip(texiaoID)
	local interactHeros = self:getInfo().interactHeros
	local heroItem = interactHeros[1]

	if not heroItem then
		return
	end

	if self.isClip_ then
		local clipPos = HouseFurnitureEffectTable:clipPos(texiaoID)
		local radius = 50
		local center = {
			x = 0,
			y = -clipPos[2]
		}

		heroItem:setClip(self.heroNode.transform, center, radius)
	else
		heroItem:clearcClip()
	end
end

function HouseItem:playEffectEvent(texiaoID, frameLabel)
	local isClip = HouseFurnitureEffectTable:eventIsClip(texiaoID)
	self.isClip_ = isClip

	self:showEffectClip(isClip, texiaoID)

	local eventHeroAction = HouseFurnitureEffectTable:eventHeroAction(texiaoID)
	local heroPos = HouseFurnitureEffectTable:eventHeroPos(texiaoID)

	if eventHeroAction and self.curEffectHero_ then
		local item = self.curEffectHero_

		if item then
			item:playActionByName(eventHeroAction, 0, true)

			local itemPos = item:getGameObject().transform.localPosition

			item:SetLocalPosition(itemPos.x + heroPos[1], itemPos.y - heroPos[2], 0)
		end
	end
end

function HouseItem:clearEffectAction()
	if not self.showEffect_ then
		return
	end

	self.showEffect_:hideFollowBone(self.heroNode)
	self.showEffect_:hideFollowSlot(self.heroNode)
end

function HouseItem:unInteractHero()
	if not self.curEffectHero_ then
		return
	end

	self:clearEffectAction()

	local item = self.curEffectHero_

	if item then
		local freeGrid = self.houseMap_:getFreeGridByItem(item)

		if freeGrid.flag then
			item:resumeFree({
				x = freeGrid.coord_x,
				y = freeGrid.coord_y
			})
		end
	end
end

function HouseItem:initSpecialEffect(pos, gridType)
	local info = self:getInfo()
	local texiaoID = HouseFurnitureTable:furnitureEffectIdle(info.item_id)

	if not texiaoID or texiaoID <= 0 then
		return
	end

	local effectName = HouseFurnitureEffectTable:effectName(texiaoID)
	local action = HouseFurnitureEffectTable:action(texiaoID)
	local texiaoXy = HouseFurnitureEffectTable:pos(texiaoID)
	local count = HouseFurnitureEffectTable:count(texiaoID)
	local effect = xyd.Spine.new(self.groupSpecialEffect_)

	effect:setInfo(effectName, function ()
		effect:play(action, count)
	end)

	local direct = 1

	if gridType == xyd.HouseGridType.RIGHT_WALL then
		direct = -1
	end

	local x_ = pos.x + (texiaoXy[1] or 0) * direct
	local y_ = pos.y - (texiaoXy[2] or 0)

	effect:SetLocalPosition(x_, y_, 0)
	effect:SetLocalScale(direct, 1, 1)
end

function HouseItem:addHeroNode(item)
	self.curActionType = xyd.HouseItemActionType.INTERACT

	item:changeParent(self.heroNode)
	self:updateHerosZOrder()
	self:setImg()
end

function HouseItem:updateHerosZOrder()
	local count = 0
	local info = self:getInfo()
	local freePoint = info.free_point
	local depth = self.heroNode:GetComponent(typeof(UIWidget)).depth
	local maxDepth = depth

	for i = #freePoint, 1, -1 do
		if freePoint[i] and type(freePoint[i]) ~= "number" then
			local curMaxDepth = freePoint[i]:updateDepthObj(depth + i, self.effectNode, 24 - i * 12)
			count = count + 1

			if maxDepth < curMaxDepth then
				maxDepth = curMaxDepth
			end
		end
	end

	self:updateDepthByHero(maxDepth)
end

function HouseItem:updateDepthByHero(maxDepth)
	for i = 1, #self.heroEffectdepthObjs_ do
		self.heroEffectdepthObjs_[i].depth = maxDepth + i
	end
end

function HouseItem:removeHeroNode(heroItem)
	local info = self:getInfo()

	info:removeInteractItem(heroItem)

	heroItem:getGameObject().transform.parent = nil

	heroItem:changeModelRender()
	self:setImg()

	if info:isInteract() == false then
		self.curActionType = xyd.HouseItemActionType.NONE
	end

	self:clearEffectAction()
	self:showEffect()
end

function HouseItem:checkCanInteract()
	local flag = true

	if self.showEffect_ and self.showEffect_:isValid() == false then
		flag = false
	end

	return flag
end

function HouseItem:checkTimeAction()
	local texiaoID = HouseFurnitureTable:furnitureEffectIdle(self.info_.item_id)

	if texiaoID and texiaoID > 0 then
		local triggerRate = HouseFurnitureEffectTable:triggerRate(texiaoID)

		if #triggerRate > 0 then
			local gapTime = HouseFurnitureEffectTable:gapTime(texiaoID)

			return gapTime
		end
	end

	return -1
end

function HouseItem:playTimeAction()
	if not self:checkCanInteract() then
		return
	end

	local texiaoID = HouseFurnitureTable:furnitureEffectIdle(self.info_.item_id)
	local triggerRate = HouseFurnitureEffectTable:triggerRate(texiaoID)

	if #triggerRate == 0 then
		return
	end

	local ids = HouseFurnitureEffectTable:triggerIDs(texiaoID)
	local index = xyd.getRandomByWeights(triggerRate)
	local id = ids[index]

	self:initEffect(id)

	return true
end

function HouseItem:setSpineLevel()
end

return HouseItem
