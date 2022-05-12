local CommonTabBar = import("app.common.ui.CommonTabBar")
local BaseWindow = import(".BaseWindow")
local GuildJoinWindow = class("GuildJoinWindow", BaseWindow)
local GuildRecommend = class("GuildRecommend", import("app.components.CopyComponent"))
local GuildSearch = class("GuildSearch", import("app.components.CopyComponent"))
local GuildCreate = class("GuildCreate", import("app.components.CopyComponent"))
local GuildRecommendItem = class("GuildRecommendItem", import("app.components.CopyComponent"))
local GuildNameChangeWindow = class("GuildNameChangeWindow", import("app.windows.GuildNameChangeWindow"))

function GuildJoinWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.components = {}
end

function GuildJoinWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
	self:setComponent(1)

	if not xyd.models.guild:isLoaded() then
		xyd.models.guild:reqGuildInfo()
	end

	xyd.models.guild:reqGuildFresh()
end

function GuildJoinWindow:getUIComponent()
	local go = self.window_:NodeByName("groupAction")
	self.guild_create = go:NodeByName("guild_create").gameObject
	self.guild_recommend = go:NodeByName("guild_recommend").gameObject
	self.guild_search = go:NodeByName("guild_search").gameObject
	self.guild_recommend_item = go:NodeByName("guild_recommend_item").gameObject
	self.main = go:NodeByName("e:Group").gameObject
	self.nav = self.main:NodeByName("nav").gameObject
	self.labelWinTitle = go:ComponentByName("e:Group/e:Group/labelWinTitle", typeof(UILabel))
	self.closeBtn = self.main:NodeByName("closeBtn").gameObject

	self.guild_search:SetActive(false)
	self.guild_recommend:SetActive(false)
	self.guild_create:SetActive(false)
	self.guild_recommend_item:SetActive(false)
end

function GuildJoinWindow:initUIComponent()
	self.tab = CommonTabBar.new(self.nav, 3, function (index)
		xyd.SoundManager:get():playSound(xyd.SoundID.TAB)
		self:setComponent(index)
	end)

	self.tab:setTexts({
		__("GUILD_TEXT13"),
		__("GUILD_TEXT14"),
		__("GUILD_TEXT15")
	})
end

function GuildJoinWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GUILD_GET_INFO, self.onGuildInfo, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_REFRESH, self.onGuildsRefresh, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_SEARCH, self.onGuildSearch, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_CREATE, self.onGuildCreate, self)
	self.eventProxy_:addEventListener(xyd.event.GET_INFO_BY_GUILD_ID, function (self, event)
		xyd.WindowManager.get():openWindow("guild_apply_detail_window", {
			data = event.data.guild_info
		})
	end, self)
	self:setCloseBtn(self.closeBtn)
end

function GuildJoinWindow:onGuildInfo()
	for i = 1, 3 do
		if self.components[i] then
			self.components[i]:setLayout()
		end
	end
end

function GuildJoinWindow:setComponent(id)
	if not self.components[id] then
		if id == 1 then
			self.components[id] = GuildRecommend.new(self.guild_recommend, self.guild_recommend_item)
		elseif id == 2 then
			self.components[id] = GuildCreate.new(self.guild_create)
		elseif id == 3 then
			self.components[id] = GuildSearch.new(self.guild_search, self.guild_recommend_item)
		end
	end

	for i = 1, 3 do
		if self.components[i] then
			self.components[i]:SetActive(i == id)
		end
	end

	if id == 3 then
		local item = self.components[id]

		item:reset()
	end
end

function GuildJoinWindow:onGuildsRefresh()
	local recommend = self.components[1]

	recommend:resetLayout()
end

function GuildJoinWindow:onGuildSearch(event)
	local list = event.data.guilds

	if not list or #list == 0 then
		local tmpName = xyd.models.guild:getTmpName()

		if tmpName and tonumber(tmpName) and #tostring(tmpName) == 6 then
			xyd.alertTips(__("GUILD_TEXT71"))
		else
			xyd.alertTips(__("GUILD_TEXT72"))
		end

		return
	end

	local search = self.components[3]

	search:setLayout(list)
