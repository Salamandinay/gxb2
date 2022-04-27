local ArcticExpeditionMainWindow = class("ArcticExpeditionMainWindow", import(".BaseWindow"))
local BaseComponent = import("app.components.BaseComponent")
local WindowTop = import("app.components.WindowTop")
local CellItem = class("CellItem", import("app.components.CopyComponent"))
local cjson = require("cjson")
local CountDown = import("app.components.CountDown")
local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)

function CellItem:ctor(go, parent)
	self.parent_ = parent
	self.showBtnGroup_ = false

	CellItem.super.ctor(self, go)
end

function CellItem:initUI()
	CellItem.super.initUI(self)
	self:getComponent()

	UIEventListener.Get(self.go).onClick = function ()
		self.showBtnGroup_ = not self.showBtnGroup_

		self:updateBtnState()
	end

	UIEventListener.Get(self.go).onDrag = function (go, delta)
		self.parent_:updateMiniMapPos()
	end

	UIEventListener.Get(self.btnEnter_).onClick = function ()
		self.parent_.needOpenCell_ = true

		if not self.parent_.activityData_:reqCellInfo(self.cellId_) then
			local cellType = xyd.tables.arcticExpeditionCellsTable:getCellType(self.cellId_)
			local functionType = xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(cellType)

			if functionType == 4 then
				xyd.WindowManager.get():openWindow("arctic_expedition_boss_info_window", {
					cell_id = self.cellId_
				})
			else
				xyd.WindowManager.get():openWindow("arctic_expedition_cell_window", {
					cell_id = self.cellId_
				})
			end

			local win = xyd.WindowManager.get():getWindow("exskill_guide_window")

			if win and (win:getCurIndex() == 19 or win:getCurIndex() == 20) then
				self.parent_:jumpToOtherCell()
			end

			self.parent_.needOpenCell_ = false
		end
	end

	UIEventListener.Get(self.btnAssemble_).onClick = function ()
		if self.parent_.activityData_:getEndTime() - xyd.getServerTime() <= xyd.DAY_TIME or -self.parent_.activityData_:startTime() + xyd.getServerTime() < xyd.DAY_TIME then
			xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_64"))

			return
		end

		if self.rallyPlayerID_ and self.rallyPlayerID_ == xyd.models.selfPlayer.playerID_ then
			xyd.alertYesNo(__("ARCTIC_EXPEDITION_TEXT_49"), function (yes_no)
				if yes_no then
					self.parent_.activityData_:reqCellRally(self.cellId_)
				end
			end)
		elseif self.rallyPlayerID_ then
			xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_53"))
		else
			self.parent_.tempAssembleCell = self.cellId_

			self.parent_.activityData_:reqRankList(self.parent_.activityData_:getSelfGroup(), 1)
		end
	end
end

function CellItem:updateBtnState()
	if not self.showBtnGroup_ then
		self.btnGroup_:SetActive(false)
		self.hpProgress_.gameObject:SetActive(false)
		self.selectGroup_:SetActive(false)
	else
		self.btnGroup_:SetActive(true)
		self.selectGroup_:SetActive(true)
		self.hpProgress_.gameObject:SetActive(true)
		self.parent_:updateCellShowState(self.cellId_)
		self:showEffect()
	end

	local cellType = xyd.tables.arcticExpeditionCellsTable:getCellType(self.cellId_)
	local functionType = xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(cellType)

	if functionType == 5 then
		self.btnAssemble_:SetActive(false)
	end
end

function CellItem:showEffect()
	self.selectImgGroup_.transform:SetLocalScale(1.05, 1.05, 1)

	local seq = self:getSequence(nil, true)

	local function setter1(value)
		self.maskImg.alpha = value
	end

	seq:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 0.8, 0.2))
	seq:Insert(0.2, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0.8, 1, 0.13333333333333333))
	seq:Insert(0, self.selectImgGroup_.transform:DOScale(Vector3(0.95, 0.95, 1), 0.2))
	seq:Insert(0.2, self.selectImgGroup_.transform:DOScale(Vector3(1, 1, 1), 0.13333333333333333))
end

function CellItem:hideBtnGroup()
	self.showBtnGroup_ = false

	self:updateBtnState()
	self:updateHpValue()
end

function CellItem:getComponent()
	self.bgImg_ = self.go:GetComponent(typeof(UISprite))
	self.cellImg_ = self.go:ComponentByName("cellImg", typeof(UISprite))
	self.effectRoot_ = self.go:NodeByName("effectRoot").gameObject
	self.stateImg_ = self.go:ComponentByName("stateImg", typeof(UISprite))
	self.btnGroup_ = self.go:NodeByName("btnGroup").gameObject
	self.btnEnter_ = self.go:NodeByName("btnGroup/btnEnter").gameObject
	self.hpProgress_ = self.go:ComponentByName("nameGroup", typeof(UIProgressBar))
	self.nameText_ = self.go:ComponentByName("nameGroup/nameText", typeof(UILabel))
	self.cellPosText_ = self.go:ComponentByName("nameGroup/cellPos", typeof(UILabel))
	self.selectGroup_ = self.go:NodeByName("selectGroup").gameObject
	self.selectImgGroup_ = self.selectGroup_:NodeByName("selectImg")
	self.maskImg = self.selectGroup_:ComponentByName("e:image", typeof(UISprite))
	self.btnGroup_ = self.go:NodeByName("btnGroup")
	self.btnEnter_ = self.btnGroup_:NodeByName("btnEnter").gameObject
	self.btnEnterLabel_ = self.btnGroup_:ComponentByName("btnEnter/label", typeof(UILabel))
	self.btnAssemble_ = self.btnGroup_:NodeByName("btnAssemble").gameObject
	self.btnAssembleLabel_ = self.btnGroup_:ComponentByName("btnAssemble/label", typeof(UILabel))
	self.btnAssembleImg_ = self.btnAssemble_:GetComponent(typeof(UISprite))
	self.rallyNode_ = self.go:NodeByName("rallyNode").gameObject
	self.rallyEffectNode_ = self.rallyNode_:NodeByName("effectRoot").gameObject
	self.rallyPlayerNode_ = self.rallyNode_:NodeByName("rallyBg").gameObject
	self.rallyPlayerIcon_ = self.rallyNode_:ComponentByName("rallyBg/playerIcon", typeof(UISprite))
	self.btnEnterLabel_.text = __("ARCTIC_EXPEDITION_TEXT_67")
