local FoolClockGiftbag = class("FoolClockGiftbag", import(".ActivityContent"))
local FoolClockGiftbagItem = class("FoolClockGiftbagItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local FestivalChoseTable = xyd.tables.activityFestivalChoseTable
local ITEM_HEIGHT = 328

function FoolClockGiftbag:ctor(parentGO, params)
	FoolClockGiftbag.super.ctor(self, parentGO, params)
end

function FoolClockGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/fool_clock_giftbag"
end

function FoolClockGiftbag:resizeToParent()
	FoolClockGiftbag.super.resizeToParent(self)
	self:resizePosY(self.arrowDown, -847.5, -1024.5)
end

function FoolClockGiftbag:initUI()
	self:getUIComponent()
	FoolClockGiftbag.super.initUI(self)
	self:initUIComponent()
end

function FoolClockGiftbag:getUIComponent()
	local go = self.go
	self.textImg = go:ComponentByName("panelLogo/textImg", typeof(UISprite))
	self.groupModel = go:NodeByName("groupModel").gameObject
	self.timeGroup = go:NodeByName("panelLogo/timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.scrollView = go:ComponentByName("scrollView", typeof(UIScrollView))
	self.scrollPanel = go:ComponentByName("scrollView", typeof(UIPanel))
	self.groupItems = self.scrollView:NodeByName("groupItems").gameObject
	self.groupArrow = go:NodeByName("groupArrow").gameObject
	self.arrowUp = self.groupArrow:ComponentByName("arrowUp", typeof(UISprite))
	self.arrowDown = self.groupArrow:ComponentByName("arrowDown", typeof(UISprite))
	self.giftbagItem = go:NodeByName("fool_clock_giftbag_item").gameObject
	self.emptyItem = go:NodeByName("empty_item").gameObject

	self.giftbagItem:SetActive(false)
	self.emptyItem:SetActive(false)
	self.arrowUp:SetActive(false)
	self.arrowDown:SetActive(false)
end

function FoolClockGiftbag:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "fool_clock_giftbag_text_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.timeLabel:X(7)
		self.endLabel:X(-7)
	end

	self.items = {}
	local buyoutList = {}
	local canBuyList = {}

	NGUITools.DestroyChildren(self.groupItems.transform)

	local dBuyTimes = self.activityData:getDiamondBuyTimes()
	local dLimitTImes = xyd.tables.miscTable:getNumber("foolsday_giftlimit", "value") or 1
	local itemParams = {
		item_type = 1,
		buy_times = dBuyTimes,
		limit_times = dLimitTImes
	}

	if dLimitTImes <= dBuyTimes then
		table.insert(buyoutList, itemParams)
	else
		table.insert(canBuyList, itemParams)
	end

	local giftbagIds = FestivalChoseTable:getIDs()

	for i = #giftbagIds, 1, -1 do
		local giftbagId = giftbagIds[i]
		local giftbagData = FestivalChoseTable:getGiftbagData(giftbagId)

		if giftbagData and next(giftbagData) then
			local giftbagCharge = self.activityData:getGiftbagCharges(giftbagId)
			giftbagData.giftbag_id = giftbagId
			giftbagData.item_type = 2
			giftbagData.buy_times = giftbagCharge.buy_times
			giftbagData.limit_times = giftbagCharge.limit_times
			giftbagData.choose_index = giftbagCharge.choose_index

			if giftbagCharge.limit_times <= giftbagCharge.buy_times then
				table.insert(buyoutList, giftbagData)
			else
				table.insert(canBuyList, giftbagData)
			end
		end
	end

	local giftbagList = xyd.arrayMerge(canBuyList, buyoutList)

	for _, data in ipairs(giftbagList) do
		local go = NGUITools.AddChild(self.groupItems.gameObject, self.giftbagItem.gameObject)
		local item = FoolClockGiftbagItem.new(go, self, data.item_type)

		item:setInfo(data)
		xyd.setDragScrollView(item.go, self.scrollView)
		table.insert(self.items, item)
	end

	local extraGo = NGUITools.AddChild(self.groupItems.gameObject, self.emptyItem.gameObject)

	self.groupItems:GetComponent(typeof(UILayout)):Reposition()
	self.scrollView:ResetPosition()
	self:waitForTime(0.3, function ()
		self:updateArrow()
	end)
end

function FoolClockGiftbag:updateArrow()
	local topDelta = ITEM_HEIGHT - self.scrollPanel.clipOffset.y
	local topNum = math.floor(topDelta / ITEM_HEIGHT + 0.5)
	local arrowUp = false

	for i = 1, topNum do
		arrowUp = arrowUp or true
	end

	self.arrowUp:SetActive(arrowUp)

	local nums = #self.items
	local botDelta = nums * ITEM_HEIGHT - self.scrollPanel.height - topDelta
	local botNum = math.floor(botDelta / ITEM_HEIGHT + 0.5)
	local arrowDown = false

	if botNum >= 1 then
		arrowDown = true
	end

	self.arrowDown:SetActive(arrowDown)
end

function FoolClockGiftbag:onRegister()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	self.scrollView.onDragMoving = handler(self, self.updateArrow)

	UIEventListener.Get(self.arrowUp.gameObject).onClick = function ()
		local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))

		sp.Begin(sp.gameObject, Vector3(116, -987, 0), 16)
		self:waitForTime(0.3, function ()
			self:updateArrow()
		end)
	end

	UIEventListener.Get(self.arrowDown.gameObject).onClick = function ()
		local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))

		sp.Begin(sp.gameObject, Vector3(116, -185 - (-185 + ITEM_HEIGHT) * self.scale_num_contrary, 0), 16)
		self:waitForTime(0.3, function ()
			self:updateArrow()
		end)
	end
