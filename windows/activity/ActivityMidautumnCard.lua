local ActivityContent = import(".ActivityContent")
local ActivityMidautumnCard = class("ActivityMidautumnCard", ActivityContent)
local CountDown = require("app.components.CountDown")

function ActivityMidautumnCard:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.giftBagID = self.activityData.detail.charges[1].table_id
end

function ActivityMidautumnCard:getPrefabPath()
	return "Prefabs/Windows/activity/activity_midautumn_card"
end

function ActivityMidautumnCard:initUI()
	self:getUIComponent()
	ActivityMidautumnCard.super.initUI(self)

	self.giftBagID = self.activityData.detail.charges[1].table_id

	self:initUIComponet()
	self:onRegisterEvent()
end

function ActivityMidautumnCard:getUIComponent()
	local go = self.go
	self.bg = go:ComponentByName("bg", typeof(UITexture))
	self.imgTitle = go:ComponentByName("imgTitle", typeof(UISprite))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.buttomGroup = go:NodeByName("buttomGroup").gameObject
	self.label1 = self.buttomGroup:ComponentByName("label1", typeof(UILabel))
	self.label2 = self.buttomGroup:ComponentByName("label2", typeof(UILabel))
	self.limitLabel = self.buttomGroup:ComponentByName("limitLabel", typeof(UILabel))
	self.VIPLabel = self.buttomGroup:ComponentByName("VIPLabel", typeof(UILabel))
	self.iconGroup = self.buttomGroup:NodeByName("iconGroup").gameObject
	self.iconTag = self.buttomGroup:NodeByName("iconTag").gameObject
	self.btn = self.buttomGroup:NodeByName("button").gameObject
	self.btnLabel = self.btn:ComponentByName("label", typeof(UILabel))
	self.dayGroup = self.buttomGroup:NodeByName("dayGroup").gameObject

	for i = 1, 4 do
		self["icon_" .. i] = self.dayGroup:ComponentByName("icon" .. i, typeof(UISprite))
		self["icon" .. i .. "Label2"] = self["icon_" .. i].gameObject:ComponentByName("icon" .. i .. "_Label2", typeof(UILabel))
	end

	self.levLabel = self.icon_4:ComponentByName("icon4_Label4", typeof(UILabel))
end

function ActivityMidautumnCard:resizeToParent()
	ActivityMidautumnCard.super.resizeToParent(self)
	self:resizePosY(self.bg, 30, -5)
	self:resizePosY(self.imgTitle, -180, -260)
	self:resizePosY(self.buttomGroup, -625, -730)
end

function ActivityMidautumnCard:initUIComponet()
	self:setText()
	self:setState()
	self:setIcon()
end

function ActivityMidautumnCard:onRegisterEvent()
	UIEventListener.Get(self.btn).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "BLACK_CARD_TEXT02"
		})
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityData))
end

function ActivityMidautumnCard:setText()
	self.label1.text = __("BLACK_CARD_TEXT01")
	self.label2.text = __("BLACK_CARD_TEXT03")

	if xyd.Global.lang == "fr_fr" then
		self.levLabel.text = "Niv."
	end

	xyd.setUISpriteAsync(self.imgTitle, nil, "activity_midautumn_card2_" .. xyd.Global.lang)

	self.btnLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.giftBagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftBagID)
	self.VIPLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagID) .. " VIP EXP"
end

function ActivityMidautumnCard:setState()
	if xyd.tables.giftBagTable:getBuyLimit(self.giftBagID) - self.activityData.detail.charges[1].buy_times <= 0 then
		self.btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.btn)
	else
		self.btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

		xyd.applyChildrenOrigin(self.btn)
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", xyd.tables.giftBagTable:getBuyLimit(self.giftBagID) - self.activityData.detail.charges[1].buy_times)
end

function ActivityMidautumnCard:setIcon()
	self.iconArr = {}
	local ids = xyd.tables.activityBlackCardTable:getIDs()

	for id in ipairs(ids) do
		local award = xyd.tables.activityBlackCardTable:getAward(id)
		local iconSource = xyd.tables.itemTable:getIcon(award[1])
		local icon = xyd.getItemIcon({
			show_has_num = true,
			itemID = award[1],
			num = award[2] * xyd.tables.giftBagTable:getDays(self.giftBagID),
			uiRoot = self.iconGroup,
			scale = Vector3(0.6018518518518519, 0.6018518518518519, 0.6018518518518519)
		})

		table.insert(self.iconArr, icon)
		xyd.setUISpriteAsync(self["icon_" .. id], nil, iconSource)

		self["icon" .. id .. "Label2"].text = award[2]
	end

	self.iconGroup:GetComponent(typeof(UILayout)):Reposition()

	for id in ipairs(ids) do
		local iconType = xyd.tables.activityBlackCardTable:getType(id)

		if iconType and iconType == 1 then
			local tmp = NGUITools.AddChild(self.buttomGroup.gameObject, self.iconTag.gameObject)
			local iconGroup_x = self.iconGroup.transform.localPosition.x
			local iconGroup_y = self.iconGroup.transform.localPosition.y

			tmp:X(iconGroup_x + self.iconArr[id]:getIconRoot().transform.localPosition.x + 32.5 - 5)
			tmp:Y(iconGroup_y + self.iconArr[id]:getIconRoot().transform.localPosition.y + 32.5 - 4)
			tmp:SetLocalScale(0.6, 0.6, 0.6)

			local tagSprite = tmp:GetComponent(typeof(UISprite))

			if xyd.Global.lang == "fr_fr" then
				xyd.setUISpriteAsync(tagSprite, nil, "activity_midautumn_card_jb_niv")
			else
				xyd.setUISpriteAsync(tagSprite, nil, "activity_midautumn_card_jb_lv")
			end
		end
	end
end

function ActivityMidautumnCard:onRecharge(event)
	if xyd.tables.giftBagTable:getActivityID(event.data.giftbag_id) ~= xyd.ActivityID.BLACK_CARD then
		return
	end

	self:setState()
end

function ActivityMidautumnCard:onActivityData()
	self:setState()
end

return ActivityMidautumnCard
