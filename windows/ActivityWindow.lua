local BaseWindow = import(".BaseWindow")
local ActivityWindow = class("ActivityWindow", BaseWindow)
local ActivityTable = xyd.tables.activityTable
local Activity = xyd.models.activity
local CommonTabBar = require("app.common.ui.CommonTabBar")
local WindowTop = require("app.components.WindowTop")
local FixedWrapContent = require("app.common.ui.FixedWrapContent")
local CountDown = require("app.components.CountDown")
local ModelClass, TableClass, PrefabsPath = unpack(require("app.models.ActivityDatas"))
local ActivityTitleItem = class("ActivityTitleItem", import("app.components.BaseComponent"), true)

function ActivityWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.titlesMap = {}
	self.titlesList = {}
	self.activityType = params.activity_type or xyd.EventType.COOL
	self.activityType2 = params.activity_type2 or 0
	self.select = params.select

	if self.select then
		if params.activity_type and ActivityTable:getType(self.select) and ActivityTable:getType(self.select) == 0 then
			-- Nothing
		else
			local winType = ActivityTable:getType(self.select)

			if not winType or winType == 0 then
				if xyd.tables.activityTable:getWindowParams(self.select) and xyd.tables.activityTable:getWindowParams(self.select).activity_type then
					self.activityType = xyd.tables.activityTable:getWindowParams(self.select).activity_type
				else
					self.activityType = xyd.EventType.COOL
				end
			else
				self.activityType = winType
			end
		end
	end

	if self.activityType ~= xyd.EventType.push and self.activityType ~= xyd.EventType.NEWBIE and self.activityType ~= xyd.EventType.LARGE and self.activityType ~= xyd.EventType.YEARS then
		self.activityType2 = 1
	end

	if params.onlyShowList ~= nil then
		self.onlyShowList = params.onlyShowList
	elseif self.select and xyd.tables.activityTable:getWindowParams(self.select) and xyd.tables.activityTable:getWindowParams(self.select).activity_ids then
		self.onlyShowList = xyd.tables.activityTable:getWindowParams(self.select).activity_ids
	end

	self.selectGiftbagID = params.select_giftbag_id
	self.giftbag_push_list_ = params.giftbag_push_list
	self.closeBtnCallback = params.closeBtnCallback
	self.eventsRedCount = {}
	self.redMarkType = {
		xyd.RedMarkType.ACTIVITY_WINDOW_TAG_1,
		xyd.RedMarkType.ACTIVITY_WINDOW_TAG_2,
		xyd.RedMarkType.ACTIVITY_WINDOW_TAG_3
	}

	self:registerEvent()
	self:afRecordWnd(params.activity_type)
end

function ActivityWindow:getSelect()
	return self.select
end

function ActivityWindow:afRecordWnd(activityType)
	if activityType and (activityType == xyd.EventType.COOL or activityType == xyd.EventType.PUSH) then
		xyd.models.advertiseComplete:afActivity(activityType)
	end
end

function ActivityWindow:setMask(flag)
	self.touchMask:SetActive(flag)
end

function ActivityWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initTopGroup()
	self:initNav()
end

function ActivityWindow:getUIComponent()
	local go = self.window_
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.bg01 = go:ComponentByName("groupMain/bg01", typeof(UISprite))
	self.bg02 = go:ComponentByName("groupMain/bg02_panel/bg02", typeof(UISprite))
	self.groupContent = go:ComponentByName("groupMain/groupContent", typeof(UIPanel))
	self.nav = go:ComponentByName("nav", typeof(UIWidget))
	self.clickTipsTab2 = self.nav.gameObject:NodeByName("tab_2/clickTips").gameObject
	self.clickTipsTab2_box = self.nav.gameObject:NodeByName("tab_2/clickTips/clickTipsBox").gameObject
	self.clickTipsTab3 = self.nav.gameObject:NodeByName("tab_3/clickTips").gameObject
	self.clickTipsTab3_box = self.nav.gameObject:NodeByName("tab_3/clickTips/clickTipsBox").gameObject
	self.scroll = go:NodeByName("groupMain/scroll").gameObject
	self.scroll_uiScrollView = go:ComponentByName("groupMain/scroll", typeof(UIScrollView))
	self.scroll_uiPanel = go:ComponentByName("groupMain/scroll", typeof(UIPanel))
	self.titleGroup = go:NodeByName("groupMain/scroll/titleGroup").gameObject
	self.titleGroupLayout = self.titleGroup:GetComponent(typeof(UILayout))
	self.itemFloatRoot_ = go:ComponentByName("groupMain/itemFloat/root", typeof(UIWidget)).gameObject

	self.groupMain:SetActive(false)
end

function ActivityWindow:itemFloat(items, depth)
	xyd.itemFloat(items, nil, self.itemFloatRoot_, depth)
end

function ActivityWindow:initUIComponent()
	if self.activityType == xyd.EventType.NEWBIE or self.activityType == xyd.EventType.PUSH or self.activityType == xyd.EventType.LARGE or self.activityType == xyd.EventType.YEARS then
		self.bg01:SetTopAnchor(self.window_, 1, -129)
		self.bg01:SetBottomAnchor(self.window_, 0, 151)
		self.bg02:SetTopAnchor(self.window_, 1, -124)
		self.bg02:SetBottomAnchor(self.window_, 0, 146)
		self.groupContent:SetTopAnchor(self.window_, 1, -259)
		self.groupContent:SetBottomAnchor(self.window_, 0, 152)
		self.groupMain:GetComponent(typeof(UIWidget)):SetTopAnchor(self.window_, 1, -104)
		self.groupMain:GetComponent(typeof(UIWidget)):SetBottomAnchor(self.window_, 0, 146)
		self.nav:SetActive(false)
	else
		self.bg01:SetTopAnchor(self.window_, 1, -154)
		self.bg01:SetBottomAnchor(self.window_, 0, 121)
		self.bg02:SetTopAnchor(self.window_, 1, -149)
		self.bg02:SetBottomAnchor(self.window_, 0, 118)
		self.groupContent:SetTopAnchor(self.window_, 1, -283)
		self.groupContent:SetBottomAnchor(self.window_, 0, 123)
		self.groupMain:GetComponent(typeof(UIWidget)):SetTopAnchor(self.window_, 1, -129)
		self.groupMain:GetComponent(typeof(UIWidget)):SetBottomAnchor(self.window_, 0, 121)
		self.nav:SetActive(true)
	end
end

function ActivityWindow:initNav()
	local index = 3
	local labelText = {}
	self.tab = CommonTabBar.new(self.nav.gameObject, index, function (index)
		self:updateNav(index)
	end, self.activityType)

	if self.select then
		self.activityType2 = xyd.tables.activityTable:getType2(self.select) or 0

		self.tab:setTabActive(self.activityType2, true, false)
	else
		self.tab:setTabActive(1, true, false)
	end

	for i = 1, 3 do
		self.tab.tabs[i].redMark:SetActive(true)
		self.tab.tabs[i].redMark:SetActive(false)
		xyd.models.redMark:setMarkImg(self.redMarkType[i], self.tab.tabs[i].redMark)
		table.insert(labelText, __("ACTIVITY_NAV_TEXT_" .. self.activityType .. "_" .. i))
	end

	self.tab:setTexts(labelText)
	self:setRedMark()

	if self.activityType == xyd.EventType.COOL then
		if not xyd.checkFunctionOpen(xyd.FunctionID.COOL, true) then
			self.clickTipsTab2:SetActive(true)

			UIEventListener.Get(self.clickTipsTab2_box.gameObject).onClick = handler(self, function ()
				xyd.checkFunctionOpen(xyd.FunctionID.COOL, false)
			end)
		else
			self.clickTipsTab2:SetActive(false)
		end
	end

	if self.activityType == xyd.EventType.LIMIT then
		if not xyd.checkFunctionOpen(xyd.FunctionID.LIMIT, true) then
			self.clickTipsTab3:SetActive(true)

			UIEventListener.Get(self.clickTipsTab3_box.gameObject).onClick = handler(self, function ()
				xyd.checkFunctionOpen(xyd.FunctionID.LIMIT, false)
			end)
		else
			self.clickTipsTab3:SetActive(false)
		end
	end
end

function ActivityWindow:updateNav(i)
	if self.activityType2 == i then
		return
	end

	self.select2 = nil

	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)

	self.activityType2 = i

	self:setActivityDisplay()
end

function ActivityWindow:playOpenAnimation(callback)
	callback()
	xyd.SoundManager.get():playSound(xyd.SoundID.SLIDE_TO_RIGHT)
	self.imgBg:SetActive(true)

	local sequence = self:getSequence()

	self.groupMain:SetActive(true)
	self.groupMain:X(-self.window_:GetComponent(typeof(UIPanel)).width)
	sequence:Append(self.groupMain.transform:DOLocalMoveX(50, 0.3))

	local function setter1(val)
		self.imgBg.alpha = val
	end

	sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.2))
	sequence:Append(self.groupMain.transform:DOLocalMoveX(0, 0.27))
	sequence:AppendCallback(function ()
		self:setWndComplete()

		self.isAnimationCompleted = true

		print("self.select", self.select)

		if self.select then
			self.activityType2 = xyd.tables.activityTable:getType2(self.select)

			if self.nav.gameObject.activeSelf == true and self.activityType2 > 0 then
				self.tab:onClickBtn(self.activityType2)
			end

			self:setActivityDisplay()

			self.select2 = self.select
			self.select = nil
		else
			self:setActivityDisplay()
		end

		if self.activityType == xyd.EventType.COOL then
			self:updateMainWindowNew()
		end
	end)
