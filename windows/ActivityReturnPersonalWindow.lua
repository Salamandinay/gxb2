local ActivityReturnPersonalWindow = class("ActivityReturnMissionWindow", import(".BaseWindow"))
local pMissionItem = class("pMissionItem", import("app.components.CopyComponent"))
local tMissionItem = class("tMissionItem", import("app.components.CopyComponent"))
local returnShopItem = class("returnShopItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local WindowTop = import("app.components.WindowTop")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local cjson = require("cjson")

function ActivityReturnPersonalWindow:ctor(name, params)
	ActivityReturnPersonalWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.RETURN)
	self.cur_select_ = 1

	dump(self.activityData.detail)
end

function ActivityReturnPersonalWindow:initWindow()
	ActivityReturnPersonalWindow.super.initWindow(self)
	self:getComponent()
	self:initTop()
	self:layouUI()
	self:register()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.RETURN)

	self.hasNotGetData_ = true
end

function ActivityReturnPersonalWindow:getComponent()
	local winTrans = self.window_:NodeByName("actionGroup")
	local logoRoot = winTrans:NodeByName("logoRoot")
	local activeHeight = xyd.WindowManager.get():getActiveHeight()

	if activeHeight > 1340 then
		logoRoot:Y(555)
	else
		logoRoot:Y(509)
	end

	self.logoImg_ = winTrans:ComponentByName("logoRoot/logoImg", typeof(UITexture))
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.timeLabel_ = winTrans:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.countLabel_ = winTrans:ComponentByName("timeGroup/countLabel", typeof(UILabel))
	self.navGroup_ = winTrans:NodeByName("content/navGroup").gameObject
	self.teamGroup_ = winTrans:NodeByName("content/teamGroup").gameObject
	self.shopGroup_ = winTrans:NodeByName("content/shopGroup").gameObject
	self.personalGroup_ = winTrans:NodeByName("content/personalGroup").gameObject
	self.scrollTeam_ = self.teamGroup_:ComponentByName("scrollTeam", typeof(UIScrollView))
	self.scrollTeam_grid_ = self.teamGroup_:ComponentByName("scrollTeam/grid", typeof(MultiRowWrapContent))
	self.tMissionItem_ = self.teamGroup_:NodeByName("missionItem").gameObject
	self.teamerGroupTitle_ = self.teamGroup_:ComponentByName("groupTeamer/teamerGroupTitle", typeof(UILabel))
	self.groupApplyTeamer_ = self.teamGroup_:NodeByName("groupTeamer/groupApplyTeamer").gameObject
	self.groupTeamerInfo_ = self.teamGroup_:NodeByName("groupTeamer/groupTeamerInfo").gameObject
	self.textEdit_ = self.groupApplyTeamer_:ComponentByName("e:Group/textEdit_", typeof(UILabel))
	self.textBack_ = self.groupApplyTeamer_:ComponentByName("e:Group/textBack_", typeof(UILabel))
	self.textCancleBtn_ = self.groupApplyTeamer_:NodeByName("e:Group/cancleBtn").gameObject
	self.teamerSendBtn_ = self.groupApplyTeamer_:NodeByName("btnSend_").gameObject
	self.teamerSendBtn_label = self.groupApplyTeamer_:ComponentByName("btnSend_/button_label", typeof(UILabel))
	self.applyTipsLabel_ = self.groupApplyTeamer_:ComponentByName("applyTipsLabel", typeof(UILabel))
	self.teamerPlayerIconRoot_ = self.groupTeamerInfo_:NodeByName("playerIcon").gameObject
	self.teamerPlayerName_ = self.groupTeamerInfo_:ComponentByName("playerName", typeof(UILabel))
	self.teamerIdLabel_ = self.groupTeamerInfo_:ComponentByName("idLabel", typeof(UILabel))
	self.teamerPlayerId_ = self.groupTeamerInfo_:ComponentByName("playerId", typeof(UILabel))
	self.teamerServerLabel_ = self.groupTeamerInfo_:ComponentByName("serverGroup/labelServer", typeof(UILabel))

	xyd.addTextInput(self.textEdit_, {
		type = xyd.TextInputArea.InputSingleLine,
		textBack = __("ACTIVITY_RETURN_PERSONAL_FRIEND_TIPS_2"),
		textBackLabel = self.textBack_
	})

	self.multiWrapTeam_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollTeam_, self.scrollTeam_grid_, self.tMissionItem_, tMissionItem, self)
	self.shopCostIcon_ = self.shopGroup_:ComponentByName("itemCostGroup/costIcon", typeof(UISprite))
	self.shopCostItemNum_ = self.shopGroup_:ComponentByName("itemCostGroup/labelNum", typeof(UILabel))
	self.shopPlusIcon_ = self.shopGroup_:NodeByName("itemCostGroup/plusIcon").gameObject
	self.scrollShop_ = self.shopGroup_:ComponentByName("scrollShop", typeof(UIScrollView))
	self.scrollShop_grid_ = self.shopGroup_:ComponentByName("scrollShop/grid", typeof(MultiRowWrapContent))
	self.shopItem_ = self.shopGroup_:NodeByName("shopItem").gameObject
	self.multiWrapShop_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollShop_, self.scrollShop_grid_, self.shopItem_, returnShopItem, self)
	self.floatItemRoot_ = winTrans:NodeByName("content/itemFloat/root").gameObject
	self.scrollPersonal_ = self.personalGroup_:ComponentByName("scrollPersonal", typeof(UIScrollView))
	self.scrollPersonal_grid_ = self.personalGroup_:ComponentByName("scrollPersonal/grid", typeof(MultiRowWrapContent))
	self.pMissionItem_ = self.personalGroup_:NodeByName("missionItem").gameObject
	self.multiWrapPerson_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollPersonal_, self.scrollPersonal_grid_, self.pMissionItem_, pMissionItem, self)
	self.contentGroupList_ = {
		self.personalGroup_,
		[3] = self.shopGroup_,
		[2] = self.teamGroup_
	}
