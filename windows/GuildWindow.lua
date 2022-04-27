local BaseWindow = import(".BaseWindow")
local GuildWindow = class("GuildWindow", BaseWindow)
local GuildMemberItem = class("GuildMemberItem", import("app.components.BaseComponent"))
GuildWindow.GuildMemberItem = GuildMemberItem

function GuildWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.inTrans = false
	self.showTrans = false
end

function GuildWindow:playOpenAnimation(callback)
	BaseWindow.playOpenAnimation(self, function ()
		callback()
	end)
end

function GuildWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:onGuildInfo()
	self:registerEvent()
	self:updateUpIcon()
end

function GuildWindow:getUIComponent()
	local go = self.window_
	local group = go:NodeByName("groupAction").gameObject
	self.itemFloatRoot = go:NodeByName("groupAction/itemFloatRoot/itemFloat").gameObject
	self.labelWinTitle = group:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = group:NodeByName("closeBtn").gameObject
	self.helpBtn = group:NodeByName("helpBtn").gameObject
	self.btnLog = group:NodeByName("btnLog").gameObject
	self.btnMail = group:NodeByName("btnMail").gameObject
	self.btnCheckIn = group:NodeByName("btnCheckIn").gameObject
	self.btnLog_label = group:ComponentByName("btnLog/button_label", typeof(UILabel))
	self.btnLog_redPoint = group:ComponentByName("btnLog/redPoint", typeof(UISprite))
	self.btnMail_label = group:ComponentByName("btnMail/button_label", typeof(UILabel))
	self.btnCheckIn_label = group:ComponentByName("btnCheckIn/button_label", typeof(UILabel))
	self.btnCheckIn_redPoint = group:ComponentByName("btnCheckIn/redPoint", typeof(UISprite))
	self.btnCheckIn_upIcon = group:NodeByName("btnCheckIn/upIcon").gameObject
	local labelTime = group:ComponentByName("timePanel/labelTime", typeof(UILabel))
	self.labelTime = require("app.components.CountDown").new(labelTime)
	self.imgFlag = group:ComponentByName("imgFlag", typeof(UISprite))
	self.labelNotice = group:ComponentByName("e:Scroller/labelNotice", typeof(UILabel))
	self.labelName = group:ComponentByName("labelName", typeof(UILabel))
	self.labelID = group:ComponentByName("labelID", typeof(UILabel))
	self.labelIDNum = group:ComponentByName("labelIDNum", typeof(UILabel))
	self.labelLevel = group:ComponentByName("labelLevel", typeof(UILabel))
	self.labelNum = group:ComponentByName("labelNum", typeof(UILabel))
	self.labelLang = group:ComponentByName("labelLang", typeof(UILabel))
	self.btnApplyList = group:NodeByName("btnApplyList").gameObject
	self.btnMember = group:NodeByName("btnMember").gameObject
	self.btnZhaomu = group:NodeByName("btnZhaomu").gameObject
	self.btnApplyList_label = group:ComponentByName("btnApplyList/button_label", typeof(UILabel))
	self.btnMember_label = group:ComponentByName("btnMember/button_label", typeof(UILabel))
	self.btnZhaomu_label = group:ComponentByName("btnZhaomu/button_label", typeof(UILabel))
	self.expProgress_label = group:ComponentByName("expProgress/labelDisplay", typeof(UILabel))
	self.btnApplyList_redPoint = group:ComponentByName("btnApplyList/redPoint", typeof(UISprite))
	self.btnSetting = group:NodeByName("btnSetting").gameObject
	self.btnQuit = group:NodeByName("btnQuit").gameObject
	self.scroll_ = group:ComponentByName("scroll", typeof(UIScrollView))
	self.groupItems = group:ComponentByName("scroll/groupItems", typeof(UIGrid))
	self.expProgress = group:ComponentByName("expProgress", typeof(UIProgressBar))
	self.guild_member_item = go:NodeByName("guild_member_item").gameObject
	self.tranlationBtn = group:NodeByName("tranlationPanel/tranlationBtn").gameObject
	self.tipsNum = group:ComponentByName("tipsNum", typeof(UILabel))
	self.tipsLang = group:ComponentByName("tipsLang", typeof(UILabel))
	self.tipsOpen = group:ComponentByName("tipsOpen", typeof(UILabel))
	self.tipsPower = group:ComponentByName("tipsPower", typeof(UILabel))
	self.labelOpen = group:ComponentByName("labelOpen", typeof(UILabel))
	self.labelPower = group:ComponentByName("labelPower", typeof(UILabel))
	self.tipsPolicy = group:ComponentByName("tipsPolicy", typeof(UILabel))
	self.labelPolicy = group:ComponentByName("labelPolicy", typeof(UILabel))
