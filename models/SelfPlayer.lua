local SelfPlayer = class("SelfPlayer", import("app.models.Player"))
local PlayerPrefs = UnityEngine.PlayerPrefs
local itemTable = xyd.tables.itemTable
local OnlineTable = xyd.tables.onlineTable
local JSON = require("cjson")

function SelfPlayer:ctor(...)
	SelfPlayer.super.ctor(self, ...)

	self.signeds_ = {}
	self.guides_ = {}
	self.openedFuncsIds_ = {}
	self.monthlyGifts_ = {}
	self.monthlyCanBuyGifts_ = {}
	self.tasks_ = nil
	self.firstTimeInfo_ = {}
	self.time = 0
	self.uid_ = nil
	self.token_ = ""
	self.tili_ = 0
	self.vip_ = 0
	self.avatarID_ = 0
	self.avatarFrameID_ = 0
	self.exp_ = 0
	self.pictureID_ = 0
	self.picturePartnerId_ = 0
	self.vipPoint_ = 0
	self.vipEndTime_ = 0
	self.tomorrowTime_ = 0
	self.languageCode_ = 1
	self.signature_ = ""
	self.nextDayTime = 0
	self.serverID_ = 1
	self.kaimenPlayed = 0
	self.shouchongDisplayed = 0
	self.isCallback = 0
	self.callbackAwarded = 0
	self.lastLoginTime = 0
	self.isShowOnlineAwardRedMark = false

	self:setupMidToEventNameMappings_()

	self.globalTimerCallBack = {}
	self.slotChangeTableId = {}
	self.globalTimer_Keyid = 1

	self:initGlobalTimer()
end

function SelfPlayer:disposeAll()
	SelfPlayer.super.disposeAll(self)

	if self.globalTimer_ then
		self.globalTimer_:Stop()
	end
end

function SelfPlayer:initGlobalTimer()
	if self.globalTimer_ then
		self.globalTimer_:Stop()
	end

	self.globalTimer_ = Timer.New(handler(self, self.updateGbobalTimer), 1, -1, false)

	self.globalTimer_:Start()
end

function SelfPlayer:updateGbobalTimer()
	for i in ipairs(self.globalTimerCallBack) do
		if self.globalTimerCallBack ~= nil and self.globalTimerCallBack[i] ~= nil then
			self.globalTimerCallBack[i].time_yet = self.globalTimerCallBack[i].time_yet + 1

			if self.globalTimerCallBack[i].timeDis <= self.globalTimerCallBack[i].time_yet then
				if self.globalTimerCallBack[i] ~= nil then
					self.globalTimerCallBack[i].callBack()
				end

				if self.globalTimerCallBack[i] ~= nil then
					self.globalTimerCallBack[i].time_yet = 0

					if self.globalTimerCallBack[i].alltimes ~= -1 then
						self.globalTimerCallBack[i].already_Times = self.globalTimerCallBack[i].already_Times + 1

						if self.globalTimerCallBack[i].alltimes <= self.globalTimerCallBack[i].already_Times then
							table.remove(self.globalTimerCallBack, i)
						end
					end
				end
			end
		end
	end
end

function SelfPlayer:addGlobalTimer(callBack, timeDis, alltimes)
	if timeDis == nil then
		timeDis = 1
	end

	if alltimes == nil then
		alltimes = -1
	end

	local timeParams = {
		already_Times = 0,
		time_yet = 0,
		callBack = callBack,
		timeDis = timeDis,
		alltimes = alltimes,
		keyid = self.globalTimer_Keyid
	}
	self.globalTimer_Keyid = self.globalTimer_Keyid + 1

	table.insert(self.globalTimerCallBack, timeParams)

	return timeParams.keyid
end

function SelfPlayer:removeGlobalTimer(keyId)
	for i in pairs(self.globalTimerCallBack) do
		if self.globalTimerCallBack[i] ~= nil and self.globalTimerCallBack[i].keyid == keyId then
			table.remove(self.globalTimerCallBack, i)

			break
		end
	end
end

function SelfPlayer:initDailyTimer()
	self.time = xyd.getServerTime()
	self.nextDayTime = (math.floor(self.time / 86400) + 1) * 60 * 60 * 24
	self.timer_ = Timer.New(handler(self.updateTimer), 1, -1, false)

	self.timer_:Start()
