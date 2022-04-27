local BaseWindow = import(".BaseWindow")
local ArtifactListWindow = class("ArtifactListWindow", BaseWindow)
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ItemIcon = import("app.components.ItemIcon")
local ArtifactItem = class("ArtifactItem")
local ItemTable = xyd.tables.itemTable
local EquipTable = xyd.tables.equipTable

function ArtifactListWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.list_ = {}
	self.identi_to_id = {}
	self.list_by_type_ = {}
	self.showQuality = 0
end

function ArtifactListWindow:initWindow()
	BaseWindow.initWindow(self)
	self:initData()
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function ArtifactListWindow:initData()
	self.list_ = ItemTable:getItemListByType(xyd.ItemType.ARTIFACT)
	local tempList = {}
	self.list_by_type_[0] = {}

	for i = 1, #self.list_ do
		local key = ItemTable:getIcon(self.list_[i])

		if not self.identi_to_id[key] then
			self.identi_to_id[key] = self.list_[i]
		else
			local cur_star = EquipTable:getStar(self.identi_to_id[key])
			local tar_star = EquipTable:getStar(self.list_[i])

			if cur_star < tar_star then
				self.identi_to_id[key] = self.list_[i]
			end
		end
	end

	for key, itemID in pairs(self.identi_to_id) do
		table.insert(tempList, {
			key = key,
			itemID = itemID
		})
	end

	table.sort(tempList, function (a, b)
		local qA = ItemTable:getQuality(a.itemID)
		local qB = ItemTable:getQuality(b.itemID)

		if qA ~= qB then
			return qA < qB
		end

		return a.itemID < b.itemID
	end)

	for _, data in ipairs(tempList) do
		local id = data.itemID
		local qlty = ItemTable:getQuality(id)
		local has = xyd.models.backpack:getItemNumByID(id) > 0

		if not self.list_by_type_[qlty] then
			self.list_by_type_[qlty] = {}
		end

		table.insert(self.list_by_type_[qlty], {
			itemID = id,
			has = has
		})
		table.insert(self.list_by_type_[0], {
			itemID = id,
			has = has
		})
	end

	self.list_ = nil
	self.identi_to_id = nil
end

function ArtifactListWindow:getUIComponent()
	local go = self.window_
	self.closeBtn = go:NodeByName("main/closeBtn").gameObject
	self.titleLabel = go:ComponentByName("main/titleLabel", typeof(UILabel))
	self.btnCircle1 = go:NodeByName("main/btnCircles/btnCircle1").gameObject
	self.btnCircle2 = go:NodeByName("main/btnCircles/btnCircle2").gameObject
	self.btnCircle3 = go:NodeByName("main/btnCircles/btnCircle3").gameObject
	self.btnCircle4 = go:NodeByName("main/btnCircles/btnCircle4").gameObject
	self.btnCircle5 = go:NodeByName("main/btnCircles/btnCircle5").gameObject
	self.btnCircle6 = go:NodeByName("main/btnCircles/btnCircle6").gameObject
	self.btnQualityChosen = go:NodeByName("main/btnCircles/btnQualityChosen").gameObject
	self.scrollView = go:ComponentByName("main/scroll_view", typeof(UIScrollView))
	self.scrollPanel = go:ComponentByName("main/scroll_view", typeof(UIPanel))
	self.wrapContent = go:ComponentByName("main/scroll_view/wrap_content", typeof(MultiRowWrapContent))
	local itemCell = go:NodeByName("item").gameObject
	self.wrapContent_ = FixedMultiWrapContent.new(self.scrollView, self.wrapContent, itemCell, ArtifactItem, self)
end

function ArtifactListWindow:initUIComponent()
	self.titleLabel.text = __("ARTIFACT_LIST")

	self.btnQualityChosen:SetActive(false)

	local infos = self.list_by_type_[self.showQuality]

	self.wrapContent_:setInfos(infos, {})
end

function ArtifactListWindow:registerEvent()
	for k = 1, 6 do
		UIEventListener.Get(self["btnCircle" .. k]).onClick = function ()
			self:onQualityBtn(k)
		end
	end

	self:setCloseBtn(self.closeBtn)
end

function ArtifactListWindow:onQualityBtn(i)
	if self.showQuality == 0 then
		self.btnQualityChosen:SetActive(true)

		local pos = self["btnCircle" .. i].transform.localPosition

		self.btnQualityChosen:SetLocalPosition(pos.x, pos.y, pos.z)

		self.showQuality = i
	elseif self.showQuality ~= i then
		local pos = self["btnCircle" .. i].transform.localPosition

		self.btnQualityChosen:SetLocalPosition(pos.x, pos.y, pos.z)

		self.showQuality = i
	elseif self.showQuality == i then
		self.btnQualityChosen:SetActive(false)

		self.showQuality = 0
	end

	local infos = self.list_by_type_[self.showQuality]

	self.wrapContent_:setInfos(infos, {})
end

function ArtifactItem:ctor(go, artifactListWindow)
	self.go = go
	self.itemIcon = ItemIcon.new(go)

	self.itemIcon:setDragScrollView(artifactListWindow.scrollView)
end

function ArtifactItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.data = info
	self.itemIndex = index

	self.itemIcon:setInfo(self.data)

	self.name = "artifact_item_" .. self.itemIndex
end

function ArtifactItem:setOrder(order)
	self.order_ = order
end

function ArtifactItem:getOrder(order)
	return self.order_
end

function ArtifactItem:onClickIcon()
end

function ArtifactItem:getGameObject()
	return self.go
end

return ArtifactListWindow
