local PotentialityEditWindow = class("PotentialityEditWindow", import(".BaseWindow"))
local PotentialityEditItem = class("PotentialityEditItem", import("app.components.BaseComponent"))
local PotentialIcon = class("PotentialIcon", import("app.components.PotentialIcon"))
local json = require("cjson")

function PotentialityEditWindow:ctor(name, params)
	PotentialityEditWindow.super.ctor(self, name, params)
end

function PotentialityEditWindow:initWindow()
	PotentialityEditWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function PotentialityEditWindow:getUIComponent()
	local groupTrans = self.window_:NodeByName("groupAction")
	self.btnHelp = groupTrans:NodeByName("btnHelp").gameObject
	self.closeBtn = groupTrans:NodeByName("closeBtn").gameObject
	self.titleLabel = groupTrans:ComponentByName("titleLabel", typeof(UILabel))
	local contentGroupTrans = groupTrans:NodeByName("contentGroup")
	self.scrollView = contentGroupTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.layout = contentGroupTrans:ComponentByName("scrollView/layout", typeof(UILayout))
end

function PotentialityEditWindow:initUIComponent()
	self.items = {}
	self.editType = nil
	self.editIndex = 0
	self.partner_ = self.params_.partner
	self.potentials_bak = self.partner_:getPotentialBak()
	self.titleLabel.text = __("POTENTIAL_PLAN_TEXT02")

	if self.potentials_bak and type(self.potentials_bak) == "string" then
		self.potentials_bak = json.decode(self.potentials_bak)

		for i = 1, #self.potentials_bak do
			self:buildNewBak(i, {
				name = self.potentials_bak[i].name,
				potentials = self.potentials_bak[i].potentials
			})
		end
	end

	if not self.potentials_bak or #self.potentials_bak < 3 then
		self:buildNewBak(#self.items + 1)
	end

	self:resetPosition()
end

function PotentialityEditWindow:buildNewBak(index, params)
	local item = nil

	if params then
		item = PotentialityEditItem.new(self.layout.gameObject, {
			type = "on",
			index = index,
			partner = self.partner_,
			name = params.name,
			potentials = params.potentials,
			parent = self
		})
	else
		item = PotentialityEditItem.new(self.layout.gameObject, {
			type = "down",
			index = index,
			partner = self.partner_,
			parent = self
		})
	end

	table.insert(self.items, item)
end

function PotentialityEditWindow:register()
	PotentialityEditWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.EDIT_POTENTIALS_BAK, handler(self, self.onUpdateBak))
	self.eventProxy_:addEventListener(xyd.event.SET_POTENTIALS_BAK, handler(self, self.onUpdateBak))

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "POTENTIAL_PLAN_HELP"
		})
	end
end

