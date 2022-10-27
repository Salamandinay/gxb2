local ArtifactDecomposeWindow = class("ArtifactDecomposeWindow", import(".BaseWindow"))
local ItemIcon = import("app.components.ItemIcon")
local ItemCard = class("ItemCard")

function ItemCard:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.itemIcon = ItemIcon.new(go)

	self.itemIcon:setDragScrollView(parent.scrollView)
	self.itemIcon:setScale(0.9)
end

function ItemCard:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self.itemIcon:setInfo(info)
end

function ItemCard:getGameObject()
	return self.go
end

function ArtifactDecomposeWindow:ctor(name, params)
	ArtifactDecomposeWindow.super.ctor(self, name, params)
end

function ArtifactDecomposeWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ArtifactDecomposeWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	local mid1 = groupAction:NodeByName("mid1").gameObject
	self.labelDesc = mid1:ComponentByName("labelDesc", typeof(UILabel))
	self.item = mid1:NodeByName("item").gameObject
	self.scroller_ = mid1:ComponentByName("scroller_", typeof(UIScrollView))
	self.groupEquip = self.scroller_:ComponentByName("groupEquip", typeof(UIGrid))
	local mid2 = groupAction:NodeByName("mid2").gameObject
	self.noEquip = mid2:NodeByName("noEquip").gameObject
	self.noEquipLabel = self.noEquip:ComponentByName("noEquipLabel", typeof(UILabel))
	self.scrollView = mid2:ComponentByName("scroller", typeof(UIScrollView))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	local wrapContent = self.scrollView:ComponentByName("equipContainer", typeof(MultiRowWrapContent))
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView, wrapContent, itemContainer, ItemCard, self)
	self.btnDecompose = groupAction:NodeByName("btnDecompose").gameObject
	self.btnDecomposeLabel = self.btnDecompose:ComponentByName("button_label", typeof(UILabel))
	self.countLabel = groupAction:ComponentByName("resGroup/countLabel", typeof(UILabel))
	local groupCircles = groupAction:NodeByName("groupCircles").gameObject
	self.btnQualityChosen = groupCircles:NodeByName("btnQualityChosen").gameObject

	for i = 1, 6 do
		self["btnCircle" .. i] = groupCircles:NodeByName("btnCircle" .. i).gameObject
	end
end

function ArtifactDecomposeWindow:layout()
	self.labelTitle.text = __("ACTIVITY_ANTIQUE_LEVELUP_TEXT09")
	self.labelDesc.text = __("ACTIVITY_ANTIQUE_LEVELUP_TEXT10")
	self.noEquipLabel.text = __("NO_ARTIFACT")
	self.btnDecomposeLabel.text = __("ACTIVITY_ANTIQUE_LEVELUP_TEXT13")
	self.decomNum = 0

	self:getDecomLimit()

	self.countLabel.text = self.decomNum
	self.selectList = {}

	self.item:SetActive(false)

	for i = 1, 5 do
		local item = NGUITools.AddChild(self.groupEquip.gameObject, self.item)
		local equipIcon = item:NodeByName("equipIcon").gameObject

		xyd.setDragScrollView(equipIcon, self.scroller_)

		local icon = ItemIcon.new(equipIcon)

		icon:SetActive(false)

		self.selectList[i] = {
			itemID = 0,
			num = 0,
			qlt = 0,
			itemRoot = item,
			itemIcon = icon
		}

		UIEventListener.Get(equipIcon).onClick = function ()
			self:cancelSelect(i)
		end
	end

	self.selectQlt = 0

	self.btnQualityChosen:SetActive(false)

	self.artifacts = {}

	self:getArtifacts()
	self.multiWrap_:setInfos(self.artifacts[self.selectQlt], {})
end

