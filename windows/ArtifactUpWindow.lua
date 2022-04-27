local BaseWindow = import(".BaseWindow")
local ArtifactUpWindow = class("ArtifactUpWindow", BaseWindow)
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

function ArtifactUpWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.artifacts = {}
	self.cur_id = 0
	self.Effects = {}
	self.id_to_item = {}
	self.skinName = "ArtifactUpWindowSkin"
	self.artifacts = params.equips or {}
	self.itemID = params.itemID
	self.equipedPartner = params.equipedPartner

	self:sortEquips()

	self.groupEquipItems = {}
	self.progressBarValue = 0
	self.infos = {}
end

function ArtifactUpWindow:sortEquips()
	table.sort(self.artifacts, function (a, b)
		local aLev = xyd.tables.equipTable:getItemLev(a.itemID)
		local bLev = xyd.tables.equipTable:getItemLev(b.itemID)

		if aLev < bLev then
			return true
		elseif aLev == bLev and a.itemID < b.itemID then
			return true
		end

		return false
	end)
end

function ArtifactUpWindow:getUIComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("content").gameObject
	local top = content:NodeByName("top").gameObject
	self.backBtn = top:NodeByName("backBtn").gameObject
	self.labelTitle = top:ComponentByName("labelTitle", typeof(UILabel))
	local mid1 = content:NodeByName("mid1").gameObject
	local itemBeforeContainer = mid1:NodeByName("itemBefore").gameObject
	self.itemBefore = ItemIcon.new(itemBeforeContainer)
	self.itemBeforeEffect = itemBeforeContainer:NodeByName("itemBeforeEffect").gameObject
	local itemAfterContainer = mid1:NodeByName("itemAfter").gameObject
	self.itemAfter = ItemIcon.new(itemAfterContainer)
	self.itemAfterEffect = itemAfterContainer:NodeByName("itemAfterEffect").gameObject
	self.labelDesc = mid1:ComponentByName("labelDesc", typeof(UILabel))
	self.upProgressbar = mid1:ComponentByName("upProgressbar", typeof(UIProgressBar))
	self.progressBarEffectGroup = self.upProgressbar:NodeByName("progressBarEffectGroup").gameObject
	self.labelDisplay = mid1:ComponentByName("upProgressbar/labelDisplay", typeof(UILabel))
	self.scroller_ = mid1:ComponentByName("scroller_", typeof(UIScrollView))
	self.groupEquip = self.scroller_:NodeByName("groupEquip").gameObject
	self.groupEquipItem = self.scroller_:NodeByName("item").gameObject

	self.groupEquipItem:SetActive(false)

	self.groupEquipGrid = self.groupEquip:GetComponent(typeof(UIGrid))
	local mid2 = content:NodeByName("mid2").gameObject
	self.noEquip = mid2:NodeByName("noEquip").gameObject
	self.noEquipLable = self.noEquip:ComponentByName("noEquipLable", typeof(UILabel))
	self.scrollView = mid2:ComponentByName("scroller", typeof(UIScrollView))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	local wrapContent = self.scrollView:ComponentByName("equipContainer", typeof(MultiRowWrapContent))
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView, wrapContent, itemContainer, ItemCard, self)
	self.equipContainer = self.scrollView:NodeByName("equipContainer").gameObject
	self.btnUp = content:NodeByName("btnUp").gameObject
	self.btnUpLabel = self.btnUp:ComponentByName("button_label", typeof(UILabel))
	self.btnAutoAdd = content:NodeByName("btnAutoAdd").gameObject
	self.btnAutoAddLabel = self.btnAutoAdd:ComponentByName("button_label", typeof(UILabel))
end

function ArtifactUpWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initEquipContainer()
	self:initUpgradeItems()
	self:initProgressBar()
	self:initCostIcon()

	self.btnUpLabel.text = __("LEV_UP")
	self.btnAutoAddLabel.text = __("ARTIFACT_ONEBUTTON")

	xyd.setBgColorType(self.btnUp, xyd.ButtonBgColorType.blue_btn_65_65)

	self.labelDesc.text = __("ARTIFACT_UP_LABEL_1")
	self.labelTitle.text = __("ARTIFACT_UP_TITLE")

	self:registerEvent()
end

