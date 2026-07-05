-- LocalScript для StarterGui: создаёт современное GUI-меню с кнопкой открытия/закрытия.
local TweenService = game:GetService("TweenService") -- Сервис для плавных анимаций.
local Players = game:GetService("Players") -- Сервис игроков.
local UserInputService = game:GetService("UserInputService") -- Сервис ввода мыши и тача.

local player = Players.LocalPlayer -- Получаем локального игрока.
local playerGui = player:WaitForChild("PlayerGui") -- Получаем PlayerGui игрока.

local oldGui = playerGui:FindFirstChild("ModernDarkMenuGui") -- Проверяем, есть ли старая копия GUI.
if oldGui then -- Если старая копия найдена.
	oldGui:Destroy() -- Удаляем старую копию, чтобы не было дублей.
end -- Конец проверки старой копии.

local screenGui = Instance.new("ScreenGui") -- Создаём основной контейнер интерфейса.
screenGui.Name = "ModernDarkMenuGui" -- Даём контейнеру имя.
screenGui.ResetOnSpawn = false -- Не удаляем GUI после смерти персонажа.
screenGui.IgnoreGuiInset = true -- Разрешаем занимать всю область экрана.
screenGui.DisplayOrder = 50 -- Поднимаем интерфейс над большинством GUI.
screenGui.Parent = playerGui -- Помещаем GUI в PlayerGui.

local MAIN_OPEN_SIZE = UDim2.fromOffset(420, 300) -- Размер открытой панели.
local MAIN_CLOSED_SIZE = UDim2.fromOffset(0, 0) -- Размер закрытой панели.
local MAIN_SHADOW_OPEN_SIZE = UDim2.fromOffset(432, 312) -- Размер тени открытой панели.
local OPEN_BUTTON_SIZE = UDim2.fromOffset(62, 62) -- Размер кнопки открытия.
local CLOSED_BUTTON_SIZE = UDim2.fromOffset(0, 0) -- Размер скрытой кнопки открытия.

local openTweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out) -- Анимация открытия.
local closeTweenInfo = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.In) -- Анимация закрытия.
local fadeTweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) -- Анимация прозрачности.
local buttonTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) -- Анимация кнопок.

local isOpen = false -- Показывает, открыто ли меню.
local isTweening = false -- Защищает от спама по кнопкам.
local dragging = false -- Показывает, идёт ли перетаскивание.
local dragStart = Vector3.new(0, 0, 0) -- Начальная точка курсора.
local panelStartPosition = UDim2.new(0.5, 0, 0.5, 0) -- Начальная позиция панели.

local function addCorner(object, radius) -- Функция добавляет скругление.
	local corner = Instance.new("UICorner") -- Создаём UICorner.
	corner.CornerRadius = radius -- Задаём радиус скругления.
	corner.Parent = object -- Помещаем скругление внутрь объекта.
	return corner -- Возвращаем созданный объект.
end -- Конец функции addCorner.

local function addStroke(object, color, thickness, transparency) -- Функция добавляет обводку.
	local stroke = Instance.new("UIStroke") -- Создаём UIStroke.
	stroke.Color = color -- Задаём цвет обводки.
	stroke.Thickness = thickness -- Задаём толщину.
	stroke.Transparency = transparency -- Задаём прозрачность.
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Включаем обводку по границе.
	stroke.Parent = object -- Помещаем обводку внутрь объекта.
	return stroke -- Возвращаем созданную обводку.
end -- Конец функции addStroke.

local function createTween(object, tweenInfo, goals) -- Функция создаёт Tween.
	return TweenService:Create(object, tweenInfo, goals) -- Возвращаем готовую анимацию.
end -- Конец функции createTween.

local function getShadowPosition(framePosition) -- Функция считает позицию тени.
	return UDim2.new(framePosition.X.Scale, framePosition.X.Offset + 8, framePosition.Y.Scale, framePosition.Y.Offset + 8) -- Возвращаем позицию со смещением.
end -- Конец функции getShadowPosition.

