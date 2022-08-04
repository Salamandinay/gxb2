local FormationItem = class("FormationItem")

function FormationItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = nil
	self.isFriend = false
end

function FormationItem:setIsFriend(isFriend)
	self.isFriend = isFriend
end

function FormationItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	if not self.heroIcon_ then
		self.heroIcon_ = import("app.components.HeroIcon").new(self.uiRoot_, self.parent_.partnerRenderPanel)
	end

	self.partner_ = info.partnerInfo
	self.callbackFunc = info.callbackFunc
	self.partnerId_ = self.partner_.partnerID
	self.partner_.noClickSelected = false
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.partnerScrollerUIScrollView
	self.partner_.is_vowed = self.partner_.is_vowed
	self.partner_.noClick = false
	self.partner_.isShowSelected = false

	self.heroIcon_:setInfo(self.partner_)
	self:setIsChoose(false)
	self.heroIcon_:setLock(false)

	if self.partner_:getPartnerID() == self.parent_:getPartnerID() then
		self:setIsChoose(true)

		self.parent_.lastItem = self
	end

	if xyd.models.guild:isUsedGuildCompetitionUsedPrsToday(self.partner_:getTableID()) then
		self.heroIcon_:setLock(true)
	end
end

function FormationItem:onClick()
	if xyd.models.guild:isUsedGuildCompetitionUsedPrsToday(self.partner_:getTableID()) then
		xyd.alertTips(__("GUILD_COMPETITION_PARTNER_TEXT02"))

		return
	end

	self.callbackFunc(self.partner_, self)
	self:setIsChoose(true)
end

function FormationItem:setIsChoose(status)
	if self.heroIcon_ then
		self.heroIcon_:setChoose(status)
	end
end

function FormationItem:getHeroIcon()
	return self.heroIcon_
end

function FormationItem:getPartnerId()
	return self.partnerId_
end

function FormationItem:setShowActive(canShow)
	self.uiRoot_.gameObject:SetActive(canShow)
end

function FormationItem:getGameObject()
	return self.uiRoot_
end

function FormationItem:getPartner()
	return self.partner_
end

local GuildCompetitionPartnerStudyWindow = class("GuildCompetitionPartnerStudyWindow", import(".BaseWindow"))
local PartnerCardLarge = import("app.components.PartnerCardLarge")

function GuildCompetitionPartnerStudyWindow:ctor(name, params)
	GuildCompetitionPartnerStudyWindow.super.ctor(self, name, params)

	self.current_group = params.current_group or 0
end

function GuildCompetitionPartnerStudyWindow:initWindow()
	self:getUIComponent()
	GuildCompetitionPartnerStudyWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function GuildCompetitionPartnerStudyWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.winGroup = self.groupAction:NodeByName("winGroup").gameObject
	self.winTitle = self.winGroup:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = self.winGroup:NodeByName("closeBtn").gameObject
	self.helpBtn = self.winGroup:NodeByName("helpBtn").gameObject
	self.upGroup = self.groupAction:NodeByName("upGroup").gameObject
	self.desc = self.upGroup:ComponentByName("desc", typeof(UILabel))
	self.upBg = self.upGroup:ComponentByName("upBg", typeof(UISprite))
	self.leftCardCon = self.upGroup:NodeByName("leftCardCon").gameObject
	self.rightCardCon = self.upGroup:NodeByName("rightCardCon").gameObject
	self.arrowImg = self.upGroup:ComponentByName("arrowImg", typeof(UISprite))
	self.btnGroup = self.upGroup:NodeByName("btnGroup").gameObject
	self.changeBtn = self.btnGroup:NodeByName("changeBtn").gameObject
	self.changeBtnRedPoint = self.changeBtn:NodeByName("changeBtnRedPoint").gameObject
	self.changeBtnLabel = self.changeBtn:ComponentByName("changeBtnLabel", typeof(UILabel))
	self.sureBtn = self.btnGroup:NodeByName("sureBtn").gameObject
	self.sureBtnRedPoint = self.sureBtn:NodeByName("sureBtnRedPoint").gameObject
	self.sureBtnLabel = self.sureBtn:ComponentByName("sureBtnLabel", typeof(UILabel))
	self.downGroup = self.groupAction:NodeByName("downGroup").gameObject
	self.chooseGroup = self.downGroup:NodeByName("choose_group").gameObject
	self.fGroup = self.chooseGroup:NodeByName("f_group").gameObject
	self.partnerScroller = self.chooseGroup:NodeByName("partner_scroller").gameObject
	self.partnerScrollerUIScrollView = self.chooseGroup:ComponentByName("partner_scroller", typeof(UIScrollView))
	self.partnerContainer = self.partnerScroller:NodeByName("partner_container").gameObject
	self.partnerContainerUIWrapContent = self.partnerScroller:ComponentByName("partner_container", typeof(UIWrapContent))
	self.heroRoot = self.chooseGroup:NodeByName("hero_root").gameObject
	self.partnerNone = self.chooseGroup:NodeByName("partnerNone").gameObject
	self.labelNoneTips = self.partnerNone:ComponentByName("labelNoneTips", typeof(UILabel))
