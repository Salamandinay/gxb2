local ActivityContent = import(".ActivityContent")
local ActivitySpfarm = class("ActivitySpfarm", ActivityContent)
local CountDown = import("app.components.CountDown")
local json = require("cjson")

function ActivitySpfarm:ctor(parentGO, params, parent)
	ActivitySpfarm.super.ctor(self, parentGO, params, parent)
end

function ActivitySpfarm:getPrefabPath()
	return "Prefabs/Windows/activity/activity_spfarm"
end

function ActivitySpfarm:initUI()
	self:getUIComponent()
	ActivitySpfarm.super.initUI(self)
	self:initUIComponent()

	if xyd.getServerTime() < self.activityData:getEndTime() - self.activityData:getViewTimeSec() and xyd.getServerTime() >= self.activityData:getEndTime() - xyd.DAY_TIME * (self.activityData:getViewTimeDay() + 1) then
		local timeStamp = xyd.db.misc:getValue("activity_spfarm_end_soon_tips")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.alertTips(__("ACTIVITY_SPFARM_TEXT83"))
			xyd.db.misc:setValue({
				key = "activity_spfarm_end_soon_tips",
				value = xyd.getServerTime()
			})
		end
	end
end

function ActivitySpfarm:getUIComponent()
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.imgBg = self.groupAction:ComponentByName("imgBg", typeof(UITexture))
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.helpBtn = self.upCon:NodeByName("helpBtn").gameObject
	self.awardBtn = self.upCon:NodeByName("awardBtn").gameObject
	self.rankBtn = self.upCon:NodeByName("rankBtn").gameObject
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.logoTextImg = self.centerCon:ComponentByName("logoTextImg", typeof(UISprite))
	self.imgText02 = self.centerCon:NodeByName("imgText02").gameObject
	self.labelTime = self.imgText02:ComponentByName("labelTime", typeof(UILabel))
	self.labelText01 = self.imgText02:ComponentByName("labelText01", typeof(UILabel))
	self.logoTextImgBg = self.centerCon:ComponentByName("logoTextImgBg", typeof(UISprite))
	self.descBg = self.centerCon:ComponentByName("descBg", typeof(UISprite))
	self.descLabel = self.descBg:ComponentByName("descLabel", typeof(UILabel))
	self.levelBg = self.centerCon:ComponentByName("levelBg", typeof(UISprite))
	self.levelDescLabel = self.levelBg:ComponentByName("levelDescLabel", typeof(UILabel))
	self.levelLabel = self.levelBg:ComponentByName("levelLabel ", typeof(UILabel))
	self.goBtn = self.centerCon:NodeByName("goBtn").gameObject
	self.goBtnLabel = self.goBtn:ComponentByName("goBtnLabel", typeof(UILabel))
	self.chatCon = self.groupAction:NodeByName("chatCon").gameObject
	self.chatBg = self.chatCon:ComponentByName("chatBg", typeof(UISprite))
	self.chatLabel = self.chatBg:ComponentByName("chatLabel", typeof(UILabel))
end

function ActivitySpfarm:initUIComponent()
	xyd.setUISpriteAsync(self.logoTextImg, nil, "activity_spfarm_logo_" .. xyd.Global.lang)

	if xyd.Global.lang == "de_de" then
		self.descLabel.width = 230
	elseif xyd.Global.lang == "ko_kr" then
		self.descLabel.gameObject:X(-78.4)
	end

	self.descLabel.text = __("ACTIVITY_SPFARM_TEXT01")
	self.levelDescLabel.text = __("ACTIVITY_SPFARM_TEXT02")

	self:updateGoBtn()
	self:initTime()
	self:initChat()
	self:updateTotalBuildLev()
end

function ActivitySpfarm:updateGoBtn()
	self.goBtnLabel.text = __("ACTIVITY_SPFARM_TEXT03")
	local mapRob = self.activityData:getMapRob()

	if mapRob and #mapRob > 0 then
		self.goBtnLabel.text = __("ACTIVITY_SPFARM_TEXT82")
	end

	if self.activityData:isViewing() or self.activityData:isEnd() then
		self.goBtnLabel.text = __("ACTIVITY_SPFARM_TEXT81")

		if self.activityData:isViewing() then
			local mapRob = self.activityData:getMapRob()

			if mapRob and #mapRob > 0 then
				self.activityData:endRob()
			end
		end
	end
end

function ActivitySpfarm:initTime()
	local endTime = self.activityData:getEndTime() - self.activityData:getViewTimeSec()
	local disTime = endTime - xyd:getServerTime()

	if disTime > 0 then
		local timeCount = CountDown.new(self.labelTime)

		timeCount:setInfo({
			duration = disTime,
			callback = function ()
				local mapRob = self.activityData:getMapRob()

				if mapRob and #mapRob > 0 then
					self.activityData:endRob()

					local activitySpfarmMapWd = xyd.WindowManager.get():getWindow("activity_spfarm_map_window")

					if activitySpfarmMapWd then
						xyd.alertConfirm(__("ACTIVITY_SPFARM_TEXT87"), nil, __("SURE"))
					else
						xyd.alertTips(__("ACTIVITY_END_YET"))
					end
				end

				self.labelTime.text = __("ACTIVITY_END_YET")
			end
		})
	else
		self.labelTime.text = __("ACTIVITY_END_YET")
	end