end

function CellItem:setInfo(info, cellId)
	self.eraID_ = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION):getEra()
	self.cellId_ = cellId
	self.info_ = info or {}
	self.cellType_ = xyd.tables.arcticExpeditionCellsTable:getCellType(self.cellId_)
	self.cellGroup_ = self.info_.group or xyd.tables.arcticExpeditionCellsTable:getCellGroup(self.cellId_)
	self.cellPos = xyd.tables.arcticExpeditionCellsTable:getCellPos(self.cellId_)
	self.nameText_.text = xyd.tables.arcticExpeditionCellsTypeTable:getCellName(self.cellType_)
	self.cellPosText_.text = "(" .. self.cellPos[1] .. "," .. self.cellPos[2] .. ")"

	if not self.cellType_ or self.cellType_ <= 1 then
		self.go:SetActive(false)
	end

	local imgName = self.cellGroup_

	xyd.setUISpriteAsync(self.bgImg_, nil, "arctic_expedition_cell_img_" .. imgName)

	local effectNames = xyd.tables.arcticExpeditionCellsTypeTable:getBuildingEffect(self.cellType_)

	if effectNames and #effectNames > 0 then
		self.effectRoot_:SetActive(true)

		local effectName = effectNames[self.eraID_]

		if not self.buildingEffect_ then
			self.buildingEffect_ = xyd.Spine.new(self.effectRoot_)

			if effectName[1] and tostring(effectName[1]) then
				self.buildingEffect_:setInfo(effectName[1], function ()
					self.buildingEffect_:play(effectName[2], -1, 1)

					if effectName[1] == "fx_ept_building3" then
						self.buildingEffect_:SetLocalPosition(-40, -220, 0)
					end
				end)
			end
		elseif effectName[1] and tostring(effectName[1]) then
			self.buildingEffect_:play(effectName[2], -1, 1)

			if effectName[1] == "fx_ept_building3" then
				self.buildingEffect_:SetLocalPosition(-40, -220, 0)
			end
		end
	end

	self:checkRallyLabel()
	self:refreshState()
	self:updateHpValue()
end

function CellItem:checkRallyLabel()
	local rallyInfo = self.info_["rally" .. self.parent_.activityData_:getSelfGroup()]

	if rallyInfo and rallyInfo.end_time and rallyInfo.end_time - xyd.getServerTime() > 0 then
		local player_id = rallyInfo.player_id
		self.rallyPlayerID_ = player_id

		xyd.setUISpriteAsync(self.btnAssembleImg_, nil, "white_btn_65_65")
		self.btnAssembleLabel_.transform:X(0)

		if xyd.Global.lang == "fr_fr" then
			self.btnAssembleLabel_.width = 176
			self.btnAssembleLabel_.height = 42
			self.btnAssembleImg_.width = 190
			self.btnAssembleImg_.height = 56

			self.btnAssemble_.transform:X(180)
		elseif xyd.Global.lang == "en_en" then
			self.btnAssembleLabel_.width = 120
			self.btnAssembleLabel_.height = 42
			self.btnAssembleImg_.width = 140
			self.btnAssembleImg_.height = 56

			self.btnAssemble_.transform:X(156)
		elseif xyd.Global.lang == "de_de" then
			self.btnAssembleLabel_.width = 176
			self.btnAssembleLabel_.height = 42
			self.btnAssembleImg_.width = 190
			self.btnAssembleImg_.height = 56

			self.btnAssemble_.transform:X(180)
		end

		self.btnAssembleLabel_.text = __("ARCTIC_EXPEDITION_TEXT_45")

		self:waitForTime(rallyInfo.end_time - xyd.getServerTime(), function ()
			xyd.setUISpriteAsync(self.btnAssembleImg_, nil, "arctic_expedition_btn_together")
			self.btnAssembleLabel_.transform:X(10)

			self.btnAssembleLabel_.text = __("ARCTIC_EXPEDITION_TEXT_44")

			if xyd.Global.lang == "fr_fr" then
				self.btnAssembleLabel_.width = 176
				self.btnAssembleLabel_.height = 42
				self.btnAssembleImg_.width = 190
				self.btnAssembleImg_.height = 56

				self.btnAssemble_.transform:X(180)
			elseif xyd.Global.lang == "en_en" then
				self.btnAssembleLabel_.width = 100
				self.btnAssembleLabel_.height = 42
				self.btnAssembleImg_.width = 140
				self.btnAssembleImg_.height = 56

				self.btnAssemble_.transform:X(156)
			elseif xyd.Global.lang == "de_de" then
				self.btnAssembleLabel_.width = 176
				self.btnAssembleLabel_.height = 42
				self.btnAssembleImg_.width = 190
				self.btnAssembleImg_.height = 56

				self.btnAssemble_.transform:X(180)
			end
		end)
	else
		xyd.setUISpriteAsync(self.btnAssembleImg_, nil, "arctic_expedition_btn_together")
		self.btnAssembleLabel_.transform:X(10)

		self.btnAssembleLabel_.text = __("ARCTIC_EXPEDITION_TEXT_44")

		if xyd.Global.lang == "fr_fr" then
			self.btnAssembleLabel_.width = 176
			self.btnAssembleLabel_.height = 42
			self.btnAssembleImg_.width = 190
			self.btnAssembleImg_.height = 56

			self.btnAssemble_.transform:X(180)
		elseif xyd.Global.lang == "en_en" then
			self.btnAssembleLabel_.width = 100
			self.btnAssembleLabel_.height = 42
			self.btnAssembleImg_.width = 140
			self.btnAssembleImg_.height = 56

			self.btnAssemble_.transform:X(156)
		elseif xyd.Global.lang == "de_de" then
			self.btnAssembleLabel_.width = 176
			self.btnAssembleLabel_.height = 42
			self.btnAssembleImg_.width = 190
			self.btnAssembleImg_.height = 56

			self.btnAssemble_.transform:X(180)
		end
	end
