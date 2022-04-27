local WinGameWindow = class("WinGameWindow", import(".BaseWindow"))
local EffectConstants = xyd.EffectConstants
local DBResManager = xyd.DBResManager
local PlayerPrefs = UnityEngine.PlayerPrefs
local cjson = require("cjson")
local SpineManager = xyd.SpineManager

function WinGameWindow:ctor(name, params)
	WinGameWindow.super.ctor(self, name, params)

	self._oldStars = 0
	self._oldBalance = 0
	self._newBalance = 0
	self._report = params.report

	if self._report.total_level == nil then
		self._totalLevelNum = 0
	else
		self._totalLevelNum = self._report.total_level
	end

	if self._report.stars == nil then
		self._starsNum = 0
	else
		self._starsNum = math.min(self._report.stars, 3)
	end

	if self._report.score == nil then
		self._scoreNum = 0
	else
		self._scoreNum = self._report.score
	end

	self._onConfirmCallback = params.onConfirmCallback
	self._shouldLogGuideLoss = params.shouldLogGuideLoss
	self._usingTimeline = {}
end

function WinGameWindow:initWindow()
	WinGameWindow.super.initWindow(self)
	self:getUIComponent()
	self:registerEvents()
	self:initUIComponent()

	if xyd.MapController.get().isInNewUserGuide and self._totalLevelNum > 4 then
		self:PreGetTurnTableDataAndLoad()
	end

	xyd.SelfInfo.get():resetLastGameChoose()
end

function WinGameWindow:getUIComponent()
	local winTrans = self.window_.transform
	self._closeBtn = winTrans:ComponentByName("e:Skin/group_bg/_closeBtn", typeof(UISprite))
	self._totalLevel = winTrans:ComponentByName("e:Skin/group_bg/_totalLevel", typeof(UILabel))
	self._star1 = winTrans:NodeByName("e:Skin/group_bg/_star1").gameObject
	self._star2 = winTrans:NodeByName("e:Skin/group_bg/_star2").gameObject
	self._star3 = winTrans:NodeByName("e:Skin/group_bg/_star3").gameObject
	self._scoreLabel = winTrans:ComponentByName("e:Skin/group_bg/_scoreLabel", typeof(UILabel))
	self._nextBtn = winTrans:NodeByName("e:Skin/group_bg/_nextBtn").gameObject
	self._nextBtnText = winTrans:ComponentByName("e:Skin/group_bg/_nextBtn/_nextBtnText", typeof(UILabel))
	self._rewardText = winTrans:ComponentByName("e:Skin/group_bg/_shareBtn/_rewardText", typeof(UILabel))
	self._shareBtn = winTrans:NodeByName("e:Skin/group_bg/_shareBtn").gameObject
	self._winEffHolder = winTrans:NodeByName("e:Skin/group_bg/_winEffHolder").gameObject
	self.group_bg = winTrans:NodeByName("e:Skin/group_bg").gameObject
	self._title_left = winTrans:ComponentByName("e:Skin/group_bg/_title_left", typeof(UILabel))
	self._title_right = winTrans:ComponentByName("e:Skin/group_bg/_title_right", typeof(UILabel))
	self._gatherTaskPanel = winTrans:NodeByName("e:Skin/group_bg/_gatherTaskPanel").gameObject
	self._rankPanel = winTrans:NodeByName("e:Skin/group_bg/_rankPanel").gameObject
	self._gatherProgressBar = winTrans:ComponentByName("e:Skin/group_bg/_gatherTaskPanel/e:Group/_gatherProgressBar", typeof(UISprite))
	self._gatherProgressMask = winTrans:ComponentByName("e:Skin/group_bg/_gatherTaskPanel/e:Group/_gatherProgressMask", typeof(UISprite))
	self._gatheredNumText = winTrans:ComponentByName("e:Skin/group_bg/_gatherTaskPanel/e:Group/_gatheredNumText", typeof(UILabel))
	self._toGatherNumText = winTrans:ComponentByName("e:Skin/group_bg/_gatherTaskPanel/_toGatherNumDesc/_toGatherNumText", typeof(UILabel))
	self._label_gather1 = winTrans:ComponentByName("e:Skin/group_bg/_gatherTaskPanel/_toGatherNumDesc/_label_gather1", typeof(UILabel))
	self._label_gather2 = winTrans:ComponentByName("e:Skin/group_bg/_gatherTaskPanel/_toGatherNumDesc/_label_gather2", typeof(UILabel))
	self._toGatherNumDesc = winTrans:NodeByName("e:Skin/group_bg/_gatherTaskPanel/_toGatherNumDesc").gameObject
	self._redPacketImg = winTrans:ComponentByName("e:Skin/group_bg/_gatherTaskPanel/e:Group/_redPacketImg", typeof(UISprite))
	self.rankingScroller = winTrans:NodeByName("e:Skin/group_bg/_rankPanel/rankingScroller").gameObject
	self.streak_group = winTrans:NodeByName("e:Skin/group_bg/streak_group").gameObject
	self.icon_streak = self.streak_group.transform:ComponentByName("icon_streak", typeof(UISprite))
	self.num_streak = self.streak_group.transform:ComponentByName("num_streak", typeof(UILabel))
	self.text_streak = self.streak_group.transform:ComponentByName("text_streak", typeof(UILabel))
