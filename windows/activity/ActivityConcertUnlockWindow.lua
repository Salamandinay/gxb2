local BaseWindow = import(".BaseWindow")
local ActivityConcertUnlockWindow = class("ActivityConcertUnlockWindow", BaseWindow)

function ActivityConcertUnlockWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.table_id_ = params.table_id
	local dif = MusicGameTable:get():difficulty(self.table_id_)

	if dif == 2 then
		self.cost_ = MiscTable:get():split2num("activity_music_day_unlock_normal", "value", "#")
	else
		self.cost_ = MiscTable:get():split2num("activity_music_day_unlock_hard", "value", "#")
	end

	self.skinName = "ActivityConcertUnlockWindowSkin"
end

function ActivityConcertUnlockWindow:createChildren()
	BaseWindow.createChildren(self)
	self.unlockBtn:setBg(SingleButton.BgColorType.blue_btn_65_65)

	self.titleLabel.text = __(_G, "ACTIVITY_CONCERT_UNLOCK_WINDOW_TEXT01")
	self.unlockDescLabel.text = __(_G, "ACTIVITY_CONCERT_UNLOCK_WINDOW_TEXT02")
	local dif = MusicGameTable:get():difficulty(self.table_id_)
	self.unlockLabel.text = __(_G, "ACTIVITY_CONCERT_UNLOCK_WINDOW_TEXT06", __(_G, "ACTIVITY_CONCERT_NAV" .. tostring(dif - 2)), self:getLev())
	local data = self.cost_

	if xyd.Global.lang == "ja_jp" then
		local ____TS_obj = self.tipsLabel
		local ____TS_index = "size"
		____TS_obj[____TS_index] = ____TS_obj[____TS_index] - 1
	end

	xyd:setLabelFlow(self.tipsLabel, __(_G, "ACTIVITY_CONCERT_UNLOCK_WINDOW_TEXT04", ItemTextTable:get():getName(data[0]), data[1]))

	self.unlockBtn.labelDisplay.text = __(_G, "ACTIVITY_CONCERT_UNLOCK_WINDOW_TEXT03")

	self.unlockBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		local cost = self.cost_

		if Backpack:get():getItemNumByID(cost[0]) < cost[1] then
			xyd:showToast(__(_G, "NOT_ENOUGH", ItemTextTable:get():getName(cost[0])))

			return
		end

		App.WindowManager:openWindow("alert_window", {
			alertType = xyd.AlertType.YES_NO,
			message = __(_G, "CONCERT_CONFIRM", ItemTextTable:get():getName(cost[0]), cost[1]),
			callback = function (____, flag)
				if not flag then
					return
				end

				xyd.Backend:get():request(xyd.mid.ACTIVITY_BUY_MUSIC, {
					activity_id = xyd.ActivityID.ACTIVITY_CONCERT,
					music_id = self.table_id_
				})
			end
		})
	end, self)
	self.eventProxy_:addEventListener(xyd.event.ACTIVITY_BUY_MUSIC, function (____, event)
		local data = event.data
		local table_id = data.music_id

		if table_id == self.table_id_ then
			App.WindowManager:closeWindow(self)
			xyd:showToast(__(_G, "ACTIVITY_CONCERT_UNLOCK_WINDOW_TEXT05"))
		end
	end, self)
end

function ActivityConcertUnlockWindow:getLev()
	local judge = {
		"",
		"S",
		"A",
		"B",
		"C",
		"D"
	}
	local lev = MusicGameTable:get():getNextUnlock(self.table_id_ - 1)

	return judge[lev + 1]
end

return ActivityConcertUnlockWindow