local openButtonShadow = Instance.new("Frame") -- Создаём тень кнопки открытия.
openButtonShadow.Name = "OpenButtonShadow" -- Имя тени.
openButtonShadow.AnchorPoint = Vector2.new(0.5, 0.5) -- Якорь по центру.
openButtonShadow.Position = UDim2.new(0, 60, 1, -52) -- Позиция слева снизу.
openButtonShadow.Size = OPEN_BUTTON_SIZE -- Размер тени.
openButtonShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Чёрный цвет тени.
openButtonShadow.BackgroundTransparency = 0.55 -- Полупрозрачная тень.
openButtonShadow.BorderSizePixel = 0 -- Убираем рамку.
openButtonShadow.ZIndex = 1 -- Слой тени.
openButtonShadow.Parent = screenGui -- Добавляем в ScreenGui.
addCorner(openButtonShadow, UDim.new(1, 0)) -- Делаем тень круглой.

local openButton = Instance.new("TextButton") -- Создаём кнопку открытия.
openButton.Name = "OpenButton" -- Имя кнопки.
openButton.AnchorPoint = Vector2.new(0.5, 0.5) -- Якорь по центру.
openButton.Position = UDim2.new(0, 56, 1, -56) -- Позиция слева снизу.
openButton.Size = OPEN_BUTTON_SIZE -- Размер кнопки.
openButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40) -- Тёмный фон.
openButton.BackgroundTransparency = 0 -- Кнопка видимая.
openButton.BorderSizePixel = 0 -- Убираем рамку.
openButton.AutoButtonColor = false -- Отключаем стандартный Roblox-эффект.
openButton.Text = "☰" -- Иконка меню.
openButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Белый текст.
openButton.TextTransparency = 0 -- Текст видим.
openButton.TextSize = 30 -- Размер текста.
openButton.Font = Enum.Font.GothamBold -- Шрифт.
openButton.ZIndex = 2 -- Слой кнопки.
openButton.Parent = screenGui -- Добавляем кнопку в ScreenGui.
addCorner(openButton, UDim.new(1, 0)) -- Делаем кнопку круглой.

local openButtonStroke = addStroke(openButton, Color3.fromRGB(190, 140, 255), 1.5, 0.25) -- Добавляем обводку.

local openGradient = Instance.new("UIGradient") -- Создаём градиент кнопки.
openGradient.Color = ColorSequence.new({ -- Цвета градиента.
	ColorSequenceKeypoint.new(0, Color3.fromRGB(145, 65, 255)), -- Фиолетовый.
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 170, 255)) -- Голубой.
}) -- Конец цветов градиента.
openGradient.Rotation = 35 -- Поворот градиента.
openGradient.Parent = openButton -- Добавляем градиент в кнопку.

local mainShadow = Instance.new("Frame") -- Создаём тень панели.
mainShadow.Name = "MainShadow" -- Имя тени.
mainShadow.AnchorPoint = Vector2.new(0.5, 0.5) -- Якорь по центру.
mainShadow.Position = UDim2.new(0.5, 8, 0.5, 8) -- Позиция тени.
mainShadow.Size = MAIN_CLOSED_SIZE -- Изначально тень закрыта.
mainShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Чёрный цвет.
mainShadow.BackgroundTransparency = 1 -- Изначально невидима.
mainShadow.BorderSizePixel = 0 -- Убираем рамку.
mainShadow.ZIndex = 3 -- Слой тени.
mainShadow.Parent = screenGui -- Добавляем в ScreenGui.
addCorner(mainShadow, UDim.new(0, 18)) -- Скругляем тень.

local mainFrame = Instance.new("Frame") -- Создаём главную панель.
mainFrame.Name = "MainFrame" -- Имя панели.
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- Якорь по центру.
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Позиция по центру.
mainFrame.Size = MAIN_CLOSED_SIZE -- Изначально панель закрыта.
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25) -- Тёмный charcoal-фон.
mainFrame.BackgroundTransparency = 1 -- Изначально невидима.
mainFrame.BorderSizePixel = 0 -- Убираем рамку.
mainFrame.ClipsDescendants = true -- Обрезаем элементы при закрытии.
mainFrame.Active = false -- Изначально ввод не нужен.
mainFrame.ZIndex = 4 -- Слой панели.
mainFrame.Parent = screenGui -- Добавляем панель в ScreenGui.
addCorner(mainFrame, UDim.new(0, 18)) -- Скругляем панель.

