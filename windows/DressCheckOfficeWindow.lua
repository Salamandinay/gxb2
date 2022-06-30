local DressCheckOfficeWindow = class("DressCheckOfficeWindow", import(".BaseWindow"))

function DressCheckOfficeWindow:ctor(name, params)
	DressCheckOfficeWindow.super.ctor(self, name, params)

	self.office_id = params.office_id
	self.showALL = params.showALL
end

function DressCheckOfficeWindow:initWindow()
	self:getUIComponent()
	self:reSize()
	self:layout()
	self:registerEvent()
end

function DressCheckOfficeWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.allCon = self.groupAction:NodeByName("allCon").gameObject
	self.conBg = self.allCon:ComponentByName("conBg", typeof(UISprite))
	self.labelTitle = self.allCon:ComponentByName("labelTitle", typeof(UILabel))
	self.posRoot = self.allCon:NodeByName("posRoot").gameObject

	for i = 1, 5 do
		self["dressPos" .. i] = self.posRoot:NodeByName("dressPos" .. i).gameObject
		self["dressPosBorder" .. i] = self["dressPos" .. i]:ComponentByName("dressPosBorder" .. i, typeof(UISprite))
		self["dressPosBg" .. i] = self["dressPos" .. i]:ComponentByName("dressPosBg" .. i, typeof(UISprite))
		self["dressPosIcon" .. i] = self["dressPos" .. i]:ComponentByName("dressPosIcon" .. i, typeof(UIWidget))
		self["dressName" .. i] = self["dressPos" .. i]:ComponentByName("dressName" .. i, typeof(UILabel))
	end

	self.personCon = self.posRoot:NodeByName("personCon").gameObject
	self.personBottom = self.personCon:ComponentByName("personBottom", typeof(UISprite))
	self.personEffect = self.personCon:NodeByName("personEffect").gameObject
	self.closeBtn = self.allCon:NodeByName("closeBtn").gameObject
	self.nameCon = self.allCon:NodeByName("nameCon").gameObject
	self.startImg = self.nameCon:ComponentByName("startImg", typeof(UISprite))
	self.suitLabel = self.nameCon:ComponentByName("suitLabel", typeof(UILabel))
	self.suitName = self.nameCon:ComponentByName("suitName", typeof(UILabel))
	self.itemCon = self.allCon:NodeByName("itemCon").gameObject
	self.itemCon_UILayout = self.allCon:ComponentByName("itemCon", typeof(UILayout))
end

function DressCheckOfficeWindow:reSize()
end

function DressCheckOfficeWindow:layout()
	self.labelTitle.text = __("DRESS_CHECK_OFFICE_WINDOW_1")
	self.suitLabel.text = __("DRESS_CHECK_OFFICE_WINDOW_2")
	self.suitName.text = xyd.tables.senpaiDressGroupTextTable:getName(self.office_id)

	if self.suitName.height > 24 then
		self.suitName.alignment = NGUIText.Alignment.Center
		self.suitName.overflowMethod = UILabel.Overflow.ShrinkContent
		self.suitName.height = 108
	end

	self.default_style_ids = xyd.tables.senpaiDressGroupTable:getStyleUnit(self.office_id)
	local suit_name_dress_id = xyd.tables.senpaiDressStyleTable:getDressId(self.default_style_ids[1])
	local suite_name_dress_item_id = xyd.tables.senpaiDressTable:getItems(suit_name_dress_id)[1]

	xyd.labelQulityColor(self.suitName, suite_name_dress_item_id)

	for i = 1, 5 do
		local text_index = i + 3
		self["dressName" .. i].text = __("PERSON_DRESS_MAIN_" .. text_index)
		local styleId = self.default_style_ids[i]

		if styleId ~= 0 then
			self:addItem(i, styleId)

			local dress_id = xyd.tables.senpaiDressStyleTable:getDressId(styleId)
			local dress_item_name_id = xyd.tables.senpaiDressTable:getItems(dress_id)[1]
			self["dressName" .. i].text = xyd.tables.itemTable:getName(dress_item_name_id)
		else
			self["dressPosBg" .. i].gameObject:SetActive(true)
		end
	end

	self.effect_arr = {}

	for i in pairs(self.default_style_ids) do
		if self.default_style_ids[i] ~= 0 then
			table.insert(self.effect_arr, self.default_style_ids[i])
		end
	end

	self.normalModel_ = import("app.components.SenpaiModel").new(self.personEffect)

	self.normalModel_:setModelInfo({
		ids = self.effect_arr
	})
	self:initEquipItem()
end

function DressCheckOfficeWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)

	for i = 1, 5 do
		UIEventListener.Get(self["dressPosBorder" .. i].gameObject).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		end
	end
end

function DressCheckOfficeWindow:addItem(i, styleId)
	local params = {
		showUpMax = true,
		uiRoot = self["dressPosIcon" .. i].gameObject,
		styleID = styleId
	}

	function params.callback()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		local style_id = self["item_" .. i]:getStyleID()
		local dress_id = xyd.tables.senpaiDressStyleTable:getDressId(style_id)
		local has_ids = xyd.tables.senpaiDressTable:getStyles(dress_id)

		if #has_ids <= 1 then
			xyd.alertTips(__("DRESS_CHECK_OFFICE_WINDOW_3"))

			return
		end

		local all_dress_styles = xyd.tables.senpaiDressTable:getStyles(dress_id)
		local index = 1

		for i in pairs(all_dress_styles) do
			if all_dress_styles[i] == style_id then
				index = i

				break
			end
		end

		xyd.WindowManager.get():openWindow("leadskin_style_exchange_window", {
			isOnlyPreview = true,
			styleIndex = index,
			styleID = style_id
		})
	end

	local item = xyd.getItemIcon(params, xyd.ItemIconType.DRESS_STYLE_ICON)
	local scale = 0.8244274809160306

	item:SetLocalScale(scale, scale, scale)

	self["item_" .. i] = item
end

function DressCheckOfficeWindow:initEquipItem()
	local equip_dress_ids = xyd.tables.senpaiDressGroupTable:getUnit(self.office_id)
	local has_item_ids = {}

	for i in pairs(equip_dress_ids) do
		local item_ids = xyd.tables.senpaiDressTable:getItems(equip_dress_ids[i])

		for j in pairs(item_ids) do
			if xyd.models.backpack:getItemNumByID(item_ids[j]) > 0 or self.showALL then
				table.insert(has_item_ids, item_ids[j])

				break
			end
		end
	end

	for i in pairs(has_item_ids) do
		local params = {
			itemID = has_item_ids[i],
			uiRoot = self.itemCon.gameObject
		}
		self.itemIcon = xyd.getItemIcon(params)
	end

	self.itemCon_UILayout:Reposition()
end

function DressCheckOfficeWindow:updateStyleOnly(styleId)
	local pos = xyd.tables.senpaiDressStyleTable:getPos(styleId)

	self["item_" .. pos]:setInfo({
		showUpMax = true,
		styleID = styleId
	})

	for i in pairs(self.effect_arr) do
		local pos_check = xyd.tables.senpaiDressStyleTable:getPos(self.effect_arr[i])

		if pos_check == pos then
			self.effect_arr[i] = styleId

			break
		end
	end

	self.normalModel_:setModelInfo({
		ids = self.effect_arr
	})
end

return DressCheckOfficeWindow
