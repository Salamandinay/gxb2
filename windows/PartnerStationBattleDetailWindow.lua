local PartnerStationBattleDetailWindow = class("PartnerStationBattleDetailWindow", import(".BaseWindow"))
local PartnerStationBattleDetailItem = class("PartnerStationBattleDetailItem", import("app.components.BaseComponent"))
local AttrLabel = import("app.components.AttrLabel")
local HeroIcon = import("app.components.HeroIcon")

function PartnerStationBattleDetailItem:ctor(parentGo, params)
	PartnerStationBattleDetailItem.super.ctor(self, parentGo)

	self.info = params.info

	self:registerEvent()
	self:layout()
end

function PartnerStationBattleDetailItem:getPrefabPath()
	return "Prefabs/Components/partner_station_battle_detail_item"
end

function PartnerStationBattleDetailItem:initUI()
	PartnerStationBattleDetailItem.super.initUI(self)

	local go = self.go
	self.attr = go:NodeByName("attr").gameObject
	self.labelLife = self.attr:ComponentByName("labelLife", typeof(UILabel))
	self.labelAtk = self.attr:ComponentByName("labelAtk", typeof(UILabel))
	self.labelDef = self.attr:ComponentByName("labelDef", typeof(UILabel))
	self.labelSpeed = self.attr:ComponentByName("labelSpeed", typeof(UILabel))
	self.btnAttrDetail = self.attr:NodeByName("btnAttrDetail").gameObject
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.labelName = go:ComponentByName("labelName", typeof(UILabel))
end

function PartnerStationBattleDetailItem:registerEvent()
	UIEventListener.Get(self.btnAttrDetail).onClick = function ()
		local wnd = xyd.WindowManager.get():getWindow("partner_station_battle_detail_window")

		if wnd then
			wnd:updateGroupAllAttr(self.info)
			wnd:setGroupAttrVisible(true)
		end

		local wnd2 = xyd.WindowManager.get():getWindow("activity_sports_party_detail_window")

		if wnd2 then
			xyd.WindowManager.get():openWindow("partner_info", {
				partner = self.info
			})
		end
	end
end

function PartnerStationBattleDetailItem:layout()
	local wnd = xyd.WindowManager.get():getWindow("partner_station_battle_detail_window")
	local partner = self.info
	local info = partner:getInfo()
	local attrs = partner:getBattleAttrs()
	local icon = HeroIcon.new(self.groupIcon)
	info.noClick = true

	icon:setInfo(info)
	icon:setScale(0.76)

	if wnd then
		icon:setPetFrame(wnd:getPetId())
	end

	self.labelName.text = xyd.tables.partnerTable:getName(info.tableID)
	self.labelLife.text = ": " .. tostring(math.floor(attrs.hp))
	self.labelAtk.text = ": " .. tostring(math.floor(attrs.atk))
	self.labelDef.text = ": " .. tostring(math.floor(attrs.arm))
	self.labelSpeed.text = ": " .. tostring(math.floor(attrs.spd))
end

function PartnerStationBattleDetailWindow:ctor(name, params)
	PartnerStationBattleDetailWindow.super.ctor(self, name, params)

	self.partnerInfos = {}
	self.petId = 0

	for _, info in ipairs(params.partner_infos) do
		if info then
			table.insert(self.partnerInfos, info)
		end
	end

	self.petId = params.pet or 0
end

function PartnerStationBattleDetailWindow:initWindow()
	PartnerStationBattleDetailWindow.super.initWindow(self)
	self:getUIComponents()
	self:layout()
	self:registerEvent()
end

function PartnerStationBattleDetailWindow:layout()
	for _, info in ipairs(self.partnerInfos) do
		local item = PartnerStationBattleDetailItem.new(self.groupMain, {
			info = info
		})
	end
end

function PartnerStationBattleDetailWindow:getUIComponents()
	local go = self.window_
	self.imgClick = go:NodeByName("imgClick").gameObject
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.labelWinTitle = go:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.groupAttr = go:NodeByName("groupAttr").gameObject
	self.groupAllAttr = self.groupAttr:NodeByName("groupAllAttr").gameObject
end

function PartnerStationBattleDetailWindow:registerEvent()
	PartnerStationBattleDetailWindow.super.register(self)

	UIEventListener.Get(self.imgClick).onClick = function ()
		self:setGroupAttrVisible(false)
	end
end

function PartnerStationBattleDetailWindow:updateGroupAllAttr(partnerInfo)
	local attrs = partnerInfo:getBattleAttrs()
	local bt = xyd.tables.dBuffTable

	NGUITools.DestroyChildren(self.groupAllAttr.transform)

	for _, key in pairs(xyd.AttrSuffix) do
		local value = math.floor(attrs[key] or 0)

		if bt:isShowPercent(key) then
			local factor = tonumber(bt:getFactor(key))
			value = value * 100 / tonumber(bt:getFactor(key))
			value = math.floor(value)
			value = tostring(value) .. "%"
		end

		local label = AttrLabel.new(self.groupAllAttr, "large", {
			string.upper(key),
			value
		})
	end

	self.groupAllAttr:GetComponent(typeof(UILayout)):Reposition()
end

function PartnerStationBattleDetailWindow:setGroupAttrVisible(flag)
	self.groupAttr:SetActive(flag)
	self.imgClick:SetActive(flag)
end

function PartnerStationBattleDetailWindow:getPetId()
	return self.petId
end

return PartnerStationBattleDetailWindow
