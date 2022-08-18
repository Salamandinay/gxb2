local MainMap = xyd.getMapInstanceByType(xyd.GameMapType.MAIN)
local LARGE_BTN_IMG_NAME = {
	[xyd.ActivityID.ICE_SECRET] = "icon_ice_2",
	[xyd.ActivityID.RETURN] = "icon_return_player",
	[xyd.ActivityID.FAIRY_TALE] = "icon_fairy_tale",
	[xyd.ActivityID.ENTRANCE_TEST] = "icon_entrance_test",
	[xyd.ActivityID.SPORTS] = "icon_sports_icon",
	[xyd.ActivityID.TIME_LIMIT_CALL] = "activity_time_limit_call_png",
	[xyd.ActivityID.ACTIVITY_YEAR_FUND] = "activity_year_fund_main",
	[xyd.ActivityID.ACTIVITY_NEWBEE_FUND] = "activity_newbee_fund_popup_icon",
	[xyd.ActivityID.ACTIVITY_BEACH_SUMMER] = "activity_beach_island_entrer_icon",
	[xyd.ActivityID.ARCTIC_EXPEDITION] = "arctic_expedition_icon"
}
local LARGE_BTN_LABEL_STROKE_COLOR = {
	[xyd.ActivityID.ICE_SECRET] = Color.New2(3341074943.0),
	[xyd.ActivityID.RETURN] = Color.New2(563252991),
	[xyd.ActivityID.FAIRY_TALE] = Color.New2(3514841599.0),
	[xyd.ActivityID.ENTRANCE_TEST] = Color.New2(1984660735),
	[xyd.ActivityID.SPORTS] = Color.New2(1905404671),
	[xyd.ActivityID.TIME_LIMIT_CALL] = Color.New2(2387223039.0),
	[xyd.ActivityID.ACTIVITY_YEAR_FUND] = Color.New2(3613720831.0),
	[xyd.ActivityID.ACTIVITY_NEWBEE_FUND] = Color.New2(3613720831.0),
	[xyd.ActivityID.ACTIVITY_BEACH_SUMMER] = Color.New2(1984660735),
	[xyd.ActivityID.ARCTIC_EXPEDITION] = Color.New2(1984660735)
}
local LARGE_BTN_LABEL_TEXT_COLOR = {
	[xyd.ActivityID.TIME_LIMIT_CALL] = Color.New2(4227377407.0)
}
local PngNum = require("app.components.PngNum")
local CountDown = import("app.components.CountDown")
local MainBottomBtn = class("MainBottomBtn")

function MainBottomBtn:ctor(goItem, id)
	self.trans = {
		"BOTTOM_BTN_LABEL_1",
		"BOTTOM_BTN_LABEL_2",
		"BOTTOM_BTN_LABEL_4",
		"BOTTOM_BTN_LABEL_5",
		"MAINWIN_RIGHT_4",
		"SETTING"
	}
	self.id = id
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.bgOnImg_ = transGo:ComponentByName("bg_on_img", typeof(UISprite))
	self.iconImg_ = transGo:ComponentByName("icon_img", typeof(UISprite))
	self.iconGo_ = transGo:Find("icon_img").gameObject
	self.btnAlertImg_ = transGo:ComponentByName("btn_alert_img", typeof(UISprite))
	self.btnLabel_ = transGo:ComponentByName("btn_label", typeof(UILabel))
	self.btnLabel_.text = __(self.trans[id])

	self.btnAlertImg_:SetActive(false)

	self.tipsImg = transGo:ComponentByName("tipsImg", typeof(UISprite))

	if UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.ANDROID_1_5_138) >= 0 or UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.IOS_71_3_204) >= 0 or UNITY_EDITOR then
		self.soundComponent = transGo:GetComponent(typeof(UIPlaySound))
		self.soundComponent.enabled = false
	end

	self:change(0)

	if id == 4 then
		self:checkTips()
	end
end

function MainBottomBtn:checkTips()
	local flag = false
	local img = "wish_up_tips"
	local wishData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)
	local summonGiftBagData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_SUMMON_GIFTBAG)

	if wishData and xyd.getServerTime() < wishData:getEndTime() then
		flag = true
		img = xyd.checkCondition(xyd.Global.lang ~= "ja_jp", "wish_up_tips", "wish_up_tips_ja_jp")
	elseif summonGiftBagData and xyd.getServerTime() < summonGiftBagData:getEndTime() then
		flag = true
		img = xyd.checkCondition(xyd.Global.lang ~= "ja_jp", "summon_up_v3", "summon_up_v3_ja_jp")
	end

	if flag and xyd.GuideController.get():isGuideComplete() then
		xyd.setUISpriteAsync(self.tipsImg, nil, img, handler(self, function ()
			self.tipsImg:MakePixelPerfect()
			self.tipsImg:SetActive(true)
			self.tipsImg:SetLocalPosition(11, 60, 0)
		end, nil))

		local data = wishData or summonGiftBagData

		xyd.addGlobalTimer(handler(self, function ()
			self.tipsImg:SetActive(false)
		end), data:getEndTime() - xyd.getServerTime(), 1)
	end
end

function MainBottomBtn:getIconGo()
	return self.iconGo_
end

function MainBottomBtn:getGoItem()
	return self.goItem_
end

function MainBottomBtn:getRedPoint()
	return self.btnAlertImg_
end

function MainBottomBtn:change(status)
	if status == 0 then
		self.btnLabel_.color = Color.New2(960513791)
		self.btnLabel_.effectColor = Color.New2(4294967295.0)

		if xyd.isIosTest() then
			xyd.setUISprite(self.iconImg_, nil, "bottom_icon_" .. self.id .. "_v3_ios_test")
		else
			local imgName = "bottom_icon_" .. self.id .. "_v3"

			if xyd.isH5() then
				imgName = imgName .. "_h5"
			end

			xyd.setUISprite(self.iconImg_, nil, imgName)
		end

		self.bgOnImg_.gameObject:SetActive(false)
	else
		self.btnLabel_.color = Color.New2(4294967295.0)
		self.btnLabel_.effectColor = Color.New2(4150425)

		if xyd.isIosTest() then
			xyd.setUISprite(self.iconImg_, nil, "bottom_icon_" .. self.id .. "_o_v3_ios_test")
		else
			local imgName = "bottom_icon_" .. self.id .. "_o_v3"

			if xyd.isH5() then
				imgName = imgName .. "_h5"
			end

			xyd.setUISprite(self.iconImg_, nil, imgName)
		end

		self.bgOnImg_.gameObject:SetActive(true)
	end
end

local MainTopRightBtn = class("MainTopRightBtn")

function MainTopRightBtn:ctor(goItem, id)
	self.trans = {
		label = {
			"FRIEND",
			"BP_TITLE",
			"QUIZ",
			"PET",
			"TRAVEL_TITLE",
			"STARRY_ALTAR",
			"GROWTH_DIARY"
		},
		img = {
			"right_friend_icon_v3",
			"right_battlepass_icon_v4",
			"right_quiz_icon_v3",
			"left_pet_icon",
			"right_explore_icon",
			"right_starry_altar_icon",
			"growth_diary_icon"
		},
		funcId = {
			xyd.FunctionID.FRIEND,
			xyd.FunctionID.MISSION,
			xyd.FunctionID.QUIZ,
			xyd.FunctionID.PET,
			xyd.FunctionID.EXPLORE,
			xyd.FunctionID.STARRY_ALTAR,
			xyd.FunctionID.GROWTH_DIARY
		}
	}
	self.id = id
	self.goItem_ = goItem
	self.name_ = self.trans.label[id]
	local transGo = goItem.transform
	self.transGo_sprite = transGo:GetComponent(typeof(UISprite))
	self.transGo_UIWidget = transGo:GetComponent(typeof(UIWidget))
	self.trBtnImg_ = transGo:ComponentByName("tr_btn_img", typeof(UISprite))
	self.trBtnLabel_ = transGo:ComponentByName("tr_btn_label", typeof(UILabel))
	self.btnAlertImg_ = transGo:ComponentByName("red_point", typeof(UISprite))
	self.upIcon = transGo:NodeByName("upIcon").gameObject

	if UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.ANDROID_1_5_138) >= 0 or UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.IOS_71_3_204) >= 0 or UNITY_EDITOR then
		self.soundComponent = transGo:GetComponent(typeof(UIPlaySound))
	end

	self.trBtnImg_:SetActive(false)

	local imgName = self.trans.img[id]

	if xyd.isH5() then
		imgName = "left_btn_bg_v3"

		xyd.setUISprite(self.trBtnImg_, nil, self.trans.img[id] .. "_h5", function ()
			self.trBtnImg_:MakePixelPerfect()
		end)
		self.trBtnImg_:SetActive(true)

		self.transGo_UIWidget.width = 80
		self.transGo_UIWidget.height = 83
	end

	xyd.setUISprite(self.transGo_sprite, nil, imgName)

	self.trBtnLabel_.text = __(self.trans.label[id])

	self.btnAlertImg_.gameObject:SetActive(false)

	local openFuncsIndex = xyd.models.functionOpen:getOpenFuncIndex()

	if self.trans.funcId[id] == 0 or openFuncsIndex[tostring(self.trans.funcId[id])] then
		self.goItem_:SetActive(true)
	else
		self.goItem_:SetActive(false)
	end

	print(self.trans.funcId[id])

	if self.trans.funcId[id] == xyd.FunctionID.GROWTH_DIARY and xyd.models.growthDiary:checkFinish() then
		self.goItem_:SetActive(false)
	end

	if self.trans.funcId[id] == xyd.FunctionID.GROWTH_DIARY and xyd.models.growthDiary:checkFinish() then
		self.goItem_:SetActive(false)
	end

	self:checkGalaxy()

	if self.id == 4 then
		self:updateUpIcon()
	end

	self:updateSound()
end

function MainTopRightBtn:updateSound()
	if self.trans.funcId[self.id] == xyd.FunctionID.QUIZ and self.soundComponent then
		self.soundComponent.tableId = 2122
	end
end

function MainTopRightBtn:checkGalaxy()
	if self.id == 6 then
		local openFuncsIndex = xyd.models.functionOpen:getOpenFuncIndex()
		local starryOpen = openFuncsIndex[tostring(xyd.FunctionID.STARRY_ALTAR)]
		local galaxyOpen = openFuncsIndex[tostring(xyd.FunctionID.GALAXY_TRIP)]
		galaxyOpen = galaxyOpen and xyd.models.galaxyTrip:getLeftTime() > 0

		if starryOpen and galaxyOpen then
			self.trBtnLabel_.text = __("GALAXY_TRIP_TEXT01")

			xyd.setUISprite(self.trBtnImg_, nil, "activity_galaxy_trip_mission_icon_xxzl_yd")
			self.goItem_:SetActive(true)
		elseif not galaxyOpen and starryOpen then
			self.trBtnLabel_.text = __(self.trans.label[self.id])
			local imgName = self.trans.img[self.id]

			xyd.setUISprite(self.trBtnImg_, nil, imgName)
			self.goItem_:SetActive(true)
		else
			self.goItem_:SetActive(false)
		end
	end
end

