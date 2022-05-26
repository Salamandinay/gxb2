local SpringGiftBag = class("SpringGiftBag", import(".ActivityContent"))
local SpringGiftBagItem = class("SpringGiftBagItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local ITEM_HEIGHT = 343

function SpringGiftBag:ctor(parentGO, params)
	SpringGiftBag.super.ctor(self, parentGO, params)
end

function SpringGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/spring_giftbag"
end

function SpringGiftBag:resizeToParent()
	SpringGiftBag.super.resizeToParent(self)
	self:resizePosY(self.timeBg, -85, -111)
	self:resizePosY(self.arrowDown, -830, -1000)
end

function SpringGiftBag:initUI()
	self:getUIComponent()
	SpringGiftBag.super.initUI(self)
	self:initUIComponent()
end

function SpringGiftBag:getUIComponent()
	local go = self.go
	self.panelLogo = go:NodeByName("panelLogo").gameObject
	self.textImg = self.panelLogo:ComponentByName("textImg", typeof(UISprite))
	self.timeBg = self.panelLogo:NodeByName("timeBg").gameObject
	self.timeGroup = self.panelLogo:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.scrollView = go:ComponentByName("scrollView", typeof(UIScrollView))
	self.scrollPanel = go:ComponentByName("scrollView", typeof(UIPanel))
	self.groupItems = self.scrollView:NodeByName("groupItems").gameObject
	self.groupArrow = go:NodeByName("groupArrow").gameObject
	self.arrowUp = self.groupArrow:ComponentByName("arrowUp", typeof(UISprite))
	self.arrowDown = self.groupArrow:ComponentByName("arrowDown", typeof(UISprite))
	self.giftbagItem = go:NodeByName("giftbag_item").gameObject
	self.partnerRoot = go:NodeByName("partnerRoot").gameObject
end

function SpringGiftBag:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "activity_children_giftbag_logo_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
	end

	self.infos = {}

	for _, charge in ipairs(self.activityData.detail_.charges) do
		table.insert(self.infos, {
			table_id = charge.table_id,
			buy_times = charge.buy_times,
			limit_times = charge.limit_times,
			choose_index = self.activityData:getChooseIndex(charge.table_id)
		})
	end

	table.sort(self.infos, function (a, b)
		local left_times1 = a.limit_times - a.buy_times > 0 and 1 or 0
		local left_times2 = b.limit_times - b.buy_times > 0 and 1 or 0

		if left_times1 ~= left_times2 then
			return left_times2 < left_times1
		else
			return a.table_id < b.table_id
		end
	end)

	self.items = {}

	NGUITools.DestroyChildren(self.groupItems.transform)

	for _, info in ipairs(self.infos) do
		local go = NGUITools.AddChild(self.groupItems.gameObject, self.giftbagItem.gameObject)
		local item = SpringGiftBagItem.new(go, self)

		item:setInfo(info)
		xyd.setDragScrollView(item.go, self.scrollView)
		table.insert(self.items, item)
	end

	self.groupItems:GetComponent(typeof(UILayout)):Reposition()
	self.scrollView:ResetPosition()
	self:waitForTime(0.3, function ()
		self:updateArrow()
	end)

	self.spine_ = xyd.Spine.new(self.partnerRoot)

	self.spine_:setInfo("fenlier_pifu04_lihui01", function ()
		self.spine_:play("animation", 0, 1)
		self.spine_:SetLocalPosition(176, -940, 0)
	end)
end

function SpringGiftBag:updateArrow()
	local topDelta = -175 - self.scrollPanel.clipOffset.y
	local topNum = math.floor(topDelta / ITEM_HEIGHT + 0.6)
	local arrowUp = false

	for i = 1, topNum do
		arrowUp = arrowUp or true
	end

	self.arrowUp:SetActive(arrowUp)

	local nums = #self.items
	local botDelta = nums * ITEM_HEIGHT + (nums - 1) * 10 - self.scrollPanel.height - topDelta
	local botNum = math.floor(botDelta / ITEM_HEIGHT + 0.6)
	local arrowDown = false

	if botNum >= 1 then
		arrowDown = true
	end

	self.arrowDown:SetActive(arrowDown)
end

function SpringGiftBag:onRegister()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.update))
	self:registerEvent(xyd.event.GIFTBAG_SET_ATTACH_INDEX, handler(self, self.update))

	self.scrollView.onDragMoving = handler(self, self.updateArrow)

	UIEventListener.Get(self.arrowUp.gameObject).onClick = function ()
		local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))

		sp.Begin(sp.gameObject, Vector3(116, -416, 0), 16)
		self:waitForTime(0.3, function ()
			self:updateArrow()
		end)
	end

	UIEventListener.Get(self.arrowDown.gameObject).onClick = function ()
		local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))

		sp.Begin(sp.gameObject, Vector3(116, -19 - 177 * self.scale_num_contrary, 0), 16)
		self:waitForTime(0.3, function ()
			self:updateArrow()
		end)
	end