local mainStroke = addStroke(mainFrame, Color3.fromRGB(120, 90, 255), 1.5, 1) -- Добавляем скрытую обводку.

local mainGradient = Instance.new("UIGradient") -- Создаём градиент панели.
mainGradient.Color = ColorSequence.new({ -- Цвета градиента панели.
	ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 34, 42)), -- Верхний цвет.
	ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 17, 22)) -- Нижний цвет.
}) -- Конец цветов градиента.
mainGradient.Rotation = 90 -- Вертикальный градиент.
mainGradient.Parent = mainFrame -- Добавляем градиент в панель.

local topBar = Instance.new("Frame") -- Создаём верхнюю панель.
topBar.Name = "TopBar" -- Имя верхней панели.
topBar.Size = UDim2.new(1, 0, 0, 58) -- Размер верхней панели.
topBar.Position = UDim2.fromOffset(0, 0) -- Позиция сверху.
topBar.BackgroundColor3 = Color3.fromRGB(38, 38, 48) -- Цвет верхней панели.
topBar.BackgroundTransparency = 1 -- Изначально скрыта.
topBar.BorderSizePixel = 0 -- Убираем рамку.
topBar.Active = true -- Включаем ввод для перетаскивания.
topBar.ZIndex = 5 -- Слой верхней панели.
topBar.Parent = mainFrame -- Добавляем в главную панель.
addCorner(topBar, UDim.new(0, 18)) -- Скругляем верхнюю панель.

local topBarGradient = Instance.new("UIGradient") -- Создаём градиент верхней панели.
topBarGradient.Color = ColorSequence.new({ -- Цвета верхнего градиента.
	ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 55, 180)), -- Фиолетовый.
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 120, 220)) -- Синий.
}) -- Конец цветов.
topBarGradient.Rotation = 15 -- Поворот градиента.
topBarGradient.Parent = topBar -- Добавляем градиент.

local titleLabel = Instance.new("TextLabel") -- Создаём заголовок.
titleLabel.Name = "TitleLabel" -- Имя заголовка.
titleLabel.Position = UDim2.fromOffset(22, 10) -- Позиция заголовка.
titleLabel.Size = UDim2.new(1, -90, 0, 26) -- Размер заголовка.
titleLabel.BackgroundTransparency = 1 -- Прозрачный фон.
titleLabel.Text = "Modern Menu" -- Текст заголовка.
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Белый текст.
titleLabel.TextTransparency = 1 -- Изначально скрыт.
titleLabel.TextSize = 20 -- Размер текста.
titleLabel.Font = Enum.Font.GothamBold -- Шрифт.
titleLabel.TextXAlignment = Enum.TextXAlignment.Left -- Выравнивание слева.
titleLabel.ZIndex = 6 -- Слой заголовка.
titleLabel.Parent = topBar -- Добавляем в верхнюю панель.

local subtitleLabel = Instance.new("TextLabel") -- Создаём подзаголовок.
subtitleLabel.Name = "SubtitleLabel" -- Имя подзаголовка.
subtitleLabel.Position = UDim2.fromOffset(22, 33) -- Позиция подзаголовка.
subtitleLabel.Size = UDim2.new(1, -90, 0, 18) -- Размер подзаголовка.
subtitleLabel.BackgroundTransparency = 1 -- Прозрачный фон.
subtitleLabel.Text = "Drag the top bar to move" -- Текст подсказки.
subtitleLabel.TextColor3 = Color3.fromRGB(210, 210, 220) -- Светло-серый текст.
subtitleLabel.TextTransparency = 1 -- Изначально скрыт.
subtitleLabel.TextSize = 12 -- Размер текста.
subtitleLabel.Font = Enum.Font.Gotham -- Шрифт.
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left -- Выравнивание слева.
subtitleLabel.ZIndex = 6 -- Слой подзаголовка.
subtitleLabel.Parent = topBar -- Добавляем в верхнюю панель.