end

function CellItem:showRallyInfo(rallyInfo)
	self.rallyNode_:SetActive(true)
	self:checkRallyLabel()

	local player_id = rallyInfo.player_id
	self.rallyPlayerID_ = player_id
	self.rallyEndTime_ = rallyInfo.end_time
	local avatar_id = rallyInfo.avatar_id
	local group = self.parent_.activityData_:getSelfGroup()

	if not self.rallyEffect_ then
		self.rallyEffect_ = xyd.Spine.new(self.rallyEffectNode_)

		self.rallyEffect_:setInfo("fx_ept_gather", function ()
			self.rallyEffect_:play("texiao01", 0, 1)
		end)
	else
		self.rallyEffect_:play("texiao01", 0, 1)
	end

	local iconName = ""
	local iconType = xyd.tables.itemTable:getType(avatar_id)

	if iconType == xyd.ItemType.HERO_DEBRIS then
		local partnerCost = xyd.tables.itemTable:partnerCost(avatar_id)
		iconName = xyd.tables.partnerTable:getAvatar(partnerCost[1])
	elseif iconType == xyd.ItemType.HERO then
		iconName = xyd.tables.partnerTable:getAvatar(avatar_id)
	elseif iconType == xyd.ItemType.SKIN then
		iconName = xyd.tables.equipTable:getSkinAvatar(avatar_id)
	else
		iconName = xyd.tables.itemTable:getIcon(avatar_id)
	end

	xyd.setUISpriteAsync(self.rallyPlayerIcon_, nil, iconName)

	local function seqFuction()
		local seq = self:getSequence(nil)

		seq:Insert(0, self.rallyPlayerNode_.transform:DOLocalMove(Vector3(0, 14.6, 0), 0.26666666666666666))
		seq:Insert(0.26666666666666666, self.rallyPlayerNode_.transform:DOLocalMove(Vector3(0, 18.6, 0), 0.26666666666666666))
		seq:Insert(0.5333333333333333, self.rallyPlayerNode_.transform:DOLocalMove(Vector3(0, 22.6, 0), 0.13333333333333333))
		seq:Insert(0.6666666666666666, self.rallyPlayerNode_.transform:DOLocalMove(Vector3(0, 14.6, 0), 0.26666666666666666))
		seq:Insert(0.9333333333333333, self.rallyPlayerNode_.transform:DOLocalMove(Vector3(0, 8.6, 0), 0.26666666666666666))
		seq:Insert(1.2, self.rallyPlayerNode_.transform:DOLocalMove(Vector3(0, 0, 0), 0.13333333333333333))
	end

	if not self.rallyTimer1_ then
		self.rallyTimer1_ = self:getTimer(seqFuction, 1.3333333333333333, -1)
	end

	self.rallyTimer1_:Start()
	self:waitForTime(rallyInfo.end_time - xyd.getServerTime(), function ()
		self:hideRallyInfo()
	end)
end

function CellItem:hideRallyInfo()
	self.rallyNode_:SetActive(false)

	if self.rallyTimer1_ then
		self.rallyTimer1_:Stop()
	end

	self.rallyPlayerID_ = nil

	self:checkRallyLabel()
end

function CellItem:updateHpValue()
	local num = self.info_.num
	local totalNum = 0

	if self.cellGroup_ == 4 then
		totalNum = xyd.tables.arcticExpeditionCellsTypeTable:getBattleCount(self.cellType_)
	else
		totalNum = xyd.tables.arcticExpeditionCellsTypeTable:getBattleCount2(self.cellType_)
	end

	if xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(self.cellType_) == 5 then
		self.hpProgress_.value = 1
	elseif num then
		self.hpProgress_.value = num / totalNum
	end
end

function CellItem:refreshState()
	local isSafe = self.info_.safe
	local safe_time = self.info_.safe_time
	local fierceFighting = false
	local countNum = 0

	for i = 1, 3 do
		local fightTime = self.info_["fight_time_" .. i]

		if fightTime and xyd.getServerTime() - fightTime < 3600 then
			countNum = countNum + 1
		end
	end

	if countNum >= 2 then
		fierceFighting = true
	end

	if isSafe and isSafe >= 1 and xyd.getServerTime() < safe_time + xyd.tables.arcticExpeditionCellsTypeTable:getTruceTime(self.cellType_) then
		self.stateImg_.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.stateImg_, nil, "arctic_expedition_cell_state_icon_1", nil, , true)
		self:waitForTime(safe_time + xyd.tables.arcticExpeditionCellsTypeTable:getTruceTime(self.cellType_) - xyd.getServerTime(), function ()
			self:refreshState()
		end)
	elseif fierceFighting then
		self.stateImg_.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.stateImg_, nil, "arctic_expedition_cell_state_icon_2", nil, , true)
	else
		self.stateImg_.gameObject:SetActive(false)
	end
