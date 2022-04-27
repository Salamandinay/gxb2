local BaseWindow = import(".BaseWindow")
local SummonResWindow = class("SummonResWindow", BaseWindow)
local Partner = import("app.models.Partner")

function SummonResWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.step = 1
	self.moveY = 0
	self.slideXY = {
		x = 0,
		y = 0
	}
	self.effectName = {
		{
			"putong04",
			"putong01",
			"putong02",
			"putong03"
		},
		{
			"putong04",
			"putong01",
			"putong02",
			"putong03"
		},
		{
			"putong04",
			"putong01",
			"putong02",
			"putong03"
		},
		{
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		},
		{
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		},
		{
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		},
		{
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		},
		{
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		},
		{
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		},
		[15] = {
			"friend04",
			"friend01",
			"friend02",
			"friend03"
		},
		[16] = {
			"friend04",
			"friend01",
			"friend02",
			"friend03"
		},
		[22] = {
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		},
		[23] = {
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		},
		[24] = {
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		},
		[25] = {
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		},
		[26] = {
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		},
		[29] = {
			"gaoji04",
			"gaoji01",
			"gaoji02",
			"gaoji03"
		}
	}
	self.data = params
end

function SummonResWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function SummonResWindow:getUIComponent()
	local go = self.window_
	self.group = go:NodeByName("group").gameObject
	self.mask_ = go:ComponentByName("group/mask_", typeof(UISprite))
	self.bgImg = go:ComponentByName("group/bgImg", typeof(UITexture))
	self.groupModel = go:NodeByName("groupModel").gameObject
	self.imgTouch = go:NodeByName("imgTouch").gameObject
	self.imgGuide = go:ComponentByName("imgGuide", typeof(UISprite))
	self.skipBtn = go:NodeByName("skipBtn").gameObject
	self.skipBtnBoxCollider = go:ComponentByName("skipBtn", typeof(UnityEngine.BoxCollider))

	if xyd.GuideController.get():isPlayGuide() then
		self.skipBtn:SetActive(false)
	else
		self.skipBtn:SetActive(true)
	end

	if xyd.isH5() then
		xyd.setUISprite(self.imgGuide, nil, "guide_girl_h5")
	end
end

function SummonResWindow:initUIComponent()
	xyd.setUITextureByNameAsync(self.bgImg, "summon_scene", false)

	local function setter(val)
		self.mask_.alpha = val
	end

	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 0.4, 0.2))
	sequence:AppendCallback(function ()
		sequence:Kill(false)
	end)
end

function SummonResWindow:playEffect(partners, summonType, callback, isSimple, enterWindowType)
	local partnerIds = {}

	for i = 1, #partners do
		table.insert(partnerIds, partners[i].table_id)
	end

	self.enterWindowType = enterWindowType
	self.data = {
		partners = partnerIds,
		summonType = summonType,
		callback = callback
	}

	if isSimple then
		self.skipBtnBoxCollider.enabled = false
	else
		self.skipBtnBoxCollider.enabled = true
	end

	local function startEffect()
		if isSimple then
			self:step5()
		else
			self.summonEffect = xyd.Spine.new(self.groupModel)

			self.summonEffect:setInfo("fx_ui_gacha_revision", function ()
				self.summonEffect:SetLocalScale(1.2, 1.2, 1)
			end)
			self:step1()
		end
	end

	local resources = xyd.getEffectFilesByNames({
		"fx_ui_gacha_revision",
		"fx_ui_newgirl_gainp",
		"fx_ui_newgirl_gaino",
		"fx_ui_newgirl_gain_star"
	})

	self:getSpriteName(resources, partners)
	self:getSoundRes(resources)

	if xyd.isAllPathLoad(resources) then
		startEffect()
	else
		ResCache.DownloadAssets("summonRes", resources, function (success)
			if tolua.isnull(self.window_) then
				return
			end

			startEffect()
		end, function (progress)
			self:showResLoading(progress)
		end, 1)
	end
end

function SummonResWindow:getSoundRes(arry)
	local SoundTable = xyd.tables.soundTable
	local sounds = {
		"3008",
		"2147",
		"3010",
		"3011"
	}

	for i = 1, #sounds do
		local path = xyd.getSoundPath(sounds[i])

		if path then
			table.insert(arry, path)
		end
	end
