local BaseWindow = import(".BaseWindow")
local PartnerStationBattleFormationWindow = class("PartnerStationBattleFormationWindow", BaseWindow)
local GroupBuffTable = xyd.tables.groupBuffTable
local MonsterTable = xyd.tables.monsterTable
local MiscTable = xyd.tables.miscTable
local PartnerTable = xyd.tables.partnerTable
local PartnerDirectTable = xyd.tables.partnerDirectTable
local PartnerDataStation = xyd.models.partnerDataStation
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")
local GroupBuffIcon = import("app.components.GroupBuffIcon")
local GroupBuffIconItem = class("GroupBuffIconItem")

function GroupBuffIconItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.groupBuffIcon = GroupBuffIcon.new(self.go, self.parent.buffRenderPanel)

	self.groupBuffIcon:setDragScrollView(self.parent.formationBuffScroller)

	UIEventListener.Get(self.groupBuffIcon:getGameObject()).onPress = function (go, isPress)
		if isPress then
			local win = xyd.WindowManager.get():getWindow("group_buff_detail_window")

			if win then
				xyd.WindowManager.get():closeWindow("group_buff_detail_window", function ()
					XYDCo.WaitForTime(1, function ()
						local params = {
							buffID = self.info_.buffId,
							type = self.info_.type_,
							contenty = -29
						}

						xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
					end, nil)
				end)
			else
				local params = {
					buffID = self.info_.buffId,
					type = self.info_.type_,
					contenty = -29
				}

				xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
			end
		else
			xyd.WindowManager.get():closeWindow("group_buff_detail_window")
		end
	end
end

function GroupBuffIconItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	if not self.groupBuffIcon then
		self.groupBuffIcon = GroupBuffIcon.new(self.go, self.parent.buffRenderPanel)
	end

	self.groupBuffIcon:setInfo(info.buffId, info.isAct, info.type_)

	self.info_ = info

	self.go:SetActive(true)
end

function GroupBuffIconItem:getGameObject()
	return self.go
end

local PartnerEvaluationItem = class("PartnerEvaluationItem", import("app.components.BaseComponent"))

function PartnerEvaluationItem:ctor(parentGo, params)
	PartnerEvaluationItem.super.ctor(self, parentGo)

	self.index = params.type

	self:layout()
end

function PartnerEvaluationItem:getPrefabPath()
	return "Prefabs/Components/partner_evaluation_item"
end

function PartnerEvaluationItem:initUI()
	PartnerEvaluationItem.super.initUI(self)

	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.labelDesc = go:ComponentByName("labelTag", typeof(UILabel))
end

function PartnerEvaluationItem:layout()
	local text = ""
	local index = self.index

	if index == xyd.PartnerType.ATK then
		text = __("TRY_FIGHT_TIPS03")
	elseif index == xyd.PartnerType.SUP then
		text = __("TRY_FIGHT_TIPS04")
	elseif index == xyd.PartnerType.TANK then
		text = __("TRY_FIGHT_TIPS02")
	end

	self.labelDesc.text = text

	xyd.setUISpriteAsync(self.imgBg, nil, "station_white_bg")

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "en_en" then
		self.imgBg.height = 50
	end
end

function PartnerStationBattleFormationWindow:ctor(name, params)
	PartnerStationBattleFormationWindow.super.ctor(self, name, params)

	self.callback = nil
	self.groupBuffTable = GroupBuffTable
	self.slot = xyd.models.slot
	self.battlePartnerList = {}
	self.nowPartnerList = {}
	self.buffDataList = {}
	self.partners = nil
	self.pet = 0
	self.tankMin = 1
	self.supMin = 1
	self.atkMin = 3
	self.data = params
	self.battleType = params.battleType
	self.pet = params.pet or 0
	self.callback = params.callback
	self.curID = params.id
	self.curIndex = params.index or 0
	self.curTableId = params.table_id
end

function PartnerStationBattleFormationWindow:initWindow()
	PartnerStationBattleFormationWindow.super.initWindow(self)
	self:getUIComponents()
	self:initData()
	self:initLayOut()
	self:registerEvent()
end

