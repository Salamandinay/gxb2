local RobEquipConfirmWindow = class("RobEquipConfirmWindow", import(".BaseWindow"))
local ItemIcon = import("app.components.ItemIcon")
local HeroIcon = import("app.components.HeroIcon")

function RobEquipConfirmWindow:ctor(name, params)
	RobEquipConfirmWindow.super.ctor(self, name, params)

	self.callback = params.callback
	self.itemID = params.item_id
	self.partnerID = params.partner_id
	self.unTips = false
	self.titleText = params.title
end

function RobEquipConfirmWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:register()
end

function RobEquipConfirmWindow:getUIComponent()
	local main = self.window_:NodeByName("e:Group").gameObject
	self.btnConfirm = main:NodeByName("btnConfirm").gameObject
	self.btnConfirm_label = self.btnConfirm:ComponentByName("button_label", typeof(UILabel))
	self.btnCancel = main:NodeByName("btnCancel").gameObject
	self.btnCancel_label = self.btnCancel:ComponentByName("button_label", typeof(UILabel))
	self.labelTitle = main:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = main:NodeByName("closeBtn").gameObject
	self.groupChoose = main:NodeByName("groupChoose").gameObject
	self.labelNever = self.groupChoose:ComponentByName("labelNever", typeof(UILabel))
	self.imgSelect = self.groupChoose:NodeByName("groupSelect/imgSelect").gameObject
	self.itemNode = main:NodeByName("itemNode").gameObject
	self.heroNode = main:NodeByName("heroNode").gameObject
end

function RobEquipConfirmWindow:layout()
	self.labelTitle.text = self.titleText or __("ROB_EQUIP_CONFIRM")
	self.labelNever.text = __("GAMBLE_REFRESH_NOT_SHOW_TODAY")
	self.groupChoose:GetComponent(typeof(UIWidget)).width = self.labelNever.width + 100
	self.btnConfirm_label.text = __("FOR_SURE")
	self.btnCancel_label.text = __("CANCEL_2")
	local itemIcon = ItemIcon.new(self.itemNode)

	itemIcon:setInfo({
		noClick = true,
		itemID = self.itemID
	})

	local heroIcon = HeroIcon.new(self.heroNode)
	local partner = xyd.models.slot:getPartner(self.partnerID)
	local params = partner:getInfo()
	params.noClick = true

	heroIcon:setInfo(params)
end

function RobEquipConfirmWindow:register()
	RobEquipConfirmWindow.super.register(self)

	UIEventListener.Get(self.btnConfirm).onClick = function ()
		if self.callback then
			self.callback()

			if self.unTips then
				xyd.db.misc:setValue({
					key = "rob_equip_confirm",
					value = xyd.getServerTime()
				})
			end
		end

		self:close()
	end

	UIEventListener.Get(self.btnCancel).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.groupChoose).onClick = function ()
		self.unTips = not self.unTips

		self.imgSelect:SetActive(self.unTips)
	end
end

return RobEquipConfirmWindow
