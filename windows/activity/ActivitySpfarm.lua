local ActivityContent = import(".ActivityContent")
local ActivitySpfarm = class("ActivitySpfarm", ActivityContent)
local CountDown = import("app.components.CountDown")

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

	self.descLabel.text = __("ACTIVITY_SPFARM_TEXT01")
	self.levelDescLabel.text = __("ACTIVITY_SPFARM_TEXT02")
	self.goBtnLabel.text = __("ACTIVITY_SPFARM_TEXT03")

	self:initTime()
	self:initChat()
end

function ActivitySpfarm:initTime()
	local endTime = self.activityData:getEndTime()
	local disTime = endTime - xyd:getServerTime()

	if disTime > 0 then
		local timeCount = CountDown.new(self.labelTime)

		timeCount:setInfo({
			duration = disTime,
			callback = function ()
				self.labelTime.text = "00:00:00"
			end
		})
	else
		self.labelTime.text = "00:00:00"
	end
end

function ActivitySpfarm:initChat()
	self.chatCon:SetLocalScale(0.011, 0.011, 1)

	local action = self:getSequence()

	action:Append(self.chatCon.transform:DOScale(1, 0.3))
	action:AppendCallback(function ()
		action:Kill(false)
	end)
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
		xyd.WindowManager:get():openWindow("activity_spfarm_map_window", {})
	end
end

return ActivitySpfarm
