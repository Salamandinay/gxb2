local BaseWindow = import(".BaseWindow")
local GuildLabWindow = class("GuildLabWindow", BaseWindow)

function GuildLabWindow:ctor(name, params)
	self.curSelect = 1
	self.curSelectSkill = 1
	self.MAX_SKILL_NUM = 8
	self.levChange = {}
	self.skillUnLock = {}
	self.tmpSkillLev = {}
	self.selfMana_ = 0
	self.selfCoin_ = 0
	self.showSkillEffect_ = false
	self.selectPage = 1
	self.isHideNewSkill = false
	self.selectHistory = {
		1,
		1,
		1,
		1,
		1
	}

	BaseWindow.ctor(self, name, params)
end

function GuildLabWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function GuildLabWindow:getUIComponent()
	self.resGroup = self.window_:NodeByName("resGroup").gameObject
	local go = self.window_:NodeByName("main").gameObject
	self.nav = go:NodeByName("nav").gameObject
	self.labelTitle_ = go:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.bg = go:NodeByName("bg").gameObject
	self.bgTop = self.bg:NodeByName("bgTop").gameObject
	self.helpBtn = self.bgTop:NodeByName("helpBtn").gameObject
	self.btnReset = self.bgTop:NodeByName("btnReset").gameObject
	self.rightArrowBtn = self.bgTop:NodeByName("rightArrowBtn").gameObject
	self.leftArrowBtn = self.bgTop:NodeByName("leftArrowBtn").gameObject
	self.page1 = self.bgTop:ComponentByName("page1", typeof(UISprite))
	self.page2 = self.bgTop:ComponentByName("page2", typeof(UISprite))
	self.moveCon = self.bgTop:NodeByName("moveCon").gameObject
	self.firstCon = self.moveCon:NodeByName("firstCon").gameObject
	self.imgCurJop_ = self.moveCon:ComponentByName("firstCon/imgCurJop_", typeof(UISprite))

	for i = 1, 8 do
		self["btnSkill" .. i] = self.moveCon:NodeByName("firstCon/btnSkill" .. i).gameObject
		self["btnSkill" .. i .. "_icon"] = self["btnSkill" .. i]:ComponentByName("imgSkillIcon", typeof(UISprite))
		self["btnSkill" .. i .. "_icon2"] = self["btnSkill" .. i]:ComponentByName("imgSkillIcon2", typeof(UISprite))
		self["btnSkill" .. i .. "_label"] = self["btnSkill" .. i]:ComponentByName("labelDisplay", typeof(UILabel))
		self["imgArrow_first" .. i] = self.moveCon:NodeByName("firstCon/imgArrow" .. i).gameObject
		self["imgArrow_first" .. i .. "uisprite"] = self["imgArrow_first" .. i]:GetComponent(typeof(UISprite))

		if i == 1 or i == 7 then
			xyd.setUISpriteAsync(self["imgArrow_first" .. i .. "uisprite"], nil, "guild_arrow01")
		end

		if i == 2 or i == 6 then
			xyd.setUISpriteAsync(self["imgArrow_first" .. i .. "uisprite"], nil, "guild_arrow02")
		end

		if i == 3 or i == 5 then
			xyd.setUISpriteAsync(self["imgArrow_first" .. i .. "uisprite"], nil, "guild_arrow03")
		end

		if i == 4 or i == 8 then
			xyd.setUISpriteAsync(self["imgArrow_first" .. i .. "uisprite"], nil, "guild_arrow04")
		end
	end

	for i = 1, 7 do
		self["imgArrow" .. i] = self.moveCon:NodeByName("firstCon/imgArrow" .. i).gameObject
	end

	local tmp = NGUITools.AddChild(self.moveCon.gameObject, self.firstCon.gameObject)
	tmp.name = "secondCon"
	self.secondCon = tmp

	self.secondCon:SetLocalPosition(640, 0, 0)

	self.imgCurJop_second = self.secondCon:ComponentByName("imgCurJop_", typeof(UISprite))
	self.imgCurJop_second.gameObject.name = "imgCurJop_second"

	self.imgCurJop_second.gameObject:SetLocalPosition(5.2, 3.7, 0)
	self.imgCurJop_second:SetLocalScale(0.85, 0.85, 0.85)

	self.secondCon_bg1 = self.secondCon:ComponentByName("imgBg1", typeof(UISprite))
	self.secondCon_bg2 = self.secondCon:ComponentByName("imgBg2", typeof(UISprite))

	for i = 9, 16 do
		self["btnSkill" .. i] = self.moveCon:NodeByName("secondCon/btnSkill" .. i - 8).gameObject
		self["btnSkill" .. i].name = "btnSkill" .. i
		self["btnSkill" .. i .. "_icon"] = self["btnSkill" .. i]:ComponentByName("imgSkillIcon", typeof(UISprite))
		self["btnSkill" .. i .. "_icon2"] = self["btnSkill" .. i]:ComponentByName("imgSkillIcon2", typeof(UISprite))
		self["btnSkill" .. i .. "_label"] = self["btnSkill" .. i]:ComponentByName("labelDisplay", typeof(UILabel))
		local circle = NGUITools.AddChild(self["btnSkill" .. i].gameObject, self["btnSkill" .. i .. "_icon"].gameObject)
		local circle_widget = circle:GetComponent(typeof(UIWidget))
		circle_widget.depth = circle_widget.depth - 2

		xyd.setUISpriteAsync(circle:GetComponent(typeof(UISprite)), nil, "guild_skill_bg3")

		circle_widget.width = 92
		circle_widget.height = 92
		circle.name = "btnSkillCircleBg"
	end

	self.new_effectCon1 = self.secondCon:NodeByName("effectCon1").gameObject
	self.new_effectCon2 = self.secondCon:NodeByName("effectCon2").gameObject

	for i = 9, 16 do
		self["imgArrow" .. i] = self.moveCon:NodeByName("secondCon/imgArrow" .. i - 8).gameObject
		self["imgArrow" .. i .. "uisprite"] = self["imgArrow" .. i]:GetComponent(typeof(UISprite))
		self["imgArrow" .. i].name = "imgArrow" .. i

		if i == 9 or i == 15 then
			xyd.setUISpriteAsync(self["imgArrow" .. i .. "uisprite"], nil, "guild_arrow01_new")
		end

		if i == 10 or i == 14 then
			xyd.setUISpriteAsync(self["imgArrow" .. i .. "uisprite"], nil, "guild_arrow02_new")
		end

		if i == 11 or i == 13 then
			xyd.setUISpriteAsync(self["imgArrow" .. i .. "uisprite"], nil, "guild_arrow03_new")
		end

		if i == 12 or i == 16 then
			xyd.setUISpriteAsync(self["imgArrow" .. i .. "uisprite"], nil, "guild_arrow04_new")
		end
	end

	self["imgArrow" .. 16]:SetActive(true)
	xyd.setUISpriteAsync(self.secondCon_bg1, nil, "guild_bg_flower_new2")

	self.secondCon_bg1.width = 243
	self.secondCon_bg1.height = 238

	self.secondCon_bg1:SetActive(false)
	self.secondCon_bg2:SetActive(false)
	xyd.setUISpriteAsync(self.secondCon_bg2, nil, "guild_bg_flower_new1")

	self.secondCon_bg2.width = 231
	self.secondCon_bg2.height = 260

	if self.isHideNewSkill then
		self.page1:SetActive(false)
		self.page2:SetActive(false)
		self.leftArrowBtn:SetActive(false)
		self.rightArrowBtn:SetActive(false)
	end

	self.bgBottom = self.bg:NodeByName("bgBottom").gameObject
	self.btnCurSkill_ = self.bgBottom:NodeByName("btnCurSkill_").gameObject
	self.btnCurSkill_icon = self.btnCurSkill_:ComponentByName("imgSkillIcon", typeof(UISprite))
	self.btnCurSkill_label = self.btnCurSkill_:ComponentByName("labelDisplay", typeof(UILabel))
	self.labelCurSkillName_ = self.bgBottom:ComponentByName("labelCurSkillName_", typeof(UILabel))
	self.groupAttr1 = self.bgBottom:NodeByName("groupAttr1").gameObject
	self.groupAttrBg1 = self.groupAttr1:ComponentByName("groupAttrBg1", typeof(UIWidget))
	self.labelAttrName1 = self.groupAttr1:ComponentByName("labelAttrName1", typeof(UILabel))
	self.labelAttr1Num1 = self.groupAttr1:ComponentByName("labelAttr1Num1", typeof(UILabel))
	self.labelAttr1Num2 = self.groupAttr1:ComponentByName("labelAttr1Num2", typeof(UILabel))
	self.imgAttrArrow1 = self.groupAttr1:ComponentByName("imgAttrArrow1", typeof(UISprite))
	self.groupAttr2 = self.bgBottom:NodeByName("groupAttr2").gameObject
	self.groupAttrBg2 = self.groupAttr2:ComponentByName("groupAttrBg2", typeof(UIWidget))
	self.labelAttrName2 = self.groupAttr2:ComponentByName("labelAttrName2", typeof(UILabel))
	self.labelAttr2Num1 = self.groupAttr2:ComponentByName("labelAttr2Num1", typeof(UILabel))
	self.labelAttr2Num2 = self.groupAttr2:ComponentByName("labelAttr2Num2", typeof(UILabel))
	self.imgAttrArrow2 = self.groupAttr2:ComponentByName("imgAttrArrow2", typeof(UISprite))
	self.labelPreDesc_ = self.bgBottom:ComponentByName("labelPreDesc_", typeof(UILabel))

	if not self.isHideNewSkill then
		for i = 1, 2 do
			self["labelAttrName" .. i].overflowMethod = UILabel.Overflow.ResizeFreely
		end
	end

	self.groupCost_ = self.bg:NodeByName("groupCost_").gameObject
	self.labelMana_ = self.groupCost_:ComponentByName("labelMana_", typeof(UILabel))
	self.labelGuildCoin_ = self.groupCost_:ComponentByName("labelGuildCoin_", typeof(UILabel))
	self.btnLevUp_ = self.bg:NodeByName("btnLevUp_").gameObject
	self.btnLevUp_label = self.btnLevUp_:ComponentByName("button_label", typeof(UILabel))
