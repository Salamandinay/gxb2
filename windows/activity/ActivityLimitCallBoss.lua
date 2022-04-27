local ActivityLimitCallBoss = class("ActivityLimitCallBoss", import(".ActivityContent"))
local Partner = import("app.models.Partner")
local SkillIcon = import("app.components.SkillIcon")
local CountDown = import("app.components.CountDown")

function ActivityLimitCallBoss:ctor(parentGO, params, parent)
	ActivityLimitCallBoss.super.ctor(self, parentGO, params, parent)
end

function ActivityLimitCallBoss:getPrefabPath()
	return "Prefabs/Windows/activity/activity_limit_call_boss"
end

function ActivityLimitCallBoss:initUI()
	self:getUIComponent()
	ActivityLimitCallBoss.super.initUI(self)
	self:initUIComponent()
	self:updateContent()
end

function ActivityLimitCallBoss:getUIComponent()
	local go = self.go
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.rankBtn = go:NodeByName("rankBtn").gameObject
	self.awardBtn = go:NodeByName("awardBtn").gameObject
	self.textImg_ = go:ComponentByName("textImg_", typeof(UISprite))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel_ = go:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.endLabel_ = go:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.skillGroup = self.contentGroup:NodeByName("skillGroup").gameObject
	self.skillDesc = self.contentGroup:NodeByName("skillDesc").gameObject
	self.challengeBtn = self.contentGroup:NodeByName("challengeBtn").gameObject
	self.tipGroup = self.contentGroup:NodeByName("tipGroup").gameObject
	self.jumpBtn = self.contentGroup:NodeByName("nameGroup/bg2").gameObject
	self.nameLabel = self.contentGroup:ComponentByName("nameGroup/name", typeof(UILabel))
	self.tipLabel_ = self.tipGroup:ComponentByName("tipLabel_", typeof(UILabel))
	self.numLabel_ = self.tipGroup:ComponentByName("numLabel_", typeof(UILabel))
end

function ActivityLimitCallBoss:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "activity_limit_call_boss_new_" .. xyd.Global.lang)
	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	})

	self.endLabel_.text = __("END")
	self.tipLabel_.text = __("ACTIVITY_LIMIT_CALL_BOSS_CHALLENGE")
	self.nameLabel.text = xyd.tables.partnerTable:getName(xyd.tables.miscTable:getNumber("activity_new_partner_test_id", "value"))
	self.challengeBtn:ComponentByName("button_label", typeof(UILabel)).text = __("FIGHT3")

	self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
	self:initSkillGroup()
end

function ActivityLimitCallBoss:initSkillGroup()
	self.skillItems_ = {}
	local skills = xyd.tables.miscTable:split2num("activity_limit_gacha_boss_skill", "value", "|")

	for key = 1, #skills do
		local icon = SkillIcon.new(self.skillGroup)

		icon:setInfo(skills[key], {
			scale = 0.8,
			showGroup = self.skillDesc,
			callback = function ()
				if xyd.Global.lang == "en_en" or xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
					icon:showTips(true, icon.showGroup, true, 700)

					if xyd.Global.lang == "de_de" or xyd.Global.lang == "en_en" then
						self.skillDesc:Y(-300)
					end
				else
					icon:showTips(true, icon.showGroup, true)
				end
			end
		})

		UIEventListener.Get(icon.go).onSelect = function (go, isSelect)
			if not isSelect then
				self:clearSkillTips()
			end
		end

		table.insert(self.skillItems_, icon)
	end

	self.skillGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityLimitCallBoss:updateContent(event)
	self.times = self.activityData.detail.challenge_times
	self.numLabel_.text = self.times .. "/" .. xyd.tables.miscTable:getVal("activity_limit_gacha_boss_limit")

	xyd.models.redMark:setMark(xyd.RedMarkType.TIME_LIMIT_BOSS, self.activityData:getRedMarkState())
end

function ActivityLimitCallBoss:onRegister()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.openWindow("help_window", {
			key = "GACHA_LIMIT_BOSS_HELP"
		})
	end

	UIEventListener.Get(self.rankBtn).onClick = function ()
		xyd.openWindow("rank_window", {
			mapType = xyd.MapType.LIMIT_CALL_BOSS
		})
	end

	UIEventListener.Get(self.awardBtn).onClick = function ()
		xyd.openWindow("limit_call_boss_award_window")
	end

	UIEventListener.Get(self.jumpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("guide_detail_window", {
			partners = {
				{
					table_id = xyd.tables.miscTable:getNumber("activity_new_partner_test_id", "value")
				}
			},
			table_id = xyd.tables.miscTable:getNumber("activity_new_partner_test_id", "value")
		})
	end

	UIEventListener.Get(self.challengeBtn).onClick = handler(self, self.onChallenge)

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateContent))
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.LIMIT_GACHA_AWARD)

		if activityData then
			activityData:initRedMark()
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.LIMIT_GACHA_AWARD, function ()
			end)
		end
	end)
end

function ActivityLimitCallBoss:onChallenge()
	if self.times > 0 then
		xyd.WindowManager.get():openWindow("battle_formation_window", {
			showSkip = false,
			battleType = xyd.BattleType.LIMIT_CALL_BOSS,
			mapType = xyd.MapType.TRIAL
		})
	else
		xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_ICE_SECRET_BOSS_TEXT02"))
	end
end

function ActivityLimitCallBoss:clearSkillTips()
	for _, item in ipairs(self.skillItems_) do
		item:showTips(false, item.showGroup)
	end
end

function ActivityLimitCallBoss:resizeToParent()
	ActivityLimitCallBoss.super.resizeToParent(self)
	self.go:Y(-435)

	local height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height
	local offsetY = height - 869

	self.contentGroup:Y(110 - offsetY * 0.63)
	self.skillGroup:Y(-365 - offsetY * 0.17)
	self.skillDesc:Y(-290 - offsetY * 0.17)
	self.challengeBtn:Y(-468 - offsetY * 0.25)
	self.tipGroup:Y(-526 - offsetY * 0.3)

	if xyd.Global.lang == "de_de" then
		self.go:ComponentByName("timeBg_", typeof(UISprite)).width = 270
	end
end

return ActivityLimitCallBoss
