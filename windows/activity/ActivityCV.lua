function __TS__ArrayPush(arr, ...)
	local items = {
		...
	}

	for ____TS_index = 1, #items do
		local item = items[____TS_index]
		arr[#arr + 1] = item
	end

	return #arr
end

local ActivityContent = import(".ActivityContent")
local ActivityCV = class("ActivityCV", ActivityContent)

function ActivityCV:ctor(params)
	ActivityContent.ctor(self, params)

	self.current_id = {}
	self.sound_list = {}
	self.time_list = {}
	self.isPlaySound = false
	local i = 1

	while i <= 6 do
		local sound = ActivityCVTable:get():getSoundList(i)

		__TS__ArrayPush(self.sound_list, sound)
		__TS__ArrayPush(self.current_id, math.floor(math.random() * sound.length))
		__TS__ArrayPush(self.time_list, ActivityCVTable:get():getTimeList(i))

		i = i + 1
	end

	self.skinName = "ActivityCVSkin"
	self.textLabel.visible = false
end

function ActivityCV:euiComplete()
	ActivityContent.euiComplete(self)

	self.daqiao.source = "activity_cv_daqiao_" .. tostring(xyd.Global.lang) .. "_png"
	self.zhenji.source = "activity_cv_zhenji_" .. tostring(xyd.Global.lang) .. "_png"
	self.zhouyu.source = "activity_cv_zhouyu_" .. tostring(xyd.Global.lang) .. "_png"
	self.xiuji.source = "activity_cv_xiuji_" .. tostring(xyd.Global.lang) .. "_png"
	self.caozhi.source = "activity_cv_caozhi_" .. tostring(xyd.Global.lang) .. "_png"
	self.sun.source = "activity_cv_sun_" .. tostring(xyd.Global.lang) .. "_png"
	self.textImg.source = "activity_cv_text_" .. tostring(xyd.Global.lang) .. "_png"
	self.textLabel.text = __(_G, "ACTIVITY_CV_TEXT")

	self:registerEvent()
end

function ActivityCV:registerEvent()
	local i = 1

	while i <= 6 do
		self["touchGroup_" .. tostring(i)]:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
			if self.isPlaySound then
				return
			end

			self.isPlaySound = true
			self.currentPlay = String(_G, self.sound_list[i - 1 + 1][self.current_id[i - 1 + 1]])
			local t = self.time_list[i - 1 + 1][self.current_id[i - 1 + 1]]

			SoundManager:get():playSound(String(_G, self.sound_list[i - 1 + 1][self.current_id[i - 1 + 1]]), function ()
			end)
			egret:setTimeout(function ()
				self.isPlaySound = false
				local ____TS_obj = self.current_id
				local ____TS_index = i - 1 + 1
				____TS_obj[____TS_index] = ____TS_obj[____TS_index] + 1
				local ____TS_obj = self.current_id
				local ____TS_index = i - 1 + 1
				____TS_obj[____TS_index] = ____TS_obj[____TS_index] % self.sound_list[i - 1 + 1].length
			end, self, t * 1000)
		end, self)

		i = i + 1
	end

	self.shareBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		XydSDKConnector:fbShareWithParams(__(_G, "FB_SHARE_TITLE"), __(_G, "FB_SHARE_DESC"), __(_G, "FB_SHARE_IMG_URL"), __(_G, "FB_REDIR_URL"))

		if self.activityData.detail.is_awarded then
			return
		end
	end, self)
end

function ActivityCV:onRemove()
	ActivityContent.onRemove(self)

	if self.isPlaySound then
		SoundManager:get():stopSound(String(_G, self.currentPlay))
	end
end

return ActivityCV
