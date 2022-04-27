local DressSuitWindow = class("DressSuitWindow", import(".BaseWindow"))
local CommonTabBar = import("app.common.ui.CommonTabBar")
local DressSuitOfficeItem = class("DressMainAchievementItem", import("app.components.CopyComponent"))
local DressSuitSelfItem = class("DressMainAchievementItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local JSON = require("cjson")

function DressSuitWindow:ctor(name, params)
	DressSuitWindow.super.ctor(self, name, params)

	self.itemEffectDepth = 100
end

function DressSuitWindow:initWindow()
	self:getUIComponent()
	self:reSize()
	self:layout()
	self:registerEvent()
end

function DressSuitWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle_ = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.nav = self.groupAction:NodeByName("nav").gameObject
	self.page1 = self.groupAction:NodeByName("page1").gameObject
	self.official_suit_item = self.page1:NodeByName("official_suit_item").gameObject
	self.firstScroller = self.page1:NodeByName("firstScroller").gameObject
	self.firstScroller_UIScrollView = self.page1:ComponentByName("firstScroller", typeof(UIScrollView))
	self.firstScroller_UIPanel = self.page1:ComponentByName("firstScroller", typeof(UIPanel))
	self.firstItemList = self.firstScroller:NodeByName("firstItemList").gameObject
	self.firstItemList_UIWrapContent = self.firstScroller:ComponentByName("firstItemList", typeof(UIWrapContent))
	self.firstWrapContent = FixedWrapContent.new(self.firstScroller_UIScrollView, self.firstItemList_UIWrapContent, self.official_suit_item, DressSuitOfficeItem, self)
	self.noneCon = self.page1:NodeByName("noneCon").gameObject
	self.noneImg = self.noneCon:ComponentByName("noneImg", typeof(UISprite))
	self.noneLabel = self.noneCon:ComponentByName("noneLabel", typeof(UILabel))
	self.page2 = self.groupAction:NodeByName("page2").gameObject
	self.self_suit_item = self.page2:NodeByName("self_suit_item").gameObject
	self.secondSAcroller = self.page2:NodeByName("secondSAcroller").gameObject
	self.secondSAcroller_UIScrollView = self.page2:ComponentByName("secondSAcroller", typeof(UIScrollView))
	self.secondSAcroller_UIPanel = self.page2:ComponentByName("secondSAcroller", typeof(UIPanel))
	self.secondItemList = self.secondSAcroller:NodeByName("secondItemList").gameObject
	self.secondItemList_UIWrapContent = self.secondSAcroller:ComponentByName("secondItemList", typeof(UIWrapContent))
	self.secondWrapContent = FixedWrapContent.new(self.secondSAcroller_UIScrollView, self.secondItemList_UIWrapContent, self.self_suit_item, DressSuitSelfItem, self)
end

function DressSuitWindow:reSize()
end

function DressSuitWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = handler(self, function ()
		self:close()
	end)

	self.eventProxy_:addEventListener(xyd.event.DRESS_SUIT_SAVE, handler(self, self.dressSuitSave))
	self.eventProxy_:addEventListener(xyd.event.DRESS_SUIT_REMOVE, handler(self, self.dressSuitRemove))
end

function DressSuitWindow:layout()
	self.labelTitle_.text = __("DRESS_SUIT_WINDOW_3")
	self.noneLabel.text = __("DRESS_SUIT_WINDOW_4")

	self:initNav()
end

function DressSuitWindow:initNav()
	self.tabBar = CommonTabBar.new(self.nav, 2, function (index)
		self:updatePage(index)
	end, nil, , 10)
	local textArr = {}

	for i = 1, 2 do
		table.insert(textArr, __("DRESS_SUIT_WINDOW_" .. i))
	end

	self.tabBar:setTexts(textArr)
end

function DressSuitWindow:updatePage(index)
	if self.tabIndex and self.tabIndex == index then
		return
	end

	self.tabIndex = index

	if index == 1 then
		if not self.firstInitPageOne then
			self:initPageOne()

			self.firstInitPageOne = true
		end

		self.page1.gameObject:SetActive(true)
		self.page2.gameObject:SetActive(false)
	elseif index == 2 then
		if not self.firstInitPageTow then
			self:initPageTwo()

			self.firstInitPageTow = true
		end

		self.page1.gameObject:SetActive(false)
		self.page2.gameObject:SetActive(true)
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)
end

