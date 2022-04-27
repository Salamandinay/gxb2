local BaseWindow = import(".BaseWindow")
local RechargeAwardWindow = class("RechargeAwardWindow", BaseWindow)

function RechargeAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.fx_name_ = "libaofankui"
	self.animation_name1_ = "texiao01"
	self.animation_name2_ = "texiao02"
	self.items_ = params.items
	self.giftbag_id_ = params.giftbag_id
	local group = eui.Group.new(true)
	group.width = 694
	group.height = 263
	group.horizontalCenter = 0
	group.verticalCenter = 0

	self:addChild(group)

	self.fxGroup = eui.Group.new(true)
	self.fxGroup.height = 0
	self.fxGroup.width = 0
	self.fxGroup.x = 347
	self.fxGroup.y = 132
	self.topLabel = MultiLabel.new()
	self.bottomLabel = MultiLabel.new()
	self.itemGroup = eui.Group.new(true)
	self.itemGroup.y = 87
	self.itemGroup.height = 108
	self.itemGroup.horizontalCenter = 0
	self.itemGroup.width = nil
	local layout = eui.HorizontalLayout.new()
	layout.gap = 30
	self.itemGroup.layout = layout

	group:addChild(self.fxGroup)
	group:addChild(self.itemGroup)
	group:addChild(self.topLabel)
	group:addChild(self.bottomLabel)

	self.topLabel.y = 20
	self.topLabel.horizontalCenter = 0
	self.topLabel.fontSize = 22
	self.topLabel.stroke = 2
	self.topLabel.textColor = 13623013
	self.topLabel.strokeColor = 3752006
	self.topLabel.lineSpacing = 2
	self.topLabel.textAlign = "center"

	xyd:setLabelFlow(self.topLabel, __(_G, "PACK_FEEDBACK_TEXT01", GiftBagTextTable:get():getShowName(self.giftbag_id_)))

	self.bottomLabel.bottom = 20
	self.bottomLabel.fontSize = 22
	self.bottomLabel.stroke = 2
	self.bottomLabel.textColor = 13623013
	self.bottomLabel.strokeColor = 3752006
	self.bottomLabel.horizontalCenter = 0
	self.bottomLabel.text = __(_G, "PACK_FEEDBACK_TEXT02")
end

function RechargeAwardWindow:createChildren()
	BaseWindow.createChildren(self)

	local items = self.items_
	self.itemGroup.visible = false
	local i = 0

	while i < items.length do
		if items[i].item_id ~= xyd.ItemID.VIP_EXP then
			local icon = xyd:getItemIcon({
				itemID = items[i].item_id,
				num = items[i].item_num
			})

			self.itemGroup:addChild(icon)
		end

		i = i + 1
	end

	local effect = DragonBones.new(self.fx_name_, {
		callback = function ()
			self.fxGroup:addChild(effect)
			effect:play(self.animation_name1_, 1, function ()
				effect:play(self.animation_name2_, 0)
			end)

			local action = TimelineLite.new()

			action:call(function ()
				self.itemGroup.scaleX = 0.01
				self.itemGroup.scaleY = 0.01
				self.itemGroup.visible = true
			end):to(self.itemGroup, 0.6, {
				scaleY = 1,
				scaleX = 1
			})
		end
	})

	self.fxGroup:addChild(effect)
end

function RechargeAwardWindow:didClose(params)
	BaseWindow.didClose(self, params)
	xyd:itemFloat(self.items_)
end

return RechargeAwardWindow
