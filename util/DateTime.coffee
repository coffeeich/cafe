@import "cafe/template/Parser"

package "cafe.util",

DateTime: class DateTime

  @toStr: (date, tmpl) ->
    return "" unless date

    unless date instanceof Date
      date = unless isNaN(ms = Number(date)) then new Date(ms) else new Date()

    return "" unless date and day = date.getDate()

    hours   = date.getHours()
    month   = date.getMonth()
    minutes = date.getMinutes()
    seconds = date.getSeconds()
    millis = date.getMilliseconds()

    tmpl or = "%[year]%-%[month]%-%[day]% %[hours]%:%[minutes]%:%[seconds]%"

    tmpl = tmpl.replace(/%\[\s*(.*?)\s*\]%/g,"%($1)%")

    generator = Parser.getGenerator(tmpl)

    return generator(
      year   : "" + date.getFullYear()
      month  : if month   < 9  then "0" + (month + 1) else "" + (month + 1)
      day    : if day     < 10 then "0" + day         else "" + day
      hours  : if hours   < 10 then "0" + hours       else "" + hours
      minutes: if minutes < 10 then "0" + minutes     else "" + minutes
      seconds: if seconds < 10 then "0" + seconds     else "" + seconds
      millis : if millis  < 10 then "0" + millis      else "" + millis
      full:
        month:
          ru: if (/%\[day\]%/).test(tmpl) then DateTime.MONTH_NAMES.ru[month].full2 else DateTime.MONTH_NAMES.ru[month].full
          en: DateTime.MONTH_NAMES.en[month].full
      small:
        month:
          ru: DateTime.MONTH_NAMES.ru[month].small
          en: DateTime.MONTH_NAMES.en[month].small
    )

  # Названия месяцев.
  # @static
  @MONTH_NAMES:
    en: [{small: "Jan",  full: "January"}
         {small: "Feb",  full: "February"}
         {small: "Mar",  full: "March"}
         {small: "Apr",  full: "April"}
         {small: "May",  full: "May"}
         {small: "June", full: "June"}
         {small: "July", full: "July"}
         {small: "Aug",  full: "August"}
         {small: "Sept", full: "September"}
         {small: "Oct",  full: "October"}
         {small: "Nov",  full: "November"}
         {small: "Dec",  full: "December"}]

    ru: [{small: "Янв",  full: "Январь",   full2: "Января"}
         {small: "Фев",  full: "Февраль",  full2: "Февраля"}
         {small: "Март", full: "Март",     full2: "Марта"}
         {small: "Апр",  full: "Апрель",   full2: "Апреля"}
         {small: "Май",  full: "Май",      full2: "Мая"}
         {small: "Июнь", full: "Июнь",     full2: "Июня"}
         {small: "Июль", full: "Июль",     full2: "Июля"}
         {small: "Авг",  full: "Август",   full2: "Августа"}
         {small: "Сент", full: "Сентябрь", full2: "Сентября"}
         {small: "Окт",  full: "Октябрь",  full2: "Октября"}
         {small: "Ноя",  full: "Ноябрь",   full2: "Ноября"}
         {small: "Дек",  full: "Декабрь",  full2: "Декабря"}]

   # Дни недели.
   # @static
  @WEEK_DAYS_NAMES:
    en: [{small: "Su", full: "Su"}
         {small: "Mn", full: "Mn"}
         {small: "Tu", full: "Tu"}
         {small: "Wd", full: "Wd"}
         {small: "Th", full: "Th"}
         {small: "Fr", full: "Fr"}
         {small: "St", full: "St"}]

    ru: [{small: "Пн", full: "Понедельник"}
         {small: "Вт", full: "Вторник"}
         {small: "Ср", full: "Среда"}
         {small: "Чт", full: "Четверг"}
         {small: "Пт", full: "Пятница"}
         {small: "Сб", full: "Суббота"}
         {small: "Вс", full: "Воскресенье"}]
