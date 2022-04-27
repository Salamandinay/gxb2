local BaseWindow = import(".BaseWindow")
local ResourceMergeWindow = class("ResourceMergeWindow", BaseWindow)

function ResourceMergeWindow:ctor(name, params)
	self.items = params.items
	self.autoComposeArr = params.numArr
	self.needCoin = params.needCoin
	self.newEquipGetProcessArr = params.newEquipGetProcessArr

	ResourceMergeWindow.super.ctor(self, name, params)
end

function ResourceMergeWindow:initWindow()
	ResourceMergeWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
	self:initData()
end

function ResourceMergeWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelDesc1 = self.groupAction:ComponentByName("labelDesc1", typeof(UILabel))
	self.noBtn = self.groupAction:NodeByName("noBtn").gameObject
	self.no_button_label = self.noBtn:ComponentByName("button_label", typeof(UILabel))
	self.yesBtn = self.groupAction:NodeByName("yesBtn").gameObject
	self.yes_button_label = self.yesBtn:ComponentByName("button_label", typeof(UILabel))
	self.bg06 = self.groupAction:ComponentByName("bg06", typeof(UISprite))
	self.imgGold = self.bg06:ComponentByName("imgGold", typeof(UISprite))
	self.labelCost = self.bg06:ComponentByName("labelCost", typeof(UILabel))
	self.groupBottomBg = self.groupAction:ComponentByName("groupBottomBg", typeof(UISprite))
	self.showCon = self.groupAction:NodeByName("showCon").gameObject
	self.showConScroller = self.showCon:NodeByName("showConScroller").gameObject
	self.showConScroller_UIScrollView = self.showCon:ComponentByName("showConScroller", typeof(UIScrollView))
	self.largeBtnCon = self.showConScroller:NodeByName("largeBtnCon").gameObject
	self.drag = self.showCon:NodeByName("drag").gameObject
end

function ResourceMergeWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.noBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.yesBtn.gameObject).onClick = handler(self, function ()
		if self:costEnough() == false then
			xyd.alertTips(__("COMPOSE_EQUIP_NO_MANA"))

			return
		end

		local msg = messages_pb:compose_multi_equip_req()

		for i in pairs(self.newEquipGetProcessArr) do
			local itemmsg = messages_pb:items_info()

			if self.newEquipGetProcessArr[i] > 0 then
				itemmsg.item_id = self.items[i].id
				itemmsg.item_num = self.newEquipGetProcessArr[i]

				table.insert(msg.items, itemmsg)
			end
		end

		xyd.Backend.get():request(xyd.mid.COMPOSE_MULTI_EQUIP, msg)
	end)
end

function ResourceMergeWindow:addTitle()
	self.labelWinTitle.text = __("ONE_KEY_COMPOSE")
end

function ResourceMergeWindow:initUIComponent()
	self.labelDesc1.text = __("ONE_KEY_COMPOSE_TEXT")
	self.no_button_label.text = __("NO")
	self.yes_button_label.text = __("YES")
	self.labelCost.text = tostring(xyd.getRoughDisplayNumber(self.needCoin))

	if self:costEnough() == false then
		self.labelCost.color = Color.New2(4278190335.0)
	else
		self.labelCost.color = Color.New2(960513791)
	end
end

function ResourceMergeWindow:initData()
	for i in pairs(self.autoComposeArr) do
		if self.autoComposeArr[i] > 0 then
			local item = {
				noClick = true,
				itemID = self.items[i].id,
				num = self.autoComposeArr[i],
				uiRoot = self.largeBtnCon.gameObject
			}
			local icon = xyd.getItemIcon(item)

			icon:AddUIDragScrollView()
		end
	end

	self.showConScroller_UIScrollView:ResetPosition()
end

function ResourceMergeWindow:costEnough()
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.MANA) < self.needCoin then
		return false
	else
		return true
	end
end

return ResourceMergeWindow
