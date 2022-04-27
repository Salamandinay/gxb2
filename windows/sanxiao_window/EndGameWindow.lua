local EndGameWindow = class("EndGameWindow", import(".BaseWindow"))
local MovesTargetComponent = import("app.components.MovesTargetComponent")
local ObjectTargetComponent = import("app.components.ObjectTargetComponent")
local SpineManager = xyd.SpineManager
local EffectConstants = xyd.EffectConstants
local MiscTable = xyd.tables.misc
local PlayerPrefs = UnityEngine.PlayerPrefs
local cjson = require("cjson")

function EndGameWindow:ctor(name, params)
	EndGameWindow.super.ctor(self, name, params)

	self._gameEndCallback = params.gameEndCallback
	self._gameResumeCallback = params.gameResumeCallback
	self._gameMode = params.gameMode
	self._report = params.report
	self._selfLevel = xyd.SelfInfo.get():getCurrentLevel()
	self._needPopup = false
	self._needPopupClearStreak = false
	self._canShare = false
	self._usingTimeline = {}
	local table_info = MiscTable:getData("level_five_steps_cost", "k1")
	local costs = string.split(table_info, "|")
	xyd.SelfInfo.get().addMovesTime = xyd.SelfInfo.get().addMovesTime + 1
	self.cost = tonumber(costs[xyd.SelfInfo.get().addMovesTime])

	if xyd.SelfInfo.get().addMovesTime >= #costs then
		self.cost = tonumber(costs[#costs])
	end
end

function EndGameWindow:initWindow()
	EndGameWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()

	local activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITY)

	if activityModel:isOpen(xyd.ActivityConstants.CLEAR_STREAK_REWARD) then
		self:initClearStreakInfo()
	end
end

function EndGameWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_bg = winTrans:NodeByName("e:Skin/group_bg").gameObject
	self._title = winTrans:ComponentByName("e:Skin/group_bg/_title", typeof(UILabel))
	self.group_mission = winTrans:NodeByName("e:Skin/group_mission").gameObject
	self._label_gather1 = winTrans:ComponentByName("e:Skin/group_mission/_label_gather1", typeof(UILabel))
	self._label_gather2 = winTrans:ComponentByName("e:Skin/group_mission/_label_gather2", typeof(UILabel))
	self._label_gather3 = winTrans:ComponentByName("e:Skin/group_mission/_label_gather3", typeof(UILabel))
	self._targetImg = winTrans:NodeByName("e:Skin/group_mission/_targetImg").gameObject
	self._targetNum = winTrans:NodeByName("e:Skin/group_mission/_targetNum").gameObject
	self.group_clearstreak = winTrans:NodeByName("e:Skin/group_clearstreak").gameObject
	self._icon_reward = winTrans:ComponentByName("e:Skin/group_clearstreak/e:Group/_icon_reward", typeof(UISprite))
	self._label_desc = winTrans:ComponentByName("e:Skin/group_clearstreak/_label_desc", typeof(UILabel))
	self._closeBtn = winTrans:NodeByName("e:Skin/group_bg/_closeBtn").gameObject
	self._chickHolder = winTrans:NodeByName("e:Skin/group_bg/_chickHolder").gameObject
	self._shareBtn = winTrans:NodeByName("e:Skin/group_bg/_shareBtn").gameObject
	self._shareText = winTrans:ComponentByName("e:Skin/group_bg/_shareBtn/_shareText", typeof(UILabel))
	self._withdrawBtn = winTrans:NodeByName("e:Skin/group_bg/_withdrawBtn").gameObject
	self._label_withdraw = winTrans:ComponentByName("e:Skin/group_bg/_withdrawBtn/_label_withdraw", typeof(UILabel))
	self._targetGroup = winTrans:NodeByName("e:Skin/group_bg/_targetGroup").gameObject
	self._reasonGroup = winTrans:NodeByName("e:Skin/group_bg/_reasonGroup").gameObject
	self._reason_label = winTrans:NodeByName("e:Skin/group_bg/_reasonGroup/_reason_label").gameObject
	self._reason_img_bomb = winTrans:NodeByName("e:Skin/group_bg/_reasonGroup/_reason_img_bomb").gameObject
	self._reason_img_swap = winTrans:NodeByName("e:Skin/group_bg/_reasonGroup/_reason_img_swap").gameObject
	self._reason_img_color_mixer = winTrans:NodeByName("e:Skin/group_bg/_reasonGroup/_reason_img_color_mixer").gameObject
	self._bubble1 = winTrans:NodeByName("e:Skin/group_mission/_bubble1").gameObject
	self._bubble2 = winTrans:NodeByName("e:Skin/group_clearstreak/_bubble2").gameObject
	self.win_bg = winTrans:ComponentByName("e:Skin/group_bg/win_bg", typeof(UISprite))
	self._turntableBtn = winTrans:NodeByName("e:Skin/group_bg/_turntableBtn").gameObject
	self._label_turntable = winTrans:ComponentByName("e:Skin/group_bg/_turntableBtn/_label_turntable", typeof(UILabel))
	self._turntableBtnImg = winTrans:ComponentByName("e:Skin/group_bg/_turntableBtn/btnImg", typeof(UISprite))
	self.turntableBtnCollider = self._turntableBtn:GetComponent(typeof(UnityEngine.BoxCollider))
end

function EndGameWindow:onClickShareBtn()
	if not self.isDisposed_ then
		self:_onShareSuccess()
	end
end

function EndGameWindow:initClearStreakInfo()
	local clearStreakNum = xyd.SelfInfo.get():getClearStreak()

	if clearStreakNum >= 1 then
		self._needPopupClearStreak = true
		local num = math.min(5, clearStreakNum)

		xyd.setUISprite(self._icon_reward, "Game_web", "icon_jiangli" .. tostring(num))
		self._icon_reward:MakePixelPerfect()

		local desc1 = "[8a5036]" .. __("ENDGAME_CLEARSTREAK_TIPS1") .. "[-]"
		local desc2 = "[eb2802]" .. __("ENDGAME_CLEARSTREAK_TIPS2") .. "[-]"
		local desc3 = "[8a5036]" .. __("EXCLAMATION_MARK") .. "[-]"
		self._label_desc.text = desc1 .. desc2 .. desc3
	end
end

function EndGameWindow:initUIComponent()
	xyd.setDarkenBtnBehavior(self._closeBtn, self, self._onWithdrawBtnClick)
	xyd.setDarkenBtnBehavior(self._withdrawBtn, self, self._onWithdrawBtnClick)
	xyd.setDarkenBtnBehavior(self._turntableBtn, self, self._onTurntableBtnClick)

	local isExtraMovesPossiblePass = true

	if self._report.end_reason == xyd.GameEndReason.NoPossibleMoves then
		self._reasonGroup:SetActive(true)
		self._targetGroup:SetActive(false)

		self._reason_label:GetComponent(typeof(UILabel)).text = __("ENDGAME_REASON_NOPOSSIBLEMOVES")

		self._reason_img_swap:SetActive(true)
		self._reason_img_bomb:SetActive(false)

		isExtraMovesPossiblePass = false
	elseif self._report.end_reason == xyd.GameEndReason.TimeBombExploded then
		self._reasonGroup:SetActive(true)
		self._targetGroup:SetActive(false)

		self._reason_label:GetComponent(typeof(UILabel)).text = __("ENDGAME_REASON_BOMB")

		self._reason_img_bomb:SetActive(true)
		self._reason_img_swap:SetActive(false)
	elseif self._report.end_reason == xyd.GameEndReason.ColorMixerDestroyed then
		self._reasonGroup:SetActive(true)
		self._targetGroup:SetActive(false)

		self._reason_label:GetComponent(typeof(UILabel)).text = __("ENDGAME_REASON_COLORMIXER")

		self._reason_img_color_mixer:SetActive(true)
		self._reason_img_swap:SetActive(false)

		isExtraMovesPossiblePass = false
	end

	if isExtraMovesPossiblePass then
		xyd.setDarkenBtnBehavior(self._shareBtn, self, self.onClickShareBtn)
		self._shareBtn:SetActive(true)

		if xyd.TURNTABLE_ON and not xyd.MainController.get().alreadyTurntableAwarded and not xyd.MapController.get().isInNewUserGuide then
			self._turntableBtn:SetActive(true)
		end

		self._canShare = true
	else
		self._withdrawBtn.transform.localPosition = Vector3(0, self._withdrawBtn.transform.localPosition.y)
	end

	local mode = self._report.mode

	if mode == xyd.GameModeConstants.CLASSIC_MOVES then
		local score = self._report.score
		local targetScore = self._report.lowest_score_target or 0

		MovesTargetComponent.new({
			score = score,
			targetScore = targetScore
		}, self._targetGroup)
	elseif mode == xyd.GameModeConstants.LEAF then
		local score = self._report.leaf_target - self._report.leaf_remain
		local targetScore = self._report.leaf_target

		ObjectTargetComponent.new({
			targetType = "leaf",
			targetStatus = 0,
			score = score,
			targetScore = targetScore
		}, self._targetGroup)
	elseif mode == xyd.GameModeConstants.LEAF_OBJECTIVE then
		local objs = self._report[xyd.GameEndInfo.OBJECTIVES_REMAIN]
		local objTargets = self._report[xyd.GameEndInfo.OBJECTIVES_TARGET]

		for key, _ in pairs(objs) do
			local num = objTargets[key] - objs[key]
			local targetNum = objTargets[key]

			ObjectTargetComponent.new({
				score = num,
				targetScore = targetNum,
				targetStatus = targetNum <= num and 1 or 0,
				targetType = key
			}, self._targetGroup)
		end

		local score = self._report.leaf_target - self._report.leaf_remain
		local targetScore = self._report.leaf_target

		ObjectTargetComponent.new({
			targetType = "leaf",
			targetStatus = 0,
			score = score,
			targetScore = targetScore
		}, self._targetGroup)
	elseif mode == xyd.GameModeConstants.OBJECTIVE then
		local objs = self._report[xyd.GameEndInfo.OBJECTIVES_REMAIN]
		local objTargets = self._report[xyd.GameEndInfo.OBJECTIVES_TARGET]

		for key in pairs(objs) do
			local num = objTargets[key] - objs[key]
			local targetNum = objTargets[key]

			ObjectTargetComponent.new({
				score = num,
				targetScore = targetNum,
				targetStatus = targetNum <= num and 1 or 0,
				targetType = key
			}, self._targetGroup)
		end
	elseif mode == xyd.GameModeConstants.LAMP then
		local lampTarget = self._report.lamp_target
		local lampRemain = self._report.lamp_remain
		local lampScore = {
			lampTarget[1] - lampRemain[1],
			lampTarget[2] - lampRemain[2]
		}

		if lampTarget[1] > 0 then
			ObjectTargetComponent.new({
				targetType = "lamp1",
				score = lampScore[1],
				targetScore = lampTarget[1],
				targetStatus = lampScore[1] == lampTarget[1] and 1 or 0
			}, self._targetGroup)
		end

		if lampTarget[2] > 0 then
			ObjectTargetComponent.new({
				targetType = "lamp2",
				score = lampScore[2],
				targetScore = lampTarget[2],
				targetStatus = lampScore[2] == lampTarget[2] and 1 or 0
			}, self._targetGroup)
		end
	end

	self._targetGroup:GetComponent(typeof(UIGrid)):Reposition()

	self._title.text = __("GAME_FAILED")
	self._shareText.text = tostring(self.cost) .. __("ITEM_NAME_3002")
	self._label_withdraw.text = __("WITHDRAW")
	self._label_gather1.text = __("ENDGAME_GATHER_TIPS1")
	self._label_gather2.text = __("ENDGAME_GATHER_TIPS2")
	self._label_gather3.text = __("ENDGAME_GATHER_TIPS3")
	self._label_turntable.text = __("ENTER_TURNTABLE")

	self:playLoseAnimation()
end

function EndGameWindow:playLoseAnimation()
	SpineManager.get():newEffect(self._chickHolder, EffectConstants.ANNA_LOSE, function (success, eff)
		if success then
			self.chickenLose_ = eff
			self.chickenLose_.transform.localPosition = Vector3(0, -self._chickHolder:GetComponent(typeof(UIWidget)).height / 2 - 175, 20)
			self.chickenLose_.transform.localScale = Vector3(130, 130, 100)
			local SpineController = self.chickenLose_:GetComponent(typeof(SpineAnim))
			SpineController.RenderTarget = self._closeBtn:GetComponent(typeof(UISprite))
			SpineController.targetDelta = 10

			SpineController:play("texiao01", -1)
		end
	end)
end

function EndGameWindow:_onShareSuccess()
	self:_disableBtns()

	local playerInfoModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYER_INFO)

	if self.cost <= playerInfoModel.data.gems then
		self._gameResumeCallback(5)
		playerInfoModel:addGem(-self.cost)
		xyd.WindowManager:get():closeWindow("end_game_window")
	else
		self:_onWithdrawBtnClick()
	end