end

function SpringGiftBag:update()
	for i, info in ipairs(self.infos) do
		for __, charge in pairs(self.activityData.detail_.charges) do
			if info.table_id == charge.table_id then
				self.infos[i].buy_times = charge.buy_times
				self.infos[i].choose_index = self.activityData:getChooseIndex(charge.table_id)

				self.items[i]:update(self.infos[i])
			end
		end
	end
end

function SpringGiftBagItem:ctor(go, parent)
	SpringGiftBagItem.super.ctor(self, go)

	self.parent = parent
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.itemGroup2 = self.go:NodeByName("itemGroup2").gameObject
	self.vipLabel = self.go:ComponentByName("vipLabel", typeof(UILabel))
	self.limitLabel = self.go:ComponentByName("limitLabel", typeof(UILabel))
	self.purchaseBtn = self.go:NodeByName("purchaseBtn").gameObject
	self.purchaseBtnLabel = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.defaultIcon = self.go:NodeByName("defaultIcon").gameObject
end

function SpringGiftBagItem:update(params)
	self.buyTimes = params.buy_times or 0
	self.chooseIndex = params.choose_index
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.limitTimes - self.buyTimes)

	if self.limitTimes <= self.buyTimes then
		self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.purchaseBtn.gameObject)
	end

	local indexs = self.parent.activityData:getChooseIndex(self.giftbagId)

	for i = 1, self.chooseNum do
		NGUITools.DestroyChildren(self["defaultIcon" .. i].transform)

		if indexs[i] and indexs[i] ~= 0 then
			local award = self["chooseAwards" .. i][indexs[i]]

			xyd.getItemIcon({
				notShowGetWayBtn = true,
				switch = true,
				show_has_num = true,
				scale = 0.6018518518518519,
				uiRoot = self["defaultIcon" .. i].gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView,
				switch_func = function (index)
					xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
						mustChoose = true,
						items = self["chooseAwards" .. i],
						sureCallback = function (index)
							local newIndexs = self.parent.activityData:getChooseIndex(self.giftbagId)
							newIndexs[i] = index

							for j = 1, self.chooseNum do
								if not newIndexs[j] then
									newIndexs[j] = 0
								end
							end

							self.parent.activityData:selectSpecialAward(self.giftbagId, newIndexs)
							self.parent:update()
						end,
						buttomTitleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT02"),
						titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT01"),
						sureBtnText = __("SURE"),
						cancelBtnText = __("CANCEL"),
						tipsText = __("ACTIVITY_ICE_SECRET_ITEM_TIPS"),
						selectedIndex = self.chooseIndex[i] or 0
					})
				end
			})
		end
	end
end

