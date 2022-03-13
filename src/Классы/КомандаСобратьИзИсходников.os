///////////////////////////////////////////////////////////////////////////////////////////////////
//
// Выполнение команды/действия в 1С:Предприятие в режиме тонкого/толстого клиента с передачей запускаемых обработок и параметров
//
// TODO добавить фичи для проверки команды
//
// Служебный модуль с набором методов работы с командами приложения
//
// Структура модуля реализована в соответствии с рекомендациями
// oscript-app-template (C) EvilBeaver
//
///////////////////////////////////////////////////////////////////////////////////////////////////

#Использовать logos
#Использовать v8runner

Перем Лог;
Перем МенеджерКонфигуратора;

///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт

	ТекстОписания =
		"     Сборка cf-файла из исходников.";

	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды,
		ТекстОписания);

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--src",
		"Путь к каталогу с исходниками, пример: --src=./cf");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-s",
		"Краткая команда 'путь к исходникам --src', пример: -s ./cf");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--out", "Путь к файлу cf (*.cf), --out=./1Cv8.cf");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-o",
		"Краткая команда 'Путь к файлу cf --out', пример: -o ./1Cv8.cf");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--current", "Флаг загрузки в указанную базу или -с");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-c", "Флаг загрузки в указанную базу, краткая форма от --current");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--list", "Список файлов для загрузки");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--noupdate", "Флаг обновления СonfigDumpInfo.xml");

	Парсер.ДобавитьКоманду(ОписаниеКоманды);

КонецПроцедуры // ЗарегистрироватьКоманду

// Выполняет логику команды
//
// Параметры:
//   ПараметрыКоманды - Соответствие - Соответствие ключей командной строки и их значений
//   ДополнительныеПараметры - Соответствие - дополнительные параметры (необязательно)
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды, Знач ДополнительныеПараметры = Неопределено) Экспорт

	Попытка
		Лог = ДополнительныеПараметры.Лог;
	Исключение
		Лог = Логирование.ПолучитьЛог(ПараметрыСистемы.ИмяЛогаСистемы());
	КонецПопытки;

	ДанныеПодключения = ПараметрыКоманды["ДанныеПодключения"];

	ПутьВходящий = ОбщиеМетоды.ПолныйПуть(ОбщиеМетоды.ПолучитьПараметры(ПараметрыКоманды, "-s", "--src"));
	ПутьИсходящий = ОбщиеМетоды.ПолныйПуть(ОбщиеМетоды.ПолучитьПараметры(ПараметрыКоманды,"-o", "--out"));
	ВерсияПлатформы = ПараметрыКоманды["--v8version"];
	СписокФайлов = ПараметрыКоманды["--list"];
	СтрокаПодключения = ДанныеПодключения.СтрокаПодключения;
	ОбновлятьДамп = НЕ ПараметрыКоманды["--noupdate"];

	МенеджерКонфигуратора = Новый МенеджерКонфигуратора;

	Попытка
		ВТекущуюКонфигурацию = ОбщиеМетоды.ПолучитьПараметры(ПараметрыКоманды, "-c", "--current");
		Если ТипЗнч(ВТекущуюКонфигурацию) = Тип("Булево") И ВТекущуюКонфигурацию Тогда
			МенеджерКонфигуратора.Инициализация(ДанныеПодключения.СтрокаПодключения,
				ДанныеПодключения.Пользователь, ДанныеПодключения.Пароль,
				ВерсияПлатформы, ПараметрыКоманды["--uccode"], ДанныеПодключения.КодЯзыка);

			МенеджерКонфигуратора.СобратьИзИсходниковТекущуюКонфигурацию(
				ПутьВходящий,
				СписокФайлов, Истина, ОбновлятьДамп);
		Иначе
			СобратьИзИсходниковФайлКонфигурации(ПутьВходящий, ПутьИсходящий, ДанныеПодключения, ВерсияПлатформы, ОбновлятьДамп);
		КонецЕсли;
	Исключение
		МенеджерКонфигуратора.Деструктор();
		ВызватьИсключение ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
	КонецПопытки;

	МенеджерКонфигуратора.Деструктор();

	Возврат МенеджерКомандПриложения.РезультатыКоманд().Успех;
КонецФункции // ВыполнитьКоманду

Процедура СобратьИзИсходниковФайлКонфигурации(ПутьВходящий, ПутьИсходящий, ДанныеПодключения,
	ВерсияПлатформы, ОбновлятьФайлВерсий)

	КаталогВременнойБазы = ВременныеФайлы.СоздатьКаталог();
	СтрокаПодключения = "/F""" + КаталогВременнойБазы + """";
	МенеджерКонфигуратора.Инициализация(СтрокаПодключения, "", "", ВерсияПлатформы, , ДанныеПодключения.КодЯзыка);
	Конфигуратор = МенеджерКонфигуратора.УправлениеКонфигуратором();

	Конфигуратор.СоздатьФайловуюБазу(КаталогВременнойБазы);

	МенеджерКонфигуратора.СобратьИзИсходниковТекущуюКонфигурацию(ПутьВходящий, , , ОбновлятьФайлВерсий);
	МенеджерКонфигуратора.ВыгрузитьКонфигурациюВФайл(ПутьИсходящий);

	ВременныеФайлы.УдалитьФайл(КаталогВременнойБазы);

КонецПроцедуры
