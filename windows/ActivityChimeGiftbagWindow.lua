local ActivityChimeGiftbagWindow = class("ActivityChimeGiftbagWindow", import(".BaseWindow"))
local CountDown = import("app.components.CountDown")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ShowItem = class("ShowItem", import("app.components.CopyComponent"))

function ActivityChimeGiftbagWindow:ctor(name, params)
	ActivityChimeGiftbagWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_CHIME)
end

function ActivityChimeGiftbagWindow:initWindow()
	self:getUIComponent()
	ActivityChimeGiftbagWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function ActivityChimeGiftbagWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.logoTextImg = self.groupAction:ComponentByName("logoTextImg", typeof(UISprite))
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.upConTextCon1 = self.upCon:NodeByName("upConTextCon1").gameObject
	self.text1 = self.upConTextCon1:ComponentByName("text1", typeof(UILabel))
	self.upConTextCon2 = self.upCon:NodeByName("upConTextCon2").gameObject
	self.text2 = self.upConTextCon2:ComponentByName("text2", typeof(UILabel))
	self.dayItemCon = self.upCon:NodeByName("dayItemCon").gameObject

	for i = 1, 3 do
		self["dayItem" .. i] = self.dayItemCon:NodeByName("dayItem" .. i).gameObject
		self["dayItemIcon" .. i] = self["dayItem" .. i]:ComponentByName("dayItemIcon", typeof(UISprite))
		self["dayItemText" .. i] = self["dayItem" .. i]:ComponentByName("dayItemText", typeof(UILabel))
	end

	self.giftItemCon = self.upCon:NodeByName("giftItemCon").gameObject
	self.groupIcon = self.giftItemCon:NodeByName("groupIcon").gameObject
	self.groupIconUIGrid = self.giftItemCon:ComponentByName("groupIcon", typeof(UIGrid))
	self.groupIcon2 = self.giftItemCon:NodeByName("groupIcon2").gameObject
	self.groupIcon2UIGrid = self.giftItemCon:ComponentByName("groupIcon2", typeof(UIGrid))
	self.labelItemText01 = self.giftItemCon:ComponentByName("labelItemText01", typeof(UILabel))
	self.labelItemText02 = self.giftItemCon:ComponentByName("labelItemText02", typeof(UILabel))
	self.labelItemLimit = self.giftItemCon:ComponentByName("labelItemLimit", typeof(UILabel))
	self.btnPurchase = self.giftItemCon:NodeByName("btnPurchase").gameObject
	self.btnPurchaseBoxCollider = self.giftItemCon:ComponentByName("btnPurchase", typeof(UnityEngine.BoxCollider))
	self.buttonLabel = self.btnPurchase:ComponentByName("button_label", typeof(UILabel))
	self.propCon = self.btnPurchase:NodeByName("propCon").gameObject
	self.propIcon = self.propCon:ComponentByName("propIcon", typeof(UISprite))
	self.propText = self.propCon:ComponentByName("propText", typeof(UILabel))
	self.timeCon = self.groupAction:NodeByName("timeCon").gameObject
	self.timeConUILayout = self.groupAction:ComponentByName("timeCon", typeof(UILayout))
	self.timeText = self.timeCon:ComponentByName("timeText", typeof(UILabel))
	self.timeUpdateText = self.timeCon:ComponentByName("timeUpdateText", typeof(UILabel))
	self.common_giftbag_item = self.groupAction:NodeByName("common_giftbag_item").gameObject
	self.scroller = self.groupAction:NodeByName("scroller").gameObject
	self.scrollerUIScrollView = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.groupPackage = self.scroller:NodeByName("groupPackage").gameObject
	self.groupPackageUIWrapContent = self.scroller:ComponentByName("groupPackage", typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollerUIScrollView, self.groupPackageUIWrapContent, self.common_giftbag_item, ShowItem, self)
	self.timeConBg = self.groupAction:ComponentByName("timeConBg", typeof(UISprite))
end

function ActivityChimeGiftbagWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))
	xyd.setDarkenBtnBehavior(self.btnPurchase, self, function ()
		xyd.SdkManager.get():showPayment(self.dayGiftBagID)
	end)
end

function ActivityChimeGiftbagWindow:onRecharge(event)
	self:setInfos()
end

function ActivityChimeGiftbagWindow:layout()
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_CHIME, function ()
		xyd.db.misc:setValue({
			key = "activity_chime_day_buy_day_giftbag",
			value = xyd.getServerTime()
		})
	end)
	xyd.setUISpriteAsync(self.logoTextImg, nil, "activity_chime_text_bg_xyys_" .. xyd.Global.lang, nil, , true)

	self.text1.text = __("ACTIVITY_CHIME_TEXT07")
	self.text2.text = __("ACTIVITY_CHIME_TEXT08")
	self.propText.text = __("SPACE_EXPLORE_SUPPLY_TEXT02")

	self:initTime()
	self:setInfos()
