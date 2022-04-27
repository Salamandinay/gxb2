local BaseWindow = import(".BaseWindow")
local GuildGymWindow = class("GuildGymWindow", BaseWindow)
local GuildGymItem = class("GuildGymItem")
local GuildBossCard = class("GuildBossCard", require("app.components.CopyComponent"))
GuildGymWindow.GuildBossCard = GuildBossCard

function GuildGymWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.currPageNum = math.min(math.ceil(xyd.tables.miscTable:getNumber("guild_boss_max_id", "value") / 9), math.ceil(xyd.models.guild.bossID / 9)) or 1
	self.pageIcons = {}
end

function GuildGymWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function GuildGymWindow:getUIComponent()
	local go = self.window_:NodeByName("groupAction").gameObject
	self.labelWinTitle = go:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.bossContainer = go:NodeByName("bossContainer").gameObject
	self.rightArrow = go:NodeByName("rightArrow").gameObject
	self.leftArrow = go:NodeByName("leftArrow").gameObject
	self.pageIconGroup = go:NodeByName("pageIconGroup").gameObject
	self.gym_item = self.window_:NodeByName("gym_item").gameObject
	self.guild_boss_card = self.window_:NodeByName("guild_boss_card").gameObject

	self.gym_item:SetActive(false)
	self.guild_boss_card:SetActive(false)
end

function GuildGymWindow:initUIComponent()
	self:initBossList()
	self:initPageIcon()
	self:updateArrow()
end

function GuildGymWindow:register()
	BaseWindow.register(self)
	xyd.setDarkenBtnBehavior(self.leftArrow, self, self.lastPage)
	xyd.setDarkenBtnBehavior(self.rightArrow, self, self.nextPage)
end

function GuildGymWindow:initBossList()
	local bossNum = xyd.tables.guildBossTable:getMaxID()
	self.maxPageNum = math.ceil(bossNum / 9)

	if not self.currGymItem then
		local go = NGUITools.AddChild(self.bossContainer, self.gym_item)
		self.currGymItem = GuildGymItem.new(go, self.guild_boss_card, self.currPageNum)

		self.currGymItem:addParentDepth()
	end

	self.currGymItem:useFightEffect()
end

function GuildGymWindow:initPageIcon()
	for i = 1, self.maxPageNum do
		local go = NGUITools.AddChild(self.pageIconGroup, "page" .. i)
		local pageIcon = go:AddComponent(typeof(UISprite))

		xyd.setUISprite(pageIcon, nil, i == self.currPageNum and "page_icon_1" or "page_icon_0")

		pageIcon.width = 22
		pageIcon.height = 22
		pageIcon.depth = self.pageIconGroup:GetComponent(typeof(UIWidget)).depth + 1

		table.insert(self.pageIcons, pageIcon)
	end
end

function GuildGymWindow:setPageIcon()
	for i = 1, #self.pageIcons do
		local pageIcon = self.pageIcons[i]

		xyd.setUISprite(pageIcon, nil, i == self.currPageNum and "page_icon_1" or "page_icon_0")
	end
end

function GuildGymWindow:nextPage()
	if self.maxPageNum < self.currPageNum + 1 then
		return
	end

	self.currPageNum = self.currPageNum + 1

	if self.currGymItem then
		self.currGymItem:changePageNum(self.currPageNum)
		self.currGymItem:useFightEffect()
	end

	self:setPageIcon()
	self:updateArrow()
end

function GuildGymWindow:lastPage()
	if self.currPageNum - 1 <= 0 then
		return
	end

	self.currPageNum = self.currPageNum - 1

	if self.currGymItem then
		self.currGymItem:changePageNum(self.currPageNum)
		self.currGymItem:useFightEffect()
	end

	self:setPageIcon()
	self:updateArrow()
end

