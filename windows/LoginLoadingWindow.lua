local LoginLoadingWindow = class("LoginLoadingWindow", import(".BaseWindow"))
local CustomBackgroundTable = xyd.tables.customBackgroundTable
local MonsterTable = xyd.tables.monsterTable
local EquipTable = xyd.tables.equipTable
local PartnerTable = xyd.tables.partnerTable
local PetTable = xyd.tables.petTable
local ModelTable = xyd.tables.modelTable
local SkillTable = xyd.tables.skillTable
local SoundTable = xyd.tables.soundTable
local ResourceEffectTable = xyd.tables.resourceEffectTable

function LoginLoadingWindow:ctor(name, params)
	LoginLoadingWindow.super.ctor(self, name, params)

	self.totalResUrls_ = {}
	self.progress_ = 0
	self.basicProgress_ = 0
	self.modelProgress_ = 0
	self.preloadProgress_ = 0
	self.battleComplete_ = false
	self.basicComplete_ = false
	self.tweenToProgress_ = 0
	self.currRealProgress_ = 0
	self.startTime_ = 0
	self.curTipsID_ = 0
	self.tipsTimeKey = -1
	self.isProgressComplete_ = false
	self.callback = params.callback
	self.oldTime_ = 0
	self.sounds = {}
	self.battleSound = 0
	self.selectSoundPos = 0
	self.clearRes_ = {}
	self.groupNames_ = {}
	self.others = {}

	if params.others then
		self.others = params.others
	end
end

function LoginLoadingWindow:willClose()
	LoginLoadingWindow.super.willClose(self)
end

function LoginLoadingWindow:adaptX()
	local height = math.min(UnityEngine.Screen.height, xyd.Global.getMaxBgHeight())

	print(height)

	if xyd.Global.getMaxHeight() <= height then
		self.groupBot_:GetComponent(typeof(UIWidget)):SetBottomAnchor(self.window_, 0, -(height - xyd.Global.getMaxHeight()) / 2)
	end
end

function LoginLoadingWindow:initWindow()
	LoginLoadingWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	xyd.DownloadController.get():stopDownload()
end

function LoginLoadingWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupMain_ = winTrans:NodeByName("groupMain_").gameObject
	self.bg_ = self.groupMain_:ComponentByName("bg_", typeof(UITexture))
	self.groupBot_ = self.groupMain_:NodeByName("groupBot_").gameObject
	self.bar_ = self.groupBot_:ComponentByName("bar_", typeof(UISlider))
	self.effectGroup = self.groupMain_:NodeByName("effectGroup").gameObject
	self.lableTop_ = self.groupMain_:ComponentByName("lableTop_", typeof(UILabel))
end

function LoginLoadingWindow:layout()
	if self.startTime_ == 0 then
		self.startTime_ = os.time()
	end

	local labelBar = self.bar_:ComponentByName("labelDisplay", typeof(UILabel))

	XYDUtils.AddEventDelegate(self.bar_.onChange, function ()
		local val = self.bar_.value
		local str = tostring(math.floor(val * 100)) .. "%"
		str = "Now loading...  " .. tostring(str)
		labelBar.text = str
	end)
	self.groupBot_:SetActive(true)
	self:setBattleData()
end

function LoginLoadingWindow:setBattleData(data)
	self.data_ = data

	self:checkComplete()

	local subNames = {}

	self:loadBattleResource(subNames, self.others)
end

function LoginLoadingWindow:loadBattleResource(groupNames, others)
	self.groupNames_ = groupNames

	local function completeFunc(isSuccess)
		if not isSuccess then
			xyd.alert(xyd.AlertType.TIPS, __("LOGIN_LOADING_FAIL"))
			xyd.WindowManager.get():closeWindow(self.name_)
		else
			self:preLoadRes()
		end
	end

	local function progressFunc(progress)
		local val = 100 * progress
		self.modelProgress_ = val

		self:changeProgress()
	end

	dump(others)

	self.totalResUrls_ = others

	ResCache.DownloadAssets("battle_load_res", others, completeFunc, progressFunc, 0.1)
end

function LoginLoadingWindow:preLoadRes()
	ResManager.PreloadABsByPathAsync("battle_effect_pre_load_urls" .. xyd.getServerTime(), self.totalResUrls_, function ()
		self.battleComplete_ = true

		self:checkComplete()
	end, function (progress)
		local val = 100 * progress
		self.preloadProgress_ = val

		self:changeProgress2()
	end)
end

function LoginLoadingWindow:initEffectData()
	local groupNames = self.groupNames_

	for i = 1, #groupNames do
		local names = ResourceEffectTable:getResNames(groupNames[i])

		for _, name in ipairs(names) do
			-- Nothing
		end
	end
end

function LoginLoadingWindow:changeProgress()
	local progress = self.modelProgress_ * 0.85

	self:updateBar(progress)
end

function LoginLoadingWindow:changeProgress2()
	local progress = self.preloadProgress_ * 0.1 + 85

	self:updateBar(progress)
end

function LoginLoadingWindow:changeProgress3()
	self:updateBar(100)
end

function LoginLoadingWindow:updateBar(progress)
	self:playAction(progress)
end

function LoginLoadingWindow:playAction(val)
	local bar = self.bar_

	if self.action then
		self.action:Pause()
		self.action:Kill(false)

		self.action = nil
	end

	local function setter(value)
		bar.value = value
	end

	local curVal = bar.value
	local newVal = tonumber(val) / 100
	local sequence1 = DG.Tweening.DOTween.Sequence()

	sequence1:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), curVal, newVal, 1):SetEase(DG.Tweening.Ease.Linear))
	sequence1:AppendCallback(function ()
		if val == 100 then
			self.isProgressComplete_ = true

			if self.callback then
				self.callback()
			end
		end
	end)

	self.action = sequence1
end

function LoginLoadingWindow:checkComplete()
	if self.battleComplete_ and not self.isOpenBattle_ then
		self.isOpenBattle_ = true

		self:changeProgress3()
		xyd.DownloadController.get():resumeDownload()
	end
end

function LoginLoadingWindow:setCallBack(callback)
	if self.isProgressComplete_ then
		callback()
	else
		self.callback = callback
	end
end

return LoginLoadingWindow
