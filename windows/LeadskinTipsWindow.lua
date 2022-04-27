local BaseWindow = import(".BaseWindow")
local LeadskinTipsWindow = class("LeadskinTipsWindow", BaseWindow)

function LeadskinTipsWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.styleID = params.styleID
	self.is_can_rm = params.is_can_rm
	self.state = params.state
	self.entry_styleID = self.styleID
	self.pos = xyd.tables.senpaiDressStyleTable:getPos(self.styleID)
end

function LeadskinTipsWindow:initWindow()
	LeadskinTipsWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function LeadskinTipsWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.imgBg = groupAction:ComponentByName("imgBg", typeof(UISprite))
	self.labelName = groupAction:ComponentByName("labelName", typeof(UILabel))
	self.btnStyle = groupAction:NodeByName("btnStyle").gameObject
	self.groupSkin = groupAction:ComponentByName("groupSkin", typeof(UISprite))
	self.btnLeft = groupAction:NodeByName("btnLeft").gameObject
	self.btnLeftLabel = self.btnLeft:ComponentByName("button_label", typeof(UILabel))
	self.btnMid = groupAction:NodeByName("btnMid").gameObject
	self.btnMidLabel = self.btnMid:ComponentByName("button_label", typeof(UILabel))
	self.btnRight = groupAction:NodeByName("btnRight").gameObject
	self.btnRightLabel = self.btnRight:ComponentByName("button_label", typeof(UILabel))
	self.styleBtnCon = groupAction:NodeByName("styleBtnCon").gameObject
	self.btnStyle1 = self.styleBtnCon:NodeByName("btnStyle1").gameObject
	self.imgSelect1 = self.btnStyle1:ComponentByName("imgSelect", typeof(UISprite))
	self.imgUnselect1 = self.btnStyle1:ComponentByName("imgUnselect", typeof(UISprite))
	self.labelStyle1 = self.styleBtnCon:ComponentByName("labelStyle1", typeof(UILabel))
	self.btnStyle2 = self.styleBtnCon:NodeByName("btnStyle2").gameObject
	self.imgSelect2 = self.btnStyle2:ComponentByName("imgSelect", typeof(UISprite))
	self.imgUnselect2 = self.btnStyle2:ComponentByName("imgUnselect", typeof(UISprite))
	self.labelStyle2 = self.styleBtnCon:ComponentByName("labelStyle2", typeof(UILabel))
end

function LeadskinTipsWindow:initUIComponent()
	self.dress_id = xyd.tables.senpaiDressStyleTable:getDressId(self.styleID)

	self:updateText()

	self.all_styles = xyd.tables.senpaiDressTable:getStyles(self.dress_id)
	self.labelStyle1.text = __("PERSON_DRESS_MAIN_24", 1)
	self.labelStyle2.text = __("PERSON_DRESS_MAIN_24", 2)

	if self.all_styles and #self.all_styles > 1 then
		self.btnStyle.gameObject:SetActive(false)
		self.styleBtnCon.gameObject:SetActive(true)

		self.imgBg.height = 390

		self.labelName.gameObject:Y(161)
		self.groupSkin.gameObject:Y(60)
		self.btnStyle.gameObject:Y(149)
		self.btnLeft.gameObject:Y(-126)
		self.btnMid.gameObject:Y(-126)
		self.btnRight.gameObject:Y(-126)
		self:initExchage()
	else
		self.btnStyle.gameObject:SetActive(false)
		self.styleBtnCon.gameObject:SetActive(false)

		self.imgBg.height = 322

		self.labelName.gameObject:Y(131)
		self.groupSkin.gameObject:Y(23.5)
		self.btnStyle.gameObject:Y(123)
		self.btnLeft.gameObject:Y(-105)
		self.btnMid.gameObject:Y(-105)
		self.btnRight.gameObject:Y(-105)
	end

	self.btnLeftLabel.text = __("PERSON_DRESS_MAIN_26")
	self.btnRightLabel.text = __("SURE")

	if self.state == 1 then
		self.btnMid.gameObject:SetActive(false)
		self.btnLeft.gameObject:SetActive(true)
		self.btnRight.gameObject:SetActive(true)
	elseif self.state == 2 then
		self.btnMid.gameObject:SetActive(true)
		self.btnLeft.gameObject:SetActive(false)
		self.btnRight.gameObject:SetActive(false)

		self.btnMidLabel.text = __("PERSON_DRESS_MAIN_27")
	elseif self.state == 3 then
		self.btnMid.gameObject:SetActive(true)
		self.btnLeft.gameObject:SetActive(false)
		self.btnRight.gameObject:SetActive(false)

		self.btnMidLabel.text = __("SURE")
	elseif self.state == 4 then
		self.btnMid.gameObject:SetActive(true)
		self.btnLeft.gameObject:SetActive(false)
		self.btnRight.gameObject:SetActive(false)

		self.btnMidLabel.text = __("PERSON_DRESS_MAIN_25")
	elseif self.state == 5 then
		self.btnMid.gameObject:SetActive(false)
		self.btnLeft.gameObject:SetActive(true)
		self.btnRight.gameObject:SetActive(true)

		self.btnRightLabel.text = __("PERSON_DRESS_MAIN_25")
	end

	self:updateImg()