end

function ActivityReturnPersonalWindow:register()
	ActivityReturnPersonalWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onGetActivityInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAwardShop))
	self.eventProxy_:addEventListener(xyd.event.RETURN_ACTIVITY_APPLY_ACTIVE, handler(self, self.onApplyTeamer))
	self.eventProxy_:addEventListener(xyd.event.RETURN_ACTIVITY_GET_APPLY_PLAYER_SHOW, handler(self, self.onGetPlayerInfo))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))

	UIEventListener.Get(self.teamerSendBtn_).onClick = handler(self, self.onSendApply)

	UIEventListener.Get(self.textCancleBtn_).onClick = function ()
		self.textEdit_.text = " "
		self.textBack_.text = __("ACTIVITY_RETURN_PERSONAL_FRIEND_TIPS_2")
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_RETURN_WINDOW_HELP"
		})
	end

	UIEventListener.Get(self.shopPlusIcon_).onClick = function ()
		xyd.WindowManager.get():openWindow("item_tips_window", {
			itemID = xyd.ItemID.RETURN_ACTIVITY_ITEM,
			wndType = xyd.ItemTipsWndType.BACKPACK
		})
	end
end

function ActivityReturnPersonalWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function ActivityReturnPersonalWindow:layouUI()
	xyd.setUITextureByNameAsync(self.logoImg_, "activity_return_mission_logo_" .. xyd.Global.lang, true)

	self.timeLabel_.text = __("ACTIVITY_PLAYER_RETURN_ALLTIME")
	self.teamerGroupTitle_.text = __("ACTIVITY_RETURN_PERSONAL_FRIEND_TIPS")
	self.applyTipsLabel_.text = __("ACTIVITY_RETURN_PERSONAL_FRIEND_NONE")
	self.textBack_.text = __("ACTIVITY_RETURN_PERSONAL_FRIEND_TIPS_2")
	self.teamerSendBtn_label.text = __("SEND")

	self:startCountDown()
	self:initNav()
end

