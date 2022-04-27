local ActivityReturnActiveWindow = class("ActivityReturnActiveWindow", import(".BaseWindow"))
local tMissionItem = class("tMissionItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local WindowTop = import("app.components.WindowTop")
local CommonTabBar = import("app.common.ui.CommonTabBar")

function ActivityReturnActiveWindow:ctor(name, params)
	ActivityReturnActiveWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.RETURN)

	dump(self.activityData.detail)

	self.cur_select_ = 1
end

function ActivityReturnActiveWindow:initWindow()
	ActivityReturnActiveWindow.super.initWindow(self)
	self:getComponent()
	self:initTop()
	self:layouUI()
	self:register()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.RETURN)

	self.hasNotGetData_ = true
end

function ActivityReturnActiveWindow:getComponent()
	local winTrans = self.window_:NodeByName("actionGroup")
	self.logoImg_ = winTrans:ComponentByName("logoRoot/logoImg", typeof(UITexture))
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.timeLabel_ = winTrans:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.countLabel_ = winTrans:ComponentByName("timeGroup/countLabel", typeof(UILabel))
	self.navGroup_ = winTrans:NodeByName("content/navGroup").gameObject
	self.teamGroup_ = winTrans:NodeByName("content/teamGroup").gameObject
	self.infoGroup_ = winTrans:NodeByName("content/infoGroup").gameObject
	self.scrollTeam_ = self.teamGroup_:ComponentByName("scrollTeam", typeof(UIScrollView))
	self.scrollTeam_grid_ = self.teamGroup_:ComponentByName("scrollTeam/grid", typeof(MultiRowWrapContent))
	self.tMissionItem_ = self.teamGroup_:NodeByName("missionItem").gameObject
	self.teamerGroupTitle_ = self.teamGroup_:ComponentByName("groupTeamer/teamerGroupTitle", typeof(UILabel))
	self.noBindTeamerTips_ = self.teamGroup_:ComponentByName("groupTeamer/noBindTeamerTips", typeof(UILabel))
	self.groupTeamerInfo_ = self.teamGroup_:NodeByName("groupTeamer/groupTeamerInfo").gameObject
	self.teamerPlayerIconRoot_ = self.groupTeamerInfo_:NodeByName("playerIcon").gameObject
	self.teamerPlayerName_ = self.groupTeamerInfo_:ComponentByName("playerName", typeof(UILabel))
	self.teamerIdLabel_ = self.groupTeamerInfo_:ComponentByName("idLabel", typeof(UILabel))
	self.teamerPlayerId_ = self.groupTeamerInfo_:ComponentByName("playerId", typeof(UILabel))
	self.teamerServerLabel_ = self.groupTeamerInfo_:ComponentByName("serverGroup/labelServer", typeof(UILabel))
	self.multiWrapTeam_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollTeam_, self.scrollTeam_grid_, self.tMissionItem_, tMissionItem, self)
	self.labelBindCode_ = self.infoGroup_:ComponentByName("bindCodeGroup/labelBindCode", typeof(UILabel))
	self.copyBtn_ = self.infoGroup_:NodeByName("bindCodeGroup/copyBtn").gameObject
	self.labelBindTips_ = self.infoGroup_:ComponentByName("bindCodeGroup/labelBindTips", typeof(UILabel))
	self.bindInfo1 = self.infoGroup_:NodeByName("teamerInfoGroup/bindInfo1").gameObject
	self.hasInfo1 = self.infoGroup_:NodeByName("teamerInfoGroup/bindInfo1/hasInfo").gameObject
	self.playerIconRoot1 = self.hasInfo1:NodeByName("playerIconRoot").gameObject
	self.playerName1 = self.hasInfo1:ComponentByName("playerName", typeof(UILabel))
	self.conditionLabel1 = self.hasInfo1:ComponentByName("conditionLabel", typeof(UILabel))
	self.compImg1 = self.hasInfo1:NodeByName("compImg").gameObject
	self.bindInfo2 = self.infoGroup_:NodeByName("teamerInfoGroup/bindInfo2").gameObject
	self.hasInfo2 = self.infoGroup_:NodeByName("teamerInfoGroup/bindInfo2/hasInfo").gameObject
	self.playerIconRoot2 = self.hasInfo2:NodeByName("playerIconRoot").gameObject
	self.playerName2 = self.hasInfo2:ComponentByName("playerName", typeof(UILabel))
	self.conditionLabel2 = self.hasInfo2:ComponentByName("conditionLabel", typeof(UILabel))
	self.compImg2 = self.hasInfo2:NodeByName("compImg").gameObject
	self.applyListBtn_ = self.infoGroup_:NodeByName("teamerInfoGroup/applyListBtn").gameObject
	self.applyListBtn_redPoint = self.infoGroup_:NodeByName("teamerInfoGroup/applyListBtn/redPoint").gameObject
	self.applyListBtn_label = self.infoGroup_:ComponentByName("teamerInfoGroup/applyListBtn/label", typeof(UILabel))
	self.applyListBtn_mask = self.infoGroup_:NodeByName("teamerInfoGroup/applyListBtn/mask").gameObject
	self.infoTipsLabel_ = self.infoGroup_:ComponentByName("teamerInfoGroup/infoTipsLabel", typeof(UILabel))
	self.contentGroupList_ = {
		self.infoGroup_,
		[2] = self.teamGroup_
	}