end

function GuildCompetitionPartnerStudyWindow:registerEvent()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "GUILD_COMPETITION_PARTNER_HELP"
		})
	end)

	UIEventListener.Get(self.changeBtn).onClick = function ()
		if self.copyPartner then
			local params = {
				hide_btn = false,
				index = 1,
				partner = self.copyPartner,
				table_id = self.copyPartner:getTableID(),
				partner_list = {}
			}

			xyd.WindowManager.get():openWindow("guild_competition_special_partner_window", params)
		else
			xyd.alertTips(__("GUILD_COMPETITION_PARTNER_TEXT01"))
		end
	end

	UIEventListener.Get(self.sureBtn).onClick = function ()
		if self.copyPartner then
			self:saveInfo()
			self:close()
		else
			xyd.alertTips(__("GUILD_COMPETITION_PARTNER_TEXT01"))
		end
	end

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

function GuildCompetitionPartnerStudyWindow:saveInfo()
	if self.copyPartner then
		xyd.models.guild:setCompetitionSpecialPartner(self.copyPartner)
		xyd.models.guild:setCompetitionSpecialTruePartnerInfo(self.truePartnerInfo)
	end
end

function GuildCompetitionPartnerStudyWindow:layout()
	self.labelNoneTips.text = __("NO_PARTNER_2")
	self.winTitle.text = __("GUILD_COMPETITION_PARTNER_TITLE")
	self.desc.text = __("GUILD_COMPETITION_PARTNER_TEXT01")
	self.changeBtnLabel.text = __("ENTRANCE_TEST_BATTLE_JUMP_SET")
	self.sureBtnLabel.text = __("SURE")

	self:initCard()
	self:initPartnerList()
	self:initFirstEnter()
end

function GuildCompetitionPartnerStudyWindow:initCard()
	self.partnerCardLeft = PartnerCardLarge.new(self.leftCardCon)

	self.partnerCardLeft:setDefaultCardVisible(true)
	self.partnerCardLeft:setUIItemsVisible(false, false, false)
	self.partnerCardLeft:setHeroCardVisible(false)
	self.partnerCardLeft:setNameVisible(false)

	self.partnerCardRight = PartnerCardLarge.new(self.rightCardCon)

	self.partnerCardRight:setDefaultCardVisible(true)
	self.partnerCardRight:setUIItemsVisible(false, false, false)
	self.partnerCardRight:setHeroCardVisible(false)
	self.partnerCardRight:setNameVisible(false)
end

function GuildCompetitionPartnerStudyWindow:initPartnerList()
	local scale = 0.9
	local params = {
		isCanUnSelected = 1,
		gap = 20,
		callback = handler(self, function (self, group)
			self:onSelectGroup(group)
		end),
		width = self.fGroup:GetComponent(typeof(UIWidget)).width,
		scale = scale,
		chosenGroup = self.current_group
	}
	local partnerFilter = import("app.components.PartnerFilter").new(self.fGroup.gameObject, params)
	self.partnerFilter = partnerFilter

	self.partnerFilter:hideGroup(xyd.PartnerGroup.TIANYI)

	self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScrollerUIScrollView, self.partnerContainerUIWrapContent, self.heroRoot, FormationItem, self)

	self:iniPartnerData(self.current_group, true)
