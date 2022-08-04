local BaseWindow = import(".BaseWindow")
local GuildTerritoryWindow = class("GuildTerritoryWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")

function GuildTerritoryWindow:ctor(name, params)
	GuildTerritoryWindow.super.ctor(self, name, params)

	self.effectName = {
		"fx_ui_bird",
		"fx_ui_syun",
		"fx_ui_zglow",
		"fx_ui_shizhong",
		"fx_ui_stmaopao",
		"fx_ui_stpenquan",
		"fx_ui_streqi",
		"fx_ui_stpenquan_top"
	}
	self.effectList = {}
end

function GuildTerritoryWindow:initWindow()
	GuildTerritoryWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:loadEffect()
	self:registerEvent()

	self.effectChris1_ = xyd.WindowManager.get():setChristmasEffect(self.christmasEffectGroup_, true)

	self:waitForFrame(5, handler(self, self.checkGuide), nil)
	self:checkOpenSpecialPlace()
end

function GuildTerritoryWindow:checkOpenSpecialPlace()
	if self.params_.specialPlaceType then
		self:onTouchButton(self.params_.specialPlaceType)
	end
end

function GuildTerritoryWindow:checkGuide()
	if xyd.models.guild.self_info.guide_flag == 0 then
		self.isInGuide_ = true

		xyd.WindowManager.get():openWindow("guild_guide_window", {
			closeCallBack = function ()
				self.isInGuide_ = false

				self.dragonbone:play("idle", 0, 1)
				xyd.models.guild:setGuideFlag()
			end
		})
	else
		return
	end
end

function GuildTerritoryWindow:getUIComponent()
	local go = self.window_
	self.imgBg = go:ComponentByName("imgBg", typeof(UITexture))
	self.smallBg = go:ComponentByName("smallBg", typeof(UISprite))

	for i = 1, 6 do
		self["img0" .. i] = go:ComponentByName("groupMain_/img0" .. i, typeof(UISprite))
	end

	for i = 2, 7 do
		self["labelName" .. i] = go:ComponentByName("groupMain_/labelName" .. i, typeof(UILabel))
	end

	for i = 2, 5 do
		self["redPoint" .. i] = go:ComponentByName("groupMain_/redPoint" .. i, typeof(UISprite))
	end

	for i = 0, 7 do
		self["effectGroup" .. i] = go:NodeByName("groupMain_/effectGroup" .. i).gameObject
	end

	self.imgBg01_ = go:ComponentByName("groupMain_/imgBg01_", typeof(UISprite))
	self.imgCheckin = go:ComponentByName("groupMain_/imgCheckin", typeof(UISprite))
	self.groupShop = go:NodeByName("groupMain_/groupShop").gameObject
	self.groupShopTouch = go:NodeByName("groupMain_/groupShopTouch").gameObject
	self.christmasEffectGroup_ = go:NodeByName("groupMain_/christmasEffectGroup").gameObject
	self.guildCompetitionBtn = go:NodeByName("groupMain_/guildCompetitionBtn").gameObject
	self.guildCompetitionTimeText = self.guildCompetitionBtn:ComponentByName("guildCompetitionTimeText", typeof(UILabel))
	self.guildCompetitionTimeNumText = self.guildCompetitionBtn:ComponentByName("guildCompetitionTimeNumText", typeof(UILabel))
	self.guildCompetitionRedPoint = self.guildCompetitionBtn:NodeByName("guildCompetitionRedPoint").gameObject
	self.guildCompetitionGuide = go:ComponentByName("groupMain_/guildCompetitionGuide", typeof(UITexture))
	self.btnChat = go:NodeByName("groupMain_/chatGroup/btnChat").gameObject
	self.chatRed = self.btnChat:NodeByName("redIcon").gameObject
	self.shopModel = go:NodeByName("groupMain_/shopModel").gameObject
end

function GuildTerritoryWindow:initUIComponent()
	self:initTopGroup()
	self:setText()
	self:setModel()
	xyd.setUITextureAsync(self.imgBg, "Textures/scenes_web/guild_territory_bg01", function ()
		self.smallBg:SetActive(false)
	end, false)

	if xyd.models.guild.isCheckIn == 1 then
		self.imgCheckin:SetActive(false)
	end

	if xyd.isH5() then
		local sp = self.btnChat:GetComponent(typeof(UISprite))

		xyd.setUISprite(sp, nil, "chat_icon_v3_h5")
		sp:MakePixelPerfect()
	end

	self:updateGuildCompetitionTime()
end

