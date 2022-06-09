local BaseWindow = import(".BaseWindow")
local ArenaFormationWindow = class("ArenaFormationWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local ReportBtn = import("app.components.ReportBtn")

function ArenaFormationWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = params
	self.skinName = "ArenaFormationSkin"
	self.model_ = xyd.models.arena
	self.player_id = params.player_id
	self.is_robot = params.is_robot

	if type(self.is_robot) == "boolean" then
		self.is_robot = self.is_robot == true and 1 or 0
	end

	self.add_friend = params.add_friend
	self.in_private = params.in_private
	self.not_show_private_chat = params.not_show_private_chat
	self.server_id = params.server_id
	self.show_close_btn = params.show_close_btn
	self.not_show_black_btn = params.not_show_black_btn
	self.not_show_mail = params.not_show_mail
	self.notShowGuildBtn_ = params.not_show_guild_btn
	self.show_short_bg = params.show_short_bg

	self:initBlackList()
end

function ArenaFormationWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	self.groupSignature_e_Image.alpha = 0.05

	xyd.setUISpriteAsync(self.groupSignature_e_Image, nil, "person_name_edit_bg_new", function ()
		self.groupSignature_e_Image.alpha = 1
	end, nil)

	if self.is_robot ~= nil and self.is_robot == 0 then
		self.model_:reqEnemyInfo(tonumber(self.player_id))
	else
		self.not_show_private_chat = true
		self.not_show_black_btn = true
		local a_t = xyd.tables.arenaRobotTable

		if a_t:getShowID(self.player_id) then
			self.labelId.text = "[5c5c5c]" .. a_t:getShowID(self.player_id)
		else
			self.labelId.text = "[5c5c5c]" .. self.player_id
		end

		self.playerName.text = a_t:getName(self.player_id)

		self.labelGuild:SetActive(false)
		self.guildCheckBtn_:SetActive(false)
		self.pIcon:setInfo({
			avatarID = a_t:getAvatar(self.player_id),
			lev = a_t:getLev(self.player_id)
		})

		self.power.text = tostring(a_t:getPower(self.player_id))
		local partners = a_t:getFormation(self.player_id)

		for i = 1, #partners do
			local params = {
				noClick = true,
				tableID = partners[i].partner_id,
				lev = partners[i].lev
			}

			self["hero" .. tostring(partners[i].pos)]:setInfo(params)
			self["hero" .. tostring(partners[i].pos)]:SetActive(true)
		end

		self.labelText02:SetActive(false)
		self:initDress()
	end

	self.labelFormation.text = __("DEFFORMATION")
	self.btnSendMailLabel.text = __("MAIL_TEXT")
	self.btnChatPrivateLabel.text = __("CHAT_TAP_8")

	self:updateFriend()
	self:register()
	self:initShieldBtn()

	if self.server_id ~= nil then
		self.serverGroup:SetActive(true)

		self.labelServer.text = xyd.getServerNumber(self.server_id)
	else
		self.serverGroup:SetActive(false)
	end

	if self.not_show_private_chat ~= nil then
		self.btnChatPrivate:SetActive(false)
	end

	self.btnSendMail_:SetActive(false)

	if self.show_close_btn ~= nil then
		self.closeBtn:SetActive(true)
	end

	if self.not_show_black_btn ~= nil then
		self.btnShield:SetActive(false)
	end

	if self:checkShowVisit() then
		self.btnVisitLabel.text = __("HOUSE_FRIEND_LIST_WINDOW")

		self.btnVisit:SetActive(true)
		self.btnShield:SetActive(false)
	else
		self.btnVisit:SetActive(false)
	end

	self:hide()

	if self.is_robot and self.is_robot > 0 then
		self:waitForFrame(1, function ()
			self:show()
		end)
	end

	if self.notShowGuildBtn_ or not xyd.checkFunctionOpen(xyd.FunctionID.GUILD, true) then
		self.guildCheckBtn_:SetActive(false)
	end

	if self.show_short_bg == true then
		local bg = self.window_.transform:ComponentByName("groupAction/e:Image", typeof(UISprite))
		bg.height = 464

		bg:Y(43)
	end

	self:updateBgHeight()
end

function ArenaFormationWindow:updateBgHeight()
	if not self.btnShield.activeSelf and not self.btnSendMail_.activeSelf and not self.btnChatPrivate.activeSelf and not self.btnKick.activeSelf and not self.btnVisit.activeSelf then
		self.bgWidght.height = 460
	end
end

function ArenaFormationWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.bgWidght = content:ComponentByName("e:Image", typeof(UIWidget))
	self.btnBack = content:NodeByName("btnBack").gameObject
	local pIconContainer = content:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIconContainer)
	local playerGroup = content:NodeByName("playerGroup").gameObject
	self.playerName = playerGroup:ComponentByName("playerName", typeof(UILabel))
	self.serverGroup = playerGroup:NodeByName("serverGroup").gameObject
	self.labelServer = self.serverGroup:ComponentByName("labelServer", typeof(UILabel))
	local idGroup = content:NodeByName("idGroup").gameObject
	self.labelText01 = idGroup:ComponentByName("textGroup/labelText01", typeof(UILabel))
	self.labelText02 = idGroup:ComponentByName("textGroup/labelText02", typeof(UILabel))
	self.labelId = idGroup:ComponentByName("nameGroup/labelId", typeof(UILabel))
	self.labelGuild = idGroup:ComponentByName("nameGroup/labelGuild", typeof(UILabel))
	self.guildCheckBtn_ = idGroup:NodeByName("nameGroup/guildCheckBtn").gameObject
	self.groupSignature_ = content:NodeByName("groupSignature_").gameObject
	self.groupSignature_e_Image = self.groupSignature_:ComponentByName("e:Image", typeof(UISprite))
	self.labelSignature_ = self.groupSignature_:ComponentByName("scrollerSignature_/labelSignature_", typeof(UILabel))
	self.labelFormation = content:ComponentByName("labelFormation", typeof(UILabel))
	self.powerGroup = content:NodeByName("powerGroup").gameObject
	self.power = self.powerGroup:ComponentByName("power", typeof(UILabel))
	self.heroContainer1 = content:NodeByName("group1/icon1/hero1").gameObject
	self.heroContainer2 = content:NodeByName("group1/icon2/hero2").gameObject
	self.heroContainer3 = content:NodeByName("group2/icon3/hero3").gameObject
	self.heroContainer4 = content:NodeByName("group2/icon4/hero4").gameObject
	self.heroContainer5 = content:NodeByName("group2/icon5/hero5").gameObject
	self.heroContainer6 = content:NodeByName("group2/icon6/hero6").gameObject

	for i = 1, 6 do
		self["hero" .. i] = HeroIcon.new(self["heroContainer" .. i])
	end

	self.btnGroup = content:NodeByName("btnGroup").gameObject
	self.btnShield = self.btnGroup:NodeByName("btnShield").gameObject
	self.btnShieldLabel = self.btnShield:ComponentByName("button_label", typeof(UILabel))
	self.btnShieldIcon = self.btnShield:ComponentByName("icon", typeof(UISprite))
	self.btnSendMail_ = self.btnGroup:NodeByName("btnSendMail_").gameObject
	self.btnSendMailLabel = self.btnSendMail_:ComponentByName("button_label", typeof(UILabel))
	self.btnChatPrivate = self.btnGroup:NodeByName("btnChatPrivate").gameObject
	self.btnChatPrivateLabel = self.btnChatPrivate:ComponentByName("button_label", typeof(UILabel))
	self.btnKick = self.btnGroup:NodeByName("btnKick").gameObject
	self.btnKickLabel = self.btnKick:ComponentByName("button_label", typeof(UILabel))
	self.btnVisit = self.btnGroup:NodeByName("btnVisit").gameObject
	self.btnVisitLabel = self.btnVisit:ComponentByName("button_label", typeof(UILabel))
	self.btnAddFriend_ = content:NodeByName("btnAddFriend_").gameObject
	self.btnDelFriend_ = content:NodeByName("btnDelFriend_").gameObject
	self.closeBtn = content:NodeByName("closeBtn").gameObject
	self.personCon = content:NodeByName("personCon").gameObject
	self.personBottom = self.personCon:ComponentByName("personBottom", typeof(UISprite))
	self.personEffect = self.personCon:NodeByName("personEffect").gameObject
