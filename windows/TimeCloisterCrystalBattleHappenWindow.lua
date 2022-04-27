local TimeCloisterCrystalBattleHappenWindow = class("TimeCloisterCrystalBattleHappenWindow", import(".BaseWindow"))
local TimeCloisterScienceCard = import("app.components.TimeCloisterScienceCard")

function TimeCloisterCrystalBattleHappenWindow:ctor(name, params)
	TimeCloisterCrystalBattleHappenWindow.super.ctor(self, name, params)

	self.callback = params.callback
	self.battleCardIds = params.battleCardIds
end

function TimeCloisterCrystalBattleHappenWindow:initWindow()
	self:getUIComponent()
	TimeCloisterCrystalBattleHappenWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function TimeCloisterCrystalBattleHappenWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleImg = self.groupAction:ComponentByName("titleImg", typeof(UISprite))
	self.cards = self.groupAction:NodeByName("cards").gameObject

	for i = 1, 3 do
		self["card" .. i] = self.groupAction:NodeByName("card" .. i).gameObject
	end

	self.effectCon = self.groupAction:ComponentByName("effectCon", typeof(UITexture))
end

function TimeCloisterCrystalBattleHappenWindow:registerEvent()
end

function TimeCloisterCrystalBattleHappenWindow:layout()
	xyd.setUISpriteAsync(self.titleImg, nil, "time_cloister_card_skill_title_" .. xyd.Global.lang, nil, , true)

	for i, index in pairs(self.battleCardIds) do
		self["cardItem" .. i] = TimeCloisterScienceCard.new(self["card" .. i], {})

		self["cardItem" .. i]:setInfo({
			index = index
		})
		self["cardItem" .. i]:setCallback(function ()
		end)
	end

	self.cardEffect = xyd.Spine.new(self.effectCon.gameObject)

	self.cardEffect:setInfo("time_cloister_crystal_card", function ()
		self.cardEffect:setRenderTarget(self.effectCon, 1)

		if #self.battleCardIds == 1 then
			self.cardEffect:followBone("slot" .. 2, self["card" .. 1])
			self.cardEffect:followSlot("slot" .. 2, self["card" .. 1])
		else
			for i in pairs(self.battleCardIds) do
				self.cardEffect:followBone("slot" .. i, self["card" .. i])
				self.cardEffect:followSlot("slot" .. i, self["card" .. i])
			end
		end

		self.cardEffect:followBone("slot4", self.titleImg.gameObject)
		self.cardEffect:followSlot("slot4", self.titleImg.gameObject)
		self.cardEffect:play("texiao0" .. 4 - #self.battleCardIds, 1, 1, function ()
			self:close()
		end)
	end)
end

function TimeCloisterCrystalBattleHappenWindow:willClose()
	self.callback()
	TimeCloisterCrystalBattleHappenWindow.super.willClose(self)
end

return TimeCloisterCrystalBattleHappenWindow
