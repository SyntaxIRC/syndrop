bind pubm -|- "*" pubm:personNotTuna

proc pubm:personNotTuna {n uh h c t} {
 if {[info commands "::getrewritenick"] == "::getrewritenick"} {if {[channel get $c rezanon:anonymous] != 0} {set n [getrewritenick $n $c]}}
 set findtuna [split [string tolower $t] "'\"\`\\/-_\]\[\}\{=+;:!@#\$%^&*() ?¿¡."]
 if {[lsearch -exact $findtuna "thon"] != -1} {
  putserv [format "PRIVMSG %s :%s, STOP CALLING PEOPLE TUNA!" $c $n]
  return
 }
 if {[lsearch -exact $findtuna "thons"] != -1} {
  putserv [format "PRIVMSG %s :%s, STOP CALLING PEOPLE TUNA!" $c $n]
  return
 }
 if {[lsearch -exact $findtuna "thonself"] != -1} {
  putserv [format "PRIVMSG %s :%s, STOP CALLING PEOPLE TUNA!" $c $n]
  return
 }
 if {[lsearch -exact $findtuna "thonselves"] != -1} {
  putserv [format "PRIVMSG %s :%s, STOP CALLING PEOPLE TUNA!" $c $n]
 }
}
