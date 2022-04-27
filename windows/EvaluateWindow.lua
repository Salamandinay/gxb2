local BaseWindow = import(".BaseWindow")
local EvaluateWindow = class("EvaluateWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local BaseComponent = import("app.components.BaseComponent")
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")

function EvaluateWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = {}
	self.evaluationWhereFrom = params.evaluationWhereFrom
	local message = messages_pb:log_player_comment_req()
	local str = require("cjson").encode({
		evaluationWhereFrom = self.evaluationWhereFrom,
		lang = xyd.Global.lang,
		lev = xyd.models.backpack:getLev(),
		vipLev = xyd.models.backpack:getVipLev()
	})
	message.msg = str

	xyd.Backend.get():request(xyd.mid.LOG_PLAYER_COMMENT, message)
end

function EvaluateWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.labelDesc_ = self.groupAction:ComponentByName("labelDesc_", typeof(UILabel))
	self.btnCancel = self.groupAction:NodeByName("btnCancel").gameObject
	self.labelBtnCancel = self.btnCancel:ComponentByName("button_label", typeof(UILabel))
	self.btnSure = self.groupAction:NodeByName("btnSure").gameObject
	self.labelBtnSure = self.btnSure:ComponentByName("button_label", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.starGroup = self.groupAction:NodeByName("starGroup").gameObject
	self.starGroup_layout = self.groupAction:ComponentByName("starGroup", typeof(UILayout))

	for i = 1, 5 do
		self["btnStar" .. i] = self.starGroup:NodeByName("btnStar" .. i).gameObject
	end

	self.imgTitle = self.groupAction:ComponentByName("imgTitle", typeof(UITexture))
	self.labelScoreRank = self.groupAction:ComponentByName("labelScoreRank", typeof(UILabel))
end

function EvaluateWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()

	self.labelWinTitle.text = __("NEW_PINGFEN_TEXT01")
	self.labelDesc_.text = __("NEW_PINGFEN_TEXT02")
	self.labelBtnCancel.text = __("NEW_PINGFEN_TEXT08")
	self.labelBtnSure.text = __("NEW_PINGFEN_TEXT09")

	xyd.setUITextureByNameAsync(self.imgTitle, "evaluate_window_logo_" .. xyd.Global.lang)
	self:updateStarGroup()

	if xyd.Global.lang == "de_de" then
		self.labelDesc_.height = 180

		self.labelDesc_:Y(165)
	elseif xyd.Global.lang == "fr_fr" then
		self.labelDesc_.height = 190

		self.labelDesc_:Y(165)
	end
end

function EvaluateWindow:updateStarGroup()
	if not self.evaluateScore then
		self.evaluateScore = 0
	end

	for i = 1, 5 do
		local img = self["btnStar" .. i]:ComponentByName("", typeof(UISprite))

		if i <= self.evaluateScore then
			xyd.setUISpriteAsync(img, nil, "evaluate_window_icon_ax_1")
		else
			xyd.setUISpriteAsync(img, nil, "evaluate_window_icon_ax_2")
		end
	end

	if self.evaluateScore > 0 then
		self.labelScoreRank.text = __("NEW_PINGFEN_TEXT0" .. self.evaluateScore + 2)
	end
end

function EvaluateWindow:register()
	UIEventListener.Get(self.btnClose).onClick = function ()
		xyd.db.misc:setValue({
			value = true,
			key = "evaluate_have_closed"
		})
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	for i = 1, 5 do
		UIEventListener.Get(self["btnStar" .. i]).onClick = function ()
			self.evaluateScore = i

			self:updateStarGroup()
		end
	end

	UIEventListener.Get(self.btnCancel).onClick = function ()
		local cancelTime = tonumber(xyd.db.misc:getValue("evaluate_cancel_time")) or 0
		cancelTime = cancelTime + 1

		xyd.db.misc:setValue({
			key = "evaluate_cancel_time",
			value = cancelTime
		})
		xyd.db.misc:setValue({
			key = "evaluate_last_time",
			value = xyd.getServerTime()
		})

		if cancelTime >= 5 then
			xyd.db.misc:setValue({
				value = true,
				key = "evaluate_have_closed"
			})
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		if not self.evaluateScore or self.evaluateScore == 0 then
			xyd.alertTips(__("NEW_PINGFEN_TEXT17"))
		elseif self.evaluateScore <= 3 then
			xyd.openWindow("feedback_window", {
				star = self.evaluateScore,
				evaluationWhereFrom = self.evaluationWhereFrom
			})
			xyd.db.misc:setValue({
				value = true,
				key = "evaluate_have_closed"
			})

			local message = messages_pb:log_player_comment_req()
			local str = require("cjson").encode({
				star = self.evaluateScore,
				evaluationWhereFrom = self.evaluationWhereFrom,
				lang = xyd.Global.lang,
				lev = xyd.models.backpack:getLev(),
				vipLev = xyd.models.backpack:getVipLev()
			})
			message.msg = str

			xyd.Backend.get():request(xyd.mid.LOG_PLAYER_COMMENT, message)
			xyd.WindowManager.get():closeWindow(self.name_)
		elseif self.evaluateScore > 3 then
			xyd.db.misc:setValue({
				value = true,
				key = "evaluate_have_closed"
			})

			local url = ""

			if UNITY_ANDROID then
				url = xyd.Global.androidUrl
			elseif UNITY_IOS then
				if xyd.Global.lang == "ja_jp" then
					url = xyd.Global.iosUrlJP
				else
					url = xyd.Global.iosUrl
				end
			end

			local message = messages_pb:log_player_comment_req()
			local str = require("cjson").encode({
				star = self.evaluateScore,
				evaluationWhereFrom = self.evaluationWhereFrom,
				lang = xyd.Global.lang,
				lev = xyd.models.backpack:getLev(),
				vipLev = xyd.models.backpack:getVipLev()
			})
			message.msg = str

			xyd.Backend.get():request(xyd.mid.LOG_PLAYER_COMMENT, message)
			xyd.SdkManager.get():openBrowser(url)
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end
end

return EvaluateWindow
