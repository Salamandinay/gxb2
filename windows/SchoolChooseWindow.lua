local BaseShop = import(".BaseWindow")
local SchoolChooseWindow = class("SchoolChooseWindow", BaseShop)
local WindowTop = import("app.components.WindowTop")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local ItemGroupNum = 3
local textConfig = {
	btnMarket = {
		window = "shop_map_window",
		icon = "market_text"
	},
	btnGamble = {
		icon = "gamble_text",
		window = "gamble_window",
		funID = xyd.FunctionID.GAMBLE
	},
	btnTavern = {
		icon = "tavern_text",
		window = "tavern_window",
		funID = xyd.FunctionID.TAVERN
	},
	btnTransfer = {
		window = "altar_window",
		icon = "transfer_text"
	},
	btnGraduate = {
		window = "shenxue_window",
		icon = "graduate_text"
	},
	btnEnroll = {
		icon = "enroll_text",
		window = "prophet_window",
		funID = xyd.FunctionID.PROPHET
	},
	btnDate = {
		window = "dates_list_window",
		icon = "date_text"
	},
	btnHouse = {
		window = "house_window",
		icon = "house_text"
	},
	btnDress = {
		icon = "dress_text",
		window = "dress_main_window",
		funID = xyd.FunctionID.DRESS
	},
	btnDressBuy = {
		icon = "dress_buy_text",
		window = "dress_summon_window",
		funID = xyd.FunctionID.DRESS_BUY
	},
	btnDressShow = {
		icon = "dress_show_entrace",
		window = "dress_show_entrance_window",
		funID = xyd.FunctionID.DRESS_SHOW
	},
	btnSkinCollection = {
		icon = "zhaoxing_text",
		window = "collection_skin_window",
		params = {
			fromSchoolChoose = true
		},
		funID = xyd.FunctionID.SKIN_COLLECTION
	}
}

function SchoolChooseWindow:ctor(name, params)
	SchoolChooseWindow.super.ctor(self, name, params)

	self.pageBtnList_1 = {}
	self.pageBtnList_2 = {}
	self.pageBtnList_3 = {}
	self.pageBtnList_4 = {}
end

function SchoolChooseWindow:initWindow()
	SchoolChooseWindow.super.initWindow(self)
	xyd.models.collection:reqCollectionInfo()
	self:getUIComponent()
	self:layout()
	self:register()
end

function SchoolChooseWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.content1 = winTrans:NodeByName("content").gameObject
	self.contentPart1_ = self.content1:ComponentByName("contentOfPage1", typeof(UIWidget))
	self.contentPart2_ = self.content1:ComponentByName("contentOfPage2", typeof(UIWidget))
	self.content2 = winTrans:NodeByName("content_2").gameObject
	self.contentPart3_ = self.content2:ComponentByName("contentOfPage1", typeof(UIWidget))
	self.contentPart4_ = self.content2:ComponentByName("contentOfPage2", typeof(UIWidget))
	self.btnDress = self.content2:NodeByName("contentOfPage1/btnDress/pageIcon").gameObject
	self.btnDressBuy = self.content2:NodeByName("contentOfPage2/btnDressBuy/pageIcon").gameObject
	self.btnDressShow = self.content2:NodeByName("contentOfPage1/btnDressShow/pageIcon").gameObject
	self.btnSkinCollection = self.content2:NodeByName("contentOfPage2/btnSkinCollection/pageIcon").gameObject
	self.shushiBtn_ = self.content2:NodeByName("contentOfPage2/btnHouse/shushiBtn").gameObject
	self.shushiBtnLabel_ = self.shushiBtn_:ComponentByName("label", typeof(UILabel))
	self.nav = winTrans:NodeByName("nav").gameObject
	self.tab2 = self.nav:NodeByName("tab_2").gameObject
end

function SchoolChooseWindow:layout()
	self:initContent()
	self:initTopGroup()

	self.tabBar = CommonTabBar.new(self.nav, 2, function (index)
		self:changeTopTap(index)
	end)

	self.tabBar:setTexts({
		__("STUDY"),
		__("LIFE_2")
	})

	self.house = xyd.models.house

	if not self.house:reqHouseInfo() then
		self:updateComfortNum()
	end
end

function SchoolChooseWindow:updateComfortNum()
	local comfortNum = xyd.models.house:getComfortNum()

	if not comfortNum or comfortNum < 50 then
		self.shushiBtn_:SetActive(false)
	else
		self.shushiBtn_:SetActive(true)
	end

	self.shushiBtnLabel_.text = comfortNum
