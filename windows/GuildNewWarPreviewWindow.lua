local BaseWindow = import(".BaseWindow")
local GuildNewWarPreviewWindow = class("GuildNewWarPreviewWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")
local WindowTop = import("app.components.WindowTop")
local GuildNewWarPreviewItem = class("GuildNewWarPreviewItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function GuildNewWarPreviewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.nodeIndex = params.nodeIndex
end

function GuildNewWarPreviewWindow:initWindow()
	GuildNewWarPreviewWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)
	self.roleModels = {}

	self:getUIComponent()
	self:reSize()
	self:registerEvent()
	self:layout()
end

function GuildNewWarPreviewWindow:reSize()
	self:resizePosY(self.bottomGroup, -1210, -1317)
	self.flagPanel:SetRect(0, 0, 720, 720 + 201 * self.scale_num_contrary)
	self:resizePosY(self.flagScroller, -49, -57)
end

function GuildNewWarPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.imgBg = self.groupAction:ComponentByName("imgBg", typeof(UITexture))
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.btnClose = self.bottomGroup:NodeByName("btnClose").gameObject
	self.labelClose = self.btnClose:ComponentByName("labelClose", typeof(UILabel))
	self.btnClean = self.bottomGroup:NodeByName("btnClean").gameObject
	self.labelClean = self.btnClean:ComponentByName("labelClean", typeof(UILabel))
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.btnHelp = self.topGroup:NodeByName("btnHelp").gameObject
	self.nodeInfoGroup = self.topGroup:NodeByName("nodeInfoGroup").gameObject
	self.imgNode = self.nodeInfoGroup:ComponentByName("imgNode", typeof(UISprite))
	self.labelNodeName = self.nodeInfoGroup:ComponentByName("labelNodeName", typeof(UILabel))
	self.labelFlagNum = self.nodeInfoGroup:ComponentByName("labelFlagNum", typeof(UILabel))
	self.labelBuff = self.nodeInfoGroup:ComponentByName("labelBuff", typeof(UILabel))
	self.aimGroup = self.nodeInfoGroup:NodeByName("aimGroup").gameObject
	self.labelAiming = self.aimGroup:ComponentByName("labelAim", typeof(UILabel))
	self.imgAim = self.aimGroup:ComponentByName("imgAim", typeof(UISprite))
	self.btnAim = self.nodeInfoGroup:NodeByName("btnAim").gameObject
	self.labelAim = self.btnAim:ComponentByName("labelAim", typeof(UILabel))
	self.titleGroup = self.topGroup:NodeByName("titleGroup").gameObject
	self.labelSelf = self.titleGroup:ComponentByName("label", typeof(UILabel))
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.labelMidTitle = self.midGroup:ComponentByName("titleGroup/label", typeof(UILabel))
	self.flagScroller = self.midGroup:NodeByName("flagScroller").gameObject
	self.flagPanel = self.midGroup:ComponentByName("flagScroller", typeof(UIPanel))
	self.flagScrollView = self.midGroup:ComponentByName("flagScroller", typeof(UIScrollView))
	self.flagGroup = self.flagScroller:NodeByName("flagGroup").gameObject
	self.drag = self.midGroup:NodeByName("drag").gameObject
	self.flagItem = self.midGroup:NodeByName("flagItem").gameObject
end

function GuildNewWarPreviewWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GUILD_NEW_WAR_FIGHT, function (event)
		local data = xyd.decodeProtoBuf(event.data)

		self:updateNodeInfoGroup()
		self:updateFlagList()
	end)
	self.eventProxy_:addEventListener(xyd.event.GUILD_NEW_WAR_SWEEP, function (event)
		local data = xyd.decodeProtoBuf(event.data)

		xyd.openWindow("guild_new_war_destroy_result_window", {
			isCleanFight = true,
			nodeIndex = self.nodeIndex,
			selfPoint = self.activityData.tempAddSelfScore,
			selfGuildPoint = data.add
		})
	end)

	UIEventListener.Get(self.btnHelp.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "GUILD_NEW_WAR_HELP02"
		})
	end

	UIEventListener.Get(self.btnClose.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnAim.gameObject).onClick = function ()
		if xyd.models.guild.guildJob ~= xyd.GUILD_JOB.LEADER then
			if xyd.models.guild.guildJob ~= xyd.GUILD_JOB.VICE_LEADER then
				xyd.alertTips(__("GUILD_NEW_WAR_TIPS03"))

				return
			end
		end

		local baseInfo = self.activityData:getBaseInfo()
		local cdTime = baseInfo.rally_cd

		if cdTime <= xyd.getServerTime() then
			self.activityData:reqRally(self.nodeIndex, function ()
				self:updateNodeInfoGroup()

				local wnd = xyd.getWindow("guild_new_war_map_window")

				if wnd then
					wnd:updateAimImage()
				end
			end)
		else
			xyd.alertTips(__("GUILD_NEW_WAR_TEXT86", xyd.getRoughDisplayTime(cdTime - xyd.getServerTime())))
		end
	end

	UIEventListener.Get(self.btnClean.gameObject).onClick = function ()
		if self.activityData:getLeftAttackTime() <= 0 then
			xyd.alertTips(__("GUILD_NEW_WAR_TIPS04"))

			return
		end

		self.activityData:reqSweep(self.nodeIndex, 1, function ()
		end)
	end
end

function GuildNewWarPreviewWindow:layout()
	self.isSelf = self.nodeIndex <= 6
	self.curPeriod = self.activityData:getCurPeriod()
	self.nodeDetailData = self.activityData:getNodeDetailData(self.nodeIndex)
	self.labelClose.text = __("RETURN")
	self.labelAim.text = __("GUILD_NEW_WAR_TEXT22")
	self.labelAiming.text = __("GUILD_NEW_WAR_TEXT92")
	self.labelClean.text = __("GUILD_NEW_WAR_TEXT73")
	self.labelMidTitle.text = __("GUILD_NEW_WAR_TEXT51")

	if xyd.Global.lang == "de_de" then
		self.labelAim.height = 40
	end

	self.labelAiming:SetActive(false)

	if self.isSelf then
		self.labelSelf.text = __("GUILD_NEW_WAR_TEXT74")
		self.labelSelf.effectColor = Color.New2(543668223)

		xyd.setUISpriteAsync(self.titleGroup:ComponentByName("bg", typeof(UISprite)), nil, "guild_new_war2_bg_wofang")
		xyd.setUISpriteAsync(self.titleGroup:ComponentByName("bg2", typeof(UISprite)), nil, "guild_new_war2_bg_wofang")
	else
		self.labelSelf.text = __("GUILD_NEW_WAR_TEXT75")
		self.labelSelf.effectColor = Color.New2(3088991487.0)

		xyd.setUISpriteAsync(self.titleGroup:ComponentByName("bg", typeof(UISprite)), nil, "guild_new_war2_bg_difang")
		xyd.setUISpriteAsync(self.titleGroup:ComponentByName("bg2", typeof(UISprite)), nil, "guild_new_war2_bg_difang")
	end

	self.nodeType = self.activityData:getNodeType(self.nodeIndex)
	local isDestoy = true

	for j = 1, #self.nodeDetailData.list do
		if self.nodeDetailData.list[j].HP > 0 then
			isDestoy = false
		end
	end

	local spriteName = self.activityData:getFlagImgName(self.nodeIndex <= 6, self.nodeIndex, isDestoy)

	xyd.setUISpriteAsync(self.imgNode, nil, spriteName, nil, , true)

	local winTop = WindowTop.new(self.window_, self.name_, 1, true)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	winTop:setItem(items)

	self.windowTop = winTop

	self:updateNodeInfoGroup()
	self:updateFlagList()
end