function GuildGymWindow:updateArrow()
	if self.maxPageNum < self.currPageNum + 1 then
		self.rightArrow:GetComponent(typeof(UIWidget)).alpha = 0.5

		xyd.setTouchEnable(self.rightArrow, false)
	else
		self.rightArrow:GetComponent(typeof(UIWidget)).alpha = 1

		xyd.setTouchEnable(self.rightArrow, true)
	end

	if self.currPageNum - 1 <= 0 then
		self.leftArrow:GetComponent(typeof(UIWidget)).alpha = 0.5

		xyd.setTouchEnable(self.leftArrow, false)
	else
		self.leftArrow:GetComponent(typeof(UIWidget)).alpha = 1

		xyd.setTouchEnable(self.leftArrow, true)
	end
end

function GuildGymItem:ctor(go, guild_boss_card, pageNum)
	self.maxCardNum = 9
	self.pageNum_ = pageNum or 1
	self.fightCardId_ = 0
	self.lastFightCardId_ = 0
	self.go = go
	self.uiLayout = self.go:GetComponent(typeof(UILayout))
	self.guild_boss_card = guild_boss_card
	self.cards = {}

	self:initUIComponent()
end

function GuildGymItem:addParentDepth()
	if not self.go.transform.parent then
		return
	end

	local widget = self.go.transform.parent:GetComponent(typeof(UIWidget))

	if not widget then
		return
	end

	self:setDepth(widget.depth)
end

function GuildGymItem:setDepth(depth)
	if not depth or depth == 0 then
		return
	end

	local function setChildrenDepth(go, depth)
		for i = 1, go.transform.childCount do
			local child = go.transform:GetChild(i - 1).gameObject
			local widget = child:GetComponent(typeof(UIWidget))

			if widget then
				widget.depth = depth + widget.depth
			end

			if child.transform.childCount > 0 then
				setChildrenDepth(child, depth)
			end
		end
	end

	local widget = self.go:GetComponent(typeof(UIWidget))

	if widget then
		widget.depth = widget.depth + depth
	end

	setChildrenDepth(self.go, depth)
end

function GuildGymItem:initUIComponent()
	NGUITools.DestroyChildren(self.go.transform)

	self.cards = {}

	for i = 1, self.maxCardNum do
		local params = {
			pageNum = self.pageNum_,
			id = i
		}
		local go = NGUITools.AddChild(self.go, self.guild_boss_card)
		local card = GuildBossCard.new(go, params)

		card:addParentDepth()

		if (self.pageNum_ - 1) * 9 + i == xyd.models.guild.bossID then
			self.fightCardId_ = i
		end

		self.cards[i] = card
	end

	self.uiLayout:Reposition()
end

function GuildGymItem:changePageNum(pageNum)
	if self.pageNum_ == pageNum then
		return
	end

	self.pageNum_ = pageNum
	self.lastFightCardId_ = self.fightCardId_
	self.fightCardId_ = 0

	for i = 1, self.maxCardNum do
		local card = self.cards[i]

		card:updatePageNum(self.pageNum_)

		if (self.pageNum_ - 1) * 9 + i == xyd.models.guild.bossID then
			self.fightCardId_ = i
		end
	end

	self.uiLayout:Reposition()
end

function GuildGymItem:useFightEffect()
	if self.lastFightCardId_ ~= self.fightCardId_ then
		if self.fightCardId_ > 0 then
			local card = self.cards[self.fightCardId_]

			card:addFightEffect()
		else
			local card = self.cards[self.lastFightCardId_]

			card:removeFightEffect()
		end
	end
end

function GuildBossCard:ctor(go, params)
	GuildBossCard.super.ctor(self, go)

	self.isDetail = false
	self.data = params
	self.pageNum_ = params.pageNum or 1
	self.id_ = params.id or 0
	self.maxID_ = xyd.tables.guildBossTable:getMaxID()
	self.bossId_ = 0

	if self.pageNum_ > 0 then
		self.bossId_ = (self.pageNum_ - 1) * 9 + self.id_
	end

	self:getUIComponent()

	if self.bossId_ > 0 then
		self:initUIComponent()
	end
