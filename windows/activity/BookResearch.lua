local ActivityContent = import(".ActivityContent")
local BookResearch = class("BookResearch", ActivityContent)
local CountDown = require("app.components.CountDown")

function BookResearch:ctor(name, params)
	ActivityContent.ctor(self, name, params)
	self:getUIComponent()
	self:layout()
	self:onRegisterEvent()
end

function BookResearch:getPrefabPath()
	return "Prefabs/Windows/activity/book_research"
end

function BookResearch:getUIComponent()
	local go = self.go
	self.btn = go:NodeByName("mainGroup/midGroup/buyBtn").gameObject
	self.btnLabel = go:ComponentByName("mainGroup/midGroup/buyBtn/label", typeof(UILabel))
	self.rankBtn = go:NodeByName("mainGroup/rankBtn").gameObject
	self.helpBtn = go:NodeByName("mainGroup/helpBtn").gameObject
	self.label1 = go:ComponentByName("mainGroup/midGroup/label1", typeof(UILabel))
	self.label2 = go:ComponentByName("mainGroup/midGroup/label2", typeof(UILabel))
	self.label3 = go:ComponentByName("mainGroup/midGroup/label3", typeof(UILabel))
	self.label4 = go:ComponentByName("mainGroup/midGroup/label4", typeof(UILabel))
	self.imgText = go:ComponentByName("mainGroup/imgText", typeof(UISprite))
	self.timeGroup = go:ComponentByName("mainGroup/imgText/timeGroup", typeof(UILayout))
	self.timeLabel = go:ComponentByName("mainGroup/imgText/timeGroup/timeLabel", typeof(UILabel))
	self.endLabel = go:ComponentByName("mainGroup/imgText/timeGroup/endLabel", typeof(UILabel))
end

function BookResearch:layout()
	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.endLabel.text = __("TEXT_END")

	self.timeGroup:Reposition()

	self.label1.text = __("BOOK_RESEARCH_TEXT01")
	self.label2.text = self.activityData.detail.max_score
	self.label3.text = __("BOOK_RESEARCH_TEXT03")
	self.label4.text = self.activityData.detail.challenge_times
	self.btnLabel.text = __("BOOK_RESEARCH_TEXT10")

	xyd.setUISpriteAsync(self.imgText, nil, "activity_book_research_entry_" .. xyd.Global.lang)
end

function BookResearch:onRegisterEvent()
	UIEventListener.Get(self.btn).onClick = function ()
		xyd.openWindow("jump_game_window")
	end

	UIEventListener.Get(self.rankBtn).onClick = function ()
		xyd.openWindow("book_research_rank_window")
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.openWindow("help_window", {
			key = "BOOK_RESEARCH_HELP"
		})
	end
end

return BookResearch