end

function LeadskinTipsWindow:register()
	LeadskinTipsWindow.super.register(self)

	UIEventListener.Get(self.btnLeft.gameObject).onClick = function ()
		self.styleID = 0

		self:close()
	end

	UIEventListener.Get(self.btnRight.gameObject).onClick = function ()
		if self.state == 5 then
			self.entry_styleID = -1
		end

		self:close()
	end

	UIEventListener.Get(self.btnMid.gameObject).onClick = function ()
		if self.state == 2 then
			self.entry_styleID = -1
		end

		if self.state == 4 then
			self.entry_styleID = -1
		end

		self:close()
	end

	UIEventListener.Get(self.btnStyle.gameObject).onClick = function ()
		local index = 1

		for i in pairs(self.all_styles) do
			if self.all_styles[i] == self.styleID then
				index = i

				break
			end
		end

		xyd.WindowManager.get():openWindow("leadskin_style_exchange_window", {
			isOnlyPreview = true,
			styleIndex = index,
			styleID = self.styleID
		})
	end

	self:cleanDefaultBgClick()
	self:setDefaultBgClick(function ()
		self.styleID = self.entry_styleID

		self:close()
	end)
	self.eventProxy_:addEventListener(xyd.event.DRESS_UNLOCK_STYLE, handler(self, self.dressUnlockStyleBack))

	for i = 1, 2 do
		UIEventListener.Get(self["btnStyle" .. i]).onClick = function ()
			self:onClickBtn(i)
		end
	end
end

function LeadskinTipsWindow:onClickEscBack()
	self.styleID = self.entry_styleID

	self:close()
end

function LeadskinTipsWindow:updateImg()
	local image = xyd.tables.senpaiDressStyleTable:getImage(self.styleID)

	xyd.setUISpriteAsync(self.groupSkin, nil, image, nil, , )
end

function LeadskinTipsWindow:getDressIdsByPos(pos)
	local ids = xyd.models.dress:getHasDressIds(pos)
	local not_self_arr = {}

	for i in pairs(ids) do
		if ids[i] ~= self.dress_id then
			table.insert(not_self_arr, ids[i])
		end
	end

	return not_self_arr
end

function LeadskinTipsWindow:updateStyleOnly(sytle_id)
	self.styleID = sytle_id
	self.dress_id = xyd.tables.senpaiDressStyleTable:getDressId(self.styleID)

	self:updateText()
	self:updateImg()

	local dress_main_wn = xyd.WindowManager.get():getWindow("dress_main_window")

	if dress_main_wn and self.dress_id == xyd.tables.senpaiDressStyleTable:getDressId(dress_main_wn:getShowItemStyles()[self.pos]) then
		self:close()
	end
