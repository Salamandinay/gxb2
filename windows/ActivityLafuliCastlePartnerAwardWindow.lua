local BaseWindow = import(".BaseWindow")
local ActivityLafuliCastlePartnerAwardWindow = class("ActivityLafuliCastlePartnerAwardWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")
local activityID = xyd.ActivityID.ACTIVITY_LAFULI_CASTLE
local dropBoxID = xyd.tables.miscTable:split2Cost("activity_lflcastle_dropbox", "value", "|")
local energyNeed = xyd.tables.miscTable:getNumber("activity_lflcastle_energy", "value")

function ActivityLafuliCastlePartnerAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(activityID)
	self.curFilter = tonumber(xyd.db.misc:getValue("activity_lafuli_castle_partner_award_filter")) or 1
	self.items = {}
	self.icons = {}
	self.dropBoxData = {}
	self.num = 1
end

function ActivityLafuliCastlePartnerAwardWindow:initWindow()
	self:getUIComponent()
	ActivityLafuliCastlePartnerAwardWindow.super.initWindow(self)
	self:initDropBoxData()
	self:initUIComponent()
	self:register()
end

function ActivityLafuliCastlePartnerAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.helpBtn = groupAction:NodeByName("helpBtn").gameObject
	local groupMain = groupAction:NodeByName("groupMain").gameObject
	self.labelTip = groupMain:ComponentByName("labelTip", typeof(UILabel))
	local groupTop = groupMain:ComponentByName("groupTop", typeof(UISprite))
	self.scroller = groupTop:ComponentByName("scroller", typeof(UIScrollView))
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.groupFilter = groupTop:NodeByName("groupFilter").gameObject

	for i = 1, 4 do
		self["filter" .. i] = self.groupFilter:NodeByName("filter" .. i).gameObject
		self["filterChosen" .. i] = self["filter" .. i]:NodeByName("chosen").gameObject
	end

	local groupBottom = groupMain:ComponentByName("groupBottom", typeof(UISprite))
	self.progressBar = groupBottom:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressImg = self.progressBar:ComponentByName("progressImg", typeof(UISprite))
	self.progressNum = self.progressBar:ComponentByName("progressNum", typeof(UILabel))
	self.labelTip2 = groupBottom:ComponentByName("labelTip", typeof(UILabel))
	self.selectNumNode = groupMain:NodeByName("selectNumNode").gameObject
	self.btnAward = groupMain:NodeByName("btnAward").gameObject
	self.labelAward = self.btnAward:ComponentByName("labelAward", typeof(UILabel))
	self.itemCell = winTrans:NodeByName("itemCell").gameObject
end

function ActivityLafuliCastlePartnerAwardWindow:initDropBoxData()
	for i = 1, 4 do
		local info = xyd.tables.dropboxShowTable:getIdsByBoxId(dropBoxID[i])
		local all_proba = info.all_weight
		local list = info.list
		local collect = {}

		for j = 1, #list do
			local table_id = list[j]
			local weight = xyd.tables.dropboxShowTable:getWeight(table_id)
			local award = xyd.tables.dropboxShowTable:getItem(table_id)
			local proba = xyd.tables.dropboxShowTable:getWeight(table_id)
			local show_proba = math.ceil(proba * 1000000 / all_proba)
			show_proba = show_proba / 10000

			table.insert(collect, {
				award = award,
				probability = show_proba
			})
		end

		table.sort(collect, function (a, b)
			return a.probability < b.probability
		end)
		table.insert(self.dropBoxData, collect)
	end
end

function ActivityLafuliCastlePartnerAwardWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_LAFULI_CASTLE_TEXT05")
	self.labelTip.text = __("ACTIVITY_LAFULI_CASTLE_TEXT04")
	self.labelTip2.text = __("ACTIVITY_LAFULI_CASTLE_TEXT03", energyNeed)
	self.labelAward.text = __("GET2")
	self.selectNum = SelectNum.new(self.selectNumNode, "lafuli")

	self:updateDropBox()
	self:updateState()

	if xyd.Global.lang == "zh_tw" then
		self.progressBar:Y(22)

		self.labelTip2.spacingY = 3

		self.labelTip2:Y(-15)
	end

	if xyd.Global.lang == "ja_jp" then
		self.labelTip2.spacingY = 3
	end
