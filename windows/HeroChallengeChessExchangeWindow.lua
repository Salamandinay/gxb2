local HeroChallengeChessExchangeWindow = class("HeroChallengeChessExchangeWindow", import(".BaseWindow"))
local ItemIcon = import("app.components.ItemIcon")
local HeroIcon = import("app.components.HeroIcon")
local FormationItem = class("FormationItem")

function FormationItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = nil

	if not self.parent_ then
		self.win_ = xyd.getWindow("hero_challenge_chess_exchange_window")
	else
		self.win_ = self.parent_
	end

	self.isFriend = false
end

function FormationItem:setIsFriend(isFriend)
	self.isFriend = isFriend
end

function FormationItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	if realIndex ~= nil then
		self.parent_:updateFormationItemInfo(info, realIndex)
	end

	if not self.heroIcon_ then
		self.heroIcon_ = import("app.components.HeroIcon").new(self.uiRoot_, self.parent_.partnerRenderPanel)
	end

	self.uiRoot_:SetActive(true)

	self.partner_ = info.partnerInfo
	self.callbackFunc = info.callbackFunc

	self:setIsChoose(info.isSelected)

	self.partnerId_ = self.partner_.partnerID
	self.partner_.noClickSelected = true
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.scrollView
	self.partner_.is_vowed = self.partner_.is_vowed
	self.partner_.noClick = false

	if self.win_ and self.win_.isDeath and self.win_.checkNeedGrey and self.win_:checkNeedGrey() then
		local flag = self.win_:isDeath(self.partnerId_)

		if flag then
			self.heroIcon_:setGrey()
		else
			self.heroIcon_:setOrigin()
		end

		self.isDeath_ = flag
	end

	self.heroIcon_:setInfo(self.partner_)
end

function FormationItem:onClick()
	local selectPos = self.callbackFunc(self.partner_, self.isSelected)

	self:setIsChoose(not self.isSelected)
end

function FormationItem:setIsChoose(status)
	self.isSelected = status

	self.heroIcon_:setChoose(status)
end

function FormationItem:getHeroIcon()
	return self.heroIcon_
end

function FormationItem:getPartnerId()
	return self.partnerId_
end

function FormationItem:setShowActive(canShow)
	self.uiRoot_.gameObject:SetActive(canShow)
end

function FormationItem:getGameObject()
	return self.uiRoot_
end

function HeroChallengeChessExchangeWindow:ctor(name, params)
	HeroChallengeChessExchangeWindow.super.ctor(self, name, params)

	self.nowPartnerList = {}
	self.groupEquipItems = {}
	self.selectNum_ = 0
	self.fortId_ = params.fort_id
	self.money_ = 0
	self.exmoney_ = xyd.split(xyd.tables.miscTable:getVal("partner_challenge_chess_sell"), "|", true)
end

function HeroChallengeChessExchangeWindow:initWindow()
	self:getComponent()
	self:initTopGroup()
	self:refreshItemBefore()
	self:initOriginalPartnerid()
	self:layout()
	self:register()
end

function HeroChallengeChessExchangeWindow:register()
	UIEventListener.Get(self.btnUp).onClick = handler(self, self.clickSell)

	UIEventListener.Get(self.backBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.eventProxy_:addEventListener(xyd.event.SELL_PARTNER, handler(self, self.onSellEnd))
end

function HeroChallengeChessExchangeWindow:willClose()
	HeroChallengeChessExchangeWindow.super.willClose(self)
	xyd.WindowManager.get():openWindow("hero_challenge_team_window", {
		show_red_point = false,
		fort_id = self.fortId_
	})
end

function HeroChallengeChessExchangeWindow:getComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("groupAction").gameObject
	local top = content:NodeByName("top").gameObject
	self.backBtn = top:NodeByName("backBtn").gameObject
	self.labelTitle = top:ComponentByName("labelTitle", typeof(UILabel))
	local mid1 = content:NodeByName("mid1").gameObject
	local itemBeforeContainer = mid1:NodeByName("getItemIcon").gameObject
	self.itemBefore = ItemIcon.new(itemBeforeContainer)

	self.itemBefore:setInfo({
		showNum = true,
		itemID = xyd.ItemID.HERO_CHALLENGE_CHESS,
		num = self.money_
	})

	self.labelDesc = mid1:ComponentByName("labelDesc", typeof(UILabel))
	self.scroller_ = mid1:ComponentByName("scroller_", typeof(UIScrollView))
	self.groupEquip = self.scroller_:NodeByName("groupEquip").gameObject
	self.groupEquipItem = self.scroller_:NodeByName("item").gameObject

	self.groupEquipItem:SetActive(false)

	self.groupEquipGrid = self.groupEquip:GetComponent(typeof(UIGrid))
	local mid2 = content:NodeByName("mid2").gameObject
	self.noPartner = mid2:NodeByName("noPartner").gameObject
	self.noPartnerLable = self.noPartner:ComponentByName("noEquipLable", typeof(UILabel))
	self.scrollView = mid2:ComponentByName("scroller", typeof(UIScrollView))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	local wrapContent = self.scrollView:ComponentByName("container", typeof(MultiRowWrapContent))
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView, wrapContent, itemContainer, FormationItem, self)
	self.btnUp = content:NodeByName("btnUp").gameObject
	self.btnUpLabel = self.btnUp:ComponentByName("button_label", typeof(UILabel))
