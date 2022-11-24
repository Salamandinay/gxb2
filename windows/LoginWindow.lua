local LoginWindowEdit = import("app.components.LoginWindowEdit")
local LoginWindow = class("LoginWindow", import(".BaseWindow"))

function LoginWindow:ctor(name, params)
	LoginWindow.super.ctor(self, name, params)

	if params.listener ~= nil then
		self.callback_ = params.listener
	end

	if params.login_finish then
		self.isLoginFinish_ = params.login_finish
	end
end

function LoginWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.effectGroup_ = winTrans:NodeByName("effectGroup_").gameObject
	self.ziEffectGroup_ = winTrans:NodeByName("ziEffectGroup_").gameObject
	self.loginGroup = winTrans:NodeByName("e:Group/loadingGroup/loginGroup").gameObject
	self.loginBtn_ = self.loginGroup:NodeByName("loginBtn").gameObject
	self.loginLbl_ = self.loginGroup:ComponentByName("loginBtn/login_btn_label", typeof(UILabel))
	self.userInput_ = self.loginGroup:ComponentByName("uid_input", typeof(UIInput))
	self.userLbl_ = self.loginGroup:ComponentByName("uid_input/uid_input_label", typeof(UILabel))
	self.versionLabel_ = winTrans:ComponentByName("labelVersion", typeof(UILabel))
	self.backImg = winTrans:ComponentByName("backImg", typeof(UITexture))
	self.loginStart = winTrans:NodeByName("e:Group/loginStart").gameObject
	self.labelLoading = self.loginStart:ComponentByName("labelLoading", typeof(UISprite))
	self.groupWel = winTrans:NodeByName("top/groupWel").gameObject
	self.labelWel = self.groupWel:ComponentByName("labelWel", typeof(UILabel))
	self.backImg2 = winTrans:NodeByName("backImg2").gameObject
	self.logo = winTrans:ComponentByName("logo", typeof(UITexture))
	self.topButtonGroup = winTrans:NodeByName("topButtonGroup").gameObject
	self.accountBtn = self.topButtonGroup:NodeByName("accountBtn").gameObject
	self.castBtn = self.topButtonGroup:NodeByName("castBtn").gameObject
	self.repairBtn = self.topButtonGroup:NodeByName("repairBtn").gameObject
	self.gmBtn = self.topButtonGroup:NodeByName("gmBtn").gameObject
	self.gm_redPoint = self.gmBtn:NodeByName("gm_redPoint").gameObject

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.GM_CHAT, self.gm_redPoint)

	self.serverCon = self.loginStart:NodeByName("serverCon").gameObject
	self.serverConBg = self.serverCon:ComponentByName("serverConBg", typeof(UISprite))
	self.serverIcon = self.serverCon:ComponentByName("serverIcon", typeof(UISprite))
	self.serverId = self.serverCon:ComponentByName("serverId", typeof(UILabel))
	self.serverChangeBtn = self.serverCon:NodeByName("serverChangeBtn").gameObject
	self.serverChangeBtn_BoxCollider = self.serverCon:ComponentByName("serverChangeBtn", typeof(UnityEngine.BoxCollider))
	self.serverChangeBtnLabel = self.serverChangeBtn:ComponentByName("serverChangeBtnLabel", typeof(UILabel))

	if UNITY_IOS then
		self.logo:SetActive(false)
	elseif not xyd.isH5() then
		local poss = {
			ja_jp = {
				w = 548,
				h = 274,
				x = 138
			},
			ko_kr = {
				w = 493,
				h = 218,
				x = 108
			},
			zh_tw = {
				w = 548,
				h = 274,
				x = 138
			}
		}
		local logoName = "logo"

		if xyd.lang == "zh_tw" or xyd.lang == "ja_jp" or xyd.lang == "ko_kr" then
			logoName = "logo_" .. xyd.lang
			self.logo.width = poss[xyd.lang].w
			self.logo.height = poss[xyd.lang].h

			self.logo:X(poss[xyd.lang].x)
		end

		xyd.setUITextureByNameAsync(self.logo, logoName, false)
	end
end

