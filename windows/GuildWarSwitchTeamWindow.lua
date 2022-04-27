local BaseWindow = import(".BaseWindow")
local GuildWarSwitchTeamWindow = class("GuildWarSwitchTeamWindow", BaseWindow)

function GuildWarSwitchTeamWindow:ctor(name, params)
	GuildWarSwitchTeamWindow.super.ctor(self, name, params)

	self.currentIndex = params.currentIndex
	self.allNum = params.selectedNum
end

function GuildWarSwitchTeamWindow:initWindow()
	GuildWarSwitchTeamWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.winTitle_ = winTrans:ComponentByName("e:Group/titleLabel", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("e:Group/closeBtn").gameObject
	self.grid_ = winTrans:ComponentByName("e:Group/group/grid", typeof(UIGrid))
	self.teamBtn_ = winTrans:NodeByName("e:Group/group/btnTeam").gameObject

	self:layout()

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow("guild_war_switch_team_window")
	end
end

function GuildWarSwitchTeamWindow:layout()
	self.winTitle_.text = __(self:winName())

	for i = 1, self.allNum do
		local itemBtn = NGUITools.AddChild(self.grid_.gameObject, self.teamBtn_)
		local itemLabel = itemBtn:ComponentByName("btnLabel", typeof(UILabel))
		itemLabel.text = i

		UIEventListener.Get(itemBtn).onClick = function ()
			if self.currentIndex ~= i then
				local win = xyd.WindowManager.get():getWindow("guild_war_set_all_formation_window")

				if win then
					win:switchTeam(self.currentIndex, i)
				end
			end

			xyd.WindowManager.get():closeWindow("guild_war_switch_team_window")
		end
	end
end

return GuildWarSwitchTeamWindow