end

function HeroChallengeChessExchangeWindow:refreshItemBefore()
	self.itemBefore:setNum(self.money_)

	self.oldCoin_ = xyd.models.heroChallenge:getCoin(self.fortId_)
end

function HeroChallengeChessExchangeWindow:initOriginalPartnerid()
	self.originalPartnerid = {}
	local info = xyd.models.heroChallenge:getFortInfoByFortID(self.fortId_)

	if info then
		local liveIDs = info.live_partner_ids

		for key, num in pairs(liveIDs) do
			for j = 1, num do
				table.insert(self.originalPartnerid, tonumber(key))
			end
		end
	end
end

function HeroChallengeChessExchangeWindow:layout()
	self.labelTitle.text = __("CHESS_EXCHANGE_PARTNER")
	self.btnUpLabel.text = __("CHESS_EXCHANGE")
	self.labelDesc.text = __("CHESS_EXCHANGE_TIPS")

	self:iniPartnerData(0)
end

function HeroChallengeChessExchangeWindow:iniPartnerData(groupID)
	local parnterDataList = self:initHeroChallengePartnerData(groupID)

	self.multiWrap_:setInfos(parnterDataList, {})
end

function HeroChallengeChessExchangeWindow:initHeroChallengePartnerData(groupID)
	local partnerList = xyd.models.heroChallenge:getHeros(self.fortId_)
	local partnerDataList = {}

	for _, partner in ipairs(partnerList) do
		local partnerInfo = {
			noClick = true,
			tableID = partner:getHeroTableID(),
			lev = partner:getLevel(),
			awake = partner.awake,
			group = partner:getGroup(),
			grade = partner:getGrade(),
			partnerID = partner:getPartnerID(),
			power = partner:getPower()
		}
		local data = {
			callbackFunc = handler(self, function (a, callbackPInfo, callbackIsChoose)
				self:onClickheroIcon(callbackPInfo, callbackIsChoose)
			end),
			partnerInfo = partnerInfo
		}

		table.insert(partnerDataList, data)
	end

	return partnerDataList
end

function HeroChallengeChessExchangeWindow:isSelected(cPartnerId, Plist, isDel)
	local posId = -1
	local isSelected = false

	for k, v in pairs(Plist) do
		if v == cPartnerId then
			posId = k
			isSelected = true

			if isDel ~= nil and isDel == true then
				Plist[k] = nil
			end

			break
		end
	end

	return {
		isSelected = isSelected,
		posId = posId
	}
end

function HeroChallengeChessExchangeWindow:initTopGroup()
	for i = 1, 5 do
		local item = NGUITools.AddChild(self.groupEquip, self.groupEquipItem)
		local equipIcon = item:NodeByName("heroIcon").gameObject
		local heroIcon = HeroIcon.new(equipIcon)

		heroIcon:SetActive(false)
		heroIcon:setDragScrollView(self.scroller_)

		self.groupEquipItems[i] = {
			itemObj = item,
			heroIcon = heroIcon
		}
	end

	self.groupEquipGrid:Reposition()
end

function HeroChallengeChessExchangeWindow:onClickheroIcon(partnerInfo, isChoose, pos, needAnimation, posId, isFriendPartner)
	if self.needSound then
		-- Nothing
	end

	local posId = nil

	if isChoose then
		local params = self:isSelected(partnerInfo.partnerID, self.nowPartnerList)
		local isChoose = params.isSelected
		posId = params.posId

		if posId >= 0 then
			local container = self.groupEquipItems[tonumber(posId)]
			local heroIcon = container.heroIcon

			if posId >= 6 and heroIcon then
				NGUITools.Destroy(container.itemObj)

				self.groupEquipItems[tonumber(posId)] = nil
			elseif heroIcon then
				heroIcon:SetActive(false)
			end

			self.nowPartnerList[tonumber(posId)] = nil
			self.selectNum_ = self.selectNum_ - 1

			self.groupEquipGrid:Reposition()

			if self.originalPartnerid[partnerInfo.partnerID] < 22001 then
				self.money_ = self.money_ - self.exmoney_[1]
			else
				self.money_ = self.money_ - self.exmoney_[2]
			end

			self:refreshItemBefore()
		end
	else
		posId = self.selectNum_ + 1

		local function copyCallback(copyIcon)
			self:iconTapHandler(copyIcon:getPartnerInfo(), false)
		end

		local copyPartnerInfo = {
			noClickSelected = true,
			tableID = partnerInfo.tableID,
			lev = partnerInfo.lev,
			star = partnerInfo.star,
			skin_id = partnerInfo.skin_id,
			is_vowed = partnerInfo.is_vowed,
			posId = posId,
			callback = copyCallback,
			awake = partnerInfo.awake,
			grade = partnerInfo.grade,
			group = partnerInfo.group or partnerInfo:getGroup(),
			partnerID = partnerInfo.partnerID,
			power = partnerInfo.power or partnerInfo:getPower(),
			partnerType = partnerInfo.partnerType
		}
		local container = self.groupEquipItems[tonumber(posId)]
		local copyIcon = nil

		if container then
			copyIcon = container.heroIcon

			copyIcon:SetActive(true)
		else
			local item = NGUITools.AddChild(self.groupEquip, self.groupEquipItem)
			local equipIcon = item:NodeByName("heroIcon").gameObject
			copyIcon = HeroIcon.new(equipIcon)

			copyIcon:setDragScrollView(self.scroller_)

			self.groupEquipItems[tonumber(posId)] = {
				itemObj = item,
				heroIcon = copyIcon
			}
		end

		copyIcon:setInfo(copyPartnerInfo, self.pet)
		self.groupEquipGrid:Reposition()

		self.selectNum_ = self.selectNum_ + 1
		self.nowPartnerList[posId] = partnerInfo.partnerID

		if self.originalPartnerid[partnerInfo.partnerID] < 22001 then
			self.money_ = self.money_ + self.exmoney_[1]
		else
			self.money_ = self.money_ + self.exmoney_[2]
		end

		self:refreshItemBefore()
	end