end

function ArcticExpeditionMainWindow:ctor(name, params)
	ArcticExpeditionMainWindow.super.ctor(self, name, params)

	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)

	self.activityData_:getArcPartnerInfos()

	self.is_first = true

	self.activityData_:reqTimeMissionInfo()
	self.activityData_:reqRankList(self.activityData_:getSelfGroup())

	self.cellItemList_ = {}
	self.cellGroupList_ = {}
	self.unlockCellList_ = {}
	self.is_first = true
end

function ArcticExpeditionMainWindow:initWindow()
	self:getUIComponent()
	self:register()
	self:updateTimeGroup()
	self:initLayout()
	self:updateResEnergyNum()
	self:reqChatMsg()
	self:updateSelfScore()

	self.updateTimer_ = self:getTimer(function ()
		self.activityData_:reqTimeMissionInfo()
	end, 720, -1)
end

function ArcticExpeditionMainWindow:register()
	UIEventListener.Get(self.backMap_.gameObject).onDrag = function (go, delta)
		self:updateMiniMap()
	end

	UIEventListener.Get(self.backMap_.gameObject).onDrag = function (go, delta)
		self:updateMiniMapPos()
	end

	function self.mapScrollView.onDragMoving()
		self:updateMiniMapPos()
	end

	UIEventListener.Get(self.resEnergyPlus).onClick = function ()
		if self.activityData_:getEndTime() - xyd.getServerTime() <= xyd.DAY_TIME then
			xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_63"))
		else
			xyd.WindowManager.get():openWindow("arctic_expedition_buy_window")
		end
	end

	UIEventListener.Get(self.btnState_).onClick = function ()
		if not self.activityData_:reqTimeMissionInfo() then
			xyd.WindowManager.get():openWindow("arctic_expedition_time_window", {})
		else
			self.needOpenTime_ = true
		end
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
		if not self.activityData_:reqTimeMissionInfo() then
			xyd.WindowManager.get():openWindow("arctic_expedition_award_window", {})
		else
			self.needOpenAward_ = true
		end
	end

	UIEventListener.Get(self.btnRank).onClick = function ()
		if not self.activityData_:reqRankList(0) then
			xyd.WindowManager.get():openWindow("arctic_expedition_rank_window", {})
		else
			self.openRankWindow_ = true
		end
	end

	UIEventListener.Get(self.btnMission).onClick = function ()
		self.activityData_.missionRed_ = false

		xyd.WindowManager.get():openWindow("arctic_expedition_mission_window", {})
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ARCTIC_EXPEDITION_HELP_MAIN"
		})
	end

	UIEventListener.Get(self.chatBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("arctic_chat_window")
	end

	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_GET_MAP_INFO, handler(self, self.refreshMap))
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_BATTLE, handler(self, self.updateCellAfterBattle))
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_CELL_INFO, handler(self, self.onGetCellInfo))
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_RALLY, handler(self, self.onRallyInfo))
	self.eventProxy_:addEventListener(xyd.event.BOSS_BUY, function ()
		xyd.alertTips(__("PURCHASE_SUCCESS"))
		self:updateResEnergyNum()
	end)
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_GET_RANK_LIST, function (event)
		if self.tempAssembleCell then
			local self_rank = event.data.self_rank

			if not self_rank or self_rank > 50 then
				xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_48"))

				self.tempAssembleCell = nil

				return
			elseif not self.activityData_:checkRallyTime() then
				xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_51"))

				self.tempAssembleCell = nil

				return
			elseif xyd.isSameDay(self.activityData_.detail.last_rally, xyd.getServerTime()) then
				xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_52"))

				self.tempAssembleCell = nil

				return
			else
				local cost = xyd.tables.miscTable:split2num("expedition_gather_price", "value", "#")

				xyd.alertYesNo(__("ARCTIC_EXPEDITION_TEXT_50", cost[2]), function (yes_no)
					if yes_no and self.tempAssembleCell and tonumber(self.tempAssembleCell) > 0 then
						self.activityData_:reqCellRally(self.tempAssembleCell)

						self.tempAssembleCell = nil
					end
				end)
			end
		elseif self.openRankWindow_ then
			local win = xyd.WindowManager.get():getWindow("arctic_expedition_rank_window")
			local win2 = xyd.WindowManager.get():getWindow("arctic_expedition_award_window")

			if not win and not win2 then
				xyd.WindowManager.get():openWindow("arctic_expedition_rank_window", {})
			end

			self.openRankWindow_ = false
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_GET_MISSION, handler(self, self.onGetTimeMissionInfo))
	self.eventProxy_:addEventListener(xyd.event.SYSTEM_REFRESH, handler(self, self.onDailyRefresh))
	self.eventProxy_:addEventListener(xyd.event.EXPEDITION_CHAT_BACK, handler(self, self.onChatBack))
	self.eventProxy_:addEventListener(xyd.event.SYS_BROADCAST, handler(self, self.onCellGroupChange))
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_CHAT_MSG, handler(self, self.onChatBack))
end

function ArcticExpeditionMainWindow:onDailyRefresh()
	if self.activityData_:checkWillOpenNextStage() then
		xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_54"))
		xyd.WindowManager.get():closeAllWindows(nil, true)
	end
end

function ArcticExpeditionMainWindow:onGetTimeMissionInfo()
	self:updateGroupScore()

	if self.needOpenTime_ then
		xyd.WindowManager.get():openWindow("arctic_expedition_time_window", {})

		self.needOpenTime_ = false
	elseif self.needOpenAward_ then
		xyd.WindowManager.get():openWindow("arctic_expedition_award_window", {})

		self.needOpenAward_ = false
	end
