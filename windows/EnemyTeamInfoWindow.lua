local BaseWindow = import(".BaseWindow")
local EnemyTeamInfoWindow = class("EnemyTeamInfoWindow", BaseWindow)

function EnemyTeamInfoWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "EnemyTeamInfoWindowSkin"
	self.data_ = params
end

function EnemyTeamInfoWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function EnemyTeamInfoWindow:getUIComponent()
	local trans = self.window_.transform
	self.content = trans:NodeByName("content").gameObject
	self.labelWinTitle = self.content:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.content:NodeByName("closeBtn").gameObject
	self.label1 = self.content:ComponentByName("label1", typeof(UILabel))
	self.label2 = self.content:ComponentByName("label2", typeof(UILabel))

	for i = 1, 6 do
		self["group" .. i] = self.content:NodeByName("group" .. i).gameObject
	end
end

function EnemyTeamInfoWindow:layout()
	self.label1.text = __("HEAD_POS")
	self.label2.text = __("BACK_POS")
	local battleID = self.data_.battle_id
	local monsterIDs = xyd.tables.battleTable:getMonsters(battleID)
	local stands = xyd.tables.battleTable:getStands(battleID)
	local monsterTable = xyd.tables.monsterTable

	for i = 1, #monsterIDs do
		local pos = stands[i]
		local tableID = monsterIDs[i]
		local paramsA = {
			noClickSelected = true,
			isMonster = true,
			tableID = tableID,
			lev = monsterTable:getShowLev(tableID),
			callback = function ()
				xyd.WindowManager.get():openWindow("partner_info", {
					notShowWays = true,
					isHideForce = true,
					isHideAttr = true,
					table_id = xyd.tables.monsterTable:getPartnerLink(tableID),
					lev = monsterTable:getShowLev(tableID)
				})
			end,
			uiRoot = self["group" .. tostring(pos)]
		}
		local iconA = xyd.getHeroIcon(paramsA)

		iconA.go.transform:SetLocalScale(0.79, 0.79, 1)
	end
end

return EnemyTeamInfoWindow
