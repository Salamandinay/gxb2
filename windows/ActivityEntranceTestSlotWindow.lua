local SlotWindow = import(".SlotWindow")
local ActivityEntranceTestSlotWindow = class("ActivityEntranceTestSlotWindow", SlotWindow)
local EntranceTestSlotPartnerCard = class("EntranceTestSlotPartnerCard", import("app.components.BaseComponent"))
local EntranceTestClipContent = class("EntranceTestClipContent", import("app.components.BaseComponent"))
local PartnerCard = import("app.components.PartnerCard")
local WindowTop = import("app.components.WindowTop")

function ActivityEntranceTestSlotWindow:ctor(name, params)
	ActivityEntranceTestSlotWindow.super.ctor(self, name, params)

	self.currentState = "entrance"
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	self.sortType = xyd.partnerSortType.SHENXUE

	if params then
		self.fromTask = params.fromTask
	end
end

function ActivityEntranceTestSlotWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.top, self.name_, 5)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function ActivityEntranceTestSlotWindow:getUIComponent()
	ActivityEntranceTestSlotWindow.super.getUIComponent(self)
	self.renderPanel:SetTopAnchor(self.renderPanel_anchorObj, 1, -10)
	self.groupSelectLabel:SetActive(false)

	self.content = self.window_:NodeByName("middle/content").gameObject
end

function ActivityEntranceTestSlotWindow:initLayout()
	SlotWindow.initLayout(self)
	self.nav:SetLocalScale(1, 0, 1)

	self.groupSelectLabel.text = ""

	self.addSlotBtn:SetActive(false)
	self.slotNum:SetLocalPosition(340, 0, 0)
	self.slotNum:SetActive(false)

	self["label" .. tostring(9)].text = __("ENTRANCE_TEST_SORT")
end

function ActivityEntranceTestSlotWindow:initWindow()
	SlotWindow.super.initWindow(self)
	self:getUIComponent()
	self:initTopGroup()
	self:initLayout()
	self:registerEvent()
	self:waitForFrame(1, function ()
		self:initFixedMultiWrapContent(self.scrollView_, self.wrapContent_, self.partnerCard_, self.SlotPartnerCard)
		self:initData()
	end)

	if self.params_.type and tonumber(self.params_.type) > 0 then
		self:waitForFrame(1, function ()
			self.topBar_:setTabActive(self.params_.type, true)
		end)
	end

	self.middle.transform:SetLocalPosition(-1000, 0, 0)
	self:initShowPanel()
end

function ActivityEntranceTestSlotWindow:initShowPanel()
	if not self.bg_panel then
		local bg_panel_item = EntranceTestClipContent.new(self.window_)
		self.bg_panel_item = bg_panel_item:getGameObject()
		local window_panel = self.window_:GetComponent(typeof(UIPanel))
		local bg_panel = bg_panel_item:getPanel():GetComponent(typeof(UIPanel))
		self.bg_panel = bg_panel_item:getPanel()
		bg_panel.depth = self.window_:GetComponent(typeof(UIPanel)).depth + 5

		self.bg_panel_item.gameObject:X(2000)
		self:waitForFrame(30, function ()
			local bg_panel_item_uiwidget = self.bg_panel_item:GetComponent(typeof(UIWidget))
			bg_panel_item_uiwidget.width = window_panel.width
			bg_panel_item_uiwidget.height = window_panel.height
		end)
	end

	if not self.textureBg then
		local bg = NGUITools.AddChild(self.bg_panel.gameObject, "windowShowBg")
		local textureBg = bg:AddComponent(typeof(UITexture))
		local bg_UIWidget = bg:GetComponent(typeof(UIWidget))
		bg_UIWidget.depth = 5
		bg_UIWidget.height = NGUITools.screenSize.y
		bg_UIWidget.width = NGUITools.screenSize.x
		self.textureBg = textureBg
	end
end

function ActivityEntranceTestSlotWindow:registerEvent()
	ActivityEntranceTestSlotWindow.super.registerEvent(self)
	self.sortTab:setTabActive(self.sortType + 1, true, false)
	self.sortPop:NodeByName("tab_" .. xyd.partnerSortType.isCollected + 1).gameObject:SetActive(false)

	local imgChoose = self.sortPop:NodeByName("tab_10"):ComponentByName("chosen", typeof(UISprite))

	xyd.setUISpriteAsync(imgChoose, nil, "partner_sort_bg_chosen_01", nil, )

	local imgUnChoose = self.sortPop:NodeByName("tab_10"):ComponentByName("unchosen", typeof(UISprite))

	xyd.setUISpriteAsync(imgUnChoose, nil, "partner_sort_bg_unchosen_01", nil, )
end