end

function GuildLabWindow:initUIComponent()
	self:layout()
	self:changeSelect(self.curSelect)
	self:updateData()
	self:registerEvent()
	xyd.models.guild:needUpdateJobs({})
	xyd.models.guild:reqGuildSkills()
	self:initNewSkillEffect()
end

function GuildLabWindow:willClose(params, skipAnimation, force)
	BaseWindow.willClose(self, params, skipAnimation, force)

	if #self.levChange > 0 then
		xyd.models.guild:needUpdateJobs(self.levChange)
	end

	self.showSkillEffect_ = false
	local tmpChanges = {}

	for skillID in pairs(self.tmpSkillLev) do
		local num = self.tmpSkillLev[skillID]

		if num > 0 then
			xyd.models.guild:skillLevUp(skillID, num)

			local job = xyd.tables.guildSkillTable:getJob(skillID)

			if not table.indexof(tmpChanges, job) then
				table.insert(tmpChanges, job)
			end
		end
	end

	local updateJobs = {}

	for i = 1, #self.levChange do
		local job = self.levChange[i]

		if not table.indexof(tmpChanges, job) then
			table.insert(updateJobs, job)
		end
	end

	if #updateJobs > 0 then
		xyd.models.slot:updateJobsAttr(updateJobs)
	end

	self.tmpSkillLev = {}