end

function WinGameWindow:registerEvents()
	xyd.EventDispatcher.outer():addEventListener("GAME_WIN", handler(self, self._onGameWin))
end

function WinGameWindow:removeEventListeners()
	xyd.EventDispatcher.outer():removeEventListenersByEvent("GAME_WIN")
end

function WinGameWindow:initUIComponent()
	xyd.DataPlatform.get():request("GAME_WIN", self._report)

	self._totalLevel.text = self._totalLevelNum
	self._scoreLabel.text = self._scoreNum
	self._title_left.text = __("DI")
	self._title_right.text = __("LEVEL")
	self._label_gather1.text = __("GATHER_TIPS1")
	self._label_gather2.text = __("GATHER_TIPS2")
	self._nextBtnText.text = __("NEXT_LEVEL")
	self._rewardText.text = __("GET_WINGAME_REWARD")
	self.text_streak.text = __("CLEAR_STREAK")

	self:playWinAnimation()
end

function WinGameWindow:update(data)
	self._netData = data

	if self.isDisposed_ then
		return
	end

	xyd.setNormalBtnBehavior(self._closeBtn.gameObject, self, self._onCloseWin)
	xyd.setDarkenBtnBehavior(self._nextBtn, self, self._onNextBtn)

	self._oldStars = data.old_stars
	self._oldBalance = data.old_balance
	self._newBalance = data.new_balance

	if self._oldStars == nil then
		self._oldStars = 3
		self._oldBalance = 0
		self._newBalance = 0
	end

	local activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITY)

	if activityModel:isOpen(xyd.ActivityConstants.CLEAR_STREAK_REWARD) then
		self:initStreak(data.clear_streak)
	end

	self:starAnimation()
end

function WinGameWindow:_onGameWin(event)
	local data = event.data

	xyd.SelfInfo.get():syncData()
	self:update(data)
end

function WinGameWindow:starAnimation()
	if self._starsNum >= 1 then
		self:starSingleAnimation(self._star1, 0)
	end

	if self._starsNum >= 2 then
		self:starSingleAnimation(self._star2, 10)
	end

	if self._starsNum >= 3 then
		self:starSingleAnimation(self._star3, 20)
	end
end