end

function GuildJoinWindow:onGuildCreate(event)
	xyd.alertTips(__("GUILD_TEXT17"))
	xyd.WindowManager.get():closeWindow(self.name_)

	local win = xyd.WindowManager:get():getWindow("chat_window")

	if win then
		xyd.WindowManager:get():closeWindow("chat_window")
	end

	xyd.WindowManager:get():openWindow("guild_territory_window")

	local luck = xyd.models.guild:getLuckStatus()

	if luck == 1 then
		xyd.models.guild:setLuckStatus(2)
	end
end

function GuildSearch:ctor(go, guild_recommend_item)
	GuildSearch.super.ctor(self, go)

	self.guild_recommend_item = guild_recommend_item

	self:getUIComponent()
	self:initUIComponent()
	self:onRegisterEvent()
end

function GuildSearch:getUIComponent()
	local go = self.go
	self.textInput = go:ComponentByName("textInput", typeof(UILabel))
	self.btnSearch = go:NodeByName("btnSearch").gameObject
	self.btnSearch_label = self.btnSearch:ComponentByName("button_label", typeof(UILabel))
	self.groupItems = go:NodeByName("groupItems").gameObject
end

function GuildSearch:initUIComponent()
	xyd.setBgColorType(self.btnSearch, xyd.ButtonBgColorType.blue_btn_60_60)

	self.btnSearch_label.text = __("GUILD_TEXT18")
	self.textInput.gameObject:GetComponent(typeof(UIInput)).defaultColor = Color.New2(3385711103.0)
	self.textInput.gameObject:GetComponent(typeof(UIInput)).defaultText = __("GUILD_TEXT19")
end

function GuildSearch:onRegisterEvent()
	xyd.setDarkenBtnBehavior(self.btnSearch, self, self.searchItems)
end

function GuildSearch:setLayout(guildsList)
	if not guildsList then
		return
	end

	NGUITools.DestroyChildren(self.groupItems.transform)

	for i = 1, #guildsList do
		local go = NGUITools.AddChild(self.groupItems, self.guild_recommend_item)
		local item = GuildRecommendItem.new(go, guildsList[i])

		item:addParentDepth()
	end

	self.groupItems:GetComponent(typeof(UILayout)):Reposition()
end

function GuildSearch:searchItems()
	if not self.textInput.text or self.textInput.text == "" or self.textInput.text == __("GUILD_TEXT19") then
		xyd.alertTips(__("GUILD_TEXT73"))

		return
	end

	xyd.models.guild:reqGuildSearch(self.textInput.text)
end

function GuildSearch:reset()
	self.textInput:GetComponent(typeof(UIInput)).value = ""
end

function GuildCreate:ctor(go)
	GuildCreate.super.ctor(self, go)

	self.language = xyd.tables.playerLanguageTable:getIDByName(xyd.Global.lang)
	self.choosePolicy_ = 1
	self.openType_ = 1
	self.limitPowerNum_ = 0
	self.flag = 1
	self.lineNum = 1

	self:getUIComponent()
	self:initUIComponent()
end