function DressSuitWindow:initPageOne()
	local local_dress_save_office_active = xyd.db.misc:getValue("local_dress_save_office_active_new")

	if not local_dress_save_office_active then
		local_dress_save_office_active = {}
	else
		local_dress_save_office_active = JSON.decode(local_dress_save_office_active)
	end

	local is_update_local_active_info = false
	local arr = {}
	local office_ids = xyd.tables.senpaiDressGroupTable:getIDs()

	for i in pairs(office_ids) do
		local version = xyd.tables.senpaiDressGroupTable:getVersion(office_ids[i])

		if local_dress_save_office_active[tostring(office_ids[i])] and tonumber(local_dress_save_office_active[tostring(office_ids[i])]) == version then
			local params = {
				office_id = office_ids[i],
				data = {
					name = xyd.tables.senpaiDressGroupTextTable:getName(office_ids[i]),
					style_ids = xyd.tables.senpaiDressGroupTable:getStyleUnit(office_ids[i])
				}
			}

			table.insert(arr, params)
		else
			local dress_ids = xyd.tables.senpaiDressGroupTable:getUnit(office_ids[i])
			local is_active = true

			for j in pairs(dress_ids) do
				if dress_ids[j] ~= 0 and #xyd.models.dress:getHasStyles(dress_ids[j]) == 0 then
					is_active = false

					break
				end
			end

			if is_active then
				local params = {
					office_id = office_ids[i],
					data = {
						name = xyd.tables.senpaiDressGroupTextTable:getName(office_ids[i]),
						style_ids = xyd.tables.senpaiDressGroupTable:getStyleUnit(office_ids[i])
					}
				}

				table.insert(arr, params)

				local_dress_save_office_active[tostring(office_ids[i])] = version
				is_update_local_active_info = true
			end
		end
	end

	if is_update_local_active_info then
		xyd.db.misc:setValue({
			key = "local_dress_save_office_active_new",
			value = JSON.encode(local_dress_save_office_active)
		})
	end

	if #arr > 0 then
		self.noneCon:SetActive(false)
	else
		self.noneCon:SetActive(true)
	end

	self:waitForFrame(1, function ()
		self.firstWrapContent:setInfos(arr, {})
		self:waitForFrame(1, function ()
			self.firstScroller_UIScrollView:ResetPosition()
		end)
	end)
end

function DressSuitWindow:initPageTwo()
	local arr = {}
	local max_dress_style = xyd.tables.miscTable:getNumber("max_dress_style", "value")
	local save_yet_styles = xyd.models.dress:getSavedStyles()

	for i = 1, max_dress_style do
		local params = {
			index = i,
			data = save_yet_styles[i]
		}

		table.insert(arr, params)
	end

	self:waitForFrame(1, function ()
		self.secondWrapContent:setInfos(arr, {})
		self:waitForFrame(1, function ()
			self.secondSAcroller_UIScrollView:ResetPosition()
		end)
	end)
end

function DressSuitWindow:dressSuitSave()
	local arr = {}
	local max_dress_style = xyd.tables.miscTable:getNumber("max_dress_style", "value")
	local save_yet_styles = xyd.models.dress:getSavedStyles()

	for i = 1, max_dress_style do
		local params = {
			index = i,
			data = save_yet_styles[i]
		}

		table.insert(arr, params)
	end

	self:waitForFrame(1, function ()
		self.secondWrapContent:setInfos(arr, {
			keepPosition = true
		})
	end)