local closeButton = Instance.new("TextButton") -- Создаём кнопку закрытия.
closeButton.Name = "CloseButton" -- Имя кнопки.
closeButton.AnchorPoint = Vector2.new(1, 0) -- Якорь справа сверху.
closeButton.Position = UDim2.new(1, -14, 0, 11) -- Позиция кнопки.
closeButton.Size = UDim2.fromOffset(36, 36) -- Размер кнопки.
closeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Цвет фона.
closeButton.BackgroundTransparency = 1 -- Изначально скрыта.
closeButton.BorderSizePixel = 0 -- Убираем рамку.
closeButton.AutoButtonColor = false -- Отключаем стандартный эффект.
closeButton.Text = "×" -- Текст крестика.
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Белый цвет.
closeButton.TextTransparency = 1 -- Изначально скрыт.
closeButton.TextSize = 24 -- Размер крестика.
closeButton.Font = Enum.Font.GothamBold -- Шрифт.
closeButton.ZIndex = 7 -- Слой кнопки.
closeButton.Parent = topBar -- Добавляем в верхнюю панель.
addCorner(closeButton, UDim.new(0, 12)) -- Скругляем кнопку.

local closeStroke = addStroke(closeButton, Color3.fromRGB(255, 255, 255), 1, 1) -- Добавляем скрытую обводку.

local separatorLine = Instance.new("Frame") -- Создаём декоративную линию.
separatorLine.Name = "SeparatorLine" -- Имя линии.
separatorLine.Position = UDim2.new(0, 22, 0, 66) -- Позиция линии.
separatorLine.Size = UDim2.new(1, -44, 0, 2) -- Размер линии.
separatorLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Базовый цвет.
separatorLine.BackgroundTransparency = 1 -- Изначально скрыта.
separatorLine.BorderSizePixel = 0 -- Убираем рамку.
separatorLine.ZIndex = 5 -- Слой линии.
separatorLine.Parent = mainFrame -- Добавляем в панель.
addCorner(separatorLine, UDim.new(1, 0)) -- Скругляем линию.

local separatorGradient = Instance.new("UIGradient") -- Создаём градиент линии.
separatorGradient.Color = ColorSequence.new({ -- Цвета линии.
	ColorSequenceKeypoint.new(0, Color3.fromRGB(145, 65, 255)), -- Фиолетовый.
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 170, 255)) -- Синий.
}) -- Конец цветов.
separatorGradient.Rotation = 0 -- Горизонтальный градиент.
separatorGradient.Parent = separatorLine -- Добавляем градиент.

local contentFrame = Instance.new("Frame") -- Создаём блок контента.
contentFrame.Name = "ContentFrame" -- Имя блока.
contentFrame.Position = UDim2.fromOffset(22, 86) -- Позиция блока.
contentFrame.Size = UDim2.new(1, -44, 1, -108) -- Размер блока.
contentFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 38) -- Цвет блока.
contentFrame.BackgroundTransparency = 1 -- Изначально скрыт.
contentFrame.BorderSizePixel = 0 -- Убираем рамку.
contentFrame.ZIndex = 5 -- Слой блока.
contentFrame.Parent = mainFrame -- Добавляем в панель.
addCorner(contentFrame, UDim.new(0, 14)) -- Скругляем блок.

local contentStroke = addStroke(contentFrame, Color3.fromRGB(90, 90, 110), 1, 1) -- Добавляем скрытую обводку.

local bodyLabel = Instance.new("TextLabel") -- Создаём основной текст.
bodyLabel.Name = "BodyLabel" -- Имя текста.
bodyLabel.Position = UDim2.fromOffset(18, 16) -- Позиция текста.
bodyLabel.Size = UDim2.new(1, -36, 0, 56) -- Размер текста.
bodyLabel.BackgroundTransparency = 1 -- Прозрачный фон.
bodyLabel.Text = "Это полностью созданный через код GUI.\nПанель открывается плавно, закрывается плавно и перетаскивается за верхнюю часть." -- Текст описания.
bodyLabel.TextColor3 = Color3.fromRGB(225, 225, 235) -- Светлый текст.
bodyLabel.TextTransparency = 1 -- Изначально скрыт.
bodyLabel.TextSize = 14 -- Размер текста.
bodyLabel.Font = Enum.Font.Gotham -- Шрифт.
bodyLabel.TextWrapped = true -- Перенос строк.
bodyLabel.TextXAlignment = Enum.TextXAlignment.Left -- Выравнивание слева.
bodyLabel.TextYAlignment = Enum.TextYAlignment.Top -- Выравнивание сверху.
bodyLabel.ZIndex = 6 -- Слой текста.
bodyLabel.Parent = contentFrame -- Добавляем в блок контента.