end

function ArenaFormationWindow:initBlackList()
end

function ArenaFormationWindow:initShieldBtn()
	local flag = xyd.models.chat:isInBlackList(self.player_id)

	self:changeShieldBtn(flag)

	self.is_shielded = flag
end

function ArenaFormationWindow:changeShieldBtn(flag)
	if flag then
		xyd.setBgColorType(self.btnShield, xyd.ButtonBgColorType.blue_btn_65_65)
		xyd.setUISpriteAsync(self.btnShieldIcon, nil, "icon_unshield_icon")

		self.btnShieldLabel.text = __("CHAT_UNSHIELD")
	else
		xyd.setBgColorType(self.btnShield, xyd.ButtonBgColorType.white_btn_65_65)
		xyd.setUISpriteAsync(self.btnShieldIcon, nil, "chat_shield_icon")

		self.btnShieldLabel.text = __("CHAT_SHIELD")
	end
end

function ArenaFormationWindow:openWindow(params)
	BaseWindow.openWindow(self, params)
end

function ArenaFormationWindow:register()
	ArenaFormationWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.ARENA_GET_ENEMY_INFO, handler(self, self.onGetData))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_APPLY, handler(self, self.onApply))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_DELETE, handler(self, self.onDelFriend))
	self.eventProxy_:addEventListener(xyd.event.GET_BLACK_LIST, handler(self, self.onInitBlackList))
	self.eventProxy_:addEventListener(xyd.event.ADD_BLACK_LIST, handler(self, self.onAddBlack))
	self.eventProxy_:addEventListener(xyd.event.REMOVE_BLACK_LIST, handler(self, self.onRemoveBlack))
	self.eventProxy_:addEventListener(xyd.event.GET_INFO_BY_GUILD_ID, function (self, event)
		xyd.WindowManager.get():openWindow("guild_apply_detail_window", {
			isFromFormation = true,
			data = event.data.guild_info
		})
		xyd.WindowManager.get():closeWindow(self.name_)
	end, self)

	UIEventListener.Get(self.btnBack).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnAddFriend_).onClick = function ()
		self:onAddFriendTouch()
	end

	UIEventListener.Get(self.btnDelFriend_).onClick = function ()
		self:onDelFriendTouch()
	end

	UIEventListener.Get(self.btnChatPrivate).onClick = function ()
		self:onSendPrivateChatTouch()
	end

	UIEventListener.Get(self.btnShield).onClick = function ()
		self:onShieldTouch()
	end

	UIEventListener.Get(self.groupSignature_).onClick = function ()
		self:creatReportBtn()
	end

	UIEventListener.Get(self.btnVisit).onClick = function ()
		self:onVisitTouch()
	end

	UIEventListener.Get(self.btnSendMail_).onClick = function ()
		self:onSendMailTouch()
	end

	UIEventListener.Get(self.guildCheckBtn_).onClick = function ()
		if self.guildId_ then
			local msg = messages_pb:get_info_by_guild_id_req()
			msg.guild_id = self.guildId_

			xyd.Backend:get():request(xyd.mid.GET_INFO_BY_GUILD_ID, msg)
		end
	end
