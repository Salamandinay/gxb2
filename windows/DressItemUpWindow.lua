local DressItemUpWindow = class("DressItemUpWindow", import(".BaseWindow"))
local ResItem = import("app.components.ResItem")
local FreeItem = class("FreeItem", import("app.components.CopyComponent"))

function DressItemUpWindow:ctor(name, params)
	DressItemUpWindow.super.ctor(self, name, params)

	self.item_id = params.item_id
	self.self_item_fragment_id = xyd.tables.senpaiDressItemTable:getDressShard(self.item_id)[1]
	self.freeItems = {
		1999999,
		2999999,
		3999999,
		4999999,
		5999999,
		6999999
	}
	self.freeItemIds = xyd.tables.miscTable:split2num("dress_common_fragment_qlt_item_ids", "value", "|")
end

function DressItemUpWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function DressItemUpWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.top = self.groupAction:NodeByName("top").gameObject
	self.closeBtn = self.top:NodeByName("closeBtn").gameObject
	self.helpBtn = self.top:NodeByName("helpBtn").gameObject
	self.labelTitle = self.top:ComponentByName("labelTitle", typeof(UILabel))
	self.resGroup = self.groupAction:NodeByName("resGroup").gameObject
	self.resGroup_UILayout = self.groupAction:ComponentByName("resGroup", typeof(UILayout))
	self.changeGroup = self.groupAction:NodeByName("changeGroup").gameObject
	self.beforeScroller = self.changeGroup:NodeByName("beforeScroller").gameObject
	self.beforeScroller_UIScrollView = self.changeGroup:ComponentByName("beforeScroller", typeof(UIScrollView))
	self.beforeCon = self.beforeScroller:NodeByName("beforeCon").gameObject
	self.beforeIcon = self.beforeCon:NodeByName("beforeIcon").gameObject
	self.beforeName = self.beforeCon:ComponentByName("beforeName", typeof(UILabel))
	self.beforeAttrCon = self.beforeCon:NodeByName("beforeAttrCon").gameObject
	self.beforeAttrCon_UILayout = self.beforeCon:ComponentByName("beforeAttrCon", typeof(UILayout))
	self.beforeAttrLabel = self.beforeCon:ComponentByName("beforeAttrLabel", typeof(UILabel))
	self.effectGroup = self.changeGroup:ComponentByName("effectGroup", typeof(UISprite))
	self.afterScroller = self.changeGroup:NodeByName("afterScroller").gameObject
	self.afterScroller_UIScrollView = self.changeGroup:ComponentByName("afterScroller", typeof(UIScrollView))
	self.afterCon = self.afterScroller:NodeByName("afterCon").gameObject
	self.afterIcon = self.afterCon:NodeByName("afterIcon").gameObject
	self.afterName = self.afterCon:ComponentByName("afterName", typeof(UILabel))
	self.afterAttrCon = self.afterCon:NodeByName("afterAttrCon").gameObject
	self.afterAttrCon_UILayout = self.afterCon:ComponentByName("afterAttrCon", typeof(UILayout))
	self.afterAttrLabel = self.afterCon:ComponentByName("afterAttrLabel", typeof(UILabel))
	self.costGroup = self.groupAction:NodeByName("costGroup").gameObject
	self.levupBg = self.costGroup:ComponentByName("levupBg", typeof(UISprite))
	self.costIcon1 = self.costGroup:ComponentByName("costIcon1", typeof(UISprite))
	self.labelCostRes1 = self.costGroup:ComponentByName("labelCostRes1", typeof(UILabel))
	self.costIcon2 = self.costGroup:ComponentByName("costIcon2", typeof(UISprite))
	self.labelCostRes2 = self.costGroup:ComponentByName("labelCostRes2", typeof(UILabel))
	self.iconShow = self.costGroup:NodeByName("iconShow").gameObject
	self.itemCon = self.iconShow:NodeByName("itemCon").gameObject
	self.itemCon_UILayout = self.iconShow:ComponentByName("itemCon", typeof(UILayout))
	self.iconShowBg = self.iconShow:ComponentByName("iconShowBg", typeof(UISprite))
	self.btnGroup = self.groupAction:NodeByName("btnGroup").gameObject
	self.btnUp = self.btnGroup:NodeByName("btnUp").gameObject
	self.button_label = self.btnUp:ComponentByName("button_label", typeof(UILabel))
	self.noneText = self.iconShow:ComponentByName("noneText", typeof(UILabel))
	self.freeItem = self.iconShow:NodeByName("freeItem").gameObject