function ActivityEntranceTestSlotWindow:initFixedMultiWrapContent(scrollView, wrapContent_, partnerCard, SlotPartnerCard)
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent_, partnerCard, EntranceTestSlotPartnerCard, self)
end

function ActivityEntranceTestSlotWindow:initData()
	self:updateDataGroup()
end

function ActivityEntranceTestSlotWindow:updateDataGroup(isUpdateArr)
	if isUpdateArr == nil then
		isUpdateArr = true
	end

	if isUpdateArr then
		local sortedPartners = self.activityData:getSortedPartners()

		for key in pairs(sortedPartners) do
			local res = {}

			for i, partner in pairs(sortedPartners[key]) do
				local params = {
					partner = partner,
					key = key,
					red_point = self:checkRedMark(partner)
				}

				if partner.partnerID and partner.partnerID ~= 0 then
					table.insert(res, params)
				end
			end

			self.sortedPartners[key] = res
		end
	end

	SlotWindow.updateDataGroup(self)

	local num = #self.activityData.detail.partner_list or 0
	self.slotNum.text = tostring(num) .. "/" .. tostring(xyd.tables.miscTable:getNumber("activity_warmup_arena_partner_limit", "value"))

	self:waitForFrame(2, function ()
		self.scrollView_:ResetPosition()
	end)
end

function ActivityEntranceTestSlotWindow:addSortedPartners(sortedPartners, keyValue)
	if sortedPartners == nil then
		local arr = xyd.split(keyValue, "_")

		if #arr == 2 then
			sortedPartners = self.activityData:getSortedPartnersBySort(tonumber(arr[1]), tonumber(arr[2]))
		end

		if #arr == 3 then
			sortedPartners = self.activityData:getSortedPartnersBySort(tonumber(arr[1]), tonumber(arr[2]), tonumber(arr[3]))
		end
	end

	if keyValue == nil then
		keyValue = self.sortType .. "_0"
	end

	for key in pairs(sortedPartners) do
		if tostring(key) == keyValue then
			local res = {}

			for _, partner_id in pairs(sortedPartners[key]) do
				local params = {
					partner_id = partner_id,
					key = key,
					red_point = self:checkRedMark(partner_id)
				}

				table.insert(res, params)
			end

			self.sortedPartners[key] = res
		end
	end
end

function ActivityEntranceTestSlotWindow:addNewPartner(partner)
	local num = #self.activityData.detail.partner_list or 0
	self.slotNum.text = tostring(num) .. "/" .. tostring(xyd.tables.miscTable:getNumber("activity_warmup_arena_partner_limit", "value"))
	local key = tostring(self.sortType) .. "_" .. tostring(self.chosenGroup)

	table.insert(self.sortedPartners[key], 2, {
		partner = partner,
		key = key,
		red_point = self:checkRedMark(partner.partnerID)
	})
	self:updateDataGroup(false)
end

function ActivityEntranceTestSlotWindow:checkRedMark(partner)
	return false
end

function ActivityEntranceTestSlotWindow:willClose()
	SlotWindow.willClose(self)
	self.activityData:sendSettedPartnerReq()
end

function ActivityEntranceTestSlotWindow:addImg(uploadImg)
	if not self.notSetScale then
		local scale = self.window_.gameObject:GetComponent(typeof(UIPanel)).width / NGUITools.screenSize.x

		self.textureBg.gameObject:SetLocalScale(scale, scale, 1)

		self.notSetScale = true
	end

	self.bg_panel_item.gameObject:X(0)

	self.textureBg.mainTexture = uploadImg

	if not self.firstOpenUpLoad then
		self:waitForTime(0.1, function ()
			local activity_entrance_test_partner_wd = xyd.WindowManager.get():getWindow("activity_entrance_test_partner_window")

			if activity_entrance_test_partner_wd then
				self.content:SetLocalPosition(2000, 0, 0)
			end

			self.firstOpenUpLoad = true
		end)
	else
		self.content:SetLocalPosition(2000, 0, 0)
	end
end

function ActivityEntranceTestSlotWindow:showImgState(state)
	if state then
		self.bg_panel_item.gameObject:X(0)
		self.content:SetLocalPosition(2000, 0, 0)
	else
		self.content:SetLocalPosition(0, 0, 0)
		self.bg_panel_item.gameObject:X(2000)
	end
end

function EntranceTestSlotPartnerCard:ctor(go, parent)
	EntranceTestSlotPartnerCard.super.ctor(self, go)

	self.win_ = nil
	self.trnas = go
	self.win_ = xyd.WindowManager.get():getWindow("activity_entrance_test_slot_window")
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	local root = self.go
	self.card_node = root:NodeByName("card_node").gameObject
	self.finish_img = root:ComponentByName("finish_img", typeof(UITexture))
	self.new_img = root:ComponentByName("new_img", typeof(UISprite))
	self.finish_img:GetComponent(typeof(UIWidget)).depth = 1050

	self.finish_img:SetLocalPosition(49, 100, 0)
	self.new_img:SetLocalPosition(-50, 115, 0)
	self:createChildren(go, parent)

	self.go = go
	self.parent = parent
