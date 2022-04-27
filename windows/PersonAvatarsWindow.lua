local ItemRender = class("ItemRender")
local PlayerIcon = import("app.components.PlayerIcon")

function ItemRender:ctor(go, parent)
	self.go = go
	self.heroIcon = PlayerIcon.new(go, parent.renderPanel)

	self.heroIcon:setDragScrollView(parent.scroller_)
end

function ItemRender:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.infonow = info

	if not self.infonow then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.go:SetActive(true)

	local type_ = xyd.tables.itemTable:getType(self.infonow)
	local reseTinfo = {}

	if type_ == xyd.ItemType.AVATAR_FRAME then
		local num = xyd.models.backpack:getItemNumByID(self.infonow)
		local isActiveFrameEffect_ = false

		if num > 0 then
			isActiveFrameEffect_ = true
		end

		reseTinfo = {
			avatar_frame_id = self.infonow,
			callback = handler(self, self.onTouchAvatar),
			isActiveFrameEffect = isActiveFrameEffect_
		}
	else
		reseTinfo = {
			avatarID = self.infonow,
			callback = handler(self, self.onTouchAvatar)
		}
	end

	self.heroIcon:setInfo(reseTinfo)

	if type_ == xyd.ItemType.AVATAR_FRAME then
		local num = xyd.models.backpack:getItemNumByID(self.infonow)

		if num > 0 then
			self.heroIcon:setLocked(false)
			self.heroIcon:setGreyFarme(false)
			self.heroIcon:setFrameEffectVisible(true)
		else
			self.heroIcon:setLocked(true)
			self.heroIcon:setGreyFarme(true)
			self.heroIcon:setFrameEffectVisible(false)
		end
	else
		self.heroIcon:setLocked(false)
		self.heroIcon:setGreyFarme(false)
	end

	local skinAvatarType = xyd.tables.itemTable:getType(self.infonow)
	local skinAvatarID = -999

	if xyd.ItemType.SKIN == skinAvatarType then
		skinAvatarID = xyd.tables.itemTable:getSkinID(self.infonow)
	end

	local wnd = xyd.WindowManager.get():getWindow("person_avatars_window")

	if wnd and wnd.curSelectID_ == self.infonow or wnd and wnd.curSelectID_ == skinAvatarID then
		self:setSelect(true)

		wnd.lastSelectAvatar = self
	else
		self:setSelect(false)

		if type_ == xyd.ItemType.AVATAR_FRAME and wnd.curSelectID_ == 0 and self.infonow == 8007 then
			self:setSelect(true)
		end
	end

	local newAvatars = xyd.models.backpack:getNewAvatars()
	local searchIndex = -1

	for k, v in pairs(newAvatars) do
		if v == self.infonow then
			searchIndex = k

			break
		end
	end

	if searchIndex > -1 then
		self.heroIcon:setRedIcon(true)
	else
		self.heroIcon:setRedIcon(false)
	end
end

function ItemRender:setSelect(flag)
	self.heroIcon:setSelected(flag)
end

function ItemRender:getGameObject()
	return self.go
end

function ItemRender:onTouchAvatar()
	local wnd = xyd.WindowManager.get():getWindow("person_avatars_window")

	if wnd and wnd.curSelectID_ ~= self.infonow then
		wnd:changeSelectItem(self.infonow)
		self:setSelect(true)

		if wnd.lastSelectAvatar ~= nil and wnd.lastSelectAvatar.infonow ~= self.infonow then
			wnd.lastSelectAvatar:setSelect(false)
		end

		wnd.lastSelectAvatar = self
	end
end

local BaseWindow = import(".BaseWindow")
local PersonAvatarsWindow = class("PersonAvatarsWindow", BaseWindow)

function PersonAvatarsWindow:ctor(name, params)
	PersonAvatarsWindow.super.ctor(self, name, params)

	self.isChangeSignature_ = false
	self.signature_ = ""
	self.selfPlayer = xyd.models.selfPlayer
	self.backpack = xyd.models.backpack
	self.curSelect = 1
	self.curSelectID_ = -1
	self.pos = {
		"left",
		"right"
	}
	self.curSubSelect = 1
	self.curSelectAvatar = nil
	self.lastSelectAvatar = nil
end