end

function SchoolChooseWindow:register()
	SchoolChooseWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.HOUSE_GET_INFO, handler(self, self.updateComfortNum))
	self.eventProxy_:addEventListener(xyd.event.HOUSE_GET_AWARDS, handler(self, self.onGetAward))

	UIEventListener.Get(self.shushiBtn_).onClick = handler(self, self.onClickShushi)
end

function SchoolChooseWindow:onClickShushi()
	if self:checkCanAwardHouse() then
		self.house:reqGetAwards()
	else
		xyd.alertTips(__("HOUSE_AWARD_TIPS"))
	end
end

function SchoolChooseWindow:onGetAward(event)
	local win = xyd.WindowManager.get():getWindow("house_window")

	if not win then
		xyd.itemFloat(event.data.hang_items)
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.HOUSE, false)
	self.house:setHangRedPoint(false)
end

function SchoolChooseWindow:checkCanAwardHouse()
	local HouseAwardTable = xyd.tables.houseAwardTable
	local comfortNum = self.house:getComfortNum()
	local id = HouseAwardTable:getIdByComfort(comfortNum)
	local pAwardItems = HouseAwardTable:award(id)
	local hangTime = self.house:getHangTime()
	local hangUpdateTime = self.house:getHangUpdateTime()

	if hangUpdateTime == 0 then
		hangUpdateTime = hangTime
	end

	local addRate = 0
	local maxHangTime = xyd.tables.miscTable:getNumber("hang_up_time_max", "value")

	if hangTime > 0 then
		local serverTime = xyd.getServerTime()
		local trueMaxHangTime = hangTime + maxHangTime

		if serverTime < trueMaxHangTime then
			trueMaxHangTime = serverTime
		end

		local trueHangTime = trueMaxHangTime - hangUpdateTime

		if maxHangTime < trueHangTime then
			trueHangTime = maxHangTime
		elseif trueHangTime < 0 then
			trueHangTime = 0
		end

		addRate = math.floor(trueHangTime / xyd.HANG_AWARD_TIME)

		if addRate > 0 then
			addRate = addRate - 1
		end
	end

	local canGetAward = false

	for i = 1, #pAwardItems do
		local item = pAwardItems[i]
		local recordItem = self.house:getAwardItem(item[1])
		local recordNum = 0

		if recordItem then
			recordNum = tonumber(recordItem.item_num)
		end

		local awardNum = math.floor(item[2] * addRate + recordNum)

		if awardNum > 0 then
			canGetAward = true
		end
	end

	return canGetAward
end

function SchoolChooseWindow:changeTopTap(index)
	xyd.SoundManager.get():playSound(xyd.SoundID.TAB_LIST_TO_BOTTOM)

	if index == 1 then
		self.content1:SetActive(true)
		self.content2:SetActive(false)
	else
		self.content1:SetActive(false)
		self.content2:SetActive(true)
	end

	self:playAnimation(index)
end

function SchoolChooseWindow:playAnimation(index)
	local list = {
		self["pageBtnList_" .. index * 2 - 1],
		self["pageBtnList_" .. index * 2]
	}

	for i = 1, ItemGroupNum do
		for j = 1, 2 do
			list[j][i]:GetComponent(typeof(UIWidget)).alpha = 0.01
		end
	end

	local sequence = self:getSequence()

	for i = 1, ItemGroupNum do
		sequence:InsertCallback(0.06 * (i - 1), function ()
			self:itemAnimation({
				list[1][i],
				list[2][i]
			})
		end)
	end

	sequence:AppendCallback(function ()
		sequence:Kill(false)

		sequence = nil
	end)
end

function SchoolChooseWindow:itemAnimation(list)
	local sequence = self:getSequence()

	for j = 1, 2 do
		local item = list[j]
		local widget = item:GetComponent(typeof(UIWidget))
		local originY = item.transform.localPosition.y

		item:Y(originY + 30)
		sequence:Join(item.transform:DOLocalMoveY(originY, 0.2))

		local getter, setter = xyd.getTweenAlphaGeterSeter(widget)

		sequence:Join(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.2))
	end

	sequence:AppendCallback(function ()
		sequence:Kill(false)

		sequence = nil
	end)
end

function SchoolChooseWindow:initTopGroup()
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

function SchoolChooseWindow:initContent()
	self:initContent1()
	self:initContent2()
	self:initContent3()
	self:initContent4()
