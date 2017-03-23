package require tie
package require sqlite3

sqlite3 telldb ./${database-basename}.sl3

bind pub -|- [format "%s.tell" [string tolower $::nick]] pub:tell
bind pub -|- "--tell" pub:tell
bind pub -|- [format "%s.help" [string tolower $::nick]] pub:help
bind pub -|- ".bots" pub:bots
bind pubm -|- "*" pubm:tellcheck
bind join -|- "*" join:tellcheck
bind nick -|- "*" newnick:tellcheck

if {[llength [telldb eval {SELECT name FROM sqlite_master WHERE type='table' AND name='huxley_tells' COLLATE NOCASE}]] != 1} {
	telldb eval {CREATE TABLE huxley_tells(id text, stamp text, targ text, message text)}
	putlog "huxley_tells table created."
} else {
	putlog "huxley_tells table already exists; continuing start."
}


# Database manipulation commands

#Returns list of length%3=0
proc telldb:emptyforuser {target} {
 set arr [list]
 set barr [telldb eval {SELECT * FROM huxley_tells WHERE targ = :target ORDER BY CAST(stamp AS INTEGER);}]
 foreach {idid stamp targ text} $barr {
  lappend arr $stamp
  lappend arr $idid
  lappend arr $text
  telldb eval {DELETE FROM huxley_tells WHERE stamp = :stamp AND id = :idid AND message = :text}
 }
 return $arr
}

# void proc
proc telldb:storeforuser {stamp src target text} {
 telldb eval {INSERT INTO huxley_tells VALUES(:src, :stamp, :target, :text)}
}

#

# Binds

set istelling(1) 1
#void
proc join:tellcheck {n uh h c} {
 global istelling
 set istelling([string tolower $n]) 1
 set usertells [telldb:emptyforuser [string tolower $n]]
 foreach {stamp sourc text} $usertells {
  if {[string length $text] > 303} {
   set stri [split $text " "]
   set out ""
   set goes 1
   foreach {word} $stri {
    if {[string length $out]+[string length $word]+1 > 297} {
     if {$goes == 1} {
      puthelp [format "PRIVMSG %s :%s: '%s' asked me to tell you: %s [CUT]" $c $n $sourc $out]
     } else {
      puthelp [format "PRIVMSG %s :%s: ... %s" $c $n $out]
     }
    }
    append out $word
    append out " "
    incr goes
   }
  } else {
   puthelp [format "PRIVMSG %s :%s: '%s' asked me to tell you: %s" $c $n $sourc $text]
  }
 }
 set istelling([string tolower $n]) 0
}

#void
proc pubm:tellcheck {n uh h c t} {
 join:tellcheck $n $uh $h $c
}

#void
proc newnick:tellcheck {n uh h c nn} {
 join:tellcheck $nn $uh $h $c
}

#void
proc pub:tell {n uh h c t} {
 set clicks [clock microseconds]
 set src $n
 set message [split $t " "]
 if {[llength $message] == 0} {
  putserv [format "PRIVMSG %s :%s: Cannot perform action: No target specified." $c $n]
  return
 }
 if {[llength $message] == 1} {
  putserv [format "PRIVMSG %s :%s: Cannot perform action: No message given." $c $n]
  return
 }
 set targ [lindex $message 0]
 set mesg [join [lrange $message 1 end] " "]
 telldb:storeforuser $clicks $src [string tolower $targ] $mesg
 putserv [format "PRIVMSG %s :%s: I'll tell %s that as soon as I can. (stored to SQLite)" $c $n $targ]
}

#void
proc pub:help {n uh h c t} {
 puthelp [format "PRIVMSG %s :Hey %s! All I know about is %s.tell and %s.help at the moment." $c $n $::nick $::nick]
 puthelp [format "PRIVMSG %s :%s, %s.tell, also callable by typing %stell, is supposed to be a tell-bot function. If you send a tell, then next time a person with the nickname you're destinating the message for logs on or talks, they will receive it as a notice." $c $n $::nick "--"]
 if {[info commands "::pubm:personNotTuna"] == "::pubm:personNotTuna"} {puthelp [format "PRIVMSG %s :%s, I get angry if you use the French word for 'tuna'." $c $n]}
}

#void
proc pub:bots {n uh h c t} {
 putserv [format "PRIVMSG %s :Here! \[Tcl\] Do %s.help for more info" $c $::nick]
}

# /Binds