end

function GuildLabWindow:onGuildSkills()
	self:updateData()
end

function GuildLabWindow:layout()
	self.labelTitle_.text = __("GUILD_LAB_WINDOW")
	self.btnLevUp_label.text = __("LEV_UP")

	if not self.isHideNewSkill then
		if self.selectPage == 1 then
			self.leftArrowBtn:SetActive(false)
			self.rightArrowBtn:SetActive(true)
		else
			self.leftArrowBtn:SetActive(true)
			self.rightArrowBtn:SetActive(false)
		end
	end

	xyd.setTouchEnable(self.btnCurSkill_, false)

	self.selfMana_ = xyd.models.backpack:getMana()
	self.selfCoin_ = xyd.models.backpack:getItemNumByID(xyd.ItemID.GUILD_COIN)
	self.resMana_ = require("app.components.ResItem").new(self.resGroup)
	self.resCoin_ = require("app.components.ResItem").new(self.resGroup)

	self.resGroup:GetComponent(typeof(UILayout)):Reposition()
	self.resMana_:setInfo({
		tableId = xyd.ItemID.MANA
	})
	self.resCoin_:setInfo({
		show_tips = true,
		tableId = xyd.ItemID.GUILD_COIN
	})
	self.resCoin_:hidePlus()
	self:updateResItem()
end

function GuildLabWindow:updateResItem(data)
	if data then
		self.selfMana_ = self.selfMana_ - data.mana
		self.selfCoin_ = self.selfCoin_ - data.coin
	end

	self.resMana_:setItemNum(self.selfMana_)
	self.resCoin_:setItemNum(self.selfCoin_)
end

function GuildLabWindow:registerEvent()
	if self.closeBtn then
		UIEventListener.Get(self.closeBtn).onClick = function ()
			self:onClickCloseButton()
		end
	end

	if self.helpBtn then
		UIEventListener.Get(self.helpBtn).onClick = function ()
			local params = {
				key = "GUILD_LAB_WINDOW_HELP_U3"
			}

			xyd.WindowManager.get():openWindow("help_window", params)
		end
	end

	xyd.setDarkenBtnBehavior(self.btnReset, self, self.resetTouch)

	self.tab = require("app.common.ui.CommonTabBar").new(self.nav, 5, function (index)
		self:checkNeedLevUpSkill()
		self:changeSelect(index)
	end)
	local display = {}

	for k = 1, 5 do
		table.insert(display, xyd.tables.jobTable:getName(k))
	end

	self.tab:setTexts(display)

	for i = 1, self.MAX_SKILL_NUM do
		UIEventListener.Get(self["btnSkill" .. i]).onClick = function ()
			self:checkNeedLevUpSkill()
			self:updateCurSkill(i)
		end
	end

	for i = 9, 16 do
		UIEventListener.Get(self["btnSkill" .. i]).onClick = function ()
			self:checkNeedLevUpSkill()
			self:updateCurSkill(i)
		end
	end

	UIEventListener.Get(self.rightArrowBtn).onClick = handler(self, self.moveToRight)
	UIEventListener.Get(self.leftArrowBtn).onClick = handler(self, self.moveToLeft)

	UIEventListener.Get(self.btnLevUp_).onPress = function (go, isPressed)
		self:levUpLongTouch(go, isPressed)
	end

	self.eventProxy_:addEventListener(xyd.event.GUILD_GET_SKILLS, self.onGuildSkills, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_UPGRADE_SKILL, self.onGuildSkillLevUp, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_RESET_SKILL, self.onGuildResetSkill, self)