end

function SelfPlayer:updateTimer()
	self.time = xyd.getServerTime()
end

function SelfPlayer:getReserveTime()
	return xyd.secondsToString(self.nextDayTime - self.time)
end

function SelfPlayer:onRegister()
	SelfPlayer.super.onRegister(self)
	self:registerEvent(xyd.event.GET_LOGIN_INFO, handler(self, self.onLoginInfo_))
	self:registerEvent(xyd.event.EDIT_PLAYER_AVATAR, handler(self, self.onAvatarChange))
	self:registerEvent(xyd.event.EDIT_PLAYER_AVATAR_FRAME, handler(self, self.onAvatarFrameChange))
	self:registerEvent(xyd.event.EDIT_PLAYER_NAME, handler(self, self.onEditName))
	self:registerEvent(xyd.event.ONLINE_GET_AWARD, handler(self, self.onlineInfo))
	self:registerEvent(xyd.event.EDIT_PLAYER_PICTURE, handler(self, self.onEditPicture))
	self:registerEvent(xyd.event.ITEM_AWARD, handler(self, self.onItemAward))
	self:registerEvent(xyd.event.SERVER_BROADCAST, handler(self, self.onServerBroadCast))
	self:registerEvent(xyd.event.ANSWER_QUESTIONNAIRE, handler(self, self.onAnswerQuestion))
	self:registerEvent(xyd.event.BACK_QUESTION, handler(self, self.onBackQustion))
	self:registerEvent(xyd.event.NEW_PLAYER_TIPS_BACK, handler(self, self.onNewPlayerTipsInfo))
end

function SelfPlayer:onAnswerQuestion(event)
	local data = event.data
	local type = data.questionnaire_type

	for i = 1, #self.questionnaire_info_ do
		if self.questionnaire_info_[i].questionnaire_type == type then
			self.questionnaire_info_[i].current_id = data.current_id
			self.questionnaire_info_[i].is_finished = data.is_finished

			break
		end
	end

	if type == 2 then
		local is_finish = data.is_finished

		if is_finish then
			RedMark.get():setMark(xyd.RedMarkType.QUESTIONNAIRE, false)
		else
			RedMark.get():setMark(xyd.RedMarkType.QUESTIONNAIRE, true)
		end
	end
end

function SelfPlayer:onBackQustion(event)
	local data = event.data
	local type = data.questionnaire_type

	for i = 1, #self.questionnaire_info_ do
		if self.questionnaire_info_[i].questionnaire_type == type then
			self.questionnaire_info_[i].current_id = data.question_id

			break
		end
	end
end

function SelfPlayer:initModelAfterLogin()
	local modelList = {
		"backpack",
		"map",
		"slot",
		"summon",
		"activity",
		"guild",
		"petSlot",
		"arena",
		"arenaTeam",
		"chat",
		"dungeon",
		"achievement",
		"arena3v3",
		"midas",
		"background",
		"newbieCamp",
		"shop",
		"friend",
		"friendTeamBoss",
		"mail",
		"tavern",
		"vip",
		"imgGuide",
		"comic",
		"mission",
		"trial",
		"error",
		"advertiseComplete",
		"floatMessage2",
		"functionOpen",
		"acDFA",
		"academyAssessment",
		"oldSchool",
		"exploreModel",
		"storyListModel",
		"activityPointTips",
		"petTraining",
		"dress",
		"community",
		"arenaAllServerScore",
		"shrine"
	}

	for _, v in ipairs(modelList) do
		local m = xyd.models[v]
	end
end

function SelfPlayer:loginEvent_(params)
	self.loginParams_ = params
	self.uid_ = params.uid
	self.playerID_ = params.player_id
	self.token_ = params.token
	self.serverID_ = params.server_id
	xyd.Global.token = params.token
	xyd.Global.uid = params.uid
	xyd.Global.playerID = params.player_id
	xyd.Global.serverDeltaTime = params.server_time - os.time()
	xyd.Global.selfLoginTime = params.server_time

	if params.is_new ~= nil then
		xyd.Global.isANewPlayer_ = params.is_new
	end

	xyd.SdkManager.get():trackStart(tostring(xyd.Global.playerID))
	self:initModelAfterLogin()
