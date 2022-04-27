local BaseWindow = import(".BaseWindow")
local ArenaAllServerFormationWindow = class("ArenaAllServerFormationWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local Monster = import("app.models.Monster")
local ReportBtn = import("app.components.ReportBtn")

function ArenaAllServerFormationWindow:ctor(name, params)
	ArenaAllServerFormationWindow.super.ctor(self, name, params)

	self.data = params
	self.isQuiz_ = params.is_quiz
	self.model_ = xyd.models.arenaAllServerScore

	if params.zone_id then
		self.model_ = xyd.models.arenaAllServerNew
		self.zone_id_ = params.zone_id
	elseif params.model then
		self.model_ = params.model
		self.zone_id_ = params.zone_id

		print("self.zone_id_", self.zone_id_)
	end

	self.player_id = params.player_id
	self.is_robot = params.is_robot

	if type(self.is_robot) == "boolean" then
		self.is_robot = self.is_robot == true and 1 or 0
	end

	self.in_private = params.in_private
	self.not_show_private_chat = true
	self.server_id = params.server_id
	self.show_close_btn = true
	self.not_show_black_btn = true
	self.notShowGuildBtn_ = true
end

function ArenaAllServerFormationWindow:initWindow()
	ArenaAllServerFormationWindow.super.initWindow(self)
	self:getUIComponent()

	self.groupSignature_e_Image.alpha = 0.05

	xyd.setUISpriteAsync(self.groupSignature_e_Image, nil, "person_name_edit_bg_new", function ()
		self.groupSignature_e_Image.alpha = 1
	end, nil)

	if self.is_robot and self.is_robot == 1 or self.player_id < 10000 then
		local a_t = xyd.tables.arenaAllServerRobotTable

		if a_t:getShowID(self.player_id) then
			self.labelId.text = "[5c5c5c]" .. a_t:getShowID(self.player_id)
		else
			self.labelId.text = "[5c5c5c]" .. self.player_id
		end

		self.server_id = a_t:getServerID(self.player_id)
		self.playerName.text = a_t:getName(self.player_id)

		self.labelGuild:SetActive(false)
		self.guildCheckBtn_:SetActive(false)
		self.pIcon:setInfo({
			avatarID = a_t:getAvatar(self.player_id),
			lev = a_t:getLev(self.player_id)
		})

		self.power.text = tostring(a_t:getPower(self.player_id))

		self.labelText02:SetActive(false)
		self:initDress()
		self:initPartnerPart()
	else
		self.model_:reqEnemyInfo(tonumber(self.player_id), self.zone_id_)
	end

	self.labelFormation.text = __("DEFFORMATION")

	self:register()

	if self.server_id ~= nil then
		self.serverGroup:SetActive(true)

		self.labelServer.text = xyd.getServerNumber(self.server_id)
	else
		self.serverGroup:SetActive(false)
	end

	self.closeBtn:SetActive(true)
	self:hide()

	if self.is_robot and self.is_robot > 0 or self.player_id < 10000 then
		self:waitForFrame(1, function ()
			self:show()
		end)
	end

	if self.notShowGuildBtn_ or not xyd.checkFunctionOpen(xyd.FunctionID.GUILD, true) then
		self.guildCheckBtn_:SetActive(false)
	end
end

function ArenaAllServerFormationWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.content = content
	self.btnBack = content:NodeByName("btnBack").gameObject
	self.bgImg = content:ComponentByName("bgImg", typeof(UISprite))
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

	self.closeBtn = content:NodeByName("closeBtn").gameObject
	self.personCon = content:NodeByName("personCon").gameObject
	self.personBottom = self.personCon:ComponentByName("personBottom", typeof(UISprite))
	self.personEffect = self.personCon:NodeByName("personEffect").gameObject
	self.subsitGroup = content:NodeByName("subsitGroup").gameObject
	self.labelForntSit = self.subsitGroup:ComponentByName("labelForntSit", typeof(UILabel))
	self.labelBackSit = self.subsitGroup:ComponentByName("labelBackSit", typeof(UILabel))
	self.gridSitPartner = self.subsitGroup:ComponentByName("gridSitPartner", typeof(UIGrid))
	self.sitPartnerList = self.subsitGroup:NodeByName("sitPartnerList").gameObject
end

function ArenaAllServerFormationWindow:register()
	ArenaAllServerFormationWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_ENEMY_INFO_NEW, self.onGetData, self)
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_ENEMY_INFO_NEW2, self.onGetData, self)
	self.eventProxy_:addEventListener(xyd.event.ARENA_GET_ENEMY_INFO, handler(self, self.onGetData))
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

	UIEventListener.Get(self.guildCheckBtn_).onClick = function ()
		if self.guildId_ then
			local msg = messages_pb:get_info_by_guild_id_req()
			msg.guild_id = self.guildId_

			xyd.Backend:get():request(xyd.mid.GET_INFO_BY_GUILD_ID, msg)
		end
	end
end

function ArenaAllServerFormationWindow:initDress()
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

function ArenaAllServerFormationWindow:onGetData(event)
	self.dataInfo = xyd.decodeProtoBuf(event.data)
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

	self.pIcon:setInfo({
		avatarID = data.avatar_id,
		lev = data.lev,
		avatar_frame_id = data.avatar_frame_id
	})
	self:initDress()
	self:initPartnerPart()
	self:initSubsitGroup()
end