end

function HeroChallengeChessExchangeWindow:iconTapHandler(copyPartnerInfo)
	local partnerInfo = copyPartnerInfo
	local params = self:isSelected(partnerInfo.partnerID, self.nowPartnerList)
	local isChoose = params.isSelected
	local posId = params.posId

	if posId >= 0 then
		local container = self.groupEquipItems[tonumber(posId)]
		local heroIcon = container.heroIcon

		if posId >= 6 and heroIcon then
			NGUITools.Destroy(container.itemObj)

			self.groupEquipItems[tonumber(posId)] = nil
		elseif heroIcon then
			heroIcon:SetActive(false)
		end

		local fItem = self:getFormationItemByPartnerID(partnerInfo.partnerID)

		if fItem then
			fItem:setIsChoose(false)
		end

		if self.originalPartnerid[partnerInfo.partnerID] < 22001 then
			self.money_ = self.money_ - self.exmoney_[1]
		else
			self.money_ = self.money_ - self.exmoney_[2]
		end

		self:refreshItemBefore()

		self.nowPartnerList[tonumber(posId)] = nil
		self.selectNum_ = self.selectNum_ - 1

		self.groupEquipGrid:Reposition()
	end
end

function HeroChallengeChessExchangeWindow:getFormationItemByPartnerID(partnerID)
	local items = self.multiWrap_:getItems()

	for _, formationItem in ipairs(items) do
		if formationItem:getPartnerId() == partnerID then
			return formationItem
		end
	end
end

function HeroChallengeChessExchangeWindow:clickSell()
	local num = 0

	for _, partnerId in pairs(self.nowPartnerList) do
		num = num + 1
	end

	if num >= #self.originalPartnerid then
		xyd.alert(xyd.AlertType.YES_NO, __("PARTNER_CHALLENGE_CHESS_TEXT10"), function (yes)
			if yes then
				self:partnerSell()
			end
		end)
	else
		self:partnerSell()
	end
end

function HeroChallengeChessExchangeWindow:partnerSell()
	local num = 0
	local ids = {}

	for _, partnerId in pairs(self.nowPartnerList) do
		table.insert(ids, self.originalPartnerid[partnerId])

		num = num + 1
	end

	if #ids > 0 then
		xyd.models.heroChallenge:reqSellPartner(self.fortId_, ids)
	end
end

function HeroChallengeChessExchangeWindow:onSellEnd(event)
	local nowCoin = event.data.fort_info.base_info.coin
	local getNum = nowCoin - self.oldCoin_
	local params = {
		{
			item_id = xyd.ItemID.HERO_CHALLENGE_CHESS,
			item_num = getNum
		}
	}

	xyd.alertItems(params)

	for idx, container in pairs(self.groupEquipItems) do
		local heroIcon = container.heroIcon

		if idx >= 6 and heroIcon then
			NGUITools.Destroy(container.itemObj)

			self.groupEquipItems[tonumber(idx)] = nil
		elseif heroIcon then
			heroIcon:SetActive(false)
		end
	end

	self.money_ = 0
	self.selectNum_ = 0
	self.nowPartnerList = {}

	self:iniPartnerData(0)
	self:refreshItemBefore()
	self:initOriginalPartnerid()
	self:waitForFrame(2, function ()
		self.groupEquipGrid:Reposition()
		self.scroller_:ResetPosition()
	end)
end

function HeroChallengeChessExchangeWindow:updateFormationItemInfo(info, realIndex)
	local partnerInfo = info.partnerInfo
	local partnerId = partnerInfo.partnerID
	local isSelected = info.isSelected
	local isS = self:isSelected(partnerId, self.nowPartnerList, false)

	if isSelected ~= isS.isSelected then
		info.isSelected = isS.isSelected

		self.multiWrap_:updateInfo(realIndex, info)
	end
end

return HeroChallengeChessExchangeWindow