function ArtifactUpWindow:initEquipContainer()
	self.infos = {}

	for i = 1, #self.artifacts do
		local item = self.artifacts[i]

		if not item.partner_id then
			local params = {
				itemID = item.itemID,
				num = tonumber(item.itemNum),
				callback = function ()
					self:iconCallback(item.itemID)
				end
			}
			local qlt = xyd.tables.itemTable:getQuality(item.itemID)

			if qlt and qlt < 7 then
				table.insert(self.infos, params)
			end
		end
	end

	self.multiWrap_:setInfos(self.infos, {})
end

function ArtifactUpWindow:initUpgradeItems()
	self.itemBefore:setInfo({
		itemID = self.itemID
	})

	local next_itemID = xyd.tables.equipTable:getArtifactUpNext(self.itemID)

	self.itemAfter:setInfo({
		itemID = next_itemID
	})

	return next_itemID
end

function ArtifactUpWindow:initProgressBar()
	self.labelDisplay.text = "0/" .. xyd.tables.equipTable:getArtifactUpExp(self.itemID)
	self.upProgressbar.value = 0
	self.progressBarValue = 0

	if self.effectProgress then
		self.effectProgress:stop()
		self.effectProgress:SetActive(false)
	end
end

function ArtifactUpWindow:initCostIcon()
	for i = 1, 5 do
		local item = NGUITools.AddChild(self.groupEquip, self.groupEquipItem)
		local equipIcon = item:NodeByName("equipIcon").gameObject
		local itemIcon = ItemIcon.new(equipIcon)

		itemIcon:setInfo()
		itemIcon:SetActive(false)
		itemIcon:setDragScrollView(self.scroller_)

		self.groupEquipItems[i] = {
			itemObj = item,
			itemIcon = itemIcon,
			callback = function ()
				self:onclickCostIcon(i)
			end
		}
		self.cur_id = self.cur_id + 1
	end
end

function ArtifactUpWindow:registerEvent()
	UIEventListener.Get(self.btnUp).onClick = handler(self, self.onclickUpgrade)
	UIEventListener.Get(self.btnAutoAdd).onClick = handler(self, self.autoAdd)

	UIEventListener.Get(self.backBtn).onClick = function ()
		self:close()
	end

	self.eventProxy_:addEventListener(xyd.event.ARTIFACT_UPGRADE, self.onUpgrade, self)
	self.eventProxy_:addEventListener(xyd.event.ARTIFACT_UPGRADE2, self.onUpgrade, self)
end

function ArtifactUpWindow:updateProgressbar(thumb)
	self.progressBarValue = self.progressBarValue + thumb
	local maximum = xyd.tables.equipTable:getArtifactUpExp(self.itemID)
	self.upProgressbar.value = self.progressBarValue / maximum
	self.labelDisplay.text = self.progressBarValue .. "/" .. maximum

	if maximum <= self.progressBarValue then
		if not self.effectProgress then
			self.effectProgress = xyd.Spine.new(self.progressBarEffectGroup)

			self.effectProgress:setInfo("fx_ui_jindutiao", function ()
				self.effectProgress:SetLocalPosition(0, 1, 0)
				self.effectProgress:SetLocalScale(0.86, 0.9, 1)
				self.effectProgress:play("texiao01", 0)
				self.effectProgress:SetActive(true)
			end)
		else
			self.effectProgress:play("texiao01", 0)
			self.effectProgress:SetActive(true)
		end
	elseif self.effectProgress then
		self.effectProgress:stop()
		self.effectProgress:SetActive(false)
	end
end

function ArtifactUpWindow:autoAdd()
	local needExp = xyd.tables.equipTable:getArtifactUpExp(self.itemID) - self.progressBarValue
	local addList = {}

	for _, itemData in ipairs(self.infos) do
		if needExp <= 0 then
			break
		end

		local itemID = itemData.itemID

		if xyd.tables.itemTable:getQuality(itemID) <= 4 then
			local singleExp = xyd.tables.equipTable:getArtifactExp(itemID)
			local maxNum = itemData.num

			if needExp >= singleExp * maxNum then
				table.insert(addList, {
					itemID = itemID,
					num = maxNum
				})

				needExp = needExp - singleExp * maxNum
				itemData.num = itemData.num - maxNum
			else
				local addNum = math.modf(needExp / singleExp)

				if needExp > singleExp * addNum then
					addNum = addNum + 1
				end

				if maxNum >= addNum then
					table.insert(addList, {
						itemID = itemID,
						num = addNum
					})

					needExp = needExp - singleExp * addNum
					itemData.num = itemData.num - addNum
				end
			end
		end
	end

	for _, addItem in ipairs(addList) do
		self:addToCost(addItem.itemID, addItem.num)
	end

	self.multiWrap_:setInfos(self.infos, {
		keepPosition = true
	})