function ArenaAllServerFormationWindow:initSubsitGroup()
	local level = nil

	if self.zone_id_ and tonumber(self.zone_id_) > 0 or self.isQuiz_ then
		level = 22
	elseif self.dataInfo then
		level = xyd.tables.arenaAllServerRankTable:getRankLevel(self.dataInfo.score, self.dataInfo.score)
	else
		level = xyd.tables.arenaAllServerRankTable:getRankLevel(xyd.tables.arenaAllServerRobotTable:getScore(self.player_id))
	end

	local groupNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(level) or 0
	local hideNum = xyd.tables.arenaAllServerRankTable:getHideNum(level) or 0

	if groupNum > 0 then
		self.subsitGroup:SetActive(true)

		self.labelForntSit.text = __("NEW_ARENA_ALL_SERVER_TEXT_7")
		self.labelBackSit.text = __("NEW_ARENA_ALL_SERVER_TEXT_8")
		self.bgImg.height = 495 + groupNum * 100

		for i = 1, groupNum do
			local newList = NGUITools.AddChild(self.gridSitPartner.gameObject, self.sitPartnerList)

			newList:SetActive(true)

			if i > groupNum - hideNum then
				for j = 1, 6 do
					local subSuitPartner = self:getSubsitPartner(i, j)

					if subSuitPartner then
						self.powerNum = self.powerNum + subSuitPartner.power
					end
				end

				for j = 1, 2 do
					local cover = newList:NodeByName("cover" .. j).gameObject

					cover:SetActive(true)
				end
			else
				for j = 1, 6 do
					local subSuitPartner = self:getSubsitPartner(i, j)

					if subSuitPartner and subSuitPartner.table_id and tonumber(subSuitPartner.table_id) ~= 0 then
						local partner = Partner.new()

						partner:populate(subSuitPartner)

						self.powerNum = self.powerNum + subSuitPartner.power
						partner.noClick = true
						local heroIcon = HeroIcon.new(newList:NodeByName("icon" .. j .. "/hero" .. j).gameObject)

						heroIcon:setInfo(partner)
					end
				end
			end
		end
	end

	self.content.transform:Y(50 * groupNum)

	if self.zone_id_ and tonumber(self.zone_id_) or self.isQuiz_ then
		self.powerGroup:SetActive(false)
	else
		self.power.text = self.powerNum
	end
end

function ArenaAllServerFormationWindow:getSubsitPartner(i, j)
	if j > 0 and j <= 2 then
		local pos = (i - 1) * 2 + j

		return self.dataInfo.teams.front_infos[pos]
	else
		local pos = (i - 1) * 4 + j - 2

		return self.dataInfo.teams.back_infos[pos]
	end
end

function ArenaAllServerFormationWindow:initPartnerPart()
	self.powerNum = 0
	local posList = {}
	local petID = 0

	if not self.dataInfo or not self.dataInfo.teams or not self.dataInfo.teams.partners then
		self:initRobotPartners()

		return
	end

	if self.dataInfo and self.dataInfo.teams and self.dataInfo.teams.pet_infos and self.dataInfo.teams.pet_infos[1] then
		petID = self.dataInfo.teams.pet_infos[1].pet_id or 0
	end

	for i = 1, #self.dataInfo.teams.partners do
		if self.dataInfo.teams.partners[i].table_id then
			if tonumber(self.dataInfo.teams.partners[i].table_id) ~= 0 then
				local pos = self.dataInfo.teams.partners[i].pos
				local partner = Partner.new()
				posList[pos] = true

				partner:populate(self.dataInfo.teams.partners[i])

				local partnerInfo = partner:getInfo()
				partnerInfo.noClick = true

				self["hero" .. tostring(pos)]:setInfo(partnerInfo, petID)

				self.powerNum = self.powerNum + self.dataInfo.teams.partners[i].power
			end
		end
	end

	for i = 1, 6 do
		if posList[i] then
			self["hero" .. tostring(i)]:SetActive(true)
		else
			self["hero" .. tostring(i)]:SetActive(false)
		end
	end

	local signa = self.dataInfo.signature

	if signa and tostring(signa) ~= "" then
		self.labelSignature_.text = self.dataInfo.signature
	else
		self.labelSignature_.text = __("PERSON_SIGNATURE_TEXT_4")
	end

	self.power.text = self.powerNum
	self.server_id = self.dataInfo.server_id

	if self.server_id ~= nil then
		self.serverGroup:SetActive(true)

		self.labelServer.text = xyd.getServerNumber(self.server_id)
	else
		self.serverGroup:SetActive(false)
	end

	self:waitForFrame(1, function ()
		self:show()
	end)

	if self.isQuiz_ then
		self.powerGroup:SetActive(false)
	end
end

function ArenaAllServerFormationWindow:initRobotPartners()
	if self.player_id and self.player_id < 10000 then
		self.power.text = xyd.tables.arenaAllServerRobotTable:getPower(self.player_id)
		self.server_id = xyd.tables.arenaAllServerRobotTable:getServerID(self.player_id)

		if self.server_id ~= nil then
			self.serverGroup:SetActive(true)

			self.labelServer.text = xyd.getServerNumber(self.server_id)
		else
			self.serverGroup:SetActive(false)
		end

		local partners = xyd.tables.arenaAllServerRobotTable:getPartners(self.player_id)

		for i = 1, 6 do
			local pos = i
			local partner = Monster.new()

			partner:populateWithTableID(partners[i])

			local partnerInfo = partner:getInfo()
			partnerInfo.noClick = true

			self["hero" .. tostring(pos)]:setInfo(partnerInfo, 0)
		end

		self:waitForFrame(1, function ()
			self:show()
		end)
	end
end

return ArenaAllServerFormationWindow