function GuildNewWarPreviewWindow:updateNodeInfoGroup()
	self.nodeDetailData = self.activityData:getNodeDetailData(self.nodeIndex)
	local list = self.nodeDetailData.list
	local nodeBaseInfo = self.nodeDetailData.baseInfo
	local textID = xyd.tables.guildNewWarBaseTable:getTextId1(self.nodeType)
	self.labelNodeName.text = xyd.tables.guildNewWarBaseTextTable:getDesc(textID)
	textID = xyd.tables.guildNewWarBaseTable:getTextId2(self.nodeType)
	local textStr = xyd.tables.guildNewWarBaseTextTable:getDesc(textID)
	self.labelFlagNum.text = xyd.stringFormat(textStr, nodeBaseInfo.curFlagNum, nodeBaseInfo.maxFlagNum)
	local isAiming = false
	local baseInfo = self.activityData:getBaseInfo()
	local aimNodeID = baseInfo.rally

	if aimNodeID and aimNodeID > 0 then
		aimNodeID = aimNodeID + 6
		isAiming = aimNodeID == self.nodeIndex
	end

	if isAiming and not self.isSelf then
		self.aimGroup:SetActive(true)

		self.labelAim.text = __("GUILD_NEW_WAR_TEXT92")

		xyd.applyChildrenGrey(self.btnAim.gameObject)
		self.btnAim:SetActive(true)
	else
		self.labelAim.text = __("GUILD_NEW_WAR_TEXT22")

		self.aimGroup:SetActive(false)
		self.btnAim:SetActive(not self.isSelf)
	end

	local tableIndex = self.nodeIndex

	if tableIndex > 6 then
		tableIndex = tableIndex - 6
	end

	local skillID = xyd.tables.guildNewWarBaseTable:getSkillId(tableIndex)

	if skillID and skillID > 0 then
		self.labelBuff.text = xyd.tables.skillTextTable:getDesc(skillID)
	else
		self.labelBuff.text = __("GUILD_NEW_WAR_TEXT91")
	end

	local show = true

	if not self.isSelf then
		if self.curPeriod ~= xyd.GuildNewWarPeroid.FIGHTING1 then
			if self.curPeriod == xyd.GuildNewWarPeroid.FIGHTING2 then
				-- Nothing
			end
		end
	else
		show = false
	end

	if show then
		for i = 7, 12 do
			local nodeDetailData = self.activityData:getNodeDetailData(i)
			local nodeBaseInfo = nodeDetailData.baseInfo

			if nodeBaseInfo.curFlagNum > 0 then
				show = false
			end
		end
	end

	self.btnClean:SetActive(show)
end

function GuildNewWarPreviewWindow:updateFlagList()
	self.nodeDetailData = self.activityData:getNodeDetailData(self.nodeIndex)
	local baseInfo = self.nodeDetailData.baseInfo
	local list = self.nodeDetailData.list

	if self.wrapContent == nil then
		local wrapContent = self.flagScroller:ComponentByName("flagGroup", typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.flagScrollView, wrapContent, self.flagItem.gameObject, GuildNewWarPreviewItem, self)
	end

	self.wrapContent:setInfos(list, {})
	self.flagScrollView:ResetPosition()
end

function GuildNewWarPreviewItem:ctor(go, parent)
	GuildNewWarPreviewItem.super.ctor(self, go, parent)

	self.parent = parent
end

