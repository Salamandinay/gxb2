local HouseGrid = class("HouseGrid")

function HouseGrid:ctor()
	self.parentNodes = {}
	self.mapRow = 24
	self.mapCol = 24
	self.mapSize = 50
	self.wallHeight = 570
	self.wallGridHeight = 430
	self.wallOffsetY = 25
	self.wallDecorationOffY = -15
end

function HouseGrid:get()
	if HouseGrid.INSTANCE == nil then
		HouseGrid.INSTANCE = HouseGrid.new()
	end

	return HouseGrid.INSTANCE
end

function HouseGrid:init()
	local floor = xyd.HouseMap.get():getPlaceNode(xyd.HouseItemPlaceFloor.FLOOR_GRID)
	local leftWall = xyd.HouseMap.get():getPlaceNode(xyd.HouseItemPlaceFloor.LEFT_WALL_GRID)
	local rightWall = xyd.HouseMap.get():getPlaceNode(xyd.HouseItemPlaceFloor.RIGHT_WALL_GRID)
	self.parentNodes = {
		floor,
		leftWall,
		rightWall
	}
	self.netRect_ = {}
end

function HouseGrid:initNetRect(gridType)
	if not self.netRect_[gridType] then
		self.netRect_[gridType] = true

		self:createNetRect(gridType, self:getNode(gridType))
	end
end

function HouseGrid:clear()
end

function HouseGrid:hideGridLayout(info)
	for _, gridType in ipairs(info.grid_type) do
		local node = self:getNode(gridType)

		node:SetActive(false)
	end
end

function HouseGrid:showGridLayout(info)
	for _, gridType in ipairs(info.grid_type) do
		local node = self:getNode(gridType)

		node:SetActive(true)
		self:initNetRect(gridType)
	end
end

function HouseGrid:getNode(type_)
	return self.parentNodes[type_ + 1]
end

function HouseGrid:getMaxSizeByGridType(gridType, power)
	if power == nil then
		power = 1
	end

	local c_length = 0
	local c_with = 0

	if gridType == xyd.HouseGridType.FLOOR then
		c_length = self.mapCol / power
		c_with = self.mapRow / power
	elseif gridType == xyd.HouseGridType.LEFT_WALL then
		c_length = self.mapRow / power
		c_with = 1
	elseif gridType == xyd.HouseGridType.RIGHT_WALL then
		c_length = self.mapCol / power
		c_with = 1
	end

	return {
		c_length = c_length,
		c_with = c_with
	}
end

function HouseGrid:createNetRect(gridType, parentNode)
	local size = self:getMaxSizeByGridType(gridType)
	local c_length = size.c_length
	local c_with = size.c_with
	local icon = self:getColorIcon(gridType, xyd.HouseGridColorType.WHITE)
	local anchor = self:getIconAnchor(gridType)
	local depth = parentNode:GetComponent(typeof(UIWidget)).depth

	for coordX = 0, c_length - 1 do
		for coordY = 0, c_with - 1 do
			local item = self:getImgItem(icon, anchor, parentNode)
			local itemWidget = item:GetComponent(typeof(UIWidget))
			itemWidget.depth = depth

			if anchor.w > 0 then
				itemWidget.width = anchor.w
			end

			if anchor.h > 0 then
				itemWidget.height = anchor.h
			end

			if anchor.type then
				item:GetComponent(typeof(UISprite)).type = anchor.type
			end

			if anchor.pivot then
				itemWidget.pivot = anchor.pivot
			end

			local pos = self:getPiexlPosition(coordX, coordY, gridType, 1, true)

			item:SetLocalPosition(pos.x, pos.y, 0)
			item:SetLocalScale(anchor.scaleX, 1, 1)
		end
	end
end

function HouseGrid:getImgItem(iconSource, anchor, parentNode)
	local img = NGUITools.AddChild(parentNode, "img_icon")
	local sp = img:AddComponent(typeof(UISprite))

	xyd.setUISprite(sp, xyd.Atlas.HOUSE, iconSource)
	sp:MakePixelPerfect()

	return img
end

function HouseGrid:getPiexlPosition(coordX, coordY, gridType, power, isWall)
	if power == nil then
		power = 1
	end

	if isWall == nil then
		isWall = false
	end

	local pos = {
		x = 0,
		y = 0
	}
	local size = self.mapSize * power
	local wallOffsetY = self.wallOffsetY * power

	if not isWall then
		wallOffsetY = wallOffsetY + self.wallDecorationOffY
	end

	if gridType == xyd.HouseGridType.FLOOR then
		pos.x = (coordX - coordY) * size
		pos.y = (coordY + coordX) * size / 2
	elseif gridType == xyd.HouseGridType.LEFT_WALL then
		pos.x = -coordX * size
		pos.y = -coordY * self.wallGridHeight + coordX / 2 * size + wallOffsetY
	elseif gridType == xyd.HouseGridType.RIGHT_WALL then
		pos.x = coordX * size
		pos.y = -coordY * self.wallGridHeight + coordX / 2 * size + wallOffsetY
	end

	pos.y = pos.y * -1

	return pos
end