function PersonAvatarsWindow:initWindow()
	PersonAvatarsWindow.super.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self:layout()
	self:updateLayout()
end

local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function PersonAvatarsWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("e:Group").gameObject
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.labelTitle_ = groupMain:ComponentByName("labelTitle_", typeof(UILabel))
	self.groupLabel = groupMain:NodeByName("e:GroupLabel").gameObject
	self.btnChange_label = self.groupLabel:NodeByName("btnChange_"):ComponentByName("button_label", typeof(UILabel))
	self.btnChange_img = self.groupLabel:NodeByName("btnChange_").gameObject
	local playIconNode = self.groupLabel:NodeByName("playerIcon_").gameObject
	self.playerIcon_ = PlayerIcon.new(playIconNode)
	self.labelTips_ = self.groupLabel:ComponentByName("labelTips_", typeof(UILabel))
	self.labelName_ = self.groupLabel:ComponentByName("labelName_", typeof(UILabel))
	local groupUP = groupMain:NodeByName("e:GroupUp")
	self.text1 = groupUP:NodeByName("group1"):ComponentByName("text1", typeof(UILabel))
	self.text2 = groupUP:NodeByName("group2"):ComponentByName("text2", typeof(UILabel))
	self.group1 = groupUP:NodeByName("group1").gameObject
	self.group2 = groupUP:NodeByName("group2").gameObject
	self.groupArr = {
		self.group1,
		self.group2
	}
	self.groupLabelImgArr = {
		groupUP:NodeByName("group1"):ComponentByName("img1", typeof(UISprite)),
		groupUP:NodeByName("group2"):ComponentByName("img2", typeof(UISprite))
	}
	self.groupTextArr = {
		self.text1,
		self.text2
	}
	local groupCenter = groupMain:NodeByName("e:GroupCenter")
	self.scroller_ = groupCenter:ComponentByName("scroller_", typeof(UIScrollView))
	self.scroller_uiPanel = groupCenter:ComponentByName("scroller_", typeof(UIPanel))
	self.renderPanel = self.scroller_uiPanel
	local maxDepth = XYDUtils.GetMaxTargetDepth(self.window_)
	self.scroller_uiPanel.depth = maxDepth + 1
	self.groupMain_cont = groupCenter:NodeByName("scroller_"):ComponentByName("groupMain_", typeof(MultiRowWrapContent))
	self.itemCell = winTrans:NodeByName("item").gameObject
	self.groupMain_ = FixedMultiWrapContent.new(self.scroller_, self.groupMain_cont, self.itemCell, ItemRender, self)
	self.labelNoneTips_ = groupCenter:NodeByName("groupNone_"):ComponentByName("labelNoneTips_", typeof(UILabel))
	self.groupNone_ = groupCenter:NodeByName("groupNone_").gameObject
	self.drag_ = groupCenter:ComponentByName("drag", typeof(UIWidget))
	self.drag_.depth = 3
	self.groupAvatarSelect = groupMain:NodeByName("groupAvatarSelect")
	self.btnHero_label = self.groupAvatarSelect:NodeByName("btnHero_"):ComponentByName("button_label", typeof(UILabel))
	self.btnHero_img = self.groupAvatarSelect:ComponentByName("btnHero_", typeof(UISprite))
	self.btnSpecial_label = self.groupAvatarSelect:NodeByName("btnSpecial_"):ComponentByName("button_label", typeof(UILabel))
	self.btnSpecial_img = self.groupAvatarSelect:ComponentByName("btnSpecial_", typeof(UISprite))
	self.filter = {}
	self.filterChosen = {}
	self.chosenGroup = 0
	self.filterGroup = self.groupAvatarSelect:NodeByName("filterGroup").gameObject

	for i = 1, 6 do
		self.filter[i] = self.filterGroup:NodeByName("group" .. i).gameObject
		self.filterChosen[i] = self.filter[i]:NodeByName("chosen").gameObject
		UIEventListener.Get(self.filter[i]).onClick = handler(self, function ()
			self:changeFilter(i)
		end)
	end
end

function PersonAvatarsWindow:layout()
	self.labelTitle_.text = __("PERSON_AVATAR_LIST")
	self.text1.text = __("AVATAR_TEXT_1")
	self.text2.text = __("AVATAR_TEXT_2")
	self.btnHero_label.text = __("PARTNER")
	self.btnSpecial_label.text = __("PERSON_SPECIAL")
	self.btnChange_label.text = __("PERSON_CHANGE")
	local tempAvatarID = xyd.models.selfPlayer:getAvatarID()

	self:changeSelectItem(tempAvatarID)