end

function EndGameWindow:_onWithdrawBtnClick()
	xyd.SelfInfo.get().addMovesTime = 0

	if self._needPopupClearStreak and not self.group_clearstreak.activeSelf then
		self:_onWithdrawAnimation(self.group_clearstreak, self._bubble2)
		self._chickHolder.transform:DOLocalMoveX(180, 10 * xyd.TweenDeltaTime)
	elseif self._needPopup and self._canShare and not self.group_mission.activeSelf and not self.group_clearstreak.activeSelf then
		self:_onWithdrawAnimation(self.group_mission, self._bubble1)
		self._chickHolder.transform:DOLocalMoveX(180, 10 * xyd.TweenDeltaTime)
	else
		self:_disableBtns()
		self.group_mission:SetActive(false)
		self.group_clearstreak:SetActive(false)
		xyd.WindowManager.get():closeWindow("end_game_window", function ()
			if self._gameEndCallback then
				self._gameEndCallback()
			end
		end)
	end
end

function EndGameWindow:_onWithdrawAnimation(group, bubble)
	local old_group_scale = group.transform.localScale
	local old_bubble_scale = bubble.transform.localScale
	local group_widget = group:GetComponent(typeof(UIWidget))

	group:SetActive(true)

	group_widget.alpha = 0
	group.transform.localScale = old_group_scale * 0.1
	local sequence = DG.Tweening.DOTween.Sequence()

	table.insert(self._usingTimeline, sequence)

	local function getter()
		return group_widget.color
	end

	local function setter(value)
		group_widget.color = value
	end

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 10 * xyd.TweenDeltaTime))
	sequence:Insert(0, group.transform:DOScale(old_group_scale, 10 * xyd.TweenDeltaTime))
	sequence:AppendCallback(function ()
		local sequence = DG.Tweening.DOTween.Sequence()

		table.insert(self._usingTimeline, sequence)
		sequence:Insert(0, bubble.transform:DOScale(old_bubble_scale * 1.02, 35 * xyd.TweenDeltaTime))
		sequence:Insert(35 * xyd.TweenDeltaTime, bubble.transform:DOScale(old_bubble_scale, 35 * xyd.TweenDeltaTime))
		sequence:SetLoops(-1, DG.Tweening.LoopType.Yoyo)
	end)
