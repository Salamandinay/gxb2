local NewbeeFund3PopupWindow = class("NewbeeFund3PopupWindow", import(".BaseWindow"))
local CountDown = import("app.components.CountDown")

function NewbeeFund3PopupWindow:ctor(name, params)
	NewbeeFund3PopupWindow.super.ctor(self, name, params)
	xyd.db.misc:setValue({
		key = "newbee_fund3_popup_check",
		value = xyd.getServerTime()
	})

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_NEWBEE_FUND3)
end

function NewbeeFund3PopupWindow:initWindow()
	self:getUIComponent()

	UIEventListener.Get(self.buyBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
		xyd.WindowManager.get():openWindow("activity_window", {
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_NEWBEE_FUND3)
		})
	end

	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_newbee_fund3_popup_logo_" .. xyd.Global.lang)
	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel_.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	self.buyBtnLabel_.text = __("BUY")
	self.descLabel_.text = __("ACTIVITY_NEWBEE_FUND_TEXT02")
	self.tipLabel_.text = __("ACTIVITY_NEWBEE_FUND_TEXT03")
	self.totalLabel_.text = __("ACTIVITY_NEWBEE_FUND_TEXT04")
	local previewIDs = xyd.tables.miscTable:split2Cost("activity_newbee_fund_4items_preview", "value", "|")
	local infos = {}

	for _, itemID in ipairs(previewIDs) do
		infos[tonumber(itemID)] = 0
	end

	local ids = xyd.tables.activityNewbeeFundTable3:getIds()

	for _, id in pairs(ids) do
		local award = xyd.tables.activityNewbeeFundTable3:getAwards(id)

		if infos[award[1]] then
			infos[award[1]] = infos[award[1]] + award[2]
		end
	end

	self.crystalNum_.text = infos[xyd.ItemID.CRYSTAL]

	for _, itemID in ipairs(previewIDs) do
		if infos[tonumber(itemID)] ~= 0 then
			xyd.getItemIcon({
				show_has_num = true,
				showGetWays = false,
				scale = 0.7962962962962963,
				notShowGetWayBtn = true,
				itemID = tonumber(itemID),
				num = infos[tonumber(itemID)],
				uiRoot = self.awardGroup_,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	end

	self.awardGroup_:GetComponent(typeof(UILayout)):Reposition()
end

function NewbeeFund3PopupWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.bgImg_ = goTrans:ComponentByName("bgImg", typeof(UISprite))
	self.maskImg_ = goTrans:NodeByName("maskImg").gameObject

	self.maskImg_:SetActive(true)

	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.buyBtn_ = goTrans:NodeByName("buyBtn").gameObject
	self.buyBtnLabel_ = goTrans:ComponentByName("buyBtn/label", typeof(UILabel))
	self.descLabel_ = goTrans:ComponentByName("descLabel", typeof(UILabel))
	self.tipLabel_ = goTrans:ComponentByName("tipLabel", typeof(UILabel))
	self.timeLabel_ = goTrans:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel_ = goTrans:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.awardGroup_ = goTrans:NodeByName("awardGroup").gameObject
	self.totalLabel_ = goTrans:ComponentByName("totalGroup/totalLabel", typeof(UILabel))
	self.crystalNum_ = goTrans:ComponentByName("totalGroup/crystalNum", typeof(UILabel))
end

function NewbeeFund3PopupWindow:playOpenAnimation(callback)
	NewbeeFund3PopupWindow.super.playOpenAnimation(self, function ()
		self:waitForTime(1, function ()
			self.maskImg_:SetActive(false)
		end)

		if callback then
			callback()
		end
	end)
end

function NewbeeFund3PopupWindow:didClose()
	NewbeeFund3PopupWindow.super.didClose(self)

	xyd.MainController.get().openPopWindowNum = xyd.MainController.get().openPopWindowNum - 1
end

return NewbeeFund3PopupWindow
