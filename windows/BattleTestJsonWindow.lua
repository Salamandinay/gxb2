local BaseWindow = import(".BaseWindow")
local BattleTestJsonWindow = class("BattleTestJsonWindow", BaseWindow)
local ReportHero = import("lib.battle.ReportHero")
local ReportPet = import("lib.battle.ReportPet")
local BattleCreateReport = import("lib.battle.BattleCreateReport")
local battleReportDes = import("lib.battle.BattleReportDes")
local cjson = require("cjson")
local BattleTest = import("app.common.BattleTest")
local BattleTestJsonWindowItem = class("BattleTestJsonWindowItem", import("app.components.CopyComponent"))

function BattleTestJsonWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.jsonLists = {}
end

function BattleTestJsonWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initItems()
	self:register()
end

function BattleTestJsonWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	local jsonIdGroup = content:NodeByName("jsonIdGroup").gameObject
	self.scroller = content:NodeByName("scroller").gameObject
	self.jsonIdInput = jsonIdGroup:ComponentByName("input", typeof(UIInput))
	self.groupItem = self.scroller:ComponentByName("groupItem", typeof(UIGrid))
	self.scrollView_ = content:ComponentByName("scroller", typeof(UIScrollView))
	self.itemCell = content:NodeByName("itemCell").gameObject
	self.fightBtn = content:NodeByName("fightBtn").gameObject
	self.allBtn = content:NodeByName("allBtn").gameObject

	os.execute("python Tools/createBattleJsonList.py")

	local jsonList = io.readfile("battleJsonList.json")
	self.jsonLists = cjson.decode(jsonList)
end

function BattleTestJsonWindow:layout()
	self.jsonIdInput.value = ""
	self.jsonIdInput.defaultText = "name"
end

function BattleTestJsonWindow:initItems()
	self.items = {}

	for _, name in ipairs(self.jsonLists) do
		local params = {
			name = name,
			callback = function ()
				self:setSelectName(name)
			end
		}

		if not self.items[name] then
			local goRoot = NGUITools.AddChild(self.groupItem.gameObject, self.itemCell)
			self.items[name] = BattleTestJsonWindowItem.new(goRoot, self)
		end

		self.items[name]:setInfo(params)
	end

	self.groupItem:Reposition()
	self.scrollView_:ResetPosition()
	self.itemCell:SetActive(false)
end

function BattleTestJsonWindow:setSelectName(name)
	if self.selectName == name then
		self:copyAndStartJsonFight()
	end

	self.selectName = name

	XYDCo.WaitForFrame(20, function ()
		self.selectName = ""
	end, nil)

	local arr = string.split(name, ".")
	self.jsonIdInput.value = arr[1]
end

function BattleTestJsonWindow:copyAndStartJsonFight()
	local jsonName = self.jsonIdInput.value
	jsonName = jsonName .. ".json"
	local isWrongName = true

	for k, v in ipairs(self.jsonLists) do
		if v == jsonName and self.jsonIdInput.value ~= "" then
			isWrongName = false

			break
		end
	end

	if jsonName == "" then
		isWrongName = true
	end

	if isWrongName then
		xyd.alert(xyd.AlertType.TIPS, "input wrong json name or id")
	else
		os.execute("python Tools/copyFightJsonToReport.py " .. jsonName)

		local win = xyd.WindowManager.get():getWindow("battle_test_window")

		if win then
			win:createJsonBattle()
			self:close()
		else
			xyd.alert(xyd.AlertType.TIPS, "open battle_test_window and use jsonFight")
		end
	end
end

function BattleTestJsonWindow:runAll()
	if not next(self.jsonLists) then
		self:close()

		return
	end

	local jsonName = self.jsonLists[#self.jsonLists]

	os.execute("python Tools/copyFightJsonToReport.py " .. jsonName)

	local win = xyd.WindowManager.get():getWindow("battle_test_window")

	if win then
		win:createJsonBattle(nil, true)
		table.remove(self.jsonLists, #self.jsonLists)
		reportLog(jsonName)
		self:runAll()
	else
		xyd.alert(xyd.AlertType.TIPS, "open battle_test_window and use jsonFight")

		return
	end
end

function BattleTestJsonWindow:register()
	BattleTestJsonWindow.super.register(self)

	UIEventListener.Get(self.fightBtn).onClick = function ()
		self:copyAndStartJsonFight()
	end

	UIEventListener.Get(self.allBtn).onClick = function ()
		self:runAll()
	end
end

function BattleTestJsonWindowItem:ctor(parentGo, parent)
	self.parent_ = parent

	BattleTestJsonWindowItem.super.ctor(self, parentGo)
end

function BattleTestJsonWindowItem:initUI()
	BattleTestJsonWindowItem.super.initUI(self)

	local goTrans = self.go.transform
	self.nameText = goTrans:ComponentByName("nameText", typeof(UILabel))
	self.touchField = goTrans:NodeByName("touchField").gameObject

	UIEventListener.Get(self.touchField).onClick = function ()
		self.callback()
	end
end

function BattleTestJsonWindowItem:setInfo(info)
	local arr = string.split(info.name, ".")
	self.nameText.text = arr[1]
	self.callback = info.callback
end

return BattleTestJsonWindow