end

function GuildLabWindow:levUpLongTouch(go, isPressed)
	local longTouchFunc = nil

	function longTouchFunc()
		self:levUpTouch()

		if self.levUpLongTouchFlag == true then
			XYDCo.WaitForTime(0.2, function ()
				if tolua.isnull(go) or go.activeSelf == false then
					return
				end

				longTouchFunc()
			end, "levUpLongTouchClick")
		end
	end

	XYDCo.StopWait("levUpLongTouch")

	if isPressed then
		self.levUpLongTouchFlag = true

		XYDCo.WaitForTime(0.5, function ()
			if tolua.isnull(go) or go.activeSelf == false then
				return
			end

			if self.levUpLongTouchFlag then
				longTouchFunc()
			end
		end, "levUpLongTouch")
	else
		self:levUpTouch()

		self.levUpLongTouchFlag = false
	end

	local tScale = Vector3(1, 1, 1)

	if isPressed then
		go.transform.localScale = tScale * 0.9
	else
		local sequence = DG.Tweening.DOTween.Sequence()

		sequence:Append(go.transform:DOScale(tScale * 1.2, 3 * xyd.TweenDeltaTime))
		sequence:Append(go.transform:DOScale(tScale * 0.95, 3 * xyd.TweenDeltaTime))
		sequence:Append(go.transform:DOScale(tScale, 3 * xyd.TweenDeltaTime))
	end
end

function GuildLabWindow:levUpTouch()
	local skillID = self:getCurSkill(self.curSelectSkill)

	if self:checkCanLevUp(skillID) then
		local lev = self:getSkillLev(skillID)
		local cost = self:getCost(skillID)

		self:updateResItem(cost)

		self.showSkillEffect_ = true

		if lev == 9 then
			local num = (self.tmpSkillLev[skillID] or 0) + 1
			self.tmpSkillLev[skillID] = 0

			xyd.models.guild:skillLevUp(skillID, num)
		else
			self.tmpSkillLev[skillID] = (self.tmpSkillLev[skillID] or 0) + 1

			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.GUILD_UPGRADE_SKILL,
				params = {
					num = 1,
					skill_id = skillID
				}
			})
		end
	end
end

function GuildLabWindow:checkNeedLevUpSkill()
	local skillID = self:getCurSkill(self.curSelectSkill)
	local num = self.tmpSkillLev[skillID] or 0

	if num > 0 then
		self.showSkillEffect_ = false
		self.tmpSkillLev[skillID] = 0

		xyd.models.guild:skillLevUp(skillID, num)
	end
end

function GuildLabWindow:beforeReset()
	self.showSkillEffect_ = false

	for skillID in pairs(self.tmpSkillLev) do
		local num = self.tmpSkillLev[skillID] or 0
		self.tmpSkillLev[skillID] = 0

		if num > 0 then
			xyd.models.guild:skillLevUp(skillID, num)
		end
	end
end

function GuildLabWindow:checkCanLevUp(skillID)
	if not skillID then
		return false
	end

	local cost = self:getCost(skillID)

	if cost.isMax then
		return false
	end

	if self.selfMana_ < cost.mana then
		xyd.alertTips(__("NOT_ENOUGH_MANA"))

		return false
	end

	if self.selfCoin_ < cost.coin then
		xyd.alertTips(__("GUILD_SKILL_NO_RES"))

		return false
	end

	return true
end

function GuildLabWindow:onGuildSkillLevUp(event)
	local skillID, num = nil

	if event.params then
		skillID = event.params.skill_id
		num = event.params.num
	end

	if event.data then
		skillID = event.data.skill_id
		num = event.data.num
	end

	if not skillID then
		return
	end

	local job = xyd.tables.guildSkillTable:getJob(skillID)

	if xyd.arrayIndexOf(self.levChange, job) < 0 then
		table.insert(self.levChange, job)
	end

	local isUnLock = self:showLevUpEffect()

	if not isUnLock then
		self:updateData()
	end
end

