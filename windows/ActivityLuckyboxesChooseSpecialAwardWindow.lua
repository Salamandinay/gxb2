local BaseWindow = import(".BaseWindow")
local ActivityLuckyboxesChooseSpecialAwardWindow = class("ActivityLuckyboxesChooseSpecialAwardWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ItemTable = xyd.tables.itemTable

function ActivityLuckyboxesChooseSpecialAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LUCKYBOXES)
end

function ActivityLuckyboxesChooseSpecialAwardWindow:getPrefabPath()
	return "Prefabs/Windows/activity_luckyboxes_choose_special_award_window"
end

function ActivityLuckyboxesChooseSpecialAwardWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:Register()
	self:initUIComponent()
end

function ActivityLuckyboxesChooseSpecialAwardWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.labelTip = self.groupAction:ComponentByName("labelTip", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UISprite))
	self.itemGroup = self.groupAction:NodeByName("itemGroup").gameObject
	self.itemGroup_layout = self.groupAction:ComponentByName("itemGroup", typeof(UILayout))
	self.btnChoose = self.groupAction:NodeByName("btnChoose").gameObject
	self.giftbagBuyBtnLabel = self.btnChoose:ComponentByName("giftbagBuyBtnLabel", typeof(UILabel))

	for i = 1, 3 do
		self["awardGroup" .. i] = self.itemGroup:NodeByName("awardGroup" .. i).gameObject
		self["clickMask" .. i] = self["awardGroup" .. i]:NodeByName("clickMask").gameObject
	end
end

function ActivityLuckyboxesChooseSpecialAwardWindow:addTitle()
	self.labelWinTitle.text = __("ACTIVITY_LUCKYBOXES_TEXT06")
end

function ActivityLuckyboxesChooseSpecialAwardWindow:initUIComponent()
	self.giftbagBuyBtnLabel.text = __("ACTIVITY_LUCKYBOXES_TEXT07")
	self.labelTip.text = __("ACTIVITY_LUCKYBOXES_TEXT08")
	self.awards = self.activityData:getCurLayerSpecialAward()
	self.icons = {}

	dump(self.awards)

	for i = 1, 3 do
		local award = self.awards[i]
		self.icons[i] = xyd.getItemIcon({
			show_has_num = true,
			hideText = true,
			uiRoot = self["awardGroup" .. i],
			itemID = award[1],
			num = award[2]
		})

		if self.awards[i].awarded == true then
			xyd.applyChildrenGrey(self.icons[i]:getIconRoot())
		end
	end

	self.itemGroup_layout:Reposition()

	local yoffset = (self.labelTip.height - 20) / 2
	local yOldPosition = self.labelTip.gameObject.transform.localPosition.y

	self.labelTip:Y(yOldPosition + yoffset)

	if self.labelTip.height >= 120 then
		self.labelTip.overflowMethod = UILabel.Overflow.ShrinkContent
		self.labelTip.height = 120

		self.labelTip:Y(350)
	end

	self.bg2.height = self.bg2.height + self.labelTip.height - 20
end

function ActivityLuckyboxesChooseSpecialAwardWindow:Register()
	self.eventProxy_:addEventListener(xyd.event.LABA_SELECT_AWARD, function (event)
		xyd.WindowManager.get():closeWindow("activity_luckyboxes_choose_special_award_window")
	end)

	for i = 1, 3 do
		UIEventListener.Get(self["clickMask" .. i]).onClick = function ()
			if self.awards[i].awarded == true then
				return
			end

			self.chooseIndex = i

			for j = 1, 3 do
				if self.awards[j].awarded ~= true then
					self.icons[j]:setMask(self.chooseIndex == j)
					self.icons[j]:setChoose(self.chooseIndex == j)
					self["clickMask" .. j]:SetActive(self.chooseIndex ~= j)
				end
			end
		end
	end

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow("activity_luckyboxes_choose_special_award_window")
	end

	UIEventListener.Get(self.btnChoose).onClick = function ()
		if not self.chooseIndex then
			xyd.alertTips(__("ACTIVITY_LUCKYBOXES_TEXT13"))

			return
		end

		local timeStamp = xyd.db.misc:getValue("activity_luckyboxes_tip_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "activity_luckyboxes_tip",
				callback = handler(self, function ()
					xyd.setEnabled(self.btnChoose, false)

					local msg = messages_pb:laba_select_award_req()
					msg.activity_id = xyd.ActivityID.ACTIVITY_LUCKYBOXES
					msg.id = tonumber(self.activityData:getCurLayer())
					msg.index = tonumber(self.chooseIndex)

					xyd.Backend.get():request(xyd.mid.LABA_SELECT_AWARD, msg)
				end),
				text = __("ACTIVITY_LUCKYBOXES_TEXT16")
			})

			return
		else
			xyd.setEnabled(self.btnChoose, false)

			local msg = messages_pb:laba_select_award_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_LUCKYBOXES
			msg.id = tonumber(self.activityData:getCurLayer())
			msg.index = tonumber(self.chooseIndex)

			xyd.Backend.get():request(xyd.mid.LABA_SELECT_AWARD, msg)
		end
	end
end

return ActivityLuckyboxesChooseSpecialAwardWindow