function MainTopRightBtn:updateUpIcon()
	if self.id == 3 then
		if xyd.models.activity:isResidentReturnAddTime() then
			self.upIcon:SetActive(xyd.models.activity:isResidentReturnAddTime())

			local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.DAILY_QUIZ)

			xyd.setUISpriteAsync(self.upIcon.gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_" .. return_multiple, nil, , )
		else
			self.upIcon:SetActive(xyd.getReturnBackIsDoubleTime() or xyd.getIsQuizDoubleDrop())
			xyd.setUISpriteAsync(self.upIcon.gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_2", nil, , )
		end

		if xyd.isH5() then
			self.upIcon:X(30)
			self.upIcon:Y(-3)
		end
	end
end

function MainTopRightBtn:levChange()
	local id = self.id

	if (self.trans.funcId[id] == 0 or xyd.checkFunctionOpen(self.trans.funcId[id], true)) and (xyd.Global.isReview ~= 1 or self.id ~= 2) then
		self.goItem_:SetActive(true)
	else
		self.goItem_:SetActive(false)
	end

	if self.trans.funcId[id] == xyd.FunctionID.GROWTH_DIARY and xyd.models.growthDiary:checkFinish() then
		self.goItem_:SetActive(false)
	end
end

function MainTopRightBtn:getGameObject()
	return self.goItem_
end

function MainTopRightBtn:setUISprite(spriteName)
	if xyd.isH5() then
		xyd.setUISprite(self.trBtnImg_, nil, spriteName .. "_h5")
		self.trBtnImg_:MakePixelPerfect()

		return
	end

	xyd.setUISprite(self.transGo_sprite, nil, spriteName)
end

function MainTopRightBtn:setLabel(label)
	self.trBtnLabel_.text = label
end

function MainTopRightBtn:getName()
	return self.name_
end

function MainTopRightBtn:getRedPoint()
	return self.btnAlertImg_
end

local MainUIActivityItem = class("MainUIActivityItem")

function MainUIActivityItem:ctor(goItem, itemdata, scrollerPanel)
	self.go = goItem
	self.redpoint = self.go:NodeByName("red_point").gameObject
	self.img = self.go:ComponentByName("e:image", typeof(UISprite))
	self.label = self.go:ComponentByName("label", typeof(UILabel))
	self.timeLabel = self.go:ComponentByName("timeLabel", typeof(UILabel))
	self.go.name = "MainUIActivityItem"
	self.defaultTextColor = Color.New2(4294967295.0)

	if xyd.isH5() then
		self.redpoint:SetLocalPosition(33, 39, 0)

		if self.big_con_up_effect == nil then
			self.big_con_effect_up = self.go:ComponentByName("effect_up", typeof(UITexture))
			self.big_con_up_effect = xyd.Spine.new(self.big_con_effect_up.gameObject)

			self.big_con_up_effect:setInfo("fx_act_icon_2", function ()
				self.big_con_up_effect:setRenderPanel(scrollerPanel)
				self.big_con_up_effect:play("texiao01", 0)
			end)
		end
	end

	if itemdata == nil then
		return
	end

	self:updateInfo(itemdata)
end

function MainUIActivityItem:getRedPoint()
	return self.redpoint
end

function MainUIActivityItem:getGo()
	return self.go
end

function MainUIActivityItem:updateInfo(itemdata)
	self.id = itemdata.activity_id
	self.isShowName = itemdata.isShowName or false
	self.isShowTime = itemdata.isShowTime or false

	if xyd.isH5() then
		LARGE_BTN_LABEL_STROKE_COLOR[self.id] = Color.New2(2387223039.0)
		LARGE_BTN_LABEL_TEXT_COLOR[self.id] = Color.New2(4227377407.0)
		self.defaultTextColor = Color.New2(4227377407.0)
	end

	self.label.effectColor = LARGE_BTN_LABEL_STROKE_COLOR[self.id]

	if LARGE_BTN_LABEL_TEXT_COLOR[self.id] then
		self.label.color = LARGE_BTN_LABEL_TEXT_COLOR[self.id]
	else
		self.label.color = self.defaultTextColor
	end

	if tolua.isnull(self.go) then
		return
	end

	UIEventListener.Get(self.go:NodeByName("e:image").gameObject).onClick = function ()
		MainMap:stopSound()

		local testParams = nil
		local params = xyd.tables.activityTable:getWindowParams(self.id)

		if params ~= nil then
			testParams = params.activity_ids
		end

		local actData = xyd.models.activity:getActivity(self.id)

		if actData and actData:getEndTime() - xyd.getServerTime() > 0 then
			local win_name = xyd.tables.activityTable:getWindowName(self.id)

			if win_name then
				if win_name == "activity_window" then
					xyd.WindowManager.get():openWindow("activity_window", {
						activity_type = xyd.tables.activityTable:getType(self.id),
						onlyShowList = testParams
					})
				elseif self.id == xyd.ActivityID.RETURN then
					print("actData.detail.role", actData.detail.role)

					if actData.detail.role == xyd.PlayerReturnType.RETURN then
						xyd.WindowManager.get():openWindow(win_name)
					elseif actData.detail.role == xyd.PlayerReturnType.ACTIVE then
						xyd.WindowManager.get():openWindow("activity_return_active_window", {})
					end
				elseif self.id == xyd.ActivityID.ENTRANCE_TEST then
					xyd.WindowManager.get():openWindow(win_name)
				else
					xyd.WindowManager.get():openWindow(win_name)
				end
			end
		else
			xyd.alertTips(__("ACTIVITY_END_YET"))
		end
	end

	if LARGE_BTN_IMG_NAME[self.id] ~= nil then
		if xyd.isH5() then
			local tableIcon = xyd.tables.activityTable:getIcon(self.id)

			if tableIcon then
				LARGE_BTN_IMG_NAME[self.id] = tableIcon
			end
		end

		xyd.setUISpriteAsync(self.img, nil, LARGE_BTN_IMG_NAME[self.id], function ()
			self.img:MakePixelPerfect()
		end)
	end

	if self.id == xyd.ActivityID.ACTIVITY_YEAR_FUND then
		local data = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_YEAR_FUND)

		if data.detail.charges[1].buy_times ~= 1 and data:getEndTime() - xyd.getServerTime() < xyd.TimePeriod.DAY_TIME then
			self.label:SetActive(false)
			self.timeLabel:SetActive(true)

			self.isShowName = false

			if not self.timer then
				self.timer = CountDown.new(self.timeLabel, {
					duration = data:getEndTime() - xyd.getServerTime()
				})
			else
				self.timer:setInfo({
					duration = data:getEndTime() - xyd.getServerTime()
				})
			end
		else
			self.timeLabel:SetActive(false)

			self.label.text = xyd.tables.activityTextTable:getTitle(self.id)
		end
	else
		self.timeLabel:SetActive(false)

		self.label.text = xyd.tables.activityTextTable:getTitle(self.id)
	end

	self.label.gameObject:SetActive(self.isShowName)
	self:updateRedMark()
end

function MainUIActivityItem:updateRedMark()
	local params = xyd.tables.activityTable:getWindowParams(self.id)

	if params and params.activity_ids then
		local showRedPoint = false

		for i, otherId in pairs(params.activity_ids) do
			local otherData = xyd.models.activity:getActivity(otherId)

			if otherData and otherData:getRedMarkState() == true then
				showRedPoint = true

				break
			end
		end

		self.redpoint:SetActive(showRedPoint)

		return
	end

	local commonData = xyd.models.activity:getActivity(self.id)

	if commonData then
		self.redpoint:SetActive(commonData:getRedMarkState())

		return
	end

	self.redpoint:SetActive(false)
end

local MainWindow = class("MainWindow", import(".BaseWindow"))
local selfPlayer = xyd.models.selfPlayer
local backpack = xyd.models.backpack
local ResItem = import("app.components.ResItem")
local PlayerIcon = import("app.components.PlayerIcon")
local PngNum = import("app.components.PngNum")
local Object = UnityEngine.Object
local json = require("cjson")
MainWindow.HideType = {
	KIND3 = 3,
	KIND4 = 4,
	KIND2 = 2,
	KIND5 = 5,
	KIND1 = 1,
	KIND6 = 6,
	KIND0 = 0,
	KIND7 = 7
}
MainWindow.AnimationShowState = {
	SHOWING = 1,
	HIDING = 2,
	NONE = 0
}
MainWindow.HideConf = {
	[MainWindow.HideType.KIND0] = {
		0,
		0,
		0,
		0,
		0
	},
	[MainWindow.HideType.KIND1] = {
		1,
		0,
		1,
		1,
		1
	},
	[MainWindow.HideType.KIND2] = {
		0,
		0,
		1,
		1,
		1
	},
	[MainWindow.HideType.KIND3] = {
		0,
		0,
		1,
		0,
		1
	},
	[MainWindow.HideType.KIND4] = {
		1,
		1,
		1,
		1,
		1
	},
	[MainWindow.HideType.KIND5] = {
		0,
		1,
		1,
		1,
		1
	},
	[MainWindow.HideType.KIND6] = {
		0,
		1,
		1,
		1,
		1
	},
	[MainWindow.HideType.KIND7] = {
		0,
		1,
		1,
		1,
		1
	}
}

function MainWindow:ctor(name, params)
	MainWindow.super.ctor(self, name, params)

	self.callback = nil

	if params.listener ~= nil then
		self.callback_ = params.listener
	end

	self.isShake = false
	self.currentIndex = 0
	self.bottomBtnList_ = {}
	self.trBtnList_ = {}
	self.rightSelectId = 0
	self.redIcons = {}
	self.isPlayAnimation = false
	self.isStart = true
	self.oldY = {}
	self.kaimenTimerIDList_ = {}
	self.storyBubbleOnceFinished = true
	self.hideStatus_ = {}
	self.firstLogin_ = true
	self.loadingTime_ = 0
	self.currentState = xyd.Global.lang
	self.playerIcon = nil
	self.onlineCountDown = nil
	self.vipPngNum = nil
	self.hand = nil
	self.isOnlyInitScrollerAct = true
	self.largeBtnArr = {}
	self.largeBtnItemArr = {}
	self.largeAutoMoveKey = -1
	self.isFirstTimerMoveLarge = true
	self.largePageBgArr = {}
	self.isFirstInitTempPos = true
	self.largeTempPos = 1
	self.largecurIndex = 1
	self.largewidthNum = 119
end

function MainWindow:initWindow()
	MainWindow.super.initWindow()

	local winTrans = self.window_.transform
	self.transTop = winTrans:Find("top_group")
	self.chartGroup = winTrans:Find("chart_group")
	self.bottomGroup = winTrans:Find("bottom_group")
	self.btnChat = self.chartGroup:NodeByName("btnChat").gameObject
	self.btnChat_redIcon = self.chartGroup:NodeByName("btnChat/redIcon").gameObject
	self.btnChat_redIcon2 = self.chartGroup:NodeByName("btnChat/redIcon2").gameObject
	self.btnChat_redIcon3 = self.chartGroup:NodeByName("btnChat/redIcon3").gameObject
	self.stageTouch = winTrans:NodeByName("stageTouch").gameObject
	UIEventListener.Get(self.stageTouch).onClick = handler(self, self.onThisTouch)
	self.transTopTween = self.transTop:Find("top_tween_group")
	local transTopL = self.transTopTween:Find("top_L_group")
	self.transTopL = self.transTopTween:Find("top_L_group")
	local transTopM = self.transTopTween:Find("top_M_group")
	self.transTopR = self.transTopTween:Find("top_R_group")
	self.transTopR_uiRect = self.transTopR:GetComponent(typeof(UIRect))
	self.leftUpCon = import("app.components.MainWindowLeftUpCon").new(self.transTopL.gameObject, {}, self)
	self.arrGroup = self.bottomGroup:NodeByName("arrGroup").gameObject
	self.partnerSwitchArrow1 = self.arrGroup:NodeByName("leftArr").gameObject
	self.partnerSwitchArrow2 = self.arrGroup:NodeByName("rightArr").gameObject
	UIEventListener.Get(self.partnerSwitchArrow1).onClick = handler(self, function ()
		self:partnerSwitch(-1)
	end)
	UIEventListener.Get(self.partnerSwitchArrow2).onClick = handler(self, function ()
		self:partnerSwitch(1)
	end)
	self.resGroup = transTopM:Find("res_group")
	self.mailBtn = transTopM:Find("mail_btn")
	self.mailBtn_red_point = self.mailBtn:NodeByName("red_point").gameObject
	self.gameAssistantBtn = transTopM:Find("game_assistant_btn")
	self.redIcons[xyd.RedMarkType.MAIL] = self.mailBtn_red_point
	self.transPlayerGroup = transTopM:Find("player_group")
	self.groupVip = self.transPlayerGroup:Find("vip_group")
	self.groupVip_bg = self.transPlayerGroup:Find("vip_group/bg")
	self.redIconVip = self.transPlayerGroup:Find("vip_group/redIconVip")
	self.groupVip_ = self.groupVip:NodeByName("vip_num").gameObject
	self.pageVipNum_ = PngNum.new(self.groupVip_)
	self.bottomBtnGroup = self.bottomGroup:Find("bottom_btn_group")
	self.midBtnGroup = self.bottomGroup:Find("mid_btn_group")
	self.schoolBtn = self.midBtnGroup:Find("school_btn")
	self.redPointSchool = self.schoolBtn:NodeByName("redPointSchool").gameObject
	self.arenaBtn = self.midBtnGroup:Find("arena_btn")
	self.redPointBattle = self.arenaBtn:NodeByName("redPointBattle").gameObject
	self.btnStory = self.midBtnGroup:Find("story_btn")
	self.dianjiGroup = self.btnStory:NodeByName("dianjiGroup").gameObject
	self.btnLimitDress = self.midBtnGroup:Find("limit_dress_btn")
	self.btnNotice = self.midBtnGroup:NodeByName("notice_btn").gameObject
	self.btnNoticeEffect = self.midBtnGroup:NodeByName("notice_btn/spineRoot").gameObject
	self.redPointStory = self.btnStory:NodeByName("redPointStory").gameObject
	self.upIcon = self.btnStory:NodeByName("upIcon").gameObject
	self.bottomBtn = self.bottomGroup:Find("bottom_btn")

	self.bottomBtn.gameObject:SetActive(false)

	self.topRightBtn = self.transTopTween:Find("top_right_btn")

	self.topRightBtn.gameObject:SetActive(false)

	self.storyBubble = self.btnStory:Find("story_bubble")
	self.storyBubble1 = self.storyBubble:Find("story_bubble1")
	self.storyBubble2 = self.storyBubble:Find("story_bubble2")
	self.storyLabel1 = self.storyBubble1:ComponentByName("story_label1", typeof(UILabel))
	self.storyLabel2 = self.storyBubble2:ComponentByName("story_label2", typeof(UILabel))

	self.storyBubble:SetActive(false)

	self.actGroup = transTopL:Find("actGroup")
	self.actGroup1 = self.actGroup:Find("actGroup1")
	self.actGroup2 = self.actGroup:Find("actGroup2")
	self.groupPush = transTopL:Find("groupPush")
	self.actGroup3 = transTopL:Find("groupPush/actGroup3")
	self.activityImg3 = self.actGroup3:Find("e:image").gameObject
	self.actGroupEffect5 = transTopL:Find("groupPush/actGroupEffect5").gameObject
	self.actGroupEffect6 = transTopL:Find("groupPush/actGroupEffect6").gameObject
	self.pushEndIcon = transTopL:ComponentByName("groupPush/actGroup3/endIcon", typeof(UISprite))
	self.pushCountDown = transTopL:ComponentByName("groupPush/pushCountDown", typeof(UILabel))
	self.activityImg1 = self.actGroup1:Find("icon").gameObject
	self.activityImg2 = self.actGroup2:Find("icon").gameObject
	self.actGroup1_label = self.actGroup1:ComponentByName("label", typeof(UILabel))
	self.actGroup2_label = self.actGroup2:ComponentByName("label", typeof(UILabel))
	self.actGroup1_red_point = self.actGroup1:Find("red_point").gameObject
	self.actGroup2_red_point = self.actGroup2:Find("red_point").gameObject
	self.largeBigConEg = transTopL:Find("largeBigCon").gameObject
	self.largeBigCon = NGUITools.AddChild(transTopL.gameObject, self.largeBigConEg.gameObject)
	self.largeBtnConScroller = self.largeBigCon.transform:Find("largeBtnConScroller").gameObject
	self.largeBtnConScroller_drag = self.largeBigCon:NodeByName("drag").gameObject
	self.largeBtnCon = self.largeBigCon.transform:Find("largeBtnConScroller/largeBtnCon").gameObject
	self.largeBtn_CenterOnChild = self.largeBtnCon:GetComponent(typeof(UICenterOnChild))
	self.largeBtnScroller_scrollView = self.largeBtnConScroller:GetComponent(typeof(UIScrollView))
	self.largeBtnScroller_scrollView.onDragMoving = handler(self, self.moveLargeCon)
	self.largeBtnScroller_scrollView.onDragFinished = handler(self, self.moveLargeConFinish)
	self.largeBtneg = transTopL:Find("largeBtneg").gameObject
	self.largeBtneg_widget = self.largeBtneg:GetComponent(typeof(UIWidget))
	self.largewidthNum = self.largeBtneg_widget.width
	self.largePageShowCon = self.largeBigCon.transform:Find("largePageShowCon").gameObject
	self.largePageBg = self.largeBigCon.transform:Find("largePageShowCon/largePageBg").gameObject
	self.largePageLight = self.largeBigCon.transform:Find("largePageShowCon/largePageLight").gameObject
	self.newbieCamp = self.actGroup:Find("actGroup3")
	self.newbieCampIcon = self.newbieCamp:Find("e:image")
	self.newbieCampLabel = self.newbieCamp:ComponentByName("label", typeof(UILabel))
	self.newbieRedPoint = self.newbieCamp:Find("red_point").gameObject
	self.redIcons[xyd.RedMarkType.NEWBIE_GUIDE] = self.newbieRedPoint
	local top_bg_imgName = "top_bg_r_v3"

	xyd.setUISprite(self.top_bg, nil, top_bg_imgName)
	self:initKaiXue()
	self:initLayout()
	self:registerEvent()
	self:initGiftbagPush()
	self:initPartnerSound()
	self:initActivityBtn()
	self:initChat()
	self:initGameAssistantBtn()

	self.hideStatus_ = {
		{
			hide = false,
			trans = self.transTopTween,
			normalPos = {
				x = self.transTopTween.localPosition.x,
				y = self.transTopTween.localPosition.y
			}
		},
		{
			hide = false,
			trans = self.bottomGroup,
			normalPos = {
				x = self.bottomGroup.localPosition.x,
				y = self.bottomGroup.localPosition.y
			}
		},
		{
			hide = false,
			trans = self.midBtnGroup,
			normalPos = {
				x = self.midBtnGroup.localPosition.x,
				y = self.midBtnGroup.localPosition.y
			}
		},
		{
			hide = false,
			trans = self.chartGroup,
			normalPos = {
				right = self.chartGroup.localPosition.x,
				y = self.chartGroup.localPosition.y
			}
		},
		{
			hide = false,
			trans = self.arrGroup.transform,
			normalPos = {
				x = self.arrGroup.transform.localPosition.x,
				y = self.arrGroup.transform.localPosition.y
			}
		}
	}

	self:initOnceActivityInfo()
	self:updateWindowDisplay(MainWindow.HideType.KIND0)
	self:initRedMark()
	self:updateUpIcon()
	self:changeChristmasEffect()
	xyd.models.activityPointTips:initData()
end

function MainWindow:changeChristmasEffect()
end

function MainWindow:moveLargeConFinish()
	if self.largeAutoMoveKey ~= -1 then
		xyd.removeGlobalTimer(self.largeAutoMoveKey)
	end

	self.largeAutoMoveKey = xyd.addGlobalTimer(handler(self, self.autoMoveLargeCon), 5)
end

function MainWindow:moveLargeCon(isFirstTimerMoveLarge)
	if #self.largeBtnArr <= 1 then
		return
	end

	if isFirstTimerMoveLarge ~= nil then
		self.isFirstTimerMoveLarge = isFirstTimerMoveLarge
	end

	local tempx = self.largeBtnScroller_scrollView.transform.localPosition.x
	local posIndex = self:getScrollPosIndex(tempx)

	if self.isFirstTimerMoveLarge == false and self.largeAutoMoveKey ~= -1 then
		xyd.removeGlobalTimer(self.largeAutoMoveKey)

		self.largeAutoMoveKey = -1
	end

	if self.isFirstTimerMoveLarge then
		self.isFirstTimerMoveLarge = false
	end

	if posIndex <= self.largecurIndex then
		self.largecurIndex = self.largecurIndex + 1

		if self.largecurIndex > #self.largeBtnArr then
			self.largecurIndex = self.largecurIndex % #self.largeBtnArr
		end

		self.largeBtnItemArr[3]:updateInfo(self:getLargeItemData(self.largeBtnArr[self.largecurIndex].activity_id))

		local nextIndex = self.largecurIndex + 1

		if nextIndex > #self.largeBtnArr then
			nextIndex = 1
		end

		self.largeBtnItemArr[1]:updateInfo(self:getLargeItemData(self.largeBtnArr[nextIndex].activity_id))
		self.largeBtnItemArr[1]:getGo():SetLocalPosition(self.largeBtnItemArr[3]:getGo().transform.localPosition.x + self.largewidthNum, 0, 0)

		local tempItem = self.largeBtnItemArr[1]
		self.largeBtnItemArr[1] = self.largeBtnItemArr[2]
		self.largeBtnItemArr[2] = self.largeBtnItemArr[3]
		self.largeBtnItemArr[3] = tempItem
		self.largeTempPos = self.largeTempPos - self.largewidthNum
	else
		self.largecurIndex = self.largecurIndex - 1

		if self.largecurIndex < 1 then
			self.largecurIndex = #self.largeBtnArr + self.largecurIndex % #self.largeBtnArr
		end

		self.largeBtnItemArr[1]:updateInfo(self:getLargeItemData(self.largeBtnArr[self.largecurIndex].activity_id))

		local lastIndex = self.largecurIndex - 1

		if lastIndex < 1 then
			lastIndex = #self.largeBtnArr
		end

		self.largeBtnItemArr[3]:updateInfo(self:getLargeItemData(self.largeBtnArr[lastIndex].activity_id))
		self.largeBtnItemArr[3]:getGo():SetLocalPosition(self.largeBtnItemArr[1]:getGo().transform.localPosition.x - self.largewidthNum, 0, 0)

		local tempItem = self.largeBtnItemArr[3]
		self.largeBtnItemArr[3] = self.largeBtnItemArr[2]
		self.largeBtnItemArr[2] = self.largeBtnItemArr[1]
		self.largeBtnItemArr[1] = tempItem
		self.largeTempPos = self.largeTempPos + self.largewidthNum
	end

	self:updateLargeBtnPage(self:checkLargePagePoint())
end

function MainWindow:checkLargePagePoint()
	local sortArr = {}

	for i in pairs(self.largeBtnItemArr) do
		local params = {
			xpos = 9999,
			id = self.largeBtnItemArr[i].id
		}

		table.insert(sortArr, params)
	end

	for i in pairs(self.largeBtnItemArr) do
		local tras = self.transTopL.transform:InverseTransformPoint(self.largeBtnItemArr[i]:getGo().transform.position)
		sortArr[i].xpos = math.abs(tras.x - self.largeBigCon.transform.localPosition.x)
	end

	table.sort(sortArr, function (a, b)
		return a.xpos < b.xpos
	end)

	return sortArr[1].id
end

function MainWindow:getScrollPosIndex(tempx)
	local posIndex = math.ceil((tempx - self.largeTempPos) / self.largewidthNum) + self.largecurIndex

	return posIndex
end

function MainWindow:initOnceActivityInfo()
	if not xyd.GuideController.get():isGuideComplete() then
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.FOLLOWING_GIFTBAG, function ()
			xyd.db.misc:setValue({
				key = "activity_follow_gift",
				value = xyd.getServerTime()
			})
		end)
	end
