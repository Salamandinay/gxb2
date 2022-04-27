local BaseWindow = import(".BaseWindow")
local PartnerSlotIncreaseWindow = class("PartnerSlotIncreaseWindow", BaseWindow)

function PartnerSlotIncreaseWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	if params then
		self.descText = params.descText
	end
end

function PartnerSlotIncreaseWindow:initWindow()
	PartnerSlotIncreaseWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initLayout()
end

function PartnerSlotIncreaseWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.desLabel_ = groupAction:ComponentByName("desLabel_", typeof(UILabel))
	self.btnGroup = groupAction:NodeByName("btnGroup").gameObject

	for i = 0, 3 do
		self["jumpBtn_" .. i] = self.btnGroup:NodeByName("jumpBtn_" .. i).gameObject
	end

	self.comfirmBtn_ = groupAction:NodeByName("comfirmBtn_").gameObject
end

function PartnerSlotIncreaseWindow:initUIComponent()
	self.desLabel_.text = __("SLOT_INCREASE_TITLE")

	if self.descText then
		self.desLabel_.text = self.descText
	end

	self.comfirmBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("SURE")

	for i = 0, 3 do
		self["jumpBtn_" .. i]:ComponentByName("button_label", typeof(UILabel)).text = __("SLOT_INCREASE_TEXT" .. i)

		UIEventListener.Get(self["jumpBtn_" .. i]).onClick = function ()
			self:onJumpBtn(i)
		end
	end

	UIEventListener.Get(self.comfirmBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function PartnerSlotIncreaseWindow:initLayout()
	local buyTime = xyd.models.slot:getBuySlotTimes()
	local buyTimeLimit = xyd.tables.miscTable:getNumber("herobag_buy_limit", "value")

	if buyTime < buyTimeLimit then
		self.jumpBtn_1:SetActive(true)
	else
		self.jumpBtn_1:SetActive(false)
	end

	local vipLev = xyd.models.backpack:getVipLev()
	local maxVipLev = xyd.models.backpack:getMaxVipLev()

	if vipLev < maxVipLev then
		self.jumpBtn_3:SetActive(true)
	else
		self.jumpBtn_3:SetActive(false)
	end

	self.btnGroup:GetComponent(typeof(UILayout)):Reposition()
end

function PartnerSlotIncreaseWindow:onJumpBtn(index)
	if index == 0 then
		local wnd = xyd.WindowManager.get():getWindow("altar_window")

		if wnd then
			wnd:showTab(1)
			wnd.tabBar:setTabActive(1, true)

			local params = {
				main_window = true,
				loading_window = true,
				guide_window = true,
				altar_window = true
			}

			xyd.WindowManager.get():closeAllWindows(params, false)

			return
		end

		xyd.WindowManager.get():openWindow("altar_window", {}, function ()
			local params = {
				main_window = true,
				loading_window = true,
				guide_window = true,
				altar_window = true
			}

			xyd.WindowManager.get():closeAllWindows(params, false)
		end)
	elseif index == 1 then
		xyd.WindowManager.get():openWindow("slot_window", {}, function ()
			local win = xyd.WindowManager.get():getWindow("slot_window")

			if win then
				win:addSlotSpace()
			end

			local params = {
				guide_window = true,
				loading_window = true,
				alert_window = true,
				slot_window = true,
				main_window = true
			}

			xyd.WindowManager.get():closeAllWindows(params, false)
		end)
	elseif index == 2 then
		xyd.WindowManager.get():openWindow("shenxue_window", {}, function ()
			local params = {
				main_window = true,
				loading_window = true,
				shenxue_window = true,
				guide_window = true
			}

			xyd.WindowManager.get():closeAllWindows(params, false)
		end)
	elseif index == 3 then
		xyd.WindowManager.get():openWindow("vip_window", {
			show_benefit = true
		})
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

return PartnerSlotIncreaseWindow
