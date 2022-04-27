local HeroChallengeChessGetPartnerWindow = class("HeroChallengeChessGetPartnerWindow", import(".BaseWindow"))
local HeroChallengeChessAwardItem1 = class("HeroChallengeChessAwardItem1", import("app.components.BaseComponent"))
local PartnerCard = import("app.components.PartnerCard")
local Monster = import("app.models.Monster")

function HeroChallengeChessGetPartnerWindow:ctor(name, params)
	HeroChallengeChessGetPartnerWindow.super.ctor(self, name, params)

	self.fortId = params.fort_id
end

function HeroChallengeChessGetPartnerWindow:initWindow()
	self:getUIComponent()
	self:setLayout()
	self:register()
	self:initItems()
end

function HeroChallengeChessGetPartnerWindow:getUIComponent()
	self.resGroup = self.window_:NodeByName("resGroup").gameObject
	local winTrans = self.window_:NodeByName("groupAction")

	for i = 1, 3 do
		self["effectGroup" .. i] = winTrans:NodeByName("groupEffect" .. i).gameObject
	end

	self.winTitle_ = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.btnRefresh_ = winTrans:NodeByName("btnRefresh").gameObject
	self.btnRefreshCostLabel_ = winTrans:ComponentByName("btnRefresh/costNum", typeof(UILabel))
	self.btnRefreshLabel_ = winTrans:ComponentByName("btnRefresh/labelRefresh", typeof(UILabel))
	self.groupMain_ = winTrans:NodeByName("groupMain").gameObject
	self.labelFreeCoin_ = winTrans:ComponentByName("labelFreeCoin", typeof(UILabel))
	self.labelFreeCoinTime_ = winTrans:ComponentByName("labelFreeCoinTime", typeof(UILabel))
	self.threeItem_ = winTrans:NodeByName("threeItem").gameObject
	self.partnerImg_ = winTrans:ComponentByName("threeItem/node1/partnerImg", typeof(UISprite))
	self.groupImg_ = winTrans:ComponentByName("threeItem/node2/groupImg", typeof(UISprite))
	self.labelLevel_ = winTrans:ComponentByName("threeItem/node3/labelLevel", typeof(UILabel))
	self.labelName_ = winTrans:ComponentByName("threeItem/node4/labelName", typeof(UILabel))

	for i = 1, 4 do
		self["node" .. i] = winTrans:NodeByName("threeItem/node" .. i)
	end

	self.blockImg_ = winTrans:NodeByName("blockImg").gameObject
end

