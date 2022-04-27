local BaseWindow = import(".BaseWindow")
local ActivityConcertInfoWindow = class("ActivityConcertInfoWindow", BaseWindow)

function ActivityConcertInfoWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.table_id_ = params.table_id
	self.time_scale_ = params.time_scale
	self.complete_count_ = params.complete_count
	self.skinName = "ActivityConcertInfoWindowSkin"
end

function ActivityConcertInfoWindow:createChildren()
	BaseWindow.createChildren(self)

	self.titleLabel.text = __(_G, "ACTIVITY_CONCERT_INFO_WINDOW_TEXT09")
	self.nameDescLabel.text = __(_G, "ACTIVITY_CONCERT_INFO_WINDOW_TEXT01")
	self.nameLabel.text = self:getName()
	self.authorDescLabel.text = __(_G, "ACTIVITY_CONCERT_INFO_WINDOW_TEXT02")
	self.authorLabel.text = self:getAuthor()
	self.timeDescLabel.text = __(_G, "ACTIVITY_CONCERT_INFO_WINDOW_TEXT03")
	self.timeLabel.text = self:getTime()
	self.totalDescLabel.text = __(_G, "ACTIVITY_CONCERT_INFO_WINDOW_TEXT04")
	self.totalLabel.text = String(_G, self:getTotal())
	self.DifficultDescLabel.text = __(_G, "ACTIVITY_CONCERT_INFO_WINDOW_TEXT05")
	self.DifficultLabel.text = String(_G, self:getDifficult())
	self.infoLabel.text = __(_G, "ACTIVITY_CONCERT_INFO_WINDOW_TEXT06")
	self.awardLabel.text = __(_G, "ACTIVITY_CONCERT_INFO_WINDOW_TEXT07")

	self.startBtn:setBg(SingleButton.BgColorType.blue_btn_65_65)

	self.startBtn.labelDisplay.text = __(_G, "ACTIVITY_CONCERT_INFO_WINDOW_TEXT08")

	self.startBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		local data = ActivityModel:get():getActivity(xyd.ActivityID.ACTIVITY_CONCERT)

		App.WindowManager:openWindow("music_game_window", {
			stage_id = self.table_id_,
			time_scale = self.time_scale_,
			max_score = data.detail.music_list[self.table_id_ - 1].score
		})
	end, self)

	local award = MusicGameTable:get():getAwards(self.table_id_)
	local item = xyd:getItemIcon({
		itemID = award[0],
		num = award[1]
	})
	item.scaleX = 0.8333333333333334
	item.scaleY = 0.8333333333333334

	if self.complete_count_ > 0 then
		item.choose = true
	end

	self.itemGroup:addChild(item)

	self.item_ = item

	self.rankBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		App.WindowManager:openWindow("music_game_rank_single_window", {
			music_id = self.table_id_
		})
	end, self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (____, event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_CONCERT then
			local real_detail = JSON:parse(data.detail)

			if real_detail.music_info.music_id == self.table_id_ then
				self.item_.choose = true
			end
		end
	end, self)
end

function ActivityConcertInfoWindow:getName()
	return ActivityMusicGameTextTable:get():getName(self.table_id_)
end

function ActivityConcertInfoWindow:getAuthor()
	return ActivityMusicGameTextTable:get():getAuthor(self.table_id_)
end

function ActivityConcertInfoWindow:getTime()
	local all_time = math.floor(MusicGameTable:get():endTime(self.table_id_))
	local s = all_time % 60
	local m = math.floor(all_time / 60)
	local t_str = ""

	if m < 10 then
		t_str = tostring(t_str) .. "0"
	end

	t_str = tostring(t_str) .. tostring(m) .. ":"

	if s < 10 then
		t_str = tostring(t_str) .. "0"
	end

	t_str = tostring(t_str) .. tostring(s)

	return t_str
end

function ActivityConcertInfoWindow:getTotal()
	return MusicGameTable:get():getMaxHits(self.table_id_)
end

function ActivityConcertInfoWindow:getDifficult()
	return __(_G, "ACTIVITY_CONCERT_NAV" .. tostring(MusicGameTable:get():difficulty(self.table_id_) - 1))
end

return ActivityConcertInfoWindow
