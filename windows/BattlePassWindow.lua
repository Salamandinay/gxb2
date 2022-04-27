local BattlePassWindow = class("BattlePassWindow", import(".BaseWindow"))
local BattlePassSteam = class("BattlePassSteam", import("app.components.BattlePassSteam"))
local BattlePassSteamNew = class("BattlePassSteam", import("app.components.BattlePassSteamNew"))
local BattlePassMission = class("BattlePassMission", import("app.components.BattlePassMission"))
local BattlePassExchange = class("BattlePassExchange", import("app.components.BattlePassExchange"))
local BattlePassAchieve = class("BattlePassAchieve", import("app.components.BattlePassAchieve"))
local CommonTabBar = import("app.common.ui.CommonTabBar")
local json = require("cjson")

function BattlePassWindow:ctor(name, params)
	BattlePassWindow.super.ctor(self, name, params)

	self.rootList_ = {}
	self.contentList_ = {}
	local activityId = xyd.models.activity:getBattlePassId()
	local needLoadRes = {}
	self.battlePassAwardTable = xyd.models.activity:getBattlePassTable(xyd.BATTLE_PASS_TABLE.AWARD)
	local paidAwards = self.battlePassAwardTable:getPaidAward(5)

	for idx, itemData in ipairs(paidAwards) do
		local itemId = itemData[1]
		local source = xyd.tables.itemTable:getIcon(itemId)

		table.insert(needLoadRes, xyd.getSpritePath(source))
	end

	self:setResourcePaths(needLoadRes)

	self.activityData = xyd.models.activity:getActivity(activityId)
	local redType = xyd.models.redMark:getRedState(xyd.RedMarkType.BATTLE_PASS)

	if redType then
		xyd.models.mission:getData()
		xyd.models.achievement:getData()
	end

	if params and params.tag then
		self.cur_select_ = params.tag + 1
		self.labelIndex_ = params.labelIndex
		self.isBack_ = params.isBack
	else
		self:initOpenIndex()
	end

	if params and params.open_buy_window then
		self.openBuyWindow_ = params.open_buy_window
	end

	local storyFlag = tonumber(xyd.db.misc:getValue("battle_pass_story"))
	local plot_id = xyd.tables.miscTable:getNumber("battle_pass_plot", "value")

	if storyFlag and storyFlag ~= 1 then
		-- Nothing
	end

	if self.openBuyWindow_ and self.openBuyWindow_ == 1 then
		self:openBuyWindow()
	end

	self:checkOpenBuyWindow()
end

function BattlePassWindow:initWindow()
	BattlePassWindow.super.initWindow(self)

	self.image1_ = self.window_:NodeByName("content/e:image").gameObject
	self.image2_ = self.window_:NodeByName("content/e:image2").gameObject
	self.nav_ = self.window_:NodeByName("content/e:image/navGroup").gameObject
	self.nav2_ = self.window_:NodeByName("content/e:image2/navGroup").gameObject

	for i = 1, 4 do
		local root = self.window_:NodeByName("content/groupItem/content" .. i).gameObject
		self.rootList_[i] = {
			root = root
		}
	end
end

function BattlePassWindow:playOpenAnimation(callback)
	BattlePassWindow.super.playOpenAnimation(self, function ()
		self:initTop()
		self:initLayout()
		self:registerEvent()
		self:initRedPointImg()

		if xyd.Global.lang == "fr_fr" then
			for i = 1, 4 do
				local label = self.nav_:ComponentByName("tab_" .. i .. "/label", typeof(UILabel))
				label.fontSize = 22
			end
		end

		if callback then
			callback()
		end
	end)
end