end

function GuildBossCard:getUIComponent()
	local go = self.go
	self.cardGroup = go:NodeByName("cardGroup").gameObject
	self.heroBg = self.cardGroup:ComponentByName("heroBg", typeof(UISprite))
	self.closeBg = self.cardGroup:ComponentByName("closeBg", typeof(UISprite))
	self.forceImg = self.cardGroup:ComponentByName("forceImg", typeof(UISprite))
	self.bossID = self.cardGroup:ComponentByName("bossID", typeof(UILabel))
	self.gottenMark = self.cardGroup:ComponentByName("gottenMark", typeof(UISprite))
	self.statusGroup = go:NodeByName("statusGroup").gameObject
	self.statusGroup2 = self.statusGroup:NodeByName("statusGroup2").gameObject
	self.rectTime = self.statusGroup2:NodeByName("rectTime").gameObject
	self.labelFightTime = self.statusGroup2:ComponentByName("labelFightTime", typeof(UILabel))
	self.statusGroup1 = self.statusGroup:NodeByName("statusGroup1").gameObject
	self.clearImg = self.statusGroup1:ComponentByName("clearImg", typeof(UISprite))
	self.gLace = self.statusGroup:NodeByName("gLace").gameObject
end

function GuildBossCard:initUIComponent()
	self:initBossStatus()
end

function GuildBossCard:checkOpenFinalBoss()
	local isOpen = true

	if self.bossId_ == xyd.GUILD_FINAL_BOSS_ID then
		local time_ = xyd.tables.miscTable:getNumber("guild_final_boss_begin_time", "value")
		local serverTime = xyd.getServerTime()

		if serverTime < time_ then
			isOpen = false
		end
	end

	return isOpen
end

function GuildBossCard:initBossStatus()
	self.forceImg:SetActive(false)
	xyd.setUISprite(self.clearImg, nil, "guild_boss_clear_" .. xyd.Global.lang)
	self.clearImg:MakePixelPerfect()

	local flag = false

	for i = 1, #xyd.models.guild.awardBossIds do
		if self.bossId_ == xyd.models.guild.awardBossIds[i] then
			flag = true
		end
	end

	if flag and not self.isDetail then
		self.gottenMark:SetActive(true)
	else
		self.gottenMark:SetActive(false)
	end

	if self.pageNum_ == 0 or self.maxID_ < self.bossId_ then
		self:SetActive(false)
	else
		self:SetActive(true)

		self.bossID.text = tostring(self.bossId_)

		if self.bossId_ < xyd.models.guild.bossID then
			self:bossClear()
			xyd.applyGrey(self.gottenMark)
		elseif self.bossId_ == xyd.models.guild.bossID and self:checkOpenFinalBoss() then
			self:bossOpen()
			xyd.applyOrigin(self.gottenMark)
		else
			self:bossClose()
			xyd.applyGrey(self.gottenMark)
		end
	end

	xyd.setDarkenBtnBehavior(self.go, self, self.touchCard)

	if self.isDetail then
		self.closeBg:SetActive(false)
		xyd.setUISprite(self.heroBg, nil, xyd.tables.guildBossTable:getShow(self.bossId_))
		self.heroBg:SetActive(true)
		self.statusGroup:SetActive(false)
		self.statusGroup1:SetActive(false)
		self.statusGroup2:SetActive(false)

		self.bossID.text = xyd.getRoughDisplayNumber(xyd.tables.guildBossTable:getPower(self.bossId_))
		self.bossID.fontSize = 21

		self.bossID.gameObject:X(20)
		self.forceImg:SetActive(true)
	end
end