function LoginWindow:initWindow()
	LoginWindow.super.initWindow(self)
	self:getUIComponent()

	local tableID = xyd.tables.miscTable:getNumber("loading_renew", "value")
	local height = self:getScreenHeight()
	local srcImgName = tostring(xyd.tables.customBackgroundTable:getEffectBackground(tableID))
	local srcSpineName = xyd.tables.customBackgroundTable:getEffect(tableID)
	local res = xyd.getEffectFilesByNames({
		srcSpineName
	})
	local path1 = xyd.getSpritePath(srcImgName)

	table.insert(res, path1)

	self.allHasRes = xyd.isAllPathLoad(res)

	if self.allHasRes then
		xyd.setUITextureByNameAsync(self.backImg, srcImgName, true, function ()
			local height = self:getScreenHeight()
			local scale = height / self.backImg.height

			self.backImg:SetLocalScale(scale, scale, 1)
			self:onBgLoad()
			self:initEffect()
		end, true)
	else
		ResCache.DownloadAssets("login_window_effect_and_sprite", res, function (success)
		end, function (progress)
		end, 1)
		self:initEffect()
		xyd.setUITextureByNameAsync(self.backImg, "login_scene", false, function ()
			self:onBgLoad()
		end, true)
	end

	self:layout()
	self:registerEvent()

	if UNITY_EDITOR then
		self:initEditorCon()
	end
end

function LoginWindow:layout()
	if not self.isLoginFinish_ and not xyd.Global.isHasBeenBanServer and not xyd.Global.isDueData then
		self.loginGroup:SetActive(true)
		self.loginStart:SetActive(false)
		self.groupWel:SetActive(false)
		self.backImg2:SetActive(false)
		self:initLoginGroup()
	elseif xyd.Global.isDueData then
		self.loginGroup:SetActive(false)
		self.loginStart:SetActive(true)
		self.groupWel:SetActive(true)
		self.backImg2:SetActive(true)
		self.topButtonGroup.gameObject:SetActive(false)
		self.serverCon:SetActive(false)
	else
		self.loginGroup:SetActive(false)
		self.loginStart:SetActive(true)
		self.groupWel:SetActive(true)
		self.backImg2:SetActive(true)

		if not xyd.Global.isHasBeenBanServer then
			self:initAfterLoginGroup()
		else
			self.topButtonGroup.gameObject:SetActive(false)
			self:initChoiceOtherServer()
		end
	end

	self:resizePosY(self.ziEffectGroup_.gameObject, -495, -634)
	self:resizePosY(self.topButtonGroup.gameObject, 597, 686)
	self:resizePosY(self.versionLabel_.gameObject, 630, 719)

	self.versionLabel_.text = xyd.res_version
end

function LoginWindow:registerEvent()
	UIEventListener.Get(self.accountBtn).onClick = handler(self, self.openAccount)
	UIEventListener.Get(self.castBtn).onClick = handler(self, self.openCast)
	UIEventListener.Get(self.repairBtn).onClick = handler(self, self.onRepair)
	UIEventListener.Get(self.gmBtn).onClick = handler(self, function ()
		if self.isLoginFinish_ then
			xyd.WindowManager:get():openWindow("chat_gm_window")
		else
			xyd.alert(xyd.AlertType.TIPS, __("IS_LOGGING_IN"))
		end
	end)
end

function LoginWindow:onRepair()
	xyd.WindowManager.get():openWindow("system_repair_doctor_window")
end

function LoginWindow:openCast()
	local noticeData = xyd.models.settingUp:getNotice()

	if not noticeData then
		return
	end

	xyd.WindowManager.get():openWindow("notice_window")
end

function LoginWindow:openAccount()
	if xyd.Global.isAnonymous_ == 1 then
		xyd.alert(xyd.AlertType.YES_NO, __("ANONYMOUS_MODIFY_ACCOUNT"), function (yes)
			if yes then
				xyd.WindowManager.get():openWindow("modify_account_window", {
					winType = xyd.ModifyAccountWindowType.LOGIN
				})
			end
		end)
	else
		xyd.WindowManager.get():openWindow("modify_account_window", {
			winType = xyd.ModifyAccountWindowType.LOGIN
		})
	end
