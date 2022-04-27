local HouseCombineItem = class("HouseCombineItem")

function HouseCombineItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	xyd.setDragScrollView(go, parent.scrollView)
	self:initUI()
	self:registerEvent()
end

function HouseCombineItem:getGameObject()
	return self.go
end

function HouseCombineItem:initUI()
	self.groupAdd_ = self.go:NodeByName("groupAdd_").gameObject
	self.img_ = self.groupAdd_:ComponentByName("img_", typeof(UISprite))
	self.img2_ = self.groupAdd_:ComponentByName("img2_", typeof(UITexture))
	self.groupMain_ = self.go:NodeByName("groupMain_").gameObject
	self.labelName_ = self.groupMain_:ComponentByName("labelName_", typeof(UILabel))
	self.btnEditName_ = self.groupMain_:NodeByName("btnEditName_").gameObject
	self.btnDel_ = self.groupMain_:NodeByName("btnDel_").gameObject
	self.btnSave_ = self.groupMain_:NodeByName("btnSave_").gameObject
	self.btnApply_ = self.groupMain_:NodeByName("btnApply_").gameObject

	self:layout()
end

function HouseCombineItem:layout()
	self.btnDel_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_17")
	self.btnSave_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_18")
	self.btnApply_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_19")

	if xyd.Global.lang == "de_de" then
		self.btnDel_:ComponentByName("button_label", typeof(UILabel)).fontSize = 20
		self.btnSave_:ComponentByName("button_label", typeof(UILabel)).fontSize = 20
		self.btnApply_:ComponentByName("button_label", typeof(UILabel)).fontSize = 20
	end
end

function HouseCombineItem:registerEvent()
	UIEventListener.Get(self.groupAdd_).onClick = handler(self, self.onAddTouch)
	UIEventListener.Get(self.btnEditName_).onClick = handler(self, self.onEditNameTouch)
	UIEventListener.Get(self.btnDel_).onClick = handler(self, self.onDelTouch)
	UIEventListener.Get(self.btnSave_).onClick = handler(self, self.onSaveTouch)
	UIEventListener.Get(self.btnApply_).onClick = handler(self, self.onApplyTouch)
end

function HouseCombineItem:onAddTouch()
	xyd.WindowManager.get():openWindow("house_new_combine_window", {
		is_new = true,
		id = self.data.id,
		uploadImg = self.parent.uploadImg
	})
end

function HouseCombineItem:onEditNameTouch()
	xyd.WindowManager.get():openWindow("house_new_combine_window", {
		id = self.data.id,
		old_name = self.data.name,
		furnitures = self.data.furniture_infos,
		imgUrl = self.imgUrl
	})
end

function HouseCombineItem:onDelTouch()
	xyd.alert(xyd.AlertType.YES_NO, __("HOUSE_TEXT_35", self.data.name), function (yes)
		if yes then
			xyd.models.house:reqDelCombine(self.data.id)
		end
	end)
end

function HouseCombineItem:onSaveTouch()
	xyd.alert(xyd.AlertType.YES_NO, __("HOUSE_TEXT_37"), function (yes)
		if yes then
			local msg = messages_pb.house_add_combine_req()

			xyd.HouseMap.get():getSaveData(msg)
			xyd.models.house:reqAddCombine(msg, self.data.name, self.data.id, self.parent.uploadImg)
		end
	end)
end

function HouseCombineItem:onApplyTouch()
	xyd.alert(xyd.AlertType.YES_NO, __("HOUSE_TEXT_36", self.data.name), function (yes)
		if yes then
			local furnitures = self.data.furniture_infos
			local wnd = xyd.getWindow("house_combine_window")
			local floor = 1

			if wnd then
				floor = wnd:getCurFloor()
			end

			local flag = xyd.models.house:checkFurnitureNum(furnitures, floor)

			if not flag then
				xyd.alertTips(__("HOUSE_TEXT_58"))

				return
			end

			xyd.HouseMap.get():clearAll()
			xyd.HouseMap.get():initItems(furnitures)
			xyd.HouseMap.get():setNeedSave(true)

			local wnd = xyd.WindowManager.get():getWindow("house_window")

			if wnd then
				wnd:updateHouseBox()
			end
		end
	end)
end

function HouseCombineItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)

	if self.data.is_null then
		self.groupMain_:SetActive(false)
		xyd.setTouchEnable(self.groupAdd_, true)
		self.img_:SetActive(false)
		self.img2_:SetActive(false)
	else
		self.labelName_.text = self.data.name

		self.groupMain_:SetActive(true)
		self.img_:SetActive(true)
		xyd.setTouchEnable(self.groupAdd_, false)

		local imgUrl = xyd.models.house:getHouseCombineImgUrl(self.data.id)
		local fileName = xyd.models.house:getHouseCombineImgName(self.data.id)

		if imgUrl then
			xyd.setTextureByURL(imgUrl, self.img2_, 202, 130, function ()
				self.img2_:SetActive(true)

				self.imgUrl = imgUrl
			end, nil, xyd.HOUSE_IMG_SAVE_PATH, fileName)
		else
			self.img2_:SetActive(false)
			self.img_:SetActive(true)
		end
	end
end

local HouseCombineWindow = class("HouseCombineWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function HouseCombineWindow:ctor(name, params)
	HouseCombineWindow.super.ctor(self, name, params)

	self.curFloor_ = params.floor or 1
	self.uploadImg = params.uploadImg
end

function HouseCombineWindow:initWindow()
	HouseCombineWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:updateItemList()
	self:registerEvent()
end

function HouseCombineWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle_ = winTrans:ComponentByName("groupAction/labelTitle_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	local scrollView = winTrans:ComponentByName("groupAction/scroller_", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("itemList_", typeof(UIWrapContent))
	local houseCombineItem = scrollView:NodeByName("house_combine_item").gameObject
	self.wrapContent_ = FixedWrapContent.new(scrollView, wrapContent, houseCombineItem, HouseCombineItem, self)
end

function HouseCombineWindow:layout()
	self.labelTitle_.text = __("HOUSE_TEXT_15")
end

function HouseCombineWindow:registerEvent()
	self:register()
	self.eventProxy_:addEventListener(xyd.event.HOUSE_ADD_COMBINE, handler(self, self.onAddCombine))
	self.eventProxy_:addEventListener(xyd.event.HOUSE_DEL_COMBINE, handler(self, self.onAddCombine))
end

function HouseCombineWindow:updateItemList(keepPosition)
	local data = xyd.models.house:getCombines()
	local tmpArry = {}
	local ids = {
		1,
		2,
		3,
		4,
		5
	}

	for i = 1, 5 do
		if data[i] then
			table.removebyvalue(ids, data[i].id)
			table.insert(tmpArry, data[i])
		else
			local id = table.remove(ids, 1)

			table.insert(tmpArry, {
				is_null = true,
				id = id
			})
		end
	end

	self.wrapContent_:setInfos(tmpArry, {
		keepPosition = keepPosition
	})
end

function HouseCombineWindow:onAddCombine()
	self:updateItemList(true)
end

function HouseCombineWindow:getCurFloor()
	return self.curFloor_
end

function HouseCombineWindow:willClose()
	HouseCombineWindow.super.willClose(self)

	local wnd = xyd.WindowManager.get():getWindow("house_window")

	if wnd then
		wnd:onCombineHide(true)
	end
end

return HouseCombineWindow