function GuildNewWarPreviewItem:initUI()
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.labelTitle = self.go:ComponentByName("labelTitle", typeof(UILabel))
	self.labelHP = self.go:ComponentByName("labelHP", typeof(UILabel))
	self.labelBraveHP = self.go:ComponentByName("labelBraveHP", typeof(UILabel))
	self.icon = self.labelBraveHP:ComponentByName("icon", typeof(UISprite))
	self.imgFlag = self.go:ComponentByName("imgFlag", typeof(UISprite))
	self.btnAdd = self.go:NodeByName("btnAdd").gameObject
	self.labelAdd = self.btnAdd:ComponentByName("labelAdd", typeof(UILabel))
	self.btnExchange = self.go:NodeByName("btnExchange").gameObject
	self.labelExchange = self.btnExchange:ComponentByName("labelExchange", typeof(UILabel))
	self.playerGroup = self.go:NodeByName("playerGroup").gameObject
	self.labelPlayerName = self.playerGroup:ComponentByName("labelPlayerName", typeof(UILabel))
	self.labelPlayerPower = self.playerGroup:ComponentByName("labelPlayerPower", typeof(UILabel))
	self.rolePos = self.playerGroup:ComponentByName("rolePos", typeof(UIWidget))
	self.btnChallege = self.go:NodeByName("btnChallege").gameObject
	self.labelChallege = self.btnChallege:ComponentByName("labelChallege", typeof(UILabel))
	self.btnDestroy = self.go:NodeByName("btnDestroy").gameObject
	self.labelDestroyTips = self.go:ComponentByName("labelDestroyTips", typeof(UILabel))
	self.labelNoPlayerTips = self.go:ComponentByName("labelNoPlayerTips", typeof(UILabel))
	self.labelDestroy = self.btnDestroy:ComponentByName("labelDestroy", typeof(UILabel))
	self.destroyGroup = self.go:NodeByName("destroyGroup").gameObject
	self.labelHaveDestroy = self.destroyGroup:ComponentByName("labelHaveDestroy", typeof(UILabel))

	UIEventListener.Get(self.btnAdd.gameObject).onClick = function ()
		if xyd.models.guild.guildJob ~= xyd.GUILD_JOB.LEADER and xyd.models.guild.guildJob ~= xyd.GUILD_JOB.VICE_LEADER then
			xyd.alertTips(__("GUILD_NEW_WAR_TIPS03"))

			return
		end

		self.parent.activityData:checkNeedReqGuildMemberInfo(function ()
			xyd.openWindow("guild_new_war_set_def_player_window", {
				nodeIndex = self.parent.nodeIndex,
				flagIndex = self.data.id,
				selectedPlayerID = self.data.playerInfo.player_id
			})
		end)
	end

	UIEventListener.Get(self.btnExchange.gameObject).onClick = function ()
		if xyd.models.guild.guildJob ~= xyd.GUILD_JOB.LEADER and xyd.models.guild.guildJob ~= xyd.GUILD_JOB.VICE_LEADER then
			xyd.alertTips(__("GUILD_NEW_WAR_TIPS03"))

			return
		end

		self.parent.activityData:checkNeedReqGuildMemberInfo(function ()
			xyd.openWindow("guild_new_war_set_def_player_window", {
				nodeIndex = self.parent.nodeIndex,
				flagIndex = self.data.id,
				selectedPlayerID = self.data.playerInfo.player_id
			})
		end)
	end

	UIEventListener.Get(self.btnChallege.gameObject).onClick = function ()
		local can = false
		local nodeType = self.parent.activityData:getNodeType(self.parent.nodeIndex)

		if not can then
			if nodeType == xyd.GuildNewWarNodeType.MID or nodeType == xyd.GuildNewWarNodeType.RIGHT_MID or nodeType == xyd.GuildNewWarNodeType.LEFT_MID then
				for i = 7, 8 do
					local nodeDetailData = self.parent.activityData:getNodeDetailData(i)
					local nodeBaseInfo = nodeDetailData.baseInfo

					if nodeBaseInfo.curFlagNum <= 0 then
						can = true

						break
					end
				end
			elseif nodeType == xyd.GuildNewWarNodeType.MAIN then
				for i = 7, 8 do
					local nodeDetailData = self.parent.activityData:getNodeDetailData(i)
					local nodeBaseInfo = nodeDetailData.baseInfo

					if nodeBaseInfo.curFlagNum <= 0 then
						for i = 9, 11 do
							local nodeDetailData = self.parent.activityData:getNodeDetailData(i)
							local nodeBaseInfo = nodeDetailData.baseInfo

							if nodeBaseInfo.curFlagNum <= 0 then
								can = true

								break
							end
						end
					end
				end
			else
				can = true
			end
		end

		if not can then
			if nodeType == xyd.GuildNewWarNodeType.MAIN then
				xyd.alertTips(__("GUILD_NEW_WAR_TIPS13"))

				return
			else
				xyd.alertTips(__("GUILD_NEW_WAR_TIPS12"))

				return
			end
		end

		self.parent.activityData:checkHaveEnemyInfo(self.data.playerInfo.player_id, function ()
			local data = {
				enemyInfo = {
					playerInfo = self.data.playerInfo
				},
				selfInfo = {
					playerInfo = {
						power = 100000,
						player_name = xyd.Global.playerName,
						dress_style = xyd.models.dress:getEffectEquipedStyles(),
						lev = xyd.models.backpack:getLev(),
						avatar_id = xyd.models.selfPlayer:getAvatarID(),
						avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
						server_id = xyd.models.selfPlayer:getServerID()
					}
				}
			}

			self.parent.activityData:setTempBattleEnemyInfo(self.data.playerInfo)
			xyd.openWindow("guild_new_war_fight_window", {
				data = data,
				nodeID = self.parent.nodeIndex,
				flagID = self.data.id
			})
		end)
	end

	UIEventListener.Get(self.btnDestroy.gameObject).onClick = function ()
		local can = false
		local nodeType = self.parent.activityData:getNodeType(self.parent.nodeIndex)

		if not can then
			if nodeType == xyd.GuildNewWarNodeType.MID or nodeType == xyd.GuildNewWarNodeType.RIGHT_MID or nodeType == xyd.GuildNewWarNodeType.LEFT_MID then
				for i = 7, 8 do
					local nodeDetailData = self.parent.activityData:getNodeDetailData(i)
					local nodeBaseInfo = nodeDetailData.baseInfo

					if nodeBaseInfo.curFlagNum <= 0 then
						can = true

						break
					end
				end
			elseif nodeType == xyd.GuildNewWarNodeType.MAIN then
				for i = 7, 8 do
					local nodeDetailData = self.parent.activityData:getNodeDetailData(i)
					local nodeBaseInfo = nodeDetailData.baseInfo

					if nodeBaseInfo.curFlagNum <= 0 then
						for i = 9, 11 do
							local nodeDetailData = self.parent.activityData:getNodeDetailData(i)
							local nodeBaseInfo = nodeDetailData.baseInfo

							if nodeBaseInfo.curFlagNum <= 0 then
								can = true

								break
							end
						end
					end
				end
			else
				can = true
			end
		end

		if not can then
			if nodeType == xyd.GuildNewWarNodeType.MAIN then
				xyd.alertTips(__("GUILD_NEW_WAR_TIPS13"))

				return
			else
				xyd.alertTips(__("GUILD_NEW_WAR_TIPS12"))

				return
			end
		end

		xyd.openWindow("guild_new_war_destroy_window", {
			nodeIndex = self.parent.nodeIndex,
			flagIndex = self.data.id
		})
	end

	UIEventListener.Get(self.rolePos.gameObject).onClick = function ()
		xyd.openWindow("guild_new_war_player_formation_window", {
			data = self.data
		})
	end

	self.labelAdd.text = __("GUILD_NEW_WAR_TEXT26")
	self.labelExchange.text = __("GUILD_NEW_WAR_TEXT27")
	self.labelChallege.text = __("GUILD_NEW_WAR_TEXT50")
	self.labelDestroy.text = __("GUILD_NEW_WAR_TEXT87")
	self.labelHaveDestroy.text = __("GUILD_NEW_WAR_TEXT88")
	self.labelDestroyTips.text = __("GUILD_NEW_WAR_TEXT52")
	self.labelNoPlayerTips.text = __("GUILD_NEW_WAR_TEXT90")

	if xyd.Global.lang == "fr_fr" then
		self.labelNoPlayerTips:X(50)

		self.labelNoPlayerTips.width = 450
	end
