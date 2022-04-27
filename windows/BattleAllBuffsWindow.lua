local BaseWindow = import(".BaseWindow")
local BattleAllBuffsWindow = class("BattleAllBuffsWindow", BaseWindow)
local BattleAllBuffsWindowItem = class("BattleAllBuffsWindowItem", import("app.components.CopyComponent"))
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")
local DBuffTable = xyd.tables.dBuffTable

function BattleAllBuffsWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.selfFighters = params.selfFighters
	self.sideFighters = params.sideFighters
	self.callback = params.callback
	self.jsonLists = {}
end

function BattleAllBuffsWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initItems()
	self:register()
end

function BattleAllBuffsWindow:willClose()
	BattleAllBuffsWindow.super.willClose(self)

	if self.callback ~= nil then
		self:callback()
	end
end

function BattleAllBuffsWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.windowItem = winTrans:NodeByName("windowItem").gameObject
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.selfWords = self.groupAction:ComponentByName("selfWords", typeof(UILabel))
	self.sideWords = self.groupAction:ComponentByName("sideWords", typeof(UILabel))
	self.scrollview = self.groupAction:NodeByName("scrollview").gameObject
	self.grid = self.scrollview:NodeByName("grid").gameObject
	self.tipsWords = self.groupAction:ComponentByName("tipsWords", typeof(UILabel))
end

function BattleAllBuffsWindow:layout()
	self.selfWords.text = __("SELF")
	self.sideWords.text = __("ENEMY")
	self.tipsWords.text = __("BATTLE_BUFF_SEC")
end

function BattleAllBuffsWindow:initItems()
	self.items = {}

	for i = 1, 6 do
		local params = {
			index = i,
			selfFighter = self.selfFighters[i],
			sideFighter = self.sideFighters[i]
		}
		local goRoot = NGUITools.AddChild(self.grid, self.windowItem)
		self.items[i] = BattleAllBuffsWindowItem.new(goRoot, self, params)
	end

	self.windowItem:SetActive(false)
end

function BattleAllBuffsWindowItem:ctor(parentGo, parent, params)
	self.parent_ = parent

	BattleAllBuffsWindowItem.super.ctor(self, parentGo)

	self.index = params.index
	self.leftPartner_ = params.selfFighter
	self.rightPartner_ = params.sideFighter

	self:initUI()
	self:initLayout()
end

function BattleAllBuffsWindowItem:initUI()
	BattleAllBuffsWindowItem.super.initUI(self)

	local goTrans = self.go.transform
	self.colorBg = goTrans:NodeByName("colorBg").gameObject
	self.playerIcon1 = goTrans:NodeByName("playerIcon1").gameObject
	self.playerIcon2 = goTrans:NodeByName("playerIcon2").gameObject
	self.list1 = goTrans:NodeByName("list1").gameObject
	self.list2 = goTrans:NodeByName("list2").gameObject
	self.buffItem = goTrans:NodeByName("buffItem").gameObject
	self.click1 = goTrans:NodeByName("click1").gameObject
	self.click2 = goTrans:NodeByName("click2").gameObject
end

function BattleAllBuffsWindowItem:getIcon(data, parentGo)
	local icon = nil
	local tableId = data.tableID_
	local lev = data.level
	local partnerInfo = nil

	if data.isMonster then
		lev = xyd.tables.monsterTable:getShowLev(tableId)
		local pTableID = xyd.tables.monsterTable:getPartnerLink(tableId)
		local star = xyd.tables.partnerTable:getStar(pTableID)
		partnerInfo = {
			noClick = true,
			tableID = pTableID,
			lev = lev,
			star = star,
			skin_id = data:getSkin()
		}
	else
		local partner = Partner.new()

		partner:populate({
			table_id = tableId,
			lev = lev,
			awake = data.awake,
			show_skin = data.isShowSkin_,
			equips = {
				0,
				0,
				0,
				0,
				0,
				0,
				data:getSkin()
			}
		})

		partnerInfo = partner:getInfo()
		partnerInfo.noClick = true
	end

	icon = HeroIcon.new(parentGo)

	icon:setInfo(partnerInfo)

	icon.scale = 0.7

	return icon
end

function BattleAllBuffsWindowItem:updateBuffsList(isRight)
	local data = self.leftPartner_
	local listNode = self.list1

	if isRight then
		data = self.rightPartner_
		listNode = self.list2
	end

	local count = 0
	local showBuffs = {}

	local function checkHave(path)
		local data = nil

		for i = 1, #showBuffs do
			local val = showBuffs[i]

			if val.path == path then
				data = val

				break
			end
		end

		return data
	end

	for i = #data.buffs, 1, -1 do
		local buff = data.buffs[i]
		local icon1 = DBuffTable:getIcon1(buff.name)
		local path = icon1
		local icon2 = DBuffTable:getIcon2(buff.name)

		if icon2 and icon2 ~= "" and buff.value < 0 then
			path = icon2
		end

		if path ~= nil and path ~= "" then
			local data = checkHave(path)

			if data then
				data.num = data.num + 1

				if buff.name == "weak" then
					data.num = 1
				end
			elseif count < 18 then
				table.insert(showBuffs, {
					num = 1,
					path = path,
					name = buff.name,
					value = buff.value
				})

				count = count + 1
			end
		end
	end

	for i = #showBuffs, 1, -1 do
		local path = showBuffs[i].path
		local num = showBuffs[i].num
		local node = NGUITools.AddChild(listNode, self.buffItem)

		node:SetActive(true)

		local line = math.floor((i - 1) / 6)
		local index = (i - 1) % 6

		node:SetLocalPosition(32 * index - 94 + 16, -34 * line + 38 - 16, 0)

		local img = node:ComponentByName("buffIcon", typeof(UISprite))
		local label = node:ComponentByName("buffNum", typeof(UILabel))

		xyd.setUISprite(img, xyd.Atlas.BATTLE, path)

		label.text = num

		if num == 1 then
			label:SetActive(false)
		else
			label:SetActive(true)
		end
	end

	if isRight then
		self.hasRight = #showBuffs > 0
		self.rightIcons = showBuffs
	else
		self.hasLeft = #showBuffs > 0
		self.leftIcons = showBuffs
	end
end

function BattleAllBuffsWindowItem:initLayout()
	if self.leftPartner_ then
		local heroIcon = self:getIcon(self.leftPartner_, self.playerIcon1)

		self:updateBuffsList()
	end

	if self.rightPartner_ then
		local heroIcon = self:getIcon(self.rightPartner_, self.playerIcon2)

		self:updateBuffsList(true)
	end

	UIEventListener.Get(self.click1).onClick = function ()
		if self.hasLeft then
			xyd.WindowManager.get():openWindow("battle_buff_list_window", {
				fighter = self.leftPartner_,
				showIcons = self.leftIcons
			})
		end
	end

	UIEventListener.Get(self.click2).onClick = function ()
		if self.hasRight then
			xyd.WindowManager.get():openWindow("battle_buff_list_window", {
				fighter = self.rightPartner_,
				showIcons = self.rightIcons
			})
		end
	end

	self.colorBg:SetActive(self.index % 2 == 1)
end

return BattleAllBuffsWindow