end

function ActivityLafuliCastlePartnerAwardWindow:updateDropBox()
	local datas = self.dropBoxData[self.curFilter]

	for i = 1, #datas do
		if not self.items[i] then
			local go = NGUITools.AddChild(self.groupItem, self.itemCell)
			local iconNode = go:NodeByName("icon").gameObject
			local probabilityLabel = go:ComponentByName("probabilityLabel", typeof(UILabel))
			local icon = xyd.getItemIcon({
				show_has_num = true,
				showGetWays = false,
				itemID = datas[i].award[1],
				num = datas[i].award[2],
				uiRoot = iconNode,
				dragScrollView = self.scroller,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
			probabilityLabel.text = tostring(datas[i].probability) .. "%"
			self.items[i] = go
			self.icons[i] = icon
		else
			self.items[i]:SetActive(true)

			local probabilityLabel = self.items[i]:ComponentByName("probabilityLabel", typeof(UILabel))

			self.icons[i]:setInfo({
				show_has_num = true,
				showGetWays = false,
				itemID = datas[i].award[1],
				num = datas[i].award[2],
				dragScrollView = self.scroller,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			probabilityLabel.text = tostring(datas[i].probability) .. "%"
		end
	end

	for i = #datas + 1, #self.items do
		self.items[i]:SetActive(false)
	end

	self.groupItem:GetComponent(typeof(UIGrid)):Reposition()
	self.scroller:ResetPosition()

	for i = 1, 4 do
		if i == self.curFilter then
			self["filterChosen" .. i]:SetActive(true)
		else
			self["filterChosen" .. i]:SetActive(false)
		end
	end
end

function ActivityLafuliCastlePartnerAwardWindow:updateState()
	self.progressNum.text = self.activityData.detail.energy .. "/" .. energyNeed
	self.progressBar.value = math.min(self.activityData.detail.energy, energyNeed) / energyNeed

	if energyNeed <= self.activityData.detail.energy then
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_lafuli_castle_jdt4")
	else
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_lafuli_castle_jdt3")
	end

	self.selectNum:setInfo({
		curNum = 1,
		maxNum = math.floor(self.activityData.detail.energy / energyNeed),
		callback = function (num)
			self.num = num
		end,
		maxCallback = function ()
			xyd.alertTips(__("ACTIVITY_LAFULI_CASTLE_TEXT13"))
		end
	})

	if energyNeed <= self.activityData.detail.energy then
		xyd.setEnabled(self.btnAward.gameObject, true)
	else
		xyd.setEnabled(self.btnAward.gameObject, false)
	end
end

function ActivityLafuliCastlePartnerAwardWindow:register()
	ActivityLafuliCastlePartnerAwardWindow.super.register(self)

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_LAFULI_CASTLE_HELP02"
		})
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
		if self.num <= 0 then
			return
		end

		if self.activityData.detail.energy < energyNeed * self.num then
			return
		end

		xyd.alertYesNo(__("ACTIVITY_LAFULI_CASTLE_TEXT14", __("GROUP_" .. self.curFilter), self.num), function (yes)
			if yes then
				local params = {
					type = 4,
					index = self.curFilter,
					num = self.num
				}

				self.activityData:sendReq(params)
			end
		end)
	end

	for i = 1, 4 do
		UIEventListener.Get(self["filter" .. i]).onClick = function ()
			if self.curFilter == i then
				return
			end

			self.curFilter = i

			xyd.db.misc:setValue({
				key = "activity_lafuli_castle_partner_award_filter",
				value = i
			})
			self:updateDropBox()
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateState))
end

return ActivityLafuliCastlePartnerAwardWindow
