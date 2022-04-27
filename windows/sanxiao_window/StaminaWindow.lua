local StaminaWindow = class("StaminaWindow", import(".BaseWindow"))
local MiscTable = xyd.tables.misc

function StaminaWindow:ctor(name, params)
	StaminaWindow.super.ctor(self, name, params)

	self._isBuyed = false
end

function StaminaWindow:initWindow()
	StaminaWindow.super.initWindow(self)
	self:registerEvents()
	self:getUIComponent()
	self:initUIComponent()
end

function StaminaWindow:registerEvents()
	self.eventProxy_:addEventListener(xyd.event.UPDATE_STAMINA_NUM, handler(self, self.updateStamina))
	self.eventProxy_:addEventListener(xyd.event.UPDATE_STAMINA_TIME, handler(self, self.updateStaminaTime))
end

function StaminaWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_all = winTrans:NodeByName("group_all").gameObject
	self.btn_close = winTrans:NodeByName("group_all/btn_close").gameObject
	self.title_more = winTrans:NodeByName("group_all/title_more").gameObject
	self.title_full = winTrans:NodeByName("group_all/title_full").gameObject
	self.bg_full = winTrans:ComponentByName("group_all/bg_full", typeof(UISprite))
	self.text_full = winTrans:NodeByName("group_all/text_full").gameObject
	self.btn_continue = winTrans:NodeByName("group_all/btn_continue").gameObject
	self.btn_askfor = winTrans:NodeByName("group_all/btn_askfor").gameObject
	self.btn_buy_all = winTrans:NodeByName("group_all/btn_buy_all").gameObject
	self.item_label = winTrans:ComponentByName("group_all/btn_buy_all/item_label", typeof(UILabel))
	self.label_btn_continue = winTrans:ComponentByName("group_all/btn_continue/btn_label", typeof(UILabel))
	self.label_btn_askfor = winTrans:ComponentByName("group_all/btn_askfor/btn_label", typeof(UILabel))
	self.label_btn_buy_all = winTrans:ComponentByName("group_all/btn_buy_all/btn_label", typeof(UILabel))
	self.label_wait = winTrans:ComponentByName("group_all/label_wait", typeof(UILabel))
	self.label_left_time = winTrans:ComponentByName("group_all/label_left_time", typeof(UILabel))
	self.progress_bar = winTrans:NodeByName("group_all/progress_bar").gameObject
	self.pb_thumb_container = winTrans:ComponentByName("group_all/progress_bar/pb_thumb_container", typeof(UIPanel))
	self.pb_thumb = winTrans:ComponentByName("group_all/progress_bar/pb_thumb_container/pb_thumb", typeof(UISprite))
	self.pb_img1 = winTrans:ComponentByName("group_all/progress_bar/pb_label_container/pb_img1", typeof(UISprite))
	self.pb_bg = winTrans:ComponentByName("group_all/progress_bar/pb_bg", typeof(UISprite))
	self.pb_label = winTrans:ComponentByName("group_all/progress_bar/pb_label_container/pb_label", typeof(UILabel))

	xyd.setUISpriteAsync(self.pb_thumb, xyd.MappingData.bg_jingdu, "bg_jingdu")
	xyd.setUISpriteAsync(self.pb_bg, xyd.MappingData.bg_jingdu_di, "bg_jingdu_di")
	xyd.setUISpriteAsync(self.bg_full, xyd.MappingData.icon_tiliquanman, "icon_tiliquanman")
	xyd.setUISpriteAsync(self.pb_img1, xyd.MappingData.icon_tiliquanman_xiao, "icon_tiliquanman_xiao")

	self.title_more.transform:GetComponent(typeof(UILabel)).text = __("ENERGY_TITLE")
	self.title_full.transform:GetComponent(typeof(UILabel)).text = __("ENERGY_FULL_TITLE")
	self.text_full.transform:GetComponent(typeof(UILabel)).text = __("ENERGY_FULL_TIPS")
	self.btn_askfor.transform:ComponentByName("btn_label", typeof(UILabel)).text = __("ENERGY_BUTTON2")
	self.btn_buy_all.transform:ComponentByName("btn_label", typeof(UILabel)).text = __("ENERGY_BUTTON1")
	self.label_wait.text = __("ENERGY_TIPS")
	self.btn_continue.transform:ComponentByName("btn_label", typeof(UILabel)).text = __("CONTINUE")
