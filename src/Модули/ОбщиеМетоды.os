#Использовать logos
#Использовать tempfiles
#Использовать fs
#Использовать json
#Использовать ParserFileV8i
#Использовать strings

Перем Лог;
Перем ФайлПарсераСпискаБаз Экспорт;
Перем КэшПодключенныхБаз;

Функция ПодключитьРаннер() Экспорт // TODO удалить  метод после рефакторинга
	Путь = ОбъединитьПути(КаталогПроекта(), "tools", "runner.os");
	ПодключитьСценарий(Путь, "runner");
	runner = Новый runner();
	Возврат runner;
КонецФункции

Функция ЗапуститьПроцесс(Знач СтрокаВыполнения) Экспорт
	Перем ПаузаОжиданияЧтенияБуфера;
	
	ПаузаОжиданияЧтенияБуфера = 10;
	
	Лог = ПолучитьЛог();
	Лог.Отладка(СтрокаВыполнения);
	Процесс = СоздатьПроцесс(СтрокаВыполнения,,Истина);
	Процесс.Запустить();
	
	ТекстБазовый = "";
	Счетчик = 0; МаксСчетчикЦикла = 100000;
	
	Пока Истина Цикл 
		Текст = Процесс.ПотокВывода.Прочитать();
		Лог.Отладка("Цикл ПотокаВывода "+Текст);
		Если Текст = Неопределено ИЛИ ПустаяСтрока(СокрЛП(Текст))  Тогда 
			Прервать;
		КонецЕсли;
		Счетчик = Счетчик + 1;
		Если Счетчик > МаксСчетчикЦикла Тогда 
			Прервать;
		КонецЕсли;
		ТекстБазовый = ТекстБазовый + Текст;
		
		sleep(ПаузаОжиданияЧтенияБуфера); //Подождем, надеюсь буфер не переполниться. 
		
	КонецЦикла;
	
	Процесс.ОжидатьЗавершения();
	
	Если Процесс.КодВозврата = 0 Тогда
		Текст = Процесс.ПотокВывода.Прочитать();
		Если Текст = Неопределено ИЛИ ПустаяСтрока(СокрЛП(Текст)) Тогда 

		Иначе
			ТекстБазовый = ТекстБазовый + Текст;
		КонецЕсли;
		Лог.Отладка(ТекстБазовый);
		Возврат ТекстБазовый;
	Иначе
		ВызватьИсключение "Сообщение от процесса 
		| код:" + Процесс.КодВозврата + " процесс: "+ Процесс.ПотокОшибок.Прочитать();
	КонецЕсли;	

КонецФункции