end

function ActivityWindow:registerEvent()
	if not xyd.GuideController.get():isPlayGuide() and (self.activityType == xyd.EventType.LIMIT or self.activityType == xyd.EventType.PUSH) then
		xyd.models.activity:reqActivityList()
	elseif not xyd.GuideController.get():isPlayGuide() then
		local sentGetActivityListDay = xyd.db.misc:getValue("sent_get_activity_list_day")
		local isSend = true

		if sentGetActivityListDay then
			isSend = xyd.isSameDay(tonumber(sentGetActivityListDay), xyd.getServerTime() - 3)
		end

		if sentGetActivityListDay == nil or isSend == false then
			xyd.db.misc:setValue({
				key = "sent_get_activity_list_day",
				value = tostring(xyd.getServerTime())
			})
			xyd.models.activity:reqActivityList()
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_LIST, self.onActivityList, self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, self.onActivityChange, self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, self.onActivityChange, self)
end

function ActivityWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, nil, , self.closeBtnCallback)
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

function ActivityWindow:getWindowTop()
	return self.windowTop
end

function ActivityWindow:hasSubTitles(activityData)
	local id = activityData.id

	if activityData.detail and activityData.detail[1] then
		self.titlesMap[id] = {}

		for i, data in ipairs(activityData.detail) do
			local title = ActivityTitleItem.new(self.titleGroup, {
				id = id,
				type = i
			})

			title:setDragScrollView(self.scroll:GetComponent(typeof(UIScrollView)))
			table.insert(self.titlesMap[id], title)

			if activityData:backRank() then
				table.insert(self.backList, title)
			else
				table.insert(self.titlesList, title)
			end
		end

		self.titleGroupLayout:Reposition()

		return true
	end

	return false
end

function ActivityWindow:setPushActivityDisplay()
	local activityList = xyd.models.activity:getPushActivity()

	xyd.changeScrollViewMove(self.scroll, false, Vector3(0, -88, 0), Vector2(0, 0))

	self.titlesList = {}
	local itemType = "middle"

	if #activityList <= 4 then
		itemType = "big"
	end

	for i = 1, #activityList do
		local id = activityList[i]
		local activityData = xyd.models.activity:getActivity(id)

		print("id    ====", id, "isShow   ", activityData:isShow())

		if ActivityWindow.ContentClass[id] and activityData:isShow() and not self:hasSubTitles(activityData) then
			local title = ActivityTitleItem.new(self.titleGroup, {
				type = 1,
				id = id,
				itemType = itemType
			})

			title:setDragScrollView(self.scroll:GetComponent(typeof(UIScrollView)))

			self.titlesMap[id] = {
				title
			}

			table.insert(self.titlesList, title)
		end
	end

	table.sort(self.titlesList, function (a, b)
		local aTime = a:getUpdateTime()
		local bTime = b:getUpdateTime()

		if aTime ~= bTime then
			return aTime < bTime
		else
			return b.type < a.type
		end
	end)

	for i in pairs(self.titlesList) do
		self.titlesList[i]:getSelfGo().transform:SetSiblingIndex(i - 1)
	end

	self.titleGroupLayout:Reposition()
end

function ActivityWindow:setNormalDisplay()
	xyd.changeScrollViewMove(self.scroll, false, Vector3(0, -88, 0), Vector2(0, 0))

	local activityList = xyd.models.activity:getActivityList()
	local sortedIDs = table.sortedKeys(activityList, function (a, b)
		if self:isComplete(a) then
			return false
		end

		if self:isComplete(b) then
			return true
		end

		if ActivityTable:getRank(b) ~= ActivityTable:getRank(a) then
			return ActivityTable:getRank(b) < ActivityTable:getRank(a)
		else
			return b < a
		end
	end)
	self.backList = {}
	self.titlesList = {}
	self.idsList = {}
	self.allNavIds = {}

	for i = 1, #sortedIDs do
		local id = sortedIDs[i]

		if id == 298 then
			dump("111111111111")
		end

		local activityData = activityList[id]
		local idType = ActivityTable:getType(id)

		if self.onlyShowList ~= nil and xyd.arrayIndexOf(self.onlyShowList, id) > -1 then
			local idTypeEg = ActivityTable:getType(self.onlyShowList[1])
			local tempParams = xyd.tables.activityTable:getWindowParams(self.onlyShowList[1])

			if tempParams and tempParams.activity_type and tonumber(tempParams.activity_type) ~= 0 then
				idTypeEg = xyd.tables.activityTable:getWindowParams(self.onlyShowList[1]).activity_type
			end

			idType = tonumber(idTypeEg)
		end

		if not xyd.models.activity:ifActivityPushGiftBag(id) and idType == self.activityType and ActivityWindow.ContentClass[id] and activityData:isShow() and not activityData:isHide(self.activityType) and (id ~= xyd.ActivityID.FOLLOWING_GIFTBAG or id == xyd.ActivityID.FOLLOWING_GIFTBAG and xyd.isH5()) then
			if (self.activityType2 == 0 or ActivityTable:getType2(id) == self.activityType2) and not self:hasSubTitles(activityData) then
				local isContinue = false

				if self.onlyShowList ~= nil and xyd.arrayIndexOf(self.onlyShowList, id) <= -1 then
					isContinue = true
				end

				if isContinue == false then
					if activityData:backRank() or id == xyd.ActivityID.RED_RIDING_HOOD and activityData:getRankState() then
						table.insert(self.backList, id)
					else
						table.insert(self.idsList, id)
					end
				end
			end

			if self.onlyShowList == nil then
				table.insert(self.allNavIds, id)
			end
		end
	end

	table.insertto(self.idsList, self.backList)

	local itemType = "middle"

	if #self.idsList <= 4 then
		itemType = "big"
	end

	for i = 1, #self.idsList do
		local id = self.idsList[i]
		local title = ActivityTitleItem.new(self.titleGroup, {
			type = 1,
			id = id,
			itemType = itemType
		})

		title:setDragScrollView(self.scroll:GetComponent(typeof(UIScrollView)))

		self.titlesMap[id] = {
			title
		}

		table.insert(self.titlesList, title)
	end

	self.titleGroupLayout:Reposition()
	xyd.changeScrollViewMove(self.scroll, true)
end

function ActivityWindow:setActivityDisplay()
	NGUITools.DestroyChildren(self.titleGroup.transform)

	if self.activityType == xyd.EventType.PUSH then
		self:setPushActivityDisplay()
	else
		self:setNormalDisplay()
	end

	local selectTitle, selectCurId, selectAllLength = nil

	if self.select then
		if not self.selectGiftbagID then
			if self.titlesMap[self.select] == nil then
				return
			end

			selectTitle = self.titlesMap[self.select][1]

			for i in pairs(self.idsList) do
				if self.idsList[i] == self.select then
					selectCurId = i
					selectAllLength = #self.idsList

					break
				end
			end
		else
			for i, title in ipairs(self.titlesMap[self.select]) do
				local detail, giftBagID = title:getDetailGiftBag()

				if giftBagID == self.selectGiftbagID then
					selectTitle = title

					break
				end
			end
		end
	else
		selectTitle = self.titlesList[1]
	end

	if self.jumpToAnotherNav then
		for i in pairs(self.titlesList) do
			if self.jumpToAnotherNavId == self.titlesList[i]:getId() then
				selectTitle = self.titlesList[i]
				selectAllLength = #self.titlesList
				selectCurId = i

				break
			end
		end

		self.jumpToAnotherNav = false
	end

	if selectTitle then
		local id = selectTitle.ID

		selectTitle:setState(true)

		if selectCurId ~= nil then
			self:jumpToInfo(selectCurId, selectAllLength)
		end

		self:setCurrentActivity(id, selectTitle.TYPE)

		local activity = xyd.models.activity:getActivity(id)

		activity:setDefRedMark(false)
		selectTitle:setRedMark()
	end

	self:setTitleRedMark()
end

function ActivityWindow:isComplete(id)
	if id == xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_UP then
		local ids = xyd.tables.activityEquipLevelUpTable:getIds()
		local data = xyd.models.activity:getActivity(id)
		local buyTimes = data.detail.buy_times

		for i = 1, #ids do
			local idx = ids[i]
			local limit = xyd.tables.activityEquipLevelUpTable:getLimit(idx)

			if tonumber(buyTimes[i]) < limit then
				return false
			end
		end

		return true
	end

	if id == xyd.ActivityID.CHECKIN then
		local data = xyd.models.activity:getActivity(id)

		return not data:getRedMarkState()
	end

	if id == xyd.ActivityID.ANNIVERSARY_GIFTBAG3_1 or id == xyd.ActivityID.ANNIVERSARY_GIFTBAG3_2 then
		local data = xyd.models.activity:getActivity(id)

		return data.detail.charges[1].buy_times == 1
	end

	if id == xyd.ActivityID.ACTIVITY_CHRISTMAS_SIGN_UP then
		local data = xyd.models.activity:getActivity(id)

		if data:getAward(data:getCurDateID()) ~= nil then
			if data:getCurGiftBag() ~= nil and data:getCurGiftBag() ~= 0 then
				if data.detail.charges == nil or data.detail.charges[data:getGiftBagIndex(data:getCurGiftBag())].limit_times <= data.detail.charges[data:getGiftBagIndex(data:getCurGiftBag())].buy_times then
					return true
				else
					return false
				end
			else
				return true
			end
		else
			return false
		end
	end

	return false