end

function GuildWindow:updateOpenLabel()
	local data = xyd.models.guild.base_info
	self.labelOpen.text = __("GUILD_OPEN_TYPE" .. (data.apply_way or 1))
end

function GuildWindow:updatePowerLimit()
	local data = xyd.models.guild.base_info
	self.labelPower.text = data.power_limit
end

function GuildWindow:updatePolicy()
	local data = xyd.models.guild.base_info
	self.labelPolicy.text = __("GUILD_POLICY_TEXT" .. data.plan)
end

function GuildWindow:initUIComponent()
	self.guild_member_item:SetActive(false)

	local data = xyd.models.guild.base_info
	local level = xyd.models.guild.level

	xyd.setUISprite(self.imgFlag, nil, xyd.tables.guildIconTable:getIcon(data.flag))

	self.labelName.text = data.name
	self.tipsNum.text = __("GUILD_NUM_TIPS")
	self.tipsLang.text = __("GUILD_LANG_TIPS")
	self.tipsOpen.text = __("GUILD_OPEN_TYPE_LABEL")
	self.tipsPower.text = __("GUILD_OPWER_LIMIT_LABEL")
	self.tipsPolicy.text = __("GUILD_POLICY_TIPS")

	self:updateOpenLabel()
	self:updatePolicy()
	self:updatePowerLimit()

	self.labelID.text = __("GUILD_ID_TIPS")
	self.labelIDNum.text = data.guild_id
	self.labelLevel.text = "Lv." .. tostring(xyd.models.guild.level)
	self.labelNotice.text = data.announcement == "" and __("GUILD_TEXT01") or data.announcement
	self.btnLog_label.text = __("LOG")

	if xyd.Global.lang == "de_de" then
		self.btnLog_label.width = 90
		self.btnLog_label.depth = 12
	end

	self.btnMail_label.text = __("MAIL_TEXT")
	local members = xyd.models.guild.members
	self.labelNum.text = #members .. "/" .. tostring(xyd.tables.guildExpTable:getMember(level))

	if not data.language then
		self.labelLang.text = __("GUILD_LANGUAGE_UNSET")
	else
		self.labelLang.text = xyd.tables.playerLanguageTable:getTrueName(data.language)
	end

	local max = #xyd.tables.guildExpTable:getIDs()

	if level >= max then
		self.expProgress.value = 1
	else
		local unitExp = xyd.tables.guildExpTable:getAllExp(level)
		self.expProgress.value = (data.exp - unitExp) / (xyd.tables.guildExpTable:getAllExp(level + 1) - unitExp)
		self.expProgress_label.text = data.exp - unitExp .. " / " .. xyd.tables.guildExpTable:getAllExp(level + 1) - unitExp
	end

	self.btnCheckIn_label.text = __("CHECKIN_TEXT04")
	self.btnApplyList_label.text = __("GUILD_TEXT02")
	self.btnMember_label.text = __("GUILD_TEXT03")
	self.btnZhaomu_label.text = __("GUILD_TEXT04")

	xyd.setBgColorType(self.btnCheckIn, xyd.ButtonBgColorType.blue_btn_70_70)
	xyd.setBgColorType(self.btnApplyList, xyd.ButtonBgColorType.blue_btn_70_70)
	xyd.setBgColorType(self.btnMember, xyd.ButtonBgColorType.blue_btn_70_70)
	xyd.setBgColorType(self.btnZhaomu, xyd.ButtonBgColorType.blue_btn_70_70)

	if xyd.models.guild.guildJob == xyd.GUILD_JOB.NORMAL then
		self.btnApplyList:SetActive(false)
		self.btnMember:SetActive(false)
		self.btnMail:SetActive(false)
		self.btnSetting:SetActive(false)
		self.btnZhaomu:X(-250)
	end

	if xyd.models.guild.isCheckIn == 1 then
		xyd.setTouchEnable(self.btnCheckIn, false)
		xyd.applyDark(self.btnCheckIn:GetComponent(typeof(UISprite)))
		xyd.applyDark(self.btnCheckIn_upIcon:GetComponent(typeof(UISprite)))

		local label = self.btnCheckIn_label

		if label then
			xyd.applyDark(label)
		end

		self.labelTime:getGameObject():SetActive(true)
		self.labelTime:setInfo({
			duration = xyd.getUpdateTime()
		})
	end

	if xyd.Global.lang == "de_de" then
		self.btnLog_label.fontSize = 20
		self.btnMail_label.fontSize = 20
	end
