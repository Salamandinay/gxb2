local BaseWindow = import(".BaseWindow")
local GroupBuffDetailWindow = class("GroupBuffDetailWindow", BaseWindow)
local GroupBuffIcon = import("app.components.GroupBuffIcon")

function GroupBuffDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = nil
	self.StageTable = xyd.tables.stageTable
	self.GroupBuffTable = xyd.tables.groupBuffTable
	self.GroupBuffTextTable = xyd.tables.groupBuffTextTable
	self.DBuffTable = xyd.tables.dBuffTable
	self.skinName = "GroupBuffDetailWindowSkin"
	self.buffID_ = params.buffID
	self.type_ = params.type or xyd.GroupBuffIconType.GROUP_BUFF

	if params.contenty then
		self.contenty = params.contenty
	end
end

function GroupBuffDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponents()
	self:initLayOut()
end

function GroupBuffDetailWindow:update(params)
	self.buffID_ = params.buffID
	self.type_ = params.type or xyd.GroupBuffIconType.GROUP_BUFF

	if params.contenty then
		self.contenty = params.contenty
	end

	self:initLayOut()
end

function GroupBuffDetailWindow:getUIComponents()
	local trans = self.window_.transform
	local content = trans:NodeByName("content").gameObject

	if self.contenty then
		content:Y(self.contenty)
	end

	self.bgImg = content:ComponentByName("bgImg", typeof(UISprite))
	local top = content:NodeByName("top").gameObject
	self.labelName = top:ComponentByName("labelName", typeof(UILabel))
	self.labelLine1 = top:ComponentByName("labelLine1", typeof(UILabel))

	if xyd.Global.lang == "ja_jp" then
		self.labelLine1.fontSize = 17
	end

	self.buffIconGroup = top:NodeByName("buffIconGroup").gameObject
	self.content = content:GetComponent(typeof(UIWidget))
	local bottom = content:NodeByName("bottom").gameObject
	self.labelDes = bottom:ComponentByName("labelDes", typeof(UILabel))
	local attrGroup = bottom:NodeByName("attrGroup").gameObject
	self.attrGroupTable = attrGroup:GetComponent(typeof(UITable))
	self.labelAttr1 = attrGroup:ComponentByName("labelAttr1", typeof(UILabel))
	self.labelAttr2 = attrGroup:ComponentByName("labelAttr2", typeof(UILabel))
	self.labelAttrNum1 = attrGroup:ComponentByName("labelAttrNum1", typeof(UILabel))
	self.labelAttrNum2 = attrGroup:ComponentByName("labelAttrNum2", typeof(UILabel))
	self.initHeight = self.labelDes.height
	self.baseConHeight = self.content.height
end

function GroupBuffDetailWindow:initLayOut()
	local buffIcon = nil

	if not self.buffIcon_ then
		buffIcon = GroupBuffIcon.new(self.buffIconGroup)
		self.buffIcon_ = buffIcon
	else
		buffIcon = self.buffIcon_
	end

	buffIcon:setInfo(self.buffID_, true, self.type_)
	buffIcon:SetLocalScale(0.85, 0.85, 1)

	self.labelLine1.text = __("GROUP_BUFF_DES")
	local desc, name_, effectShowData = nil

	if self.type_ == xyd.GroupBuffIconType.HERO_CHALLENGE then
		desc = xyd.tables.partnerChallengeBuffTable:getDesc(self.buffID_)
		name_ = xyd.tables.partnerChallengeBuffTable:getName(self.buffID_)
		effectShowData = {}
	elseif self.type_ == xyd.GroupBuffIconType.NEW_TRIAL then
		desc = xyd.tables.newTrialBuffTable:getDesc(self.buffID_)
		name_ = xyd.tables.newTrialBuffTable:getName(self.buffID_)
		effectShowData = {}
	elseif self.type_ == xyd.GroupBuffIconType.FAIRY_TALE then
		desc = xyd.tables.activityFairyTaleBuffTable:getDesc(self.buffID_)
		name_ = xyd.tables.activityFairyTaleBuffTable:getName(self.buffID_)
		effectShowData = {}
	elseif self.type_ == xyd.GroupBuffIconType.SPORTS then
		desc = __("ACTIVITY_SPORTS_FIGHT_BUFF")
		name_ = __("ACTIVITY_SPORTS_FIGHT_BUFF_TITLE")
		effectShowData = {}
		self.labelLine1.text = ""
	elseif self.type_ == xyd.GroupBuffIconType.FAIR_ARENA then
		desc = xyd.tables.activityFairArenaBoxBuffTable:getDesc(self.buffID_)
		name_ = xyd.tables.activityFairArenaBoxBuffTable:getName(self.buffID_)
		effectShowData = {}
	else
		desc = self.GroupBuffTextTable:getDesc(self.buffID_)
		name_ = self.GroupBuffTextTable:getName(self.buffID_)
		effectShowData = xyd.split(self.GroupBuffTable:getEffectShow(self.buffID_), "|")
	end

	self.labelDes.text = desc
	self.labelName.text = name_
	local height = self.labelDes.height - self.initHeight
	local poses = xyd.tables.groupBuffTable:getEffectStands(self.buffID_)

	for i = 1, #effectShowData do
		if effectShowData[i] then
			local effectData = xyd.split(effectShowData[i], "#")
			local effectName = effectData[1]
			local effectNum = tonumber(effectData[2])
			local pos_label = self:getPosDesc(poses[i])

			if pos_label ~= "" then
				self["labelAttr" .. i].text = __("POSITION_DESC", pos_label, xyd.tables.dBuffTable:getDesc(effectName))
			else
				self["labelAttr" .. i].text = xyd.tables.dBuffTable:getDesc(effectName)
			end

			local factor = tonumber(self.DBuffTable:getFactor(effectName) or 1)

			if self.DBuffTable:isShowPercent(effectName) then
				self["labelAttrNum" .. tostring(i)].text = "+ " .. tostring(effectNum / factor * 100) .. "%"
			else
				self["labelAttrNum" .. tostring(i)].text = "+ " .. tostring(effectNum)
			end

			height = height + 30
		end
	end

	self.attrGroupTable:Reposition()

	self.content.height = self.baseConHeight + height
end

function GroupBuffDetailWindow:getPosDesc(pos)
	if not pos then
		return ""
	end

	local result = ""
	local poses = xyd.split(pos, "|", true)

	if #poses == 6 then
		-- Nothing
	elseif #poses == 2 and poses[1] == 1 and poses[2] == 2 then
		result = __("HEAD_POS1")
	else
		result = __("BACK_POS1")
	end

	return result
end

function GroupBuffDetailWindow:willClose()
	BaseWindow.willClose(self)
end

return GroupBuffDetailWindow