function GuildLabWindow:showLevUpEffect()
	if not self.showSkillEffect_ then
		return
	end

	local btnSkill = self.btnCurSkill_
	local effect = self:getDragonbonesEffect("shetuan_shengji", btnSkill, self.btnCurSkill_icon)

	if self.selectPage == 2 then
		return
	end

	local skills = xyd.tables.guildSkillTable:getJobSkills(self.curSelect)
	local nextSkill = skills[self.curSelectSkill + 1]

	if nextSkill and xyd.arrayIndexOf(self.skillUnLock, nextSkill) < 0 and self:checkPreSkillValid(nextSkill) then
		self:showSkillUnLock()

		return true
	end

	return false
end

function GuildLabWindow:showSkillUnLock()
	local btnSkill = self["btnSkill" .. self.curSelectSkill + 1]

	if btnSkill then
		if not self["effectbtnSkill" .. self.curSelectSkill] then
			self["effectbtnSkill" .. self.curSelectSkill] = self:getDragonbonesEffect("shetuan_jiesuo", btnSkill)
		else
			self["effectbtnSkill" .. self.curSelectSkill]:play("texiao01", 1, 1)
		end

		local img2 = self["btnSkill" .. self.curSelectSkill + 1 .. "_icon2"]

		img2:SetActive(true)

		local sequence = DG.Tweening.DOTween.Sequence()

		local function setter(val)
			img2.color = Color.New2(val)
		end

		sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 4294967040.0, 4294967295.0, 0.1))
		sequence:AppendCallback(function ()
			self:updateData()
		end)
	end
end

function GuildLabWindow:getDragonbonesEffect(effectName, parent, widget)
	local effect = xyd.Spine.new(parent)

	effect:setInfo(effectName, function ()
		effect:play("texiao01", 1, 1)

		if widget then
			effect:setRenderTarget(widget, 1)
		end
	end, true)

	return effect
end

function GuildLabWindow:resetTouch()
	local resetCost = xyd.split(xyd.tables.miscTable:getVal("guild_reset_skill_cost"), "#", true)

	if self.selectPage == 1 then
		local skillID = self:getCurSkill(1)
		local curLev = self:getSkillLev(skillID)

		if curLev <= 0 then
			xyd.alertTips(__("GUILD_NO_SKILL_CAN_RESET"))

			return false
		end
	else
		local skills = xyd.tables.guildSkillTable:getJobSkills(self.curSelect)
		local isSecondPageHasLev = false

		for i = 9, 16 do
			local id = skills[i]
			local curPreSkillLev = self:getSkillLev(id)

			if curPreSkillLev > 0 then
				isSecondPageHasLev = true

				break
			end
		end

		if not isSecondPageHasLev then
			xyd.alertTips(__("GUILD_NO_SKILL_CAN_RESET"))

			return false
		end
	end

	self:beforeReset()

	local guildSkillTable = xyd.tables.guildSkillTable
	local skillID = self:getCurSkill(self.curSelectSkill)
	local resetNum = guildSkillTable:getReset(skillID)

	if xyd.models.guild:isResetFree(resetNum) then
		resetCost[2] = 0
	end

	xyd.alertConfirm(__("GUILD_RESET_TIPS"), function ()
		local selfNum = xyd.models.backpack:getItemNumByID(resetCost[1])

		if selfNum < resetCost[2] then
			xyd.alertTips(__("NOT_ENOUGH_CRYSTAL"))
		else
			xyd.models.guild:resetSkill(resetNum)
		end
	end, __("SURE"), false, resetCost, __("GUILD_RESET"))
end

function GuildLabWindow:onGuildResetSkill(event)
	xyd.alertTips(__("GUILD_RESET_SUCCESS"))

	self.selfMana_ = xyd.models.backpack:getMana()
	self.selfCoin_ = xyd.models.backpack:getItemNumByID(xyd.ItemID.GUILD_COIN)

	self:updateResItem()

	self.curSelectSkill = 1

	for i, skillData in pairs(xyd.decodeProtoBuf(event.data).skills) do
		if skillData.skill_id then
			local resetNum = xyd.tables.guildSkillTable:getReset(skillData.skill_id)

			if resetNum >= 10 and resetNum <= 14 then
				self.curSelectSkill = 9

				break
			end
		end
	end

	self:updateData()
	xyd.models.slot:updateJobsAttr({
		self.curSelect
	})
end