end

function SelfPlayer:getQuestionnaireInfo()
	return self.questionnaire_info_
end

function SelfPlayer:onLoginInfo_(event)
	local params = event.data
	self.questionnaire_info_ = params.questionnaire

	if tostring(params.ban_room_info) and #tostring(params.ban_room_info) > 0 then
		self.banRoomInfo_ = {
			is_banned = params.ban_room_info.is_banned,
			ban_until_time = params.ban_room_info.ban_until_time
		}
	end

	self:onPlayerInfo_({
		name = xyd.event.PLAYER_INFO,
		data = params.player_info
	})
	xyd.EventDispatcher:outer():dispatchEvent({
		name = xyd.event.GET_MAP_INFO,
		data = params.map_info
	})
	xyd.EventDispatcher:outer():dispatchEvent({
		name = xyd.event.GET_BACKPACK_INFO,
		data = params.backpack_info
	})
	xyd.EventDispatcher:outer():dispatchEvent({
		name = xyd.event.GET_SUMMON_INFO,
		data = params.summon_info
	})

	if params.guild_skill_info then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GUILD_GET_SKILLS,
			data = params.guild_skill_info
		})
	end

	if params.chime_info then
		print("================================")
		dump(params.chime_info)
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_CHIME_INFO,
			data = params.chime_info
		})
	end

	xyd.EventDispatcher:outer():dispatchEvent({
		name = xyd.event.GET_SLOT_INFO,
		data = params.slot_info
	})
	xyd.EventDispatcher:outer():dispatchEvent({
		name = xyd.event.GET_MIDAS_INFO,
		data = params.midas_info
	})

	if tostring(params.background_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_BACKGROUND_LIST,
			data = params.background_info
		})
	end

	if tostring(params.rookie_mission_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_ROOKIE_MISSION_LIST,
			data = params.rookie_mission_info
		})
	end

	if tostring(params.show_window_info) ~= "" then
		xyd.models.dressShow:setShowWindowInfo(params.show_window_info)
	end

	xyd.GuideController.get():initGuideData({
		name = xyd.event.GET_GUIDE_INFO,
		data = params.guide_info
	})
	xyd.models.chat:getPlayerList()
	xyd.models.chat:getBlackList()
	xyd.EventDispatcher:outer():dispatchEvent({
		name = xyd.event.GET_SHOP_INFO,
		data = params.shop_info
	})

	if tostring(params.mission_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_MISSION_LIST,
			data = params.mission_info
		})
	end

	xyd.EventDispatcher:outer():dispatchEvent({
		name = xyd.event.GET_ACHIEVEMENT_LIST,
		data = params.achievement_info
	})

	if tostring(params.mails_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.MAIL_LIST,
			data = params.mails_info
		})
	end

	if tostring(params.pub_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.PUB_GET_LIST,
			data = params.pub_info
		})
	end

	if tostring(params.dungeon_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.DUNGEON_GET_MAP_INFO,
			data = params.dungeon_info
		})
	end

	if tostring(params.message_infos) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_MESSAGE_INFOS,
			data = params.message_infos
		})
	end

	if tostring(params.talk_list) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_TALK_LIST,
			data = params.talk_list
		})
	end

	if tostring(params.school_practise_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.SCHOOL_PRACTICE_INFO,
			data = params.school_practise_info
		})
	end

	if tostring(params.arena_rank_list) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_RANK_LIST,
			data = params.arena_rank_list
		})
	end

	if tostring(params.arena_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_ARENA_INFO,
			data = params.arena_info
		})
	end

	if tostring(params.top_arena_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_ARENA_3v3_INFO,
			data = params.top_arena_info
		})
	end

	if tostring(params.team_arena_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_ARENA_TEAM_INFO,
			data = params.team_arena_info
		})
	end

	xyd.models.arenaTeam:reqApplyList()
	xyd.models.arenaTeam:reqInviteTeams()

	if tostring(params.activity_list) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_ACTIVITY_LIST,
			data = params.activity_list
		})
	end

	if tostring(params.friend_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.FRIEND_GET_INFO,
			data = params.friend_info
		})
	end

	if tostring(params.message_pushes) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.DEVICE_NOTIFY_INFO,
			data = params.message_pushes
		})
	end

	if tostring(params.trial_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.TRIAL_INFO,
			data = params.trial_info
		})
	end

	if tostring(params.partner_achievement_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.LOAD_PARTNER_ACHIEVEMENT,
			data = params.partner_achievement_info
		})
	end

	if tostring(params.guild_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GUILD_GET_INFO,
			data = params.guild_info
		})
	end

	if tostring(params.pet_infos) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_PET_LIST,
			data = params.pet_infos
		})
	end

	if tostring(params.version_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.ON_VERSION_CODE,
			data = params.version_info
		})
	end

	if tostring(params.friend_team_boss_apply_list) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.FRIEND_TEAM_BOSS_GET_APPLY_LIST,
			data = params.friend_team_boss_apply_list
		})
	end

	if tostring(params.friend_team_boss_invite_list) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.FRIEND_TEAM_BOSS_GET_INVITE_LIST,
			data = params.friend_team_boss_invite_list
		})
	end

	if tostring(params.rookie_mission_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_ROOKIE_MISSION_LIST,
			data = params.rookie_mission_info
		})
	end

	if tostring(params.vip_award_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_VIP_AWARD_INFO,
			data = params.vip_award_info
		})
	end

	if tostring(params.school_practise_info) then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.SCHOOL_PRACTICE_INFO,
			data = params.school_practise_info
		})
	end

	if tostring(params.midas_info_new) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_MIDAS_INFO_2,
			data = params.midas_info_new
		})
	end

	if tostring(params.old_building_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.OLD_BUILDING_INFO,
			data = params.old_building_info
		})
	end

	if tostring(params.tower_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.TOWER_MAP_INFO,
			data = params.tower_info
		})
	end

	if tostring(params.travel_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.EXPLORE_GET_INFO,
			data = params.travel_info
		})
	end

	if tostring(params.plot_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_PLOT_INFO,
			data = params.plot_info
		})
	end

	if tostring(params.pet_train_infos) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.PET_TRAINING_GET_INFO,
			data = params.pet_train_infos
		})
	end

	if tostring(params.dress_info) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_DRESS_INFO,
			data = params.dress_info
		})
	end

	if tostring(params.community_act_list) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_COMMUNITY_ACT_INFO,
			data = params.community_act_list
		})
	end

	self:onlineInfo({
		name = xyd.event.PLAYER_INFO,
		data = params.online_info
	})

	xyd.Global.isLoginInfoReceived = true
	xyd.Global.lastRefreshTime_ = xyd.getServerTime()

	if params.opened_funcs and tostring(params.opened_funcs) ~= "" then
		self:setOpenedFunc(params.opened_funcs)
	end

	if xyd.Global.isLoadingFinish then
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.LOGIN_INFO_LOADED
		})
	end

	xyd.models.comic:calculateTotal()
	xyd.models.comic:setRedMark()
	xyd.models.dailyQuiz:reqDailyQuizInfo()
	xyd.models.arenaAllServerNew:reqRedInfo()
	xyd.models.arenaAllServerScore:updateBaseInfo()
	xyd.models.trial:reqTrialInfo()
	xyd.models.dungeon:reqDungeonInfo()
	xyd.models.heroChallenge:updateRedMark()
	xyd.models.friendTeamBoss:reqInfo()
	xyd.models.academyAssessment:setRedMark()
	xyd.models.oldSchool:updateRedMark()
	xyd.models.functionOpen:initData()
	xyd.models.shrineHurdleModel:reqShineHurdleInfo()
	xyd.models.shrineHurdleModel:getHistoryInfo()
	xyd.models.house:reqHouseInfo()

	local functionId = xyd.tables.shopConfigTable:getFunctionID(xyd.ShopType.SHOP_ARENA)

	if xyd.checkFunctionOpen(functionId, true) then
		xyd.models.shop:refreshShopInfo(xyd.ShopType.SHOP_ARENA)
	end

	local functionId = xyd.tables.shopConfigTable:getFunctionID(xyd.ShopType.SHOP_SKIN)

	if xyd.checkFunctionOpen(functionId, true) then
		xyd.models.shop:refreshShopInfo(xyd.ShopType.SHOP_SKIN)
	end

	local functionId = xyd.tables.shopConfigTable:getFunctionID(xyd.ShopType.SHOP_HERO_NEW)

	if xyd.checkFunctionOpen(functionId, true) then
		xyd.models.shop:refreshShopInfo(xyd.ShopType.SHOP_HERO_NEW)
	end

	if xyd.isLoadingFinish then
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.GAME_START
		})
	end

	if params.red_point_list then
		for i, item in pairs(params.red_point_list) do
			xyd.EventDispatcher:outer():dispatchEvent({
				name = xyd.event.RED_POINT,
				data = item
			})
		end
	end

	if params.cloister_red_info then
		local t = xyd.models.timeCloisterModel

		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.CLOISTER_RED_INFO,
			data = params.cloister_red_info
		})
	end

	xyd.models.quickFormation:reqTeamsInfo()