function ActivityReturnPersonalWindow:initNav()
	if not self.tab_ then
		local chosen = {
			color = Color.New2(4278124287.0),
			effectColor = Color.New2(1030530815)
		}
		local unchosen = {
			color = Color.New2(1348707327),
			effectColor = Color.New2(4294967295.0)
		}
		local colorParams = {
			chosen = chosen,
			unchosen = unchosen
		}
		self.tab_ = CommonTabBar.new(self.navGroup_, 3, function (index)
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

			if self.hasNotGetData_ then
				return
			end

			self:refreshContent(index)
		end, nil, colorParams)
		local tableLabels = {
			__("ACT_RETURN_PERSONAL_NAV_1"),
			__("ACT_RETURN_PERSONAL_NAV_2"),
			__("ACT_RETURN_PERSONAL_NAV_3")
		}

		self.tab_:setTexts(tableLabels)
	end
end

function ActivityReturnPersonalWindow:startCountDown(leftTime)
	local params = {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	}

	if not self.countDown_ then
		self.countDown_ = CountDown.new(self.countLabel_, params)
	else
		self.countDown_:setInfo(params)
	end
end

function ActivityReturnPersonalWindow:onGetActivityInfo()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.RETURN)
	self.hasNotGetData_ = false

	if self.tab_ then
		self.tab_:setTabActive(self.cur_select_, true)
	end
end

function ActivityReturnPersonalWindow:refreshContent(index)
	for i = 1, 3 do
		self.contentGroupList_[i]:SetActive(index == i)
	end

	self.cur_select_ = index

	if self.cur_select_ == 1 then
		self:refreshPMissionPart()
	elseif self.cur_select_ == 2 then
		self:refreshTMissionPart()
	else
		self:refreshShopPart()
	end
end

function ActivityReturnPersonalWindow:refreshPMissionPart(keepPosition)
	local tempList = {}
	local missionList = xyd.tables.activityReturnPMissionTable:getIds()
	self.missionCompList_ = self.activityData.detail.p_mis_comp_times
	self.missionCountList_ = self.activityData.detail.p_mis_count

	for _, id in ipairs(missionList) do
		local params = {
			id = id,
			compTime = tonumber(self.missionCompList_[id]),
			count = tonumber(self.missionCountList_[id])
		}

		table.insert(tempList, params)
	end

	table.sort(tempList, function (a, b)
		local rankA = xyd.tables.activityReturnPMissionTable:getRank(a.id) or a.id
		local rankB = xyd.tables.activityReturnPMissionTable:getRank(b.id) or b.id
		local wightA = xyd.checkCondition(xyd.tables.activityReturnPMissionTable:getRepeatTimes(a.id) <= a.compTime, rankA + 100, rankA)
		local wightB = xyd.checkCondition(xyd.tables.activityReturnPMissionTable:getRepeatTimes(b.id) <= b.compTime, rankB + 100, rankB)

		return wightA < wightB
	end)

	self.pMissionData_ = tempList

	self.multiWrapPerson_:setInfos(self.pMissionData_, {
		keepPosition = keepPosition
	})
end

function ActivityReturnPersonalWindow:onItemChange()
	self.shopCostItemNum_.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.RETURN_ACTIVITY_ITEM))
end

function pMissionItem:ctor(parentGo, parent)
	self.parent_ = parent

	pMissionItem.super.ctor(self, parentGo)
end

function pMissionItem:initUI()
	pMissionItem.super.initUI(self)
	self:getComponent()
	self:registerEvent()
end

function pMissionItem:registerEvent()
	UIEventListener.Get(self.go).onClick = function ()
		local goWindow = xyd.tables.activityReturnPMissionTable:getGoWindow(self.id_)

		if goWindow and goWindow ~= "" and self.compTime_ < self.limitTimes_ then
			xyd.WindowManager.get():openWindow(goWindow, {}, function ()
				xyd.WindowManager.get():closeWindow(self.name_)
			end)
		end
	end
end

function pMissionItem:getComponent()
	local goTrans = self.go.transform
	self.missionName_ = goTrans:ComponentByName("missionName", typeof(UILabel))
	self.progressBar_ = goTrans:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressValueLabel_ = goTrans:ComponentByName("progressBar/valueLabel", typeof(UILabel))
	self.compLabel_ = goTrans:ComponentByName("compLabel", typeof(UILabel))
	self.imgMask_ = goTrans:NodeByName("imgMask").gameObject
	self.itemRoot_ = goTrans:ComponentByName("itemRoot", typeof(UILayout))
	self.goBtn_ = goTrans:NodeByName("goBtn").gameObject
	self.goBtnLabel_ = goTrans:ComponentByName("goBtn/label", typeof(UILabel))
	self.goBtnLabel_.text = __("ACTIVITY_RETURN_WAITING_FOR_FINISH")
