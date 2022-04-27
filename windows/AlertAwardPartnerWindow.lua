local AlertAwardWindow = import(".AlertAwardWindow")
local AlertAwardPartnerWindow = class("AlertAwardPartnerWindow", AlertAwardWindow)
local HeroIcon = require("app.components.HeroIcon")

function AlertAwardPartnerWindow:createItem(data)
	local type_ = xyd.tables.itemTable:getType(data.item_id)
	local itemIcon = HeroIcon.new(self.groupItem_)

	if data.partnerID then
		local p = xyd.models.slot:getPartner(data.partnerID)
		local pInfo = p:getInfo()

		function pInfo.callback()
			xyd.WindowManager.get():openWindow("partner_info", {
				partner = p
			})
		end

		pInfo.noClickSelected = true

		itemIcon:setInfo(pInfo)
	end

	return itemIcon
end

function AlertAwardPartnerWindow:initData()
end

return AlertAwardPartnerWindow
