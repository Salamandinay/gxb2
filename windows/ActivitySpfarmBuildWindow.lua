local ActivitySpfarmBuildWindow = class("ActivitySpfarmBuildWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local BuildItem = class("BuildItem", import("app.components.CopyComponent"))
local CommonTabBar = import("app.common.ui.CommonTabBar")
local json = require("cjson")

function ActivitySpfarmBuildWindow:ctor(name, params)
	ActivitySpfarmBuildWindow.super.ctor(self, name, params)

	self.enterType = params.type
	self.pos = params.pos
	self.defaultLev = params.defaultLev or 1
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)

	if self:getEnterType() == xyd.ActivitySpfarmBuildWindowType.CHANGE then
		self.enterBuildID = self.activityData:getBuildBaseInfo(self.pos).build_id
	end
end

function ActivitySpfarmBuildWindow:initWindow()
	self:getUIComponent()
	ActivitySpfarmBuildWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function ActivitySpfarmBuildWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.winTitle = self.topGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.helpBtn = self.topGroup:NodeByName("helpBtn").gameObject
	self.closeBtn = self.topGroup:NodeByName("closeBtn").gameObject
	self.navBtns = self.groupAction:NodeByName("navBtns").gameObject
	self.buildItem = self.groupAction:NodeByName("buildItem").gameObject
	self.scrollView = self.groupAction:NodeByName("scrollView").gameObject
	self.scrollViewUIScrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.scrollContent = self.scrollView:NodeByName("scrollContent").gameObject
	self.scrollContentMultiRowWrapContent = self.scrollView:ComponentByName("scrollContent", typeof(MultiRowWrapContent))
	self.multiWrap = require("app.common.ui.FixedMultiWrapContent").new(self.scrollViewUIScrollView, self.scrollContentMultiRowWrapContent, self.buildItem, BuildItem, self)
	self.downGroup = self.groupAction:NodeByName("downGroup").gameObject
	self.btn = self.downGroup:NodeByName("btn").gameObject
	self.btnLable = self.btn:ComponentByName("btnLable", typeof(UILabel))
	self.resItem = self.downGroup:NodeByName("resItem").gameObject
	self.resItemBg = self.resItem:ComponentByName("resItemBg", typeof(UISprite))
	self.resItemIcon = self.resItem:ComponentByName("resItemIcon", typeof(UISprite))
	self.resItemLabel = self.resItem:ComponentByName("resItemLabel", typeof(UILabel))
	self.scrollView2 = self.groupAction:NodeByName("scrollView2").gameObject
	self.scrollView2UIScrollView = self.groupAction:ComponentByName("scrollView2", typeof(UIScrollView))
	self.descLabel = self.scrollView2:ComponentByName("descLabel", typeof(UILabel))
end

function ActivitySpfarmBuildWindow:reSize()
end

function ActivitySpfarmBuildWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.btn.gameObject).onClick = handler(self, function ()
		if self:getEnterType() == xyd.ActivitySpfarmBuildWindowType.CHANGE and self.selectId == self.enterBuildID then
			xyd.alertTips(__("ACTIVITY_SPFARM_TEXT29"))

			return
		end

		local buildType = xyd.tables.activitySpfarmBuildingTable:getType(self.selectId)
		local curNum = self.activityData:getcurBuildNum(self.selectId)
		local limitNum = self.activityData:getTypeBuildLimitNumUp(buildType)

		if limitNum <= curNum then
			if self.activityData:getTypeBuildMaxNumUp(buildType) <= limitNum then
				xyd.alertTips(__("ACTIVITY_SPFARM_TEXT14"))
			else
				xyd.alertTips(__("ACTIVITY_SPFARM_TEXT105"))
			end

			return
		end

		if self:getEnterType() == xyd.ActivitySpfarmBuildWindowType.CHANGE then
			local limitLev = self.activityData:getTypeBuildLimitLevUp(buildType)

			if limitLev < self:getDefaultLev() then
				xyd.alertTips(__("ACTIVITY_SPFARM_TEXT15"))

				return
			end
		end

		if self:getEnterType() == xyd.ActivitySpfarmBuildWindowType.BUILD then
			local cost = xyd.tables.activitySpfarmBuildingTable:getCost(self.selectId)
			local hasNum = xyd.models.backpack:getItemNumByID(cost[1])

			if hasNum < cost[2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

				return
			end

			local function sendFun()
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
					type = xyd.ActivitySpfarmType.BUILD,
					pos = self.pos,
					build_id = self.selectId
				}))
			end

			local function canBuildFun()
				local timeStamp = xyd.db.misc:getValue("actiivty_spfarm_build_build_time_stamp")
				timeStamp = timeStamp and tonumber(timeStamp)

				if not timeStamp or timeStamp < self.activityData:startTime() or self.activityData:getEndTime() < timeStamp then
					xyd.openWindow("gamble_tips_window", {
						type = "actiivty_spfarm_build_build",
						wndType = self.curWindowType_,
						text = __("ACTIVITY_SPFARM_TEXT18", cost[2], xyd.tables.itemTable:getName(cost[1])),
						callback = function ()
							sendFun()
						end,
						labelNeverText = __("ACTIVITY_SPFARM_TEXT30")
					})

					return
				else
					sendFun()

					return
				end
			end

			if self.activityData:isViewing() then
				local timeStamp = xyd.db.misc:getValue("actiivty_spfarm_isviewing_click_time_stamp")
				timeStamp = timeStamp and tonumber(timeStamp)

				if not timeStamp or timeStamp < self.activityData:startTime() or self.activityData:getEndTime() < timeStamp then
					xyd.openWindow("gamble_tips_window", {
						type = "actiivty_spfarm_isviewing_click",
						wndType = self.curWindowType_,
						text = __("ACTIVITY_SPFARM_TEXT116"),
						callback = function ()
							sendFun()
						end,
						labelNeverText = __("ACTIVITY_SPFARM_TEXT30")
					})
				else
					canBuildFun()
				end
			else
				canBuildFun()
			end

			return
		end

		if self:getEnterType() == xyd.ActivitySpfarmBuildWindowType.CHANGE then
			local cost = xyd.tables.activitySpfarmBuildingTable:getCostExchange(self.selectId)
			local hasNum = xyd.models.backpack:getItemNumByID(cost[1])

			if hasNum < cost[2] * self:getDefaultLev() then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

				return
			end

			local id = self.activityData:getBuildBaseInfo(self.pos).id

			local function sendFun()
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
					type = xyd.ActivitySpfarmType.CHANGE,
					id = id,
					build_id = self.selectId
				}))
			end

			local function canChangeFun()
				local timeStamp = xyd.db.misc:getValue("actiivty_spfarm_build_change_time_stamp")
				timeStamp = timeStamp and tonumber(timeStamp)

				if not timeStamp or timeStamp < self.activityData:startTime() or self.activityData:getEndTime() < timeStamp then
					xyd.openWindow("gamble_tips_window", {
						type = "actiivty_spfarm_build_change",
						wndType = self.curWindowType_,
						text = __("ACTIVITY_SPFARM_TEXT19", cost[2] * self:getDefaultLev(), xyd.tables.itemTable:getName(cost[1])),
						callback = function ()
							sendFun()
						end,
						labelNeverText = __("ACTIVITY_SPFARM_TEXT30")
					})

					return
				else
					sendFun()

					return
				end
			end

			if self.activityData:isViewing() then
				local timeStamp = xyd.db.misc:getValue("actiivty_spfarm_isviewing_click_time_stamp")
				timeStamp = timeStamp and tonumber(timeStamp)

				if not timeStamp or timeStamp < self.activityData:startTime() or self.activityData:getEndTime() < timeStamp then
					xyd.openWindow("gamble_tips_window", {
						type = "actiivty_spfarm_isviewing_click",
						wndType = self.curWindowType_,
						text = __("ACTIVITY_SPFARM_TEXT116"),
						callback = function ()
							sendFun()
						end,
						labelNeverText = __("ACTIVITY_SPFARM_TEXT30")
					})
				else
					canChangeFun()
				end
			else
				canChangeFun()
			end
		end
	end)
end

function ActivitySpfarmBuildWindow:layout()
	if self:getEnterType() == xyd.ActivitySpfarmBuildWindowType.BUILD then
		self.winTitle.text = __("ACTIVITY_SPFARM_TEXT09")
		self.btnLable.text = __("ACTIVITY_SPFARM_TEXT09")
	elseif self:getEnterType() == xyd.ActivitySpfarmBuildWindowType.CHANGE then
		self.winTitle.text = __("ACTIVITY_SPFARM_TEXT10")
		self.btnLable.text = __("ACTIVITY_SPFARM_TEXT10")
	end

	self.buildIdsArr = {}

	table.insert(self.buildIdsArr, xyd.tables.activitySpfarmBuildingTable:getCommonBuildIds())
	table.insert(self.buildIdsArr, xyd.tables.activitySpfarmBuildingTable:getHighBuildArr())
	table.insert(self.buildIdsArr, xyd.tables.activitySpfarmBuildingTable:getSpecialBuildArr())
	self:initNav()
	self:updateDownShow()