end

function MainWindow:initLayout()
	self:initResItem()
	self:initTopBtnGroup()
	self:initBottomGroup()
	self:initAvatar()
	self:initPlayerInfo()
	self:initPartnerSwitchArrow()
end

function MainWindow:initAvatar()
	local avatarID = selfPlayer:getAvatarID()
	local lev = backpack:getLev()
	local avatarFrameID = selfPlayer:getAvatarFrameID()
	local playerInfo = {
		avatarID = avatarID,
		lev = lev,
		avatar_frame_id = avatarFrameID,
		callback = function ()
			xyd.WindowManager.get():openWindow("person_info_window")
			MainMap:stopSound()
		end
	}

	if not self.playerIcon then
		self.playerIcon = PlayerIcon.new(self.transPlayerGroup.gameObject)

		self.playerIcon:setInfo(playerInfo)

		self.playerIcon.go.transform.localPosition = Vector3(56, -56, 0)
	else
		self.playerIcon:setInfo(playerInfo)
	end

	self:showProperTopBtn()
end

function MainWindow:initResItem()
	local goldParams = {
		hideBg = true,
		tableId = xyd.ItemID.MANA
	}
	self.goldItem = ResItem.new(self.resGroup.gameObject)

	self.goldItem:setInfo(goldParams)
	self.goldItem:showBothLine(true)

	self.redIcons[xyd.RedMarkType.MIDAS] = self.goldItem:getRedMarkGo()
	local crystalParams = {
		hideBg = true,
		showBonus = true,
		tableId = xyd.ItemID.CRYSTAL
	}
	self.crystalItem = ResItem.new(self.resGroup.gameObject)

	self.crystalItem:setInfo(crystalParams)
	self.crystalItem:showBothLine(false, "left")
	self.crystalItem:showBothLine(true, "right")
	table.insert(self.resItemList, self.goldItem)
	table.insert(self.resItemList, self.crystalItem)
end

function MainWindow:initTopBtnGroup()
	local callbackList = {
		function ()
			MainMap:stopSound()
			xyd.WindowManager.get():openWindow("friend_window")
		end,
		function ()
			if not xyd.checkFunctionOpen(xyd.FunctionID.MISSION) then
				return
			end

			if xyd.models.activity:getActivity(xyd.ActivityID.BATTLE_PASS) or xyd.models.activity:getActivity(xyd.ActivityID.BATTLE_PASS_2) then
				xyd.WindowManager.get():openWindow("battle_pass_window", {})
			else
				xyd.WindowManager.get():openWindow("daily_mission_window")
			end

			MainMap:stopSound()
		end,
		function ()
			MainMap:stopSound()
			xyd.db.misc:setValue({
				key = "daily_quize_redmark",
				value = xyd.getServerTime()
			})
			xyd.models.redMark:setMark(xyd.RedMarkType.DAILY_QUIZ, false)

			if xyd.models.dailyQuiz:isAllMaxLev() then
				xyd.WindowManager.get():openWindow("daily_quiz2_window")
			else
				xyd.WindowManager.get():openWindow("daily_quiz_window")
			end
		end,
		function ()
			MainMap:stopSound()

			if xyd.models.petTraining:isTrainOpen() then
				xyd.WindowManager.get():openWindow("pet_start_window")
			else
				xyd.WindowManager.get():openWindow("pet_window")
			end
		end,
		function ()
			MainMap:stopSound()

			if xyd.models.exploreModel:getTrainRoomsInfo() then
				xyd.WindowManager.get():openWindow("explore_window")
			end
		end,
		function ()
			if not xyd.checkFunctionOpen(xyd.FunctionID.STARRY_ALTAR) then
				return
			end

			local galaxyOpen = xyd.checkFunctionOpen(xyd.FunctionID.GALAXY_TRIP, true)

			if galaxyOpen then
				xyd.WindowManager.get():openWindow("galaxy_start_window")
			else
				xyd.WindowManager.get():openWindow("starry_altar_window")
			end

			MainMap:stopSound()
		end,
		function ()
			if not xyd.checkFunctionOpen(xyd.FunctionID.GROWTH_DIARY) then
				return
			end

			xyd.WindowManager.get():openWindow("growth_dairy_window")
			MainMap:stopSound()
		end
	}

	for i = 1, 7 do
		local go = NGUITools.AddChild(self.transTopR.gameObject, self.topRightBtn.gameObject)

		go:SetActive(true)

		go.name = "tr_btn_" .. i
		local btn = MainTopRightBtn.new(go, i)

		table.insert(self.trBtnList_, btn)

		UIEventListener.Get(go).onClick = callbackList[i]
	end

	self.func2Btn = {
		[xyd.FunctionID.MISSION] = self.trBtnList_[2],
		[xyd.FunctionID.QUIZ] = self.trBtnList_[3],
		[xyd.FunctionID.PET] = self.trBtnList_[4]
	}
	self.btnMission_ = self.trBtnList_[2]
	self.btnExplore_ = self.trBtnList_[5]
	self.btnQuiz_ = self.trBtnList_[3]

	self:showProperTopBtn()