function HeroChallengeChessGetPartnerWindow:setLayout()
	self.btnRefreshLabel_.text = __("REFRESH")
	self.winTitle_.text = __("CHESS_TEXT01")
	self.item1_ = require("app.components.ResItem").new(self.resGroup)
	self.booklabelResItem = require("app.components.ResItem").new(self.resGroup)

	self.resGroup:GetComponent(typeof(UILayout)):Reposition()
	self.item1_:setInfo({
		show_tips = true,
		tableId = xyd.ItemID.HERO_CHALLENGE
	})

	local function callbackFunc()
		local params = {
			show_has_num = true,
			itemID = xyd.ItemID.HERO_CHALLENGE_CHESS,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	self.booklabelResItem:setInfo({
		show_tips = true,
		tableId = xyd.ItemID.HERO_CHALLENGE_CHESS,
		callback = callbackFunc
	})
	self.booklabelResItem:hidePlus()

	local bookNum = xyd.models.heroChallenge:initBookLabel(self.fortId)

	if xyd.models.heroChallenge.chessCoin_ then
		bookNum = xyd.models.heroChallenge:getCoin(self.fortId)
	end

	self.booklabelResItem:setItemNum(bookNum)
end

function HeroChallengeChessGetPartnerWindow:updateBookLabel()
	local bookNum = xyd.models.heroChallenge:getCoin(self.fortId)

	self.booklabelResItem:setItemNum(bookNum)
end

function HeroChallengeChessGetPartnerWindow:register()
	HeroChallengeChessGetPartnerWindow.super.register(self)

	UIEventListener.Get(self.btnRefresh_).onClick = handler(self, self.onBtnRefreshTouch)

	self.eventProxy_:addEventListener(xyd.event.BUY_PARTNER, handler(self, self.refreshWindow))
	self.eventProxy_:addEventListener(xyd.event.REFRESH_CHESS_SHOP, handler(self, self.refreshWindow))
end

function HeroChallengeChessGetPartnerWindow:initItems()
	self.curSelect_ = 1
	local rewards = xyd.models.heroChallenge:getBuyChessReward(self.fortId)

	if not rewards or not next(rewards) then
		xyd.models.heroChallenge:reqRefreshChessShop(self.fortId)
	else
		self:refreshParnters(rewards[1].partner_ids)
	end

	self:refreshFreeState()
end

function HeroChallengeChessGetPartnerWindow:refreshFreeState()
	local time = xyd.models.heroChallenge:getFreeTime(self.fortId)

	if not time or time == 0 then
		self.labelFreeCoin_.gameObject:SetActive(false)
		self.btnRefreshCostLabel_.gameObject:SetActive(true)
	else
		self.labelFreeCoin_.gameObject:SetActive(true)
		self.btnRefreshCostLabel_.gameObject:SetActive(false)

		self.labelFreeCoin_.text = __("CHESS_FREE_TIMES") .. time
	end
end

function HeroChallengeChessGetPartnerWindow:refreshWindow()
	local rewards = xyd.models.heroChallenge:getBuyChessReward(self.fortId)

	self.groupMain_:SetActive(true)

	if rewards and next(rewards) then
		self:refreshParnters(rewards[1].partner_ids)
	else
		self:refreshParnters({})
	end

	self:refreshFreeState()
	self:updateBookLabel()
end

function HeroChallengeChessGetPartnerWindow:refreshParnters(ids)
	if not self.heroChallengeChessAwardItem_ then
		self.heroChallengeChessAwardItem_ = HeroChallengeChessAwardItem1.new(self.groupMain_)
	end

	self.heroChallengeChessAwardItem_:setInfo(self.fortId, ids)
end

function HeroChallengeChessGetPartnerWindow:onBtnRefreshTouch()
	local coin = xyd.models.heroChallenge:getCoin(self.fortId)
	local time = xyd.models.heroChallenge:getFreeTime(self.fortId)

	if coin and coin == 0 and (not time or tonumber(time) == 0) then
		xyd.alertTips(__("CHESS_COIN_NOT_ENOUGH"))

		return
	end

	self.groupMain_:SetActive(false)
	xyd.models.heroChallenge:reqRefreshChessShop(self.fortId)
end

function HeroChallengeChessGetPartnerWindow:onConfirmTouch(heronum, index)
	local select = index or self.curSelect_
	local heroChallenge = xyd.models.heroChallenge
	local f1 = heroChallenge:getCoin(self.fortId) < 3
	local f2 = heroChallenge:getFirst(self.fortId) == 1
	local num1 = heroChallenge:getBuyChessReward(self.fortId)
	local pp = num1[1].partner_ids[index]
	local sid = xyd.tables.monsterTable:getPartnerLink(pp)
	local sname = xyd.tables.partnerTextTable:getName(sid)

	if not f2 and f1 then
		xyd.alertTips(__("CHESS_COIN_NOT_ENOUGH"))

		return
	end

	if heronum == 2 then
		self.threeItem_:SetActive(true)
		self.groupImg_:SetActive(false)

		local heroSource = xyd.tables.partnerPictureTable:getPartnerCard(sid)
		self.labelName_.text = sname
		self.labelLevel_.text = "290"
		local group = xyd.tables.partnerTable:getGroup(sid)

		xyd.setUISpriteAsync(self.partnerImg_, nil, heroSource)
		xyd.setUISpriteAsync(self.groupImg_, nil, "img_group" .. group)
		self.blockImg_:SetActive(true)

		if not self.partnerTreeEffect_ then
			self.partnerTreeEffect_ = xyd.Spine.new(self["effectGroup" .. index])
		else
			self.partnerTreeEffect_:destroy()

			self.partnerTreeEffect_ = xyd.Spine.new(self["effectGroup" .. index])
		end

		self.partnerTreeEffect_:setInfo("partner_challenge_chess_lvlup", function ()
			self.partnerTreeEffect_:followSlot("tihuan4", self.node4)
			self.partnerTreeEffect_:followSlot("tihuan5", self.node3)
			self.partnerTreeEffect_:followSlot("tihuan1", self.node2)
			self.partnerTreeEffect_:followSlot("tihuan2", self.node1)
			self.partnerTreeEffect_:followBone("tihuan4", self.node4)
			self.partnerTreeEffect_:followBone("tihuan5", self.node3)
			self.partnerTreeEffect_:followBone("tihuan1", self.node2)
			self.partnerTreeEffect_:followBone("000", self.node1)
			self.partnerTreeEffect_:playWithEvent("texiao01", 1, 1, {
				Complete = function ()
					self.threeItem_:SetActive(false)
					self.partnerTreeEffect_:SetActive(false)
					xyd.models.heroChallenge:reqBuyPartner(self.fortId, select)
					self.blockImg_:SetActive(false)
				end,
				show = function ()
					self.groupImg_:SetActive(true)
				end
			})
		end)
	else
		xyd.models.heroChallenge:reqBuyPartner(self.fortId, select)
	end
end

function HeroChallengeChessGetPartnerWindow:willClose()
	xyd.WindowManager.get():openWindow("hero_challenge_team_window", {
		show_red_point = false,
		fort_id = self.fortId
	})
end

function HeroChallengeChessAwardItem1:ctor(parentGo)
	HeroChallengeChessAwardItem1.super.ctor(self, parentGo)
end

function HeroChallengeChessAwardItem1:getPrefabPath()
	return "Prefabs/Components/hero_challenge_chess_award1"
end

function HeroChallengeChessAwardItem1:initUI()
	HeroChallengeChessAwardItem1.super.initUI(self)

	self.nums_ = {}
	self.cardItemList_ = {}
	self.effectList_ = {}

	self:getComponent()
	self:registerEvent()
end

function HeroChallengeChessAwardItem1:getComponent()
	for i = 1, 3 do
		self["partnerGroup" .. i] = self.go:NodeByName("partnerGroup" .. i).gameObject
		local rootTrans = self["partnerGroup" .. i].transform
		self["btnGetPartner" .. i] = rootTrans:NodeByName("btnGetPartner").gameObject
		self["btnGetPartnerCostLabel" .. i] = rootTrans:ComponentByName("btnGetPartner/costNum", typeof(UILabel))
		self["btnGetPartnerLabel" .. i] = rootTrans:ComponentByName("btnGetPartner/labelRefresh", typeof(UILabel))
		self["partnerRoot" .. i] = rootTrans:NodeByName("partnerRoot").gameObject
		self["effectGroup" .. i] = rootTrans:NodeByName("effectGroup").gameObject
		self["labelHasDesc" .. i] = rootTrans:ComponentByName("labelHasDesc", typeof(UILabel))
		self["labelHasNum" .. i] = rootTrans:ComponentByName("labelHasNum", typeof(UILabel))
	end
end

function HeroChallengeChessAwardItem1:registerEvent()
	local ids = self.ids_

	for i = 1, 3 do
		UIEventListener.Get(self["btnGetPartner" .. i]).onClick = function ()
			self:onItemTouch(i)
		end

		UIEventListener.Get(self["partnerGroup" .. i]).onClick = function ()
			self:onCardTouch(i)
		end
	end
end

function HeroChallengeChessAwardItem1:setInfo(fortId, ids)
	self.fortId_ = fortId
	self.ids_ = ids
	self.nums_ = {}

	for i = 1, #self.ids_ do
		local descLabel = self["labelHasDesc" .. i]
		local numLabel = self["labelHasNum" .. i]

		descLabel.gameObject:SetActive(true)

		local desc = __("CHESS_ALREADY_HAVE")
		descLabel.text = __("CHESS_ALREADY_HAVE")
		local num = xyd.models.heroChallenge:getHeroNum(self.fortId_, tonumber(self.ids_[i]))

		if num and num > 0 then
			self.nums_[i] = num
		else
			self.nums_[i] = 0
		end

		descLabel.text = desc .. self.nums_[i]
	end

	self:updatePartners()
	self:updateBtnState()
end

function HeroChallengeChessAwardItem1:getInfoByID(id)
	local itemID = xyd.tables.monsterTable:getPartnerLink(id)
	local params = {
		tableID = itemID,
		tabel_id = itemID,
		star = xyd.tables.partnerTable:getStar(itemID),
		lev = xyd.tables.monsterTable:getLv(id),
		grade = xyd.tables.monsterTable:getGrade(id),
		group = xyd.tables.partnerTable:getGroup(itemID)
	}

	return params
end

function HeroChallengeChessAwardItem1:updatePartners()
	for i = 1, #self.ids_ do
		self["partnerGroup" .. i]:SetActive(true)

		local id = tonumber(self.ids_[i])
		local params = self:getInfoByID(id)

		if not self.cardItemList_[i] then
			self.cardItemList_[i] = PartnerCard.new(self["partnerRoot" .. i])
		end

		if self.nums_[i] and self.nums_[i] == 2 then
			if not self.effectList_[i] then
				self.effectList_[i] = xyd.Spine.new(self["effectGroup" .. i])

				self.effectList_[i]:setInfo("partner_challenge_chess_tips", function ()
					self.effectList_[i]:play("texiao01", 0)
				end)
			else
				self.effectList_[i]:SetActive(true)
				self.effectList_[i]:play("texiao01", 0)
			end
		elseif self.effectList_[i] then
			self.effectList_[i]:SetActive(false)
		end

		self.cardItemList_[i]:setInfo(params)
	end

	for i = 1, 3 do
		if not self.ids_[i] then
			self["partnerGroup" .. i]:SetActive(false)
		end
	end
end

function HeroChallengeChessAwardItem1:updateBtnState()
	local ff = xyd.models.heroChallenge:getFirst(self.fortId_)

	for i = 1, #self.ids_ do
		self["btnGetPartner" .. i]:SetActive(true)

		self["btnGetPartnerLabel" .. i].text = __("GET")

		if ff and ff == 1 then
			self["btnGetPartnerCostLabel" .. i].text = "0"
		else
			self["btnGetPartnerCostLabel" .. i].text = "3"
		end
	end
end

function HeroChallengeChessAwardItem1:onCardTouch(index)
	local id = tonumber(self.ids_[index])
	local pInfo = Monster.new()

	pInfo:populateWithTableID(id)
	xyd.WindowManager.get():openWindow("partner_info", {
		notShowWays = true,
		partner = pInfo
	})
end

function HeroChallengeChessAwardItem1:onItemTouch(index)
	local win = xyd.WindowManager.get():getWindow("hero_challenge_chess_get_partner_window")

	if win then
		win:onConfirmTouch(self.nums_[index], index)
	end
end

return HeroChallengeChessGetPartnerWindow