end

function ArenaFormationWindow:onVisitTouch()
	xyd.WindowManager.get():closeWindow(self.name_)
	xyd.WindowManager.get():openWindow("house_visit_window", {
		other_player_id = self.player_id
	})
end

function ArenaFormationWindow:checkShowVisit()
	local flag = true

	if xyd.models.friend:checkIsFriend(self.player_id) == false then
		flag = false
	else
		local wnd = xyd.WindowManager.get():getWindow("house_window")

		if wnd then
			flag = false
		end

		wnd = xyd.WindowManager.get():getWindow("friend_team_boss_window")

		if wnd then
			flag = false
		end

		wnd = xyd.WindowManager.get():getWindow("arena_all_server_window")

		if wnd then
			flag = false
		end
	end

	return flag
end

function ArenaFormationWindow:creatReportBtn()
	local str = self.labelSignature_.text

	if not str or str == "" or str == __("PERSON_SIGNATURE_TEXT_4") then
		return
	end

	if self.reportBtn then
		self:showReport(not self.reportBtn.visible)

		return
	end

	local params = {
		open_type = 3,
		data = {
			msg = str,
			player_id = self.player_id,
			report_type = xyd.Report_Type.SIGNATURE
		}
	}
	self.reportBtn = ReportBtn.new(self.groupSignature_, params)

	self.reportBtn:SetLocalPosition(140, 70, 0)
	self:showReport(true)
end