end

function SelfPlayer:setOpenedFunc(ids)
	for key, value in pairs(ids) do
		if tonumber(value) and tonumber(value) > 0 then
			self.openedFuncsIds_[tonumber(value)] = 1
		end
	end
end

function SelfPlayer:getOpenedFuncs()
	return self.openedFuncsIds_ or {}
end

function SelfPlayer:checkPlayerBaned()
	if not self.banRoomInfo_ then
		return false
	end

	if not self.banRoomInfo_.is_banned or self.banRoomInfo_.is_banned == 0 then
		return false
	elseif self.banRoomInfo_.ban_until_time == -1 or xyd.getServerTime() < self.banRoomInfo_.ban_until_time then
		return true
	end

	return false
end

function SelfPlayer:requestOtherInfo()
	self:initDailyTimer()
end

function SelfPlayer:onPlayerInfo_(event)
	local params = event.data

	if self.playerID_ ~= nil and self.playerID_ ~= params.player_id then
		return
	end

	SelfPlayer.super.populate(self, params)

	xyd.Global.playerName = self.playerName_
	self.vip_ = params.vip
	self.avatarID_ = params.avatar_id

	if xyd.ItemType.SKIN == itemTable:getType(self.avatarID_) then
		self.avatarID_ = itemTable:getSkinID(self.avatarID_)
	end

	self.serverID_ = params.server_id
	self.avatarFrameID_ = params.avatar_frame_id
	self.pictureID_ = params.picture_id
	self.signature_ = params.signature

	if itemTable:getType(self.pictureID_) == xyd.ItemType.SKIN_PICTURE then
		self.pictureID_ = itemTable:getSkinID(self.pictureID_)
	end

	self.picturePartnerId_ = params.picture_partner_id
	self.exp_ = params.exp
	self.vipPoint_ = params.vip_point
	self.tomorrowTime_ = params.tomorrow_time
	self.languageCode_ = params.language or 1
	self.kaimenPlayed = params.is_played or 0
	self.shouchongDisplayed = params.is_show_charge or 0
	self.isCallback = params.is_callback or 0
	self.callbackAwarded = params.callback_awarded or 0
	self.lastLoginTime = params.last_login_time or 0
	self.createdTime_ = params.created_time or 0
	local JSON = require("cjson")

	if xyd.db.misc:getValue("kbn_local_storage") ~= nil then
		self.chosenPartnerLocal = JSON.decode(xyd.db.misc:getValue("kbn_local_storage"))
	else
		self.chosenPartnerLocal = {}
	end

	self.allChosenPartner = {}

	if next(self.chosenPartnerLocal) == nil then
		table.insert(self.allChosenPartner, self.pictureID_)
	end

	for i = 1, #self.chosenPartnerLocal do
		table.insert(self.allChosenPartner, self.chosenPartnerLocal[i])
	end

	local showRandom = tonumber(xyd.db.misc:getValue("kbn_show_random")) == 1 and true or false

	if showRandom then
		local randomNum = math.random(1, #self.allChosenPartner)
		self.pictureID_ = self.allChosenPartner[randomNum]
		self.curIndex = randomNum
	else
		self.pictureID_ = self.allChosenPartner[1]
		self.curIndex = 1
	end

	dump(self.pictureID_)
end

function SelfPlayer:checkLanguage()
	local language = self.languageCode_
	local curID = xyd.tables.playerLanguageTable:getIDByName(string.lower(xyd.Global.lang))

	if tonumber(language) ~= tonumber(curID) then
		SettingUp.get():changeLanguage(curID, true)
	end
end

function SelfPlayer:getCreatedTime()
	return self.createdTime_
end

function SelfPlayer:getAccount()
	return self.account_ or ""
end

function SelfPlayer:setAccount(account)
	self.account_ = account
end

function SelfPlayer:getLanguageCode()
	return self.languageCode_
end

function SelfPlayer:onlevelUp(event)
	local level = event.data.new_level
	self.level_ = level
end

function SelfPlayer:onEditName(event)
	local name = event.data.player_name
	self.playerName_ = name
	xyd.Global.playerName = name
end

function SelfPlayer:onEditPicture(event)
	local id = event.data.picture_id

	if itemTable:getType(id) == xyd.ItemType.SKIN_PICTURE then
		id = itemTable:getSkinID(id)
	end

	self.pictureID_ = id
	local oldPartnerID = self.picturePartnerId_
	self.picturePartnerId_ = event.data.picture_partner_id or 0

	dump(self.pictureID_)
end

function SelfPlayer:editPicturesToLocalStorage(chosenArray)
	dump(chosenArray)

	local JSON = require("cjson")
	local param = {
		key = "kbn_local_storage",
		value = JSON.encode(chosenArray)
	}

	xyd.db.misc:setValue(param)
end

function SelfPlayer:editPictures(chosenArray)
	local oldID = self.allChosenPartner[1]
	self.allChosenPartner = {}

	for i = 1, #chosenArray do
		self.allChosenPartner[i] = chosenArray[i]
	end

	self:editPlayerPicture(chosenArray[1])
	self:editPicturesToLocalStorage(chosenArray)
	self:setPictureID(self.allChosenPartner[1])

	self.curIndex = 1

	if self.allChosenPartner[1] == oldID then
		xyd.MainMap.get():updateImg()
	end
end

function SelfPlayer:getPictureID()
	return self.pictureID_
end

function SelfPlayer:getPictureIDFromLocalStorage()
	return self.chosenPartnerLocal
end

function SelfPlayer:isPicturesID(itemID)
	if self.pictureID_ == itemID then
		return true
	end

	return false
end

function SelfPlayer:setPictureID(id)
	if itemTable:getType(id) == xyd.ItemType.SKIN_PICTURE then
		id = itemTable:getSkinID(id)
	end

	self.pictureID_ = id

	dump(self.pictureID_)
end

function SelfPlayer:getPicturePartner()
	return self.picturePartnerId_
end

function SelfPlayer:getServerID()
	return self.serverID_
end

function SelfPlayer:onTaskInfo(event)
	local params = event.data

	self.tasks_:populate(params)
end

function SelfPlayer:onSignDaily(event)
	self.signeds_.daily:setSigned()
end

function SelfPlayer:getAvatarID()
	return self.avatarID_
end

function SelfPlayer:getAvatarFrameID()
	return self.avatarFrameID_
end

function SelfPlayer:getDailySignedInfo()
	return self.signeds_.daily
end

function SelfPlayer:getTaskInfo()
	return self.tasks_
end

function SelfPlayer:getTasks()
	return self.tasks_:getTasks()
end

function SelfPlayer:getTomorrowTime()
	return self.tomorrowTime_
end

function SelfPlayer:setTomorrowTime(time)
	self.tomorrowTime_ = time
end

function SelfPlayer:onGetBlackList(event)
	self.blackList_ = {}
	local params = event.data.player_ids or {}

	for k, v in pairs(params) do
		local playerID = params[k]
		self.blackList_[tonumber(playerID)] = true
	end
end

function SelfPlayer:onModifyBlackList(event)
	local params = event.data

	if not params then
		return
	end

	local playerID = tonumber(params.to_player_id)
	local isAdd = tonumber(params.is_add)

	if isAdd == 1 then
		self.blackList_[playerID] = true
	else
		self.blackList_[playerID] = false
	end
end

function SelfPlayer:getBlackList()
	return self.blackList_ or {}
end

function SelfPlayer:isInBlackList(playerID)
	local blackList = self:getBlackList()

	return blackList[tonumber(playerID)]
end

function SelfPlayer:onModifyLanguage(event)
	local params = event.data or {}
	local newLanguageCode = params.language

	if newLanguageCode then
		self.languageCode_ = newLanguageCode
	end
end

function SelfPlayer:isFitstTimeDone(key)
	return self.firstTimeInfo_[key] == 1
end

function SelfPlayer:onEditPlayerSignature(signature)
	self.signature_ = signature
end

function SelfPlayer:editSignature(signature)
	self:onEditPlayerSignature(signature)

	local msg = messages_pb:signature_req()
	msg.signature = signature

	xyd.Backend.get():request(xyd.mid.SIGNATURE, msg)
end

function SelfPlayer:getSignature()
	return self.signature_
end

function SelfPlayer:getVipLev()
	return self.vip_
end

function SelfPlayer:changeAvatar(avatarID)
	if xyd.ItemType.SKIN == itemTable:getType(avatarID) then
		avatarID = itemTable:getSkinID(avatarID)
	end

	local msg = messages_pb.edit_player_avatar_req()
	msg.avatar_id = avatarID

	xyd.Backend.get():request(xyd.mid.EDIT_PLAYER_AVATAR, msg)
end

function SelfPlayer:onAvatarChange(event)
	local id = event.data.avatar_id

	if xyd.ItemType.SKIN == itemTable:getType(id) then
		id = itemTable:getSkinID(id)
	end

	self.avatarID_ = id
end

function SelfPlayer:changeAvatarFrame(avatarFrameID)
	local msg = messages_pb.edit_player_avatar_frame_req()
	msg.avatar_frame_id = avatarFrameID

	xyd.Backend.get():request(xyd.mid.EDIT_PLAYER_AVATAR_FRAME, msg)
end

function SelfPlayer:onAvatarFrameChange(event)
	local id = event.data.avatar_frame_id
	self.avatarFrameID_ = id
end

function SelfPlayer:changeName(playerName)
	local msg = messages_pb.edit_player_name_req()
	msg.player_name = xyd.escapesLuaString(playerName)

	xyd.Backend.get():request(xyd.mid.EDIT_PLAYER_NAME, msg, "EDIT_PLAYER_NAME")
end

function SelfPlayer:onlineInfo(event)
	self.onlineInfo_ = event.data

	self:updateOnlineRedMark()
	xyd.models.activity:updateAddtionFunc()

	self.onlineTimer = xyd.addGlobalTimer(handler(self, self.onOnlineTimer))
end

function SelfPlayer:onOnlineTimer()
	if self.onlineCd == nil then
		return
	end

	self.onlineCd = self.onlineCd - 1

	if self.onlineCd < 0 then
		if self.onlineTimer ~= nil then
			xyd.removeGlobalTimer(self.onlineTimer)
		end

		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ONLINE_AWARD, handler(self, function ()
			self:updateOnlineRedMark()
		end))
	end