end

function ActivityReturnActiveWindow:register()
	ActivityReturnActiveWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onGetActivityInfo))
	self.eventProxy_:addEventListener(xyd.event.RETURN_ACTIVITY_ACCEPT_APPLY, handler(self, self.onAcceptTeamer))

	UIEventListener.Get(self.copyBtn_).onClick = function ()
		local id = xyd.models.selfPlayer:getPlayerID()

		xyd.SdkManager:get():copyToClipboard(tostring(id))
		xyd.showToast(__("COPY_SELF_ID_SUCCESSFUL"))
	end

	UIEventListener.Get(self.applyListBtn_).onClick = function ()
		self.applyListBtn_redPoint:SetActive(false)
		self.activityData:setDefRedMark(false)
		xyd.models.redMark:setMark(xyd.RedMarkType.RETURN, self.activityData:getRedMarkState())
		xyd.WindowManager.get():openWindow("activity_return_apply_list_window", {
			apply_list = self.activityData.detail.apply_list,
			applyListInfo = self.activityData.detail.apply_show_info
		})
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_RETURN_WINDOW_HELP"
		})
	end
end

function ActivityReturnActiveWindow:layouUI()
	xyd.setUITextureByNameAsync(self.logoImg_, "activity_return_mission_logo_" .. xyd.Global.lang, true)

	self.timeLabel_.text = __("ACTIVITY_PLAYER_RETURN_ALLTIME")
	self.teamerGroupTitle_.text = __("ACTIVITY_RETURN_PERSONAL_FRIEND_TIPS")
	self.labelBindTips_.text = __("ACTIVITY_RETURN_CDKEY")
	self.noBindTeamerTips_.text = __("ACTIVITY_RETURN_PERSONAL_FRIEND_NONE")
	self.applyListBtn_label.text = __("ACTIVITY_RETURN_APPLY_LIST_WINDOW")
	self.infoTipsLabel_.text = __("ACTIVITY_RETURN_COMPANY_LIST")

	self:startCountDown()
	self:initNav()
end

function ActivityReturnActiveWindow:onGetActivityInfo()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.RETURN)
	self.hasNotGetData_ = false

	if self.tab_ then
		self.tab_:setTabActive(self.cur_select_, true)
	end
end

function ActivityReturnActiveWindow:initTop()
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

function ActivityReturnActiveWindow:startCountDown()
	local params = {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	}

	if not self.countDown_ then
		self.countDown_ = CountDown.new(self.countLabel_, params)
	else
		self.countDown_:setInfo(params)
	end
end

function ActivityReturnActiveWindow:initNav()
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
		self.tab_ = CommonTabBar.new(self.navGroup_, 2, function (index)
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

			if self.hasNotGetData_ then
				return
			end

			self:refreshContent(index)
		end, nil, colorParams)
		local tableLabels = {
			__("ACT_RETURN_PERSONAL_NAV_4"),
			__("ACT_RETURN_PERSONAL_NAV_2")
		}

		self.tab_:setTexts(tableLabels)
	end
end