function GuildCreate:getUIComponent()
	local go = self.go
	self.imgIcon = go:NodeByName("imgIcon").gameObject
	self.textInput = go:ComponentByName("textInput", typeof(UILabel))
	self.imgLang = go:NodeByName("imgLang").gameObject
	self.btnIcon = go:NodeByName("btnIcon").gameObject
	self.btnLang = go:NodeByName("btnLang").gameObject
	self.btnPolicy = go:NodeByName("btnPolicy").gameObject
	self.btnIcon_label = self.btnIcon:ComponentByName("button_label", typeof(UILabel))
	self.btnLang_label = self.btnLang:ComponentByName("button_label", typeof(UILabel))
	self.btnPolicy_label = self.btnPolicy:ComponentByName("button_label", typeof(UILabel))
	self.editScroll = go:ComponentByName("editLabelPanel", typeof(UIScrollView))
	self.editLabelInput = go:ComponentByName("editLabelPanel/editableText", typeof(UIInput))
	self.editableText = go:ComponentByName("editLabelPanel/editableText", typeof(UILabel))
	local SummonButton = require("app.components.SummonButton")
	self.btnCreate = SummonButton.new(go:NodeByName("btnCreate").gameObject)
	self.openTypeLabel_ = go:ComponentByName("e:Image2/labelText", typeof(UILabel))
	self.btnLeft_ = go:NodeByName("btnLeft").gameObject
	self.btnRight_ = go:NodeByName("btnRight").gameObject
	self.selectNumPos_ = go:NodeByName("selectNumRoot").gameObject
	self.selectNum_ = import("app.components.SelectNum").new(self.selectNumPos_, "default")
	self.labelType_ = go:ComponentByName("labelType", typeof(UILabel))
	self.labelPower_ = go:ComponentByName("labelPower", typeof(UILabel))
end

function GuildCreate:updateOpenType()
	local textList = {
		__("GUILD_OPEN_TYPE1"),
		__("GUILD_OPEN_TYPE2"),
		__("GUILD_OPEN_TYPE3")
	}
	self.openTypeLabel_.text = textList[self.openType_]
end

function GuildCreate:onChange()
	local pos = self.editLabelInput.caretVerts
	local pos_y = math.abs(tonumber(pos.y))
	local lineNum = math.floor(pos_y / self.editableText.fontSize)

	if lineNum ~= self.lineNum and lineNum > 2 then
		pos = Vector3(0, -25 + (lineNum - 1) * self.editableText.fontSize, 0)

		self:waitForFrame(2, function ()
			SpringPanel.Begin(self.editScroll.gameObject, pos, 8)
		end)
	end

	self.lineNum = lineNum
end