function GuildTerritoryWindow:registerEvent()
	for i = 1, 6 do
		UIEventListener.Get(self["img0" .. i].gameObject).onClick = function ()
			self:onTouchButton(i)
		end
	end

	UIEventListener.Get(self.imgCheckin.gameObject).onClick = function ()
		self:onTouchCheckIn()
	end

	UIEventListener.Get(self.groupShopTouch).onClick = function ()
		self:onTouchButton(7)
	end

	UIEventListener.Get(self.btnChat).onClick = function ()
		local wnd = xyd.WindowManager.get():openWindow("chat_window")

		wnd:onTopTouch(7)
	end

	UIEventListener.Get(self.shopModel:NodeByName("touchField").gameObject).onClick = function ()
		xyd.openWindow("guild_shop_window")
	end

	self.eventProxy_:addEventListener(xyd.event.CLOSE_ALL_GUILD_WINDOW, function ()
		self:close()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.WINDOW_WILL_CLOSE, self.onWindowClose, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_CHECKIN, self.onCheckIn, self)

	UIEventListener.Get(self.guildCompetitionBtn.gameObject).onClick = function ()
		if xyd.models.guild:getGuildCompetitionInfo() then
			local timeData = xyd.models.guild:getGuildCompetitionLeftTime()

			if timeData.type == 1 then
				xyd.WindowManager.get():openWindow("guild_competition_main_window")
			elseif timeData.type == -1 then
				xyd.showToast(__("ACTIVITY_END_YET"))
			else
				xyd.WindowManager.get():openWindow("guild_competition_main_window")
			end
		else
			xyd.showToast(__("ACTIVITY_END_YET"))
		end

		if self.guildCompetitionGuide.gameObject.activeSelf then
			xyd.db.misc:setValue({
				value = 1,
				key = "is_local_guild_competition_has_guide"
			})
			self.guildCompetitionGuide:SetActive(false)
		end
	end

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.GUILD_MEMBER,
		xyd.RedMarkType.GUILD_CHECKIN,
		xyd.RedMarkType.GUILD_LOG
	}, self.redPoint2)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.GUILD_ORDER, self.redPoint3)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.GUILD_BOSS, self.redPoint4)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.GUILD_WAR, self.redPoint5)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.GUILD_CHAT, self.chatRed)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.GUILD_COMPETITION,
		xyd.RedMarkType.GUILD_COMPETITION_TASK_RED
	}, self.guildCompetitionRedPoint)
end

function GuildTerritoryWindow:onTouchButton(type)
	if not xyd.models.guild.guildID or not xyd.models.guild.base_info then
		xyd.alertTips(__("GUILD_TEXT66"))

		return
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if type == 1 then
		-- Nothing
	elseif type == 2 then
		xyd.WindowManager.get():openWindow("guild_window")
	elseif type == 3 then
		local lev = xyd.tables.miscTable:getNumber("guild_order_open", "value")

		if xyd.models.guild.level < lev then
			xyd.alertTips(__("GUILD_TEXT48", lev))

			return
		end

		xyd.WindowManager.get():openWindow("guild_dininghall")
	elseif type == 4 then
		xyd.WindowManager.get():openWindow("guild_gym_window")
	elseif type == 5 then
		if xyd.models.guild.base_info.is_open == 0 then
			local info = xyd.models.guild.base_info

			xyd.alertTips(__("GUILD_TEXT49"))

			return
		end

		local lev = xyd.tables.miscTable:getNumber("guild_war_open", "value")

		if xyd.models.guild.level < lev then
			xyd.alertTips(__("GUILD_TEXT48", lev))

			return
		end

		local tmpStr = xyd.tables.miscTable:getVal("guild_war_time_interval")
		local nowTime = xyd.getServerTime()
		local timeIntervals = xyd.split(tmpStr, "|", true)

		if nowTime - (xyd.getGMTWeekStartTime(nowTime) + timeIntervals[#timeIntervals] - 1800) > 0 then
			xyd.alertTips(__("GUILD_WAR_NEXT_WEEK"))

			return
		end

		xyd.WindowManager.get():openWindow("guild_war_info_window")
	elseif type == 6 then
		xyd.WindowManager.get():openWindow("guild_lab_window")
	elseif type == 7 then
		xyd.WindowManager.get():openWindow("shop_window", {
			shopType = xyd.ShopType.SHOP_GUILD
		})
		xyd.WindowManager.get():closeWindow(self)
	end
end

function GuildTerritoryWindow:onTouchCheckIn()
	xyd.models.guild:checkIn()
end

function GuildTerritoryWindow:onCheckIn()
	if xyd.models.guild.isCheckIn == 1 then
		self.imgCheckin:SetActive(false)
	end

	self:setShopModel()

	if xyd.WindowManager.get():getWindow("guild_window") then
		return
	end

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

	xyd.itemFloat(items, nil, , 6000)
end

function GuildTerritoryWindow:onWindowClose(event)
	local data = event.params

	if data.windowName ~= "chat_window" then
		return
	end

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.GUILD_CHAT, self.chatRed)
end

function GuildTerritoryWindow:setText()
	self.labelName2.text = __("GUILD_TEXT50")
	self.labelName3.text = __("GUILD_TEXT51")
	self.labelName4.text = __("GUILD_TEXT52")
	self.labelName5.text = __("GUILD_TEXT53")
	self.labelName6.text = __("GUILD_TEXT54")
	self.labelName7.text = __("GUILD_TEXT55")
end

function GuildTerritoryWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 5)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function GuildTerritoryWindow:setModel()
	local modelID = GuildTerritoryWindow.MODEL_ID
	local name = xyd.tables.modelTable:getModelName(modelID)
	local node = xyd.Spine.new(self.groupShop)

	node:setInfo(name, function ()
		node:SetLocalScale(0.5, 0.5, 1)

		if self.isInGuide_ then
			node:stop()
		else
			node:play("idle", 0, 1)
		end
	end, false)

	self.dragonbone = node

	self:setShopModel()
