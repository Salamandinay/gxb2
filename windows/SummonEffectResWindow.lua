local partnerAnimationName1 = {
	nil,
	nil,
	nil,
	nil,
	"texiao01",
	"texiao02",
	"texiao07",
	"texiao08",
	"texiao09",
	"texiao03",
	"texiao10"
}
local partnerAnimationName2 = {
	nil,
	nil,
	nil,
	nil,
	"texiao04",
	"texiao05",
	"texiao11",
	"texiao12",
	"texiao13",
	"texiao06",
	"texiao14"
}
local BaseWindow = import(".BaseWindow")
local SummonEffectResWindow = class("SummonEffectResWindow", BaseWindow)
local PartnerTable = xyd.tables.partnerTable
local PartnerSummonEffect = import("app.components.PartnerSummonEffect")

function SummonEffectResWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.effectComponemt = nil
	self.partners_ = {}
	self.destory_res_ = false
	self.ind_ = 0
	self.type_ = 0
	self.wait_ = false
	self.dialog_ = nil
	self.ifSummon = params.ifSummon
	self.needShare = false
	self.skins_ = params.skins
	self.destory_res_ = params.destory_res
	self.callback = params.callback
	self.show_res_after_skip = params.show_res_after_skip
	self.paramsItems = params.partners

	function self.callback_()
		xyd.setTouchEnable(self.skipBtn, false)
		xyd.closeWindow(self.name_)
	end

	if params.partners then
		local clip_partners = {}

		for i = 1, #params.partners do
			local id = params.partners[i]

			if not clip_partners[id] or params.showRepeat then
				clip_partners[id] = 1

				table.insert(self.partners_, id)
			end
		end
	end

	if params.partners and #params.partners == 1 then
		local star = PartnerTable:getStar(params.partners[1])

		if star >= 5 then
			self.needShare = true
		end

		if self.skins_ then
			self.needShare = true
		end
	end

	self.selfPlayer = xyd.models.selfPlayer
end

function SummonEffectResWindow:initShareBtn()
end

function SummonEffectResWindow:initShareGroup()
end

function SummonEffectResWindow:excuteCallBack(isCloseAll)
	SummonEffectResWindow.super.excuteCallBack(self, isCloseAll)

	if not isCloseAll and self.callback then
		self.callback()
	end
end

function SummonEffectResWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	self:play()
end

function SummonEffectResWindow:getUIComponent()
	local go = self.window_
	self.groupBg = go:NodeByName("groupBg").gameObject
	self.mask_ = self.groupBg:ComponentByName("mask_", typeof(UISprite))
	self.bgImg = self.groupBg:ComponentByName("bgImg", typeof(UITexture))
	self.groupModel = go:NodeByName("groupModel").gameObject
	self.touchGroup = go:NodeByName("touchGroup").gameObject
	self.skipBtn = go:NodeByName("skipBtn").gameObject
	self.effectGroup = go:NodeByName("effectGroup").gameObject
	self.effectComponemt = PartnerSummonEffect.new(self.effectGroup, self)
end

function SummonEffectResWindow:layout()
	xyd.setUITextureByNameAsync(self.bgImg, "summon_scene", false)

	if xyd.GuideController.get():isPlayGuide() then
		self.skipBtn:SetActive(false)
	else
		self.skipBtn:SetActive(true)

		if self.needShare and self.selfPlayer:checkCanShareSummon() then
			self:initShareBtn()
		end
	end

	if self.ifSummon then
		self.summonEffect_ = xyd.Spine.new(self.groupModel)

		self.summonEffect_:setInfo("fx_ui_gacha_revision", function ()
			self.summonEffect_:SetLocalScale(1.2, 1.2, 1)
		end, nil)
		self.groupModel:SetActive(false)
	end
end

function SummonEffectResWindow:registerEvent()
	UIEventListener.Get(self.touchGroup).onClick = function ()
		if not self.wait_ then
			return
		end

		self:clearDialog()

		self.wait_ = false

		if self.type_ == 0 then
			self.ind_ = self.ind_ + 1

			self:checkPlayCat(self.ind_, function ()
				self:playPartner(self.ind_)
			end)
		else
			self.ind_ = self.ind_ + 1

			self:playSkin(self.ind_)
		end
	end

	UIEventListener.Get(self.skipBtn).onClick = function ()
		if xyd.GuideController.get():isPlayGuide() then
			return
		end

		self.effectComponemt:stop()
		xyd.alert(xyd.AlertType.YES_NO, __("SUMMON_EFFECT_SKIP"), function (yes)
			if self.effectComponemt then
				self.effectComponemt:start()
			end

			if yes then
				self:clearDialog()

				if self.show_res_after_skip and self.paramsItems then
					xyd.WindowManager.get():openWindow("summon_result_window", {
						oldBaodiEnergy = 0,
						progressValue = 0,
						type = 6,
						items = {
							{
								item_num = 1,
								item_id = self.paramsItems[1]
							}
						}
					})
				end

				self:callback_()
			end
		end)
	end
end