end

function GuildWindow:registerEvent()
	GuildWindow.super.register(self)
	self:setCloseBtn(self.closeBtn)
	xyd.setDarkenBtnBehavior(self.btnLog, self, self.onTouchLog)
	xyd.setDarkenBtnBehavior(self.btnMail, self, self.onTouchMail)
	xyd.setDarkenBtnBehavior(self.btnCheckIn, self, self.onTouchCheckIn)
	xyd.setDarkenBtnBehavior(self.btnApplyList, self, self.onTouchApplyList)
	xyd.setDarkenBtnBehavior(self.btnMember, self, self.onTouchMember)
	xyd.setDarkenBtnBehavior(self.btnZhaomu, self, self.onTouchZhaomu)
	xyd.setDarkenBtnBehavior(self.btnQuit, self, self.onTouchQuit)
	xyd.setDarkenBtnBehavior(self.btnSetting, self, self.onTouchSetting)
	xyd.setDarkenBtnBehavior(self.tranlationBtn, self, self.onTouchTranlation)
	self.eventProxy_:addEventListener(xyd.event.GUILD_CHECKIN, self.onCheckIn, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_GET_INFO, self.onGuildInfo, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_NAME, self.onEditGuildName, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_ANNOUNCEMENT, self.onGuildAnnouncement, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_FLAG, self.onGuildFlag, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_LANGUAGE, function ()
		self.labelLang.text = xyd.tables.playerLanguageTable:getTrueName(xyd.models.guild.base_info.language)
	end, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_PLAN, handler(self, self.updatePolicy))
	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_APPLY_WAY, handler(self, self.updateOpenLabel))
	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_POWER_LIMIT, handler(self, self.updatePowerLimit))
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.GUILD_MEMBER, self.btnApplyList_redPoint.gameObject)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.GUILD_CHECKIN, self.btnCheckIn_redPoint.gameObject)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.GUILD_LOG, self.btnLog_redPoint.gameObject)

	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "GUILD_WINDOW_HELP_U3"
		})
	end)
end

function GuildWindow:onTouchLog()
	xyd.WindowManager.get():openWindow("guild_log_window")
end

function GuildWindow:onTouchMail()
	local MailSendWindowTypeGuild = 1

	xyd.WindowManager.get():openWindow("mail_send_window", {
		type = MailSendWindowTypeGuild
	})
end

function GuildWindow:onTouchCheckIn()
	xyd.models.guild:checkIn()
end

function GuildWindow:onCheckIn()
	local go = self.window_
	local panelItemFloat = go:ComponentByName("groupAction/itemFloatRoot", typeof(UIPanel))
	panelItemFloat.depth = go:GetComponent(typeof(UIPanel)).depth + 10

	xyd.setTouchEnable(self.btnCheckIn, false)
	xyd.applyDark(self.btnCheckIn:GetComponent(typeof(UISprite)))

	local label = self.btnCheckIn_label

	if label then
		xyd.applyDark(label)
	end

	xyd.applyDark(self.btnCheckIn_upIcon:GetComponent(typeof(UISprite)))

	local cost = xyd.tables.miscTable:split2Cost("guild_sign_in_show", "value", "|#")
	local items_multiple = 1

	if xyd.models.activity:isResidentReturnAddTime() then
		items_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.GUILD)
	end

	local items = {}

	for i = 1, #cost do
		local data = cost[i]
		local num = tonumber(data[2]) * items_multiple
		local item = {
			hideText = true,
			item_id = data[1],
			item_num = num
		}

		table.insert(items, item)
	end

	xyd.itemFloat(items, nil, self.itemFloatRoot)
	self.labelTime:getGameObject():SetActive(true)
	self.labelTime:setInfo({
		duration = xyd.getUpdateTime()
	})

	local max = #xyd.tables.guildExpTable:getIDs()
	local level = xyd.models.guild.level
	self.labelLevel.text = "Lv." .. tostring(xyd.models.guild.level)

	if max <= level then
		self.expProgress.value = 1
	else
		local data = xyd.models.guild.base_info
		local unitExp = xyd.tables.guildExpTable:getAllExp(level)
		self.expProgress.value = (data.exp - unitExp) / (xyd.tables.guildExpTable:getAllExp(level + 1) - unitExp)
		self.expProgress_label.text = data.exp - unitExp .. " / " .. xyd.tables.guildExpTable:getAllExp(level + 1) - unitExp
	end