end

function MainWindow:checkTrBtn()
	if self.trBtnList_ then
		for i = 1, #self.trBtnList_ do
			if self.trBtnList_[i].id == 7 and xyd.models.growthDiary:checkFinish() then
				self.trBtnList_[i].goItem_:SetActive(false)
			elseif self.trBtnList_[i].id == 6 then
				self.trBtnList_[i]:checkGalaxy()
			end
		end

		self.transTopR:GetComponent(typeof(UIGrid)):Reposition()
	end
end

function MainWindow:updateUpIcon()
	for i in pairs(self.trBtnList_) do
		self.trBtnList_[i]:updateUpIcon()
	end

	if xyd.models.activity:isResidentReturnAddTime() then
		self.upIcon:SetActive(xyd.models.activity:isResidentReturnAddTime())

		local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.HANG_UP)

		xyd.setUISpriteAsync(self.upIcon.gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_" .. return_multiple, nil, , )
		self.upIcon.gameObject:SetLocalPosition(126, -65, 0)
	else
		self.upIcon:SetActive(xyd.getReturnBackIsDoubleTime())
		xyd.setUISpriteAsync(self.upIcon.gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_2", nil, , )
		self.upIcon.gameObject:SetLocalPosition(143, 44, 0)
	end
end

function MainWindow:showProperTopBtn()
	if xyd.checkFunctionOpen(xyd.FunctionID.TOWER, true) then
		xyd.applyChildrenOrigin(self.arenaBtn.gameObject)
	elseif xyd.isH5() then
		xyd.applyChildrenDark(self.arenaBtn.gameObject)
	else
		xyd.applyChildrenGrey(self.arenaBtn.gameObject)
	end

	for i = 1, #self.trBtnList_ do
		if self.trBtnList_[i] then
			self.trBtnList_[i]:levChange()
		end
	end

	if xyd.isH5() then
		self.transTopR_uiRect:SetLeftAnchor(self.transTop, 1, -88)
		self.transTopR_uiRect:SetRightAnchor(self.transTop, 1, -16)
	end

	self.transTopR:GetComponent(typeof(UIGrid)):Reposition()
	self:initGameAssistantBtn()
end

function MainWindow:resetRightBtnGroup()
	if self.rightSelectId > 0 then
		self["MainWinRightBtn_" .. tostring(self.rightSelectId)]:closeList()

		self.rightSelectId = 0
	end
end

function MainWindow:playButtonSound(id)
	if self.currentIndex == id then
		return
	end

	local soundId = 0

	if id == 1 then
		soundId = 2116
	elseif id == 2 then
		soundId = 2127
	elseif id == 3 then
		soundId = 2129
	elseif id == 4 then
		soundId = 2130
	elseif id == 5 then
		soundId = 2144
	elseif id == 6 then
		soundId = 2131
	end

	xyd.SoundManager.get():playSound(soundId)
end

function MainWindow:initBottomGroup()
	for i = 1, 6 do
		local go = NGUITools.AddChild(self.bottomBtnGroup.gameObject, self.bottomBtn.gameObject)

		go:SetActive(true)

		go.name = "bottom_btn_" .. i
		local btn = MainBottomBtn.new(go, i)

		table.insert(self.bottomBtnList_, btn)

		UIEventListener.Get(go).onClick = handler(self, function ()
			if not self.stopClickBottomBtn then
				self:playButtonSound(i)
				self:onBottomBtnValueChange(i)
			end
		end)
		self["MainwinBottomBtn_" .. i] = go
		self["MainwinBottomBtn_red_img_" .. i] = btn
	end

	local btnChatImgName = "chat_icon_v3"
	local schoolBtnImgName = "top_school_icon_v3"
	local arenaBtnImgName = "top_arena_icon_v3"
	local btnStoryImgName = "top_story_icon_v3"

	if xyd.isH5() then
		btnChatImgName = btnChatImgName .. "_h5"
		schoolBtnImgName = schoolBtnImgName .. "_h5"
		arenaBtnImgName = arenaBtnImgName .. "_h5"
		btnStoryImgName = btnStoryImgName .. "_h5"

		self.schoolBtn:Y(22)
		self.arenaBtn:Y(31.6)
		self.btnStory:Y(31.2)
	end

	self.btnChat_uisprite = self.btnChat:GetComponent(typeof(UISprite))
	self.schoolBtn_uisprite = self.schoolBtn:GetComponent(typeof(UISprite))
	self.arenaBtn_uisprite = self.arenaBtn:GetComponent(typeof(UISprite))
	self.btnStory_uisprite = self.btnStory:GetComponent(typeof(UISprite))

	xyd.setUISprite(self.btnChat_uisprite, nil, btnChatImgName)
	xyd.setUISprite(self.schoolBtn_uisprite:GetComponent(typeof(UISprite)), nil, schoolBtnImgName)
	xyd.setUISprite(self.arenaBtn_uisprite:GetComponent(typeof(UISprite)), nil, arenaBtnImgName)
	xyd.setUISprite(self.btnStory_uisprite:GetComponent(typeof(UISprite)), nil, btnStoryImgName)
	self.btnChat_uisprite:MakePixelPerfect()
	self.schoolBtn_uisprite:MakePixelPerfect()
	self.arenaBtn_uisprite:MakePixelPerfect()
	self.btnStory_uisprite:MakePixelPerfect()

	local imgText1 = self.schoolBtn:ComponentByName("imgText1", typeof(UISprite))
	local nameText1 = self.schoolBtn:ComponentByName("nameText1", typeof(UILabel))
	local imgText2 = self.arenaBtn:ComponentByName("imgText2", typeof(UISprite))
	local nameText2 = self.arenaBtn:ComponentByName("nameText2", typeof(UILabel))
	local imgText3 = self.btnStory:ComponentByName("imgText3", typeof(UISprite))
	local nameText3 = self.btnStory:ComponentByName("nameText3", typeof(UILabel))

	if xyd.Global.lang == "ja_jp" then
		nameText3:X(105)
	end

	nameText1.text = __("MAIN_SCHOOL")

	imgText1:SetActive(false)

	if xyd.isH5() then
		local imgSprite1 = "main_win_school_text_" .. tostring(xyd.Global.lang)

		xyd.setUISpriteAsync(imgText1, nil, imgSprite1, nil, false, true)
		imgText1:SetActive(true)
		imgText1:SetLocalPosition(0, -67.8, 0)
		nameText1:SetActive(false)
	end

	nameText2.text = __("MAIN_ARENA")

	imgText2:SetActive(false)

	if xyd.Global.lang == "en_en" then
		nameText2:X(0)
	end

	if xyd.isH5() then
		local imgSprite2 = "main_win_arena_text_" .. tostring(xyd.Global.lang)

		xyd.setUISpriteAsync(imgText2, nil, imgSprite2, nil, false, true)
		imgText2:SetActive(true)
		imgText2:SetLocalPosition(-7.5, -75.7, 0)
		nameText2:SetActive(false)
	end

	nameText3.text = __("MAIN_STORY")

	imgText3:SetActive(false)

	if xyd.isH5() then
		local imgSprite3 = "main_win_story_text_" .. tostring(xyd.Global.lang)

		xyd.setUISpriteAsync(imgText3, nil, imgSprite3, nil, false, true)
		imgText3:SetActive(true)
		imgText3:SetLocalPosition(-39, -75.4, 0)
		nameText3:SetActive(false)
	end

	if xyd.Global.lang ~= "zh_tw" and xyd.isH5() then
		imgText3:X(0)
	end

	local dressActivityData = xyd.models.activity:getActivity(xyd.ActivityID.DRESS_SUMMON_LIMIT)

	if not dressActivityData or dressActivityData:getEndTime() <= xyd.getServerTime() or not xyd.checkFunctionOpen(xyd.FunctionID.DRESS, true) then
		self.btnLimitDress:SetActive(false)
	else
		self.btnLimitDress:SetActive(true)
	end

	UIEventListener.Get(self.arenaBtn.gameObject).onClick = handler(self, function ()
		MainMap:stopSound()

		if not xyd.checkFunctionOpen(xyd.FunctionID.TOWER) then
			self:showHand(true)

			return
		end

		xyd.SoundManager.get():playSound(2126)
		xyd.WindowManager.get():openWindow("battle_choose_window")
	end)
	UIEventListener.Get(self.btnLimitDress.gameObject).onClick = handler(self, function ()
		if self.isShake then
			return
		end

		local dressActivityData = xyd.models.activity:getActivity(xyd.ActivityID.DRESS_SUMMON_LIMIT)

		if not dressActivityData or dressActivityData:getEndTime() <= xyd.getServerTime() then
			return
		end

		xyd.WindowManager.get():openWindow("dress_summon_window", {})
	end)
	UIEventListener.Get(self.schoolBtn.gameObject).onClick = handler(self, function ()
		if self.isShake then
			return
		end

		MainMap:stopSound()
		xyd.SoundManager.get():playSound(2123)
		xyd.WindowManager.get():openWindow("school_choose_window")
	end)
	UIEventListener.Get(self.btnStory.gameObject).onClick = handler(self, function ()
		MainMap:stopSound()
		xyd.SoundManager.get():playSound(2124)
		xyd.WindowManager.get():openWindow("campaign_window")
	end)
	UIEventListener.Get(self.mailBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("mail_window")
	end)
	UIEventListener.Get(self.gameAssistantBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("game_assistant_window")

		if self.gameAssistantMoveSequence then
			self.gameAssistantMoveSequence:Kill(false)

			self.gameAssistantMoveSequence = nil
		end

		self.gameAssistantBtn.localRotation = Vector3(0, 0, 0)

		self.gameAssistantBtn:Y(-78)
		xyd.db.misc:setValue({
			value = 0,
			key = "gameAssistant_has_open"
		})
		xyd.db.misc:setValue({
			key = "gameAssistant_todayHaveClick_timeStamp",
			value = xyd.getServerTime()
		})

		xyd.models.gameAssistant.todayHaveClick = true
	end)

	UIEventListener.Get(self.btnNotice).onClick = function ()
		xyd.WindowManager.get():openWindow("new_notice_window", {})
	end
end

function MainWindow:onBottomBtnValueChange(index, noCallBack, noShake)
	if self.currentIndex == index then
		return
	end

	local callbackList = {
		self.onClickBtnHome,
		self.onClickBtnPartner,
		self.onClickBtnBackpack,
		self.onClickBtnSummon,
		self.onClickBtnGuild,
		self.onClickBtnSetting
	}
	local callback = callbackList[index] or nil
	callback = callback and handler(self, callbackList[index])

	if noCallBack then
		callback = nil
	end

	local function action()
		MainMap:stopSound()

		if noShake then
			if callback then
				callback()
			end

			if not self.noChangeState_ and self.currentIndex > 0 then
				self.bottomBtnList_[self.currentIndex]:change(0)
			end

			if index > 0 then
				self.bottomBtnList_[index]:change(1)
			end

			self.currentIndex = index
			self.noChangeState_ = false
		else
			self:bottomBtnShake(index, callback)
		end
	end

	if index ~= 5 then
		action()
	elseif self:checkFuncOpen({
		func_id = xyd.FunctionID.GUILD
	}, true) then
		action()
	end
end

function MainWindow:isSummonGacha()
	local actList = xyd.models.activity:getActivityList()

	for i = 1, #actList do
		if actList[i] and actList[i].id == xyd.ActivityID.SUMMON_GIFTBAG and xyd.Global.isInGuide == false then
			local img = eui.Image.new()

			if string.lower(xyd.Global.lang) == "ja_jp" then
				img.source = "summon_up_v3_ja_jp_png"
			else
				img.source = "summon_up_v3_png"
			end

			img.top = -30
			img.right = -5

			self.MainwinBottomBtn_4:addChild(img)

			break
		end
	end
end

function MainWindow:isHasNewCampaign()
	local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)

	if not mapInfo then
		return false
	end

	local maxStage = tonumber(mapInfo.max_stage)
	local maxHangStage = tonumber(mapInfo.max_hang_stage)
	local currentStage = tonumber(mapInfo.current_stage)
	local serverTime = xyd.getServerTime()

	if maxStage < currentStage then
		self:updateStoryDialogData(currentStage)
	end
end

function MainWindow:initActivityBtn()
	self:setActivityEnter()
end

function MainWindow:setActivityEnter()
	self:CheckExtraActBtn()
end

function MainWindow:initChat()
	UIEventListener.Get(self.btnChat).onClick = function ()
		MainMap.get():stopSound()
		xyd.WindowManager.get():openWindow("chat_window")
	end
end

function MainWindow:initGameAssistantBtn()
	local isOpen = xyd.checkFunctionOpen(xyd.FunctionID.GAME_ASSISTANT, true)

	self.gameAssistantBtn:SetActive(isOpen)

	if isOpen then
		if not xyd.models.gameAssistant.todayHaveClick then
			self.gameAssistantBtn:Y(-78)

			local timeStamp = xyd.db.misc:getValue("gameAssistant_todayHaveClick_timeStamp")

			if not timeStamp then
				return
			elseif timeStamp and not xyd.isSameDay(xyd.getServerTime(), tonumber(timeStamp)) then
				self:waitForTime(3, function ()
					local wnd = xyd.getWindow("game_assistant_window")

					if not wnd then
						self:playHideGameAssistantBtnAnimation()
					end
				end)
			else
				self.gameAssistantBtn:Y(-36)

				self.gameAssistantBtn.localRotation = Vector3(0, 0, 180)
			end
		else
			self.gameAssistantBtn:Y(-36)

			self.gameAssistantBtn.localRotation = Vector3(0, 0, 180)
		end
	end
end

function MainWindow:playHideGameAssistantBtnAnimation()
	if self.gameAssistantMoveSequence then
		self.gameAssistantMoveSequence:Kill(false)

		self.gameAssistantMoveSequence = nil
	end

	self.gameAssistantMoveSequence = self:getSequence()
	local oldX = self.gameAssistantBtn.gameObject.transform.localPosition.x

	self.gameAssistantMoveSequence:Insert(0, self.gameAssistantBtn.gameObject.transform:DOLocalMove(Vector3(oldX, -36, 0), 0.6, false))
	self.gameAssistantMoveSequence:Insert(0, self.gameAssistantBtn.gameObject.transform:DOLocalRotate(Vector3(0, 0, 180), 0.4))
end

function MainWindow:CheckExtraActBtn(btnType)
	self.leftUpCon:CheckExtraActBtn(btnType)

	if not self.newbieBtn_ then
		self.newbieBtn_ = self.leftUpCon.newbieBtn_
	end

	if not self.limitBtn_ then
		self.limitBtn_ = self.leftUpCon.limitBtn_
	end
end

function MainWindow:CheckScrollerUpdateLargeActBtn()
	local activityDataAll = xyd.models.activity:getActivityList()
	local oldDataLength = #self.largeBtnArr

	if oldDataLength == 0 then
		self.isOnlyInitScrollerAct = true

		self:CheckExtraActBtn()
		self:updateLargeScrollerBtnRedPoint()

		return
	end

	local isNewInit = false

	for i in pairs(activityDataAll) do
		if xyd.tables.activityTable:getType(activityDataAll[i].id) == xyd.EventType.LARGE then
			local isHas = false

			for j in pairs(self.largeBtnArr) do
				if activityDataAll[i].id == self.largeBtnArr[j].id then
					isHas = true

					break
				end
			end

			if isHas == false then
				isNewInit = true
			end
		end
	end

	if isNewInit == false then
		for i in pairs(self.largeBtnArr) do
			local actData = xyd.models.activity:getActivity(self.largeBtnArr[i].id)

			if not actData or actData:getEndTime() - xyd.getServerTime() <= 0 or not actData:isOpen() then
				isNewInit = true

				break
			end
		end
	end

	if isNewInit == true then
		xyd.changeScrollViewMove(self.largeBtnConScroller.gameObject, false, Vector3(1, 0, 0), Vector2(1, 0))

		if self.isFirstTimerMoveLarge == false and self.largeAutoMoveKey ~= -1 then
			xyd.removeGlobalTimer(self.largeAutoMoveKey)

			self.largeAutoMoveKey = -1
		end

		for i in pairs(self.largePageBgArr) do
			NGUITools.Destroy(self.largePageBgArr[i])
		end

		xyd.changeScrollViewMove(self.largeBtnConScroller.gameObject, false, Vector3(1, 0, 0), Vector2(1, 0))

		local oldlargeBigCon = self.largeBigCon

		NGUITools.DestroyChildren(self.largeBtnCon.gameObject.transform)

		if xyd.isH5() and self.big_con_behind_effect then
			self.big_con_behind_effect:destroy()

			self.big_con_behind_effect = nil
		end

		self:waitForFrame(5, function ()
			self.largeBigCon = NGUITools.AddChild(self.transTopL.gameObject, self.largeBigConEg.gameObject)
			self.largeBtnConScroller = self.largeBigCon.transform:Find("largeBtnConScroller").gameObject
			self.largeBtnConScroller_drag = self.largeBigCon:NodeByName("drag").gameObject
			self.largeBtnCon = self.largeBigCon.transform:Find("largeBtnConScroller/largeBtnCon").gameObject
			self.largeBtn_CenterOnChild = self.largeBtnCon:GetComponent(typeof(UICenterOnChild))
			self.largeBtnScroller_scrollView = self.largeBtnConScroller:GetComponent(typeof(UIScrollView))
			self.largeBtnScroller_scrollView.onDragMoving = handler(self, self.moveLargeCon)
			self.largeBtnScroller_scrollView.onDragFinished = handler(self, self.moveLargeConFinish)
			self.largePageShowCon = self.largeBigCon.transform:Find("largePageShowCon").gameObject
			self.largePageBg = self.largeBigCon.transform:Find("largePageShowCon/largePageBg").gameObject
			self.largePageLight = self.largeBigCon.transform:Find("largePageShowCon/largePageLight").gameObject

			for i in pairs(self.leftUpCon:getExtraActBtnArr()) do
				if self.leftUpCon:getExtraActBtnArr()[i]:getGo().transform.name == "largeBigCon" then
					self.leftUpCon:getExtraActBtnArr()[i] = self.largeBigCon
				end
			end

			NGUITools.Destroy(oldlargeBigCon)

			self.largeTempPos = 1
			self.largecurIndex = 1
			self.largePageBgArr = {}
			self.largeBtnArr = {}
			self.largeBtnItemArr = {}
			self.isOnlyInitScrollerAct = true

			self:CheckExtraActBtn()
			self:updateLargeScrollerBtnRedPoint()
		end)
	end
end

function MainWindow:CheckScrollerLargeActBtn()
	local activityDataAll = xyd.models.activity:getActivityList()

	for i in pairs(activityDataAll) do
		if xyd.tables.activityTable:getType(activityDataAll[i].id) == xyd.EventType.LARGE and activityDataAll[i] and activityDataAll[i]:getEndTime() - xyd.getServerTime() > 0 and activityDataAll[i]:isOpen() then
			table.insert(self.largeBtnArr, activityDataAll[i])
		end
	end

	table.sort(self.largeBtnArr, function (a, b)
		return a.activity_id < b.activity_id
	end)

	if #self.largeBtnArr >= 1 and #self.largeBtnItemArr == 0 then
		local manCreatLen = 3

		if #self.largeBtnArr == 1 then
			manCreatLen = 1
		end

		for i = 1, manCreatLen do
			local tmp = NGUITools.AddChild(self.largeBtnCon.gameObject, self.largeBtneg.gameObject)
			tmp.gameObject:ComponentByName("e:image", typeof(UIDragScrollView)).scrollView = self.largeBtnScroller_scrollView
			local item = MainUIActivityItem.new(tmp, nil, self.largeBtnConScroller:GetComponent(typeof(UIPanel)))

			table.insert(self.largeBtnItemArr, item)
		end
	end

	if #self.largeBtnArr >= 1 then
		if self.largecurIndex == 1 then
			self.largeBtnConScroller_drag:SetActive(false)
			self.largeBtnItemArr[1]:updateInfo(self:getLargeItemData(self.largeBtnArr[1].activity_id))

			if #self.largeBtnArr > 1 then
				self.largeBtnConScroller_drag:SetActive(true)

				if #self.largeBtnArr == 2 then
					self.largeBtnItemArr[2]:updateInfo(self:getLargeItemData(self.largeBtnArr[2].activity_id))
					self.largeBtnItemArr[3]:updateInfo(self:getLargeItemData(self.largeBtnArr[2].activity_id))
				end

				if #self.largeBtnArr >= 3 then
					self.largeBtnItemArr[2]:updateInfo(self:getLargeItemData(self.largeBtnArr[#self.largeBtnArr].activity_id))
					self.largeBtnItemArr[3]:updateInfo(self:getLargeItemData(self.largeBtnArr[2].activity_id))
				end

				XYDCo.WaitForFrame(1, function ()
					self.largeBtnItemArr[3]:getGo():SetLocalPosition(self.largeBtnItemArr[1]:getGo().transform.localPosition.x - self.largewidthNum, 0, 0)

					local tempItem = self.largeBtnItemArr[2]
					self.largeBtnItemArr[2] = self.largeBtnItemArr[1]
					self.largeBtnItemArr[1] = self.largeBtnItemArr[3]
					self.largeBtnItemArr[3] = tempItem
				end, nil)

				self.largeAutoMoveKey = xyd.addGlobalTimer(handler(self, self.autoMoveLargeCon), 5)
			end
		end

		self.largeBtn_CenterOnChild.onFinished = handler(self, function ()
			self:moveLargeCon(true)
		end)

		self.largeBtnConScroller.gameObject:SetActive(true)
		self.largeBigCon:SetActive(true)

		local pageBgX = 0 - 16 * (#self.largeBtnArr - 1) / 2

		for i = 1, #self.largeBtnArr do
			local tmp = NGUITools.AddChild(self.largePageShowCon.gameObject, self.largePageBg.gameObject)

			table.insert(self.largePageBgArr, tmp)

			local mark = xyd.checkCondition(i <= #self.largeBtnArr / 2, -1, 1)

			tmp:SetLocalPosition(pageBgX + 16 * (i - 1), 0, 0)
			tmp:SetActive(true)
		end

		self.largePageLight:SetLocalPosition(self.largePageBgArr[1].transform.localPosition.x, 0, 0)
	else
		self.largeBtnConScroller.gameObject:SetActive(false)
		self.largeBigCon:SetActive(false)
	end

	if #self.largeBtnArr > 1 then
		self.largePageShowCon:SetActive(true)
	else
		self.largePageShowCon:SetActive(false)
	end
end

function MainWindow:updateLatgeBtnRedPoint()
	for i in pairs(self.largeBtnItemArr) do
		self.largeBtnItemArr[i]:updateRedMark()
	end
end

function MainWindow:updateLargeBtnPage(id)
	for i in pairs(self.largeBtnArr) do
		if id == self.largeBtnArr[i].activity_id then
			self.largePageLight:SetLocalPosition(self.largePageBgArr[i].transform.localPosition.x, 0, 0)

			break
		end
	end
end

function MainWindow:autoMoveLargeCon()
	self.largeBtn_CenterOnChild:CenterOn(self.largeBtnItemArr[3]:getGo().transform)
	self:updateLargeBtnPage(self.largeBtnItemArr[3].id)
end

function MainWindow:getLargeItemData(id)
	local dataParams = {
		isShowName = true,
		activity_id = id
	}

	return dataParams
end

function MainWindow:registerEvent()
	self:register()
	self.eventProxy_:addEventListener(xyd.event.GET_ECONOMY_INFO_PUSH, handler(self, self.refreshEconomy))
	self.eventProxy_:addEventListener(xyd.event.EDIT_PLAYER_AVATAR, handler(self, self.initAvatar))
	self.eventProxy_:addEventListener(xyd.event.EDIT_PLAYER_AVATAR_FRAME, handler(self, self.initAvatar))
	self.eventProxy_:addEventListener(xyd.event.EDIT_PLAYER_NAME, handler(self, self.initPlayerInfo))
	self.eventProxy_:addEventListener(xyd.event.LEV_CHANGE, function ()
		self:initAvatar()

		self.notShowMapAlert = false
	end)
	self.eventProxy_:addEventListener(xyd.event.VIP_CHANGE, handler(self, self.initPlayerInfo))
	self.eventProxy_:addEventListener(xyd.event.NEW_AVATARS, handler(self, self.showAlert))
	self.eventProxy_:addEventListener(xyd.event.NEW_PICTURES, handler(self, self.showAlert))
	self.eventProxy_:addEventListener(xyd.event.GET_MAP_INFO, handler(self, self.isHasNewCampaign))
	self.eventProxy_:addEventListener(xyd.event.STAGE_HANG, handler(self, self.isHasNewCampaign))
	self.eventProxy_:addEventListener(xyd.event.FUNCTION_OPEN, handler(self, self.showProperTopBtn))
	self.eventProxy_:addEventListener(xyd.event.RED_POINT, handler(self, self.onRedPoint))

	UIEventListener.Get(self.groupVip_bg.gameObject).onClick = handler(self, function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.WindowManager.get():openWindow("vip_window", {
			show_benefit = true
		})
	end)

	self.eventProxy_:addEventListener(xyd.event.WINDOW_WILL_OPEN, handler(self, self.onWindowOpen))
	self.eventProxy_:addEventListener(xyd.event.WINDOW_WILL_CLOSE, handler(self, self.onWindowClose))
	self.eventProxy_:addEventListener(xyd.event.GET_GAME_NOTICE_LIST, handler(self, self.updateBtnNotice))
end

function MainWindow:onRedPoint(event)
	local funID = event.data.function_id

	if funID == xyd.FunctionID.MISSION then
		xyd.models.redMark:setMark(xyd.RedMarkType.BATTLE_PASS, true)
		xyd.models.redMark:setMark(xyd.RedMarkType.MISSION, true)
	end
end

function MainWindow:bottomBtnShake(index, callback)
	if index <= 0 then
		return
	end

	local oldY = nil

	if self.isShake then
		return
	end

	self.isShake = true
	local btn = self.bottomBtnList_[index]
	local iconTran = btn:getIconGo().transform
	oldY = iconTran.localPosition.y

	if self.oldY[index] ~= nil or self.oldY[index] ~= nil then
		oldY = self.oldY[index]
	else
		self.oldY[index] = oldY
	end

	if index == 1 then
		xyd.SoundManager:get():playSound(2132)
	end

	local btnCollider = btn:getGoItem():GetComponent(typeof(UnityEngine.BoxCollider))
	btnCollider.enabled = false

	if callback then
		callback()
	end

	if not self.noChangeState_ then
		if self.currentIndex > 0 then
			self.bottomBtnList_[self.currentIndex]:change(0)
		end

		self.currentIndex = index
	end

	local function playAni2()
		local sequence2 = DG.Tweening.DOTween.Sequence()

		sequence2:Insert(0, iconTran:DOLocalMoveY(oldY, 0.68):SetEase(DG.Tweening.Ease.OutBounce))
		sequence2:Insert(0, iconTran:DOScale(Vector3(1.075, 1, 1), 0.2))
		sequence2:Insert(0.2, iconTran:DOScale(Vector3(1, 1, 1), 0.14))
		sequence2:Insert(0.34, iconTran:DOScale(Vector3(1, 1.04, 1), 0.14))
		sequence2:Insert(0.48, iconTran:DOScale(Vector3(1, 1, 1), 0.2))
		sequence2:AppendCallback(function ()
			btnCollider.enabled = true

			self:delSequene(sequence2)
		end)
		self:addSequene(sequence2)
	end

	self:waitForTime(0.1, function ()
		if tolua.isnull(self.window_) then
			return
		end

		local sequence1 = DG.Tweening.DOTween.Sequence()

		sequence1:Insert(0, iconTran:DOLocalMoveY(oldY + 30, 0.2):SetEase(DG.Tweening.Ease.OutSine))
		sequence1:Insert(0, iconTran:DOScale(Vector3(1.09, 1.09, 1), 0.2):SetEase(DG.Tweening.Ease.OutSine))
		sequence1:AppendCallback(function ()
			self.isShake = false

			if not self.noChangeState_ and self.currentIndex and self.currentIndex > 0 then
				self.bottomBtnList_[self.currentIndex]:change(1)
			end

			self.noChangeState_ = false

			playAni2()
			self:delSequene(sequence1)
		end)
		self:addSequene(sequence1)
	end, "changeBtnValue")
end

function MainWindow:bottomBtnOnlyShake(index, callback)
	if index <= 0 then
		return
	end

	local oldY = nil
	local btn = self.bottomBtnList_[index]
	local iconTran = btn:getIconGo().transform
	oldY = iconTran.localPosition.y

	if self.oldY[index] ~= nil or self.oldY[index] ~= nil then
		oldY = self.oldY[index]
	else
		self.oldY[index] = oldY
	end

	local btnCollider = btn:getGoItem():GetComponent(typeof(UnityEngine.BoxCollider))
	btnCollider.enabled = false

	if callback then
		callback()
	end

	local function playAni2()
		local sequence2 = self:getSequence()

		sequence2:Insert(0, iconTran:DOLocalMoveY(oldY, 0.68):SetEase(DG.Tweening.Ease.OutBounce))
		sequence2:Insert(0, iconTran:DOScale(Vector3(1.075, 1, 1), 0.2))
		sequence2:Insert(0.2, iconTran:DOScale(Vector3(1, 1, 1), 0.14))
		sequence2:Insert(0.34, iconTran:DOScale(Vector3(1, 1.04, 1), 0.14))
		sequence2:Insert(0.48, iconTran:DOScale(Vector3(1, 1, 1), 0.2))
		sequence2:AppendCallback(function ()
			btnCollider.enabled = true
		end)
	end

	self:waitForTime(0.1, function ()
		if tolua.isnull(self.window_) then
			return
		end

		local sequence1 = self:getSequence()

		sequence1:Insert(0, iconTran:DOLocalMoveY(oldY + 30, 0.2):SetEase(DG.Tweening.Ease.OutSine))
		sequence1:Insert(0, iconTran:DOScale(Vector3(1.09, 1.09, 1), 0.2):SetEase(DG.Tweening.Ease.OutSine))
		sequence1:AppendCallback(function ()
			playAni2()
		end)
	end)
end

function MainWindow:onClickBtnHome()
	local wnd1 = xyd.WindowManager.get():getWindow("slot_window")
	local wnd2 = xyd.WindowManager.get():getWindow("summon_window")
	local wnd3 = xyd.WindowManager.get():getWindow("backpack_window")
	local wnd = wnd1 and function ()
		return wnd1
	end or function ()
		return wnd2
	end()
	wnd = wnd and function ()
		return wnd
	end or function ()
		return wnd3
	end()

	if wnd then
		wnd:willCloseAnimation(function ()
			xyd.WindowManager.get():closeAllWindows({
				guide_window = true,
				main_window = true
			}, true)
		end)
	else
		xyd.WindowManager.get():closeAllWindows({
			guide_window = true,
			main_window = true
		}, true)
	end
end

function MainWindow:onClickBtnBackpack()
	local wnd1 = xyd.WindowManager.get():getWindow("slot_window")
	local wnd2 = xyd.WindowManager.get():getWindow("summon_window")
	local wnd = wnd1 and function ()
		return wnd1
	end or function ()
		return wnd2
	end()

	if wnd then
		wnd:willCloseAnimation(function ()
			xyd.WindowManager.get():openWindow("backpack_window", {}, function ()
				xyd.WindowManager.get():closeAllWindows({
					main_window = true,
					loading_window = true,
					res_loading_window = true,
					guide_window = true,
					backpack_window = true
				})
			end)
		end)
	else
		xyd.WindowManager.get():openWindow("backpack_window", {}, function ()
			xyd.WindowManager.get():closeAllWindows({
				main_window = true,
				loading_window = true,
				res_loading_window = true,
				guide_window = true,
				backpack_window = true
			})
		end)
	end
end

function MainWindow:onClickBtnSummon()
	local wnd1 = xyd.WindowManager.get():getWindow("slot_window")
	local wnd2 = xyd.WindowManager.get():getWindow("backpack_window")
	local wnd = wnd1 and function ()
		return wnd1
	end or function ()
		return wnd2
	end()

	if wnd then
		wnd:willCloseAnimation(function ()
			xyd.WindowManager.get():openWindow("summon_window", {}, function ()
				xyd.WindowManager.get():closeAllWindows({
					main_window = true,
					loading_window = true,
					new_partner_warming_up_entry_window = true,
					summon_window = true,
					guide_window = true,
					res_loading_window = true
				})
			end)
		end)
	else
		local flag = nil
		flag = not xyd.WindowManager.get():getWindow("activity_window") and not xyd.WindowManager.get():getWindow("campaign_window")

		xyd.WindowManager.get():openWindow("summon_window", {
			hideBottom = flag
		}, function ()
			xyd.WindowManager.get():closeAllWindows({
				main_window = true,
				loading_window = true,
				new_partner_warming_up_entry_window = true,
				summon_window = true,
				guide_window = true,
				res_loading_window = true
			})
		end)
	end
end

function MainWindow:onClickBtnSetting()
	xyd.WindowManager.get():openWindow("setting_up_window", {}, function ()
		xyd.WindowManager.get():closeAllWindows({
			main_window = true,
			loading_window = true,
			setting_up_window = true,
			guide_window = true,
			res_loading_window = true
		})
	end)
end

function MainWindow:onClickBtnGuild()
	if xyd.models.guild.guildID > 0 then
		xyd.WindowManager.get():openWindow("guild_territory_window", {}, function ()
			xyd.WindowManager.get():closeAllWindows({
				main_window = true,
				loading_window = true,
				guild_territory_window = true,
				guide_window = true,
				res_loading_window = true
			})
		end)
	else
		xyd.WindowManager.get():openWindow("guild_join_window")

		self.noChangeState_ = true
	end
end

function MainWindow:onClickBtnPartner()
	local wnd1 = xyd.WindowManager.get():getWindow("backpack_window")
	local wnd2 = xyd.WindowManager.get():getWindow("summon_window")
	local wnd = wnd1 and function ()
		return wnd1
	end or function ()
		return wnd2
	end()

	if wnd then
		wnd:willCloseAnimation(function ()
			xyd.WindowManager.get():openWindow("slot_window", {}, function ()
				xyd.WindowManager.get():closeAllWindows({
					main_window = true,
					loading_window = true,
					slot_window = true,
					guide_window = true,
					res_loading_window = true
				})
			end)
		end)
	else
		xyd.WindowManager.get():openWindow("slot_window", {}, function ()
			xyd.WindowManager.get():closeAllWindows({
				main_window = true,
				loading_window = true,
				slot_window = true,
				guide_window = true,
				res_loading_window = true
			})
		end)
	end
end

function MainWindow:openWindow()
	if not xyd.GuideController.get():isGuideComplete() and xyd.GuideController.get():getMaskLen() <= 0 then
		self:hideWindow()
	end
end

function MainWindow:setBottomBtnStatus(btnId, shake)
	for i = 1, 6 do
		if i == btnId then
			self.bottomBtnList_[i]:change(1, self.isStart, shake)
		else
			self.bottomBtnList_[i]:change(0, self.isStart, false)
		end
	end

	self.isStart = false
end

function MainWindow:updateWindowDisplay(hideType)
	if hideType == nil then
		hideType = MainWindow.HideType.KIND0
	end

	if hideType == MainWindow.HideType.KIND0 then
		self.chartGroup:SetActive(true)
	else
		self.chartGroup:SetActive(false)
	end

	self.curHideType = hideType
	local needHides = MainWindow.HideConf[hideType]

	for index = 1, #needHides do
		local needHide = needHides[index]
		local status = self.hideStatus_[index]

		if status then
			if status.hide then
				if needHide <= 0 then
					status.trans.localPosition.x = status.normalPos.x
					status.trans.localPosition.y = status.normalPos.y

					status.trans:SetActive(true)

					status.hide = false
				end
			elseif needHide > 0 then
				status.trans.localPosition.x = -30000
				status.trans.localPosition.y = -30000

				status.trans:SetActive(false)

				if status.trans == self.midBtnGroup then
					self:showHand(false)
				end

				status.hide = true
			end
		end
	end

	if hideType == MainWindow.HideType.KIND0 then
		if not xyd.GuideController.get():isPlayGuide() then
			if self.isPlayAnimation then
				return
			end

			self.transTopTween:SetActive(false)
			self:playAnimation()
			self:initStoryTimer()
		else
			self:onBottomBtnValueChange(1, true, true)

			self.isPlayAnimation = false

			self:setWndComplete()
		end
	end
end

function MainWindow:playAnimation()
	self.isWndComplete_ = false
	self.isPlayAnimation = true

	self:onBottomBtnValueChange(1, true, false)

	self.transTopTween.localPosition = Vector3(0, 112, 0)

	self.transTopTween:SetActive(true)

	local sequence1 = DG.Tweening.DOTween.Sequence()

	sequence1:Append(self.transTopTween:DOLocalMoveY(0, 0.3):SetEase(DG.Tweening.Ease.InOutSine))
	sequence1:AppendCallback(handler(self, function ()
		self:delSequene(sequence1)

		self.isPlayAnimation = false

		self:setWndComplete()
	end))
	self:addSequene(sequence1)
end

function MainWindow:refreshEconomy(event)
	local params = event.data

	if params.exp then
		self:updateExp()
	end
end

function MainWindow:updateExp(event)
	if event == nil then
		event = nil
	end
end

function MainWindow:willClose(params, skipAnimation, force)
	if params == nil then
		params = nil
	end

	if skipAnimation == nil then
		skipAnimation = false
	end

	if force == nil then
		force = false
	end

	MainWindow.super.willClose(self, params, skipAnimation, force)
end

function MainWindow:showMapLoadingSpr(flag)
	local mapType = MainController:get():getMapType()

	if flag == true then
		local currTime = xyd.getServerTime()
		self.loadingTime_ = currTime
	else
		self.loadingTime_ = 0
	end
end

function MainWindow:showAlert()
	local newAvatars = backpack:getNewAvatars()

	if not self.imgAlert_ then
		self.imgAlert_ = self.window_:NodeByName("top_group/top_tween_group/top_M_group/player_group/player_icon/main_group/red_img").gameObject
	end

	if #newAvatars > 0 then
		self.imgAlert_:SetActive(true)
	else
		self.imgAlert_:SetActive(false)
	end
end

function MainWindow:editName()
	local name = selfPlayer:getPlayerName()

	if name ~= nil and name ~= nil and name == "" then
		-- Nothing
	end
end

function MainWindow:showHand(flag)
	local hand = self.hand

	if flag == false then
		if hand ~= nil then
			self.hand:SetActive(false)
		end

		self.stageTouch:SetActive(false)

		return
	elseif flag == true and hand ~= nil then
		self.hand:SetActive(true)
		self.stageTouch:SetActive(true)

		return
	end

	self.stageTouch:SetActive(true)
	self:initStoryBtnDianjiEffect()
end

function MainWindow:onThisTouch()
	self:showHand(false)
end

function MainWindow:initPlayerInfo()
	local vipLev = xyd.models.backpack:getVipLev()
	local visible = vipLev > 0

	if visible then
		self.pageVipNum_:setInfo({
			iconName = "player_vip",
			num = vipLev
		})
	end

	self.groupVip:SetActive(visible)
end

function MainWindow:showGuideMask(isShow)
	local guideMask_ = self:getChildByName("guide_mask")

	if isShow then
		if not guideMask_ then
			guideMask_ = eui.Image.new()
			guideMask_.source = "guide_mask_png"
			guideMask_.name = "guide_mask"
			guideMask_.alpha = 0.01
			guideMask_.percentWidth = 100
			guideMask_.percentHeight = 100

			self:addChild(guideMask_)
		end

		guideMask_.visible = true
	elseif not isShow and guideMask_ then
		guideMask_.visible = false
	end
end

function MainWindow:initRedMark()
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.MIDAS, self.redIcons[xyd.RedMarkType.MIDAS])
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.CAMPAIGN_ACHIEVEMENT
	}, self.redPointStory)
	xyd.models.achievement:updateRedPointCampaign()
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.MAIL, self.redIcons[xyd.RedMarkType.MAIL])
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.BACKPACK,
		xyd.RedMarkType.BACKPACK_OVER_ITEM
	}, self.MainwinBottomBtn_red_img_3:getRedPoint())
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.SUMMON, self.MainwinBottomBtn_red_img_4:getRedPoint())
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.NEW_FIVE_STAR,
		xyd.RedMarkType.AVAILABLE_EQUIPMENT,
		xyd.RedMarkType.PROMOTABLE_PARTNER,
		xyd.RedMarkType.COMPOSE
	}, self.MainwinBottomBtn_red_img_2:getRedPoint())
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.JOIN_GUILD,
		xyd.RedMarkType.GUILD_LOG,
		xyd.RedMarkType.GUILD_ORDER,
		xyd.RedMarkType.GUILD_MEMBER,
		xyd.RedMarkType.GUILD_CHECKIN,
		xyd.RedMarkType.GUILD_BOSS,
		xyd.RedMarkType.GUILD_COMPETITION,
		xyd.RedMarkType.GUILD_COMPETITION_TASK_RED
	}, self.MainwinBottomBtn_red_img_5:getRedPoint())
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.CHAT_RED_NORMAL
	}, self.btnChat_redIcon.gameObject)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.CHAT_RED_GUILD
	}, self.btnChat_redIcon2.gameObject)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.CHAT_RED_PRIVATE
	}, self.btnChat_redIcon3.gameObject)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.FRIEND, self.trBtnList_[1]:getRedPoint())
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.PET, self.trBtnList_[4]:getRedPoint())
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.GROWTH_DIARY, self.trBtnList_[7]:getRedPoint())
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.GALAXY_TRIP,
		xyd.RedMarkType.GALAXY_TRIP_MAP_CAN_GET_POINT
	}, self.trBtnList_[6]:getRedPoint())
	xyd.models.backpack:checkCollectionShopRed()

	local funcs = {
		xyd.RedMarkType.STORY_LIST_MEMORY,
		xyd.RedMarkType.QUESTIONNAIRE,
		xyd.RedMarkType.GM_CHAT,
		xyd.RedMarkType.COMIC,
		xyd.RedMarkType.COLLECTION_SHOP,
		xyd.RedMarkType.COLLECTION_SHOP_2,
		xyd.RedMarkType.BACKGROUND,
		xyd.RedMarkType.COMMUNITY_ACTIVITY,
		xyd.RedMarkType.GAME_NOTICE
	}

	if xyd.Global.lang == "ko_kr" then
		funcs = {
			xyd.RedMarkType.STORY_LIST_MEMORY,
			xyd.RedMarkType.QUESTIONNAIRE,
			xyd.RedMarkType.GM_CHAT,
			xyd.RedMarkType.COMIC,
			xyd.RedMarkType.COLLECTION_SHOP,
			xyd.RedMarkType.COLLECTION_SHOP_2,
			xyd.RedMarkType.BACKGROUND,
			xyd.RedMarkType.GAME_NOTICE,
			xyd.RedMarkType.COMMUNITY_ACTIVITY
		}
	end

	xyd.models.redMark:setJointMarkImg(funcs, self.MainwinBottomBtn_red_img_6:getRedPoint())

	local data = xyd.models.activity:getBattlePassData()

	if data then
		xyd.models.redMark:setJointMarkImg({
			xyd.RedMarkType.BATTLE_PASS,
			xyd.RedMarkType.ACHIEVEMENT,
			xyd.RedMarkType.MISSION,
			xyd.RedMarkType.BATTLE_PASS_MISSION1,
			xyd.RedMarkType.BATTLE_PASS_MISSION2,
			xyd.RedMarkType.BATTLE_PASS_MISSION3
		}, self.btnMission_:getRedPoint())
		xyd.models.redMark:setJointMarkImg({
			xyd.RedMarkType.STORY_LIST_MEMORY,
			xyd.RedMarkType.QUESTIONNAIRE,
			xyd.RedMarkType.GM_CHAT,
			xyd.RedMarkType.COMIC,
			xyd.RedMarkType.BACKGROUND,
			xyd.RedMarkType.COMMUNITY_ACTIVITY
		}, self.MainwinBottomBtn_red_img_6:getRedPoint())
		data:getRedMarkState()
	else
		xyd.models.redMark:setMarkImg(xyd.RedMarkType.MISSION, self.btnMission_:getRedPoint())
		xyd.models.redMark:setJointMarkImg({
			xyd.RedMarkType.STORY_LIST_MEMORY,
			xyd.RedMarkType.QUESTIONNAIRE,
			xyd.RedMarkType.GM_CHAT,
			xyd.RedMarkType.COMIC,
			xyd.RedMarkType.BACKGROUND,
			xyd.RedMarkType.COMMUNITY_ACTIVITY
		}, self.MainwinBottomBtn_red_img_6:getRedPoint())
	end

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.TAVERN,
		xyd.RedMarkType.COFFEE_SHOP,
		xyd.RedMarkType.SKIN_SHOP,
		xyd.RedMarkType.ARENA_SHOP,
		xyd.RedMarkType.HOUSE,
		xyd.RedMarkType.DRESS_ITEM_CAN_UP,
		xyd.RedMarkType.SKIN_LEVEL_CAN_UP
	}, self.redPointSchool)
	xyd.models.dress:checkAllItemCanUpEveryDay()
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.TRIAL,
		xyd.RedMarkType.DUNGEON,
		xyd.RedMarkType.ARENA_3v3,
		xyd.RedMarkType.ARENA_TEAM,
		xyd.RedMarkType.HERO_CHALLENGE,
		xyd.RedMarkType.FRIEND_TEAM_BOSS,
		xyd.RedMarkType.ACADEMY_ASSESSMENT,
		xyd.RedMarkType.OLD_SCHOOL,
		xyd.RedMarkType.TOWER_FUND_GIFTBAG,
		xyd.RedMarkType.FRIEND_TEAM_BOSS_MSG,
		xyd.RedMarkType.FRIEND_TEAM_BOSS_MSG2,
		xyd.RedMarkType.TIME_CLOISTER_CAN_PROBE,
		xyd.RedMarkType.TIME_CLOISTER_PROBE_COMPLETED,
		xyd.RedMarkType.TIME_CLOISTER_ACHIEVEMENT,
		xyd.RedMarkType.TIME_CLOISTER_BATTLE,
		xyd.RedMarkType.ARENA_ALL_SERVER,
		xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_MISSION
	}, self.redPointBattle)
	self:updateLargeScrollerBtnRedPoint()
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.VIP_AWARD
	}, self.redIconVip.gameObject)
	xyd.models.slot:checkPromotablePartner()
	xyd.models.backpack:checkAvailableEquipment()
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.EXPLORE_OUPUT_AWARD,
		xyd.RedMarkType.EXPLORE_ADVENTURE_BOX_CAN_OPEN
	}, self.btnExplore_:getRedPoint())

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.YEARS_SUMMARY)

	if activityData then
		activityData:checkReadState()
	end

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.DAILY_QUIZ, self.btnQuiz_:getRedPoint())
end