function ActivityReturnActiveWindow:refreshContent(index)
	for i = 1, 2 do
		self.contentGroupList_[i]:SetActive(index == i)
	end

	self.cur_select_ = index

	if self.cur_select_ == 1 then
		self:refreshTInfoPart()
	elseif self.cur_select_ == 2 then
		self:refreshTMissionPart()
	end
end

function ActivityReturnActiveWindow:onAcceptTeamer(event)
	local data = event.data
	local detail = self.activityData.detail
	detail.buy_times = data.buy_times
	detail.accept_list = data.accept_list
	detail.apply_show_info = data.apply_show_info
	detail.accept_show_info = data.accept_show_info
	detail.bind_player_id = data.bind_player_id
	detail.other_info = data.other_info

	self:refreshTInfoPart()
end

function ActivityReturnActiveWindow:refreshTInfoPart()
	self.labelBindCode_.text = xyd.models.selfPlayer:getPlayerID()
	self.acceptList_ = self.activityData.detail.accept_list
	self.acceptInfoList_ = self.activityData.detail.accept_show_info
	self.needRedPoint_ = self.activityData:getRedMarkState()

	for i = 1, 2 do
		local playerInfo = self.acceptInfoList_[i]

		if not playerInfo then
			self["hasInfo" .. i]:SetActive(false)
		else
			self["hasInfo" .. i]:SetActive(true)
			self:refreshTeamerInfoIcon(i)
		end
	end

	local canOpenApplyWindow = not self.acceptInfoList_ or not self.acceptInfoList_[1] or #self.acceptInfoList_ == 2 and not self.hasCompAllMission or self.hasCompAllMission and #self.acceptInfoList_ == 1

	self.applyListBtn_mask:SetActive(not canOpenApplyWindow)

	if canOpenApplyWindow and self.needRedPoint_ then
		self.applyListBtn_redPoint:SetActive(true)
	end
end

function ActivityReturnActiveWindow:refreshTeamerInfoIcon(index)
	local playerInfo = self.acceptInfoList_[index]

	if playerInfo then
		self["playerName" .. index].text = playerInfo.player_name
		local playerInfo = {
			avatarID = playerInfo.avatar_id,
			avatar_frame_id = playerInfo.avatar_frame_id,
			lev = playerInfo.lev
		}

		function playerInfo.callback()
			xyd.WindowManager.get():openWindow("arena_formation_window", {
				is_robot = false,
				player_id = playerInfo.player_id
			})
		end

		if not self["teamerIcon" .. index] then
			self["teamerIcon" .. index] = import("app.components.PlayerIcon").new(self["playerIconRoot" .. index])

			self["teamerIcon" .. index]:setInfo(playerInfo)
		else
			self["teamerIcon" .. index]:setInfo(playerInfo)
		end
	end

	if index == #self.acceptInfoList_ then
		self.hasCompAllMission = self:checkCompMission()

		if self.hasCompAllMission then
			self["compImg" .. index]:SetActive(true)

			self["conditionLabel" .. index].text = __(" ")
		else
			self["compImg" .. index]:SetActive(false)

			self["conditionLabel" .. index].text = __("ACTIVITY_RETURN_IS_BINDING")
		end
	elseif index < #self.acceptInfoList_ then
		self["compImg" .. index]:SetActive(true)

		self["conditionLabel" .. index].text = __(" ")
	end
end

function ActivityReturnActiveWindow:checkCompMission()
	self.tMissionAwarded_ = self.activityData.detail.t_mis_awarded or {}
	local tMissionList = xyd.tables.activityReturnTMissionTable:getIds()

	for _, missionId in ipairs(tMissionList) do
		if not self.tMissionAwarded_[missionId] or self.tMissionAwarded_[missionId] == 0 then
			return false
		end
	end

	return true
end

function ActivityReturnActiveWindow:refreshTMissionPart()
	self:refreshTeamerInfo()
	self:refreshTmissionList()
end

function ActivityReturnActiveWindow:refreshTeamerInfo()
	if not self.acceptInfoList_ or not self.acceptInfoList_[1] or #self.acceptInfoList_ == 1 and self.hasCompAllMission then
		self.noBindTeamerTips_.gameObject:SetActive(true)
		self.groupTeamerInfo_:SetActive(false)
	else
		self.groupTeamerInfo_:SetActive(true)
		self.noBindTeamerTips_.gameObject:SetActive(false)
		self:refreshTeamerIcon()
	end