end

function ArcticExpeditionMainWindow:jumpToOtherCell()
	local selfGroup = self.activityData_:getSelfGroup()
	local ids = xyd.tables.arcticExpeditionCellsTable:getIds()
	local targetCell = 36

	for index, cellId in ipairs(ids) do
		local cellInfo = self.activityData_:getCellInfo(cellId)
		local cellGroup = cellInfo.group
		local canFight = self:checkCanFightOther(cellId)
		local type = xyd.tables.arcticExpeditionCellsTable:getCellType(cellId)
		local functionID = xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(type)
		local pos = xyd.tables.arcticExpeditionCellsTable:getCellPos(cellId)

		if pos[1] >= 4 and pos[1] <= 10 and pos[2] <= 10 and pos[2] >= 2 and canFight and cellGroup ~= selfGroup and functionID < 4 and (not cellInfo.safe or cellInfo.safe < 1 or not cellInfo.safe_time or cellInfo.safe_time + xyd.tables.arcticExpeditionCellsTypeTable:getTruceTime(type) - xyd.getServerTime()) then
			targetCell = cellId

			break
		end
	end

	self:jumpToCellPos(targetCell, true)
end

function ArcticExpeditionMainWindow:checkCanFightOther(cell_id)
	local cellList = {}
	local cellPos = xyd.tables.arcticExpeditionCellsTable:getCellPos(cell_id)

	xyd.tables.arcticExpeditionCellsTable:getCellAroud1(cellPos, cellList)

	for key, value in pairs(cellList) do
		if value == 1 then
			local info = self.activityData_:getCellInfo(tonumber(key))

			if info and info.group == self.activityData_:getSelfGroup() then
				return true
			end
		end
	end

	return false
end

function ArcticExpeditionMainWindow:onGetCellInfo(event)
	if self.needUpdateRallyInfo_ then
		self:checkShowRallyList()

		self.needUpdateRallyInfo_ = nil
	elseif self.needOpenCell_ then
		local cell_info = event.data
		local cell_id = cell_info.table_id
		local cellType = xyd.tables.arcticExpeditionCellsTable:getCellType(cell_id)
		local functionType = xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(cellType)

		if functionType == 4 then
			xyd.WindowManager.get():openWindow("arctic_expedition_boss_info_window", {
				cell_id = cell_id
			})
		else
			xyd.WindowManager.get():openWindow("arctic_expedition_cell_window", {
				cell_id = cell_id
			})
		end

		local win = xyd.WindowManager.get():getWindow("exskill_guide_window")

		if win and (win:getCurIndex() == 19 or win:getCurIndex() == 20) then
			self:jumpToOtherCell()
		end

		self.needOpenCell_ = false
	end

	local cell_info = event.data

	self.cellItemList_[cell_info.table_id]:setInfo(cell_info, cell_info.table_id)
	self:checkShowRallyList()
end

function ArcticExpeditionMainWindow:updateEnterPos()
	local lastPos = xyd.db.misc:getValue("arctic_expedition_last_pos")
	local guideValue = xyd.db.misc:getValue("arctic_expedition_guide")

	if not lastPos or not guideValue then
		lastPos = self:getGroupCenterPos()
	else
		lastPos = cjson.decode(lastPos)
	end

	local eraID = self.activityData_:getEra()

	if not guideValue or tonumber(guideValue) <= 0 then
		local spring = self.mapScrollView.gameObject:AddComponent(typeof(SpringPanel))

		spring.Begin(spring.gameObject, Vector3(lastPos.x, lastPos.y, 0), 8)
		self:waitForFrame(8, function ()
			self:updateMiniMapPos()
		end)
		xyd.WindowManager:get():openWindow("exskill_guide_window", {
			wnd = self,
			table = xyd.tables.timeCloisterGuideTable,
			guide_type = xyd.GuideType.ARCTIC_EXPEDITION_1
		})
		xyd.db.misc:setValue({
			value = "1",
			key = "arctic_expedition_guide"
		})
	elseif eraID == 2 and tonumber(guideValue) < 2 then
		self:showGuideEra2()
	elseif eraID == 3 and tonumber(guideValue) < 3 then
		self:showGuideEra3()
	else
		local spring = self.mapScrollView.gameObject:AddComponent(typeof(SpringPanel))

		spring.Begin(spring.gameObject, Vector3(lastPos.x, lastPos.y, 0), 8)
		self:waitForFrame(8, function ()
			self:updateMiniMapPos()
		end)
	end
end

function ArcticExpeditionMainWindow:showGuideEra2()
	local ids = xyd.tables.arcticExpeditionCellsTable:getIds()
	local targetCell = 1

	for index, cellId in ipairs(ids) do
		local type = xyd.tables.arcticExpeditionCellsTable:getCellType(cellId)
		local functionID = xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(type)

		if functionID == 4 then
			targetCell = cellId

			break
		end
	end

	self:jumpToCellPos(targetCell, true)
	self:waitForFrame(10, function ()
		xyd.WindowManager:get():openWindow("exskill_guide_window", {
			wnd = self,
			table = xyd.tables.timeCloisterGuideTable,
			guide_type = xyd.GuideType.ARCTIC_EXPEDITION_3
		})
		xyd.db.misc:setValue({
			value = "2",
			key = "arctic_expedition_guide"
		})
	end)
end