function PartnerStationBattleFormationWindow:getUIComponents()
	local go = self.window_
	self.winBg_ = go:ComponentByName("winBg_", typeof(UISprite))
	self.groupTop = go:NodeByName("groupTop").gameObject
	self.labelWinTitle = self.groupTop:ComponentByName("labelWinTitle", typeof(UILabel))
	self.groupMain = self.groupTop:NodeByName("groupMain").gameObject
	self.labelForceNum = self.groupMain:ComponentByName("labelForceNum", typeof(UILabel))
	self.buffGroup = self.groupMain:NodeByName("buffGroup").gameObject
	self.formationBuffScroller = self.buffGroup:ComponentByName("formationBuffScroller", typeof(UIScrollView))
	self.buffPanel = self.buffGroup:ComponentByName("formationBuffScroller", typeof(UIPanel))
	self.buffRoot = self.buffGroup:NodeByName("buff_root").gameObject
	self.formationBuffContainer = self.formationBuffScroller:ComponentByName("formationBuffContainer", typeof(UIWrapContent))
	self.groupBar = self.groupMain:NodeByName("groupBar").gameObject
	local str = {
		"Atk",
		"Ctrl",
		"Arm",
		"Sup"
	}

	for _, name in ipairs(str) do
		self["group" .. name] = self.groupBar:NodeByName("group" .. name).gameObject
		self["label" .. name] = self["group" .. name]:ComponentByName("label" .. name, typeof(UILabel))
		self[string.lower(name) .. "Bar"] = self["group" .. name]:ComponentByName(string.lower(name) .. "Bar", typeof(UIProgressBar))
	end

	self.selectedFormationGroup = self.groupMain:NodeByName("selectedFormationGroup").gameObject
	self.backGroup = self.selectedFormationGroup:NodeByName("backGroup").gameObject
	self.labelBack = self.backGroup:ComponentByName("labelBack", typeof(UILabel))

	for i = 3, 6 do
		self["container_" .. i] = self.backGroup:NodeByName("container_" .. i).gameObject
	end

	self.frontGroup = self.selectedFormationGroup:NodeByName("frontGroup").gameObject
	self.labelFront = self.frontGroup:ComponentByName("labelFront", typeof(UILabel))

	for i = 1, 2 do
		self["container_" .. i] = self.frontGroup:NodeByName("container_" .. i).gameObject
	end

	self.groupEva = self.groupMain:NodeByName("groupEva").gameObject
	self.groupEvaYes = self.groupEva:NodeByName("groupEvaYes").gameObject
	self.labelEvaluateYes = self.groupEvaYes:ComponentByName("labelEvaluateYes", typeof(UILabel))
	self.groupEvaNo = self.groupEva:NodeByName("groupEvaNo").gameObject
	self.battleBtnGroup = self.groupTop:NodeByName("battleBtnGroup").gameObject
	self.battleBtn = self.battleBtnGroup:NodeByName("battleBtn").gameObject
	self.battleBtnLabel = self.battleBtn:ComponentByName("battleBtnLabel", typeof(UILabel))
	self.closeBtn = self.groupTop:NodeByName("closeBtn").gameObject
	self.tipBtn = self.groupTop:NodeByName("tipBtn").gameObject
end

function PartnerStationBattleFormationWindow:initData()
	local partnerList = self.data.partner_list

	for i = 1, #partnerList do
		local partner = partnerList[i]
		local partnerID = MonsterTable:getPartnerLink(partner.tableID)
		partnerID = partnerID or partner.tableID
		self.nowPartnerList[i] = partnerID
	end

	self.totalPoint = 30
end

function PartnerStationBattleFormationWindow:initLayOut()
	self.labelFront.text = __("FRONT_ROW")
	self.labelBack.text = __("BACK_ROW")
	self.battleBtnLabel.text = __("BATTLE_START")
	self.labelAtk.text = __("PARTNER_STATION_POINT_ATK")
	self.labelArm.text = __("PARTNER_STATION_POINT_ARM")
	self.labelSup.text = __("PARTNER_STATION_POINT_HP")
	self.labelCtrl.text = __("PARTNER_STATION_POINT_CTL")
	self.labelEvaluateYes.text = __("TRY_FIGHT_TIPS01")

	self:initBuffScroll()
	self:updateFormation()
	self:initHeroIcon()

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
		self.labelArm.fontSize = 16
		self.labelAtk.fontSize = 16
		self.labelSup.fontSize = 16
		self.labelCtrl.fontSize = 16
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelArm:SetLocalPosition(-163, 0, 0)
		self.labelAtk:SetLocalPosition(-163, 0, 0)
		self.labelSup:SetLocalPosition(-170, 0, 0)
		self.labelCtrl:SetLocalPosition(-170, 0, 0)
	end
end

function PartnerStationBattleFormationWindow:updateFormation()
	self:updateForceNum()
	self:updateBar()
	self:updatePartnerEvaluate()
	self:updateBuff()
end

function PartnerStationBattleFormationWindow:updateForceNum()
	local power = 0
	local partners = self.data.partner_list

	for i = 1, #partners do
		local partner = partners[i]
		power = power + partner:getPower()
	end

	self.labelForceNum.text = tostring(power)
end

function PartnerStationBattleFormationWindow:updateBar()
	local atk = 0
	local arm = 0
	local ctrl = 0
	local sup = 0

	for i = 1, #self.nowPartnerList do
		local id = self.nowPartnerList[i]

		if id then
			id = PartnerTable:getCommentID(id)

			if id then
				atk = atk + PartnerDirectTable:getPointAtk(id)
				arm = arm + PartnerDirectTable:getPointArm(id)
				ctrl = ctrl + PartnerDirectTable:getPointCtrl(id)
				sup = sup + PartnerDirectTable:getPointSup(id)
			end
		end
	end

	self.atkBar.value = math.floor(atk) / self.totalPoint
	self.armBar.value = math.floor(arm) / self.totalPoint
	self.ctrlBar.value = math.floor(ctrl) / self.totalPoint
	self.supBar.value = math.floor(sup) / self.totalPoint