function ArenaFormationWindow:showReport(flag)
	if flag == nil then
		flag = false
	end

	if not self.reportBtn then
		return
	end

	self.reportBtn:SetActive(flag)
end

function ArenaFormationWindow:onAddBlack(event)
	xyd.models.chat:pushBlackList({
		player_id = self.player_id,
		player_name = self.dataInfo.player_name,
		avatar_id = self.dataInfo.avatar_id,
		lev = self.dataInfo.lev,
		avatar_frame_id = self.dataInfo.avatar_frame_id
	})
	self:changeShieldBtn(true)

	self.is_shielded = true
end

function ArenaFormationWindow:onRemoveBlack(event)
	xyd.models.chat:popBlackList(self.player_id)
	xyd.alert(xyd.AlertType.TIPS, __("CHAT_HAS_UNSHIELDED"))
	self:changeShieldBtn(false)

	self.is_shielded = false
end

function ArenaFormationWindow:onInitBlackList(event)
	self:initShieldBtn()
end

function ArenaFormationWindow:onSendPrivateChatTouch()
	if self.is_robot == 1 then
		xyd.alert(xyd.AlertType.TIPS, __("PLAYER_NOT_EXIST"))

		return
	end

	if self.in_private and self.in_private == true then
		return
	end

	xyd.WindowManager.get():closeWindow(self.name_)

	local winBlack = xyd.WindowManager.get():getWindow("chat_black_list_window")
	local win = xyd.WindowManager.get():getWindow("chat_window")

	if winBlack then
		xyd.WindowManager.get():closeWindow("chat_black_list_window")
	end

	local arenaNewSeasonServerRankWindow = xyd.WindowManager.get():getWindow("arena_new_season_server_rank_window")

	if arenaNewSeasonServerRankWindow then
		xyd.WindowManager.get():closeWindow("arena_new_season_server_rank_window")
	end

	if not win then
		xyd.WindowManager.get():openWindow("chat_window", {
			is_detail = true,
			to_player_id = self.player_id
		})

		win = xyd.WindowManager.get():getWindow("chat_window")
	else
		win.isDetail = true
		win.toPlayerId = self.player_id
	end

	win.privateParams = {
		player_name = self.dataInfo.player_name,
		avatar_id = self.dataInfo.avatar_id,
		lev = self.dataInfo.lev,
		player_id = self.player_id
	}
	win.privateServerID = self.server_id
	win.ifArenaOpen = true

	win:setPlyaerListPos(10000)

	win.notSetPos0 = true

	win:onTopTouch(xyd.MsgType.PRIVATE)
	win:setWarningVisible(self.player_id)
end

function ArenaFormationWindow:onShieldTouch()
	if self.is_robot == 1 then
		xyd.alert(xyd.AlertType.TIPS, __("PLAYER_NOT_EXIST"))

		return
	end

	if self.is_shielded == false then
		if xyd.tables.miscTable:getNumber("chat_blacklist_num", "value") <= xyd.models.chat:getBlackLength() then
			xyd.alert(xyd.AlertType.TIPS, __("CHAT_BLACK_LIMIT"))

			return
		end

		xyd.alert(xyd.AlertType.YES_NO, __("IF_CHAT_SHIELD"), function (yes)
			if yes then
				xyd.models.chat:addBlackList(self.player_id)
			end
		end)
	else
		xyd.models.chat:removeBlackList(self.player_id)
	end
end

function ArenaFormationWindow:onApply()
	xyd.alert(xyd.AlertType.TIPS, __("FRIEND_APPLY_SUCCESS"))
	xyd.WindowManager.get():closeWindow(self.name_)
end

function ArenaFormationWindow:onDelFriend()
	xyd.alert(xyd.AlertType.TIPS, __("FRIEND_DELETE_SUCCESS"))
	self:updateFriend()
end

function ArenaFormationWindow:onAddFriendTouch()
	if self.is_robot == 1 then
		xyd.alert(xyd.AlertType.TIPS, __("PLAYER_NOT_EXIST"))

		return
	end

	local flag = true
	local tips = ""

	if xyd.models.friend:checkIsFriend(self.player_id) then
		flag = false
		tips = __("PLAYER_IS_FRIEND")
	elseif xyd.models.friend:isFullFriends() then
		flag = false
		tips = __("SELF_MAX_FRIENDS")
	end

	if tips ~= "" then
		xyd.alert(xyd.AlertType.TIPS, tips)
	end

	if flag then
		xyd.models.friend:applyFriend(self.player_id)
	end
