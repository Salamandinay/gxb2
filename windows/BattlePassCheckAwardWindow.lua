local BaseWindow = import(".BaseWindow")
local BattlePassCheckAwardWindow = class("BattlePassCheckAwardWindow", BaseWindow)

function BattlePassCheckAwardWindow:ctor(name, params)
	self.isBtnGrey = params.isBtnGrey or false
	self.showType = params.showType

	BattlePassCheckAwardWindow.super.ctor(self, name, params)
end

function BattlePassCheckAwardWindow:initWindow()
	BattlePassCheckAwardWindow.super.initWindow(self)

	local conTrans = self.window_:NodeByName("groupAction")
	self.closeBtn = conTrans:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.titleLabel_ = conTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.effectGroupTop_ = conTrans:NodeByName("topNode/effectGroup").gameObject
	self.effectGroupDown_ = conTrans:NodeByName("bottomNode/effectGroup").gameObject
	self.scrollViewTop_ = conTrans:ComponentByName("topNode/scrollView", typeof(UIScrollView))
	self.gridTop_ = conTrans:ComponentByName("topNode/scrollView/grid", typeof(UIGrid))
	self.scrollViewDown_ = conTrans:ComponentByName("bottomNode/scrollView", typeof(UIScrollView))
	self.gridDown_ = conTrans:ComponentByName("bottomNode/scrollView/grid", typeof(UIGrid))
	self.btnLvUpBtn_ = conTrans:ComponentByName("btnLvUp", typeof(UISprite))
	self.labelLvUp_ = conTrans:ComponentByName("btnLvUp/label", typeof(UILabel))
	self.btnMask_ = conTrans:NodeByName("btnLvUp/mask").gameObject

	self:layout()
	self:register()
	self:initEffect()
end

function BattlePassCheckAwardWindow:initEffect()
	local effect1 = "fx_ui_battlepass_silver"
	local effect2 = "fx_ui_battlepass_brass"
	effect2 = "fx_bp_common"
	effect1 = "fx_bp_silver"
	self.effect1 = xyd.Spine.new(self.effectGroupDown_.gameObject)

	self.effect1:setInfo(effect1, function ()
		self.effect1:SetLocalScale(-0.55, 0.55, 0.55)
		self.effect1:SetLocalPosition(-20, -160, 0.55)

		if self.effect1 == nil then
			return
		end

		self.effect1:setRenderTarget(self.effectGroupDown_:GetComponent(typeof(UITexture)), 5)
		self.effect1:play("texiao01", 0)
	end)

	self.effect2 = xyd.Spine.new(self.effectGroupTop_.gameObject)

	self.effect2:setInfo(effect2, function ()
		self.effect2:SetLocalScale(0.55, 0.55, 0.55)
		self.effect2:SetLocalPosition(10, -200, 0.55)

		if self.effect2 == nil then
			return
		end

		self.effect2:setRenderTarget(self.effectGroupTop_:GetComponent(typeof(UITexture)), 2)
		self.effect2:play("texiao01", 0)
	end)
end

function BattlePassCheckAwardWindow:register()
	BattlePassCheckAwardWindow.super.register(self)

	UIEventListener.Get(self.btnLvUpBtn_.gameObject).onClick = function ()
		if self.isBtnGrey then
			return
		end

		xyd.WindowManager.get():openWindow("battle_pass_buy_window_new", {
			showType = self.showType
		})
	end
end

function BattlePassCheckAwardWindow:layout()
	self.labelLvUp_.text = __("BP_UPGRADE_BUTTON")
	self.titleLabel_.text = __("BP_BUY_LEV_PREAWARD")

	if self.isBtnGrey then
		xyd.applyGrey(self.btnLvUpBtn_)

		self.labelLvUp_.effectStyle = UILabel.Effect.None
	else
		xyd.applyOrigin(self.btnLvUpBtn_)
	end

	local battlePassTable = xyd.models.activity:getBattlePassTable(xyd.BATTLE_PASS_TABLE.MAIN)

	self.btnMask_:SetActive(self.isBtnGrey)

	local topList = {}
	local downList = {}
	local awards1 = battlePassTable:getPreAward(1)
	local awards2 = battlePassTable:getPreAward(2)

	for _, info in ipairs(awards1) do
		local params = {
			noClickSelected = true,
			scale = 0.7037037037037037,
			itemID = info[1],
			num = info[2],
			uiRoot = self.gridTop_.gameObject,
			dragScrollView = self.scrollViewTop_,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		table.insert(topList, params)
	end

	for _, info in ipairs(awards2) do
		local params = {
			noClickSelected = true,
			scale = 0.7037037037037037,
			itemID = info[1],
			num = info[2],
			uiRoot = self.gridDown_.gameObject,
			dragScrollView = self.scrollViewDown_,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		table.insert(downList, params)
	end

	self.topItemList_ = {}

	for _, itemData in ipairs(topList) do
		local item = xyd.getItemIcon(itemData)

		table.insert(self.topItemList_, item)
	end

	self.gridTop_:Reposition()
	self.scrollViewTop_:ResetPosition()

	self.downItemList_ = {}

	for _, itemData in ipairs(downList) do
		local item = xyd.getItemIcon(itemData)

		table.insert(self.downItemList_, item)
	end

	self.gridDown_:Reposition()
	self.scrollViewDown_:ResetPosition()
end

return BattlePassCheckAwardWindow
