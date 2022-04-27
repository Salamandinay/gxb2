local BaseWindow = import(".BaseWindow")
local DatesAttrWindow = class("DatesAttrWindow", BaseWindow)

function DatesAttrWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.lovePoint = params.love_point
	self.type = params.type
	self.partnerID = params.partner_id
	self.pos = params.pos
end

function DatesAttrWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
end

function DatesAttrWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupTip = winTrans:NodeByName("groupTip").gameObject
	self.bg = self.groupTip:NodeByName("bg").gameObject
	self.tips0 = self.groupTip:ComponentByName("tips0", typeof(UILabel))
	self.groupAttr = self.groupTip:NodeByName("groupAttr").gameObject
	self.tips1 = self.groupAttr:ComponentByName("groupLeft/tips1", typeof(UILabel))
	self.tips2 = self.groupAttr:ComponentByName("groupRight/tips2", typeof(UILabel))
	self.tips3 = self.groupAttr:ComponentByName("groupLeft/tips3", typeof(UILabel))
	self.tips4 = self.groupAttr:ComponentByName("groupRight/tips4", typeof(UILabel))
end

function DatesAttrWindow:layout()
	self:initTipPos()

	local content = xyd.tables.datesTextTable:getText(self.lovePoint)
	local p = xyd.models.slot:getPartner(self.partnerID)
	local str = xyd.stringFormat(content, p:getName())
	self.tips0.text = str
	self.tips1.text = __("DATES_TEXT09")
	self.tips3.text = __("DATES_TEXT11")
	self.tips2.text = math.floor(self.lovePoint / 100) .. "/100"
	local attrs = xyd.tables.datesTable:getAttr(self.lovePoint)

	if #attrs == 0 then
		self.tips4.text = __("DATES_TEXT13")
	else
		local str2 = ""
		local DBuffTable = xyd.tables.dBuffTable

		for i = 1, #attrs do
			str2 = DBuffTable:translationDesc(attrs[i])

			if i < #attrs then
				str2 = str2 .. "\n"
			end
		end

		self.tips4.text = str2
	end
end

function DatesAttrWindow:initTipPos()
	local curPos = self.window_.transform:InverseTransformPoint(self.pos)

	if self.type == "dates" then
		self.groupTip:SetLocalPosition(curPos.x - 278, curPos.y, 0)
	else
		self.bg:SetLocalScale(1, 1, 1)
		self.bg:SetLocalPosition(-30, 0, 0)
		self.groupTip:SetLocalPosition(curPos.x + 278, curPos.y, 0)
	end
end

return DatesAttrWindow