end

function EntranceTestSlotPartnerCard:getPrefabPath()
	return "Prefabs/Components/activityEntranceTestEmptyCard"
end

function EntranceTestSlotPartnerCard:init(partner, sort_key, red_point)
	self.new_img:SetActive(false)

	if partner then
		self.card_node:SetActive(true)
		self.partnerCard:setInfo(nil, partner)
		self.partnerCard.partnerMarked:SetActive(false)
		self.partnerCard:setUpgradeEffect(false)
		self.partnerCard:setRedPoint(red_point)
		self.finish_img:SetActive(self.activityData:checkIsFinish(partner))

		local tableIds = {}
		local allIds = xyd.tables.activityWarmupArenaPartnerTable:getIds()

		for i in pairs(allIds) do
			if xyd.tables.activityWarmupArenaPartnerTable:getIsNewPartner(allIds[i]) == 1 then
				table.insert(tableIds, xyd.tables.activityWarmupArenaPartnerTable:getPartnerId(allIds[i]))
			end
		end

		for i, id in pairs(tableIds) do
			if partner.tableID == id then
				self.new_img:SetActive(true)
			end
		end
	else
		self.finish_img:SetActive(false)
		self.card_node:SetActive(false)
	end

	if self.data and self.data.partner then
		local np = self.data.partner
		local table_id = np.tableID

		if not self.flag and self.parent.fromTask and tonumber(table_id) == tonumber(xyd.tables.miscTable:split2num("entrance_test_help_show", "value", "|")[1]) then
			print("=-----------------------------------------")

			self.effect = xyd.Spine.new(self.card_node.gameObject)

			self.effect:setInfo("fx_ui_dianji", function ()
				self.effect:setRenderTarget(self.new_img.gameObject:GetComponent(typeof(UISprite)), 50)
				self.effect:play("texiao01", 0)
			end)
		end
	end
end

function EntranceTestSlotPartnerCard:createChildren(go, parent)
	self.partnerCard = PartnerCard.new(self.card_node, parent.renderPanel)

	xyd.setUITextureAsync(self.finish_img, "Textures/activity_text_web/activity_entrance_test_finish_" .. xyd.Global.lang)

	UIEventListener.Get(self.trnas.gameObject).onClick = handler(self, function ()
		if self.data.partner then
			local np = self.data.partner
			local table_id = np.tableID

			if self.effect then
				self.effect:stop()

				self.flag = true
			end

			self:waitForFrame(1, function ()
				local tex = XYDUtils.CameraCapture(xyd.WindowManager.get():getUICamera(), UnityEngine.Rect(0, 0, NGUITools.screenSize.x, NGUITools.screenSize.y), NGUITools.screenSize.x, NGUITools.screenSize.y)
				local params = {
					partner = self.data.partner,
					sort_key = self.data.key,
					table_id = table_id,
					current_group = parent.chosenGroup,
					sort_type = parent.sortType
				}
				local now_key = self.data.key
				local keys = xyd.split(now_key, "_")
				params.sort_key = keys[1] .. "_" .. "0" .. "_0"

				parent:addImg(tex)
				xyd.WindowManager.get():openWindow("activity_entrance_test_partner_window", params)
			end)
		else
			xyd.WindowManager.get():openWindow("activity_entrance_test_add_hero_window", {
				sort_key = self.data.key,
				chosenGroup = parent.chosenGroup
			})
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
	end)
end

function EntranceTestSlotPartnerCard:update(index, realIndex, info)
	if info == nil then
		self.trnas:SetActive(false)

		return
	end

	self.trnas:SetActive(true)

	self.data = info

	self:init(self.data.partner, self.data.key, self.data.red_point)

	self.name = "SlotPartnerCard" .. tostring(self.itemIndex)
end

function EntranceTestSlotPartnerCard:setGEffectVisible(state)
	if self.partnerCard then
		self.partnerCard:setGEffectVisible(state)
	end
end

function EntranceTestClipContent:ctor(parentGo)
	EntranceTestSlotPartnerCard.super.ctor(self, parentGo)
end

function EntranceTestClipContent:getPrefabPath()
	return "Prefabs/Components/entrance_test_clip_content"
end

function EntranceTestClipContent:initUI()
	self:getUIComponent()
	EntranceTestClipContent.super.initUI(self)
end

function EntranceTestClipContent:getUIComponent()
	self.windowShowPanel = self.go:NodeByName("windowShowPanel").gameObject
end

function EntranceTestClipContent:getPanel()
	return self.windowShowPanel
end

return ActivityEntranceTestSlotWindow