end

function ActivityWindow:updateMainWindowNew()
	local ids = xyd.tables.miscTable:split2Cost("giftbag_new_show", "value", "|")
	local targetIds = {}

	for i = 1, #ids do
		for j = 1, #self.idsList do
			if ids[i] == self.idsList[j] and xyd.tables.activityTable:getType(tonumber(ids[i])) == 1 then
				table.insert(targetIds, ids[i])
			end
		end
	end

	for i = 1, #targetIds do
		local timestamp = xyd.models.activity:getActivity(targetIds[i]).end_time

		if not xyd.db.misc:getValue("main_window_activity_new" .. targetIds[i] .. timestamp) then
			xyd.db.misc:setValue({
				value = "1",
				key = "main_window_activity_new" .. targetIds[i] .. timestamp
			})
		end
	end

	xyd.models.activity:updateMainWindowNew()
end

function ActivityWindow:onActivityList(event)
	if self.isAnimationCompleted then
		if self.select2 then
			self.select = self.select2
		end

		self:setActivityDisplay()

		self.select = nil
		self.select2 = nil
	end

	xyd.models.activityPointTips:initData()
end

function ActivityWindow:onActivityChange(event)
	local id = event.data.activity_id

	self:setTitleRedMark(id)
end

function ActivityWindow:checkPushGiftBag(id, type)
	local data = xyd.models.activity:getActivity(id)

	if not data or not data.detail then
		return -1
	end

	if data.detail and next(data.detail) then
		local detail = data.detail[type]

		if detail then
			local charge = detail.charge

			if charge then
				local giftbagID = charge.table_id

				if giftbagID then
					local check = xyd.tables.giftBagTable:getParamVIP(giftbagID)

					if check ~= "" then
						return giftbagID
					end
				end
			end
		end
	else
		local detail = data.detail

		if detail then
			local giftbagID = detail.table_id

			if giftbagID then
				local check = xyd.tables.giftBagTable:getParamVIP(giftbagID)

				if check ~= "" then
					return giftbagID
				end
			end
		end
	end

	return -1
end

function ActivityWindow:playReturn()
end

function ActivityWindow:isWndComplete()
	return self.isWndComplete_ and self.hasInitFirstActivity_
end

function ActivityWindow:setCurrentActivity(id, type)
	if id ~= xyd.ActivityID.SPORTS then
		local msg = messages_pb:record_activity_req()
		msg.activity_id = id

		xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)
	end

	local giftbagId = self:checkPushGiftBag(id, type)

	if giftbagId > 0 and id ~= xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY_SUPER then
		local msg = messages_pb:log_giftbag_push_req()
		msg.giftbag_id = giftbagId

		xyd.Backend.get():request(xyd.mid.LOG_GIFTBAG_PUSH, msg)
	end

	local needLoad = PrefabsPath[id] and {
		xyd.ACTIVITY_PATH .. PrefabsPath[id]
	} or {}

	Activity:downloadAssets("activity_prefab_" .. id, needLoad, function ()
		if self.cur_content_ and self.cur_content_.onRemove then
			self.cur_content_:onRemove()
		end

		NGUITools.DestroyChildren(self.groupContent.transform)

		local class = ActivityWindow.ContentClass[id]()
		local content = class.new(self.groupContent.gameObject, {
			id = id,
			type = type
		}, self)
		self.cur_content_ = content
		xyd.Global.curActivityID = id
		self.hasInitFirstActivity_ = true
	end)

	for i, v in ipairs(self.titlesList) do
		if v.ID ~= id or v.TYPE ~= type then
			v:setState(false)
		end
	end
end

function ActivityWindow:setTitleRedMark(id, type)
	if id then
		if not self.titlesMap[id] then
			return
		end

		if type == nil then
			type = 1
		end

		if not type then
			for i, title in ipairs(self.titlesMap[id]) do
				title:setRedMark()
			end
		else
			self:updateTagRedMarkCount(self.titlesMap[id][type])
		end

		return
	end

	for i, title in ipairs(self.titlesList) do
		title:setRedMark()
	end
end

function ActivityWindow:excuteCallBack()
	ActivityWindow.super.excuteCallBack(self)

	if self.giftbag_push_list_ then
		xyd.WindowManager.get():openWindow("month_card_push_window", {
			not_log = true,
			list = self.giftbag_push_list_
		})
	end

	xyd.models.activity:setRedMarkState()
end

function ActivityWindow:ifNeedDaDian()
	if self.giftbag_push_list_ and self.giftbag_push_list_ > 0 then
		return true
	end

	return false
end

function ActivityWindow:setTitleTimeLabel(id, count, type)
	if not self.titlesMap[id] then
		return
	end

	local title = self.titlesMap[id][type]

	title:setTimeLabel(count)
end

function ActivityWindow:changeActivityItem(id)
	local type = ActivityTable:getType(id)

	self:updateNav(type - 1)

	local title = self.titlesMap[id][1]

	title:setState(true)
	self:setCurrentActivity(id, title.TYPE)
	title:setRedMark()
end

function ActivityWindow:getCurContent()
	return self.cur_content_
end

function ActivityWindow:upDateTitleName(id)
	local type = ActivityTable:getType2(id)
	local title = self.titlesMap[id][1]

	if title then
		title:updateName()
	end
end

function ActivityWindow:updateRedMark(id, value)
	local type2 = xyd.tables.activityTable:getType2(id)
	local index = type2

	if index == 0 then
		index = 1
	end

	self.eventsRedCount[index] = self.eventsRedCount[index] + value

	xyd.models.redMark:setMark(self.redMarkType[index], self.eventsRedCount[index] > 0)
end

function ActivityWindow:setRedMark()
	self.eventsRedCount = {}

	for i in pairs(self.redMarkType) do
		self.eventsRedCount[i] = 0
	end

	local activityList = xyd.models.activity:getActivityList()

	for i in pairs(activityList) do
		local data = activityList[i]

		if data ~= nil then
			local id = data.id

			if self:isShowActivity(id) == true and data:getRedMarkState() then
				local type2 = xyd.tables.activityTable:getType2(id)

				if self.eventsRedCount[type2] ~= nil then
					self.eventsRedCount[type2] = self.eventsRedCount[type2] + 1
				end
			end
		end
	end

	for i in pairs(self.redMarkType) do
		local type = self.redMarkType[i]

		xyd.models.redMark:setMark(type, self.eventsRedCount[i] > 0)
	end
end

function ActivityWindow:isShowActivity(id)
	if xyd.tables.activityTable:getType(id) ~= self.activityType then
		return false
	end

	if ActivityWindow.ContentClass[id] == nil then
		return false
	end

	local activityData = xyd.models.activity:getActivity(id)

	if not activityData:isShow() then
		return false
	end

	if xyd.models.activity:ifActivityPushGiftBag(id) then
		return false
	end

	return true
end

function ActivityWindow:updateTagRedMarkCount(titleItem)
	if not titleItem or titleItem and tolua.isnull(titleItem.go) then
		return
	end

	local redMark0 = titleItem:getRedMarkVisible()

	titleItem:setRedMark()

	local redMark1 = titleItem:getRedMarkVisible()
	local id = titleItem.id
	local index = xyd.tables.activityTable:getType2(id)

	if index == nil or index == 0 then
		index = 1
	end

	if not redMark0 and redMark1 then
		self.eventsRedCount[index] = self.eventsRedCount[index] + 1
	elseif redMark0 and not redMark1 then
		self.eventsRedCount[index] = self.eventsRedCount[index] - 1
	end

	local redMarkType = self.redMarkType[index]

	xyd.models.redMark:setMark(redMarkType, self.eventsRedCount[index] > 0)
end

function ActivityWindow:updateTitleRedMark(id)
	for i, title in pairs(self.titlesList) do
		if title.id == id then
			title:setRedMark()

			break
		end
	end
end

function ActivityWindow:willClose()
	ActivityWindow.super.willClose(self)
	xyd.models.activity:setRedMarkState()
end

function ActivityWindow:jumpToInfo(curid, AllLength)
	local currIndex = curid

	if not currIndex then
		return
	end

	local panel = self.scroll:GetComponent(typeof(UIPanel))
	local height = panel.baseClipRegion.w
	local width = panel.baseClipRegion.z
	local itemSize = 134
	local lastIndex = AllLength
	local width2 = lastIndex * itemSize

	if width >= width2 then
		return
	end

	local displayNum = math.ceil(width / itemSize)
	local half = math.floor(displayNum / 2)

	if currIndex <= half then
		return
	end

	local maxDeltaX = width2 - width
	local deltaX = currIndex * itemSize - width / 2 - itemSize / 2
	local oldPos = self.scroll_uiScrollView.transform.localPosition.x
	deltaX = math.min(deltaX, maxDeltaX)
	deltaX = math.max(-oldPos, deltaX)

	self.scroll_uiScrollView:MoveRelative(Vector3(-deltaX, 0, 0))