end

function GuildNewWarPreviewItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo(index)
end

function GuildNewWarPreviewItem:updateInfo(index)
	self.id = self.data.id
	self.braveHP = self.data.braveHP
	local spriteName = self.parent.activityData:getFlagImgName(self.parent.nodeIndex <= 6, self.parent.nodeIndex, self.data.HP <= 0, true)

	xyd.setUISpriteAsync(self.imgFlag, nil, spriteName, function ()
		self.imgFlag.gameObject.transform.localScale = Vector3(0.638095238095238, 0.638095238095238, 0)
	end, nil, true)

	self.labelTitle.text = __("GUILD_NEW_WAR_TEXT24", self.id)
	local helpData = xyd.tables.miscTable:split2num("guild_new_war_flag_durability", "value", "|")
	self.labelHP.text = __("GUILD_NEW_WAR_TEXT25", helpData[1], self.data.HP)
	self.labelBraveHP.text = self.data.braveHP

	self.labelBraveHP:SetActive(false)

	if self.data.HP <= 0 then
		self.destroyGroup:SetActive(true)
		self.labelBraveHP:SetActive(false)
	else
		self.destroyGroup:SetActive(false)
	end

	self.btnAdd:SetActive(self:checkCanShowBtnAdd())
	self.btnExchange:SetActive(self:checkCanShowBtnExchange())
	self.btnChallege:SetActive(self:checkCanShowBtnChallege())
	self.btnDestroy:SetActive(self:checkCanShowBtnDestroy())
	self.labelDestroyTips:SetActive(self:checkCanShowBtnDestroy())

	if self.parent.isSelf then
		xyd.setUISpriteAsync(self.imgNode, nil, "guild_new_war2_icon_qizhi_2")

		self.data.guild_id = self.parent.activityData:getBaseInfo().self_guild.base_info.guild_id
		self.data.guild_name = self.parent.activityData:getBaseInfo().self_guild.base_info.name
	else
		xyd.setUISpriteAsync(self.imgNode, nil, "guild_new_war2_icon_qizhi_1")

		self.data.guild_id = self.parent.activityData:getBaseInfo().match_guild.base_info.guild_id
		self.data.guild_name = self.parent.activityData:getBaseInfo().match_guild.base_info.name
	end

	if (self.parent.curPeriod == xyd.GuildNewWarPeroid.FIGHTING1 or self.parent.curPeriod == xyd.GuildNewWarPeroid.FIGHTING2) and self.data.HP <= 0 then
		xyd.setUISpriteAsync(self.bg, nil, "guild_new_war2_bg_3")

		self.labelTitle.effectColor = Color.New2(1852731135)
	elseif self.parent.isSelf then
		xyd.setUISpriteAsync(self.bg, nil, "guild_new_war2_bg_1")

		self.labelTitle.effectColor = Color.New2(896118783)
	else
		xyd.setUISpriteAsync(self.bg, nil, "guild_new_war2_bg_2")

		self.labelTitle.effectColor = Color.New2(3091292415.0)
	end

	self.labelNoPlayerTips:SetActive(false)

	if self.parent.curPeriod == xyd.GuildNewWarPeroid.READY1 or self.parent.curPeriod == xyd.GuildNewWarPeroid.READY2 then
		if self.data.playerInfo and self.data.playerInfo.player_id and self.data.playerInfo.player_id > 0 then
			if self.parent.isSelf then
				self.playerGroup:SetActive(true)
			end

			self.rolePos:ComponentByName("", typeof(UITexture)).depth = 100 + 10 * index

			if not self.roleModel then
				self.roleModel = import("app.components.SenpaiModel").new(self.rolePos.gameObject)
			end

			self.labelBraveHP:SetActive(true)
			self.roleModel:setModelInfo({
				isNewClipShader = true,
				ids = self.data.playerInfo.dress_style,
				pos = Vector3(0, -150, 0),
				textureSize = Vector2(2, 300)
			})

			self.labelPlayerName.text = self.data.playerInfo.player_name
			self.labelPlayerPower.text = self.data.playerInfo.power

			self.roleModel:setRenderTarget(self.rolePos, 1)
			self.rolePos:SetActive(false)
			self:waitForFrame(1, function ()
				self.rolePos:SetActive(true)
			end)
		else
			self.playerGroup:SetActive(false)
		end
	elseif self.parent.curPeriod == xyd.GuildNewWarPeroid.FIGHTING1 or self.parent.curPeriod == xyd.GuildNewWarPeroid.FIGHTING2 then
		if self.data.HP <= 0 then
			self.playerGroup:SetActive(false)
		elseif self.data.braveHP <= 0 or not self.data.playerInfo.player_id or self.data.playerInfo.player_id == 0 then
			self.playerGroup:SetActive(false)

			if self.parent.isSelf then
				self.labelNoPlayerTips:SetActive(true)
			end
		elseif self.data.playerInfo and self.data.playerInfo.player_id and self.data.playerInfo.player_id > 0 then
			self.playerGroup:SetActive(true)

			self.rolePos:ComponentByName("", typeof(UITexture)).depth = 100 + 10 * index

			if not self.roleModel then
				self.roleModel = import("app.components.SenpaiModel").new(self.rolePos.gameObject)
			end

			if self.data.playerInfo and self.data.playerInfo.player_id and self.data.playerInfo.player_id > 0 then
				self.roleModel:setModelInfo({
					isNewClipShader = true,
					ids = self.data.playerInfo.dress_style,
					pos = Vector3(0, -150, 0),
					textureSize = Vector2(2, 300)
				})

				self.labelPlayerName.text = self.data.playerInfo.player_name
				self.labelPlayerPower.text = self.data.playerInfo.power

				self.labelBraveHP:SetActive(true)
				self.roleModel:setRenderTarget(self.rolePos, 1)
				self.rolePos:SetActive(false)
				self:waitForFrame(1, function ()
					self.rolePos:SetActive(true)
				end)
			end
		else
			self.playerGroup:SetActive(false)

			if self.parent.isSelf then
				self.labelNoPlayerTips:SetActive(true)
			end
		end
	end