function ArcticExpeditionMainWindow:showGuideEra3()
	local ids = xyd.tables.arcticExpeditionCellsTable:getIds()
	local targetCell = 1

	for index, cellId in ipairs(ids) do
		local type = xyd.tables.arcticExpeditionCellsTable:getCellType(cellId)
		local functionID = xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(type)

		if functionID == 4 then
			targetCell = cellId

			break
		end
	end

	self:jumpToCellPos(targetCell, true)

	local cellList = {}
	local cellPos = xyd.tables.arcticExpeditionCellsTable:getCellPos(targetCell)

	xyd.tables.arcticExpeditionCellsTable:getCellAroud1(cellPos, cellList)

	local otherCell = nil

	for key, value in pairs(cellList) do
		if value == 1 then
			local info = self.activityData_:getCellInfo(tonumber(key))

			if info and info.group ~= self.activityData_:getSelfGroup() then
				otherCell = tonumber(key)

				break
			end
		end
	end

	if not otherCell then
		for key, value in pairs(cellList) do
			if value == 1 then
				otherCell = tonumber(key)

				break
			end
		end
	end

	self.otherCell = self.cellItemList_[otherCell]
	self.otherCellBg = self.otherCell.go
	self.otherCellBtn = self.otherCell.btnEnter_

	self:waitForFrame(10, function ()
		xyd.WindowManager:get():openWindow("exskill_guide_window", {
			wnd = self,
			table = xyd.tables.timeCloisterGuideTable,
			guide_type = xyd.GuideType.ARCTIC_EXPEDITION_4
		})
		xyd.db.misc:setValue({
			value = "3",
			key = "arctic_expedition_guide"
		})
	end)
end

function ArcticExpeditionMainWindow:jumpToCellPos(cell_id, needChoose)
	local spring = self.mapScrollView.gameObject:GetComponent(typeof(SpringPanel))
	spring = spring or self.mapScrollView.gameObject:AddComponent(typeof(SpringPanel))
	local pos = xyd.tables.arcticExpeditionCellsTable:getCellPos(cell_id)
	local realHeight = xyd.Global.getRealHeight()
	local realWidth = xyd.Global.getRealWidth()
	local maxWidth = 2048 - realWidth
	local maxHeight = 2048 - realHeight + 236

	spring.Begin(spring.gameObject, Vector3(-(maxWidth / 13) * pos[1], maxHeight / 13 * pos[2], 0), 8)

	self.targetCell_ = self.cellItemList_[cell_id]
	self.targetBg = self.targetCell_.go
	self.targetEnterBtn = self.targetCell_.btnEnter_

	if needChoose then
		self.cellItemList_[cell_id].showBtnGroup_ = true

		self.cellItemList_[cell_id]:updateBtnState()
	end

	self:waitForFrame(8, function ()
		self:updateMiniMapPos()
	end)
end

function ArcticExpeditionMainWindow:getGroupCenterPos()
	local selfGroup = self.activityData_:getSelfGroup()
	local ids = xyd.tables.arcticExpeditionCellsTable:getIds()

	for index, cellId in ipairs(ids) do
		local type = xyd.tables.arcticExpeditionCellsTable:getCellType(cellId)
		local functionID = xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(type)

		if functionID == 5 and self.activityData_:getSelfGroup() == self.activityData_:getCellInfo(cellId).group then
			self.centerCell_ = self.cellItemList_[cellId]
			self.centerCellBg = self.cellItemList_[cellId].go
			self.centerEnterBtn = self.centerCell_.btnEnter_
			local pos = xyd.tables.arcticExpeditionCellsTable:getCellPos(cellId)
			local realHeight = xyd.Global.getRealHeight()
			local realWidth = xyd.Global.getRealWidth()
			local maxWidth = 2048 - realWidth
			local maxHeight = 2048 - realHeight + 236
			self.cellItemList_[cellId].showBtnGroup_ = true

			self.cellItemList_[cellId]:updateBtnState()

			if self.activityData_:getSelfGroup() == 2 then
				return {
					x = -(maxWidth / 13) * (pos[1] + 3),
					y = maxHeight / 13 * pos[2]
				}
			else
				return {
					x = -(maxWidth / 13) * pos[1],
					y = maxHeight / 13 * pos[2]
				}
			end
		end
	end
end

function ArcticExpeditionMainWindow:updateTimeGroup()
	local endTime = self.activityData_:getEndTime()
	local startTime = self.activityData_:startTime()
	local duration = nil

	if xyd.getServerTime() - startTime < xyd.DAY_TIME then
		self.labelEnd_.text = __("ARCTIC_EXPEDITION_TEXT_25")
		duration = startTime + xyd.DAY_TIME - xyd.getServerTime()
	elseif xyd.DAY_TIME < endTime - xyd.getServerTime() then
		self.labelEnd_.text = __("ARCTIC_EXPEDITION_TEXT_26")
		duration = endTime - xyd.DAY_TIME - xyd.getServerTime()
	else
		self.labelEnd_.text = __("ARCTIC_EXPEDITION_TEXT_27")

		self.labelTime_.gameObject:SetActive(false)

		duration = 0
	end

	local timeCount = import("app.components.CountDown").new(self.labelTime_)

	timeCount:setInfo({
		duration = duration
	})
end

function ArcticExpeditionMainWindow:willClose()
	local params = {
		x = self.mapScrollView.transform.localPosition.x,
		y = self.mapScrollView.transform.localPosition.y
	}

	xyd.db.misc:setValue({
		key = "arctic_expedition_last_pos",
		value = cjson.encode(params)
	})
	ArcticExpeditionMainWindow.super.willClose(self)
end

function ArcticExpeditionMainWindow:updateCellAfterBattle(event)
	local cell_id = event.data.info.table_id
	local cellInfo = self.activityData_:getCellInfo(cell_id)

	self.cellItemList_[cell_id]:setInfo(cellInfo, cell_id)
	self:updateResEnergyNum()
	self:updateSelfScore()
