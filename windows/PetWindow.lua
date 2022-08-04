local BaseWindow = import(".BaseWindow")
local PetWindow = class("PetWindow", BaseWindow)
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local WindowTop = import("app.components.WindowTop")
local PetListItem = class("PetListItem", import("app.components.CopyComponent"))

function PetWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.PetSlot = xyd.models.petSlot
	self.fistPetItem_y = nil

	if params then
		self.jumpIndex = params.jumpIndex
	end
end

function PetWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.main = winTrans:NodeByName("main").gameObject
	self.topGroup = self.main:NodeByName("topGroup").gameObject
	self.helpBtn = self.topGroup:NodeByName("helpBtn").gameObject
	self.labelTitle = self.topGroup:ComponentByName("labelTitle_", typeof(UILabel))
	self.content = self.main:NodeByName("content").gameObject
	self.scroller = self.content:ComponentByName("scroller", typeof(UIScrollView))
	self.scroller_uipanel = self.content:ComponentByName("scroller", typeof(UIPanel))
	self.petDataGroup = self.content:NodeByName("scroller/petDataGroup").gameObject
	self.gEffect = self.main:NodeByName("gEffect").gameObject
	local wrapContent = self.petDataGroup:GetComponent(typeof(MultiRowWrapContent))
	local petListItem = winTrans:NodeByName("pet_list_item").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.scroller, wrapContent, petListItem, PetListItem, self)
end

function PetWindow:playOpenAnimation(callback)
	PetWindow.super.playOpenAnimation(self, function ()
		local seq = self:getSequence(function ()
			self:setWndComplete()
		end)
		local main = self.main

		main.transform:X(-self.window_:GetComponent(typeof(UIPanel)).width)
		seq:Append(main.transform:DOLocalMove(Vector3(50, 19, 0), 0.3))
		seq:Append(main.transform:DOLocalMove(Vector3(0, 19, 0), 0.27))

		if callback then
			callback()
		end
	end)
end

function PetWindow:initWindow()
	PetWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initDataGroup()
	self:registerEvent()
end

function PetWindow:layout()
	self.labelTitle.text = __("PET_LIST")

	self:initTopGroup()
end

function PetWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			show_tips = true,
			hidePlus = true,
			id = xyd.ItemID.PET_STONE
		},
		{
			show_tips = true,
			hidePlus = true,
			id = xyd.ItemID.PET_SKILL_EXP
		}
	}

	self.windowTop:setItem(items)
end

function PetWindow:initDataGroup()
	local ids = self.PetSlot:getPetIDs()

	table.sort(ids, function (a, b)
		local petA = self.PetSlot:getPetByID(a)
		local petB = self.PetSlot:getPetByID(b)
		local scoreA = petB:getGrade() < petA:getGrade() and 1000 or 0
		local scoreB = petA:getGrade() < petB:getGrade() and 1000 or 0
		scoreA = scoreA + (petA:getLevel() > 0 and 10000 or 0)
		scoreB = scoreB + (petB:getLevel() > 0 and 10000 or 0)
		scoreA = scoreA + (petB:getLevel() < petA:getLevel() and 100 or 0)
		scoreB = scoreB + (petA:getLevel() < petB:getLevel() and 100 or 0)

		if petA:getTableID() < petB:getTableID() then
			scoreA = scoreA + 10
		else
			scoreB = scoreB + 10
		end

		return scoreA > scoreB
	end)

	local data = {}

	for i = 1, #ids do
		local id = ids[i]
		local time = xyd.tables.petTable:getShowTime(id)

		if not time or xyd.getServerTime() >= time then
			table.insert(data, {
				pos = i,
				id = id
			})
		end
	end

	self.wrapContent:setInfos(data, {})

	if self.jumpIndex then
		for i = 1, #data do
			if data[i].id == self.jumpIndex then
				self:waitForFrame(2, handler(self, function ()
					self.wrapContent:jumpToIndex(i)

					self.jumpIndex = nil
				end), nil)
			end
		end
	end
end

function PetWindow:registerEvent()
	BaseWindow.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_PET_LIST, self.onGetList, self)
	self.eventProxy_:addEventListener(xyd.event.ACTIVE_PET, self.onActivePet, self)
	self.eventProxy_:addEventListener(xyd.event.WINDOW_WILL_CLOSE, self.onDetailWindowClose, self)
	self.eventProxy_:addEventListener(xyd.event.PET_GRADE_UP, self.initDataGroup, self)
	self.eventProxy_:addEventListener(xyd.event.PET_LEV_UP, self.initDataGroup, self)
	self.eventProxy_:addEventListener(xyd.event.PET_RESTORE, self.initDataGroup, self)
end

function PetWindow:onGetList()
	self:initDataGroup()
end

