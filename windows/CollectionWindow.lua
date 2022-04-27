local BaseWindow = import(".BaseWindow")
local CollectionWindow = class("CollectionWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")

function CollectionWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.alreadyLoad = false
	self.NODES_LIST = {
		"skin",
		"frame",
		"soul",
		"story",
		"furniture",
		"face",
		"bg"
	}
	self.funIdMap = {
		[xyd.CollectionType.BG] = xyd.FunctionID.BACKGROUND
	}
	self.skinName = "CollectionWindowSkin"
	self.currentState = xyd.Global.lang
end

function CollectionWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:layout()
	self:registerEvent()
	self:initResItem()
	xyd.models.collection:reqCollectionInfo()
	self:playEnterAnim()
end

function CollectionWindow:getUIComponent()
	local trans = self.window_.transform
	self.downGroup = trans:NodeByName("e:GroupDown").gameObject

	for i, keyName in pairs(self.NODES_LIST) do
		self[tostring(keyName) .. "Node"] = self.downGroup:NodeByName(tostring(keyName) .. "Node").gameObject
		self[tostring(keyName) .. "NodeLabel"] = self[tostring(keyName) .. "Node"]:ComponentByName("titleWords", typeof(UILabel))
		self[tostring(keyName) .. "NodeBar"] = self[tostring(keyName) .. "Node"]:ComponentByName("progressBar_", typeof(UIProgressBar))
		self[tostring(keyName) .. "Nodepersent"] = self[tostring(keyName) .. "Node"]:ComponentByName("persentText", typeof(UILabel))
	end

	self.shopBtn = self.downGroup:NodeByName("shopBtn").gameObject
	self.shopBtn_redPoint = self.shopBtn:NodeByName("redPoint").gameObject
	self.btnHelp = trans:NodeByName("btnHelp").gameObject
	self.logo = trans:ComponentByName("logo", typeof(UISprite))
	self.heroBg = trans:ComponentByName("heroBg", typeof(UISprite))
	self.resItem = self.downGroup:NodeByName("resItem").gameObject
	self.LabelResNum = self.downGroup:ComponentByName("resItem/LabelResNum", typeof(UILabel))
	self.collectionPointNode = self.downGroup:NodeByName("collectionPointNode").gameObject
	self.clickNode = self.downGroup:NodeByName("collectionPointNode/clickNode").gameObject
	local multiLanImgWidth = {
		ko_kr = 120,
		ja_jp = 170,
		en_en = 135,
		fr_fr = 175,
		de_de = 180,
		zh_tw = 120
	}

	for i = 1, 7 do
		self["pointDes" .. tostring(i)] = self.downGroup:ComponentByName("collectionPointNode/e:Group/e:Group_" .. tostring(i) .. "/pointDes" .. tostring(i), typeof(UILabel))
		self["point" .. tostring(i)] = self.downGroup:ComponentByName("collectionPointNode/e:Group/e:Group_" .. tostring(i) .. "/point" .. tostring(i), typeof(UILabel))
		self.collectionPointNode:ComponentByName("e:Group/e:Group_" .. tostring(i) .. "/img" .. tostring(i), typeof(UISprite)).width = multiLanImgWidth[xyd.Global.lang]
	end

	self.effectNode = trans:NodeByName("effectNode").gameObject
	self.shopAnition = self.shopBtn:GetComponent(typeof(UnityEngine.Animation))
	self.btnHelpAnition = self.btnHelp:GetComponent(typeof(UnityEngine.Animation))
	self.logoAnition = self.logo:GetComponent(typeof(UnityEngine.Animation))
	self.resItemAnition = self.resItem:GetComponent(typeof(UnityEngine.Animation))
end

function CollectionWindow:playEnterAnim()
	self.shopAnition:Play()
	self.btnHelpAnition:Play()
	self.logoAnition:Play()
	self.resItemAnition:Play()
end

function CollectionWindow:initResItem()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function CollectionWindow:getWindowTop()
	return self.windowTop
end

function CollectionWindow:layout()
	xyd.setUISpriteAsync(self.logo, nil, "collection_logo_" .. xyd.Global.lang)

	self.fanyeEffect_ = xyd.Spine.new(self.effectNode)

	self.fanyeEffect_:setInfo("collection_fanye", function ()
		self.fanyeEffect_:SetLocalScale(1, 1, 1)
		self.fanyeEffect_:setRenderTarget(self.effectNode:GetComponent(typeof(UITexture)), 1)
		self.fanyeEffect_:play("open", 1, 1, function ()
		end, false)
	end)

	for i, keyName in pairs(self.NODES_LIST) do
		self[tostring(keyName) .. "NodeLabel"].text = xyd.split(__("SEVEN_COLLECTION_TITLES"), "|")[i]
	end

	for i = 1, #self.NODES_LIST do
		local bar = self[tostring(self.NODES_LIST[i]) .. "NodeBar"]
		local barText = self[tostring(self.NODES_LIST[i]) .. "Nodepersent"]
		bar.value = 0
		barText.text = ""
	end

	self:checkFunctionsOpen()
	self:updateResNum()
end

