local BaseWindow = import(".BaseWindow")
local GuildSettingWindow = class("GuildSettingWindow", BaseWindow)

function GuildSettingWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.openType_ = tonumber(xyd.models.guild.base_info.apply_way)
	self.choosePolicy_ = tonumber(xyd.models.guild.base_info.plan)
	self.items = {}
end

function GuildSettingWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function GuildSettingWindow:getUIComponent()
	local group = self.window_:NodeByName("e:Group").gameObject
	local go = self.window_:NodeByName("guild_create").gameObject
	self.labelWinTitle = group:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = group:NodeByName("closeBtn").gameObject
	self.imgIcon = go:NodeByName("imgIcon").gameObject
	self.textInput = go:ComponentByName("textInput", typeof(UILabel))
	self.imgLang = go:NodeByName("imgLang").gameObject
	self.btnIcon = go:NodeByName("btnIcon").gameObject
	self.btnLang = go:NodeByName("btnLang").gameObject
	self.btnPolicy = go:NodeByName("btnPolicy").gameObject
	self.btnIcon_label = self.btnIcon:ComponentByName("button_label", typeof(UILabel))
	self.btnLang_label = self.btnLang:ComponentByName("button_label", typeof(UILabel))
	self.btnPolicy_label = self.btnPolicy:ComponentByName("button_label", typeof(UILabel))
	self.editableText = go:ComponentByName("editScroll/editableText", typeof(UILabel))
	self.btnDissolve = go:NodeByName("btnDissolve").gameObject
	self.btnDissolve_label = self.btnDissolve:ComponentByName("button_label", typeof(UILabel))
	self.btnCancel = go:NodeByName("btnCancel").gameObject
	self.btnCancel_label = self.btnCancel:ComponentByName("button_label", typeof(UILabel))
	self.btnName = go:NodeByName("btnName").gameObject
	local labelTime = go:ComponentByName("labelTime", typeof(UILabel))
	self.labelTime = require("app.components.CountDown").new(labelTime)
	self.openTypeLabel_ = go:ComponentByName("e:Image2/labelText", typeof(UILabel))
	self.btnLeft_ = go:NodeByName("btnLeft").gameObject
	self.btnRight_ = go:NodeByName("btnRight").gameObject
	self.selectNumPos_ = go:NodeByName("selectNumRoot").gameObject
	self.selectNum_ = import("app.components.SelectNum").new(self.selectNumPos_, "default")
	self.labelType_ = go:ComponentByName("labelType", typeof(UILabel))
	self.labelPower_ = go:ComponentByName("labelPower", typeof(UILabel))
	self.inputBg = go:NodeByName("inputBg").gameObject
end

function GuildSettingWindow:updateOpenType()
	local textList = {
		__("GUILD_OPEN_TYPE1"),
		__("GUILD_OPEN_TYPE2"),
		__("GUILD_OPEN_TYPE3")
	}
	self.openTypeLabel_.text = textList[self.openType_]
end

