local TreasureBackWindow = class("TreasureBackWindow", import(".BaseWindow"))

function TreasureBackWindow:ctor(name, params)
	TreasureBackWindow.super.ctor(self, name, params)

	self.item_id = params.item_id
	self.partner_id = params.partner_id
	self.show_item_id = 5101
end

function TreasureBackWindow:initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function TreasureBackWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.titleLabel = self.groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.materialGroup1 = self.groupAction:NodeByName("materialGroup1").gameObject
	self.materialCountLabel1 = self.materialGroup1:ComponentByName("materialCountLabel", typeof(UILabel))
	self.materialGroup2 = self.groupAction:NodeByName("materialGroup2").gameObject
	self.materialCountLabel2 = self.materialGroup2:ComponentByName("materialCountLabel", typeof(UILabel))
	self.descLabel = self.groupAction:ComponentByName("descLabel", typeof(UILabel))
	self.backBtn = self.groupAction:NodeByName("backBtn").gameObject
	self.backBtn_label = self.backBtn:ComponentByName("label", typeof(UILabel))
	self.iconGroup = self.backBtn:NodeByName("iconGroup").gameObject
	self.btnIcon = self.iconGroup:ComponentByName("btnIcon", typeof(UISprite))
	self.btnIconNum = self.iconGroup:ComponentByName("btnIconNum", typeof(UILabel))
	self.itemGroup = self.groupAction:NodeByName("itemGroup").gameObject
	self.itemGroup_UILayout = self.groupAction:ComponentByName("itemGroup", typeof(UILayout))
	self.helpBtn = self.groupAction:NodeByName("helpBtn").gameObject
end

function TreasureBackWindow:layout()
	self.titleLabel.text = __("RETURN_TREASURE_WINDOW")
	self.backBtn_label.text = __("RETURN_TREASURE_TEXT01")

	if xyd.Global.lang == "de_de" then
		self.backBtn_label.width = 160

		self.backBtn_label.gameObject:X(24)
	end

	self.descLabel.text = __("RETURN_TREASURE_TEXT02")

	self:initUpItems()
	self:initDownItems()
	self:initBtnIcon()
end

function TreasureBackWindow:registerEvent()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "RETURN_TREASURE_HELP"
		})
	end)
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, function ()
		local cost = xyd.tables.miscTable:split2num("return_treasure_cost", "value", "#")

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		xyd.alert(xyd.AlertType.YES_NO, __("RETURN_TREASURE_TIPS"), function (yes_no)
			if yes_no then
				local msg = messages_pb:treasure_return_req()
				msg.partner_id = self.partner_id

				xyd.Backend.get():request(xyd.mid.TREASURE_RETURN, msg)
			end
		end)
	end)

	self.eventProxy_:addEventListener(xyd.event.TREASURE_RETURN, handler(self, self.returnBack))
end

function TreasureBackWindow:returnBack()
	local all_cost_yet = xyd.tables.equipTable:getTreasureCost(self.item_id)
	local coefficient = xyd.tables.miscTable:getNumber("return_treasure_ratio", "value") or 1

	for i in pairs(all_cost_yet) do
		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = all_cost_yet[i][1],
				item_num = math.floor(all_cost_yet[i][2] * coefficient)
			}
		})
	end

	self:close()
end

function TreasureBackWindow:initUpItems()
	local params1 = {
		itemID = self.item_id,
		uiRoot = self.materialGroup1.gameObject
	}
	local left_icon = xyd.getItemIcon(params1)
	local params2 = {
		noClick = true,
		itemID = self.show_item_id,
		uiRoot = self.materialGroup2.gameObject
	}
	local right_icon = xyd.getItemIcon(params2)
end

function TreasureBackWindow:initDownItems()
	local all_cost_yet = xyd.tables.equipTable:getTreasureCost(self.item_id)
	local coefficient = xyd.tables.miscTable:getNumber("return_treasure_ratio", "value") or 1

	for i in pairs(all_cost_yet) do
		local params1 = {
			scale = 0.9259259259259259,
			itemID = all_cost_yet[i][1],
			num = math.floor(all_cost_yet[i][2] * coefficient),
			uiRoot = self.itemGroup.gameObject
		}

		xyd.getItemIcon(params1)
	end

	self.itemGroup_UILayout:Reposition()
end

function TreasureBackWindow:initBtnIcon()
	local cost = xyd.tables.miscTable:split2num("return_treasure_cost", "value", "#")

	xyd.setUISpriteAsync(self.btnIcon, nil, "icon_" .. cost[1], nil, , )

	self.btnIconNum.text = cost[2]

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		self.btnIconNum.color = Color.New2(3422556671.0)
		self.btnIconNum.effectColor = Color.New2(4294967295.0)
	else
		self.btnIconNum.color = Color.New2(4294967295.0)
		self.btnIconNum.effectColor = Color.New2(1012112383)
	end
end

return TreasureBackWindow