function MainWindow:updateLargeScrollerBtnRedPoint()
	local iceRedPoint, returnBackPlayerRedPoint, sportsRedPoint, yearFundRedPoint = nil

	for i in pairs(self.largeBtnItemArr) do
		if self.largeBtnItemArr[i].id == xyd.RedMarkType.ICE_SECRET then
			iceRedPoint = self.largeBtnItemArr[i]:getRedPoint()
		end

		if self.largeBtnItemArr[i].id == xyd.RedMarkType.RETURN then
			returnBackPlayerRedPoint = self.largeBtnItemArr[i]:getRedPoint()
		end

		if self.largeBtnItemArr[i].id == xyd.RedMarkType.SPORTS then
			sportsRedPoint = self.largeBtnItemArr[i]:getRedPoint()
		end

		if self.largeBtnItemArr[i].id == xyd.RedMarkType.ACTIVITY_YEAR_FUND then
			yearFundRedPoint = self.largeBtnItemArr[i]:getRedPoint()
		end
	end

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.ICE_SECRET,
		xyd.RedMarkType.ACTIVITY_ICE_SECRET_GIFTBAG,
		xyd.RedMarkType.ACTIVITY_ICE_SECRET_MISSION,
		xyd.RedMarkType.ICE_SECRET_BOSS_CHALLENGE
	}, iceRedPoint)
	xyd.models.activity:setIceSecretRedMarkState()
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.ACTIVITY_YEAR_FUND
	}, yearFundRedPoint)
	xyd.models.activity:setIceSecretRedMarkState()
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.RETURN
	}, returnBackPlayerRedPoint)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.SPORTS
	}, sportsRedPoint)
	self:updateLatgeBtnRedPoint()