function PetWindow:onActivePet(event)
	local items = self.wrapContent:getItems()
	local item = nil

	for i = 1, #items do
		if items[i].id == event.data.pet_info.pet_id then
			item = items[i]

			items[i]:update(nil, items[i].realIndex, {
				id = items[i].id
			})
		end
	end

	local node = NGUITools.AddChild(item.go, self.gEffect)
	local effect = xyd.Spine.new(node)

	effect:setInfo("ui_pet_unlock", function ()
		effect:SetLocalPosition(0, 2, 0)
		effect:SetLocalScale(0.75, 0.97, 1)
		effect:play("texiao_01", 1, 1, function ()
			effect:destroy()
			NGUITools.Destroy(node)
		end)
	end)
end

function PetWindow:onDetailWindowClose(event)
	local data = event.params

	if data.windowName ~= "pet_detail_window" then
		return
	end

	self:initDataGroup()
end

function PetWindow:playActiveEffect(x, y, curItem, uiItem)
end

function PetWindow:getScrollView()
	return self.scroller
end

function PetWindow:getScrollView_uipanel()
	return self.scroller_uipanel
end

function PetListItem:ctor(go, petWindow)
	PetListItem.super.ctor(self, go)

	self.petWindow = petWindow

	self:setDragScrollView(petWindow:getScrollView())
	self:getUIComponent()
	self:register()

	self.deltaFrame = 1
	self.maxDetlta = 1
end

function PetListItem:getUIComponent()
	self.dbGroup = self.go:NodeByName("dbGroup").gameObject
	local group = self.go:NodeByName("group").gameObject
	self.bg = group:ComponentByName("bg", typeof(UISprite))
	self.groupModel = group:NodeByName("groupModel").gameObject
	self.btn = self.go:NodeByName("btn").gameObject
	self.btn_uiSprite = self.go:ComponentByName("btn", typeof(UISprite))
	self.button_label = self.btn:ComponentByName("button_label", typeof(UILabel))
	self.button_mix = self.btn:NodeByName("button_mix").gameObject
	self.button_icon = self.button_mix:ComponentByName("button_icon", typeof(UISprite))
	self.button_num = self.button_mix:ComponentByName("button_num", typeof(UILabel))
	self.button_label_2 = self.button_mix:ComponentByName("button_label_2", typeof(UILabel))
	self.labelLevel = self.go:ComponentByName("labelLevel", typeof(UILabel))
	self.btnCore = self.go:NodeByName("btnCore").gameObject
	self.btnCoreSprite = self.btnCore:GetComponent(typeof(UISprite))
	self.btnCoreLabel = self.btnCore:ComponentByName("btnCoreLabel", typeof(UILabel))
	self.border0 = self.go:ComponentByName("border0", typeof(UISprite))
	self.border1 = self.go:ComponentByName("border1", typeof(UISprite))
end

function PetListItem:register()
	UIEventListener.Get(self.go.gameObject).onClick = handler(self, self.onDisplay)
	UIEventListener.Get(self.btnCore).onClick = handler(self, self.onTouch)

	xyd.setDarkenBtnBehavior(self.btn, self, self.onTouch)
end

function PetListItem:getId()
	return self.id
end

function PetListItem:update(index, realIndex, info)
	self.realIndex = realIndex

	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id = info.id
	local pet = xyd.models.petSlot:getPetByID(self.id)

	if not pet then
		return
	end

	local cost = nil

	if pet:getLevel() <= 0 then
		cost = xyd.tables.petTable:getActiveCost(self.id)
		self.button_label.text = __("PET_ACTIVE")
		self.button_label.color = Color.New2(4278124287.0)
		self.button_label.effectColor = Color.New2(1012112383)
		self.button_label.fontSize = 24

		xyd.setUISpriteAsync(self.button_icon, nil, xyd.tables.itemTable:getSmallIcon(cost[1]))

		self.button_num.text = tostring(cost[2])

		self.button_label:SetActive(false)
		self.labelLevel:SetActive(false)
		self.button_mix:SetActive(true)

		self.button_label_2.text = __("PET_ACTIVE")

		if xyd.Global.lang == "de_de" then
			self.button_icon:X(-52)
			self.button_num:X(-50)

			self.button_label_2.fontSize = 24
		end

		if xyd.Global.lang == "fr_fr" then
			self.button_icon:X(-50)
			self.button_num:X(-48)
			self.button_label_2:X(24)

			self.button_label_2.fontSize = 22
		end

		xyd.applyChildrenGrey(self.go)
		xyd.applyChildrenOrigin(self.btn)

		if self.db and self.spAnim then
			self.db.spAnim.fillColor = Vector4(0, 0, 0, 1)
		end
	else
		self.button_label.text = __("PET_DETAIL")
		self.labelLevel.text = "Lv." .. tostring(pet:getLevel())

		if xyd.Global.lang == "fr_fr" then
			self.labelLevel.text = "Niv." .. tostring(pet:getLevel())
		end

		self.button_num.effectColor = Color.New2(943741695)
		self.button_num.fontSize = 20
		self.button_num.color = Color.New2(4278124287.0)

		self.button_label:SetActive(true)
		self.labelLevel:SetActive(true)
		self.button_mix:SetActive(false)
		xyd.applyChildrenOrigin(self.go)

		if self.db and self.db.spAnim then
			self.db.spAnim.fillColor = Vector4(1, 1, 1, 1)
		end
	end

	local grade = pet:getGrade()
	local strs = xyd.tables.miscTable:split("pet_frame_use", "value", "|")

	xyd.setUISpriteAsync(self.border1, nil, tostring(strs[grade + 1]))
	xyd.setUISpriteAsync(self.border0, nil, tostring(strs[grade + 1]))
	xyd.setUISpriteAsync(self.bg, nil, xyd.tables.petTable:getCardBg(self.id))

	local modelName = pet:getModelName()
	local pos = xyd.tables.modelTable:getPetCardPos(pet:getModelID())

	if self.modelName_ == modelName then
		return
	else
		self.modelName_ = modelName

		self:initModel(modelName, pos)
		self:effectClip()
	end

	self:effectClip()

	if pet:getExLv() > 0 then
		self.btnCore:SetActive(true)
		xyd.setUISpriteAsync(self.btnCoreSprite, nil, "pet_exskill_" .. self.id)

		self.btnCoreLabel.text = __("PET_EXSKILL_TEXT_01", pet:getExLv())
	else
		self.btnCore:SetActive(false)
	end
