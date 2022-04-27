local BaseWindow = import(".BaseWindow")
local BattlePassBuyLevWindow = class("BattlePassBuyLevWindow", BaseWindow)
local itemForDataGroup = class("itemForDataGroup")

function BattlePassBuyLevWindow:ctor(name, params)
	BattlePassBuyLevWindow.super.ctor(self, name, params)

	self.itemList_ = {}
	self.selectedBar = false
	self.wantAddLev = 0
	self.battlePassAwardTable = xyd.models.activity:getBattlePassTable(xyd.BATTLE_PASS_TABLE.AWARD)
end

function BattlePassBuyLevWindow:initWindow()
	local conTrans = self.window_:NodeByName("groupAction")
	self.labelWinTitle_ = conTrans:ComponentByName("labelWinTitle", typeof(UILabel))

	self:addTitle()
	BattlePassBuyLevWindow.super.initWindow(self)

	self.titleTipWords_ = conTrans:ComponentByName("titleTipWords", typeof(UILabel))
	self.closeBtn_ = conTrans:NodeByName("closeBtn").gameObject
	self.closeBtn = conTrans:NodeByName("closeBtn").gameObject
	self.helpBtn_ = conTrans:NodeByName("helpBtn").gameObject
	self.effectGroup_ = conTrans:NodeByName("containerNode/effectGroup").gameObject
	self.scrollView_ = conTrans:ComponentByName("containerNode/scrollView", typeof(UIScrollView))
	self.grid_ = conTrans:ComponentByName("containerNode/scrollView/grid", typeof(MultiRowWrapContent))
	local root = conTrans:NodeByName("itemRoot").gameObject
	self.warpContent_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, root, itemForDataGroup, self)
	local scrollNode = conTrans:NodeByName("scrollNode")
	self.levTipWords_ = scrollNode:ComponentByName("levTipWords", typeof(UILabel))
	self.btnMin_ = scrollNode:NodeByName("btnMin").gameObject
	self.btnMax_ = scrollNode:NodeByName("btnMax").gameObject
	self.okBtn_ = conTrans:NodeByName("okBtn").gameObject
	self.costImg_ = self.okBtn_:ComponentByName("costImg", typeof(UISprite))
	self.rectImg_ = self.okBtn_:NodeByName("rect").gameObject
	self.labelBuy_ = self.okBtn_:ComponentByName("labelBuy", typeof(UILabel))
	self.labelBefore_ = self.okBtn_:ComponentByName("labelBefore", typeof(UILabel))
	self.tipsLabel_ = conTrans:ComponentByName("tipsLabel", typeof(UILabel))
	self.progressBar_ = scrollNode:ComponentByName("progressBar", typeof(UISlider))

	XYDUtils.AddEventDelegate(self.progressBar_.onChange, function ()
		self:onValueChange()
	end)
	self:layout()
	self:register()
	self:updateBar()
	self:initList()
end

function BattlePassBuyLevWindow:layout()
	self.tipsLabel_.text = __("BP_BUY_LEV_TIP2")
	self.titleTipWords_.text = __("BP_BUY_LEV_PREAWARD") .. " :"
	self.labelWinTitle_.text = __("BP_BUY_LEV_WINDOW")
end

function BattlePassBuyLevWindow:register()
	BattlePassBuyLevWindow.super.register(self)

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "BP_BUY_LEV_WINDOW_HELP"
		})
	end

	UIEventListener.Get(self.btnMin_).onClick = function ()
		self:changeNumByBtn(-1)
	end

	UIEventListener.Get(self.btnMax_).onClick = function ()
		self:changeNumByBtn(1)
	end

	UIEventListener.Get(self.okBtn_).onClick = function ()
		local cost = tonumber(self.labelBuy_.text)
		local tips = __("DAILY_QUIZ_BUY_TIPS_2", cost)

		xyd.alertYesNo(tips, function (yes)
			if yes then
				if not cost then
					cost = 1
				end

				if cost and cost > 0 and xyd.models.backpack:getCrystal() < cost then
					xyd.alertTips(__("NOT_ENOUGH_CRYSTAL"))

					return
				end

				local msg = messages_pb.battle_pass_buy_level_req()
				msg.activity_id = xyd.models.activity:getBattlePassId()
				msg.level = self.wantAddLev

				xyd.Backend.get():request(xyd.mid.BATTLE_PASS_BUY_LEVEL, msg)
				xyd.WindowManager.get():closeWindow(self.name_)
			end
		end)
	end