end

function ActivityReturnActiveWindow:refreshTeamerIcon()
	if #self.acceptInfoList_ == 2 then
		self.teamerInfo_ = self.acceptInfoList_[2]
	elseif #self.acceptInfoList_ == 1 and not self.hasCompAllMission then
		self.teamerInfo_ = self.acceptInfoList_[1]
	else
		return
	end

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

function ActivityReturnActiveWindow:refreshTmissionList(keepPosition)
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
	self.itemRoot_ = goTrans:ComponentByName("itemRoot", typeof(UILayout))
	self.goBtnMask_ = goTrans:NodeByName("goBtn/mask").gameObject
	self.goBtnLabel_.text = __("GO")

	xyd.setUISpriteAsync(self.imgMask_, nil, "mission_awarded_" .. xyd.Global.lang)
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
	self.awards_ = xyd.tables.activityReturnTMissionTable:getAward2(self.id_)
	self.goWindow_ = xyd.tables.activityReturnTMissionTable:getGoWindow(self.id_)

	self:refreshUI()
end

function tMissionItem:refreshUI()
	self.missionName_.text = __(self.desc_)
	local params = {
		itemID = tonumber(self.awards_[1]),
		num = tonumber(self.awards_[2]),
		uiRoot = self.itemRoot_.gameObject
	}

	if not self.awardIcon_ then
		self.awardIcon_ = xyd.getItemIcon(params)
	else
		NGUITools.Destroy(self.awardIcon_:getGameObject())

		self.awardIcon_ = xyd.getItemIcon(params)
	end

	if self.limitTimes_ <= self.compTime_ and (#self.parent_.acceptInfoList_ ~= 1 or not self.parent_.hasCompAllMission) then
		self.progressBarPerson_.value = 1
		self.progressBarPersonLabel_.text = self.completeValue1_ .. "/" .. self.completeValue1_
		self.progressBarTeamer_.value = 1
		self.progressBarTeamerLabel_.text = self.completeValue2_ .. "/" .. self.completeValue2_

		self.imgMask_:SetActive(true)

		self.goBtnBox_.enabled = false

		self.goBtn_:SetActive(false)
	elseif #self.parent_.acceptInfoList_ == 1 and self.parent_.hasCompAllMission then
		self.progressBarPerson_.value = 0
		self.progressBarTeamer_.value = 0
		self.progressBarPersonLabel_.text = "0/" .. self.completeValue1_
		self.progressBarTeamerLabel_.text = "0/" .. self.completeValue2_
		self.goBtnBox_.enabled = false

		self.imgMask_:SetActive(false)
		self.goBtn_:SetActive(true)
	else
		self.progressBarPerson_.value = self.count_ / self.completeValue1_
		self.progressBarTeamer_.value = self.teamerCount_ / self.completeValue2_
		self.progressBarPersonLabel_.text = self.count_ .. "/" .. self.completeValue1_
		self.progressBarTeamerLabel_.text = self.teamerCount_ .. "/" .. self.completeValue2_
		self.goBtnBox_.enabled = true

		self.goBtn_:SetActive(true)
		self.imgMask_:SetActive(false)
	end

	if self:checkHideGoBtn() then
		self.goBtnMask_:SetActive(true)

		self.goBtnBox_.enabled = false
		self.goBtnLabel_.text = __("ACTIVITY_RETURN_MISSION_NO_BIND")
	elseif not self.goWindow_ or self.goWindow_ == "" then
		self.goBtnMask_:SetActive(false)

		self.goBtnBox_.enabled = false
		self.goBtnLabel_.text = __("ACTIVITY_RETURN_WAITING_FOR_FINISH")
	else
		self.goBtnBox_.enabled = true

		self.goBtnMask_:SetActive(false)

		self.goBtnLabel_.text = __("GO")
	end
end

function tMissionItem:checkHideGoBtn()
	if self.parent_.hasCompAllMission or not self.parent_.activityData.detail.other_info then
		return true
	else
		return false
	end
end

function ActivityReturnActiveWindow:willClose()
	ActivityReturnActiveWindow.super.willClose(self)

	if self.countDown_ then
		self.countDown_:stopTimeCount()
	end
end

return ActivityReturnActiveWindow
