local BaseWindow = import(".BaseWindow")
local GuildNewWarDestroyResultWindow = class("GuildNewWarDestroyResultWindow", BaseWindow)
local cjson = require("cjson")

function GuildNewWarDestroyResultWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.nodeIndex = params.nodeIndex or 1
	self.flagIndex = params.flagIndex or 1
	self.selfPoint = params.selfPoint or 0
	self.enemyPoint = params.enemyPoint or 0
	self.isCleanFight = params.isCleanFight or false
	self.selfGuildPoint = params.selfGuildPoint or 0
	self.num = params.num or 1
end

function GuildNewWarDestroyResultWindow:initWindow()
	GuildNewWarDestroyResultWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)

	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function GuildNewWarDestroyResultWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.labelGuildNewWarAwardText = self.midGroup:ComponentByName("labelGuildNewWarAwardText", typeof(UILabel))
	self.itemGroupGuildNewWar = self.midGroup:NodeByName("itemGroupGuildNewWar").gameObject
	self.itemGroupGuildNewWarLayout = self.midGroup:ComponentByName("itemGroupGuildNewWar", typeof(UILayout))
	self.labelGuildNewWarSelfPoint = self.midGroup:ComponentByName("labelGuildNewWarSelfPoint", typeof(UILabel))
	self.labelGuildNewWarEnemyPoint = self.midGroup:ComponentByName("labelGuildNewWarEnemyPoint", typeof(UILabel))
	self.lineImg1 = self.midGroup:NodeByName("lineImg1").gameObject
	self.lineImg2 = self.midGroup:NodeByName("lineImg2").gameObject
	self.effectPos = self.groupAction:ComponentByName("effectPos", typeof(UITexture))
	self.textImg = self.groupAction:ComponentByName("textImg", typeof(UITexture))
end

function GuildNewWarDestroyResultWindow:registerEvent()
end

function GuildNewWarDestroyResultWindow:layout()
	self.effectName = "shengli"
	self.labelImg = "battle_result_text03_" .. xyd.Global.lang

	self.lineImg1:SetActive(false)
	self.lineImg2:SetActive(false)
	xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_WIN)

	local sp1 = xyd.Spine.new(self.effectPos.gameObject)

	local function callback()
		sp1:SetLocalPosition(0, 120, 0)
		sp1:setPlayNeedStop(true)
		sp1:setNoStopResumeSetupPose(true)
		sp1:play("texiao01", 1, 1, function ()
			sp1:play("texiao02", 0)
		end)

		local sp2 = xyd.Spine.new(self.effectPos.gameObject)

		sp2:setInfo(self.effectName, function ()
			sp2:SetLocalPosition(0, 120, 5)
			sp2:setRenderTarget(self.effectPos, 0)
			sp2:play("texiao03", 1, 1, function ()
				sp2:play("texiao04", 0)
			end)
		end)
		self:waitForTime(0.3, function ()
			self.labelGuildNewWarSelfPoint.text = __("GUILD_NEW_WAR_TEXT55", self.selfPoint)
			self.labelGuildNewWarAwardText.text = __("GUILD_NEW_WAR_TEXT42")

			self.lineImg1:SetActive(true)
			self.lineImg2:SetActive(true)

			if self.isCleanFight then
				self.labelGuildNewWarEnemyPoint.text = __("GUILD_NEW_WAR_TEXT61", self.selfGuildPoint)
			else
				self.labelGuildNewWarEnemyPoint.text = __("GUILD_NEW_WAR_TEXT95", self.enemyPoint)
			end

			self.icons = {}
			self.nodeType = self.activityData:getNodeType(self.nodeIndex)
			local awards = xyd.tables.guildNewWarBaseTable:getFlagAwards(self.nodeType)

			if self.isCleanFight then
				awards = xyd.tables.guildNewWarBaseTable:getSweepAwards(self.nodeType)
			end

			for i = 1, #awards do
				local award = awards[i]
				local params = {
					scale = 0.7962962962962963,
					uiRoot = self.itemGroupGuildNewWar.gameObject,
					itemID = award[1],
					num = award[2] * self.num
				}

				if self.icons[i] then
					self.icons[i]:setInfo(params)
				else
					self.icons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
				end
			end

			self.itemGroupGuildNewWarLayout:Reposition()
		end, "")
	end

	xyd.setUITextureByNameAsync(self.textImg, self.labelImg, true)
	sp1:setInfo(self.effectName, function ()
		sp1:setRenderTarget(self.effectPos, 0)
		sp1:changeAttachment("zititihuan1", self.textImg)
		sp1:changeAttachment("zititihuan2", self.textImg)
		callback()
	end)
end

return GuildNewWarDestroyResultWindow