end

function ArcticExpeditionMainWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.UIPanel = winTrans:NodeByName("UIPanel").gameObject
	self.titleGroup = self.UIPanel:NodeByName("titleGroup").gameObject
	self.logoImg_ = self.titleGroup:ComponentByName("logo", typeof(UITexture))
	self.labelEnd_ = self.titleGroup:ComponentByName("labelEnd", typeof(UILabel))
	self.labelTime_ = self.titleGroup:ComponentByName("labelTime", typeof(UILabel))
	self.topBtnGroup = self.UIPanel:NodeByName("topBtnGroup").gameObject
	self.helpBtn_ = self.topBtnGroup:NodeByName("helpBtn").gameObject
	self.btnState_ = self.topBtnGroup:NodeByName("btnState").gameObject
	self.btnStateLabel = self.topBtnGroup:ComponentByName("btnState/label", typeof(UILabel))
	self.groupImg_ = self.topBtnGroup:ComponentByName("groupGroupScore/groupImg", typeof(UISprite))
	self.groupScoreLabel_ = self.topBtnGroup:ComponentByName("groupGroupScore/label", typeof(UILabel))
	self.groupScoreLabelText_ = self.topBtnGroup:ComponentByName("groupGroupScore/labelText", typeof(UILabel))
	self.selfScoreLabel_ = self.topBtnGroup:ComponentByName("groupSelfScore/label", typeof(UILabel))
	self.selfScoreLabelText_ = self.topBtnGroup:ComponentByName("groupSelfScore/labelText", typeof(UILabel))
	self.bottomBtnGroup = self.UIPanel:NodeByName("bottomBtnGroup").gameObject
	self.btnMission = self.bottomBtnGroup:NodeByName("btnMission").gameObject
	self.btnMissionLabel = self.btnMission:ComponentByName("label", typeof(UISprite))
	self.btnMissionRed = self.btnMission:NodeByName("redPoint").gameObject
	self.btnAward = self.bottomBtnGroup:NodeByName("btnAward").gameObject
	self.btnAwardLabel = self.btnAward:ComponentByName("label", typeof(UISprite))
	self.btnRank = self.bottomBtnGroup:NodeByName("btnRank").gameObject
	self.btnRankLabel = self.btnRank:ComponentByName("label", typeof(UISprite))
	self.resEnergy = winTrans:NodeByName("res_item").gameObject
	self.resEnergyNum = winTrans:ComponentByName("res_item/res_num_label", typeof(UILabel))
	self.resEnergyPlus = winTrans:NodeByName("res_item/plus_btn").gameObject
	self.mapGroup = winTrans:NodeByName("mapGroup").gameObject
	self.mapScrollView = self.mapGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.backMap_ = self.mapGroup:ComponentByName("scrollView/backMap", typeof(UITexture))
	self.posCell = self.backMap_:NodeByName("posCell").gameObject
	self.cellGroup_ = self.mapGroup:NodeByName("cellGroup").gameObject
	self.cellItem_ = self.mapGroup:NodeByName("cellItem").gameObject
	self.uiGroup_ = winTrans:NodeByName("UIPanel").gameObject
	self.miniCamera_ = self.uiGroup_:NodeByName("miniMap/miniCamera").gameObject
	self.chatGroup = self.UIPanel:NodeByName("chatGroup").gameObject
	self.chatBtn = self.chatGroup:NodeByName("chatBtn").gameObject
	self.chatLabel = self.chatGroup:ComponentByName("labelChat", typeof(UILabel))
end

function ArcticExpeditionMainWindow:initLayout()
	if self.activityData_.hasReqChat then
		self.chatGroup:SetActive(true)
		self:updateLastChat()
	else
		self.chatGroup:SetActive(false)
	end

	local realHeight = xyd.Global.getRealHeight()
	local realWidth = xyd.Global.getRealWidth()
	self.btnStateLabel.text = __("ARCTIC_EXPEDITION_TEXT_66")
	self.groupScoreLabelText_.text = __("ARCTIC_EXPEDITION_TEXT_60")
	self.selfScoreLabelText_.text = __("ARCTIC_EXPEDITION_TEXT_15")

	xyd.setUISpriteAsync(self.groupImg_, nil, "arctic_expedition_cell_group_icon_" .. self.activityData_:getSelfGroup())
	xyd.setUITextureByNameAsync(self.logoImg_, "arctic_expedition_logo_" .. xyd.Global.lang, true)
	xyd.setUISpriteAsync(self.btnMissionLabel, nil, "arctic_expedition_btn_mission_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.btnAwardLabel, nil, "arctic_expedition_btn_award_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.btnRankLabel, nil, "arctic_expedition_btn_rank_" .. xyd.Global.lang, nil, , true)
	self.backMap_.transform:X(-realWidth * 0.5)
	self.backMap_.transform:Y(realHeight * 0.5 - 68)
	self:initTopGroup()

	if not self.activityData_:reqMapInfo() then
		self:refreshMap()
	end

	self:updateMissionRed()
end

function ArcticExpeditionMainWindow:updateMissionRed()
	local missionRed = self.activityData_:checkMissionRed()

	self.btnMissionRed:SetActive(missionRed)
end

function ArcticExpeditionMainWindow:updateSelfScore()
	self.selfScoreLabel_.text = math.ceil(self.activityData_.detail.score)
end

function ArcticExpeditionMainWindow:updateGroupScore()
	self.groupScoreLabel_.text = self.activityData_.detail_["group_score" .. self.activityData_:getSelfGroup()] or 0
end

function ArcticExpeditionMainWindow:updateResEnergyNum()
	self.resEnergyNum.text = self.activityData_:getStaNum()
