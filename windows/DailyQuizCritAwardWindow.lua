local BaseWindow = import(".BaseWindow")
local DailyQuizCritAwardWindow = class("DailyQuizCritAwardWindow", BaseWindow)
local DailyQuiz = xyd.models.dailyQuiz

function DailyQuizCritAwardWindow:ctor(name, params)
	self.otherFx = {
		"huodewupin"
	}
	self.data_ = {}
	self.items_ = {}
	self.quiz_type = 1
	self.callback = nil
	self.showBtn_ = true

	DailyQuizCritAwardWindow.super.ctor(self, name, params)

	self.data_ = params.data
	self.quiz_type = params.quiz_type
	self.callback = params.callback
end

function DailyQuizCritAwardWindow:initWindow()
	DailyQuizCritAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:loadEffects()
	self:registerEvent()
end

function DailyQuizCritAwardWindow:getUIComponent()
	local trans = self.window_.transform
	local groupMain = trans:NodeByName("groupMain_").gameObject
	self.scroller = groupMain:NodeByName("scroller").gameObject
	self.groupItems_ = self.scroller:NodeByName("groupItems_")
	self.groupItems_grid = self.scroller:ComponentByName("groupItems_", typeof(UIGrid))
	self.groupOne_ = groupMain:NodeByName("groupOne_")
	self.groupOne_grid = groupMain:ComponentByName("groupOne_", typeof(UIGrid))
	self.groupBtns_ = groupMain:NodeByName("groupBtns_").gameObject
	self.effectRoot = groupMain:ComponentByName("effect", typeof(UISprite))
	self.textImg = groupMain:ComponentByName("textImg", typeof(UITexture))

	xyd.setUITextureByNameAsync(self.textImg, "huodewupin_" .. xyd.Global.lang, true)

	self.btnSure_ = self.groupBtns_:ComponentByName("btnSure_", typeof(UISprite))
	self.btnNext_ = self.groupBtns_:ComponentByName("btnNext_", typeof(UISprite))
	self.btnSureLabel = self.btnSure_:ComponentByName("btnSureLabel", typeof(UILabel))
	self.btnNextLabel = self.btnNext_:ComponentByName("btnNextLabel", typeof(UILabel))
end

function DailyQuizCritAwardWindow:willClose()
	DailyQuizCritAwardWindow.super.willClose(self)

	self.huodeWuPinEffect_ = nil
end

function DailyQuizCritAwardWindow:layout()
	self.btnSureLabel.text = __("CONFIRM")

	self.groupBtns_:SetActive(false)

	self.btnNextLabel.text = __("NEXT_BATTLE")

	if not DailyQuiz:isHasLeftTimes(self.quiz_type) then
		local pos = self.btnSure_.transform.localPosition

		self.btnSure_:SetLocalPosition(0, pos.y, pos.z)
		self.btnNext_:SetActive(false)
	end

	self.groupItems_.gameObject:SetActive(false)
end

function DailyQuizCritAwardWindow:loadEffects()
	local callback = nil

	function callback()
		self:playAnimation()
	end

	callback()
end

function DailyQuizCritAwardWindow:initData()
	if tolua.isnull(self.window_) then
		return
	end

	for i = 1, #self.data_ do
		local item = self.data_[i]
		local icon = xyd.getItemIcon({
			itemID = item.item_id,
			num = tonumber(item.item_num),
			uiRoot = self.groupOne_.gameObject,
			scale = Vector3(0.02, 0.02, 0.02)
		})
		icon.name = "daily_quiz_icon"

		table.insert(self.items_, {
			obj = icon:getIconRoot(),
			item = item
		})
	end

	if #self.data_ > 5 then
		self.groupOne_grid.cellWidth = 115
	end

	self.groupOne_grid:Reposition()
end

function DailyQuizCritAwardWindow:playAnimation()
	local function playNormal(obj, callback)
		xyd.SoundManager.get():playSound(xyd.SoundID.GAMEBLE_NORMAL)
		obj.gameObject:SetActive(true)

		obj.transform.localScale = Vector3(0.36, 0.36, 0.36)
		local sequeneNormal = DG.Tweening.DOTween.Sequence()

		sequeneNormal:Append(obj.transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.13))
		sequeneNormal:Append(obj.transform:DOScale(Vector3(0.9, 0.9, 0.9), 0.16))
		sequeneNormal:Append(obj.transform:DOScale(Vector3(1, 1, 1), 0.16))
		sequeneNormal:AppendCallback(function ()
			if callback then
				callback()
			end
		end)
		sequeneNormal:SetAutoKill(true)
	end

	local function play(actions)
		for i, data in ipairs(actions) do
			local item = data.item
			local obj = data.obj

			if i < #actions then
				self:setTimeout(function ()
					playNormal(obj)
				end, obj, 100 * i)
			else
				local function callback()
					self.groupBtns_:SetActive(true)
				end

				self:setTimeout(function ()
					playNormal(obj, callback)
				end, obj, 100 * i)
			end
		end
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.GAMBLE_REWARDS)

	if not self.huodeWuPinEffect_ then
		local effect = xyd.Spine.new(self.effectRoot.gameObject)

		effect:setInfo("huodewupin", function ()
			effect:SetLocalScale(1, 1, 1)
			effect:changeAttachment("zi1", self.textImg)
			effect:setRenderTarget(self.effectRoot, 1)
			effect:play("texiao01", 1, 1, handler(self, function ()
				self:initData()

				local actions = self.items_

				self:setTimeout(play(actions), self, 300)
				effect:play("texiao02", 0)
			end))
		end)

		self.huodeWuPinEffect_ = effect

		return
	end

	self.huodeWuPinEffect_:play("texiao01", 1, 1, function ()
		self:initData()

		local actions = self.items_

		self:setTimeout(play(actions), self, 300)
		self.huodeWuPinEffect_:play("texiao02", 0)
	end)
end

function DailyQuizCritAwardWindow:registerEvent()
	DailyQuizCritAwardWindow.super.register(self)

	UIEventListener.Get(self.btnSure_.gameObject).onClick = handler(self, self.sureTouch)
	UIEventListener.Get(self.btnNext_.gameObject).onClick = handler(self, self.initNextBtn)
end

function DailyQuizCritAwardWindow:initNextBtn()
	if DailyQuiz:isHasLeftTimes(self.quiz_type) then
		xyd.WindowManager:get():closeWindow("daily_quiz_crit_award_window")
		DailyQuiz:nextSweep()
	end
end

function DailyQuizCritAwardWindow:sureTouch()
	xyd.WindowManager:get():closeWindow("daily_quiz_crit_award_window")
end

return DailyQuizCritAwardWindow