end

function pMissionItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id_ = info.id
	self.compTime_ = info.compTime
	self.count_ = info.count
	self.desc_ = xyd.tables.activityReturnPMissionTable:getDesc(self.id_)
	self.completeValue_ = xyd.tables.activityReturnPMissionTable:getCompleteValue(self.id_)
	self.limitTimes_ = xyd.tables.activityReturnPMissionTable:getRepeatTimes(self.id_)
	self.awards_ = xyd.tables.activityReturnPMissionTable:getAward(self.id_)
	self.goWindow_ = xyd.tables.activityReturnPMissionTable:getGoWindow(self.id_)

	self:refreshUI()
end

function pMissionItem:refreshUI()
	self.missionName_.text = __(self.desc_)

	self.imgMask_:SetActive(self.limitTimes_ <= self.compTime_)

	self.compLabel_.text = __("ACTIVITY_RETURN_MISSION_REPEAT_FINISH", self.compTime_, self.limitTimes_)
	local params = {
		itemID = tonumber(self.awards_[1]),
		num = tonumber(self.awards_[2]),
		uiRoot = self.itemRoot_.gameObject,
		dragScrollView = self.parent_.scrollPersonal_
	}

	if not self.awardIcon_ then
		self.awardIcon_ = xyd.getItemIcon(params)
	else
		NGUITools.Destroy(self.awardIcon_:getGameObject())

		self.awardIcon_ = xyd.getItemIcon(params)
	end

	if self.limitTimes_ <= self.compTime_ then
		self.progressBar_.value = 1
		self.progressValueLabel_.text = self.completeValue_ .. "/" .. self.completeValue_
	else
		self.progressBar_.value = self.count_ / self.completeValue_
		self.progressValueLabel_.text = self.count_ .. "/" .. self.completeValue_
	end

	self.goBtn_:SetActive(false)
	self.compLabel_.gameObject:SetActive(true)
end

function ActivityReturnPersonalWindow:refreshShopPart(keepPosition)
	self.shopCostItemNum_.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.RETURN_ACTIVITY_ITEM))
	self.buyTimesList_ = self.activityData.detail.buy_times
	local shopIds = xyd.tables.activityReturnShopTable:getIds()
	local tempList = {}

	for _, id in ipairs(shopIds) do
		local params = {
			id = id,
			buy_times = self.buyTimesList_[id],
			limit_times = xyd.tables.activityReturnShopTable:getLimit(id)
		}

		table.insert(tempList, params)
	end

	self.buyTimesList_ = tempList

	self.multiWrapShop_:setInfos(self.buyTimesList_, {
		keepPosition = keepPosition
	})
end

function ActivityReturnPersonalWindow:onAwardShop()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.RETURN)
	local awardId, num = self.activityData:getBuyItem()
	local item = xyd.tables.activityReturnShopTable:getAward(awardId)

	self.activityData:setBuyItem()
	xyd.itemFloat({
		{
			item_id = item[1],
			item_num = num * item[2]
		}
	}, nil, self.floatItemRoot_)
	self:refreshShopPart(true)
end

function returnShopItem:ctor(parentGo, parent)
	self.parent_ = parent

	returnShopItem.super.ctor(self, parentGo)
end

function returnShopItem:initUI()
	returnShopItem.super.initUI(self)
	self:getComponent()
	self:registerEvent()
end

function returnShopItem:getComponent()
	local goTrans = self.go:NodeByName("mainNode")
	self.mainNode_ = goTrans.gameObject
	self.iconNode_ = goTrans:NodeByName("iconNode").gameObject
	self.res_text_ = goTrans:ComponentByName("res_text", typeof(UILabel))
	self.res_icon_ = goTrans:ComponentByName("res_icon", typeof(UISprite))
	self.limitText_ = goTrans:ComponentByName("limitText", typeof(UILabel))
