local SoulLandFightWindow = class("SoulLandFightWindow", import(".BaseWindow"))
local HeroIcon = import("app.components.HeroIcon")

function SoulLandFightWindow:ctor(name, params)
	SoulLandFightWindow.super.ctor(self, name, params)

	self.fortId = params.fortId
	local fortArr = xyd.tables.soulLandTable:getFortArr()
	local mapList = xyd.models.soulLand:getMapList()
	self.stageId = fortArr[self.fortId][mapList[self.fortId].max_stage + 1]
end

function SoulLandFightWindow:initWindow()
	self:getUIComponent()
	SoulLandFightWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function SoulLandFightWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.resGroup = self.groupAction:NodeByName("resGroup").gameObject
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.reViewBtn = self.upCon:NodeByName("reViewBtn").gameObject
	self.partNameLabel = self.upCon:ComponentByName("partNameLabel", typeof(UILabel))
	self.closeBtn = self.upCon:NodeByName("closeBtn").gameObject
	self.enemyCon = self.groupAction:NodeByName("enemyCon").gameObject
	self.enemyName = self.enemyCon:ComponentByName("enemyName", typeof(UILabel))
	self.enemyLayout = self.enemyCon:ComponentByName("enemyLayout", typeof(UILayout))
	self.awardCon = self.groupAction:NodeByName("awardCon").gameObject
	self.awardName = self.awardCon:ComponentByName("awardName", typeof(UILabel))
	self.awardLayout = self.awardCon:ComponentByName("awardLayout", typeof(UILayout))
	self.descCon = self.groupAction:NodeByName("descCon").gameObject
	self.descName = self.descCon:ComponentByName("descName", typeof(UILabel))
	self.descScorll = self.descCon:NodeByName("descScorll").gameObject
	self.descScorllUIScrollView = self.descCon:ComponentByName("descScorll", typeof(UIScrollView))
	self.descLabel = self.descScorll:ComponentByName("descLabel", typeof(UILabel))
	self.fightBtn = self.groupAction:NodeByName("fightBtn").gameObject
	self.fightBtnLabel = self.fightBtn:ComponentByName("fightBtnLabel", typeof(UILabel))
end

function SoulLandFightWindow:reSize()
end

function SoulLandFightWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.reViewBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("tower_video_window", {
			stage = self.stageId,
			state = xyd.CommonViewState.SOUL_LAND
		})
	end)
	UIEventListener.Get(self.fightBtn.gameObject).onClick = handler(self, self.onFight)
end

function SoulLandFightWindow:layout()
	local mapList = xyd.models.soulLand:getMapList()
	self.partNameLabel.text = __("SOUL_LAND_TEXT06", __("SOUL_LAND_AREA_TEXT0" .. self.fortId), mapList[self.fortId].max_stage + 1)
	self.enemyName.text = __("SOUL_LAND_TEXT07")
	self.awardName.text = __("SOUL_LAND_TEXT08")
	self.descName.text = __("SOUL_LAND_TEXT09")

	if xyd.Global.lang == "fr_fr" then
		self.descName.width = 150
		self.awardName.width = 150
		self.enemyName.width = 150
	end

	self.fightBtnLabel.text = __("SOUL_LAND_TEXT10")
	local godSkillId = xyd.tables.soulLandTable:getGodSkill(self.stageId)
	self.descLabel.text = xyd.tables.skillTable:getDesc(godSkillId)

	self.descScorllUIScrollView:ResetPosition()
	self:initTop()
	self:initEnemyCon()
	self:initAwardCon()
end

function SoulLandFightWindow:initEnemyCon()
	local battleId = xyd.tables.soulLandTable:getBattleId(self.stageId)
	local enemies = xyd.tables.battleTable:getMonsters(battleId)

	if #enemies > 0 then
		NGUITools.DestroyChildren(self.enemyLayout.gameObject.transform)

		for i = 1, #enemies do
			local tableID = enemies[i]
			local id = xyd.tables.monsterTable:getPartnerLink(tableID)
			local lev = xyd.tables.monsterTable:getShowLev(tableID)
			local icon = HeroIcon.new(self.enemyLayout.gameObject)

			icon:setInfo({
				noClick = true,
				tableID = id,
				lev = lev
			})

			local scale = 0.7962962962962963

			icon.go:SetLocalScale(scale, scale, scale)
		end
	end

	self.enemyLayout:Reposition()
end

function SoulLandFightWindow:initTop()
	local resCost = xyd.tables.miscTable:split2num("soul_land_ticket_init", "value", "#")
	self.windowTop = import("app.components.WindowTop").new(self.window_, self.name_, 50, false)
	local items = {
		{
			id = resCost[1],
			callback = function ()
				self:onPurchaseTicket()
			end
		}
	}

	self.windowTop:setItem(items)
	self.windowTop:hideBg()
end

function SoulLandFightWindow:onPurchaseTicket()
	xyd.WindowManager.get():openWindow("item_purchase_window", {
		exchange_id = xyd.ExchangeItem._2TO421
	})
end

function SoulLandFightWindow:onFight()
	local resCost = xyd.tables.miscTable:split2num("soul_land_ticket_init", "value", "#")

	if xyd.models.backpack:getItemNumByID(resCost[1]) <= 0 then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(resCost[1])))

		return
	end

	local fightParams = {
		showSkip = true,
		stageId = self.stageId,
		fortId = self.fortId,
		battleType = xyd.BattleType.SOUL_LAND,
		skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("soul_land_skip_report")) == 1, true, false),
		btnSkipCallback = function (flag)
			local valuedata = xyd.checkCondition(flag, 1, 0)

			xyd.db.misc:setValue({
				key = "soul_land_skip_report",
				value = valuedata
			})
		end
	}

	xyd.WindowManager:get():openWindow("battle_formation_window", fightParams)
end

function SoulLandFightWindow:initAwardCon()
	local awards = xyd.tables.soulLandTable:getAwardsShow(self.stageId)

	for i, award in pairs(awards) do
		local item = {
			show_has_num = false,
			isShowSelected = false,
			itemID = award[1],
			num = award[2],
			scale = Vector3(0.7962962962962963, 0.7962962962962963, 1),
			uiRoot = self.awardLayout.gameObject,
			soulEquipInfo = {}
		}
		local icon = xyd.getItemIcon(item)
	end

	self.awardLayout:Reposition()
end

return SoulLandFightWindow