end

function FoolClockGiftbag:onRecharge(event)
	local giftbagId = event.data.giftbag_id

	for i = 1, #self.items do
		if self.items[i].giftbagId == giftbagId then
			self.activityData:updateGiftbagBuyTimes(giftbagId)
			self.items[i]:onAward()

			break
		end
	end
end

function FoolClockGiftbag:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_FOOL_CLOCK_GIFTBAG then
		return
	end

	self.activityData.detail.buy_times = self.activityData.detail.buy_times + 1

	for i = 1, #self.items do
		if self.items[i].itemType == 1 then
			self.items[i]:onAward()

			break
		end
	end
end

function FoolClockGiftbagItem:ctor(go, parent, itemType)
	self.parent = parent
	self.itemType = itemType or 1
	self.chooseIndex = 0

	FoolClockGiftbagItem.super.ctor(self, go)
	self:register()
end

function FoolClockGiftbagItem:initUI()
	FoolClockGiftbagItem.super.initUI(self)

	self.itemGroup1_1 = self.go:NodeByName("itemGroup1_1").gameObject
	self.itemGroup1_2 = self.go:NodeByName("itemGroup1_2").gameObject
	self.itemGroup1_3 = self.go:NodeByName("itemGroup1_3").gameObject
	self.itemGroup1_4 = self.go:NodeByName("itemGroup1_4").gameObject
	self.itemGroup2_1 = self.go:NodeByName("itemGroup2_1").gameObject
	self.itemGroup2_2 = self.go:NodeByName("itemGroup2_2").gameObject
	self.itemGroup2_3 = self.go:NodeByName("itemGroup2_3").gameObject
	self.itemGroup2_4 = self.go:NodeByName("itemGroup2_4").gameObject
	self.itemGroup2_5 = self.go:NodeByName("itemGroup2_5").gameObject
	self.itemGroup2_6 = self.go:NodeByName("itemGroup2_6").gameObject
	self.iconGroup = self.itemGroup2_6:NodeByName("icon_group").gameObject
	self.chooseImg = self.itemGroup2_6:NodeByName("choose_img").gameObject

	xyd.setDragScrollView(self.chooseImg, self.parent.scrollView)

	self.limitLabel = self.go:ComponentByName("limitLabel", typeof(UILabel))
	self.purchaseBtn = self.go:NodeByName("purchaseBtn").gameObject
	self.purchaseBtnBg = self.purchaseBtn:GetComponent(typeof(UISprite))
	self.purchaseBtnLabel = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.purchaseBtnIcon = self.purchaseBtn:NodeByName("icon").gameObject
	self.vipLabel = self.go:ComponentByName("vipLabel", typeof(UILabel))

	if self.itemType == 1 then
		self.itemGroup2_1:SetActive(false)
		self.itemGroup2_2:SetActive(false)
		self.itemGroup2_3:SetActive(false)
		self.itemGroup2_4:SetActive(false)
		self.itemGroup2_5:SetActive(false)
		self.itemGroup2_6:SetActive(false)
		self.itemGroup1_1:SetActive(true)
		self.itemGroup1_2:SetActive(true)
		self.itemGroup1_3:SetActive(true)
		self.itemGroup1_4:SetActive(true)
		self.vipLabel:SetActive(false)
		self.purchaseBtnIcon:SetActive(true)
		xyd.setUISpriteAsync(self.purchaseBtnBg, nil, "blue_btn_65_65")

		self.purchaseBtnLabel.color = Color.New2(4294967295.0)
		self.purchaseBtnLabel.effectColor = Color.New2(1012112383)

		self.purchaseBtnLabel:X(16)
		self.purchaseBtnLabel:Y(-1)
		self.limitLabel:Y(-116)
	else
		self.itemGroup2_1:SetActive(true)
		self.itemGroup2_2:SetActive(true)
		self.itemGroup2_3:SetActive(true)
		self.itemGroup2_4:SetActive(true)
		self.itemGroup2_5:SetActive(true)
		self.itemGroup2_6:SetActive(true)
		self.itemGroup1_1:SetActive(false)
		self.itemGroup1_2:SetActive(false)
		self.itemGroup1_3:SetActive(false)
		self.itemGroup1_4:SetActive(false)
		self.vipLabel:SetActive(true)
		self.purchaseBtnIcon:SetActive(false)
		xyd.setUISpriteAsync(self.purchaseBtnBg, nil, "mana_week_card_btn01")
	end