end

function PersonAvatarsWindow:registerEvent()
	PersonAvatarsWindow.super.register(self)

	for i = 1, 2 do
		self:AddLabelOnClick(i)
	end

	UIEventListener.Get(self.btnHero_img.gameObject).onClick = handler(self, self.onHeroTouch)
	UIEventListener.Get(self.btnSpecial_img.gameObject).onClick = handler(self, self.onSpecialTouch)
	UIEventListener.Get(self.btnChange_img.gameObject).onClick = handler(self, self.onChangeTouch)
end

function PersonAvatarsWindow:AddLabelOnClick(i)
	UIEventListener.Get(self.groupArr[i]).onClick = handler(self, function ()
		if self.curSelect == i then
			return
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

		self.curSelect = i

		if i == 2 then
			self.curSelectID_ = xyd.models.selfPlayer:getAvatarFrameID()

			self.filterGroup:SetActive(false)
		else
			self.curSelectID_ = xyd.models.selfPlayer:getAvatarID()

			if self.curSubSelect == 1 then
				self.filterGroup:SetActive(true)
			end
		end

		self.is_change_nav = true

		self:updateLayout()
	end)
end

function PersonAvatarsWindow:updateLayout()
	self:setButtonState()
	self:changeSelectItem(self.curSelectID_)
	self:initData()
end

function PersonAvatarsWindow:onHeroTouch()
	self.curSubSelect = 1

	self.filterGroup:SetActive(true)
	self:updateLayout()
end

function PersonAvatarsWindow:onSpecialTouch()
	self.curSubSelect = 2

	self.filterGroup:SetActive(false)
	self:updateLayout()
end

function PersonAvatarsWindow:onChangeTouch()
	if self.curSelect == 1 then
		xyd.models.selfPlayer:changeAvatar(self.curSelectID_)

		if self.save_last_avatarFrameID then
			xyd.models.selfPlayer:changeAvatarFrame(self.save_last_avatarFrameID)
		end
	else
		if self.curSelectID_ == 0 then
			self.curSelectID_ = 8007
		end

		xyd.models.selfPlayer:changeAvatarFrame(self.curSelectID_)

		if self.save_last_avatarID then
			xyd.models.selfPlayer:changeAvatar(self.save_last_avatarID)
		end
	end

	xyd.WindowManager.get():closeWindow("person_avatars_window")
end

function PersonAvatarsWindow:changeSelectItem(itemID)
	if itemID == 0 then
		itemID = 8007
	end

	local type_ = xyd.tables.itemTable:getType(itemID)
	local avatarID = xyd.models.selfPlayer:getAvatarID()
	local avatarFrameID = xyd.models.selfPlayer:getAvatarFrameID()

	if itemID > 0 then
		if type_ == xyd.ItemType.AVATAR_FRAME then
			avatarFrameID = itemID
		else
			avatarID = itemID
		end
	end

	self.curSelectID_ = itemID
	local textID = itemID

	if itemID > 0 then
		if self.curSelect == 1 then
			if type_ ~= xyd.ItemType.AVATAR_FRAME then
				if self.save_last_avatarFrameID then
					avatarFrameID = self.save_last_avatarFrameID
				end

				if self.is_change_nav then
					if self.save_last_avatarID then
						avatarID = self.save_last_avatarID
					end

					self.is_change_nav = false
					self.curSelectID_ = avatarID
					textID = avatarID
				else
					self.save_last_avatarID = itemID
				end
			end
		elseif type_ == xyd.ItemType.AVATAR_FRAME then
			if self.save_last_avatarID then
				avatarID = self.save_last_avatarID
			end

			if self.is_change_nav then
				if self.save_last_avatarFrameID then
					avatarFrameID = self.save_last_avatarFrameID
				end

				self.is_change_nav = false
				self.curSelectID_ = avatarFrameID
				textID = avatarFrameID
			elseif xyd.models.backpack:getItemNumByID(itemID) > 0 then
				self.save_last_avatarFrameID = itemID
			else
				local default = xyd.models.selfPlayer:getAvatarFrameID()

				if default == 0 then
					default = 8007
				end

				self.save_last_avatarFrameID = default
			end
		end
	end

	local info = {
		noClick = true,
		avatarID = avatarID,
		avatar_frame_id = avatarFrameID,
		renderPanel = self.window_:GetComponent(typeof(UIPanel))
	}

	self.playerIcon_:setInfo(info)

	if textID == 0 then
		textID = 8007
	end

	self.labelTips_.text = xyd.tables.itemTable:getDesc(textID)
	self.labelName_.text = xyd.tables.itemTable:getName(textID)

	self:showSelectItem()