end

function DressItemUpWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "DRESS_LEV_UP_HELP"
		})
	end)
	UIEventListener.Get(self.btnUp.gameObject).onClick = handler(self, self.onTouchBtn)

	self.eventProxy_:addEventListener(xyd.event.DRESS_UPGRADE_DRESS, handler(self, self.dressUpgradeDressBack))
end

function DressItemUpWindow:layout()
	self.labelTitle.text = __("DRESS_ITEM_UP_WINDOW_1")
	self.button_label.text = __("LEV_UP")
	self.noneText.text = __("DRESS_ITEM_UP_TIPS")

	self:updateCostInfo()
end

function DressItemUpWindow:updateCostInfo()
	self.common_cost_arr = {}
	self.fragment_cost_arr = {}
	self.general_cost_arr = {}
	local cost_all_items = xyd.tables.senpaiDressItemTable:getUpgradeCost(self.item_id)

	for i in pairs(cost_all_items) do
		if xyd.tables.itemTable:getType(cost_all_items[i][1]) == xyd.ItemType.DRESS_FRAGMENT then
			table.insert(self.fragment_cost_arr, cost_all_items[i])
		else
			table.insert(self.general_cost_arr, cost_all_items[i])
		end
	end

	local cost_all_items_2 = xyd.tables.senpaiDressItemTable:getUpgradeCost2(self.item_id)

	for i in pairs(cost_all_items_2) do
		table.insert(self.common_cost_arr, cost_all_items_2[i])
	end

	dump(self.common_cost_arr, "创建出的")
	self:updateCost()
	self:updateShowItem()
	self:updateFragment()
end

function DressItemUpWindow:updateCost()
	if self.general_cost_arr and #self.general_cost_arr == 1 then
		self.levupBg.width = 220

		self.costIcon1.gameObject:X(-35.8)
		self.labelCostRes1.gameObject:X(26.8)
		self.costIcon2.gameObject:SetActive(false)
		self.labelCostRes2.gameObject:SetActive(false)
	elseif self.general_cost_arr and #self.general_cost_arr == 2 then
		self.levupBg.width = 354

		self.costIcon1.gameObject:X(-150.6)
		self.labelCostRes1.gameObject:X(-88)
		self.costIcon2.gameObject:SetActive(true)
		self.labelCostRes2.gameObject:SetActive(true)
	end

	for i, item in pairs(self.general_cost_arr) do
		xyd.setUISpriteAsync(self["costIcon" .. i], nil, xyd.tables.itemTable:getIcon(item[1]), nil, , )

		self["labelCostRes" .. i].text = tostring(xyd.getRoughDisplayNumber(item[2]))

		if xyd.models.backpack:getItemNumByID(item[1]) < item[2] then
			self["labelCostRes" .. i].color = Color.New2(3422556671.0)
		else
			self["labelCostRes" .. i].color = Color.New2(960513791)
		end

		local params = {
			tableId = item[1],
			callback = function ()
				local params = {
					itemID = item[1],
					wndType = xyd.ItemTipsWndType.BACKPACK
				}

				xyd.WindowManager.get():openWindow("item_tips_window", params)
			end
		}

		if not self.topItems then
			self.topItems = {}
		end

		if self.topItems[i] then
			self.topItems[i]:setInfo(params)
		else
			local item = ResItem.new(self.resGroup.gameObject)

			item:setInfo(params)
			table.insert(self.topItems, item)
		end

		self.topItems[i]:showTips()
		self.topItems[i]:refresh()
	end

	self.resGroup_UILayout:Reposition()
end