end

function SelfPlayer:getOnlineInfo()
	return self.onlineInfo_
end

function SelfPlayer:getOnlineAward()
	local msg = messages_pb.online_get_award_req()

	xyd.Backend.get():request(xyd.mid.ONLINE_GET_AWARD, msg, "ONLINE_GET_AWARD")
end

function SelfPlayer:editPlayerPicture(id, partnerID)
	if partnerID == nil then
		partnerID = 0
	end

	if itemTable:getType(id) == xyd.ItemType.SKIN then
		id = itemTable:getSkinID(id)
	end

	local msg = messages_pb.edit_player_picture_req()
	msg.picture_id = id
	msg.partner_id = partnerID

	xyd.Backend.get():request(xyd.mid.EDIT_PLAYER_PICTURE, msg, "EDIT_PLAYER_PICTURE")
end

function SelfPlayer:setupMidToEventNameMappings_()
	self.mid2EventNames_ = {
		[xyd.mid.GUILD_BOSS_INFO] = xyd.event.GUILD_BOSS_BROADCAST
	}
end

function SelfPlayer:onServerBroadCast(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local data = event.data
	local mid = data.mid
	local payload = data.payload

	if payload == nil then
		return
	end

	payload = JSON.decode(payload)

	if self.mid2EventNames_[mid] then
		local eventObj = {
			name = self.mid2EventNames_[mid] or tostring(mid) .. "",
			data = payload
		}

		xyd.EventDispatcher.outer():dispatchEvent(eventObj)
		xyd.EventDispatcher.inner():dispatchEvent(eventObj)
	end
end

function SelfPlayer:isKaimenPlayed()
	return self.kaimenPlayed == 1
end

function SelfPlayer:isShouChongDisplayed()
	return self.shouchongDisplayed == 1
end

function SelfPlayer:ifCallback()
	return self.isCallback == 1
end

function SelfPlayer:setCallback(val)
	self.isCallback = val
end

function SelfPlayer:ifCallbackAwarded()
	return self.callbackAwarded == 1
end

function SelfPlayer:getLastLoginTime()
	return self.lastLoginTime
end

function SelfPlayer:hasPlayedKaimen()
	self.kaimenPlayed = 1
	local msg = messages_pb.kaimen_played_req()
	msg.key = "is_played"

	xyd.Backend.get():request(xyd.mid.KAIMEN_PLAYED, msg)
end

function SelfPlayer:hasDisplayShouChong()
	self.shouchongDisplayed = 1
	local msg = messages_pb:kaimen_played_req()
	msg.key = "is_show_charge"

	xyd.Backend.get():request(xyd.mid.KAIMEN_PLAYED, msg)
end

function SelfPlayer:isChangeNameFree()
	local playerID = xyd.Global.playerID or 1
	local name_ = "player" .. tostring(playerID % 1000000)
	local name2_ = "Senior" .. tostring(playerID % 1000000)

	if xyd.Global.playerName == name_ or xyd.Global.playerName == name2_ then
		return true
	end

	return false
end

function SelfPlayer:onItemAward(event)
	local data = event.data.items

	xyd.models.itemFloatModel:pushNewItems(data)

	if not data or not data[1] or not data[1].item_id then
		return
	end

	if data[1].item_id == xyd.ItemID.EQUIP_GACHA then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.EQUIP_GACHA)
	end

	if data[1].item_id == xyd.ItemID.SODA then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_ICE_SUMMER)
	end

	if data[1].item_id == xyd.ItemID.INFLATABLE_HAMMER then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_ICE_SECRET_MISSION)
	end