function CollectionWindow:checkFunctionsOpen()
	for i = 1, #self.NODES_LIST do
		self:checkAndGreyFuncNode(i + 1, self.funIdMap[i + 1])
	end
end

function CollectionWindow:updateResNum()
	self.LabelResNum.text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.COLLECT_COIN))
end

function CollectionWindow:updateBars()
	for i = 1, #self.NODES_LIST do
		local bar = self[tostring(self.NODES_LIST[i]) .. "NodeBar"]
		local barText = self[tostring(self.NODES_LIST[i]) .. "Nodepersent"]
		bar.value = xyd.models.collection:getPercentByType(i) / 100
		barText.text = math.floor(xyd.models.collection:getPercentByType(i)) .. "%"
	end
end

function CollectionWindow:updatePointList()
	for i = 1, #self.NODES_LIST do
		self["pointDes" .. tostring(i)].text = xyd.split(__("SEVEN_COLLECTION_TITLES"), "|")[i]
		local ids = xyd.models.collection:getIdsByType(i)
		local pointNum = 0

		if ids then
			for key, id in pairs(ids) do
				pointNum = pointNum + xyd.tables.collectionTable:getCoin(id)
			end
		end

		self["point" .. tostring(i)].text = pointNum
	end
end

function CollectionWindow:registerEvent()
	UIEventListener.Get(self.shopBtn).onClick = function ()
		xyd.models.shop:refreshShopInfo(xyd.ShopType.SHOP_COLLECTION1)
		xyd.models.shop:refreshShopInfo(xyd.ShopType.SHOP_COLLECTION2)
		xyd.models.backpack:checkCollectionShopRed(true)
	end

	UIEventListener.Get(self.resItem).onClick = handler(self, function ()
		self.collectionPointNode:SetActive(true)
	end)
	UIEventListener.Get(self.clickNode).onClick = handler(self, function ()
		self.collectionPointNode:SetActive(false)
	end)

	self.eventProxy_:addEventListener(xyd.event.GET_SHOP_INFO, function (_, event)
		if event.data.shop_type == xyd.ShopType.SHOP_COLLECTION1 then
			xyd.WindowManager.get():openWindow("collection_shop_window", {})
		end
	end, self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self:updateResNum()
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_COLLECTION_INFO, function ()
		self.alreadyLoad = true

		self:updateBars()
		self:updatePointList()
	end)

	UIEventListener.Get(self.btnHelp.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "COLLECTION_HELP"
		})
	end)

	for i = 1, #self.NODES_LIST do
		UIEventListener.Get(self[self.NODES_LIST[i] .. "Node"].gameObject).onClick = handler(self, function ()
			if not self.alreadyLoad then
				return
			end

			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

			if i == xyd.CollectionType.FRAME then
				xyd.WindowManager.get():openWindow("collection_frame_window")
			elseif i == xyd.CollectionType.BG then
				self:checkAndOpen("background_window", {
					isCollection = true
				}, xyd.FunctionID.BACKGROUND)
			elseif i == xyd.CollectionType.SKIN then
				xyd.WindowManager.get():openWindow("collection_skin_window")
			elseif i == xyd.CollectionType.FACE then
				xyd.WindowManager.get():openWindow("collection_face_window")
			elseif i == xyd.CollectionType.FURNITURE then
				xyd.WindowManager.get():openWindow("collection_furniture_window")
			elseif i == xyd.CollectionType.SOUL then
				xyd.WindowManager.get():openWindow("collection_soul_window")
			elseif i == xyd.CollectionType.STORY then
				xyd.WindowManager.get():openWindow("collection_story_window")
			end
		end)
	end

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.COLLECTION_SHOP,
		xyd.RedMarkType.COLLECTION_SHOP_2
	}, self.shopBtn_redPoint)
end

function CollectionWindow:willClose()
	BaseWindow.willClose(self)
end

function CollectionWindow:checkAndGreyFuncNode(collectionType, funId)
	if funId and collectionType and not self:checkCanOpen(funId) then
		local bar = self[tostring(self.NODES_LIST[collectionType - 1 + 1]) .. "NodeBar"]
		local barText = self[tostring(self.NODES_LIST[collectionType - 1 + 1]) .. "Nodepersent"]
		bar.enabled = false
		barText.enabled = false

		xyd.applyChildrenGrey(self[tostring(self.NODES_LIST[collectionType - 1 + 1]) .. "Node"])
	end
end

function CollectionWindow:checkCanOpen(funId)
	return xyd.checkFunctionOpen(funId, true)
end

function CollectionWindow:checkAndOpen(winName, params, funId)
	if funId and not self:checkCanOpen(funId) then
		local openLev = xyd.tables.functionTable:getOpenValue(funId) or 0
		local tips = __("FUNC_OPEN_LEV", openLev)

		xyd.alert(xyd.AlertType.TIPS, tips)

		return
	end

	xyd.WindowManager.get():openWindow(winName, params)
end

function CollectionWindow:returnCommonScreen()
	BaseWindow.returnCommonScreen(self)

	local ____TS_obj = self.logo
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - 50 * self.scale_num_
	local ____TS_obj = self.heroBg
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - 30 * self.scale_num_
end

return CollectionWindow