end

function GuildCompetitionPartnerStudyWindow:iniPartnerData(groupID, needUpdateTop)
	local partnerDataList = self:initNormalPartnerData(groupID, needUpdateTop)

	if partnerDataList and #partnerDataList == 0 then
		self.partnerNone.gameObject:SetActive(true)
	elseif not self.maxPartner and partnerDataList and partnerDataList[1] then
		self.maxPartner = partnerDataList[1].partnerInfo
	end

	local choiceYetPartner = xyd.models.guild:getCompetitionSpecialPartner()

	if choiceYetPartner and self.maxPartner and xyd.models.guild:getCompetitionSpecialTruePartnerInfo() then
		local truePartnerID = xyd.models.guild:getCompetitionSpecialTruePartnerInfo().truePartnerID
		self.clickPartnerID = truePartnerID
	end

	self.partnerMultiWrap_:setInfos(partnerDataList, {})
	self.partnerNone.gameObject:SetActive(false)

	if partnerDataList and #partnerDataList == 0 then
		self.partnerNone.gameObject:SetActive(true)
	end
end

function GuildCompetitionPartnerStudyWindow:onSelectGroup(group)
	if self.selectGroup_ == group then
		return
	end

	self.selectGroup_ = group

	self:iniPartnerData(group, false)
end

function GuildCompetitionPartnerStudyWindow:initNormalPartnerData(groupID, needUpdateTop)
	local partnerList = self:getPartners()
	local lvSortedList = partnerList[tostring(xyd.partnerSortType.isCollected) .. "_0"]
	local partnerDataList = {}
	self.power = 0

	for _, partnerId in ipairs(lvSortedList) do
		if partnerId ~= 0 and partnerId ~= 0 then
			local partnerInfo = self:getPartnerByPartnerId(tonumber(partnerId))
			partnerInfo.noClick = true
			local data = {
				isSelected = false,
				callbackFunc = handler(self, function (a, callbackPInfo, clickItem)
					self.clickPartnerID = callbackPInfo:getPartnerID()

					self:onClickheroIcon(callbackPInfo, clickItem)
				end),
				partnerInfo = partnerInfo
			}
			local pGroupID = xyd.tables.partnerTable:getGroup(partnerInfo.tableID)

			if groupID == 0 or pGroupID == groupID then
				local heroList = xyd.tables.partnerTable:getHeroList(partnerInfo:getTableID())

				if #heroList >= 3 and pGroupID ~= xyd.PartnerGroup.TIANYI then
					local lowTbaleId = heroList[1]
					local linkTenTableId = xyd.tables.partnerTable:getStar10(lowTbaleId)

					if linkTenTableId and linkTenTableId > 0 then
						table.insert(partnerDataList, data)
					end
				end
			end
		end
	end

	return partnerDataList
end

function GuildCompetitionPartnerStudyWindow:getPartners()
	local list = xyd.models.slot:getSortedPartners()

	return list
end

function GuildCompetitionPartnerStudyWindow:getPartnerByPartnerId(partnerId)
	local partnerInfo = xyd.models.slot:getPartner(tonumber(partnerId))

	return partnerInfo
end

function GuildCompetitionPartnerStudyWindow:onClickheroIcon(partnerInfo, clickItem)
	if self.lastItem then
		self.lastItem:setIsChoose(false)
	end

	self.lastItem = clickItem

	self:updateCard(partnerInfo)
end

function GuildCompetitionPartnerStudyWindow:getPartnerID()
	if self.clickPartnerID then
		return self.clickPartnerID
	end

	return 0
end