function SpringGiftBagItem:setInfo(params)
	self.giftbagId = params.table_id
	self.buyTimes = params.buy_times or 0
	self.limitTimes = params.limit_times
	self.chooseIndex = params.choose_index
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.limitTimes - self.buyTimes)

	if self.limitTimes <= self.buyTimes then
		self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.purchaseBtn.gameObject)
	end

	xyd.setDragScrollView(self.purchaseBtn.gameObject, self.parent.scrollView)

	self.vipLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftbagId) .. " VIP EXP"
	self.purchaseBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.giftbagId) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftbagId)
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftbagId) or 0
	self.awards = xyd.tables.giftTable:getAwards(self.giftID) or {}
	self.chooseNum = xyd.tables.activitySpringGiftbagTable:getChooseNum(self.giftbagId)
	self.chooseAwards1 = xyd.tables.activitySpringGiftbagTable:getAwards1(self.giftbagId)
	self.chooseAwards2 = xyd.tables.activitySpringGiftbagTable:getAwards2(self.giftbagId)

	for _, award in ipairs(self.awards) do
		if award[1] ~= xyd.ItemID.VIP_EXP then
			xyd.getItemIcon({
				show_has_num = true,
				notShowGetWayBtn = true,
				scale = 0.6018518518518519,
				uiRoot = self.itemGroup,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView
			})
		end
	end

	local indexs = self.parent.activityData:getChooseIndex(self.giftbagId)

	for i = 1, self.chooseNum do
		self["defaultIcon" .. i] = NGUITools.AddChild(self.itemGroup2.gameObject, self.defaultIcon.gameObject)

		xyd.setDragScrollView(self["defaultIcon" .. i], self.parent.scrollView)

		UIEventListener.Get(self["defaultIcon" .. i]).onClick = handler(self, function ()
			xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
				mustChoose = true,
				items = self["chooseAwards" .. i],
				sureCallback = function (index)
					local newIndexs = self.parent.activityData:getChooseIndex(self.giftbagId)
					newIndexs[i] = index

					for j = 1, self.chooseNum do
						if not newIndexs[j] then
							newIndexs[j] = 0
						end
					end

					self.parent.activityData:selectSpecialAward(self.giftbagId, newIndexs)
					self.parent:update()
				end,
				buttomTitleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT02"),
				titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT01"),
				sureBtnText = __("SURE"),
				cancelBtnText = __("CANCEL"),
				tipsText = __("ACTIVITY_ICE_SECRET_ITEM_TIPS"),
				selectedIndex = self.chooseIndex[i] or 0
			})
		end)

		if indexs[i] and indexs[i] ~= 0 then
			local award = self["chooseAwards" .. i][indexs[i]]

			xyd.getItemIcon({
				notShowGetWayBtn = true,
				switch = true,
				show_has_num = true,
				scale = 0.7129629629629629,
				uiRoot = self["defaultIcon" .. i].gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView,
				switch_func = function (index)
					xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
						mustChoose = true,
						items = self["chooseAwards" .. i],
						sureCallback = function (index)
							local newIndexs = self.parent.activityData:getChooseIndex(self.giftbagId)
							newIndexs[i] = index

							for j = 1, self.chooseNum do
								if not newIndexs[j] then
									newIndexs[j] = 0
								end
							end

							self.parent.activityData:selectSpecialAward(self.giftbagId, newIndexs)
							self.parent:update()
						end,
						buttomTitleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT02"),
						titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT01"),
						sureBtnText = __("SURE"),
						cancelBtnText = __("CANCEL"),
						tipsText = __("ACTIVITY_ICE_SECRET_ITEM_TIPS"),
						selectedIndex = self.chooseIndex[i] or 0
					})
				end
			})
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

	UIEventListener.Get(self.purchaseBtn).onClick = handler(self, function ()
		if #self.chooseIndex < self.chooseNum then
			xyd.alertConfirm(__("GO_TO_SELECT"))
		else
			xyd.SdkManager.get():showPayment(self.giftbagId)
		end
	end)
end

return SpringGiftBag