end

function ArtifactUpWindow:addToCost(itemID, num)
	local exp = xyd.tables.equipTable:getArtifactExp(itemID) * num

	self:updateProgressbar(exp)

	for k in pairs(self.groupEquipItems) do
		local item = self.groupEquipItems[k].itemIcon

		if itemID == item:getItemID() then
			local itemNum = item:getNum()

			item:setNum(itemNum + num)

			return true
		end
	end

	for k in pairs(self.groupEquipItems) do
		local item = self.groupEquipItems[k].itemIcon

		if item:getItemID() == 0 then
			item:setInfo({
				itemID = itemID,
				num = num,
				callback = function ()
					self:onclickCostIcon(k)
				end
			})
			item:SetActive(true)

			return true
		end
	end

	self.cur_id = self.cur_id + 1
	local id = self.cur_id
	local item = NGUITools.AddChild(self.groupEquip, self.groupEquipItem)
	local equipIcon = item:NodeByName("equipIcon").gameObject
	local itemIcon = ItemIcon.new(equipIcon)

	itemIcon:setDragScrollView(self.scroller_)

	self.groupEquipItems[id] = {
		itemObj = item,
		itemIcon = itemIcon
	}

	itemIcon:setInfo({
		itemID = itemID,
		num = num,
		callback = function ()
			self:onclickCostIcon(id)
		end
	})
	item:SetActive(true)
	self.groupEquipGrid:Reposition()

	if #self.groupEquipItems > 5 then
		-- Nothing
	end

	return true
end

function ArtifactUpWindow:iconCallback(itemID)
	local itemInfo = nil

	for i = 1, #self.infos do
		itemInfo = self.infos[i]

		if itemInfo.itemID == itemID then
			break
		end
	end

	if itemInfo == nil then
		return
	end

	local itemNum = itemInfo.num
	local params = {
		top = 550,
		itemID = itemID,
		itemNum = itemNum,
		callback = function (num)
			if num <= itemNum and self:addToCost(itemID, num) then
				itemInfo.num = itemNum - num

				self.multiWrap_:setInfos(self.infos, {
					keepPosition = true
				})
			end
		end
	}

	xyd.WindowManager.get():openWindow("artifact_offer_window", params)

	local win = xyd.WindowManager.get():getWindow("artifact_offer_window")

	if win then
		-- Nothing
	end
end

function ArtifactUpWindow:onclickUpgrade()
	local maximum = xyd.tables.equipTable:getArtifactUpExp(self.itemID)

	if self.progressBarValue < maximum then
		xyd.alertTips(__("NOT_ENOUGH_EXP"))

		return
	end

	local items = {}
	local count = 0

	for i in pairs(self.groupEquipItems) do
		local item = self.groupEquipItems[i].itemIcon

		if item:getItemID() > 0 then
			table.insert(items, {
				item_id = item:getItemID(),
				item_num = item:getNum()
			})
		end
	end

	local function levUp()
		for i in pairs(self.groupEquipItems) do
			count = count + 1
			local item = self.groupEquipItems[i].itemIcon

			item:setInfo()
			item:SetActive(false)

			if count > 5 then
				local itemObj = self.groupEquipItems[i].itemObj

				NGUITools.Destroy(itemObj)
			end
		end

		for i = #self.groupEquipItems, 6, -1 do
			self.groupEquipItems[i] = nil
		end

		for i in pairs(self.groupEquipItems) do
			if i > 5 then
				self.groupEquipItems[i] = nil
			end
		end

		self.groupEquipGrid:Reposition()

		if self.equipedPartner then
			self.equipedPartner:artifactUpgrade(items)
		else
			local msg = messages_pb:artifact_upgrade2_req()
			msg.item_id = self.itemID

			for _, item in ipairs(items) do
				local itemMsg = messages_pb:items_info()
				itemMsg.item_id = item.item_id
				itemMsg.item_num = item.item_num

				table.insert(msg.items, itemMsg)
			end

			xyd.Backend.get():request(xyd.mid.ARTIFACT_UPGRADE2, msg)

			self.tempNextID = self:initUpgradeItems()
		end

		self.scroller_:ResetPosition()
	end

	if self:checkItems(items) then
		xyd.alertYesNo(__("ARTIFACT_REMINDER_TEXT1"), function (yes)
			if yes then
				levUp()
			end
		end)
	else
		levUp()
	end