function GuildCompetitionPartnerStudyWindow:updateCard(partnerInfo)
	local tableID = partnerInfo:getTableID()
	local modelID = 0

	if partnerInfo:getSkinId() ~= 0 then
		modelID = xyd.tables.equipTable:getSkinModel(partnerInfo.skin_id)
	else
		modelID = xyd.tables.partnerTable:getModelID(tableID)
	end

	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)

	self.partnerCardLeft:setInfo(nil, partnerInfo)
	self.partnerCardLeft:setUIItemsVisible(true, true, true)
	self.partnerCardLeft:setNameVisible(true, true)

	local baseInfo = partnerInfo:getInfo()
	self.copyPartnerInfo = self:getCloneInfo(baseInfo)
	self.copyPartnerInfo.star = self.maxPartner:getStar()
	self.copyPartnerInfo.grade = self.maxPartner:getGrade()
	self.copyPartnerInfo.awake = self.maxPartner:getAwake()
	self.copyPartnerInfo.lev = self.maxPartner:getLevel()
	self.copyPartnerInfo.treasures = {}
	self.truePartnerInfo = {
		truePartnerID = partnerInfo:getPartnerID()
	}
	self.copyPartnerInfo.partnerID = xyd.models.guild:getCompetitionSpecialPartnerId()
	local job = partnerInfo:getJob()
	local jobEquips = xyd.cloneTable(xyd.tables.miscTable:split2num("partner_equip_job" .. job, "value", "|"))

	table.insert(jobEquips, 0)
	table.insert(jobEquips, 0)
	table.insert(jobEquips, baseInfo.equipments[7] or 0)

	self.copyPartnerInfo.equipments = jobEquips
	self.copyPartnerInfo.skill_index = 1
	local defaultPotentials = {
		0,
		0,
		0,
		0,
		0
	}

	for i = 11, self.maxPartner:getStar() do
		defaultPotentials[i - 10] = 2
	end

	self.copyPartnerInfo.potentials = defaultPotentials

	if self.copyPartnerInfo.star > 10 then
		for i = 1, 4 do
			self.copyPartnerInfo.ex_skills[i] = self.copyPartnerInfo.star - 10
		end
	end

	local heroList = xyd.tables.partnerTable:getHeroList(self.copyPartnerInfo.tableID)

	if #heroList == 3 then
		if self.copyPartnerInfo.star <= 5 then
			self.copyPartnerInfo.tableID = heroList[1]
		elseif self.copyPartnerInfo.star >= 10 then
			self.copyPartnerInfo.tableID = heroList[3]
		else
			self.copyPartnerInfo.tableID = heroList[2]
		end
	end

	self.truePartnerInfo.trueTableID = self.copyPartnerInfo.tableID

	self.partnerCardRight:setInfo(self.copyPartnerInfo)
	self.partnerCardRight:setUIItemsVisible(true, true, true)
	self.partnerCardRight:setNameVisible(true, true)

	local Partner = import("app.models.Partner")
	self.copyPartner = Partner.new()

	self.copyPartner:populate(self.copyPartnerInfo)
end

function GuildCompetitionPartnerStudyWindow:getCloneInfo(baseInfo)
	local copyPotentials = {
		0,
		0,
		0,
		0,
		0
	}

	if baseInfo.potentials then
		for i in ipairs(baseInfo.potentials) do
			if baseInfo.potentials[i] then
				copyPotentials[i] = baseInfo.potentials[i]
			end
		end
	end

	local star_origin = {}

	for i in ipairs(baseInfo.star_origin) do
		star_origin[i] = baseInfo.star_origin[i]
	end

	return {
		tableID = xyd.getCopy(baseInfo.tableID),
		star = xyd.getCopy(baseInfo.star),
		lev = xyd.getCopy(baseInfo.lev),
		partnerID = xyd.getCopy(baseInfo.partnerID),
		equipments = xyd.getCopy(baseInfo.equipments),
		grade = xyd.getCopy(baseInfo.grade),
		awake = xyd.getCopy(baseInfo.awake),
		lockFlags = xyd.getCopy(baseInfo.lockFlags),
		skin_id = xyd.getCopy(baseInfo.skin_id),
		lovePoint = xyd.getCopy(baseInfo.lovePoint),
		isVowed = xyd.getCopy(baseInfo.isVowed),
		power = xyd.getCopy(baseInfo.power),
		group = xyd.getCopy(baseInfo.group),
		potentials = copyPotentials,
		skill_index = xyd.getCopy(baseInfo.skill_index),
		ex_skills = {},
		wedding_date = xyd.getCopy(baseInfo.wedding_date),
		travel = xyd.getCopy(baseInfo.travel),
		potentials_bak = {},
		treasures = {},
		star_origin = star_origin
	}