function HouseGrid:getColorItem(coordY, coordX, gridType, color, parentNode)
	local icon = self:getColorIcon(gridType, color)
	local anchor = self:getIconAnchor(gridType)
	local item = self:getImgItem(icon, anchor, parentNode)
	local pos = self:getPiexlPosition(coordX, coordY, gridType)
	local itemWidget = item:GetComponent(typeof(UIWidget))
	local depth = parentNode:GetComponent(typeof(UIWidget)).depth
	itemWidget.depth = depth

	if anchor.w > 0 then
		itemWidget.width = anchor.w
	end

	if anchor.h > 0 then
		itemWidget.height = anchor.h
	end

	if anchor.type then
		item:GetComponent(typeof(UISprite)).type = anchor.type
	end

	if anchor.pivot then
		itemWidget.pivot = anchor.pivot
	end

	local pos = self:getPiexlPosition(coordX, coordY, gridType, 1, true)

	item:SetLocalPosition(pos.x, pos.y, 0)
	item:SetLocalScale(anchor.scaleX, 1, 1)

	return item
end

function HouseGrid:getColorIcon(gridType, color)
	local icon = ""
	local suffix = tostring(color)

	if gridType == xyd.HouseGridType.FLOOR then
		icon = "house_floor_unit" .. suffix
	elseif gridType == xyd.HouseGridType.LEFT_WALL then
		icon = "house_wall_unit_left" .. suffix
	elseif gridType == xyd.HouseGridType.RIGHT_WALL then
		icon = "house_wall_unit_left" .. suffix
	end

	return icon
end

function HouseGrid:getIconAnchor(gridType, power, isPaper)
	if power == nil then
		power = 1
	end

	if isPaper == nil then
		isPaper = false
	end

	local anchor = {
		h = 0,
		y = 0,
		w = 0,
		scaleX = 1,
		x = 0
	}
	local height = self.wallGridHeight

	if isPaper then
		height = self.wallHeight
	end

	if gridType == xyd.HouseGridType.FLOOR then
		anchor.pivot = UIWidget.Pivot.Top
	elseif gridType == xyd.HouseGridType.LEFT_WALL then
		anchor.h = height
		anchor.pivot = UIWidget.Pivot.BottomRight
		anchor.type = UIBasicSprite.Type.Sliced
	elseif gridType == xyd.HouseGridType.RIGHT_WALL then
		anchor.scaleX = -1
		anchor.h = height
		anchor.pivot = UIWidget.Pivot.BottomRight
		anchor.type = UIBasicSprite.Type.Sliced
	end

	return anchor
end

function HouseGrid:getTrueGridPos(pos, gridType)
	local coordX = 0
	local coordY = 0

	if gridType == xyd.HouseGridType.FLOOR then
		coordX = (pos.x - 2 * pos.y) / (self.mapSize * 2)
		coordY = -(2 * pos.y + pos.x) / (self.mapSize * 2)
	elseif gridType == xyd.HouseGridType.LEFT_WALL then
		coordX = -pos.x / self.mapSize
		coordY = 0
	elseif gridType == xyd.HouseGridType.RIGHT_WALL then
		coordX = pos.x / self.mapSize
		coordY = 0
	end

	return {
		coord_x = coordX,
		coord_y = coordY
	}
end

function HouseGrid:changeStagePosToGrid(stageX, stageY, info, offY)
	local curGridType = info.cur_grid_type
	local gridPos = {
		coord_y = 0,
		grid_type_index = -1,
		coord_x = 0
	}
	offY = offY or 0

	for i = 1, #info.grid_type do
		local tmpGridType = info.grid_type[i]
		local size = self:getMaxSizeByGridType(tmpGridType)
		local maxX = size.c_length - info:length()
		local maxY = size.c_with - info:width()
		local node = self:getNode(tmpGridType)
		local pos = node.transform:InverseTransformPoint(Vector3(stageX, stageY, 0))
		pos.y = pos.y + offY
		local tmpGridPos = self:getTrueGridPos(pos, tmpGridType)

		if tmpGridPos.coord_x >= 0 and tmpGridPos.coord_y >= 0 or curGridType == xyd.HouseGridType.FLOOR then
			if curGridType ~= tmpGridType then
				gridPos.grid_type_index = i
			end

			gridPos.coord_x = Mathf.Clamp(math.floor(tmpGridPos.coord_x - info:length() / 2 + 0.5), 0, maxX) + 0
			gridPos.coord_y = Mathf.Clamp(math.floor(tmpGridPos.coord_y - info:width() / 2 + 0.5), 0, maxY) + 0

			break
		end
	end

	return gridPos
end

function HouseGrid:getStagePos(x_, y_, info)
	local node = self:getNode(info.cur_grid_type)
	local pos = node:localToGlobal(x_, y_)

	return pos
end

function HouseGrid:updateOneGridNum(row, col, val, info)
end

function HouseGrid:createGridNumLabel(row, col, info)
	local pos = self:getPiexlPosition(col, row, info.cur_grid_type)
	local label3 = eui.Label.new()
	label3.x = pos.x - 10
	label3.size = 20
	label3.y = pos.y + 10
	label3.textColor = 16711680
	local node = self:getNode(info.cur_grid_type)

	node:addChild(label3)

	label3.visible = false
	label3.text = ""
	label3.name = "grid_val"

	return label3
end

function HouseGrid:getOffsetY(gridType)
	if gridType == xyd.HouseGridType.FLOOR then
		return 0
	end

	return self.wallOffsetY
end

return HouseGrid