end

function ActivitySpfarmBuildWindow:initNav()
	self.navTab = CommonTabBar.new(self.navBtns, 3, function (index)
		self:changeNav(index)
	end)
	local navStr = {
		__("ACTIVITY_SPFARM_TEXT11"),
		__("ACTIVITY_SPFARM_TEXT12"),
		__("ACTIVITY_SPFARM_TEXT13")
	}

	self.navTab:setTexts(navStr)

	local lastChoiceNav = xyd.db.misc:getValue("activity_spfarm_build_choice_nav")

	if lastChoiceNav then
		lastChoiceNav = tonumber(lastChoiceNav)
	elseif self.enterBuildID then
		for i = 1, 3 do
			if xyd.arrayIndexOf(self.buildIdsArr[i], self.enterBuildID) > 0 then
				lastChoiceNav = i

				break
			end
		end
	else
		lastChoiceNav = 1
	end

	if self.enterBuildID then
		if xyd.arrayIndexOf(self.buildIdsArr[lastChoiceNav], self.enterBuildID) > 0 then
			self.selectId = self.enterBuildID
		else
			self.selectId = self.buildIdsArr[lastChoiceNav][1]
		end
	else
		self.selectId = self.buildIdsArr[lastChoiceNav][1]
	end

	self.navTab:setTabActive(lastChoiceNav, true, false)
end

function ActivitySpfarmBuildWindow:changeNav(index)
	if self.pageIndex and self.pageIndex == index then
		return
	end

	self.pageIndex = index
	local arr = {}
	arr = self.buildIdsArr[self.pageIndex]

	self.multiWrap:setInfos(arr, {})
	self.scrollViewUIScrollView:ResetPosition()

	if not self.noFirstClcikNav then
		self.noFirstClcikNav = true
	else
		self:changeSelet(arr[1])
	end
end

function ActivitySpfarmBuildWindow:willClose()
	xyd.db.misc:setValue({
		key = "activity_spfarm_build_choice_nav",
		value = self.pageIndex
	})
	ActivitySpfarmBuildWindow.super.willClose(self)
end

function ActivitySpfarmBuildWindow:getSelectId()
	return self.selectId
end

function ActivitySpfarmBuildWindow:changeSelet(buildId)
	for i, item in pairs(self.multiWrap:getItems()) do
		if item:getBuildId() == self.selectId then
			item:setSelect(false)
		elseif item:getBuildId() == buildId then
			item:setSelect(true)
		end
	end

	self.selectId = buildId

	self:updateDownShow()
end

function ActivitySpfarmBuildWindow:updateDownShow()
	local defense = xyd.tables.activitySpfarmBuildingTable:getDefense(self.selectId)
	local outCome = xyd.tables.activitySpfarmBuildingTable:getOutcome(self.selectId)
	local lev = self:getDefaultLev()

	if self:getEnterType() == xyd.ActivitySpfarmBuildWindowType.CHANGE then
		local buildType = xyd.tables.activitySpfarmBuildingTable:getType(self.selectId)
		local limitLev = self.activityData:getTypeBuildLimitLevUp(buildType)

		if limitLev < self:getDefaultLev() then
			lev = limitLev
		end
	end

	if defense and defense > 0 then
		self.descLabel.text = __("ACTIVITY_SPFARM_TEXT17", tostring(defense * lev * 100) .. "%")
	elseif outCome and #outCome > 0 then
		local nameStr = xyd.tables.itemTable:getName(outCome[1])
		self.descLabel.text = __("ACTIVITY_SPFARM_TEXT16", xyd.getRoughDisplayNumber(outCome[2] * lev), nameStr)
	end

	self.scrollView2UIScrollView:ResetPosition()

	if self:getEnterType() == xyd.ActivitySpfarmBuildWindowType.BUILD then
		local cost = xyd.tables.activitySpfarmBuildingTable:getCost(self.selectId)

		xyd.setUISpriteAsync(self.resItemIcon, nil, xyd.tables.itemTable:getIcon(cost[1]))

		self.resItemLabel.text = cost[2] .. "/" .. xyd.models.backpack:getItemNumByID(cost[1])
	elseif self:getEnterType() == xyd.ActivitySpfarmBuildWindowType.CHANGE then
		local cost = xyd.tables.activitySpfarmBuildingTable:getCostExchange(self.selectId)

		xyd.setUISpriteAsync(self.resItemIcon, nil, xyd.tables.itemTable:getIcon(cost[1]))

		self.resItemLabel.text = cost[2] * lev .. "/" .. xyd.models.backpack:getItemNumByID(cost[1])
	end