end

function SchoolChooseWindow:initContent1()
	for i = 0, ItemGroupNum - 1 do
		local target = self.contentPart1_.transform:GetChild(i).gameObject
		local targetName = target.name
		local textIcon = target.transform:ComponentByName("textIcon", typeof(UISprite))
		local pageIcon = target.transform:ComponentByName("pageIcon", typeof(UISprite))
		local textIconName = textConfig[targetName].icon .. "_" .. xyd.Global.lang

		xyd.setUISpriteAsync(textIcon, nil, textIconName, function ()
			textIcon:MakePixelPerfect()
		end, nil)

		if textConfig[targetName].window then
			UIEventListener.Get(pageIcon.gameObject).onClick = function ()
				self:checkAndOpen(targetName)
			end
		end

		table.insert(self.pageBtnList_1, target)

		local funID = textConfig[targetName].funID

		if funID and not xyd.checkFunctionOpen(funID, true) then
			target.transform:ComponentByName("imgMask", typeof(UISprite)):SetActive(true)
		end
	end

	self.alertImg1 = self.window_.transform:NodeByName("content/contentOfPage1/btnMarket/redPoint").gameObject
	self.alertImg2 = self.window_.transform:NodeByName("content/contentOfPage1/btnTavern/redPoint").gameObject

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.COFFEE_SHOP,
		xyd.RedMarkType.SKIN_SHOP,
		xyd.RedMarkType.ARENA_SHOP
	}, self.alertImg1)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.TAVERN, self.alertImg2)

	self.btnTavern_upIcon = self.window_.transform:NodeByName("content/contentOfPage1/btnTavern/upIcon").gameObject

	self:updateUpIcon()
end

function SchoolChooseWindow:initContent2()
	for i = 0, ItemGroupNum - 1 do
		local target = self.contentPart2_.transform:GetChild(i).gameObject
		local targetName = target.name
		local textIcon = target.transform:ComponentByName("textIcon", typeof(UISprite))
		local pageIcon = target.transform:ComponentByName("pageIcon", typeof(UISprite))
		local textIconName = textConfig[targetName].icon .. "_" .. xyd.Global.lang

		xyd.setUISpriteAsync(textIcon, nil, textIconName, function ()
			textIcon:MakePixelPerfect()
		end, nil)

		local funID = textConfig[targetName].funID

		if funID and not xyd.checkFunctionOpen(funID, true) then
			target.transform:ComponentByName("imgMask", typeof(UISprite)):SetActive(true)
		end

		if textConfig[targetName].window then
			UIEventListener.Get(pageIcon.gameObject).onClick = function ()
				self:checkAndOpen(targetName)
			end
		end

		table.insert(self.pageBtnList_2, target)
	end

	self.btnDressShow_red = self.window_.transform:NodeByName("content_2/contentOfPage1/btnDressShow/redPoint").gameObject

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.DRESS_SHOW, self.btnDressShow_red)

	self.btnDress_red = self.window_.transform:NodeByName("content_2/contentOfPage1/btnDress/redPoint").gameObject

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.DRESS_ITEM_CAN_UP
	}, self.btnDress_red)
end

function SchoolChooseWindow:initContent3()
	for i = 0, ItemGroupNum - 1 do
		local target = self.contentPart3_.transform:GetChild(i).gameObject
		local targetName = target.name
		local textIcon = target.transform:ComponentByName("textIcon", typeof(UISprite))
		local pageIcon = target.transform:ComponentByName("pageIcon", typeof(UISprite))
		local textIconName = textConfig[targetName].icon .. "_" .. xyd.Global.lang

		xyd.setUISpriteAsync(textIcon, nil, textIconName, function ()
			textIcon:MakePixelPerfect()
		end, nil)

		if textConfig[targetName].window then
			UIEventListener.Get(pageIcon.gameObject).onClick = function ()
				self:checkAndOpen(targetName)
			end
		end

		table.insert(self.pageBtnList_3, target)

		local funID = textConfig[targetName].funID

		if funID and not xyd.checkFunctionOpen(funID, true) then
			target.transform:ComponentByName("imgMask", typeof(UISprite)):SetActive(true)
		end
	end
end

