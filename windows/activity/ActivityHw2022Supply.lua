local ActivityHw2022Supply = class("ActivityHw2022Supply", import(".ActivityContent"))
local cjson = require("cjson")
local SupplyItem = class("SupplyItem", import("app.components.CopyComponent"))

function ActivityHw2022Supply:ctor(parentGO, params)
	self.supplyItemList_ = {}

	ActivityHw2022Supply.super.ctor(self, parentGO, params)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_HW2022_SUPPLY, function ()
		self.activityData.touchTime = xyd.getServerTime()
	end)
	dump(self.activityData.detail)
end

function ActivityHw2022Supply:getPrefabPath()
	return "Prefabs/Windows/activity/activity_hw2022_battlepass"
end

function ActivityHw2022Supply:initUI()
	ActivityHw2022Supply.super.initUI(self)
	self:getUIComponent()
	self:updateProgressBar()
	self:layout()
	self:updateHeight()
end

function ActivityHw2022Supply:onRegister()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_HALLOWEEN2022_GIFTBAG_HELP"
		})
	end

	UIEventListener.Get(self.jumpBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow("activity_window", function ()
			local params = xyd.tables.activityTable:getWindowParams(xyd.ActivityID.ACTIVITY_HW2022)
			local testParams = nil

			if params ~= nil then
				testParams = params.activity_ids
			end

			dump(testParams, "testParams")
			xyd.openWindow("activity_window", {
				activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_HW2022),
				onlyShowList = testParams,
				select = xyd.ActivityID.ACTIVITY_HW2022
			})
		end)
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.RECHARGE, function (evt)
		self:updateList()
	end, self)
end

function ActivityHw2022Supply:getUIComponent()
	local goTrans = self.go.transform
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.content_ = goTrans:NodeByName("content").gameObject

	for i = 1, 4 do
		self["labelTips" .. i] = self.content_:ComponentByName("labelGroup/label" .. i, typeof(UILabel))
		self["labelTips" .. i].text = __("ACTIVITY_HALLOWEEN2022_GIFTBAG_TEXT0" .. i)
	end

	self.itemGrid_ = goTrans:ComponentByName("content/itemGrid", typeof(UIGrid))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.jumpBtn_ = goTrans:NodeByName("jumpBtn").gameObject
	self.jumpBtnLabel_ = goTrans:ComponentByName("jumpBtn/label", typeof(UILabel))
	self.itemRoot_ = goTrans:NodeByName("itemRoot").gameObject
	self.progressBar_ = goTrans:ComponentByName("content/progressBar", typeof(UIProgressBar))
end

function ActivityHw2022Supply:updateHeight()
	self:resizePosY(self.logoImg_.gameObject, 15, 5)
	self:resizePosY(self.jumpBtn_.gameObject, -77, -97)
	self:resizePosY(self.content_.gameObject, -135, -175)
	self:resizePosY(self.itemGrid_.gameObject, -163, -178)

	self.itemGrid_.cellHeight = 127 + 17 * self.scale_num_contrary
	self.progressBar_.transform:GetComponent(typeof(UIWidget)).height = 432 + 68 * self.scale_num_contrary
end

function ActivityHw2022Supply:onGetAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_HW2022_SUPPLY then
		return
	end

	if type(data) == "number" then
		self:updateList()
	else
		local data_ = xyd.decodeProtoBuf(data)
		local info = require("cjson").decode(data_.detail)
		local items = info.items

		xyd.itemFloat(items)
		self:updateList()
	end
end

function ActivityHw2022Supply:updateProgressBar()
	local point = self.activityData:getPointNow()
	local maxPoint = tonumber(xyd.tables.miscTable:getVal("activity_halloween2022_limit_max"))

	if point / maxPoint < 0.125 then
		self.progressBar_.value = 0
	elseif point / maxPoint >= 0.125 and point / maxPoint < 0.25 then
		self.progressBar_.value = math.max(0.01, point / maxPoint - 0.235)
	elseif point / maxPoint >= 0.25 and point / maxPoint < 0.5 then
		self.progressBar_.value = point / maxPoint - 0.18
	else
		self.progressBar_.value = point / maxPoint
	end
end

function ActivityHw2022Supply:layout()
	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_hw2022_bp_logo_" .. xyd.Global.lang)

	self.jumpBtnLabel_.text = __("ACTIVITY_HALLOWEEN2022_GIFTBAG_BUTTON01")

	self:updateList()
end

function ActivityHw2022Supply:updateList(resetPosition)
	local ids = xyd.tables.activityHw2022GiftbagTable:getIDs()

	for index, id in ipairs(ids) do
		if not self.supplyItemList_[index] then
			local newRoot = NGUITools.AddChild(self.itemGrid_.gameObject, self.itemRoot_)

			newRoot:SetActive(true)

			self.supplyItemList_[index] = SupplyItem.new(newRoot, self)
		end

		self.supplyItemList_[index]:setInfo(id)
	end

	if resetPosition then
		self.itemGrid_:Reposition()
	end
end