end

function DressSuitWindow:dressSuitRemove()
	local arr = {}
	local max_dress_style = xyd.tables.miscTable:getNumber("max_dress_style", "value")
	local save_yet_styles = xyd.models.dress:getSavedStyles()

	for i = 1, max_dress_style do
		local params = {
			index = i,
			data = save_yet_styles[i]
		}

		table.insert(arr, params)
	end

	self:waitForFrame(1, function ()
		self.secondWrapContent:setInfos(arr, {
			keepPosition = true
		})
	end)
end

function DressSuitWindow:willClose()
	DressSuitWindow.super.willClose(self)
	self.page1.gameObject:SetActive(false)
	self.page2.gameObject:SetActive(false)
end

function DressSuitOfficeItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.official_suit_item = self.go
	self.officialCon = self.official_suit_item:NodeByName("officialCon").gameObject
	self.labelName = self.officialCon:ComponentByName("labelName", typeof(UILabel))
	self.seeBtn = self.officialCon:NodeByName("seeBtn").gameObject
	self.seeBtn_button_label = self.seeBtn:ComponentByName("seeBtn_button_label", typeof(UILabel))
	self.applyBtn = self.officialCon:NodeByName("applyBtn").gameObject
	self.apply_button_label = self.applyBtn:ComponentByName("apply_button_label", typeof(UILabel))
	self.groupShow = self.official_suit_item:NodeByName("groupShow").gameObject
	self.addBg = self.groupShow:ComponentByName("addBg", typeof(UISprite))
	self.personCon = self.groupShow:NodeByName("personCon").gameObject
	self.personCon:GetComponent(typeof(UIWidget)).depth = self.parent.itemEffectDepth + 5
	self.parent.itemEffectDepth = self.parent.itemEffectDepth + 15
	self.seeBtn_button_label.text = __("CHECK_TEAM")
	self.apply_button_label.text = __("DRESS_CHANGE")
	UIEventListener.Get(self.applyBtn.gameObject).onClick = handler(self, self.applyBtnTouch)
	UIEventListener.Get(self.seeBtn.gameObject).onClick = handler(self, self.seeBtnTouch)
end

function DressSuitOfficeItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.office_id and self.office_id == info.office_id then
		return
	end

	self.info = info
	self.office_id = self.info.office_id
	self.labelName.text = self.info.data.name
	self.info = info

	if info.data then
		self.labelName.text = info.data.name

		if xyd.models.dress:isNewClipShaderOpen() then
			if not self.normalModel_ then
				self.normalModel_ = import("app.components.SenpaiModel").new(self.personCon)
			end

			self.normalModel_:setModelInfo({
				isNewClipShader = true,
				isNotCoverMaskTuxture = true,
				ids = info.data.style_ids,
				textureSize = Vector2(1, 385),
				pos = Vector3(0, -170, 0),
				uiPanel = self.parent.firstScroller_UIPanel
			})
		else
			if not self.normalModel_ then
				self.normalModel_ = import("app.components.SenpaiModel").new(self.personCon)
			end

			local show_ids = {}

			for i in pairs(info.data.style_ids) do
				if info.data.style_ids[i] and info.data.style_ids[i] > 0 then
					local pos = xyd.tables.senpaiDressStyleTable:getPos(info.data.style_ids[i])

					if pos ~= xyd.DressPosState.HEAD_ORNAMENTS and pos ~= xyd.DressPosState.OTHER_ORNAMENTS then
						table.insert(show_ids, info.data.style_ids[i])
					end
				end
			end

			self.normalModel_:setModelInfo({
				isNewClipShader = false,
				isNotCoverMaskTuxture = true,
				ids = show_ids,
				textureSize = Vector2(1, 385),
				pos = Vector3(0, -170, 0),
				uiPanel = self.parent.firstScroller_UIPanel
			})
		end
	end