end

function StaminaWindow:initUIComponent()
	self:setDefaultBgClick(function ()
		self:onBtnClose()
	end)
	xyd.setDarkenBtnBehavior(self.btn_close, self, self.onBtnClose)
	xyd.setDarkenBtnBehavior(self.btn_continue, self, self.onBtnContinue)
	xyd.setDarkenBtnBehavior(self.btn_buy_all, self, self.onBtnBuyAll)
	self:setIsFull(xyd.SelfInfo.get():getStamina() >= 5)
	self:initStamina()
	self:initStaminaTime()
	self:initProgressbar()
	self:initBuyBtnLabel()
end

function StaminaWindow:setIsFull(isFull)
	self.title_more:SetActive(not isFull)
	self.btn_buy_all:SetActive(not isFull)
	self.progress_bar:SetActive(not isFull)
	self.label_wait:SetActive(not isFull)
	self.label_left_time:SetActive(not isFull)
	self.btn_continue:SetActive(isFull)
	self.title_full:SetActive(isFull)
	self.bg_full:SetActive(isFull)
	self.text_full:SetActive(isFull)
end

function StaminaWindow:initBuyBtnLabel()
	local life_buy_cost = MiscTable:getData("life_buy_cost", "k1")
	self.life_buy_cost = tonumber(life_buy_cost)
	self.item_label.text = "x" .. life_buy_cost
end

function StaminaWindow:initStamina()
	local stamina_num = xyd.SelfInfo.get():getStamina()
	self.pb_label.text = tostring(stamina_num) .. "/" .. "5"
end

function StaminaWindow:updateStamina()
	local stamina_num = xyd.SelfInfo.get():getStamina()
	self.pb_label.text = tostring(stamina_num) .. "/" .. "5"

	self:updateProgressbar(stamina_num, 5)
end

function StaminaWindow:initStaminaTime()
	local playerInfoModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYER_INFO)
	self.label_left_time.text = xyd.secondsToString(playerInfoModel.stamina_time)
end

function StaminaWindow:updateStaminaTime(event)
	self.label_left_time.text = xyd.secondsToString(event.data.normal_time)
end

function StaminaWindow:initProgressbar()
	local stamina_num = xyd.SelfInfo.get():getStamina()
	local percent = stamina_num / 5
	local move_value = self.pb_thumb.width * (1 - percent)
	self.pb_thumb_container.transform.localPosition = Vector3(-move_value, 0)
	self.pb_thumb.transform.localPosition = Vector3(move_value, 0)
end

function StaminaWindow:updateProgressbar(val, max)
	local percent = val / max
	local move_value = self.pb_thumb.width * (1 - percent)
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Insert(0, self.pb_thumb_container.transform:DOLocalMoveX(-move_value, 10 * xyd.TweenDeltaTime))
	sequence:Insert(0, self.pb_thumb.transform:DOLocalMoveX(move_value, 10 * xyd.TweenDeltaTime))
	sequence:AppendCallback(function ()
		if xyd.SelfInfo.get():getStamina() >= 5 then
			self:setIsFull(true)
		end
	end)
end

function StaminaWindow:onBtnContinue()
	function self._callBack()
		xyd.WindowManager.get():openWindow("pre_game_window", {
			totalLevel = xyd.SelfInfo.get():getCurrentLevel()
		})
	end

	self:onBtnClose()
end

function StaminaWindow:onBtnAskFor()
	xyd.SoundManager.get():playEffect("Common/se_button")
end

function StaminaWindow:onBtnBuyAll()
	xyd.SoundManager.get():playEffect("Common/se_button")

	if self._isBuyed then
		return
	end

	self._isBuyed = true
	local playerInfoModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYER_INFO)

	playerInfoModel:buyStamina(playerInfoModel.MAX_STAMINA - playerInfoModel.data.stamina, self.life_buy_cost)
end

function StaminaWindow:onBtnClose()
	self:disableAllBtns()
	xyd.SoundManager.get():playEffect("Common/se_button")
	self:close()
end

function StaminaWindow:disableAllBtns()
	self.defaultBg_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.btn_close:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.btn_continue:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
end

function StaminaWindow:dispose()
	if self._callBack then
		self._callBack()
	end

	StaminaWindow.super.dispose(self)
end

return StaminaWindow