end

function PetListItem:initModel(modelName, pos)
	if self.db and self.db.name then
		if self.db:getName() == modelName then
			return
		else
			self.db:destroy()
		end
	end

	self.db = xyd.Spine.new(self.groupModel)

	self:waitForFrame(2, handler(self, function ()
		if self.realIndex == 1 and self.petWindow.fistPetItem_y == nil then
			self.petWindow.fistPetItem_y = self.petWindow.content.transform:InverseTransformPoint(self.go.transform.position).y
		end
	end))
	self:waitForFrame(3, handler(self, function ()
		if self.modelName_ ~= modelName then
			return
		end

		self.db:setInfo(modelName, function ()
			self.db:SetLocalScale(pos[1], pos[1], 1)
			self.db:play("idle", 0, 1)
			self.db:SetLocalPosition(pos[2], -pos[3] + 211, -10 * math.random())
			self:waitForFrame(1, handler(self, function ()
				self:effectClip()
			end), nil)

			local pet = xyd.models.petSlot:getPetByID(self.id)

			if pet:getLevel() <= 0 then
				self.db.spAnim.fillColor = Vector4(0, 0, 0, 1)
			else
				self.db.spAnim.fillColor = Vector4(1, 1, 1, 1)
			end
		end, true)
	end))
	self.db:SetLocalPosition(pos[2], -pos[3] + 211, -10 * math.random())
end

function PetListItem:effectClip()
	if self.isFirstEffectClip == nil and self.db and self.petWindow and not tolua.isnull(self.petWindow.window_) then
		self.db:setClipAreaWithScroller(self.petWindow.scroller.gameObject, self.go.gameObject, self.petWindow.fistPetItem_y, Vector4(2, 8, 6, 6), Vector2(-5, -10))
		self.petWindow.scroller:Scroll(0.001)

		if not self.petWindow or not self.petWindow.scroller or self.petWindow.scroller.gameObject == nil or not self.go or self.go.gameObject == nil or not self.petWindow.fistPetItem_y then
			self:waitForTime(1, function ()
				self:effectClip()
			end)
		end
	end
end

function PetListItem:onTouch()
	local id = self.id
	local pet = xyd.models.petSlot:getPetByID(id)

	if pet:getLevel() <= 0 then
		self:activePet()
	else
		self:detailTouch()
	end
end

function PetListItem:onDisplay()
	local id = self.id

	xyd.WindowManager:get():openWindow("pet_info_window", {
		id = id
	})
end

function PetListItem:activePet()
	local id = self.id
	local cost = xyd.tables.petTable:getActiveCost(id)
	local selfNum = xyd.models.backpack:getItemNumByID(cost[1])

	if selfNum < cost[2] then
		xyd.alert(xyd.AlertType.TIPS, __("PET_ACTIVE_ERROR"))
	else
		xyd.models.petSlot:activePet(self.id)
	end
end

function PetListItem:detailTouch()
	xyd.WindowManager.get():openWindow("pet_detail_window", {
		pet_id = self.id
	})
	xyd.WindowManager.get():closeWindow("pet_window", nil, , true)
end

function PetListItem:showActiveEffect()
	if self.effect and self.effect:isValid() then
		self.effect:play("texiao02", 1)

		return
	elseif self.effect and not self.effect:isValid() then
		return
	end

	self.effect = DragonBones.new("ui_pet_head", {
		callback = function ()
			self.effect:play("texiao02", 1)
		end
	})

	self.dbGroup:addChild(self.effect)
end

return PetWindow