end

function returnShopItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.info_ = info
	self.limit_ = info.limit_times
	self.buyTime_ = info.buy_times or 0
	self.id_ = info.id
	self.info_.item = xyd.tables.activityReturnShopTable:getAward(self.id_)
	self.info_.cost = xyd.tables.activityReturnShopTable:getCost(self.id_)

	xyd.setUISpriteAsync(self.res_icon_, nil, xyd.tables.itemTable:getName(self.info_.cost[1]))

	self.res_text_.text = self.info_.cost[2]
	self.limitText_.text = __("BUY_GIFTBAG_LIMIT", self.buyTime_ .. "/" .. self.limit_)
	local params = {
		uiRoot = self.iconNode_,
		itemID = self.info_.item[1],
		num = self.info_.item[2],
		dragScrollView = self.parent_.scrollShop_
	}

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon(params)
	elseif self.itemIcon_ then
		NGUITools.Destroy(self.itemIcon_:getGameObject())

		self.itemIcon_ = xyd.getItemIcon(params)
	end
end

function returnShopItem:registerEvent()
	UIEventListener.Get(self.mainNode_).onClick = function ()
		if self.limit_ and self.limit_ <= self.buyTime_ then
			xyd.showToast(__("ACTIVITY_WORLD_BOSS_LIMIT"))

			return
		end

		local get_data = self.info_.item
		local data = self.info_.cost

		if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(data[1])))

			return
		end

		local params = {
			needTips = true,
			limitKey = "ACTIVITY_WORLD_BOSS_LIMIT",
			buyType = get_data[1],
			buyNum = get_data[2],
			costType = data[1],
			costNum = data[2]
		}

		function params.purchaseCallback(_, num)
			if xyd.models.backpack:getItemNumByID(data[1]) < data[2] * num then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(data[1])))

				return
			end

			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.RETURN
			msg.params = cjson.encode({
				award_id = self.id_,
				num = num
			})

			self.parent_.activityData:setBuyItem(self.id_, num)
			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
			xyd.WindowManager.get():closeWindow("limit_purchase_item_window")
		end

		params.titleWords = __("ITEM_BUY_WINDOW", xyd.tables.itemTable:getName(get_data[1]))
		params.limitNum = self.limit_ - self.buyTime_
		params.notEnoughWords = __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(data[1]))
		params.eventType = xyd.event.BOSS_BUY

		function params.tipsCallback()
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(data[1])))
		end

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
	end
end

function ActivityReturnPersonalWindow:refreshTMissionPart()
	self:refreshTeamerInfo()
	self:refreshTmissionList()
end

function ActivityReturnPersonalWindow:refreshTeamerInfo()
	self.bindPlayerId_ = self.activityData.detail.bind_player_id

	if not self.bindPlayerId_ or self.bindPlayerId_ == 0 then
		self.groupApplyTeamer_:SetActive(true)
		self.groupTeamerInfo_:SetActive(false)
	else
		self.groupTeamerInfo_:SetActive(true)
		self.groupApplyTeamer_:SetActive(false)
		self:refreshTeamerIcon()
	end
end

function ActivityReturnPersonalWindow:refreshTeamerIcon()
	self.teamerInfo_ = self.activityData.detail.other_info.p_info
	self.teamerPlayerName_.text = self.teamerInfo_.player_name
	self.teamerIdLabel_.text = "ID:"
	self.teamerPlayerId_.text = self.teamerInfo_.player_id
	self.teamerServerLabel_.text = xyd.getServerNumber(self.teamerInfo_.server_id)
	local playerInfo = {
		avatarID = self.teamerInfo_.avatar_id,
		avatar_frame_id = self.teamerInfo_.avatar_frame_id,
		lev = self.teamerInfo_.lev,
		callback = function ()
			xyd.WindowManager.get():openWindow("arena_formation_window", {
				is_robot = false,
				player_id = self.teamerInfo_.player_id
			})
		end
	}

	if not self.teamerIcon_ then
		self.teamerIcon_ = import("app.components.PlayerIcon").new(self.teamerPlayerIconRoot_)

		self.teamerIcon_:setInfo(playerInfo)
	else
		self.teamerIcon_:setInfo(playerInfo)
	end
