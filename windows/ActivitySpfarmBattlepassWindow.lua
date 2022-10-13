local ActivitySpfarmBattlepassWindow = class("ActivitySpfarmBattlepassWindow", import(".BaseWindow"))
local SpfarmLevelItem = class("SpfarmLevelItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivitySpfarmBattlepassWindow:ctor(name, params)
	ActivitySpfarmBattlepassWindow.super.ctor(self, name, params)

	self.spFarmActivityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
	self.levelItems_ = {}
end

function ActivitySpfarmBattlepassWindow:initWindow()
	ActivitySpfarmBattlepassWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:updateList(true)
	self:register()
end

function ActivitySpfarmBattlepassWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.logoImg_ = winTrans:ComponentByName("logoImg", typeof(UISprite))
	self.timeGroup_ = winTrans:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = winTrans:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel_ = winTrans:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.descLabel_ = winTrans:ComponentByName("descBg/descLabel", typeof(UILabel))
	self.buyBtn_ = winTrans:NodeByName("buyBtn").gameObject
	self.buyBtnLabel_ = winTrans:ComponentByName("buyBtn/label", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.effectRoot_ = winTrans:NodeByName("effectRoot").gameObject
	local content = winTrans:NodeByName("content").gameObject
	self.tipsLabel1_ = content:ComponentByName("tipsLabel1", typeof(UILabel))
	self.tipsLabel2_ = content:ComponentByName("tipsLabel2", typeof(UILabel))
	self.tipsLabel3_ = content:ComponentByName("tipsLabel3", typeof(UILabel))
	self.scrollView_ = content:ComponentByName("scrollView", typeof(UIScrollView))
	self.progressBar_ = content:ComponentByName("scrollView/progressBar", typeof(UIProgressBar))
	self.progressWidgt_ = content:ComponentByName("scrollView/progressBar", typeof(UIWidget))
	self.layout_ = content:ComponentByName("scrollView/layout", typeof(UILayout))
	self.levelItem_ = content:NodeByName("scrollView/levelItem").gameObject

	self.levelItem_:SetActive(false)

	self.effectTar_ = winTrans:NodeByName("effectGroup/effectTar").gameObject
end

function ActivitySpfarmBattlepassWindow:register()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.buyBtn_).onClick = function ()
		local endTime = self.spFarmActivityData:getEndTime() - self.spFarmActivityData:getViewTimeSec()
		local disTime = endTime - xyd:getServerTime()

		if disTime <= 0 then
			xyd.alertTips(__("ACTIVITY_SPFARM_BATTLEPASS_TIPS02"))

			return
		end

		local params = {
			select = 302,
			activity_type = 7
		}

		xyd.WindowManager.get():closeWindow("activity_spfarm_map_window")
		self:close()
		xyd.goToActivityWindowAgain(params)
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function ActivitySpfarmBattlepassWindow:layout()
	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_spfarm_bp_logo_" .. xyd.Global.lang)

	self.descLabel_.text = __("ACTIVITY_SPFARM_BATTLEPASS_TEXT01")
	self.buyBtnLabel_.text = __("ACTIVITY_SPFARM_BATTLEPASS_TEXT02")
	local totalLev = self.spFarmActivityData:getAllBuildTotalLev()
	self.tipsLabel1_.text = __("ACTIVITY_SPFARM_BATTLEPASS_TEXT03", totalLev)
	self.tipsLabel2_.text = __("ACTIVITY_SPFARM_BATTLEPASS_TEXT04")
	self.tipsLabel3_.text = __("ACTIVITY_SPFARM_BATTLEPASS_TEXT05")

	if self.spFarmActivityData:checkSpecialBuy() then
		self.buyBtnLabel_.text = __("ACTIVITY_SPFARM_BATTLEPASS_TEXT06")
	end

	self.endLabel_.text = __("TEXT_END")
	local leftTime = self.spFarmActivityData:getEndTime() - xyd.getServerTime()
	local params = {
		duration = leftTime
	}

	if not self.countDonwLabel_ then
		self.countDonwLabel_ = import("app.components.CountDown").new(self.timeLabel_, params)
	else
		self.countDonwLabel_:setInfo(params)
	end

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	self.timeGroup_:Reposition()

	self.partnerEffect_ = xyd.Spine.new(self.effectRoot_)

	self.partnerEffect_:setInfo("maya_pifu06_lihui01", function ()
		self.partnerEffect_:play("texiao04", 0, 1)
		self.partnerEffect_:SetLocalPosition(30, -650, 0)
	end)
end

function ActivitySpfarmBattlepassWindow:updateList(resetposition)
	dump(self.spFarmActivityData.detail, "self.spFarmActivityData.detail")

	local awardsData = self.spFarmActivityData.detail.awarded
	local paidsData = self.spFarmActivityData.detail.paid_awarded
	local totalLev = self.spFarmActivityData:getAllBuildTotalLev()
	local hasBuy = self.spFarmActivityData:checkSpecialBuy()
	local ids = xyd.tables.activitySpfarmBattlepassTable:getIDs()
	self.progressWidgt_.height = #ids * 112 - 70
	local maxLev = xyd.tables.activitySpfarmBattlepassTable:getNeedLevel(ids[#ids])

	if maxLev < totalLev then
		totalLev = maxLev
	end

	self.progressBar_.value = totalLev / maxLev

	for index, id in ipairs(ids) do
		if not self.levelItems_[index] then
			local newRoot = NGUITools.AddChild(self.layout_.gameObject, self.levelItem_)

			newRoot:SetActive(true)

			self.levelItems_[index] = SpfarmLevelItem.new(newRoot, self)
		end

		self.levelItems_[index]:setInfo(id, awardsData[tonumber(id)], paidsData[tonumber(id)], totalLev, hasBuy)

		if index == 1 or #ids == index then
			self.layout_:Reposition()
		end
	end

	if resetposition then
		self.scrollView_:ResetPosition()
	end
end

function ActivitySpfarmBattlepassWindow:onClickItem(indexValue)
	local param = {
		type = 22,
		batches = {}
	}
	local ids = xyd.tables.activitySpfarmBattlepassTable:getIDs()
	local totalLev = self.spFarmActivityData:getAllBuildTotalLev()
	local hasBuy = self.spFarmActivityData:checkSpecialBuy()
	local awardsData = self.spFarmActivityData.detail.awarded
	local paidsData = self.spFarmActivityData.detail.paid_awarded

	for _, id in ipairs(ids) do
		local needLevel = xyd.tables.activitySpfarmBattlepassTable:getNeedLevel(id)

		if indexValue == 1 then
			if needLevel <= totalLev and awardsData[id] ~= 1 then
				table.insert(param.batches, {
					id = id,
					index = indexValue
				})
			end
		elseif needLevel <= totalLev and paidsData[id] ~= 1 and hasBuy then
			table.insert(param.batches, {
				id = id,
				index = indexValue
			})
		end
	end

	local params2 = json.encode(param)

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, params2)
end

function ActivitySpfarmBattlepassWindow:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local info = json.decode(data.detail)
	local batch_result = info.batch_result
	local tmpData = {}

	for _, info in ipairs(batch_result) do
		local items = info.items

		for _, item in ipairs(items) do
			local itemID = item.item_id

			if tmpData[itemID] == nil then
				tmpData[itemID] = 0
			end

			tmpData[itemID] = tmpData[item.item_id] + item.item_num
		end
	end

	local datas = {}

	for k, v in pairs(tmpData) do
		table.insert(datas, {
			item_id = tonumber(k),
			item_num = v
		})
	end

	xyd.itemFloat(datas)
	self:updateList()
end

function SpfarmLevelItem:ctor(go, parent)
	self.parent_ = parent
	self.awardItemList_ = {}
	self.paidItemList_ = {}
	self.effectTar_ = self.parent_.effectTar_

	SpfarmLevelItem.super.ctor(self, go)
end

function SpfarmLevelItem:initUI()
	SpfarmLevelItem.super.initUI()
	self:getUIComponent()
end

function SpfarmLevelItem:getUIComponent()
	local goTrans = self.go.transform
	self.maskImg_ = goTrans:NodeByName("levelPart/maskImg").gameObject
	self.levelLabel_ = goTrans:ComponentByName("levelPart/tipsLabel", typeof(UILabel))
	self.itemGrid1_ = goTrans:ComponentByName("itemPart/itemGrid1", typeof(UILayout))
	self.itemGrid2_ = goTrans:ComponentByName("itemPart/itemGrid2", typeof(UILayout))
end

function SpfarmLevelItem:setInfo(id, is_awarded, is_paidAwarded, totalLev, hasBuy)
	self.id_ = id
	self.needLevel_ = xyd.tables.activitySpfarmBattlepassTable:getNeedLevel(id)
	self.levelLabel_.text = self.needLevel_

	if totalLev < self.needLevel_ then
		self.maskImg_:SetActive(true)
	else
		self.maskImg_:SetActive(false)
	end

	local canBuyNormal = false
	local canBuyPaid = false

	if is_awarded ~= 1 and self.needLevel_ <= totalLev then
		canBuyNormal = true
	end

	if is_paidAwarded ~= 1 and self.needLevel_ <= totalLev then
		canBuyPaid = true
	end

	local awardItems = xyd.tables.activitySpfarmBattlepassTable:getNormalAward(self.id_)
	local paidItems = xyd.tables.activitySpfarmBattlepassTable:getPaidAward(self.id_)

	for index, item in ipairs(awardItems) do
		if not self.awardItemList_[index] then
			self.awardItemList_[index] = xyd.getItemIcon({
				scale = 0.7037037037037037,
				isNew = item[1] == 6773,
				uiRoot = self.itemGrid1_.gameObject,
				itemID = item[1],
				num = item[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent_.scrollView_,
				callback = function ()
					if canBuyNormal then
						self.parent_:onClickItem(1)
					else
						local params = {
							notShowNotSell = true,
							showGetWays = false,
							clickCloseWnd = false,
							show_has_num = true,
							itemID = item[1],
							wndType = xyd.ItemTipsWndType.ACTIVITY,
							num = item[2]
						}

						xyd.WindowManager.get():openWindow("item_tips_window", params)
					end
				end
			}, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.awardItemList_[index]:setInfo({
				scale = 0.7037037037037037,
				uiRoot = self.itemGrid1_.gameObject,
				isNew = item[1] == 6773,
				itemID = item[1],
				num = item[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent_.scrollView_,
				callback = function ()
					if canBuyNormal then
						self.parent_:onClickItem(1)
					else
						local params = {
							notShowNotSell = true,
							showGetWays = false,
							clickCloseWnd = false,
							show_has_num = true,
							itemID = item[1],
							wndType = xyd.ItemTipsWndType.ACTIVITY,
							num = item[2]
						}

						xyd.WindowManager.get():openWindow("item_tips_window", params)
					end
				end
			})
		end

		self.awardItemList_[index]:setLockSource("activity_spfarm_bp_lock_img")
		self.awardItemList_[index]:setMaskSource("activity_spfarm_bp_mask2")

		if totalLev < self.needLevel_ then
			if is_awarded == 1 then
				self.awardItemList_[index]:setChoose(true)
			else
				self.awardItemList_[index]:setChoose(false)
			end

			self.awardItemList_[index]:setLock(true, 42, 47)
		else
			self.awardItemList_[index]:setLock(false, 42, 47)

			if is_awarded == 1 then
				self.awardItemList_[index]:setChoose(true)
			else
				self.awardItemList_[index]:setChoose(false)
			end
		end

		if canBuyNormal then
			self.awardItemList_[index]:setEffect(true, "bp_available", {
				effectPos = Vector3(0, -2, 0),
				effectScale = Vector3(1.1, 1.1, 1.1),
				target = self.effectTar_
			})
		else
			self.awardItemList_[index]:setEffect(false)
		end
	end

	for index, item in ipairs(paidItems) do
		if not self.paidItemList_[index] then
			local isNew = item[1] == 6773
			self.paidItemList_[index] = xyd.getItemIcon({
				scale = 0.7037037037037037,
				isNew = isNew,
				uiRoot = self.itemGrid2_.gameObject,
				itemID = item[1],
				num = item[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent_.scrollView_,
				callback = function ()
					if canBuyPaid and hasBuy then
						self.parent_:onClickItem(2)
					elseif not hasBuy then
						xyd.alertTips(__("ACTIVITY_SPFARM_BATTLEPASS_TIPS01"))
					else
						local params = {
							notShowNotSell = true,
							showGetWays = false,
							clickCloseWnd = false,
							show_has_num = true,
							itemID = item[1],
							wndType = xyd.ItemTipsWndType.ACTIVITY,
							num = item[2]
						}

						xyd.WindowManager.get():openWindow("item_tips_window", params)
					end
				end
			}, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.paidItemList_[index]:setInfo({
				scale = 0.7037037037037037,
				uiRoot = self.itemGrid2_.gameObject,
				isNew = item[1] == 6773,
				itemID = item[1],
				num = item[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent_.scrollView_,
				callback = function ()
					if canBuyPaid and hasBuy then
						self.parent_:onClickItem(2)
					elseif not hasBuy then
						xyd.alertTips(__("ACTIVITY_SPFARM_BATTLEPASS_TIPS01"))
					else
						local params = {
							notShowNotSell = true,
							showGetWays = false,
							clickCloseWnd = false,
							show_has_num = true,
							itemID = item[1],
							wndType = xyd.ItemTipsWndType.ACTIVITY,
							num = item[2]
						}

						xyd.WindowManager.get():openWindow("item_tips_window", params)
					end
				end
			})
		end

		self.paidItemList_[index]:setMaskSource("activity_spfarm_bp_mask3")
		self.paidItemList_[index]:setLockSource("activity_spfarm_bp_lock_img")

		if totalLev < self.needLevel_ or not hasBuy then
			if is_paidAwarded == 1 then
				self.paidItemList_[index]:setChoose(true)
			else
				self.paidItemList_[index]:setChoose(false)
			end

			self.paidItemList_[index]:setLock(true, 42, 47)
		else
			self.paidItemList_[index]:setLock(false, 42, 47)

			if is_paidAwarded == 1 then
				self.paidItemList_[index]:setChoose(true)
			else
				self.paidItemList_[index]:setChoose(false)
			end
		end

		if canBuyPaid then
			self.paidItemList_[index]:setEffect(true, "bp_available", {
				effectPos = Vector3(0, -2, 0),
				effectScale = Vector3(1.1, 1.1, 1.1),
				target = self.effectTar_
			})
		else
			self.paidItemList_[index]:setEffect(false)
		end
	end
end

return ActivitySpfarmBattlepassWindow