function BattlePassWindow:checkOpenBuyWindow()
	local bpLv = xyd.getBpLev()
	local startTime = self.activityData:startTime()
	local endTime = self.activityData:getEndTime()
	local timeFlag = tonumber(xyd.db.misc:getValue("battle_pass_time_flag"))
	local timeFlag2 = tonumber(xyd.db.misc:getValue("battle_pass_time_open"))
	local lastTimeList = xyd.tables.miscTable:split2num("battle_pass_time", "value", "|")
	local severTime = xyd.getServerTime()

	if timeFlag2 and startTime <= timeFlag2 and (not timeFlag or timeFlag and timeFlag < startTime) then
		self:openBuyWindow()

		return
	end

	xyd.db.misc:setValue({
		key = "battle_pass_time_open",
		value = xyd.getServerTime()
	})

	for _, chargeData in ipairs(self.activityData.detail.charges) do
		if tonumber(chargeData.buy_times) > 0 then
			return
		end
	end

	local limitLv = xyd.tables.miscTable:getNumber("battle_pass_level", "value")

	if bpLv < limitLv then
		return
	end

	local index = nil

	for i = 1, #lastTimeList - 1 do
		if endTime - severTime >= 86400 * lastTimeList[i + 1] and endTime - severTime <= 86400 * lastTimeList[i] then
			index = i

			if timeFlag and endTime - timeFlag > 86400 * lastTimeList[index] then
				self:openBuyWindow()

				return
			end
		end
	end
end

function BattlePassWindow:openBuyWindow()
	local showType = "noGift"

	if self.activityData.detail.charges[3].buy_times > 0 then
		showType = "buyTop"
	elseif self.activityData.detail.charges[1].buy_times > 0 then
		if self.activityData.detail.charges[2].buy_times > 0 then
			showType = "buyAll"
		else
			showType = "buyOne"
		end
	end

	if showType == "buyTop" or showType == "buyAll" then
		return
	end

	xyd.db.misc:setValue({
		key = "battle_pass_time_flag",
		value = xyd.getServerTime()
	})

	local winName = "battle_pass_buy_window_new"

	xyd.WindowManager.get():openWindow(winName, {
		showType = showType
	})
end

function BattlePassWindow:initLayout()
	local chosen = {
		color = Color.New2(2439060479.0),
		effectColor = Color.New2(4294833407.0)
	}
	local unchosen = {
		color = Color.New2(4277988351.0),
		effectColor = Color.New2(1799694591)
	}
	local nav = self.nav_
	local colorParams = {
		chosen = chosen,
		unchosen = unchosen
	}
	local tableLabels = xyd.split(__("BATTLE_PASS_TAGS"), "|")
	local group = 1
	nav = self.nav2_

	self.image1_:SetActive(false)

	colorParams = nil
	tableLabels = xyd.split(__("BP_TAGS"), "|")

	self.image2_:SetActive(true)
	nav:SetActive(true)

	self.tab = CommonTabBar.new(nav, 4, function (index)
		self:onTouch(index)

		if self.hasInit_ then
			xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
		end

		self.hasInit_ = true
	end, nil, colorParams, group)

	self.tab:setTexts(tableLabels)
	self.tab:setTabActive(self.cur_select_, true)
end

function BattlePassWindow:getWindowTop()
	return self.windowTop_
end

function BattlePassWindow:initTop()
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}
	self.windowTop_ = import("app.components.WindowTop").new(self.window_, self.name_)

	self.windowTop_:setItem(items)
end

function BattlePassWindow:getEventProxy()
	return self.eventProxy_
end

function BattlePassWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function BattlePassWindow:initRedPointImg()
	for i = 1, 4 do
		local redIcon = self.nav_:ComponentByName("tab_" .. i .. "/redPoint", typeof(UISprite))
		local redIcon2 = self.nav2_:ComponentByName("tab_" .. i .. "/redPoint", typeof(UISprite))

		if redIcon then
			if i == 1 then
				xyd.models.redMark:setMarkImg(xyd.RedMarkType.BATTLE_PASS, redIcon.gameObject)
			elseif i == 2 then
				xyd.models.redMark:setJointMarkImg({
					xyd.RedMarkType.MISSION,
					xyd.RedMarkType.BATTLE_PASS_MISSION1,
					xyd.RedMarkType.BATTLE_PASS_MISSION2,
					xyd.RedMarkType.BATTLE_PASS_MISSION3
				}, redIcon.gameObject)
			else
				xyd.models.redMark:setMarkImg(xyd.RedMarkType.ACHIEVEMENT, redIcon.gameObject)
			end
		end

		if redIcon2 then
			if i == 1 then
				xyd.models.redMark:setMarkImg(xyd.RedMarkType.BATTLE_PASS, redIcon2.gameObject)
			elseif i == 2 then
				xyd.models.redMark:setJointMarkImg({
					xyd.RedMarkType.MISSION,
					xyd.RedMarkType.BATTLE_PASS_MISSION1,
					xyd.RedMarkType.BATTLE_PASS_MISSION2,
					xyd.RedMarkType.BATTLE_PASS_MISSION3
				}, redIcon2.gameObject)
			else
				xyd.models.redMark:setMarkImg(xyd.RedMarkType.ACHIEVEMENT, redIcon2.gameObject)
			end
		end
	end
end

function BattlePassWindow:initOpenIndex()
	self.activityData:getRedMarkState()

	local redState4 = xyd.models.redMark:getRedState(xyd.RedMarkType.ACHIEVEMENT)
	local redState1 = xyd.models.redMark:getRedState(xyd.RedMarkType.BATTLE_PASS)
	local redState2 = xyd.models.redMark:getRedState(xyd.RedMarkType.BATTLE_PASS_MISSION1) or xyd.models.redMark:getRedState(xyd.RedMarkType.BATTLE_PASS_MISSION2) or xyd.models.redMark:getRedState(xyd.RedMarkType.BATTLE_PASS_MISSION3) or xyd.models.redMark:getRedState(xyd.RedMarkType.MISSION)

	if redState1 then
		self.cur_select_ = 1
	elseif redState2 then
		self.cur_select_ = 2
	elseif redState4 then
		self.cur_select_ = 4
	else
		self.cur_select_ = 1
	end
end

function BattlePassWindow:onTouch(index)
	if self.hasClose_ then
		return
	end

	self.cur_select_ = index
	self.panelDepth_ = self.window_:GetComponent(typeof(UIPanel)).depth
	local activityId = xyd.models.activity:getBattlePassId()
	local switch = {
		function ()
			self.rootList_[1].root:SetActive(true)

			local item = BattlePassSteamNew.new(self.rootList_[1].root, self)

			item:layOutUI()

			return item
		end,
		function ()
			local item = BattlePassMission.new(self.rootList_[2].root, {
				isBack = self.isBack_,
				parent = self
			})

			item.go:SetActive(true)
			item:layout()

			return item
		end,
		function ()
			local item = BattlePassExchange.new(self.rootList_[3].root, self)

			item:layout()
			item.go:SetActive(true)

			return item
		end,
		function ()
			local item = BattlePassAchieve.new(self.rootList_[4].root, self)

			item.go:SetActive(true)
			item:layout()

			return item
		end
	}
	local cotentItem = self.contentList_[index]

	if not cotentItem then
		local item = switch[index]()
		self.contentList_[index] = item

		self.contentList_[index]:SetActive(true)
	else
		self.contentList_[index]:SetActive(true)
		self.contentList_[index]:updatePage(true)
	end

	self:waitForFrame(1, function ()
		for i = 1, 4 do
			local cotentItem = self.contentList_[i]

			if cotentItem and i ~= index then
				self.contentList_[i]:SetActive(false)
				self.contentList_[i]:updatePage(false)
			end
		end
	end)
end

function BattlePassWindow:willClose()
	for _, item in pairs(self.contentList_) do
		if item then
			item:willClose()
		end
	end

	BattlePassWindow.super.willClose(self)
end

function BattlePassWindow:saveCache()
	self.hasClose_ = true
end

function BattlePassWindow:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= xyd.ActivityID.BATTLE_PASS then
		return
	end

	xyd.models.activity:getBattlePassData():updatePaidRecord({
		id = giftBagID
	})

	if self.contentList_[1] then
		self.contentList_[1]:updatePage(true)
	end
end

return BattlePassWindow