local actionButton = Instance.new("TextButton") -- Создаём пример кнопки.
actionButton.Name = "ActionButton" -- Имя кнопки.
actionButton.AnchorPoint = Vector2.new(0.5, 1) -- Якорь снизу по центру.
actionButton.Position = UDim2.new(0.5, 0, 1, -18) -- Позиция кнопки.
actionButton.Size = UDim2.new(1, -36, 0, 42) -- Размер кнопки.
actionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60) -- Цвет фона.
actionButton.BackgroundTransparency = 1 -- Изначально скрыта.
actionButton.BorderSizePixel = 0 -- Убираем рамку.
actionButton.AutoButtonColor = false -- Отключаем стандартный эффект.
actionButton.Text = "Example Button" -- Текст кнопки.
actionButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Белый текст.
actionButton.TextTransparency = 1 -- Изначально скрыт.
actionButton.TextSize = 15 -- Размер текста.
actionButton.Font = Enum.Font.GothamBold -- Шрифт.
actionButton.ZIndex = 6 -- Слой кнопки.
actionButton.Parent = contentFrame -- Добавляем в блок контента.
addCorner(actionButton, UDim.new(0, 12)) -- Скругляем кнопку.

local actionGradient = Instance.new("UIGradient") -- Создаём градиент кнопки.
actionGradient.Color = ColorSequence.new({ -- Цвета градиента.
	ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 65, 255)), -- Фиолетовый.
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 165, 255)) -- Голубой.
}) -- Конец цветов градиента.
actionGradient.Rotation = 25 -- Поворот градиента.
actionGradient.Parent = actionButton -- Добавляем градиент в кнопку.

local fadeTargets = { -- Таблица элементов для появления и исчезновения.
	{topBar, {BackgroundTransparency = 0.16}, {BackgroundTransparency = 1}}, -- Верхняя панель.
	{titleLabel, {TextTransparency = 0}, {TextTransparency = 1}}, -- Заголовок.
	{subtitleLabel, {TextTransparency = 0.15}, {TextTransparency = 1}}, -- Подзаголовок.
	{closeButton, {BackgroundTransparency = 0.86, TextTransparency = 0}, {BackgroundTransparency = 1, TextTransparency = 1}}, -- Кнопка закрытия.
	{closeStroke, {Transparency = 0.65}, {Transparency = 1}}, -- Обводка закрытия.
	{separatorLine, {BackgroundTransparency = 0}, {BackgroundTransparency = 1}}, -- Линия.
	{contentFrame, {BackgroundTransparency = 0.08}, {BackgroundTransparency = 1}}, -- Карточка контента.
	{contentStroke, {Transparency = 0.72}, {Transparency = 1}}, -- Обводка карточки.
	{bodyLabel, {TextTransparency = 0}, {TextTransparency = 1}}, -- Текст.
	{actionButton, {BackgroundTransparency = 0, TextTransparency = 0}, {BackgroundTransparency = 1, TextTransparency = 1}}, -- Внутренняя кнопка.
} -- Конец таблицы fadeTargets.

local function tweenFadeTargets(opening) -- Функция проявляет или скрывает элементы.
	for _, targetData in ipairs(fadeTargets) do -- Проходим по всем элементам.
		local object = targetData[1] -- Получаем объект.
		local goals = targetData[3] -- По умолчанию используем цели закрытия.
		if opening then -- Если меню открывается.
			goals = targetData[2] -- Используем цели открытия.
		end -- Конец проверки открытия.
		createTween(object, fadeTweenInfo, goals):Play() -- Запускаем анимацию.
	end -- Конец цикла.
end -- Конец функции tweenFadeTargets.

local function syncShadowWithPanel() -- Функция двигает тень за панелью.
	mainShadow.Position = getShadowPosition(mainFrame.Position) -- Синхронизируем позицию тени.
end -- Конец функции syncShadowWithPanel.