function SummonEffectResWindow:play()
	self.type_ = 0
	self.ind_ = 1

	if self.partners_ then
		self:checkPlayCat(self.ind_, function ()
			self:playPartner(self.ind_)
		end)
	else
		self.type_ = 1

		self:playSkin(self.ind_)
	end
end

function SummonEffectResWindow:clearDialog()
	if not self.dialog_ then
		return
	end

	if self.dialog_.sound then
		xyd.SoundManager.get():stopSound(self.dialog_.sound)
	end

	if self.dialog_.timeoutId then
		XYDCo.StopWait(self.dialog_.timeoutId)
	end

	self.dialog_ = nil
end

function SummonEffectResWindow:playDialog(table_id)
	local dialog = PartnerTable:getStartDialog(table_id)

	if dialog and dialog.sound and dialog.sound ~= "" and dialog.sound ~= 0 then
		print("==============> play welcome sound" .. tostring(dialog.sound))
		xyd.SoundManager.get():playSound(dialog.sound)

		local key = "summon_play_dialog_" .. dialog.sound

		XYDCo.WaitForTime(dialog.time, function ()
			self.dialog_.sound = nil
			self.dialog_.timeoutId = nil

			self:clearDialog()
		end, key)

		dialog.timeoutId = key
		self.dialog_ = dialog
	end
end

function SummonEffectResWindow:playPartner(ind)
	if self.partners_ then
		if ind <= #self.partners_ then
			local star = PartnerTable:getStar(self.partners_[ind])

			if self.params_.partnerDatas then
				star = self.params_.partnerDatas[ind]:getStar()
			end

			if star >= 5 then
				self:playDialog(self.partners_[ind])

				local function callback()
					if star >= 11 then
						star = 11
					end

					local animation1 = partnerAnimationName1[star]
					local animation2 = partnerAnimationName2[star]
					local group = PartnerTable:getGroup(self.partners_[ind])

					if group == xyd.PartnerGroup.TIANYI then
						if star == 10 then
							animation1 = "texiao15"
							animation2 = "texiao16"
						elseif star > 10 then
							animation1 = "texiao17"
							animation2 = "texiao18"
						end
					end

					self.effectComponemt:play(animation1, 1, function ()
						if animation2 then
							self.effectComponemt:play(animation2, 0)
						end

						self.wait_ = true
					end)
				end

				self.effectComponemt:setInfo({
					table_id = self.partners_[ind],
					star = star
				}, callback)
			else
				local function callback()
					local animationname = "texiao01"
					self.ind_ = self.ind_ + 1

					if self.ifSummon then
						if self.ind_ % 2 == 0 then
							animationname = "texiao03"

							xyd.SoundManager.get():playSound(xyd.SoundID.GAIN_HERO_LEFT)
						else
							xyd.SoundManager.get():playSound(xyd.SoundID.GAIN_HERO_RIGHT)
						end
					end

					self.effectComponemt:play(animationname, 1, function ()
						self:checkPlayCat(ind + 1, function ()
							self:playPartner(ind + 1)
						end)
					end)
				end

				self.effectComponemt:setInfo({
					table_id = self.partners_[ind]
				}, callback)
			end

			return
		end

		self.type_ = 1
		self.ind_ = 1

		self:playSkin(1)
	else
		self.type_ = 1
		self.ind_ = 1

		self:playSkin(1)
	end
end

function SummonEffectResWindow:checkPlayCat(index, callback)
	local star = PartnerTable:getStar(self.partners_[index])

	if star and star >= 5 and self.ifSummon then
		self.groupModel:SetActive(true)
		self.groupBg:SetActive(true)
		self.effectGroup:SetActive(false)
		self.touchGroup:SetActive(false)
		self.summonEffect_:play("222", 1, 1, function ()
			self.touchGroup:SetActive(true)
			self.effectGroup:SetActive(true)
			callback()
		end, true)
		xyd.SoundManager.get():playSound("2148")
	else
		callback()
	end
end

function SummonEffectResWindow:getTableIDBySkinID(skin_id)
	local list = xyd.tables.partnerPictureTable:getSkinPartner(skin_id)

	if not list then
		return nil
	end

	for i = 1, #list do
		if PartnerTable:getStar(list[i]) == 5 then
			return list[i]
		end
	end

	return list[1]
end

function SummonEffectResWindow:playSkin(ind)
	if self.skins_ then
		if ind <= #self.skins_ then
			local function callback()
				self:playDialog(self:getTableIDBySkinID(self.skins_[ind]))
				self.effectComponemt:play("texiao01", 1, function ()
					self.wait_ = true

					self.effectComponemt:play("texiao04", 0, function ()
					end)
				end)
			end

			self.effectComponemt:setInfo({
				skin_id = self.skins_[ind]
			}, callback)
		elseif self.callback_ then
			self:callback_()
		end
	elseif self.callback_ then
		self:callback_()
	end
end

function SummonEffectResWindow:setWaitState(state)
	self.wait_ = state
end

function SummonEffectResWindow:FBShare()
end

function SummonEffectResWindow:drawImg()
end

function SummonEffectResWindow:sendMsg(params)
end

return SummonEffectResWindow