end

function MainWindow:initKaiXue()
	if not xyd.GuideController.get():isGuideComplete() or selfPlayer:isKaimenPlayed() and (not selfPlayer:ifCallback() or not not selfPlayer:ifCallbackAwarded()) then
		return
	end

	xyd.openWindow("kaixue_window")
end

function MainWindow:checkIfOldPlayerBack()
	local storyId = 1

	if selfPlayer:ifCallback() and not selfPlayer:ifCallbackAwarded() then
		xyd.WindowManager.get():openWindow("story_window", {
			story_id = storyId,
			story_type = xyd.StoryType.OLD_PLAYER_BACK,
			callback = function ()
				if not selfPlayer:ifCallbackAwarded() then
					xyd.WindowManager.get():openWindow("old_player_back_gift_window")
				end
			end
		})
	end
end

function MainWindow:leftFuncOpenAnimation(funID, pos)
	local btn = self.func2Btn[funID]

	if not btn then
		return
	end

	local obj = btn:getGameObject()
	local transform = obj.transform
	local pos = transform.localPosition
	local deltaPos = transform:InverseTransformPoint(pos)

	transform:SetLocalPosition(deltaPos.x, deltaPos.y, 0)
	obj:SetActive(true)

	local action = DG.Tweening.DOTween.Sequence():OnComplete(function ()
		self:afterLeftFuncOpen(btn)
	end)
	local scale = 68 / obj:GetComponent(typeof(UIWidget)).width

	action:Append(transform:DOScale(Vector3(scale, scale, 1), 0.4):Join(transform:DOLocalMove(pos), 0.4))
