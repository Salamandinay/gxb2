local NewPartnerWarmup = class("NewPartnerWarmup", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")
local json = require("cjson")

function NewPartnerWarmup:ctor(parentGO, params)
	NewPartnerWarmup.super.ctor(self, parentGO, params)
end

function NewPartnerWarmup:getPrefabPath()
	return "Prefabs/Windows/activity/new_partner_warmup"
end

function NewPartnerWarmup:resizeToParent()
	NewPartnerWarmup.super.resizeToParent(self)
	self:resizePosY(self.bg, 64, 0)
	self:resizePosY(self.imgText, 35, -22)
	self:resizePosY(self.groupTime, -272, -336)
	self:resizePosY(self.itemStage1, -428, -493)
	self:resizePosY(self.itemStage2, -607, -674)
	self:resizePosY(self.itemStage3, -784, -854)
end

function NewPartnerWarmup:initUI()
	self:getUIComponent()
	NewPartnerWarmup.super.initUI(self)
	self:initUIComponent()
	self:register()
	self:updateRedPoint()
end

function NewPartnerWarmup:getUIComponent()
	local go = self.go
	self.bg = go:NodeByName("bg").gameObject
	self.imgText = go:ComponentByName("imgText", typeof(UISprite))
	self.groupTime = go:NodeByName("groupTime").gameObject
	self.labelTime = self.groupTime:ComponentByName("groupLabel/labelTime", typeof(UILabel))
	self.labelEnd = self.groupTime:ComponentByName("groupLabel/labelEnd", typeof(UILabel))
	self.btnHelp = go:NodeByName("btnHelp").gameObject
	self.btnAward = go:NodeByName("btnAward").gameObject

	for i = 1, 4 do
		self["itemStage" .. i] = go:NodeByName("itemStage" .. i).gameObject
		self["btnStage" .. i] = self["itemStage" .. i]:ComponentByName("btn", typeof(UISprite))
		self["labelStage" .. i] = self["itemStage" .. i]:ComponentByName("label", typeof(UILabel))
		self["redPointStage" .. i] = self["itemStage" .. i]:NodeByName("redPoint").gameObject
	end
end

function NewPartnerWarmup:initUIComponent()
	xyd.setUISpriteAsync(self.imgText, nil, "new_partner_warmup_text_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.labelTime, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.labelEnd.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.labelEnd.transform:SetSiblingIndex(0)
	end

	self.curDays = math.ceil((xyd.getServerTime() - self.activityData.start_time) / 86400)

	for i = 1, 3 do
		local plotID = xyd.tables.newPartnerWarmUpStageTable:getPlotIds(i)
		self["labelStage" .. i].text = xyd.tables.partnerWarmUpPlotTextTable:getTitle(plotID[2])
		local unlockDay = xyd.tables.newPartnerWarmUpStageTable:getUnlockDay(i)

		if unlockDay <= self.curDays then
			xyd.setUISpriteAsync(self["btnStage" .. i], nil, "new_partner_warmup_btn_play")
		else
			xyd.setUISpriteAsync(self["btnStage" .. i], nil, "new_partner_warmup_btn_lock")
		end
	end
end

function NewPartnerWarmup:updateRedPoint()
	for i = 1, 3 do
		local unlockDay = xyd.tables.newPartnerWarmUpStageTable:getUnlockDay(i)

		if unlockDay <= self.curDays and self.activityData.detail.current_stage == i then
			self["redPointStage" .. i]:SetActive(true)
		else
			self["redPointStage" .. i]:SetActive(false)
		end
	end

	self.activityData:updateRedMark()
end

function NewPartnerWarmup:register()
	self:registerEvent(xyd.event.NEW_PARTNER_WARMUP_FIGHT, function (event)
		self:updateRedPoint()

		local curStage = self.activityData.detail.current_stage == -1 and 3 or self.activityData.detail.current_stage - 1
		local battleID = xyd.tables.newPartnerWarmUpStageTable:getBattleID(curStage)

		if not battleID or battleID == 0 then
			local plotID = xyd.tables.newPartnerWarmUpStageTable:getPlotIds(curStage)

			xyd.WindowManager.get():openWindow("story_window", {
				is_back = true,
				story_type = xyd.StoryType.OTHER,
				story_id = plotID[2]
			})

			local awards = xyd.tables.newPartnerWarmUpStageTable:getReward(curStage)

			for _, award in ipairs(awards) do
				xyd.itemFloat({
					{
						item_id = award[1],
						item_num = award[2]
					}
				})
			end
		end
	end)

	UIEventListener.Get(self.btnHelp.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "PARTNER_WARMUP_HELP"
		})
	end

	UIEventListener.Get(self.btnAward.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("new_partner_warmup_preview_window")
	end

	for i = 1, 3 do
		local function clickFunc()
			local unlockDay = xyd.tables.newPartnerWarmUpStageTable:getUnlockDay(i)

			if self.curDays < unlockDay then
				xyd.alertTips(xyd.secondsToString((unlockDay - 1) * 24 * 60 * 60 - (xyd.getServerTime() - self.activityData.start_time)) .. " " .. __("ACTIVITY_ENCOUNTER_STORY_TEXT04"))
			elseif self.activityData.detail.current_stage < i and self.activityData.detail.current_stage ~= -1 then
				xyd.alertTips(__("PARTNER_WARMUP_TEXT03"))
			elseif i < self.activityData.detail.current_stage or self.activityData.detail.current_stage == -1 then
				xyd.alertYesNo(__("PARTNER_WARMUP_TEXT04"), function (yes)
					if yes then
						local plotID = xyd.tables.newPartnerWarmUpStageTable:getPlotIds(i)

						xyd.WindowManager.get():openWindow("story_window", {
							is_back = true,
							story_type = xyd.StoryType.OTHER,
							story_id = plotID[2]
						})
					end
				end)
			else
				local msg = messages_pb.new_partner_warmup_fight_req()
				msg.activity_id = xyd.ActivityID.NEW_PARTNER_WARMUP
				msg.stage_id = i

				xyd.Backend.get():request(xyd.mid.NEW_PARTNER_WARMUP_FIGHT, msg)
			end
		end

		UIEventListener.Get(self["itemStage" .. i].gameObject).onClick = clickFunc
		UIEventListener.Get(self["btnStage" .. i].gameObject).onClick = clickFunc
	end
end

return NewPartnerWarmup