end

function ActivityChimeGiftbagWindow:initTime()
	self.timeUpdateText.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.timeUpdateText.transform:SetSiblingIndex(0)
		self.timeText.transform:SetSiblingIndex(1)
	end

	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		local countdown = CountDown.new(self.timeText, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime(),
			callback = handler(self, self.timeOver)
		})

		self.timeConUILayout:Reposition()
		self:updateTimeBgWidth()
	else
		self:timeOver()
		self:updateTimeBgWidth()
	end
end

function ActivityChimeGiftbagWindow:timeOver()
	self.timeText.text = "00:00:00"

	self.timeConUILayout:Reposition()
end

function ActivityChimeGiftbagWindow:updateTimeBgWidth()
	self.timeConBg.width = self.timeText.width + self.timeUpdateText.width + self.timeConUILayout.gap.x + 138
end

function ActivityChimeGiftbagWindow:setInfos()
	local infos = self.activityData:getChargesInfo()
	local setArr = {}
	local isYetArr = {}
	local dayInfo = nil

	for i, info in pairs(infos) do
		local giftBagId = info.table_id
		local mailId = xyd.tables.giftBagTable:getMailId(giftBagId)

		if mailId and mailId > 0 then
			dayInfo = info
		else
			local limitNum = info.limit_times - info.buy_times

			if limitNum <= 0 then
				table.insert(isYetArr, info)
			else
				table.insert(setArr, info)
			end
		end
	end

	table.sort(isYetArr, function (a, b)
		return a.table_id < b.table_id
	end)
	table.sort(setArr, function (a, b)
		return a.table_id < b.table_id
	end)

	for i in pairs(isYetArr) do
		table.insert(setArr, isYetArr[i])
	end

	local keepPosition = true

	if not self.isFirstInitYet then
		keepPosition = false
	end

	setArr[#setArr].isHideLine = true

	self.wrapContent:setInfos(setArr, {
		keepPosition = keepPosition
	})
	self.scrollerUIScrollView:ResetPosition()
	self:setUpIcon(dayInfo)
end

function ActivityChimeGiftbagWindow:setUpIcon(dayInfo)
	local giftBagID = dayInfo.table_id
	self.dayGiftBagID = giftBagID
	local giftID = xyd.tables.giftBagTable:getGiftID(giftBagID)
	local awards = xyd.tables.giftTable:getDailyAwards(giftID)
	self.labelItemText01.text = "VIP EXP"
	local limtNum = dayInfo.limit_times - dayInfo.buy_times

	if limtNum < 0 then
		limtNum = 0
	end

	self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", limtNum)
	self.labelItemText02.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(giftBagID))
	self.buttonLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(giftBagID))

	if limtNum <= 0 then
		self.btnPurchaseBoxCollider.enabled = false

		xyd.applyChildrenGrey(self.btnPurchase.gameObject)
	else
		self.btnPurchaseBoxCollider.enabled = true

		xyd.applyChildrenOrigin(self.btnPurchase.gameObject)
	end

	if not awards then
		return
	end

	if #awards >= 5 then
		self.groupIcon2:SetActive(true)
	else
		self.groupIcon2:SetActive(false)
	end

	local awardNewArr = {}

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			table.insert(awardNewArr, data)
		end
	end

	if not self.conArr1 then
		self.conArr1 = {}
	end

	local countTime = xyd.getServerTime()

	if self.activityData:getEndTime() < countTime then
		countTime = self.activityData:getEndTime()
	end

	local curDay = math.ceil((countTime - self.activityData:startTime()) / xyd.DAY_TIME)

	for i = 1, #awardNewArr do
		local data = awardNewArr[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local scale = 0.7129629629629629
			local icaonGroup = self.groupIcon
			local param = {
				isAddUIDragScrollView = true,
				labelNumScale = 1.2,
				show_has_num = true,
				itemID = data[1],
				num = data[2] * curDay,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = icaonGroup,
				scale = Vector3(scale, scale, scale),
				dragScrollView = self.parentScroller
			}

			if self.conArr1[i] then
				self.conArr1[i]:setInfo(param)
			else
				self.conArr1[i] = xyd.getItemIcon(param, xyd.ItemIconType.ADVANCE_ICON)
			end

			self.conArr1[i]:SetActive(true)
		end
	end

	for j = #awardNewArr + 1, #self.conArr1 do
		self.conArr1[j]:SetActive(false)
	end

	self.groupIconUIGrid:Reposition()
	self.groupIcon2UIGrid:Reposition()

	for i = 1, 3 do
		if awards[i] then
			xyd.setUISpriteAsync(self["dayItemIcon" .. i], nil, xyd.tables.itemTable:getIcon(awards[i][1]), function ()
				self["dayItemIcon" .. i]:SetLocalScale(0.45, 0.45, 1)
			end, nil, true)

			self["dayItemText" .. i].text = "x" .. xyd.getRoughDisplayNumber(awards[i][2])

			self["dayItem" .. i].gameObject:SetActive(true)
		else
			self["dayItem" .. i].gameObject:SetActive(false)
		end
	end
end

function ShowItem:ctor(go, parent)
	dump(123, "test")

	self.go = go
	self.parent = parent

	ShowItem.super.ctor(self, go)
end

function ShowItem:getUIComponent()
	self.itemBg = self.go:ComponentByName("itemBg", typeof(UISprite))
	self.groupIcon = self.go:NodeByName("groupIcon").gameObject
	self.groupIconUIGrid = self.go:ComponentByName("groupIcon", typeof(UIGrid))
	self.groupIcon2 = self.go:NodeByName("groupIcon2").gameObject
	self.groupIcon2UIGrid = self.go:ComponentByName("groupIcon2", typeof(UIGrid))
	self.labelItemText01 = self.go:ComponentByName("labelItemText01", typeof(UILabel))
	self.labelItemText02 = self.go:ComponentByName("labelItemText02", typeof(UILabel))
	self.labelItemLimit = self.go:ComponentByName("labelItemLimit", typeof(UILabel))
	self.btnPurchase = self.go:NodeByName("btnPurchase").gameObject
	self.btnPurchaseBoxCollider = self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider))
	self.buttonLabel = self.btnPurchase:ComponentByName("button_label", typeof(UILabel))
	self.redMark = self.btnPurchase:ComponentByName("redMark", typeof(UISprite))
	self.labelOriginLeft = self.go:ComponentByName("labelOriginLeft", typeof(UISprite))
	self.labelOriginRight = self.go:ComponentByName("labelOriginRight", typeof(UISprite))
