local BattleFormationWindow = import(".BattleFormationWindow")
local StationBattleFormationWindow = class("StationBattleFormationWindow", BattleFormationWindow)
local PartnerDirectTable = xyd.tables.partnerDirectTable
local PartnerTable = xyd.tables.partnerTable
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

	print(index)

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

function StationBattleFormationWindow:ctor(name, params)
	StationBattleFormationWindow.super.ctor(self, name, params)

	self.tankMin = 1
	self.supMin = 1
	self.atkMin = 3
	self.curId = params.curId
	self.tableId = params.table_id
	self.totalPoint = 30
end

function StationBattleFormationWindow:playOpenAnimation(callback)
	if callback then
		callback()
	end

	self.topGroup:SetLocalPosition(0, 810, 0)
	self.chooseGroup:SetLocalPosition(0, -1090, 0)

	self.top_tween = DG.Tweening.DOTween.Sequence()

	self.top_tween:Append(self.topGroup.transform:DOLocalMoveY(234, 0.5))
	self.top_tween:AppendCallback(function ()
		self:setWndComplete()

		if self.top_tween then
			self.top_tween:Kill(true)
		end
	end)

	self.down_tween = DG.Tweening.DOTween.Sequence()

	self.down_tween:Append(self.chooseGroup.transform:DOLocalMoveY(-150, 0.5))
	self.down_tween:AppendCallback(function ()
		if self.down_tween then
			self.down_tween:Kill(true)
		end
	end)
end

function StationBattleFormationWindow:initWindow()
	local winTrans = self.window_.transform
	self.selectedGroup = winTrans:Find("main/top_group/selected_group")
	self.groupBar = self.selectedGroup:NodeByName("groupBar").gameObject
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

	self.groupEva = self.selectedGroup:NodeByName("groupEva").gameObject
	self.groupEvaYes = self.groupEva:NodeByName("groupEvaYes").gameObject
	self.labelEvaluateYes = self.groupEvaYes:ComponentByName("labelEvaluateYes", typeof(UILabel))
	self.groupEvaNo = self.groupEva:NodeByName("groupEvaNo").gameObject

	StationBattleFormationWindow.super.initWindow(self)
	self.mainGroup.transform:Y(self.scale_num_ * -85 + 55)

	self.labelAtk.text = __("PARTNER_STATION_POINT_ATK")
	self.labelArm.text = __("PARTNER_STATION_POINT_ARM")
	self.labelSup.text = __("PARTNER_STATION_POINT_HP")
	self.labelCtrl.text = __("PARTNER_STATION_POINT_CTL")
	self.labelEvaluateYes.text = __("TRY_FIGHT_TIPS01")
	self.labelBattleBtn.text = __("NEXT_STEP")

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
		self.labelArm.fontSize = 16
		self.labelAtk.fontSize = 16
		self.labelSup.fontSize = 16
		self.labelCtrl.fontSize = 16
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelArm:SetLocalPosition(-170, 0, 0)
		self.labelAtk:SetLocalPosition(-170, 0, 0)
		self.labelSup:SetLocalPosition(-170, 0, 0)
		self.labelCtrl:SetLocalPosition(-170, 0, 0)
	end
end

function StationBattleFormationWindow:initBuffList()
	self.buffDataList = {}
	local buffIds = self.groupBuffTable:getIds()

	for i, buffId in ipairs(buffIds) do
		local isAct = false

		table.insert(self.buffDataList, {
			contenty = 215,
			isAct = isAct,
			buffId = tonumber(buffId)
		})
	end

	table.sort(self.buffDataList, function (a, b)
		return a.buffId < b.buffId
	end)
	self:initBuffList2()
end

function StationBattleFormationWindow:updateForceNum()
	StationBattleFormationWindow.super.updateForceNum(self)
	self:updateBar()
	self:updatePartnerEvaluate()
end

function StationBattleFormationWindow:stationBattle(partnerParams)
	xyd.openWindow("station_battle_enemy_formation_window", {
		choose_enemy = true,
		self_partners = partnerParams,
		table_id = self.tableId,
		type_id = self.curId,
		battleType = xyd.BattleType.PARTNER_STATION,
		pet = self.pet
	})
	xyd.closeWindow("station_battle_formation_window")
end

function StationBattleFormationWindow:showPartnerDetail(event, force, partnerInfoForce)
	if force == nil then
		force = false
	end
end

function StationBattleFormationWindow:updateBar()
	local atk = 0
	local arm = 0
	local ctrl = 0
	local sup = 0

	for i = 1, #self.copyIconList do
		local icon = self.copyIconList[i]

		if icon then
			local info = icon:getPartnerInfo()
			local id = PartnerTable:getCommentID(info.tableID)

			if id and id > 0 then
				print(id)

				atk = atk + PartnerDirectTable:getPointAtk(id)
				arm = arm + PartnerDirectTable:getPointArm(id)
				ctrl = ctrl + PartnerDirectTable:getPointCtrl(id)
				sup = sup + PartnerDirectTable:getPointSup(id)
			end
		end
	end

	self.atkBar.value = atk / self.totalPoint
	self.armBar.value = arm / self.totalPoint
	self.ctrlBar.value = ctrl / self.totalPoint
	self.supBar.value = sup / self.totalPoint
end

function StationBattleFormationWindow:updatePartnerEvaluate()
	NGUITools.DestroyChildren(self.groupEvaNo.transform)

	local tankCnt = 0
	local supCnt = 0
	local atkCnt = 0
	local ifReasonable = true

	for i = 1, #self.copyIconList do
		local icon = self.copyIconList[i]

		if icon then
			local info = icon:getPartnerInfo()
			local id = info.tableID

			if id then
				id = PartnerTable:getCommentID(id)

				if id then
					local types = PartnerDirectTable:getPartnerType(id)

					if types then
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

return StationBattleFormationWindow