end

function ArcticExpeditionMainWindow:reqChatMsg()
	self.activityData_:reqChatMsg()
end

function ArcticExpeditionMainWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.UIPanel.gameObject, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)
	self.windowTop:addItemInResList(self.resEnergy)
end

function ArcticExpeditionMainWindow:refreshMap()
	local GroupColor = {
		Color.New2(3903474175.0),
		Color.New2(4016532991.0),
		Color.New2(2464115199.0),
		Color.New2(1390213375)
	}
	self.groupID_ = self.activityData_:getSelfGroup()
	local isFirst = self.is_first
	self.cellInfoList_ = self.activityData_:getMapInfo()
	local tb = xyd.tables.arcticExpeditionCellsTable
	self.cellIds_ = tb:getIds()
	local mainPos, startPos = nil

	for index, cellId in ipairs(self.cellIds_) do
		local pos = tb:getCellPos(cellId)

		if pos and pos[2] then
			if not self.cellGroupList_[pos[2]] then
				local cellGrid = NGUITools.AddChild(self.posCell, self.cellGroup_.gameObject)

				if pos[2] % 2 == 1 then
					cellGrid.transform:X(-78)
				else
					cellGrid.transform:X(0)
				end

				cellGrid.transform:Y((pos[2] - 1) * -133)

				self.cellGroupList_[pos[2]] = cellGrid:GetComponent(typeof(UIGrid))

				self:waitForFrame(1, function ()
					self.cellGroupList_[pos[2]]:Reposition()
				end)
			end

			if not self.cellItemList_[cellId] then
				local newRoot = NGUITools.AddChild(self.cellGroupList_[pos[2]].gameObject, self.cellItem_)

				newRoot:SetActive(true)

				local newItem = CellItem.new(newRoot, self)

				newItem:setDepth(pos[2] * 14 + pos[1])

				self.cellItemList_[cellId] = newItem
			end

			self.cellItemList_[cellId]:setInfo(self.cellInfoList_[cellId], cellId)

			if isFirst then
				-- Nothing
			end
		end
	end

	self.cellGroupList_[#self.cellGroupList_]:Reposition()

	if isFirst then
		self:updateEnterPos()
	end

	self:checkShowRallyList()

	self.is_first = false
end

function ArcticExpeditionMainWindow:checkShowRallyList()
	self.cellInfoList_ = self.activityData_:getMapInfo()
	local group = self.activityData_:getSelfGroup()
	local rallyList = {}

	for index, cellId in ipairs(self.cellIds_) do
		local cellInfo = self.cellInfoList_[cellId]
		local rallyInfo = cellInfo["rally" .. group]

		self.cellItemList_[cellId]:hideRallyInfo()

		if rallyInfo and rallyInfo.end_time then
			table.insert(rallyList, rallyInfo)
		end
	end

	table.sort(rallyList, function (a, b)
		return b.end_time < a.end_time
	end)

	for i = 1, 3 do
		if rallyList[i] and xyd.getServerTime() <= rallyList[i].end_time then
			self.cellItemList_[rallyList[i].cell_id]:showRallyInfo(rallyList[i])
		end
	end
end

function ArcticExpeditionMainWindow:onRallyInfo(event)
	local cell_id = event.data.cell_id
	self.needUpdateRallyInfo_ = cell_id
	self.activityData_.detail.last_rally = xyd.getServerTime()

	self.cellItemList_[cell_id]:hideBtnGroup()
	self.activityData_:reqCellInfo(cell_id, true)
end

function ArcticExpeditionMainWindow:updateCellShowState(cell_id)
	for index, cellId in ipairs(self.cellIds_) do
		if self.cellItemList_[cellId] and cell_id ~= cellId then
			self.cellItemList_[cellId]:hideBtnGroup()
		end
	end
end

function ArcticExpeditionMainWindow:updateMiniMapPos()
	if not self.window_ or tolua.isnull(self.window_) then
		return
	end

	local bigMapPos = self.mapScrollView.transform.localPosition
	local posX = bigMapPos.x - 222
	local posY = bigMapPos.y
	local realHeight = xyd.Global.getRealHeight()
	local realWidth = xyd.Global.getRealWidth()
	local maxPosx = 2048 - realWidth + 444
	local maxPosy = 2048 - (realHeight - 118) + 142

	self.miniCamera_.transform:X(posX / -maxPosx * 138)
	self.miniCamera_.transform:Y(posY / -maxPosy * 122)
end

function ArcticExpeditionMainWindow:onChatBack(event)
	self.chatGroup:SetActive(true)
	self:updateLastChat()
end

function ArcticExpeditionMainWindow:onCellGroupChange(event)
	local cell_id = event.data.table_id
	local cellInfo = self.activityData_:getCellInfo(cell_id)

	if self.cellItemList_[cell_id] then
		self.cellItemList_[cell_id]:setInfo(cellInfo, cell_id)
	end
end

function ArcticExpeditionMainWindow:updateLastChat()
	local infos = xyd.models.chat:getMsgsByTypeWithFilter(xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE)

	for i = #infos, 1, -1 do
		local info = infos[i]
		local content = info.content
		local eMsgId = tonumber(info.e_msg_id) or 0
		local isEmo = string.find(content, "#emotion")
		local isGif = string.find(content, "#gif")
		local isImg = info.msg_format and info.msg_format == "img"

		if not isEmo and not isGif and not isImg and eMsgId == 0 then
			local tmpStr = content

			if string.len(content) > 14 then
				tmpStr = string.sub(content, 1, 14) .. "..."
			end

			self.chatLabel.text = tmpStr

			break
		end
	end
end

return ArcticExpeditionMainWindow
