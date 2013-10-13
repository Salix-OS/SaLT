#! /usr/bin/env python
# -*- coding: utf-8 -*-

# this list defines the available languages, which should be used to generate the menu
langavailable = [
  # locale: the real locale on a Linux system.
  # polang: the name of the XX.po as translated by Transifex.
  # g2lang: the name of the /usr/share/locale/XX/LC_MESSAGES/grub.mo for already translated grub2 messages (grub2 does not follow the regular Linux locale scheme :-/ ). It could be none if there is no grub2 translation for it yet.
  # nativename: the name of the language in its language
  # console keyboard layout: the layout of the keyboard for that language in the Linux console. The Xorg (or Wayland one day) one will be determined based on it (Salix database).

  # locale,      polang,  g2lang,      name,                      nativename,              Console keyboard layout
  ['ar_SA.utf8', 'ar',    'en@arabic', 'Arabic',                  'العربية',               ['us']],                # seems to be the most neutral arabic locale, us keyboard seems to be a good compromise
  ['cs_CZ.utf8', 'cs',    None,        'Czech',                   'Česky',                 ['cz']],
  ['da_DK.utf8', 'da',    'da',        'Danish',                  'Dansk',                 ['dk']],
  ['de_DE.utf8', 'de',    'de',        'German',                  'Deutsch',               ['de']],
  ['en_US',      'en',    None,        'English (US)',            None,                    ['us']],
  ['en_GB.utf8', 'en',    None,        'English (GB)',            None,                    ['uk']],
  ['es_ES.utf8', 'es',    None,        'Spanish (Castilian)',    'Español (Castellano)',   ['es']],
  ['es_AR.utf8', 'es_AR', None,        'Spanish (Argentinian)',  'Español (Argentina)',    ['es']],
  ['fr_FR.utf8', 'fr',    'fr',        'French',                 'Français',               ['fr-latin9']],
  ['el_GR.utf8', 'el',    'en@greek',  'Greek',                  'Ελληνικά',               ['gr']],
  ['he.utf8',    'he',    'en@hebrew', 'Hebrew',                 'עִבְרִית',                  ['il']],
  ['hu_HU.utf8', 'hu',    'hu',        'Hungarian',              'Magyar',                 ['hu']],
  ['it_IT.utf8', 'it',    'it',        'Italian',                'Italiano',               ['it']],
  ['ja_JP.utf8', 'ja',    'ja',        'Japanese',               '日本語',                 ['jp106']],
  ['lt_LT.utf8', 'lt',    None,        'Lithuanian',             'Lietuviy',               ['lt']],
  ['nl_NL.utf8', 'nl',    'nl',        'Dutch',                  'Nederlands',             ['nl']],
  ['pl_PL.utf8', 'pl',    'pl',        'Polish',                 'Polski',                 ['pl']],
  ['pt_BR.utf8', 'pt_BR', None,        'Portuguese (Brazilian)', 'Português (Brasileiro)', ['br-abnt2']],
  ['pt_PT.utf8', 'pt_PT', None,        'Portuguese (European)',  'Português (Europeu)',    ['pt-latin1']],
  ['ru_RU.utf8', 'ru',    'ru',        'Russian',                'Русский',                ['ru_win']],
  ['sv_SE.utf8', 'sv',    'sv',        'Swedish',                'Svenska',                ['sv-latin1']],
  ['tr_TR.utf8', 'tr',    None,        'Turkish',                'Türkçe',                 ['trq']],
  ['uk_UA.utf8', 'uk',    'uk',        'Ukrainian',              'Українська',             ['ua']],
]
# which field to display as name
displayname = 'nativename'
# the sort order used by getlangavail, i.e. by the language menu
langsortkey = displayname
# put here some defaults
defaultlocale = 'en_US'

langpremenu = """
if [ -z "${{salt_langnum}}" ]; then
  set salt_langnum={deflangnum}
  set salt_locale={deflocale}
  set lang={deflang}
fi
set default=${{salt_langnum}}
"""
langmenuentry = """
menuentry "{title}"{hotkey} --class=locale {{
  set salt_langnum="{lang_num}"
  set salt_locale="{locale}"
  set _lang="{lang}"
  set salt_kb="{key}"
  nextconfig
}}
"""
kbmenuentry = """
menuentry "{title}"{hotkey} --class=keyboard {{
  set salt_kb="{title}"
  nextconfig
}}
"""