function GuildSettingWindow:initUIComponent()
	self.btnDissolve:SetActive(false)
	self.btnCancel:SetActive(false)
	self.labelTime:SetActive(false)

	self.textInput.text = xyd.models.guild.base_info.name

	if xyd.models.guild.base_info.announcement and xyd.models.guild.base_info.announcement ~= "" then
		self.editableText.text = xyd.models.guild.base_info.announcement
		self.editableText.color = Color.New2(4294967295.0)
	else
		self.editableText.text = __("GUILD_TEXT61")
		self.editableText.color = Color.New2(3385711103.0)
	end

	self.btnPolicy_label.text = __("GUILD_POLICY_BTN_LABEL")
	self.btnIcon_label.text = __("GUILD_CHOOSE_FLAG")
	self.btnLang_label.text = __("GUILD_CHOOSE_LANG")
	self.btnDissolve_label.text = __("GUILD_TEXT46")

	xyd.setBgColorType(self.btnDissolve, xyd.ButtonBgColorType.red_btn_65_65)

	self.btnCancel_label.text = __("GUILD_TEXT47")

	xyd.setBgColorType(self.btnCancel, xyd.ButtonBgColorType.blue_btn_70_70)

	local flag = xyd.models.guild.base_info.flag

	xyd.setUISprite(self.imgIcon:GetComponent(typeof(UISprite)), nil, xyd.tables.guildIconTable:getIcon(flag))

	if xyd.models.guild.guildJob == xyd.GUILD_JOB.LEADER then
		self.btnDissolve:SetActive(xyd.models.guild.base_info.dissolve_time == 0)
		self.btnCancel:SetActive(xyd.models.guild.base_info.dissolve_time > 0)

		if xyd.models.guild.base_info.dissolve_time > 0 then
			local time = xyd.models.guild.base_info.dissolve_time + xyd.tables.miscTable:getNumber("guild_dissolve_cd", "value") - xyd.getServerTime()

			if time > 0 then
				self.labelTime:setInfo({
					duration = time
				})
				self.labelTime:SetActive(true)
			end
		end
	end

	local maxNum = tonumber(xyd.tables.miscTable:getVal("max_guild_limit"))
	local minNum = tonumber(xyd.tables.miscTable:getVal("min_guild_limit"))
	local feetNum = tonumber(xyd.tables.miscTable:getVal("change_guild_limit"))

	local function callbackFunction(num)
		self.limitPowerNum_ = num
	end

	self.selectNum_:setInfo({
		delForceZero = true,
		maxNum = maxNum,
		minNum = minNum,
		callback = callbackFunction,
		feetNum = feetNum,
		curNum = xyd.models.guild.base_info.power_limit
	})
	self.selectNum_:setPrompt(0)
	self.selectNum_:setKeyboardPos(0, -130)
	self.selectNum_:setSelectBGSize(304)
	self.selectNum_:setBtnScale(0.84)
	self.selectNum_:setBtnPos(203)
	self.selectNum_:setKeyboardScale(0.65, 0.65)
	self:updateOpenType()

	self.labelType_.text = __("GUILD_OPEN_TYPE_LABEL")
	self.labelPower_.text = __("GUILD_OPWER_LIMIT_LABEL")

	if xyd.Global.lang == "fr_fr" then
		self.labelType_.text = __("GUILD_OPEN_TYPE_LABEL2")
		self.labelPower_.text = __("GUILD_OPWER_LIMIT_LABEL2")
	end

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
		self.labelType_.fontSize = 22
		self.labelPower_.fontSize = 22
	end
end

function GuildSettingWindow:registerEvent()
	self:setCloseBtn(self.closeBtn)
	xyd.setDarkenBtnBehavior(self.btnIcon, self, self.chooseIcon)
	xyd.setDarkenBtnBehavior(self.imgIcon, self, self.chooseIcon)
	xyd.setDarkenBtnBehavior(self.btnLang, self, self.chooseLang)
	xyd.setDarkenBtnBehavior(self.imgLang, self, self.chooseLang)
	xyd.setDarkenBtnBehavior(self.btnName, self, self.editName)
	xyd.setDarkenBtnBehavior(self.btnDissolve, self, self.guildDissolveOrCancel)
	xyd.setDarkenBtnBehavior(self.btnCancel, self, self.guildDissolveOrCancel)
	xyd.setDarkenBtnBehavior(self.btnRight_, self, self.onClickRight)
	xyd.setDarkenBtnBehavior(self.btnLeft_, self, self.onClickLeft)
	xyd.setDarkenBtnBehavior(self.btnPolicy, self, self.choosePolicy)

	UIEventListener.Get(self.editableText.gameObject).onClick = function ()
		self:editAnnouncement()
	end

	UIEventListener.Get(self.inputBg).onClick = function ()
		self:editAnnouncement()
	end

	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_NAME, self.onEditGuildName, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_DISSOLVE, self.onGuildDissolve, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_ANNOUNCEMENT, self.onGuildAnnouncement, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_FLAG, self.onGuildFlag, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_CANCEL_DISSOLVE, self.onCancelGuildDissolve, self)
end

function GuildSettingWindow:choosePolicy()
	xyd.WindowManager.get():openWindow("guild_policy_select_window", {
		policy = self.choosePolicy_,
		callback = function (policy)
			self.choosePolicy_ = policy
		end,
		closeCallBack = function ()
			if self.choosePolicy_ and self.choosePolicy_ ~= tonumber(xyd.models.guild.base_info.plan) then
				xyd.models.guild:reqChangePlan(self.choosePolicy_)
				xyd.alertTips(__("GUILD_POLICY_CHANGED_TIP"))
			end
		end
	})
end

function GuildSettingWindow:onClickRight()
	self.openType_ = self.openType_ + 1

	if self.openType_ > 3 then
		self.openType_ = 1
	end

	self:updateOpenType()
end

function GuildSettingWindow:onClickLeft()
	self.openType_ = self.openType_ - 1

	if self.openType_ <= 0 then
		self.openType_ = 3
	end

	self:updateOpenType()
end

function GuildSettingWindow:chooseIcon()
	xyd.WindowManager.get():openWindow("guild_flag_window", {})
