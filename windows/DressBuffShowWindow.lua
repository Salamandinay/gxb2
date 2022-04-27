local DressBuffShowWindow = class("DressBuffShowWindow", import(".BaseWindow"))

function DressBuffShowWindow:ctor(name, params)
	DressBuffShowWindow.super.ctor(self, name, params)

	self.style_id = params.style_id
	self.nums = params.nums
end

function DressBuffShowWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function DressBuffShowWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bg = self.groupAction:ComponentByName("bg", typeof(UIWidget))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.explainText = self.groupAction:ComponentByName("explainText", typeof(UILabel))
end

function DressBuffShowWindow:layout()
	self.labelTitle.text = __("DRESS_BUFF_SHOW_WINDOW_1")
	self.explainText.text = xyd.tables.senpaiDressSkillBuffTextTable:getDesc(self.style_id, unpack(self.nums))
	self.bg.height = 140 + self.explainText.height

	self.explainText.gameObject:Y((self.explainText.height - 60) / 2)
end

function DressBuffShowWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

return DressBuffShowWindow
