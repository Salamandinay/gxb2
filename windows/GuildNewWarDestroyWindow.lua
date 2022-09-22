local BaseWindow = import(".BaseWindow")
local GuildNewWarDestroyWindow = class("GuildNewWarDestroyWindow", BaseWindow)
local cjson = require("cjson")

function GuildNewWarDestroyWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.nodeIndex = params.nodeIndex
	self.flagIndex = params.flagIndex
end

function GuildNewWarDestroyWindow:initWindow()
	GuildNewWarDestroyWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)

	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function GuildNewWarDestroyWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelWindowTitle = self.groupAction:ComponentByName("labelWindowTitle", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.imgFlag = self.topGroup:ComponentByName("imgFlag", typeof(UISprite))
	self.progressGroup = self.topGroup:NodeByName("progressGroup").gameObject
	self.progressGroupLayout = self.topGroup:ComponentByName("progressGroup", typeof(UILayout))
	self.labelHPText = self.progressGroup:ComponentByName("labelHPText", typeof(UILabel))
	self.progressBar = self.progressGroup:ComponentByName("progressBar", typeof(UIProgressBar))
	self.labelProgressValue = self.progressBar:ComponentByName("labelProgressValue", typeof(UILabel))
	self.progressImg = self.progressBar:ComponentByName("progressImg", typeof(UISprite))
	self.labelFlag = self.topGroup:ComponentByName("labelFlag", typeof(UILabel))
	self.labelTips = self.topGroup:ComponentByName("labelTips", typeof(UILabel))
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.labelTitle = self.midGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.itemGroup = self.midGroup:NodeByName("itemGroup").gameObject
	self.itemGroupLayout = self.midGroup:ComponentByName("itemGroup", typeof(UILayout))
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.labelLimit = self.bottomGroup:ComponentByName("labelLimit", typeof(UILabel))
	self.btnSure = self.bottomGroup:NodeByName("btnSure").gameObject
	self.labelSure = self.btnSure:ComponentByName("labelSure", typeof(UILabel))
end

function GuildNewWarDestroyWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GUILD_NEW_WAR_FIGHT, function (event)
		local data = xyd.decodeProtoBuf(event.data)
		self.activityData.isDestroyFight = nil

		xyd.openWindow("guild_new_war_destroy_result_window", {
			nodeIndex = self.nodeIndex,
			flagIndex = self.flagIndex,
			selfPoint = self.activityData.tempAddSelfScore or 0,
			enemyPoint = xyd.tables.miscTable:split2num("guild_new_war_flag_durability", "value", "|")[2]
		})

		if self.activityData:getMapNodeDatas()[self.nodeIndex].flagInfos[self.flagIndex].HP <= 0 then
			self:close()
		else
			self:updateFlagState()
		end
	end)

	UIEventListener.Get(self.btnClose.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnSure.gameObject).onClick = function ()
		if self.activityData:getLeftAttackTime() <= 0 then
			xyd.alertTips(__("GUILD_NEW_WAR_TIPS04"))

			return
		end

		if self.activityData:getMapNodeDatas()[self.nodeIndex].flagInfos[self.flagIndex].HP > 0 then
			self.activityData:reqFight(self.nodeIndex, self.flagIndex, nil, , function ()
				local hp = self.activityData:getMapNodeDatas()[self.nodeIndex].flagInfos[self.flagIndex].HP - xyd.tables.miscTable:split2num("guild_new_war_flag_durability", "value", "|")[2]
				self.activityData:getMapNodeDatas()[self.nodeIndex].flagInfos[self.flagIndex].HP = math.max(0, hp)

				self.activityData:updateMapInfo()
			end, true)
		else
			xyd.alertTips(__("GUILD_NEW_WAR_TEXT83"))
		end
	end
end

function GuildNewWarDestroyWindow:setTitle(title)
	self.labelWindowTitle.text = __("GUILD_NEW_WAR_TEXT51")
end

function GuildNewWarDestroyWindow:layout()
	self.data = self.activityData:getFlagData(self.nodeIndex, self.flagIndex)
	self.labelWindowTitle.text = __("GUILD_NEW_WAR_TEXT51")
	self.labelSure.text = __("GUILD_NEW_WAR_TEXT54")
	self.labelTitle.text = __("GUILD_NEW_WAR_TEXT42")
	self.labelTips.text = __("GUILD_NEW_WAR_TEXT52")
	self.labelFlag.text = __("GUILD_NEW_WAR_TEXT24", self.flagIndex)
	local spriteName = self.activityData:getFlagImgName(false, self.nodeIndex, self.data.HP <= 0)

	xyd.setUISpriteAsync(self.imgFlag, nil, spriteName, nil, , true)

	local helpData = xyd.tables.miscTable:split2Cost("guild_new_war_flag_durability", "value", "|")
	self.labelProgressValue.text = self.data.HP .. "/" .. helpData[1]
	self.progressBar.value = self.data.HP / helpData[1]
	local helpData2 = xyd.tables.miscTable:split2Cost("guild_new_war_attack_times", "value", "|")
	local leftTime = self.activityData:getLeftAttackTime()
	self.labelLimit.text = __("GUILD_NEW_WAR_TEXT68", leftTime .. "/" .. helpData2[2])
	self.icons = {}
	self.nodeType = self.activityData:getNodeType(self.nodeIndex)
	local awards = xyd.tables.guildNewWarBaseTable:getFlagAwards(self.nodeType)

	for i = 1, #awards do
		local award = awards[i]
		local params = {
			scale = 0.9074074074074074,
			uiRoot = self.itemGroup.gameObject,
			itemID = award[1],
			num = award[2]
		}

		if self.icons[i] then
			self.icons[i]:setInfo(params)
		else
			self.icons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		end
	end

	self.itemGroupLayout:Reposition()
	self.progressGroupLayout:Reposition()
end

function GuildNewWarDestroyWindow:updateFlagState()
	self.data = self.activityData:getFlagData(self.nodeIndex, self.flagIndex)
	self.labelFlag.text = __("GUILD_NEW_WAR_TEXT24", self.flagIndex)
	local spriteName = self.activityData:getFlagImgName(false, self.nodeIndex, self.data.HP <= 0)

	xyd.setUISpriteAsync(self.imgFlag, nil, spriteName, nil, , true)

	local helpData = xyd.tables.miscTable:split2Cost("guild_new_war_flag_durability", "value", "|")
	self.labelProgressValue.text = self.data.HP .. "/" .. helpData[1]
	self.progressBar.value = self.data.HP / helpData[1]
	local helpData2 = xyd.tables.miscTable:split2Cost("guild_new_war_attack_times", "value", "|")
	local leftTime = self.activityData:getLeftAttackTime()
	self.labelLimit.text = __("GUILD_NEW_WAR_TEXT68", leftTime .. "/" .. helpData2[2])

	self.progressGroupLayout:Reposition()
end

return GuildNewWarDestroyWindow