end

function EndGameWindow:_onTurntableBtnClick()
	if not self.isDisposed_ then
		self.turntableBtnCollider.enabled = false
		local turntableData = PlayerPrefs.GetString("turntable_data")
		local turntableVersion = PlayerPrefs.GetInt("turntable_version")
		local force = false

		if turntableData == nil or turntableData == "" then
			force = true
		end

		local version = nil

		if turntableVersion and xyd.TURNTABLE_VERSION <= turntableVersion then
			version = turntableVersion
		else
			version = xyd.TURNTABLE_VERSION
		end

		local url = xyd.LoadingController.get():backendURL()
		local params = {
			mid = xyd.mid.GET_TURNTABLE_TABLE,
			token = xyd.Global.token,
			force = force,
			table_version = version
		}

		local function callback(response, success)
			if success then
				local version = response.payload.version
				local table_date = response.payload.table_data
				local can_init = response.payload.can_init

				if can_init then
					if table_date ~= nil and table_date ~= "" then
						xyd.TURNTABLE_VERSION = version
						local resJson = cjson.encode(table_date)

						PlayerPrefs.SetString("turntable_data", resJson)
						PlayerPrefs.SetInt("turntable_version", version)
						self:_onTurntableSuccess(table_date)
					elseif turntableData ~= nil and turntableData ~= "" then
						local data = cjson.decode(turntableData)

						self:_onTurntableSuccess(data)
					else
						self:AlertWindow(2)
					end
				else
					self:AlertWindow(1)
				end
			else
				self:AlertWindow(2)
			end
		end

		xyd.Backend.get():webRequestWithLoadSprite(url, params, callback, self._turntableBtnImg, 20, 0, 580, 1.5, self.window_)
	end