end

function ActivitySpfarm:initChat()
	local localShowChatIds = xyd.db.misc:getValue("activity_spfarm_chat_show_ids")
	local ids = xyd.tables.activitySpfarmDialogTextTable:getIDs()
	local totalLev = self.activityData:getAllBuildTotalLev()
	local showId = nil
	local isNew = false
	local curDay = self.activityData:getCurTimeDay()
	local allCanGetArr = {}

	for i, id in pairs(ids) do
		if xyd.tables.activitySpfarmDialogTable:getTime(id) <= curDay and xyd.tables.activitySpfarmDialogTable:getLevel(id) <= totalLev then
			table.insert(allCanGetArr, id)
		end
	end

	if not localShowChatIds then
		if not localShowChatIds then
			isNew = true
		end

		showId = ids[1]
		localShowChatIds = {}

		table.insert(localShowChatIds, showId)
	else
		localShowChatIds = json.decode(localShowChatIds)

		if #localShowChatIds >= #ids then
			showId = ids[#ids]
		elseif #localShowChatIds >= #allCanGetArr then
			showId = allCanGetArr[#allCanGetArr]
		else
			showId = allCanGetArr[#localShowChatIds + 1]
			isNew = true

			table.insert(localShowChatIds, showId)
		end
	end

	self.chatLabel.text = xyd.tables.activitySpfarmDialogTextTable:getContent(showId)

	xyd.db.misc:setValue({
		key = "activity_spfarm_chat_show_ids",
		value = json.encode(localShowChatIds)
	})

	if isNew then
		self.chatCon:SetLocalScale(0.011, 0.011, 1.5)

		local action = self:getSequence()

		action:Append(self.chatCon.transform:DOScale(1, 0.3))
		action:AppendCallback(function ()
			action:Kill(false)
		end)
	end
end

function ActivitySpfarm:resizeToParent()
	ActivitySpfarm.super.resizeToParent(self)
end

function ActivitySpfarm:onRegister()
	ActivitySpfarm.super.onRegister(self)

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_SPFARM_HELP1"
		})
	end

	UIEventListener.Get(self.goBtn).onClick = function ()
		if self.activityData:isEnd() then
			xyd.alertTips(__("ACTIVITY_END_YET"))

			return
		end

		local function callback()
			xyd.WindowManager:get():openWindow("activity_spfarm_map_window", {})
		end

		self:loadRes(callback)
	end

	UIEventListener.Get(self.awardBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("spfarm_check_award_window", {})
	end

	UIEventListener.Get(self.rankBtn).onClick = function ()
		if not self.activityData:reqFriendRank() then
			xyd.WindowManager.get():openWindow("activity_spfarm_rank_window", {})
		end
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivitySpfarm:updateTotalBuildLev()
	local levStr = "Lv." .. self.activityData:getAllBuildTotalLev()

	if xyd.Global.lang == "fr_fr" then
		levStr = "Niv." .. self.activityData:getAllBuildTotalLev()
	end

	self.levelLabel.text = levStr
end

function ActivitySpfarm:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SPFARM then
		return
	end

	local data = xyd.decodeProtoBuf(event.data)
	data.detail = json.decode(data.detail)
	local type = data.detail.type

	if type == xyd.ActivitySpfarmType.END_ROB then
		self:updateGoBtn()
	elseif type == xyd.ActivitySpfarmType.START_ROB then
		self:updateGoBtn()
	elseif type == xyd.ActivitySpfarmType.BUILD then
		self:updateTotalBuildLev()
	elseif type == xyd.ActivitySpfarmType.UP_GRADE then
		self:updateTotalBuildLev()
	elseif type == xyd.ActivitySpfarmType.RANK_LIST_FRIEND then
		xyd.WindowManager.get():openWindow("activity_spfarm_rank_window", {})
	end
end

function ActivitySpfarm:loadRes(callback)
	local res = xyd.getEffectFilesByNames({
		"fx_spfarm_gate_exit",
		"fx_spfarm_gate_upgrade",
		"fx_spfarm_lvlup",
		xyd.Battle.effect_switch
	})
	local path1 = xyd.getSpritePath("activity_spfarm_bg_1")

	table.insert(res, path1)

	local allHasRes = xyd.isAllPathLoad(res)

	if allHasRes then
		callback()

		return
	else
		ResCache.DownloadAssets("activity_spfarm", res, function (success)
			xyd.WindowManager.get():closeWindow("res_loading_window")

			if tolua.isnull(self.go) then
				return
			end

			callback()
		end, function (progress)
			local loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			if progress >= 1 and not loading_win then
				return
			end

			if not loading_win then
				xyd.WindowManager.get():openWindow("res_loading_window", {})
			end

			loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			loading_win:setLoadWndName("activity_lost_space_map_load_wd")
			loading_win:setLoadProgress("activity_lost_space_map_load_wd", progress)
		end, 1)
	end
end

return ActivitySpfarm
