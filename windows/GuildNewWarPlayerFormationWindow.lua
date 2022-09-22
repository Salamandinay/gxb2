local BaseWindow = import(".BaseWindow")
local GuildNewWarPlayerFormationWindow = class("GuildNewWarPlayerFormationWindow", BaseWindow)
local HeroIcon = import("app.components.HeroIcon")
local PlayerIcon = import("app.components.PlayerIcon")
local Partner = import("app.models.Partner")

function GuildNewWarPlayerFormationWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
	dump(params, "test23222")

	self.guild_id = params.data.guild_id
	self.guild_name = params.data.guild_name
	self.data = params.data.playerInfo
	self.player_id = self.data.player_id
	self.is_robot = self.data.is_robot
end

function GuildNewWarPlayerFormationWindow:initWindow()
	self:getUIComponents()
	BaseWindow.initWindow(self)
	self:registerEvent()

	self.labelFormation.text = __("DEFFORMATION")

	self:onGetData(self.data)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)

	self.activityData:reqOtherDefFormation(self.player_id)
end

function GuildNewWarPlayerFormationWindow:getUIComponents()
	local trans = self.window_.transform:NodeByName("groupAction").gameObject
	self.btnPanel = trans:NodeByName("btnPanel").gameObject
	self.closeBtn = self.btnPanel:NodeByName("closeBtn").gameObject
	local pIcon = trans:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIcon)
	self.playerName = trans:ComponentByName("playerName", typeof(UILabel))
	self.id = trans:ComponentByName("id", typeof(UILabel))
	self.guild = trans:ComponentByName("guild", typeof(UILabel))
	self.groupSignature_ = trans:NodeByName("groupSignature_").gameObject
	self.scrollerSignature_ = self.groupSignature_:NodeByName("scrollerSignature_").gameObject
	self.labelSignature_ = self.scrollerSignature_:ComponentByName("labelSignature_", typeof(UILabel))
	self.labelFormation = trans:ComponentByName("labelFormation", typeof(UILabel))
	self.serverInfo = trans:NodeByName("serverInfo").gameObject
	self.serverId = self.serverInfo:ComponentByName("serverId", typeof(UILabel))
	self.groupPower_ = trans:NodeByName("groupPower_").gameObject
	self.power = self.groupPower_:ComponentByName("power", typeof(UILabel))
	self.formation = trans:NodeByName("formation").gameObject
	local idGroup = trans:NodeByName("idGroup").gameObject
	self.labelText01 = idGroup:ComponentByName("textGroup/labelText01", typeof(UILabel))
	self.labelText02 = idGroup:ComponentByName("textGroup/labelText02", typeof(UILabel))
	self.labelId = idGroup:ComponentByName("nameGroup/labelId", typeof(UILabel))
	self.labelGuild = idGroup:ComponentByName("nameGroup/labelGuild", typeof(UILabel))
	self.guildCheckBtn_ = idGroup:NodeByName("nameGroup/guildCheckBtn").gameObject
	self.personCon = trans:NodeByName("personCon").gameObject
	self.personBottom = self.personCon:ComponentByName("personBottom", typeof(UISprite))
	self.personEffect = self.personCon:NodeByName("personEffect").gameObject
	local cnt = 1

	for i = 1, 3 do
		self["formation" .. i] = self.formation:NodeByName("formation" .. i).gameObject
		local grid1 = self["formation" .. i]:NodeByName("grid1").gameObject
		local grid2 = self["formation" .. i]:NodeByName("grid2").gameObject

		for j = 1, 2 do
			local root = grid1:NodeByName("hero" .. cnt).gameObject
			self["hero" .. cnt] = HeroIcon.new(root)

			self["hero" .. cnt]:SetActive(false)

			cnt = cnt + 1
		end

		for j = 3, 6 do
			local root = grid2:NodeByName("hero" .. cnt).gameObject
			self["hero" .. cnt] = HeroIcon.new(root)

			self["hero" .. cnt]:SetActive(false)

			cnt = cnt + 1
		end
	end
end

function GuildNewWarPlayerFormationWindow:registerEvent()
	self:register()
	self.eventProxy_:addEventListener(xyd.event.GUILD_NEW_WAR_GET_OTHER, self.initTeams, self)

	UIEventListener.Get(self.groupSignature_).onClick = handler(self, self.creatReportBtn)

	UIEventListener.Get(self.guildCheckBtn_).onClick = function ()
		if self.guild_id then
			local msg = messages_pb:get_info_by_guild_id_req()
			msg.guild_id = self.guild_id

			xyd.Backend:get():request(xyd.mid.GET_INFO_BY_GUILD_ID, msg)
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_INFO_BY_GUILD_ID, function (self, event)
		xyd.WindowManager.get():openWindow("guild_apply_detail_window", {
			isFromFormation = true,
			data = event.data.guild_info
		})
		xyd.WindowManager.get():closeWindow(self.name_)
	end, self)
end

function GuildNewWarPlayerFormationWindow:onGetData(info)
	dump(info, "test11111")

	self.dataInfo = info
	local data = self.dataInfo
	self.playerName.text = data.player_name
	self.serverId.text = xyd.getServerNumber(data.server_id)
	self.labelText01.text = "ID"
	self.labelId.text = data.player_id
	self.guildId_ = data.guild_id

	if self.guild_name and self.guild_name ~= "" then
		self.labelText02.text = __("GUILD_TEXT12")
		self.labelGuild.text = self.guild_name
	else
		self.labelText02:SetActive(false)
		self.labelGuild:SetActive(false)
		self.guildCheckBtn_:SetActive(false)
	end

	self.pIcon:setInfo({
		avatarID = data.avatar_id,
		lev = data.lev,
		avatar_frame_id = data.avatar_frame_id
	})

	if data.signature and data.signature ~= "" then
		self.labelSignature_.text = data.signature
	else
		self.labelSignature_.text = __("PERSON_SIGNATURE_TEXT_4")
	end

	self.power.text = data.power

	self:initDress()
end

function GuildNewWarPlayerFormationWindow:initTeams(event)
	local teams = event.data.teams
	local len = #teams
	local isHideLev = false

	for i = 1, len do
		local petID = 0

		if teams[i] and teams[i].pet then
			petID = teams[i].pet.pet_id
		end

		for j = 1, #teams[i].partners do
			local index = (i - 1) * 6 + teams[i].partners[j].pos
			local partner = Partner.new()

			partner:populate(teams[i].partners[j])

			local partnerInfo = partner:getInfo()
			partnerInfo.noClick = true
			partnerInfo.hideLev = isHideLev
			partnerInfo.scale = 0.8

			self["hero" .. index]:setInfo(partnerInfo, petID)
			self["hero" .. index]:SetActive(true)
		end
	end
end

function GuildNewWarPlayerFormationWindow:creatReportBtn()
end

function GuildNewWarPlayerFormationWindow:showReport(flag)
end

function GuildNewWarPlayerFormationWindow:initDress()
	if self.normalModel_ then
		return
	end

	local styleID = {}
	local ids = xyd.tables.senpaiDressSlotTable:getIDs()

	for i = 1, #ids do
		if self.data and self.data.dress_style and self.data.dress_style[i] then
			table.insert(styleID, tonumber(self.data.dress_style[i]))
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

return GuildNewWarPlayerFormationWindow