end

function GuildSettingWindow:chooseLang()
	local origin_lang = xyd.models.guild.base_info.language

	xyd.WindowManager.get():openWindow("guild_change_language_window", {
		callback = function (language)
			language = tonumber(language)

			if origin_lang == language then
				return
			end

			xyd.models.guild:editLanguage(language)
		end,
		language = xyd.models.guild.base_info.language
	})
end

function GuildSettingWindow:editName()
	xyd.WindowManager.get():openWindow("guild_namechange_window")
end

function GuildSettingWindow:editAnnouncement()
	xyd.WindowManager.get():openWindow("guild_announcement_window")
end

function GuildSettingWindow:fixInput()
	local emojiInput = self.window_:NodeByName("guild_create/editableLabel/Emoji Texture")

	if emojiInput and not tolua.isnull(emojiInput.gameObject) then
		emojiInput.gameObject:SetActive(false)
		self:waitForTime(0.2, function ()
			emojiInput.gameObject:SetActive(true)
		end)
	end
end

function GuildSettingWindow:onEditGuildName(event)
	self.textInput.text = xyd.models.guild.base_info.name
end

function GuildSettingWindow:guildDissolveOrCancel()
	local data = xyd.models.guild.base_info

	if data.dissolve_time and data.dissolve_time > 0 then
		xyd.models.guild:guildCancelDissolve()
	else
		if xyd.models.guild:getGuildCompetitionInfo() and xyd.models.guild:getGuildCompetitionLeftTime().type == 2 or xyd.models.guild:getGuildCompetitionInfo() and xyd.models.guild:getGuildCompetitionLeftTime().type == 1 and xyd.getServerTime() > xyd.models.guild:getGuildCompetitionLeftTime().curEndTime - 7200 - 60 then
			xyd.showToast(__("GUILD_COMPETITION_NO_TIPS3"))

			return
		end

		local newGuildWarData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)

		if newGuildWarData then
			local endTime, curPeriod = nil
			curPeriod, endTime = newGuildWarData:getCurPeriod()

			if curPeriod ~= xyd.GuildNewWarPeroid.BEGIN_RELAX and curPeriod ~= xyd.GuildNewWarPeroid.END_RELAX and (curPeriod ~= xyd.GuildNewWarPeroid.NORMAL_RELAX or endTime - xyd.getServerTime() <= 7260) then
				xyd.showToast(__("GUILD_NEW_WAR_TIPS10"))

				return
			end
		end

		xyd.alert(xyd.AlertType.YES_NO, __("GUILD_DISSOLVE_TIPS"), function (yes_no)
			if not yes_no then
				return
			end

			xyd.models.guild:guildDissolve()
		end)
	end
end

function GuildSettingWindow:onGuildDissolve(event)
	local time = xyd.models.guild.base_info.dissolve_time + xyd.tables.miscTable:getNumber("guild_dissolve_cd", "value") - xyd.getServerTime()

	if time > 0 then
		self.labelTime:SetActive(true)
		self.labelTime:setInfo({
			duration = time
		})
	end

	self.btnDissolve:SetActive(false)
	self.btnCancel:SetActive(true)
end

function GuildSettingWindow:onCancelGuildDissolve(event)
	self.btnCancel:SetActive(false)
	self.btnDissolve:SetActive(true)
	self.labelTime:stopTimeCount()
	self.labelTime:SetActive(false)
end

function GuildSettingWindow:onGuildAnnouncement(event)
	if xyd.models.guild.base_info.announcement and xyd.models.guild.base_info.announcement ~= "" then
		self.editableText.text = xyd.models.guild.base_info.announcement
		self.editableText.color = Color.New2(4294967295.0)
	else
		self.editableText.text = __("GUILD_TEXT61")
		self.editableText.color = Color.New2(3385711103.0)
	end
end

function GuildSettingWindow:onGuildFlag()
	local data = xyd.models.guild.base_info

	xyd.setUISprite(self.imgIcon:GetComponent(typeof(UISprite)), nil, xyd.tables.guildIconTable:getIcon(data.flag))
end

function GuildSettingWindow:willClose()
	local data = xyd.models.guild.base_info
	local numNow = tonumber(self.limitPowerNum_)

	if numNow and numNow ~= tonumber(data.power_limit) then
		xyd.models.guild:reqChangePower(numNow)
	end

	if self.openType_ and self.openType_ ~= tonumber(data.apply_way) then
		xyd.models.guild:reqChangeApplyWay(self.openType_)
	end
end

return GuildSettingWindow
