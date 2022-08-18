local BaseWindow = import(".BaseWindow")
local GalaxyBattlePassPreviewWindow = class("GalaxyBattlePassPreviewWindow", BaseWindow)
local IconItem = class("IconItem")

function GalaxyBattlePassPreviewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION)
	self.giftbagID = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION)[1]
	self.icons1 = {}
end

function GalaxyBattlePassPreviewWindow:initWindow()
	self:getUIComponent()
	GalaxyBattlePassPreviewWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function GalaxyBattlePassPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupAction = groupAction
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.item = self.groupAction:NodeByName("item").gameObject
	self.iconPos = self.item:NodeByName("iconPos").gameObject
	self.group1 = self.groupAction:NodeByName("group1").gameObject
	self.scrollerBg1 = self.group1:ComponentByName("scrollerBg1", typeof(UISprite))
	self.itemGroup = self.group1:NodeByName("itemGroup").gameObject
	self.itemGroupGrid = self.group1:ComponentByName("itemGroup", typeof(UIGrid))
	self.labelTitle1 = self.group1:ComponentByName("labelTitle1", typeof(UILabel))
	self.img = self.labelTitle1:ComponentByName("img", typeof(UISprite))
	self.group2 = self.groupAction:NodeByName("group2").gameObject
	self.scrollerBg2 = self.group2:ComponentByName("scrollerBg2", typeof(UISprite))
	self.scroller2 = self.group2:NodeByName("scroller2").gameObject
	self.scrollView2 = self.group2:ComponentByName("scroller2", typeof(UIScrollView))
	self.wrapContent2 = self.scroller2:NodeByName("wrapContent2").gameObject
	self.drag = self.group2:NodeByName("drag").gameObject
	self.labelTitle2 = self.group2:ComponentByName("labelTitle2", typeof(UILabel))
	self.labelVip = self.groupAction:ComponentByName("labelVip", typeof(UILabel))
	self.btnBuy = self.groupAction:NodeByName("btnBuy").gameObject
	self.labelBuy = self.btnBuy:ComponentByName("labelBuy", typeof(UILabel))
end

function GalaxyBattlePassPreviewWindow:initUIComponent()
	self.labelTitle1.text = __("GALAXY_TRIP_TEXT45")
	self.labelTitle2.text = __("GALAXY_TRIP_TEXT46")
	self.labelVip.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftbagID) .. " " .. __("VIP EXP")
	self.labelBuy.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftbagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftbagID))
	local wrapContent = self.scroller2:ComponentByName("wrapContent2", typeof(MultiRowWrapContent))
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView2, wrapContent, self.item, IconItem, self)

	self:updateContent()
end

function GalaxyBattlePassPreviewWindow:updateContent()
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftbagID)
	local awards = xyd.tables.giftTable:getAwards(self.giftID)

	for i = 1, #awards do
		if awards[i][1] ~= 8 and xyd.tables.itemTable:getType(awards[i][1]) ~= 12 then
			local params = {
				show_has_num = true,
				hideText = false,
				scale = 0.6481481481481481,
				uiRoot = self.itemGroup,
				itemID = awards[i][1],
				num = awards[i][2]
			}

			if not self.icons1[i] then
				self.icons1[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.icons1[i]:setInfo(params)
			end
		end
	end

	local datas = {}
	local ids = xyd.tables.galaxyTripBattlepassTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])

		dump(id)
		dump(xyd.tables.galaxyTripBattlepassTable:getPayAwards(id))

		local payAwards = xyd.tables.galaxyTripBattlepassTable:getPayAwards(id)

		for j = 1, #payAwards do
			if not datas[payAwards[j][1]] then
				datas[payAwards[j][1]] = 0
			end

			datas[payAwards[j][1]] = datas[payAwards[j][1]] + payAwards[j][2]
		end
	end

	local realDatas = {}

	for key, value in pairs(datas) do
		table.insert(realDatas, {
			key,
			value
		})
	end

	self.multiWrap_:setInfos(realDatas, {})
	self.multiWrap_:resetPosition()
	self.scrollView2:ResetPosition()
end

function GalaxyBattlePassPreviewWindow:register()
	UIEventListener.Get(self.btnBuy).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftbagID)
	end

	self.eventProxy_:addEventListener(xyd.event.RECHARGE, function ()
		xyd.closeWindow(self.name_)
	end)
end

function GalaxyBattlePassPreviewWindow:willClose()
	BaseWindow.willClose(self)
end

function IconItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:getUIComponent()
end

function IconItem:getUIComponent()
	self.iconPos = self.go:NodeByName("iconPos").gameObject
end

function IconItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)

	local params = {
		show_has_num = true,
		hideText = false,
		scale = 0.6481481481481481,
		uiRoot = self.iconPos,
		itemID = self.data[1],
		num = self.data[2],
		dragScrollView = self.parent.scrollView2
	}

	if not self.icon then
		self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	else
		self.icon:setInfo(params)
	end
end

function IconItem:getGameObject()
	return self.go
end

return GalaxyBattlePassPreviewWindow
