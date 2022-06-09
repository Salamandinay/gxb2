local ActivitySpfarmOpponentWindow = class("ActivitySpfarmOpponentWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local PersonItem = class("PersonItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivitySpfarmOpponentWindow:ctor(name, params)
	ActivitySpfarmOpponentWindow.super.ctor(self, name, params)

	self.infos = params.infos
end

function ActivitySpfarmOpponentWindow:initWindow()
	self:getUIComponent()
	ActivitySpfarmOpponentWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function ActivitySpfarmOpponentWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.winTitle = self.topGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.topGroup:NodeByName("closeBtn").gameObject
	self.descLabel = self.groupAction:ComponentByName("descLabel", typeof(UILabel))

	for i = 1, 3 do
		self["itemPanel" .. i] = self.groupAction:NodeByName("itemPanel" .. i).gameObject
	end

	self.item = self.groupAction:NodeByName("item").gameObject
end

function ActivitySpfarmOpponentWindow:reSize()
end

function ActivitySpfarmOpponentWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivitySpfarmOpponentWindow:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SPFARM then
		return
	end

	local data = xyd.decodeProtoBuf(event.data)
	data.detail = json.decode(data.detail)
	local type = data.detail.type

	if type == xyd.ActivitySpfarmType.START_ROB then
		self:close()
	end
end

function ActivitySpfarmOpponentWindow:layout()
	self.winTitle.text = __("ACTIVITY_SPFARM_TEXT35")
	self.descLabel.text = __("ACTIVITY_SPFARM_TEXT36")

	for i = 1, 3 do
		local tmp = NGUITools.AddChild(self["itemPanel" .. i].gameObject, self.item.gameObject)
		self["item" .. i] = PersonItem.new(tmp, self)

		self["item" .. i]:setInfo(self.infos[i])
	end
end

function PersonItem:ctor(goItem, parent)
	self.goItem = goItem
	self.parent = parent

	PersonItem.super.ctor(self, goItem)
end

function PersonItem:getUIComponent()
	self.item = self.go
	self.bottomBg = self.item:ComponentByName("bottomBg", typeof(UISprite))
	self.personCon = self.item:NodeByName("personCon").gameObject
	self.powerCon = self.item:NodeByName("powerCon").gameObject
	self.powerBg = self.powerCon:ComponentByName("powerBg", typeof(UISprite))
	self.powerIcon = self.powerCon:ComponentByName("powerIcon", typeof(UISprite))
	self.powerLabel = self.powerCon:ComponentByName("powerLabel", typeof(UILabel))
	self.levCon = self.item:NodeByName("levCon").gameObject
	self.levBg = self.levCon:ComponentByName("levBg", typeof(UISprite))
	self.levLeftLabel = self.levCon:ComponentByName("levLeftLabel", typeof(UILabel))
	self.levRightLabel = self.levCon:ComponentByName("levRightLabel", typeof(UILabel))
	self.btnCon = self.item:NodeByName("btnCon").gameObject
	self.btn = self.btnCon:NodeByName("btn").gameObject
	self.btnLabel = self.btn:ComponentByName("btnLabel", typeof(UILabel))
	self.btnIcon = self.btn:NodeByName("btnIcon").gameObject
	self.btnIconUISprite = self.btn:ComponentByName("btnIcon", typeof(UISprite))
	self.btnIconNum = self.btn:ComponentByName("btnIconNum", typeof(UILabel))
end

function PersonItem:initUI()
	self:getUIComponent()
	self:register()

	self.btnLabel.text = __("ACTIVITY_SPFARM_TEXT40")

	if xyd.Global.lang == "de_de" then
		self.btnLabel.width = 80
	end

	self.levLeftLabel.text = __("ACTIVITY_SPFARM_TEXT02")

	if xyd.Global.lang == "ja_jp" then
		self.levLeftLabel.height = 30
	end
end

function PersonItem:register()
	UIEventListener.Get(self.btn.gameObject).onClick = handler(self, function ()
		if xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_SPFARM_ROB_TICKET) < 1 then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.ACTIVITY_SPFARM_ROB_TICKET)))

			return
		else
			xyd.WindowManager.get():openWindow("activity_spfarm_select_partner_window", {
				player_id = self.info.player_id
			})
		end
	end)
end

function PersonItem:setInfo(info)
	local allBuildLev = 0
	local power = 0
	self.info = info

	for i = 2, #info.build_infos do
		allBuildLev = allBuildLev + info.build_infos[i].lv

		if info.build_infos[i].partners and #info.build_infos[i].partners > 0 then
			for k, partnerInfo in pairs(info.build_infos[i].partners) do
				power = power + partnerInfo.power
			end
		end
	end

	self.levRightLabel.text = tostring(allBuildLev)
	self.powerLabel.text = tostring(power)

	if not self.normalModel_ then
		self.normalModel_ = import("app.components.SenpaiModel").new(self.personCon.gameObject)
	end

	local ids = info.dress_style

	self.normalModel_:setModelInfo({
		isNewClipShader = false,
		ids = ids
	})
end

return ActivitySpfarmOpponentWindow