end

function GuildCompetitionPartnerStudyWindow:initFirstEnter()
	local choiceYetPartner = xyd.models.guild:getCompetitionSpecialPartner()

	if choiceYetPartner and self.maxPartner then
		local truePartnerID = xyd.models.guild:getCompetitionSpecialTruePartnerInfo().truePartnerID
		self.clickPartnerID = truePartnerID
		self.truePartnerInfo = {
			truePartnerID = truePartnerID
		}
		local truePartner = xyd.models.slot:getPartner(truePartnerID)

		self.partnerCardLeft:setInfo(nil, truePartner)
		self.partnerCardLeft:setUIItemsVisible(true, true, true)
		self.partnerCardLeft:setNameVisible(true, true)

		local baseInfo = truePartner:getInfo()
		local oldStar = choiceYetPartner.star
		local newStar = self.maxPartner:getStar()
		self.copyPartnerInfo = self:getCloneInfo(baseInfo)
		self.copyPartnerInfo.star = self.maxPartner:getStar()
		self.copyPartnerInfo.grade = self.maxPartner:getGrade()
		self.copyPartnerInfo.awake = self.maxPartner:getAwake()
		self.copyPartnerInfo.lev = self.maxPartner:getLevel()
		self.copyPartnerInfo.skill_index = choiceYetPartner.skill_index
		self.copyPartnerInfo.equipments = xyd.cloneTable(choiceYetPartner.equipments)
		self.copyPartnerInfo.potentials = xyd.cloneTable(choiceYetPartner.potentials)
		self.copyPartnerInfo.partnerID = xyd.models.guild:getCompetitionSpecialPartnerId()
		self.copyPartnerInfo.equipments[7] = truePartner.equipments[7] or 0

		for i in pairs(self.copyPartnerInfo.potentials) do
			if i > 5 then
				self.copyPartnerInfo.potentials[i] = nil
			end
		end

		if newStar > 10 then
			for i = 1, 4 do
				self.copyPartnerInfo.ex_skills[i] = newStar - 10
			end

			if oldStar < 11 then
				self.copyPartnerInfo.potentials = {
					0,
					0,
					0,
					0,
					0
				}
			end

			for i = 11, 15 do
				if i <= newStar then
					if self.copyPartnerInfo.potentials[i - 10] == 0 then
						self.copyPartnerInfo.potentials[i - 10] = 2
					end
				else
					break
				end
			end
		end

		local heroList = xyd.tables.partnerTable:getHeroList(self.copyPartnerInfo.tableID)

		if #heroList == 3 then
			if self.copyPartnerInfo.star <= 5 then
				self.copyPartnerInfo.tableID = heroList[1]
			elseif self.copyPartnerInfo.star >= 10 then
				self.copyPartnerInfo.tableID = heroList[3]
			else
				self.copyPartnerInfo.tableID = heroList[2]
			end
		end

		self.truePartnerInfo.trueTableID = self.copyPartnerInfo.tableID

		self.partnerCardRight:setInfo(self.copyPartnerInfo)
		self.partnerCardRight:setUIItemsVisible(true, true, true)
		self.partnerCardRight:setNameVisible(true, true)

		local Partner = import("app.models.Partner")
		self.copyPartner = Partner.new()

		self.copyPartner:populate(self.copyPartnerInfo)
		self:saveInfo()
	end
end

return GuildCompetitionPartnerStudyWindow