end

function GuildNewWarPreviewItem:checkCanShowBtnAdd()
	local flag = false

	if self.parent.isSelf and (self.parent.curPeriod == xyd.GuildNewWarPeroid.READY1 or self.parent.curPeriod == xyd.GuildNewWarPeroid.READY2) and (not self.data.playerInfo or not self.data.playerInfo.player_id or self.data.playerInfo.player_id == 0) then
		flag = true
	end

	return flag
end

function GuildNewWarPreviewItem:checkCanShowBtnExchange()
	local flag = false

	if self.parent.isSelf and (self.parent.curPeriod == xyd.GuildNewWarPeroid.READY1 or self.parent.curPeriod == xyd.GuildNewWarPeroid.READY2) and self.data.playerInfo and self.data.playerInfo.player_id then
		flag = true
	end

	return flag
end

function GuildNewWarPreviewItem:checkCanShowBtnChallege()
	local flag = false

	if not self.parent.isSelf and (self.parent.curPeriod == xyd.GuildNewWarPeroid.FIGHTING1 or self.parent.curPeriod == xyd.GuildNewWarPeroid.FIGHTING2) and self.data.playerInfo and self.data.playerInfo.player_id and self.data.braveHP > 0 and self.data.playerInfo.player_id and self.data.playerInfo.player_id > 0 then
		flag = true
	end

	return flag
end

function GuildNewWarPreviewItem:checkCanShowBtnDestroy()
	local flag = false

	if not self.parent.isSelf and (self.parent.curPeriod == xyd.GuildNewWarPeroid.FIGHTING1 or self.parent.curPeriod == xyd.GuildNewWarPeroid.FIGHTING2) and (self.data.braveHP <= 0 or not self.data.playerInfo.player_id or self.data.playerInfo.player_id == 0) and self.data.HP > 0 then
		flag = true
	end

	return flag
end

return GuildNewWarPreviewWindow