end

function LoginWindow:update(params)
	LoginWindow.super.update(self)

	if params.listener ~= nil then
		self.callback_ = params.listener
	end

	if params.login_finish then
		self.isLoginFinish_ = params.login_finish
	end

	self:layout()
end

function LoginWindow:initLoginGroup()
	self.userLbl_.text = __("ACCOUNT")
	self.loginLbl_.text = __("LOGIN")

	self.userInput_:Set(xyd.db.meta.sid, false)

	UIEventListener.Get(self.loginBtn_).onClick = function ()
		if self.logined_ then
			return
		end

		if self.userInput_.value == "" then
			return
		end

		print(self.userInput_.value)

		self.logined_ = true

		self:login()

		if UNITY_EDITOR then
			self.editCon:setSaveAcount(self.userInput_.value)
		end
	end
end

function LoginWindow:initAfterLoginGroup()
	self.server_id = xyd.models.selfPlayer:getServerID()

	self:changeServerIdShow()

	self.serverChangeBtnLabel.text = __("BEGIN")

	xyd.setUISpriteAsync(self.labelLoading, nil, "tap_tips_" .. xyd.lang, function ()
		self.labelLoading:MakePixelPerfect()
	end)

	local name = xyd.models.selfPlayer:getAccount()

	if name and xyd.utf8len(name) > 12 then
		name = xyd.subUft8Len(name, 12)
	end

	self.labelWel.text = __("WELCOME_USER", name)

	UIEventListener.Get(self.backImg2).onClick = function ()
		if self.isEnterMainScene_ then
			return
		end

		if self.server_id == xyd.models.selfPlayer:getServerID() then
			self.serverChangeBtn_BoxCollider.enabled = false
			local service_wd = xyd.WindowManager.get():getWindow("service_window")

			if service_wd then
				xyd.WindowManager.get():closeWindow("service_window")
			end

			self.isEnterMainScene_ = true

			xyd.MainController.get():enterMainScene()
		else
			local str = __("SWITCH_SERVER_TIP")

			xyd.alert(xyd.AlertType.YES_NO, str, function (yes_no)
				if yes_no then
					self:changeServer(self.server_id)
				end
			end)
		end
	end

	UIEventListener.Get(self.serverChangeBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("service_window", {
			isClickToChange = false,
			default_server_id = self.server_id
		})
	end

	self:showWei()
end

function LoginWindow:changeServer(serverID)
	UnityEngine.PlayerPrefs.SetString("is_change_server_to_enter_game_" .. xyd.Global.uid, "true")
	xyd.EventDispatcher:inner():dispatchEvent({
		name = xyd.event.CHANGE_SERVER,
		data = {
			server_id = serverID
		}
	})
end

function LoginWindow:changeServerId(id)
	self.server_id = id

	self:changeServerIdShow()
end

function LoginWindow:changeServerIdShow()
	local showServer = "T" .. tostring(self.server_id)

	if self.server_id > 2 then
		showServer = "S" .. tostring(self.server_id - 2)
	end

	self.serverId.text = showServer
end

function LoginWindow:onBgLoad()
	UIManager.Close("ui_loading")

	self.isBgLoad_ = true

	self:showWei()
end

function LoginWindow:showWei()
	if not self.isLoginFinish_ or not self.isBgLoad_ or self.showWeiAction_ then
		return
	end

	local action = DG.Tweening.DOTween.Sequence()
	local transform = self.groupWel.transform

	transform:SetLocalPosition(0, 105, 0)
	action:Append(transform:DOLocalMoveY(-31, 0.23)):AppendInterval(3.5):Append(transform:DOLocalMoveY(105, 0.43))

	self.showWeiAction_ = action
end

function LoginWindow:initEffect()
	if xyd.isH5() then
		local sp1 = xyd.Spine.new(self.ziEffectGroup_)

		sp1:setInfo("loading1_zi", function ()
			sp1:SetLocalPosition(-510, -280, 0)
			sp1:SetLocalScale(1, 1, 1)
			sp1:setRenderTarget(self.ziEffectGroup_:GetComponent(typeof(UIWidget)), 2)
			sp1:play("title_" .. string.lower(xyd.lang), 1, 1)
		end)
	end

	local sp2 = xyd.Spine.new(self.effectGroup_)

	if self.allHasRes then
		local tableID = xyd.tables.miscTable:getNumber("loading_renew", "value")
		local spineName = xyd.tables.customBackgroundTable:getEffect(tableID)
		local animation = xyd.tables.customBackgroundTable:getAnimation(tableID)

		sp2:setInfo(spineName, function ()
			local height = self:getScreenHeight()
			local effect_scale = height / self.backImg.height * 0.656 * 1.0517241379310345

			dump(height)
			dump(self.backImg.height)
			sp2:SetLocalScale(effect_scale, effect_scale, 1)

			local effect_offset = xyd.tables.customBackgroundTable:getOffset(tableID)
			local effect_offect_scale = height / self.backImg.height / 1.25

			if effect_offset then
				self.effectGroup_.transform:SetLocalPosition(effect_offset[1] * effect_offect_scale, -effect_offset[2] * effect_offect_scale, 0)
			end

			sp2:play(animation, 0, 1)
		end)

		return
	end

	sp2:setInfo("loading1", function ()
		sp2:SetLocalPosition(0, -775, 0)
		sp2:SetLocalScale(1, 1, 1)
		sp2:play("animation", 0, 1)
	end)
end

function LoginWindow:login()
	if self.callback_ ~= nil then
		xyd.db.clean()

		xyd.db.meta.sid = self.userInput_.value

		xyd.db.meta:persist()
		print("xyd.db.meta.sid = " .. xyd.db.meta.sid)

		local platform_id = nil

		if UNITY_IOS then
			platform_id = 2
		else
			platform_id = 1
		end

		self.callback_({
			name = xyd.event.SDK_LOGIN_SUCCESS,
			params = {
				isFakeLogin = true,
				loginToken = "111",
				sessionID = self.userInput_.value,
				platform_id = platform_id,
				username = self.userInput_.value
			}
		})
	end
end

function LoginWindow:willClose()
	LoginWindow.super.willClose(self)

	if self.refreshDataTimer then
		self.refreshDataTimer:Stop()

		self.refreshDataTimer = nil
	end

	if self.showWeiAction_ then
		self.showWeiAction_:Pause()
		self.showWeiAction_:Kill()

		self.showWeiAction_ = nil
	end
end

function LoginWindow:battleTest()
	xyd.WindowManager.get():closeWindow("login_window")

	local path = "E:/gh_unity_client/Assets/Lua/data/battle_report/report.json"
	local jsonData = io.readfile(path)
	local cjson = require("cjson")
	local params = cjson.decode(jsonData)

	xyd.BattleController.get():startBattle(params)
end

function LoginWindow:initEditorCon()
	if UNITY_EDITOR then
		self.editCon = LoginWindowEdit.new(self.loginGroup.gameObject, {
			userInput = self.userInput_
		})
	end
end

function LoginWindow:setLoginSuccState()
	self.loginStart:SetActive(false)
	self.ziEffectGroup_:SetActive(false)
end

function LoginWindow:initChoiceOtherServer()
	UnityEngine.PlayerPrefs.SetString("is_change_server_to_enter_game_" .. xyd.Global.uid, "false")

	self.serverId.text = __("LOGIN_TIPS_ERROR_1")

	UIEventListener.Get(self.backImg2).onClick = function ()
		xyd.alertTips(__("LOGIN_TIPS_ERROR_2"))
	end

	UIEventListener.Get(self.serverChangeBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("service_window", {})
	end
end

function LoginWindow:getScreenHeight()
	local width, height = xyd.getScreenSize()

	if height > 1458 then
		height = 1458
	end

	if UnityEngine.Screen.height / UnityEngine.Screen.width > xyd.Global.getRealHeight() / xyd.Global.getRealWidth() then
		return xyd.Global.getMaxBgHeight()
	end

	return height
end

return LoginWindow
