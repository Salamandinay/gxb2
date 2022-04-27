local ActivityFireworkExplainWindow = class("ActivityFireworkExplainWindow", import(".BaseWindow"))

function ActivityFireworkExplainWindow:ctor(name, params)
	ActivityFireworkExplainWindow.super.ctor(self, name, params)
end

function ActivityFireworkExplainWindow:initWindow()
	self:getUIComponent()
	ActivityFireworkExplainWindow.super.initWindow(self)
	self:layout()
	self:registerEvent()
end

function ActivityFireworkExplainWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.titleCon = self.groupAction:NodeByName("titleCon").gameObject
	self.titleBg = self.titleCon:ComponentByName("titleBg", typeof(UISprite))
	self.titleText = self.titleCon:ComponentByName("titleText", typeof(UILabel))
	self.explainCon = self.groupAction:NodeByName("explainCon").gameObject
	self.explainText1 = self.explainCon:ComponentByName("explainText1", typeof(UILabel))
	self.explainText2 = self.explainCon:ComponentByName("explainText2", typeof(UILabel))
	self.explainText3 = self.explainCon:ComponentByName("explainText3", typeof(UILabel))
	self.explainText4 = self.explainCon:ComponentByName("explainText4", typeof(UILabel))
	self.nameCon = self.groupAction:NodeByName("nameCon").gameObject
	self.nameText1 = self.nameCon:ComponentByName("nameText1", typeof(UILabel))
	self.nameText2 = self.nameCon:ComponentByName("nameText2", typeof(UILabel))
	self.nameText3 = self.nameCon:ComponentByName("nameText3", typeof(UILabel))
	self.nameText4 = self.nameCon:ComponentByName("nameText4", typeof(UILabel))
	self.nameText5 = self.nameCon:ComponentByName("nameText5", typeof(UILabel))
	self.nameText6 = self.nameCon:ComponentByName("nameText6", typeof(UILabel))
	self.nameText7 = self.nameCon:ComponentByName("nameText7", typeof(UILabel))
	self.boomImg = self.groupAction:ComponentByName("boomImg", typeof(UISprite))
end

function ActivityFireworkExplainWindow:layout()
	xyd.setUISpriteAsync(self.boomImg, nil, "activity_firework_boom_" .. xyd.Global.lang)

	for i = 1, 4 do
		self["explainText" .. i].text = __("FIREWORK_EXPLAIN_TEXT0" .. i)
	end

	self.titleText.text = __("FIREWORK_EXPLAIN_TEXT09")
	self.nameText1.text = __("FIREWORK_EXPLAIN_TEXT06")
	self.nameText3.text = __("FIREWORK_EXPLAIN_TEXT06")
	self.nameText4.text = __("FIREWORK_EXPLAIN_TEXT07")
	self.nameText7.text = __("FIREWORK_EXPLAIN_TEXT07")
	self.nameText5.text = __("FIREWORK_EXPLAIN_TEXT08")
	self.nameText6.text = __("FIREWORK_EXPLAIN_TEXT08")
	self.nameText2.text = __("FIREWORK_EXPLAIN_TEXT10")

	if xyd.Global.lang == "fr_fr" then
		self.nameText5.width = 150
		self.nameText6.width = 150
	elseif xyd.Global.lang == "ko_kr" then
		for i = 1, 7 do
			self["nameText" .. i].fontSize = 22
		end
	end
end

function ActivityFireworkExplainWindow:registerEvent()
end

return ActivityFireworkExplainWindow
