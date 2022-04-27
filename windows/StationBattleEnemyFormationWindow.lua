local BattleFormationWindow = import(".BattleFormationWindow")
local StationBattleEnemyFormationWindow = class("StationBattleEnemyFormationWindow", BattleFormationWindow)
local HeroIcon = import("app.components.HeroIcon")

function StationBattleEnemyFormationWindow:ctor(name, params)
	StationBattleEnemyFormationWindow.super.ctor(self, name, params)

	self.self_partners_ = nil
	self.SORT_TYPE = {
		__("TREE"),
		__("FIVE_STAR"),
		__("SIX_STAR"),
		__("TEN_STAR")
	}
	self.self_partners_ = params.self_partners
	self.cur_id_ = params.type_id
	self.table_id_ = params.table_id
	self.sort_type_ = 1
end

function StationBattleEnemyFormationWindow:initWindow()
	local winTrans = self.window_.transform
	self.sortBtn = winTrans:NodeByName("main/choose_group/sortBtn").gameObject
	self.sortArrow = self.sortBtn:ComponentByName("arrow", typeof(UISprite))
	self.sortLabel = self.sortBtn:ComponentByName("label", typeof(UILabel))
	self.sortPop = winTrans:NodeByName("main/top_group/sortPop").gameObject
	self.imgMask = winTrans:NodeByName("main/top_group/imgMask").gameObject
	self.btnHelp = winTrans:NodeByName("main/top_group/btnHelp").gameObject

	for i = 1, 4 do
		self["SortType" .. i] = self.sortPop:NodeByName("SortType" .. i).gameObject
		self["SortLabel" .. i] = self["SortType" .. i]:ComponentByName("label", typeof(UILabel))
		self["SortChosen" .. i] = self["SortType" .. i]:ComponentByName("chosen", typeof(UISprite))
		self["SortUnChosen" .. i] = self["SortType" .. i]:ComponentByName("unchosen", typeof(UISprite))
	end

	StationBattleEnemyFormationWindow.super.initWindow(self)
	self:initSortText()

	self.labelBattleBtn.text = __("FOR_SURE")
	UIEventListener.Get(self.sortBtn).onClick = handler(self, self.moveSortPop)
	UIEventListener.Get(self.imgMask).onClick = handler(self, self.moveSortPop)

	UIEventListener.Get(self.btnHelp).onClick = function ()
		local params = {
			key = "PARTNER_STATION_SELECT_ENEMY_WINDOW_HELP",
			title = __("SETTING_UP_HELP")
		}

		xyd.openWindow("partner_data_station_help_window", params)
	end

	for i = 1, 4 do
		UIEventListener.Get(self["SortType" .. i]).onClick = function ()
			print(self.sort_type_)
			print(i)
			self:changeSortType(i)
		end
	end

	self.petBtn:SetActive(false)
end

function StationBattleEnemyFormationWindow:initSortText()
	local sizeLang = {
		fr_fr = 20,
		de_de = 20
	}

	for i = 1, 4 do
		self["SortLabel" .. i].text = self.SORT_TYPE[i]
		self["SortLabel" .. i].fontSize = sizeLang[xyd.Global.lang] or 22
	end

	self.sortLabel.text = __("TREE")
end

function StationBattleEnemyFormationWindow:updateForceNum()
	local power = 0

	for i = 1, #self.copyIconList do
		local partnerIcon = self.copyIconList[i]

		if partnerIcon then
			local partnerInfo = partnerIcon:getPartnerInfo()
			local partner = xyd.models.partnerDataStation:getPartner(tonumber(partnerInfo.partnerID))
			power = power + partner:getPower()
		end
	end

	self.labelForceNum.text = tostring(power)
end

function StationBattleEnemyFormationWindow:setBtnState(index, type)
	if type == "chosen" then
		self["SortChosen" .. index]:SetActive(true)
		self["SortUnChosen" .. index]:SetActive(false)
	else
		self["SortChosen" .. index]:SetActive(false)
		self["SortUnChosen" .. index]:SetActive(true)
	end
end

function StationBattleEnemyFormationWindow:changeSortType(sortType)
	if sortType ~= self.sort_type_ then
		self:setBtnState(sortType, "chosen")
		self:setBtnState(self.sort_type_, "unchosen")

		self.sort_type_ = sortType
		self.sortLabel.text = self.SORT_TYPE[sortType]

		self:iniPartnerData(self.selectGroup_ or 0, false)
		self:moveSortPop()
	end
end