end

function ActivityReturnPersonalWindow:onSendApply()
	local sendMsg = tonumber(self.textEdit_.text)

	if sendMsg and sendMsg ~= " " then
		local msg = messages_pb.return_activity_get_apply_player_show_req()
		msg.activity_id = xyd.ActivityID.RETURN
		msg.other_player_id = sendMsg

		xyd.Backend.get():request(xyd.mid.RETURN_ACTIVITY_GET_APPLY_PLAYER_SHOW, msg)
	end
end

function ActivityReturnPersonalWindow:refreshTmissionList(keepPosition)
	if self.activityData.detail.other_info then
		self.otherTMissionCount_ = self.activityData.detail.other_info.t_mis_count or {}
	else
		self.otherTMissionCount_ = {}
	end

	self.tMissionAwarded_ = self.activityData.detail.t_mis_awarded or {}
	self.tMissionCount_ = self.activityData.detail.t_mis_count or {}
	local tMissionList = xyd.tables.activityReturnTMissionTable:getIds()
	local tempList = {}

	for idx, missionId in ipairs(tMissionList) do
		local params = {
			id = missionId,
			teamerCount = self.otherTMissionCount_[idx] or 0,
			count = self.tMissionCount_[idx] or 0,
			compTime = self.tMissionAwarded_[idx] or 0,
			limitTimes = 1
		}

		table.insert(tempList, params)
	end

	table.sort(tempList, function (a, b)
		local rankA = xyd.tables.activityReturnTMissionTable:getRank(a.id) or a.id
		local rankB = xyd.tables.activityReturnTMissionTable:getRank(b.id) or b.id
		local wightA = xyd.checkCondition(a.limitTimes <= a.compTime, rankA + 100, rankA)
		local wightB = xyd.checkCondition(b.limitTimes <= b.compTime, rankB + 100, rankB)

		return wightA < wightB
	end)

	self.tMissionData_ = tempList

	self.multiWrapTeam_:setInfos(self.tMissionData_, {
		keepPosition = keepPosition
	})
end

function ActivityReturnPersonalWindow:onApplyTeamer(event)
	local data = event.data

	if data.result == "OK" then
		xyd.showToast(__("GUILD_TEXT64"))
	else
		xyd.showToast(__("APPLY_FALSE"))
	end
end

function ActivityReturnPersonalWindow:onGetPlayerInfo(event)
	local data = event.data

	xyd.WindowManager.get():openWindow("activity_return_player_info_window", {
		playerData = data,
		callback = function (yes_no)
			if yes_no then
				local msg = messages_pb.return_activity_apply_active_req()
				msg.activity_id = xyd.ActivityID.RETURN
				msg.other_player_id = data.player_id

				xyd.Backend.get():request(xyd.mid.RETURN_ACTIVITY_APPLY_ACTIVE, msg)
			end
		end
	})
end

function tMissionItem:ctor(parentGo, parent)
	self.parent_ = parent

	tMissionItem.super.ctor(self, parentGo)
end

function tMissionItem:initUI()
	tMissionItem.super.initUI(self)
	self:getComponent()
	self:registerEvent()
end

function tMissionItem:registerEvent()
	UIEventListener.Get(self.goBtn_).onClick = function ()
		local goWindow = xyd.tables.activityReturnTMissionTable:getGoWindow(self.id_)

		if goWindow and goWindow ~= "" then
			if goWindow == "arena_3v3_window" and xyd.models.backpack:getLev() < 55 then
				xyd.alertTips(__("FUNC_OPEN_LEV", 55))

				return
			end

			xyd.WindowManager.get():openWindow(goWindow, {}, function ()
				xyd.WindowManager.get():closeWindow(self.name_)
			end)
		end
	end
end