end

function DressSuitOfficeItem:applyBtnTouch()
	xyd.alert(xyd.AlertType.YES_NO, __("DRESS_SUIT_WINDOW_8", self.info.data.name), function (yes_no)
		if yes_no then
			local dress_main_wn = xyd.WindowManager.get():getWindow("dress_main_window")

			if dress_main_wn then
				if dress_main_wn:getIsEdit() then
					dress_main_wn:updateEditShowItemsGroup(self.info.data.style_ids)
				else
					dress_main_wn:updateEditShowItemsGroup(self.info.data.style_ids, true)
				end
			end

			self.parent:close()
		end
	end)
end

function DressSuitOfficeItem:seeBtnTouch()
	xyd.WindowManager.get():openWindow("dress_check_office_window", {
		office_id = self.office_id
	})
end

function DressSuitSelfItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.self_suit_item = self.go
	self.selfCon = self.self_suit_item:NodeByName("selfCon").gameObject
	self.labelName = self.selfCon:ComponentByName("labelName", typeof(UILabel))
	self.btnEditName = self.selfCon:NodeByName("btnEditName").gameObject
	self.btnDel = self.selfCon:NodeByName("btnDel").gameObject
	self.btnDel_button_label = self.btnDel:ComponentByName("btnDel_button_label", typeof(UILabel))
	self.btnSave = self.selfCon:NodeByName("btnSave").gameObject
	self.btnSave_button_label = self.btnSave:ComponentByName("btnSave_button_label", typeof(UILabel))
	self.btnApply = self.selfCon:NodeByName("btnApply").gameObject
	self.btnApply_button_label = self.btnApply:ComponentByName("btnApply_button_label", typeof(UILabel))
	self.groupShow = self.self_suit_item:NodeByName("groupShow").gameObject
	self.addBtn = self.groupShow:NodeByName("addBtn").gameObject
	self.addBg = self.groupShow:ComponentByName("addBg", typeof(UISprite))
	self.personCon = self.groupShow:NodeByName("personCon").gameObject
	self.personCon:GetComponent(typeof(UIWidget)).depth = self.parent.itemEffectDepth + 5
	self.parent.itemEffectDepth = self.parent.itemEffectDepth + 15
	self.btnDel_button_label.text = __("HOUSE_TEXT_17")
	self.btnSave_button_label.text = __("HOUSE_TEXT_18")
	self.btnApply_button_label.text = __("DRESS_CHANGE")
	UIEventListener.Get(self.addBtn.gameObject).onClick = handler(self, self.addNewTouch)
	UIEventListener.Get(self.btnEditName.gameObject).onClick = handler(self, self.editNameTouch)
	UIEventListener.Get(self.btnSave.gameObject).onClick = handler(self, self.btnSaveTouch)
	UIEventListener.Get(self.btnDel.gameObject).onClick = handler(self, self.btnDelTouch)
	UIEventListener.Get(self.btnApply.gameObject).onClick = handler(self, self.btnApplyTouch)
end