Функция ПрочитатьФайлИнформации(Знач ПутьКФайлу) Экспорт

	Текст = "";
	Файл = Новый Файл(ПутьКФайлу);
	Если Файл.Существует() Тогда
		Чтение = Новый ЧтениеТекста(Файл.ПолноеИмя);
		Текст = Чтение.Прочитать();
		Чтение.Закрыть();
	Иначе
		Текст = "Информации об ошибке нет";
	КонецЕсли;

	Лог = ПолучитьЛог();
	Лог.Отладка("файл информации:
	|"+Текст);
	Возврат Текст;

КонецФункции

Процедура ДополнитьАргументыИзПеременныхОкружения(Знач СоответствиеПеременных, ЗначенияПараметров) Экспорт
	ПолучитьЛог();

	Для каждого Элемент Из СоответствиеПеременных Цикл
		ЗначениеПеременной = ПолучитьПеременнуюСреды(ВРег(Элемент.Ключ));
		ПараметрКоманднойСтроки = ЗначенияПараметров.Получить(Элемент.Значение);
		Если ПараметрКоманднойСтроки = Неопределено ИЛИ ПустаяСтрока(ПараметрКоманднойСтроки) Тогда 
			Если ЗначениеЗаполнено(ЗначениеПеременной) И НЕ ПустаяСтрока(ЗначениеПеременной) Тогда
				ЗначенияПараметров.Вставить(Элемент.Значение, ЗначениеПеременной);
			КонецЕсли;
		КонецЕсли;
	КонецЦикла;
	Для Каждого Параметр Из ЗначенияПараметров Цикл
		Лог.Отладка("Передан параметр: %1 = %2", Параметр.Ключ, Параметр.Значение);
	КонецЦикла;
	
КонецПроцедуры

Функция ИмяФайлаНастроек() Экспорт
	Возврат "env.json";
КонецФункции // ИмяФайлаНастроек()

Процедура ДополнитьАргументыИзФайлаНастроек(Знач Команда, ЗначенияПараметров, Знач НастройкиИзФайла) Экспорт
	Перем КлючПоУмолчанию, Настройки;
	КлючПоУмолчанию = "default";

	ДополнитьСоответствиеСУчетомПриоритета(ЗначенияПараметров, НастройкиИзФайла.Получить(Команда));
	ДополнитьСоответствиеСУчетомПриоритета(ЗначенияПараметров, НастройкиИзФайла.Получить(КлючПоУмолчанию));

	ПолучитьЛог();
	Для каждого Элемент из ЗначенияПараметров Цикл 
		Лог.Отладка(Элемент.Ключ + ":"+Элемент.Значение);
	КонецЦикла;

КонецПроцедуры //ДополнитьАргументыИзФайлаНастроек

Процедура ДополнитьСоответствиеСУчетомПриоритета(КоллекцияОсновная, Знач КоллекцияДоп = Неопределено)
	Если КоллекцияДоп = Неопределено Тогда 
		Возврат;
	КонецЕсли;

	Для Каждого Элемент из КоллекцияДоп Цикл 
		Значение = КоллекцияОсновная.Получить(Элемент.Ключ);
		Если НЕ ЗначениеЗаполнено(Значение) Тогда 
			КоллекцияОсновная.Вставить(Элемент.Ключ, Элемент.Значение);
		КонецЕсли;
	КонецЦикла;
КонецПроцедуры //ДополнитьСоответствиеСУчетомПриоритета

Функция ПереопределитьПолныйПутьВСтрокеПодключения(Знач СтрокаПодключения) Экспорт
	ПолучитьЛог().Отладка(СтрокаПодключения);
	Если Лев(СтрокаПодключения,2)="/F" Тогда
		ПутьКБазе = УбратьКавычкиВокругПути(Сред(СтрокаПодключения, 3));
		ПутьКБазе = ПолныйПуть(ПутьКБазе);
		СтрокаПодключения = "/F""" + ПутьКБазе + """"
	КонецЕсли;
	Возврат СтрокаПодключения;
КонецФункции // ПереопределитьПолныйПутьВСтрокеПодключения()

Функция ПрочитатьНастройкиФайлJSON(Знач ТекущийКаталогПроекта, Знач ПутьКФайлу = Неопределено ) Экспорт
	ИмяФайлаНастроек = ИмяФайлаНастроек();

	Лог.Отладка(":"+ПутьКФайлу+":"+ИмяФайлаНастроек);
	Если ПутьКФайлу = Неопределено ИЛИ НЕ ЗначениеЗаполнено(ПутьКФайлу) Тогда 
		ПутьКФайлу = ОбъединитьПути(ТекущийКаталогПроекта, ИмяФайлаНастроек);
	КонецЕсли;
	Лог.Отладка(ПутьКФайлу);

	Возврат ПрочитатьФайлJSON(ПутьКФайлу);
КонецФункции

Функция ПрочитатьФайлJSON(Знач ИмяФайла) Экспорт
	Лог.Отладка(ИмяФайла);
	ФайлСуществующий = Новый Файл(ИмяФайла);
	Если Не ФайлСуществующий.Существует() Тогда
		Возврат Новый Соответствие;
	КонецЕсли;
	Чтение = Новый ЧтениеТекста(ИмяФайла, КодировкаТекста.UTF8);
	JsonСтрока  = Чтение.Прочитать();
	Чтение.Закрыть();
	ПарсерJSON  = Новый ПарсерJSON();
	Результат   = ПарсерJSON.ПрочитатьJSON(JsonСтрока);

	Возврат Результат;
КонецФункции

// TODO возможно, лучше просто передавать параметры для инкапсуляции знания об "--ordinaryapp" в одном месте
Функция УказанПараметрТолстыйКлиент(Знач ПараметрТолстыйКлиентИзКоманднойСтроки, Знач Лог) Экспорт
	Если ПараметрТолстыйКлиентИзКоманднойСтроки = Неопределено Тогда
		ЗапускатьТолстыйКлиент = Ложь;
		ОписаниеПараметра = "Не задан параметр --ordinaryapp";
	Иначе
		ЗапускатьТолстыйКлиент = ПараметрТолстыйКлиентИзКоманднойСтроки = Истина
			ИЛИ СокрЛП(Строка(ПараметрТолстыйКлиентИзКоманднойСтроки)) = "1" ;
		ОписаниеПараметра = СтрШаблон("Передан параметр --ordinaryapp, равный %1,", ПараметрТолстыйКлиентИзКоманднойСтроки);
	КонецЕсли;
	
	Лог.Отладка(СтрШаблон("%1 для выбора режима толстого/тонкого клиента", ОписаниеПараметра));
	Если ЗапускатьТолстыйКлиент Тогда
		Лог.Отладка("Выбран режим запуска - толстый клиент 1С.");
	Иначе
		Лог.Отладка("Выбран режим запуска - тонкий клиент 1С.");
	КонецЕсли;
	
	Возврат ЗапускатьТолстыйКлиент;
КонецФункции

Функция ПолучитьИмяВременногоФайлаВКаталоге(Знач Каталог, Знач Расширение = "") Экспорт
	ПревКаталог = ВременныеФайлы.БазовыйКаталог;
	ВременныеФайлы.БазовыйКаталог = Каталог;
	ИмяВременногоФайла = ВременныеФайлы.НовоеИмяФайла(Расширение);
	ВременныеФайлы.БазовыйКаталог = ПревКаталог;
	Возврат ИмяВременногоФайла;
КонецФункции

// TODO перенести в библиотеку ФС/fs
Процедура УдалитьФайлЕслиОнСуществует(Знач ПутьФайла) Экспорт
	ПутьФайла = ОбъединитьПути(ТекущийКаталог(), ПутьФайла);
	Файл = Новый Файл(ПутьФайла);	
	Если Файл.Существует() Тогда
		УдалитьФайлы(ПутьФайла);
	КонецЕсли;
КонецПроцедуры

Процедура ОбеспечитьПустойКаталог(Знач ФайлОбъектКаталога) Экспорт

	//TODO заменить ОбеспечитьПустойКаталог на ФС.ОбеспечитьПустойКаталог
	ФС.ОбеспечитьПустойКаталог(ФайлОбъектКаталога.ПолноеИмя);
	
КонецПроцедуры

Функция ОбернутьПутьВКавычки(Знач Путь) Экспорт

	Результат = Путь;
	Если Прав(Результат, 1) = "\" ИЛИ Прав(Результат, 1) = "/" Тогда
		Результат = Лев(Результат, СтрДлина(Результат) - 1);
	КонецЕсли;

	Результат = """" + Результат + """";

	Возврат Результат;

КонецФункции

Функция УбратьКавычкиВокругПути(Знач Путь) Экспорт
	//NOTICE: https://github.com/xDrivenDevelopment/precommit1c 
	//Apache 2.0 
	ОбработанныйПуть = Путь;

	Если Лев(ОбработанныйПуть, 1) = """" Тогда
		ОбработанныйПуть = Прав(ОбработанныйПуть, СтрДлина(ОбработанныйПуть) - 1);
	КонецЕсли;
	Если Прав(ОбработанныйПуть, 1) = """" Тогда
		ОбработанныйПуть = Лев(ОбработанныйПуть, СтрДлина(ОбработанныйПуть) - 1);
	КонецЕсли;
	
	Возврат ОбработанныйПуть;
	
КонецФункции

Функция ПолныйПуть(Знач Путь, Знач КаталогПроекта = "") Экспорт
	Перем ФайлПуть;
	
	Если ПустаяСтрока(Путь) Тогда 
		Возврат Путь;
	КонецЕсли;

	Если ПустаяСтрока(КаталогПроекта) Тогда
		КаталогПроекта = ПараметрыСистемы.КорневойПутьПроекта;
	КонецЕсли;

	Если Лев(Путь, 1) = "." Тогда 
		Путь = ОбъединитьПути(КаталогПроекта, Путь);
	КонецЕсли;
	
	ФайлПуть = Новый Файл(Путь);

	Возврат ФайлПуть.ПолноеИмя
	
КонецФункции //ПолныйПуть()

Функция КаталогПроекта() Экспорт
	ФайлИсточника = Новый Файл(ТекущийСценарий().Источник);
	Возврат ОбъединитьПути(ФайлИсточника.Путь, "..", "..");
КонецФункции

Функция ПолучитьЛог()
	Если Лог = Неопределено Тогда
		Лог = Логирование.ПолучитьЛог(ПараметрыСистемы.ИмяЛогаСистемы());
	КонецЕсли;
	Возврат Лог;	
КонецФункции

Функция ТипФайлаПоддерживается(Знач Файл) Экспорт
	Если ПустаяСтрока(Файл.Расширение) Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Поз = Найти(".epf,.erf,", Файл.Расширение+",");
	Возврат Поз > 0;
	
КонецФункции

//Возвращает парсер списка баз, для возможности его модификации.
Функция ПолучитьПарсерБаз() Экспорт
	Перем Парсер;
	Парсер = Новый ПарсерСпискаБаз;
	Если ЗначениеЗаполнено(ФайлПарсераСпискаБаз) Тогда 
		Парсер.УстановитьФайл(ФайлПарсераСпискаБаз);
	Иначе 
		СистемнаяИнформация = Новый СистемнаяИнформация;
		ЭтоWindows = Найти(ВРег(СистемнаяИнформация.ВерсияОС), "WINDOWS") > 0;
		Если НЕ ЭтоWindows Тогда
			ЗначениеПеременной = ПолучитьПеременнуюСреды(ВРег("HOME"));
			ФайлСпискаБаз = Новый Файл(ОбъединитьПути(ЗначениеПеременной, ".1C/1cestart/ibases.v8i")).ПолноеИмя;
			Парсер.УстановитьФайл(ФайлСпискаБаз);
		КонецЕсли;
	КонецЕсли;

	Возврат Парсер;
КонецФункции

//Получает строку названия базы в списке подключения 
//
//	Параметры:
//		СтрокаПодключения - Строка - строка подключения к базе
//							Примеры: /F"d:\path", /S"server1c\base", Connect=File="/tmp/base
//		ВидЗначения - Строка - ключ из структуры описания базы, по умолчанию Name, можно получить ID для очистки кэша.
//		Парсер - ПарсерСпискаБаз - для целей тестирования и ускорения поиска, возможно переопределить. 
//
//	Возвращаемое значение:
//		Строка - имя базы в списке
//		Неопределено - в случаи ошибки поиска, парсинга или какой другой.
//
Функция ПолучитьИмяБазыВСписке(Знач СтрокаПодключения, Знач ВидЗначения = "Name", Знач Парсер = Неопределено) Экспорт
	//Перем Результат, Парсер, СписокБаз, СтрокаПоиска;
	Результат = Неопределено;
	СтрокаПоиска = "";
	Попытка
		Если Парсер = Неопределено Тогда
			Парсер = ПолучитьПарсерБаз();
		КонецЕсли;
		СписокБаз = Парсер.ПолучитьСписокБаз();
	Исключение
		Лог.Ошибка("Загрузка файла списка баз "+ОписаниеОшибки());
		Возврат Результат;
	КонецПопытки;

	Если СписокБаз = Неопределено Тогда 
		Возврат Результат;
	КонецЕсли;

	СтрокаПоиска = СтрокаКоннекта(СтрокаПодключения);

	Если ПустаяСтрока(СтрокаПоиска) Тогда 
		Возврат Результат;
	КонецЕсли;

	Для каждого База Из СписокБаз Цикл
		СтруктураАдреса = База.Значение;
		НеобходимВыход = Ложь;
		Для каждого Часть Из СтруктураАдреса Цикл
			Если Часть.Ключ = "Connect" И СтрокаПоиска = Часть.Значение.String Тогда
				Попытка
					Результат = СтруктураАдреса[ВидЗначения];
				Исключение
					Лог.Ошибка(
						СтрШаблон("Получить описание БД по виду <%1> ошибка <%2>",ВидЗначения, ОписаниеОшибки()));
				КонецПопытки;
				НеобходимВыход = Истина;
				Прервать;
			КонецЕсли;
		КонецЦикла;

		Если НеобходимВыход Тогда
			Прервать;
		КонецЕсли;
	КонецЦикла;

	Возврат Результат;

КонецФункции //ПолучитьИмяБазыВСписке

// Добавляет в список базу новую базу по наименованию проекта, в случаи задвоения к наименованию 
// добавляем еще и CRC32 от полного пути проекта.
//
//	Параметры:
//		СтрокаПодключения - Строка - Строка подключения к базе данных
//		НазваниеПроекта - Строка - Название проекта, в случаи передачи КорневойПутьПроекта, тогда определяет как ИмяБезРасширения
//		ДопПараметры - Структура - дополнительные параметры в виде структуры,с необязательными значениями
//			+ Version - Строка - версия платформы для запуска, пустое значение или "8.3", "8.3.10"
//			+ RootPath - Строка - путь к каталогу с проектом, если пустой, тогда берем текущий каталог. 
//			+ * - дополнительные ключи, которые можно записать в ibases.v8i
//	
Процедура ДобавитьБазуВСписокБаз(Знач СтрокаПодключения, Знач НазваниеПроекта = "", ДопПараметры = Неопределено) Экспорт
	Перем КорневойПутьПроекта;
	Если  ТипЗнч(ДопПараметры) = Тип("Структура") Тогда
		КорневойПутьПроекта = ?(ЗначениеЗаполнено(ДопПараметры["RootPath"]), ТекущийКаталог(), ДопПараметры["RootPath"]);
	Иначе
		КорневойПутьПроекта = ТекущийКаталог();
	КонецЕсли;

	Провайдер = Новый ХешированиеДанных(ХешФункция.CRC32);
	Провайдер.Добавить(КорневойПутьПроекта);
	МассивНаименований = Новый Массив;
	МассивНаименований.Добавить(СокрЛП(НазваниеПроекта));
	МассивНаименований.Добавить(СокрЛП(НазваниеПроекта) + "_" + СокрЛП(Провайдер.ХешСуммаСтрокой));

	//База уже есть в списке, ничего не делаем.
	ИмяБазыВСписке = ПолучитьИмяБазыВСписке(СтрокаПодключения);
	Если ЗначениеЗаполнено(ИмяБазыВСписке) Тогда 
		Лог.Отладка(СтрШаблон("Базу нашли в списке <%1>, пропускаем добавление", ИмяБазыВСписке));
		Возврат;
	КонецЕсли;

	ДобавилиБазу = Ложь;
	Парсер = ПолучитьПарсерБаз();
	СписокБаз = Парсер.ПолучитьСписокБаз();
	
	Для Каждого ИмяБазы из МассивНаименований Цикл
		Если Парсер.НайтиПоИмени(ИмяБазы) = Неопределено Тогда
			ДобавилиБазу = Истина;
			ОписаниеБазы = ОписаниеБазыВСписке(ДопПараметры);
			ОписаниеБазы.Вставить("Name", ИмяБазы);
			ОписаниеБазы.Вставить("Connect", Новый Структура("String", СтрокаКоннекта(СтрокаПодключения)));
			СписокБаз.Вставить(ИмяБазы, ОписаниеБазы);
			Попытка
				Парсер.ЗаписатьСписокБаз(СписокБаз);
			Исключение
				Лог.Ошибка(СтрШаблон("Запись нового списка <%1>, ошибка <%2>", ИмяБазы, 
					ОписаниеОшибки()));
			КонецПопытки;
			Прервать;
		КонецЕсли;
	КонецЦикла;

КонецПроцедуры //ДобавитьБазуВСписокБаз

Функция СтрокаКоннекта(Знач СтрокаПодключения)
	Результат = "";
	Если Врег(Лев(СтрокаПодключения, 2)) = "/F" Тогда
		//Connect=File="/home/evgensosna/projects/land/build/ib";
		//Кавычки убираем два раза, вдруг кавычки в кавычках. 
		СтрокаПредварительно = УбратьКавычкиВокругПути(Сред(СтрокаПодключения,3, СтрДлина(СтрокаПодключения)-2));
		СтрокаПредварительно = СтрЗаменить(СтрокаПредварительно, "/", ПолучитьРазделительПути());
		СтрокаПредварительно = СтрЗаменить(СтрокаПредварительно, "\", ПолучитьРазделительПути());
		СтрокаПредварительно = Новый Файл(СтрокаПредварительно).ПолноеИмя;
		Результат = "Connect=File=""" + СтрокаПредварительно + """";
	ИначеЕсли Врег(Лев(СтрокаПодключения, 2)) = "/S" Тогда
		//Connect=Srvr="serverssl.service.th.consul";Ref="ssl";
		РезультатПромежуточный = УбратьКавычкиВокругПути(
				УбратьКавычкиВокругПути(Сред(СтрокаПодключения,3))
				);
		Разделитель = ?(Найти(Результат, "/")>0, "/", "\");
		МассивПодключения = 
			СтроковыеФункции.РазложитьСтрокуВМассивПодстрок(РезультатПромежуточный, Разделитель);
		Если МассивПодключения.Количество() = 2 Тогда 
			Результат = СтрШаблон("Connect=Srvr=""%1"";Ref=""%2"";", МассивПодключения[0], МассивПодключения[1]);
		КонецЕсли;
	ИначеЕсли Врег(Лев(СтрокаПодключения, 7)) = "Connect" Тогда
		Результат = СтрокаПодключения;
	КонецЕсли;
	Возврат Результат;
КонецФункции // СтрокаКоннекта(Знач СтрокаПодключения)

//Возвращает структуру с описанием базы данных
//
//	Параметры:
//		ДопПараметры - Структура - произвольные данные, которые добавим к результирующей структуре.
//
//	Возвращаемое значение:
//		Структура с минимальным описанием базы данных.
Функция ОписаниеБазыВСписке(ДопПараметры)
	Результат = Новый Структура();
	Результат.Вставить("Connect","");
	// UUID генерим сразу, т.к. структура новая.
	Результат.Вставить("ID", Новый УникальныйИдентификатор()); 
	Результат.Вставить("OrderInList", ТекущаяУниверсальнаяДатаВМиллисекундах());
	Результат.Вставить("Folder", "/");
	Результат.Вставить("OrderInTree", ТекущаяУниверсальнаяДатаВМиллисекундах());
	Результат.Вставить("External", "0");
	Результат.Вставить("ClientConnectionSpeed", "Normal");
	Результат.Вставить("App", "Auto");
	Результат.Вставить("WA", "1");
	Результат.Вставить("Version", "");
	Если ТипЗнч(ДопПараметры) = Тип("Структура") Тогда
		Для каждого Элемент из ДопПараметры Цикл
			Результат.Вставить(Элемент.Ключ, Элемент.Значение);
		КонецЦикла;
	КонецЕсли;

	Возврат Результат;
КонецФункции //ОписаниеБазыВСписке

Функция ПреобразоватьСтрокуПодключения(Знач СтрокаПодключения = Неопределено) Экспорт
	Если КэшПодключенныхБаз = Неопределено Тогда
		КэшПодключенныхБаз = Новый Соответствие;
	КонецЕсли;

	Если НЕ ЗначениеЗаполнено(СтрокаПодключения) Тогда 
		Возврат СтрокаПодключения;
	КонецЕсли;

	Если КэшПодключенныхБаз.Получить(СтрокаПодключения) = Неопределено Тогда
		Результат = ПолучитьИмяБазыВСписке(СтрокаПодключения);
		КэшПодключенныхБаз.Вставить(СтрокаПодключения, СтрШаблон("/IBName ""%1"" ", Строка(Результат)));
		Если НЕ ЗначениеЗаполнено(Результат) Тогда
			КэшПодключенныхБаз.Вставить(СтрокаПодключения, Ложь);
			Возврат СтрокаПодключения;
		КонецЕсли;
	КонецЕсли;

	Результат = КэшПодключенныхБаз.Получить(СтрокаПодключения);
	Если ТипЗнч(Результат) = Тип("Булево") Тогда
		Результат = СтрокаПодключения;
	КонецЕсли;
	
	Лог.Отладка(СтрШаблон("Кэш подключения БД %1 преобразовали в %2", СтрокаПодключения, Результат));
	
	Возврат Результат;
	
КонецФункции //ПреобразоватьСтрокуПодключения

//Возвращает строку с именем в общем списке баз или же исходную, с условием использования кэша. 
//	Параметры:
//		СтрокаПодключения - Строка - строка подключения к базе, пример /F./build/ib , /Sserveronec/ib
//		ИспользоватьКэш - Строка - принимает значения 0 или 1, 0 - не использовать кэш, 1 - использовать и попытаться 
//									найти данную строку подключения в списке баз данных. По умолчанию "0"
//	Возвращаемое значение:
//		Строка - преобразованная СтрокаПодключения, что и на входе или же с учетом имени в списке баз /IBName "test"
Функция ПолучитьСтрокуПодключенияСКэшем(Знач СтрокаПодключения, ИспользоватьКэш = "0") Экспорт
	Перем Результат;
	Результат = ?(ИспользоватьКэш = "1", 
			ПреобразоватьСтрокуПодключения(СтрокаПодключения),
			СтрокаПодключения);

	Возврат Результат;
КонецФункции // ПолучитьСтрокуПодключенияСКэшем()

// из-за особенностей загрузки модуль ОбщиеМетоды грузится раньше ПараметрыСистемы, 
//поэтому сразу в конце кода модуля использовать ПараметрыСистемы нельзя