function GuildLabWindow:changeSelect(index)
	self.curSelect = index
	self.oldSelectImgIndex = self.curSelectSkill
	self.curSelectSkill = 1

	xyd.setUISprite(self.imgCurJop_, nil, "guild_skill_job" .. self.curSelect)
	xyd.setUISpriteAsync(self.imgCurJop_second, nil, "guild_skill_job" .. self.curSelect .. "_new")

	self.selectPage = 1

	if self.sequence_page then
		self.sequence_page:Pause()
		self.sequence_page:Kill(true)
	end

	if not self.isHideNewSkill then
		self:setPageCircle(self.selectHistory[self.curSelect])

		if self.selectHistory[self.curSelect] == 1 then
			self.moveCon:SetLocalPosition(0, 0, 0)
			self.leftArrowBtn:SetActive(false)
			self.rightArrowBtn:SetActive(true)
		else
			self.selectPage = 2
			self.curSelectSkill = 9

			self.moveCon:SetLocalPosition(-640, 0, 0)
			self.leftArrowBtn:SetActive(true)
			self.rightArrowBtn:SetActive(false)

			if self.newSkillEffect2 then
				self.newSkillEffect2:stop()
				self.newSkillEffect2:SetActive(false)

				if not self.newSkillEffect1:getGameObject().activeSelf then
					self.newSkillEffect1:SetActive(true)
					self.newSkillEffect1:play("texiao01", 0)
				end
			end
		end
	end

	self:updateData()
end

function GuildLabWindow:updateData()
	self:updateSkills()
	self:updateCurSkill(self.curSelectSkill)
end

function GuildLabWindow:updateSkills()
	local guildSkillTable = xyd.tables.guildSkillTable
	local skills = guildSkillTable:getJobSkills(self.curSelect)

	for i = 1, 8 do
		local id = skills[i]
		local btn = self["btnSkill" .. i]
		local img = self["btnSkill" .. i .. "_icon"]
		local img2 = self["btnSkill" .. i .. "_icon2"]
		local label = self["btnSkill" .. i .. "_label"]

		xyd.setUISprite(img, nil, guildSkillTable:getIcon(id))
		xyd.setUISprite(img2, nil, guildSkillTable:getIcon(id))
		img:MakePixelPerfect()
		img2:MakePixelPerfect()
		img2:SetActive(false)

		local maxLev = guildSkillTable:getLevMax(id)
		local curLev = self:getSkillLev(id)
		label.text = tostring(curLev) .. "/" .. maxLev

		xyd.applyOrigin(img)

		if curLev == maxLev then
			label.effectColor = Color.New2(943741695)
			label.color = Color.New2(1945778431)
		elseif self:checkPreSkillValid(id) then
			label.effectColor = Color.New2(943741695)
			label.color = Color.New2(4294967295.0)
		else
			label.effectColor = Color.New2(1229539839)
			label.color = Color.New2(4294967295.0)

			xyd.applyGrey(img)
		end

		if i > 1 and self:checkPreSkillValid(id) then
			if table.indexof(self.skillUnLock, id) == false then
				table.insert(self.skillUnLock, id)
			end

			self["imgArrow" .. i - 1]:SetActive(true)
		elseif i > 1 then
			self["imgArrow" .. i - 1]:SetActive(false)
		end
	end

	for i = 9, 16 do
		local id = skills[i]
		local btn = self["btnSkill" .. i]
		local img = self["btnSkill" .. i .. "_icon"]
		local img2 = self["btnSkill" .. i .. "_icon2"]
		local label = self["btnSkill" .. i .. "_label"]

		xyd.setUISprite(img, nil, guildSkillTable:getIcon(id))
		xyd.setUISprite(img2, nil, guildSkillTable:getIcon(id))
		img:MakePixelPerfect()
		img2:MakePixelPerfect()
		img2:SetActive(false)

		local maxLev = guildSkillTable:getLevMax(id)
		local curLev = self:getSkillLev(id)
		label.text = tostring(curLev) .. "/" .. maxLev

		xyd.applyOrigin(img)

		if curLev == maxLev then
			label.effectColor = Color.New2(943741695)
			label.color = Color.New2(1945778431)
		elseif self:checkPreSkillValid(id) then
			label.effectColor = Color.New2(943741695)
			label.color = Color.New2(4294967295.0)
		else
			label.effectColor = Color.New2(1229539839)
			label.color = Color.New2(4294967295.0)

			xyd.applyGrey(img)
		end

		self["imgArrow" .. i]:SetActive(true)
	end
end

function GuildLabWindow:checkPreSkillValid(skillID)
	local preSkill = xyd.tables.guildSkillTable:getPreSkill(skillID)

	if preSkill and #preSkill == 1 and preSkill[1] <= 0 then
		return true
	end

	local isLock = false

	for i in pairs(preSkill) do
		local preSkillLev = xyd.tables.guildSkillTable:getLvReq(skillID)
		local curPreSkillLev = self:getSkillLev(preSkill[i])

		if curPreSkillLev < preSkillLev[i] then
			isLock = true

			break
		end
	end

	return not isLock
end

function GuildLabWindow:getCurSkill(index)
	local skills = xyd.tables.guildSkillTable:getJobSkills(self.curSelect)
	local skillID = skills[index]

	return skillID