end

function GuildTerritoryWindow:setShopModel()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_SHOP)

	if activityData and xyd.tables.miscTable:getNumber("guild_shop_open_limit", "value") <= xyd.models.guild.saleLev and activityData:isOpen() and xyd.models.guild.saleLev ~= 0 then
		if not self.shopEffect then
			self.shopEffect = xyd.Spine.new(self.shopModel)

			self.shopEffect:setInfo("banila_pifu04", function ()
				self.shopEffect:SetLocalScale(0.5, 0.5, 1)

				if self.isInGuide_ then
					self.shopEffect:stop()
				else
					self.shopEffect:play("idle", 0, 1)
				end
			end, false)
		end

		self.shopModel:SetActive(true)

		if activityData:getUpdateTime() - xyd.getServerTime() > 0 then
			local countdown = import("app.components.CountDown").new(self.shopModel:ComponentByName("label1", typeof(UILabel)), {
				duration = activityData:getUpdateTime() - xyd.getServerTime()
			})
		end

		self.shopModel:ComponentByName("label2", typeof(UILabel)).text = __("GUILD_ROAM_TEXT12")
	else
		self.shopModel:SetActive(false)
	end
end

function GuildTerritoryWindow:loadEffect()
	for i = 1, #self.effectName do
		local effect = xyd.Spine.new(self["effectGroup" .. i - 1])
		local texiaoname = "texiao01"

		if i == 4 then
			texiaoname = "texiao1"
		end

		effect:setInfo(self.effectName[i], function ()
			effect:play(texiaoname, 0, 1)
		end, false)
	end
end

function GuildTerritoryWindow:willClose()
	if self.effectChris1_ then
		self.effectChris1_:destroy()
	end

	if self.guildCompetitionTimeCount then
		self.guildCompetitionTimeCount:stopTimeCount()
	end

	GuildTerritoryWindow.super.willClose(self)
end

function GuildTerritoryWindow:updateGuildCompetitionTime()
	if xyd.models.guild:getGuildCompetitionInfo() then
		self.guildCompetitionBtn:SetActive(true)
		self.guildCompetitionGuide:SetActive(false)

		local timeData = xyd.models.guild:getGuildCompetitionLeftTime()

		if timeData.type == 1 then
			self.guildCompetitionTimeText.text = __("GUILD_COMPETITION_READY_TIME")
			self.guildCompetitionTimeText.color = Color.New2(3526711295.0)
			local CountDown = import("app.components.CountDown")

			self.guildCompetitionTimeNumText:SetActive(true)

			if self.guildCompetitionTimeCount then
				self.guildCompetitionTimeCount:stopTimeCount()
			end

			self.guildCompetitionTimeCount = CountDown.new(self.guildCompetitionTimeNumText, {
				duration = timeData.curEndTime - xyd.getServerTime(),
				callback = handler(self, self.updateGuildCompetitionTime)
			})
		elseif timeData.type == 2 then
			self.guildCompetitionTimeText.text = __("GUILD_COMPETITION_ENTRANCE")
			local CountDown = import("app.components.CountDown")

			self.guildCompetitionTimeNumText:SetActive(true)

			if self.guildCompetitionTimeCount then
				self.guildCompetitionTimeCount:stopTimeCount()
			end

			self.guildCompetitionTimeCount = CountDown.new(self.guildCompetitionTimeNumText, {
				duration = timeData.curEndTime - xyd.getServerTime(),
				callback = handler(self, self.updateGuildCompetitionTime)
			})
			local isLocalGuildCompetitionHasGuide = xyd.db.misc:getValue("is_local_guild_competition_has_guide")

			if not isLocalGuildCompetitionHasGuide then
				self.guildCompetitionGuide:SetActive(true)

				if not self.competition_guide_effect then
					self.competition_guide_effect = xyd.Spine.new(self.guildCompetitionGuide.gameObject)

					self.competition_guide_effect:setInfo("fx_ui_dianji", function ()
						self.competition_guide_effect:play("texiao01", 0, 1, function ()
						end)
					end)
				end
			end
		else
			self.guildCompetitionTimeText.text = __("GUILD_COMPETITION_END_TIME")
			self.guildCompetitionTimeText.color = Color.New2(1566469887)

			self.guildCompetitionTimeNumText:SetActive(false)
		end
	else
		self.guildCompetitionBtn:SetActive(false)
		self.guildCompetitionGuide:SetActive(false)
	end
end

GuildTerritoryWindow.MODEL_ID = 4400101

return GuildTerritoryWindow
