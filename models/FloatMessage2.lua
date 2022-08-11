local BaseModel = import(".BaseModel")
local FloatMessage2 = class("FloatMessage2", BaseModel)

function FloatMessage2:ctor()
	FloatMessage2.super.ctor(self)

	self.notices_ = {}
	self.summonList = {}
	self.count_ = 0
	self.noticeShowType_ = false
	self.showInWnds = {
		"main_window",
		"summon_window",
		"res_loading_window",
		"summon_result_window",
		"loading_window",
		"alert_window",
		"system_alert_window",
		"chat_window",
		"friend_window",
		"daily_mission_window",
		"img_guide_window",
		"enhance_window",
		"achievement_window",
		"mail_window",
		"vip_window",
		"battle_pass_window",
		"person_info_window",
		"item_tips_window",
		"midas_window",
		"daily_quiz_window",
		"daily_quiz2_window",
		"daily_quiz_detail_window",
		"guild_join_window",
		"gamble_door_window",
		"float_message_window2",
		"activity_point_tips_window",
		"arctic_expedition_main_window",
		"arctic_expedition_mission_window",
		"arctic_expedition_award_window",
		"arctic_expedition_rank_window",
		"arctic_expedition_record_window",
		"arctic_expedition_record_window2",
		"arctic_expedition_cell_window",
		"activity_window",
		"gamble_rewards_window"
	}
end

function FloatMessage2:onRegister()
	self:registerEventInner(xyd.event.WINDOW_DID_OPEN, self.onWndOpen, self)
	self:registerEventInner(xyd.event.WINDOW_DID_CLOSE, self.onWndClose, self)
	self:registerEventInner(xyd.event.SYS_BROADCAST, self.onSysBroadcast, self)
end

function FloatMessage2:disposeAll()
	FloatMessage2.super.disposeAll(self)

	local win = xyd.WindowManager.get():getWindow("float_message_window2")

	if win then
		xyd.closeWindow("float_message_window2")
	end
end

function FloatMessage2:onWndOpen(event)
	local windowName = event.params.windowName
	local wnds = self.showInWnds

	if xyd.arrayIndexOf(wnds, windowName) <= -1 then
		self:showMessage(false)
	end
end

function FloatMessage2:showMessage(flag)
	if self.msgWnd then
		if self.noticeShowType_ or flag == false then
			self.msgWnd:hide()
		else
			self.msgWnd:show()
			self.msgWnd:setDepth()
		end
	end
end

function FloatMessage2:setNoticeType(flag)
	self.noticeShowType_ = flag

	self:checkShow()
end

function FloatMessage2:onWndClose(event)
	self:checkShow()
end

function FloatMessage2:pushSummonList()
	if #self.summonList <= 0 then
		return
	end

	for i = 1, #self.summonList do
		local data = self.summonList[i]

		self:showNotice(data)
	end

	self.summonList = {}

	self:checkShow()
end

function FloatMessage2:checkShow()
	local wnds = self.showInWnds
	local flag = true
	local windowContexts_ = xyd.WindowManager.get():getAllWindow()

	for wndName, _ in pairs(windowContexts_) do
		local windowContext = windowContexts_[wndName]

		if windowContext and xyd.arrayIndexOf(wnds, wndName) <= -1 then
			flag = false

			break
		end
	end

	self:showMessage(flag)
end

function FloatMessage2:onSysBroadcast(event)
	if xyd.GuideController.get():isPlayGuide() then
		return
	end

	local data = event.data

	if data.broadcast_type == xyd.SysBroadcast.FIVE_STAR and data.player_id == xyd.Global.playerID then
		table.insert(self.summonList, data)

		return
	end

	self:showNotice(data)
end

function FloatMessage2:createEffect(callback)
	local win = xyd.WindowManager.get():getWindow("float_message_window2")

	if not win then
		xyd.WindowManager.get():openWindow("float_message_window2", {}, callback)
	end
end

function FloatMessage2:showNotice(data)
	table.insert(self.notices_, xyd.decodeProtoBuf(data))

	local isLogin = xyd.WindowManager.get():getWindow("login_window")

	if self.isShowNotice or isLogin then
		return
	end

	local function callback(window)
		self.isShowNotice = true

		self:checkShow()
		window:playEnterAnimation()

		self.msgWnd = window
	end

	local abbr = xyd.db.misc:getValue("abbr_setting_up_float_message_result")

	if abbr == nil or abbr and tonumber(abbr) ~= 0 then
		local win = xyd.WindowManager.get():getWindow("float_message_window2")

		if not win then
			self:createEffect(callback)
		else
			win:adjustWindowDepth()
			callback(win)
		end
	end
end

return FloatMessage2