function SchoolChooseWindow:initContent4()
	for i = 0, ItemGroupNum - 1 do
		local target = self.contentPart4_.transform:GetChild(i).gameObject
		local targetName = target.name
		local textIcon = target.transform:ComponentByName("textIcon", typeof(UISprite))
		local pageIcon = target.transform:ComponentByName("pageIcon", typeof(UISprite))
		local textIconName = textConfig[targetName].icon .. "_" .. xyd.Global.lang

		xyd.setUISpriteAsync(textIcon, nil, textIconName, function ()
			textIcon:MakePixelPerfect()
		end, nil)

		local funID = textConfig[targetName].funID

		if funID and not xyd.checkFunctionOpen(funID, true) then
			target.transform:ComponentByName("imgMask", typeof(UISprite)):SetActive(true)
		end

		if textConfig[targetName].window then
			UIEventListener.Get(pageIcon.gameObject).onClick = function ()
				self:checkAndOpen(targetName)
			end
		end

		table.insert(self.pageBtnList_4, target)
	end

	local navRed = self.nav:NodeByName("tab_2/redPoint")
	local houseRed = self.contentPart4_:NodeByName("btnHouse/redPoint").gameObject
	local skinRed = self.contentPart4_:NodeByName("btnSkinCollection/redPoint").gameObject

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.HOUSE,
		xyd.RedMarkType.DRESS_ITEM_CAN_UP,
		xyd.RedMarkType.SKIN_LEVEL_CAN_UP
	}, navRed)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.HOUSE
	}, houseRed)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.SKIN_LEVEL_CAN_UP
	}, skinRed)
end

function SchoolChooseWindow:updateUpIcon()
	if xyd.models.activity:isResidentReturnAddTime() then
		self.btnTavern_upIcon:SetActive(xyd.models.activity:isResidentReturnAddTime())

		local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.WORKING)

		xyd.setUISpriteAsync(self.btnTavern_upIcon.gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_" .. return_multiple, nil, , )
	else
		self.btnTavern_upIcon:SetActive(false)
	end
end

function SchoolChooseWindow:checkAndOpen(targetName)
	local funID = textConfig[targetName].funID
	local wndName = textConfig[targetName].window
	local params = textConfig[targetName].params or {}

	if funID then
		if funID == xyd.FunctionID.DRESS_BUY and not xyd.models.dress:isfunctionOpen() then
			xyd.showToast(__("NEW_FUNCTION_TIP"))

			return
		end

		if funID == xyd.FunctionID.DRESS_BUY and not xyd.models.dress:isfunctionOpen() then
			xyd.showToast(__("NEW_FUNCTION_TIP"))

			return
		end

		if funID == xyd.FunctionID.SKIN_COLLECTION then
			local ids = xyd.models.collection:getIdsByType(xyd.CollectionType.SKIN)

			dump(ids)

			if ids and #ids < 3 then
				xyd.showToast(__("COLLECTION_SKIN_UNLOCK_TEXT", 3 - #ids))

				return
			end
		end

		if not xyd.checkFunctionOpen(funID) then
			return
		end
	end

	xyd.SoundManager.get():playSound("2006")

	if wndName == "dress_summon_window" then
		local openTime = xyd.tables.miscTable:getVal("dress_gacha_start_time")

		if openTime and xyd.getServerTime() < tonumber(openTime) then
			xyd.alertTips(__("DRESS_GACHA_OPEN_TIME", xyd.getRoughDisplayTime(tonumber(openTime) - xyd.getServerTime())))

			return
		end
	end

	xyd.WindowManager.get():openWindow(wndName, params)
end

function SchoolChooseWindow:iosTestChangeUI()
	local winTrans = self.window_.transform

	xyd.setUITexture(winTrans:ComponentByName("bg", typeof(UITexture)), "Textures/texture_ios/bg_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("content/contentOfPage2/btnTransfer/pageIcon", typeof(UISprite)), nil, "btn_transfer_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("content/contentOfPage2/btnSkinCollection/pageIcon", typeof(UISprite)), nil, "btn_transfer_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("content/contentOfPage2/btnGraduate/pageIcon", typeof(UISprite)), nil, "btn_graduate_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("content/contentOfPage2/btnEnroll/pageIcon", typeof(UISprite)), nil, "btn_enroll_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("content/contentOfPage1/btnMarket/pageIcon", typeof(UISprite)), nil, "btn_market_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("content/contentOfPage1/btnGamble/pageIcon", typeof(UISprite)), nil, "btn_gamble_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("content/contentOfPage1/btnTavern/pageIcon", typeof(UISprite)), nil, "btn_tavern_ios_test")
end

return SchoolChooseWindow