end

function GuildWindow:onTouchApplyList()
	xyd.models.guild:reqApplyList()
	xyd.WindowManager.get():openWindow("guild_apply_list_window")
end

function GuildWindow:onTouchMember()
	xyd.WindowManager.get():openWindow("guild_member_list_window")
end

function GuildWindow:onTouchZhaomu()
	xyd.WindowManager.get():openWindow("guild_recruit_window")
end

function GuildWindow:onTouchQuit()
	if xyd.models.guild.guildJob == xyd.GUILD_JOB.LEADER then
		xyd.showToast(__("GUILD_TEXT05"))

		return
	end

	if xyd.models.guild:getGuildCompetitionInfo() and xyd.models.guild:getGuildCompetitionLeftTime().type == 2 then
		xyd.showToast(__("GUILD_COMPETITION_NO_TIPS1"))

		return
	end

	xyd.alertYesNo(__("GUILD_TEXT06"), function (yes_no)
		if not yes_no then
			return
		end

		xyd.models.guild:guildQuit()
		xyd.WindowManager.get():closeWindow("guild_window")
		xyd.WindowManager.get():closeWindow("guild_territory_window")
	end)
end

function GuildWindow:onTouchSetting()
	xyd.WindowManager.get():openWindow("guild_setting_window")
end

function GuildWindow:onTouchTranlation()
	if self.inTrans then
		xyd.showToast(__("CHAT_TRANSLATEING"))

		return
	end

	if not self.showTrans then
		local data = xyd.models.guild.base_info
		self.inTrans = true
		self.guildMsg = {
			inTransl = true,
			originalContent = data.announcement or "",
			content = xyd.models.acDFA:preTraslation(data.announcement or "")
		}

		xyd.models.chat:translateFrontend(self.guildMsg, function (msg, type)
			if type == xyd.TranslateType.DOING then
				xyd.showToast(__("CHAT_TRANSLATEING"))
			else
				self.inTrans = false
				self.labelNotice.text = msg.translate
				self.showTrans = true
			end
		end)
	else
		local data = xyd.models.guild.base_info
		self.labelNotice.text = data.announcement == "" and __("GUILD_TEXT01") or data.announcement
		self.inTrans = false
		self.showTrans = false
	end
end

function GuildWindow:setMemberList()
	local members = xyd.models.guild.members

	NGUITools.DestroyChildren(self.groupItems.gameObject.transform)

	local function sort_(a, b)
		local result = nil

		if tonumber(a.job) == tonumber(b.job) then
			if tonumber(a.is_online) == tonumber(b.is_online) then
				result = tonumber(b.last_time) < tonumber(a.last_time)
			else
				result = tonumber(b.is_online) < tonumber(a.is_online)
			end
		else
			result = tonumber(b.job) < tonumber(a.job)
		end

		return result
	end

	table.sort(members, sort_)
	self:waitForFrame(1, function ()
		for i = 1, #members do
			local data = members[i]
			local item = GuildMemberItem.new(self.groupItems.gameObject, data, function ()
				if data.player_id == xyd.models.selfPlayer:getPlayerID() then
					return
				end

				xyd.WindowManager.get():openWindow("arena_formation_window", {
					is_robot = false,
					player_id = data.player_id
				})
			end, self.scroll_:GetComponent(typeof(UIPanel)))

			self.groupItems:Reposition()

			if i == 1 or i == #members then
				self.scroll_:ResetPosition()
			end
		end
	end)
end

