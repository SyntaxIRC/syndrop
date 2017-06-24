bind pubm -|- "*" rezanon:relay
bind ctcp -|- "ACTION" rezanon:relayme

setudef flag rezanon:anonymous

proc isanon {c} {
	if {[channel get $c rezanon:anonymous] == 0} {return 0}
	return 1
}

proc rezrand {minn {maxx 0}} {
	if {!$maxx} {set maxx $minn;set minn 0}
	if {$minn==$maxx} {return $maxx}
	set maxnum [expr {$maxx - $minn}]
	set fp [open /dev/urandom r]
	set bytes [read $fp 6]
	close $fp
	scan $bytes %c%c%c%c%c%c ca co ce cu ci ch
	set co [expr {$co + pow(2,8)}]
	set ce [expr {$ce + pow(2,16)}]
	set cu [expr {$cu + pow(2,24)}]
	set ci [expr {$ci + pow(2,32)}]
	set ch [expr {$ch + pow(2,40)}]
	return [expr {$minn+(int($ca+$co+$ce+$cu+$ci+$ch)%$maxnum)}]
}

setudef int rezanon:rewritetimeout

proc getrewritetime {c} {
	if {[set to [channel get $c rezanon:rewritetimeout]] <= 60} {return 3600}
	return $to
}

proc getrewritenick {n c} {
	if {[isvoice $n $c] == 1} {return $n}
	if {[ishalfop $n $c] == 1} {return}
	if {[isop $n $c] == 1} {return}
	set n [string toupper $n]
	set do 0
	if {![info exists ::rewrites($c,$n)]} { set do 1 } elseif {[lindex $::rewrites($c,$n) 1] + [getrewritetime $c] <= [clock seconds]} {set do 1}
	if {$do} {
		set fp [open "./words" r]
		set word [split [read $fp] "\n "]
		set words [list]
		foreach i $word {
			if {[string length $i] < 2} {continue}
			foreach a [split $i {}] {
				if {[string first $a "\[\]\{\}^\|\\_-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"] == -1} {uplevel 1 continue}
			}
			lappend words $i
		}
		set randm [rezrand 0 [expr {[llength $words] -1}]]
		set ::rewrites($c,$n) [list [lindex $words $randm] [clock seconds]]
	}
	return [lindex $::rewrites($c,$n) 0]
}

proc rezanon:relay {n uh h c t} {
	if {![isanon $c]} {return}
	if {[string first [format "%s." [string tolower $::botnick]] [string tolower $t]] == 0} {return}
	if {[string first "--voiceme" [string tolower $t]] == 0} {return}
	if {[string first "--unhide" [string tolower $t]] == 0} {return}
	if {[string first "--tell" [string tolower $t]] == 0} {return}
	if {[isvoice $n $c] == 1} {return}
	if {[ishalfop $n $c] == 1} {return}
	if {[isop $n $c] == 1} {return}
	putnow [format "PRIVMSG %s :<%s> %s" $c [getrewritenick $n [string toupper $c]] $t]
}

proc rezanon:relayme {n uh h c t} {
	if {![isanon $c]} {return}
	if {[isvoice $n $c] == 1} {return}
	if {[ishalfop $n $c] == 1} {return}
	if {[isop $n $c] == 1} {return}
	putnow [format "PRIVMSG %s :ACTION %s %s" $c [getrewritenick $n [string toupper $c]] $t]
}

bind pub -|- "--voiceme" rezanon:voiceme
bind pub -|- [format "%s.voiceme" $::botnick] rezanon:voiceme

bind pub -|- "--unhide" rezanon:voiceme
bind pub -|- [format "%s.unhide" $::botnick] rezanon:voiceme

proc rezanon:voiceme {n uh h c t} {
	if {![isanon $c]} {return}
	if {[isvoice $n $c] == 1} {return}
	putnow [format "MODE %s +v %s" $c $n]
	putnow [format "NOTICE %s :You have been voiced, and thus unhidden, on %s." $n $c]
}