end

function GuildLabWindow:getSkillLev(skillID)
	local curLev = xyd.models.guild:getSkillLevByID(tonumber(skillID))
	local lev = curLev + (self.tmpSkillLev[skillID] or 0)

	return lev
end

function GuildLabWindow:updateCurSkill(index)
	local guildSkillTable = xyd.tables.guildSkillTable
	local skillID = self:getCurSkill(index)

	if not skillID then
		return
	end

	xyd.setUISprite(self.btnCurSkill_icon, nil, guildSkillTable:getIcon(skillID))

	local baseEffects = guildSkillTable:getBaseEffect(skillID)
	local growEffects = guildSkillTable:getGrowEffect(skillID)
	local curLev = self:getSkillLev(skillID)
	local maxLev = guildSkillTable:getLevMax(skillID)
	local isMax = curLev == maxLev

	for i = 1, #baseEffects do
		local base = xyd.split(baseEffects[i], "#")
		local grow = xyd.split(growEffects[i], "#")
		local buffName = base[1]
		local num = tonumber(base[2]) + (curLev - 1) * tonumber(grow[2])

		if curLev <= 0 then
			num = 0
		end

		self["groupAttr" .. i]:SetActive(true)

		self["labelAttrName" .. i].text = xyd.tables.dBuffTable:getDesc(buffName)

		if not self.isHideNewSkill then
			self["labelAttrName" .. i].fontSize = 20

			if self["labelAttrName" .. i].width > 190 then
				while true do
					self["labelAttrName" .. i].fontSize = self["labelAttrName" .. i].fontSize - 1

					if self["labelAttrName" .. i].width <= 190 then
						break
					end
				end
			end

			self["groupAttrBg" .. i].width = self["labelAttrName" .. i].width + 14
		end

		self["labelAttr" .. i .. "Num1"].text = xyd.tables.dBuffTable:translationNum(buffName, num)
		local label2Num = self["labelAttr" .. i .. "Num2"]
		local imgArrow = self["imgAttrArrow" .. i]

		if not isMax then
			local nextNum = tonumber(base[2]) + curLev * tonumber(grow[2])
			label2Num.text = xyd.tables.dBuffTable:translationNum(buffName, nextNum)

			label2Num:SetActive(true)
			imgArrow:SetActive(true)
		else
			label2Num:SetActive(false)
			imgArrow:SetActive(false)
		end
	end

	if #baseEffects < 2 then
		self.groupAttr2:SetActive(false)
		self.labelPreDesc_.gameObject:Y(-4)
	else
		self.labelPreDesc_.gameObject:Y(-49)
	end

	self.labelCurSkillName_.text = guildSkillTable:getName(skillID)
	local isShowCost = true

	if self:checkPreSkillValid(skillID) then
		self.labelPreDesc_:SetActive(false)
	else
		if self.selectPage == 1 then
			local preSkillLev = xyd.tables.guildSkillTable:getLvReq(skillID)
			self.labelPreDesc_.text = __("GUILD_LAB_SKILL_TIPS1", preSkillLev[1])
		elseif self.selectPage == 2 then
			self.labelPreDesc_.text = __("GUILD_SKILL2_TEXT01")
		end

		self.labelPreDesc_:SetActive(true)

		isShowCost = false
	end

	local oldBtn = self["btnSkill" .. self.curSelectSkill]

	xyd.setUISprite(oldBtn:GetComponent(typeof(UISprite)), nil, "guild_skill_bg1")

	if self.oldSelectImgIndex then
		local oldBtn2 = self["btnSkill" .. self.oldSelectImgIndex]

		xyd.setUISprite(oldBtn2:GetComponent(typeof(UISprite)), nil, "guild_skill_bg1")
	end

	local curBtn = self["btnSkill" .. index]

	xyd.setUISprite(curBtn:GetComponent(typeof(UISprite)), nil, "guild_skill_bg2")

	self.curSelectSkill = index

	self:updateCost(isShowCost)
end

function GuildLabWindow:updateCost(isShowCost)
	local skillID = self:getCurSkill(self.curSelectSkill)

	if not skillID then
		return
	end

	local cost = self:getCost(skillID)

	if cost.isMax then
		self.groupCost_:SetActive(false)
		self.btnLevUp_:SetActive(false)
	else
		self.groupCost_:SetActive(true)
		self.btnLevUp_:SetActive(true)

		self.labelMana_.text = tostring(cost.mana)
		self.labelGuildCoin_.text = tostring(cost.coin)

		if self.selfMana_ < cost.mana then
			self.labelMana_.color = Color.New2(3422556671.0)
		else
			self.labelMana_.color = Color.New2(1432789759)
		end

		if self.selfCoin_ < cost.coin then
			self.labelGuildCoin_.color = Color.New2(3422556671.0)
		else
			self.labelGuildCoin_.color = Color.New2(1432789759)
		end

		if not isShowCost then
			xyd.setEnabled(self.btnLevUp_, false)
		else
			xyd.setEnabled(self.btnLevUp_, true)
		end
	end