end

function ActivitySpfarmBuildWindow:getDefaultLev()
	return self.defaultLev
end

function ActivitySpfarmBuildWindow:getEnterType()
	return self.enterType
end

function ActivitySpfarmBuildWindow:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SPFARM then
		return
	end

	local data = xyd.decodeProtoBuf(event.data)
	data.detail = json.decode(data.detail)

	if data.detail.type == xyd.ActivitySpfarmType.BUILD then
		self:close()
	elseif data.detail.type == xyd.ActivitySpfarmType.CHANGE then
		self:close()
	end
end

function BuildItem:ctor(goItem, parent)
	self.goItem_ = goItem
	self.parent = parent
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)

	BuildItem.super.ctor(self, goItem)
end

function BuildItem:initUI()
	self.bottomBg = self.go:ComponentByName("bottomBg", typeof(UISprite))
	self.buildImg = self.go:ComponentByName("buildImg", typeof(UISprite))
	self.nameLabel = self.go:ComponentByName("nameLabel", typeof(UILabel))
	self.infoBg = self.go:ComponentByName("infoBg", typeof(UISprite))
	self.levLabel = self.infoBg:ComponentByName("levLabel", typeof(UILabel))
	self.numLabel = self.infoBg:ComponentByName("numLabel", typeof(UILabel))
	self.lockCon = self.go:NodeByName("lockCon").gameObject
	self.lockImg1 = self.lockCon:ComponentByName("lockImg1", typeof(UISprite))
	self.lockImg2 = self.lockCon:ComponentByName("lockImg2", typeof(UISprite))
	self.selectImg = self.go:ComponentByName("selectImg", typeof(UISprite))
	UIEventListener.Get(self.go.gameObject).onClick = handler(self, self.onTouch)

	if xyd.Global.lang == "fr_fr" then
		self.nameLabel.fontSize = 18
	end
end

function BuildItem:onTouch()
	if self.buildId ~= self.parent:getSelectId() then
		self.parent:changeSelet(self.buildId)
	end
end

function BuildItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.buildId = info
	local buildImg = xyd.tables.activitySpfarmBuildingTable:getIcon(self.buildId)

	xyd.setUISpriteAsync(self.buildImg, nil, buildImg)

	if self.buildId == self.parent:getSelectId() then
		self:setSelect(true)
	else
		self:setSelect(false)
	end

	self.nameLabel.text = xyd.tables.activitySpfarmBuildingTextTable:getName(self.buildId)
	local lev = self.parent:getDefaultLev()
	local buildType = xyd.tables.activitySpfarmBuildingTable:getType(self.buildId)
	local curNum = self.activityData:getcurBuildNum(self.buildId)
	local limitNum = self.activityData:getTypeBuildLimitNumUp(buildType)
	self.numLabel.text = curNum .. "/" .. limitNum

	self.lockCon:SetActive(false)

	if limitNum <= curNum then
		self.lockCon:SetActive(true)
	else
		self.lockCon:SetActive(false)
	end

	if not self.lockCon.gameObject.activeSelf and self.buildId == self.parent.enterBuildID then
		self.lockCon:SetActive(true)
	end

	if self.parent:getEnterType() == xyd.ActivitySpfarmBuildWindowType.CHANGE then
		local limitLev = self.activityData:getTypeBuildLimitLevUp(buildType)

		if limitLev < self.parent:getDefaultLev() then
			self.lockCon:SetActive(true)

			lev = limitLev
		end
	end

	self.levLabel.text = "Lv." .. lev

	if xyd.Global.lang == "fr_fr" then
		self.levLabel.text = "Niv." .. lev
	end
end

function BuildItem:setSelect(state)
	self.selectImg.gameObject:SetActive(state)
end

function BuildItem:getBuildId()
	return self.buildId
end

return ActivitySpfarmBuildWindow