end

function SelfPlayer:checkCanShareSummon()
	return false
end

function SelfPlayer:updateOnlineRedMark()
	if self.onlineInfo_.id == 0 then
		return
	end

	local cd = OnlineTable:getCD(self.onlineInfo_.id)
	local duration = cd - xyd:getServerTime() + self.onlineInfo_.time
	self.onlineCd = duration
	self.isShowOnlineAwardRedMark = duration <= 0
end

function SelfPlayer:partnerSwitch(direction)
	local nextIndex = self.curIndex + direction

	if nextIndex == 0 then
		nextIndex = #self.allChosenPartner
	elseif nextIndex > #self.allChosenPartner then
		nextIndex = 1
	end

	self.pictureID_ = self.allChosenPartner[nextIndex]
	self.curIndex = nextIndex
end

function SelfPlayer:getAllChosenPartner()
	return self.allChosenPartner
end

function SelfPlayer:onNewPlayerTipsInfo(event)
	dump(xyd.decodeProtoBuf(event.data), "測試推送回來")

	local data = xyd.decodeProtoBuf(event.data)
	local msgData = nil

	if data.msg then
		msgData = JSON.decode(data.msg)
	end

	if data.misc_push_type == xyd.CommonPushType.NEW_PLAYER_TIPS and msgData then
		self.showNewPlayerTipsId = msgData.id

		dump(msgData, "測試")
	end
end

function SelfPlayer:openNewPlayerTipsWindow(id)
	if self.showNewPlayerTipsId and self.showNewPlayerTipsId == id then
		xyd.WindowManager.get():openWindow("new_player_tips_window", {
			id = self.showNewPlayerTipsId
		})

		self.showNewPlayerTipsId = nil
	end
end

function SelfPlayer:backToMainWindowUpdatePartner()
	local allLength = #self.allChosenPartner
	local newId = math.ceil(math.random() * allLength)

	if allLength > 1 then
		while true do
			if newId == self.curIndex then
				newId = math.ceil(math.random() * allLength)
			else
				break
			end
		end
	end

	self.pictureID_ = self.allChosenPartner[newId]
	self.curIndex = newId
end

return SelfPlayer
