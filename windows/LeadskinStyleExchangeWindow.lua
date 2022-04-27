local BaseWindow = import(".BaseWindow")
local LeadskinStyleExchangeWindow = class("LeadskinStyleExchangeWindow", BaseWindow)

function LeadskinStyleExchangeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.styleID = params.styleID
	self.styleIndex = params.styleIndex
	self.choiceStyle = self.styleID
	self.lock_ids = {}
	self.mainWin_ = params.window

	if params.isOnlyPreview ~= nil then
		self.isOnlyPreview = params.isOnlyPreview
	else
		self.isOnlyPreview = false
	end
end

function LeadskinStyleExchangeWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.imgSkin = groupAction:ComponentByName("imgSkin", typeof(UISprite))
	self.btnStyle1 = groupAction:NodeByName("btnStyle1").gameObject
	self.imgSelect1 = self.btnStyle1:ComponentByName("imgSelect", typeof(UISprite))
	self.imgUnselect1 = self.btnStyle1:ComponentByName("imgUnselect", typeof(UISprite))
	self.labelStyle1 = groupAction:ComponentByName("labelStyle1", typeof(UILabel))
	self.btnStyle2 = groupAction:NodeByName("btnStyle2").gameObject
	self.imgSelect2 = self.btnStyle2:ComponentByName("imgSelect", typeof(UISprite))
	self.imgUnselect2 = self.btnStyle2:ComponentByName("imgUnselect", typeof(UISprite))
	self.labelStyle2 = groupAction:ComponentByName("labelStyle2", typeof(UILabel))
end

function LeadskinStyleExchangeWindow:initWindow()
	self:getUIComponent()
	LeadskinStyleExchangeWindow.super.initWindow(self)
	self:register()

	self.dress_id = xyd.tables.senpaiDressStyleTable:getDressId(self.styleID)
	self.all_styles = xyd.tables.senpaiDressTable:getStyles(self.dress_id)

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

	self:initUIComponent()
end

function LeadskinStyleExchangeWindow:initUIComponent()
	self.labelTitle_.text = __("PERSON_DRESS_MAIN_23")
	self.labelStyle1.text = __("PERSON_DRESS_MAIN_24", 1)
	self.labelStyle2.text = __("PERSON_DRESS_MAIN_24", 2)

	self:setImg()
	self:setBtn()
end

function LeadskinStyleExchangeWindow:register()
	LeadskinStyleExchangeWindow.super.register(self)

	for i = 1, 2 do
		UIEventListener.Get(self["btnStyle" .. i]).onClick = function ()
			self:onClickBtn(i)
		end
	end

	self.eventProxy_:addEventListener(xyd.event.DRESS_UNLOCK_STYLE, handler(self, self.dressUnlockStyleBack))
end

function LeadskinStyleExchangeWindow:onClickBtn(styleIndex)
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

	self.styleIndex = styleIndex

	self:setImg()
	self:setBtn()
end

function LeadskinStyleExchangeWindow:setImg()
	self.choiceStyle = self.all_styles[self.styleIndex]
	local image = xyd.tables.senpaiDressStyleTable:getImage(self.choiceStyle)

	xyd.setUISpriteAsync(self.imgSkin, nil, image, nil, , )
end

function LeadskinStyleExchangeWindow:setBtn()
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

function LeadskinStyleExchangeWindow:willClose()
	LeadskinStyleExchangeWindow.super.willClose(self)

	if not self.isOnlyPreview then
		-- Nothing
	elseif self.choiceStyle ~= self.styleID then
		local dress_check_office_wn = xyd.WindowManager.get():getWindow("dress_check_office_window")

		if self.mainWin_ then
			dress_check_office_wn = self.mainWin_
		end

		if dress_check_office_wn then
			dress_check_office_wn:updateStyleOnly(self.choiceStyle)
		end
	end
end

function LeadskinStyleExchangeWindow:dressUnlockStyleBack(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.style_id then
		local index = -1

		for i in pairs(self.all_styles) do
			if self.all_styles[i] == data.style_id then
				index = i

				break
			end
		end

		if index ~= -1 then
			for i in pairs(self.lock_ids) do
				if self.lock_ids[i] == index then
					table.remove(self.lock_ids, i)

					break
				end
			end
		end

		local leadskin_choose_wn = xyd.WindowManager.get():getWindow("leadskin_choose_window")

		if leadskin_choose_wn then
			leadskin_choose_wn:updateDressIconShowNum(data.style_id)
		end
	end
end

return LeadskinStyleExchangeWindow