end

function PersonAvatarsWindow:showSelectItem()
	local itemID = self.curSelectID_

	if self.curSelect == 2 then
		if xyd.models.backpack:getItemNumByID(itemID) > 0 then
			self.btnChange_label:SetActive(true)
			self.btnChange_label.parent:SetActive(true)
			self.labelTips_:SetActive(false)
		else
			self.btnChange_label:SetActive(false)
			self.btnChange_label.parent:SetActive(false)
			self.labelTips_:SetActive(true)
		end
	else
		self.btnChange_label:SetActive(true)
		self.btnChange_label.parent:SetActive(true)
	end

	XYDCo.WaitForTime(0.1, function ()
		if not self.stage then
			return
		end

		for i = 0, self.groupMain_.numChildren do
			local child = self.groupMain_:getChildAt(i)

			if child.data == itemID then
				child:setSelect(true)
			else
				child:setSelect(false)
			end
		end
	end, "")
end

function PersonAvatarsWindow:setButtonState()
	for i = 1, 2 do
		if i == self.curSelect then
			xyd.setUISpriteAsync(self.groupLabelImgArr[i], nil, "nav_btn_blue_" .. tostring(self.pos[i]), nil, )

			self.groupTextArr[i].color = Color.New2(4294967295.0)
			self.groupTextArr[i].effectColor = Color.New2(1012112383)
		else
			xyd.setUISpriteAsync(self.groupLabelImgArr[i], nil, "nav_btn_white_" .. tostring(self.pos[i]), nil, )

			self.groupTextArr[i].color = Color.New2(1012112383)
			self.groupTextArr[i].effectColor = Color.New2(4294967295.0)
		end
	end

	local groupAvatarSelectActive = false
	groupAvatarSelectActive = self.curSelect == 1 and true or false

	self.groupAvatarSelect:SetActive(groupAvatarSelectActive)

	if self.curSelect == 1 then
		self.scroller_uiPanel:SetRect(330, -231, 660, 462)
	else
		self.scroller_uiPanel:SetRect(330, -264.5, 660, 529)
	end

	if self.curSubSelect == 1 then
		xyd.setUISpriteAsync(self.btnHero_img, nil, "emotion_choose_btn", nil, )

		self.btnHero_label.color = Color.New2(4294967295.0)
		self.btnHero_label.effectColor = Color.New2(1012112383)

		xyd.setUISpriteAsync(self.btnSpecial_img, nil, "white_btn_0", nil, )

		self.btnSpecial_label.color = Color.New2(960513791)
		self.btnSpecial_label.effectColor = Color.New2(4294967295.0)
	else
		xyd.setUISpriteAsync(self.btnHero_img, nil, "white_btn_0", nil, )

		self.btnHero_label.color = Color.New2(960513791)
		self.btnHero_label.effectColor = Color.New2(4294967295.0)

		xyd.setUISpriteAsync(self.btnSpecial_img, nil, "emotion_choose_btn", nil, )

		self.btnSpecial_label.color = Color.New2(4294967295.0)
		self.btnSpecial_label.effectColor = Color.New2(1012112383)
	end

	if self.curSelect == 1 then
		self.labelNoneTips_.text = __("NOT_HAVE_AVATAR")
	else
		self.labelNoneTips_.text = __("NOT_HAVE_AVATAR_FRAME")
	end

	self.labelTips_:SetActive(false)
end

function PersonAvatarsWindow:willClose()
	BaseWindow.willClose(self)
	self.backpack:clearNewAvatars()
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.SKINDETAILWINDOW_CHOICEBUYSKIN
	})
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.NEW_AVATARS,
		params = {}
	})
end