local function openMenu() -- Функция открытия меню.
	if isTweening or isOpen then -- Проверяем защиту от повторного запуска.
		return -- Прерываем функцию.
	end -- Конец проверки.

	isTweening = true -- Включаем блокировку анимаций.
	isOpen = true -- Ставим состояние открыто.
	dragging = false -- Отключаем перетаскивание.
	mainFrame.Active = true -- Включаем активность панели.

	createTween(openButton, buttonTweenInfo, {Size = CLOSED_BUTTON_SIZE, BackgroundTransparency = 1, TextTransparency = 1}):Play() -- Скрываем кнопку открытия.
	createTween(openButtonShadow, buttonTweenInfo, {Size = CLOSED_BUTTON_SIZE, BackgroundTransparency = 1}):Play() -- Скрываем тень кнопки.
	createTween(openButtonStroke, buttonTweenInfo, {Transparency = 1}):Play() -- Скрываем обводку кнопки.

	createTween(mainShadow, openTweenInfo, {Size = MAIN_SHADOW_OPEN_SIZE, BackgroundTransparency = 0.58}):Play() -- Показываем тень панели.
	createTween(mainStroke, fadeTweenInfo, {Transparency = 0.28}):Play() -- Показываем обводку панели.
	tweenFadeTargets(true) -- Показываем внутренние элементы.

	local panelTween = createTween(mainFrame, openTweenInfo, {Size = MAIN_OPEN_SIZE, BackgroundTransparency = 0}) -- Создаём Tween панели.
	panelTween:Play() -- Запускаем Tween панели.
	panelTween.Completed:Wait() -- Ждём завершения Tween.

	isTweening = false -- Снимаем блокировку.
end -- Конец функции openMenu.

local function closeMenu() -- Функция закрытия меню.
	if isTweening or not isOpen then -- Проверяем защиту от повторного запуска.
		return -- Прерываем функцию.
	end -- Конец проверки.

	isTweening = true -- Включаем блокировку.
	isOpen = false -- Ставим состояние закрыто.
	dragging = false -- Отключаем перетаскивание.

	tweenFadeTargets(false) -- Скрываем внутренние элементы.
	createTween(mainShadow, closeTweenInfo, {Size = MAIN_CLOSED_SIZE, BackgroundTransparency = 1}):Play() -- Скрываем тень панели.
	createTween(mainStroke, fadeTweenInfo, {Transparency = 1}):Play() -- Скрываем обводку панели.

	createTween(openButton, buttonTweenInfo, {Size = OPEN_BUTTON_SIZE, BackgroundTransparency = 0, TextTransparency = 0}):Play() -- Показываем кнопку открытия.
	createTween(openButtonShadow, buttonTweenInfo, {Size = OPEN_BUTTON_SIZE, BackgroundTransparency = 0.55}):Play() -- Показываем тень кнопки.
	createTween(openButtonStroke, buttonTweenInfo, {Transparency = 0.25}):Play() -- Показываем обводку кнопки.

	local panelTween = createTween(mainFrame, closeTweenInfo, {Size = MAIN_CLOSED_SIZE, BackgroundTransparency = 1}) -- Создаём Tween закрытия.
	panelTween:Play() -- Запускаем Tween закрытия.
	panelTween.Completed:Wait() -- Ждём завершения.

	mainFrame.Active = false -- Выключаем активность панели.
	isTweening = false -- Снимаем блокировку.
end -- Конец функции closeMenu.

topBar.InputBegan:Connect(function(input) -- Обрабатываем начало ввода на верхней панели.
	if not isOpen or isTweening then -- Проверяем, можно ли перетаскивать.
		return -- Прерываем функцию.
	end -- Конец проверки.

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then -- Проверяем мышь или тач.
		dragging = true -- Включаем перетаскивание.
		dragStart = input.Position -- Запоминаем начальную позицию ввода.
		panelStartPosition = mainFrame.Position -- Запоминаем начальную позицию панели.

		input.Changed:Connect(function() -- Следим за окончанием ввода.
			if input.UserInputState == Enum.UserInputState.End then -- Если пользователь отпустил мышь или палец.
				dragging = false -- Выключаем перетаскивание.
			end -- Конец проверки состояния.
		end) -- Конец обработчика изменения ввода.
	end -- Конец проверки типа ввода.
end) -- Конец обработчика начала ввода.