function PotentialityEditWindow:onUpdateBak()
	if not self.editType or not self.editIndex then
		print("error~~")

		return
	end

	self.potentials_bak = self.partner_:getPotentialBak()

	if self.potentials_bak and type(self.potentials_bak) == "string" then
		self.potentials_bak = json.decode(self.potentials_bak)
	end

	local index = self.editIndex
	local item = self.items[index]

	if self.editType == "refresh" then
		local potentials = self.potentials_bak[index].potentials

		item:update(false, nil, potentials)
	elseif self.editType == "duplicate" then
		local potentials = self.potentials_bak[index].potentials

		item:update(false, nil, potentials)
		xyd.alertTips(__("POTENTIAL_PLAN_TEXT06"))
	elseif self.editType == "name" then
		local name = self.potentials_bak[index].name

		item:update(false, name)
	elseif self.editType == "makeup" then
		item.type = "on"

		item:updateContent()

		if #self.items < 3 then
			self:buildNewBak(#self.items + 1)
		end

		self:resetPosition()
	elseif self.editType == "delete" then
		if index == 3 then
			item.type = "down"

			item:updateContent()
		else
			table.remove(self.items, index)
			NGUITools.Destroy(item.go.transform)

			if self.items[#self.items].type ~= "down" then
				self:buildNewBak(#self.items + 1)
			end

			for i = 1, #self.items do
				self.items[i].index = i
			end
		end

		self:resetPosition()
	elseif self.editType == "active" then
		for i = 1, #self.items do
			self.items[i]:updateActiveBtn()
		end

		xyd.alertTips(__("POTENTIAL_PLAN_TEXT08"))
	end

	self.editType = nil
	self.editIndex = nil
end

function PotentialityEditWindow:resetPosition()
	self:waitForFrame(1, function ()
		self.layout:Reposition()
		self.scrollView:ResetPosition()
	end)
end

function PotentialityEditItem:ctor(parentGo, params)
	self.type = params.type
	self.index = params.index
	self.partner = params.partner
	self.name = params.name
	self.potentials = params.potentials or {
		0,
		0,
		0,
		0,
		0
	}
	self.parent = params.parent

	PotentialityEditItem.super.ctor(self, parentGo)
end

function PotentialityEditItem:getPrefabPath()
	return "Prefabs/Components/potentiality_edit_item"
end

function PotentialityEditItem:initUI()
	self:getUIComponent()
	self:initUIComponent()
	self:updateContent()
end

function PotentialityEditItem:getUIComponent()
	local go = self.go
	self.goWidget = go:GetComponent(typeof(UIWidget))
	self.groupOn = go:NodeByName("groupOn").gameObject
	self.nameLabel = self.groupOn:ComponentByName("nameGroup/nameLabel", typeof(UILabel))
	self.nameBtn = self.groupOn:NodeByName("nameGroup/nameBtn").gameObject
	self.deleteBtn = self.groupOn:NodeByName("deleteBtn").gameObject
	self.potentialGroup = self.groupOn:ComponentByName("potentialGroup", typeof(UILayout))
	self.duplicateBtn = self.groupOn:NodeByName("duplicateBtn").gameObject
	self.activeBtn = self.groupOn:NodeByName("activeBtn").gameObject
	self.groupDown = go:NodeByName("groupDown").gameObject
	self.groupDownLabel = self.groupDown:ComponentByName("label", typeof(UILabel))
end

function PotentialityEditItem:initUIComponent()
	self.duplicateBtn:ComponentByName("button_label", typeof(UILabel)).text = __("POTENTIAL_PLAN_TEXT05")
	self.activeBtn:ComponentByName("button_label", typeof(UILabel)).text = __("POTENTIAL_PLAN_TEXT07")
	self.groupDownLabel.text = __("POTENTIAL_PLAN_TEXT03")

	self.groupOn:SetActive(false)
	self.groupDown:SetActive(false)
	xyd.setDragScrollView(self.groupOn, self.parent.scrollView)
	xyd.setDragScrollView(self.groupDown, self.parent.scrollView)
end

function PotentialityEditItem:updateContent()
	if self.type == "down" then
		self.groupOn:SetActive(false)
		self.groupDown:SetActive(true)

		self.goWidget.height = 64
	else
		self.groupOn:SetActive(true)
		self.groupDown:SetActive(false)

		self.goWidget.height = 264

		self:initPotentials()
		self:updatePotentials()
	end

	self.nameLabel.text = self.name or __("POTENTIAL_PLAN_TEXT04", self.index)
end

function PotentialityEditItem:initPotentials()
	NGUITools.DestroyChildren(self.potentialGroup.transform)

	self.potentialIcons = {}
	local star = self.partner:getStar()
	local skills = self.partner:getPotentialByOrder()
	local potentials = self.potentials

	for i = 1, 5 do
		local iconItem = PotentialIcon.new(self.potentialGroup.gameObject)

		iconItem:setDragScrollView(self.parent.scrollView)
		iconItem:setTouchListener(function ()
			if star < i + 10 then
				xyd.alertTips(__("POTENTIALITY_LOCK", i))

				return
			else
				xyd.WindowManager.get():openWindow("potentiality_choose_window", {
					type = "potentials_bak",
					skill_list = skills[i],
					callBack = function (index)
						potentials[i] = index
						self.parent.editType = "refresh"
						self.parent.editIndex = self.index

						self:EditPotentialsBak(false, nil, potentials)
					end
				})
			end
		end)
		table.insert(self.potentialIcons, iconItem)
	end
end

function PotentialityEditItem:updatePotentials()
	local star = self.partner:getStar()
	local skills = self.partner:getPotentialByOrder()
	local potentials = self.potentials

	for i = 1, 5 do
		local params = {}
		local id = -1
		local ind = star - 9

		if i >= ind then
			params.is_lock = true
			params.is_mask = true
		elseif potentials[i] and potentials[i] ~= 0 then
			id = skills[i][potentials[i]]
			params.show_effect = false
		else
			params.is_next = true
		end

		params.scale = 0.9

		self.potentialIcons[i]:setInfo(id, params)
	end

	self.potentialGroup:Reposition()
	self:updateActiveBtn()
end

function PotentialityEditItem:updateActiveBtn()
	if self:checkActive() then
		xyd.setEnabled(self.activeBtn, true)
	else
		xyd.setEnabled(self.activeBtn, false)
	end
end

function PotentialityEditItem:onRegister()
	PotentialityEditItem.super.onRegister(self)

	UIEventListener.Get(self.nameBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("potentiality_bak_edit_name_window", {
			name = self.name,
			callback = function (name)
				self.parent.editType = "name"
				self.parent.editIndex = self.index

				self:EditPotentialsBak(false, name)
			end
		})
	end

	UIEventListener.Get(self.deleteBtn).onClick = handler(self, self.onDelete)
	UIEventListener.Get(self.duplicateBtn).onClick = handler(self, self.onDuplicate)
	UIEventListener.Get(self.activeBtn).onClick = handler(self, self.onActive)
	UIEventListener.Get(self.groupDown).onClick = handler(self, self.onSetNewBak)
end

function PotentialityEditItem:onSetNewBak()
	if not self:checkBak() then
		return
	end

	self.parent.editType = "makeup"
	self.parent.editIndex = self.index

	self:EditPotentialsBak(false)
end

function PotentialityEditItem:onDelete()
	xyd.alertYesNo(__("POTENTIAL_PLAN_TEXT09"), function (yes)
		if yes then
			self.parent.editType = "delete"
			self.parent.editIndex = self.index

			self:EditPotentialsBak(true)
		end
	end)
end

function PotentialityEditItem:onDuplicate()
	local active_status = self.partner:getActiveIndex()

	for i = 1, 5 do
		self.potentials[i] = active_status[i] or 0
	end

	self.parent.editType = "duplicate"
	self.parent.editIndex = self.index

	self:EditPotentialsBak(false)
end

function PotentialityEditItem:onActive()
	local msg = messages_pb.set_potentials_bak_req()
	msg.partner_id = self.partner:getPartnerID()
	msg.index = self.index

	xyd.Backend.get():request(xyd.mid.SET_POTENTIALS_BAK, msg)

	self.parent.editIndex = self.index
	self.parent.editType = "active"
end

function PotentialityEditItem:checkBak()
	local star = self.partner:getStar()

	if star < 11 then
		xyd.alert(xyd.AlertType.TIPS, __("POTENTIALITY_UNLOCK_TEXT1", 1))

		return false
	elseif star < 13 and self.index > 1 then
		xyd.alert(xyd.AlertType.TIPS, __("POTENTIALITY_UNLOCK_TEXT1", 3))

		return false
	elseif star < 15 and self.index > 2 then
		xyd.alert(xyd.AlertType.TIPS, __("POTENTIALITY_UNLOCK_TEXT1", 5))

		return false
	end

	return true
end

function PotentialityEditItem:EditPotentialsBak(isDeleted, name, potentials)
	local msg = messages_pb.edit_potentials_bak_req()
	msg.partner_id = self.partner:getPartnerID()
	msg.index = self.index

	if not isDeleted then
		msg.params = json.encode({
			name = name or self.name,
			potentials = potentials or self.potentials
		})
	end

	xyd.Backend.get():request(xyd.mid.EDIT_POTENTIALS_BAK, msg)
end

function PotentialityEditItem:update(isDeleted, name, potentials)
	if isDeleted then
		self.type = "down"

		self.groupOn:SetActive(false)
		self.groupDown:SetActive(true)

		self.goWidget.height = 64

		return
	end

	if name then
		self.name = name
		self.nameLabel.text = self.name
	end

	if potentials then
		self.potentials = potentials

		self:updatePotentials()
	end
end

function PotentialityEditItem:checkActive()
	local active_status = self.partner:getActiveIndex()

	for i = 1, 5 do
		if active_status[i] and active_status[i] ~= self.potentials[i] then
			return true
		end

		if not active_status[i] and self.potentials[i] ~= 0 then
			return true
		end
	end

	return false
end

return PotentialityEditWindow
