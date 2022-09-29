local PvpVsWindow = class("PvpVsWindow", import(".BaseWindow"))
local PlayerIcon = import("app.components.PlayerIcon")

function PvpVsWindow:ctor(name, params)
	self.callBack = params.pvpCallBack

	PvpVsWindow.super.ctor(self, name, params)
	self:initFormationData()

	self.isOut = false
	self.isChangeAttr = false
end

function PvpVsWindow:initFormationData()
	self.enemyInfo = self.params_.event_data.enemy_info
	self.selfInfo = self.params_.event_data.self_info
	self.battle_report = self.params_.battle_report or self.params_.event_data.battle_report
	self.dressAttrsA = self.battle_report.dressAttrsA
	self.dressAttrsB = self.battle_report.dressAttrsB

	if not self.dressAttrsB[1] then
		self.dressAttrsB = {
			0,
			0,
			0
		}
	end

	if self.params_.battle_type == xyd.BattleType.ARENA_TEAM or self.params_.battle_type == xyd.BattleType.ARENA_TEAM_DEF then
		local battleIndex = xyd.models.arenaTeam:getNowBattleIndex()
		local matchNum = self.params_.event_data.matchNum

		if matchNum and matchNum > 0 then
			battleIndex = matchNum
		end

		self.selfInfo = self.selfInfo.players[battleIndex]
		self.enemyInfo = self.enemyInfo.players[battleIndex]
	end

	if self.params_.battle_type == xyd.BattleType.ARENA_ALL_SERVER and self.enemyInfo and self.enemyInfo.player_id < 10000 then
		local table_id = self.enemyInfo.player_id
		self.enemyInfo.lev = xyd.tables.arenaAllServerRobotTable:getLev(table_id)
		self.enemyInfo.player_name = xyd.tables.arenaAllServerRobotTable:getName(table_id)
		self.enemyInfo.power = xyd.tables.arenaAllServerRobotTable:getPower(table_id)
		self.enemyInfo.score = xyd.tables.arenaAllServerRobotTable:getScore(table_id)
		self.enemyInfo.server_id = xyd.tables.arenaAllServerRobotTable:getServerID(table_id)
		self.enemyInfo.avatar_id = xyd.tables.arenaAllServerRobotTable:getAvatar(table_id)
	end
end

function PvpVsWindow:initWindow()
	self.tweenArr = {}

	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function PvpVsWindow:playOpenAnimation(callback)
	if callback then
		callback()
	end

	local sequence = self:getSequence()
	local leftSprite = self.leftGroup:GetComponent(typeof(UISprite))
	local leftTransform = self.leftGroup.transform
	leftSprite.alpha = 0.01

	local function leftGetter()
		return leftSprite.color
	end

	local function leftSetter(value)
		leftSprite.color = value
	end

	local rightSprite = self.rightGroup:GetComponent(typeof(UISprite))
	local rightTransform = self.rightGroup.transform
	rightSprite.alpha = 0.01

	local function rightGetter()
		return rightSprite.color
	end

	local function rightSetter(value)
		rightSprite.color = value
	end

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(leftGetter, leftSetter, 1, 0.1):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(rightGetter, rightSetter, 1, 0.1):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, leftTransform:DOLocalMoveX(-218, 0.27))
	sequence:Insert(0, rightTransform:DOLocalMoveX(213, 0.27))
	sequence:Insert(0.3, leftTransform:DOLocalMoveX(-222, 0.1))
	sequence:Insert(0.3, rightTransform:DOLocalMoveX(217, 0.1))
	sequence:InsertCallback(3.67, function ()
		self:outAnimation()
	end)
	sequence:AppendCallback(function ()
	end)
	self.vsModel_:setInfo("vs_shining", function ()
		self.vsModel_:play("texiao01", 1, 1, function ()
			self.vsModel_:play("texiao02", 0, 1)
		end)
	end)
	self:changeDressAttr()
end

function PvpVsWindow:outAnimation()
	if self.isOut then
		return
	end

	self.isOut = true

	self.midBg:SetActive(false)

	if self.vsModel_ then
		self.vsModel_:play("texiao03", 1, 1, function ()
		end)
	end

	local sequence = self:getSequence()
	local leftSprite = self.leftGroup:GetComponent(typeof(UISprite))
	local leftTransform = self.leftGroup.transform
	local rightSprite = self.rightGroup:GetComponent(typeof(UISprite))
	local rightTransform = self.rightGroup.transform

	sequence:Insert(0.1, leftTransform:DOLocalMoveX(-782, 0.17))
	sequence:Insert(0.1, rightTransform:DOLocalMoveX(787, 0.17))
	sequence:AppendCallback(function ()
		self:closeImmediately()
	end)
end