end

function MainWindow:beforeLeftFuncOpen(funID, pos)
	local btn = self.func2Btn[funID]

	if not btn then
		return
	end

	local obj = btn:getGameObject()

	obj:NodeByName("tr_btn_img"):SetActive(false)
	obj:NodeByName("tr_btn_label"):SetActive(false)

	local redPoint = obj:NodeByName("red_point").gameObject
	local preRedPoint = redPoint.activeSelf

	redPoint:SetActive(false)
	obj:SetActive(false)

	local icon = xyd.tables.functionTable:getIcon(funID)
	local sp = obj:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(sp, nil, icon, function ()
		sp:MakePixelPerfect()
	end)

	self.funcBtnInfo_ = {
		preRedPoint = preRedPoint
	}
end

function MainWindow:afterLeftFuncOpen(btn)
	if not btn then
		return
	end

	local obj = btn:getGameObject()

	obj:NodeByName("tr_btn_img"):SetActive(false)
	obj:NodeByName("tr_btn_label"):SetActive(false)
	obj:NodeByName("red_point"):SetActive(self.funcBtnInfo_.preRedPoint)

	local sp = obj:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(sp, nil, "left_btn_bg_v3")

	sp.width = 80
	sp.height = 83

	obj:SetLocalScale(1, 1, 1)