function PersonAvatarsWindow:changeFilter(chosenGroup)
	if self.chosenGroup == chosenGroup then
		self.chosenGroup = 0
	else
		self.chosenGroup = chosenGroup
	end

	for k, v in ipairs(self.filterChosen) do
		if k == self.chosenGroup then
			v:SetActive(true)
		else
			v:SetActive(false)
		end
	end

	self:updateLayout()
end

function PersonAvatarsWindow:initData()
	local data = {}

	if self.curSelect == 1 then
		data = xyd.models.backpack:getAvatars()
		data = self:filterAvatars(data)
		data = self:filterAvatarsByGroup(data)

		self:sortAvatars(data)
	else
		data = xyd.tables.itemTable:getItemListByType(xyd.ItemType.AVATAR_FRAME) or {}

		table.sort(data)

		local index = -1

		for k, v in pairs(data) do
			if v == 8007 then
				index = k

				break
			end
		end

		if index > 0 then
			table.remove(data, index)
		end

		table.insert(data, 1, 8007)

		local hasFrameTable = {}
		local noHasFrameTable = {}

		table.insert(hasFrameTable, 8007)

		for k, v in pairs(data) do
			local collectionId = xyd.tables.itemTable:getCollectionId(v)
			local isCanShow = true

			if v == 8007 or not collectionId or collectionId == 0 then
				isCanShow = false
			end

			if isCanShow and collectionId and collectionId > 0 then
				local showTime = xyd.tables.collectionTable:getShowTime(collectionId)

				if showTime and xyd.getServerTime() < showTime then
					isCanShow = false
				end
			end

			if isCanShow then
				if xyd.models.backpack:getItemNumByID(v) > 0 then
					table.insert(hasFrameTable, v)
				else
					table.insert(noHasFrameTable, v)
				end
			end
		end

		for k, v in pairs(noHasFrameTable) do
			table.insert(hasFrameTable, v)
		end

		data = hasFrameTable
	end

	if #data == 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end

	self.groupMain_:setInfos(data, {})
end

function PersonAvatarsWindow:filterAvatars(avatars)
	local tmpAvatars = {}

	for i = 1, table.getn(avatars) do
		local type = xyd.tables.itemTable:getType(avatars[i])

		if type == xyd.ItemType.HERO and self.curSubSelect == 1 then
			table.insert(tmpAvatars, avatars[i])
		end

		if type ~= xyd.ItemType.HERO and self.curSubSelect ~= 1 then
			table.insert(tmpAvatars, avatars[i])
		end
	end

	return tmpAvatars
end

function PersonAvatarsWindow:filterAvatarsByGroup(avatars)
	if self.chosenGroup == 0 or self.curSubSelect ~= 1 then
		return avatars
	end

	local tmpAvatars = {}

	for i = 1, table.getn(avatars) do
		local group = xyd.tables.partnerTable:getGroup(avatars[i])

		if group == self.chosenGroup then
			table.insert(tmpAvatars, avatars[i])
		end
	end

	return tmpAvatars
end

function PersonAvatarsWindow:sortAvatars(avatars)
	local newAvatars = self.backpack:getNewAvatars()

	if self.curSelect == 1 then
		table.sort(avatars, function (a, b)
			local index = -1

			for k, v in pairs(newAvatars) do
				if v == a then
					index = k

					break
				end
			end

			local aVal = index > -1 and 1000 or 0
			local aType_ = xyd.tables.itemTable:getType(a)

			if aType_ == xyd.ItemType.AVATAR then
				aVal = aVal + 100
			elseif aType_ == xyd.ItemType.SKIN then
				aVal = aVal - 100
			end

			local index2 = -1

			for k, v in pairs(newAvatars) do
				if v == b then
					index2 = k

					break
				end
			end

			local bVal = index2 > -1 and 1000 or 0
			local bType_ = xyd.tables.itemTable:getType(b)

			if bType_ == xyd.ItemType.AVATAR then
				bVal = bVal + 100
			elseif aType_ == xyd.ItemType.SKIN then
				bVal = bVal - 100
			end

			if b < a then
				aVal = aVal + 10
			elseif a < b then
				bVal = bVal + 10
			end

			return aVal > bVal
		end)
	else
		return table.sort(avatars)
	end
end

return PersonAvatarsWindow