end

function FoolClockGiftbagItem:setInfo(params)
	self.buyTimes = params.buy_times or 0
	self.limitTImes = params.limit_times

	if self.itemType == 1 then
		self.awards = xyd.tables.miscTable:split2Cost("foolsday_giftawards", "value", "|#")
		self.cost = xyd.tables.miscTable:split2Cost("foolsday_giftcost", "value", "#")
		self.purchaseBtnLabel.text = tostring(self.cost[2])
	else
		self.awards = params.awards
		self.giftbagId = params.giftbag_id
		self.chooseAwards = FestivalChoseTable:getChooseAwards(self.giftbagId)
		self.chooseIndex = params.choose_index
		self.vipLabel.text = "+" .. params.vip_exp .. " VIP EXP"
		self.purchaseBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.giftbagId) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftbagId)
		self.oldChooseIndex = self.chooseIndex

		if self.chooseIndex > 0 then
			local cAward = self.chooseAwards[self.chooseIndex]

			table.insert(self.awards, cAward)
		end
	end

	local isBuyout = false
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(self.limitTImes - self.buyTimes))

	if self.limitTImes <= self.buyTimes then
		isBuyout = true
		self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.purchaseBtn.gameObject)
	end

	local awardNum = 0

	for i in ipairs(self.awards) do
		local data = self.awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			awardNum = awardNum + 1
			local scale = 0.6018518518518519

			if self.itemType == 1 then
				if awardNum == 2 then
					scale = 0.7037037037037037
				end
			elseif awardNum == 6 then
				scale = 0.7037037037037037
			end

			local groupName = "itemGroup" .. self.itemType .. "_" .. awardNum
			local uiRoot = self[groupName]
			local switch = false
			local switch_func = nil

			if awardNum == 6 then
				uiRoot = self.iconGroup

				if not isBuyout then
					switch = true

					function switch_func()
						xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
							mustChoose = true,
							items = self.chooseAwards,
							sureCallback = function (index)
								if index == 0 then
									return
								end

								self.parent.activityData:selectSpecialAward(self.giftbagId, index)

								self.chooseIndex = index
							end,
							buttomTitleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT02"),
							titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT01"),
							sureBtnText = __("SURE"),
							cancelBtnText = __("CANCEL"),
							tipsText = __(""),
							selectedIndex = self.chooseIndex
						})
					end
				end
			end

			xyd.getItemIcon({
				notShowGetWayBtn = true,
				show_has_num = true,
				uiRoot = uiRoot,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				scale = scale,
				dragScrollView = self.parent.scrollView,
				isNew = xyd.tables.itemTable:getType(data[1]) == xyd.ItemType.SKIN,
				switch = switch,
				switch_func = switch_func
			})
		end
	end