end

function ActivityWindow:getInThisWindow(id)
	local searchType = xyd.tables.activityTable:getType(id)

	if not searchType or searchType == 0 then
		local windowParams = xyd.tables.activityTable:getWindowParams(id)

		if windowParams and windowParams.activity_ids then
			local first_id = tonumber(windowParams.activity_ids[1])
			searchType = xyd.tables.activityTable:getType(first_id)
		end
	end

	if searchType and searchType > 0 and searchType == self.activityType then
		if searchType == xyd.EventType.COOL or searchType == xyd.EventType.LIMIT then
			if xyd.arrayIndexOf(self.allNavIds, id) > -1 then
				return true
			end
		else
			for i, item in pairs(self.titlesList) do
				if item:getId() == id then
					return true
				end
			end
		end
	end

	return false
end

function ActivityWindow:reOpen(name, params)
	local isSearch = false

	if params.select and params.select > 0 then
		for i, item in pairs(self.titlesList) do
			if item:getId() == params.select then
				item:onTouch()
				self.scroll_uiScrollView:ResetPosition()
				self:jumpToInfo(i, #self.titlesList)

				isSearch = true

				break
			end
		end
	end

	if not isSearch then
		self.jumpToAnotherNav = true
		self.jumpToAnotherNavId = params.select
		local type2 = xyd.tables.activityTable:getType2(params.select)

		self:updateNav(type2)
		self.tab:setTabActive(type2, true, false)
	end
end

ActivityWindow.ContentClass = {
	[xyd.ActivityID.CHECKIN] = function ()
		return require("app.windows.activity.CheckIn")
	end,
	[xyd.ActivityID.MONTH_CARD] = function ()
		return require("app.windows.activity.MonthCard")
	end,
	[xyd.ActivityID.MONTHLY_GIFTBAG] = function ()
		return require("app.windows.activity.MonthlyGiftBag")
	end,
	[xyd.ActivityID.WEEKLY_GIFTBAG] = function ()
		return require("app.windows.activity.WeeklyGiftBag")
	end,
	[xyd.ActivityID.FIRST_RECHARGE] = function ()
		return require("app.windows.activity.FirstRecharge")
	end,
	[xyd.ActivityID.VALUE_GIFTBAG01] = function ()
		return require("app.windows.activity.ValueGiftBag")
	end,
	[xyd.ActivityID.VALUE_GIFTBAG02] = function ()
		return require("app.windows.activity.ValueGiftBag")
	end,
	[xyd.ActivityID.VALUE_GIFTBAG03] = function ()
		return require("app.windows.activity.ValueGiftBag")
	end,
	[xyd.ActivityID.SUMMON_GIFTBAG] = function ()
		return require("app.windows.activity.SummonGiftBag")
	end,
	[xyd.ActivityID.PROPHET_SUMMON_GIFTBAG] = function ()
		return require("app.windows.activity.ProphetSummonGiftBag")
	end,
	[xyd.ActivityID.MIRACLE_GIFTBAG] = function ()
		return require("app.windows.activity.MiracleGiftBag")
	end,
	[xyd.ActivityID.FOLLOWING_GIFTBAG] = function ()
		return require("app.windows.activity.FollowingGiftBag")
	end,
	[xyd.ActivityID.WISHING_POOL_GIFTBAG] = function ()
		return require("app.windows.activity.WishingPoolGiftBag")
	end,
	[xyd.ActivityID.PUB_MISSION_GIFTBAG] = function ()
		return require("app.windows.activity.PubMissionGiftBag")
	end,
	[xyd.ActivityID.BATTLE_ARENA_GIFTBAG] = function ()
		return require("app.windows.activity.BattleArenaGiftBag")
	end,
	[xyd.ActivityID.SHELTER_GIFTBAG] = function ()
		return require("app.windows.activity.ShelterGiftBag")
	end,
	[xyd.ActivityID.SHENXUE_GIFTBAG] = function ()
		return require("app.windows.activity.ShenXueGiftBag")
	end,
	[xyd.ActivityID.HERO_EXCHANGE] = function ()
		return require("app.windows.activity.HeroExchange")
	end,
	[xyd.ActivityID.QIXI_GIFTBAG] = function ()
		return require("app.windows.activity.QiXiGiftBag")
	end,
	[xyd.ActivityID.LIMIT_FIVE_STAR_GIFTBAG] = function ()
		return require("app.windows.activity.LimitFiveStarGiftBag")
	end,
	[xyd.ActivityID.ACTIVITY_WORLD_BOSS] = function ()
		return require("app.windows.activity.ActivityWorldBoss")
	end,
	[xyd.ActivityID.MID_AUTUMN_ACTIVITY] = function ()
		return require("app.windows.activity.MidAutumnActivity")
	end,
	[xyd.ActivityID.BLACK_CARD] = function ()
		return require("app.windows.activity.ActivityMidautumnCard")
	end,
	[xyd.ActivityID.ACTIVITY_JIGSAW] = function ()
		return require("app.windows.activity.ActivityJigsaw")
	end,
	[xyd.ActivityID.SUBSCRIPTION] = function ()
		return require("app.windows.activity.Subscription")
	end,
	[xyd.ActivityID.MONTHLY_GIFTBAG02] = function ()
		return require("app.windows.activity.MonthlyGiftBag")
	end,
	[xyd.ActivityID.WEEKLY_GIFTBAG02] = function ()
		return require("app.windows.activity.WeeklyGiftBag")
	end,
	[xyd.ActivityID.AWAWKE_GIFTBAG] = function ()
		return require("app.windows.activity.AwakeGiftBag")
	end,
	[xyd.ActivityID.BENEFIT_GIFTBAG01] = function ()
		return require("app.windows.activity.BenefitGiftbag02")
	end,
	[xyd.ActivityID.BENEFIT_GIFTBAG02] = function ()
		return require("app.windows.activity.BenefitGiftbag02")
	end,
	[xyd.ActivityID.NEWYEAR_SIGNIN] = function ()
		return require("app.windows.activity.NewYearSignIn")
	end,
	[xyd.ActivityID.RING_GIFTBAG] = function ()
		return require("app.windows.activity.RingGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG] = function ()
		return require("app.windows.activity.SchoolOpensGiftbag")
	end,
	[xyd.ActivityID.GROW_UP_GIFTBAG] = function ()
		return require("app.windows.activity.GrowUpGiftBag")
	end,
	[xyd.ActivityID.MAKE_CAKE] = function ()
		return require("app.windows.activity.MakeCake")
	end,
	[xyd.ActivityID.JACKPOT_MACHINE] = function ()
		return require("app.windows.activity.ActivityJackPotMachine")
	end,
	[xyd.ActivityID.PROMOTION_GIFTBAG] = function ()
		return require("app.windows.activity.PromotionGiftBag")
	end,
	[xyd.ActivityID.LEVEL_FUND] = function ()
		return require("app.windows.activity.LevelFund")
	end,
	[xyd.ActivityID.BOOK_RESEARCH] = function ()
		return require("app.windows.activity.BookResearch")
	end,
	[xyd.ActivityID.DOUBLE_RING_GIFTBAG] = function ()
		return require("app.windows.activity.DoubleRingGiftbag")
	end,
	[xyd.ActivityID.CANDY_COLLECT] = function ()
		return require("app.windows.activity.ActivityCandyCollect")
	end,
	[xyd.ActivityID.ACTIVITY_MONTHLY] = function ()
		return require("app.windows.activity.ActivityMonthly")
	end,
	[xyd.ActivityID.ACTIVITY_COIN_EMERGENCY] = function ()
		return require("app.windows.activity.ActivityCoinEmergency")
	end,
	[xyd.ActivityID.ACTIVITY_EXP_EMERGENCY] = function ()
		return require("app.windows.activity.ActivityExpEmergency")
	end,
	[xyd.ActivityID.NEW_LEVEL_UP_GIFTBAG] = function ()
		return require("app.windows.activity.NewLevelUpGiftBag")
	end,
	[xyd.ActivityID.NEW_FOUR_STAR_GIFT] = function ()
		return require("app.windows.activity.NewFiveStarGiftBag")
	end,
	[xyd.ActivityID.NEW_FIVE_STAR_GIFT] = function ()
		return require("app.windows.activity.NewFiveStarGiftBag")
	end,
	[xyd.ActivityID.ACTIVITY_VOTE2] = function ()
		return require("app.windows.activity.ActivityVote2")
	end,
	[xyd.ActivityID.NEWYEAR_BAOXIANG] = function ()
		return require("app.windows.activity.ActivityBaoxiang")
	end,
	[xyd.ActivityID.TURING_MISSION] = function ()
		return require("app.windows.activity.TuringMissionWindow")
	end,
	[xyd.ActivityID.BENEFIT_GIFTBAG03] = function ()
		return require("app.windows.activity.BenefitGiftbag")
	end,
	[xyd.ActivityID.BENEFIT_GIFTBAG04] = function ()
		return require("app.windows.activity.BenefitGiftbag")
	end,
	[xyd.ActivityID.ALL_STARS_PRAY] = function ()
		return require("app.windows.activity.ActivityAllStarsPray")
	end,
	[xyd.ActivityID.SUPER_HERO_CLUB] = function ()
		return require("app.windows.activity.ActivitySuperHeroClub")
	end,
	[xyd.ActivityID.DAILY_GIFGBAG] = function ()
		return require("app.windows.activity.DailyGiftBag")
	end,
	[xyd.ActivityID.DAILY_GIFGBAG02] = function ()
		return require("app.windows.activity.DailyGiftBag")
	end,
	[xyd.ActivityID.ONLINE_AWARD] = function ()
		return require("app.windows.activity.OnlineAward")
	end,
	[xyd.ActivityID.BIND_ACCOUNT_ENTRY] = function ()
		return require("app.windows.activity.BindAccountEntryWindow")
	end,
	[xyd.ActivityID.NEWBIE_CAMP] = function ()
		return require("app.windows.activity.NewbieCampWindow")
	end,
	[xyd.ActivityID.ACTIVITY_SEVENDAYS] = function ()
		return require("app.windows.activity.ActivitySevenDay")
	end,
	[xyd.ActivityID.ENERGY_SUMMON] = function ()
		return require("app.windows.activity.ActivityEnergySummon")
	end,
	[xyd.ActivityID.PRIVILEGE_CARD] = function ()
		return require("app.windows.activity.PrivilegeCard")
	end,
	[xyd.ActivityID.NEW_PARTNER_WARMUP] = function ()
		return require("app.windows.activity.NewPartnerWarmup")
	end,
	[xyd.ActivityID.WARMUP_GIFT] = function ()
		return require("app.windows.activity.WarmUpGift")
	end,
	[xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG] = function ()
		return require("app.windows.activity.SchoolOpensGiftbag")
	end,
	[xyd.ActivityID.ICE_SUMMER] = function ()
		return require("app.windows.activity.ActivityIceSummer")
	end,
	[xyd.ActivityID.ICE_SECRET] = function ()
		return require("app.windows.activity.ActivityIceSecret")
	end,
	[xyd.ActivityID.ACTIVITY_FOOD_FESTIVAL] = function ()
		return require("app.windows.activity.ActivityFoodFestival")
	end,
	[xyd.ActivityID.SEVEN_STAR_GIFT] = function ()
		return require("app.windows.activity.SevenStarGift")
	end,
	[xyd.ActivityID.NINE_STAR_GIFT1] = function ()
		return require("app.windows.activity.NineStarGift1")
	end,
	[xyd.ActivityID.NINE_STAR_GIFT2] = function ()
		return require("app.windows.activity.NineStarGift2")
	end,
	[xyd.ActivityID.ACTIVITY_ICE_SECRET_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityIceSecretGiftBag")
	end,
	[xyd.ActivityID.SUMMON_WELFARE] = function ()
		return require("app.windows.activity.SummonWelfare")
	end,
	[xyd.ActivityID.NEW_STAGE_GIFTBAG] = function ()
		return require("app.windows.activity.NewStageGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_TOWER_EMERGENCY] = function ()
		return require("app.windows.activity.ActivityTowerEmergency")
	end,
	[xyd.ActivityID.ACTIVITY_ICE_SECRET_MISSION] = function ()
		return require("app.windows.activity.ActivityIceSecretMission")
	end,
	[xyd.ActivityID.NEW_SUMMON_SPECIAL_HERO_GIFT] = function ()
		return require("app.windows.activity.NewSummonSpecialHeroGift")
	end,
	[xyd.ActivityID.HOT_POINT_PARTNER] = function ()
		return require("app.windows.activity.HotSpotPartnerBox")
	end,
	[xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_UP] = function ()
		return require("app.windows.activity.ActivityEquipLevelUp")
	end,
	[xyd.ActivityID.WISH_CAPSULE] = function ()
		return require("app.windows.activity.WishCapsule")
	end,
	[xyd.ActivityID.ACTIVITY_KEYBOARD] = function ()
		return require("app.windows.activity.ActivityKeyboard")
	end,
	[xyd.ActivityID.DRAGON_BOAT] = function ()
		return require("app.windows.activity.ActivityDragonBoat")
	end,
	[xyd.ActivityID.SPROUTS] = function ()
		return require("app.windows.activity.ActivitySprouts")
	end,
	[xyd.ActivityID.RED_RIDING_HOOD] = function ()
		return require("app.windows.activity.RedRidingHood")
	end,
	[xyd.ActivityID.ACTIVITY_CRYSTAL_GIFT] = function ()
		return require("app.windows.activity.ActivityCrystalGift")
	end,
	[xyd.ActivityID.TOWER_FUND_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityTowerFundGiftBag")
	end,
	[xyd.ActivityID.BENEFIT_GIFTBAG05] = function ()
		return require("app.windows.activity.BenefitGiftbag02")
	end,
	[xyd.ActivityID.BENEFIT_GIFTBAG06] = function ()
		return require("app.windows.activity.BenefitGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_DOUBLE_DROP_QUIZ] = function ()
		return require("app.windows.activity.ActivityDoubleDrop")
	end,
	[xyd.ActivityID.ICE_SECRET_BOSS_CHALLENGE] = function ()
		return require("app.windows.activity.IceSecretBossChallenge")
	end,
	[xyd.ActivityID.ACTIVITY_SCRATCH_CARD] = function ()
		return require("app.windows.activity.ActivityScratchCard")
	end,
	[xyd.ActivityID.HALLOWEEN_PUMPKIN_FIELD] = function ()
		return require("app.windows.activity.ActivityHalloweenPumpkinField")
	end,
	[xyd.ActivityID.ACTIVITY_LASSO] = function ()
		return require("app.windows.activity.ActivityLasso")
	end,
	[xyd.ActivityID.MAGIC_DUST_PUSH_GIFTBGA] = function ()
		return require("app.windows.activity.NewPushGiftBag")
	end,
	[xyd.ActivityID.GRADE_STONE_PUSH_GIFTBAG] = function ()
		return require("app.windows.activity.NewPushGiftBag")
	end,
	[xyd.ActivityID.PET_STONE_PUSH_GIFTBAG] = function ()
		return require("app.windows.activity.NewPushGiftBag")
	end,
	[xyd.ActivityID.ACADEMY_ASSESSMENT_PUSH_GIFTBAG] = function ()
		return require("app.windows.activity.NewPushGiftBag")
	end,
	[xyd.ActivityID.FAN_PAI] = function ()
		return require("app.windows.activity.ActivityFanPai")
	end,
	[xyd.ActivityID.EASTER_EGG] = function ()
		return require("app.windows.activity.ActivityEasterEgg")
	end,
	[xyd.ActivityID.WEEK_MISSION] = function ()
		return require("app.windows.activity.ActivityWeekMission")
	end,
	[xyd.ActivityID.WELFARE_SALE] = function ()
		return require("app.windows.activity.ActivityWelfareSale")
	end,
	[xyd.ActivityID.NEW_SEVENDAY_GIFTBAG] = function ()
		return require("app.windows.activity.NewSevendayGiftbag")
	end,
	[xyd.ActivityID.MONTH_BEGINNING_GIFTBAG] = function ()
		return require("app.windows.activity.MonthBeginningGiftBag")
	end,
	[xyd.ActivityID.KAKAOPAY] = function ()
		return require("app.windows.activity.ActivityKakaopay")
	end,
	[xyd.ActivityID.LIMIT_CALL_BOSS] = function ()
		return require("app.windows.activity.ActivityLimitCallBoss")
	end,
	[xyd.ActivityID.LIMIT_GACHA_AWARD] = function ()
		return require("app.windows.activity.ActivityLimitGachaAward")
	end,
	[xyd.ActivityID.TIME_LIMIT_CALL] = function ()
		return require("app.windows.activity.ActivityLimitTimeRecruit")
	end,
	[xyd.ActivityID.ACTIVITY_SEARCH_BOOK] = function ()
		return require("app.windows.activity.ActivitySearchBook")
	end,
	[xyd.ActivityID.ACTIVITY_BLACK_FRIDAY] = function ()
		return require("app.windows.activity.ActivityBlackFriday")
	end,
	[xyd.ActivityID.NEW_FIRST_RECHARGE] = function ()
		return require("app.windows.activity.NewFirstRecharge")
	end,
	[xyd.ActivityID.NEW_LIMIT_FIVE_STAR_GIFTBAG] = function ()
		return require("app.windows.activity.LimitFiveStarGiftBag")
	end,
	[xyd.ActivityID.LAFULI_DRIFT] = function ()
		return require("app.windows.activity.ActivityLafuliDrift")
	end,
	[xyd.ActivityID.LAFULI_DRIFT_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityLafuliDriftGiftbag")
	end,
	[xyd.ActivityID.EXCHANGE_DUMMY] = function ()
		return require("app.windows.activity.ActivityChristmasExchangeDummy")
	end,
	[xyd.ActivityID.ACTIVITY_CHRISTMAS_SALE] = function ()
		return require("app.windows.activity.ActivityChristmasSale")
	end,
	[xyd.ActivityID.NEW_SUMMON_GIFTBAG] = function ()
		return require("app.windows.activity.NewSummonGiftBag")
	end,
	[xyd.ActivityID.NEWYEAR_NEW_SIGNIN] = function ()
		return require("app.windows.activity.NewYearNewSignIn")
	end,
	[xyd.ActivityID.ACTIVITY_YEAR_FUND] = function ()
		return require("app.windows.activity.ActivityYearFund")
	end,
	[xyd.ActivityID.STUDY_QUESTION] = function ()
		return require("app.windows.activity.ActivityStudyQuestion")
	end,
	[xyd.ActivityID.TULIN_GROWUP_GIFTBAG] = function ()
		return require("app.windows.activity.LimitGropupGiftBag")
	end,
	[xyd.ActivityID.NEWBEE_10GACHA] = function ()
		return require("app.windows.activity.ActivityNewbee10Gacha")
	end,
	[xyd.ActivityID.ACTIVITY_NEWBEE_FUND] = function ()
		return require("app.windows.activity.ActivityNewbeeFund")
	end,
	[xyd.ActivityID.NEWBEE_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityNewbeeGiftBag")
	end,
	[xyd.ActivityID.GAMBLE_PLUS] = function ()
		return require("app.windows.activity.ActivityGamblePlus")
	end,
	[xyd.ActivityID.NEWBEE_GACHA_POOL] = function ()
		return require("app.windows.activity.NewbeeGachaPool")
	end,
	[xyd.ActivityID.NEWYEAR_WELFARE] = function ()
		return require("app.windows.activity.NewYearWelfare")
	end,
	[xyd.ActivityID.SPRING_NEW_YEAR] = function ()
		return require("app.windows.activity.ActivitySpringNewYear")
	end,
	[xyd.ActivityID.ACTIVITY_EXCHANGE] = function ()
		return require("app.windows.activity.ActivityExchange")
	end,
	[xyd.ActivityID.ACTIVITY_RECHARGE] = function ()
		return require("app.windows.activity.ActivityRecharge")
	end,
	[xyd.ActivityID.ACTIVITY_VALENTINE] = function ()
		return require("app.windows.activity.ActivityValentine")
	end,
	[xyd.ActivityID.ACTIVITY_NEW_SHIMO] = function ()
		return require("app.windows.activity.ActivityNewShimo")
	end,
	[xyd.ActivityID.ACTIVITY_SHIMO_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityShimoGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_TREE_GROUP] = function ()
		return require("app.windows.activity.ActivityTreeGroup")
	end,
	[xyd.ActivityID.ACTIVITY_PUPPET] = function ()
		return require("app.windows.activity.ActivityPuppet")
	end,
	[xyd.ActivityID.EASTER_GIFTBAG] = function ()
		return require("app.windows.activity.EasterGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_SMASH_EGG] = function ()
		return require("app.windows.activity.ActivitySmashEgg")
	end,
	[xyd.ActivityID.ACTIVITY_LIMITED_TASK] = function ()
		return require("app.windows.activity.ActivityLimitedTask")
	end,
	[xyd.ActivityID.EASTER_EGG_GIFTBAG] = function ()
		return require("app.windows.activity.EasterEggGiftbag")
	end,
	[xyd.ActivityID.REDEEM_CODE] = function ()
	end,
	[xyd.ActivityID.ACTIVITY_BOMB] = function ()
		return require("app.windows.activity.ActivityBomb")
	end,
	[xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityGraduateGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_PARTNER_GALLERY] = function ()
		return require("app.windows.activity.ActivityPartnerGallery")
	end,
	[xyd.ActivityID.COURSE_RESEARCH] = function ()
		return require("app.windows.activity.ActivityCourseResearch")
	end,
	[xyd.ActivityID.COLLECT_CORAL_BRANCH] = function ()
		return require("app.windows.activity.ActivityCollectCoralBranch")
	end,
	[xyd.ActivityID.ACTIVITY_NEWBEE_LEESON] = function ()
		return require("app.windows.activity.ActivityNewbeeLesson")
	end,
	[xyd.ActivityID.NEWBEE_LESSON_GIFTBAG] = function ()
		return require("app.windows.activity.NewbeeLessonGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_TIME_PARTNER] = function ()
		return require("app.windows.activity.ActivityTimePartner")
	end,
	[xyd.ActivityID.ACTIVITY_TIME_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityTimeGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_TIME_GAMBLE] = function ()
		return require("app.windows.activity.ActivityTimeGamble")
	end,
	[xyd.ActivityID.ACTIVITY_TIME_MISSION] = function ()
		return require("app.windows.activity.ActivityTimeMission")
	end,
	[xyd.ActivityID.ACTIVITY_GIFTBAG_OPTIONAL] = function ()
		return require("app.windows.activity.ActivityGiftBagOptional")
	end,
	[xyd.ActivityID.ACTIVITY_SPACE_EXPLORE_SUPPLY] = function ()
		return require("app.windows.activity.ActivitySpaceExploreSupply")
	end,
	[xyd.ActivityID.ACTIVITY_SPACE_EXPLORE_MISSION] = function ()
		return require("app.windows.activity.ActivitySpaceExploreMission")
	end,
	[xyd.ActivityID.ACTIVITY_SPACE_EXPLORE_TEAM] = function ()
		return require("app.windows.activity.ActivitySpaceExploreTeam")
	end,
	[xyd.ActivityID.ACTIVITY_SPACE_EXPLORE] = function ()
		return require("app.windows.activity.ActivitySpaceExplore")
	end,
	[xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY] = function ()
		return require("app.windows.activity.ActivityOptionalSupply")
	end,
	[xyd.ActivityID.ACTIVITY_NEWBEE_LEESON_2] = function ()
		return require("app.windows.activity.ActivityNewbeeLesson")
	end,
	[xyd.ActivityID.NEWBEE_LESSON_GIFTBAG_2] = function ()
		return require("app.windows.activity.NewbeeLessonGiftbag")
	end,
	[xyd.ActivityID.COURSE_RESEARCH_2] = function ()
		return require("app.windows.activity.ActivityCourseResearch")
	end,
	[xyd.ActivityID.CRYSTAL_BALL] = function ()
		return require("app.windows.activity.ActivityCrystalBall")
	end,
	[xyd.ActivityID.ACTIVITY_WINE] = function ()
		return require("app.windows.activity.ActivityWine")
	end,
	[xyd.ActivityID.ACTIVITY_TREASURE] = function ()
		return require("app.windows.activity.ActivityTreasure")
	end,
	[xyd.ActivityID.ANNIVERSARY_GIFTBAG3_1] = function ()
		return require("app.windows.activity.AnniversaryGiftbag3")
	end,
	[xyd.ActivityID.ANNIVERSARY_GIFTBAG3_2] = function ()
		return require("app.windows.activity.AnniversaryGiftbag3")
	end,
	[xyd.ActivityID.ACTIVITY_3BIRTHDAY_VIP] = function ()
		return require("app.windows.activity.Activity3BirthdayVipWindow")
	end,
	[xyd.ActivityID.ACTIVITY_BEACH_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityBeachGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_BEACH_SUMMER] = function ()
		return require("app.windows.activity.ActivityBeachSummer")
	end,
	[xyd.ActivityID.ACTIVITY_BEACH_PUZZLE] = function ()
		return require("app.windows.activity.ActivityBeachPuzzle")
	end,
	[xyd.ActivityID.ACTIVITY_BEACH_SHOP] = function ()
		return require("app.windows.activity.ActivityBeachShop")
	end,
	[xyd.ActivityID.ACTIVITY_JUNGLE] = function ()
		return require("app.windows.activity.ActivityJungle")
	end,
	[xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_ANTIQUE] = function ()
		return require("app.windows.activity.ActivityEquipLevelAntique")
	end,
	[xyd.ActivityID.ENCONTER_STORY] = function ()
		return require("app.windows.activity.ActivityEnconterStory")
	end,
	[xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY_SUPER] = function ()
		return require("app.windows.activity.ActivityOptionalSupply")
	end,
	[xyd.ActivityID.DRESS_SUMMON_LIMIT] = function ()
		return require("app.windows.activity.ActivityDressSummonLimit")
	end,
	[xyd.ActivityID.ACTIVITY_DRESS_OPENING_CEREMONY] = function ()
		return require("app.windows.activity.ActivityDressOpeningCeremony")
	end,
	[xyd.ActivityID.ACTIVITY_ARTIFACT_EXCHANGE] = function ()
		return require("app.windows.activity.ActivityArtifactExchange")
	end,
	[xyd.ActivityID.ACTIVITY_FISHING] = function ()
		return require("app.windows.activity.ActivityFishing")
	end,
	[xyd.ActivityID.MONTHLY_HIKE] = function ()
		return require("app.windows.activity.ActivityMonthlyHike")
	end,
	[xyd.ActivityID.ACTIVITY_NEWBEE_FUND3] = function ()
		return require("app.windows.activity.ActivityNewbeeFund3")
	end,
	[xyd.ActivityID.ACTIVITY_HALLOWEEN] = function ()
		return require("app.windows.activity.ActivityHalloween")
	end,
	[xyd.ActivityID.ACTIVITY_HALLOWEEN_MISSION] = function ()
		return require("app.windows.activity.ActivityHalloweenMission")
	end,
	[xyd.ActivityID.ACTIVITY_HALLOWEEN_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityHalloweenGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT] = function ()
		return require("app.windows.activity.ActivitySecretTreasureHunt")
	end,
	[xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT_MISSION] = function ()
		return require("app.windows.activity.ActivitySecretTreasureHuntMission")
	end,
	[xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT_GIFTBAG] = function ()
		return require("app.windows.activity.ActivitySecretTreasureHuntGiftbag")
	end,
	[xyd.ActivityID.ALL_STARS_PRAY_GIFTBAG] = function ()
		return require("app.windows.activity.AllStarsPrayGiftbag")
	end,
	[xyd.ActivityID.THANKSGIVING_GIFTBAG] = function ()
		return require("app.windows.activity.ThanksgivingGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_CHRISTMAS_SIGN_UP] = function ()
		return require("app.windows.activity.ActivityChristmasSignUp")
	end,
	[xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY] = function ()
		return require("app.windows.activity.ActivityJackpotLottery")
	end,
	[xyd.ActivityID.ACTIVITY_LUCKYBOXES] = function ()
		return require("app.windows.activity.ActivityLuckyboxes")
	end,
	[xyd.ActivityID.CHRISTMAS_COST] = function ()
		return require("app.windows.activity.ActivityChristmasCost")
	end,
	[xyd.ActivityID.ACTIVITY_SANTA_VISIT] = function ()
		return require("app.windows.activity.ActivitySantaVisit")
	end,
	[xyd.ActivityID.ACTIVITY_CHRISTMAS_EXCHANGE] = function ()
		return require("app.windows.activity.ActivityChristmasExchange")
	end,
	[xyd.ActivityID.ACTIVITY_FIREWORK] = function ()
		return require("app.windows.activity.ActivityFirework")
	end,
	[xyd.ActivityID.ACTIVITY_FIREWORK_AWARD] = function ()
		return require("app.windows.activity.ActivityFireworkAward")
	end,
	[xyd.ActivityID.ACTIVITY_LUCKYBOXES_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityLuckyBoxesGiftbag")
	end,
	[xyd.ActivityID.BENEFIT_GIFTBAG07] = function ()
		return require("app.windows.activity.BenefitGiftbag02")
	end,
	[xyd.ActivityID.ACTIVITY_RECALL_LOTTERY] = function ()
		return require("app.windows.activity.ActivityRecallLottery")
	end,
	[xyd.ActivityID.ACTIVITY_VAMPIRE_TASK] = function ()
		return require("app.windows.activity.ActivityVampireTask")
	end,
	[xyd.ActivityID.ACTIVITY_LAFULI_CASTLE] = function ()
		return require("app.windows.activity.ActivityLafuliCastle")
	end,
	[xyd.ActivityID.ACTIVITY_PROMOTION_LADDER] = function ()
		return require("app.windows.activity.ActivityPromotionLadder")
	end,
	[xyd.ActivityID.ACTIVITY_PROMOTION_TEST] = function ()
		return require("app.windows.activity.ActivityPromotionTest")
	end,
	[xyd.ActivityID.ACTIVITY_PROMOTION_TEST_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityPromotionTestGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_FREEBUY] = function ()
		return require("app.windows.activity.ActivityFreebuyGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_CLOCK] = function ()
		return require("app.windows.activity.ActivityClock")
	end,
	[xyd.ActivityID.ACTIVITY_FOOL_CLOCK_GIFTBAG] = function ()
		return require("app.windows.activity.FoolClockGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_EASTER2022] = function ()
		return require("app.windows.activity.ActivityEaster2022")
	end,
	[xyd.ActivityID.ACTIVITY_SIMULATION_GACHA] = function ()
		return require("app.windows.activity.ActivitySimulationGacha")
	end,
	[xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS] = function ()
		return require("app.windows.activity.NewTrialBattlepass")
	end,
	[xyd.ActivityID.ACTIVITY_RELAY_GIFT] = function ()
		return require("app.windows.activity.ActivityRelayGift")
	end,
	[xyd.ActivityID.ACTIVITY_LOST_SPACE] = function ()
		return require("app.windows.activity.ActivityLostSpace")
	end,
	[xyd.ActivityID.ACTIVITY_LOST_SPACE_GIFTBAG] = function ()
		return require("app.windows.activity.ActivityLostSpaceGiftBag")
	end,
	[xyd.ActivityID.SPRING_GIFTBAG] = function ()
		return require("app.windows.activity.SpringGiftBag")
	end,
	[xyd.ActivityID.ACTIVITY_STAR_ALTAR_MISSION] = function ()
		return require("app.windows.activity.ActivityStarAltarMission")
	end,
	[xyd.ActivityID.NEW_PARTNER_WARMUP_GIFTBAG] = function ()
		return require("app.windows.activity.NewPartnerWarmupGiftbag")
	end,
	[xyd.ActivityID.ACTIVITY_STAR_ALTAR_GIFTBAG] = function ()
		return require("app.windows.activity.StarAltarGiftBag")
	end,
	[xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP] = function ()
		return require("app.windows.activity.ActivityChildhoodShop")
	end,
	[xyd.ActivityID.ACTIVITY_CHILDREN_TASK] = function ()
		return require("app.windows.activity.ActivityChildrenTask")
	end,
	[xyd.ActivityID.ACTIVITY_SPFARM] = function ()
		return require("app.windows.activity.ActivitySpfarm")
	end,
	[xyd.ActivityID.ACTIVITY_DRAGONBOAT2022] = function ()
		return require("app.windows.activity.ActivityDragonboat2022")
	end
}

function ActivityTitleItem:ctor(parentGO, params)
	ActivityTitleItem.super.ctor(self, parentGO)
	self:getUIComponent()

	if params then
		self:setInfo(params)
	end
end

function ActivityTitleItem:getPrefabPath()
	return "Prefabs/Windows/activity/activity_title_item"
end

function ActivityTitleItem:getUIComponent()
	local go = self.go
	self.bg = go:ComponentByName("bg", typeof(UISprite))
	self.imgIcon = go:ComponentByName("imgIcon", typeof(UISprite))
	self.labelTitle01 = go:ComponentByName("labelTitle01", typeof(UILabel))
	self.labelTitle02 = go:ComponentByName("labelTitle02", typeof(UILabel))
	self.labelDiscount = go:ComponentByName("labelDiscount", typeof(UILabel))
	self.labelTimeObj = go:ComponentByName("labelTime", typeof(UILabel))
	self.labelTime = CountDown.new(self.labelTimeObj)
	self.redMark = go:ComponentByName("redMark", typeof(UISprite))
end

function ActivityTitleItem:setInfo(params)
	self.id = params.id
	self.type = params.type
	self.itemType = params.itemType
	self.activityData = xyd.models.activity:getActivity(self.id)

	self:initUIComponent()
end

function ActivityTitleItem:getDetailGiftBag()
	local detail = self.activityData.detail
	local tableID = nil

	if detail and detail[self.type] then
		detail = self.activityData.detail[self.type]
		tableID = self.activityData.detail[self.type].charge.table_id
	elseif detail then
		tableID = self.activityData.detail.table_id
	end

	return detail, tableID
end

function ActivityTitleItem:updateName()
	local nameId = self.id
	self.labelTitle01.text = xyd.tables.activityTextTable:getTitle(nameId)
	self.labelTitle02.text = xyd.tables.activityTextTable:getTitle(nameId)
end

function ActivityTitleItem:initUIComponent()
	self:updateName()

	if self.id == xyd.ActivityID.FOLLOWING_GIFTBAG and xyd.Global.lang == "en_en" then
		xyd.setUISpriteAsync(self.imgIcon, nil, "following_giftbag_en_en")
	elseif self.id == xyd.ActivityID.ACADEMY_ASSESSMENT_PUSH_GIFTBAG then
		local giftBagID = self.activityData.detail[self.type].charge.table_id
		local assessment_type = xyd.tables.giftBagTable:getGiftType(giftBagID) - 63

		xyd.setUISpriteAsync(self.imgIcon, nil, "academy_assessment_activity_icon_" .. assessment_type)
	else
		xyd.setUISpriteAsync(self.imgIcon, "activity_icon", ActivityTable:getIcon(self.id))
	end

	self:setTouchEvent()
	self:setState(false)

	if self.id == xyd.ActivityID.MONTHLY_GIFTBAG or self.id == xyd.ActivityID.WEEKLY_GIFTBAG or self.id == xyd.ActivityID.PRIVILEGE_CARD or self.id == xyd.ActivityID.DAILY_GIFGBAG or self.id == xyd.ActivityID.MONTHLY_GIFTBAG02 or self.id == xyd.ActivityID.WEEKLY_GIFTBAG02 or self.id == xyd.ActivityID.DAILY_GIFGBAG02 then
		local discountActivityID = nil

		if self.id == xyd.ActivityID.MONTHLY_GIFTBAG then
			discountActivityID = xyd.ActivityID.LIMIT_DISCOUNT_MONTHLY_GIFTBAG
		elseif self.id == xyd.ActivityID.WEEKLY_GIFTBAG then
			discountActivityID = xyd.ActivityID.LIMIT_DISCOUNT_WEEKLY_GIFTBAG
		elseif self.id == xyd.ActivityID.PRIVILEGE_CARD then
			discountActivityID = xyd.ActivityID.LIMIT_DISCOUNT_PRIVILEGE_CARD
		elseif self.id == xyd.ActivityID.DAILY_GIFGBAG then
			discountActivityID = xyd.ActivityID.LIMIT_DISCOUNT_DAILY_GIFGBAG
		elseif self.id == xyd.ActivityID.MONTHLY_GIFTBAG02 then
			discountActivityID = xyd.ActivityID.LIMIT_DISCOUNT_MONTHLY_GIFTBAG02
		elseif self.id == xyd.ActivityID.WEEKLY_GIFTBAG02 then
			discountActivityID = xyd.ActivityID.LIMIT_DISCOUNT_WEEKLY_GIFTBAG02
		elseif self.id == xyd.ActivityID.DAILY_GIFGBAG02 then
			discountActivityID = xyd.ActivityID.LIMIT_DISCOUNT_DAILY_GIFGBAG02
		end

		local discountActivityData = xyd.models.activity:getActivity(discountActivityID)
		local discountGiftBagIDs = xyd.tables.activityTable:getGiftBag(discountActivityID)
		local isDiscount = false

		for i = 1, #self.activityData.detail.charges do
			for j = 1, #discountGiftBagIDs do
				if self.activityData.detail.charges[i].table_id == discountGiftBagIDs[j] then
					isDiscount = true
				end
			end
		end

		if isDiscount then
			self.labelDiscount:SetActive(true)

			self.labelDiscount.text = __("SALE_UPPER_TITLE")

			self.labelTimeObj:Y(37)

			local updateTime = discountActivityData:getEndTime()

			if xyd.getServerTime() < updateTime then
				self.labelTime:setInfo({
					duration = updateTime - xyd.getServerTime()
				})
			else
				self.labelTime:SetActive(false)
			end
		else
			local updateTime = self.activityData:getUpdateTime()

			if xyd.getServerTime() < updateTime then
				self.labelTime:setInfo({
					duration = updateTime - xyd.getServerTime()
				})
			else
				self.labelTime:SetActive(false)
			end
		end
	elseif self.id == xyd.ActivityID.MONTH_CARD then
		local activityData_1 = xyd.models.activity:getActivity(xyd.ActivityID.MINI_MONTH_CARD)
		local activityData_2 = xyd.models.activity:getActivity(xyd.ActivityID.MONTH_CARD)
		local tableID_1 = activityData_1:getGiftBagID()
		local tableID_2 = activityData_2:getGiftBagID()
		local limitDiscountData1 = xyd.models.activity:getActivity(xyd.ActivityID.LIMIT_DISCOUNT_MINI_MONTH_CARD)
		local limitDiscountData2 = xyd.models.activity:getActivity(xyd.ActivityID.LIMIT_DISCOUNT_MONTH_CARD)
		local limitDiscountGiftbagID1 = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.LIMIT_DISCOUNT_MINI_MONTH_CARD)[1]
		local limitDiscountGiftbagID2 = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.LIMIT_DISCOUNT_MONTH_CARD)[1]

		if tableID_1 == limitDiscountGiftbagID1 or tableID_2 == limitDiscountGiftbagID2 then
			self.labelDiscount:SetActive(true)

			self.labelDiscount.text = __("SALE_UPPER_TITLE")

			self.labelTimeObj:Y(37)

			local updateTime = -1

			if tableID_1 == limitDiscountGiftbagID1 then
				updateTime = limitDiscountData1:getEndTime()
			end

			if tableID_2 == limitDiscountGiftbagID2 then
				updateTime = math.max(limitDiscountData2:getEndTime(), updateTime)
			end

			if xyd.getServerTime() < updateTime then
				self.labelTime:setInfo({
					duration = updateTime - xyd.getServerTime()
				})
			else
				self.labelTime:SetActive(false)
			end
		else
			local updateTime = self.activityData:getUpdateTime()

			if xyd.getServerTime() < updateTime then
				self.labelTime:setInfo({
					duration = updateTime - xyd.getServerTime()
				})
			else
				self.labelTime:SetActive(false)
			end
		end
	elseif self.id == xyd.ActivityID.ACTIVITY_VOTE then
		local timestamps = xyd.tables.miscTable:split2Cost("wedding_vote_time_interval", "value", "|")
		local start_time = self.activityData.startTime
		local cur_time = xyd.getServerTime() - start_time

		for i = 1, #timestamps do
			if cur_time < timestamps[i] then
				cur_time = timestamps[i] - cur_time

				break
			end
		end

		if cur_time < 0 then
			self.labelTime:SetActive(false)
		else
			self.labelTime:setInfo({
				duration = cur_time
			})
		end
	else
		local updateTime = self.activityData:getUpdateTime()

		if xyd.ActivityID.ACTIVITY_EXP_EMERGENCY <= self.id and self.id <= xyd.ActivityID.NEW_FIVE_STAR_GIFT or self.id == xyd.ActivityID.SUMMON_WELFARE or self.id == xyd.ActivityID.SEVEN_STAR_GIFT or self.id == xyd.ActivityID.NINE_STAR_GIFT1 or self.id == xyd.ActivityID.NINE_STAR_GIFT2 or xyd.ActivityID.MAGIC_DUST_PUSH_GIFTBGA <= self.id and self.id <= xyd.ActivityID.ACADEMY_ASSESSMENT_PUSH_GIFTBAG or self.id == xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY or self.id == xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY_SUPER then
			updateTime = self:getUpdateTime()
		end

		if xyd.getServerTime() < updateTime then
			self.labelTime:setInfo({
				duration = updateTime - xyd.getServerTime()
			})
		else
			self.labelTime:SetActive(false)
		end
	end

	self:setRedMark()
end

function ActivityTitleItem:getUpdateTime()
	local detail, tableID = self:getDetailGiftBag()
	local updateTime = nil

	if detail.update_time then
		updateTime = detail.update_time
	else
		updateTime = 0
	end

	if not updateTime then
		return detail.end_time
	end

	return updateTime + xyd.tables.giftBagTable:getLastTime(tableID)
end

function ActivityTitleItem:setTouchEvent()
	self:setTouchListener(handler(self, self.onTouch))
end

function ActivityTitleItem:onTouch()
	if self.currentState then
		return
	end

	self:setState(true)
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	local wnd = xyd.WindowManager.get():getWindow("activity_window")

	if wnd then
		wnd.select2 = self.id

		wnd:setCurrentActivity(self.id, self.type)
	end

	self.activityData:setDefRedMark(false)
	XYDCo.WaitForTime(0.5, xyd.scb(self.go, function ()
		self:setRedMark()
	end), nil)
end

function ActivityTitleItem:setState(isSelect)
	self.currentState = isSelect

	if self.itemType == nil then
		if isSelect then
			xyd.setUISprite(self.bg, nil, "activity_icon_1_big")
		else
			xyd.setUISprite(self.bg, nil, "activity_icon_0_big")
		end
	elseif isSelect then
		xyd.setUISprite(self.bg, nil, "activity_icon_1_" .. self.itemType)

		self.imgIcon.width = 76
		self.imgIcon.height = 76
	else
		xyd.setUISprite(self.bg, nil, "activity_icon_0_" .. self.itemType)

		self.imgIcon.width = 76
		self.imgIcon.height = 76
	end

	self.bg:MakePixelPerfect()

	self.labelTitle01.width = self.itemType == "middle" and 120 or 160
	self.labelTitle02.width = self.itemType == "middle" and 120 or 160
	self.go:GetComponent(typeof(UIWidget)).height = self.bg.height
	self.go:GetComponent(typeof(UIWidget)).width = self.bg.width

	self.labelTitle01:SetActive(isSelect)
	self.labelTitle02:SetActive(not isSelect)
end

function ActivityTitleItem:setRedMark()
	self.redMark:SetActive(self.activityData:getRedMarkState())

	if self.itemType ~= nil and self.itemType == "middle" then
		self.redMark.transform:X(54)
	end
end

function ActivityTitleItem:setTimeLabel(count)
	if not count then
		self.labelTime:stopTimeCount()
		self.labelTime:SetActive(false)

		return
	end

	self.labelTime:setInfo({
		duration = count
	})
	self.labelTime:SetActive(true)
end

function ActivityTitleItem:addStroke()
	self.labelTitle01.stroke = 2
	self.labelTitle01.strokeColor = 16777215
	self.labelTitle02.stroke = 2
	self.labelTitle02.strokeColor = 16777215
end

function ActivityTitleItem:cancelStroke()
	self.labelTitle01.stroke = 0
	self.labelTitle02.stroke = 0
end

function ActivityTitleItem.____getters:ID()
	return self.id
end

function ActivityTitleItem:getId()
	return self.id
end

function ActivityTitleItem.____getters:TYPE()
	return self.type
end

function ActivityTitleItem:getRedMarkVisible()
	return self.redMark.gameObject.activeSelf
end

function ActivityTitleItem:getSelfGo()
	return self.go
end

return ActivityWindow