function StationBattleEnemyFormationWindow:moveSortPop()
	local sequence2 = self:getSequence()
	local sortPopTrans = self.sortPop.transform
	local p = self.sortPop:GetComponent(typeof(UIPanel))
	local sortPopY = -180

	local function getter()
		return Color.New(1, 1, 1, p.alpha)
	end

	local function setter(color)
		p.alpha = color.a
	end

	if self.sortPop.activeSelf == true then
		self.sortArrow.transform:SetLocalScale(1, 1, 1)
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY + 17, 0.067))
		sequence2:Insert(0.067, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0.1))
		sequence2:Insert(0.067, sortPopTrans:DOLocalMoveY(sortPopY - 58, 0.1))
		sequence2:Insert(0.167, sortPopTrans:DOLocalMoveY(sortPopY, 0))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil

			self.sortPop:SetActive(false)
		end)
	else
		self.sortPop:SetActive(true)
		self.sortArrow.transform:SetLocalScale(1, -1, 1)
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY - 58, 0))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0))
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY + 17, 0.1))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.1))
		sequence2:Insert(0.1, sortPopTrans:DOLocalMoveY(sortPopY, 0.2))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil
		end)
	end
end

function StationBattleEnemyFormationWindow:readStorageFormation()
	local flag = StationBattleEnemyFormationWindow.super.readStorageFormation(self)

	if not flag then
		local list = {
			1,
			2,
			3,
			4,
			5,
			6
		}

		for i = 1, 6 do
			self.nowPartnerList[i] = list[i]
		end
	end

	return true
end

function StationBattleEnemyFormationWindow:onClickBattleBtn()
	StationBattleEnemyFormationWindow.super.onClickBattleBtn(self)
	xyd.WindowManager.get():closeWindow("station_battle_enemy_formation_window")
end

function StationBattleEnemyFormationWindow:iniPartnerData(groupID, needUpdateTop)
	self.collection = self:initPartnerStationEnemyData(groupID, needUpdateTop)

	self.partnerMultiWrap_:setInfos(self.collection, {})
end

function StationBattleEnemyFormationWindow:initPartnerStationEnemyData(groupID, needUpdateTop)
	local type = self.sort_type_
	local partnerList = xyd.models.partnerDataStation:getHeros(type)
	local partnerDataList = {}
	local chooseDataList = {}
	self.power = 0

	for _, partner in ipairs(partnerList) do
		local partnerInfo = {
			noClick = true,
			tableID = partner:getHeroTableID(),
			lev = partner:getLevel(),
			awake = partner.awake,
			group = partner:getGroup(),
			grade = partner:getGrade(),
			partnerID = partner:getPartnerID(),
			power = partner:getPower()
		}
		local pGroupID = partner:getGroup()
		local isS = self:isSelected(partnerInfo.partnerID, self.nowPartnerList, false)

		if groupID == 0 or pGroupID == groupID or isS.isSelected then
			local data = {
				callbackFunc = handler(self, function (a, callbackPInfo, callbackIsChoose)
					self:onClickheroIcon(callbackPInfo, callbackIsChoose)
				end),
				partnerInfo = partnerInfo,
				isSelected = isS.isSelected
			}

			table.insert(partnerDataList, data)
		end
	end

	for i, _ in pairs(self.nowPartnerList) do
		local partnerId = self.nowPartnerList[i]
		local partner = xyd.models.partnerDataStation:getPartner(tonumber(partnerId))

		if partner then
			local partnerInfo = {
				noClick = true,
				tableID = partner:getHeroTableID(),
				lev = partner:getLevel(),
				awake = partner.awake,
				group = partner:getGroup(),
				grade = partner:getGrade(),
				partnerID = partner:getPartnerID(),
				posId = tonumber(i),
				power = partner:getPower()
			}
			local isS = true
			self.power = self.power + partner:getPower()
			local cParams = self:isSelected(partnerInfo.partnerID, self.copyIconList, false)
			local isChoose = cParams.isSelected

			if not isChoose and needUpdateTop then
				self:onClickheroIcon(partnerInfo, false, partnerInfo.posId)
			end
		end
	end

	self.labelForceNum.text = tostring(self.power)

	return partnerDataList
end

function StationBattleEnemyFormationWindow:stationBattle(partnerParams)
	local monsterInfo = {}
	local msg = messages_pb.partner_data_fight_req()
	msg.table_id = self.table_id_
	msg.type_id = self.cur_id_
	msg.pet_id = self.pet

	for _, partner in ipairs(self.self_partners_) do
		local tmpPartner = messages_pb:partners_info()
		tmpPartner.partner_id = partner.partner_id
		tmpPartner.pos = partner.pos

		table.insert(msg.partners, tmpPartner)
	end

	for _, info in ipairs(partnerParams) do
		local tmpMonster = messages_pb:monsters_infos()
		tmpMonster.table_id = info.partner_id
		tmpMonster.pos = info.pos

		table.insert(msg.monster_infos, tmpMonster)
	end

	xyd.Backend.get():request(xyd.mid.PARTNER_DATA_FIGHT, msg)
	xyd.models.partnerDataStation:reqTouchId(12)
end

function StationBattleEnemyFormationWindow:showPartnerDetail(event, force, partnerInfoForce)
	if force == nil then
		force = false
	end
end

return StationBattleEnemyFormationWindow
