local TimeCloisterEncounterWindow = class("TimeCloisterEncounterWindow", import(".BaseWindow"))
local timeCloister = xyd.models.timeCloisterModel

function TimeCloisterEncounterWindow:ctor(name, params)
	TimeCloisterEncounterWindow.super.ctor(self, name, params)

	self.cardId = params.cardId
	local awardId = self.cardId
	local subCards = xyd.tables.timeCloisterCardTable:getSubCard(self.cardId)

	if subCards and #subCards > 0 then
		awardId = subCards[1]
	end

	self.awards = xyd.tables.timeCloisterCardTable:getAwards(awardId)
	self.battleId = xyd.tables.timeCloisterCardTable:getParams(self.cardId)[1]
	self.base = xyd.tables.timeCloisterCardTable:getBase(self.cardId)
	self.cloister = params.cloister
end

function TimeCloisterEncounterWindow:initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function TimeCloisterEncounterWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.nameText = self.groupAction:ComponentByName("nameText", typeof(UILabel))
	self.attrCon = self.groupAction:NodeByName("attrCon").gameObject
	self.attrText = self.attrCon:ComponentByName("attrText", typeof(UILabel))
	self.attrs = self.attrCon:NodeByName("attrs").gameObject
	self.attr1 = self.attrs:NodeByName("attr1").gameObject
	self.attrIcon1 = self.attr1:ComponentByName("attrIcon1", typeof(UISprite))
	self.attrLabel1 = self.attr1:ComponentByName("attrLabel1", typeof(UILabel))
	self.attr2 = self.attrs:NodeByName("attr2").gameObject
	self.attrIcon2 = self.attr2:ComponentByName("attrIcon2", typeof(UISprite))
	self.attrLabel2 = self.attr2:ComponentByName("attrLabel2", typeof(UILabel))
	self.attr3 = self.attrs:NodeByName("attr3").gameObject
	self.attrIcon3 = self.attr3:ComponentByName("attrIcon3", typeof(UISprite))
	self.attrLabel3 = self.attr3:ComponentByName("attrLabel3", typeof(UILabel))
	self.enemyCon = self.groupAction:NodeByName("enemyCon").gameObject
	self.enemyText = self.enemyCon:ComponentByName("enemyText", typeof(UILabel))
	self.enemyLayout = self.enemyCon:ComponentByName("enemyLayout", typeof(UILayout))
	self.awardCon = self.groupAction:NodeByName("awardCon").gameObject
	self.awardText = self.awardCon:ComponentByName("awardText", typeof(UILabel))
	self.awardLayout = self.awardCon:ComponentByName("awardLayout", typeof(UILayout))
	self.fightBtn = self.groupAction:NodeByName("fightBtn").gameObject
	self.fightLabel = self.fightBtn:ComponentByName("fightLabel", typeof(UILabel))
end

function TimeCloisterEncounterWindow:layout()
	self.attrText.text = __("TIME_CLOISTER_TEXT63")
	self.enemyText.text = __("TIME_CLOISTER_TEXT64")
	self.awardText.text = __("AWARD3")
	self.fightLabel.text = __("FIGHT3")
	self.nameText.text = xyd.tables.timeCloisterCardTextTable:getName(self.cardId)

	for i = 1, 3 do
		if self.base[i] then
			self["attrLabel" .. i].text = self.base[i]
		else
			self["attrLabel" .. i].text = "0"
		end
	end

	local monsters = xyd.tables.battleTable:getMonsters(self.battleId)

	for i = 1, #monsters do
		local tableID = monsters[i]
		local id = xyd.tables.monsterTable:getPartnerLink(tableID)
		local itemID = xyd.tables.monsterTable:getSkin(tableID)
		local lev = xyd.tables.monsterTable:getShowLev(tableID)
		local params = {
			is_monster = true,
			noClick = true,
			uiRoot = self.enemyLayout.gameObject,
			itemID = id,
			lev = lev
		}

		if itemID and itemID > 0 then
			params.skin_id = itemID
		end

		local icon = xyd.getItemIcon(params)

		icon:setScale(0.7222222222222222)
	end

	self.enemyLayout:Reposition()

	for i, data in pairs(self.awards) do
		xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7962962962962963,
			uiRoot = self.awardLayout.gameObject,
			itemID = data[1],
			num = data[2]
		})
	end

	self.awardLayout:Reposition()
end

function TimeCloisterEncounterWindow:registerEvent()
	UIEventListener.Get(self.fightBtn.gameObject).onClick = handler(self, function ()
		local fightParams = {
			showSkip = true,
			battleID = self.battleId,
			battleType = xyd.BattleType.TIME_CLOISTER_EXTRA,
			eventId = self.cardId,
			cloister = self.cloister,
			skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("Time_cloister_encounter_skip_report")) == 1, true, false),
			btnSkipCallback = function (flag)
				local valuedata = xyd.checkCondition(flag, 1, 0)

				xyd.db.misc:setValue({
					key = "Time_cloister_encounter_skip_report",
					value = valuedata
				})
			end
		}

		if self.cloister == xyd.TimeCloisterMissionType.TWO then
			local techInfo = timeCloister:getTechInfoByCloister(self.cloister)

			if techInfo[3] and techInfo[3][xyd.TimeCloisterSpecialTecId.PARTNER_3_TEC] then
				local partnerTecLev = techInfo[3][xyd.TimeCloisterSpecialTecId.PARTNER_3_TEC].curLv

				if partnerTecLev > 0 then
					fightParams.cloisterExtraPartnerId = "-" .. self.cloister
				end
			end
		end

		xyd.WindowManager:get():openWindow("battle_formation_window", fightParams)
	end)
end

return TimeCloisterEncounterWindow