end

function FoolClockGiftbagItem:updateChooseAward()
	if self.itemType == 1 then
		return
	end

	self.chooseIndex = self.parent.activityData:getChooseIndex(self.giftbagId)
	local cAward = self.chooseAwards[self.chooseIndex]

	if self.oldChooseIndex ~= self.chooseIndex then
		self.oldChooseIndex = self.chooseIndex
		self.awards[6] = cAward

		NGUITools.DestroyChildren(self.iconGroup.transform)

		local switch = true

		local function switch_func()
			xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
				mustChoose = true,
				items = self.chooseAwards,
				sureCallback = function (index)
					if index == 0 then
						return
					end

					self.parent.activityData:selectSpecialAward(self.giftbagId, index)

					self.chooseIndex = index
				end,
				buttomTitleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT02"),
				titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT01"),
				sureBtnText = __("SURE"),
				cancelBtnText = __("CANCEL"),
				tipsText = __(""),
				selectedIndex = self.chooseIndex
			})
		end

		xyd.getItemIcon({
			notShowGetWayBtn = true,
			show_has_num = true,
			scale = 0.7037037037037037,
			uiRoot = self.iconGroup,
			itemID = cAward[1],
			num = cAward[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent.scrollView,
			isNew = xyd.tables.itemTable:getType(cAward[1]) == xyd.ItemType.SKIN,
			switch = switch,
			switch_func = switch_func
		})
	end
end

function FoolClockGiftbagItem:onChooseAward(event)
	local data = event.data

	self:updateChooseAward()
end

function FoolClockGiftbagItem:register()
	self:registerEvent(xyd.event.GIFTBAG_SET_ATTACH_INDEX, handler(self, self.onChooseAward))

	UIEventListener.Get(self.chooseImg).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
			mustChoose = true,
			items = self.chooseAwards,
			sureCallback = function (index)
				self.parent.activityData:selectSpecialAward(self.giftbagId, index)

				self.chooseIndex = index
			end,
			buttomTitleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT02"),
			titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT01"),
			sureBtnText = __("SURE"),
			cancelBtnText = __("CANCEL"),
			tipsText = __(""),
			selectedIndex = self.chooseIndex
		})
	end)
	UIEventListener.Get(self.purchaseBtn).onClick = handler(self, function ()
		if self.itemType == 1 then
			local data = {}

			if xyd.models.backpack:getItemNumByID(self.cost[1]) < self.cost[2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.cost[1])))

				return
			end

			xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
				if yes then
					local msg = messages_pb.get_activity_award_req()
					msg.activity_id = xyd.ActivityID.ACTIVITY_FOOL_CLOCK_GIFTBAG
					msg.params = json.encode(data)

					xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
				end
			end)

			return
		end

		if self.chooseIndex == 0 then
			xyd.alertConfirm(__("GO_TO_SELECT"), handler(self, function ()
			end))
		else
			xyd.SdkManager.get():showPayment(self.giftbagId)
		end
	end)
end

function FoolClockGiftbagItem:updateStatus()
	if self.itemType == 1 then
		self.buyTimes = self.parent.activityData:getDiamondBuyTimes()
	else
		local giftbagCharge = self.parent.activityData:getGiftbagCharges(self.giftbagId)
		self.buyTimes = giftbagCharge.buy_times
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(self.limitTImes - self.buyTimes))

	if self.limitTImes <= self.buyTimes then
		self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.purchaseBtn.gameObject)
	end
end

function FoolClockGiftbagItem:onAward()
	self:updateStatus()

	local itemInfos = {}
	local awards = self.awards

	for i = 1, #awards do
		local award = awards[i]

		table.insert(itemInfos, {
			item_id = award[1],
			item_num = award[2]
		})
	end

	if self.itemType == 1 then
		xyd.itemFloat(itemInfos)
	end

	for i, item in pairs(itemInfos) do
		local type = xyd.tables.itemTable:getType(item.item_id)

		if type == xyd.ItemType.SKIN then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = {
					tonumber(item.item_id)
				}
			})
		end
	end
end

return FoolClockGiftbag