function tMissionItem:getComponent()
	local goTrans = self.go.transform
	self.missionName_ = goTrans:ComponentByName("missionName", typeof(UILabel))
	self.progressBarPerson_ = goTrans:ComponentByName("progressBarPerson", typeof(UIProgressBar))
	self.progressBarPersonLabel_ = goTrans:ComponentByName("progressBarPerson/valueLabel", typeof(UILabel))
	self.progressBarTeamer_ = goTrans:ComponentByName("progressBarTeamer", typeof(UIProgressBar))
	self.progressBarTeamerLabel_ = goTrans:ComponentByName("progressBarTeamer/valueLabel", typeof(UILabel))
	self.goBtn_ = goTrans:NodeByName("goBtn").gameObject
	self.goBtnBox_ = goTrans:ComponentByName("goBtn", typeof(UnityEngine.BoxCollider))
	self.goBtnLabel_ = goTrans:ComponentByName("goBtn/label", typeof(UILabel))
	self.imgMask_ = goTrans:ComponentByName("imgMask", typeof(UISprite))

	xyd.setUISpriteAsync(self.imgMask_, nil, "mission_awarded_" .. xyd.Global.lang)

	self.itemRoot_ = goTrans:ComponentByName("itemRoot", typeof(UILayout))
	self.goBtnMask_ = goTrans:NodeByName("goBtn/mask").gameObject
end

function tMissionItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id_ = info.id
	self.compTime_ = info.compTime
	self.count_ = info.count
	self.teamerCount_ = info.teamerCount
	self.limitTimes_ = 1
	self.desc_ = xyd.tables.activityReturnTMissionTable:getDesc(self.id_)
	self.completeValue1_ = xyd.tables.activityReturnTMissionTable:getCompleteValue(self.id_)
	self.completeValue2_ = xyd.tables.activityReturnTMissionTable:getCompleteValue2(self.id_) or 0
	self.awards_ = xyd.tables.activityReturnTMissionTable:getAward1(self.id_)
	self.goWindow_ = xyd.tables.activityReturnTMissionTable:getGoWindow(self.id_)

	self:refreshUI()
end

function tMissionItem:refreshUI()
	self.missionName_.text = __(self.desc_)

	self.goBtn_:SetActive(self.compTime_ < self.limitTimes_)

	local params = {
		itemID = tonumber(self.awards_[1]),
		num = tonumber(self.awards_[2]),
		uiRoot = self.itemRoot_.gameObject,
		dragScrollView = self.parent_.scrollTeam_
	}

	if not self.awardIcon_ then
		self.awardIcon_ = xyd.getItemIcon(params)
	else
		NGUITools.Destroy(self.awardIcon_:getGameObject())

		self.awardIcon_ = xyd.getItemIcon(params)
	end

	if self.limitTimes_ <= self.compTime_ then
		self.progressBarPerson_.value = 1
		self.progressBarPersonLabel_.text = self.completeValue1_ .. "/" .. self.completeValue1_
		self.progressBarTeamer_.value = 1
		self.progressBarTeamerLabel_.text = self.completeValue2_ .. "/" .. self.completeValue2_

		self.imgMask_:SetActive(true)
	else
		self.progressBarPerson_.value = self.count_ / self.completeValue1_
		self.progressBarTeamer_.value = self.teamerCount_ / self.completeValue2_
		self.progressBarPersonLabel_.text = self.count_ .. "/" .. self.completeValue1_
		self.progressBarTeamerLabel_.text = self.teamerCount_ .. "/" .. self.completeValue2_

		self.imgMask_:SetActive(false)
	end

	if not self.parent_.bindPlayerId_ or self.parent_.bindPlayerId_ == 0 then
		self.goBtnMask_:SetActive(true)

		self.goBtnBox_.enabled = false
		self.goBtnLabel_.text = __("ACTIVITY_RETURN_MISSION_NO_BIND")
	elseif not self.goWindow_ or self.goWindow_ == "" then
		self.goBtnMask_:SetActive(false)

		self.goBtnBox_.enabled = false
		self.goBtnLabel_.text = __("ACTIVITY_RETURN_WAITING_FOR_FINISH")
	else
		self.goBtnMask_:SetActive(false)

		self.goBtnBox_.enabled = true
		self.goBtnLabel_.text = __("GO")
	end
end

function ActivityReturnPersonalWindow:willClose()
	ActivityReturnPersonalWindow.super.willClose(self)

	if self.countDown_ then
		self.countDown_:stopTimeCount()
	end
end

return ActivityReturnPersonalWindow