function WinGameWindow:starSingleAnimation(go, startFrame)
	local sequence = DG.Tweening.DOTween.Sequence()

	table.insert(self._usingTimeline, sequence)
	go:SetActive(true)

	go.transform.localScale = Vector3(4, 4)
	local widget = go:GetComponent(typeof(UIWidget))
	widget.alpha = 0

	local function getter()
		return widget.color
	end

	local function setter(value)
		widget.color = value
	end

	sequence:Insert((11 + startFrame) * xyd.TweenDeltaTime, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 5 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert((11 + startFrame) * xyd.TweenDeltaTime, go.transform:DOScale(Vector3(0.84, 0.84, 1), 8 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert((19 + startFrame) * xyd.TweenDeltaTime, go.transform:DOScale(Vector3(1.12, 1.12, 1), 3 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert((22 + startFrame) * xyd.TweenDeltaTime, go.transform:DOScale(Vector3(1, 1, 1), 3 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
end

function WinGameWindow:playWinAnimation()
	SpineManager.get():newEffect(self._winEffHolder, EffectConstants.ANNA_WIN, function (success, eff)
		if success then
			self.winEff_ = eff
			self.winEff_.transform.localPosition = Vector3(0, -self._winEffHolder:GetComponent(typeof(UIWidget)).height / 2 - 60, 20)
			self.winEff_.transform.localScale = Vector3(100, 100, 100)
			local SpineController = self.winEff_:GetComponent(typeof(SpineAnim))
			SpineController.RenderTarget = self._closeBtn
			SpineController.targetDelta = 20

			SpineController:play("texiao01", 1)

			local onComplete = nil

			function onComplete()
				SpineController:play("texiao02", -1)
			end

			SpineController:addListener("Complete", onComplete)
		end
	end)
end

function WinGameWindow:_onNextBtn()
	self:_onCloseWin()
end

function WinGameWindow:_onCloseWin()
	if self.isDisposed_ then
		return
	end

	xyd.WindowManager.get():closeWindow("win_game_window", self._onConfirmCallback)
end

function WinGameWindow:initStreak(streakNum)
	if streakNum == 0 then
		return
	end

	local picName = "icon_liansheng"

	xyd.setUISpriteAsync(self.icon_streak, xyd.MappingData[picName], picName, function ()
		self.num_streak.text = tostring(streakNum)

		self.streak_group:SetActive(true)
		xyd.setNormalBtnBehavior(self.streak_group, self, function ()
			xyd.WindowManager.get():openWindow("clear_streak_window")
		end)
	end)
end

function WinGameWindow:PreLoadTurnTablePics(data)
	for i = 1, #data do
		local picName = data[i].icon
		local md5 = data[i].md5

		if md5 and picName and not UNITY_EDITOR and not UNITY_STANDALONE then
			local path = "TurntableGift_web/" .. md5 .. "/" .. picName

			if not FileUtils.IsResInData(string.lower(path) .. ".bytes") then
				local url = XYDUtils.CdnUrl() .. "Android/" .. picName .. ".bytes." .. md5

				__TRACE(url, "preload gift Texture  ============================")
				ResManager.DownloadRes(url, md5, string.lower(path) .. ".bytes", function (status)
				end)
			end
		end
	end
end

function WinGameWindow:PreGetTurnTableDataAndLoad()
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

	if turntableData ~= nil and turntableData ~= "" then
		local data = cjson.decode(turntableData)

		self:PreLoadTurnTablePics(data)
	else
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

				if table_date ~= nil and table_date ~= "" then
					xyd.TURNTABLE_VERSION = version
					local resJson = cjson.encode(table_date)

					PlayerPrefs.SetString("turntable_data", resJson)
					PlayerPrefs.SetInt("turntable_version", version)
					self:PreLoadTurnTablePics(table_date)
				end
			end
		end

		xyd.Backend.get():webRequest(url, params, callback)
	end
end

function WinGameWindow:dispose()
	self:removeEventListeners()

	self._onConfirmCallback = nil

	for _, sq in ipairs(self._usingTimeline) do
		sq:Kill(true)
	end

	self._usingTimeline = {}

	if self.winEff_ ~= nil then
		SpineManager.get():pushEffect(self.winEff_)
	end

	WinGameWindow.super.dispose(self)
end

return WinGameWindow