function DressSuitSelfItem:update(index, info)
	dump(info, "放入的數據==========")

	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.index = info.index
	self.info = info

	if info.data then
		self.selfCon:SetActive(true)

		self.labelName.text = info.data.name

		if xyd.models.dress:isNewClipShaderOpen() then
			if not self.normalModel_ then
				self.normalModel_ = import("app.components.SenpaiModel").new(self.personCon)
			end

			self.normalModel_:setModelInfo({
				isNewClipShader = true,
				isNotCoverMaskTuxture = true,
				ids = info.data.style_ids,
				textureSize = Vector2(1, 385),
				pos = Vector3(0, -170, 0),
				uiPanel = self.parent.secondSAcroller_UIPanel
			})
		else
			if not self.normalModel_ then
				self.normalModel_ = import("app.components.SenpaiModel").new(self.personCon)
			end

			local show_ids = {}

			for i in pairs(info.data.style_ids) do
				if info.data.style_ids[i] and info.data.style_ids[i] > 0 then
					local pos = xyd.tables.senpaiDressStyleTable:getPos(info.data.style_ids[i])

					if pos ~= xyd.DressPosState.HEAD_ORNAMENTS and pos ~= xyd.DressPosState.OTHER_ORNAMENTS then
						table.insert(show_ids, info.data.style_ids[i])
					end
				end
			end

			self.normalModel_:setModelInfo({
				isNewClipShader = false,
				isNotCoverMaskTuxture = true,
				ids = show_ids,
				textureSize = Vector2(1, 385),
				pos = Vector3(0, -170, 0),
				uiPanel = self.parent.secondSAcroller_UIPanel
			})
		end

		self.addBtn.gameObject:SetActive(false)
		self.personCon.gameObject:SetActive(true)
	else
		self.selfCon:SetActive(false)
		self.addBtn.gameObject:SetActive(true)
		self.personCon.gameObject:SetActive(false)
	end
end

function DressSuitSelfItem:addNewTouch()
	local params = {
		index = #xyd.models.dress:getSavedStyles() + 1,
		styles = xyd.models.dress:getEquipedStyles()
	}
	local dress_main_wn = xyd.WindowManager.get():getWindow("dress_main_window")

	if dress_main_wn and dress_main_wn:getIsEdit() then
		params.styles = dress_main_wn:getShowItemStyles()
	end

	xyd.WindowManager.get():openWindow("dress_new_suit_window", params)
end

function DressSuitSelfItem:editNameTouch()
	xyd.WindowManager.get():openWindow("dress_new_suit_window", {
		old_name = self.info.data.name,
		index = self.index,
		styles = self.info.data.style_ids
	})
end

function DressSuitSelfItem:btnSaveTouch()
	local body_styles = xyd.models.dress:getEquipedStyles()
	local dress_main_wn = xyd.WindowManager.get():getWindow("dress_main_window")

	if dress_main_wn and dress_main_wn:getIsEdit() then
		body_styles = dress_main_wn:getShowItemStyles()
	end

	local isSame = true

	for i = 1, #body_styles do
		if body_styles[i] ~= self.info.data.style_ids[i] then
			isSame = false
		end
	end

	if isSame then
		xyd.alertTips(__("DRESS_SUIT_WINDOW_5"))

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("DRESS_SUIT_WINDOW_7"), function (yes_no)
		if yes_no then
			local msg = messages_pb.dress_suit_save_req()
			msg.name = self.info.data.name

			for i in pairs(body_styles) do
				table.insert(msg.style_ids, body_styles[i])
			end

			msg.index = self.index

			xyd.Backend.get():request(xyd.mid.DRESS_SUIT_SAVE, msg)
		end
	end)
end

function DressSuitSelfItem:btnDelTouch()
	xyd.alert(xyd.AlertType.YES_NO, __("DRESS_SUIT_WINDOW_6", self.info.data.name), function (yes_no)
		if yes_no then
			local msg = messages_pb.dress_suit_remove_req()
			msg.index = self.index

			xyd.Backend.get():request(xyd.mid.DRESS_SUIT_REMOVE, msg)
		end
	end)
end

function DressSuitSelfItem:btnApplyTouch()
	xyd.alert(xyd.AlertType.YES_NO, __("DRESS_SUIT_WINDOW_8", self.info.data.name), function (yes_no)
		if yes_no then
			local dress_main_wn = xyd.WindowManager.get():getWindow("dress_main_window")

			if dress_main_wn then
				if dress_main_wn:getIsEdit() then
					dress_main_wn:updateEditShowItemsGroup(self.info.data.style_ids)
				else
					dress_main_wn:updateEditShowItemsGroup(self.info.data.style_ids, true)
				end
			end

			self.parent:close()
		end
	end)
end

return DressSuitWindow
