local BaseWindow = import(".BaseWindow")
local SoulEquipComfirmExchangeWindow = class("SoulEquipComfirmExchangeWindow", BaseWindow)
local SoulEquipComfirmExchangeItem = class("SoulEquipComfirmExchangeItem", import("app.components.CopyComponent"))

function SoulEquipComfirmExchangeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.equipIDs = params.equipIDs
	self.callback = params.callback
	self.items = {}
	self.noChoose = true
end

function SoulEquipComfirmExchangeWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function SoulEquipComfirmExchangeWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelWindowTitle = self.groupAction:ComponentByName("labelWindowTitle", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.itemGroup = self.midGroup:NodeByName("itemGroup").gameObject
	self.itemGroupGrid = self.midGroup:ComponentByName("itemGroup", typeof(UIGrid))
	self.item = self.midGroup:NodeByName("item").gameObject
	self.equipIconPos = self.item:NodeByName("equipIconPos").gameObject
	self.heroIconPos = self.item:NodeByName("heroIconPos").gameObject
	self.groupChoose = self.groupAction:NodeByName("groupChoose").gameObject
	self.groupChooseLayout = self.groupAction:ComponentByName("groupChoose", typeof(UILayout))
	self.btnUntips = self.groupChoose:NodeByName("img").gameObject
	self.imgSelect = self.btnUntips:ComponentByName("imgSelect", typeof(UISprite))
	self.labelNever = self.groupChoose:ComponentByName("labelNever", typeof(UILabel))
	self.btnSure = self.groupAction:NodeByName("btnSure").gameObject
	self.labelSure = self.btnSure:ComponentByName("labelSure", typeof(UILabel))
	self.btnCancel = self.groupAction:NodeByName("btnCancel").gameObject
	self.labelCancel = self.btnCancel:ComponentByName("labelCancel", typeof(UILabel))
end

function SoulEquipComfirmExchangeWindow:register()
	UIEventListener.Get(self.btnClose).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnUntips).onClick = function ()
		self.noChoose = not self.noChoose

		self.imgSelect:SetActive(self.noChoose)
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		if self.callback then
			self.callback()

			if self.noChoose then
				xyd.db.misc:setValue({
					key = "soul_equip_exchange_equip_tip",
					value = xyd.getServerTime()
				})
			end
		end

		self:close()
	end

	UIEventListener.Get(self.btnCancel).onClick = function ()
		self:close()
	end
end

function SoulEquipComfirmExchangeWindow:layout()
	self.labelWindowTitle.text = __("ROB_EQUIP_CONFIRM")
	self.labelNever.text = __("GAMBLE_REFRESH_NOT_SHOW_TODAY")
	self.labelSure.text = __("FOR_SURE")
	self.labelCancel.text = __("CANCEL_2")

	self:update()
end

function SoulEquipComfirmExchangeWindow:update()
	local datas = {}

	for i = 1, #self.equipIDs do
		local equipID = self.equipIDs[i]

		if equipID then
			local equip = xyd.models.slot:getSoulEquip(equipID)

			if equip then
				-- Nothing
			end

			if equip and equip:getOwnerPartnerID() and equip:getOwnerPartnerID() > 0 then
				if self.items[i] == nil then
					local tmp = NGUITools.AddChild(self.itemGroup.gameObject, self.item)
					local item = SoulEquipComfirmExchangeItem.new(tmp)

					item:setInfo({
						equip = equip
					})

					self.items[i] = item
				else
					self.items[i]:setInfo({
						equip = equip
					})
				end
			end
		end
	end

	self.itemGroupGrid:Reposition()
end

function SoulEquipComfirmExchangeItem:ctor(go)
	self.go = go
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY)

	self:getUIComponent()
end

function SoulEquipComfirmExchangeItem:getUIComponent()
	self.item = self.go
	self.equipIconPos = self.item:NodeByName("equipIconPos").gameObject
	self.heroIconPos = self.item:NodeByName("heroIconPos").gameObject
end

function SoulEquipComfirmExchangeItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	local itemIcon = xyd.getItemIcon({
		noClick = true,
		scale = 0.7962962962962963,
		uiRoot = self.equipIconPos,
		itemID = params.equip:getTableID(),
		soulEquipInfo = params.equip:getSoulEquipInfo()
	}, xyd.ItemIconType.ADVANCE_ICON)
	local partner = xyd.models.slot:getPartner(params.equip:getOwnerPartnerID())
	local params1 = partner:getInfo()
	params1.noClick = true
	params1.scale = 0.7962962962962963
	params1.uiRoot = self.heroIconPos
	local heroIcon = xyd.getItemIcon(params1, xyd.ItemIconType.ADVANCE_ICON)
end

return SoulEquipComfirmExchangeWindow
