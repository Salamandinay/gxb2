local TimeCloisterCardPreivewWindow = class("TimeCloisterCardPreivewWindow", import(".BaseWindow"))
local CardItem = class("CardItem", import("app.common.ui.FixedMultiWrapContentItem"))
local cardTable = xyd.tables.timeCloisterCardTable

function CardItem:initUI()
	self.icon = self.go:ComponentByName("icon", typeof(UISprite))
	self.nameBg = self.go:ComponentByName("nameBg", typeof(UISprite))
	self.nameLabel = self.go:ComponentByName("nameLabel", typeof(UILabel))
	self.descLabel = self.go:ComponentByName("descLabel", typeof(UILabel))
	self.bgUISprite = self.go:ComponentByName("bg", typeof(UISprite))

	if xyd.Global.lang == "fr_fr" then
		self.nameLabel.fontSize = 16
	end

	UIEventListener.Get(self.go).onClick = function ()
		if self.data.card_id ~= 0 then
			xyd.WindowManager.get():openWindow("time_cloister_card_detail_window", {
				card_id = self.data.card_id
			})
		end
	end

	xyd.models.timeCloisterModel:changeCommonCardUI(self.go)
end

function CardItem:updateInfo()
	self.nameLabel.text = cardTable:getName(self.data.card_id)
	self.descLabel.text = cardTable:getDesc(self.data.card_id)
	local img = xyd.tables.timeCloisterCardTable:getImg(self.data.card_id)

	xyd.setUISpriteAsync(self.icon, nil, img)

	if self.data.unlock then
		xyd.applyChildrenOrigin(self.go)
	else
		xyd.applyChildrenGrey(self.go)
	end
end

function TimeCloisterCardPreivewWindow:ctor(name, params)
	self.type = params.type
	self.types = {}

	if self.type == xyd.TimeCloisterCardType.SUPPLY then
		self.types = {
			self.type,
			xyd.TimeCloisterCardType.DRESS_MISSION_EVENT
		}
	elseif self.type == xyd.TimeCloisterCardType.BATTLE then
		self.types = {
			self.type,
			xyd.TimeCloisterCardType.ENCOUNTER_BATTLE
		}
	elseif self.type == xyd.TimeCloisterCardType.EVENT then
		self.types = {
			self.type,
			xyd.TimeCloisterCardType.PLOT_EVENT
		}
	end

	self.hideUnlock = false
	self.cloister = params.cloister

	TimeCloisterCardPreivewWindow.super.ctor(self, name, params)
end

function TimeCloisterCardPreivewWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function TimeCloisterCardPreivewWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller_", typeof(UIScrollView))
	local itemGroup = self.scrollView:ComponentByName("itemGroup", typeof(UIWrapContent))
	local itemContainer = groupAction:NodeByName("time_cloister_card").gameObject
	self.wrapContent_ = import("app.common.ui.FixedMultiWrapContent").new(self.scrollView, itemGroup, itemContainer, CardItem, self)
	local groupHide = groupAction:NodeByName("groupHide").gameObject
	self.hideBtn = groupHide:NodeByName("hideBtn").gameObject
	self.icon = groupHide:NodeByName("icon").gameObject
	self.hideLabel = groupHide:ComponentByName("hideLabel", typeof(UILabel))
end

function TimeCloisterCardPreivewWindow:layout()
	local titleText = {
		__("TIME_CLOISTER_TEXT25"),
		__("TIME_CLOISTER_TEXT26"),
		__("TIME_CLOISTER_TEXT27")
	}
	self.titleLabel.text = titleText[self.type]
	self.hideLabel.text = __("TIME_CLOISTER_TEXT28")

	self.icon:SetActive(self.hideUnlock)

	if xyd.models.timeCloisterModel:getCardInfo() then
		self:initContent()
	end
end

function TimeCloisterCardPreivewWindow:initContent()
	self.allList = {}
	self.unlockList = {}
	local cardInfo = xyd.models.timeCloisterModel:getCardInfo()
	local cards = xyd.tables.timeCloisterTable:getCloisterCards(self.cloister)

	for id, value in pairs(cardInfo) do
		local type = xyd.tables.timeCloisterCardTable:getType(id)

		if type == xyd.TimeCloisterCardType.PLOT_EVENT then
			type = xyd.TimeCloisterCardType.EVENT
		end

		if xyd.arrayIndexOf(self.types, type) > -1 and xyd.arrayIndexOf(cards, tonumber(id)) > -1 then
			local card_id = (value == 1 or value == 2) and id or value

			table.insert(self.allList, {
				card_id = card_id,
				unlock = value ~= 2
			})

			if value ~= 2 then
				table.insert(self.unlockList, {
					unlock = true,
					card_id = card_id
				})
			end
		end
	end

	table.sort(self.allList, function (a, b)
		return a.card_id < b.card_id
	end)
	table.sort(self.unlockList, function (a, b)
		return a.card_id < b.card_id
	end)
	self.wrapContent_:setInfos(self.allList, {})
end

function TimeCloisterCardPreivewWindow:onGetCardInfo()
	self:initContent()
end

function TimeCloisterCardPreivewWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_CARD_INFO, handler(self, self.onGetCardInfo))

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.hideBtn).onClick = function ()
		self.hideUnlock = not self.hideUnlock

		self.icon:SetActive(self.hideUnlock)

		if self.hideUnlock then
			self.wrapContent_:setInfos(self.unlockList, {
				keepPosition = true
			})
		else
			self.wrapContent_:setInfos(self.allList, {
				keepPosition = true
			})
		end
	end
end

return TimeCloisterCardPreivewWindow