function SupplyItem:ctor(go, parent)
	self.parent_ = parent
	self.awardItemList_ = {}

	SupplyItem.super.ctor(self, go)
end

function SupplyItem:initUI()
	SupplyItem.super.initUI(self)
	self:getUIComponent()
end

function SupplyItem:getUIComponent()
	local goTrans = self.go.transform
	self.scroeLabel_ = goTrans:ComponentByName("scroeLabel", typeof(UILabel))
	self.iconRoot1_ = goTrans:NodeByName("iconRoot1").gameObject
	self.vipLabel_ = goTrans:ComponentByName("vipLabel", typeof(UILabel))
	self.awardBtn_ = goTrans:NodeByName("awardBtn").gameObject
	self.awardBtnLabel_ = goTrans:ComponentByName("awardBtn/curPrice", typeof(UILabel))
	self.scrollView_ = goTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = goTrans:ComponentByName("scrollView/grid", typeof(UILayout))
	UIEventListener.Get(self.awardBtn_).onClick = handler(self, self.touchAward)
end

function SupplyItem:setInfo(id)
	local activityData = self.parent_.activityData
	self.id_ = id
	local point = xyd.tables.activityHw2022GiftbagTable:getPoint(self.id_)
	self.scroeLabel_.text = point
	local awardTime = xyd.tables.activityHw2022GiftbagTable:getOpenTime(self.id_)
	local award = xyd.tables.activityHw2022GiftbagTable:getAwards(self.id_)
	local freeClick = nil

	if not activityData.detail.awards[self.id_] or activityData.detail.awards[self.id_] ~= 1 then
		function freeClick()
			if awardTime <= xyd.getServerTime() then
				local params = cjson.encode({
					award_id = self.id_
				})

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_HW2022_SUPPLY, params)
			else
				xyd.alertTips(__("ACTIVITY_HALLOWEEN2022_GIFTBAG_TIPS01", point))
			end
		end
	end

	if not self.freeIcon then
		self.freeIcon = xyd.getItemIcon({
			wndType = 5,
			scale = 0.7129629629629629,
			uiRoot = self.iconRoot1_,
			itemID = award[1],
			num = award[2],
			callback = freeClick
		})
	end

	if activityData.detail.awards[self.id_] and activityData.detail.awards[self.id_] == 1 then
		self.freeIcon:setChoose(true)
		self.freeIcon:setEffect(false)
	else
		self.freeIcon:setChoose(false)

		if awardTime <= xyd.getServerTime() then
			local effect = "bp_available"

			self.freeIcon:setEffect(true, effect, {
				effectPos = Vector3(0, -2, 0),
				effectScale = Vector3(1.1, 1.1, 1.1),
				target = self.target_
			})
		else
			self.freeIcon:setEffect(false)
		end
	end

	local giftbag_id = xyd.tables.activityHw2022GiftbagTable:getGiftbagID(self.id_)
	self.vipLabel_.text = "+" .. xyd.tables.giftBagTable:getVipExp(giftbag_id) .. " VIP EXP"
	self.awardBtnLabel_.text = tostring(xyd.tables.giftBagTextTable:getCurrency(giftbag_id)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(giftbag_id))
	local charges = activityData.detail.charges
	self.hasBuy = false

	for _, info in ipairs(charges) do
		if info.table_id == giftbag_id and info.limit_times <= info.buy_times then
			self.hasBuy = true
		end
	end

	local giftID = xyd.tables.giftBagTable:getGiftID(giftbag_id)
	local awards = xyd.tables.giftTable:getAwards(giftID)
	local awardNewArr = {}

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			table.insert(awardNewArr, data)
		end
	end

	for i = 1, #awardNewArr do
		local data = awardNewArr[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local scale = 0.7129629629629629
			local icaonGroup = self.grid_.gameObject
			local item = {
				show_has_num = true,
				labelNumScale = 1.2,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = icaonGroup,
				scale = Vector3(0.7129629629629629, 0.7129629629629629, 0.7129629629629629),
				dragScrollView = self.scrollView_
			}

			if not self.awardItemList_[i] then
				self.awardItemList_[i] = xyd.getItemIcon(item)
			end

			self.awardItemList_[i]:setChoose(self.hasBuy)
		end
	end

	self:waitForFrame(1, function ()
		self.grid_:Reposition()
		self.scrollView_:ResetPosition()
	end)

	if self.hasBuy then
		self.awardBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.awardBtn_.gameObject)
	end
end

function SupplyItem:touchAward()
	local point = xyd.tables.activityHw2022GiftbagTable:getPoint(self.id_)
	local awardTime = xyd.tables.activityHw2022GiftbagTable:getOpenTime(self.id_)

	if xyd.getServerTime() < awardTime then
		xyd.alertTips(__("ACTIVITY_HALLOWEEN2022_GIFTBAG_TIPS01", point))

		return
	end

	local giftbag_id = xyd.tables.activityHw2022GiftbagTable:getGiftbagID(self.id_)

	xyd.SdkManager.get():showPayment(giftbag_id)
end

return ActivityHw2022Supply