end

function ArenaFormationWindow:onDelFriendTouch()
	if xyd.models.friend:checkIsFriend(self.player_id) then
		xyd.alert(xyd.AlertType.YES_NO, __("FRIEND_DEL_FRIEND"), function (yes)
			if yes then
				xyd.models.friend:delFriend(self.player_id)
				xyd.WindowManager.get():closeWindow(self.name_)
			end
		end)
	end
end

function ArenaFormationWindow:onSendMailTouch()
	if self.is_robot == 1 then
		xyd.alert(xyd.AlertType.TIPS, __("PLAYER_NOT_EXIST"))

		return
	end

	xyd.WindowManager.get():openWindow("mail_send_window", {
		oldContent = "",
		type = 2,
		player_id = self.player_id,
		player_name = self.playerName.text
	})
end

function ArenaFormationWindow:onGetData(event)
	self.dataInfo = event.data
	local data = event.data
	self.playerName.text = data.player_name
	self.labelText01.text = "ID"
	self.labelId.text = data.player_id
	self.guildId_ = data.guild_id

	if data.guild_name and data.guild_name ~= "" then
		self.labelText02.text = __("GUILD_TEXT12")
		self.labelGuild.text = data.guild_name
		self.guild_name = data.guild_name
	else
		self.labelText02:SetActive(false)
		self.labelGuild:SetActive(false)
		self.guildCheckBtn_:SetActive(false)
	end

	local petID = 0

	if data and data.pet then
		petID = data.pet.pet_id
	end

	self.pIcon:setInfo({
		avatarID = data.avatar_id,
		lev = data.lev,
		avatar_frame_id = data.avatar_frame_id
	})

	local power = 0
	local posList = {}

	for i = 1, #data.partners do
		local pos = data.partners[i].pos
		local partner = Partner.new()
		posList[pos] = true

		partner:populate(data.partners[i])

		local partnerInfo = partner:getInfo()
		partnerInfo.noClick = true

		self["hero" .. tostring(pos)]:setInfo(partnerInfo, petID)

		power = power + data.partners[i].power
	end

	for i = 1, 6 do
		if posList[i] then
			self["hero" .. tostring(i)]:SetActive(true)
		else
			self["hero" .. tostring(i)]:SetActive(false)
		end
	end

	local signa = data.signature

	if signa and tostring(signa) ~= "" then
		self.labelSignature_.text = data.signature
	else
		self.labelSignature_.text = __("PERSON_SIGNATURE_TEXT_4")
	end

	self.power.text = tostring(power)
	self.server_id = data.server_id

	if self.server_id ~= nil then
		self.serverGroup:SetActive(true)

		self.labelServer.text = xyd.getServerNumber(self.server_id)
	else
		self.serverGroup:SetActive(false)
	end

	self:initDress()
	self:waitForFrame(1, function ()
		self:show()
	end)
end

function ArenaFormationWindow:updateFriend()
	if xyd.models.friend:checkIsFriend(self.player_id) then
		self.btnDelFriend_:SetActive(true)
		self.btnAddFriend_:SetActive(false)
	elseif self.player_id ~= xyd.Global.playerID then
		self.btnAddFriend_:SetActive(true)
		self.btnDelFriend_:SetActive(false)
	end

	if self.not_show_private_chat then
		self.btnAddFriend_:SetActive(false)
		self.btnDelFriend_:SetActive(false)

		return
	end
end

function ArenaFormationWindow:willClose(params)
	BaseWindow.willClose(self, params)
end

function ArenaFormationWindow:initDress()
	if self.normalModel_ then
		return
	end

	local styleID = {}
	local ids = xyd.tables.senpaiDressSlotTable:getIDs()

	for i = 1, #ids do
		if self.dataInfo and self.dataInfo.dress_style and self.dataInfo.dress_style[i] then
			table.insert(styleID, tonumber(self.dataInfo.dress_style[i]))
		else
			table.insert(styleID, xyd.tables.senpaiDressSlotTable:getDefaultStyle(ids[i]))
		end
	end

	self:waitForFrame(2, function ()
		self.normalModel_ = import("app.components.SenpaiModel").new(self.personEffect)

		self.normalModel_:setModelInfo({
			ids = styleID
		})
	end)
end

return ArenaFormationWindow
