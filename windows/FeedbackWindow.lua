local BaseWindow = import(".BaseWindow")
local FeedbackWindow = class("FeedbackWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local BaseComponent = import("app.components.BaseComponent")
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")

function FeedbackWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = {}
	self.star = params.star
	self.evaluationWhereFrom = params.evaluationWhereFrom
	self.evaluateScore = params.evaluateScore
end

function FeedbackWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.labelDesc_ = self.groupAction:ComponentByName("labelDesc_", typeof(UILabel))
	self.btnCancel = self.groupAction:NodeByName("btnCancel").gameObject
	self.labelBtnCancel = self.btnCancel:ComponentByName("button_label", typeof(UILabel))
	self.btnSure = self.groupAction:NodeByName("btnSure").gameObject
	self.labelBtnSure = self.btnSure:ComponentByName("button_label", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.labelLimit = self.groupAction:ComponentByName("labelLimit", typeof(UILabel))
	self.feedbackGroup = self.groupAction:NodeByName("feedbackGroup").gameObject
	self.feedbackGroup_scrollview = self.groupAction:ComponentByName("feedbackGroup", typeof(UIScrollView))
	self.lableFeedback = self.feedbackGroup:ComponentByName("lableFeedback", typeof(UILabel))
	self.drag = self.groupAction:NodeByName("drag").gameObject
	self.imgTitle = self.groupAction:ComponentByName("imgTitle", typeof(UITexture))

	xyd.addTextInput(self.lableFeedback, {
		max_length = 500,
		max_line = 500,
		type = xyd.TextInputArea.InputSingleLine,
		onChangeCallBack = function (text)
			print(text)

			self.labelLimit.text = __("NEW_PINGFEN_TEXT12", xyd.utf8len(text))
		end,
		check_length_function = xyd.utf8len
	})
end

function FeedbackWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()

	self.labelWinTitle.text = __("NEW_PINGFEN_TEXT10")
	self.labelDesc_.text = __("NEW_PINGFEN_TEXT11")
	self.labelBtnCancel.text = __("NEW_PINGFEN_TEXT14")
	self.labelBtnSure.text = __("NEW_PINGFEN_TEXT15")
	self.labelLimit.text = __("NEW_PINGFEN_TEXT12", 0)
	self.lableFeedback.text = __("NEW_PINGFEN_TEXT13")

	xyd.setUITextureByNameAsync(self.imgTitle, "evaluate_window_logo_" .. xyd.Global.lang)
end

function FeedbackWindow:register()
	UIEventListener.Get(self.btnClose).onClick = function ()
		xyd.db.misc:setValue({
			value = true,
			key = "evaluate_have_closed"
		})
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnCancel).onClick = function ()
		xyd.db.misc:setValue({
			value = true,
			key = "evaluate_have_closed"
		})
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		if self.lableFeedback.text == "" or self.lableFeedback.text == __("NEW_PINGFEN_TEXT13") then
			xyd.alertTips(__("NEW_PINGFEN_TEXT19"))
		else
			xyd.db.misc:setValue({
				value = true,
				key = "evaluate_have_closed"
			})

			local message = messages_pb:log_player_comment_req()
			message.msg = json.encode({
				feedback = self.lableFeedback.text,
				evaluationWhereFrom = self.evaluationWhereFrom,
				lang = xyd.Global.lang,
				lev = xyd.models.backpack:getLev(),
				vipLev = xyd.models.backpack:getVipLev()
			})

			xyd.Backend.get():request(xyd.mid.LOG_PLAYER_COMMENT, message)
			xyd.alertTips(__("NEW_PINGFEN_TEXT16"))
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end

	UIEventListener.Get(self.drag).onClick = function ()
		if self.lableFeedback.text == __("NEW_PINGFEN_TEXT13") then
			self.lableFeedback.text = ""
		end

		xyd.models.textInput:showInput(self.lableFeedback, {
			max_length = 500,
			max_line = 500,
			type = xyd.TextInputArea.InputSingleLine,
			max_tips = __("NEW_PINGFEN_TEXT18"),
			callback = function ()
				self.labelLimit.text = __("NEW_PINGFEN_TEXT12", xyd.utf8len(self.lableFeedback.text))

				if self.lableFeedback.text == "" then
					self.lableFeedback.text = __("NEW_PINGFEN_TEXT13")
				end
			end,
			onChangeCallBack = function (text)
				print(text)

				self.labelLimit.text = __("NEW_PINGFEN_TEXT12", xyd.utf8len(text))
			end,
			check_length_function = xyd.utf8len
		})
	end
end

return FeedbackWindow