function ArtifactDecomposeWindow:cancelSelect(index)
	if self.selectList[index].itemID == 0 then
		return
	end

	for _, item in ipairs(self.artifacts[0]) do
		if item.itemID == self.selectList[index].itemID then
			item.num = item.num + self.selectList[index].num

			break
		end
	end

	if self.selectQlt == 0 or self.selectQlt == self.selectList[index].qlt then
		self.multiWrap_:setInfos(self.artifacts[self.selectQlt], {
			keepPosition = true
		})
	end

	self:updateDecomNum(self.selectList[index].itemID, self.selectList[index].num, false)
	self.selectList[index].itemIcon:SetActive(false)

	self.selectList[index].itemID = 0
	self.selectList[index].num = 0
	self.selectList[index].qlt = 0

	if #self.selectList > 5 then
		local infos = {}

		for _, itemInfo in ipairs(self.selectList) do
			if itemInfo.itemID ~= 0 then
				table.insert(infos, {
					itemID = itemInfo.itemID,
					num = itemInfo.num,
					qlt = itemInfo.qlt
				})
			end
		end

		local listNums = #self.selectList

		NGUITools.Destroy(self.selectList[listNums].itemRoot)

		self.selectList[listNums] = nil

		for i = 1, listNums - 1 do
			self.selectList[i].itemID = infos[i].itemID
			self.selectList[i].num = infos[i].num
			self.selectList[i].qlt = infos[i].qlt

			self.selectList[i].itemIcon:setInfo({
				noClick = true,
				itemID = infos[i].itemID,
				num = infos[i].num
			})
			self.selectList[i].itemIcon:SetActive(true)
		end

		self.groupEquip:Reposition()
	end
end

function ArtifactDecomposeWindow:updateDecomNum(itemID, num, isAdd)
	local exp = xyd.tables.equipTable:getArtifactExp(itemID)

	if isAdd then
		self.decomNum = self.decomNum + exp * num / 10
	else
		self.decomNum = self.decomNum - exp * num / 10
	end

	self.countLabel.text = self.decomNum
end

function ArtifactDecomposeWindow:getDecomLimit()
	local data = xyd.split(xyd.tables.miscTable:getVal("activity_equip_decompose"), "|", true)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_ANTIQUE)
	self.decomLimit = data[2] - activityData.detail_.trans_num
end

function ArtifactDecomposeWindow:getArtifacts()
	for i = 0, 6 do
		self.artifacts[i] = {}
	end

	local datas = xyd.models.backpack:getItems()

	for i = 1, #datas do
		local itemID = datas[i].item_id
		local itemNum = tonumber(datas[i].item_num)

		if xyd.tables.itemTable:getType(itemID) == xyd.ItemType.ARTIFACT then
			local qlt = xyd.tables.equipTable:getQuality(itemID)

			if qlt < 7 then
				local item = nil
				item = {
					itemID = itemID,
					num = itemNum,
					qlt = qlt,
					callback = function ()
						self:clickIcon(item)
					end
				}

				table.insert(self.artifacts[0], item)
				table.insert(self.artifacts[qlt], item)
			end
		end
	end

	for i = 0, 6 do
		local list = self.artifacts[i]

		table.sort(list, function (a, b)
			local aLev = xyd.tables.equipTable:getItemLev(a.itemID)
			local bLev = xyd.tables.equipTable:getItemLev(b.itemID)

			return aLev == bLev and a.itemID < b.itemID or aLev < bLev
		end)
	end
end

function ArtifactDecomposeWindow:clickIcon(item)
	local params = {
		top = 550,
		itemID = item.itemID,
		itemNum = item.num,
		callback = function (num)
			if num <= item.num then
				self:addToCost(item.itemID, num)
				self:updateDecomNum(item.itemID, num, true)

				item.num = item.num - num

				self.multiWrap_:setInfos(self.artifacts[self.selectQlt], {
					keepPosition = true
				})
			end
		end
	}

	xyd.WindowManager.get():openWindow("artifact_offer_window", params)
end