end

function BattlePassBuyLevWindow:updateBar()
	local maxLev = self.battlePassAwardTable:getMaxId()
	local canUpLevNum = maxLev - xyd.getBpLev()
	self.progressBar_.value = self.wantAddLev / canUpLevNum
	self.progressBar_.numberOfSteps = canUpLevNum
end

function BattlePassBuyLevWindow:onValueChange()
	if self.onClickingBtn then
		return
	end

	local maxLev = self.battlePassAwardTable:getMaxId()
	local canUpLevNum = maxLev - xyd.getBpLev() - 1
	self.wantAddLev = math.floor(self.progressBar_.value * canUpLevNum + 1)

	if maxLev < self.wantAddLev then
		self.wantAddLev = maxLev
	end

	self:updateShowBySlider()
end

function BattlePassBuyLevWindow:changeNumByBtn(num)
	local shouldUpdate = false

	if num < 0 then
		if self.wantAddLev > 0 then
			self.wantAddLev = self.wantAddLev + num
			shouldUpdate = true
		end
	elseif num > 0 then
		local maxLev = self.battlePassAwardTable:getMaxId()
		local canUpLevNum = maxLev - xyd.getBpLev()

		if self.wantAddLev < canUpLevNum then
			self.wantAddLev = self.wantAddLev + num
			shouldUpdate = true
		end
	end

	if self.wantAddLev < 1 then
		self.wantAddLev = 1
	end

	self.onClickingBtn = true

	self:updateBar()

	if shouldUpdate then
		self:updateShowBySlider(true)
	else
		self.onClickingBtn = false
	end
end

function BattlePassBuyLevWindow:updateShowBySlider()
	if self.wantAddLev <= 0 then
		self.wantAddLev = 1
	end

	local maxLev = self.battlePassAwardTable:getMaxId()
	local canUpLevNum = maxLev - xyd.getBpLev()
	local bpData = xyd.models.activity:getBattlePassData()
	local bpId = xyd.models.activity:getBattlePassId()
	local startTime = xyd.tables.miscTable:getNumber("bp_start_time", "value")

	if bpData then
		startTime = bpData:startTime()
	end

	local totalTime = xyd.getServerTime() - startTime
	local bpDuration = xyd.tables.miscTable:getNumber("bp_duration", "value")
	local durationTime = totalTime % bpDuration
	local disTime = xyd.tables.miscTable:getNumber("bp_buy_level_duration", "value")
	local hasDis = disTime < durationTime
	local needCost = 0
	local dicNeedCost = 0

	if self.wantAddLev > 0 then
		for i = 1, canUpLevNum do
			if #self.battlePassAwardTable:getCostDiamonds(i - 1 + xyd.getBpLev()) > 0 then
				needCost = needCost + self.battlePassAwardTable:getCostDiamonds(i - 1 + xyd.getBpLev())[2]
				dicNeedCost = dicNeedCost + self.battlePassAwardTable:getCostDctDiamonds(i - 1 + xyd.getBpLev())[2]
			end

			if self.wantAddLev <= i then
				break
			end
		end
	end

	local words = __("BATTLE_PASS_BUY_LEV_TIP", xyd.getBpLev(), xyd.getBpLev() + self.wantAddLev)

	if xyd.ActivityID.BATTLE_PASS == xyd.models.activity:getBattlePassId() then
		words = __("BP_BUY_LEV_TIP", xyd.getBpLev(), xyd.getBpLev() + self.wantAddLev)
	end

	local content1 = string.gsub(words, "0x(%w+) ", "%1][")
	self.levTipWords_.text = content1

	if hasDis then
		self.labelBuy_.text = tostring(dicNeedCost)
		self.labelBefore_.text = tostring(needCost)

		self.labelBuy_:SetLocalPosition(10, 12, 0)
		self.rectImg_:SetActive(true)
	else
		self.labelBuy_.text = tostring(needCost)
		self.labelBefore_.text = " "

		self.labelBuy_:SetLocalPosition(10, 1, 0)
		self.rectImg_:SetActive(false)
	end

	self:updateAwardList()

	self.onClickingBtn = false
