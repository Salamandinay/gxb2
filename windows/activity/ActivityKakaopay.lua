local ActivityKakaopay = class("ActivityKakaopay", import(".ActivityContent"))

function ActivityKakaopay:ctor(parentGo, params, parent)
	ActivityKakaopay.super.ctor(self, parentGo, params, parent)
end

function ActivityKakaopay:getPrefabPath()
	return "Prefabs/Windows/activity/activity_kakaopay"
end

function ActivityKakaopay:initUI()
	self:getUIComponent()
	ActivityKakaopay.super.initUI(self)

	self.cafeurl = "https://cafe.naver.com/gxb2kr"

	self:initText()
end

function ActivityKakaopay:resizeToParent()
	ActivityKakaopay.super.resizeToParent(self)
	self:resizePosY(self.groupMain, 0, -67)
	self:resizePosY(self.alipay, -36.8, 29)
end

function ActivityKakaopay:getUIComponent()
	local groupMain = self.go:NodeByName("groupMain").gameObject
	self.textImg = groupMain:NodeByName("textImg").gameObject
	self.groupMain = groupMain
	self.textGroup = groupMain:NodeByName("textBg").gameObject
	self.scroller_ = groupMain:ComponentByName("textBg/scroller_", typeof(UIScrollView))
	self.labelContent = groupMain:ComponentByName("textBg/scroller_/labelContent", typeof(UILabel))
	local payGroup = groupMain:NodeByName("payGroup").gameObject
	self.payGroup = payGroup
	self.goLabel = payGroup:ComponentByName("goLabel", typeof(UILabel))
	self.giftButton = payGroup:NodeByName("giftButton").gameObject
	self.giftButton_label = self.giftButton:ComponentByName("button_label", typeof(UILabel))
	self.payButton = payGroup:NodeByName("payButton").gameObject
	self.payButton_label = self.payButton:ComponentByName("button_label", typeof(UILabel))
	self.cafeGroup = groupMain:NodeByName("cafeGroup").gameObject
	self.cafeLabel = self.cafeGroup:ComponentByName("cafeLabel", typeof(UILabel))
	self.bubble = groupMain:NodeByName("bubble").gameObject
	self.bubbleLabel = groupMain:ComponentByName("bubble/bubbleLabel", typeof(UILabel))
	self.alipay = groupMain:NodeByName("alipay").gameObject
	self.tipsImg = groupMain:NodeByName("tipsImg").gameObject
end

function ActivityKakaopay:initText()
	self.labelContent.text = __("KR_KAKAOPAY_TEXT01")

	self.scroller_:ResetPosition()

	self.goLabel.text = __("KR_KAKAOPAY_TEXT02")
	self.giftButton_label.text = __("KR_KAKAOPAY_TEXT03")
	self.payButton_label.text = __("KR_KAKAOPAY_TEXT04")
	self.cafeLabel.text = __("KR_KAKAOPAY_SNS_TEXT01")
	self.bubbleLabel.text = __("KR_KAKAOPAY_SNS_TEXT02")
end

function ActivityKakaopay:onRegister()
	UIEventListener.Get(self.cafeGroup).onClick = function ()
		xyd.SdkManager.get():openBrowser(self.cafeurl)

		local msg = messages_pb.log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.KAKAOPAY_CAFE

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end

	UIEventListener.Get(self.payButton).onClick = function ()
		xyd.WindowManager.get():openWindow("vip_window")

		local msg = messages_pb.log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.KAKAOPAY_RECHARGE

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end

	UIEventListener.Get(self.giftButton).onClick = function ()
		xyd.WindowManager.get():closeWindow("activity_window")
		xyd.WindowManager.get():openWindow("activity_window", {
			activity_type = xyd.EventType.COOL,
			closeCallBack = function ()
				xyd.WindowManager.get():openWindow("activity_window", {
					activity_type = xyd.EventType.LIMIT,
					select = xyd.ActivityID.KAKAOPAY
				})
			end
		})

		local msg = messages_pb.log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.KAKAOPAY_GIFT

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end
end

return ActivityKakaopay