function ArtifactDecomposeWindow:addToCost(itemID, num)
	local added = false

	for _, item in ipairs(self.selectList) do
		if item.itemID == itemID then
			item.num = item.num + num

			item.itemIcon:setNum(item.num, itemID)

			added = true

			break
		end
	end

	if added then
		return
	end

	for i = 1, 5 do
		if self.selectList[i].itemID == 0 then
			self.selectList[i].itemID = itemID
			self.selectList[i].num = num
			self.selectList[i].qlt = xyd.tables.equipTable:getQuality(itemID)

			self.selectList[i].itemIcon:setInfo({
				noClick = true,
				itemID = itemID,
				num = num
			})
			self.selectList[i].itemIcon:SetActive(true)

			added = true

			break
		end
	end

	if added then
		return
	end

	local item = NGUITools.AddChild(self.groupEquip.gameObject, self.item)
	local equipIcon = item:NodeByName("equipIcon").gameObject

	xyd.setDragScrollView(equipIcon, self.scroller_)

	local icon = xyd.getItemIcon({
		noClick = true,
		uiRoot = equipIcon,
		itemID = itemID,
		num = num
	})
	local itemInfo = {
		itemRoot = item,
		itemIcon = icon,
		itemID = itemID,
		num = num,
		qlt = xyd.tables.equipTable:getQuality(itemID)
	}
	local index = #self.selectList + 1
	self.selectList[index] = itemInfo

	UIEventListener.Get(equipIcon).onClick = function ()
		self:cancelSelect(index)
	end

	self.groupEquip:Reposition()
end

function ArtifactDecomposeWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.RECYCLE_ARTIFACT, handler(self, self.onDecompose))

	UIEventListener.Get(self.closeBtn).onClick = handler(self, function ()
		self:close()
	end)

	for i = 1, 6 do
		UIEventListener.Get(self["btnCircle" .. i]).onClick = function ()
			if self.selectQlt == i then
				self.selectQlt = 0

				self.btnQualityChosen:SetActive(false)
			else
				self.selectQlt = i

				self.btnQualityChosen:X(self["btnCircle" .. i].transform.localPosition.x)
				self.btnQualityChosen:SetActive(true)
			end

			self.multiWrap_:setInfos(self.artifacts[self.selectQlt], {})
		end
	end

	UIEventListener.Get(self.btnDecompose).onClick = handler(self, self.reqDecompose)
end

function ArtifactDecomposeWindow:reqDecompose()
	local infos = {}

	for _, item in ipairs(self.selectList) do
		if item.itemID ~= 0 then
			table.insert(infos, {
				item_id = item.itemID,
				item_num = item.num
			})
		end
	end

	if #infos > 0 then
		local tipsStr = __("ACTIVITY_ANTIQUE_LEVELUP_TEXT12")

		xyd.alert(xyd.AlertType.YES_NO, tipsStr, function (yes)
			if yes then
				local msg = messages_pb.recycle_artifact_req()
				msg.activity_id = xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_ANTIQUE

				for _, item in ipairs(infos) do
					local item_info = messages_pb:items_info()
					item_info.item_id = item.item_id
					item_info.item_num = item.item_num

					table.insert(msg.items, item_info)
				end

				xyd.Backend.get():request(xyd.mid.RECYCLE_ARTIFACT, msg)
			end
		end)
	else
		xyd.showToast(__("ACTIVITY_ANTIQUE_LEVELUP_TEXT11"))
	end
end

function ArtifactDecomposeWindow:onDecompose(event)
	local trans_num = event.data.trans_num
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_ANTIQUE)
	activityData.detail_.trans_num = trans_num
	local data = xyd.split(xyd.tables.miscTable:getVal("activity_equip_decompose"), "|", true)
	self.decomLimit = data[2] - trans_num
	self.decomNum = 0
	self.countLabel.text = self.decomNum

	for i = 1, #self.selectList do
		local item = self.selectList[i]

		item.itemIcon:SetActive(false)

		item.itemID = 0
		item.num = 0
		item.qlt = 0

		if i > 5 then
			NGUITools.Destroy(item.itemRoot)

			self.selectList[i] = nil
		end
	end

	self.groupEquip:Reposition()
	self:getArtifacts()
	self.multiWrap_:setInfos(self.artifacts[self.selectQlt], {})
	xyd.alertItems(event.data.items)
end

return ArtifactDecomposeWindow
