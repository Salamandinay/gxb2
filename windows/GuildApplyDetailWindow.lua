local BaseWindow = import(".BaseWindow")
local GuildMemberItem = require("app.windows.GuildWindow").GuildMemberItem
local GuildApplyDetailWindow = class("GuildApplyDetailWindow", BaseWindow)

function GuildApplyDetailWindow:ctor(name, params)
	GuildApplyDetailWindow.super.ctor(self, name, params)

	self.members_ = params.data.members
	self.baseInfo_ = params.data.base_info
	self.isFromFormation_ = params.isFromFormation
	local selfGuildId = xyd.models.guild.guildID

	if not selfGuildId or selfGuildId == 0 then
		self.noClick = false
	elseif tonumber(selfGuildId) ~= tonumber(self.baseInfo_.guild_id) then
		self.noClick = true
	end

	self.itemList_ = {}
end

function GuildApplyDetailWindow:playOpenAnimation(callback)
	GuildApplyDetailWindow.super.playOpenAnimation(self, function ()
		if callback then
			callback()
		end

		self:setMemberList()
	end)
end

function GuildApplyDetailWindow:initWindow()
	GuildApplyDetailWindow.super.initWindow(self)

	local go = self.window_
	local group = go:NodeByName("group_action").gameObject
	self.labelWinTitle = group:ComponentByName("labelWinTitle", typeof(UILabel))
	self.btnApply = group:NodeByName("btnApply").gameObject
	self.btnApply_label = group:ComponentByName("btnApply/button_label", typeof(UILabel))
	self.closeBtn = group:NodeByName("closeBtn").gameObject
	self.imgFlag = group:ComponentByName("imgFlag", typeof(UISprite))
	self.scrollView_ = group:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.labelNotice = group:ComponentByName("e:Scroller/labelNotice", typeof(UILabel))
	self.labelName = group:ComponentByName("labelName", typeof(UILabel))
	self.labelID = group:ComponentByName("labelID", typeof(UILabel))
	self.labelIDNum = group:ComponentByName("labelIDNum", typeof(UILabel))
	self.labelLevel = group:ComponentByName("labelLevel", typeof(UILabel))
	self.labelNum = group:ComponentByName("labelNum", typeof(UILabel))
	self.labelLang = group:ComponentByName("labelLang", typeof(UILabel))
	self.expProgress_label = group:ComponentByName("expProgress/labelDisplay", typeof(UILabel))
	self.scroll_ = group:ComponentByName("scroll", typeof(UIScrollView))
	self.groupItems = group:ComponentByName("scroll/groupItems", typeof(UIGrid))
	self.expProgress = group:ComponentByName("expProgress", typeof(UIProgressBar))
	self.tipsNum = group:ComponentByName("tipsNum", typeof(UILabel))
	self.tipsLang = group:ComponentByName("tipsLang", typeof(UILabel))
	self.tipsOpen = group:ComponentByName("tipsOpen", typeof(UILabel))
	self.tipsPower = group:ComponentByName("tipsPower", typeof(UILabel))
	self.labelOpen = group:ComponentByName("labelOpen", typeof(UILabel))
	self.labelPower = group:ComponentByName("labelPower", typeof(UILabel))
	self.tipsPolicy = group:ComponentByName("tipsPolicy", typeof(UILabel))
	self.labelPolicy = group:ComponentByName("labelPolicy", typeof(UILabel))
	self.tranlationBtn = group:NodeByName("tranlationPanel/tranlationBtn").gameObject

	self:setLayout()
	self:registerEvent()
end

function GuildApplyDetailWindow:updateOpenLabel()
	self.labelOpen.text = __("GUILD_OPEN_TYPE" .. self.baseInfo_.apply_way)
end

function GuildApplyDetailWindow:updatePowerLimit()
	self.labelPower.text = self.baseInfo_.power_limit
end

function GuildApplyDetailWindow:updatePolicy()
	self.labelPolicy.text = __("GUILD_POLICY_TEXT" .. self.baseInfo_.plan)
end