function PvpVsWindow:changeDressAttr()
	self.isChangeAttr = true
	local seq = self:getSequence()

	local function addHideAction(sequence, hideGroup, pos)
		local labelNode = self[hideGroup .. "Group"]:NodeByName("group_player/data_group/data_label" .. pos).gameObject
		local label = labelNode:GetComponent(typeof(UILabel))
		label.alpha = 1

		local function getter()
			return label.color
		end

		local function setter(value)
			label.color = value
		end

		sequence:Insert(0.67, DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0.23):SetEase(DG.Tweening.Ease.InOutSine))
		sequence:Insert(0.67, labelNode.transform:DOScale(Vector3(0.5, 0.5, 1), 0.23))

		local imgNode = self[hideGroup .. "Group"]:NodeByName("group_player/data_group/data_image" .. pos).gameObject
		local img = imgNode:GetComponent(typeof(UISprite))
		img.alpha = 1

		local function imgGetter()
			return img.color
		end

		local function imgSetter(value)
			img.color = value
		end

		sequence:Insert(0.67, DG.Tweening.DOTween.ToAlpha(imgGetter, imgSetter, 0, 0.23):SetEase(DG.Tweening.Ease.InOutSine))
		sequence:Insert(0.67, imgNode.transform:DOScale(Vector3(0.5, 0.5, 1), 0.23))
	end

	local function addShowAction(sequence, showGroup, pos, showAttrStr)
		local labelNode = self[showGroup .. "Group"]:NodeByName("group_player/data_group/data_label" .. pos).gameObject

		labelNode:SetActive(true)

		local label = labelNode:GetComponent(typeof(UILabel))

		local function getter()
			return label.color
		end

		local function setter(value)
			label.color = value
		end

		sequence:Insert(1.1, labelNode.transform:DOScale(Vector3(0.5, 0.5, 1), 0.2))
		sequence:InsertCallback(1.3, function ()
			label.text = showAttrStr
		end)
		sequence:Insert(1.3, labelNode.transform:DOScale(Vector3(1, 1, 1), 0.2))
	end

	for i = 1, 3 do
		local attrA = tonumber(self.dressAttrsA[i])
		local attrB = tonumber(self.dressAttrsB[i])
		local resAttr = attrA - attrB
		local showAttrStr = "+" .. math.abs(resAttr)

		if resAttr > 0 then
			addHideAction(seq, "right", i)
			addShowAction(seq, "left", i, showAttrStr)
		elseif resAttr < 0 then
			addHideAction(seq, "left", i)
			addShowAction(seq, "right", i, showAttrStr)
		end
	end
end

function PvpVsWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.leftGroup = self.groupAction:NodeByName("left_group").gameObject
	self.rightGroup = self.groupAction:NodeByName("right_group").gameObject
	self.vsNode = self.groupAction:NodeByName("vs_node").gameObject
	self.midBg = self.groupAction:NodeByName("mid_bg").gameObject
	self.allBg = self.trans:NodeByName("all_bg").gameObject
end

function PvpVsWindow:registerEvent()
	UIEventListener.Get(self.allBg).onClick = handler(self, function ()
		if not self.isChangeAttr then
			return
		end

		self:outAnimation()
	end)
end

function PvpVsWindow:layout()
	local dataA = {
		playerInfo = self.selfInfo,
		dressAttrs = self.dressAttrsA
	}

	self:initPlayer(self.leftGroup, dataA)

	local dataB = {
		isRight = 1,
		playerInfo = self.enemyInfo,
		dressAttrs = self.dressAttrsB
	}

	self:initPlayer(self.rightGroup, dataB)

	self.vsModel_ = xyd.Spine.new(self.vsNode)
end

function PvpVsWindow:initPlayer(parentGo, data)
	local playerGroup = parentGo:NodeByName("group_player").gameObject
	local senpaiNode = playerGroup:NodeByName("senpai_node").gameObject
	local dataGroup = playerGroup:NodeByName("data_group").gameObject
	local serverGroup = playerGroup:NodeByName("server_group").gameObject
	local avatarIcon = playerGroup:NodeByName("avatar_icon").gameObject
	local playerName = playerGroup:ComponentByName("player_name", typeof(UILabel))
	local serverName = serverGroup:ComponentByName("server_name", typeof(UILabel))
	local dataLabel1 = dataGroup:ComponentByName("data_label1", typeof(UILabel))
	local dataLabel2 = dataGroup:ComponentByName("data_label2", typeof(UILabel))
	local dataLabel3 = dataGroup:ComponentByName("data_label3", typeof(UILabel))
	dataLabel1.text = data.dressAttrs[1]
	dataLabel2.text = data.dressAttrs[2]
	dataLabel3.text = data.dressAttrs[3]
	local pIcon = PlayerIcon.new(avatarIcon)
	local isRobot = data.playerInfo.is_robot
	local playerId = data.playerInfo.player_id

	if not isRobot or isRobot == 0 or data.playerInfo.player_name then
		playerName.text = data.playerInfo.player_name

		pIcon:setInfo({
			scale = 0.7,
			avatarID = data.playerInfo.avatar_id,
			avatar_frame_id = data.playerInfo.avatar_frame_id,
			lev = data.playerInfo.lev
		})
	else
		local a_t = xyd.tables.arenaRobotTable
		playerName.text = a_t:getName(playerId)

		pIcon:setInfo({
			scale = 0.7,
			avatarID = a_t:getAvatar(playerId),
			avatar_frame_id = data.playerInfo.avatar_frame_id,
			lev = a_t:getLev(playerId)
		})
	end

	serverName.text = xyd.getServerNumber(data.playerInfo.server_id or 1)
	local styleID = {}
	local ids = xyd.tables.senpaiDressSlotTable:getIDs()

	for i = 1, #ids do
		if data.playerInfo and data.playerInfo.dress_style and data.playerInfo.dress_style[i] then
			table.insert(styleID, tonumber(data.playerInfo.dress_style[i]))
		else
			table.insert(styleID, xyd.tables.senpaiDressSlotTable:getDefaultStyle(ids[i]))
		end
	end

	self:waitForFrame(2, function ()
		local normalModel_ = import("app.components.SenpaiModel").new(senpaiNode)

		normalModel_:setModelInfo({
			ids = styleID
		})

		if data.isRight == 1 then
			senpaiNode.transform.localScale = Vector3(-0.9, 0.9, 1)
		else
			senpaiNode.transform.localScale = Vector3(0.9, 0.9, 1)
		end
	end)
end

function PvpVsWindow:willClose()
	if self.callBack then
		self.callBack()
	end

	PvpVsWindow.super.willClose(self)
end

return PvpVsWindow