end

function BattlePassBuyLevWindow:initList()
	self:updateAwardList()
	self:updateShowBySlider()
end

function BattlePassBuyLevWindow:updateAwardList()
	local items = {}
	local nowSelectLev = xyd.getBpLev() + self.wantAddLev
	local freeArr = {}
	local paidArr = {}
	local data = xyd.models.activity:getBattlePassData()
	local charges = data.detail.charges
	local is_extra = charges[1].buy_times > 0 or charges[3].buy_times > 0 or charges[1].buy_times > 0 and charges[2].buy_times > 0

	for i = xyd.getBpLev() + 1, nowSelectLev do
		xyd.tableConcat(freeArr, self.battlePassAwardTable:getFreeAward(i))
		xyd.tableConcat(paidArr, self.battlePassAwardTable:getPaidAward(i))
	end

	local list = {}

	for _, itemInfo in ipairs(freeArr) do
		if not list[itemInfo[1]] then
			list[itemInfo[1]] = {
				scale = 0.8333333333333334,
				itemID = itemInfo[1],
				num = itemInfo[2]
			}
		else
			list[itemInfo[1]].num = list[itemInfo[1]].num + itemInfo[2]
		end
	end

	if is_extra then
		for _, itemInfo in ipairs(paidArr) do
			if not list[itemInfo[1]] then
				list[itemInfo[1]] = {
					scale = 0.8333333333333334,
					itemID = itemInfo[1],
					num = itemInfo[2]
				}
			else
				list[itemInfo[1]].num = list[itemInfo[1]].num + itemInfo[2]
			end
		end
	end

	for _, itemInfo in pairs(list) do
		table.insert(items, itemInfo)
	end

	table.sort(items, function (a, b)
		local id_a = a.itemID
		local id_b = b.itemID

		return tonumber(id_b < id_a)
	end)
	XYDCo.WaitForFrame(1, function ()
		self.warpContent_:setInfos(items, {})
	end, nil)
end

function itemForDataGroup:ctor(parentGo, parent)
	self.uiRoot_ = parentGo
	self.parent_ = parent
end

function itemForDataGroup:update(index, realIndex, info)
	if not info or not info.itemID then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	self.data_ = info

	self:initItem()
end

function itemForDataGroup:getGameObject()
	return self.uiRoot_
end

function itemForDataGroup:initItem()
	if not self.itemID or self.itemID ~= self.data_.itemID then
		self.itemID = self.data_.itemID

		if not self.itemIcon_ then
			self.itemIcon_ = xyd.getItemIcon({
				uiRoot = self.uiRoot_,
				itemID = self.data_.itemID,
				num = self.data_.num,
				scale = self.data_.scale,
				itemIconSpecil = self.data_.itemIconSpecil,
				dragScrollView = self.parent_.scrollView_
			})
		else
			NGUITools.Destroy(self.itemIcon_:getGameObject())

			self.itemIcon_ = xyd.getItemIcon({
				uiRoot = self.uiRoot_,
				itemID = self.data_.itemID,
				num = self.data_.num,
				scale = self.data_.scale,
				itemIconSpecil = self.data_.itemIconSpecil,
				dragScrollView = self.parent_.scrollView_
			})
		end
	elseif self.itemIcon_ then
		self.itemIcon_:setInfo(self.data_)
	end
end

return BattlePassBuyLevWindow