end

function GuildLabWindow:getCost(skillID)
	local guildSkillTable = xyd.tables.guildSkillTable
	local curLev = self:getSkillLev(skillID)
	local maxLev = guildSkillTable:getLevMax(skillID)
	local isMax = curLev == maxLev
	local mana = 0
	local coin = 0

	if not isMax then
		local baseGold = guildSkillTable:getBaseGold(skillID)
		local growGold = guildSkillTable:getGrowGold(skillID)
		mana = baseGold[2] + growGold * curLev
		local baseCoin = guildSkillTable:getBaseGuildCoin(skillID)
		local growCoin = guildSkillTable:getGrowGuildCoin(skillID)
		coin = baseCoin[2] + growCoin * curLev
	end

	return {
		isMax = isMax,
		mana = mana,
		coin = coin
	}
end

function GuildLabWindow:initNewSkillEffect()
	if not self.isHideNewSkill then
		self.newSkillEffect1 = xyd.Spine.new(self.new_effectCon1.gameObject)

		self.newSkillEffect1:setInfo("guild_skill2_loading", function ()
			self.newSkillEffect1:play("texiao01", 0)
		end)
		self.newSkillEffect1:SetLocalPosition(20.8, -468.6, 0)

		self.newSkillEffect2 = xyd.Spine.new(self.new_effectCon2.gameObject)

		self.newSkillEffect2:setInfo("guild_skill2_switch", function ()
		end)
		self.newSkillEffect2:SetLocalPosition(20.8, -466.5, 0)
	end
end

function GuildLabWindow:moveToRight()
	local guildSkillTable = xyd.tables.guildSkillTable
	local skills = guildSkillTable:getJobSkills(self.curSelect)
	local isSecondPageHasLev = false

	for i = 9, 16 do
		local id = skills[i]
		local curPreSkillLev = self:getSkillLev(id)

		if curPreSkillLev > 0 then
			isSecondPageHasLev = true

			break
		end
	end

	if not isSecondPageHasLev then
		local skillID = self:getCurSkill(9)

		if not self:checkPreSkillValid(skillID) then
			xyd.showToast(__("GUILD_SKILL2_TEXT01"))

			return
		end
	end

	self.newSkillEffect1:stop()
	self.newSkillEffect1:SetActive(false)

	if self.newSkillEffect2 then
		self.newSkillEffect2:SetActive(true)
		self.newSkillEffect2:play("texiao01", 1, 1, function ()
			self.newSkillEffect1:SetActive(true)
			self.newSkillEffect1:play("texiao01", 0)
			self:waitForTime(0.01, function ()
				self.newSkillEffect2:SetActive(false)
			end)
		end)
	end

	self:checkNeedLevUpSkill()

	self.selectPage = 2
	self.oldSelectImgIndex = self.curSelectSkill
	self.curSelectSkill = 9

	self:setPageCircle(2)

	self.selectHistory[self.curSelect] = 2

	self:updateCurSkill(self.curSelectSkill)

	self.sequence_page = self:getSequence()

	self.rightArrowBtn:SetActive(false)
	self.sequence_page:Append(self.moveCon.transform:DOLocalMoveX(-640, 0.4))
	self.sequence_page:AppendCallback(function ()
		self.sequence_page:Kill(true)
		self.leftArrowBtn:SetActive(true)
		self.rightArrowBtn:SetActive(false)
	end)
end

function GuildLabWindow:moveToLeft()
	self:checkNeedLevUpSkill()

	self.selectPage = 1
	self.oldSelectImgIndex = self.curSelectSkill
	self.curSelectSkill = 1

	self:setPageCircle(1)

	self.selectHistory[self.curSelect] = 1

	self:updateCurSkill(self.curSelectSkill)

	self.sequence_page = self:getSequence()

	self.leftArrowBtn:SetActive(false)
	self.sequence_page:Append(self.moveCon.transform:DOLocalMoveX(0, 0.4))
	self.sequence_page:AppendCallback(function ()
		self.sequence_page:Kill(true)
		self.leftArrowBtn:SetActive(false)
		self.rightArrowBtn:SetActive(true)
	end)
end

function GuildLabWindow:setPageCircle(page)
	if self.isHideNewSkill then
		return
	end

	for i = 1, 2 do
		if i == page then
			if self["page" .. i] then
				xyd.setUISpriteAsync(self["page" .. i], nil, "page_icon_1", nil, )
			end
		elseif self["page" .. i] then
			xyd.setUISpriteAsync(self["page" .. i], nil, "page_icon_0", nil, )
		end
	end
end

return GuildLabWindow
