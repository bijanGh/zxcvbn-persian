scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "از ترکیب چند کلمه غیر مرتبط استفاده کنید"
      "اجباری به استفاده از حروف، اعداد و یا سمبل ها نیست"
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 'یک یا چند کلمه دیگر اضافه کنید. کلمات غیر متداول بهترند.'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'توالی مرتب حروف به راحتی قابل حدس زدن هستند'
        else
          'الگوهای کوتاه کیبوردی به راحتی قابل حدس زدن هستند'
        warning: warning
        suggestions: [
          'از یک الگوی طولانی تر استفاده کنید'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'تکرار هایی مثل aaa به راحتی حدس زده می شوند'
        else
          'ترکیب هایی مثل abcabc فقط تا حدودی از abc سخت تر هستند'
        warning: warning
        suggestions: [
          'از تکرار کلمات و کاراکتر ها اجتناب کنید'
        ]

      when 'sequence'
        warning: "توالی های مثل 6543 به راحتی قابل حدس زدن هستند"
        suggestions: [
          'از توالی ها اجتناب کنید'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "شماره سال به راحتی قابل حدس زدن هست"
          suggestions: [
            'از شماره سال اجتناب کنید'
            'از استفاده شماره سال های مرتبط با خودتون اجتناب کنید'
          ]

      when 'date'
        warning: "تاریخ ها معمولا به راحتی حدس زده می شوند."
        suggestions: [
          'از استفاده از تاریخ و سال مرتبط با خودتون اجتناب کتید'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'این یکی از 10 پسور ناامن شناخته شده است!'
        else if match.rank <= 100
          'این یکی از 100 پسور ناامن شناخته شده است!'
        else
          'این یکی از متداول ترین پسورد ها هست'
      else if match.guesses_log10 <= 4
        'این رمز عبور مشابه یک رمز عبور متداول هست'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        'یک کلمه به تنهایی قابل حدس زدن هست'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'اسم و فامیلی به راحتی قابل حدس زدن هست'
      else
        'اسم های معروف به راحتی قابل حدس زدن هستند'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "استفاده کز حروف بزرگ معمولا کمک چندانی نمی کند"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "استفاده از تمام حروف بزرگ به امنیت رمز ورود کمکی نمی کند"

    if match.reversed and match.token.length >= 4
      suggestions.push "کلمات رزرو شده برای حدس زدن خیلی سخت نیستند"
    if match.l33t
      suggestions.push "استفاده از جایگزین هایی مثل @ به جای a رمز عبور ایمنی نمی سازد"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