end

function SummonResWindow:registerEvent()
	UIEventListener.Get(self.imgTouch).onDrag = function (go, delta)
		self:onTouchMove(delta)
	end

	UIEventListener.Get(self.imgTouch).onDragEnd = function (go)
		self:onTouchEnd()
	end

	UIEventListener.Get(self.skipBtn.gameObject).onClick = handler(self, function ()
		self.isPause = true

		if self.summonEffect then
			self.summonEffect:pause()
		end

		if self.enterWindowType and self.enterWindowType == "summon_window" then
			local params = {
				type = "summon_res",
				isNoESC = true,
				wndType = self.curWindowType_,
				text = __("SUMMON_EFFECT_SKIP"),
				labelNeverText = __("GAMBLE_JUMP_CARTOON"),
				callback = function ()
					self.data.callback()
				end,
				closeFun = function ()
					if self.summonEffect then
						self.summonEffect:resume()

						self.isPause = false
					end
				end,
				selectCallback = function (state)
					if state then
						self:onClickSkip()
					end
				end
			}

			if xyd.Global.lang == "fr_fr" then
				params.tipsWidth = 476
			end

			xyd.openWindow("gamble_tips_window", params)
		else
			xyd.alert(xyd.AlertType.YES_NO, __("SUMMON_EFFECT_SKIP"), function (yes)
				if yes then
					self.data.callback()
				elseif self.summonEffect then
					self.summonEffect:resume()

					self.isPause = false
				end
			end)
		end
	end)
end

function SummonResWindow:onTouchMove(delta)
	self.slideXY = {
		x = self.slideXY.x + delta.x,
		y = self.slideXY.y + delta.y
	}
end

function SummonResWindow:onTouchEnd()
	if self.slideXY.y < -100 and self.step == 2 then
		UIEventListener.Get(self.imgTouch).onDrag = nil
		UIEventListener.Get(self.imgTouch).onDragEnd = nil

		self:step2()
	end

	self.slideXY = {
		x = 0,
		y = 0
	}
end

function SummonResWindow:stepNew()
	self.summonEffect:play("222", 1, 1, function ()
		self:step5()
	end, true)
end

function SummonResWindow:step1()
	local actionName = self.effectName[self.data.summonType][self.step]

	self.summonEffect:play(actionName, 0, 1, nil, true)

	if self.isPause and self.isPause == true then
		self.summonEffect:pause()
	end

	self.step = 2

	if xyd.GuideController.get():isPlayGuide() then
		XYDCo.WaitForTime(3, function ()
			if self.step == 2 then
				self:step2()
			end
		end, nil)
		self.imgGuide:SetActive(true)
	end
end

function SummonResWindow:step2()
	xyd.SoundManager.get():playSound("2147")
	self.imgGuide:SetActive(false)

	local actionName = self.effectName[self.data.summonType][self.step]

	self.summonEffect:play(actionName, 1, 1, function ()
		self:step3()
	end, true)

	self.step = 3
end

function SummonResWindow:step3()
	local actionName = self.effectName[self.data.summonType][self.step]

	self.summonEffect:play(actionName, 1, 1, function ()
		self:step4()
	end, true)

	self.step = 4
end

function SummonResWindow:step4()
	xyd.SoundManager.get():playSound("3010")

	local actionName = self.effectName[self.data.summonType][self.step]

	self.summonEffect:play(actionName, 1, 1, function ()
		self:step5()
	end, true)

	self.step = 5
end

function SummonResWindow:step5()
	if self.summonEffect then
		self.summonEffect:destroy()
	end

	xyd.onGetNewPartnersOrSkins({
		showRepeat = true,
		ifSummon = true,
		partners = self.data.partners,
		callback = self.data.callback
	})
end

function SummonResWindow:getSpriteName(arry, partners)
	for i = 1, #partners do
		local showID = partners[i].show_id
		showID = showID or partners[i].table_id
		local res = xyd.getPicturePath(showID)

		if xyd.arrayIndexOf(arry, res) < 0 then
			table.insert(arry, res)
		end
	end
end

function SummonResWindow:onClickSkip()
	local summonWd = xyd.WindowManager.get():getWindow("summon_window")

	if summonWd then
		summonWd:onClickSkip()
	end
end

return SummonResWindow