end

function PartnerStationBattleFormationWindow:updatePartnerEvaluate()
	local tankCnt = 0
	local supCnt = 0
	local atkCnt = 0
	local ifReasonable = true

	for i = 1, #self.nowPartnerList do
		local id = self.nowPartnerList[i]

		if id then
			id = PartnerTable:getCommentID(id)

			if id then
				local types = PartnerDirectTable:getPartnerType(id)

				for _, type in ipairs(types) do
					if type == xyd.PartnerType.ATK then
						atkCnt = atkCnt + 1
					elseif type == xyd.PartnerType.SUP then
						supCnt = supCnt + 1
					elseif type == xyd.PartnerType.TANK then
						tankCnt = tankCnt + 1
					end
				end
			end
		end
	end

	if atkCnt < self.atkMin then
		local label = PartnerEvaluationItem.new(self.groupEvaNo, {
			type = xyd.PartnerType.ATK
		})
		ifReasonable = false
	end

	if supCnt < self.supMin then
		local label = PartnerEvaluationItem.new(self.groupEvaNo, {
			type = xyd.PartnerType.SUP
		})
		ifReasonable = false
	end

	if tankCnt < self.tankMin then
		local label = PartnerEvaluationItem.new(self.groupEvaNo, {
			type = xyd.PartnerType.TANK
		})
		ifReasonable = false
	end

	if ifReasonable then
		self.groupEvaYes:SetActive(true)
		self.groupEvaNo:SetActive(false)
	else
		self.groupEvaYes:SetActive(false)
		self.groupEvaNo:SetActive(true)
	end

	self.groupEvaNo:GetComponent(typeof(UILayout)):Reposition()
end

function PartnerStationBattleFormationWindow:updateBuff()
	local groupNum = {}
	local tNum = 0

	for i = 1, #self.nowPartnerList do
		local id = self.nowPartnerList[i]

		if id then
			local group = PartnerTable:getGroup(id)

			if not groupNum[tostring(group)] then
				groupNum[tostring(group)] = 0
			end

			groupNum[tostring(group)] = groupNum[tostring(group)] + 1
			tNum = tNum + 1
		end
	end

	local buffIds = self.groupBuffTable:getIds()
	local maxWidth = #self.buffDataList * 76

	for i = 1, #self.buffDataList do
		local buffId = self.buffDataList[i].buffId
		local isAct = self.buffDataList[i].isAct
		local type_ = self.buffDataList[i].type or xyd.GroupBuffIconType.GROUP_BUFF

		if type_ ~= xyd.GroupBuffIconType.HERO_CHALLENGE then
			local groupDataList = xyd.split(self.groupBuffTable:getGroupConfig(buffId), "|")
			local isNewAct = true

			if tNum < 6 then
				isNewAct = false
			else
				for _, gi in ipairs(groupDataList) do
					local giList = xyd.split(gi, "#")

					if tonumber(groupNum[tostring(giList[0])]) ~= tonumber(giList[1]) then
						isNewAct = false

						break
					end
				end
			end

			self.actBuffID = 0

			if isNewAct then
				self.actBuffID = buffId
			end

			if isNewAct ~= isAct then
				break
			end
		end
	end
end

function PartnerStationBattleFormationWindow:initHeroIcon()
	local partners = self.data.partner_list

	for i = 1, #partners do
		local posId = partners[i].pos
		posId = posId or i
		local icon = HeroIcon.new(self["container_" .. tostring(posId)])

		icon:setInfo(partners[i]:getInfo())
		icon:setPetFrame(self.pet)
	end
end

function PartnerStationBattleFormationWindow:initBuffScroll()
	local buffIds = self.groupBuffTable:getIds()

	for i, buffId in ipairs(buffIds) do
		local isAct = false

		table.insert(self.buffDataList, {
			isAct = isAct,
			buffId = tonumber(buffId)
		})
	end

	self.buffWrapContent = require("app.common.ui.FixedWrapContent").new(self.formationBuffScroller, self.formationBuffContainer, self.buffRoot, GroupBuffIconItem, self)

	self.buffWrapContent:setInfos(self.buffDataList, {})
end

function PartnerStationBattleFormationWindow:isBuffAct(buffID)
	if tonumber(self.actBuffID) == tonumber(buffID) then
		return true
	else
		return false
	end
end

function PartnerStationBattleFormationWindow:registerEvent()
	PartnerStationBattleFormationWindow.super.register(self)

	UIEventListener.Get(self.battleBtn).onClick = handler(self, self.onClickBattleBtn)
end

function PartnerStationBattleFormationWindow:onClickBattleBtn()
	if self.curIndex then
		PartnerDataStation:reqBattle({
			table_id = self.curTableId,
			type_id = self.curID,
			index = self.curIndex
		})
	else
		PartnerDataStation:reqBattle({
			table_id = self.curTableId,
			type_id = self.curID
		})
	end
end

return PartnerStationBattleFormationWindow
