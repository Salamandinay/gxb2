local BaseWindow = import(".BaseWindow")
local SkillIcon = import("app.components.SkillIcon")
local AttrLabel = import("app.components.AttrLabel")
local FullOrderLevelUpWindow = class("FullOrderLevelUpWindow", BaseWindow)

function FullOrderLevelUpWindow:ctor(name, params)
	FullOrderLevelUpWindow.super.ctor(self, name, params)

	self.partner_ = params.partner
	self.fakeUseRes = params.fakeUseRes
	self.fakeLev = params.fakeLev
	self.levUpCallback = params.levUpCallback
	self.backpack_ = xyd.models.backpack
end

function FullOrderLevelUpWindow:initWindow()
	FullOrderLevelUpWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initResItem()
	self:initAttrLabel()
	self:register()
end

function FullOrderLevelUpWindow:getUIComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("content").gameObject
	local title = content:NodeByName("title").gameObject
	self.closeBtn = title:NodeByName("closeBtn").gameObject
	self.titleName = title:ComponentByName("titleName", typeof(UILabel))
	local topGroup = content:NodeByName("topGroup").gameObject

	for i = 1, 2 do
		self["resItem" .. i] = topGroup:NodeByName("resItem" .. i).gameObject
	end

	local middle = content:NodeByName("middle").gameObject
	self.attrChangeGroup = middle:NodeByName("attrChangeGroup").gameObject
	self.attrChangeGroupGrid = self.attrChangeGroup:GetComponent(typeof(UIGrid))
	local costGroup = content:NodeByName("bottomGroup/costGroup").gameObject

	for i = 1, 2 do
		self["costItem" .. i] = costGroup:NodeByName("costItem" .. i).gameObject
	end

	self.btnLevelUp = content:NodeByName("btnLevelUp").gameObject
	self.btnLevelUpLable = self.btnLevelUp:ComponentByName("button_label", typeof(UILabel))
end

function FullOrderLevelUpWindow:initUIComponent()
	if not self.partner_ then
		xyd.WindowManager:get():closeWindow(self)

		return
	end

	self.titleName.text = __("ONE_KEY_UPLEVEL_TITLE")
	self.btnLevelUpLable.text = __("LEV_UP")
end

function FullOrderLevelUpWindow:initResItem()
	self.owns = {
		self.backpack_:getItemNumByID(xyd.ItemID.MANA),
		self.backpack_:getItemNumByID(xyd.ItemID.PARTNER_EXP)
	}

	for i = 1, 2 do
		self["resItem" .. i]:ComponentByName("labelRes", typeof(UILabel)).text = xyd.getRoughDisplayNumber(self.owns[i])
	end

	local ownMANA = xyd.models.backpack:getItemNumByID(xyd.ItemID.MANA) - self.fakeUseRes[xyd.ItemID.MANA]
	local ownEXP = xyd.models.backpack:getItemNumByID(xyd.ItemID.PARTNER_EXP) - self.fakeUseRes[xyd.ItemID.PARTNER_EXP]
	local costMANA, costEXP = nil
	local maxLevel = self.partner_:getMaxLev(self.partner_:getGrade(), self.partner_:getAwake())
	local partnerLevel = self.partner_:getLevel()

	while partnerLevel < maxLevel do
		costMANA = xyd.tables.expPartnerTable:getAllMoney(maxLevel) - xyd.tables.expPartnerTable:getAllMoney(partnerLevel)
		costEXP = xyd.tables.expPartnerTable:getAllExp(maxLevel) - xyd.tables.expPartnerTable:getAllExp(partnerLevel)

		if costMANA <= ownMANA and costEXP <= ownEXP then
			break
		end

		maxLevel = maxLevel - 1
	end

	self.maxLev = maxLevel
	self.costs = {
		costMANA,
		costEXP
	}

	for i = 1, 2 do
		self["costItem" .. i]:ComponentByName("labelCost", typeof(UILabel)).text = xyd.getRoughDisplayNumber(self.costs[i])
	end
end

function FullOrderLevelUpWindow:initAttrLabel()
	NGUITools.DestroyChildren(self.attrChangeGroup.transform)
	AttrLabel.new(self.attrChangeGroup, "change", {
		"LEV",
		self.partner_:getLevel(),
		self.maxLev
	})

	local attr_enums = {
		"power",
		"hp",
		"atk",
		"arm"
	}
	local attrs = self.partner_:getBattleAttrs()
	local new_attrs = self.partner_:getBattleAttrs({
		level = self.maxLev,
		self.partner_:getGrade()
	})

	for _, v in ipairs(attr_enums) do
		local params = {
			v,
			attrs[v],
			new_attrs[v]
		}
		params[1] = string.upper(params[1])

		AttrLabel.new(self.attrChangeGroup, "change", params)
	end

	self.attrChangeGroupGrid:Reposition()
end

function FullOrderLevelUpWindow:register()
	FullOrderLevelUpWindow.super.register(self)

	UIEventListener.Get(self.btnLevelUp).onClick = handler(self, self.onclickBtnLevelUp)
end

function FullOrderLevelUpWindow:onclickBtnLevelUp()
	if self.owns[1] < self.costs[1] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.MANA)))

		return
	end

	if self.owns[2] < self.costs[2] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.PARTNER_EXP)))

		return
	end

	local timeStamp = xyd.db.misc:getValue("full_order_level_up_time_stamp")

	if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
		xyd.WindowManager.get():openWindow("gamble_tips_window", {
			type = "full_order_level_up",
			wndType = self.curWindowType_,
			callback = function ()
				self.partner_:levUp(self.maxLev - self.partner_:getLevel() + self.fakeLev)

				if self.levUpCallback then
					self.levUpCallback()
				end

				self:close()
			end,
			text = __("ONE_KEY_UPLEVEL_HINT")
		})
	else
		self.partner_:levUp(self.maxLev - self.partner_:getLevel() + self.fakeLev)

		if self.levUpCallback then
			self.levUpCallback()
		end

		self:close()
	end
end

return FullOrderLevelUpWindow