end

function MainWindow:checkFuncOpen(data, isShowTips)
	if isShowTips == nil then
		isShowTips = false
	end

	if data.func_id and not xyd.checkFunctionOpen(data.func_id, not isShowTips) then
		return false
	end

	return true
end

function MainWindow:judgePlayStoryDialog()
end

function MainWindow:updateStoryDialogData(stage, playNum, failNum)
	local str = xyd.db.misc:getValue("STORY_DIALOG_DATA")
	local data = {}

	if str then
		data = json.decode(str)
	end

	data = data or {
		failNum = 0,
		stage = -1,
		playNum = 0
	}

	if stage ~= data.stage then
		data = {
			failNum = 0,
			playNum = 0,
			stage = stage
		}
	end

	if playNum then
		data.playNum = data.playNum + playNum
	end

	if failNum then
		data.failNum = data.failNum + failNum
	end

	xyd.db.misc:addOrUpdate({
		key = "STORY_DIALOG_DATA",
		value = json.encode(data)
	})
end

function MainWindow:showGuideMask(isShow)
end

function MainWindow:playEnterSound()
	local soundManager = xyd.SoundManager.get()

	local function callback()
		if not soundManager:isPlayBg() then
			soundManager:playSound(xyd.Global.bgMusic)
		end
	end

	if soundManager:isEffectOn() then
		soundManager:playSound(xyd.SoundID.RING, callback)
	else
		callback()
	end
end

function MainWindow:initGiftbagPush()
	local GiftbagPushController = xyd.GiftbagPushController.get()

	GiftbagPushController:insertWindow(self.name_)

	if xyd.Global.lang ~= "ja_jp" then
		return
	end

	local GiftbagPushController2 = xyd.GiftbagPushController2.get()
end

function MainWindow:initPartnerSound()
	local PartnerSoundController = xyd.PartnerSoundController.get()

	PartnerSoundController:insertWindow(self.name_)
end

function MainWindow:initPartnerSwitchArrow()
	local chosenArray = xyd.models.selfPlayer:getAllChosenPartner()

	if #chosenArray == 1 then
		self.partnerSwitchArrow1:SetActive(false)
		self.partnerSwitchArrow2:SetActive(false)
	else
		self.partnerSwitchArrow1:SetActive(true)
		self.partnerSwitchArrow2:SetActive(true)
	end
end

function MainWindow:partnerSwitch(direction)
	xyd.models.selfPlayer:partnerSwitch(direction)
	MainMap.get():stopSound()
	MainMap.get():updateImg()
end

function MainWindow:iosTestChangeUI()
	self.top_bg = self.transTopTween:ComponentByName("top_M_group/top_bg", typeof(UISprite))
	self.vip_icon = self.groupVip:ComponentByName("icon", typeof(UISprite))
	self.actGroup1_icon = self.actGroup1:ComponentByName("icon", typeof(UISprite))
	self.actGroup2_icon = self.actGroup2:ComponentByName("icon", typeof(UISprite))
	self.actGroup3_icon = self.actGroup3:ComponentByName("e:image", typeof(UISprite))
	self.bottomBg = self.bottomGroup:ComponentByName("bottomBg", typeof(UISprite))

	xyd.setUISprite(self.top_bg, nil, "top_bg_r_v3_ios_test")
	xyd.setUISprite(self.mailBtn:GetComponent(typeof(UISprite)), nil, "right_mail_icon_v3")
	xyd.setUISprite(self.groupVip_bg:GetComponent(typeof(UISprite)), nil, "vip_bg_v3_ios_test")
	xyd.setUISprite(self.vip_icon, nil, "vip_icon_ios_test")
	xyd.setUISprite(self.actGroup1_icon, nil, "act_bg_img_v3_ios_test")
	xyd.setUISprite(self.actGroup2_icon, nil, "act_bg_img_2_v3_ios_test")
	xyd.setUISprite(self.actGroup3_icon, nil, "act_bg_img_4_v3_ios_test")
	xyd.setUISprite(self.newbieCampIcon:GetComponent(typeof(UISprite)), nil, "newbie_guide_icon_ios_test")
	xyd.setUISprite(self.btnChat:GetComponent(typeof(UISprite)), nil, "chat_icon_v3_ios_test")
	xyd.setUISprite(self.schoolBtn:GetComponent(typeof(UISprite)), nil, "top_school_icon_v3_ios_test")
	xyd.setUISprite(self.arenaBtn:GetComponent(typeof(UISprite)), nil, "top_arena_icon_v3_ios_test")
	xyd.setUISprite(self.btnStory:GetComponent(typeof(UISprite)), nil, "top_story_icon_v3_ios_test")

	for i = 1, 5 do
		local item = self.trBtnList_[i]

		xyd.setUISprite(item.transGo_sprite, nil, item.trans.img[item.id] .. "_ios_test")
	end

	for i = 1, 6 do
		local item = self.bottomBtnList_[i]

		xyd.setUISpriteAsync(item.iconImg_, nil, "bottom_icon_" .. item.id .. "_v3_ios_test")
		xyd.setUISprite(item.bgOnImg_, nil, "bottom_btn_bg02_v3_ios_test")
	end

	xyd.setUISprite(self.bottomBg, nil, "bottom_bg_r_v3_ios_test")

	for i = 1, #self.largeBtnItemArr do
		local item = self.largeBtnArr[i]

		if LARGE_BTN_IMG_NAME[self.id] ~= nil then
			xyd.setUISpriteAsync(item.img, nil, LARGE_BTN_IMG_NAME[self.id] .. "_ios_test")
		end
	end

	xyd.setUISprite(self.mailBtn:GetComponent(typeof(UISprite)), nil, "right_mail_icon_v3_ios_test")

	for i = 1, #self.largeBtnItemArr do
		local img = self.largeBtnItemArr[i].img

		xyd.setUISprite(img, nil, img.spriteName .. "_ios_test")
	end

	self.btnChat:SetActive(false)
end

function MainWindow:initStoryBtnDianjiEffect()
	if self.hand then
		self.hand:play("texiao01", 0)
	else
		local model = xyd.Spine.new(self.dianjiGroup)

		model:setInfo("fx_ui_dianji", function ()
			model:SetLocalScale(1, 1, 1)
			model:SetLocalPosition(0, 0, 0)
			model:play("texiao01", 0)
		end)

		self.hand = model
	end
end

function MainWindow:initStoryTimer()
	if self.notShowMapAlert then
		return
	end

	if xyd.models.map:checkIsCampaignEnd() then
		self.notShowMapAlert = true

		return
	end

	self:waitForTime(2, function ()
		if self.curHideType ~= MainWindow.HideType.KIND0 then
			return
		end

		local alertData = xyd.db.misc:getValue("map_alert_times") or "{}"
		local alertTimes = json.decode(alertData)
		local todayTimes = {}

		if alertTimes and next(alertTimes) then
			for k, v in ipairs(alertTimes) do
				if xyd.isToday(v) then
					table.insert(todayTimes, v)
				end
			end
		end

		if #todayTimes >= 4 then
			self.notShowMapAlert = true

			return
		end

		table.insert(todayTimes, xyd.getServerTime())
		xyd.db.misc:setValue({
			key = "map_alert_times",
			value = json.encode(todayTimes)
		})
		self:showHand(true)
	end, "map_alert_times")
end

function MainWindow:init3D()
	local ngui3DNode = xyd.ngui3DNode.get()
	local params = {
		showTexture = self.showTexture,
		width = self.showTexture.width,
		height = self.showTexture.height
	}

	ngui3DNode:setInfo(params)
end

function MainWindow:showTestCode()
	import("app.common.ui.TestShowCode").new(self.window_)
end

function MainWindow:onWindowOpen(event)
	if not self.win_list_ then
		self.win_list_ = {
			"main_window"
		}
	end

	local windowName = event.params.windowName

	if windowName == "float_message_window2" or windowName == "float_message_window2" then
		return
	end

	table.insert(self.win_list_, windowName)
end

function MainWindow:onWindowClose(event)
	if not self.win_list_ then
		self.win_list_ = {
			"main_window"
		}
	end

	local win_name = event.params.windowName
	local ind = xyd.arrayIndexOf(self.win_list_, win_name)

	if ind == -1 then
		return
	end

	table.remove(self.win_list_, ind)

	local loading_ind = xyd.arrayIndexOf(self.win_list_, "loading_window")

	if loading_ind ~= -1 then
		table.remove(self.win_list_, loading_ind)
	end

	if not self.win_list_ or #self.win_list_ <= 0 then
		return
	end

	local windowNum = #self.win_list_

	if self.win_list_[1] == "main_window" and #self.win_list_ == 1 and win_name ~= "func_open_window" and win_name ~= "guide_window" and not self.isJumping then
		self.leftUpCon:updateMaskActArrowRedPoint()

		if win_name ~= "edit_picture_window" then
			local showRandom = tonumber(xyd.db.misc:getValue("kbn_show_random")) == 1 and true or false
			local windowType = xyd.tables.windowTable:getLayerType(win_name)

			if showRandom and windowType == xyd.UILayerType.FULL_SCREEN_UI then
				self:backToMainWindowUpdatePartner()
			end
		end
	end

	if self.win_list_[1] == "main_window" and #self.win_list_ == 1 then
		self:checkTrBtn()
	end

	if self.win_list_ and windowNum <= 3 then
		local missWindow = {
			activity_point_tips_window = 2,
			loading_window = 1
		}

		for i = 1, #self.win_list_ do
			if missWindow[self.win_list_[i]] then
				windowNum = windowNum - 1
			end
		end
	end

	if self.win_list_[1] == "main_window" and windowNum == 1 and win_name ~= "func_open_window" and win_name ~= "guide_window" and not self.isJumping and xyd.GuideController.get():isGuideComplete() and self.hasEvaluateWindow then
		xyd.openWindow("evaluate_window", {
			evaluationWhereFrom = self.evaluationWhereFrom
		})

		self.evaluationWhereFrom = nil
		self.hasEvaluateWindow = nil
	end
end

function MainWindow:updateBtnNotice()
	print("=============updateBtnNotice=========")

	if xyd.models.settingUp:checkNoticeShow() then
		self.btnNotice:SetActive(true)
		self:waitForFrame(1, function ()
			if not self.noticeEffect then
				self.noticeEffect = xyd.Spine.new(self.btnNoticeEffect)

				self.noticeEffect:setInfo("fx_icon_main_notice_bell", function ()
					self.noticeEffect:play("idle", 0, 1)
				end)
			else
				self.noticeEffect:play("idle", 0, 1)
			end
		end)
	elseif self.noticeEffect then
		self.noticeEffect:play("hide", 1, 1)

		local sequence = self:getSequence(function ()
			self.btnNotice:SetActive(false)
		end, true)

		sequence:Insert(0, self.btnNotice.transform:DOLocalMove(Vector3(300, -180, 0), 1))
	else
		self.btnNotice:SetActive(false)
	end
end

function MainWindow:setHasEvaluateWindow(flag, whereFrom)
	local playerLev = xyd.models.backpack:getLev()
	local limitLev = xyd.tables.miscTable:getNumber("new_pingfen_level_limit", "value") or 10

	print(limitLev)

	if playerLev < limitLev then
		return
	end

	self.hasEvaluateWindow = flag
	self.evaluationWhereFrom = whereFrom
end

function MainWindow:backToMainWindowUpdatePartner()
	xyd.models.selfPlayer:backToMainWindowUpdatePartner()
	MainMap.get():stopSound()
	MainMap.get():updateImg()
	MainMap.get():resetPlayDialog()
end

function MainWindow:setStopClickBottomBtn(flag)
	self.stopClickBottomBtn = flag
end

return MainWindow