function DressItemUpWindow:updateShowItem()
	if not self.berfore_icon then
		local item = {
			isAddUIDragScrollView = true,
			itemID = self.item_id,
			scale = Vector3(0.5, 0.5, 1),
			uiRoot = self.beforeIcon.gameObject
		}
		self.berfore_icon = xyd.getItemIcon(item)
	else
		self.berfore_icon:setInfo({
			itemID = self.item_id
		})
	end

	self.beforeName.text = xyd.tables.itemTable:getName(self.item_id)

	NGUITools.DestroyChildren(self.beforeAttrCon.transform)

	local text_all_height = 0
	local gap = self.beforeAttrCon_UILayout.gap.y

	for i = 1, 3 do
		local attr = xyd.tables.senpaiDressItemTable["getBase" .. i](xyd.tables.senpaiDressItemTable, self.item_id)

		if attr and attr ~= 0 then
			local attr_obj = NGUITools.AddChild(self.beforeAttrCon.gameObject, self.beforeAttrLabel.gameObject)

			attr_obj:SetActive(true)

			local attr_text = attr_obj:GetComponent(typeof(UILabel))
			attr_text.text = "+" .. attr .. " " .. __("PERSON_DRESS_ATTR_" .. i)
			text_all_height = text_all_height + attr_text.height + gap
		end
	end

	local before_skillIds = xyd.tables.senpaiDressItemTable:getSkillIds(self.item_id)

	if before_skillIds and #before_skillIds > 0 then
		local before_skill_desc = xyd.tables.senpaiDressSkillTextTable:getDesc(before_skillIds[#before_skillIds])
		local before_skill_attr_obj = NGUITools.AddChild(self.beforeAttrCon.gameObject, self.beforeAttrLabel.gameObject)

		before_skill_attr_obj:SetActive(true)

		local before_skill_attr_text = before_skill_attr_obj:GetComponent(typeof(UILabel))
		before_skill_attr_text.text = before_skill_desc
		text_all_height = text_all_height + before_skill_attr_text.height + gap
	end

	self.beforeAttrCon:GetComponent(typeof(UIWidget)).height = text_all_height

	self.beforeAttrCon_UILayout:Reposition()
	self.beforeScroller_UIScrollView:ResetPosition()

	local next_item_id = xyd.tables.senpaiDressItemTable:getNextId(self.item_id)

	if next_item_id and next_item_id ~= 0 then
		if not self.after_icon then
			local item = {
				isAddUIDragScrollView = true,
				itemID = next_item_id,
				scale = Vector3(0.5, 0.5, 1),
				uiRoot = self.afterIcon.gameObject
			}
			self.after_icon = xyd.getItemIcon(item)
		else
			self.after_icon:setInfo({
				itemID = next_item_id
			})
		end

		self.afterName.text = xyd.tables.itemTable:getName(next_item_id)

		NGUITools.DestroyChildren(self.afterAttrCon.transform)

		local text_all_height = 0
		local gap = self.afterAttrCon_UILayout.gap.y

		for i = 1, 3 do
			local attr = xyd.tables.senpaiDressItemTable["getBase" .. i](xyd.tables.senpaiDressItemTable, next_item_id)

			if attr and attr ~= 0 then
				local attr_obj = NGUITools.AddChild(self.afterAttrCon.gameObject, self.afterAttrLabel.gameObject)

				attr_obj:SetActive(true)

				local attr_text = attr_obj:GetComponent(typeof(UILabel))
				attr_text.text = "+" .. attr .. " " .. __("PERSON_DRESS_ATTR_" .. i)
				text_all_height = text_all_height + attr_text.height + gap
			end
		end

		local after_skillIds = xyd.tables.senpaiDressItemTable:getSkillIds(next_item_id)

		if after_skillIds and #after_skillIds > 0 then
			local after_skill_desc = xyd.tables.senpaiDressSkillTextTable:getDesc(after_skillIds[#after_skillIds])
			local after_skill_attr_obj = NGUITools.AddChild(self.afterAttrCon.gameObject, self.afterAttrLabel.gameObject)

			after_skill_attr_obj:SetActive(true)

			local after_skill_attr_text = after_skill_attr_obj:GetComponent(typeof(UILabel))
			after_skill_attr_text.text = after_skill_desc
			text_all_height = text_all_height + after_skill_attr_text.height + gap
		end

		self.afterAttrCon:GetComponent(typeof(UIWidget)).height = text_all_height

		self.afterAttrCon_UILayout:Reposition()
		self.afterScroller_UIScrollView:ResetPosition()
	else
		self.afterScroller.gameObject:SetActive(false)
	end
end

function DressItemUpWindow:updateFragment()
	NGUITools.DestroyChildren(self.itemCon.transform)

	self.itemFrees = {}
	self.choiceFragmentArr = {}

	for i in pairs(self.fragment_cost_arr) do
		local tmp = NGUITools.AddChild(self.itemCon.gameObject, self.freeItem.gameObject)
		local params = {
			choice_num = 0,
			is_common = false,
			item_id = self.fragment_cost_arr[i][1],
			item_num = self.fragment_cost_arr[i][2],
			choice_yet_infos = {}
		}
		params.choice_num = xyd.models.backpack:getItemNumByID(params.item_id)

		if params.item_num < params.choice_num then
			params.choice_num = params.item_num
		end

		if params.choice_num > 0 then
			table.insert(params.choice_yet_infos, {
				item_id = params.item_id,
				item_num = params.choice_num
			})
		end

		local item = FreeItem.new(tmp, self, params)

		table.insert(self.itemFrees, item)
		table.insert(self.choiceFragmentArr, params)
	end

	for i in pairs(self.common_cost_arr) do
		local tmp = NGUITools.AddChild(self.itemCon.gameObject, self.freeItem.gameObject)
		local params = {
			choice_num = 0,
			is_common = true,
			item_id = self.common_cost_arr[i][1],
			item_num = self.common_cost_arr[i][2],
			choice_yet_infos = {}
		}
		local item = FreeItem.new(tmp, self, params)

		table.insert(self.itemFrees, item)
		table.insert(self.choiceFragmentArr, params)
	end

	if not self.isFirstSetCommonNum then
		self.isFirstSetCommonNum = true

		self:firstSetCommonNum()
	end

	if #self.itemFrees == 0 then
		self.noneText.gameObject:SetActive(true)
	else
		self.noneText.gameObject:SetActive(false)
	end

	self.itemCon_UILayout:Reposition()
end

function DressItemUpWindow:firstSetCommonNum()
	for k in pairs(self.common_cost_arr) do
		local qlt = self.common_cost_arr[k][1]
		local arr = xyd.models.dress:getCommonQltFragmentArr(qlt, self.self_item_fragment_id)
		local can_choice_num = self.common_cost_arr[k][2]
		local choice_yet_infos = {}

		for i in pairs(arr) do
			if arr[i].is_can_use == 1 then
				local is_choice_index = -1

				for k in pairs(choice_yet_infos) do
					if arr[i].item_id == choice_yet_infos[k].item_id then
						is_choice_index = k
					end
				end

				if can_choice_num <= arr[i].item_num then
					table.insert(choice_yet_infos, {
						item_id = arr[i].item_id,
						item_num = can_choice_num
					})

					can_choice_num = 0

					break
				else
					table.insert(choice_yet_infos, {
						item_id = arr[i].item_id,
						item_num = arr[i].item_num
					})

					can_choice_num = can_choice_num - arr[i].item_num
				end
			end
		end

		self:updateFragmentNum(self.common_cost_arr[k][1], choice_yet_infos)
	end
end

function DressItemUpWindow:updateFragmentNum(item_id, choice_yet_infos)
	for i in pairs(self.choiceFragmentArr) do
		if self.choiceFragmentArr[i].item_id == item_id then
			self.itemFrees[i]:setChoiceYetInfos(choice_yet_infos)

			self.choiceFragmentArr[i].choice_yet_infos = choice_yet_infos
		end
	end
end

function DressItemUpWindow:onTouchBtn()
	for i in pairs(self.itemFrees) do
		if self.itemFrees[i]:getChoiceNum() < self.itemFrees[i]:getItemNum() then
			xyd.alertTips(__("DRESS_ITEM_UP_WINDOW_2"))

			return
		end
	end

	local cost_items = self.general_cost_arr
	local text = ""

	for i in pairs(cost_items) do
		if xyd.models.backpack:getItemNumByID(cost_items[i][1]) < cost_items[i][2] then
			if i ~= 1 then
				text = text .. "\n"
			end

			text = text .. __("NOT_ENOUGH", xyd.tables.itemTable:getName(cost_items[i][1]))
		end
	end

	if text ~= "" then
		xyd.alertTips(text)

		return
	end

	local msg = messages_pb:dress_upgrade_dress_req()
	msg.item_id = self.item_id
	msg.item_num = 1

	if self.common_cost_arr and #self.common_cost_arr > 0 then
		for i in pairs(self.itemFrees) do
			if self.itemFrees[i]:getIsCommon() then
				local choice_yet_infos = self.itemFrees[i]:getChoiceYetInfos()

				for j in pairs(choice_yet_infos) do
					local item_info = messages_pb:items_info()
					item_info.item_id = choice_yet_infos[j].item_id
					item_info.item_num = choice_yet_infos[j].item_num

					table.insert(msg.common_items, item_info)
				end
			end
		end
	end

	xyd.Backend.get():request(xyd.mid.DRESS_UPGRADE_DRESS, msg)
end

function DressItemUpWindow:dressUpgradeDressBack()
	local items = {}
	local next_item_id = xyd.tables.senpaiDressItemTable:getNextId(self.item_id)

	table.insert(items, {
		item_num = 1,
		item_id = next_item_id
	})

	local next_next_item_id = xyd.tables.senpaiDressItemTable:getNextId(next_item_id)

	xyd.alertItems(items, function ()
		next_next_item_id = xyd.tables.senpaiDressItemTable:getNextId(next_item_id)

		if not next_next_item_id or next_next_item_id and next_next_item_id == 0 then
			self:close()
		end
	end)

	if next_next_item_id and next_next_item_id ~= 0 then
		self.item_id = next_item_id
		self.isFirstSetCommonNum = false

		self:updateCostInfo()
	end

	if next_item_id and next_item_id > 0 then
		local dress_id = xyd.tables.senpaiDressItemTable:getDressId(next_item_id)

		xyd.models.dress:updateGroupItems(next_item_id, dress_id, true)
	end
end

function DressItemUpWindow:close()
	local dress_main_wn = xyd.WindowManager.get():getWindow("dress_main_window")

	if dress_main_wn then
		dress_main_wn:updateBackItems()
	end

	DressItemUpWindow.super.close(self)
end

function DressItemUpWindow:getSelfFragmentID()
	return self.self_item_fragment_id
end

function FreeItem:ctor(goItem, parent, itemdata)
	self.goItem_ = goItem
	self.parent = parent
	self.item_id = itemdata.item_id
	self.item_num = itemdata.item_num
	self.is_common = itemdata.is_common
	self.choice_num = itemdata.choice_num
	self.choice_yet_infos = itemdata.choice_yet_infos
	self.freeItem = goItem.transform
	self.itemCon = self.freeItem:NodeByName("itemCon").gameObject
	self.numText = self.freeItem:ComponentByName("numText", typeof(UILabel))

	self:initItem(itemdata)
end

function FreeItem:initItem(itemdata)
	if not self.is_common then
		local icon = xyd.getItemIcon({
			itemID = self.item_id,
			uiRoot = self.itemCon.gameObject,
			scale = Vector3(0.8981481481481481, 0.8981481481481481, 1),
			callback = function ()
				xyd.WindowManager.get():openWindow("dress_choice_fragment_window", {
					item_id = self.item_id,
					all_num = self.item_num,
					choice_yet_infos = self.choice_yet_infos,
					is_common = self.is_common,
					self_item_fragment_id = self.parent:getSelfFragmentID()
				})
			end
		})

		self:updateNumText(self.choice_num)
	else
		local icon = xyd.getItemIcon({
			itemID = self.parent.freeItemIds[self.item_id],
			uiRoot = self.itemCon.gameObject,
			scale = Vector3(0.8981481481481481, 0.8981481481481481, 1),
			callback = function ()
				xyd.WindowManager.get():openWindow("dress_choice_fragment_window", {
					item_id = self.item_id,
					all_num = self.item_num,
					choice_yet_infos = self.choice_yet_infos,
					is_common = self.is_common,
					self_item_fragment_id = self.parent:getSelfFragmentID()
				})
			end
		})

		self:updateNumText(self.choice_num)
	end
end

function FreeItem:updateNumText(leftNum)
	self.numText.text = leftNum .. "/" .. self.item_num

	if leftNum < self.item_num then
		self.numText.color = Color.New2(4278124287.0)
	else
		self.numText.color = Color.New2(2986279167.0)
	end
end

function FreeItem:getItemId()
	return self.item_id
end

function FreeItem:getItemNum()
	return self.item_num
end

function FreeItem:getChoiceNum()
	return self.choice_num
end

function FreeItem:getIsCommon()
	return self.is_common
end

function FreeItem:getChoiceYetInfos()
	return self.choice_yet_infos
end

function FreeItem:setChoiceYetInfos(choice_yet_infos)
	self.choice_yet_infos = choice_yet_infos
	local all_num = 0

	for i in pairs(self.choice_yet_infos) do
		all_num = all_num + self.choice_yet_infos[i].item_num
	end

	self.choice_num = all_num

	self:updateNumText(self.choice_num)
end

return DressItemUpWindow