end

function LeadskinTipsWindow:willClose()
	LeadskinTipsWindow.super.willClose(self)

	if self.styleID ~= self.entry_styleID then
		local dress_main_wn = xyd.WindowManager.get():getWindow("dress_main_window")

		if dress_main_wn then
			if self.state == 4 or self.state == 5 then
				dress_main_wn:updateEditShowItems(self.styleID, self.pos, true)
			else
				dress_main_wn:updateEditShowItems(self.styleID, self.pos)
			end
		end
	end
end

function LeadskinTipsWindow:updateText()
	local dress_item_name_id = xyd.tables.senpaiDressTable:getItems(self.dress_id)[1]
	self.labelName.text = xyd.tables.itemTable:getName(dress_item_name_id)
	self.labelName.color = xyd.getQualityColor(xyd.tables.senpaiDressItemTable:getQlt(dress_item_name_id))
end

function LeadskinTipsWindow:initExchage()
	local index = 1

	for i in pairs(self.all_styles) do
		if self.all_styles[i] == self.styleID then
			index = i

			break
		end
	end

	self.styleIndex = index

	if #self.all_styles == 1 then
		self.btnStyle2:SetActive(false)
		self.labelStyle2.gameObject:SetActive(false)
		self.btnStyle1:X(-41)
		self.labelStyle1.gameObject:X(-6)
	end

	local has_ids = xyd.models.dress:getHasStyles(self.dress_id)

	if self.isOnlyPreview == false then
		for i = 1, #self.all_styles do
			local check_id = self.all_styles[i]

			if xyd.arrayIndexOf(has_ids, check_id) == -1 then
				table.insert(self.lock_ids, i)
			end
		end
	else
		self.lock_ids = {}
	end

	self:setBtn()
end

function LeadskinTipsWindow:setBtn()
	if self.styleIndex == 1 then
		self.imgSelect1:SetActive(true)
		self.imgUnselect1:SetActive(false)
		self.imgSelect2:SetActive(false)
		self.imgUnselect2:SetActive(true)
	else
		self.imgSelect1:SetActive(false)
		self.imgUnselect1:SetActive(true)
		self.imgSelect2:SetActive(true)
		self.imgUnselect2:SetActive(false)
	end
end

function LeadskinTipsWindow:onClickBtn(styleIndex)
	if xyd.arrayIndexOf(self.lock_ids, styleIndex) ~= -1 then
		local cost = xyd.tables.senpaiDressStyleTable:getCost(self.all_styles[styleIndex])

		if cost and #cost > 0 then
			local item_name = xyd.tables.itemTable:getName(cost[1])
			local text = __("DRESS_UNLOCK_STYLE_TIPS", cost[2], item_name)

			xyd.alert(xyd.AlertType.YES_NO, text, function (yes_no)
				if yes_no then
					if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
						xyd.alertTips(__("NOT_ENOUGH", item_name))
					else
						xyd.models.dress:sendUnlockStyle(self.all_styles[styleIndex])
					end
				end
			end)

			return
		end

		xyd.alertTips(__("CAMPAIGN_LOCKING"))
	end

	local dressEditStyles = {
		0,
		0,
		0,
		0,
		0
	}
	local dressMainWd = xyd.WindowManager.get():getWindow("dress_main_window")

	if dressMainWd then
		dressEditStyles = dressMainWd:getShowItemStyles()
	end

	if xyd.models.dress:checkIsCollide(self.all_styles[styleIndex], dressEditStyles) then
		xyd.models.dress:showCollideTips(function ()
			self.styleIndex = styleIndex

			self:setImg()
			self:setBtn()
		end)
	else
		self.styleIndex = styleIndex

		self:setImg()
		self:setBtn()
	end
end

function LeadskinTipsWindow:setImg()
	self.styleID = self.all_styles[self.styleIndex]

	self:updateImg()
end

function LeadskinTipsWindow:dressUnlockStyleBack(event)
end

return LeadskinTipsWindow