end

function ArtifactUpWindow:checkItems(items)
	for _, itemData in ipairs(items) do
		if xyd.tables.itemTable:getQuality(itemData.item_id) >= 5 then
			return true
		end
	end
end

function ArtifactUpWindow:onUpgrade(event)
	local effectLeft = xyd.Spine.new(self.itemBeforeEffect)
	local effectRight = xyd.Spine.new(self.itemAfterEffect)

	effectLeft:setInfo("fx_ui_shengjizi", function ()
		effectLeft:SetLocalPosition(0, 0, 0)
		effectLeft:SetLocalScale(1, 1, 1)
		effectLeft:setRenderTarget(self.itemBeforeEffect:GetComponent(typeof(UIWidget)), 1)
		effectRight:setInfo("fx_ui_shengjihuang", function ()
			effectRight:SetLocalPosition(0, 0, 0)
			effectRight:SetLocalScale(1, 1, 1)
			effectRight:setRenderTarget(self.itemAfterEffect:GetComponent(typeof(UIWidget)), 1)
			effectLeft:play("texiao", 1, 1, function ()
				local datas = xyd.models.backpack:getItems()

				if event.data.partner_info then
					local itemID = event.data.partner_info.equips[xyd.EquipPos.ARTIFACT]
					self.itemID = itemID
				else
					self.itemID = self.tempNextID
					self.tempNextID = nil
				end

				self.artifacts = {}

				for i = 1, #datas do
					local itemID = datas[i].item_id
					local itemNum = tonumber(datas[i].item_num)

					if not event.data.partner_info and self.itemID == itemID then
						itemNum = itemNum - 1
					end

					local item = {
						itemID = itemID,
						itemNum = itemNum
					}

					if xyd.tables.itemTable:getType(itemID) == xyd.ItemType.ARTIFACT and itemNum > 0 then
						table.insert(self.artifacts, item)
					end
				end

				self:sortEquips()

				local next_itemID = self:initUpgradeItems()

				if next_itemID == 0 then
					self:close()
					xyd.WindowManager.get():openWindow("gamble_rewards_window", {
						wnd_type = 2,
						data = {
							{
								item_num = 1,
								item_id = self.itemID
							}
						}
					})

					return
				end

				self:initProgressBar()
				self:initEquipContainer()
				effectLeft:destroy()
				xyd.alertItems({
					{
						item_num = 1,
						item_id = self.itemID
					}
				})
			end)
			effectRight:play("texiao", 1, 1, function ()
				effectRight:destroy()
			end)
		end)
	end)
end

function ArtifactUpWindow:onclickCostIcon(index)
	local item = self.groupEquipItems[index].itemIcon
	local num = item:getNum()
	local itemID = item:getItemID()

	if not itemID or itemID == 0 then
		return
	end

	local exp = xyd.tables.equipTable:getArtifactExp(itemID) * num

	self:updateProgressbar(-exp)

	for i = 1, #self.infos do
		local info = self.infos[i]

		if info.itemID == itemID then
			info.num = info.num + num
		end
	end

	self.multiWrap_:setInfos(self.infos, {
		keepPosition = true
	})
	item:setInfo()
	item:SetActive(false)

	if self.groupEquip.transform.childCount > 5 then
		local itemObj = self.groupEquipItems[index].itemObj

		NGUITools.Destroy(itemObj)

		self.groupEquipItems[index] = nil
	end

	self.groupEquipGrid:Reposition()
end

function ArtifactUpWindow:willClose()
	BaseWindow.willClose(self)

	for i = 1, #self.Effects do
	end
end

return ArtifactUpWindow
