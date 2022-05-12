local NewTrialBattlepass = class("NewTrialBattlepass", import(".ActivityContent"))
local TrialBattlePassItem = class("TrialBattlePassItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function TrialBattlePassItem:ctor(go, parent)
	TrialBattlePassItem.super.ctor(self, go)

	self.parent_ = parent
	self.paidItemList_ = {}
	self.paidOpItemList_ = {}
end

function TrialBattlePassItem:initUI()
	TrialBattlePassItem.super.initUI()
	self:getUIComponent()
end

function TrialBattlePassItem:getUIComponent()
	local goTrans = self.go.transform
	self.levLabel_ = goTrans:ComponentByName("levLabel", typeof(UILabel))
	self.itemGroup1_ = goTrans:ComponentByName("itemGroup1", typeof(UILayout))
	self.itemGroup2_ = goTrans:ComponentByName("itemGroup2", typeof(UILayout))
	self.awardBtn_ = goTrans:NodeByName("awardBtn").gameObject
	self.awardMask_ = goTrans:NodeByName("awardBtn/mask").gameObject
	self.awardLabel_ = goTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.itemIcon_ = goTrans:NodeByName("itemIcon").gameObject
	UIEventListener.Get(self.awardBtn_).onClick = handler(self, self.onClickAwardBtn)
end

function TrialBattlePassItem:onClickAwardBtn()
	if self.isAwarded_ and self.isAwarded_ == 1 and (not self.isExawarded_ or self.isExawarded_ ~= 1) and not self.parent_.activityData:checkBuy() then
		xyd.WindowManager.get():openWindow("new_trial_battlepass_check_award_window", {})
	else
		local expNow = self.parent_.activityData.detail.point

		if self.needExp_ <= expNow then
			self.parent_:awardItems()
		end
	end
end

function TrialBattlePassItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.info_ = info
	self.id_ = info.id
	self.index_ = info.index
	self.isAwarded_ = tonumber(info.is_awarded)
	self.isExawarded_ = tonumber(info.is_exawarded)
	self.needExp_ = info.need_exp
	self.levLabel_.text = self.needExp_
	self.traget_ = info.traget
	local expNow = self.parent_.activityData.detail.point

	if self.needExp_ <= expNow then
		self.levLabel_.color = Color.New2(4293307391.0)
		self.levLabel_.effectColor = Color.New2(3311934868.0)

		if not self.parent_.activityData:checkBuy() and self.isAwarded_ == 1 then
			self.awardLabel_.text = __("NEW_TRIAL_BATTLEPASS_TEXT10")
		else
			self.awardLabel_.text = __("NEW_TRIAL_BATTLEPASS_TEXT09")
		end

		if self.isAwarded_ ~= 1 or self.isExawarded_ ~= 1 then
			self.awardMask_:SetActive(false)
		else
			self.awardMask_:SetActive(true)
		end
	else
		self.levLabel_.color = Color.New2(1616336895)
		self.levLabel_.effectColor = Color.New2(4294569983.0)

		self.awardMask_:SetActive(true)

		self.awardLabel_.text = __("NEW_TRIAL_BATTLEPASS_TEXT09")
	end

	self:updateItemList()
end

function TrialBattlePassItem:refresh()
	self:update(nil, , self.info_)
end

function TrialBattlePassItem:updateItemList()
	local freeAwards = xyd.tables.newTrialBattlePassAwardsTable:getFreeAwards(self.id_)
	local freeOpAwards = xyd.tables.newTrialBattlePassAwardsTable:getFreeOptionalAwards(self.id_)
	local freeOpAward = freeOpAwards[self.index_]
	local paidAwards = xyd.tables.newTrialBattlePassAwardsTable:getPaidAwards(self.id_)
	local paidOpAwards = xyd.tables.newTrialBattlePassAwardsTable:getPaidOptionalAwards(self.id_)
	local paidOpAward = paidOpAwards[self.index_]

	for index, itemData in ipairs(paidAwards) do
		if not self.paidItemList_[index] then
			local newItemRoot = NGUITools.AddChild(self.itemGroup2_.gameObject, self.itemIcon_)

			newItemRoot.transform:SetSiblingIndex(index)

			local itemIcon = xyd.getItemIcon({
				notShowGetWayBtn = true,
				scale = 0.6296296296296297,
				show_has_num = true,
				itemID = itemData[1],
				num = itemData[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = newItemRoot,
				dragScrollView = self.parent_.scrollView_
			}, nil, 11)
			self.paidItemList_[index] = {
				itemIcon = itemIcon,
				itemRoot = newItemRoot
			}
		else
			local type_ = xyd.tables.itemTable:getType(itemData[1])
			local type = self.paidItemList_[index].itemIcon:getIconType()

			if type_ ~= xyd.ItemType.HERO_DEBRIS and type_ ~= xyd.ItemType.HERO and type_ ~= xyd.ItemType.HERO_RANDOM_DEBRIS and type_ ~= xyd.ItemType.SKIN and type ~= "item_icon" or (type_ == xyd.ItemType.HERO_DEBRIS or type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.HERO_RANDOM_DEBRIS or type_ == xyd.ItemType.SKIN) and type ~= "hero_icon" then
				NGUITools.Destroy(self.paidItemList_[index].itemIcon:getGameObject())

				local newItemRoot = self.paidItemList_[index].itemRoot
				local itemIcon = xyd.getItemIcon({
					notShowGetWayBtn = true,
					scale = 0.6296296296296297,
					show_has_num = true,
					itemID = itemData[1],
					num = itemData[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					uiRoot = newItemRoot,
					dragScrollView = self.parent_.scrollView_
				}, nil, 11)

				newItemRoot.transform:SetSiblingIndex(index - 1)

				self.paidItemList_[index] = {
					itemIcon = itemIcon,
					itemRoot = newItemRoot
				}
			else
				self.paidItemList_[index].itemIcon:setInfo({
					notShowGetWayBtn = true,
					show_has_num = true,
					scale = 0.6296296296296297,
					itemID = itemData[1],
					num = itemData[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY
				})
			end
		end
	end

	for index, item in ipairs(self.paidItemList_) do
		if index > #paidAwards then
			item.itemRoot:SetActive(false)
		else
			item.itemRoot:SetActive(true)
		end
	end

	if freeAwards and freeAwards[1] and tonumber(freeAwards[1]) > 0 then
		if not self.freeAwardItem then
			self.freeAwardRoot = NGUITools.AddChild(self.itemGroup1_.gameObject, self.itemIcon_)
			self.freeAwardItem = xyd.getItemIcon({
				notShowGetWayBtn = true,
				scale = 0.6296296296296297,
				show_has_num = true,
				itemID = freeAwards[1],
				num = freeAwards[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = self.freeAwardRoot,
				dragScrollView = self.parent_.scrollView_
			}, nil, 11)
		else
			self.freeAwardRoot.transform:SetSiblingIndex(1)
			self.freeAwardRoot:SetActive(true)
			self.freeAwardItem:setInfo({
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.6296296296296297,
				itemID = freeAwards[1],
				num = freeAwards[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	elseif self.freeAwardRoot then
		self.freeAwardRoot:SetActive(false)
	end

	if not self.freeOpItem_ then
		local newItemRoot = NGUITools.AddChild(self.itemGroup1_.gameObject, self.itemIcon_)

		UIEventListener.Get(newItemRoot).onClick = function ()
			xyd.WindowManager.get():openWindow("new_trial_battlepass_select_award_window", {})
		end

		newItemRoot.transform:SetSiblingIndex(0)

		local newItemIcon = nil

		if freeOpAward and freeOpAward[1] and freeOpAward[1] > 0 then
			newItemIcon = xyd.getItemIcon({
				notShowGetWayBtn = true,
				scale = 0.6296296296296297,
				show_has_num = true,
				itemID = freeOpAward[1],
				num = freeOpAward[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = newItemRoot,
				dragScrollView = self.parent_.scrollView_
			}, nil, 11)
		end

		self.freeOpItem_ = {
			itemRoot = newItemRoot,
			itemIcon = newItemIcon
		}
	elseif self.freeOpItem_.itemIcon then
		local type_ = xyd.tables.itemTable:getType(freeOpAward[1])
		local type = self.freeOpItem_.itemIcon:getIconType()

		if type_ ~= xyd.ItemType.HERO_DEBRIS and type_ ~= xyd.ItemType.HERO and type_ ~= xyd.ItemType.HERO_RANDOM_DEBRIS and type_ ~= xyd.ItemType.SKIN and type ~= "item_icon" or (type_ == xyd.ItemType.HERO_DEBRIS or type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.HERO_RANDOM_DEBRIS or type_ == xyd.ItemType.SKIN) and type ~= "hero_icon" then
			NGUITools.Destroy(self.freeOpItem_.itemIcon:getGameObject())

			local newItemRoot = self.freeOpItem_.itemRoot
			local newItemIcon = xyd.getItemIcon({
				notShowGetWayBtn = true,
				scale = 0.6296296296296297,
				show_has_num = true,
				itemID = freeOpAward[1],
				num = freeOpAward[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = newItemRoot,
				dragScrollView = self.parent_.scrollView_
			}, nil, 11)
			self.freeOpItem_ = {
				itemRoot = newItemRoot,
				itemIcon = newItemIcon
			}
		else
			self.freeOpItem_.itemIcon:setInfo({
				itemID = freeOpAward[1],
				num = freeOpAward[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	elseif freeOpAward and freeOpAward[1] and freeOpAward[1] > 0 then
		local newItemRoot = self.freeOpItem_.itemRoot
		local newItemIcon = xyd.getItemIcon({
			notShowGetWayBtn = true,
			scale = 0.6296296296296297,
			show_has_num = true,
			itemID = freeOpAward[1],
			num = freeOpAward[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			uiRoot = newItemRoot,
			dragScrollView = self.parent_.scrollView_
		}, nil, 11)
		self.freeOpItem_ = {
			itemRoot = newItemRoot,
			itemIcon = newItemIcon
		}
	end

	self.itemGroup1_:Reposition()

	if not self.paidOpItem_ then
		local newItemRoot = NGUITools.AddChild(self.itemGroup2_.gameObject, self.itemIcon_)

		newItemRoot.transform:SetSiblingIndex(0)

		UIEventListener.Get(newItemRoot).onClick = function ()
			xyd.WindowManager.get():openWindow("new_trial_battlepass_select_award_window", {})
		end

		local newItemIcon = nil

		if paidOpAward and paidOpAward[1] and paidOpAward[1] > 0 then
			newItemIcon = xyd.getItemIcon({
				notShowGetWayBtn = true,
				scale = 0.6296296296296297,
				show_has_num = true,
				itemID = paidOpAward[1],
				num = paidOpAward[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = newItemRoot,
				dragScrollView = self.parent_.scrollView_
			}, nil, 11)
		end

		self.paidOpItem_ = {
			itemRoot = newItemRoot,
			itemIcon = newItemIcon
		}
	elseif self.paidOpItem_.itemIcon then
		local type_ = xyd.tables.itemTable:getType(paidOpAward[1])
		local type = self.paidOpItem_.itemIcon:getIconType()

		if type_ ~= xyd.ItemType.HERO_DEBRIS and type_ ~= xyd.ItemType.HERO and type_ ~= xyd.ItemType.HERO_RANDOM_DEBRIS and type_ ~= xyd.ItemType.SKIN and type ~= "item_icon" or (type_ == xyd.ItemType.HERO_DEBRIS or type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.HERO_RANDOM_DEBRIS or type_ == xyd.ItemType.SKIN) and type ~= "hero_icon" then
			NGUITools.Destroy(self.paidOpItem_.itemIcon:getGameObject())

			local newItemRoot = self.paidOpItem_.itemRoot
			local newItemIcon = xyd.getItemIcon({
				notShowGetWayBtn = true,
				scale = 0.6296296296296297,
				show_has_num = true,
				itemID = paidOpAward[1],
				num = paidOpAward[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = newItemRoot,
				dragScrollView = self.parent_.scrollView_
			}, nil, 11)
			self.paidOpItem_ = {
				itemRoot = newItemRoot,
				itemIcon = newItemIcon
			}
		else
			self.paidOpItem_.itemIcon:setInfo({
				itemID = paidOpAward[1],
				num = paidOpAward[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	elseif paidOpAward and paidOpAward[1] and paidOpAward[1] > 0 then
		local newItemRoot = self.paidOpItem_.itemRoot
		local newItemIcon = xyd.getItemIcon({
			notShowGetWayBtn = true,
			scale = 0.6296296296296297,
			show_has_num = true,
			itemID = paidOpAward[1],
			num = paidOpAward[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			uiRoot = newItemRoot,
			dragScrollView = self.parent_.scrollView_
		}, nil, 11)
		self.paidOpItem_ = {
			itemRoot = newItemRoot,
			itemIcon = newItemIcon
		}
	end

	self.itemGroup2_:Reposition()

	if self.needExp_ <= self.parent_.activityData.detail.point and self.isAwarded_ == 0 then
		if self.freeAwardItem then
			local effect = "bp_available"

			self.freeAwardItem:setEffect(true, effect, {
				effectPos = Vector3(0, -2, 0),
				effectScale = Vector3(1.1, 1.1, 1.1),
				target = self.target_
			})
		end

		if self.freeOpItem_.itemIcon then
			local effect = "bp_available"

			self.freeOpItem_.itemIcon:setEffect(true, effect, {
				effectPos = Vector3(0, -2, 0),
				effectScale = Vector3(1.1, 1.1, 1.1),
				target = self.target_
			})
		end
	else
		if self.freeAwardItem then
			self.freeAwardItem:setEffectState(false)
		end

		if self.freeOpItem_.itemIcon then
			self.freeOpItem_.itemIcon:setEffectState(false)
		end
	end

	if self.parent_.activityData:checkBuy() and self.needExp_ <= self.parent_.activityData.detail.point and self.isExawarded_ == 0 then
		for _, item in ipairs(self.paidItemList_) do
			local effect = "bp_available"

			item.itemIcon:setEffect(true, effect, {
				effectPos = Vector3(0, -2, 0),
				effectScale = Vector3(1.1, 1.1, 1.1),
				target = self.target_
			})
		end

		if self.paidOpItem_.itemIcon then
			local effect = "bp_available"

			self.paidOpItem_.itemIcon:setEffect(true, effect, {
				effectPos = Vector3(0, -2, 0),
				effectScale = Vector3(1.1, 1.1, 1.1),
				target = self.target_
			})
		end
	else
		for _, item in ipairs(self.paidItemList_) do
			item.itemIcon:setEffectState(false)
		end

		if self.paidOpItem_.itemIcon then
			self.paidOpItem_.itemIcon:setEffectState(false)
		end
	end

	if self.isAwarded_ and self.isAwarded_ == 1 then
		if self.freeAwardItem then
			self.freeAwardItem:setChoose(true)
		end

		if self.freeOpItem_.itemIcon then
			self.freeOpItem_.itemIcon:setChoose(true)
		end
	else
		if self.freeAwardItem then
			self.freeAwardItem:setChoose(false)
		end

		if self.freeOpItem_.itemIcon then
			self.freeOpItem_.itemIcon:setChoose(false)
		end
	end

	if not self.parent_.activityData:checkBuy() then
		if self.isExawarded_ and self.isExawarded_ == 1 then
			for _, item in ipairs(self.paidItemList_) do
				item.itemIcon:setChoose(true)
			end

			if self.paidOpItem_.itemIcon then
				self.paidOpItem_.itemIcon:setChoose(true)
			end
		else
			for _, item in ipairs(self.paidItemList_) do
				item.itemIcon:setChoose(false)
			end

			if self.paidOpItem_.itemIcon then
				self.paidOpItem_.itemIcon:setChoose(false)
			end
		end

		for _, item in ipairs(self.paidItemList_) do
			item.itemIcon:setLock(true)
		end

		if self.paidOpItem_.itemIcon then
			self.paidOpItem_.itemIcon:setLock(true)
		end
	else
		for _, item in ipairs(self.paidItemList_) do
			item.itemIcon:setLock(false)
		end

		if self.paidOpItem_.itemIcon then
			self.paidOpItem_.itemIcon:setLock(false)
		end

		if self.isExawarded_ and self.isExawarded_ == 1 then
			for _, item in ipairs(self.paidItemList_) do
				item.itemIcon:setChoose(true)
			end

			if self.paidOpItem_.itemIcon then
				self.paidOpItem_.itemIcon:setChoose(true)
			end
		else
			for _, item in ipairs(self.paidItemList_) do
				item.itemIcon:setChoose(false)
			end

			if self.paidOpItem_.itemIcon then
				self.paidOpItem_.itemIcon:setChoose(false)
			end
		end
	end
end

function NewTrialBattlepass:ctor(parentGO, params)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS, function ()
		NewTrialBattlepass.super.ctor(self, parentGO, params)
	end)
end

function NewTrialBattlepass:getPrefabPath()
	return "Prefabs/Windows/activity/activity_trial_battlepass"
end

function NewTrialBattlepass:resizeToParent()
	NewTrialBattlepass.super.resizeToParent(self)
end

function NewTrialBattlepass:initUI()
	NewTrialBattlepass.super.initUI(self)
	dump(self.activityData.detail, "NewTrialBattlepass")
	self:getUIComponent()
	self:layout()
	self:initList()
	self:register()
end

function NewTrialBattlepass:getUIComponent()
	local goTrans = self.go.transform
	self.btnHelp_ = goTrans:NodeByName("btnHelp").gameObject
	self.btnChange_ = goTrans:NodeByName("btnChange").gameObject
	self.textImg_ = goTrans:ComponentByName("textImg", typeof(UISprite))
	self.btnBuy_ = goTrans:NodeByName("btnBuy").gameObject
	self.btnBuyLabel_ = goTrans:ComponentByName("btnBuy/label", typeof(UILabel))
	self.timeLabel_ = goTrans:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.timeEnd_ = goTrans:ComponentByName("timeGroup/timeEnd", typeof(UILabel))
	self.effectTarget_ = goTrans:ComponentByName("effectGroup/effectTarget", typeof(UITexture))
	self.energyGroup_ = goTrans:NodeByName("energyGroup")
	self.labelTips_ = self.energyGroup_:ComponentByName("labelTips", typeof(UILabel))
	self.progressBar_ = self.energyGroup_:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel_ = self.energyGroup_:ComponentByName("progressLabel", typeof(UILabel))
	self.addImg_ = self.energyGroup_:NodeByName("addImg").gameObject
	self.jumpBtn_ = self.energyGroup_:NodeByName("jumpBtn").gameObject
	self.jumpBtnLabel_ = self.energyGroup_:ComponentByName("jumpBtn/label", typeof(UILabel))
	self.scrollView_ = goTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.wrapContent = self.scrollView_:ComponentByName("grid", typeof(MultiRowWrapContent))
	self.itemRoot_ = goTrans:NodeByName("itemRoot").gameObject

	for i = 1, 4 do
		self["textlabel" .. i] = goTrans:ComponentByName("labelGroup/label" .. i, typeof(UILabel))
		self["textlabel" .. i].text = __("NEW_TRIAL_BATTLEPASS_TEXT0" .. 3 + i)
	end
end

function NewTrialBattlepass:layout()
	xyd.setUISpriteAsync(self.textImg_, nil, "trial_battlepass_" .. xyd.Global.lang)

	self.btnBuyLabel_.text = __("NEW_TRIAL_BATTLEPASS_TEXT03")
	self.labelTips_.text = __("NEW_TRIAL_BATTLEPASS_TEXT02")
	self.jumpBtnLabel_.text = __("NEW_TRIAL_BATTLEPASS_TEXT08")

	self:updateProgressBar()

	local updateTime = self.activityData.update_time
	local leftTime = updateTime + xyd.tables.activityTable:getLastTime(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS) - xyd.getServerTime()
	local params = {
		key = "ACTIVITY_END_COUNT",
		duration = leftTime
	}

	if not self.countDonwLabel_ then
		self.countDonwLabel_ = CountDown.new(self.timeEnd_, params)
	else
		self.countDonwLabel_:setInfo(params)
	end

	local openTime = xyd.db.misc:getValue("new_trial_battle_pass_choose_open_time")

	if self.activityData:getIndexChoose() == 0 and (not openTime or tonumber(openTime) < tonumber(updateTime)) then
		xyd.WindowManager.get():openWindow("new_trial_battlepass_select_award_window", {})
		xyd.db.misc:setValue({
			key = "new_trial_battle_pass_choose_open_time",
			value = xyd.getServerTime()
		})
	end

	if self.activityData:checkBuy() then
		xyd.setEnabled(self.btnBuy_, false)
	end

	if not self.activityData:checkCanChangeAward() then
		self.btnChange_:SetActive(false)
	end
end

function NewTrialBattlepass:updateProgressBar()
	local maxValue = 3000
	local point = self.activityData.detail.point

	if point > 3000 then
		point = 3000
	end

	self.progressBar_.value = point / maxValue
	self.progressLabel_.text = point .. "/" .. maxValue
end

function NewTrialBattlepass:register()
	UIEventListener.Get(self.btnHelp_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "NEW_TRIAL_BATTLEPASS_HELP"
		})
	end

	UIEventListener.Get(self.addImg_).onClick = function ()
		if self.activityData:getRestCanBuy() <= 0 and self.activityData:checkBuy() and self.activityData:getUpdateTime() - xyd.getServerTime() > 24 * xyd.HOUR then
			xyd.alertTips(__("NEW_TRIAL_BATTLEPASS_TEXT22"))

			return
		elseif self.activityData:getRestCanBuy() <= 0 and self.activityData:checkBuy() and self.activityData:getUpdateTime() - xyd.getServerTime() < 24 * xyd.HOUR then
			xyd.alertTips(__("NEW_TRIAL_BATTLEPASS_TEXT24"))

			return
		elseif self.activityData:getRestCanBuy() <= 0 and self.activityData:getUpdateTime() - xyd.getServerTime() <= 24 * xyd.HOUR then
			xyd.alertTips(__("NEW_TRIAL_BATTLEPASS_TEXT20"))

			return
		elseif self.activityData:getRestCanBuy() <= 0 then
			xyd.alertTips(__("NEW_TRIAL_BATTLEPASS_TEXT20"))

			return
		end

		xyd.WindowManager.get():openWindow("new_trial_battlepass_buy_point_window", {})
	end

	UIEventListener.Get(self.btnChange_).onClick = function ()
		if self.activityData:checkCanChangeAward() then
			xyd.WindowManager.get():openWindow("new_trial_battlepass_select_award_window", {})
		else
			xyd.alertTips(__("NEW_TRIAL_BATTLEPASS_TEXT18"))
		end
	end

	UIEventListener.Get(self.btnBuy_).onClick = function ()
		if self.activityData:getIndexChoose() > 0 then
			xyd.WindowManager.get():openWindow("new_trial_battlepass_check_award_window2", {})
		else
			xyd.alertTips(__("NEW_TRIAL_BATTLEPASS_TEXT17"))
			xyd.WindowManager.get():openWindow("new_trial_battlepass_select_award_window", {})
		end
	end

	UIEventListener.Get(self.jumpBtn_).onClick = function ()
		if xyd.checkFunctionOpen(xyd.FunctionID.TRIAL) then
			xyd.WindowManager.get():openWindow("trial_enter_window", {}, function ()
				local params = {
					main_window = true,
					loading_window = true,
					guide_window = true,
					trial_enter_window = true
				}

				xyd.WindowManager.get():closeAllWindows(params, false)
			end)
		end
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function NewTrialBattlepass:initList()
	local ids = xyd.tables.newTrialBattlePassAwardsTable:getIDs()
	local infoList = {}

	for _, id in ipairs(ids) do
		local params = {
			id = id,
			index = self.activityData:getIndexChoose(),
			is_awarded = self.activityData.detail.awarded[id],
			is_exawarded = self.activityData.detail.ex_awarded[id],
			need_exp = xyd.tables.newTrialBattlePassAwardsTable:getExp(id),
			target = self.effectTarget_
		}

		table.insert(infoList, params)
	end

	local pointNow = self.activityData.detail.point

	table.sort(infoList, function (a, b)
		local valueA = a.id

		if a.is_awarded == 1 and a.is_exawarded == 1 then
			valueA = valueA + 10000
		end

		if pointNow < a.need_exp then
			valueA = valueA + 1000
		end

		local valueB = b.id

		if b.is_awarded == 1 and b.is_exawarded == 1 then
			valueB = valueB + 10000
		end

		if pointNow < b.need_exp then
			valueB = valueB + 1000
		end

		return valueA < valueB
	end)

	self.infos_ = infoList
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.wrapContent, self.itemRoot_, TrialBattlePassItem, self)

	self.multiWrap_:setInfos(self.infos_, {})
end

function NewTrialBattlepass:updateList()
	for _, info in ipairs(self.infos_) do
		local id = info.id
		info.index = self.activityData:getIndexChoose()
		info.is_awarded = self.activityData.detail.awarded[id]
		info.is_exawarded = self.activityData.detail.ex_awarded[id]
	end

	self.multiWrap_:setInfos(self.infos_, {
		keepPostion = true
	})
end

function NewTrialBattlepass:refreshList()
	local items = self.multiWrap_:getItems()

	for _, item in ipairs(items) do
		item:refresh()
	end
end

function NewTrialBattlepass:awardItems()
	local awardList = {}

	if self.activityData:getIndexChoose() == 0 then
		xyd.alertTips(__("NEW_TRIAL_BATTLEPASS_TEXT17"))
		xyd.WindowManager.get():openWindow("new_trial_battlepass_select_award_window", {})

		return
	end

	for _, info in ipairs(self.infos_) do
		local id = info.id

		if info.need_exp <= self.activityData.detail.point and (self.activityData.detail.awarded[id] == 0 or self.activityData:checkBuy() and self.activityData.detail.ex_awarded[id] == 0) then
			table.insert(awardList, id)
		end
	end

	if self.activityData:checkCanChangeAward() then
		local index = self.activityData:getIndexChoose()
		local freeOpAwards = xyd.tables.newTrialBattlePassAwardsTable:getFreeOptionalAwards(1)
		local freeOpAward = freeOpAwards[index]

		xyd.alertYesNo(__("NEW_TRIAL_BATTLEPASS_TEXT13", xyd.tables.itemTable:getName(freeOpAward[1])), function (yes_no)
			if yes_no then
				self.activityData:reqAward(awardList)
			end
		end)
	else
		self.activityData:reqAward(awardList)
	end
end

function NewTrialBattlepass:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if giftBagID ~= 420 then
		return
	end

	self:updateList()
	xyd.setEnabled(self.btnBuy_, false)
end

function NewTrialBattlepass:onAward(event)
	if event.data.activity_id == xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS then
		local info = cjson.decode(event.data.detail)

		dump(info)
		self:updateList()

		if info.type == 1 then
			self.btnChange_:SetActive(false)

			local items = info.items

			xyd.itemFloat(items)
		elseif info.type == 2 then
			self:updateProgressBar()
		end
	end
end

return NewTrialBattlepass