function GuildCreate:initUIComponent()
	xyd.setDarkenBtnBehavior(self.btnCreate:getGameObject(), self, self.createReq)
	xyd.setDarkenBtnBehavior(self.btnIcon, self, self.chooseIcon)
	xyd.setDarkenBtnBehavior(self.imgIcon, self, self.chooseIcon)
	xyd.setDarkenBtnBehavior(self.btnLang, self, self.chooseLang)
	xyd.setDarkenBtnBehavior(self.btnPolicy, self, self.choosePolicy)
	xyd.setDarkenBtnBehavior(self.imgLang, self, self.chooseLang)
	xyd.setDarkenBtnBehavior(self.btnRight_, self, self.onClickRight)
	xyd.setDarkenBtnBehavior(self.btnLeft_, self, self.onClickLeft)
	xyd.setUISprite(self.imgIcon:GetComponent(typeof(UISprite)), nil, xyd.tables.guildIconTable:getIcon(1))
	XYDUtils.AddEventDelegate(self.editLabelInput.onChange, handler(self, self.onChange))

	local luck = xyd.models.guild:getLuckStatus()

	if luck == 1 then
		self.btnCreate:setCostIcon()
		self.btnCreate:setLabel(__("GUILD_FREE_CREATE"))
	else
		local cost = xyd.tables.miscTable:split2Cost("create_guild_cost", "value", "#")

		self.btnCreate:setCostIcon(cost)
		self.btnCreate:setLabel(__("GUILD_TEXT20"))
	end

	self.btnIcon_label.text = __("GUILD_CHOOSE_FLAG")
	self.btnLang_label.text = __("GUILD_CHOOSE_LANG")
	self.btnPolicy_label.text = __("GUILD_POLICY_BTN_LABEL")
	self.textInput.gameObject:GetComponent(typeof(UIInput)).defaultText = __("GUILD_TEXT22")
	self.textInput.gameObject:GetComponent(typeof(UIInput)).defaultColor = Color.New2(3385711103.0)
	self.editableText.gameObject:GetComponent(typeof(UIInput)).defaultText = __("GUILD_TEXT23")
	self.editableText.gameObject:GetComponent(typeof(UIInput)).defaultColor = Color.New2(3385711103.0)

	if xyd.Global.lang == "de_de" then
		self.btnCreate.itemIcon:X(-70)
		self.btnCreate.label:X(15)
	end

	if xyd.models.guild:isLoaded() then
		self:setLayout()
	end

	local function callbackFunction(num)
		self.limitPowerNum_ = num
	end

	local maxNum = tonumber(xyd.tables.miscTable:getVal("max_guild_limit"))
	local minNum = tonumber(xyd.tables.miscTable:getVal("min_guild_limit"))
	local feetNum = tonumber(xyd.tables.miscTable:getVal("change_guild_limit"))

	self.selectNum_:setInfo({
		curNum = 0,
		delForceZero = true,
		maxNum = maxNum,
		minNum = minNum,
		callback = callbackFunction,
		feetNum = feetNum
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

function GuildCreate:onClickRight()
	self.openType_ = self.openType_ + 1

	if self.openType_ > 3 then
		self.openType_ = 1
	end

	self:updateOpenType()
end

function GuildCreate:onClickLeft()
	self.openType_ = self.openType_ - 1

	if self.openType_ <= 0 then
		self.openType_ = 3
	end

	self:updateOpenType()
end

function GuildCreate:createReq()
	local cost = xyd.tables.miscTable:split2Cost("create_guild_cost", "value", "#")

	if xyd.models.guild:getLuckStatus() ~= 1 and xyd.isItemAbsence(cost[1], cost[2]) then
		return
	end

	local name = self.textInput.text
	local notice = self.editableText.text or ""

	if notice == __("GUILD_TEXT23") then
		notice = ""
	end

	if GuildNameChangeWindow:isNameValid(name) then
		xyd.models.guild:guildCreate(name, self.flag, notice, tonumber(self.language), self.openType_, self.limitPowerNum_, self.choosePolicy_)
	end
end

function GuildCreate:choosePolicy()
	xyd.WindowManager.get():openWindow("guild_policy_select_window", {
		policy = self.choosePolicy_,
		callback = function (policy)
			self.choosePolicy_ = policy
		end
	})
end

function GuildCreate:chooseIcon()
	xyd.WindowManager:get():openWindow("guild_flag_window", {
		callback = function (guild_flag_window, flag)
			self.flag = flag

			xyd.setUISprite(self.imgIcon:GetComponent(typeof(UISprite)), nil, xyd.tables.guildIconTable:getIcon(flag))
		end
	})
end

function GuildCreate:chooseLang()
	xyd.WindowManager.get():openWindow("guild_change_language_window", {
		callback = function (language)
			self.language = language
		end,
		language = self.language
	})
end

function GuildCreate:setLayout()
	if self.isLayout then
		return
	end

	self.isLayout = true
end

function GuildRecommend:ctor(go, guild_recommend_item)
	GuildRecommend.super.ctor(self, go)

	self.guild_recommend_item = guild_recommend_item

	self:getUIComponent()
	self:initUIComponent()
end

function GuildRecommend:getUIComponent()
	local go = self.go
	self.labelText01 = go:ComponentByName("labelText01", typeof(UILabel))
	self.btnRefresh = go:NodeByName("btnRefresh").gameObject
	self.btnRefresh_label = self.btnRefresh:ComponentByName("button_label", typeof(UILabel))
	self.groupItems = go:NodeByName("groupItems").gameObject
	self.groupNone = go:NodeByName("groupNone").gameObject
	self.groupNameLabel_ = go:ComponentByName("groupNone/labelNoneTips", typeof(UILabel))
end

function GuildRecommend:initUIComponent()
	self.labelText01.text = __("GUILD_TEXT13")
	self.btnRefresh_label.text = __("GUILD_TEXT70")

	xyd.setDarkenBtnBehavior(self.btnRefresh, self, self.reqGuilds)

	if xyd.models.guild:isLoaded() then
		self:setLayout()
	end
end

function GuildRecommend:setLayout()
	if self.isLayout then
		return
	end

	self.isLayout = true
	local guildsList = xyd.models.guild.guildsList

	for i = 1, #guildsList do
		local go = NGUITools.AddChild(self.groupItems, self.guild_recommend_item)
		local item = GuildRecommendItem.new(go, guildsList[i])

		item:addParentDepth()
	end

	self.groupItems:GetComponent(typeof(UILayout)):Reposition()

	if #guildsList <= 0 then
		self.groupNone:SetActive(true)

		self.groupNameLabel_.text = __("GUILD_TEXT69")
	else
		self.groupNone:SetActive(false)
	end
end

function GuildRecommend:reqGuilds()
	xyd.models.guild:reqGuildFresh()
end

function GuildRecommend:resetLayout()
	self.isLayout = false

	NGUITools.DestroyChildren(self.groupItems.transform)
	self:setLayout()
end

function GuildRecommendItem:ctor(go, data)
	GuildRecommendItem.super.ctor(self, go)

	self.data = data

	self:getUIComponent()
	self:initUIComponent()
	self:onRegisterEvent()
end

function GuildRecommendItem:getUIComponent()
	local go = self.go
	self.imgIcon01 = go:ComponentByName("imgIcon01", typeof(UISprite))
	self.imgIcon02 = go:ComponentByName("imgIcon02", typeof(UISprite))
	self.labelText0 = go:ComponentByName("labelText0", typeof(UILabel))
	self.labelText1 = go:ComponentByName("labelText1", typeof(UILabel))
	self.labelText2 = go:ComponentByName("labelText2", typeof(UILabel))
	self.labelText3 = go:ComponentByName("labelText3", typeof(UILabel))
	self.labelText4 = go:ComponentByName("labelText4", typeof(UILabel))
	self.btnApply = go:ComponentByName("btnApply", typeof(UISprite))
	self.btnApply_label = self.btnApply:ComponentByName("button_label", typeof(UILabel))
end

function GuildRecommendItem:initUIComponent()
	xyd.setBgColorType(self.btnApply.gameObject, xyd.ButtonBgColorType.blue_btn_60_60)

	local lev = xyd.tables.guildExpTable:getLev(self.data.exp)
	self.labelText0.text = self.data.num .. "/" .. xyd.tables.guildExpTable:getMember(lev)
	self.labelText1.text = self.data.name
	self.labelText2.text = __("GUILD_TEXT25")
	self.labelText3.text = tostring(lev)
	self.labelText4.text = __("GUILD_POLICY_TEXT" .. (self.data.plan or 1))

	xyd.setUISprite(self.imgIcon01, nil, xyd.tables.guildIconTable:getIcon(self.data.flag))

	self.btnApply_label.text = __("HERO_CHALLENGE_TEAM_TITLE")
end

function GuildRecommendItem:onRegisterEvent()
	xyd.setDarkenBtnBehavior(self.btnApply.gameObject, self, self.reqApply)
	self:registerEvent(xyd.event.GUILD_SINGLE_REFRESH, handler(self, self.refreshBtn))
end

function GuildRecommendItem:refreshBtn(event)
	if event.data and event.data.guild_id ~= self.data.guild_id then
		return
	end

	xyd.setEnabled(self.btnApply.gameObject, false)
	xyd.applyGrey(self.btnApply)

	self.btnApply_label.text = __("GUILD_TEXT27")
end

function GuildRecommendItem:reqApply()
	local msg = messages_pb:get_info_by_guild_id_req()
	msg.guild_id = self.data.guild_id

	xyd.Backend:get():request(xyd.mid.GET_INFO_BY_GUILD_ID, msg)
end

return GuildJoinWindow