end

function EndGameWindow:_onTurntableSuccess(data)
	self:_disableBtns()
	xyd.WindowManager:get():openWindow("turntable_window", {
		gameMode = self._gameMode,
		endGameWindow = self,
		turntableData = data
	})
	self.window_:SetActive(false)
end

function EndGameWindow:AlertWindow(val)
	if val == 1 then
		UIManager.ShowConfirmAlert("", __("TURNTABLE_LIMITED"), __("OK"), false, function ()
			self.turntableBtnCollider.enabled = false
		end)
	elseif val == 2 then
		UIManager.ShowAlert("", __("NOT_CONNECTED"), __("RESTART"), __("WITHDRAW"), false, function (yes)
			if yes then
				self:_onTurntableBtnClick()
			else
				self.turntableBtnCollider.enabled = true
			end
		end)
	end
end

function EndGameWindow:TurntableReturn(val)
	if val == 1 then
		self._gameResumeCallback(0)
		xyd.WindowManager:get():closeWindow("end_game_window")
	elseif val == 2 then
		self.window_:SetActive(true)
		xyd.WindowManager:get():updateWindow("end_game_window", nil, function ()
			self:_enableBtnsAfterReactive()
		end)
		self._turntableBtn:SetActive(false)
	elseif val == 3 then
		self.window_:SetActive(true)
		xyd.WindowManager:get():updateWindow("end_game_window", nil, function ()
			self:_enableBtnsAfterReactive()
		end)
	end