UserInputService.InputChanged:Connect(function(input) -- Обрабатываем движение мыши или пальца.
	if not dragging then -- Если перетаскивание не активно.
		return -- Прерываем функцию.
	end -- Конец проверки.

	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then -- Проверяем тип ввода.
		return -- Прерываем неподходящий ввод.
	end -- Конец проверки.

	local delta = input.Position - dragStart -- Считаем смещение курсора.
	mainFrame.Position = UDim2.new(panelStartPosition.X.Scale, panelStartPosition.X.Offset + delta.X, panelStartPosition.Y.Scale, panelStartPosition.Y.Offset + delta.Y) -- Двигаем панель.
	syncShadowWithPanel() -- Двигаем тень вместе с панелью.
end) -- Конец обработчика движения.

openButton.MouseEnter:Connect(function() -- Обрабатываем наведение на кнопку открытия.
	if not isTweening and not isOpen then -- Проверяем, что кнопка активна.
		createTween(openButton, fadeTweenInfo, {Size = UDim2.fromOffset(68, 68)}):Play() -- Немного увеличиваем кнопку.
	end -- Конец проверки.
end) -- Конец события MouseEnter.

openButton.MouseLeave:Connect(function() -- Обрабатываем уход курсора с кнопки.
	if not isTweening and not isOpen then -- Проверяем, что кнопка активна.
		createTween(openButton, fadeTweenInfo, {Size = OPEN_BUTTON_SIZE}):Play() -- Возвращаем размер кнопки.
	end -- Конец проверки.
end) -- Конец события MouseLeave.

closeButton.MouseEnter:Connect(function() -- Обрабатываем наведение на кнопку закрытия.
	if not isTweening and isOpen then -- Проверяем, что меню открыто.
		createTween(closeButton, fadeTweenInfo, {BackgroundTransparency = 0.72}):Play() -- Подсвечиваем кнопку закрытия.
	end -- Конец проверки.
end) -- Конец события MouseEnter.

closeButton.MouseLeave:Connect(function() -- Обрабатываем уход курсора с кнопки закрытия.
	if not isTweening and isOpen then -- Проверяем, что меню открыто.
		createTween(closeButton, fadeTweenInfo, {BackgroundTransparency = 0.86}):Play() -- Возвращаем прозрачность.
	end -- Конец проверки.
end) -- Конец события MouseLeave.

actionButton.MouseEnter:Connect(function() -- Обрабатываем наведение на внутреннюю кнопку.
	if isOpen and not isTweening then -- Проверяем, что меню активно.
		createTween(actionButton, fadeTweenInfo, {Size = UDim2.new(1, -28, 0, 44)}):Play() -- Немного увеличиваем кнопку.
	end -- Конец проверки.
end) -- Конец события MouseEnter.

actionButton.MouseLeave:Connect(function() -- Обрабатываем уход курсора с внутренней кнопки.
	if isOpen and not isTweening then -- Проверяем, что меню активно.
		createTween(actionButton, fadeTweenInfo, {Size = UDim2.new(1, -36, 0, 42)}):Play() -- Возвращаем размер.
	end -- Конец проверки.
end) -- Конец события MouseLeave.

actionButton.MouseButton1Click:Connect(function() -- Обрабатываем нажатие на пример кнопки.
	if isTweening then -- Проверяем, идёт ли анимация.
		return -- Не выполняем действие во время анимации.
	end -- Конец проверки.
	bodyLabel.Text = "Кнопка внутри меню нажата.\nЗдесь можно подключить любую игровую логику." -- Меняем текст для примера.
end) -- Конец обработчика внутренней кнопки.

openButton.MouseButton1Click:Connect(function() -- Обрабатываем нажатие кнопки открытия.
	openMenu() -- Открываем меню.
end) -- Конец обработчика кнопки открытия.

closeButton.MouseButton1Click:Connect(function() -- Обрабатываем нажатие кнопки закрытия.
	closeMenu() -- Закрываем меню.
end) -- Конец обработчика кнопки закрытия.