end

function ShowItem:initUI()
	self:getUIComponent()
	ShowItem.super.initUI(self)
	self:onRegister()

	self.labelItemText01.text = "VIP EXP"
end

function ShowItem:onRegister()
	xyd.setDarkenBtnBehavior(self.btnPurchase, self, function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end)
end

function ShowItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.data = info
	self.giftBagID = info.table_id
	local limtNum = info.limit_times - info.buy_times

	if limtNum < 0 then
		limtNum = 0
	end

	self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", limtNum)
	self.labelItemText02.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(self.giftBagID))
	self.buttonLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagID))

	if limtNum <= 0 then
		self.btnPurchaseBoxCollider.enabled = false

		xyd.applyChildrenGrey(self.btnPurchase.gameObject)
		self.labelItemLimit.gameObject:SetActive(false)
	else
		self.btnPurchaseBoxCollider.enabled = true

		xyd.applyChildrenOrigin(self.btnPurchase.gameObject)
		self.labelItemLimit.gameObject:SetActive(true)
	end

	if info.isHideLine then
		self.labelOriginLeft:SetActive(false)
		self.labelOriginRight:SetActive(false)
	else
		self.labelOriginLeft:SetActive(true)
		self.labelOriginRight:SetActive(true)
	end

	self:setIcon()
end

function ShowItem:setIcon()
	local giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	local awards = xyd.tables.giftTable:getAwards(giftID)

	if not awards then
		return
	end

	if #awards >= 5 then
		self.groupIcon2:SetActive(true)
	else
		self.groupIcon2:SetActive(false)
	end

	local awardNewArr = {}

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			table.insert(awardNewArr, data)
		end
	end

	if not self.conArr1 then
		self.conArr1 = {}
	end

	for i = 1, #awardNewArr do
		local data = awardNewArr[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local scale = 0.7129629629629629
			local icaonGroup = self.groupIcon
			local param = {
				isAddUIDragScrollView = true,
				labelNumScale = 1.2,
				show_has_num = true,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = icaonGroup,
				scale = Vector3(scale, scale, scale),
				dragScrollView = self.parentScroller
			}

			if self.conArr1[i] then
				self.conArr1[i]:setInfo(param)
			else
				self.conArr1[i] = xyd.getItemIcon(param, xyd.ItemIconType.ADVANCE_ICON)
			end

			self.conArr1[i]:SetActive(true)
		end
	end

	for j = #awardNewArr + 1, #self.conArr1 do
		self.conArr1[j]:SetActive(false)
	end

	self.groupIconUIGrid:Reposition()
	self.groupIcon2UIGrid:Reposition()
end

return ActivityChimeGiftbagWindow