end

function EndGameWindow:_enableBtnsAfterReactive()
	if tolua.isnull(self._shareBtn) then
		self._shareBtn = winTrans:NodeByName("e:Skin/group_bg/_shareBtn").gameObject
	end

	if tolua.isnull(self._withdrawBtn) then
		self._withdrawBtn = winTrans:NodeByName("e:Skin/group_bg/_withdrawBtn").gameObject
	end

	if tolua.isnull(self._closeBtn) then
		self._closeBtn = winTrans:NodeByName("e:Skin/group_bg/_closeBtn").gameObject
	end

	if tolua.isnull(self._turntableBtn) then
		self._turntableBtn = winTrans:NodeByName("e:Skin/group_bg/_turntableBtn").gameObject
	end

	self._shareBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	self._withdrawBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	self._closeBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	self._turntableBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
end

function EndGameWindow:_disableBtns()
	if not tolua.isnull(self._shareBtn) then
		self._shareBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end

	self._withdrawBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self._closeBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

	if not tolua.isnull(self.turntableBtnCollider) then
		self.turntableBtnCollider.enabled = false
	end
end

function EndGameWindow:_enableBtns()
	if not tolua.isnull(self._shareBtn) then
		self._shareBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end

	self._withdrawBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	self._closeBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

	if not tolua.isnull(self.turntableBtnCollider) then
		self.turntableBtnCollider.enabled = true
	end
end

function EndGameWindow:dispose()
	for _, sq in ipairs(self._usingTimeline) do
		sq:Kill(true)
	end

	self._usingTimeline = {}

	if self.chickenLose_ ~= nil then
		SpineManager.get():pushEffect(self.chickenLose_)
	end

	EndGameWindow.super.dispose(self)
end

return EndGameWindow