function GuildApplyDetailWindow:setLayout()
	local data = self.baseInfo_
	local level = xyd.tables.guildExpTable:getLev(self.baseInfo_.exp)
	local flagName = xyd.tables.guildIconTable:getIcon(data.flag)

	xyd.setUISpriteAsync(self.imgFlag, nil, flagName)

	self.labelName.text = data.name
	self.labelIDNum.text = data.guild_id
	self.labelID.text = __("GUILD_ID_TIPS")
	self.labelLevel.text = "Lv." .. tostring(level)

	if not data.announcement or data.announcement == "" then
		self.labelNotice.text = __("GUILD_TEXT01")
	else
		self.labelNotice.text = data.announcement
	end

	self.scrollView_:ResetPosition()

	if not self.baseInfo_.language then
		self.labelLang.text = __("GUILD_LANGUAGE_UNSET")
	else
		self.labelLang.text = xyd.tables.playerLanguageTable:getTrueName(self.baseInfo_.language)
	end

	self.tipsNum.text = __("GUILD_NUM_TIPS")
	self.tipsLang.text = __("GUILD_LANG_TIPS")
	self.tipsOpen.text = __("GUILD_OPEN_TYPE_LABEL")
	self.tipsPower.text = __("GUILD_OPWER_LIMIT_LABEL")
	self.tipsPolicy.text = __("GUILD_POLICY_TIPS")

	self:updateOpenLabel()
	self:updatePolicy()
	self:updatePowerLimit()

	local members = self.members_
	self.labelNum.text = tostring(#members) .. "/" .. tostring(xyd.tables.guildExpTable:getMember(level))
	local max = #xyd.tables.guildExpTable:getIDs()

	if level >= max then
		self.expProgress.value = 1
	else
		local unitExp = xyd.tables.guildExpTable:getAllExp(level)
		self.expProgress.value = (data.exp - unitExp) / (xyd.tables.guildExpTable:getAllExp(level + 1) - unitExp)
	end

	self.btnApply_label.text = __("GUILD_APPLY")

	if xyd.models.guild.guildID > 0 then
		xyd.setEnabled(self.btnApply, false)
	end

	local table_ = xyd.tables.serverMapTable
	local hostSelf = table_:getTimeHostMix(xyd.models.selfPlayer:getServerID())

	if hostSelf ~= table_:getTimeHostMix(self.baseInfo_.server_id) then
		xyd.setEnabled(self.btnApply, false)
	end

	xyd.setDarkenBtnBehavior(self.tranlationBtn, self, self.onTouchTranlation)
end

function GuildApplyDetailWindow:onTouchTranlation()
	if self.inTrans then
		xyd.showToast(__("CHAT_TRANSLATEING"))

		return
	end

	if not self.showTrans then
		local data = self.baseInfo_
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
		local data = self.baseInfo_
		self.labelNotice.text = data.announcement == "" and __("GUILD_TEXT01") or data.announcement
		self.inTrans = false
		self.showTrans = false
	end
end

function GuildApplyDetailWindow:registerEvent()
	UIEventListener.Get(self.btnApply).onClick = function ()
		local selfPower = xyd.models.slot:calSelfPower() or 0
		local needPower = self.baseInfo_.power_limit or 0

		if tonumber(self.baseInfo_.apply_way) and tonumber(self.baseInfo_.apply_way) == 3 then
			xyd.alertTips(__("GUILD_APPLY_NO_ACCEPUT"))

			return
		elseif selfPower < needPower then
			xyd.alertTips(__("GUILD_APPLY_NEED_POWER"))

			return
		end

		xyd.models.guild:apply(self.baseInfo_.guild_id)
	end

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:onClickCloseButton()
	end

	self.eventProxy_:addEventListener(xyd.event.GUILD_APPLY, self.onApplyGuild, self)
end

function GuildApplyDetailWindow:onApplyGuild()
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.GUILD_SINGLE_REFRESH,
		data = {
			guild_id = self.baseInfo_.guild_id
		}
	})

	if self.baseInfo_.apply_way and tonumber(self.baseInfo_.apply_way) == 2 then
		xyd.WindowManager.get():closeAllWindows({
			func_open_window = true,
			main_window = true,
			loading_window = true
		}, true)
		self:waitForFrame(5, function ()
			xyd.WindowManager.get():openWindow("guild_territory_window", {}, function ()
				xyd.WindowManager.get():closeWindow(self.name_)
			end)
		end)
	else
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function GuildApplyDetailWindow:setMemberList()
	local members = self.members_

	table.sort(members, function (a, b)
		return b.job < a.job
	end)

	local panel = self.scroll_:GetComponent(typeof(UIPanel))

	for idx, memberInfo in ipairs(members) do
		if not self.window_ or tolua.isnull(self.window_.gameObject) then
			return
		end

		if not self.itemList_[idx] then
			local item = GuildMemberItem.new(self.groupItems.gameObject, memberInfo, function ()
				if memberInfo.player_id == xyd.models.selfPlayer:getPlayerID() then
					return
				end

				xyd.WindowManager.get():openWindow("arena_formation_window", {
					not_show_guild_btn = true,
					is_robot = false,
					player_id = memberInfo.player_id
				})
			end, panel)

			if self.isFromFormation_ then
				item:setFormationData(self.noClick)
			end

			self.itemList_[idx] = item
		end

		self.groupItems:Reposition()

		if idx == 1 or idx == #members then
			self.scroll_:ResetPosition()
		end
	end
end

return GuildApplyDetailWindow