function GuildBossCard:touchCard()
	xyd.SoundManager:get():playSound(xyd.SoundID.BUTTON)

	if self.isDetail then
		return
	end

	if self.cardStatus_ == 1 then
		xyd.WindowManager.get():openWindow("guild_boss_history_window", {
			bossId = self.bossId_
		})
	elseif self.cardStatus_ == 2 then
		if self.bossId_ == xyd.GUILD_FINAL_BOSS_ID then
			if os.date("!*t", xyd.getServerTime()).wday == 6 and os.date("!*t", xyd.getServerTime()).hour == 0 then
				xyd.showToast(__("GUILD_TEXT68"))

				return
			end

			xyd.WindowManager.get():openWindow("guild_final_boss_window", {
				bossId = self.bossId_
			})
		else
			xyd.WindowManager.get():openWindow("guild_boss_window", {
				bossId = self.bossId_
			})
		end
	end
end

function GuildBossCard:bossClear()
	xyd.setUISprite(self.heroBg, nil, xyd.tables.guildBossTable:getShow(self.bossId_))
	self.heroBg:SetActive(true)
	self.closeBg:SetActive(false)

	if self.cardStatus_ ~= 1 then
		xyd.applyChildrenGrey(self.cardGroup)
	end

	self.gLace:SetActive(false)

	self.cardStatus_ = 1

	self.statusGroup1:SetActive(true)
	self.statusGroup2:SetActive(false)
	self.statusGroup:SetActive(true)
end

function GuildBossCard:bossOpen()
	self.closeBg:SetActive(false)
	xyd.setUISprite(self.heroBg, nil, xyd.tables.guildBossTable:getShow(self.bossId_))
	self.heroBg:SetActive(true)
	self.gLace:SetActive(true)

	if self.cardStatus_ == 1 then
		xyd.applyChildrenOrigin(self.cardGroup)
	end

	local updateTime = xyd.models.guild:getFightUpdateTime()

	if xyd.getServerTime() < updateTime then
		self:setCountDownTime(updateTime - xyd.getServerTime())
		self.labelFightTime.gameObject:SetActive(true)
		self.rectTime:SetActive(true)
	else
		self.labelFightTime.gameObject:SetActive(false)
		self.rectTime:SetActive(false)
	end

	self.cardStatus_ = 2

	self.statusGroup1:SetActive(false)
	self.statusGroup2:SetActive(true)
	self.statusGroup:SetActive(true)
end

function GuildBossCard:setCountDownTime(duration)
	local params = {
		duration = duration
	}

	if not self.countDown_ then
		self.countDown_ = import("app.components.CountDown").new(self.labelFightTime, params)
	else
		self.countDown_:setInfo(params)
	end
end

function GuildBossCard:bossClose()
	self.closeBg:SetActive(true)
	self.heroBg:SetActive(false)

	if self.cardStatus_ == 1 then
		xyd.applyChildrenOrigin(self.cardGroup)
	end

	self.cardStatus_ = 3

	self.statusGroup:SetActive(false)
end

function GuildBossCard:updatePageNum(pageNum)
	if self.pageNum_ == pageNum then
		return
	end

	self.pageNum_ = pageNum

	if self.pageNum_ > 0 then
		self.bossId_ = (self.pageNum_ - 1) * 9 + self.id_
	end

	self:initBossStatus()
end

function GuildBossCard:addFightEffect()
	self.effect = xyd.Spine.new(self.heroBg.gameObject)

	self.effect:setInfo("jianxg", function ()
		self.effect:SetLocalScale(0.7777777777777778, 0.7777777777777778, 1)
		self.effect:SetLocalPosition(10, 0, 0)
		self.effect:setRenderTarget(self.heroBg, 1)
		self.effect:play("texiao1", 0, 1)
	end)
	self.gLace:SetActive(true)
end

function GuildBossCard:removeFightEffect()
	if self.effect then
		self.effect:destroy()
	end

	self.gLace:SetActive(false)
end

function GuildBossCard:getBossIDLabel()
	return self.bossID
end

function GuildBossCard:updateBossID(bossId)
	self.bossId_ = bossId
	self.isDetail = true

	self:initUIComponent()
end

return GuildGymWindow