function GuildWindow:onGuildInfo()
	self:waitForFrame(1, function ()
		self:setMemberList()
	end)

	local level = xyd.models.guild.level
	local members = xyd.models.guild.members
	self.labelNum.text = tostring(#members) .. "/" .. tostring(xyd.tables.guildExpTable:getMember(level))

	if xyd.models.guild.isCheckIn ~= 1 then
		xyd.setEnabled(self.btnCheckIn, true)
		self.labelTime:getGameObject():SetActive(false)
		self.labelTime:stopTimeCount()
	end
end

function GuildWindow:onEditGuildName()
	local data = xyd.models.guild.base_info
	self.labelName.text = data.name
	self.labelNotice.text = data.announcement == "" and __("GUILD_TEXT01") or data.announcement
end

function GuildWindow:onGuildAnnouncement()
	local data = xyd.models.guild.base_info
	self.labelNotice.text = data.announcement == "" and __("GUILD_TEXT01") or data.announcement
end

function GuildWindow:onGuildFlag()
	local data = xyd.models.guild.base_info

	xyd.setUISprite(self.imgFlag, nil, xyd.tables.guildIconTable:getIcon(data.flag))
end

function GuildWindow:updateUpIcon()
	if xyd.models.activity:isResidentReturnAddTime() then
		self.btnCheckIn_upIcon:SetActive(xyd.models.activity:isResidentReturnAddTime())

		local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.GUILD)

		xyd.setUISpriteAsync(self.btnCheckIn_upIcon.gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_" .. return_multiple, nil, , )

		if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "ja_jp" then
			self.btnCheckIn_upIcon:X(87.6)
		elseif xyd.Global.lang == "ko_kr" or xyd.Global.lang == "en_en" then
			self.btnCheckIn_upIcon:X(75)
		end
	else
		self.btnCheckIn_upIcon:SetActive(false)
	end
end

function GuildMemberItem:ctor(go, data, callback, parentPanel)
	GuildMemberItem.super.ctor(self, go)

	self.data = data
	self.callback = callback
	self.parentPanel_ = parentPanel

	self:getUIComponent()
	self:initUIComponent()
end

function GuildMemberItem:getPrefabPath()
	return "Prefabs/Windows/guild_member_item"
end

function GuildMemberItem:getUIComponent()
	local go = self.go
	self.imgbg = go:ComponentByName("imgbg", typeof(UISprite))
	self.groupAvatar = go:NodeByName("groupAvatar").gameObject
	self.labelText0 = go:ComponentByName("labelText0", typeof(UILabel))
	self.labelText1 = go:ComponentByName("labelText1", typeof(UILabel))
	self.labelText2 = go:ComponentByName("labelText2", typeof(UILabel))
	self.labelText3 = go:ComponentByName("labelText3", typeof(UILabel))
	self.guildWarFlag = go:ComponentByName("guildWarFlag", typeof(UISprite))
end

function GuildMemberItem:initUIComponent()
	local data = self.data
	local playerIcon = require("app.components.PlayerIcon").new(self.groupAvatar, self.parentPanel_)

	playerIcon:setInfo({
		noClick = true,
		avatarID = data.avatar_id,
		avatar_frame_id = data.avatar_frame_id
	})
	playerIcon:SetLocalScale(0.6491228070175439, 0.6491228070175439, 1)

	self.labelText0.text = tostring(data.lev)
	self.labelText1.text = data.player_name
	self.labelText2.text = __("GUILD_JOB" .. tostring(data.job))

	if data.is_online and data.is_online ~= 0 then
		self.labelText3.text = __("GUILD_TEXT07")
	else
		self.labelText3.text = xyd.getReceiveTime(data.last_time)
	end

	if data.is_join_battle and data.is_join_battle == 1 then
		self.guildWarFlag:SetActive(true)
	elseif data.player_id == xyd.models.selfPlayer:getPlayerID() and #xyd.models.guild.self_info.partners > 0 then
		self.guildWarFlag:SetActive(true)
	else
		self.guildWarFlag:SetActive(false)
	end

	if self.callback then
		xyd.setDarkenBtnBehavior(self.go, self, self.callback)
	end
end

function GuildMemberItem:setFormationData(noClick)
	if noClick then
		self.go:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	else
		self.go:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end

	self.guildWarFlag:SetActive(false)
end

return GuildWindow
